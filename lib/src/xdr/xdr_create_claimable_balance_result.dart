// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_claimable_balance_id.dart';
import 'xdr_create_claimable_balance_result_code.dart';
import 'xdr_data_io.dart';

class XdrCreateClaimableBalanceResult {
  XdrCreateClaimableBalanceResultCode _code;

  XdrCreateClaimableBalanceResultCode get discriminant => this._code;

  set discriminant(XdrCreateClaimableBalanceResultCode value) =>
      this._code = value;

  XdrClaimableBalanceID? _balanceID;

  XdrClaimableBalanceID? get balanceID => this._balanceID;

  set balanceID(XdrClaimableBalanceID? value) => this._balanceID = value;

  XdrCreateClaimableBalanceResult(this._code);

  static void encode(
      XdrDataOutputStream stream, XdrCreateClaimableBalanceResult encoded) {
    stream.writeInt(encoded.discriminant.value);
    switch (encoded.discriminant) {
      case XdrCreateClaimableBalanceResultCode.CREATE_CLAIMABLE_BALANCE_SUCCESS:
        XdrClaimableBalanceID.encode(stream, encoded.balanceID!);
        break;
      default:
        break;
    }
  }

  static XdrCreateClaimableBalanceResult decode(XdrDataInputStream stream) {
    XdrCreateClaimableBalanceResult decoded = XdrCreateClaimableBalanceResult(
        XdrCreateClaimableBalanceResultCode.decode(stream));
    switch (decoded.discriminant) {
      case XdrCreateClaimableBalanceResultCode.CREATE_CLAIMABLE_BALANCE_SUCCESS:
        decoded.balanceID = XdrClaimableBalanceID.decode(stream);
        break;
      default:
        break;
    }
    return decoded;
  }
}
