// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import "package:eventsource/eventsource.dart";
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'request_builder.dart';
import '../responses/response.dart';
import '../responses/effects/effect_responses.dart';
import '../util.dart';

/// Builds requests connected to effects from horizon.
class EffectsRequestBuilder extends RequestBuilder {
  EffectsRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, ["effects"]);

  /// Effects request builder of a specific account given by [accountId].
  /// See: <a href="https://developers.stellar.org/api/resources/accounts/effects/" target="_blank">Effects for Account</a>
  EffectsRequestBuilder forAccount(String accountId) {
    accountId = checkNotNull(accountId, "accountId cannot be null");
    this.setSegments(["accounts", accountId, "effects"]);
    return this;
  }

  /// Effects request builder of a specific ledger given by [ledgerSeq].
  /// See: <a href="https://www.stellar.org/developers/horizon/reference/endpoints/effects-for-ledger.html" target="_blank">Effects for Ledger</a>
  EffectsRequestBuilder forLedger(int ledgerSeq) {
    this.setSegments(["ledgers", ledgerSeq.toString(), "effects"]);
    return this;
  }

  /// Effects request builder of a specific transaction given by [transactionId].
  /// See: <a href="https://developers.stellar.org/api/resources/transactions/effects/" target="_blank">Effect for Transaction</a>
  EffectsRequestBuilder forTransaction(String transactionId) {
    transactionId = checkNotNull(transactionId, "transactionId cannot be null");
    this.setSegments(["transactions", transactionId, "effects"]);
    return this;
  }

  /// Effects request builder of a specific operation given by [operationId].
  /// See: <a href="https://developers.stellar.org/api/resources/operations/effects/" target="_blank">Effect for Operation</a>
  EffectsRequestBuilder forOperation(int operationId) {
    this.setSegments(["operations", operationId.toString(), "effects"]);
    return this;
  }

  /// Requests specific <code>uri</code> and returns Page of EffectResponse.
  /// This method is helpful for getting the next set of results.
  static Future<Page<EffectResponse>> requestExecute(
      http.Client httpClient, Uri uri) async {
    TypeToken type = new TypeToken<Page<EffectResponse>>();
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
  /// See: <a href="https://developers.stellar.org/api/introduction/streaming/" target="_blank">Streaming</a>
  Stream<EffectResponse> stream() {
    StreamController<EffectResponse> listener =
        new StreamController.broadcast();
    EventSource.connect(this.buildUri()).then((eventSource) {
      eventSource.listen((Event event) {
        if (event.data == "\"hello\"" || event.event == "close") {
          return null;
        }
        EffectResponse effectResponse =
            EffectResponse.fromJson(json.decode(event.data));
        listener.add(effectResponse);
      });
    });
    return listener.stream;
  }

  /// Build and execute request.
  Future<Page<EffectResponse>> execute() {
    return EffectsRequestBuilder.requestExecute(
        this.httpClient, this.buildUri());
  }

  @override
  EffectsRequestBuilder cursor(String token) {
    super.cursor(token);
    return this;
  }

  @override
  EffectsRequestBuilder limit(int number) {
    super.limit(number);
    return this;
  }

  @override
  EffectsRequestBuilder order(RequestBuilderOrder direction) {
    super.order(direction);
    return this;
  }
}
