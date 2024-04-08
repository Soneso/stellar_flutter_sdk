// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import "../eventsource/eventsource.dart";
import '../responses/response.dart';
import '../responses/transaction_response.dart';
import 'request_builder.dart';

/// Builds requests connected to transactions. Transactions are commands that modify the ledger state and consist of one or more operations.
/// See: <a href="https://developers.stellar.org/api/resources/transactions/" target="_blank">Transactions</a>
class TransactionsRequestBuilder extends RequestBuilder {
  TransactionsRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, ["transactions"]);

  /// Returns information on a specific transaction identified [transactionId].
  /// See:  @see <a href="https://developers.stellar.org/api/resources/transactions/single/" target="_blank">Retrieve a Transaction</a>
  Future<TransactionResponse> transaction(String transactionId) {
    this.setSegments(["transactions", transactionId]);
    return this.transactionURI(this.buildUri());
  }

  /// Returns successful transactions for a given account identified by [accountId].
  /// See:<a href="https://developers.stellar.org/api/resources/accounts/transactions/" target="_blank">Retrieve an Account's Transactions</a>
  TransactionsRequestBuilder forAccount(String accountId) {
    this.setSegments(["accounts", accountId, "transactions"]);
    return this;
  }

  /// Returns successful transactions for a given claimable balance by [claimableBalanceId].
  /// See:<a href="https://developers.stellar.org/api/resources/claimablebalances/transactions/" target="_blank">Retrieve an Claimable Balance's Transactions</a>
  TransactionsRequestBuilder forClaimableBalance(String claimableBalanceId) {
    this.setSegments(
        ["claimable_balances", claimableBalanceId, "transactions"]);
    return this;
  }

  /// Returns successful transactions in a given ledger identified by [ledgerSeq].
  /// See: <a href="https://developers.stellar.org/api/resources/ledgers/transactions/" target="_blank">Retrieve a Ledger's Transactions</a>
  TransactionsRequestBuilder forLedger(int ledgerSeq) {
    this.setSegments(["ledgers", ledgerSeq.toString(), "transactions"]);
    return this;
  }

  TransactionsRequestBuilder forLiquidityPool(String liquidityPoolId) {
    this.setSegments(["liquidity_pools", liquidityPoolId, "transactions"]);
    return this;
  }

  /// Adds a parameter defining whether to include failed transactions. By default only successful transactions are returned.
  TransactionsRequestBuilder includeFailed(bool value) {
    queryParameters.addAll({"include_failed": value.toString()});
    return this;
  }

  /// Requests specific uri and returns TransactionResponse.
  /// This method is helpful for getting the links.
  Future<TransactionResponse> transactionURI(Uri uri) async {
    TypeToken<TransactionResponse> type = TypeToken<TransactionResponse>();
    ResponseHandler<TransactionResponse> responseHandler =
        ResponseHandler<TransactionResponse>(type);

    return await httpClient
        .get(uri, headers: RequestBuilder.headers)
        .then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  /// Requests specific uri and returns Page of TransactionResponse.
  /// This method is helpful for getting the next set of results.
  static Future<Page<TransactionResponse>> requestExecute(
      http.Client httpClient, Uri uri) async {
    TypeToken<Page<TransactionResponse>> type =
        TypeToken<Page<TransactionResponse>>();
    ResponseHandler<Page<TransactionResponse>> responseHandler =
        ResponseHandler<Page<TransactionResponse>>(type);

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
  Stream<TransactionResponse> stream() {
    StreamController<TransactionResponse> listener =
        StreamController.broadcast();

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
          TransactionResponse operationResponse = TransactionResponse.fromJson(
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
