// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'response.dart';
import 'dart:convert';
import '../xdr/xdr_data_io.dart';
import '../xdr/xdr_operation.dart';
import '../xdr/xdr_transaction.dart';
import '../xdr/xdr_ledger.dart';
import '../util.dart';
import 'transaction_response.dart';

/// Represents the horizon server response after submitting transaction.
class SubmitTransactionResponse extends Response {
  String? hash;
  int? ledger;
  String? _strEnvelopeXdr;
  String? _strResultXdr;
  String? _strMetaXdr;
  String? _strFeeMetaXdr;
  SubmitTransactionResponseExtras? extras;
  TransactionResponse? successfulTransaction;

  SubmitTransactionResponse(
      this.extras,
      this.ledger,
      this.hash,
      this._strEnvelopeXdr,
      this._strResultXdr,
      this._strMetaXdr,
      this._strFeeMetaXdr,
      this.successfulTransaction);

  bool get success {
    if (_strResultXdr != null) {
      XdrTransactionResult result =
          XdrTransactionResult.fromBase64EncodedXdrString(_strResultXdr!);
      if (result.result.discriminant == XdrTransactionResultCode.txSUCCESS) {
        return true;
      } else if (result.result.discriminant ==
              XdrTransactionResultCode.txFEE_BUMP_INNER_SUCCESS &&
          result.result.innerResultPair != null) {
        XdrInnerTransactionResultPair innerResultPair =
            result.result.innerResultPair;
        if (innerResultPair.result.result.discriminant ==
            XdrTransactionResultCode.txSUCCESS) {
          return true;
        }
      }
    }
    return false;
  }

  String? get envelopeXdr {
    if (this.success) {
      return this._strEnvelopeXdr;
    } else {
      if (this.extras != null) {
        return this.extras!.envelopeXdr;
      }
      return null;
    }
  }

  String? get resultXdr {
    if (this.success) {
      return this._strResultXdr;
    } else {
      if (this.extras != null) {
        return this.extras!.resultXdr;
      }
      return null;
    }
  }

  String? get resultMetaXdr {
    if (this.success) {
      return this._strMetaXdr;
    } else {
      if (this.extras != null) {
        return this.extras!.strMetaXdr;
      }
      return null;
    }
  }

  String? get feeMetaXdr {
    if (this.success) {
      return this._strFeeMetaXdr;
    } else {
      if (this.extras != null) {
        return this.extras!.strFeeMetaXdr;
      }
      return null;
    }
  }

  XdrTransactionResult? getTransactionResultXdr() {
    if (this.resultXdr == null) {
      return null;
    }
    try {
      return XdrTransactionResult.fromBase64EncodedXdrString(this.resultXdr!);
    } catch (e) {
      return null;
    }
  }

  XdrTransactionMeta? getTransactionMetaResultXdr() {
    if (this.resultMetaXdr == null) {
      return null;
    }

    try {
      return XdrTransactionMeta.fromBase64EncodedXdrString(this.resultMetaXdr!);
    } catch (e) {
      return null;
    }
  }

  XdrLedgerEntryChanges? getFeeMetaXdr() {
    if (this.feeMetaXdr == null) {
      return null;
    }

    try {
      return XdrLedgerEntryChanges.fromBase64EncodedXdrString(this.feeMetaXdr!);
    } catch (e) {
      return null;
    }
  }

