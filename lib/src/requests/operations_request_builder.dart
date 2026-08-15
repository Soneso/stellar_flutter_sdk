// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:stellar_flutter_sdk/src/key_pair.dart';
import 'package:stellar_flutter_sdk/src/util.dart';

import '../responses/operations/operation_responses.dart';
import '../responses/response.dart';
import 'request_builder.dart';

/// Builds requests to query operations from Horizon.
///
/// Operations represent specific actions that change the ledger state, such as payments,
/// offers, account management, and trustline operations. Operations are submitted to the
/// Stellar network grouped within transactions.
///
/// This builder supports filtering operations by account, ledger, transaction, claimable
/// balance, or liquidity pool. It also supports streaming operations via Server-Sent Events
/// and pagination through result sets.
///
/// Example:
/// ```dart
/// // Get operations for a specific account
/// final operations = await sdk.operations
///     .forAccount('GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B')
///     .order(RequestBuilderOrder.DESC)
///     .limit(10)
///     .execute();
///
/// // Get operations for a specific transaction
/// final txOps = await sdk.operations
///     .forTransaction('tx_hash')
///     .execute();
///
/// // Stream operations in real-time
/// sdk.operations
///     .forAccount('account_id')
///     .cursor('now')
///     .stream()
///     .listen((operation) {
///       print('New operation: ${operation.type}');
///     });
/// ```
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
/// - [OperationResponse] for response structure
class OperationsRequestBuilder extends RequestBuilder {
  /// Creates an OperationsRequestBuilder for querying operations from Horizon.
  ///
  /// This constructor is typically called internally by the SDK. Use [StellarSDK.operations]
  /// to access operation query functionality.
  ///
  /// Parameters:
  /// - [httpClient] HTTP client for making requests to Horizon
  /// - [serverURI] Base URI of the Horizon server
  OperationsRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, ["operations"]);

  /// Requests specific uri and returns OperationResponse.
  /// This method is helpful for getting the links.
  Future<OperationResponse> operationURI(Uri uri) async {
    return RequestBuilder.requestExecute<OperationResponse>(httpClient, uri);
  }

  /// Provides information about a specific operation given by [operationId].
  /// See: [Stellar developer docs](https://developers.stellar.org)
  Future<OperationResponse> operation(String operationId) {
    this.setSegments(["operations", operationId]);
    return this.operationURI(this.buildUri());
  }

  /// Returns successful operations for a given account identified by [accountId].
  /// See: [Stellar developer docs](https://developers.stellar.org)
  OperationsRequestBuilder forAccount(String accountId) {
    this.setSegments(["accounts", accountId, "operations"]);
    return this;
  }

  /// Returns successful operations for a given claimable balance by [claimableBalanceId].
  /// See: [Stellar developer docs](https://developers.stellar.org)
  OperationsRequestBuilder forClaimableBalance(String claimableBalanceId) {
    final id = RequestBuilder.claimableBalanceIdHorizonHex(claimableBalanceId);
    this.setSegments(["claimable_balances", id, "operations"]);
    return this;
  }

  /// Returns successful operations in a specific ledger identified by [ledgerSeq].
  /// See: [Stellar developer docs](https://developers.stellar.org)
  OperationsRequestBuilder forLedger(int ledgerSeq) {
    this.setSegments(["ledgers", ledgerSeq.toString(), "operations"]);
    return this;
  }

  /// Returns successful operations for a specific transaction identiefied by [transactionId].
  /// See: [Stellar developer docs](https://developers.stellar.org)
  OperationsRequestBuilder forTransaction(String transactionId) {
    this.setSegments(["transactions", transactionId, "operations"]);
    return this;
  }

  /// Returns successful operations for a specific liquidity pool identified by [liquidityPoolId].
  /// The pool ID can be provided in either hex format or Stellar-encoded format (starting with 'L').
  /// See: [Stellar developer docs](https://developers.stellar.org)
  OperationsRequestBuilder forLiquidityPool(String liquidityPoolId) {
    var id = liquidityPoolId;
    if (id.startsWith("L")) {
      try {
        id = Util.bytesToHex(StrKey.decodeLiquidityPoolId(liquidityPoolId));
      } catch (_) {
        throw ArgumentError("invalid liquidity pool id: $liquidityPoolId");
      }
    }
    this.setSegments(["liquidity_pools", id, "operations"]);
    return this;
  }

  /// Adds a parameter defining whether to include operations of failed transactions. By default only operations of
  /// successful transactions are returned.
  OperationsRequestBuilder includeFailed(bool value) {
    queryParameters.addAll({"include_failed": value.toString()});
    return this;
  }

  // TODO: includeTransactions / join

  /// Requests specific `uri` and returns Page of OperationResponse.
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

  /// Build and execute the request.
  ///
  /// Returns a [Page] of [OperationResponse] objects containing the requested operations
  /// and pagination links for navigating through result sets.
  ///
  /// Example:
  /// ```dart
  /// final page = await sdk.operations.forAccount('account_id').limit(20).execute();
  /// for (var operation in page.records) {
  ///   print('Operation type: ${operation.type}');
  /// }
  /// // Get next page
  /// if (page.links.next != null) {
  ///   final nextPage = await sdk.operations.forAccount('account_id').cursor(page.records.last.pagingToken).execute();
  /// }
  /// ```
  Future<Page<OperationResponse>> execute() {
    return OperationsRequestBuilder.requestExecute(
        this.httpClient, this.buildUri());
  }

  /// Sets the cursor for pagination to start returning records from a specific point.
  /// Returns this builder for method chaining.
  @override
  OperationsRequestBuilder cursor(String token) {
    super.cursor(token);
    return this;
  }

  /// Sets the maximum number of records to return in a single page.
  /// Returns this builder for method chaining.
  @override
  OperationsRequestBuilder limit(int number) {
    super.limit(number);
    return this;
  }

  /// Sets the sort order for returned records (ascending or descending).
  /// Returns this builder for method chaining.
  @override
  OperationsRequestBuilder order(RequestBuilderOrder direction) {
    super.order(direction);
    return this;
  }
}
