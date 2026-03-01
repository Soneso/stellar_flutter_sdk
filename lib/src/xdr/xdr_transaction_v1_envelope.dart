// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_decorated_signature.dart';
import 'xdr_transaction.dart';

class XdrTransactionV1Envelope {
  XdrTransactionV1Envelope(this._tx, this._signatures);

  XdrTransaction _tx;
  XdrTransaction get tx => this._tx;
  set tx(XdrTransaction value) => this._tx = value;

  List<XdrDecoratedSignature> _signatures;
  List<XdrDecoratedSignature> get signatures => this._signatures;
  set signatures(List<XdrDecoratedSignature> value) => this._signatures = value;

  static void encode(XdrDataOutputStream stream,
      XdrTransactionV1Envelope encodedTransactionEnvelope) {
    XdrTransaction.encode(stream, encodedTransactionEnvelope._tx);
    int signaturesSize = encodedTransactionEnvelope.signatures.length;
    stream.writeInt(signaturesSize);
    for (int i = 0; i < signaturesSize; i++) {
      XdrDecoratedSignature.encode(
          stream, encodedTransactionEnvelope._signatures[i]);
    }
  }

  static XdrTransactionV1Envelope decode(XdrDataInputStream stream) {
    XdrTransaction tx = XdrTransaction.decode(stream);
    int signaturesSize = stream.readInt();
    List<XdrDecoratedSignature> signatures =
        List<XdrDecoratedSignature>.empty(growable: true);
    for (int i = 0; i < signaturesSize; i++) {
      signatures.add(XdrDecoratedSignature.decode(stream));
    }
    return XdrTransactionV1Envelope(tx, signatures);
  }
}
