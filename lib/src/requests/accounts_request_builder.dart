// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import "package:eventsource/eventsource.dart";
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import '../responses/response.dart';
import '../responses/account_response.dart';
import 'request_builder.dart';
import '../assets.dart';

/// Provides information on a specific account.
/// See <a href="https://developers.stellar.org/api/resources/accounts/single/" target="_blank">Account Details</a>
class AccountsRequestBuilder extends RequestBuilder {
  static const String ASSET_PARAMETER_NAME = "asset";
  static const String SIGNER_PARAMETER_NAME = "signer";
  static const String SPONSOR_PARAMETER_NAME = "sponsor";

  AccountsRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, ["accounts"]);

  /// Requests specific [uri] and returns AccountResponse.
  /// This method is helpful for getting the links.
  Future<AccountResponse> accountURI(Uri uri) async {
    TypeToken type = new TypeToken<AccountResponse>();
    ResponseHandler<AccountResponse> responseHandler =
        ResponseHandler<AccountResponse>(type);

    return await httpClient
        .get(uri, headers: RequestBuilder.headers)
        .then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  /// Requests details about the account to fetch by [accountId].
  /// See <a href="https://developers.stellar.org/api/resources/accounts/single/" target="_blank">Account Details</a>
  Future<AccountResponse> account(String accountId) {
    this.setSegments(["accounts", accountId]);
    return this.accountURI(this.buildUri());
  }

  /// Returns all accounts that contain a specific signer given by the [signerAccountId]
  /// See: <a href="https://developers.stellar.org/api/resources/accounts/" target="_blank">Accounts</a>
  AccountsRequestBuilder forSigner(String signerAccountId) {
    if (queryParameters.containsKey(ASSET_PARAMETER_NAME)) {
      throw new Exception("cannot set both signer and asset");
    }
    queryParameters.addAll({SIGNER_PARAMETER_NAME: signerAccountId});
    return this;
  }

  /// Returns all accounts that contain a specific sponsor given by the [sponsorAccountId]
  /// See: <a href="https://developers.stellar.org/api/resources/accounts/" target="_blank">Accounts</a>
  AccountsRequestBuilder forSponsor(String sponsorAccountId) {
    queryParameters.addAll({SPONSOR_PARAMETER_NAME: sponsorAccountId});
    return this;
  }

  /// Returns all accounts who are trustees to a specific [asset].
  /// See: <a href="https://developers.stellar.org/api/resources/accounts/" target="_blank">Accounts</a>
  AccountsRequestBuilder forAsset(Asset asset) {
    if (queryParameters.containsKey(SIGNER_PARAMETER_NAME)) {
      throw new Exception("cannot set both signer and asset");
    }
    queryParameters.addAll({ASSET_PARAMETER_NAME: encodeAsset(asset)});
    return this;
  }

  /// Requests specific uri and returns Page of AccountResponse.
  /// This method is helpful for getting the next set of results.
  static Future<Page<AccountResponse>> requestExecute(
      http.Client httpClient, Uri uri) async {
    TypeToken type = new TypeToken<Page<AccountResponse>>();
    ResponseHandler<Page<AccountResponse>> responseHandler =
        new ResponseHandler<Page<AccountResponse>>(type);

    return await httpClient
        .get(uri, headers: RequestBuilder.headers)
        .then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  /// Allows to stream SSE events from horizon.
  /// Certain endpoints in Horizon can be called in streaming mode using Server-Sent Events.
  /// This mode will keep the connection to horizon open and horizon will continue to return
  /// responses as ledgers close.
  /// See: <a href="https://developers.stellar.org/api/introduction/streaming/" target="_blank">Streaming</a>
  Stream<AccountResponse> stream() {
    StreamController<AccountResponse> listener =
        new StreamController.broadcast();
    EventSource.connect(this.buildUri()).then((eventSource) {
      eventSource.listen((Event event) {
        if (event.data == "\"hello\"" || event.event == "close") {
          return null;
        }
        AccountResponse accountResponse =
            AccountResponse.fromJson(json.decode(event.data));
        listener.add(accountResponse);
      });
    });
    return listener.stream;
  }

  /// Build and execute request.
  Future<Page<AccountResponse>> execute() {
    return AccountsRequestBuilder.requestExecute(
        this.httpClient, this.buildUri());
  }

  @override
  AccountsRequestBuilder cursor(String token) {
    super.cursor(token);
    return this;
  }

  @override
  AccountsRequestBuilder limit(int number) {
    super.limit(number);
    return this;
  }

  @override
  AccountsRequestBuilder order(RequestBuilderOrder direction) {
    super.order(direction);
    return this;
  }
}
