// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../asset_type_credit_alphanum.dart';
import '../assets.dart';
import "../eventsource/eventsource.dart";
import '../responses/offer_response.dart';
import '../responses/response.dart';
import 'request_builder.dart';

/// Builds requests connected to offers. Offers are statements about how much of an asset an account wants to buy or sell.
/// See: <a href="https://developers.stellar.org/api/resources/offers/" target="_blank">Offers</a>
class OffersRequestBuilder extends RequestBuilder {
  OffersRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, ["offers"]);

  /// Requests specific [uri] and returns OfferResponse.
  /// This method is helpful for getting the links.
  Future<OfferResponse> offersURI(Uri uri) async {
    TypeToken<OfferResponse> type = new TypeToken<OfferResponse>();
    ResponseHandler<OfferResponse> responseHandler =
        ResponseHandler<OfferResponse>(type);

    return await httpClient
        .get(uri, headers: RequestBuilder.headers)
        .then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  /// The offer details endpoint provides information on a single offer given by [offerId].
  /// See: <a href="https://developers.stellar.org/api/resources/offers/single/" target="_blank">Retrieve an Offer</a>
  Future<OfferResponse> offer(String offerId) {
    this.setSegments(["offers", offerId]);
    return this.offersURI(this.buildUri());
  }

  /// Returns all offers a given account has currently open.
  /// See: <a href="https://developers.stellar.org/api/resources/accounts/offers/" target="_blank">Offers for Account</a>
  OffersRequestBuilder forAccount(String accountId) {
    this.setSegments(["accounts", accountId, "offers"]);
    return this;
  }

  /// Returns all offers where the given account is the seller.
  /// See <a href="https://developers.stellar.org/api/resources/offers/list/" target="_blank">Offers</a>
  OffersRequestBuilder forSeller(String seller) {
    queryParameters.addAll({"seller": seller});
    return this;
  }

  /// Returns all offers buying an [asset].
  /// See <a href="https://developers.stellar.org/api/resources/offers/list/" target="_blank">Offers</a>
  OffersRequestBuilder forBuyingAsset(Asset asset) {
    queryParameters.addAll({"buying_asset_type": asset.type});
    if (asset is AssetTypeCreditAlphaNum) {
      AssetTypeCreditAlphaNum creditAlphaNumAsset = asset;
      queryParameters.addAll({"buying_asset_code": creditAlphaNumAsset.code});
      queryParameters
          .addAll({"buying_asset_issuer": creditAlphaNumAsset.issuerId});
    }
    return this;
  }

  /// Returns all selling buying an [asset].
  /// See <a href="https://developers.stellar.org/api/resources/offers/list/" target="_blank">Offers</a>
  OffersRequestBuilder forSellingAsset(Asset asset) {
    queryParameters.addAll({"selling_asset_type": asset.type});
    if (asset is AssetTypeCreditAlphaNum) {
      AssetTypeCreditAlphaNum creditAlphaNumAsset = asset;
      queryParameters.addAll({"selling_asset_code": creditAlphaNumAsset.code});
      queryParameters
          .addAll({"selling_asset_issuer": creditAlphaNumAsset.issuerId});
    }
    return this;
  }

  /// Returns all offers sponsored by a given sponsor.
  /// See <a href="https://developers.stellar.org/api/resources/offers/list/" target="_blank">Offers</a>
  OffersRequestBuilder forSponsor(String sponsorAccountId) {
    queryParameters.addAll({"sponsor": sponsorAccountId});
    return this;
  }

  /// Requests specific uri and returns Page of OfferResponse.
  /// This method is helpful for getting the next set of results.
  static Future<Page<OfferResponse>> requestExecute(
      http.Client httpClient, Uri uri) async {
    TypeToken<Page<OfferResponse>> type = new TypeToken<Page<OfferResponse>>();
    ResponseHandler<Page<OfferResponse>> responseHandler =
        new ResponseHandler<Page<OfferResponse>>(type);

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
  Stream<OfferResponse> stream() {
    StreamController<OfferResponse> listener = StreamController.broadcast();

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
          OfferResponse operationResponse = OfferResponse.fromJson(
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

  /// Build and execute request.
  Future<Page<OfferResponse>> execute() {
    return OffersRequestBuilder.requestExecute(
        this.httpClient, this.buildUri());
  }

  @override
  OffersRequestBuilder cursor(String token) {
    super.cursor(token);
    return this;
  }

  @override
  OffersRequestBuilder limit(int number) {
    super.limit(number);
    return this;
  }

  @override
  OffersRequestBuilder order(RequestBuilderOrder direction) {
    super.order(direction);
    return this;
  }
}
