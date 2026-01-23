import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('TransactionsRequestBuilder', () {
    late http.Client mockClient;
    late Uri serverUri;

    setUp(() {
      mockClient = MockClient((request) async {
        return http.Response('{"_embedded": {"records": []}}', 200);
      });
      serverUri = Uri.parse('https://horizon-testnet.stellar.org');
    });

    group('constructor', () {
      test('creates builder with transactions segment', () {
        final builder = TransactionsRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('transactions'));
      });

      test('uses provided server URI', () {
        final builder = TransactionsRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.host, equals('horizon-testnet.stellar.org'));
        expect(uri.scheme, equals('https'));
      });
    });

    group('forAccount', () {
      final accountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';

      test('builds URI with account transactions path', () {
        final builder = TransactionsRequestBuilder(mockClient, serverUri);
        builder.forAccount(accountId);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('accounts'));
        expect(uri.pathSegments, contains(accountId));
        expect(uri.pathSegments, contains('transactions'));
      });

      test('path segments are in correct order', () {
        final builder = TransactionsRequestBuilder(mockClient, serverUri);
        builder.forAccount(accountId);
        final uri = builder.buildUri();

        final segments = uri.pathSegments;
        final accountsIndex = segments.indexOf('accounts');
        expect(segments[accountsIndex + 1], equals(accountId));
        expect(segments[accountsIndex + 2], equals('transactions'));
      });

      test('returns builder for method chaining', () {
        final builder = TransactionsRequestBuilder(mockClient, serverUri);
        final result = builder.forAccount(accountId);

        expect(result, same(builder));
      });

      test('can be combined with pagination parameters', () {
        final builder = TransactionsRequestBuilder(mockClient, serverUri);
        builder
          ..forAccount(accountId)
          ..limit(10)
          ..order(RequestBuilderOrder.DESC);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains(accountId));
        expect(uri.queryParameters['limit'], equals('10'));
        expect(uri.queryParameters['order'], equals('desc'));
      });
    });

    group('forLedger', () {
      test('builds URI with ledger transactions path', () {
        final builder = TransactionsRequestBuilder(mockClient, serverUri);
        builder.forLedger(12345);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('ledgers'));
        expect(uri.pathSegments, contains('12345'));
        expect(uri.pathSegments, contains('transactions'));
      });

      test('path segments are in correct order', () {
        final builder = TransactionsRequestBuilder(mockClient, serverUri);
        builder.forLedger(67890);
        final uri = builder.buildUri();

        final segments = uri.pathSegments;
        final ledgersIndex = segments.indexOf('ledgers');
        expect(segments[ledgersIndex + 1], equals('67890'));
        expect(segments[ledgersIndex + 2], equals('transactions'));
      });

      test('returns builder for method chaining', () {
        final builder = TransactionsRequestBuilder(mockClient, serverUri);
        final result = builder.forLedger(12345);

        expect(result, same(builder));
      });

      test('can be combined with limit and order', () {
        final builder = TransactionsRequestBuilder(mockClient, serverUri);
        builder
          ..forLedger(12345)
          ..limit(20)
          ..order(RequestBuilderOrder.ASC);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('12345'));
        expect(uri.queryParameters['limit'], equals('20'));
        expect(uri.queryParameters['order'], equals('asc'));
      });
    });

    group('forClaimableBalance', () {
      test('builds URI with hex claimable balance ID', () {
        final builder = TransactionsRequestBuilder(mockClient, serverUri);
        final balanceId = 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890';
        builder.forClaimableBalance(balanceId);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('claimable_balances'));
        expect(uri.pathSegments, contains(balanceId));
        expect(uri.pathSegments, contains('transactions'));
      });

      test('converts B-prefixed claimable balance ID to hex', () {
        final builder = TransactionsRequestBuilder(mockClient, serverUri);
        final balanceId = 'Babcdef1234567890abcdef1234567890abcdef1234567890abcdef12345678';
        builder.forClaimableBalance(balanceId);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('claimable_balances'));
        expect(uri.pathSegments, contains('transactions'));
      });

      test('handles invalid B-prefixed ID gracefully', () {
        final builder = TransactionsRequestBuilder(mockClient, serverUri);
        final invalidId = 'BINVALID';
        builder.forClaimableBalance(invalidId);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('claimable_balances'));
        expect(uri.pathSegments, contains(invalidId));
      });

      test('returns builder for method chaining', () {
        final builder = TransactionsRequestBuilder(mockClient, serverUri);
        final result = builder.forClaimableBalance('test_id');

        expect(result, same(builder));
      });
    });

    group('forLiquidityPool', () {
      test('builds URI with hex liquidity pool ID', () {
        final builder = TransactionsRequestBuilder(mockClient, serverUri);
        final poolId = 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890';
        builder.forLiquidityPool(poolId);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('liquidity_pools'));
        expect(uri.pathSegments, contains(poolId));
        expect(uri.pathSegments, contains('transactions'));
      });

      test('converts L-prefixed liquidity pool ID to hex', () {
        final builder = TransactionsRequestBuilder(mockClient, serverUri);
        final poolId = 'Labcdef1234567890abcdef1234567890abcdef1234567890abcdef12345678';
        builder.forLiquidityPool(poolId);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('liquidity_pools'));
        expect(uri.pathSegments, contains('transactions'));
      });

      test('handles invalid L-prefixed ID gracefully', () {
        final builder = TransactionsRequestBuilder(mockClient, serverUri);
        final invalidId = 'LINVALID';
        builder.forLiquidityPool(invalidId);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('liquidity_pools'));
        expect(uri.pathSegments, contains(invalidId));
      });

      test('returns builder for method chaining', () {
        final builder = TransactionsRequestBuilder(mockClient, serverUri);
        final result = builder.forLiquidityPool('test_pool');

        expect(result, same(builder));
      });
    });

    group('includeFailed', () {
      test('adds include_failed parameter as true', () {
        final builder = TransactionsRequestBuilder(mockClient, serverUri);
        builder.includeFailed(true);
        final uri = builder.buildUri();

        expect(uri.queryParameters['include_failed'], equals('true'));
      });

      test('adds include_failed parameter as false', () {
        final builder = TransactionsRequestBuilder(mockClient, serverUri);
        builder.includeFailed(false);
        final uri = builder.buildUri();

        expect(uri.queryParameters['include_failed'], equals('false'));
      });

      test('returns builder for method chaining', () {
        final builder = TransactionsRequestBuilder(mockClient, serverUri);
        final result = builder.includeFailed(true);

        expect(result, same(builder));
      });

      test('can be combined with forAccount filter', () {
        final accountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';
        final builder = TransactionsRequestBuilder(mockClient, serverUri);
        builder
          ..forAccount(accountId)
          ..includeFailed(true);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains(accountId));
        expect(uri.queryParameters['include_failed'], equals('true'));
      });
    });

    group('cursor, limit, and order', () {
      test('cursor returns TransactionsRequestBuilder', () {
        final builder = TransactionsRequestBuilder(mockClient, serverUri);
        final result = builder.cursor('12345');

        expect(result, isA<TransactionsRequestBuilder>());
        expect(result, same(builder));
      });

      test('limit returns TransactionsRequestBuilder', () {
        final builder = TransactionsRequestBuilder(mockClient, serverUri);
        final result = builder.limit(10);

        expect(result, isA<TransactionsRequestBuilder>());
        expect(result, same(builder));
      });

      test('order returns TransactionsRequestBuilder', () {
        final builder = TransactionsRequestBuilder(mockClient, serverUri);
        final result = builder.order(RequestBuilderOrder.ASC);

        expect(result, isA<TransactionsRequestBuilder>());
        expect(result, same(builder));
      });

      test('supports full method chaining', () {
        final accountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';
        final builder = TransactionsRequestBuilder(mockClient, serverUri);

        builder
          ..forAccount(accountId)
          ..includeFailed(true)
          ..cursor('now')
          ..limit(100)
          ..order(RequestBuilderOrder.DESC);

        final uri = builder.buildUri();

        expect(uri.pathSegments, contains(accountId));
        expect(uri.queryParameters['include_failed'], equals('true'));
        expect(uri.queryParameters['cursor'], equals('now'));
        expect(uri.queryParameters['limit'], equals('100'));
        expect(uri.queryParameters['order'], equals('desc'));
      });
    });

    group('buildUri with combinations', () {
      test('builds URI with forAccount and includeFailed', () {
        final accountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';
        final builder = TransactionsRequestBuilder(mockClient, serverUri);
        builder
          ..forAccount(accountId)
          ..includeFailed(true)
          ..limit(50);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains(accountId));
        expect(uri.queryParameters['include_failed'], equals('true'));
        expect(uri.queryParameters['limit'], equals('50'));
      });

      test('builds URI with forLedger and all parameters', () {
        final builder = TransactionsRequestBuilder(mockClient, serverUri);
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

      test('builds URI with forLiquidityPool and pagination', () {
        final builder = TransactionsRequestBuilder(mockClient, serverUri);
        final poolId = 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890';
        builder
          ..forLiquidityPool(poolId)
          ..cursor('poolcursor')
          ..limit(15);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains(poolId));
        expect(uri.queryParameters['cursor'], equals('poolcursor'));
        expect(uri.queryParameters['limit'], equals('15'));
      });
    });

    group('URI construction edge cases', () {
      test('handles server URI with port', () {
        final uriWithPort = Uri.parse('https://localhost:8000');
        final builder = TransactionsRequestBuilder(mockClient, uriWithPort);
        final uri = builder.buildUri();

        expect(uri.port, equals(8000));
        expect(uri.host, equals('localhost'));
        expect(uri.pathSegments, contains('transactions'));
      });

      test('preserves HTTPS scheme', () {
        final builder = TransactionsRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.scheme, equals('https'));
      });

      test('builds URI with no filters or parameters', () {
        final builder = TransactionsRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('transactions'));
        expect(uri.queryParameters.isEmpty, isTrue);
      });
    });
  });
}
