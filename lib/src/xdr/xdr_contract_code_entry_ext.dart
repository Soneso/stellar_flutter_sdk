// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_contract_code_entry_v1.dart';
import 'xdr_data_io.dart';

class XdrContractCodeEntryExt {
  int _v;

  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  XdrContractCodeEntryV1? _v1;

  XdrContractCodeEntryV1? get v1 => this._v1;

  XdrContractCodeEntryExt(this._v);

  set v1(XdrContractCodeEntryV1? value) => this._v1 = value;

  static void encode(
    XdrDataOutputStream stream,
    XdrContractCodeEntryExt encodedContractCodeEntryExt,
  ) {
    stream.writeInt(encodedContractCodeEntryExt.discriminant);
    switch (encodedContractCodeEntryExt.discriminant) {
      case 0:
        break;
      case 1:
        XdrContractCodeEntryV1.encode(stream, encodedContractCodeEntryExt._v1!);
        break;
      default:
        break;
    }
  }

  static XdrContractCodeEntryExt decode(XdrDataInputStream stream) {
    int discriminant = stream.readInt();
    XdrContractCodeEntryExt decodedContractCodeEntryExt =
        XdrContractCodeEntryExt(discriminant);
    switch (decodedContractCodeEntryExt.discriminant) {
      case 0:
        break;
      case 1:
        decodedContractCodeEntryExt._v1 = XdrContractCodeEntryV1.decode(stream);
        break;
      default:
        break;
    }
    return decodedContractCodeEntryExt;
  }
}
