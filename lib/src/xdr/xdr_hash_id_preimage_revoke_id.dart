// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_account_id.dart';
import 'xdr_asset.dart';
import 'xdr_data_io.dart';
import 'xdr_hash.dart';
import 'xdr_sequence_number.dart';
import 'xdr_uint32.dart';

class XdrHashIDPreimageRevokeID {
  XdrAccountID _sourceAccount;
  XdrAccountID get sourceAccount => this._sourceAccount;
  set sourceAccount(XdrAccountID value) => this._sourceAccount = value;

  XdrSequenceNumber _seqNum;
  XdrSequenceNumber get seqNum => this._seqNum;
  set seqNum(XdrSequenceNumber value) => this._seqNum = value;

  XdrUint32 _opNum;
  XdrUint32 get opNum => this._opNum;
  set opNum(XdrUint32 value) => this._opNum = value;

  XdrHash _liquidityPoolID;
  XdrHash get liquidityPoolID => this._liquidityPoolID;
  set liquidityPoolID(XdrHash value) => this._liquidityPoolID = value;

  XdrAsset _asset;
  XdrAsset get asset => this._asset;
  set asset(XdrAsset value) => this._asset = value;

  XdrHashIDPreimageRevokeID(
    this._sourceAccount,
    this._seqNum,
    this._opNum,
    this._liquidityPoolID,
    this._asset,
  );

  static void encode(
    XdrDataOutputStream stream,
    XdrHashIDPreimageRevokeID encodedHashIDPreimageRevokeID,
  ) {
    XdrAccountID.encode(stream, encodedHashIDPreimageRevokeID.sourceAccount);
    XdrSequenceNumber.encode(stream, encodedHashIDPreimageRevokeID.seqNum);
    XdrUint32.encode(stream, encodedHashIDPreimageRevokeID.opNum);
    XdrHash.encode(stream, encodedHashIDPreimageRevokeID.liquidityPoolID);
    XdrAsset.encode(stream, encodedHashIDPreimageRevokeID.asset);
  }

  static XdrHashIDPreimageRevokeID decode(XdrDataInputStream stream) {
    XdrAccountID sourceAccount = XdrAccountID.decode(stream);
    XdrSequenceNumber seqNum = XdrSequenceNumber.decode(stream);
    XdrUint32 opNum = XdrUint32.decode(stream);
    XdrHash liquidityPoolID = XdrHash.decode(stream);
    XdrAsset asset = XdrAsset.decode(stream);
    return XdrHashIDPreimageRevokeID(
      sourceAccount,
      seqNum,
      opNum,
      liquidityPoolID,
      asset,
    );
  }
}
