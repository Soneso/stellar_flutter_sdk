// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'xdr_data_io.dart';
import 'xdr_envelope_type.dart';
import 'xdr_fee_bump_transaction_envelope.dart';
import 'xdr_transaction_v0_envelope.dart';
import 'xdr_transaction_v1_envelope.dart';

class XdrTransactionEnvelope {
  XdrTransactionEnvelope(this._type);

  XdrEnvelopeType _type;
  XdrEnvelopeType get discriminant => this._type;
  set discriminant(XdrEnvelopeType value) => this._type = value;

  XdrTransactionV1Envelope? _v1;
  XdrTransactionV1Envelope? get v1 => this._v1;
  set v1(XdrTransactionV1Envelope? value) => this._v1 = value;

  XdrFeeBumpTransactionEnvelope? _feeBump;
  XdrFeeBumpTransactionEnvelope? get feeBump => this._feeBump;
  set feeBump(XdrFeeBumpTransactionEnvelope? value) => this._feeBump = value;

  XdrTransactionV0Envelope? _v0;
  XdrTransactionV0Envelope? get v0 => this._v0;
  set v0(XdrTransactionV0Envelope? value) => this._v0 = value;

  static void encode(
      XdrDataOutputStream stream, XdrTransactionEnvelope encodedEnvelope) {
    stream.writeInt(encodedEnvelope.discriminant.value);
    switch (encodedEnvelope.discriminant) {
      case XdrEnvelopeType.ENVELOPE_TYPE_TX_V0:
        XdrTransactionV0Envelope.encode(stream, encodedEnvelope.v0!);
        break;
      case XdrEnvelopeType.ENVELOPE_TYPE_TX:
        XdrTransactionV1Envelope.encode(stream, encodedEnvelope.v1!);
        break;
      case XdrEnvelopeType.ENVELOPE_TYPE_TX_FEE_BUMP:
        XdrFeeBumpTransactionEnvelope.encode(stream, encodedEnvelope.feeBump!);
        break;
    }
  }

  static XdrTransactionEnvelope decode(XdrDataInputStream stream) {
    XdrTransactionEnvelope decoded =
        XdrTransactionEnvelope(XdrEnvelopeType.decode(stream));
    switch (decoded.discriminant) {
      case XdrEnvelopeType.ENVELOPE_TYPE_TX_V0:
        decoded.v0 = XdrTransactionV0Envelope.decode(stream);
        break;
      case XdrEnvelopeType.ENVELOPE_TYPE_TX:
        decoded.v1 = XdrTransactionV1Envelope.decode(stream);
        break;
      case XdrEnvelopeType.ENVELOPE_TYPE_TX_FEE_BUMP:
        decoded.feeBump = XdrFeeBumpTransactionEnvelope.decode(stream);
        break;
    }
    return decoded;
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
