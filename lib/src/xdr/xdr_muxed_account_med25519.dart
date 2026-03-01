// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:stellar_flutter_sdk/src/key_pair.dart';

import 'xdr_data_io.dart';
import 'xdr_uint256.dart';
import 'xdr_uint64.dart';

class XdrMuxedAccountMed25519 {
  XdrUint64 _id;

  XdrUint64 get id => this._id;

  set id(XdrUint64 value) => this._id = value;

  XdrUint256 _ed25519;

  XdrUint256 get ed25519 => this._ed25519;

  set ed25519(XdrUint256 value) => this._ed25519 = value;

  XdrMuxedAccountMed25519(this._id, this._ed25519);

  static void encode(XdrDataOutputStream stream,
      XdrMuxedAccountMed25519 muxedAccountMed25519Entry) {
    XdrUint64.encode(stream, muxedAccountMed25519Entry.id);
    XdrUint256.encode(stream, muxedAccountMed25519Entry.ed25519);
  }

  static void encodeInverted(XdrDataOutputStream stream,
      XdrMuxedAccountMed25519 muxedAccountMed25519Entry) {
    XdrUint256.encode(stream, muxedAccountMed25519Entry.ed25519);
    XdrUint64.encode(stream, muxedAccountMed25519Entry.id);
  }

  static XdrMuxedAccountMed25519 decode(XdrDataInputStream stream) {
    return XdrMuxedAccountMed25519(
        XdrUint64.decode(stream), XdrUint256.decode(stream));
  }

  static XdrMuxedAccountMed25519 decodeInverted(XdrDataInputStream stream) {
    XdrUint256 dEd25519 = XdrUint256.decode(stream);
    XdrUint64 dId = XdrUint64.decode(stream);
    return XdrMuxedAccountMed25519(dId, dEd25519);
  }

  String get accountId {
    XdrDataOutputStream xdrOutputStream = new XdrDataOutputStream();
    XdrMuxedAccountMed25519.encodeInverted(
        xdrOutputStream, this);
    Uint8List bytes = Uint8List.fromList(xdrOutputStream.bytes);
    return StrKey.encodeStellarMuxedAccountId(bytes);
  }
}
