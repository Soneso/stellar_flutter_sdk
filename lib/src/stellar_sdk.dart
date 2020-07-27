// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:http/http.dart' as http;
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

/// Main class of the flutter stellar sdk.
class StellarSDK {
  static const versionNumber = "1.0.4";

  static final StellarSDK PUBLIC =
      new StellarSDK("https://horizon.stellar.org");
  static final StellarSDK TESTNET =
      new StellarSDK("https://horizon-testnet.stellar.org");

  Uri _serverURI;
  http.Client _httpClient;

  StellarSDK(String url) {
    _serverURI = Uri.parse(url);
    _httpClient = new http.Client();
  }

  http.Client get httpClient => _httpClient;

  set httpClient(http.Client httpClient) {
    this._httpClient = httpClient;
  }

  /// Returns RootResponse.
  Future<RootResponse> root() async {
    TypeToken type = new TypeToken<RootResponse>();
    ResponseHandler<RootResponse> responseHandler =
        new ResponseHandler<RootResponse>(type);

    return await httpClient.get(_serverURI).then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  /// Returns AccountsRequestBuilder instance.
  AccountsRequestBuilder get accounts =>
      new AccountsRequestBuilder(httpClient, _serverURI);

  /// Returns AssetsRequestBuilder instance.
  AssetsRequestBuilder get assets =>
      new AssetsRequestBuilder(httpClient, _serverURI);

  /// Returns EffectsRequestBuilder instance.
  EffectsRequestBuilder get effects =>
      new EffectsRequestBuilder(httpClient, _serverURI);

  /// Returns LedgersRequestBuilder instance.
  LedgersRequestBuilder get ledgers =>
      new LedgersRequestBuilder(httpClient, _serverURI);

  /// Returns OffersRequestBuilder instance.
  OffersRequestBuilder get offers =>
      new OffersRequestBuilder(httpClient, _serverURI);

  /// Returns OperationsRequestBuilder instance.
  OperationsRequestBuilder get operations =>
      new OperationsRequestBuilder(httpClient, _serverURI);

  /// Returns FeeStatsResponse instance.
  FeeStatsRequestBuilder get feeStats =>
      new FeeStatsRequestBuilder(httpClient, _serverURI);

  /// Returns OrderBookRequestBuilder instance.
  OrderBookRequestBuilder get orderBook =>
      new OrderBookRequestBuilder(httpClient, _serverURI);

  /// Returns TradesRequestBuilder instance.
  TradesRequestBuilder get trades =>
      new TradesRequestBuilder(httpClient, _serverURI);

  /// Returns TradeAggregationsRequestBuilder instance.
  TradeAggregationsRequestBuilder tradeAggregations(
      Asset baseAsset,
      Asset counterAsset,
      int startTime,
      int endTime,
      int resolution,
      int offset) {
    return new TradeAggregationsRequestBuilder(httpClient, _serverURI,
        baseAsset, counterAsset, startTime, endTime, resolution, offset);
  }

  /// Returns StrictSendPathsRequestBuilder instance.
  StrictSendPathsRequestBuilder get strictSendPaths =>
      new StrictSendPathsRequestBuilder(httpClient, _serverURI);

  /// Returns StrictReceivePathsRequestBuilder instance.
  StrictReceivePathsRequestBuilder get strictReceivePaths =>
      new StrictReceivePathsRequestBuilder(httpClient, _serverURI);

  /// Returns PaymentsRequestBuilder instance.
  PaymentsRequestBuilder get payments =>
      new PaymentsRequestBuilder(httpClient, _serverURI);

  /// Returns TransactionsRequestBuilder instance.
  TransactionsRequestBuilder get transactions =>
      new TransactionsRequestBuilder(httpClient, _serverURI);

  /// Submits a [transaction] to the network.
  Future<SubmitTransactionResponse> submitTransaction(
      Transaction transaction) async {
    return submitTransactionEnvelopeXdrBase64(
        transaction.toEnvelopeXdrBase64());
  }

  /// Submits a [feeBumpTransaction] to the network.
  Future<SubmitTransactionResponse> submitFeeBumpTransaction(
      FeeBumpTransaction feeBumpTransaction) async {
    return submitTransactionEnvelopeXdrBase64(
        feeBumpTransaction.toEnvelopeXdrBase64());
  }

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
          throw new SubmitTransactionTimeoutResponseException();
        default:
          throw new SubmitTransactionUnknownResponseException(
              response.statusCode, response.body);
      }
      return submitTransactionResponse;
    }).catchError((onError) {
      throw onError;
    });

    return result;
  }
}
