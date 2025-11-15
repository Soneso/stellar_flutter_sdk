// Copyright 2021 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'operation.dart';
import 'assets.dart';
import 'util.dart';
import 'muxed_account.dart';
import 'xdr/xdr_operation.dart';
import 'xdr/xdr_type.dart';
import 'xdr/xdr_trustline.dart';

/// Claws back an amount of an asset from an account, burning it from the network.
///
/// The clawback operation allows an asset issuer to burn a specific amount of an asset
/// from a holder's account. This is a powerful regulatory compliance feature that enables
/// asset issuers to revoke assets in cases of fraud, regulatory requirements, or other
/// special circumstances. This operation was introduced in Protocol 17 via CAP-35.
///
/// Requirements:
/// - The asset must have the ASSET_CLAWBACK_ENABLED flag set on the issuer account
/// - The operation source account must be the asset issuer
/// - The from account must hold a trustline to the asset
/// - The clawed back assets are permanently burned from the network supply
///
/// Security Considerations:
/// - Clawback is an irreversible operation - assets are permanently removed
/// - This feature can be controversial as it gives issuers control over holder assets
/// - Asset holders should be aware if an asset has clawback enabled before accepting it
/// - Used for regulatory compliance (freezing stolen assets, court orders, etc.)
///
/// Example:
/// ```dart
/// // Issuer claws back 100 USD from a compromised account
/// var clawback = ClawbackOperationBuilder(
///   usdAsset,
///   "GCOMPRISED_ACCOUNT_ID",
///   "100.0"
/// ).setSourceAccount(issuerAccountId).build();
///
/// var transaction = TransactionBuilder(issuerAccount)
///   .addOperation(clawback)
///   .build();
/// ```
///
/// See also:
/// - [ClawbackOperationBuilder] for constructing clawback operations
/// - [SetTrustLineFlagsOperation] for setting ASSET_CLAWBACK_ENABLED flag
/// - [CAP-35](https://github.com/stellar/stellar-protocol/blob/master/core/cap-0035.md)
/// - [Stellar developer docs](https://developers.stellar.org)
class ClawbackOperation extends Operation {
  Asset _asset;
  MuxedAccount _from;
  String _amount;

  ClawbackOperation(this._from, this._asset, this._amount);

  /// The account from which the asset is clawed back.
  MuxedAccount get from => _from;

  /// The asset to be clawed back.
  Asset get asset => _asset;

  /// The amount of the asset to claw back, in decimal string format.
  String get amount => _amount;

  /// Converts this operation to its XDR OperationBody representation.
  ///
  /// Returns: XDR OperationBody for this clawback operation.
  @override
  XdrOperationBody toOperationBody() {
    XdrBigInt64 amount = XdrBigInt64(Util.toXdrBigInt64Amount(this.amount));
    XdrClawbackOp op = XdrClawbackOp(asset.toXdr(), this._from.toXdr(), amount);

    XdrOperationBody body = XdrOperationBody(XdrOperationType.CLAWBACK);
    body.clawbackOp = op;
    return body;
  }

  /// Builds Clawback operation.
  static ClawbackOperationBuilder builder(XdrClawbackOp op) {
    return ClawbackOperationBuilder.forMuxedFromAccount(
        Asset.fromXdr(op.asset),
        MuxedAccount.fromXdr(op.from),
        Util.fromXdrBigInt64Amount(op.amount.bigInt));
  }
}

/// Builder for [ClawbackOperation].
///
/// Provides a fluent interface for constructing clawback operations with
/// optional source account configuration.
///
/// Example:
/// ```dart
/// var operation = ClawbackOperationBuilder(
///   usdAsset,
///   "GHOLDER_ACCOUNT_ID",
///   "50.25"
/// ).setSourceAccount(issuerAccountId).build();
/// ```
class ClawbackOperationBuilder {
  Asset _asset;
  late MuxedAccount _from;
  String _amount;
  MuxedAccount? _mSourceAccount;

  /// Creates a ClawbackOperationBuilder.
  ///
  /// Parameters:
  /// - [_asset]: The asset to be clawed back.
  /// - [fromAccountId]: The account ID from which the asset will be clawed back.
  /// - [_amount]: The amount to claw back in decimal string format (e.g., "100.50").
  ClawbackOperationBuilder(this._asset, String fromAccountId, this._amount) {
    MuxedAccount? fr = MuxedAccount.fromAccountId(fromAccountId);
    this._from = checkNotNull(fr, "invalid fromAccountId");
  }

  /// Creates a ClawbackOperation builder using a MuxedAccount.
  ///
  /// Parameters:
  /// - [_asset]: The asset to be clawed back.
  /// - [_from]: MuxedAccount of the account from which the asset will be clawed back.
  /// - [_amount]: The amount to claw back in decimal string format.
  ClawbackOperationBuilder.forMuxedFromAccount(
      this._asset, this._from, this._amount);

  /// Sets the source account for this operation.
  ///
  /// The source account must be the issuer of the asset being clawed back.
  ///
  /// Parameters:
  /// - [sourceAccountId]: The account ID of the operation source (asset issuer).
  ///
  /// Returns: This builder instance for method chaining.
  ClawbackOperationBuilder setSourceAccount(String sourceAccountId) {
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
  ClawbackOperationBuilder setMuxedSourceAccount(MuxedAccount sourceAccount) {
    _mSourceAccount = sourceAccount;
    return this;
  }

  /// Builds the clawback operation.
  ///
  /// Returns: A configured [ClawbackOperation] instance.
  ClawbackOperation build() {
    ClawbackOperation operation = ClawbackOperation(_from, _asset, _amount);
    if (_mSourceAccount != null) {
      operation.sourceAccount = _mSourceAccount;
    }
    return operation;
  }
}
