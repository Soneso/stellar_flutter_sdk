// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import "dart:convert";
import 'dart:typed_data';
import 'muxed_account.dart';
import 'key_pair.dart';
import 'memo.dart';
import 'network.dart';
import 'operation.dart';
import 'util.dart';
import 'xdr/xdr_account.dart';
import 'xdr/xdr_data_io.dart';
import 'xdr/xdr_operation.dart';
import 'xdr/xdr_signing.dart';
import 'xdr/xdr_transaction.dart';
import 'xdr/xdr_type.dart';
import 'account.dart';

abstract class AbstractTransaction {
  List<XdrDecoratedSignature> _mSignatures;
  static const int MIN_BASE_FEE = 100;

  AbstractTransaction() {
    _mSignatures = List<XdrDecoratedSignature>();
  }

  /// Signs the transaction for the [signer] and given [network] passphrase.
  void sign(KeyPair signer, Network network) {
    checkNotNull(signer, "signer cannot be null");
    checkNotNull(network, "signer cannot be null");
    Uint8List txHash = this.hash(network);
    _mSignatures.add(signer.signDecorated(txHash));
  }

  /// Adds a sha256Hash signature to this transaction by revealing [preimage].
  void signHash(Uint8List preimage) {
    checkNotNull(preimage, "preimage cannot be null");
    XdrSignature signature = XdrSignature();
    signature.signature = preimage;

    Uint8List hash = Util.hash(preimage);
    Uint8List signatureHintBytes = Uint8List.fromList(
        hash.getRange(hash.length - 4, hash.length).toList());
    XdrSignatureHint signatureHint = XdrSignatureHint();
    signatureHint.signatureHint = signatureHintBytes;

    XdrDecoratedSignature decoratedSignature = XdrDecoratedSignature();
    decoratedSignature.hint = signatureHint;
    decoratedSignature.signature = signature;

    _mSignatures.add(decoratedSignature);
  }

  /// Returns the transaction hash of this transaction.
  Uint8List hash(Network network) {
    return Util.hash(this.signatureBase(network));
  }

  Uint8List signatureBase(Network network);

  List<XdrDecoratedSignature> get signatures => _mSignatures;
  set signatures(List<XdrDecoratedSignature> value) =>
      this._mSignatures = value;

  XdrTransactionEnvelope toEnvelopeXdr();

  /// Returns a base64-encoded TransactionEnvelope XDR object of this transaction.
  /// This transaction needs to have at least one signature.
  String toEnvelopeXdrBase64() {
    XdrTransactionEnvelope envelope = this.toEnvelopeXdr();
    XdrDataOutputStream xdrOutputStream = XdrDataOutputStream();
    XdrTransactionEnvelope.encode(xdrOutputStream, envelope);
    return base64Encode(xdrOutputStream.bytes);
  }

  static AbstractTransaction fromEnvelopeXdr(XdrTransactionEnvelope envelope) {
    switch (envelope.discriminant) {
      case XdrEnvelopeType.ENVELOPE_TYPE_TX:
        return Transaction.fromV1EnvelopeXdr(envelope.v1);
        break;
      case XdrEnvelopeType.ENVELOPE_TYPE_TX_V0:
        return Transaction.fromV0EnvelopeXdr(envelope.v0);
        break;
      case XdrEnvelopeType.ENVELOPE_TYPE_TX_FEE_BUMP:
        return FeeBumpTransaction.fromFeeBumpTransactionEnvelope(
            envelope.feeBump);
        break;
      default:
        throw Exception("transaction type is not supported: " +
            envelope.discriminant.value);
        break;
    }
  }

  /// Creates a [Transaction] instance from an xdr [envelope] string representing a TransactionEnvelope.
  static AbstractTransaction fromEnvelopeXdrString(String envelope) {
    Uint8List bytes = base64Decode(envelope);
    XdrTransactionEnvelope transactionEnvelope =
        XdrTransactionEnvelope.decode(XdrDataInputStream(bytes));
    return fromEnvelopeXdr(transactionEnvelope);
  }
}

