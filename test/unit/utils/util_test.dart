import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/src/util.dart';
import 'package:stellar_flutter_sdk/src/xdr/xdr_type.dart';

void main() {
  group('Util Tests', () {
    group('checkNotNull', () {
      test('should return reference when not null', () {
        var value = "test";
        expect(checkNotNull(value, "Error"), equals("test"));
      });

      test('should throw exception when null', () {
        expect(
          () => checkNotNull(null, "Value cannot be null"),
          throwsA(isA<Exception>()),
        );
      });

      test('should include error message in exception', () {
        var errorMessage = "Custom error message";
        expect(
          () => checkNotNull(null, errorMessage),
          throwsA(
            predicate((e) => e is Exception && e.toString().contains(errorMessage)),
          ),
        );
      });
    });

    group('checkArgument', () {
      test('should not throw when expression is true', () {
        expect(() => checkArgument(true, "Error"), returnsNormally);
      });

      test('should throw when expression is false', () {
        expect(
          () => checkArgument(false, "Invalid argument"),
          throwsA(isA<Exception>()),
        );
      });

      test('should include error message in exception', () {
        var errorMessage = "Argument must be positive";
        expect(
          () => checkArgument(false, errorMessage),
          throwsA(
            predicate((e) => e is Exception && e.toString().contains(errorMessage)),
          ),
        );
      });
    });

    group('removeTailZero', () {
      test('should remove trailing zeros after decimal', () {
        expect(removeTailZero("123.4500"), equals("123.45"));
      });

      test('should remove decimal point when all zeros', () {
        expect(removeTailZero("100.000"), equals("100"));
      });

      test('should remove single trailing zero and decimal', () {
        expect(removeTailZero("5.0"), equals("5"));
      });

      test('should handle no trailing zeros', () {
        expect(removeTailZero("123.45"), equals("123.45"));
      });

      test('should handle strings without decimal point', () {
        expect(removeTailZero("123"), equals("123"));
        expect(removeTailZero("100"), equals("1"));
      });

      test('should handle very small decimals', () {
        expect(removeTailZero("0.0010"), equals("0.001"));
      });
    });

    group('isHexString', () {
      test('should return true for lowercase hex', () {
        expect(isHexString("1a2b3c"), isTrue);
      });

      test('should return true for uppercase hex', () {
        expect(isHexString("ABCDEF"), isTrue);
      });

      test('should return true for mixed case hex', () {
        expect(isHexString("1A2b3C"), isTrue);
      });

      test('should return false for non-hex characters', () {
        expect(isHexString("xyz123"), isFalse);
      });

      test('should return false for strings with spaces', () {
        expect(isHexString("12 34"), isFalse);
      });

      test('should return false for empty string', () {
        expect(isHexString(""), isFalse);
      });

      test('should return false for strings with special characters', () {
        expect(isHexString("12-34"), isFalse);
      });
    });
  });

  group('Util class methods', () {
    group('bytesToHex and hexToBytes', () {
      test('should convert bytes to hex', () {
        var bytes = Uint8List.fromList([255, 0, 128]);
        expect(Util.bytesToHex(bytes), equals("ff0080"));
      });

      test('should convert hex to bytes', () {
        var bytes = Util.hexToBytes("ff0080");
        expect(bytes, equals(Uint8List.fromList([255, 0, 128])));
      });

      test('should handle empty arrays', () {
        expect(Util.bytesToHex(Uint8List(0)), equals(""));
        expect(Util.hexToBytes("").length, equals(0));
      });

      test('should handle single byte', () {
        var bytes = Uint8List.fromList([42]);
        expect(Util.bytesToHex(bytes), equals("2a"));
        expect(Util.hexToBytes("2a"), equals(Uint8List.fromList([42])));
      });

      test('should be reversible', () {
        var original = Uint8List.fromList([1, 2, 3, 4, 5]);
        var hex = Util.bytesToHex(original);
        var restored = Util.hexToBytes(hex);
        expect(restored, equals(original));
      });
    });

    group('hash', () {
      test('should produce 32-byte SHA-256 hash', () {
        var data = Uint8List.fromList([1, 2, 3, 4]);
        var hash = Util.hash(data);
        expect(hash.length, equals(32));
      });

      test('should produce consistent hashes', () {
        var data = Uint8List.fromList([1, 2, 3, 4]);
        var hash1 = Util.hash(data);
        var hash2 = Util.hash(data);
        expect(hash1, equals(hash2));
      });

      test('should produce different hashes for different data', () {
        var data1 = Uint8List.fromList([1, 2, 3, 4]);
        var data2 = Uint8List.fromList([5, 6, 7, 8]);
        var hash1 = Util.hash(data1);
        var hash2 = Util.hash(data2);
        expect(hash1, isNot(equals(hash2)));
      });

      test('should handle empty data', () {
        var hash = Util.hash(Uint8List(0));
        expect(hash.length, equals(32));
      });
    });

    group('paddedByteArray', () {
      test('should pad to specified length', () {
        var bytes = Uint8List.fromList([1, 2, 3]);
        var padded = Util.paddedByteArray(bytes, 5);
        expect(padded.length, equals(5));
        expect(padded, equals(Uint8List.fromList([1, 2, 3, 0, 0])));
      });

      test('should not modify array at target length', () {
        var bytes = Uint8List.fromList([1, 2, 3]);
        var padded = Util.paddedByteArray(bytes, 3);
        expect(padded, equals(bytes));
      });

      test('should handle empty input', () {
        var padded = Util.paddedByteArray(Uint8List(0), 3);
        expect(padded, equals(Uint8List.fromList([0, 0, 0])));
      });
    });

    group('paddedByteArrayString', () {
      test('should pad string to specified length', () {
        var padded = Util.paddedByteArrayString("XLM", 5);
        expect(padded.length, equals(5));
        expect(padded.sublist(0, 3), equals(utf8.encode("XLM")));
        expect(padded[3], equals(0));
        expect(padded[4], equals(0));
      });

      test('should handle exact length', () {
        var padded = Util.paddedByteArrayString("XLM", 3);
        expect(padded, equals(utf8.encode("XLM")));
      });

      test('should handle empty string', () {
        var padded = Util.paddedByteArrayString("", 3);
        expect(padded, equals(Uint8List.fromList([0, 0, 0])));
      });
    });

    group('paddedByteArrayToString', () {
      test('should convert padded bytes to string', () {
        var bytes = Uint8List.fromList([88, 76, 77, 0, 0]);
        expect(Util.paddedByteArrayToString(bytes), equals("XLM"));
      });

      test('should handle non-padded bytes', () {
        var bytes = Uint8List.fromList([88, 76, 77]);
        expect(Util.paddedByteArrayToString(bytes), equals("XLM"));
      });

      test('should handle multiple null bytes', () {
        var bytes = Uint8List.fromList([65, 66, 0, 0, 0, 0]);
        expect(Util.paddedByteArrayToString(bytes), equals("AB"));
      });

      test('should roundtrip with paddedByteArrayString', () {
        var original = "TEST";
        var padded = Util.paddedByteArrayString(original, 10);
        var restored = Util.paddedByteArrayToString(padded);
        expect(restored, equals(original));
      });
    });

    group('stringIdToXdrHash', () {
      test('should convert hex string to 32-byte hash', () {
        var hex = "a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2";
        var hash = Util.stringIdToXdrHash(hex);
        expect(hash.hash.length, equals(32));
      });

      test('should pad short strings', () {
        var hex = "a1b2c3";
        var hash = Util.stringIdToXdrHash(hex);
        expect(hash.hash.length, equals(32));
      });

      test('should truncate long strings', () {
        var hex = "a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6";
        var hash = Util.stringIdToXdrHash(hex);
        expect(hash.hash.length, equals(32));
      });

      test('should handle lowercase hex', () {
        var hex = "abcdef1234567890";
        expect(() => Util.stringIdToXdrHash(hex), returnsNormally);
      });
    });

    group('createCryptoRandomString', () {
      test('should create random string', () {
        var str = Util.createCryptoRandomString();
        expect(str.isNotEmpty, isTrue);
      });

      test('should create different strings on each call', () {
        var str1 = Util.createCryptoRandomString();
        var str2 = Util.createCryptoRandomString();
        expect(str1, isNot(equals(str2)));
      });

      test('should respect length parameter', () {
        var str1 = Util.createCryptoRandomString(16);
        var str2 = Util.createCryptoRandomString(32);
        expect(str1.length, isNot(equals(str2.length)));
      });
    });

    group('appendEndpointToUrl', () {
      test('should append endpoint to URL without trailing slash', () {
        var url = "https://api.example.com/sep6";
        var endpoint = "info";
        var result = Util.appendEndpointToUrl(url, endpoint);
        expect(result.toString(), equals("https://api.example.com/sep6/info"));
      });

      test('should handle URL with trailing slash', () {
        var url = "https://api.example.com/sep6/";
        var endpoint = "info";
        var result = Util.appendEndpointToUrl(url, endpoint);
        expect(result.toString(), equals("https://api.example.com/sep6/info"));
      });

      test('should handle empty endpoint', () {
        var url = "https://api.example.com";
        var endpoint = "";
        var result = Util.appendEndpointToUrl(url, endpoint);
        expect(result.toString(), equals("https://api.example.com/"));
      });

      test('should handle endpoint with leading slash', () {
        var url = "https://api.example.com";
        var endpoint = "/info";
        var result = Util.appendEndpointToUrl(url, endpoint);
        expect(result.toString(), equals("https://api.example.com//info"));
      });
    });

    group('toXdrBigInt64Amount and fromXdrBigInt64Amount', () {
      test('should convert decimal to stroops', () {
        var stroops = Util.toXdrBigInt64Amount("100.5");
        expect(stroops, equals(BigInt.from(1005000000)));
      });

      test('should convert stroops to decimal', () {
        var amount = Util.fromXdrBigInt64Amount(BigInt.from(1005000000));
        expect(amount, equals("100.5"));
      });

      test('should handle integer amounts', () {
        var stroops = Util.toXdrBigInt64Amount("100");
        expect(stroops, equals(BigInt.from(1000000000)));

        var amount = Util.fromXdrBigInt64Amount(BigInt.from(1000000000));
        expect(amount, equals("100"));
      });

      test('should handle zero', () {
        var stroops = Util.toXdrBigInt64Amount("0");
        expect(stroops, equals(BigInt.zero));

        var amount = Util.fromXdrBigInt64Amount(BigInt.zero);
        expect(amount, equals("0"));
      });

      test('should handle 7 decimal places', () {
        var stroops = Util.toXdrBigInt64Amount("123.4567890");
        expect(stroops, equals(BigInt.from(1234567890)));
      });

      test('should throw on more than 7 decimal places', () {
        expect(
          () => Util.toXdrBigInt64Amount("123.45678901"),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle small amounts', () {
        var stroops = Util.toXdrBigInt64Amount("0.0000001");
        expect(stroops, equals(BigInt.one));

        var amount = Util.fromXdrBigInt64Amount(BigInt.one);
        expect(amount, equals("0.0000001"));
      });

      test('should remove trailing zeros', () {
        var amount = Util.fromXdrBigInt64Amount(BigInt.from(1230000000));
        expect(amount, equals("123"));
      });

      test('should be reversible', () {
        var original = "123.456";
        var stroops = Util.toXdrBigInt64Amount(original);
        var restored = Util.fromXdrBigInt64Amount(stroops);
        expect(restored, equals(original));
      });

      test('should handle large amounts', () {
        var largeAmount = "922337203685.4775807";
        var stroops = Util.toXdrBigInt64Amount(largeAmount);
        var restored = Util.fromXdrBigInt64Amount(stroops);
        expect(restored, equals(largeAmount));
      });
    });
  });

  group('Base32', () {
    group('encode', () {
      test('should encode bytes to Base32', () {
        var bytes = Uint8List.fromList([104, 101, 108, 108, 111]);
        var encoded = Base32.encode(bytes);
        expect(encoded, isNotEmpty);
      });

      test('should encode empty array', () {
        var encoded = Base32.encode(Uint8List(0));
        expect(encoded, equals(""));
      });

      test('should use correct alphabet', () {
        var bytes = Uint8List.fromList([0x00]);
        var encoded = Base32.encode(bytes);
        expect(encoded, matches(RegExp(r'^[A-Z2-7]+$')));
      });
    });

    group('encodeHexString', () {
      test('should encode hex string to Base32', () {
        var base32 = Base32.encodeHexString("48656c6c6f");
        expect(base32, isNotEmpty);
      });

      test('should handle lowercase hex', () {
        expect(() => Base32.encodeHexString("abcdef"), returnsNormally);
      });

      test('should handle uppercase hex', () {
        expect(() => Base32.encodeHexString("ABCDEF"), returnsNormally);
      });
    });

    group('decode', () {
      test('should decode Base32 to bytes', () {
        var encoded = Base32.encode(Uint8List.fromList([1, 2, 3]));
        var decoded = Base32.decode(encoded);
        expect(decoded, equals(Uint8List.fromList([1, 2, 3])));
      });

      test('should handle empty string', () {
        var decoded = Base32.decode("");
        expect(decoded.length, equals(0));
      });

      test('should be reversible', () {
        var original = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
        var encoded = Base32.encode(original);
        var decoded = Base32.decode(encoded);
        expect(decoded, equals(original));
      });
    });
  });

  group('Base16Codec', () {
    group('encode', () {
      test('should encode bytes to hex string', () {
        var bytes = [255, 0, 128];
        var encoded = base16encode(bytes);
        expect(encoded, equals("ff0080"));
      });

      test('should handle empty array', () {
        expect(base16encode([]), equals(""));
      });

      test('should pad single digit hex', () {
        var encoded = base16encode([0, 15]);
        expect(encoded, equals("000f"));
      });
    });

    group('decode', () {
      test('should decode hex string to bytes', () {
        var decoded = base16decode("ff0080");
        expect(decoded, equals([255, 0, 128]));
      });

      test('should handle empty string', () {
        expect(base16decode("").length, equals(0));
      });

      test('should be reversible', () {
        var original = [1, 2, 3, 4, 5];
        var encoded = base16encode(original);
        var decoded = base16decode(encoded);
        expect(decoded, equals(original));
      });
    });

    group('codec', () {
      test('should work with codec interface', () {
        const codec = Base16Codec();
        var bytes = [1, 2, 3];
        var encoded = codec.encode(bytes);
        var decoded = codec.decode(encoded);
        expect(decoded, equals(bytes));
      });
    });
  });
}
