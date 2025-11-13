// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:stellar_flutter_sdk/src/muxed_account.dart';

import 'operation.dart';
import 'key_pair.dart';
import 'xdr/xdr_signing.dart';
import 'xdr/xdr_operation.dart';
import 'xdr/xdr_account.dart';
import 'xdr/xdr_type.dart';
import 'constants/stellar_protocol_constants.dart';

/// Configures account settings including flags, thresholds, signers, and account properties.
///
/// The SetOptions operation is one of the most versatile operations in Stellar, allowing
/// comprehensive account configuration. It can set account options individually or in combination,
/// enabling everything from multi-signature setups to authorization controls.
///
/// Configuration Categories:
///
/// **1. Inflation Destination**
/// - Sets the account to receive inflation payouts
/// - Note: Inflation was disabled in Protocol 12, this field is now mostly unused
///
/// **2. Account Flags** (Controls authorization and asset behavior)
/// - **AUTH_REQUIRED_FLAG (1)**: Requires authorization before accounts can hold your assets
/// - **AUTH_REVOCABLE_FLAG (2)**: Allows revoking authorization and freezing assets
/// - **AUTH_IMMUTABLE_FLAG (4)**: Prevents changing authorization flags in the future
/// - **AUTH_CLAWBACK_ENABLED_FLAG (8)**: Enables clawback functionality for issued assets
///
/// **3. Home Domain**
/// - Sets the account's home domain for federation and stellar.toml lookup
/// - Maximum 32 characters
/// - Used for account discovery and asset information
///
/// **4. Thresholds** (Multi-signature weight requirements)
/// - **Master Weight**: Weight of the account's master key (0-255)
/// - **Low Threshold**: Required weight for low-security operations (0-255)
/// - **Medium Threshold**: Required weight for medium-security operations (0-255)
/// - **High Threshold**: Required weight for high-security operations (0-255)
///
/// **5. Signers**
/// - Add or update additional signers for multi-signature
/// - Set weight to 0 to remove a signer
/// - Each signer has a weight (0-255)
/// - Combined signer weights must meet threshold requirements
///
/// Operation Threshold Levels:
/// - **Low**: AllowTrust, BumpSequence, ClaimClaimableBalance
/// - **Medium**: All other operations except SetOptions and account merge
/// - **High**: SetOptions, AccountMerge
///
/// Example - Set Account Flags (Require Authorization):
/// ```dart
/// // Require authorization for accounts to hold issued assets
/// var setAuthRequired = SetOptionsOperationBuilder()
///   .setSetFlags(1)  // AUTH_REQUIRED_FLAG
///   .setSourceAccount(issuerAccountId)
///   .build();
///
/// var transaction = TransactionBuilder(issuerAccount)
///   .addOperation(setAuthRequired)
///   .build();
/// ```
///
/// Example - Configure Multi-Signature (2-of-3):
/// ```dart
/// // Set up 2-of-3 multi-sig with master key and two signers
/// var addSigner1 = SetOptionsOperationBuilder()
///   .setSigner(signer1Key, 1)  // Add first signer with weight 1
///   .build();
///
/// var addSigner2 = SetOptionsOperationBuilder()
///   .setSigner(signer2Key, 1)  // Add second signer with weight 1
///   .build();
///
/// var setThresholds = SetOptionsOperationBuilder()
///   .setMasterKeyWeight(1)      // Master key weight 1
///   .setLowThreshold(1)         // Low requires 1
///   .setMediumThreshold(2)      // Medium requires 2
///   .setHighThreshold(2)        // High requires 2
///   .build();
///
/// // Execute all operations in one transaction
/// var transaction = TransactionBuilder(account)
///   .addOperation(addSigner1)
///   .addOperation(addSigner2)
///   .addOperation(setThresholds)
///   .build();
/// ```
///
/// Example - Set Home Domain:
/// ```dart
/// // Set home domain for federation
/// var setDomain = SetOptionsOperationBuilder()
///   .setHomeDomain('example.com')
///   .build();
/// ```
///
/// Example - Enable Clawback:
/// ```dart
/// // Enable clawback for issued assets (must be set before issuance)
/// var enableClawback = SetOptionsOperationBuilder()
///   .setSetFlags(8)  // AUTH_CLAWBACK_ENABLED_FLAG
///   .setSourceAccount(issuerAccountId)
///   .build();
/// ```
///
/// Example - Remove Signer:
/// ```dart
/// // Remove a signer by setting weight to 0
/// var removeSigner = SetOptionsOperationBuilder()
///   .setSigner(signerKey, 0)  // Weight 0 removes signer
///   .build();
/// ```
///
/// Example - Lock Account Flags (Make Immutable):
/// ```dart
/// // Prevent future flag changes by setting AUTH_IMMUTABLE_FLAG
/// var lockFlags = SetOptionsOperationBuilder()
///   .setSetFlags(4)  // AUTH_IMMUTABLE_FLAG
///   .build();
/// ```
///
/// Important Security Considerations:
/// - **Master Key Weight 0**: Disables master key (ensure other signers exist)
/// - **High Threshold > Total Weight**: Locks account permanently
/// - **AUTH_IMMUTABLE_FLAG**: Cannot be reversed, use with caution
/// - **AUTH_CLAWBACK_ENABLED**: Must be set before issuing assets
/// - Always test threshold configurations before committing
///
/// Flag Combinations:
/// - AUTH_REQUIRED + AUTH_REVOCABLE: Full control over asset holders
/// - AUTH_REQUIRED + AUTH_IMMUTABLE: Require auth but cannot revoke later
/// - AUTH_REVOCABLE + CLAWBACK: Maximum issuer control
///
/// Best Practices:
/// - Set flags before issuing assets
/// - Test multi-sig configurations on testnet first
/// - Keep backup signers when disabling master key
/// - Document threshold requirements for your team
/// - Use home domain for transparency and discoverability
///
/// See also:
/// - [SetTrustLineFlagsOperation] - Control individual trustlines
/// - [AccountMergeOperation] - Merge accounts
/// - [ManageDataOperation] - Store account data
/// - [Stellar developer docs](https://developers.stellar.org)
///
/// Represents a SetOptions operation.
class SetOptionsOperation extends Operation {
  String? _inflationDestination;
  int? _clearFlags;
  int? _setFlags;
  int? _masterKeyWeight;
  int? _lowThreshold;
  int? _mediumThreshold;
  int? _highThreshold;
  String? _homeDomain;
  XdrSignerKey? _signer;
  int? _signerWeight;

