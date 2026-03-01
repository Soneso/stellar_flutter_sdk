// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_asset.dart';
import 'xdr_data_io.dart';
import 'xdr_int32.dart';

class XdrLiquidityPoolConstantProductParameters {
  XdrLiquidityPoolConstantProductParameters(
      this._assetA, this._assetB, this._fee);

  XdrAsset _assetA;
  XdrAsset get assetA => this._assetA;
  set assetA(XdrAsset value) => this._assetA = value;

  XdrAsset _assetB;
  XdrAsset get assetB => this._assetB;
  set assetB(XdrAsset value) => this._assetB = value;

  XdrInt32 _fee;
  XdrInt32 get fee => this._fee;
  set fee(XdrInt32 value) => this._fee = value;

  static XdrInt32 LIQUIDITY_POOL_FEE_V18 = XdrInt32(30);

  static void encode(XdrDataOutputStream stream,
      XdrLiquidityPoolConstantProductParameters params) {
    XdrAsset.encode(stream, params.assetA);
    XdrAsset.encode(stream, params.assetB);
    XdrInt32.encode(stream, params.fee);
  }

  static XdrLiquidityPoolConstantProductParameters decode(
      XdrDataInputStream stream) {
    XdrAsset assetA = XdrAsset.decode(stream);
    XdrAsset assetB = XdrAsset.decode(stream);
    XdrInt32 fee = XdrInt32.decode(stream);
    return XdrLiquidityPoolConstantProductParameters(assetA, assetB, fee);
  }
}
