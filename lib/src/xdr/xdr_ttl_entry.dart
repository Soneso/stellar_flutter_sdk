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

  static void encode(XdrDataOutputStream stream, XdrTTLEntry encodedTTLEntry) {
    XdrHash.encode(stream, encodedTTLEntry.keyHash);
    XdrUint32.encode(stream, encodedTTLEntry.liveUntilLedgerSeq);
  }

  static XdrTTLEntry decode(XdrDataInputStream stream) {
    XdrHash keyHash = XdrHash.decode(stream);
    XdrUint32 liveUntilLedgerSeq = XdrUint32.decode(stream);
    return XdrTTLEntry(keyHash, liveUntilLedgerSeq);
  }
}
