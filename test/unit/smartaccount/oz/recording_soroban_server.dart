// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:dio/dio.dart' as dio;
import 'package:stellar_flutter_sdk/src/soroban/soroban_server.dart';

import 'noop_http_adapter.dart';

/// Recording [SorobanServer] subclass used by lifecycle tests to assert
/// that the kit calls `close()` on the shared Soroban RPC client exactly
/// once per kit close.
///
/// Construction goes through [SorobanServer.withDio] with a [NoopHttpAdapter]
/// so any RPC call attempted during the test is short-circuited at the
/// transport layer rather than reaching out to a real endpoint. Every
/// invocation of [close] increments [closeCalls].
class RecordingSorobanServer extends SorobanServer {
  /// Constructs a recording server backed by a no-op HTTP adapter so the
  /// transport is fully self-contained.
  RecordingSorobanServer()
      : super.withDio(
          'https://soroban.test/',
          dio.Dio()..httpClientAdapter = NoopHttpAdapter(),
        );

  /// Captured `close()` call count. Increments on every invocation; the
  /// underlying Dio client tolerates repeated close calls without error.
  int closeCalls = 0;

  @override
  void close() {
    closeCalls++;
    super.close();
  }
}
