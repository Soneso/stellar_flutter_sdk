// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import '../memo.dart';
import 'response.dart';

/// Represents a confirmed transaction in the Stellar network.
///
/// TransactionResponse contains comprehensive information about a transaction
/// that has been applied to the ledger, including its operations, fees, memo,
/// signatures, and execution results.
///
/// Example:
/// ```dart
/// var tx = await sdk.transactions.transaction(txHash);
///
/// print('Transaction ID: ${tx.id}');
/// print('Ledger: ${tx.ledger}');
/// print('Source account: ${tx.sourceAccount}');
/// print('Success: ${tx.successful}');
/// print('Fee charged: ${tx.feeCharged}');
/// print('Operation count: ${tx.operationCount}');
///
/// if (tx.memo != null) {
///   print('Memo: ${tx.memo}');
/// }
///
/// // Check if it's a fee bump transaction
/// if (tx.feeBumpTransaction != null) {
///   print('Fee bump by: ${tx.feeBumpTransaction!.feeAccount}');
/// }
/// ```
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
/// - [Memo] for transaction memo types
class TransactionResponse extends Response {
  /// Unique identifier for this transaction (same as hash).
  String id;

  /// Transaction hash (hex-encoded).
  String hash;

  /// Ledger sequence number where this transaction was applied.
  int ledger;

  /// Timestamp when this transaction was created.
  String createdAt;

  /// Public key of the source account.
  String sourceAccount;

  /// Muxed address of the source account if applicable.
  String? sourceAccountMuxed;

  /// Muxed account ID if source is a muxed account.
  String? sourceAccountMuxedId;

  /// Account that paid the transaction fee.
  String feeAccount;

  /// Muxed address of the fee account if applicable.
  String? feeAccountMuxed;

  /// Muxed account ID if fee account is muxed.
  String? feeAccountMuxedId;

  /// Whether the transaction executed successfully.
  bool successful;

  /// Cursor value for pagination.
  String pagingToken;

  /// Sequence number used by the source account.
  int sourceAccountSequence;

  /// Maximum fee the source account was willing to pay (in stroops).
  int maxFee;

  /// Actual fee charged for this transaction (in stroops).
  int feeCharged;

  /// Number of operations in this transaction.
  int operationCount;

  /// Base64-encoded XDR of the transaction envelope.
  String envelopeXdr;

  /// Base64-encoded XDR of the transaction result.
  String resultXdr;

  /// Base64-encoded XDR of the transaction result metadata.
  String? resultMetaXdr;

  /// Base64-encoded XDR of the fee metadata.
  String feeMetaXdr;

  /// Memo attached to this transaction.
  Memo _memo;

  /// Base64-encoded memo bytes for hash memos.
  String? memoBytes;

  /// List of base64-encoded signatures.
  List<String> signatures;

  /// Fee bump transaction wrapper if this transaction was fee-bumped.
  FeeBumpTransactionResponse? feeBumpTransaction;

  /// Inner transaction details if this is a fee bump transaction.
  InnerTransaction? innerTransaction;

  /// Hypermedia links to related resources.
  TransactionResponseLinks links;

  /// Transaction preconditions (time bounds, ledger bounds, etc).
  TransactionPreconditionsResponse? preconditions;

  TransactionResponse(
      this.id,
      this.hash,
      this.ledger,
      this.createdAt,
      this.sourceAccount,
      this.sourceAccountMuxed,
      this.sourceAccountMuxedId,
      this.feeAccount,
      this.feeAccountMuxed,
      this.feeAccountMuxedId,
      this.successful,
      this.pagingToken,
      this.sourceAccountSequence,
      this.maxFee,
      this.feeCharged,
      this.operationCount,
      this.envelopeXdr,
      this.resultXdr,
      this.resultMetaXdr,
      this.feeMetaXdr,
      this._memo,
      this.memoBytes,
      this.signatures,
      this.feeBumpTransaction,
      this.innerTransaction,
      this.links,
      this.preconditions);

  Memo? get memo => _memo;

