// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrStellarValueType {
  final _value;
  const XdrStellarValueType._internal(this._value);
  toString() => 'StellarValueType.$_value';
  XdrStellarValueType(this._value);
  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XdrStellarValueType && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  static const STELLAR_VALUE_BASIC = const XdrStellarValueType._internal(0);
  static const STELLAR_VALUE_SIGNED = const XdrStellarValueType._internal(1);

  static XdrStellarValueType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return STELLAR_VALUE_BASIC;
      case 1:
        return STELLAR_VALUE_SIGNED;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrStellarValueType value) {
    stream.writeInt(value.value);
  }
}
