// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import "package:eventsource/eventsource.dart";
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'request_builder.dart';
import '../responses/response.dart';
import '../responses/operations/operation_responses.dart';
import '../util.dart';

/// Builds requests connected to payments.
class PaymentsRequestBuilder extends RequestBuilder {
  PaymentsRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, ["payments"]);

  /// Returns successful payments for a given account identified by [accountId].
  /// See: <a href="https://developers.stellar.org/api/resources/accounts/payments/" target="_blank">Payments for Account</a>
  PaymentsRequestBuilder forAccount(String accountId) {
    accountId = checkNotNull(accountId, "accountId cannot be null");
    this.setSegments(["accounts", accountId, "payments"]);
    return this;
  }

  /// Returns all payment-related operations in a specific ledger identified by [ledgerSeq].
  /// See: <a href="https://developers.stellar.org/api/resources/ledgers/payments/" target="_blank">Payments for Ledger</a>
  PaymentsRequestBuilder forLedger(int ledgerSeq) {
    this.setSegments(["ledgers", ledgerSeq.toString(), "payments"]);
    return this;
  }

  /// Returns the payments of a given transaction by [transactionId].
  /// See: <a href="https://www.stellar.org/developers/horizon/reference/endpoints/payments-for-transaction.html" target="_blank">Payments for Transaction</a>
  PaymentsRequestBuilder forTransaction(String transactionId) {
    transactionId = checkNotNull(transactionId, "transactionId cannot be null");
    this.setSegments(["transactions", transactionId, "payments"]);
    return this;
  }

  // TODO: include transactions / join

  /// Requests specific uri and returns Page of OperationResponse.
  /// This method is helpful for getting the next set of results.
  static Future<Page<OperationResponse>> requestExecute(
      http.Client httpClient, Uri uri) async {
    TypeToken type = new TypeToken<Page<OperationResponse>>();
    ResponseHandler<Page<OperationResponse>> responseHandler =
        new ResponseHandler<Page<OperationResponse>>(type);

    return await httpClient
        .get(uri, headers: RequestBuilder.headers)
        .then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  /// Allows to stream SSE events from horizon.
  /// Certain endpoints in Horizon can be called in streaming mode using Server-Sent Events.
  /// This mode will keep the connection to horizon open and horizon will continue to return
  /// responses as ledgers close.
  /// See: <a href="https://developers.stellar.org/api/introduction/streaming/" target="_blank">Streaming</a>
  Stream<OperationResponse> stream() {
    StreamController<OperationResponse> listener =
        new StreamController.broadcast();
    EventSource.connect(this.buildUri()).then((eventSource) {
      eventSource.listen((Event event) {
        if (event.data == "\"hello\"" || event.event == "close") {
          return null;
        }
        OperationResponse payment =
            OperationResponse.fromJson(json.decode(event.data));
        listener.add(payment);
      });
    });
    return listener.stream;
  }

  ///Build and execute request.
  Future<Page<OperationResponse>> execute() {
    return PaymentsRequestBuilder.requestExecute(
        this.httpClient, this.buildUri());
  }

  @override
  PaymentsRequestBuilder cursor(String token) {
    super.cursor(token);
    return this;
  }

  @override
  PaymentsRequestBuilder limit(int number) {
    super.limit(number);
    return this;
  }

  @override
  PaymentsRequestBuilder order(RequestBuilderOrder direction) {
    super.order(direction);
    return this;
  }
}
