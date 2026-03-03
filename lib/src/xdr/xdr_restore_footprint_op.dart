// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_extension_point.dart';

class XdrRestoreFootprintOp {

  XdrExtensionPoint _ext;
  XdrExtensionPoint get ext => this._ext;
  set ext(XdrExtensionPoint value) => this._ext = value;

  XdrRestoreFootprintOp(this._ext);

  static void encode(XdrDataOutputStream stream, XdrRestoreFootprintOp encodedRestoreFootprintOp) {
    XdrExtensionPoint.encode(stream, encodedRestoreFootprintOp.ext);
  }

  static XdrRestoreFootprintOp decode(XdrDataInputStream stream) {
    XdrExtensionPoint ext = XdrExtensionPoint.decode(stream);
    return XdrRestoreFootprintOp(ext);
  }
}
