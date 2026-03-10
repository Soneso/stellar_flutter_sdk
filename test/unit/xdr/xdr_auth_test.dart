import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:typed_data';

void main() {
  group('XdrAuth encode/decode', () {
    test('handles maximum int value', () {
      final auth = XdrAuth(2147483647);

      final output = XdrDataOutputStream();
      XdrAuth.encode(output, auth);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrAuth.decode(input);

      expect(decoded.flags, equals(2147483647));
    });
  });

  group('XdrAuthCert encode/decode', () {
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
    test('handles zero sequence number', () {
      final stellarMessage = XdrStellarMessage(XdrMessageType.ERROR_MSG);
      stellarMessage.error = XdrError(XdrErrorCode.ERR_MISC, 'test');

      final macBytes = Uint8List(32);

      final authMessageV0 = XdrAuthenticatedMessageV0(
        XdrUint64(BigInt.zero),
        stellarMessage,
        XdrHmacSha256Mac(macBytes),
      );

      final authMessage = XdrAuthenticatedMessage(0);
      authMessage.v0 = authMessageV0;

      final output = XdrDataOutputStream();
      XdrAuthenticatedMessage.encode(output, authMessage);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrAuthenticatedMessage.decode(input);

      expect(decoded.v0!.sequence.uint64, equals(BigInt.zero));
    });
  });

  group('XdrAuthenticatedMessageV0 encode/decode', () {
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
    test('handles all ones mac', () {
      final mac = Uint8List(32);
      mac.fillRange(0, 32, 255);

      final hmacMac = XdrHmacSha256Mac(mac);

      final output = XdrDataOutputStream();
      XdrHmacSha256Mac.encode(output, hmacMac);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrHmacSha256Mac.decode(input);

      expect(decoded.mac.every((b) => b == 255), isTrue);
    });
  });
}
