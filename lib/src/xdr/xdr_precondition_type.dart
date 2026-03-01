// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrPreconditionType {
  final _value;

  const XdrPreconditionType._internal(this._value);

  toString() => 'PreconditionType.$_value';

  XdrPreconditionType(this._value);

  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XdrPreconditionType && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  static const NONE = const XdrPreconditionType._internal(0);
  static const TIME = const XdrPreconditionType._internal(1);
  static const V2 = const XdrPreconditionType._internal(2);

  static XdrPreconditionType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return NONE;
      case 1:
        return TIME;
      case 2:
        return V2;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrPreconditionType value) {
    stream.writeInt(value.value);
  }
}
