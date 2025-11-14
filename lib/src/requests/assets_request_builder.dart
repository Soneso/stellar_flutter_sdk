// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:http/http.dart' as http;
import 'dart:async';
import '../responses/response.dart';
import '../responses/asset_response.dart';
import 'request_builder.dart';

/// Builds requests to query assets from Horizon.
///
/// Assets represent tokens on the Stellar network. This endpoint provides information
/// about all issued assets along with statistics including total supply, number of
/// accounts holding the asset, and authorization flags.
///
/// The native asset (XLM) is not included in these results as it exists by default
/// on the network.
///
/// This builder supports filtering assets by code and issuer, with pagination
/// through result sets. Streaming is not available for the assets endpoint.
///
/// Example:
/// ```dart
/// // Get all assets with a specific code
/// final usdAssets = await sdk.assets
///     .assetCode('USD')
///     .limit(20)
///     .execute();
///
/// // Get a specific asset by code and issuer
/// final specificAsset = await sdk.assets
///     .assetCode('EUR')
///     .assetIssuer('GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B')
///     .execute();
///
/// // Get all assets ordered by number of accounts
/// final popularAssets = await sdk.assets
///     .order(RequestBuilderOrder.DESC)
///     .limit(50)
///     .execute();
/// ```
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
/// - [AssetResponse] for response structure
class AssetsRequestBuilder extends RequestBuilder {
  AssetsRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, ["assets"]);

  /// Filter assets by asset code.
  ///
  /// Returns only assets with the specified [assetCode] (e.g., 'USD', 'EUR', 'BTC').
  /// Can be combined with [assetIssuer] to get a specific asset.
  ///
  /// Parameters:
  /// - [assetCode]: The asset code to filter by (e.g., 'USD')
  ///
  /// Example:
  /// ```dart
  /// final usdAssets = await sdk.assets.assetCode('USD').execute();
  /// ```
  AssetsRequestBuilder assetCode(String assetCode) {
    queryParameters.addAll({"asset_code": assetCode});
    return this;
  }

  /// Filter assets by issuer account ID.
  ///
  /// Returns only assets issued by the specified [assetIssuer] account.
  /// Can be combined with [assetCode] to get a specific asset.
  ///
  /// Parameters:
  /// - [assetIssuer]: The issuer's account ID (e.g., 'GCDNJUBQSX...')
  ///
  /// Example:
  /// ```dart
  /// final assetsFromIssuer = await sdk.assets
  ///     .assetIssuer('GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B')
  ///     .execute();
  /// ```
  AssetsRequestBuilder assetIssuer(String assetIssuer) {
    queryParameters.addAll({"asset_issuer": assetIssuer});
    return this;
  }

  static Future<Page<AssetResponse>> requestExecute(http.Client httpClient, Uri uri) async {
    TypeToken<Page<AssetResponse>> type = new TypeToken<Page<AssetResponse>>();
    ResponseHandler<Page<AssetResponse>> responseHandler =
        new ResponseHandler<Page<AssetResponse>>(type);

    return await httpClient.get(uri, headers: RequestBuilder.headers).then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  /// Build and execute the request.
  ///
  /// Returns a [Page] of [AssetResponse] objects containing asset information
  /// including statistics and authorization flags.
  ///
  /// Example:
  /// ```dart
  /// final page = await sdk.assets.assetCode('USD').limit(10).execute();
  /// for (var asset in page.records) {
  ///   print('${asset.assetCode} issued by ${asset.assetIssuer}');
  ///   print('  Accounts: ${asset.numAccounts}');
  ///   print('  Amount: ${asset.amount}');
  /// }
  /// ```
  Future<Page<AssetResponse>> execute() {
    return AssetsRequestBuilder.requestExecute(this.httpClient, this.buildUri());
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
