// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

/// Contract-level error codes from the OpenZeppelin smart account contract.
///
/// These codes are returned in failed contract responses and can be mapped to
/// SDK exceptions by code-aware error handlers when interpreting transaction
/// results. The numeric range is `3xxx` (credential errors), aligned with the
/// contract's own `Error` enum.
class OZContractErrorCodes {
  OZContractErrorCodes._();

  /// Integer arithmetic overflow occurred in the contract.
  static const int mathOverflow = 3012;

  /// The `key_data` field on a signer exceeds the maximum allowed size.
  static const int keyDataTooLarge = 3013;

  /// The number of context-rule IDs in the auth payload does not match the
  /// expected count.
  static const int contextRuleIdsLengthMismatch = 3014;

  /// A name field (e.g. context-rule name) exceeds the maximum allowed length.
  static const int nameTooLong = 3015;

  /// The signer is not authorised to sign the given context rule.
  static const int unauthorizedSigner = 3016;
}
