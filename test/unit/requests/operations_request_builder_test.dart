import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('OperationsRequestBuilder', () {
    late http.Client mockClient;
    late Uri serverUri;

    setUp(() {
      mockClient = MockClient((request) async {
        return http.Response('{"_embedded": {"records": []}}', 200);
      });
      serverUri = Uri.parse('https://horizon-testnet.stellar.org');
    });

    group('constructor', () {
      test('creates builder with operations segment', () {
        final builder = OperationsRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('operations'));
      });

      test('uses provided server URI', () {
        final builder = OperationsRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.host, equals('horizon-testnet.stellar.org'));
        expect(uri.scheme, equals('https'));
      });
    });

    group('forAccount', () {
      final accountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';

      test('builds URI with account operations path', () {
        final builder = OperationsRequestBuilder(mockClient, serverUri);
        builder.forAccount(accountId);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('accounts'));
        expect(uri.pathSegments, contains(accountId));
        expect(uri.pathSegments, contains('operations'));
      });

      test('path segments are in correct order', () {
        final builder = OperationsRequestBuilder(mockClient, serverUri);
        builder.forAccount(accountId);
        final uri = builder.buildUri();

        final segments = uri.pathSegments;
        final accountsIndex = segments.indexOf('accounts');
        expect(segments[accountsIndex + 1], equals(accountId));
        expect(segments[accountsIndex + 2], equals('operations'));
      });

      test('returns builder for method chaining', () {
        final builder = OperationsRequestBuilder(mockClient, serverUri);
        final result = builder.forAccount(accountId);

        expect(result, same(builder));
      });

      test('can be combined with pagination parameters', () {
        final builder = OperationsRequestBuilder(mockClient, serverUri);
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
      test('builds URI with ledger operations path', () {
        final builder = OperationsRequestBuilder(mockClient, serverUri);
        builder.forLedger(12345);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('ledgers'));
        expect(uri.pathSegments, contains('12345'));
        expect(uri.pathSegments, contains('operations'));
      });

      test('path segments are in correct order', () {
        final builder = OperationsRequestBuilder(mockClient, serverUri);
        builder.forLedger(67890);
        final uri = builder.buildUri();

        final segments = uri.pathSegments;
        final ledgersIndex = segments.indexOf('ledgers');
        expect(segments[ledgersIndex + 1], equals('67890'));
        expect(segments[ledgersIndex + 2], equals('operations'));
      });

      test('returns builder for method chaining', () {
        final builder = OperationsRequestBuilder(mockClient, serverUri);
        final result = builder.forLedger(12345);

        expect(result, same(builder));
      });

      test('can be combined with limit and order', () {
        final builder = OperationsRequestBuilder(mockClient, serverUri);
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

    group('forTransaction', () {
      final transactionId = '3389e9f0f1a65f19736cacf544c2e825313e8447f569233bb8db39aa607c8889';

      test('builds URI with transaction operations path', () {
        final builder = OperationsRequestBuilder(mockClient, serverUri);
        builder.forTransaction(transactionId);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('transactions'));
        expect(uri.pathSegments, contains(transactionId));
        expect(uri.pathSegments, contains('operations'));
      });

      test('path segments are in correct order', () {
        final builder = OperationsRequestBuilder(mockClient, serverUri);
        builder.forTransaction(transactionId);
        final uri = builder.buildUri();

        final segments = uri.pathSegments;
        final txIndex = segments.indexOf('transactions');
        expect(segments[txIndex + 1], equals(transactionId));
        expect(segments[txIndex + 2], equals('operations'));
      });

      test('returns builder for method chaining', () {
        final builder = OperationsRequestBuilder(mockClient, serverUri);
        final result = builder.forTransaction(transactionId);

        expect(result, same(builder));
      });

      test('can be combined with pagination', () {
        final builder = OperationsRequestBuilder(mockClient, serverUri);
        builder
          ..forTransaction(transactionId)
          ..limit(25)
          ..cursor('12345');
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains(transactionId));
        expect(uri.queryParameters['limit'], equals('25'));
        expect(uri.queryParameters['cursor'], equals('12345'));
      });
    });

    group('forClaimableBalance', () {
      test('builds URI with hex claimable balance ID', () {
        final builder = OperationsRequestBuilder(mockClient, serverUri);
        final balanceId = 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890';
        builder.forClaimableBalance(balanceId);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('claimable_balances'));
        expect(uri.pathSegments, contains(balanceId));
        expect(uri.pathSegments, contains('operations'));
      });

      test('converts B-prefixed claimable balance ID to hex', () {
        final builder = OperationsRequestBuilder(mockClient, serverUri);
        final balanceId = 'Babcdef1234567890abcdef1234567890abcdef1234567890abcdef12345678';
        builder.forClaimableBalance(balanceId);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('claimable_balances'));
        expect(uri.pathSegments, contains('operations'));
      });

      test('handles invalid B-prefixed ID gracefully', () {
        final builder = OperationsRequestBuilder(mockClient, serverUri);
        final invalidId = 'BINVALID';
        builder.forClaimableBalance(invalidId);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('claimable_balances'));
        expect(uri.pathSegments, contains(invalidId));
      });

      test('returns builder for method chaining', () {
        final builder = OperationsRequestBuilder(mockClient, serverUri);
        final result = builder.forClaimableBalance('test_id');

        expect(result, same(builder));
      });
    });

    group('forLiquidityPool', () {
      test('builds URI with hex liquidity pool ID', () {
        final builder = OperationsRequestBuilder(mockClient, serverUri);
        final poolId = 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890';
        builder.forLiquidityPool(poolId);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('liquidity_pools'));
        expect(uri.pathSegments, contains(poolId));
        expect(uri.pathSegments, contains('operations'));
      });

      test('converts L-prefixed liquidity pool ID to hex', () {
        final builder = OperationsRequestBuilder(mockClient, serverUri);
        final poolId = 'Labcdef1234567890abcdef1234567890abcdef1234567890abcdef12345678';
        builder.forLiquidityPool(poolId);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('liquidity_pools'));
        expect(uri.pathSegments, contains('operations'));
      });

      test('handles invalid L-prefixed ID gracefully', () {
        final builder = OperationsRequestBuilder(mockClient, serverUri);
        final invalidId = 'LINVALID';
        builder.forLiquidityPool(invalidId);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('liquidity_pools'));
        expect(uri.pathSegments, contains(invalidId));
      });

      test('returns builder for method chaining', () {
        final builder = OperationsRequestBuilder(mockClient, serverUri);
        final result = builder.forLiquidityPool('test_pool');

        expect(result, same(builder));
      });
    });

    group('includeFailed', () {
      test('adds include_failed parameter as true', () {
        final builder = OperationsRequestBuilder(mockClient, serverUri);
        builder.includeFailed(true);
        final uri = builder.buildUri();

        expect(uri.queryParameters['include_failed'], equals('true'));
      });

      test('adds include_failed parameter as false', () {
        final builder = OperationsRequestBuilder(mockClient, serverUri);
        builder.includeFailed(false);
        final uri = builder.buildUri();

        expect(uri.queryParameters['include_failed'], equals('false'));
      });

      test('returns builder for method chaining', () {
        final builder = OperationsRequestBuilder(mockClient, serverUri);
        final result = builder.includeFailed(true);

        expect(result, same(builder));
      });

      test('can be combined with forAccount filter', () {
        final accountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';
        final builder = OperationsRequestBuilder(mockClient, serverUri);
        builder
          ..forAccount(accountId)
          ..includeFailed(true);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains(accountId));
        expect(uri.queryParameters['include_failed'], equals('true'));
      });
    });

    group('cursor, limit, and order', () {
      test('cursor returns OperationsRequestBuilder', () {
        final builder = OperationsRequestBuilder(mockClient, serverUri);
        final result = builder.cursor('12345');

        expect(result, isA<OperationsRequestBuilder>());
        expect(result, same(builder));
      });

      test('limit returns OperationsRequestBuilder', () {
        final builder = OperationsRequestBuilder(mockClient, serverUri);
        final result = builder.limit(10);

        expect(result, isA<OperationsRequestBuilder>());
        expect(result, same(builder));
      });

      test('order returns OperationsRequestBuilder', () {
        final builder = OperationsRequestBuilder(mockClient, serverUri);
        final result = builder.order(RequestBuilderOrder.ASC);

        expect(result, isA<OperationsRequestBuilder>());
        expect(result, same(builder));
      });

      test('supports full method chaining', () {
        final accountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';
        final builder = OperationsRequestBuilder(mockClient, serverUri);

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
      test('builds URI with forLedger and includeFailed', () {
        final builder = OperationsRequestBuilder(mockClient, serverUri);
        builder
          ..forLedger(12345)
          ..includeFailed(true)
          ..limit(50);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('12345'));
        expect(uri.queryParameters['include_failed'], equals('true'));
        expect(uri.queryParameters['limit'], equals('50'));
      });

      test('builds URI with forTransaction and all parameters', () {
        final txId = '3389e9f0f1a65f19736cacf544c2e825313e8447f569233bb8db39aa607c8889';
        final builder = OperationsRequestBuilder(mockClient, serverUri);
        builder
          ..forTransaction(txId)
          ..cursor('67890')
          ..limit(30)
          ..order(RequestBuilderOrder.ASC);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains(txId));
        expect(uri.queryParameters['cursor'], equals('67890'));
        expect(uri.queryParameters['limit'], equals('30'));
        expect(uri.queryParameters['order'], equals('asc'));
      });

      test('builds URI with forLiquidityPool and pagination', () {
        final builder = OperationsRequestBuilder(mockClient, serverUri);
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
        final builder = OperationsRequestBuilder(mockClient, uriWithPort);
        final uri = builder.buildUri();

        expect(uri.port, equals(8000));
        expect(uri.host, equals('localhost'));
        expect(uri.pathSegments, contains('operations'));
      });

      test('preserves HTTPS scheme', () {
        final builder = OperationsRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.scheme, equals('https'));
      });

      test('builds URI with no filters or parameters', () {
        final builder = OperationsRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('operations'));
        expect(uri.queryParameters.isEmpty, isTrue);
      });
    });
  });
}
