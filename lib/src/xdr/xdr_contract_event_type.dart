// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrContractEventType {
  final _value;
  const XdrContractEventType._internal(this._value);
  toString() => 'ContractEventType.$_value';
  XdrContractEventType(this._value);
  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is XdrContractEventType && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  static const SYSTEM = const XdrContractEventType._internal(0);
  static const CONTRACT = const XdrContractEventType._internal(1);
  static const DIAGNOSTIC = const XdrContractEventType._internal(2);

  static XdrContractEventType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return SYSTEM;
      case 1:
        return CONTRACT;
      case 2:
        return DIAGNOSTIC;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrContractEventType value) {
    stream.writeInt(value.value);
  }
}
