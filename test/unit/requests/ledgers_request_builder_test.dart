import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('LedgersRequestBuilder', () {
    late http.Client mockClient;
    late Uri serverUri;

    setUp(() {
      mockClient = MockClient((request) async {
        return http.Response('{"_embedded": {"records": []}}', 200);
      });
      serverUri = Uri.parse('https://horizon-testnet.stellar.org');
    });

    group('constructor', () {
      test('creates builder with ledgers segment', () {
        final builder = LedgersRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('ledgers'));
      });

      test('uses provided HTTP client', () {
        final builder = LedgersRequestBuilder(mockClient, serverUri);

        expect(builder.httpClient, same(mockClient));
      });

      test('uses provided server URI', () {
        final builder = LedgersRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.host, equals('horizon-testnet.stellar.org'));
        expect(uri.scheme, equals('https'));
      });
    });

    group('ledger', () {
      test('builds URI for specific ledger sequence', () {
        final builder = LedgersRequestBuilder(mockClient, serverUri);
        builder.setSegments(['ledgers', '12345']);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('ledgers'));
        expect(uri.pathSegments, contains('12345'));
      });

      test('path segments are in correct order', () {
        final builder = LedgersRequestBuilder(mockClient, serverUri);
        builder.setSegments(['ledgers', '67890']);
        final uri = builder.buildUri();

        final segments = uri.pathSegments;
        final ledgersIndex = segments.indexOf('ledgers');
        expect(segments[ledgersIndex + 1], equals('67890'));
      });

      test('handles large ledger sequence numbers', () {
        final builder = LedgersRequestBuilder(mockClient, serverUri);
        builder.setSegments(['ledgers', '999999999']);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('999999999'));
      });

      test('handles small ledger sequence numbers', () {
        final builder = LedgersRequestBuilder(mockClient, serverUri);
        builder.setSegments(['ledgers', '1']);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('1'));
      });
    });

    group('cursor, limit, and order', () {
      test('cursor returns LedgersRequestBuilder', () {
        final builder = LedgersRequestBuilder(mockClient, serverUri);
        final result = builder.cursor('12345');

        expect(result, isA<LedgersRequestBuilder>());
        expect(result, same(builder));
      });

      test('limit returns LedgersRequestBuilder', () {
        final builder = LedgersRequestBuilder(mockClient, serverUri);
        final result = builder.limit(10);

        expect(result, isA<LedgersRequestBuilder>());
        expect(result, same(builder));
      });

      test('order returns LedgersRequestBuilder', () {
        final builder = LedgersRequestBuilder(mockClient, serverUri);
        final result = builder.order(RequestBuilderOrder.ASC);

        expect(result, isA<LedgersRequestBuilder>());
        expect(result, same(builder));
      });

      test('supports full method chaining', () {
        final builder = LedgersRequestBuilder(mockClient, serverUri);

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
      test('builds URI with cursor and limit', () {
        final builder = LedgersRequestBuilder(mockClient, serverUri);
        builder
          ..cursor('12345')
          ..limit(50);
        final uri = builder.buildUri();

        expect(uri.queryParameters['cursor'], equals('12345'));
        expect(uri.queryParameters['limit'], equals('50'));
      });

      test('builds URI with limit and order', () {
        final builder = LedgersRequestBuilder(mockClient, serverUri);
        builder
          ..limit(20)
          ..order(RequestBuilderOrder.DESC);
        final uri = builder.buildUri();

        expect(uri.queryParameters['limit'], equals('20'));
        expect(uri.queryParameters['order'], equals('desc'));
      });

      test('builds URI with all parameters', () {
        final builder = LedgersRequestBuilder(mockClient, serverUri);
        builder
          ..cursor('67890')
          ..limit(30)
          ..order(RequestBuilderOrder.ASC);
        final uri = builder.buildUri();

        expect(uri.queryParameters['cursor'], equals('67890'));
        expect(uri.queryParameters['limit'], equals('30'));
        expect(uri.queryParameters['order'], equals('asc'));
      });

      test('builds URI with descending order', () {
        final builder = LedgersRequestBuilder(mockClient, serverUri);
        builder
          ..order(RequestBuilderOrder.DESC)
          ..limit(10);
        final uri = builder.buildUri();

        expect(uri.queryParameters['order'], equals('desc'));
        expect(uri.queryParameters['limit'], equals('10'));
      });
    });

    group('URI construction edge cases', () {
      test('handles empty server path', () {
        final simpleUri = Uri.parse('https://horizon.stellar.org');
        final builder = LedgersRequestBuilder(mockClient, simpleUri);
        final uri = builder.buildUri();

        expect(uri.scheme, equals('https'));
        expect(uri.host, equals('horizon.stellar.org'));
        expect(uri.pathSegments, contains('ledgers'));
      });

      test('handles server URI with port', () {
        final uriWithPort = Uri.parse('https://localhost:8000');
        final builder = LedgersRequestBuilder(mockClient, uriWithPort);
        final uri = builder.buildUri();

        expect(uri.port, equals(8000));
        expect(uri.host, equals('localhost'));
        expect(uri.pathSegments, contains('ledgers'));
      });

      test('preserves HTTPS scheme', () {
        final builder = LedgersRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.scheme, equals('https'));
      });

      test('handles ledger with no additional parameters', () {
        final builder = LedgersRequestBuilder(mockClient, serverUri);
        builder.setSegments(['ledgers', '12345']);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('12345'));
        expect(uri.queryParameters, isEmpty);
      });
    });

    group('parameter validation', () {
      test('cursor with now value', () {
        final builder = LedgersRequestBuilder(mockClient, serverUri);
        builder.cursor('now');
        final uri = builder.buildUri();

        expect(uri.queryParameters['cursor'], equals('now'));
      });

      test('limit with zero value', () {
        final builder = LedgersRequestBuilder(mockClient, serverUri);
        builder.limit(0);
        final uri = builder.buildUri();

        expect(uri.queryParameters['limit'], equals('0'));
      });

      test('limit with large value', () {
        final builder = LedgersRequestBuilder(mockClient, serverUri);
        builder.limit(1000);
        final uri = builder.buildUri();

        expect(uri.queryParameters['limit'], equals('1000'));
      });

      test('cursor with special characters gets encoded', () {
        final builder = LedgersRequestBuilder(mockClient, serverUri);
        builder.cursor('cursor+with/special=chars');
        final uri = builder.buildUri();

        expect(uri.queryParameters['cursor'], equals('cursor+with/special=chars'));
      });
    });
  });
}
