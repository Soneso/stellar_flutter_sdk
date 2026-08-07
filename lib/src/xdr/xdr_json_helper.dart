// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import '../util.dart' show Util;

/// Shared runtime for SEP-0051 (XDR-JSON) encoding and decoding.
///
/// Every rule the specification states once lives here once: the string escape
/// ladder, hexadecimal rendering, integer widths, container limits, the nesting
/// guard and error construction. Generated per-type code delegates one
/// expression per field to these members and holds no validation of its own.
///
/// Encoding members take a Dart value and return a node of the JSON tree.
/// Decoding members are prefixed `read` and take a node of the JSON tree,
/// returning the Dart value. The tree is the shape `dart:convert` produces:
/// `Map<String, dynamic>`, `List<dynamic>`, `String`, `num`, `bool` and `null`.
///
/// ## Input strictness
///
/// The specification fixes one canonical rendering per value, and this decoder
/// accepts only that rendering. Hexadecimal must be lowercase and of even
/// length; a `\x` escape must carry exactly two lowercase hexadecimal digits;
/// an escape the ladder does not define is rejected rather than passed through;
/// a decimal integer must carry no leading `+`, no leading zero, no exponent
/// and no fraction; and a duplicate object key is rejected rather than
/// resolved. The intent is that a value has one encoding, so a byte-for-byte
/// comparison of two documents is meaningful.
///
/// An object decoded into a struct must also carry no key the type does not
/// declare. A document with an extra key is describing some other type, and
/// accepting it would let a field the protocol later renames decode as though
/// it were simply absent.
///
/// The one key accepted everywhere and declared nowhere is `$schema`, which
/// SEP-0051 §JSON Schema requires be allowed but not required. It is stripped
/// on input and never emitted. That is the only place this decoder accepts what
/// the reference implementation rejects.
///
/// ## 64-bit integers
///
/// A 64-bit value is carried as a `BigInt` and rendered as a base-10 string, as
/// the specification requires for the Hyper types. It never passes through
/// `int`, `num` or the numeric path of `jsonEncode`, because the JavaScript
/// number type cannot hold the full range and rounds silently. For
/// compatibility with XDR-JSON v1, which rendered these as JSON numbers, a
/// number is also accepted on input, but only below 2^53, where a JSON number
/// is exact. Past that the decoder has already rounded, and the rounded value
/// is itself a whole number, so no inspection of the value can recover what the
/// document meant. Such input is rejected rather than silently returned wrong.
class XdrJsonHelper {
  /// Maximum number of nested JSON containers accepted in either direction.
  ///
  /// Matches `XdrDataInputStream.maxRecursiveDecodeDepth`, so the JSON and
  /// binary decoders bound recursion at the same number.
  static const int maxDepth = 128;

  /// The optional schema property. It is accepted on input, stripped, and
  /// never emitted.
  static const String schemaKey = r'$schema';

  static const int _int32Min = -2147483648;
  static const int _int32Max = 2147483647;
  static const int _uint32Max = 4294967295;

  static final BigInt _twoPow64 = BigInt.two.pow(64);
  static final BigInt _uint64Mask = _twoPow64 - BigInt.one;

  /// Smallest value an `int64` can carry.
  static final BigInt int64Min = -BigInt.two.pow(63);

  /// Largest value an `int64` can carry.
  static final BigInt int64Max = BigInt.two.pow(63) - BigInt.one;

  /// Largest value a `uint64` can carry.
  static final BigInt uint64Max = _twoPow64 - BigInt.one;

  static const int _maxPreviewLength = 40;

  /// The largest magnitude a JSON number carries exactly, 2^53. Past it the
  /// decoder rounds, and the rounded value is indistinguishable from an exact
  /// one.
  static const int _maxExactJsonInteger = 9007199254740992;

  // ---------------------------------------------------------------------------
  // Document boundary
  // ---------------------------------------------------------------------------

  /// Serialises a JSON tree to the canonical compact form.
  ///
  /// The tree is validated before it reaches `jsonEncode`: an over-nested or
  /// unrepresentable tree is reported as a [FormatException] rather than
  /// reaching the encoder, whose failure mode is not catchable on every target.
  static String encodeDocument(Object? value, {required String type}) {
    guardValueDepth(value, type: type);
    return jsonEncode(value);
  }

  /// Parses a JSON document into a tree.
  ///
  /// The text is scanned before it reaches `jsonDecode`, both to bound nesting
  /// and to reject duplicate object keys, which `jsonDecode` resolves silently
  /// in favour of the last occurrence.
  static Object? decodeDocument(String json, {required String type}) {
    guardTextDepth(json, type: type);
    try {
      return jsonDecode(json);
    } on FormatException catch (error) {
      // The wording of a decoder error is not stable across compilation
      // targets, so only the fact of the failure is carried forward.
      fail(type, 'could not be parsed as JSON: ${error.message}');
    }
  }

  // ---------------------------------------------------------------------------
  // Nesting guards
  // ---------------------------------------------------------------------------

