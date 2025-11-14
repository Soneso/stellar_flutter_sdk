// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:http/http.dart' as http;
import 'claimable_balance_response.dart';
import 'liquidity_pool_response.dart';
import 'dart:async';
import '../requests/request_builder.dart';
import 'effects/effect_responses.dart';
import 'operations/operation_responses.dart';

// responses
import 'transaction_response.dart';
import 'account_response.dart';
import 'account_data_response.dart';
import 'asset_response.dart';
import 'ledger_response.dart';
import 'offer_response.dart';
import 'fee_stats_response.dart';
import 'health_response.dart';
import 'order_book_response.dart';
import 'path_response.dart';
import 'root_response.dart';
import 'submit_transaction_response.dart';
import 'trade_response.dart';
import 'trade_aggregation_response.dart';
import 'challenge_response.dart';
import '../sep/0002/federation.dart';
import '../sep/0006/transfer_server_service.dart';
import '../sep/0012/kyc_service.dart';
import '../sep/0024/sep24_service.dart';

String? serializeNull(dynamic src) {
  return null;
}

int? convertInt(var src) {
  if (src == null) return null;
  if (src is int) return src;
  if (src is String) return int.parse(src);
  throw Exception("Not integer");
}

double? convertDouble(var src) {
  if (src == null) return null;
  if (src is double) return src;
  if (src is int) return src.toDouble();
  if (src is String) return double.parse(src);
  throw Exception("Not double");
}

/// Base class for all responses received from the Horizon server.
///
/// This abstract class provides common functionality for handling HTTP response
/// headers, particularly rate limiting information. All specific response types
/// extend this class.
///
/// Rate limit information is populated from HTTP headers:
/// - rateLimitLimit: Total number of requests allowed per time window
/// - rateLimitRemaining: Number of requests remaining in current window
/// - rateLimitReset: Timestamp when the rate limit window resets
///
/// Example:
/// ```dart
/// var account = await sdk.accounts.account(accountId);
/// print('Rate limit remaining: ${account.rateLimitRemaining}');
/// print('Rate limit resets at: ${account.rateLimitReset}');
/// ```
///
/// See also:
/// - [Page] for paginated responses
/// - [TooManyRequestsException] for rate limit errors
abstract class Response {
  /// Maximum number of requests allowed in the current rate limit window.
  int? rateLimitLimit;

  /// Number of requests remaining in the current rate limit window.
  int? rateLimitRemaining;

  /// Unix timestamp when the rate limit window will reset.
  int? rateLimitReset;

  /// Populates rate limit fields from HTTP response headers.
  ///
  /// This method is called internally by the SDK to extract rate limiting
  /// information from Horizon's response headers.
  ///
  /// Parameters:
  /// - headers: HTTP response headers from the Horizon server
  void setHeaders(Map<String, String> headers) {
    if (headers["X-Ratelimit-Limit"] != null) {
      this.rateLimitLimit = int.tryParse(headers["X-Ratelimit-Limit"]!);
    }
    if (headers["X-Ratelimit-Remaining"] != null) {
      this.rateLimitRemaining = int.tryParse(headers["X-Ratelimit-Remaining"]!);
    }
    if (headers["X-Ratelimit-Reset"] != null) {
      this.rateLimitReset = int.tryParse(headers["X-Ratelimit-Reset"]!);
    }
  }
}

/// Represents a hypermedia link in a Horizon response.
///
/// Horizon uses HAL (Hypertext Application Language) format for responses,
/// which includes links to related resources. Links can be templated (containing
/// URI template variables) or direct URLs.
///
/// Example:
/// ```dart
/// var page = await sdk.payments.execute();
/// if (page.links?.next != null) {
///   print('Next page URL: ${page.links!.next!.href}');
/// }
/// ```
///
/// See also:
/// - [PageLinks] for pagination links
/// - [Page] for paginated responses
class Link {
  /// The URL of the linked resource.
  String href;

  /// Whether this link is a URI template requiring variable substitution.
  bool? templated;

  /// Creates a Link with the specified URL and optional templated flag.
  Link(this.href, this.templated);

  /// Constructs a Link from JSON returned by Horizon API.
  factory Link.fromJson(Map<String, dynamic> json) {
    return Link(json['href'], json['templated']);
  }

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'href': href, 'templated': templated};
}

/// Navigation links for paginated responses.
///
/// PageLinks provides hypermedia links for navigating through paginated
/// result sets. The next and prev links may be null when at the boundaries
/// of the result set.
///
/// Example:
/// ```dart
/// var page = await sdk.payments.limit(10).execute();
///
/// // Navigate to next page
/// if (page.links?.next != null) {
///   var nextPage = await page.getNextPage(httpClient);
/// }
///
/// // Link to current page
/// print('Current page: ${page.links?.self.href}');
/// ```
///
/// See also:
/// - [Page] for paginated responses
/// - [Link] for individual link details
class PageLinks {
  /// Link to the next page of results, or null if on the last page.
  Link? next;

