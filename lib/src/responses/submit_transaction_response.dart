// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'response.dart';
import 'dart:convert';
import '../xdr/xdr_data_io.dart';
import '../xdr/xdr_operation.dart';
import '../xdr/xdr_transaction.dart';

/// Represents the horizon server response after submitting transaction.
class SubmitTransactionResponse extends Response {
  String hash;
  int ledger;
  String strEnvelopeXdr;
  String strResultXdr;
  SubmitTransactionResponseExtras extras;

  SubmitTransactionResponse(this.extras, this.ledger, this.hash,
      this.strEnvelopeXdr, this.strResultXdr);

  bool get success => ledger != null;

  String get envelopeXdr {
    if (this.success) {
      return this.strEnvelopeXdr;
    } else {
      if (this.extras != null) {
        return this.extras.envelopeXdr;
      }
      return null;
    }
  }

  String get resultXdr {
    if (this.success) {
      return this.strResultXdr;
    } else {
      if (this.extras != null) {
        return this.extras.resultXdr;
      }
      return null;
    }
  }

  /// Helper method that returns Offer ID for ManageOffer from TransactionResult Xdr.
  /// This is helpful when you need the ID of an offer to update it later.
  int getOfferIdFromResult(int position) {
    if (!this.success) {
      return null;
    }

    XdrDataInputStream xdrInputStream =
        new XdrDataInputStream(base64Decode(this.resultXdr));
    XdrTransactionResult result;

    try {
      result = XdrTransactionResult.decode(xdrInputStream);
    } catch (e) {
      return null;
    }

    if (result.result.results[position] == null) {
      return null;
    }

    XdrOperationType disc =
        (result.result.results[position] as XdrOperationResult).tr.discriminant;
    if (disc != XdrOperationType.MANAGE_SELL_OFFER &&
        disc != XdrOperationType.MANAGE_BUY_OFFER) {
      return null;
    }

    if ((result.result.results[0] as XdrOperationResult)
            .tr
            .manageOfferResult
            .success
            .offer
            .offer ==
        null) {
      return null;
    }

    return (result.result.results[0] as XdrOperationResult)
        .tr
        .manageOfferResult
        .success
        .offer
        .offer
        .offerID
        .uint64;
  }

  factory SubmitTransactionResponse.fromJson(Map<String, dynamic> json) =>
      new SubmitTransactionResponse(
          json['extras'] == null
              ? null
              : new SubmitTransactionResponseExtras.fromJson(
                  json['extras'] as Map<String, dynamic>),
          convertInt(json['ledger']),
          json['hash'] as String,
          json['envelope_xdr'] as String,
          json['result_xdr'] as String)
        ..rateLimitLimit = convertInt(json['rateLimitLimit'])
        ..rateLimitRemaining = convertInt(json['rateLimitRemaining'])
        ..rateLimitReset = convertInt(json['rateLimitReset']);
}

/// Contains result codes for this transaction.
class ExtrasResultCodes {
  String transactionResultCode;
  List<String> operationsResultCodes;

  ExtrasResultCodes(this.transactionResultCode, this.operationsResultCodes);

  factory ExtrasResultCodes.fromJson(Map<String, dynamic> json) =>
      new ExtrasResultCodes(json['transaction'] as String,
          (json['operations'] as List)?.map((e) => e as String)?.toList());
}

/// Additional information returned by the horizon server.
class SubmitTransactionResponseExtras {
  String envelopeXdr;
  String resultXdr;
  ExtrasResultCodes resultCodes;

  SubmitTransactionResponseExtras(
      this.envelopeXdr, this.resultXdr, this.resultCodes);

  factory SubmitTransactionResponseExtras.fromJson(Map<String, dynamic> json) =>
      new SubmitTransactionResponseExtras(
          json['envelope_xdr'] as String,
          json['result_xdr'] as String,
          json['result_codes'] == null
              ? null
              : new ExtrasResultCodes.fromJson(
                  json['result_codes'] as Map<String, dynamic>));
}

class SubmitTransactionTimeoutResponseException implements Exception {
  String toString() {
    return "Timeout. Please resubmit your transaction to receive submission status. More info: https://www.stellar.org/developers/horizon/reference/errors/timeout.html";
  }
}

class SubmitTransactionUnknownResponseException implements Exception {
  int _code;
  String _body;

  SubmitTransactionUnknownResponseException(this._code, this._body);

  String toString() {
    return "Unknown response from Horizon - code: $code - body:$body";
  }

  int get code => _code;
  String get body => _body;
}
