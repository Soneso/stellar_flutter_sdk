// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:http/http.dart' as http;
import 'dart:async';
import '../0001/stellar_toml.dart';
import '../../responses/response.dart';
import '../../requests/request_builder.dart';
import '../../util.dart';

/// Implements Federation protocol.
/// See <a href="https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0002.md" target="_blank">Federation Protocol</a>
class Federation {
  /// Resolves a stellar address such as bob*soneso.com.
  /// Returns a [FederationResponse] object.
  static Future<FederationResponse> resolveStellarAddress(String address) async {
    String addr = checkNotNull(address, "address can not be null");
    if (!addr.contains("*")) {
      throw new Exception("invalid federation address: $addr");
    }

    String domain = addr.split("*").last;
    StellarToml toml = await StellarToml.fromDomain(domain);
    String? federationServer = toml.generalInformation?.federationServer;
    if (federationServer == null) {
      throw new Exception("no federation server found for domain $domain");
    }

    Uri serverURI = Uri.parse(federationServer);
    http.Client httpClient = new http.Client();

    _FederationRequestBuilder requestBuilder = new _FederationRequestBuilder(httpClient, serverURI);
    FederationResponse response =
        await requestBuilder.forStringToLookUp(addr).forType("name").execute();
    return response;
  }

  /// Resolves a stellar account id such as GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI
  /// The url of the federation server has to be provided.
  /// Returns a [FederationResponse] object.
  static Future<FederationResponse> resolveStellarAccountId(
      String accountId, String federationServerUrl) async {
    String id = checkNotNull(accountId, "accountId can not be null");
    String server = checkNotNull(federationServerUrl, "federationServerUrl can not be null");

    Uri serverURI = Uri.parse(server);
    http.Client httpClient = new http.Client();

    _FederationRequestBuilder requestBuilder = new _FederationRequestBuilder(httpClient, serverURI);
    FederationResponse response =
        await requestBuilder.forStringToLookUp(id).forType("id").execute();
    return response;
  }

  /// Resolves a stellar account transaction id such as c1b368c00e9852351361e07cc58c54277e7a6366580044ab152b8db9cd8ec52a
  /// The url of the federation server has to be provided.
  /// Returns a [FederationResponse] object.
  static Future<FederationResponse> resolveStellarTransactionId(
      String txId, String federationServerUrl) async {
    String id = checkNotNull(txId, "txId can not be null");
    String server = checkNotNull(federationServerUrl, "federationServerUrl can not be null");

    Uri serverURI = Uri.parse(server);
    http.Client httpClient = new http.Client();

    _FederationRequestBuilder requestBuilder = new _FederationRequestBuilder(httpClient, serverURI);
    FederationResponse response =
        await requestBuilder.forStringToLookUp(id).forType("txid").execute();
    return response;
  }

  /// Resolves a stellar forward.
  /// The url of the federation server and the forward query parameters have to be provided.
  /// Returns a [FederationResponse] object.
  static Future<FederationResponse> resolveForward(
      Map<String, String> forwardQueryParameters, String federationServerUrl) async {
    Map<String, String> params =
        checkNotNull(forwardQueryParameters, "forwardQueryParameters can not be null");
    String server = checkNotNull(federationServerUrl, "federationServerUrl can not be null");

    Uri serverURI = Uri.parse(server);
    http.Client httpClient = new http.Client();

    _FederationRequestBuilder requestBuilder = new _FederationRequestBuilder(httpClient, serverURI);
    FederationResponse response =
        await requestBuilder.forType("forward").forQueryParameters(params).execute();
    return response;
  }
}

/// Represents an federation server response.
/// See <a href="https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0002.md" target="_blank">Federation Protocol</a>.
class FederationResponse extends Response {
  String stellarAddress;
  String accountId;
  String? memoType;
  String? memo;

  FederationResponse(this.stellarAddress, this.accountId, this.memoType, this.memo);

  factory FederationResponse.fromJson(Map<String, dynamic> json) => new FederationResponse(
      json['stellar_address'] as String,
      json['account_id'] as String,
      json['memo_type'] == null ? null : json['memo_type'] as String,
      json['memo'] == null ? null : json['memo'] as String);
}

// Requests the federation data.
class _FederationRequestBuilder extends RequestBuilder {
  _FederationRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, null);

  Future<FederationResponse> federationURI(Uri uri) async {
    TypeToken<FederationResponse> type = new TypeToken<FederationResponse>();
    ResponseHandler<FederationResponse> responseHandler = ResponseHandler<FederationResponse>(type);

    return await httpClient.get(uri, headers: RequestBuilder.headers).then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  _FederationRequestBuilder forType(String type) {
    queryParameters.addAll({"type": type});
    return this;
  }

  _FederationRequestBuilder forStringToLookUp(String stringToLookUp) {
    queryParameters.addAll({"q": stringToLookUp});
    return this;
  }

  _FederationRequestBuilder forQueryParameters(Map<String, String> queryParams) {
    queryParameters.addAll(queryParams);
    return this;
  }

  static Future<FederationResponse> requestExecute(http.Client httpClient, Uri uri) async {
    TypeToken<FederationResponse> type = new TypeToken<FederationResponse>();
    ResponseHandler<FederationResponse> responseHandler =
        new ResponseHandler<FederationResponse>(type);

    return await httpClient.get(uri, headers: RequestBuilder.headers).then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  Future<FederationResponse> execute() {
    return _FederationRequestBuilder.requestExecute(this.httpClient, this.buildUri());
  }
}
