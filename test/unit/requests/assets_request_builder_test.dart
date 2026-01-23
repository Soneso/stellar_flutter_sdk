import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('AssetsRequestBuilder', () {
    late http.Client mockClient;
    late Uri serverUri;

    setUp(() {
      mockClient = MockClient((request) async {
        return http.Response('{"_embedded": {"records": []}}', 200);
      });
      serverUri = Uri.parse('https://horizon-testnet.stellar.org');
    });

    group('constructor', () {
      test('creates builder with assets segment', () {
        final builder = AssetsRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('assets'));
      });

      test('uses provided HTTP client', () {
        final builder = AssetsRequestBuilder(mockClient, serverUri);

        expect(builder.httpClient, same(mockClient));
      });

      test('uses provided server URI', () {
        final builder = AssetsRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.host, equals('horizon-testnet.stellar.org'));
        expect(uri.scheme, equals('https'));
      });
    });

    group('assetCode', () {
      test('adds asset_code query parameter', () {
        final builder = AssetsRequestBuilder(mockClient, serverUri);
        builder.assetCode('USD');
        final uri = builder.buildUri();

        expect(uri.queryParameters['asset_code'], equals('USD'));
      });

      test('returns builder for method chaining', () {
        final builder = AssetsRequestBuilder(mockClient, serverUri);
        final result = builder.assetCode('EUR');

        expect(result, same(builder));
      });

      test('handles short asset codes', () {
        final builder = AssetsRequestBuilder(mockClient, serverUri);
        builder.assetCode('XLM');
        final uri = builder.buildUri();

        expect(uri.queryParameters['asset_code'], equals('XLM'));
      });

      test('handles long asset codes', () {
        final builder = AssetsRequestBuilder(mockClient, serverUri);
        builder.assetCode('LONGASSETCD');
        final uri = builder.buildUri();

        expect(uri.queryParameters['asset_code'], equals('LONGASSETCD'));
      });

      test('can be combined with limit and order', () {
        final builder = AssetsRequestBuilder(mockClient, serverUri);
        builder
          ..assetCode('BTC')
          ..limit(10)
          ..order(RequestBuilderOrder.DESC);
        final uri = builder.buildUri();

        expect(uri.queryParameters['asset_code'], equals('BTC'));
        expect(uri.queryParameters['limit'], equals('10'));
        expect(uri.queryParameters['order'], equals('desc'));
      });
    });

    group('assetIssuer', () {
      final issuerAccountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';

      test('adds asset_issuer query parameter', () {
        final builder = AssetsRequestBuilder(mockClient, serverUri);
        builder.assetIssuer(issuerAccountId);
        final uri = builder.buildUri();

        expect(uri.queryParameters['asset_issuer'], equals(issuerAccountId));
      });

      test('returns builder for method chaining', () {
        final builder = AssetsRequestBuilder(mockClient, serverUri);
        final result = builder.assetIssuer(issuerAccountId);

        expect(result, same(builder));
      });

      test('can be combined with assetCode', () {
        final builder = AssetsRequestBuilder(mockClient, serverUri);
        builder
          ..assetCode('USD')
          ..assetIssuer(issuerAccountId);
        final uri = builder.buildUri();

        expect(uri.queryParameters['asset_code'], equals('USD'));
        expect(uri.queryParameters['asset_issuer'], equals(issuerAccountId));
      });

      test('can be combined with limit and order', () {
        final builder = AssetsRequestBuilder(mockClient, serverUri);
        builder
          ..assetIssuer(issuerAccountId)
          ..limit(20)
          ..order(RequestBuilderOrder.ASC);
        final uri = builder.buildUri();

        expect(uri.queryParameters['asset_issuer'], equals(issuerAccountId));
        expect(uri.queryParameters['limit'], equals('20'));
        expect(uri.queryParameters['order'], equals('asc'));
      });
    });

    group('cursor, limit, and order', () {
      test('cursor returns AssetsRequestBuilder', () {
        final builder = AssetsRequestBuilder(mockClient, serverUri);
        final result = builder.cursor('12345');

        expect(result, isA<AssetsRequestBuilder>());
        expect(result, same(builder));
      });

      test('limit returns AssetsRequestBuilder', () {
        final builder = AssetsRequestBuilder(mockClient, serverUri);
        final result = builder.limit(10);

        expect(result, isA<AssetsRequestBuilder>());
        expect(result, same(builder));
      });

      test('order returns AssetsRequestBuilder', () {
        final builder = AssetsRequestBuilder(mockClient, serverUri);
        final result = builder.order(RequestBuilderOrder.ASC);

        expect(result, isA<AssetsRequestBuilder>());
        expect(result, same(builder));
      });

      test('supports full method chaining', () {
        final builder = AssetsRequestBuilder(mockClient, serverUri);

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

      test('builds URI with assetCode and pagination', () {
        final builder = AssetsRequestBuilder(mockClient, serverUri);
        builder
          ..assetCode('USD')
          ..cursor('12345')
          ..limit(50);
        final uri = builder.buildUri();

        expect(uri.queryParameters['asset_code'], equals('USD'));
        expect(uri.queryParameters['cursor'], equals('12345'));
        expect(uri.queryParameters['limit'], equals('50'));
      });

      test('builds URI with assetIssuer and sorting', () {
        final builder = AssetsRequestBuilder(mockClient, serverUri);
        builder
          ..assetIssuer(issuerAccountId)
          ..order(RequestBuilderOrder.DESC)
          ..limit(20);
        final uri = builder.buildUri();

        expect(uri.queryParameters['asset_issuer'], equals(issuerAccountId));
        expect(uri.queryParameters['order'], equals('desc'));
        expect(uri.queryParameters['limit'], equals('20'));
      });

      test('builds URI with assetCode and assetIssuer', () {
        final builder = AssetsRequestBuilder(mockClient, serverUri);
        builder
          ..assetCode('EUR')
          ..assetIssuer(issuerAccountId)
          ..limit(10);
        final uri = builder.buildUri();

        expect(uri.queryParameters['asset_code'], equals('EUR'));
        expect(uri.queryParameters['asset_issuer'], equals(issuerAccountId));
        expect(uri.queryParameters['limit'], equals('10'));
      });

      test('builds URI with all parameters', () {
        final builder = AssetsRequestBuilder(mockClient, serverUri);
        builder
          ..assetCode('BTC')
          ..assetIssuer(issuerAccountId)
          ..cursor('67890')
          ..limit(30)
          ..order(RequestBuilderOrder.ASC);
        final uri = builder.buildUri();

        expect(uri.queryParameters['asset_code'], equals('BTC'));
        expect(uri.queryParameters['asset_issuer'], equals(issuerAccountId));
        expect(uri.queryParameters['cursor'], equals('67890'));
        expect(uri.queryParameters['limit'], equals('30'));
        expect(uri.queryParameters['order'], equals('asc'));
      });
    });

    group('URI construction edge cases', () {
      test('handles empty server path', () {
        final simpleUri = Uri.parse('https://horizon.stellar.org');
        final builder = AssetsRequestBuilder(mockClient, simpleUri);
        final uri = builder.buildUri();

        expect(uri.scheme, equals('https'));
        expect(uri.host, equals('horizon.stellar.org'));
        expect(uri.pathSegments, contains('assets'));
      });

      test('handles server URI with port', () {
        final uriWithPort = Uri.parse('https://localhost:8000');
        final builder = AssetsRequestBuilder(mockClient, uriWithPort);
        final uri = builder.buildUri();

        expect(uri.port, equals(8000));
        expect(uri.host, equals('localhost'));
        expect(uri.pathSegments, contains('assets'));
      });

      test('preserves HTTPS scheme', () {
        final builder = AssetsRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.scheme, equals('https'));
      });

      test('handles assets with no additional parameters', () {
        final builder = AssetsRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('assets'));
        expect(uri.queryParameters, isEmpty);
      });
    });

    group('parameter validation', () {
      test('assetCode with empty string', () {
        final builder = AssetsRequestBuilder(mockClient, serverUri);
        builder.assetCode('');
        final uri = builder.buildUri();

        expect(uri.queryParameters['asset_code'], equals(''));
      });

      test('assetIssuer with empty string', () {
        final builder = AssetsRequestBuilder(mockClient, serverUri);
        builder.assetIssuer('');
        final uri = builder.buildUri();

        expect(uri.queryParameters['asset_issuer'], equals(''));
      });

      test('limit with zero value', () {
        final builder = AssetsRequestBuilder(mockClient, serverUri);
        builder.limit(0);
        final uri = builder.buildUri();

        expect(uri.queryParameters['limit'], equals('0'));
      });

      test('limit with large value', () {
        final builder = AssetsRequestBuilder(mockClient, serverUri);
        builder.limit(1000);
        final uri = builder.buildUri();

        expect(uri.queryParameters['limit'], equals('1000'));
      });
    });
  });
}