  /// Link to the previous page of results, or null if on the first page.
  Link? prev;

  /// Link to the current page.
  Link self;

  /// Creates PageLinks with navigation links for next, previous, and current pages.
  PageLinks(this.next, this.prev, this.self);

  /// Constructs PageLinks from JSON returned by Horizon API.
  factory PageLinks.fromJson(Map<String, dynamic> json) => PageLinks(
      json['next'] == null ? null : Link.fromJson(json['next']),
      json['prev'] == null ? null : Link.fromJson(json['prev']),
      Link.fromJson(json['self']));
}

/// Generic type token for preserving runtime type information.
///
/// Used internally by the SDK to maintain type information during JSON deserialization
/// of generic containers like [Page]. Dart's type erasure prevents direct access to
/// generic type parameters at runtime, so this token captures the type at construction.
///
/// This class is used by the SDK's response handling infrastructure and is not
/// intended for direct use by application developers.
///
/// Example:
/// ```dart
/// TypeToken<Page<TransactionResponse>> token = TypeToken<Page<TransactionResponse>>();
/// // token.type contains the runtime Type information
/// ```
///
/// See also:
/// - [Page] which uses TypeToken for runtime type handling
/// - [TypedResponse] interface for types requiring runtime type information
class TypeToken<T> {
  /// The runtime Type captured from the generic parameter.
  late Type type;

  /// Hash code based on the captured Type.
  late int hashCode;

  /// Creates a TypeToken capturing the runtime type T for generic type handling.
  TypeToken() {
    type = T;
    hashCode = T.hashCode;
  }
}

/// Interface for responses that require runtime type information.
///
/// Some response types (particularly generic containers like Page) need
/// type information to be set after construction for proper deserialization.
/// This interface is used internally by the SDK.
abstract class TypedResponse<T> {
  /// Sets the runtime type information for this response.
  ///
  /// Parameters:
  /// - type: Type token containing runtime type information
  void setType(TypeToken<T> type);
}

/// Represents a paginated collection of resources from the Horizon server.
///
/// Page is a generic container that holds a list of records along with
/// pagination links. It supports efficient navigation through large result
/// sets using cursor-based pagination.
///
/// Type Parameters:
/// - T: The type of records in this page (e.g., TransactionResponse, PaymentResponse)
///
/// Example:
/// ```dart
/// // Get first page of transactions
/// Page<TransactionResponse> page = await sdk.transactions
///     .forAccount(accountId)
///     .order(RequestBuilderOrder.DESC)
///     .limit(10)
///     .execute();
///
/// print('Records in this page: ${page.records.length}');
/// for (var tx in page.records) {
///   print('Transaction: ${tx.id}');
/// }
///
/// // Get next page
/// if (page.links?.next != null) {
///   Page<TransactionResponse>? nextPage = await page.getNextPage(httpClient);
/// }
/// ```
///
/// See also:
/// - [PageLinks] for navigation links
/// - [RequestBuilder.cursor] for manual pagination
class Page<T> extends Response implements TypedResponse<Page<T>> {
  /// The list of records in this page.
  List<T> records;

  /// Navigation links for accessing related pages.
  PageLinks? links;

  /// Type token for runtime type information.
  TypeToken<Page<T>> type;

  /// Creates a Page with records, navigation links, and type information.
  Page(this.records, this.links, this.type);

