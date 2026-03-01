// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_ledger_entry_changes.dart';
import 'xdr_operation_meta.dart';

class XdrTransactionMetaV1 {
  XdrTransactionMetaV1(this._txChanges, this._operations);
  XdrLedgerEntryChanges _txChanges;
  XdrLedgerEntryChanges get txChanges => this._txChanges;
  set txChanges(XdrLedgerEntryChanges value) => this._txChanges = value;

  List<XdrOperationMeta> _operations;
  List<XdrOperationMeta> get operations => this._operations;
  set operations(List<XdrOperationMeta> value) => this._operations = value;

  static void encode(XdrDataOutputStream stream,
      XdrTransactionMetaV1 encodedTransactionMetaV1) {
    XdrLedgerEntryChanges.encode(stream, encodedTransactionMetaV1._txChanges);
    int operationsSize = encodedTransactionMetaV1.operations.length;
    stream.writeInt(operationsSize);
    for (int i = 0; i < operationsSize; i++) {
      XdrOperationMeta.encode(stream, encodedTransactionMetaV1._operations[i]);
    }
  }

  static XdrTransactionMetaV1 decode(XdrDataInputStream stream) {
    XdrLedgerEntryChanges txChanges = XdrLedgerEntryChanges.decode(stream);
    int operationsSize = stream.readInt();
    List<XdrOperationMeta> operations =
        List<XdrOperationMeta>.empty(growable: true);
    for (int i = 0; i < operationsSize; i++) {
      operations.add(XdrOperationMeta.decode(stream));
    }
    return XdrTransactionMetaV1(txChanges, operations);
  }
}
