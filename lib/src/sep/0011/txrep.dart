// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import '../../transaction.dart';
import '../../memo.dart';
import '../../price.dart';
import '../../operation.dart';
import '../../util.dart';
import '../../key_pair.dart';
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
    _addSignatures(transaction.signatures, lines);
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
    } else if (operation is PathPaymentStrictReceiveOperation) {
      _addLine('$prefix.sendAsset', encodeAsset(operation.sendAsset), lines);
      _addLine('$prefix.sendMax', toAmount(operation.sendMax), lines);
      _addLine('$prefix.destination', operation.destination.accountId, lines);
      _addLine('$prefix.destAsset', encodeAsset(operation.destAsset), lines);
      _addLine('$prefix.destAmount', toAmount(operation.destAmount), lines);
      _addLine('$prefix.path.len', operation.path.length.toString(), lines);
      int assetIndex = 0;
      for (Asset asset in operation.path) {
        _addLine('$prefix.path[$assetIndex]', encodeAsset(asset), lines);
        assetIndex++;
      }
    } else if (operation is PathPaymentStrictSendOperation) {
      _addLine('$prefix.sendAsset', encodeAsset(operation.sendAsset), lines);
      _addLine('$prefix.sendAmount', toAmount(operation.sendAmount), lines);
      _addLine('$prefix.destination', operation.destination.accountId, lines);
      _addLine('$prefix.destAsset', encodeAsset(operation.destAsset), lines);
      _addLine('$prefix.destMin', toAmount(operation.destMin), lines);
      _addLine('$prefix.path.len', operation.path.length.toString(), lines);
      int assetIndex = 0;
      for (Asset asset in operation.path) {
        _addLine('$prefix.path[$assetIndex]', encodeAsset(asset), lines);
        assetIndex++;
      }
    } else if (operation is ManageSellOfferOperation) {
      _addLine('$prefix.selling', encodeAsset(operation.selling), lines);
      _addLine('$prefix.buying', encodeAsset(operation.buying), lines);
      _addLine('$prefix.amount', toAmount(operation.amount), lines);
      Price price = Price.fromString(operation.price);
      _addLine('$prefix.price.n', price.n.toString(), lines);
      _addLine('$prefix.price.d', price.d.toString(), lines);
      _addLine('$prefix.offerID', operation.offerId, lines);
    } else if (operation is CreatePassiveSellOfferOperation) {
      _addLine('$prefix.selling', encodeAsset(operation.selling), lines);
      _addLine('$prefix.buying', encodeAsset(operation.buying), lines);
      _addLine('$prefix.amount', toAmount(operation.amount), lines);
      Price price = Price.fromString(operation.price);
      _addLine('$prefix.price.n', price.n.toString(), lines);
      _addLine('$prefix.price.d', price.d.toString(), lines);
    } else if (operation is SetOptionsOperation) {
      if (operation.inflationDestination != null) {
        _addLine('$prefix.inflationDest._present', 'true', lines);
        _addLine(
            '$prefix.inflationDest', operation.inflationDestination, lines);
      } else {
        _addLine('$prefix.inflationDest._present', 'false', lines);
      }
      if (operation.clearFlags != null) {
        _addLine('$prefix.clearFlags._present', 'true', lines);
        _addLine('$prefix.clearFlags', operation.clearFlags.toString(), lines);
      } else {
        _addLine('$prefix.clearFlags._present', 'false', lines);
      }
      if (operation.setFlags != null) {
        _addLine('$prefix.setFlags._present', 'true', lines);
        _addLine('$prefix.setFlags', operation.setFlags.toString(), lines);
      } else {
        _addLine('$prefix.setFlags._present', 'false', lines);
      }
      if (operation.masterKeyWeight != null) {
        _addLine('$prefix.masterWeight._present', 'true', lines);
        _addLine('$prefix.masterWeight', operation.masterKeyWeight.toString(),
            lines);
      } else {
        _addLine('$prefix.masterWeight._present', 'false', lines);
      }
      if (operation.lowThreshold != null) {
        _addLine('$prefix.lowThreshold._present', 'true', lines);
        _addLine(
            '$prefix.lowThreshold', operation.lowThreshold.toString(), lines);
      } else {
        _addLine('$prefix.lowThreshold._present', 'false', lines);
      }
      if (operation.mediumThreshold != null) {
        _addLine('$prefix.medThreshold._present', 'true', lines);
        _addLine('$prefix.medThreshold', operation.mediumThreshold.toString(),
            lines);
      } else {
        _addLine('$prefix.medThreshold._present', 'false', lines);
      }
      if (operation.highThreshold != null) {
        _addLine('$prefix.highThreshold._present', 'true', lines);
        _addLine(
            '$prefix.highThreshold', operation.highThreshold.toString(), lines);
      } else {
        _addLine('$prefix.highThreshold._present', 'false', lines);
      }
      if (operation.homeDomain != null) {
        final jsonEncoder = JsonEncoder();
        _addLine('$prefix.homeDomain._present', 'true', lines);
        _addLine(
            '$prefix.homeDomain',
            jsonEncoder.convert(operation.homeDomain),
            lines); // TODO utf-8 + escape
      } else {
        _addLine('$prefix.homeDomain._present', 'false', lines);
      }
      if (operation.signer != null) {
        _addLine('$prefix.signer._present', 'true', lines);
        if (operation.signer.ed25519 != null) {
          _addLine(
              '$prefix.signer.key',
              StrKey.encodeStellarAccountId(operation.signer.ed25519.uint256),
              lines);
        } else if (operation.signer.preAuthTx != null) {
          _addLine(
              '$prefix.signer.key',
              StrKey.encodePreAuthTx(operation.signer.preAuthTx.uint256),
              lines);
        } else if (operation.signer.hashX != null) {
          _addLine('$prefix.signer.key',
              StrKey.encodePreAuthTx(operation.signer.hashX.uint256), lines);
        }
      } else {
        _addLine('$prefix.signer._present', 'false', lines);
      }
    } else if (operation is ChangeTrustOperation) {
      _addLine('$prefix.line', encodeAsset(operation.asset), lines);
      if (operation.limit != null) {
        _addLine('$prefix.limit._present', 'true', lines);
        _addLine('$prefix.limit', operation.limit, lines);
      } else {
        _addLine('$prefix.limit._present', 'false', lines);
      }
    } else if (operation is AllowTrustOperation) {
      _addLine('$prefix.trustor', operation.trustor, lines);
      _addLine('$prefix.asset', operation.assetCode, lines);
      _addLine('$prefix.authorize', operation.authorize.toString(), lines);
      _addLine('$prefix.authorizeToMaintainLiabilities',
          operation.authorizeToMaintainLiabilities.toString(), lines);
    } else if (operation is AllowTrustOperation) {
      _addLine('$prefix.trustor', operation.trustor, lines);
      _addLine('$prefix.asset', operation.assetCode, lines);
      _addLine('$prefix.authorize', operation.authorize.toString(), lines);
      _addLine('$prefix.authorizeToMaintainLiabilities',
          operation.authorizeToMaintainLiabilities.toString(), lines);
    } else if (operation is AccountMergeOperation) {
      // account merge does not include 'accountMergeOp' prefix
      _addLine('tx.operation[$index].body.destination',
          operation.destination.accountId, lines);
    } else if (operation is ManageDataOperation) {
      _addLine('$prefix.dataName', operation.name, lines);
      if (operation.value != null) {
        _addLine('$prefix.dataValue._present', 'true', lines);
        _addLine('$prefix.dataValue', Util.bytesToHex(operation.value), lines);
      } else {
        _addLine('$prefix.dataValue._present', 'false', lines);
      }
    } else if (operation is BumpSequenceOperation) {
      _addLine('$prefix.bumpTo', operation.bumpTo.toString(), lines);
    } else if (operation is ManageBuyOfferOperation) {
      _addLine('$prefix.selling', encodeAsset(operation.selling), lines);
      _addLine('$prefix.buying', encodeAsset(operation.buying), lines);
      _addLine('$prefix.buyAmount', toAmount(operation.amount), lines);
      Price price = Price.fromString(operation.price);
      _addLine('$prefix.price.n', price.n.toString(), lines);
      _addLine('$prefix.price.d', price.d.toString(), lines);
      _addLine('$prefix.offerID', operation.offerId, lines);
    }
  }

  static _addSignatures(
      List<XdrDecoratedSignature> signatures, List<String> lines) {
    if (lines == null) return;
    if (signatures == null) {
      _addLine('tx.signatures.len', '0', lines);
      return;
    }
    _addLine('tx.signatures.len', signatures.length.toString(), lines);
    int index = 0;
    for (XdrDecoratedSignature sig in signatures) {
      _addSignature(sig, index, lines);
      index++;
    }
  }

  static _addSignature(
      XdrDecoratedSignature signature, int index, List<String> lines) {
    if (lines == null || signature == null) return;
    _addLine('tx.signatures[$index].hint',
        Util.bytesToHex(signature.hint.signatureHint), lines);
    _addLine('tx.signatures[$index].signature',
        Util.bytesToHex(signature.signature.signature), lines);
  }
}
