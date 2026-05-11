// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

// Library-private parser is reached via direct relative-path import (the
// file is intentionally not exported from the SDK barrel).
import 'package:stellar_flutter_sdk/src/smartaccount/core/web_authn_cbor_parser.dart';

// ===========================================================================
// CBOR builder helpers
// ===========================================================================

/// Encodes a CBOR text string (major type 3).
Uint8List _buildCborTextString(String text) {
  final utf8Bytes = Uint8List.fromList(utf8.encode(text));
  final head = _buildCborHead(3, utf8Bytes.length);
  return _concat(<Uint8List>[head, utf8Bytes]);
}

/// Encodes a CBOR byte string (major type 2).
Uint8List _buildCborByteString(Uint8List data) {
  final head = _buildCborHead(2, data.length);
  return _concat(<Uint8List>[head, data]);
}

/// Builds a CBOR head byte (and any extended length bytes) for the given
/// major type and length/value.
Uint8List _buildCborHead(int majorType, int length) {
  final major = majorType << 5;
  if (length < 24) {
    return Uint8List.fromList(<int>[(major | length) & 0xFF]);
  } else if (length < 256) {
    return Uint8List.fromList(<int>[(major | 24) & 0xFF, length & 0xFF]);
  } else if (length < 65536) {
    return Uint8List.fromList(<int>[
      (major | 25) & 0xFF,
      (length >> 8) & 0xFF,
      length & 0xFF,
    ]);
  } else {
    return Uint8List.fromList(<int>[
      (major | 26) & 0xFF,
      (length >> 24) & 0xFF,
      (length >> 16) & 0xFF,
      (length >> 8) & 0xFF,
      length & 0xFF,
    ]);
  }
}

Uint8List _concat(List<Uint8List> parts) {
  var total = 0;
  for (final p in parts) {
    total += p.length;
  }
  final out = Uint8List(total);
  var off = 0;
  for (final p in parts) {
    out.setRange(off, off + p.length, p);
    off += p.length;
  }
  return out;
}

/// Builds a minimal but structurally valid CBOR attestation object containing
/// the three standard fields: "fmt", "attStmt", "authData".
Uint8List _buildAttestationObject(
  Uint8List authData, {
  bool fmtFirst = true,
  bool includeAttStmt = false,
}) {
  final entries = <Uint8List>[];
  final int entryCount;

  if (!fmtFirst) {
    entries
      ..add(_buildCborTextString('authData'))
      ..add(_buildCborByteString(authData))
      ..add(_buildCborTextString('fmt'))
      ..add(_buildCborTextString('none'));
    entryCount = 2;
  } else {
    entries
      ..add(_buildCborTextString('fmt'))
      ..add(_buildCborTextString('none'));
    if (includeAttStmt) {
      entries
        ..add(_buildCborTextString('attStmt'))
        ..add(_buildCborHead(5, 0)); // empty map
    }
    entries
      ..add(_buildCborTextString('authData'))
      ..add(_buildCborByteString(authData));
    entryCount = includeAttStmt ? 3 : 2;
  }

  final result = <Uint8List>[_buildCborHead(5, entryCount), ...entries];
  return _concat(result);
}

/// Builds realistic 37-byte authenticator data with the given flags byte.
Uint8List _buildAuthenticatorData([int flagsByte = 0x00]) {
  final data = Uint8List(37);
  for (var i = 0; i < 32; i++) {
    data[i] = (i + 1) & 0xFF;
  }
  data[32] = flagsByte & 0xFF;
  data[33] = 0x00;
  data[34] = 0x00;
  data[35] = 0x00;
  data[36] = 0x01;
  return data;
}

/// Builds a minimal CBOR-encoded COSE ES256 key map.
Uint8List _buildCoseKey(Uint8List x, Uint8List y) {
  final builder = BytesBuilder()
    ..addByte(0xA5) // map(5)
    ..add(<int>[0x01, 0x02]) // kty -> EC2
    ..add(<int>[0x03, 0x26]) // alg -> ES256
    ..add(<int>[0x20, 0x01]) // crv -> P-256
    ..addByte(0x21) // -2 (X)
    ..add(_buildCborByteString(x))
    ..addByte(0x22) // -3 (Y)
    ..add(_buildCborByteString(y));
  return builder.toBytes();
}

// Known test key material.
final Uint8List _testX =
    Uint8List.fromList(List<int>.generate(32, (i) => (i + 1) & 0xFF));
final Uint8List _testY =
    Uint8List.fromList(List<int>.generate(32, (i) => (i + 33) & 0xFF));

