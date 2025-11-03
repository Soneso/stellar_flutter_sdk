// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:stellar_flutter_sdk/src/requests/claimable_balance_request_builder.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'assets.dart';
import 'requests/request_builder.dart';
import 'responses/response.dart';
import 'responses/root_response.dart';
import 'responses/submit_transaction_response.dart';
import 'transaction.dart';
import 'requests/accounts_request_builder.dart';
import 'requests/assets_request_builder.dart';
import 'requests/effects_request_builder.dart';
import 'requests/ledgers_request_builder.dart';
import 'requests/offers_request_builder.dart';
import 'requests/fee_stats_request_builder.dart';
import 'requests/operations_request_builder.dart';
import 'requests/transactions_request_builder.dart';
import 'requests/order_book_request_builder.dart';
import 'requests/path_request_builder.dart';
import 'requests/payments_request_builder.dart';
import 'requests/trade_aggregations_request_builder.dart';
import 'requests/trades_request_builder.dart';
import 'requests/liquidity_pools_request_builder.dart';
import 'requests/health_request_builder.dart';

/// Main entry point for interacting with the Stellar network via Horizon API.
///
/// The StellarSDK class provides access to all Horizon API endpoints for querying
/// the Stellar ledger, submitting transactions, and streaming real-time updates.
/// It is the primary interface for building Stellar applications.
///
/// Capabilities:
/// - Query accounts, assets, transactions, operations, and effects
/// - Submit transactions to the network (synchronous and asynchronous)
/// - Stream real-time updates for ledger changes
/// - Access order books, trades, and liquidity pools
/// - Configure custom HTTP clients (proxy, Tor support)
///
/// Available Networks:
/// - [PUBLIC]: Production Stellar network (mainnet)
/// - [TESTNET]: Test network for development
/// - [FUTURENET]: Network for testing upcoming protocol features
///
/// Basic usage:
/// ```dart
/// // Connect to testnet
/// StellarSDK sdk = StellarSDK.TESTNET;
///
/// // Or connect to custom Horizon instance
/// StellarSDK customSdk = StellarSDK("https://custom-horizon.example.com");
///
/// // Query account
/// AccountResponse account = await sdk.accounts.account("GABC...");
///
/// // Build and submit transaction
/// Transaction transaction = TransactionBuilder(sourceAccount)
///   .addOperation(PaymentOperation(...))
///   .build();
///
/// transaction.sign(keyPair, Network.TESTNET);
/// SubmitTransactionResponse response = await sdk.submitTransaction(transaction);
///
/// if (response.success) {
///   print("Transaction hash: ${response.hash}");
/// }
/// ```
///
/// Request builders (property access):
/// - [accounts]: Query and stream account data
/// - [assets]: Query asset information
/// - [effects]: Query effects from operations
/// - [ledgers]: Query ledger data
/// - [offers]: Query offers and order books
/// - [operations]: Query operation data
/// - [payments]: Query payment operations
/// - [transactions]: Query transaction data
/// - [trades]: Query trade execution data
/// - [liquidityPools]: Query liquidity pool data
/// - [feeStats]: Query current fee statistics
/// - [health]: Check Horizon server health
///
/// Advanced features:
/// ```dart
/// // Custom HTTP client (e.g., for Tor/SOCKS5 proxy)
/// HttpClient httpClient = HttpClient();
/// httpClient.findProxy = (uri) {
///   return "SOCKS5 localhost:9050"; // Tor proxy
/// };
/// StellarSDK sdk = StellarSDK(
///   "https://horizon.stellar.org",
///   httpClient: httpClient
/// );
///
/// // Asynchronous transaction submission
/// SubmitAsyncTransactionResponse asyncResponse =
///   await sdk.submitAsyncTransaction(transaction);
///
/// // Stream payments to account
/// sdk.payments.forAccount(accountId).cursor("now").stream().listen((payment) {
///   print("Received payment: ${payment.amount} ${payment.assetCode}");
/// });
/// ```
///
/// Important notes:
/// - Always use TESTNET for development and testing
/// - Sign transactions with the correct network passphrase
/// - Handle errors appropriately (network failures, transaction failures)
/// - Consider rate limiting when making frequent API calls
/// - Use streaming endpoints carefully to avoid resource leaks
///
/// See also:
/// - [Transaction] for building and signing transactions
/// - [Network] for network passphrase configuration
/// - [Horizon API Documentation](https://developers.stellar.org/docs/data/horizon/api-reference)
class StellarSDK {
  /// Current version of the Stellar Flutter SDK.
  static const versionNumber = "2.1.7";

