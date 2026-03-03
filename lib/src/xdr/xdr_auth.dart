// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrAuth {
  int _flags;
  int get flags => this._flags;
  set flags(int value) => this._flags = value;

  XdrAuth(this._flags);

  static void encode(XdrDataOutputStream stream, XdrAuth encodedAuth) {
    stream.writeInt(encodedAuth.flags);
  }

  static XdrAuth decode(XdrDataInputStream stream) {
    int flags = stream.readInt();
    return XdrAuth(flags);
  }
}
