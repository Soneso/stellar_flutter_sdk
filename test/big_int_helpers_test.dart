import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/src/xdr/xdr_contract.dart';

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
      List<int> parts = XdrSCVal.bigInt128Parts(value);
      
      expect(parts.length, equals(2));
      expect(parts[0], isA<int>()); // hi part
      expect(parts[1], isA<int>()); // lo part
    });

    test('bigInt256Parts splits BigInt correctly', () {
      BigInt value = BigInt.from(67890);
      List<int> parts = XdrSCVal.bigInt256Parts(value);
      
      expect(parts.length, equals(4));
      expect(parts[0], isA<int>()); // hihi part
      expect(parts[1], isA<int>()); // hilo part  
      expect(parts[2], isA<int>()); // lohi part
      expect(parts[3], isA<int>()); // lolo part
    });

    test('helper functions handle zero correctly', () {
      BigInt zero = BigInt.zero;
      
      List<int> parts128 = XdrSCVal.bigInt128Parts(zero);
      expect(parts128[0], equals(0));
      expect(parts128[1], equals(0));
      
      List<int> parts256 = XdrSCVal.bigInt256Parts(zero);
      expect(parts256[0], equals(0));
      expect(parts256[1], equals(0));  
      expect(parts256[2], equals(0));
      expect(parts256[3], equals(0));
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
      BigInt negativeValue = BigInt.from(-12345);
      List<int> parts = XdrSCVal.bigInt128Parts(negativeValue);
      
      expect(parts.length, equals(2));
      // For negative numbers, hi part should have sign bits set
      expect(parts[0], lessThan(0));
    });

    test('bigInt256Parts handles negative numbers correctly', () {
      BigInt negativeValue = BigInt.from(-67890);
      List<int> parts = XdrSCVal.bigInt256Parts(negativeValue);
      
      expect(parts.length, equals(4));
      // For negative numbers, hihi part should have sign bits set
      expect(parts[0], lessThan(0));
    });

    test('edge case: maximum 64-bit values', () {
      // Test with max int64 value
      BigInt maxInt64 = BigInt.from(9223372036854775807); // 2^63 - 1
      
      List<int> parts128 = XdrSCVal.bigInt128Parts(maxInt64);
      expect(parts128[0], equals(0)); // hi should be 0
      expect(parts128[1], equals(maxInt64.toInt())); // lo should be the value
      
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

    // Tests for the new toBigInt() method
    test('toBigInt converts U128 values correctly', () {
      BigInt testValue = BigInt.from(2).pow(100);
      XdrSCVal scVal = XdrSCVal.forU128BigInt(testValue);
      
      BigInt? result = scVal.toBigInt();
      expect(result, isNotNull);
      expect(result, equals(testValue));
    });

    test('toBigInt converts I128 values correctly', () {
      BigInt testValue = BigInt.parse('-12345678901234567890');
      XdrSCVal scVal = XdrSCVal.forI128BigInt(testValue);
      
      BigInt? result = scVal.toBigInt();
      expect(result, isNotNull);
      expect(result, equals(testValue));
    });

    test('toBigInt converts U256 values correctly', () {
      BigInt testValue = BigInt.from(2).pow(200);
      XdrSCVal scVal = XdrSCVal.forU256BigInt(testValue);
      
      BigInt? result = scVal.toBigInt();
      expect(result, isNotNull);
      expect(result, equals(testValue));
    });

    test('toBigInt converts I256 values correctly', () {
      BigInt testValue = BigInt.from(-2).pow(200);
      XdrSCVal scVal = XdrSCVal.forI256BigInt(testValue);
      
      BigInt? result = scVal.toBigInt();
      expect(result, isNotNull);
      expect(result, equals(testValue));
    });

    test('toBigInt returns null for unsupported types', () {
      XdrSCVal stringVal = XdrSCVal.forString("test");
      expect(stringVal.toBigInt(), isNull);
      
      XdrSCVal boolVal = XdrSCVal.forBool(true);
      expect(boolVal.toBigInt(), isNull);
      
      XdrSCVal u32Val = XdrSCVal.forU32(42);
      expect(u32Val.toBigInt(), isNull);
    });

    test('roundtrip conversion preserves values', () {
      List<BigInt> testValues = [
        BigInt.zero,
        BigInt.one,
        BigInt.from(42),
        BigInt.from(-42),
        BigInt.parse('123456789'),
        BigInt.parse('-987654321'),
        BigInt.from(2).pow(63) - BigInt.one, // max int64
        BigInt.from(-2).pow(63), // min int64
        BigInt.from(2).pow(100), // large 128-bit
        BigInt.from(-2).pow(100), // large negative 128-bit
      ];

      for (BigInt originalValue in testValues) {
        // Test U128 roundtrip
        XdrSCVal u128Val = XdrSCVal.forU128BigInt(originalValue);
        BigInt? u128Result = u128Val.toBigInt();
        expect(u128Result, equals(originalValue), 
               reason: 'U128 roundtrip failed for $originalValue');

        // Test I128 roundtrip
        XdrSCVal i128Val = XdrSCVal.forI128BigInt(originalValue);
        BigInt? i128Result = i128Val.toBigInt();
        expect(i128Result, equals(originalValue), 
               reason: 'I128 roundtrip failed for $originalValue');

        // Test U256 roundtrip
        XdrSCVal u256Val = XdrSCVal.forU256BigInt(originalValue);
        BigInt? u256Result = u256Val.toBigInt();
        expect(u256Result, equals(originalValue), 
               reason: 'U256 roundtrip failed for $originalValue');

        // Test I256 roundtrip
        XdrSCVal i256Val = XdrSCVal.forI256BigInt(originalValue);
        BigInt? i256Result = i256Val.toBigInt();
        expect(i256Result, equals(originalValue), 
               reason: 'I256 roundtrip failed for $originalValue');
      }
    });

    test('toBigInt handles edge cases correctly', () {
      // Test with very large positive 256-bit value
      BigInt large256 = BigInt.from(2).pow(255) - BigInt.one;
      XdrSCVal u256Val = XdrSCVal.forU256BigInt(large256);
      BigInt? result = u256Val.toBigInt();
      expect(result, equals(large256));

      // Test with maximum negative 256-bit value
      BigInt minNeg256 = -BigInt.from(2).pow(255);
      XdrSCVal i256Val = XdrSCVal.forI256BigInt(minNeg256);
      BigInt? negResult = i256Val.toBigInt();
      expect(negResult, equals(minNeg256));
    });
  });
}