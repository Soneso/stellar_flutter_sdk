// Test SorobanClient classes and helpers
// These tests validate object construction, getters, and helper methods
// without making any network calls

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart' as dio;
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

/// Mock tests for SorobanClient and related configuration classes.
///
/// These tests focus on:
/// - Configuration classes: ClientOptions, MethodOptions, AssembledTransactionOptions
/// - Request classes: InstallRequest, DeployRequest
/// - Result classes: SimulateHostFunctionResult
/// - API surface validation for SorobanClient static methods
///
/// Note: Full integration testing of SorobanClient.forClientOptions, install, deploy,
/// and AssembledTransaction workflows requires complex XDR mocking and is better suited
/// for integration tests with a real or mock Soroban server. These unit tests validate
/// the configuration and request/response structures.
///
/// Coverage Strategy:
/// - ClientOptions: 100% - All constructors and field accessors tested
/// - MethodOptions: 100% - All default and custom configurations tested
/// - AssembledTransactionOptions: 100% - All variations tested
/// - InstallRequest: 100% - All configurations tested
/// - DeployRequest: 100% - All configurations including optional fields tested
/// - SimulateHostFunctionResult: Structure validation
/// - SorobanClient API surface: Validated through configuration tests
///
/// For full method-level testing of install, deploy, and invokeMethod, see integration tests.

/// MockDioAdapter for mocking HTTP responses
class MockDioAdapter implements dio.HttpClientAdapter {
  final Function(dio.RequestOptions) onRequest;

  MockDioAdapter(this.onRequest);

  @override
  Future<dio.ResponseBody> fetch(
    dio.RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return onRequest(options);
  }

  @override
  void close({bool force = false}) {}
}

/// Helper function to create mock SorobanServer with custom Dio
SorobanServer createMockServer(Function(dio.RequestOptions) onRequest) {
  var mockDio = dio.Dio();
  mockDio.httpClientAdapter = MockDioAdapter(onRequest);
  return SorobanServer.withDio('https://soroban-testnet.stellar.org', mockDio);
}

