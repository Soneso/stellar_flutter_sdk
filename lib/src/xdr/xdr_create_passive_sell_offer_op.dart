// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_asset.dart';
import 'xdr_big_int64.dart';
import 'xdr_data_io.dart';
import 'xdr_price.dart';

class XdrCreatePassiveSellOfferOp {
  XdrCreatePassiveSellOfferOp(
      this._selling, this._buying, this._amount, this._price);

  XdrAsset _selling;
  XdrAsset get selling => this._selling;
  set selling(XdrAsset value) => this._selling = value;

  XdrAsset _buying;
  XdrAsset get buying => this._buying;
  set buying(XdrAsset value) => this._buying = value;

  XdrBigInt64 _amount;
  XdrBigInt64 get amount => this._amount;
  set amount(XdrBigInt64 value) => this._amount = value;

  XdrPrice _price;
  XdrPrice get price => this._price;
  set price(XdrPrice value) => this._price = value;

  static void encode(XdrDataOutputStream stream,
      XdrCreatePassiveSellOfferOp encodedCreatePassiveOfferOp) {
    XdrAsset.encode(stream, encodedCreatePassiveOfferOp.selling);
    XdrAsset.encode(stream, encodedCreatePassiveOfferOp.buying);
    XdrBigInt64.encode(stream, encodedCreatePassiveOfferOp.amount);
    XdrPrice.encode(stream, encodedCreatePassiveOfferOp.price);
  }

  static XdrCreatePassiveSellOfferOp decode(XdrDataInputStream stream) {
    return XdrCreatePassiveSellOfferOp(
        XdrAsset.decode(stream),
        XdrAsset.decode(stream),
        XdrBigInt64.decode(stream),
        XdrPrice.decode(stream));
  }
}
