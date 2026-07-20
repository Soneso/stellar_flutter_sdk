// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';

import '../../xdr/xdr.dart';

/// Orders two [XdrSCVal] ScMap keys the way the Soroban host does.
///
/// The host stores and validates ScMap keys in a semantic order and rejects a
/// map whose keys are not in that order when it materializes the map from an
/// `SCVal` contract argument. Sorting by the XDR-encoded key bytes instead is
/// length-major — the four-byte length prefix of a variable-length payload is
/// compared before its content — which diverges from the host whenever two
/// keys' variable-length fields differ in length, and the host then rejects
/// the map with `InvalidInput`.
///
/// Ordering:
///
/// - Values of different types compare by their `SCValType` discriminant.
/// - `Vec` compares element-wise (recursively); the shorter vec sorts first
///   on a prefix tie.
/// - `Map` compares entry-wise (key, then value, recursively); the map with
///   fewer entries sorts first on a prefix tie.
/// - `Bytes`, `String`, and `Symbol` compare by content, byte for byte
///   (unsigned); the shorter value sorts first on a prefix tie (length is
///   the tiebreaker, never the primary key).
/// - All remaining values compare by their XDR encoding. For the fixed-width
///   types that can appear in smart-account map keys (addresses, unsigned
///   scalars) this equals a content comparison. Signed integer scalars would
///   compare by their two's-complement bytes rather than numerically; they
///   cannot appear as smart-account map keys.
int compareScValHostOrder(XdrSCVal a, XdrSCVal b) {
  final int typeA = a.discriminant.value as int;
  final int typeB = b.discriminant.value as int;
  if (typeA != typeB) {
    return typeA.compareTo(typeB);
  }

  if (a.discriminant == XdrSCValType.SCV_VEC) {
    final elementsA = a.vec ?? const <XdrSCVal>[];
    final elementsB = b.vec ?? const <XdrSCVal>[];
    final shared =
        elementsA.length < elementsB.length ? elementsA.length : elementsB.length;
    for (var i = 0; i < shared; i++) {
      final cmp = compareScValHostOrder(elementsA[i], elementsB[i]);
      if (cmp != 0) return cmp;
    }
    return elementsA.length.compareTo(elementsB.length);
  }
  if (a.discriminant == XdrSCValType.SCV_MAP) {
    final entriesA = a.map ?? const <XdrSCMapEntry>[];
    final entriesB = b.map ?? const <XdrSCMapEntry>[];
    final shared =
        entriesA.length < entriesB.length ? entriesA.length : entriesB.length;
    for (var i = 0; i < shared; i++) {
      final keyCmp = compareScValHostOrder(entriesA[i].key, entriesB[i].key);
      if (keyCmp != 0) return keyCmp;
      final valCmp = compareScValHostOrder(entriesA[i].val, entriesB[i].val);
      if (valCmp != 0) return valCmp;
    }
    return entriesA.length.compareTo(entriesB.length);
  }
  if (a.discriminant == XdrSCValType.SCV_BYTES) {
    return _compareBytesUnsigned(
      a.bytes?.sCBytes ?? const <int>[],
      b.bytes?.sCBytes ?? const <int>[],
    );
  }
  if (a.discriminant == XdrSCValType.SCV_STRING) {
    return _compareBytesUnsigned(
      utf8.encode(a.str ?? ''),
      utf8.encode(b.str ?? ''),
    );
  }
  if (a.discriminant == XdrSCValType.SCV_SYMBOL) {
    return _compareBytesUnsigned(
      utf8.encode(a.sym ?? ''),
      utf8.encode(b.sym ?? ''),
    );
  }
  return _compareBytesUnsigned(
    _scValToXdrBytesForOrder(a),
    _scValToXdrBytesForOrder(b),
  );
}

/// Compares two byte sequences element-wise as unsigned bytes; on a prefix
/// tie the shorter sequence is smaller. This matches the Soroban host's
/// ordering of `Bytes`/`String`/`Symbol` content (Rust slice `Ord`).
int _compareBytesUnsigned(List<int> a, List<int> b) {
  final shared = a.length < b.length ? a.length : b.length;
  for (var i = 0; i < shared; i++) {
    final cmp = (a[i] & 0xFF).compareTo(b[i] & 0xFF);
    if (cmp != 0) return cmp;
  }
  return a.length.compareTo(b.length);
}

List<int> _scValToXdrBytesForOrder(XdrSCVal value) {
  final stream = XdrDataOutputStream();
  XdrSCVal.encode(stream, value);
  return stream.bytes;
}
