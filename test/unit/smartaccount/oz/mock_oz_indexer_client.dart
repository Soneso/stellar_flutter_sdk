// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:dio/dio.dart' as dio;
import 'package:stellar_flutter_sdk/src/smartaccount/oz/oz_indexer_client.dart';

import 'noop_http_adapter.dart';

/// Recording mock of [OZIndexerClient] used by lifecycle tests to assert close() is invoked exactly once per close() invocation.
class MockOZIndexerClient extends OZIndexerClient {
  MockOZIndexerClient()
      : super.withDio(
          'https://indexer.test',
          dio.Dio()..httpClientAdapter = NoopHttpAdapter(),
        );

  int closeCalls = 0;

  @override
  Future<void> close() async {
    closeCalls++;
    await super.close();
  }
}
