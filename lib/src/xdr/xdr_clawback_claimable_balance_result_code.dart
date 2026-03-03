// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrClawbackClaimableBalanceResultCode {
  final _value;
  const XdrClawbackClaimableBalanceResultCode._internal(this._value);
  toString() => 'ClawbackClaimableBalanceResultCode.$_value';
  XdrClawbackClaimableBalanceResultCode(this._value);
  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XdrClawbackClaimableBalanceResultCode && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  static const CLAWBACK_CLAIMABLE_BALANCE_SUCCESS =
      const XdrClawbackClaimableBalanceResultCode._internal(0);
  static const CLAWBACK_CLAIMABLE_BALANCE_DOES_NOT_EXIST =
      const XdrClawbackClaimableBalanceResultCode._internal(-1);
  static const CLAWBACK_CLAIMABLE_BALANCE_NOT_ISSUER =
      const XdrClawbackClaimableBalanceResultCode._internal(-2);
  static const CLAWBACK_CLAIMABLE_BALANCE_NOT_CLAWBACK_ENABLED =
      const XdrClawbackClaimableBalanceResultCode._internal(-3);

  static XdrClawbackClaimableBalanceResultCode decode(
    XdrDataInputStream stream,
  ) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return CLAWBACK_CLAIMABLE_BALANCE_SUCCESS;
      case -1:
        return CLAWBACK_CLAIMABLE_BALANCE_DOES_NOT_EXIST;
      case -2:
        return CLAWBACK_CLAIMABLE_BALANCE_NOT_ISSUER;
      case -3:
        return CLAWBACK_CLAIMABLE_BALANCE_NOT_CLAWBACK_ENABLED;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
    XdrDataOutputStream stream,
    XdrClawbackClaimableBalanceResultCode value,
  ) {
    stream.writeInt(value.value);
  }
}