  /// Scans JSON text, rejecting nesting deeper than [maxDepth] and any object
  /// that repeats a key.
  ///
  /// Only containers are counted, so the limit matches [guardValueDepth]
  /// exactly. The scan is a single forward pass and never recurses; a guard
  /// that recursed could exhaust the stack on the input it exists to reject.
  ///
  /// Text that is not valid JSON is left to the parser to report: this scan
  /// establishes the two properties the parser does not, and nothing more.
  static void guardTextDepth(String json, {required String type}) {
    final int length = json.length;
    final List<Set<String>?> keysInScope = <Set<String>?>[];
    int index = 0;
    int depth = 0;

    while (index < length) {
      final int unit = json.codeUnitAt(index);

      if (unit == 0x7B || unit == 0x5B) {
        // '{' or '['
        depth++;
        if (depth > maxDepth) {
          fail(
            type,
            'nests JSON containers more than $maxDepth deep, which is the limit',
          );
        }
        keysInScope.add(unit == 0x7B ? <String>{} : null);
        index++;
      } else if (unit == 0x7D || unit == 0x5D) {
        // '}' or ']'
        depth--;
        if (keysInScope.isNotEmpty) {
          keysInScope.removeLast();
        }
        index++;
      } else if (unit == 0x22) {
        // '"'
        final int end = _scanJsonString(json, index);
        final Set<String>? keys = keysInScope.isEmpty ? null : keysInScope.last;
        if (keys != null && _followedByColon(json, end)) {
          final String key = _unescapeJsonString(json, index, end);
          if (!keys.add(key)) {
            fail(type, 'repeats the object key ${preview(key)}');
          }
        }
        index = end;
      } else {
        index++;
      }
    }
  }

