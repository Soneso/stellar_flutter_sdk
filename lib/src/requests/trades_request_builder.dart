// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:http/http.dart' as http;
import 'dart:async';
import '../assets.dart';
import '../asset_type_credit_alphanum.dart';
import '../responses/response.dart';
import 'request_builder.dart';
import '../responses/trade_response.dart';
import '../util.dart';

/// Builds requests connected to trades.
class TradesRequestBuilder extends RequestBuilder {
  TradesRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, ["trades"]);

  TradesRequestBuilder baseAsset(Asset asset) {
    queryParameters.addAll({"base_asset_type": asset.type});
    if (asset is AssetTypeCreditAlphaNum) {
      AssetTypeCreditAlphaNum creditAlphaNumAsset = asset;
      queryParameters.addAll({"base_asset_code": creditAlphaNumAsset.code});
      queryParameters
          .addAll({"base_asset_issuer": creditAlphaNumAsset.issuerId});
    }
    return this;
  }

  TradesRequestBuilder counterAsset(Asset asset) {
    queryParameters.addAll({"counter_asset_type": asset.type});
    if (asset is AssetTypeCreditAlphaNum) {
      AssetTypeCreditAlphaNum creditAlphaNumAsset = asset;
      queryParameters.addAll({"counter_asset_code": creditAlphaNumAsset.code});
      queryParameters
          .addAll({"counter_asset_issuer": creditAlphaNumAsset.issuerId});
    }
    return this;
  }

  /// Returns the trades for a given account by [accountId].
  /// See: <a href="https://www.stellar.org/developers/horizon/reference/endpoints/trades-for-account.html">Trades for Account</a>
  TradesRequestBuilder forAccount(String accountId) {
    accountId = checkNotNull(accountId, "accountId cannot be null");
    this.setSegments(["accounts", accountId, "trades"]);
    return this;
  }

  static Future<Page<TradeResponse>> requestExecute(
      http.Client httpClient, Uri uri) async {
    TypeToken type = new TypeToken<Page<TradeResponse>>();
    ResponseHandler<Page<TradeResponse>> responseHandler =
        new ResponseHandler<Page<TradeResponse>>(type);

    return await httpClient
        .get(uri, headers: RequestBuilder.headers)
        .then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  Future<Page<TradeResponse>> execute() {
    return TradesRequestBuilder.requestExecute(
        this.httpClient, this.buildUri());
  }

  TradesRequestBuilder offerId(String offerId) {
    queryParameters.addAll({"offer_id": offerId});
    return this;
  }

  //TODO: add missing: stream, cursor, limit
}
