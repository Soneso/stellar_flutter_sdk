// Test response parsing and construction for soroban_server.dart classes
// These tests validate JSON deserialization, object construction, and helper methods
// without making any network calls

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

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
}
