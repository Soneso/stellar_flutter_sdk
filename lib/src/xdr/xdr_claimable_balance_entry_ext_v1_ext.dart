// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrClaimableBalanceEntryExtV1Ext {
  int _v;

  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  XdrClaimableBalanceEntryExtV1Ext(this._v);

  static void encode(XdrDataOutputStream stream, XdrClaimableBalanceEntryExtV1Ext encodedClaimableBalanceEntryExtV1Ext) {
    stream.writeInt(encodedClaimableBalanceEntryExtV1Ext.discriminant);
    switch (encodedClaimableBalanceEntryExtV1Ext.discriminant) {
      case 0:
        break;
      default:
        break;
    }
  }

  static XdrClaimableBalanceEntryExtV1Ext decode(XdrDataInputStream stream) {
    int discriminant = stream.readInt();
    XdrClaimableBalanceEntryExtV1Ext decodedClaimableBalanceEntryExtV1Ext = XdrClaimableBalanceEntryExtV1Ext(discriminant);
    switch (decodedClaimableBalanceEntryExtV1Ext.discriminant) {
      case 0:
        break;
      default:
        break;
    }
    return decodedClaimableBalanceEntryExtV1Ext;
  }
}
