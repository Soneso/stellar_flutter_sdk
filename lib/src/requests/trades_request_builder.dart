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

  TradesRequestBuilder tradeType(String tradeType) {
    queryParameters.addAll({"trade_type": tradeType});
    return this;
  }

  /// Returns the trades for a given account by [accountId].
  /// See: <a href="https://www.stellar.org/developers/horizon/reference/endpoints/trades-for-account.html">Trades for Account</a>
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

  Future<Page<TradeResponse>> execute() {
    return TradesRequestBuilder.requestExecute(
        this.httpClient, this.buildUri());
  }

  TradesRequestBuilder offerId(String offerId) {
    queryParameters.addAll({"offer_id": offerId});
    return this;
  }

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
  /// See: <a href="https://developers.stellar.org/api/introduction/streaming/" target="_blank">Streaming</a>
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
