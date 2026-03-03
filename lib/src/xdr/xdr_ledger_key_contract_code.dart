// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_hash.dart';

class XdrLedgerKeyContractCode {
  XdrHash _hash;
  XdrHash get hash => this._hash;
  set hash(XdrHash value) => this._hash = value;

  XdrLedgerKeyContractCode(this._hash);

  static void encode(
    XdrDataOutputStream stream,
    XdrLedgerKeyContractCode encodedLedgerKeyContractCode,
  ) {
    XdrHash.encode(stream, encodedLedgerKeyContractCode.hash);
  }

  static XdrLedgerKeyContractCode decode(XdrDataInputStream stream) {
    XdrHash hash = XdrHash.decode(stream);
    return XdrLedgerKeyContractCode(hash);
  }
}
