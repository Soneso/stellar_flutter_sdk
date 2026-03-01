// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrClaimableBalanceIDType {
  final _value;

  const XdrClaimableBalanceIDType._internal(this._value);

  toString() => 'ClaimableBalanceIDType.$_value';

  XdrClaimableBalanceIDType(this._value);

  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XdrClaimableBalanceIDType && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  static const CLAIMABLE_BALANCE_ID_TYPE_V0 =
      const XdrClaimableBalanceIDType._internal(0);

  static XdrClaimableBalanceIDType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return CLAIMABLE_BALANCE_ID_TYPE_V0;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
    XdrDataOutputStream stream,
    XdrClaimableBalanceIDType value,
  ) {
    stream.writeInt(value.value);
  }
}
