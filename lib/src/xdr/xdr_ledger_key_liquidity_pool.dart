// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_hash.dart';

class XdrLedgerKeyLiquidityPool {
  XdrHash _liquidityPoolID;
  XdrHash get liquidityPoolID => this._liquidityPoolID;
  set liquidityPoolID(XdrHash value) => this._liquidityPoolID = value;

  XdrLedgerKeyLiquidityPool(this._liquidityPoolID);

  static void encode(
    XdrDataOutputStream stream,
    XdrLedgerKeyLiquidityPool encodedLedgerKeyLiquidityPool,
  ) {
    XdrHash.encode(stream, encodedLedgerKeyLiquidityPool.liquidityPoolID);
  }

  static XdrLedgerKeyLiquidityPool decode(XdrDataInputStream stream) {
    XdrHash liquidityPoolID = XdrHash.decode(stream);
    return XdrLedgerKeyLiquidityPool(liquidityPoolID);
  }
}
