// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr/xdr_account.dart';

/// Account authorization flags that control asset trustline behavior.
///
/// Account flags are used by asset issuers to control how their assets can be
/// held and transferred. These flags are set using [SetOptionsOperation] and
/// affect all trustlines to the issuer's assets.
///
/// Available flags:
/// - **AUTH_REQUIRED**: Trustlines require explicit authorization
/// - **AUTH_REVOCABLE**: Issuer can revoke trustline authorization
/// - **AUTH_IMMUTABLE**: Authorization flags become permanent
/// - **AUTH_CLAWBACK_ENABLED**: Issuer can clawback assets
///
/// Flag combinations:
/// ```dart
/// // Common regulated asset setup
/// SetOptionsOperation regulated = SetOptionsOperationBuilder()
///   .setSetFlags(
///     AccountFlag.AUTH_REQUIRED_FLAG.value |
///     AccountFlag.AUTH_REVOCABLE_FLAG.value
///   )
///   .build();
///
/// // Enable clawback for compliance
/// SetOptionsOperation clawback = SetOptionsOperationBuilder()
///   .setSetFlags(AccountFlag.AUTH_CLAWBACK_ENABLED_FLAG.value)
///   .build();
///
/// // Make account immutable (permanent)
/// SetOptionsOperation immutable = SetOptionsOperationBuilder()
///   .setSetFlags(AccountFlag.AUTH_IMMUTABLE_FLAG.value)
///   .build();
/// ```
///
/// Important notes:
/// - Flags only affect credit assets issued by the account
/// - AUTH_IMMUTABLE makes other authorization flags permanent
/// - Once AUTH_IMMUTABLE is set, it cannot be unset
/// - AUTH_CLAWBACK_ENABLED cannot be combined with AUTH_IMMUTABLE
/// - Clawback can only be set before any trustlines exist
///
/// See also:
/// - [SetOptionsOperation] for setting account flags
/// - [AllowTrustOperation] for authorizing specific trustlines
/// - [ClawbackOperation] for clawing back assets
/// - [Stellar Account Flags](https://developers.stellar.org/docs/learn/encyclopedia/security/signatures-multisig#authorization-flags)
class AccountFlag {
  /// Authorization required (0x1).
  ///
  /// When set, the issuer must explicitly authorize each trustline before
  /// accounts can hold the asset. This provides full control over who can
  /// hold the asset.
  ///
  /// Use cases:
  /// - Regulated securities requiring KYC/AML
  /// - Restricted assets for verified users only
  /// - Compliance with financial regulations
  ///
  /// Effect:
  /// - New trustlines start unauthorized
  /// - Accounts cannot receive the asset until authorized
  /// - Issuer uses [AllowTrustOperation] to authorize trustlines
  ///
  /// Example:
  /// ```dart
  /// // Enable authorization required
  /// SetOptionsOperation enableAuth = SetOptionsOperationBuilder()
  ///   .setSetFlags(AccountFlag.AUTH_REQUIRED_FLAG.value)
  ///   .build();
  ///
  /// // Later, authorize a specific account
  /// AllowTrustOperation authorize = AllowTrustOperationBuilder(
  ///   trustor: accountId,
  ///   assetCode: "USD",
  ///   authorize: true
  /// ).build();
  /// ```
  static final AUTH_REQUIRED_FLAG =
      AccountFlag._internal(XdrAccountFlags.AUTH_REQUIRED_FLAG.value);

  /// Authorization revocable (0x2).
  ///
  /// When set, the issuer can freeze or unfreeze trustlines, preventing
  /// assets from being transferred. Combined with AUTH_REQUIRED, provides
  /// full control over asset movement.
  ///
  /// Use cases:
  /// - Freezing assets under investigation
  /// - Enforcing court orders or legal compliance
  /// - Responding to security incidents
  /// - Regulatory compliance requirements
  ///
  /// Effect:
  /// - Issuer can deauthorize trustlines at any time
  /// - Deauthorized accounts cannot send or receive the asset
  /// - Accounts can still return assets to the issuer
  ///
  /// Example:
  /// ```dart
  /// // Enable revocable authorization
  /// SetOptionsOperation enableRevoke = SetOptionsOperationBuilder()
  ///   .setSetFlags(
  ///     AccountFlag.AUTH_REQUIRED_FLAG.value |
  ///     AccountFlag.AUTH_REVOCABLE_FLAG.value
  ///   )
  ///   .build();
  ///
  /// // Later, revoke authorization from an account
  /// AllowTrustOperation revoke = AllowTrustOperationBuilder(
  ///   trustor: accountId,
  ///   assetCode: "USD",
  ///   authorize: false
  /// ).build();
  /// ```
  static final AUTH_REVOCABLE_FLAG =
      AccountFlag._internal(XdrAccountFlags.AUTH_REVOCABLE_FLAG.value);

