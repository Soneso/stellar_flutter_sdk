import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('EffectsRequestBuilder', () {
    late http.Client mockClient;
    late Uri serverUri;

    setUp(() {
      mockClient = MockClient((request) async {
        return http.Response('{"_embedded": {"records": []}}', 200);
      });
      serverUri = Uri.parse('https://horizon-testnet.stellar.org');
    });

    group('constructor', () {
      test('creates builder with effects segment', () {
        final builder = EffectsRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('effects'));
      });

      test('uses provided server URI', () {
        final builder = EffectsRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.host, equals('horizon-testnet.stellar.org'));
        expect(uri.scheme, equals('https'));
      });
    });

    group('forAccount', () {
      final accountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';

      test('builds URI with account effects path', () {
        final builder = EffectsRequestBuilder(mockClient, serverUri);
        builder.forAccount(accountId);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('accounts'));
        expect(uri.pathSegments, contains(accountId));
        expect(uri.pathSegments, contains('effects'));
      });

      test('path segments are in correct order', () {
        final builder = EffectsRequestBuilder(mockClient, serverUri);
        builder.forAccount(accountId);
        final uri = builder.buildUri();

        final segments = uri.pathSegments;
        final accountsIndex = segments.indexOf('accounts');
        expect(segments[accountsIndex + 1], equals(accountId));
        expect(segments[accountsIndex + 2], equals('effects'));
      });

      test('returns builder for method chaining', () {
        final builder = EffectsRequestBuilder(mockClient, serverUri);
        final result = builder.forAccount(accountId);

        expect(result, same(builder));
      });

      test('can be combined with pagination parameters', () {
        final builder = EffectsRequestBuilder(mockClient, serverUri);
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
        final builder = EffectsRequestBuilder(mockClient, serverUri);
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
      test('builds URI with ledger effects path', () {
        final builder = EffectsRequestBuilder(mockClient, serverUri);
        builder.forLedger(12345);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('ledgers'));
        expect(uri.pathSegments, contains('12345'));
        expect(uri.pathSegments, contains('effects'));
      });

      test('path segments are in correct order', () {
        final builder = EffectsRequestBuilder(mockClient, serverUri);
        builder.forLedger(67890);
        final uri = builder.buildUri();

        final segments = uri.pathSegments;
        final ledgersIndex = segments.indexOf('ledgers');
        expect(segments[ledgersIndex + 1], equals('67890'));
        expect(segments[ledgersIndex + 2], equals('effects'));
      });

      test('returns builder for method chaining', () {
        final builder = EffectsRequestBuilder(mockClient, serverUri);
        final result = builder.forLedger(12345);

        expect(result, same(builder));
      });

      test('can be combined with limit and order', () {
        final builder = EffectsRequestBuilder(mockClient, serverUri);
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
        final builder = EffectsRequestBuilder(mockClient, serverUri);
        builder.forLedger(999999999);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('999999999'));
        expect(uri.pathSegments, contains('effects'));
      });
    });

    group('forTransaction', () {
      final transactionId = '3389e9f0f1a65f19736cacf544c2e825313e8447f569233bb8db39aa607c8889';

      test('builds URI with transaction effects path', () {
        final builder = EffectsRequestBuilder(mockClient, serverUri);
        builder.forTransaction(transactionId);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('transactions'));
        expect(uri.pathSegments, contains(transactionId));
        expect(uri.pathSegments, contains('effects'));
      });

      test('path segments are in correct order', () {
        final builder = EffectsRequestBuilder(mockClient, serverUri);
        builder.forTransaction(transactionId);
        final uri = builder.buildUri();

        final segments = uri.pathSegments;
        final txIndex = segments.indexOf('transactions');
        expect(segments[txIndex + 1], equals(transactionId));
        expect(segments[txIndex + 2], equals('effects'));
      });

      test('returns builder for method chaining', () {
        final builder = EffectsRequestBuilder(mockClient, serverUri);
        final result = builder.forTransaction(transactionId);

        expect(result, same(builder));
      });

      test('can be combined with pagination', () {
        final builder = EffectsRequestBuilder(mockClient, serverUri);
        builder
          ..forTransaction(transactionId)
          ..limit(15)
          ..cursor('12345');
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains(transactionId));
        expect(uri.queryParameters['limit'], equals('15'));
        expect(uri.queryParameters['cursor'], equals('12345'));
      });
    });

    group('forOperation', () {
      final operationId = '12884905984';

      test('builds URI with operation effects path', () {
        final builder = EffectsRequestBuilder(mockClient, serverUri);
        builder.forOperation(operationId);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('operations'));
        expect(uri.pathSegments, contains(operationId));
        expect(uri.pathSegments, contains('effects'));
      });

      test('path segments are in correct order', () {
        final builder = EffectsRequestBuilder(mockClient, serverUri);
        builder.forOperation(operationId);
        final uri = builder.buildUri();

        final segments = uri.pathSegments;
        final opsIndex = segments.indexOf('operations');
        expect(segments[opsIndex + 1], equals(operationId));
        expect(segments[opsIndex + 2], equals('effects'));
      });

      test('returns builder for method chaining', () {
        final builder = EffectsRequestBuilder(mockClient, serverUri);
        final result = builder.forOperation(operationId);

        expect(result, same(builder));
      });

      test('can be combined with limit and order', () {
        final builder = EffectsRequestBuilder(mockClient, serverUri);
        builder
          ..forOperation(operationId)
          ..limit(30)
          ..order(RequestBuilderOrder.DESC);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains(operationId));
        expect(uri.queryParameters['limit'], equals('30'));
        expect(uri.queryParameters['order'], equals('desc'));
      });

      test('handles alphanumeric operation IDs', () {
        final builder = EffectsRequestBuilder(mockClient, serverUri);
        builder.forOperation('op_abc123');
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('op_abc123'));
        expect(uri.pathSegments, contains('effects'));
      });
    });

    group('forLiquidityPool', () {
      test('builds URI with hex liquidity pool ID', () {
        final builder = EffectsRequestBuilder(mockClient, serverUri);
        final poolId = 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890';
        builder.forLiquidityPool(poolId);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('liquidity_pools'));
        expect(uri.pathSegments, contains(poolId));
        expect(uri.pathSegments, contains('effects'));
      });

      test('converts L-prefixed liquidity pool ID to hex', () {
        final builder = EffectsRequestBuilder(mockClient, serverUri);
        final poolId = 'Labcdef1234567890abcdef1234567890abcdef1234567890abcdef12345678';
        builder.forLiquidityPool(poolId);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('liquidity_pools'));
        expect(uri.pathSegments, contains('effects'));
      });

      test('handles invalid L-prefixed ID gracefully', () {
        final builder = EffectsRequestBuilder(mockClient, serverUri);
        final invalidId = 'LINVALID';
        builder.forLiquidityPool(invalidId);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('liquidity_pools'));
        expect(uri.pathSegments, contains(invalidId));
      });

      test('returns builder for method chaining', () {
        final builder = EffectsRequestBuilder(mockClient, serverUri);
        final result = builder.forLiquidityPool('test_pool');

        expect(result, same(builder));
      });

      test('can be combined with pagination', () {
        final poolId = 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890';
        final builder = EffectsRequestBuilder(mockClient, serverUri);
        builder
          ..forLiquidityPool(poolId)
          ..limit(40)
          ..cursor('pool_cursor');
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains(poolId));
        expect(uri.queryParameters['limit'], equals('40'));
        expect(uri.queryParameters['cursor'], equals('pool_cursor'));
      });
    });

    group('cursor, limit, and order', () {
      test('cursor returns EffectsRequestBuilder', () {
        final builder = EffectsRequestBuilder(mockClient, serverUri);
        final result = builder.cursor('12345');

        expect(result, isA<EffectsRequestBuilder>());
        expect(result, same(builder));
      });

      test('limit returns EffectsRequestBuilder', () {
        final builder = EffectsRequestBuilder(mockClient, serverUri);
        final result = builder.limit(10);

        expect(result, isA<EffectsRequestBuilder>());
        expect(result, same(builder));
      });

      test('order returns EffectsRequestBuilder', () {
        final builder = EffectsRequestBuilder(mockClient, serverUri);
        final result = builder.order(RequestBuilderOrder.ASC);

        expect(result, isA<EffectsRequestBuilder>());
        expect(result, same(builder));
      });

      test('supports full method chaining', () {
        final accountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';
        final builder = EffectsRequestBuilder(mockClient, serverUri);

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
      test('builds URI with forLedger and pagination', () {
        final builder = EffectsRequestBuilder(mockClient, serverUri);
        builder
          ..forLedger(12345)
          ..limit(50)
          ..cursor('test');
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('12345'));
        expect(uri.queryParameters['limit'], equals('50'));
        expect(uri.queryParameters['cursor'], equals('test'));
      });

      test('builds URI with forTransaction and all parameters', () {
        final txId = '3389e9f0f1a65f19736cacf544c2e825313e8447f569233bb8db39aa607c8889';
        final builder = EffectsRequestBuilder(mockClient, serverUri);
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

      test('builds URI with forOperation and sorting', () {
        final opId = '12884905984';
        final builder = EffectsRequestBuilder(mockClient, serverUri);
        builder
          ..forOperation(opId)
          ..order(RequestBuilderOrder.DESC)
          ..limit(40);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains(opId));
        expect(uri.queryParameters['order'], equals('desc'));
        expect(uri.queryParameters['limit'], equals('40'));
      });

      test('builds URI with forLiquidityPool and pagination', () {
        final poolId = 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890';
        final builder = EffectsRequestBuilder(mockClient, serverUri);
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
        final builder = EffectsRequestBuilder(mockClient, uriWithPort);
        final uri = builder.buildUri();

        expect(uri.port, equals(8000));
        expect(uri.host, equals('localhost'));
        expect(uri.pathSegments, contains('effects'));
      });

      test('preserves HTTPS scheme', () {
        final builder = EffectsRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.scheme, equals('https'));
      });

      test('builds URI with no filters or parameters', () {
        final builder = EffectsRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('effects'));
        expect(uri.queryParameters.isEmpty, isTrue);
      });

      test('handles server URI with existing path', () {
        final uriWithPath = Uri.parse('https://horizon-testnet.stellar.org/api/v1');
        final builder = EffectsRequestBuilder(mockClient, uriWithPath);
        final uri = builder.buildUri();

        expect(uri.pathSegments.contains('api'), isTrue);
        expect(uri.pathSegments.contains('v1'), isTrue);
        expect(uri.pathSegments.contains('effects'), isTrue);
      });
    });

    group('parameter validation', () {
      test('cursor with special characters gets encoded', () {
        final builder = EffectsRequestBuilder(mockClient, serverUri);
        builder.cursor('cursor+with/special=chars');
        final uri = builder.buildUri();

        expect(uri.queryParameters['cursor'], equals('cursor+with/special=chars'));
      });

      test('limit with zero value', () {
        final builder = EffectsRequestBuilder(mockClient, serverUri);
        builder.limit(0);
        final uri = builder.buildUri();

        expect(uri.queryParameters['limit'], equals('0'));
      });

      test('limit with large value', () {
        final builder = EffectsRequestBuilder(mockClient, serverUri);
        builder.limit(1000);
        final uri = builder.buildUri();

        expect(uri.queryParameters['limit'], equals('1000'));
      });
    });
  });
}