  factory TransactionResponse.fromJson(Map<String, dynamic> json) {
    var signaturesFromJson = json['signatures'];
    List<String> signaturesList = List<String>.from(signaturesFromJson);

    return TransactionResponse(
        json['id'],
        json['hash'],
        convertInt(json['ledger'])!,
        json['created_at'],
        json['source_account'],
        json['source_account_muxed'],
        json['source_account_muxed_id'],
        json['fee_account'],
        json['fee_account_muxed'],
        json['fee_account_muxed_id'],
        json['successful'],
        json['paging_token'],
        convertInt(json['source_account_sequence'])!,
        convertInt(json['max_fee'])!,
        convertInt(json['fee_charged'])!,
        convertInt(json['operation_count'])!,
        json['envelope_xdr'],
        json['result_xdr'],
        json['result_meta_xdr'],
        json['fee_meta_xdr'],
        Memo.fromJson(json),
        json['memo_bytes'],
        signaturesList,
        json['fee_bump_transaction'] == null
            ? null
            : FeeBumpTransactionResponse.fromJson(json['fee_bump_transaction']),
        json['inner_transaction'] == null
            ? null
            : InnerTransaction.fromJson(json['inner_transaction']),
        TransactionResponseLinks.fromJson(json['_links']),
        json['preconditions'] == null
            ? null
            : TransactionPreconditionsResponse.fromJson(json['preconditions']));
  }
}

/// Represents a fee bump transaction that wraps another transaction.
///
/// Fee bump transactions (CAP-15) allow anyone to pay the fee for an existing
/// transaction that has insufficient fees. This is useful for:
/// - Ensuring critical transactions get included when network fees spike
/// - Allowing third parties to sponsor transaction fees
/// - Rescuing transactions stuck in the queue with low fees
///
/// This object is only present when a transaction is a fee bump transaction
/// or is wrapped by one. It contains the hash and signatures of the outer
/// fee bump transaction envelope.
///
/// See also:
/// - [TransactionResponse] for the main transaction details
/// - [InnerTransaction] for the wrapped transaction
/// - [CAP-15 Fee Bump Transactions](https://github.com/stellar/stellar-protocol/blob/master/core/cap-0015.md)
class FeeBumpTransactionResponse {
  String hash;
  List<String> signatures;

  /// Constructor creates a FeeBumpTransaction object from [hash] and [signatures].
  FeeBumpTransactionResponse(this.hash, this.signatures);

  factory FeeBumpTransactionResponse.fromJson(Map<String, dynamic> json) {
    var signaturesFromJson = json['signatures'];
    List<String> signaturesList = List<String>.from(signaturesFromJson);
    return FeeBumpTransactionResponse(json['hash'], signaturesList);
  }
}

/// Represents the original transaction wrapped by a fee bump transaction.
///
/// When a transaction is wrapped by a fee bump transaction, this object
/// contains details about the original inner transaction including its hash,
/// signatures, and max fee. The outer fee bump transaction replaces the
/// inner transaction's fee but preserves its operations and signatures.
///
/// This object is only present when a transaction is wrapped by a fee bump
/// transaction. It provides access to the original transaction details that
/// were submitted before being wrapped.
///
/// See also:
/// - [TransactionResponse] for the main transaction details
/// - [FeeBumpTransactionResponse] for the wrapping transaction
class InnerTransaction {
  String hash;
  List<String> signatures;
  int maxFee;

  /// Constructor creates a InnerTransaction object from [hash], [signatures] and [maxFee].
  InnerTransaction(this.hash, this.signatures, this.maxFee);

  factory InnerTransaction.fromJson(Map<String, dynamic> json) {
    var signaturesFromJson = json['signatures'];
    List<String> signaturesList = List<String>.from(signaturesFromJson);
    return InnerTransaction(
        json['hash'], signaturesList, convertInt(json['max_fee'])!);
  }
}

/// Time bounds precondition for a transaction.
///
/// Specifies a time window during which the transaction is valid. The
/// transaction can only be included in a ledger if the ledger's close
/// time falls within this range.
///
/// See also:
/// - [TransactionPreconditionsResponse] for all precondition types
class PreconditionsTimeBoundsResponse {
  String? minTime;
  String? maxTime;

  PreconditionsTimeBoundsResponse(this.minTime, this.maxTime);

  factory PreconditionsTimeBoundsResponse.fromJson(Map<String, dynamic> json) {
    return PreconditionsTimeBoundsResponse(json['min_time'], json['max_time']);
  }
}

/// Ledger bounds precondition for a transaction.
///
/// Specifies a ledger sequence range during which the transaction is valid.
/// The transaction can only be included in a ledger whose sequence number
/// falls within this range. This is useful for preventing replay attacks
/// and ensuring transactions expire after a certain number of ledgers.
///
/// See also:
/// - [TransactionPreconditionsResponse] for all precondition types
class PreconditionsLedgerBoundsResponse {
  int minLedger;
  int? maxLedger;

