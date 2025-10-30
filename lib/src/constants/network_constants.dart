// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

/// Network, timeout, and HTTP-related constants for the Stellar SDK.
///
/// This file contains constants related to network operations, timeouts,
/// transaction time bounds, HTTP status codes, and default fee values.
/// These constants ensure consistent behavior across network interactions
/// and transaction construction.
///
/// Note: This class cannot be instantiated. All constants are static and
/// should be accessed directly via the class name.
final class NetworkConstants {
  // Private constructor to prevent instantiation
  NetworkConstants._();

  // ============================================================================
  // TIMEOUT AND TIME BOUND CONSTANTS
  // ============================================================================
  // Constants related to transaction timeouts and time bound calculations.
  // These values affect how long transactions remain valid and how much
  // buffer time is provided for clock skew and network delays.

  /// Default transaction timeout in seconds.
  ///
  /// This is the default duration for which a transaction remains valid
  /// after being constructed. After this period, the transaction will be
  /// rejected by the network if not yet included in a ledger.
  ///
  /// Default: 300 seconds (5 minutes)
  static const int DEFAULT_TIMEOUT_SECONDS = 300;

  /// Transaction time buffer in seconds.
  ///
  /// This buffer is subtracted from the current time when setting the lower
  /// bound of transaction time bounds. It accounts for potential clock skew
  /// between the client and the Stellar network, ensuring transactions are
  /// not rejected due to minor time differences.
  ///
  /// Default: 10 seconds
  static const int TRANSACTION_TIME_BUFFER_SECONDS = 10;

  /// WebAuth challenge grace period in seconds.
  ///
  /// The time window during which a WebAuth challenge transaction is considered
  /// valid. This grace period allows for clock differences and network delays
  /// between the client and the authentication server.
  ///
  /// Default: 300 seconds (5 minutes)
  /// Reference: SEP-10 Web Authentication specification
  static const int WEBAUTH_GRACE_PERIOD_SECONDS = 300;

  /// Poll wait time in seconds for transaction status checks.
  ///
  /// The delay between consecutive status check requests when polling for
  /// transaction completion. This prevents overwhelming the RPC server with
  /// rapid consecutive requests.
  ///
  /// Default: 3 seconds
  static const int TRANSACTION_POLL_WAIT_SECONDS = 3;

  // ============================================================================
  // LEDGER EXPIRATION CONSTANTS
  // ============================================================================
  // Constants related to Soroban contract state expiration and restoration.

  /// Default ledger expiration offset in blocks.
  ///
  /// The number of ledgers to add to the current ledger sequence when setting
  /// the expiration for Soroban authorization entries. This gives a buffer for
  /// transaction submission and ensures the authorization remains valid.
  ///
  /// Default: 100 blocks (approximately 8.3 minutes at 5-second block time)
  static const int DEFAULT_LEDGER_EXPIRATION_OFFSET = 100;

  // ============================================================================
  // FEE CONSTANTS
  // ============================================================================
  // Constants related to transaction fees.

  /// Default base fee for Soroban operations in stroops.
  ///
  /// This is the default fee used when constructing Soroban transactions
  /// through the SorobanClient. The actual fee may be higher after simulation
  /// to account for resource consumption.
  ///
  /// Default: 100 stroops (0.00001 XLM)
  static const int DEFAULT_SOROBAN_BASE_FEE = 100;

  // ============================================================================
  // HTTP STATUS CODE CONSTANTS
  // ============================================================================
  // HTTP status codes used in network request handling and error detection.

  /// HTTP status code threshold for errors.
  ///
  /// Any HTTP response with a status code greater than or equal to this value
  /// is considered an error response and will trigger error handling logic.
  ///
  /// Default: 300 (HTTP redirection and error codes)
  static const int HTTP_ERROR_STATUS_THRESHOLD = 300;

  /// HTTP 429 Too Many Requests status code.
  ///
  /// Indicates that the client has sent too many requests in a given time period
  /// and should retry after a delay (typically specified in the Retry-After header).
  ///
  /// Reference: RFC 6585 - HTTP Status Code 429 (Too Many Requests)
  static const int HTTP_TOO_MANY_REQUESTS = 429;
}
