// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

/// Reference constants for a subset of the OpenZeppelin smart-account
/// contract's on-chain error codes.
///
/// When the contract rejects a call, the code appears inside the message of a
/// `SmartAccountTransactionException` (for example `Error(Contract, #3016)`).
/// The SDK surfaces the raw error but does not parse or map contract error
/// codes itself; callers can extract the code from the message and compare it
/// against these constants. The numeric range is `3xxx` (credential errors),
/// aligned with the contract's own `Error` enum.
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
