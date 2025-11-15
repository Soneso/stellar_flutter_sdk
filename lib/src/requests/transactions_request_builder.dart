// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:stellar_flutter_sdk/src/key_pair.dart';
import 'package:stellar_flutter_sdk/src/util.dart';

import "../eventsource/eventsource.dart";
import '../responses/response.dart';
import '../responses/transaction_response.dart';
import 'request_builder.dart';

/// Builder for requests to the transactions endpoint.
///
/// TransactionsRequestBuilder provides methods for querying transaction data
/// from the Horizon server. Transactions are commands that modify the ledger
/// state and consist of one or more operations.
///
/// Example:
/// ```dart
/// // Get a specific transaction
/// var tx = await sdk.transactions.transaction(txHash);
///
/// // Get transactions for an account
/// var txs = await sdk.transactions
///     .forAccount(accountId)
///     .order(RequestBuilderOrder.DESC)
///     .limit(10)
///     .execute();
///
/// // Include failed transactions
/// var allTxs = await sdk.transactions
///     .forAccount(accountId)
///     .includeFailed(true)
///     .execute();
///
/// // Stream new transactions
/// sdk.transactions.cursor('now').stream().listen((tx) {
///   print('New transaction: ${tx.id}');
/// });
/// ```
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
class TransactionsRequestBuilder extends RequestBuilder {
  /// Creates a TransactionsRequestBuilder for querying transactions from Horizon.
  ///
  /// This constructor is typically called internally by the SDK. Use [StellarSDK.transactions]
  /// to access transaction query functionality.
  ///
  /// Parameters:
  /// - [httpClient] HTTP client for making requests to Horizon
  /// - [serverURI] Base URI of the Horizon server
  TransactionsRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, ["transactions"]);

  /// Retrieves a specific transaction by its hash.
  ///
  /// Parameters:
  /// - transactionId: The transaction hash to retrieve
  ///
  /// Returns: TransactionResponse containing transaction details
  ///
  /// Example:
  /// ```dart
  /// var tx = await sdk.transactions.transaction(
  ///   '3389e9f0f1a65f19736cacf544c2e825313e8447f569233bb8db39aa607c8889'
  /// );
  /// print('Fee: ${tx.feeCharged}');
  /// ```
  ///
  /// See also:
  /// - [Stellar developer docs](https://developers.stellar.org)
  Future<TransactionResponse> transaction(String transactionId) {
    this.setSegments(["transactions", transactionId]);
    return this.transactionURI(this.buildUri());
  }

  /// Filters transactions by account.
  ///
  /// Returns all successful transactions for the specified account.
  ///
  /// Parameters:
  /// - accountId: The account public key
  ///
  /// Returns: This builder instance for method chaining
  ///
  /// Example:
  /// ```dart
  /// var txs = await sdk.transactions
  ///     .forAccount('GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B')
  ///     .order(RequestBuilderOrder.DESC)
  ///     .execute();
  /// ```
  ///
  /// See also:
  /// - [Stellar developer docs](https://developers.stellar.org)
  TransactionsRequestBuilder forAccount(String accountId) {
    this.setSegments(["accounts", accountId, "transactions"]);
    return this;
  }

  /// Filters transactions by claimable balance.
  ///
  /// Returns all transactions that affect the specified claimable balance.
  ///
  /// Parameters:
  /// - claimableBalanceId: The claimable balance ID (hex or B-prefixed)
  ///
  /// Returns: This builder instance for method chaining
  ///
  /// Example:
  /// ```dart
  /// var txs = await sdk.transactions
  ///     .forClaimableBalance(claimableBalanceId)
  ///     .execute();
  /// ```
  ///
  /// See also:
  /// - [Stellar developer docs](https://developers.stellar.org)
  TransactionsRequestBuilder forClaimableBalance(String claimableBalanceId) {
    var id = claimableBalanceId;
    if (id.startsWith("B")) {
      try {
        id = Util.bytesToHex(
            StrKey.decodeClaimableBalanceId(claimableBalanceId));
      } catch (_) {}
    }
    this.setSegments(["claimable_balances", id, "transactions"]);
    return this;
  }

  /// Filters transactions by ledger sequence number.
  ///
  /// Returns all transactions that occurred in the specified ledger.
  ///
  /// Parameters:
  /// - ledgerSeq: The ledger sequence number
  ///
  /// Returns: This builder instance for method chaining
  ///
  /// Example:
  /// ```dart
  /// var txs = await sdk.transactions
  ///     .forLedger(12345)
  ///     .execute();
  /// ```
  ///
  /// See also:
  /// - [Stellar developer docs](https://developers.stellar.org)
  TransactionsRequestBuilder forLedger(int ledgerSeq) {
    this.setSegments(["ledgers", ledgerSeq.toString(), "transactions"]);
    return this;
  }

  /// Filters transactions by liquidity pool.
  ///
  /// Returns all transactions that affect the specified liquidity pool.
  ///
  /// Parameters:
  /// - liquidityPoolId: The liquidity pool ID (hex or L-prefixed)
  ///
  /// Returns: This builder instance for method chaining
  ///
  /// Example:
  /// ```dart
  /// var txs = await sdk.transactions
  ///     .forLiquidityPool(poolId)
  ///     .execute();
  /// ```
  TransactionsRequestBuilder forLiquidityPool(String liquidityPoolId) {
    var id = liquidityPoolId;
    if (id.startsWith("L")) {
      try {
        id = Util.bytesToHex(StrKey.decodeLiquidityPoolId(liquidityPoolId));
      } catch (_) {}
    }
    this.setSegments(["liquidity_pools", id, "transactions"]);
    return this;
  }

  /// Configures whether to include failed transactions in results.
  ///
  /// By default, only successful transactions are returned. Set to true
  /// to include transactions that failed during execution.
  ///
  /// Parameters:
  /// - value: Whether to include failed transactions
  ///
  /// Returns: This builder instance for method chaining
  ///
  /// Example:
  /// ```dart
  /// // Get all transactions including failed ones
  /// var txs = await sdk.transactions
  ///     .forAccount(accountId)
  ///     .includeFailed(true)
  ///     .execute();
  ///
  /// for (var tx in txs.records) {
  ///   print('TX ${tx.id}: ${tx.successful ? "success" : "failed"}');
  /// }
  /// ```
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

  /// Opens a stream to listen for transactions in real-time.
  ///
  /// Uses Server-Sent Events (SSE) to maintain an open connection to Horizon.
  /// The stream will emit TransactionResponse objects as transactions are
  /// confirmed on the ledger.
  ///
  /// Returns: Stream of TransactionResponse objects
  ///
  /// Example:
  /// ```dart
  /// // Stream new transactions for an account
  /// sdk.transactions
  ///     .forAccount(accountId)
  ///     .cursor('now')
  ///     .stream()
  ///     .listen((tx) {
  ///       print('New transaction: ${tx.id}');
  ///       print('Operations: ${tx.operationCount}');
  ///     });
  /// ```
  ///
  /// See also:
  /// - [Stellar developer docs](https://developers.stellar.org)
  Stream<TransactionResponse> stream() {
    StreamController<TransactionResponse> listener =
        StreamController.broadcast();

    bool cancelled = false;
    EventSource? source;

    /// Creates a new EventSource connection to stream transaction updates from Horizon.
    /// Automatically reconnects when the connection closes to maintain continuous streaming.
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

  /// Builds and executes the request.
  ///
  /// Returns: Page of TransactionResponse objects
  ///
  /// Example:
  /// ```dart
  /// var page = await sdk.transactions
  ///     .forAccount(accountId)
  ///     .order(RequestBuilderOrder.DESC)
  ///     .limit(20)
  ///     .execute();
  ///
  /// for (var tx in page.records) {
  ///   print('Transaction: ${tx.id}');
  ///   print('Fee charged: ${tx.feeCharged}');
  /// }
  /// ```
  Future<Page<TransactionResponse>> execute() {
    return TransactionsRequestBuilder.requestExecute(
        this.httpClient, this.buildUri());
  }

  /// Sets the cursor for pagination to start returning records from a specific point.
  /// Returns this builder for method chaining.
  @override
  TransactionsRequestBuilder cursor(String token) {
    super.cursor(token);
    return this;
  }

  /// Sets the maximum number of records to return in a single page.
  /// Returns this builder for method chaining.
  @override
  TransactionsRequestBuilder limit(int number) {
    super.limit(number);
    return this;
  }

  /// Sets the sort order for returned records (ascending or descending).
  /// Returns this builder for method chaining.
  @override
  TransactionsRequestBuilder order(RequestBuilderOrder direction) {
    super.order(direction);
    return this;
  }
}
