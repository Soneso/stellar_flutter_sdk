// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_claimable_balance_id.dart';
import 'xdr_data_io.dart';

class XdrClaimClaimableBalanceOp {
  XdrClaimableBalanceID _balanceID;

  XdrClaimableBalanceID get balanceID => this._balanceID;

  set balanceID(XdrClaimableBalanceID value) => this._balanceID = value;

  XdrClaimClaimableBalanceOp(this._balanceID);

  static void encode(
    XdrDataOutputStream stream,
    XdrClaimClaimableBalanceOp encoded,
  ) {
    XdrClaimableBalanceID.encode(stream, encoded.balanceID);
  }

  static XdrClaimClaimableBalanceOp decode(XdrDataInputStream stream) {
    return XdrClaimClaimableBalanceOp(XdrClaimableBalanceID.decode(stream));
  }
}