  /// Authorization immutable (0x4).
  ///
  /// When set, makes the account's authorization flags permanent and prevents
  /// the account from being deleted. This is irreversible.
  ///
  /// Use cases:
  /// - Creating truly decentralized assets
  /// - Proving to users that authorization won't be added later
  /// - Making asset behavior predictable and permanent
  ///
  /// Effect:
  /// - AUTH_REQUIRED and AUTH_REVOCABLE flags become permanent
  /// - No authorization flags can be changed afterward
  /// - Account can never be merged or deleted
  /// - Provides strong guarantees to asset holders
  ///
  /// Warning: This is permanent and cannot be undone. Use with extreme caution.
  ///
  /// Example:
  /// ```dart
  /// // Make account immutable (PERMANENT - cannot be reversed!)
  /// SetOptionsOperation makeImmutable = SetOptionsOperationBuilder()
  ///   .setSetFlags(AccountFlag.AUTH_IMMUTABLE_FLAG.value)
  ///   .build();
  ///
  /// // Typical use: Set desired auth flags, then make immutable
  /// Transaction setup = TransactionBuilder(issuerAccount)
  ///   // First, set desired authorization behavior
  ///   .addOperation(SetOptionsOperationBuilder()
  ///     .setSetFlags(AccountFlag.AUTH_REQUIRED_FLAG.value)
  ///     .build())
  ///   // Then make it permanent
  ///   .addOperation(SetOptionsOperationBuilder()
  ///     .setSetFlags(AccountFlag.AUTH_IMMUTABLE_FLAG.value)
  ///     .build())
  ///   .build();
  /// ```
  static final AUTH_IMMUTABLE_FLAG =
      AccountFlag._internal(XdrAccountFlags.AUTH_IMMUTABLE_FLAG.value);

  /// Clawback enabled (0x8).
  ///
  /// When set, allows the issuer to clawback (burn) assets from accounts
  /// holding them. Introduced in Protocol 17 (CAP-35).
  ///
  /// Use cases:
  /// - Regulatory compliance (asset seizure)
  /// - Reversing fraudulent transactions
  /// - Enforcing legal judgments
  /// - Anti-money laundering operations
  ///
  /// Effect:
  /// - Issuer can use [ClawbackOperation] to burn assets from any account
  /// - All new trustlines are created with clawback enabled
  /// - All claimable balances are created with clawback enabled
  /// - Can only be set before any trustlines exist
  /// - Cannot be combined with AUTH_IMMUTABLE
  ///
  /// Important restrictions:
  /// - Must be set before any trustlines are created
  /// - Cannot be set if AUTH_IMMUTABLE is set
  /// - Cannot be unset once any trustlines exist
  /// - Only affects trustlines created after flag is set
  ///
  /// Example:
  /// ```dart
  /// // Enable clawback on new issuer account
  /// SetOptionsOperation enableClawback = SetOptionsOperationBuilder()
  ///   .setSetFlags(AccountFlag.AUTH_CLAWBACK_ENABLED_FLAG.value)
  ///   .build();
  ///
  /// // Later, clawback assets from an account
  /// ClawbackOperation clawback = ClawbackOperationBuilder(
  ///   asset: usdAsset,
  ///   from: accountId,
  ///   amount: "100.50"
  /// ).build();
  /// ```
  ///
  /// See also:
  /// - [ClawbackOperation] for clawing back assets
  /// - [CAP-35](https://stellar.org/protocol/cap-35) for protocol specification
  static final AUTH_CLAWBACK_ENABLED_FLAG =
      AccountFlag._internal(XdrAccountFlags.AUTH_CLAWBACK_ENABLED_FLAG.value);

  final _value;

  const AccountFlag._internal(this._value);

  toString() => 'AccountFlag.$_value';

  /// Creates an AccountFlag with the given value.
  ///
  /// Parameters:
  /// - [_value]: The flag value (bitmask)
  AccountFlag(this._value);

  get value => this._value;
}
