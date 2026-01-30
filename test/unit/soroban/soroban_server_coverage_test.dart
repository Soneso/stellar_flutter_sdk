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
          XdrSequenceNumber(XdrBigInt64(BigInt.from(100))),
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
          XdrSequenceNumber(XdrBigInt64(BigInt.from(100))),
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
}
