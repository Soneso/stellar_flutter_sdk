// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrString64 {
  XdrString64(this._string64);
  String _string64;
  String get string64 => this._string64;
  set string64(String value) => this._string64 = value;

  static encode(XdrDataOutputStream stream, XdrString64 encodedString64) {
    stream.writeString(encodedString64.string64);
  }

  static XdrString64 decode(XdrDataInputStream stream) {
    return XdrString64(stream.readString());
  }
}