/// Represents <a href="https://www.stellar.org/developers/learn/concepts/transactions.html" target="_blank">Transaction</a> in the Stellar network.
class Transaction extends AbstractTransaction {
  int _mFee;
  MuxedAccount _mSourceAccount;
  int _mSequenceNumber;
  List<Operation> _mOperations;
  Memo _mMemo;
  TimeBounds _mTimeBounds;

  Transaction(MuxedAccount sourceAccount, int fee, int sequenceNumber,
      List<Operation> operations, Memo memo, TimeBounds timeBounds)
      : super() {
    _mSourceAccount =
        checkNotNull(sourceAccount, "sourceAccount cannot be null");
    _mSequenceNumber =
        checkNotNull(sequenceNumber, "sequenceNumber cannot be null");
    _mOperations = checkNotNull(operations, "operations cannot be null");
    checkArgument(operations.length > 0, "At least one operation required");

    _mFee = fee;
    _mMemo = memo != null ? memo : Memo.none();
    _mTimeBounds = timeBounds;
  }

  /// Returns signature base of this transaction.
  Uint8List signatureBase(Network network) {
    try {
      XdrDataOutputStream xdrOutputStream = XdrDataOutputStream();
      // Hashed NetworkID
      xdrOutputStream.write(network.networkId);
      // Envelope Type - 4 bytes
      List<int> typeTx = List<int>.filled(4, 0);
      typeTx[3] = XdrEnvelopeType.ENVELOPE_TYPE_TX.value;
      xdrOutputStream.write(typeTx);
      // Transaction XDR bytes
      XdrTransaction.encode(xdrOutputStream, this.toXdr());

      return Uint8List.fromList(xdrOutputStream.bytes);
    } catch (exception) {
      return null;
    }
  }

  MuxedAccount get sourceAccount => _mSourceAccount;

  int get sequenceNumber => _mSequenceNumber;

  Memo get memo => _mMemo;

  /// Return TimeBounds of this transaction, or null (representing no time restrictions)
  TimeBounds get timeBounds => _mTimeBounds;

  /// Returns fee paid for this transaction in stroops (1 stroop = 0.0000001 XLM).
  int get fee => _mFee;

  /// Returns the list of operations in this transaction.
  List<Operation> get operations => _mOperations;

  /// Generates a V0 Transaction XDR object for this transaction.
  XdrTransactionV0 toV0Xdr() {
    // fee
    XdrUint32 fee = XdrUint32();
    fee.uint32 = _mFee;
    // sequenceNumber
    XdrInt64 sequenceNumberUint = XdrInt64();
    sequenceNumberUint.int64 = _mSequenceNumber;
    XdrSequenceNumber sequenceNumber = XdrSequenceNumber();
    sequenceNumber.sequenceNumber = sequenceNumberUint;
    XdrPublicKey sourcePublickKey =
        KeyPair.fromAccountId(_mSourceAccount.ed25519AccountId).xdrPublicKey;
    // sourceAccount
    XdrAccountID sourceAccount = XdrAccountID();
    sourceAccount.accountID = sourcePublickKey;
    // operations
    List<XdrOperation> operations = List<XdrOperation>(_mOperations.length);
    for (int i = 0; i < _mOperations.length; i++) {
      operations[i] = _mOperations[i].toXdr();
    }
    // ext
    XdrTransactionV0Ext ext = XdrTransactionV0Ext();
    ext.discriminant = 0;

    XdrTransactionV0 transaction = XdrTransactionV0();
    transaction.fee = fee;
    transaction.seqNum = sequenceNumber;
    transaction.sourceAccountEd25519 = sourcePublickKey.getEd25519();
    transaction.operations = operations;
    transaction.memo = _mMemo.toXdr();
    transaction.timeBounds =
        (_mTimeBounds == null ? null : _mTimeBounds.toXdr());
    transaction.ext = ext;
    return transaction;
  }

  String toXdrBase64() {
    XdrTransaction xdr = this.toXdr();
    XdrDataOutputStream xdrOutputStream = XdrDataOutputStream();
    XdrTransaction.encode(xdrOutputStream, xdr);
    return base64Encode(xdrOutputStream.bytes);
  }

