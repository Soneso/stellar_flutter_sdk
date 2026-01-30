import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('HealthRequestBuilder', () {
    late http.Client mockClient;
    late Uri serverUri;

    setUp(() {
      mockClient = MockClient((request) async {
        return http.Response('''
        {
          "database_connected": true,
          "core_up": true,
          "core_synced": true
        }
        ''', 200);
      });
      serverUri = Uri.parse('https://horizon-testnet.stellar.org');
    });

    group('constructor', () {
      test('creates builder with health segment', () {
        final builder = HealthRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('health'));
      });

      test('uses provided HTTP client', () {
        final builder = HealthRequestBuilder(mockClient, serverUri);

        expect(builder.httpClient, same(mockClient));
      });

      test('uses provided server URI', () {
        final builder = HealthRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.host, equals('horizon-testnet.stellar.org'));
        expect(uri.scheme, equals('https'));
      });

      test('builds correct path', () {
        final builder = HealthRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.path, contains('health'));
      });
    });

    group('buildUri', () {
      test('builds URI with health endpoint', () {
        final builder = HealthRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('health'));
        expect(uri.pathSegments.length, greaterThanOrEqualTo(1));
      });

      test('builds URI with no query parameters', () {
        final builder = HealthRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.queryParameters.isEmpty, isTrue);
      });

      test('builds URI with HTTPS scheme', () {
        final builder = HealthRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.scheme, equals('https'));
      });

      test('builds URI with correct host', () {
        final builder = HealthRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.host, equals('horizon-testnet.stellar.org'));
      });

      test('handles server URI with port', () {
        final uriWithPort = Uri.parse('https://localhost:8000');
        final builder = HealthRequestBuilder(mockClient, uriWithPort);
        final uri = builder.buildUri();

        expect(uri.port, equals(8000));
        expect(uri.host, equals('localhost'));
        expect(uri.pathSegments, contains('health'));
      });

      test('handles server URI with existing path', () {
        final uriWithPath = Uri.parse('https://horizon-testnet.stellar.org/api/v1');
        final builder = HealthRequestBuilder(mockClient, uriWithPath);
        final uri = builder.buildUri();

        expect(uri.pathSegments.contains('api'), isTrue);
        expect(uri.pathSegments.contains('v1'), isTrue);
        expect(uri.pathSegments.contains('health'), isTrue);
      });
    });

    group('URI construction edge cases', () {
      test('handles empty server path', () {
        final simpleUri = Uri.parse('https://horizon.stellar.org');
        final builder = HealthRequestBuilder(mockClient, simpleUri);
        final uri = builder.buildUri();

        expect(uri.scheme, equals('https'));
        expect(uri.host, equals('horizon.stellar.org'));
        expect(uri.pathSegments, contains('health'));
      });

      test('preserves HTTPS scheme', () {
        final builder = HealthRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.scheme, equals('https'));
      });

      test('handles localhost URI', () {
        final localUri = Uri.parse('http://localhost:8000');
        final builder = HealthRequestBuilder(mockClient, localUri);
        final uri = builder.buildUri();

        expect(uri.host, equals('localhost'));
        expect(uri.port, equals(8000));
        expect(uri.pathSegments, contains('health'));
      });

      test('handles IP address URI', () {
        final ipUri = Uri.parse('https://192.168.1.1:8000');
        final builder = HealthRequestBuilder(mockClient, ipUri);
        final uri = builder.buildUri();

        expect(uri.host, equals('192.168.1.1'));
        expect(uri.port, equals(8000));
        expect(uri.pathSegments, contains('health'));
      });

      test('handles URI with subdomain', () {
        final subdomainUri = Uri.parse('https://testnet.horizon.stellar.org');
        final builder = HealthRequestBuilder(mockClient, subdomainUri);
        final uri = builder.buildUri();

        expect(uri.host, equals('testnet.horizon.stellar.org'));
        expect(uri.pathSegments, contains('health'));
      });

      test('handles URI with multiple path segments', () {
        final multiPathUri = Uri.parse('https://horizon.stellar.org/api/v2/public');
        final builder = HealthRequestBuilder(mockClient, multiPathUri);
        final uri = builder.buildUri();

        expect(uri.pathSegments.contains('api'), isTrue);
        expect(uri.pathSegments.contains('v2'), isTrue);
        expect(uri.pathSegments.contains('public'), isTrue);
        expect(uri.pathSegments.contains('health'), isTrue);
      });

      test('handles HTTP scheme', () {
        final httpUri = Uri.parse('http://localhost:8000');
        final builder = HealthRequestBuilder(mockClient, httpUri);
        final uri = builder.buildUri();

        expect(uri.scheme, equals('http'));
        expect(uri.pathSegments, contains('health'));
      });
    });

    group('builder behavior', () {
      test('can be instantiated multiple times with same client', () {
        final builder1 = HealthRequestBuilder(mockClient, serverUri);
        final builder2 = HealthRequestBuilder(mockClient, serverUri);

        expect(builder1.httpClient, same(mockClient));
        expect(builder2.httpClient, same(mockClient));
        expect(builder1.httpClient, same(builder2.httpClient));
      });

      test('can be instantiated with different URIs', () {
        final uri1 = Uri.parse('https://horizon.stellar.org');
        final uri2 = Uri.parse('https://horizon-testnet.stellar.org');

        final builder1 = HealthRequestBuilder(mockClient, uri1);
        final builder2 = HealthRequestBuilder(mockClient, uri2);

        final builtUri1 = builder1.buildUri();
        final builtUri2 = builder2.buildUri();

        expect(builtUri1.host, equals('horizon.stellar.org'));
        expect(builtUri2.host, equals('horizon-testnet.stellar.org'));
      });

      test('buildUri returns consistent results', () {
        final builder = HealthRequestBuilder(mockClient, serverUri);
        final uri1 = builder.buildUri();
        final uri2 = builder.buildUri();

        expect(uri1.toString(), equals(uri2.toString()));
      });

      test('buildUri creates new URI instance each time', () {
        final builder = HealthRequestBuilder(mockClient, serverUri);
        final uri1 = builder.buildUri();
        final uri2 = builder.buildUri();

        expect(identical(uri1, uri2), isFalse);
        expect(uri1.toString(), equals(uri2.toString()));
      });
    });

    group('HTTP client usage', () {
      test('uses MockClient for testing', () {
        final builder = HealthRequestBuilder(mockClient, serverUri);

        expect(builder.httpClient, isA<MockClient>());
      });

      test('preserves client reference', () {
        final builder = HealthRequestBuilder(mockClient, serverUri);

        expect(builder.httpClient, same(mockClient));
        expect(identical(builder.httpClient, mockClient), isTrue);
      });
    });

    group('integration with RequestBuilder base class', () {
      test('inherits from RequestBuilder', () {
        final builder = HealthRequestBuilder(mockClient, serverUri);

        expect(builder, isA<RequestBuilder>());
      });

      test('can access httpClient property', () {
        final builder = HealthRequestBuilder(mockClient, serverUri);

        expect(builder.httpClient, isNotNull);
        expect(builder.httpClient, same(mockClient));
      });

      test('can call buildUri method', () {
        final builder = HealthRequestBuilder(mockClient, serverUri);

        expect(() => builder.buildUri(), returnsNormally);
      });
    });

    group('URI format validation', () {
      test('produces valid URI string', () {
        final builder = HealthRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.toString(), isNotEmpty);
        expect(uri.toString(), contains('horizon-testnet.stellar.org'));
        expect(uri.toString(), contains('health'));
      });

      test('produces parseable URI', () {
        final builder = HealthRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();
        final uriString = uri.toString();

        expect(() => Uri.parse(uriString), returnsNormally);
        final reparsed = Uri.parse(uriString);
        expect(reparsed.host, equals(uri.host));
        expect(reparsed.path, equals(uri.path));
      });

      test('produces absolute URI', () {
        final builder = HealthRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.isAbsolute, isTrue);
        expect(uri.hasScheme, isTrue);
        expect(uri.hasAuthority, isTrue);
      });
    });

    group('public vs testnet network', () {
      test('works with public network URI', () {
        final publicUri = Uri.parse('https://horizon.stellar.org');
        final builder = HealthRequestBuilder(mockClient, publicUri);
        final uri = builder.buildUri();

        expect(uri.host, equals('horizon.stellar.org'));
        expect(uri.pathSegments, contains('health'));
      });

      test('works with testnet network URI', () {
        final testnetUri = Uri.parse('https://horizon-testnet.stellar.org');
        final builder = HealthRequestBuilder(mockClient, testnetUri);
        final uri = builder.buildUri();

        expect(uri.host, equals('horizon-testnet.stellar.org'));
        expect(uri.pathSegments, contains('health'));
      });

      test('works with futurenet network URI', () {
        final futurenetUri = Uri.parse('https://horizon-futurenet.stellar.org');
        final builder = HealthRequestBuilder(mockClient, futurenetUri);
        final uri = builder.buildUri();

        expect(uri.host, equals('horizon-futurenet.stellar.org'));
        expect(uri.pathSegments, contains('health'));
      });

      test('works with custom horizon URI', () {
        final customUri = Uri.parse('https://custom-horizon.example.com');
        final builder = HealthRequestBuilder(mockClient, customUri);
        final uri = builder.buildUri();

        expect(uri.host, equals('custom-horizon.example.com'));
        expect(uri.pathSegments, contains('health'));
      });
    });

    group('path construction', () {
      test('appends health to empty path', () {
        final simpleUri = Uri.parse('https://horizon.stellar.org');
        final builder = HealthRequestBuilder(mockClient, simpleUri);
        final uri = builder.buildUri();

        expect(uri.pathSegments, equals(['health']));
      });

      test('appends health to existing path', () {
        final pathUri = Uri.parse('https://horizon.stellar.org/api');
        final builder = HealthRequestBuilder(mockClient, pathUri);
        final uri = builder.buildUri();

        expect(uri.pathSegments.contains('api'), isTrue);
        expect(uri.pathSegments.contains('health'), isTrue);
        expect(uri.pathSegments.indexOf('health'), greaterThan(uri.pathSegments.indexOf('api')));
      });

      test('preserves trailing slash behavior', () {
        final builder = HealthRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.path, isNotEmpty);
        expect(uri.pathSegments, contains('health'));
      });
    });
  });
}
