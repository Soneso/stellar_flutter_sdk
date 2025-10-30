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

/// Exception thrown when request returned an non-success HTTP code.
class ErrorResponse implements Exception {
  http.Response response;

  ErrorResponse(this.response);

  String toString() {
    return "Error response from the server. Code: $code - Body: $body";
  }

  int get code => response.statusCode;
  String get body => response.body;
}

/// Exception thrown when too many requests were sent to the Horizon server.
class TooManyRequestsException implements Exception {
  int? _retryAfter;

  TooManyRequestsException(this._retryAfter);

  String toString() {
    return "The rate limit for the requesting IP address is over its allotted limit.";
  }

  int? get retryAfter => _retryAfter;
}

/// This interface is used in RequestBuilder classes <code>stream</code> method.
abstract class EventListener<T> {
  void onEvent(T object);
}

/// Represents possible order parameter values.
class RequestBuilderOrder {
  final _value;
  const RequestBuilderOrder._internal(this._value);
  toString() => 'RequestBuilderOrder.$_value';
  RequestBuilderOrder(this._value);
  get value => this._value;

  static const ASC = const RequestBuilderOrder._internal("asc");
  static const DESC = const RequestBuilderOrder._internal("desc");
}

/// Abstract class for request builders.
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

  /// Sets [cursor] parameter on the request.
  /// A cursor is a value that points to a specific location in a collection of resources.
  /// The cursor attribute itself is an opaque value meaning that users should not try to parse it.
  RequestBuilder cursor(String cursor) {
    queryParameters.addAll({"cursor": cursor});
    return this;
  }

  /// Sets [limit] parameter on the request.
  /// It defines maximum number of records to return.
  /// For range and default values check documentation of the endpoint requested.
  RequestBuilder limit(int number) {
    queryParameters.addAll({"limit": number.toString()});
    return this;
  }

  /// Sets [order] parameter on the request.
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

class ResponseHandler<T> {
  late TypeToken<T> _type;

  ResponseHandler(TypeToken<T> type) {
    this._type = type;
  }

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
