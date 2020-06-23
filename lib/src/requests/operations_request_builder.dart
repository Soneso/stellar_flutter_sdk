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


/// Builds requests connected to operations.
class OperationsRequestBuilder extends RequestBuilder {
  OperationsRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, ["operations"]);

  /// Requests specific uri and returns OperationResponse.
  /// This method is helpful for getting the links.
  Future<OperationResponse> operationURI(Uri uri) async {
    TypeToken type = new TypeToken<OperationResponse>();
    ResponseHandler<OperationResponse> responseHandler =
    new ResponseHandler<OperationResponse>(type);

    return await httpClient.get(uri, headers:RequestBuilder.headers).then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  /// Returns the operation for a given [operationId].
  /// See: <a href="https://www.stellar.org/developers/horizon/reference/operations-single.html">Operation Details</a>
  Future<OperationResponse> operation(int operationId) {
    operationId = checkNotNull(operationId, "operationId cannot be null");
    this.setSegments(["operations", operationId.toString()]);
    return this.operationURI(this.buildUri());
  }

  /// Returuns the operations for a given account represented by [accountId].
  /// See: <a href="https://www.stellar.org/developers/horizon/reference/operations-for-account.html">Operations for Account</a>
  OperationsRequestBuilder forAccount(String accountId) {
    accountId = checkNotNull(accountId, "accountId cannot be null");
    this.setSegments(["accounts", accountId, "operations"]);
    return this;
  }

  /// Returns the operations for a given Ledger represented by [ledgerSeq].
  /// See: <a href="https://www.stellar.org/developers/horizon/reference/operations-for-ledger.html">Operations for Ledger</a>
  OperationsRequestBuilder forLedger(int ledgerSeq) {
    ledgerSeq = checkNotNull(ledgerSeq, "ledgerSeq cannot be null");
    this.setSegments(["ledgers", ledgerSeq.toString(), "operations"]);
    return this;
  }

  /// Returns the operations for a given transaction represented by [transactionId].
  /// See: <a href="https://www.stellar.org/developers/horizon/reference/operations-for-transaction.html">Operations for Transaction</a>
  OperationsRequestBuilder forTransaction(String transactionId) {
    transactionId = checkNotNull(transactionId, "transactionId cannot be null");
    this.setSegments(["transactions", transactionId, "operations"]);
    return this;
  }

  /// Adds a parameter defining whether to include operations of failed transactions. By default only operations of
  /// successful transactions are returned.
  OperationsRequestBuilder includeFailed(bool value) {
    value = checkNotNull(value, "value cannot be null");
    queryParameters.addAll({"include_failed": value.toString()});
    return this;
  }

  // TODO: includeTransactions / join

  /// Requests specific <code>uri</code> and returns Page of OperationResponse.
  /// This method is helpful for getting the next set of results.
  static Future<Page<OperationResponse>> requestExecute(
      http.Client httpClient, Uri uri) async {
    TypeToken type = new TypeToken<Page<OperationResponse>>();
    ResponseHandler<Page<OperationResponse>> responseHandler =
    new ResponseHandler<Page<OperationResponse>>(type);

    return await httpClient.get(uri, headers:RequestBuilder.headers).then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  /// Allows to stream SSE events from horizon.
  /// Certain endpoints in Horizon can be called in streaming mode using Server-Sent Events.
  /// This mode will keep the connection to horizon open and horizon will continue to return
  /// responses as ledgers close.
  /// See: <a href="http://www.w3.org/TR/eventsource/" target="_blank">Server-Sent Events</a>
  //  See: <a href="https://www.stellar.org/developers/horizon/learn/responses.html" target="_blank">Response Format documentation</a>
  Stream<OperationResponse> stream() {
    StreamController<OperationResponse> listener =
    new StreamController.broadcast();
    EventSource.connect(this.buildUri()).then((eventSource) {
      eventSource.listen((Event event) {
        if (event.data == "\"hello\"" || event.event == "close") {
          return null;
        }
        OperationResponse operationResponse =
        OperationResponse.fromJson(json.decode(event.data));
        listener.add(operationResponse);
      });
    });
    return listener.stream;
  }

  /// Build and execute request.
  Future<Page<OperationResponse>> execute() {
    return OperationsRequestBuilder.requestExecute(
        this.httpClient, this.buildUri());
  }

  @override
  OperationsRequestBuilder cursor(String token) {
    super.cursor(token);
    return this;
  }

  @override
  OperationsRequestBuilder limit(int number) {
    super.limit(number);
    return this;
  }

  @override
  OperationsRequestBuilder order(RequestBuilderOrder direction) {
    super.order(direction);
    return this;
  }
}