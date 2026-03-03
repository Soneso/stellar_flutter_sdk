// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_asset.dart';
import 'xdr_big_int64.dart';
import 'xdr_data_io.dart';
import 'xdr_muxed_account.dart';

class XdrClawbackOp {
  XdrAsset _asset;
  XdrAsset get asset => this._asset;
  set asset(XdrAsset value) => this._asset = value;

  XdrMuxedAccount _from;
  XdrMuxedAccount get from => this._from;
  set from(XdrMuxedAccount value) => this._from = value;

  XdrBigInt64 _amount;
  XdrBigInt64 get amount => this._amount;
  set amount(XdrBigInt64 value) => this._amount = value;

  XdrClawbackOp(this._asset, this._from, this._amount);

  static void encode(
    XdrDataOutputStream stream,
    XdrClawbackOp encodedClawbackOp,
  ) {
    XdrAsset.encode(stream, encodedClawbackOp.asset);
    XdrMuxedAccount.encode(stream, encodedClawbackOp.from);
    XdrBigInt64.encode(stream, encodedClawbackOp.amount);
  }

  static XdrClawbackOp decode(XdrDataInputStream stream) {
    XdrAsset asset = XdrAsset.decode(stream);
    XdrMuxedAccount from = XdrMuxedAccount.decode(stream);
    XdrBigInt64 amount = XdrBigInt64.decode(stream);
    return XdrClawbackOp(asset, from, amount);
  }
}
