// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_sc_env_meta_kind.dart';
import 'xdr_uint64.dart';

class XdrSCEnvMetaEntry {
  XdrSCEnvMetaEntry(this._kind);
  XdrSCEnvMetaKind _kind;
  XdrSCEnvMetaKind get discriminant => this._kind;
  set discriminant(XdrSCEnvMetaKind value) => this._kind = value;

  XdrUint64? _interfaceVersion;
  XdrUint64? get interfaceVersion => this._interfaceVersion;
  set interfaceVersion(XdrUint64? value) => this._interfaceVersion = value;

  static void encode(XdrDataOutputStream stream, XdrSCEnvMetaEntry encoded) {
    stream.writeInt(encoded.discriminant.value);
    switch (encoded.discriminant) {
      case XdrSCEnvMetaKind.SC_ENV_META_KIND_INTERFACE_VERSION:
        XdrUint64.encode(stream, encoded.interfaceVersion!);
        break;
    }
  }

  static XdrSCEnvMetaEntry decode(XdrDataInputStream stream) {
    XdrSCEnvMetaEntry decoded =
        XdrSCEnvMetaEntry(XdrSCEnvMetaKind.decode(stream));
    switch (decoded.discriminant) {
      case XdrSCEnvMetaKind.SC_ENV_META_KIND_INTERFACE_VERSION:
        decoded.interfaceVersion = XdrUint64.decode(stream);
        break;
    }
    return decoded;
  }
}
