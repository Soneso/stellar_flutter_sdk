// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_sc_val.dart';

class XdrSCMapEntry {
  XdrSCVal _key;
  XdrSCVal get key => this._key;
  set key(XdrSCVal value) => this._key = value;

  XdrSCVal _val;
  XdrSCVal get val => this._val;
  set val(XdrSCVal value) => this._val = value;

  XdrSCMapEntry(this._key, this._val);

  static void encode(XdrDataOutputStream stream, XdrSCMapEntry encoded) {
    XdrSCVal.encode(stream, encoded.key);
    XdrSCVal.encode(stream, encoded.val);
  }

  static XdrSCMapEntry decode(XdrDataInputStream stream) {
    return XdrSCMapEntry(XdrSCVal.decode(stream), XdrSCVal.decode(stream));
  }
}