  /// Creates a SetOptionsOperation.
  ///
  /// All parameters are optional, allowing configuration of specific account options.
  ///
  /// Parameters:
  /// - [inflationDestination]: Account ID to receive inflation (mostly unused).
  /// - [clearFlags]: Flags to clear (bitwise: 1=AUTH_REQUIRED, 2=AUTH_REVOCABLE, 4=AUTH_IMMUTABLE, 8=AUTH_CLAWBACK).
  /// - [setFlags]: Flags to set (bitwise: 1=AUTH_REQUIRED, 2=AUTH_REVOCABLE, 4=AUTH_IMMUTABLE, 8=AUTH_CLAWBACK).
  /// - [masterKeyWeight]: Weight of master key (0-255, 0 disables master key).
  /// - [lowThreshold]: Weight required for low threshold operations (0-255).
  /// - [mediumThreshold]: Weight required for medium threshold operations (0-255).
  /// - [highThreshold]: Weight required for high threshold operations (0-255).
  /// - [homeDomain]: Home domain for federation lookup (max 32 chars).
  /// - [signer]: XdrSignerKey to add/update/remove.
  /// - [signerWeight]: Weight for the signer (0-255, 0 removes signer).
  SetOptionsOperation(
      String? inflationDestination,
      int? clearFlags,
      int? setFlags,
      int? masterKeyWeight,
      int? lowThreshold,
      int? mediumThreshold,
      int? highThreshold,
      String? homeDomain,
      XdrSignerKey? signer,
      int? signerWeight) {
    this._inflationDestination = inflationDestination;
    this._clearFlags = clearFlags;
    this._setFlags = setFlags;
    this._masterKeyWeight = masterKeyWeight;
    this._lowThreshold = lowThreshold;
    this._mediumThreshold = mediumThreshold;
    this._highThreshold = highThreshold;
    this._homeDomain = homeDomain;
    this._signer = signer;
    this._signerWeight = signerWeight;
  }

