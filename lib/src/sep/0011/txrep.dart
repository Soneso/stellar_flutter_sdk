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

  static AbstractTransaction fromTxRep(String txRep) {
    if (txRep == null) {
      return null;
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
    String sourceAccountId = _removeComment(map['tx.sourceAccount']);
    int sequenceNumber = int.parse(_removeComment(map['tx.seqNum']));
    KeyPair sourceKeyPair = KeyPair.fromAccountId(sourceAccountId);
    Account sourceAccount = Account(sourceKeyPair, sequenceNumber - 1);
    TransactionBuilder txBuilder = TransactionBuilder(sourceAccount,
        Network.TESTNET); // TODO: remove network from transaction

    // TimeBounds
    if (_removeComment(map['tx.timeBounds._present']) == 'true' &&
        map['tx.timeBounds.minTime'] != null &&
        map['tx.timeBounds.maxTime'] != null) {
      int minTime = int.parse(_removeComment(map['tx.timeBounds.minTime']));
      int maxTime = int.parse(_removeComment(map['tx.timeBounds.maxTime']));
      TimeBounds timeBounds = TimeBounds(minTime, maxTime);
      txBuilder.addTimeBounds(timeBounds);
    }
    // Memo
    String memoType = _removeComment(map['tx.memo.type']);
    if (memoType == 'MEMO_TEXT' && map['tx.memo.text'] != null) {
      txBuilder.addMemo(
          MemoText(_removeComment(map['tx.memo.text']).replaceAll('"', '')));
    } else if (memoType == 'MEMO_ID' && map['tx.memo.id'] != null) {
      txBuilder.addMemo(MemoId(int.parse(_removeComment(map['tx.memo.id']))));
    } else if (memoType == 'MEMO_HASH' && map['tx.memo.hash'] != null) {
      txBuilder.addMemo(
          MemoHash(Util.hexToBytes(_removeComment(map['tx.memo.hash']))));
    } else if (memoType == 'MEMO_RETURN' && map['tx.memo.return'] != null) {
      txBuilder.addMemo(
          MemoReturnHash.string(_removeComment(map['tx.memo.return'])));
    } else {
      txBuilder.addMemo(MemoNone());
    }
    // Operations
    int nrOfOperations = int.parse(_removeComment(map['tx.operations.len']));
    for (int i = 0; i < nrOfOperations; i++) {
      Operation operation = _getOperation(i, map);
      if (operation != null) {
        txBuilder.addOperation(operation);
      }
    }

    AbstractTransaction transaction = txBuilder.build();

    // Signatures
    int nrOfSignatures = int.parse(_removeComment(map['tx.signatures.len']));
    List<XdrDecoratedSignature> signatures = List<XdrDecoratedSignature>();
    for (int i = 0; i < nrOfSignatures; i++) {
      XdrDecoratedSignature signature = _getSignature(i, map);
      if (signature != null) {
        signatures.add(signature);
      }
    }
    transaction.signatures = signatures;
    return transaction;
  }

  static XdrDecoratedSignature _getSignature(
      int index, Map<String, String> map) {
    Uint8List hint =
        Util.hexToBytes(_removeComment(map['tx.signatures[$index].hint']));
    Uint8List signature =
        Util.hexToBytes(_removeComment(map['tx.signatures[$index].signature']));
    XdrSignatureHint sigHint = XdrSignatureHint();
    sigHint.signatureHint = hint;
    XdrSignature sig = XdrSignature();
    sig.signature = signature;
    XdrDecoratedSignature decoratedSignature = XdrDecoratedSignature();
    decoratedSignature.hint = sigHint;
    decoratedSignature.signature = sig;
    return decoratedSignature;
  }

  static Operation _getOperation(int index, Map<String, String> map) {
    String prefix = 'tx.operation[$index].body.';
    String sourceAccountId;
    if (_removeComment(map['tx.operation[$index].sourceAccount._present']) ==
        'true') {
      sourceAccountId =
          _removeComment(map['tx.operation[$index].sourceAccount']);
    }
    if (_removeComment(map[prefix + 'type']) == 'CREATE_ACCOUNT') {
      String opPrefix = prefix + 'createAccountOp.';
      String destination = _removeComment(map[opPrefix + 'destination']);
      String startingBalance =
          fromAmount(_removeComment(map[opPrefix + 'startingBalance']));
      CreateAccountOperationBuilder builder =
          CreateAccountOperationBuilder(destination, startingBalance);
      if (sourceAccountId != null) {
        builder.setSourceAccount(sourceAccountId);
      }
      return builder.build();
    } else if (_removeComment(map[prefix + 'type']) == 'PAYMENT') {
      String opPrefix = prefix + 'paymentOp.';
      String destination = _removeComment(map[opPrefix + 'destination']);
      Asset asset = decodeAsset(_removeComment(map[opPrefix + 'asset']));
      String amount = fromAmount(_removeComment(map[opPrefix + 'amount']));
      PaymentOperationBuilder builder =
          PaymentOperationBuilder(destination, asset, amount);
      if (sourceAccountId != null) {
        builder.setSourceAccount(sourceAccountId);
      }
      return builder.build();
    } else if (_removeComment(map[prefix + 'type']) ==
        'PATH_PAYMENT_STRICT_RECEIVE') {
      String opPrefix = prefix + 'pathPaymentStrictReceiveOp.';
      Asset sendAsset =
          decodeAsset(_removeComment(map[opPrefix + 'sendAsset']));
      String sendMax = fromAmount(_removeComment(map[opPrefix + 'sendMax']));
      String destination = _removeComment(map[opPrefix + 'destination']);
      Asset destAsset =
          decodeAsset(_removeComment(map[opPrefix + 'destAsset']));
      String destAmount =
          fromAmount(_removeComment(map[opPrefix + 'destAmount']));
      List<Asset> path = List<Asset>();
      String pathLengthKey = opPrefix + 'path.len';
      if (map[pathLengthKey] != null) {
        int pathLen = int.parse(_removeComment(map[pathLengthKey]));
        if (pathLen > 5) {
          throw Exception(
              'path.len can not be greater than 5 in $pathLengthKey but is $pathLen');
        }
        for (int i = 0; i < pathLen; i++) {
          Asset nextAsset =
              decodeAsset(_removeComment(map[opPrefix + 'path[$i]']));
          path.add(nextAsset);
        }
      }
      PathPaymentStrictReceiveOperationBuilder builder =
          PathPaymentStrictReceiveOperationBuilder(
              sendAsset, sendMax, destination, destAsset, destAmount);
      builder.setPath(path);
      if (sourceAccountId != null) {
        builder.setSourceAccount(sourceAccountId);
      }
      return builder.build();
    } else if (_removeComment(map[prefix + 'type']) ==
        'PATH_PAYMENT_STRICT_SEND') {
      String opPrefix = prefix + 'pathPaymentStrictSendOp.';
      Asset sendAsset =
          decodeAsset(_removeComment(map[opPrefix + 'sendAsset']));
      String sendAmount =
          fromAmount(_removeComment(map[opPrefix + 'sendAmount']));
      String destination = _removeComment(map[opPrefix + 'destination']);
      Asset destAsset =
          decodeAsset(_removeComment(map[opPrefix + 'destAsset']));
      String destMin = fromAmount(_removeComment(map[opPrefix + 'destMin']));
      List<Asset> path = List<Asset>();
      String pathLengthKey = opPrefix + 'path.len';
      if (map[pathLengthKey] != null) {
        int pathLen = int.parse(_removeComment(map[pathLengthKey]));
        if (pathLen > 5) {
          throw Exception(
              'path.len can not be greater than 5 in $pathLengthKey but is $pathLen');
        }
        for (int i = 0; i < pathLen; i++) {
          Asset nextAsset =
              decodeAsset(_removeComment(map[opPrefix + 'path[$i]']));
          path.add(nextAsset);
        }
      }
      PathPaymentStrictSendOperationBuilder builder =
          PathPaymentStrictSendOperationBuilder(
              sendAsset, sendAmount, destination, destAsset, destMin);
      builder.setPath(path);
      if (sourceAccountId != null) {
        builder.setSourceAccount(sourceAccountId);
      }
      return builder.build();
    } else if (_removeComment(map[prefix + 'type']) == 'MANAGE_SELL_OFFER') {
      String opPrefix = prefix + 'manageSellOfferOp.';
      Asset selling = decodeAsset(_removeComment(map[opPrefix + '.selling']));
      Asset buying = decodeAsset(_removeComment(map[opPrefix + 'buying']));
      String amount = fromAmount(_removeComment(map[opPrefix + 'amount']));
      int n = int.parse(_removeComment(map[opPrefix + 'price.n']));
      int d = int.parse(_removeComment(map[opPrefix + 'price.d']));
      if (d == 0) {
        throw Exception(
            'price denominator can not be 0 in ' + opPrefix + 'price.d');
      }
      Decimal dec = Decimal.parse(n.toString()) / Decimal.parse(d.toString());
      int offerId = int.parse(_removeComment(map[opPrefix + 'offerID']));
      ManageSellOfferOperationBuilder builder = ManageSellOfferOperationBuilder(
          selling, buying, amount, dec.toString());
      builder.setOfferId(offerId.toString());
      if (sourceAccountId != null) {
        builder.setSourceAccount(sourceAccountId);
      }
      return builder.build();
    } else if (_removeComment(map[prefix + 'type']) ==
        'CREATE_PASSIVE_SELL_OFFER') {
      String opPrefix = prefix + 'createPasiveSellOfferOp.';
      Asset selling = decodeAsset(_removeComment(map[opPrefix + 'selling']));
      Asset buying = decodeAsset(_removeComment(map[opPrefix + 'buying']));
      String amount = fromAmount(_removeComment(map[opPrefix + 'amount']));
      int n = int.parse(_removeComment(map[opPrefix + 'price.n']));
      int d = int.parse(_removeComment(map[opPrefix + 'price.d']));
      if (d == 0) {
        throw Exception(
            'price denominator can not be 0 in ' + opPrefix + 'price.d');
      }
      Decimal dec = Decimal.parse(n.toString()) / Decimal.parse(d.toString());

      CreatePassiveSellOfferOperationBuilder builder =
          CreatePassiveSellOfferOperationBuilder(
              selling, buying, amount, dec.toString());
      if (sourceAccountId != null) {
        builder.setSourceAccount(sourceAccountId);
      }
      return builder.build();
    } else if (_removeComment(map[prefix + 'type']) == 'SET_OPTIONS') {
      String opPrefix = prefix + 'setOptionsOp.';
      String inflationDest;
      if (_removeComment(map[opPrefix + 'inflationDest._present']) == 'true') {
        inflationDest = _removeComment(map[opPrefix + 'inflationDest']);
      }
      int clearFlags;
      if (_removeComment(map[opPrefix + 'clearFlags._present']) == 'true') {
        clearFlags = int.parse(_removeComment(map[opPrefix + 'clearFlags']));
      }
      int setFlags;
      if (_removeComment(map[opPrefix + 'setFlags._present']) == 'true') {
        setFlags = int.parse(_removeComment(map[opPrefix + 'setFlags']));
      }
      int masterWeight;
      if (_removeComment(map[opPrefix + 'masterWeight._present']) == 'true') {
        masterWeight =
            int.parse(_removeComment(map[opPrefix + 'masterWeight']));
      }
      int lowThreshold;
      if (_removeComment(map[opPrefix + 'lowThreshold._present']) == 'true') {
        lowThreshold =
            int.parse(_removeComment(map[opPrefix + 'lowThreshold']));
      }
      int medThreshold;
      if (_removeComment(map[opPrefix + 'medThreshold._present']) == 'true') {
        medThreshold =
            int.parse(_removeComment(map[opPrefix + 'medThreshold']));
      }
      int highThreshold;
      if (_removeComment(map[opPrefix + 'highThreshold._present']) == 'true') {
        highThreshold =
            int.parse(_removeComment(map[opPrefix + 'highThreshold']));
      }
      String homeDomain;
      if (_removeComment(map[opPrefix + 'homeDomain._present']) == 'true') {
        homeDomain = _removeComment(map[opPrefix + 'homeDomain'])
            .replaceAll('"', ''); //TODO improve this.
      }
      XdrSignerKey signer;
      int signerWeight;
      if (_removeComment(map[opPrefix + 'signer._present']) == 'true' &&
          map[opPrefix + 'signer.key'] != null &&
          map[opPrefix + 'signer.weight'] != null) {
        signerWeight =
            int.parse(_removeComment(map[opPrefix + 'signer.weight']));

        String key = _removeComment(map[opPrefix + 'signer.key']);
        if (key.startsWith('G')) {
          signer = XdrSignerKey();
          signer.discriminant = XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519;
          signer.ed25519.uint256 = StrKey.decodeStellarAccountId(key);
        } else if (key.startsWith('X')) {
          signer = XdrSignerKey();
          signer.discriminant = XdrSignerKeyType.SIGNER_KEY_TYPE_PRE_AUTH_TX;
          signer.preAuthTx.uint256 = StrKey.decodePreAuthTx(key);
        } else if (key.startsWith('T')) {
          signer = XdrSignerKey();
          signer.discriminant = XdrSignerKeyType.SIGNER_KEY_TYPE_HASH_X;
          signer.hashX.uint256 = StrKey.decodeSha256Hash(key);
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
        builder.setClearFlags(setFlags);
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
        builder.setSourceAccount(sourceAccountId);
      }
      return builder.build();
    } else if (_removeComment(map[prefix + 'type']) == 'CHANGE_TRUST') {
      String opPrefix = prefix + 'changeTrustOp.';
      Asset asset = decodeAsset(_removeComment(map[opPrefix + 'line']));
      String limit;
      if (_removeComment(map[opPrefix + 'limit._present']) == 'true') {
        limit = fromAmount(_removeComment(map[opPrefix + 'limit']));
      }
      ChangeTrustOperationBuilder builder =
          ChangeTrustOperationBuilder(asset, limit);
      if (sourceAccountId != null) {
        builder.setSourceAccount(sourceAccountId);
      }
      return builder.build();
    } else if (_removeComment(map[prefix + 'type']) == 'ALLOW_TRUST') {
      String opPrefix = prefix + 'allowTrustOp.';
      String trustor = _removeComment(map[opPrefix + 'trustor']);
      String assetCode = _removeComment(map[opPrefix + 'asset']);
      int authtorize = int.parse(_removeComment(map[opPrefix + 'authorize']));
      AllowTrustOperationBuilder builder =
          AllowTrustOperationBuilder(trustor, assetCode, authtorize);
      if (sourceAccountId != null) {
        builder.setSourceAccount(sourceAccountId);
      }
      return builder.build();
    } else if (_removeComment(map[prefix + 'type']) == 'ACCOUNT_MERGE') {
      // account merge does not include 'accountMergeOp' prefix
      String destination =
          _removeComment(map['tx.operation[$index].body.destination']);
      AccountMergeOperationBuilder builder =
          AccountMergeOperationBuilder(destination);
      if (sourceAccountId != null) {
        builder.setSourceAccount(sourceAccountId);
      }
      return builder.build();
    } else if (_removeComment(map[prefix + 'type']) == 'MANAGE_DATA') {
      String opPrefix = prefix + 'manageDataOp.';
      String dataName = _removeComment(map[opPrefix + 'dataName']);
      Uint8List value;
      if (_removeComment(map[opPrefix + 'dataValue._present']) == 'true') {
        String valueHex =
            fromAmount(_removeComment(map[opPrefix + 'dataValue']));
        value = Util.hexToBytes(valueHex);
      }
      ManageDataOperationBuilder builder =
          ManageDataOperationBuilder(dataName, value);
      if (sourceAccountId != null) {
        builder.setSourceAccount(sourceAccountId);
      }
      return builder.build();
    } else if (_removeComment(map[prefix + 'type']) == 'BUMP_SEQUENCE') {
      String opPrefix = prefix + 'bumpSequenceOp.';
      int bumpTo = int.parse(_removeComment(map[opPrefix + 'bumpTo']));
      BumpSequenceOperationBuilder builder =
          BumpSequenceOperationBuilder(bumpTo);
      if (sourceAccountId != null) {
        builder.setSourceAccount(sourceAccountId);
      }
      return builder.build();
    } else if (_removeComment(map[prefix + 'type']) == 'MANAGE_BUY_OFFER') {
      String opPrefix = prefix + 'manageBuyOfferOp.';
      Asset selling = decodeAsset(_removeComment(map[opPrefix + 'selling']));
      Asset buying = decodeAsset(_removeComment(map[opPrefix + 'buying']));
      String amount = fromAmount(_removeComment(map[opPrefix + 'buyAmount']));
      int n = int.parse(_removeComment(map[opPrefix + 'price.n']));
      int d = int.parse(_removeComment(map[opPrefix + 'price.d']));
      if (d == 0) {
        throw Exception(
            'price denominator can not be 0 in ' + opPrefix + 'price.d');
      }
      Decimal dec = Decimal.parse(n.toString()) / Decimal.parse(d.toString());
      int offerId = int.parse(_removeComment(map[opPrefix + 'offerID']));
      ManageBuyOfferOperationBuilder builder = ManageBuyOfferOperationBuilder(
          selling, buying, amount, dec.toString());
      builder.setOfferId(offerId.toString());
      if (sourceAccountId != null) {
        builder.setSourceAccount(sourceAccountId);
      }
      return builder.build();
    }
    return null;
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
      _addLine('tx.memo.text', jsonEncoder.convert(memo.text), lines);
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
              StrKey.encodePreAuthTx(operation.signer.hashX.uint256), lines);
        }

        _addLine(
            '$prefix.signer.weight', operation.signerWeight.toString(), lines);
      } else {
        _addLine('$prefix.signer._present', 'false', lines);
      }
    } else if (operation is ChangeTrustOperation) {
      _addLine('$prefix.line', encodeAsset(operation.asset), lines);
      if (operation.limit != null) {
        _addLine('$prefix.limit._present', 'true', lines);
        _addLine('$prefix.limit', toAmount(operation.limit), lines);
      } else {
        _addLine('$prefix.limit._present', 'false', lines);
      }
    } else if (operation is AllowTrustOperation) {
      _addLine('$prefix.trustor', operation.trustor, lines);
      _addLine('$prefix.asset', operation.assetCode, lines);
      int auth = operation.authorize ? 1 : 0;
      auth = operation.authorizeToMaintainLiabilities ? 2 : auth;
      _addLine('$prefix.authorize', auth.toString(), lines);
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
