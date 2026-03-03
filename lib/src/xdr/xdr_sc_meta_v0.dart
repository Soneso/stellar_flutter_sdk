// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrSCMetaV0 {
  String _key;
  String get key => this._key;
  set key(String value) => this._key = value;

  String _val;
  String get val => this._val;
  set val(String value) => this._val = value;

  XdrSCMetaV0(this._key, this._val);

  static void encode(XdrDataOutputStream stream, XdrSCMetaV0 encodedSCMetaV0) {
    stream.writeString(encodedSCMetaV0.key);
    stream.writeString(encodedSCMetaV0.val);
  }

  static XdrSCMetaV0 decode(XdrDataInputStream stream) {
    String key = stream.readString();
    String val = stream.readString();
    return XdrSCMetaV0(key, val);
  }
}
