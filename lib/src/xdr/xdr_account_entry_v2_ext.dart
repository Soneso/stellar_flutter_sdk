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

  XdrAccountEntryV2Ext(this._v);

  set v3(XdrAccountEntryV3? value) => this._v3 = value;

  static void encode(
    XdrDataOutputStream stream,
    XdrAccountEntryV2Ext encodedAccountEntryV2Ext,
  ) {
    stream.writeInt(encodedAccountEntryV2Ext.discriminant);
    switch (encodedAccountEntryV2Ext.discriminant) {
      case 0:
        break;
      case 3:
        XdrAccountEntryV3.encode(stream, encodedAccountEntryV2Ext._v3!);
        break;
      default:
        break;
    }
  }

  static XdrAccountEntryV2Ext decode(XdrDataInputStream stream) {
    int discriminant = stream.readInt();
    XdrAccountEntryV2Ext decodedAccountEntryV2Ext = XdrAccountEntryV2Ext(
      discriminant,
    );
    switch (decodedAccountEntryV2Ext.discriminant) {
      case 0:
        break;
      case 3:
        decodedAccountEntryV2Ext._v3 = XdrAccountEntryV3.decode(stream);
        break;
      default:
        break;
    }
    return decodedAccountEntryV2Ext;
  }
}
