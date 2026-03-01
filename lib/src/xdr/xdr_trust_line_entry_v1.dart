// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_liabilities.dart';
import 'xdr_trust_line_entry_v1_ext.dart';

class XdrTrustLineEntryV1 {
  XdrTrustLineEntryV1(this._liabilities, this._ext);

  XdrLiabilities _liabilities;

  XdrLiabilities get liabilities => this._liabilities;

  set liabilities(XdrLiabilities value) => this._liabilities = value;

  XdrTrustLineEntryV1Ext _ext;

  XdrTrustLineEntryV1Ext get ext => this._ext;

  set ext(XdrTrustLineEntryV1Ext value) => this._ext = value;

  static void encode(
      XdrDataOutputStream stream, XdrTrustLineEntryV1 encodedTrustLineEntryV1) {
    XdrLiabilities.encode(stream, encodedTrustLineEntryV1.liabilities);
    XdrTrustLineEntryV1Ext.encode(stream, encodedTrustLineEntryV1.ext);
  }

  static XdrTrustLineEntryV1 decode(XdrDataInputStream stream) {
    XdrLiabilities liabilities = XdrLiabilities.decode(stream);
    XdrTrustLineEntryV1Ext ext = XdrTrustLineEntryV1Ext.decode(stream);
    return XdrTrustLineEntryV1(liabilities, ext);
  }
}
