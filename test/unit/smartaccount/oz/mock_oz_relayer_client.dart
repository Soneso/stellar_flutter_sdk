// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:dio/dio.dart' as dio;
import 'package:stellar_flutter_sdk/src/smartaccount/oz/oz_relayer_client.dart';

import 'noop_http_adapter.dart';

/// Recording mock of [OZRelayerClient] used by lifecycle tests to assert close() invocations.
class MockOZRelayerClient extends OZRelayerClient {
  MockOZRelayerClient()
      : super.withDio(
          'https://relayer.test',
          dio.Dio()
            ..httpClientAdapter = NoopHttpAdapter(
              responseBody:
                  '{"success":true,"hash":"deadbeef","status":"SUCCESS"}',
            ),
        );

  int closeCalls = 0;

  @override
  Future<void> close() async {
    closeCalls++;
    await super.close();
  }
}
