// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:dio/dio.dart' as dio;
import 'package:stellar_flutter_sdk/src/soroban/soroban_server.dart';

import 'noop_http_adapter.dart';

/// Recording [SorobanServer] subclass used by lifecycle tests to assert close() is called exactly once per kit close.
class RecordingSorobanServer extends SorobanServer {
  RecordingSorobanServer()
      : super.withDio(
          'https://soroban.test/',
          dio.Dio()..httpClientAdapter = NoopHttpAdapter(),
        );

  /// Increments on every invocation; the underlying Dio client tolerates repeated close calls without error.
  int closeCalls = 0;

  @override
  void close() {
    closeCalls++;
    super.close();
  }
}
