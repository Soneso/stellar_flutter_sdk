import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart' as dio;
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

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

void main() {
  group('SorobanClient Additional Tests', () {
    late KeyPair sourceKeyPair;
    late String sourceAccountId;
    const rpcUrl = 'https://soroban-testnet.stellar.org';

    setUp(() {
      sourceKeyPair = KeyPair.random();
      sourceAccountId = sourceKeyPair.accountId;
    });

    // Note: SorobanClient constructor is private and tested indirectly through
    // forClientOptions, deploy, and install static methods
    group('SorobanClient Indirect Constructor Testing', () {
      test('forClientOptions validates constructor logic indirectly', () async {
        final options = ClientOptions(
          sourceAccountKeyPair: sourceKeyPair,
          contractId:
              'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK',
          network: Network.TESTNET,
          rpcUrl: rpcUrl,
        );

        // This will fail since we don't have a real server, but it exercises
        // the code path
        expect(
          () async => await SorobanClient.forClientOptions(options: options),
          throwsA(anything),
        );
      });
    });

    // Note: Can't directly test getters because constructor is private
    // These are tested indirectly through integration tests

    // Note: buildInvokeMethodTx requires a SorobanClient instance
    // which requires a private constructor - tested in integration tests

    // Note: AssembledTransaction constructor is private
    // These error cases are tested through integration tests with build/buildWithOp

    // Note: AssembledTransaction simulate error handling tested in integration tests

    group('SimulateHostFunctionResult', () {
      test('creates result with all fields', () {
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
      });
    });

    // Note: ContractSpec helper methods tested in integration tests
    // because they require a SorobanClient instance (private constructor)

    group('DeployRequest with all options', () {
      test('creates deploy request with all optional fields', () {
        final wasmHash =
            '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef';
        final constructorArgs = [
          XdrSCVal.forU32(1),
          XdrSCVal.forU32(2),
        ];
        final salt = XdrUint256(Uint8List.fromList(List.filled(32, 5)));
        final methodOptions = MethodOptions(
          fee: 500,
          timeoutInSeconds: 120,
          simulate: false,
          restore: true,
        );

        final request = DeployRequest(
          sourceAccountKeyPair: sourceKeyPair,
          network: Network.TESTNET,
          rpcUrl: rpcUrl,
          wasmHash: wasmHash,
          constructorArgs: constructorArgs,
          salt: salt,
          methodOptions: methodOptions,
          enableSorobanServerLogging: true,
        );

        expect(request.sourceAccountKeyPair, sourceKeyPair);
        expect(request.network, Network.TESTNET);
        expect(request.rpcUrl, rpcUrl);
        expect(request.wasmHash, wasmHash);
        expect(request.constructorArgs, constructorArgs);
        expect(request.salt, salt);
        expect(request.methodOptions.fee, 500);
        expect(request.methodOptions.timeoutInSeconds, 120);
        expect(request.methodOptions.simulate, false);
        expect(request.methodOptions.restore, true);
        expect(request.enableSorobanServerLogging, true);
      });
    });

    group('InstallRequest variations', () {
      test('creates install request with minimal fields', () {
        final wasmBytes = Uint8List.fromList([0, 97, 115, 109]);

        final request = InstallRequest(
          wasmBytes: wasmBytes,
          sourceAccountKeyPair: sourceKeyPair,
          network: Network.PUBLIC,
          rpcUrl: 'https://soroban-mainnet.stellar.org',
        );

        expect(request.wasmBytes, wasmBytes);
        expect(request.network, Network.PUBLIC);
        expect(request.rpcUrl, 'https://soroban-mainnet.stellar.org');
        expect(request.enableSorobanServerLogging, false);
      });

      test('creates install request with large wasm file', () {
        // Simulate a larger WASM file
        final wasmBytes = Uint8List.fromList(
          List.generate(10000, (i) => i % 256),
        );

        final request = InstallRequest(
          wasmBytes: wasmBytes,
          sourceAccountKeyPair: sourceKeyPair,
          network: Network.TESTNET,
          rpcUrl: rpcUrl,
          enableSorobanServerLogging: true,
        );

        expect(request.wasmBytes.length, 10000);
      });
    });

    group('ClientOptions with different networks', () {
      test('creates options with PUBLIC network', () {
        final options = ClientOptions(
          sourceAccountKeyPair: sourceKeyPair,
          contractId:
              'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK',
          network: Network.PUBLIC,
          rpcUrl: 'https://soroban-mainnet.stellar.org',
        );

        expect(options.network, Network.PUBLIC);
      });

      test('creates options with custom network', () {
        final customNetwork = Network('custom passphrase');
        final options = ClientOptions(
          sourceAccountKeyPair: sourceKeyPair,
          contractId:
              'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK',
          network: customNetwork,
          rpcUrl: 'https://custom-rpc.example.com',
        );

        expect(options.network.networkPassphrase, 'custom passphrase');
      });
    });

    group('MethodOptions variations', () {
      test('creates options with only fee specified', () {
        final options = MethodOptions(fee: 1000);

        expect(options.fee, 1000);
        expect(
            options.timeoutInSeconds, NetworkConstants.DEFAULT_TIMEOUT_SECONDS);
        expect(options.simulate, true);
        expect(options.restore, false);
      });

      test('creates options with only timeout specified', () {
        final options = MethodOptions(timeoutInSeconds: 30);

        expect(options.fee, NetworkConstants.DEFAULT_SOROBAN_BASE_FEE);
        expect(options.timeoutInSeconds, 30);
        expect(options.simulate, true);
        expect(options.restore, false);
      });

      test('creates options with all flags toggled', () {
        final options = MethodOptions(
          simulate: false,
          restore: true,
        );

        expect(options.simulate, false);
        expect(options.restore, true);
      });
    });

    group('AssembledTransactionOptions with various arguments', () {
      test('creates options with empty arguments list', () {
        final clientOptions = ClientOptions(
          sourceAccountKeyPair: sourceKeyPair,
          contractId:
              'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK',
          network: Network.TESTNET,
          rpcUrl: rpcUrl,
        );

        final options = AssembledTransactionOptions(
          clientOptions: clientOptions,
          methodOptions: MethodOptions(),
          method: 'no_args_method',
          arguments: [],
        );

        expect(options.arguments, isNotNull);
        expect(options.arguments!.length, 0);
      });

      test('creates options with multiple arguments', () {
        final clientOptions = ClientOptions(
          sourceAccountKeyPair: sourceKeyPair,
          contractId:
              'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK',
          network: Network.TESTNET,
          rpcUrl: rpcUrl,
        );

        final args = [
          XdrSCVal.forU32(1),
          XdrSCVal.forU64(BigInt.from(100)),
          XdrSCVal.forSymbol('test'),
          XdrSCVal.forBool(true),
        ];

        final options = AssembledTransactionOptions(
          clientOptions: clientOptions,
          methodOptions: MethodOptions(),
          method: 'multi_arg_method',
          arguments: args,
        );

        expect(options.arguments!.length, 4);
      });
    });

    group('SorobanClient with read-only keypair', () {
      test('creates client options with public key only', () {
        final publicKeyOnly = KeyPair.fromAccountId(sourceAccountId);

        final options = ClientOptions(
          sourceAccountKeyPair: publicKeyOnly,
          contractId:
              'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK',
          network: Network.TESTNET,
          rpcUrl: rpcUrl,
        );

        expect(options.sourceAccountKeyPair.accountId, sourceAccountId);
        // Public key only keypairs have null private key
        expect(options.sourceAccountKeyPair.privateKey, isNull);
      });
    });
  });
}
