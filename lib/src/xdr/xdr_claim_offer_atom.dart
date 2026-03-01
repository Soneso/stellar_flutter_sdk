// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_account_id.dart';
import 'xdr_asset.dart';
import 'xdr_data_io.dart';
import 'xdr_int64.dart';
import 'xdr_uint64.dart';

class XdrClaimOfferAtom {
  XdrClaimOfferAtom(
    this._sellerID,
    this._offerID,
    this._assetSold,
    this._amountSold,
    this._assetBought,
    this._amountBought,
  );
  XdrAccountID _sellerID;
  XdrAccountID get sellerID => this._sellerID;
  set sellerID(XdrAccountID value) => this._sellerID = value;

  XdrUint64 _offerID;
  XdrUint64 get offerID => this._offerID;
  set offerID(XdrUint64 value) => this._offerID = value;

  XdrAsset _assetSold;
  XdrAsset get assetSold => this._assetSold;
  set assetSold(XdrAsset value) => this._assetSold = value;

  XdrInt64 _amountSold;
  XdrInt64 get amountSold => this._amountSold;
  set amountSold(XdrInt64 value) => this._amountSold = value;

  XdrAsset _assetBought;
  XdrAsset get assetBought => this._assetBought;
  set assetBought(XdrAsset value) => this._assetBought = value;

  XdrInt64 _amountBought;
  XdrInt64 get amountBought => this._amountBought;
  set amountBought(XdrInt64 value) => this._amountBought = value;

  static void encode(
    XdrDataOutputStream stream,
    XdrClaimOfferAtom encodedClaimOfferAtom,
  ) {
    XdrAccountID.encode(stream, encodedClaimOfferAtom.sellerID);
    XdrUint64.encode(stream, encodedClaimOfferAtom.offerID);
    XdrAsset.encode(stream, encodedClaimOfferAtom.assetSold);
    XdrInt64.encode(stream, encodedClaimOfferAtom.amountSold);
    XdrAsset.encode(stream, encodedClaimOfferAtom.assetBought);
    XdrInt64.encode(stream, encodedClaimOfferAtom.amountBought);
  }

  static XdrClaimOfferAtom decode(XdrDataInputStream stream) {
    XdrAccountID sellerID = XdrAccountID.decode(stream);
    XdrUint64 offerID = XdrUint64.decode(stream);
    XdrAsset assetSold = XdrAsset.decode(stream);
    XdrInt64 amountSold = XdrInt64.decode(stream);
    XdrAsset assetBought = XdrAsset.decode(stream);
    XdrInt64 amountBought = XdrInt64.decode(stream);
    return XdrClaimOfferAtom(
      sellerID,
      offerID,
      assetSold,
      amountSold,
      assetBought,
      amountBought,
    );
  }
}
