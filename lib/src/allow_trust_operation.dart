// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'operation.dart';
import 'dart:convert';
import 'key_pair.dart';
import 'util.dart';
import 'xdr/xdr_operation.dart';
import 'xdr/xdr_account.dart';
import 'xdr/xdr_trustline.dart';
import 'xdr/xdr_asset.dart';
import 'muxed_account.dart';

/// Updates the authorized flag of an existing trustline.
///
/// **DEPRECATED**: This operation is deprecated as of Protocol 17. Use [SetTrustLineFlagsOperation]
/// instead, which provides more granular control over trustline flags and supports all current
/// authorization states.
///
/// AllowTrustOperation allows an asset issuer to authorize or revoke another account's ability
/// to hold their asset. This was the primary method for managing trustline authorization before
/// Protocol 17.
///
/// Authorization States:
/// - **Authorized**: Account can hold and transact with the asset (authorize=true)
/// - **Unauthorized**: Account cannot hold or transact with the asset (authorize=false)
/// - **Authorized to Maintain Liabilities**: Account can maintain existing positions but cannot receive new assets (authorizeToMaintainLiabilities=true)
///
/// Migration to SetTrustLineFlagsOperation:
///
/// Replace authorize=true:
/// ```dart
/// // OLD (deprecated):
/// var oldOp = AllowTrustOperationBuilder(trustorId, assetCode, 1)
///   .setSourceAccount(issuerAccountId)
///   .build();
///
/// // NEW (recommended):
/// var newOp = SetTrustLineFlagsOperationBuilder(
///   trustorId,
///   asset,
///   0,  // clearFlags: none
///   1   // setFlags: AUTHORIZED_FLAG
/// ).setSourceAccount(issuerAccountId).build();
/// ```
///
/// Replace authorize=false:
/// ```dart
/// // OLD (deprecated):
/// var oldOp = AllowTrustOperationBuilder(trustorId, assetCode, 0)
///   .setSourceAccount(issuerAccountId)
///   .build();
///
/// // NEW (recommended):
/// var newOp = SetTrustLineFlagsOperationBuilder(
///   trustorId,
///   asset,
///   1,  // clearFlags: AUTHORIZED_FLAG
///   0   // setFlags: none
/// ).setSourceAccount(issuerAccountId).build();
/// ```
///
/// Replace authorizeToMaintainLiabilities=true:
/// ```dart
/// // OLD (deprecated):
/// var oldOp = AllowTrustOperationBuilder(trustorId, assetCode, 2)
///   .setSourceAccount(issuerAccountId)
///   .build();
///
/// // NEW (recommended):
/// var newOp = SetTrustLineFlagsOperationBuilder(
///   trustorId,
///   asset,
///   1,  // clearFlags: AUTHORIZED_FLAG
///   2   // setFlags: AUTHORIZED_TO_MAINTAIN_LIABILITIES_FLAG
/// ).setSourceAccount(issuerAccountId).build();
/// ```
///
/// Limitations Compared to SetTrustLineFlagsOperation:
/// - Only works with asset codes, not full Asset objects
/// - Cannot set clawback flags
/// - Cannot set and clear flags in same operation
/// - Less explicit about which flags are being modified
///
/// See also:
/// - [SetTrustLineFlagsOperation] - Replacement operation with enhanced capabilities
/// - [ChangeTrustOperation] - To establish trustlines
/// - [Stellar developer docs](https://developers.stellar.org)
///
/// Represents  an AllowTrust operation.
/// See [Stellar developer docs](https://developers.stellar.org)
@Deprecated('Use SetTrustLineFlagsOperation instead. This operation is deprecated as of Protocol 17.')
class AllowTrustOperation extends Operation {
  String _trustor;
  String _assetCode;
  bool _authorize;
  bool _authorizeToMaintainLiabilities;

  /// Creates an AllowTrustOperation.
  ///
  /// Parameters:
  /// - [_trustor]: Account ID of the trustline holder.
  /// - [_assetCode]: Asset code (not full Asset object - limitation of this operation).
  /// - [_authorize]: If true, fully authorize the trustline.
  /// - [_authorizeToMaintainLiabilities]: If true, authorize to maintain liabilities only.
  ///
  /// Note: Only one of [_authorize] or [_authorizeToMaintainLiabilities] should be true.
  AllowTrustOperation(this._trustor, this._assetCode, this._authorize,
      this._authorizeToMaintainLiabilities);

  /// The account id of the recipient of the trustline.
  String get trustor => _trustor;

  /// The asset of the trustline the source account is authorizing. For example, if a gateway wants to allow another account to hold its USD credit, the type is USD.
  String get assetCode => _assetCode;

  /// Flag indicating whether the trustline is authorized.
  bool get authorize => _authorize;

  /// Flag indicating whether the trustline is authorized to maintain liabilities.
  bool get authorizeToMaintainLiabilities => _authorizeToMaintainLiabilities;

