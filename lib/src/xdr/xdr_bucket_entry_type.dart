// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrBucketEntryType {
  final _value;
  const XdrBucketEntryType._internal(this._value);
  toString() => 'BucketEntryType.$_value';
  XdrBucketEntryType(this._value);
  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XdrBucketEntryType && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

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
