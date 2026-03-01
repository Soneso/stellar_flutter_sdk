// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrSCMetaV0 {
  String _key;
  String get key => this._key;
  set key(String value) => this._key = value;

  String _value;
  String get value => this._value;
  set value(String value) => this._value = value;

  XdrSCMetaV0(this._key, this._value);

  static void encode(XdrDataOutputStream stream, XdrSCMetaV0 encoded) {
    stream.writeString(encoded.key);
    stream.writeString(encoded.value);
  }

  static XdrSCMetaV0 decode(XdrDataInputStream stream) {
    String key = stream.readString();
    String value = stream.readString();
    return XdrSCMetaV0(key, value);
  }
}
