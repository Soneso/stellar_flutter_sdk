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

/// Builds requests connected to trade aggregations. A trade aggregation represents aggregated statistics on an asset pair (base and counter) for a specific time period. Trade aggregations are useful to developers of trading clients and provide historical trade data.
/// See: <a href="https://developers.stellar.org/api/aggregations/paths/" target="_blank">Trade Aggregations</a>
class TradeAggregationsRequestBuilder extends RequestBuilder {
  TradeAggregationsRequestBuilder(
      http.Client httpClient,
      Uri serverURI,
      Asset baseAsset,
      Asset counterAsset,
      int startTime,
      int endTime,
      int resolution,
      int offset)
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
      queryParameters
          .addAll({"base_asset_issuer": creditAlphaNumAsset.issuerId});
    }
  }

  void _counterAsset(Asset asset) {
    queryParameters.addAll({"counter_asset_type": asset.type});
    if (asset is AssetTypeCreditAlphaNum) {
      AssetTypeCreditAlphaNum creditAlphaNumAsset = asset;
      queryParameters.addAll({"counter_asset_code": creditAlphaNumAsset.code});
      queryParameters
          .addAll({"counter_asset_issuer": creditAlphaNumAsset.issuerId});
    }
  }

  static Future<Page<TradeAggregationResponse>> requestExecute(
      http.Client httpClient, Uri uri) async {
    TypeToken type = new TypeToken<Page<TradeAggregationResponse>>();
    ResponseHandler<Page<TradeAggregationResponse>> responseHandler =
        new ResponseHandler<Page<TradeAggregationResponse>>(type);

    return await httpClient
        .get(uri, headers: RequestBuilder.headers)
        .then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  Future<Page<TradeAggregationResponse>> execute() {
    return TradeAggregationsRequestBuilder.requestExecute(
        this.httpClient, this.buildUri());
  }
}
