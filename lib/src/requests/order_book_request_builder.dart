// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../asset_type_credit_alphanum.dart';
import '../assets.dart';
import "../eventsource/eventsource.dart";
import '../responses/order_book_response.dart';
import '../responses/response.dart';
import 'request_builder.dart';

/// Builds requests for the order book.
///
/// An order book represents the current state of buy and sell offers for a
/// specific trading pair on the Stellar decentralized exchange (DEX). The order
/// book shows the depth of the market by listing all bids (buy offers) and asks
/// (sell offers) at various price levels.
///
/// The order book response includes:
/// - bids: Array of buy offers with prices and amounts
/// - asks: Array of sell offers with prices and amounts
/// - base asset and counter asset information
///
/// Order books are essential for:
/// - Displaying market depth in trading interfaces
/// - Finding the best available prices before placing orders
/// - Analyzing market liquidity and spread
///
/// Example:
/// ```dart
/// // Get order book for XLM/USDC trading pair
/// var orderBook = await sdk.orderBook
///     .sellingAsset(Asset.NATIVE)
///     .buyingAsset(Asset.createNonNativeAsset('USDC', issuerId))
///     .limit(20)
///     .execute();
///
/// print('Bids (buy orders):');
/// for (var bid in orderBook.bids) {
///   print('Price: ${bid.price}, Amount: ${bid.amount}');
/// }
///
/// print('Asks (sell orders):');
/// for (var ask in orderBook.asks) {
///   print('Price: ${ask.price}, Amount: ${ask.amount}');
/// }
///
/// // Stream order book updates in real-time
/// sdk.orderBook
///     .sellingAsset(sellAsset)
///     .buyingAsset(buyAsset)
///     .stream()
///     .listen((orderBook) {
///       print('Order book updated');
///       print('Best bid: ${orderBook.bids.first.price}');
///       print('Best ask: ${orderBook.asks.first.price}');
///     });
/// ```
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
class OrderBookRequestBuilder extends RequestBuilder {
  OrderBookRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, ["order_book"]);

  /// Sets the asset being sold (base asset).
  ///
  /// Specifies which asset participants are selling in this order book.
  /// This determines one half of the trading pair. Must be used together
  /// with buyingAsset() to define the complete trading pair.
  ///
  /// Parameters:
  /// - asset: The asset being sold (can be native XLM or issued asset)
  ///
  /// Returns: This builder instance for method chaining
  ///
  /// Example:
  /// ```dart
  /// var orderBook = await sdk.orderBook
  ///     .sellingAsset(Asset.NATIVE)
  ///     .buyingAsset(Asset.createNonNativeAsset('USDC', issuerId))
  ///     .execute();
  /// ```
  ///
  /// See also:
  /// - [Stellar developer docs](https://developers.stellar.org)
  OrderBookRequestBuilder sellingAsset(Asset asset) {
    queryParameters.addAll({"selling_asset_type": asset.type});
    if (asset is AssetTypeCreditAlphaNum) {
      AssetTypeCreditAlphaNum creditAlphaNumAsset = asset;
      queryParameters.addAll({"selling_asset_code": creditAlphaNumAsset.code});
      queryParameters
          .addAll({"selling_asset_issuer": creditAlphaNumAsset.issuerId});
    }
    return this;
  }

  /// Sets the asset being bought (counter asset).
  ///
  /// Specifies which asset participants are buying in this order book.
  /// This determines the other half of the trading pair. Must be used together
  /// with sellingAsset() to define the complete trading pair.
  ///
  /// Parameters:
  /// - asset: The asset being bought (can be native XLM or issued asset)
  ///
  /// Returns: This builder instance for method chaining
  ///
  /// Example:
  /// ```dart
  /// var orderBook = await sdk.orderBook
  ///     .sellingAsset(Asset.createNonNativeAsset('BTC', issuerId))
  ///     .buyingAsset(Asset.createNonNativeAsset('USDC', issuerId))
  ///     .execute();
  /// ```
  ///
  /// See also:
  /// - [Stellar developer docs](https://developers.stellar.org)
  OrderBookRequestBuilder buyingAsset(Asset asset) {
    queryParameters.addAll({"buying_asset_type": asset.type});
    if (asset is AssetTypeCreditAlphaNum) {
      AssetTypeCreditAlphaNum creditAlphaNumAsset = asset;
      queryParameters.addAll({"buying_asset_code": creditAlphaNumAsset.code});
      queryParameters
          .addAll({"buying_asset_issuer": creditAlphaNumAsset.issuerId});
    }
    return this;
  }

  /// Requests specific `uri` and returns Page of OrderBookResponse.
  /// This method is helpful for getting the next set of results.
  static Future<OrderBookResponse> requestExecute(
      http.Client httpClient, Uri uri) async {
    TypeToken<OrderBookResponse> type = new TypeToken<OrderBookResponse>();
    ResponseHandler<OrderBookResponse> responseHandler =
        new ResponseHandler<OrderBookResponse>(type);

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
  /// See: [Stellar developer docs](https://developers.stellar.org)
  Stream<OrderBookResponse> stream() {
    StreamController<OrderBookResponse> listener = StreamController.broadcast();

    bool cancelled = false;
    EventSource? source;

    /// Creates a new EventSource connection to stream order book updates from Horizon.
    /// Automatically reconnects when the connection closes to maintain continuous streaming.
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
          OrderBookResponse operationResponse = OrderBookResponse.fromJson(
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
  /// Returns: OrderBookResponse containing bids and asks for the trading pair
  ///
  /// Example:
  /// ```dart
  /// var orderBook = await sdk.orderBook
  ///     .sellingAsset(Asset.NATIVE)
  ///     .buyingAsset(Asset.createNonNativeAsset('USDC', issuerId))
  ///     .limit(10)
  ///     .execute();
  ///
  /// print('Base: ${orderBook.base.assetType}');
  /// print('Counter: ${orderBook.counter.assetType}');
  /// print('Number of bids: ${orderBook.bids.length}');
  /// print('Number of asks: ${orderBook.asks.length}');
  /// ```
  Future<OrderBookResponse> execute() {
    return OrderBookRequestBuilder.requestExecute(
        this.httpClient, this.buildUri());
  }

  /// Sets the maximum number of bids and asks to return.
  ///
  /// The limit applies separately to both bids and asks. For example,
  /// limit(10) will return up to 10 bids and up to 10 asks.
  ///
  /// Parameters:
  /// - number: Maximum number of price levels per side (default: 10, max: 200)
  ///
  /// Returns: This builder instance for method chaining
  ///
  /// Example:
  /// ```dart
  /// // Get top 5 bid and ask levels
  /// var orderBook = await sdk.orderBook
  ///     .sellingAsset(sellAsset)
  ///     .buyingAsset(buyAsset)
  ///     .limit(5)
  ///     .execute();
  /// ```
  @override
  OrderBookRequestBuilder limit(int number) {
    super.limit(number);
    return this;
  }
}
