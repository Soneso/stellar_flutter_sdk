// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('XDR Data IO - BigInt64 Operations', () {
    test('writeBigInt64/readBigInt64 roundtrip for max uint64', () {
      BigInt maxUint64 = BigInt.parse('18446744073709551615');
      XdrDataOutputStream out = XdrDataOutputStream();
      out.writeBigInt64(maxUint64);
      expect(out.bytes, equals([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]));

      XdrDataInputStream inp = XdrDataInputStream(Uint8List.fromList(out.bytes));
      expect(inp.readBigInt64(), equals(maxUint64));
    });

    test('writeBigInt64/readBigInt64Signed roundtrip for -1', () {
      BigInt negOne = BigInt.from(-1);
      XdrDataOutputStream out = XdrDataOutputStream();
      out.writeBigInt64(negOne);
      expect(out.bytes, equals([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]));

      XdrDataInputStream inp = XdrDataInputStream(Uint8List.fromList(out.bytes));
      expect(inp.readBigInt64Signed(), equals(negOne));
    });

    test('writeBigInt64/readBigInt64Signed roundtrip for min int64', () {
      BigInt minInt64 = BigInt.parse('-9223372036854775808');
      XdrDataOutputStream out = XdrDataOutputStream();
      out.writeBigInt64(minInt64);
      expect(out.bytes, equals([0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]));

      XdrDataInputStream inp = XdrDataInputStream(Uint8List.fromList(out.bytes));
      expect(inp.readBigInt64Signed(), equals(minInt64));
    });

    test('writeBigInt64/readBigInt64 roundtrip for max int64', () {
      BigInt maxInt64 = BigInt.parse('9223372036854775807');
      XdrDataOutputStream out = XdrDataOutputStream();
      out.writeBigInt64(maxInt64);
      expect(out.bytes, equals([0x7F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]));

      XdrDataInputStream inp = XdrDataInputStream(Uint8List.fromList(out.bytes));
      expect(inp.readBigInt64Signed(), equals(maxInt64));
    });

    test('writeBigInt64/readBigInt64 handles zero', () {
      BigInt zero = BigInt.zero;
      XdrDataOutputStream out = XdrDataOutputStream();
      out.writeBigInt64(zero);
      expect(out.bytes, equals([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]));

      XdrDataInputStream inp = XdrDataInputStream(Uint8List.fromList(out.bytes));
      expect(inp.readBigInt64(), equals(zero));

      XdrDataInputStream inp2 = XdrDataInputStream(Uint8List.fromList(out.bytes));
      expect(inp2.readBigInt64Signed(), equals(zero));
    });

    test('writeBigInt64/readBigInt64 handles 2^53 boundary', () {
      // 2^53 is the JavaScript safe integer boundary
      BigInt twoTo53 = BigInt.parse('9007199254740992');
      XdrDataOutputStream out = XdrDataOutputStream();
      out.writeBigInt64(twoTo53);

      XdrDataInputStream inp = XdrDataInputStream(Uint8List.fromList(out.bytes));
      expect(inp.readBigInt64(), equals(twoTo53));
    });

    test('writeBigInt64/readBigInt64 handles 2^53 + 1', () {
      // Just above JavaScript safe integer boundary
      BigInt aboveBoundary = BigInt.parse('9007199254740993');
      XdrDataOutputStream out = XdrDataOutputStream();
      out.writeBigInt64(aboveBoundary);

      XdrDataInputStream inp = XdrDataInputStream(Uint8List.fromList(out.bytes));
      expect(inp.readBigInt64(), equals(aboveBoundary));
    });

    test('writeBigInt64/readBigInt64 handles 2^63 - 1 (max signed int64)', () {
      BigInt maxSignedInt64 = BigInt.parse('9223372036854775807');
      XdrDataOutputStream out = XdrDataOutputStream();
      out.writeBigInt64(maxSignedInt64);

      XdrDataInputStream inp = XdrDataInputStream(Uint8List.fromList(out.bytes));
      BigInt readUnsigned = inp.readBigInt64();
      expect(readUnsigned, equals(maxSignedInt64));

      XdrDataInputStream inp2 = XdrDataInputStream(Uint8List.fromList(out.bytes));
      BigInt readSigned = inp2.readBigInt64Signed();
      expect(readSigned, equals(maxSignedInt64));
    });

    test('writeBigInt64/readBigInt64 handles 2^63 (unsigned interpretation)', () {
      // This is -2^63 when interpreted as signed, but 2^63 as unsigned
      BigInt twoTo63 = BigInt.parse('9223372036854775808');
      XdrDataOutputStream out = XdrDataOutputStream();
      out.writeBigInt64(twoTo63);
      expect(out.bytes, equals([0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]));

      XdrDataInputStream inp = XdrDataInputStream(Uint8List.fromList(out.bytes));
      BigInt readUnsigned = inp.readBigInt64();
      expect(readUnsigned, equals(twoTo63));

      XdrDataInputStream inp2 = XdrDataInputStream(Uint8List.fromList(out.bytes));
      BigInt readSigned = inp2.readBigInt64Signed();
      expect(readSigned, equals(BigInt.parse('-9223372036854775808')));
    });

    test('writeBigInt64 converts negative to unsigned correctly', () {
      // -1 should be written as max uint64
      BigInt negOne = BigInt.from(-1);
      XdrDataOutputStream out = XdrDataOutputStream();
      out.writeBigInt64(negOne);

      // All bytes should be 0xFF
      expect(out.bytes, equals(List<int>.filled(8, 0xFF)));

      // Reading as unsigned should give max uint64
      XdrDataInputStream inp = XdrDataInputStream(Uint8List.fromList(out.bytes));
      expect(inp.readBigInt64(), equals(BigInt.parse('18446744073709551615')));

      // Reading as signed should give -1
      XdrDataInputStream inp2 = XdrDataInputStream(Uint8List.fromList(out.bytes));
      expect(inp2.readBigInt64Signed(), equals(negOne));
    });

    test('writeBigInt64/readBigInt64 specific byte pattern test 1', () {
      // Test a specific pattern: 0x0102030405060708
      BigInt value = BigInt.parse('72623859790382856'); // decimal of above hex
      XdrDataOutputStream out = XdrDataOutputStream();
      out.writeBigInt64(value);
      expect(out.bytes, equals([0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08]));

      XdrDataInputStream inp = XdrDataInputStream(Uint8List.fromList(out.bytes));
      expect(inp.readBigInt64(), equals(value));
    });

    test('writeBigInt64/readBigInt64 specific byte pattern test 2', () {
      // Test alternating pattern: 0xAAAAAAAAAAAAAAAA
      BigInt value = BigInt.parse('12297829382473034410');
      XdrDataOutputStream out = XdrDataOutputStream();
      out.writeBigInt64(value);
      expect(out.bytes, equals([0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA]));

      XdrDataInputStream inp = XdrDataInputStream(Uint8List.fromList(out.bytes));
      expect(inp.readBigInt64(), equals(value));
    });

    test('multiple BigInt64 values in sequence', () {
      XdrDataOutputStream out = XdrDataOutputStream();
      BigInt val1 = BigInt.from(100);
      BigInt val2 = BigInt.parse('9223372036854775807');
      BigInt val3 = BigInt.from(-1);

      out.writeBigInt64(val1);
      out.writeBigInt64(val2);
      out.writeBigInt64(val3);

      XdrDataInputStream inp = XdrDataInputStream(Uint8List.fromList(out.bytes));
      expect(inp.readBigInt64Signed(), equals(val1));
      expect(inp.readBigInt64Signed(), equals(val2));
      expect(inp.readBigInt64Signed(), equals(val3));
    });

    test('readBigInt64 reads exactly 8 bytes', () {
      // Create a stream with more than 8 bytes
      List<int> data = [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A];
      XdrDataInputStream inp = XdrDataInputStream(Uint8List.fromList(data));

      BigInt value = inp.readBigInt64();
      expect(value, equals(BigInt.parse('72623859790382856'))); // 0x0102030405060708

      expect(inp.readByte(), equals(0x0A));
    });

    test('writeBigInt64 respects XDR padding', () {
      // XDR pads to 4-byte boundaries
      XdrDataOutputStream out = XdrDataOutputStream();
      out.writeBigInt64(BigInt.from(1));

      // 8 bytes should not need padding (already aligned)
      expect(out.bytes.length, equals(8));
    });
  });

  group('XdrDataOutputStream and XdrDataInputStream', () {
    test('writeByte and readByte with positive value', () {
      // readByte pre-increments offset, so a leading byte is needed
      final output = DataOutput();
      output.data = [0, 42];
      output.offset = 2;

      final input = DataInput.fromUint8List(Uint8List.fromList(output.bytes));
      expect(input.readByte(), equals(42));
    });

    test('writeByte and readByte with negative value', () {
      final output = DataOutput();
      output.data = [0, 156]; // -100 as signed byte
      output.offset = 2;

      final input = DataInput.fromUint8List(Uint8List.fromList(output.bytes));
      expect(input.readByte(), equals(-100));
    });

    test('writeByte and readByte at boundary (127)', () {
      final output = DataOutput();
      output.data = [0, 127];
      output.offset = 2;

      final input = DataInput.fromUint8List(Uint8List.fromList(output.bytes));
      expect(input.readByte(), equals(127));
    });

    test('writeByte and readByte at boundary (-128)', () {
      final output = DataOutput();
      output.data = [0, 128]; // -128 as signed byte
      output.offset = 2;

      final input = DataInput.fromUint8List(Uint8List.fromList(output.bytes));
      expect(input.readByte(), equals(-128));
    });

    test('readByte throws exception at EOF when eofException is true', () {
      final output = DataOutput();
      output.data = [0, 1];

      final input = DataInput.fromUint8List(Uint8List.fromList(output.bytes));
      input.readByte(); // consume the byte

      expect(() => input.readByte(), throwsRangeError);
    });

    test('readByte returns -129 at EOF when eofException is false', () {
      final output = DataOutput();
      output.data = [0, 1];

      final input = DataInput.fromUint8List(Uint8List.fromList(output.bytes));
      input.readByte(); // consume the byte

      expect(input.readByte(false), equals(-129));
    });

    test('readUnsignedByte returns unsigned byte value', () {
      final output = DataOutput();
      output.data = [0, 200]; // > 127, would be negative as signed

      final input = DataInput.fromUint8List(Uint8List.fromList(output.bytes));
      expect(input.readUnsignedByte(), equals(200));
    });

    test('readUnsignedByte throws exception at EOF when eofException is true', () {
      final output = DataOutput();
      output.data = [];

      final input = DataInput.fromUint8List(Uint8List.fromList(output.bytes));
      expect(() => input.readUnsignedByte(), throwsRangeError);
    });

    test('readUnsignedByte returns -129 at EOF when eofException is false', () {
      final output = DataOutput();
      output.data = [];

      final input = DataInput.fromUint8List(Uint8List.fromList(output.bytes));
      expect(input.readUnsignedByte(false), equals(-129));
    });

    test('writeBytes and readBytes with 1 byte', () {
      final output = XdrDataOutputStream();
      output.write([0x42]);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final bytes = input.readBytes(1);

      expect(bytes.length, equals(1));
      expect(bytes[0], equals(0x42));
    });

    test('writeBytes and readBytes with 3 bytes (tests padding)', () {
      final output = XdrDataOutputStream();
      output.write([0x01, 0x02, 0x03]);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final bytes = input.readBytes(3);

      expect(bytes.length, equals(3));
      expect(bytes[0], equals(0x01));
      expect(bytes[1], equals(0x02));
      expect(bytes[2], equals(0x03));
    });

    test('writeBytes and readBytes with 4 bytes (no padding needed)', () {
      final output = XdrDataOutputStream();
      output.write([0x01, 0x02, 0x03, 0x04]);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final bytes = input.readBytes(4);

      expect(bytes.length, equals(4));
      expect(bytes[0], equals(0x01));
      expect(bytes[3], equals(0x04));
    });

    test('writeBytes and readBytes with 32 bytes', () {
      final output = XdrDataOutputStream();
      final testData = List<int>.generate(32, (i) => i);
      output.write(testData);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final bytes = input.readBytes(32);

      expect(bytes.length, equals(32));
      expect(bytes, equals(testData));
    });

    test('readBytes throws exception at EOF', () {
      final output = DataOutput();
      output.data = [1];

      final input = DataInput.fromUint8List(Uint8List.fromList(output.bytes));
      expect(() => input.readBytes(10), throwsRangeError);
    });

    test('pad method validates zero padding when reading 1 byte', () {
      final output = XdrDataOutputStream();
      // Write 1 byte which will automatically add 3 zero padding bytes (total 4)
      output.write([0x42]);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final bytes = input.readBytes(1); // This should consume byte and validate padding
      // If we get here without exception, padding validation passed
      expect(bytes, equals([0x42]));
    });

    test('pad method throws exception on non-zero padding for 1 byte read', () {
      final output = DataOutput();
      // 1 byte + 3 bytes padding (but one is non-zero)
      output.data = [0x42, 0x00, 0xFF, 0x00];
      output.offset = 4;

      final input = DataInput.fromUint8List(Uint8List.fromList(output.data));
      expect(() => input.readBytes(1), throwsException);
    });

    test('writeInt and readInt', () {
      final output = XdrDataOutputStream();
      output.writeInt(123456789);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      expect(input.readInt(), equals(123456789));
    });

    test('writeInt and readInt with negative value', () {
      final output = XdrDataOutputStream();
      output.writeInt(-987654321);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      expect(input.readInt(), equals(-987654321));
    });

    test('writeInt and readInt with zero', () {
      final output = XdrDataOutputStream();
      output.writeInt(0);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      expect(input.readInt(), equals(0));
    });

    test('writeInt and readInt with max value', () {
      final output = XdrDataOutputStream();
      const maxInt = 2147483647; // 2^31 - 1
      output.writeInt(maxInt);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      expect(input.readInt(), equals(maxInt));
    });

    test('writeBigInt64 and readBigInt64 with positive value', () {
      final output = XdrDataOutputStream();
      final value = BigInt.parse('9223372036854775807'); // max int64
      output.writeBigInt64(value);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      expect(input.readBigInt64(), equals(value));
    });

    test('writeBigInt64 and readBigInt64 with zero', () {
      final output = XdrDataOutputStream();
      output.writeBigInt64(BigInt.zero);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      expect(input.readBigInt64(), equals(BigInt.zero));
    });

    test('writeBigInt64 and readBigInt64Signed with negative value', () {
      final output = XdrDataOutputStream();
      final value = BigInt.from(-1234567890123456);
      output.writeBigInt64(value);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      expect(input.readBigInt64Signed(), equals(value));
    });

    test('writeBigInt64 and readBigInt64 with large value', () {
      final output = XdrDataOutputStream();
      final value = BigInt.parse('18446744073709551615'); // max uint64
      output.writeBigInt64(value);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      expect(input.readBigInt64(), equals(value));
    });

    test('writeFloat and readFloat', () {
      final output = XdrDataOutputStream();
      output.writeFloat(3.14159);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      expect(input.readFloat(), closeTo(3.14159, 0.00001));
    });

    test('writeFloat and readFloat with negative value', () {
      final output = XdrDataOutputStream();
      output.writeFloat(-2.71828);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      expect(input.readFloat(), closeTo(-2.71828, 0.00001));
    });

    test('writeDouble and readDouble', () {
      final output = XdrDataOutputStream();
      output.writeDouble(3.141592653589793);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      expect(input.readDouble(), closeTo(3.141592653589793, 0.0000000000001));
    });

    test('writeDouble and readDouble with negative value', () {
      final output = XdrDataOutputStream();
      output.writeDouble(-2.718281828459045);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      expect(input.readDouble(), closeTo(-2.718281828459045, 0.0000000000001));
    });

    test('writeBoolean and readBoolean with true', () {
      final output = XdrDataOutputStream();
      output.writeBoolean(true);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      expect(input.readBoolean(), isTrue);
    });

    test('writeBoolean and readBoolean with false', () {
      final output = XdrDataOutputStream();
      output.writeBoolean(false);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      expect(input.readBoolean(), isFalse);
    });

    test('writeString and readString with short string', () {
      final output = XdrDataOutputStream();
      output.writeString('Hello');

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      expect(input.readString(), equals('Hello'));
    });

    test('writeString and readString with empty string', () {
      final output = XdrDataOutputStream();
      output.writeString('');

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      expect(input.readString(), equals(''));
    });

    test('writeString and readString with Unicode characters', () {
      final output = XdrDataOutputStream();
      output.writeString('Hello World 世界');

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      expect(input.readString(), equals('Hello World 世界'));
    });

    test('writeString and readString with long string', () {
      final output = XdrDataOutputStream();
      final longString = 'A' * 1000;
      output.writeString(longString);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      expect(input.readString(), equals(longString));
    });

    test('writeString throws exception for string exceeding 65535 bytes', () {
      final output = XdrDataOutputStream();
      final tooLongString = 'A' * 65536;
      expect(() => output.writeString(tooLongString), throwsFormatException);
    });

    test('writeIntArray and readIntArray', () {
      final output = XdrDataOutputStream();
      output.writeIntArray([1, 2, 3, 4, 5]);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final result = input.readIntArray();

      expect(result, equals([1, 2, 3, 4, 5]));
    });

    test('writeIntArray and readIntArray with empty array', () {
      final output = XdrDataOutputStream();
      output.writeIntArray([]);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final result = input.readIntArray();

      expect(result, equals([]));
    });

    test('writeIntArray and readIntArray with negative values', () {
      final output = XdrDataOutputStream();
      output.writeIntArray([-1, -2, -3, 100, 200]);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final result = input.readIntArray();

      expect(result, equals([-1, -2, -3, 100, 200]));
    });

    test('readFully without offset and length', () {
      final output = XdrDataOutputStream();
      output.write([1, 2, 3, 4]);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final bytes = List<int>.filled(4, 0);
      input.readFully(bytes);

      expect(bytes, equals([1, 2, 3, 4]));
    });

    test('readFully with offset and length', () {
      final output = XdrDataOutputStream();
      output.write([10, 20, 30, 40, 50, 60, 70, 80]);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final bytes = <int>[];
      input.readFully(bytes, len: 4, off: 2);

      expect(bytes, equals([30, 40]));
    });

    test('readFully throws ArgumentError when only len is provided', () {
      final output = XdrDataOutputStream();
      output.write([1, 2, 3, 4]);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final bytes = <int>[];

      expect(() => input.readFully(bytes, len: 2), throwsArgumentError);
    });

    test('readFully throws ArgumentError when only off is provided', () {
      final output = XdrDataOutputStream();
      output.write([1, 2, 3, 4]);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final bytes = <int>[];

      expect(() => input.readFully(bytes, off: 1), throwsArgumentError);
    });

    test('readFully throws RangeError for negative offset', () {
      final output = XdrDataOutputStream();
      output.write([1, 2, 3, 4]);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final bytes = <int>[];

      expect(() => input.readFully(bytes, len: 2, off: -1), throwsRangeError);
    });

    test('readFully returns early when len is zero', () {
      final output = XdrDataOutputStream();
      output.write([1, 2, 3, 4]);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final bytes = <int>[];

      input.readFully(bytes, len: 0, off: 0);
      expect(bytes, equals([]));
    });

    test('DataOutput bytes getter returns correct data', () {
      final output = XdrDataOutputStream();
      output.writeInt(42);
      output.writeBoolean(true);

      final bytes = output.bytes;
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(0));
    });

    test('DataOutput pad method adds correct padding for offset 1', () {
      final output = DataOutput();
      output.writeByte(1);
      // writeByte doesn't call pad, so offset is 1
      expect(output.offset, equals(1));

      // Now call pad manually
      output.pad();
      expect(output.offset, equals(4)); // 1 byte + 3 padding
      expect(output.bytes.length, equals(4));
    });

    test('DataOutput pad method adds correct padding for offset 2', () {
      final output = DataOutput();
      output.writeByte(1);
      output.offset = 2; // Manually set to test pad behavior
      output.pad();

      expect(output.offset, equals(4)); // 2 bytes + 2 padding
    });

    test('DataOutput pad method adds correct padding for offset 3', () {
      final output = DataOutput();
      output.writeByte(1);
      output.offset = 3; // Manually set to test pad behavior
      output.pad();

      expect(output.offset, equals(4)); // 3 bytes + 1 padding
    });

    test('DataOutput pad method adds no padding for offset 4', () {
      final output = DataOutput();
      output.writeInt(1); // writeInt calls write which calls pad
      final offsetBefore = output.offset;

      output.pad();
      expect(output.offset, equals(offsetBefore)); // No additional padding
    });

    test('DataInput offset tracking', () {
      final output = XdrDataOutputStream();
      output.writeInt(100);
      output.writeInt(200);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      expect(input.offset, equals(0));

      input.readInt();
      expect(input.offset, equals(4));

      input.readInt();
      expect(input.offset, equals(8));
    });

    test('DataInput fileLength returns correct value', () {
      final output = XdrDataOutputStream();
      output.writeInt(1);
      output.writeInt(2);
      output.writeInt(3);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      expect(input.fileLength, equals(output.bytes.length));
    });

    test('multiple write operations maintain correct padding', () {
      final output = XdrDataOutputStream();
      output.write([0x01]); // 1 byte + 3 padding
      output.write([0x02, 0x03]); // 2 bytes + 2 padding
      output.write([0x04, 0x05, 0x06]); // 3 bytes + 1 padding
      output.write([0x07, 0x08, 0x09, 0x0A]); // 4 bytes + 0 padding

      // Total should be 16 bytes (with padding)
      expect(output.bytes.length, equals(16));
    });
  });

  group('XdrDataInputStream - readString edge cases', () {
    test('readString with empty string', () {
      final output = XdrDataOutputStream();
      output.writeString('');

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      expect(input.readString(), equals(''));
    });

    test('readString with single character', () {
      final output = XdrDataOutputStream();
      output.writeString('A');

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      expect(input.readString(), equals('A'));
    });

    test('readString with special characters', () {
      final output = XdrDataOutputStream();
      output.writeString('Hello, World! @#\$%^&*()');

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      expect(input.readString(), equals('Hello, World! @#\$%^&*()'));
    });

    test('readString with unicode characters', () {
      final output = XdrDataOutputStream();
      output.writeString('Hello 世界 🌍');

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      expect(input.readString(), equals('Hello 世界 🌍'));
    });

    test('readString with newlines and tabs', () {
      final output = XdrDataOutputStream();
      output.writeString('Line1\nLine2\tTabbed');

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      expect(input.readString(), equals('Line1\nLine2\tTabbed'));
    });

    test('readString with long string', () {
      final longString = 'A' * 1000;
      final output = XdrDataOutputStream();
      output.writeString(longString);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      expect(input.readString(), equals(longString));
    });

    test('readString with string requiring padding', () {
      final output = XdrDataOutputStream();
      output.writeString('ABC'); // 3 chars, needs 1 byte padding

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      expect(input.readString(), equals('ABC'));
    });
  });

  group('XdrDataOutputStream - writeString edge cases', () {
    test('writeString throws on string longer than 65535 bytes', () {
      final output = XdrDataOutputStream();
      final tooLongString = 'A' * 65536;

      expect(() => output.writeString(tooLongString), throwsFormatException);
    });

    test('writeString at max length boundary', () {
      final output = XdrDataOutputStream();
      final maxString = 'A' * 65535;

      expect(() => output.writeString(maxString), returnsNormally);
    });

    test('writeString with empty string has correct length', () {
      final output = XdrDataOutputStream();
      output.writeString('');

      expect(output.bytes.length, greaterThan(0)); // Should have length prefix
    });

    test('writeString pads correctly for 1-byte string', () {
      final output = XdrDataOutputStream();
      output.writeString('A');

      // 4 bytes (length) + 1 byte (char) + 3 bytes (padding) = 8 bytes
      expect(output.bytes.length, equals(8));
    });

    test('writeString pads correctly for 2-byte string', () {
      final output = XdrDataOutputStream();
      output.writeString('AB');

      // 4 bytes (length) + 2 bytes (chars) + 2 bytes (padding) = 8 bytes
      expect(output.bytes.length, equals(8));
    });

    test('writeString pads correctly for 3-byte string', () {
      final output = XdrDataOutputStream();
      output.writeString('ABC');

      // 4 bytes (length) + 3 bytes (chars) + 1 byte (padding) = 8 bytes
      expect(output.bytes.length, equals(8));
    });

    test('writeString no padding for 4-byte string', () {
      final output = XdrDataOutputStream();
      output.writeString('ABCD');

      // 4 bytes (length) + 4 bytes (chars) + 0 bytes (padding) = 8 bytes
      expect(output.bytes.length, equals(8));
    });
  });

  group('XdrDataInputStream - Array reading', () {
    test('readIntArray with empty array', () {
      final output = XdrDataOutputStream();
      output.writeIntArray([]);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final result = input.readIntArray();

      expect(result.length, equals(0));
    });

    test('readIntArray with single element', () {
      final output = XdrDataOutputStream();
      output.writeIntArray([42]);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final result = input.readIntArray();

      expect(result.length, equals(1));
      expect(result[0], equals(42));
    });

    test('readIntArray with multiple elements', () {
      final output = XdrDataOutputStream();
      output.writeIntArray([1, 2, 3, 4, 5]);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final result = input.readIntArray();

      expect(result.length, equals(5));
      expect(result[0], equals(1));
      expect(result[4], equals(5));
    });

    test('readIntArray with negative values', () {
      final output = XdrDataOutputStream();
      output.writeIntArray([-100, 0, 100]);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final result = input.readIntArray();

      expect(result.length, equals(3));
      expect(result[0], equals(-100));
      expect(result[1], equals(0));
      expect(result[2], equals(100));
    });

    test('readFloatArray with empty array', () {
      final output = XdrDataOutputStream();
      output.writeFloatArray([]);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final result = input.readFloatArray();

      expect(result.length, equals(0));
    });

    test('readFloatArray with single element', () {
      final output = XdrDataOutputStream();
      output.writeFloatArray([3.14]);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final result = input.readFloatArray();

      expect(result.length, equals(1));
      expect(result[0], closeTo(3.14, 0.001));
    });

    test('readFloatArray with multiple elements', () {
      final output = XdrDataOutputStream();
      output.writeFloatArray([1.1, 2.2, 3.3]);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final result = input.readFloatArray();

      expect(result.length, equals(3));
      expect(result[0], closeTo(1.1, 0.001));
      expect(result[2], closeTo(3.3, 0.001));
    });

    test('readFloatArray with zero and negative values', () {
      final output = XdrDataOutputStream();
      output.writeFloatArray([-1.5, 0.0, 1.5]);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final result = input.readFloatArray();

      expect(result.length, equals(3));
      expect(result[0], closeTo(-1.5, 0.001));
      expect(result[1], equals(0.0));
      expect(result[2], closeTo(1.5, 0.001));
    });

    test('readDoubleArray with empty array', () {
      final output = XdrDataOutputStream();
      output.writeDoubleArray([]);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final result = input.readDoubleArray();

      expect(result.length, equals(0));
    });

    test('readDoubleArray with single element', () {
      final output = XdrDataOutputStream();
      output.writeDoubleArray([3.141592653589793]);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final result = input.readDoubleArray();

      expect(result.length, equals(1));
      expect(result[0], closeTo(3.141592653589793, 0.0000001));
    });

    test('readDoubleArray with multiple elements', () {
      final output = XdrDataOutputStream();
      output.writeDoubleArray([1.1, 2.2, 3.3, 4.4]);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final result = input.readDoubleArray();

      expect(result.length, equals(4));
      expect(result[0], closeTo(1.1, 0.0001));
      expect(result[3], closeTo(4.4, 0.0001));
    });

    test('readDoubleArray with very large and small values', () {
      final output = XdrDataOutputStream();
      output.writeDoubleArray([1.7976931348623157e308, 2.2250738585072014e-308]);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final result = input.readDoubleArray();

      expect(result.length, equals(2));
      expect(result[0], closeTo(1.7976931348623157e308, 1e293));
      expect(result[1], closeTo(2.2250738585072014e-308, 1e-309));
    });
  });

  group('DataInput - readFully edge cases', () {
    test('readFully with both len and off adds bytes to list', () {
      final output = DataOutput();
      output.data = [1, 2, 3, 4, 5];

      final input = DataInput.fromUint8List(Uint8List.fromList(output.data));
      final bytes = List<int>.filled(5, 0, growable: true);
      final originalLength = bytes.length;
      input.readFully(bytes, len: 3, off: 0);

      // readFully with len/off adds bytes via addAll, growing the list
      expect(bytes.length, greaterThan(originalLength));
    });

    test('readFully throws when only len is provided', () {
      final output = DataOutput();
      output.data = [1, 2, 3];

      final input = DataInput.fromUint8List(Uint8List.fromList(output.data));
      final bytes = List<int>.filled(3, 0);

      expect(() => input.readFully(bytes, len: 3), throwsArgumentError);
    });

    test('readFully throws when only off is provided', () {
      final output = DataOutput();
      output.data = [1, 2, 3];

      final input = DataInput.fromUint8List(Uint8List.fromList(output.data));
      final bytes = List<int>.filled(3, 0);

      expect(() => input.readFully(bytes, off: 0), throwsArgumentError);
    });

    test('readFully throws when len is negative', () {
      final output = DataOutput();
      output.data = [1, 2, 3];

      final input = DataInput.fromUint8List(Uint8List.fromList(output.data));
      final bytes = List<int>.filled(3, 0);

      expect(() => input.readFully(bytes, len: -1, off: 0), throwsRangeError);
    });

    test('readFully throws when off is negative', () {
      final output = DataOutput();
      output.data = [1, 2, 3];

      final input = DataInput.fromUint8List(Uint8List.fromList(output.data));
      final bytes = List<int>.filled(3, 0);

      expect(() => input.readFully(bytes, len: 3, off: -1), throwsRangeError);
    });

    test('readFully with len=0 returns immediately', () {
      final output = DataOutput();
      output.data = [1, 2, 3];

      final input = DataInput.fromUint8List(Uint8List.fromList(output.data));
      final bytes = List<int>.filled(3, 0);

      input.readFully(bytes, len: 0, off: 0);

      expect(bytes[0], equals(0)); // Should remain unchanged
    });

    test('readFully without len/off reads all bytes', () {
      final output = DataOutput();
      output.data = [1, 2, 3];

      final input = DataInput.fromUint8List(Uint8List.fromList(output.data));
      final bytes = List<int>.filled(3, 0);

      input.readFully(bytes);

      expect(bytes[0], equals(1));
      expect(bytes[1], equals(2));
      expect(bytes[2], equals(3));
    });
  });

  group('DataInput - skipBytes edge cases', () {
    test('skipBytes returns actual bytes skipped when within bounds', () {
      final output = DataOutput();
      output.data = [1, 2, 3, 4, 5];

      final input = DataInput.fromUint8List(Uint8List.fromList(output.data));
      final skipped = input.skipBytes(3);

      expect(skipped, equals(3));
      expect(input.offset, equals(3));
    });

    test('skipBytes returns partial skip when exceeding file length', () {
      final output = DataOutput();
      output.data = [1, 2, 3];

      final input = DataInput.fromUint8List(Uint8List.fromList(output.data));
      final skipped = input.skipBytes(10);

      expect(skipped, lessThan(10));
      expect(input.offset, equals(input.fileLength));
    });

    test('skipBytes with zero does nothing', () {
      final output = DataOutput();
      output.data = [1, 2, 3];

      final input = DataInput.fromUint8List(Uint8List.fromList(output.data));
      final initialOffset = input.offset;
      final skipped = input.skipBytes(0);

      expect(skipped, equals(0));
      expect(input.offset, equals(initialOffset));
    });

    test('skipBytes moves offset correctly', () {
      final output = DataOutput();
      output.data = [1, 2, 3, 4, 5];

      final input = DataInput.fromUint8List(Uint8List.fromList(output.data));
      input.skipBytes(2);

      expect(input.offset, equals(2));
    });
  });

  group('DataInput - readLine edge cases', () {
    test('readLine reads line with LF terminator', () {
      final output = DataOutput();
      // readUnsignedByte pre-increments offset, so a leading byte is needed
      output.data = [0, 72, 101, 108, 108, 111, 10]; // "Hello\n"

      final input = DataInput.fromUint8List(Uint8List.fromList(output.data));
      final line = input.readLine();

      expect(line, isA<String>());
      expect(line, isNotEmpty);
    });

    test('readLine returns string type', () {
      final output = DataOutput();
      output.data = [0, 65, 66, 67, 10]; // "\0ABC\n"

      final input = DataInput.fromUint8List(Uint8List.fromList(output.data));
      final result = input.readLine();

      expect(result, isA<String>());
    });
  });

  group('DataOutput - write methods edge cases', () {
    test('writeBoolean with true', () {
      final output = DataOutput();
      output.writeBoolean(true);

      final input = DataInput.fromUint8List(Uint8List.fromList(output.data));
      expect(input.readBoolean(), isTrue);
    });

    test('writeBoolean with false', () {
      final output = DataOutput();
      output.writeBoolean(false);

      final input = DataInput.fromUint8List(Uint8List.fromList(output.data));
      expect(input.readBoolean(), isFalse);
    });

    test('writeChar and readChar', () {
      final output = DataOutput();
      output.writeChar(65); // 'A'

      final input = DataInput.fromUint8List(Uint8List.fromList(output.data));
      expect(input.readChar(), equals('A'));
    });

    test('writeFloat with negative value', () {
      final output = DataOutput();
      output.writeFloat(-3.14);

      final input = DataInput.fromUint8List(Uint8List.fromList(output.data));
      expect(input.readFloat(), closeTo(-3.14, 0.001));
    });

    test('writeFloat with zero', () {
      final output = DataOutput();
      output.writeFloat(0.0);

      final input = DataInput.fromUint8List(Uint8List.fromList(output.data));
      expect(input.readFloat(), equals(0.0));
    });

    test('writeDouble with very small value', () {
      final output = DataOutput();
      output.writeDouble(1.23e-100);

      final input = DataInput.fromUint8List(Uint8List.fromList(output.data));
      expect(input.readDouble(), closeTo(1.23e-100, 1e-101));
    });

    test('writeDouble with very large value', () {
      final output = DataOutput();
      output.writeDouble(1.23e100);

      final input = DataInput.fromUint8List(Uint8List.fromList(output.data));
      expect(input.readDouble(), closeTo(1.23e100, 1e85));
    });

    test('writeShort with max value', () {
      final output = DataOutput();
      output.writeShort(32767); // 2^15 - 1

      final input = DataInput.fromUint8List(Uint8List.fromList(output.data));
      expect(input.readShort(), equals(32767));
    });

    test('writeShort with min value', () {
      final output = DataOutput();
      output.writeShort(-32768); // -2^15

      final input = DataInput.fromUint8List(Uint8List.fromList(output.data));
      expect(input.readShort(), equals(-32768));
    });
  });

  group('DataOutput - writeBigInt64 edge cases', () {
    test('writeBigInt64 with zero', () {
      final output = DataOutput();
      output.writeBigInt64(BigInt.zero);

      final input = DataInput.fromUint8List(Uint8List.fromList(output.data));
      expect(input.readBigInt64(), equals(BigInt.zero));
    });

    test('writeBigInt64 with max int64', () {
      final output = DataOutput();
      final maxInt64 = BigInt.parse('9223372036854775807');
      output.writeBigInt64(maxInt64);

      final input = DataInput.fromUint8List(Uint8List.fromList(output.data));
      expect(input.readBigInt64(), equals(maxInt64));
    });

    test('writeBigInt64 with negative value', () {
      final output = DataOutput();
      final negValue = BigInt.from(-1000000);
      output.writeBigInt64(negValue);

      final input = DataInput.fromUint8List(Uint8List.fromList(output.data));
      final result = input.readBigInt64Signed();
      expect(result, equals(negValue));
    });

    test('writeBigInt64 with small positive value', () {
      final output = DataOutput();
      output.writeBigInt64(BigInt.from(42));

      final input = DataInput.fromUint8List(Uint8List.fromList(output.data));
      expect(input.readBigInt64(), equals(BigInt.from(42)));
    });
  });

  group('DataOutput - writeUTF edge cases', () {
    test('writeUTF throws when string is too long', () {
      final output = DataOutput();
      final tooLong = 'A' * 65536;

      expect(() => output.writeUTF(tooLong), throwsFormatException);
    });

    test('writeUTF at boundary validates length check', () {
      final output = DataOutput();
      final atBoundary = 'A' * 65535;

      expect(() => output.writeUTF(atBoundary), returnsNormally);
      expect(output.data.length, greaterThan(0));
    });

    test('writeUTF encodes length as short', () {
      final output = DataOutput();
      output.writeUTF('test');

      expect(output.data.length, greaterThan(2));
      final input = DataInput.fromUint8List(Uint8List.fromList(output.data));
      final length = input.readShort();
      expect(length, equals(4));
    });
  });

  group('XdrDataInputStream - read method', () {
    test('read returns byte value', () {
      final output = DataOutput();
      output.data = [0, 42];
      output.offset = 2;

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      expect(input.read(), equals(42));
    });

    test('read advances offset', () {
      final output = DataOutput();
      output.data = [0, 42, 43];
      output.offset = 3;

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      input.read();
      expect(input.offset, greaterThan(0));
    });
  });

  group('XdrStellarMessage discriminants', () {
    test('should create ERROR_MSG', () {
      final msg = XdrStellarMessage(XdrMessageType.ERROR_MSG);
      expect(msg.discriminant, equals(XdrMessageType.ERROR_MSG));
    });

    test('should create AUTH_MSG', () {
      final msg = XdrStellarMessage(XdrMessageType.AUTH);
      expect(msg.discriminant, equals(XdrMessageType.AUTH));
    });

    test('should create DONT_HAVE', () {
      final msg = XdrStellarMessage(XdrMessageType.DONT_HAVE);
      expect(msg.discriminant, equals(XdrMessageType.DONT_HAVE));
    });

    test('should create GET_PEERS', () {
      final msg = XdrStellarMessage(XdrMessageType.GET_PEERS);
      expect(msg.discriminant, equals(XdrMessageType.GET_PEERS));
    });

    test('should create PEERS', () {
      final msg = XdrStellarMessage(XdrMessageType.PEERS);
      expect(msg.discriminant, equals(XdrMessageType.PEERS));
    });

    test('should create GET_TX_SET', () {
      final msg = XdrStellarMessage(XdrMessageType.GET_TX_SET);
      expect(msg.discriminant, equals(XdrMessageType.GET_TX_SET));
    });

    test('should create TX_SET', () {
      final msg = XdrStellarMessage(XdrMessageType.TX_SET);
      expect(msg.discriminant, equals(XdrMessageType.TX_SET));
    });

    test('should create TRANSACTION', () {
      final msg = XdrStellarMessage(XdrMessageType.TRANSACTION);
      expect(msg.discriminant, equals(XdrMessageType.TRANSACTION));
    });

    test('should create GET_SCP_QUORUMSET', () {
      final msg = XdrStellarMessage(XdrMessageType.GET_SCP_QUORUMSET);
      expect(msg.discriminant, equals(XdrMessageType.GET_SCP_QUORUMSET));
    });

    test('should create SCP_QUORUMSET', () {
      final msg = XdrStellarMessage(XdrMessageType.SCP_QUORUMSET);
      expect(msg.discriminant, equals(XdrMessageType.SCP_QUORUMSET));
    });

    test('should create SCP_MESSAGE', () {
      final msg = XdrStellarMessage(XdrMessageType.SCP_MESSAGE);
      expect(msg.discriminant, equals(XdrMessageType.SCP_MESSAGE));
    });

    test('should create GET_SCP_STATE', () {
      final msg = XdrStellarMessage(XdrMessageType.GET_SCP_STATE);
      expect(msg.discriminant, equals(XdrMessageType.GET_SCP_STATE));
    });

    test('should set error', () {
      final msg = XdrStellarMessage(XdrMessageType.ERROR_MSG);
      final error = XdrError(XdrErrorCode.ERR_MISC, 'testmessage      ');
      msg.error = error;
      expect(msg.error, equals(error));
    });

    test('should set auth', () {
      final msg = XdrStellarMessage(XdrMessageType.AUTH);
      final auth = XdrAuth(0);
      msg.auth = auth;
      expect(msg.auth, equals(auth));
    });

    test('should set dontHave', () {
      final msg = XdrStellarMessage(XdrMessageType.DONT_HAVE);
      final dontHave = XdrDontHave(XdrMessageType.TRANSACTION, XdrUint256(Uint8List(32)));
      msg.dontHave = dontHave;
      expect(msg.dontHave, equals(dontHave));
    });
  });

  group('XdrPrice setters', () {
    test('should set n', () {
      final price = XdrPrice(XdrInt32(1), XdrInt32(2));
      price.n = XdrInt32(3);
      expect(price.n.int32, equals(3));
    });

    test('should set d', () {
      final price = XdrPrice(XdrInt32(1), XdrInt32(2));
      price.d = XdrInt32(4);
      expect(price.d.int32, equals(4));
    });
  });

  group('XdrAsset setters', () {
    test('should set discriminant', () {
      final asset = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      asset.discriminant = XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4;
      expect(asset.discriminant, equals(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4));
    });
  });

  group('XdrLedgerKey setters', () {
    test('should set discriminant', () {
      final ledgerKey = XdrLedgerKey(XdrLedgerEntryType.ACCOUNT);
      ledgerKey.discriminant = XdrLedgerEntryType.TRUSTLINE;
      expect(ledgerKey.discriminant, equals(XdrLedgerEntryType.TRUSTLINE));
    });
  });
}
