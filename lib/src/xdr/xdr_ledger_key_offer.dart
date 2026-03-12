// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_account_id.dart';
import 'xdr_data_io.dart';
import 'xdr_ledger_key_offer_base.dart';
import 'xdr_uint64.dart';

class XdrLedgerKeyOffer extends XdrLedgerKeyOfferBase {
  XdrLedgerKeyOffer(super.sellerID, super.offerID);

  static void encode(XdrDataOutputStream stream, XdrLedgerKeyOffer val) {
    XdrLedgerKeyOfferBase.encode(stream, val);
  }

  static XdrLedgerKeyOffer decode(XdrDataInputStream stream) {
    var b = XdrLedgerKeyOfferBase.decode(stream);
    return XdrLedgerKeyOffer(b.sellerID, b.offerID);
  }

  static XdrLedgerKeyOffer fromTxRep(Map<String, String> map, String prefix) {
    var b = XdrLedgerKeyOfferBase.fromTxRep(map, prefix);
    return XdrLedgerKeyOffer(b.sellerID, b.offerID);
  }

  static XdrLedgerKeyOffer forOfferId(String sellerAccountId, int offerId) {
    return XdrLedgerKeyOffer(
      XdrAccountID.forAccountId(sellerAccountId),
      XdrUint64(BigInt.from(offerId)),
    );
  }
}