  /// Converts this operation to its XDR OperationBody representation.
  ///
  /// Returns: XDR OperationBody for this allow trust operation.
  @override
  XdrOperationBody toOperationBody() {
    XdrAccountID trustor =
        new XdrAccountID(KeyPair.fromAccountId(this._trustor).xdrPublicKey);
    // asset
    XdrAssetType discriminant = XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4;
    Uint8List? assetCode4;
    Uint8List? assetCode12;

    if (_assetCode.length <= 4) {
      assetCode4 =
          Util.paddedByteArray(Uint8List.fromList(utf8.encode(_assetCode)), 4);
    } else {
      discriminant = XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12;
      assetCode12 =
          Util.paddedByteArray(Uint8List.fromList(utf8.encode(_assetCode)), 12);
    }
    XdrAllowTrustOpAsset asset = new XdrAllowTrustOpAsset(discriminant);
    asset.assetCode4 = assetCode4;
    asset.assetCode12 = assetCode12;

    int xdrAuthorize = 0;
    // authorize
    if (authorize) {
      xdrAuthorize = XdrTrustLineFlags.AUTHORIZED_FLAG.value;
    } else if (authorizeToMaintainLiabilities) {
      xdrAuthorize =
          XdrTrustLineFlags.AUTHORIZED_TO_MAINTAIN_LIABILITIES_FLAG.value;
    }

    XdrAllowTrustOp op = new XdrAllowTrustOp(trustor, asset, xdrAuthorize);

    XdrOperationBody body = new XdrOperationBody(XdrOperationType.ALLOW_TRUST);
    body.allowTrustOp = op;
    return body;
  }

  /// Builds AllowTrust operation from XDR operation.
  ///
  /// Reconstructs an AllowTrustOperation from its XDR representation.
  ///
  /// Parameters:
  /// - [op]: The XDR AllowTrust operation.
  ///
  /// Returns: A builder instance for constructing the operation.
  static AllowTrustOperationBuilder builder(XdrAllowTrustOp op) {
    String assetCode;
    switch (op.asset.discriminant) {
      case XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4:
        assetCode = Util.paddedByteArrayToString(op.asset.assetCode4);
        break;
      case XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12:
        assetCode = Util.paddedByteArrayToString(op.asset.assetCode12);
        break;
      default:
        throw new Exception("Unknown asset code");
    }

    return AllowTrustOperationBuilder(
        KeyPair.fromXdrPublicKey(op.trustor.accountID).accountId,
        assetCode,
        op.authorize);
  }
}

/// Builder for [AllowTrustOperation].
///
/// **DEPRECATED**: Use [SetTrustLineFlagsOperationBuilder] instead.
///
/// Provides a fluent interface for constructing allow trust operations.
///
/// Example (deprecated - use SetTrustLineFlagsOperation instead):
/// ```dart
/// // Authorize trustline
/// var operation = AllowTrustOperationBuilder(
///   trustorId,
///   'USD',
///   1  // AUTHORIZED_FLAG
/// ).setSourceAccount(issuerAccountId).build();
/// ```
@Deprecated('Use SetTrustLineFlagsOperationBuilder instead. This operation is deprecated as of Protocol 17.')
class AllowTrustOperationBuilder {
  String _trustor;
  String _assetCode;
  int _authorize;

  MuxedAccount? _mSourceAccount;

  /// Creates an AllowTrustOperationBuilder.
  ///
  /// Parameters:
  /// - [_trustor]: Account ID of the trustline holder.
  /// - [_assetCode]: Asset code string (4 or 12 characters max).
  /// - [_authorize]: Authorization flag value (0=none, 1=authorized, 2=maintain liabilities).
  AllowTrustOperationBuilder(this._trustor, this._assetCode, this._authorize);

  /// Sets the source account for this operation.
  ///
  /// The source account must be the asset issuer.
  ///
  /// Parameters:
  /// - [sourceAccountId]: The account ID of the asset issuer.
  ///
  /// Returns: This builder instance for method chaining.
  AllowTrustOperationBuilder setSourceAccount(String sourceAccountId) {
    MuxedAccount? sa = MuxedAccount.fromAccountId(sourceAccountId);
    _mSourceAccount = checkNotNull(sa, "invalid sourceAccountId");
    return this;
  }

  /// Sets the muxed source account for this operation.
  ///
  /// Parameters:
  /// - [sourceAccount]: The muxed source account (asset issuer).
  ///
  /// Returns: This builder instance for method chaining.
  AllowTrustOperationBuilder setMuxedSourceAccount(MuxedAccount sourceAccount) {
    _mSourceAccount = sourceAccount;
    return this;
  }

  /// Builds the allow trust operation.
  ///
  /// Returns: A configured [AllowTrustOperation] instance.
  AllowTrustOperation build() {
    bool tAuthorized = _authorize == XdrTrustLineFlags.AUTHORIZED_FLAG.value;
    bool tAuthorizedToMaintain = _authorize ==
        XdrTrustLineFlags.AUTHORIZED_TO_MAINTAIN_LIABILITIES_FLAG.value;
    AllowTrustOperation operation = new AllowTrustOperation(
        _trustor, _assetCode, tAuthorized, tAuthorizedToMaintain);
    if (_mSourceAccount != null) {
      operation.sourceAccount = _mSourceAccount;
    }
    return operation;
  }
}
