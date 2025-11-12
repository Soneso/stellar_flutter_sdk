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
import 'xdr/xdr_memo.dart';
import 'account.dart';
import 'invoke_host_function_operation.dart';
import 'soroban/soroban_auth.dart';

/// Base class for all Stellar transaction types.
///
/// Provides common functionality for transaction signing, hashing, and XDR serialization.
/// This abstract class is the foundation for both standard [Transaction] and
/// [FeeBumpTransaction] types.
///
/// Key features:
/// - Transaction signing with one or more keypairs
/// - Hash signature verification
/// - XDR envelope creation and parsing
/// - Network-specific transaction hashing
///
/// Transaction types:
/// - [Transaction]: Standard transaction with operations
/// - [FeeBumpTransaction]: Fee bump wrapper for existing transactions
///
/// Example:
/// ```dart
/// // Sign a transaction
/// transaction.sign(keyPair, Network.TESTNET);
///
/// // Get transaction hash
/// Uint8List hash = transaction.hash(Network.TESTNET);
///
/// // Convert to XDR for submission
/// String xdr = transaction.toEnvelopeXdrBase64();
///
/// // Parse from XDR
/// AbstractTransaction tx = AbstractTransaction.fromEnvelopeXdrString(xdr);
/// ```
///
/// See also:
/// - [Transaction] for standard transactions
/// - [FeeBumpTransaction] for fee bump transactions
/// - [Stellar Transaction Guide](https://developers.stellar.org/docs/learn/fundamentals/transactions)
abstract class AbstractTransaction {
  late List<XdrDecoratedSignature> _mSignatures;
  static const int MIN_BASE_FEE = 100;

  AbstractTransaction() {
    _mSignatures = [];
  }

  /// Signs the transaction with the given keypair for a specific network.
  ///
  /// Adds a signature to this transaction using the provided [signer] keypair.
  /// The signature is computed over the transaction hash for the specified [network].
  /// Multiple signatures can be added by calling this method multiple times with
  /// different signers.
  ///
  /// Parameters:
  /// - [signer]: The [KeyPair] to sign with (must have the private key)
  /// - [network]: The [Network] passphrase (e.g., Network.TESTNET or Network.PUBLIC)
  ///
  /// Security notes:
  /// - Always verify you're signing for the correct network
  /// - Never reuse signatures across different networks
  /// - The transaction hash includes the network passphrase to prevent replay attacks
  ///
  /// Example:
  /// ```dart
  /// transaction.sign(sourceKeyPair, Network.TESTNET);
  /// // For multi-sig, add additional signatures
  /// transaction.sign(secondKeyPair, Network.TESTNET);
  /// ```
  void sign(KeyPair signer, Network network) {
    _mSignatures.add(signer.signDecorated(this.hash(network)));
  }

