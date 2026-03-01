// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_account_entry_v1_ext.dart';
import 'xdr_data_io.dart';
import 'xdr_liabilities.dart';

class XdrAccountEntryV1 {
  XdrLiabilities _liabilities;

  XdrLiabilities get liabilities => this._liabilities;

  set liabilities(XdrLiabilities value) => this._liabilities = value;

  XdrAccountEntryV1Ext _ext;

  XdrAccountEntryV1Ext get ext => this._ext;

  set ext(XdrAccountEntryV1Ext value) => this._ext = value;

  XdrAccountEntryV1(this._liabilities, this._ext);

  static void encode(
      XdrDataOutputStream stream, XdrAccountEntryV1 encodedAccountEntryV1) {
    XdrLiabilities.encode(stream, encodedAccountEntryV1.liabilities);
    XdrAccountEntryV1Ext.encode(stream, encodedAccountEntryV1.ext);
  }

  static XdrAccountEntryV1 decode(XdrDataInputStream stream) {
    return XdrAccountEntryV1(
        XdrLiabilities.decode(stream), XdrAccountEntryV1Ext.decode(stream));
  }
}
