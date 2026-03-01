// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_extension_point.dart';
import 'xdr_uint32.dart';
import 'xdr_uint64.dart';

class XdrAccountEntryV3 {
  XdrAccountEntryV3(this._ext, this._seqLedger, this._seqTime);

  XdrUint32 _seqLedger;

  XdrUint32 get seqLedger => this._seqLedger;

  set seqLedger(XdrUint32 value) => this._seqLedger = value;

  XdrUint64 _seqTime;

  XdrUint64 get seqTime => this._seqTime;

  set seqTime(XdrUint64 value) => this._seqTime = value;

  XdrExtensionPoint _ext;

  XdrExtensionPoint get ext => this._ext;

  set ext(XdrExtensionPoint value) => this._ext = value;

  static void encode(XdrDataOutputStream stream, XdrAccountEntryV3 encoded) {
    XdrExtensionPoint.encode(stream, encoded.ext);
    XdrUint32.encode(stream, encoded.seqLedger);
    XdrUint64.encode(stream, encoded.seqTime);
  }

  static XdrAccountEntryV3 decode(XdrDataInputStream stream) {
    XdrAccountEntryV3 decoded = XdrAccountEntryV3(
        XdrExtensionPoint.decode(stream),
        XdrUint32.decode(stream),
        XdrUint64.decode(stream));
    return decoded;
  }
}
