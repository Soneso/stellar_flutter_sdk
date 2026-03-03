// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrUint32 {
  XdrUint32(this._uint32);

  int _uint32;
  int get uint32 => this._uint32;
  set uint32(int value) => this._uint32 = value;

  static void encode(XdrDataOutputStream stream, XdrUint32 encodedUint32) {
    stream.writeInt(encodedUint32.uint32);
  }

  static XdrUint32 decode(XdrDataInputStream stream) {
    return XdrUint32(stream.readInt());
  }
}
