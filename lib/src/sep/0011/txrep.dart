// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';
import 'package:decimal/decimal.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import '../../transaction.dart';
import '../../memo.dart';
import '../../price.dart';
import '../../operation.dart';
import '../../util.dart';
import '../../key_pair.dart';

class TxRep {
  /// returns returns txrep by by parsing a base64 encoded transaction envelope xdr [transactionEnvelopeXdrBase64].
  static String fromTransactionEnvelopeXdrBase64(
      String transactionEnvelopeXdrBase64) {
    if (transactionEnvelopeXdrBase64 == null) {
      throw Exception('transactionEnvelopeXdrBase64 can not be null');
    }

    XdrTransactionEnvelope envelopeXdr =
        XdrTransactionEnvelope.fromEnvelopeXdrString(
            transactionEnvelopeXdrBase64);

    Transaction tx;
    FeeBumpTransaction feeBump;
    List<XdrDecoratedSignature> feeBumpSignatures;
    switch (envelopeXdr.discriminant) {
      case XdrEnvelopeType.ENVELOPE_TYPE_TX_V0:
        tx = Transaction.fromV0EnvelopeXdr(envelopeXdr.v0);
        break;
      case XdrEnvelopeType.ENVELOPE_TYPE_TX:
        tx = Transaction.fromV1EnvelopeXdr(envelopeXdr.v1);
        break;
      case XdrEnvelopeType.ENVELOPE_TYPE_TX_FEE_BUMP:
        feeBump = FeeBumpTransaction.fromFeeBumpTransactionEnvelope(
            envelopeXdr.feeBump);
        tx = feeBump.innerTransaction;
        feeBumpSignatures = envelopeXdr.feeBump.signatures;
        break;
    }

    bool isFeeBump = feeBump != null;

    List<String> lines = List<String>();
    String type = isFeeBump ? 'ENVELOPE_TYPE_TX_FEE_BUMP' : 'ENVELOPE_TYPE_TX';
    String prefix = isFeeBump ? 'feeBump.tx.innerTx.tx.' : 'tx.';

    _addLine('type', type, lines);

    if (isFeeBump) {
      _addLine('feeBump.tx.feeSource', feeBump.feeAccount.accountId, lines);
      _addLine('feeBump.tx.fee', feeBump.fee.toString(), lines);
      _addLine('feeBump.tx.innerTx.type', 'ENVELOPE_TYPE_TX', lines);
    }

    _addLine('${prefix}sourceAccount', tx.sourceAccount.accountId, lines);
    _addLine('${prefix}fee', tx.fee.toString(), lines);

    _addLine('${prefix}seqNum', tx.sequenceNumber.toString(), lines);
    _addTimeBounds(tx.timeBounds, lines, prefix);
    _addMemo(tx.memo, lines, prefix);
    _addOperations(tx.operations, lines, prefix);
    _addLine('${prefix}ext.v', '0', lines);
    _addSignatures(
        tx.signatures, lines, isFeeBump ? 'feeBump.tx.innerTx.' : "");
    if (isFeeBump) {
      _addLine('feeBump.tx.ext.v', '0', lines);
      _addSignatures(feeBumpSignatures, lines, 'feeBump.');
    }
    return lines.join('\n');
  }

