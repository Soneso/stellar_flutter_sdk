// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_account_id.dart';
import 'xdr_asset.dart';
import 'xdr_data_io.dart';
import 'xdr_uint32.dart';

class XdrSetTrustLineFlagsOp {
  XdrSetTrustLineFlagsOp(
    this._accountID,
    this._asset,
    this._clearFlags,
    this._setFlags,
  );

  XdrAccountID _accountID;
  XdrAccountID get accountID => this._accountID;
  set accountID(XdrAccountID value) => this._accountID = value;

  XdrAsset _asset;
  XdrAsset get asset => this._asset;
  set asset(XdrAsset value) => this._asset = value;

  XdrUint32 _clearFlags;
  XdrUint32 get clearFlags => this._clearFlags;
  set clearFlags(XdrUint32 value) => this._clearFlags = value;

  XdrUint32 _setFlags;
  XdrUint32 get setFlags => this._setFlags;
  set setFlags(XdrUint32 value) => this._setFlags = value;

  static void encode(
    XdrDataOutputStream stream,
    XdrSetTrustLineFlagsOp encodedSetTrustLineFlagssOp,
  ) {
    XdrAccountID.encode(stream, encodedSetTrustLineFlagssOp.accountID);
    XdrAsset.encode(stream, encodedSetTrustLineFlagssOp.asset);
    XdrUint32.encode(stream, encodedSetTrustLineFlagssOp.clearFlags);
    XdrUint32.encode(stream, encodedSetTrustLineFlagssOp.setFlags);
  }

  static XdrSetTrustLineFlagsOp decode(XdrDataInputStream stream) {
    XdrAccountID accountID = XdrAccountID.decode(stream);
    XdrAsset asset = XdrAsset.decode(stream);
    XdrUint32 clearFlags = XdrUint32.decode(stream);
    XdrUint32 setFlags = XdrUint32.decode(stream);

    return XdrSetTrustLineFlagsOp(accountID, asset, clearFlags, setFlags);
  }
}
