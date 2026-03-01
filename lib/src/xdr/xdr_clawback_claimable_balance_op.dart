// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_claimable_balance_id.dart';
import 'xdr_data_io.dart';

class XdrClawbackClaimableBalanceOp {
  XdrClaimableBalanceID _balanceID;

  XdrClaimableBalanceID get balanceID => this._balanceID;

  set balanceID(XdrClaimableBalanceID value) => this._balanceID = value;

  XdrClawbackClaimableBalanceOp(this._balanceID);

  static void encode(
      XdrDataOutputStream stream, XdrClawbackClaimableBalanceOp encoded) {
    XdrClaimableBalanceID.encode(stream, encoded.balanceID);
  }

  static XdrClawbackClaimableBalanceOp decode(XdrDataInputStream stream) {
    return XdrClawbackClaimableBalanceOp(XdrClaimableBalanceID.decode(stream));
  }
}
