// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:http/http.dart' as http;

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
/// - [Stellar developer docs](https://developers.stellar.org)
class PaymentsRequestBuilder extends RequestBuilder {
  /// Creates a PaymentsRequestBuilder for querying payment operations from Horizon.
  ///
  /// This constructor is typically called internally by the SDK. Use [StellarSDK.payments]
  /// to access payment query functionality.
  ///
  /// Parameters:
  /// - [httpClient] HTTP client for making requests to Horizon
  /// - [serverURI] Base URI of the Horizon server
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
  /// - [Stellar developer docs](https://developers.stellar.org)
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
  /// - [Stellar developer docs](https://developers.stellar.org)
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
    return RequestBuilder.requestExecute<Page<OperationResponse>>(
        httpClient, uri);
  }

  /// Allows to stream SSE events from horizon.
  /// Certain endpoints in Horizon can be called in streaming mode using Server-Sent Events.
  /// This mode will keep the connection to horizon open and horizon will continue to return
  /// responses as ledgers close.
  /// See: [Stellar developer docs](https://developers.stellar.org)
  Stream<OperationResponse> stream() {
    return streamEvents<OperationResponse>(
        (json) => OperationResponse.fromJson(json));
  }

  ///Build and execute request.
  Future<Page<OperationResponse>> execute() {
    return PaymentsRequestBuilder.requestExecute(
        this.httpClient, this.buildUri());
  }

  /// Sets the cursor for pagination to start returning records from a specific point.
  /// Returns this builder for method chaining.
  @override
  PaymentsRequestBuilder cursor(String token) {
    super.cursor(token);
    return this;
  }

  /// Sets the maximum number of records to return in a single page.
  /// Returns this builder for method chaining.
  @override
  PaymentsRequestBuilder limit(int number) {
    super.limit(number);
    return this;
  }

  /// Sets the sort order for returned records (ascending or descending).
  /// Returns this builder for method chaining.
  @override
  PaymentsRequestBuilder order(RequestBuilderOrder direction) {
    super.order(direction);
    return this;
  }
}
