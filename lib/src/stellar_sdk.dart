// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:http/http.dart' as http;
import 'package:stellar_flutter_sdk/src/requests/claimable_balance_request_builder.dart';
import 'dart:async';
import 'dart:convert';
import 'http_client_stub.dart' if (dart.library.io) 'http_client_io.dart';
import 'assets.dart';
import 'account_merge_operation.dart';
import 'constants/network_constants.dart';
import 'memo.dart';
import 'muxed_account.dart';
import 'operation.dart';
import 'path_payment_strict_receive_operation.dart';
import 'path_payment_strict_send_operation.dart';
import 'payment_operation.dart';
import 'requests/request_builder.dart';
import 'responses/account_response.dart';
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
/// - [Stellar developer docs](https://developers.stellar.org)
class StellarSDK {
  /// Current version of the Stellar Flutter SDK.
  static const versionNumber = "3.7.0";

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

  /// Creates a new StellarSDK instance pointing to the given Horizon URL.
  ///
  /// Initializes the SDK with a Horizon server endpoint and optional custom HTTP client.
  /// The HTTP client can be configured for proxy support (Tor, SOCKS5) or custom headers.
  ///
  /// Parameters:
  /// - [url] The base URL of the Horizon server (e.g., "https://horizon.stellar.org")
  /// - [httpClient] Optional custom HTTP client for proxy support. On native platforms
  ///   (iOS, Android), pass a `dart:io` `HttpClient`. On web, this parameter
  ///   is not supported; passing a non-null value throws [UnsupportedError]
  ///   (browsers handle HTTP internally).
  ///
  /// Example:
  /// ```dart
  /// // Connect to default testnet
  /// StellarSDK sdk = StellarSDK.TESTNET;
  ///
  /// // Connect to custom Horizon instance
  /// StellarSDK customSdk = StellarSDK("https://horizon.example.com");
  ///
  /// // Connect with Tor proxy (native platforms only)
  /// import 'dart:io';
  /// HttpClient torClient = HttpClient();
  /// torClient.findProxy = (uri) => "SOCKS5 localhost:9050";
  /// StellarSDK torSdk = StellarSDK(
  ///   "https://horizon.stellar.org",
  ///   httpClient: torClient,
  /// );
  /// ```
  ///
  /// **Platform notes:**
  /// - iOS/Android: Pass `HttpClient` from `dart:io` for proxy support
  /// - Web: Not supported; throws [UnsupportedError] if non-null
  StellarSDK(
    String url, {
    Object? httpClient,
  }) {
    _serverURI = Uri.parse(url);
    _httpClient = createHttpClient(httpClient);
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

  /// Sets global HTTP overrides for all HTTP connections (iOS/Android only).
  ///
  /// This allows you to override certificate verification or other
  /// low-level HTTP behavior. Use with caution as it affects all
  /// HTTP connections in the application.
  ///
  /// **Note:** This feature is only available on iOS and Android.
  /// On web, calling this setter throws [UnsupportedError] because
  /// browsers manage HTTP connections internally.
  ///
  /// Example (iOS/Android only):
  /// ```dart
  /// import 'dart:io';
  ///
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
  ///
  /// **Platform notes:**
  /// - iOS/Android: Pass an `HttpOverrides` subclass from `dart:io`
  /// - Web: Not supported; throws [UnsupportedError]
  set httpOverrides(Object httpOverrides) {
    setGlobalHttpOverrides(httpOverrides);
    _httpClient = http.Client();
  }

  /// Fetches the root endpoint information from the Horizon server.
  ///
  /// The root endpoint provides metadata about the Horizon instance, including
  /// network information, protocol version, and available endpoints.
  ///
  /// Returns: [RootResponse] containing server information
  ///
  /// Example:
  /// ```dart
  /// RootResponse rootInfo = await sdk.root();
  /// print("Network passphrase: ${rootInfo.networkPassphrase}");
  /// print("Protocol version: ${rootInfo.protocolVersion}");
  /// ```
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

  /// Account data entry key that marks an account as requiring a memo on
  /// incoming payments (SEP-29).
  static const String _memoRequiredDataKey = 'config.memo_required';

  /// Decoded value of [_memoRequiredDataKey] that activates the requirement.
  static const String _memoRequiredDataValue = '1';

  /// Checks whether [transaction] may be submitted without a memo (SEP-29).
  ///
  /// SEP-29 lets an account require a memo on incoming payments by setting its
  /// data entry `config.memo_required` to `1`. This method loads the
  /// destination accounts of the transaction from Horizon and throws
  /// [AccountRequiresMemoException] if one of them carries that entry while
  /// the transaction has no memo. The submit methods of this class run the
  /// same check by default.
  ///
  /// The check covers payment, path payment (strict send and strict receive)
  /// and account merge operations. A fee bump transaction is checked through
  /// its inner transaction. No request is made if the transaction carries a
  /// memo of any type other than [MemoNone], or if none of its operations
  /// names a destination that needs a lookup. Multiplexed (M...) destinations
  /// are not looked up, because the multiplexing id already identifies the
  /// recipient. Otherwise each distinct destination account is loaded once,
  /// sequentially and in operation order, until the first account that
  /// requires a memo. A destination that does not exist (Horizon answers 404)
  /// is skipped; the network then decides about the submission.
  ///
  /// Parameters:
  /// - [transaction] The [Transaction] or [FeeBumpTransaction] to check
  ///
  /// Throws:
  /// - [AccountRequiresMemoException] If the transaction has no memo and a
  ///   destination account requires one
  /// - [ErrorResponse] If a destination lookup fails with an HTTP status other
  ///   than 404
  /// - [TooManyRequestsException] If a destination lookup is rate limited
  /// - [http.ClientException] If a destination lookup fails at the transport
  ///   level
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   await sdk.checkMemoRequired(transaction);
  /// } on AccountRequiresMemoException catch (e) {
  ///   print("Memo required by ${e.accountId} (operation ${e.operationIndex})");
  /// }
  /// ```
  ///
  /// See also:
  /// - [AccountRequiresMemoException] for the reported account and operation
  /// - [SEP-29 specification](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0029.md)
  Future<void> checkMemoRequired(AbstractTransaction transaction) async {
    if (transaction is FeeBumpTransaction) {
      await _checkMemoRequiredForTransaction(transaction.innerTransaction);
    } else if (transaction is Transaction) {
      await _checkMemoRequiredForTransaction(transaction);
    }
  }

  /// Runs the SEP-29 check of [checkMemoRequired] on a [Transaction].
  Future<void> _checkMemoRequiredForTransaction(
      Transaction transaction) async {
    bool memoMissing =
        transaction.memo == null || transaction.memo is MemoNone;
    if (!memoMissing) {
      return;
    }

    // Distinct non-multiplexed destination account ids, in operation order,
    // each mapped to the index of the first operation that names it.
    Map<String, int> destinationIndexes = <String, int>{};
    List<Operation> operations = transaction.operations;
    for (int i = 0; i < operations.length; i++) {
      Operation operation = operations[i];
      MuxedAccount destination;
      if (operation is PaymentOperation) {
        destination = operation.destination;
      } else if (operation is PathPaymentStrictSendOperation) {
        destination = operation.destination;
      } else if (operation is PathPaymentStrictReceiveOperation) {
        destination = operation.destination;
      } else if (operation is AccountMergeOperation) {
        destination = operation.destination;
      } else {
        continue;
      }
      if (destination.id != null) {
        continue;
      }
      destinationIndexes.putIfAbsent(destination.ed25519AccountId, () => i);
    }

    for (String accountId in destinationIndexes.keys) {
      AccountResponse account;
      try {
        account = await accounts.account(accountId);
      } on ErrorResponse catch (e) {
        if (e.code == NetworkConstants.HTTP_NOT_FOUND) {
          continue;
        }
        rethrow;
      }
      AccountResponseData data = account.data;
      if (data.keys.contains(_memoRequiredDataKey) &&
          utf8.decode(data.getDecoded(_memoRequiredDataKey),
                  allowMalformed: true) ==
              _memoRequiredDataValue) {
        throw AccountRequiresMemoException(
            accountId, destinationIndexes[accountId]!);
      }
    }
  }

  /// Runs the SEP-29 check of [checkMemoRequired] on a base64-encoded
  /// transaction envelope.
  ///
  /// An envelope that cannot be decoded is not checked. It is submitted
  /// unchanged, so that Horizon reports the malformed envelope in its
  /// response.
  Future<void> _checkMemoRequiredForEnvelope(String envelope) async {
    AbstractTransaction transaction;
    try {
      transaction = AbstractTransaction.fromEnvelopeXdrString(envelope);
    } catch (_) {
      return;
    }
    await checkMemoRequired(transaction);
  }

  /// Submits a synchronous [transaction] to the network. Unlike the asynchronous version [submitAsyncTransaction],
  /// which relays the response from core directly back to the user, this endpoint blocks and waits for the transaction
  /// to be ingested in Horizon.
  ///
  /// Before submitting, the transaction is checked with [checkMemoRequired] (SEP-29). If the transaction has no memo,
  /// this costs one account lookup per distinct non-muxed destination. Set [skipMemoRequiredCheck] to `true` to submit
  /// without the SEP-29 memo-required check.
  ///
  /// Returns [SubmitTransactionTimeoutResponseException] If the response represents a timeout (status code: 504). The exception
  /// may contain the hash of the transaction if available, so that the result can be fetched later.
  ///
  /// Throws [AccountRequiresMemoException] if the transaction has no memo and a destination account requires one.
  /// Throws [ErrorResponse] or [TooManyRequestsException] if a destination account lookup of the memo-required check fails.
  /// A destination that does not exist (status code: 404) is skipped by the check.
  /// Throws [UnknownResponse] if the Horizon response could not be interpreted.
  /// Throws [http.ClientException] if there is a transport-level failure when communication with the server.
  /// For example, if the server could not be reached.
  /// See also: [Stellar developer docs](https://developers.stellar.org)
  Future<SubmitTransactionResponse> submitTransaction(Transaction transaction,
      {bool skipMemoRequiredCheck = false}) async {
    if (!skipMemoRequiredCheck) {
      await checkMemoRequired(transaction);
    }
    return submitTransactionEnvelopeXdrBase64(
        transaction.toEnvelopeXdrBase64(),
        skipMemoRequiredCheck: true);
  }

  /// Submits a synchronous [feeBumpTransaction] to the network. Unlike the asynchronous version [submitAsyncFeeBumpTransaction],
  /// which relays the response from core directly back to the user, this endpoint blocks and waits for the transaction
  /// to be ingested in Horizon.
  ///
  /// Before submitting, the inner transaction is checked with [checkMemoRequired] (SEP-29). If it has no memo,
  /// this costs one account lookup per distinct non-muxed destination. Set [skipMemoRequiredCheck] to `true` to submit
  /// without the SEP-29 memo-required check.
  ///
  /// Returns [SubmitTransactionTimeoutResponseException] If the response represents a timeout (status code: 504). The exception
  /// may contain the hash of the transaction if available, so that the result can be fetched later.
  ///
  /// Throws [AccountRequiresMemoException] if the inner transaction has no memo and a destination account requires one.
  /// Throws [ErrorResponse] or [TooManyRequestsException] if a destination account lookup of the memo-required check fails.
  /// A destination that does not exist (status code: 404) is skipped by the check.
  /// Throws [UnknownResponse] if the Horizon response could not be interpreted.
  /// Throws [http.ClientException] if there is a transport-level failure when communication with the server.
  /// For example, if the server could not be reached.
  /// See also: [Stellar developer docs](https://developers.stellar.org)
  Future<SubmitTransactionResponse> submitFeeBumpTransaction(
      FeeBumpTransaction feeBumpTransaction,
      {bool skipMemoRequiredCheck = false}) async {
    if (!skipMemoRequiredCheck) {
      await checkMemoRequired(feeBumpTransaction);
    }
    return submitTransactionEnvelopeXdrBase64(
        feeBumpTransaction.toEnvelopeXdrBase64(),
        skipMemoRequiredCheck: true);
  }

  /// Submits an asynchronous [transaction] to the network. Unlike the synchronous version [submitTransaction],
  /// which blocks and waits for the transaction to be ingested in Horizon, this endpoint relays the response from
  /// core directly back to the user. Returns [SubmitAsyncTransactionResponse].
  /// Before submitting, the transaction is checked with [checkMemoRequired] (SEP-29). If the transaction has no memo,
  /// this costs one account lookup per distinct non-muxed destination. Set [skipMemoRequiredCheck] to `true` to submit
  /// without the SEP-29 memo-required check.
  /// Throws [AccountRequiresMemoException] if the transaction has no memo and a destination account requires one.
  /// Throws [ErrorResponse] or [TooManyRequestsException] if a destination account lookup of the memo-required check fails.
  /// A destination that does not exist (status code: 404) is skipped by the check.
  /// Throws [SubmitAsyncTransactionProblem] if the Horizon response represents a known problem.
  /// Throws [UnknownResponse] if the Horizon response could not be interpreted.
  /// Throws [http.ClientException] if there is a transport-level failure when communication with the server.
  /// For example, if the server could not be reached.
  /// See also: [Stellar developer docs](https://developers.stellar.org)
  Future<SubmitAsyncTransactionResponse> submitAsyncTransaction(
      Transaction transaction,
      {bool skipMemoRequiredCheck = false}) async {
    if (!skipMemoRequiredCheck) {
      await checkMemoRequired(transaction);
    }
    return submitAsyncTransactionEnvelopeXdrBase64(
        transaction.toEnvelopeXdrBase64(),
        skipMemoRequiredCheck: true);
  }

  /// Submits an asynchronous [feeBumpTransaction] to the network. Unlike the synchronous version [submitFeeBumpTransaction],
  /// which blocks and waits for the transaction to be ingested in Horizon, this endpoint relays the response from
  /// core directly back to the user. Returns [SubmitAsyncTransactionResponse].
  /// Before submitting, the inner transaction is checked with [checkMemoRequired] (SEP-29). If it has no memo,
  /// this costs one account lookup per distinct non-muxed destination. Set [skipMemoRequiredCheck] to `true` to submit
  /// without the SEP-29 memo-required check.
  /// Throws [AccountRequiresMemoException] if the inner transaction has no memo and a destination account requires one.
  /// Throws [ErrorResponse] or [TooManyRequestsException] if a destination account lookup of the memo-required check fails.
  /// A destination that does not exist (status code: 404) is skipped by the check.
  /// Throws [SubmitAsyncTransactionProblem] if the Horizon response represents a known problem.
  /// Throws [UnknownResponse] if the Horizon response could not be interpreted.
  /// Throws [http.ClientException] if there is a transport-level failure when communication with the server.
  /// For example, if the server could not be reached.
  /// See also: [Stellar developer docs](https://developers.stellar.org)
  Future<SubmitAsyncTransactionResponse> submitAsyncFeeBumpTransaction(
      FeeBumpTransaction feeBumpTransaction,
      {bool skipMemoRequiredCheck = false}) async {
    if (!skipMemoRequiredCheck) {
      await checkMemoRequired(feeBumpTransaction);
    }
    return submitAsyncTransactionEnvelopeXdrBase64(
        feeBumpTransaction.toEnvelopeXdrBase64(),
        skipMemoRequiredCheck: true);
  }

  /// Submits a synchronous [transactionEnvelopeXdrBase64] String to the network. Unlike the asynchronous version [submitAsyncTransactionEnvelopeXdrBase64],
  /// which relays the response from core directly back to the user, this endpoint blocks and waits for the transaction
  /// to be ingested in Horizon.
  ///
  /// Before submitting, the envelope is decoded and the transaction is checked with [checkMemoRequired] (SEP-29).
  /// If the transaction has no memo, this costs one account lookup per distinct non-muxed destination. An envelope
  /// that cannot be decoded is not checked and is submitted unchanged. Set [skipMemoRequiredCheck] to `true` to submit
  /// without the SEP-29 memo-required check.
  ///
  /// Returns [SubmitTransactionTimeoutResponseException] If the response represents a timeout (status code: 504). The exception
  /// may contain the hash of the transaction if available, so that the result can be fetched later.
  ///
  /// Throws [AccountRequiresMemoException] if the transaction has no memo and a destination account requires one.
  /// Throws [ErrorResponse] or [TooManyRequestsException] if a destination account lookup of the memo-required check fails.
  /// A destination that does not exist (status code: 404) is skipped by the check.
  /// Throws [UnknownResponse] if the Horizon response could not be interpreted.
  /// Throws [http.ClientException] if there is a transport-level failure when communication with the server.
  /// For example, if the server could not be reached.
  /// See also: [Stellar developer docs](https://developers.stellar.org)
  Future<SubmitTransactionResponse> submitTransactionEnvelopeXdrBase64(
      String transactionEnvelopeXdrBase64,
      {bool skipMemoRequiredCheck = false}) async {
    if (!skipMemoRequiredCheck) {
      await _checkMemoRequiredForEnvelope(transactionEnvelopeXdrBase64);
    }
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
  /// Before submitting, the envelope is decoded and the transaction is checked with [checkMemoRequired] (SEP-29).
  /// If the transaction has no memo, this costs one account lookup per distinct non-muxed destination. An envelope
  /// that cannot be decoded is not checked and is submitted unchanged. Set [skipMemoRequiredCheck] to `true` to submit
  /// without the SEP-29 memo-required check.
  /// Throws [AccountRequiresMemoException] if the transaction has no memo and a destination account requires one.
  /// Throws [ErrorResponse] or [TooManyRequestsException] if a destination account lookup of the memo-required check fails.
  /// A destination that does not exist (status code: 404) is skipped by the check.
  /// Throws [SubmitAsyncTransactionProblem] if the Horizon response represents a known problem.
  /// Throws [UnknownResponse] if the Horizon response could not be interpreted.
  /// Throws [http.ClientException] if there is a transport-level failure when communication with the server.
  /// For example, if the server could not be reached.
  /// See also: [Stellar developer docs](https://developers.stellar.org)
  Future<SubmitAsyncTransactionResponse>
      submitAsyncTransactionEnvelopeXdrBase64(
          String transactionEnvelopeXdrBase64,
          {bool skipMemoRequiredCheck = false}) async {
    if (!skipMemoRequiredCheck) {
      await _checkMemoRequiredForEnvelope(transactionEnvelopeXdrBase64);
    }
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

/// Exception thrown when a transaction without a memo pays an account that
/// requires one (SEP-29).
///
/// An account requires a memo on incoming payments when its data entry
/// `config.memo_required` is set to `1`. The submit methods of [StellarSDK]
/// and [StellarSDK.checkMemoRequired] throw this exception before anything is
/// submitted, when the checked transaction carries no memo and one of its
/// payment, path payment or account merge operations names such an account as
/// a non-multiplexed destination.
///
/// Example:
/// ```dart
/// try {
///   await sdk.submitTransaction(transaction);
/// } on AccountRequiresMemoException catch (e) {
///   print("Account ${e.accountId} requires a memo "
///       "(operation ${e.operationIndex})");
/// }
/// ```
///
/// See also:
/// - [StellarSDK.checkMemoRequired] for running the check without submitting
/// - [SEP-29 specification](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0029.md)
class AccountRequiresMemoException implements Exception {
  /// The account id (G...) of the destination account that requires a memo.
  final String accountId;

  /// The zero-based index, over all operations of the checked transaction, of
  /// the first payment, path payment or account merge operation that names
  /// [accountId] as a non-multiplexed destination.
  final int operationIndex;

  /// Creates an exception for the destination [accountId] named by the
  /// operation at [operationIndex].
  AccountRequiresMemoException(this.accountId, this.operationIndex);

  String toString() {
    return "Destination account $accountId of operation $operationIndex "
        "requires a memo in the transaction.";
  }
}
