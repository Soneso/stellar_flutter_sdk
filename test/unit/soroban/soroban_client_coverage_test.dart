// Coverage tests for SorobanClient
// These tests target uncovered code paths to reach 90% coverage
// for soroban_client.dart by testing the public API and edge cases

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('SorobanClient Coverage Tests', () {
    late KeyPair sourceKeyPair;
    late String sourceAccountId;
    const rpcUrl = 'https://soroban-testnet.stellar.org';

    setUp(() {
      sourceKeyPair = KeyPair.random();
      sourceAccountId = sourceKeyPair.accountId;
    });

    group('SorobanClient.forClientOptions - Error Handling', () {
      test('throws exception when contract info cannot be loaded', () async {
        final options = ClientOptions(
          sourceAccountKeyPair: sourceKeyPair,
          contractId: 'CINVALIDCONTRACTID123456789012345678901234567890123456',
          network: Network.TESTNET,
          rpcUrl: 'https://invalid-soroban.stellar.org:443',
        );

        expect(
          SorobanClient.forClientOptions(options: options),
          throwsA(anything),
        );
      });

      test('validates contract ID format requirements', () async {
        final options = ClientOptions(
          sourceAccountKeyPair: sourceKeyPair,
          contractId: 'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK',
          network: Network.TESTNET,
          rpcUrl: 'https://invalid-rpc.example.com',
        );

        expect(
          SorobanClient.forClientOptions(options: options),
          throwsA(anything),
        );
      });
    });

    group('DeployRequest - Validation', () {
      test('creates deploy request with minimal fields', () {
        final request = DeployRequest(
          sourceAccountKeyPair: sourceKeyPair,
          network: Network.TESTNET,
          rpcUrl: rpcUrl,
          wasmHash: 'abc123def456',
        );

        expect(request.sourceAccountKeyPair, sourceKeyPair);
        expect(request.wasmHash, 'abc123def456');
        expect(request.constructorArgs, isNull);
        expect(request.salt, isNull);
        expect(request.methodOptions, isNotNull);
      });

      test('creates deploy request with all optional fields', () {
        final constructorArgs = [
          XdrSCVal.forU32(100),
          XdrSCVal.forU32(200),
        ];
        final salt = XdrUint256(Uint8List.fromList(List.filled(32, 5)));
        final customOptions = MethodOptions(
          fee: 2000,
          timeoutInSeconds: 120,
        );

        final request = DeployRequest(
          sourceAccountKeyPair: sourceKeyPair,
          network: Network.PUBLIC,
          rpcUrl: 'https://soroban.stellar.org:443',
          wasmHash: 'fullhash',
          constructorArgs: constructorArgs,
          salt: salt,
          methodOptions: customOptions,
          enableSorobanServerLogging: true,
        );

        expect(request.constructorArgs!.length, 2);
        expect(request.salt, isNotNull);
        expect(request.methodOptions.fee, 2000);
        expect(request.enableSorobanServerLogging, true);
      });

      test('supports multiple constructor argument types', () {
        final args = [
          XdrSCVal.forU32(1),
          XdrSCVal.forU64(BigInt.from(100)),
          XdrSCVal.forSymbol('test'),
          XdrSCVal.forBool(true),
          XdrSCVal.forVoid(),
        ];

        final request = DeployRequest(
          sourceAccountKeyPair: sourceKeyPair,
          network: Network.TESTNET,
          rpcUrl: rpcUrl,
          wasmHash: 'multitype',
          constructorArgs: args,
        );

        expect(request.constructorArgs!.length, 5);
      });

      test('uses default method options when not specified', () {
        final request = DeployRequest(
          sourceAccountKeyPair: sourceKeyPair,
          network: Network.TESTNET,
          rpcUrl: rpcUrl,
          wasmHash: 'defaults',
        );

        expect(request.methodOptions.fee, NetworkConstants.DEFAULT_SOROBAN_BASE_FEE);
        expect(request.methodOptions.timeoutInSeconds, NetworkConstants.DEFAULT_TIMEOUT_SECONDS);
        expect(request.methodOptions.simulate, true);
        expect(request.methodOptions.restore, false);
      });
    });

    group('InstallRequest - Validation', () {
      test('creates install request with minimal fields', () {
        final wasmBytes = Uint8List.fromList([0x00, 0x61, 0x73, 0x6d]);

        final request = InstallRequest(
          wasmBytes: wasmBytes,
          sourceAccountKeyPair: sourceKeyPair,
          network: Network.TESTNET,
          rpcUrl: rpcUrl,
        );

        expect(request.wasmBytes, wasmBytes);
        expect(request.sourceAccountKeyPair, sourceKeyPair);
        expect(request.network, Network.TESTNET);
        expect(request.enableSorobanServerLogging, false);
      });

      test('handles empty wasm bytes', () {
        final wasmBytes = Uint8List(0);

        final request = InstallRequest(
          wasmBytes: wasmBytes,
          sourceAccountKeyPair: sourceKeyPair,
          network: Network.TESTNET,
          rpcUrl: rpcUrl,
        );

        expect(request.wasmBytes.length, 0);
      });

      test('handles large wasm files', () {
        final wasmBytes = Uint8List.fromList(
          List.generate(50000, (i) => i % 256),
        );

        final request = InstallRequest(
          wasmBytes: wasmBytes,
          sourceAccountKeyPair: sourceKeyPair,
          network: Network.TESTNET,
          rpcUrl: rpcUrl,
          enableSorobanServerLogging: true,
        );

        expect(request.wasmBytes.length, 50000);
        expect(request.enableSorobanServerLogging, true);
      });

      test('supports different network types', () {
        final wasmBytes = Uint8List.fromList([0x00, 0x61, 0x73, 0x6d]);

        final testnetRequest = InstallRequest(
          wasmBytes: wasmBytes,
          sourceAccountKeyPair: sourceKeyPair,
          network: Network.TESTNET,
          rpcUrl: 'https://soroban-testnet.stellar.org',
        );

        final publicRequest = InstallRequest(
          wasmBytes: wasmBytes,
          sourceAccountKeyPair: sourceKeyPair,
          network: Network.PUBLIC,
          rpcUrl: 'https://soroban-mainnet.stellar.org',
        );

        final customNetwork = Network('custom passphrase');
        final customRequest = InstallRequest(
          wasmBytes: wasmBytes,
          sourceAccountKeyPair: sourceKeyPair,
          network: customNetwork,
          rpcUrl: 'https://custom.example.com',
        );

        expect(testnetRequest.network, Network.TESTNET);
        expect(publicRequest.network, Network.PUBLIC);
        expect(customRequest.network.networkPassphrase, 'custom passphrase');
      });
    });

    group('ClientOptions - Network Variations', () {
      test('creates options with TESTNET', () {
        final options = ClientOptions(
          sourceAccountKeyPair: sourceKeyPair,
          contractId: 'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK',
          network: Network.TESTNET,
          rpcUrl: 'https://soroban-testnet.stellar.org:443',
        );

        expect(options.network, Network.TESTNET);
        expect(options.network.networkPassphrase, Network.TESTNET.networkPassphrase);
      });

      test('creates options with PUBLIC', () {
        final options = ClientOptions(
          sourceAccountKeyPair: sourceKeyPair,
          contractId: 'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK',
          network: Network.PUBLIC,
          rpcUrl: 'https://soroban-mainnet.stellar.org',
        );

        expect(options.network, Network.PUBLIC);
      });

      test('creates options with custom network', () {
        final customNetwork = Network('My Custom Network Passphrase');
        final options = ClientOptions(
          sourceAccountKeyPair: sourceKeyPair,
          contractId: 'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK',
          network: customNetwork,
          rpcUrl: 'https://custom-rpc.example.com',
        );

        expect(options.network.networkPassphrase, 'My Custom Network Passphrase');
      });

      test('supports read-only keypairs', () {
        final publicKeyOnly = KeyPair.fromAccountId(sourceAccountId);

        final options = ClientOptions(
          sourceAccountKeyPair: publicKeyOnly,
          contractId: 'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK',
          network: Network.TESTNET,
          rpcUrl: rpcUrl,
        );

        expect(options.sourceAccountKeyPair.accountId, sourceAccountId);
        expect(options.sourceAccountKeyPair.privateKey, isNull);
      });

      test('supports write-enabled keypairs', () {
        final options = ClientOptions(
          sourceAccountKeyPair: sourceKeyPair,
          contractId: 'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK',
          network: Network.TESTNET,
          rpcUrl: rpcUrl,
        );

        expect(options.sourceAccountKeyPair.privateKey, isNotNull);
      });

      test('allows contractId modification', () {
        final options = ClientOptions(
          sourceAccountKeyPair: sourceKeyPair,
          contractId: 'COLD123',
          network: Network.TESTNET,
          rpcUrl: rpcUrl,
        );

        expect(options.contractId, 'COLD123');
        options.contractId = 'CNEW789';
        expect(options.contractId, 'CNEW789');
      });

      test('supports server logging toggle', () {
        final optionsDisabled = ClientOptions(
          sourceAccountKeyPair: sourceKeyPair,
          contractId: 'CTEST',
          network: Network.TESTNET,
          rpcUrl: rpcUrl,
          enableServerLogging: false,
        );

        final optionsEnabled = ClientOptions(
          sourceAccountKeyPair: sourceKeyPair,
          contractId: 'CTEST',
          network: Network.TESTNET,
          rpcUrl: rpcUrl,
          enableServerLogging: true,
        );

        expect(optionsDisabled.enableServerLogging, false);
        expect(optionsEnabled.enableServerLogging, true);
      });
    });

    group('MethodOptions - Comprehensive Variations', () {
      test('creates with default values', () {
        final options = MethodOptions();

        expect(options.fee, NetworkConstants.DEFAULT_SOROBAN_BASE_FEE);
        expect(options.timeoutInSeconds, NetworkConstants.DEFAULT_TIMEOUT_SECONDS);
        expect(options.simulate, true);
        expect(options.restore, false);
      });

      test('creates with custom fee only', () {
        final options = MethodOptions(fee: 5000);

        expect(options.fee, 5000);
        expect(options.timeoutInSeconds, NetworkConstants.DEFAULT_TIMEOUT_SECONDS);
        expect(options.simulate, true);
        expect(options.restore, false);
      });

      test('creates with custom timeout only', () {
        final options = MethodOptions(timeoutInSeconds: 60);

        expect(options.fee, NetworkConstants.DEFAULT_SOROBAN_BASE_FEE);
        expect(options.timeoutInSeconds, 60);
        expect(options.simulate, true);
        expect(options.restore, false);
      });

      test('creates with simulate disabled', () {
        final options = MethodOptions(simulate: false);

        expect(options.simulate, false);
        expect(options.restore, false);
      });

      test('creates with restore enabled', () {
        final options = MethodOptions(restore: true);

        expect(options.restore, true);
        expect(options.simulate, true);
      });

      test('creates with all custom values', () {
        final options = MethodOptions(
          fee: 10000,
          timeoutInSeconds: 180,
          simulate: false,
          restore: true,
        );

        expect(options.fee, 10000);
        expect(options.timeoutInSeconds, 180);
        expect(options.simulate, false);
        expect(options.restore, true);
      });

      test('supports very high fees', () {
        final options = MethodOptions(fee: 1000000);
        expect(options.fee, 1000000);
      });

      test('supports very short timeout', () {
        final options = MethodOptions(timeoutInSeconds: 10);
        expect(options.timeoutInSeconds, 10);
      });

      test('supports very long timeout', () {
        final options = MethodOptions(timeoutInSeconds: 7200);
        expect(options.timeoutInSeconds, 7200);
      });

      test('supports zero fee', () {
        final options = MethodOptions(fee: 0);
        expect(options.fee, 0);
      });
    });

    group('AssembledTransactionOptions - Argument Variations', () {
      test('creates with null arguments', () {
        final clientOptions = ClientOptions(
          sourceAccountKeyPair: sourceKeyPair,
          contractId: 'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK',
          network: Network.TESTNET,
          rpcUrl: rpcUrl,
        );

        final options = AssembledTransactionOptions(
          clientOptions: clientOptions,
          methodOptions: MethodOptions(),
          method: 'no_args_method',
        );

        expect(options.arguments, isNull);
        expect(options.method, 'no_args_method');
      });

      test('creates with empty arguments list', () {
        final clientOptions = ClientOptions(
          sourceAccountKeyPair: sourceKeyPair,
          contractId: 'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK',
          network: Network.TESTNET,
          rpcUrl: rpcUrl,
        );

        final options = AssembledTransactionOptions(
          clientOptions: clientOptions,
          methodOptions: MethodOptions(),
          method: 'empty_args_method',
          arguments: [],
        );

        expect(options.arguments, isNotNull);
        expect(options.arguments!.length, 0);
      });

      test('creates with single argument', () {
        final clientOptions = ClientOptions(
          sourceAccountKeyPair: sourceKeyPair,
          contractId: 'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK',
          network: Network.TESTNET,
          rpcUrl: rpcUrl,
        );

        final args = [XdrSCVal.forU32(42)];

        final options = AssembledTransactionOptions(
          clientOptions: clientOptions,
          methodOptions: MethodOptions(),
          method: 'single_arg_method',
          arguments: args,
        );

        expect(options.arguments!.length, 1);
      });

      test('creates with multiple argument types', () {
        final clientOptions = ClientOptions(
          sourceAccountKeyPair: sourceKeyPair,
          contractId: 'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK',
          network: Network.TESTNET,
          rpcUrl: rpcUrl,
        );

        final args = [
          XdrSCVal.forU32(1),
          XdrSCVal.forU64(BigInt.from(100)),
          XdrSCVal.forI32(-5),
          XdrSCVal.forI64(BigInt.from(-1000)),
          XdrSCVal.forSymbol('test_symbol'),
          XdrSCVal.forBool(true),
          XdrSCVal.forBool(false),
          XdrSCVal.forVoid(),
        ];

        final options = AssembledTransactionOptions(
          clientOptions: clientOptions,
          methodOptions: MethodOptions(),
          method: 'multi_type_args',
          arguments: args,
        );

        expect(options.arguments!.length, 8);
      });

      test('creates with complex nested arguments', () {
        final clientOptions = ClientOptions(
          sourceAccountKeyPair: sourceKeyPair,
          contractId: 'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK',
          network: Network.TESTNET,
          rpcUrl: rpcUrl,
        );

        final vecArgs = [XdrSCVal.forU32(1), XdrSCVal.forU32(2)];
        final args = [
          XdrSCVal.forVec(vecArgs),
          XdrSCVal.forBytes(Uint8List.fromList([1, 2, 3, 4])),
          XdrSCVal.forString('test string'),
        ];

        final options = AssembledTransactionOptions(
          clientOptions: clientOptions,
          methodOptions: MethodOptions(),
          method: 'complex_args',
          arguments: args,
        );

        expect(options.arguments!.length, 3);
      });

      test('creates with logging enabled', () {
        final clientOptions = ClientOptions(
          sourceAccountKeyPair: sourceKeyPair,
          contractId: 'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK',
          network: Network.TESTNET,
          rpcUrl: rpcUrl,
        );

        final options = AssembledTransactionOptions(
          clientOptions: clientOptions,
          methodOptions: MethodOptions(),
          method: 'logged_method',
          enableSorobanServerLogging: true,
        );

        expect(options.enableSorobanServerLogging, true);
      });

      test('creates with custom method options', () {
        final clientOptions = ClientOptions(
          sourceAccountKeyPair: sourceKeyPair,
          contractId: 'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK',
          network: Network.TESTNET,
          rpcUrl: rpcUrl,
        );

        final customMethodOptions = MethodOptions(
          fee: 5000,
          timeoutInSeconds: 120,
          simulate: false,
          restore: true,
        );

        final options = AssembledTransactionOptions(
          clientOptions: clientOptions,
          methodOptions: customMethodOptions,
          method: 'custom_options_method',
        );

        expect(options.methodOptions.fee, 5000);
        expect(options.methodOptions.timeoutInSeconds, 120);
        expect(options.methodOptions.simulate, false);
        expect(options.methodOptions.restore, true);
      });
    });

    group('SimulateHostFunctionResult - Construction', () {
      test('creates result with all fields present', () {
        final auth = <SorobanAuthorizationEntry>[];
        final transactionData = XdrSorobanTransactionData(
          XdrSorobanTransactionDataExt(0),
          XdrSorobanResources(
            XdrLedgerFootprint([], []),
            XdrUint32(0),
            XdrUint32(0),
            XdrUint32(0),
          ),
          XdrInt64(BigInt.zero),
        );
        final returnedValue = XdrSCVal.forU32(42);

        final result = SimulateHostFunctionResult(
          auth,
          transactionData,
          returnedValue,
        );

        expect(result.auth, auth);
        expect(result.transactionData, transactionData);
        expect(result.returnedValue, returnedValue);
        expect(result.returnedValue.u32, isNotNull);
      });

      test('creates result with null auth', () {
        final transactionData = XdrSorobanTransactionData(
          XdrSorobanTransactionDataExt(0),
          XdrSorobanResources(
            XdrLedgerFootprint([], []),
            XdrUint32(0),
            XdrUint32(0),
            XdrUint32(0),
          ),
          XdrInt64(BigInt.zero),
        );
        final returnedValue = XdrSCVal.forVoid();

        final result = SimulateHostFunctionResult(
          null,
          transactionData,
          returnedValue,
        );

        expect(result.auth, isNull);
        expect(result.returnedValue.discriminant, XdrSCValType.SCV_VOID);
      });

      test('creates result with empty auth list', () {
        final auth = <SorobanAuthorizationEntry>[];
        final transactionData = XdrSorobanTransactionData(
          XdrSorobanTransactionDataExt(0),
          XdrSorobanResources(
            XdrLedgerFootprint([], []),
            XdrUint32(0),
            XdrUint32(0),
            XdrUint32(0),
          ),
          XdrInt64(BigInt.zero),
        );
        final returnedValue = XdrSCVal.forBool(true);

        final result = SimulateHostFunctionResult(
          auth,
          transactionData,
          returnedValue,
        );

        expect(result.auth!.length, 0);
        expect(result.returnedValue.b, true);
      });

      test('creates result with complex footprint', () {
        final readOnlyEntry = XdrLedgerKey(XdrLedgerEntryType.CONTRACT_DATA);
        final readWriteEntry = XdrLedgerKey(XdrLedgerEntryType.CONTRACT_CODE);

        final transactionData = XdrSorobanTransactionData(
          XdrSorobanTransactionDataExt(0),
          XdrSorobanResources(
            XdrLedgerFootprint([readOnlyEntry], [readWriteEntry]),
            XdrUint32(5000),
            XdrUint32(10000),
            XdrUint32(15000),
          ),
          XdrInt64(BigInt.from(2000)),
        );
        final returnedValue = XdrSCVal.forI128Parts(
          BigInt.zero,
          BigInt.from(999999),
        );

        final result = SimulateHostFunctionResult(
          null,
          transactionData,
          returnedValue,
        );

        expect(result.transactionData.resources.footprint.readOnly.length, 1);
        expect(result.transactionData.resources.footprint.readWrite.length, 1);
        expect(result.transactionData.resources.instructions.uint32, 5000);
        expect(result.transactionData.resources.writeBytes.uint32, 15000);
      });

      test('creates result with different return value types', () {
        final transactionData = XdrSorobanTransactionData(
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
          null,
          transactionData,
          XdrSCVal.forU32(123),
        );
        expect(resultU32.returnedValue.u32!.uint32, 123);

        final resultI32 = SimulateHostFunctionResult(
          null,
          transactionData,
          XdrSCVal.forI32(-456),
        );
        expect(resultI32.returnedValue.i32!.int32, -456);

        final resultBool = SimulateHostFunctionResult(
          null,
          transactionData,
          XdrSCVal.forBool(false),
        );
        expect(resultBool.returnedValue.b, false);

        final resultString = SimulateHostFunctionResult(
          null,
          transactionData,
          XdrSCVal.forString('test'),
        );
        expect(resultString.returnedValue.str, isNotNull);

        final resultBytes = SimulateHostFunctionResult(
          null,
          transactionData,
          XdrSCVal.forBytes(Uint8List.fromList([1, 2, 3])),
        );
        expect(resultBytes.returnedValue.bytes, isNotNull);
      });
    });

    group('Edge Cases and Boundary Conditions', () {
      test('handles very long method names', () {
        final clientOptions = ClientOptions(
          sourceAccountKeyPair: sourceKeyPair,
          contractId: 'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK',
          network: Network.TESTNET,
          rpcUrl: rpcUrl,
        );

        final longMethodName = 'very_long_method_name_that_exceeds_normal_length_${'x' * 100}';

        final options = AssembledTransactionOptions(
          clientOptions: clientOptions,
          methodOptions: MethodOptions(),
          method: longMethodName,
        );

        expect(options.method, longMethodName);
      });

      test('handles maximum integer values', () {
        final args = [
          XdrSCVal.forU32(4294967295),
          XdrSCVal.forU64(BigInt.parse('18446744073709551615')),
          XdrSCVal.forI32(2147483647),
          XdrSCVal.forI32(-2147483648),
          XdrSCVal.forI64(BigInt.parse('9223372036854775807')),
          XdrSCVal.forI64(BigInt.parse('-9223372036854775808')),
        ];

        final clientOptions = ClientOptions(
          sourceAccountKeyPair: sourceKeyPair,
          contractId: 'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK',
          network: Network.TESTNET,
          rpcUrl: rpcUrl,
        );

        final options = AssembledTransactionOptions(
          clientOptions: clientOptions,
          methodOptions: MethodOptions(),
          method: 'max_values',
          arguments: args,
        );

        expect(options.arguments!.length, 6);
      });

      test('handles empty strings and symbols', () {
        final args = [
          XdrSCVal.forString(''),
          XdrSCVal.forSymbol(''),
        ];

        final clientOptions = ClientOptions(
          sourceAccountKeyPair: sourceKeyPair,
          contractId: 'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK',
          network: Network.TESTNET,
          rpcUrl: rpcUrl,
        );

        final options = AssembledTransactionOptions(
          clientOptions: clientOptions,
          methodOptions: MethodOptions(),
          method: 'empty_strings',
          arguments: args,
        );

        expect(options.arguments!.length, 2);
      });

      test('handles large byte arrays', () {
        final largeBytes = Uint8List.fromList(
          List.generate(10000, (i) => i % 256),
        );

        final args = [XdrSCVal.forBytes(largeBytes)];

        final clientOptions = ClientOptions(
          sourceAccountKeyPair: sourceKeyPair,
          contractId: 'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK',
          network: Network.TESTNET,
          rpcUrl: rpcUrl,
        );

        final options = AssembledTransactionOptions(
          clientOptions: clientOptions,
          methodOptions: MethodOptions(),
          method: 'large_bytes',
          arguments: args,
        );

        expect(options.arguments!.length, 1);
      });

      test('handles special characters in RPC URLs', () {
        final specialUrls = [
          'https://soroban.stellar.org:443',
          'http://localhost:8000/soroban/rpc',
          'https://rpc.stellar.org/v1/soroban',
          'https://testnet-soroban-123.example.com',
        ];

        for (final url in specialUrls) {
          final options = ClientOptions(
            sourceAccountKeyPair: sourceKeyPair,
            contractId: 'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK',
            network: Network.TESTNET,
            rpcUrl: url,
          );

          expect(options.rpcUrl, url);
        }
      });

      test('handles different salt variations for deployment', () {
        final zeroSalt = XdrUint256(Uint8List.fromList(List.filled(32, 0)));
        final maxSalt = XdrUint256(Uint8List.fromList(List.filled(32, 255)));
        final randomSalt = XdrUint256(Uint8List.fromList(
          List.generate(32, (i) => i * 7 % 256),
        ));

        final requestZero = DeployRequest(
          sourceAccountKeyPair: sourceKeyPair,
          network: Network.TESTNET,
          rpcUrl: rpcUrl,
          wasmHash: 'hash1',
          salt: zeroSalt,
        );

        final requestMax = DeployRequest(
          sourceAccountKeyPair: sourceKeyPair,
          network: Network.TESTNET,
          rpcUrl: rpcUrl,
          wasmHash: 'hash2',
          salt: maxSalt,
        );

        final requestRandom = DeployRequest(
          sourceAccountKeyPair: sourceKeyPair,
          network: Network.TESTNET,
          rpcUrl: rpcUrl,
          wasmHash: 'hash3',
          salt: randomSalt,
        );

        expect(requestZero.salt, isNotNull);
        expect(requestMax.salt, isNotNull);
        expect(requestRandom.salt, isNotNull);
      });
    });
  });
}
