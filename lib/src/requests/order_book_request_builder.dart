// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import "package:eventsource/eventsource.dart";
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import '../assets.dart';
import 'request_builder.dart';
import '../responses/response.dart';
import '../responses/order_book_response.dart';
import '../asset_type_credit_alphanum.dart';

/// Builds requests connected to order book.
class OrderBookRequestBuilder extends RequestBuilder {
  OrderBookRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, ["order_book"]);

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

  static Future<OrderBookResponse> requestExecute(
      http.Client httpClient, Uri uri) async {
    TypeToken type = new TypeToken<OrderBookResponse>();
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
  /// See: <a href="http://www.w3.org/TR/eventsource/" target="_blank">Server-Sent Events</a>
  ///  See: <a href="https://www.stellar.org/developers/horizon/learn/responses.html" target="_blank">Response Format documentation</a>
  Stream<OrderBookResponse> stream() {
    StreamController<OrderBookResponse> listener =
        new StreamController.broadcast();
    EventSource.connect(this.buildUri()).then((eventSource) {
      eventSource.listen((Event event) {
        if (event.data == "\"hello\"" || event.event == "close") {
          return null;
        }
        OrderBookResponse orderBookResponse =
            OrderBookResponse.fromJson(json.decode(event.data));
        listener.add(orderBookResponse);
      });
    });
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
