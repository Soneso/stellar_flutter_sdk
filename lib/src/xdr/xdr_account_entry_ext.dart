// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_account_entry_v1.dart';
import 'xdr_data_io.dart';

class XdrAccountEntryExt {
  int _v;

  int get discriminant => this._v;

  set discriminant(int value) => this._v = value;

  XdrAccountEntryV1? _v1;

  XdrAccountEntryV1? get v1 => this._v1;

  set v1(XdrAccountEntryV1? value) => this._v1 = value;

  XdrAccountEntryExt(this._v);

  static void encode(
      XdrDataOutputStream stream, XdrAccountEntryExt encodedAccountEntryExt) {
    stream.writeInt(encodedAccountEntryExt.discriminant);
    switch (encodedAccountEntryExt.discriminant) {
      case 0:
        break;
      case 1:
        XdrAccountEntryV1.encode(stream, encodedAccountEntryExt.v1!);
        break;
    }
  }

  static XdrAccountEntryExt decode(XdrDataInputStream stream) {
    XdrAccountEntryExt decodedAccountEntryExt =
        XdrAccountEntryExt(stream.readInt());
    switch (decodedAccountEntryExt.discriminant) {
      case 0:
        break;
      case 1:
        decodedAccountEntryExt.v1 = XdrAccountEntryV1.decode(stream);
        break;
    }
    return decodedAccountEntryExt;
  }
}
