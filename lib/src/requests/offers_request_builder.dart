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
import 'trades_request_builder.dart';

/// Builds requests to query offers from Horizon.
///
/// Offers represent orders placed on the Stellar Decentralized Exchange (DEX).
/// Each offer specifies an amount of an asset to buy or sell at a specific price.
/// Offers remain open until they are filled, canceled, or the account no longer
/// has sufficient funds.
///
/// This builder supports filtering offers by account, seller, buying/selling assets,
/// and sponsor. It also supports streaming offers via Server-Sent Events and
/// pagination through result sets.
///
/// Example:
/// ```dart
/// // Get all offers for an account
/// final offers = await sdk.offers
///     .forAccount('GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B')
///     .execute();
///
/// // Get offers buying a specific asset
/// final buyOffers = await sdk.offers
///     .forBuyingAsset(Asset.createNonNativeAsset('USD', issuerId))
///     .limit(20)
///     .execute();
///
/// // Stream new offers in real-time
/// sdk.offers
///     .forSellingAsset(Asset.createNonNativeAsset('EUR', issuerId))
///     .stream()
///     .listen((offer) {
///       print('New offer: ${offer.amount} @ ${offer.price}');
///     });
/// ```
///
/// See also:
/// - [Horizon Offers API](https://developers.stellar.org/docs/data/apis/horizon/api-reference/resources/offers)
/// - [OfferResponse] for response structure
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
  /// See: [Retrieve an Offer](https://developers.stellar.org/api/resources/offers/single/)
  Future<OfferResponse> offer(String offerId) {
    this.setSegments(["offers", offerId]);
    return this.offersURI(this.buildUri());
  }

  /// Returns all offers a given account has currently open.
  /// See: [Offers for Account](https://developers.stellar.org/api/resources/accounts/offers/)
  OffersRequestBuilder forAccount(String accountId) {
    this.setSegments(["accounts", accountId, "offers"]);
    return this;
  }

  /// Returns all offers where the given account is the seller.
  /// See [Offers](https://developers.stellar.org/api/resources/offers/list/)
  OffersRequestBuilder forSeller(String seller) {
    queryParameters.addAll({"seller": seller});
    return this;
  }

  /// Returns all offers buying an [asset].
  /// See [Offers](https://developers.stellar.org/api/resources/offers/list/)
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
  /// See [Offers](https://developers.stellar.org/api/resources/offers/list/)
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
  /// See [Offers](https://developers.stellar.org/api/resources/offers/list/)
  OffersRequestBuilder forSponsor(String sponsorAccountId) {
    queryParameters.addAll({"sponsor": sponsorAccountId});
    return this;
  }

  /// Returns all trades for a specific offer by [offerId].
  /// This method returns a TradesRequestBuilder instance configured to fetch trades
  /// for the specified offer using the /offers/{offer_id}/trades endpoint.
  /// See [Trades for Offer](https://developers.stellar.org/docs/data/apis/horizon/api-reference/get-trades-by-offer-id)
  TradesRequestBuilder trades(String offerId) {
    TradesRequestBuilder builder = TradesRequestBuilder(httpClient, uriBuilder);
    builder.setSegments(["offers", offerId, "trades"]);
    return builder;
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
  /// See: [Streaming](https://developers.stellar.org/api/introduction/streaming/)
  Stream<OfferResponse> stream() {
    StreamController<OfferResponse> listener = StreamController.broadcast();

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

  /// Build and execute the request.
  ///
  /// Returns a [Page] of [OfferResponse] objects containing the requested offers
  /// and pagination links for navigating through result sets.
  ///
  /// Example:
  /// ```dart
  /// final page = await sdk.offers.forAccount('account_id').execute();
  /// for (var offer in page.records) {
  ///   print('Offer ${offer.id}: Selling ${offer.selling.assetCode} for ${offer.buying.assetCode}');
  ///   print('Price: ${offer.price}, Amount: ${offer.amount}');
  /// }
  /// ```
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
