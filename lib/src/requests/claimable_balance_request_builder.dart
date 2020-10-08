// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:http/http.dart' as http;
import '../assets.dart';
import '../responses/claimable_balance_response.dart';
import 'dart:async';
import '../responses/response.dart';
import 'request_builder.dart';

/// See <a href="https://developers.stellar.org/api/resources/claimablebalances/" target="_blank">Claimable Balance</a>
class ClaimableBalancesRequestBuilder extends RequestBuilder {
  static const String SPONSOR_PARAMETER_NAME = "sponsor";
  static const String CLAIMANT_PARAMETER_NAME = "claimant";
  static const String ASSET_PARAMETER_NAME = "asset";

  ClaimableBalancesRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, ["claimable_balances"]);

  /// Requests specific [uri] and returns ClaimableBalancesResponse.
  /// This method is helpful for getting the links.
  Future<ClaimableBalanceResponse> claimableBalance(Uri uri) async {
    TypeToken type = new TypeToken<ClaimableBalanceResponse>();
    ResponseHandler<ClaimableBalanceResponse> responseHandler =
        ResponseHandler<ClaimableBalanceResponse>(type);

    return await httpClient
        .get(uri, headers: RequestBuilder.headers)
        .then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  /// Requests details about the claimable balance to fetch by [balanceId].
  /// See <a href="https://developers.stellar.org/api/resources/claimablebalances/" target="_blank">Claimable Balances</a>
  Future<ClaimableBalanceResponse> forBalanceId(String balanceId) {
    this.setSegments(["claimable_balances", balanceId]);
    return this.claimableBalance(this.buildUri());
  }

  /// Returns all claimable balances for the account id of the sponsor who is paying the reserves for this claimable balances.
  /// See: <a href="https://developers.stellar.org/api/resources/accounts/" target="_blank">Claimable Balances</a>
  ClaimableBalancesRequestBuilder forSponsor(String signerAccountId) {
    queryParameters.addAll({SPONSOR_PARAMETER_NAME: signerAccountId});
    return this;
  }

  /// Returns all claimable balances for the accountId of a claimant.
  /// See: <a href="https://developers.stellar.org/api/resources/accounts/" target="_blank">Claimable Balances</a>
  ClaimableBalancesRequestBuilder forClaimant(String claimantAccountId) {
    queryParameters.addAll({CLAIMANT_PARAMETER_NAME: claimantAccountId});
    return this;
  }

  /// Returns all claimable balances for an asset.
  /// See: <a href="https://developers.stellar.org/api/resources/accounts/" target="_blank">Claimable Balances</a>
  ClaimableBalancesRequestBuilder forAsset(Asset asset) {
    queryParameters.addAll({ASSET_PARAMETER_NAME: Asset.canonicalForm(asset)});
    return this;
  }

  /// Requests specific uri and returns Page of ClaimableBalanceResponse.
  /// This method is helpful for getting the next set of results.
  static Future<Page<ClaimableBalanceResponse>> requestExecute(
      http.Client httpClient, Uri uri) async {
    print(uri.toString());
    TypeToken type = new TypeToken<Page<ClaimableBalanceResponse>>();
    ResponseHandler<Page<ClaimableBalanceResponse>> responseHandler =
        new ResponseHandler<Page<ClaimableBalanceResponse>>(type);

    return await httpClient
        .get(uri, headers: RequestBuilder.headers)
        .then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  /// Build and execute request.
  Future<Page<ClaimableBalanceResponse>> execute() {
    return ClaimableBalancesRequestBuilder.requestExecute(
        this.httpClient, this.buildUri());
  }

  @override
  ClaimableBalancesRequestBuilder cursor(String token) {
    super.cursor(token);
    return this;
  }

  @override
  ClaimableBalancesRequestBuilder limit(int number) {
    super.limit(number);
    return this;
  }

  @override
  ClaimableBalancesRequestBuilder order(RequestBuilderOrder direction) {
    super.order(direction);
    return this;
  }
}
