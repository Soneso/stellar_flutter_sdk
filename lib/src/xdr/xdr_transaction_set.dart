// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_hash.dart';
import 'xdr_transaction_envelope.dart';

class XdrTransactionSet {
  XdrHash _previousLedgerHash;
  XdrHash get previousLedgerHash => this._previousLedgerHash;
  set previousLedgerHash(XdrHash value) => this._previousLedgerHash = value;

  List<XdrTransactionEnvelope> _txs;
  List<XdrTransactionEnvelope> get txs => this._txs;
  set txs(List<XdrTransactionEnvelope> value) => this._txs = value;

  XdrTransactionSet(this._previousLedgerHash, this._txs);

  static void encode(
    XdrDataOutputStream stream,
    XdrTransactionSet encodedTransactionSet,
  ) {
    XdrHash.encode(stream, encodedTransactionSet.previousLedgerHash);
    int txssize = encodedTransactionSet.txs.length;
    stream.writeInt(txssize);
    for (int i = 0; i < txssize; i++) {
      XdrTransactionEnvelope.encode(stream, encodedTransactionSet.txs[i]);
    }
  }

  static XdrTransactionSet decode(XdrDataInputStream stream) {
    XdrHash previousLedgerHash = XdrHash.decode(stream);
    int txssize = stream.readInt();
    List<XdrTransactionEnvelope> txs = List<XdrTransactionEnvelope>.empty(
      growable: true,
    );
    for (int i = 0; i < txssize; i++) {
      txs.add(XdrTransactionEnvelope.decode(stream));
    }
    return XdrTransactionSet(previousLedgerHash, txs);
  }
}
