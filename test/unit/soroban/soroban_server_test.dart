// Test response parsing and construction for soroban_server.dart classes
// These tests validate JSON deserialization, object construction, and helper methods
// without making any network calls

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
  group('GetHealthResponse', () {
    test('fromJson parses complete response', () {
      final json = {
        'result': {
          'status': 'healthy',
          'ledgerRetentionWindow': 17280,
          'latestLedger': 123456,
          'oldestLedger': 106176,
        }
      };

      final response = GetHealthResponse.fromJson(json);

      expect(response.status, equals('healthy'));
      expect(response.ledgerRetentionWindow, equals(17280));
      expect(response.latestLedger, equals(123456));
      expect(response.oldestLedger, equals(106176));
      expect(response.error, isNull);
    });

    test('fromJson handles partial response', () {
      final json = {
        'result': {'status': 'healthy'}
      };

      final response = GetHealthResponse.fromJson(json);

      expect(response.status, equals('healthy'));
      expect(response.ledgerRetentionWindow, isNull);
      expect(response.latestLedger, isNull);
      expect(response.oldestLedger, isNull);
    });

    test('fromJson handles error response', () {
      final json = {
        'error': {
          'code': '-32600',
          'message': 'Invalid request',
        }
      };

      final response = GetHealthResponse.fromJson(json);

      expect(response.status, isNull);
      expect(response.error, isNotNull);
      expect(response.error!.code, equals('-32600'));
      expect(response.error!.message, equals('Invalid request'));
    });

    test('constant HEALTHY is correct', () {
      expect(GetHealthResponse.HEALTHY, equals('healthy'));
    });
  });

  group('GetVersionInfoResponse', () {
    test('fromJson parses protocol version >= 22 format', () {
      final json = {
        'result': {
          'version': '1.2.3',
          'commitHash': 'abc123',
          'buildTimestamp': '2024-01-15T10:30:00Z',
          'captiveCoreVersion': '19.5.0',
          'protocolVersion': 22,
        }
      };

      final response = GetVersionInfoResponse.fromJson(json);

      expect(response.version, equals('1.2.3'));
      expect(response.commitHash, equals('abc123'));
      expect(response.buildTimeStamp, equals('2024-01-15T10:30:00Z'));
      expect(response.captiveCoreVersion, equals('19.5.0'));
      expect(response.protocolVersion, equals(22));
    });

    test('fromJson parses protocol version < 22 format', () {
      final json = {
        'result': {
          'version': '1.0.0',
          'commit_hash': 'def456',
          'build_time_stamp': '2023-12-01T08:00:00Z',
          'captive_core_version': '19.3.0',
          'protocol_version': 21,
        }
      };

      final response = GetVersionInfoResponse.fromJson(json);

      expect(response.version, equals('1.0.0'));
      expect(response.commitHash, equals('def456'));
      expect(response.buildTimeStamp, equals('2023-12-01T08:00:00Z'));
      expect(response.captiveCoreVersion, equals('19.3.0'));
      expect(response.protocolVersion, equals(21));
    });

    test('fromJson handles error response', () {
      final json = {
        'error': {
          'code': '-32601',
          'message': 'Method not found',
        }
      };

      final response = GetVersionInfoResponse.fromJson(json);

      expect(response.version, isNull);
      expect(response.error, isNotNull);
      expect(response.error!.message, equals('Method not found'));
    });
  });

  group('InclusionFee', () {
    test('fromJson parses complete fee statistics', () {
      final json = {
        'max': '1000',
        'min': '100',
        'mode': '200',
        'p10': '120',
        'p20': '150',
        'p30': '180',
        'p40': '200',
        'p50': '250',
        'p60': '300',
        'p70': '400',
        'p80': '500',
        'p90': '700',
        'p99': '950',
        'transactionCount': '5000',
        'ledgerCount': 20,
      };

      final fee = InclusionFee.fromJson(json);

      expect(fee.max, equals('1000'));
      expect(fee.min, equals('100'));
      expect(fee.mode, equals('200'));
      expect(fee.p10, equals('120'));
      expect(fee.p20, equals('150'));
      expect(fee.p30, equals('180'));
      expect(fee.p40, equals('200'));
      expect(fee.p50, equals('250'));
      expect(fee.p60, equals('300'));
      expect(fee.p70, equals('400'));
      expect(fee.p80, equals('500'));
      expect(fee.p90, equals('700'));
      expect(fee.p99, equals('950'));
      expect(fee.transactionCount, equals('5000'));
      expect(fee.ledgerCount, equals(20));
    });
  });

  group('GetFeeStatsResponse', () {
    test('fromJson parses complete response with both fee types', () {
      final json = {
        'result': {
          'sorobanInclusionFee': {
            'max': '2000',
            'min': '100',
            'mode': '150',
            'p10': '110',
            'p20': '120',
            'p30': '130',
            'p40': '140',
            'p50': '150',
            'p60': '160',
            'p70': '170',
            'p80': '180',
            'p90': '200',
            'p99': '500',
            'transactionCount': '1000',
            'ledgerCount': 10,
          },
          'inclusionFee': {
            'max': '500',
            'min': '50',
            'mode': '100',
            'p10': '55',
            'p20': '60',
            'p30': '70',
            'p40': '80',
            'p50': '100',
            'p60': '120',
            'p70': '150',
            'p80': '180',
            'p90': '200',
            'p99': '400',
            'transactionCount': '3000',
            'ledgerCount': 15,
          },
          'latestLedger': 654321,
        }
      };

      final response = GetFeeStatsResponse.fromJson(json);

      expect(response.sorobanInclusionFee, isNotNull);
      expect(response.sorobanInclusionFee!.max, equals('2000'));
      expect(response.sorobanInclusionFee!.p50, equals('150'));
      expect(response.inclusionFee, isNotNull);
      expect(response.inclusionFee!.min, equals('50'));
      expect(response.inclusionFee!.mode, equals('100'));
      expect(response.latestLedger, equals(654321));
    });

    test('fromJson handles missing soroban fees', () {
      final json = {
        'result': {
          'inclusionFee': {
            'max': '500',
            'min': '50',
            'mode': '100',
            'p10': '55',
            'p20': '60',
            'p30': '70',
            'p40': '80',
            'p50': '100',
            'p60': '120',
            'p70': '150',
            'p80': '180',
            'p90': '200',
            'p99': '400',
            'transactionCount': '3000',
            'ledgerCount': 15,
          },
          'latestLedger': 100000,
        }
      };

      final response = GetFeeStatsResponse.fromJson(json);

      expect(response.sorobanInclusionFee, isNull);
      expect(response.inclusionFee, isNotNull);
      expect(response.latestLedger, equals(100000));
    });
  });

  group('GetLatestLedgerResponse', () {
    test('fromJson parses complete response', () {
      final json = {
        'result': {
          'id': 'abcdef1234567890',
          'protocolVersion': 21,
          'sequence': 987654,
          'closeTime': 1705305600,
          'headerXdr': 'base64header',
          'metadataXdr': 'base64metadata',
        }
      };

      final response = GetLatestLedgerResponse.fromJson(json);

      expect(response.id, equals('abcdef1234567890'));
      expect(response.protocolVersion, equals(21));
      expect(response.sequence, equals(987654));
      expect(response.closeTime, equals(1705305600));
      expect(response.headerXdr, equals('base64header'));
      expect(response.metadataXdr, equals('base64metadata'));
    });

    test('fromJson handles closeTime as string', () {
      final json = {
        'result': {
          'id': 'hash123',
          'protocolVersion': 20,
          'sequence': 500000,
          'closeTime': '1705305600',
        }
      };

      final response = GetLatestLedgerResponse.fromJson(json);

      expect(response.closeTime, equals(1705305600));
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'result': {
          'id': 'hash456',
          'protocolVersion': 21,
          'sequence': 600000,
        }
      };

      final response = GetLatestLedgerResponse.fromJson(json);

      expect(response.id, equals('hash456'));
      expect(response.closeTime, isNull);
      expect(response.headerXdr, isNull);
      expect(response.metadataXdr, isNull);
    });
  });

  group('SorobanRpcErrorResponse', () {
    test('fromJson parses error with data', () {
      final json = {
        'error': {
          'code': -32700,
          'message': 'Parse error',
          'data': {'details': 'Invalid JSON format'},
        }
      };

      final response = SorobanRpcErrorResponse.fromJson(json);

      expect(response.code, equals('-32700'));
      expect(response.message, equals('Parse error'));
      expect(response.data, isNotNull);
      expect(response.data!['details'], equals('Invalid JSON format'));
    });

    test('fromJson handles string code', () {
      final json = {
        'error': {
          'code': '-32600',
          'message': 'Invalid Request',
        }
      };

      final response = SorobanRpcErrorResponse.fromJson(json);

      expect(response.code, equals('-32600'));
    });

    test('fromJson handles numeric code', () {
      final json = {
        'error': {
          'code': -32601,
          'message': 'Method not found',
        }
      };

      final response = SorobanRpcErrorResponse.fromJson(json);

      expect(response.code, equals('-32601'));
    });

    test('fromJson handles missing data field', () {
      final json = {
        'error': {
          'code': -32602,
          'message': 'Invalid params',
        }
      };

      final response = SorobanRpcErrorResponse.fromJson(json);

      expect(response.data, isNull);
    });
  });

  group('GetLedgerEntriesResponse', () {
    test('fromJson handles empty entries', () {
      final json = {
        'result': {
          'entries': [],
          'latestLedger': 123456,
        }
      };

      final response = GetLedgerEntriesResponse.fromJson(json);

      expect(response.entries, isNotNull);
      expect(response.entries!.length, equals(0));
      expect(response.latestLedger, equals(123456));
    });

    test('fromJson handles error response', () {
      final json = {
        'error': {
          'code': '-32600',
          'message': 'Invalid request',
        }
      };

      final response = GetLedgerEntriesResponse.fromJson(json);

      expect(response.error, isNotNull);
      expect(response.error!.code, equals('-32600'));
    });
  });

  group('GetNetworkResponse', () {
    test('fromJson parses network information', () {
      final json = {
        'result': {
          'friendbotUrl': 'https://friendbot.stellar.org',
          'passphrase': 'Test SDF Network ; September 2015',
          'protocolVersion': 21,
        }
      };

      final response = GetNetworkResponse.fromJson(json);

      expect(response.friendbotUrl, equals('https://friendbot.stellar.org'));
      expect(response.passphrase, equals('Test SDF Network ; September 2015'));
      expect(response.protocolVersion, equals(21));
    });

    test('fromJson handles missing friendbot', () {
      final json = {
        'result': {
          'passphrase': 'Public Global Stellar Network ; September 2015',
          'protocolVersion': 21,
        }
      };

      final response = GetNetworkResponse.fromJson(json);

      expect(response.friendbotUrl, isNull);
      expect(response.passphrase,
          equals('Public Global Stellar Network ; September 2015'));
    });
  });

  group('SendTransactionResponse', () {
    test('constants are correct', () {
      expect(SendTransactionResponse.STATUS_PENDING, equals('PENDING'));
      expect(SendTransactionResponse.STATUS_DUPLICATE, equals('DUPLICATE'));
      expect(SendTransactionResponse.STATUS_TRY_AGAIN_LATER,
          equals('TRY_AGAIN_LATER'));
      expect(SendTransactionResponse.STATUS_ERROR, equals('ERROR'));
    });

    test('fromJson parses successful send', () {
      final json = {
        'result': {
          'status': 'PENDING',
          'hash': 'abc123def456',
          'latestLedger': 100000,
          'latestLedgerCloseTime': '1705305600',
        }
      };

      final response = SendTransactionResponse.fromJson(json);

      expect(response.status, equals('PENDING'));
      expect(response.hash, equals('abc123def456'));
      expect(response.latestLedger, equals(100000));
      expect(response.latestLedgerCloseTime, equals('1705305600'));
      expect(response.errorResultXdr, isNull);
    });

    test('fromJson parses error send', () {
      final json = {
        'result': {
          'status': 'ERROR',
          'errorResultXdr': 'base64errorxdr',
          'latestLedger': 100001,
          'latestLedgerCloseTime': '1705305601',
        }
      };

      final response = SendTransactionResponse.fromJson(json);

      expect(response.status, equals('ERROR'));
      expect(response.errorResultXdr, equals('base64errorxdr'));
      expect(response.hash, isNull);
    });
  });

  group('GetTransactionResponse', () {
    test('constants are correct', () {
      expect(GetTransactionResponse.STATUS_SUCCESS, equals('SUCCESS'));
      expect(GetTransactionResponse.STATUS_NOT_FOUND, equals('NOT_FOUND'));
      expect(GetTransactionResponse.STATUS_FAILED, equals('FAILED'));
    });

    test('fromJson parses successful transaction', () {
      final json = {
        'result': {
          'status': 'SUCCESS',
          'latestLedger': 200000,
          'latestLedgerCloseTime': '1705305700',
          'oldestLedger': 180000,
          'oldestLedgerCloseTime': '1705295700',
          'applicationOrder': 1,
          'feeBump': false,
          'envelopeXdr': 'base64envelope',
          'resultXdr': 'base64result',
          'resultMetaXdr': 'base64meta',
          'ledger': 199999,
          'createdAt': '1705305699',
        }
      };

      final response = GetTransactionResponse.fromJson(json);

      expect(response.status, equals('SUCCESS'));
      expect(response.latestLedger, equals(200000));
      expect(response.latestLedgerCloseTime, equals('1705305700'));
      expect(response.oldestLedger, equals(180000));
      expect(response.oldestLedgerCloseTime, equals('1705295700'));
      expect(response.applicationOrder, equals(1));
      expect(response.feeBump, equals(false));
      expect(response.envelopeXdr, equals('base64envelope'));
      expect(response.resultXdr, equals('base64result'));
      expect(response.resultMetaXdr, equals('base64meta'));
      expect(response.ledger, equals(199999));
      expect(response.createdAt, equals('1705305699'));
    });

    test('fromJson parses not found transaction', () {
      final json = {
        'result': {
          'status': 'NOT_FOUND',
          'latestLedger': 200000,
          'latestLedgerCloseTime': '1705305700',
          'oldestLedger': 180000,
          'oldestLedgerCloseTime': '1705295700',
        }
      };

      final response = GetTransactionResponse.fromJson(json);

      expect(response.status, equals('NOT_FOUND'));
      expect(response.resultXdr, isNull);
      expect(response.envelopeXdr, isNull);
    });

    test('fromJson parses failed transaction', () {
      final json = {
        'result': {
          'status': 'FAILED',
          'latestLedger': 200001,
          'latestLedgerCloseTime': '1705305701',
          'oldestLedger': 180001,
          'oldestLedgerCloseTime': '1705295701',
          'applicationOrder': 2,
          'feeBump': false,
          'envelopeXdr': 'base64envelope',
          'resultXdr': 'base64failedresult',
          'resultMetaXdr': 'base64failedmeta',
          'ledger': 200000,
          'createdAt': '1705305700',
        }
      };

      final response = GetTransactionResponse.fromJson(json);

      expect(response.status, equals('FAILED'));
      expect(response.resultXdr, equals('base64failedresult'));
    });
  });

  group('SimulateTransactionResponse', () {
    test('fromJson parses response fields', () {
      final json = {
        'result': {
          'latestLedger': 300000,
        }
      };

      final response = SimulateTransactionResponse.fromJson(json);

      expect(response.latestLedger, equals(300000));
      expect(response.restorePreamble, isNull);
    });

    test('fromJson parses error field', () {
      final json = {
        'result': {
          'error': 'transaction simulation failed',
          'latestLedger': 300001,
        }
      };

      final response = SimulateTransactionResponse.fromJson(json);

      expect(response.resultError, equals('transaction simulation failed'));
      expect(response.latestLedger, equals(300001));
    });

    test('fromJson handles numeric minResourceFee', () {
      final json = {
        'result': {
          'minResourceFee': 12345,
          'latestLedger': 300002,
        }
      };

      final response = SimulateTransactionResponse.fromJson(json);

      expect(response.minResourceFee, equals(12345));
    });

    test('fromJson handles string minResourceFee', () {
      final json = {
        'result': {
          'minResourceFee': '67890',
          'latestLedger': 300003,
        }
      };

      final response = SimulateTransactionResponse.fromJson(json);

      expect(response.minResourceFee, equals(67890));
    });
  });

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
  });

  group('MethodOptions', () {
    test('creates with default values', () {
      final options = MethodOptions();

      expect(options.fee, equals(100));
      expect(options.timeoutInSeconds, equals(300));
      expect(options.simulate, equals(true));
      expect(options.restore, equals(false));
    });

    test('creates with custom values', () {
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

    test('creates with constructor args and salt', () {
      final keyPair = KeyPair.random();
      final args = [XdrSCVal.forU32(42)];
      final salt = XdrUint256(Uint8List(32));

      final request = DeployRequest(
        sourceAccountKeyPair: keyPair,
        network: Network.TESTNET,
        rpcUrl: 'https://test.example.com',
        wasmHash: 'hash789',
        constructorArgs: args,
        salt: salt,
      );

      expect(request.constructorArgs, equals(args));
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
  });

  group('SorobanServer Mock Tests', () {
    group('getHealth', () {
      test('returns healthy status with retention window', () async {
        var mockDio = dio.Dio();
        mockDio.httpClientAdapter = MockDioAdapter((options) {
          var requestBody = jsonDecode(options.data);
          expect(requestBody['jsonrpc'], '2.0');
          expect(requestBody['method'], 'getHealth');

          return dio.ResponseBody.fromString(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': requestBody['id'],
              'result': {
                'status': 'healthy',
                'ledgerRetentionWindow': 17280,
                'latestLedger': 100000,
                'oldestLedger': 82720,
              }
            }),
            200,
            headers: {'content-type': [dio.Headers.jsonContentType]},
          );
        });

        var server = SorobanServer.withDio(
            'https://soroban-testnet.stellar.org', mockDio);

        final response = await server.getHealth();

        expect(response.status, 'healthy');
        expect(response.ledgerRetentionWindow, 17280);
        expect(response.latestLedger, 100000);
        expect(response.oldestLedger, 82720);
      });

      test('returns unhealthy status', () async {
        var mockDio = dio.Dio();
        mockDio.httpClientAdapter = MockDioAdapter((options) {
          var requestBody = jsonDecode(options.data);
          expect(requestBody['method'], 'getHealth');

          return dio.ResponseBody.fromString(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': requestBody['id'],
              'result': {
                'status': 'unhealthy',
                'ledgerRetentionWindow': 0,
                'latestLedger': 0,
                'oldestLedger': 0,
              }
            }),
            200,
            headers: {'content-type': [dio.Headers.jsonContentType]},
          );
        });

        var server = SorobanServer.withDio(
            'https://soroban-testnet.stellar.org', mockDio);

        final response = await server.getHealth();

        expect(response.status, 'unhealthy');
      });
    });

    group('getNetwork', () {
      test('returns network passphrase and protocol version', () async {
        var mockDio = dio.Dio();
        mockDio.httpClientAdapter = MockDioAdapter((options) {
          var requestBody = jsonDecode(options.data);
          expect(requestBody['method'], 'getNetwork');

          return dio.ResponseBody.fromString(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': requestBody['id'],
              'result': {
                'friendbotUrl': 'https://friendbot.stellar.org',
                'passphrase': 'Test SDF Network ; September 2015',
                'protocolVersion': 20,
              }
            }),
            200,
            headers: {'content-type': [dio.Headers.jsonContentType]},
          );
        });

        var server = SorobanServer.withDio(
            'https://soroban-testnet.stellar.org', mockDio);

        final response = await server.getNetwork();

        expect(response.friendbotUrl, 'https://friendbot.stellar.org');
        expect(response.passphrase, 'Test SDF Network ; September 2015');
        expect(response.protocolVersion, 20);
      });

      test('returns network without friendbot URL', () async {
        var mockDio = dio.Dio();
        mockDio.httpClientAdapter = MockDioAdapter((options) {
          var requestBody = jsonDecode(options.data);
          expect(requestBody['method'], 'getNetwork');

          return dio.ResponseBody.fromString(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': requestBody['id'],
              'result': {
                'passphrase': 'Public Global Stellar Network ; September 2015',
                'protocolVersion': 20,
              }
            }),
            200,
            headers: {'content-type': [dio.Headers.jsonContentType]},
          );
        });

        var server = SorobanServer.withDio(
            'https://soroban-mainnet.stellar.org', mockDio);

        final response = await server.getNetwork();

        expect(response.friendbotUrl, isNull);
        expect(response.passphrase,
            'Public Global Stellar Network ; September 2015');
        expect(response.protocolVersion, 20);
      });
    });

    group('getLatestLedger', () {
      test('returns latest ledger info', () async {
        var mockDio = dio.Dio();
        mockDio.httpClientAdapter = MockDioAdapter((options) {
          var requestBody = jsonDecode(options.data);
          expect(requestBody['method'], 'getLatestLedger');

          return dio.ResponseBody.fromString(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': requestBody['id'],
              'result': {
                'id': 'a7d8f6c5e9b1a3d2f4c8e7b9a5c3d1f2e8b6c4d7a9e1f3b5c2d8e6a4b7c9d1e2',
                'protocolVersion': 20,
                'sequence': 100000,
              }
            }),
            200,
            headers: {'content-type': [dio.Headers.jsonContentType]},
          );
        });

        var server = SorobanServer.withDio(
            'https://soroban-testnet.stellar.org', mockDio);

        final response = await server.getLatestLedger();

        expect(response.id,
            'a7d8f6c5e9b1a3d2f4c8e7b9a5c3d1f2e8b6c4d7a9e1f3b5c2d8e6a4b7c9d1e2');
        expect(response.protocolVersion, 20);
        expect(response.sequence, 100000);
      });
    });

    group('getAccount', () {
      test('returns account with sequence number', () async {
        final accountId =
            'GDAT5HWTGIU4TSSZ4752OUC4SABDLTLZFRPZUJ3D6LKBNEPA7V2CIG54';
        final keyPair = KeyPair.fromAccountId(accountId);

        var mockDio = dio.Dio();
        mockDio.httpClientAdapter = MockDioAdapter((options) {
          var requestBody = jsonDecode(options.data);
          expect(requestBody['method'], 'getLedgerEntries');
          expect(requestBody['params']['keys'], isList);
          expect((requestBody['params']['keys'] as List).length, 1);

          // Create mock account entry
          var accountEntry = XdrAccountEntry(
            XdrAccountID(keyPair.xdrPublicKey),
            XdrInt64(BigInt.zero),
            XdrSequenceNumber(XdrBigInt64(BigInt.from(123456789))),
            XdrUint32(0),
            null,
            XdrUint32(0),
            XdrString32(''),
            XdrThresholds(Uint8List.fromList([1, 0, 0, 0])),
            [],
            XdrAccountEntryExt(0),
          );

          var ledgerEntryData = XdrLedgerEntryData(XdrLedgerEntryType.ACCOUNT);
          ledgerEntryData.account = accountEntry;

          return dio.ResponseBody.fromString(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': requestBody['id'],
              'result': {
                'entries': [
                  {
                    'key': (requestBody['params']['keys'] as List)[0],
                    'xdr': ledgerEntryData.toBase64EncodedXdrString(),
                    'lastModifiedLedgerSeq': 99999,
                  }
                ],
                'latestLedger': 100000,
              }
            }),
            200,
            headers: {'content-type': [dio.Headers.jsonContentType]},
          );
        });

        var server = SorobanServer.withDio(
            'https://soroban-testnet.stellar.org', mockDio);

        final account = await server.getAccount(accountId);

        expect(account, isNotNull);
        expect(account!.accountId, accountId);
        expect(account.sequenceNumber, BigInt.from(123456789));
      });

      test('returns null for non-existent account', () async {
        final accountId =
            'GDAT5HWTGIU4TSSZ4752OUC4SABDLTLZFRPZUJ3D6LKBNEPA7V2CIG54';

        var mockDio = dio.Dio();
        mockDio.httpClientAdapter = MockDioAdapter((options) {
          var requestBody = jsonDecode(options.data);
          expect(requestBody['method'], 'getLedgerEntries');

          return dio.ResponseBody.fromString(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': requestBody['id'],
              'result': {
                'entries': [],
                'latestLedger': 100000,
              }
            }),
            200,
            headers: {'content-type': [dio.Headers.jsonContentType]},
          );
        });

        var server = SorobanServer.withDio(
            'https://soroban-testnet.stellar.org', mockDio);

        final account = await server.getAccount(accountId);

        expect(account, isNull);
      });
    });

    group('getLedgerEntries', () {
      test('returns ledger entries for provided keys', () async {
        final accountId =
            'GDAT5HWTGIU4TSSZ4752OUC4SABDLTLZFRPZUJ3D6LKBNEPA7V2CIG54';
        final keyPair = KeyPair.fromAccountId(accountId);

        var ledgerKey = XdrLedgerKey(XdrLedgerEntryType.ACCOUNT);
        ledgerKey.account = XdrLedgerKeyAccount(
            XdrAccountID(keyPair.xdrPublicKey));
        final base64Key = ledgerKey.toBase64EncodedXdrString();

        var mockDio = dio.Dio();
        mockDio.httpClientAdapter = MockDioAdapter((options) {
          var requestBody = jsonDecode(options.data);
          expect(requestBody['method'], 'getLedgerEntries');
          expect(requestBody['params']['keys'], [base64Key]);

          var accountEntry = XdrAccountEntry(
            XdrAccountID(keyPair.xdrPublicKey),
            XdrInt64(BigInt.zero),
            XdrSequenceNumber(XdrBigInt64(BigInt.from(123456789))),
            XdrUint32(0),
            null,
            XdrUint32(0),
            XdrString32(''),
            XdrThresholds(Uint8List.fromList([1, 0, 0, 0])),
            [],
            XdrAccountEntryExt(0),
          );

          var ledgerEntryData = XdrLedgerEntryData(XdrLedgerEntryType.ACCOUNT);
          ledgerEntryData.account = accountEntry;

          return dio.ResponseBody.fromString(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': requestBody['id'],
              'result': {
                'entries': [
                  {
                    'key': base64Key,
                    'xdr': ledgerEntryData.toBase64EncodedXdrString(),
                    'lastModifiedLedgerSeq': 99999,
                  }
                ],
                'latestLedger': 100000,
              }
            }),
            200,
            headers: {'content-type': [dio.Headers.jsonContentType]},
          );
        });

        var server = SorobanServer.withDio(
            'https://soroban-testnet.stellar.org', mockDio);

        final response = await server.getLedgerEntries([base64Key]);

        expect(response.entries, isNotNull);
        expect(response.entries!.length, 1);
        expect(response.entries![0].key, base64Key);
        expect(response.latestLedger, 100000);
      });

      test('returns empty entries for non-existent keys', () async {
        final fakeKey = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';

        var mockDio = dio.Dio();
        mockDio.httpClientAdapter = MockDioAdapter((options) {
          var requestBody = jsonDecode(options.data);
          expect(requestBody['method'], 'getLedgerEntries');

          return dio.ResponseBody.fromString(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': requestBody['id'],
              'result': {
                'entries': [],
                'latestLedger': 100000,
              }
            }),
            200,
            headers: {'content-type': [dio.Headers.jsonContentType]},
          );
        });

        var server = SorobanServer.withDio(
            'https://soroban-testnet.stellar.org', mockDio);

        final response = await server.getLedgerEntries([fakeKey]);

        expect(response.entries, isNotNull);
        expect(response.entries!.length, 0);
      });
    });

    group('getFeeStats', () {
      test('returns fee statistics for Soroban and classic transactions',
          () async {
        var mockDio = dio.Dio();
        mockDio.httpClientAdapter = MockDioAdapter((options) {
          var requestBody = jsonDecode(options.data);
          expect(requestBody['method'], 'getFeeStats');

          return dio.ResponseBody.fromString(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': requestBody['id'],
              'result': {
                'sorobanInclusionFee': {
                  'max': '1000',
                  'min': '100',
                  'mode': '150',
                  'p10': '110',
                  'p20': '120',
                  'p30': '130',
                  'p40': '140',
                  'p50': '150',
                  'p60': '160',
                  'p70': '170',
                  'p80': '180',
                  'p90': '200',
                  'p95': '300',
                  'p99': '500',
                  'transactionCount': '500',
                  'ledgerCount': 10,
                },
                'inclusionFee': {
                  'max': '500',
                  'min': '100',
                  'mode': '100',
                  'p10': '100',
                  'p20': '100',
                  'p30': '100',
                  'p40': '100',
                  'p50': '100',
                  'p60': '100',
                  'p70': '100',
                  'p80': '100',
                  'p90': '100',
                  'p95': '200',
                  'p99': '300',
                  'transactionCount': '1000',
                  'ledgerCount': 10,
                },
                'latestLedger': 100000,
              }
            }),
            200,
            headers: {'content-type': [dio.Headers.jsonContentType]},
          );
        });

        var server = SorobanServer.withDio(
            'https://soroban-testnet.stellar.org', mockDio);

        final response = await server.getFeeStats();

        expect(response.sorobanInclusionFee, isNotNull);
        expect(response.sorobanInclusionFee!.max, '1000');
        expect(response.sorobanInclusionFee!.min, '100');
        expect(response.sorobanInclusionFee!.p50, '150');
        expect(response.sorobanInclusionFee!.transactionCount, '500');

        expect(response.inclusionFee, isNotNull);
        expect(response.inclusionFee!.max, '500');
        expect(response.inclusionFee!.p50, '100');

        expect(response.latestLedger, 100000);
      });
    });

    group('getVersionInfo', () {
      test('returns version and build information', () async {
        var mockDio = dio.Dio();
        mockDio.httpClientAdapter = MockDioAdapter((options) {
          var requestBody = jsonDecode(options.data);
          expect(requestBody['method'], 'getVersionInfo');

          // Use both camelCase (protocol >= 22) and snake_case (protocol < 22) for compatibility
          return dio.ResponseBody.fromString(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': requestBody['id'],
              'result': {
                'version': '20.5.0',
                'commit_hash': 'a1b2c3d4e5f6g7h8i9j0',
                'build_time_stamp': '2024-01-15T10:30:00Z',
                'captive_core_version': '19.14.0',
                'protocol_version': 20,
              }
            }),
            200,
            headers: {'content-type': [dio.Headers.jsonContentType]},
          );
        });

        var server = SorobanServer.withDio(
            'https://soroban-testnet.stellar.org', mockDio);

        final response = await server.getVersionInfo();

        expect(response.version, '20.5.0');
        expect(response.commitHash, 'a1b2c3d4e5f6g7h8i9j0');
        expect(response.buildTimeStamp, '2024-01-15T10:30:00Z');
        expect(response.captiveCoreVersion, '19.14.0');
        expect(response.protocolVersion, 20);
      });
    });

    group('simulateTransaction', () {
      test('returns successful simulation with results and resource fee',
          () async {
        final sourceAccountId =
            'GDAT5HWTGIU4TSSZ4752OUC4SABDLTLZFRPZUJ3D6LKBNEPA7V2CIG54';
        final sourceKeyPair = KeyPair.fromAccountId(sourceAccountId);
        final sourceAccount = Account(sourceAccountId, BigInt.from(123456));

        var mockDio = dio.Dio();
        mockDio.httpClientAdapter = MockDioAdapter((options) {
          var requestBody = jsonDecode(options.data);
          expect(requestBody['method'], 'simulateTransaction');
          expect(requestBody['params']['transaction'], isNotNull);

          // Mock successful simulation response
          final resultValue = XdrSCVal.forU32(42);

          return dio.ResponseBody.fromString(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': requestBody['id'],
              'result': {
                'minResourceFee': '100000',
                'cost': {
                  'cpuInsns': '1000',
                  'memBytes': '100',
                },
                'results': [
                  {
                    'auth': [],
                    'xdr': resultValue.toBase64EncodedXdrString(),
                  }
                ],
                'latestLedger': 100000,
              }
            }),
            200,
            headers: {'content-type': [dio.Headers.jsonContentType]},
          );
        });

        var server = SorobanServer.withDio(
            'https://soroban-testnet.stellar.org', mockDio);

        // Create a simple transaction
        final tx = TransactionBuilder(sourceAccount)
            .addOperation(
                BumpSequenceOperation(BigInt.from(123456 + 10)))
            .build();

        final request = SimulateTransactionRequest(tx);
        final response = await server.simulateTransaction(request);

        expect(response.resultError, isNull);
        expect(response.minResourceFee, 100000);
        expect(response.results, isNotNull);
        expect(response.results!.length, 1);
        expect(response.latestLedger, 100000);
        // Note: Not validating transactionData XDR parsing in mock test
      });

      test('returns error response on simulation failure', () async {
        final sourceAccountId =
            'GDAT5HWTGIU4TSSZ4752OUC4SABDLTLZFRPZUJ3D6LKBNEPA7V2CIG54';
        final sourceAccount = Account(sourceAccountId, BigInt.from(123456));

        var mockDio = dio.Dio();
        mockDio.httpClientAdapter = MockDioAdapter((options) {
          var requestBody = jsonDecode(options.data);
          expect(requestBody['method'], 'simulateTransaction');

          return dio.ResponseBody.fromString(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': requestBody['id'],
              'result': {
                'error': 'Transaction simulation failed: insufficient balance',
                'latestLedger': 100000,
              }
            }),
            200,
            headers: {'content-type': [dio.Headers.jsonContentType]},
          );
        });

        var server = SorobanServer.withDio(
            'https://soroban-testnet.stellar.org', mockDio);

        final tx = TransactionBuilder(sourceAccount)
            .addOperation(
                BumpSequenceOperation(BigInt.from(123456 + 10)))
            .build();

        final request = SimulateTransactionRequest(tx);
        final response = await server.simulateTransaction(request);

        expect(response.resultError, isNotNull);
        expect(response.resultError,
            'Transaction simulation failed: insufficient balance');
      });

      test('returns cost information for simulation', () async {
        final sourceAccountId =
            'GDAT5HWTGIU4TSSZ4752OUC4SABDLTLZFRPZUJ3D6LKBNEPA7V2CIG54';
        final sourceAccount = Account(sourceAccountId, BigInt.from(123456));

        var mockDio = dio.Dio();
        mockDio.httpClientAdapter = MockDioAdapter((options) {
          var requestBody = jsonDecode(options.data);
          expect(requestBody['method'], 'simulateTransaction');

          return dio.ResponseBody.fromString(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': requestBody['id'],
              'result': {
                'minResourceFee': '50000',
                'cost': {
                  'cpuInsns': '2000',
                  'memBytes': '200',
                },
                'latestLedger': 100000,
              }
            }),
            200,
            headers: {'content-type': [dio.Headers.jsonContentType]},
          );
        });

        var server = SorobanServer.withDio(
            'https://soroban-testnet.stellar.org', mockDio);

        final tx = TransactionBuilder(sourceAccount)
            .addOperation(
                BumpSequenceOperation(BigInt.from(123456 + 10)))
            .build();

        final request = SimulateTransactionRequest(tx);
        final response = await server.simulateTransaction(request);

        expect(response.minResourceFee, 50000);
        expect(response.latestLedger, 100000);
      });
    });

    group('sendTransaction', () {
      test('returns PENDING status on successful submission', () async {
        final sourceKeyPair = KeyPair.random();
        final sourceAccountId = sourceKeyPair.accountId;
        final sourceAccount = Account(sourceAccountId, BigInt.from(123456));

        var mockDio = dio.Dio();
        mockDio.httpClientAdapter = MockDioAdapter((options) {
          var requestBody = jsonDecode(options.data);
          expect(requestBody['method'], 'sendTransaction');
          expect(requestBody['params']['transaction'], isNotNull);

          return dio.ResponseBody.fromString(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': requestBody['id'],
              'result': {
                'status': 'PENDING',
                'hash': 'a7d8f6c5e9b1a3d2f4c8e7b9a5c3d1f2e8b6c4d7a9e1f3b5c2d8e6a4b7c9d1e2',
                'latestLedger': 100000,
                'latestLedgerCloseTime': '1234567890',
              }
            }),
            200,
            headers: {'content-type': [dio.Headers.jsonContentType]},
          );
        });

        var server = SorobanServer.withDio(
            'https://soroban-testnet.stellar.org', mockDio);

        final tx = TransactionBuilder(sourceAccount)
            .addOperation(
                BumpSequenceOperation(BigInt.from(123456 + 10)))
            .build();
        tx.sign(sourceKeyPair, Network.TESTNET);

        final response = await server.sendTransaction(tx);

        expect(response.status, SendTransactionResponse.STATUS_PENDING);
        expect(response.hash,
            'a7d8f6c5e9b1a3d2f4c8e7b9a5c3d1f2e8b6c4d7a9e1f3b5c2d8e6a4b7c9d1e2');
        expect(response.latestLedger, 100000);
      });

      test('returns ERROR status on transaction error', () async {
        final sourceKeyPair = KeyPair.random();
        final sourceAccountId = sourceKeyPair.accountId;
        final sourceAccount = Account(sourceAccountId, BigInt.from(123456));

        var mockDio = dio.Dio();
        mockDio.httpClientAdapter = MockDioAdapter((options) {
          var requestBody = jsonDecode(options.data);
          expect(requestBody['method'], 'sendTransaction');

          return dio.ResponseBody.fromString(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': requestBody['id'],
              'result': {
                'status': 'ERROR',
                'hash': 'a7d8f6c5e9b1a3d2f4c8e7b9a5c3d1f2e8b6c4d7a9e1f3b5c2d8e6a4b7c9d1e2',
                'errorResultXdr': 'AAAAAAAAAGT/////AAAAAQAAAAAAAAAB////+gAAAAA=',
                'latestLedger': 100000,
                'latestLedgerCloseTime': '1234567890',
              }
            }),
            200,
            headers: {'content-type': [dio.Headers.jsonContentType]},
          );
        });

        var server = SorobanServer.withDio(
            'https://soroban-testnet.stellar.org', mockDio);

        final tx = TransactionBuilder(sourceAccount)
            .addOperation(
                BumpSequenceOperation(BigInt.from(123456 + 10)))
            .build();
        tx.sign(sourceKeyPair, Network.TESTNET);

        final response = await server.sendTransaction(tx);

        expect(response.status, SendTransactionResponse.STATUS_ERROR);
        expect(response.errorResultXdr, isNotNull);
      });

      test('returns DUPLICATE status when transaction already submitted',
          () async {
        final sourceKeyPair = KeyPair.random();
        final sourceAccountId = sourceKeyPair.accountId;
        final sourceAccount = Account(sourceAccountId, BigInt.from(123456));

        var mockDio = dio.Dio();
        mockDio.httpClientAdapter = MockDioAdapter((options) {
          var requestBody = jsonDecode(options.data);
          expect(requestBody['method'], 'sendTransaction');

          return dio.ResponseBody.fromString(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': requestBody['id'],
              'result': {
                'status': 'DUPLICATE',
                'hash': 'a7d8f6c5e9b1a3d2f4c8e7b9a5c3d1f2e8b6c4d7a9e1f3b5c2d8e6a4b7c9d1e2',
                'latestLedger': 100000,
                'latestLedgerCloseTime': '1234567890',
              }
            }),
            200,
            headers: {'content-type': [dio.Headers.jsonContentType]},
          );
        });

        var server = SorobanServer.withDio(
            'https://soroban-testnet.stellar.org', mockDio);

        final tx = TransactionBuilder(sourceAccount)
            .addOperation(
                BumpSequenceOperation(BigInt.from(123456 + 10)))
            .build();
        tx.sign(sourceKeyPair, Network.TESTNET);

        final response = await server.sendTransaction(tx);

        expect(response.status, SendTransactionResponse.STATUS_DUPLICATE);
        expect(response.hash,
            'a7d8f6c5e9b1a3d2f4c8e7b9a5c3d1f2e8b6c4d7a9e1f3b5c2d8e6a4b7c9d1e2');
      });

      test('returns TRY_AGAIN_LATER status when server is busy', () async {
        final sourceKeyPair = KeyPair.random();
        final sourceAccountId = sourceKeyPair.accountId;
        final sourceAccount = Account(sourceAccountId, BigInt.from(123456));

        var mockDio = dio.Dio();
        mockDio.httpClientAdapter = MockDioAdapter((options) {
          var requestBody = jsonDecode(options.data);
          expect(requestBody['method'], 'sendTransaction');

          return dio.ResponseBody.fromString(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': requestBody['id'],
              'result': {
                'status': 'TRY_AGAIN_LATER',
                'hash': 'a7d8f6c5e9b1a3d2f4c8e7b9a5c3d1f2e8b6c4d7a9e1f3b5c2d8e6a4b7c9d1e2',
                'latestLedger': 100000,
                'latestLedgerCloseTime': '1234567890',
              }
            }),
            200,
            headers: {'content-type': [dio.Headers.jsonContentType]},
          );
        });

        var server = SorobanServer.withDio(
            'https://soroban-testnet.stellar.org', mockDio);

        final tx = TransactionBuilder(sourceAccount)
            .addOperation(
                BumpSequenceOperation(BigInt.from(123456 + 10)))
            .build();
        tx.sign(sourceKeyPair, Network.TESTNET);

        final response = await server.sendTransaction(tx);

        expect(
            response.status, SendTransactionResponse.STATUS_TRY_AGAIN_LATER);
      });
    });

    group('getTransaction', () {
      test('returns SUCCESS status with result XDR', () async {
        final txHash =
            'a7d8f6c5e9b1a3d2f4c8e7b9a5c3d1f2e8b6c4d7a9e1f3b5c2d8e6a4b7c9d1e2';

        var mockDio = dio.Dio();
        mockDio.httpClientAdapter = MockDioAdapter((options) {
          var requestBody = jsonDecode(options.data);
          expect(requestBody['method'], 'getTransaction');
          expect(requestBody['params']['hash'], txHash);

          return dio.ResponseBody.fromString(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': requestBody['id'],
              'result': {
                'status': 'SUCCESS',
                'ledger': 99999,
                'createdAt': '1234567890',
                'applicationOrder': 1,
                'feeBump': false,
                'envelopeXdr':
                    'AAAAAgAAAABzdv3ojkzWHMD7KUoXhrPx0GH18vHKV0ZfqpMiEblG1gAAAGQAAAAAAAAAAgAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAEAAAAAc3b96I5M1hzA+ylKF4az8dBh9fLxyldGX6qTIhG5RtYAAAABAAAAAHN2/eiOTNYcwPspSheGs/HQYfXy8cpXRl+qkyIRuUbWAAAAAAAAAAAF9eEAAAAAAAAAAAIRuUbWAAAAQHnJ0a5x7tKWBH+QV+HMBx5eGgc+3cDVmqLVTlpHtqJKnXWFDlUqL+tKKk+HqXKHqXKHqXKHqXKHqXKHqXKHqXKHqXo=',
                'resultXdr': 'AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAA=',
                'resultMetaXdr':
                    'AAAAAgAAAAIAAAADAAGGoQAAAAAAAAAAdVGJlbmFtZSI6IkludGVybmFsIFNlcnZlciBFcnJvciJ9',
              }
            }),
            200,
            headers: {'content-type': [dio.Headers.jsonContentType]},
          );
        });

        var server = SorobanServer.withDio(
            'https://soroban-testnet.stellar.org', mockDio);

        final response = await server.getTransaction(txHash);

        expect(response.status, GetTransactionResponse.STATUS_SUCCESS);
        expect(response.ledger, 99999);
        expect(response.createdAt, '1234567890');
        expect(response.envelopeXdr, isNotNull);
        expect(response.resultXdr, isNotNull);
        expect(response.resultMetaXdr, isNotNull);
      });

      test('returns NOT_FOUND status for non-existent transaction', () async {
        final txHash =
            'a7d8f6c5e9b1a3d2f4c8e7b9a5c3d1f2e8b6c4d7a9e1f3b5c2d8e6a4b7c9d1e2';

        var mockDio = dio.Dio();
        mockDio.httpClientAdapter = MockDioAdapter((options) {
          var requestBody = jsonDecode(options.data);
          expect(requestBody['method'], 'getTransaction');

          return dio.ResponseBody.fromString(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': requestBody['id'],
              'result': {
                'status': 'NOT_FOUND',
                'latestLedger': 100000,
                'latestLedgerCloseTime': '1234567890',
                'oldestLedger': 82720,
                'oldestLedgerCloseTime': '1234560000',
              }
            }),
            200,
            headers: {'content-type': [dio.Headers.jsonContentType]},
          );
        });

        var server = SorobanServer.withDio(
            'https://soroban-testnet.stellar.org', mockDio);

        final response = await server.getTransaction(txHash);

        expect(response.status, GetTransactionResponse.STATUS_NOT_FOUND);
        expect(response.latestLedger, 100000);
        expect(response.oldestLedger, 82720);
      });

      test('returns FAILED status with error result', () async {
        final txHash =
            'a7d8f6c5e9b1a3d2f4c8e7b9a5c3d1f2e8b6c4d7a9e1f3b5c2d8e6a4b7c9d1e2';

        var mockDio = dio.Dio();
        mockDio.httpClientAdapter = MockDioAdapter((options) {
          var requestBody = jsonDecode(options.data);
          expect(requestBody['method'], 'getTransaction');

          return dio.ResponseBody.fromString(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': requestBody['id'],
              'result': {
                'status': 'FAILED',
                'ledger': 99999,
                'createdAt': '1234567890',
                'applicationOrder': 1,
                'feeBump': false,
                'envelopeXdr':
                    'AAAAAgAAAABzdv3ojkzWHMD7KUoXhrPx0GH18vHKV0ZfqpMiEblG1gAAAGQAAAAAAAAAAgAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAEAAAAAc3b96I5M1hzA+ylKF4az8dBh9fLxyldGX6qTIhG5RtYAAAABAAAAAHN2/eiOTNYcwPspSheGs/HQYfXy8cpXRl+qkyIRuUbWAAAAAAAAAAAF9eEAAAAAAAAAAAIRuUbWAAAAQHnJ0a5x7tKWBH+QV+HMBx5eGgc+3cDVmqLVTlpHtqJKnXWFDlUqL+tKKk+HqXKHqXKHqXKHqXKHqXKHqXKHqXKHqXo=',
                'resultXdr': 'AAAAAAAAAGT/////AAAAAQAAAAAAAAAB////+gAAAAA=',
                'resultMetaXdr': 'AAAAAgAAAAIAAAADAAGGoQAA',
              }
            }),
            200,
            headers: {'content-type': [dio.Headers.jsonContentType]},
          );
        });

        var server = SorobanServer.withDio(
            'https://soroban-testnet.stellar.org', mockDio);

        final response = await server.getTransaction(txHash);

        expect(response.status, GetTransactionResponse.STATUS_FAILED);
        expect(response.ledger, 99999);
        expect(response.resultXdr, isNotNull);
      });
    });

    group('getTransactions', () {
      test('returns transactions with pagination', () async {
        var mockDio = dio.Dio();
        mockDio.httpClientAdapter = MockDioAdapter((options) {
          var requestBody = jsonDecode(options.data);
          expect(requestBody['method'], 'getTransactions');
          expect(requestBody['params']['startLedger'], 90000);

          return dio.ResponseBody.fromString(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': requestBody['id'],
              'result': {
                'transactions': [
                  {
                    'status': 'SUCCESS',
                    'ledger': 90001,
                    'createdAt': '1234567890',
                    'applicationOrder': 1,
                    'feeBump': false,
                    'envelopeXdr':
                        'AAAAAgAAAABzdv3ojkzWHMD7KUoXhrPx0GH18vHKV0ZfqpMiEblG1gAAAGQAAAAAAAAAAgAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAEAAAAAc3b96I5M1hzA+ylKF4az8dBh9fLxyldGX6qTIhG5RtYAAAABAAAAAHN2/eiOTNYcwPspSheGs/HQYfXy8cpXRl+qkyIRuUbWAAAAAAAAAAAF9eEAAAAAAAAAAAIRuUbWAAAAQHnJ0a5x7tKWBH+QV+HMBx5eGgc+3cDVmqLVTlpHtqJKnXWFDlUqL+tKKk+HqXKHqXKHqXKHqXKHqXKHqXKHqXKHqXo=',
                    'resultXdr': 'AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAA=',
                    'resultMetaXdr': 'AAAAAgAAAAIAAAADAAGGoQAA',
                  },
                  {
                    'status': 'SUCCESS',
                    'ledger': 90002,
                    'createdAt': '1234567895',
                    'applicationOrder': 1,
                    'feeBump': false,
                    'envelopeXdr':
                        'AAAAAgAAAABzdv3ojkzWHMD7KUoXhrPx0GH18vHKV0ZfqpMiEblG1gAAAGQAAAAAAAAAAwAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAEAAAAAc3b96I5M1hzA+ylKF4az8dBh9fLxyldGX6qTIhG5RtYAAAABAAAAAHN2/eiOTNYcwPspSheGs/HQYfXy8cpXRl+qkyIRuUbWAAAAAAAAAAAF9eEAAAAAAAAAAAIRuUbWAAAAQHnJ0a5x7tKWBH+QV+HMBx5eGgc+3cDVmqLVTlpHtqJKnXWFDlUqL+tKKk+HqXKHqXKHqXKHqXKHqXKHqXKHqXKHqXo=',
                    'resultXdr': 'AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAA=',
                    'resultMetaXdr': 'AAAAAgAAAAIAAAADAAGGoQAA',
                  }
                ],
                'latestLedger': 100000,
                'latestLedgerCloseTimestamp': 1234567900,
                'oldestLedger': 82720,
                'oldestLedgerCloseTimestamp': 1234560000,
                'cursor': '90002-1',
              }
            }),
            200,
            headers: {'content-type': [dio.Headers.jsonContentType]},
          );
        });

        var server = SorobanServer.withDio(
            'https://soroban-testnet.stellar.org', mockDio);

        final request =
            GetTransactionsRequest(startLedger: 90000);
        final response = await server.getTransactions(request);

        expect(response.transactions, isNotNull);
        expect(response.transactions!.length, 2);
        expect(response.transactions![0].status,
            GetTransactionResponse.STATUS_SUCCESS);
        expect(response.transactions![0].ledger, 90001);
        expect(response.transactions![1].ledger, 90002);
        expect(response.cursor, '90002-1');
        expect(response.latestLedger, 100000);
      });

      test('returns empty transactions list for ledger range with no transactions',
          () async {
        var mockDio = dio.Dio();
        mockDio.httpClientAdapter = MockDioAdapter((options) {
          var requestBody = jsonDecode(options.data);
          expect(requestBody['method'], 'getTransactions');

          return dio.ResponseBody.fromString(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': requestBody['id'],
              'result': {
                'transactions': [],
                'latestLedger': 100000,
                'latestLedgerCloseTimestamp': 1234567900,
                'oldestLedger': 82720,
                'oldestLedgerCloseTimestamp': 1234560000,
              }
            }),
            200,
            headers: {'content-type': [dio.Headers.jsonContentType]},
          );
        });

        var server = SorobanServer.withDio(
            'https://soroban-testnet.stellar.org', mockDio);

        final request =
            GetTransactionsRequest(startLedger: 99000);
        final response = await server.getTransactions(request);

        expect(response.transactions, isNotNull);
        expect(response.transactions!.length, 0);
      });
    });

    group('getEvents', () {
      test('returns events with topic filters', () async {
        var mockDio = dio.Dio();
        mockDio.httpClientAdapter = MockDioAdapter((options) {
          var requestBody = jsonDecode(options.data);
          expect(requestBody['method'], 'getEvents');
          expect(requestBody['params']['startLedger'], 90000);

          final topic1 = XdrSCVal.forSymbol('transfer');
          final topic2 = XdrSCVal.forSymbol('mint');
          final value = XdrSCVal.forU64(BigInt.from(1000));

          return dio.ResponseBody.fromString(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': requestBody['id'],
              'result': {
                'events': [
                  {
                    'type': 'contract',
                    'ledger': 90001,
                    'ledgerClosedAt': '2024-01-15T10:30:00Z',
                    'contractId':
                        'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK',
                    'id': '0000000001-0000000001',
                    'pagingToken': '0000000001-0000000001',
                    'topic': [
                      topic1.toBase64EncodedXdrString(),
                      topic2.toBase64EncodedXdrString(),
                    ],
                    'value': value.toBase64EncodedXdrString(),
                    'inSuccessfulContractCall': true,
                    'txHash': 'a7d8f6c5e9b1a3d2f4c8e7b9a5c3d1f2e8b6c4d7a9e1f3b5c2d8e6a4b7c9d1e2',
                  }
                ],
                'latestLedger': 100000,
              }
            }),
            200,
            headers: {'content-type': [dio.Headers.jsonContentType]},
          );
        });

        var server = SorobanServer.withDio(
            'https://soroban-testnet.stellar.org', mockDio);

        final filters = [
          EventFilter(
            type: 'contract',
            topics: [
              TopicFilter([XdrSCVal.forSymbol('transfer').toBase64EncodedXdrString()]),
            ],
          ),
        ];

        final request =
            GetEventsRequest(startLedger: 90000, filters: filters);
        final response = await server.getEvents(request);

        expect(response.events, isNotNull);
        expect(response.events!.length, 1);
        expect(response.events![0].type, 'contract');
        expect(response.events![0].ledger, 90001);
        expect(response.events![0].contractId,
            'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK');
        expect(response.latestLedger, 100000);
      });

      test('returns events with contract filter', () async {
        final contractId =
            'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK';

        var mockDio = dio.Dio();
        mockDio.httpClientAdapter = MockDioAdapter((options) {
          var requestBody = jsonDecode(options.data);
          expect(requestBody['method'], 'getEvents');
          expect(requestBody['params']['filters'], isNotNull);

          final value = XdrSCVal.forU64(BigInt.from(1000));

          return dio.ResponseBody.fromString(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': requestBody['id'],
              'result': {
                'events': [
                  {
                    'type': 'contract',
                    'ledger': 90001,
                    'ledgerClosedAt': '2024-01-15T10:30:00Z',
                    'contractId': contractId,
                    'id': '0000000001-0000000001',
                    'pagingToken': '0000000001-0000000001',
                    'topic': [],
                    'value': value.toBase64EncodedXdrString(),
                    'inSuccessfulContractCall': true,
                    'txHash': 'a7d8f6c5e9b1a3d2f4c8e7b9a5c3d1f2e8b6c4d7a9e1f3b5c2d8e6a4b7c9d1e2',
                  }
                ],
                'latestLedger': 100000,
              }
            }),
            200,
            headers: {'content-type': [dio.Headers.jsonContentType]},
          );
        });

        var server = SorobanServer.withDio(
            'https://soroban-testnet.stellar.org', mockDio);

        final filters = [
          EventFilter(
            type: 'contract',
            contractIds: [contractId],
          ),
        ];

        final request =
            GetEventsRequest(startLedger: 90000, filters: filters);
        final response = await server.getEvents(request);

        expect(response.events, isNotNull);
        expect(response.events!.length, 1);
        expect(response.events![0].contractId, contractId);
      });

      test('returns empty events list when no matching events', () async {
        var mockDio = dio.Dio();
        mockDio.httpClientAdapter = MockDioAdapter((options) {
          var requestBody = jsonDecode(options.data);
          expect(requestBody['method'], 'getEvents');

          return dio.ResponseBody.fromString(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': requestBody['id'],
              'result': {
                'events': [],
                'latestLedger': 100000,
              }
            }),
            200,
            headers: {'content-type': [dio.Headers.jsonContentType]},
          );
        });

        var server = SorobanServer.withDio(
            'https://soroban-testnet.stellar.org', mockDio);

        final request = GetEventsRequest(startLedger: 90000);
        final response = await server.getEvents(request);

        expect(response.events, isNotNull);
        expect(response.events!.length, 0);
      });
    });

    group('getContractData', () {
      test('returns contract data entry for persistent storage', () async {
        final contractId =
            'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK';
        final key = XdrSCVal.forSymbol('counter');

        var mockDio = dio.Dio();
        mockDio.httpClientAdapter = MockDioAdapter((options) {
          var requestBody = jsonDecode(options.data);
          expect(requestBody['method'], 'getLedgerEntries');
          expect(requestBody['params']['keys'], isList);

          final value = XdrSCVal.forU64(BigInt.from(42));
          final contractAddress = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT);
          contractAddress.contractId = XdrHash(Uint8List.fromList(List.filled(32, 0)));
          final contractData = XdrContractDataEntry(
            XdrExtensionPoint(0),
            contractAddress,
            key,
            XdrContractDataDurability.PERSISTENT,
            value,
          );

          final ledgerEntryData =
              XdrLedgerEntryData(XdrLedgerEntryType.CONTRACT_DATA);
          ledgerEntryData.contractData = contractData;

          return dio.ResponseBody.fromString(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': requestBody['id'],
              'result': {
                'entries': [
                  {
                    'key': (requestBody['params']['keys'] as List)[0],
                    'xdr': ledgerEntryData.toBase64EncodedXdrString(),
                    'lastModifiedLedgerSeq': 99999,
                    'liveUntilLedgerSeq': 150000,
                  }
                ],
                'latestLedger': 100000,
              }
            }),
            200,
            headers: {'content-type': [dio.Headers.jsonContentType]},
          );
        });

        var server = SorobanServer.withDio(
            'https://soroban-testnet.stellar.org', mockDio);

        final contractIdHash = StrKey.decodeContractIdHex(contractId);
        final entry = await server.getContractData(
          contractIdHash,
          key,
          XdrContractDataDurability.PERSISTENT,
        );

        expect(entry, isNotNull);
        expect(entry!.lastModifiedLedgerSeq, 99999);
        expect(entry.liveUntilLedgerSeq, 150000);
        expect(entry.ledgerEntryDataXdr.contractData, isNotNull);
      });

      test('returns null for non-existent contract data', () async {
        final contractId =
            'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK';
        final key = XdrSCVal.forSymbol('nonexistent');

        var mockDio = dio.Dio();
        mockDio.httpClientAdapter = MockDioAdapter((options) {
          var requestBody = jsonDecode(options.data);
          expect(requestBody['method'], 'getLedgerEntries');

          return dio.ResponseBody.fromString(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': requestBody['id'],
              'result': {
                'entries': [],
                'latestLedger': 100000,
              }
            }),
            200,
            headers: {'content-type': [dio.Headers.jsonContentType]},
          );
        });

        var server = SorobanServer.withDio(
            'https://soroban-testnet.stellar.org', mockDio);

        final contractIdHash = StrKey.decodeContractIdHex(contractId);
        final entry = await server.getContractData(
          contractIdHash,
          key,
          XdrContractDataDurability.PERSISTENT,
        );

        expect(entry, isNull);
      });
    });

    group('Error Handling', () {
      test('handles network error', () async {
        var mockDio = dio.Dio();
        mockDio.httpClientAdapter = MockDioAdapter((options) {
          throw dio.DioException(
            requestOptions: options,
            error: 'Network error',
            type: dio.DioExceptionType.connectionError,
          );
        });

        var server = SorobanServer.withDio(
            'https://soroban-testnet.stellar.org', mockDio);

        expect(
          () async => await server.getHealth(),
          throwsA(isA<dio.DioException>()),
        );
      });

      test('handles invalid JSON response', () async {
        var mockDio = dio.Dio();
        mockDio.httpClientAdapter = MockDioAdapter((options) {
          return dio.ResponseBody.fromString(
            'Invalid JSON',
            200,
            headers: {'content-type': [dio.Headers.jsonContentType]},
          );
        });

        var server = SorobanServer.withDio(
            'https://soroban-testnet.stellar.org', mockDio);

        // Invalid JSON causes DioException wrapping FormatException
        expect(
          () async => await server.getHealth(),
          throwsA(isA<dio.DioException>()),
        );
      });

      test('handles JSON-RPC error response', () async {
        var mockDio = dio.Dio();
        mockDio.httpClientAdapter = MockDioAdapter((options) {
          var requestBody = jsonDecode(options.data);

          return dio.ResponseBody.fromString(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': requestBody['id'],
              'error': {
                'code': -32600,
                'message': 'Invalid Request',
                'data': {'additionalInfo': 'Additional error information'},
              }
            }),
            200,
            headers: {'content-type': [dio.Headers.jsonContentType]},
          );
        });

        var server = SorobanServer.withDio(
            'https://soroban-testnet.stellar.org', mockDio);

        final response = await server.getHealth();

        expect(response.error, isNotNull);
        expect(response.error!.code, '-32600');
        expect(response.error!.message, 'Invalid Request');
        expect(response.error!.data, isNotNull);
      });

      test('handles HTTP error status codes', () async {
        var mockDio = dio.Dio();
        mockDio.httpClientAdapter = MockDioAdapter((options) {
          throw dio.DioException(
            requestOptions: options,
            response: dio.Response(
              requestOptions: options,
              statusCode: 500,
              data: {'error': 'Internal Server Error'},
            ),
            type: dio.DioExceptionType.badResponse,
          );
        });

        var server = SorobanServer.withDio(
            'https://soroban-testnet.stellar.org', mockDio);

        expect(
          () async => await server.getHealth(),
          throwsA(isA<dio.DioException>()),
        );
      });

      test('handles timeout error', () async {
        var mockDio = dio.Dio();
        mockDio.httpClientAdapter = MockDioAdapter((options) {
          throw dio.DioException(
            requestOptions: options,
            error: 'Connection timeout',
            type: dio.DioExceptionType.connectionTimeout,
          );
        });

        var server = SorobanServer.withDio(
            'https://soroban-testnet.stellar.org', mockDio);

        expect(
          () async => await server.getHealth(),
          throwsA(isA<dio.DioException>()),
        );
      });
    });

    group('Request Validation', () {
      test('validates correct JSON-RPC request structure', () async {
        var capturedRequest;

        var mockDio = dio.Dio();
        mockDio.httpClientAdapter = MockDioAdapter((options) {
          capturedRequest = jsonDecode(options.data);

          return dio.ResponseBody.fromString(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': capturedRequest['id'],
              'result': {
                'status': 'healthy',
                'ledgerRetentionWindow': 17280,
                'latestLedger': 100000,
                'oldestLedger': 82720,
              }
            }),
            200,
            headers: {'content-type': [dio.Headers.jsonContentType]},
          );
        });

        var server = SorobanServer.withDio(
            'https://soroban-testnet.stellar.org', mockDio);

        await server.getHealth();

        expect(capturedRequest['jsonrpc'], '2.0');
        expect(capturedRequest['method'], 'getHealth');
        expect(capturedRequest['id'], isNotNull);
      });

      test('includes params for methods with arguments', () async {
        final txHash =
            'a7d8f6c5e9b1a3d2f4c8e7b9a5c3d1f2e8b6c4d7a9e1f3b5c2d8e6a4b7c9d1e2';
        var capturedRequest;

        var mockDio = dio.Dio();
        mockDio.httpClientAdapter = MockDioAdapter((options) {
          capturedRequest = jsonDecode(options.data);

          return dio.ResponseBody.fromString(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': capturedRequest['id'],
              'result': {
                'status': 'NOT_FOUND',
                'latestLedger': 100000,
                'latestLedgerCloseTime': '1234567890',
                'oldestLedger': 82720,
                'oldestLedgerCloseTime': '1234560000',
              }
            }),
            200,
            headers: {'content-type': [dio.Headers.jsonContentType]},
          );
        });

        var server = SorobanServer.withDio(
            'https://soroban-testnet.stellar.org', mockDio);

        await server.getTransaction(txHash);

        expect(capturedRequest['params'], isNotNull);
        expect(capturedRequest['params']['hash'], txHash);
      });

      test('sends correct headers', () async {
        dio.Options? capturedOptions;

        var mockDio = dio.Dio();
        mockDio.httpClientAdapter = MockDioAdapter((options) {
          capturedOptions = dio.Options(headers: options.headers);

          return dio.ResponseBody.fromString(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': 1,
              'result': {
                'status': 'healthy',
                'ledgerRetentionWindow': 17280,
                'latestLedger': 100000,
                'oldestLedger': 82720,
              }
            }),
            200,
            headers: {'content-type': [dio.Headers.jsonContentType]},
          );
        });

        var server = SorobanServer.withDio(
            'https://soroban-testnet.stellar.org', mockDio);

        await server.getHealth();

        expect(capturedOptions, isNotNull);
        expect(capturedOptions!.headers!['Content-Type'], 'application/json');
      });
    });
  });
}
