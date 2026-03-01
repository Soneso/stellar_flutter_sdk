// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_contract_event.dart';
import 'xdr_data_io.dart';

class XdrDiagnosticEventBase {
  bool _inSuccessfulContractCall;
  bool get inSuccessfulContractCall => this._inSuccessfulContractCall;
  set ext(bool value) => this._inSuccessfulContractCall = value;

  XdrContractEvent _event;
  XdrContractEvent get event => this._event;
  set hash(XdrContractEvent value) => this._event = value;

  XdrDiagnosticEventBase(this._inSuccessfulContractCall, this._event);

  static void encode(
    XdrDataOutputStream stream,
    XdrDiagnosticEventBase encoded,
  ) {
    stream.writeBoolean(encoded.inSuccessfulContractCall);
    XdrContractEvent.encode(stream, encoded.event);
  }

  static XdrDiagnosticEventBase decode(XdrDataInputStream stream) {
    return XdrDiagnosticEventBase(
      stream.readBoolean(),
      XdrContractEvent.decode(stream),
    );
  }
}
