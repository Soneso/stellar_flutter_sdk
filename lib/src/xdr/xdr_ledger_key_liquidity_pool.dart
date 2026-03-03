// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_pool_id.dart';

class XdrLedgerKeyLiquidityPool {

  XdrPoolID _liquidityPoolID;
  XdrPoolID get liquidityPoolID => this._liquidityPoolID;
  set liquidityPoolID(XdrPoolID value) => this._liquidityPoolID = value;

  XdrLedgerKeyLiquidityPool(this._liquidityPoolID);

  static void encode(XdrDataOutputStream stream, XdrLedgerKeyLiquidityPool encodedLedgerKeyLiquidityPool) {
    XdrPoolID.encode(stream, encodedLedgerKeyLiquidityPool.liquidityPoolID);
  }

  static XdrLedgerKeyLiquidityPool decode(XdrDataInputStream stream) {
    XdrPoolID liquidityPoolID = XdrPoolID.decode(stream);
    return XdrLedgerKeyLiquidityPool(liquidityPoolID);
  }
}
