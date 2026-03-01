// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_envelope_type.dart';
import 'xdr_transaction.dart';

class XdrTransactionSignaturePayloadTaggedTransaction {
  XdrTransactionSignaturePayloadTaggedTransaction(this._type);
  XdrEnvelopeType _type;
  XdrEnvelopeType get discriminant => this._type;
  set discriminant(XdrEnvelopeType value) => this._type = value;

  XdrTransaction? _tx;
  XdrTransaction? get tx => this._tx;
  set tx(XdrTransaction? value) => this._tx = value;

  static void encode(
      XdrDataOutputStream stream,
      XdrTransactionSignaturePayloadTaggedTransaction
          encodedTransactionSignaturePayloadTaggedTransaction) {
    stream.writeInt(
        encodedTransactionSignaturePayloadTaggedTransaction.discriminant.value);
    switch (encodedTransactionSignaturePayloadTaggedTransaction.discriminant) {
      case XdrEnvelopeType.ENVELOPE_TYPE_TX:
        XdrTransaction.encode(
            stream, encodedTransactionSignaturePayloadTaggedTransaction._tx!);
        break;
    }
  }

  static XdrTransactionSignaturePayloadTaggedTransaction decode(
      XdrDataInputStream stream) {
    XdrTransactionSignaturePayloadTaggedTransaction
        decodedTransactionSignaturePayloadTaggedTransaction =
        XdrTransactionSignaturePayloadTaggedTransaction(
            XdrEnvelopeType.decode(stream));
    switch (decodedTransactionSignaturePayloadTaggedTransaction.discriminant) {
      case XdrEnvelopeType.ENVELOPE_TYPE_TX:
        decodedTransactionSignaturePayloadTaggedTransaction._tx =
            XdrTransaction.decode(stream);
        break;
    }
    return decodedTransactionSignaturePayloadTaggedTransaction;
  }
}
