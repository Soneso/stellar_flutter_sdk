// Focused unit tests for directly testable SorobanClient paths
// Tests configuration classes and error conditions that don't require mocking internal classes

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('SorobanClient.forClientOptions - Network Error Handling', () {
    test('throws exception when RPC URL is unreachable', () async {
      final keyPair = KeyPair.random();
      final options = ClientOptions(
        sourceAccountKeyPair: keyPair,
        contractId: 'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK',
        network: Network.TESTNET,
        rpcUrl: 'https://nonexistent-server-12345.invalid',
      );

      expect(
        () async => await SorobanClient.forClientOptions(options: options),
        throwsA(anything),
      );
    });

    test('throws exception with invalid contract ID format', () async {
      final keyPair = KeyPair.random();
      final options = ClientOptions(
        sourceAccountKeyPair: keyPair,
        contractId: 'INVALID',
        network: Network.TESTNET,
        rpcUrl: 'https://soroban-testnet.stellar.org',
      );

      expect(
        () async => await SorobanClient.forClientOptions(options: options),
        throwsA(anything),
      );
    });

    test('handles server logging configuration', () {
      final keyPair = KeyPair.random();
      final optionsDisabled = ClientOptions(
        sourceAccountKeyPair: keyPair,
        contractId: 'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK',
        network: Network.TESTNET,
        rpcUrl: 'https://test.example.com',
        enableServerLogging: false,
      );

      final optionsEnabled = ClientOptions(
        sourceAccountKeyPair: keyPair,
        contractId: 'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK',
        network: Network.TESTNET,
        rpcUrl: 'https://test.example.com',
        enableServerLogging: true,
      );

      expect(optionsDisabled.enableServerLogging, false);
      expect(optionsEnabled.enableServerLogging, true);
    });
  });

  group('SorobanClient.install - Parameter Validation', () {
    test('accepts various wasm byte sizes', () {
      final keyPair = KeyPair.random();

      // Empty wasm
      final emptyRequest = InstallRequest(
        wasmBytes: Uint8List(0),
        sourceAccountKeyPair: keyPair,
        network: Network.TESTNET,
        rpcUrl: 'https://test.example.com',
      );
      expect(emptyRequest.wasmBytes.length, 0);

      // Small wasm
      final smallRequest = InstallRequest(
        wasmBytes: Uint8List.fromList([0, 97, 115, 109]),
        sourceAccountKeyPair: keyPair,
        network: Network.TESTNET,
        rpcUrl: 'https://test.example.com',
      );
      expect(smallRequest.wasmBytes.length, 4);

      // Large wasm
      final largeRequest = InstallRequest(
        wasmBytes: Uint8List(100000),
        sourceAccountKeyPair: keyPair,
        network: Network.TESTNET,
        rpcUrl: 'https://test.example.com',
      );
      expect(largeRequest.wasmBytes.length, 100000);
    });

    test('handles different network types', () {
      final keyPair = KeyPair.random();
      final wasmBytes = Uint8List.fromList([0, 97, 115, 109]);

      final testnetRequest = InstallRequest(
        wasmBytes: wasmBytes,
        sourceAccountKeyPair: keyPair,
        network: Network.TESTNET,
        rpcUrl: 'https://soroban-testnet.stellar.org',
      );
      expect(testnetRequest.network, Network.TESTNET);

      final publicRequest = InstallRequest(
        wasmBytes: wasmBytes,
        sourceAccountKeyPair: keyPair,
        network: Network.PUBLIC,
        rpcUrl: 'https://soroban-mainnet.stellar.org',
      );
      expect(publicRequest.network, Network.PUBLIC);

      final customNetwork = Network('custom passphrase');
      final customRequest = InstallRequest(
        wasmBytes: wasmBytes,
        sourceAccountKeyPair: keyPair,
        network: customNetwork,
        rpcUrl: 'https://custom.example.com',
      );
      expect(customRequest.network.networkPassphrase, 'custom passphrase');
    });

    test('preserves logging configuration', () {
      final keyPair = KeyPair.random();
      final wasmBytes = Uint8List.fromList([0, 97, 115, 109]);

      final disabledRequest = InstallRequest(
        wasmBytes: wasmBytes,
        sourceAccountKeyPair: keyPair,
        network: Network.TESTNET,
        rpcUrl: 'https://test.example.com',
        enableSorobanServerLogging: false,
      );
      expect(disabledRequest.enableSorobanServerLogging, false);

      final enabledRequest = InstallRequest(
        wasmBytes: wasmBytes,
        sourceAccountKeyPair: keyPair,
        network: Network.TESTNET,
        rpcUrl: 'https://test.example.com',
        enableSorobanServerLogging: true,
      );
      expect(enabledRequest.enableSorobanServerLogging, true);
    });
  });

  group('SorobanClient.deploy - Parameter Combinations', () {
    test('handles all constructor arg combinations', () {
      final keyPair = KeyPair.random();

      // No constructor args
      final noArgsRequest = DeployRequest(
        sourceAccountKeyPair: keyPair,
        network: Network.TESTNET,
        rpcUrl: 'https://test.example.com',
        wasmHash: 'abc123',
      );
      expect(noArgsRequest.constructorArgs, isNull);

      // Single constructor arg
      final singleArgRequest = DeployRequest(
        sourceAccountKeyPair: keyPair,
        network: Network.TESTNET,
        rpcUrl: 'https://test.example.com',
        wasmHash: 'abc123',
        constructorArgs: [XdrSCVal.forU32(42)],
      );
      expect(singleArgRequest.constructorArgs!.length, 1);

      // Multiple constructor args of different types
      final multiArgRequest = DeployRequest(
        sourceAccountKeyPair: keyPair,
        network: Network.TESTNET,
        rpcUrl: 'https://test.example.com',
        wasmHash: 'abc123',
        constructorArgs: [
          XdrSCVal.forU32(1),
          XdrSCVal.forU64(BigInt.from(100)),
          XdrSCVal.forI32(-5),
          XdrSCVal.forBool(true),
          XdrSCVal.forSymbol('test'),
          XdrSCVal.forString('hello'),
          XdrSCVal.forVoid(),
        ],
      );
      expect(multiArgRequest.constructorArgs!.length, 7);
    });

    test('handles salt variations', () {
      final keyPair = KeyPair.random();

      // No salt
      final noSaltRequest = DeployRequest(
        sourceAccountKeyPair: keyPair,
        network: Network.TESTNET,
        rpcUrl: 'https://test.example.com',
        wasmHash: 'abc123',
      );
      expect(noSaltRequest.salt, isNull);

      // Zero salt
      final zeroSalt = XdrUint256(Uint8List.fromList(List.filled(32, 0)));
      final zeroSaltRequest = DeployRequest(
        sourceAccountKeyPair: keyPair,
        network: Network.TESTNET,
        rpcUrl: 'https://test.example.com',
        wasmHash: 'abc123',
        salt: zeroSalt,
      );
      expect(zeroSaltRequest.salt, isNotNull);

      // Max salt
      final maxSalt = XdrUint256(Uint8List.fromList(List.filled(32, 255)));
      final maxSaltRequest = DeployRequest(
        sourceAccountKeyPair: keyPair,
        network: Network.TESTNET,
        rpcUrl: 'https://test.example.com',
        wasmHash: 'abc123',
        salt: maxSalt,
      );
      expect(maxSaltRequest.salt, isNotNull);

      // Custom salt
      final customSalt = XdrUint256(Uint8List.fromList(
        List.generate(32, (i) => i * 7 % 256),
      ));
      final customSaltRequest = DeployRequest(
        sourceAccountKeyPair: keyPair,
        network: Network.TESTNET,
        rpcUrl: 'https://test.example.com',
        wasmHash: 'abc123',
        salt: customSalt,
      );
      expect(customSaltRequest.salt, isNotNull);
    });

    test('uses default method options when not specified', () {
      final keyPair = KeyPair.random();
      final request = DeployRequest(
        sourceAccountKeyPair: keyPair,
        network: Network.TESTNET,
        rpcUrl: 'https://test.example.com',
        wasmHash: 'abc123',
      );

      expect(request.methodOptions.fee, NetworkConstants.DEFAULT_SOROBAN_BASE_FEE);
      expect(request.methodOptions.timeoutInSeconds, NetworkConstants.DEFAULT_TIMEOUT_SECONDS);
      expect(request.methodOptions.simulate, true);
      expect(request.methodOptions.restore, false);
    });

    test('accepts custom method options', () {
      final keyPair = KeyPair.random();
      final customOptions = MethodOptions(
        fee: 5000,
        timeoutInSeconds: 120,
        simulate: false,
        restore: true,
      );

      final request = DeployRequest(
        sourceAccountKeyPair: keyPair,
        network: Network.TESTNET,
        rpcUrl: 'https://test.example.com',
        wasmHash: 'abc123',
        methodOptions: customOptions,
      );

      expect(request.methodOptions.fee, 5000);
      expect(request.methodOptions.timeoutInSeconds, 120);
      expect(request.methodOptions.simulate, false);
      expect(request.methodOptions.restore, true);
    });

    test('handles all optional fields together', () {
      final keyPair = KeyPair.random();
      final args = [XdrSCVal.forU32(100), XdrSCVal.forU32(200)];
      final salt = XdrUint256(Uint8List.fromList(List.filled(32, 42)));
      final options = MethodOptions(fee: 2000, timeoutInSeconds: 90);

      final request = DeployRequest(
        sourceAccountKeyPair: keyPair,
        network: Network.PUBLIC,
        rpcUrl: 'https://soroban.stellar.org',
        wasmHash: 'fullhash123',
        constructorArgs: args,
        salt: salt,
        methodOptions: options,
        enableSorobanServerLogging: true,
      );

      expect(request.constructorArgs!.length, 2);
      expect(request.salt, isNotNull);
      expect(request.methodOptions.fee, 2000);
      expect(request.methodOptions.timeoutInSeconds, 90);
      expect(request.enableSorobanServerLogging, true);
    });
  });

  group('MethodOptions - Edge Cases', () {
    test('handles extreme fee values', () {
      final zeroFee = MethodOptions(fee: 0);
      expect(zeroFee.fee, 0);

      final lowFee = MethodOptions(fee: 1);
      expect(lowFee.fee, 1);

      final highFee = MethodOptions(fee: 1000000);
      expect(highFee.fee, 1000000);

      final maxFee = MethodOptions(fee: 9223372036854775807); // Max int64
      expect(maxFee.fee, 9223372036854775807);
    });

    test('handles extreme timeout values', () {
      final minTimeout = MethodOptions(timeoutInSeconds: 1);
      expect(minTimeout.timeoutInSeconds, 1);

      final lowTimeout = MethodOptions(timeoutInSeconds: 10);
      expect(lowTimeout.timeoutInSeconds, 10);

      final normalTimeout = MethodOptions(timeoutInSeconds: 300);
      expect(normalTimeout.timeoutInSeconds, 300);

      final highTimeout = MethodOptions(timeoutInSeconds: 3600);
      expect(highTimeout.timeoutInSeconds, 3600);

      final veryHighTimeout = MethodOptions(timeoutInSeconds: 86400);
      expect(veryHighTimeout.timeoutInSeconds, 86400);
    });

    test('handles all boolean flag combinations', () {
      final allFalse = MethodOptions(simulate: false, restore: false);
      expect(allFalse.simulate, false);
      expect(allFalse.restore, false);

      final simulateOnly = MethodOptions(simulate: true, restore: false);
      expect(simulateOnly.simulate, true);
      expect(simulateOnly.restore, false);

      final restoreOnly = MethodOptions(simulate: false, restore: true);
      expect(restoreOnly.simulate, false);
      expect(restoreOnly.restore, true);

      final allTrue = MethodOptions(simulate: true, restore: true);
      expect(allTrue.simulate, true);
      expect(allTrue.restore, true);
    });
  });

  group('AssembledTransactionOptions - Argument Types', () {
    test('handles null arguments', () {
      final keyPair = KeyPair.random();
      final clientOptions = ClientOptions(
        sourceAccountKeyPair: keyPair,
        contractId: 'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK',
        network: Network.TESTNET,
        rpcUrl: 'https://test.example.com',
      );

      final options = AssembledTransactionOptions(
        clientOptions: clientOptions,
        methodOptions: MethodOptions(),
        method: 'no_args',
      );

      expect(options.arguments, isNull);
    });

    test('handles empty arguments list', () {
      final keyPair = KeyPair.random();
      final clientOptions = ClientOptions(
        sourceAccountKeyPair: keyPair,
        contractId: 'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK',
        network: Network.TESTNET,
        rpcUrl: 'https://test.example.com',
      );

      final options = AssembledTransactionOptions(
        clientOptions: clientOptions,
        methodOptions: MethodOptions(),
        method: 'empty_args',
        arguments: [],
      );

      expect(options.arguments, isNotNull);
      expect(options.arguments!.length, 0);
    });

    test('handles all XDR value types', () {
      final keyPair = KeyPair.random();
      final clientOptions = ClientOptions(
        sourceAccountKeyPair: keyPair,
        contractId: 'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK',
        network: Network.TESTNET,
        rpcUrl: 'https://test.example.com',
      );

      final args = [
        // Integer types
        XdrSCVal.forU32(4294967295), // Max u32
        XdrSCVal.forU64(BigInt.parse('18446744073709551615')), // Max u64
        XdrSCVal.forI32(2147483647), // Max i32
        XdrSCVal.forI32(-2147483648), // Min i32
        XdrSCVal.forI64(BigInt.parse('9223372036854775807')), // Max i64
        XdrSCVal.forI64(BigInt.parse('-9223372036854775808')), // Min i64
        XdrSCVal.forI128Parts(BigInt.zero, BigInt.from(999)),
        XdrSCVal.forU128Parts(BigInt.zero, BigInt.from(123)),
        XdrSCVal.forI256Parts(BigInt.zero, BigInt.zero, BigInt.zero, BigInt.from(456)),
        XdrSCVal.forU256Parts(BigInt.zero, BigInt.zero, BigInt.zero, BigInt.from(789)),

        // Boolean
        XdrSCVal.forBool(true),
        XdrSCVal.forBool(false),

        // Void
        XdrSCVal.forVoid(),

        // Strings and symbols
        XdrSCVal.forString(''),
        XdrSCVal.forString('test string'),
        XdrSCVal.forSymbol(''),
        XdrSCVal.forSymbol('test_symbol'),

        // Bytes
        XdrSCVal.forBytes(Uint8List(0)),
        XdrSCVal.forBytes(Uint8List.fromList([1, 2, 3])),
        XdrSCVal.forBytes(Uint8List.fromList(List.generate(1000, (i) => i % 256))),

        // Collections
        XdrSCVal.forVec([]),
        XdrSCVal.forVec([XdrSCVal.forU32(1), XdrSCVal.forU32(2)]),
      ];

      final options = AssembledTransactionOptions(
        clientOptions: clientOptions,
        methodOptions: MethodOptions(),
        method: 'all_types',
        arguments: args,
      );

      expect(options.arguments!.length, greaterThan(20));
    });
  });

  group('SimulateHostFunctionResult - Construction', () {
    test('handles all result variations', () {
      final txData = XdrSorobanTransactionData(
        XdrSorobanTransactionDataExt(0),
        XdrSorobanResources(
          XdrLedgerFootprint([], []),
          XdrUint32(1000),
          XdrUint32(2000),
          XdrUint32(3000),
        ),
        XdrInt64(BigInt.from(100)),
      );

      // Null auth
      final resultNull = SimulateHostFunctionResult(null, txData, XdrSCVal.forVoid());
      expect(resultNull.auth, isNull);

      // Empty auth list
      final resultEmpty = SimulateHostFunctionResult([], txData, XdrSCVal.forU32(42));
      expect(resultEmpty.auth!.length, 0);

      // Different return types
      final resultVoid = SimulateHostFunctionResult(null, txData, XdrSCVal.forVoid());
      expect(resultVoid.returnedValue.discriminant, XdrSCValType.SCV_VOID);

      final resultU32 = SimulateHostFunctionResult(null, txData, XdrSCVal.forU32(123));
      expect(resultU32.returnedValue.u32!.uint32, 123);

      final resultBool = SimulateHostFunctionResult(null, txData, XdrSCVal.forBool(false));
      expect(resultBool.returnedValue.b, false);

      final resultString = SimulateHostFunctionResult(null, txData, XdrSCVal.forString('test'));
      expect(resultString.returnedValue.str, isNotNull);
    });

    test('handles complex footprints', () {
      final readOnlyEntries = [
        XdrLedgerKey(XdrLedgerEntryType.CONTRACT_DATA),
        XdrLedgerKey(XdrLedgerEntryType.CONTRACT_CODE),
      ];

      final readWriteEntries = [
        XdrLedgerKey(XdrLedgerEntryType.CONTRACT_DATA),
        XdrLedgerKey(XdrLedgerEntryType.ACCOUNT),
      ];

      final txData = XdrSorobanTransactionData(
        XdrSorobanTransactionDataExt(0),
        XdrSorobanResources(
          XdrLedgerFootprint(readOnlyEntries, readWriteEntries),
          XdrUint32(5000),
          XdrUint32(10000),
          XdrUint32(15000),
        ),
        XdrInt64(BigInt.from(2000)),
      );

      final result = SimulateHostFunctionResult(null, txData, XdrSCVal.forVoid());

      expect(result.transactionData.resources.footprint.readOnly.length, 2);
      expect(result.transactionData.resources.footprint.readWrite.length, 2);
      expect(result.transactionData.resources.instructions.uint32, 5000);
      expect(result.transactionData.resources.diskReadBytes.uint32, 10000);
      expect(result.transactionData.resources.writeBytes.uint32, 15000);
      expect(result.transactionData.resourceFee.int64, BigInt.from(2000));
    });
  });

  group('ClientOptions - Keypair Variations', () {
    test('works with read-only keypairs', () {
      final sourceKeyPair = KeyPair.random();
      final publicOnly = KeyPair.fromAccountId(sourceKeyPair.accountId);

      final options = ClientOptions(
        sourceAccountKeyPair: publicOnly,
        contractId: 'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK',
        network: Network.TESTNET,
        rpcUrl: 'https://test.example.com',
      );

      expect(options.sourceAccountKeyPair.accountId, sourceKeyPair.accountId);
      expect(options.sourceAccountKeyPair.privateKey, isNull);
    });

    test('works with full keypairs', () {
      final sourceKeyPair = KeyPair.random();

      final options = ClientOptions(
        sourceAccountKeyPair: sourceKeyPair,
        contractId: 'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK',
        network: Network.TESTNET,
        rpcUrl: 'https://test.example.com',
      );

      expect(options.sourceAccountKeyPair.accountId, sourceKeyPair.accountId);
      expect(options.sourceAccountKeyPair.privateKey, isNotNull);
    });

    test('allows contractId modification', () {
      final keyPair = KeyPair.random();
      final options = ClientOptions(
        sourceAccountKeyPair: keyPair,
        contractId: 'COLD123',
        network: Network.TESTNET,
        rpcUrl: 'https://test.example.com',
      );

      expect(options.contractId, 'COLD123');
      options.contractId = 'CNEW456';
      expect(options.contractId, 'CNEW456');

      // Test multiple changes
      options.contractId = 'CTEST789';
      expect(options.contractId, 'CTEST789');
    });
  });

  group('RPC URL Variations', () {
    test('handles various RPC URL formats', () {
      final keyPair = KeyPair.random();
      final contractId = 'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK';

      // Standard HTTPS with port
      final https = ClientOptions(
        sourceAccountKeyPair: keyPair,
        contractId: contractId,
        network: Network.TESTNET,
        rpcUrl: 'https://soroban-testnet.stellar.org:443',
      );
      expect(https.rpcUrl, 'https://soroban-testnet.stellar.org:443');

      // HTTPS without port
      final httpsNoPort = ClientOptions(
        sourceAccountKeyPair: keyPair,
        contractId: contractId,
        network: Network.TESTNET,
        rpcUrl: 'https://soroban-testnet.stellar.org',
      );
      expect(httpsNoPort.rpcUrl, 'https://soroban-testnet.stellar.org');

      // HTTP localhost
      final localhost = ClientOptions(
        sourceAccountKeyPair: keyPair,
        contractId: contractId,
        network: Network.TESTNET,
        rpcUrl: 'http://localhost:8000',
      );
      expect(localhost.rpcUrl, 'http://localhost:8000');

      // With path
      final withPath = ClientOptions(
        sourceAccountKeyPair: keyPair,
        contractId: contractId,
        network: Network.TESTNET,
        rpcUrl: 'https://api.example.com/soroban/rpc',
      );
      expect(withPath.rpcUrl, 'https://api.example.com/soroban/rpc');

      // With subdomain
      final subdomain = ClientOptions(
        sourceAccountKeyPair: keyPair,
        contractId: contractId,
        network: Network.TESTNET,
        rpcUrl: 'https://testnet-soroban-123.example.com',
      );
      expect(subdomain.rpcUrl, 'https://testnet-soroban-123.example.com');
    });
  });
}