  /// Pre-configured instance for the Stellar production network (mainnet).
  ///
  /// Use this for real transactions with actual funds. Points to the public
  /// Horizon instance at https://horizon.stellar.org.
  ///
  /// Example:
  /// ```dart
  /// StellarSDK sdk = StellarSDK.PUBLIC;
  /// ```
  static final StellarSDK PUBLIC = StellarSDK("https://horizon.stellar.org");

  /// Pre-configured instance for the Stellar test network.
  ///
  /// Use this for development and testing. Test XLM can be obtained from
  /// friendbot. Points to https://horizon-testnet.stellar.org.
  ///
  /// Example:
  /// ```dart
  /// StellarSDK sdk = StellarSDK.TESTNET;
  /// ```
  static final StellarSDK TESTNET =
      StellarSDK("https://horizon-testnet.stellar.org");

  /// Pre-configured instance for the Stellar future network.
  ///
  /// Use this to test upcoming protocol features before they reach testnet
  /// and mainnet. Points to https://horizon-futurenet.stellar.org.
  ///
  /// Example:
  /// ```dart
  /// StellarSDK sdk = StellarSDK.FUTURENET;
  /// ```
  static final StellarSDK FUTURENET =
      StellarSDK("https://horizon-futurenet.stellar.org");

  late Uri _serverURI;
  late http.Client _httpClient;

  /// Creates a new StellarSDK instance pointing to the given Horizon [url].
  ///
  /// Parameters:
  /// - [url]: The base URL of the Horizon server (e.g., "https://horizon.stellar.org")
  /// - [httpClient]: Optional custom HttpClient for proxy support (Tor, SOCKS5, etc.)
  ///
  /// Example:
  /// ```dart
  /// // Connect to default testnet
  /// StellarSDK sdk = StellarSDK.TESTNET;
  ///
  /// // Connect to custom Horizon instance
  /// StellarSDK customSdk = StellarSDK("https://horizon.example.com");
  ///
  /// // Connect with Tor proxy
  /// HttpClient torClient = HttpClient();
  /// torClient.findProxy = (uri) => "SOCKS5 localhost:9050";
  /// StellarSDK torSdk = StellarSDK(
  ///   "https://horizon.stellar.org",
  ///   httpClient: torClient
  /// );
  /// ```
  StellarSDK(
    String url, {
    HttpClient? httpClient, // Optional client for proxy (Tor/SOCKS5) support.
  }) {
    _serverURI = Uri.parse(url);
    _httpClient = httpClient != null ? IOClient(httpClient) : http.Client();
  }

  /// Gets the HTTP client used for making requests to Horizon.
  ///
  /// The client can be customized for advanced use cases like proxy support.
  http.Client get httpClient => _httpClient;

  /// Sets a custom HTTP client for making requests to Horizon.
  ///
  /// Use this to configure proxy settings, custom headers, or other
  /// HTTP client behavior.
  ///
  /// Example:
  /// ```dart
  /// StellarSDK sdk = StellarSDK.TESTNET;
  /// sdk.httpClient = customClient;
  /// ```
  set httpClient(http.Client httpClient) {
    this._httpClient = httpClient;
  }

