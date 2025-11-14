// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:stellar_flutter_sdk/src/asset_type_credit_alphanum.dart';
import 'package:stellar_flutter_sdk/src/asset_type_native.dart';
import 'package:stellar_flutter_sdk/src/constants/network_constants.dart';
import 'package:stellar_flutter_sdk/src/stellar_sdk.dart';

import '../assets.dart';
import '../responses/response.dart';

/// Exception thrown when a request returns a non-success HTTP code.
///
/// This exception is raised when the Horizon server responds with an HTTP status
/// code indicating an error (400+). The exception contains the full HTTP response
/// for detailed error analysis.
///
/// Example:
/// ```dart
/// try {
///   var account = await sdk.accounts.account('INVALID_ID');
/// } catch (e) {
///   if (e is ErrorResponse) {
///     print('Error code: ${e.code}');
///     print('Error body: ${e.body}');
///   }
/// }
/// ```
///
/// See also:
/// - [TooManyRequestsException] for rate limit errors
class ErrorResponse implements Exception {
  http.Response response;

  ErrorResponse(this.response);

  String toString() {
    return "Error response from the server. Code: $code - Body: $body";
  }

  int get code => response.statusCode;
  String get body => response.body;
}

/// Exception thrown when the rate limit for requests to the Horizon server is exceeded.
///
/// Horizon enforces rate limits to prevent abuse. When the limit is exceeded,
/// this exception is thrown with a suggested retry-after delay in seconds.
///
/// Parameters:
/// - retryAfter: Number of seconds to wait before retrying the request
///
/// Example:
/// ```dart
/// try {
///   var accounts = await sdk.accounts.forSigner(signerKey).execute();
/// } catch (e) {
///   if (e is TooManyRequestsException) {
///     print('Rate limited. Retry after: ${e.retryAfter} seconds');
///     await Future.delayed(Duration(seconds: e.retryAfter ?? 60));
///     // Retry the request
///   }
/// }
/// ```
///
/// See also:
/// - [ErrorResponse] for other HTTP errors
class TooManyRequestsException implements Exception {
  int? _retryAfter;

  TooManyRequestsException(this._retryAfter);

  String toString() {
    return "The rate limit for the requesting IP address is over its allotted limit.";
  }

  int? get retryAfter => _retryAfter;
}

/// Interface for streaming events from Horizon server-sent events (SSE).
///
/// This interface is used in RequestBuilder stream methods to receive real-time
/// updates from the Horizon server as new records are created.
///
/// Example:
/// ```dart
/// class MyPaymentListener implements EventListener<OperationResponse> {
///   @override
///   void onEvent(OperationResponse payment) {
///     print('New payment: ${payment.id}');
///   }
/// }
///
/// sdk.payments.forAccount(accountId).stream().listen(MyPaymentListener());
/// ```
///
/// See also:
/// - RequestBuilder stream methods for SSE connections
abstract class EventListener<T> {
  /// Called when a new event is received from the stream.
  ///
  /// Parameters:
  /// - object: The response object representing the new event
  void onEvent(T object);
}

/// Represents sorting order options for query results.
///
/// Horizon API endpoints support ordering results in ascending or descending
/// order based on the natural ordering of the resource.
///
/// Example:
/// ```dart
/// // Get transactions in descending order (newest first)
/// var transactions = await sdk.transactions
///     .order(RequestBuilderOrder.DESC)
///     .limit(10)
///     .execute();
///
/// // Get payments in ascending order (oldest first)
/// var payments = await sdk.payments
///     .order(RequestBuilderOrder.ASC)
///     .execute();
/// ```
class RequestBuilderOrder {
  final _value;
  const RequestBuilderOrder._internal(this._value);
  toString() => 'RequestBuilderOrder.$_value';
  RequestBuilderOrder(this._value);
  get value => this._value;

  /// Ascending order (oldest to newest).
  static const ASC = const RequestBuilderOrder._internal("asc");

  /// Descending order (newest to oldest).
  static const DESC = const RequestBuilderOrder._internal("desc");
}

/// Base class for all Horizon API request builders.
///
/// RequestBuilder provides common functionality for building and executing
/// HTTP requests to the Horizon server. It supports method chaining for
/// setting query parameters like cursor, limit, and order.
///
/// Subclasses implement specific endpoint functionality (accounts, transactions,
/// payments, etc.) while inheriting common query capabilities.
///
/// Example:
/// ```dart
/// // Request builders support method chaining
/// var payments = await sdk.payments
///     .forAccount(accountId)
///     .order(RequestBuilderOrder.DESC)
///     .limit(20)
///     .cursor('cursor_value')
///     .execute();
/// ```
///
/// See also:
/// - `AccountsRequestBuilder` for account queries
/// - `TransactionsRequestBuilder` for transaction queries
/// - `PaymentsRequestBuilder` for payment queries
abstract class RequestBuilder {
  late Uri uriBuilder;
  late http.Client httpClient;
  late List<String> _segments;
  bool _segmentsAdded = false;
  late Map<String, String> queryParameters;
  static final Map<String, String> headers = Map<String, String>.unmodifiable({
    "X-Client-Name": "stellar_flutter_sdk",
    "X-Client-Version": StellarSDK.versionNumber
  });

  RequestBuilder(
      http.Client httpClient, Uri serverURI, List<String>? defaultSegment) {
    this.httpClient = httpClient;
    uriBuilder = serverURI;
    _segments = [];
    if (defaultSegment != null) {
      this.setSegments(defaultSegment);
    }
    _segmentsAdded = false; // Allow overwriting segments
    queryParameters = {};
  }

