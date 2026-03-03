// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_claimable_balance_id.dart';
import 'xdr_data_io.dart';

class XdrLedgerKeyClaimableBalance {
  XdrClaimableBalanceID _balanceID;
  XdrClaimableBalanceID get balanceID => this._balanceID;
  set balanceID(XdrClaimableBalanceID value) => this._balanceID = value;

  XdrLedgerKeyClaimableBalance(this._balanceID);

  static void encode(
    XdrDataOutputStream stream,
    XdrLedgerKeyClaimableBalance encodedLedgerKeyClaimableBalance,
  ) {
    XdrClaimableBalanceID.encode(
      stream,
      encodedLedgerKeyClaimableBalance.balanceID,
    );
  }

  static XdrLedgerKeyClaimableBalance decode(XdrDataInputStream stream) {
    XdrClaimableBalanceID balanceID = XdrClaimableBalanceID.decode(stream);
    return XdrLedgerKeyClaimableBalance(balanceID);
  }
}
