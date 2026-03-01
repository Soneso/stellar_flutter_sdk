// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_hash.dart';

class XdrLedgerKeyTTL {
  XdrHash _hashKey;
  XdrHash get hashKey => this._hashKey;
  set hash(XdrHash value) => this._hashKey = value;

  XdrLedgerKeyTTL(this._hashKey);

  static void encode(XdrDataOutputStream stream, XdrLedgerKeyTTL encoded) {
    XdrHash.encode(stream, encoded.hashKey);
  }

  static XdrLedgerKeyTTL decode(XdrDataInputStream stream) {
    XdrLedgerKeyTTL decoded = XdrLedgerKeyTTL(XdrHash.decode(stream));
    return decoded;
  }
}
