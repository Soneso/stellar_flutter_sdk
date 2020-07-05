// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import '../memo.dart';
import 'response.dart';
import '../util.dart';

/// Represents transaction response received from the horizon server
/// See: <a href="https://developers.stellar.org/api/resources/transactions/" target="_blank">Transaction documentation</a>.
class TransactionResponse extends Response {
  String hash;
  int ledger;
  String createdAt;
  String sourceAccount;
  String feeAccount;
  bool successful;
  String pagingToken;
  int sourceAccountSequence;
  int maxFee;
  int feeCharged;
  int operationCount;
  String envelopeXdr;
  String resultXdr;
  String resultMetaXdr;
  Memo _memo;
  List<String> signatures;
  FeeBumpTransactionResponse feeBumpTransaction;
  InnerTransaction innerTransaction;
  TransactionResponseLinks links;

  TransactionResponse(
      this.hash,
      this.ledger,
      this.createdAt,
      this.sourceAccount,
      this.feeAccount,
      this.successful,
      this.pagingToken,
      this.sourceAccountSequence,
      this.maxFee,
      this.feeCharged,
      this.operationCount,
      this.envelopeXdr,
      this.resultXdr,
      this.resultMetaXdr,
      this._memo,
      this.signatures,
      this.feeBumpTransaction,
      this.innerTransaction,
      this.links);

  Memo get memo => _memo;
  set memo(Memo memo) {
    memo = checkNotNull(memo, "memo cannot be null");
    if (this._memo != null) {
      throw new Exception("Memo has been already set.");
    }
    this._memo = memo;
  }

  factory TransactionResponse.fromJson(Map<String, dynamic> json) {
    var signaturesFromJson = json['signatures'];
    List<String> signaturesList = new List<String>.from(signaturesFromJson);

    return new TransactionResponse(
        json['hash'] as String,
        convertInt(json['ledger']),
        json['created_at'] as String,
        json['source_account'] as String,
        json['fee_account'] as String,
        json['successful'] as bool,
        json['paging_token'] as String,
        convertInt(json['source_account_sequence']),
        convertInt(json['max_fee']),
        convertInt(json['fee_charged']),
        convertInt(json['operation_count']),
        json['envelope_xdr'] as String,
        json['result_xdr'] as String,
        json['result_meta_xdr'] as String,
        Memo.fromJson(json),
        signaturesList,
        json['fee_bump_transaction'] == null
            ? null
            : new FeeBumpTransactionResponse.fromJson(
                json['fee_bump_transaction'] as Map<String, dynamic>),
        json['inner_transaction'] == null
            ? null
            : new InnerTransaction.fromJson(
                json['inner_transaction'] as Map<String, dynamic>),
        json['_links'] == null
            ? null
            : new TransactionResponseLinks.fromJson(
                json['_links'] as Map<String, dynamic>));
  }
}

/// FeeBumpTransaction is only present in a TransactionResponse if the transaction is a fee bump transaction or is
/// wrapped by a fee bump transaction. The object has two fields: the hash of the fee bump transaction and the
/// signatures present in the fee bump transaction envelope.
class FeeBumpTransactionResponse {
  String hash;
  List<String> signatures;

  /// Constructor creates a FeeBumpTransaction object from [hash] and [signatures].
  FeeBumpTransactionResponse(this.hash, this.signatures);

  factory FeeBumpTransactionResponse.fromJson(Map<String, dynamic> json) {
    var signaturesFromJson = json['signatures'];
    List<String> signaturesList = new List<String>.from(signaturesFromJson);
    return new FeeBumpTransactionResponse(
        json['hash'] as String, signaturesList);
  }
}

/// InnerTransaction is only present in a TransactionResponse if the transaction is a fee bump transaction or is
/// wrapped by a fee bump transaction. The object has three fields: the hash of the inner transaction wrapped by the
/// fee bump transaction, the max fee set in the inner transaction, and the signatures present in the inner
/// transaction envelope.
class InnerTransaction {
  String hash;
  List<String> signatures;
  int maxFee;

  /// Constructor creates a InnerTransaction object from [hash], [signatures] and [maxFee].
  InnerTransaction(this.hash, this.signatures, this.maxFee);

  factory InnerTransaction.fromJson(Map<String, dynamic> json) {
    var signaturesFromJson = json['signatures'];
    List<String> signaturesList = new List<String>.from(signaturesFromJson);
    return new InnerTransaction(
        json['hash'] as String, signaturesList, convertInt(json['max_fee']));
  }
}

/// Links connected to a transaction response.
class TransactionResponseLinks {
  Link account;
  Link effects;
  Link ledger;
  Link operations;
  Link precedes;
  Link self;
  Link succeeds;

  TransactionResponseLinks(this.account, this.effects, this.ledger,
      this.operations, this.precedes, this.self, this.succeeds);

  factory TransactionResponseLinks.fromJson(Map<String, dynamic> json) =>
      new TransactionResponseLinks(
          json['account'] == null
              ? null
              : new Link.fromJson(json['account'] as Map<String, dynamic>),
          json['effects'] == null
              ? null
              : new Link.fromJson(json['effects'] as Map<String, dynamic>),
          json['ledger'] == null
              ? null
              : new Link.fromJson(json['ledger'] as Map<String, dynamic>),
          json['operations'] == null
              ? null
              : new Link.fromJson(json['operations'] as Map<String, dynamic>),
          json['precedes'] == null
              ? null
              : new Link.fromJson(json['precedes'] as Map<String, dynamic>),
          json['self'] == null
              ? null
              : new Link.fromJson(json['self'] as Map<String, dynamic>),
          json['succeeds'] == null
              ? null
              : new Link.fromJson(json['succeeds'] as Map<String, dynamic>));
}
