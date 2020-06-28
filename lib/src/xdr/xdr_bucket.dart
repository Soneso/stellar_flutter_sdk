// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_ledger.dart';
import 'xdr_data_io.dart';

//TODO: add BucketMetadata

class XdrBucketEntryType {
  final _value;
  const XdrBucketEntryType._internal(this._value);
  toString() => 'BucketEntryType.$_value';
  XdrBucketEntryType(this._value);
  get value => this._value;

  /// Bucket metadata, should come first.
  static const METAENTRY = const XdrBucketEntryType._internal(-1);

  /// Only updated.
  static const LIVEENTRY = const XdrBucketEntryType._internal(0);

  /// Deadentry.
  static const DEADENTRY = const XdrBucketEntryType._internal(1);

  /// Only created.
  static const INITENTRY = const XdrBucketEntryType._internal(2);

  static XdrBucketEntryType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case -1:
        return METAENTRY;
      case 0:
        return LIVEENTRY;
      case 1:
        return DEADENTRY;
      case 2:
        return INITENTRY;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrBucketEntryType value) {
    stream.writeInt(value.value);
  }
}

class XdrBucketEntry {
  XdrBucketEntry();
  XdrBucketEntryType _type;
  XdrBucketEntryType get discriminant => this._type;
  set discriminant(XdrBucketEntryType value) => this._type = value;

  XdrLedgerEntry _liveEntry;
  XdrLedgerEntry get liveEntry => this._liveEntry;
  set liveEntry(XdrLedgerEntry value) => this._liveEntry = value;

  XdrLedgerKey _deadEntry;
  XdrLedgerKey get deadEntry => this._deadEntry;
  set deadEntry(XdrLedgerKey value) => this._deadEntry = value;

  static void encode(
      XdrDataOutputStream stream, XdrBucketEntry encodedBucketEntry) {
    stream.writeInt(encodedBucketEntry.discriminant.value);
    switch (encodedBucketEntry.discriminant) {
      case XdrBucketEntryType.LIVEENTRY:
        XdrLedgerEntry.encode(stream, encodedBucketEntry.liveEntry);
        break;
      case XdrBucketEntryType.DEADENTRY:
        XdrLedgerKey.encode(stream, encodedBucketEntry.deadEntry);
        break;
    }
  }

  static XdrBucketEntry decode(XdrDataInputStream stream) {
    XdrBucketEntry decodedBucketEntry = XdrBucketEntry();
    XdrBucketEntryType discriminant = XdrBucketEntryType.decode(stream);
    decodedBucketEntry.discriminant = discriminant;
    switch (decodedBucketEntry.discriminant) {
      case XdrBucketEntryType.LIVEENTRY:
        decodedBucketEntry.liveEntry = XdrLedgerEntry.decode(stream);
        break;
      case XdrBucketEntryType.DEADENTRY:
        decodedBucketEntry.deadEntry = XdrLedgerKey.decode(stream);
        break;
    }
    return decodedBucketEntry;
  }
}
