// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_account_id.dart';
import 'xdr_data_io.dart';
import 'xdr_string64.dart';

class XdrLedgerKeyDataBase {

  XdrAccountID _accountID;
  XdrAccountID get accountID => this._accountID;
  set accountID(XdrAccountID value) => this._accountID = value;

  XdrString64 _dataName;
  XdrString64 get dataName => this._dataName;
  set dataName(XdrString64 value) => this._dataName = value;

  XdrLedgerKeyDataBase(this._accountID, this._dataName);

  static void encode(XdrDataOutputStream stream, XdrLedgerKeyDataBase encodedLedgerKeyData) {
    XdrAccountID.encode(stream, encodedLedgerKeyData.accountID);
    XdrString64.encode(stream, encodedLedgerKeyData.dataName);
  }

  static XdrLedgerKeyDataBase decode(XdrDataInputStream stream) {
    XdrAccountID accountID = XdrAccountID.decode(stream);
    XdrString64 dataName = XdrString64.decode(stream);
    return XdrLedgerKeyDataBase(accountID, dataName);
  }
}
