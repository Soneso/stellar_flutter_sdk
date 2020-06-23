// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:http/http.dart' as http;
import 'dart:async';
import '../util.dart';
import '../requests/request_builder.dart';
import 'effects/effect_responses.dart';
import 'operations/operation_responses.dart';

// responses
import 'transaction_response.dart';
import 'account_response.dart';
import 'asset_response.dart';
import 'ledger_response.dart';
import 'offer_response.dart';
import 'fee_stats_response.dart';
import 'order_book_response.dart';
import 'path_response.dart';
import 'root_response.dart';
import 'submit_transaction_response.dart';
import 'trade_response.dart';
import 'trade_aggregation_response.dart';

String serializeNull(dynamic src) {
  return null;
}

int convertInt(var src) {
  if (src == null) return null;
  if (src is int) return src;
  if (src is String) return int.parse(src);
  throw Exception("Not integer");
}

// Represents a response received from the horizon server.
abstract class Response {
  int rateLimitLimit;
  int rateLimitRemaining;
  int rateLimitReset;

  void setHeaders(Map<String, String> headers) {
    if (headers["X-Ratelimit-Limit"] != null) {
      this.rateLimitLimit = int.parse(headers["X-Ratelimit-Limit"]);
    }
    if (headers["X-Ratelimit-Remaining"] != null) {
      this.rateLimitRemaining = int.parse(headers["X-Ratelimit-Remaining"]);
    }
    if (headers["X-Ratelimit-Reset"] != null) {
      this.rateLimitReset = int.parse(headers["X-Ratelimit-Reset"]);
    }
  }
}

/// Represents the links in a response from the horizon server.
class Link {
  String href;
  bool templated;

  Link(this.href, this.templated);

  factory Link.fromJson(Map<String, dynamic> json) {
    return new Link(json['href'] as String, json['templated'] as bool);
  }

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'href': href, 'templated': templated};
}

/// Links connected to page response.
class PageLinks {
  Link next;
  Link prev;
  Link self;

  PageLinks(this.next, this.prev, this.self);

  factory PageLinks.fromJson(Map<String, dynamic> json) => new PageLinks(
      json['next'] == null
          ? null
          : new Link.fromJson(json['next'] as Map<String, dynamic>),
      json['prev'] == null
          ? null
          : new Link.fromJson(json['prev'] as Map<String, dynamic>),
      json['self'] == null
          ? null
          : new Link.fromJson(json['self'] as Map<String, dynamic>));
}

class TypeToken<T> {
  Type type;
  int hashCode;

  TypeToken() {
    type = T;
    hashCode = T.hashCode;
  }
}

/// Indicates a generic container that requires type information to be provided after initialisation.
abstract class TypedResponse<T> {
  void setType(TypeToken<T> type);
}

/// Represents page of objects.
class Page<T> extends Response implements TypedResponse<Page<T>> {
  List<T> records;
  PageLinks links;

  TypeToken<Page<T>> type;

  Page();

  ///The next page of results or null when there is no link for the next page of results
  Future<Page<T>> getNextPage(http.Client httpClient) async {
    if (this.links.next == null) {
      return null;
    }
    checkNotNull(
        this.type,
        "type cannot be null, is it being correctly set after the creation of this " +
            this.runtimeType.toString() +
            "?");
    ResponseHandler<Page<T>> responseHandler =
        new ResponseHandler<Page<T>>(this.type);
    String url = this.links.next.href;

    return await httpClient.get(url).then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  @override
  void setType(TypeToken<Page<T>> type) {
    this.type = type;
  }

  factory Page.fromJson(Map<String, dynamic> json) => new Page<T>()
    ..rateLimitLimit = convertInt(json['rateLimitLimit'])
    ..rateLimitRemaining = convertInt(json['rateLimitRemaining'])
    ..rateLimitReset = convertInt(json['rateLimitReset'])
    ..records = (json["_embedded"]['records'] as List)
        ?.map((e) => ResponseConverter.fromJson<T>(e) as T)
        ?.toList()
    ..links = json['_links'] == null
        ? null
        : new PageLinks.fromJson(json['_links'] as Map<String, dynamic>)
    ..setType(new TypeToken<Page<T>>());
}

class ResponseConverter {
  static dynamic fromJson<T>(Map<String, dynamic> json) {
    switch (T) {
      case AccountResponse:
        return AccountResponse.fromJson(json);
      case AssetResponse:
        return AssetResponse.fromJson(json);
      case EffectResponse:
        return EffectResponse.fromJson(json);
      case LedgerResponse:
        return LedgerResponse.fromJson(json);
      case OfferResponse:
        return OfferResponse.fromJson(json);
      case OrderBookResponse:
        return OrderBookResponse.fromJson(json);
      case OperationResponse:
        return OperationResponse.fromJson(json);
      case FeeStatsResponse:
        return FeeStatsResponse.fromJson(json);
      case PathResponse:
        return PathResponse.fromJson(json);
      case RootResponse:
        return RootResponse.fromJson(json);
      case SubmitTransactionResponse:
        return SubmitTransactionResponse.fromJson(json);
      case TradeAggregationResponse:
        return TradeAggregationResponse.fromJson(json);
      case TradeResponse:
        return TradeResponse.fromJson(json);
      case TransactionResponse:
        return TransactionResponse.fromJson(json);
    }

    switch (T.toString()) {
      case "Page<AccountResponse>":
        return Page<AccountResponse>.fromJson(json);
      case "Page<AssetResponse>":
        return Page<AssetResponse>.fromJson(json);
      case "Page<EffectResponse>":
        return Page<EffectResponse>.fromJson(json);
      case "Page<LedgerResponse>":
        return Page<LedgerResponse>.fromJson(json);
      case "Page<OfferResponse>":
        return Page<OfferResponse>.fromJson(json);
      case "Page<OrderBookResponse>":
        return Page<OrderBookResponse>.fromJson(json);
      case "Page<OperationResponse>":
        return Page<OperationResponse>.fromJson(json);
      case "Page<FeeStatsResponse>":
        return Page<FeeStatsResponse>.fromJson(json);
      case "Page<PathResponse>":
        return Page<PathResponse>.fromJson(json);
      case "Page<RootResponse>":
        return Page<RootResponse>.fromJson(json);
      case "Page<SubmitTransactionResponse>":
        return Page<SubmitTransactionResponse>.fromJson(json);
      case "Page<TradeAggregationResponse>":
        return Page<TradeAggregationResponse>.fromJson(json);
      case "Page<TradeResponse>":
        return Page<TradeResponse>.fromJson(json);
      case "Page<TransactionResponse>":
        return Page<TransactionResponse>.fromJson(json);
    }
  }
}
