// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_account_id.dart';
import 'xdr_data_io.dart';
import 'xdr_ledger_entry_v1_ext.dart';

class XdrLedgerEntryV1 {
  XdrLedgerEntryV1(this._ext);

  XdrAccountID? _sponsoringID;

  XdrAccountID? get sponsoringID => this._sponsoringID;

  set sponsoringID(XdrAccountID? value) => this._sponsoringID = value;

  XdrLedgerEntryV1Ext _ext;

  XdrLedgerEntryV1Ext get ext => this._ext;

  set ext(XdrLedgerEntryV1Ext value) => this._ext = value;

  static void encode(XdrDataOutputStream stream, XdrLedgerEntryV1 encoded) {
    if (encoded.sponsoringID != null) {
      stream.writeInt(1);
      XdrAccountID.encode(stream, encoded.sponsoringID);
    } else {
      stream.writeInt(0);
    }
    XdrLedgerEntryV1Ext.encode(stream, encoded.ext);
  }

  static XdrLedgerEntryV1 decode(XdrDataInputStream stream) {
    int sponsoringIDPresent = stream.readInt();
    XdrAccountID? sponsoringID;
    if (sponsoringIDPresent != 0) {
      sponsoringID = XdrAccountID.decode(stream);
    }
    XdrLedgerEntryV1 decoded =
        XdrLedgerEntryV1(XdrLedgerEntryV1Ext.decode(stream));
    decoded.sponsoringID = sponsoringID;
    return decoded;
  }
}
