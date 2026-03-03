// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrClaimableBalanceFlags {
  final _value;
  const XdrClaimableBalanceFlags._internal(this._value);
  toString() => 'ClaimableBalanceFlags.$_value';
  XdrClaimableBalanceFlags(this._value);
  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is XdrClaimableBalanceFlags && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  static const CLAIMABLE_BALANCE_CLAWBACK_ENABLED_FLAG = const XdrClaimableBalanceFlags._internal(1);

  static XdrClaimableBalanceFlags decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 1:
        return CLAIMABLE_BALANCE_CLAWBACK_ENABLED_FLAG;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrClaimableBalanceFlags value) {
    stream.writeInt(value.value);
  }
}