  /// returns a base64 encoded transaction envelope xdr by parsing [txRep].
  static String transactionEnvelopeXdrBase64FromTxRep(String txRep) {
    if (txRep == null) {
      throw Exception('txRep can not be null');
    }
    List<String> lines = txRep.split('\n'); //TODO: handle newline within string
    Map<String, String> map = Map<String, String>();
    for (String line in lines) {
      var parts = line.split(':');
      if (parts.length > 1) {
        String key = parts[0].trim();
        String value = parts.sublist(1).join(':').trim();
        map.addAll({key: value});
      }
    }
    String prefix = 'tx.';
    bool isFeeBump = _removeComment(map['type']) == 'ENVELOPE_TYPE_TX_FEE_BUMP';
    int feeBumpFee;
    String feeBumpSource = _removeComment(map['feeBump.tx.feeSource']);

    if (isFeeBump) {
      prefix = 'feeBump.tx.innerTx.tx.';
      String feeBumpFeeStr = _removeComment(map['feeBump.tx.fee']);
      if (feeBumpFeeStr == null) {
        throw Exception('missing feeBump.tx.fee');
      }
      try {
        feeBumpFee = int.parse(feeBumpFeeStr);
      } catch (e) {
        throw Exception('invalid feeBump.tx.fee');
      }
      if (feeBumpFee == null) {
        throw Exception('invalid feeBump.tx.fee');
      }

      if (feeBumpSource == null) {
        throw Exception('missing feeBump.tx.feeSource');
      }
      KeyPair feeBumpSourceKeyPair;
      try {
        feeBumpSourceKeyPair = KeyPair.fromAccountId(feeBumpSource);
      } catch (e) {
        throw Exception('invalid feeBump.tx.feeSource');
      }
      if (feeBumpSourceKeyPair == null) {
        throw Exception('invalid feeBump.tx.feeSource');
      }
    }

    String sourceAccountId = _removeComment(map['${prefix}sourceAccount']);
    if (sourceAccountId == null) {
      throw Exception('missing ${prefix}sourceAccount');
    }
    String feeStr = _removeComment(map['${prefix}fee']);
    int fee;
    if (feeStr == null) {
      throw Exception('missing ${prefix}fee');
    } else {
      try {
        fee = int.parse(feeStr);
      } catch (e) {
        throw Exception('invalid ${prefix}fee');
      }
    }
    if (fee == null) {
      throw Exception('invalid ${prefix}fee');
    }

    String seqNr = _removeComment(map['${prefix}seqNum']);
    int sequenceNumber;
    if (seqNr == null) {
      throw Exception('missing ${prefix}seqNum');
    } else {
      try {
        sequenceNumber = int.parse(seqNr);
      } catch (e) {
        throw Exception('invalid ${prefix}seqNum');
      }
    }
    if (sequenceNumber == null) {
      throw Exception('invalid ${prefix}seqNum');
    }

    if (sourceAccountId == null) {
      throw Exception('invalid ${prefix}sourceAccount');
    }
    try {
      KeyPair.fromAccountId(sourceAccountId);
    } catch (e) {
      throw Exception('invalid ${prefix}sourceAccount');
    }

    MuxedAccount mux = MuxedAccount.fromAccountId(sourceAccountId);
    Account sourceAccount = Account(mux.ed25519AccountId, sequenceNumber - 1,
        muxedAccountMed25519Id: mux.id);
    TransactionBuilder txBuilder = TransactionBuilder(sourceAccount);

    // TimeBounds
    if (_removeComment(map['${prefix}timeBounds._present']) == 'true' &&
        map['${prefix}timeBounds.minTime'] != null &&
        map['${prefix}timeBounds.maxTime'] != null) {
      try {
        int minTime =
            int.parse(_removeComment(map['${prefix}timeBounds.minTime']));
        int maxTime =
            int.parse(_removeComment(map['${prefix}timeBounds.maxTime']));
        TimeBounds timeBounds = TimeBounds(minTime, maxTime);
        txBuilder.addTimeBounds(timeBounds);
      } catch (e) {
        throw Exception('invalid ${prefix}timeBounds');
      }
    } else if (_removeComment(map['${prefix}timeBounds._present']) == 'true') {
      throw Exception('invalid ${prefix}timeBounds');
    }

    // Memo
    String memoType = _removeComment(map['${prefix}memo.type']);
    if (memoType == null) {
      throw Exception('missing ${prefix}memo.type');
    }
    try {
      if (memoType == 'MEMO_TEXT' && map['${prefix}memo.text'] != null) {
        txBuilder.addMemo(MemoText(
            _removeComment(map['${prefix}memo.text']).replaceAll('"', '')));
      } else if (memoType == 'MEMO_ID' && map['${prefix}memo.id'] != null) {
        txBuilder.addMemo(
            MemoId(int.parse(_removeComment(map['${prefix}memo.id']))));
      } else if (memoType == 'MEMO_HASH' && map['${prefix}memo.hash'] != null) {
        txBuilder.addMemo(MemoHash(
            Util.hexToBytes(_removeComment(map['${prefix}memo.hash']))));
      } else if (memoType == 'MEMO_RETURN' &&
          map['${prefix}memo.return'] != null) {
        txBuilder.addMemo(
            MemoReturnHash.string(_removeComment(map['${prefix}memo.return'])));
      } else {
        txBuilder.addMemo(MemoNone());
      }
    } catch (e) {
      throw Exception('invalid ${prefix}memo');
    }

    // Operations
    String operationsLen = _removeComment(map['${prefix}operations.len']);
    if (operationsLen == null) {
      throw Exception('missing ${prefix}operations.len');
    }
    int nrOfOperations;
    try {
      nrOfOperations = int.parse(operationsLen);
    } catch (e) {
      throw Exception('invalid ${prefix}operations.len');
    }
    if (nrOfOperations > 100) {
      throw Exception('invalid ${prefix}operations.len - greater than 100');
    }

    for (int i = 0; i < nrOfOperations; i++) {
      Operation operation = _getOperation(i, map, prefix);
      if (operation != null) {
        txBuilder.addOperation(operation);
      }
    }
    int maxOperationFee = (fee.toDouble() / nrOfOperations.toDouble()).round();
    txBuilder.setMaxOperationFee(maxOperationFee);
    AbstractTransaction transaction = txBuilder.build();

    // Signatures
    prefix = isFeeBump ? 'feeBump.tx.innerTx.' : "";
    String signaturesLen = _removeComment(map['${prefix}signatures.len']);
    if (signaturesLen != null) {
      int nrOfSignatures;
      try {
        nrOfSignatures = int.parse(signaturesLen);
      } catch (e) {
        throw Exception('invalid ${prefix}signatures.len');
      }
      if (nrOfSignatures > 20) {
        throw Exception('invalid ${prefix}signatures.len - greater than 20');
      }
      List<XdrDecoratedSignature> signatures = List<XdrDecoratedSignature>();
      for (int i = 0; i < nrOfSignatures; i++) {
        XdrDecoratedSignature signature = _getSignature(i, map, prefix);
        if (signature != null) {
          signatures.add(signature);
        }
      }
      transaction.signatures = signatures;
    }
    if (isFeeBump) {
      FeeBumpTransactionBuilder builder =
          FeeBumpTransactionBuilder(transaction);
      int baseFee =
          (feeBumpFee.toDouble() / (nrOfOperations + 1).toDouble()).round();
      builder.setBaseFee(baseFee);
      builder.setMuxedFeeAccount(MuxedAccount.fromAccountId(feeBumpSource));
      FeeBumpTransaction feeBumpTransaction = builder.build();
      String fbSignaturesLen = _removeComment(map['feeBump.signatures.len']);
      if (fbSignaturesLen != null) {
        int nrOfFbSignatures;
        try {
          nrOfFbSignatures = int.parse(fbSignaturesLen);
        } catch (e) {
          throw Exception('invalid feeBump.signatures.len');
        }
        if (nrOfFbSignatures > 20) {
          throw Exception('invalid feeBump.signatures.len - greater than 20');
        }
        List<XdrDecoratedSignature> fbSignatures =
            List<XdrDecoratedSignature>();
        for (int i = 0; i < nrOfFbSignatures; i++) {
          XdrDecoratedSignature fbSignature = _getSignature(i, map, 'feeBump.');
          if (fbSignature != null) {
            fbSignatures.add(fbSignature);
          }
        }
        feeBumpTransaction.signatures = fbSignatures;
        return feeBumpTransaction.toEnvelopeXdrBase64();
      }
    }
    return transaction.toEnvelopeXdrBase64();
  }

  static XdrDecoratedSignature _getSignature(
      int index, Map<String, String> map, String prefix) {
    String hintStr = _removeComment(map['${prefix}signatures[$index].hint']);
    if (hintStr == null) {
      throw Exception('missing ${prefix}signatures[$index].hint');
    }
    String signatureStr =
        _removeComment(map['${prefix}signatures[$index].signature']);
    if (signatureStr == null) {
      throw Exception('missing ${prefix}signatures[$index].signature');
    }
    try {
      Uint8List hint = Util.hexToBytes(hintStr);
      Uint8List signature = Util.hexToBytes(signatureStr);
      XdrSignatureHint sigHint = XdrSignatureHint();
      sigHint.signatureHint = hint;
      XdrSignature sig = XdrSignature();
      sig.signature = signature;
      XdrDecoratedSignature decoratedSignature = XdrDecoratedSignature();
      decoratedSignature.hint = sigHint;
      decoratedSignature.signature = sig;
      return decoratedSignature;
    } catch (e) {
      throw Exception(
          'invalid hint or signature in ${prefix}signatures[$index]');
    }
  }

