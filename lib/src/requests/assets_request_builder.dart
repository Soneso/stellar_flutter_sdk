// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:http/http.dart' as http;
import 'dart:async';
import '../responses/response.dart';
import '../responses/asset_response.dart';
import 'request_builder.dart';

/// Lists all assets. It will give you all the assets in the system along with various statistics about each.
/// See <a href="https://developers.stellar.org/api/resources/assets/object/" target="_blank">Assets</a>
class AssetsRequestBuilder extends RequestBuilder {
  AssetsRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, ["assets"]);

  AssetsRequestBuilder assetCode(String assetCode) {
    queryParameters.addAll({"asset_code": assetCode});
    return this;
  }

  AssetsRequestBuilder assetIssuer(String assetIssuer) {
    queryParameters.addAll({"asset_issuer": assetIssuer});
    return this;
  }

  static Future<Page<AssetResponse>> requestExecute(
      http.Client httpClient, Uri uri) async {
    TypeToken type = new TypeToken<Page<AssetResponse>>();
    ResponseHandler<Page<AssetResponse>> responseHandler =
        new ResponseHandler<Page<AssetResponse>>(type);

    return await httpClient
        .get(uri, headers: RequestBuilder.headers)
        .then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  Future<Page<AssetResponse>> execute() {
    return AssetsRequestBuilder.requestExecute(
        this.httpClient, this.buildUri());
  }

  @override
  AssetsRequestBuilder cursor(String token) {
    super.cursor(token);
    return this;
  }

  @override
  AssetsRequestBuilder limit(int number) {
    super.limit(number);
    return this;
  }

  @override
  AssetsRequestBuilder order(RequestBuilderOrder direction) {
    super.order(direction);
    return this;
  }
}
