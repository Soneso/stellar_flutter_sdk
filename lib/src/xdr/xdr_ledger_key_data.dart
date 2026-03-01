// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_account_id.dart';
import 'xdr_data_io.dart';
import 'xdr_ledger_key_data_base.dart';
import 'xdr_string64.dart';

class XdrLedgerKeyData extends XdrLedgerKeyDataBase {
  XdrLedgerKeyData(super.accountID, super.dataName);

  static void encode(XdrDataOutputStream stream, XdrLedgerKeyData val) {
    XdrLedgerKeyDataBase.encode(stream, val);
  }

  static XdrLedgerKeyData decode(XdrDataInputStream stream) {
    var b = XdrLedgerKeyDataBase.decode(stream);
    return XdrLedgerKeyData(b.accountID, b.dataName);
  }

  static XdrLedgerKeyData forDataName(String accountId, String dataName) {
    return XdrLedgerKeyData(
      XdrAccountID.forAccountId(accountId),
      XdrString64(dataName),
    );
  }
}
