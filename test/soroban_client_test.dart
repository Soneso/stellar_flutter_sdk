import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  final TESTNET_SERVER_URL = "https://soroban-testnet.stellar.org";
  final HELLO_CONTRACT_PATH =
      '/Users/chris/Soneso/github/stellar_flutter_sdk/test/wasm/soroban_hello_world_contract.wasm';
  final AUTH_CONTRACT_PATH =
      '/Users/chris/Soneso/github/stellar_flutter_sdk/test/wasm/soroban_auth_contract.wasm';
  final SWAP_CONTRACT_PATH =
      '/Users/chris/Soneso/github/stellar_flutter_sdk/test/wasm/soroban_atomic_swap_contract.wasm';
  final TOKEN_CONTRACT_PATH =
      '/Users/chris/Soneso/github/stellar_flutter_sdk/test/wasm/soroban_token_contract.wasm';

  final network = Network.TESTNET;
  final sourceAccountKeyPair = KeyPair.random();

  setUp(() async {
    await FriendBot.fundTestAccount(sourceAccountKeyPair.accountId);
  });

  Future<String> installContract(String path) async {
    final contractCode = await Util.readFile(path);
    final installRequest = InstallRequest(
        wasmBytes: contractCode,
        sourceAccountKeyPair: sourceAccountKeyPair,
        network: network,
        rpcUrl: TESTNET_SERVER_URL,
        enableSorobanServerLogging: true);
    return await SorobanClient.install(installRequest: installRequest);
  }

  Future<SorobanClient> deployContract(String wasmHash) async {
    final deployRequest = DeployRequest(
        sourceAccountKeyPair: sourceAccountKeyPair,
        network: network,
        rpcUrl: TESTNET_SERVER_URL,
        wasmHash: wasmHash,
        enableSorobanServerLogging: true);
    return await SorobanClient.deploy(deployRequest: deployRequest);
  }

  Future<void> createToken(SorobanClient tokenClient, KeyPair submitterKp,
      String name, String symbol) async {
    // see https://soroban.stellar.org/docs/reference/interfaces/token-interface

    final submitterId = submitterKp.accountId;

    final adminAddress = Address.forAccountId(submitterId).toXdrSCVal();
    final methodName = "initialize";

    final tokenName = XdrSCVal.forString(name);
    final tokenSymbol = XdrSCVal.forString(symbol);

    List<XdrSCVal> args = [
      adminAddress,
      XdrSCVal.forU32(0),
      tokenName,
      tokenSymbol
    ];

    await tokenClient.invokeMethod(name: methodName, args: args);
  }

  Future<void> mint(SorobanClient tokenClient, KeyPair adminKp,
      String toAccountId, int amount) async {
    // see https://soroban.stellar.org/docs/reference/interfaces/token-interface

    final methodName = "mint";
    final toAddress = Address.forAccountId(toAccountId).toXdrSCVal();
    final amountValue = XdrSCVal.forI128Parts(0, amount);

    List<XdrSCVal> args = [toAddress, amountValue];

    final tx =
        await tokenClient.buildInvokeMethodTx(name: methodName, args: args);
    await tx.signAuthEntries(signerKeyPair: adminKp);
    await tx.signAndSend();
  }

  Future<int> readBalance(
      String forAccountId, SorobanClient tokenClient) async {
    // see https://soroban.stellar.org/docs/reference/interfaces/token-interface

    final address = Address.forAccountId(forAccountId).toXdrSCVal();
    final methodName = "balance";
    List<XdrSCVal> args = [address];
    final resultValue =
        await tokenClient.invokeMethod(name: methodName, args: args);
    assert(resultValue.i128 != null);
    return resultValue.i128!.lo.uint64;
  }

  test('test hello contract', () async {
    final helloContractWasmHash = await installContract(HELLO_CONTRACT_PATH);
    print("Installed hello contract wasm hash: $helloContractWasmHash");

    final client = await deployContract(helloContractWasmHash);
    print("Deployed hello contract contract id: ${client.getContractId()}");

    final methodNames = client.getMethodNames();
    assert(methodNames.length == 1);
    assert(methodNames.first == "hello");

    final result = await client
        .invokeMethod(name: "hello", args: [XdrSCVal.forSymbol("John")]);
    assert(result.vec != null);
    assert(result.vec!.length == 2);
    assert(result.vec![0].sym != null);
    assert(result.vec![1].sym != null);
    final resultValue = result.vec![0].sym! + ", " + result.vec![1].sym!;
    assert(resultValue == "Hello, John");
  });

  test('test auth', () async {
    final authContractWasmHash = await installContract(AUTH_CONTRACT_PATH);
    print("Installed auth contract wasm hash: $authContractWasmHash");

    final deployedClient = await deployContract(authContractWasmHash);
    print(
        "Deployed auth contract contract id: ${deployedClient.getContractId()}");

    // just a small test to check if it can load by contract id
    final client = await SorobanClient.forClientOptions(
        options: ClientOptions(
            sourceAccountKeyPair: sourceAccountKeyPair,
            contractId: deployedClient.getContractId(),
            network: network,
            rpcUrl: TESTNET_SERVER_URL,
            enableServerLogging: true));

    assert(client.getContractId() == deployedClient.getContractId());

    final methodName = "increment";

    final methodNames = client.getMethodNames();
    assert(methodNames.length == 1);
    assert(methodNames.first == methodName);

    // submitter and invoker use are the same
    // no need to sign auth

    var invokerAddress = Address.forAccountId(sourceAccountKeyPair.accountId);
    List<XdrSCVal> args = [invokerAddress.toXdrSCVal(), XdrSCVal.forU32(3)];
    final result = await client.invokeMethod(name: methodName, args: args);
    assert(result.u32 != null);
    assert(result.u32!.uint32 == 3);

    // submitter and invoker use are NOT the same
    // we need to sign the auth entry

    final invokerKeyPair = KeyPair.random();
    await FriendBot.fundTestAccount(invokerKeyPair.accountId);
    invokerAddress = Address.forAccountId(invokerKeyPair.accountId);
    args = [invokerAddress.toXdrSCVal(), XdrSCVal.forU32(4)];
    var thrown = false;
    try {
      await client.invokeMethod(name: methodName, args: args);
      // should not reach here because of missing signature of invoker
    } catch (e) {
      thrown = true;
      print(e.toString());
    }
    assert(thrown);

    final tx = await client.buildInvokeMethodTx(name: methodName, args: args);
    await tx.signAuthEntries(signerKeyPair: invokerKeyPair);
    final response = await tx.signAndSend();
    final resultVal = response.getResultValue();
    assert(resultVal?.u32 != null);
    assert(resultVal!.u32!.uint32 == 4);
  });

  test('test atomic swap', () async {
    final swapContractWasmHash = await installContract(SWAP_CONTRACT_PATH);
    print("Installed swap contract wasm hash: $swapContractWasmHash");

    final tokenContractWasmHash = await installContract(TOKEN_CONTRACT_PATH);
    print("Installed token contract wasm hash: $tokenContractWasmHash");

    final adminKeyPair = KeyPair.random();
    final aliceKeyPair = KeyPair.random();
    final aliceId = aliceKeyPair.accountId;
    final bobKeyPair = KeyPair.random();
    final bobId = bobKeyPair.accountId;

    await FriendBot.fundTestAccount(adminKeyPair.accountId);
    await FriendBot.fundTestAccount(aliceId);
    await FriendBot.fundTestAccount(bobId);

    final atomicSwapClient = await deployContract(swapContractWasmHash);
    print(
        "Deployed atomic swap contract contract id: ${atomicSwapClient.getContractId()}");

    final tokenAClient = await deployContract(tokenContractWasmHash);
    final tokenAContractId = tokenAClient.getContractId();
    print("Deployed token A contract contract id: $tokenAContractId");

    final tokenBClient = await deployContract(tokenContractWasmHash);
    final tokenBContractId = tokenBClient.getContractId();
    print("Deployed token B contract contract id: $tokenBContractId");

    await createToken(tokenAClient, adminKeyPair, "TokenA", "TokenA");
    await createToken(tokenBClient, adminKeyPair, "TokenB", "TokenB");
    print("Tokens created");

    await mint(tokenAClient, adminKeyPair, aliceId, 10000000000000);
    await mint(tokenBClient, adminKeyPair, bobId, 10000000000000);
    print("Alice and Bob funded");

    final aliceTokenABalance = await readBalance(aliceId, tokenAClient);
    assert(aliceTokenABalance == 10000000000000);

    final bobTokenBBalance = await readBalance(bobId, tokenBClient);
    assert(bobTokenBBalance == 10000000000000);

    final amountA = XdrSCVal.forI128Parts(0, 1000);
    final minBForA = XdrSCVal.forI128Parts(0, 4500);

    final amountB = XdrSCVal.forI128Parts(0, 5000);
    final minAForB = XdrSCVal.forI128Parts(0, 950);

    final swapMethodName = "swap";

    List<XdrSCVal> args = [
      Address.forAccountId(aliceId).toXdrSCVal(),
      Address.forAccountId(bobId).toXdrSCVal(),
      Address.forContractId(tokenAContractId).toXdrSCVal(),
      Address.forContractId(tokenBContractId).toXdrSCVal(),
      amountA,
      minBForA,
      amountB,
      minAForB
    ];

    final tx = await atomicSwapClient.buildInvokeMethodTx(
        name: swapMethodName, args: args);

    final whoElseNeedsToSign = tx.needsNonInvokerSigningBy();
    assert(whoElseNeedsToSign.length == 2);
    assert(whoElseNeedsToSign.contains(aliceId));
    assert(whoElseNeedsToSign.contains(bobId));

    await tx.signAuthEntries(signerKeyPair: aliceKeyPair);
    print("Signed by Alice");

    // test signing via delegate
    final bobPublicKeyKeyPair = KeyPair.fromAccountId(bobId);
    await tx.signAuthEntries(
        signerKeyPair: bobPublicKeyKeyPair,
        authorizeEntryDelegate: (entry, network) async {
          print("Bob is signing");
          // You can send it to some other server for signing by encoding it as a base64xdr string
          final base64Entry = entry.toBase64EncodedXdrString();
          // send for signing ...
          // and on the other server you can decode it:
          final entryToSign =
              SorobanAuthorizationEntry.fromBase64EncodedXdr(base64Entry);
          // sign it
          entryToSign.sign(bobKeyPair, network);
          // encode as a base64xdr string and send it back
          final signedBase64Entry = entryToSign.toBase64EncodedXdrString();
          print("Bob signed");
          // here you can now decode it and return it
          return SorobanAuthorizationEntry.fromBase64EncodedXdr(
              signedBase64Entry);
        });

    print("Signed by Bob");

    final response = await tx.signAndSend();
    final result = response.getResultValue();
    assert(result != null);
    assert(result!.discriminant == XdrSCValType.SCV_VOID);
  });
}
