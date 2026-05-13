// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:dio/dio.dart' as dio;
import 'package:stellar_flutter_sdk/src/smartaccount/oz/oz_relayer_client.dart';

import 'noop_http_adapter.dart';

/// Recording mock of [OZRelayerClient] used by lifecycle tests to assert
/// that the kit closes its relayer client exactly once per `close()`
/// invocation.
///
/// The mock extends the production class through the
/// [OZRelayerClient.withDio] test-only constructor so a [NoopHttpAdapter]
/// keeps every request offline. Every call to [close] is recorded in
/// [closeCalls] so tests can assert the kit's resource-teardown contract.
class MockOZRelayerClient extends OZRelayerClient {
  /// Constructs a recording mock backed by a no-op HTTP adapter wired with
  /// a relayer-shaped response body so any production deserialiser paths
  /// the test exercises remain functional.
  MockOZRelayerClient()
      : super.withDio(
          'https://relayer.test',
          dio.Dio()
            ..httpClientAdapter = NoopHttpAdapter(
              responseBody:
                  '{"success":true,"hash":"deadbeef","status":"SUCCESS"}',
            ),
        );

  /// Captured `close()` call count. Increments on every invocation,
  /// including idempotent repeats — the base class itself is idempotent
  /// at the HTTP layer.
  int closeCalls = 0;

  @override
  Future<void> close() async {
    closeCalls++;
    await super.close();
  }
}
