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
    XdrTransactionEnvelope envelopeXdr =
        XdrTransactionEnvelope.fromEnvelopeXdrString(
            transactionEnvelopeXdrBase64);

    Transaction? tx;
    FeeBumpTransaction? feeBump;
    List<XdrDecoratedSignature?>? feeBumpSignatures;
    switch (envelopeXdr.discriminant) {
      case XdrEnvelopeType.ENVELOPE_TYPE_TX_V0:
        tx = Transaction.fromV0EnvelopeXdr(envelopeXdr.v0!);
        break;
      case XdrEnvelopeType.ENVELOPE_TYPE_TX:
        tx = Transaction.fromV1EnvelopeXdr(envelopeXdr.v1!);
        break;
      case XdrEnvelopeType.ENVELOPE_TYPE_TX_FEE_BUMP:
        feeBump = FeeBumpTransaction.fromFeeBumpTransactionEnvelope(
            envelopeXdr.feeBump!);
        tx = feeBump.innerTransaction;
        feeBumpSignatures = envelopeXdr.feeBump!.signatures;
        break;
    }

    bool isFeeBump = feeBump != null;

    List<String> lines = [];
    String type = isFeeBump ? 'ENVELOPE_TYPE_TX_FEE_BUMP' : 'ENVELOPE_TYPE_TX';
    String prefix = isFeeBump ? 'feeBump.tx.innerTx.tx.' : 'tx.';

    _addLine('type', type, lines);

    if (isFeeBump) {
      _addLine('feeBump.tx.feeSource', feeBump.feeAccount!.accountId, lines);
      _addLine('feeBump.tx.fee', feeBump.fee.toString(), lines);
      _addLine('feeBump.tx.innerTx.type', 'ENVELOPE_TYPE_TX', lines);
    }

    _addLine('${prefix}sourceAccount', tx!.sourceAccount!.accountId, lines);
    _addLine('${prefix}fee', tx.fee.toString(), lines);

    _addLine('${prefix}seqNum', tx.sequenceNumber.toString(), lines);
    _addPreconditions(tx.preconditions!, lines, prefix);
    _addMemo(tx.memo, lines, prefix);
    _addOperations(tx.operations, lines, prefix);
    _addLine('${prefix}ext.v', '0', lines);
    _addSignatures(
        tx.signatures, lines, isFeeBump ? 'feeBump.tx.innerTx.' : "");
    if (isFeeBump) {
      _addLine('feeBump.tx.ext.v', '0', lines);
      _addSignatures(feeBumpSignatures!, lines, 'feeBump.');
    }
    return lines.join('\n');
  }

  /// returns a base64 encoded transaction envelope xdr by parsing [txRep].
  static String transactionEnvelopeXdrBase64FromTxRep(String? txRep) {
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
    int? feeBumpFee;
    String? feeBumpSource = _removeComment(map['feeBump.tx.feeSource']);

    if (isFeeBump) {
      prefix = 'feeBump.tx.innerTx.tx.';
      String? feeBumpFeeStr = _removeComment(map['feeBump.tx.fee']);
      if (feeBumpFeeStr == null) {
        throw Exception('missing feeBump.tx.fee');
      }
      try {
        feeBumpFee = int.tryParse(feeBumpFeeStr);
      } catch (e) {
        throw Exception('invalid feeBump.tx.fee');
      }
      if (feeBumpFee == null) {
        throw Exception('invalid feeBump.tx.fee');
      }

      if (feeBumpSource == null) {
        throw Exception('missing feeBump.tx.feeSource');
      }
      KeyPair? feeBumpSourceKeyPair;
      try {
        feeBumpSourceKeyPair = KeyPair.fromAccountId(feeBumpSource);
      } catch (e) {
        throw Exception('invalid feeBump.tx.feeSource');
      }
      if (feeBumpSourceKeyPair == null) {
        throw Exception('invalid feeBump.tx.feeSource');
      }
    }

    String? sourceAccountId = _removeComment(map['${prefix}sourceAccount']);
    if (sourceAccountId == null) {
      throw Exception('missing ${prefix}sourceAccount');
    }
    String? feeStr = _removeComment(map['${prefix}fee']);
    int? fee;
    if (feeStr == null) {
      throw Exception('missing ${prefix}fee');
    } else {
      try {
        fee = int.tryParse(feeStr);
      } catch (e) {
        throw Exception('invalid ${prefix}fee');
      }
    }
    if (fee == null) {
      throw Exception('invalid ${prefix}fee');
    }

    String? seqNr = _removeComment(map['${prefix}seqNum']);
    int? sequenceNumber;
    if (seqNr == null) {
      throw Exception('missing ${prefix}seqNum');
    } else {
      try {
        sequenceNumber = int.tryParse(seqNr);
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

    MuxedAccount? mux = MuxedAccount.fromAccountId(sourceAccountId);
    Account sourceAccount = Account(mux!.ed25519AccountId, sequenceNumber - 1,
        muxedAccountMed25519Id: mux.id);
    TransactionBuilder txBuilder = TransactionBuilder(sourceAccount);
    txBuilder.addPreconditions(_getPreconditions(map, prefix));

    // Memo
    String? memoType = _removeComment(map['${prefix}memo.type']);
    if (memoType == null) {
      throw Exception('missing ${prefix}memo.type');
    }
    try {
      if (memoType == 'MEMO_TEXT' && map['${prefix}memo.text'] != null) {
        txBuilder.addMemo(MemoText(
            _removeComment(map['${prefix}memo.text'])!.replaceAll('"', '')));
      } else if (memoType == 'MEMO_ID' && map['${prefix}memo.id'] != null) {
        txBuilder.addMemo(
            MemoId(int.tryParse(_removeComment(map['${prefix}memo.id'])!)!));
      } else if (memoType == 'MEMO_HASH' && map['${prefix}memo.hash'] != null) {
        txBuilder.addMemo(MemoHash(
            Util.hexToBytes(_removeComment(map['${prefix}memo.hash'])!)));
      } else if (memoType == 'MEMO_RETURN' &&
          map['${prefix}memo.return'] != null) {
        txBuilder.addMemo(MemoReturnHash.string(
            _removeComment(map['${prefix}memo.return'])!));
      } else {
        txBuilder.addMemo(MemoNone());
      }
    } catch (e) {
      throw Exception('invalid ${prefix}memo');
    }

    // Operations
    String? operationsLen = _removeComment(map['${prefix}operations.len']);
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
      Operation? operation = _getOperation(i, map, prefix);
      if (operation != null) {
        txBuilder.addOperation(operation);
      }
    }
    int maxOperationFee = (fee.toDouble() / nrOfOperations.toDouble()).round();
    txBuilder.setMaxOperationFee(maxOperationFee);
    // AbstractTransaction transaction = txBuilder.build();
    Transaction transaction = txBuilder.build();

    // Signatures
    prefix = isFeeBump ? 'feeBump.tx.innerTx.' : "";
    String? signaturesLen = _removeComment(map['${prefix}signatures.len']);
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
      List<XdrDecoratedSignature> signatures = [];
      for (int i = 0; i < nrOfSignatures; i++) {
        XdrDecoratedSignature? signature = _getSignature(i, map, prefix);
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
          (feeBumpFee!.toDouble() / (nrOfOperations + 1).toDouble()).round();
      builder.setBaseFee(baseFee);
      builder.setMuxedFeeAccount(MuxedAccount.fromAccountId(feeBumpSource!));
      FeeBumpTransaction feeBumpTransaction = builder.build();
      String? fbSignaturesLen = _removeComment(map['feeBump.signatures.len']);
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
        List<XdrDecoratedSignature> fbSignatures = [];
        for (int i = 0; i < nrOfFbSignatures; i++) {
          XdrDecoratedSignature? fbSignature =
              _getSignature(i, map, 'feeBump.');
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

  static TransactionPreconditions _getPreconditions(Map<String, String> map, String prefix) {
    // Preconditions
    TransactionPreconditions cond = TransactionPreconditions();
    String? preonditionsType = _removeComment(map['${prefix}cond.type']);
    if (preonditionsType != null && preonditionsType == "PRECOND_TIME") {
      String precondPrefix = '${prefix}cond.';
      if (map['${precondPrefix}timeBounds.minTime'] != null &&
          map['${precondPrefix}timeBounds.maxTime'] != null) {
        try {
          int? minTime = int.tryParse(
              _removeComment(map['${precondPrefix}timeBounds.minTime'])!);
          int? maxTime = int.tryParse(
              _removeComment(map['${precondPrefix}timeBounds.maxTime'])!);
          TimeBounds timeBounds = TimeBounds(minTime!, maxTime!);
          cond.timeBounds = timeBounds;
          return cond;
        } catch (e) {
          throw Exception('invalid ${precondPrefix}timeBounds');
        }
      }
    } else if (preonditionsType != null && preonditionsType == "PRECOND_V2") {
      String precondPrefix = '${prefix}cond.v2.';
      cond.timeBounds = _getTimeBounds(map, precondPrefix);
      cond.ledgerBounds = _getLedgerBounds(map, precondPrefix);

      if (_removeComment(map['${precondPrefix}minSeqNum._present']) == 'true' &&
          map['${precondPrefix}minSeqNum'] != null) {
        int? minSeqNum =
        int.tryParse(_removeComment(map['${precondPrefix}minSeqNum'])!);
        if (minSeqNum == null) {
          throw Exception('invalid ${precondPrefix}minSeqNum');
        }
        cond.minSeqNumber = minSeqNum;
      } else if (_removeComment(map['${precondPrefix}minSeqNum._present']) ==
          'true') {
        throw Exception('missing ${prefix}minSeqNum');
      }

      int? minSeqAge;
      if (map['${precondPrefix}minSeqAge'] != null) {
        minSeqAge =
            int.tryParse(_removeComment(map['${precondPrefix}minSeqAge'])!);
      }
      if (minSeqAge == null) {
        throw Exception('missing ${precondPrefix}minSeqAge');
      }
      cond.minSeqAge = minSeqAge;

      int? minSeqLedgerGap;
      if (map['${precondPrefix}minSeqLedgerGap'] != null) {
        minSeqLedgerGap = int.tryParse(
            _removeComment(map['${precondPrefix}minSeqLedgerGap'])!);
      }
      if (minSeqLedgerGap == null) {
        throw Exception('missing ${precondPrefix}minSeqLedgerGap');
      }
      cond.minSeqLedgerGap = minSeqLedgerGap;

      List<XdrSignerKey>? extraSigners;
      String? extraSignersLen =
      _removeComment(map['${precondPrefix}extraSigners.len']);
      if (extraSignersLen == null) {
        throw Exception('missing ${precondPrefix}extraSigners.len');
      }
      int nrOfExtraSigners;
      try {
        nrOfExtraSigners = int.parse(extraSignersLen);
      } catch (e) {
        throw Exception('invalid ${precondPrefix}extraSigners.len');
      }
      if (nrOfExtraSigners > 2) {
        throw Exception('invalid ${prefix}extraSigners.len- greater than 2');
      }
      if (nrOfExtraSigners > 0) {
        extraSigners = [];
        for (int i = 0; i < nrOfExtraSigners; i++) {
          String? key = _removeComment(
              map[precondPrefix + 'extraSigners[' + i.toString() + ']']);
          if (key == null) {
            throw Exception('missing $precondPrefix' +
                'extraSigners[' +
                i.toString() +
                ']');
          }
          try {
            if (key.startsWith('G')) {
              XdrSignerKey signer = XdrSignerKey();
              signer.discriminant = XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519;
              signer.ed25519 = XdrUint256();
              signer.ed25519!.uint256 = StrKey.decodeStellarAccountId(key);
              extraSigners.add(signer);
            } else if (key.startsWith('T')) {
              XdrSignerKey signer = XdrSignerKey();
              signer.discriminant =
                  XdrSignerKeyType.SIGNER_KEY_TYPE_PRE_AUTH_TX;
              signer.preAuthTx = XdrUint256();
              signer.preAuthTx!.uint256 = StrKey.decodePreAuthTx(key);
              extraSigners.add(signer);
            } else if (key.startsWith('X')) {
              XdrSignerKey signer = XdrSignerKey();
              signer.discriminant = XdrSignerKeyType.SIGNER_KEY_TYPE_HASH_X;
              signer.hashX = XdrUint256();
              signer.hashX!.uint256 = StrKey.decodeSha256Hash(key);
              extraSigners.add(signer);
            } else if (key.startsWith('P')) {
              XdrSignerKey signer = XdrSignerKey();
              signer.discriminant =
                  XdrSignerKeyType.KEY_TYPE_ED25519_SIGNED_PAYLOAD;
              XdrSignedPayload payload = StrKey.decodeXdrSignedPayload(key);
              signer.signedPayload = payload;
              extraSigners.add(signer);
            } else {
              throw Exception('invalid $precondPrefix' +
                  'extraSigners[' +
                  i.toString() +
                  ']');
            }
          } catch (e) {
            throw Exception('invalid $precondPrefix' +
                'extraSigners[' +
                i.toString() +
                ']');
          }
        }
      }
      cond.extraSigners = extraSigners;
      return cond;
    }

    cond.timeBounds = _getTimeBounds(map, prefix);
    return cond;
  }

  static TimeBounds? _getTimeBounds(Map<String, String> map, String prefix) {
    if (_removeComment(map['${prefix}timeBounds._present']) == 'true' &&
        map['${prefix}timeBounds.minTime'] != null &&
        map['${prefix}timeBounds.maxTime'] != null) {
      try {
        int? minTime =
            int.tryParse(_removeComment(map['${prefix}timeBounds.minTime'])!);
        int? maxTime =
            int.tryParse(_removeComment(map['${prefix}timeBounds.maxTime'])!);
        return TimeBounds(minTime!, maxTime!);
      } catch (e) {
        throw Exception('invalid ${prefix}timeBounds');
      }
    } else if (_removeComment(map['${prefix}timeBounds._present']) == 'true') {
      throw Exception('invalid ${prefix}timeBounds');
    }
  }

  static LedgerBounds? _getLedgerBounds(
      Map<String, String> map, String prefix) {
    if (_removeComment(map['${prefix}ledgerBounds._present']) == 'true' &&
        map['${prefix}ledgerBounds.minLedger'] != null &&
        map['${prefix}ledgerBounds.maxLedger'] != null) {
      try {
        int? minLedger = int.tryParse(
            _removeComment(map['${prefix}ledgerBounds.minLedger'])!);
        int? maxLedger = int.tryParse(
            _removeComment(map['${prefix}ledgerBounds.maxLedger'])!);
        return LedgerBounds(minLedger!, maxLedger!);
      } catch (e) {
        throw Exception('invalid ${prefix}ledgerBounds');
      }
    } else if (_removeComment(map['${prefix}ledgerBounds._present']) ==
        'true') {
      throw Exception('invalid ${prefix}ledgerBounds');
    }
  }

  static XdrDecoratedSignature? _getSignature(
      int index, Map<String, String> map, String prefix) {
    String? hintStr = _removeComment(map['${prefix}signatures[$index].hint']);
    if (hintStr == null) {
      throw Exception('missing ${prefix}signatures[$index].hint');
    }
    String? signatureStr =
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

  static Operation? _getOperation(
      int index, Map<String, String> map, String txPrefix) {
    String prefix = '${txPrefix}operations[$index].body.';
    String? sourceAccountId;
    if (_removeComment(
            map['${txPrefix}operations[$index].sourceAccount._present']) ==
        'true') {
      sourceAccountId =
          _removeComment(map['${txPrefix}operations[$index].sourceAccount']);
      if (sourceAccountId == null) {
        throw Exception('missing ${txPrefix}operations[$index].sourceAccount');
      }
      try {
        KeyPair.fromAccountId(sourceAccountId);
      } catch (e) {
        throw Exception('invalid ${txPrefix}operations[$index].sourceAccount');
      }
    }
    String? opType = _removeComment(map[prefix + 'type']);
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
    if (opType == 'CREATE_CLAIMABLE_BALANCE') {
      String opPrefix = prefix + 'createClaimableBalanceOp.';
      return _getCreateClaimableBalanceOp(sourceAccountId, opPrefix, map);
    }
    if (opType == 'CLAIM_CLAIMABLE_BALANCE') {
      String opPrefix = prefix + 'claimClaimableBalanceOp.';
      return _getClaimClaimableBalanceOp(sourceAccountId, opPrefix, map);
    }
    if (opType == 'BEGIN_SPONSORING_FUTURE_RESERVES') {
      String opPrefix = prefix + 'beginSponsoringFutureReservesOp.';
      return _getBeginSponsoringFutureReservesOp(
          sourceAccountId, opPrefix, map);
    }
    if (opType == 'END_SPONSORING_FUTURE_RESERVES') {
      return _getEndSponsoringFutureReservesOp(sourceAccountId);
    }
    if (opType == 'REVOKE_SPONSORSHIP') {
      String opPrefix = prefix + 'revokeSponsorshipOp.';
      return _getRevokeSponsorshipOperation(sourceAccountId, opPrefix, map);
    }
    if (opType == 'CLAWBACK') {
      String opPrefix = prefix + 'clawbackOp.';
      return _getClawbackOp(sourceAccountId, opPrefix, map);
    }
    if (opType == 'CLAWBACK_CLAIMABLE_BALANCE') {
      String opPrefix = prefix + 'clawbackClaimableBalanceOp.';
      return _getClawbackClaimableBalanceOp(sourceAccountId, opPrefix, map);
    }
    if (opType == 'SET_TRUST_LINE_FLAGS') {
      String opPrefix = prefix + 'setTrustLineFlagsOp.';
      return _getSetTrustLineFlagsOp(sourceAccountId, opPrefix, map);
    }
    if (opType == 'SET_TRUST_LINE_FLAGS') {
      String opPrefix = prefix + 'setTrustLineFlagsOp.';
      return _getSetTrustLineFlagsOp(sourceAccountId, opPrefix, map);
    }
    if (opType == 'LIQUIDITY_POOL_DEPOSIT') {
      String opPrefix = prefix + 'liquidityPoolDepositOp.';
      return _getLiquidityPoolDepositOp(sourceAccountId, opPrefix, map);
    }
    if (opType == 'LIQUIDITY_POOL_WITHDRAW') {
      String opPrefix = prefix + 'liquidityPoolWithdrawOp.';
      return _getLiquidityPoolWithdrawOp(sourceAccountId, opPrefix, map);
    }
    throw Exception('invalid or unsupported [$prefix].type - $opType');
  }

  static LiquidityPoolWithdrawOperation _getLiquidityPoolWithdrawOp(
      String? sourceAccountId, String opPrefix, Map<String, String> map) {
    String? liquidityPoolID = _removeComment(map[opPrefix + 'liquidityPoolID']);
    if (liquidityPoolID == null) {
      throw Exception('missing $opPrefix' + 'liquidityPoolID');
    }

    String? amountStr = _removeComment(map[opPrefix + 'amount']);
    if (amountStr == null) {
      throw Exception('missing $opPrefix' + 'amount');
    }
    String? amount;
    try {
      amount = _fromAmount(amountStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'amount');
    }
    if (amount == null) {
      throw Exception('invalid $opPrefix' + 'amount');
    }

    String? minAmountAStr = _removeComment(map[opPrefix + 'minAmountA']);
    if (minAmountAStr == null) {
      throw Exception('missing $opPrefix' + 'minAmountA');
    }
    String? minAmountA;
    try {
      minAmountA = _fromAmount(minAmountAStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'minAmountA');
    }
    if (minAmountA == null) {
      throw Exception('invalid $opPrefix' + 'minAmountA');
    }

    String? minAmountBStr = _removeComment(map[opPrefix + 'minAmountB']);
    if (minAmountBStr == null) {
      throw Exception('missing $opPrefix' + 'minAmountB');
    }
    String? minAmountB;
    try {
      minAmountB = _fromAmount(minAmountBStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'minAmountB');
    }
    if (minAmountB == null) {
      throw Exception('invalid $opPrefix' + 'minAmountB');
    }

    LiquidityPoolWithdrawOperationBuilder builder =
        new LiquidityPoolWithdrawOperationBuilder(
            liquidityPoolId: liquidityPoolID,
            amount: amount,
            minAmountA: minAmountA,
            minAmountB: minAmountB);
    if (sourceAccountId != null) {
      builder
          .setMuxedSourceAccount(MuxedAccount.fromAccountId(sourceAccountId)!);
    }
    return builder.build();
  }

  static LiquidityPoolDepositOperation _getLiquidityPoolDepositOp(
      String? sourceAccountId, String opPrefix, Map<String, String> map) {
    String? liquidityPoolID = _removeComment(map[opPrefix + 'liquidityPoolID']);
    if (liquidityPoolID == null) {
      throw Exception('missing $opPrefix' + 'liquidityPoolID');
    }

    String? maxAmountAStr = _removeComment(map[opPrefix + 'maxAmountA']);
    if (maxAmountAStr == null) {
      throw Exception('missing $opPrefix' + 'maxAmountA');
    }
    String? maxAmountA;
    try {
      maxAmountA = _fromAmount(maxAmountAStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'maxAmountA');
    }
    if (maxAmountA == null) {
      throw Exception('invalid $opPrefix' + 'maxAmountA');
    }

    String? maxAmountBStr = _removeComment(map[opPrefix + 'maxAmountB']);
    if (maxAmountBStr == null) {
      throw Exception('missing $opPrefix' + 'maxAmountB');
    }
    String? maxAmountB;
    try {
      maxAmountB = _fromAmount(maxAmountBStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'maxAmountB');
    }
    if (maxAmountB == null) {
      throw Exception('invalid $opPrefix' + 'maxAmountB');
    }

    String? minPriceNStr = _removeComment(map[opPrefix + 'minPrice.n']);
    if (minPriceNStr == null) {
      throw Exception('missing $opPrefix' + 'minPrice.n');
    }
    int? minPriceN;
    try {
      minPriceN = int.tryParse(minPriceNStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'minPrice.n');
    }
    if (minPriceN == null) {
      throw Exception('invalid $opPrefix' + 'minPrice.n');
    }

    String? minPriceDStr = _removeComment(map[opPrefix + 'minPrice.d']);
    if (minPriceDStr == null) {
      throw Exception('missing $opPrefix' + 'minPrice.d');
    }
    int? minPriceD;
    try {
      minPriceD = int.tryParse(minPriceDStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'minPrice.d');
    }
    if (minPriceD == null) {
      throw Exception('invalid $opPrefix' + 'minPrice.d');
    }

    String? maxPriceNStr = _removeComment(map[opPrefix + 'maxPrice.n']);
    if (maxPriceNStr == null) {
      throw Exception('missing $opPrefix' + 'maxPrice.n');
    }
    int? maxPriceN;
    try {
      maxPriceN = int.tryParse(maxPriceNStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'maxPrice.n');
    }
    if (maxPriceN == null) {
      throw Exception('invalid $opPrefix' + 'maxPrice.n');
    }

    String? maxPriceDStr = _removeComment(map[opPrefix + 'maxPrice.d']);
    if (maxPriceDStr == null) {
      throw Exception('missing $opPrefix' + 'maxPrice.d');
    }
    int? maxPriceD;
    try {
      maxPriceD = int.tryParse(maxPriceDStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'maxPrice.d');
    }
    if (maxPriceD == null) {
      throw Exception('invalid $opPrefix' + 'maxPrice.d');
    }

    String minP = removeTailZero(
        (BigInt.from(minPriceN) / BigInt.from(minPriceD)).toString());
    String maxP = removeTailZero(
        (BigInt.from(maxPriceN) / BigInt.from(maxPriceD)).toString());

    LiquidityPoolDepositOperationBuilder builder =
        new LiquidityPoolDepositOperationBuilder(
            liquidityPoolId: liquidityPoolID,
            maxAmountA: maxAmountA,
            maxAmountB: maxAmountB,
            minPrice: minP,
            maxPrice: maxP);
    if (sourceAccountId != null) {
      builder
          .setMuxedSourceAccount(MuxedAccount.fromAccountId(sourceAccountId)!);
    }
    return builder.build();
  }

  static SetTrustLineFlagsOperation _getSetTrustLineFlagsOp(
      String? sourceAccountId, String opPrefix, Map<String, String> map) {
    String? accountId = _removeComment(map[opPrefix + 'trustor']);
    if (accountId == null) {
      throw Exception('missing $opPrefix' + 'trustor');
    }
    try {
      KeyPair.fromAccountId(accountId);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'trustor');
    }

    String? assetStr = _removeComment(map[opPrefix + 'asset']);
    if (assetStr == null) {
      throw Exception('missing $opPrefix' + 'asset');
    }
    Asset? asset;
    try {
      asset = _decodeAsset(assetStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'asset');
    }
    if (asset == null) {
      throw Exception('invalid $opPrefix' + 'asset');
    }

    String? clearFlagsStr = _removeComment(map[opPrefix + 'clearFlags']);
    if (clearFlagsStr == null) {
      throw Exception('missing $opPrefix' + 'clearFlags');
    }
    int? clearFlags;
    try {
      clearFlags = int.tryParse(clearFlagsStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'clearFlags');
    }
    if (clearFlags == null) {
      throw Exception('invalid $opPrefix' + 'clearFlags');
    }

    String? setFlagsStr = _removeComment(map[opPrefix + 'setFlags']);
    if (setFlagsStr == null) {
      throw Exception('missing $opPrefix' + 'setFlags');
    }
    int? setFlags;
    try {
      setFlags = int.tryParse(setFlagsStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'setFlags');
    }
    if (setFlags == null) {
      throw Exception('invalid $opPrefix' + 'setFlags');
    }

    SetTrustLineFlagsOperationBuilder builder =
        SetTrustLineFlagsOperationBuilder(
            accountId, asset, clearFlags, setFlags);
    if (sourceAccountId != null) {
      builder
          .setMuxedSourceAccount(MuxedAccount.fromAccountId(sourceAccountId)!);
    }
    return builder.build();
  }

  static ClawbackClaimableBalanceOperation _getClawbackClaimableBalanceOp(
      String? sourceAccountId, String opPrefix, Map<String, String> map) {
    String? claimableBalanceId = _removeComment(map[opPrefix + 'balanceID.v0']);
    if (claimableBalanceId == null) {
      throw Exception('missing $opPrefix' + 'balanceID.v0');
    }
    ClawbackClaimableBalanceOperationBuilder builder =
        ClawbackClaimableBalanceOperationBuilder(claimableBalanceId);
    if (sourceAccountId != null) {
      builder
          .setMuxedSourceAccount(MuxedAccount.fromAccountId(sourceAccountId)!);
    }
    return builder.build();
  }

  static ClawbackOperation _getClawbackOp(
      String? sourceAccountId, String opPrefix, Map<String, String> map) {
    String? assetStr = _removeComment(map[opPrefix + 'asset']);
    if (assetStr == null) {
      throw Exception('missing $opPrefix' + 'asset');
    }
    Asset? asset;
    try {
      asset = _decodeAsset(assetStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'asset');
    }
    if (asset == null) {
      throw Exception('invalid $opPrefix' + 'asset');
    }
    String? amountStr = _removeComment(map[opPrefix + 'amount']);
    if (amountStr == null) {
      throw Exception('missing $opPrefix' + 'amount');
    }
    String? amount;
    try {
      amount = _fromAmount(amountStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'amount');
    }
    if (amount == null) {
      throw Exception('invalid $opPrefix' + 'amount');
    }

    String? accountId = _removeComment(map[opPrefix + 'from']);
    if (accountId == null) {
      throw Exception('missing $opPrefix' + 'from');
    }
    try {
      KeyPair.fromAccountId(accountId);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'from');
    }
    ClawbackOperationBuilder builder =
        ClawbackOperationBuilder(asset, accountId, amount);
    if (sourceAccountId != null) {
      builder
          .setMuxedSourceAccount(MuxedAccount.fromAccountId(sourceAccountId)!);
    }
    return builder.build();
  }

  static RevokeSponsorshipOperation _getRevokeSponsorshipOperation(
      String? sourceAccountId, String opPrefix, Map<String, String> map) {
    String? type = _removeComment(map[opPrefix + 'type']);
    if (type == null) {
      throw Exception('missing $opPrefix' + 'type');
    }
    RevokeSponsorshipOperationBuilder builder =
        RevokeSponsorshipOperationBuilder();
    if (type == 'REVOKE_SPONSORSHIP_LEDGER_ENTRY') {
      String? ledgerKeyType = _removeComment(map[opPrefix + 'ledgerKey.type']);
      if (ledgerKeyType == null) {
        throw Exception('missing $opPrefix' + 'ledgerKey.type');
      }
      if (ledgerKeyType == 'ACCOUNT') {
        String? accountId =
            _removeComment(map[opPrefix + 'ledgerKey.account.accountID']);
        if (accountId == null) {
          throw Exception('missing $opPrefix' + 'ledgerKey.account.accountID');
        }
        try {
          KeyPair.fromAccountId(accountId);
        } catch (e) {
          throw Exception('invalid $opPrefix' + 'ledgerKey.account.accountID');
        }
        builder = builder.revokeAccountSponsorship(accountId);
      } else if (ledgerKeyType == 'TRUSTLINE') {
        String? accountId =
            _removeComment(map[opPrefix + 'ledgerKey.trustLine.accountID']);
        if (accountId == null) {
          throw Exception(
              'missing $opPrefix' + 'ledgerKey.trustLine.accountID');
        }
        try {
          KeyPair.fromAccountId(accountId);
        } catch (e) {
          throw Exception(
              'invalid $opPrefix' + 'ledgerKey.trustLine.accountID');
        }
        String? assetStr =
            _removeComment(map[opPrefix + 'ledgerKey.trustLine.asset']);
        if (assetStr == null) {
          throw Exception('missing $opPrefix' + 'ledgerKey.trustLine.asset');
        }
        Asset? asset;
        try {
          asset = _decodeAsset(assetStr);
        } catch (e) {
          throw Exception('invalid $opPrefix' + 'ledgerKey.trustLine.asset');
        }
        if (asset == null) {
          throw Exception('invalid $opPrefix' + 'ledgerKey.trustLine.asset');
        }

        builder = builder.revokeTrustlineSponsorship(accountId, asset);
      } else if (ledgerKeyType == 'OFFER') {
        String? sellerId =
            _removeComment(map[opPrefix + 'ledgerKey.offer.sellerID']);
        if (sellerId == null) {
          throw Exception('missing $opPrefix' + 'ledgerKey.offer.sellerID');
        }
        try {
          KeyPair.fromAccountId(sellerId);
        } catch (e) {
          throw Exception('invalid $opPrefix' + 'ledgerKey.offer.sellerID');
        }
        String? offerIdStr =
            _removeComment(map[opPrefix + 'ledgerKey.offer.offerID']);
        if (offerIdStr == null) {
          throw Exception('missing $opPrefix' + 'ledgerKey.offer.offerID');
        }
        int? offerId;
        try {
          offerId = int.tryParse(offerIdStr);
        } catch (e) {
          throw Exception('invalid $opPrefix' + 'ledgerKey.offer.offerID');
        }
        if (offerId == null) {
          throw Exception('invalid $opPrefix' + 'ledgerKey.offer.offerID');
        }
        builder = builder.revokeOfferSponsorship(sellerId, offerId);
      } else if (ledgerKeyType == 'DATA') {
        String? accountId =
            _removeComment(map[opPrefix + 'ledgerKey.data.accountID']);
        if (accountId == null) {
          throw Exception('missing $opPrefix' + 'ledgerKey.data.accountID');
        }
        try {
          KeyPair.fromAccountId(accountId);
        } catch (e) {
          throw Exception('invalid $opPrefix' + 'ledgerKey.data.accountID');
        }
        String? dataName =
            _removeComment(map[opPrefix + 'ledgerKey.data.dataName']);
        if (dataName == null) {
          throw Exception('missing $opPrefix' + 'ledgerKey.data.dataName');
        } else {
          dataName = dataName.replaceAll('"', '');
        }
        builder = builder.revokeDataSponsorship(accountId, dataName);
      } else if (ledgerKeyType == 'CLAIMABLE_BALANCE') {
        String? claimableBalanceId = _removeComment(
            map[opPrefix + 'ledgerKey.claimableBalance.balanceID.v0']);
        if (claimableBalanceId == null) {
          throw Exception(
              'missing $opPrefix' + 'ledgerKey.claimableBalance.balanceID.v0');
        }
        builder = builder.revokeClaimableBalanceSponsorship(claimableBalanceId);
      }
    } else if (type == "REVOKE_SPONSORSHIP_SIGNER") {
      String? accountId = _removeComment(map[opPrefix + 'signer.accountID']);
      if (accountId == null) {
        throw Exception('missing $opPrefix' + 'signer.accountID');
      }
      try {
        KeyPair.fromAccountId(accountId);
      } catch (e) {
        throw Exception('invalid $opPrefix' + 'signer.accountID');
      }
      String? signerKey = _removeComment(map[opPrefix + 'signer.signerKey']);
      if (signerKey == null) {
        throw Exception('missing $opPrefix' + 'signer.signerKey');
      }
      if (signerKey.startsWith("G")) {
        builder = builder.revokeEd25519Signer(accountId, signerKey);
      } else if (signerKey.startsWith("T")) {
        builder = builder.revokePreAuthTxSigner(accountId, signerKey);
      } else if (signerKey.startsWith("X")) {
        builder = builder.revokeSha256HashSigner(accountId, signerKey);
      } else {
        throw Exception('invalid $opPrefix' + 'signer.signerKe');
      }
    }
    if (sourceAccountId != null) {
      builder
          .setMuxedSourceAccount(MuxedAccount.fromAccountId(sourceAccountId)!);
    }
    return builder.build();
  }

  static EndSponsoringFutureReservesOperation _getEndSponsoringFutureReservesOp(
      String? sourceAccountId) {
    EndSponsoringFutureReservesOperationBuilder builder =
        EndSponsoringFutureReservesOperationBuilder();
    if (sourceAccountId != null) {
      builder
          .setMuxedSourceAccount(MuxedAccount.fromAccountId(sourceAccountId)!);
    }
    return builder.build();
  }

  static BeginSponsoringFutureReservesOperation
      _getBeginSponsoringFutureReservesOp(
          String? sourceAccountId, String opPrefix, Map<String, String> map) {
    String? sponsoredID = _removeComment(map[opPrefix + 'sponsoredID']);
    if (sponsoredID == null) {
      throw Exception('missing $opPrefix' + 'sponsoredID');
    }
    BeginSponsoringFutureReservesOperationBuilder builder =
        BeginSponsoringFutureReservesOperationBuilder(sponsoredID);
    if (sourceAccountId != null) {
      builder
          .setMuxedSourceAccount(MuxedAccount.fromAccountId(sourceAccountId)!);
    }
    return builder.build();
  }

  static ClaimClaimableBalanceOperation _getClaimClaimableBalanceOp(
      String? sourceAccountId, String opPrefix, Map<String, String> map) {
    String? claimableBalanceId = _removeComment(map[opPrefix + 'balanceID.v0']);
    if (claimableBalanceId == null) {
      throw Exception('missing $opPrefix' + 'balanceID.v0');
    }
    ClaimClaimableBalanceOperationBuilder builder =
        ClaimClaimableBalanceOperationBuilder(claimableBalanceId);
    if (sourceAccountId != null) {
      builder
          .setMuxedSourceAccount(MuxedAccount.fromAccountId(sourceAccountId)!);
    }
    return builder.build();
  }

  static CreateClaimableBalanceOperation _getCreateClaimableBalanceOp(
      String? sourceAccountId, String opPrefix, Map<String, String> map) {
    String? assetStr = _removeComment(map[opPrefix + 'asset']);
    if (assetStr == null) {
      throw Exception('missing $opPrefix' + 'asset');
    }
    Asset? asset;
    try {
      asset = _decodeAsset(assetStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'asset');
    }
    if (asset == null) {
      throw Exception('invalid $opPrefix' + 'asset');
    }
    String? amountStr = _removeComment(map[opPrefix + 'amount']);
    if (amountStr == null) {
      throw Exception('missing $opPrefix' + 'amount');
    }
    String? amount;
    try {
      amount = _fromAmount(amountStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'amount');
    }
    if (amount == null) {
      throw Exception('invalid $opPrefix' + 'amount');
    }
    List<Claimant?> claimants = [];
    String claimantsLengthKey = opPrefix + 'claimants.len';
    if (map[claimantsLengthKey] != null) {
      int claimantsLen = 0;
      try {
        claimantsLen = int.parse(_removeComment(map[claimantsLengthKey])!);
      } catch (e) {
        throw Exception('invalid $claimantsLengthKey');
      }
      for (int i = 0; i < claimantsLen; i++) {
        Claimant nextClaimant = _getClaimant(opPrefix, i, map);
        claimants.add(nextClaimant);
      }
    }
    CreateClaimableBalanceOperationBuilder builder =
        CreateClaimableBalanceOperationBuilder(claimants, asset, amount);
    if (sourceAccountId != null) {
      builder
          .setMuxedSourceAccount(MuxedAccount.fromAccountId(sourceAccountId)!);
    }
    return builder.build();
  }

  static Claimant _getClaimant(
      String prefix, int index, Map<String, String> map) {
    String? destination =
        _removeComment(map[prefix + 'claimants[$index].v0.destination']);
    if (destination == null) {
      throw Exception('missing $prefix' + 'claimants[$index].v0.destination');
    }
    try {
      KeyPair.fromAccountId(destination);
    } catch (e) {
      throw Exception('invalid $prefix' + 'claimants[$index].v0.destination');
    }
    XdrClaimPredicate predicate =
        _getClaimPredicate(prefix + 'claimants[$index].v0.predicate.', map);
    return Claimant(destination, predicate);
  }

  static XdrClaimPredicate _getClaimPredicate(
      String prefix, Map<String, String> map) {
    String? type = _removeComment(map[prefix + 'type']);
    if (type == null) {
      throw Exception('missing $prefix' + 'type');
    }
    switch (type) {
      case 'CLAIM_PREDICATE_UNCONDITIONAL':
        XdrClaimPredicate result = XdrClaimPredicate();
        result.discriminant =
            XdrClaimPredicateType.CLAIM_PREDICATE_UNCONDITIONAL;
        return result;
      case 'CLAIM_PREDICATE_AND':
        List<XdrClaimPredicate> andPredicates = [];
        String lengthKey = prefix + 'andPredicates.len';
        if (map[lengthKey] != null) {
          int len = 0;
          try {
            len = int.parse(_removeComment(map[lengthKey])!);
          } catch (e) {
            throw Exception('invalid $lengthKey');
          }
          if (len != 2) {
            throw Exception('invalid $lengthKey');
          }
          for (int i = 0; i < len; i++) {
            XdrClaimPredicate next =
                _getClaimPredicate(prefix + 'andPredicates[$i].', map);
            andPredicates.add(next);
          }
        } else {
          throw Exception('missing $prefix' + 'andPredicates.len');
        }
        XdrClaimPredicate result = XdrClaimPredicate();
        result.discriminant = XdrClaimPredicateType.CLAIM_PREDICATE_AND;
        result.andPredicates = andPredicates;
        return result;
      case 'CLAIM_PREDICATE_OR':
        List<XdrClaimPredicate> orPredicates = [];
        String lengthKey = prefix + 'orPredicates.len';
        if (map[lengthKey] != null) {
          int len = 0;
          try {
            len = int.parse(_removeComment(map[lengthKey])!);
          } catch (e) {
            throw Exception('invalid $lengthKey');
          }
          if (len != 2) {
            throw Exception('invalid $lengthKey');
          }
          for (int i = 0; i < len; i++) {
            XdrClaimPredicate next =
                _getClaimPredicate(prefix + 'orPredicates[$i].', map);
            orPredicates.add(next);
          }
        } else {
          throw Exception('missing $prefix' + 'orPredicates.len');
        }
        XdrClaimPredicate result = XdrClaimPredicate();
        result.discriminant = XdrClaimPredicateType.CLAIM_PREDICATE_OR;
        result.orPredicates = orPredicates;
        return result;
      case 'CLAIM_PREDICATE_NOT':
        XdrClaimPredicate result = XdrClaimPredicate();
        result.discriminant = XdrClaimPredicateType.CLAIM_PREDICATE_NOT;
        result.notPredicate = _getClaimPredicate(prefix + 'notPredicate.', map);
        return result;
      case 'CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME':
        String timeKey = prefix + 'absBefore';
        int time = 0;
        if (map[timeKey] != null) {
          try {
            time = int.parse(_removeComment(map[timeKey])!);
          } catch (e) {
            throw Exception('invalid $timeKey');
          }
        } else {
          throw Exception('missing $prefix' + 'absBefore');
        }
        XdrClaimPredicate result = XdrClaimPredicate();
        result.discriminant =
            XdrClaimPredicateType.CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME;
        XdrInt64 absBefore = new XdrInt64();
        absBefore.int64 = time;
        result.absBefore = absBefore;
        return result;
      case 'CLAIM_PREDICATE_BEFORE_RELATIVE_TIME':
        String timeKey = prefix + 'relBefore';
        int time = 0;
        if (map[timeKey] != null) {
          try {
            time = int.parse(_removeComment(map[timeKey])!);
          } catch (e) {
            throw Exception('invalid $timeKey');
          }
        } else {
          throw Exception('missing $prefix' + 'relBefore');
        }
        XdrClaimPredicate result = XdrClaimPredicate();
        result.discriminant =
            XdrClaimPredicateType.CLAIM_PREDICATE_BEFORE_RELATIVE_TIME;
        XdrInt64 relBefore = new XdrInt64();
        relBefore.int64 = time;
        result.relBefore = relBefore;
        return result;
      default:
        throw Exception('invalid $prefix' + 'type');
    }
  }

  static CreateAccountOperation _getCreateAccountOperation(
      String? sourceAccountId, String opPrefix, Map<String, String> map) {
    String? destination = _removeComment(map[opPrefix + 'destination']);
    if (destination == null) {
      throw Exception('missing $opPrefix' + 'destination');
    }
    try {
      KeyPair.fromAccountId(destination);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'destination');
    }
    String? startingBalanceValue =
        _removeComment(map[opPrefix + 'startingBalance']);
    if (startingBalanceValue == null) {
      throw Exception('missing $opPrefix' + 'startingBalance');
    }
    String? startingBalance;
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
      String? sourceAccountId, String opPrefix, Map<String, String> map) {
    String? destination = _removeComment(map[opPrefix + 'destination']);
    if (destination == null) {
      throw Exception('missing $opPrefix' + 'destination');
    }
    try {
      KeyPair.fromAccountId(destination);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'destination');
    }
    String? assetStr = _removeComment(map[opPrefix + 'asset']);
    if (assetStr == null) {
      throw Exception('missing $opPrefix' + 'asset');
    }
    Asset? asset;
    try {
      asset = _decodeAsset(assetStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'asset');
    }
    if (asset == null) {
      throw Exception('invalid $opPrefix' + 'asset');
    }
    String? amountStr = _removeComment(map[opPrefix + 'amount']);
    if (amountStr == null) {
      throw Exception('missing $opPrefix' + 'amount');
    }
    String? amount;
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
          .setMuxedSourceAccount(MuxedAccount.fromAccountId(sourceAccountId)!);
    }
    return builder.build();
  }

  static PathPaymentStrictReceiveOperation
      _getPathPaymentStrictReceiveOperation(
          String? sourceAccountId, String opPrefix, Map<String, String> map) {
    String? sendAssetStr = _removeComment(map[opPrefix + 'sendAsset']);
    if (sendAssetStr == null) {
      throw Exception('missing $opPrefix' + 'sendAsset');
    }
    Asset? sendAsset;
    try {
      sendAsset = _decodeAsset(sendAssetStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'sendAsset');
    }
    if (sendAsset == null) {
      throw Exception('invalid $opPrefix' + 'sendAsset');
    }

    String? sendMaxStr = _removeComment(map[opPrefix + 'sendMax']);
    if (sendMaxStr == null) {
      throw Exception('missing $opPrefix' + 'sendMax');
    }
    String? sendMax;
    try {
      sendMax = _fromAmount(sendMaxStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'sendMax');
    }
    if (sendMax == null) {
      throw Exception('invalid $opPrefix' + 'sendMax');
    }

    String? destination = _removeComment(map[opPrefix + 'destination']);
    if (destination == null) {
      throw Exception('missing $opPrefix' + 'destination');
    }
    try {
      KeyPair.fromAccountId(destination);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'destination');
    }

    String? destAssetStr = _removeComment(map[opPrefix + 'destAsset']);
    if (destAssetStr == null) {
      throw Exception('missing $opPrefix' + 'destAsset');
    }
    Asset? destAsset;
    try {
      destAsset = _decodeAsset(destAssetStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'destAsset');
    }
    if (destAsset == null) {
      throw Exception('invalid $opPrefix' + 'destAsset');
    }

    String? destAmountStr = _removeComment(map[opPrefix + 'destAmount']);
    if (destAmountStr == null) {
      throw Exception('missing $opPrefix' + 'destAmount');
    }
    String? destAmount;
    try {
      destAmount = _fromAmount(destAmountStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'destAmount');
    }
    if (destAmount == null) {
      throw Exception('invalid $opPrefix' + 'destAmount');
    }

    List<Asset?> path = [];
    String pathLengthKey = opPrefix + 'path.len';
    if (map[pathLengthKey] != null) {
      int pathLen = 0;
      try {
        pathLen = int.parse(_removeComment(map[pathLengthKey])!);
      } catch (e) {
        throw Exception('invalid $pathLengthKey');
      }
      if (pathLen > 5) {
        throw Exception(
            'path.len can not be greater than 5 in $pathLengthKey but is $pathLen');
      }
      for (int i = 0; i < pathLen; i++) {
        String? nextAssetStr = _removeComment(map[opPrefix + 'path[$i]']);
        if (nextAssetStr == null) {
          throw Exception('missing $opPrefix' + 'path[$i]');
        }
        try {
          Asset? nextAsset = _decodeAsset(nextAssetStr);
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
          .setMuxedSourceAccount(MuxedAccount.fromAccountId(sourceAccountId)!);
    }
    return builder.build();
  }

  static PathPaymentStrictSendOperation _getPathPaymentStrictSendOperation(
      String? sourceAccountId, String opPrefix, Map<String, String> map) {
    String? sendAssetStr = _removeComment(map[opPrefix + 'sendAsset']);
    if (sendAssetStr == null) {
      throw Exception('missing $opPrefix' + 'sendAsset');
    }
    Asset? sendAsset;
    try {
      sendAsset = _decodeAsset(sendAssetStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'sendAsset');
    }
    if (sendAsset == null) {
      throw Exception('invalid $opPrefix' + 'sendAsset');
    }

    String? sendAmountStr = _removeComment(map[opPrefix + 'sendAmount']);
    if (sendAmountStr == null) {
      throw Exception('missing $opPrefix' + 'sendAmount');
    }
    String? sendAmount;
    try {
      sendAmount = _fromAmount(sendAmountStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'sendAmount');
    }
    if (sendAmount == null) {
      throw Exception('invalid $opPrefix' + 'sendAmount');
    }

    String? destination = _removeComment(map[opPrefix + 'destination']);
    if (destination == null) {
      throw Exception('missing $opPrefix' + 'destination');
    }
    try {
      KeyPair.fromAccountId(destination);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'destination');
    }

    String? destAssetStr = _removeComment(map[opPrefix + 'destAsset']);
    if (destAssetStr == null) {
      throw Exception('missing $opPrefix' + 'destAsset');
    }
    Asset? destAsset;
    try {
      destAsset = _decodeAsset(destAssetStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'destAsset');
    }
    if (destAsset == null) {
      throw Exception('invalid $opPrefix' + 'destAsset');
    }

    String? destMinStr = _removeComment(map[opPrefix + 'destMin']);
    if (destMinStr == null) {
      throw Exception('missing $opPrefix' + 'destMin');
    }
    String? destMin;
    try {
      destMin = _fromAmount(destMinStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'destMin');
    }
    if (destMin == null) {
      throw Exception('invalid $opPrefix' + 'destMin');
    }

    List<Asset?> path = [];
    String pathLengthKey = opPrefix + 'path.len';
    if (map[pathLengthKey] != null) {
      int pathLen = 0;
      try {
        pathLen = int.parse(_removeComment(map[pathLengthKey])!);
      } catch (e) {
        throw Exception('invalid $pathLengthKey');
      }
      if (pathLen > 5) {
        throw Exception(
            'path.len can not be greater than 5 in $pathLengthKey but is $pathLen');
      }
      for (int i = 0; i < pathLen; i++) {
        String? nextAssetStr = _removeComment(map[opPrefix + 'path[$i]']);
        if (nextAssetStr == null) {
          throw Exception('missing $opPrefix' + 'path[$i]');
        }
        try {
          Asset? nextAsset = _decodeAsset(nextAssetStr);
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
          .setMuxedSourceAccount(MuxedAccount.fromAccountId(sourceAccountId)!);
    }
    return builder.build();
  }

  static ManageSellOfferOperation _getManageSellOfferOperation(
      String? sourceAccountId, String opPrefix, Map<String, String> map) {
    String? sellingStr = _removeComment(map[opPrefix + 'selling']);
    if (sellingStr == null) {
      throw Exception('missing $opPrefix' + 'selling');
    }
    Asset? selling;
    try {
      selling = _decodeAsset(sellingStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'selling');
    }
    if (selling == null) {
      throw Exception('invalid $opPrefix' + 'selling');
    }
    String? buyingStr = _removeComment(map[opPrefix + 'buying']);
    if (buyingStr == null) {
      throw Exception('missing $opPrefix' + 'buying');
    }
    Asset? buying;
    try {
      buying = _decodeAsset(buyingStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'buying');
    }
    if (buying == null) {
      throw Exception('invalid $opPrefix' + 'buying');
    }

    String? amountStr = _removeComment(map[opPrefix + 'amount']);
    if (amountStr == null) {
      throw Exception('missing $opPrefix' + 'amount');
    }
    String? amount;
    try {
      amount = _fromAmount(amountStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'amount');
    }
    if (amount == null) {
      throw Exception('invalid $opPrefix' + 'amount');
    }

    String? priceNStr = _removeComment(map[opPrefix + 'price.n']);
    if (priceNStr == null) {
      throw Exception('missing $opPrefix' + 'price.n');
    }
    int? n;
    try {
      n = int.tryParse(priceNStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'price.n');
    }
    if (n == null) {
      throw Exception('invalid $opPrefix' + 'price.n');
    }

    String? priceDStr = _removeComment(map[opPrefix + 'price.d']);
    if (priceDStr == null) {
      throw Exception('missing $opPrefix' + 'price.d');
    }
    int? d;
    try {
      d = int.tryParse(priceDStr);
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

    String? offerIdStr = _removeComment(map[opPrefix + 'offerID']);
    if (offerIdStr == null) {
      throw Exception('missing $opPrefix' + 'offerID');
    }
    int? offerId;
    try {
      offerId = int.tryParse(offerIdStr);
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
          .setMuxedSourceAccount(MuxedAccount.fromAccountId(sourceAccountId)!);
    }
    return builder.build();
  }

  static ManageBuyOfferOperation _getManageBuyOfferOperation(
      String? sourceAccountId, String opPrefix, Map<String, String> map) {
    String? sellingStr = _removeComment(map[opPrefix + 'selling']);
    if (sellingStr == null) {
      throw Exception('missing $opPrefix' + 'selling');
    }
    Asset? selling;
    try {
      selling = _decodeAsset(sellingStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'selling');
    }
    if (selling == null) {
      throw Exception('invalid $opPrefix' + 'selling');
    }
    String? buyingStr = _removeComment(map[opPrefix + 'buying']);
    if (buyingStr == null) {
      throw Exception('missing $opPrefix' + 'buying');
    }
    Asset? buying;
    try {
      buying = _decodeAsset(buyingStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'buying');
    }
    if (buying == null) {
      throw Exception('invalid $opPrefix' + 'buying');
    }

    String? amountStr = _removeComment(map[opPrefix + 'buyAmount']);
    if (amountStr == null) {
      throw Exception('missing $opPrefix' + 'buyAmount');
    }
    String? buyAmount;
    try {
      buyAmount = _fromAmount(amountStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'buyAmount');
    }
    if (buyAmount == null) {
      throw Exception('invalid $opPrefix' + 'buyAmount');
    }

    String? priceNStr = _removeComment(map[opPrefix + 'price.n']);
    if (priceNStr == null) {
      throw Exception('missing $opPrefix' + 'price.n');
    }
    int? n;
    try {
      n = int.tryParse(priceNStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'price.n');
    }
    if (n == null) {
      throw Exception('invalid $opPrefix' + 'price.n');
    }

    String? priceDStr = _removeComment(map[opPrefix + 'price.d']);
    if (priceDStr == null) {
      throw Exception('missing $opPrefix' + 'price.d');
    }
    int? d;
    try {
      d = int.tryParse(priceDStr);
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

    String? offerIdStr = _removeComment(map[opPrefix + 'offerID']);
    if (offerIdStr == null) {
      throw Exception('missing $opPrefix' + 'offerID');
    }
    int? offerId;
    try {
      offerId = int.tryParse(offerIdStr);
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
          .setMuxedSourceAccount(MuxedAccount.fromAccountId(sourceAccountId)!);
    }
    return builder.build();
  }

  static CreatePassiveSellOfferOperation _getCreatePassiveSellOfferOperation(
      String? sourceAccountId, String opPrefix, Map<String, String> map) {
    String? sellingStr = _removeComment(map[opPrefix + 'selling']);
    if (sellingStr == null) {
      throw Exception('missing $opPrefix' + 'selling');
    }
    Asset? selling;
    try {
      selling = _decodeAsset(sellingStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'selling');
    }
    if (selling == null) {
      throw Exception('invalid $opPrefix' + 'selling');
    }
    String? buyingStr = _removeComment(map[opPrefix + 'buying']);
    if (buyingStr == null) {
      throw Exception('missing $opPrefix' + 'buying');
    }
    Asset? buying;
    try {
      buying = _decodeAsset(buyingStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'buying');
    }
    if (buying == null) {
      throw Exception('invalid $opPrefix' + 'buying');
    }

    String? amountStr = _removeComment(map[opPrefix + 'amount']);
    if (amountStr == null) {
      throw Exception('missing $opPrefix' + 'amount');
    }
    String? amount;
    try {
      amount = _fromAmount(amountStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'amount');
    }
    if (amount == null) {
      throw Exception('invalid $opPrefix' + 'amount');
    }

    String? priceNStr = _removeComment(map[opPrefix + 'price.n']);
    if (priceNStr == null) {
      throw Exception('missing $opPrefix' + 'price.n');
    }
    int? n;
    try {
      n = int.tryParse(priceNStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'price.n');
    }
    if (n == null) {
      throw Exception('invalid $opPrefix' + 'price.n');
    }

    String? priceDStr = _removeComment(map[opPrefix + 'price.d']);
    if (priceDStr == null) {
      throw Exception('missing $opPrefix' + 'price.d');
    }
    int? d;
    try {
      d = int.tryParse(priceDStr);
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
          .setMuxedSourceAccount(MuxedAccount.fromAccountId(sourceAccountId)!);
    }
    return builder.build();
  }

  static SetOptionsOperation _getSetOptionsOperation(
      String? sourceAccountId, String opPrefix, Map<String, String> map) {
    String? present = _removeComment(map[opPrefix + 'inflationDest._present']);
    if (present == null) {
      throw Exception('missing $opPrefix' + 'inflationDest._present');
    }

    String? inflationDest;
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
    int? clearFlags;
    if (present == 'true') {
      String? clearFlagsStr = _removeComment(map[opPrefix + 'clearFlags']);
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
    int? setFlags;
    if (present == 'true') {
      String? setFlagsStr = _removeComment(map[opPrefix + 'setFlags']);
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
    int? masterWeight;
    if (present == 'true') {
      String? masterWeightStr = _removeComment(map[opPrefix + 'masterWeight']);
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
    int? lowThreshold;
    if (present == 'true') {
      String? lowThresholdStr = _removeComment(map[opPrefix + 'lowThreshold']);
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
    int? medThreshold;
    if (present == 'true') {
      String? medThresholdStr = _removeComment(map[opPrefix + 'medThreshold']);
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
    int? highThreshold;
    if (present == 'true') {
      String? highThresholdStr =
          _removeComment(map[opPrefix + 'highThreshold']);
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

    String? homeDomain;
    if (present == 'true') {
      homeDomain =
          _removeComment(map[opPrefix + 'homeDomain'])?.replaceAll('"', '') ??
              null; //TODO improve this.

      if (homeDomain == null) {
        throw Exception('missing $opPrefix' + 'homeDomain');
      }
    }

    present = _removeComment(map[opPrefix + 'signer._present']);
    if (present == null) {
      throw Exception('missing $opPrefix' + 'signer._present');
    }

    XdrSignerKey? signer;
    int? signerWeight;

    if (present == 'true') {
      String? signerWeightStr = _removeComment(map[opPrefix + 'signer.weight']);
      if (signerWeightStr == null) {
        throw Exception('missing $opPrefix' + 'signer.weight');
      }
      try {
        signerWeight = int.parse(signerWeightStr);
      } catch (e) {
        throw Exception('invalid $opPrefix' + 'signer.weight');
      }

      String? key = _removeComment(map[opPrefix + 'signer.key']);
      if (key == null) {
        throw Exception('missing $opPrefix' + 'signer.key');
      }

      try {
        if (key.startsWith('G')) {
          signer = XdrSignerKey();
          signer.discriminant = XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519;
          signer.ed25519 = XdrUint256();
          signer.ed25519!.uint256 = StrKey.decodeStellarAccountId(key);
        } else if (key.startsWith('T')) {
          signer = XdrSignerKey();
          signer.discriminant = XdrSignerKeyType.SIGNER_KEY_TYPE_PRE_AUTH_TX;
          signer.preAuthTx = XdrUint256();
          signer.preAuthTx!.uint256 = StrKey.decodePreAuthTx(key);
        } else if (key.startsWith('X')) {
          signer = XdrSignerKey();
          signer.discriminant = XdrSignerKeyType.SIGNER_KEY_TYPE_HASH_X;
          signer.hashX = XdrUint256();
          signer.hashX!.uint256 = StrKey.decodeSha256Hash(key);
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
          .setMuxedSourceAccount(MuxedAccount.fromAccountId(sourceAccountId)!);
    }
    return builder.build();
  }

  static ChangeTrustOperation _getChangeTrustOperation(
      String? sourceAccountId, String opPrefix, Map<String, String> map) {
    String? assetStr = _removeComment(map[opPrefix + 'line']);
    if (assetStr == null) {
      throw Exception('missing $opPrefix' + 'line');
    }
    Asset? asset;
    try {
      asset = _decodeAsset(assetStr);
    } catch (e) {
      throw Exception('invalid $opPrefix' + 'line');
    }
    if (asset == null) {
      throw Exception('invalid $opPrefix' + 'line');
    }

    String? limit;
    String? limitStr = _removeComment(map[opPrefix + 'limit']);
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
          .setMuxedSourceAccount(MuxedAccount.fromAccountId(sourceAccountId)!);
    }
    return builder.build();
  }

  static AllowTrustOperation _getAllowTrustOperation(
      String? sourceAccountId, String opPrefix, Map<String, String> map) {
    String? trustor = _removeComment(map[opPrefix + 'trustor']);
    if (trustor == null) {
      throw Exception('missing $opPrefix' + 'trustor');
    }
    String? assetCode = _removeComment(map[opPrefix + 'asset']);
    if (assetCode == null) {
      throw Exception('missing $opPrefix' + 'asset');
    }
    String? authStr = _removeComment(map[opPrefix + 'authorize']);
    if (authStr == null) {
      throw Exception('missing $opPrefix' + 'authorize');
    }
    int? authorize;
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
          .setMuxedSourceAccount(MuxedAccount.fromAccountId(sourceAccountId)!);
    }
    return builder.build();
  }

  static AccountMergeOperation _getAccountMergeOperation(
      String? sourceAccountId,
      int index,
      Map<String, String> map,
      String txPrefix) {
    String? destination =
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
          .setMuxedSourceAccount(MuxedAccount.fromAccountId(sourceAccountId)!);
    }
    return builder.build();
  }

  static ManageDataOperation _getManageDataOperation(
      String? sourceAccountId, String opPrefix, Map<String, String> map) {
    String? dataName = _removeComment(map[opPrefix + 'dataName']);
    if (dataName == null) {
      throw Exception('missing $opPrefix' + 'dataName');
    } else {
      dataName = dataName.replaceAll('"', '');
    }
    Uint8List? value;
    String? present = _removeComment(map[opPrefix + 'dataValue._present']);
    if (present == null) {
      throw Exception('missing $opPrefix' + 'dataValue._present');
    }
    if (present == 'true') {
      String? dataValueStr = _removeComment(map[opPrefix + 'dataValue']);
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
          .setMuxedSourceAccount(MuxedAccount.fromAccountId(sourceAccountId)!);
    }
    return builder.build();
  }

  static BumpSequenceOperation _getBumpSequenceOperation(
      String? sourceAccountId, String opPrefix, Map<String, String> map) {
    String? bumpToStr = _removeComment(map[opPrefix + 'bumpTo']);
    if (bumpToStr == null) {
      throw Exception('missing $opPrefix' + 'bumpTo');
    }

    int? bumpTo;
    try {
      bumpTo = int.tryParse(bumpToStr);
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

  static String? _removeComment(String? value) {
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
    lines.add('$key: $value');
  }

  static _addPreconditions(
      TransactionPreconditions? cond, List<String>? lines, String prefix) {
    if (lines == null) return;
    if (cond == null || (!cond.hasV2() && cond.timeBounds == null)) {
      _addLine('${prefix}cond.type', 'PRECOND_NONE', lines);
      return;
    }
    if (cond.hasV2()) {
      _addLine('${prefix}cond.type', 'PRECOND_V2', lines);
      String precondPrefix = prefix + "cond.v2.";
      _addTimeBounds(cond.timeBounds, lines, precondPrefix);
      _addLedgerBounds(cond.ledgerBounds, lines, precondPrefix);

      if (cond.minSeqNumber != null) {
        _addLine('${precondPrefix}minSeqNum._present', 'true', lines);
        _addLine(
            '${precondPrefix}minSeqNum', cond.minSeqNumber.toString(), lines);
      } else {
        _addLine('${precondPrefix}minSeqNum._present', 'false', lines);
      }
      _addLine('${precondPrefix}minSeqAge', cond.minSeqAge.toString(), lines);
      _addLine('${precondPrefix}minSeqLedgerGap',
          cond.minSeqLedgerGap.toString(), lines);

      _addLine('${precondPrefix}extraSigners.len',
          cond.extraSigners!.length.toString(), lines);
      int index = 0;
      for (XdrSignerKey? key in cond.extraSigners!) {
        if (key?.ed25519 != null) {
          _addLine('${precondPrefix}extraSigners[${index.toString()}]',
              StrKey.encodeStellarAccountId(key!.ed25519!.uint256!), lines);
        } else if (key?.preAuthTx != null) {
          _addLine('${precondPrefix}extraSigners[${index.toString()}]',
              StrKey.encodePreAuthTx(key!.preAuthTx!.uint256!), lines);
        } else if (key?.hashX != null) {
          _addLine('${precondPrefix}extraSigners[${index.toString()}]',
              StrKey.encodeSha256Hash(key!.hashX!.uint256!), lines);
        } else if (key?.signedPayload != null) {
          _addLine('${precondPrefix}extraSigners[${index.toString()}]',
              StrKey.encodeXdrSignedPayload(key!.signedPayload!), lines);
        }
        index++;
      }
    } else if (cond.timeBounds != null) {
      _addLine('${prefix}cond.type', 'PRECOND_TIME', lines);
      _addLine('${prefix}cond.timeBounds.minTime',
          cond.timeBounds!.minTime.toString(), lines);
      _addLine('${prefix}cond.timeBounds.maxTime',
          cond.timeBounds!.maxTime.toString(), lines);
    }
  }

  static _addTimeBounds(
      TimeBounds? timeBounds, List<String>? lines, String prefix) {
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

  static _addLedgerBounds(
      LedgerBounds? ledgerBounds, List<String>? lines, String prefix) {
    if (lines == null) return;
    if (ledgerBounds == null) {
      _addLine('${prefix}ledgerBounds._present', 'false', lines);
    } else {
      _addLine('${prefix}ledgerBounds._present', 'true', lines);
      _addLine('${prefix}ledgerBounds.minLedger',
          ledgerBounds.minLedger.toString(), lines);
      _addLine('${prefix}ledgerBounds.maxLedger',
          ledgerBounds.maxLedger.toString(), lines);
    }
  }

  static _addMemo(Memo? memo, List<String>? lines, String prefix) {
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
      _addLine('${prefix}memo.hash', memo.hexValue!, lines);
    } else if (memo is MemoReturnHash) {
      _addLine('${prefix}memo.type', 'MEMO_RETURN', lines);
      _addLine('${prefix}memo.retHash', memo.hexValue!, lines);
    }
  }

  static _addOperations(
      List<Operation?>? operations, List<String>? lines, String prefix) {
    if (lines == null) return;
    if (operations == null) {
      _addLine('${prefix}operations.len', '0', lines);
      return;
    }
    _addLine('${prefix}operations.len', operations.length.toString(), lines);
    int index = 0;
    for (Operation? op in operations) {
      _addOperation(op, index, lines, prefix);
      index++;
    }
  }

  static _addOperation(
      Operation? operation, int index, List<String>? lines, String txPrefix) {
    if (lines == null || operation == null) return;

    if (operation.sourceAccount != null) {
      _addLine('${txPrefix}operations[$index].sourceAccount._present', 'true',
          lines);
      _addLine('${txPrefix}operations[$index].sourceAccount',
          operation.sourceAccount!.accountId, lines);
    } else {
      _addLine('${txPrefix}operations[$index].sourceAccount._present', 'false',
          lines);
    }

    _addLine('${txPrefix}operations[$index].body.type',
        _txRepOpTypeUpperCase(operation), lines);
    String prefix =
        '${txPrefix}operations[$index].body.${_txRepOpType(operation)}';

    if (operation is CreateAccountOperation) {
      _addLine('$prefix.destination', operation.destination!, lines);
      _addLine('$prefix.startingBalance', _toAmount(operation.startingBalance!),
          lines);
    } else if (operation is PaymentOperation) {
      _addLine('$prefix.destination', operation.destination!.accountId, lines);
      _addLine('$prefix.asset', _encodeAsset(operation.asset!), lines);
      _addLine('$prefix.amount', _toAmount(operation.amount!), lines);
    } else if (operation is PathPaymentStrictReceiveOperation) {
      _addLine('$prefix.sendAsset', _encodeAsset(operation.sendAsset!), lines);
      _addLine('$prefix.sendMax', _toAmount(operation.sendMax!), lines);
      _addLine('$prefix.destination', operation.destination!.accountId, lines);
      _addLine('$prefix.destAsset', _encodeAsset(operation.destAsset!), lines);
      _addLine('$prefix.destAmount', _toAmount(operation.destAmount!), lines);
      _addLine('$prefix.path.len', operation.path!.length.toString(), lines);
      int assetIndex = 0;
      for (Asset? asset in operation.path!) {
        _addLine('$prefix.path[$assetIndex]', _encodeAsset(asset!), lines);
        assetIndex++;
      }
    } else if (operation is PathPaymentStrictSendOperation) {
      _addLine('$prefix.sendAsset', _encodeAsset(operation.sendAsset!), lines);
      _addLine('$prefix.sendAmount', _toAmount(operation.sendAmount!), lines);
      _addLine('$prefix.destination', operation.destination!.accountId, lines);
      _addLine('$prefix.destAsset', _encodeAsset(operation.destAsset!), lines);
      _addLine('$prefix.destMin', _toAmount(operation.destMin!), lines);
      _addLine('$prefix.path.len', operation.path!.length.toString(), lines);
      int assetIndex = 0;
      for (Asset? asset in operation.path!) {
        _addLine('$prefix.path[$assetIndex]', _encodeAsset(asset!), lines);
        assetIndex++;
      }
    } else if (operation is ManageSellOfferOperation) {
      _addLine('$prefix.selling', _encodeAsset(operation.selling!), lines);
      _addLine('$prefix.buying', _encodeAsset(operation.buying!), lines);
      _addLine('$prefix.amount', _toAmount(operation.amount!), lines);
      Price price = Price.fromString(operation.price!);
      _addLine('$prefix.price.n', price.n.toString(), lines);
      _addLine('$prefix.price.d', price.d.toString(), lines);
      _addLine('$prefix.offerID', operation.offerId!, lines);
    } else if (operation is CreatePassiveSellOfferOperation) {
      _addLine('$prefix.selling', _encodeAsset(operation.selling!), lines);
      _addLine('$prefix.buying', _encodeAsset(operation.buying!), lines);
      _addLine('$prefix.amount', _toAmount(operation.amount!), lines);
      Price price = Price.fromString(operation.price!);
      _addLine('$prefix.price.n', price.n.toString(), lines);
      _addLine('$prefix.price.d', price.d.toString(), lines);
    } else if (operation is SetOptionsOperation) {
      if (operation.inflationDestination != null) {
        _addLine('$prefix.inflationDest._present', 'true', lines);
        _addLine(
            '$prefix.inflationDest', operation.inflationDestination!, lines);
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
        if (operation.signer?.ed25519 != null) {
          _addLine(
              '$prefix.signer.key',
              StrKey.encodeStellarAccountId(
                  operation.signer!.ed25519!.uint256!),
              lines);
        } else if (operation.signer?.preAuthTx != null) {
          _addLine(
              '$prefix.signer.key',
              StrKey.encodePreAuthTx(operation.signer!.preAuthTx!.uint256!),
              lines);
        } else if (operation.signer?.hashX != null) {
          _addLine(
              '$prefix.signer.key',
              StrKey.encodeSha256Hash(operation.signer!.hashX!.uint256!),
              lines);
        } else if (operation.signer?.signedPayload != null) {
          _addLine(
              '$prefix.signer.key',
              StrKey.encodeXdrSignedPayload(operation.signer!.signedPayload!),
              lines);
        }
        _addLine(
            '$prefix.signer.weight', operation.signerWeight.toString(), lines);
      } else {
        _addLine('$prefix.signer._present', 'false', lines);
      }
    } else if (operation is ChangeTrustOperation) {
      _addLine('$prefix.line', _encodeAsset(operation.asset!), lines);
      _addLine('$prefix.limit', _toAmount(operation.limit!), lines);
    } else if (operation is AllowTrustOperation) {
      _addLine('$prefix.trustor', operation.trustor!, lines);
      _addLine('$prefix.asset', operation.assetCode!, lines);
      int auth = operation.authorize! ? 1 : 0;
      auth = operation.authorizeToMaintainLiabilities! ? 2 : auth;
      _addLine('$prefix.authorize', auth.toString(), lines);
    } else if (operation is AccountMergeOperation) {
      // account merge does not include 'accountMergeOp' prefix
      _addLine('${txPrefix}operations[$index].body.destination',
          operation.destination!.accountId, lines);
    } else if (operation is ManageDataOperation) {
      final jsonEncoder = JsonEncoder();
      _addLine('$prefix.dataName', jsonEncoder.convert(operation.name), lines);
      if (operation.value != null) {
        _addLine('$prefix.dataValue._present', 'true', lines);
        _addLine('$prefix.dataValue', Util.bytesToHex(operation.value!), lines);
      } else {
        _addLine('$prefix.dataValue._present', 'false', lines);
      }
    } else if (operation is BumpSequenceOperation) {
      _addLine('$prefix.bumpTo', operation.bumpTo.toString(), lines);
    } else if (operation is ManageBuyOfferOperation) {
      _addLine('$prefix.selling', _encodeAsset(operation.selling!), lines);
      _addLine('$prefix.buying', _encodeAsset(operation.buying!), lines);
      _addLine('$prefix.buyAmount', _toAmount(operation.amount!), lines);
      Price price = Price.fromString(operation.price!);
      _addLine('$prefix.price.n', price.n.toString(), lines);
      _addLine('$prefix.price.d', price.d.toString(), lines);
      _addLine('$prefix.offerID', operation.offerId!, lines);
    } else if (operation is CreateClaimableBalanceOperation) {
      _addLine('$prefix.asset', _encodeAsset(operation.asset!), lines);
      _addLine('$prefix.amount', _toAmount(operation.amount!), lines);
      List<Claimant?>? claimants = operation.claimants;
      if (claimants != null) {
        int claimantsLen = claimants.length;
        _addLine('$prefix.claimants.len', claimantsLen.toString(), lines);
        for (int i = 0; i < claimantsLen; i++) {
          Claimant? claimant = claimants[i];
          if (claimant != null) {
            _addLine('$prefix.claimants[$i].type', "CLAIMANT_TYPE_V0", lines);
            _addLine('$prefix.claimants[$i].v0.destination',
                claimant.destination!, lines);
            String px = '$prefix.claimants[$i].v0.predicate';
            _addClaimPredicate(claimant.predicate, lines, px);
          }
        }
      }
    } else if (operation is ClaimClaimableBalanceOperation) {
      _addLine('$prefix.balanceID.type', "CLAIMABLE_BALANCE_ID_TYPE_V0", lines);
      _addLine('$prefix.balanceID.v0', operation.balanceId!, lines);
    } else if (operation is BeginSponsoringFutureReservesOperation) {
      _addLine('$prefix.sponsoredID', operation.sponsoredId!, lines);
    } else if (operation is RevokeSponsorshipOperation) {
      XdrLedgerKey? ledgerKey = operation.ledgerKey;
      XdrSignerKey? signerKey = operation.signerKey;
      String? signerAccountId = operation.signerAccountId;
      if (ledgerKey != null) {
        _addLine('$prefix.type', "REVOKE_SPONSORSHIP_LEDGER_ENTRY", lines);
        if (ledgerKey.discriminant == XdrLedgerEntryType.ACCOUNT) {
          _addLine('$prefix.ledgerKey.type', "ACCOUNT", lines);
          _addLine('$prefix.ledgerKey.account.accountID',
              ledgerKey.getAccountAccountId()!, lines);
        } else if (ledgerKey.discriminant == XdrLedgerEntryType.TRUSTLINE) {
          _addLine('$prefix.ledgerKey.type', "TRUSTLINE", lines);
          _addLine('$prefix.ledgerKey.trustLine.accountID',
              ledgerKey.getTrustlineAccountId()!, lines);
          _addLine('$prefix.ledgerKey.trustLine.asset',
              _encodeAsset(Asset.fromXdr(ledgerKey.trustLine!.asset!)), lines);
        } else if (ledgerKey.discriminant == XdrLedgerEntryType.OFFER) {
          _addLine('$prefix.ledgerKey.type', "OFFER", lines);
          _addLine('$prefix.ledgerKey.offer.sellerID',
              ledgerKey.getOfferSellerId()!, lines);
          _addLine('$prefix.ledgerKey.offer.offerID',
              ledgerKey.getOfferOfferId().toString(), lines);
        } else if (ledgerKey.discriminant == XdrLedgerEntryType.DATA) {
          _addLine('$prefix.ledgerKey.type', "DATA", lines);
          _addLine('$prefix.ledgerKey.data.accountID',
              ledgerKey.getDataAccountId()!, lines);
          final jsonEncoder = JsonEncoder();
          _addLine('$prefix.ledgerKey.data.dataName',
              jsonEncoder.convert(ledgerKey.data!.dataName!.string64!), lines);
        } else if (ledgerKey.discriminant ==
            XdrLedgerEntryType.CLAIMABLE_BALANCE) {
          _addLine('$prefix.ledgerKey.type', "CLAIMABLE_BALANCE", lines);
          _addLine('$prefix.ledgerKey.claimableBalance.balanceID.type',
              "CLAIMABLE_BALANCE_ID_TYPE_V0", lines);
          _addLine('$prefix.ledgerKey.claimableBalance.balanceID.v0',
              ledgerKey.getClaimableBalanceId()!, lines);
        }
      } else if (signerKey != null && signerAccountId != null) {
        _addLine('$prefix.type', "REVOKE_SPONSORSHIP_SIGNER", lines);
        _addLine('$prefix.signer.accountID', signerAccountId, lines);
        if (signerKey.ed25519 != null) {
          _addLine(
              '$prefix.signer.signerKey',
              StrKey.encodeStellarAccountId(signerKey.ed25519!.uint256!),
              lines);
        } else if (signerKey.preAuthTx != null) {
          _addLine('$prefix.signer.signerKey',
              StrKey.encodePreAuthTx(signerKey.preAuthTx!.uint256!), lines);
        } else if (signerKey.hashX != null) {
          _addLine('$prefix.signer.signerKey',
              StrKey.encodeSha256Hash(signerKey.hashX!.uint256!), lines);
        }
      }
    } else if (operation is ClawbackOperation) {
      _addLine('$prefix.asset', _encodeAsset(operation.asset!), lines);
      _addLine('$prefix.from', operation.from!.accountId, lines);
      _addLine('$prefix.amount', _toAmount(operation.amount!), lines);
    } else if (operation is ClawbackClaimableBalanceOperation) {
      _addLine('$prefix.balanceID.type', 'CLAIMABLE_BALANCE_ID_TYPE_V0', lines);
      _addLine('$prefix.balanceID.v0', operation.balanceId!, lines);
    } else if (operation is SetTrustLineFlagsOperation) {
      _addLine('$prefix.trustor', operation.trustorId!, lines);
      _addLine('$prefix.asset', _encodeAsset(operation.asset!), lines);
      _addLine('$prefix.clearFlags', operation.clearFlags!.toString(), lines);
      _addLine('$prefix.setFlags', operation.setFlags!.toString(), lines);
    } else if (operation is LiquidityPoolDepositOperation) {
      _addLine('$prefix.liquidityPoolID', operation.liquidityPoolId, lines);
      _addLine('$prefix.maxAmountA', _toAmount(operation.maxAmountA), lines);
      _addLine('$prefix.maxAmountB', _toAmount(operation.maxAmountB), lines);
      Price minPrice = Price.fromString(operation.minPrice);
      Price maxPrice = Price.fromString(operation.maxPrice);
      _addLine('$prefix.minPrice.n', minPrice.n.toString(), lines);
      _addLine('$prefix.minPrice.d', minPrice.d.toString(), lines);
      _addLine('$prefix.maxPrice.n', maxPrice.n.toString(), lines);
      _addLine('$prefix.maxPrice.d', maxPrice.d.toString(), lines);
    } else if (operation is LiquidityPoolWithdrawOperation) {
      _addLine('$prefix.liquidityPoolID', operation.liquidityPoolId, lines);
      _addLine('$prefix.amount', _toAmount(operation.amount), lines);
      _addLine('$prefix.minAmountA', _toAmount(operation.minAmountA), lines);
      _addLine('$prefix.minAmountB', _toAmount(operation.minAmountB), lines);
    }
  }

  static _addClaimPredicate(
      XdrClaimPredicate? predicate, List<String>? lines, String prefix) {
    if (lines == null || predicate == null) return;
    switch (predicate.discriminant) {
      case XdrClaimPredicateType.CLAIM_PREDICATE_UNCONDITIONAL:
        _addLine('$prefix.type', "CLAIM_PREDICATE_UNCONDITIONAL", lines);
        return;
      case XdrClaimPredicateType.CLAIM_PREDICATE_AND:
        _addLine('$prefix.type', "CLAIM_PREDICATE_AND", lines);
        List<XdrClaimPredicate?>? andPredicates = predicate.andPredicates;
        if (andPredicates != null) {
          int count = andPredicates.length;
          _addLine('$prefix.andPredicates.len', count.toString(), lines);
          for (int i = 0; i < count; i++) {
            String px = '$prefix.andPredicates[$i]';
            _addClaimPredicate(andPredicates[i], lines, px);
          }
        }
        return;
      case XdrClaimPredicateType.CLAIM_PREDICATE_OR:
        _addLine('$prefix.type', "CLAIM_PREDICATE_OR", lines);
        List<XdrClaimPredicate?>? orPredicates = predicate.orPredicates;
        if (orPredicates != null) {
          int count = orPredicates.length;
          _addLine('$prefix.orPredicates.len', count.toString(), lines);
          for (int i = 0; i < count; i++) {
            String px = '$prefix.orPredicates[$i]';
            _addClaimPredicate(orPredicates[i], lines, px);
          }
        }
        return;
      case XdrClaimPredicateType.CLAIM_PREDICATE_NOT:
        _addLine('$prefix.type', "CLAIM_PREDICATE_NOT", lines);
        if (predicate.notPredicate != null) {
          _addLine('$prefix.notPredicate._present', 'true', lines);
          String px = '$prefix.notPredicate';
          _addClaimPredicate(predicate.notPredicate, lines, px);
        } else {
          _addLine('$prefix.notPredicate._present', 'false', lines);
        }
        return;
      case XdrClaimPredicateType.CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME:
        _addLine('$prefix.type', "CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME", lines);
        if (predicate.absBefore?.int64 != null) {
          _addLine('$prefix.absBefore', predicate.absBefore!.int64!.toString(),
              lines);
        }
        return;
      case XdrClaimPredicateType.CLAIM_PREDICATE_BEFORE_RELATIVE_TIME:
        _addLine('$prefix.type', "CLAIM_PREDICATE_BEFORE_RELATIVE_TIME", lines);
        if (predicate.relBefore?.int64 != null) {
          _addLine('$prefix.relBefore', predicate.relBefore!.int64!.toString(),
              lines);
        }
        return;
      default:
        return;
    }
  }

  static _addSignatures(List<XdrDecoratedSignature?>? signatures,
      List<String>? lines, String prefix) {
    if (lines == null) return;
    if (signatures == null) {
      _addLine('${prefix}signatures.len', '0', lines);
      return;
    }
    _addLine('${prefix}signatures.len', signatures.length.toString(), lines);
    int index = 0;
    for (XdrDecoratedSignature? sig in signatures) {
      _addSignature(sig, index, lines, prefix);
      index++;
    }
  }

  static _addSignature(XdrDecoratedSignature? signature, int index,
      List<String>? lines, String prefix) {
    if (lines == null || signature == null) return;
    _addLine('${prefix}signatures[$index].hint',
        Util.bytesToHex(signature.hint!.signatureHint!), lines);
    _addLine('${prefix}signatures[$index].signature',
        Util.bytesToHex(signature.signature!.signature!), lines);
  }

  static String _txRepOpTypeUpperCase(Operation operation) {
    int value = operation.toXdr().body!.discriminant!.value;
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
      case 14:
        return 'CREATE_CLAIMABLE_BALANCE';
      case 15:
        return 'CLAIM_CLAIMABLE_BALANCE';
      case 16:
        return 'BEGIN_SPONSORING_FUTURE_RESERVES';
      case 17:
        return 'END_SPONSORING_FUTURE_RESERVES';
      case 18:
        return 'REVOKE_SPONSORSHIP';
      case 19:
        return 'CLAWBACK';
      case 20:
        return 'CLAWBACK_CLAIMABLE_BALANCE';
      case 21:
        return 'SET_TRUST_LINE_FLAGS';
      case 22:
        return 'LIQUIDITY_POOL_DEPOSIT';
      case 23:
        return 'LIQUIDITY_POOL_WITHDRAW';
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static String _txRepOpType(Operation operation) {
    int value = operation.toXdr().body!.discriminant!.value;
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
      case 14:
        return 'createClaimableBalanceOp';
      case 15:
        return 'claimClaimableBalanceOp';
      case 16:
        return 'beginSponsoringFutureReservesOp';
      case 17:
        return 'endSponsoringFutureReservesOp';
      case 18:
        return 'revokeSponsorshipOp';
      case 19:
        return 'clawbackOp';
      case 20:
        return 'clawbackClaimableBalanceOp';
      case 21:
        return 'setTrustLineFlagsOp';
      case 22:
        return 'liquidityPoolDepositOp';
      case 23:
        return 'liquidityPoolWithdrawOp';
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static String _toAmount(String value) {
    Decimal amount = Decimal.parse(value) * Decimal.parse('10000000.00');
    return amount.toString();
  }

  static String? _fromAmount(String value) {
    Decimal amount = Decimal.parse(value) / Decimal.parse('10000000.00');
    return amount.toString();
  }

  static String _encodeAsset(Asset asset) {
    if (asset is AssetTypeNative) {
      return 'XLM';
    } else if (asset is AssetTypeCreditAlphaNum) {
      AssetTypeCreditAlphaNum creditAsset = asset;
      return creditAsset.code! + ":" + creditAsset.issuerId!;
    } else {
      throw Exception("unsupported asset " + asset.type);
    }
  }

  static Asset? _decodeAsset(String? asset) {
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