  /// Adds a sha256Hash signature to this transaction by revealing [preimage].
  void signHash(Uint8List preimage) {
    XdrSignature signature = XdrSignature(preimage);

    Uint8List hash = Util.hash(preimage);
    Uint8List signatureHintBytes = Uint8List.fromList(
        hash.getRange(hash.length - 4, hash.length).toList());

    XdrSignatureHint signatureHint = XdrSignatureHint(signatureHintBytes);

    XdrDecoratedSignature decoratedSignature =
        XdrDecoratedSignature(signatureHint, signature);

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
        return Transaction.fromV1EnvelopeXdr(envelope.v1!);
      case XdrEnvelopeType.ENVELOPE_TYPE_TX_V0:
        return Transaction.fromV0EnvelopeXdr(envelope.v0!);
      case XdrEnvelopeType.ENVELOPE_TYPE_TX_FEE_BUMP:
        return FeeBumpTransaction.fromFeeBumpTransactionEnvelope(
            envelope.feeBump!);
      default:
        throw Exception("transaction type is not supported: " +
            envelope.discriminant.value);
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

/// Represents a transaction in the Stellar network.
///
/// A transaction is a grouping of operations that are executed atomically on the
/// Stellar ledger. Transactions are the fundamental unit of change in Stellar -
/// they contain one or more operations and must be signed by the source account(s)
/// before submission to the network.
///
/// Transaction workflow:
/// 1. Build the transaction with operations using [TransactionBuilder]
/// 2. Sign the transaction with one or more keypairs using [sign]
/// 3. Convert to XDR format using [toEnvelopeXdrBase64]
/// 4. Submit the XDR to the network via Horizon or Soroban RPC
///
/// Example:
/// ```dart
/// // Load the source account from the network
/// Account sourceAccount = await sdk.accounts.account(sourceKeyPair.accountId);
///
/// // Build a transaction with a payment operation
/// Transaction transaction = TransactionBuilder(sourceAccount)
///   .addOperation(
///     PaymentOperationBuilder(
///       destinationAccountId,
///       Asset.native(),
///       "100.50"
///     ).build()
///   )
///   .addMemo(Memo.text("Payment memo"))
///   .build();
///
/// // Sign the transaction
/// transaction.sign(sourceKeyPair, Network.TESTNET);
///
/// // Submit to the network
/// SubmitTransactionResponse response = await sdk.submitTransaction(transaction);
/// ```
///
/// Security considerations:
/// - Always verify the network passphrase matches your intended network
/// - Review all operations before signing
/// - Keep private keys secure and never expose them
/// - Validate transaction results before considering operations complete
///
/// See also:
/// - [TransactionBuilder] for constructing transactions
/// - [Operation] for available operation types
/// - [Network] for network passphrases
/// - [Stellar Transaction Documentation](https://developers.stellar.org/docs/learn/fundamentals/transactions)
class Transaction extends AbstractTransaction {
  int _mFee;
  int get fee => this._mFee;
  set fee(int value) => this._mFee = value;

  MuxedAccount _mSourceAccount;
  BigInt _mSequenceNumber;
  List<Operation> _mOperations;
  Memo? _mMemo;
  TransactionPreconditions? _mPreconditions;

  XdrSorobanTransactionData? _sorobanTransactionData;
  XdrSorobanTransactionData? get sorobanTransactionData =>
      this._sorobanTransactionData;
  set sorobanTransactionData(XdrSorobanTransactionData? value) =>
      this._sorobanTransactionData = value;

  Transaction(this._mSourceAccount, this._mFee, this._mSequenceNumber,
      this._mOperations, Memo? memo, TransactionPreconditions? preconditions,
      {XdrSorobanTransactionData? sorobanTransactionData})
      : super() {
    checkArgument(
        this._mOperations.length > 0, "At least one operation required");

    _mMemo = memo != null ? memo : Memo.none();
    _mPreconditions = preconditions;
    _sorobanTransactionData = sorobanTransactionData;
  }

  /// Returns signature base of this transaction.
  Uint8List signatureBase(Network network) {
    XdrDataOutputStream xdrOutputStream = XdrDataOutputStream();
    // Hashed NetworkID
    xdrOutputStream.write(network.networkId!);
    // Envelope Type - 4 bytes
    List<int> typeTx = List<int>.filled(4, 0);
    typeTx[3] = XdrEnvelopeType.ENVELOPE_TYPE_TX.value;
    xdrOutputStream.write(typeTx);
    // Transaction XDR bytes
    XdrTransaction.encode(xdrOutputStream, this.toXdr());

    return Uint8List.fromList(xdrOutputStream.bytes);
  }

  MuxedAccount get sourceAccount => _mSourceAccount;

  BigInt get sequenceNumber => _mSequenceNumber;

  Memo? get memo => _mMemo;

  /// Return transaction preconditions as specified by CAP-21 and CAP-40
  TransactionPreconditions? get preconditions => _mPreconditions;

  /// Returns the list of operations in this transaction.
  List<Operation> get operations => _mOperations;

  /// Adds additional resource fee to the transaction fee.
  ///
  /// This method is used for Soroban smart contract transactions where resource
  /// fees are calculated separately and added to the base transaction fee.
  ///
  /// Parameters:
  /// - [resourceFee]: The additional resource fee in stroops
  ///
  /// Example:
  /// ```dart
  /// transaction.addResourceFee(50000);
  /// ```
  addResourceFee(int resourceFee) {
    this._mFee += resourceFee;
  }

  /// Generates a V0 Transaction XDR object for this transaction.
  XdrTransactionV0 toV0Xdr() {
    // fee
    XdrUint32 fee = XdrUint32(_mFee);
    // sequenceNumber
    XdrBigInt64 sequenceNumberUint = XdrBigInt64(_mSequenceNumber);

    XdrPublicKey sourcePublickKey =
        KeyPair.fromAccountId(_mSourceAccount.ed25519AccountId).xdrPublicKey;

    // operations
    List<XdrOperation> operations = List<XdrOperation>.empty(growable: true);
    for (int i = 0; i < _mOperations.length; i++) {
      operations.add(_mOperations[i].toXdr());
    }

    TimeBounds? tb = _mPreconditions?.timeBounds;
    XdrTimeBounds? xdrTimeBounds = (tb == null ? null : tb.toXdr());
    XdrMemo xdrMemo =
        _mMemo == null ? XdrMemo(XdrMemoType.MEMO_NONE) : _mMemo!.toXdr();

    return XdrTransactionV0(
        sourcePublickKey.getEd25519()!,
        fee,
        XdrSequenceNumber(sequenceNumberUint),
        xdrTimeBounds,
        xdrMemo,
        operations,
        XdrTransactionV0Ext(0));
  }

  String toXdrBase64() {
    XdrTransaction xdr = this.toXdr();
    XdrDataOutputStream xdrOutputStream = XdrDataOutputStream();
    XdrTransaction.encode(xdrOutputStream, xdr);
    return base64Encode(xdrOutputStream.bytes);
  }

  /// Converts this transaction to its XDR representation.
  ///
  /// Generates a V1 Transaction XDR object that can be serialized for network
  /// transmission. The XDR (External Data Representation) format is the binary
  /// encoding used by the Stellar protocol.
  ///
  /// This method includes all transaction components:
  /// - Source account
  /// - Fee
  /// - Sequence number
  /// - Operations
  /// - Memo
  /// - Preconditions
  /// - Soroban transaction data (if applicable)
  ///
  /// Returns: [XdrTransaction] representation of this transaction.
  ///
  /// See also:
  /// - [toEnvelopeXdrBase64] to get the signed envelope as base64
  /// - [toXdrBase64] to get just the transaction (without signatures) as base64
  XdrTransaction toXdr() {
    // fee
    XdrUint32 fee = XdrUint32(_mFee);

    // sequenceNumber
    XdrBigInt64 sequenceNumberUint = XdrBigInt64(_mSequenceNumber);

    // operations
    List<XdrOperation> operations = List<XdrOperation>.empty(
        growable: true); //[]..length = _mOperations.length;
    for (int i = 0; i < _mOperations.length; i++) {
      operations.add(_mOperations[i].toXdr());
    }

    // ext
    XdrTransactionExt ext = XdrTransactionExt(0);
    if (this._sorobanTransactionData != null) {
      ext = XdrTransactionExt(1);
      ext.sorobanTransactionData = this._sorobanTransactionData;
    }

    XdrPreconditions xdrPreconditions = (_mPreconditions == null
        ? XdrPreconditions(XdrPreconditionType.NONE)
        : _mPreconditions!.toXdr());
    XdrMemo xdrMemo =
        (_mMemo == null ? XdrMemo(XdrMemoType.MEMO_NONE) : _mMemo!.toXdr());
    return XdrTransaction(
        _mSourceAccount.toXdr(),
        fee,
        XdrSequenceNumber(sequenceNumberUint),
        xdrPreconditions,
        xdrMemo,
        operations,
        ext);
  }

  /// Creates a [Transaction] instance from a XdrTransactionV1Envelope [envelope].
  static Transaction fromV1EnvelopeXdr(XdrTransactionV1Envelope envelope) {
    XdrTransaction? tx = envelope.tx;
    int mFee = tx.fee.uint32;

    BigInt mSequenceNumber = tx.seqNum.sequenceNumber.bigInt;
    Memo? mMemo = Memo.fromXdr(tx.memo);
    TransactionPreconditions mPreconditions =
        TransactionPreconditions.fromXdr(tx.preconditions);

    List<Operation> mOperations = List<Operation>.empty(growable: true);
    for (int i = 0; i < tx.operations.length; i++) {
      mOperations.add(Operation.fromXdr(tx.operations[i]));
    }

    Transaction transaction = Transaction(
        MuxedAccount.fromXdr(tx.sourceAccount),
        mFee,
        mSequenceNumber,
        mOperations,
        mMemo,
        mPreconditions,
        sorobanTransactionData: tx.ext.sorobanTransactionData);

    for (XdrDecoratedSignature? signature in envelope.signatures) {
      if (signature != null) {
        transaction._mSignatures.add(signature);
      }
    }

    return transaction;
  }

  /// Creates a [Transaction] instance from a XdrTransactionV0Envelope [envelope].
  static Transaction fromV0EnvelopeXdr(XdrTransactionV0Envelope envelope) {
    XdrTransactionV0? tx = envelope.tx;
    int? mFee = tx.fee.uint32;
    String mSourceAccount =
        KeyPair.fromPublicKey(tx.sourceAccountEd25519.uint256).accountId;
    BigInt mSequenceNumber = tx.seqNum.sequenceNumber.bigInt;
    Memo mMemo = Memo.fromXdr(tx.memo);
    TimeBounds? mTimeBounds;
    if (tx.timeBounds != null) {
      mTimeBounds = TimeBounds.fromXdr(tx.timeBounds!);
    }

    List<Operation> mOperations = List<Operation>.empty(growable: true);
    for (int i = 0; i < tx.operations.length; i++) {
      mOperations.add(Operation.fromXdr(tx.operations[i]));
    }
    MuxedAccount muxSource = MuxedAccount.fromAccountId(mSourceAccount)!;
    TransactionPreconditions preconditions = TransactionPreconditions();
    preconditions.timeBounds = mTimeBounds;
    Transaction transaction = Transaction(
        muxSource, mFee, mSequenceNumber, mOperations, mMemo, preconditions);

    for (XdrDecoratedSignature? signature in envelope.signatures) {
      if (signature != null) {
        transaction._mSignatures.add(signature);
      }
    }

    return transaction;
  }

  /// Generates a TransactionEnvelope XDR object for this transaction.
  /// This transaction needs to have at least one signature.
  XdrTransactionEnvelope toEnvelopeXdr() {
    XdrTransactionEnvelope xdrTe =
        XdrTransactionEnvelope(XdrEnvelopeType.ENVELOPE_TYPE_TX);
    XdrTransaction transaction = this.toXdr();

    List<XdrDecoratedSignature> signatures =
        List<XdrDecoratedSignature>.empty(growable: true);
    signatures.addAll(_mSignatures);
    XdrTransactionV1Envelope v1Envelope =
        XdrTransactionV1Envelope(transaction, signatures);
    xdrTe.v1 = v1Envelope;
    return xdrTe;
  }

  /// Builds a new TransactionBuilder object.
  static TransactionBuilder builder(TransactionBuilderAccount sourceAccount) {
    return TransactionBuilder(sourceAccount);
  }

  /// Sets Soroban authorization entries for invoke contract operations.
  ///
  /// This method applies the provided authorization entries to all
  /// [InvokeHostFunctionOperation] instances in the transaction. Used for
  /// Soroban smart contract invocations that require authorization.
  ///
  /// Parameters:
  /// - [auth]: List of authorization entries, or null to clear all authorizations
  ///
  /// Example:
  /// ```dart
  /// List<SorobanAuthorizationEntry> authEntries = [
  ///   SorobanAuthorizationEntry(...)
  /// ];
  /// transaction.setSorobanAuth(authEntries);
  /// ```
  ///
  /// See also:
  /// - [InvokeHostFunctionOperation] for Soroban contract invocations
  /// - [SorobanAuthorizationEntry] for authorization data
  setSorobanAuth(List<SorobanAuthorizationEntry>? auth) {
    List<SorobanAuthorizationEntry> auth2Set =
        List<SorobanAuthorizationEntry>.empty(growable: true);
    if (auth != null) {
      auth2Set = auth;
    }
    for (Operation op in operations) {
      if (op is InvokeHostFunctionOperation) {
        op.auth = auth2Set;
      }
    }
  }
}

/// Builder class for constructing Stellar transactions.
///
/// TransactionBuilder provides a fluent interface for creating transactions with
/// operations, memos, preconditions, and fees. The builder pattern ensures that
/// transactions are constructed correctly with all required components.
///
/// The builder automatically manages:
/// - Sequence number incrementation
/// - Fee calculation based on operation count
/// - Transaction assembly and validation
///
/// Example:
/// ```dart
/// // Basic transaction with payment
/// Transaction tx = TransactionBuilder(sourceAccount)
///   .addOperation(paymentOperation)
///   .addMemo(Memo.text("Payment"))
///   .build();
///
/// // Transaction with multiple operations and preconditions
/// Transaction tx = TransactionBuilder(sourceAccount)
///   .addOperation(operation1)
///   .addOperation(operation2)
///   .setMaxOperationFee(1000)
///   .addPreconditions(
///     TransactionPreconditions()
///       ..timeBounds = TimeBounds(0, deadline)
///   )
///   .build();
/// ```
///
/// See also:
/// - [Transaction] for the resulting transaction object
/// - [Operation] for available operations
/// - [TransactionPreconditions] for advanced preconditions
class TransactionBuilder {
  TransactionBuilderAccount _mSourceAccount;
  Memo? _mMemo;
  late List<Operation> _mOperations;
  int? _mMaxOperationFee;
  TransactionPreconditions? _mPreconditions;
  int get operationsCount => _mOperations.length;

  /// Construct a transaction builder.
  TransactionBuilder(this._mSourceAccount) {
    _mOperations = [];
  }

  /// Adds an operation to this transaction.
  ///
  /// See [Operation] for available operation types and
  /// [Stellar Operations](https://developers.stellar.org/docs/learn/fundamentals/transactions/operations)
  /// for details.
  TransactionBuilder addOperation(Operation operation) {
    _mOperations.add(operation);
    return this;
  }

  /// Adds a memo to this transaction.
  ///
  /// A memo is optional metadata attached to the transaction. See [Memo] for
  /// available memo types and [Stellar Memos](https://developers.stellar.org/docs/learn/encyclopedia/transactions-specialized/memo)
  /// for details.
  TransactionBuilder addMemo(Memo memo) {
    if (_mMemo != null) {
      throw Exception("Memo has been already added.");
    }
    _mMemo = memo;
    return this;
  }

  TransactionBuilder addPreconditions(TransactionPreconditions preconditions) {
    _mPreconditions = preconditions;
    return this;
  }

  /// Adds time-bounds to this transaction.
  ///
  /// Deprecated: This method will be removed in upcoming releases. Use [addPreconditions]
  /// instead for more control over transaction preconditions.
  ///
  /// See [Stellar Time Bounds](https://developers.stellar.org/docs/learn/encyclopedia/transactions-specialized/transaction-preconditions)
  /// for details.
  @Deprecated('Use [addPreconditions()]')
  TransactionBuilder addTimeBounds(TimeBounds timeBounds) {
    if (_mPreconditions?.timeBounds != null) {
      throw Exception("TimeBounds already set.");
    }
    _mPreconditions = TransactionPreconditions();
    _mPreconditions!.timeBounds = timeBounds;
    return this;
  }

  TransactionBuilder setMaxOperationFee(int maxOperationFee) {
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
    List<Operation> operations = [];
    operations.addAll(_mOperations);
    Transaction transaction = Transaction(
        _mSourceAccount.muxedAccount,
        operations.length * _mMaxOperationFee!,
        _mSourceAccount.incrementedSequenceNumber,
        operations,
        _mMemo,
        _mPreconditions);
    // Increment sequence number when there were no exceptions when creating a transaction
    _mSourceAccount.incrementSequenceNumber();
    return transaction;
  }
}

/// Represents [Fee Bump Transaction](https://github.com/stellar/stellar-protocol/blob/master/core/cap-0015.md) in Stellar network.
/// A fee bump transaction that wraps an existing transaction with a higher fee.
///
/// Fee bump transactions (introduced in CAP-15) allow anyone to increase the
/// fee of a transaction without requiring the original signer. This enables:
/// - Transaction sponsors paying fees for others
/// - Fee bumping for stuck transactions
/// - Third-party fee services
///
/// Structure:
/// - Wraps a complete inner transaction
/// - Specifies a new fee account (fee source)
/// - Sets a higher total fee
/// - Has its own signatures (separate from inner transaction)
///
/// Fee requirements:
/// - Fee must be >= inner transaction fee
/// - Fee must be >= MIN_BASE_FEE * (inner operations + 1)
/// - Fee account must have sufficient balance
///
/// Protocol specification:
/// - [CAP-15](https://github.com/stellar/stellar-protocol/blob/master/core/cap-0015.md)
///
/// Example:
/// ```dart
/// // Original transaction (already signed)
/// Transaction originalTx = TransactionBuilder(sourceAccount)
///   .addOperation(paymentOp)
///   .build();
/// originalTx.sign(sourceKeyPair, Network.TESTNET);
///
/// // Create fee bump transaction
/// FeeBumpTransaction feeBumpTx = FeeBumpTransactionBuilder(originalTx)
///   .setBaseFee(200)
///   .setFeeAccount(sponsorAccountId)
///   .build();
///
/// // Sign with fee account
/// feeBumpTx.sign(sponsorKeyPair, Network.TESTNET);
///
/// // Submit the fee bump transaction
/// SubmitTransactionResponse response = await sdk.submitTransaction(feeBumpTx);
/// ```
///
/// Important notes:
/// - Inner transaction must be a v1 envelope
/// - Inner transaction must already be signed
/// - Fee bump transaction requires separate signature from fee account
/// - If submitted, both transactions execute atomically
///
/// See also:
/// - [FeeBumpTransactionBuilder] for constructing fee bump transactions
/// - [Transaction] for the inner transaction type
/// - [MuxedAccount] for fee account specification
class FeeBumpTransaction extends AbstractTransaction {
  int _mFee;
  MuxedAccount _mFeeAccount;
  Transaction _mInner;

  /// Gets the total fee for this fee bump transaction.
  int get fee => this._mFee;

  /// Gets the account paying the fee.
  MuxedAccount get feeAccount => this._mFeeAccount;

  /// Gets the wrapped inner transaction.
  Transaction get innerTransaction => this._mInner;

  /// Creates a fee bump transaction.
  ///
  /// Parameters:
  /// - [_mFeeAccount]: The account paying the bumped fee
  /// - [_mFee]: The total fee in stroops
  /// - [_mInner]: The inner transaction being fee-bumped
  FeeBumpTransaction(this._mFeeAccount, this._mFee, this._mInner) : super();

  static FeeBumpTransaction fromFeeBumpTransactionEnvelope(
      XdrFeeBumpTransactionEnvelope envelope) {
    Transaction inner = Transaction.fromV1EnvelopeXdr(envelope.tx.innerTx.v1!);
    int fee = envelope.tx.fee.int64;
    FeeBumpTransaction feeBump = FeeBumpTransaction(
        MuxedAccount.fromXdr(envelope.tx.feeSource), fee, inner);
    return feeBump;
  }

  /// Returns signature base of this transaction.
  Uint8List signatureBase(Network network) {
    XdrDataOutputStream xdrOutputStream = XdrDataOutputStream();
    // Hashed NetworkID
    xdrOutputStream.write(network.networkId!);
    // Envelope Type - 4 bytes
    List<int> typeTx = List<int>.filled(4, 0);
    typeTx[3] = XdrEnvelopeType.ENVELOPE_TYPE_TX_FEE_BUMP.value;
    xdrOutputStream.write(typeTx);
    // Transaction XDR bytes
    XdrFeeBumpTransaction.encode(xdrOutputStream, this.toXdr());

    return Uint8List.fromList(xdrOutputStream.bytes);
  }

  String toXdrBase64() {
    XdrFeeBumpTransaction xdr = this.toXdr();
    XdrDataOutputStream xdrOutputStream = XdrDataOutputStream();
    XdrFeeBumpTransaction.encode(xdrOutputStream, xdr);
    return base64Encode(xdrOutputStream.bytes);
  }

  /// Generates a Fee Bump Transaction XDR object for this fee bump transaction.
  XdrFeeBumpTransaction toXdr() {
    XdrInt64 xdrFee = new XdrInt64(_mFee);

    XdrFeeBumpTransactionInnerTx innerXDR =
        XdrFeeBumpTransactionInnerTx(XdrEnvelopeType.ENVELOPE_TYPE_TX);
    innerXDR.v1 = _mInner.toEnvelopeXdr().v1;

    return XdrFeeBumpTransaction(
        _mFeeAccount.toXdr(), xdrFee, innerXDR, XdrFeeBumpTransactionExt(0));
  }

  /// Generates a TransactionEnvelope XDR object for this transaction.
  XdrTransactionEnvelope toEnvelopeXdr() {
    XdrTransactionEnvelope xdr =
        XdrTransactionEnvelope(XdrEnvelopeType.ENVELOPE_TYPE_TX_FEE_BUMP);

    List<XdrDecoratedSignature> signatures =
        List<XdrDecoratedSignature>.empty(growable: true);
    signatures.addAll(_mSignatures);

    xdr.feeBump = XdrFeeBumpTransactionEnvelope(this.toXdr(), signatures);

    return xdr;
  }

  /// Builds a new FeeBumpTransactionBuilder object.
  static FeeBumpTransactionBuilder builder(
    Transaction innerTransaction,
  ) {
    return FeeBumpTransactionBuilder(innerTransaction);
  }
}

/// Builder for creating fee bump transactions.
///
/// Provides a fluent interface for constructing [FeeBumpTransaction] instances
/// that wrap existing transactions with higher fees.
///
/// Required steps:
/// 1. Create builder with inner transaction
/// 2. Set base fee (per operation)
/// 3. Set fee account (who pays)
/// 4. Build the transaction
/// 5. Sign with fee account
///
/// Example:
/// ```dart
/// // Create inner transaction
/// Transaction innerTx = TransactionBuilder(sourceAccount)
///   .addOperation(paymentOp)
///   .build();
/// innerTx.sign(sourceKeyPair, Network.TESTNET);
///
/// // Build fee bump transaction
/// FeeBumpTransaction feeBumpTx = FeeBumpTransactionBuilder(innerTx)
///   .setBaseFee(200) // 200 stroops per operation
///   .setFeeAccount(sponsorAccountId)
///   .build();
///
/// // Sign with fee account
/// feeBumpTx.sign(sponsorKeyPair, Network.TESTNET);
/// ```
///
/// See also:
/// - [FeeBumpTransaction] for the resulting transaction type
/// - [TransactionBuilder] for building inner transactions
class FeeBumpTransactionBuilder {
  late Transaction _mInner;
  int? _mBaseFee;
  MuxedAccount? _mFeeAccount;

  /// Constructs a new fee bump transaction builder.
  ///
  /// The inner transaction will be automatically upgraded to v1 envelope
  /// format if it's in v0 format.
  ///
  /// Parameters:
  /// - [inner]: The transaction to wrap with a fee bump
  ///
  /// Example:
  /// ```dart
  /// FeeBumpTransactionBuilder builder = FeeBumpTransactionBuilder(innerTx);
  /// ```
  FeeBumpTransactionBuilder(Transaction inner) {
    if (inner.toEnvelopeXdr().discriminant ==
        XdrEnvelopeType.ENVELOPE_TYPE_TX_V0) {
      _mInner = new Transaction(
          inner.sourceAccount,
          inner.fee,
          inner.sequenceNumber,
          inner.operations,
          inner.memo,
          inner.preconditions);
      _mInner._mSignatures = inner.signatures;
    } else {
      _mInner = inner;
    }
  }

  /// Sets the base fee per operation in stroops.
  ///
  /// The total fee is calculated as: baseFee * (operations + 1)
  /// The +1 accounts for the fee bump operation itself.
  ///
  /// Parameters:
  /// - [baseFee]: Fee per operation in stroops (minimum 100)
  ///
  /// Returns: This builder for method chaining
  ///
  /// Throws:
  /// - [Exception]: If base fee already set
  /// - [Exception]: If base fee < MIN_BASE_FEE (100)
  /// - [Exception]: If base fee < inner transaction's base fee
  /// - [Exception]: If total fee would overflow 64-bit integer
  ///
  /// Example:
  /// ```dart
  /// builder.setBaseFee(200); // 200 stroops per operation
  /// ```
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

  /// Sets the account that will pay the bumped fee.
  ///
  /// This account will be charged the fee and must sign the fee bump transaction.
  /// Can be different from the inner transaction's source account.
  ///
  /// Parameters:
  /// - [feeAccount]: The account ID (G... or M... address)
  ///
  /// Returns: This builder for method chaining
  ///
  /// Throws:
  /// - [Exception]: If fee account already set
  ///
  /// Example:
  /// ```dart
  /// builder.setFeeAccount("GDJK...");
  /// ```
  FeeBumpTransactionBuilder setFeeAccount(String feeAccount) {
    if (_mFeeAccount != null) {
      throw new Exception("fee account has been already been set.");
    }
    _mFeeAccount = MuxedAccount.fromAccountId(feeAccount);
    return this;
  }

  /// Sets the muxed account that will pay the bumped fee.
  ///
  /// Alternative to [setFeeAccount] when using multiplexed accounts.
  ///
  /// Parameters:
  /// - [feeAccount]: The [MuxedAccount] instance
  ///
  /// Returns: This builder for method chaining
  ///
  /// Throws:
  /// - [Exception]: If fee account already set
  ///
  /// Example:
  /// ```dart
  /// MuxedAccount muxed = MuxedAccount(accountId, 123);
  /// builder.setMuxedFeeAccount(muxed);
  /// ```
  FeeBumpTransactionBuilder setMuxedFeeAccount(MuxedAccount feeAccount) {
    if (_mFeeAccount != null) {
      throw new Exception("fee account has been already been set.");
    }
    _mFeeAccount = feeAccount;
    return this;
  }

  /// Builds the fee bump transaction.
  ///
  /// Creates the [FeeBumpTransaction] with all specified parameters.
  /// Both base fee and fee account must be set before building.
  ///
  /// Returns: The constructed [FeeBumpTransaction]
  ///
  /// Throws:
  /// - [Exception]: If base fee not set
  /// - [Exception]: If fee account not set
  ///
  /// Example:
  /// ```dart
  /// FeeBumpTransaction feeBumpTx = builder
  ///   .setBaseFee(200)
  ///   .setFeeAccount(sponsorId)
  ///   .build();
  /// ```
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
  late int _mMinTime;
  late int _mMaxTime;

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
    return TimeBounds(timeBounds.minTime.uint64, timeBounds.maxTime.uint64);
  }

  /// Creates a [XdrTimeBounds] object from this time bounds.
  XdrTimeBounds toXdr() {
    XdrUint64 minTime = XdrUint64(_mMinTime);
    XdrUint64 maxTime = XdrUint64(_mMaxTime);
    XdrTimeBounds timeBounds = XdrTimeBounds(minTime, maxTime);
    return timeBounds;
  }

  @override
  bool operator ==(Object o) {
    if (this == o) {
      return true;
    }

    if (!(o is TimeBounds)) {
      return false;
    }

    if (_mMinTime != o.minTime) return false;
    return _mMaxTime == o.maxTime;
  }
}

/// LedgerBounds are Preconditions of a transaction per [CAP-21](https://github.com/stellar/stellar-protocol/blob/master/core/cap-0021.md#specification)
class LedgerBounds {
  int _minLedger;
  int _maxLedger;