  /// Generates a V1 Transaction XDR object for this transaction.
  XdrTransaction toXdr() {
    // fee
    XdrUint32 fee = XdrUint32();
    fee.uint32 = _mFee;

    // sequenceNumber
    XdrInt64 sequenceNumberUint = XdrInt64();
    sequenceNumberUint.int64 = _mSequenceNumber;
    XdrSequenceNumber sequenceNumber = XdrSequenceNumber();
    sequenceNumber.sequenceNumber = sequenceNumberUint;

    // operations
    List<XdrOperation> operations = List<XdrOperation>(_mOperations.length);
    for (int i = 0; i < _mOperations.length; i++) {
      operations[i] = _mOperations[i].toXdr();
    }

    // ext
    XdrTransactionExt ext = XdrTransactionExt();
    ext.discriminant = 0;

    XdrTransaction transaction = XdrTransaction();
    transaction.fee = fee;
    transaction.seqNum = sequenceNumber;
    transaction.sourceAccount = _mSourceAccount.toXdr();
    transaction.operations = operations;
    transaction.memo = _mMemo.toXdr();
    transaction.timeBounds =
        (_mTimeBounds == null ? null : _mTimeBounds.toXdr());
    transaction.ext = ext;
    return transaction;
  }

  /// Creates a [Transaction] instance from a XdrTransactionV1Envelope [envelope].
  static Transaction fromV1EnvelopeXdr(XdrTransactionV1Envelope envelope) {
    XdrTransaction tx = envelope.tx;
    int mFee = tx.fee.uint32;

    int mSequenceNumber = tx.seqNum.sequenceNumber.int64;
    Memo mMemo = Memo.fromXdr(tx.memo);
    TimeBounds mTimeBounds = TimeBounds.fromXdr(tx.timeBounds);

    List<Operation> mOperations = List<Operation>(tx.operations.length);
    for (int i = 0; i < tx.operations.length; i++) {
      mOperations[i] = Operation.fromXdr(tx.operations[i]);
    }

    Transaction transaction = Transaction(
        MuxedAccount.fromXdr(tx.sourceAccount),
        mFee,
        mSequenceNumber,
        mOperations,
        mMemo,
        mTimeBounds);

    for (XdrDecoratedSignature signature in envelope.signatures) {
      transaction._mSignatures.add(signature);
    }

    return transaction;
  }

  /// Creates a [Transaction] instance from a XdrTransactionV0Envelope [envelope].
  static Transaction fromV0EnvelopeXdr(XdrTransactionV0Envelope envelope) {
    XdrTransactionV0 tx = envelope.tx;
    int mFee = tx.fee.uint32;
    String mSourceAccount =
        KeyPair.fromPublicKey(tx.sourceAccountEd25519.uint256).accountId;
    int mSequenceNumber = tx.seqNum.sequenceNumber.int64;
    Memo mMemo = Memo.fromXdr(tx.memo);
    TimeBounds mTimeBounds = TimeBounds.fromXdr(tx.timeBounds);

    List<Operation> mOperations = List<Operation>(tx.operations.length);
    for (int i = 0; i < tx.operations.length; i++) {
      mOperations[i] = Operation.fromXdr(tx.operations[i]);
    }
    MuxedAccount muxSource = MuxedAccount(mSourceAccount, null);
    Transaction transaction = Transaction(
        muxSource, mFee, mSequenceNumber, mOperations, mMemo, mTimeBounds);

    for (XdrDecoratedSignature signature in envelope.signatures) {
      transaction._mSignatures.add(signature);
    }

    return transaction;
  }

  /// Generates a TransactionEnvelope XDR object for this transaction.
  /// This transaction needs to have at least one signature.
  XdrTransactionEnvelope toEnvelopeXdr() {
    if (_mSignatures.length == 0) {
      throw Exception(
          "Transaction must be signed by at least one signer. Use transaction.sign().");
    }

    XdrTransactionEnvelope xdrTe = XdrTransactionEnvelope();
    XdrTransaction transaction = this.toXdr();
    XdrTransactionV1Envelope v1Envelope = XdrTransactionV1Envelope();
    v1Envelope.tx = transaction;
    List<XdrDecoratedSignature> signatures = List<XdrDecoratedSignature>();
    signatures.addAll(_mSignatures);
    v1Envelope.signatures = signatures;
    xdrTe.discriminant = XdrEnvelopeType.ENVELOPE_TYPE_TX;
    xdrTe.v1 = v1Envelope;
    return xdrTe;
  }

