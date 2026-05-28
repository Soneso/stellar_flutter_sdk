// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:dio/dio.dart' as dio;

/// No-op HTTP adapter that returns a canned 200 response. Defaults to `'{}'`;
/// pass a relayer-shaped body (e.g. `'{"success":true,...}'`) when the
/// production deserialisation path must stay exercisable.
class NoopHttpAdapter implements dio.HttpClientAdapter {
  NoopHttpAdapter({this.responseBody = '{}'});

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
