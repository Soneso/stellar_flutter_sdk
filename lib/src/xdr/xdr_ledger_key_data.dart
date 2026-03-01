// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_account_id.dart';
import 'xdr_data_io.dart';
import 'xdr_string64.dart';

class XdrLedgerKeyData {
  XdrLedgerKeyData(this._accountID, this._dataName);

  XdrAccountID _accountID;

  XdrAccountID get accountID => this._accountID;

  set accountID(XdrAccountID value) => this._accountID = value;

  XdrString64 _dataName;

  XdrString64 get dataName => this._dataName;

  set dataName(XdrString64 value) => this._dataName = value;

  static void encode(
      XdrDataOutputStream stream, XdrLedgerKeyData encodedLedgerKeyData) {
    XdrAccountID.encode(stream, encodedLedgerKeyData.accountID);
    XdrString64.encode(stream, encodedLedgerKeyData.dataName);
  }

  static XdrLedgerKeyData decode(XdrDataInputStream stream) {
    return XdrLedgerKeyData(
        XdrAccountID.decode(stream), XdrString64.decode(stream));
  }

  static XdrLedgerKeyData forDataName(String accountId, String dataName) {
    return XdrLedgerKeyData(
        XdrAccountID.forAccountId(accountId), XdrString64(dataName));
  }
}
