@Timeout(const Duration(seconds: 600))
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import '../tests_util.dart';

void main() {
  final String rpcUrl = 'https://soroban-testnet.stellar.org:443';
  final Network network = Network.TESTNET;
  final String helloContractPath =
      'test/wasm/soroban_hello_world_contract.wasm';
  final String authContractPath = 'test/wasm/soroban_auth_contract.wasm';
  final String eventsContractPath = 'test/wasm/soroban_events_contract.wasm';
  final String tokenContractPath = 'test/wasm/soroban_token_contract.wasm';
  final String swapContractPath = 'test/wasm/soroban_atomic_swap_contract.wasm';

  group('SorobanServer', () {
    late SorobanServer server;
    late KeyPair keyPair;

    setUpAll(() async {
      server = SorobanServer(rpcUrl);
      keyPair = KeyPair.random();
      await FriendBot.fundTestAccount(keyPair.accountId);
    });

    test('soroban: Health Check', () async {
      // Snippet from soroban.md "Health Check"
      GetHealthResponse health = await server.getHealth();
      expect(health.status, GetHealthResponse.HEALTHY);
    });

    test('soroban: Network Information', () async {
      // Snippet from soroban.md "Network Information"
      GetNetworkResponse networkResp = await server.getNetwork();
      expect(networkResp.passphrase, isNotNull);
      expect(networkResp.protocolVersion, isNotNull);
    });

    test('soroban: Latest Ledger', () async {
      // Snippet from soroban.md "Latest Ledger"
      GetLatestLedgerResponse ledger = await server.getLatestLedger();
      expect(ledger.sequence, isNotNull);
      expect(ledger.sequence!, greaterThan(0));
    });

    test('soroban: Account Data', () async {
      // Snippet from soroban.md "Account Data"
      Account? account = await server.getAccount(keyPair.accountId);
      expect(account, isNotNull);
      expect(account!.sequenceNumber, isNotNull);
    });
  });

  group('Quick Start and SorobanClient', () {
    late KeyPair keyPair;
    late String helloWasmHash;
    late SorobanClient helloClient;

    setUpAll(() async {
      keyPair = KeyPair.random();
      await FriendBot.fundTestAccount(keyPair.accountId);

      // Install hello contract
      final contractCode = await loadContractCode(helloContractPath);
      helloWasmHash = await SorobanClient.install(
        installRequest: InstallRequest(
          wasmBytes: contractCode,
          rpcUrl: rpcUrl,
          network: network,
          sourceAccountKeyPair: keyPair,
        ),
      );

      // Deploy hello contract
      helloClient = await SorobanClient.deploy(
        deployRequest: DeployRequest(
          rpcUrl: rpcUrl,
          network: network,
          sourceAccountKeyPair: keyPair,
          wasmHash: helloWasmHash,
        ),
      );
    });

    test('soroban: Quick Start - invoke hello', () async {
      // Snippet from soroban.md "Quick Start"
      XdrSCVal result = await helloClient.invokeMethod(
        name: 'hello',
        args: [XdrSCVal.forSymbol('World')],
      );
      expect(result.vec, isNotNull);
      expect(result.vec!.length, 2);
      expect(result.vec![0].sym, 'Hello');
      expect(result.vec![1].sym, 'World');
    });

    test('soroban: Creating a Client', () async {
      // Snippet from soroban.md "Creating a Client"
      SorobanClient client = await SorobanClient.forClientOptions(
        options: ClientOptions(
          sourceAccountKeyPair: keyPair,
          contractId: helloClient.getContractId(),
          network: network,
          rpcUrl: rpcUrl,
        ),
      );

      List<String> methodNames = client.getMethodNames();
      expect(methodNames, contains('hello'));

      ContractSpec spec = client.getContractSpec();
      expect(spec.funcs(), isNotEmpty);
    });

    test('soroban: Invoking Methods', () async {
      // Snippet from soroban.md "Invoking Methods" (read-only call)
      XdrSCVal result = await helloClient.invokeMethod(
        name: 'hello',
        args: [XdrSCVal.forSymbol('Dart')],
      );
      expect(result.vec![0].sym, 'Hello');
      expect(result.vec![1].sym, 'Dart');
    });
  });

  group('AssembledTransaction', () {
    late KeyPair keyPair;
    late SorobanClient authClient;

    setUpAll(() async {
      keyPair = KeyPair.random();
      await FriendBot.fundTestAccount(keyPair.accountId);

      // Install and deploy auth contract
      final contractCode = await loadContractCode(authContractPath);
      String wasmHash = await SorobanClient.install(
        installRequest: InstallRequest(
          wasmBytes: contractCode,
          rpcUrl: rpcUrl,
          network: network,
          sourceAccountKeyPair: keyPair,
        ),
      );

      authClient = await SorobanClient.deploy(
        deployRequest: DeployRequest(
          rpcUrl: rpcUrl,
          network: network,
          sourceAccountKeyPair: keyPair,
          wasmHash: wasmHash,
        ),
      );
    });

    test('soroban: Building Without Submitting', () async {
      // Snippet from soroban.md "Building Without Submitting"
      AssembledTransaction tx = await authClient.buildInvokeMethodTx(
        name: 'increment',
        args: [
          Address.forAccountId(keyPair.accountId).toXdrSCVal(),
          XdrSCVal.forU32(5),
        ],
      );
      expect(tx.simulationResponse, isNotNull);
    });

    test('soroban: Accessing Simulation Results', () async {
      // Snippet from soroban.md "Accessing Simulation Results"
      AssembledTransaction tx = await authClient.buildInvokeMethodTx(
        name: 'increment',
        args: [
          Address.forAccountId(keyPair.accountId).toXdrSCVal(),
          XdrSCVal.forU32(3),
        ],
      );

      SimulateHostFunctionResult simData = tx.getSimulationData();
      expect(simData.returnedValue, isNotNull);
      int? minResourceFee = tx.simulationResponse?.minResourceFee;
      expect(minResourceFee, isNotNull);
    });

    test('soroban: Read-Only vs Write Calls', () async {
      // Snippet from soroban.md "Read-Only vs Write Calls"
      AssembledTransaction tx = await authClient.buildInvokeMethodTx(
        name: 'increment',
        args: [
          Address.forAccountId(keyPair.accountId).toXdrSCVal(),
          XdrSCVal.forU32(2),
        ],
      );

      // Auth contract increment is a write call
      expect(tx.isReadCall(), isFalse);

      // Write: must sign and submit
      GetTransactionResponse response = await tx.signAndSend();
      XdrSCVal? result = response.getResultValue();
      expect(result, isNotNull);
      expect(result!.u32?.uint32, isNotNull);
    });
  });

  group('Authorization', () {
    late KeyPair sourceKeyPair;
    late SorobanClient swapClient;
    late SorobanClient tokenAClient;
    late SorobanClient tokenBClient;
    late String tokenAContractId;
    late String tokenBContractId;
    late KeyPair adminKeyPair;
    late KeyPair aliceKeyPair;
    late KeyPair bobKeyPair;

    setUpAll(() async {
      sourceKeyPair = KeyPair.random();
      adminKeyPair = KeyPair.random();
      aliceKeyPair = KeyPair.random();
      bobKeyPair = KeyPair.random();

      await FriendBot.fundTestAccount(sourceKeyPair.accountId);
      await FriendBot.fundTestAccount(adminKeyPair.accountId);
      await FriendBot.fundTestAccount(aliceKeyPair.accountId);
      await FriendBot.fundTestAccount(bobKeyPair.accountId);

      // Install contracts
      final swapCode = await loadContractCode(swapContractPath);
      String swapWasmHash = await SorobanClient.install(
        installRequest: InstallRequest(
          wasmBytes: swapCode,
          rpcUrl: rpcUrl,
          network: network,
          sourceAccountKeyPair: sourceKeyPair,
        ),
      );

      final tokenCode = await loadContractCode(tokenContractPath);
      String tokenWasmHash = await SorobanClient.install(
        installRequest: InstallRequest(
          wasmBytes: tokenCode,
          rpcUrl: rpcUrl,
          network: network,
          sourceAccountKeyPair: sourceKeyPair,
        ),
      );

      // Deploy swap contract
      swapClient = await SorobanClient.deploy(
        deployRequest: DeployRequest(
          rpcUrl: rpcUrl,
          network: network,
          sourceAccountKeyPair: sourceKeyPair,
          wasmHash: swapWasmHash,
        ),
      );

      // Deploy token A
      XdrSCVal adminAddress = Address.forAccountId(
        adminKeyPair.accountId,
      ).toXdrSCVal();
      tokenAClient = await SorobanClient.deploy(
        deployRequest: DeployRequest(
          rpcUrl: rpcUrl,
          network: network,
          sourceAccountKeyPair: sourceKeyPair,
          wasmHash: tokenWasmHash,
          constructorArgs: [
            adminAddress,
            XdrSCVal.forU32(0),
            XdrSCVal.forString('TokenA'),
            XdrSCVal.forString('TokenA'),
          ],
        ),
      );
      tokenAContractId = tokenAClient.getContractId();

      // Deploy token B
      tokenBClient = await SorobanClient.deploy(
        deployRequest: DeployRequest(
          rpcUrl: rpcUrl,
          network: network,
          sourceAccountKeyPair: sourceKeyPair,
          wasmHash: tokenWasmHash,
          constructorArgs: [
            adminAddress,
            XdrSCVal.forU32(0),
            XdrSCVal.forString('TokenB'),
            XdrSCVal.forString('TokenB'),
          ],
        ),
      );
      tokenBContractId = tokenBClient.getContractId();

      // Mint tokens to Alice and Bob using admin keypair
      // Need a client with admin as source
      SorobanClient tokenAAdmin = await SorobanClient.forClientOptions(
        options: ClientOptions(
          sourceAccountKeyPair: adminKeyPair,
          contractId: tokenAContractId,
          network: network,
          rpcUrl: rpcUrl,
        ),
      );
      SorobanClient tokenBAdmin = await SorobanClient.forClientOptions(
        options: ClientOptions(
          sourceAccountKeyPair: adminKeyPair,
          contractId: tokenBContractId,
          network: network,
          rpcUrl: rpcUrl,
        ),
      );

      // Mint to Alice (token A) and Bob (token B)
      // Admin is the source account, so invoker auth is automatic (no signAuthEntries needed)
      await tokenAAdmin.invokeMethod(
        name: 'mint',
        args: [
          Address.forAccountId(aliceKeyPair.accountId).toXdrSCVal(),
          XdrSCVal.forI128Parts(BigInt.zero, BigInt.from(10000)),
        ],
      );

      await tokenBAdmin.invokeMethod(
        name: 'mint',
        args: [
          Address.forAccountId(bobKeyPair.accountId).toXdrSCVal(),
          XdrSCVal.forI128Parts(BigInt.zero, BigInt.from(10000)),
        ],
      );
    });

    test('soroban: Check Who Needs to Sign and Local Signing', () async {
      // Snippet from soroban.md "Check Who Needs to Sign" and "Local Signing"
      AssembledTransaction tx = await swapClient.buildInvokeMethodTx(
        name: 'swap',
        args: [
          Address.forAccountId(aliceKeyPair.accountId).toXdrSCVal(),
          Address.forAccountId(bobKeyPair.accountId).toXdrSCVal(),
          Address.forContractId(tokenAContractId).toXdrSCVal(),
          Address.forContractId(tokenBContractId).toXdrSCVal(),
          XdrSCVal.forI128Parts(BigInt.zero, BigInt.from(1000)),
          XdrSCVal.forI128Parts(BigInt.zero, BigInt.from(4500)),
          XdrSCVal.forI128Parts(BigInt.zero, BigInt.from(5000)),
          XdrSCVal.forI128Parts(BigInt.zero, BigInt.from(950)),
        ],
      );

      List<String> neededSigners = tx.needsNonInvokerSigningBy();
      expect(neededSigners.length, 2);
      expect(neededSigners, contains(aliceKeyPair.accountId));
      expect(neededSigners, contains(bobKeyPair.accountId));

      // Local signing
      await tx.signAuthEntries(signerKeyPair: aliceKeyPair);
      await tx.signAuthEntries(signerKeyPair: bobKeyPair);

      GetTransactionResponse response = await tx.signAndSend();
      XdrSCVal? result = response.getResultValue();
      expect(result, isNotNull);
      expect(result!.discriminant, XdrSCValType.SCV_VOID);
    });

    test('soroban: Delegated Authorization', () async {
      // Snippet from soroban.md "Delegated Authorization"
      final SorobanServer server = SorobanServer(
        'https://soroban-testnet.stellar.org:443',
      );

      // Top-level credential account and a delegate signer's account
      final KeyPair topLevelKeyPair = KeyPair.fromSecretSeed(
        'SAAACAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUPB6NKI',
      );
      final KeyPair delegateKeyPair = KeyPair.fromSecretSeed(
        'SDJRWLCGLROL365KUWQG7OAAYHBNCNV7TJ7LG2GW5663XVZED6YU7HXB',
      );

      // An ADDRESS or ADDRESS_V2 entry bound to the top-level account. In practice
      // this comes from simulation (tx.simulationResponse!.sorobanAuth!.first);
      // it is built explicitly here so the snippet is self-contained.
      final SorobanAuthorizationEntry sourceEntry = SorobanAuthorizationEntry(
        SorobanCredentials.forAddressV2(
          SorobanAddressCredentials(
            Address.forAccountId(topLevelKeyPair.accountId),
            BigInt.from(1234), // nonce
            0, // signatureExpirationLedger (set by withDelegates below)
            XdrSCVal.forVoid(),
          ),
        ),
        SorobanAuthorizedInvocation(
          SorobanAuthorizedFunction.forContractFunction(
            Address.forContractId(
              'CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE',
            ),
            'swap',
            [],
          ),
        ),
      );

      // Set the expiration relative to the latest ledger.
      final GetLatestLedgerResponse latestLedger = await server
          .getLatestLedger();
      final int expirationLedger = latestLedger.sequence! + 100;

      // Build the WITH_DELEGATES entry. The builder sorts the delegate array,
      // rejects duplicates, and resets the top-level signature to void.
      SorobanAuthorizationEntry delegated =
          SorobanAuthorizationEntry.withDelegates(sourceEntry, [
            SorobanDelegateDescriptor(delegateKeyPair.accountId),
          ], expirationLedger);

      // The top-level account needs its own signature before submission.
      // When one node needs multiple classical (G-address) signatures, add them in
      // ascending public-key order. The host requires that order and the SDK
      // appends signatures in the order you call sign.
      delegated.sign(topLevelKeyPair, Network.TESTNET);

      // Delegate signer: forAddress routes the signature into the matching node
      // (top-level or any delegate, depth-first) and throws when no node matches.
      delegated.sign(
        delegateKeyPair,
        Network.TESTNET,
        forAddress: delegateKeyPair.accountId,
      );
      expect(
        SorobanAuthorizationEntry.carriesSignature(
          delegated.credentials.innerAddressCredentials!.signature,
        ),
        true,
      );
      expect(
        SorobanAuthorizationEntry.carriesSignature(
          delegated
              .credentials
              .addressWithDelegatesCredentials!
              .delegates
              .single
              .signature,
        ),
        true,
      );
      print('Both account nodes carry signatures');
    });
  });

  group('Type Conversions', () {
    test('soroban: Primitives', () {
      // Snippet from soroban.md "Primitives"
      XdrSCVal boolVal = XdrSCVal.forBool(true);
      expect(boolVal.b, true);

      XdrSCVal u32Val = XdrSCVal.forU32(42);
      expect(u32Val.u32?.uint32, 42);

      XdrSCVal i32Val = XdrSCVal.forI32(-42);
      expect(i32Val.i32?.int32, -42);

      XdrSCVal u64Val = XdrSCVal.forU64(BigInt.from(1000000));
      expect(u64Val.u64?.uint64, BigInt.from(1000000));

      XdrSCVal i64Val = XdrSCVal.forI64(BigInt.from(-1000000));
      expect(i64Val.i64?.int64, BigInt.from(-1000000));

      XdrSCVal stringVal = XdrSCVal.forString('Hello');
      expect(stringVal.str, 'Hello');

      XdrSCVal symbolVal = XdrSCVal.forSymbol('transfer');
      expect(symbolVal.sym, 'transfer');

      XdrSCVal voidVal = XdrSCVal.forVoid();
      expect(voidVal.discriminant, XdrSCValType.SCV_VOID);
    });

    test('soroban: Big Integers', () {
      // Snippet from soroban.md "Big Integers"
      XdrSCVal smallI128 = XdrSCVal.forI128BigInt(BigInt.from(42));
      expect(smallI128.i128, isNotNull);

      XdrSCVal partsVal = XdrSCVal.forI128Parts(BigInt.zero, BigInt.from(1000));
      expect(partsVal.i128, isNotNull);
    });

    test('soroban: Addresses', () {
      // Snippet from soroban.md "Addresses"
      // Account address (G...) - convenience method
      XdrSCVal account = XdrSCVal.forAccountAddress(
        'GAB2CB576PHBBPQ5ODORRZ2LYCMWPZGWGCN2KDK7DXOIMZASKUY3QZ6Q',
      );

      // Contract address (C...) - convenience method
      XdrSCVal contract = XdrSCVal.forContractAddress(
        'CCTHWH6DJQY6N2HSPVOFNKFT3FBM4MFBVEXXOAQ6UOS7BTML4JDRSXQP',
      );

      // Muxed contract address (W...) - convenience method
      XdrSCVal muxedContract = XdrSCVal.forMuxedContractAddress(
        'WA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAAAAAAAAAWWC',
      );

      Address muxed = Address.forMuxedContract(
        contractId: 'CA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUWDA',
        id: BigInt.zero,
      );
      Address parsedMuxed = Address.forMuxedContractId(muxed.muxedContractId!);

      // Via Address helper
      XdrSCVal addr = Address.forAccountId(
        'GAB2CB576PHBBPQ5ODORRZ2LYCMWPZGWGCN2KDK7DXOIMZASKUY3QZ6Q',
      ).toXdrSCVal();
      expect(
        account.address!.toStrKey(),
        'GAB2CB576PHBBPQ5ODORRZ2LYCMWPZGWGCN2KDK7DXOIMZASKUY3QZ6Q',
      );
      expect(
        contract.address!.toStrKey(),
        'CCTHWH6DJQY6N2HSPVOFNKFT3FBM4MFBVEXXOAQ6UOS7BTML4JDRSXQP',
      );
      expect(muxedContract.address!.toStrKey(), muxed.muxedContractId);
      expect(
        parsedMuxed.toXdrSCVal().toBase64EncodedXdrString(),
        muxedContract.toBase64EncodedXdrString(),
      );
      expect(addr.address!.toStrKey(), account.address!.toStrKey());
    });

    test('soroban: Collections', () {
      // Snippet from soroban.md "Collections"
      XdrSCVal vec = XdrSCVal.forVec([
        XdrSCVal.forSymbol('a'),
        XdrSCVal.forSymbol('b'),
      ]);
      expect(vec.vec, isNotNull);
      expect(vec.vec!.length, 2);

      XdrSCVal map = XdrSCVal.forMap([
        XdrSCMapEntry(XdrSCVal.forSymbol('age'), XdrSCVal.forU32(30)),
        XdrSCMapEntry(XdrSCVal.forSymbol('name'), XdrSCVal.forString('Alice')),
      ]);
      expect(map.map, isNotNull);
      expect(map.map!.length, 2);
      expect(
        compareScValHostOrder(map.map![0].key, map.map![1].key),
        lessThan(0),
      );
    });
  });

  group('Events', () {
    late SorobanServer server;
    late KeyPair keyPair;
    late String eventsContractId;
    late int eventLedger;

    setUpAll(() async {
      server = SorobanServer(rpcUrl);
      keyPair = KeyPair.random();
      await FriendBot.fundTestAccount(keyPair.accountId);

      // Install and deploy events contract
      final contractCode = await loadContractCode(eventsContractPath);
      String wasmHash = await SorobanClient.install(
        installRequest: InstallRequest(
          wasmBytes: contractCode,
          rpcUrl: rpcUrl,
          network: network,
          sourceAccountKeyPair: keyPair,
        ),
      );

      SorobanClient client = await SorobanClient.deploy(
        deployRequest: DeployRequest(
          rpcUrl: rpcUrl,
          network: network,
          sourceAccountKeyPair: keyPair,
          wasmHash: wasmHash,
        ),
      );
      eventsContractId = client.getContractId();

      // Invoke to emit an event
      XdrSCVal result = await client.invokeMethod(name: 'increment', args: []);
      expect(result.u32?.uint32, 1);

      // Get current ledger for event query
      GetLatestLedgerResponse latestLedger = await server.getLatestLedger();
      // Search from a few ledgers back
      eventLedger = latestLedger.sequence! - 100;
      if (eventLedger < 0) eventLedger = 1;
    });

    test('soroban: Basic Event Query', () async {
      // Snippet from soroban.md "Basic Event Query"
      GetEventsResponse response = await server.getEvents(
        GetEventsRequest(startLedger: eventLedger),
      );

      // Events may or may not contain our contract event depending on timing
      // Just verify the call works
      expect(response.isErrorResponse, false);
    });

    test('soroban: Filtering by Contract and Topic', () async {
      // Snippet from soroban.md "Filtering by Contract and Topic"
      EventFilter filter = EventFilter(
        type: 'contract',
        contractIds: [eventsContractId],
        topics: [
          TopicFilter([
            XdrSCVal.forSymbol('COUNTER').toBase64EncodedXdrString(),
            XdrSCVal.forSymbol('increment').toBase64EncodedXdrString(),
          ]),
        ],
      );

      GetEventsResponse response = await server.getEvents(
        GetEventsRequest(startLedger: eventLedger, filters: [filter]),
      );

      expect(response.isErrorResponse, false);
    });
  });

  group('ContractSpec', () {
    late KeyPair keyPair;
    late SorobanClient helloClient;

    setUpAll(() async {
      keyPair = KeyPair.random();
      await FriendBot.fundTestAccount(keyPair.accountId);

      final contractCode = await loadContractCode(helloContractPath);
      String wasmHash = await SorobanClient.install(
        installRequest: InstallRequest(
          wasmBytes: contractCode,
          rpcUrl: rpcUrl,
          network: network,
          sourceAccountKeyPair: keyPair,
        ),
      );

      helloClient = await SorobanClient.deploy(
        deployRequest: DeployRequest(
          rpcUrl: rpcUrl,
          network: network,
          sourceAccountKeyPair: keyPair,
          wasmHash: wasmHash,
        ),
      );
    });

    test('soroban: Using ContractSpec', () async {
      // Snippet from soroban.md "Using ContractSpec"
      ContractSpec spec = helloClient.getContractSpec();

      List<XdrSCSpecFunctionV0> functions = spec.funcs();
      expect(functions, isNotEmpty);

      XdrSCSpecFunctionV0? helloFunc = spec.getFunc('hello');
      expect(helloFunc, isNotNull);
      expect(helloFunc!.name, 'hello');

      // Use funcArgsToXdrSCValues
      List<XdrSCVal> args = spec.funcArgsToXdrSCValues('hello', {'to': 'Spec'});
      XdrSCVal result = await helloClient.invokeMethod(
        name: 'hello',
        args: args,
      );
      expect(result.vec![0].sym, 'Hello');
      expect(result.vec![1].sym, 'Spec');
    });
  });

  group('Contract Parser', () {
    test('soroban: Parse from Bytecode', () async {
      // Snippet from soroban.md "Parse from Bytecode"
      Uint8List bytecode = await loadContractCode(helloContractPath);
      SorobanContractInfo contractInfo =
          SorobanContractParser.parseContractByteCode(bytecode);

      expect(contractInfo.specEntries, isNotEmpty);

      // Verify we can find the hello function
      bool foundHello = false;
      for (XdrSCSpecEntry entry in contractInfo.specEntries) {
        if (entry.discriminant ==
            XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0) {
          if (entry.functionV0?.name == 'hello') {
            foundHello = true;
          }
        }
      }
      expect(foundHello, true);
    });

    test('soroban: Parse from Network', () async {
      // Snippet from soroban.md "Parse from Network"
      SorobanServer server = SorobanServer(rpcUrl);

      // Install the contract first to get a wasmId
      KeyPair kp = KeyPair.random();
      await FriendBot.fundTestAccount(kp.accountId);

      Uint8List contractCode = await loadContractCode(helloContractPath);
      String wasmId = await SorobanClient.install(
        installRequest: InstallRequest(
          wasmBytes: contractCode,
          rpcUrl: rpcUrl,
          network: network,
          sourceAccountKeyPair: kp,
        ),
      );

      SorobanContractInfo? contractInfo = await server
          .loadContractInfoForWasmId(wasmId);
      expect(contractInfo, isNotNull);

      ContractSpec spec = ContractSpec(contractInfo!.specEntries);
      List<XdrSCSpecFunctionV0> functions = spec.funcs();
      expect(functions, isNotEmpty);

      bool foundHello = false;
      for (XdrSCSpecFunctionV0 func in functions) {
        if (func.name == 'hello') {
          foundHello = true;
        }
      }
      expect(foundHello, true);
    });
  });

  group('Low-Level Operations', () {
    late KeyPair keyPair;
    late SorobanServer server;

    setUpAll(() async {
      keyPair = KeyPair.random();
      server = SorobanServer(rpcUrl);
      await FriendBot.fundTestAccount(keyPair.accountId);
    });

    test('soroban: Upload WASM (Low-Level)', () async {
      // Snippet from soroban.md "Upload WASM"
      Uint8List wasmBytes = await loadContractCode(helloContractPath);

      InvokeHostFunctionOperation uploadOp = InvokeHostFuncOpBuilder(
        UploadContractWasmHostFunction(wasmBytes),
      ).build();

      Account? account = await server.getAccount(keyPair.accountId);
      expect(account, isNotNull);
      Transaction tx = TransactionBuilder(
        account!,
      ).addOperation(uploadOp).build();

      SimulateTransactionResponse sim = await server.simulateTransaction(
        SimulateTransactionRequest(tx),
      );
      expect(sim.resultError, isNull);

      tx.sorobanTransactionData = sim.transactionData;
      tx.addResourceFee(sim.minResourceFee!);
      tx.sign(keyPair, network);

      SendTransactionResponse sendResponse = await server.sendTransaction(tx);
      expect(sendResponse.hash, isNotNull);

      // Poll for result
      GetTransactionResponse txResponse;
      do {
        await Future.delayed(Duration(seconds: 3));
        txResponse = await server.getTransaction(sendResponse.hash!);
      } while (txResponse.status == GetTransactionResponse.STATUS_NOT_FOUND);

      expect(txResponse.status, GetTransactionResponse.STATUS_SUCCESS);
      String? wasmHash = txResponse.getWasmId();
      expect(wasmHash, isNotNull);
    });

    test(
      'soroban: Direct authorization signing stamps unsigned simulation entries',
      () async {
        // Snippet from soroban.md "Direct Authorization Signing"
        final server = SorobanServer('https://soroban-testnet.stellar.org:443');
        final signer = KeyPair.fromSecretSeed(
          'SAAACAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUPB6NKI',
        );
        final entry = SorobanAuthorizationEntry(
          SorobanCredentials.forAddressV2(
            SorobanAddressCredentials(
              Address.forAccountId(signer.accountId),
              BigInt.one,
              0,
              XdrSCVal.forVoid(),
            ),
          ),
          SorobanAuthorizedInvocation(
            SorobanAuthorizedFunction.forContractFunction(
              Address.forContractId(
                'CA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUWDA',
              ),
              'swap',
              [],
            ),
          ),
        );
        final simResponse = SimulateTransactionResponse.fromJson({
          'result': {
            'latestLedger': 1,
            'minResourceFee': '0',
            'results': [
              {
                'auth': [entry.toBase64EncodedXdrString()],
                'xdr': XdrSCVal.forVoid().toBase64EncodedXdrString(),
              },
            ],
          },
        });
        final tx = TransactionBuilder(Account(signer.accountId, BigInt.one))
            .addOperation(
              InvokeHostFuncOpBuilder(
                InvokeContractHostFunction(
                  'CA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUWDA',
                  'swap',
                  arguments: [],
                ),
              ).build(),
            )
            .build();
        final latest = await server.getLatestLedger();
        await signSimulatedAuth(server, simResponse, tx, signer);
        final signed = (tx.operations.single as InvokeHostFunctionOperation)
            .auth
            .single
            .credentials
            .innerAddressCredentials!;
        expect(
          signed.signatureExpirationLedger,
          greaterThanOrEqualTo(latest.sequence! + 10),
        );
        expect(
          SorobanAuthorizationEntry.carriesSignature(signed.signature),
          true,
        );
        print('Simulation entry stamped and signed');
      },
    );
  });

  group('toNative conversion (offline)', () {
    test('soroban: toNative - Scalars and BigInt', () {
      // Snippet from soroban.md "Converting to Native Dart Values"
      XdrSCVal boolVal = XdrSCVal.forBool(true);
      expect(boolVal.toNative(), true);

      XdrSCVal u32Val = XdrSCVal.forU32(42);
      expect(u32Val.toNative(), 42);

      // u64 and wider integers always convert to BigInt, never int, so the
      // value stays exact on every platform this SDK targets, web included.
      XdrSCVal u64Val = XdrSCVal.forU64(BigInt.parse('18446744073709551615'));
      dynamic nativeU64 = u64Val.toNative();
      expect(nativeU64, isA<BigInt>());
      expect(nativeU64, BigInt.parse('18446744073709551615'));
    });

    test('soroban: toNative - Map keys in host order', () {
      // Snippet from soroban.md "Converting to Native Dart Values"
      XdrSCVal mapVal = XdrSCVal.forMap([
        XdrSCMapEntry(XdrSCVal.forSymbol('age'), XdrSCVal.forU32(30)),
        XdrSCMapEntry(XdrSCVal.forSymbol('name'), XdrSCVal.forString('Alice')),
      ]);

      expect(
        compareScValHostOrder(mapVal.map![0].key, mapVal.map![1].key),
        lessThan(0),
      );
      Map<dynamic, dynamic> native = mapVal.toNative() as Map<dynamic, dynamic>;
      print(native);
      print(native.keys.toList());
      expect(native, equals({'age': 30, 'name': 'Alice'}));
      expect(native.keys.toList(), equals(['age', 'name']));
    });

    test('soroban: toNative - Detecting a fallback', () {
      // Snippet from soroban.md "Converting to Native Dart Values"
      // A vec has no value equality, so it cannot serve as a map key: the
      // whole map falls back to the XdrSCVal itself.
      XdrSCVal mapWithVecKey = XdrSCVal.forMap([
        XdrSCMapEntry(
          XdrSCVal.forVec([XdrSCVal.forBool(true)]),
          XdrSCVal.forU32(1),
        ),
      ]);

      dynamic native = mapWithVecKey.toNative();
      expect(native is XdrSCVal, true);
      expect(native, same(mapWithVecKey));
    });
  });
}

// The simulation response, the transaction it simulated, and the authorizing
// keypair come from the surrounding flow and enter as parameters.
Future<void> signSimulatedAuth(
  SorobanServer server,
  SimulateTransactionResponse simResponse,
  Transaction tx,
  KeyPair signerKeyPair,
) async {
  // Get auth entries from simulation
  List<SorobanAuthorizationEntry>? auth = simResponse.sorobanAuth;
  GetLatestLedgerResponse latestLedger = await server.getLatestLedger();

  if (auth != null) {
    for (SorobanAuthorizationEntry entry in auth) {
      // These entries come from simulation and carry no signature.
      entry.credentials.innerAddressCredentials?.signatureExpirationLedger =
          latestLedger.sequence! + 10;

      // Sign the entry
      entry.sign(signerKeyPair, Network.TESTNET);
    }
  }

  // Set signed auth on transaction
  tx.setSorobanAuth(auth);
}
