// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('XDR Other Types - XdrEnvelopeType', () {
    test('XdrEnvelopeType enum all values encode/decode', () {
      final types = [
        XdrEnvelopeType.ENVELOPE_TYPE_TX_V0,
        XdrEnvelopeType.ENVELOPE_TYPE_SCP,
        XdrEnvelopeType.ENVELOPE_TYPE_TX,
        XdrEnvelopeType.ENVELOPE_TYPE_AUTH,
        XdrEnvelopeType.ENVELOPE_TYPE_SCPVALUE,
        XdrEnvelopeType.ENVELOPE_TYPE_TX_FEE_BUMP,
        XdrEnvelopeType.ENVELOPE_TYPE_OP_ID,
        XdrEnvelopeType.ENVELOPE_TYPE_POOL_REVOKE_OP_ID,
        XdrEnvelopeType.ENVELOPE_TYPE_CONTRACT_ID,
        XdrEnvelopeType.ENVELOPE_TYPE_SOROBAN_AUTHORIZATION,
      ];

      for (var type in types) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrEnvelopeType.encode(output, type);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrEnvelopeType.decode(input);

        expect(decoded.value, equals(type.value));
      }
    });

    test('XdrEnvelopeType value mapping verification', () {
      expect(XdrEnvelopeType.ENVELOPE_TYPE_TX_V0.value, equals(0));
      expect(XdrEnvelopeType.ENVELOPE_TYPE_SCP.value, equals(1));
      expect(XdrEnvelopeType.ENVELOPE_TYPE_TX.value, equals(2));
      expect(XdrEnvelopeType.ENVELOPE_TYPE_AUTH.value, equals(3));
      expect(XdrEnvelopeType.ENVELOPE_TYPE_SCPVALUE.value, equals(4));
      expect(XdrEnvelopeType.ENVELOPE_TYPE_TX_FEE_BUMP.value, equals(5));
      expect(XdrEnvelopeType.ENVELOPE_TYPE_OP_ID.value, equals(6));
      expect(XdrEnvelopeType.ENVELOPE_TYPE_POOL_REVOKE_OP_ID.value, equals(7));
      expect(XdrEnvelopeType.ENVELOPE_TYPE_CONTRACT_ID.value, equals(8));
      expect(XdrEnvelopeType.ENVELOPE_TYPE_SOROBAN_AUTHORIZATION.value, equals(9));
    });

    test('XdrEnvelopeType decode invalid value throws exception', () {
      XdrDataOutputStream output = XdrDataOutputStream();
      output.writeInt(999);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      expect(() => XdrEnvelopeType.decode(input), throwsException);
    });
  });

  group('XDR Other Types - XdrSignerKey', () {
    test('XdrSignerKeyType enum values encode/decode', () {
      final types = [
        XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519,
        XdrSignerKeyType.SIGNER_KEY_TYPE_PRE_AUTH_TX,
        XdrSignerKeyType.SIGNER_KEY_TYPE_HASH_X,
        XdrSignerKeyType.KEY_TYPE_ED25519_SIGNED_PAYLOAD,
        XdrSignerKeyType.KEY_TYPE_MUXED_ED25519,
      ];

      for (var type in types) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrSignerKeyType.encode(output, type);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrSignerKeyType.decode(input);

        expect(decoded.value, equals(type.value));
      }
    });

    test('XdrSignerKeyType value mapping', () {
      expect(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519.value, equals(0));
      expect(XdrSignerKeyType.SIGNER_KEY_TYPE_PRE_AUTH_TX.value, equals(1));
      expect(XdrSignerKeyType.SIGNER_KEY_TYPE_HASH_X.value, equals(2));
      expect(XdrSignerKeyType.KEY_TYPE_ED25519_SIGNED_PAYLOAD.value, equals(3));
      expect(XdrSignerKeyType.KEY_TYPE_MUXED_ED25519.value, equals(0x100));
    });

    test('XdrSignerKey SIGNER_KEY_TYPE_ED25519 encode/decode round-trip', () {
      var original = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519);
      original.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAB)));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSignerKey.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSignerKey.decode(input);

      expect(decoded.discriminant.value, equals(original.discriminant.value));
      expect(decoded.ed25519!.uint256, equals(original.ed25519!.uint256));
    });

    test('XdrSignerKey SIGNER_KEY_TYPE_PRE_AUTH_TX encode/decode round-trip', () {
      var original = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_PRE_AUTH_TX);
      original.preAuthTx = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xCD)));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSignerKey.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSignerKey.decode(input);

      expect(decoded.discriminant.value, equals(original.discriminant.value));
      expect(decoded.preAuthTx!.uint256, equals(original.preAuthTx!.uint256));
    });

    test('XdrSignerKey SIGNER_KEY_TYPE_HASH_X encode/decode round-trip', () {
      var original = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_HASH_X);
      original.hashX = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xEF)));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSignerKey.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSignerKey.decode(input);

      expect(decoded.discriminant.value, equals(original.discriminant.value));
      expect(decoded.hashX!.uint256, equals(original.hashX!.uint256));
    });

    test('XdrSignerKey KEY_TYPE_ED25519_SIGNED_PAYLOAD encode/decode round-trip', () {
      var ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x12)));
      var payloadBytes = Uint8List.fromList([0x01, 0x02, 0x03, 0x04]);
      var payload = XdrDataValue(payloadBytes);
      var signedPayload = XdrSignedPayload(ed25519, payload);

      var original = XdrSignerKey(XdrSignerKeyType.KEY_TYPE_ED25519_SIGNED_PAYLOAD);
      original.signedPayload = signedPayload;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSignerKey.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSignerKey.decode(input);

      expect(decoded.discriminant.value, equals(original.discriminant.value));
      expect(decoded.signedPayload!.ed25519.uint256, equals(ed25519.uint256));
      expect(decoded.signedPayload!.payload.dataValue, equals(payloadBytes));
    });
  });

  group('XDR Other Types - XdrDecoratedSignature', () {
    test('XdrSignatureHint encode/decode round-trip', () {
      var hintBytes = Uint8List.fromList([0x01, 0x02, 0x03, 0x04]);
      var original = XdrSignatureHint(hintBytes);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSignatureHint.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSignatureHint.decode(input);

      expect(decoded.signatureHint, equals(hintBytes));
      expect(decoded.signatureHint.length, equals(4));
    });

    test('XdrSignature encode/decode round-trip', () {
      var sigBytes = Uint8List.fromList(List.generate(64, (i) => i % 256));
      var original = XdrSignature(sigBytes);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSignature.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSignature.decode(input);

      expect(decoded.signature, equals(sigBytes));
    });

    test('XdrSignature with different lengths', () {
      final lengths = [32, 48, 64, 128];

      for (var length in lengths) {
        var sigBytes = Uint8List.fromList(List.generate(length, (i) => (i * 3) % 256));
        var original = XdrSignature(sigBytes);

        XdrDataOutputStream output = XdrDataOutputStream();
        XdrSignature.encode(output, original);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrSignature.decode(input);

        expect(decoded.signature.length, equals(length));
        expect(decoded.signature, equals(sigBytes));
      }
    });

    test('XdrDecoratedSignature encode/decode round-trip', () {
      var hintBytes = Uint8List.fromList([0xAA, 0xBB, 0xCC, 0xDD]);
      var hint = XdrSignatureHint(hintBytes);
      var sigBytes = Uint8List.fromList(List.generate(64, (i) => i));
      var signature = XdrSignature(sigBytes);

      var original = XdrDecoratedSignature(hint, signature);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrDecoratedSignature.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrDecoratedSignature.decode(input);

      expect(decoded.hint.signatureHint, equals(hintBytes));
      expect(decoded.signature.signature, equals(sigBytes));
    });
  });

  group('XDR Other Types - XdrPublicKey', () {
    test('XdrPublicKeyType enum encode/decode', () {
      var original = XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrPublicKeyType.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrPublicKeyType.decode(input);

      expect(decoded.value, equals(original.value));
      expect(decoded.value, equals(0));
    });

    test('XdrPublicKey PUBLIC_KEY_TYPE_ED25519 encode/decode round-trip', () {
      var keyBytes = Uint8List.fromList(List.generate(32, (i) => (i * 7) % 256));
      var original = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      original.setEd25519(XdrUint256(keyBytes));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrPublicKey.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrPublicKey.decode(input);

      expect(decoded.getDiscriminant().value, equals(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519.value));
      expect(decoded.getEd25519()!.uint256, equals(keyBytes));
    });

    test('XdrPublicKey with all zeros', () {
      var keyBytes = Uint8List.fromList(List<int>.filled(32, 0));
      var original = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      original.setEd25519(XdrUint256(keyBytes));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrPublicKey.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrPublicKey.decode(input);

      expect(decoded.getEd25519()!.uint256, equals(keyBytes));
    });

    test('XdrPublicKey with all ones', () {
      var keyBytes = Uint8List.fromList(List<int>.filled(32, 0xFF));
      var original = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      original.setEd25519(XdrUint256(keyBytes));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrPublicKey.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrPublicKey.decode(input);

      expect(decoded.getEd25519()!.uint256, equals(keyBytes));
    });
  });

  group('XDR Other Types - XdrThresholds', () {
    test('XdrThresholds encode/decode round-trip', () {
      var thresholdBytes = Uint8List.fromList([0x01, 0x02, 0x03, 0x04]);
      var original = XdrThresholds(thresholdBytes);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrThresholds.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrThresholds.decode(input);

      expect(decoded.thresholds, equals(thresholdBytes));
      expect(decoded.thresholds.length, equals(4));
    });

    test('XdrThresholds with different values', () {
      final thresholdSets = [
        Uint8List.fromList([0x00, 0x00, 0x00, 0x00]),
        Uint8List.fromList([0xFF, 0xFF, 0xFF, 0xFF]),
        Uint8List.fromList([0x01, 0x05, 0x0A, 0x14]),
        Uint8List.fromList([0x64, 0x32, 0x16, 0x08]),
      ];

      for (var thresholds in thresholdSets) {
        var original = XdrThresholds(thresholds);

        XdrDataOutputStream output = XdrDataOutputStream();
        XdrThresholds.encode(output, original);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrThresholds.decode(input);

        expect(decoded.thresholds, equals(thresholds));
      }
    });
  });

  group('XDR Other Types - XdrSigner', () {
    test('XdrSigner with ED25519 key encode/decode round-trip', () {
      var signerKey = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519);
      signerKey.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x42)));
      var weight = XdrUint32(10);

      var original = XdrSigner(signerKey, weight);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSigner.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSigner.decode(input);

      expect(decoded.key.discriminant.value, equals(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519.value));
      expect(decoded.key.ed25519!.uint256, equals(signerKey.ed25519!.uint256));
      expect(decoded.weight.uint32, equals(10));
    });

    test('XdrSigner with PRE_AUTH_TX key encode/decode round-trip', () {
      var signerKey = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_PRE_AUTH_TX);
      signerKey.preAuthTx = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x99)));
      var weight = XdrUint32(5);

      var original = XdrSigner(signerKey, weight);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSigner.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSigner.decode(input);

      expect(decoded.key.discriminant.value, equals(XdrSignerKeyType.SIGNER_KEY_TYPE_PRE_AUTH_TX.value));
      expect(decoded.key.preAuthTx!.uint256, equals(signerKey.preAuthTx!.uint256));
      expect(decoded.weight.uint32, equals(5));
    });

    test('XdrSigner with different weights', () {
      final weights = [0, 1, 10, 50, 100, 255];

      for (var weightValue in weights) {
        var signerKey = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519);
        signerKey.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x01)));
        var weight = XdrUint32(weightValue);

        var original = XdrSigner(signerKey, weight);

        XdrDataOutputStream output = XdrDataOutputStream();
        XdrSigner.encode(output, original);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrSigner.decode(input);

        expect(decoded.weight.uint32, equals(weightValue));
      }
    });
  });

  group('XDR Other Types - XdrLiabilities', () {
    test('XdrLiabilities encode/decode round-trip', () {
      var buying = XdrInt64(BigInt.from(1000000));
      var selling = XdrInt64(BigInt.from(2000000));

      var original = XdrLiabilities(buying, selling);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLiabilities.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLiabilities.decode(input);

      expect(decoded.buying.int64, equals(BigInt.from(1000000)));
      expect(decoded.selling.int64, equals(BigInt.from(2000000)));
    });

    test('XdrLiabilities with zero values', () {
      var buying = XdrInt64(BigInt.zero);
      var selling = XdrInt64(BigInt.zero);

      var original = XdrLiabilities(buying, selling);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLiabilities.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLiabilities.decode(input);

      expect(decoded.buying.int64, equals(BigInt.zero));
      expect(decoded.selling.int64, equals(BigInt.zero));
    });

    test('XdrLiabilities with max int64 values', () {
      var buying = XdrInt64(BigInt.parse('9223372036854775807'));
      var selling = XdrInt64(BigInt.parse('9223372036854775807'));

      var original = XdrLiabilities(buying, selling);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLiabilities.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLiabilities.decode(input);

      expect(decoded.buying.int64, equals(BigInt.parse('9223372036854775807')));
      expect(decoded.selling.int64, equals(BigInt.parse('9223372036854775807')));
    });

    test('XdrLiabilities with negative values', () {
      var buying = XdrInt64(BigInt.from(-1000000));
      var selling = XdrInt64(BigInt.from(-2000000));

      var original = XdrLiabilities(buying, selling);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLiabilities.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLiabilities.decode(input);

      expect(decoded.buying.int64, equals(BigInt.from(-1000000)));
      expect(decoded.selling.int64, equals(BigInt.from(-2000000)));
    });
  });

  group('XDR Other Types - XdrPrice', () {
    test('XdrPrice encode/decode round-trip', () {
      var n = XdrInt32(10);
      var d = XdrInt32(3);

      var original = XdrPrice(n, d);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrPrice.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrPrice.decode(input);

      expect(decoded.n.int32, equals(10));
      expect(decoded.d.int32, equals(3));
    });

    test('XdrPrice with different ratios', () {
      final priceRatios = [
        [1, 1],
        [1, 2],
        [2, 1],
        [100, 99],
        [1000000, 1],
        [1, 1000000],
      ];

      for (var ratio in priceRatios) {
        var n = XdrInt32(ratio[0]);
        var d = XdrInt32(ratio[1]);

        var original = XdrPrice(n, d);

        XdrDataOutputStream output = XdrDataOutputStream();
        XdrPrice.encode(output, original);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrPrice.decode(input);

        expect(decoded.n.int32, equals(ratio[0]));
        expect(decoded.d.int32, equals(ratio[1]));
      }
    });

    test('XdrPrice with max int32 values', () {
      var n = XdrInt32(2147483647);
      var d = XdrInt32(2147483647);

      var original = XdrPrice(n, d);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrPrice.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrPrice.decode(input);

      expect(decoded.n.int32, equals(2147483647));
      expect(decoded.d.int32, equals(2147483647));
    });

    test('XdrPrice with negative numerator', () {
      var n = XdrInt32(-100);
      var d = XdrInt32(50);

      var original = XdrPrice(n, d);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrPrice.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrPrice.decode(input);

      expect(decoded.n.int32, equals(-100));
      expect(decoded.d.int32, equals(50));
    });
  });

  group('XDR Other Types - XdrSignedPayload', () {
    test('XdrSignedPayload encode/decode round-trip', () {
      var ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x55)));
      var payloadBytes = Uint8List.fromList([0x01, 0x02, 0x03, 0x04, 0x05]);
      var payload = XdrDataValue(payloadBytes);

      var original = XdrSignedPayload(ed25519, payload);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSignedPayload.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSignedPayload.decode(input);

      expect(decoded.ed25519.uint256, equals(ed25519.uint256));
      expect(decoded.payload.dataValue, equals(payloadBytes));
    });

    test('XdrSignedPayload with empty payload', () {
      var ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x88)));
      var payloadBytes = Uint8List.fromList([]);
      var payload = XdrDataValue(payloadBytes);

      var original = XdrSignedPayload(ed25519, payload);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSignedPayload.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSignedPayload.decode(input);

      expect(decoded.ed25519.uint256, equals(ed25519.uint256));
      expect(decoded.payload.dataValue.length, equals(0));
    });

    test('XdrSignedPayload with large payload', () {
      var ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x77)));
      var payloadBytes = Uint8List.fromList(List.generate(256, (i) => i % 256));
      var payload = XdrDataValue(payloadBytes);

      var original = XdrSignedPayload(ed25519, payload);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSignedPayload.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSignedPayload.decode(input);

      expect(decoded.ed25519.uint256, equals(ed25519.uint256));
      expect(decoded.payload.dataValue, equals(payloadBytes));
      expect(decoded.payload.dataValue.length, equals(256));
    });
  });

  group('XDR Other Types - Complex Scenarios', () {
    test('Multiple XdrDecoratedSignature in sequence', () {
      var signatures = <XdrDecoratedSignature>[];

      for (var i = 0; i < 5; i++) {
        var hint = XdrSignatureHint(Uint8List.fromList([i, i + 1, i + 2, i + 3]));
        var sig = XdrSignature(Uint8List.fromList(List.generate(64, (j) => (i + j) % 256)));
        signatures.add(XdrDecoratedSignature(hint, sig));
      }

      XdrDataOutputStream output = XdrDataOutputStream();
      for (var sig in signatures) {
        XdrDecoratedSignature.encode(output, sig);
      }
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      for (var i = 0; i < 5; i++) {
        var decoded = XdrDecoratedSignature.decode(input);
        expect(decoded.hint.signatureHint[0], equals(i));
        expect(decoded.signature.signature.length, equals(64));
      }
    });

    test('Multiple XdrSigner with different types', () {
      var signers = <XdrSigner>[];

      var ed25519Key = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519);
      ed25519Key.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x01)));
      signers.add(XdrSigner(ed25519Key, XdrUint32(10)));

      var preAuthKey = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_PRE_AUTH_TX);
      preAuthKey.preAuthTx = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x02)));
      signers.add(XdrSigner(preAuthKey, XdrUint32(5)));

      var hashXKey = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_HASH_X);
      hashXKey.hashX = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x03)));
      signers.add(XdrSigner(hashXKey, XdrUint32(3)));

      XdrDataOutputStream output = XdrDataOutputStream();
      for (var signer in signers) {
        XdrSigner.encode(output, signer);
      }
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);

      var decoded1 = XdrSigner.decode(input);
      expect(decoded1.key.discriminant.value, equals(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519.value));
      expect(decoded1.weight.uint32, equals(10));

      var decoded2 = XdrSigner.decode(input);
      expect(decoded2.key.discriminant.value, equals(XdrSignerKeyType.SIGNER_KEY_TYPE_PRE_AUTH_TX.value));
      expect(decoded2.weight.uint32, equals(5));

      var decoded3 = XdrSigner.decode(input);
      expect(decoded3.key.discriminant.value, equals(XdrSignerKeyType.SIGNER_KEY_TYPE_HASH_X.value));
      expect(decoded3.weight.uint32, equals(3));
    });

    test('XdrPrice array encode/decode', () {
      var prices = <XdrPrice>[];
      for (var i = 1; i <= 10; i++) {
        prices.add(XdrPrice(XdrInt32(i), XdrInt32(i * 2)));
      }

      XdrDataOutputStream output = XdrDataOutputStream();
      for (var price in prices) {
        XdrPrice.encode(output, price);
      }
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      for (var i = 1; i <= 10; i++) {
        var decoded = XdrPrice.decode(input);
        expect(decoded.n.int32, equals(i));
        expect(decoded.d.int32, equals(i * 2));
      }
    });

    test('Mixed XdrSignerKeyType in single stream', () {
      var keys = <XdrSignerKey>[];

      var key1 = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519);
      key1.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAA)));
      keys.add(key1);

      var key2 = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_HASH_X);
      key2.hashX = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xBB)));
      keys.add(key2);

      var key3 = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_PRE_AUTH_TX);
      key3.preAuthTx = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xCC)));
      keys.add(key3);

      XdrDataOutputStream output = XdrDataOutputStream();
      for (var key in keys) {
        XdrSignerKey.encode(output, key);
      }
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);

      var decoded1 = XdrSignerKey.decode(input);
      expect(decoded1.discriminant.value, equals(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519.value));
      expect(decoded1.ed25519!.uint256[0], equals(0xAA));

      var decoded2 = XdrSignerKey.decode(input);
      expect(decoded2.discriminant.value, equals(XdrSignerKeyType.SIGNER_KEY_TYPE_HASH_X.value));
      expect(decoded2.hashX!.uint256[0], equals(0xBB));

      var decoded3 = XdrSignerKey.decode(input);
      expect(decoded3.discriminant.value, equals(XdrSignerKeyType.SIGNER_KEY_TYPE_PRE_AUTH_TX.value));
      expect(decoded3.preAuthTx!.uint256[0], equals(0xCC));
    });

    test('XdrLiabilities with asymmetric values', () {
      final testCases = [
        [BigInt.from(1000000), BigInt.zero],
        [BigInt.zero, BigInt.from(5000000)],
        [BigInt.from(999999), BigInt.from(1)],
        [BigInt.parse('9223372036854775807'), BigInt.from(100)],
      ];

      for (var testCase in testCases) {
        var buying = XdrInt64(testCase[0]);
        var selling = XdrInt64(testCase[1]);

        var original = XdrLiabilities(buying, selling);

        XdrDataOutputStream output = XdrDataOutputStream();
        XdrLiabilities.encode(output, original);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrLiabilities.decode(input);

        expect(decoded.buying.int64, equals(testCase[0]));
        expect(decoded.selling.int64, equals(testCase[1]));
      }
    });
  });

  group('XDR Other Types - Edge Cases', () {
    test('XdrSignature with minimum size', () {
      var sigBytes = Uint8List.fromList([0x01]);
      var original = XdrSignature(sigBytes);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSignature.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSignature.decode(input);

      expect(decoded.signature.length, equals(1));
      expect(decoded.signature[0], equals(0x01));
    });

    test('XdrThresholds all same values', () {
      var thresholdBytes = Uint8List.fromList([0x0A, 0x0A, 0x0A, 0x0A]);
      var original = XdrThresholds(thresholdBytes);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrThresholds.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrThresholds.decode(input);

      expect(decoded.thresholds[0], equals(0x0A));
      expect(decoded.thresholds[1], equals(0x0A));
      expect(decoded.thresholds[2], equals(0x0A));
      expect(decoded.thresholds[3], equals(0x0A));
    });

    test('XdrPrice with zero denominator', () {
      var n = XdrInt32(100);
      var d = XdrInt32(0);

      var original = XdrPrice(n, d);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrPrice.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrPrice.decode(input);

      expect(decoded.n.int32, equals(100));
      expect(decoded.d.int32, equals(0));
    });

    test('XdrEnvelopeType sequential encoding', () {
      final types = [
        XdrEnvelopeType.ENVELOPE_TYPE_TX_V0,
        XdrEnvelopeType.ENVELOPE_TYPE_TX,
        XdrEnvelopeType.ENVELOPE_TYPE_TX_FEE_BUMP,
      ];

      XdrDataOutputStream output = XdrDataOutputStream();
      for (var type in types) {
        XdrEnvelopeType.encode(output, type);
      }
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      for (var expectedType in types) {
        var decoded = XdrEnvelopeType.decode(input);
        expect(decoded.value, equals(expectedType.value));
      }
    });
  });
}
