// Copyright 2021 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'key_pair.dart';
import 'muxed_account.dart';
import 'operation.dart';
import 'xdr/xdr_operation.dart';
import 'xdr/xdr_account.dart';
import 'assets.dart';
import 'xdr/xdr_trustline.dart';
import 'xdr/xdr_type.dart';
import 'xdr/xdr_asset.dart';

/// Sets or clears flags on a trustline for regulatory control and asset management.
///
/// This operation allows asset issuers to set or clear specific flags on a trustline,
/// controlling how accounts can interact with their asset. This is crucial for regulatory
/// compliance and asset management. Introduced in Protocol 17 as an improvement over
/// AllowTrustOperation.
///
/// Trustline Flags:
/// - **AUTHORIZED_FLAG (1)**: Account authorized to hold and transact with asset
/// - **AUTHORIZED_TO_MAINTAIN_LIABILITIES_FLAG (2)**: Can maintain existing positions but not receive new assets
/// - **TRUSTLINE_CLAWBACK_ENABLED_FLAG (4)**: Trustline subject to clawback
///
/// Flag Operations:
/// - **setFlags**: Flags to enable on the trustline (bitwise OR)
/// - **clearFlags**: Flags to disable on the trustline (bitwise AND NOT)
/// - Can set and clear different flags in one operation
///
/// Use Cases:
/// - Authorize accounts to hold regulated assets (KYC/AML compliance)
/// - Revoke authorization for non-compliant accounts
/// - Enable clawback on specific trustlines
/// - Freeze accounts while allowing them to close positions
///
/// Example - Authorize Trustline:
/// ```dart
/// // Authorize account to hold USD asset
/// var authOp = SetTrustLineFlagsOperationBuilder(
///   trustorAccountId,
///   usdAsset,
///   0,  // clearFlags: none
///   1   // setFlags: AUTHORIZED_FLAG
/// ).setSourceAccount(issuerAccountId).build();
///
/// var transaction = TransactionBuilder(issuerAccount)
///   .addOperation(authOp)
///   .build();
/// ```
///
/// Example - Enable Clawback on Trustline:
/// ```dart
/// // Enable clawback for specific trustline
/// var clawbackOp = SetTrustLineFlagsOperationBuilder(
///   trustorAccountId,
///   asset,
///   0,  // clearFlags: none
///   4   // setFlags: TRUSTLINE_CLAWBACK_ENABLED_FLAG
/// ).setSourceAccount(issuerAccountId).build();
/// ```
///
/// Example - Freeze Account (Maintain Liabilities Only):
/// ```dart
/// // Allow account to close positions but not receive more
/// var freezeOp = SetTrustLineFlagsOperationBuilder(
///   trustorAccountId,
///   asset,
///   1,  // clearFlags: AUTHORIZED_FLAG
///   2   // setFlags: AUTHORIZED_TO_MAINTAIN_LIABILITIES_FLAG
/// ).setSourceAccount(issuerAccountId).build();
/// ```
///
/// Important Considerations:
/// - Source account must be the asset issuer
/// - Issuer account must have proper authorization flags set
/// - Cannot set clawback flag if not enabled on issuer
/// - AUTHORIZED_TO_MAINTAIN_LIABILITIES allows closing but not opening positions
/// - Used for regulatory compliance and risk management
///
/// See also:
/// - [ChangeTrustOperation] to establish trustlines
/// - [ClawbackOperation] to claw back assets
/// - [AllowTrustOperation] (deprecated, use SetTrustlineFlagsOperation instead)
/// - [Stellar developer docs](https://developers.stellar.org)
class SetTrustLineFlagsOperation extends Operation {
  String _trustorId;
  Asset _asset;
  int _clearFlags;
  int _setFlags;

  SetTrustLineFlagsOperation(
      this._trustorId, this._asset, this._clearFlags, this._setFlags);

  /// The account ID of the trustline holder (trustor).
  String get trustorId => _trustorId;

  /// The asset of the trustline.
  Asset get asset => _asset;

  /// Flags to clear (disable) on the trustline.
  int get clearFlags => _clearFlags;

  /// Flags to set (enable) on the trustline.
  int get setFlags => _setFlags;

  @override
  XdrOperationBody toOperationBody() {
    XdrAccountID accountID =
        XdrAccountID(KeyPair.fromAccountId(this.trustorId).xdrPublicKey);
    XdrAsset xdrAsset = asset.toXdr();

    XdrSetTrustLineFlagsOp op = XdrSetTrustLineFlagsOp(accountID, xdrAsset,
        new XdrUint32(this.clearFlags), new XdrUint32(this.setFlags));

    XdrOperationBody body =
        XdrOperationBody(XdrOperationType.SET_TRUST_LINE_FLAGS);
    body.setTrustLineFlagsOp = op;
    return body;
  }

  static SetTrustLineFlagsOperationBuilder builder(XdrSetTrustLineFlagsOp op) {
    String trustorId =
        KeyPair.fromXdrPublicKey(op.accountID.accountID).accountId;
    int clearFlags = op.clearFlags.uint32;
    int setFlags = op.setFlags.uint32;
    return SetTrustLineFlagsOperationBuilder(
        trustorId, Asset.fromXdr(op.asset), clearFlags, setFlags);
  }
}

/// Builder for [SetTrustLineFlagsOperation].
///
/// Provides a fluent interface for constructing trustline flag operations.
///
/// Example:
/// ```dart
/// var operation = SetTrustLineFlagsOperationBuilder(
///   trustorId,
///   asset,
///   0,  // clearFlags
///   1   // setFlags: AUTHORIZED_FLAG
/// ).setSourceAccount(issuerAccountId).build();
/// ```
class SetTrustLineFlagsOperationBuilder {
  String _trustorId;
  Asset _asset;
  int _clearFlags;
  int _setFlags;
  MuxedAccount? _mSourceAccount;

  /// Creates a SetTrustLineFlagsOperationBuilder.
  ///
  /// Parameters:
  /// - [_trustorId]: Account ID of the trustline holder.
  /// - [_asset]: The asset of the trustline.
  /// - [_clearFlags]: Flags to clear (bitwise values: 1, 2, 4).
  /// - [_setFlags]: Flags to set (bitwise values: 1, 2, 4).
  SetTrustLineFlagsOperationBuilder(
      this._trustorId, this._asset, this._clearFlags, this._setFlags);

  /// Sets the source account for this operation.
  ///
  /// The source account must be the asset issuer.
  ///
  /// Parameters:
  /// - [sourceAccountId]: The account ID of the asset issuer.
  ///
  /// Returns: This builder instance for method chaining.
  SetTrustLineFlagsOperationBuilder setSourceAccount(String sourceAccountId) {
    _mSourceAccount = MuxedAccount.fromAccountId(sourceAccountId);
    return this;
  }

  /// Sets the muxed source account for this operation.
  ///
  /// Parameters:
  /// - [sourceAccount]: The muxed source account (asset issuer).
  ///
  /// Returns: This builder instance for method chaining.
  SetTrustLineFlagsOperationBuilder setMuxedSourceAccount(
      MuxedAccount sourceAccount) {
    _mSourceAccount = sourceAccount;
    return this;
  }

  /// Builds the set trustline flags operation.
  ///
  /// Returns: A configured [SetTrustLineFlagsOperation] instance.
  SetTrustLineFlagsOperation build() {
    SetTrustLineFlagsOperation operation =
        SetTrustLineFlagsOperation(_trustorId, _asset, _clearFlags, _setFlags);
    if (_mSourceAccount != null) {
      operation.sourceAccount = _mSourceAccount;
    }
    return operation;
  }
}
