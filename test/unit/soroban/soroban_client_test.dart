// Test SorobanClient classes and helpers
// These tests validate object construction, getters, and helper methods
// without making any network calls

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

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
  });
}
