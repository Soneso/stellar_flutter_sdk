import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/src/xdr/xdr_contract.dart';
import 'package:stellar_flutter_sdk/src/xdr/xdr_data_io.dart';

void main() {
  group('BigInt Helper Functions', () {
    test('forU128BigInt creates valid XdrSCVal', () {
      // Test with a large positive number
      BigInt value = BigInt.from(2).pow(100);
      XdrSCVal result = XdrSCVal.forU128BigInt(value);

      expect(result.discriminant, equals(XdrSCValType.SCV_U128));
      expect(result.u128, isNotNull);
    });

    test('forI128BigInt creates valid XdrSCVal', () {
      // Test with a negative number
      BigInt value = BigInt.from(-1000000000000000);
      XdrSCVal result = XdrSCVal.forI128BigInt(value);

      expect(result.discriminant, equals(XdrSCValType.SCV_I128));
      expect(result.i128, isNotNull);
    });

    test('forU256BigInt creates valid XdrSCVal', () {
      // Test with a very large positive number
      BigInt value = BigInt.from(2).pow(200);
      XdrSCVal result = XdrSCVal.forU256BigInt(value);

      expect(result.discriminant, equals(XdrSCValType.SCV_U256));
      expect(result.u256, isNotNull);
    });

    test('forI256BigInt creates valid XdrSCVal', () {
      // Test with a very large negative number
      BigInt value = BigInt.from(-2).pow(200);
      XdrSCVal result = XdrSCVal.forI256BigInt(value);

      expect(result.discriminant, equals(XdrSCValType.SCV_I256));
      expect(result.i256, isNotNull);
    });

    test('bigInt128Parts splits BigInt correctly', () {
      BigInt value = BigInt.from(12345);
      List<BigInt> parts = XdrSCVal.bigInt128Parts(value);

      expect(parts.length, equals(2));
      expect(parts[0], isA<BigInt>()); // hi part
      expect(parts[1], isA<BigInt>()); // lo part
    });

    test('bigInt256Parts splits BigInt correctly', () {
      BigInt value = BigInt.from(67890);
      List<BigInt> parts = XdrSCVal.bigInt256Parts(value);

      expect(parts.length, equals(4));
      expect(parts[0], isA<BigInt>()); // hihi part
      expect(parts[1], isA<BigInt>()); // hilo part
      expect(parts[2], isA<BigInt>()); // lohi part
      expect(parts[3], isA<BigInt>()); // lolo part
    });

    test('helper functions handle zero correctly', () {
      BigInt zero = BigInt.zero;

      List<BigInt> parts128 = XdrSCVal.bigInt128Parts(zero);
      expect(parts128[0], equals(BigInt.zero));
      expect(parts128[1], equals(BigInt.zero));

      List<BigInt> parts256 = XdrSCVal.bigInt256Parts(zero);
      expect(parts256[0], equals(BigInt.zero));
      expect(parts256[1], equals(BigInt.zero));
      expect(parts256[2], equals(BigInt.zero));
      expect(parts256[3], equals(BigInt.zero));
    });

    test('helper functions handle small positive numbers correctly', () {
      BigInt small = BigInt.from(42);

      XdrSCVal u128Val = XdrSCVal.forU128BigInt(small);
      expect(u128Val.discriminant, equals(XdrSCValType.SCV_U128));

      XdrSCVal i128Val = XdrSCVal.forI128BigInt(small);
      expect(i128Val.discriminant, equals(XdrSCValType.SCV_I128));

      XdrSCVal u256Val = XdrSCVal.forU256BigInt(small);
      expect(u256Val.discriminant, equals(XdrSCValType.SCV_U256));

      XdrSCVal i256Val = XdrSCVal.forI256BigInt(small);
      expect(i256Val.discriminant, equals(XdrSCValType.SCV_I256));
    });

    test('bigInt128Parts handles negative numbers correctly', () {
      // With BigInt return type, this now works correctly on all platforms
      BigInt negativeValue = BigInt.from(-12345);
      List<BigInt> parts = XdrSCVal.bigInt128Parts(negativeValue);

      expect(parts.length, equals(2));
      // For negative numbers, hi part should be negative (sign extended)
      expect(parts[0].isNegative, isTrue,
          reason: 'Hi part should be negative for negative number');
    });

    test('bigInt256Parts handles negative numbers correctly', () {
      // With BigInt return type, this now works correctly on all platforms
      BigInt negativeValue = BigInt.from(-67890);
      List<BigInt> parts = XdrSCVal.bigInt256Parts(negativeValue);

      expect(parts.length, equals(4));
      // For negative numbers, hiHi part should be negative (sign extended)
      expect(parts[0].isNegative, isTrue,
          reason: 'HiHi part should be negative for negative number');
    });

    test('edge case: maximum 64-bit values', () {
      // Test with max int64 value
      BigInt maxInt64 = BigInt.parse('7FFFFFFFFFFFFFFF', radix: 16); // 2^63 - 1

      List<BigInt> parts128 = XdrSCVal.bigInt128Parts(maxInt64);
      expect(parts128[0], equals(BigInt.zero)); // hi should be 0
      expect(parts128[1], equals(maxInt64)); // lo should be the value

      XdrSCVal result = XdrSCVal.forU128BigInt(maxInt64);
      expect(result.discriminant, equals(XdrSCValType.SCV_U128));
    });

    test('edge case: large 128-bit boundary values', () {
      // Test with 2^100 (fits in 128 bits)
      BigInt large128 = BigInt.from(2).pow(100);

      XdrSCVal u128Result = XdrSCVal.forU128BigInt(large128);
      expect(u128Result.discriminant, equals(XdrSCValType.SCV_U128));
      expect(u128Result.u128, isNotNull);

      XdrSCVal i128Result = XdrSCVal.forI128BigInt(large128);
      expect(i128Result.discriminant, equals(XdrSCValType.SCV_I128));
      expect(i128Result.i128, isNotNull);
    });

    test('roundtrip consistency check', () {
      // Test that the parts can be used to reconstruct equivalent values
      List<BigInt> testValues = [
        BigInt.zero,
        BigInt.one,
        BigInt.from(42),
        BigInt.from(-42),
        BigInt.from(2).pow(32),
        BigInt.from(-2).pow(32),
      ];

      for (BigInt value in testValues) {
        // Test 128-bit functions
        XdrSCVal u128Val = XdrSCVal.forU128BigInt(value);
        expect(u128Val.discriminant, equals(XdrSCValType.SCV_U128));

        XdrSCVal i128Val = XdrSCVal.forI128BigInt(value);
        expect(i128Val.discriminant, equals(XdrSCValType.SCV_I128));

        // Test 256-bit functions
        XdrSCVal u256Val = XdrSCVal.forU256BigInt(value);
        expect(u256Val.discriminant, equals(XdrSCValType.SCV_U256));

        XdrSCVal i256Val = XdrSCVal.forI256BigInt(value);
        expect(i256Val.discriminant, equals(XdrSCValType.SCV_I256));
      }
    });

    // XDR encoding/decoding roundtrip tests - these test the actual wire format
    // which is what matters for interoperability
    test('XDR roundtrip preserves U128 values', () {
      List<BigInt> testValues = [
        BigInt.zero,
        BigInt.one,
        BigInt.from(42),
        BigInt.from(2).pow(53) - BigInt.one, // max safe JS integer
        BigInt.from(2).pow(100), // large 128-bit
      ];

      for (BigInt originalValue in testValues) {
        XdrSCVal original = XdrSCVal.forU128BigInt(originalValue);

        // Encode to XDR bytes
        XdrDataOutputStream outputStream = XdrDataOutputStream();
        XdrSCVal.encode(outputStream, original);
        List<int> bytes = outputStream.bytes;

        // Decode from XDR bytes
        XdrDataInputStream inputStream = XdrDataInputStream(Uint8List.fromList(bytes));
        XdrSCVal decoded = XdrSCVal.decode(inputStream);

        expect(decoded.discriminant, equals(XdrSCValType.SCV_U128));

        // Re-encode and compare bytes (the authoritative test)
        XdrDataOutputStream reencodeStream = XdrDataOutputStream();
        XdrSCVal.encode(reencodeStream, decoded);
        expect(reencodeStream.bytes, equals(bytes),
            reason: 'XDR roundtrip should preserve bytes for $originalValue');
      }
    });

    test('XDR roundtrip preserves I128 values', () {
      List<BigInt> testValues = [
        BigInt.zero,
        BigInt.one,
        BigInt.from(-1),
        BigInt.from(42),
        BigInt.from(-42),
        BigInt.from(2).pow(53) - BigInt.one,
        BigInt.from(-2).pow(53) + BigInt.one,
      ];

      for (BigInt originalValue in testValues) {
        XdrSCVal original = XdrSCVal.forI128BigInt(originalValue);

        // Encode to XDR bytes
        XdrDataOutputStream outputStream = XdrDataOutputStream();
        XdrSCVal.encode(outputStream, original);
        List<int> bytes = outputStream.bytes;

        // Decode from XDR bytes
        XdrDataInputStream inputStream = XdrDataInputStream(Uint8List.fromList(bytes));
        XdrSCVal decoded = XdrSCVal.decode(inputStream);

        expect(decoded.discriminant, equals(XdrSCValType.SCV_I128));

        // Re-encode and compare bytes
        XdrDataOutputStream reencodeStream = XdrDataOutputStream();
        XdrSCVal.encode(reencodeStream, decoded);
        expect(reencodeStream.bytes, equals(bytes),
            reason: 'XDR roundtrip should preserve bytes for $originalValue');
      }
    });

    test('XDR roundtrip preserves U256 values', () {
      List<BigInt> testValues = [
        BigInt.zero,
        BigInt.from(2).pow(200),
        BigInt.from(2).pow(255) - BigInt.one,
      ];

      for (BigInt originalValue in testValues) {
        XdrSCVal original = XdrSCVal.forU256BigInt(originalValue);

        XdrDataOutputStream outputStream = XdrDataOutputStream();
        XdrSCVal.encode(outputStream, original);
        List<int> bytes = outputStream.bytes;

        XdrDataInputStream inputStream = XdrDataInputStream(Uint8List.fromList(bytes));
        XdrSCVal decoded = XdrSCVal.decode(inputStream);

        expect(decoded.discriminant, equals(XdrSCValType.SCV_U256));

        XdrDataOutputStream reencodeStream = XdrDataOutputStream();
        XdrSCVal.encode(reencodeStream, decoded);
        expect(reencodeStream.bytes, equals(bytes),
            reason: 'XDR roundtrip should preserve bytes for $originalValue');
      }
    });

    test('XDR roundtrip preserves I256 values', () {
      List<BigInt> testValues = [
        BigInt.zero,
        BigInt.from(-1),
        BigInt.from(-2).pow(200),
        -BigInt.from(2).pow(255),
      ];

      for (BigInt originalValue in testValues) {
        XdrSCVal original = XdrSCVal.forI256BigInt(originalValue);

        XdrDataOutputStream outputStream = XdrDataOutputStream();
        XdrSCVal.encode(outputStream, original);
        List<int> bytes = outputStream.bytes;

        XdrDataInputStream inputStream = XdrDataInputStream(Uint8List.fromList(bytes));
        XdrSCVal decoded = XdrSCVal.decode(inputStream);

        expect(decoded.discriminant, equals(XdrSCValType.SCV_I256));

        XdrDataOutputStream reencodeStream = XdrDataOutputStream();
        XdrSCVal.encode(reencodeStream, decoded);
        expect(reencodeStream.bytes, equals(bytes),
            reason: 'XDR roundtrip should preserve bytes for $originalValue');
      }
    });

    // In-memory toBigInt() tests
    // These tests verify the convenience method works for typical use cases
    test('toBigInt converts positive values correctly on all platforms', () {
      List<BigInt> testValues = [
        BigInt.zero,
        BigInt.one,
        BigInt.from(42),
        BigInt.from(1000000),
        BigInt.from(2).pow(30), // Safe on all platforms
        BigInt.from(2).pow(32), // 2^32
        BigInt.from(2).pow(48), // 2^48
        BigInt.from(2).pow(63) - BigInt.one, // max signed 64-bit
        BigInt.parse('170141183460469231731687303715884105727'), // max i128
      ];

      for (BigInt originalValue in testValues) {
        // Test U128
        XdrSCVal u128Val = XdrSCVal.forU128BigInt(originalValue);
        BigInt? u128Result = u128Val.toBigInt();
        expect(u128Result, equals(originalValue),
               reason: 'U128 toBigInt failed for $originalValue');

        // Test I128
        XdrSCVal i128Val = XdrSCVal.forI128BigInt(originalValue);
        BigInt? i128Result = i128Val.toBigInt();
        expect(i128Result, equals(originalValue),
               reason: 'I128 toBigInt failed for $originalValue');

        // Test U256
        XdrSCVal u256Val = XdrSCVal.forU256BigInt(originalValue);
        BigInt? u256Result = u256Val.toBigInt();
        expect(u256Result, equals(originalValue),
               reason: 'U256 toBigInt failed for $originalValue');

        // Test I256
        XdrSCVal i256Val = XdrSCVal.forI256BigInt(originalValue);
        BigInt? i256Result = i256Val.toBigInt();
        expect(i256Result, equals(originalValue),
               reason: 'I256 toBigInt failed for $originalValue');
      }
    });

    test('toBigInt converts negative values correctly', () {
      // With BigInt return type from bigInt128Parts/bigInt256Parts,
      // negative values now work correctly on all platforms including web
      List<BigInt> testValues = [
        BigInt.from(-1),
        BigInt.from(-42),
        BigInt.from(-1000000),
        BigInt.from(-2).pow(32),
      ];

      for (BigInt originalValue in testValues) {
        XdrSCVal i128Val = XdrSCVal.forI128BigInt(originalValue);
        BigInt? i128Result = i128Val.toBigInt();
        expect(i128Result, equals(originalValue),
               reason: 'I128 toBigInt failed for $originalValue');

        XdrSCVal i256Val = XdrSCVal.forI256BigInt(originalValue);
        BigInt? i256Result = i256Val.toBigInt();
        expect(i256Result, equals(originalValue),
               reason: 'I256 toBigInt failed for $originalValue');
      }
    });

    test('toBigInt converts large values correctly', () {
      // With BigInt return type from bigInt128Parts/bigInt256Parts,
      // large values now work correctly on all platforms including web

      // Test positive large values with unsigned types
      List<BigInt> unsignedTestValues = [
        BigInt.from(2).pow(100),
        BigInt.from(2).pow(200),
      ];

      for (BigInt originalValue in unsignedTestValues) {
        // Test 128-bit unsigned values
        if (originalValue < BigInt.from(2).pow(128)) {
          XdrSCVal u128Val = XdrSCVal.forU128BigInt(originalValue);
          BigInt? u128Result = u128Val.toBigInt();
          expect(u128Result, equals(originalValue),
                 reason: 'U128 toBigInt failed for $originalValue');
        }

        // Test 256-bit unsigned values
        if (originalValue < BigInt.from(2).pow(256)) {
          XdrSCVal u256Val = XdrSCVal.forU256BigInt(originalValue);
          BigInt? u256Result = u256Val.toBigInt();
          expect(u256Result, equals(originalValue),
                 reason: 'U256 toBigInt failed for $originalValue');
        }
      }

      // Test negative large values with signed types
      List<BigInt> signedTestValues = [
        BigInt.parse('-12345678901234567890'),
        BigInt.from(-2).pow(200),
      ];

      for (BigInt originalValue in signedTestValues) {
        // Test 128-bit signed values
        if (originalValue >= -BigInt.from(2).pow(127) && originalValue < BigInt.from(2).pow(127)) {
          XdrSCVal i128Val = XdrSCVal.forI128BigInt(originalValue);
          BigInt? i128Result = i128Val.toBigInt();
          expect(i128Result, equals(originalValue),
                 reason: 'I128 toBigInt failed for $originalValue');
        }

        // Test 256-bit signed values
        if (originalValue >= -BigInt.from(2).pow(255) && originalValue < BigInt.from(2).pow(255)) {
          XdrSCVal i256Val = XdrSCVal.forI256BigInt(originalValue);
          BigInt? i256Result = i256Val.toBigInt();
          expect(i256Result, equals(originalValue),
                 reason: 'I256 toBigInt failed for $originalValue');
        }
      }
    });

    test('toBigInt returns null for unsupported types', () {
      XdrSCVal stringVal = XdrSCVal.forString("test");
      expect(stringVal.toBigInt(), isNull);

      XdrSCVal boolVal = XdrSCVal.forBool(true);
      expect(boolVal.toBigInt(), isNull);

      XdrSCVal u32Val = XdrSCVal.forU32(42);
      expect(u32Val.toBigInt(), isNull);
    });
  });
}
