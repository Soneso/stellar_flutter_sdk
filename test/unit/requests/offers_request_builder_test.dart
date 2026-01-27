import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('OffersRequestBuilder', () {
    late http.Client mockClient;
    late Uri serverUri;

    setUp(() {
      mockClient = MockClient((request) async {
        return http.Response('{"_embedded": {"records": []}}', 200);
      });
      serverUri = Uri.parse('https://horizon-testnet.stellar.org');
    });

    group('constructor', () {
      test('creates builder with offers segment', () {
        final builder = OffersRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('offers'));
      });

      test('uses provided HTTP client', () {
        final builder = OffersRequestBuilder(mockClient, serverUri);

        expect(builder.httpClient, same(mockClient));
      });

      test('uses provided server URI', () {
        final builder = OffersRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.host, equals('horizon-testnet.stellar.org'));
        expect(uri.scheme, equals('https'));
      });
    });

    group('forAccount', () {
      final accountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';

      test('sets account segment in URI', () {
        final builder = OffersRequestBuilder(mockClient, serverUri);
        builder.forAccount(accountId);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('accounts'));
        expect(uri.pathSegments, contains(accountId));
        expect(uri.pathSegments, contains('offers'));
      });

      test('path segments are in correct order', () {
        final builder = OffersRequestBuilder(mockClient, serverUri);
        builder.forAccount(accountId);
        final uri = builder.buildUri();

        final segments = uri.pathSegments;
        final accountsIndex = segments.indexOf('accounts');
        expect(segments[accountsIndex + 1], equals(accountId));
        expect(segments[accountsIndex + 2], equals('offers'));
      });

      test('returns builder for method chaining', () {
        final builder = OffersRequestBuilder(mockClient, serverUri);
        final result = builder.forAccount(accountId);

        expect(result, same(builder));
      });
    });

    group('forSeller', () {
      final sellerAccountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';

      test('adds seller query parameter', () {
        final builder = OffersRequestBuilder(mockClient, serverUri);
        builder.forSeller(sellerAccountId);
        final uri = builder.buildUri();

        expect(uri.queryParameters['seller'], equals(sellerAccountId));
      });

      test('returns builder for method chaining', () {
        final builder = OffersRequestBuilder(mockClient, serverUri);
        final result = builder.forSeller(sellerAccountId);

        expect(result, same(builder));
      });

      test('can be combined with limit and order', () {
        final builder = OffersRequestBuilder(mockClient, serverUri);
        builder
          ..forSeller(sellerAccountId)
          ..limit(10)
          ..order(RequestBuilderOrder.DESC);
        final uri = builder.buildUri();

        expect(uri.queryParameters['seller'], equals(sellerAccountId));
        expect(uri.queryParameters['limit'], equals('10'));
        expect(uri.queryParameters['order'], equals('desc'));
      });
    });

    group('forBuyingAsset', () {
      final issuerAccountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';

      test('adds buying asset parameters for AlphaNum4', () {
        final builder = OffersRequestBuilder(mockClient, serverUri);
        final asset = AssetTypeCreditAlphaNum4('USD', issuerAccountId);
        builder.forBuyingAsset(asset);
        final uri = builder.buildUri();

        expect(uri.queryParameters['buying_asset_type'], equals('credit_alphanum4'));
        expect(uri.queryParameters['buying_asset_code'], equals('USD'));
        expect(uri.queryParameters['buying_asset_issuer'], equals(issuerAccountId));
      });

      test('adds buying asset parameters for AlphaNum12', () {
        final builder = OffersRequestBuilder(mockClient, serverUri);
        final asset = AssetTypeCreditAlphaNum12('LONGASSET', issuerAccountId);
        builder.forBuyingAsset(asset);
        final uri = builder.buildUri();

        expect(uri.queryParameters['buying_asset_type'], equals('credit_alphanum12'));
        expect(uri.queryParameters['buying_asset_code'], equals('LONGASSET'));
        expect(uri.queryParameters['buying_asset_issuer'], equals(issuerAccountId));
      });

      test('adds buying asset parameters for native asset', () {
        final builder = OffersRequestBuilder(mockClient, serverUri);
        builder.forBuyingAsset(Asset.NATIVE);
        final uri = builder.buildUri();

        expect(uri.queryParameters['buying_asset_type'], equals('native'));
        expect(uri.queryParameters.containsKey('buying_asset_code'), isFalse);
        expect(uri.queryParameters.containsKey('buying_asset_issuer'), isFalse);
      });

      test('returns builder for method chaining', () {
        final builder = OffersRequestBuilder(mockClient, serverUri);
        final asset = AssetTypeCreditAlphaNum4('USD', issuerAccountId);
        final result = builder.forBuyingAsset(asset);

        expect(result, same(builder));
      });
    });

    group('forSellingAsset', () {
      final issuerAccountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';

      test('adds selling asset parameters for AlphaNum4', () {
        final builder = OffersRequestBuilder(mockClient, serverUri);
        final asset = AssetTypeCreditAlphaNum4('EUR', issuerAccountId);
        builder.forSellingAsset(asset);
        final uri = builder.buildUri();

        expect(uri.queryParameters['selling_asset_type'], equals('credit_alphanum4'));
        expect(uri.queryParameters['selling_asset_code'], equals('EUR'));
        expect(uri.queryParameters['selling_asset_issuer'], equals(issuerAccountId));
      });

      test('adds selling asset parameters for native asset', () {
        final builder = OffersRequestBuilder(mockClient, serverUri);
        builder.forSellingAsset(Asset.NATIVE);
        final uri = builder.buildUri();

        expect(uri.queryParameters['selling_asset_type'], equals('native'));
      });

      test('combines with forBuyingAsset', () {
        final builder = OffersRequestBuilder(mockClient, serverUri);
        final buyingAsset = AssetTypeCreditAlphaNum4('USD', issuerAccountId);
        final sellingAsset = Asset.NATIVE;
        builder.forBuyingAsset(buyingAsset).forSellingAsset(sellingAsset);
        final uri = builder.buildUri();

        expect(uri.queryParameters['buying_asset_code'], equals('USD'));
        expect(uri.queryParameters['selling_asset_type'], equals('native'));
      });
    });

    group('forSponsor', () {
      final sponsorAccountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';

      test('adds sponsor query parameter', () {
        final builder = OffersRequestBuilder(mockClient, serverUri);
        builder.forSponsor(sponsorAccountId);
        final uri = builder.buildUri();

        expect(uri.queryParameters['sponsor'], equals(sponsorAccountId));
      });

      test('returns builder for method chaining', () {
        final builder = OffersRequestBuilder(mockClient, serverUri);
        final result = builder.forSponsor(sponsorAccountId);

        expect(result, same(builder));
      });

      test('can be combined with other filters', () {
        final sellerAccountId = 'GBZXN7PIRZGNMHGA7MUUUF4GWPY5AYPV6LY4UV2GL6VJGIQRXFDNMADI';
        final builder = OffersRequestBuilder(mockClient, serverUri);
        builder
          ..forSeller(sellerAccountId)
          ..forSponsor(sponsorAccountId)
          ..limit(20);
        final uri = builder.buildUri();

        expect(uri.queryParameters['seller'], equals(sellerAccountId));
        expect(uri.queryParameters['sponsor'], equals(sponsorAccountId));
        expect(uri.queryParameters['limit'], equals('20'));
      });
    });

    group('cursor, limit, and order', () {
      test('cursor returns OffersRequestBuilder', () {
        final builder = OffersRequestBuilder(mockClient, serverUri);
        final result = builder.cursor('12345');

        expect(result, isA<OffersRequestBuilder>());
        expect(result, same(builder));
      });

      test('limit returns OffersRequestBuilder', () {
        final builder = OffersRequestBuilder(mockClient, serverUri);
        final result = builder.limit(10);

        expect(result, isA<OffersRequestBuilder>());
        expect(result, same(builder));
      });

      test('order returns OffersRequestBuilder', () {
        final builder = OffersRequestBuilder(mockClient, serverUri);
        final result = builder.order(RequestBuilderOrder.ASC);

        expect(result, isA<OffersRequestBuilder>());
        expect(result, same(builder));
      });
    });

    group('buildUri with combinations', () {
      final issuerAccountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';

      test('builds URI with buying and selling assets', () {
        final builder = OffersRequestBuilder(mockClient, serverUri);
        final buyingAsset = AssetTypeCreditAlphaNum4('USD', issuerAccountId);
        final sellingAsset = AssetTypeCreditAlphaNum4('EUR', issuerAccountId);
        builder
          ..forBuyingAsset(buyingAsset)
          ..forSellingAsset(sellingAsset)
          ..cursor('12345')
          ..limit(50);
        final uri = builder.buildUri();

        expect(uri.queryParameters['buying_asset_code'], equals('USD'));
        expect(uri.queryParameters['selling_asset_code'], equals('EUR'));
        expect(uri.queryParameters['cursor'], equals('12345'));
        expect(uri.queryParameters['limit'], equals('50'));
      });

      test('builds URI with seller and sponsor', () {
        final sellerAccountId = 'GBZXN7PIRZGNMHGA7MUUUF4GWPY5AYPV6LY4UV2GL6VJGIQRXFDNMADI';
        final sponsorAccountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';
        final builder = OffersRequestBuilder(mockClient, serverUri);
        builder
          ..forSeller(sellerAccountId)
          ..forSponsor(sponsorAccountId)
          ..order(RequestBuilderOrder.DESC)
          ..limit(20);
        final uri = builder.buildUri();

        expect(uri.queryParameters['seller'], equals(sellerAccountId));
        expect(uri.queryParameters['sponsor'], equals(sponsorAccountId));
        expect(uri.queryParameters['order'], equals('desc'));
        expect(uri.queryParameters['limit'], equals('20'));
      });
    });

    group('URI construction edge cases', () {
      test('handles empty server path', () {
        final simpleUri = Uri.parse('https://horizon.stellar.org');
        final builder = OffersRequestBuilder(mockClient, simpleUri);
        final uri = builder.buildUri();

        expect(uri.scheme, equals('https'));
        expect(uri.host, equals('horizon.stellar.org'));
        expect(uri.pathSegments, contains('offers'));
      });

      test('handles server URI with port', () {
        final uriWithPort = Uri.parse('https://localhost:8000');
        final builder = OffersRequestBuilder(mockClient, uriWithPort);
        final uri = builder.buildUri();

        expect(uri.port, equals(8000));
        expect(uri.host, equals('localhost'));
        expect(uri.pathSegments, contains('offers'));
      });

      test('preserves HTTPS scheme', () {
        final builder = OffersRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.scheme, equals('https'));
      });
    });

    group('execute', () {
      test('executes HTTP request and returns Page of OfferResponse', () async {
        final mockResponse = '''
        {
          "_embedded": {
            "records": [
              {
                "id": "12345",
                "paging_token": "12345",
                "seller": "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX",
                "selling": {
                  "asset_type": "native"
                },
                "buying": {
                  "asset_type": "credit_alphanum4",
                  "asset_code": "USD",
                  "asset_issuer": "GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H"
                },
                "amount": "1000.0000000",
                "price_r": {
                  "n": 1,
                  "d": 2
                },
                "price": "0.5",
                "last_modified_ledger": 12345,
                "last_modified_time": "2024-01-01T00:00:00Z",
                "_links": {
                  "self": {"href": "https://horizon-testnet.stellar.org/offers/12345"},
                  "offer_maker": {"href": "https://horizon-testnet.stellar.org/accounts/GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX"}
                }
              }
            ]
          },
          "_links": {
            "self": {"href": "https://horizon-testnet.stellar.org/offers"},
            "next": {"href": "https://horizon-testnet.stellar.org/offers?cursor=next"},
            "prev": {"href": "https://horizon-testnet.stellar.org/offers?cursor=prev"}
          }
        }
        ''';

        final client = MockClient((request) async {
          return http.Response(mockResponse, 200);
        });

        final builder = OffersRequestBuilder(client, serverUri);
        final page = await builder.execute();

        expect(page, isNotNull);
        expect(page.records, isNotEmpty);
        expect(page.records.length, equals(1));
        expect(page.records.first.id, equals('12345'));
      });

      test('handles HTTP errors gracefully', () async {
        final client = MockClient((request) async {
          return http.Response('{"type": "not_found", "title": "Resource Missing"}', 404);
        });

        final builder = OffersRequestBuilder(client, serverUri);

        expect(() => builder.execute(), throwsA(isA<ErrorResponse>()));
      });
    });

    group('requestExecute static method', () {
      test('executes request for custom URI', () async {
        final mockResponse = '{"_embedded": {"records": []}, "_links": {"self": {"href": "test"}}}';
        final client = MockClient((request) async {
          expect(request.url.toString(), contains('/offers'));
          return http.Response(mockResponse, 200);
        });

        final customUri = Uri.parse('https://horizon-testnet.stellar.org/offers?cursor=test');
        final page = await OffersRequestBuilder.requestExecute(client, customUri);

        expect(page, isNotNull);
        expect(page.records, isEmpty);
      });
    });

    group('stream', () {
      test('returns a stream of OfferResponse', () {
        final builder = OffersRequestBuilder(mockClient, serverUri);
        final stream = builder.stream();

        expect(stream, isA<Stream<OfferResponse>>());
      });

      test('stream can be listened to', () async {
        final builder = OffersRequestBuilder(mockClient, serverUri);
        final stream = builder.stream();

        final subscription = stream.listen((_) {});
        expect(subscription, isNotNull);

        await subscription.cancel();
      });
    });

    group('offer method', () {
      test('fetches specific offer by ID', () async {
        final offerId = '12345';
        final mockResponse = '''
        {
          "id": "12345",
          "paging_token": "12345",
          "seller": "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX",
          "selling": {
            "asset_type": "native"
          },
          "buying": {
            "asset_type": "credit_alphanum4",
            "asset_code": "USD",
            "asset_issuer": "GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H"
          },
          "amount": "1000.0000000",
          "price_r": {
            "n": 1,
            "d": 2
          },
          "price": "0.5",
          "last_modified_ledger": 12345,
          "last_modified_time": "2024-01-01T00:00:00Z",
          "_links": {
            "self": {"href": "https://horizon-testnet.stellar.org/offers/12345"},
            "offer_maker": {"href": "https://horizon-testnet.stellar.org/accounts/GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX"}
          }
        }
        ''';

        final client = MockClient((request) async {
          expect(request.url.pathSegments, contains('offers'));
          expect(request.url.pathSegments, contains(offerId));
          return http.Response(mockResponse, 200);
        });

        final builder = OffersRequestBuilder(client, serverUri);
        final offer = await builder.offer(offerId);

        expect(offer, isNotNull);
        expect(offer.id, equals(offerId));
      });
    });
  });
}
