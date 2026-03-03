// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_hash.dart';
import 'xdr_scp_ballot.dart';
import 'xdr_uint32.dart';

class XdrSCPStatementExternalize {
  XdrSCPBallot _commit;
  XdrSCPBallot get commit => this._commit;
  set commit(XdrSCPBallot value) => this._commit = value;

  XdrUint32 _nH;
  XdrUint32 get nH => this._nH;
  set nH(XdrUint32 value) => this._nH = value;

  XdrHash _commitQuorumSetHash;
  XdrHash get commitQuorumSetHash => this._commitQuorumSetHash;
  set commitQuorumSetHash(XdrHash value) => this._commitQuorumSetHash = value;

  XdrSCPStatementExternalize(this._commit, this._nH, this._commitQuorumSetHash);

  static void encode(
    XdrDataOutputStream stream,
    XdrSCPStatementExternalize encodedSCPStatementExternalize,
  ) {
    XdrSCPBallot.encode(stream, encodedSCPStatementExternalize.commit);
    XdrUint32.encode(stream, encodedSCPStatementExternalize.nH);
    XdrHash.encode(stream, encodedSCPStatementExternalize.commitQuorumSetHash);
  }

  static XdrSCPStatementExternalize decode(XdrDataInputStream stream) {
    XdrSCPBallot commit = XdrSCPBallot.decode(stream);
    XdrUint32 nH = XdrUint32.decode(stream);
    XdrHash commitQuorumSetHash = XdrHash.decode(stream);
    return XdrSCPStatementExternalize(commit, nH, commitQuorumSetHash);
  }
}
