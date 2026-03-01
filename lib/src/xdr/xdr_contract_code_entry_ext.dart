// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_contract_code_entry_ext_v1.dart';
import 'xdr_data_io.dart';

class XdrContractCodeEntryExt {
  XdrContractCodeEntryExt(this._v);
  int _v;
  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  XdrContractCodeEntryExtV1? _v1;
  XdrContractCodeEntryExtV1? get v1 => this._v1;
  set v1(XdrContractCodeEntryExtV1? value) => this._v1 = value;

  static void encode(
    XdrDataOutputStream stream,
    XdrContractCodeEntryExt encoded,
  ) {
    stream.writeInt(encoded.discriminant);
    switch (encoded.discriminant) {
      case 0:
        break;
      case 1:
        XdrContractCodeEntryExtV1.encode(stream, encoded.v1!);
        break;
    }
  }

  static XdrContractCodeEntryExt decode(XdrDataInputStream stream) {
    XdrContractCodeEntryExt decoded = XdrContractCodeEntryExt(stream.readInt());
    switch (decoded.discriminant) {
      case 0:
        break;
      case 1:
        decoded.v1 = XdrContractCodeEntryExtV1.decode(stream);
        break;
    }
    return decoded;
  }
}
