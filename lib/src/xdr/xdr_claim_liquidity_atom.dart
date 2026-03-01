// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_asset.dart';
import 'xdr_data_io.dart';
import 'xdr_hash.dart';
import 'xdr_int64.dart';

class XdrClaimLiquidityAtom {
  XdrClaimLiquidityAtom(
    this._liquidityPoolID,
    this._assetSold,
    this._amountSold,
    this._assetBought,
    this._amountBought,
  );
  XdrHash _liquidityPoolID;
  XdrHash get liquidityPoolID => this._liquidityPoolID;
  set liquidityPoolID(XdrHash value) => this._liquidityPoolID = value;

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
    XdrClaimLiquidityAtom encodedC,
  ) {
    XdrHash.encode(stream, encodedC.liquidityPoolID);
    XdrAsset.encode(stream, encodedC.assetSold);
    XdrInt64.encode(stream, encodedC.amountSold);
    XdrAsset.encode(stream, encodedC.assetBought);
    XdrInt64.encode(stream, encodedC.amountBought);
  }

  static XdrClaimLiquidityAtom decode(XdrDataInputStream stream) {
    XdrHash liquidityPoolID = XdrHash.decode(stream);
    XdrAsset assetSold = XdrAsset.decode(stream);
    XdrInt64 amountSold = XdrInt64.decode(stream);
    XdrAsset assetBought = XdrAsset.decode(stream);
    XdrInt64 amountBought = XdrInt64.decode(stream);
    return XdrClaimLiquidityAtom(
      liquidityPoolID,
      assetSold,
      amountSold,
      assetBought,
      amountBought,
    );
  }
}
