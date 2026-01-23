import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('ClaimableBalancesRequestBuilder', () {
    late http.Client mockClient;
    late Uri serverUri;

    setUp(() {
      mockClient = MockClient((request) async {
        return http.Response('{"_embedded": {"records": []}}', 200);
      });
      serverUri = Uri.parse('https://horizon-testnet.stellar.org');
    });

    group('constructor', () {
      test('creates builder with claimable_balances segment', () {
        final builder = ClaimableBalancesRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('claimable_balances'));
      });

      test('uses provided HTTP client', () {
        final builder = ClaimableBalancesRequestBuilder(mockClient, serverUri);

        expect(builder.httpClient, same(mockClient));
      });

      test('uses provided server URI', () {
        final builder = ClaimableBalancesRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.host, equals('horizon-testnet.stellar.org'));
        expect(uri.scheme, equals('https'));
      });
    });

    group('forSponsor', () {
      final sponsorAccountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';

      test('adds sponsor query parameter', () {
        final builder = ClaimableBalancesRequestBuilder(mockClient, serverUri);
        builder.forSponsor(sponsorAccountId);
        final uri = builder.buildUri();

        expect(uri.queryParameters['sponsor'], equals(sponsorAccountId));
      });

      test('returns builder for method chaining', () {
        final builder = ClaimableBalancesRequestBuilder(mockClient, serverUri);
        final result = builder.forSponsor(sponsorAccountId);

        expect(result, same(builder));
      });

      test('can be combined with limit and order', () {
        final builder = ClaimableBalancesRequestBuilder(mockClient, serverUri);
        builder
          ..forSponsor(sponsorAccountId)
          ..limit(10)
          ..order(RequestBuilderOrder.DESC);
        final uri = builder.buildUri();

        expect(uri.queryParameters['sponsor'], equals(sponsorAccountId));
        expect(uri.queryParameters['limit'], equals('10'));
        expect(uri.queryParameters['order'], equals('desc'));
      });
    });

    group('forClaimant', () {
      final claimantAccountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';

      test('adds claimant query parameter', () {
        final builder = ClaimableBalancesRequestBuilder(mockClient, serverUri);
        builder.forClaimant(claimantAccountId);
        final uri = builder.buildUri();

        expect(uri.queryParameters['claimant'], equals(claimantAccountId));
      });

      test('returns builder for method chaining', () {
        final builder = ClaimableBalancesRequestBuilder(mockClient, serverUri);
        final result = builder.forClaimant(claimantAccountId);

        expect(result, same(builder));
      });

      test('can be combined with limit and order', () {
        final builder = ClaimableBalancesRequestBuilder(mockClient, serverUri);
        builder
          ..forClaimant(claimantAccountId)
          ..limit(20)
          ..order(RequestBuilderOrder.ASC);
        final uri = builder.buildUri();

        expect(uri.queryParameters['claimant'], equals(claimantAccountId));
        expect(uri.queryParameters['limit'], equals('20'));
        expect(uri.queryParameters['order'], equals('asc'));
      });

      test('can be combined with forSponsor', () {
        final sponsorAccountId = 'GBZXN7PIRZGNMHGA7MUUUF4GWPY5AYPV6LY4UV2GL6VJGIQRXFDNMADI';
        final builder = ClaimableBalancesRequestBuilder(mockClient, serverUri);
        builder
          ..forClaimant(claimantAccountId)
          ..forSponsor(sponsorAccountId);
        final uri = builder.buildUri();

        expect(uri.queryParameters['claimant'], equals(claimantAccountId));
        expect(uri.queryParameters['sponsor'], equals(sponsorAccountId));
      });
    });

    group('forAsset', () {
      final issuerAccountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';

      test('adds asset parameter for AlphaNum4', () {
        final builder = ClaimableBalancesRequestBuilder(mockClient, serverUri);
        final asset = AssetTypeCreditAlphaNum4('USD', issuerAccountId);
        builder.forAsset(asset);
        final uri = builder.buildUri();

        expect(uri.queryParameters['asset'], equals('USD:$issuerAccountId'));
      });

      test('adds asset parameter for AlphaNum12', () {
        final builder = ClaimableBalancesRequestBuilder(mockClient, serverUri);
        final asset = AssetTypeCreditAlphaNum12('LONGASSET', issuerAccountId);
        builder.forAsset(asset);
        final uri = builder.buildUri();

        expect(uri.queryParameters['asset'], equals('LONGASSET:$issuerAccountId'));
      });

      test('adds asset parameter for native asset', () {
        final builder = ClaimableBalancesRequestBuilder(mockClient, serverUri);
        builder.forAsset(Asset.NATIVE);
        final uri = builder.buildUri();

        expect(uri.queryParameters['asset'], equals('native'));
      });

      test('returns builder for method chaining', () {
        final builder = ClaimableBalancesRequestBuilder(mockClient, serverUri);
        final asset = AssetTypeCreditAlphaNum4('USD', issuerAccountId);
        final result = builder.forAsset(asset);

        expect(result, same(builder));
      });

      test('can be combined with forClaimant', () {
        final claimantAccountId = 'GBZXN7PIRZGNMHGA7MUUUF4GWPY5AYPV6LY4UV2GL6VJGIQRXFDNMADI';
        final builder = ClaimableBalancesRequestBuilder(mockClient, serverUri);
        final asset = AssetTypeCreditAlphaNum4('EUR', issuerAccountId);
        builder
          ..forAsset(asset)
          ..forClaimant(claimantAccountId);
        final uri = builder.buildUri();

        expect(uri.queryParameters['asset'], contains('EUR'));
        expect(uri.queryParameters['claimant'], equals(claimantAccountId));
      });
    });

    group('cursor, limit, and order', () {
      test('cursor returns ClaimableBalancesRequestBuilder', () {
        final builder = ClaimableBalancesRequestBuilder(mockClient, serverUri);
        final result = builder.cursor('12345');

        expect(result, isA<ClaimableBalancesRequestBuilder>());
        expect(result, same(builder));
      });

      test('limit returns ClaimableBalancesRequestBuilder', () {
        final builder = ClaimableBalancesRequestBuilder(mockClient, serverUri);
        final result = builder.limit(10);

        expect(result, isA<ClaimableBalancesRequestBuilder>());
        expect(result, same(builder));
      });

      test('order returns ClaimableBalancesRequestBuilder', () {
        final builder = ClaimableBalancesRequestBuilder(mockClient, serverUri);
        final result = builder.order(RequestBuilderOrder.ASC);

        expect(result, isA<ClaimableBalancesRequestBuilder>());
        expect(result, same(builder));
      });

      test('supports full method chaining', () {
        final builder = ClaimableBalancesRequestBuilder(mockClient, serverUri);

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
      final claimantAccountId = 'GBZXN7PIRZGNMHGA7MUUUF4GWPY5AYPV6LY4UV2GL6VJGIQRXFDNMADI';
      final sponsorAccountId = 'GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B';

      test('builds URI with forClaimant and pagination', () {
        final builder = ClaimableBalancesRequestBuilder(mockClient, serverUri);
        builder
          ..forClaimant(claimantAccountId)
          ..cursor('12345')
          ..limit(50);
        final uri = builder.buildUri();

        expect(uri.queryParameters['claimant'], equals(claimantAccountId));
        expect(uri.queryParameters['cursor'], equals('12345'));
        expect(uri.queryParameters['limit'], equals('50'));
      });

      test('builds URI with forSponsor and sorting', () {
        final builder = ClaimableBalancesRequestBuilder(mockClient, serverUri);
        builder
          ..forSponsor(sponsorAccountId)
          ..order(RequestBuilderOrder.DESC)
          ..limit(20);
        final uri = builder.buildUri();

        expect(uri.queryParameters['sponsor'], equals(sponsorAccountId));
        expect(uri.queryParameters['order'], equals('desc'));
        expect(uri.queryParameters['limit'], equals('20'));
      });

      test('builds URI with forAsset and pagination', () {
        final builder = ClaimableBalancesRequestBuilder(mockClient, serverUri);
        final asset = AssetTypeCreditAlphaNum4('USD', issuerAccountId);
        builder
          ..forAsset(asset)
          ..cursor('67890')
          ..limit(30);
        final uri = builder.buildUri();

        expect(uri.queryParameters['asset'], contains('USD'));
        expect(uri.queryParameters['cursor'], equals('67890'));
        expect(uri.queryParameters['limit'], equals('30'));
      });

      test('builds URI with all filters', () {
        final builder = ClaimableBalancesRequestBuilder(mockClient, serverUri);
        final asset = AssetTypeCreditAlphaNum4('EUR', issuerAccountId);
        builder
          ..forClaimant(claimantAccountId)
          ..forSponsor(sponsorAccountId)
          ..forAsset(asset)
          ..order(RequestBuilderOrder.ASC)
          ..limit(40);
        final uri = builder.buildUri();

        expect(uri.queryParameters['claimant'], equals(claimantAccountId));
        expect(uri.queryParameters['sponsor'], equals(sponsorAccountId));
        expect(uri.queryParameters['asset'], contains('EUR'));
        expect(uri.queryParameters['order'], equals('asc'));
        expect(uri.queryParameters['limit'], equals('40'));
      });
    });

    group('URI construction edge cases', () {
      test('handles empty server path', () {
        final simpleUri = Uri.parse('https://horizon.stellar.org');
        final builder = ClaimableBalancesRequestBuilder(mockClient, simpleUri);
        final uri = builder.buildUri();

        expect(uri.scheme, equals('https'));
        expect(uri.host, equals('horizon.stellar.org'));
        expect(uri.pathSegments, contains('claimable_balances'));
      });

      test('handles server URI with port', () {
        final uriWithPort = Uri.parse('https://localhost:8000');
        final builder = ClaimableBalancesRequestBuilder(mockClient, uriWithPort);
        final uri = builder.buildUri();

        expect(uri.port, equals(8000));
        expect(uri.host, equals('localhost'));
        expect(uri.pathSegments, contains('claimable_balances'));
      });

      test('preserves HTTPS scheme', () {
        final builder = ClaimableBalancesRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.scheme, equals('https'));
      });

      test('handles claimable balances with no filters', () {
        final builder = ClaimableBalancesRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('claimable_balances'));
        expect(uri.queryParameters, isEmpty);
      });
    });

    group('parameter validation', () {
      test('forSponsor with empty string', () {
        final builder = ClaimableBalancesRequestBuilder(mockClient, serverUri);
        builder.forSponsor('');
        final uri = builder.buildUri();

        expect(uri.queryParameters['sponsor'], equals(''));
      });

      test('forClaimant with empty string', () {
        final builder = ClaimableBalancesRequestBuilder(mockClient, serverUri);
        builder.forClaimant('');
        final uri = builder.buildUri();

        expect(uri.queryParameters['claimant'], equals(''));
      });

      test('limit with zero value', () {
        final builder = ClaimableBalancesRequestBuilder(mockClient, serverUri);
        builder.limit(0);
        final uri = builder.buildUri();

        expect(uri.queryParameters['limit'], equals('0'));
      });

      test('limit with large value', () {
        final builder = ClaimableBalancesRequestBuilder(mockClient, serverUri);
        builder.limit(1000);
        final uri = builder.buildUri();

        expect(uri.queryParameters['limit'], equals('1000'));
      });

      test('cursor with special characters gets encoded', () {
        final builder = ClaimableBalancesRequestBuilder(mockClient, serverUri);
        builder.cursor('cursor+with/special=chars');
        final uri = builder.buildUri();

        expect(uri.queryParameters['cursor'], equals('cursor+with/special=chars'));
      });
    });
  });
}
