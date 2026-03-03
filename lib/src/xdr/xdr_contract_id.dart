// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_hash.dart';

class XdrContractID {
  XdrContractID(this._contractID);

  XdrHash _contractID;
  XdrHash get contractID => this._contractID;
  set contractID(XdrHash value) => this._contractID = value;

  static void encode(
    XdrDataOutputStream stream,
    XdrContractID encodedContractID,
  ) {
    XdrHash.encode(stream, encodedContractID.contractID);
  }

  static XdrContractID decode(XdrDataInputStream stream) {
    return XdrContractID(XdrHash.decode(stream));
  }
}
