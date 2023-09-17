// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:stellar_flutter_sdk/src/requests/claimable_balance_request_builder.dart';
import 'dart:async';
import 'dart:convert';
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
  static const versionNumber = "1.6.3";

  static final StellarSDK PUBLIC = StellarSDK("https://horizon.stellar.org");
  static final StellarSDK TESTNET = StellarSDK("https://horizon-testnet.stellar.org");
  static final StellarSDK FUTURENET = StellarSDK("https://horizon-futurenet.stellar.org");

  late Uri _serverURI;
  late http.Client _httpClient;

  StellarSDK(String url) {
    _serverURI = Uri.parse(url);
    _httpClient = http.Client();
  }

  http.Client get httpClient => _httpClient;

  set httpClient(http.Client httpClient) {
    this._httpClient = httpClient;
  }

  set httpOverrides(HttpOverrides httpOverrides) {
    HttpOverrides.global = httpOverrides;
    _httpClient = http.Client();
  }

  /// Returns RootResponse.
  Future<RootResponse> root() async {
    TypeToken<RootResponse> type = TypeToken<RootResponse>();
    ResponseHandler<RootResponse> responseHandler = ResponseHandler<RootResponse>(type);

    return await httpClient.get(_serverURI).then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  /// Returns AccountsRequestBuilder instance.
  AccountsRequestBuilder get accounts => AccountsRequestBuilder(httpClient, _serverURI);

  /// Returns AssetsRequestBuilder instance.
  AssetsRequestBuilder get assets => AssetsRequestBuilder(httpClient, _serverURI);

  /// Returns EffectsRequestBuilder instance.
  EffectsRequestBuilder get effects => EffectsRequestBuilder(httpClient, _serverURI);

  /// Returns LedgersRequestBuilder instance.
  LedgersRequestBuilder get ledgers => LedgersRequestBuilder(httpClient, _serverURI);

  /// Returns OffersRequestBuilder instance.
  OffersRequestBuilder get offers => OffersRequestBuilder(httpClient, _serverURI);

  /// Returns OperationsRequestBuilder instance.
  OperationsRequestBuilder get operations => OperationsRequestBuilder(httpClient, _serverURI);

  /// Returns FeeStatsResponse instance.
  FeeStatsRequestBuilder get feeStats => FeeStatsRequestBuilder(httpClient, _serverURI);

  /// Returns OrderBookRequestBuilder instance.
  OrderBookRequestBuilder get orderBook => OrderBookRequestBuilder(httpClient, _serverURI);

  /// Returns TradesRequestBuilder instance.
  TradesRequestBuilder get trades => TradesRequestBuilder(httpClient, _serverURI);

  ClaimableBalancesRequestBuilder get claimableBalances =>
      ClaimableBalancesRequestBuilder(httpClient, _serverURI);

  /// Returns TradeAggregationsRequestBuilder instance.
  TradeAggregationsRequestBuilder tradeAggregations(
      Asset baseAsset, Asset counterAsset, int startTime, int endTime, int resolution, int offset) {
    return TradeAggregationsRequestBuilder(
        httpClient, _serverURI, baseAsset, counterAsset, startTime, endTime, resolution, offset);
  }

  /// Returns StrictSendPathsRequestBuilder instance.
  StrictSendPathsRequestBuilder get strictSendPaths =>
      StrictSendPathsRequestBuilder(httpClient, _serverURI);

  /// Returns StrictReceivePathsRequestBuilder instance.
  StrictReceivePathsRequestBuilder get strictReceivePaths =>
      StrictReceivePathsRequestBuilder(httpClient, _serverURI);

  /// Returns PaymentsRequestBuilder instance.
  PaymentsRequestBuilder get payments => PaymentsRequestBuilder(httpClient, _serverURI);

  /// Returns TransactionsRequestBuilder instance.
  TransactionsRequestBuilder get transactions => TransactionsRequestBuilder(httpClient, _serverURI);

  /// Returns LiquidityPoolsRequestBuilder instance.
  LiquidityPoolsRequestBuilder get liquidityPools =>
      LiquidityPoolsRequestBuilder(httpClient, _serverURI);

  /// Returns LiquidityPoolTradesRequestBuilder instance.
  LiquidityPoolTradesRequestBuilder get liquidityPoolTrades =>
      LiquidityPoolTradesRequestBuilder(httpClient, _serverURI);

  /// Submits a [transaction] to the network.
  Future<SubmitTransactionResponse> submitTransaction(Transaction transaction) async {
    return submitTransactionEnvelopeXdrBase64(transaction.toEnvelopeXdrBase64());
  }

  /// Submits a [feeBumpTransaction] to the network.
  Future<SubmitTransactionResponse> submitFeeBumpTransaction(
      FeeBumpTransaction feeBumpTransaction) async {
    return submitTransactionEnvelopeXdrBase64(feeBumpTransaction.toEnvelopeXdrBase64());
  }

  Future<SubmitTransactionResponse> submitTransactionEnvelopeXdrBase64(
      String transactionEnvelopeXdrBase64) async {
    Uri callURI = _serverURI.replace(pathSegments: ["transactions"]);

    //print("Envelope XDR: " + transaction.toEnvelopeXdrBase64());
    SubmitTransactionResponse result = await _httpClient
        .post(callURI, body: {"tx": transactionEnvelopeXdrBase64}, headers: RequestBuilder.headers)
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
          throw SubmitTransactionUnknownResponseException(response.statusCode, response.body);
      }
      return submitTransactionResponse;
    }).catchError((onError) {
      throw onError;
    });

    return result;
  }
}
