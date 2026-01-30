import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('OrderBookRequestBuilder', () {
    late http.Client mockClient;
    late Uri serverUri;

    setUp(() {
      mockClient = MockClient((request) async {
        return http.Response('{"bids": [], "asks": []}', 200);
      });
      serverUri = Uri.parse('https://horizon-testnet.stellar.org');
    });

    group('constructor', () {
      test('creates builder with order_book segment', () {
        final builder = OrderBookRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('order_book'));
      });

      test('uses provided HTTP client', () {
        final builder = OrderBookRequestBuilder(mockClient, serverUri);

        expect(builder.httpClient, same(mockClient));
      });

      test('uses provided server URI', () {
        final builder = OrderBookRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.host, equals('horizon-testnet.stellar.org'));
        expect(uri.scheme, equals('https'));
      });
    });

    group('sellingAsset', () {
      final issuerAccountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';

      test('adds selling asset parameters for AlphaNum4', () {
        final builder = OrderBookRequestBuilder(mockClient, serverUri);
        final asset = AssetTypeCreditAlphaNum4('USD', issuerAccountId);
        builder.sellingAsset(asset);
        final uri = builder.buildUri();

        expect(uri.queryParameters['selling_asset_type'], equals('credit_alphanum4'));
        expect(uri.queryParameters['selling_asset_code'], equals('USD'));
        expect(uri.queryParameters['selling_asset_issuer'], equals(issuerAccountId));
      });

      test('adds selling asset parameters for AlphaNum12', () {
        final builder = OrderBookRequestBuilder(mockClient, serverUri);
        final asset = AssetTypeCreditAlphaNum12('LONGASSET', issuerAccountId);
        builder.sellingAsset(asset);
        final uri = builder.buildUri();

        expect(uri.queryParameters['selling_asset_type'], equals('credit_alphanum12'));
        expect(uri.queryParameters['selling_asset_code'], equals('LONGASSET'));
        expect(uri.queryParameters['selling_asset_issuer'], equals(issuerAccountId));
      });

      test('adds selling asset parameters for native asset', () {
        final builder = OrderBookRequestBuilder(mockClient, serverUri);
        builder.sellingAsset(Asset.NATIVE);
        final uri = builder.buildUri();

        expect(uri.queryParameters['selling_asset_type'], equals('native'));
        expect(uri.queryParameters.containsKey('selling_asset_code'), isFalse);
        expect(uri.queryParameters.containsKey('selling_asset_issuer'), isFalse);
      });

      test('returns builder for method chaining', () {
        final builder = OrderBookRequestBuilder(mockClient, serverUri);
        final asset = AssetTypeCreditAlphaNum4('USD', issuerAccountId);
        final result = builder.sellingAsset(asset);

        expect(result, same(builder));
      });
    });

    group('buyingAsset', () {
      final issuerAccountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';

      test('adds buying asset parameters for AlphaNum4', () {
        final builder = OrderBookRequestBuilder(mockClient, serverUri);
        final asset = AssetTypeCreditAlphaNum4('EUR', issuerAccountId);
        builder.buyingAsset(asset);
        final uri = builder.buildUri();

        expect(uri.queryParameters['buying_asset_type'], equals('credit_alphanum4'));
        expect(uri.queryParameters['buying_asset_code'], equals('EUR'));
        expect(uri.queryParameters['buying_asset_issuer'], equals(issuerAccountId));
      });

      test('adds buying asset parameters for native asset', () {
        final builder = OrderBookRequestBuilder(mockClient, serverUri);
        builder.buyingAsset(Asset.NATIVE);
        final uri = builder.buildUri();

        expect(uri.queryParameters['buying_asset_type'], equals('native'));
      });

      test('returns builder for method chaining', () {
        final builder = OrderBookRequestBuilder(mockClient, serverUri);
        final asset = Asset.NATIVE;
        final result = builder.buyingAsset(asset);

        expect(result, same(builder));
      });

      test('combines with sellingAsset', () {
        final builder = OrderBookRequestBuilder(mockClient, serverUri);
        final sellingAsset = AssetTypeCreditAlphaNum4('USD', issuerAccountId);
        final buyingAsset = Asset.NATIVE;
        builder.sellingAsset(sellingAsset).buyingAsset(buyingAsset);
        final uri = builder.buildUri();

        expect(uri.queryParameters['selling_asset_code'], equals('USD'));
        expect(uri.queryParameters['selling_asset_type'], equals('credit_alphanum4'));
        expect(uri.queryParameters['buying_asset_type'], equals('native'));
      });
    });

    group('limit', () {
      test('limit returns OrderBookRequestBuilder', () {
        final builder = OrderBookRequestBuilder(mockClient, serverUri);
        final result = builder.limit(10);

        expect(result, isA<OrderBookRequestBuilder>());
        expect(result, same(builder));
      });

      test('adds limit query parameter', () {
        final builder = OrderBookRequestBuilder(mockClient, serverUri);
        builder.limit(20);
        final uri = builder.buildUri();

        expect(uri.queryParameters['limit'], equals('20'));
      });

      test('handles small limit value', () {
        final builder = OrderBookRequestBuilder(mockClient, serverUri);
        builder.limit(1);
        final uri = builder.buildUri();

        expect(uri.queryParameters['limit'], equals('1'));
      });

      test('handles large limit value', () {
        final builder = OrderBookRequestBuilder(mockClient, serverUri);
        builder.limit(200);
        final uri = builder.buildUri();

        expect(uri.queryParameters['limit'], equals('200'));
      });
    });

    group('buildUri with combinations', () {
      final issuerAccountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';

      test('builds URI with both assets', () {
        final builder = OrderBookRequestBuilder(mockClient, serverUri);
        final sellingAsset = AssetTypeCreditAlphaNum4('USD', issuerAccountId);
        final buyingAsset = Asset.NATIVE;
        builder
          ..sellingAsset(sellingAsset)
          ..buyingAsset(buyingAsset);
        final uri = builder.buildUri();

        expect(uri.queryParameters['selling_asset_type'], equals('credit_alphanum4'));
        expect(uri.queryParameters['selling_asset_code'], equals('USD'));
        expect(uri.queryParameters['buying_asset_type'], equals('native'));
      });

      test('builds URI with both assets and limit', () {
        final builder = OrderBookRequestBuilder(mockClient, serverUri);
        final sellingAsset = Asset.NATIVE;
        final buyingAsset = AssetTypeCreditAlphaNum4('USDC', issuerAccountId);
        builder
          ..sellingAsset(sellingAsset)
          ..buyingAsset(buyingAsset)
          ..limit(50);
        final uri = builder.buildUri();

        expect(uri.queryParameters['selling_asset_type'], equals('native'));
        expect(uri.queryParameters['buying_asset_code'], equals('USDC'));
        expect(uri.queryParameters['limit'], equals('50'));
      });

      test('builds URI with two credit assets', () {
        final builder = OrderBookRequestBuilder(mockClient, serverUri);
        final sellingAsset = AssetTypeCreditAlphaNum4('USD', issuerAccountId);
        final buyingAsset = AssetTypeCreditAlphaNum4('EUR', issuerAccountId);
        builder
          ..sellingAsset(sellingAsset)
          ..buyingAsset(buyingAsset)
          ..limit(10);
        final uri = builder.buildUri();

        expect(uri.queryParameters['selling_asset_code'], equals('USD'));
        expect(uri.queryParameters['buying_asset_code'], equals('EUR'));
        expect(uri.queryParameters['limit'], equals('10'));
      });

      test('builds URI with AlphaNum12 assets', () {
        final builder = OrderBookRequestBuilder(mockClient, serverUri);
        final sellingAsset = AssetTypeCreditAlphaNum12('LONGASSET1', issuerAccountId);
        final buyingAsset = AssetTypeCreditAlphaNum12('LONGASSET2', issuerAccountId);
        builder
          ..sellingAsset(sellingAsset)
          ..buyingAsset(buyingAsset);
        final uri = builder.buildUri();

        expect(uri.queryParameters['selling_asset_type'], equals('credit_alphanum12'));
        expect(uri.queryParameters['selling_asset_code'], equals('LONGASSET1'));
        expect(uri.queryParameters['buying_asset_type'], equals('credit_alphanum12'));
        expect(uri.queryParameters['buying_asset_code'], equals('LONGASSET2'));
      });
    });

    group('URI construction edge cases', () {
      test('handles empty server path', () {
        final simpleUri = Uri.parse('https://horizon.stellar.org');
        final builder = OrderBookRequestBuilder(mockClient, simpleUri);
        final uri = builder.buildUri();

        expect(uri.scheme, equals('https'));
        expect(uri.host, equals('horizon.stellar.org'));
        expect(uri.pathSegments, contains('order_book'));
      });

      test('handles server URI with port', () {
        final uriWithPort = Uri.parse('https://localhost:8000');
        final builder = OrderBookRequestBuilder(mockClient, uriWithPort);
        final uri = builder.buildUri();

        expect(uri.port, equals(8000));
        expect(uri.host, equals('localhost'));
        expect(uri.pathSegments, contains('order_book'));
      });

      test('preserves HTTPS scheme', () {
        final builder = OrderBookRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.scheme, equals('https'));
      });

      test('builds URI with selling asset only', () {
        final issuerAccountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';
        final builder = OrderBookRequestBuilder(mockClient, serverUri);
        final asset = AssetTypeCreditAlphaNum4('USD', issuerAccountId);
        builder.sellingAsset(asset);
        final uri = builder.buildUri();

        expect(uri.queryParameters['selling_asset_code'], equals('USD'));
        expect(uri.queryParameters.containsKey('buying_asset_type'), isFalse);
      });

      test('builds URI with buying asset only', () {
        final issuerAccountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';
        final builder = OrderBookRequestBuilder(mockClient, serverUri);
        final asset = AssetTypeCreditAlphaNum4('EUR', issuerAccountId);
        builder.buyingAsset(asset);
        final uri = builder.buildUri();

        expect(uri.queryParameters['buying_asset_code'], equals('EUR'));
        expect(uri.queryParameters.containsKey('selling_asset_type'), isFalse);
      });
    });

    group('parameter validation', () {
      test('limit with zero value', () {
        final builder = OrderBookRequestBuilder(mockClient, serverUri);
        builder.limit(0);
        final uri = builder.buildUri();

        expect(uri.queryParameters['limit'], equals('0'));
      });

      test('limit overwrites previous value', () {
        final builder = OrderBookRequestBuilder(mockClient, serverUri);
        builder.limit(10);
        builder.limit(20);
        final uri = builder.buildUri();

        expect(uri.queryParameters['limit'], equals('20'));
      });
    });

    group('execute', () {
      test('executes HTTP request and returns OrderBookResponse', () async {
        final mockResponse = '''
        {
          "bids": [
            {
              "price": "0.5000000",
              "amount": "100.0000000",
              "price_r": {"n": 1, "d": 2}
            }
          ],
          "asks": [
            {
              "price": "2.0000000",
              "amount": "50.0000000",
              "price_r": {"n": 2, "d": 1}
            }
          ],
          "base": {
            "asset_type": "native"
          },
          "counter": {
            "asset_type": "credit_alphanum4",
            "asset_code": "USD",
            "asset_issuer": "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX"
          }
        }
        ''';

        final client = MockClient((request) async {
          return http.Response(mockResponse, 200);
        });

        final issuerAccountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';
        final builder = OrderBookRequestBuilder(client, serverUri);
        builder.sellingAsset(Asset.NATIVE);
        builder.buyingAsset(AssetTypeCreditAlphaNum4('USD', issuerAccountId));

        final orderBook = await builder.execute();

        expect(orderBook, isNotNull);
        expect(orderBook.bids, isNotEmpty);
        expect(orderBook.asks, isNotEmpty);
        expect(orderBook.bids.length, equals(1));
        expect(orderBook.asks.length, equals(1));
        expect(orderBook.bids.first.amount, equals('100.0000000'));
        expect(orderBook.asks.first.amount, equals('50.0000000'));
      });

      test('executes request with limit parameter', () async {
        final mockResponse = '{"bids": [], "asks": [], "base": {"asset_type": "native"}, "counter": {"asset_type": "native"}}';
        final client = MockClient((request) async {
          expect(request.url.queryParameters['limit'], equals('5'));
          return http.Response(mockResponse, 200);
        });

        final builder = OrderBookRequestBuilder(client, serverUri);
        builder.sellingAsset(Asset.NATIVE);
        builder.buyingAsset(Asset.NATIVE);
        builder.limit(5);

        final orderBook = await builder.execute();

        expect(orderBook, isNotNull);
      });

      test('handles HTTP errors gracefully', () async {
        final client = MockClient((request) async {
          return http.Response('{"type": "not_found", "title": "Resource Missing"}', 404);
        });

        final builder = OrderBookRequestBuilder(client, serverUri);

        expect(() => builder.execute(), throwsA(isA<ErrorResponse>()));
      });
    });

    group('requestExecute static method', () {
      test('executes request for custom URI', () async {
        final mockResponse = '{"bids": [], "asks": [], "base": {"asset_type": "native"}, "counter": {"asset_type": "native"}}';
        final client = MockClient((request) async {
          expect(request.url.toString(), contains('/order_book'));
          return http.Response(mockResponse, 200);
        });

        final customUri = Uri.parse('https://horizon-testnet.stellar.org/order_book?selling_asset_type=native&buying_asset_type=native');
        final orderBook = await OrderBookRequestBuilder.requestExecute(client, customUri);

        expect(orderBook, isNotNull);
        expect(orderBook.bids, isEmpty);
        expect(orderBook.asks, isEmpty);
      });

      test('includes proper headers in request', () async {
        final mockResponse = '{"bids": [], "asks": [], "base": {"asset_type": "native"}, "counter": {"asset_type": "native"}}';
        final client = MockClient((request) async {
          expect(request.headers['X-Client-Name'], isNotNull);
          expect(request.headers['X-Client-Version'], isNotNull);
          return http.Response(mockResponse, 200);
        });

        final customUri = Uri.parse('https://horizon-testnet.stellar.org/order_book');
        await OrderBookRequestBuilder.requestExecute(client, customUri);
      });
    });

    group('stream', () {
      test('returns a stream of OrderBookResponse', () {
        final builder = OrderBookRequestBuilder(mockClient, serverUri);
        final stream = builder.stream();

        expect(stream, isA<Stream<OrderBookResponse>>());
      });

      test('stream can be listened to', () async {
        final builder = OrderBookRequestBuilder(mockClient, serverUri);
        final stream = builder.stream();

        final subscription = stream.listen((_) {});
        expect(subscription, isNotNull);

        await subscription.cancel();
      });

      test('stream supports multiple listeners', () async {
        final builder = OrderBookRequestBuilder(mockClient, serverUri);
        final stream = builder.stream();

        final subscription1 = stream.listen((_) {});
        final subscription2 = stream.listen((_) {});

        expect(subscription1, isNotNull);
        expect(subscription2, isNotNull);

        await subscription1.cancel();
        await subscription2.cancel();
      });
    });
  });
}
