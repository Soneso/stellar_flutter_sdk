// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'xdr_data_io.dart';

class XdrSCBytes {
  XdrSCBytes(this._sCBytes);

  Uint8List _sCBytes;
  Uint8List get sCBytes => this._sCBytes;
  set sCBytes(Uint8List value) => this._sCBytes = value;

  static void encode(XdrDataOutputStream stream, XdrSCBytes encodedSCBytes) {
    int sCBytesSize = encodedSCBytes.sCBytes.length;
    stream.writeInt(sCBytesSize);
    stream.write(encodedSCBytes.sCBytes);
  }

  static XdrSCBytes decode(XdrDataInputStream stream) {
    int sCBytesSize = stream.readInt();
    return XdrSCBytes(stream.readBytes(sCBytesSize));
  }
}
