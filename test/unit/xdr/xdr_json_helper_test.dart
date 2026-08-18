import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

/// Matches a [FormatException] whose message contains [fragment].
///
/// Only messages this SDK constructs are asserted on. The wording `jsonDecode`
/// produces differs between compilation targets, so nothing passed through from
/// it is pinned.
Matcher formatFailure(String fragment) => throwsA(
  isA<FormatException>().having(
    (FormatException e) => e.message,
    'message',
    contains(fragment),
  ),
);

/// A JSON document nesting [depth] arrays.
String nestedArrayText(int depth) => '${'[' * depth}${']' * depth}';

/// A tree nesting [depth] lists.
Object? nestedArrayValue(int depth) {
  Object? value = <Object?>[];
  for (int i = 1; i < depth; i++) {
    value = <Object?>[value];
  }
  return value;
}

void main() {
  // ---------------------------------------------------------------------------
  // Document boundary
  // ---------------------------------------------------------------------------
  group('XdrJsonHelper document boundary', () {
    test('encodes compactly with no whitespace', () {
      final String json = XdrJsonHelper.encodeDocument(<String, Object?>{
        'b': 1,
        'a': 2,
      }, type: 'T');
      expect(json, '{"b":1,"a":2}');
    });

    test('preserves insertion order rather than sorting keys', () {
      final String json = XdrJsonHelper.encodeDocument(<String, Object?>{
        'zebra': 1,
        'apple': 2,
        '10': 3,
        '2': 4,
      }, type: 'T');
      expect(json, '{"zebra":1,"apple":2,"10":3,"2":4}');
    });

    test('renders an empty array and an empty string', () {
      expect(
        XdrJsonHelper.encodeDocument(<String, Object?>{
          'a': <Object?>[],
          'b': '',
        }, type: 'T'),
        '{"a":[],"b":""}',
      );
    });

    test('decodes a document to a tree', () {
      final Object? value = XdrJsonHelper.decodeDocument(
        '{"a":[1,2]}',
        type: 'T',
      );
      expect(value, <String, Object?>{
        'a': <Object?>[1, 2],
      });
    });

    test('reports malformed JSON as a FormatException', () {
      expect(
        () => XdrJsonHelper.decodeDocument('[1,2,]', type: 'T'),
        formatFailure('could not be parsed as JSON'),
      );
    });

    test('escapes a backslash once in the ladder and once in JSON', () {
      final String escaped = XdrJsonHelper.escapedBytes(<int>[0x5C], type: 'T');
      expect(escaped, r'\\');
      expect(
        XdrJsonHelper.encodeDocument(<String, Object?>{
          'a': escaped,
        }, type: 'T'),
        r'{"a":"\\\\"}',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Nesting guards
  // ---------------------------------------------------------------------------
  group('XdrJsonHelper.guardTextDepth', () {
    test('accepts nesting exactly at the limit', () {
      expect(
        () => XdrJsonHelper.guardTextDepth(
          nestedArrayText(XdrJsonHelper.maxDepth),
          type: 'T',
        ),
        returnsNormally,
      );
    });

    test('rejects nesting one level past the limit', () {
      expect(
        () => XdrJsonHelper.guardTextDepth(
          nestedArrayText(XdrJsonHelper.maxDepth + 1),
          type: 'T',
        ),
        formatFailure('nests JSON containers more than 128 deep'),
      );
    });

    test('counts objects and arrays alike', () {
      final String text =
          '${'{"a":' * XdrJsonHelper.maxDepth}1${'}' * XdrJsonHelper.maxDepth}';
      expect(
        () => XdrJsonHelper.guardTextDepth(text, type: 'T'),
        returnsNormally,
      );
      final String deeper =
          '${'{"a":' * (XdrJsonHelper.maxDepth + 1)}1${'}' * (XdrJsonHelper.maxDepth + 1)}';
      expect(
        () => XdrJsonHelper.guardTextDepth(deeper, type: 'T'),
        formatFailure('nests JSON containers more than 128 deep'),
      );
    });

    test('rejects a repeated object key', () {
      expect(
        () => XdrJsonHelper.guardTextDepth('{"a":1,"a":2}', type: 'T'),
        formatFailure('repeats the object key "a"'),
      );
    });

    test('accepts the same key in sibling objects', () {
      expect(
        () => XdrJsonHelper.guardTextDepth(
          '{"x":{"a":1},"y":{"a":2}}',
          type: 'T',
        ),
        returnsNormally,
      );
    });

    test('accepts a repeated string value in an array', () {
      expect(
        () => XdrJsonHelper.guardTextDepth('["a","a"]', type: 'T'),
        returnsNormally,
      );
    });

    test('does not read braces inside a string as containers', () {
      expect(
        () => XdrJsonHelper.guardTextDepth(
          '{"a":"${'[' * (XdrJsonHelper.maxDepth + 5)}"}',
          type: 'T',
        ),
        returnsNormally,
      );
    });

    test('does not read an escaped quote as the end of a string', () {
      expect(
        () =>
            XdrJsonHelper.guardTextDepth(r'{"a":"x\":1,\"a","b":2}', type: 'T'),
        returnsNormally,
      );
    });

    test('tolerates unterminated text and leaves the parser to report it', () {
      expect(
        () => XdrJsonHelper.guardTextDepth('{"a":"unterminated', type: 'T'),
        returnsNormally,
      );
      expect(
        () => XdrJsonHelper.decodeDocument('{"a":"unterminated', type: 'T'),
        formatFailure('could not be parsed as JSON'),
      );
    });

    test('resolves the two-character JSON escapes when comparing keys', () {
      expect(
        () => XdrJsonHelper.guardTextDepth(r'{"a\nb":1,"a\nb":2}', type: 'T'),
        formatFailure('repeats the object key'),
      );
      expect(
        () => XdrJsonHelper.guardTextDepth(r'{"a\tb":1,"a\rb":2}', type: 'T'),
        returnsNormally,
      );
      expect(
        () => XdrJsonHelper.guardTextDepth(r'{"a\bb":1,"a\fb":2}', type: 'T'),
        returnsNormally,
      );
      expect(
        () => XdrJsonHelper.guardTextDepth(r'{"a\/b":1,"a/b":2}', type: 'T'),
        formatFailure('repeats the object key'),
      );
      expect(
        () => XdrJsonHelper.guardTextDepth(r'{"a\uZZZZ":1}', type: 'T'),
        returnsNormally,
      );
    });

    test('resolves a four-digit escape when comparing keys', () {
      expect(
        () => XdrJsonHelper.guardTextDepth(r'{"\u0061":1,"a":2}', type: 'T'),
        formatFailure('repeats the object key "a"'),
      );
      expect(
        () => XdrJsonHelper.guardTextDepth(r'{"\u0061":1,"b":2}', type: 'T'),
        returnsNormally,
      );
    });

    test('recognises a key separated from its colon by whitespace', () {
      expect(
        () => XdrJsonHelper.guardTextDepth('{"a" : 1, "a" : 2}', type: 'T'),
        formatFailure('repeats the object key "a"'),
      );
      expect(
        () => XdrJsonHelper.guardTextDepth('{"a"\n\t: 1,\r"b" : 2}', type: 'T'),
        returnsNormally,
      );
    });

    test('rejects a duplicate key that jsonDecode would resolve silently', () {
      // The parser itself keeps the last occurrence, so the guard is the only
      // thing that reports it.
      expect(jsonDecode('{"a":1,"a":2}'), <String, Object?>{'a': 2});
      expect(
        () => XdrJsonHelper.decodeDocument('{"a":1,"a":2}', type: 'T'),
        formatFailure('repeats the object key "a"'),
      );
    });
  });

  group('XdrJsonHelper.guardValueDepth', () {
    test('accepts nesting exactly at the limit', () {
      expect(
        () => XdrJsonHelper.guardValueDepth(
          nestedArrayValue(XdrJsonHelper.maxDepth),
          type: 'T',
        ),
        returnsNormally,
      );
    });

    test('rejects nesting one level past the limit', () {
      expect(
        () => XdrJsonHelper.guardValueDepth(
          nestedArrayValue(XdrJsonHelper.maxDepth + 1),
          type: 'T',
        ),
        formatFailure('nests JSON containers more than 128 deep'),
      );
    });

    test('agrees with the text scan on the boundary', () {
      final int limit = XdrJsonHelper.maxDepth;
      expect(
        () => XdrJsonHelper.guardValueDepth(nestedArrayValue(limit), type: 'T'),
        returnsNormally,
      );
      expect(
        () => XdrJsonHelper.guardTextDepth(nestedArrayText(limit), type: 'T'),
        returnsNormally,
      );
      expect(
        () => XdrJsonHelper.guardValueDepth(
          nestedArrayValue(limit + 1),
          type: 'T',
        ),
        formatFailure('128'),
      );
      expect(
        () =>
            XdrJsonHelper.guardTextDepth(nestedArrayText(limit + 1), type: 'T'),
        formatFailure('128'),
      );
    });

    test('accepts every scalar the JSON encoder can represent', () {
      expect(
        () => XdrJsonHelper.guardValueDepth(<String, Object?>{
          'a': null,
          'b': 'text',
          'c': true,
          'd': 1,
          'e': 1.5,
        }, type: 'T'),
        returnsNormally,
      );
    });

    test('rejects a non-finite double in the tree walk', () {
      for (final double value in <double>[
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        expect(
          () => XdrJsonHelper.guardValueDepth(<String, Object?>{
            'a': value,
          }, type: 'T'),
          formatFailure('which JSON cannot represent'),
          reason: 'accepted $value',
        );
      }
    });

    test('rejects a non-finite double before the encoder is reached', () {
      // jsonEncode reports these by raising an Error rather than an Exception,
      // which would escape the FormatException contract, so the guard must stop
      // them first.
      for (final double value in <double>[
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        expect(
          () => XdrJsonHelper.encodeDocument(<String, Object?>{
            'a': value,
          }, type: 'T'),
          formatFailure('which JSON cannot represent'),
          reason: 'accepted $value',
        );
      }
    });

    test('accepts a finite double', () {
      expect(
        XdrJsonHelper.encodeDocument(<String, Object?>{'a': 1.5}, type: 'T'),
        '{"a":1.5}',
      );
    });

    test('rejects a leaf the JSON encoder cannot represent', () {
      expect(
        () => XdrJsonHelper.guardValueDepth(<String, Object?>{
          'a': BigInt.one,
        }, type: 'T'),
        formatFailure('has no JSON representation'),
      );
    });

    test('rejects a non-string object key', () {
      expect(
        () => XdrJsonHelper.guardValueDepth(<Object?, Object?>{
          1: 'a',
        }, type: 'T'),
        formatFailure('non-string object key'),
      );
    });

    test('rejects a tree that refers to itself', () {
      final List<Object?> cycle = <Object?>[];
      cycle.add(cycle);
      expect(
        () => XdrJsonHelper.guardValueDepth(cycle, type: 'T'),
        formatFailure('nests JSON containers more than 128 deep'),
      );
    });

    test('guards before the encoder rather than catching after it', () {
      expect(
        () => XdrJsonHelper.encodeDocument(
          nestedArrayValue(XdrJsonHelper.maxDepth + 1),
          type: 'T',
        ),
        formatFailure('nests JSON containers more than 128 deep'),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Errors
  // ---------------------------------------------------------------------------
  group('XdrJsonHelper.fail and preview', () {
    test('names the type in the message', () {
      expect(
        () => XdrJsonHelper.fail('XdrThing', 'is wrong'),
        formatFailure('XDR-JSON XdrThing is wrong'),
      );
    });

    test('previews each kind of value', () {
      expect(XdrJsonHelper.preview(null), 'null');
      expect(XdrJsonHelper.preview(true), 'true');
      expect(XdrJsonHelper.preview(12), '12');
      expect(XdrJsonHelper.preview('ab'), '"ab"');
      expect(
        XdrJsonHelper.preview(<Object?>[1, 2]),
        'an array of 2 element(s)',
      );
      expect(
        XdrJsonHelper.preview(<String, Object?>{'a': 1}),
        'an object with 1 key(s)',
      );
      expect(XdrJsonHelper.preview(BigInt.from(7)), '7');
    });

    test('escapes control bytes and non-ASCII in a preview', () {
      expect(XdrJsonHelper.preview('a\nb'), r'"a\u000ab"');
      expect(XdrJsonHelper.preview('a\\b'), r'"a\\b"');
      expect(XdrJsonHelper.preview('café'), r'"caf\u00e9"');
    });

    test('truncates a long preview', () {
      expect(XdrJsonHelper.preview('x' * 200), '"${'x' * 40}..."');
      expect(XdrJsonHelper.preview('x' * 40), '"${'x' * 40}"');
    });

    test('cuts a preview between escapes rather than inside one', () {
      // The escape for e-acute is six characters wide. After 39 plain
      // characters there is no room for it, so the whole escape is dropped;
      // after 34 it fits exactly and is kept whole. Neither cut can leave a
      // partial escape behind.
      expect(XdrJsonHelper.preview('${'x' * 39}é'), '"${'x' * 39}..."');
      expect(
        XdrJsonHelper.preview('${'x' * 34}é'),
        '"${'x' * 34}${r'\u00e9'}"',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Integers
  // ---------------------------------------------------------------------------
  group('XdrJsonHelper 32-bit integers', () {
    test('renders values inside the range', () {
      expect(XdrJsonHelper.int32(-2147483648, type: 'T'), -2147483648);
      expect(XdrJsonHelper.int32(2147483647, type: 'T'), 2147483647);
      expect(XdrJsonHelper.uint32(0, type: 'T'), 0);
      expect(XdrJsonHelper.uint32(4294967295, type: 'T'), 4294967295);
    });

    test('rejects values outside the range on encode', () {
      expect(
        () => XdrJsonHelper.int32(-2147483649, type: 'T'),
        formatFailure('outside the range of an int32'),
      );
      expect(
        () => XdrJsonHelper.int32(2147483648, type: 'T', key: 'seq'),
        formatFailure('key "seq" holds 2147483648'),
      );
      expect(
        () => XdrJsonHelper.uint32(-1, type: 'T'),
        formatFailure('outside the range of a uint32'),
      );
      expect(
        () => XdrJsonHelper.uint32(4294967296, type: 'T'),
        formatFailure('outside the range of a uint32'),
      );
    });

    test('reads values inside the range', () {
      expect(XdrJsonHelper.readInt32(-2147483648, type: 'T'), -2147483648);
      expect(XdrJsonHelper.readInt32(2147483647, type: 'T'), 2147483647);
      expect(XdrJsonHelper.readUint32(0, type: 'T'), 0);
      expect(XdrJsonHelper.readUint32(4294967295, type: 'T'), 4294967295);
    });

    test('rejects a non-number', () {
      expect(
        () => XdrJsonHelper.readInt32('1', type: 'T'),
        formatFailure('expects a JSON number'),
      );
      expect(
        () => XdrJsonHelper.readUint32(null, type: 'T', key: 'flags'),
        formatFailure('key "flags" expects a JSON number'),
      );
    });

    test('rejects a number that is not whole', () {
      expect(
        () => XdrJsonHelper.readInt32(1.5, type: 'T'),
        formatFailure('expects a whole number'),
      );
      expect(
        () => XdrJsonHelper.readUint32(double.nan, type: 'T'),
        formatFailure('expects a whole number'),
      );
      expect(
        () => XdrJsonHelper.readUint32(double.infinity, type: 'T'),
        formatFailure('expects a whole number'),
      );
    });

    test('rejects values outside the range on decode', () {
      expect(
        () => XdrJsonHelper.readInt32(2147483648, type: 'T'),
        formatFailure('outside the range of an int32'),
      );
      expect(
        () => XdrJsonHelper.readUint32(-1, type: 'T'),
        formatFailure('outside the range of a uint32'),
      );
    });
  });

  group('XdrJsonHelper 64-bit integers', () {
    test('renders as a base-10 string, never a number', () {
      expect(XdrJsonHelper.int64(BigInt.from(-1), type: 'T'), '-1');
      expect(
        XdrJsonHelper.int64(XdrJsonHelper.int64Min, type: 'T'),
        '-9223372036854775808',
      );
      expect(
        XdrJsonHelper.int64(XdrJsonHelper.int64Max, type: 'T'),
        '9223372036854775807',
      );
      expect(XdrJsonHelper.uint64(BigInt.zero, type: 'T'), '0');
      expect(
        XdrJsonHelper.uint64(XdrJsonHelper.uint64Max, type: 'T'),
        '18446744073709551615',
      );
    });

    test('rejects values outside the range on encode', () {
      expect(
        () =>
            XdrJsonHelper.int64(XdrJsonHelper.int64Min - BigInt.one, type: 'T'),
        formatFailure('outside the range of an int64'),
      );
      expect(
        () =>
            XdrJsonHelper.int64(XdrJsonHelper.int64Max + BigInt.one, type: 'T'),
        formatFailure('outside the range of an int64'),
      );
      expect(
        () => XdrJsonHelper.uint64(BigInt.from(-1), type: 'T'),
        formatFailure('outside the range of a uint64'),
      );
      expect(
        () => XdrJsonHelper.uint64(
          XdrJsonHelper.uint64Max + BigInt.one,
          type: 'T',
        ),
        formatFailure('outside the range of a uint64'),
      );
    });

    test('reads the full range from a string with exact digits', () {
      expect(
        XdrJsonHelper.readInt64('-9223372036854775808', type: 'T'),
        XdrJsonHelper.int64Min,
      );
      expect(
        XdrJsonHelper.readInt64('9223372036854775807', type: 'T'),
        XdrJsonHelper.int64Max,
      );
      expect(
        XdrJsonHelper.readUint64('18446744073709551615', type: 'T'),
        XdrJsonHelper.uint64Max,
      );
      expect(XdrJsonHelper.readUint64('0', type: 'T'), BigInt.zero);
    });

    test('round-trips the extremes through a full document', () {
      final String json = XdrJsonHelper.encodeDocument(<String, Object?>{
        'lo': XdrJsonHelper.int64(XdrJsonHelper.int64Min, type: 'T'),
        'hi': XdrJsonHelper.uint64(XdrJsonHelper.uint64Max, type: 'T'),
      }, type: 'T');
      expect(json, '{"lo":"-9223372036854775808","hi":"18446744073709551615"}');

      final Map<String, dynamic> decoded = XdrJsonHelper.readObject(
        XdrJsonHelper.decodeDocument(json, type: 'T'),
        type: 'T',
      );
      expect(
        XdrJsonHelper.readInt64(decoded['lo'], type: 'T'),
        XdrJsonHelper.int64Min,
      );
      expect(
        XdrJsonHelper.readUint64(decoded['hi'], type: 'T'),
        XdrJsonHelper.uint64Max,
      );
    });

    test('accepts a JSON number for XDR-JSON v1 compatibility', () {
      expect(XdrJsonHelper.readUint64(100, type: 'T'), BigInt.from(100));
      expect(XdrJsonHelper.readInt64(-100, type: 'T'), BigInt.from(-100));
    });

    test('accepts a JSON number up to the exact limit of 2^53', () {
      expect(
        XdrJsonHelper.readUint64(9007199254740992, type: 'T'),
        BigInt.from(9007199254740992),
      );
      expect(
        XdrJsonHelper.readInt64(-9007199254740992, type: 'T'),
        -BigInt.from(9007199254740992),
      );
    });

    test('rejects a JSON number past 2^53, whatever its text', () {
      // Past 2^53 the decoder has already rounded, and the rounded value is a
      // whole number, so its text reads as a valid integer that is not the one
      // the document carried. Magnitude decides, which does not vary by target;
      // the text does.
      expect(
        () => XdrJsonHelper.readUint64(9007199254740994, type: 'T'),
        formatFailure('which a JSON number cannot carry exactly'),
      );
      expect(
        () => XdrJsonHelper.readUint64(1.8446744073709552e19, type: 'T'),
        formatFailure('which a JSON number cannot carry exactly'),
      );
      expect(
        () => XdrJsonHelper.readInt64(-1.8446744073709552e19, type: 'T'),
        formatFailure('which a JSON number cannot carry exactly'),
      );
    });

    test('rejects the int64 minimum supplied as a JSON number', () {
      // int.abs() overflows to itself at this value on the VM, so a bound
      // written with abs() would let this one input through there while
      // dart2js rejected it. The bound is on the signed value for that reason.
      expect(
        () => XdrJsonHelper.readInt64(-9223372036854775808, type: 'T'),
        formatFailure('which a JSON number cannot carry exactly'),
      );
      expect(
        () => XdrJsonHelper.decodeDocument('-9223372036854775808', type: 'T'),
        returnsNormally,
      );
      // The same value is accepted in the rendering the specification requires.
      expect(
        XdrJsonHelper.readInt64('-9223372036854775808', type: 'T'),
        XdrJsonHelper.int64Min,
      );
    });

    test('accepts the negative exact limit but not one step beyond', () {
      expect(
        XdrJsonHelper.readInt64(-9007199254740992, type: 'T'),
        -BigInt.from(9007199254740992),
      );
      expect(
        () => XdrJsonHelper.readInt64(-9007199254740994, type: 'T'),
        formatFailure('which a JSON number cannot carry exactly'),
      );
    });

    test('rejects a non-finite JSON number', () {
      expect(
        () => XdrJsonHelper.readInt64(double.nan, type: 'T'),
        formatFailure('which a JSON number cannot carry exactly'),
      );
      expect(
        () => XdrJsonHelper.readUint64(double.infinity, type: 'T'),
        formatFailure('which a JSON number cannot carry exactly'),
      );
    });

    test('rejects a JSON number that is not whole', () {
      expect(
        () => XdrJsonHelper.readInt64(1.5, type: 'T'),
        formatFailure('expects a base-10 int64 string'),
      );
    });

    test('rejects non-canonical decimal text', () {
      for (final String text in <String>[
        '',
        '+1',
        '007',
        '-0',
        '1.0',
        '1e10',
        '0x10',
        ' 1',
        '1 ',
        'abc',
        '-',
      ]) {
        expect(
          () => XdrJsonHelper.readInt64(text, type: 'T'),
          formatFailure('expects a base-10 int64 string'),
          reason: 'accepted $text',
        );
      }
    });

    test('rejects a value outside the range on decode', () {
      expect(
        () => XdrJsonHelper.readInt64('9223372036854775808', type: 'T'),
        formatFailure('outside the range of an int64'),
      );
      expect(
        () => XdrJsonHelper.readUint64('-1', type: 'T'),
        formatFailure('outside the range of a uint64'),
      );
      expect(
        () => XdrJsonHelper.readUint64('18446744073709551616', type: 'T'),
        formatFailure('outside the range of a uint64'),
      );
    });

    test('rejects a value that is neither a string nor a number', () {
      expect(
        () => XdrJsonHelper.readInt64(true, type: 'T', key: 'seqNum'),
        formatFailure('key "seqNum" expects a base-10 int64 string'),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Booleans, hex, arrays, optionals
  // ---------------------------------------------------------------------------
  group('XdrJsonHelper booleans', () {
    test('round-trips', () {
      expect(XdrJsonHelper.boolean(true), isTrue);
      expect(XdrJsonHelper.boolean(false), isFalse);
      expect(XdrJsonHelper.readBoolean(true, type: 'T'), isTrue);
      expect(XdrJsonHelper.readBoolean(false, type: 'T'), isFalse);
    });

    test('rejects a value that is not a boolean', () {
      expect(
        () => XdrJsonHelper.readBoolean(1, type: 'T'),
        formatFailure('expects a boolean'),
      );
      expect(
        () => XdrJsonHelper.readBoolean('true', type: 'T', key: 'auth'),
        formatFailure('key "auth" expects a boolean'),
      );
    });
  });

  group('XdrJsonHelper hexadecimal', () {
    test('renders lowercase, and empty as an empty string', () {
      expect(
        XdrJsonHelper.hex(
          Uint8List.fromList(<int>[0xDE, 0xAD, 0x00]),
          type: 'T',
        ),
        'dead00',
      );
      expect(XdrJsonHelper.hex(Uint8List(0), type: 'T'), '');
    });

    test('rejects bytes longer than the declared maximum on encode', () {
      final Uint8List bytes = Uint8List.fromList(<int>[1, 2, 3]);
      expect(
        () => XdrJsonHelper.hex(bytes, type: 'T', key: 'payload', maxLength: 2),
        formatFailure('key "payload" holds 3 bytes'),
      );
      expect(XdrJsonHelper.hex(bytes, type: 'T', maxLength: 3), '010203');
    });

    test('round-trips every byte value', () {
      final Uint8List all = Uint8List.fromList(
        List<int>.generate(256, (int i) => i),
      );
      expect(
        XdrJsonHelper.readHex(XdrJsonHelper.hex(all, type: 'T'), type: 'T'),
        all,
      );
    });

    test('reads an empty string as no bytes', () {
      expect(XdrJsonHelper.readHex('', type: 'T'), Uint8List(0));
    });

    test('rejects uppercase hexadecimal', () {
      expect(
        () => XdrJsonHelper.readHex('DEAD', type: 'T'),
        formatFailure('expects lowercase hexadecimal digits'),
      );
      expect(
        () => XdrJsonHelper.readHex('dEad', type: 'T'),
        formatFailure('expects lowercase hexadecimal digits'),
      );
    });

    test('rejects an odd number of digits', () {
      expect(
        () => XdrJsonHelper.readHex('abc', type: 'T'),
        formatFailure('odd number of hexadecimal digits'),
      );
    });

    test('rejects characters that are not hexadecimal', () {
      expect(
        () => XdrJsonHelper.readHex('zz', type: 'T'),
        formatFailure('expects lowercase hexadecimal digits'),
      );
      expect(
        () => XdrJsonHelper.readHex('0x10', type: 'T'),
        formatFailure('expects lowercase hexadecimal digits'),
      );
    });

    test('rejects a value that is not a string', () {
      expect(
        () => XdrJsonHelper.readHex(1, type: 'T', key: 'hash'),
        formatFailure('key "hash" expects a hexadecimal string'),
      );
    });

    test('validates a fixed length and a maximum length', () {
      expect(
        () => XdrJsonHelper.readHex('aabb', type: 'T', expectedLength: 3),
        formatFailure('holds 2 bytes but the declared length is 3'),
      );
      expect(
        XdrJsonHelper.readHex('aabb', type: 'T', expectedLength: 2).length,
        2,
      );
      expect(
        () => XdrJsonHelper.readHex('aabbcc', type: 'T', maxLength: 2),
        formatFailure('more than the declared maximum of 2'),
      );
      expect(XdrJsonHelper.readHex('aabb', type: 'T', maxLength: 2).length, 2);
    });
  });

  group('XdrJsonHelper arrays and optionals', () {
    test('renders an array, empty included', () {
      expect(
        XdrJsonHelper.array<int>(<int>[1, 2], (int v) => v, type: 'T'),
        <Object?>[1, 2],
      );
      expect(
        XdrJsonHelper.array<int>(<int>[], (int v) => v, type: 'T'),
        <Object?>[],
      );
    });

    test('rejects an array longer than the declared maximum on encode', () {
      expect(
        () => XdrJsonHelper.array<int>(
          <int>[1, 2, 3],
          (int v) => v,
          type: 'T',
          key: 'signers',
          maxLength: 2,
        ),
        formatFailure('key "signers" holds 3 elements'),
      );
    });

    test('rejects a lazy iterable longer than the declared maximum', () {
      // A lazy iterable has no length until it is walked, so this is the
      // post-build check rather than the one that runs ahead of encoding.
      final Iterable<int> lazy = <int>[1, 2, 3].map((int v) => v);
      expect(lazy, isNot(isA<List<int>>()));
      expect(
        () => XdrJsonHelper.array<int>(
          lazy,
          (int v) => v,
          type: 'T',
          key: 'signers',
          maxLength: 2,
        ),
        formatFailure('key "signers" holds 3 elements'),
      );
      expect(
        XdrJsonHelper.array<int>(lazy, (int v) => v, type: 'T', maxLength: 3),
        <Object?>[1, 2, 3],
      );
    });

    test('reads an array', () {
      expect(XdrJsonHelper.readArray(<Object?>[1, 2], type: 'T'), <Object?>[
        1,
        2,
      ]);
      expect(XdrJsonHelper.readArray(<Object?>[], type: 'T'), <Object?>[]);
    });

    test('rejects a value that is not an array', () {
      expect(
        () => XdrJsonHelper.readArray('x', type: 'T', key: 'signers'),
        formatFailure('key "signers" expects an array'),
      );
    });

    test('validates a fixed length and a maximum length', () {
      expect(
        () => XdrJsonHelper.readArray(<Object?>[1], type: 'T', fixedLength: 2),
        formatFailure('holds 1 elements but the declared length is 2'),
      );
      expect(
        XdrJsonHelper.readArray(
          <Object?>[1, 2],
          type: 'T',
          fixedLength: 2,
        ).length,
        2,
      );
      expect(
        () => XdrJsonHelper.readArray(
          <Object?>[1, 2, 3],
          type: 'T',
          maxLength: 2,
        ),
        formatFailure('more than the declared maximum of 2'),
      );
      expect(
        XdrJsonHelper.readArray(<Object?>[1], type: 'T', maxLength: 2).length,
        1,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Objects
  // ---------------------------------------------------------------------------
  group('XdrJsonHelper objects', () {
    test('reads a JSON object', () {
      expect(
        XdrJsonHelper.readObject(<String, dynamic>{'a': 1}, type: 'T'),
        <String, dynamic>{'a': 1},
      );
    });

    test('accepts a map that is not already typed on string keys', () {
      final Map<Object?, Object?> loose = <Object?, Object?>{'a': 1};
      expect(XdrJsonHelper.readObject(loose, type: 'T'), <String, dynamic>{
        'a': 1,
      });
    });

    test('rejects a value that is not an object', () {
      expect(
        () => XdrJsonHelper.readObject(<Object?>[1], type: 'T'),
        formatFailure('expects a JSON object'),
      );
    });

    test('rejects a non-string key', () {
      expect(
        () => XdrJsonHelper.readObject(<Object?, Object?>{1: 'a'}, type: 'T'),
        formatFailure('non-string object key'),
      );
    });

    test('accepts an object carrying only declared keys', () {
      expect(
        XdrJsonHelper.readObject(
          <String, dynamic>{'a': 1, 'b': 2},
          type: 'T',
          allowedKeys: const <String>{'a', 'b'},
        ),
        <String, dynamic>{'a': 1, 'b': 2},
      );
    });

    test('rejects an unknown key, naming the key and the type', () {
      expect(
        () => XdrJsonHelper.readObject(
          <String, dynamic>{'a': 1, 'foo': 2},
          type: 'XdrThing',
          allowedKeys: const <String>{'a'},
        ),
        throwsA(
          isA<FormatException>().having(
            (FormatException e) => e.message,
            'message',
            allOf(contains('XdrThing'), contains('has the unknown key "foo"')),
          ),
        ),
      );
    });

    test('names every unknown key, in a target-independent order', () {
      // Decoded key order differs between compilation targets, so the message
      // sorts rather than reporting the order it happened to see.
      expect(
        () => XdrJsonHelper.readObject(
          <String, dynamic>{'zeta': 1, 'a': 2, 'alpha': 3},
          type: 'T',
          allowedKeys: const <String>{'a'},
        ),
        formatFailure('has the unknown keys "alpha", "zeta"'),
      );
    });

    test('rejects an unknown key supplied alongside the schema property', () {
      expect(
        () => XdrJsonHelper.readObject(
          <String, dynamic>{r'$schema': 'x', 'a': 1, 'foo': 2},
          type: 'T',
          allowedKeys: const <String>{'a'},
        ),
        formatFailure('has the unknown key "foo"'),
      );
    });

    test('accepts the schema property against a declared key list', () {
      // The schema property is allowed but never required, and is the one key
      // accepted everywhere and declared nowhere.
      expect(
        XdrJsonHelper.readObject(
          <String, dynamic>{r'$schema': 'https://example.test/s', 'a': 1},
          type: 'T',
          allowedKeys: const <String>{'a'},
        ),
        <String, dynamic>{'a': 1},
      );
    });

    test('counts an input alias as its declared key', () {
      // A field accepting a second spelling contributes both to the key list;
      // readField is what holds a document to one of them.
      const Set<String> keys = <String>{'type', 'type_'};
      expect(
        XdrJsonHelper.readObject(
          <String, dynamic>{'type_': 1},
          type: 'T',
          allowedKeys: keys,
        ),
        <String, dynamic>{'type_': 1},
      );
      expect(
        XdrJsonHelper.readField(
          XdrJsonHelper.readObject(
            <String, dynamic>{'type_': 1},
            type: 'T',
            allowedKeys: keys,
          ),
          'type',
          type: 'T',
          alias: 'type_',
        ),
        1,
      );
    });

    test('rejects both spellings of an aliased key together', () {
      // Two spellings of one field are indistinguishable from a repeated key,
      // so the pair is refused rather than resolved to either one.
      const Set<String> keys = <String>{'type', 'type_'};
      final Map<String, dynamic> object = XdrJsonHelper.readObject(
        <String, dynamic>{'type': 1, 'type_': 2},
        type: 'T',
        allowedKeys: keys,
      );
      expect(
        () =>
            XdrJsonHelper.readField(object, 'type', type: 'T', alias: 'type_'),
        formatFailure('carries both "type" and its accepted alias "type_"'),
      );
    });

    test('strips the schema property without a declared key list', () {
      // The carve-out is in readObject, so it holds for the union arm path too,
      // which passes no key list.
      expect(
        XdrJsonHelper.readObject(<String, dynamic>{
          r'$schema': 'x',
          'a': 1,
        }, type: 'T'),
        <String, dynamic>{'a': 1},
      );
    });

    test('reads a union arm object that carries the schema property', () {
      final MapEntry<String, Object?> entry = XdrJsonHelper.readSingleKeyObject(
        <String, dynamic>{r'$schema': 'https://example.test/s', 'tx': 1},
        type: 'T',
      );
      expect(entry.key, 'tx');
      expect(entry.value, 1);
    });

    test('strips the schema property and leaves the argument unchanged', () {
      final Map<String, dynamic> source = <String, dynamic>{
        r'$schema': 'https://example.test/s',
        'a': 1,
      };
      final Map<String, dynamic> stripped = XdrJsonHelper.stripSchema(source);
      expect(stripped, <String, dynamic>{'a': 1});
      expect(source.containsKey(r'$schema'), isTrue);
    });

    test('returns the same map when there is no schema property', () {
      final Map<String, dynamic> source = <String, dynamic>{'a': 1};
      expect(identical(XdrJsonHelper.stripSchema(source), source), isTrue);
    });

    test('reads a required key', () {
      expect(
        XdrJsonHelper.readField(<String, dynamic>{'a': 1}, 'a', type: 'T'),
        1,
      );
    });

    test('distinguishes a null value from a missing key', () {
      expect(
        XdrJsonHelper.readField(<String, dynamic>{'a': null}, 'a', type: 'T'),
        isNull,
      );
      expect(
        () => XdrJsonHelper.readField(<String, dynamic>{}, 'a', type: 'T'),
        formatFailure('is missing the required key "a"'),
      );
    });

    test('accepts an alias for a key', () {
      expect(
        XdrJsonHelper.readField(
          <String, dynamic>{'type_': 1},
          'type',
          type: 'T',
          alias: 'type_',
        ),
        1,
      );
      expect(
        XdrJsonHelper.readField(
          <String, dynamic>{'type': 1},
          'type',
          type: 'T',
          alias: 'type_',
        ),
        1,
      );
    });

    test('rejects a key supplied under both spellings', () {
      expect(
        () => XdrJsonHelper.readField(
          <String, dynamic>{'type': 1, 'type_': 2},
          'type',
          type: 'T',
          alias: 'type_',
        ),
        formatFailure('carries both "type" and its accepted alias "type_"'),
      );
    });

    test('reads a single-key object', () {
      final MapEntry<String, Object?> entry = XdrJsonHelper.readSingleKeyObject(
        <String, dynamic>{'tx': 1},
        type: 'T',
      );
      expect(entry.key, 'tx');
      expect(entry.value, 1);
    });

    test('ignores the schema property when counting keys', () {
      final MapEntry<String, Object?> entry = XdrJsonHelper.readSingleKeyObject(
        <String, dynamic>{r'$schema': 'x', 'tx': 1},
        type: 'T',
      );
      expect(entry.key, 'tx');
    });

    test('rejects an object that does not hold exactly one key', () {
      expect(
        () => XdrJsonHelper.readSingleKeyObject(<String, dynamic>{}, type: 'T'),
        formatFailure('exactly one key'),
      );
      expect(
        () => XdrJsonHelper.readSingleKeyObject(<String, dynamic>{
          'a': 1,
          'b': 2,
        }, type: 'T'),
        formatFailure('exactly one key'),
      );
      expect(
        () => XdrJsonHelper.readSingleKeyObject(<String, dynamic>{
          r'$schema': 'x',
        }, type: 'T'),
        formatFailure('exactly one key'),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Strings
  // ---------------------------------------------------------------------------
  group('XdrJsonHelper escape ladder', () {
    test('renders the named escapes', () {
      expect(XdrJsonHelper.escapedBytes(<int>[0x00], type: 'T'), r'\0');
      expect(XdrJsonHelper.escapedBytes(<int>[0x09], type: 'T'), r'\t');
      expect(XdrJsonHelper.escapedBytes(<int>[0x0A], type: 'T'), r'\n');
      expect(XdrJsonHelper.escapedBytes(<int>[0x0D], type: 'T'), r'\r');
      expect(XdrJsonHelper.escapedBytes(<int>[0x5C], type: 'T'), r'\\');
    });

    test('passes printable ASCII through verbatim', () {
      expect(XdrJsonHelper.escapedBytes(<int>[0x20], type: 'T'), ' ');
      expect(XdrJsonHelper.escapedBytes(<int>[0x7E], type: 'T'), '~');
      expect(XdrJsonHelper.escapedBytes(<int>[0x22], type: 'T'), '"');
      expect(XdrJsonHelper.escapedBytes(<int>[0x2F], type: 'T'), '/');
    });

    test('escapes everything else as two lowercase hexadecimal digits', () {
      expect(XdrJsonHelper.escapedBytes(<int>[0x01], type: 'T'), r'\x01');
      expect(XdrJsonHelper.escapedBytes(<int>[0x1F], type: 'T'), r'\x1f');
      expect(XdrJsonHelper.escapedBytes(<int>[0x7F], type: 'T'), r'\x7f');
      expect(XdrJsonHelper.escapedBytes(<int>[0xFF], type: 'T'), r'\xff');
      expect(
        XdrJsonHelper.escapedBytes(<int>[0xC3, 0xC4], type: 'T'),
        r'\xc3\xc4',
      );
    });

    test('round-trips every byte value', () {
      final List<int> all = List<int>.generate(256, (int i) => i);
      final String escaped = XdrJsonHelper.escapedBytes(all, type: 'T');
      expect(
        XdrJsonHelper.readEscapedBytes(escaped, type: 'T'),
        Uint8List.fromList(all),
      );
    });

    test('renders empty input as an empty string', () {
      expect(XdrJsonHelper.escapedBytes(<int>[], type: 'T'), '');
      expect(XdrJsonHelper.readEscapedBytes('', type: 'T'), Uint8List(0));
    });

    test('rejects a value that is not a byte', () {
      expect(
        () => XdrJsonHelper.escapedBytes(<int>[256], type: 'T'),
        formatFailure('which is not a byte'),
      );
      expect(
        () => XdrJsonHelper.escapedBytes(<int>[-1], type: 'T', key: 'code'),
        formatFailure('key "code" holds -1'),
      );
    });

    test('rejects an uppercase hexadecimal escape', () {
      expect(
        () => XdrJsonHelper.readEscapedBytes(r'\xFF', type: 'T'),
        formatFailure('two lowercase hexadecimal digits'),
      );
      expect(
        () => XdrJsonHelper.readEscapedBytes(r'\xfF', type: 'T'),
        formatFailure('two lowercase hexadecimal digits'),
      );
    });

    test('rejects an escape the ladder does not define', () {
      expect(
        () => XdrJsonHelper.readEscapedBytes(r'\q', type: 'T'),
        formatFailure(r'unrecognised escape \q'),
      );
      expect(
        () => XdrJsonHelper.readEscapedBytes(r'\u0041', type: 'T'),
        formatFailure(r'unrecognised escape \u'),
      );
    });

    test('rejects a trailing backslash', () {
      expect(
        () => XdrJsonHelper.readEscapedBytes('a\\', type: 'T'),
        formatFailure('ends with an unfinished escape'),
      );
    });

    test('rejects a truncated hexadecimal escape', () {
      expect(
        () => XdrJsonHelper.readEscapedBytes(r'\x', type: 'T'),
        formatFailure(r'truncated \x escape'),
      );
      expect(
        () => XdrJsonHelper.readEscapedBytes(r'\xf', type: 'T'),
        formatFailure(r'truncated \x escape'),
      );
    });

    test('rejects an unescaped byte outside printable ASCII', () {
      expect(
        () => XdrJsonHelper.readEscapedBytes('a\u0001b', type: 'T'),
        formatFailure('unescaped character U+0001'),
      );
      expect(
        () => XdrJsonHelper.readEscapedBytes('caf\u00e9', type: 'T'),
        formatFailure('unescaped character U+00E9'),
      );
      expect(
        () => XdrJsonHelper.readEscapedBytes('a\u007fb', type: 'T'),
        formatFailure('unescaped character U+007F'),
      );
    });

    test('rejects a value that is not a string', () {
      expect(
        () => XdrJsonHelper.readEscapedBytes(1, type: 'T', key: 'msg'),
        formatFailure('key "msg" expects a string'),
      );
    });

    test('validates a fixed length and a maximum length', () {
      expect(
        () =>
            XdrJsonHelper.readEscapedBytes('ab', type: 'T', expectedLength: 3),
        formatFailure('holds 2 bytes but the declared length is 3'),
      );
      expect(
        () => XdrJsonHelper.readEscapedBytes('abc', type: 'T', maxLength: 2),
        formatFailure('more than the declared maximum of 2'),
      );
    });
  });

  group('XdrJsonHelper text strings', () {
    test('encodes to UTF-8 before applying the ladder', () {
      expect(XdrJsonHelper.escapedString('café', type: 'T'), r'caf\xc3\xa9');
      expect(
        XdrJsonHelper.readEscapedString(r'caf\xc3\xa9', type: 'T'),
        'café',
      );
    });

    test('round-trips text holding the named escapes', () {
      const String text = 'a\tb\nc\rd\\e\u0000f';
      final String escaped = XdrJsonHelper.escapedString(text, type: 'T');
      expect(escaped, r'a\tb\nc\rd\\e\0f');
      expect(XdrJsonHelper.readEscapedString(escaped, type: 'T'), text);
    });

    test('rejects bytes that are not valid UTF-8', () {
      expect(
        () => XdrJsonHelper.readEscapedString(r'\xff', type: 'T'),
        formatFailure('not valid UTF-8'),
      );
      expect(
        () => XdrJsonHelper.readEscapedString(r'\xc3', type: 'T', key: 'memo'),
        formatFailure('key "memo" resolves to bytes that are not valid UTF-8'),
      );
    });

    test('validates the declared byte maximum, counting bytes not runes', () {
      expect(
        XdrJsonHelper.escapedString('café', type: 'T', maxBytes: 5),
        r'caf\xc3\xa9',
      );
      expect(
        () => XdrJsonHelper.escapedString('café', type: 'T', maxBytes: 4),
        formatFailure('is 5 bytes, longer than the declared maximum of 4'),
      );
      expect(
        () => XdrJsonHelper.readEscapedString(
          r'caf\xc3\xa9',
          type: 'T',
          maxBytes: 4,
        ),
        formatFailure('more than the declared maximum of 4'),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Wide integers
  // ---------------------------------------------------------------------------
  group('XdrJsonHelper wide integers', () {
    final BigInt twoPow64 = BigInt.two.pow(64);

    test('reassembles an unsigned 128-bit value', () {
      expect(
        XdrJsonHelper.partsToDecimalString(
          <BigInt>[BigInt.one, BigInt.zero],
          signed: false,
          type: 'T',
        ),
        twoPow64.toString(),
      );
      expect(
        XdrJsonHelper.partsToDecimalString(
          <BigInt>[BigInt.zero, BigInt.from(5)],
          signed: false,
          type: 'T',
        ),
        '5',
      );
    });

    test('reassembles a signed 128-bit value', () {
      expect(
        XdrJsonHelper.partsToDecimalString(
          <BigInt>[-BigInt.one, twoPow64 - BigInt.one],
          signed: true,
          type: 'T',
        ),
        '-1',
      );
      expect(
        XdrJsonHelper.partsToDecimalString(
          <BigInt>[-BigInt.one, BigInt.zero],
          signed: true,
          type: 'T',
        ),
        (-twoPow64).toString(),
      );
    });

    test('round-trips the 128-bit extremes', () {
      final BigInt min = -BigInt.two.pow(127);
      final BigInt max = BigInt.two.pow(127) - BigInt.one;
      final BigInt uMax = BigInt.two.pow(128) - BigInt.one;

      for (final BigInt value in <BigInt>[
        min,
        max,
        BigInt.zero,
        -BigInt.one,
        BigInt.one,
      ]) {
        final List<BigInt> limbs = XdrJsonHelper.decimalStringToParts(
          value.toString(),
          limbCount: 2,
          signed: true,
          type: 'T',
        );
        expect(limbs.length, 2);
        expect(
          XdrJsonHelper.partsToDecimalString(limbs, signed: true, type: 'T'),
          value.toString(),
        );
      }

      final List<BigInt> uLimbs = XdrJsonHelper.decimalStringToParts(
        uMax.toString(),
        limbCount: 2,
        signed: false,
        type: 'T',
      );
      expect(
        XdrJsonHelper.partsToDecimalString(uLimbs, signed: false, type: 'T'),
        uMax.toString(),
      );
    });

    test('round-trips the 256-bit extremes', () {
      final BigInt min = -BigInt.two.pow(255);
      final BigInt max = BigInt.two.pow(255) - BigInt.one;
      final BigInt uMax = BigInt.two.pow(256) - BigInt.one;

      for (final BigInt value in <BigInt>[min, max, BigInt.zero, -BigInt.one]) {
        final List<BigInt> limbs = XdrJsonHelper.decimalStringToParts(
          value.toString(),
          limbCount: 4,
          signed: true,
          type: 'T',
        );
        expect(limbs.length, 4);
        expect(
          XdrJsonHelper.partsToDecimalString(limbs, signed: true, type: 'T'),
          value.toString(),
        );
      }

      final List<BigInt> uLimbs = XdrJsonHelper.decimalStringToParts(
        uMax.toString(),
        limbCount: 4,
        signed: false,
        type: 'T',
      );
      expect(
        XdrJsonHelper.partsToDecimalString(uLimbs, signed: false, type: 'T'),
        uMax.toString(),
      );
    });

    test('returns the most significant limb signed and the rest unsigned', () {
      final List<BigInt> limbs = XdrJsonHelper.decimalStringToParts(
        '-1',
        limbCount: 2,
        signed: true,
        type: 'T',
      );
      expect(limbs[0], -BigInt.one);
      expect(limbs[1], twoPow64 - BigInt.one);

      final List<BigInt> unsigned = XdrJsonHelper.decimalStringToParts(
        (BigInt.two.pow(128) - BigInt.one).toString(),
        limbCount: 2,
        signed: false,
        type: 'T',
      );
      expect(unsigned[0], twoPow64 - BigInt.one);
      expect(unsigned[1], twoPow64 - BigInt.one);
    });

    test('rejects an empty limb list', () {
      expect(
        () => XdrJsonHelper.partsToDecimalString(
          <BigInt>[],
          signed: false,
          type: 'T',
        ),
        formatFailure('no limbs to reassemble'),
      );
    });

    test('rejects a limb outside its declared width', () {
      expect(
        () => XdrJsonHelper.partsToDecimalString(
          <BigInt>[twoPow64],
          signed: false,
          type: 'T',
        ),
        formatFailure('limb outside the range of a uint64'),
      );
      expect(
        () => XdrJsonHelper.partsToDecimalString(
          <BigInt>[BigInt.two.pow(63), BigInt.zero],
          signed: true,
          type: 'T',
        ),
        formatFailure('most significant limb outside the range of an int64'),
      );
      expect(
        () => XdrJsonHelper.partsToDecimalString(
          <BigInt>[BigInt.zero, -BigInt.one],
          signed: true,
          type: 'T',
        ),
        formatFailure('limb outside the range of a uint64'),
      );
    });

    test('rejects a value outside the declared width', () {
      expect(
        () => XdrJsonHelper.decimalStringToParts(
          BigInt.two.pow(127).toString(),
          limbCount: 2,
          signed: true,
          type: 'T',
        ),
        formatFailure('outside the range of a signed 128-bit integer'),
      );
      expect(
        () => XdrJsonHelper.decimalStringToParts(
          '-1',
          limbCount: 2,
          signed: false,
          type: 'T',
        ),
        formatFailure('outside the range of an unsigned 128-bit integer'),
      );
    });

    test('rejects a rendering that is not a canonical decimal string', () {
      expect(
        () => XdrJsonHelper.decimalStringToParts(
          '007',
          limbCount: 2,
          signed: false,
          type: 'T',
        ),
        formatFailure('expects a base-10 decimal string'),
      );
      expect(
        () => XdrJsonHelper.decimalStringToParts(
          5,
          limbCount: 2,
          signed: false,
          type: 'T',
          key: 'lo',
        ),
        formatFailure('key "lo" expects a base-10 decimal string'),
      );
    });
  });

  group('XdrJsonHelper.readStrKey', () {
    // The strkeys below are what the reference implementation renders for the
    // byte patterns named beside them, so the codec is anchored to the wire
    // form rather than only to its own inverse.
    const String contractIdOfOnes =
        'CAAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQC526';
    const String poolIdOfThrees =
        'LABQGAYDAMBQGAYDAMBQGAYDAMBQGAYDAMBQGAYDAMBQGAYDAMBQG3AW';

    test('resolves a contract strkey to its bytes', () {
      expect(
        XdrJsonHelper.readStrKey(
          contractIdOfOnes,
          type: 'T',
          decode: StrKey.decodeContractId,
        ),
        Uint8List.fromList(List<int>.filled(32, 1)),
      );
    });

    test('resolves a liquidity pool strkey to its bytes', () {
      expect(
        XdrJsonHelper.readStrKey(
          poolIdOfThrees,
          type: 'T',
          decode: StrKey.decodeLiquidityPoolId,
        ),
        Uint8List.fromList(List<int>.filled(32, 3)),
      );
    });

    test('rejects a strkey of another kind', () {
      // Both are 32-byte payloads and differ only in the version byte, so the
      // decoder chosen by the field is what keeps them apart.
      expect(
        () => XdrJsonHelper.readStrKey(
          poolIdOfThrees,
          type: 'XdrConfigUpgradeSetKey',
          key: 'contract_id',
          decode: StrKey.decodeContractId,
        ),
        formatFailure('Version byte is invalid'),
      );
    });

    test('rejects a corrupted checksum', () {
      final String corrupted =
          '${contractIdOfOnes.substring(0, contractIdOfOnes.length - 1)}A';
      expect(
        () => XdrJsonHelper.readStrKey(
          corrupted,
          type: 'T',
          decode: StrKey.decodeContractId,
        ),
        formatFailure('holds a malformed strkey'),
      );
    });

    test('rejects a string too short to carry a version byte', () {
      // The codec measures the string before decoding it, so short input is
      // refused by its own validation and arrives here as a FormatException.
      expect(
        () => XdrJsonHelper.readStrKey(
          '',
          type: 'T',
          key: 'contract_id',
          decode: StrKey.decodeContractId,
        ),
        formatFailure(
          'key "contract_id" holds a malformed strkey: "" '
          '(Encoded string must be 56 characters, got 0)',
        ),
      );
    });

    test('rejects a value that is not a string', () {
      expect(
        () => XdrJsonHelper.readStrKey(
          42,
          type: 'T',
          key: 'contract_id',
          decode: StrKey.decodeContractId,
        ),
        formatFailure('key "contract_id" expects a strkey but found 42'),
      );
    });

    test('names the type it was reading', () {
      expect(
        () => XdrJsonHelper.readStrKey(
          'not a strkey',
          type: 'XdrContractEvent',
          decode: StrKey.decodeContractId,
        ),
        formatFailure('XDR-JSON XdrContractEvent'),
      );
    });
  });

  group('XdrJsonHelper asset codes', () {
    Uint8List padded(List<int> code, int length) {
      final Uint8List bytes = Uint8List(length);
      bytes.setRange(0, code.length, code);
      return bytes;
    }

    // The renderings below are the reference implementation's for the same
    // byte patterns.
    test('renders a four-byte code without its NUL padding', () {
      expect(
        XdrJsonHelper.assetCode4(padded('USD'.codeUnits, 4), type: 'T'),
        'USD',
      );
      expect(
        XdrJsonHelper.assetCode4(padded('ABCD'.codeUnits, 4), type: 'T'),
        'ABCD',
      );
    });

    test('renders an all-NUL four-byte code as the empty string', () {
      expect(XdrJsonHelper.assetCode4(Uint8List(4), type: 'T'), '');
    });

    test('pads a twelve-byte code back to five bytes', () {
      expect(
        XdrJsonHelper.assetCode12(padded('US'.codeUnits, 12), type: 'T'),
        r'US\0\0\0',
      );
    });

    test('renders an all-NUL twelve-byte code as five escaped NULs', () {
      expect(
        XdrJsonHelper.assetCode12(Uint8List(12), type: 'T'),
        r'\0\0\0\0\0',
      );
    });

    test('leaves a code of five or more bytes untrimmed', () {
      expect(
        XdrJsonHelper.assetCode12(padded('BTCOIN'.codeUnits, 12), type: 'T'),
        'BTCOIN',
      );
      expect(
        XdrJsonHelper.assetCode12(
          padded('ABCDEFGHIJKL'.codeUnits, 12),
          type: 'T',
        ),
        'ABCDEFGHIJKL',
      );
    });

    test('never pads beyond the bytes it was given', () {
      expect(XdrJsonHelper.assetCode12(Uint8List(3), type: 'T'), r'\0\0\0');
    });

    test('escapes a byte outside printable ASCII', () {
      expect(
        XdrJsonHelper.assetCode4(padded(<int>[0xC3, 0xC4], 4), type: 'T'),
        r'\xc3\xc4',
      );
    });

    test('restores the padding of a four-byte code', () {
      expect(
        XdrJsonHelper.readAssetCode4('USD', type: 'T'),
        padded('USD'.codeUnits, 4),
      );
      expect(XdrJsonHelper.readAssetCode4('', type: 'T'), Uint8List(4));
    });

    test('restores the padding of a twelve-byte code', () {
      expect(
        XdrJsonHelper.readAssetCode12(r'US\0\0\0', type: 'T'),
        padded('US'.codeUnits, 12),
      );
      expect(
        XdrJsonHelper.readAssetCode12(r'\0\0\0\0\0', type: 'T'),
        Uint8List(12),
      );
    });

    test('round-trips every four-byte code through its rendering', () {
      for (final Uint8List code in <Uint8List>[
        padded('USD'.codeUnits, 4),
        padded('A'.codeUnits, 4),
        padded('ABCD'.codeUnits, 4),
        Uint8List(4),
        padded(<int>[0x00, 0x41], 4),
      ]) {
        expect(
          XdrJsonHelper.readAssetCode4(
            XdrJsonHelper.assetCode4(code, type: 'T'),
            type: 'T',
          ),
          code,
        );
      }
    });

    test('round-trips every twelve-byte code through its rendering', () {
      for (final Uint8List code in <Uint8List>[
        padded('US'.codeUnits, 12),
        padded('BTCOIN'.codeUnits, 12),
        padded('ABCDEFGHIJKL'.codeUnits, 12),
        Uint8List(12),
        padded(<int>[0x41, 0x00, 0x42], 12),
      ]) {
        expect(
          XdrJsonHelper.readAssetCode12(
            XdrJsonHelper.assetCode12(code, type: 'T'),
            type: 'T',
          ),
          code,
        );
      }
    });

    test('rejects a four-byte code carrying more than four bytes', () {
      expect(
        () => XdrJsonHelper.readAssetCode4(
          'USDCX',
          type: 'XdrAssetAlphaNum4',
          key: 'asset_code',
        ),
        formatFailure(
          'key "asset_code" holds 5 bytes, more than the declared maximum of 4',
        ),
      );
    });

    test('rejects a twelve-byte code carrying more than twelve bytes', () {
      expect(
        () => XdrJsonHelper.readAssetCode12(
          'ABCDEFGHIJKLM',
          type: 'XdrAssetAlphaNum12',
          key: 'asset_code',
        ),
        formatFailure(
          'key "asset_code" holds 13 bytes, more than the declared maximum of 12',
        ),
      );
    });

    test('rejects a code that is not a string', () {
      expect(
        () => XdrJsonHelper.readAssetCode4(<int>[1], type: 'T'),
        formatFailure('expects a string but found'),
      );
      expect(
        () => XdrJsonHelper.readAssetCode12(null, type: 'T'),
        formatFailure('expects a string but found null'),
      );
    });
  });

  group('XdrJsonHelper strkey widths', () {
    // Both strings below are of the right kind and carry a valid checksum,
    // and differ only in the number of bytes they encode.
    const String publicKey32 =
        'GAAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQDZ7H';
    const String publicKey31 =
        'GAAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAZOBQ';

    test('accepts a strkey of the declared width', () {
      expect(
        XdrJsonHelper.readStrKey(
          publicKey32,
          type: 'T',
          decode: StrKey.decodeStellarAccountId,
          expectedLength: 32,
        ),
        Uint8List.fromList(List<int>.filled(32, 1)),
      );
    });

    test('rejects a decoded value the declared width cannot hold', () {
      expect(
        () => XdrJsonHelper.readStrKey(
          publicKey32,
          type: 'XdrPublicKey',
          key: 'ed25519',
          decode: (String _) => Uint8List(31),
          expectedLength: 32,
        ),
        formatFailure(
          'key "ed25519" holds 31 bytes but the declared length is 32',
        ),
      );
    });

    test('leaves the decoded width alone when the field declares none', () {
      expect(
        XdrJsonHelper.readStrKey(
          publicKey32,
          type: 'T',
          decode: (String _) => Uint8List(31),
        ),
        Uint8List(31),
      );
    });

    test('reports a strkey the codec refuses', () {
      // The report carries the codec's own wording, so the detail naming the
      // length it expected and the length it was given survives the wrapping.
      void read() => XdrJsonHelper.readStrKey(
        publicKey31,
        type: 'XdrPublicKey',
        key: 'ed25519',
        decode: StrKey.decodeStellarAccountId,
        expectedLength: 32,
      );

      expect(publicKey31.length, 55);
      expect(read, formatFailure('key "ed25519" holds a malformed strkey'));
      expect(
        read,
        formatFailure('(Encoded string must be 56 characters, got 55)'),
      );
    });

    test('reports a strkey the codec refuses with no declared width', () {
      expect(
        () => XdrJsonHelper.readStrKey(
          publicKey31,
          type: 'T',
          decode: StrKey.decodeStellarAccountId,
        ),
        formatFailure('holds a malformed strkey'),
      );
    });
  });

  group('XdrJsonHelper.readStrKeyPrefix', () {
    test('returns the leading character', () {
      expect(XdrJsonHelper.readStrKeyPrefix('GABC', type: 'T'), 'G');
      expect(XdrJsonHelper.readStrKeyPrefix('LXYZ', type: 'T'), 'L');
    });

    test('rejects a value that is not a string', () {
      expect(
        () => XdrJsonHelper.readStrKeyPrefix(7, type: 'T', key: 'address'),
        formatFailure('key "address" expects a strkey but found 7'),
      );
    });

    test('rejects an empty string', () {
      expect(
        () => XdrJsonHelper.readStrKeyPrefix('', type: 'T'),
        formatFailure('expects a strkey but found ""'),
      );
    });
  });

  group('XdrJsonHelper signed payload region', () {
    Uint8List region(int declaredLength, List<int> payload, {int? padTo}) {
      final List<int> bytes = <int>[
        ...List<int>.filled(32, 1),
        (declaredLength >> 24) & 0xFF,
        (declaredLength >> 16) & 0xFF,
        (declaredLength >> 8) & 0xFF,
        declaredLength & 0xFF,
        ...payload,
      ];
      final int target = padTo ?? payload.length + (-payload.length) % 4;
      bytes.addAll(List<int>.filled(target - payload.length, 0));
      return Uint8List.fromList(bytes);
    }

    test('splits the signer key from the payload', () {
      final (
        Uint8List key,
        Uint8List payload,
      ) = XdrJsonHelper.readSignedPayloadRegion(
        region(3, <int>[0xAA, 0xBB, 0xCC]),
        type: 'T',
      );
      expect(key, Uint8List.fromList(List<int>.filled(32, 1)));
      expect(payload, Uint8List.fromList(<int>[0xAA, 0xBB, 0xCC]));
    });

    test('reads a payload that needs no padding', () {
      final (
        Uint8List _,
        Uint8List payload,
      ) = XdrJsonHelper.readSignedPayloadRegion(
        region(4, <int>[1, 2, 3, 4]),
        type: 'T',
      );
      expect(payload, Uint8List.fromList(<int>[1, 2, 3, 4]));
    });

    test('reads the largest payload the declaration allows', () {
      final List<int> full = List<int>.generate(64, (int i) => i);
      final (Uint8List _, Uint8List payload) =
          XdrJsonHelper.readSignedPayloadRegion(region(64, full), type: 'T');
      expect(payload, Uint8List.fromList(full));
    });

    test('rejects a region too short to hold a key and a length', () {
      expect(
        () => XdrJsonHelper.readSignedPayloadRegion(
          Uint8List(35),
          type: 'T',
          key: 'ed25519_signed_payload',
        ),
        formatFailure('is 35 bytes, too short to hold a signer key'),
      );
    });

    test('rejects an empty payload, which has no strkey rendering', () {
      expect(
        () => XdrJsonHelper.readSignedPayloadRegion(
          region(0, <int>[]),
          type: 'XdrSignedPayload',
        ),
        formatFailure(
          'carries an empty payload, which has no strkey rendering',
        ),
      );
    });

    test('rejects a payload longer than the declaration allows', () {
      expect(
        () => XdrJsonHelper.readSignedPayloadRegion(
          region(65, List<int>.filled(65, 7)),
          type: 'T',
        ),
        formatFailure(
          'carries a 65-byte payload, more than the declared maximum of 64',
        ),
      );
    });

    test('rejects a region whose width disagrees with its length prefix', () {
      expect(
        () => XdrJsonHelper.readSignedPayloadRegion(
          region(3, <int>[0xAA, 0xBB, 0xCC], padTo: 8),
          type: 'T',
        ),
        formatFailure('but a 3-byte payload occupies 40'),
      );
    });

    test('rejects padding that is not NUL', () {
      final Uint8List bytes = region(3, <int>[0xAA, 0xBB, 0xCC]);
      bytes[bytes.length - 1] = 0x01;
      expect(
        () => XdrJsonHelper.readSignedPayloadRegion(bytes, type: 'T'),
        formatFailure('pads its payload with a byte that is not NUL'),
      );
    });

    test('states the payload bound once for both directions', () {
      expect(
        () => XdrJsonHelper.checkSignedPayloadLength(0, type: 'T'),
        formatFailure('carries an empty payload'),
      );
      expect(
        () => XdrJsonHelper.checkSignedPayloadLength(65, type: 'T', key: 'p'),
        formatFailure('key "p" carries a 65-byte payload'),
      );
      expect(
        () => XdrJsonHelper.checkSignedPayloadLength(1, type: 'T'),
        returnsNormally,
      );
      expect(
        () => XdrJsonHelper.checkSignedPayloadLength(64, type: 'T'),
        returnsNormally,
      );
    });
  });
}
