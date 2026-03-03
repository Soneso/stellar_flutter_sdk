// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrSCMetaKind {
  final _value;
  const XdrSCMetaKind._internal(this._value);
  toString() => 'SCMetaKind.$_value';
  XdrSCMetaKind(this._value);
  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is XdrSCMetaKind && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  static const SC_META_V0 = const XdrSCMetaKind._internal(0);

  static XdrSCMetaKind decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return SC_META_V0;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrSCMetaKind value) {
    stream.writeInt(value.value);
  }
}
