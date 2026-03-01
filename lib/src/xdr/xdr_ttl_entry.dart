// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_hash.dart';
import 'xdr_uint32.dart';

class XdrTTLEntry {
  XdrHash _keyHash;
  XdrHash get keyHash => this._keyHash;
  set keyHash(XdrHash value) => this._keyHash = value;

  XdrUint32 _liveUntilLedgerSeq;
  XdrUint32 get liveUntilLedgerSeq => this._liveUntilLedgerSeq;
  set liveUntilLedgerSeq(XdrUint32 value) => this._liveUntilLedgerSeq = value;

  XdrTTLEntry(this._keyHash, this._liveUntilLedgerSeq);

  static void encode(XdrDataOutputStream stream, XdrTTLEntry encoded) {
    XdrHash.encode(stream, encoded.keyHash);
    XdrUint32.encode(stream, encoded.liveUntilLedgerSeq);
  }

  static XdrTTLEntry decode(XdrDataInputStream stream) {
    return XdrTTLEntry(XdrHash.decode(stream), XdrUint32.decode(stream));
  }
}
