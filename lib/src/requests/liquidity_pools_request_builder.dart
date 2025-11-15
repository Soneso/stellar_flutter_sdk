// Copyright 2021 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:http/http.dart' as http;
import 'package:stellar_flutter_sdk/src/key_pair.dart';
import 'package:stellar_flutter_sdk/src/util.dart';
import '../responses/trade_response.dart';
import '../assets.dart';
import '../responses/liquidity_pool_response.dart';
import 'dart:async';
import '../responses/response.dart';
import 'request_builder.dart';

/// Builds requests to query liquidity pools from Horizon.
///
/// Liquidity pools are automated market makers (AMMs) on the Stellar network that
/// allow users to provide liquidity and earn fees. Each pool consists of two assets
/// and uses a constant product formula for trading.
///
/// This builder supports filtering pools by reserve assets, account participation,
/// and pool ID. Pagination is supported but streaming is not available.
///
/// Example:
/// ```dart
/// // Get all liquidity pools for an account
/// final pools = await sdk.liquidityPools
///     .forAccount('GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B')
///     .execute();
///
/// // Get a specific pool by ID
/// final pool = await sdk.liquidityPools.forPoolId('pool_id');
///
/// // Filter by reserve assets
/// final usdXlmPools = await sdk.liquidityPools
///     .forReserveAssets(xlmAsset, usdAsset)
///     .execute();
/// ```
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
/// - [LiquidityPoolResponse] for response structure
class LiquidityPoolsRequestBuilder extends RequestBuilder {
  static const String RESERVES_PARAMETER_NAME = "reserves";
  static const String ACCOUNT_PARAMETER_NAME = "account";

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
  /// See [Stellar developer docs](https://developers.stellar.org)
  Future<LiquidityPoolResponse> forPoolId(String poolId) {
    var id = poolId;
    if (id.startsWith("L")) {
      try {
        id = Util.bytesToHex(StrKey.decodeLiquidityPoolId(poolId));
      } catch (_) {}
    }
    this.setSegments(["liquidity_pools", id]);
    return this.liquidityPool(this.buildUri());
  }

  /// Filters liquidity pools to only those containing the specified reserve assets.
  /// Returns this builder for method chaining.
  LiquidityPoolsRequestBuilder forReserveAssets(Asset reserveAssetA, Asset reserveAssetB) {
    queryParameters.addAll({RESERVES_PARAMETER_NAME: Asset.canonicalForm(reserveAssetA) + "," + Asset.canonicalForm(reserveAssetB)});
    return this;
  }

  /// Returns all liquidity pools the specified account is participating in.
  /// See [Stellar developer docs](https://developers.stellar.org)
  LiquidityPoolsRequestBuilder forAccount(String accountId) {
    queryParameters.addAll({ACCOUNT_PARAMETER_NAME: accountId});
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

  /// Sets the cursor for pagination to start returning records from a specific point.
  /// Returns this builder for method chaining.
  @override
  LiquidityPoolsRequestBuilder cursor(String token) {
    super.cursor(token);
    return this;
  }

  /// Sets the maximum number of records to return in a single page.
  /// Returns this builder for method chaining.
  @override
  LiquidityPoolsRequestBuilder limit(int number) {
    super.limit(number);
    return this;
  }

  /// Sets the sort order for returned records (ascending or descending).
  /// Returns this builder for method chaining.
  @override
  LiquidityPoolsRequestBuilder order(RequestBuilderOrder direction) {
    super.order(direction);
    return this;
  }
}

/// Builds requests to query trades for a specific liquidity pool from Horizon.
///
/// This builder retrieves all trades executed against a specific liquidity pool.
/// Trades represent exchanges between the two assets in the pool, showing the
/// amounts traded, prices, and participating accounts.
///
/// This builder requires a pool ID to be specified using [forPoolId]. It supports
/// pagination and ordering but does not support streaming.
///
/// Example:
/// ```dart
/// // Get recent trades for a specific pool
/// final trades = await sdk.liquidityPoolTrades
///     .forPoolId('pool_id_here')
///     .order(RequestBuilderOrder.DESC)
///     .limit(20)
///     .execute();
///
/// for (var trade in trades.records) {
///   print('Trade: ${trade.baseAmount} for ${trade.counterAmount}');
/// }
/// ```
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
/// - [TradeResponse] for response structure
/// - [LiquidityPoolsRequestBuilder] for querying pools
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

  /// Sets the liquidity pool to retrieve trades for by [poolId].
  ///
  /// The pool ID can be provided in either hex format or Stellar-encoded format
  /// (starting with 'L'). The method will automatically decode Stellar-encoded IDs.
  ///
  /// This method must be called before executing the request.
  ///
  /// See: [Stellar developer docs](https://developers.stellar.org)
  LiquidityPoolTradesRequestBuilder forPoolId(String poolId) {
    var id = poolId;
    if (id.startsWith("L")) {
      try {
        id = Util.bytesToHex(StrKey.decodeLiquidityPoolId(poolId));
      } catch (_) {}
    }
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

  /// Sets the cursor for pagination to start returning records from a specific point.
  /// Returns this builder for method chaining.
  @override
  LiquidityPoolTradesRequestBuilder cursor(String token) {
    super.cursor(token);
    return this;
  }

  /// Sets the maximum number of records to return in a single page.
  /// Returns this builder for method chaining.
  @override
  LiquidityPoolTradesRequestBuilder limit(int number) {
    super.limit(number);
    return this;
  }

  /// Sets the sort order for returned records (ascending or descending).
  /// Returns this builder for method chaining.
  @override
  LiquidityPoolTradesRequestBuilder order(RequestBuilderOrder direction) {
    super.order(direction);
    return this;
  }
}
