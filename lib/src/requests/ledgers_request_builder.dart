// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import "../eventsource/eventsource.dart";
import '../responses/ledger_response.dart';
import '../responses/response.dart';
import 'request_builder.dart';

/// Builds requests to query ledgers from Horizon.
///
/// Ledgers represent the state of the Stellar network at a specific point in time.
/// Each ledger contains all transactions, operations, and effects that occurred
/// during that ledger's close time. Ledgers close approximately every 5 seconds.
///
/// This builder supports retrieving individual ledgers by sequence number,
/// querying all ledgers with pagination, and streaming new ledgers as they close
/// via Server-Sent Events.
///
/// Example:
/// ```dart
/// // Get a specific ledger by sequence number
/// final ledger = await sdk.ledgers.ledger(12345);
/// print('Ledger hash: ${ledger.hash}');
///
/// // Get recent ledgers
/// final ledgers = await sdk.ledgers
///     .order(RequestBuilderOrder.DESC)
///     .limit(10)
///     .execute();
///
/// // Stream new ledgers as they close
/// sdk.ledgers
///     .cursor('now')
///     .stream()
///     .listen((ledger) {
///       print('New ledger: ${ledger.sequence}');
///     });
/// ```
///
/// See also:
/// - [Horizon Ledgers API](https://developers.stellar.org/api/resources/ledgers/)
/// - [LedgerResponse] for response structure
class LedgersRequestBuilder extends RequestBuilder {
  LedgersRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, ["ledgers"]);

  /// Requests specific uri and returns LedgerResponse.
  /// This method is helpful for getting the links.
  Future<LedgerResponse> ledgerURI(Uri uri) async {
    TypeToken<LedgerResponse> type = new TypeToken<LedgerResponse>();
    ResponseHandler<LedgerResponse> responseHandler =
        new ResponseHandler<LedgerResponse>(type);

    return await httpClient
        .get(uri, headers: RequestBuilder.headers)
        .then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  /// Provides information on a specific ledger given by [ledgerSeq].
  /// See: [Ledger Details](https://developers.stellar.org/api/resources/ledgers/single/)
  Future<LedgerResponse> ledger(int ledgerSeq) {
    this.setSegments(["ledgers", ledgerSeq.toString()]);
    return this.ledgerURI(this.buildUri());
  }

  /// Requests specific uri and returns Page of LedgerResponse.
  /// This method is helpful for getting the next set of results.
  static Future<Page<LedgerResponse>> requestExecute(
      http.Client httpClient, Uri uri) async {
    TypeToken<Page<LedgerResponse>> type =
        new TypeToken<Page<LedgerResponse>>();
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
  /// See: [Streaming](https://developers.stellar.org/api/introduction/streaming/)
  Stream<LedgerResponse> stream() {
    StreamController<LedgerResponse> listener = StreamController.broadcast();

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
          LedgerResponse operationResponse = LedgerResponse.fromJson(
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
  /// Returns a [Page] of [LedgerResponse] objects containing the requested ledgers
  /// and pagination links for navigating through result sets.
  ///
  /// Example:
  /// ```dart
  /// final page = await sdk.ledgers.order(RequestBuilderOrder.DESC).limit(20).execute();
  /// for (var ledger in page.records) {
  ///   print('Ledger ${ledger.sequence}: ${ledger.transactionCount} transactions');
  /// }
  /// ```
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
