// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrSorobanAuthorizedFunctionType {
  final _value;
  const XdrSorobanAuthorizedFunctionType._internal(this._value);
  toString() => 'XdrSorobanAuthorizedFunctionType.$_value';
  XdrSorobanAuthorizedFunctionType(this._value);
  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XdrSorobanAuthorizedFunctionType && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  static const SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN =
      const XdrSorobanAuthorizedFunctionType._internal(0);
  static const SOROBAN_AUTHORIZED_FUNCTION_TYPE_CREATE_CONTRACT_HOST_FN =
      const XdrSorobanAuthorizedFunctionType._internal(1);
  static const SOROBAN_AUTHORIZED_FUNCTION_TYPE_CREATE_CONTRACT_V2_HOST_FN =
      const XdrSorobanAuthorizedFunctionType._internal(2);

  static XdrSorobanAuthorizedFunctionType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN;
      case 1:
        return SOROBAN_AUTHORIZED_FUNCTION_TYPE_CREATE_CONTRACT_HOST_FN;
      case 2:
        return SOROBAN_AUTHORIZED_FUNCTION_TYPE_CREATE_CONTRACT_V2_HOST_FN;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
      XdrDataOutputStream stream, XdrSorobanAuthorizedFunctionType value) {
    stream.writeInt(value.value);
  }
}
