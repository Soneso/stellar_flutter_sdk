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

/// Main class of the flutter stellar sdk.
class StellarSDK {
  static const versionNumber = "1.8.3";

  static final StellarSDK PUBLIC = StellarSDK("https://horizon.stellar.org");
  static final StellarSDK TESTNET =
      StellarSDK("https://horizon-testnet.stellar.org");
  static final StellarSDK FUTURENET =
      StellarSDK("https://horizon-futurenet.stellar.org");

  late Uri _serverURI;
  late http.Client _httpClient;

  StellarSDK(
    String url, {
    HttpClient? httpClient, // Optional client for proxy (Tor/SOCKS5) support.
  }) {
    _serverURI = Uri.parse(url);
    _httpClient = httpClient != null ? IOClient(httpClient) : http.Client();
  }

  http.Client get httpClient => _httpClient;

  set httpClient(http.Client httpClient) {
    this._httpClient = httpClient;
  }

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

  /// Returns a new [FeeStatsResponse] instance.
  FeeStatsRequestBuilder get feeStats =>
      FeeStatsRequestBuilder(httpClient, _serverURI);

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
          throw SubmitTransactionTimeoutResponseException();
        default:
          throw SubmitTransactionUnknownResponseException(
              response.statusCode, response.body);
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
          } else if (data.containsKey('type')){
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
