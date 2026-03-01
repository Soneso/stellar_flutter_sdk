// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrSorobanCredentialsType {
  final _value;
  const XdrSorobanCredentialsType._internal(this._value);
  toString() => 'SorobanCredentialsType.$_value';
  XdrSorobanCredentialsType(this._value);
  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XdrSorobanCredentialsType && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  static const SOROBAN_CREDENTIALS_SOURCE_ACCOUNT =
      const XdrSorobanCredentialsType._internal(0);
  static const SOROBAN_CREDENTIALS_ADDRESS =
      const XdrSorobanCredentialsType._internal(1);

  static XdrSorobanCredentialsType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return SOROBAN_CREDENTIALS_SOURCE_ACCOUNT;
      case 1:
        return SOROBAN_CREDENTIALS_ADDRESS;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
      XdrDataOutputStream stream, XdrSorobanCredentialsType value) {
    stream.writeInt(value.value);
  }
}