  static Operation _getOperation(
      int index, Map<String, String> map, String txPrefix) {
    String prefix = '${txPrefix}operations[$index].body.';
    String sourceAccountId;
    if (_removeComment(
            map['${txPrefix}operations[$index].sourceAccount._present']) ==
        'true') {
      sourceAccountId =
          _removeComment(map['${txPrefix}operations[$index].sourceAccount']);
      try {
        KeyPair.fromAccountId(sourceAccountId);
      } catch (e) {
        throw Exception('invalid ${txPrefix}operations[$index].sourceAccount');
      }
      if (sourceAccountId == null) {
        throw Exception('missing ${txPrefix}operations[$index].sourceAccount');
      }
    }
    String opType = _removeComment(map[prefix + 'type']);
    if (opType == null) {
      throw Exception('missing $prefix' + 'type');
    }
    if (opType == 'CREATE_ACCOUNT') {
      String opPrefix = prefix + 'createAccountOp.';
      return _getCreateAccountOperation(sourceAccountId, opPrefix, map);
    }
    if (opType == 'PAYMENT') {
      String opPrefix = prefix + 'paymentOp.';
      return _getPaymentOperation(sourceAccountId, opPrefix, map);
    }
    if (opType == 'PATH_PAYMENT_STRICT_RECEIVE') {
      String opPrefix = prefix + 'pathPaymentStrictReceiveOp.';
      return _getPathPaymentStrictReceiveOperation(
          sourceAccountId, opPrefix, map);
    }
    if (opType == 'PATH_PAYMENT_STRICT_SEND') {
      String opPrefix = prefix + 'pathPaymentStrictSendOp.';
      return _getPathPaymentStrictSendOperation(sourceAccountId, opPrefix, map);
    }
    if (opType == 'MANAGE_SELL_OFFER') {
      String opPrefix = prefix + 'manageSellOfferOp.';
      return _getManageSellOfferOperation(sourceAccountId, opPrefix, map);
    }
    if (opType == 'CREATE_PASSIVE_SELL_OFFER') {
      String opPrefix = prefix + 'createPassiveSellOfferOp.';
      return _getCreatePassiveSellOfferOperation(
          sourceAccountId, opPrefix, map);
    }
    if (opType == 'SET_OPTIONS') {
      String opPrefix = prefix + 'setOptionsOp.';
      return _getSetOptionsOperation(sourceAccountId, opPrefix, map);
    }
    if (opType == 'CHANGE_TRUST') {
      String opPrefix = prefix + 'changeTrustOp.';
      return _getChangeTrustOperation(sourceAccountId, opPrefix, map);
    }
    if (opType == 'ALLOW_TRUST') {
      String opPrefix = prefix + 'allowTrustOp.';
      return _getAllowTrustOperation(sourceAccountId, opPrefix, map);
    }
    if (opType == 'ACCOUNT_MERGE') {
      // account merge does not include 'accountMergeOp' prefix
      return _getAccountMergeOperation(sourceAccountId, index, map, txPrefix);
    }
    if (opType == 'MANAGE_DATA') {
      String opPrefix = prefix + 'manageDataOp.';
      return _getManageDataOperation(sourceAccountId, opPrefix, map);
    }
    if (opType == 'BUMP_SEQUENCE') {
      String opPrefix = prefix + 'bumpSequenceOp.';
      return _getBumpSequenceOperation(sourceAccountId, opPrefix, map);
    }
    if (opType == 'MANAGE_BUY_OFFER') {
      String opPrefix = prefix + 'manageBuyOfferOp.';
      return _getManageBuyOfferOperation(sourceAccountId, opPrefix, map);
    }
    throw Exception('invalid or unsupported [$prefix].type - $opType');
  }