  /// Constructor [_minLedger] and [_maxLedger] are 64bit Unix timestamps.
  LedgerBounds(this._minLedger, this._maxLedger) {
    if (_minLedger < 0) {
      throw Exception("minLdeger cannot be negative");
    }

    if (_maxLedger < 0) {
      throw new Exception("maxLedger cannot be negative");
    }
    if (_maxLedger != 0 && _minLedger >= _maxLedger) {
      throw Exception("minLedger must be >= maxLedger");
    }
  }

  int get minLedger => _minLedger;
  int get maxLedger => _maxLedger;

  /// Creates a [LedgerBounds] instance from a [ledgerBounds] XdrLedgerBounds object.
  static LedgerBounds? fromXdr(XdrLedgerBounds ledgerBounds) {
    return LedgerBounds(
        ledgerBounds.minLedger.uint32, ledgerBounds.maxLedger.uint32);
  }

  /// Creates a [XdrLedgerBounds] object from this ledger bounds.
  XdrLedgerBounds toXdr() {
    XdrUint32 minLedger = XdrUint32(_minLedger);
    XdrUint32 maxLedger = XdrUint32(_maxLedger);
    return XdrLedgerBounds(minLedger, maxLedger);
  }

  @override
  bool operator ==(Object o) {
    if (this == o) {
      return true;
    }

    if (!(o is LedgerBounds)) {
      return false;
    }

    LedgerBounds that = o;

    if (_minLedger != that.minLedger) return false;
    return _maxLedger == that.maxLedger;
  }
}

/// Transaction preconditions for advanced transaction control.
///
/// Introduced in CAP-21, preconditions allow transactions to specify additional
/// validity constraints beyond the basic sequence number. This enables:
/// - Time-based transaction validity windows
/// - Ledger-based transaction validity windows
/// - Minimum sequence number requirements
/// - Sequence age and gap requirements
/// - Additional required signers
///
/// Precondition types:
/// - [timeBounds]: Time range for transaction validity
/// - [ledgerBounds]: Ledger range for transaction validity
/// - [minSeqNumber]: Minimum source account sequence number
/// - [minSeqAge]: Minimum age of source account sequence number (seconds)
/// - [minSeqLedgerGap]: Minimum ledger gap since sequence number changed
/// - [extraSigners]: Additional required signers (up to 2)
///
/// Use cases:
/// - Scheduled transactions with time windows
/// - Smart contract interactions with timing requirements
/// - Multi-signature workflows with specific signer requirements
/// - Transaction batching with sequence guarantees
///
/// Protocol specification:
/// - [CAP-21](https://github.com/stellar/stellar-protocol/blob/master/core/cap-0021.md)
///
/// Example:
/// ```dart
/// // Time-bounded transaction (valid for 5 minutes)
/// TransactionPreconditions preconditions = TransactionPreconditions();
/// preconditions.timeBounds = TimeBounds(
///   DateTime.now(),
///   DateTime.now().add(Duration(minutes: 5))
/// );
///
/// // Ledger-bounded transaction
/// preconditions.ledgerBounds = LedgerBounds(1000, 1100);
///
/// // Require minimum sequence number
/// preconditions.minSeqNumber = BigInt.from(123456);
///
/// // Require sequence age of at least 1 hour
/// preconditions.minSeqAge = 3600;
///
/// // Require ledger gap of at least 10 ledgers
/// preconditions.minSeqLedgerGap = 10;
///
/// // Build transaction with preconditions
/// Transaction tx = TransactionBuilder(sourceAccount)
///   .addOperation(operation)
///   .setPreconditions(preconditions)
///   .build();
/// ```
///
/// See also:
/// - [TimeBounds] for time-based constraints
/// - [LedgerBounds] for ledger-based constraints
/// - [TransactionBuilder] for building transactions with preconditions
class TransactionPreconditions {
  /// Maximum number of extra signers that can be required.
  static const MAX_EXTRA_SIGNERS_COUNT = 2;

