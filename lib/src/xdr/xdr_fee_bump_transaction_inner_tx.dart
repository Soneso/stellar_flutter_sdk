// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_envelope_type.dart';
import 'xdr_transaction_v1_envelope.dart';

class XdrFeeBumpTransactionInnerTx {
  XdrFeeBumpTransactionInnerTx(this._type);

  XdrEnvelopeType _type;
  XdrEnvelopeType get discriminant => this._type;
  set discriminant(XdrEnvelopeType value) => this._type = value;

  XdrTransactionV1Envelope? _v1;
  XdrTransactionV1Envelope? get v1 => this._v1;
  set v1(XdrTransactionV1Envelope? value) => this._v1 = value;

  static void encode(
    XdrDataOutputStream stream,
    XdrFeeBumpTransactionInnerTx encodedTransaction,
  ) {
    stream.writeInt(encodedTransaction.discriminant.value);
    switch (encodedTransaction.discriminant) {
      case XdrEnvelopeType.ENVELOPE_TYPE_TX:
        XdrTransactionV1Envelope.encode(stream, encodedTransaction.v1!);
        break;
    }
  }

  static XdrFeeBumpTransactionInnerTx decode(XdrDataInputStream stream) {
    XdrFeeBumpTransactionInnerTx decoded = XdrFeeBumpTransactionInnerTx(
      XdrEnvelopeType.decode(stream),
    );
    switch (decoded.discriminant) {
      case XdrEnvelopeType.ENVELOPE_TYPE_TX:
        decoded.v1 = XdrTransactionV1Envelope.decode(stream);
        break;
    }
    return decoded;
  }
}