  /// Account ID of the inflation destination.
  ///
  /// Note: Inflation was disabled in Protocol 12.
  String? get inflationDestination => _inflationDestination;

  /// Flags to clear on the account.
  ///
  /// Bitwise values: 1=AUTH_REQUIRED, 2=AUTH_REVOCABLE, 4=AUTH_IMMUTABLE, 8=AUTH_CLAWBACK.
  int? get clearFlags => _clearFlags;

  /// Flags to set on the account.
  ///
  /// Bitwise values: 1=AUTH_REQUIRED, 2=AUTH_REVOCABLE, 4=AUTH_IMMUTABLE, 8=AUTH_CLAWBACK.
  int? get setFlags => _setFlags;

  /// Weight of the master key (0-255).
  ///
  /// Setting to 0 disables the master key. Ensure other signers exist before disabling.
  int? get masterKeyWeight => _masterKeyWeight;

  /// Weight required for low threshold operations (0-255).
  ///
  /// Low threshold operations: AllowTrust, BumpSequence, ClaimClaimableBalance.
  int? get lowThreshold => _lowThreshold;

  /// Weight required for medium threshold operations (0-255).
  ///
  /// Medium threshold operations: All operations except SetOptions and AccountMerge.
  int? get mediumThreshold => _mediumThreshold;

  /// Weight required for high threshold operations (0-255).
  ///
  /// High threshold operations: SetOptions, AccountMerge.
  int? get highThreshold => _highThreshold;

  /// The home domain of the account.
  ///
  /// Used for federation lookup and stellar.toml file. Maximum 32 characters.
  String? get homeDomain => _homeDomain;

  /// Signer to add, update, or remove.
  ///
  /// Use with signerWeight to manage account signers.
  XdrSignerKey? get signer => _signer;

  /// Weight for the signer (0-255).
  ///
  /// Set to 0 to remove the signer from the account.
  int? get signerWeight => _signerWeight;

  @override
  XdrOperationBody toOperationBody() {
    XdrSetOptionsOp op = new XdrSetOptionsOp();
    if (inflationDestination != null) {
      op.inflationDest = new XdrAccountID(
          KeyPair.fromAccountId(this.inflationDestination!).xdrPublicKey);
    }
    if (clearFlags != null) {
      op.clearFlags = new XdrUint32(this.clearFlags!);
    }
    if (setFlags != null) {
      op.setFlags = new XdrUint32(this.setFlags!);
    }
    if (masterKeyWeight != null) {
      op.masterWeight = new XdrUint32(masterKeyWeight!);
    }
    if (lowThreshold != null) {
      op.lowThreshold = new XdrUint32(lowThreshold!);
    }
    if (mediumThreshold != null) {
      op.medThreshold = new XdrUint32(mediumThreshold!);
    }
    if (highThreshold != null) {
      op.highThreshold = new XdrUint32(highThreshold!);
    }
    if (homeDomain != null) {
      op.homeDomain = new XdrString32(this.homeDomain!);
    }
    if (signer != null) {

      XdrUint32 weight = new XdrUint32(signerWeight! & 0xFF);
      op.signer = new XdrSigner(this.signer!, weight);
    }

    XdrOperationBody body = new XdrOperationBody(XdrOperationType.SET_OPTIONS);
    body.setOptionsOp = op;
    return body;
  }

