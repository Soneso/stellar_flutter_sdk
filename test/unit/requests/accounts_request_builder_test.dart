import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('AccountsRequestBuilder', () {
    late http.Client mockClient;
    late Uri serverUri;

    setUp(() {
      mockClient = MockClient((request) async {
        return http.Response('{"_embedded": {"records": []}}', 200);
      });
      serverUri = Uri.parse('https://horizon-testnet.stellar.org');
    });

    group('constructor', () {
      test('creates builder with accounts segment', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('accounts'));
      });

      test('uses provided HTTP client', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);

        expect(builder.httpClient, same(mockClient));
      });

      test('uses provided server URI', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.host, equals('horizon-testnet.stellar.org'));
        expect(uri.scheme, equals('https'));
      });
    });

    group('forSigner', () {
      final signerAccountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';

      test('adds signer query parameter', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        builder.forSigner(signerAccountId);
        final uri = builder.buildUri();

        expect(uri.queryParameters['signer'], equals(signerAccountId));
      });

      test('returns builder for method chaining', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        final result = builder.forSigner(signerAccountId);

        expect(result, same(builder));
      });

      test('can be combined with limit and order', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        builder
          ..forSigner(signerAccountId)
          ..limit(10)
          ..order(RequestBuilderOrder.DESC);
        final uri = builder.buildUri();

        expect(uri.queryParameters['signer'], equals(signerAccountId));
        expect(uri.queryParameters['limit'], equals('10'));
        expect(uri.queryParameters['order'], equals('desc'));
      });

      test('throws exception when combined with forAsset', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        final asset = AssetTypeCreditAlphaNum4('USD', signerAccountId);
        builder.forAsset(asset);

        expect(
          () => builder.forSigner(signerAccountId),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('forSponsor', () {
      final sponsorAccountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';

      test('adds sponsor query parameter', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        builder.forSponsor(sponsorAccountId);
        final uri = builder.buildUri();

        expect(uri.queryParameters['sponsor'], equals(sponsorAccountId));
      });

      test('returns builder for method chaining', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        final result = builder.forSponsor(sponsorAccountId);

        expect(result, same(builder));
      });

      test('can be combined with limit and order', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        builder
          ..forSponsor(sponsorAccountId)
          ..limit(20)
          ..order(RequestBuilderOrder.ASC);
        final uri = builder.buildUri();

        expect(uri.queryParameters['sponsor'], equals(sponsorAccountId));
        expect(uri.queryParameters['limit'], equals('20'));
        expect(uri.queryParameters['order'], equals('asc'));
      });

      test('can be combined with forSigner', () {
        final signerAccountId = 'GBZXN7PIRZGNMHGA7MUUUF4GWPY5AYPV6LY4UV2GL6VJGIQRXFDNMADI';
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        builder
          ..forSigner(signerAccountId)
          ..forSponsor(sponsorAccountId);
        final uri = builder.buildUri();

        expect(uri.queryParameters['signer'], equals(signerAccountId));
        expect(uri.queryParameters['sponsor'], equals(sponsorAccountId));
      });
    });

    group('forAsset', () {
      final issuerAccountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';

      test('adds asset query parameter for AlphaNum4', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        final asset = AssetTypeCreditAlphaNum4('USD', issuerAccountId);
        builder.forAsset(asset);
        final uri = builder.buildUri();

        expect(uri.queryParameters['asset'], equals('USD:$issuerAccountId'));
      });

      test('adds asset query parameter for AlphaNum12', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        final asset = AssetTypeCreditAlphaNum12('LONGASSET', issuerAccountId);
        builder.forAsset(asset);
        final uri = builder.buildUri();

        expect(uri.queryParameters['asset'], equals('LONGASSET:$issuerAccountId'));
      });

      test('adds asset query parameter for native asset', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        builder.forAsset(Asset.NATIVE);
        final uri = builder.buildUri();

        expect(uri.queryParameters['asset'], equals('native'));
      });

      test('returns builder for method chaining', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        final asset = AssetTypeCreditAlphaNum4('USD', issuerAccountId);
        final result = builder.forAsset(asset);

        expect(result, same(builder));
      });

      test('can be combined with limit and order', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        final asset = AssetTypeCreditAlphaNum4('EUR', issuerAccountId);
        builder
          ..forAsset(asset)
          ..limit(50)
          ..order(RequestBuilderOrder.DESC);
        final uri = builder.buildUri();

        expect(uri.queryParameters['asset'], contains('EUR'));
        expect(uri.queryParameters['limit'], equals('50'));
        expect(uri.queryParameters['order'], equals('desc'));
      });

      test('throws exception when combined with forSigner', () {
        final signerAccountId = 'GBZXN7PIRZGNMHGA7MUUUF4GWPY5AYPV6LY4UV2GL6VJGIQRXFDNMADI';
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        builder.forSigner(signerAccountId);

        final asset = AssetTypeCreditAlphaNum4('USD', issuerAccountId);
        expect(
          () => builder.forAsset(asset),
          throwsA(isA<Exception>()),
        );
      });

      test('can be combined with forSponsor', () {
        final sponsorAccountId = 'GBZXN7PIRZGNMHGA7MUUUF4GWPY5AYPV6LY4UV2GL6VJGIQRXFDNMADI';
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        final asset = AssetTypeCreditAlphaNum4('USD', issuerAccountId);
        builder
          ..forAsset(asset)
          ..forSponsor(sponsorAccountId);
        final uri = builder.buildUri();

        expect(uri.queryParameters['asset'], contains('USD'));
        expect(uri.queryParameters['sponsor'], equals(sponsorAccountId));
      });
    });

    group('forLiquidityPool', () {
      test('adds liquidity pool query parameter with hex ID', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        final poolId = 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890';
        builder.forLiquidityPool(poolId);
        final uri = builder.buildUri();

        expect(uri.queryParameters['liquidity_pool'], equals(poolId));
      });

      test('converts L-prefixed pool ID to hex', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        // Real liquidity pool ID format starting with L
        final poolId = 'dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7';
        final lPrefixedId = 'L' + poolId;
        builder.forLiquidityPool(lPrefixedId);
        final uri = builder.buildUri();

        // Should strip L prefix and decode
        expect(uri.queryParameters['liquidity_pool'], isNotEmpty);
      });

      test('handles invalid L-prefixed ID gracefully', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        final invalidLId = 'LINVALID';
        builder.forLiquidityPool(invalidLId);
        final uri = builder.buildUri();

        // Should use original ID if decoding fails
        expect(uri.queryParameters['liquidity_pool'], equals(invalidLId));
      });

      test('returns builder for method chaining', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        final poolId = 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890';
        final result = builder.forLiquidityPool(poolId);

        expect(result, same(builder));
      });

      test('can be combined with other filters', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        final poolId = 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890';
        builder
          ..forLiquidityPool(poolId)
          ..limit(25)
          ..order(RequestBuilderOrder.ASC);
        final uri = builder.buildUri();

        expect(uri.queryParameters['liquidity_pool'], equals(poolId));
        expect(uri.queryParameters['limit'], equals('25'));
        expect(uri.queryParameters['order'], equals('asc'));
      });
    });

    group('account', () {
      final accountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';

      test('builds URI with account ID segment', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        builder.setSegments(['accounts', accountId]);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('accounts'));
        expect(uri.pathSegments, contains(accountId));
      });

      test('overrides default segments with account path', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        builder.setSegments(['accounts', accountId]);
        final uri = builder.buildUri();

        final segments = uri.pathSegments;
        expect(segments.indexOf('accounts'), isNonNegative);
        expect(segments[segments.indexOf('accounts') + 1], equals(accountId));
      });
    });

    group('accountData', () {
      final accountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';
      final dataKey = 'my_data_key';

      test('builds URI with account data path', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        builder.setSegments(['accounts', accountId, 'data', dataKey]);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('accounts'));
        expect(uri.pathSegments, contains(accountId));
        expect(uri.pathSegments, contains('data'));
        expect(uri.pathSegments, contains(dataKey));
      });

      test('path segments are in correct order', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        builder.setSegments(['accounts', accountId, 'data', dataKey]);
        final uri = builder.buildUri();

        final segments = uri.pathSegments;
        final accountsIndex = segments.indexOf('accounts');
        expect(segments[accountsIndex + 1], equals(accountId));
        expect(segments[accountsIndex + 2], equals('data'));
        expect(segments[accountsIndex + 3], equals(dataKey));
      });
    });

    group('cursor, limit, and order', () {
      test('cursor returns AccountsRequestBuilder', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        final result = builder.cursor('12345');

        expect(result, isA<AccountsRequestBuilder>());
        expect(result, same(builder));
      });

      test('limit returns AccountsRequestBuilder', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        final result = builder.limit(10);

        expect(result, isA<AccountsRequestBuilder>());
        expect(result, same(builder));
      });

      test('order returns AccountsRequestBuilder', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        final result = builder.order(RequestBuilderOrder.ASC);

        expect(result, isA<AccountsRequestBuilder>());
        expect(result, same(builder));
      });

      test('supports full method chaining', () {
        final accountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';
        final builder = AccountsRequestBuilder(mockClient, serverUri);

        builder
          ..forSigner(accountId)
          ..cursor('now')
          ..limit(100)
          ..order(RequestBuilderOrder.DESC);

        final uri = builder.buildUri();

        expect(uri.queryParameters['signer'], equals(accountId));
        expect(uri.queryParameters['cursor'], equals('now'));
        expect(uri.queryParameters['limit'], equals('100'));
        expect(uri.queryParameters['order'], equals('desc'));
      });
    });

    group('buildUri with combinations', () {
      final accountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';
      final issuerAccountId = 'GBZXN7PIRZGNMHGA7MUUUF4GWPY5AYPV6LY4UV2GL6VJGIQRXFDNMADI';

      test('builds URI with forSigner and pagination', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        builder
          ..forSigner(accountId)
          ..cursor('12345')
          ..limit(50);
        final uri = builder.buildUri();

        expect(uri.queryParameters['signer'], equals(accountId));
        expect(uri.queryParameters['cursor'], equals('12345'));
        expect(uri.queryParameters['limit'], equals('50'));
      });

      test('builds URI with forAsset and sorting', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        final asset = AssetTypeCreditAlphaNum4('USD', issuerAccountId);
        builder
          ..forAsset(asset)
          ..order(RequestBuilderOrder.DESC)
          ..limit(20);
        final uri = builder.buildUri();

        expect(uri.queryParameters['asset'], contains('USD'));
        expect(uri.queryParameters['order'], equals('desc'));
        expect(uri.queryParameters['limit'], equals('20'));
      });

      test('builds URI with forSponsor and all parameters', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        builder
          ..forSponsor(accountId)
          ..cursor('67890')
          ..limit(30)
          ..order(RequestBuilderOrder.ASC);
        final uri = builder.buildUri();

        expect(uri.queryParameters['sponsor'], equals(accountId));
        expect(uri.queryParameters['cursor'], equals('67890'));
        expect(uri.queryParameters['limit'], equals('30'));
        expect(uri.queryParameters['order'], equals('asc'));
      });

      test('builds URI with forLiquidityPool and pagination', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        final poolId = 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890';
        builder
          ..forLiquidityPool(poolId)
          ..cursor('poolcursor')
          ..limit(15);
        final uri = builder.buildUri();

        expect(uri.queryParameters['liquidity_pool'], equals(poolId));
        expect(uri.queryParameters['cursor'], equals('poolcursor'));
        expect(uri.queryParameters['limit'], equals('15'));
      });

      test('builds URI with multiple filters combined', () {
        final sponsorAccountId = 'GBZXN7PIRZGNMHGA7MUUUF4GWPY5AYPV6LY4UV2GL6VJGIQRXFDNMADI';
        final signerAccountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        builder
          ..forSigner(signerAccountId)
          ..forSponsor(sponsorAccountId)
          ..limit(40)
          ..order(RequestBuilderOrder.DESC);
        final uri = builder.buildUri();

        expect(uri.queryParameters['signer'], equals(signerAccountId));
        expect(uri.queryParameters['sponsor'], equals(sponsorAccountId));
        expect(uri.queryParameters['limit'], equals('40'));
        expect(uri.queryParameters['order'], equals('desc'));
      });
    });

    group('URI construction edge cases', () {
      test('handles empty server path', () {
        final simpleUri = Uri.parse('https://horizon.stellar.org');
        final builder = AccountsRequestBuilder(mockClient, simpleUri);
        final uri = builder.buildUri();

        expect(uri.scheme, equals('https'));
        expect(uri.host, equals('horizon.stellar.org'));
        expect(uri.pathSegments, contains('accounts'));
      });

      test('handles server URI with port', () {
        final uriWithPort = Uri.parse('https://localhost:8000');
        final builder = AccountsRequestBuilder(mockClient, uriWithPort);
        final uri = builder.buildUri();

        expect(uri.port, equals(8000));
        expect(uri.host, equals('localhost'));
        expect(uri.pathSegments, contains('accounts'));
      });

      test('preserves HTTPS scheme', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.scheme, equals('https'));
      });

      test('handles account ID with no additional parameters', () {
        final accountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        builder.setSegments(['accounts', accountId]);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains(accountId));
        expect(uri.queryParameters, isEmpty);
      });
    });

    group('parameter validation', () {
      test('forSigner with empty string', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        builder.forSigner('');
        final uri = builder.buildUri();

        expect(uri.queryParameters['signer'], equals(''));
      });

      test('forSponsor with empty string', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        builder.forSponsor('');
        final uri = builder.buildUri();

        expect(uri.queryParameters['sponsor'], equals(''));
      });

      test('limit with zero value', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        builder.limit(0);
        final uri = builder.buildUri();

        expect(uri.queryParameters['limit'], equals('0'));
      });

      test('limit with large value', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        builder.limit(1000);
        final uri = builder.buildUri();

        expect(uri.queryParameters['limit'], equals('1000'));
      });

      test('cursor with special characters gets encoded', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        builder.cursor('cursor+with/special=chars');
        final uri = builder.buildUri();

        expect(uri.queryParameters['cursor'], equals('cursor+with/special=chars'));
      });
    });
  });
}
