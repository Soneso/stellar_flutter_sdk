// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:http/http.dart' as http;
import 'dart:async';
import 'request_builder.dart';
import '../responses/response.dart';
import '../responses/offer_response.dart';
import '../util.dart';
import '../assets.dart';
import '../asset_type_credit_alphanum.dart';

/// Builds requests connected to offers.
class OffersRequestBuilder extends RequestBuilder {
  OffersRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, ["offers"]);

  /// Returns the offers for a given account by [accountId].
  /// See: <a href="https://www.stellar.org/developers/horizon/reference/endpoints/offers-for-account.html">Payments for Account</a>
  OffersRequestBuilder forAccount(String accountId) {
    accountId = checkNotNull(accountId, "accountId cannot be null");
    this.setSegments(["accounts", accountId, "offers"]);
    return this;
  }

  /// Returns all offers where the given account is the seller.
  /// See <a href="https://www.stellar.org/developers/horizon/reference/endpoints/offers.html">Offers</a>
  OffersRequestBuilder forSeller(String seller) {
    seller = checkNotNull(seller, "seller cannot be null");
    queryParameters.addAll({"seller": seller});
    return this;
  }

  /// Returns all offers buying an [asset].
  /// See <a href="https://www.stellar.org/developers/horizon/reference/endpoints/offers.html">Offers</a>
  OffersRequestBuilder forBuyingAsset(Asset asset) {
    asset = checkNotNull(asset, "asset cannot be null");
    queryParameters.addAll({"buying": _encodeAsset(asset)});
    return this;
  }

  /// Returns all selling buying an [asset].
  /// See <a href="https://www.stellar.org/developers/horizon/reference/endpoints/offers.html">Offers</a>
  OffersRequestBuilder forSellingAsset(Asset asset) {
    asset = checkNotNull(asset, "asset cannot be null");
    queryParameters.addAll({"selling": _encodeAsset(asset)});
    return this;
  }

  static String _encodeAsset(Asset asset) {
    asset = checkNotNull(asset, "asset cannot be null");
    if (asset.type == Asset.TYPE_NATIVE) {
      return Asset.TYPE_NATIVE;
    } else {
      return (asset as AssetTypeCreditAlphaNum).code +
          ":" +
          (asset as AssetTypeCreditAlphaNum).issuer;
    }
  }

  /// Requests specific uri and returns Page of OfferResponse.
  /// This method is helpful for getting the next set of results.
  static Future<Page<OfferResponse>> requestExecute(
      http.Client httpClient, Uri uri) async {
    TypeToken type = new TypeToken<Page<OfferResponse>>();
    ResponseHandler<Page<OfferResponse>> responseHandler =
        new ResponseHandler<Page<OfferResponse>>(type);

    return await httpClient
        .get(uri, headers: RequestBuilder.headers)
        .then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  /// Build and execute request.
  Future<Page<OfferResponse>> execute() {
    return OffersRequestBuilder.requestExecute(
        this.httpClient, this.buildUri());
  }

  @override
  OffersRequestBuilder cursor(String token) {
    super.cursor(token);
    return this;
  }

  @override
  OffersRequestBuilder limit(int number) {
    super.limit(number);
    return this;
  }

  @override
  OffersRequestBuilder order(RequestBuilderOrder direction) {
    super.order(direction);
    return this;
  }
}