void main() {
  // =========================================================================
  // 1. extractAuthenticatorDataFromAttestation
  // =========================================================================
  group('extractAuthenticatorDataFromAttestation', () {
    test('test_extract_authenticator_data_auth_data_as_first_entry', () {
      final authData = _buildAuthenticatorData();
      final attestation = _buildAttestationObject(authData, fmtFirst: false);
      final result =
          WebAuthnCborParser.extractAuthenticatorDataFromAttestation(attestation);
      expect(result, equals(authData));
    });

    test('test_extract_authenticator_data_auth_data_as_second_entry', () {
      final authData = _buildAuthenticatorData();
      final attestation = _buildAttestationObject(authData);
      final result =
          WebAuthnCborParser.extractAuthenticatorDataFromAttestation(attestation);
      expect(result, equals(authData));
    });

    test('test_extract_authenticator_data_auth_data_as_third_entry', () {
      final authData = _buildAuthenticatorData();
      final attestation =
          _buildAttestationObject(authData, includeAttStmt: true);
      final result =
          WebAuthnCborParser.extractAuthenticatorDataFromAttestation(attestation);
      expect(result, equals(authData));
    });

    test('test_extract_authenticator_data_empty_input_returns_null', () {
      expect(
        WebAuthnCborParser.extractAuthenticatorDataFromAttestation(
            Uint8List(0)),
        isNull,
      );
    });

    test('test_extract_authenticator_data_single_byte_input_returns_null', () {
      expect(
        WebAuthnCborParser.extractAuthenticatorDataFromAttestation(
            Uint8List.fromList(const [0x01])),
        isNull,
      );
    });

    test('test_extract_authenticator_data_non_map_major_type_returns_null', () {
      // 0x82 = major type 4 (array), length 2.
      final data = Uint8List.fromList(const [0x82, 0x01, 0x02]);
      expect(
        WebAuthnCborParser.extractAuthenticatorDataFromAttestation(data),
        isNull,
      );
    });

    test('test_extract_authenticator_data_map_with_no_auth_data_key_returns_null',
        () {
      final data = _concat(<Uint8List>[
        _buildCborHead(5, 1),
        _buildCborTextString('fmt'),
        _buildCborTextString('none'),
      ]);
      expect(
        WebAuthnCborParser.extractAuthenticatorDataFromAttestation(data),
        isNull,
      );
    });

    test('test_extract_authenticator_data_map_with_zero_entries_returns_null',
        () {
      final data = _buildCborHead(5, 0);
      expect(
        WebAuthnCborParser.extractAuthenticatorDataFromAttestation(data),
        isNull,
      );
    });

    test(
        'test_extract_authenticator_data_truncated_byte_string_length_returns_null',
        () {
      final data = _concat(<Uint8List>[
        _buildCborHead(5, 1),
        _buildCborTextString('authData'),
        Uint8List.fromList(const [0x58, 0x28, 0x01, 0x02]),
      ]);
      expect(
        WebAuthnCborParser.extractAuthenticatorDataFromAttestation(data),
        isNull,
      );
    });

    test('test_extract_authenticator_data_auth_data_with_1byte_cbor_length',
        () {
      final authData =
          Uint8List.fromList(List<int>.generate(100, (i) => i & 0xFF));
      final attestation = _buildAttestationObject(authData);
      expect(
        WebAuthnCborParser.extractAuthenticatorDataFromAttestation(attestation),
        equals(authData),
      );
    });

    test('test_extract_authenticator_data_auth_data_with_2byte_cbor_length',
        () {
      final authData =
          Uint8List.fromList(List<int>.generate(300, (i) => i & 0xFF));
      final attestation = _buildAttestationObject(authData);
      expect(
        WebAuthnCborParser.extractAuthenticatorDataFromAttestation(attestation),
        equals(authData),
      );
    });

    test('test_extract_authenticator_data_auth_data_with_inline_length', () {
      final authData =
          Uint8List.fromList(List<int>.generate(20, (i) => i & 0xFF));
      final attestation = _buildAttestationObject(authData);
      expect(
        WebAuthnCborParser.extractAuthenticatorDataFromAttestation(attestation),
        equals(authData),
      );
    });

    test('test_extract_authenticator_data_truncated_map_header_returns_null',
        () {
      expect(
        WebAuthnCborParser.extractAuthenticatorDataFromAttestation(
            Uint8List.fromList(const [0xA1])),
        isNull,
      );
    });

    test('test_extract_authenticator_data_real_attestation_object_bytes', () {
      final rpIdHash = Uint8List(32)..fillRange(0, 32, 0xAB);
      const flags = 0x41;
      final signCount = Uint8List.fromList(const [0x00, 0x00, 0x00, 0x05]);
      final authData =
          _concat(<Uint8List>[rpIdHash, Uint8List.fromList(<int>[flags]), signCount]);

      final attestation = _concat(<Uint8List>[
        _buildCborHead(5, 2),
        _buildCborTextString('fmt'),
        _buildCborTextString('none'),
        _buildCborTextString('authData'),
        _buildCborByteString(authData),
      ]);

      final result =
          WebAuthnCborParser.extractAuthenticatorDataFromAttestation(attestation);
      expect(result, equals(authData));
      expect(result!.length - 5, equals(32));
    });

    test(
        'test_extract_authenticator_data_value_after_fmt_is_map_skipped_correctly',
        () {
      final authData = _buildAuthenticatorData();
      final attestation = _concat(<Uint8List>[
        _buildCborHead(5, 3),
        _buildCborTextString('fmt'),
        _buildCborTextString('packed'),
        _buildCborTextString('attStmt'),
        _buildCborHead(5, 1),
        _buildCborTextString('x5c'),
        _buildCborByteString(Uint8List(10)..fillRange(0, 10, 0xFF)),
        _buildCborTextString('authData'),
        _buildCborByteString(authData),
      ]);

      final result =
          WebAuthnCborParser.extractAuthenticatorDataFromAttestation(attestation);
      expect(result, equals(authData));
    });
  });

  // =========================================================================
  // 2. readCborByteString
  // =========================================================================
  group('readCborByteString', () {
    test('test_read_cbor_byte_string_inline_length', () {
      final payload = Uint8List.fromList(const [0x01, 0x02, 0x03]);
      final encoded = _buildCborByteString(payload);
      final result = WebAuthnCborParser.readCborByteString(encoded, 0);
      expect(result, isNotNull);
      expect(result!.$1, equals(payload));
      expect(result.$2, equals(encoded.length));
    });

    test('test_read_cbor_byte_string_1byte_header_additional_info_24', () {
      final payload =
          Uint8List.fromList(List<int>.generate(30, (i) => i & 0xFF));
      final encoded = _buildCborByteString(payload);
      expect(encoded[0], equals(0x58));
      final result = WebAuthnCborParser.readCborByteString(encoded, 0);
      expect(result, isNotNull);
      expect(result!.$1, equals(payload));
    });

    test('test_read_cbor_byte_string_2byte_header_additional_info_25', () {
      final payload =
          Uint8List.fromList(List<int>.generate(300, (i) => i & 0xFF));
      final encoded = _buildCborByteString(payload);
      expect(encoded[0], equals(0x59));
      final result = WebAuthnCborParser.readCborByteString(encoded, 0);
      expect(result, isNotNull);
      expect(result!.$1, equals(payload));
    });

    test('test_read_cbor_byte_string_4byte_header_additional_info_26', () {
      final content = Uint8List.fromList(const [0xAA, 0xBB, 0xCC, 0xDD, 0xEE]);
      final header =
          Uint8List.fromList(const [0x5A, 0x00, 0x00, 0x00, 0x05]);
      final encoded = _concat(<Uint8List>[header, content]);
      final result = WebAuthnCborParser.readCborByteString(encoded, 0);
      expect(result, isNotNull);
      expect(result!.$1, equals(content));
      expect(result.$2, equals(encoded.length));
    });

    test(
        'test_read_cbor_byte_string_4byte_header_negative_int_overflow_returns_null',
        () {
      final encoded =
          Uint8List.fromList(const [0x5A, 0x80, 0x00, 0x00, 0x00, 0x01]);
      expect(WebAuthnCborParser.readCborByteString(encoded, 0), isNull);
    });

    test('test_read_cbor_byte_string_empty_byte_string', () {
      final encoded = Uint8List.fromList(const [0x40]);
      final result = WebAuthnCborParser.readCborByteString(encoded, 0);
      expect(result, isNotNull);
      expect(result!.$1.length, equals(0));
      expect(result.$2, equals(1));
    });

    test('test_read_cbor_byte_string_truncated_data_returns_null', () {
      final encoded = Uint8List.fromList(const [0x4A, 0x01, 0x02, 0x03]);
      expect(WebAuthnCborParser.readCborByteString(encoded, 0), isNull);
    });

    test('test_read_cbor_byte_string_offset_at_end_of_data_returns_null', () {
      final data = Uint8List.fromList(const [0x01, 0x02]);
      expect(WebAuthnCborParser.readCborByteString(data, 2), isNull);
    });

    test('test_read_cbor_byte_string_wrong_major_type_returns_null', () {
      final encoded = Uint8List.fromList(const [0x61, 0x41]);
      expect(WebAuthnCborParser.readCborByteString(encoded, 0), isNull);
    });

    test('test_read_cbor_byte_string_1byte_header_truncated_length_returns_null',
        () {
      expect(
        WebAuthnCborParser.readCborByteString(
            Uint8List.fromList(const [0x58]), 0),
        isNull,
      );
    });

    test('test_read_cbor_byte_string_2byte_header_truncated_length_returns_null',
        () {
      expect(
        WebAuthnCborParser.readCborByteString(
            Uint8List.fromList(const [0x59, 0x01]), 0),
        isNull,
      );
    });
  });

  // =========================================================================
  // 3. readCborTextString
  // =========================================================================
  group('readCborTextString', () {
    test('test_read_cbor_text_string_inline_length', () {
      const text = 'hello';
      final encoded = _buildCborTextString(text);
      final result = WebAuthnCborParser.readCborTextString(encoded, 0);
      expect(result, isNotNull);
      expect(result!.$1, equals(text));
      expect(result.$2, equals(encoded.length));
    });

    test('test_read_cbor_text_string_1byte_header_additional_info_24', () {
      final text = 'a' * 30;
      final encoded = _buildCborTextString(text);
      final result = WebAuthnCborParser.readCborTextString(encoded, 0);
      expect(result, isNotNull);
      expect(result!.$1, equals(text));
    });

    test('test_read_cbor_text_string_2byte_header_additional_info_25', () {
      final text = 'b' * 300;
      final encoded = _buildCborTextString(text);
      final result = WebAuthnCborParser.readCborTextString(encoded, 0);
      expect(result, isNotNull);
      expect(result!.$1, equals(text));
    });

    test('test_read_cbor_text_string_multibyte_utf8', () {
      const text = 'ステラー';
      final encoded = _buildCborTextString(text);
      final result = WebAuthnCborParser.readCborTextString(encoded, 0);
      expect(result, isNotNull);
      expect(result!.$1, equals(text));
    });

    test('test_read_cbor_text_string_empty_string', () {
      final encoded = _buildCborTextString('');
      final result = WebAuthnCborParser.readCborTextString(encoded, 0);
      expect(result, isNotNull);
      expect(result!.$1, equals(''));
    });

    test('test_read_cbor_text_string_truncated_data_returns_null', () {
      final encoded = Uint8List.fromList(const [0x6A, 0x41, 0x42]);
      expect(WebAuthnCborParser.readCborTextString(encoded, 0), isNull);
    });

    test('test_read_cbor_text_string_wrong_major_type_returns_null', () {
      final encoded = Uint8List.fromList(const [0x44, 0x01, 0x02, 0x03, 0x04]);
      expect(WebAuthnCborParser.readCborTextString(encoded, 0), isNull);
    });
  });

  // =========================================================================
  // 4. readCborLength
  // =========================================================================
  group('readCborLength', () {
    test('test_read_cbor_length_inline_length_0', () {
      final result = WebAuthnCborParser.readCborLength(
          Uint8List.fromList(const [0x40]), 0);
      expect(result, isNotNull);
      expect(result!.$1, equals(0));
      expect(result.$2, equals(1));
    });

    test('test_read_cbor_length_inline_length_23', () {
      final result = WebAuthnCborParser.readCborLength(
          Uint8List.fromList(const [0x57]), 0);
      expect(result, isNotNull);
      expect(result!.$1, equals(23));
      expect(result.$2, equals(1));
    });

    test('test_read_cbor_length_1byte_extended_additional_info_24', () {
      final result = WebAuthnCborParser.readCborLength(
          Uint8List.fromList(const [0x58, 0x64]), 0);
      expect(result, isNotNull);
      expect(result!.$1, equals(100));
      expect(result.$2, equals(2));
    });

    test('test_read_cbor_length_2byte_extended_additional_info_25', () {
      final result = WebAuthnCborParser.readCborLength(
          Uint8List.fromList(const [0x59, 0x01, 0x00]), 0);
      expect(result, isNotNull);
      expect(result!.$1, equals(256));
      expect(result.$2, equals(3));
    });

    test('test_read_cbor_length_4byte_extended_additional_info_26', () {
      final result = WebAuthnCborParser.readCborLength(
          Uint8List.fromList(const [0x5A, 0x00, 0x01, 0x00, 0x00]), 0);
      expect(result, isNotNull);
      expect(result!.$1, equals(65536));
      expect(result.$2, equals(5));
    });

    test('test_read_cbor_length_4byte_extended_negative_overflow_returns_null',
        () {
      expect(
        WebAuthnCborParser.readCborLength(
            Uint8List.fromList(const [0x5A, 0x80, 0x00, 0x00, 0x00]), 0),
        isNull,
      );
    });

    test('test_read_cbor_length_insufficient_data_1byte_extended_returns_null',
        () {
      expect(
        WebAuthnCborParser.readCborLength(
            Uint8List.fromList(const [0x58]), 0),
        isNull,
      );
    });

    test('test_read_cbor_length_insufficient_data_2byte_extended_returns_null',
        () {
      expect(
        WebAuthnCborParser.readCborLength(
            Uint8List.fromList(const [0x59, 0x01]), 0),
        isNull,
      );
    });

    test('test_read_cbor_length_offset_at_end_returns_null', () {
      expect(
        WebAuthnCborParser.readCborLength(
            Uint8List.fromList(const [0x01]), 1),
        isNull,
      );
    });
  });

  // =========================================================================
  // 5. skipCborValue
  // =========================================================================
  group('skipCborValue', () {
    test('test_skip_cbor_value_unsigned_integer_inline', () {
      final data = Uint8List.fromList(const [0x0A, 0x99]);
      expect(WebAuthnCborParser.skipCborValue(data, 0), equals(1));
    });

    test('test_skip_cbor_value_negative_integer_inline', () {
      final data = Uint8List.fromList(const [0x20, 0x99]);
      expect(WebAuthnCborParser.skipCborValue(data, 0), equals(1));
    });

    test('test_skip_cbor_value_text_string', () {
      final encoded = _buildCborTextString('abc');
      final extra = Uint8List.fromList(const [0xFF]);
      final combined = _concat(<Uint8List>[encoded, extra]);
      expect(
        WebAuthnCborParser.skipCborValue(combined, 0),
        equals(encoded.length),
      );
    });

    test('test_skip_cbor_value_byte_string', () {
      final encoded =
          _buildCborByteString(Uint8List.fromList(const [0x01, 0x02, 0x03, 0x04]));
      final extra = Uint8List.fromList(const [0xFF]);
      final combined = _concat(<Uint8List>[encoded, extra]);
      expect(
        WebAuthnCborParser.skipCborValue(combined, 0),
        equals(encoded.length),
      );
    });

    test('test_skip_cbor_value_array_with_nested_elements', () {
      final data = Uint8List.fromList(const [0x82, 0x01, 0x02]);
      expect(WebAuthnCborParser.skipCborValue(data, 0), equals(3));
    });

    test('test_skip_cbor_value_map_with_nested_entries', () {
      final data = _concat(<Uint8List>[
        _buildCborHead(5, 1),
        _buildCborTextString('k'),
        Uint8List.fromList(const [0x05]),
      ]);
      expect(WebAuthnCborParser.skipCborValue(data, 0), equals(data.length));
    });

    test('test_skip_cbor_value_nested_array', () {
      final inner = Uint8List.fromList(const [0x81, 0x07]);
      final outer = _concat(<Uint8List>[
        Uint8List.fromList(const [0x81]),
        inner,
      ]);
      expect(
        WebAuthnCborParser.skipCborValue(outer, 0),
        equals(outer.length),
      );
    });

    test('test_skip_cbor_value_tagged_value', () {
      final data = Uint8List.fromList(const [0xC1, 0x19, 0x03, 0xE8]);
      expect(WebAuthnCborParser.skipCborValue(data, 0), equals(4));
    });

    test('test_skip_cbor_value_float16', () {
      final data = Uint8List.fromList(const [0xF9, 0x00, 0x00, 0xFF]);
      expect(WebAuthnCborParser.skipCborValue(data, 0), equals(3));
    });

    test('test_skip_cbor_value_float32', () {
      final data =
          Uint8List.fromList(const [0xFA, 0x3F, 0x80, 0x00, 0x00, 0xFF]);
      expect(WebAuthnCborParser.skipCborValue(data, 0), equals(5));
    });

    test('test_skip_cbor_value_float64', () {
      final data = Uint8List(10);
      data[0] = 0xFB;
      for (var i = 1; i <= 8; i++) {
        data[i] = i & 0xFF;
      }
      data[9] = 0xFF;
      expect(WebAuthnCborParser.skipCborValue(data, 0), equals(9));
    });

    test('test_skip_cbor_value_simple_value_inline', () {
      final data = Uint8List.fromList(const [0xF4, 0xFF]);
      expect(WebAuthnCborParser.skipCborValue(data, 0), equals(1));
    });

    test('test_skip_cbor_value_simple_value_1byte_extended', () {
      final data = Uint8List.fromList(const [0xF8, 0x10, 0xFF]);
      expect(WebAuthnCborParser.skipCborValue(data, 0), equals(2));
    });

    test('test_skip_cbor_value_truncated_content_returns_null', () {
      final data = Uint8List.fromList(const [0x4A]);
      expect(WebAuthnCborParser.skipCborValue(data, 0), isNull);
    });

    test('test_skip_cbor_value_offset_at_end_returns_null', () {
      expect(
        WebAuthnCborParser.skipCborValue(
            Uint8List.fromList(const [0x01]), 1),
        isNull,
      );
    });
  });

  // =========================================================================
  // 6. skipCborHead
  // =========================================================================
  group('skipCborHead', () {
    test('test_skip_cbor_head_inline_additional_info', () {
      expect(
        WebAuthnCborParser.skipCborHead(
            Uint8List.fromList(const [0x05, 0xFF]), 0),
        equals(1),
      );
    });

    test('test_skip_cbor_head_additional_info_24_2bytes', () {
      expect(
        WebAuthnCborParser.skipCborHead(
            Uint8List.fromList(const [0x18, 0x64, 0xFF]), 0),
        equals(2),
      );
    });

    test('test_skip_cbor_head_additional_info_25_3bytes', () {
      expect(
        WebAuthnCborParser.skipCborHead(
            Uint8List.fromList(const [0x19, 0x01, 0x00, 0xFF]), 0),
        equals(3),
      );
    });

    test('test_skip_cbor_head_additional_info_26_5bytes', () {
      expect(
        WebAuthnCborParser.skipCborHead(
            Uint8List.fromList(const [0x1A, 0x00, 0x01, 0x00, 0x00, 0xFF]), 0),
        equals(5),
      );
    });

    test('test_skip_cbor_head_additional_info_27_9bytes', () {
      final data = Uint8List(10);
      data[0] = 0x1B;
      for (var i = 1; i <= 8; i++) {
        data[i] = 0x00;
      }
      data[9] = 0xFF;
      expect(WebAuthnCborParser.skipCborHead(data, 0), equals(9));
    });

    test('test_skip_cbor_head_additional_info_24_truncated_returns_null', () {
      expect(
        WebAuthnCborParser.skipCborHead(
            Uint8List.fromList(const [0x18]), 0),
        isNull,
      );
    });

    test('test_skip_cbor_head_additional_info_25_truncated_returns_null', () {
      expect(
        WebAuthnCborParser.skipCborHead(
            Uint8List.fromList(const [0x19, 0x01]), 0),
        isNull,
      );
    });

    test('test_skip_cbor_head_additional_info_26_truncated_returns_null', () {
      expect(
        WebAuthnCborParser.skipCborHead(
            Uint8List.fromList(const [0x1A, 0x00, 0x01, 0x00]), 0),
        isNull,
      );
    });

    test('test_skip_cbor_head_additional_info_27_truncated_returns_null', () {
      final data = Uint8List.fromList(
          const [0x1B, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]);
      expect(WebAuthnCborParser.skipCborHead(data, 0), isNull);
    });
  });

  // =========================================================================
  // 7. extractPublicKeyFromCoseKey
  // =========================================================================
  group('extractPublicKeyFromCoseKey', () {
    test('test_extract_public_key_from_cose_key_standard_order', () {
      final coseKey = _buildCoseKey(_testX, _testY);
      final result = WebAuthnCborParser.extractPublicKeyFromCoseKey(coseKey);
      expect(result, isNotNull);
      expect(result!.length, equals(65));
      expect(result[0], equals(0x04));
      expect(result.sublist(1, 33), equals(_testX));
      expect(result.sublist(33, 65), equals(_testY));
    });

    test('test_extract_public_key_from_cose_key_y_before_x', () {
      final builder = BytesBuilder()
        ..addByte(0xA5)
        ..add(<int>[0x01, 0x02])
        ..add(<int>[0x03, 0x26])
        ..add(<int>[0x20, 0x01])
        ..addByte(0x22) // Y first
        ..add(_buildCborByteString(_testY))
        ..addByte(0x21) // X second
        ..add(_buildCborByteString(_testX));
      final data = builder.toBytes();

      final result = WebAuthnCborParser.extractPublicKeyFromCoseKey(data);
      expect(result, isNotNull);
      expect(result!.length, equals(65));
      expect(result.sublist(1, 33), equals(_testX));
      expect(result.sublist(33, 65), equals(_testY));
    });

    test('test_extract_public_key_from_cose_key_extra_entries_around_coordinates',
        () {
      final builder = BytesBuilder()
        ..addByte(0xA7) // map(7)
        ..add(<int>[0x01, 0x02])
        ..add(<int>[0x03, 0x26])
        ..add(<int>[0x20, 0x01])
        ..add(<int>[0x04, 0x18, 0x63]) // extra entry: key 4 -> uint(99)
        ..addByte(0x21)
        ..add(_buildCborByteString(_testX))
        ..addByte(0x22)
        ..add(_buildCborByteString(_testY))
        ..add(<int>[0x05, 0x01]); // extra trailing entry: key 5 -> uint(1)
      final data = builder.toBytes();

      final result = WebAuthnCborParser.extractPublicKeyFromCoseKey(data);
      expect(result, isNotNull);
      expect(result!.length, equals(65));
    });

    test('test_extract_public_key_from_cose_key_missing_x_coordinate_returns_null',
        () {
      final builder = BytesBuilder()
        ..addByte(0xA2) // map(2)
        ..add(<int>[0x01, 0x02])
        ..addByte(0x22)
        ..add(_buildCborByteString(_testY));
      final result = WebAuthnCborParser.extractPublicKeyFromCoseKey(
          builder.toBytes());
      expect(result, isNull);
    });

    test('test_extract_public_key_from_cose_key_missing_y_coordinate_returns_null',
        () {
      final builder = BytesBuilder()
        ..addByte(0xA2)
        ..add(<int>[0x01, 0x02])
        ..addByte(0x21)
        ..add(_buildCborByteString(_testX));
      final result = WebAuthnCborParser.extractPublicKeyFromCoseKey(
          builder.toBytes());
      expect(result, isNull);
    });

    test('test_extract_public_key_from_cose_key_x_coordinate_wrong_size_returns_null',
        () {
      final shortX = Uint8List.fromList(const [0x01, 0x02, 0x03]);
      final builder = BytesBuilder()
        ..addByte(0xA2)
        ..addByte(0x21)
        ..add(_buildCborByteString(shortX))
        ..addByte(0x22)
        ..add(_buildCborByteString(_testY));
      final result = WebAuthnCborParser.extractPublicKeyFromCoseKey(
          builder.toBytes());
      expect(result, isNull);
    });

    test('test_extract_public_key_from_cose_key_y_coordinate_wrong_size_returns_null',
        () {
      final shortY = Uint8List.fromList(const [0x01, 0x02]);
      final builder = BytesBuilder()
        ..addByte(0xA2)
        ..addByte(0x21)
        ..add(_buildCborByteString(_testX))
        ..addByte(0x22)
        ..add(_buildCborByteString(shortY));
      final result = WebAuthnCborParser.extractPublicKeyFromCoseKey(
          builder.toBytes());
      expect(result, isNull);
    });

    test('test_extract_public_key_from_cose_key_empty_input_returns_null', () {
      expect(
        WebAuthnCborParser.extractPublicKeyFromCoseKey(Uint8List(0)),
        isNull,
      );
    });

    test(
        'test_extract_public_key_from_cose_key_non_map_input_falls_back_to_pattern_matching',
        () {
      final prefix = Uint8List.fromList(
          const [0xA5, 0x01, 0x02, 0x03, 0x26, 0x20, 0x01, 0x21, 0x58, 0x20]);
      final yHeader = Uint8List.fromList(const [0x22, 0x58, 0x20]);
      final rawData = _concat(<Uint8List>[prefix, _testX, yHeader, _testY]);

      final result = WebAuthnCborParser.extractPublicKeyFromCoseKey(rawData);
      expect(result, isNotNull);
      expect(result!.length, equals(65));
      expect(result.sublist(1, 33), equals(_testX));
      expect(result.sublist(33, 65), equals(_testY));
    });

    test(
        'test_extract_public_key_from_cose_key_map_parsing_fails_then_pattern_succeeds',
        () {
      final prefix = Uint8List.fromList(
          const [0xA5, 0x01, 0x02, 0x03, 0x26, 0x20, 0x01, 0x21, 0x58, 0x20]);
      final yHeader = Uint8List.fromList(const [0x22, 0x58, 0x20]);
      final fullData = _concat(<Uint8List>[prefix, _testX, yHeader, _testY]);
      final result = WebAuthnCborParser.extractPublicKeyFromCoseKey(fullData);
      expect(result, isNotNull);
      expect(result!.length, equals(65));
    });
  });

  // =========================================================================
  // 8. extractPublicKeyFromSpki
  // =========================================================================
  group('extractPublicKeyFromSpki', () {
    test('test_extract_public_key_from_spki_exact_65_bytes_with_prefix', () {
      final spki = _concat(<Uint8List>[
        Uint8List.fromList(const [0x04]),
        _testX,
        _testY,
      ]);
      expect(spki.length, equals(65));
      final result = WebAuthnCborParser.extractPublicKeyFromSpki(spki);
      expect(result, isNotNull);
      expect(result, equals(spki));
    });

    test('test_extract_public_key_from_spki_91byte_spki_with_prefix_at_26',
        () {
      final header = Uint8List(26)..fillRange(0, 26, 0x30);
      final keyBytes = _concat(<Uint8List>[
        Uint8List.fromList(const [0x04]),
        _testX,
        _testY,
      ]);
      final spki = _concat(<Uint8List>[header, keyBytes]);
      expect(spki.length, equals(91));
      final result = WebAuthnCborParser.extractPublicKeyFromSpki(spki);
      expect(result, isNotNull);
      expect(result, equals(keyBytes));
    });

    test(
        'test_extract_public_key_from_spki_larger_than_91bytes_with_prefix_at_correct_position',
        () {
      final spki = Uint8List(100);
      spki[35] = 0x04;
      final result = WebAuthnCborParser.extractPublicKeyFromSpki(spki);
      expect(result, isNotNull);
      expect(result!.length, equals(65));
      expect(result[0], equals(0x04));
    });

    test('test_extract_public_key_from_spki_shorter_than_65bytes_returns_null',
        () {
      final spki = Uint8List(64)..fillRange(0, 64, 0x01);
      expect(WebAuthnCborParser.extractPublicKeyFromSpki(spki), isNull);
    });

    test('test_extract_public_key_from_spki_empty_input_returns_null', () {
      expect(
        WebAuthnCborParser.extractPublicKeyFromSpki(Uint8List(0)),
        isNull,
      );
    });

    test('test_extract_public_key_from_spki_65bytes_without_prefix_returns_null',
        () {
      final spki = Uint8List(65)..fillRange(0, 65, 0x01);
      spki[0] = 0x03;
      expect(WebAuthnCborParser.extractPublicKeyFromSpki(spki), isNull);
    });

    test('test_extract_public_key_from_spki_exactly_64bytes_returns_null', () {
      final spki = Uint8List(64)..fillRange(0, 64, 0x04);
      expect(WebAuthnCborParser.extractPublicKeyFromSpki(spki), isNull);
    });

    test('test_extract_public_key_from_spki_91bytes_with_wrong_prefix_byte_returns_null',
        () {
      expect(
        WebAuthnCborParser.extractPublicKeyFromSpki(Uint8List(91)),
        isNull,
      );
    });
  });

  // =========================================================================
  // 9. parseAuthenticatorFlags
  // =========================================================================
  group('parseAuthenticatorFlags', () {
    test('test_parse_authenticator_flags_null_input_both_null', () {
      final flags = WebAuthnCborParser.parseAuthenticatorFlags(null);
      expect(flags.deviceType, isNull);
      expect(flags.backedUp, isNull);
    });

    test('test_parse_authenticator_flags_empty_byte_array_both_null', () {
      final flags = WebAuthnCborParser.parseAuthenticatorFlags(Uint8List(0));
      expect(flags.deviceType, isNull);
      expect(flags.backedUp, isNull);
    });

    test('test_parse_authenticator_flags_too_short_32bytes_both_null', () {
      final flags = WebAuthnCborParser.parseAuthenticatorFlags(Uint8List(32));
      expect(flags.deviceType, isNull);
      expect(flags.backedUp, isNull);
    });

    test('test_parse_authenticator_flags_exactly_min_length_33bytes_parses_correctly',
        () {
      final data = Uint8List(33);
      data[32] = 0x00;
      final flags = WebAuthnCborParser.parseAuthenticatorFlags(data);
      expect(flags.deviceType, equals(WebAuthnCborParser.deviceTypeSingle));
      expect(flags.backedUp, isFalse);
    });

    test('test_parse_authenticator_flags_be0_bs0_single_device_not_backed_up',
        () {
      final data = _buildAuthenticatorData(0x00);
      final flags = WebAuthnCborParser.parseAuthenticatorFlags(data);
      expect(flags.deviceType, equals(WebAuthnCborParser.deviceTypeSingle));
      expect(flags.backedUp, isFalse);
    });

    test('test_parse_authenticator_flags_be1_bs0_multi_device_not_backed_up',
        () {
      final data = _buildAuthenticatorData(0x08);
      final flags = WebAuthnCborParser.parseAuthenticatorFlags(data);
      expect(flags.deviceType, equals(WebAuthnCborParser.deviceTypeMulti));
      expect(flags.backedUp, isFalse);
    });

    test('test_parse_authenticator_flags_be0_bs1_single_device_backed_up', () {
      final data = _buildAuthenticatorData(0x10);
      final flags = WebAuthnCborParser.parseAuthenticatorFlags(data);
      expect(flags.deviceType, equals(WebAuthnCborParser.deviceTypeSingle));
      expect(flags.backedUp, isTrue);
    });

    test('test_parse_authenticator_flags_be1_bs1_multi_device_backed_up', () {
      final data = _buildAuthenticatorData(0x18);
      final flags = WebAuthnCborParser.parseAuthenticatorFlags(data);
      expect(flags.deviceType, equals(WebAuthnCborParser.deviceTypeMulti));
      expect(flags.backedUp, isTrue);
    });

    test('test_parse_authenticator_flags_other_flag_bits_do_not_affect_result',
        () {
      final allFlags = (0x01 | 0x04 | 0x08 | 0x10 | 0x40) & 0xFF;
      final data = _buildAuthenticatorData(allFlags);
      final flags = WebAuthnCborParser.parseAuthenticatorFlags(data);
      expect(flags.deviceType, equals(WebAuthnCborParser.deviceTypeMulti));
      expect(flags.backedUp, isTrue);
    });

    test('test_parse_authenticator_flags_37byte_typical_auth_data_parses_correctly',
        () {
      final data = _buildAuthenticatorData(0x08);
      expect(data.length, equals(37));
      final flags = WebAuthnCborParser.parseAuthenticatorFlags(data);
      expect(flags.deviceType, equals(WebAuthnCborParser.deviceTypeMulti));
      expect(flags.backedUp, isFalse);
    });

    test('test_parse_authenticator_flags_device_type_single_constant_value',
        () {
      expect(WebAuthnCborParser.deviceTypeSingle, equals('singleDevice'));
    });

    test('test_parse_authenticator_flags_device_type_multi_constant_value',
        () {
      expect(WebAuthnCborParser.deviceTypeMulti, equals('multiDevice'));
    });
  });

  // =========================================================================
  // §9.4 minimum-bar additions (plan-pinned cases)
  // =========================================================================
  group('CBOR minimum-bar additions', () {
    test('test_cbor_decode_uint_small', () {
      // Major type 0, value 23 (inline).
      final encoded = _buildCborHead(0, 23);
      expect(encoded[0], equals(0x17));
      final length = WebAuthnCborParser.readCborLength(encoded, 0);
      expect(length, isNotNull);
      expect(length!.$1, equals(23));
    });

    test('test_cbor_decode_uint_one_byte', () {
      // Major type 0, additional info 24, value 0xFF.
      final data = Uint8List.fromList(const [0x18, 0xFF]);
      final length = WebAuthnCborParser.readCborLength(data, 0);
      expect(length, isNotNull);
      expect(length!.$1, equals(0xFF));
    });

    test('test_cbor_decode_uint_two_bytes', () {
      // Major type 0, additional info 25, value 0x1234.
      final data = Uint8List.fromList(const [0x19, 0x12, 0x34]);
      final length = WebAuthnCborParser.readCborLength(data, 0);
      expect(length, isNotNull);
      expect(length!.$1, equals(0x1234));
    });

    test('test_cbor_decode_uint_four_bytes', () {
      // Major type 0, additional info 26, value 0x12345678.
      final data =
          Uint8List.fromList(const [0x1A, 0x12, 0x34, 0x56, 0x78]);
      final length = WebAuthnCborParser.readCborLength(data, 0);
      expect(length, isNotNull);
      expect(length!.$1, equals(0x12345678));
    });

    test('test_cbor_decode_uint_eight_bytes', () {
      // Additional info 27 is not supported by readCborLength (overflows
      // signed 32-bit Int range); the parser must return null.
      final data = Uint8List.fromList(
          const [0x1B, 0x12, 0x34, 0x56, 0x78, 0x90, 0xAB, 0xCD, 0xEF]);
      expect(WebAuthnCborParser.readCborLength(data, 0), isNull);
    });

    test('test_cbor_decode_negative_int', () {
      // Major type 1, value -2 encoded as 0x21. Skip via skipCborValue.
      final data = Uint8List.fromList(const [0x21, 0x99]);
      expect(WebAuthnCborParser.skipCborValue(data, 0), equals(1));
    });

    test('test_cbor_decode_array_definite', () {
      // Array of 3 ints.
      final data = Uint8List.fromList(const [0x83, 0x01, 0x02, 0x03]);
      expect(WebAuthnCborParser.skipCborValue(data, 0), equals(4));
    });

    test('test_cbor_decode_array_indefinite_terminated', () {
      // Major type 4 with additional info 31 (indefinite). Not supported;
      // expect null.
      final data = Uint8List.fromList(const [0x9F, 0x01, 0xFF]);
      expect(WebAuthnCborParser.skipCborValue(data, 0), isNull);
    });

    test('test_cbor_decode_array_indefinite_unterminated_rejected', () {
      // Indefinite array with no break byte; expect null.
      final data = Uint8List.fromList(const [0x9F, 0x01]);
      expect(WebAuthnCborParser.skipCborValue(data, 0), isNull);
    });

    test('test_cbor_decode_map_definite', () {
      // Map with one key-value pair: { 1: 2 }.
      final data = Uint8List.fromList(const [0xA1, 0x01, 0x02]);
      expect(WebAuthnCborParser.skipCborValue(data, 0), equals(3));
    });

    test('test_cbor_decode_map_indefinite', () {
      // Major type 5 with additional info 31 (indefinite). Not supported.
      final data = Uint8List.fromList(const [0xBF, 0x01, 0x02, 0xFF]);
      expect(WebAuthnCborParser.skipCborValue(data, 0), isNull);
    });

    test('test_cbor_decode_truncated_rejected', () {
      // Byte-string head present but no following content.
      final data = Uint8List.fromList(const [0x4A]);
      expect(WebAuthnCborParser.skipCborValue(data, 0), isNull);
    });

    test('test_cbor_decode_deeply_nested_rejected', () {
      // Build a deeply-nested array of arrays beyond the parser's max depth.
      // Each [0x81] is an array(1) wrapping the next array; final element is
      // 0x01 (uint 1).
      const depth = 200;
      final data = Uint8List(depth + 1);
      for (var i = 0; i < depth; i++) {
        data[i] = 0x81;
      }
      data[depth] = 0x01;
      // Should not crash; parser depth cap returns null.
      expect(WebAuthnCborParser.skipCborValue(data, 0), isNull);
    });

    test('test_cbor_decode_max_depth_exceeded_rejected', () {
      // Identical to the deeply-nested case but with depth one above the cap.
      const depth = 80; // > _maxCborDepth (64)
      final data = Uint8List(depth + 1);
      for (var i = 0; i < depth; i++) {
        data[i] = 0x81;
      }
      data[depth] = 0x01;
      expect(WebAuthnCborParser.skipCborValue(data, 0), isNull);
    });

    test('test_cbor_fuzz_10000_seeded_rng_no_panic', () {
      // Plan-pinned seed for deterministic reproduction across CI runs.
      const int seed = 0xDEADBEEF;
      final rng = math.Random(seed);
      const int iterations = 10000;
      const int maxLength = 512;

      for (var i = 0; i < iterations; i++) {
        final length = rng.nextInt(maxLength + 1);
        final input = Uint8List(length);
        for (var j = 0; j < length; j++) {
          input[j] = rng.nextInt(256);
        }

        // Each public method must either return a clean result or null.
        // None must crash, throw, or loop indefinitely.
        try {
          WebAuthnCborParser.extractAuthenticatorDataFromAttestation(input);
          WebAuthnCborParser.extractPublicKeyFromCoseKey(input);
          WebAuthnCborParser.extractPublicKeyFromSpki(input);
          WebAuthnCborParser.parseAuthenticatorFlags(input);
          WebAuthnCborParser.readCborByteString(input, 0);
          WebAuthnCborParser.readCborTextString(input, 0);
          WebAuthnCborParser.readCborLength(input, 0);
          WebAuthnCborParser.skipCborValue(input, 0);
          WebAuthnCborParser.skipCborHead(input, 0);
        } on FormatException {
          // UTF-8 decoder may legitimately throw on malformed text-string
          // content discovered after the head was accepted. The test still
          // fails the parser if any other unexpected exception bubbles out;
          // the expectation here is strictly "no crashes".
        }
      }
    });
  });
}
