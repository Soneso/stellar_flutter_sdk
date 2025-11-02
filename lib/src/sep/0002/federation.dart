// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:http/http.dart' as http;
import 'dart:async';
import '../0001/stellar_toml.dart';
import '../../responses/response.dart';
import '../../requests/request_builder.dart';

/// Implements SEP-0002 Federation protocol for human-readable Stellar addresses.
///
/// Federation allows users to use human-readable addresses like name*domain.com
/// instead of cryptic public keys (G...). This makes Stellar more user-friendly
/// by allowing addresses similar to email addresses.
///
/// The protocol works by resolving addresses through federation servers that
/// map human-readable names to Stellar account IDs, memos, and other information.
///
/// Example - Resolve a Stellar address:
/// ```dart
/// final response = await Federation.resolveStellarAddress('bob*example.com');
/// print('Account ID: ${response.accountId}');
/// print('Memo: ${response.memo}');
/// print('Memo type: ${response.memoType}');
/// ```
///
/// Example - Reverse lookup (account to name):
/// ```dart
/// final response = await Federation.resolveStellarAccountId(
///   'GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP',
///   'example.com',
/// );
/// print('Stellar address: ${response.stellarAddress}');
/// ```
///
/// See also:
/// - [SEP-0002 Specification](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0002.md)
class Federation {
  /// Resolves a federation address to Stellar account information.
  ///
  /// Takes a human-readable address like "bob*example.com" and returns the
  /// corresponding Stellar account ID, memo, and other metadata.
  ///
  /// Parameters:
  /// - address: Federation address in format "name*domain.com"
  /// - httpClient: Optional custom HTTP client
  /// - httpRequestHeaders: Optional custom headers
  ///
  /// Returns: Future<FederationResponse> with account details
  ///
  /// Throws:
  /// - Exception: If address format is invalid or federation server not found
  ///
  /// Example:
  /// ```dart
  /// final response = await Federation.resolveStellarAddress('alice*stellar.org');
  /// print('Send to: ${response.accountId}');
  /// ```
  static Future<FederationResponse> resolveStellarAddress(String address,
      {http.Client? httpClient,
      Map<String, String>? httpRequestHeaders}) async {
    if (!address.contains("*")) {
      throw Exception("invalid federation address: $address");
    }

    String domain = address.split("*").last;
    StellarToml toml = await StellarToml.fromDomain(domain,
        httpClient: httpClient, httpRequestHeaders: httpRequestHeaders);
    String? federationServer = toml.generalInformation.federationServer;
    if (federationServer == null) {
      throw Exception("no federation server found for domain $domain");
    }

    Uri serverURI = Uri.parse(federationServer);
    http.Client client = httpClient == null ? http.Client() : httpClient;

    _FederationRequestBuilder requestBuilder = _FederationRequestBuilder(
        client, serverURI,
        httpRequestHeaders: httpRequestHeaders);
    FederationResponse response = await requestBuilder
        .forStringToLookUp(address)
        .forType("name")
        .execute();
    return response;
  }

  /// Resolves a stellar account id such as GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI
  /// The url of the federation server has to be provided.
  /// Returns a [FederationResponse] object.
  static Future<FederationResponse> resolveStellarAccountId(
      String accountId, String federationServerUrl,
      {http.Client? httpClient,
      Map<String, String>? httpRequestHeaders}) async {
    Uri serverURI = Uri.parse(federationServerUrl);
    http.Client client = httpClient == null ? http.Client() : httpClient;

    _FederationRequestBuilder requestBuilder = _FederationRequestBuilder(
        client, serverURI,
        httpRequestHeaders: httpRequestHeaders);
    FederationResponse response = await requestBuilder
        .forStringToLookUp(accountId)
        .forType("id")
        .execute();
    return response;
  }

  /// Resolves a stellar account transaction id such as c1b368c00e9852351361e07cc58c54277e7a6366580044ab152b8db9cd8ec52a
  /// The url of the federation server has to be provided.
  /// Returns a [FederationResponse] object.
  static Future<FederationResponse> resolveStellarTransactionId(
      String txId, String federationServerUrl,
      {http.Client? httpClient,
      Map<String, String>? httpRequestHeaders}) async {
    Uri serverURI = Uri.parse(federationServerUrl);
    http.Client client = httpClient == null ? http.Client() : httpClient;

    _FederationRequestBuilder requestBuilder = _FederationRequestBuilder(
        client, serverURI,
        httpRequestHeaders: httpRequestHeaders);
    FederationResponse response =
        await requestBuilder.forStringToLookUp(txId).forType("txid").execute();
    return response;
  }

  /// Resolves a stellar forward.
  /// The url of the federation server and the forward query parameters have to be provided.
  /// Returns a [FederationResponse] object.
  static Future<FederationResponse> resolveForward(
      Map<String, String> forwardQueryParameters, String federationServerUrl,
      {http.Client? httpClient,
      Map<String, String>? httpRequestHeaders}) async {
    Uri serverURI = Uri.parse(federationServerUrl);
    http.Client client = httpClient == null ? http.Client() : httpClient;

    _FederationRequestBuilder requestBuilder = _FederationRequestBuilder(
        client, serverURI,
        httpRequestHeaders: httpRequestHeaders);
    FederationResponse response = await requestBuilder
        .forType("forward")
        .forQueryParameters(forwardQueryParameters)
        .execute();
    return response;
  }
}

/// Represents an federation server response.
/// See <a href="https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0002.md" target="_blank">Federation Protocol</a>.
class FederationResponse extends Response {
  String? stellarAddress;
  String? accountId;
  String? memoType;
  String? memo;

  FederationResponse(
      this.stellarAddress, this.accountId, this.memoType, this.memo);

  factory FederationResponse.fromJson(Map<String, dynamic> json) =>
      FederationResponse(
          json['stellar_address'],
          json['account_id'],
          json['memo_type'] == null ? null : json['memo_type'],
          json['memo'] == null ? null : json['memo']);
}

// Requests the federation data.
class _FederationRequestBuilder extends RequestBuilder {
  Map<String, String>? httpRequestHeaders;

  _FederationRequestBuilder(http.Client httpClient, Uri serverURI,
      {this.httpRequestHeaders})
      : super(httpClient, serverURI, null);

  Future<FederationResponse> federationURI(Uri uri) async {
    TypeToken<FederationResponse> type = TypeToken<FederationResponse>();
    ResponseHandler<FederationResponse> responseHandler =
        ResponseHandler<FederationResponse>(type);

    return await httpClient
        .get(uri, headers: httpRequestHeaders)
        .then((response) {
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

  _FederationRequestBuilder forQueryParameters(
      Map<String, String> queryParams) {
    queryParameters.addAll(queryParams);
    return this;
  }

  static Future<FederationResponse> requestExecute(
      http.Client httpClient, Uri uri,
      {Map<String, String>? httpRequestHeaders}) async {
    TypeToken<FederationResponse> type = TypeToken<FederationResponse>();
    ResponseHandler<FederationResponse> responseHandler =
        ResponseHandler<FederationResponse>(type);

    return await httpClient
        .get(
      uri,
      headers: httpRequestHeaders,
    )
        .then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  Future<FederationResponse> execute() {
    return _FederationRequestBuilder.requestExecute(
        this.httpClient, this.buildUri());
  }
}
