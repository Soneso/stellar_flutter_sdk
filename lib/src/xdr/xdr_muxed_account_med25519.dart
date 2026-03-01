// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:stellar_flutter_sdk/src/key_pair.dart';

import 'xdr_data_io.dart';
import 'xdr_muxed_account_med25519_base.dart';
import 'xdr_uint256.dart';
import 'xdr_uint64.dart';

class XdrMuxedAccountMed25519 extends XdrMuxedAccountMed25519Base {
  XdrMuxedAccountMed25519(super.id, super.ed25519);

  static void encode(XdrDataOutputStream stream, XdrMuxedAccountMed25519 val) {
    XdrMuxedAccountMed25519Base.encode(stream, val);
  }

  static XdrMuxedAccountMed25519 decode(XdrDataInputStream stream) {
    var b = XdrMuxedAccountMed25519Base.decode(stream);
    return XdrMuxedAccountMed25519(b.id, b.ed25519);
  }

  static void encodeInverted(
    XdrDataOutputStream stream,
    XdrMuxedAccountMed25519 muxedAccountMed25519Entry,
  ) {
    XdrUint256.encode(stream, muxedAccountMed25519Entry.ed25519);
    XdrUint64.encode(stream, muxedAccountMed25519Entry.id);
  }

  static XdrMuxedAccountMed25519 decodeInverted(XdrDataInputStream stream) {
    XdrUint256 dEd25519 = XdrUint256.decode(stream);
    XdrUint64 dId = XdrUint64.decode(stream);
    return XdrMuxedAccountMed25519(dId, dEd25519);
  }

  String get accountId {
    XdrDataOutputStream xdrOutputStream = new XdrDataOutputStream();
    XdrMuxedAccountMed25519.encodeInverted(xdrOutputStream, this);
    Uint8List bytes = Uint8List.fromList(xdrOutputStream.bytes);
    return StrKey.encodeStellarMuxedAccountId(bytes);
  }
}
