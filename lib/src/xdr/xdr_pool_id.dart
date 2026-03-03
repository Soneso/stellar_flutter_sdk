// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_hash.dart';

class XdrPoolID {
  XdrPoolID(this._poolID);

  XdrHash _poolID;
  XdrHash get poolID => this._poolID;
  set poolID(XdrHash value) => this._poolID = value;

  static void encode(XdrDataOutputStream stream, XdrPoolID encodedPoolID) {
    XdrHash.encode(stream, encodedPoolID.poolID);
  }

  static XdrPoolID decode(XdrDataInputStream stream) {
    return XdrPoolID(XdrHash.decode(stream));
  }
}
