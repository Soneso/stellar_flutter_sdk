// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:http/http.dart' as http;
import 'package:stellar_flutter_sdk/src/asset_type_credit_alphanum.dart';
import 'package:stellar_flutter_sdk/src/asset_type_native.dart';
import 'package:stellar_flutter_sdk/src/stellar_sdk.dart';
import 'dart:convert';
import '../responses/response.dart';
import '../assets.dart';

/// Exception thrown when request returned an non-success HTTP code.
class ErrorResponse implements Exception {
  int _code;
  String _body;

  ErrorResponse(this._code, this._body);

  String toString() {
    return "Error response from the server. Code: ${_code} - Body: $body";
  }

  int get code => _code;
  String get body => _body;
}

/// Exception thrown when too many requests were sent to the Horizon server.
class TooManyRequestsException implements Exception {
  int _retryAfter;

  TooManyRequestsException(this._retryAfter);

  String toString() {
    return "The rate limit for the requesting IP address is over its alloted limit.";
  }

  int get retryAfter => _retryAfter;
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
  Uri uriBuilder;
  http.Client httpClient;
  List<String> _segments;
  bool _segmentsAdded = false;
  Map<String, String> queryParameters;
  static final Map<String, String> headers = {
    "X-Client-Name": "stellar_flutter_sdk",
    "X-Client-Version": StellarSDK.versionNumber
  };

  RequestBuilder(
      http.Client httpClient, Uri serverURI, List<String> defaultSegment) {
    this.httpClient = httpClient;
    uriBuilder = serverURI;
    _segments = List<String>();
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
        pathSegments: _segments,
      );
    }
    if (queryParameters.length > 0) {
      build = build.replace(queryParameters: queryParameters);
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
}

class ResponseHandler<T> {
  TypeToken<T> _type;

  ResponseHandler(TypeToken<T> type) {
    this._type = type;
  }

  T handleResponse(final http.Response response) {
    // Too Many Requests
    if (response.statusCode == 429) {
      int retryAfter = int.parse(response.headers["Retry-After"]);
      throw TooManyRequestsException(retryAfter);
    }

    String content = response.body;

    // Other errors
    if (response.statusCode >= 300) {
      throw ErrorResponse(response.statusCode, content);
    }

    T object = ResponseConverter.fromJson<T>(json.decode(content));
    if (object is Response) {
      object.setHeaders(response.headers);
    }
    if (object is TypedResponse) {
      object.setType(_type);
    }
    return object;
  }
}
