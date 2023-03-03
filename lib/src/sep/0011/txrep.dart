// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';
import 'package:decimal/decimal.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

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

    List<String> lines = List<String>.empty(growable: true);
    String type = isFeeBump ? 'ENVELOPE_TYPE_TX_FEE_BUMP' : 'ENVELOPE_TYPE_TX';
    String prefix = isFeeBump ? 'feeBump.tx.innerTx.tx.' : 'tx.';

    _addLine('type', type, lines);

    if (isFeeBump) {
      _addLine('feeBump.tx.feeSource', feeBump.feeAccount.accountId, lines);
      _addLine('feeBump.tx.fee', feeBump.fee.toString(), lines);
      _addLine('feeBump.tx.innerTx.type', 'ENVELOPE_TYPE_TX', lines);
    }

    _addLine('${prefix}sourceAccount', tx!.sourceAccount.accountId, lines);
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
  static String transactionEnvelopeXdrBase64FromTxRep(String txRep) {
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
      List<XdrDecoratedSignature> signatures =
          List<XdrDecoratedSignature>.empty(growable: true);
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
      builder.setMuxedFeeAccount(MuxedAccount.fromAccountId(feeBumpSource!)!);
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
        List<XdrDecoratedSignature> fbSignatures =
            List<XdrDecoratedSignature>.empty(growable: true);
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

  static TransactionPreconditions _getPreconditions(
      Map<String, String> map, String prefix) {
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
        extraSigners = List<XdrSignerKey>.empty(growable: true);
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
              XdrSignerKey signer =
                  XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519);
              signer.ed25519 = XdrUint256(StrKey.decodeStellarAccountId(key));
              extraSigners.add(signer);
            } else if (key.startsWith('T')) {
              XdrSignerKey signer =
                  XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_PRE_AUTH_TX);
              signer.preAuthTx = XdrUint256(StrKey.decodePreAuthTx(key));
              extraSigners.add(signer);
            } else if (key.startsWith('X')) {
              XdrSignerKey signer =
                  XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_HASH_X);
              signer.hashX = XdrUint256(StrKey.decodeSha256Hash(key));
              extraSigners.add(signer);
            } else if (key.startsWith('P')) {
              XdrSignerKey signer = XdrSignerKey(
                  XdrSignerKeyType.KEY_TYPE_ED25519_SIGNED_PAYLOAD);
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
    if (opType == 'INVOKE_HOST_FUNCTION') {
      String opPrefix = prefix + 'invokeHostFunctionOp.';
      return _getInvokeHostFunctionOp(sourceAccountId, opPrefix, map);
    }
    throw Exception('invalid or unsupported [$prefix].type - $opType');
  }

  static InvokeHostFunctionOperation _getInvokeHostFunctionOp(
      String? sourceAccountId, String opPrefix, Map<String, String> map) {
    String? fnType = _removeComment(map[opPrefix + 'function.type']);
    if (fnType == null) {
      throw Exception('missing $opPrefix' + 'function.type');
    }
    if ('HOST_FUNCTION_TYPE_INSTALL_CONTRACT_CODE' == fnType) {
      XdrLedgerFootprint footprint =
          _getFootprint(opPrefix + 'footprint.', map);
      String? code = _removeComment(
          map[opPrefix + 'function.installContractCodeArgs.code']);
      if (code == null) {
        throw Exception(
            'missing $opPrefix' + 'function.installContractCodeArgs.code');
      }
      InvokeHostFuncOpBuilder builder =
          InvokeHostFuncOpBuilder.forInstallingContractCode(
              Util.hexToBytes(code),
              footprint: footprint);
      if (sourceAccountId != null) {
        builder.setMuxedSourceAccount(
            MuxedAccount.fromAccountId(sourceAccountId)!);
      }
      return builder.build();
    } else if ('HOST_FUNCTION_TYPE_CREATE_CONTRACT' == fnType) {
      XdrLedgerFootprint footprint =
          _getFootprint(opPrefix + 'footprint.', map);
      String contractArgsPrefix = opPrefix + 'function.createContractArgs.';
      String? ccType = _removeComment(map[contractArgsPrefix + 'source.type']);
      if (ccType == null) {
        throw Exception('missing $contractArgsPrefix' + 'source.type');
      }
      String? cIDType =
          _removeComment(map[contractArgsPrefix + 'contractID.type']);
      if (cIDType == null) {
        throw Exception('missing $contractArgsPrefix' + 'contractID.type');
      }
      if ('SCCONTRACT_CODE_WASM_REF' == ccType) {
        String? wasmId =
            _removeComment(map[contractArgsPrefix + 'source.wasm_id']);
        if (wasmId == null) {
          throw Exception('missing $contractArgsPrefix' + 'source.wasm_id');
        }
        String? salt =
            _removeComment(map[contractArgsPrefix + 'contractID.salt']);
        if (salt == null) {
          throw Exception('missing $contractArgsPrefix' + 'contractID.salt');
        }
        InvokeHostFuncOpBuilder builder =
            InvokeHostFuncOpBuilder.forCreatingContract(wasmId,
                salt: XdrUint256(Util.hexToBytes(salt)), footprint: footprint);
        if (sourceAccountId != null) {
          builder.setMuxedSourceAccount(
              MuxedAccount.fromAccountId(sourceAccountId)!);
        }
        return builder.build();
      } else if ('SCCONTRACT_CODE_TOKEN' == ccType) {
        if ('CONTRACT_ID_FROM_SOURCE_ACCOUNT' == cIDType) {
          String? salt =
              _removeComment(map[contractArgsPrefix + 'contractID.salt']);
          if (salt == null) {
            throw Exception('missing $contractArgsPrefix' + 'contractID.salt');
          }
          InvokeHostFuncOpBuilder builder =
              InvokeHostFuncOpBuilder.forDeploySACWithSourceAccount(
                  salt: XdrUint256(Util.hexToBytes(salt)),
                  footprint: footprint);
          if (sourceAccountId != null) {
            builder.setMuxedSourceAccount(
                MuxedAccount.fromAccountId(sourceAccountId)!);
          }
          return builder.build();
        } else if ('CONTRACT_ID_FROM_ASSET' == cIDType) {
          String? asset =
              _removeComment(map[contractArgsPrefix + 'contractID.asset']);
          if (asset == null) {
            throw Exception('missing $contractArgsPrefix' + 'contractID.asset');
          }
          InvokeHostFuncOpBuilder builder =
              InvokeHostFuncOpBuilder.forDeploySACWithAsset(
                  Asset.createFromCanonicalForm(asset)!,
                  footprint: footprint);
          if (sourceAccountId != null) {
            builder.setMuxedSourceAccount(
                MuxedAccount.fromAccountId(sourceAccountId)!);
          }
          return builder.build();
        } else {
          throw Exception('unknown $contractArgsPrefix' + 'contractID.type');
        }
      } else {
        throw Exception('unknown $contractArgsPrefix' + 'source.type');
      }
    } else if ('HOST_FUNCTION_TYPE_INVOKE_CONTRACT' == fnType) {
      XdrLedgerFootprint footprint =
          _getFootprint(opPrefix + 'footprint.', map);
      String invokeArgsPrefix = opPrefix + 'function.invokeArgs';
      String argsLengthKey = invokeArgsPrefix + '.len';
      String? argsLenS = _removeComment(map[argsLengthKey]);
      if (argsLenS == null) {
        throw Exception('missing $opPrefix' + argsLengthKey);
      }
      int argsLen = 0;
      try {
        argsLen = int.parse(argsLenS);
      } catch (e) {
        throw Exception('invalid $argsLengthKey ' + argsLenS);
      }
      if (argsLen < 2) {
        throw Exception('invalid $argsLengthKey ' + argsLenS);
      }
      String? contractId =
          _removeComment(map[invokeArgsPrefix + '[0].obj.bin']);
      if (contractId == null) {
        throw Exception('missing $invokeArgsPrefix' + '[0].obj.bin');
      }
      String? fnName = _removeComment(map[invokeArgsPrefix + '[1].sym']);
      if (fnName == null) {
        throw Exception('missing $invokeArgsPrefix' + '[1].sym');
      }
      List<XdrSCVal> args = List<XdrSCVal>.empty(growable: true);
      for (int i = 2; i < argsLen; i++) {
        XdrSCVal next = _getSCVal(invokeArgsPrefix + '[$i].', map);
        args.add(next);
      }
      List<XdrContractAuth> contractAuth =
          List<XdrContractAuth>.empty(growable: true);
      String? contractAuthLenS = _removeComment(map[opPrefix + 'auth.len']);
      if (contractAuthLenS == null) {
        throw Exception('missing $opPrefix' + 'auth.len');
      }
      int contractAuthLen = 0;
      try {
        contractAuthLen = int.parse(contractAuthLenS);
      } catch (e) {
        throw Exception('invalid $opPrefix' + 'auth.len');
      }
      for (int i = 0; i < contractAuthLen; i++) {
        XdrContractAuth next = _getContractAuth('$opPrefix' + 'auth[$i]', map);
        contractAuth.add(next);
      }

      InvokeHostFuncOpBuilder builder =
          InvokeHostFuncOpBuilder.forInvokingContract(contractId, fnName,
              functionArguments: args,
              footprint: footprint,
              contractAuth: ContractAuth.fromXdrList(contractAuth));
      if (sourceAccountId != null) {
        builder.setMuxedSourceAccount(
            MuxedAccount.fromAccountId(sourceAccountId)!);
      }
      return builder.build();
    } else {
      throw Exception('invalid $opPrefix' + 'function.type ' + fnType);
    }
  }

  static XdrContractAuth _getContractAuth(
      String prefix, Map<String, String> map) {
    XdrAddressWithNonce? addressWithNonce;
    String? present = _removeComment(map['$prefix.addressWithNonce._present']);
    if (present == null) {
      throw Exception('missing $prefix.addressWithNonce._present');
    }
    if ('true' == present) {
      addressWithNonce = _getAddressWithNonce('$prefix.addressWithNonce', map);
    }
    XdrAuthorizedInvocation rootInvocation =
        _getAuthorizedInvocation('$prefix.rootInvocation', map);

    List<XdrSCVal> args = List<XdrSCVal>.empty(growable: true);
    String? argsLenS = _removeComment(map['$prefix.signatureArgs.len']);
    if (argsLenS == null) {
      throw Exception('missing $prefix.signatureArgs.len');
    }
    int argsLen = 0;
    try {
      argsLen = int.parse(argsLenS);
    } catch (e) {
      throw Exception('invalid $prefix.signatureArgs.len');
    }
    for (int i = 0; i < argsLen; i++) {
      XdrSCVal next = _getSCVal('$prefix.signatureArgs[$i].', map);
      args.add(next);
    }
    return XdrContractAuth(addressWithNonce, rootInvocation, args);
  }

  static XdrAuthorizedInvocation _getAuthorizedInvocation(
      String prefix, Map<String, String> map) {
    String? contractID = _removeComment(map['$prefix.contractID']);
    if (contractID == null) {
      throw Exception('missing $prefix.contractID');
    }
    String? functionName = _removeComment(map['$prefix.functionName']);
    if (functionName == null) {
      throw Exception('missing $prefix.functionName');
    }

    List<XdrSCVal> args = List<XdrSCVal>.empty(growable: true);
    String? argsLenS = _removeComment(map['$prefix.args.len']);
    if (argsLenS == null) {
      throw Exception('missing $prefix.args.len');
    }
    int argsLen = 0;
    try {
      argsLen = int.parse(argsLenS);
    } catch (e) {
      throw Exception('invalid $prefix.args.len');
    }
    for (int i = 0; i < argsLen; i++) {
      XdrSCVal next = _getSCVal('$prefix.args[$i].', map);
      args.add(next);
    }

    List<XdrAuthorizedInvocation> subInvocations =
        List<XdrAuthorizedInvocation>.empty(growable: true);
    String? subInvocationsLenS =
        _removeComment(map['$prefix.subInvocations.len']);
    if (subInvocationsLenS == null) {
      throw Exception('missing $prefix.subInvocations.len');
    }
    int subInvocationsLen = 0;
    try {
      subInvocationsLen = int.parse(subInvocationsLenS);
    } catch (e) {
      throw Exception('invalid $prefix.subInvocations.len');
    }
    for (int i = 0; i < subInvocationsLen; i++) {
      XdrAuthorizedInvocation next =
          _getAuthorizedInvocation('$prefix.subInvocations[$i]', map);
      subInvocations.add(next);
    }
    return XdrAuthorizedInvocation(XdrHash(Util.hexToBytes(contractID)),
        functionName, args, subInvocations);
  }

  static XdrAddressWithNonce _getAddressWithNonce(
      String prefix, Map<String, String> map) {
    XdrSCAddress address = _getSCAddress('$prefix.address.', map);
    String? nonceS = _removeComment(map['$prefix.nonce']);
    if (nonceS == null) {
      throw Exception('missing $prefix.nonce');
    }
    int nonce = 0;
    try {
      nonce = int.parse(nonceS);
    } catch (e) {
      throw Exception('invalid $prefix.nonce');
    }
    return XdrAddressWithNonce(address, XdrUint64(nonce));
  }

  static XdrLedgerFootprint _getFootprint(
      String prefix, Map<String, String> map) {
    List<XdrLedgerKey> readOnly = List<XdrLedgerKey>.empty(growable: true);
    List<XdrLedgerKey> readWrite = List<XdrLedgerKey>.empty(growable: true);

    String readOnlyLengthKey = prefix + 'readOnly.len';
    if (map[readOnlyLengthKey] != null) {
      int readOnlyLen = 0;
      try {
        readOnlyLen = int.parse(_removeComment(map[readOnlyLengthKey])!);
      } catch (e) {
        throw Exception('invalid $readOnlyLengthKey');
      }
      for (int i = 0; i < readOnlyLen; i++) {
        XdrLedgerKey next = _getLedgerKey(prefix + 'readOnly[$i].', map);
        readOnly.add(next);
      }
    }
    String readWriteLengthKey = prefix + 'readWrite.len';
    if (map[readWriteLengthKey] != null) {
      int readWriteLen = 0;
      try {
        readWriteLen = int.parse(_removeComment(map[readWriteLengthKey])!);
      } catch (e) {
        throw Exception('invalid $readWriteLengthKey');
      }
      for (int i = 0; i < readWriteLen; i++) {
        XdrLedgerKey next = _getLedgerKey(prefix + 'readWrite[$i].', map);
        readWrite.add(next);
      }
    }
    return XdrLedgerFootprint(readOnly, readWrite);
  }

  static XdrLedgerKey _getLedgerKey(String prefix, Map<String, String> map) {
    String? type = _removeComment(map[prefix + 'type']);
    if (type == null) {
      throw Exception('missing $prefix' + 'type');
    }
    if ('ACCOUNT' == type) {
      String? accountId = _removeComment(map[prefix + 'account.accountID']);
      if (accountId == null) {
        throw Exception('missing $prefix' + 'account.accountID');
      }
      XdrLedgerKey result = XdrLedgerKey(XdrLedgerEntryType.ACCOUNT);
      KeyPair kp = KeyPair.fromAccountId(accountId);
      result.account = XdrLedgerKeyAccount(XdrAccountID(kp.xdrPublicKey));
      return result;
    } else if ('TRUSTLINE' == type) {
      String? accountId = _removeComment(map[prefix + 'trustLine.accountID']);
      if (accountId == null) {
        throw Exception('missing $prefix' + 'trustLine.accountID');
      }
      String? assetStr = _removeComment(map[prefix + 'trustLine.asset']);
      if (assetStr == null) {
        throw Exception('missing $prefix' + 'trustLine.asset');
      }
      Asset? asset;
      try {
        asset = _decodeAsset(assetStr);
      } catch (e) {
        throw Exception('invalid $prefix' + 'trustLine.asset');
      }
      if (asset == null) {
        throw Exception('invalid $prefix' + 'trustLine.asset');
      }

      XdrLedgerKey result = XdrLedgerKey(XdrLedgerEntryType.TRUSTLINE);
      KeyPair kp = KeyPair.fromAccountId(accountId);
      result.trustLine = XdrLedgerKeyTrustLine(
          XdrAccountID(kp.xdrPublicKey), asset.toXdrTrustLineAsset());
      return result;
    } else if ('CONTRACT_DATA' == type) {
      String? cId = _removeComment(map[prefix + 'contractData.contractID']);
      if (cId == null) {
        throw Exception('missing $prefix' + 'contractData.contractID');
      }
      XdrLedgerKey result = XdrLedgerKey(XdrLedgerEntryType.CONTRACT_DATA);
      result.contractID = XdrHash(Util.hexToBytes(cId));
      result.contractDataKey = _getSCVal(prefix + 'contractData.key.', map);
      return result;
    } else if ('CONTRACT_CODE' == type) {
      String? cCodeHash = _removeComment(map[prefix + 'contractCode.hash']);
      if (cCodeHash == null) {
        throw Exception('missing $prefix' + 'contractCode.hash');
      }
      XdrLedgerKey result = XdrLedgerKey(XdrLedgerEntryType.CONTRACT_CODE);
      result.contractCodeHash = XdrHash(Util.hexToBytes(cCodeHash));
      return result;
    } else {
      throw Exception('unsupported $prefix' + 'type ' + type);
    }
  }

  static XdrSCVal _getSCVal(String prefix, Map<String, String> map) {
    String? type = _removeComment(map[prefix + 'type']);
    if (type == null) {
      throw Exception('missing $prefix' + 'type');
    }
    if ('SCV_U63' == type) {
      String? u63S = _removeComment(map[prefix + 'u63']);
      if (u63S == null) {
        throw Exception('missing $prefix' + 'u63');
      }
      int u63 = 0;
      try {
        u63 = int.parse(u63S);
      } catch (e) {
        throw Exception('invalid $prefix.u63');
      }
      return XdrSCVal.forU63(u63);
    } else if ('SCV_U32' == type) {
      String? u32S = _removeComment(map[prefix + 'u32']);
      if (u32S == null) {
        throw Exception('missing $prefix' + 'u32');
      }
      int u32 = 0;
      try {
        u32 = int.parse(u32S);
      } catch (e) {
        throw Exception('invalid $prefix.u32');
      }
      return XdrSCVal.forU32(u32);
    } else if ('SCV_I32' == type) {
      String? i32S = _removeComment(map[prefix + 'i32']);
      if (i32S == null) {
        throw Exception('missing $prefix' + 'i32');
      }
      int i32 = 0;
      try {
        i32 = int.parse(i32S);
      } catch (e) {
        throw Exception('invalid $prefix.i32');
      }
      return XdrSCVal.forI32(i32);
    } else if ('SCV_STATIC' == type) {
      return XdrSCVal.forStatic(_getSCStatic(prefix, map));
    } else if ('SCV_OBJECT' == type) {
      String objPrefix = prefix + 'obj.';
      XdrSCObject? obj = _getSCObject(objPrefix, map);
      if (obj != null) {
        return XdrSCVal.forObject(obj);
      }
      return XdrSCVal(XdrSCValType.SCV_OBJECT);
    } else if ('SCV_SYMBOL' == type) {
      String? sym = _removeComment(map[prefix + 'sym']);
      if (sym == null) {
        throw Exception('missing $prefix' + 'sym');
      }
      return XdrSCVal.forSymbol(sym);
    } else if ('SCV_BITSET' == type) {
      String? bitsS = _removeComment(map[prefix + 'bits']);
      if (bitsS == null) {
        throw Exception('missing $prefix' + 'bits');
      }
      int bits = 0;
      try {
        bits = int.parse(bitsS);
      } catch (e) {
        throw Exception('invalid $prefix.bits');
      }
      return XdrSCVal.forBitset(bits);
    } else if ('SCV_STATUS' == type) {
      return XdrSCVal.forStatus(_getSCStatus(prefix + "status.", map));
    } else {
      throw Exception('unknown $prefix' + 'type');
    }
  }

  static XdrSCObject? _getSCObject(String prefix, Map<String, String> map) {
    String? present = _removeComment(map[prefix + '_present']);
    if (present == null) {
      throw Exception('missing $prefix' + '_present');
    }
    if ('true' != present) {
      return null;
    }
    String? type = _removeComment(map[prefix + 'type']);
    if (type == null) {
      throw Exception('missing $prefix' + 'type');
    }
    if ('SCO_VEC' == type) {
      return XdrSCObject.forVec(_getSCVec(prefix, map));
    } else if ('SCO_MAP' == type) {
      return XdrSCObject.forMap(_getSCMap(prefix, map));
    } else if ('SCO_U64' == type) {
      String? u64S = _removeComment(map[prefix + 'u64']);
      if (u64S == null) {
        throw Exception('missing $prefix' + 'u64');
      }
      int u64 = 0;
      try {
        u64 = int.parse(u64S);
      } catch (e) {
        throw Exception('invalid $prefix.u64');
      }
      return XdrSCObject.forU64(u64);
    } else if ('SCO_I64' == type) {
      String? i64S = _removeComment(map[prefix + 'i64']);
      if (i64S == null) {
        throw Exception('missing $prefix' + 'i64');
      }
      int i64 = 0;
      try {
        i64 = int.parse(i64S);
      } catch (e) {
        throw Exception('invalid $prefix.i64');
      }
      return XdrSCObject.forI64(i64);
    } else if ('SCO_U128' == type) {
      String? u128LoS = _removeComment(map[prefix + 'u128.lo']);
      if (u128LoS == null) {
        throw Exception('missing $prefix' + 'u128.lo');
      }
      int u128Lo = 0;
      try {
        u128Lo = int.parse(u128LoS);
      } catch (e) {
        throw Exception('invalid $prefix.u128.lo');
      }
      String? u128HiS = _removeComment(map[prefix + 'u128.hi']);
      if (u128HiS == null) {
        throw Exception('missing $prefix' + 'u128.hi');
      }
      int u128Hi = 0;
      try {
        u128Hi = int.parse(u128HiS);
      } catch (e) {
        throw Exception('invalid $prefix.u128.hi');
      }
      return XdrSCObject.forU128(
          XdrInt128Parts(XdrUint64(u128Lo), XdrUint64(u128Hi)));
    } else if ('SCO_I128' == type) {
      String? i128LoS = _removeComment(map[prefix + 'i128.lo']);
      if (i128LoS == null) {
        throw Exception('missing $prefix' + 'i128.lo');
      }
      int i128Lo = 0;
      try {
        i128Lo = int.parse(i128LoS);
      } catch (e) {
        throw Exception('invalid $prefix.i128.lo');
      }
      String? i128HiS = _removeComment(map[prefix + 'i128.hi']);
      if (i128HiS == null) {
        throw Exception('missing $prefix' + 'i128.hi');
      }
      int i128Hi = 0;
      try {
        i128Hi = int.parse(i128HiS);
      } catch (e) {
        throw Exception('invalid $prefix.i128.hi');
      }
      return XdrSCObject.forI128(
          XdrInt128Parts(XdrUint64(i128Lo), XdrUint64(i128Hi)));
    } else if ('SCO_BYTES' == type) {
      String? bin = _removeComment(map[prefix + 'bin']);
      if (bin == null) {
        throw Exception('missing $prefix' + 'bin');
      }
      return XdrSCObject.forBytes(Util.hexToBytes(bin));
    } else if ('SCO_CONTRACT_CODE' == type) {
      String contractCodePrefix = prefix + 'contractCode.';
      String? type = _removeComment(map[contractCodePrefix + 'type']);
      if (type == null) {
        throw Exception('missing $contractCodePrefix' + 'type');
      }
      if ('SCCONTRACT_CODE_WASM_REF' == type) {
        String? wasmId = _removeComment(map[contractCodePrefix + 'wasm_id']);
        if (wasmId == null) {
          throw Exception('missing $contractCodePrefix' + 'wasm_id');
        }
        XdrSCContractCode cc =
            XdrSCContractCode(XdrSCContractCodeType.SCCONTRACT_CODE_WASM_REF);
        cc.wasmId = XdrHash(Util.hexToBytes(wasmId));
        return XdrSCObject.forContractCode(cc);
      } else if ('SCCONTRACT_CODE_TOKEN' == type) {
        XdrSCContractCode cc =
            XdrSCContractCode(XdrSCContractCodeType.SCCONTRACT_CODE_TOKEN);
        return XdrSCObject.forContractCode(cc);
      } else {
        throw Exception('unknown $contractCodePrefix' + 'type');
      }
    } else if ('SCO_ADDRESS' == type) {
      return XdrSCObject.forAddress(_getSCAddress(prefix + 'address.', map));
    } else if ('SCO_NONCE_KEY' == type) {
      return XdrSCObject.forNonceKey(
          _getSCAddress(prefix + 'nonceAddress.', map));
    } else {
      throw Exception('unknown $prefix' + 'type');
    }
  }

  static XdrSCAddress _getSCAddress(String prefix, Map<String, String> map) {
    String? type = _removeComment(map[prefix + 'type']);
    if (type == null) {
      throw Exception('missing $prefix' + 'type');
    }
    if ('SC_ADDRESS_TYPE_ACCOUNT' == type) {
      String? accountId = _removeComment(map[prefix + 'accountId']);
      if (accountId == null) {
        throw Exception('missing $prefix' + 'accountId');
      }
      return XdrSCAddress.forAccountId(accountId);
    } else if ('SC_ADDRESS_TYPE_CONTRACT' == type) {
      String? contractId = _removeComment(map[prefix + 'contractId']);
      if (contractId == null) {
        throw Exception('missing $prefix' + 'contractId');
      }
      return XdrSCAddress.forContractId(contractId);
    } else {
      throw Exception('unknown $prefix' + 'type');
    }
  }

  static List<XdrSCMapEntry> _getSCMap(String prefix, Map<String, String> map) {
    List<XdrSCMapEntry> result = List<XdrSCMapEntry>.empty(growable: true);
    String mapLengthKey = prefix + 'map.len';
    if (map[mapLengthKey] != null) {
      int mapLen = 0;
      try {
        mapLen = int.parse(_removeComment(map[mapLengthKey])!);
      } catch (e) {
        throw Exception('invalid $mapLengthKey');
      }
      for (int i = 0; i < mapLen; i++) {
        XdrSCVal nextKey = _getSCVal(prefix + 'map[$i].key.', map);
        XdrSCVal nextVal = _getSCVal(prefix + 'map[$i].val.', map);
        result.add(XdrSCMapEntry(nextKey, nextVal));
      }
    }
    return result;
  }

  static List<XdrSCVal> _getSCVec(String prefix, Map<String, String> map) {
    List<XdrSCVal> result = List<XdrSCVal>.empty(growable: true);
    String vecLengthKey = prefix + 'vec.len';
    if (map[vecLengthKey] != null) {
      int vecLen = 0;
      try {
        vecLen = int.parse(_removeComment(map[vecLengthKey])!);
      } catch (e) {
        throw Exception('invalid $vecLengthKey');
      }
      for (int i = 0; i < vecLen; i++) {
        XdrSCVal next = _getSCVal(prefix + 'vec[$i].', map);
        result.add(next);
      }
    }
    return result;
  }

  static XdrSCStatic _getSCStatic(String prefix, Map<String, String> map) {
    String? ic = _removeComment(map[prefix + 'ic']);
    if (ic == null) {
      throw Exception('missing $prefix' + 'ic');
    }
    if ('SCS_VOID' == ic) {
      return XdrSCStatic.SCS_VOID;
    } else if ('SCS_TRUE' == ic) {
      return XdrSCStatic.SCS_TRUE;
    } else if ('SCS_FALSE' == ic) {
      return XdrSCStatic.SCS_FALSE;
    } else if ('SCS_LEDGER_KEY_CONTRACT_CODE' == ic) {
      return XdrSCStatic.SCS_LEDGER_KEY_CONTRACT_CODE;
    } else {
      throw Exception('unknown $prefix' + 'ic');
    }
  }

  static XdrSCStatus _getSCStatus(String prefix, Map<String, String> map) {
    String? type = _removeComment(map[prefix + 'type']);
    if (type == null) {
      throw Exception('missing $prefix' + 'type');
    }
    if ('SST_OK' == type) {
      return XdrSCStatus(XdrSCStatusType.SST_OK);
    } else if ('SST_UNKNOWN_ERROR' == type) {
      XdrSCStatus status = XdrSCStatus(XdrSCStatusType.SST_UNKNOWN_ERROR);
      String? unknownCode = _removeComment(map[prefix + 'unknownCode']);
      if (unknownCode == null) {
        throw Exception('missing $prefix' + 'unknownCode');
      }
      if ('UNKNOWN_ERROR_GENERAL' == unknownCode) {
        status.unknownCode = XdrSCUnknownErrorCode.UNKNOWN_ERROR_GENERAL;
      } else if ('UNKNOWN_ERROR_XDR' == unknownCode) {
        status.unknownCode = XdrSCUnknownErrorCode.UNKNOWN_ERROR_XDR;
      } else {
        throw Exception('unknown $prefix' + 'unknownCode');
      }
      return status;
    } else if ('SST_HOST_VALUE_ERROR' == type) {
      XdrSCStatus status = XdrSCStatus(XdrSCStatusType.SST_HOST_VALUE_ERROR);
      String? valCode = _removeComment(map[prefix + 'valCode']);
      if (valCode == null) {
        throw Exception('missing $prefix' + 'valCode');
      }
      if ('HOST_VALUE_UNKNOWN_ERROR' == valCode) {
        status.valCode = XdrSCHostValErrorCode.HOST_VALUE_UNKNOWN_ERROR;
      } else if ('HOST_VALUE_RESERVED_TAG_VALUE' == valCode) {
        status.valCode = XdrSCHostValErrorCode.HOST_VALUE_RESERVED_TAG_VALUE;
      } else if ('HOST_VALUE_UNEXPECTED_VAL_TYPE' == valCode) {
        status.valCode = XdrSCHostValErrorCode.HOST_VALUE_UNEXPECTED_VAL_TYPE;
      } else if ('HOST_VALUE_U63_OUT_OF_RANGE' == valCode) {
        status.valCode = XdrSCHostValErrorCode.HOST_VALUE_U63_OUT_OF_RANGE;
      } else if ('HOST_VALUE_U32_OUT_OF_RANGE' == valCode) {
        status.valCode = XdrSCHostValErrorCode.HOST_VALUE_U32_OUT_OF_RANGE;
      } else if ('HOST_VALUE_STATIC_UNKNOWN' == valCode) {
        status.valCode = XdrSCHostValErrorCode.HOST_VALUE_STATIC_UNKNOWN;
      } else if ('HOST_VALUE_MISSING_OBJECT' == valCode) {
        status.valCode = XdrSCHostValErrorCode.HOST_VALUE_MISSING_OBJECT;
      } else if ('HOST_VALUE_SYMBOL_TOO_LONG' == valCode) {
        status.valCode = XdrSCHostValErrorCode.HOST_VALUE_SYMBOL_TOO_LONG;
      } else if ('HOST_VALUE_SYMBOL_BAD_CHAR' == valCode) {
        status.valCode = XdrSCHostValErrorCode.HOST_VALUE_SYMBOL_BAD_CHAR;
      } else if ('HOST_VALUE_SYMBOL_CONTAINS_NON_UTF8' == valCode) {
        status.valCode =
            XdrSCHostValErrorCode.HOST_VALUE_SYMBOL_CONTAINS_NON_UTF8;
      } else if ('HOST_VALUE_BITSET_TOO_MANY_BITS' == valCode) {
        status.valCode = XdrSCHostValErrorCode.HOST_VALUE_BITSET_TOO_MANY_BITS;
      } else if ('HOST_VALUE_STATUS_UNKNOWN' == valCode) {
        status.valCode = XdrSCHostValErrorCode.HOST_VALUE_STATUS_UNKNOWN;
      } else {
        throw Exception('unknown $prefix' + 'valCode');
      }
      return status;
    } else if ('SST_HOST_OBJECT_ERROR' == type) {
      XdrSCStatus status = XdrSCStatus(XdrSCStatusType.SST_HOST_OBJECT_ERROR);
      String? objCode = _removeComment(map[prefix + 'objCode']);
      if (objCode == null) {
        throw Exception('missing $prefix' + 'objCode');
      }
      if ('HOST_OBJECT_UNKNOWN_ERROR' == objCode) {
        status.objCode = XdrSCHostObjErrorCode.HOST_OBJECT_UNKNOWN_ERROR;
      } else if ('HOST_OBJECT_UNKNOWN_REFERENCE' == objCode) {
        status.objCode = XdrSCHostObjErrorCode.HOST_OBJECT_UNKNOWN_REFERENCE;
      } else if ('HOST_OBJECT_UNEXPECTED_TYPE' == objCode) {
        status.objCode = XdrSCHostObjErrorCode.HOST_OBJECT_UNEXPECTED_TYPE;
      } else if ('HOST_OBJECT_OBJECT_COUNT_EXCEEDS_U32_MAX' == objCode) {
        status.objCode =
            XdrSCHostObjErrorCode.HOST_OBJECT_OBJECT_COUNT_EXCEEDS_U32_MAX;
      } else if ('HOST_OBJECT_VEC_INDEX_OUT_OF_BOUND' == objCode) {
        status.objCode =
            XdrSCHostObjErrorCode.HOST_OBJECT_VEC_INDEX_OUT_OF_BOUND;
      } else if ('HOST_OBJECT_CONTRACT_HASH_WRONG_LENGTH' == objCode) {
        status.objCode =
            XdrSCHostObjErrorCode.HOST_OBJECT_CONTRACT_HASH_WRONG_LENGTH;
      } else {
        throw Exception('unknown $prefix' + 'objCode');
      }
      return status;
    } else if ('SST_HOST_FUNCTION_ERROR' == type) {
      XdrSCStatus status = XdrSCStatus(XdrSCStatusType.SST_HOST_FUNCTION_ERROR);
      String? fnCode = _removeComment(map[prefix + 'fnCode']);
      if (fnCode == null) {
        throw Exception('missing $prefix' + 'fnCode');
      }
      if ('HOST_FN_UNKNOWN_ERROR' == fnCode) {
        status.fnCode = XdrSCHostFnErrorCode.HOST_FN_UNKNOWN_ERROR;
      } else if ('HOST_FN_UNEXPECTED_HOST_FUNCTION_ACTION' == fnCode) {
        status.fnCode =
            XdrSCHostFnErrorCode.HOST_FN_UNEXPECTED_HOST_FUNCTION_ACTION;
      } else if ('HOST_FN_INPUT_ARGS_WRONG_LENGTH' == fnCode) {
        status.fnCode = XdrSCHostFnErrorCode.HOST_FN_INPUT_ARGS_WRONG_LENGTH;
      } else if ('HOST_FN_INPUT_ARGS_WRONG_TYPE' == fnCode) {
        status.fnCode = XdrSCHostFnErrorCode.HOST_FN_INPUT_ARGS_WRONG_TYPE;
      } else if ('HOST_FN_INPUT_ARGS_INVALID' == fnCode) {
        status.fnCode = XdrSCHostFnErrorCode.HOST_FN_INPUT_ARGS_INVALID;
      } else {
        throw Exception('unknown $prefix' + 'fnCode');
      }
      return status;
    } else if ('SST_HOST_STORAGE_ERROR' == type) {
      XdrSCStatus status = XdrSCStatus(XdrSCStatusType.SST_HOST_STORAGE_ERROR);
      String? storageCode = _removeComment(map[prefix + 'storageCode']);
      if (storageCode == null) {
        throw Exception('missing $prefix' + 'storageCode');
      }
      if ('HOST_STORAGE_UNKNOWN_ERROR' == storageCode) {
        status.storageCode =
            XdrSCHostStorageErrorCode.HOST_STORAGE_UNKNOWN_ERROR;
      } else if ('HOST_STORAGE_EXPECT_CONTRACT_DATA' == storageCode) {
        status.storageCode =
            XdrSCHostStorageErrorCode.HOST_STORAGE_EXPECT_CONTRACT_DATA;
      } else if ('HOST_STORAGE_READWRITE_ACCESS_TO_READONLY_ENTRY' ==
          storageCode) {
        status.storageCode = XdrSCHostStorageErrorCode
            .HOST_STORAGE_READWRITE_ACCESS_TO_READONLY_ENTRY;
      } else if ('HOST_STORAGE_ACCESS_TO_UNKNOWN_ENTRY' == storageCode) {
        status.storageCode =
            XdrSCHostStorageErrorCode.HOST_STORAGE_ACCESS_TO_UNKNOWN_ENTRY;
      } else if ('HOST_STORAGE_MISSING_KEY_IN_GET' == storageCode) {
        status.storageCode =
            XdrSCHostStorageErrorCode.HOST_STORAGE_MISSING_KEY_IN_GET;
      } else if ('HOST_STORAGE_GET_ON_DELETED_KEY' == storageCode) {
        status.storageCode =
            XdrSCHostStorageErrorCode.HOST_STORAGE_GET_ON_DELETED_KEY;
      } else {
        throw Exception('unknown $prefix' + 'storageCode');
      }
      return status;
    } else if ('SST_HOST_CONTEXT_ERROR' == type) {
      XdrSCStatus status = XdrSCStatus(XdrSCStatusType.SST_HOST_CONTEXT_ERROR);
      String? contextCode = _removeComment(map[prefix + 'contextCode']);
      if (contextCode == null) {
        throw Exception('missing $prefix' + 'contextCode');
      }
      if ('HOST_CONTEXT_UNKNOWN_ERROR' == contextCode) {
        status.contextCode =
            XdrSCHostContextErrorCode.HOST_CONTEXT_UNKNOWN_ERROR;
      } else if ('HOST_CONTEXT_NO_CONTRACT_RUNNING' == contextCode) {
        status.contextCode =
            XdrSCHostContextErrorCode.HOST_CONTEXT_NO_CONTRACT_RUNNING;
      } else {
        throw Exception('unknown $prefix' + 'contextCode');
      }
      return status;
    } else if ('SST_VM_ERROR' == type) {
      XdrSCStatus status = XdrSCStatus(XdrSCStatusType.SST_VM_ERROR);
      String? vmCode = _removeComment(map[prefix + 'vmCode']);
      if (vmCode == null) {
        throw Exception('missing $prefix' + 'vmCode');
      }
      if ('VM_UNKNOWN' == vmCode) {
        status.vmCode = XdrSCVmErrorCode.VM_UNKNOWN;
      } else if ('VM_VALIDATION' == vmCode) {
        status.vmCode = XdrSCVmErrorCode.VM_VALIDATION;
      } else if ('VM_INSTANTIATION' == vmCode) {
        status.vmCode = XdrSCVmErrorCode.VM_INSTANTIATION;
      } else if ('VM_FUNCTION' == vmCode) {
        status.vmCode = XdrSCVmErrorCode.VM_FUNCTION;
      } else if ('VM_TABLE' == vmCode) {
        status.vmCode = XdrSCVmErrorCode.VM_TABLE;
      } else if ('VM_MEMORY' == vmCode) {
        status.vmCode = XdrSCVmErrorCode.VM_MEMORY;
      } else if ('VM_GLOBAL' == vmCode) {
        status.vmCode = XdrSCVmErrorCode.VM_GLOBAL;
      } else if ('VM_VALUE' == vmCode) {
        status.vmCode = XdrSCVmErrorCode.VM_VALUE;
      } else if ('VM_TRAP_UNREACHABLE' == vmCode) {
        status.vmCode = XdrSCVmErrorCode.VM_TRAP_UNREACHABLE;
      } else if ('VM_TRAP_MEMORY_ACCESS_OUT_OF_BOUNDS' == vmCode) {
        status.vmCode = XdrSCVmErrorCode.VM_TRAP_MEMORY_ACCESS_OUT_OF_BOUNDS;
      } else if ('VM_TRAP_TABLE_ACCESS_OUT_OF_BOUNDS' == vmCode) {
        status.vmCode = XdrSCVmErrorCode.VM_TRAP_TABLE_ACCESS_OUT_OF_BOUNDS;
      } else if ('VM_TRAP_ELEM_UNINITIALIZED' == vmCode) {
        status.vmCode = XdrSCVmErrorCode.VM_TRAP_ELEM_UNINITIALIZED;
      } else if ('VM_TRAP_DIVISION_BY_ZERO' == vmCode) {
        status.vmCode = XdrSCVmErrorCode.VM_TRAP_DIVISION_BY_ZERO;
      } else if ('VM_TRAP_INTEGER_OVERFLOW' == vmCode) {
        status.vmCode = XdrSCVmErrorCode.VM_TRAP_INTEGER_OVERFLOW;
      } else if ('VM_TRAP_INVALID_CONVERSION_TO_INT' == vmCode) {
        status.vmCode = XdrSCVmErrorCode.VM_TRAP_INVALID_CONVERSION_TO_INT;
      } else if ('VM_TRAP_STACK_OVERFLOW' == vmCode) {
        status.vmCode = XdrSCVmErrorCode.VM_TRAP_STACK_OVERFLOW;
      } else if ('VM_TRAP_UNEXPECTED_SIGNATURE' == vmCode) {
        status.vmCode = XdrSCVmErrorCode.VM_TRAP_UNEXPECTED_SIGNATURE;
      } else if ('VM_TRAP_MEM_LIMIT_EXCEEDED' == vmCode) {
        status.vmCode = XdrSCVmErrorCode.VM_TRAP_MEM_LIMIT_EXCEEDED;
      } else if ('VM_TRAP_CPU_LIMIT_EXCEEDED' == vmCode) {
        status.vmCode = XdrSCVmErrorCode.VM_TRAP_CPU_LIMIT_EXCEEDED;
      } else {
        throw Exception('unknown $prefix' + 'vmCode');
      }
      return status;
    } else {
      throw Exception('unknown $prefix' + 'type');
    }
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
    List<Claimant> claimants = List<Claimant>.empty(growable: true);
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
        return XdrClaimPredicate(
            XdrClaimPredicateType.CLAIM_PREDICATE_UNCONDITIONAL);
      case 'CLAIM_PREDICATE_AND':
        List<XdrClaimPredicate> andPredicates =
            List<XdrClaimPredicate>.empty(growable: true);
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
        XdrClaimPredicate result =
            XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_AND);
        result.andPredicates = andPredicates;
        return result;
      case 'CLAIM_PREDICATE_OR':
        List<XdrClaimPredicate> orPredicates =
            List<XdrClaimPredicate>.empty(growable: true);
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
        XdrClaimPredicate result =
            XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_OR);
        result.orPredicates = orPredicates;
        return result;
      case 'CLAIM_PREDICATE_NOT':
        XdrClaimPredicate result =
            XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_NOT);
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
        XdrClaimPredicate result = XdrClaimPredicate(
            XdrClaimPredicateType.CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME);
        result.absBefore = new XdrInt64(time);
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
        XdrClaimPredicate result = XdrClaimPredicate(
            XdrClaimPredicateType.CLAIM_PREDICATE_BEFORE_RELATIVE_TIME);
        result.relBefore = new XdrInt64(time);
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
      MuxedAccount? smux = MuxedAccount.fromAccountId(sourceAccountId);
      if (smux == null) {
        throw Exception('invalid $opPrefix' + 'sourceAccountId');
      }
      builder.setMuxedSourceAccount(smux);
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
    MuxedAccount? ddes = MuxedAccount.fromAccountId(destination);
    if (ddes == null) {
      throw Exception('invalid $opPrefix' + 'destination');
    }
    PaymentOperationBuilder builder =
        PaymentOperationBuilder.forMuxedDestinationAccount(ddes, asset, amount);
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

    List<Asset> path = List<Asset>.empty(growable: true);
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
          if (nextAsset == null) {
            throw Exception('invalid $opPrefix' + 'path[$i]');
          }
          path.add(nextAsset);
        } catch (e) {
          throw Exception('invalid $opPrefix' + 'path[$i]');
        }
      }
    }
    MuxedAccount? muxDest = MuxedAccount.fromAccountId(destination);
    if (muxDest == null) {
      throw Exception('invalid $opPrefix' + 'destination');
    }
    PathPaymentStrictReceiveOperationBuilder builder =
        PathPaymentStrictReceiveOperationBuilder.forMuxedDestinationAccount(
            sendAsset, sendMax, muxDest, destAsset, destAmount);
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

    List<Asset> path = List<Asset>.empty(growable: true);
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
          if (nextAsset == null) {
            throw Exception('invalid $opPrefix' + 'path[$i]');
          }
          path.add(nextAsset);
        } catch (e) {
          throw Exception('invalid $opPrefix' + 'path[$i]');
        }
      }
    }
    MuxedAccount? muxDest = MuxedAccount.fromAccountId(destination);
    if (muxDest == null) {
      throw Exception('invalid $opPrefix' + 'destination');
    }
    PathPaymentStrictSendOperationBuilder builder =
        PathPaymentStrictSendOperationBuilder.forMuxedDestinationAccount(
            sendAsset, sendAmount, muxDest, destAsset, destMin);
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

    Decimal dec =
        (Decimal.parse(n.toString()) / Decimal.parse(d.toString())).toDecimal();

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

    Decimal dec =
        (Decimal.parse(n.toString()) / Decimal.parse(d.toString())).toDecimal();

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
    Decimal dec =
        (Decimal.parse(n.toString()) / Decimal.parse(d.toString())).toDecimal();

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
          signer = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519);
          signer.ed25519 = XdrUint256(StrKey.decodeStellarAccountId(key));
        } else if (key.startsWith('T')) {
          signer = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_PRE_AUTH_TX);
          signer.preAuthTx = XdrUint256(StrKey.decodePreAuthTx(key));
        } else if (key.startsWith('X')) {
          signer = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_HASH_X);
          signer.hashX = XdrUint256(StrKey.decodeSha256Hash(key));
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
        ChangeTrustOperationBuilder(asset, limit!);
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
            MuxedAccount.fromAccountId(destination)!);
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
      MuxedAccount? smux = MuxedAccount.fromAccountId(sourceAccountId);
      if (smux == null) {
        throw Exception('invalid $opPrefix' + 'sourceAccountId');
      }
      builder.setMuxedSourceAccount(smux);
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
              StrKey.encodeStellarAccountId(key!.ed25519!.uint256), lines);
        } else if (key?.preAuthTx != null) {
          _addLine('${precondPrefix}extraSigners[${index.toString()}]',
              StrKey.encodePreAuthTx(key!.preAuthTx!.uint256), lines);
        } else if (key?.hashX != null) {
          _addLine('${precondPrefix}extraSigners[${index.toString()}]',
              StrKey.encodeSha256Hash(key!.hashX!.uint256), lines);
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
      for (Asset? asset in operation.path) {
        _addLine('$prefix.path[$assetIndex]', _encodeAsset(asset!), lines);
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
      for (Asset? asset in operation.path) {
        _addLine('$prefix.path[$assetIndex]', _encodeAsset(asset!), lines);
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
              StrKey.encodeStellarAccountId(operation.signer!.ed25519!.uint256),
              lines);
        } else if (operation.signer?.preAuthTx != null) {
          _addLine(
              '$prefix.signer.key',
              StrKey.encodePreAuthTx(operation.signer!.preAuthTx!.uint256),
              lines);
        } else if (operation.signer?.hashX != null) {
          _addLine('$prefix.signer.key',
              StrKey.encodeSha256Hash(operation.signer!.hashX!.uint256), lines);
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
        _addLine('$prefix.dataValue', Util.bytesToHex(operation.value!), lines);
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
    } else if (operation is CreateClaimableBalanceOperation) {
      _addLine('$prefix.asset', _encodeAsset(operation.asset), lines);
      _addLine('$prefix.amount', _toAmount(operation.amount), lines);
      List<Claimant> claimants = operation.claimants;
      int claimantsLen = claimants.length;
      _addLine('$prefix.claimants.len', claimantsLen.toString(), lines);
      for (int i = 0; i < claimantsLen; i++) {
        Claimant? claimant = claimants[i];
        _addLine('$prefix.claimants[$i].type', "CLAIMANT_TYPE_V0", lines);
        _addLine('$prefix.claimants[$i].v0.destination', claimant.destination,
            lines);
        String px = '$prefix.claimants[$i].v0.predicate';
        _addClaimPredicate(claimant.predicate, lines, px);
      }
    } else if (operation is ClaimClaimableBalanceOperation) {
      _addLine('$prefix.balanceID.type', "CLAIMABLE_BALANCE_ID_TYPE_V0", lines);
      _addLine('$prefix.balanceID.v0', operation.balanceId, lines);
    } else if (operation is BeginSponsoringFutureReservesOperation) {
      _addLine('$prefix.sponsoredID', operation.sponsoredId, lines);
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
              _encodeAsset(Asset.fromXdr(ledgerKey.trustLine!.asset)), lines);
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
              jsonEncoder.convert(ledgerKey.data!.dataName.string64), lines);
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
          _addLine('$prefix.signer.signerKey',
              StrKey.encodeStellarAccountId(signerKey.ed25519!.uint256), lines);
        } else if (signerKey.preAuthTx != null) {
          _addLine('$prefix.signer.signerKey',
              StrKey.encodePreAuthTx(signerKey.preAuthTx!.uint256), lines);
        } else if (signerKey.hashX != null) {
          _addLine('$prefix.signer.signerKey',
              StrKey.encodeSha256Hash(signerKey.hashX!.uint256), lines);
        }
      }
    } else if (operation is ClawbackOperation) {
      _addLine('$prefix.asset', _encodeAsset(operation.asset), lines);
      _addLine('$prefix.from', operation.from.accountId, lines);
      _addLine('$prefix.amount', _toAmount(operation.amount), lines);
    } else if (operation is ClawbackClaimableBalanceOperation) {
      _addLine('$prefix.balanceID.type', 'CLAIMABLE_BALANCE_ID_TYPE_V0', lines);
      _addLine('$prefix.balanceID.v0', operation.balanceId, lines);
    } else if (operation is SetTrustLineFlagsOperation) {
      _addLine('$prefix.trustor', operation.trustorId, lines);
      _addLine('$prefix.asset', _encodeAsset(operation.asset), lines);
      _addLine('$prefix.clearFlags', operation.clearFlags.toString(), lines);
      _addLine('$prefix.setFlags', operation.setFlags.toString(), lines);
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
    } else if (operation is InvokeHostFunctionOperation) {
      String fnPrefix = prefix + ".function";
      _addLine('$fnPrefix.type', _txRepInvokeHostFnType(operation.functionType),
          lines);
      if (operation is InstallContractCodeOp) {
        _addLine('$fnPrefix.installContractCodeArgs.code',
            Util.bytesToHex(operation.contractBytes), lines);
      } else if (operation is CreateContractOp) {
        String cCArgs = fnPrefix + ".createContractArgs";
        _addLine('$cCArgs.source.type', 'SCCONTRACT_CODE_WASM_REF', lines);
        _addLine('$cCArgs.source.wasm_id', operation.wasmId, lines);
        _addLine('$cCArgs.contractID.type', 'CONTRACT_ID_FROM_SOURCE_ACCOUNT',
            lines);
        _addLine('$cCArgs.contractID.salt',
            Util.bytesToHex(operation.salt.uint256), lines);
      } else if (operation is DeploySACWithSourceAccountOp) {
        String cCArgs = fnPrefix + ".createContractArgs";
        _addLine('$cCArgs.source.type', 'SCCONTRACT_CODE_TOKEN', lines);
        _addLine('$cCArgs.contractID.type', 'CONTRACT_ID_FROM_SOURCE_ACCOUNT',
            lines);
        _addLine('$cCArgs.contractID.salt',
            Util.bytesToHex(operation.salt.uint256), lines);
      } else if (operation is DeploySACWithAssetOp) {
        String cCArgs = fnPrefix + ".createContractArgs";
        _addLine('$cCArgs.source.type', 'SCCONTRACT_CODE_TOKEN', lines);
        _addLine('$cCArgs.contractID.type', 'CONTRACT_ID_FROM_ASSET', lines);
        _addLine(
            '$cCArgs.contractID.asset', _encodeAsset(operation.asset), lines);
      } else if (operation is InvokeContractOp) {
        String iArgsPrefix = fnPrefix + ".invokeArgs";
        int argsLen =
            operation.arguments == null ? 0 : operation.arguments!.length;
        List<XdrSCVal> args = operation.arguments!;
        _addLine('$iArgsPrefix.len', (args.length + 2).toString(), lines);
        _addLine('$iArgsPrefix[0].type', 'SCV_OBJECT', lines);
        _addLine('$iArgsPrefix[0].obj.type', 'SCO_BYTES', lines);
        _addLine('$iArgsPrefix[0].obj.bin', operation.contractID, lines);
        _addLine('$iArgsPrefix[1].type', 'SCV_SYMBOL', lines);
        _addLine('$iArgsPrefix[1].sym', operation.functionName, lines);
        for (int i = 0; i < argsLen; i++) {
          _addSCVal(operation.arguments![i], lines,
              iArgsPrefix + "[" + (i + 2).toString() + "]");
        }
      }
      XdrLedgerFootprint footprint = operation.getXdrFootprint();
      List<XdrLedgerKey> readOnly = footprint.readOnly;
      List<XdrLedgerKey> readWrite = footprint.readWrite;
      String footprintPrefix = prefix + '.footprint';
      _addLine(
          '$footprintPrefix.readOnly.len', readOnly.length.toString(), lines);
      for (int i = 0; i < readOnly.length; i++) {
        _addLedgerKey(readOnly[i], lines, footprintPrefix + '.readOnly[$i]');
      }
      _addLine(
          '$footprintPrefix.readWrite.len', readWrite.length.toString(), lines);
      for (int i = 0; i < readWrite.length; i++) {
        _addLedgerKey(readWrite[i], lines, footprintPrefix + '.readWrite[$i]');
      }
      List<XdrContractAuth> contractAuth = operation.contractAuth;
      _addLine('$prefix.auth.len', contractAuth.length.toString(), lines);
      for (int i = 0; i < contractAuth.length; i++) {
        _addContractAuth(contractAuth[i], lines, prefix + '.auth[$i]');
      }
    }
  }

  static _addContractAuth(
      XdrContractAuth auth, List<String> lines, String prefix) {
    if (auth.addressWithNonce != null) {
      _addLine('$prefix.addressWithNonce._present', 'true', lines);
      _addAddressWithNonce(
          auth.addressWithNonce!, lines, '$prefix.addressWithNonce');
    } else {
      _addLine('$prefix.addressWithNonce._present', 'false', lines);
    }
    _addAuthorizedInvocation(
        auth.rootInvocation, lines, '$prefix.rootInvocation');
    List<XdrSCVal> argsArr = List<XdrSCVal>.empty(growable: true);
    if (auth.signatureArgs.length > 0) {
      XdrSCVal innerVal = auth.signatureArgs[0];
      if (innerVal.obj != null && innerVal.obj!.vec != null) {
        // PATCH: See: https://discord.com/channels/897514728459468821/1076723574884282398/1078095366890729595
        argsArr = innerVal.obj!.vec!;
      } else {
        argsArr = auth.signatureArgs;
      }
    }
    _addLine('$prefix.signatureArgs.len', argsArr.length.toString(), lines);
    for (int i = 0; i < argsArr.length; i++) {
      _addSCVal(argsArr[i], lines, prefix + '.signatureArgs[$i]');
    }
  }

  static _addAddressWithNonce(
      XdrAddressWithNonce addr, List<String> lines, String prefix) {
    _addSCAddress(addr.address, lines, prefix + '.address');
    _addLine('$prefix.nonce', addr.nonce.uint64.toString(), lines);
  }

  static _addAuthorizedInvocation(XdrAuthorizedInvocation authorizedInvocation,
      List<String> lines, String prefix) {
    _addLine('$prefix.contractID',
        Util.bytesToHex(authorizedInvocation.contractID.hash), lines);
    _addLine('$prefix.functionName', authorizedInvocation.functionName, lines);
    List<XdrSCVal> args = authorizedInvocation.args;
    _addLine('$prefix.args.len', args.length.toString(), lines);
    for (int i = 0; i < args.length; i++) {
      _addSCVal(args[i], lines, prefix + '.args[$i]');
    }
    List<XdrAuthorizedInvocation> subInvocations =
        authorizedInvocation.subInvocations;
    _addLine(
        '$prefix.subInvocations.len', subInvocations.length.toString(), lines);
    for (int i = 0; i < subInvocations.length; i++) {
      _addAuthorizedInvocation(
          subInvocations[i], lines, prefix + '.subInvocations[$i]');
    }
  }

  static _addLedgerKey(XdrLedgerKey key, List<String> lines, String prefix) {
    switch (key.discriminant) {
      case XdrLedgerEntryType.ACCOUNT:
        _addLine('$prefix.type', 'ACCOUNT', lines);
        KeyPair kp = KeyPair.fromXdrPublicKey(key.account!.accountID.accountID);
        _addLine('$prefix.account.accountID', kp.accountId, lines);
        break;
      case XdrLedgerEntryType.TRUSTLINE:
        _addLine('$prefix.type', 'TRUSTLINE', lines);
        KeyPair kp =
            KeyPair.fromXdrPublicKey(key.trustLine!.accountID.accountID);
        _addLine('$prefix.trustLine.accountID', kp.accountId, lines);
        _addLine('$prefix.trustLine.asset',
            _encodeAsset(Asset.fromXdr(key.trustLine!.asset)), lines);
        break;
      case XdrLedgerEntryType.CONTRACT_DATA:
        _addLine('$prefix.type', 'CONTRACT_DATA', lines);
        _addLine('$prefix.contractData.contractID',
            Util.bytesToHex(key.contractID!.hash), lines);
        _addSCVal(key.contractDataKey!, lines, prefix + '.contractData.key');
        break;
      case XdrLedgerEntryType.CONTRACT_CODE:
        _addLine('$prefix.type', 'CONTRACT_CODE', lines);
        _addLine('$prefix.contractCode.hash',
            Util.bytesToHex(key.contractCodeHash!.hash), lines);
        break;
    }
  }

  static _addSCVal(XdrSCVal value, List<String> lines, String prefix) {
    switch (value.discriminant) {
      case XdrSCValType.SCV_U63:
        _addLine('$prefix.type', 'SCV_U63', lines);
        _addLine('$prefix.u63', value.u63!.int64.toString(), lines);
        break;
      case XdrSCValType.SCV_U32:
        _addLine('$prefix.type', 'SCV_U32', lines);
        _addLine('$prefix.u32', value.u32!.uint32.toString(), lines);
        break;
      case XdrSCValType.SCV_I32:
        _addLine('$prefix.type', 'SCV_I32', lines);
        _addLine('$prefix.i32', value.i32!.int32.toString(), lines);
        break;
      case XdrSCValType.SCV_STATIC:
        _addLine('$prefix.type', 'SCV_STATIC', lines);
        _addSCStaticVal(value.ic!, lines, prefix);
        break;
      case XdrSCValType.SCV_OBJECT:
        _addLine('$prefix.type', 'SCV_OBJECT', lines);
        if (value.obj == null) {
          _addLine('$prefix.obj._present', 'false', lines);
        } else {
          _addLine('$prefix.obj._present', 'true', lines);
          _addSCObject(value.obj!, lines, prefix + ".obj");
        }
        break;
      case XdrSCValType.SCV_SYMBOL:
        _addLine('$prefix.type', 'SCV_SYMBOL', lines);
        _addLine('$prefix.sym', value.sym!, lines);
        break;
      case XdrSCValType.SCV_BITSET:
        _addLine('$prefix.type', 'SCV_BITSET', lines);
        _addLine('$prefix.bits', value.bits!.uint64.toString(), lines);
        break;
      case XdrSCValType.SCV_STATUS:
        _addLine('$prefix.type', 'SCV_STATUS', lines);
        XdrSCStatus status = value.status!;
        _addSCStatus(status, lines, prefix + '.status');
        break;
    }
  }

  static _addSCStatus(XdrSCStatus status, List<String> lines, String prefix) {
    switch (status.discriminant) {
      case XdrSCStatusType.SST_OK:
        _addLine('$prefix.type', 'SST_OK', lines);
        break;
      case XdrSCStatusType.SST_UNKNOWN_ERROR:
        _addLine('$prefix.type', 'SST_UNKNOWN_ERROR', lines);
        if (status.unknownCode! ==
            XdrSCUnknownErrorCode.UNKNOWN_ERROR_GENERAL) {
          _addLine('$prefix.unknownCode', 'UNKNOWN_ERROR_GENERAL', lines);
        } else if (status.unknownCode! ==
            XdrSCUnknownErrorCode.UNKNOWN_ERROR_XDR) {
          _addLine('$prefix.unknownCode', 'UNKNOWN_ERROR_XDR', lines);
        }
        break;
      case XdrSCStatusType.SST_HOST_VALUE_ERROR:
        _addLine('$prefix.type', 'SST_HOST_VALUE_ERROR', lines);
        XdrSCHostValErrorCode valCode = status.valCode!;
        switch (valCode) {
          case XdrSCHostValErrorCode.HOST_VALUE_UNKNOWN_ERROR:
            _addLine('$prefix.valCode', 'HOST_VALUE_UNKNOWN_ERROR', lines);
            break;
          case XdrSCHostValErrorCode.HOST_VALUE_RESERVED_TAG_VALUE:
            _addLine('$prefix.valCode', 'HOST_VALUE_RESERVED_TAG_VALUE', lines);
            break;
          case XdrSCHostValErrorCode.HOST_VALUE_UNEXPECTED_VAL_TYPE:
            _addLine(
                '$prefix.valCode', 'HOST_VALUE_UNEXPECTED_VAL_TYPE', lines);
            break;
          case XdrSCHostValErrorCode.HOST_VALUE_U63_OUT_OF_RANGE:
            _addLine('$prefix.valCode', 'HOST_VALUE_U63_OUT_OF_RANGE', lines);
            break;
          case XdrSCHostValErrorCode.HOST_VALUE_U32_OUT_OF_RANGE:
            _addLine('$prefix.valCode', 'HOST_VALUE_U32_OUT_OF_RANGE', lines);
            break;
          case XdrSCHostValErrorCode.HOST_VALUE_STATIC_UNKNOWN:
            _addLine('$prefix.valCode', 'HOST_VALUE_STATIC_UNKNOWN', lines);
            break;
          case XdrSCHostValErrorCode.HOST_VALUE_MISSING_OBJECT:
            _addLine('$prefix.valCode', 'HOST_VALUE_MISSING_OBJECT', lines);
            break;
          case XdrSCHostValErrorCode.HOST_VALUE_SYMBOL_TOO_LONG:
            _addLine('$prefix.valCode', 'HOST_VALUE_SYMBOL_TOO_LONG', lines);
            break;
          case XdrSCHostValErrorCode.HOST_VALUE_SYMBOL_BAD_CHAR:
            _addLine('$prefix.valCode', 'HOST_VALUE_SYMBOL_BAD_CHAR', lines);
            break;
          case XdrSCHostValErrorCode.HOST_VALUE_SYMBOL_CONTAINS_NON_UTF8:
            _addLine('$prefix.valCode', 'HOST_VALUE_SYMBOL_CONTAINS_NON_UTF8',
                lines);
            break;
          case XdrSCHostValErrorCode.HOST_VALUE_BITSET_TOO_MANY_BITS:
            _addLine(
                '$prefix.valCode', 'HOST_VALUE_BITSET_TOO_MANY_BITS', lines);
            break;
          case XdrSCHostValErrorCode.HOST_VALUE_STATUS_UNKNOWN:
            _addLine('$prefix.valCode', 'HOST_VALUE_STATUS_UNKNOWN', lines);
            break;
        }
        break;
      case XdrSCStatusType.SST_HOST_OBJECT_ERROR:
        _addLine('$prefix.type', 'SST_HOST_OBJECT_ERROR', lines);
        XdrSCHostObjErrorCode objCode = status.objCode!;
        switch (objCode) {
          case XdrSCHostObjErrorCode.HOST_OBJECT_UNKNOWN_ERROR:
            _addLine('$prefix.objCode', 'HOST_OBJECT_UNKNOWN_ERROR', lines);
            break;
          case XdrSCHostObjErrorCode.HOST_OBJECT_UNKNOWN_REFERENCE:
            _addLine('$prefix.objCode', 'HOST_OBJECT_UNKNOWN_REFERENCE', lines);
            break;
          case XdrSCHostObjErrorCode.HOST_OBJECT_UNEXPECTED_TYPE:
            _addLine('$prefix.objCode', 'HOST_OBJECT_UNEXPECTED_TYPE', lines);
            break;
          case XdrSCHostObjErrorCode.HOST_OBJECT_OBJECT_COUNT_EXCEEDS_U32_MAX:
            _addLine('$prefix.objCode',
                'HOST_OBJECT_OBJECT_COUNT_EXCEEDS_U32_MAX', lines);
            break;
          case XdrSCHostObjErrorCode.HOST_OBJECT_OBJECT_NOT_EXIST:
            _addLine('$prefix.objCode', 'HOST_OBJECT_OBJECT_NOT_EXIST', lines);
            break;
          case XdrSCHostObjErrorCode.HOST_OBJECT_VEC_INDEX_OUT_OF_BOUND:
            _addLine(
                '$prefix.objCode', 'HOST_OBJECT_VEC_INDEX_OUT_OF_BOUND', lines);
            break;
          case XdrSCHostObjErrorCode.HOST_OBJECT_CONTRACT_HASH_WRONG_LENGTH:
            _addLine('$prefix.objCode',
                'HOST_OBJECT_CONTRACT_HASH_WRONG_LENGTH', lines);
            break;
        }
        break;
      case XdrSCStatusType.SST_HOST_FUNCTION_ERROR:
        _addLine('$prefix.type', 'SST_HOST_FUNCTION_ERROR', lines);
        XdrSCHostFnErrorCode fnCode = status.fnCode!;
        switch (fnCode) {
          case XdrSCHostFnErrorCode.HOST_FN_UNKNOWN_ERROR:
            _addLine('$prefix.fnCode', 'HOST_FN_UNKNOWN_ERROR', lines);
            break;
          case XdrSCHostFnErrorCode.HOST_FN_UNEXPECTED_HOST_FUNCTION_ACTION:
            _addLine('$prefix.fnCode',
                'HOST_FN_UNEXPECTED_HOST_FUNCTION_ACTION', lines);
            break;
          case XdrSCHostFnErrorCode.HOST_FN_INPUT_ARGS_WRONG_LENGTH:
            _addLine(
                '$prefix.fnCode', 'HOST_FN_INPUT_ARGS_WRONG_LENGTH', lines);
            break;
          case XdrSCHostFnErrorCode.HOST_FN_INPUT_ARGS_WRONG_TYPE:
            _addLine('$prefix.fnCode', 'HOST_FN_INPUT_ARGS_WRONG_TYPE', lines);
            break;
          case XdrSCHostFnErrorCode.HOST_FN_INPUT_ARGS_INVALID:
            _addLine('$prefix.fnCode', 'HOST_FN_INPUT_ARGS_INVALID', lines);
            break;
        }
        break;
      case XdrSCStatusType.SST_HOST_STORAGE_ERROR:
        _addLine('$prefix.type', 'SST_HOST_STORAGE_ERROR', lines);
        XdrSCHostStorageErrorCode storageCode = status.storageCode!;
        switch (storageCode) {
          case XdrSCHostStorageErrorCode.HOST_STORAGE_UNKNOWN_ERROR:
            _addLine(
                '$prefix.storageCode', 'HOST_STORAGE_UNKNOWN_ERROR', lines);
            break;
          case XdrSCHostStorageErrorCode.HOST_STORAGE_EXPECT_CONTRACT_DATA:
            _addLine('$prefix.storageCode', 'HOST_STORAGE_EXPECT_CONTRACT_DATA',
                lines);
            break;
          case XdrSCHostStorageErrorCode
              .HOST_STORAGE_READWRITE_ACCESS_TO_READONLY_ENTRY:
            _addLine('$prefix.storageCode',
                'HOST_STORAGE_READWRITE_ACCESS_TO_READONLY_ENTRY', lines);
            break;
          case XdrSCHostStorageErrorCode.HOST_STORAGE_ACCESS_TO_UNKNOWN_ENTRY:
            _addLine('$prefix.storageCode',
                'HOST_STORAGE_ACCESS_TO_UNKNOWN_ENTRY', lines);
            break;
          case XdrSCHostStorageErrorCode.HOST_STORAGE_MISSING_KEY_IN_GET:
            _addLine('$prefix.storageCode', 'HOST_STORAGE_MISSING_KEY_IN_GET',
                lines);
            break;
          case XdrSCHostStorageErrorCode.HOST_STORAGE_GET_ON_DELETED_KEY:
            _addLine('$prefix.storageCode', 'HOST_STORAGE_GET_ON_DELETED_KEY',
                lines);
            break;
        }
        break;
      case XdrSCStatusType.SST_HOST_CONTEXT_ERROR:
        _addLine('$prefix.type', 'SST_HOST_CONTEXT_ERROR', lines);
        XdrSCHostContextErrorCode contextCode = status.contextCode!;
        switch (contextCode) {
          case XdrSCHostContextErrorCode.HOST_CONTEXT_UNKNOWN_ERROR:
            _addLine(
                '$prefix.contextCode', 'HOST_CONTEXT_UNKNOWN_ERROR', lines);
            break;
          case XdrSCHostContextErrorCode.HOST_CONTEXT_NO_CONTRACT_RUNNING:
            _addLine('$prefix.contextCode', 'HOST_CONTEXT_NO_CONTRACT_RUNNING',
                lines);
            break;
        }
        break;
      case XdrSCStatusType.SST_VM_ERROR:
        _addLine('$prefix.type', 'SST_VM_ERROR', lines);
        XdrSCVmErrorCode vmCode = status.vmCode!;
        switch (vmCode) {
          case XdrSCVmErrorCode.VM_UNKNOWN:
            _addLine('$prefix.vmCode', 'VM_UNKNOWN', lines);
            break;
          case XdrSCVmErrorCode.VM_VALIDATION:
            _addLine('$prefix.vmCode', 'VM_VALIDATION', lines);
            break;
          case XdrSCVmErrorCode.VM_INSTANTIATION:
            _addLine('$prefix.vmCode', 'VM_INSTANTIATION', lines);
            break;
          case XdrSCVmErrorCode.VM_FUNCTION:
            _addLine('$prefix.vmCode', 'VM_FUNCTION', lines);
            break;
          case XdrSCVmErrorCode.VM_TABLE:
            _addLine('$prefix.vmCode', 'VM_TABLE', lines);
            break;
          case XdrSCVmErrorCode.VM_MEMORY:
            _addLine('$prefix.vmCode', 'VM_MEMORY', lines);
            break;
          case XdrSCVmErrorCode.VM_GLOBAL:
            _addLine('$prefix.vmCode', 'VM_GLOBAL', lines);
            break;
          case XdrSCVmErrorCode.VM_VALUE:
            _addLine('$prefix.vmCode', 'VM_VALUE', lines);
            break;
          case XdrSCVmErrorCode.VM_TRAP_UNREACHABLE:
            _addLine('$prefix.vmCode', 'VM_TRAP_UNREACHABLE', lines);
            break;
          case XdrSCVmErrorCode.VM_TRAP_MEMORY_ACCESS_OUT_OF_BOUNDS:
            _addLine(
                '$prefix.vmCode', 'VM_TRAP_MEMORY_ACCESS_OUT_OF_BOUNDS', lines);
            break;
          case XdrSCVmErrorCode.VM_TRAP_TABLE_ACCESS_OUT_OF_BOUNDS:
            _addLine(
                '$prefix.vmCode', 'VM_TRAP_TABLE_ACCESS_OUT_OF_BOUNDS', lines);
            break;
          case XdrSCVmErrorCode.VM_TRAP_ELEM_UNINITIALIZED:
            _addLine('$prefix.vmCode', 'VM_TRAP_ELEM_UNINITIALIZED', lines);
            break;
          case XdrSCVmErrorCode.VM_TRAP_DIVISION_BY_ZERO:
            _addLine('$prefix.vmCode', 'VM_TRAP_DIVISION_BY_ZERO', lines);
            break;
          case XdrSCVmErrorCode.VM_TRAP_INTEGER_OVERFLOW:
            _addLine('$prefix.vmCode', 'VM_TRAP_INTEGER_OVERFLOW', lines);
            break;
          case XdrSCVmErrorCode.VM_TRAP_INVALID_CONVERSION_TO_INT:
            _addLine(
                '$prefix.vmCode', 'VM_TRAP_INVALID_CONVERSION_TO_INT', lines);
            break;
          case XdrSCVmErrorCode.VM_TRAP_STACK_OVERFLOW:
            _addLine('$prefix.vmCode', 'VM_TRAP_STACK_OVERFLOW', lines);
            break;
          case XdrSCVmErrorCode.VM_TRAP_UNEXPECTED_SIGNATURE:
            _addLine('$prefix.vmCode', 'VM_TRAP_UNEXPECTED_SIGNATURE', lines);
            break;
          case XdrSCVmErrorCode.VM_TRAP_MEM_LIMIT_EXCEEDED:
            _addLine('$prefix.vmCode', 'VM_TRAP_MEM_LIMIT_EXCEEDED', lines);
            break;
          case XdrSCVmErrorCode.VM_TRAP_CPU_LIMIT_EXCEEDED:
            _addLine('$prefix.vmCode', 'VM_TRAP_CPU_LIMIT_EXCEEDED', lines);
            break;
        }
        break;
      case XdrSCStatusType.SST_CONTRACT_ERROR:
        _addLine('$prefix.type', 'SST_CONTRACT_ERROR', lines);
        _addLine('$prefix.contractCode', status.contractCode!.uint32.toString(),
            lines);
        break;
      case XdrSCStatusType.SST_HOST_AUTH_ERROR:
        _addLine('$prefix.type', 'SST_HOST_AUTH_ERROR', lines);
        XdrSCHostAuthErrorCode authCode = status.authCode!;
        switch (authCode) {
          case XdrSCHostAuthErrorCode.HOST_AUTH_UNKNOWN_ERROR:
            _addLine('$prefix.authCode', 'HOST_AUTH_UNKNOWN_ERROR', lines);
            break;
          case XdrSCHostAuthErrorCode.HOST_AUTH_NONCE_ERROR:
            _addLine('$prefix.authCode', 'HOST_AUTH_NONCE_ERROR', lines);
            break;
          case XdrSCHostAuthErrorCode.HOST_AUTH_DUPLICATE_AUTHORIZATION:
            _addLine(
                '$prefix.authCode', 'HOST_AUTH_DUPLICATE_AUTHORIZATION', lines);
            break;
          case XdrSCHostAuthErrorCode.HOST_AUTH_NOT_AUTHORIZED:
            _addLine('$prefix.authCode', 'HOST_AUTH_NOT_AUTHORIZED', lines);
            break;
        }
        break;
    }
  }

  static _addSCObject(XdrSCObject obj, List<String> lines, String prefix) {
    switch (obj.discriminant) {
      case XdrSCObjectType.SCO_VEC:
        _addLine('$prefix.type', 'SCO_VEC', lines);
        _addLine('$prefix.vec.len', obj.vec!.length.toString(), lines);
        for (int i = 0; i < obj.vec!.length; i++) {
          _addSCVal(obj.vec![i], lines, prefix + ".vec[$i]");
        }
        break;
      case XdrSCObjectType.SCO_MAP:
        _addLine('$prefix.type', 'SCO_MAP', lines);
        _addLine('$prefix.map.len', obj.map!.length.toString(), lines);
        for (int i = 0; i < obj.map!.length; i++) {
          _addSCVal(obj.map![i].key, lines, prefix + ".map[$i].key");
          _addSCVal(obj.map![i].val, lines, prefix + ".map[$i].val");
        }
        break;
      case XdrSCObjectType.SCO_U64:
        _addLine('$prefix.type', 'SCO_U64', lines);
        _addLine('$prefix.u64', obj.u64!.uint64.toString(), lines);
        break;
      case XdrSCObjectType.SCO_I64:
        _addLine('$prefix.type', 'SCO_I64', lines);
        _addLine('$prefix.i64', obj.i64!.int64.toString(), lines);
        break;
      case XdrSCObjectType.SCO_U128:
        _addLine('$prefix.type', 'SCO_U128', lines);
        _addLine('$prefix.u128.lo', obj.u128!.lo.uint64.toString(), lines);
        _addLine('$prefix.u128.hi', obj.u128!.hi.uint64.toString(), lines);
        break;
      case XdrSCObjectType.SCO_I128:
        _addLine('$prefix.type', 'SCO_I128', lines);
        _addLine('$prefix.i128.lo', obj.i128!.lo.uint64.toString(), lines);
        _addLine('$prefix.i128.hi', obj.i128!.hi.uint64.toString(), lines);
        break;
      case XdrSCObjectType.SCO_BYTES:
        _addLine('$prefix.type', 'SCO_BYTES', lines);
        _addLine('$prefix.bin', Util.bytesToHex(obj.bin!.dataValue), lines);
        break;
      case XdrSCObjectType.SCO_CONTRACT_CODE:
        _addLine('$prefix.type', 'SCO_CONTRACT_CODE', lines);
        String cCPrefix = prefix + '.contractCode';
        XdrSCContractCode cCode = obj.contractCode!;
        if (cCode.discriminant ==
            XdrSCContractCodeType.SCCONTRACT_CODE_WASM_REF) {
          _addLine('$cCPrefix.type', 'SCCONTRACT_CODE_WASM_REF', lines);
          _addLine(
              '$cCPrefix.wasm_id', Util.bytesToHex(cCode.wasmId!.hash), lines);
        } else if (cCode.discriminant ==
            XdrSCContractCodeType.SCCONTRACT_CODE_TOKEN) {
          _addLine('$cCPrefix.type', 'SCCONTRACT_CODE_TOKEN', lines);
        }
        break;
      case XdrSCObjectType.SCO_ADDRESS:
        _addLine('$prefix.type', 'SCO_ADDRESS', lines);
        _addSCAddress(obj.address!, lines, '$prefix.address');
        break;
      case XdrSCObjectType.SCO_NONCE_KEY:
        _addLine('$prefix.type', 'SCO_NONCE_KEY', lines);
        _addSCAddress(obj.nonceKey!, lines, '$prefix.nonceAddress');
        break;
    }
  }

  static _addSCAddress(
      XdrSCAddress address, List<String> lines, String prefix) {
    switch (address.discriminant) {
      case XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT:
        _addLine('$prefix.type', 'SC_ADDRESS_TYPE_ACCOUNT', lines);
        _addLine(
            '$prefix.accountId',
            KeyPair.fromXdrPublicKey(address.accountId!.accountID).accountId,
            lines);
        break;
      case XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT:
        _addLine('$prefix.type', 'SC_ADDRESS_TYPE_CONTRACT', lines);
        _addLine('$prefix.contractId',
            Util.bytesToHex(address.contractId!.hash), lines);
        break;
    }
  }

  static _addSCStaticVal(XdrSCStatic value, List<String> lines, String prefix) {
    switch (value) {
      case XdrSCStatic.SCS_FALSE:
        _addLine('$prefix.ic', 'SCS_FALSE', lines);
        break;
      case XdrSCStatic.SCS_LEDGER_KEY_CONTRACT_CODE:
        _addLine('$prefix.ic', 'SCS_LEDGER_KEY_CONTRACT_CODE', lines);
        break;
      case XdrSCStatic.SCS_TRUE:
        _addLine('$prefix.ic', 'SCS_TRUE', lines);
        break;
      case XdrSCStatic.SCS_VOID:
        _addLine('$prefix.ic', 'SCS_VOID', lines);
        break;
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
          _addLine('$prefix.absBefore', predicate.absBefore!.int64.toString(),
              lines);
        }
        return;
      case XdrClaimPredicateType.CLAIM_PREDICATE_BEFORE_RELATIVE_TIME:
        _addLine('$prefix.type', "CLAIM_PREDICATE_BEFORE_RELATIVE_TIME", lines);
        if (predicate.relBefore?.int64 != null) {
          _addLine('$prefix.relBefore', predicate.relBefore!.int64.toString(),
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
      case 24:
        return 'INVOKE_HOST_FUNCTION';
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
      case 24:
        return 'invokeHostFunctionOp';
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static String _txRepInvokeHostFnType(XdrHostFunctionType type) {
    if (type == XdrHostFunctionType.HOST_FUNCTION_TYPE_INSTALL_CONTRACT_CODE) {
      return 'HOST_FUNCTION_TYPE_INSTALL_CONTRACT_CODE';
    } else if (type == XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT) {
      return 'HOST_FUNCTION_TYPE_CREATE_CONTRACT';
    } else if (type == XdrHostFunctionType.HOST_FUNCTION_TYPE_INVOKE_CONTRACT) {
      return 'HOST_FUNCTION_TYPE_INVOKE_CONTRACT';
    } else {
      throw Exception("Unknown host function type value: " + type.value);
    }
  }

  static String _toAmount(String value) {
    Decimal amount = Decimal.parse(value) * Decimal.parse('10000000.00');
    return amount.toString();
  }

  static String? _fromAmount(String value) {
    Decimal amount =
        (Decimal.parse(value) / Decimal.parse('10000000.00')).toDecimal();
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
