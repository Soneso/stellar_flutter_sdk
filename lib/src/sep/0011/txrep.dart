// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:stellar_flutter_sdk/src/xdr/xdr_operation.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import '../../transaction.dart';
import '../../memo.dart';
import '../../operation.dart';
import 'txrep_utils.dart';

class TxRep {
  static String toTxRep(AbstractTransaction tx) {
    if (tx == null) {
      return null;
    }

    Transaction transaction = tx is Transaction
        ? tx
        : tx is FeeBumpTransaction ? tx.innerTransaction : null;

    if (transaction == null) {
      return null;
    }

    List<String> lines = List<String>();
    _addLine(
        'type',
        tx is Transaction ? 'ENVELOPE_TYPE_TX' : 'ENVELOPE_TYPE_TX_FEE_BUMP',
        lines);
    _addLine('tx.sourceAccount', transaction.sourceAccount.accountId, lines);
    _addLine('tx.fee', transaction.fee.toString(), lines);
    _addLine('tx.seqNum', transaction.sequenceNumber.toString(), lines);
    _addTimeBounds(transaction.timeBounds, lines);
    _addMemo(transaction.memo, lines);
    _addOperations(transaction.operations, lines);
    _addLine('tx.ext.v', '0', lines);

    return lines.join('\n');
  }

  static _addLine(String key, String value, List<String> lines) {
    if (key != null && value != null && lines != null) {
      lines.add('$key: $value');
    }
  }

  static _addTimeBounds(TimeBounds timeBounds, List<String> lines) {
    if (lines == null) return;
    if (timeBounds == null) {
      _addLine('tx.timeBounds._present', 'false', lines);
    } else {
      _addLine('tx.timeBounds._present', 'true', lines);
      _addLine('tx.timeBounds.minTime', timeBounds.minTime.toString(), lines);
      _addLine('tx.timeBounds.maxTime', timeBounds.maxTime.toString(), lines);
    }
  }

  static _addMemo(Memo memo, List<String> lines) {
    if (lines == null || memo == null) return;
    if (memo is MemoNone) {
      _addLine('tx.memo.type', 'MEMO_NONE', lines);
    } else if (memo is MemoText) {
      final jsonEncoder = JsonEncoder();
      _addLine('tx.memo.type', 'MEMO_TEXT', lines);
      _addLine('tx.memo.text', jsonEncoder.convert(memo.text),
          lines); // TODO utf-8 + escape
    } else if (memo is MemoId) {
      _addLine('tx.memo.type', 'MEMO_ID', lines);
      _addLine('tx.memo.id', memo.getId().toString(), lines);
    } else if (memo is MemoHash) {
      _addLine('tx.memo.type', 'MEMO_HASH', lines);
      _addLine('tx.memo.hash', memo.hexValue, lines);
    } else if (memo is MemoReturnHash) {
      _addLine('tx.memo.type', 'MEMO_RETURN', lines);
      _addLine('tx.memo.retHash', memo.hexValue, lines);
    }
  }

  static _addOperations(List<Operation> operations, List<String> lines) {
    if (lines == null) return;
    if (operations == null) {
      _addLine('tx.operations.len', '0', lines);
      return;
    }
    _addLine('tx.operations.len', operations.length.toString(), lines);
    int index = 0;
    for (Operation op in operations) {
      _addOperation(op, index, lines);
      index++;
    }
  }

  static _addOperation(Operation operation, int index, List<String> lines) {
    if (lines == null || operation == null) return;

    if (operation.sourceAccount != null) {
      _addLine('tx.operation[$index].sourceAccount._present', 'true', lines);
      _addLine('tx.operation[$index].sourceAccount',
          operation.sourceAccount.accountId, lines);
    } else {
      _addLine('tx.operation[$index].sourceAccount._present', 'false', lines);
    }

    _addLine('tx.operation[$index].body.type', txRepOpTypeUpperCase(operation),
        lines);
    String prefix = 'tx.operation[$index].body.${txRepOpType(operation)}';

    if (operation is CreateAccountOperation) {
      _addLine('$prefix.destination', operation.destination, lines);
      _addLine('$prefix.startingBalance', toAmount(operation.startingBalance),
          lines);
    } else if (operation is PaymentOperation) {
      _addLine('$prefix.destination', operation.destination.accountId, lines);
      _addLine('$prefix.asset', encodeAsset(operation.asset), lines);
      _addLine('$prefix.amount', toAmount(operation.amount), lines);
    }
  }
}
