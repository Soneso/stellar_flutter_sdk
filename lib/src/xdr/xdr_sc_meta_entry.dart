// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_sc_meta_kind.dart';
import 'xdr_sc_meta_v0.dart';

class XdrSCMetaEntry {
  XdrSCMetaEntry(this._kind);
  XdrSCMetaKind _kind;
  XdrSCMetaKind get discriminant => this._kind;
  set discriminant(XdrSCMetaKind value) => this._kind = value;

  XdrSCMetaV0? _v0;
  XdrSCMetaV0? get v0 => this._v0;
  set v0(XdrSCMetaV0? value) => this._v0 = value;

  static void encode(XdrDataOutputStream stream, XdrSCMetaEntry encoded) {
    stream.writeInt(encoded.discriminant.value);
    switch (encoded.discriminant) {
      case XdrSCMetaKind.SC_META_V0:
        XdrSCMetaV0.encode(stream, encoded.v0!);
        break;
    }
  }

  static XdrSCMetaEntry decode(XdrDataInputStream stream) {
    XdrSCMetaEntry decoded = XdrSCMetaEntry(XdrSCMetaKind.decode(stream));
    switch (decoded.discriminant) {
      case XdrSCMetaKind.SC_META_V0:
        decoded.v0 = XdrSCMetaV0.decode(stream);
        break;
    }
    return decoded;
  }
}
