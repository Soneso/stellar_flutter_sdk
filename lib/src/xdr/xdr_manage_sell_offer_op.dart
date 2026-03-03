// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_asset.dart';
import 'xdr_big_int64.dart';
import 'xdr_data_io.dart';
import 'xdr_price.dart';
import 'xdr_uint64.dart';

class XdrManageSellOfferOp {

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

  XdrUint64 _offerID;
  XdrUint64 get offerID => this._offerID;
  set offerID(XdrUint64 value) => this._offerID = value;

  XdrManageSellOfferOp(this._selling, this._buying, this._amount, this._price, this._offerID);

  static void encode(XdrDataOutputStream stream, XdrManageSellOfferOp encodedManageSellOfferOp) {
    XdrAsset.encode(stream, encodedManageSellOfferOp.selling);
    XdrAsset.encode(stream, encodedManageSellOfferOp.buying);
    XdrBigInt64.encode(stream, encodedManageSellOfferOp.amount);
    XdrPrice.encode(stream, encodedManageSellOfferOp.price);
    XdrUint64.encode(stream, encodedManageSellOfferOp.offerID);
  }

  static XdrManageSellOfferOp decode(XdrDataInputStream stream) {
    XdrAsset selling = XdrAsset.decode(stream);
    XdrAsset buying = XdrAsset.decode(stream);
    XdrBigInt64 amount = XdrBigInt64.decode(stream);
    XdrPrice price = XdrPrice.decode(stream);
    XdrUint64 offerID = XdrUint64.decode(stream);
    return XdrManageSellOfferOp(selling, buying, amount, price, offerID);
  }
}