  RequestBuilder setSegments(List<String> segments) {
    if (_segmentsAdded) {
      throw new Exception("URL segments have been already added.");
    }

    _segmentsAdded = true;
    // Remove default segments
    this._segments.clear();
    for (String segment in segments) {
      this._segments.add(segment);
    }

    return this;
  }

  /// Sets the cursor parameter for pagination.
  ///
  /// A cursor points to a specific location in a collection of resources and is
  /// used for efficient pagination. Cursors are opaque values that should not be
  /// parsed or constructed manually.
  ///
  /// Parameters:
  /// - cursor: Opaque cursor value from a previous response
  ///
  /// Returns: This builder instance for method chaining
  ///
  /// Example:
  /// ```dart
  /// // Get first page
  /// var page1 = await sdk.payments.limit(10).execute();
  ///
  /// // Get next page using cursor from previous response
  /// var page2 = await sdk.payments
  ///     .cursor(page1.records.last.pagingToken)
  ///     .limit(10)
  ///     .execute();
  /// ```
  RequestBuilder cursor(String cursor) {
    queryParameters.addAll({"cursor": cursor});
    return this;
  }

  /// Sets the maximum number of records to return.
  ///
  /// Limits the number of records returned in a single response. Different
  /// endpoints may have different default and maximum values.
  ///
  /// Parameters:
  /// - number: Maximum number of records (typically 1-200)
  ///
  /// Returns: This builder instance for method chaining
  ///
  /// Example:
  /// ```dart
  /// // Get last 50 transactions
  /// var transactions = await sdk.transactions
  ///     .order(RequestBuilderOrder.DESC)
  ///     .limit(50)
  ///     .execute();
  /// ```
  RequestBuilder limit(int number) {
    queryParameters.addAll({"limit": number.toString()});
    return this;
  }

  /// Sets the sort order for results.
  ///
  /// Controls whether results are returned in ascending (oldest first) or
  /// descending (newest first) order.
  ///
  /// Parameters:
  /// - direction: Sort order (RequestBuilderOrder.ASC or RequestBuilderOrder.DESC)
  ///
  /// Returns: This builder instance for method chaining
  ///
  /// Example:
  /// ```dart
  /// // Get newest payments first
  /// var payments = await sdk.payments
  ///     .order(RequestBuilderOrder.DESC)
  ///     .execute();
  /// ```
  ///
  /// See also:
  /// - [RequestBuilderOrder] for available sort directions
  RequestBuilder order(RequestBuilderOrder direction) {
    queryParameters.addAll({"order": direction.value});
    return this;
  }

  Uri buildUri() {
    Uri build = uriBuilder;

    if (_segments.length > 0) {
      build = build.replace(
        pathSegments: [
          ...build.pathSegments,
          ..._segments,
        ],
      );
    }
    if (queryParameters.length > 0) {
      build = build.replace(
        queryParameters: {
          ...build.queryParameters,
          ...queryParameters,
        },
      );
    }

    return build;
  }

  String encodeAsset(Asset asset) {
    if (asset is AssetTypeNative) {
      return Asset.TYPE_NATIVE;
    } else if (asset is AssetTypeCreditAlphaNum) {
      AssetTypeCreditAlphaNum creditAsset = asset;
      return creditAsset.code + ":" + creditAsset.issuerId;
    } else {
      throw Exception("unsupported asset " + asset.type);
    }
  }

  String encodeAssets(List<Asset> assets) {
    List<String> encodedAssets = [];
    for (Asset next in assets) {
      encodedAssets.add(encodeAsset(next));
    }
    return encodedAssets.join(",");
  }
}

/// Handles HTTP responses from Horizon and converts them to typed objects.
///
/// This class processes HTTP responses, checks for errors, and deserializes
/// JSON data into strongly-typed response objects. It handles rate limiting,
/// error responses, and type conversion.
///
/// Type Parameters:
/// - T: The expected response type
///
/// Throws:
/// - [TooManyRequestsException]: When rate limit is exceeded (HTTP 429)
/// - [ErrorResponse]: When server returns an error status (HTTP 400+)
///
/// Example usage is typically internal to request builders:
/// ```dart
/// ResponseHandler<AccountResponse> handler =
///     ResponseHandler<AccountResponse>(TypeToken<AccountResponse>());
/// var account = handler.handleResponse(httpResponse);
/// ```
class ResponseHandler<T> {
  late TypeToken<T> _type;

  ResponseHandler(TypeToken<T> type) {
    this._type = type;
  }

  /// Processes an HTTP response and converts it to the expected type.
  ///
  /// Parameters:
  /// - response: The HTTP response from the Horizon server
  ///
  /// Returns: Typed response object
  ///
  /// Throws:
  /// - [TooManyRequestsException]: When HTTP status is 429
  /// - [ErrorResponse]: When HTTP status is 400 or higher
  T handleResponse(final http.Response response) {
    // Too Many Requests
    if (response.statusCode == NetworkConstants.HTTP_TOO_MANY_REQUESTS) {
      final retryAfterResponseHeader = response.headers["retry-after"];
      final retryAfter = retryAfterResponseHeader != null
          ? int.parse(retryAfterResponseHeader)
          : null;
      throw TooManyRequestsException(retryAfter);
    }

    // Other errors
    if (response.statusCode >= NetworkConstants.HTTP_ERROR_STATUS_THRESHOLD) {
      throw ErrorResponse(response);
    }

    T object = ResponseConverter.fromJson<T>(json.decode(response.body));
    if (object is Response) {
      object.setHeaders(response.headers);
    }
    if (object is TypedResponse) {
      object.setType(_type);
    }
    return object;
  }
}
