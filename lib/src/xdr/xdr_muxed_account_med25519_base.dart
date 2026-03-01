// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_uint256.dart';
import 'xdr_uint64.dart';

class XdrMuxedAccountMed25519Base {
  XdrUint64 _id;

  XdrUint64 get id => this._id;

  set id(XdrUint64 value) => this._id = value;

  XdrUint256 _ed25519;

  XdrUint256 get ed25519 => this._ed25519;

  set ed25519(XdrUint256 value) => this._ed25519 = value;

  XdrMuxedAccountMed25519Base(this._id, this._ed25519);

  static void encode(
    XdrDataOutputStream stream,
    XdrMuxedAccountMed25519Base muxedAccountMed25519Entry,
  ) {
    XdrUint64.encode(stream, muxedAccountMed25519Entry.id);
    XdrUint256.encode(stream, muxedAccountMed25519Entry.ed25519);
  }

  static XdrMuxedAccountMed25519Base decode(XdrDataInputStream stream) {
    return XdrMuxedAccountMed25519Base(
      XdrUint64.decode(stream),
      XdrUint256.decode(stream),
    );
  }
}