  /// Helper method that returns Offer ID for ManageOffer from TransactionResult Xdr.
  /// This is helpful when you need the ID of an offer to update it later.
  int? getOfferIdFromResult(int position) {
    if (!this.success) {
      return null;
    }

    XdrDataInputStream xdrInputStream =
        XdrDataInputStream(base64Decode(this.resultXdr!));
    XdrTransactionResult result;

    try {
      result = XdrTransactionResult.decode(xdrInputStream);
    } catch (e) {
      return null;
    }

    if (result.result.results[position] == null) {
      return null;
    }

    XdrOperationType? disc =
        (result.result.results[position] as XdrOperationResult)
            .tr!
            .discriminant;
    if (disc != XdrOperationType.MANAGE_SELL_OFFER &&
        disc != XdrOperationType.MANAGE_BUY_OFFER) {
      return null;
    }

    if ((result.result.results[position] as XdrOperationResult?)
            ?.tr!
            .manageOfferResult!
            .success!
            .offer
            .offer ==
        null) {
      return null;
    }

    return (result.result.results[position] as XdrOperationResult)
        .tr!
        .manageOfferResult!
        .success!
        .offer
        .offer!
        .offerID
        .uint64;
  }

  /// Helper method that returns Claimable Balance Id for CreateClaimableBalance from TransactionResult Xdr.
  /// This is helpful when you need the created Claimable Balance ID to show it to the user
  String? getClaimableBalanceIdIdFromResult(int position) {
    if (!this.success) {
      return null;
    }

    XdrDataInputStream xdrInputStream =
        XdrDataInputStream(base64Decode(this.resultXdr!));
    XdrTransactionResult result;

    try {
      result = XdrTransactionResult.decode(xdrInputStream);
    } catch (e) {
      return null;
    }

    if (result.result.results[position] == null) {
      return null;
    }

    XdrOperationType? disc =
        (result.result.results[position] as XdrOperationResult)
            .tr!
            .discriminant;
    if (disc != XdrOperationType.CREATE_CLAIMABLE_BALANCE) {
      return null;
    }

    if ((result.result.results[position] as XdrOperationResult?)
            ?.tr!
            .createClaimableBalanceResult!
            .balanceID ==
        null) {
      return null;
    }

    return Util.bytesToHex((result.result.results[0] as XdrOperationResult)
        .tr!
        .createClaimableBalanceResult!
        .balanceID!
        .v0!
        .hash);
  }

  factory SubmitTransactionResponse.fromJson(Map<String, dynamic> json) =>
      SubmitTransactionResponse(
          json['extras'] == null
              ? null
              : SubmitTransactionResponseExtras.fromJson(json['extras']),
          convertInt(json['ledger']),
          json['hash'],
          json['envelope_xdr'],
          json['result_xdr'],
          json['result_meta_xdr'],
          json['fee_meta_xdr'],
          json['successful'] == true
              ? TransactionResponse.fromJson(json)
              : null)
        ..rateLimitLimit = convertInt(json['rateLimitLimit'])
        ..rateLimitRemaining = convertInt(json['rateLimitRemaining'])
        ..rateLimitReset = convertInt(json['rateLimitReset']);
}

/// Contains result codes for this transaction.
class ExtrasResultCodes {
  String? transactionResultCode;
  List<String?>? operationsResultCodes;

  ExtrasResultCodes(this.transactionResultCode, this.operationsResultCodes);

  factory ExtrasResultCodes.fromJson(Map<String, dynamic> json) =>
      ExtrasResultCodes(
        json['transaction'],
        json['operations'] != null
            ? List<String>.from(json['operations'].map((e) => e))
            : null,
      );
}

/// Additional information returned by the horizon server.
class SubmitTransactionResponseExtras {
  String envelopeXdr;
  String resultXdr;
  String? strMetaXdr;
  String? strFeeMetaXdr;
  ExtrasResultCodes? resultCodes;

  SubmitTransactionResponseExtras(this.envelopeXdr, this.resultXdr,
      this.strMetaXdr, this.strFeeMetaXdr, this.resultCodes);

  factory SubmitTransactionResponseExtras.fromJson(Map<String, dynamic> json) =>
      SubmitTransactionResponseExtras(
          json['envelope_xdr'],
          json['result_xdr'],
          json['result_meta_xdr'],
          json['fee_meta_xdr'],
          json['result_codes'] == null
              ? null
              : ExtrasResultCodes.fromJson(json['result_codes']));
}

class SubmitTransactionTimeoutResponseException implements Exception {
  /// Identifies the problem type.
  String type;

