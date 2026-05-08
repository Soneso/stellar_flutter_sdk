// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

/// Configuration defaults and contract limits for OpenZeppelin smart-account
/// operations.
///
/// These constants tune timeouts, identification headers, and on-chain
/// contract limits used by the OpenZeppelin smart-account managers.
class OZConstants {
  /// Private constructor prevents instantiation; this class exposes only
  /// static constants.
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
}
