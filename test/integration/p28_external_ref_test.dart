import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import '../tests_util.dart';

void main() {
  String testOn = 'testnet'; //'futurenet';

  final String rpcUrl = testOn == 'testnet'
      ? "https://soroban-testnet.stellar.org"
      : "https://rpc-futurenet.stellar.org";
  SorobanServer sorobanServer = SorobanServer(rpcUrl);
  StellarSDK sdk = testOn == 'testnet'
      ? StellarSDK.TESTNET
      : StellarSDK.FUTURENET;
  Network network = testOn == 'testnet' ? Network.TESTNET : Network.FUTURENET;

  // The owner fixture exposes set_executable(tag, wasm_hash) and
  // get_executable(tag) over the CAP-85 host functions; its source lives in this
  // repo under tools/p28-owner-fixture.
  String ownerFixturePath = "test/wasm/p28_owner_fixture.wasm";
  String targetContractPath = "test/wasm/soroban_hello_world_contract.wasm";
  String executableTag = 'sdk-e2e-v1';

  test('external reference lifecycle against a live network', () async {
    final latestLedger = await sorobanServer.getLatestLedger();
    final protocolVersion = latestLedger.protocolVersion;
    if (protocolVersion == null || protocolVersion < 28) {
      markTestSkipped(
        'The network at $rpcUrl reports protocol '
        '${protocolVersion ?? 'unavailable'}; external reference executables '
        'need protocol 28.',
      );
      return;
    }

    final keyPair = KeyPair.random();
    await fundTestAccountAndAwaitVisibility(
      keyPair.accountId,
      rpc: sorobanServer,
      horizon: sdk,
      useFuturenet: testOn != 'testnet',
    );

    // Install and deploy the owner fixture holding the executable tag entries.
    final ownerWasmHash = await SorobanClient.install(
      installRequest: InstallRequest(
        wasmBytes: await loadContractCode(ownerFixturePath),
        sourceAccountKeyPair: keyPair,
        network: network,
        rpcUrl: rpcUrl,
        server: sorobanServer,
      ),
    );
    final owner = await SorobanClient.deploy(
      deployRequest: DeployRequest(
        sourceAccountKeyPair: keyPair,
        network: network,
        rpcUrl: rpcUrl,
        wasmHash: ownerWasmHash,
        server: sorobanServer,
      ),
    );
    expect(owner.getMethodNames(), contains('set_executable'));
    final ownerIdHex = StrKey.decodeContractIdHex(owner.getContractId());
    final ownerAddress = Address.forContractId(ownerIdHex);

    // Install the target code and write the tag entry naming it.
    final targetBytes = await loadContractCode(targetContractPath);
    final targetWasmHash = await SorobanClient.install(
      installRequest: InstallRequest(
        wasmBytes: targetBytes,
        sourceAccountKeyPair: keyPair,
        network: network,
        rpcUrl: rpcUrl,
        server: sorobanServer,
      ),
    );
    await owner.invokeMethod(name: 'set_executable', args: [
      XdrSCVal.forString(executableTag),
      XdrSCVal.forBytes(Util.hexToBytes(targetWasmHash)),
    ]);

    // The reference resolves to the stored wasm hash; an unknown tag answers
    // an accepted-but-empty read and a null from the resolver.
    final ref = XdrContractExecutableExternalRef(
      ownerAddress.toXdr(),
      Uint8List.fromList(utf8.encode(executableTag)),
    );
    final resolved = await sorobanServer.getExternalRefWasmHash(ref);
    expect(resolved, isNotNull);
    expect(Util.bytesToHex(resolved!), targetWasmHash);

    const unusedTag = 'no entry exists under this tag';
    final unusedKey = XdrLedgerKey.forContractData(
      ownerAddress.toXdr(),
      XdrSCVal.forExecutableTag(unusedTag),
      XdrContractDataDurability.PERSISTENT,
    );
    final response = await sorobanServer.getLedgerEntries([
      unusedKey.toBase64EncodedXdrString(),
    ]);
    expect(response.error, isNull);
    expect(response.entries, isNotNull);
    expect(response.entries, isEmpty);
    final unusedRef = XdrContractExecutableExternalRef(
      ownerAddress.toXdr(),
      Uint8List.fromList(utf8.encode(unusedTag)),
    );
    expect(await sorobanServer.getExternalRefWasmHash(unusedRef), isNull);

    // Deploy from the reference with an explicit salt; the created contract id
    // must match the derivation, and the instance must run the target's code.
    final random = Random.secure();
    final salt =
        Uint8List.fromList(List<int>.generate(32, (_) => random.nextInt(256)));
    final predictedContractId = Address.deriveContractId(
      deployer: Address.forAccountId(keyPair.accountId),
      salt: salt,
      network: network,
    );
    final client = await SorobanClient.deployFromExternalRef(
      deployRequest: DeployFromExternalRefRequest.forTagString(
        sourceAccountKeyPair: keyPair,
        network: network,
        rpcUrl: rpcUrl,
        executableOwner: ownerAddress,
        tag: executableTag,
        salt: XdrUint256(salt),
        server: sorobanServer,
      ),
    );
    expect(client.getContractId(), predictedContractId);
    expect(client.getMethodNames(), contains('hello'));

    // The instance entry carries the external reference arm naming owner and
    // tag, and the loading paths recover the target's code through it.
    final newIdHex = StrKey.decodeContractIdHex(client.getContractId());
    final instanceEntry = await sorobanServer.getContractData(
      newIdHex,
      XdrSCVal.forLedgerKeyContractInstance(),
      XdrContractDataDurability.PERSISTENT,
    );
    expect(instanceEntry, isNotNull);
    final executable =
        instanceEntry!.ledgerEntryDataXdr.contractData?.val.instance?.executable;
    expect(executable, isNotNull);
    expect(executable!.type,
        XdrContractExecutableType.CONTRACT_EXECUTABLE_EXTERNAL_REF);
    expect(Util.bytesToHex(executable.externalRef!.executableOwner.contractId!.hash),
        ownerIdHex);
    expect(executable.externalRef!.tag,
        Uint8List.fromList(utf8.encode(executableTag)));

    final codeEntry =
        await sorobanServer.loadContractCodeForContractId(newIdHex);
    expect(codeEntry, isNotNull);
    expect(codeEntry!.code, equals(targetBytes));
    final info = await sorobanServer.loadContractInfoForContractId(newIdHex);
    expect(info, isNotNull);
    expect(info!.funcs.map((func) => func.name), contains('hello'));

    // The deployed instance is live: it answers as the target contract.
    final result = await client.invokeMethod(
      name: 'hello',
      args: [XdrSCVal.forSymbol('friend')],
    );
    expect(result.vec![0].sym, 'Hello');
    expect(result.vec![1].sym, 'friend');
  }, timeout: const Timeout(Duration(minutes: 8)));
}
