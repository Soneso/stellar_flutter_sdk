// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/src/xdr/xdr_data_io.dart';

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

      // readByte advances offset then reads, so it reads at index 9 (value 0x0A = 10)
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
}