  /// Builds a new TransactionBuilder object.
  static TransactionBuilder builder(TransactionBuilderAccount sourceAccount) {
    return TransactionBuilder(sourceAccount);
  }
}

/// Builds a Transaction object.
class TransactionBuilder {
  TransactionBuilderAccount _mSourceAccount;
  Memo _mMemo;
  TimeBounds _mTimeBounds;
  List<Operation> _mOperations;
  int _mMaxOperationFee;

  int get operationsCount => _mOperations.length;

  /// Construct a transaction builder.
  TransactionBuilder(TransactionBuilderAccount sourceAccount) {
    checkNotNull(sourceAccount, "sourceAccount cannot be null");
    _mSourceAccount = sourceAccount;
    _mOperations = List<Operation>();
  }

  /// Adds an <a href="https://www.stellar.org/developers/learn/concepts/list-of-operations.html" target="_blank">operation</a> to this transaction.
  TransactionBuilder addOperation(Operation operation) {
    checkNotNull(operation, "operation cannot be null");
    _mOperations.add(operation);
    return this;
  }

  /// Adds a <a href="https://www.stellar.org/developers/learn/concepts/transactions.html" target="_blank">memo</a> to this transaction.
  TransactionBuilder addMemo(Memo memo) {
    if (_mMemo != null) {
      throw Exception("Memo has been already added.");
    }
    checkNotNull(memo, "memo cannot be null");
    _mMemo = memo;
    return this;
  }

  /// Adds <a href="https://www.stellar.org/developers/learn/concepts/transactions.html" target="_blank">time-bounds</a> to this transaction.
  TransactionBuilder addTimeBounds(TimeBounds timeBounds) {
    if (_mTimeBounds != null) {
      throw Exception("TimeBounds has been already added.");
    }
    checkNotNull(timeBounds, "timeBounds cannot be null");
    _mTimeBounds = timeBounds;
    return this;
  }

  TransactionBuilder setMaxOperationFee(int maxOperationFee) {
    checkNotNull(maxOperationFee, "maxOperationFee cannot be null");
    if (maxOperationFee < AbstractTransaction.MIN_BASE_FEE) {
      throw new Exception(
          "maxOperationFee cannot be smaller than the BASE_FEE (${AbstractTransaction.MIN_BASE_FEE}): $maxOperationFee");
    }
    _mMaxOperationFee = maxOperationFee;
    return this;
  }

  /// Builds a transaction. It will increment the sequence number of the source account.
  Transaction build() {
    if (_mMaxOperationFee == null) {
      _mMaxOperationFee = AbstractTransaction.MIN_BASE_FEE;
    }
    List<Operation> operations = List<Operation>();
    operations.addAll(_mOperations);
    Transaction transaction = Transaction(
        _mSourceAccount.muxedAccount,
        operations.length * _mMaxOperationFee,
        _mSourceAccount.incrementedSequenceNumber,
        operations,
        _mMemo,
        _mTimeBounds);
    // Increment sequence number when there were no exceptions when creating a transaction
    _mSourceAccount.incrementSequenceNumber();
    return transaction;
  }
}

/// Represents <a href="https://github.com/stellar/stellar-protocol/blob/master/core/cap-0015.md" target="_blank">Fee Bump Transaction</a> in Stellar network.
class FeeBumpTransaction extends AbstractTransaction {
  int _mFee;
  MuxedAccount _mFeeAccount;
  Transaction _mInner;

  int get fee => this._mFee;
  MuxedAccount get feeAccount => this._mFeeAccount;
  Transaction get innerTransaction => this._mInner;

  FeeBumpTransaction(
      MuxedAccount feeAccount, int fee, Transaction innerTransaction)
      : super() {
    _mFeeAccount = checkNotNull(feeAccount, "feeAccount cannot be null");
    _mFee = checkNotNull(fee, "fee cannot be null");
    _mInner = innerTransaction;
  }

