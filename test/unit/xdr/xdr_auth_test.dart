import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:typed_data';

void main() {
  group('XdrAuth encode/decode', () {
    test('encodes and decodes unused field', () {
      final auth = XdrAuth(42);

      final output = XdrDataOutputStream();
      XdrAuth.encode(output, auth);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrAuth.decode(input);

      expect(decoded.unused, equals(42));
    });

    test('handles zero unused value', () {
      final auth = XdrAuth(0);

      final output = XdrDataOutputStream();
      XdrAuth.encode(output, auth);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrAuth.decode(input);

      expect(decoded.unused, equals(0));
    });

    test('handles maximum int value', () {
      final auth = XdrAuth(2147483647);

      final output = XdrDataOutputStream();
      XdrAuth.encode(output, auth);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrAuth.decode(input);

      expect(decoded.unused, equals(2147483647));
    });
  });

  group('XdrAuthCert encode/decode', () {
    test('encodes and decodes complete auth cert', () {
      final pubkey = Uint8List(32);
      for (int i = 0; i < 32; i++) {
        pubkey[i] = i;
      }

      final signature = Uint8List(64);
      for (int i = 0; i < 64; i++) {
        signature[i] = i * 2;
      }

      final authCert = XdrAuthCert(
        XdrCurve25519Public(pubkey),
        XdrUint64(BigInt.from(1234567890)),
        XdrSignature(signature),
      );

      final output = XdrDataOutputStream();
      XdrAuthCert.encode(output, authCert);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrAuthCert.decode(input);

      expect(decoded.pubkey.key, equals(pubkey));
      expect(decoded.expiration.uint64, equals(BigInt.from(1234567890)));
      expect(decoded.sig.signature, equals(signature));
    });

    test('handles zero expiration', () {
      final pubkey = Uint8List(32);
      final signature = Uint8List(64);

      final authCert = XdrAuthCert(
        XdrCurve25519Public(pubkey),
        XdrUint64(BigInt.zero),
        XdrSignature(signature),
      );

      final output = XdrDataOutputStream();
      XdrAuthCert.encode(output, authCert);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrAuthCert.decode(input);

      expect(decoded.expiration.uint64, equals(BigInt.zero));
    });

    test('handles large expiration value', () {
      final pubkey = Uint8List(32);
      final signature = Uint8List(64);

      final authCert = XdrAuthCert(
        XdrCurve25519Public(pubkey),
        XdrUint64(BigInt.parse('9999999999999')),
        XdrSignature(signature),
      );

      final output = XdrDataOutputStream();
      XdrAuthCert.encode(output, authCert);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrAuthCert.decode(input);

      expect(decoded.expiration.uint64, equals(BigInt.parse('9999999999999')));
    });
  });

  group('XdrAuthenticatedMessage encode/decode', () {
    test('encodes and decodes v0 message', () {
      final messageBytes = Uint8List.fromList([1, 2, 3, 4]);
      final stellarMessage = XdrStellarMessage(XdrMessageType.ERROR_MSG);
      stellarMessage.error = XdrError(XdrErrorCode.ERR_MISC, 'test');

      final macBytes = Uint8List(32);
      for (int i = 0; i < 32; i++) {
        macBytes[i] = (i * 3) % 256;
      }

      final authMessageV0 = XdrAuthenticatedMessageV0(
        XdrUint64(BigInt.from(12345)),
        stellarMessage,
        XdrHmacSha256Mac(macBytes),
      );

      final authMessage = XdrAuthenticatedMessage(XdrUint32(0));
      authMessage.v0 = authMessageV0;

      final output = XdrDataOutputStream();
      XdrAuthenticatedMessage.encode(output, authMessage);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrAuthenticatedMessage.decode(input);

      expect(decoded.discriminant.uint32, equals(0));
      expect(decoded.v0, isNotNull);
      expect(decoded.v0!.sequence.uint64, equals(BigInt.from(12345)));
    });

    test('handles zero sequence number', () {
      final stellarMessage = XdrStellarMessage(XdrMessageType.ERROR_MSG);
      stellarMessage.error = XdrError(XdrErrorCode.ERR_MISC, 'test');

      final macBytes = Uint8List(32);

      final authMessageV0 = XdrAuthenticatedMessageV0(
        XdrUint64(BigInt.zero),
        stellarMessage,
        XdrHmacSha256Mac(macBytes),
      );

      final authMessage = XdrAuthenticatedMessage(XdrUint32(0));
      authMessage.v0 = authMessageV0;

      final output = XdrDataOutputStream();
      XdrAuthenticatedMessage.encode(output, authMessage);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrAuthenticatedMessage.decode(input);

      expect(decoded.v0!.sequence.uint64, equals(BigInt.zero));
    });
  });

  group('XdrAuthenticatedMessageV0 encode/decode', () {
    test('encodes and decodes complete message', () {
      final stellarMessage = XdrStellarMessage(XdrMessageType.ERROR_MSG);
      stellarMessage.error = XdrError(XdrErrorCode.ERR_MISC, 'testmsg');

      final macBytes = Uint8List(32);
      for (int i = 0; i < 32; i++) {
        macBytes[i] = i;
      }

      final authMessageV0 = XdrAuthenticatedMessageV0(
        XdrUint64(BigInt.from(999999)),
        stellarMessage,
        XdrHmacSha256Mac(macBytes),
      );

      final output = XdrDataOutputStream();
      XdrAuthenticatedMessageV0.encode(output, authMessageV0);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrAuthenticatedMessageV0.decode(input);

      expect(decoded.sequence.uint64, equals(BigInt.from(999999)));
      expect(decoded.mac.key, equals(macBytes));
    });

    test('handles large sequence number', () {
      final stellarMessage = XdrStellarMessage(XdrMessageType.ERROR_MSG);
      stellarMessage.error = XdrError(XdrErrorCode.ERR_MISC, 'test');

      final macBytes = Uint8List(32);

      final authMessageV0 = XdrAuthenticatedMessageV0(
        XdrUint64(BigInt.parse('18446744073709551615')),
        stellarMessage,
        XdrHmacSha256Mac(macBytes),
      );

      final output = XdrDataOutputStream();
      XdrAuthenticatedMessageV0.encode(output, authMessageV0);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrAuthenticatedMessageV0.decode(input);

      expect(decoded.sequence.uint64, equals(BigInt.parse('18446744073709551615')));
    });
  });

  group('XdrHmacSha256Key encode/decode', () {
    test('encodes and decodes key with pattern', () {
      final key = Uint8List(32);
      for (int i = 0; i < 32; i++) {
        key[i] = (i * 5) % 256;
      }

      final hmacKey = XdrHmacSha256Key(key);

      final output = XdrDataOutputStream();
      XdrHmacSha256Key.encode(output, hmacKey);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrHmacSha256Key.decode(input);

      expect(decoded.key, equals(key));
    });

    test('handles all zeros key', () {
      final key = Uint8List(32);

      final hmacKey = XdrHmacSha256Key(key);

      final output = XdrDataOutputStream();
      XdrHmacSha256Key.encode(output, hmacKey);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrHmacSha256Key.decode(input);

      expect(decoded.key.every((b) => b == 0), isTrue);
    });
  });

  group('XdrHmacSha256Mac encode/decode', () {
    test('encodes and decodes mac with pattern', () {
      final mac = Uint8List(32);
      for (int i = 0; i < 32; i++) {
        mac[i] = (i * 17) % 256;
      }

      final hmacMac = XdrHmacSha256Mac(mac);

      final output = XdrDataOutputStream();
      XdrHmacSha256Mac.encode(output, hmacMac);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrHmacSha256Mac.decode(input);

      expect(decoded.key, equals(mac));
    });

    test('handles all ones mac', () {
      final mac = Uint8List(32);
      mac.fillRange(0, 32, 255);

      final hmacMac = XdrHmacSha256Mac(mac);

      final output = XdrDataOutputStream();
      XdrHmacSha256Mac.encode(output, hmacMac);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrHmacSha256Mac.decode(input);

      expect(decoded.key.every((b) => b == 255), isTrue);
    });
  });

  group('XdrEnvelopeType enum', () {
    test('encodes and decodes ENVELOPE_TYPE_TX_V0', () {
      final output = XdrDataOutputStream();
      XdrEnvelopeType.encode(output, XdrEnvelopeType.ENVELOPE_TYPE_TX_V0);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrEnvelopeType.decode(input);

      expect(decoded, equals(XdrEnvelopeType.ENVELOPE_TYPE_TX_V0));
      expect(decoded.value, equals(0));
    });

    test('encodes and decodes ENVELOPE_TYPE_SCP', () {
      final output = XdrDataOutputStream();
      XdrEnvelopeType.encode(output, XdrEnvelopeType.ENVELOPE_TYPE_SCP);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrEnvelopeType.decode(input);

      expect(decoded, equals(XdrEnvelopeType.ENVELOPE_TYPE_SCP));
      expect(decoded.value, equals(1));
    });

    test('encodes and decodes ENVELOPE_TYPE_TX', () {
      final output = XdrDataOutputStream();
      XdrEnvelopeType.encode(output, XdrEnvelopeType.ENVELOPE_TYPE_TX);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrEnvelopeType.decode(input);

      expect(decoded, equals(XdrEnvelopeType.ENVELOPE_TYPE_TX));
      expect(decoded.value, equals(2));
    });

    test('encodes and decodes ENVELOPE_TYPE_AUTH', () {
      final output = XdrDataOutputStream();
      XdrEnvelopeType.encode(output, XdrEnvelopeType.ENVELOPE_TYPE_AUTH);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrEnvelopeType.decode(input);

      expect(decoded, equals(XdrEnvelopeType.ENVELOPE_TYPE_AUTH));
      expect(decoded.value, equals(3));
    });

    test('encodes and decodes ENVELOPE_TYPE_SCPVALUE', () {
      final output = XdrDataOutputStream();
      XdrEnvelopeType.encode(output, XdrEnvelopeType.ENVELOPE_TYPE_SCPVALUE);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrEnvelopeType.decode(input);

      expect(decoded, equals(XdrEnvelopeType.ENVELOPE_TYPE_SCPVALUE));
      expect(decoded.value, equals(4));
    });

    test('encodes and decodes ENVELOPE_TYPE_TX_FEE_BUMP', () {
      final output = XdrDataOutputStream();
      XdrEnvelopeType.encode(output, XdrEnvelopeType.ENVELOPE_TYPE_TX_FEE_BUMP);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrEnvelopeType.decode(input);

      expect(decoded, equals(XdrEnvelopeType.ENVELOPE_TYPE_TX_FEE_BUMP));
      expect(decoded.value, equals(5));
    });
  });
}
