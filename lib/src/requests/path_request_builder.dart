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

/// Builds requests connected to finding paths. Paths provide information about potential path payments. A path can be used to populate the necessary fields for a path payment operation.
/// The strict receive payment path endpoint lists the paths a payment can take based on the amount of an asset you want the recipient to receive. The destination asset amount stays constant, and the type and amount of an asset sent varies based on offers in the order books.
/// See: <a href="https://developers.stellar.org/api/aggregations/paths/" target="_blank">Paths</a>
/// See: <a href="https://developers.stellar.org/api/aggregations/paths/strict-receive/" target="_blank">List Strict Receive Payment Paths</a>
class StrictReceivePathsRequestBuilder extends RequestBuilder {
  StrictReceivePathsRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, ["paths", "strict-receive"]);

  /// Sets the source account. For this search, Horizon loads a list of assets available to the sender (based on source_account or source_assets) and displays the possible paths from the different source assets to the destination asset.
  /// See: <a href="https://developers.stellar.org/api/aggregations/paths/strict-receive/" target="_blank">List Strict Receive Payment Paths</a>
  StrictReceivePathsRequestBuilder sourceAccount(String accountId) {
    if (queryParameters.containsKey("source_assets")) {
      throw Exception("cannot set both source_assets and source_account");
    }
    queryParameters.addAll({"source_account": accountId});
    return this;
  }

  /// Sets the source assets. For this search, Horizon loads a list of assets available to the sender (based on source_account or source_assets) and displays the possible paths from the different source assets to the destination asset.
  /// See: <a href="https://developers.stellar.org/api/aggregations/paths/strict-receive/" target="_blank">List Strict Receive Payment Paths</a>
  StrictReceivePathsRequestBuilder sourceAssets(List<Asset> sourceAssets) {
    if (queryParameters.containsKey("source_account")) {
      throw Exception("cannot set both source_assets and source_account");
    }
    queryParameters.addAll({"source_assets": encodeAssets(sourceAssets)});
    return this;
  }

  /// Sets the destination amount. The [amount] of the destination asset that should be received.
  /// See: <a href="https://developers.stellar.org/api/aggregations/paths/strict-receive/" target="_blank">List Strict Receive Payment Paths</a>
  StrictReceivePathsRequestBuilder destinationAmount(String amount) {
    queryParameters.addAll({"destination_amount": amount});
    return this;
  }

  /// Sets the destination asset.
  /// See: <a href="https://developers.stellar.org/api/aggregations/paths/strict-receive/" target="_blank">List Strict Receive Payment Paths</a>
  StrictReceivePathsRequestBuilder destinationAsset(Asset asset) {
    queryParameters.addAll({"destination_asset_type": asset.type});
    if (asset is AssetTypeCreditAlphaNum) {
      AssetTypeCreditAlphaNum creditAlphaNumAsset = asset;
      queryParameters
          .addAll({"destination_asset_code": creditAlphaNumAsset.code});
      queryParameters
          .addAll({"destination_asset_issuer": creditAlphaNumAsset.issuerId});
    }
    return this;
  }

  static Future<Page<PathResponse>> requestExecute(
      http.Client httpClient, Uri uri) async {
    TypeToken type = new TypeToken<Page<PathResponse>>();
    ResponseHandler<Page<PathResponse>> responseHandler =
        new ResponseHandler<Page<PathResponse>>(type);

    return await httpClient
        .get(uri, headers: RequestBuilder.headers)
        .then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  Future<Page<PathResponse>> execute() {
    return StrictReceivePathsRequestBuilder.requestExecute(
        this.httpClient, this.buildUri());
  }
}

/// Builds requests connected to finding paths. Paths provide information about potential path payments. A path can be used to populate the necessary fields for a path payment operation.
/// The strict receive payment path endpoint lists the paths a payment can take based on the amount of an asset you want to send. The source asset amount stays constant, and the type and amount of an asset received varies based on offers in the order books.
/// See: <a href="https://developers.stellar.org/api/aggregations/paths/" target="_blank">Paths</a>
/// See: <a href="https://developers.stellar.org/api/aggregations/paths/strict-send/" target="_blank">List Strict Send Payment Paths</a>
class StrictSendPathsRequestBuilder extends RequestBuilder {
  StrictSendPathsRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, ["paths", "strict-send"]);

  /// Sets the destination account.For this search, Horizon loads a list of assets that the recipient can recieve (based on destination_account or destination_assets) and displays the possible paths from the different source assets to the destination asset. Only paths that satisfy the source_amount are returned.
  /// See: <a href="https://developers.stellar.org/api/aggregations/paths/strict-send/" target="_blank">List Strict Send Payment Paths</a>
  StrictSendPathsRequestBuilder destinationAccount(String accountId) {
    if (queryParameters.containsKey("destination_assets")) {
      throw Exception(
          "cannot set both destination_assets and destination_account");
    }
    queryParameters.addAll({"destination_account": accountId});
    return this;
  }

  /// Sets the destination assets. For this search, Horizon loads a list of assets that the recipient can recieve (based on destination_account or destination_assets) and displays the possible paths from the different source assets to the destination asset. Only paths that satisfy the source_amount are returned.
  /// See: <a href="https://developers.stellar.org/api/aggregations/paths/strict-send/" target="_blank">List Strict Send Payment Paths</a>
  StrictSendPathsRequestBuilder destinationAssets(
      List<Asset> destinationAssets) {
    if (queryParameters.containsKey("destination_account")) {
      throw Exception(
          "cannot set both destination_assets and destination_account");
    }
    queryParameters
        .addAll({"destination_assets": encodeAssets(destinationAssets)});
    return this;
  }

  /// Sets the source amount.
  /// See: <a href="https://developers.stellar.org/api/aggregations/paths/strict-send/" target="_blank">List Strict Send Payment Paths</a>
  StrictSendPathsRequestBuilder sourceAmount(String amount) {
    queryParameters.addAll({"source_amount": amount});
    return this;
  }

  /// Sets the source asset.
  /// See: <a href="https://developers.stellar.org/api/aggregations/paths/strict-send/" target="_blank">List Strict Send Payment Paths</a>
  StrictSendPathsRequestBuilder sourceAsset(Asset asset) {
    queryParameters.addAll({"source_asset_type": asset.type});
    if (asset is AssetTypeCreditAlphaNum) {
      AssetTypeCreditAlphaNum creditAlphaNumAsset = asset;
      queryParameters.addAll({"source_asset_code": creditAlphaNumAsset.code});
      queryParameters
          .addAll({"source_asset_issuer": creditAlphaNumAsset.issuerId});
    }
    return this;
  }

  static Future<Page<PathResponse>> requestExecute(
      http.Client httpClient, Uri uri) async {
    TypeToken type = new TypeToken<Page<PathResponse>>();
    ResponseHandler<Page<PathResponse>> responseHandler =
        new ResponseHandler<Page<PathResponse>>(type);

    return await httpClient
        .get(uri, headers: RequestBuilder.headers)
        .then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  Future<Page<PathResponse>> execute() {
    return StrictSendPathsRequestBuilder.requestExecute(
        this.httpClient, this.buildUri());
  }
}
