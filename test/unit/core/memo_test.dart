import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:collection/collection.dart';

void main() {
  group('Memo', () {
    group('MemoNone', () {
      test('creates MemoNone instance', () {
        final memo = Memo.none();

        expect(memo, isA<MemoNone>());
      });

      test('MemoNone XDR round-trip', () {
        final memo = Memo.none();
        final xdr = memo.toXdr();
        final restored = Memo.fromXdr(xdr);

        expect(restored, isA<MemoNone>());
        expect(xdr.discriminant, equals(XdrMemoType.MEMO_NONE));
      });

      test('MemoNone equality', () {
        final memo1 = Memo.none();
        final memo2 = Memo.none();

        expect(memo1 == memo2, isTrue);
      });
    });

    group('MemoText', () {
      test('creates MemoText with valid string', () {
        final memo = Memo.text("Invoice 12345");

        expect(memo, isA<MemoText>());
        expect((memo as MemoText).text, equals("Invoice 12345"));
      });

      test('creates MemoText with empty string', () {
        final memo = Memo.text("");

        expect(memo, isA<MemoText>());
        expect((memo as MemoText).text, equals(""));
      });

      test('creates MemoText with max length 28 bytes', () {
        final text = "1234567890123456789012345678";
        final memo = Memo.text(text);

        expect(memo, isA<MemoText>());
        expect((memo as MemoText).text, equals(text));
        expect(utf8.encode(text).length, equals(28));
      });

      test('MemoText throws if text too long', () {
        final text = "12345678901234567890123456789";

        expect(
          () => Memo.text(text),
          throwsA(isA<MemoTooLongException>()),
        );
      });

      test('MemoText with unicode characters within byte limit', () {
        final text = "Payment 💰";
        final memo = Memo.text(text);

        expect(memo, isA<MemoText>());
        expect((memo as MemoText).text, equals(text));
        expect(utf8.encode(text).length, lessThanOrEqualTo(28));
      });

      test('MemoText throws if unicode text exceeds byte limit', () {
        final text = "😀😀😀😀😀😀😀😀";

        expect(
          () => Memo.text(text),
          throwsA(isA<MemoTooLongException>()),
        );
      });

      test('MemoText XDR round-trip', () {
        final memo = Memo.text("Test payment");
        final xdr = memo.toXdr();
        final restored = Memo.fromXdr(xdr);

        expect(restored, isA<MemoText>());
        expect((restored as MemoText).text, equals("Test payment"));
        expect(xdr.discriminant, equals(XdrMemoType.MEMO_TEXT));
      });

      test('MemoText equality', () {
        final memo1 = Memo.text("Invoice 123");
        final memo2 = Memo.text("Invoice 123");
        final memo3 = Memo.text("Invoice 456");

        expect(memo1 == memo2, isTrue);
        expect(memo1 == memo3, isFalse);
      });

      test('MemoText with special characters', () {
        final text = "Pay: \$100.00 @user#123";
        final memo = Memo.text(text);

        expect(memo, isA<MemoText>());
        expect((memo as MemoText).text, equals(text));
      });
    });

    group('MemoId', () {
      test('creates MemoId with valid id', () {
        final id = BigInt.from(987654321);
        final memo = Memo.id(id);

        expect(memo, isA<MemoId>());
        expect((memo as MemoId).getId(), equals(id));
      });

      test('creates MemoId with value 1', () {
        final id = BigInt.one;
        final memo = Memo.id(id);

        expect(memo, isA<MemoId>());
        expect((memo as MemoId).getId(), equals(id));
      });

      test('MemoId throws if id is zero', () {
        expect(
          () => Memo.id(BigInt.zero),
          throwsA(isA<Exception>()),
        );
      });

      test('creates MemoId with max uint64 value', () {
        final maxUint64 = BigInt.parse("18446744073709551615");
        final memo = Memo.id(maxUint64);

        expect(memo, isA<MemoId>());
        expect((memo as MemoId).getId(), equals(maxUint64));
      });

      test('MemoId XDR round-trip', () {
        final id = BigInt.from(123456789);
        final memo = Memo.id(id);
        final xdr = memo.toXdr();
        final restored = Memo.fromXdr(xdr);

        expect(restored, isA<MemoId>());
        expect((restored as MemoId).getId(), equals(id));
        expect(xdr.discriminant, equals(XdrMemoType.MEMO_ID));
      });

      test('MemoId equality', () {
        final memo1 = Memo.id(BigInt.from(12345));
        final memo2 = Memo.id(BigInt.from(12345));
        final memo3 = Memo.id(BigInt.from(54321));

        expect(memo1 == memo2, isTrue);
        expect(memo1 == memo3, isFalse);
      });

      test('MemoId with large number', () {
        final largeId = BigInt.parse("9999999999999999999");
        final memo = Memo.id(largeId);

        expect(memo, isA<MemoId>());
        expect((memo as MemoId).getId(), equals(largeId));
      });
    });

    group('MemoHash', () {
      test('creates MemoHash with valid 32-byte hash', () {
        final hash = Uint8List(32);
        for (int i = 0; i < 32; i++) {
          hash[i] = i;
        }
        final memo = Memo.hash(hash);

        expect(memo, isA<MemoHash>());
        expect(
          ListEquality().equals((memo as MemoHash).bytes, hash),
          isTrue,
        );
      });

      test('MemoHash pads hash shorter than 32 bytes', () {
        final hash = Uint8List.fromList([1, 2, 3, 4, 5]);
        final memo = Memo.hash(hash);

        expect(memo, isA<MemoHash>());
        expect((memo as MemoHash).bytes!.length, equals(32));
        expect((memo).bytes![0], equals(1));
        expect((memo).bytes![4], equals(5));
        expect((memo).bytes![31], equals(0));
      });

      test('MemoHash throws if hash exceeds 32 bytes', () {
        final hash = Uint8List(33);

        expect(
          () => Memo.hash(hash),
          throwsA(isA<MemoTooLongException>()),
        );
      });

      test('creates MemoHash from hex string', () {
        final hexString = "0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20";
        final memo = Memo.hashString(hexString);

        expect(memo, isA<MemoHash>());
        expect((memo as MemoHash).bytes!.length, equals(32));
        expect((memo).hexValue!.toLowerCase(), equals(hexString));
      });

      test('MemoHash XDR round-trip', () {
        final hash = Uint8List(32);
        for (int i = 0; i < 32; i++) {
          hash[i] = i;
        }
        final memo = Memo.hash(hash);
        final xdr = memo.toXdr();
        final restored = Memo.fromXdr(xdr);

        expect(restored, isA<MemoHash>());
        expect(
          ListEquality().equals((restored as MemoHash).bytes, hash),
          isTrue,
        );
        expect(xdr.discriminant, equals(XdrMemoType.MEMO_HASH));
      });

      test('MemoHash equality', () {
        final hash1 = Uint8List.fromList([1, 2, 3, 4, 5]);
        final hash2 = Uint8List.fromList([1, 2, 3, 4, 5]);
        final hash3 = Uint8List.fromList([5, 4, 3, 2, 1]);

        final memo1 = Memo.hash(hash1);
        final memo2 = Memo.hash(hash2);
        final memo3 = Memo.hash(hash3);

        expect(memo1 == memo2, isTrue);
        expect(memo1 == memo3, isFalse);
      });

      test('MemoHash hexValue returns correct hex', () {
        final hash = Uint8List.fromList([0xAB, 0xCD, 0xEF, 0x12]);
        final memo = Memo.hash(hash);

        expect((memo as MemoHash).hexValue, isNotNull);
        expect((memo).hexValue!.toUpperCase().startsWith("ABCDEF12"), isTrue);
      });

    });

    group('MemoReturnHash', () {
      test('creates MemoReturnHash with valid 32-byte hash', () {
        final hash = Uint8List(32);
        for (int i = 0; i < 32; i++) {
          hash[i] = i;
        }
        final memo = Memo.returnHash(hash);

        expect(memo, isA<MemoReturnHash>());
        expect(
          ListEquality().equals((memo as MemoReturnHash).bytes, hash),
          isTrue,
        );
      });

      test('MemoReturnHash pads hash shorter than 32 bytes', () {
        final hash = Uint8List.fromList([1, 2, 3, 4, 5]);
        final memo = Memo.returnHash(hash);

        expect(memo, isA<MemoReturnHash>());
        expect((memo as MemoReturnHash).bytes!.length, equals(32));
        expect((memo).bytes![0], equals(1));
        expect((memo).bytes![4], equals(5));
        expect((memo).bytes![31], equals(0));
      });

      test('MemoReturnHash throws if hash exceeds 32 bytes', () {
        final hash = Uint8List(33);

        expect(
          () => Memo.returnHash(hash),
          throwsA(isA<MemoTooLongException>()),
        );
      });

      test('creates MemoReturnHash from hex string', () {
        final hexString = "0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20";
        final memo = Memo.returnHashString(hexString);

        expect(memo, isA<MemoReturnHash>());
        expect((memo as MemoReturnHash).bytes!.length, equals(32));
      });

      test('MemoReturnHash XDR round-trip', () {
        final hash = Uint8List(32);
        for (int i = 0; i < 32; i++) {
          hash[i] = i;
        }
        final memo = Memo.returnHash(hash);
        final xdr = memo.toXdr();
        final restored = Memo.fromXdr(xdr);

        expect(restored, isA<MemoReturnHash>());
        expect(
          ListEquality().equals((restored as MemoReturnHash).bytes, hash),
          isTrue,
        );
        expect(xdr.discriminant, equals(XdrMemoType.MEMO_RETURN));
      });

      test('MemoReturnHash equality', () {
        final hash1 = Uint8List.fromList([1, 2, 3, 4, 5]);
        final hash2 = Uint8List.fromList([1, 2, 3, 4, 5]);
        final hash3 = Uint8List.fromList([5, 4, 3, 2, 1]);

        final memo1 = Memo.returnHash(hash1);
        final memo2 = Memo.returnHash(hash2);
        final memo3 = Memo.returnHash(hash3);

        expect(memo1 == memo2, isTrue);
        expect(memo1 == memo3, isFalse);
      });

      test('MemoReturnHash hexValue returns correct hex', () {
        final hash = Uint8List.fromList([0xAB, 0xCD, 0xEF, 0x12]);
        final memo = Memo.returnHash(hash);

        expect((memo as MemoReturnHash).hexValue, isNotNull);
        expect((memo).hexValue!.toUpperCase().startsWith("ABCDEF12"), isTrue);
      });
    });

    group('Memo type checking', () {
      test('can distinguish MemoNone type', () {
        final memo = Memo.none();

        expect(memo is MemoNone, isTrue);
        expect(memo is MemoText, isFalse);
        expect(memo is MemoId, isFalse);
        expect(memo is MemoHash, isFalse);
        expect(memo is MemoReturnHash, isFalse);
      });

      test('can distinguish MemoText type', () {
        final memo = Memo.text("Test");

        expect(memo is MemoText, isTrue);
        expect(memo is MemoNone, isFalse);
        expect(memo is MemoId, isFalse);
        expect(memo is MemoHash, isFalse);
        expect(memo is MemoReturnHash, isFalse);
      });

      test('can distinguish MemoId type', () {
        final memo = Memo.id(BigInt.from(12345));

        expect(memo is MemoId, isTrue);
        expect(memo is MemoNone, isFalse);
        expect(memo is MemoText, isFalse);
        expect(memo is MemoHash, isFalse);
        expect(memo is MemoReturnHash, isFalse);
      });

      test('can distinguish MemoHash type', () {
        final hash = Uint8List(32);
        final memo = Memo.hash(hash);

        expect(memo is MemoHash, isTrue);
        expect(memo is MemoNone, isFalse);
        expect(memo is MemoText, isFalse);
        expect(memo is MemoId, isFalse);
        expect(memo is MemoReturnHash, isFalse);
      });

      test('can distinguish MemoReturnHash type', () {
        final hash = Uint8List(32);
        final memo = Memo.returnHash(hash);

        expect(memo is MemoReturnHash, isTrue);
        expect(memo is MemoNone, isFalse);
        expect(memo is MemoText, isFalse);
        expect(memo is MemoId, isFalse);
        expect(memo is MemoHash, isFalse);
      });
    });

    group('Memo.fromJson', () {
      test('fromJson creates MemoNone', () {
        final json = {'memo_type': 'none'};
        final memo = Memo.fromJson(json);

        expect(memo, isA<MemoNone>());
      });

      test('fromJson creates MemoText', () {
        final json = {'memo_type': 'text', 'memo': 'Invoice 123'};
        final memo = Memo.fromJson(json);

        expect(memo, isA<MemoText>());
        expect((memo as MemoText).text, equals('Invoice 123'));
      });

      test('fromJson creates MemoId', () {
        final json = {'memo_type': 'id', 'memo': '987654321'};
        final memo = Memo.fromJson(json);

        expect(memo, isA<MemoId>());
        expect((memo as MemoId).getId(), equals(BigInt.from(987654321)));
      });

      test('fromJson creates MemoHash', () {
        final hash = Uint8List.fromList([1, 2, 3, 4, 5]);
        final base64Hash = base64.encode(hash);
        final json = {'memo_type': 'hash', 'memo': base64Hash};
        final memo = Memo.fromJson(json);

        expect(memo, isA<MemoHash>());
        expect((memo as MemoHash).bytes, isNotNull);
      });

      test('fromJson creates MemoReturnHash', () {
        final hash = Uint8List.fromList([1, 2, 3, 4, 5]);
        final base64Hash = base64.encode(hash);
        final json = {'memo_type': 'return', 'memo': base64Hash};
        final memo = Memo.fromJson(json);

        expect(memo, isA<MemoReturnHash>());
        expect((memo as MemoReturnHash).bytes, isNotNull);
      });

      test('fromJson throws on unknown memo type', () {
        final json = {'memo_type': 'unknown', 'memo': 'value'};

        expect(
          () => Memo.fromJson(json),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Memo.fromStrings', () {
      test('fromStrings creates MemoNone', () {
        final memo = Memo.fromStrings('', 'none');

        expect(memo, isA<MemoNone>());
      });

      test('fromStrings creates MemoText', () {
        final memo = Memo.fromStrings('Invoice 123', 'text');

        expect(memo, isA<MemoText>());
        expect((memo as MemoText).text, equals('Invoice 123'));
      });

      test('fromStrings creates MemoId', () {
        final memo = Memo.fromStrings('987654321', 'id');

        expect(memo, isA<MemoId>());
        expect((memo as MemoId).getId(), equals(BigInt.from(987654321)));
      });

      test('fromStrings creates MemoHash', () {
        final hash = Uint8List.fromList([1, 2, 3, 4, 5]);
        final base64Hash = base64.encode(hash);
        final memo = Memo.fromStrings(base64Hash, 'hash');

        expect(memo, isA<MemoHash>());
        expect((memo as MemoHash).bytes, isNotNull);
      });

      test('fromStrings creates MemoReturnHash', () {
        final hash = Uint8List.fromList([1, 2, 3, 4, 5]);
        final base64Hash = base64.encode(hash);
        final memo = Memo.fromStrings(base64Hash, 'return');

        expect(memo, isA<MemoReturnHash>());
        expect((memo as MemoReturnHash).bytes, isNotNull);
      });
    });

    group('MemoTooLongException', () {
      test('MemoTooLongException has message', () {
        final exception = MemoTooLongException("Text too long");

        expect(exception.message, equals("Text too long"));
        expect(exception.toString(), contains("Text too long"));
      });

      test('MemoTooLongException without message', () {
        final exception = MemoTooLongException();

        expect(exception.toString(), equals("MemoTooLongException"));
      });
    });

    group('Edge cases', () {
      test('MemoText with exact 28-byte UTF-8 string', () {
        final text = "abcdefghijklmnopqrstuvwxyz12";
        final memo = Memo.text(text);

        expect(memo, isA<MemoText>());
        expect(utf8.encode(text).length, equals(28));
      });

      test('MemoHash with empty byte array gets padded', () {
        final hash = Uint8List(0);
        final memo = Memo.hash(hash);

        expect((memo as MemoHash).bytes!.length, equals(32));
        expect((memo).bytes!.every((b) => b == 0), isTrue);
      });

      test('MemoReturnHash with empty byte array gets padded', () {
        final hash = Uint8List(0);
        final memo = Memo.returnHash(hash);

        expect((memo as MemoReturnHash).bytes!.length, equals(32));
        expect((memo).bytes!.every((b) => b == 0), isTrue);
      });

      test('MemoHash from hex string handles uppercase', () {
        final hexString = "ABCDEF0123456789";
        final memo = Memo.hashString(hexString);

        expect(memo, isA<MemoHash>());
        expect((memo as MemoHash).bytes, isNotNull);
      });

      test('MemoReturnHash from hex string handles case insensitive', () {
        final hexStringUpper = "ABCDEF0123456789";
        final hexStringLower = "abcdef0123456789";

        final memo1 = Memo.returnHashString(hexStringUpper);
        final memo2 = Memo.returnHashString(hexStringLower);

        expect(
          ListEquality().equals(
            (memo1 as MemoReturnHash).bytes,
            (memo2 as MemoReturnHash).bytes,
          ),
          isTrue,
        );
      });

      test('MemoText with null character in string', () {
        final text = "Test\x00Memo";
        final memo = Memo.text(text);

        expect(memo, isA<MemoText>());
        expect((memo as MemoText).text, equals(text));
      });

      test('MemoId with BigInt.one is valid', () {
        final memo = Memo.id(BigInt.one);

        expect(memo, isA<MemoId>());
        expect((memo as MemoId).getId(), equals(BigInt.one));
      });
    });

    group('XDR conversions', () {
      test('all memo types XDR round-trip preserves data', () {
        final memos = [
          Memo.none(),
          Memo.text("Test"),
          Memo.id(BigInt.from(12345)),
          Memo.hash(Uint8List.fromList([1, 2, 3, 4, 5])),
          Memo.returnHash(Uint8List.fromList([5, 4, 3, 2, 1])),
        ];

        for (final memo in memos) {
          final xdr = memo.toXdr();
          final restored = Memo.fromXdr(xdr);

          expect(restored.runtimeType, equals(memo.runtimeType));

          if (memo is MemoText) {
            expect((restored as MemoText).text, equals(memo.text));
          } else if (memo is MemoId) {
            expect((restored as MemoId).getId(), equals(memo.getId()));
          } else if (memo is MemoHash) {
            expect(
              ListEquality().equals((restored as MemoHash).bytes, memo.bytes),
              isTrue,
            );
          } else if (memo is MemoReturnHash) {
            expect(
              ListEquality().equals((restored as MemoReturnHash).bytes, memo.bytes),
              isTrue,
            );
          }
        }
      });

      test('XDR discriminant values are correct', () {
        expect(
          Memo.none().toXdr().discriminant,
          equals(XdrMemoType.MEMO_NONE),
        );
        expect(
          Memo.text("Test").toXdr().discriminant,
          equals(XdrMemoType.MEMO_TEXT),
        );
        expect(
          Memo.id(BigInt.from(123)).toXdr().discriminant,
          equals(XdrMemoType.MEMO_ID),
        );
        expect(
          Memo.hash(Uint8List(32)).toXdr().discriminant,
          equals(XdrMemoType.MEMO_HASH),
        );
        expect(
          Memo.returnHash(Uint8List(32)).toXdr().discriminant,
          equals(XdrMemoType.MEMO_RETURN),
        );
      });
    });
  });
}
