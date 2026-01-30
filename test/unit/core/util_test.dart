// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('checkNotNull', () {
    test('returns value when not null', () {
      final result = checkNotNull('test', 'Error message');
      expect(result, equals('test'));
    });

    test('returns non-null integers', () {
      final result = checkNotNull(42, 'Error message');
      expect(result, equals(42));
    });

    test('returns non-null objects', () {
      final obj = {'key': 'value'};
      final result = checkNotNull(obj, 'Error message');
      expect(result, equals(obj));
    });

    test('throws Exception when value is null', () {
      expect(() => checkNotNull(null, 'Value cannot be null'),
          throwsA(isA<Exception>()));
    });

    test('includes error message in exception', () {
      try {
        checkNotNull(null, 'Custom error message');
        fail('Should have thrown');
      } on Exception catch (e) {
        expect(e.toString(), contains('Custom error message'));
      }
    });
  });

  group('checkArgument', () {
    test('does not throw when expression is true', () {
      expect(() => checkArgument(true, 'Error message'), returnsNormally);
      expect(() => checkArgument(1 == 1, 'Error'), returnsNormally);
      expect(() => checkArgument(5 > 3, 'Error'), returnsNormally);
    });

    test('throws Exception when expression is false', () {
      expect(() => checkArgument(false, 'Argument is invalid'),
          throwsA(isA<Exception>()));
    });

    test('throws Exception with correct message', () {
      try {
        checkArgument(1 > 2, 'One is not greater than two');
        fail('Should have thrown');
      } on Exception catch (e) {
        expect(e.toString(), contains('One is not greater than two'));
      }
    });

    test('evaluates complex expressions', () {
      expect(() => checkArgument(10 > 5 && 3 < 7, 'Error'), returnsNormally);
      expect(() => checkArgument(10 < 5 || 3 > 7, 'Invalid'),
          throwsA(isA<Exception>()));
    });
  });

  group('removeTailZero', () {
    test('removes trailing zeros after decimal', () {
      expect(removeTailZero('123.4500'), equals('123.45'));
      expect(removeTailZero('100.000'), equals('100'));
      expect(removeTailZero('5.0'), equals('5'));
    });

    test('removes decimal point when no significant digits remain', () {
      expect(removeTailZero('10.0000'), equals('10'));
      expect(removeTailZero('7.0'), equals('7'));
    });

    test('preserves strings without trailing zeros', () {
      expect(removeTailZero('123.45'), equals('123.45'));
      expect(removeTailZero('99.99'), equals('99.99'));
    });

    test('handles single zero after decimal', () {
      expect(removeTailZero('5.0'), equals('5'));
    });

    test('preserves zero before decimal', () {
      expect(removeTailZero('0.5'), equals('0.5'));
      expect(removeTailZero('0.0'), equals('0'));
    });

    test('handles multiple zeros', () {
      expect(removeTailZero('0.00000'), equals('0'));
      expect(removeTailZero('1.10000'), equals('1.1'));
    });

    test('handles strings without decimals', () {
      // removeTailZero removes trailing zeros even from integers
      expect(removeTailZero('100'), equals('1'));
      expect(removeTailZero('42'), equals('42'));
    });
  });

  group('isHexString', () {
    test('returns true for valid hex strings', () {
      expect(isHexString('1a2b3c'), isTrue);
      expect(isHexString('ABCDEF'), isTrue);
      expect(isHexString('0123456789'), isTrue);
      expect(isHexString('aAbBcCdDeEfF'), isTrue);
    });

    test('returns false for invalid hex strings', () {
      expect(isHexString('xyz123'), isFalse);
      expect(isHexString('12 34'), isFalse);
      expect(isHexString('12-34'), isFalse);
      expect(isHexString('g123'), isFalse);
    });

    test('returns false for empty string', () {
      expect(isHexString(''), isFalse);
    });

    test('returns true for uppercase hex', () {
      expect(isHexString('DEADBEEF'), isTrue);
    });

    test('returns true for lowercase hex', () {
      expect(isHexString('deadbeef'), isTrue);
    });

    test('returns true for mixed case hex', () {
      expect(isHexString('DeAdBeEf'), isTrue);
    });

    test('returns false for hex with spaces', () {
      expect(isHexString('ab cd'), isFalse);
    });
  });

  group('addressFromId', () {
    test('creates address from valid account ID', () {
      final accountId = 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H';
      final address = addressFromId(accountId);

      expect(address, isNotNull);
      expect(address!.type, equals(Address.TYPE_ACCOUNT));
      expect(address.accountId, equals(accountId));
    });

    test('returns null for contract ID (not supported by addressFromId)', () {
      final contractId = 'CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABSC4';
      final address = addressFromId(contractId);

      // addressFromId does not support contract IDs
      expect(address, isNull);
    });

    test('creates address from hex contract ID', () {
      final hexContractId =
          '0000000000000000000000000000000000000000000000000000000000000000';
      final address = addressFromId(hexContractId);

      expect(address, isNotNull);
      expect(address!.type, equals(Address.TYPE_CONTRACT));
    });

    test('creates address from muxed account ID', () {
      final muxedAccountId =
          'MAAAAAABGFQ36FMUQEJBVEBWVMPXIZAKSJYCLOECKPNZ4CFKSDCEWV75TR3C55HR2FJ24';
      final address = addressFromId(muxedAccountId);

      expect(address, isNotNull);
      expect(address!.type, equals(Address.TYPE_MUXED_ACCOUNT));
    });

    test('returns null for invalid ID', () {
      final address = addressFromId('INVALID_ID');
      expect(address, isNull);
    });

    test('returns null for empty string', () {
      final address = addressFromId('');
      expect(address, isNull);
    });
  });

  group('Util.bytesToHex', () {
    test('converts bytes to hex string', () {
      final bytes = Uint8List.fromList([255, 0, 128]);
      expect(Util.bytesToHex(bytes), equals('ff0080'));
    });

    test('handles empty byte array', () {
      final bytes = Uint8List.fromList([]);
      expect(Util.bytesToHex(bytes), equals(''));
    });

    test('handles single byte', () {
      final bytes = Uint8List.fromList([15]);
      expect(Util.bytesToHex(bytes), equals('0f'));
    });

    test('handles all zero bytes', () {
      final bytes = Uint8List.fromList([0, 0, 0]);
      expect(Util.bytesToHex(bytes), equals('000000'));
    });

    test('handles all 255 bytes', () {
      final bytes = Uint8List.fromList([255, 255, 255]);
      expect(Util.bytesToHex(bytes), equals('ffffff'));
    });
  });

  group('Util.hexToBytes', () {
    test('converts hex string to bytes', () {
      final bytes = Util.hexToBytes('ff0080');
      expect(bytes, equals(Uint8List.fromList([255, 0, 128])));
    });

    test('handles uppercase hex', () {
      final bytes = Util.hexToBytes('FF0080');
      expect(bytes, equals(Uint8List.fromList([255, 0, 128])));
    });

    test('handles mixed case hex', () {
      final bytes = Util.hexToBytes('Ff0080');
      expect(bytes, equals(Uint8List.fromList([255, 0, 128])));
    });

    test('handles empty string', () {
      final bytes = Util.hexToBytes('');
      expect(bytes.length, equals(0));
    });

    test('converts back and forth', () {
      final original = Uint8List.fromList([1, 2, 3, 4, 5]);
      final hex = Util.bytesToHex(original);
      final restored = Util.hexToBytes(hex);
      expect(restored, equals(original));
    });
  });

  group('Util.hash', () {
    test('computes SHA-256 hash', () {
      final data = Uint8List.fromList([1, 2, 3, 4]);
      final hash = Util.hash(data);

      expect(hash.length, equals(32));
    });

    test('produces different hashes for different input', () {
      final data1 = Uint8List.fromList([1, 2, 3]);
      final data2 = Uint8List.fromList([1, 2, 4]);

      final hash1 = Util.hash(data1);
      final hash2 = Util.hash(data2);

      expect(hash1, isNot(equals(hash2)));
    });

    test('produces same hash for same input', () {
      final data = Uint8List.fromList([1, 2, 3, 4]);

      final hash1 = Util.hash(data);
      final hash2 = Util.hash(data);

      expect(hash1, equals(hash2));
    });

    test('handles empty data', () {
      final data = Uint8List.fromList([]);
      final hash = Util.hash(data);

      expect(hash.length, equals(32));
    });
  });

  group('Util.paddedByteArray', () {
    test('pads byte array to specified length', () {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final padded = Util.paddedByteArray(bytes, 5);

      expect(padded.length, equals(5));
      expect(padded, equals(Uint8List.fromList([1, 2, 3, 0, 0])));
    });

    test('does not modify if already at target length', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final padded = Util.paddedByteArray(bytes, 5);

      expect(padded.length, equals(5));
      expect(padded, equals(bytes));
    });

    test('pads with zeros', () {
      final bytes = Uint8List.fromList([255]);
      final padded = Util.paddedByteArray(bytes, 3);

      expect(padded, equals(Uint8List.fromList([255, 0, 0])));
    });

    test('handles empty input', () {
      final bytes = Uint8List.fromList([]);
      final padded = Util.paddedByteArray(bytes, 3);

      expect(padded, equals(Uint8List.fromList([0, 0, 0])));
    });

    test('pads to larger size', () {
      final bytes = Uint8List.fromList([1, 2]);
      final padded = Util.paddedByteArray(bytes, 10);

      expect(padded.length, equals(10));
      expect(padded[0], equals(1));
      expect(padded[1], equals(2));
      for (int i = 2; i < 10; i++) {
        expect(padded[i], equals(0));
      }
    });
  });

  group('Util.paddedByteArrayString', () {
    test('pads string to specified length', () {
      final padded = Util.paddedByteArrayString('XLM', 4);

      expect(padded.length, equals(4));
      expect(padded[3], equals(0));
    });

    test('converts and pads correctly', () {
      final padded = Util.paddedByteArrayString('AB', 5);

      expect(padded.length, equals(5));
      expect(padded[0], equals(65)); // 'A'
      expect(padded[1], equals(66)); // 'B'
      expect(padded[2], equals(0));
      expect(padded[3], equals(0));
      expect(padded[4], equals(0));
    });

    test('handles empty string', () {
      final padded = Util.paddedByteArrayString('', 3);

      expect(padded.length, equals(3));
      expect(padded, equals(Uint8List.fromList([0, 0, 0])));
    });
  });

  group('Util.paddedByteArrayToString', () {
    test('removes trailing zeros and converts to string', () {
      final bytes = Uint8List.fromList([88, 76, 77, 0, 0]); // "XLM" + zeros
      final str = Util.paddedByteArrayToString(bytes);

      expect(str, equals('XLM'));
    });

    test('handles string without padding', () {
      final bytes = Uint8List.fromList([65, 66, 67]); // "ABC"
      final str = Util.paddedByteArrayToString(bytes);

      expect(str, equals('ABC'));
    });

    test('handles all zeros', () {
      final bytes = Uint8List.fromList([0, 0, 0]);
      final str = Util.paddedByteArrayToString(bytes);

      expect(str, equals(''));
    });

    test('round trip conversion', () {
      final original = 'USD';
      final bytes = Util.paddedByteArrayString(original, 6);
      final restored = Util.paddedByteArrayToString(bytes);

      expect(restored, equals(original));
    });
  });

  group('Util.stringIdToXdrHash', () {
    test('converts hex string to XdrHash', () {
      final hexId = 'a1b2c3d4e5f678901234567890abcdef1234567890abcdef1234567890abcdef';
      final xdrHash = Util.stringIdToXdrHash(hexId);

      expect(xdrHash.hash.length, equals(32));
    });

    test('pads short IDs to 32 bytes', () {
      final shortId = 'a1b2c3';
      final xdrHash = Util.stringIdToXdrHash(shortId);

      expect(xdrHash.hash.length, equals(32));
    });

    test('truncates long IDs to 32 bytes', () {
      final longId = 'a1b2c3d4e5f678901234567890abcdef1234567890abcdef1234567890abcdef' +
          'aabbccdd';
      final xdrHash = Util.stringIdToXdrHash(longId);

      expect(xdrHash.hash.length, equals(32));
    });
  });

  group('Util.createCryptoRandomString', () {
    test('creates random string of default length', () {
      final random = Util.createCryptoRandomString();
      expect(random.isNotEmpty, isTrue);
    });

    test('creates random string of specified length', () {
      final random = Util.createCryptoRandomString(16);
      expect(random.isNotEmpty, isTrue);
    });

    test('creates different strings on each call', () {
      final random1 = Util.createCryptoRandomString(32);
      final random2 = Util.createCryptoRandomString(32);

      expect(random1, isNot(equals(random2)));
    });

    test('creates strings with varying lengths', () {
      final short = Util.createCryptoRandomString(8);
      final long = Util.createCryptoRandomString(64);

      expect(short.isNotEmpty, isTrue);
      expect(long.isNotEmpty, isTrue);
    });
  });

  group('Util.appendEndpointToUrl', () {
    test('appends endpoint to URL without trailing slash', () {
      final url = Util.appendEndpointToUrl('https://api.example.com', 'info');
      expect(url.toString(), equals('https://api.example.com/info'));
    });

    test('handles base URL with trailing slash', () {
      final url = Util.appendEndpointToUrl('https://api.example.com/', 'info');
      expect(url.toString(), equals('https://api.example.com/info'));
    });

    test('appends multiple path segments', () {
      final url = Util.appendEndpointToUrl(
          'https://api.example.com', 'sep24/transactions');
      expect(url.toString(), equals('https://api.example.com/sep24/transactions'));
    });

    test('removes trailing slash before appending', () {
      final url = Util.appendEndpointToUrl('https://api.example.com/', 'fee');
      expect(url.toString(), equals('https://api.example.com/fee'));
    });
  });

  group('Util.toXdrBigInt64Amount', () {
    test('converts decimal amount to stroops', () {
      final stroops = Util.toXdrBigInt64Amount('100.5');
      expect(stroops, equals(BigInt.from(1005000000)));
    });

    test('converts integer amount', () {
      final stroops = Util.toXdrBigInt64Amount('100');
      expect(stroops, equals(BigInt.from(1000000000)));
    });

    test('handles small amounts', () {
      final stroops = Util.toXdrBigInt64Amount('0.0000001');
      expect(stroops, equals(BigInt.from(1)));
    });

    test('handles zero', () {
      final stroops = Util.toXdrBigInt64Amount('0');
      expect(stroops, equals(BigInt.zero));
    });

    test('removes trailing zeros from decimal', () {
      final stroops = Util.toXdrBigInt64Amount('100.5000000');
      expect(stroops, equals(BigInt.from(1005000000)));
    });

    test('handles maximum precision', () {
      final stroops = Util.toXdrBigInt64Amount('1.1234567');
      expect(stroops, equals(BigInt.from(11234567)));
    });

    test('throws on too many decimal places', () {
      expect(() => Util.toXdrBigInt64Amount('1.12345678'),
          throwsA(isA<Exception>()));
    });
  });

  group('Util.fromXdrBigInt64Amount', () {
    test('converts stroops to decimal amount', () {
      final amount = Util.fromXdrBigInt64Amount(BigInt.from(1005000000));
      expect(amount, equals('100.5'));
    });

    test('converts integer stroops', () {
      final amount = Util.fromXdrBigInt64Amount(BigInt.from(1000000000));
      expect(amount, equals('100'));
    });

    test('handles small amounts', () {
      final amount = Util.fromXdrBigInt64Amount(BigInt.from(1));
      expect(amount, equals('0.0000001'));
    });

    test('handles zero', () {
      final amount = Util.fromXdrBigInt64Amount(BigInt.zero);
      expect(amount, equals('0'));
    });

    test('removes trailing zeros', () {
      final amount = Util.fromXdrBigInt64Amount(BigInt.from(1005000000));
      expect(amount, equals('100.5'));
      expect(amount, isNot(equals('100.5000000')));
    });

    test('round trip conversion', () {
      final original = '123.456';
      final stroops = Util.toXdrBigInt64Amount(original);
      final restored = Util.fromXdrBigInt64Amount(stroops);
      expect(restored, equals(original));
    });
  });

  group('Base32', () {
    test('encodes bytes to base32', () {
      final bytes = Uint8List.fromList([104, 101, 108, 108, 111]); // "hello"
      final encoded = Base32.encode(bytes);
      expect(encoded.isNotEmpty, isTrue);
    });

    test('decodes base32 to bytes', () {
      final encoded = 'NBSWY3DP'; // "hello"
      final decoded = Base32.decode(encoded);
      expect(decoded.isNotEmpty, isTrue);
    });

    test('round trip encoding and decoding', () {
      final original = Uint8List.fromList([1, 2, 3, 4, 5]);
      final encoded = Base32.encode(original);
      final decoded = Base32.decode(encoded);
      expect(decoded, equals(original));
    });

    test('encodes hex string to base32', () {
      final encoded = Base32.encodeHexString('48656c6c6f');
      expect(encoded.isNotEmpty, isTrue);
    });

    test('handles empty byte array', () {
      final bytes = Uint8List.fromList([]);
      final encoded = Base32.encode(bytes);
      expect(encoded, equals(''));
    });
  });

  group('Base16 encoding', () {
    test('encodes bytes to hex using base16encode', () {
      final bytes = [255, 0, 128];
      final hex = base16encode(bytes);
      expect(hex, equals('ff0080'));
    });

    test('decodes hex to bytes using base16decode', () {
      final bytes = base16decode('ff0080');
      expect(bytes, equals([255, 0, 128]));
    });

    test('round trip base16 encoding', () {
      final original = [1, 2, 3, 4, 5];
      final encoded = base16encode(original);
      final decoded = base16decode(encoded);
      expect(decoded, equals(original));
    });

    test('Base16Codec encodes correctly', () {
      const codec = Base16Codec();
      final hex = codec.encode([255, 128, 0]);
      expect(hex, equals('ff8000'));
    });

    test('Base16Codec decodes correctly', () {
      const codec = Base16Codec();
      final bytes = codec.decode('ff8000');
      expect(bytes, equals([255, 128, 0]));
    });

    test('handles empty arrays', () {
      final encoded = base16encode([]);
      expect(encoded, equals(''));

      final decoded = base16decode('');
      expect(decoded.length, equals(0));
    });

    test('handles single byte', () {
      final encoded = base16encode([15]);
      expect(encoded, equals('0f'));

      final decoded = base16decode('0f');
      expect(decoded, equals([15]));
    });
  });
}
