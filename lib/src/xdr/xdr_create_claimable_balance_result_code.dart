// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrCreateClaimableBalanceResultCode {
  final _value;

  const XdrCreateClaimableBalanceResultCode._internal(this._value);

  toString() => 'CreateClaimableBalanceResultCode.$_value';

  XdrCreateClaimableBalanceResultCode(this._value);

  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XdrCreateClaimableBalanceResultCode && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  /// Success.
  static const CREATE_CLAIMABLE_BALANCE_SUCCESS =
      const XdrCreateClaimableBalanceResultCode._internal(0);

  static const CREATE_CLAIMABLE_BALANCE_MALFORMED =
      const XdrCreateClaimableBalanceResultCode._internal(-1);

  static const CREATE_CLAIMABLE_BALANCE_LOW_RESERVE =
      const XdrCreateClaimableBalanceResultCode._internal(-2);

  static const CREATE_CLAIMABLE_BALANCE_NO_TRUST =
      const XdrCreateClaimableBalanceResultCode._internal(-3);

  static const CREATE_CLAIMABLE_BALANCE_NOT_AUTHORIZED =
      const XdrCreateClaimableBalanceResultCode._internal(-4);

  static const CREATE_CLAIMABLE_BALANCE_UNDERFUNDED =
      const XdrCreateClaimableBalanceResultCode._internal(-5);

  static XdrCreateClaimableBalanceResultCode decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return CREATE_CLAIMABLE_BALANCE_SUCCESS;
      case -1:
        return CREATE_CLAIMABLE_BALANCE_MALFORMED;
      case -2:
        return CREATE_CLAIMABLE_BALANCE_LOW_RESERVE;
      case -3:
        return CREATE_CLAIMABLE_BALANCE_NO_TRUST;
      case -4:
        return CREATE_CLAIMABLE_BALANCE_NOT_AUTHORIZED;
      case -5:
        return CREATE_CLAIMABLE_BALANCE_UNDERFUNDED;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
    XdrDataOutputStream stream,
    XdrCreateClaimableBalanceResultCode value,
  ) {
    stream.writeInt(value.value);
  }
}
