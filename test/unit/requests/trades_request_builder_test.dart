import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('TradesRequestBuilder', () {
    late http.Client mockClient;
    late Uri serverUri;

    setUp(() {
      mockClient = MockClient((request) async {
        return http.Response('{"_embedded": {"records": []}}', 200);
      });
      serverUri = Uri.parse('https://horizon-testnet.stellar.org');
    });

    group('constructor', () {
      test('creates builder with trades segment', () {
        final builder = TradesRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('trades'));
      });

      test('uses provided HTTP client', () {
        final builder = TradesRequestBuilder(mockClient, serverUri);

        expect(builder.httpClient, same(mockClient));
      });

      test('uses provided server URI', () {
        final builder = TradesRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.host, equals('horizon-testnet.stellar.org'));
        expect(uri.scheme, equals('https'));
      });
    });

    group('baseAsset', () {
      final issuerAccountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';

      test('adds base asset parameters for AlphaNum4', () {
        final builder = TradesRequestBuilder(mockClient, serverUri);
        final asset = AssetTypeCreditAlphaNum4('USD', issuerAccountId);
        builder.baseAsset(asset);
        final uri = builder.buildUri();

        expect(uri.queryParameters['base_asset_type'], equals('credit_alphanum4'));
        expect(uri.queryParameters['base_asset_code'], equals('USD'));
        expect(uri.queryParameters['base_asset_issuer'], equals(issuerAccountId));
      });

      test('adds base asset parameters for AlphaNum12', () {
        final builder = TradesRequestBuilder(mockClient, serverUri);
        final asset = AssetTypeCreditAlphaNum12('LONGASSET', issuerAccountId);
        builder.baseAsset(asset);
        final uri = builder.buildUri();

        expect(uri.queryParameters['base_asset_type'], equals('credit_alphanum12'));
        expect(uri.queryParameters['base_asset_code'], equals('LONGASSET'));
        expect(uri.queryParameters['base_asset_issuer'], equals(issuerAccountId));
      });

      test('adds base asset parameters for native asset', () {
        final builder = TradesRequestBuilder(mockClient, serverUri);
        builder.baseAsset(Asset.NATIVE);
        final uri = builder.buildUri();

        expect(uri.queryParameters['base_asset_type'], equals('native'));
        expect(uri.queryParameters.containsKey('base_asset_code'), isFalse);
        expect(uri.queryParameters.containsKey('base_asset_issuer'), isFalse);
      });

      test('returns builder for method chaining', () {
        final builder = TradesRequestBuilder(mockClient, serverUri);
        final asset = AssetTypeCreditAlphaNum4('USD', issuerAccountId);
        final result = builder.baseAsset(asset);

        expect(result, same(builder));
      });
    });

    group('counterAsset', () {
      final issuerAccountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';

      test('adds counter asset parameters for AlphaNum4', () {
        final builder = TradesRequestBuilder(mockClient, serverUri);
        final asset = AssetTypeCreditAlphaNum4('EUR', issuerAccountId);
        builder.counterAsset(asset);
        final uri = builder.buildUri();

        expect(uri.queryParameters['counter_asset_type'], equals('credit_alphanum4'));
        expect(uri.queryParameters['counter_asset_code'], equals('EUR'));
        expect(uri.queryParameters['counter_asset_issuer'], equals(issuerAccountId));
      });

      test('adds counter asset parameters for native asset', () {
        final builder = TradesRequestBuilder(mockClient, serverUri);
        builder.counterAsset(Asset.NATIVE);
        final uri = builder.buildUri();

        expect(uri.queryParameters['counter_asset_type'], equals('native'));
      });

      test('combines with baseAsset', () {
        final builder = TradesRequestBuilder(mockClient, serverUri);
        final baseAsset = AssetTypeCreditAlphaNum4('USD', issuerAccountId);
        final counterAsset = Asset.NATIVE;
        builder.baseAsset(baseAsset).counterAsset(counterAsset);
        final uri = builder.buildUri();

        expect(uri.queryParameters['base_asset_type'], equals('credit_alphanum4'));
        expect(uri.queryParameters['base_asset_code'], equals('USD'));
        expect(uri.queryParameters['counter_asset_type'], equals('native'));
      });
    });

    group('tradeType', () {
      test('adds trade_type parameter', () {
        final builder = TradesRequestBuilder(mockClient, serverUri);
        builder.tradeType('orderbook');
        final uri = builder.buildUri();

        expect(uri.queryParameters['trade_type'], equals('orderbook'));
      });

      test('supports liquidity_pool trade type', () {
        final builder = TradesRequestBuilder(mockClient, serverUri);
        builder.tradeType('liquidity_pool');
        final uri = builder.buildUri();

        expect(uri.queryParameters['trade_type'], equals('liquidity_pool'));
      });

      test('supports all trade type', () {
        final builder = TradesRequestBuilder(mockClient, serverUri);
        builder.tradeType('all');
        final uri = builder.buildUri();

        expect(uri.queryParameters['trade_type'], equals('all'));
      });
    });

    group('forAccount', () {
      final accountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';

      test('sets account segment in URI', () {
        final builder = TradesRequestBuilder(mockClient, serverUri);
        builder.forAccount(accountId);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('accounts'));
        expect(uri.pathSegments, contains(accountId));
        expect(uri.pathSegments, contains('trades'));
      });

      test('path segments are in correct order', () {
        final builder = TradesRequestBuilder(mockClient, serverUri);
        builder.forAccount(accountId);
        final uri = builder.buildUri();

        final segments = uri.pathSegments;
        final accountsIndex = segments.indexOf('accounts');
        expect(segments[accountsIndex + 1], equals(accountId));
        expect(segments[accountsIndex + 2], equals('trades'));
      });

      test('returns builder for method chaining', () {
        final builder = TradesRequestBuilder(mockClient, serverUri);
        final result = builder.forAccount(accountId);

        expect(result, same(builder));
      });
    });

    group('offerId', () {
      test('adds offer_id query parameter', () {
        final builder = TradesRequestBuilder(mockClient, serverUri);
        builder.offerId('12345');
        final uri = builder.buildUri();

        expect(uri.queryParameters['offer_id'], equals('12345'));
      });

      test('combines with other filters', () {
        final builder = TradesRequestBuilder(mockClient, serverUri);
        builder.offerId('12345').limit(10);
        final uri = builder.buildUri();

        expect(uri.queryParameters['offer_id'], equals('12345'));
        expect(uri.queryParameters['limit'], equals('10'));
      });
    });

    group('liquidityPoolId', () {
      test('adds liquidity_pool_id query parameter with hex ID', () {
        final builder = TradesRequestBuilder(mockClient, serverUri);
        final poolId = 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890';
        builder.liquidityPoolId(poolId);
        final uri = builder.buildUri();

        expect(uri.queryParameters['liquidity_pool_id'], equals(poolId));
      });

      test('converts L-prefixed pool ID to hex', () {
        final builder = TradesRequestBuilder(mockClient, serverUri);
        final poolId = 'dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7';
        final lPrefixedId = 'L' + poolId;
        builder.liquidityPoolId(lPrefixedId);
        final uri = builder.buildUri();

        expect(uri.queryParameters['liquidity_pool_id'], isNotEmpty);
      });

      test('handles invalid L-prefixed ID gracefully', () {
        final builder = TradesRequestBuilder(mockClient, serverUri);
        final invalidLId = 'LINVALID';
        builder.liquidityPoolId(invalidLId);
        final uri = builder.buildUri();

        expect(uri.queryParameters['liquidity_pool_id'], equals(invalidLId));
      });
    });

    group('cursor, limit, and order', () {
      test('cursor returns TradesRequestBuilder', () {
        final builder = TradesRequestBuilder(mockClient, serverUri);
        final result = builder.cursor('12345');

        expect(result, isA<TradesRequestBuilder>());
        expect(result, same(builder));
      });

      test('limit returns TradesRequestBuilder', () {
        final builder = TradesRequestBuilder(mockClient, serverUri);
        final result = builder.limit(10);

        expect(result, isA<TradesRequestBuilder>());
        expect(result, same(builder));
      });

      test('order returns TradesRequestBuilder', () {
        final builder = TradesRequestBuilder(mockClient, serverUri);
        final result = builder.order(RequestBuilderOrder.ASC);

        expect(result, isA<TradesRequestBuilder>());
        expect(result, same(builder));
      });
    });

    group('buildUri with combinations', () {
      final issuerAccountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';

      test('builds URI with trading pair and pagination', () {
        final builder = TradesRequestBuilder(mockClient, serverUri);
        final baseAsset = AssetTypeCreditAlphaNum4('USD', issuerAccountId);
        final counterAsset = Asset.NATIVE;
        builder
          ..baseAsset(baseAsset)
          ..counterAsset(counterAsset)
          ..cursor('12345')
          ..limit(50);
        final uri = builder.buildUri();

        expect(uri.queryParameters['base_asset_code'], equals('USD'));
        expect(uri.queryParameters['counter_asset_type'], equals('native'));
        expect(uri.queryParameters['cursor'], equals('12345'));
        expect(uri.queryParameters['limit'], equals('50'));
      });

      test('builds URI with all trade filters', () {
        final builder = TradesRequestBuilder(mockClient, serverUri);
        final baseAsset = Asset.NATIVE;
        final counterAsset = AssetTypeCreditAlphaNum4('USDC', issuerAccountId);
        builder
          ..baseAsset(baseAsset)
          ..counterAsset(counterAsset)
          ..tradeType('orderbook')
          ..offerId('67890')
          ..order(RequestBuilderOrder.DESC)
          ..limit(20);
        final uri = builder.buildUri();

        expect(uri.queryParameters['base_asset_type'], equals('native'));
        expect(uri.queryParameters['counter_asset_code'], equals('USDC'));
        expect(uri.queryParameters['trade_type'], equals('orderbook'));
        expect(uri.queryParameters['offer_id'], equals('67890'));
        expect(uri.queryParameters['order'], equals('desc'));
        expect(uri.queryParameters['limit'], equals('20'));
      });
    });

    group('URI construction edge cases', () {
      test('handles empty server path', () {
        final simpleUri = Uri.parse('https://horizon.stellar.org');
        final builder = TradesRequestBuilder(mockClient, simpleUri);
        final uri = builder.buildUri();

        expect(uri.scheme, equals('https'));
        expect(uri.host, equals('horizon.stellar.org'));
        expect(uri.pathSegments, contains('trades'));
      });

      test('handles server URI with port', () {
        final uriWithPort = Uri.parse('https://localhost:8000');
        final builder = TradesRequestBuilder(mockClient, uriWithPort);
        final uri = builder.buildUri();

        expect(uri.port, equals(8000));
        expect(uri.host, equals('localhost'));
        expect(uri.pathSegments, contains('trades'));
      });

      test('preserves HTTPS scheme', () {
        final builder = TradesRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.scheme, equals('https'));
      });
    });

    group('execute', () {
      test('executes HTTP request and returns Page of TradeResponse', () async {
        final mockResponse = '''
        {
          "_embedded": {
            "records": [
              {
                "id": "141694811279085569-0",
                "paging_token": "141694811279085569-0",
                "ledger_close_time": "2024-01-01T00:00:00Z",
                "offer_id": "12345",
                "base_offer_id": "12345",
                "counter_offer_id": "67890",
                "base_account": "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX",
                "base_amount": "100.0000000",
                "base_asset_type": "native",
                "counter_account": "GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H",
                "counter_amount": "50.0000000",
                "counter_asset_type": "credit_alphanum4",
                "counter_asset_code": "USD",
                "counter_asset_issuer": "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX",
                "base_is_seller": true,
                "price": {
                  "n": "1",
                  "d": "2"
                },
                "trade_type": "orderbook",
                "_links": {
                  "self": {"href": "https://horizon-testnet.stellar.org/trades/141694811279085569-0"},
                  "base": {"href": "https://horizon-testnet.stellar.org/accounts/GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX"},
                  "counter": {"href": "https://horizon-testnet.stellar.org/accounts/GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H"},
                  "operation": {"href": "https://horizon-testnet.stellar.org/operations/141694811279085569"}
                }
              }
            ]
          },
          "_links": {
            "self": {"href": "https://horizon-testnet.stellar.org/trades"},
            "next": {"href": "https://horizon-testnet.stellar.org/trades?cursor=next"},
            "prev": {"href": "https://horizon-testnet.stellar.org/trades?cursor=prev"}
          }
        }
        ''';

        final client = MockClient((request) async {
          return http.Response(mockResponse, 200);
        });

        final builder = TradesRequestBuilder(client, serverUri);
        final page = await builder.execute();

        expect(page, isNotNull);
        expect(page.records, isNotEmpty);
        expect(page.records.length, equals(1));
        expect(page.records.first.baseAmount, equals('100.0000000'));
        expect(page.records.first.counterAmount, equals('50.0000000'));
      });

      test('executes request with all filters applied', () async {
        final mockResponse = '{"_embedded": {"records": []}, "_links": {"self": {"href": "test"}}}';
        final client = MockClient((request) async {
          expect(request.url.queryParameters['offer_id'], equals('12345'));
          expect(request.url.queryParameters['trade_type'], equals('orderbook'));
          expect(request.url.queryParameters['limit'], equals('10'));
          return http.Response(mockResponse, 200);
        });

        final builder = TradesRequestBuilder(client, serverUri);
        builder.offerId('12345').tradeType('orderbook').limit(10);
        final page = await builder.execute();

        expect(page, isNotNull);
        expect(page.records, isEmpty);
      });

      test('handles HTTP errors gracefully', () async {
        final client = MockClient((request) async {
          return http.Response('{"type": "not_found", "title": "Resource Missing"}', 404);
        });

        final builder = TradesRequestBuilder(client, serverUri);

        expect(() => builder.execute(), throwsA(isA<ErrorResponse>()));
      });
    });

    group('requestExecute static method', () {
      test('executes request for custom URI', () async {
        final mockResponse = '{"_embedded": {"records": []}, "_links": {"self": {"href": "test"}}}';
        final client = MockClient((request) async {
          expect(request.url.toString(), contains('/trades'));
          return http.Response(mockResponse, 200);
        });

        final customUri = Uri.parse('https://horizon-testnet.stellar.org/trades?cursor=test');
        final page = await TradesRequestBuilder.requestExecute(client, customUri);

        expect(page, isNotNull);
        expect(page.records, isEmpty);
      });

      test('includes proper headers in request', () async {
        final mockResponse = '{"_embedded": {"records": []}, "_links": {"self": {"href": "test"}}}';
        final client = MockClient((request) async {
          expect(request.headers['X-Client-Name'], isNotNull);
          expect(request.headers['X-Client-Version'], isNotNull);
          return http.Response(mockResponse, 200);
        });

        final customUri = Uri.parse('https://horizon-testnet.stellar.org/trades');
        await TradesRequestBuilder.requestExecute(client, customUri);
      });
    });

    group('stream', () {
      test('returns a stream of TradeResponse', () {
        final builder = TradesRequestBuilder(mockClient, serverUri);
        final stream = builder.stream();

        expect(stream, isA<Stream<TradeResponse>>());
      });

      test('stream can be listened to', () async {
        final builder = TradesRequestBuilder(mockClient, serverUri);
        final stream = builder.stream();

        final subscription = stream.listen((_) {});
        expect(subscription, isNotNull);

        await subscription.cancel();
      });

      test('stream supports multiple listeners', () async {
        final builder = TradesRequestBuilder(mockClient, serverUri);
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
