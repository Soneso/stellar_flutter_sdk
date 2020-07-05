// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:http/http.dart' as http;
import 'dart:async';
import '../assets.dart';
import '../asset_type_credit_alphanum.dart';
import '../responses/response.dart';
import 'request_builder.dart';
import '../responses/trade_response.dart';
import '../util.dart';
import "package:eventsource/eventsource.dart";
import 'dart:convert';


/// Builds requests connected to trades. When an offer is fully or partially fulfilled, a trade happens. Trades can also be caused by successful path payments, because path payments involve fulfilling offers. A trade occurs between two parties—base and counter. Which is which is either arbitrary or determined by the calling query.
/// See: <a href="https://developers.stellar.org/api/resources/trades/" target="_blank">Trades</a>
class TradesRequestBuilder extends RequestBuilder {
  TradesRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, ["trades"]);

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

  /// Returns the trades for a given account by [accountId].
  /// See: <a href="https://www.stellar.org/developers/horizon/reference/endpoints/trades-for-account.html">Trades for Account</a>
  TradesRequestBuilder forAccount(String accountId) {
    accountId = checkNotNull(accountId, "accountId cannot be null");
    this.setSegments(["accounts", accountId, "trades"]);
    return this;
  }

  static Future<Page<TradeResponse>> requestExecute(
      http.Client httpClient, Uri uri) async {
    TypeToken type = new TypeToken<Page<TradeResponse>>();
    ResponseHandler<Page<TradeResponse>> responseHandler =
        new ResponseHandler<Page<TradeResponse>>(type);

    return await httpClient
        .get(uri, headers: RequestBuilder.headers)
        .then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  Future<Page<TradeResponse>> execute() {
    return TradesRequestBuilder.requestExecute(
        this.httpClient, this.buildUri());
  }

  TradesRequestBuilder offerId(String offerId) {
    queryParameters.addAll({"offer_id": offerId});
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
  /// See: <a href="https://developers.stellar.org/api/introduction/streaming/" target="_blank">Streaming</a>
  Stream<TradeResponse> stream() {
    StreamController<TradeResponse> listener =
    new StreamController.broadcast();
    EventSource.connect(this.buildUri()).then((eventSource) {
      eventSource.listen((Event event) {
        if (event.data == "\"hello\"" || event.event == "close") {
          return null;
        }
        TradeResponse tradeResponse =
        TradeResponse.fromJson(json.decode(event.data));
        listener.add(tradeResponse);
      });
    });
    return listener.stream;
  }
}
