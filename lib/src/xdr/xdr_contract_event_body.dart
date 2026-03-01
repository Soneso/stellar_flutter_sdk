// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_contract_event_body_v0.dart';
import 'xdr_data_io.dart';

class XdrContractEventBody {
  XdrContractEventBody(this._v);
  int _v;
  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  XdrContractEventBodyV0? _v0;
  XdrContractEventBodyV0? get v0 => this._v0;
  set v0(XdrContractEventBodyV0? value) => this._v0 = value;

  static void encode(XdrDataOutputStream stream, XdrContractEventBody encoded) {
    stream.writeInt(encoded.discriminant);
    switch (encoded.discriminant) {
      case 0:
        XdrContractEventBodyV0.encode(stream, encoded.v0!);
        break;
    }
  }

  static XdrContractEventBody decode(XdrDataInputStream stream) {
    XdrContractEventBody decoded = XdrContractEventBody(stream.readInt());
    switch (decoded.discriminant) {
      case 0:
        decoded.v0 = XdrContractEventBodyV0.decode(stream);
        break;
    }
    return decoded;
  }
}
