// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_account_entry_v3.dart';
import 'xdr_data_io.dart';

class XdrAccountEntryV2Ext {
  int _v;

  int get discriminant => this._v;

  set discriminant(int value) => this._v = value;

  XdrAccountEntryV3? _v3;

  XdrAccountEntryV3? get v3 => this._v3;

  set v3(XdrAccountEntryV3? value) => this._v3 = value;

  XdrAccountEntryV2Ext(this._v);

  static void encode(XdrDataOutputStream stream, XdrAccountEntryV2Ext encoded) {
    stream.writeInt(encoded.discriminant);
    switch (encoded.discriminant) {
      case 0:
        break;
      case 3:
        XdrAccountEntryV3.encode(stream, encoded.v3!);
        break;
    }
  }

  static XdrAccountEntryV2Ext decode(XdrDataInputStream stream) {
    XdrAccountEntryV2Ext decoded = XdrAccountEntryV2Ext(stream.readInt());
    switch (decoded.discriminant) {
      case 0:
        break;
      case 3:
        decoded.v3 = XdrAccountEntryV3.decode(stream);
        break;
    }
    return decoded;
  }
}
