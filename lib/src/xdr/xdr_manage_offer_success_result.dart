// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_claim_atom.dart';
import 'xdr_data_io.dart';
import 'xdr_manage_offer_success_result_offer.dart';

class XdrManageOfferSuccessResult {
  List<XdrClaimAtom> _offersClaimed;
  List<XdrClaimAtom> get offersClaimed => this._offersClaimed;
  set offersClaimed(List<XdrClaimAtom> value) => this._offersClaimed = value;

  XdrManageOfferSuccessResultOffer _offer;
  XdrManageOfferSuccessResultOffer get offer => this._offer;
  set offer(XdrManageOfferSuccessResultOffer value) => this._offer = value;

  XdrManageOfferSuccessResult(this._offersClaimed, this._offer);

  static void encode(
    XdrDataOutputStream stream,
    XdrManageOfferSuccessResult encodedManageOfferSuccessResult,
  ) {
    int offersClaimedsize =
        encodedManageOfferSuccessResult.offersClaimed.length;
    stream.writeInt(offersClaimedsize);
    for (int i = 0; i < offersClaimedsize; i++) {
      XdrClaimAtom.encode(
        stream,
        encodedManageOfferSuccessResult.offersClaimed[i],
      );
    }
    XdrManageOfferSuccessResultOffer.encode(
      stream,
      encodedManageOfferSuccessResult.offer,
    );
  }

  static XdrManageOfferSuccessResult decode(XdrDataInputStream stream) {
    int offersClaimedsize = stream.readInt();
    List<XdrClaimAtom> offersClaimed = List<XdrClaimAtom>.empty(growable: true);
    for (int i = 0; i < offersClaimedsize; i++) {
      offersClaimed.add(XdrClaimAtom.decode(stream));
    }
    XdrManageOfferSuccessResultOffer offer =
        XdrManageOfferSuccessResultOffer.decode(stream);
    return XdrManageOfferSuccessResult(offersClaimed, offer);
  }
}
