import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('RequestBuilder', () {
    late http.Client mockClient;
    late Uri serverUri;

    setUp(() {
      mockClient = MockClient((request) async {
        return http.Response('{"_embedded": {"records": []}}', 200);
      });
      serverUri = Uri.parse('https://horizon-testnet.stellar.org');
    });

    group('constructor and initialization', () {
      test('creates builder with default segments', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.toString(), contains('accounts'));
      });

      test('creates builder without default segments', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.host, equals('horizon-testnet.stellar.org'));
        expect(uri.scheme, equals('https'));
      });
    });

    group('setSegments', () {
      test('sets custom URL segments', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        builder.setSegments(['accounts', 'GABC123']);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('accounts'));
        expect(uri.pathSegments, contains('GABC123'));
      });

      test('throws exception when segments already added', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        builder.setSegments(['accounts', 'test1']);

        expect(
          () => builder.setSegments(['accounts', 'test2']),
          throwsA(isA<Exception>()),
        );
      });

      test('replaces default segments with custom segments', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        builder.setSegments(['transactions']);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('transactions'));
        expect(uri.pathSegments.where((s) => s == 'accounts').length, equals(0));
      });
    });

    group('cursor parameter', () {
      test('adds cursor parameter to query string', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        builder.cursor('12345-67890');
        final uri = builder.buildUri();

        expect(uri.queryParameters['cursor'], equals('12345-67890'));
      });

      test('adds cursor with special characters', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        builder.cursor('now');
        final uri = builder.buildUri();

        expect(uri.queryParameters['cursor'], equals('now'));
      });

      test('cursor parameter is URL encoded', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        builder.cursor('test cursor');
        final uri = builder.buildUri();

        expect(uri.toString(), contains('cursor'));
      });
    });

    group('limit parameter', () {
      test('adds limit parameter to query string', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        builder.limit(10);
        final uri = builder.buildUri();

        expect(uri.queryParameters['limit'], equals('10'));
      });

      test('accepts limit of 1', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        builder.limit(1);
        final uri = builder.buildUri();

        expect(uri.queryParameters['limit'], equals('1'));
      });

      test('accepts limit of 200', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        builder.limit(200);
        final uri = builder.buildUri();

        expect(uri.queryParameters['limit'], equals('200'));
      });

      test('limit overwrites previous value', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        builder.limit(10);
        builder.limit(20);
        final uri = builder.buildUri();

        expect(uri.queryParameters['limit'], equals('20'));
      });
    });

    group('order parameter', () {
      test('adds ascending order parameter', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        builder.order(RequestBuilderOrder.ASC);
        final uri = builder.buildUri();

        expect(uri.queryParameters['order'], equals('asc'));
      });

      test('adds descending order parameter', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        builder.order(RequestBuilderOrder.DESC);
        final uri = builder.buildUri();

        expect(uri.queryParameters['order'], equals('desc'));
      });

      test('order overwrites previous value', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        builder.order(RequestBuilderOrder.ASC);
        builder.order(RequestBuilderOrder.DESC);
        final uri = builder.buildUri();

        expect(uri.queryParameters['order'], equals('desc'));
      });
    });

    group('buildUri', () {
      test('builds URI with no parameters', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.scheme, equals('https'));
        expect(uri.host, equals('horizon-testnet.stellar.org'));
        expect(uri.pathSegments, contains('accounts'));
      });

      test('builds URI with all common parameters', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        builder
          ..cursor('12345')
          ..limit(50)
          ..order(RequestBuilderOrder.DESC);
        final uri = builder.buildUri();

        expect(uri.queryParameters['cursor'], equals('12345'));
        expect(uri.queryParameters['limit'], equals('50'));
        expect(uri.queryParameters['order'], equals('desc'));
      });

      test('builds URI preserving existing path segments', () {
        final serverWithPath = Uri.parse('https://horizon-testnet.stellar.org/api/v1');
        final builder = AccountsRequestBuilder(mockClient, serverWithPath);
        final uri = builder.buildUri();

        expect(uri.pathSegments.contains('api'), isTrue);
        expect(uri.pathSegments.contains('v1'), isTrue);
        expect(uri.pathSegments.contains('accounts'), isTrue);
      });

      test('builds URI preserving existing query parameters', () {
        final serverWithQuery = Uri.parse('https://horizon-testnet.stellar.org?existing=value');
        final builder = AccountsRequestBuilder(mockClient, serverWithQuery);
        builder.limit(10);
        final uri = builder.buildUri();

        expect(uri.queryParameters['existing'], equals('value'));
        expect(uri.queryParameters['limit'], equals('10'));
      });
    });

    group('encodeAsset', () {
      test('encodes native asset', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        final encoded = builder.encodeAsset(Asset.NATIVE);

        expect(encoded, equals('native'));
      });

      test('encodes credit alphanum4 asset', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        final asset = AssetTypeCreditAlphaNum4(
          'USD',
          'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX',
        );
        final encoded = builder.encodeAsset(asset);

        expect(encoded, equals('USD:GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX'));
        expect(encoded, contains(':'));
      });

      test('encodes credit alphanum12 asset', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        final asset = AssetTypeCreditAlphaNum12(
          'LONGASSET',
          'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX',
        );
        final encoded = builder.encodeAsset(asset);

        expect(encoded, equals('LONGASSET:GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX'));
      });

      test('throws exception for unsupported asset type', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        final poolShare = AssetTypePoolShare(
          assetA: Asset.NATIVE,
          assetB: AssetTypeCreditAlphaNum4('USD', 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX'),
        );

        expect(
          () => builder.encodeAsset(poolShare),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('encodeAssets', () {
      test('encodes empty asset list', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        final encoded = builder.encodeAssets([]);

        expect(encoded, equals(''));
      });

      test('encodes single asset', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        final encoded = builder.encodeAssets([Asset.NATIVE]);

        expect(encoded, equals('native'));
      });

      test('encodes multiple assets with comma separator', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        final assets = [
          Asset.NATIVE,
          AssetTypeCreditAlphaNum4('USD', 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX'),
          AssetTypeCreditAlphaNum12('LONGASSET', 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX'),
        ];
        final encoded = builder.encodeAssets(assets);

        expect(encoded, contains('native'));
        expect(encoded, contains('USD:'));
        expect(encoded, contains('LONGASSET:'));
        expect(encoded, contains(','));
        expect(encoded.split(',').length, equals(3));
      });
    });

    group('method chaining', () {
      test('supports chaining cursor, limit, and order', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        final result = builder
          ..cursor('12345')
          ..limit(50)
          ..order(RequestBuilderOrder.DESC);

        expect(result, same(builder));
        final uri = builder.buildUri();
        expect(uri.queryParameters['cursor'], equals('12345'));
        expect(uri.queryParameters['limit'], equals('50'));
        expect(uri.queryParameters['order'], equals('desc'));
      });

      test('chaining returns same builder instance', () {
        final builder = AccountsRequestBuilder(mockClient, serverUri);
        final result1 = builder.cursor('test');
        final result2 = result1.limit(10);
        final result3 = result2.order(RequestBuilderOrder.ASC);

        expect(result1, same(builder));
        expect(result2, same(builder));
        expect(result3, same(builder));
      });
    });

    group('RequestBuilderOrder', () {
      test('ASC has correct value', () {
        expect(RequestBuilderOrder.ASC.value, equals('asc'));
      });

      test('DESC has correct value', () {
        expect(RequestBuilderOrder.DESC.value, equals('desc'));
      });

      test('toString returns descriptive string', () {
        expect(RequestBuilderOrder.ASC.toString(), contains('asc'));
        expect(RequestBuilderOrder.DESC.toString(), contains('desc'));
      });

      test('constants are singleton instances', () {
        expect(RequestBuilderOrder.ASC, same(RequestBuilderOrder.ASC));
        expect(RequestBuilderOrder.DESC, same(RequestBuilderOrder.DESC));
      });
    });

    group('headers', () {
      test('includes X-Client-Name header', () {
        expect(RequestBuilder.headers['X-Client-Name'], equals('stellar_flutter_sdk'));
      });

      test('includes X-Client-Version header', () {
        expect(RequestBuilder.headers['X-Client-Version'], isNotNull);
        expect(RequestBuilder.headers['X-Client-Version'], equals(StellarSDK.versionNumber));
      });

      test('headers are unmodifiable', () {
        expect(
          () => RequestBuilder.headers['test'] = 'value',
          throwsA(isA<UnsupportedError>()),
        );
      });
    });
  });

  group('ResponseHandler', () {
    test('throws TooManyRequestsException on 429 status', () {
      final handler = ResponseHandler<AccountResponse>(
        TypeToken<AccountResponse>(),
      );
      final response = http.Response('', 429);

      expect(
        () => handler.handleResponse(response),
        throwsA(isA<TooManyRequestsException>()),
      );
    });

    test('throws TooManyRequestsException with retry-after header', () {
      final handler = ResponseHandler<AccountResponse>(
        TypeToken<AccountResponse>(),
      );
      final response = http.Response('', 429, headers: {'retry-after': '60'});

      try {
        handler.handleResponse(response);
        fail('Expected TooManyRequestsException');
      } catch (e) {
        expect(e, isA<TooManyRequestsException>());
        expect((e as TooManyRequestsException).retryAfter, equals(60));
      }
    });

    test('throws ErrorResponse on 400 status', () {
      final handler = ResponseHandler<AccountResponse>(
        TypeToken<AccountResponse>(),
      );
      final response = http.Response('{"error": "bad request"}', 400);

      expect(
        () => handler.handleResponse(response),
        throwsA(isA<ErrorResponse>()),
      );
    });

    test('throws ErrorResponse on 404 status', () {
      final handler = ResponseHandler<AccountResponse>(
        TypeToken<AccountResponse>(),
      );
      final response = http.Response('{"error": "not found"}', 404);

      expect(
        () => handler.handleResponse(response),
        throwsA(isA<ErrorResponse>()),
      );
    });

    test('throws ErrorResponse on 500 status', () {
      final handler = ResponseHandler<AccountResponse>(
        TypeToken<AccountResponse>(),
      );
      final response = http.Response('{"error": "internal error"}', 500);

      expect(
        () => handler.handleResponse(response),
        throwsA(isA<ErrorResponse>()),
      );
    });
  });

  group('ErrorResponse', () {
    test('extracts status code from response', () {
      final response = http.Response('error', 404);
      final error = ErrorResponse(response);

      expect(error.code, equals(404));
    });

    test('extracts body from response', () {
      final response = http.Response('error message', 400);
      final error = ErrorResponse(response);

      expect(error.body, equals('error message'));
    });

    test('toString includes code and body', () {
      final response = http.Response('test error', 500);
      final error = ErrorResponse(response);
      final errorString = error.toString();

      expect(errorString, contains('500'));
      expect(errorString, contains('test error'));
    });
  });

  group('TooManyRequestsException', () {
    test('creates exception with retry-after value', () {
      final exception = TooManyRequestsException(60);

      expect(exception.retryAfter, equals(60));
    });

    test('creates exception with null retry-after', () {
      final exception = TooManyRequestsException(null);

      expect(exception.retryAfter, isNull);
    });

    test('toString returns descriptive message', () {
      final exception = TooManyRequestsException(30);
      final message = exception.toString();

      expect(message, contains('rate limit'));
    });
  });
}
