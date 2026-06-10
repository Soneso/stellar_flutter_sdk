// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/src/smartaccount/oz/oz_http_internal.dart';

void main() {
  group('isJsonContentType', () {
    test('test_isJsonContentType_null_returnsTrue', () {
      expect(isJsonContentType(null), isTrue,
          reason:
              'A missing Content-Type header is accepted; the calling code '
              'falls back to JSON parsing which will fail loudly on a '
              'non-JSON body');
    });

    test('test_isJsonContentType_exactApplicationJson_returnsTrue', () {
      expect(isJsonContentType('application/json'), isTrue);
    });

    test('test_isJsonContentType_applicationProblemJson_returnsTrue', () {
      expect(isJsonContentType('application/problem+json'), isTrue,
          reason: 'RFC 7807 problem details responses must be accepted');
    });

    test('test_isJsonContentType_withCharsetParameter_returnsTrue', () {
      expect(isJsonContentType('application/json; charset=utf-8'), isTrue,
          reason:
              'Parameters after the media type (e.g. charset) must be '
              'stripped before equality matching');
    });

    test('test_isJsonContentType_problemJsonWithCharset_returnsTrue', () {
      expect(
          isJsonContentType('application/problem+json; charset=utf-8'), isTrue);
    });

    test('test_isJsonContentType_mixedCase_returnsTrue', () {
      expect(isJsonContentType('Application/JSON'), isTrue,
          reason: 'Media-type matching is case-insensitive');
      expect(isJsonContentType('APPLICATION/PROBLEM+JSON'), isTrue);
    });

    test('test_isJsonContentType_withSurroundingWhitespace_returnsTrue', () {
      expect(isJsonContentType('  application/json  '), isTrue,
          reason:
              'Whitespace around the media type must be trimmed before '
              'equality matching');
    });

    test('test_isJsonContentType_applicationJsonx_returnsFalse', () {
      expect(isJsonContentType('application/jsonx'), isFalse,
          reason:
              'Look-alike media types must be rejected; "application/jsonx" '
              'is not JSON');
    });

    test('test_isJsonContentType_applicationJson5_returnsFalse', () {
      expect(isJsonContentType('application/json5'), isFalse,
          reason: 'JSON5 is a different media type and must be rejected');
    });

    test('test_isJsonContentType_applicationJsonAttacker_returnsFalse', () {
      expect(isJsonContentType('application/json+attacker'), isFalse,
          reason:
              'Suffix-extended look-alike media types must be rejected by '
              'exact equality');
    });

    test('test_isJsonContentType_textHtml_returnsFalse', () {
      expect(isJsonContentType('text/html'), isFalse);
    });

    test('test_isJsonContentType_textPlain_returnsFalse', () {
      expect(isJsonContentType('text/plain'), isFalse);
    });

    test('test_isJsonContentType_emptyString_returnsFalse', () {
      expect(isJsonContentType(''), isFalse,
          reason:
              'An empty Content-Type header is treated as a non-JSON media '
              'type; only the null sentinel grants the no-header pass');
    });
  });

  group('genericErrorMessage', () {
    test('nonEmptyToString_returnsToString', () {
      expect(genericErrorMessage(Exception('rpc error')), contains('rpc error'));
    });

    test('emptyToString_returnsDefault', () {
      // Create an object whose toString() is empty.
      expect(
        genericErrorMessage(_EmptyToString()),
        equals('Request failed'),
      );
    });

    test('customDefaultText_usedWhenEmpty', () {
      expect(
        genericErrorMessage(_EmptyToString(), defaultText: 'custom fallback'),
        equals('custom fallback'),
      );
    });
  });
}

class _EmptyToString {
  @override
  String toString() => '';
}
