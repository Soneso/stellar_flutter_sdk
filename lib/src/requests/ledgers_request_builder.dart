// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import "package:eventsource/eventsource.dart";
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'request_builder.dart';
import '../responses/response.dart';
import '../responses/ledger_response.dart';

/// Builds requests connected to ledgers. Each ledger stores the state of the network at a point in time and contains all the changes - transactions, operations, effects, etc. - to that state.
/// See: <a href="https://developers.stellar.org/api/resources/ledgers/" target="_blank">Ledgers</a>
class LedgersRequestBuilder extends RequestBuilder {
  LedgersRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, ["ledgers"]);

  /// Requests specific uri and returns LedgerResponse.
  /// This method is helpful for getting the links.
  Future<LedgerResponse> ledgerURI(Uri uri) async {
    TypeToken type = new TypeToken<LedgerResponse>();
    ResponseHandler<LedgerResponse> responseHandler =
        new ResponseHandler<LedgerResponse>(type);

    return await httpClient
        .get(uri, headers: RequestBuilder.headers)
        .then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  /// Provides information on a specific ledger given by [ledgerSeq].
  /// See: <a href="https://developers.stellar.org/api/resources/ledgers/single/" target="_blank">Ledger Details</a>
  Future<LedgerResponse> ledger(int ledgerSeq) {
    this.setSegments(["ledgers", ledgerSeq.toString()]);
    return this.ledgerURI(this.buildUri());
  }

  /// Requests specific uri and returns Page of LedgerResponse.
  /// This method is helpful for getting the next set of results.
  static Future<Page<LedgerResponse>> requestExecute(
      http.Client httpClient, Uri uri) async {
    TypeToken type = new TypeToken<Page<LedgerResponse>>();
    ResponseHandler<Page<LedgerResponse>> responseHandler =
        new ResponseHandler<Page<LedgerResponse>>(type);

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
  Stream<LedgerResponse> stream() {
    StreamController<LedgerResponse> listener =
        new StreamController.broadcast();
    EventSource.connect(this.buildUri()).then((eventSource) {
      eventSource.listen((Event event) {
        if (event.data == "\"hello\"" || event.event == "close") {
          return null;
        }
        LedgerResponse ledgerResponse =
            LedgerResponse.fromJson(json.decode(event.data));
        listener.add(ledgerResponse);
      });
    });
    return listener.stream;
  }

  /// Build and execute request.
  Future<Page<LedgerResponse>> execute() {
    return LedgersRequestBuilder.requestExecute(
        this.httpClient, this.buildUri());
  }

  @override
  LedgersRequestBuilder cursor(String token) {
    super.cursor(token);
    return this;
  }

  @override
  LedgersRequestBuilder limit(int number) {
    super.limit(number);
    return this;
  }

  @override
  LedgersRequestBuilder order(RequestBuilderOrder direction) {
    super.order(direction);
    return this;
  }
}
