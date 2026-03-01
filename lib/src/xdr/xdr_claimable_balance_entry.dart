// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_asset.dart';
import 'xdr_claimable_balance_entry_ext.dart';
import 'xdr_claimable_balance_id.dart';
import 'xdr_claimant.dart';
import 'xdr_data_io.dart';
import 'xdr_int64.dart';

class XdrClaimableBalanceEntry {
  XdrClaimableBalanceID _balanceID;

  XdrClaimableBalanceID get balanceID => this._balanceID;

  set balanceID(XdrClaimableBalanceID value) => this._balanceID = value;

  List<XdrClaimant> _claimants;

  List<XdrClaimant> get claimants => this._claimants;

  set claimants(List<XdrClaimant> value) => this._claimants = value;

  XdrAsset _asset;

  XdrAsset get asset => this._asset;

  set asset(XdrAsset value) => this._asset = value;

  XdrInt64 _amount;

  XdrInt64 get amount => this._amount;

  set amount(XdrInt64 value) => this._amount = value;

  XdrClaimableBalanceEntryExt _ext;

  XdrClaimableBalanceEntryExt get ext => this._ext;

  set ext(XdrClaimableBalanceEntryExt value) => this._ext = value;

  XdrClaimableBalanceEntry(
      this._balanceID, this._claimants, this._asset, this._amount, this._ext);

  static void encode(
      XdrDataOutputStream stream, XdrClaimableBalanceEntry encoded) {
    XdrClaimableBalanceID.encode(stream, encoded.balanceID);
    int pSize = encoded.claimants.length;
    stream.writeInt(pSize);
    for (int i = 0; i < pSize; i++) {
      XdrClaimant.encode(stream, encoded.claimants[i]);
    }
    XdrAsset.encode(stream, encoded.asset);
    XdrInt64.encode(stream, encoded.amount);
    XdrClaimableBalanceEntryExt.encode(stream, encoded.ext);
  }

  static XdrClaimableBalanceEntry decode(XdrDataInputStream stream) {
    XdrClaimableBalanceID xBalanceID = XdrClaimableBalanceID.decode(stream);
    int pSize = stream.readInt();
    List<XdrClaimant> xClaimants = List<XdrClaimant>.empty(growable: true);
    for (int i = 0; i < pSize; i++) {
      xClaimants.add(XdrClaimant.decode(stream));
    }
    XdrAsset xAsset = XdrAsset.decode(stream);
    XdrInt64 xAmount = XdrInt64.decode(stream);
    XdrClaimableBalanceEntryExt xExt =
        XdrClaimableBalanceEntryExt.decode(stream);

    return XdrClaimableBalanceEntry(
        xBalanceID, xClaimants, xAsset, xAmount, xExt);
  }
}
