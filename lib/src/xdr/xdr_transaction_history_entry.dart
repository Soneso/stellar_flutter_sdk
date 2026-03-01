// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_transaction_history_entry_ext.dart';
import 'xdr_transaction_set.dart';
import 'xdr_uint32.dart';

class XdrTransactionHistoryEntry {
  XdrUint32 _ledgerSeq;
  XdrUint32 get ledgerSeq => this._ledgerSeq;
  set ledgerSeq(XdrUint32 value) => this._ledgerSeq = value;

  XdrTransactionSet _txSet;
  XdrTransactionSet get txSet => this._txSet;
  set txSet(XdrTransactionSet value) => this._txSet = value;

  XdrTransactionHistoryEntryExt _ext;
  XdrTransactionHistoryEntryExt get ext => this._ext;
  set ext(XdrTransactionHistoryEntryExt value) => this._ext = value;

  XdrTransactionHistoryEntry(this._ledgerSeq, this._txSet, this._ext);

  static void encode(XdrDataOutputStream stream,
      XdrTransactionHistoryEntry encodedTransactionHistoryEntry) {
    XdrUint32.encode(stream, encodedTransactionHistoryEntry.ledgerSeq);
    XdrTransactionSet.encode(stream, encodedTransactionHistoryEntry.txSet);
    XdrTransactionHistoryEntryExt.encode(
        stream, encodedTransactionHistoryEntry.ext);
  }

  static XdrTransactionHistoryEntry decode(XdrDataInputStream stream) {
    return XdrTransactionHistoryEntry(
        XdrUint32.decode(stream),
        XdrTransactionSet.decode(stream),
        XdrTransactionHistoryEntryExt.decode(stream));
  }
}
