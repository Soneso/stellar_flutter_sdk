// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:dio/dio.dart' as dio;
import 'package:meta/meta.dart';

import '../core/smart_account_errors.dart';
import 'oz_validation.dart';

/// Library-private helpers shared between the OpenZeppelin smart-account
/// HTTP clients ([OZIndexerClient] and [OZRelayerClient]).
///
/// These helpers are not exported via the public barrel and must remain
/// import-private to the `lib/src/smartaccount/oz/` sources. The
/// [internal] annotation enforces this contract for any consumer that
/// imports the SDK by file path.

/// Removes every trailing `/` character from [url].
///
/// Used during URL normalization so the canonical base URL never carries
/// a trailing slash, which lets call-site code concatenate path
/// components with a single leading slash without producing
/// double-slash artefacts.
@internal
String stripTrailingSlashes(String url) {
  var end = url.length;
  while (end > 0 && url.codeUnitAt(end - 1) == 0x2F) {
    end--;
  }
  return url.substring(0, end);
}

/// Returns [totalTimeout] when it is at most [maxMillis] milliseconds, or
/// a [Duration] capped at [maxMillis] otherwise.
///
/// Connect timeouts must never grow with a caller-supplied overall
/// request timeout — a hostile or misconfigured server would otherwise
/// force unbounded TCP/TLS handshake waits.
@internal
Duration capConnectTimeout(Duration totalTimeout, int maxMillis) {
  if (totalTimeout.inMilliseconds <= maxMillis) {
    return totalTimeout;
  }
  return Duration(milliseconds: maxMillis);
}

/// `validateStatus` callback that accepts every HTTP status code.
///
/// Combined with explicit per-call status checks in the OZ HTTP
/// clients, this routes 4xx/5xx responses through the body-parsing path
/// rather than through Dio's default exception flow.
@internal
bool alwaysValidate(int? status) => true;

/// Returns `true` when [e] represents any of the three Dio timeout
/// variants (`connectionTimeout`, `sendTimeout`, `receiveTimeout`).
@internal
bool isDioTimeout(dio.DioException e) {
  return e.type == dio.DioExceptionType.receiveTimeout ||
      e.type == dio.DioExceptionType.connectionTimeout ||
      e.type == dio.DioExceptionType.sendTimeout;
}

/// Extracts a human-readable error message from a [dio.DioException].
///
/// Falls back to [defaultText] when the underlying exception has no
/// message and an empty `toString()` representation.
@internal
String dioErrorMessage(dio.DioException e,
    {String defaultText = 'Request failed'}) {
  final message = e.message;
  if (message != null && message.isNotEmpty) {
    return message;
  }
  final asString = e.toString();
  return asString.isEmpty ? defaultText : asString;
}

/// Truncates [body] to at most [maxChars] characters, appending an
/// ellipsis (`...`) when truncation occurred.
@internal
String truncateBody(String body, {int maxChars = 200}) {
  if (body.length > maxChars) {
    return '${body.substring(0, maxChars)}...';
  }
  return body;
}

/// Extracts a human-readable message from an arbitrary thrown object,
/// falling back to [defaultText] when the object's `toString()`
/// representation is empty.
@internal
String genericErrorMessage(Object e, {String defaultText = 'Request failed'}) {
  final text = e.toString();
  return text.isEmpty ? defaultText : text;
}

/// Returns `true` when [contentType] is `null` or its media type is
/// `application/json` or `application/problem+json` (case-insensitive,
/// with optional parameters such as `; charset=utf-8`).
///
/// A `null` content-type is accepted because some servers omit the
/// header even though they emit a valid JSON body; the JSON parse in
/// the calling code will fail loudly when that assumption is wrong.
///
/// The media type is matched by exact equality after splitting on `;`
/// and trimming, so look-alike types such as `application/jsonx` or
/// `application/json5` are rejected.
@internal
bool isJsonContentType(String? contentType) {
  if (contentType == null) {
    return true;
  }
  final semi = contentType.indexOf(';');
  final mediaType = (semi < 0 ? contentType : contentType.substring(0, semi))
      .trim()
      .toLowerCase();
  return mediaType == 'application/json' ||
      mediaType == 'application/problem+json';
}

/// Validates and normalizes [url] for an OpenZeppelin HTTP client.
///
/// The URL must be non-empty after trimming surrounding whitespace, use
/// HTTPS (or `http://` against a localhost host as identified by
/// [isLocalhostUrl]), and resolve to a non-empty host after trailing
/// slashes are stripped.
///
/// [serviceName] is the human-readable service identifier used in
/// every error message (e.g. `'Indexer'` or `'Relayer'`). It is
/// capitalised exactly as it should appear in the rendered message.
///
/// Throws [InvalidConfig] when any of the above checks fail.
@internal
String normalizeOZUrl(String url, {required String serviceName}) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) {
    throw ConfigurationException.invalidConfig('$serviceName URL is required');
  }
  if (!trimmed.startsWith('https://') && !isLocalhostUrl(trimmed)) {
    throw ConfigurationException.invalidConfig(
      '$serviceName URL must use HTTPS (or http://localhost for '
      'development): $trimmed',
    );
  }
  final stripped = stripTrailingSlashes(trimmed);
  // Stripping trailing slashes can leave a scheme-only string (for
  // example "https://" becomes "https:") that the prefix check still
  // treats as valid; reject any result without a non-empty host so
  // request-time failures don't surface as opaque URL errors.
  final parsed = Uri.tryParse(stripped);
  if (parsed == null || parsed.host.isEmpty) {
    throw ConfigurationException.invalidConfig(
      '$serviceName URL must include a host: $trimmed',
    );
  }
  return stripped;
}