  static FeeBumpTransaction fromFeeBumpTransactionEnvelope(
      XdrFeeBumpTransactionEnvelope envelope) {
    Transaction inner = Transaction.fromV1EnvelopeXdr(envelope.tx.innerTx.v1);
    int fee = envelope.tx.fee.int64;
    FeeBumpTransaction feeBump = FeeBumpTransaction(
        MuxedAccount.fromXdr(envelope.tx.feeSource), fee, inner);
    return feeBump;
  }

  /// Returns signature base of this transaction.
  Uint8List signatureBase(Network network) {
    try {
      XdrDataOutputStream xdrOutputStream = XdrDataOutputStream();
      // Hashed NetworkID
      xdrOutputStream.write(network.networkId);
      // Envelope Type - 4 bytes
      List<int> typeTx = List<int>.filled(4, 0);
      typeTx[3] = XdrEnvelopeType.ENVELOPE_TYPE_TX_FEE_BUMP.value;
      xdrOutputStream.write(typeTx);
      // Transaction XDR bytes
      XdrFeeBumpTransaction.encode(xdrOutputStream, this.toXdr());

      return Uint8List.fromList(xdrOutputStream.bytes);
    } catch (exception) {
      return null;
    }
  }

  String toXdrBase64() {
    XdrFeeBumpTransaction xdr = this.toXdr();
    XdrDataOutputStream xdrOutputStream = XdrDataOutputStream();
    XdrFeeBumpTransaction.encode(xdrOutputStream, xdr);
    return base64Encode(xdrOutputStream.bytes);
  }

  /// Generates a Fee Bump Transaction XDR object for this fee bump transaction.
  XdrFeeBumpTransaction toXdr() {
    XdrFeeBumpTransaction xdr = XdrFeeBumpTransaction();
    xdr.ext = XdrFeeBumpTransactionExt();
    xdr.ext.discriminant = 0;

    XdrInt64 xdrFee = new XdrInt64();
    xdrFee.int64 = _mFee;
    xdr.fee = xdrFee;

    xdr.feeSource = _mFeeAccount.toXdr();

    XdrFeeBumpTransactionInnerTx innerXDR = XdrFeeBumpTransactionInnerTx();
    innerXDR.discriminant = XdrEnvelopeType.ENVELOPE_TYPE_TX;
    innerXDR.v1 = _mInner.toEnvelopeXdr().v1;
    xdr.innerTx = innerXDR;

    return xdr;
  }

  /// Generates a TransactionEnvelope XDR object for this transaction.
  XdrTransactionEnvelope toEnvelopeXdr() {
    XdrTransactionEnvelope xdr = XdrTransactionEnvelope();
    XdrFeeBumpTransactionEnvelope feeBumpEnvelope =
        XdrFeeBumpTransactionEnvelope();

    feeBumpEnvelope.tx = this.toXdr();

    List<XdrDecoratedSignature> signatures = List<XdrDecoratedSignature>();
    signatures.addAll(_mSignatures);
    feeBumpEnvelope.signatures = signatures;
    xdr.discriminant = XdrEnvelopeType.ENVELOPE_TYPE_TX_FEE_BUMP;
    xdr.feeBump = feeBumpEnvelope;

    return xdr;
  }

  /// Builds a new FeeBumpTransactionBuilder object.
  static FeeBumpTransactionBuilder builder(
    Transaction innerTransaction,
  ) {
    return FeeBumpTransactionBuilder(innerTransaction);
  }
}

/// Builds a FeeBumpTransaction object.
class FeeBumpTransactionBuilder {
  Transaction _mInner;
  int _mBaseFee;
  MuxedAccount _mFeeAccount;

  /// Construct a new fee bump transaction builder.
  FeeBumpTransactionBuilder(Transaction inner) {
    checkNotNull(inner, "inner cannot be null");

    if (inner.toEnvelopeXdr().discriminant ==
        XdrEnvelopeType.ENVELOPE_TYPE_TX_V0) {
      _mInner = new Transaction(inner.sourceAccount, inner.fee,
          inner.sequenceNumber, inner.operations, inner.memo, inner.timeBounds);
      _mInner._mSignatures = inner.signatures;
    } else {
      _mInner = inner;
    }
  }