  /// Builds SetOptions operation from XDR operation.
  ///
  /// Reconstructs a SetOptionsOperation from its XDR representation.
  ///
  /// Parameters:
  /// - [op]: The XDR SetOptions operation.
  ///
  /// Returns: A builder instance for constructing the operation.
  static SetOptionsOperationBuilder builder(XdrSetOptionsOp op) {
    SetOptionsOperationBuilder builder = SetOptionsOperationBuilder();

    if (op.inflationDest != null) {
      builder = builder.setInflationDestination(
          KeyPair.fromXdrPublicKey(op.inflationDest!.accountID).accountId);
    }
    if (op.clearFlags != null) {
      builder = builder.setClearFlags(op.clearFlags!.uint32);
    }
    if (op.setFlags != null) {
      builder = builder.setSetFlags(op.setFlags!.uint32);
    }
    if (op.masterWeight != null) {
      builder = builder.setMasterKeyWeight(op.masterWeight!.uint32);
    }
    if (op.lowThreshold != null) {
      builder = builder.setLowThreshold(op.lowThreshold!.uint32);
    }
    if (op.medThreshold != null) {
      builder = builder.setMediumThreshold(op.medThreshold!.uint32);
    }
    if (op.highThreshold != null) {
      builder = builder.setHighThreshold(op.highThreshold!.uint32);
    }
    if (op.homeDomain != null) {
      builder = builder.setHomeDomain(op.homeDomain!.string32);
    }
    if (op.signer != null) {
      builder =
          builder.setSigner(op.signer!.key, op.signer!.weight.uint32 & 0xFF);
    }

    return builder;
  }
}

/// Builder for [SetOptionsOperation].
///
/// Provides a fluent interface for configuring account options. All settings are optional,
/// allowing you to configure only what you need to change.
///
/// Example:
/// ```dart
/// var operation = SetOptionsOperationBuilder()
///   .setSetFlags(1)  // AUTH_REQUIRED_FLAG
///   .setHomeDomain('example.com')
///   .setSourceAccount(accountId)
///   .build();
/// ```
class SetOptionsOperationBuilder {
  String? _inflationDestination;
  int? _clearFlags;
  int? _setFlags;
  int? _masterKeyWeight;
  int? _lowThreshold;
  int? _mediumThreshold;
  int? _highThreshold;
  String? _homeDomain;
  XdrSignerKey? _signer;
  int? _signerWeight;
  MuxedAccount? _sourceAccount;

  /// Creates a SetOptionsOperationBuilder.
  ///
  /// All configuration is done through builder methods before calling build().
  SetOptionsOperationBuilder();

  /// Sets the inflation destination for the account.
  ///
  /// Note: Inflation was disabled in Protocol 12, this is mostly unused.
  ///
  /// Parameters:
  /// - [inflationDestination]: Account ID to receive inflation.
  ///
  /// Returns: This builder instance for method chaining.
  SetOptionsOperationBuilder setInflationDestination(
      String inflationDestination) {
    this._inflationDestination = inflationDestination;
    return this;
  }

  /// Clears the specified flags from the account.
  ///
  /// Use this to disable previously set authorization flags.
  ///
  /// Parameters:
  /// - [clearFlags]: Bitwise flags to clear (1=AUTH_REQUIRED, 2=AUTH_REVOCABLE, 4=AUTH_IMMUTABLE, 8=AUTH_CLAWBACK).
  ///
  /// Returns: This builder instance for method chaining.
  SetOptionsOperationBuilder setClearFlags(int clearFlags) {
    this._clearFlags = clearFlags;
    return this;
  }

  /// Sets the specified flags on the account.
  ///
  /// Use this to enable authorization flags for asset control.
  ///
  /// Parameters:
  /// - [setFlags]: Bitwise flags to set (1=AUTH_REQUIRED, 2=AUTH_REVOCABLE, 4=AUTH_IMMUTABLE, 8=AUTH_CLAWBACK).
  ///
  /// Returns: This builder instance for method chaining.
  ///
  /// Example:
  /// ```dart
  /// .setSetFlags(1)  // Require authorization
  /// .setSetFlags(3)  // Require authorization + allow revocable (1 + 2)
  /// ```
  SetOptionsOperationBuilder setSetFlags(int setFlags) {
    this._setFlags = setFlags;
    return this;
  }

  /// Sets the weight of the master key (0-255).
  ///
  /// Setting to 0 disables the master key. Ensure other signers exist before disabling.
  ///
  /// Parameters:
  /// - [masterKeyWeight]: Weight value (0-255).
  ///
  /// Returns: This builder instance for method chaining.
  SetOptionsOperationBuilder setMasterKeyWeight(int masterKeyWeight) {
    this._masterKeyWeight = masterKeyWeight;
    return this;
  }

