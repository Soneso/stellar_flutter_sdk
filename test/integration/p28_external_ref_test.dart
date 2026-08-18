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

  String helloContractPath = "test/wasm/soroban_hello_world_contract.wasm";

  test('external reference resolution against a live network', () async {
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

    final wasmBytes = await loadContractCode(helloContractPath);
    final wasmHash = await SorobanClient.install(
      installRequest: InstallRequest(
        wasmBytes: wasmBytes,
        sourceAccountKeyPair: keyPair,
        network: network,
        rpcUrl: rpcUrl,
        server: sorobanServer,
      ),
    );
    final client = await SorobanClient.deploy(
      deployRequest: DeployRequest(
        sourceAccountKeyPair: keyPair,
        network: network,
        rpcUrl: rpcUrl,
        wasmHash: wasmHash,
        server: sorobanServer,
      ),
    );
    final contractId = client.getContractId();
    final contractIdHex = contractId.startsWith('C')
        ? StrKey.decodeContractIdHex(contractId)
        : contractId;

    // The executable dispatch still loads a wasm instance from the live ledger.
    final codeEntry = await sorobanServer.loadContractCodeForContractId(
      contractIdHex,
    );
    expect(codeEntry, isNotNull);
    expect(codeEntry!.code, isNotEmpty);

    // The RPC must accept the ledger key the resolver builds for an executable
    // tag, and answer an empty entry list for a tag no entry exists under. The
    // response is asserted directly because a null from the resolver would not
    // distinguish an accepted-but-absent key from a rejected request.
    const unusedTag = 'no entry exists under this tag';
    final owner = Address.forContractId(contractIdHex).toXdr();
    final tagKey = XdrLedgerKey.forContractData(
      owner,
      XdrSCVal.forExecutableTag(unusedTag),
      XdrContractDataDurability.PERSISTENT,
    );
    final response = await sorobanServer.getLedgerEntries([
      tagKey.toBase64EncodedXdrString(),
    ]);
    expect(response.error, isNull);
    expect(response.entries, isNotNull);
    expect(response.entries, isEmpty);

    // The resolver reports the same absence as null.
    final ref = XdrContractExecutable.forExternalRef(
      owner,
      unusedTag,
    ).externalRef!;
    expect(await sorobanServer.getExternalRefWasmHash(ref), isNull);
  }, timeout: const Timeout(Duration(minutes: 5)));
}
