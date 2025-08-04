import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  String testOn = 'testnet'; //'futurenet';
  Network network = testOn == 'testnet' ? Network.TESTNET : Network.FUTURENET;

  final TESTNET_SERVER_URL = testOn == 'testnet'
      ? "https://soroban-testnet.stellar.org"
      : "https://rpc-futurenet.stellar.org";
  final HELLO_CONTRACT_PATH =
      '/Users/chris/Soneso/github/stellar_flutter_sdk/test/wasm/soroban_hello_world_contract.wasm';
  final AUTH_CONTRACT_PATH =
      '/Users/chris/Soneso/github/stellar_flutter_sdk/test/wasm/soroban_auth_contract.wasm';
  final SWAP_CONTRACT_PATH =
      '/Users/chris/Soneso/github/stellar_flutter_sdk/test/wasm/soroban_atomic_swap_contract.wasm';
  final TOKEN_CONTRACT_PATH =
      '/Users/chris/Soneso/github/stellar_flutter_sdk/test/wasm/soroban_token_contract.wasm';

  final sourceAccountKeyPair = KeyPair.random();

  setUp(() async {
    if (testOn == 'testnet') {
      await FriendBot.fundTestAccount(sourceAccountKeyPair.accountId);
    } else {
      await FuturenetFriendBot.fundTestAccount(sourceAccountKeyPair.accountId);
    }
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

  // ContractSpec versions of token functions for comparison
  Future<void> createTokenWithSpec(SorobanClient tokenClient, KeyPair submitterKp,
      String name, String symbol) async {
    // Using ContractSpec - much simpler!
    final args = tokenClient.funcArgsToXdrSCValues("initialize", {
      "admin": submitterKp.accountId,  // String -> Address automatic conversion
      "decimal": 0,                    // int -> u32 automatic conversion
      "name": name,                    // String -> String (direct)
      "symbol": symbol                 // String -> String (direct)
    });

    await tokenClient.invokeMethod(name: "initialize", args: args);
  }

  Future<void> mintWithSpec(SorobanClient tokenClient, KeyPair adminKp,
      String toAccountId, int amount) async {
    // Using ContractSpec - automatic type conversion!
    final args = tokenClient.funcArgsToXdrSCValues("mint", {
      "to": toAccountId,  // String -> Address automatic conversion
      "amount": amount    // int -> i128 automatic conversion
    });

    final tx = await tokenClient.buildInvokeMethodTx(name: "mint", args: args);
    await tx.signAuthEntries(signerKeyPair: adminKp);
    await tx.signAndSend();
  }

  Future<int> readBalanceWithSpec(
      String forAccountId, SorobanClient tokenClient) async {
    // Using ContractSpec - cleaner argument passing!
    final args = tokenClient.funcArgsToXdrSCValues("balance", {
      "id": forAccountId  // String -> Address automatic conversion
    });
    
    final resultValue = await tokenClient.invokeMethod(name: "balance", args: args);
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

    // Manual XdrSCVal creation (original approach)
    final result = await client
        .invokeMethod(name: "hello", args: [XdrSCVal.forSymbol("John")]);
    assert(result.vec != null);
    assert(result.vec!.length == 2);
    assert(result.vec![0].sym != null);
    assert(result.vec![1].sym != null);
    final resultValue = result.vec![0].sym! + ", " + result.vec![1].sym!;
    assert(resultValue == "Hello, John");
  });

  test('test hello contract with ContractSpec', () async {
    final helloContractWasmHash = await installContract(HELLO_CONTRACT_PATH);
    print("Installed hello contract wasm hash: $helloContractWasmHash");

    final client = await deployContract(helloContractWasmHash);
    print("Deployed hello contract contract id: ${client.getContractId()}");

    final methodNames = client.getMethodNames();
    assert(methodNames.length == 1);
    assert(methodNames.first == "hello");

    // Using ContractSpec for automatic type conversion (new approach)
    try {
      final contractSpec = client.getContractSpec();
      
      // Demonstrate ContractSpec capabilities
      final functions = contractSpec.funcs();
      print("Contract functions: ${functions.map((f) => f.name).toList()}");
      
      final helloFunc = contractSpec.getFunc("hello");
      assert(helloFunc != null);
      assert(helloFunc!.name == "hello");
      print("Found hello function with ${helloFunc!.inputs.length} inputs");
      
      // Convert arguments using ContractSpec - this is the key improvement!
      // Instead of: [XdrSCVal.forSymbol("Maria")]
      // We can use: {"to": "Maria"}
      final args = contractSpec.funcArgsToXdrSCValues("hello", {"to": "Maria"});
      
      final result = await client.invokeMethod(name: "hello", args: args);
      assert(result.vec != null);
      assert(result.vec!.length == 2);
      assert(result.vec![0].sym != null);
      assert(result.vec![1].sym != null);
      final resultValue = result.vec![0].sym! + ", " + result.vec![1].sym!;
      assert(resultValue == "Hello, Maria");
      
      print("✓ ContractSpec successfully converted hello function arguments");
      print("✓ Result: $resultValue");
      
      // Test convenience method on SorobanClient
      final args2 = client.funcArgsToXdrSCValues("hello", {"to": "World"});
      final result2 = await client.invokeMethod(name: "hello", args: args2);
      final resultValue2 = result2.vec![0].sym! + ", " + result2.vec![1].sym!;
      assert(resultValue2 == "Hello, World");
      print("✓ SorobanClient convenience method works: $resultValue2");
      
    } catch (e) {
      print("ContractSpec failed: $e");
      rethrow; // Let the test fail if ContractSpec doesn't work
    }
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
    if (testOn == 'testnet') {
      await FriendBot.fundTestAccount(invokerKeyPair.accountId);
    } else {
      await FuturenetFriendBot.fundTestAccount(invokerKeyPair.accountId);
    }

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

  test('test auth with ContractSpec', () async {
    final authContractWasmHash = await installContract(AUTH_CONTRACT_PATH);
    print("Installed auth contract wasm hash: $authContractWasmHash");

    final client = await deployContract(authContractWasmHash);
    print("Deployed auth contract contract id: ${client.getContractId()}");

    final methodNames = client.getMethodNames();
    assert(methodNames.length == 1);
    assert(methodNames.first == "increment");

    // Demonstrate ContractSpec usage with auth contract
    final contractSpec = client.getContractSpec();
    
    // Show the difference between manual and ContractSpec approach
    print("=== Manual XdrSCVal Creation (Original) ===");
    var invokerAddress = Address.forAccountId(sourceAccountKeyPair.accountId);
    List<XdrSCVal> manualArgs = [invokerAddress.toXdrSCVal(), XdrSCVal.forU32(5)];
    final manualResult = await client.invokeMethod(name: "increment", args: manualArgs);
    assert(manualResult.u32 != null);
    assert(manualResult.u32!.uint32 == 5);
    print("Manual result: ${manualResult.u32!.uint32}");

    print("=== ContractSpec Approach (New) ===");
    // Much simpler and more readable!
    final specArgs = contractSpec.funcArgsToXdrSCValues("increment", {
      "user": sourceAccountKeyPair.accountId,  // String account ID -> automatically converts to Address
      "value": 7                               // int -> automatically converts to u32
    });
    final specResult = await client.invokeMethod(name: "increment", args: specArgs);
    assert(specResult.u32 != null);
    assert(specResult.u32!.uint32 == 12); // 5 + 7
    print("ContractSpec result: ${specResult.u32!.uint32}");

    // Test convenience method
    final args3 = client.funcArgsToXdrSCValues("increment", {
      "user": sourceAccountKeyPair.accountId,
      "value": 9
    });
    final result3 = await client.invokeMethod(name: "increment", args: args3);
    assert(result3.u32!.uint32 == 21); // 5 + 7 + 9
    print("✓ SorobanClient convenience method: ${result3.u32!.uint32}");

    print("✓ ContractSpec successfully simplified auth contract invocation");
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

    if (testOn == 'testnet') {
      await FriendBot.fundTestAccount(adminKeyPair.accountId);
      await FriendBot.fundTestAccount(aliceId);
      await FriendBot.fundTestAccount(bobId);
    } else {
      await FuturenetFriendBot.fundTestAccount(adminKeyPair.accountId);
      await FuturenetFriendBot.fundTestAccount(aliceId);
      await FuturenetFriendBot.fundTestAccount(bobId);
    }

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

  test('test atomic swap with ContractSpec', () async {
    final swapContractWasmHash = await installContract(SWAP_CONTRACT_PATH);
    print("Installed swap contract wasm hash: $swapContractWasmHash");

    final tokenContractWasmHash = await installContract(TOKEN_CONTRACT_PATH);
    print("Installed token contract wasm hash: $tokenContractWasmHash");

    final adminKeyPair = KeyPair.random();
    final aliceKeyPair = KeyPair.random();
    final aliceId = aliceKeyPair.accountId;
    final bobKeyPair = KeyPair.random();
    final bobId = bobKeyPair.accountId;

    if (testOn == 'testnet') {
      await FriendBot.fundTestAccount(adminKeyPair.accountId);
      await FriendBot.fundTestAccount(aliceId);
      await FriendBot.fundTestAccount(bobId);
    } else {
      await FuturenetFriendBot.fundTestAccount(adminKeyPair.accountId);
      await FuturenetFriendBot.fundTestAccount(aliceId);
      await FuturenetFriendBot.fundTestAccount(bobId);
    }

    final atomicSwapClient = await deployContract(swapContractWasmHash);
    print("Deployed atomic swap contract contract id: ${atomicSwapClient.getContractId()}");

    final tokenAClient = await deployContract(tokenContractWasmHash);
    final tokenAContractId = tokenAClient.getContractId();
    print("Deployed token A contract contract id: $tokenAContractId");

    final tokenBClient = await deployContract(tokenContractWasmHash);
    final tokenBContractId = tokenBClient.getContractId();
    print("Deployed token B contract contract id: $tokenBContractId");

    // Use ContractSpec for token operations
    print("=== Creating tokens with ContractSpec ===");
    await createTokenWithSpec(tokenAClient, adminKeyPair, "TokenA", "TokenA");
    await createTokenWithSpec(tokenBClient, adminKeyPair, "TokenB", "TokenB");
    print("✓ Tokens created using ContractSpec");

    print("=== Minting tokens with ContractSpec ===");
    await mintWithSpec(tokenAClient, adminKeyPair, aliceId, 10000000000000);
    await mintWithSpec(tokenBClient, adminKeyPair, bobId, 10000000000000);
    print("✓ Alice and Bob funded using ContractSpec");

    final aliceTokenABalance = await readBalanceWithSpec(aliceId, tokenAClient);
    assert(aliceTokenABalance == 10000000000000);

    final bobTokenBBalance = await readBalanceWithSpec(bobId, tokenBClient);
    assert(bobTokenBBalance == 10000000000000);
    print("✓ Balances verified using ContractSpec");

    print("=== Demonstrating ContractSpec for complex atomic swap ===");
    print("--- Manual XdrSCVal creation (original approach) ---");
    final manualAmountA = XdrSCVal.forI128Parts(0, 1000);
    final manualMinBForA = XdrSCVal.forI128Parts(0, 4500);
    final manualAmountB = XdrSCVal.forI128Parts(0, 5000);
    final manualMinAForB = XdrSCVal.forI128Parts(0, 950);

    List<XdrSCVal> manualArgs = [
      Address.forAccountId(aliceId).toXdrSCVal(),
      Address.forAccountId(bobId).toXdrSCVal(),
      Address.forContractId(tokenAContractId).toXdrSCVal(),
      Address.forContractId(tokenBContractId).toXdrSCVal(),
      manualAmountA,
      manualMinBForA,
      manualAmountB,
      manualMinAForB
    ];
    print("Manual args count: ${manualArgs.length}");

    print("--- ContractSpec approach (new approach) ---");
    // This is MUCH cleaner and more readable!
    final contractSpec = atomicSwapClient.getContractSpec();
    final specArgs = contractSpec.funcArgsToXdrSCValues("swap", {
      "a": aliceId,                    // String -> Address (automatic)
      "b": bobId,                      // String -> Address (automatic)
      "token_a": tokenAContractId,     // String -> Address (automatic)
      "token_b": tokenBContractId,     // String -> Address (automatic)
      "amount_a": 1000,                // int -> i128 (automatic)
      "min_b_for_a": 4500,            // int -> i128 (automatic)
      "amount_b": 5000,                // int -> i128 (automatic)
      "min_a_for_b": 950               // int -> i128 (automatic)
    });
    print("ContractSpec args count: ${specArgs.length}");
    print("✓ ContractSpec automatically converted 8 parameters with correct types");

    // Build and execute the transaction using ContractSpec args
    final tx = await atomicSwapClient.buildInvokeMethodTx(name: "swap", args: specArgs);

    final whoElseNeedsToSign = tx.needsNonInvokerSigningBy();
    assert(whoElseNeedsToSign.length == 2);
    assert(whoElseNeedsToSign.contains(aliceId));
    assert(whoElseNeedsToSign.contains(bobId));

    await tx.signAuthEntries(signerKeyPair: aliceKeyPair);
    print("✓ Signed by Alice");

    await tx.signAuthEntries(signerKeyPair: bobKeyPair);
    print("✓ Signed by Bob");

    final response = await tx.signAndSend();
    final result = response.getResultValue();
    assert(result != null);
    assert(result!.discriminant == XdrSCValType.SCV_VOID);
    
    print("✓ Atomic swap completed successfully using ContractSpec!");
    print("✓ ContractSpec made complex contract invocation much simpler and more readable");
  });
}
