// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_ledger_entry_changes.dart';
import 'xdr_operation_meta.dart';

class XdrTransactionMetaV2 {
  XdrTransactionMetaV2(
      this._txChangesBefore, this._operations, this._txChangesAfter);
  XdrLedgerEntryChanges _txChangesBefore;
  XdrLedgerEntryChanges get txChangesBefore => this._txChangesBefore;
  set txChangesBefore(XdrLedgerEntryChanges value) =>
      this._txChangesBefore = value;

  List<XdrOperationMeta> _operations;
  List<XdrOperationMeta> get operations => this._operations;
  set operations(List<XdrOperationMeta> value) => this._operations = value;

  XdrLedgerEntryChanges _txChangesAfter;
  XdrLedgerEntryChanges get txChangesAfter => this._txChangesAfter;
  set txChangesAfter(XdrLedgerEntryChanges value) =>
      this._txChangesAfter = value;

  static void encode(XdrDataOutputStream stream,
      XdrTransactionMetaV2 encodedTransactionMetaV2) {
    XdrLedgerEntryChanges.encode(
        stream, encodedTransactionMetaV2._txChangesBefore);
    int operationsSize = encodedTransactionMetaV2.operations.length;
    stream.writeInt(operationsSize);
    for (int i = 0; i < operationsSize; i++) {
      XdrOperationMeta.encode(stream, encodedTransactionMetaV2._operations[i]);
    }
    XdrLedgerEntryChanges.encode(
        stream, encodedTransactionMetaV2._txChangesAfter);
  }

  static XdrTransactionMetaV2 decode(XdrDataInputStream stream) {
    XdrLedgerEntryChanges txChangesBefore =
        XdrLedgerEntryChanges.decode(stream);
    int operationsSize = stream.readInt();
    List<XdrOperationMeta> operations =
        List<XdrOperationMeta>.empty(growable: true);
    for (int i = 0; i < operationsSize; i++) {
      operations.add(XdrOperationMeta.decode(stream));
    }
    XdrLedgerEntryChanges txChangesAfter = XdrLedgerEntryChanges.decode(stream);

    return XdrTransactionMetaV2(txChangesBefore, operations, txChangesAfter);
  }
}
