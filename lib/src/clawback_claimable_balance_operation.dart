// Copyright 2021 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'muxed_account.dart';
import 'xdr/xdr_ledger.dart';
import 'operation.dart';
import 'util.dart';
import 'xdr/xdr_operation.dart';
import 'xdr/xdr_account.dart';

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
/// - [Stellar Clawback Documentation](https://developers.stellar.org/docs/encyclopedia/clawback)
class ClawbackClaimableBalanceOperation extends Operation {
  String _balanceId;

  ClawbackClaimableBalanceOperation(this._balanceId);

  /// The hex-encoded ID of the claimable balance to claw back.
  String get balanceId => _balanceId;

  @override
  XdrOperationBody toOperationBody() {
    XdrClaimableBalanceID bId = XdrClaimableBalanceID.forId(balanceId);
    XdrOperationBody body =
        XdrOperationBody(XdrOperationType.CLAWBACK_CLAIMABLE_BALANCE);
    body.clawbackClaimableBalanceOp = XdrClawbackClaimableBalanceOp(bId);
    return body;
  }

  static ClawbackClaimableBalanceOperationBuilder builder(
      XdrClawbackClaimableBalanceOp op) {
    String balanceId = Util.bytesToHex(op.balanceID.v0!.hash);
    return ClawbackClaimableBalanceOperationBuilder(balanceId);
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
class ClawbackClaimableBalanceOperationBuilder {
  String _balanceId;
  MuxedAccount? _mSourceAccount;

  /// Creates a ClawbackClaimableBalanceOperationBuilder.
  ///
  /// Parameters:
  /// - [_balanceId]: The hex-encoded claimable balance ID to claw back.
  ClawbackClaimableBalanceOperationBuilder(this._balanceId);

  /// Sets the source account for this operation.
  ///
  /// The source account must be the issuer of the asset in the claimable balance.
  ///
  /// Parameters:
  /// - [sourceAccountId]: The account ID of the asset issuer.
  ///
  /// Returns: This builder instance for method chaining.
  ClawbackClaimableBalanceOperationBuilder setSourceAccount(
      String sourceAccountId) {
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
  ClawbackClaimableBalanceOperationBuilder setMuxedSourceAccount(
      MuxedAccount sourceAccount) {
    _mSourceAccount = sourceAccount;
    return this;
  }

  /// Builds the clawback claimable balance operation.
  ///
  /// Returns: A configured [ClawbackClaimableBalanceOperation] instance.
  ClawbackClaimableBalanceOperation build() {
    ClawbackClaimableBalanceOperation operation =
        ClawbackClaimableBalanceOperation(_balanceId);
    if (_mSourceAccount != null) {
      operation.sourceAccount = _mSourceAccount;
    }
    return operation;
  }
}