  /// Sets global HTTP overrides for all HTTP connections.
  ///
  /// This allows you to override certificate verification or other
  /// low-level HTTP behavior. Use with caution as it affects all
  /// HTTP connections in the application.
  ///
  /// Example:
  /// ```dart
  /// class MyHttpOverrides extends HttpOverrides {
  ///   HttpClient createHttpClient(SecurityContext? context) {
  ///     return super.createHttpClient(context)
  ///       ..badCertificateCallback = (cert, host, port) => true;
  ///   }
  /// }
  ///
  /// StellarSDK sdk = StellarSDK.TESTNET;
  /// sdk.httpOverrides = MyHttpOverrides();
  /// ```
  set httpOverrides(HttpOverrides httpOverrides) {
    HttpOverrides.global = httpOverrides;
    _httpClient = http.Client();
  }

  /// Returns [RootResponse].
  Future<RootResponse> root() async {
    TypeToken<RootResponse> type = TypeToken<RootResponse>();
    ResponseHandler<RootResponse> responseHandler =
        ResponseHandler<RootResponse>(type);

    return await httpClient.get(_serverURI).then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  /// Returns a new [AccountsRequestBuilder] instance.
  AccountsRequestBuilder get accounts =>
      AccountsRequestBuilder(httpClient, _serverURI);

  /// Returns a new [AssetsRequestBuilder] instance.
  AssetsRequestBuilder get assets =>
      AssetsRequestBuilder(httpClient, _serverURI);

  /// Returns a new [EffectsRequestBuilder] instance.
  EffectsRequestBuilder get effects =>
      EffectsRequestBuilder(httpClient, _serverURI);

  /// Returns a new [LedgersRequestBuilder] instance.
  LedgersRequestBuilder get ledgers =>
      LedgersRequestBuilder(httpClient, _serverURI);

  /// Returns a new [OffersRequestBuilder] instance.
  OffersRequestBuilder get offers =>
      OffersRequestBuilder(httpClient, _serverURI);

  /// Returns a new [OperationsRequestBuilder] instance.
  OperationsRequestBuilder get operations =>
      OperationsRequestBuilder(httpClient, _serverURI);

  /// Returns a new [FeeStatsRequestBuilder] instance.
  FeeStatsRequestBuilder get feeStats =>
      FeeStatsRequestBuilder(httpClient, _serverURI);

  /// Returns a new [HealthRequestBuilder] instance.
  HealthRequestBuilder get health =>
      HealthRequestBuilder(httpClient, _serverURI);

  /// Returns a new [OrderBookRequestBuilder] instance.
  OrderBookRequestBuilder get orderBook =>
      OrderBookRequestBuilder(httpClient, _serverURI);

  /// Returns a new [TradesRequestBuilder] instance.
  TradesRequestBuilder get trades =>
      TradesRequestBuilder(httpClient, _serverURI);

  /// Returns a new [ClaimableBalancesRequestBuilder] instance.
  ClaimableBalancesRequestBuilder get claimableBalances =>
      ClaimableBalancesRequestBuilder(httpClient, _serverURI);

  /// Returns a new [TradeAggregationsRequestBuilder] instance.
  TradeAggregationsRequestBuilder tradeAggregations(
      Asset baseAsset,
      Asset counterAsset,
      int startTime,
      int endTime,
      int resolution,
      int offset) {
    return TradeAggregationsRequestBuilder(httpClient, _serverURI, baseAsset,
        counterAsset, startTime, endTime, resolution, offset);
  }

  /// Returns a new [StrictSendPathsRequestBuilder] instance.
  StrictSendPathsRequestBuilder get strictSendPaths =>
      StrictSendPathsRequestBuilder(httpClient, _serverURI);

  /// Returns a new [StrictReceivePathsRequestBuilder] instance.
  StrictReceivePathsRequestBuilder get strictReceivePaths =>
      StrictReceivePathsRequestBuilder(httpClient, _serverURI);

  /// Returns a new [PaymentsRequestBuilder] instance.
  PaymentsRequestBuilder get payments =>
      PaymentsRequestBuilder(httpClient, _serverURI);

  /// Returns a new [TransactionsRequestBuilder] instance.
  TransactionsRequestBuilder get transactions =>
      TransactionsRequestBuilder(httpClient, _serverURI);

  /// Returns a new [LiquidityPoolsRequestBuilder] instance.
  LiquidityPoolsRequestBuilder get liquidityPools =>
      LiquidityPoolsRequestBuilder(httpClient, _serverURI);

  /// Returns a new [LiquidityPoolTradesRequestBuilder] instance.
  LiquidityPoolTradesRequestBuilder get liquidityPoolTrades =>
      LiquidityPoolTradesRequestBuilder(httpClient, _serverURI);

  /// Submits a synchronous [transaction] to the network. Unlike the asynchronous version [submitAsyncTransaction],
  /// which relays the response from core directly back to the user, this endpoint blocks and waits for the transaction
  /// to be ingested in Horizon.
  ///
  /// Returns [SubmitTransactionTimeoutResponseException] If the response represents a timeout (status code: 504). The exception
  /// may contain the hash of the transaction if available, so that the result can be fetched later.
  ///
  /// Throws [UnknownResponse] if the Horizon response could not be interpreted.
  /// Throws [http.ClientException] if there is a transport-level failure when communication with the server.
  /// For example, if the server could not be reached.
  /// See also: https://developers.stellar.org/docs/data/horizon/api-reference/submit-a-transaction
  Future<SubmitTransactionResponse> submitTransaction(
      Transaction transaction) async {
    return submitTransactionEnvelopeXdrBase64(
        transaction.toEnvelopeXdrBase64());
  }

  /// Submits a synchronous [feeBumpTransaction] to the network. Unlike the asynchronous version [submitAsyncFeeBumpTransaction],
  /// which relays the response from core directly back to the user, this endpoint blocks and waits for the transaction
  /// to be ingested in Horizon.
  ///
  /// Returns [SubmitTransactionTimeoutResponseException] If the response represents a timeout (status code: 504). The exception
  /// may contain the hash of the transaction if available, so that the result can be fetched later.
  ///
  /// Throws [UnknownResponse] if the Horizon response could not be interpreted.
  /// Throws [http.ClientException] if there is a transport-level failure when communication with the server.
  /// For example, if the server could not be reached.
  /// See also: https://developers.stellar.org/docs/data/horizon/api-reference/submit-a-transaction
  Future<SubmitTransactionResponse> submitFeeBumpTransaction(
      FeeBumpTransaction feeBumpTransaction) async {
    return submitTransactionEnvelopeXdrBase64(
        feeBumpTransaction.toEnvelopeXdrBase64());
  }

  /// Submits an asynchronous [transaction] to the network. Unlike the synchronous version [submitTransaction],
  /// which blocks and waits for the transaction to be ingested in Horizon, this endpoint relays the response from
  /// core directly back to the user. Returns [SubmitAsyncTransactionResponse].
  /// Throws [SubmitAsyncTransactionProblem] if the Horizon response represents a known problem.
  /// Throws [UnknownResponse] if the Horizon response could not be interpreted.
  /// Throws [http.ClientException] if there is a transport-level failure when communication with the server.
  /// For example, if the server could not be reached.
  /// See also: https://developers.stellar.org/docs/data/horizon/api-reference/submit-async-transaction
  Future<SubmitAsyncTransactionResponse> submitAsyncTransaction(
      Transaction transaction) async {
    return submitAsyncTransactionEnvelopeXdrBase64(
        transaction.toEnvelopeXdrBase64());
  }

  /// Submits an asynchronous [feeBumpTransaction] to the network. Unlike the synchronous version [submitFeeBumpTransaction],
  /// which blocks and waits for the transaction to be ingested in Horizon, this endpoint relays the response from
  /// core directly back to the user. Returns [SubmitAsyncTransactionResponse].
  /// Throws [SubmitAsyncTransactionProblem] if the Horizon response represents a known problem.
  /// Throws [UnknownResponse] if the Horizon response could not be interpreted.
  /// Throws [http.ClientException] if there is a transport-level failure when communication with the server.
  /// For example, if the server could not be reached.
  /// See also: https://developers.stellar.org/docs/data/horizon/api-reference/submit-async-transaction
  Future<SubmitAsyncTransactionResponse> submitAsyncFeeBumpTransaction(
      FeeBumpTransaction feeBumpTransaction) async {
    return submitAsyncTransactionEnvelopeXdrBase64(
        feeBumpTransaction.toEnvelopeXdrBase64());
  }

  /// Submits a synchronous [transactionEnvelopeXdrBase64] String to the network. Unlike the asynchronous version [submitAsyncTransactionEnvelopeXdrBase64],
  /// which relays the response from core directly back to the user, this endpoint blocks and waits for the transaction
  /// to be ingested in Horizon.
  ///
  /// Returns [SubmitTransactionTimeoutResponseException] If the response represents a timeout (status code: 504). The exception
  /// may contain the hash of the transaction if available, so that the result can be fetched later.
  ///
  /// Throws [UnknownResponse] if the Horizon response could not be interpreted.
  /// Throws [http.ClientException] if there is a transport-level failure when communication with the server.
  /// For example, if the server could not be reached.
  /// See also: https://developers.stellar.org/docs/data/horizon/api-reference/submit-a-transaction
  Future<SubmitTransactionResponse> submitTransactionEnvelopeXdrBase64(
      String transactionEnvelopeXdrBase64) async {
    Uri callURI = _serverURI.replace(pathSegments: ["transactions"]);

    //print("Envelope XDR: " + transaction.toEnvelopeXdrBase64());
    SubmitTransactionResponse result = await _httpClient
        .post(callURI,
            body: {"tx": transactionEnvelopeXdrBase64},
            headers: RequestBuilder.headers)
        .then((response) {
      SubmitTransactionResponse submitTransactionResponse;
      //print(response.body);
      switch (response.statusCode) {
        case 200:
        case 400:
          submitTransactionResponse =
              SubmitTransactionResponse.fromJson(json.decode(response.body));
          break;
        case 504:
          throw SubmitTransactionTimeoutResponseException.fromJson(
              json.decode(response.body));
        default:
          throw UnknownResponse(response.statusCode, response.body);
      }
      return submitTransactionResponse;
    }).catchError((onError) {
      throw onError;
    });

    return result;
  }

  /// Submits an asynchronous [transactionEnvelopeXdrBase64] String to the network. Unlike the synchronous version [submitTransactionEnvelopeXdrBase64],
  /// which blocks and waits for the transaction to be ingested in Horizon, this endpoint relays the response from
  /// core directly back to the user. Returns [SubmitAsyncTransactionResponse].
  /// Throws [SubmitAsyncTransactionProblem] if the Horizon response represents a known problem.
  /// Throws [UnknownResponse] if the Horizon response could not be interpreted.
  /// Throws [http.ClientException] if there is a transport-level failure when communication with the server.
  /// For example, if the server could not be reached.
  /// See also: https://developers.stellar.org/docs/data/horizon/api-reference/submit-async-transaction
  Future<SubmitAsyncTransactionResponse>
      submitAsyncTransactionEnvelopeXdrBase64(
          String transactionEnvelopeXdrBase64) async {
    Uri callURI = _serverURI.replace(pathSegments: ["transactions_async"]);

    SubmitAsyncTransactionResponse result = await _httpClient
        .post(callURI,
            body: {"tx": transactionEnvelopeXdrBase64},
            headers: RequestBuilder.headers)
        .then((response) {
      SubmitAsyncTransactionResponse submitTransactionResponse;
      //print(response.body);
      switch (response.statusCode) {
        case 201:
          submitTransactionResponse = SubmitAsyncTransactionResponse.fromJson(
              json.decode(response.body), response.statusCode);
          break;
        case 400:
        case 403:
        case 409:
        case 500:
        case 503:
          Map<String, dynamic> data = json.decode(response.body);
          if (data.containsKey('tx_status')) {
            submitTransactionResponse = SubmitAsyncTransactionResponse.fromJson(
                data, response.statusCode);
          } else if (data.containsKey('type')) {
            throw SubmitAsyncTransactionProblem.fromJson(data);
          } else {
            throw UnknownResponse(response.statusCode, response.body);
          }
          break;
        default:
          throw UnknownResponse(response.statusCode, response.body);
      }
      return submitTransactionResponse;
    }).catchError((onError) {
      throw onError;
    });

    return result;
  }
}
