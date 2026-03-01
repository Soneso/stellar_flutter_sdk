// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_hash.dart';
import 'xdr_liquidity_pool_body.dart';

class XdrLiquidityPoolEntry {
  XdrLiquidityPoolEntry(this._liquidityPoolID, this._body);

  XdrHash _liquidityPoolID;
  XdrHash get liquidityPoolID => this._liquidityPoolID;
  set liquidityPoolID(XdrHash value) => this._liquidityPoolID = value;

  XdrLiquidityPoolBody _body;
  XdrLiquidityPoolBody get body => this._body;
  set body(XdrLiquidityPoolBody value) => this._body = value;

  static void encode(
      XdrDataOutputStream stream, XdrLiquidityPoolEntry encoded) {
    XdrHash.encode(stream, encoded.liquidityPoolID);
    XdrLiquidityPoolBody.encode(stream, encoded.body);
  }

  static XdrLiquidityPoolEntry decode(XdrDataInputStream stream) {
    return XdrLiquidityPoolEntry(
        XdrHash.decode(stream), XdrLiquidityPoolBody.decode(stream));
  }
}
