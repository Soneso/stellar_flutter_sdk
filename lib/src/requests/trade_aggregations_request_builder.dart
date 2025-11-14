// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:http/http.dart' as http;
import 'dart:async';
import '../assets.dart';
import '../asset_type_credit_alphanum.dart';
import '../responses/response.dart';
import 'request_builder.dart';
import '../responses/trade_aggregation_response.dart';

/// Builds requests for trade aggregations.
///
/// Trade aggregations provide OHLCV (Open, High, Low, Close, Volume) statistics
/// for a trading pair over specified time periods. They aggregate individual
/// trades into time buckets, making it easy to analyze price movements and
/// trading volume for charting and market analysis.
///
/// Each aggregation includes:
/// - timestamp: Time bucket start
/// - trade_count: Number of trades in the bucket
/// - base_volume: Volume of base asset traded
/// - counter_volume: Volume of counter asset traded
/// - avg: Average price in the bucket
/// - high: Highest price in the bucket
/// - low: Lowest price in the bucket
/// - open: Opening price in the bucket
/// - close: Closing price in the bucket
///
/// Example:
/// ```dart
/// // Get hourly trade aggregations for XLM/USDC pair
/// var baseAsset = Asset.createNonNativeAsset('XLM', issuerId);
/// var counterAsset = Asset.createNonNativeAsset('USDC', issuerId);
///
/// var startTime = DateTime.now().subtract(Duration(days: 7)).millisecondsSinceEpoch;
/// var endTime = DateTime.now().millisecondsSinceEpoch;
/// var resolution = 3600000; // 1 hour in milliseconds
/// var offset = 0;
///
/// var aggregations = await sdk.tradeAggregations
///     .tradeAggregations(baseAsset, counterAsset, startTime, endTime, resolution, offset)
///     .limit(200)
///     .order(RequestBuilderOrder.DESC)
///     .execute();
///
/// for (var agg in aggregations.records) {
///   print('Time: ${agg.timestamp}');
///   print('High: ${agg.high}, Low: ${agg.low}');
///   print('Volume: ${agg.baseVolume}');
/// }
/// ```
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
class TradeAggregationsRequestBuilder extends RequestBuilder {
  /// Creates a trade aggregations request builder.
  ///
  /// Parameters:
  /// - httpClient: HTTP client for making requests
  /// - serverURI: Horizon server URI
  /// - baseAsset: Base asset of the trading pair
  /// - counterAsset: Counter asset of the trading pair
  /// - startTime: Start time in milliseconds since epoch (lower boundary)
  /// - endTime: End time in milliseconds since epoch (upper boundary)
  /// - resolution: Time bucket size in milliseconds (e.g., 3600000 for 1 hour)
  ///              Supported resolutions: 1 minute (60000), 5 minutes (300000),
  ///              15 minutes (900000), 1 hour (3600000), 1 day (86400000), 1 week (604800000)
  /// - offset: Offset from start time in milliseconds (shifts time buckets, usually 0)
  TradeAggregationsRequestBuilder(http.Client httpClient, Uri serverURI, Asset baseAsset,
      Asset counterAsset, int startTime, int endTime, int resolution, int offset)
      : super(httpClient, serverURI, ["trade_aggregations"]) {
    this._baseAsset(baseAsset);
    this._counterAsset(counterAsset);
    queryParameters.addAll({"start_time": startTime.toString()});
    queryParameters.addAll({"end_time": endTime.toString()});
    queryParameters.addAll({"resolution": resolution.toString()});
    queryParameters.addAll({"offset": offset.toString()});
  }

  void _baseAsset(Asset asset) {
    queryParameters.addAll({"base_asset_type": asset.type});
    if (asset is AssetTypeCreditAlphaNum) {
      AssetTypeCreditAlphaNum creditAlphaNumAsset = asset;
      queryParameters.addAll({"base_asset_code": creditAlphaNumAsset.code});
      queryParameters.addAll({"base_asset_issuer": creditAlphaNumAsset.issuerId});
    }
  }

  void _counterAsset(Asset asset) {
    queryParameters.addAll({"counter_asset_type": asset.type});
    if (asset is AssetTypeCreditAlphaNum) {
      AssetTypeCreditAlphaNum creditAlphaNumAsset = asset;
      queryParameters.addAll({"counter_asset_code": creditAlphaNumAsset.code});
      queryParameters.addAll({"counter_asset_issuer": creditAlphaNumAsset.issuerId});
    }
  }

  static Future<Page<TradeAggregationResponse>> requestExecute(
      http.Client httpClient, Uri uri) async {
    TypeToken<Page<TradeAggregationResponse>> type =
        new TypeToken<Page<TradeAggregationResponse>>();
    ResponseHandler<Page<TradeAggregationResponse>> responseHandler =
        new ResponseHandler<Page<TradeAggregationResponse>>(type);

    return await httpClient.get(uri, headers: RequestBuilder.headers).then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  /// Builds and executes the request.
  ///
  /// Returns: Page of TradeAggregationResponse objects containing OHLCV data
  ///
  /// Example:
  /// ```dart
  /// var page = await sdk.tradeAggregations
  ///     .tradeAggregations(baseAsset, counterAsset, startTime, endTime, resolution, offset)
  ///     .execute();
  ///
  /// for (var agg in page.records) {
  ///   print('Timestamp: ${agg.timestamp}');
  ///   print('Open: ${agg.open}, Close: ${agg.close}');
  ///   print('High: ${agg.high}, Low: ${agg.low}');
  ///   print('Base Volume: ${agg.baseVolume}');
  /// }
  /// ```
  Future<Page<TradeAggregationResponse>> execute() {
    return TradeAggregationsRequestBuilder.requestExecute(this.httpClient, this.buildUri());
  }
}
