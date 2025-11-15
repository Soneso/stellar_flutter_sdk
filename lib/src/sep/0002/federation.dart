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
/// Usernames can be standard names, email addresses (e.g., maria@gmail.com*stellar.org),
/// or phone numbers in international format (e.g., +14155550100*stellar.org).
///
/// Supported SEP-0002 version: 1.1.0
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
  /// corresponding Stellar account ID, memo, and other metadata. The username
  /// portion can be a standard name, email address, or phone number in
  /// international format (ITU-T E.164).
  ///
  /// The method automatically discovers the federation server by querying the
  /// domain's stellar.toml file and sends a federation request with type "name".
  ///
  /// Parameters:
  /// - [address] Federation address in format "name*domain.com"
  /// - [httpClient] Optional custom HTTP client for network requests
  /// - [httpRequestHeaders] Optional custom headers for HTTP requests
  ///
  /// Returns:
  /// A [FederationResponse] containing the account ID, optional memo information,
  /// and the stellar address.
  ///
  /// Throws:
  /// - [Exception] if the address format is invalid (missing * separator)
  /// - [Exception] if no federation server is found in the domain's stellar.toml
  /// - [Exception] if the network request fails or returns an error status
  ///
  /// Example:
  /// ```dart
  /// final response = await Federation.resolveStellarAddress('alice*stellar.org');
  /// print('Send to: ${response.accountId}');
  /// if (response.memoType != null) {
  ///   print('Include memo: ${response.memo} (type: ${response.memoType})');
  /// }
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

  /// Performs reverse federation lookup to resolve an account ID to a Stellar address.
  ///
  /// Takes a Stellar account ID and queries the federation server to find the
  /// corresponding human-readable Stellar address. This is useful for identifying
  /// who sent a payment or for displaying user-friendly names instead of public keys.
  ///
  /// Note: Reverse lookups may be ambiguous if an anchor sends transactions on behalf
  /// of its users, as the account ID will be the anchor's ID. In such cases, use
  /// [resolveStellarTransactionId] instead to identify the specific sender.
  ///
  /// Parameters:
  /// - [accountId] Stellar account public key (e.g., GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI)
  /// - [federationServerUrl] Complete URL of the federation server to query
  /// - [httpClient] Optional custom HTTP client for network requests
  /// - [httpRequestHeaders] Optional custom headers for HTTP requests
  ///
  /// Returns:
  /// A [FederationResponse] containing the stellar address and other account details.
  ///
  /// Throws:
  /// - [Exception] if the account ID is not found on the federation server
  /// - [Exception] if the network request fails or returns an error status
  ///
  /// Example:
  /// ```dart
  /// final response = await Federation.resolveStellarAccountId(
  ///   'GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP',
  ///   'https://api.stellar.org/federation',
  /// );
  /// print('Account belongs to: ${response.stellarAddress}');
  /// ```
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

  /// Resolves a transaction ID to identify the sender's Stellar address.
  ///
  /// Takes a transaction hash and queries the federation server to find the
  /// Stellar address of the transaction sender. This is particularly useful when
  /// an anchor or institution sends transactions on behalf of users, making
  /// account ID lookups ambiguous.
  ///
  /// Parameters:
  /// - [txId] Transaction hash (e.g., c1b368c00e9852351361e07cc58c54277e7a6366580044ab152b8db9cd8ec52a)
  /// - [federationServerUrl] Complete URL of the federation server to query
  /// - [httpClient] Optional custom HTTP client for network requests
  /// - [httpRequestHeaders] Optional custom headers for HTTP requests
  ///
  /// Returns:
  /// A [FederationResponse] containing the sender's stellar address and account details.
  ///
  /// Throws:
  /// - [Exception] if the transaction ID is not found on the federation server
  /// - [Exception] if the network request fails or returns an error status
  ///
  /// Example:
  /// ```dart
  /// final response = await Federation.resolveStellarTransactionId(
  ///   'c1b368c00e9852351361e07cc58c54277e7a6366580044ab152b8db9cd8ec52a',
  ///   'https://api.stellar.org/federation',
  /// );
  /// print('Payment received from: ${response.stellarAddress}');
  /// ```
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

  /// Performs a forward federation request for cross-network or institutional payments.
  ///
  /// Used when forwarding payments to a different network or financial institution.
  /// The query parameters required vary depending on the destination institution's
  /// requirements, which should be documented in their stellar.toml file.
  ///
  /// Common use cases include forwarding to bank accounts, remittance centers, or
  /// other payment networks. The federation server translates the provided information
  /// into a Stellar account ID and memo for routing the payment.
  ///
  /// Parameters:
  /// - [forwardQueryParameters] Map of institution-specific query parameters (e.g., bank account details, recipient information)
  /// - [federationServerUrl] Complete URL of the federation server to query
  /// - [httpClient] Optional custom HTTP client for network requests
  /// - [httpRequestHeaders] Optional custom headers for HTTP requests
  ///
  /// Returns:
  /// A [FederationResponse] containing the routing account ID and memo information
  /// needed to complete the forwarded payment.
  ///
  /// Throws:
  /// - [Exception] if the forward request is invalid or unsupported by the server
  /// - [Exception] if required query parameters are missing or incorrect
  /// - [Exception] if the network request fails or returns an error status
  ///
  /// Example - Forward to bank account:
  /// ```dart
  /// final response = await Federation.resolveForward(
  ///   {
  ///     'forward_type': 'bank_account',
  ///     'swift': 'BOPBPHMM',
  ///     'acct': '2382376',
  ///   },
  ///   'https://api.example.com/federation',
  /// );
  /// print('Route payment to: ${response.accountId}');
  /// print('With memo: ${response.memo}');
  /// ```
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