  static CreateAccountOperation _getCreateAccountOperation(
      String sourceAccountId, String opPrefix, Map<String, String> map) {
    String destination = _removeComment(map[opPrefix + 'destination']);
    if (destination == null) {
      throw Exception('missing $opPrefix' + 'destination');
    }
    try {
      KeyPair.fromAccountId(destination);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'destination');
    }
    String startingBalanceValue =
        _removeComment(map[opPrefix + 'startingBalance']);
    if (startingBalanceValue == null) {
      throw Exception('missing $opPrefix' + 'startingBalance');
    }
    String startingBalance;
    try {
      startingBalance = _fromAmount(startingBalanceValue);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'startingBalance');
    }
    if (startingBalance == null) {
      throw Exception('invalid $opPrefix' + 'startingBalance');
    }
    CreateAccountOperationBuilder builder =
        CreateAccountOperationBuilder(destination, startingBalance);
    if (sourceAccountId != null) {
      builder
          .setMuxedSourceAccount(MuxedAccount.fromAccountId(sourceAccountId));
    }
    return builder.build();
  }

  static PaymentOperation _getPaymentOperation(
      String sourceAccountId, String opPrefix, Map<String, String> map) {
    String destination = _removeComment(map[opPrefix + 'destination']);
    if (destination == null) {
      throw Exception('missing $opPrefix' + 'destination');
    }
    try {
      KeyPair.fromAccountId(destination);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'destination');
    }
    String assetStr = _removeComment(map[opPrefix + 'asset']);
    if (assetStr == null) {
      throw Exception('missing $opPrefix' + 'asset');
    }
    Asset asset;
    try {
      asset = _decodeAsset(assetStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'asset');
    }
    if (asset == null) {
      throw Exception('invalid $opPrefix' + 'asset');
    }
    String amountStr = _removeComment(map[opPrefix + 'amount']);
    if (amountStr == null) {
      throw Exception('missing $opPrefix' + 'amount');
    }
    String amount;
    try {
      amount = _fromAmount(amountStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'amount');
    }
    if (amount == null) {
      throw Exception('invalid $opPrefix' + 'amount');
    }
    PaymentOperationBuilder builder =
        PaymentOperationBuilder.forMuxedDestinationAccount(
            MuxedAccount.fromAccountId(destination), asset, amount);
    if (sourceAccountId != null) {
      builder
          .setMuxedSourceAccount(MuxedAccount.fromAccountId(sourceAccountId));
    }
    return builder.build();
  }

  static PathPaymentStrictReceiveOperation
      _getPathPaymentStrictReceiveOperation(
          String sourceAccountId, String opPrefix, Map<String, String> map) {
    String sendAssetStr = _removeComment(map[opPrefix + 'sendAsset']);
    if (sendAssetStr == null) {
      throw Exception('missing $opPrefix' + 'sendAsset');
    }
    Asset sendAsset;
    try {
      sendAsset = _decodeAsset(sendAssetStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'sendAsset');
    }
    if (sendAsset == null) {
      throw Exception('invalid $opPrefix' + 'sendAsset');
    }

    String sendMaxStr = _removeComment(map[opPrefix + 'sendMax']);
    if (sendMaxStr == null) {
      throw Exception('missing $opPrefix' + 'sendMax');
    }
    String sendMax;
    try {
      sendMax = _fromAmount(sendMaxStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'sendMax');
    }
    if (sendMax == null) {
      throw Exception('invalid $opPrefix' + 'sendMax');
    }

    String destination = _removeComment(map[opPrefix + 'destination']);
    if (destination == null) {
      throw Exception('missing $opPrefix' + 'destination');
    }
    try {
      KeyPair.fromAccountId(destination);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'destination');
    }

    String destAssetStr = _removeComment(map[opPrefix + 'destAsset']);
    if (destAssetStr == null) {
      throw Exception('missing $opPrefix' + 'destAsset');
    }
    Asset destAsset;
    try {
      destAsset = _decodeAsset(destAssetStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'destAsset');
    }
    if (destAsset == null) {
      throw Exception('invalid $opPrefix' + 'destAsset');
    }

    String destAmountStr = _removeComment(map[opPrefix + 'destAmount']);
    if (destAmountStr == null) {
      throw Exception('missing $opPrefix' + 'destAmount');
    }
    String destAmount;
    try {
      destAmount = _fromAmount(destAmountStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'destAmount');
    }
    if (destAmount == null) {
      throw Exception('invalid $opPrefix' + 'destAmount');
    }

    List<Asset> path = List<Asset>();
    String pathLengthKey = opPrefix + 'path.len';
    if (map[pathLengthKey] != null) {
      int pathLen = 0;
      try {
        pathLen = int.parse(_removeComment(map[pathLengthKey]));
      } catch (e) {
        throw Exception('invalid $pathLengthKey');
      }
      if (pathLen > 5) {
        throw Exception(
            'path.len can not be greater than 5 in $pathLengthKey but is $pathLen');
      }
      for (int i = 0; i < pathLen; i++) {
        String nextAssetStr = _removeComment(map[opPrefix + 'path[$i]']);
        if (nextAssetStr == null) {
          throw Exception('missing $opPrefix' + 'path[$i]');
        }
        try {
          Asset nextAsset = _decodeAsset(nextAssetStr);
          path.add(nextAsset);
        } catch (e) {
          throw Exception('invalid $opPrefix' + 'path[$i]');
        }
      }
    }
    PathPaymentStrictReceiveOperationBuilder builder =
        PathPaymentStrictReceiveOperationBuilder.forMuxedDestinationAccount(
            sendAsset,
            sendMax,
            MuxedAccount.fromAccountId(destination),
            destAsset,
            destAmount);
    builder.setPath(path);
    if (sourceAccountId != null) {
      builder
          .setMuxedSourceAccount(MuxedAccount.fromAccountId(sourceAccountId));
    }
    return builder.build();
  }

  static PathPaymentStrictSendOperation _getPathPaymentStrictSendOperation(
      String sourceAccountId, String opPrefix, Map<String, String> map) {
    String sendAssetStr = _removeComment(map[opPrefix + 'sendAsset']);
    if (sendAssetStr == null) {
      throw Exception('missing $opPrefix' + 'sendAsset');
    }
    Asset sendAsset;
    try {
      sendAsset = _decodeAsset(sendAssetStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'sendAsset');
    }
    if (sendAsset == null) {
      throw Exception('invalid $opPrefix' + 'sendAsset');
    }

    String sendAmountStr = _removeComment(map[opPrefix + 'sendAmount']);
    if (sendAmountStr == null) {
      throw Exception('missing $opPrefix' + 'sendAmount');
    }
    String sendAmount;
    try {
      sendAmount = _fromAmount(sendAmountStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'sendAmount');
    }
    if (sendAmount == null) {
      throw Exception('invalid $opPrefix' + 'sendAmount');
    }

    String destination = _removeComment(map[opPrefix + 'destination']);
    if (destination == null) {
      throw Exception('missing $opPrefix' + 'destination');
    }
    try {
      KeyPair.fromAccountId(destination);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'destination');
    }

    String destAssetStr = _removeComment(map[opPrefix + 'destAsset']);
    if (destAssetStr == null) {
      throw Exception('missing $opPrefix' + 'destAsset');
    }
    Asset destAsset;
    try {
      destAsset = _decodeAsset(destAssetStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'destAsset');
    }
    if (destAsset == null) {
      throw Exception('invalid $opPrefix' + 'destAsset');
    }

    String destMinStr = _removeComment(map[opPrefix + 'destMin']);
    if (destMinStr == null) {
      throw Exception('missing $opPrefix' + 'destMin');
    }
    String destMin;
    try {
      destMin = _fromAmount(destMinStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'destMin');
    }
    if (destMin == null) {
      throw Exception('invalid $opPrefix' + 'destMin');
    }

    List<Asset> path = List<Asset>();
    String pathLengthKey = opPrefix + 'path.len';
    if (map[pathLengthKey] != null) {
      int pathLen = 0;
      try {
        pathLen = int.parse(_removeComment(map[pathLengthKey]));
      } catch (e) {
        throw Exception('invalid $pathLengthKey');
      }
      if (pathLen > 5) {
        throw Exception(
            'path.len can not be greater than 5 in $pathLengthKey but is $pathLen');
      }
      for (int i = 0; i < pathLen; i++) {
        String nextAssetStr = _removeComment(map[opPrefix + 'path[$i]']);
        if (nextAssetStr == null) {
          throw Exception('missing $opPrefix' + 'path[$i]');
        }
        try {
          Asset nextAsset = _decodeAsset(nextAssetStr);
          path.add(nextAsset);
        } catch (e) {
          throw Exception('invalid $opPrefix' + 'path[$i]');
        }
      }
    }
    PathPaymentStrictSendOperationBuilder builder =
        PathPaymentStrictSendOperationBuilder.forMuxedDestinationAccount(
            sendAsset,
            sendAmount,
            MuxedAccount.fromAccountId(destination),
            destAsset,
            destMin);
    builder.setPath(path);
    if (sourceAccountId != null) {
      builder
          .setMuxedSourceAccount(MuxedAccount.fromAccountId(sourceAccountId));
    }
    return builder.build();
  }

  static ManageSellOfferOperation _getManageSellOfferOperation(
      String sourceAccountId, String opPrefix, Map<String, String> map) {
    String sellingStr = _removeComment(map[opPrefix + 'selling']);
    if (sellingStr == null) {
      throw Exception('missing $opPrefix' + 'selling');
    }
    Asset selling;
    try {
      selling = _decodeAsset(sellingStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'selling');
    }
    if (selling == null) {
      throw Exception('invalid $opPrefix' + 'selling');
    }
    String buyingStr = _removeComment(map[opPrefix + 'buying']);
    if (buyingStr == null) {
      throw Exception('missing $opPrefix' + 'buying');
    }
    Asset buying;
    try {
      buying = _decodeAsset(buyingStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'buying');
    }
    if (buying == null) {
      throw Exception('invalid $opPrefix' + 'buying');
    }

    String amountStr = _removeComment(map[opPrefix + 'amount']);
    if (amountStr == null) {
      throw Exception('missing $opPrefix' + 'amount');
    }
    String amount;
    try {
      amount = _fromAmount(amountStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'amount');
    }
    if (amount == null) {
      throw Exception('invalid $opPrefix' + 'amount');
    }

    String priceNStr = _removeComment(map[opPrefix + 'price.n']);
    if (priceNStr == null) {
      throw Exception('missing $opPrefix' + 'price.n');
    }
    int n;
    try {
      n = int.parse(priceNStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'price.n');
    }
    if (n == null) {
      throw Exception('invalid $opPrefix' + 'price.n');
    }

    String priceDStr = _removeComment(map[opPrefix + 'price.d']);
    if (priceDStr == null) {
      throw Exception('missing $opPrefix' + 'price.d');
    }
    int d;
    try {
      d = int.parse(priceDStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'price.d');
    }
    if (d == null) {
      throw Exception('invalid $opPrefix' + 'price.d');
    }
    if (d == 0) {
      throw Exception(
          'price denominator can not be 0 in ' + opPrefix + 'price.d');
    }

    Decimal dec = Decimal.parse(n.toString()) / Decimal.parse(d.toString());

    String offerIdStr = _removeComment(map[opPrefix + 'offerID']);
    if (offerIdStr == null) {
      throw Exception('missing $opPrefix' + 'offerID');
    }
    int offerId;
    try {
      offerId = int.parse(offerIdStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'offerID');
    }
    if (offerId == null) {
      throw Exception('invalid $opPrefix' + 'offerID');
    }

    ManageSellOfferOperationBuilder builder = ManageSellOfferOperationBuilder(
        selling, buying, amount, dec.toString());
    builder.setOfferId(offerId.toString());
    if (sourceAccountId != null) {
      builder
          .setMuxedSourceAccount(MuxedAccount.fromAccountId(sourceAccountId));
    }
    return builder.build();
  }

  static ManageBuyOfferOperation _getManageBuyOfferOperation(
      String sourceAccountId, String opPrefix, Map<String, String> map) {
    String sellingStr = _removeComment(map[opPrefix + 'selling']);
    if (sellingStr == null) {
      throw Exception('missing $opPrefix' + 'selling');
    }
    Asset selling;
    try {
      selling = _decodeAsset(sellingStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'selling');
    }
    if (selling == null) {
      throw Exception('invalid $opPrefix' + 'selling');
    }
    String buyingStr = _removeComment(map[opPrefix + 'buying']);
    if (buyingStr == null) {
      throw Exception('missing $opPrefix' + 'buying');
    }
    Asset buying;
    try {
      buying = _decodeAsset(buyingStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'buying');
    }
    if (buying == null) {
      throw Exception('invalid $opPrefix' + 'buying');
    }

    String amountStr = _removeComment(map[opPrefix + 'buyAmount']);
    if (amountStr == null) {
      throw Exception('missing $opPrefix' + 'buyAmount');
    }
    String buyAmount;
    try {
      buyAmount = _fromAmount(amountStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'buyAmount');
    }
    if (buyAmount == null) {
      throw Exception('invalid $opPrefix' + 'buyAmount');
    }

    String priceNStr = _removeComment(map[opPrefix + 'price.n']);
    if (priceNStr == null) {
      throw Exception('missing $opPrefix' + 'price.n');
    }
    int n;
    try {
      n = int.parse(priceNStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'price.n');
    }
    if (n == null) {
      throw Exception('invalid $opPrefix' + 'price.n');
    }

    String priceDStr = _removeComment(map[opPrefix + 'price.d']);
    if (priceDStr == null) {
      throw Exception('missing $opPrefix' + 'price.d');
    }
    int d;
    try {
      d = int.parse(priceDStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'price.d');
    }
    if (d == null) {
      throw Exception('invalid $opPrefix' + 'price.d');
    }
    if (d == 0) {
      throw Exception(
          'price denominator can not be 0 in ' + opPrefix + 'price.d');
    }

    Decimal dec = Decimal.parse(n.toString()) / Decimal.parse(d.toString());

    String offerIdStr = _removeComment(map[opPrefix + 'offerID']);
    if (offerIdStr == null) {
      throw Exception('missing $opPrefix' + 'offerID');
    }
    int offerId;
    try {
      offerId = int.parse(offerIdStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'offerID');
    }
    if (offerId == null) {
      throw Exception('invalid $opPrefix' + 'offerID');
    }

    ManageBuyOfferOperationBuilder builder = ManageBuyOfferOperationBuilder(
        selling, buying, buyAmount, dec.toString());
    builder.setOfferId(offerId.toString());
    if (sourceAccountId != null) {
      builder
          .setMuxedSourceAccount(MuxedAccount.fromAccountId(sourceAccountId));
    }
    return builder.build();
  }

  static CreatePassiveSellOfferOperation _getCreatePassiveSellOfferOperation(
      String sourceAccountId, String opPrefix, Map<String, String> map) {
    String sellingStr = _removeComment(map[opPrefix + 'selling']);
    if (sellingStr == null) {
      throw Exception('missing $opPrefix' + 'selling');
    }
    Asset selling;
    try {
      selling = _decodeAsset(sellingStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'selling');
    }
    if (selling == null) {
      throw Exception('invalid $opPrefix' + 'selling');
    }
    String buyingStr = _removeComment(map[opPrefix + 'buying']);
    if (buyingStr == null) {
      throw Exception('missing $opPrefix' + 'buying');
    }
    Asset buying;
    try {
      buying = _decodeAsset(buyingStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'buying');
    }
    if (buying == null) {
      throw Exception('invalid $opPrefix' + 'buying');
    }

    String amountStr = _removeComment(map[opPrefix + 'amount']);
    if (amountStr == null) {
      throw Exception('missing $opPrefix' + 'amount');
    }
    String amount;
    try {
      amount = _fromAmount(amountStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'amount');
    }
    if (amount == null) {
      throw Exception('invalid $opPrefix' + 'amount');
    }

    String priceNStr = _removeComment(map[opPrefix + 'price.n']);
    if (priceNStr == null) {
      throw Exception('missing $opPrefix' + 'price.n');
    }
    int n;
    try {
      n = int.parse(priceNStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'price.n');
    }
    if (n == null) {
      throw Exception('invalid $opPrefix' + 'price.n');
    }

    String priceDStr = _removeComment(map[opPrefix + 'price.d']);
    if (priceDStr == null) {
      throw Exception('missing $opPrefix' + 'price.d');
    }
    int d;
    try {
      d = int.parse(priceDStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'price.d');
    }
    if (d == null) {
      throw Exception('invalid $opPrefix' + 'price.d');
    }
    if (d == 0) {
      throw Exception(
          'price denominator can not be 0 in ' + opPrefix + 'price.d');
    }
    Decimal dec = Decimal.parse(n.toString()) / Decimal.parse(d.toString());

    CreatePassiveSellOfferOperationBuilder builder =
        CreatePassiveSellOfferOperationBuilder(
            selling, buying, amount, dec.toString());
    if (sourceAccountId != null) {
      builder
          .setMuxedSourceAccount(MuxedAccount.fromAccountId(sourceAccountId));
    }
    return builder.build();
  }

  static SetOptionsOperation _getSetOptionsOperation(
      String sourceAccountId, String opPrefix, Map<String, String> map) {
    String present = _removeComment(map[opPrefix + 'inflationDest._present']);
    if (present == null) {
      throw Exception('missing $opPrefix' + 'inflationDest._present');
    }

    String inflationDest;
    if (present == 'true') {
      inflationDest = _removeComment(map[opPrefix + 'inflationDest']);
      if (inflationDest == null) {
        throw Exception('missing $opPrefix' + 'inflationDest');
      }
    }

    present = _removeComment(map[opPrefix + 'clearFlags._present']);
    if (present == null) {
      throw Exception('missing $opPrefix' + 'clearFlags._present');
    }
    int clearFlags;
    if (present == 'true') {
      String clearFlagsStr = _removeComment(map[opPrefix + 'clearFlags']);
      if (clearFlagsStr == null) {
        throw Exception('missing $opPrefix' + 'clearFlags');
      }
      try {
        clearFlags = int.parse(clearFlagsStr);
      } catch (e) {
        throw Exception('invalid $opPrefix' + 'clearFlags');
      }
    }

    present = _removeComment(map[opPrefix + 'setFlags._present']);
    if (present == null) {
      throw Exception('missing $opPrefix' + 'setFlags._present');
    }
    int setFlags;
    if (present == 'true') {
      String setFlagsStr = _removeComment(map[opPrefix + 'setFlags']);
      if (setFlagsStr == null) {
        throw Exception('missing $opPrefix' + 'setFlags');
      }
      try {
        setFlags = int.parse(setFlagsStr);
      } catch (e) {
        throw Exception('invalid $opPrefix' + 'setFlags');
      }
    }

    present = _removeComment(map[opPrefix + 'masterWeight._present']);
    if (present == null) {
      throw Exception('missing $opPrefix' + 'masterWeight._present');
    }
    int masterWeight;
    if (present == 'true') {
      String masterWeightStr = _removeComment(map[opPrefix + 'masterWeight']);
      if (masterWeightStr == null) {
        throw Exception('missing $opPrefix' + 'masterWeight');
      }
      try {
        masterWeight = int.parse(masterWeightStr);
      } catch (e) {
        throw Exception('invalid $opPrefix' + 'masterWeight');
      }
    }

    present = _removeComment(map[opPrefix + 'lowThreshold._present']);
    if (present == null) {
      throw Exception('missing $opPrefix' + 'lowThreshold._present');
    }
    int lowThreshold;
    if (present == 'true') {
      String lowThresholdStr = _removeComment(map[opPrefix + 'lowThreshold']);
      if (lowThresholdStr == null) {
        throw Exception('missing $opPrefix' + 'lowThreshold');
      }
      try {
        lowThreshold = int.parse(lowThresholdStr);
      } catch (e) {
        throw Exception('invalid $opPrefix' + 'lowThreshold');
      }
    }

    present = _removeComment(map[opPrefix + 'medThreshold._present']);
    if (present == null) {
      throw Exception('missing $opPrefix' + 'medThreshold._present');
    }
    int medThreshold;
    if (present == 'true') {
      String medThresholdStr = _removeComment(map[opPrefix + 'medThreshold']);
      if (medThresholdStr == null) {
        throw Exception('missing $opPrefix' + 'medThreshold');
      }
      try {
        medThreshold = int.parse(medThresholdStr);
      } catch (e) {
        throw Exception('invalid $opPrefix' + 'medThreshold');
      }
    }

    present = _removeComment(map[opPrefix + 'highThreshold._present']);
    if (present == null) {
      throw Exception('missing $opPrefix' + 'highThreshold._present');
    }
    int highThreshold;
    if (present == 'true') {
      String highThresholdStr = _removeComment(map[opPrefix + 'highThreshold']);
      if (highThresholdStr == null) {
        throw Exception('missing $opPrefix' + 'highThreshold');
      }
      try {
        highThreshold = int.parse(highThresholdStr);
      } catch (e) {
        throw Exception('invalid $opPrefix' + 'highThreshold');
      }
    }

    present = _removeComment(map[opPrefix + 'homeDomain._present']);
    if (present == null) {
      throw Exception('missing $opPrefix' + 'homeDomain._present');
    }

    String homeDomain;
    if (present == 'true') {
      homeDomain = _removeComment(map[opPrefix + 'homeDomain'])
          .replaceAll('"', ''); //TODO improve this.

      if (homeDomain == null) {
        throw Exception('missing $opPrefix' + 'homeDomain');
      }
    }

    present = _removeComment(map[opPrefix + 'signer._present']);
    if (present == null) {
      throw Exception('missing $opPrefix' + 'signer._present');
    }

    XdrSignerKey signer;
    int signerWeight;

    if (present == 'true') {
      String signerWeightStr = _removeComment(map[opPrefix + 'signer.weight']);
      if (signerWeightStr == null) {
        throw Exception('missing $opPrefix' + 'signer.weight');
      }
      try {
        signerWeight = int.parse(signerWeightStr);
      } catch (e) {
        throw Exception('invalid $opPrefix' + 'signer.weight');
      }

      String key = _removeComment(map[opPrefix + 'signer.key']);
      if (key == null) {
        throw Exception('missing $opPrefix' + 'signer.key');
      }

      try {
        if (key.startsWith('G')) {
          signer = XdrSignerKey();
          signer.discriminant = XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519;
          signer.ed25519 = XdrUint256();
          signer.ed25519.uint256 = StrKey.decodeStellarAccountId(key);
        } else if (key.startsWith('X')) {
          signer = XdrSignerKey();
          signer.discriminant = XdrSignerKeyType.SIGNER_KEY_TYPE_PRE_AUTH_TX;
          signer.preAuthTx = XdrUint256();
          signer.preAuthTx.uint256 = StrKey.decodePreAuthTx(key);
        } else if (key.startsWith('T')) {
          signer = XdrSignerKey();
          signer.discriminant = XdrSignerKeyType.SIGNER_KEY_TYPE_HASH_X;
          signer.hashX = XdrUint256();
          signer.hashX.uint256 = StrKey.decodeSha256Hash(key);
        } else {
          throw Exception('invalid $opPrefix' + 'signer.key');
        }
      } catch (e) {
        throw Exception('invalid $opPrefix' + 'signer.key');
      }
    }

    SetOptionsOperationBuilder builder = SetOptionsOperationBuilder();
    if (inflationDest != null) {
      builder.setInflationDestination(inflationDest);
    }
    if (clearFlags != null) {
      builder.setClearFlags(clearFlags);
    }
    if (setFlags != null) {
      builder.setSetFlags(setFlags);
    }
    if (masterWeight != null) {
      builder.setMasterKeyWeight(masterWeight);
    }
    if (lowThreshold != null) {
      builder.setLowThreshold(lowThreshold);
    }
    if (medThreshold != null) {
      builder.setMediumThreshold(medThreshold);
    }
    if (highThreshold != null) {
      builder.setHighThreshold(highThreshold);
    }
    if (homeDomain != null) {
      builder.setHomeDomain(homeDomain);
    }
    if (signer != null && signerWeight != null) {
      builder.setSigner(signer, signerWeight);
    }
    if (sourceAccountId != null) {
      builder
          .setMuxedSourceAccount(MuxedAccount.fromAccountId(sourceAccountId));
    }
    return builder.build();
  }

  static ChangeTrustOperation _getChangeTrustOperation(
      String sourceAccountId, String opPrefix, Map<String, String> map) {
    String assetStr = _removeComment(map[opPrefix + 'line']);
    if (assetStr == null) {
      throw Exception('missing $opPrefix' + 'line');
    }
    Asset asset;
    try {
      asset = _decodeAsset(assetStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'line');
    }
    if (asset == null) {
      throw Exception('invalid $opPrefix' + 'line');
    }

    String limit;
    String limitStr = _removeComment(map[opPrefix + 'limit']);
    if (limitStr == null) {
      throw Exception('missing $opPrefix' + 'limit');
    }
    try {
      limit = _fromAmount(limitStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'limit');
    }

    ChangeTrustOperationBuilder builder =
        ChangeTrustOperationBuilder(asset, limit);
    if (sourceAccountId != null) {
      builder
          .setMuxedSourceAccount(MuxedAccount.fromAccountId(sourceAccountId));
    }
    return builder.build();
  }

  static AllowTrustOperation _getAllowTrustOperation(
      String sourceAccountId, String opPrefix, Map<String, String> map) {
    String trustor = _removeComment(map[opPrefix + 'trustor']);
    if (trustor == null) {
      throw Exception('missing $opPrefix' + 'trustor');
    }
    String assetCode = _removeComment(map[opPrefix + 'asset']);
    if (assetCode == null) {
      throw Exception('missing $opPrefix' + 'asset');
    }
    String authStr = _removeComment(map[opPrefix + 'authorize']);
    if (authStr == null) {
      throw Exception('missing $opPrefix' + 'authorize');
    }
    int authorize;
    try {
      authorize = int.parse(authStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'authorize');
    }
    if (authorize < 0 || authorize > 2) {
      throw Exception('invalid $opPrefix' + 'authorize');
    }
    AllowTrustOperationBuilder builder =
        AllowTrustOperationBuilder(trustor, assetCode, authorize);
    if (sourceAccountId != null) {
      builder
          .setMuxedSourceAccount(MuxedAccount.fromAccountId(sourceAccountId));
    }
    return builder.build();
  }

  static AccountMergeOperation _getAccountMergeOperation(String sourceAccountId,
      int index, Map<String, String> map, String txPrefix) {
    String destination =
        _removeComment(map['${txPrefix}operations[$index].body.destination']);
    if (destination == null) {
      throw Exception('missing ${txPrefix}operations[$index].body.destination');
    } else {
      try {
        KeyPair.fromAccountId(destination);
      } catch (e) {
        throw Exception(
            'invalid ${txPrefix}operations[$index].body.destination');
      }
    }
    AccountMergeOperationBuilder builder =
        AccountMergeOperationBuilder.forMuxedDestinationAccount(
            MuxedAccount.fromAccountId(destination));
    if (sourceAccountId != null) {
      builder
          .setMuxedSourceAccount(MuxedAccount.fromAccountId(sourceAccountId));
    }
    return builder.build();
  }

  static ManageDataOperation _getManageDataOperation(
      String sourceAccountId, String opPrefix, Map<String, String> map) {
    String dataName = _removeComment(map[opPrefix + 'dataName']);
    if (dataName == null) {
      throw Exception('missing $opPrefix' + 'dataName');
    } else {
      dataName = dataName.replaceAll('"', '');
    }
    Uint8List value;
    String present = _removeComment(map[opPrefix + 'dataValue._present']);
    if (present == null) {
      throw Exception('missing $opPrefix' + 'dataValue._present');
    }
    if (present == 'true') {
      String dataValueStr = _removeComment(map[opPrefix + 'dataValue']);
      if (dataValueStr == null) {
        throw Exception('missing $opPrefix' + 'dataValue');
      }
      try {
        value = Util.hexToBytes(dataValueStr);
      } catch (e) {
        throw Exception('invalid $opPrefix' + 'dataValue');
      }
    }
    ManageDataOperationBuilder builder =
        ManageDataOperationBuilder(dataName, value);
    if (sourceAccountId != null) {
      builder
          .setMuxedSourceAccount(MuxedAccount.fromAccountId(sourceAccountId));
    }
    return builder.build();
  }

  static BumpSequenceOperation _getBumpSequenceOperation(
      String sourceAccountId, String opPrefix, Map<String, String> map) {
    String bumpToStr = _removeComment(map[opPrefix + 'bumpTo']);
    if (bumpToStr == null) {
      throw Exception('missing $opPrefix' + 'bumpTo');
    }

    int bumpTo;
    try {
      bumpTo = int.parse(bumpToStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'bumpTo');
    }
    if (bumpTo == null) {
      throw Exception('invalid $opPrefix' + 'bumpTo');
    }

    BumpSequenceOperationBuilder builder = BumpSequenceOperationBuilder(bumpTo);
    if (sourceAccountId != null) {
      builder
          .setMuxedSourceAccount(MuxedAccount.fromAccountId(sourceAccountId));
    }
    return builder.build();
  }

  static String _removeComment(String value) {
    if (value == null) {
      return null;
    }
    int idx = value.indexOf("(");
    if (idx == -1) {
      return value;
    }
    return value.substring(0, idx).trim();
  }

  static _addLine(String key, String value, List<String> lines) {
    if (key != null && value != null && lines != null) {
      lines.add('$key: $value');
    }
  }

  static _addTimeBounds(
      TimeBounds timeBounds, List<String> lines, String prefix) {
    if (lines == null) return;
    if (timeBounds == null) {
      _addLine('${prefix}timeBounds._present', 'false', lines);
    } else {
      _addLine('${prefix}timeBounds._present', 'true', lines);
      _addLine(
          '${prefix}timeBounds.minTime', timeBounds.minTime.toString(), lines);
      _addLine(
          '${prefix}timeBounds.maxTime', timeBounds.maxTime.toString(), lines);
    }
  }

  static _addMemo(Memo memo, List<String> lines, String prefix) {
    if (lines == null || memo == null) return;
    if (memo is MemoNone) {
      _addLine('${prefix}memo.type', 'MEMO_NONE', lines);
    } else if (memo is MemoText) {
      final jsonEncoder = JsonEncoder();
      _addLine('${prefix}memo.type', 'MEMO_TEXT', lines);
      _addLine('${prefix}memo.text', jsonEncoder.convert(memo.text), lines);
    } else if (memo is MemoId) {
      _addLine('${prefix}memo.type', 'MEMO_ID', lines);
      _addLine('${prefix}memo.id', memo.getId().toString(), lines);
    } else if (memo is MemoHash) {
      _addLine('${prefix}memo.type', 'MEMO_HASH', lines);
      _addLine('${prefix}memo.hash', memo.hexValue, lines);
    } else if (memo is MemoReturnHash) {
      _addLine('${prefix}memo.type', 'MEMO_RETURN', lines);
      _addLine('${prefix}memo.retHash', memo.hexValue, lines);
    }
  }

  static _addOperations(
      List<Operation> operations, List<String> lines, String prefix) {
    if (lines == null) return;
    if (operations == null) {
      _addLine('${prefix}operations.len', '0', lines);
      return;
    }
    _addLine('${prefix}operations.len', operations.length.toString(), lines);
    int index = 0;
    for (Operation op in operations) {
      _addOperation(op, index, lines, prefix);
      index++;
    }
  }

  static _addOperation(
      Operation operation, int index, List<String> lines, String txPrefix) {
    if (lines == null || operation == null) return;

    if (operation.sourceAccount != null) {
      _addLine('${txPrefix}operations[$index].sourceAccount._present', 'true',
          lines);
      _addLine('${txPrefix}operations[$index].sourceAccount',
          operation.sourceAccount.accountId, lines);
    } else {
      _addLine('${txPrefix}operations[$index].sourceAccount._present', 'false',
          lines);
    }

    _addLine('${txPrefix}operations[$index].body.type',
        _txRepOpTypeUpperCase(operation), lines);
    String prefix =
        '${txPrefix}operations[$index].body.${_txRepOpType(operation)}';

    if (operation is CreateAccountOperation) {
      _addLine('$prefix.destination', operation.destination, lines);
      _addLine('$prefix.startingBalance', _toAmount(operation.startingBalance),
          lines);
    } else if (operation is PaymentOperation) {
      _addLine('$prefix.destination', operation.destination.accountId, lines);
      _addLine('$prefix.asset', _encodeAsset(operation.asset), lines);
      _addLine('$prefix.amount', _toAmount(operation.amount), lines);
    } else if (operation is PathPaymentStrictReceiveOperation) {
      _addLine('$prefix.sendAsset', _encodeAsset(operation.sendAsset), lines);
      _addLine('$prefix.sendMax', _toAmount(operation.sendMax), lines);
      _addLine('$prefix.destination', operation.destination.accountId, lines);
      _addLine('$prefix.destAsset', _encodeAsset(operation.destAsset), lines);
      _addLine('$prefix.destAmount', _toAmount(operation.destAmount), lines);
      _addLine('$prefix.path.len', operation.path.length.toString(), lines);
      int assetIndex = 0;
      for (Asset asset in operation.path) {
        _addLine('$prefix.path[$assetIndex]', _encodeAsset(asset), lines);
        assetIndex++;
      }
    } else if (operation is PathPaymentStrictSendOperation) {
      _addLine('$prefix.sendAsset', _encodeAsset(operation.sendAsset), lines);
      _addLine('$prefix.sendAmount', _toAmount(operation.sendAmount), lines);
      _addLine('$prefix.destination', operation.destination.accountId, lines);
      _addLine('$prefix.destAsset', _encodeAsset(operation.destAsset), lines);
      _addLine('$prefix.destMin', _toAmount(operation.destMin), lines);
      _addLine('$prefix.path.len', operation.path.length.toString(), lines);
      int assetIndex = 0;
      for (Asset asset in operation.path) {
        _addLine('$prefix.path[$assetIndex]', _encodeAsset(asset), lines);
        assetIndex++;
      }
    } else if (operation is ManageSellOfferOperation) {
      _addLine('$prefix.selling', _encodeAsset(operation.selling), lines);
      _addLine('$prefix.buying', _encodeAsset(operation.buying), lines);
      _addLine('$prefix.amount', _toAmount(operation.amount), lines);
      Price price = Price.fromString(operation.price);
      _addLine('$prefix.price.n', price.n.toString(), lines);
      _addLine('$prefix.price.d', price.d.toString(), lines);
      _addLine('$prefix.offerID', operation.offerId, lines);
    } else if (operation is CreatePassiveSellOfferOperation) {
      _addLine('$prefix.selling', _encodeAsset(operation.selling), lines);
      _addLine('$prefix.buying', _encodeAsset(operation.buying), lines);
      _addLine('$prefix.amount', _toAmount(operation.amount), lines);
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
        _addLine('$prefix.homeDomain',
            jsonEncoder.convert(operation.homeDomain), lines);
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
              StrKey.encodeSha256Hash(operation.signer.hashX.uint256), lines);
        }

        _addLine(
            '$prefix.signer.weight', operation.signerWeight.toString(), lines);
      } else {
        _addLine('$prefix.signer._present', 'false', lines);
      }
    } else if (operation is ChangeTrustOperation) {
      _addLine('$prefix.line', _encodeAsset(operation.asset), lines);
      _addLine('$prefix.limit', _toAmount(operation.limit), lines);
    } else if (operation is AllowTrustOperation) {
      _addLine('$prefix.trustor', operation.trustor, lines);
      _addLine('$prefix.asset', operation.assetCode, lines);
      int auth = operation.authorize ? 1 : 0;
      auth = operation.authorizeToMaintainLiabilities ? 2 : auth;
      _addLine('$prefix.authorize', auth.toString(), lines);
    } else if (operation is AccountMergeOperation) {
      // account merge does not include 'accountMergeOp' prefix
      _addLine('${txPrefix}operations[$index].body.destination',
          operation.destination.accountId, lines);
    } else if (operation is ManageDataOperation) {
      final jsonEncoder = JsonEncoder();
      _addLine('$prefix.dataName', jsonEncoder.convert(operation.name), lines);
      if (operation.value != null) {
        _addLine('$prefix.dataValue._present', 'true', lines);
        _addLine('$prefix.dataValue', Util.bytesToHex(operation.value), lines);
      } else {
        _addLine('$prefix.dataValue._present', 'false', lines);
      }
    } else if (operation is BumpSequenceOperation) {
      _addLine('$prefix.bumpTo', operation.bumpTo.toString(), lines);
    } else if (operation is ManageBuyOfferOperation) {
      _addLine('$prefix.selling', _encodeAsset(operation.selling), lines);
      _addLine('$prefix.buying', _encodeAsset(operation.buying), lines);
      _addLine('$prefix.buyAmount', _toAmount(operation.amount), lines);
      Price price = Price.fromString(operation.price);
      _addLine('$prefix.price.n', price.n.toString(), lines);
      _addLine('$prefix.price.d', price.d.toString(), lines);
      _addLine('$prefix.offerID', operation.offerId, lines);
    }
  }

  static _addSignatures(List<XdrDecoratedSignature> signatures,
      List<String> lines, String prefix) {
    if (lines == null) return;
    if (signatures == null) {
      _addLine('${prefix}signatures.len', '0', lines);
      return;
    }
    _addLine('${prefix}signatures.len', signatures.length.toString(), lines);
    int index = 0;
    for (XdrDecoratedSignature sig in signatures) {
      _addSignature(sig, index, lines, prefix);
      index++;
    }
  }

  static _addSignature(XdrDecoratedSignature signature, int index,
      List<String> lines, String prefix) {
    if (lines == null || signature == null) return;
    _addLine('${prefix}signatures[$index].hint',
        Util.bytesToHex(signature.hint.signatureHint), lines);
    _addLine('${prefix}signatures[$index].signature',
        Util.bytesToHex(signature.signature.signature), lines);
  }

  static String _txRepOpTypeUpperCase(Operation operation) {
    int value = operation.toXdr().body.discriminant.value;
    switch (value) {
      case 0:
        return 'CREATE_ACCOUNT';
      case 1:
        return 'PAYMENT';
      case 2:
        return 'PATH_PAYMENT_STRICT_RECEIVE';
      case 3:
        return 'MANAGE_SELL_OFFER';
      case 4:
        return 'CREATE_PASSIVE_SELL_OFFER';
      case 5:
        return 'SET_OPTIONS';
      case 6:
        return 'CHANGE_TRUST';
      case 7:
        return 'ALLOW_TRUST';
      case 8:
        return 'ACCOUNT_MERGE';
      case 9:
        return 'INFLATION';
      case 10:
        return 'MANAGE_DATA';
      case 11:
        return 'BUMP_SEQUENCE';
      case 12:
        return 'MANAGE_BUY_OFFER';
      case 13:
        return 'PATH_PAYMENT_STRICT_SEND';
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static String _txRepOpType(Operation operation) {
    int value = operation.toXdr().body.discriminant.value;
    switch (value) {
      case 0:
        return 'createAccountOp';
      case 1:
        return 'paymentOp';
      case 2:
        return 'pathPaymentStrictReceiveOp';
      case 3:
        return 'manageSellOfferOp';
      case 4:
        return 'createPassiveSellOfferOp';
      case 5:
        return 'setOptionsOp';
      case 6:
        return 'changeTrustOp';
      case 7:
        return 'allowTrustOp';
      case 8:
        return 'accountMergeOp';
      case 9:
        return 'inflationOp';
      case 10:
        return 'manageDataOp';
      case 11:
        return 'bumpSequenceOp';
      case 12:
        return 'manageBuyOfferOp';
      case 13:
        return 'pathPaymentStrictSendOp';
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static String _toAmount(String value) {
    Decimal amount = Decimal.parse(value) * Decimal.parse('10000000.00');
    return amount.toString();
  }

  static String _fromAmount(String value) {
    Decimal amount = Decimal.parse(value) / Decimal.parse('10000000.00');
    return amount.toString();
  }

  static String _encodeAsset(Asset asset) {
    if (asset is AssetTypeNative) {
      return 'XLM';
    } else if (asset is AssetTypeCreditAlphaNum) {
      AssetTypeCreditAlphaNum creditAsset = asset;
      return creditAsset.code + ":" + creditAsset.issuerId;
    } else {
      throw Exception("unsupported asset " + asset.type);
    }
  }

  static Asset _decodeAsset(String asset) {
    if (asset == null) {
      return null;
    }
    if (asset == 'XLM') {
      return Asset.NATIVE;
    } else {
      List<String> components = asset.split(':');
      if (components.length != 2) {
        return null;
      } else {
        String code = components[0].trim();
        String issuerId = components[1].trim();
        if (code.length <= 4) {
          return AssetTypeCreditAlphaNum4(code, issuerId);
        } else if (code.length <= 12) {
          return AssetTypeCreditAlphaNum12(code, issuerId);
        }
      }
    }
    return null;
  }
}