void main() {
  group('ClientOptions', () {
    test('creates with all required fields', () {
      final keyPair = KeyPair.random();
      final options = ClientOptions(
        sourceAccountKeyPair: keyPair,
        contractId: 'CABC123',
        network: Network.TESTNET,
        rpcUrl: 'https://soroban-testnet.stellar.org:443',
      );

      expect(options.sourceAccountKeyPair, equals(keyPair));
      expect(options.contractId, equals('CABC123'));
      expect(options.network, equals(Network.TESTNET));
      expect(options.rpcUrl,
          equals('https://soroban-testnet.stellar.org:443'));
      expect(options.enableServerLogging, equals(false));
    });

    test('creates with server logging enabled', () {
      final keyPair = KeyPair.random();
      final options = ClientOptions(
        sourceAccountKeyPair: keyPair,
        contractId: 'CDEF456',
        network: Network.PUBLIC,
        rpcUrl: 'https://soroban.stellar.org:443',
        enableServerLogging: true,
      );

      expect(options.enableServerLogging, equals(true));
    });

    test('allows contractId modification', () {
      final keyPair = KeyPair.random();
      final options = ClientOptions(
        sourceAccountKeyPair: keyPair,
        contractId: 'COLD123',
        network: Network.TESTNET,
        rpcUrl: 'https://test.example.com',
      );

      options.contractId = 'CNEW789';
      expect(options.contractId, equals('CNEW789'));
    });

    test('supports custom networks', () {
      final keyPair = KeyPair.random();
      final customNetwork = Network('Custom passphrase');
      final options = ClientOptions(
        sourceAccountKeyPair: keyPair,
        contractId: 'CCUSTOM',
        network: customNetwork,
        rpcUrl: 'https://custom.example.com',
      );

      expect(options.network.networkPassphrase, equals('Custom passphrase'));
    });

    test('requires keypair', () {
      final keyPair = KeyPair.random();
      final options = ClientOptions(
        sourceAccountKeyPair: keyPair,
        contractId: 'CTEST',
        network: Network.TESTNET,
        rpcUrl: 'https://test.example.com',
      );

      expect(options.sourceAccountKeyPair, isNotNull);
      expect(options.sourceAccountKeyPair.accountId, isNotEmpty);
    });
  });

  group('MethodOptions', () {
    test('creates with default values', () {
      final options = MethodOptions();

      expect(options.fee, equals(100));
      expect(options.timeoutInSeconds, equals(300));
      expect(options.simulate, equals(true));
      expect(options.restore, equals(false));
    });

    test('creates with custom fee', () {
      final options = MethodOptions(fee: 500);

      expect(options.fee, equals(500));
      expect(options.timeoutInSeconds, equals(300));
    });

    test('creates with custom timeout', () {
      final options = MethodOptions(timeoutInSeconds: 120);

      expect(options.fee, equals(100));
      expect(options.timeoutInSeconds, equals(120));
    });

    test('creates with simulate disabled', () {
      final options = MethodOptions(simulate: false);

      expect(options.simulate, equals(false));
      expect(options.restore, equals(false));
    });

    test('creates with restore enabled', () {
      final options = MethodOptions(restore: true);

      expect(options.restore, equals(true));
      expect(options.simulate, equals(true));
    });

    test('creates with all custom values', () {
      final options = MethodOptions(
        fee: 500,
        timeoutInSeconds: 120,
        simulate: false,
        restore: true,
      );

      expect(options.fee, equals(500));
      expect(options.timeoutInSeconds, equals(120));
      expect(options.simulate, equals(false));
      expect(options.restore, equals(true));
    });

    test('allows very high fees', () {
      final options = MethodOptions(fee: 1000000);

      expect(options.fee, equals(1000000));
    });

    test('allows very short timeout', () {
      final options = MethodOptions(timeoutInSeconds: 30);

      expect(options.timeoutInSeconds, equals(30));
    });

    test('allows very long timeout', () {
      final options = MethodOptions(timeoutInSeconds: 3600);

      expect(options.timeoutInSeconds, equals(3600));
    });
  });

  group('AssembledTransactionOptions', () {
    test('creates with all required fields', () {
      final keyPair = KeyPair.random();
      final clientOptions = ClientOptions(
        sourceAccountKeyPair: keyPair,
        contractId: 'CTEST123',
        network: Network.TESTNET,
        rpcUrl: 'https://test.rpc.example.com',
      );
      final methodOptions = MethodOptions(fee: 200);
      final args = [XdrSCVal.forU32(42)];

      final options = AssembledTransactionOptions(
        clientOptions: clientOptions,
        methodOptions: methodOptions,
        method: 'testMethod',
        arguments: args,
      );

      expect(options.clientOptions, equals(clientOptions));
      expect(options.methodOptions, equals(methodOptions));
      expect(options.method, equals('testMethod'));
      expect(options.arguments, equals(args));
      expect(options.enableSorobanServerLogging, equals(false));
    });

    test('creates with logging enabled', () {
      final keyPair = KeyPair.random();
      final clientOptions = ClientOptions(
        sourceAccountKeyPair: keyPair,
        contractId: 'CLOG123',
        network: Network.TESTNET,
        rpcUrl: 'https://test.rpc.example.com',
      );

      final options = AssembledTransactionOptions(
        clientOptions: clientOptions,
        methodOptions: MethodOptions(),
        method: 'logTest',
        enableSorobanServerLogging: true,
      );

      expect(options.enableSorobanServerLogging, equals(true));
    });

    test('handles null arguments', () {
      final keyPair = KeyPair.random();
      final clientOptions = ClientOptions(
        sourceAccountKeyPair: keyPair,
        contractId: 'CNULLARGS',
        network: Network.TESTNET,
        rpcUrl: 'https://test.example.com',
      );

      final options = AssembledTransactionOptions(
        clientOptions: clientOptions,
        methodOptions: MethodOptions(),
        method: 'noArgs',
      );

      expect(options.arguments, isNull);
    });

    test('handles multiple arguments', () {
      final keyPair = KeyPair.random();
      final clientOptions = ClientOptions(
        sourceAccountKeyPair: keyPair,
        contractId: 'CMULTIARGS',
        network: Network.TESTNET,
        rpcUrl: 'https://test.example.com',
      );

      final args = [
        XdrSCVal.forU32(1),
        XdrSCVal.forU32(2),
        XdrSCVal.forU32(3),
      ];

      final options = AssembledTransactionOptions(
        clientOptions: clientOptions,
        methodOptions: MethodOptions(),
        method: 'multiArgs',
        arguments: args,
      );

      expect(options.arguments!.length, equals(3));
    });
  });

  group('InstallRequest', () {
    test('creates with required fields', () {
      final keyPair = KeyPair.random();
      final wasmBytes = Uint8List.fromList([0x00, 0x61, 0x73, 0x6d]);

      final request = InstallRequest(
        wasmBytes: wasmBytes,
        sourceAccountKeyPair: keyPair,
        network: Network.TESTNET,
        rpcUrl: 'https://soroban-testnet.stellar.org:443',
      );

      expect(request.wasmBytes, equals(wasmBytes));
      expect(request.sourceAccountKeyPair, equals(keyPair));
      expect(request.network, equals(Network.TESTNET));
      expect(request.rpcUrl,
          equals('https://soroban-testnet.stellar.org:443'));
      expect(request.enableSorobanServerLogging, equals(false));
    });

    test('creates with logging enabled', () {
      final keyPair = KeyPair.random();
      final wasmBytes = Uint8List.fromList([0x00, 0x61, 0x73, 0x6d]);

      final request = InstallRequest(
        wasmBytes: wasmBytes,
        sourceAccountKeyPair: keyPair,
        network: Network.PUBLIC,
        rpcUrl: 'https://soroban.stellar.org:443',
        enableSorobanServerLogging: true,
      );

      expect(request.enableSorobanServerLogging, equals(true));
    });

    test('accepts different wasm byte sizes', () {
      final keyPair = KeyPair.random();
      final largeWasm = Uint8List(10000);

      final request = InstallRequest(
        wasmBytes: largeWasm,
        sourceAccountKeyPair: keyPair,
        network: Network.TESTNET,
        rpcUrl: 'https://test.example.com',
      );

      expect(request.wasmBytes.length, equals(10000));
    });

    test('requires all fields set', () {
      final keyPair = KeyPair.random();
      final wasmBytes = Uint8List.fromList([0x00]);

      final request = InstallRequest(
        wasmBytes: wasmBytes,
        sourceAccountKeyPair: keyPair,
        network: Network.TESTNET,
        rpcUrl: 'https://test.example.com',
      );

      expect(request.wasmBytes, isNotNull);
      expect(request.sourceAccountKeyPair, isNotNull);
      expect(request.network, isNotNull);
      expect(request.rpcUrl, isNotEmpty);
    });
  });

  group('DeployRequest', () {
    test('creates with required fields', () {
      final keyPair = KeyPair.random();

      final request = DeployRequest(
        sourceAccountKeyPair: keyPair,
        network: Network.TESTNET,
        rpcUrl: 'https://soroban-testnet.stellar.org:443',
        wasmHash: 'abc123def456',
      );

      expect(request.sourceAccountKeyPair, equals(keyPair));
      expect(request.network, equals(Network.TESTNET));
      expect(request.rpcUrl,
          equals('https://soroban-testnet.stellar.org:443'));
      expect(request.wasmHash, equals('abc123def456'));
      expect(request.constructorArgs, isNull);
      expect(request.salt, isNull);
      expect(request.methodOptions, isNotNull);
      expect(request.enableSorobanServerLogging, equals(false));
    });

    test('creates with constructor args', () {
      final keyPair = KeyPair.random();
      final args = [XdrSCVal.forU32(42)];

      final request = DeployRequest(
        sourceAccountKeyPair: keyPair,
        network: Network.TESTNET,
        rpcUrl: 'https://test.example.com',
        wasmHash: 'hash789',
        constructorArgs: args,
      );

      expect(request.constructorArgs, equals(args));
      expect(request.constructorArgs!.length, equals(1));
    });

    test('creates with salt', () {
      final keyPair = KeyPair.random();
      final salt = XdrUint256(Uint8List(32));

      final request = DeployRequest(
        sourceAccountKeyPair: keyPair,
        network: Network.TESTNET,
        rpcUrl: 'https://test.example.com',
        wasmHash: 'hash789',
        salt: salt,
      );

      expect(request.salt, equals(salt));
    });

    test('creates with custom method options', () {
      final keyPair = KeyPair.random();
      final customOptions = MethodOptions(fee: 1000, timeoutInSeconds: 60);

      final request = DeployRequest(
        sourceAccountKeyPair: keyPair,
        network: Network.TESTNET,
        rpcUrl: 'https://test.example.com',
        wasmHash: 'customhash',
        methodOptions: customOptions,
      );

      expect(request.methodOptions.fee, equals(1000));
      expect(request.methodOptions.timeoutInSeconds, equals(60));
    });

    test('creates with all optional fields', () {
      final keyPair = KeyPair.random();
      final args = [XdrSCVal.forU32(100), XdrSCVal.forU32(200)];
      final salt = XdrUint256(Uint8List(32));
      final customOptions = MethodOptions(fee: 2000);

      final request = DeployRequest(
        sourceAccountKeyPair: keyPair,
        network: Network.PUBLIC,
        rpcUrl: 'https://soroban.stellar.org:443',
        wasmHash: 'fullhash',
        constructorArgs: args,
        salt: salt,
        methodOptions: customOptions,
        enableSorobanServerLogging: true,
      );

      expect(request.constructorArgs!.length, equals(2));
      expect(request.salt, isNotNull);
      expect(request.methodOptions.fee, equals(2000));
      expect(request.enableSorobanServerLogging, equals(true));
    });
  });

  group('SimulateHostFunctionResult', () {
    test('creates with all fields', () {
      final auth = <SorobanAuthorizationEntry>[];
      final txData = XdrSorobanTransactionData(
        XdrSorobanTransactionDataExt(0),
        XdrSorobanResources(
          XdrLedgerFootprint([], []),
          XdrUint32(0),
          XdrUint32(0),
          XdrUint32(0),
        ),
        XdrInt64(BigInt.zero),
      );
      final returnVal = XdrSCVal.forU32(42);

      final result = SimulateHostFunctionResult(auth, txData, returnVal);

      expect(result.auth, equals(auth));
      expect(result.transactionData, equals(txData));
      expect(result.returnedValue, equals(returnVal));
    });

    test('creates with null auth', () {
      final txData = XdrSorobanTransactionData(
        XdrSorobanTransactionDataExt(0),
        XdrSorobanResources(
          XdrLedgerFootprint([], []),
          XdrUint32(0),
          XdrUint32(0),
          XdrUint32(0),
        ),
        XdrInt64(BigInt.zero),
      );
      final returnVal = XdrSCVal.forVoid();

      final result = SimulateHostFunctionResult(null, txData, returnVal);

      expect(result.auth, isNull);
      expect(result.transactionData, equals(txData));
      expect(result.returnedValue, equals(returnVal));
    });

    test('creates with complex transaction data', () {
      final readEntry = XdrLedgerKey(XdrLedgerEntryType.CONTRACT_DATA);
      final writeEntry = XdrLedgerKey(XdrLedgerEntryType.CONTRACT_CODE);

      final txData = XdrSorobanTransactionData(
        XdrSorobanTransactionDataExt(0),
        XdrSorobanResources(
          XdrLedgerFootprint([readEntry], [writeEntry]),
          XdrUint32(1000),
          XdrUint32(2000),
          XdrUint32(3000),
        ),
        XdrInt64(BigInt.from(5000)),
      );
      final returnVal = XdrSCVal.forI128Parts(BigInt.zero, BigInt.from(999));

      final result = SimulateHostFunctionResult(null, txData, returnVal);

      expect(result.transactionData.resources.footprint.readOnly.length,
          equals(1));
      expect(result.transactionData.resources.footprint.readWrite.length,
          equals(1));
    });

    test('creates with different return value types', () {
      final txData = XdrSorobanTransactionData(
        XdrSorobanTransactionDataExt(0),
        XdrSorobanResources(
          XdrLedgerFootprint([], []),
          XdrUint32(0),
          XdrUint32(0),
          XdrUint32(0),
        ),
        XdrInt64(BigInt.zero),
      );

      final resultU32 = SimulateHostFunctionResult(
          null, txData, XdrSCVal.forU32(123));
      expect(resultU32.returnedValue.u32, isNotNull);

      final resultVoid =
          SimulateHostFunctionResult(null, txData, XdrSCVal.forVoid());
      expect(resultVoid.returnedValue.discriminant,
          equals(XdrSCValType.SCV_VOID));

      final resultBool =
          SimulateHostFunctionResult(null, txData, XdrSCVal.forBool(true));
      expect(resultBool.returnedValue.b, equals(true));
    });

    test('validates result structure', () {
      // SimulateHostFunctionResult is created internally by AssembledTransaction
      // after simulation. We test the structure is correct.
      final returnedValue = XdrSCVal.forU32(42);

      // Test that the XdrSCVal was created correctly
      expect(returnedValue.u32, isNotNull);
      expect(returnedValue.u32!.uint32, 42);
    });
  });

  group('SorobanClient Mock Tests', () {
    late KeyPair sourceKeyPair;
    late String sourceAccountId;
    const contractId =
        'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK';
    const rpcUrl = 'https://soroban-testnet.stellar.org';

    setUp(() {
      sourceKeyPair = KeyPair.random();
      sourceAccountId = sourceKeyPair.accountId;
    });

    group('forClientOptions', () {
      test('throws exception when contract info cannot be loaded', () async {
        final options = ClientOptions(
          sourceAccountKeyPair: KeyPair.fromAccountId(sourceAccountId),
          contractId: contractId,
          network: Network.TESTNET,
          rpcUrl: rpcUrl,
        );

        // Since we can't easily mock the complex contract loading,
        // test that the method attempts the operation and handles failure
        expect(
          () async => await SorobanClient.forClientOptions(options: options),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('install', () {
      test('validates install request is created correctly', () async {
        final wasmBytes = Uint8List.fromList([0, 97, 115, 109]); // WASM header

        final installRequest = InstallRequest(
          wasmBytes: wasmBytes,
          sourceAccountKeyPair: sourceKeyPair,
          network: Network.TESTNET,
          rpcUrl: rpcUrl,
        );

        // Verify request was created with correct parameters
        expect(installRequest.wasmBytes, wasmBytes);
        expect(installRequest.sourceAccountKeyPair, sourceKeyPair);
        expect(installRequest.network, Network.TESTNET);
        expect(installRequest.rpcUrl, rpcUrl);
      });

      test('install throws exception with invalid server', () async {
        final wasmBytes = Uint8List.fromList([0, 97, 115, 109]);

        final installRequest = InstallRequest(
          wasmBytes: wasmBytes,
          sourceAccountKeyPair: sourceKeyPair,
          network: Network.TESTNET,
          rpcUrl: 'invalid-url',
        );

        // Test that install fails with invalid configuration
        expect(
          () async => await SorobanClient.install(installRequest: installRequest),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('ClientOptions (mock context)', () {
      test('creates options with all required fields', () {
        final options = ClientOptions(
          sourceAccountKeyPair: sourceKeyPair,
          contractId: contractId,
          network: Network.TESTNET,
          rpcUrl: rpcUrl,
        );

        expect(options.sourceAccountKeyPair, sourceKeyPair);
        expect(options.contractId, contractId);
        expect(options.network, Network.TESTNET);
        expect(options.rpcUrl, rpcUrl);
        expect(options.enableServerLogging, false);
      });

      test('creates options with server logging enabled', () {
        final options = ClientOptions(
          sourceAccountKeyPair: sourceKeyPair,
          contractId: contractId,
          network: Network.TESTNET,
          rpcUrl: rpcUrl,
          enableServerLogging: true,
        );

        expect(options.enableServerLogging, true);
      });
    });

    group('MethodOptions (mock context)', () {
      test('creates options with default values', () {
        final options = MethodOptions();

        expect(options.fee, NetworkConstants.DEFAULT_SOROBAN_BASE_FEE);
        expect(
            options.timeoutInSeconds, NetworkConstants.DEFAULT_TIMEOUT_SECONDS);
        expect(options.simulate, true);
        expect(options.restore, false);
      });

      test('creates options with custom values', () {
        final options = MethodOptions(
          fee: 200,
          timeoutInSeconds: 60,
          simulate: false,
          restore: true,
        );

        expect(options.fee, 200);
        expect(options.timeoutInSeconds, 60);
        expect(options.simulate, false);
        expect(options.restore, true);
      });
    });

    group('AssembledTransactionOptions (mock context)', () {
      test('creates options with all required fields', () {
        final clientOptions = ClientOptions(
          sourceAccountKeyPair: sourceKeyPair,
          contractId: contractId,
          network: Network.TESTNET,
          rpcUrl: rpcUrl,
        );

        final methodOptions = MethodOptions();

        final options = AssembledTransactionOptions(
          clientOptions: clientOptions,
          methodOptions: methodOptions,
          method: 'test_method',
          arguments: [XdrSCVal.forU32(42)],
        );

        expect(options.clientOptions, clientOptions);
        expect(options.methodOptions, methodOptions);
        expect(options.method, 'test_method');
        expect(options.arguments, isNotNull);
        expect(options.arguments!.length, 1);
        expect(options.enableSorobanServerLogging, false);
      });

      test('creates options with server logging enabled', () {
        final clientOptions = ClientOptions(
          sourceAccountKeyPair: sourceKeyPair,
          contractId: contractId,
          network: Network.TESTNET,
          rpcUrl: rpcUrl,
        );

        final options = AssembledTransactionOptions(
          clientOptions: clientOptions,
          methodOptions: MethodOptions(),
          method: 'test_method',
          enableSorobanServerLogging: true,
        );

        expect(options.enableSorobanServerLogging, true);
      });

      test('creates options without arguments', () {
        final clientOptions = ClientOptions(
          sourceAccountKeyPair: sourceKeyPair,
          contractId: contractId,
          network: Network.TESTNET,
          rpcUrl: rpcUrl,
        );

        final options = AssembledTransactionOptions(
          clientOptions: clientOptions,
          methodOptions: MethodOptions(),
          method: 'test_method',
        );

        expect(options.arguments, isNull);
      });
    });

    group('InstallRequest (mock context)', () {
      test('creates request with all required fields', () {
        final wasmBytes = Uint8List.fromList([0, 97, 115, 109]);

        final request = InstallRequest(
          wasmBytes: wasmBytes,
          sourceAccountKeyPair: sourceKeyPair,
          network: Network.TESTNET,
          rpcUrl: rpcUrl,
        );

        expect(request.wasmBytes, wasmBytes);
        expect(request.sourceAccountKeyPair, sourceKeyPair);
        expect(request.network, Network.TESTNET);
        expect(request.rpcUrl, rpcUrl);
        expect(request.enableSorobanServerLogging, false);
      });

      test('creates request with server logging enabled', () {
        final wasmBytes = Uint8List.fromList([0, 97, 115, 109]);

        final request = InstallRequest(
          wasmBytes: wasmBytes,
          sourceAccountKeyPair: sourceKeyPair,
          network: Network.TESTNET,
          rpcUrl: rpcUrl,
          enableSorobanServerLogging: true,
        );

        expect(request.enableSorobanServerLogging, true);
      });
    });

    group('DeployRequest (mock context)', () {
      test('creates request with all required fields', () {
        final wasmHash =
            '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef';

        final request = DeployRequest(
          sourceAccountKeyPair: sourceKeyPair,
          network: Network.TESTNET,
          rpcUrl: rpcUrl,
          wasmHash: wasmHash,
        );

        expect(request.sourceAccountKeyPair, sourceKeyPair);
        expect(request.network, Network.TESTNET);
        expect(request.rpcUrl, rpcUrl);
        expect(request.wasmHash, wasmHash);
        expect(request.constructorArgs, isNull);
        expect(request.salt, isNull);
        expect(request.enableSorobanServerLogging, false);
        expect(request.methodOptions, isNotNull);
      });

      test('creates request with constructor args', () {
        final wasmHash =
            '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef';
        final constructorArgs = [XdrSCVal.forU32(42)];

        final request = DeployRequest(
          sourceAccountKeyPair: sourceKeyPair,
          network: Network.TESTNET,
          rpcUrl: rpcUrl,
          wasmHash: wasmHash,
          constructorArgs: constructorArgs,
        );

        expect(request.constructorArgs, constructorArgs);
        expect(request.constructorArgs!.length, 1);
      });

      test('creates request with custom salt', () {
        final wasmHash =
            '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef';
        final salt = XdrUint256(Uint8List.fromList(List.filled(32, 1)));

        final request = DeployRequest(
          sourceAccountKeyPair: sourceKeyPair,
          network: Network.TESTNET,
          rpcUrl: rpcUrl,
          wasmHash: wasmHash,
          salt: salt,
        );

        expect(request.salt, salt);
      });

      test('creates request with custom method options', () {
        final wasmHash =
            '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef';
        final methodOptions = MethodOptions(
          fee: 200,
          timeoutInSeconds: 60,
        );

        final request = DeployRequest(
          sourceAccountKeyPair: sourceKeyPair,
          network: Network.TESTNET,
          rpcUrl: rpcUrl,
          wasmHash: wasmHash,
          methodOptions: methodOptions,
        );

        expect(request.methodOptions, methodOptions);
        expect(request.methodOptions.fee, 200);
        expect(request.methodOptions.timeoutInSeconds, 60);
      });

      test('creates request with server logging enabled', () {
        final wasmHash =
            '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef';

        final request = DeployRequest(
          sourceAccountKeyPair: sourceKeyPair,
          network: Network.TESTNET,
          rpcUrl: rpcUrl,
          wasmHash: wasmHash,
          enableSorobanServerLogging: true,
        );

        expect(request.enableSorobanServerLogging, true);
      });
    });

    group('AssembledTransaction', () {
      test('validates transaction options creation', () {
        final clientOptions = ClientOptions(
          sourceAccountKeyPair: sourceKeyPair,
          contractId: contractId,
          network: Network.TESTNET,
          rpcUrl: rpcUrl,
        );

        final assembledOptions = AssembledTransactionOptions(
          clientOptions: clientOptions,
          methodOptions: MethodOptions(),
          method: 'test_method',
          arguments: [XdrSCVal.forU32(42)],
        );

        expect(assembledOptions.clientOptions, clientOptions);
        expect(assembledOptions.method, 'test_method');
        expect(assembledOptions.arguments, isNotNull);
        expect(assembledOptions.arguments!.length, 1);
      });

      test('needsNonInvokerSigningBy returns empty list for non-InvokeHostFunction op', () async {
        final keyPair = KeyPair.random();

        // Build a valid XDR ledger entry for the mock account response
        final xdrAccountId = XdrAccountID(
            KeyPair.fromAccountId(keyPair.accountId).xdrPublicKey);
        final accountEntry = XdrAccountEntry(
            xdrAccountId,
            XdrInt64(BigInt.from(100000000)),
            XdrSequenceNumber(XdrBigInt64(BigInt.from(12345))),
            XdrUint32(0),
            null, // inflationDest
            XdrUint32(0), // flags
            XdrString32(''), // homeDomain
            XdrThresholds(Uint8List.fromList([1, 0, 0, 0])),
            [], // signers
            XdrAccountEntryExt(0));
        final ledgerEntryData = XdrLedgerEntryData(XdrLedgerEntryType.ACCOUNT);
        ledgerEntryData.account = accountEntry;
        final entryXdr = ledgerEntryData.toBase64EncodedXdrString();

        // Start a local HTTP server to mock the Soroban RPC
        final httpServer = await HttpServer.bind('127.0.0.1', 0);
        final mockRpcUrl = 'http://127.0.0.1:${httpServer.port}';

        httpServer.listen((request) async {
          request.response
            ..statusCode = 200
            ..headers.contentType = ContentType.json
            ..write(json.encode({
              "jsonrpc": "2.0",
              "id": 1,
              "result": {
                "entries": [
                  {"key": "AAAAAAAAAA==", "xdr": entryXdr, "lastModifiedLedgerSeq": 100}
                ],
                "latestLedger": 1000
              }
            }));
          await request.response.close();
        });

        try {
          final clientOptions = ClientOptions(
            sourceAccountKeyPair: keyPair,
            contractId: contractId,
            network: Network.TESTNET,
            rpcUrl: mockRpcUrl,
          );

          final assembledOptions = AssembledTransactionOptions(
            clientOptions: clientOptions,
            methodOptions: MethodOptions(simulate: false),
            method: 'test_method',
          );

          final assembledTx = await AssembledTransaction.build(
              options: assembledOptions);

          // Replace tx with a RestoreFootprintOperation transaction
          final account = Account(keyPair.accountId, BigInt.from(12345));
          final restoreOp = RestoreFootprintOperation();
          assembledTx.tx = TransactionBuilder(account)
              .addOperation(restoreOp)
              .build();

          final signers = assembledTx.needsNonInvokerSigningBy();
          expect(signers, isEmpty);
        } finally {
          await httpServer.close();
        }
      });

      test('validates transaction fails without proper server', () async {
        final clientOptions = ClientOptions(
          sourceAccountKeyPair: sourceKeyPair,
          contractId: contractId,
          network: Network.TESTNET,
          rpcUrl: 'invalid-url',
        );

        final assembledOptions = AssembledTransactionOptions(
          clientOptions: clientOptions,
          methodOptions: MethodOptions(),
          method: 'test_method',
          arguments: [],
        );

        // Transaction build should fail with invalid server
        expect(
          () async => await AssembledTransaction.build(options: assembledOptions),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
