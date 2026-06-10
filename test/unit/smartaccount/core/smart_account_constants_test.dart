import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('SmartAccountConstants', () {
    test('test_constant_ED25519_PUBLIC_KEY_SIZE_equals_32', () {
      expect(SmartAccountConstants.ed25519PublicKeySize, 32);
    });

    test('test_constant_SECP256R1_PUBLIC_KEY_SIZE_equals_65', () {
      expect(SmartAccountConstants.secp256r1PublicKeySize, 65);
    });

    test('test_constant_UNCOMPRESSED_PUBKEY_PREFIX_equals_0x04', () {
      expect(SmartAccountConstants.uncompressedPubkeyPrefix, 0x04);
    });

    test('test_uncompressed_pubkey_prefix_is_byte_typed', () {
      const prefix = SmartAccountConstants.uncompressedPubkeyPrefix;
      // Must be representable as a single byte (0..255 inclusive).
      expect(prefix, isA<int>());
      expect(prefix >= 0 && prefix <= 0xFF, isTrue);
    });

    test('test_constants_are_compile_time_constant_let_or_const', () {
      // These references must resolve at compile time. Asserting the values
      // are usable in a const context proves they're declared as `const`.
      const ed = SmartAccountConstants.ed25519PublicKeySize;
      const sec = SmartAccountConstants.secp256r1PublicKeySize;
      const prefix = SmartAccountConstants.uncompressedPubkeyPrefix;
      expect(ed, 32);
      expect(sec, 65);
      expect(prefix, 0x04);
    });
  });
}
