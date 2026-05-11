// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// secp256r1 generator point coordinates (from FIPS 186-4 / SEC 2).
final BigInt _gx = BigInt.parse(
  '6b17d1f2e12c4247f8bce6e563a440f277037d812deb33a0f4a13945d898c296',
  radix: 16,
);
final BigInt _gy = BigInt.parse(
  '4fe342e2fe1a7f9b8ee7eb4a7c0f9e162bce33576b315ececbb6406837bf51f5',
  radix: 16,
);
final BigInt _curveOrder = BigInt.parse(
  'ffffffff00000000ffffffffffffffffbce6faada7179e84f3b9cac2fc632551',
  radix: 16,
);
final BigInt _halfOrder = _curveOrder >> 1;

Uint8List _bigIntToFixedBytes(BigInt value, int len) {
  if (value < BigInt.zero) {
    throw ArgumentError('negative');
  }
  var hex = value.toRadixString(16);
  if (hex.length.isOdd) hex = '0$hex';
  final raw = Uint8List(hex.length ~/ 2);
  for (var i = 0; i < raw.length; i++) {
    raw[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
  }
  if (raw.length == len) return raw;
  if (raw.length < len) {
    final padded = Uint8List(len);
    padded.setRange(len - raw.length, len, raw);
    return padded;
  }
  throw ArgumentError('value too large for length $len');
}

Uint8List _generatorPubkey() {
  final out = Uint8List(65);
  out[0] = 0x04;
  out.setRange(1, 33, _bigIntToFixedBytes(_gx, 32));
  out.setRange(33, 65, _bigIntToFixedBytes(_gy, 32));
  return out;
}

Uint8List _encodeDerSignature(BigInt r, BigInt s) {
  Uint8List componentBytes(BigInt v) {
    var hex = v.toRadixString(16);
    if (hex.length.isOdd) hex = '0$hex';
    final raw = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < raw.length; i++) {
      raw[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    // DER encoding: positive integers must not have a leading 0x80+ byte;
    // prepend 0x00 if so.
    if (raw.isNotEmpty && (raw[0] & 0x80) != 0) {
      final out = Uint8List(raw.length + 1);
      out[0] = 0;
      out.setRange(1, out.length, raw);
      return out;
    }
    return raw;
  }

  final rb = componentBytes(r);
  final sb = componentBytes(s);
  final body = <int>[
    0x02,
    rb.length,
    ...rb,
    0x02,
    sb.length,
    ...sb,
  ];
  if (body.length > 255) throw ArgumentError('body too long');
  return Uint8List.fromList([0x30, body.length, ...body]);
}

void main() {
  group('parseDerSignature', () {
    test('parseDerSignature_validMinimalSignature', () {
      final sig = _encodeDerSignature(BigInt.one, BigInt.from(2));
      final out = SmartAccountUtils.parseDerSignature(sig);
      expect(out[0], BigInt.one);
      expect(out[1], BigInt.from(2));
    });

    test('parseDerSignature_stripsLeadingZeroPadding', () {
      // The encoder injects 0x00 padding when the high bit is set; the
      // parser must strip it back.
      final r = BigInt.parse(
        '80112233445566778899aabbccddeeff00112233445566778899aabbccddeeff',
        radix: 16,
      );
      final s = BigInt.from(123);
      final sig = _encodeDerSignature(r, s);
      final out = SmartAccountUtils.parseDerSignature(sig);
      expect(out[0], r);
      expect(out[1], s);
    });

    test('parseDerSignature_tooShort', () {
      expect(
        () => SmartAccountUtils.parseDerSignature(Uint8List(4)),
        throwsA(isA<InvalidInput>()),
      );
    });

    test('parseDerSignature_wrongLeadingByte', () {
      final out = Uint8List.fromList([0x31, 6, 0x02, 1, 1, 0x02, 1, 1]);
      expect(() => SmartAccountUtils.parseDerSignature(out),
          throwsA(isA<InvalidInput>()));
    });

    test('parseDerSignature_lengthMismatch', () {
      final out = Uint8List.fromList([0x30, 99, 0x02, 1, 1, 0x02, 1, 1]);
      expect(() => SmartAccountUtils.parseDerSignature(out),
          throwsA(isA<InvalidInput>()));
    });

    test('parseDerSignature_missingRMarker', () {
      final out = Uint8List.fromList([0x30, 6, 0x03, 1, 1, 0x02, 1, 1]);
      expect(() => SmartAccountUtils.parseDerSignature(out),
          throwsA(isA<InvalidInput>()));
    });

    test('parseDerSignature_zeroLengthR', () {
      final out = Uint8List.fromList([0x30, 6, 0x02, 0, 0x02, 1, 1, 0]);
      expect(() => SmartAccountUtils.parseDerSignature(out),
          throwsA(isA<InvalidInput>()));
    });

    test('parseDerSignature_truncatedRComponent', () {
      // R length claims 5 bytes but only 1 is present.
      final out = Uint8List.fromList([0x30, 4, 0x02, 5, 0x01, 0x02]);
      expect(() => SmartAccountUtils.parseDerSignature(out),
          throwsA(isA<InvalidInput>()));
    });

    test('parseDerSignature_missingSMarker', () {
      // R length 1 followed by something other than 0x02 marker.
      final out = Uint8List.fromList([0x30, 6, 0x02, 1, 1, 0x03, 1, 1]);
      expect(() => SmartAccountUtils.parseDerSignature(out),
          throwsA(isA<InvalidInput>()));
    });

    test('parseDerSignature_zeroLengthS', () {
      final out = Uint8List.fromList([0x30, 6, 0x02, 1, 1, 0x02, 0, 0]);
      expect(() => SmartAccountUtils.parseDerSignature(out),
          throwsA(isA<InvalidInput>()));
    });

    test('parseDerSignature_truncatedSComponent', () {
      final out = Uint8List.fromList([0x30, 6, 0x02, 1, 1, 0x02, 5, 1]);
      expect(() => SmartAccountUtils.parseDerSignature(out),
          throwsA(isA<InvalidInput>()));
    });

    test('parseDerSignature_trailingBytesAfterS', () {
      final out = Uint8List.fromList([
        0x30, 8, 0x02, 1, 1, 0x02, 1, 1, 0x99, 0x99,
      ]);
      expect(() => SmartAccountUtils.parseDerSignature(out),
          throwsA(isA<InvalidInput>()));
    });

    test('parseDerSignature_trailingBytesInsideEnvelope', () {
      // header length 6 covers the body; appending bytes makes the size
      // mismatch (declared 6 but actual 8).
      final out = Uint8List.fromList([
        0x30, 6, 0x02, 1, 1, 0x02, 1, 1, 0x99, 0x99,
      ]);
      expect(() => SmartAccountUtils.parseDerSignature(out),
          throwsA(isA<InvalidInput>()));
    });

    test('parseDerSignature_rIsZero', () {
      final out = Uint8List.fromList([0x30, 6, 0x02, 1, 0, 0x02, 1, 1]);
      expect(() => SmartAccountUtils.parseDerSignature(out),
          throwsA(isA<InvalidInput>()));
    });

    test('parseDerSignature_sIsZero', () {
      final out = Uint8List.fromList([0x30, 6, 0x02, 1, 1, 0x02, 1, 0]);
      expect(() => SmartAccountUtils.parseDerSignature(out),
          throwsA(isA<InvalidInput>()));
    });

    test('parseDerSignature_rExceedsCurveOrder', () {
      final tooBig = _curveOrder + BigInt.one;
      expect(
        () => SmartAccountUtils.parseDerSignature(
            _encodeDerSignature(tooBig, BigInt.one)),
        throwsA(isA<InvalidInput>()),
      );
    });

    test('parseDerSignature_sExceedsCurveOrder', () {
      final tooBig = _curveOrder + BigInt.one;
      expect(
        () => SmartAccountUtils.parseDerSignature(
            _encodeDerSignature(BigInt.one, tooBig)),
        throwsA(isA<InvalidInput>()),
      );
    });

    test('parseDerSignature_rJustBelowCurveOrder', () {
      final justBelow = _curveOrder - BigInt.one;
      final out = SmartAccountUtils.parseDerSignature(
        _encodeDerSignature(justBelow, BigInt.one),
      );
      expect(out[0], justBelow);
    });
  });

  group('normalizeSignature', () {
    test('test_normalize_low_s_already_compact', () {
      final s = _halfOrder - BigInt.one;
      final r = BigInt.from(7);
      final sig = SmartAccountUtils.normalizeSignature(_encodeDerSignature(r, s));
      expect(sig.length, 64);
      // S should be unchanged.
      expect(sig.sublist(32), _bigIntToFixedBytes(s, 32));
    });

    test('test_normalize_high_s_flipped', () {
      final s = _halfOrder + BigInt.one;
      final r = BigInt.from(7);
      final sig =
          SmartAccountUtils.normalizeSignature(_encodeDerSignature(r, s));
      expect(sig.length, 64);
      final expected = _curveOrder - s;
      expect(sig.sublist(32), _bigIntToFixedBytes(expected, 32));
    });

    test('test_normalize_low_s_boundary_value', () {
      final s = _halfOrder; // boundary -- not >, not flipped
      final r = BigInt.from(7);
      final sig =
          SmartAccountUtils.normalizeSignature(_encodeDerSignature(r, s));
      expect(sig.sublist(32), _bigIntToFixedBytes(s, 32));
    });

    test('test_normalize_der_truncated_rejected', () {
      expect(
        () => SmartAccountUtils.normalizeSignature(Uint8List(4)),
        throwsA(isA<InvalidInput>()),
      );
    });

    test('test_normalize_der_padded_with_leading_zero_handled', () {
      // R has the high bit set, so the encoder prepends 0x00; the parser
      // must strip the leading zero and accept R as a valid 32-byte
      // value.
      final r = BigInt.parse(
        '80aabbccddeeff00112233445566778899aabbccddeeff0011223344556677',
        radix: 16,
      );
      final s = BigInt.from(99);
      final sig =
          SmartAccountUtils.normalizeSignature(_encodeDerSignature(r, s));
      expect(sig.length, 64);
    });

    test('test_normalize_signature_length_zero_rejected', () {
      expect(
        () => SmartAccountUtils.normalizeSignature(Uint8List(0)),
        throwsA(isA<InvalidInput>()),
      );
    });

    test('test_normalize_off_curve_signature_rejected', () {
      // 0 is rejected because rIsZero.
      expect(
        () => SmartAccountUtils.normalizeSignature(
            _encodeDerSignature(BigInt.zero, BigInt.one)),
        throwsA(isA<InvalidInput>()),
      );
    });

    test('test_normalize_returns_64_byte_compact_r_concat_s', () {
      final r = BigInt.from(0x12);
      final s = BigInt.from(0x34);
      final sig =
          SmartAccountUtils.normalizeSignature(_encodeDerSignature(r, s));
      expect(sig.length, 64);
      // Top 31 bytes of R should be zero, last byte = 0x12.
      for (var i = 0; i < 31; i++) {
        expect(sig[i], 0);
      }
      expect(sig[31], 0x12);
      expect(sig[63], 0x34);
    });

    test('test_normalize_fuzz_1000_seeded_rng_no_panic', () {
      final rng = Random(0xCAFEBABE);
      var validCount = 0;
      var invalidCount = 0;
      for (var i = 0; i < 1000; i++) {
        final length = rng.nextInt(80) + 1;
        final input = Uint8List(length);
        for (var j = 0; j < length; j++) {
          input[j] = rng.nextInt(256);
        }
        try {
          final out = SmartAccountUtils.normalizeSignature(input);
          expect(out.length, 64);
          validCount++;
        } on InvalidInput {
          invalidCount++;
        } catch (e) {
          fail('Unexpected error type: $e');
        }
      }
      expect(validCount + invalidCount, 1000);
    });

    test('testNormalizeSignature_alreadyLowS', () {
      final r = BigInt.from(0x42);
      final s = BigInt.from(0x100);
      final sig =
          SmartAccountUtils.normalizeSignature(_encodeDerSignature(r, s));
      expect(sig.sublist(32), _bigIntToFixedBytes(s, 32));
    });

    test('testNormalizeSignature_highSToLowS', () {
      final r = BigInt.from(7);
      final s = _halfOrder + BigInt.one;
      final sig =
          SmartAccountUtils.normalizeSignature(_encodeDerSignature(r, s));
      // Flipped to n - s.
      expect(sig.sublist(32), _bigIntToFixedBytes(_curveOrder - s, 32));
    });

    test('testNormalizeSignature_exactHalfOrder', () {
      final sig = SmartAccountUtils.normalizeSignature(
          _encodeDerSignature(BigInt.one, _halfOrder));
      expect(sig.sublist(32), _bigIntToFixedBytes(_halfOrder, 32));
    });

    test('testNormalizeSignature_halfOrderPlusOne', () {
      final s = _halfOrder + BigInt.one;
      final sig = SmartAccountUtils.normalizeSignature(
          _encodeDerSignature(BigInt.one, s));
      expect(sig.sublist(32), _bigIntToFixedBytes(_curveOrder - s, 32));
    });

    test('testNormalizeSignature_invalidHeader', () {
      final out = Uint8List.fromList([0x31, 6, 0x02, 1, 1, 0x02, 1, 1]);
      expect(() => SmartAccountUtils.normalizeSignature(out),
          throwsA(isA<InvalidInput>()));
    });

    test('testNormalizeSignature_missingRMarker', () {
      final out = Uint8List.fromList([0x30, 6, 0x99, 1, 1, 0x02, 1, 1]);
      expect(() => SmartAccountUtils.normalizeSignature(out),
          throwsA(isA<InvalidInput>()));
    });

    test('testNormalizeSignature_missingSMarker', () {
      final out = Uint8List.fromList([0x30, 6, 0x02, 1, 1, 0x99, 1, 1]);
      expect(() => SmartAccountUtils.normalizeSignature(out),
          throwsA(isA<InvalidInput>()));
    });

    test('testNormalizeSignature_truncated', () {
      final out = Uint8List.fromList([0x30, 4, 0x02, 5, 1]);
      expect(() => SmartAccountUtils.normalizeSignature(out),
          throwsA(isA<InvalidInput>()));
    });
  });

  group('extractPublicKeyFromRegistration', () {
    test('test_extract_strategy1_direct_cose_key', () {
      final pk = _generatorPubkey();
      final out = SmartAccountUtils.extractPublicKeyFromRegistration(
        publicKey: pk,
      );
      expect(out, pk);
    });

    test('test_extract_returns_65_byte_uncompressed_with_0x04_prefix', () {
      final pk = _generatorPubkey();
      final out = SmartAccountUtils.extractPublicKeyFromRegistration(
        publicKey: pk,
      );
      expect(out.length, 65);
      expect(out[0], 0x04);
    });

    test('test_extract_compressed_key_rejected', () {
      final pk = Uint8List(33);
      pk[0] = 0x02;
      expect(
        () => SmartAccountUtils.extractPublicKeyFromRegistration(publicKey: pk),
        throwsA(isA<InvalidInput>()),
      );
      pk[0] = 0x03;
      expect(
        () => SmartAccountUtils.extractPublicKeyFromRegistration(publicKey: pk),
        throwsA(isA<InvalidInput>()),
      );
    });

    test('test_extract_off_curve_point_rejected', () {
      final pk = Uint8List(65);
      pk[0] = 0x04;
      // Set X = 1 and Y = 1 -- not on curve.
      pk[32] = 1;
      pk[64] = 1;
      expect(
        () => SmartAccountUtils.extractPublicKeyFromRegistration(publicKey: pk),
        throwsA(isA<InvalidInput>()),
      );
    });

    test('test_extract_strategy_fallback_order_strategy1_first', () {
      final pk = _generatorPubkey();
      final attest = Uint8List.fromList([
        0xFF, 0xFF, 0xFF, // junk
      ]);
      final out = SmartAccountUtils.extractPublicKeyFromRegistration(
        publicKey: pk,
        attestationObject: attest,
      );
      expect(out, pk);
    });

    test('test_extract_cose_key_missing_rejected', () {
      // Provide attestation object that lacks the COSE prefix.
      final attest = Uint8List.fromList(List<int>.generate(200, (i) => i));
      expect(
        () => SmartAccountUtils.extractPublicKeyFromRegistration(
            attestationObject: attest),
        throwsA(isA<InvalidInput>()),
      );
    });

    test('test_extract_attestation_object_parse_failure_rejected', () {
      final attest = Uint8List(50);
      expect(
        () => SmartAccountUtils.extractPublicKeyFromRegistration(
            attestationObject: attest),
        throwsA(isA<InvalidInput>()),
      );
    });

    test('test_extract_strategy3_from_attestation_object', () {
      // Build a synthetic attestation object that contains the COSE prefix
      // followed by the generator-point coordinates.
      final pkx = _bigIntToFixedBytes(_gx, 32);
      final pky = _bigIntToFixedBytes(_gy, 32);
      final attest = Uint8List.fromList([
        0x99, 0x88, // garbage prefix
        0xA5, 0x01, 0x02, 0x03, 0x26, 0x20, 0x01, 0x21, 0x58, 0x20,
        ...pkx,
        0x22, 0x58, 0x20,
        ...pky,
      ]);
      final out = SmartAccountUtils.extractPublicKeyFromRegistration(
        attestationObject: attest,
      );
      expect(out.length, 65);
      expect(out[0], 0x04);
    });

    test('test_extract_strategy2_from_authenticator_data', () {
      final pkx = _bigIntToFixedBytes(_gx, 32);
      final pky = _bigIntToFixedBytes(_gy, 32);
      final credentialId = Uint8List.fromList([1, 2, 3, 4]);
      final builder = <int>[
        ...List<int>.filled(32, 0xAA), // rpIdHash
        0x40, // flags with AT bit (0x40)
        0, 0, 0, 0, // sign count
        ...List<int>.filled(16, 0xBB), // aaguid
        0, credentialId.length, // credentialIdLen big-endian
        ...credentialId,
        0xA5, 0x01, 0x02, 0x03, 0x26, 0x20, 0x01, 0x21, 0x58, 0x20,
        ...pkx,
        0x22, 0x58, 0x20,
        ...pky,
      ];
      final out = SmartAccountUtils.extractPublicKeyFromRegistration(
        authenticatorData: Uint8List.fromList(builder),
      );
      expect(out.length, 65);
      expect(out[0], 0x04);
    });

    test('extractPublicKey_noParametersThrows', () {
      expect(
        () => SmartAccountUtils.extractPublicKeyFromRegistration(),
        throwsA(isA<InvalidInput>()),
      );
    });

    test('extractPublicKey_emptyPublicKeyFallsThrough', () {
      // Empty publicKey -> falls through; with no other source -> throws.
      expect(
        () => SmartAccountUtils.extractPublicKeyFromRegistration(
            publicKey: Uint8List(0)),
        throwsA(isA<InvalidInput>()),
      );
    });

    test('extractPublicKey_directKeyOffCurveThrows', () {
      final pk = Uint8List(65);
      pk[0] = 0x04;
      // Coordinates contain non-zero garbage that is not on curve.
      pk[20] = 0xFF;
      pk[60] = 0xFF;
      expect(
        () => SmartAccountUtils.extractPublicKeyFromRegistration(publicKey: pk),
        throwsA(isA<InvalidInput>()),
      );
    });

    test('extractPublicKey_directKeyZeroCoordinatesThrows', () {
      final pk = Uint8List(65);
      pk[0] = 0x04;
      // X = 0, Y = 0 -> point at infinity, must be rejected.
      expect(
        () => SmartAccountUtils.extractPublicKeyFromRegistration(publicKey: pk),
        throwsA(isA<InvalidInput>()),
      );
    });

    test('extractPublicKey_directKeyCoordinatesExceedFieldPrime', () {
      final pk = Uint8List(65);
      pk[0] = 0x04;
      // Set coordinates to all-0xFF (greater than the field prime).
      for (var i = 1; i < 65; i++) {
        pk[i] = 0xFF;
      }
      expect(
        () => SmartAccountUtils.extractPublicKeyFromRegistration(publicKey: pk),
        throwsA(isA<InvalidInput>()),
      );
    });

    test('extractPublicKey_nonKeyDataFallsThroughToError', () {
      final pk = Uint8List(20);
      pk[0] = 0x99; // not 0x04, 0x02, or 0x03 -> falls through
      expect(
        () =>
            SmartAccountUtils.extractPublicKeyFromRegistration(publicKey: pk),
        throwsA(isA<InvalidInput>()),
      );
    });
  });

  group('extractPublicKeyFromAuthenticatorData', () {
    test('testExtractPublicKeyFromAuthenticatorData_tooShort', () {
      final out = SmartAccountUtils.extractPublicKeyFromAuthenticatorData(
        Uint8List(10),
      );
      expect(out, isNull);
    });

    test('testExtractPublicKeyFromAuthenticatorData_noATFlag', () {
      final data = Uint8List(200);
      // flags byte at index 32 is 0 -> AT not set.
      final out =
          SmartAccountUtils.extractPublicKeyFromAuthenticatorData(data);
      expect(out, isNull);
    });

    test('testExtractPublicKeyFromAuthenticatorData_truncatedCOSEKey', () {
      final builder = <int>[
        ...List<int>.filled(32, 0xAA),
        0x40,
        0, 0, 0, 0,
        ...List<int>.filled(16, 0xBB),
        0, 0, // credentialIdLen = 0
        // No COSE key follows.
      ];
      final out = SmartAccountUtils.extractPublicKeyFromAuthenticatorData(
        Uint8List.fromList(builder),
      );
      expect(out, isNull);
    });

    test(
        'testExtractPublicKeyFromAuthenticatorData_wrongCosePrefixReturnsNull',
        () {
      final pkx = _bigIntToFixedBytes(_gx, 32);
      final pky = _bigIntToFixedBytes(_gy, 32);
      final builder = <int>[
        ...List<int>.filled(32, 0xAA),
        0x40,
        0, 0, 0, 0,
        ...List<int>.filled(16, 0xBB),
        0, 0,
        // Wrong COSE prefix - first byte 0xFF.
        0xFF, 0x01, 0x02, 0x03, 0x26, 0x20, 0x01, 0x21, 0x58, 0x20,
        ...pkx,
        0x22, 0x58, 0x20,
        ...pky,
      ];
      final out = SmartAccountUtils.extractPublicKeyFromAuthenticatorData(
        Uint8List.fromList(builder),
      );
      expect(out, isNull);
    });

    test('testExtractPublicKeyFromAuthenticatorData_truncatedAfterXReturnsNull',
        () {
      final pkx = _bigIntToFixedBytes(_gx, 32);
      final builder = <int>[
        ...List<int>.filled(32, 0xAA),
        0x40,
        0, 0, 0, 0,
        ...List<int>.filled(16, 0xBB),
        0, 0,
        0xA5, 0x01, 0x02, 0x03, 0x26, 0x20, 0x01, 0x21, 0x58, 0x20,
        ...pkx,
        // Truncated -- no Y data.
      ];
      final out = SmartAccountUtils.extractPublicKeyFromAuthenticatorData(
        Uint8List.fromList(builder),
      );
      expect(out, isNull);
    });

    test('testExtractPublicKeyFromAuthenticatorData_wrongYMarkerThrows', () {
      final pkx = _bigIntToFixedBytes(_gx, 32);
      final pky = _bigIntToFixedBytes(_gy, 32);
      final builder = <int>[
        ...List<int>.filled(32, 0xAA),
        0x40,
        0, 0, 0, 0,
        ...List<int>.filled(16, 0xBB),
        0, 0,
        0xA5, 0x01, 0x02, 0x03, 0x26, 0x20, 0x01, 0x21, 0x58, 0x20,
        ...pkx,
        0x99, 0x99, 0x99, // wrong Y marker
        ...pky,
      ];
      expect(
        () => SmartAccountUtils.extractPublicKeyFromAuthenticatorData(
            Uint8List.fromList(builder)),
        throwsA(isA<InvalidInput>()),
      );
    });

    test('extractPublicKeyFromAuthData_offCurveCoordinatesThrow', () {
      final builder = <int>[
        ...List<int>.filled(32, 0xAA),
        0x40,
        0, 0, 0, 0,
        ...List<int>.filled(16, 0xBB),
        0, 0,
        0xA5, 0x01, 0x02, 0x03, 0x26, 0x20, 0x01, 0x21, 0x58, 0x20,
        ...List<int>.filled(32, 0x42), // off-curve X
        0x22, 0x58, 0x20,
        ...List<int>.filled(32, 0x42), // off-curve Y
      ];
      expect(
        () => SmartAccountUtils.extractPublicKeyFromAuthenticatorData(
            Uint8List.fromList(builder)),
        throwsA(isA<InvalidInput>()),
      );
    });

    test('testExtractPublicKeyFromAuthenticatorData_longCredentialId', () {
      final pkx = _bigIntToFixedBytes(_gx, 32);
      final pky = _bigIntToFixedBytes(_gy, 32);
      final credId = List<int>.filled(255, 0xCC);
      final builder = <int>[
        ...List<int>.filled(32, 0xAA),
        0x40,
        0, 0, 0, 0,
        ...List<int>.filled(16, 0xBB),
        0, credId.length,
        ...credId,
        0xA5, 0x01, 0x02, 0x03, 0x26, 0x20, 0x01, 0x21, 0x58, 0x20,
        ...pkx,
        0x22, 0x58, 0x20,
        ...pky,
      ];
      final out = SmartAccountUtils.extractPublicKeyFromAuthenticatorData(
        Uint8List.fromList(builder),
      );
      expect(out, isNotNull);
      expect(out!.length, 65);
    });

    test('testExtractPublicKeyFromAuthenticatorData_bigEndianCredIdLength', () {
      final pkx = _bigIntToFixedBytes(_gx, 32);
      final pky = _bigIntToFixedBytes(_gy, 32);
      final credId = List<int>.filled(258, 0xCD);
      // 258 = 0x0102 -> high byte 0x01, low byte 0x02.
      final builder = <int>[
        ...List<int>.filled(32, 0xAA),
        0x40,
        0, 0, 0, 0,
        ...List<int>.filled(16, 0xBB),
        0x01, 0x02,
        ...credId,
        0xA5, 0x01, 0x02, 0x03, 0x26, 0x20, 0x01, 0x21, 0x58, 0x20,
        ...pkx,
        0x22, 0x58, 0x20,
        ...pky,
      ];
      final out = SmartAccountUtils.extractPublicKeyFromAuthenticatorData(
        Uint8List.fromList(builder),
      );
      expect(out, isNotNull);
    });
  });

  group('extractPublicKeyFromAttestationObject', () {
    test('testExtractPublicKeyFromAttestationObject_validCOSEPrefix', () {
      final pkx = _bigIntToFixedBytes(_gx, 32);
      final pky = _bigIntToFixedBytes(_gy, 32);
      final attest = Uint8List.fromList([
        0xFF, 0xFE,
        0xA5, 0x01, 0x02, 0x03, 0x26, 0x20, 0x01, 0x21, 0x58, 0x20,
        ...pkx,
        0x22, 0x58, 0x20,
        ...pky,
      ]);
      final out =
          SmartAccountUtils.extractPublicKeyFromAttestationObject(attest);
      expect(out.length, 65);
    });

    test('testExtractPublicKeyFromAttestationObject_missingCOSEPrefix', () {
      final attest = Uint8List.fromList(List<int>.generate(150, (i) => i));
      expect(
        () => SmartAccountUtils.extractPublicKeyFromAttestationObject(attest),
        throwsA(isA<InvalidInput>()),
      );
    });

    test('testExtractPublicKeyFromAttestationObject_truncatedAfterPrefix', () {
      final attest = Uint8List.fromList([
        0xA5, 0x01, 0x02, 0x03, 0x26, 0x20, 0x01, 0x21, 0x58, 0x20,
        // truncated
      ]);
      expect(
        () => SmartAccountUtils.extractPublicKeyFromAttestationObject(attest),
        throwsA(isA<InvalidInput>()),
      );
    });

    test('testExtractPublicKeyFromAttestationObject_wrongYMarkerThrows', () {
      final pkx = _bigIntToFixedBytes(_gx, 32);
      final pky = _bigIntToFixedBytes(_gy, 32);
      final attest = Uint8List.fromList([
        0xA5, 0x01, 0x02, 0x03, 0x26, 0x20, 0x01, 0x21, 0x58, 0x20,
        ...pkx,
        0xAA, 0xBB, 0xCC, // wrong Y marker
        ...pky,
      ]);
      expect(
        () => SmartAccountUtils.extractPublicKeyFromAttestationObject(attest),
        throwsA(isA<InvalidInput>()),
      );
    });

    test('extractPublicKeyFromAttestation_offCurveThrows', () {
      final attest = Uint8List.fromList([
        0xA5, 0x01, 0x02, 0x03, 0x26, 0x20, 0x01, 0x21, 0x58, 0x20,
        ...List<int>.filled(32, 0x99),
        0x22, 0x58, 0x20,
        ...List<int>.filled(32, 0x99),
      ]);
      expect(
        () => SmartAccountUtils.extractPublicKeyFromAttestationObject(attest),
        throwsA(isA<InvalidInput>()),
      );
    });
  });

  group('on-curve validation', () {
    test('testOnCurveValidation_generatorPointAccepted', () {
      final pk = _generatorPubkey();
      expect(
        SmartAccountUtils.extractPublicKeyFromRegistration(publicKey: pk),
        pk,
      );
    });

    test('testOnCurveValidation_offCurvePointRejected_authData', () {
      final builder = <int>[
        ...List<int>.filled(32, 0xAA),
        0x40,
        0, 0, 0, 0,
        ...List<int>.filled(16, 0xBB),
        0, 0,
        0xA5, 0x01, 0x02, 0x03, 0x26, 0x20, 0x01, 0x21, 0x58, 0x20,
        ...List<int>.filled(32, 0x42),
        0x22, 0x58, 0x20,
        ...List<int>.filled(32, 0x42),
      ];
      expect(
        () => SmartAccountUtils.extractPublicKeyFromAuthenticatorData(
            Uint8List.fromList(builder)),
        throwsA(isA<InvalidInput>()),
      );
    });

    test('testOnCurveValidation_offCurvePointRejected_attestationObject', () {
      final attest = Uint8List.fromList([
        0xA5, 0x01, 0x02, 0x03, 0x26, 0x20, 0x01, 0x21, 0x58, 0x20,
        ...List<int>.filled(32, 0x42),
        0x22, 0x58, 0x20,
        ...List<int>.filled(32, 0x42),
      ]);
      expect(
        () => SmartAccountUtils.extractPublicKeyFromAttestationObject(attest),
        throwsA(isA<InvalidInput>()),
      );
    });

    test('testOnCurveValidation_zeroXRejected', () {
      final pk = Uint8List(65);
      pk[0] = 0x04;
      pk.setRange(33, 65, _bigIntToFixedBytes(_gy, 32));
      expect(
        () => SmartAccountUtils.extractPublicKeyFromRegistration(publicKey: pk),
        throwsA(isA<InvalidInput>()),
      );
    });

    test('testOnCurveValidation_zeroYRejected', () {
      final pk = Uint8List(65);
      pk[0] = 0x04;
      pk.setRange(1, 33, _bigIntToFixedBytes(_gx, 32));
      expect(
        () => SmartAccountUtils.extractPublicKeyFromRegistration(publicKey: pk),
        throwsA(isA<InvalidInput>()),
      );
    });

    test('testOnCurveValidation_xExceedsFieldPrimeRejected', () {
      final pk = Uint8List(65);
      pk[0] = 0x04;
      // X = all 0xFF -- exceeds field prime.
      for (var i = 1; i < 33; i++) {
        pk[i] = 0xFF;
      }
      pk.setRange(33, 65, _bigIntToFixedBytes(_gy, 32));
      expect(
        () => SmartAccountUtils.extractPublicKeyFromRegistration(publicKey: pk),
        throwsA(isA<InvalidInput>()),
      );
    });

    test('testOnCurveValidation_yExceedsFieldPrimeRejected', () {
      final pk = Uint8List(65);
      pk[0] = 0x04;
      pk.setRange(1, 33, _bigIntToFixedBytes(_gx, 32));
      for (var i = 33; i < 65; i++) {
        pk[i] = 0xFF;
      }
      expect(
        () => SmartAccountUtils.extractPublicKeyFromRegistration(publicKey: pk),
        throwsA(isA<InvalidInput>()),
      );
    });
  });

  group('getContractSalt', () {
    test('getContractSalt_deterministicForSameInput', () {
      final cred = Uint8List.fromList([1, 2, 3, 4]);
      final s1 = SmartAccountUtils.getContractSalt(cred);
      final s2 = SmartAccountUtils.getContractSalt(cred);
      expect(s1, s2);
      expect(s1.length, 32);
    });

    test('getContractSalt_differentInputsDifferentSalts', () {
      final s1 = SmartAccountUtils.getContractSalt(
          Uint8List.fromList([1]));
      final s2 = SmartAccountUtils.getContractSalt(
          Uint8List.fromList([2]));
      expect(s1, isNot(s2));
    });

    test('getContractSalt_emptyInput', () {
      final s1 = SmartAccountUtils.getContractSalt(Uint8List(0));
      expect(s1.length, 32);
    });
  });

  group('deriveContractAddress', () {
    test('deriveContractAddress_returnsValidCAddress', () {
      final addr = SmartAccountUtils.deriveContractAddress(
        credentialId: Uint8List.fromList([1, 2, 3]),
        deployerPublicKey:
            'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX',
        networkPassphrase: 'Test SDF Network ; September 2015',
      );
      expect(StrKey.isValidContractId(addr), isTrue);
    });

    test('deriveContractAddress_deterministic', () {
      const deployer =
          'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';
      final a1 = SmartAccountUtils.deriveContractAddress(
        credentialId: Uint8List.fromList([1, 2, 3]),
        deployerPublicKey: deployer,
        networkPassphrase: 'Test SDF Network ; September 2015',
      );
      final a2 = SmartAccountUtils.deriveContractAddress(
        credentialId: Uint8List.fromList([1, 2, 3]),
        deployerPublicKey: deployer,
        networkPassphrase: 'Test SDF Network ; September 2015',
      );
      expect(a1, a2);
    });

    test('deriveContractAddress_differentCredentialIdsDifferentAddresses',
        () {
      const deployer =
          'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';
      final a1 = SmartAccountUtils.deriveContractAddress(
        credentialId: Uint8List.fromList([1]),
        deployerPublicKey: deployer,
        networkPassphrase: 'Test SDF Network ; September 2015',
      );
      final a2 = SmartAccountUtils.deriveContractAddress(
        credentialId: Uint8List.fromList([2]),
        deployerPublicKey: deployer,
        networkPassphrase: 'Test SDF Network ; September 2015',
      );
      expect(a1, isNot(a2));
    });

    test('deriveContractAddress_differentNetworksDifferentAddresses',
        () {
      const deployer =
          'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';
      final a1 = SmartAccountUtils.deriveContractAddress(
        credentialId: Uint8List.fromList([1]),
        deployerPublicKey: deployer,
        networkPassphrase: 'Test SDF Network ; September 2015',
      );
      final a2 = SmartAccountUtils.deriveContractAddress(
        credentialId: Uint8List.fromList([1]),
        deployerPublicKey: deployer,
        networkPassphrase:
            'Public Global Stellar Network ; September 2015',
      );
      expect(a1, isNot(a2));
    });

    test('deriveContractAddress_invalidDeployerKeyThrows', () {
      expect(
        () => SmartAccountUtils.deriveContractAddress(
          credentialId: Uint8List.fromList([1]),
          deployerPublicKey: 'NOT_A_VALID_KEY',
          networkPassphrase: 'Test SDF Network ; September 2015',
        ),
        throwsA(isA<InvalidAddress>()),
      );
    });
  });

  group('findSubarray', () {
    test('findSubarray_findsAtBeginning', () {
      expect(
          SmartAccountUtils.findSubarray(
              Uint8List.fromList([1, 2, 3, 4]), Uint8List.fromList([1, 2])),
          0);
    });

    test('findSubarray_findsInMiddle', () {
      expect(
          SmartAccountUtils.findSubarray(
              Uint8List.fromList([1, 2, 3, 4]), Uint8List.fromList([2, 3])),
          1);
    });

    test('findSubarray_findsAtEnd', () {
      expect(
          SmartAccountUtils.findSubarray(
              Uint8List.fromList([1, 2, 3, 4]), Uint8List.fromList([3, 4])),
          2);
    });

    test('findSubarray_notFound', () {
      expect(
          SmartAccountUtils.findSubarray(
              Uint8List.fromList([1, 2, 3, 4]), Uint8List.fromList([5])),
          -1);
    });

    test('findSubarray_emptySubarray', () {
      expect(
          SmartAccountUtils.findSubarray(
              Uint8List.fromList([1, 2, 3]), Uint8List(0)),
          -1);
    });

    test('findSubarray_subarrayLargerThanArray', () {
      expect(
          SmartAccountUtils.findSubarray(
              Uint8List.fromList([1]), Uint8List.fromList([1, 2, 3])),
          -1);
    });

    test('findSubarray_exactMatch', () {
      expect(
          SmartAccountUtils.findSubarray(
              Uint8List.fromList([1, 2, 3]), Uint8List.fromList([1, 2, 3])),
          0);
    });

    test('findSubarray_singleByteMatch', () {
      expect(
          SmartAccountUtils.findSubarray(
              Uint8List.fromList([1, 2, 3]), Uint8List.fromList([2])),
          1);
    });

    test('findSubarray_firstOccurrence', () {
      expect(
          SmartAccountUtils.findSubarray(
              Uint8List.fromList([1, 2, 1, 2, 1, 2]),
              Uint8List.fromList([1, 2])),
          0);
    });

    test('findSubarray_bothEmpty', () {
      expect(SmartAccountUtils.findSubarray(Uint8List(0), Uint8List(0)), -1);
    });
  });
}