  /// Value indicating infinite timeout (no time bounds).
  static const TIMEOUT_INFINITE = 0;

  TimeBounds? _timeBounds;
  LedgerBounds? _ledgerBounds;
  BigInt? _minSeqNumber;
  int? _minSeqAge;
  int? _minSeqLedgerGap;
  List<XdrSignerKey>? _extraSigners;

  /// Gets the time bounds for transaction validity.
  ///
  /// Returns: [TimeBounds] or null if not set
  TimeBounds? get timeBounds => _timeBounds;

  /// Gets the ledger bounds for transaction validity.
  ///
  /// Returns: [LedgerBounds] or null if not set
  LedgerBounds? get ledgerBounds => _ledgerBounds;

  /// Gets the minimum sequence number required for the source account.
  ///
  /// Returns: Minimum sequence number or null if not set
  BigInt? get minSeqNumber => _minSeqNumber;

  /// Gets the minimum age in seconds for the source account's sequence number.
  ///
  /// Returns: Minimum age in seconds or null if not set
  int? get minSeqAge => _minSeqAge;

  /// Gets the minimum ledger gap since the sequence number last changed.
  ///
  /// Returns: Minimum ledger gap or null if not set
  int? get minSeqLedgerGap => _minSeqLedgerGap;

  /// Gets the list of additional required signers.
  ///
  /// Returns: List of signer keys (max 2) or null if not set
  List<XdrSignerKey>? get extraSigners => _extraSigners;

