// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:stellar_flutter_sdk/src/key_pair.dart';
import 'package:stellar_flutter_sdk/src/util.dart';

import "../eventsource/eventsource.dart";
import '../responses/effects/effect_responses.dart';
import '../responses/response.dart';
import 'request_builder.dart';

/// Builds requests to query effects from Horizon.
///
/// Effects represent specific changes to the ledger state resulting from operations.
/// Examples include account credited, account debited, signer created, trustline created,
/// trade executed, and many others. Each operation can produce multiple effects.
///
/// This builder supports filtering effects by account, ledger, transaction, operation,
/// or liquidity pool. It also supports streaming effects via Server-Sent Events and
/// pagination through result sets.
///
/// Example:
/// ```dart
/// // Get effects for a specific account
/// final effects = await sdk.effects
///     .forAccount('GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B')
///     .order(RequestBuilderOrder.DESC)
///     .limit(10)
///     .execute();
///
/// // Get effects for a specific operation
/// final opEffects = await sdk.effects
///     .forOperation('operation_id')
///     .execute();
///
/// // Stream effects in real-time
/// sdk.effects
///     .forAccount('account_id')
///     .cursor('now')
///     .stream()
///     .listen((effect) {
///       print('New effect: ${effect.type}');
///     });
/// ```
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
/// - [EffectResponse] for response structure
class EffectsRequestBuilder extends RequestBuilder {
  /// Creates an EffectsRequestBuilder for querying operation effects from Horizon.
  ///
  /// This constructor is typically called internally by the SDK. Use [StellarSDK.effects]
  /// to access effects query functionality.
  ///
  /// Parameters:
  /// - [httpClient] HTTP client for making requests to Horizon
  /// - [serverURI] Base URI of the Horizon server
  EffectsRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, ["effects"]);

  /// Effects request builder of a specific account given by [accountId].
  /// See: [Stellar developer docs](https://developers.stellar.org)
  EffectsRequestBuilder forAccount(String accountId) {
    this.setSegments(["accounts", accountId, "effects"]);
    return this;
  }

  /// Effects request builder of a specific ledger given by [ledgerSeq].
  /// See: [Effects for Ledger](https://www.stellar.org/developers/horizon/reference/endpoints/effects-for-ledger.html)
  EffectsRequestBuilder forLedger(int ledgerSeq) {
    this.setSegments(["ledgers", ledgerSeq.toString(), "effects"]);
    return this;
  }

  /// Effects request builder of a specific transaction given by [transactionId].
  /// See: [Stellar developer docs](https://developers.stellar.org)
  EffectsRequestBuilder forTransaction(String transactionId) {
    this.setSegments(["transactions", transactionId, "effects"]);
    return this;
  }

  /// Effects request builder of a specific operation given by [operationId].
  /// See: [Stellar developer docs](https://developers.stellar.org)
  EffectsRequestBuilder forOperation(String operationId) {
    this.setSegments(["operations", operationId, "effects"]);
    return this;
  }

  /// Effects request builder for a specific liquidity pool identified by [poolId].
  /// The pool ID can be provided in either hex format or Stellar-encoded format (starting with 'L').
  /// See: [Stellar developer docs](https://developers.stellar.org)
  EffectsRequestBuilder forLiquidityPool(String poolId) {
    var id = poolId;
    if (id.startsWith("L")) {
      try {
        id = Util.bytesToHex(StrKey.decodeLiquidityPoolId(poolId));
      } catch (_) {}
    }
    this.setSegments(["liquidity_pools", id, "effects"]);
    return this;
  }

  /// Requests specific `uri` and returns Page of EffectResponse.
  /// This method is helpful for getting the next set of results.
  static Future<Page<EffectResponse>> requestExecute(
      http.Client httpClient, Uri uri) async {
    TypeToken<Page<EffectResponse>> type =
        new TypeToken<Page<EffectResponse>>();
    ResponseHandler<Page<EffectResponse>> responseHandler =
        new ResponseHandler<Page<EffectResponse>>(type);

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
  Stream<EffectResponse> stream() {
    StreamController<EffectResponse> listener = StreamController.broadcast();

    bool cancelled = false;
    EventSource? source;

    /// Creates a new EventSource connection to stream effect updates from Horizon.
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
          EffectResponse operationResponse = EffectResponse.fromJson(
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
  /// Returns a [Page] of [EffectResponse] objects containing the requested effects
  /// and pagination links for navigating through result sets.
  ///
  /// Example:
  /// ```dart
  /// final page = await sdk.effects.forAccount('account_id').limit(20).execute();
  /// for (var effect in page.records) {
  ///   if (effect is AccountCreditedEffectResponse) {
  ///     print('Account credited: ${effect.amount} ${effect.assetType}');
  ///   }
  /// }
  /// ```
  Future<Page<EffectResponse>> execute() {
    return EffectsRequestBuilder.requestExecute(
        this.httpClient, this.buildUri());
  }

  /// Sets the cursor for pagination to start returning records from a specific point.
  /// Returns this builder for method chaining.
  @override
  EffectsRequestBuilder cursor(String token) {
    super.cursor(token);
    return this;
  }

  /// Sets the maximum number of records to return in a single page.
  /// Returns this builder for method chaining.
  @override
  EffectsRequestBuilder limit(int number) {
    super.limit(number);
    return this;
  }

  /// Sets the sort order for returned records (ascending or descending).
  /// Returns this builder for method chaining.
  @override
  EffectsRequestBuilder order(RequestBuilderOrder direction) {
    super.order(direction);
    return this;
  }
}
