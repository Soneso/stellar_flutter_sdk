// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'xdr_contract_event.dart';
import 'xdr_data_io.dart';

class XdrDiagnosticEvent {
  bool _inSuccessfulContractCall;
  bool get inSuccessfulContractCall => this._inSuccessfulContractCall;
  set ext(bool value) => this._inSuccessfulContractCall = value;

  XdrContractEvent _event;
  XdrContractEvent get event => this._event;
  set hash(XdrContractEvent value) => this._event = value;

  XdrDiagnosticEvent(this._inSuccessfulContractCall, this._event);

  static void encode(XdrDataOutputStream stream, XdrDiagnosticEvent encoded) {
    stream.writeBoolean(encoded.inSuccessfulContractCall);
    XdrContractEvent.encode(stream, encoded.event);
  }

  static XdrDiagnosticEvent decode(XdrDataInputStream stream) {
    return XdrDiagnosticEvent(
        stream.readBoolean(), XdrContractEvent.decode(stream));
  }

  String toBase64EncodedXdrString() {
    XdrDataOutputStream xdrOutputStream = XdrDataOutputStream();
    XdrDiagnosticEvent.encode(xdrOutputStream, this);
    return base64Encode(xdrOutputStream.bytes);
  }

  static XdrDiagnosticEvent fromBase64EncodedXdrString(String base64Encoded) {
    Uint8List bytes = base64Decode(base64Encoded);
    return XdrDiagnosticEvent.decode(XdrDataInputStream(bytes));
  }
}