  set timeBounds(TimeBounds? value) => _timeBounds = value;
  set ledgerBounds(LedgerBounds? value) => _ledgerBounds = value;
  set minSeqNumber(BigInt? value) => _minSeqNumber = value;
  set minSeqAge(int? value) => _minSeqAge = value;
  set minSeqLedgerGap(int? value) => _minSeqLedgerGap = value;
  set extraSigners(List<XdrSignerKey>? value) => _extraSigners = value;

  static TransactionPreconditions fromXdr(XdrPreconditions xdr) {
    TransactionPreconditions result = TransactionPreconditions();
    if (xdr.discriminant.value == XdrPreconditionType.V2.value) {
      if (xdr.v2!.timeBounds != null) {
        result.timeBounds = TimeBounds.fromXdr(xdr.v2!.timeBounds!);
      }
      if (xdr.v2!.ledgerBounds != null) {
        result.ledgerBounds = LedgerBounds.fromXdr(xdr.v2!.ledgerBounds!);
      }
      if (xdr.v2!.sequenceNumber != null) {
        result.minSeqNumber = xdr.v2!.sequenceNumber!.bigInt;
      }
      result.minSeqAge = xdr.v2!.minSeqAge.uint64;
      result.minSeqLedgerGap = xdr.v2!.minSeqLedgerGap.uint32;
      List<XdrSignerKey> keys = [];
      for (var i = 0; i < xdr.v2!.extraSigners.length; i++) {
        keys.add(xdr.v2!.extraSigners[i]);
      }
      result.extraSigners = keys;
    } else {
      if (xdr.timeBounds != null) {
        result.timeBounds = TimeBounds.fromXdr(xdr.timeBounds!);
      }
    }
    return result;
  }

