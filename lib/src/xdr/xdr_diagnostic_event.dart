// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'xdr_data_io.dart';
import 'xdr_diagnostic_event_base.dart';

class XdrDiagnosticEvent extends XdrDiagnosticEventBase {
  XdrDiagnosticEvent(super.inSuccessfulContractCall, super.event);

  static void encode(XdrDataOutputStream stream, XdrDiagnosticEvent val) {
    XdrDiagnosticEventBase.encode(stream, val);
  }

  static XdrDiagnosticEvent decode(XdrDataInputStream stream) {
    var b = XdrDiagnosticEventBase.decode(stream);
    return XdrDiagnosticEvent(b.inSuccessfulContractCall, b.event);
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
