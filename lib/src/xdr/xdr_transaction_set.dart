// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_hash.dart';
import 'xdr_transaction_envelope.dart';

class XdrTransactionSet {
  XdrTransactionSet(this._previousLedgerHash, this._txEnvelopes);
  XdrHash _previousLedgerHash;
  XdrHash get previousLedgerHash => this._previousLedgerHash;
  set previousLedgerHash(XdrHash value) => this._previousLedgerHash = value;

  List<XdrTransactionEnvelope> _txEnvelopes;
  List<XdrTransactionEnvelope> get txEnvelopes => this._txEnvelopes;
  set txs(List<XdrTransactionEnvelope> value) => this._txEnvelopes = value;

  static void encode(
    XdrDataOutputStream stream,
    XdrTransactionSet encodedTransactionSet,
  ) {
    XdrHash.encode(stream, encodedTransactionSet._previousLedgerHash);
    int txEnvelopesSize = encodedTransactionSet.txEnvelopes.length;
    stream.writeInt(txEnvelopesSize);
    for (int i = 0; i < txEnvelopesSize; i++) {
      XdrTransactionEnvelope.encode(
        stream,
        encodedTransactionSet._txEnvelopes[i],
      );
    }
  }

  static XdrTransactionSet decode(XdrDataInputStream stream) {
    XdrHash previousLedgerHash = XdrHash.decode(stream);

    int txEnvelopesSize = stream.readInt();
    List<XdrTransactionEnvelope> envelopes = List<XdrTransactionEnvelope>.empty(
      growable: true,
    );
    for (int i = 0; i < txEnvelopesSize; i++) {
      envelopes.add(XdrTransactionEnvelope.decode(stream));
    }

    return XdrTransactionSet(previousLedgerHash, envelopes);
  }
}
