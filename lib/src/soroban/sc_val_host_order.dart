// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';

import '../xdr/xdr.dart';

/// Orders two [XdrSCVal] values the way the Soroban host does.
///
/// The host keeps ScMap keys in this order and rejects a contract argument
/// map whose keys are out of order or repeated with `InvalidInput`. The
/// XDR-encoded bytes of a variable-length value start with its length, so
/// they do not give this order. Use [sortedScMap] to build a map from caller
/// data.
///
/// Ordering:
///
/// - Values of different types compare by their `SCValType` discriminant.
/// - `I32`, `I64`, `I128`, `I256`, and `LedgerKeyNonce` compare as signed
///   integers over their full width.
/// - `Vec` compares element-wise (recursively); the shorter vec sorts first
///   on a prefix tie.
/// - `Map` compares entry-wise (key, then value, recursively); the map with
///   fewer entries sorts first on a prefix tie.
/// - `Bytes`, `String`, `Symbol`, and `ExecutableTag` compare by content,
///   byte for byte (unsigned); the shorter value sorts first on a prefix tie
///   (length is the tiebreaker, never the primary key).
/// - `ContractInstance` compares by executable, then by storage: absent
///   storage first, present storage by the `Map` rule.
/// - All remaining types (`Bool`, `Void`, `Error`, `U32`, `U64`, `U128`,
///   `U256`, `Timepoint`, `Duration`, `Address`, `LedgerKeyContractInstance`)
///   encode as enum values and unsigned big-endian fields of fixed width, so
///   their XDR bytes compare in the host's field-by-field order.
int compareScValHostOrder(XdrSCVal a, XdrSCVal b) {
  final int typeA = a.discriminant.value as int;
  final int typeB = b.discriminant.value as int;
  if (typeA != typeB) {
    return typeA.compareTo(typeB);
  }

  if (a.discriminant == XdrSCValType.SCV_I32) {
    return a.i32!.int32.toSigned(32).compareTo(b.i32!.int32.toSigned(32));
  }
  if (a.discriminant == XdrSCValType.SCV_I64) {
    return _compareSigned64(a.i64!, b.i64!);
  }
  if (a.discriminant == XdrSCValType.SCV_LEDGER_KEY_NONCE) {
    return _compareSigned64(a.nonce_key!.nonce, b.nonce_key!.nonce);
  }
  if (a.discriminant == XdrSCValType.SCV_I128) {
    final hi = _compareSigned64(a.i128!.hi, b.i128!.hi);
    return hi != 0 ? hi : _compareUnsigned64(a.i128!.lo, b.i128!.lo);
  }
  if (a.discriminant == XdrSCValType.SCV_I256) {
    final x = a.i256!;
    final y = b.i256!;
    var cmp = _compareSigned64(x.hiHi, y.hiHi);
    if (cmp == 0) cmp = _compareUnsigned64(x.hiLo, y.hiLo);
    if (cmp == 0) cmp = _compareUnsigned64(x.loHi, y.loHi);
    if (cmp == 0) cmp = _compareUnsigned64(x.loLo, y.loLo);
    return cmp;
  }

  if (a.discriminant == XdrSCValType.SCV_VEC) {
    final elementsA = a.vec ?? const <XdrSCVal>[];
    final elementsB = b.vec ?? const <XdrSCVal>[];
    final shared = elementsA.length < elementsB.length
        ? elementsA.length
        : elementsB.length;
    for (var i = 0; i < shared; i++) {
      final cmp = compareScValHostOrder(elementsA[i], elementsB[i]);
      if (cmp != 0) return cmp;
    }
    return elementsA.length.compareTo(elementsB.length);
  }
  if (a.discriminant == XdrSCValType.SCV_MAP) {
    final entriesA = a.map ?? const <XdrSCMapEntry>[];
    final entriesB = b.map ?? const <XdrSCMapEntry>[];
    final shared = entriesA.length < entriesB.length
        ? entriesA.length
        : entriesB.length;
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
  if (a.discriminant == XdrSCValType.SCV_EXECUTABLE_TAG) {
    return _compareBytesUnsigned(
      a.executableTag ?? const <int>[],
      b.executableTag ?? const <int>[],
    );
  }
  if (a.discriminant == XdrSCValType.SCV_CONTRACT_INSTANCE) {
    final executableCmp = _compareExecutables(
      a.instance!.executable,
      b.instance!.executable,
    );
    if (executableCmp != 0) return executableCmp;
    final storageA = a.instance!.storage;
    final storageB = b.instance!.storage;
    if (storageA == null) return storageB == null ? 0 : -1;
    if (storageB == null) return 1;
    return compareScValHostOrder(
      XdrSCVal.forMap(storageA),
      XdrSCVal.forMap(storageB),
    );
  }
  return _compareBytesUnsigned(
    _scValToXdrBytesForOrder(a),
    _scValToXdrBytesForOrder(b),
  );
}

/// Builds an `SCV_MAP` value from [entries] with the keys in the Soroban
/// host's order ([compareScValHostOrder]).
///
/// [entries] itself is left unchanged. Throws an [ArgumentError] naming the
/// key when two keys compare equal.
XdrSCVal sortedScMap(List<XdrSCMapEntry> entries) {
  final sorted = List<XdrSCMapEntry>.of(entries)
    ..sort((x, y) => compareScValHostOrder(x.key, y.key));
  for (var i = 1; i < sorted.length; i++) {
    if (compareScValHostOrder(sorted[i - 1].key, sorted[i].key) == 0) {
      throw ArgumentError.value(
        sorted[i].key.toXdrJson(),
        'entries',
        'Duplicate ScMap key',
      );
    }
  }
  return XdrSCVal.forMap(sorted);
}

/// Orders contract executables by `ContractExecutableType` value, then a Wasm
/// executable by its hash, an external reference by its owner address and
/// then its tag bytes.
int _compareExecutables(XdrContractExecutable a, XdrContractExecutable b) {
  final typeA = a.discriminant.value as int;
  final typeB = b.discriminant.value as int;
  if (typeA != typeB) return typeA.compareTo(typeB);
  if (a.wasmHash != null) {
    return _compareBytesUnsigned(a.wasmHash!.hash, b.wasmHash!.hash);
  }
  final refA = a.externalRef;
  final refB = b.externalRef;
  if (refA == null || refB == null) return 0;
  final ownerCmp = compareScValHostOrder(
    XdrSCVal.forAddress(refA.executableOwner),
    XdrSCVal.forAddress(refB.executableOwner),
  );
  return ownerCmp != 0 ? ownerCmp : _compareBytesUnsigned(refA.tag, refB.tag);
}

int _compareSigned64(XdrInt64 a, XdrInt64 b) =>
    a.int64.toSigned(64).compareTo(b.int64.toSigned(64));

int _compareUnsigned64(XdrUint64 a, XdrUint64 b) =>
    a.uint64.toUnsigned(64).compareTo(b.uint64.toUnsigned(64));

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
