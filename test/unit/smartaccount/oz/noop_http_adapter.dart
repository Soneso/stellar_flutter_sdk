// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:dio/dio.dart' as dio;

/// HTTP adapter that returns a configurable canned response body with a 200
/// status code and records nothing. Used so test doubles that wrap the
/// production HTTP clients can be constructed without a real network
/// endpoint while still satisfying the production client contract.
///
/// The adapter is intentionally trivial: it is consumed by lifecycle tests
/// whose assertions focus on close-call accounting and HTTP-client wiring,
/// not on request / response payloads. Tests that need to capture or
/// assert on outbound payloads should use the recording harnesses in
/// `oz_pipeline_fixtures.dart` instead.
class NoopHttpAdapter implements dio.HttpClientAdapter {
  /// Constructs a no-op adapter that returns the supplied JSON body.
  ///
  /// Defaults to an empty JSON object (`'{}'`). Callers that exercise the
  /// relayer client may want to pass a relayer-shaped response such as
  /// `'{"success":true,"hash":"deadbeef","status":"SUCCESS"}'` so the
  /// production deserialisation path stays exercisable.
  NoopHttpAdapter({this.responseBody = '{}'});

  /// The JSON body returned by every `fetch` invocation.
  final String responseBody;

  @override
  Future<dio.ResponseBody> fetch(
    dio.RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return dio.ResponseBody.fromString(
      responseBody,
      200,
      headers: <String, List<String>>{
        'content-type': <String>['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
