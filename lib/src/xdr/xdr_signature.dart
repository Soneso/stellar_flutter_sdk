// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'xdr_data_io.dart';

class XdrSignature {
  XdrSignature(this._signature);

  Uint8List _signature;
  Uint8List get signature => this._signature;
  set signature(Uint8List value) => this._signature = value;

  static void encode(
    XdrDataOutputStream stream,
    XdrSignature encodedSignature,
  ) {
    int signatureSize = encodedSignature.signature.length;
    stream.writeInt(signatureSize);
    stream.write(encodedSignature.signature);
  }

  static XdrSignature decode(XdrDataInputStream stream) {
    int signatureSize = stream.readInt();
    return XdrSignature(stream.readBytes(signatureSize));
  }
}
