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

  XdrManageOfferSuccessResultOffer(this._effect);

  set offer(XdrOfferEntry? value) => this._offer = value;

  static void encode(XdrDataOutputStream stream, XdrManageOfferSuccessResultOffer encodedManageOfferSuccessResultOffer) {
    stream.writeInt(encodedManageOfferSuccessResultOffer.discriminant.value);
    switch (encodedManageOfferSuccessResultOffer.discriminant) {
      case XdrManageOfferEffect.MANAGE_OFFER_CREATED:
      case XdrManageOfferEffect.MANAGE_OFFER_UPDATED:
        XdrOfferEntry.encode(stream, encodedManageOfferSuccessResultOffer._offer!);
        break;
      case XdrManageOfferEffect.MANAGE_OFFER_DELETED:
        break;
      default:
        break;
    }
  }

  static XdrManageOfferSuccessResultOffer decode(XdrDataInputStream stream) {
    XdrManageOfferSuccessResultOffer decodedManageOfferSuccessResultOffer = XdrManageOfferSuccessResultOffer(XdrManageOfferEffect.decode(stream));
    switch (decodedManageOfferSuccessResultOffer.discriminant) {
      case XdrManageOfferEffect.MANAGE_OFFER_CREATED:
      case XdrManageOfferEffect.MANAGE_OFFER_UPDATED:
        decodedManageOfferSuccessResultOffer._offer = XdrOfferEntry.decode(stream);
        break;
      case XdrManageOfferEffect.MANAGE_OFFER_DELETED:
        break;
      default:
        break;
    }
    return decodedManageOfferSuccessResultOffer;
  }
}