  /// Sets the low threshold for operations (0-255).
  ///
  /// Low threshold operations: AllowTrust, BumpSequence, ClaimClaimableBalance.
  ///
  /// Parameters:
  /// - [lowThreshold]: Required weight for low threshold operations (0-255).
  ///
  /// Returns: This builder instance for method chaining.
  SetOptionsOperationBuilder setLowThreshold(int lowThreshold) {
    this._lowThreshold = lowThreshold;
    return this;
  }

  /// Sets the medium threshold for operations (0-255).
  ///
  /// Medium threshold operations: All operations except SetOptions and AccountMerge.
  ///
  /// Parameters:
  /// - [mediumThreshold]: Required weight for medium threshold operations (0-255).
  ///
  /// Returns: This builder instance for method chaining.
  SetOptionsOperationBuilder setMediumThreshold(int mediumThreshold) {
    this._mediumThreshold = mediumThreshold;
    return this;
  }

  /// Sets the high threshold for operations (0-255).
  ///
  /// High threshold operations: SetOptions, AccountMerge.
  ///
  /// Parameters:
  /// - [highThreshold]: Required weight for high threshold operations (0-255).
  ///
  /// Returns: This builder instance for method chaining.
  SetOptionsOperationBuilder setHighThreshold(int highThreshold) {
    this._highThreshold = highThreshold;
    return this;
  }

  /// Sets the account's home domain.
  ///
  /// Home domain is used for federation lookup and stellar.toml file discovery.
  /// Maximum 32 characters.
  ///
  /// Parameters:
  /// - [homeDomain]: Domain name (e.g., 'example.com').
  ///
  /// Returns: This builder instance for method chaining.
  ///
  /// Throws: Exception if domain exceeds 32 characters.
  SetOptionsOperationBuilder setHomeDomain(String homeDomain) {
    if (homeDomain.length > StellarProtocolConstants.HOME_DOMAIN_MAX_LENGTH) {
      throw new Exception("Home domain must be <= ${StellarProtocolConstants.HOME_DOMAIN_MAX_LENGTH} characters");
    }
    this._homeDomain = homeDomain;
    return this;
  }

  /// Adds, updates, or removes a signer from the account.
  ///
  /// Set weight to 0 to remove a signer. Multiple signers enable multi-signature schemes.
  ///
  /// Parameters:
  /// - [signer]: XdrSignerKey representing the signer.
  /// - [weight]: Weight of the signer (0-255). 0 removes the signer.
  ///
  /// Returns: This builder instance for method chaining.
  ///
  /// Example:
  /// ```dart
  /// // Add signer with weight 1
  /// .setSigner(signerKey, 1)
  ///
  /// // Remove signer
  /// .setSigner(signerKey, 0)
  /// ```
  SetOptionsOperationBuilder setSigner(XdrSignerKey signer, int weight) {
    this._signer = signer;
    _signerWeight = weight & 0xFF;
    return this;
  }

  /// Sets the source account for this operation.
  ///
  /// Parameters:
  /// - [sourceAccountId]: The account ID that will perform this operation.
  ///
  /// Returns: This builder instance for method chaining.
  SetOptionsOperationBuilder setSourceAccount(String sourceAccountId) {
    _sourceAccount = MuxedAccount.fromAccountId(sourceAccountId);
    return this;
  }

  /// Sets the muxed source account for this operation.
  ///
  /// Parameters:
  /// - [sourceAccount]: The muxed source account.
  ///
  /// Returns: This builder instance for method chaining.
  SetOptionsOperationBuilder setMuxedSourceAccount(MuxedAccount sourceAccount) {
    _sourceAccount = sourceAccount;
    return this;
  }

  /// Builds the set options operation.
  ///
  /// Returns: A configured [SetOptionsOperation] instance.
  SetOptionsOperation build() {
    SetOptionsOperation operation = new SetOptionsOperation(
        _inflationDestination,
        _clearFlags,
        _setFlags,
        _masterKeyWeight,
        _lowThreshold,
        _mediumThreshold,
        _highThreshold,
        _homeDomain,
        _signer,
        _signerWeight);
    if (_sourceAccount != null) {
      operation.sourceAccount = _sourceAccount;
    }
    return operation;
  }
}
