// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:http/http.dart' as http;

/// Creates an HTTP client for web platform.
///
/// On web, HTTP requests are handled by the browser's built-in fetch API
/// or XMLHttpRequest. The dart:io HttpClient is not available because
/// browsers do not provide low-level socket access for security reasons.
///
/// Returns: A standard [http.Client] that uses browser APIs internally.
///
/// Throws [UnsupportedError] if [httpClient] is provided, since custom
/// HttpClient configuration (connection pooling, proxies, etc.) is not
/// available on web platforms.
http.Client createHttpClient(Object? httpClient) {
  if (httpClient != null) {
    throw UnsupportedError(
        'Custom HttpClient not supported on web. '
        'Web browsers handle HTTP internally via fetch/XMLHttpRequest. '
        'Pass null to use the default browser HTTP implementation.');
  }
  return http.Client();
}

/// HTTP overrides are not supported on web platform.
///
/// On iOS/Android, [HttpOverrides] allows customizing HTTP behavior
/// globally (e.g., for testing or proxy configuration). This is not
/// available on web because browsers manage HTTP connections internally
/// and do not expose low-level control to JavaScript/Dart code.
///
/// Throws [UnsupportedError] always on web platform.
void setGlobalHttpOverrides(Object overrides) {
  throw UnsupportedError(
      'HttpOverrides not supported on web. '
      'Browsers manage HTTP connections internally.');
}
