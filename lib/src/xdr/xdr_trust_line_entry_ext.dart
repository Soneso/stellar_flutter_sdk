// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_trust_line_entry_v1.dart';

class XdrTrustLineEntryExt {
  XdrTrustLineEntryExt(this._v);

  int _v;

  int get discriminant => this._v;

  set discriminant(int value) => this._v = value;

  XdrTrustLineEntryV1? _v1;

  XdrTrustLineEntryV1? get v1 => this._v1;

  set v1(XdrTrustLineEntryV1? value) => this._v1 = value;

  static void encode(
    XdrDataOutputStream stream,
    XdrTrustLineEntryExt encodedTrustLineEntryExt,
  ) {
    stream.writeInt(encodedTrustLineEntryExt.discriminant);
    switch (encodedTrustLineEntryExt.discriminant) {
      case 0:
        break;
      case 1:
        XdrTrustLineEntryV1.encode(stream, encodedTrustLineEntryExt.v1!);
        break;
    }
  }

  static XdrTrustLineEntryExt decode(XdrDataInputStream stream) {
    XdrTrustLineEntryExt decodedTrustLineEntryExt = XdrTrustLineEntryExt(
      stream.readInt(),
    );
    switch (decodedTrustLineEntryExt.discriminant) {
      case 0:
        break;
      case 1:
        decodedTrustLineEntryExt.v1 = XdrTrustLineEntryV1.decode(stream);
        break;
    }
    return decodedTrustLineEntryExt;
  }
}
