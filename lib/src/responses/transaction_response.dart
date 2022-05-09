// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import '../memo.dart';
import 'response.dart';
import '../util.dart';

/// Represents transaction response received from the horizon server
/// See: <a href="https://developers.stellar.org/api/resources/transactions/" target="_blank">Transaction documentation</a>.
class TransactionResponse extends Response {
  String? hash;
  int? ledger;
  String? createdAt;
  String? sourceAccount;
  String? sourceAccountMuxed;
  String? sourceAccountMuxedId;
  String? feeAccount;
  String? feeAccountMuxed;
  String? feeAccountMuxedId;
  bool? successful;
  String? pagingToken;
  int? sourceAccountSequence;
  int? maxFee;
  int? feeCharged;
  int? operationCount;
  String? envelopeXdr;
  String? resultXdr;
  String? resultMetaXdr;
  Memo? _memo;
  List<String?>? signatures;
  FeeBumpTransactionResponse? feeBumpTransaction;
  InnerTransaction? innerTransaction;
  TransactionResponseLinks? links;
  TransactionPreconditionsResponse? preconditions;

  TransactionResponse(
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
      this._memo,
      this.signatures,
      this.feeBumpTransaction,
      this.innerTransaction,
      this.links,
      this.preconditions);

  Memo? get memo => _memo;

  set memo(Memo? memo) {
    memo = checkNotNull(memo, "memo cannot be null");
    if (this._memo != null) {
      throw Exception("Memo has been already set.");
    }
    this._memo = memo;
  }

  factory TransactionResponse.fromJson(Map<String, dynamic> json) {
    var signaturesFromJson = json['signatures'];
    List<String> signaturesList = List<String>.from(signaturesFromJson);

    return TransactionResponse(
        json['hash'],
        convertInt(json['ledger']),
        json['created_at'],
        json['source_account'],
        json['source_account_muxed'],
        json['source_account_muxed_id'],
        json['fee_account'],
        json['fee_account_muxed'],
        json['fee_account_muxed_id'],
        json['successful'],
        json['paging_token'],
        convertInt(json['source_account_sequence']),
        convertInt(json['max_fee']),
        convertInt(json['fee_charged']),
        convertInt(json['operation_count']),
        json['envelope_xdr'],
        json['result_xdr'],
        json['result_meta_xdr'],
        Memo.fromJson(json),
        signaturesList,
        json['fee_bump_transaction'] == null
            ? null
            : FeeBumpTransactionResponse.fromJson(json['fee_bump_transaction']),
        json['inner_transaction'] == null
            ? null
            : InnerTransaction.fromJson(json['inner_transaction']),
        json['_links'] == null
            ? null
            : TransactionResponseLinks.fromJson(json['_links']),
        json['preconditions'] == null
            ? null
            : TransactionPreconditionsResponse.fromJson(json['preconditions']));
  }
}

/// FeeBumpTransaction is only present in a TransactionResponse if the transaction is a fee bump transaction or is
/// wrapped by a fee bump transaction. The object has two fields: the hash of the fee bump transaction and the
/// signatures present in the fee bump transaction envelope.
class FeeBumpTransactionResponse {
  String? hash;
  List<String?>? signatures;

  /// Constructor creates a FeeBumpTransaction object from [hash] and [signatures].
  FeeBumpTransactionResponse(this.hash, this.signatures);

  factory FeeBumpTransactionResponse.fromJson(Map<String, dynamic> json) {
    var signaturesFromJson = json['signatures'];
    List<String> signaturesList = List<String>.from(signaturesFromJson);
    return FeeBumpTransactionResponse(json['hash'], signaturesList);
  }
}

/// InnerTransaction is only present in a TransactionResponse if the transaction is a fee bump transaction or is
/// wrapped by a fee bump transaction. The object has three fields: the hash of the inner transaction wrapped by the
/// fee bump transaction, the max fee set in the inner transaction, and the signatures present in the inner
/// transaction envelope.
class InnerTransaction {
  String? hash;
  List<String?>? signatures;
  int? maxFee;

  /// Constructor creates a InnerTransaction object from [hash], [signatures] and [maxFee].
  InnerTransaction(this.hash, this.signatures, this.maxFee);

  factory InnerTransaction.fromJson(Map<String, dynamic> json) {
    var signaturesFromJson = json['signatures'];
    List<String> signaturesList = List<String>.from(signaturesFromJson);
    return InnerTransaction(
        json['hash'], signaturesList, convertInt(json['max_fee']));
  }
}

class PreconditionsTimeBoundsResponse {
  String? minTime;
  String? maxTime;

  PreconditionsTimeBoundsResponse(this.minTime, this.maxTime);

  factory PreconditionsTimeBoundsResponse.fromJson(Map<String, dynamic> json) {
    return PreconditionsTimeBoundsResponse(
        json['min_time'], json['max_time']);
  }
}

class PreconditionsLedgerBoundsResponse {
  int minLedger;
  int maxLedger;

  PreconditionsLedgerBoundsResponse(this.minLedger, this.maxLedger);

  factory PreconditionsLedgerBoundsResponse.fromJson(
      Map<String, dynamic> json) {
    return PreconditionsLedgerBoundsResponse(
        convertInt(json['min_ledger']) == null
            ? 0
            : convertInt(json['min_ledger'])!,
        convertInt(json['max_ledger']) == null
            ? 0
            : convertInt(json['max_ledger'])!);
  }
}

class TransactionPreconditionsResponse {
  PreconditionsTimeBoundsResponse? timeBounds;
  PreconditionsLedgerBoundsResponse? ledgerBounds;
  String? minAccountSequence;
  String? minAccountSequenceAge;
  int? minAccountSequenceLedgerGap;
  List<String?>? extraSigners;

  TransactionPreconditionsResponse(
      this.timeBounds,
      this.ledgerBounds,
      this.minAccountSequence,
      this.minAccountSequenceAge,
      this.minAccountSequenceLedgerGap,
      this.extraSigners);

  factory TransactionPreconditionsResponse.fromJson(Map<String, dynamic> json) {
    var signersFromJson = json['extra_signers'];
    List<String> signersList = [];
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

/// Links connected to a transaction response.
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
