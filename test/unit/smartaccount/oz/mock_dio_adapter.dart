// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart' as dio;

/// Test-only HTTP-mock adapter for `dio.Dio`.
///
/// Installed via `dio.Dio.httpClientAdapter = MockDioAdapter(...)` so unit
/// tests can return canned responses (or throw injected errors) without
/// opening real network sockets. Captures the most recent request URL and
/// body so tests can verify the SDK built the correct HTTP request.
class MockDioAdapter implements dio.HttpClientAdapter {
  /// Constructs a mock adapter that always returns a `200 OK` response with
  /// the given JSON body.
  MockDioAdapter.json(String responseBody)
      : _responseBody = responseBody,
        _statusCode = 200,
        _contentType = 'application/json',
        _extraResponseHeaders = const <String, List<String>>{},
        _throwOnFetch = null,
        _responseDelay = Duration.zero;

  /// Constructs a mock adapter that returns [responseBody] with the
  /// provided HTTP [statusCode] and [contentType]. Optional
  /// [extraResponseHeaders] are merged into the canned response (e.g. a
  /// `location` header for a 3xx redirect simulation). The optional
  /// [responseDelay] delays the response by the given duration so tests
  /// can race a [dio.CancelToken] against the adapter.
  MockDioAdapter.response({
    required String responseBody,
    int statusCode = 200,
    String contentType = 'application/json',
    Map<String, List<String>> extraResponseHeaders =
        const <String, List<String>>{},
    Duration responseDelay = Duration.zero,
  })  : _responseBody = responseBody,
        _statusCode = statusCode,
        _contentType = contentType,
        _extraResponseHeaders = extraResponseHeaders,
        _throwOnFetch = null,
        _responseDelay = responseDelay;

  /// Constructs a mock adapter that throws [error] on every request. Used
  /// to simulate network failures and timeouts.
  MockDioAdapter.throwing(Object error)
      : _responseBody = '',
        _statusCode = 0,
        _contentType = 'application/json',
        _extraResponseHeaders = const <String, List<String>>{},
        _throwOnFetch = error,
        _responseDelay = Duration.zero;

  /// Constructs a mock adapter that waits [delay] before returning a
  /// `200 OK` response with the given JSON body. Used by cancellation
  /// tests to keep the request in flight long enough for the test to
  /// cancel its token.
  MockDioAdapter.delayed(String responseBody, Duration delay)
      : _responseBody = responseBody,
        _statusCode = 200,
        _contentType = 'application/json',
        _extraResponseHeaders = const <String, List<String>>{},
        _throwOnFetch = null,
        _responseDelay = delay;

  final String _responseBody;
  final int _statusCode;
  final String _contentType;
  final Map<String, List<String>> _extraResponseHeaders;
  final Object? _throwOnFetch;
  final Duration _responseDelay;

  /// URL of the most recent request observed by the adapter.
  String? capturedUrl;

  /// Method of the most recent request observed by the adapter.
  String? capturedMethod;

  /// Decoded request body of the most recent request observed by the
  /// adapter. `null` for requests that did not include a request body.
  String? capturedBody;

  /// Headers of the most recent request observed by the adapter.
  Map<String, List<String>> capturedHeaders = <String, List<String>>{};

  /// `receiveTimeout` recorded on the most recent [dio.RequestOptions]. Used
  /// by tests to assert per-request overrides flowed through Dio's request
  /// merger.
  Duration? capturedReceiveTimeout;

  /// `sendTimeout` recorded on the most recent [dio.RequestOptions].
  Duration? capturedSendTimeout;

  /// `followRedirects` recorded on the most recent [dio.RequestOptions]. The
  /// clients pin this to `false` in their constructors and tests verify the
  /// option propagates to every emitted request.
  bool? capturedFollowRedirects;

  /// `maxRedirects` recorded on the most recent [dio.RequestOptions].
  int? capturedMaxRedirects;

  @override
  Future<dio.ResponseBody> fetch(
    dio.RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    capturedUrl = options.uri.toString();
    capturedMethod = options.method;
    capturedHeaders = <String, List<String>>{
      for (final entry in options.headers.entries)
        entry.key: <String>[entry.value.toString()],
    };
    capturedReceiveTimeout = options.receiveTimeout;
    capturedSendTimeout = options.sendTimeout;
    capturedFollowRedirects = options.followRedirects;
    capturedMaxRedirects = options.maxRedirects;
    if (requestStream != null) {
      final chunks = <int>[];
      await for (final chunk in requestStream) {
        chunks.addAll(chunk);
      }
      capturedBody = String.fromCharCodes(chunks);
    } else {
      capturedBody = null;
    }
    final error = _throwOnFetch;
    if (error != null) {
      if (error is dio.DioException) {
        throw dio.DioException(
          requestOptions: options,
          type: error.type,
          error: error.error,
          message: error.message,
          response: error.response,
          stackTrace: error.stackTrace,
        );
      }
      throw error;
    }
    if (_responseDelay > Duration.zero) {
      // Race the configured delay against the request's cancelFuture so
      // tests can cancel before the response is produced. Cancellation
      // surfaces as a `DioExceptionType.cancel` exactly as the real
      // adapter behaves under cancellation.
      final futures = <Future<Object?>>[
        Future<Object?>.delayed(_responseDelay),
      ];
      if (cancelFuture != null) {
        futures.add(
          cancelFuture.then<Object?>(
            (_) => _CancelSentinel.instance,
          ),
        );
      }
      final winner = await Future.any(futures);
      if (identical(winner, _CancelSentinel.instance)) {
        throw dio.DioException.requestCancelled(
          requestOptions: options,
          reason: 'cancelled by test',
        );
      }
    }
    final headers = <String, List<String>>{
      'content-type': <String>[_contentType],
    };
    for (final entry in _extraResponseHeaders.entries) {
      headers[entry.key] = entry.value;
    }
    return dio.ResponseBody.fromString(
      _responseBody,
      _statusCode,
      headers: headers,
    );
  }

  @override
  void close({bool force = false}) {
    // No-op: the adapter holds no resources.
  }
}

/// Sentinel value used by [MockDioAdapter] to distinguish a cancelled
/// request from a completed response when racing the cancellation future
/// against the configured delay.
class _CancelSentinel {
  const _CancelSentinel._();

  static const _CancelSentinel instance = _CancelSentinel._();
}
