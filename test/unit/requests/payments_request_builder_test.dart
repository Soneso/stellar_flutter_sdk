import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('PaymentsRequestBuilder', () {
    late http.Client mockClient;
    late Uri serverUri;

    setUp(() {
      mockClient = MockClient((request) async {
        return http.Response('{"_embedded": {"records": []}}', 200);
      });
      serverUri = Uri.parse('https://horizon-testnet.stellar.org');
    });

    group('constructor', () {
      test('creates builder with payments segment', () {
        final builder = PaymentsRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('payments'));
      });

      test('uses provided server URI', () {
        final builder = PaymentsRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.host, equals('horizon-testnet.stellar.org'));
        expect(uri.scheme, equals('https'));
      });
    });

    group('forAccount', () {
      final accountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';

      test('builds URI with account payments path', () {
        final builder = PaymentsRequestBuilder(mockClient, serverUri);
        builder.forAccount(accountId);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('accounts'));
        expect(uri.pathSegments, contains(accountId));
        expect(uri.pathSegments, contains('payments'));
      });

      test('path segments are in correct order', () {
        final builder = PaymentsRequestBuilder(mockClient, serverUri);
        builder.forAccount(accountId);
        final uri = builder.buildUri();

        final segments = uri.pathSegments;
        final accountsIndex = segments.indexOf('accounts');
        expect(segments[accountsIndex + 1], equals(accountId));
        expect(segments[accountsIndex + 2], equals('payments'));
      });

      test('returns builder for method chaining', () {
        final builder = PaymentsRequestBuilder(mockClient, serverUri);
        final result = builder.forAccount(accountId);

        expect(result, same(builder));
      });

      test('can be combined with pagination parameters', () {
        final builder = PaymentsRequestBuilder(mockClient, serverUri);
        builder
          ..forAccount(accountId)
          ..limit(10)
          ..order(RequestBuilderOrder.DESC);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains(accountId));
        expect(uri.queryParameters['limit'], equals('10'));
        expect(uri.queryParameters['order'], equals('desc'));
      });

      test('can be combined with cursor', () {
        final builder = PaymentsRequestBuilder(mockClient, serverUri);
        builder
          ..forAccount(accountId)
          ..cursor('now')
          ..limit(20);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains(accountId));
        expect(uri.queryParameters['cursor'], equals('now'));
        expect(uri.queryParameters['limit'], equals('20'));
      });
    });

    group('forLedger', () {
      test('builds URI with ledger payments path', () {
        final builder = PaymentsRequestBuilder(mockClient, serverUri);
        builder.forLedger(12345);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('ledgers'));
        expect(uri.pathSegments, contains('12345'));
        expect(uri.pathSegments, contains('payments'));
      });

      test('path segments are in correct order', () {
        final builder = PaymentsRequestBuilder(mockClient, serverUri);
        builder.forLedger(67890);
        final uri = builder.buildUri();

        final segments = uri.pathSegments;
        final ledgersIndex = segments.indexOf('ledgers');
        expect(segments[ledgersIndex + 1], equals('67890'));
        expect(segments[ledgersIndex + 2], equals('payments'));
      });

      test('returns builder for method chaining', () {
        final builder = PaymentsRequestBuilder(mockClient, serverUri);
        final result = builder.forLedger(12345);

        expect(result, same(builder));
      });

      test('can be combined with limit and order', () {
        final builder = PaymentsRequestBuilder(mockClient, serverUri);
        builder
          ..forLedger(12345)
          ..limit(25)
          ..order(RequestBuilderOrder.ASC);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('12345'));
        expect(uri.queryParameters['limit'], equals('25'));
        expect(uri.queryParameters['order'], equals('asc'));
      });

      test('handles large ledger sequence numbers', () {
        final builder = PaymentsRequestBuilder(mockClient, serverUri);
        builder.forLedger(999999999);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('999999999'));
        expect(uri.pathSegments, contains('payments'));
      });
    });

    group('forTransaction', () {
      final transactionId = '3389e9f0f1a65f19736cacf544c2e825313e8447f569233bb8db39aa607c8889';

      test('builds URI with transaction payments path', () {
        final builder = PaymentsRequestBuilder(mockClient, serverUri);
        builder.forTransaction(transactionId);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('transactions'));
        expect(uri.pathSegments, contains(transactionId));
        expect(uri.pathSegments, contains('payments'));
      });

      test('path segments are in correct order', () {
        final builder = PaymentsRequestBuilder(mockClient, serverUri);
        builder.forTransaction(transactionId);
        final uri = builder.buildUri();

        final segments = uri.pathSegments;
        final txIndex = segments.indexOf('transactions');
        expect(segments[txIndex + 1], equals(transactionId));
        expect(segments[txIndex + 2], equals('payments'));
      });

      test('returns builder for method chaining', () {
        final builder = PaymentsRequestBuilder(mockClient, serverUri);
        final result = builder.forTransaction(transactionId);

        expect(result, same(builder));
      });

      test('can be combined with pagination', () {
        final builder = PaymentsRequestBuilder(mockClient, serverUri);
        builder
          ..forTransaction(transactionId)
          ..limit(15)
          ..cursor('12345');
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains(transactionId));
        expect(uri.queryParameters['limit'], equals('15'));
        expect(uri.queryParameters['cursor'], equals('12345'));
      });

      test('handles short transaction IDs', () {
        final builder = PaymentsRequestBuilder(mockClient, serverUri);
        builder.forTransaction('abc123');
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('abc123'));
        expect(uri.pathSegments, contains('payments'));
      });
    });

    group('cursor, limit, and order', () {
      test('cursor returns PaymentsRequestBuilder', () {
        final builder = PaymentsRequestBuilder(mockClient, serverUri);
        final result = builder.cursor('12345');

        expect(result, isA<PaymentsRequestBuilder>());
        expect(result, same(builder));
      });

      test('limit returns PaymentsRequestBuilder', () {
        final builder = PaymentsRequestBuilder(mockClient, serverUri);
        final result = builder.limit(10);

        expect(result, isA<PaymentsRequestBuilder>());
        expect(result, same(builder));
      });

      test('order returns PaymentsRequestBuilder', () {
        final builder = PaymentsRequestBuilder(mockClient, serverUri);
        final result = builder.order(RequestBuilderOrder.ASC);

        expect(result, isA<PaymentsRequestBuilder>());
        expect(result, same(builder));
      });

      test('supports full method chaining', () {
        final accountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';
        final builder = PaymentsRequestBuilder(mockClient, serverUri);

        builder
          ..forAccount(accountId)
          ..cursor('now')
          ..limit(100)
          ..order(RequestBuilderOrder.DESC);

        final uri = builder.buildUri();

        expect(uri.pathSegments, contains(accountId));
        expect(uri.queryParameters['cursor'], equals('now'));
        expect(uri.queryParameters['limit'], equals('100'));
        expect(uri.queryParameters['order'], equals('desc'));
      });
    });

    group('buildUri with combinations', () {
      test('builds URI with forAccount and pagination', () {
        final accountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';
        final builder = PaymentsRequestBuilder(mockClient, serverUri);
        builder
          ..forAccount(accountId)
          ..limit(50)
          ..cursor('test');
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains(accountId));
        expect(uri.queryParameters['limit'], equals('50'));
        expect(uri.queryParameters['cursor'], equals('test'));
      });

      test('builds URI with forLedger and all parameters', () {
        final builder = PaymentsRequestBuilder(mockClient, serverUri);
        builder
          ..forLedger(12345)
          ..cursor('67890')
          ..limit(30)
          ..order(RequestBuilderOrder.ASC);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('12345'));
        expect(uri.queryParameters['cursor'], equals('67890'));
        expect(uri.queryParameters['limit'], equals('30'));
        expect(uri.queryParameters['order'], equals('asc'));
      });

      test('builds URI with forTransaction and sorting', () {
        final txId = '3389e9f0f1a65f19736cacf544c2e825313e8447f569233bb8db39aa607c8889';
        final builder = PaymentsRequestBuilder(mockClient, serverUri);
        builder
          ..forTransaction(txId)
          ..order(RequestBuilderOrder.DESC)
          ..limit(40);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains(txId));
        expect(uri.queryParameters['order'], equals('desc'));
        expect(uri.queryParameters['limit'], equals('40'));
      });
    });

    group('URI construction edge cases', () {
      test('handles server URI with port', () {
        final uriWithPort = Uri.parse('https://localhost:8000');
        final builder = PaymentsRequestBuilder(mockClient, uriWithPort);
        final uri = builder.buildUri();

        expect(uri.port, equals(8000));
        expect(uri.host, equals('localhost'));
        expect(uri.pathSegments, contains('payments'));
      });

      test('preserves HTTPS scheme', () {
        final builder = PaymentsRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.scheme, equals('https'));
      });

      test('builds URI with no filters or parameters', () {
        final builder = PaymentsRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('payments'));
        expect(uri.queryParameters.isEmpty, isTrue);
      });

      test('handles server URI with existing path', () {
        final uriWithPath = Uri.parse('https://horizon-testnet.stellar.org/api/v1');
        final builder = PaymentsRequestBuilder(mockClient, uriWithPath);
        final uri = builder.buildUri();

        expect(uri.pathSegments.contains('api'), isTrue);
        expect(uri.pathSegments.contains('v1'), isTrue);
        expect(uri.pathSegments.contains('payments'), isTrue);
      });
    });

    group('parameter validation', () {
      test('cursor with special characters gets encoded', () {
        final builder = PaymentsRequestBuilder(mockClient, serverUri);
        builder.cursor('cursor+with/special=chars');
        final uri = builder.buildUri();

        expect(uri.queryParameters['cursor'], equals('cursor+with/special=chars'));
      });

      test('limit with zero value', () {
        final builder = PaymentsRequestBuilder(mockClient, serverUri);
        builder.limit(0);
        final uri = builder.buildUri();

        expect(uri.queryParameters['limit'], equals('0'));
      });

      test('limit with large value', () {
        final builder = PaymentsRequestBuilder(mockClient, serverUri);
        builder.limit(1000);
        final uri = builder.buildUri();

        expect(uri.queryParameters['limit'], equals('1000'));
      });
    });
  });
}
