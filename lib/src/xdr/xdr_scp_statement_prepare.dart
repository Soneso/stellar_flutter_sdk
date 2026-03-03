// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_hash.dart';
import 'xdr_scp_ballot.dart';
import 'xdr_uint32.dart';

class XdrSCPStatementPrepare {
  XdrHash _quorumSetHash;
  XdrHash get quorumSetHash => this._quorumSetHash;
  set quorumSetHash(XdrHash value) => this._quorumSetHash = value;

  XdrSCPBallot _ballot;
  XdrSCPBallot get ballot => this._ballot;
  set ballot(XdrSCPBallot value) => this._ballot = value;

  XdrSCPBallot? _prepared;
  XdrSCPBallot? get prepared => this._prepared;
  set prepared(XdrSCPBallot? value) => this._prepared = value;

  XdrSCPBallot? _preparedPrime;
  XdrSCPBallot? get preparedPrime => this._preparedPrime;
  set preparedPrime(XdrSCPBallot? value) => this._preparedPrime = value;

  XdrUint32 _nC;
  XdrUint32 get nC => this._nC;
  set nC(XdrUint32 value) => this._nC = value;

  XdrUint32 _nH;
  XdrUint32 get nH => this._nH;
  set nH(XdrUint32 value) => this._nH = value;

  XdrSCPStatementPrepare(
    this._quorumSetHash,
    this._ballot,
    this._prepared,
    this._preparedPrime,
    this._nC,
    this._nH,
  );

  static void encode(
    XdrDataOutputStream stream,
    XdrSCPStatementPrepare encodedSCPStatementPrepare,
  ) {
    XdrHash.encode(stream, encodedSCPStatementPrepare.quorumSetHash);
    XdrSCPBallot.encode(stream, encodedSCPStatementPrepare.ballot);
    if (encodedSCPStatementPrepare.prepared != null) {
      stream.writeInt(1);
      XdrSCPBallot.encode(stream, encodedSCPStatementPrepare.prepared!);
    } else {
      stream.writeInt(0);
    }
    if (encodedSCPStatementPrepare.preparedPrime != null) {
      stream.writeInt(1);
      XdrSCPBallot.encode(stream, encodedSCPStatementPrepare.preparedPrime!);
    } else {
      stream.writeInt(0);
    }
    XdrUint32.encode(stream, encodedSCPStatementPrepare.nC);
    XdrUint32.encode(stream, encodedSCPStatementPrepare.nH);
  }

  static XdrSCPStatementPrepare decode(XdrDataInputStream stream) {
    XdrHash quorumSetHash = XdrHash.decode(stream);
    XdrSCPBallot ballot = XdrSCPBallot.decode(stream);
    XdrSCPBallot? prepared;
    int preparedPresent = stream.readInt();
    if (preparedPresent != 0) {
      prepared = XdrSCPBallot.decode(stream);
    }
    XdrSCPBallot? preparedPrime;
    int preparedPrimePresent = stream.readInt();
    if (preparedPrimePresent != 0) {
      preparedPrime = XdrSCPBallot.decode(stream);
    }
    XdrUint32 nC = XdrUint32.decode(stream);
    XdrUint32 nH = XdrUint32.decode(stream);
    return XdrSCPStatementPrepare(
      quorumSetHash,
      ballot,
      prepared,
      preparedPrime,
      nC,
      nH,
    );
  }
}
