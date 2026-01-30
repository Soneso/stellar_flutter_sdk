import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('XDR BigInt Web Compatibility', () {

    // Core type tests
    test('XdrInt64 handles max int64', () {
      BigInt maxInt64 = BigInt.parse('9223372036854775807');
      XdrInt64 xdr = XdrInt64(maxInt64);
      expect(xdr.int64, equals(maxInt64));

      XdrDataOutputStream out = XdrDataOutputStream();
      XdrInt64.encode(out, xdr);
      XdrDataInputStream inp = XdrDataInputStream(Uint8List.fromList(out.bytes));
      XdrInt64 decoded = XdrInt64.decode(inp);
      expect(decoded.int64, equals(maxInt64));
    });

    test('XdrInt64 handles min int64', () {
      BigInt minInt64 = BigInt.parse('-9223372036854775808');
      XdrInt64 xdr = XdrInt64(minInt64);
      expect(xdr.int64, equals(minInt64));

      XdrDataOutputStream out = XdrDataOutputStream();
      XdrInt64.encode(out, xdr);
      XdrDataInputStream inp = XdrDataInputStream(Uint8List.fromList(out.bytes));
      XdrInt64 decoded = XdrInt64.decode(inp);
      expect(decoded.int64, equals(minInt64));
    });

    test('XdrUint64 handles max uint64', () {
      BigInt maxUint64 = BigInt.parse('18446744073709551615');
      XdrUint64 xdr = XdrUint64(maxUint64);
      expect(xdr.uint64, equals(maxUint64));

      XdrDataOutputStream out = XdrDataOutputStream();
      XdrUint64.encode(out, xdr);
      XdrDataInputStream inp = XdrDataInputStream(Uint8List.fromList(out.bytes));
      XdrUint64 decoded = XdrUint64.decode(inp);
      expect(decoded.uint64, equals(maxUint64));
    });

    // Soroban type tests
    test('I128 handles -1 correctly', () {
      BigInt negOne = BigInt.from(-1);
      XdrSCVal scVal = XdrSCVal.forI128BigInt(negOne);
      BigInt? result = scVal.toBigInt();
      expect(result, equals(negOne));
    });

    test('I128 handles large negative values', () {
      BigInt large = BigInt.parse('-123456789012345678901234567890');
      XdrSCVal scVal = XdrSCVal.forI128BigInt(large);
      BigInt? result = scVal.toBigInt();
      expect(result, equals(large));
    });

    test('U128 handles large positive values', () {
      BigInt large = BigInt.from(2).pow(120);
      XdrSCVal scVal = XdrSCVal.forU128BigInt(large);
      BigInt? result = scVal.toBigInt();
      expect(result, equals(large));
    });

    test('I256 handles large negative values', () {
      BigInt large = -BigInt.from(2).pow(200);
      XdrSCVal scVal = XdrSCVal.forI256BigInt(large);
      BigInt? result = scVal.toBigInt();
      expect(result, equals(large));
    });

    test('U256 handles max value', () {
      BigInt max = BigInt.from(2).pow(256) - BigInt.one;
      XdrSCVal scVal = XdrSCVal.forU256BigInt(max);
      BigInt? result = scVal.toBigInt();
      expect(result, equals(max));
    });

    // Byte-level verification tests
    test('I128 -1 produces correct bytes', () {
      XdrSCVal scVal = XdrSCVal.forI128BigInt(BigInt.from(-1));
      XdrDataOutputStream out = XdrDataOutputStream();
      XdrSCVal.encode(out, scVal);
      List<int> bytes = out.bytes;

      // Skip discriminant (4 bytes), check I128 bytes (16 bytes of 0xFF)
      List<int> i128Bytes = bytes.sublist(4, 20);
      expect(i128Bytes, equals(List<int>.filled(16, 0xFF)));
    });

    test('U128 2^64 produces correct bytes', () {
      BigInt value = BigInt.from(2).pow(64);
      XdrSCVal scVal = XdrSCVal.forU128BigInt(value);
      XdrDataOutputStream out = XdrDataOutputStream();
      XdrSCVal.encode(out, scVal);
      List<int> bytes = out.bytes;

      // Skip discriminant (4 bytes)
      // hi = 1, lo = 0
      // Expected: 00 00 00 00 00 00 00 01 (hi) + 00 00 00 00 00 00 00 00 (lo)
      List<int> u128Bytes = bytes.sublist(4, 20);
      expect(u128Bytes, equals([0,0,0,0,0,0,0,1, 0,0,0,0,0,0,0,0]));
    });

    // High-level API tests
    test('MemoId handles large values', () {
      BigInt largeId = BigInt.parse('9007199254740993'); // 2^53 + 1
      MemoId memo = MemoId(largeId);
      expect(memo.getId(), equals(largeId));

      XdrMemo xdr = memo.toXdr();
      expect(xdr.id!.uint64, equals(largeId));
    });

    test('MuxedAccount handles large IDs', () {
      BigInt largeId = BigInt.parse('18446744073709551615'); // max uint64
      MuxedAccount muxed = MuxedAccount(
        'GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWHF',
        largeId
      );
      expect(muxed.id, equals(largeId));
    });

    // XDR roundtrip cross-platform verification
    test('XDR bytes identical for max uint64', () {
      BigInt value = BigInt.parse('18446744073709551615');
      XdrUint64 xdr = XdrUint64(value);

      XdrDataOutputStream out = XdrDataOutputStream();
      XdrUint64.encode(out, xdr);

      // These bytes should be identical regardless of platform
      expect(out.bytes, equals([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]));
    });

    // Boundary tests (2^53 boundary)
    test('Values at 2^53 boundary work correctly', () {
      BigInt boundary = BigInt.parse('9007199254740992'); // Exactly 2^53
      BigInt aboveBoundary = BigInt.parse('9007199254740993'); // 2^53 + 1

      for (BigInt value in [boundary, aboveBoundary]) {
        XdrUint64 xdr = XdrUint64(value);
        XdrDataOutputStream out = XdrDataOutputStream();
        XdrUint64.encode(out, xdr);
        XdrDataInputStream inp = XdrDataInputStream(Uint8List.fromList(out.bytes));
        XdrUint64 decoded = XdrUint64.decode(inp);
        expect(decoded.uint64, equals(value), reason: 'Failed for value $value');
      }
    });
  });
}
