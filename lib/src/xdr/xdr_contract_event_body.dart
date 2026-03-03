// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_contract_event_v0.dart';
import 'xdr_data_io.dart';

class XdrContractEventBody {
  int _v;

  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  XdrContractEventV0? _v0;

  XdrContractEventV0? get v0 => this._v0;

  XdrContractEventBody(this._v);

  set v0(XdrContractEventV0? value) => this._v0 = value;

  static void encode(
    XdrDataOutputStream stream,
    XdrContractEventBody encodedContractEventBody,
  ) {
    stream.writeInt(encodedContractEventBody.discriminant);
    switch (encodedContractEventBody.discriminant) {
      case 0:
        XdrContractEventV0.encode(stream, encodedContractEventBody._v0!);
        break;
      default:
        break;
    }
  }

  static XdrContractEventBody decode(XdrDataInputStream stream) {
    int discriminant = stream.readInt();
    XdrContractEventBody decodedContractEventBody = XdrContractEventBody(
      discriminant,
    );
    switch (decodedContractEventBody.discriminant) {
      case 0:
        decodedContractEventBody._v0 = XdrContractEventV0.decode(stream);
        break;
      default:
        break;
    }
    return decodedContractEventBody;
  }
}
