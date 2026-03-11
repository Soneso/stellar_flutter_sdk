// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
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

  static XdrTransactionEnvelope fromTxRep(
    Map<String, String> map,
    String prefix,
  ) {
    var b = XdrTransactionEnvelopeBase.fromTxRep(map, prefix);
    var result = XdrTransactionEnvelope(b.discriminant);
    result.v0 = b.v0;
    result.v1 = b.v1;
    result.feeBump = b.feeBump;
    return result;
  }

  /// Legacy name — delegates to [fromBase64EncodedXdrString].
  static XdrTransactionEnvelope fromEnvelopeXdrString(String envelope) {
    return fromBase64EncodedXdrString(envelope);
  }

  static XdrTransactionEnvelope fromBase64EncodedXdrString(
    String base64Encoded,
  ) {
    Uint8List bytes = base64Decode(base64Encoded);
    return XdrTransactionEnvelope.decode(XdrDataInputStream(bytes));
  }

  /// Legacy name — delegates to [toBase64EncodedXdrString].
  String toEnvelopeXdrBase64() {
    return toBase64EncodedXdrString();
  }
}
