// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_hash.dart';

class XdrConfigUpgradeSetKey {
  XdrConfigUpgradeSetKey(this._contractID, this._contentHash);

  XdrHash _contractID;
  XdrHash get contractID => this._contractID;
  set contractID(XdrHash value) => this._contractID = value;

  XdrHash _contentHash;
  XdrHash get contentHash => this._contentHash;
  set contentHash(XdrHash value) => this._contentHash = value;

  static void encode(
    XdrDataOutputStream stream,
    XdrConfigUpgradeSetKey encoded,
  ) {
    XdrHash.encode(stream, encoded.contractID);
    XdrHash.encode(stream, encoded.contentHash);
  }

  static XdrConfigUpgradeSetKey decode(XdrDataInputStream stream) {
    return XdrConfigUpgradeSetKey(
      XdrHash.decode(stream),
      XdrHash.decode(stream),
    );
  }
}
