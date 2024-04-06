// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import "../eventsource/eventsource.dart";
import '../responses/operations/operation_responses.dart';
import '../responses/response.dart';
import 'request_builder.dart';

/// Builds requests connected to operations. Operations are objects that represent a desired change to the ledger: payments, offers to exchange currency, changes made to account options, etc. Operations are submitted to the Stellar network grouped in a Transaction.
/// See: <a href="https://developers.stellar.org/api/resources/operations/" target="_blank">Operations</a>
class OperationsRequestBuilder extends RequestBuilder {
  OperationsRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, ["operations"]);

  /// Requests specific uri and returns OperationResponse.
  /// This method is helpful for getting the links.
  Future<OperationResponse> operationURI(Uri uri) async {
    TypeToken<OperationResponse> type = new TypeToken<OperationResponse>();
    ResponseHandler<OperationResponse> responseHandler =
        new ResponseHandler<OperationResponse>(type);

    return await httpClient
        .get(uri, headers: RequestBuilder.headers)
        .then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  /// Provides information about a specific operation given by [operationId].
  /// See: <a href="https://developers.stellar.org/api/resources/operations/single/" target="_blank">Operation Details</a>
  Future<OperationResponse> operation(int operationId) {
    this.setSegments(["operations", operationId.toString()]);
    return this.operationURI(this.buildUri());
  }

  /// Returns successful operations for a given account identified by [accountId].
  /// See: <a href="https://developers.stellar.org/api/resources/accounts/operations/" target="_blank">Operations for Account</a>
  OperationsRequestBuilder forAccount(String accountId) {
    this.setSegments(["accounts", accountId, "operations"]);
    return this;
  }

  /// Returns successful operations for a given claimable balance by [claimableBalanceId].
  /// See: <a href="https://developers.stellar.org/api/resources/claimablebalances/operations/" target="_blank">Operations for claimable balance</a>
  OperationsRequestBuilder forClaimableBalance(String claimableBalanceId) {
    this.setSegments(["claimable_balances", claimableBalanceId, "operations"]);
    return this;
  }

  /// Returns successful operations in a specific ledger identified by [ledgerSeq].
  /// See: <a href="https://developers.stellar.org/api/resources/ledgers/operations/" target="_blank">Operations for Ledger</a>
  OperationsRequestBuilder forLedger(int ledgerSeq) {
    this.setSegments(["ledgers", ledgerSeq.toString(), "operations"]);
    return this;
  }

  /// Returns successful operations for a specific transaction identiefied by [transactionId].
  /// See: <a href="https://developers.stellar.org/api/resources/transactions/operations/" target="_blank">Operations for Transaction</a>
  OperationsRequestBuilder forTransaction(String transactionId) {
    this.setSegments(["transactions", transactionId, "operations"]);
    return this;
  }

  OperationsRequestBuilder forLiquidityPool(String liquidityPoolId) {
    this.setSegments(["liquidity_pools", liquidityPoolId, "operations"]);
    return this;
  }

  /// Adds a parameter defining whether to include operations of failed transactions. By default only operations of
  /// successful transactions are returned.
  OperationsRequestBuilder includeFailed(bool value) {
    queryParameters.addAll({"include_failed": value.toString()});
    return this;
  }

  // TODO: includeTransactions / join

  /// Requests specific <code>uri</code> and returns Page of OperationResponse.
  /// This method is helpful for getting the next set of results.
  static Future<Page<OperationResponse>> requestExecute(
      http.Client httpClient, Uri uri) async {
    TypeToken<Page<OperationResponse>> type =
        new TypeToken<Page<OperationResponse>>();
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
    StreamController<OperationResponse> listener = StreamController.broadcast();

    bool cancelled = false;
    EventSource? source;

    Future<void> createNewEventSource() async {
      if (cancelled) {
        return;
      }
      source?.close();
      source = await EventSource.connect(this.buildUri());
      source!.listen((Event event) async {
        if (cancelled) {
          return null;
        }
        if (event.event == "open") {
          return null;
        }
        if (event.event == "close") {
          // Reconnect on close to stream infinitely
          createNewEventSource();
          return null;
        }
        try {
          OperationResponse operationResponse = OperationResponse.fromJson(
            json.decode(event.data!),
          );
          listener.add(operationResponse);
        } catch (e, stackTrace) {
          listener.addError(e, stackTrace);
          createNewEventSource();
        }
      });
    }

    listener.onListen = () {
      cancelled = false;
      createNewEventSource();
    };
    listener.onCancel = () {
      if (!listener.hasListener) {
        cancelled = true;
        source?.close();
      }
    };

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
