// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:stellar_flutter_sdk/src/key_pair.dart';
import 'package:stellar_flutter_sdk/src/util.dart';

import '../assets.dart';
import "../eventsource/eventsource.dart";
import '../responses/account_response.dart';
import '../responses/account_data_response.dart';
import '../responses/response.dart';
import 'request_builder.dart';

/// Builder for requests to the accounts endpoint.
///
/// AccountsRequestBuilder provides methods for querying account information
/// from the Horizon server. It supports filtering by signer, asset, sponsor,
/// and liquidity pool, as well as retrieving individual account details and
/// account data entries.
///
/// Example:
/// ```dart
/// // Get a specific account
/// var account = await sdk.accounts.account(accountId);
///
/// // Get accounts that trust a specific asset
/// var accounts = await sdk.accounts
///     .forAsset(asset)
///     .limit(20)
///     .execute();
///
/// // Get accounts with a specific signer
/// var signerAccounts = await sdk.accounts
///     .forSigner(signerAccountId)
///     .execute();
///
/// // Stream account updates
/// sdk.accounts.forAccount(accountId).stream().listen((account) {
///   print('Account updated: ${account.id}');
/// });
/// ```
///
/// See also:
/// - [Horizon Accounts API](https://developers.stellar.org/api/resources/accounts/)
class AccountsRequestBuilder extends RequestBuilder {
  static const String ASSET_PARAMETER_NAME = "asset";
  static const String SIGNER_PARAMETER_NAME = "signer";
  static const String SPONSOR_PARAMETER_NAME = "sponsor";
  static const String LIQUIDITY_POOL_PARAMETER_NAME = "liquidity_pool";

  AccountsRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, ["accounts"]);

  /// Requests specific [uri] and returns AccountResponse.
  /// This method is helpful for getting the links.
  Future<AccountResponse> accountURI(Uri uri) async {
    TypeToken<AccountResponse> type = new TypeToken<AccountResponse>();
    ResponseHandler<AccountResponse> responseHandler =
        ResponseHandler<AccountResponse>(type);

    return await httpClient
        .get(uri, headers: RequestBuilder.headers)
        .then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  /// Retrieves detailed information about a specific account.
  ///
  /// Parameters:
  /// - accountId: The public key of the account to retrieve
  ///
  /// Returns: AccountResponse containing account details
  ///
  /// Example:
  /// ```dart
  /// var account = await sdk.accounts.account(
  ///   'GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B'
  /// );
  /// print('Sequence number: ${account.sequenceNumber}');
  /// print('Native balance: ${account.balances[0].balance}');
  /// ```
  ///
  /// See also:
  /// - [AccountResponse] for response structure
  /// - [Horizon Account Details](https://developers.stellar.org/api/resources/accounts/single/)
  Future<AccountResponse> account(String accountId) {
    this.setSegments(["accounts", accountId]);
    return this.accountURI(this.buildUri());
  }

  /// Retrieves a specific data entry for an account.
  ///
  /// Accounts can store arbitrary key-value data. This method retrieves
  /// the value for a specific key.
  ///
  /// Parameters:
  /// - accountId: The public key of the account
  /// - key: The data entry key to retrieve
  ///
  /// Returns: AccountDataResponse containing the data value
  ///
  /// Example:
  /// ```dart
  /// var data = await sdk.accounts.accountData(accountId, 'my_key');
  /// print('Data value: ${data.valueDecoded}');
  /// ```
  ///
  /// See also:
  /// - [AccountDataResponse] for response structure
  /// - [Horizon Account Data](https://developers.stellar.org/api/resources/accounts/data/)
  Future<AccountDataResponse> accountData(String accountId, String key) async {
    this.setSegments(["accounts", accountId, "data", key]);
    TypeToken<AccountDataResponse> type = new TypeToken<AccountDataResponse>();
    ResponseHandler<AccountDataResponse> responseHandler =
        ResponseHandler<AccountDataResponse>(type);

    return await httpClient
        .get(this.buildUri(), headers: RequestBuilder.headers)
        .then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  /// Filters accounts by signer.
  ///
  /// Returns all accounts that have the specified account as a signer.
  ///
  /// Parameters:
  /// - signerAccountId: Public key of the signer to filter by
  ///
  /// Returns: This builder instance for method chaining
  ///
  /// Throws:
  /// - Exception: If forAsset was already called (cannot combine filters)
  ///
  /// Example:
  /// ```dart
  /// var accounts = await sdk.accounts
  ///     .forSigner('GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B')
  ///     .execute();
  /// ```
  ///
  /// See also:
  /// - [Horizon Accounts Endpoint](https://developers.stellar.org/api/resources/accounts/)
  AccountsRequestBuilder forSigner(String signerAccountId) {
    if (queryParameters.containsKey(ASSET_PARAMETER_NAME)) {
      throw new Exception("cannot set both signer and asset");
    }
    queryParameters.addAll({SIGNER_PARAMETER_NAME: signerAccountId});
    return this;
  }

  /// Filters accounts by sponsor.
  ///
  /// Returns all accounts sponsored by the specified account. This includes
  /// accounts whose creation was sponsored and accounts with sponsored reserves.
  ///
  /// Parameters:
  /// - sponsorAccountId: Public key of the sponsor to filter by
  ///
  /// Returns: This builder instance for method chaining
  ///
  /// Example:
  /// ```dart
  /// var accounts = await sdk.accounts
  ///     .forSponsor('GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B')
  ///     .execute();
  /// ```
  ///
  /// See also:
  /// - [Horizon Accounts Endpoint](https://developers.stellar.org/api/resources/accounts/)
  AccountsRequestBuilder forSponsor(String sponsorAccountId) {
    queryParameters.addAll({SPONSOR_PARAMETER_NAME: sponsorAccountId});
    return this;
  }

  /// Filters accounts by asset trustline.
  ///
  /// Returns all accounts that hold a trustline for the specified asset.
  ///
  /// Parameters:
  /// - asset: The asset to filter by
  ///
  /// Returns: This builder instance for method chaining
  ///
  /// Throws:
  /// - Exception: If forSigner was already called (cannot combine filters)
  ///
  /// Example:
  /// ```dart
  /// var asset = AssetTypeCreditAlphaNum4('USD', issuerId);
  /// var accounts = await sdk.accounts
  ///     .forAsset(asset)
  ///     .limit(50)
  ///     .execute();
  /// ```
  ///
  /// See also:
  /// - [Horizon Accounts Endpoint](https://developers.stellar.org/api/resources/accounts/)
  AccountsRequestBuilder forAsset(Asset asset) {
    if (queryParameters.containsKey(SIGNER_PARAMETER_NAME)) {
      throw new Exception("cannot set both signer and asset");
    }
    queryParameters.addAll({ASSET_PARAMETER_NAME: encodeAsset(asset)});
    return this;
  }

  /// Filters accounts by liquidity pool participation.
  ///
  /// Returns all accounts that have a balance in the specified liquidity pool.
  ///
  /// Parameters:
  /// - poolId: Liquidity pool ID (hex string or L-prefixed)
  ///
  /// Returns: This builder instance for method chaining
  ///
  /// Example:
  /// ```dart
  /// var accounts = await sdk.accounts
  ///     .forLiquidityPool(liquidityPoolId)
  ///     .execute();
  /// ```
  AccountsRequestBuilder forLiquidityPool(String poolId) {
    var id = poolId;
    if (id.startsWith("L")) {
      try {
        id = Util.bytesToHex(StrKey.decodeLiquidityPoolId(poolId));
      } catch (_) {}
    }
    queryParameters.addAll({LIQUIDITY_POOL_PARAMETER_NAME: id});
    return this;
  }

  /// Requests specific uri and returns Page of AccountResponse.
  /// This method is helpful for getting the next set of results.
  static Future<Page<AccountResponse>> requestExecute(
      http.Client httpClient, Uri uri) async {
    TypeToken<Page<AccountResponse>> type =
        new TypeToken<Page<AccountResponse>>();
    ResponseHandler<Page<AccountResponse>> responseHandler =
        new ResponseHandler<Page<AccountResponse>>(type);

    return await httpClient
        .get(uri, headers: RequestBuilder.headers)
        .then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  /// Opens a stream to listen for account updates in real-time.
  ///
  /// Uses Server-Sent Events (SSE) to maintain an open connection to Horizon.
  /// The stream will emit AccountResponse objects as accounts are created or
  /// updated on the ledger.
  ///
  /// Returns: Stream of AccountResponse objects
  ///
  /// Example:
  /// ```dart
  /// // Stream all new accounts
  /// sdk.accounts
  ///     .cursor('now')
  ///     .stream()
  ///     .listen((account) {
  ///       print('New account: ${account.id}');
  ///     });
  ///
  /// // Stream updates for accounts holding an asset
  /// sdk.accounts
  ///     .forAsset(asset)
  ///     .stream()
  ///     .listen((account) {
  ///       print('Account updated: ${account.id}');
  ///     });
  /// ```
  ///
  /// See also:
  /// - [Horizon Streaming](https://developers.stellar.org/api/introduction/streaming/)
  Stream<AccountResponse> stream() {
    StreamController<AccountResponse> listener = StreamController.broadcast();

    bool cancelled = false;
    EventSource? source;

    Future<void> createNewEventSource() async {
      if (cancelled) {
        return;
      }
      source?.close();
      source = await EventSource.connect(
        this.buildUri(),
        client: httpClient,
      );
      source!.listen((Event event) async {
        if (cancelled) {
          return null;
        }
        if (event.event == "open") {
          return null;
        }
        if (event.event == "close") {
          // Reconnect on close to stream infinitely
          createNewEventSource();
          return null;
        }
        try {
          AccountResponse operationResponse = AccountResponse.fromJson(
            json.decode(event.data!),
          );
          listener.add(operationResponse);
        } catch (e, stackTrace) {
          listener.addError(e, stackTrace);
          createNewEventSource();
        }
      });
    }

    listener.onListen = () {
      cancelled = false;
      createNewEventSource();
    };
    listener.onCancel = () {
      if (!listener.hasListener) {
        cancelled = true;
        source?.close();
      }
    };

    return listener.stream;
  }

  /// Builds and executes the request.
  ///
  /// Returns: Page of AccountResponse objects
  ///
  /// Example:
  /// ```dart
  /// var page = await sdk.accounts
  ///     .forAsset(asset)
  ///     .limit(20)
  ///     .execute();
  ///
  /// for (var account in page.records) {
  ///   print('Account: ${account.id}');
  /// }
  /// ```
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
