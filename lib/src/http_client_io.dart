// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:io';
import 'package:http/io_client.dart';
import 'package:http/http.dart' as http;

/// Creates an HTTP client for native platforms.
http.Client createHttpClient(Object? httpClient) {
  if (httpClient != null) {
    return IOClient(httpClient as HttpClient);
  }
  return http.Client();
}

/// Sets global HTTP overrides for native platforms.
void setGlobalHttpOverrides(Object overrides) {
  HttpOverrides.global = overrides as HttpOverrides;
}
