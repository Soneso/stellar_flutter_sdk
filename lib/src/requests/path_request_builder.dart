// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:http/http.dart' as http;
import 'dart:async';
import '../assets.dart';
import '../asset_type_credit_alphanum.dart';
import '../responses/response.dart';
import '../responses/path_response.dart';
import 'request_builder.dart';

/// Builds requests connected to paths.
class StrictReceivePathsRequestBuilder extends RequestBuilder {
  StrictReceivePathsRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, ["paths", "strict-receive"]);

  StrictReceivePathsRequestBuilder destinationAccount(String accountId) {
    queryParameters.addAll({"destination_account": accountId});
    return this;
  }

  StrictReceivePathsRequestBuilder sourceAccount(String accountId) {
    queryParameters.addAll({"source_account": accountId});
    return this;
  }

  // TODO: source_assets

  StrictReceivePathsRequestBuilder destinationAmount(String amount) {
    queryParameters.addAll({"destination_amount": amount});
    return this;
  }

  StrictReceivePathsRequestBuilder destinationAsset(Asset asset) {
    queryParameters.addAll({"destination_asset_type": asset.type});
    if (asset is AssetTypeCreditAlphaNum) {
      AssetTypeCreditAlphaNum creditAlphaNumAsset = asset;
      queryParameters
          .addAll({"destination_asset_code": creditAlphaNumAsset.code});
      queryParameters.addAll(
          {"destination_asset_issuer": creditAlphaNumAsset.issuer});
    }
    return this;
  }

  static Future<Page<PathResponse>> requestExecute(
      http.Client httpClient, Uri uri) async {
    TypeToken type = new TypeToken<Page<PathResponse>>();
    ResponseHandler<Page<PathResponse>> responseHandler =
    new ResponseHandler<Page<PathResponse>>(type);

    return await httpClient.get(uri, headers:RequestBuilder.headers).then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  Future<Page<PathResponse>> execute() {
    return StrictReceivePathsRequestBuilder.requestExecute(this.httpClient, this.buildUri());
  }
}


/// Builds requests connected to paths.
class StrictSendPathsRequestBuilder extends RequestBuilder {
  StrictSendPathsRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, ["paths", "strict-send"]);

  StrictSendPathsRequestBuilder destinationAccount(String accountId) {
    queryParameters.addAll({"destination_account": accountId});
    return this;
  }

  // TODO: destination_assets

  StrictSendPathsRequestBuilder sourceAmount(String amount) {
    queryParameters.addAll({"source_amount": amount});
    return this;
  }

  StrictSendPathsRequestBuilder sourceAsset(Asset asset) {
    queryParameters.addAll({"source_asset_type": asset.type});
    if (asset is AssetTypeCreditAlphaNum) {
      AssetTypeCreditAlphaNum creditAlphaNumAsset = asset;
      queryParameters
          .addAll({"source_asset_code": creditAlphaNumAsset.code});
      queryParameters.addAll(
          {"source_asset_issuer": creditAlphaNumAsset.issuer});
    }
    return this;
  }

  static Future<Page<PathResponse>> requestExecute(
      http.Client httpClient, Uri uri) async {
    TypeToken type = new TypeToken<Page<PathResponse>>();
    ResponseHandler<Page<PathResponse>> responseHandler =
    new ResponseHandler<Page<PathResponse>>(type);

    return await httpClient.get(uri, headers:RequestBuilder.headers).then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  Future<Page<PathResponse>> execute() {
    return StrictSendPathsRequestBuilder.requestExecute(this.httpClient, this.buildUri());
  }
}