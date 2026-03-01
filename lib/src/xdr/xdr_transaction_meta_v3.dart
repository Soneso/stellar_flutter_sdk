// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_extension_point.dart';
import 'xdr_ledger_entry_changes.dart';
import 'xdr_operation_meta.dart';
import 'xdr_soroban_transaction_meta.dart';

class XdrTransactionMetaV3 {
  XdrExtensionPoint _ext;
  XdrExtensionPoint get ext => this._ext;
  set ext(XdrExtensionPoint value) => this._ext = value;

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

  XdrSorobanTransactionMeta? _sorobanMeta;
  XdrSorobanTransactionMeta? get sorobanMeta => this._sorobanMeta;
  set sorobanMeta(XdrSorobanTransactionMeta? value) =>
      this._sorobanMeta = value;

  XdrTransactionMetaV3(this._ext, this._txChangesBefore, this._operations,
      this._txChangesAfter, this._sorobanMeta);

  static void encode(XdrDataOutputStream stream, XdrTransactionMetaV3 encoded) {
    XdrExtensionPoint.encode(stream, encoded.ext);
    XdrLedgerEntryChanges.encode(stream, encoded._txChangesBefore);
    int operationsSize = encoded.operations.length;
    stream.writeInt(operationsSize);
    for (int i = 0; i < operationsSize; i++) {
      XdrOperationMeta.encode(stream, encoded._operations[i]);
    }

    XdrLedgerEntryChanges.encode(stream, encoded._txChangesAfter);

    if (encoded.sorobanMeta != null) {
      stream.writeInt(1);
      XdrSorobanTransactionMeta.encode(stream, encoded.sorobanMeta!);
    } else {
      stream.writeInt(0);
    }
  }

  static XdrTransactionMetaV3 decode(XdrDataInputStream stream) {
    XdrExtensionPoint ext = XdrExtensionPoint.decode(stream);
    XdrLedgerEntryChanges txChangesBefore =
        XdrLedgerEntryChanges.decode(stream);
    int operationsSize = stream.readInt();
    List<XdrOperationMeta> operations =
        List<XdrOperationMeta>.empty(growable: true);
    for (int i = 0; i < operationsSize; i++) {
      operations.add(XdrOperationMeta.decode(stream));
    }
    XdrLedgerEntryChanges txChangesAfter = XdrLedgerEntryChanges.decode(stream);

    XdrSorobanTransactionMeta? sorobanMeta;
    int present = stream.readInt();
    if (present != 0) {
      sorobanMeta = XdrSorobanTransactionMeta.decode(stream);
    }

    return XdrTransactionMetaV3(
        ext, txChangesBefore, operations, txChangesAfter, sorobanMeta);
  }
}