  /// A short, human-readable summary of the problem type.
  String title;

  /// The HTTP status code for this occurrence of the problem.
  int status;

  /// A human-readable explanation specific to this occurrence of the problem.
  String detail;

  /// Additional details that might help the client understand the error(s) that occurred.
  Map<String, dynamic>? extras;

  /// Transaction hash if available in the error response extras.
  String? get hash {
    if (extras != null &&
        extras!.containsKey('hash') &&
        extras!['hash'] is String) {
      return extras!['hash'] as String;
    }
    return null;
  }

  SubmitTransactionTimeoutResponseException({
    required this.type,
    required this.title,
    required this.status,
    required this.detail,
    this.extras,
  });

  String toString() {
    return "Submit transaction timeout response from Horizon" +
        " - type: $type - title:$title - status:$status - detail:$detail";
  }

  factory SubmitTransactionTimeoutResponseException.fromJson(
          Map<String, dynamic> json) =>
      SubmitTransactionTimeoutResponseException(
        type: json['type'],
        title: json['title'],
        status: json['status'],
        detail: json['detail'],
        extras: json['extras'],
      );
}

@Deprecated('Use [UnknownResponse]')
class SubmitTransactionUnknownResponseException extends UnknownResponse {
  SubmitTransactionUnknownResponseException(super.code, super.body);
}

/// Response of async transaction submission to Horizon.
/// See https://developers.stellar.org/docs/data/horizon/api-reference/submit-async-transaction
class SubmitAsyncTransactionResponse {
  static const txStatusError = 'ERROR';
  static const txStatusPending = 'PENDING';
  static const txStatusDuplicate = 'DUPLICATE';
  static const txStatusTryAgainLater = 'TRY_AGAIN_LATER';

  /// Status of the transaction submission.
  /// Possible values: [ERROR, PENDING, DUPLICATE, TRY_AGAIN_LATER]
  String txStatus;

  /// Hash of the transaction.
  String hash;

  /// The HTTP status code of the response obtained from Horizon.
  int httpStatusCode;

  /// Constructor
  /// [txStatus] Status of the transaction submission. Possible values: [ERROR, PENDING, DUPLICATE, TRY_AGAIN_LATER]
  /// [hash] Hash of the transaction.
  /// [httpStatusCode] The HTTP status code of the response obtained from Horizon.
  SubmitAsyncTransactionResponse(
      {required this.txStatus,
      required this.hash,
      required this.httpStatusCode});

  factory SubmitAsyncTransactionResponse.fromJson(
          Map<String, dynamic> json, int httpResponseStatusCode) =>
      SubmitAsyncTransactionResponse(
        txStatus: json['tx_status'],
        hash: json['hash'],
        httpStatusCode: httpResponseStatusCode,
      );
}

/// Thrown if the response of async transaction submission to Horizon represents a known problem.
/// See https://developers.stellar.org/docs/data/horizon/api-reference/submit-async-transaction
class SubmitAsyncTransactionProblem implements Exception {
  /// Identifies the problem type.
  String type;

  /// A short, human-readable summary of the problem type.
  String title;

  /// The HTTP status code for this occurrence of the problem.
  int status;

  /// A human-readable explanation specific to this occurrence of the problem.
  String detail;

  /// Additional details that might help the client understand the error(s) that occurred.
  Map<String, dynamic>? extras;

  /// Constructor.
  SubmitAsyncTransactionProblem({
    required this.type,
    required this.title,
    required this.status,
    required this.detail,
    this.extras,
  });

  String toString() {
    return "Submit async transaction problem response from Horizon" +
        " - type: $type - title:$title - status:$status - detail:$detail";
  }

  factory SubmitAsyncTransactionProblem.fromJson(Map<String, dynamic> json) =>
      SubmitAsyncTransactionProblem(
        type: json['type'],
        title: json['title'],
        status: json['status'],
        detail: json['detail'],
        extras: json['extras'],
      );
}
