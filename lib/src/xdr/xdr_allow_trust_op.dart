// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_account_id.dart';
import 'xdr_allow_trust_op_asset.dart';
import 'xdr_data_io.dart';

class XdrAllowTrustOp {
  XdrAllowTrustOp(this._trustor, this._asset, this._authorize);

  XdrAccountID _trustor;
  XdrAccountID get trustor => this._trustor;
  set trustor(XdrAccountID value) => this._trustor = value;

  XdrAllowTrustOpAsset _asset;
  XdrAllowTrustOpAsset get asset => this._asset;
  set asset(XdrAllowTrustOpAsset value) => this._asset = value;

  int _authorize;
  int get authorize => this._authorize;
  set authorize(int value) => this._authorize = value;

  static void encode(
      XdrDataOutputStream stream, XdrAllowTrustOp encodedAllowTrustOp) {
    XdrAccountID.encode(stream, encodedAllowTrustOp.trustor);
    XdrAllowTrustOpAsset.encode(stream, encodedAllowTrustOp.asset);
    stream.writeInt(encodedAllowTrustOp.authorize);
  }

  static XdrAllowTrustOp decode(XdrDataInputStream stream) {
    XdrAccountID trustor = XdrAccountID.decode(stream);
    XdrAllowTrustOpAsset asset = XdrAllowTrustOpAsset.decode(stream);
    return XdrAllowTrustOp(trustor, asset, stream.readInt());
  }
}