  /// Fetches the next page of results.
  ///
  /// Automatically follows the 'next' link to retrieve the next page.
  /// Returns null if there is no next page available.
  ///
  /// Parameters:
  /// - httpClient: HTTP client to use for the request
  ///
  /// Returns: Next page of results, or null if at the end
  ///
  /// Example:
  /// ```dart
  /// var page = await sdk.payments.limit(20).execute();
  /// while (page != null) {
  ///   for (var payment in page.records) {
  ///     print('Payment: ${payment.id}');
  ///   }
  ///   page = await page.getNextPage(httpClient);
  /// }
  /// ```
  Future<Page<T>?> getNextPage(http.Client httpClient) async {
    if (this.links?.next == null) {
      return null;
    }

    ResponseHandler<Page<T>> responseHandler =
        ResponseHandler<Page<T>>(this.type);

    String url = this.links!.next!.href;

    return await httpClient
        .get(Uri.parse(url), headers: RequestBuilder.headers)
        .then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  @override
  void setType(TypeToken<Page<T>> type) {
    this.type = type;
  }

  /// Constructs a Page from JSON returned by Horizon API with embedded records.
  factory Page.fromJson(Map<String, dynamic> json) => Page<T>(
      json["_embedded"]['records'] != null
          ? List<T>.from(json["_embedded"]['records']
              .map((e) => ResponseConverter.fromJson<T>(e) as T))
          : [],
      json['_links'] == null ? null : PageLinks.fromJson(json['_links']),
      TypeToken<Page<T>>())
    ..rateLimitLimit = convertInt(json['rateLimitLimit'])
    ..rateLimitRemaining = convertInt(json['rateLimitRemaining'])
    ..rateLimitReset = convertInt(json['rateLimitReset']);
}

/// Converts JSON maps to strongly-typed response objects.
///
/// Internal utility class used by the SDK to deserialize JSON responses from Horizon
/// and other services into the appropriate response classes. This converter handles
/// both simple response types and paginated results.
///
/// This class is used automatically by the SDK's request handling infrastructure and
/// is not intended for direct use by application developers.
///
/// Supported types include:
/// - Account, Asset, Effect, Ledger, Offer, Operation, Transaction responses
/// - Claimable Balance and Liquidity Pool responses
/// - SEP protocol responses (Federation, Transfer, KYC, Interactive)
/// - Paginated collections of all supported types
///
/// See also:
/// - [Page] for paginated response handling
/// - [Response] for the base response class
class ResponseConverter {
  static dynamic fromJson<T>(Map<String, dynamic> json) {
    switch (T) {
      case AccountResponse:
        return AccountResponse.fromJson(json);
      case AccountDataResponse:
        return AccountDataResponse.fromJson(json);
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
      case HealthResponse:
        return HealthResponse.fromJson(json);
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
      case FederationResponse:
        return FederationResponse.fromJson(json);
      case ClaimableBalanceResponse:
        return ClaimableBalanceResponse.fromJson(json);
      case ChallengeResponse:
        return ChallengeResponse.fromJson(json);
      case SubmitCompletedChallengeResponse:
        return SubmitCompletedChallengeResponse.fromJson(json);
      case DepositResponse:
        return DepositResponse.fromJson(json);
      case WithdrawResponse:
        return WithdrawResponse.fromJson(json);
      case InfoResponse:
        return InfoResponse.fromJson(json);
      case FeeResponse:
        return FeeResponse.fromJson(json);
      case AnchorTransactionsResponse:
        return AnchorTransactionsResponse.fromJson(json);
      case AnchorTransactionResponse:
        return AnchorTransactionResponse.fromJson(json);
      case GetCustomerInfoResponse:
        return GetCustomerInfoResponse.fromJson(json);
      case PutCustomerInfoResponse:
        return PutCustomerInfoResponse.fromJson(json);
      case CustomerFileResponse:
        return CustomerFileResponse.fromJson(json);
      case GetCustomerFilesResponse:
        return GetCustomerFilesResponse.fromJson(json);
      case LiquidityPoolResponse:
        return LiquidityPoolResponse.fromJson(json);
      case SEP24InfoResponse:
        return SEP24InfoResponse.fromJson(json);
      case SEP24FeeResponse:
        return SEP24FeeResponse.fromJson(json);
      case SEP24InteractiveResponse:
        return SEP24InteractiveResponse.fromJson(json);
      case SEP24TransactionsResponse:
        return SEP24TransactionsResponse.fromJson(json);
      case SEP24TransactionResponse:
        return SEP24TransactionResponse.fromJson(json);
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
      case "Page<ClaimableBalanceResponse>":
        return Page<ClaimableBalanceResponse>.fromJson(json);
      case "Page<LiquidityPoolResponse>":
        return Page<LiquidityPoolResponse>.fromJson(json);
    }
  }
}

/// Exception thrown when a response cannot be interpreted.
///
/// This exception is raised when the SDK receives a response from Horizon
/// or an Anchor service that cannot be properly parsed or understood. This
/// typically indicates an API version mismatch or unexpected response format.
///
/// Example:
/// ```dart
/// try {
///   var result = await someHorizonCall();
/// } catch (e) {
///   if (e is UnknownResponse) {
///     print('Unknown response code: ${e.code}');
///     print('Response body: ${e.body}');
///   }
/// }
/// ```
class UnknownResponse implements Exception {
  /// HTTP status code of the response.
  int code;

  /// Raw response body that could not be parsed.
  String body;

  /// Creates an UnknownResponse exception with HTTP status code and response body.
  UnknownResponse(this.code, this.body);

  String toString() {
    return "Unknown response - code: $code - body:$body";
  }
}
