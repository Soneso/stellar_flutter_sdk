// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrAuth {
  int _unused;
  int get unused => this._unused;
  set unused(int value) => this._unused = value;

  XdrAuth(this._unused);

  static void encode(XdrDataOutputStream stream, XdrAuth encodedAuth) {
    stream.writeInt(encodedAuth.unused);
  }

  static XdrAuth decode(XdrDataInputStream stream) {
    return XdrAuth(stream.readInt());
  }
}
