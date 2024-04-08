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

/// Builds requests connected to the order book. An order book is a collections of offers for a specific pair of assets.
/// See: <a href="https://developers.stellar.org/api/aggregations/order-books/" target="_blank">Order books</a>
class OrderBookRequestBuilder extends RequestBuilder {
  OrderBookRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, ["order_book"]);

  /// Sets the asset being sold (base asset).
  /// See: <a href="https://developers.stellar.org/api/aggregations/order-books/" target="_blank">Order books</a>
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
  /// See: <a href="https://developers.stellar.org/api/aggregations/order-books/" target="_blank">Order books</a>
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

  /// Requests specific <code>uri</code> and returns Page of OrderBookResponse.
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
  /// See: <a href="https://developers.stellar.org/api/introduction/streaming/" target="_blank">Streaming</a>
  Stream<OrderBookResponse> stream() {
    StreamController<OrderBookResponse> listener = StreamController.broadcast();

    bool cancelled = false;
    EventSource? source;

    Future<void> createNewEventSource() async {
      if (cancelled) {
        return;
      }
      source?.close();
      source = await EventSource.connect(this.buildUri());
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

  Future<OrderBookResponse> execute() {
    return OrderBookRequestBuilder.requestExecute(
        this.httpClient, this.buildUri());
  }

  @override
  OrderBookRequestBuilder limit(int number) {
    super.limit(number);
    return this;
  }
}