  bool hasV2() {
    return _ledgerBounds != null ||
        (_minSeqLedgerGap != null && _minSeqLedgerGap! > 0) ||
        (_minSeqAge != null && _minSeqAge! > 0) ||
        (_minSeqNumber != null && _minSeqNumber! > BigInt.zero) ||
        (_extraSigners != null && _extraSigners!.length > 0);
  }

  XdrPreconditions toXdr() {
    XdrPreconditionType type = XdrPreconditionType.NONE;
    if (hasV2()) {
      type = XdrPreconditionType.V2;
    } else if (_timeBounds != null) {
      type = XdrPreconditionType.TIME;
    }
    XdrPreconditions result = XdrPreconditions(type);
    if (hasV2()) {
      int sav = 0;
      if (_minSeqAge != null) {
        sav = _minSeqAge!;
      }
      XdrUint64 sa = XdrUint64(sav);

      int slv = 0;
      if (_minSeqLedgerGap != null) {
        slv = _minSeqLedgerGap!;
      }
      XdrUint32 sl = XdrUint32(slv);

      List<XdrSignerKey> es = [];
      if (_extraSigners != null) {
        es = _extraSigners!;
      }

      XdrPreconditionsV2 v2 = XdrPreconditionsV2(sa, sl, es);

      if (_minSeqNumber != null) {
        XdrBigInt64 sn = XdrBigInt64(_minSeqNumber!);
        v2.sequenceNumber = sn;
      }

      if (_timeBounds != null) {
        v2.timeBounds = _timeBounds!.toXdr();
      }

      if (_ledgerBounds != null) {
        v2.ledgerBounds = _ledgerBounds!.toXdr();
      }

      result.v2 = v2;
    } else if (_timeBounds != null) {
      result.timeBounds = _timeBounds!.toXdr();
    }
    return result;
  }
}
