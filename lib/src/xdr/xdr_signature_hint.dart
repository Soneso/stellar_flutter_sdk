// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'xdr_data_io.dart';

class XdrSignatureHint {
  Uint8List _signatureHint;
  Uint8List get signatureHint => this._signatureHint;
  set signatureHint(Uint8List value) => this._signatureHint = value;

  XdrSignatureHint(this._signatureHint);

  static encode(
      XdrDataOutputStream stream, XdrSignatureHint encodedSignatureHint) {
    stream.write(encodedSignatureHint.signatureHint);
  }

  static XdrSignatureHint decode(XdrDataInputStream stream) {
    int signatureHintSize = 4;
    return XdrSignatureHint(stream.readBytes(signatureHintSize));
  }
}
