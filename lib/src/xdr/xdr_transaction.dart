// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_memo.dart';
import 'xdr_muxed_account.dart';
import 'xdr_operation.dart';
import 'xdr_preconditions.dart';
import 'xdr_sequence_number.dart';
import 'xdr_transaction_ext.dart';
import 'xdr_uint32.dart';

class XdrTransaction {
  XdrTransaction(this._sourceAccount, this._fee, this._seqNum, this._cond,
      this._memo, this._operations, this._ext);
  XdrMuxedAccount _sourceAccount;
  XdrMuxedAccount get sourceAccount => this._sourceAccount;
  set sourceAccount(XdrMuxedAccount value) => this._sourceAccount = value;

  XdrUint32 _fee;
  XdrUint32 get fee => this._fee;
  set fee(XdrUint32 value) => this._fee = value;

  XdrSequenceNumber _seqNum;
  XdrSequenceNumber get seqNum => this._seqNum;
  set seqNum(XdrSequenceNumber value) => this._seqNum = value;

  XdrPreconditions _cond;
  XdrPreconditions get preconditions => this._cond;
  set preconditions(XdrPreconditions value) => this._cond = value;

  XdrMemo _memo;
  XdrMemo get memo => this._memo;
  set memo(XdrMemo value) => this._memo = value;

  List<XdrOperation> _operations;
  List<XdrOperation> get operations => this._operations;
  set operations(List<XdrOperation> value) => this._operations = value;

  XdrTransactionExt _ext;
  XdrTransactionExt get ext => this._ext;
  set ext(XdrTransactionExt value) => this._ext = value;

  static void encode(
      XdrDataOutputStream stream, XdrTransaction encodedTransaction) {
    XdrMuxedAccount.encode(stream, encodedTransaction._sourceAccount);
    XdrUint32.encode(stream, encodedTransaction._fee);
    XdrSequenceNumber.encode(stream, encodedTransaction._seqNum);
    XdrPreconditions.encode(stream, encodedTransaction._cond);
    XdrMemo.encode(stream, encodedTransaction._memo);
    int operationsSize = encodedTransaction.operations.length;
    stream.writeInt(operationsSize);
    for (int i = 0; i < operationsSize; i++) {
      XdrOperation.encode(stream, encodedTransaction._operations[i]);
    }
    XdrTransactionExt.encode(stream, encodedTransaction._ext);
  }

  static XdrTransaction decode(XdrDataInputStream stream) {
    XdrMuxedAccount sourceAccount = XdrMuxedAccount.decode(stream);
    XdrUint32 fee = XdrUint32.decode(stream);
    XdrSequenceNumber seqNum = XdrSequenceNumber.decode(stream);
    XdrPreconditions cond = XdrPreconditions.decode(stream);
    XdrMemo memo = XdrMemo.decode(stream);
    int operationsSize = stream.readInt();
    List<XdrOperation> operations = List<XdrOperation>.empty(growable: true);
    for (int i = 0; i < operationsSize; i++) {
      operations.add(XdrOperation.decode(stream));
    }
    XdrTransactionExt ext = XdrTransactionExt.decode(stream);
    return XdrTransaction(
        sourceAccount, fee, seqNum, cond, memo, operations, ext);
  }
}