/// Represents a federation server response containing resolved account information.
///
/// This response is returned by all federation lookup methods and contains the
/// Stellar account details needed to send payments or identify users.
///
/// All fields are optional as different lookup types may return different subsets
/// of information. For example, forward lookups typically return account ID and memo,
/// while reverse lookups return the stellar address.
///
/// See [SEP-0002 Federation Protocol](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0002.md).
class FederationResponse extends Response {
  /// The human-readable Stellar address in format "name*domain.com".
  ///
  /// Returned by reverse lookups (account ID or transaction ID resolution).
  /// Null for forward federation requests.
  String? stellarAddress;

  /// The Stellar account public key (G... address).
  ///
  /// Always present for successful forward lookups and name resolution.
  /// May be null for some reverse lookup scenarios.
  String? accountId;

  /// The type of memo to attach to transactions sent to this address.
  ///
  /// Valid values: "text", "id", or "hash".
  /// Null if no memo is required for this destination.
  String? memoType;

  /// The memo value to attach to transactions sent to this address.
  ///
  /// The format depends on memoType:
  /// - For "text": UTF-8 string up to 28 bytes
  /// - For "id": Unsigned 64-bit integer as string
  /// - For "hash": Base64-encoded 32-byte hash
  ///
  /// Always represented as a string even for numeric memo types.
  /// Null if no memo is required for this destination.
  String? memo;

  /// Creates a FederationResponse with resolved account and memo information.
  ///
  /// This constructor is typically called internally when deserializing federation
  /// server responses. It stores the account details and any required memo information
  /// for payment routing. Use Federation methods like [Federation.resolveStellarAddress]
  /// to perform federation lookups.
  ///
  /// Parameters:
  /// - [stellarAddress] Human-readable address in format "name*domain.com" (null for forward lookups)
  /// - [accountId] Stellar account public key (G... address)
  /// - [memoType] Type of memo to attach ("text", "id", or "hash", null if none required)
  /// - [memo] Memo value to attach to transactions as string (null if none required)
  FederationResponse(
      this.stellarAddress, this.accountId, this.memoType, this.memo);

  /// Constructs a FederationResponse from JSON returned by federation server.
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

  /// Executes federation request to the specified URI.
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

  /// Sets the federation request type (name, id, txid, or forward).
  _FederationRequestBuilder forType(String type) {
    queryParameters.addAll({"type": type});
    return this;
  }

  /// Sets the query parameter value to look up in the federation request.
  _FederationRequestBuilder forStringToLookUp(String stringToLookUp) {
    queryParameters.addAll({"q": stringToLookUp});
    return this;
  }

  /// Adds additional query parameters for forward federation requests.
  _FederationRequestBuilder forQueryParameters(
      Map<String, String> queryParams) {
    queryParameters.addAll(queryParams);
    return this;
  }

  /// Executes HTTP GET request to federation server and parses response.
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

  /// Builds and executes the federation request with accumulated parameters.
  Future<FederationResponse> execute() {
    return _FederationRequestBuilder.requestExecute(
        this.httpClient, this.buildUri());
  }
}
