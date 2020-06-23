// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import "package:eventsource/eventsource.dart";
import 'package:http/http.dart' as http;
import 'request_builder.dart';
import 'dart:async';
import 'dart:convert';
import '../responses/response.dart';
import '../responses/transaction_response.dart';
import '../util.dart';

/// Builds requests connected to transactions.
class TransactionsRequestBuilder extends RequestBuilder {
  TransactionsRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, ["transactions"]);

  /// Requests specific uri and returns TransactionResponse.
  /// This method is helpful for getting the links.
  Future<TransactionResponse> transactionURI(Uri uri) async {
    TypeToken type = new TypeToken<TransactionResponse>();
    ResponseHandler<TransactionResponse> responseHandler =
    new ResponseHandler<TransactionResponse>(type);

    return await httpClient.get(uri).then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  /// Returns a transaction by [transactionId].
  /// See:  @see <a href="https://www.stellar.org/developers/horizon/reference/transactions-single.html">Transaction Details</a>
  Future<TransactionResponse> transaction(String transactionId) {
    this.setSegments(["transactions", transactionId]);
    return this.transactionURI(this.buildUri());
  }

  /// Returns the transactions for an account by [accountId].
  /// See:<a href="https://www.stellar.org/developers/horizon/reference/transactions-for-account.html">Transactions for Account</a>
  TransactionsRequestBuilder forAccount(String accountId) {
    accountId = checkNotNull(accountId, "accountId cannot be null");
    this.setSegments(["accounts", accountId, "transactions"]);
    return this;
  }

  /// Returns the transactiona for a leger by [ledgerSeq].
  /// See: <a href="https://www.stellar.org/developers/horizon/reference/transactions-for-ledger.html">Transactions for Ledger</a>
  TransactionsRequestBuilder forLedger(int ledgerSeq) {
    this.setSegments(["ledgers", ledgerSeq.toString(), "transactions"]);
    return this;
  }

  /// Adds a parameter defining whether to include failed transactions. By default only successful transactions are returned.
  TransactionsRequestBuilder includeFailed(bool value) {
    value = checkNotNull(value, "value cannot be null");
    queryParameters.addAll({"include_failed": value.toString()});
    return this;
  }

  /// Requests specific uri and returns Page of TransactionResponse.
  /// This method is helpful for getting the next set of results.
  static Future<Page<TransactionResponse>> requestExecute(
      http.Client httpClient, Uri uri) async {
    TypeToken type = new TypeToken<Page<TransactionResponse>>();
    ResponseHandler<Page<TransactionResponse>> responseHandler =
    new ResponseHandler<Page<TransactionResponse>>(type);

    return await httpClient.get(uri).then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  /// Allows to stream SSE events from horizon.
  /// Certain endpoints in Horizon can be called in streaming mode using Server-Sent Events.
  /// This mode will keep the connection to horizon open and horizon will continue to return
  /// responses as ledgers close.
  /// See: <a href="http://www.w3.org/TR/eventsource/" target="_blank">Server-Sent Events</a>
  /// See: <a href="https://www.stellar.org/developers/horizon/learn/responses.html" target="_blank">Response Format documentation</a>
  Stream<TransactionResponse> stream() {
    StreamController<TransactionResponse> listener =
    new StreamController.broadcast();
    EventSource.connect(this.buildUri()).then((eventSource) {
      eventSource.listen((Event event) {
        if (event.data == "\"hello\"" || event.event == "close") {
          return null;
        }
        TransactionResponse transactionResponse =
        TransactionResponse.fromJson(json.decode(event.data));
        listener.add(transactionResponse);
      });
    });
    return listener.stream;
  }

  /// Build and execute request.
  Future<Page<TransactionResponse>> execute() {
    return TransactionsRequestBuilder.requestExecute(
        this.httpClient, this.buildUri());
  }

  @override
  TransactionsRequestBuilder cursor(String token) {
    super.cursor(token);
    return this;
  }

  @override
  TransactionsRequestBuilder limit(int number) {
    super.limit(number);
    return this;
  }

  @override
  TransactionsRequestBuilder order(RequestBuilderOrder direction) {
    super.order(direction);
    return this;
  }
}
