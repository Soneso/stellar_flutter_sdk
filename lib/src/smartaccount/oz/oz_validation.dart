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

/// Returns `true` when [url] is a development localhost URL of the form
/// `http://localhost`, `http://localhost:<port>`, or `http://localhost/<path>`.
///
/// Returns `false` for any other input, including HTTPS schemes and hostnames
/// that merely begin with `localhost` such as `http://localhost.evil.com`.
bool isLocalhostUrl(String url) {
  const prefix = 'http://localhost';
  if (!url.startsWith(prefix)) {
    return false;
  }
  // why: a bare startsWith check would accept `http://localhost.evil.com`.
  // Accept only the empty suffix or a suffix starting with `:` (port) or `/`
  // (path) so the boundary character following `localhost` is constrained.
  if (url.length == prefix.length) {
    return true;
  }
  final boundary = url.codeUnitAt(prefix.length);
  return boundary == 0x3A || boundary == 0x2F;
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
