// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_asset.dart';
import 'xdr_big_int64.dart';
import 'xdr_claimant.dart';
import 'xdr_data_io.dart';

class XdrCreateClaimableBalanceOp {
  XdrAsset _asset;

  XdrAsset get asset => this._asset;

  set asset(XdrAsset value) => this._asset = value;

  XdrBigInt64 _amount;

  XdrBigInt64 get amount => this._amount;

  set amount(XdrBigInt64 value) => this._amount = value;

  List<XdrClaimant> _claimants;

  List<XdrClaimant> get claimants => this._claimants;

  set claimants(List<XdrClaimant> value) => this._claimants = value;

  XdrCreateClaimableBalanceOp(this._asset, this._amount, this._claimants);

  static void encode(
      XdrDataOutputStream stream, XdrCreateClaimableBalanceOp encoded) {
    XdrAsset.encode(stream, encoded.asset);
    XdrBigInt64.encode(stream, encoded.amount);
    int pSize = encoded.claimants.length;
    stream.writeInt(pSize);
    for (int i = 0; i < pSize; i++) {
      XdrClaimant.encode(stream, encoded.claimants[i]);
    }
  }

  static XdrCreateClaimableBalanceOp decode(XdrDataInputStream stream) {
    XdrAsset xAsset = XdrAsset.decode(stream);
    XdrBigInt64 xAmount = XdrBigInt64.decode(stream);
    int pSize = stream.readInt();
    List<XdrClaimant> xClaimants = List<XdrClaimant>.empty(growable: true);
    for (int i = 0; i < pSize; i++) {
      xClaimants.add(XdrClaimant.decode(stream));
    }
    return XdrCreateClaimableBalanceOp(xAsset, xAmount, xClaimants);
  }
}