  /// Walks a JSON tree, rejecting nesting deeper than [maxDepth] and any leaf
  /// `jsonEncode` cannot represent.
  ///
  /// The walk is iterative for the same reason [guardTextDepth] is: a recursive
  /// walk would fail on deep input by exhausting the stack, which on some
  /// targets ends the process rather than raising. The depth cap also bounds a
  /// tree that refers to itself.
  static void guardValueDepth(Object? value, {required String type}) {
    final List<Object?> pending = <Object?>[value];
    final List<int> depths = <int>[0];

    while (pending.isNotEmpty) {
      final Object? current = pending.removeLast();
      final int depth = depths.removeLast();

      if (current is num) {
        // NaN and the infinities have no JSON form. `jsonEncode` reports them
        // by raising an Error rather than an Exception, which would escape the
        // FormatException contract, so they are stopped here.
        if (!current.isFinite) {
          fail(type, 'holds ${preview(current)}, which JSON cannot represent');
        }
        continue;
      }

      if (current == null || current is String || current is bool) {
        continue;
      }

      if (current is! Map && current is! List) {
        fail(
          type,
          'holds ${preview(current)}, which has no JSON representation',
        );
      }

      final int nested = depth + 1;
      if (nested > maxDepth) {
        fail(
          type,
          'nests JSON containers more than $maxDepth deep, which is the limit',
        );
      }

      if (current is Map) {
        current.forEach((Object? key, Object? entry) {
          if (key is! String) {
            fail(type, 'has the non-string object key ${preview(key)}');
          }
          pending.add(entry);
          depths.add(nested);
        });
      } else if (current is List) {
        for (final Object? entry in current) {
          pending.add(entry);
          depths.add(nested);
        }
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Errors
  // ---------------------------------------------------------------------------

  /// Reports malformed XDR-JSON for [type] as a [FormatException].
  ///
  /// Every rejection in this file and in generated code arrives here, so a
  /// caller of `fromXdrJson` has one exception type to handle whatever the
  /// cause. Errors raised by strkey decoding and by UTF-8 decoding are caught
  /// at their boundary and reported through this method too.
  static Never fail(String type, String detail) {
    throw FormatException('XDR-JSON $type $detail');
  }

  /// Renders an untrusted value for an error message.
  ///
  /// The result is truncated and holds no unescaped control bytes, so a hostile
  /// document cannot inject line breaks or terminal escapes into a log through
  /// an exception message.
  static String preview(Object? value) {
    if (value == null) {
      return 'null';
    }
    if (value is bool || value is num) {
      return _escapeAndTruncate(value.toString());
    }
    if (value is String) {
      return '"${_escapeAndTruncate(value)}"';
    }
    if (value is List) {
      return 'an array of ${value.length} element(s)';
    }
    if (value is Map) {
      return 'an object with ${value.length} key(s)';
    }
    return _escapeAndTruncate(value.toString());
  }

  // ---------------------------------------------------------------------------
  // Encoding
  // ---------------------------------------------------------------------------

  /// Renders a signed 32-bit integer as a JSON number.
  static int int32(int value, {required String type, String? key}) {
    if (value < _int32Min || value > _int32Max) {
      fail(type, '${_at(key)}holds $value, outside the range of an int32');
    }
    return value;
  }

  /// Renders an unsigned 32-bit integer as a JSON number.
  static int uint32(int value, {required String type, String? key}) {
    if (value < 0 || value > _uint32Max) {
      fail(type, '${_at(key)}holds $value, outside the range of a uint32');
    }
    return value;
  }

  /// Renders a signed 64-bit integer as a base-10 JSON string.
  static String int64(BigInt value, {required String type, String? key}) {
    if (value < int64Min || value > int64Max) {
      fail(type, '${_at(key)}holds $value, outside the range of an int64');
    }
    return value.toString();
  }

  /// Renders an unsigned 64-bit integer as a base-10 JSON string.
  static String uint64(BigInt value, {required String type, String? key}) {
    if (value < BigInt.zero || value > uint64Max) {
      fail(type, '${_at(key)}holds $value, outside the range of a uint64');
    }
    return value.toString();
  }

  /// Renders a boolean as a JSON boolean.
  static bool boolean(bool value) => value;

  /// Renders bytes as a lowercase hexadecimal string.
  ///
  /// Empty input renders as an empty string, which is the rendering of an
  /// empty variable-length opaque field. [maxLength] bounds a variable-length
  /// field whose declaration carries a maximum.
  static String hex(
    Uint8List bytes, {
    required String type,
    String? key,
    int? maxLength,
  }) {
    _checkByteLength(bytes.length, type: type, key: key, maxLength: maxLength);
    return Util.bytesToHex(bytes);
  }

  /// Renders a Dart string as escaped ASCII.
  ///
  /// The string is encoded to UTF-8 and the escape ladder of SEP-0051 §String
  /// is applied byte by byte, so the result is lossless for any string the XDR
  /// decoder could have produced.
  static String escapedString(
    String value, {
    required String type,
    String? key,
    int? maxBytes,
  }) {
    final List<int> bytes = utf8.encode(value);
    if (maxBytes != null && bytes.length > maxBytes) {
      fail(
        type,
        '${_at(key)}is ${bytes.length} bytes, longer than the declared maximum of $maxBytes',
      );
    }
    return escapedBytes(bytes, type: type, key: key);
  }

  /// Applies the escape ladder of SEP-0051 §String to raw bytes.
  ///
  /// Used for the opaque-backed types, whose bytes are not text and are never
  /// interpreted as UTF-8.
  static String escapedBytes(
    List<int> bytes, {
    required String type,
    String? key,
  }) {
    final StringBuffer buffer = StringBuffer();
    for (final int byte in bytes) {
      if (byte < 0 || byte > 0xFF) {
        fail(type, '${_at(key)}holds $byte, which is not a byte');
      }
      switch (byte) {
        case 0x00:
          buffer.write(r'\0');
          break;
        case 0x09:
          buffer.write(r'\t');
          break;
        case 0x0A:
          buffer.write(r'\n');
          break;
        case 0x0D:
          buffer.write(r'\r');
          break;
        case 0x5C:
          buffer.write(r'\\');
          break;
        default:
          if (byte >= 0x20 && byte <= 0x7E) {
            buffer.writeCharCode(byte);
          } else {
            buffer.write(r'\x');
            buffer.write(byte.toRadixString(16).padLeft(2, '0'));
          }
      }
    }
    return buffer.toString();
  }

  /// Renders a sequence as a JSON array.
  ///
  /// An empty sequence renders as `[]`; an array is never omitted.
  static List<Object?> array<T>(
    Iterable<T> values,
    Object? Function(T) encode, {
    required String type,
    String? key,
    int? maxLength,
  }) {
    // A sequence whose length is already known is checked before its elements
    // are encoded, so an over-long field costs nothing to reject. A lazy
    // iterable has no length until it is walked, hence the second check.
    if (values is List<T>) {
      _checkElementCount(
        values.length,
        type: type,
        key: key,
        maxLength: maxLength,
      );
    }

    final List<Object?> result = <Object?>[];
    for (final T value in values) {
      result.add(encode(value));
    }
    _checkElementCount(
      result.length,
      type: type,
      key: key,
      maxLength: maxLength,
    );
    return result;
  }

  // ---------------------------------------------------------------------------
  // Decoding
  // ---------------------------------------------------------------------------

  /// Requires a JSON object, strips the optional schema property, and returns
  /// it with string keys.
  ///
  /// [allowedKeys] holds every key spelling the type declares. When it is
  /// supplied, a key outside it is rejected: SEP-0051 gives a type one set of
  /// field names, and a document carrying anything else is describing a
  /// different type. Accepting it silently would let a field renamed by a
  /// future protocol version decode as though it were absent.
  ///
  /// The schema property is the single exception, and it is removed here rather
  /// than tested for, so every caller gets the carve-out without restating it.
  ///
  /// A field that accepts a second input spelling contributes both spellings to
  /// [allowedKeys]; [readField] is what then holds it to one of them, so the
  /// pair behaves as the one declared key it is.
  static Map<String, dynamic> readObject(
    Object? value, {
    required String type,
    Set<String>? allowedKeys,
  }) {
    Map<String, dynamic> result;

    if (value is Map<String, dynamic>) {
      result = value;
    } else if (value is Map) {
      result = <String, dynamic>{};
      value.forEach((Object? key, Object? entry) {
        if (key is! String) {
          fail(type, 'has the non-string object key ${preview(key)}');
        }
        result[key] = entry;
      });
    } else {
      fail(type, 'expects a JSON object but found ${preview(value)}');
    }

    result = stripSchema(result);
    if (allowedKeys == null) {
      return result;
    }

    // Sorted, so the message does not depend on the decoded key order, which
    // differs between compilation targets.
    final List<String> unknown =
        result.keys.where((String key) => !allowedKeys.contains(key)).toList()
          ..sort();
    if (unknown.isEmpty) {
      return result;
    }

    final String rendered = unknown.map(preview).join(', ');
    fail(
      type,
      unknown.length == 1
          ? 'has the unknown key $rendered'
          : 'has the unknown keys $rendered',
    );
  }

  /// Removes the optional schema property.
  ///
  /// The property is accepted anywhere an object is accepted and carries no
  /// meaning to this decoder. The argument is left unmodified.
  static Map<String, dynamic> stripSchema(Map<String, dynamic> object) {
    if (!object.containsKey(schemaKey)) {
      return object;
    }
    final Map<String, dynamic> result = Map<String, dynamic>.of(object);
    result.remove(schemaKey);
    return result;
  }

  /// Reads a required key.
  ///
  /// An optional field may hold `null`, but its key must still be present, so
  /// a missing key and a null value are distinct failures.
  ///
  /// [alias] names a second accepted spelling. Supplying both spellings is
  /// rejected rather than resolved, because the two would be indistinguishable
  /// from a repeated key.
  static Object? readField(
    Map<String, dynamic> object,
    String key, {
    required String type,
    String? alias,
  }) {
    final bool hasKey = object.containsKey(key);
    final bool hasAlias = alias != null && object.containsKey(alias);

    if (hasKey && hasAlias) {
      fail(
        type,
        'carries both "$key" and its accepted alias "$alias"; supply one',
      );
    }
    if (hasKey) {
      return object[key];
    }
    if (hasAlias) {
      return object[alias];
    }
    fail(type, 'is missing the required key "$key"');
  }

  /// Requires an object holding exactly one key and returns it.
  ///
  /// This is the rendering of a union arm that carries a value. The arm key is
  /// discovered rather than declared, so no key list applies; the single-key
  /// requirement is what rejects anything extra. [readObject] has already
  /// removed the schema property, which therefore does not count towards it.
  static MapEntry<String, Object?> readSingleKeyObject(
    Object? value, {
    required String type,
  }) {
    final Map<String, dynamic> object = readObject(value, type: type);
    if (object.length != 1) {
      fail(
        type,
        'expects an object with exactly one key but found ${preview(value)}',
      );
    }
    final String key = object.keys.first;
    return MapEntry<String, Object?>(key, object[key]);
  }

  /// Reads a signed 32-bit integer from a JSON number.
  static int readInt32(Object? value, {required String type, String? key}) =>
      _read32(
        value,
        type: type,
        key: key,
        min: _int32Min,
        max: _int32Max,
        what: 'int32',
      );

  /// Reads an unsigned 32-bit integer from a JSON number.
  static int readUint32(Object? value, {required String type, String? key}) =>
      _read32(
        value,
        type: type,
        key: key,
        min: 0,
        max: _uint32Max,
        what: 'uint32',
      );

  /// Reads a signed 64-bit integer from a base-10 string, or from a number for
  /// compatibility with XDR-JSON v1.
  static BigInt readInt64(Object? value, {required String type, String? key}) =>
      _read64(
        value,
        type: type,
        key: key,
        min: int64Min,
        max: int64Max,
        what: 'int64',
      );

  /// Reads an unsigned 64-bit integer from a base-10 string, or from a number
  /// for compatibility with XDR-JSON v1.
  static BigInt readUint64(
    Object? value, {
    required String type,
    String? key,
  }) => _read64(
    value,
    type: type,
    key: key,
    min: BigInt.zero,
    max: uint64Max,
    what: 'uint64',
  );

  /// Reads a boolean.
  static bool readBoolean(Object? value, {required String type, String? key}) {
    if (value is bool) {
      return value;
    }
    fail(type, '${_at(key)}expects a boolean but found ${preview(value)}');
  }

  /// Reads bytes from a lowercase hexadecimal string.
  ///
  /// [expectedLength] pins the exact byte count of a fixed-length opaque field;
  /// [maxLength] bounds a variable-length one.
  static Uint8List readHex(
    Object? value, {
    required String type,
    String? key,
    int? expectedLength,
    int? maxLength,
  }) {
    if (value is! String) {
      fail(
        type,
        '${_at(key)}expects a hexadecimal string but found ${preview(value)}',
      );
    }
    if (value.length.isOdd) {
      fail(
        type,
        '${_at(key)}has an odd number of hexadecimal digits: ${preview(value)}',
      );
    }

    final int count = value.length ~/ 2;
    final Uint8List bytes = Uint8List(count);
    for (int i = 0; i < count; i++) {
      final int high = _hexDigit(value.codeUnitAt(2 * i));
      final int low = _hexDigit(value.codeUnitAt(2 * i + 1));
      if (high < 0 || low < 0) {
        fail(
          type,
          '${_at(key)}expects lowercase hexadecimal digits but found ${preview(value)}',
        );
      }
      bytes[i] = (high << 4) | low;
    }

    _checkByteLength(
      count,
      type: type,
      key: key,
      expectedLength: expectedLength,
      maxLength: maxLength,
    );
    return bytes;
  }

  /// Reads a Dart string from escaped ASCII.
  ///
  /// The escapes are resolved to bytes and the bytes decoded as UTF-8. Input
  /// whose bytes are not valid UTF-8 is rejected: the binary decoder cannot
  /// produce such a string either, so the two paths accept the same values.
  static String readEscapedString(
    Object? value, {
    required String type,
    String? key,
    int? maxBytes,
  }) {
    final Uint8List bytes = readEscapedBytes(
      value,
      type: type,
      key: key,
      maxLength: maxBytes,
    );
    try {
      return utf8.decode(bytes);
    } on FormatException {
      fail(
        type,
        '${_at(key)}resolves to bytes that are not valid UTF-8: ${preview(value)}',
      );
    }
  }

  /// Reads raw bytes from escaped ASCII.
  static Uint8List readEscapedBytes(
    Object? value, {
    required String type,
    String? key,
    int? expectedLength,
    int? maxLength,
  }) {
    if (value is! String) {
      fail(type, '${_at(key)}expects a string but found ${preview(value)}');
    }

    final List<int> bytes = <int>[];
    final int length = value.length;
    int index = 0;

    while (index < length) {
      final int unit = value.codeUnitAt(index);

      if (unit != 0x5C) {
        if (unit < 0x20 || unit > 0x7E) {
          fail(
            type,
            '${_at(key)}holds the unescaped character U+${unit.toRadixString(16).padLeft(4, '0').toUpperCase()}; '
            'every byte outside the printable ASCII range must use an escape',
          );
        }
        bytes.add(unit);
        index++;
        continue;
      }

      index++;
      if (index >= length) {
        fail(type, '${_at(key)}ends with an unfinished escape');
      }

      final int marker = value.codeUnitAt(index);
      switch (marker) {
        case 0x30: // '0'
          bytes.add(0x00);
          index++;
          break;
        case 0x74: // 't'
          bytes.add(0x09);
          index++;
          break;
        case 0x6E: // 'n'
          bytes.add(0x0A);
          index++;
          break;
        case 0x72: // 'r'
          bytes.add(0x0D);
          index++;
          break;
        case 0x5C: // '\'
          bytes.add(0x5C);
          index++;
          break;
        case 0x78: // 'x'
          if (index + 2 >= length) {
            fail(type, '${_at(key)}ends with a truncated \\x escape');
          }
          final int high = _hexDigit(value.codeUnitAt(index + 1));
          final int low = _hexDigit(value.codeUnitAt(index + 2));
          if (high < 0 || low < 0) {
            fail(
              type,
              '${_at(key)}has an escape that is not followed by two lowercase '
              'hexadecimal digits: ${preview(value)}',
            );
          }
          bytes.add((high << 4) | low);
          index += 3;
          break;
        default:
          fail(
            type,
            '${_at(key)}holds the unrecognised escape '
            '\\${_escapeForMessage(String.fromCharCode(marker))}',
          );
      }
    }

    _checkByteLength(
      bytes.length,
      type: type,
      key: key,
      expectedLength: expectedLength,
      maxLength: maxLength,
    );
    return Uint8List.fromList(bytes);
  }

  /// Reads a JSON array.
  ///
  /// [fixedLength] pins the exact element count of a fixed-length array;
  /// [maxLength] bounds a variable-length one.
  static List<dynamic> readArray(
    Object? value, {
    required String type,
    String? key,
    int? maxLength,
    int? fixedLength,
  }) {
    if (value is! List) {
      fail(type, '${_at(key)}expects an array but found ${preview(value)}');
    }
    if (fixedLength != null && value.length != fixedLength) {
      fail(
        type,
        '${_at(key)}holds ${value.length} elements but the declared length is $fixedLength',
      );
    }
    if (maxLength != null && value.length > maxLength) {
      fail(
        type,
        '${_at(key)}holds ${value.length} elements, more than the declared maximum of $maxLength',
      );
    }
    return value;
  }

  // ---------------------------------------------------------------------------
  // Stellar renderings
  // ---------------------------------------------------------------------------

  /// Byte count of the fixed opaque an `AssetCode4` carries.
  static const int _assetCode4Width = 4;

  /// Byte count of the fixed opaque an `AssetCode12` carries.
  static const int _assetCode12Width = 12;

  /// Shortest rendering an `AssetCode12` takes.
  ///
  /// The code of a twelve-byte asset is five to twelve characters, so trimming
  /// one below five would render it as something the four-byte form could also
  /// produce. Padding back to five keeps the two widths distinguishable.
  static const int _assetCode12MinRendered = 5;

  /// Resolves a strkey to the bytes it carries.
  ///
  /// [decode] is the codec for the strkey kind the field declares, so a value
  /// of another kind is refused by its version byte rather than silently
  /// accepted. The codec reports a bad checksum or a wrong version byte in its
  /// own vocabulary; those are reported here under the XDR-JSON contract
  /// instead, so a caller has one exception type to handle. The codec's own
  /// wording is carried through where it has any.
  ///
  /// [expectedLength] is the byte count the field's declaration fixes. The
  /// strkey codec checks the encoding, the version byte and the checksum, and
  /// nothing about the width, so a well-formed strkey carrying the wrong number
  /// of bytes decodes cleanly and would otherwise be written back out as
  /// malformed XDR.
  static Uint8List readStrKey(
    Object? value, {
    required String type,
    String? key,
    required Uint8List Function(String) decode,
    int? expectedLength,
  }) {
    if (value is! String) {
      fail(type, '${_at(key)}expects a strkey but found ${preview(value)}');
    }

    String? detail;
    Uint8List? decoded;
    try {
      decoded = decode(value);
    } on FormatException catch (error) {
      detail = error.message;
    } on ArgumentError {
      // A string too short to hold a version byte and a checksum fails in the
      // codec's own indexing rather than through its validation, so it arrives
      // as an ArgumentError carrying no wording worth repeating.
    }

    if (decoded == null) {
      fail(
        type,
        '${_at(key)}holds a malformed strkey: ${preview(value)}'
        '${detail == null ? '' : ' ($detail)'}',
      );
    }

    _checkByteLength(
      decoded.length,
      type: type,
      key: key,
      expectedLength: expectedLength,
    );
    return decoded;
  }

  /// The leading character of a strkey-valued JSON string.
  ///
  /// Where a type renders as one of several strkey kinds, the kind is carried
  /// by the value rather than by a key, so a reader has to look at the first
  /// character before it knows which codec applies.
  static String readStrKeyPrefix(
    Object? value, {
    required String type,
    String? key,
  }) {
    if (value is! String || value.isEmpty) {
      fail(type, '${_at(key)}expects a strkey but found ${preview(value)}');
    }
    return value[0];
  }

  /// Renders a four-byte asset code.
  ///
  /// The code is padded with trailing NUL bytes to fill the field; the padding
  /// is not part of the value, so it is dropped before the escape ladder runs.
  /// A field of four NUL bytes renders as the empty string.
  static String assetCode4(
    Uint8List bytes, {
    required String type,
    String? key,
  }) => escapedBytes(_trimTrailingNuls(bytes, 0), type: type, key: key);

  /// Renders a twelve-byte asset code.
  ///
  /// Trailing NUL bytes are dropped, then restored up to
  /// [_assetCode12MinRendered]. An all-NUL field therefore renders as five
  /// escaped NULs rather than as an empty string, and reads back as the twelve
  /// bytes it came from.
  static String assetCode12(
    Uint8List bytes, {
    required String type,
    String? key,
  }) => escapedBytes(
    _trimTrailingNuls(bytes, _assetCode12MinRendered),
    type: type,
    key: key,
  );

  /// Reads a four-byte asset code, restoring the trailing NUL padding.
  static Uint8List readAssetCode4(
    Object? value, {
    required String type,
    String? key,
  }) => _readAssetCode(value, type: type, key: key, width: _assetCode4Width);

  /// Reads a twelve-byte asset code, restoring the trailing NUL padding.
  static Uint8List readAssetCode12(
    Object? value, {
    required String type,
    String? key,
  }) => _readAssetCode(value, type: type, key: key, width: _assetCode12Width);

  static Uint8List _readAssetCode(
    Object? value, {
    required String type,
    required String? key,
    required int width,
  }) {
    final Uint8List bytes = readEscapedBytes(
      value,
      type: type,
      key: key,
      maxLength: width,
    );
    final Uint8List padded = Uint8List(width);
    padded.setAll(0, bytes);
    return padded;
  }

  /// Byte count of the signer key a signed-payload strkey carries.
  static const int _signedPayloadKeyWidth = 32;

  /// Byte count of the length prefix that follows the signer key.
  static const int _signedPayloadLengthWidth = 4;

  /// Largest payload a signed-payload signer can carry, from `opaque payload<64>`.
  static const int _signedPayloadMaxLength = 64;

  /// Refuses a signed-payload length that has no SEP-0051 rendering.
  ///
  /// The payload is bounded above by its own declaration. It is bounded below
  /// by the strkey form, which has no encoding for an empty payload: the region
  /// such a value produces is shorter than any strkey the ecosystem reads back,
  /// so a document carrying one could never be decoded again. Both directions
  /// call this, so the bound is stated once.
  static void checkSignedPayloadLength(
    int length, {
    required String type,
    String? key,
  }) {
    if (length < 1) {
      fail(
        type,
        '${_at(key)}carries an empty payload, which has no strkey rendering',
      );
    }
    if (length > _signedPayloadMaxLength) {
      fail(
        type,
        '${_at(key)}carries a $length-byte payload, more than the declared '
        'maximum of $_signedPayloadMaxLength',
      );
    }
  }

  /// Splits the payload region of a signed-payload strkey into the signer key
  /// and the payload it carries, in that order.
  ///
  /// The region is the XDR encoding of the two fields: a 32-byte key, a 4-byte
  /// big-endian length, and the payload padded with NUL bytes to a multiple of
  /// four. A region whose length prefix, padding or total width disagrees with
  /// that layout is refused rather than truncated to fit.
  ///
  /// The bytes are taken rather than the JSON value so that this holds no
  /// dependency on the strkey codec, which [readStrKey] takes as a parameter.
  static (Uint8List, Uint8List) readSignedPayloadRegion(
    Uint8List region, {
    required String type,
    String? key,
  }) {
    const int prefix = _signedPayloadKeyWidth + _signedPayloadLengthWidth;
    if (region.length < prefix) {
      fail(
        type,
        '${_at(key)}is ${region.length} bytes, too short to hold a signer key '
        'and a payload length',
      );
    }

    int length = 0;
    for (int i = 0; i < _signedPayloadLengthWidth; i++) {
      length = (length << 8) | region[_signedPayloadKeyWidth + i];
    }
    checkSignedPayloadLength(length, type: type, key: key);

    final int padded = length + (-length) % 4;
    if (region.length != prefix + padded) {
      fail(
        type,
        '${_at(key)}is ${region.length} bytes, but a $length-byte payload '
        'occupies ${prefix + padded}',
      );
    }
    for (int i = prefix + length; i < region.length; i++) {
      if (region[i] != 0) {
        fail(type, '${_at(key)}pads its payload with a byte that is not NUL');
      }
    }

    return (
      Uint8List.sublistView(region, 0, _signedPayloadKeyWidth),
      Uint8List.sublistView(region, prefix, prefix + length),
    );
  }

  /// The bytes of [bytes] up to its last non-NUL, never fewer than [floor] and
  /// never more than it was given.
  static Uint8List _trimTrailingNuls(Uint8List bytes, int floor) {
    int end = bytes.length;
    while (end > 0 && bytes[end - 1] == 0) {
      end--;
    }
    final int least = floor < bytes.length ? floor : bytes.length;
    return Uint8List.sublistView(bytes, 0, end < least ? least : end);
  }

  // ---------------------------------------------------------------------------
  // Wide integers
  // ---------------------------------------------------------------------------

  /// Reassembles a 128-bit or 256-bit value from its 64-bit limbs and renders
  /// it as one base-10 decimal string.
  ///
  /// [limbs] runs most significant first. When [signed] is set the most
  /// significant limb carries the sign and the rest are unsigned, which is how
  /// the signed parts types are declared.
  static String partsToDecimalString(
    List<BigInt> limbs, {
    required bool signed,
    required String type,
  }) {
    if (limbs.isEmpty) {
      fail(type, 'has no limbs to reassemble');
    }

    BigInt value = BigInt.zero;
    for (int i = 0; i < limbs.length; i++) {
      final BigInt limb = limbs[i];
      final bool isTop = i == 0;

      if (isTop && signed) {
        if (limb < int64Min || limb > int64Max) {
          fail(
            type,
            'has a most significant limb outside the range of an int64',
          );
        }
      } else if (limb < BigInt.zero || limb > uint64Max) {
        fail(type, 'has a limb outside the range of a uint64');
      }

      value = (value << 64) + limb;
    }
    return value.toString();
  }

  /// Splits a base-10 decimal string into [limbCount] 64-bit limbs, most
  /// significant first, inverting [partsToDecimalString].
  ///
  /// When [signed] is set the most significant limb is returned signed and the
  /// rest unsigned.
  static List<BigInt> decimalStringToParts(
    Object? value, {
    required int limbCount,
    required bool signed,
    required String type,
    String? key,
  }) {
    if (value is! String) {
      fail(
        type,
        '${_at(key)}expects a base-10 decimal string but found ${preview(value)}',
      );
    }

    final BigInt? parsed = _parseDecimal(value);
    if (parsed == null) {
      fail(
        type,
        '${_at(key)}expects a base-10 decimal string but found ${preview(value)}',
      );
    }

    final int bits = 64 * limbCount;
    final BigInt min = signed ? -BigInt.two.pow(bits - 1) : BigInt.zero;
    final BigInt max = signed
        ? BigInt.two.pow(bits - 1) - BigInt.one
        : BigInt.two.pow(bits) - BigInt.one;
    if (parsed < min || parsed > max) {
      fail(
        type,
        '${_at(key)}holds $parsed, outside the range of ${signed ? 'a signed' : 'an unsigned'} $bits-bit integer',
      );
    }

    // Two's complement over the full width, so a negative value splits into
    // the same limbs the binary encoding carries.
    final BigInt unsigned = parsed & (BigInt.two.pow(bits) - BigInt.one);
    final List<BigInt> limbs = <BigInt>[];
    for (int i = 0; i < limbCount; i++) {
      final int shift = 64 * (limbCount - 1 - i);
      BigInt limb = (unsigned >> shift) & _uint64Mask;
      if (i == 0 && signed && limb > int64Max) {
        limb -= _twoPow64;
      }
      limbs.add(limb);
    }
    return limbs;
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  static String _at(String? key) => key == null ? '' : 'key "$key" ';

  /// The indefinite article that precedes a width name.
  ///
  /// The names in play are `int32`, `uint32`, `int64` and `uint64`, so the
  /// leading letter settles it.
  static String _article(String word) => word.startsWith('i') ? 'an' : 'a';

  static int _read32(
    Object? value, {
    required String type,
    required String? key,
    required int min,
    required int max,
    required String what,
  }) {
    if (value is! num) {
      fail(
        type,
        '${_at(key)}expects a JSON number but found ${preview(value)}',
      );
    }
    final BigInt? parsed = _parseDecimal(value.toString());
    if (parsed == null) {
      fail(
        type,
        '${_at(key)}expects a whole number but found ${preview(value)}',
      );
    }
    if (parsed < BigInt.from(min) || parsed > BigInt.from(max)) {
      fail(
        type,
        '${_at(key)}holds $parsed, outside the range of ${_article(what)} $what',
      );
    }
    return parsed.toInt();
  }

  static BigInt _read64(
    Object? value, {
    required String type,
    required String? key,
    required BigInt min,
    required BigInt max,
    required String what,
  }) {
    BigInt? parsed;
    if (value is String) {
      parsed = _parseDecimal(value);
    } else if (value is num) {
      // Accepted for compatibility with XDR-JSON v1, but only where a JSON
      // number is exact. Past 2^53 the decoder has already rounded, and the
      // rounded value is still a whole number, so its text reads as a valid
      // integer that is not the one the document carried. Magnitude is the only
      // signal available, and it does not vary by target; the text does.
      //
      // The bound is on the signed value. `int.abs()` overflows to itself at
      // the int64 minimum, so an abs() form would let exactly that one input —
      // a value XDR genuinely carries — past the bound.
      if (!value.isFinite ||
          value < -_maxExactJsonInteger ||
          value > _maxExactJsonInteger) {
        fail(
          type,
          '${_at(key)}holds ${preview(value)}, which a JSON number cannot carry '
          'exactly; render ${_article(what)} $what as a base-10 string',
        );
      }
      parsed = _parseDecimal(value.toString());
    }

    if (parsed == null) {
      fail(
        type,
        '${_at(key)}expects a base-10 $what string but found ${preview(value)}',
      );
    }
    if (parsed < min || parsed > max) {
      fail(
        type,
        '${_at(key)}holds $parsed, outside the range of ${_article(what)} $what',
      );
    }
    return parsed;
  }

  /// Parses canonical base-10 text: an optional minus sign, then either a
  /// single zero or a digit run with no leading zero. Rejects a leading plus,
  /// a fraction, an exponent, whitespace and a radix prefix.
  static BigInt? _parseDecimal(String text) {
    if (text.isEmpty) {
      return null;
    }
    int index = 0;
    bool negative = false;
    if (text.codeUnitAt(0) == 0x2D) {
      negative = true;
      index = 1;
    }
    if (index >= text.length) {
      return null;
    }
    final int first = text.codeUnitAt(index);
    if (first < 0x30 || first > 0x39) {
      return null;
    }
    if (first == 0x30) {
      // A single zero is the only rendering that may start with one, and there
      // is no negative zero.
      if (text.length - index > 1 || negative) {
        return null;
      }
    }
    for (int i = index; i < text.length; i++) {
      final int unit = text.codeUnitAt(i);
      if (unit < 0x30 || unit > 0x39) {
        return null;
      }
    }
    return BigInt.parse(text);
  }

  static void _checkElementCount(
    int count, {
    required String type,
    required String? key,
    int? maxLength,
  }) {
    if (maxLength != null && count > maxLength) {
      fail(
        type,
        '${_at(key)}holds $count elements, more than the declared maximum of $maxLength',
      );
    }
  }

  static void _checkByteLength(
    int count, {
    required String type,
    required String? key,
    int? expectedLength,
    int? maxLength,
  }) {
    if (expectedLength != null && count != expectedLength) {
      fail(
        type,
        '${_at(key)}holds $count bytes but the declared length is $expectedLength',
      );
    }
    if (maxLength != null && count > maxLength) {
      fail(
        type,
        '${_at(key)}holds $count bytes, more than the declared maximum of $maxLength',
      );
    }
  }

  /// Lowercase hexadecimal digit value, or -1. Uppercase is not a digit here:
  /// the canonical rendering is lowercase and only one rendering is accepted.
  static int _hexDigit(int unit) {
    if (unit >= 0x30 && unit <= 0x39) {
      return unit - 0x30;
    }
    if (unit >= 0x61 && unit <= 0x66) {
      return unit - 0x61 + 10;
    }
    return -1;
  }

  /// Index just past the closing quote of the JSON string starting at [start].
  /// Unterminated input returns the end of the text and is left to the parser.
  static int _scanJsonString(String json, int start) {
    int index = start + 1;
    while (index < json.length) {
      final int unit = json.codeUnitAt(index);
      if (unit == 0x5C) {
        index += 2;
        continue;
      }
      if (unit == 0x22) {
        return index + 1;
      }
      index++;
    }
    return json.length;
  }

  static bool _followedByColon(String json, int index) {
    int probe = index;
    while (probe < json.length) {
      final int unit = json.codeUnitAt(probe);
      if (unit == 0x20 || unit == 0x09 || unit == 0x0A || unit == 0x0D) {
        probe++;
        continue;
      }
      return unit == 0x3A;
    }
    return false;
  }

  /// Resolves the JSON escapes of the string literal spanning [start, end), so
  /// two keys written differently but denoting the same text compare equal.
  static String _unescapeJsonString(String json, int start, int end) {
    final StringBuffer buffer = StringBuffer();
    int index = start + 1;
    final int limit = end - 1;

    while (index < limit) {
      final int unit = json.codeUnitAt(index);
      if (unit != 0x5C) {
        buffer.writeCharCode(unit);
        index++;
        continue;
      }

      index++;
      if (index >= limit) {
        break;
      }
      final int marker = json.codeUnitAt(index);
      index++;
      switch (marker) {
        case 0x62: // 'b'
          buffer.writeCharCode(0x08);
          break;
        case 0x66: // 'f'
          buffer.writeCharCode(0x0C);
          break;
        case 0x6E: // 'n'
          buffer.writeCharCode(0x0A);
          break;
        case 0x72: // 'r'
          buffer.writeCharCode(0x0D);
          break;
        case 0x74: // 't'
          buffer.writeCharCode(0x09);
          break;
        case 0x75: // 'u'
          if (index + 4 <= limit) {
            final int? code = int.tryParse(
              json.substring(index, index + 4),
              radix: 16,
            );
            if (code != null) {
              buffer.writeCharCode(code);
              index += 4;
              break;
            }
          }
          buffer.writeCharCode(marker);
          break;
        default:
          buffer.writeCharCode(marker);
      }
    }
    return buffer.toString();
  }

  /// One code unit rendered safe for a message: a backslash is doubled,
  /// printable ASCII passes through, and anything else becomes `\uXXXX`.
  static String _escapedUnit(int unit) {
    if (unit == 0x5C) {
      return r'\\';
    }
    if (unit >= 0x20 && unit <= 0x7E) {
      return String.fromCharCode(unit);
    }
    return '\\u${unit.toRadixString(16).padLeft(4, '0')}';
  }

  static String _escapeForMessage(String value) {
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < value.length; i++) {
      buffer.write(_escapedUnit(value.codeUnitAt(i)));
    }
    return buffer.toString();
  }

  /// Escapes and truncates together, so the cut falls between escapes and never
  /// inside one. Truncating the escaped text instead could end a preview on a
  /// partial `\uXX`, which reads as corruption rather than as elision.
  static String _escapeAndTruncate(String value) {
    final StringBuffer buffer = StringBuffer();
    int length = 0;

    for (int i = 0; i < value.length; i++) {
      final String piece = _escapedUnit(value.codeUnitAt(i));
      if (length + piece.length > _maxPreviewLength) {
        buffer.write('...');
        return buffer.toString();
      }
      buffer.write(piece);
      length += piece.length;
    }
    return buffer.toString();
  }
}
