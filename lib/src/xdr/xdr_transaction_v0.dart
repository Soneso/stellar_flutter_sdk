// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_memo.dart';
import 'xdr_operation.dart';
import 'xdr_sequence_number.dart';
import 'xdr_time_bounds.dart';
import 'xdr_transaction_v0_ext.dart';
import 'xdr_uint256.dart';
import 'xdr_uint32.dart';

class XdrTransactionV0 {
  XdrTransactionV0(
    this._sourceAccountEd25519,
    this._fee,
    this._seqNum,
    this._timeBounds,
    this._memo,
    this._operations,
    this._ext,
  );
  XdrUint256 _sourceAccountEd25519;
  XdrUint256 get sourceAccountEd25519 => this._sourceAccountEd25519;
  set sourceAccountEd25519(XdrUint256 value) =>
      this._sourceAccountEd25519 = value;

  XdrUint32 _fee;
  XdrUint32 get fee => this._fee;
  set fee(XdrUint32 value) => this._fee = value;

  XdrSequenceNumber _seqNum;
  XdrSequenceNumber get seqNum => this._seqNum;
  set seqNum(XdrSequenceNumber value) => this._seqNum = value;

  XdrTimeBounds? _timeBounds;
  XdrTimeBounds? get timeBounds => this._timeBounds;
  set timeBounds(XdrTimeBounds? value) => this._timeBounds = value;

  XdrMemo _memo;
  XdrMemo get memo => this._memo;
  set memo(XdrMemo value) => this._memo = value;

  List<XdrOperation> _operations;
  List<XdrOperation> get operations => this._operations;
  set operations(List<XdrOperation> value) => this._operations = value;

  XdrTransactionV0Ext _ext;
  XdrTransactionV0Ext get ext => this._ext;
  set ext(XdrTransactionV0Ext value) => this._ext = value;

  static void encode(
    XdrDataOutputStream stream,
    XdrTransactionV0 encodedTransaction,
  ) {
    XdrUint256.encode(stream, encodedTransaction._sourceAccountEd25519);
    XdrUint32.encode(stream, encodedTransaction._fee);
    XdrSequenceNumber.encode(stream, encodedTransaction._seqNum);
    if (encodedTransaction._timeBounds != null) {
      stream.writeInt(1);
      XdrTimeBounds.encode(stream, encodedTransaction._timeBounds!);
    } else {
      stream.writeInt(0);
    }
    XdrMemo.encode(stream, encodedTransaction._memo);
    int operationsSize = encodedTransaction.operations.length;
    stream.writeInt(operationsSize);
    for (int i = 0; i < operationsSize; i++) {
      XdrOperation.encode(stream, encodedTransaction._operations[i]);
    }
    XdrTransactionV0Ext.encode(stream, encodedTransaction._ext);
  }

  static XdrTransactionV0 decode(XdrDataInputStream stream) {
    XdrUint256 sourceAccountEd25519 = XdrUint256.decode(stream);
    XdrUint32 fee = XdrUint32.decode(stream);
    XdrSequenceNumber seqNum = XdrSequenceNumber.decode(stream);
    XdrTimeBounds? timeBounds;
    int timeBoundsPresent = stream.readInt();
    if (timeBoundsPresent != 0) {
      timeBounds = XdrTimeBounds.decode(stream);
    }
    XdrMemo memo = XdrMemo.decode(stream);

    int operationsSize = stream.readInt();
    List<XdrOperation> operations = List<XdrOperation>.empty(growable: true);
    for (int i = 0; i < operationsSize; i++) {
      operations.add(XdrOperation.decode(stream));
    }

    XdrTransactionV0Ext ext = XdrTransactionV0Ext.decode(stream);
    return XdrTransactionV0(
      sourceAccountEd25519,
      fee,
      seqNum,
      timeBounds,
      memo,
      operations,
      ext,
    );
  }
}
