import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('LiquidityPoolsRequestBuilder', () {
    late http.Client mockClient;
    late Uri serverUri;

    setUp(() {
      mockClient = MockClient((request) async {
        return http.Response('{"_embedded": {"records": []}}', 200);
      });
      serverUri = Uri.parse('https://horizon-testnet.stellar.org');
    });

    group('constructor', () {
      test('creates builder with liquidity_pools segment', () {
        final builder = LiquidityPoolsRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('liquidity_pools'));
      });

      test('uses provided HTTP client', () {
        final builder = LiquidityPoolsRequestBuilder(mockClient, serverUri);

        expect(builder.httpClient, same(mockClient));
      });

      test('uses provided server URI', () {
        final builder = LiquidityPoolsRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.host, equals('horizon-testnet.stellar.org'));
        expect(uri.scheme, equals('https'));
      });
    });

    group('forReserveAssets', () {
      final issuerAccountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';

      test('adds reserves parameter for two native assets', () {
        final builder = LiquidityPoolsRequestBuilder(mockClient, serverUri);
        builder.forReserveAssets(Asset.NATIVE, Asset.NATIVE);
        final uri = builder.buildUri();

        expect(uri.queryParameters['reserves'], contains('native'));
        expect(uri.queryParameters['reserves'], contains(','));
      });

      test('adds reserves parameter for native and credit asset', () {
        final builder = LiquidityPoolsRequestBuilder(mockClient, serverUri);
        final creditAsset = AssetTypeCreditAlphaNum4('USD', issuerAccountId);
        builder.forReserveAssets(Asset.NATIVE, creditAsset);
        final uri = builder.buildUri();

        expect(uri.queryParameters['reserves'], contains('native'));
        expect(uri.queryParameters['reserves'], contains('USD:'));
        expect(uri.queryParameters['reserves'], contains(','));
      });

      test('adds reserves parameter for two credit assets', () {
        final builder = LiquidityPoolsRequestBuilder(mockClient, serverUri);
        final assetA = AssetTypeCreditAlphaNum4('USD', issuerAccountId);
        final assetB = AssetTypeCreditAlphaNum4('EUR', issuerAccountId);
        builder.forReserveAssets(assetA, assetB);
        final uri = builder.buildUri();

        expect(uri.queryParameters['reserves'], contains('USD:'));
        expect(uri.queryParameters['reserves'], contains('EUR:'));
        expect(uri.queryParameters['reserves'], contains(','));
      });

      test('returns builder for method chaining', () {
        final builder = LiquidityPoolsRequestBuilder(mockClient, serverUri);
        final creditAsset = AssetTypeCreditAlphaNum4('USD', issuerAccountId);
        final result = builder.forReserveAssets(Asset.NATIVE, creditAsset);

        expect(result, same(builder));
      });

      test('can be combined with limit and order', () {
        final builder = LiquidityPoolsRequestBuilder(mockClient, serverUri);
        final assetA = AssetTypeCreditAlphaNum4('USD', issuerAccountId);
        final assetB = AssetTypeCreditAlphaNum4('EUR', issuerAccountId);
        builder
          ..forReserveAssets(assetA, assetB)
          ..limit(10)
          ..order(RequestBuilderOrder.DESC);
        final uri = builder.buildUri();

        expect(uri.queryParameters['reserves'], isNotEmpty);
        expect(uri.queryParameters['limit'], equals('10'));
        expect(uri.queryParameters['order'], equals('desc'));
      });
    });

    group('forAccount', () {
      final accountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';

      test('adds account query parameter', () {
        final builder = LiquidityPoolsRequestBuilder(mockClient, serverUri);
        builder.forAccount(accountId);
        final uri = builder.buildUri();

        expect(uri.queryParameters['account'], equals(accountId));
      });

      test('returns builder for method chaining', () {
        final builder = LiquidityPoolsRequestBuilder(mockClient, serverUri);
        final result = builder.forAccount(accountId);

        expect(result, same(builder));
      });

      test('can be combined with limit and order', () {
        final builder = LiquidityPoolsRequestBuilder(mockClient, serverUri);
        builder
          ..forAccount(accountId)
          ..limit(20)
          ..order(RequestBuilderOrder.ASC);
        final uri = builder.buildUri();

        expect(uri.queryParameters['account'], equals(accountId));
        expect(uri.queryParameters['limit'], equals('20'));
        expect(uri.queryParameters['order'], equals('asc'));
      });

      test('can be combined with forReserveAssets', () {
        final issuerAccountId = 'GBZXN7PIRZGNMHGA7MUUUF4GWPY5AYPV6LY4UV2GL6VJGIQRXFDNMADI';
        final builder = LiquidityPoolsRequestBuilder(mockClient, serverUri);
        final assetA = AssetTypeCreditAlphaNum4('USD', issuerAccountId);
        builder
          ..forAccount(accountId)
          ..forReserveAssets(Asset.NATIVE, assetA);
        final uri = builder.buildUri();

        expect(uri.queryParameters['account'], equals(accountId));
        expect(uri.queryParameters['reserves'], isNotEmpty);
      });
    });

    group('cursor, limit, and order', () {
      test('cursor returns LiquidityPoolsRequestBuilder', () {
        final builder = LiquidityPoolsRequestBuilder(mockClient, serverUri);
        final result = builder.cursor('12345');

        expect(result, isA<LiquidityPoolsRequestBuilder>());
        expect(result, same(builder));
      });

      test('limit returns LiquidityPoolsRequestBuilder', () {
        final builder = LiquidityPoolsRequestBuilder(mockClient, serverUri);
        final result = builder.limit(10);

        expect(result, isA<LiquidityPoolsRequestBuilder>());
        expect(result, same(builder));
      });

      test('order returns LiquidityPoolsRequestBuilder', () {
        final builder = LiquidityPoolsRequestBuilder(mockClient, serverUri);
        final result = builder.order(RequestBuilderOrder.ASC);

        expect(result, isA<LiquidityPoolsRequestBuilder>());
        expect(result, same(builder));
      });

      test('supports full method chaining', () {
        final builder = LiquidityPoolsRequestBuilder(mockClient, serverUri);

        builder
          ..cursor('now')
          ..limit(100)
          ..order(RequestBuilderOrder.DESC);

        final uri = builder.buildUri();

        expect(uri.queryParameters['cursor'], equals('now'));
        expect(uri.queryParameters['limit'], equals('100'));
        expect(uri.queryParameters['order'], equals('desc'));
      });
    });

    group('buildUri with combinations', () {
      final issuerAccountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';
      final accountId = 'GBZXN7PIRZGNMHGA7MUUUF4GWPY5AYPV6LY4UV2GL6VJGIQRXFDNMADI';

      test('builds URI with forReserveAssets and pagination', () {
        final builder = LiquidityPoolsRequestBuilder(mockClient, serverUri);
        final assetA = AssetTypeCreditAlphaNum4('USD', issuerAccountId);
        final assetB = AssetTypeCreditAlphaNum4('EUR', issuerAccountId);
        builder
          ..forReserveAssets(assetA, assetB)
          ..cursor('12345')
          ..limit(50);
        final uri = builder.buildUri();

        expect(uri.queryParameters['reserves'], isNotEmpty);
        expect(uri.queryParameters['cursor'], equals('12345'));
        expect(uri.queryParameters['limit'], equals('50'));
      });

      test('builds URI with forAccount and sorting', () {
        final builder = LiquidityPoolsRequestBuilder(mockClient, serverUri);
        builder
          ..forAccount(accountId)
          ..order(RequestBuilderOrder.DESC)
          ..limit(20);
        final uri = builder.buildUri();

        expect(uri.queryParameters['account'], equals(accountId));
        expect(uri.queryParameters['order'], equals('desc'));
        expect(uri.queryParameters['limit'], equals('20'));
      });

      test('builds URI with all parameters', () {
        final builder = LiquidityPoolsRequestBuilder(mockClient, serverUri);
        final assetA = AssetTypeCreditAlphaNum4('USD', issuerAccountId);
        builder
          ..forAccount(accountId)
          ..forReserveAssets(Asset.NATIVE, assetA)
          ..cursor('67890')
          ..limit(30)
          ..order(RequestBuilderOrder.ASC);
        final uri = builder.buildUri();

        expect(uri.queryParameters['account'], equals(accountId));
        expect(uri.queryParameters['reserves'], isNotEmpty);
        expect(uri.queryParameters['cursor'], equals('67890'));
        expect(uri.queryParameters['limit'], equals('30'));
        expect(uri.queryParameters['order'], equals('asc'));
      });
    });

    group('URI construction edge cases', () {
      test('handles empty server path', () {
        final simpleUri = Uri.parse('https://horizon.stellar.org');
        final builder = LiquidityPoolsRequestBuilder(mockClient, simpleUri);
        final uri = builder.buildUri();

        expect(uri.scheme, equals('https'));
        expect(uri.host, equals('horizon.stellar.org'));
        expect(uri.pathSegments, contains('liquidity_pools'));
      });

      test('handles server URI with port', () {
        final uriWithPort = Uri.parse('https://localhost:8000');
        final builder = LiquidityPoolsRequestBuilder(mockClient, uriWithPort);
        final uri = builder.buildUri();

        expect(uri.port, equals(8000));
        expect(uri.host, equals('localhost'));
        expect(uri.pathSegments, contains('liquidity_pools'));
      });

      test('preserves HTTPS scheme', () {
        final builder = LiquidityPoolsRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.scheme, equals('https'));
      });

      test('handles liquidity pools with no filters', () {
        final builder = LiquidityPoolsRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('liquidity_pools'));
        expect(uri.queryParameters, isEmpty);
      });
    });

    group('parameter validation', () {
      test('forAccount with empty string', () {
        final builder = LiquidityPoolsRequestBuilder(mockClient, serverUri);
        builder.forAccount('');
        final uri = builder.buildUri();

        expect(uri.queryParameters['account'], equals(''));
      });

      test('limit with zero value', () {
        final builder = LiquidityPoolsRequestBuilder(mockClient, serverUri);
        builder.limit(0);
        final uri = builder.buildUri();

        expect(uri.queryParameters['limit'], equals('0'));
      });

      test('limit with large value', () {
        final builder = LiquidityPoolsRequestBuilder(mockClient, serverUri);
        builder.limit(1000);
        final uri = builder.buildUri();

        expect(uri.queryParameters['limit'], equals('1000'));
      });

      test('cursor with special characters gets encoded', () {
        final builder = LiquidityPoolsRequestBuilder(mockClient, serverUri);
        builder.cursor('cursor+with/special=chars');
        final uri = builder.buildUri();

        expect(uri.queryParameters['cursor'], equals('cursor+with/special=chars'));
      });
    });
  });
}
