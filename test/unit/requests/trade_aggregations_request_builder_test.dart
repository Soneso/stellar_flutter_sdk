import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('TradeAggregationsRequestBuilder', () {
    late http.Client mockClient;
    late Uri serverUri;
    late Asset baseAsset;
    late Asset counterAsset;
    late int startTime;
    late int endTime;
    late int resolution;
    late int offset;
    final issuerAccountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';

    setUp(() {
      mockClient = MockClient((request) async {
        return http.Response('{"_embedded": {"records": []}}', 200);
      });
      serverUri = Uri.parse('https://horizon-testnet.stellar.org');
      baseAsset = AssetTypeCreditAlphaNum4('USD', issuerAccountId);
      counterAsset = Asset.NATIVE;
      startTime = 1633024800000; // October 1, 2021 00:00:00 UTC
      endTime = 1633111200000; // October 2, 2021 00:00:00 UTC
      resolution = 3600000; // 1 hour
      offset = 0;
    });

    group('constructor', () {
      test('creates builder with trade_aggregations segment', () {
        final builder = TradeAggregationsRequestBuilder(
          mockClient,
          serverUri,
          baseAsset,
          counterAsset,
          startTime,
          endTime,
          resolution,
          offset,
        );
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('trade_aggregations'));
      });

      test('uses provided HTTP client', () {
        final builder = TradeAggregationsRequestBuilder(
          mockClient,
          serverUri,
          baseAsset,
          counterAsset,
          startTime,
          endTime,
          resolution,
          offset,
        );

        expect(builder.httpClient, same(mockClient));
      });

      test('uses provided server URI', () {
        final builder = TradeAggregationsRequestBuilder(
          mockClient,
          serverUri,
          baseAsset,
          counterAsset,
          startTime,
          endTime,
          resolution,
          offset,
        );
        final uri = builder.buildUri();

        expect(uri.host, equals('horizon-testnet.stellar.org'));
        expect(uri.scheme, equals('https'));
      });
    });

    group('base asset parameters', () {
      test('adds base asset parameters for AlphaNum4', () {
        final baseAsset = AssetTypeCreditAlphaNum4('USD', issuerAccountId);
        final builder = TradeAggregationsRequestBuilder(
          mockClient,
          serverUri,
          baseAsset,
          counterAsset,
          startTime,
          endTime,
          resolution,
          offset,
        );
        final uri = builder.buildUri();

        expect(uri.queryParameters['base_asset_type'], equals('credit_alphanum4'));
        expect(uri.queryParameters['base_asset_code'], equals('USD'));
        expect(uri.queryParameters['base_asset_issuer'], equals(issuerAccountId));
      });

      test('adds base asset parameters for AlphaNum12', () {
        final baseAsset = AssetTypeCreditAlphaNum12('LONGASSET', issuerAccountId);
        final builder = TradeAggregationsRequestBuilder(
          mockClient,
          serverUri,
          baseAsset,
          counterAsset,
          startTime,
          endTime,
          resolution,
          offset,
        );
        final uri = builder.buildUri();

        expect(uri.queryParameters['base_asset_type'], equals('credit_alphanum12'));
        expect(uri.queryParameters['base_asset_code'], equals('LONGASSET'));
        expect(uri.queryParameters['base_asset_issuer'], equals(issuerAccountId));
      });

      test('adds base asset parameters for native asset', () {
        final baseAsset = Asset.NATIVE;
        final builder = TradeAggregationsRequestBuilder(
          mockClient,
          serverUri,
          baseAsset,
          counterAsset,
          startTime,
          endTime,
          resolution,
          offset,
        );
        final uri = builder.buildUri();

        expect(uri.queryParameters['base_asset_type'], equals('native'));
        expect(uri.queryParameters.containsKey('base_asset_code'), isFalse);
        expect(uri.queryParameters.containsKey('base_asset_issuer'), isFalse);
      });
    });

    group('counter asset parameters', () {
      test('adds counter asset parameters for AlphaNum4', () {
        final counterAsset = AssetTypeCreditAlphaNum4('EUR', issuerAccountId);
        final builder = TradeAggregationsRequestBuilder(
          mockClient,
          serverUri,
          baseAsset,
          counterAsset,
          startTime,
          endTime,
          resolution,
          offset,
        );
        final uri = builder.buildUri();

        expect(uri.queryParameters['counter_asset_type'], equals('credit_alphanum4'));
        expect(uri.queryParameters['counter_asset_code'], equals('EUR'));
        expect(uri.queryParameters['counter_asset_issuer'], equals(issuerAccountId));
      });

      test('adds counter asset parameters for AlphaNum12', () {
        final counterAsset = AssetTypeCreditAlphaNum12('COUNTERLONG', issuerAccountId);
        final builder = TradeAggregationsRequestBuilder(
          mockClient,
          serverUri,
          baseAsset,
          counterAsset,
          startTime,
          endTime,
          resolution,
          offset,
        );
        final uri = builder.buildUri();

        expect(uri.queryParameters['counter_asset_type'], equals('credit_alphanum12'));
        expect(uri.queryParameters['counter_asset_code'], equals('COUNTERLONG'));
        expect(uri.queryParameters['counter_asset_issuer'], equals(issuerAccountId));
      });

      test('adds counter asset parameters for native asset', () {
        final counterAsset = Asset.NATIVE;
        final builder = TradeAggregationsRequestBuilder(
          mockClient,
          serverUri,
          baseAsset,
          counterAsset,
          startTime,
          endTime,
          resolution,
          offset,
        );
        final uri = builder.buildUri();

        expect(uri.queryParameters['counter_asset_type'], equals('native'));
        expect(uri.queryParameters.containsKey('counter_asset_code'), isFalse);
        expect(uri.queryParameters.containsKey('counter_asset_issuer'), isFalse);
      });
    });

    group('time and resolution parameters', () {
      test('adds start_time parameter', () {
        final builder = TradeAggregationsRequestBuilder(
          mockClient,
          serverUri,
          baseAsset,
          counterAsset,
          startTime,
          endTime,
          resolution,
          offset,
        );
        final uri = builder.buildUri();

        expect(uri.queryParameters['start_time'], equals(startTime.toString()));
      });

      test('adds end_time parameter', () {
        final builder = TradeAggregationsRequestBuilder(
          mockClient,
          serverUri,
          baseAsset,
          counterAsset,
          startTime,
          endTime,
          resolution,
          offset,
        );
        final uri = builder.buildUri();

        expect(uri.queryParameters['end_time'], equals(endTime.toString()));
      });

      test('adds resolution parameter', () {
        final builder = TradeAggregationsRequestBuilder(
          mockClient,
          serverUri,
          baseAsset,
          counterAsset,
          startTime,
          endTime,
          resolution,
          offset,
        );
        final uri = builder.buildUri();

        expect(uri.queryParameters['resolution'], equals(resolution.toString()));
      });

      test('adds offset parameter', () {
        final builder = TradeAggregationsRequestBuilder(
          mockClient,
          serverUri,
          baseAsset,
          counterAsset,
          startTime,
          endTime,
          resolution,
          offset,
        );
        final uri = builder.buildUri();

        expect(uri.queryParameters['offset'], equals(offset.toString()));
      });

      test('handles 1 minute resolution', () {
        final resolution = 60000; // 1 minute
        final builder = TradeAggregationsRequestBuilder(
          mockClient,
          serverUri,
          baseAsset,
          counterAsset,
          startTime,
          endTime,
          resolution,
          offset,
        );
        final uri = builder.buildUri();

        expect(uri.queryParameters['resolution'], equals('60000'));
      });

      test('handles 5 minute resolution', () {
        final resolution = 300000; // 5 minutes
        final builder = TradeAggregationsRequestBuilder(
          mockClient,
          serverUri,
          baseAsset,
          counterAsset,
          startTime,
          endTime,
          resolution,
          offset,
        );
        final uri = builder.buildUri();

        expect(uri.queryParameters['resolution'], equals('300000'));
      });

      test('handles 15 minute resolution', () {
        final resolution = 900000; // 15 minutes
        final builder = TradeAggregationsRequestBuilder(
          mockClient,
          serverUri,
          baseAsset,
          counterAsset,
          startTime,
          endTime,
          resolution,
          offset,
        );
        final uri = builder.buildUri();

        expect(uri.queryParameters['resolution'], equals('900000'));
      });

      test('handles 1 hour resolution', () {
        final resolution = 3600000; // 1 hour
        final builder = TradeAggregationsRequestBuilder(
          mockClient,
          serverUri,
          baseAsset,
          counterAsset,
          startTime,
          endTime,
          resolution,
          offset,
        );
        final uri = builder.buildUri();

        expect(uri.queryParameters['resolution'], equals('3600000'));
      });

      test('handles 1 day resolution', () {
        final resolution = 86400000; // 1 day
        final builder = TradeAggregationsRequestBuilder(
          mockClient,
          serverUri,
          baseAsset,
          counterAsset,
          startTime,
          endTime,
          resolution,
          offset,
        );
        final uri = builder.buildUri();

        expect(uri.queryParameters['resolution'], equals('86400000'));
      });

      test('handles 1 week resolution', () {
        final resolution = 604800000; // 1 week
        final builder = TradeAggregationsRequestBuilder(
          mockClient,
          serverUri,
          baseAsset,
          counterAsset,
          startTime,
          endTime,
          resolution,
          offset,
        );
        final uri = builder.buildUri();

        expect(uri.queryParameters['resolution'], equals('604800000'));
      });

      test('handles non-zero offset', () {
        final offset = 3600000; // 1 hour offset
        final builder = TradeAggregationsRequestBuilder(
          mockClient,
          serverUri,
          baseAsset,
          counterAsset,
          startTime,
          endTime,
          resolution,
          offset,
        );
        final uri = builder.buildUri();

        expect(uri.queryParameters['offset'], equals('3600000'));
      });

      test('handles large timestamp values', () {
        final startTime = 9999999999999;
        final endTime = 9999999999999;
        final builder = TradeAggregationsRequestBuilder(
          mockClient,
          serverUri,
          baseAsset,
          counterAsset,
          startTime,
          endTime,
          resolution,
          offset,
        );
        final uri = builder.buildUri();

        expect(uri.queryParameters['start_time'], equals('9999999999999'));
        expect(uri.queryParameters['end_time'], equals('9999999999999'));
      });
    });

    group('buildUri with combinations', () {
      test('builds URI with both credit assets', () {
        final baseAsset = AssetTypeCreditAlphaNum4('USD', issuerAccountId);
        final counterAsset = AssetTypeCreditAlphaNum4('EUR', issuerAccountId);
        final builder = TradeAggregationsRequestBuilder(
          mockClient,
          serverUri,
          baseAsset,
          counterAsset,
          startTime,
          endTime,
          resolution,
          offset,
        );
        final uri = builder.buildUri();

        expect(uri.queryParameters['base_asset_type'], equals('credit_alphanum4'));
        expect(uri.queryParameters['base_asset_code'], equals('USD'));
        expect(uri.queryParameters['counter_asset_type'], equals('credit_alphanum4'));
        expect(uri.queryParameters['counter_asset_code'], equals('EUR'));
        expect(uri.queryParameters['start_time'], equals(startTime.toString()));
        expect(uri.queryParameters['end_time'], equals(endTime.toString()));
        expect(uri.queryParameters['resolution'], equals(resolution.toString()));
        expect(uri.queryParameters['offset'], equals(offset.toString()));
      });

      test('builds URI with native base and credit counter', () {
        final baseAsset = Asset.NATIVE;
        final counterAsset = AssetTypeCreditAlphaNum4('USDC', issuerAccountId);
        final builder = TradeAggregationsRequestBuilder(
          mockClient,
          serverUri,
          baseAsset,
          counterAsset,
          startTime,
          endTime,
          resolution,
          offset,
        );
        final uri = builder.buildUri();

        expect(uri.queryParameters['base_asset_type'], equals('native'));
        expect(uri.queryParameters['counter_asset_type'], equals('credit_alphanum4'));
        expect(uri.queryParameters['counter_asset_code'], equals('USDC'));
      });

      test('builds URI with credit base and native counter', () {
        final baseAsset = AssetTypeCreditAlphaNum4('BTC', issuerAccountId);
        final counterAsset = Asset.NATIVE;
        final builder = TradeAggregationsRequestBuilder(
          mockClient,
          serverUri,
          baseAsset,
          counterAsset,
          startTime,
          endTime,
          resolution,
          offset,
        );
        final uri = builder.buildUri();

        expect(uri.queryParameters['base_asset_type'], equals('credit_alphanum4'));
        expect(uri.queryParameters['base_asset_code'], equals('BTC'));
        expect(uri.queryParameters['counter_asset_type'], equals('native'));
      });

      test('builds URI with AlphaNum12 assets', () {
        final baseAsset = AssetTypeCreditAlphaNum12('LONGBASE', issuerAccountId);
        final counterAsset = AssetTypeCreditAlphaNum12('LONGCOUNTER', issuerAccountId);
        final builder = TradeAggregationsRequestBuilder(
          mockClient,
          serverUri,
          baseAsset,
          counterAsset,
          startTime,
          endTime,
          resolution,
          offset,
        );
        final uri = builder.buildUri();

        expect(uri.queryParameters['base_asset_type'], equals('credit_alphanum12'));
        expect(uri.queryParameters['base_asset_code'], equals('LONGBASE'));
        expect(uri.queryParameters['counter_asset_type'], equals('credit_alphanum12'));
        expect(uri.queryParameters['counter_asset_code'], equals('LONGCOUNTER'));
      });

      test('builds URI with all parameters including non-zero offset', () {
        final offset = 1800000; // 30 minutes
        final resolution = 3600000; // 1 hour
        final builder = TradeAggregationsRequestBuilder(
          mockClient,
          serverUri,
          baseAsset,
          counterAsset,
          startTime,
          endTime,
          resolution,
          offset,
        );
        final uri = builder.buildUri();

        expect(uri.queryParameters['base_asset_type'], isNotEmpty);
        expect(uri.queryParameters['counter_asset_type'], isNotEmpty);
        expect(uri.queryParameters['start_time'], equals(startTime.toString()));
        expect(uri.queryParameters['end_time'], equals(endTime.toString()));
        expect(uri.queryParameters['resolution'], equals('3600000'));
        expect(uri.queryParameters['offset'], equals('1800000'));
      });
    });

    group('URI construction edge cases', () {
      test('handles server URI with port', () {
        final uriWithPort = Uri.parse('https://localhost:8000');
        final builder = TradeAggregationsRequestBuilder(
          mockClient,
          uriWithPort,
          baseAsset,
          counterAsset,
          startTime,
          endTime,
          resolution,
          offset,
        );
        final uri = builder.buildUri();

        expect(uri.port, equals(8000));
        expect(uri.host, equals('localhost'));
        expect(uri.pathSegments, contains('trade_aggregations'));
      });

      test('preserves HTTPS scheme', () {
        final builder = TradeAggregationsRequestBuilder(
          mockClient,
          serverUri,
          baseAsset,
          counterAsset,
          startTime,
          endTime,
          resolution,
          offset,
        );
        final uri = builder.buildUri();

        expect(uri.scheme, equals('https'));
      });

      test('handles empty server path', () {
        final simpleUri = Uri.parse('https://horizon.stellar.org');
        final builder = TradeAggregationsRequestBuilder(
          mockClient,
          simpleUri,
          baseAsset,
          counterAsset,
          startTime,
          endTime,
          resolution,
          offset,
        );
        final uri = builder.buildUri();

        expect(uri.scheme, equals('https'));
        expect(uri.host, equals('horizon.stellar.org'));
        expect(uri.pathSegments, contains('trade_aggregations'));
      });

      test('handles zero start time', () {
        final startTime = 0;
        final builder = TradeAggregationsRequestBuilder(
          mockClient,
          serverUri,
          baseAsset,
          counterAsset,
          startTime,
          endTime,
          resolution,
          offset,
        );
        final uri = builder.buildUri();

        expect(uri.queryParameters['start_time'], equals('0'));
      });

      test('handles zero offset', () {
        final offset = 0;
        final builder = TradeAggregationsRequestBuilder(
          mockClient,
          serverUri,
          baseAsset,
          counterAsset,
          startTime,
          endTime,
          resolution,
          offset,
        );
        final uri = builder.buildUri();

        expect(uri.queryParameters['offset'], equals('0'));
      });
    });

    group('parameter validation', () {
      test('accepts same start and end time', () {
        final startTime = 1633024800000;
        final endTime = 1633024800000;
        final builder = TradeAggregationsRequestBuilder(
          mockClient,
          serverUri,
          baseAsset,
          counterAsset,
          startTime,
          endTime,
          resolution,
          offset,
        );
        final uri = builder.buildUri();

        expect(uri.queryParameters['start_time'], equals('1633024800000'));
        expect(uri.queryParameters['end_time'], equals('1633024800000'));
      });

      test('accepts end time before start time', () {
        final startTime = 1633111200000;
        final endTime = 1633024800000;
        final builder = TradeAggregationsRequestBuilder(
          mockClient,
          serverUri,
          baseAsset,
          counterAsset,
          startTime,
          endTime,
          resolution,
          offset,
        );
        final uri = builder.buildUri();

        expect(uri.queryParameters['start_time'], equals('1633111200000'));
        expect(uri.queryParameters['end_time'], equals('1633024800000'));
      });

      test('handles negative offset', () {
        final offset = -3600000;
        final builder = TradeAggregationsRequestBuilder(
          mockClient,
          serverUri,
          baseAsset,
          counterAsset,
          startTime,
          endTime,
          resolution,
          offset,
        );
        final uri = builder.buildUri();

        expect(uri.queryParameters['offset'], equals('-3600000'));
      });

      test('handles custom resolution value', () {
        final resolution = 7200000; // 2 hours
        final builder = TradeAggregationsRequestBuilder(
          mockClient,
          serverUri,
          baseAsset,
          counterAsset,
          startTime,
          endTime,
          resolution,
          offset,
        );
        final uri = builder.buildUri();

        expect(uri.queryParameters['resolution'], equals('7200000'));
      });
    });
  });
}
