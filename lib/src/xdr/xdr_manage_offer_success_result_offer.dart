// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_manage_offer_effect.dart';
import 'xdr_offer_entry.dart';

class XdrManageOfferSuccessResultOffer {
  XdrManageOfferEffect _effect;
  XdrManageOfferEffect get discriminant => this._effect;
  set discriminant(XdrManageOfferEffect value) => this._effect = value;

  XdrOfferEntry? _offer;
  XdrOfferEntry? get offer => this._offer;
  set offer(XdrOfferEntry? value) => this._offer = value;

  XdrManageOfferSuccessResultOffer(this._effect, this._offer);

  static void encode(
    XdrDataOutputStream stream,
    XdrManageOfferSuccessResultOffer encodedManageOfferSuccessResultOffer,
  ) {
    stream.writeInt(encodedManageOfferSuccessResultOffer.discriminant.value);
    switch (encodedManageOfferSuccessResultOffer.discriminant) {
      case XdrManageOfferEffect.MANAGE_OFFER_CREATED:
      case XdrManageOfferEffect.MANAGE_OFFER_UPDATED:
        XdrOfferEntry.encode(
          stream,
          encodedManageOfferSuccessResultOffer.offer!,
        );
        break;
      default:
        break;
    }
  }

  static XdrManageOfferSuccessResultOffer decode(XdrDataInputStream stream) {
    XdrManageOfferSuccessResultOffer decodedManageOfferSuccessResultOffer =
        XdrManageOfferSuccessResultOffer(
          XdrManageOfferEffect.decode(stream),
          null,
        );

    switch (decodedManageOfferSuccessResultOffer.discriminant) {
      case XdrManageOfferEffect.MANAGE_OFFER_CREATED:
      case XdrManageOfferEffect.MANAGE_OFFER_UPDATED:
        decodedManageOfferSuccessResultOffer.offer = XdrOfferEntry.decode(
          stream,
        );
        break;
      default:
        break;
    }
    return decodedManageOfferSuccessResultOffer;
  }
}