  PreconditionsLedgerBoundsResponse(this.minLedger, this.maxLedger);

  factory PreconditionsLedgerBoundsResponse.fromJson(
      Map<String, dynamic> json) {
    return PreconditionsLedgerBoundsResponse(
        convertInt(json['min_ledger']) == null
            ? 0
            : convertInt(json['min_ledger'])!,
        json['max_ledger']);
  }
}

/// Transaction preconditions that must be satisfied for execution.
///
/// Preconditions (CAP-21) provide fine-grained control over when and how
/// a transaction can be executed. They enable use cases like:
/// - Time-bounded transactions that expire
/// - Transactions that require specific ledger sequences
/// - Coordinated multi-party transactions
/// - Additional signature requirements beyond account signers
///
/// Available precondition types:
/// - timeBounds: Time window for validity
/// - ledgerBounds: Ledger sequence range for validity
/// - minAccountSequence: Minimum source account sequence number
/// - minAccountSequenceAge: Minimum age of source account sequence
/// - minAccountSequenceLedgerGap: Minimum ledger gap since sequence change
/// - extraSigners: Additional required signatures beyond account signers
///
/// See also:
/// - [TransactionResponse] for the parent transaction details
/// - [PreconditionsTimeBoundsResponse] for time bounds structure
/// - [PreconditionsLedgerBoundsResponse] for ledger bounds structure
/// - [CAP-21 Preconditions](https://github.com/stellar/stellar-protocol/blob/master/core/cap-0021.md)
class TransactionPreconditionsResponse {
  PreconditionsTimeBoundsResponse? timeBounds;
  PreconditionsLedgerBoundsResponse? ledgerBounds;
  String? minAccountSequence;
  String? minAccountSequenceAge;
  int? minAccountSequenceLedgerGap;
  List<String>? extraSigners;

  TransactionPreconditionsResponse(
      this.timeBounds,
      this.ledgerBounds,
      this.minAccountSequence,
      this.minAccountSequenceAge,
      this.minAccountSequenceLedgerGap,
      this.extraSigners);

  factory TransactionPreconditionsResponse.fromJson(Map<String, dynamic> json) {
    var signersFromJson = json['extra_signers'];
    List<String> signersList = List<String>.empty(growable: false);
    if (signersFromJson != null) {
      signersList = List<String>.from(signersFromJson);
    }

    return TransactionPreconditionsResponse(
        json['timebounds'] == null
            ? null
            : PreconditionsTimeBoundsResponse.fromJson(json['timebounds']),
        json['ledgerbounds'] == null
            ? null
            : PreconditionsLedgerBoundsResponse.fromJson(json['ledgerbounds']),
        json['min_account_sequence'],
        json['min_account_sequence_age'],
        convertInt(json['min_account_sequence_ledger_gap']),
        signersList);
  }
}

/// HAL links for navigating related transaction resources.
///
/// Provides hypermedia links to related Horizon API endpoints for a transaction.
/// These links follow the HAL (Hypertext Application Language) standard and
/// enable navigation to:
/// - account: The source account that submitted this transaction
/// - effects: All effects produced by this transaction's operations
/// - ledger: The ledger that includes this transaction
/// - operations: All operations contained in this transaction
/// - precedes: The transaction that precedes this one in the ledger
/// - self: This transaction's details endpoint
/// - succeeds: The transaction that succeeds this one in the ledger
///
/// See also:
/// - [TransactionResponse] for the parent transaction details
/// - [Link] for link structure details
class TransactionResponseLinks {
  Link? account;
  Link? effects;
  Link? ledger;
  Link? operations;
  Link? precedes;
  Link? self;
  Link? succeeds;

  TransactionResponseLinks(this.account, this.effects, this.ledger,
      this.operations, this.precedes, this.self, this.succeeds);

  factory TransactionResponseLinks.fromJson(Map<String, dynamic> json) =>
      TransactionResponseLinks(
          json['account'] == null ? null : Link.fromJson(json['account']),
          json['effects'] == null ? null : Link.fromJson(json['effects']),
          json['ledger'] == null ? null : Link.fromJson(json['ledger']),
          json['operations'] == null ? null : Link.fromJson(json['operations']),
          json['precedes'] == null ? null : Link.fromJson(json['precedes']),
          json['self'] == null ? null : Link.fromJson(json['self']),
          json['succeeds'] == null ? null : Link.fromJson(json['succeeds']));
}
