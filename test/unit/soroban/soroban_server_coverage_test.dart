import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart' as dio;
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

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
  group('SorobanServer Coverage Tests', () {
    group('GetTransactionResponse Helper Methods', () {
      test('getResultValue returns null when transaction failed', () {
        final response = GetTransactionResponse({
          'result': {
            'status': 'FAILED',
            'latestLedger': 100000,
            'latestLedgerCloseTime': '1234567890',
            'oldestLedger': 90000,
            'oldestLedgerCloseTime': '1234560000',
          }
        });

        expect(response.getResultValue(), isNull);
      });

      test('getResultValue returns null when error is present', () {
        final response = GetTransactionResponse({
          'error': {
            'code': '-32600',
            'message': 'Invalid Request',
          }
        });

        expect(response.getResultValue(), isNull);
      });

      test('getResultValue returns null when resultMetaXdr is null', () {
        final response = GetTransactionResponse({
          'result': {
            'status': 'NOT_FOUND',
            'latestLedger': 100000,
            'latestLedgerCloseTime': '1234567890',
            'oldestLedger': 90000,
            'oldestLedgerCloseTime': '1234560000',
          }
        });

        expect(response.getResultValue(), isNull);
      });

      test('xdrTransactionEnvelope getter returns null when envelopeXdr is null',
          () {
        final response = GetTransactionResponse({
          'result': {
            'status': 'NOT_FOUND',
            'latestLedger': 100000,
            'latestLedgerCloseTime': '1234567890',
            'oldestLedger': 90000,
            'oldestLedgerCloseTime': '1234560000',
          }
        });

        expect(response.xdrTransactionEnvelope, isNull);
      });

      test('xdrTransactionResult getter returns null when resultXdr is null',
          () {
        final response = GetTransactionResponse({
          'result': {
            'status': 'NOT_FOUND',
            'latestLedger': 100000,
            'latestLedgerCloseTime': '1234567890',
            'oldestLedger': 90000,
            'oldestLedgerCloseTime': '1234560000',
          }
        });

        expect(response.xdrTransactionResult, isNull);
      });

      test('xdrTransactionMeta getter returns null when resultMetaXdr is null',
          () {
        final response = GetTransactionResponse({
          'result': {
            'status': 'NOT_FOUND',
            'latestLedger': 100000,
            'latestLedgerCloseTime': '1234567890',
            'oldestLedger': 90000,
            'oldestLedgerCloseTime': '1234560000',
          }
        });

        expect(response.xdrTransactionMeta, isNull);
      });

      test('convertToInt handles null input', () {
        expect(GetTransactionResponse.convertToInt(null), isNull);
      });

      test('convertToInt handles integer input', () {
        expect(GetTransactionResponse.convertToInt(42), equals(42));
      });

      test('convertToInt handles string input', () {
        expect(GetTransactionResponse.convertToInt('123'), equals(123));
      });

      test('convertToInt throws exception for invalid input', () {
        expect(() => GetTransactionResponse.convertToInt(3.14),
            throwsA(isA<Exception>()));
      });

      test('getWasmId returns null when no result value', () {
        final response = GetTransactionResponse({
          'result': {
            'status': 'FAILED',
            'latestLedger': 100000,
            'latestLedgerCloseTime': '1234567890',
            'oldestLedger': 90000,
            'oldestLedgerCloseTime': '1234560000',
          }
        });

        expect(response.getWasmId(), isNull);
      });

      test('getCreatedContractId returns null when no result value', () {
        final response = GetTransactionResponse({
          'result': {
            'status': 'FAILED',
            'latestLedger': 100000,
            'latestLedgerCloseTime': '1234567890',
            'oldestLedger': 90000,
            'oldestLedgerCloseTime': '1234560000',
          }
        });

        expect(response.getCreatedContractId(), isNull);
      });
    });

    group('SimulateTransactionResponse Helper Methods', () {
      test('getFootprint returns null when transactionData is null', () {
        final response = SimulateTransactionResponse({
          'result': {
            'latestLedger': 100000,
          }
        });

        expect(response.getFootprint(), isNull);
      });

      test('footprint getter is alias for getFootprint', () {
        final response = SimulateTransactionResponse({
          'result': {
            'latestLedger': 100000,
          }
        });

        expect(response.footprint, equals(response.getFootprint()));
        expect(response.footprint, isNull);
      });

      test('getSorobanAuth returns null when results is null', () {
        final response = SimulateTransactionResponse({
          'result': {
            'latestLedger': 100000,
          }
        });

        expect(response.getSorobanAuth(), isNull);
      });

      test('getSorobanAuth returns null when results is empty', () {
        final response = SimulateTransactionResponse({
          'result': {
            'results': [],
            'latestLedger': 100000,
          }
        });

        expect(response.getSorobanAuth(), isNull);
      });

      test('sorobanAuth getter is alias for getSorobanAuth', () {
        final response = SimulateTransactionResponse({
          'result': {
            'latestLedger': 100000,
          }
        });

        expect(response.sorobanAuth, equals(response.getSorobanAuth()));
        expect(response.sorobanAuth, isNull);
      });
    });

    group('LedgerEntryChange', () {
      test('fromJson parses created entry without before', () {
        final ledgerKey = XdrLedgerKey(XdrLedgerEntryType.ACCOUNT);
        ledgerKey.account = XdrLedgerKeyAccount(
            XdrAccountID(KeyPair.random().xdrPublicKey));

        final afterEntry = XdrLedgerEntry(
          XdrUint32(100),
          XdrLedgerEntryData(XdrLedgerEntryType.ACCOUNT),
          XdrLedgerEntryExt(0),
        );
        afterEntry.data.account = XdrAccountEntry(
          XdrAccountID(KeyPair.random().xdrPublicKey),
          XdrInt64(BigInt.from(1000000)),
          XdrSequenceNumber(BigInt.from(100)),
          XdrUint32(0),
          null,
          XdrUint32(0),
          XdrString32(''),
          XdrThresholds(Uint8List.fromList([1, 0, 0, 0])),
          [],
          XdrAccountEntryExt(0),
        );

        final json = {
          'type': 'created',
          'key': ledgerKey.toBase64EncodedXdrString(),
          'after': afterEntry.toBase64EncodedXdrString(),
        };

        final change = LedgerEntryChange.fromJson(json);

        expect(change.type, 'created');
        expect(change.before, isNull);
        expect(change.after, isNotNull);
      });

      test('fromJson parses deleted entry without after', () {
        final ledgerKey = XdrLedgerKey(XdrLedgerEntryType.ACCOUNT);
        ledgerKey.account = XdrLedgerKeyAccount(
            XdrAccountID(KeyPair.random().xdrPublicKey));

        final beforeEntry = XdrLedgerEntry(
          XdrUint32(99),
          XdrLedgerEntryData(XdrLedgerEntryType.ACCOUNT),
          XdrLedgerEntryExt(0),
        );
        beforeEntry.data.account = XdrAccountEntry(
          XdrAccountID(KeyPair.random().xdrPublicKey),
          XdrInt64(BigInt.from(1000000)),
          XdrSequenceNumber(BigInt.from(100)),
          XdrUint32(0),
          null,
          XdrUint32(0),
          XdrString32(''),
          XdrThresholds(Uint8List.fromList([1, 0, 0, 0])),
          [],
          XdrAccountEntryExt(0),
        );

        final json = {
          'type': 'deleted',
          'key': ledgerKey.toBase64EncodedXdrString(),
          'before': beforeEntry.toBase64EncodedXdrString(),
        };

        final change = LedgerEntryChange.fromJson(json);

        expect(change.type, 'deleted');
        expect(change.before, isNotNull);
        expect(change.after, isNull);
      });
    });

    group('TransactionEvents', () {
      test('fromJson parses all event types', () {
        final json = {
          'diagnosticEventsXdr': ['event1xdr', 'event2xdr'],
          'transactionEventsXdr': ['txevent1xdr', 'txevent2xdr'],
          'contractEventsXdr': [
            ['contract1event1', 'contract1event2'],
            ['contract2event1']
          ],
        };

        final events = TransactionEvents.fromJson(json);

        expect(events.diagnosticEventsXdr, isNotNull);
        expect(events.diagnosticEventsXdr!.length, 2);
        expect(events.transactionEventsXdr, isNotNull);
        expect(events.transactionEventsXdr!.length, 2);
        expect(events.contractEventsXdr, isNotNull);
        expect(events.contractEventsXdr!.length, 2);
        expect(events.contractEventsXdr![0].length, 2);
        expect(events.contractEventsXdr![1].length, 1);
      });

      test('fromJson handles missing event types', () {
        final json = {
          'diagnosticEventsXdr': ['event1xdr'],
        };

        final events = TransactionEvents.fromJson(json);

        expect(events.diagnosticEventsXdr, isNotNull);
        expect(events.transactionEventsXdr, isNull);
        expect(events.contractEventsXdr, isNull);
      });

      test('fromJson handles empty contractEventsXdr arrays', () {
        final json = {
          'contractEventsXdr': [],
        };

        final events = TransactionEvents.fromJson(json);

        expect(events.contractEventsXdr, isNotNull);
        expect(events.contractEventsXdr!.length, 0);
      });

      test('fromJson handles mixed contractEventsXdr with non-array entries',
          () {
        final json = {
          'contractEventsXdr': [
            ['event1', 'event2'],
            'invalid', // Non-array entry should be ignored
            ['event3']
          ],
        };

        final events = TransactionEvents.fromJson(json);

        expect(events.contractEventsXdr, isNotNull);
        expect(events.contractEventsXdr!.length,
            2); // Only 2 valid arrays should be parsed
      });
    });

    group('PaginationOptions', () {
      test('getRequestArgs includes cursor and limit', () {
        final options = PaginationOptions(cursor: 'cursor123', limit: 50);
        final args = options.getRequestArgs();

        expect(args['cursor'], 'cursor123');
        expect(args['limit'], 50);
      });

      test('getRequestArgs excludes null values', () {
        final options = PaginationOptions();
        final args = options.getRequestArgs();

        expect(args.containsKey('cursor'), false);
        expect(args.containsKey('limit'), false);
      });

      test('getRequestArgs includes only cursor when limit is null', () {
        final options = PaginationOptions(cursor: 'cursor456');
        final args = options.getRequestArgs();

        expect(args['cursor'], 'cursor456');
        expect(args.containsKey('limit'), false);
      });

      test('getRequestArgs includes only limit when cursor is null', () {
        final options = PaginationOptions(limit: 100);
        final args = options.getRequestArgs();

        expect(args['limit'], 100);
        expect(args.containsKey('cursor'), false);
      });
    });

    group('GetTransactionsRequest', () {
      test('getRequestArgs includes pagination options', () {
        final paginationOptions =
            PaginationOptions(cursor: 'cursor123', limit: 50);
        final request = GetTransactionsRequest(
            startLedger: 1000, paginationOptions: paginationOptions);
        final args = request.getRequestArgs();

        expect(args['startLedger'], 1000);
        expect(args['pagination'], isNotNull);
        expect(args['pagination']['cursor'], 'cursor123');
        expect(args['pagination']['limit'], 50);
      });

      test('getRequestArgs excludes null fields', () {
        final request = GetTransactionsRequest();
        final args = request.getRequestArgs();

        expect(args.containsKey('startLedger'), false);
        expect(args.containsKey('pagination'), false);
      });
    });

    group('GetEventsRequest', () {
      test('getRequestArgs includes endLedger and pagination', () {
        final paginationOptions = PaginationOptions(limit: 100);
        final request = GetEventsRequest(
          startLedger: 1000,
          endLedger: 2000,
          paginationOptions: paginationOptions,
        );
        final args = request.getRequestArgs();

        expect(args['startLedger'], 1000);
        expect(args['endLedger'], 2000);
        expect(args['pagination'], isNotNull);
        expect(args['pagination']['limit'], 100);
      });

      test('getRequestArgs excludes null fields', () {
        final request = GetEventsRequest();
        final args = request.getRequestArgs();

        expect(args.containsKey('startLedger'), false);
        expect(args.containsKey('endLedger'), false);
        expect(args.containsKey('filters'), false);
        expect(args.containsKey('pagination'), false);
      });

      test('getRequestArgs includes filters', () {
        final filter1 = EventFilter(type: 'contract');
        final filter2 = EventFilter(
            type: 'system', contractIds: ['contract1', 'contract2']);

        final request = GetEventsRequest(
          startLedger: 1000,
          filters: [filter1, filter2],
        );
        final args = request.getRequestArgs();

        expect(args['filters'], isNotNull);
        expect(args['filters'].length, 2);
      });
    });

    group('EventFilter', () {
      test('getRequestArgs includes type and contractIds', () {
        final filter = EventFilter(
          type: 'contract',
          contractIds: ['contract1', 'contract2'],
        );
        final args = filter.getRequestArgs();

        expect(args['type'], 'contract');
        expect(args['contractIds'], ['contract1', 'contract2']);
      });

      test('getRequestArgs includes topics filter', () {
        final topic1 = XdrSCVal.forSymbol('transfer');
        final topic2 = XdrSCVal.forSymbol('mint');

        final topicFilter = TopicFilter([
          topic1.toBase64EncodedXdrString(),
          topic2.toBase64EncodedXdrString(),
        ]);

        final filter = EventFilter(
          type: 'contract',
          topics: [topicFilter],
        );
        final args = filter.getRequestArgs();

        expect(args['topics'], isNotNull);
        expect(args['topics'].length, 1);
        expect(args['topics'][0].length, 2);
      });

      test('getRequestArgs excludes null fields', () {
        final filter = EventFilter();
        final args = filter.getRequestArgs();

        expect(args.containsKey('type'), false);
        expect(args.containsKey('contractIds'), false);
        expect(args.containsKey('topics'), false);
      });
    });

    group('SimulateTransactionRequest', () {
      test('getRequestArgs includes resourceConfig when provided', () async {
        final sourceAccount = Account(
            'GDAT5HWTGIU4TSSZ4752OUC4SABDLTLZFRPZUJ3D6LKBNEPA7V2CIG54',
            BigInt.from(100));
        final tx = TransactionBuilder(sourceAccount)
            .addOperation(BumpSequenceOperation(BigInt.from(110)))
            .build();

        final resourceConfig = ResourceConfig(12345);
        final request =
            SimulateTransactionRequest(tx, resourceConfig: resourceConfig);
        final args = request.getRequestArgs();

        expect(args['resourceConfig'], isNotNull);
        expect(args['resourceConfig']['instructionLeeway'], 12345);
      });

      test('getRequestArgs excludes resourceConfig when not provided', () {
        final sourceAccount = Account(
            'GDAT5HWTGIU4TSSZ4752OUC4SABDLTLZFRPZUJ3D6LKBNEPA7V2CIG54',
            BigInt.from(100));
        final tx = TransactionBuilder(sourceAccount)
            .addOperation(BumpSequenceOperation(BigInt.from(110)))
            .build();

        final request = SimulateTransactionRequest(tx);
        final args = request.getRequestArgs();

        expect(args.containsKey('resourceConfig'), false);
      });
    });

    group('ResourceConfig', () {
      test('getRequestArgs includes instructionLeeway', () {
        final config = ResourceConfig(10000);
        final args = config.getRequestArgs();

        expect(args['instructionLeeway'], 10000);
      });
    });

    group('GetLedgersRequest', () {
      test('getRequestArgs includes cursor in pagination', () {
        final paginationOptions = PaginationOptions(cursor: 'ledger100');
        final request =
            GetLedgersRequest(startLedger: 50, paginationOptions: paginationOptions);
        final args = request.getRequestArgs();

        expect(args['startLedger'], 50);
        expect(args['pagination']['cursor'], 'ledger100');
      });

      test('getRequestArgs excludes null fields', () {
        final request = GetLedgersRequest();
        final args = request.getRequestArgs();

        expect(args.containsKey('startLedger'), false);
        expect(args.containsKey('pagination'), false);
      });
    });

    group('SimulateTransactionResponse Events', () {
      test('parses events from JSON response', () {
        final json = {
          'result': {
            'events': ['event1xdr', 'event2xdr'],
            'latestLedger': 100000,
          }
        };

        final response = SimulateTransactionResponse.fromJson(json);

        expect(response.events, isNotNull);
        expect(response.events!.length, 2);
        expect(response.events![0], 'event1xdr');
        expect(response.events![1], 'event2xdr');
      });

      test('decodes diagnostic events from JSON response', () {
        final topic = XdrSCVal(XdrSCValType.SCV_SYMBOL);
        topic.sym = 'transfer';
        final data = XdrSCVal(XdrSCValType.SCV_U32);
        data.u32 = XdrUint32(777);

        final body = XdrContractEventBody(0);
        body.v0 = XdrContractEventV0([topic], data);
        final contractEvent = XdrContractEvent(XdrExtensionPoint(0), null,
            XdrContractEventType.DIAGNOSTIC, body);
        final diagnosticEvent = XdrDiagnosticEvent(true, contractEvent);

        final json = {
          'result': {
            'events': [diagnosticEvent.toBase64EncodedXdrString()],
            'latestLedger': 100000,
          }
        };

        final response = SimulateTransactionResponse.fromJson(json);

        expect(response.diagnosticEvents, isNotNull);
        expect(response.diagnosticEvents!.length, 1);
        final decoded = response.diagnosticEvents![0];
        expect(decoded.inSuccessfulContractCall, isTrue);
        expect(decoded.event.type.value,
            equals(XdrContractEventType.DIAGNOSTIC.value));
        expect(decoded.event.body.v0!.topics.length, 1);
        expect(decoded.event.body.v0!.topics[0].sym, equals('transfer'));
        expect(decoded.event.body.v0!.data.u32!.uint32, equals(777));
      });

      test('diagnostic events are null when no events present', () {
        final json = {
          'result': {
            'latestLedger': 100000,
          }
        };

        final response = SimulateTransactionResponse.fromJson(json);

        expect(response.events, isNull);
        expect(response.diagnosticEvents, isNull);
      });

      test('diagnostic events are null when events list is empty', () {
        final json = {
          'result': {
            'events': [],
            'latestLedger': 100000,
          }
        };

        final response = SimulateTransactionResponse.fromJson(json);

        expect(response.events, isNotNull);
        expect(response.events!.length, 0);
        expect(response.diagnosticEvents, isNull);
      });

      test('handles missing events field', () {
        final json = {
          'result': {
            'latestLedger': 100000,
          }
        };

        final response = SimulateTransactionResponse.fromJson(json);

        expect(response.events, isNull);
      });
    });
  });

  group('SorobanServer httpClient injection', () {
    dio.Dio buildMockDio(void Function() onRequest) {
      final mockDio = dio.Dio();
      mockDio.httpClientAdapter = MockDioAdapter((options) {
        onRequest();
        return dio.ResponseBody.fromString(
          json.encode({
            'jsonrpc': '2.0',
            'result': {'status': 'healthy'},
            'id': 1,
          }),
          200,
          headers: {
            dio.Headers.contentTypeHeader: ['application/json'],
          },
        );
      });
      return mockDio;
    }

    test('requests go through the injected Dio instance', () async {
      var requestCount = 0;
      final server = SorobanServer('https://rpc.example.org',
          httpClient: buildMockDio(() => requestCount++));

      final health = await server.getHealth();

      expect(requestCount, 1);
      expect(health.status, GetHealthResponse.HEALTHY);
    });

    test('httpOverrides keeps the injected Dio instance', () async {
      var requestCount = 0;
      final server = SorobanServer('https://rpc.example.org',
          httpClient: buildMockDio(() => requestCount++));

      server.httpOverrides = true;

      final health = await server.getHealth();

      expect(requestCount, 1);
      expect(health.status, GetHealthResponse.HEALTHY);
    });
  });

  group('Soroban response parsing coverage', () {
    String buildV3MetaBase64(XdrSCVal returnValue) {
      final sorobanMeta = XdrSorobanTransactionMeta(
        XdrSorobanTransactionMetaExt(0),
        [],
        returnValue,
        [],
      );
      final v3 = XdrTransactionMetaV3(
        XdrExtensionPoint(0),
        XdrLedgerEntryChanges([]),
        [],
        XdrLedgerEntryChanges([]),
        sorobanMeta,
      );
      final meta = XdrTransactionMeta(3);
      meta.v3 = v3;
      return meta.toBase64EncodedXdrString();
    }

    String buildV4MetaBase64(XdrSCVal returnValue) {
      final sorobanMeta = XdrSorobanTransactionMetaV2(
        XdrSorobanTransactionMetaExt(0),
        returnValue,
      );
      final v4 = XdrTransactionMetaV4(
        XdrExtensionPoint(0),
        XdrLedgerEntryChanges([]),
        [],
        XdrLedgerEntryChanges([]),
        sorobanMeta,
        [],
        [],
      );
      final meta = XdrTransactionMeta(4);
      meta.v4 = v4;
      return meta.toBase64EncodedXdrString();
    }

    String buildTxResultBase64() {
      final resultResult =
          XdrTransactionResultResult(XdrTransactionResultCode.txSUCCESS);
      resultResult.results = [];
      final txResult = XdrTransactionResult(
        XdrInt64(BigInt.from(100)),
        resultResult,
        XdrTransactionResultExt(0),
      );
      return txResult.toBase64EncodedXdrString();
    }

    String buildEnvelopeBase64() {
      final sourceAccount = Account(
          'GDAT5HWTGIU4TSSZ4752OUC4SABDLTLZFRPZUJ3D6LKBNEPA7V2CIG54',
          BigInt.from(100));
      final tx = TransactionBuilder(sourceAccount)
          .addOperation(BumpSequenceOperation(BigInt.from(110)))
          .build();
      return tx.toEnvelopeXdrBase64();
    }

    XdrAccountEntry buildAccountEntry() {
      return XdrAccountEntry(
        XdrAccountID(KeyPair.random().xdrPublicKey),
        XdrInt64(BigInt.from(1000000)),
        XdrSequenceNumber(BigInt.from(100)),
        XdrUint32(0),
        null,
        XdrUint32(0),
        XdrString32(''),
        XdrThresholds(Uint8List.fromList([1, 0, 0, 0])),
        [],
        XdrAccountEntryExt(0),
      );
    }

    group('RPC error branches', () {
      final errorJson = {
        'jsonrpc': '2.0',
        'id': 1,
        'error': {'code': -32600, 'message': 'Invalid Request'},
      };

      test('SimulateTransactionResponse maps error', () {
        final response = SimulateTransactionResponse.fromJson(errorJson);
        expect(response.error, isNotNull);
        expect(response.error!.code, '-32600');
        expect(response.error!.message, 'Invalid Request');
        expect(response.isErrorResponse, isTrue);
      });

      test('SendTransactionResponse maps error', () {
        final response = SendTransactionResponse.fromJson(errorJson);
        expect(response.error, isNotNull);
        expect(response.error!.code, '-32600');
        expect(response.error!.message, 'Invalid Request');
      });

      test('GetTransactionResponse maps error', () {
        final response = GetTransactionResponse.fromJson(errorJson);
        expect(response.error, isNotNull);
        expect(response.error!.code, '-32600');
        expect(response.error!.message, 'Invalid Request');
      });

      test('GetTransactionsResponse maps error', () {
        final response = GetTransactionsResponse.fromJson(errorJson);
        expect(response.error, isNotNull);
        expect(response.error!.code, '-32600');
        expect(response.transactions, isNull);
      });

      test('GetFeeStatsResponse maps error', () {
        final response = GetFeeStatsResponse.fromJson(errorJson);
        expect(response.error, isNotNull);
        expect(response.error!.code, '-32600');
        expect(response.error!.message, 'Invalid Request');
      });

      test('GetLatestLedgerResponse maps error', () {
        final response = GetLatestLedgerResponse.fromJson(errorJson);
        expect(response.error, isNotNull);
        expect(response.error!.code, '-32600');
        expect(response.error!.message, 'Invalid Request');
      });

      test('GetNetworkResponse maps error', () {
        final response = GetNetworkResponse.fromJson(errorJson);
        expect(response.error, isNotNull);
        expect(response.error!.code, '-32600');
        expect(response.error!.message, 'Invalid Request');
      });

      test('GetLedgersResponse maps error', () {
        final response = GetLedgersResponse.fromJson(errorJson);
        expect(response.error, isNotNull);
        expect(response.error!.code, '-32600');
        expect(response.ledgers, isNull);
      });

      test('GetEventsResponse maps error', () {
        final response = GetEventsResponse.fromJson(errorJson);
        expect(response.error, isNotNull);
        expect(response.error!.code, '-32600');
        expect(response.events, isNull);
      });
    });

    group('SimulateTransactionResponse decoding', () {
      test('parses stateChanges into LedgerEntryChange list', () {
        final ledgerKey = XdrLedgerKey(XdrLedgerEntryType.ACCOUNT);
        ledgerKey.account =
            XdrLedgerKeyAccount(XdrAccountID(KeyPair.random().xdrPublicKey));
        final afterEntry = XdrLedgerEntry(
          XdrUint32(100),
          XdrLedgerEntryData(XdrLedgerEntryType.ACCOUNT),
          XdrLedgerEntryExt(0),
        );
        afterEntry.data.account = buildAccountEntry();

        final response = SimulateTransactionResponse.fromJson({
          'result': {
            'stateChanges': [
              {
                'type': 'created',
                'key': ledgerKey.toBase64EncodedXdrString(),
                'after': afterEntry.toBase64EncodedXdrString(),
              }
            ],
            'latestLedger': 100000,
          }
        });

        expect(response.stateChanges, isNotNull);
        expect(response.stateChanges!.length, 1);
        expect(response.stateChanges![0].type, 'created');
        expect(response.stateChanges![0].after, isNotNull);
        expect(response.stateChanges![0].before, isNull);
      });

      test('getFootprint returns footprint from transactionData', () {
        final codeKey = XdrLedgerKey.forContractCode(
            Uint8List.fromList(List<int>.filled(32, 7)));
        final txData = XdrSorobanTransactionData(
          XdrSorobanTransactionDataExt(0),
          XdrSorobanResources(
            XdrLedgerFootprint([codeKey], []),
            XdrUint32(0),
            XdrUint32(0),
            XdrUint32(0),
          ),
          XdrInt64(BigInt.zero),
        );

        final response = SimulateTransactionResponse.fromJson({
          'result': {
            'transactionData': txData.toBase64EncodedXdrString(),
            'latestLedger': 100000,
          }
        });

        expect(response.transactionData, isNotNull);
        final footprint = response.getFootprint();
        expect(footprint, isNotNull);
        expect(footprint!.getContractCodeXdrLedgerKey(), isNotNull);
        expect(response.footprint, isNotNull);
      });
    });

    group('SendTransactionResponse decoding', () {
      test('decodes diagnosticEventsXdr entries', () {
        final topic = XdrSCVal(XdrSCValType.SCV_SYMBOL);
        topic.sym = 'transfer';
        final data = XdrSCVal(XdrSCValType.SCV_U32);
        data.u32 = XdrUint32(999);
        final body = XdrContractEventBody(0);
        body.v0 = XdrContractEventV0([topic], data);
        final contractEvent = XdrContractEvent(XdrExtensionPoint(0), null,
            XdrContractEventType.DIAGNOSTIC, body);
        final diagnosticEvent = XdrDiagnosticEvent(true, contractEvent);

        final response = SendTransactionResponse.fromJson({
          'result': {
            'hash': 'abc123',
            'status': SendTransactionResponse.STATUS_ERROR,
            'latestLedger': 100,
            'latestLedgerCloseTime': '123456',
            'errorResultXdr': 'AAAA',
            'diagnosticEventsXdr': [
              diagnosticEvent.toBase64EncodedXdrString()
            ],
          }
        });

        expect(response.hash, 'abc123');
        expect(response.status, SendTransactionResponse.STATUS_ERROR);
        expect(response.diagnosticEvents, isNotNull);
        expect(response.diagnosticEvents!.length, 1);
        final decoded = response.diagnosticEvents![0];
        expect(decoded.inSuccessfulContractCall, isTrue);
        expect(decoded.event.body.v0!.topics[0].sym, 'transfer');
        expect(decoded.event.body.v0!.data.u32!.uint32, 999);
      });
    });

    group('GetTransactionResponse decoding', () {
      test('parses events into TransactionEvents', () {
        final response = GetTransactionResponse.fromJson({
          'result': {
            'status': GetTransactionResponse.STATUS_SUCCESS,
            'latestLedger': 100,
            'events': {
              'diagnosticEventsXdr': ['diag1'],
              'transactionEventsXdr': ['tx1'],
            },
          }
        });

        expect(response.events, isNotNull);
        expect(response.events!.diagnosticEventsXdr, ['diag1']);
        expect(response.events!.transactionEventsXdr, ['tx1']);
      });

      test('xdr getters decode envelope, result and meta', () {
        final response = GetTransactionResponse.fromJson({
          'result': {
            'status': GetTransactionResponse.STATUS_SUCCESS,
            'latestLedger': 100,
            'envelopeXdr': buildEnvelopeBase64(),
            'resultXdr': buildTxResultBase64(),
            'resultMetaXdr': buildV3MetaBase64(XdrSCVal.forU32(42)),
          }
        });

        expect(response.xdrTransactionEnvelope, isNotNull);
        expect(response.xdrTransactionResult, isNotNull);
        expect(
            response.xdrTransactionResult!.feeCharged.int64, BigInt.from(100));
        expect(response.xdrTransactionMeta, isNotNull);
        expect(response.xdrTransactionMeta!.v3, isNotNull);
      });

      test('getWasmId returns hex of SCV_BYTES return value', () {
        final wasmBytes = Uint8List.fromList([1, 2, 3, 4]);
        final response = GetTransactionResponse.fromJson({
          'result': {
            'status': GetTransactionResponse.STATUS_SUCCESS,
            'latestLedger': 100,
            'resultMetaXdr': buildV3MetaBase64(XdrSCVal.forBytes(wasmBytes)),
          }
        });

        expect(response.getWasmId(), Util.bytesToHex(wasmBytes));
      });

      test('getCreatedContractId returns hex of SCV_ADDRESS contract', () {
        final contractIdHex = 'e2c1c8f3b2a49d5e6f708192a3b4c5d6'
            'e7f8091a2b3c4d5e6f708192a3b4c5d6';
        final address = XdrSCAddress.forContractId(contractIdHex);
        final response = GetTransactionResponse.fromJson({
          'result': {
            'status': GetTransactionResponse.STATUS_SUCCESS,
            'latestLedger': 100,
            'resultMetaXdr': buildV3MetaBase64(XdrSCVal.forAddress(address)),
          }
        });

        expect(response.getCreatedContractId(), contractIdHex);
      });

      test('getResultValue reads v4 sorobanMeta return value', () {
        final response = GetTransactionResponse.fromJson({
          'result': {
            'status': GetTransactionResponse.STATUS_SUCCESS,
            'latestLedger': 100,
            'resultMetaXdr': buildV4MetaBase64(XdrSCVal.forU32(55)),
          }
        });

        final value = response.getResultValue();
        expect(value, isNotNull);
        expect(value!.u32!.uint32, 55);
      });
    });

    group('TransactionInfo decoding', () {
      test('parses full transaction info fixture', () {
        final info = TransactionInfo.fromJson({
          'status': TransactionInfo.STATUS_SUCCESS,
          'applicationOrder': 3,
          'feeBump': false,
          'envelopeXdr': buildEnvelopeBase64(),
          'resultXdr': buildTxResultBase64(),
          'resultMetaXdr': buildV3MetaBase64(XdrSCVal.forU32(42)),
          'ledger': 5000,
          'createdAt': 1700000000,
          'txHash': 'abcd1234',
          'diagnosticEventsXdr': ['diag1', 'diag2'],
          'events': {
            'contractEventsXdr': [
              ['ev1']
            ],
          },
        });

        expect(info.status, TransactionInfo.STATUS_SUCCESS);
        expect(info.applicationOrder, 3);
        expect(info.feeBump, isFalse);
        expect(info.ledger, 5000);
        expect(info.createdAt, 1700000000);
        expect(info.txHash, 'abcd1234');
        expect(info.diagnosticEventsXdr, ['diag1', 'diag2']);
        expect(info.events, isNotNull);
        expect(info.events!.contractEventsXdr!.length, 1);
        expect(info.xdrTransactionEnvelope, isNotNull);
        expect(info.xdrTransactionResult.feeCharged.int64, BigInt.from(100));
        expect(info.xdrTransactionMeta.v3, isNotNull);
      });

      test('parses createdAt provided as string', () {
        final info = TransactionInfo.fromJson({
          'status': TransactionInfo.STATUS_SUCCESS,
          'applicationOrder': 1,
          'feeBump': false,
          'envelopeXdr': 'env',
          'resultXdr': 'res',
          'resultMetaXdr': 'meta',
          'ledger': 10,
          'createdAt': '1700000123',
          'txHash': 'hash',
        });

        expect(info.createdAt, 1700000123);
        expect(info.diagnosticEventsXdr, isNull);
        expect(info.events, isNull);
      });

      test('getResultValue returns null when status is not SUCCESS', () {
        final info = TransactionInfo.fromJson({
          'status': TransactionInfo.STATUS_FAILED,
          'applicationOrder': 1,
          'feeBump': false,
          'envelopeXdr': 'env',
          'resultXdr': 'res',
          'resultMetaXdr': 'meta',
          'ledger': 10,
          'createdAt': 1700000000,
          'txHash': 'hash',
        });

        expect(info.getResultValue(), isNull);
      });

      test('getResultValue reads v3 sorobanMeta return value', () {
        final info = TransactionInfo.fromJson({
          'status': TransactionInfo.STATUS_SUCCESS,
          'applicationOrder': 1,
          'feeBump': false,
          'envelopeXdr': buildEnvelopeBase64(),
          'resultXdr': buildTxResultBase64(),
          'resultMetaXdr': buildV3MetaBase64(XdrSCVal.forU32(88)),
          'ledger': 10,
          'createdAt': 1700000000,
          'txHash': 'hash',
        });

        final value = info.getResultValue();
        expect(value, isNotNull);
        expect(value!.u32!.uint32, 88);
      });
    });

    group('Footprint utilities', () {
      Footprint buildFootprint() {
        final codeKey = XdrLedgerKey.forContractCode(
            Uint8List.fromList(List<int>.filled(32, 9)));
        final dataKey = XdrLedgerKey.forContractData(
          XdrSCAddress.forContractId('00000000000000000000000000000000'
              '00000000000000000000000000000001'),
          XdrSCVal.forSymbol('balance'),
          XdrContractDataDurability.PERSISTENT,
        );
        return Footprint(XdrLedgerFootprint([codeKey], [dataKey]));
      }

      test('roundtrips through base64 XDR', () {
        final footprint = buildFootprint();
        final encoded = footprint.toBase64EncodedXdrString();
        final decoded = Footprint.fromBase64EncodedXdrString(encoded);

        expect(decoded.xdrFootprint.readOnly.length, 1);
        expect(decoded.xdrFootprint.readWrite.length, 1);
        expect(decoded.xdrFootprint.readOnly[0].discriminant,
            XdrLedgerEntryType.CONTRACT_CODE);
        expect(decoded.xdrFootprint.readWrite[0].discriminant,
            XdrLedgerEntryType.CONTRACT_DATA);
      });

      test('returns contract code ledger key from readOnly', () {
        final footprint = buildFootprint();
        final key = footprint.getContractCodeXdrLedgerKey();
        expect(key, isNotNull);
        expect(key!.discriminant, XdrLedgerEntryType.CONTRACT_CODE);
        expect(footprint.getContractCodeLedgerKey(),
            key.toBase64EncodedXdrString());
      });

      test('returns contract data ledger key from readWrite', () {
        final footprint = buildFootprint();
        final key = footprint.getContractDataXdrLedgerKey();
        expect(key, isNotNull);
        expect(key!.discriminant, XdrLedgerEntryType.CONTRACT_DATA);
        expect(footprint.getContractDataLedgerKey(),
            key.toBase64EncodedXdrString());
      });

      test('returns null when key type is not in footprint', () {
        final footprint = Footprint(XdrLedgerFootprint([], []));
        expect(footprint.getContractCodeXdrLedgerKey(), isNull);
        expect(footprint.getContractCodeLedgerKey(), isNull);
        expect(footprint.getContractDataXdrLedgerKey(), isNull);
        expect(footprint.getContractDataLedgerKey(), isNull);
      });
    });

    group('LedgerEntry getters', () {
      test('decodes ledgerEntryData and keyValue', () {
        final keySc = XdrSCVal.forSymbol('counter');
        final entryData = XdrLedgerEntryData(XdrLedgerEntryType.ACCOUNT);
        entryData.account = buildAccountEntry();

        final entry = LedgerEntry(
          keySc.toBase64EncodedXdrString(),
          entryData.toBase64EncodedXdrString(),
          99999,
          null,
          null,
        );

        expect(
            entry.ledgerEntryData.discriminant, XdrLedgerEntryType.ACCOUNT);
        expect(entry.keyValue.sym, 'counter');
      });
    });

    group('EventInfo decoding', () {
      test('reads value from nested xdr map and decodes valueXdr', () {
        final scVal = XdrSCVal.forU32(7);
        final info = EventInfo.fromJson({
          'type': 'contract',
          'ledger': 1234,
          'ledgerClosedAt': '2024-01-01T00:00:00Z',
          'contractId':
              'CBQHNAXSI55GX2GN6D67GK7BHVPSLJUGZQEU7WJ5LKR5PNUCGLIMAO4K',
          'id': '0000000000001234-0000000001',
          'topic': [
            XdrSCVal.forSymbol('transfer').toBase64EncodedXdrString()
          ],
          'value': {'xdr': scVal.toBase64EncodedXdrString()},
          'inSuccessfulContractCall': true,
          'txHash': 'deadbeef',
        });

        expect(info.value, scVal.toBase64EncodedXdrString());
        expect(info.valueXdr.u32!.uint32, 7);
        expect(info.topic.length, 1);
      });
    });
  });
}
