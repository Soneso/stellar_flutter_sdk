// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import '../../key_pair.dart';
import '../core/smart_account_errors.dart';

/// Validates that [address] is a Stellar contract address (C-address).
///
/// Uses full StrKey validation including the CRC16 checksum.
///
/// Throws an [InvalidAddress] validation exception when [address] is not a
/// valid contract address. The exception message is
/// `"<fieldName> must be a valid contract address (C...), got: <address>"`.
void requireContractAddress(String address, {required String fieldName}) {
  if (!StrKey.isValidContractId(address)) {
    throw InvalidAddress(
      '$fieldName must be a valid contract address (C...), got: $address',
    );
  }
}

/// Returns `true` when [url] is a development localhost URL safe for use as
/// an OZ service endpoint.
///
/// The URL is parsed via [Uri.tryParse] and the resolved host must equal
/// `localhost`, `127.0.0.1`, or `::1` (the IPv6 loopback, which [Uri] strips
/// of its surrounding brackets). Only the `http` scheme is accepted.
///
/// URLs that smuggle a different host through userinfo (for example
/// `http://localhost:8080@evil.com/`, where RFC 3986 parses `localhost:8080`
/// as userinfo and `evil.com` as the host) are rejected by the host check.
/// Any URL that carries userinfo at all is also rejected outright so a
/// parser disagreement between this check and the HTTP client cannot let
/// an attacker-controlled host through.
///
/// Returns `false` for any malformed input, non-HTTP scheme, or non-loopback
/// host.
bool isLocalhostUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) {
    return false;
  }
  if (uri.scheme.toLowerCase() != 'http') {
    return false;
  }
  final host = uri.host.toLowerCase();
  if (host != 'localhost' && host != '127.0.0.1' && host != '::1') {
    return false;
  }
  // Even with a loopback host, the presence of userinfo signals a
  // host-confusion attack attempt — reject it outright rather than risk a
  // parser disagreement between this check and the HTTP client below.
  if (uri.userInfo.isNotEmpty) {
    return false;
  }
  return true;
}

/// Validates that [address] is a Stellar account ID (G-address) or a Stellar
/// contract address (C-address).
///
/// Uses full StrKey validation including the CRC16 checksum. Muxed account
/// IDs (M-addresses) are intentionally rejected: callers that need muxed
/// addresses must validate them separately.
///
/// Throws an [InvalidAddress] validation exception when [address] is not a
/// valid Stellar address. The exception message is
/// `"<fieldName> must be a valid Stellar address (G... or C...), got: <address>"`.
void requireStellarAddress(String address, {required String fieldName}) {
  if (!StrKey.isValidStellarAccountId(address) &&
      !StrKey.isValidContractId(address)) {
    throw InvalidAddress(
      '$fieldName must be a valid Stellar address (G... or C...), '
      'got: $address',
    );
  }
}
