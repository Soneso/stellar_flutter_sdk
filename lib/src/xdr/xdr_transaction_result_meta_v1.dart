// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_extension_point.dart';
import 'xdr_ledger_entry_changes.dart';
import 'xdr_transaction_meta.dart';
import 'xdr_transaction_result_pair.dart';

class XdrTransactionResultMetaV1 {

  XdrExtensionPoint _ext;
  XdrExtensionPoint get ext => this._ext;
  set ext(XdrExtensionPoint value) => this._ext = value;

  XdrTransactionResultPair _result;
  XdrTransactionResultPair get result => this._result;
  set result(XdrTransactionResultPair value) => this._result = value;

  XdrLedgerEntryChanges _feeProcessing;
  XdrLedgerEntryChanges get feeProcessing => this._feeProcessing;
  set feeProcessing(XdrLedgerEntryChanges value) => this._feeProcessing = value;

  XdrTransactionMeta _txApplyProcessing;
  XdrTransactionMeta get txApplyProcessing => this._txApplyProcessing;
  set txApplyProcessing(XdrTransactionMeta value) => this._txApplyProcessing = value;

  XdrLedgerEntryChanges _postTxApplyFeeProcessing;
  XdrLedgerEntryChanges get postTxApplyFeeProcessing => this._postTxApplyFeeProcessing;
  set postTxApplyFeeProcessing(XdrLedgerEntryChanges value) => this._postTxApplyFeeProcessing = value;

  XdrTransactionResultMetaV1(this._ext, this._result, this._feeProcessing, this._txApplyProcessing, this._postTxApplyFeeProcessing);

  static void encode(XdrDataOutputStream stream, XdrTransactionResultMetaV1 encodedTransactionResultMetaV1) {
    XdrExtensionPoint.encode(stream, encodedTransactionResultMetaV1.ext);
    XdrTransactionResultPair.encode(stream, encodedTransactionResultMetaV1.result);
    XdrLedgerEntryChanges.encode(stream, encodedTransactionResultMetaV1.feeProcessing);
    XdrTransactionMeta.encode(stream, encodedTransactionResultMetaV1.txApplyProcessing);
    XdrLedgerEntryChanges.encode(stream, encodedTransactionResultMetaV1.postTxApplyFeeProcessing);
  }

  static XdrTransactionResultMetaV1 decode(XdrDataInputStream stream) {
    XdrExtensionPoint ext = XdrExtensionPoint.decode(stream);
    XdrTransactionResultPair result = XdrTransactionResultPair.decode(stream);
    XdrLedgerEntryChanges feeProcessing = XdrLedgerEntryChanges.decode(stream);
    XdrTransactionMeta txApplyProcessing = XdrTransactionMeta.decode(stream);
    XdrLedgerEntryChanges postTxApplyFeeProcessing = XdrLedgerEntryChanges.decode(stream);
    return XdrTransactionResultMetaV1(ext, result, feeProcessing, txApplyProcessing, postTxApplyFeeProcessing);
  }
}
