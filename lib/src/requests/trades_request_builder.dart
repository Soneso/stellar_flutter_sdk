// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:stellar_flutter_sdk/src/key_pair.dart';
import 'package:stellar_flutter_sdk/src/util.dart';

import '../asset_type_credit_alphanum.dart';
import '../assets.dart';
import "../eventsource/eventsource.dart";
import '../responses/response.dart';
import '../responses/trade_response.dart';
import 'request_builder.dart';

/// Builds requests for trades.
///
/// A trade represents the fulfillment of an offer on the Stellar network. Trades
/// occur when offers are matched, either through direct trading or as part of
/// path payments. Each trade involves two parties and two assets - a base asset
/// and a counter asset.
///
/// Trades can be filtered by:
/// - Account (all trades involving an account)
/// - Trading pair (base and counter assets)
/// - Offer ID (trades for a specific offer)
/// - Liquidity pool (trades involving pool shares)
/// - Trade type (orderbook trades vs liquidity pool trades)
///
/// Example:
/// ```dart
/// // Get recent trades for an account
/// var trades = await sdk.trades
///     .forAccount(accountId)
///     .order(RequestBuilderOrder.DESC)
///     .limit(20)
///     .execute();
///
/// // Get trades for a specific trading pair
/// var pairTrades = await sdk.trades
///     .baseAsset(Asset.createNonNativeAsset('XLM', issuerId))
///     .counterAsset(Asset.createNonNativeAsset('USDC', issuerId))
///     .execute();
///
/// // Stream new trades in real-time
/// sdk.trades
///     .cursor('now')
///     .stream()
///     .listen((trade) {
///       print('Trade: ${trade.baseAmount} ${trade.baseAssetType}');
///       print('Price: ${trade.price}');
///     });
/// ```
///
/// See also:
/// - [Horizon Trades API](https://developers.stellar.org/docs/data/horizon/api-reference/resources/trades)
class TradesRequestBuilder extends RequestBuilder {
  TradesRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, ["trades"]);

  /// Filters trades by base asset.
  ///
  /// Returns trades where the specified asset is the base asset of the pair.
  /// This should typically be used together with counterAsset() to filter
  /// trades for a specific trading pair.
  ///
  /// Parameters:
  /// - asset: The base asset to filter by
  ///
  /// Returns: This builder instance for method chaining
  ///
  /// Example:
  /// ```dart
  /// var trades = await sdk.trades
  ///     .baseAsset(Asset.createNonNativeAsset('XLM', issuerId))
  ///     .counterAsset(Asset.NATIVE)
  ///     .execute();
  /// ```
  TradesRequestBuilder baseAsset(Asset asset) {
    queryParameters.addAll({"base_asset_type": asset.type});
    if (asset is AssetTypeCreditAlphaNum) {
      AssetTypeCreditAlphaNum creditAlphaNumAsset = asset;
      queryParameters.addAll({"base_asset_code": creditAlphaNumAsset.code});
      queryParameters
          .addAll({"base_asset_issuer": creditAlphaNumAsset.issuerId});
    }
    return this;
  }

  /// Filters trades by counter asset.
  ///
  /// Returns trades where the specified asset is the counter asset of the pair.
  /// This should typically be used together with baseAsset() to filter
  /// trades for a specific trading pair.
  ///
  /// Parameters:
  /// - asset: The counter asset to filter by
  ///
  /// Returns: This builder instance for method chaining
  ///
  /// Example:
  /// ```dart
  /// var trades = await sdk.trades
  ///     .baseAsset(Asset.NATIVE)
  ///     .counterAsset(Asset.createNonNativeAsset('USDC', issuerId))
  ///     .execute();
  /// ```
  TradesRequestBuilder counterAsset(Asset asset) {
    queryParameters.addAll({"counter_asset_type": asset.type});
    if (asset is AssetTypeCreditAlphaNum) {
      AssetTypeCreditAlphaNum creditAlphaNumAsset = asset;
      queryParameters.addAll({"counter_asset_code": creditAlphaNumAsset.code});
      queryParameters
          .addAll({"counter_asset_issuer": creditAlphaNumAsset.issuerId});
    }
    return this;
  }

  /// Filters trades by trade type.
  ///
  /// Specifies whether to return orderbook trades, liquidity pool trades, or both.
  ///
  /// Parameters:
  /// - tradeType: Type of trades to include ("orderbook", "liquidity_pool", or "all")
  ///
  /// Returns: This builder instance for method chaining
  ///
  /// Example:
  /// ```dart
  /// // Get only orderbook trades
  /// var trades = await sdk.trades
  ///     .tradeType("orderbook")
  ///     .execute();
  /// ```
  TradesRequestBuilder tradeType(String tradeType) {
    queryParameters.addAll({"trade_type": tradeType});
    return this;
  }

  /// Filters trades by account.
  ///
  /// Returns all trades where the specified account was involved, either as
  /// the buyer or seller.
  ///
  /// Parameters:
  /// - accountId: The account public key
  ///
  /// Returns: This builder instance for method chaining
  ///
  /// Example:
  /// ```dart
  /// var trades = await sdk.trades
  ///     .forAccount('GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B')
  ///     .order(RequestBuilderOrder.DESC)
  ///     .limit(50)
  ///     .execute();
  /// ```
  ///
  /// See also:
  /// - [Horizon Account Trades](https://developers.stellar.org/docs/data/horizon/api-reference/resources/accounts/trades)
  TradesRequestBuilder forAccount(String accountId) {
    this.setSegments(["accounts", accountId, "trades"]);
    return this;
  }

  static Future<Page<TradeResponse>> requestExecute(
      http.Client httpClient, Uri uri) async {
    TypeToken<Page<TradeResponse>> type = TypeToken<Page<TradeResponse>>();
    ResponseHandler<Page<TradeResponse>> responseHandler =
        ResponseHandler<Page<TradeResponse>>(type);

    return await httpClient
        .get(uri, headers: RequestBuilder.headers)
        .then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  /// Builds and executes the request.
  ///
  /// Returns: Page of TradeResponse objects
  ///
  /// Example:
  /// ```dart
  /// var page = await sdk.trades
  ///     .forAccount(accountId)
  ///     .limit(20)
  ///     .execute();
  ///
  /// for (var trade in page.records) {
  ///   print('Trade: ${trade.baseAmount} ${trade.baseAssetType}');
  ///   print('For: ${trade.counterAmount} ${trade.counterAssetType}');
  ///   print('Price: ${trade.price}');
  /// }
  /// ```
  Future<Page<TradeResponse>> execute() {
    return TradesRequestBuilder.requestExecute(
        this.httpClient, this.buildUri());
  }

  /// Filters trades by offer ID.
  ///
  /// Returns all trades that were executed against the specified offer.
  ///
  /// Parameters:
  /// - offerId: The offer ID to filter by
  ///
  /// Returns: This builder instance for method chaining
  ///
  /// Example:
  /// ```dart
  /// var trades = await sdk.trades
  ///     .offerId('12345')
  ///     .execute();
  /// ```
  TradesRequestBuilder offerId(String offerId) {
    queryParameters.addAll({"offer_id": offerId});
    return this;
  }

  /// Filters trades by liquidity pool.
  ///
  /// Returns all trades that involved the specified liquidity pool.
  ///
  /// Parameters:
  /// - poolId: Liquidity pool ID (hex string or L-prefixed)
  ///
  /// Returns: This builder instance for method chaining
  ///
  /// Example:
  /// ```dart
  /// var trades = await sdk.trades
  ///     .liquidityPoolId(poolId)
  ///     .execute();
  /// ```
  TradesRequestBuilder liquidityPoolId(String poolId) {
    var id = poolId;
    if (id.startsWith("L")) {
      try {
        id = Util.bytesToHex(StrKey.decodeLiquidityPoolId(poolId));
      } catch (_) {}
    }
    queryParameters.addAll({"liquidity_pool_id": id});
    return this;
  }

  @override
  TradesRequestBuilder cursor(String token) {
    super.cursor(token);
    return this;
  }

  @override
  TradesRequestBuilder limit(int number) {
    super.limit(number);
    return this;
  }

  @override
  TradesRequestBuilder order(RequestBuilderOrder direction) {
    super.order(direction);
    return this;
  }

  /// Allows to stream SSE events from horizon.
  /// Certain endpoints in Horizon can be called in streaming mode using Server-Sent Events.
  /// This mode will keep the connection to horizon open and horizon will continue to return
  /// responses as ledgers close.
  /// See: [Streaming](https://developers.stellar.org/docs/data/horizon/api-reference/structure/streaming)
  Stream<TradeResponse> stream() {
    StreamController<TradeResponse> listener = StreamController.broadcast();

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
          TradeResponse operationResponse = TradeResponse.fromJson(
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
}
