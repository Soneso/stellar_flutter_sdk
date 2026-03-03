// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrSCErrorType {
  final _value;
  const XdrSCErrorType._internal(this._value);
  toString() => 'SCErrorType.$_value';
  XdrSCErrorType(this._value);
  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XdrSCErrorType && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  static const SCE_CONTRACT = const XdrSCErrorType._internal(0);
  static const SCE_WASM_VM = const XdrSCErrorType._internal(1);
  static const SCE_CONTEXT = const XdrSCErrorType._internal(2);
  static const SCE_STORAGE = const XdrSCErrorType._internal(3);
  static const SCE_OBJECT = const XdrSCErrorType._internal(4);
  static const SCE_CRYPTO = const XdrSCErrorType._internal(5);
  static const SCE_EVENTS = const XdrSCErrorType._internal(6);
  static const SCE_BUDGET = const XdrSCErrorType._internal(7);
  static const SCE_VALUE = const XdrSCErrorType._internal(8);
  static const SCE_AUTH = const XdrSCErrorType._internal(9);

  static XdrSCErrorType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return SCE_CONTRACT;
      case 1:
        return SCE_WASM_VM;
      case 2:
        return SCE_CONTEXT;
      case 3:
        return SCE_STORAGE;
      case 4:
        return SCE_OBJECT;
      case 5:
        return SCE_CRYPTO;
      case 6:
        return SCE_EVENTS;
      case 7:
        return SCE_BUDGET;
      case 8:
        return SCE_VALUE;
      case 9:
        return SCE_AUTH;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrSCErrorType value) {
    stream.writeInt(value.value);
  }
}
