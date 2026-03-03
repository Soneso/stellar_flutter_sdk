// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_extension_point.dart';
import 'xdr_uint32.dart';
import 'xdr_uint64.dart';

class XdrAccountEntryV3 {

  XdrExtensionPoint _ext;
  XdrExtensionPoint get ext => this._ext;
  set ext(XdrExtensionPoint value) => this._ext = value;

  XdrUint32 _seqLedger;
  XdrUint32 get seqLedger => this._seqLedger;
  set seqLedger(XdrUint32 value) => this._seqLedger = value;

  XdrUint64 _seqTime;
  XdrUint64 get seqTime => this._seqTime;
  set seqTime(XdrUint64 value) => this._seqTime = value;

  XdrAccountEntryV3(this._ext, this._seqLedger, this._seqTime);

  static void encode(XdrDataOutputStream stream, XdrAccountEntryV3 encodedAccountEntryV3) {
    XdrExtensionPoint.encode(stream, encodedAccountEntryV3.ext);
    XdrUint32.encode(stream, encodedAccountEntryV3.seqLedger);
    XdrUint64.encode(stream, encodedAccountEntryV3.seqTime);
  }

  static XdrAccountEntryV3 decode(XdrDataInputStream stream) {
    XdrExtensionPoint ext = XdrExtensionPoint.decode(stream);
    XdrUint32 seqLedger = XdrUint32.decode(stream);
    XdrUint64 seqTime = XdrUint64.decode(stream);
    return XdrAccountEntryV3(ext, seqLedger, seqTime);
  }
}
