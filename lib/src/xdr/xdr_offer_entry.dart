// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_account_id.dart';
import 'xdr_asset.dart';
import 'xdr_data_io.dart';
import 'xdr_int64.dart';
import 'xdr_offer_entry_ext.dart';
import 'xdr_price.dart';
import 'xdr_uint32.dart';
import 'xdr_uint64.dart';

class XdrOfferEntry {
  XdrAccountID _sellerID;
  XdrAccountID get sellerID => this._sellerID;
  set sellerID(XdrAccountID value) => this._sellerID = value;

  XdrUint64 _offerID;
  XdrUint64 get offerID => this._offerID;
  set offerID(XdrUint64 value) => this._offerID = value;

  XdrAsset _selling;
  XdrAsset get selling => this._selling;
  set selling(XdrAsset value) => this._selling = value;

  XdrAsset _buying;
  XdrAsset get buying => this._buying;
  set buying(XdrAsset value) => this._buying = value;

  XdrInt64 _amount;
  XdrInt64 get amount => this._amount;
  set amount(XdrInt64 value) => this._amount = value;

  XdrPrice _price;
  XdrPrice get price => this._price;
  set price(XdrPrice value) => this._price = value;

  XdrUint32 _flags;
  XdrUint32 get flags => this._flags;
  set flags(XdrUint32 value) => this._flags = value;

  XdrOfferEntryExt _ext;
  XdrOfferEntryExt get ext => this._ext;
  set ext(XdrOfferEntryExt value) => this._ext = value;

  XdrOfferEntry(
    this._sellerID,
    this._offerID,
    this._selling,
    this._buying,
    this._amount,
    this._price,
    this._flags,
    this._ext,
  );

  static void encode(
    XdrDataOutputStream stream,
    XdrOfferEntry encodedOfferEntry,
  ) {
    XdrAccountID.encode(stream, encodedOfferEntry.sellerID);
    XdrUint64.encode(stream, encodedOfferEntry.offerID);
    XdrAsset.encode(stream, encodedOfferEntry.selling);
    XdrAsset.encode(stream, encodedOfferEntry.buying);
    XdrInt64.encode(stream, encodedOfferEntry.amount);
    XdrPrice.encode(stream, encodedOfferEntry.price);
    XdrUint32.encode(stream, encodedOfferEntry.flags);
    XdrOfferEntryExt.encode(stream, encodedOfferEntry.ext);
  }

  static XdrOfferEntry decode(XdrDataInputStream stream) {
    XdrAccountID sellerID = XdrAccountID.decode(stream);
    XdrUint64 offerID = XdrUint64.decode(stream);
    XdrAsset selling = XdrAsset.decode(stream);
    XdrAsset buying = XdrAsset.decode(stream);
    XdrInt64 amount = XdrInt64.decode(stream);
    XdrPrice price = XdrPrice.decode(stream);
    XdrUint32 flags = XdrUint32.decode(stream);
    XdrOfferEntryExt ext = XdrOfferEntryExt.decode(stream);
    return XdrOfferEntry(
      sellerID,
      offerID,
      selling,
      buying,
      amount,
      price,
      flags,
      ext,
    );
  }
}