  FeeBumpTransactionBuilder setBaseFee(int baseFee) {
    if (_mBaseFee != null) {
      throw Exception("base fee has been already set.");
    }
    if (baseFee < AbstractTransaction.MIN_BASE_FEE) {
      throw new Exception("baseFee cannot be smaller than the BASE_FEE (" +
          AbstractTransaction.MIN_BASE_FEE.toString() +
          "): " +
          baseFee.toString());
    }

    int innerBaseFee = _mInner.fee;
    int numOperations = _mInner.operations.length;
    if (numOperations > 0) {
      innerBaseFee = (innerBaseFee / numOperations).round();
    }

    if (baseFee < innerBaseFee) {
      throw new Exception(
          "base fee cannot be lower than provided inner transaction base fee");
    }

    int maxFee = baseFee * (numOperations + 1);
    if (maxFee < 0) {
      throw new Exception("fee overflows 64 bit int");
    }

    _mBaseFee = maxFee;
    return this;
  }

  FeeBumpTransactionBuilder setFeeAccount(String feeAccount) {
    if (_mFeeAccount != null) {
      throw new Exception("fee account has been already been set.");
    }
    checkNotNull(feeAccount, "feeAccount cannot be null");
    _mFeeAccount = MuxedAccount(feeAccount, null);
    return this;
  }

  FeeBumpTransactionBuilder setMuxedFeeAccount(MuxedAccount feeAccount) {
    if (_mFeeAccount != null) {
      throw new Exception("fee account has been already been set.");
    }
    _mFeeAccount = checkNotNull(feeAccount, "feeAccount cannot be null");
    return this;
  }

  /// Builds a transaction. It will increment the sequence number of the source account.
  FeeBumpTransaction build() {
    return new FeeBumpTransaction(
        checkNotNull(_mFeeAccount,
            "fee account has to be set. you must call setFeeAccount()."),
        checkNotNull(
            _mBaseFee, "base fee has to be set. you must call setBaseFee()."),
        _mInner);
  }
}

/// TimeBounds represents the time interval that a transaction is valid.
class TimeBounds {
  int _mMinTime;
  int _mMaxTime;

  /// Constructor [minTime] and [maxTime] are 64bit Unix timestamps.
  TimeBounds(int minTime, int maxTime) {
    if (minTime < 0) {
      throw Exception("minTime cannot be negative");
    }

    if (maxTime < 0) {
      throw new Exception("maxTime cannot be negative");
    }
    if (maxTime != 0 && minTime >= maxTime) {
      throw Exception("minTime must be >= maxTime");
    }

    _mMinTime = minTime;
    _mMaxTime = maxTime;
  }

  int get minTime => _mMinTime;

  int get maxTime => _mMaxTime;

  /// A factory method that sets maxTime to the specified [timeout] second from now. [timeout] in seconds.
  static TimeBounds expiresAfter(int timeout) {
    int now = (DateTime.now().millisecondsSinceEpoch / 1000).round();
    int endTime = now + timeout;
    return TimeBounds(0, endTime);
  }

  /// Creates a [TimeBounds] instance from a [timeBounds] XdrTimeBounds object.
  static TimeBounds fromXdr(XdrTimeBounds timeBounds) {
    if (timeBounds == null) {
      return null;
    }

    return TimeBounds(timeBounds.minTime.uint64, timeBounds.maxTime.uint64);
  }

  /// Creates a [XdrTimeBounds] object from this time bounds.
  XdrTimeBounds toXdr() {
    XdrTimeBounds timeBounds = XdrTimeBounds();
    XdrUint64 minTime = XdrUint64();
    XdrUint64 maxTime = XdrUint64();
    minTime.uint64 = _mMinTime;
    maxTime.uint64 = _mMaxTime;
    timeBounds.minTime = minTime;
    timeBounds.maxTime = maxTime;
    return timeBounds;
  }

  @override
  bool operator ==(Object o) {
    if (this == o) {
      return true;
    }

    if (o == null || !(o is TimeBounds)) {
      return false;
    }

    TimeBounds that = o as TimeBounds;

    if (_mMinTime != that.minTime) return false;
    return _mMaxTime == that.maxTime;
  }
}
