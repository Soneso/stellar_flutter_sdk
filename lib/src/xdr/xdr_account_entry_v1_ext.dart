// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_account_entry_v2.dart';
import 'xdr_data_io.dart';

class XdrAccountEntryV1Ext {
  int _v;

  int get discriminant => this._v;

  set discriminant(int value) => this._v = value;

  XdrAccountEntryV2? _v2;

  XdrAccountEntryV2? get v2 => this._v2;

  set v2(XdrAccountEntryV2? value) => this._v2 = value;

  XdrAccountEntryV1Ext(this._v);

  static void encode(
    XdrDataOutputStream stream,
    XdrAccountEntryV1Ext encodedAccountEntryV1Ext,
  ) {
    stream.writeInt(encodedAccountEntryV1Ext.discriminant);
    switch (encodedAccountEntryV1Ext.discriminant) {
      case 0:
        break;
      case 2:
        XdrAccountEntryV2.encode(stream, encodedAccountEntryV1Ext.v2!);
        break;
    }
  }

  static XdrAccountEntryV1Ext decode(XdrDataInputStream stream) {
    XdrAccountEntryV1Ext decodedAccountEntryV1Ext = XdrAccountEntryV1Ext(
      stream.readInt(),
    );
    switch (decodedAccountEntryV1Ext.discriminant) {
      case 0:
        break;
      case 2:
        decodedAccountEntryV1Ext.v2 = XdrAccountEntryV2.decode(stream);
        break;
    }
    return decodedAccountEntryV1Ext;
  }
}
