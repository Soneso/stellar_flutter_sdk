// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_contract_id.dart';
import 'xdr_data_io.dart';
import 'xdr_hash.dart';

class XdrConfigUpgradeSetKey {

  XdrContractID _contractID;
  XdrContractID get contractID => this._contractID;
  set contractID(XdrContractID value) => this._contractID = value;

  XdrHash _contentHash;
  XdrHash get contentHash => this._contentHash;
  set contentHash(XdrHash value) => this._contentHash = value;

  XdrConfigUpgradeSetKey(this._contractID, this._contentHash);

  static void encode(XdrDataOutputStream stream, XdrConfigUpgradeSetKey encodedConfigUpgradeSetKey) {
    XdrContractID.encode(stream, encodedConfigUpgradeSetKey.contractID);
    XdrHash.encode(stream, encodedConfigUpgradeSetKey.contentHash);
  }

  static XdrConfigUpgradeSetKey decode(XdrDataInputStream stream) {
    XdrContractID contractID = XdrContractID.decode(stream);
    XdrHash contentHash = XdrHash.decode(stream);
    return XdrConfigUpgradeSetKey(contractID, contentHash);
  }
}
