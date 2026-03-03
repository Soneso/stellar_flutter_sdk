// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_account_id.dart';
import 'xdr_data_io.dart';

class XdrLedgerKeyAccount {

  XdrAccountID _accountID;
  XdrAccountID get accountID => this._accountID;
  set accountID(XdrAccountID value) => this._accountID = value;

  XdrLedgerKeyAccount(this._accountID);

  static void encode(XdrDataOutputStream stream, XdrLedgerKeyAccount encodedLedgerKeyAccount) {
    XdrAccountID.encode(stream, encodedLedgerKeyAccount.accountID);
  }

  static XdrLedgerKeyAccount decode(XdrDataInputStream stream) {
    XdrAccountID accountID = XdrAccountID.decode(stream);
    return XdrLedgerKeyAccount(accountID);
  }
}
