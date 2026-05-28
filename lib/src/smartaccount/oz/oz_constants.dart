// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

/// Configuration defaults and contract limits for OpenZeppelin smart-account
/// operations.
///
/// These constants tune timeouts, identification headers, and on-chain
/// contract limits used by the OpenZeppelin smart-account managers.
class OZConstants {
  OZConstants._();

  /// Default session expiry in milliseconds (7 days).
  static const int defaultSessionExpiryMs = 604800000;

  /// Default HTTP timeout for indexer requests in milliseconds (10 seconds).
  static const int defaultIndexerTimeoutMs = 10000;

  /// Default HTTP timeout for relayer requests in milliseconds (6 minutes).
  static const int defaultRelayerTimeoutMs = 360000;

  /// Timeout for WebAuthn credential operations in milliseconds (60 seconds).
  static const int webauthnTimeoutMs = 60000;

  /// XLM amount retained in the temporary funding account as the minimum
  /// balance reserve when transferring Friendbot funds to a smart-account
  /// wallet.
  static const int friendbotReserveXlm = 5;

  /// Default timeout for transaction submission and polling in seconds.
  static const int defaultTimeoutSeconds = 30;

  /// Maximum signers per context rule (OpenZeppelin contract limit).
  static const int maxSigners = 15;

  /// Maximum policies per context rule (OpenZeppelin contract limit).
  static const int maxPolicies = 5;

  /// HTTP header identifying the SDK name sent with indexer and relayer
  /// requests.
  static const String clientNameHeader = 'X-Client-Name';

  /// HTTP header identifying the SDK version sent with indexer and relayer
  /// requests.
  static const String clientVersionHeader = 'X-Client-Version';

  /// SDK name sent in client-identification headers. Identifies this SDK to
  /// the OpenZeppelin indexer and relayer services.
  static const String clientName = 'flutter-stellar-sdk';

  /// Maximum size in bytes of an indexer HTTP response body. Responses
  /// larger than this are rejected to protect the host process from
  /// memory-exhaustion by a hostile or misbehaving server. The cap is
  /// generous enough to fit any realistic contract-details payload (1 MiB).
  static const int maxIndexerResponseBytes = 1 * 1024 * 1024;

  /// Maximum size in bytes of a relayer HTTP response body. The relayer
  /// only ever returns a short JSON envelope so a tighter cap is
  /// appropriate (256 KiB).
  static const int maxRelayerResponseBytes = 256 * 1024;

  /// Maximum connect-timeout enforced on indexer requests, in milliseconds.
  ///
  /// Connect timeouts are capped independently of the overall request
  /// timeout so a long polling default cannot translate into a
  /// pathologically long TCP/TLS handshake wait.
  static const int maxIndexerConnectTimeoutMs = 10000;

  /// Maximum connect-timeout enforced on relayer requests, in milliseconds.
  ///
  /// Connect timeouts are capped independently of the overall request
  /// timeout so a long submission default cannot translate into a
  /// pathologically long TCP/TLS handshake wait.
  static const int maxRelayerConnectTimeoutMs = 30000;
}
