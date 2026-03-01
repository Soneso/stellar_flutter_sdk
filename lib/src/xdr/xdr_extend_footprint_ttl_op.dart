// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_extension_point.dart';
import 'xdr_uint32.dart';

class XdrExtendFootprintTTLOp {
  XdrExtensionPoint _ext;
  XdrExtensionPoint get ext => this._ext;
  set ext(XdrExtensionPoint value) => this._ext = value;

  XdrUint32 _extendTo;
  XdrUint32 get extendTo => this._extendTo;
  set extendTo(XdrUint32 value) => this._extendTo = value;

  XdrExtendFootprintTTLOp(this._ext, this._extendTo);

  static void encode(
    XdrDataOutputStream stream,
    XdrExtendFootprintTTLOp encoded,
  ) {
    XdrExtensionPoint.encode(stream, encoded.ext);
    XdrUint32.encode(stream, encoded.extendTo);
  }

  static XdrExtendFootprintTTLOp decode(XdrDataInputStream stream) {
    return XdrExtendFootprintTTLOp(
      XdrExtensionPoint.decode(stream),
      XdrUint32.decode(stream),
    );
  }
}
