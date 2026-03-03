// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_hash.dart';

class XdrConfigUpgradeSetKey {

  XdrHash _contractID;
  XdrHash get contractID => this._contractID;
  set contractID(XdrHash value) => this._contractID = value;

  XdrHash _contentHash;
  XdrHash get contentHash => this._contentHash;
  set contentHash(XdrHash value) => this._contentHash = value;

  XdrConfigUpgradeSetKey(this._contractID, this._contentHash);

  static void encode(XdrDataOutputStream stream, XdrConfigUpgradeSetKey encodedConfigUpgradeSetKey) {
    XdrHash.encode(stream, encodedConfigUpgradeSetKey.contractID);
    XdrHash.encode(stream, encodedConfigUpgradeSetKey.contentHash);
  }

  static XdrConfigUpgradeSetKey decode(XdrDataInputStream stream) {
    XdrHash contractID = XdrHash.decode(stream);
    XdrHash contentHash = XdrHash.decode(stream);
    return XdrConfigUpgradeSetKey(contractID, contentHash);
  }
}
