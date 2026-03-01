// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrContractDataDurability {
  final _value;
  const XdrContractDataDurability._internal(this._value);
  toString() => 'ContractDataDurability.$_value';
  XdrContractDataDurability(this._value);
  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XdrContractDataDurability && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  static const TEMPORARY = const XdrContractDataDurability._internal(0);
  static const PERSISTENT = const XdrContractDataDurability._internal(1);

  static XdrContractDataDurability decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return TEMPORARY;
      case 1:
        return PERSISTENT;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
    XdrDataOutputStream stream,
    XdrContractDataDurability value,
  ) {
    stream.writeInt(value.value);
  }
}
