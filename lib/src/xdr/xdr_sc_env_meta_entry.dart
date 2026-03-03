// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_sc_env_meta_entry_interface_version.dart';
import 'xdr_sc_env_meta_kind.dart';

class XdrSCEnvMetaEntry {
  XdrSCEnvMetaKind _kind;

  XdrSCEnvMetaKind get discriminant => this._kind;

  set discriminant(XdrSCEnvMetaKind value) => this._kind = value;

  XdrSCEnvMetaEntryInterfaceVersion? _interfaceVersion;

  XdrSCEnvMetaEntryInterfaceVersion? get interfaceVersion =>
      this._interfaceVersion;

  XdrSCEnvMetaEntry(this._kind);

  set interfaceVersion(XdrSCEnvMetaEntryInterfaceVersion? value) =>
      this._interfaceVersion = value;

  static void encode(
    XdrDataOutputStream stream,
    XdrSCEnvMetaEntry encodedSCEnvMetaEntry,
  ) {
    stream.writeInt(encodedSCEnvMetaEntry.discriminant.value);
    switch (encodedSCEnvMetaEntry.discriminant) {
      case XdrSCEnvMetaKind.SC_ENV_META_KIND_INTERFACE_VERSION:
        XdrSCEnvMetaEntryInterfaceVersion.encode(
          stream,
          encodedSCEnvMetaEntry._interfaceVersion!,
        );
        break;
      default:
        break;
    }
  }

  static XdrSCEnvMetaEntry decode(XdrDataInputStream stream) {
    XdrSCEnvMetaEntry decodedSCEnvMetaEntry = XdrSCEnvMetaEntry(
      XdrSCEnvMetaKind.decode(stream),
    );
    switch (decodedSCEnvMetaEntry.discriminant) {
      case XdrSCEnvMetaKind.SC_ENV_META_KIND_INTERFACE_VERSION:
        decodedSCEnvMetaEntry._interfaceVersion =
            XdrSCEnvMetaEntryInterfaceVersion.decode(stream);
        break;
      default:
        break;
    }
    return decodedSCEnvMetaEntry;
  }
}
