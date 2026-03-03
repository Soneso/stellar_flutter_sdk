// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrTxSetComponentType {
  final _value;
  const XdrTxSetComponentType._internal(this._value);
  toString() => 'TxSetComponentType.$_value';
  XdrTxSetComponentType(this._value);
  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XdrTxSetComponentType && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  static const TXSET_COMP_TXS_MAYBE_DISCOUNTED_FEE =
      const XdrTxSetComponentType._internal(0);

  static XdrTxSetComponentType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return TXSET_COMP_TXS_MAYBE_DISCOUNTED_FEE;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrTxSetComponentType value) {
    stream.writeInt(value.value);
  }
}
