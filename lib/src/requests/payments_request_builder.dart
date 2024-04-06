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

/// Builds requests connected to payments.
class PaymentsRequestBuilder extends RequestBuilder {
  PaymentsRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, ["payments"]);

  /// Returns successful payments for a given account identified by [accountId].
  /// See: <a href="https://developers.stellar.org/api/resources/accounts/payments/" target="_blank">Payments for Account</a>
  PaymentsRequestBuilder forAccount(String accountId) {
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
    this.setSegments(["transactions", transactionId, "payments"]);
    return this;
  }

  // TODO: include transactions / join

  /// Requests specific uri and returns Page of OperationResponse.
  /// This method is helpful for getting the next set of results.
  static Future<Page<OperationResponse>> requestExecute(
      http.Client httpClient, Uri uri) async {
    TypeToken<Page<OperationResponse>> type =
        TypeToken<Page<OperationResponse>>();
    ResponseHandler<Page<OperationResponse>> responseHandler =
        ResponseHandler<Page<OperationResponse>>(type);

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
