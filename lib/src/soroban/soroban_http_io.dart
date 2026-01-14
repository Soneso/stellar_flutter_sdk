// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:io' as IO;
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

/// Configures HTTP overrides for native platforms.
/// Allows bypassing certificate validation when [enableOverrides] is true.
void configureHttpOverrides(Dio dio, bool enableOverrides) {
  if (!enableOverrides) return;
  final adapter = dio.httpClientAdapter;
  if (adapter is IOHttpClientAdapter) {
    adapter.createHttpClient = () {
      final client = IO.HttpClient();
      client.badCertificateCallback = (cert, host, port) => true;
      return client;
    };
  }
}
