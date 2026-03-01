// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'xdr_data_io.dart';
import 'xdr_transaction_envelope_base.dart';

class XdrTransactionEnvelope extends XdrTransactionEnvelopeBase {
  XdrTransactionEnvelope(super.type);

  static void encode(XdrDataOutputStream stream, XdrTransactionEnvelope val) {
    XdrTransactionEnvelopeBase.encode(stream, val);
  }

  static XdrTransactionEnvelope decode(XdrDataInputStream stream) {
    return XdrTransactionEnvelopeBase.decodeAs(
      stream,
      XdrTransactionEnvelope.new,
    );
  }

  static XdrTransactionEnvelope fromEnvelopeXdrString(String envelope) {
    Uint8List bytes = base64Decode(envelope);
    return XdrTransactionEnvelope.decode(XdrDataInputStream(bytes));
  }

  String toEnvelopeXdrBase64() {
    XdrDataOutputStream xdrOutputStream = XdrDataOutputStream();
    XdrTransactionEnvelope.encode(xdrOutputStream, this);
    return base64Encode(xdrOutputStream.bytes);
  }
}
