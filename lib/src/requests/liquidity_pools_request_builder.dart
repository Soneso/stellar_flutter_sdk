// Copyright 2021 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:http/http.dart' as http;
import '../responses/trade_response.dart';
import '../assets.dart';
import '../responses/liquidity_pool_response.dart';
import 'dart:async';
import '../responses/response.dart';
import 'request_builder.dart';
import '../util.dart';

class LiquidityPoolsRequestBuilder extends RequestBuilder {
  static const String RESERVES_PARAMETER_NAME = "reserves";

  LiquidityPoolsRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, ["liquidity_pools"]);

  /// Requests specific [uri] and returns LiquidityPoolResponse.
  /// This method is helpful for getting the links.
  Future<LiquidityPoolResponse> liquidityPool(Uri uri) async {
    TypeToken<LiquidityPoolResponse> type = new TypeToken<LiquidityPoolResponse>();
    ResponseHandler<LiquidityPoolResponse> responseHandler =
    ResponseHandler<LiquidityPoolResponse>(type);

    return await httpClient.get(uri, headers: RequestBuilder.headers).then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  /// Requests details about the liquidity pool to fetch by [poolId].
  /// See <a href="https://developers.stellar.org/api/resources/claimablebalances/" target="_blank">Claimable Balances</a>
  Future<LiquidityPoolResponse> forPoolId(String poolId) {
    this.setSegments(["liquidity_pools", poolId]);
    return this.liquidityPool(this.buildUri());
  }

  LiquidityPoolsRequestBuilder forReserveAssets(Asset reserveAssetA, Asset reserveAssetB) {
    queryParameters.addAll({RESERVES_PARAMETER_NAME: Asset.canonicalForm(reserveAssetA) + "," + Asset.canonicalForm(reserveAssetB)});
    return this;
  }

  /// Requests specific uri and returns Page of LiquidityPoolResponse.
  /// This method is helpful for getting the next set of results.
  static Future<Page<LiquidityPoolResponse>> requestExecute(
      http.Client httpClient, Uri uri) async {
    TypeToken<Page<LiquidityPoolResponse>> type =
    new TypeToken<Page<LiquidityPoolResponse>>();
    ResponseHandler<Page<LiquidityPoolResponse>> responseHandler =
    new ResponseHandler<Page<LiquidityPoolResponse>>(type);

    return await httpClient.get(uri, headers: RequestBuilder.headers).then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  /// Build and execute request.
  Future<Page<LiquidityPoolResponse>> execute() {
    return LiquidityPoolsRequestBuilder.requestExecute(this.httpClient, this.buildUri());
  }

  @override
  LiquidityPoolsRequestBuilder cursor(String token) {
    super.cursor(token);
    return this;
  }

  @override
  LiquidityPoolsRequestBuilder limit(int number) {
    super.limit(number);
    return this;
  }

  @override
  LiquidityPoolsRequestBuilder order(RequestBuilderOrder direction) {
    super.order(direction);
    return this;
  }
}

class LiquidityPoolTradesRequestBuilder extends RequestBuilder {

  LiquidityPoolTradesRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, ["liquidity_pools"]);

  /// Requests specific [uri] and returns TradeResponse.
  /// This method is helpful for getting the links.
  Future<TradeResponse> liquidityPoolTrades(Uri uri) async {
    TypeToken<TradeResponse> type = new TypeToken<TradeResponse>();
    ResponseHandler<TradeResponse> responseHandler =
    ResponseHandler<TradeResponse>(type);

    return await httpClient.get(uri, headers: RequestBuilder.headers).then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  LiquidityPoolTradesRequestBuilder forPoolId(String poolId) {
    this.setSegments(["liquidity_pools", poolId, "trades"]);
    return this;
  }

  /// Requests specific uri and returns Page of TradeResponse.
  /// This method is helpful for getting the next set of results.
  static Future<Page<TradeResponse>> requestExecute(
      http.Client httpClient, Uri uri) async {
    TypeToken<Page<TradeResponse>> type =
    new TypeToken<Page<TradeResponse>>();
    ResponseHandler<Page<TradeResponse>> responseHandler =
    new ResponseHandler<Page<TradeResponse>>(type);

    return await httpClient.get(uri, headers: RequestBuilder.headers).then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  /// Build and execute request.
  Future<Page<TradeResponse>> execute() {
    return LiquidityPoolTradesRequestBuilder.requestExecute(this.httpClient, this.buildUri());
  }

  @override
  LiquidityPoolTradesRequestBuilder cursor(String token) {
    super.cursor(token);
    return this;
  }

  @override
  LiquidityPoolTradesRequestBuilder limit(int number) {
    super.limit(number);
    return this;
  }

  @override
  LiquidityPoolTradesRequestBuilder order(RequestBuilderOrder direction) {
    super.order(direction);
    return this;
  }
}
