// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_account_id.dart';
import 'xdr_data_io.dart';
import 'xdr_uint64.dart';

class XdrLedgerKeyOffer {
  XdrLedgerKeyOffer(this._sellerID, this._offerID);

  XdrAccountID _sellerID;

  XdrAccountID get sellerID => this._sellerID;

  set sellerID(XdrAccountID value) => this._sellerID = value;

  XdrUint64 _offerID;

  XdrUint64 get offerID => this._offerID;

  set offerID(XdrUint64 value) => this._offerID = value;

  static void encode(
      XdrDataOutputStream stream, XdrLedgerKeyOffer encodedLedgerKeyOffer) {
    XdrAccountID.encode(stream, encodedLedgerKeyOffer.sellerID);
    XdrUint64.encode(stream, encodedLedgerKeyOffer.offerID);
  }

  static XdrLedgerKeyOffer decode(XdrDataInputStream stream) {
    return XdrLedgerKeyOffer(
        XdrAccountID.decode(stream), XdrUint64.decode(stream));
  }

  static XdrLedgerKeyOffer forOfferId(String sellerAccountId, int offerId) {
    return XdrLedgerKeyOffer(
        XdrAccountID.forAccountId(sellerAccountId), XdrUint64(BigInt.from(offerId)));
  }
}
