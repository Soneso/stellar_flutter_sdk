import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('Response Utility Functions', () {
    test('convertInt handles int value', () {
      expect(convertInt(42), equals(42));
    });

    test('convertInt handles String value', () {
      expect(convertInt('100'), equals(100));
    });

    test('convertInt handles null value', () {
      expect(convertInt(null), isNull);
    });

    test('convertInt throws on invalid string', () {
      expect(() => convertInt('not a number'), throwsException);
    });

    test('convertInt throws on invalid type', () {
      expect(() => convertInt(12.5), throwsException);
    });

    test('convertInt handles zero', () {
      expect(convertInt(0), equals(0));
      expect(convertInt('0'), equals(0));
    });

    test('convertInt handles negative numbers', () {
      expect(convertInt(-42), equals(-42));
      expect(convertInt('-100'), equals(-100));
    });

    test('convertInt handles large numbers', () {
      expect(convertInt(999999999), equals(999999999));
      expect(convertInt('999999999'), equals(999999999));
    });

    test('convertDouble handles double value', () {
      expect(convertDouble(42.5), equals(42.5));
    });

    test('convertDouble handles int value', () {
      expect(convertDouble(42), equals(42.0));
    });

    test('convertDouble handles String value', () {
      expect(convertDouble('100.5'), equals(100.5));
    });

    test('convertDouble handles null value', () {
      expect(convertDouble(null), isNull);
    });

    test('convertDouble throws on invalid string', () {
      expect(() => convertDouble('not a number'), throwsException);
    });

    test('convertDouble handles zero', () {
      expect(convertDouble(0), equals(0.0));
      expect(convertDouble(0.0), equals(0.0));
      expect(convertDouble('0.0'), equals(0.0));
    });

    test('convertDouble handles negative numbers', () {
      expect(convertDouble(-42.5), equals(-42.5));
      expect(convertDouble('-100.25'), equals(-100.25));
    });

    test('convertDouble handles scientific notation', () {
      expect(convertDouble('1e10'), equals(1e10));
      expect(convertDouble('1.5e-5'), equals(1.5e-5));
    });

    test('serializeNull always returns null', () {
      expect(serializeNull(42), isNull);
      expect(serializeNull('string'), isNull);
      expect(serializeNull(null), isNull);
      expect(serializeNull(true), isNull);
      expect(serializeNull([1, 2, 3]), isNull);
    });
  });

  group('Response Base Class', () {
    test('setHeaders populates rate limit fields', () {
      final response = TestResponse();
      response.setHeaders({
        'X-Ratelimit-Limit': '100',
        'X-Ratelimit-Remaining': '95',
        'X-Ratelimit-Reset': '1609459200',
      });

      expect(response.rateLimitLimit, equals(100));
      expect(response.rateLimitRemaining, equals(95));
      expect(response.rateLimitReset, equals(1609459200));
    });

    test('setHeaders handles missing rate limit headers', () {
      final response = TestResponse();
      response.setHeaders({});

      expect(response.rateLimitLimit, isNull);
      expect(response.rateLimitRemaining, isNull);
      expect(response.rateLimitReset, isNull);
    });

    test('setHeaders handles partial rate limit headers', () {
      final response = TestResponse();
      response.setHeaders({
        'X-Ratelimit-Limit': '100',
      });

      expect(response.rateLimitLimit, equals(100));
      expect(response.rateLimitRemaining, isNull);
      expect(response.rateLimitReset, isNull);
    });

    test('setHeaders handles invalid rate limit values', () {
      final response = TestResponse();
      response.setHeaders({
        'X-Ratelimit-Limit': 'invalid',
        'X-Ratelimit-Remaining': 'invalid',
        'X-Ratelimit-Reset': 'invalid',
      });

      expect(response.rateLimitLimit, isNull);
      expect(response.rateLimitRemaining, isNull);
      expect(response.rateLimitReset, isNull);
    });

    test('setHeaders handles zero values', () {
      final response = TestResponse();
      response.setHeaders({
        'X-Ratelimit-Limit': '0',
        'X-Ratelimit-Remaining': '0',
        'X-Ratelimit-Reset': '0',
      });

      expect(response.rateLimitLimit, equals(0));
      expect(response.rateLimitRemaining, equals(0));
      expect(response.rateLimitReset, equals(0));
    });
  });

  group('Link', () {
    test('creates link with href and templated', () {
      final link = Link('https://example.com/test', true);
      expect(link.href, equals('https://example.com/test'));
      expect(link.templated, equals(true));
    });

    test('creates link with href and non-templated', () {
      final link = Link('https://example.com/test', false);
      expect(link.href, equals('https://example.com/test'));
      expect(link.templated, equals(false));
    });

    test('creates link with null templated', () {
      final link = Link('https://example.com/test', null);
      expect(link.href, equals('https://example.com/test'));
      expect(link.templated, isNull);
    });

    test('fromJson creates link correctly', () {
      final json = {
        'href': 'https://example.com/test',
        'templated': true,
      };
      final link = Link.fromJson(json);
      expect(link.href, equals('https://example.com/test'));
      expect(link.templated, equals(true));
    });

    test('toJson creates correct map', () {
      final link = Link('https://example.com/test', true);
      final json = link.toJson();
      expect(json['href'], equals('https://example.com/test'));
      expect(json['templated'], equals(true));
    });

    test('handles URL with query parameters', () {
      final link = Link('https://example.com/test?param=value', false);
      expect(link.href, contains('param=value'));
    });
  });

  group('PageLinks', () {
    test('creates page links with all links', () {
      final next = Link('https://example.com/next', false);
      final prev = Link('https://example.com/prev', false);
      final self = Link('https://example.com/self', false);

      final pageLinks = PageLinks(next, prev, self);

      expect(pageLinks.next, equals(next));
      expect(pageLinks.prev, equals(prev));
      expect(pageLinks.self, equals(self));
    });

    test('creates page links with null next', () {
      final prev = Link('https://example.com/prev', false);
      final self = Link('https://example.com/self', false);

      final pageLinks = PageLinks(null, prev, self);

      expect(pageLinks.next, isNull);
      expect(pageLinks.prev, equals(prev));
      expect(pageLinks.self, equals(self));
    });

    test('creates page links with null prev', () {
      final next = Link('https://example.com/next', false);
      final self = Link('https://example.com/self', false);

      final pageLinks = PageLinks(next, null, self);

      expect(pageLinks.next, equals(next));
      expect(pageLinks.prev, isNull);
      expect(pageLinks.self, equals(self));
    });

    test('fromJson creates page links correctly', () {
      final json = {
        'next': {'href': 'https://example.com/next', 'templated': false},
        'prev': {'href': 'https://example.com/prev', 'templated': false},
        'self': {'href': 'https://example.com/self', 'templated': false},
      };

      final pageLinks = PageLinks.fromJson(json);

      expect(pageLinks.next, isNotNull);
      expect(pageLinks.next!.href, equals('https://example.com/next'));
      expect(pageLinks.prev, isNotNull);
      expect(pageLinks.prev!.href, equals('https://example.com/prev'));
      expect(pageLinks.self.href, equals('https://example.com/self'));
    });

    test('fromJson handles null next and prev', () {
      final json = {
        'self': {'href': 'https://example.com/self', 'templated': false},
      };

      final pageLinks = PageLinks.fromJson(json);

      expect(pageLinks.next, isNull);
      expect(pageLinks.prev, isNull);
      expect(pageLinks.self.href, equals('https://example.com/self'));
    });
  });

  group('TypeToken', () {
    test('creates type token with captured type', () {
      final token = TypeToken<String>();
      expect(token.type, equals(String));
    });

    test('creates type token for different types', () {
      final stringToken = TypeToken<String>();
      final intToken = TypeToken<int>();
      final listToken = TypeToken<List<String>>();

      expect(stringToken.type, equals(String));
      expect(intToken.type, equals(int));
      expect(listToken.type, equals(List<String>));
    });

    test('has consistent hash code for same type', () {
      final token1 = TypeToken<String>();
      final token2 = TypeToken<String>();

      expect(token1.hashCode, equals(token2.hashCode));
    });

    test('has different hash code for different types', () {
      final stringToken = TypeToken<String>();
      final intToken = TypeToken<int>();

      expect(stringToken.hashCode, isNot(equals(intToken.hashCode)));
    });
  });

  group('UnknownResponse', () {
    test('creates exception with code and body', () {
      final exception = UnknownResponse(404, 'Not found');
      expect(exception.code, equals(404));
      expect(exception.body, equals('Not found'));
    });

    test('toString includes code and body', () {
      final exception = UnknownResponse(500, 'Server error');
      final message = exception.toString();
      expect(message, contains('500'));
      expect(message, contains('Server error'));
    });

    test('handles empty body', () {
      final exception = UnknownResponse(204, '');
      expect(exception.code, equals(204));
      expect(exception.body, equals(''));
    });

    test('handles different HTTP codes', () {
      final exception400 = UnknownResponse(400, 'Bad request');
      final exception401 = UnknownResponse(401, 'Unauthorized');
      final exception403 = UnknownResponse(403, 'Forbidden');
      final exception500 = UnknownResponse(500, 'Server error');

      expect(exception400.code, equals(400));
      expect(exception401.code, equals(401));
      expect(exception403.code, equals(403));
      expect(exception500.code, equals(500));
    });
  });
}

class TestResponse extends Response {}
