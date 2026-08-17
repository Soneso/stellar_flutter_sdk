// Copyright 2021 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr/xdr.dart';
import 'operation.dart';

/// Claws back a claimable balance, removing it from the network.
///
/// This operation allows an asset issuer to reclaim and burn an unclaimed claimable
/// balance created with their asset. This is part of the clawback feature introduced
/// in Protocol 17 via CAP-35, extending clawback functionality to claimable balances.
///
/// Requirements:
/// - The asset must have the ASSET_CLAWBACK_ENABLED flag set
/// - The operation source account must be the asset issuer
/// - The claimable balance must exist and contain the issuer's asset
/// - The balance is permanently burned from the network supply
///
/// Use Cases:
/// - Remove unclaimed fraudulent payments
/// - Comply with legal requirements for asset recovery
/// - Clean up erroneous claimable balances
/// - Enforce regulatory compliance on pending transfers
///
/// Example:
/// ```dart
/// // Issuer claws back an unclaimed fraudulent payment
/// var clawback = ClawbackClaimableBalanceOperationBuilder(
///   "00000000da0d57da7d4850e7fc10d2a9d0ebc731f7afb40574c03395b17d49149b91f5be"
/// ).setSourceAccount(issuerAccountId).build();
///
/// var transaction = TransactionBuilder(issuerAccount)
///   .addOperation(clawback)
///   .build();
/// ```
///
/// See also:
/// - [ClawbackOperation] for clawing back assets from accounts
/// - [CreateClaimableBalanceOperation] for creating claimable balances
/// - [CAP-35](https://github.com/stellar/stellar-protocol/blob/master/core/cap-0035.md)
/// - [Stellar developer docs](https://developers.stellar.org)
class ClawbackClaimableBalanceOperation extends Operation {
  String _balanceId;

  /// Creates a ClawbackClaimableBalanceOperation for clawing back a claimable balance.
  ///
  /// This constructor creates an operation that allows an asset issuer to claw back
  /// an unclaimed claimable balance. The claimable balance must contain an asset that
  /// has the ASSET_CLAWBACK_ENABLED flag set, and the operation must be executed by
  /// the asset issuer.
  ///
  /// Parameters:
  /// - [_balanceId] The hex-encoded ID of the claimable balance to claw back
  ClawbackClaimableBalanceOperation(this._balanceId);

  /// The ID of the claimable balance to claw back.
  ///
  /// An operation read from XDR reports the 72-character form Horizon serves:
  /// the four-byte big-endian union discriminant ahead of the 32-byte hash. An
  /// operation built from a string reports that string as given.
  String get balanceId => _balanceId;

  /// Converts this operation to its XDR OperationBody representation.
  ///
  /// Returns: XDR OperationBody for this clawback claimable balance operation.
  @override
  XdrOperationBody toOperationBody() {
    XdrClaimableBalanceID bId = XdrClaimableBalanceID.forId(balanceId);
    XdrOperationBody body =
        XdrOperationBody(XdrOperationType.CLAWBACK_CLAIMABLE_BALANCE);
    body.clawbackClaimableBalanceOp = XdrClawbackClaimableBalanceOp(bId);
    return body;
  }

  /// Creates a [ClawbackClaimableBalanceOperationBuilder] from XDR operation.
  ///
  /// Used for deserializing operations from XDR format.
  ///
  /// Parameters:
  /// - [op] The XDR clawback claimable balance operation data.
  ///
  /// Returns: A builder configured with the balance ID from the XDR.
  static ClawbackClaimableBalanceOperationBuilder builder(
      XdrClawbackClaimableBalanceOp op) {
    return ClawbackClaimableBalanceOperationBuilder(
        op.balanceID.paddedBalanceIdHex);
  }
}

/// Builder for [ClawbackClaimableBalanceOperation].
///
/// Provides a fluent interface for constructing claimable balance clawback operations.
///
/// Example:
/// ```dart
/// var operation = ClawbackClaimableBalanceOperationBuilder(
///   balanceId
/// ).setSourceAccount(issuerAccountId).build();
/// ```
class ClawbackClaimableBalanceOperationBuilder
    extends OperationBuilder<ClawbackClaimableBalanceOperationBuilder> {
  String _balanceId;

  /// Creates a ClawbackClaimableBalanceOperationBuilder.
  ///
  /// Parameters:
  /// - [_balanceId] The hex-encoded claimable balance ID to claw back.
  ClawbackClaimableBalanceOperationBuilder(this._balanceId);

  /// Builds the clawback claimable balance operation.
  ///
  /// Returns: A configured [ClawbackClaimableBalanceOperation] instance.
  ClawbackClaimableBalanceOperation build() {
    ClawbackClaimableBalanceOperation operation =
        ClawbackClaimableBalanceOperation(_balanceId);
    return applySourceAccount(operation);
  }
}
