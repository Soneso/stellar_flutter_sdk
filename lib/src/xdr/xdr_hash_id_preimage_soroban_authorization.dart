// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_hash.dart';
import 'xdr_int64.dart';
import 'xdr_soroban_authorized_invocation.dart';
import 'xdr_uint32.dart';

class XdrHashIDPreimageSorobanAuthorization {
  XdrHash _networkID;
  XdrHash get networkID => this._networkID;
  set networkID(XdrHash value) => this._networkID = value;

  XdrInt64 _nonce;
  XdrInt64 get nonce => this._nonce;
  set nonce(XdrInt64 value) => this._nonce = value;

  XdrUint32 _signatureExpirationLedger;
  XdrUint32 get signatureExpirationLedger => this._signatureExpirationLedger;
  set signatureExpirationLedger(XdrUint32 value) =>
      this._signatureExpirationLedger = value;

  XdrSorobanAuthorizedInvocation _invocation;
  XdrSorobanAuthorizedInvocation get invocation => this._invocation;
  set invocation(XdrSorobanAuthorizedInvocation value) =>
      this._invocation = value;

  XdrHashIDPreimageSorobanAuthorization(this._networkID, this._nonce,
      this._signatureExpirationLedger, this._invocation);

  static void encode(XdrDataOutputStream stream,
      XdrHashIDPreimageSorobanAuthorization encoded) {
    XdrHash.encode(stream, encoded.networkID);
    XdrInt64.encode(stream, encoded.nonce);
    XdrUint32.encode(stream, encoded.signatureExpirationLedger);
    XdrSorobanAuthorizedInvocation.encode(stream, encoded.invocation);
  }

  static XdrHashIDPreimageSorobanAuthorization decode(
      XdrDataInputStream stream) {
    XdrHash networkID = XdrHash.decode(stream);
    XdrInt64 nonce = XdrInt64.decode(stream);
    XdrUint32 signatureExpirationLedger = XdrUint32.decode(stream);
    XdrSorobanAuthorizedInvocation invocation =
        XdrSorobanAuthorizedInvocation.decode(stream);
    return XdrHashIDPreimageSorobanAuthorization(
        networkID, nonce, signatureExpirationLedger, invocation);
  }
}
