// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrOfferEntryExt {
  int _v;

  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  XdrOfferEntryExt(this._v);

  static void encode(
    XdrDataOutputStream stream,
    XdrOfferEntryExt encodedOfferEntryExt,
  ) {
    stream.writeInt(encodedOfferEntryExt.discriminant);
    switch (encodedOfferEntryExt.discriminant) {
      case 0:
        break;
      default:
        break;
    }
  }

  static XdrOfferEntryExt decode(XdrDataInputStream stream) {
    int discriminant = stream.readInt();
    XdrOfferEntryExt decodedOfferEntryExt = XdrOfferEntryExt(discriminant);
    switch (decodedOfferEntryExt.discriminant) {
      case 0:
        break;
      default:
        break;
    }
    return decodedOfferEntryExt;
  }
}
