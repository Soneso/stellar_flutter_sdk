// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_hash.dart';
import 'xdr_scp_ballot.dart';
import 'xdr_uint32.dart';

class XdrSCPStatementConfirm {
  XdrSCPStatementConfirm(
    this._ballot,
    this._nPrepared,
    this._nCommit,
    this._nH,
    this._quorumSetHash,
  );
  XdrSCPBallot _ballot;
  XdrSCPBallot get ballot => this._ballot;
  set ballot(XdrSCPBallot value) => this._ballot = value;

  XdrUint32 _nPrepared;
  XdrUint32 get nPrepared => this._nPrepared;
  set nPrepared(XdrUint32 value) => this._nPrepared = value;

  XdrUint32 _nCommit;
  XdrUint32 get nCommit => this._nCommit;
  set nCommit(XdrUint32 value) => this._nCommit = value;

  XdrUint32 _nH;
  XdrUint32 get nH => this._nH;
  set nH(XdrUint32 value) => this._nH = value;

  XdrHash _quorumSetHash;
  XdrHash get quorumSetHash => this._quorumSetHash;
  set quorumSetHash(XdrHash value) => this._quorumSetHash = value;

  static void encode(
    XdrDataOutputStream stream,
    XdrSCPStatementConfirm encodedSCPStatementConfirm,
  ) {
    XdrSCPBallot.encode(stream, encodedSCPStatementConfirm.ballot);
    XdrUint32.encode(stream, encodedSCPStatementConfirm.nPrepared);
    XdrUint32.encode(stream, encodedSCPStatementConfirm.nCommit);
    XdrUint32.encode(stream, encodedSCPStatementConfirm.nH);
    XdrHash.encode(stream, encodedSCPStatementConfirm.quorumSetHash);
  }

  static XdrSCPStatementConfirm decode(XdrDataInputStream stream) {
    XdrSCPBallot ballot = XdrSCPBallot.decode(stream);
    XdrUint32 nPrepared = XdrUint32.decode(stream);
    XdrUint32 nCommit = XdrUint32.decode(stream);
    XdrUint32 nH = XdrUint32.decode(stream);
    XdrHash quorumSetHash = XdrHash.decode(stream);
    return XdrSCPStatementConfirm(
      ballot,
      nPrepared,
      nCommit,
      nH,
      quorumSetHash,
    );
  }
}
