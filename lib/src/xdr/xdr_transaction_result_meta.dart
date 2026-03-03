// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_ledger_entry_changes.dart';
import 'xdr_transaction_meta.dart';
import 'xdr_transaction_result_pair.dart';

class XdrTransactionResultMeta {
  XdrTransactionResultPair _result;
  XdrTransactionResultPair get result => this._result;
  set result(XdrTransactionResultPair value) => this._result = value;

  XdrLedgerEntryChanges _feeProcessing;
  XdrLedgerEntryChanges get feeProcessing => this._feeProcessing;
  set feeProcessing(XdrLedgerEntryChanges value) => this._feeProcessing = value;

  XdrTransactionMeta _txApplyProcessing;
  XdrTransactionMeta get txApplyProcessing => this._txApplyProcessing;
  set txApplyProcessing(XdrTransactionMeta value) =>
      this._txApplyProcessing = value;

  XdrTransactionResultMeta(
    this._result,
    this._feeProcessing,
    this._txApplyProcessing,
  );

  static void encode(
    XdrDataOutputStream stream,
    XdrTransactionResultMeta encodedTransactionResultMeta,
  ) {
    XdrTransactionResultPair.encode(
      stream,
      encodedTransactionResultMeta.result,
    );
    XdrLedgerEntryChanges.encode(
      stream,
      encodedTransactionResultMeta.feeProcessing,
    );
    XdrTransactionMeta.encode(
      stream,
      encodedTransactionResultMeta.txApplyProcessing,
    );
  }

  static XdrTransactionResultMeta decode(XdrDataInputStream stream) {
    XdrTransactionResultPair result = XdrTransactionResultPair.decode(stream);
    XdrLedgerEntryChanges feeProcessing = XdrLedgerEntryChanges.decode(stream);
    XdrTransactionMeta txApplyProcessing = XdrTransactionMeta.decode(stream);
    return XdrTransactionResultMeta(result, feeProcessing, txApplyProcessing);
  }
}
