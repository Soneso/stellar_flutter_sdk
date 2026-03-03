// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrSCAddressType {
  final _value;
  const XdrSCAddressType._internal(this._value);
  toString() => 'SCAddressType.$_value';
  XdrSCAddressType(this._value);
  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is XdrSCAddressType && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  static const SC_ADDRESS_TYPE_ACCOUNT = const XdrSCAddressType._internal(0);
  static const SC_ADDRESS_TYPE_CONTRACT = const XdrSCAddressType._internal(1);
  static const SC_ADDRESS_TYPE_MUXED_ACCOUNT = const XdrSCAddressType._internal(2);
  static const SC_ADDRESS_TYPE_CLAIMABLE_BALANCE = const XdrSCAddressType._internal(3);
  static const SC_ADDRESS_TYPE_LIQUIDITY_POOL = const XdrSCAddressType._internal(4);

  static XdrSCAddressType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return SC_ADDRESS_TYPE_ACCOUNT;
      case 1:
        return SC_ADDRESS_TYPE_CONTRACT;
      case 2:
        return SC_ADDRESS_TYPE_MUXED_ACCOUNT;
      case 3:
        return SC_ADDRESS_TYPE_CLAIMABLE_BALANCE;
      case 4:
        return SC_ADDRESS_TYPE_LIQUIDITY_POOL;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrSCAddressType value) {
    stream.writeInt(value.value);
  }
}
