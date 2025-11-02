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

/// Builder for requests to the payments endpoint.
///
/// PaymentsRequestBuilder provides methods for querying payment operations
/// from the Horizon server. Payment operations include CREATE_ACCOUNT, PAYMENT,
/// PATH_PAYMENT_STRICT_SEND, PATH_PAYMENT_STRICT_RECEIVE, and ACCOUNT_MERGE.
///
/// Example:
/// ```dart
/// // Get payments for an account
/// var payments = await sdk.payments
///     .forAccount(accountId)
///     .order(RequestBuilderOrder.DESC)
///     .limit(20)
///     .execute();
///
/// // Stream new payments
/// sdk.payments.forAccount(accountId).cursor('now').stream().listen((payment) {
///   if (payment is PaymentOperationResponse) {
///     print('Received ${payment.amount} ${payment.assetType}');
///   }
/// });
/// ```
///
/// See also:
/// - [Horizon Payments API](https://developers.stellar.org/api/resources/operations/)
class PaymentsRequestBuilder extends RequestBuilder {
  PaymentsRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, ["payments"]);

  /// Filters payments by account.
  ///
  /// Returns all payment operations involving the specified account.
  ///
  /// Parameters:
  /// - accountId: The account public key
  ///
  /// Returns: This builder instance for method chaining
  ///
  /// Example:
  /// ```dart
  /// var payments = await sdk.payments
  ///     .forAccount('GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B')
  ///     .execute();
  /// ```
  ///
  /// See also:
  /// - [Horizon Account Payments](https://developers.stellar.org/api/resources/accounts/payments/)
  PaymentsRequestBuilder forAccount(String accountId) {
    this.setSegments(["accounts", accountId, "payments"]);
    return this;
  }

  /// Filters payments by ledger sequence number.
  ///
  /// Returns all payment operations in the specified ledger.
  ///
  /// Parameters:
  /// - ledgerSeq: The ledger sequence number
  ///
  /// Returns: This builder instance for method chaining
  ///
  /// Example:
  /// ```dart
  /// var payments = await sdk.payments.forLedger(12345).execute();
  /// ```
  ///
  /// See also:
  /// - [Horizon Ledger Payments](https://developers.stellar.org/api/resources/ledgers/payments/)
  PaymentsRequestBuilder forLedger(int ledgerSeq) {
    this.setSegments(["ledgers", ledgerSeq.toString(), "payments"]);
    return this;
  }

  /// Filters payments by transaction hash.
  ///
  /// Returns all payment operations in the specified transaction.
  ///
  /// Parameters:
  /// - transactionId: The transaction hash
  ///
  /// Returns: This builder instance for method chaining
  ///
  /// Example:
  /// ```dart
  /// var payments = await sdk.payments
  ///     .forTransaction(transactionHash)
  ///     .execute();
  /// ```
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
      source = await EventSource.connect(
        this.buildUri(),
        client: httpClient,
      );
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
