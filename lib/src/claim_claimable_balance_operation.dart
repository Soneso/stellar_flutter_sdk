// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'muxed_account.dart';
import 'xdr/xdr_ledger.dart';
import 'operation.dart';
import 'util.dart';
import 'xdr/xdr_operation.dart';
import 'xdr/xdr_account.dart';

/// Claims a claimable balance, transferring the funds to the claiming account.
///
/// This operation allows an account listed as a claimant to claim a claimable balance,
/// provided their claim predicate is satisfied. Upon successful claim, the balance is
/// transferred to the claimant's account and the claimable balance entry is removed
/// from the ledger. This operation was introduced in Protocol 14 via CAP-23.
///
/// Requirements:
/// - Source account must be listed as a claimant of the balance
/// - The claimant's predicate conditions must be satisfied
/// - The claimable balance must exist and not have been claimed
/// - Claimant must have a trustline if claiming a non-native asset
///
/// Claiming Process:
/// 1. Verify source account is a valid claimant
/// 2. Evaluate the claimant's predicate (time conditions, etc.)
/// 3. Transfer the asset amount to the claimant
/// 4. Remove the claimable balance entry from the ledger
/// 5. Return the base reserve to the sponsor or creator
///
/// Example - Simple Claim:
/// ```dart
/// var claimOp = ClaimClaimableBalanceOperationBuilder(
///   balanceId
/// ).setSourceAccount(recipientAccountId).build();
///
/// var transaction = TransactionBuilder(recipientAccount)
///   .addOperation(claimOp)
///   .build();
/// ```
///
/// Example - Complete Create and Claim Workflow:
/// ```dart
/// // Step 1: Create claimable balance
/// var claimant = Claimant(
///   recipientAccountId,
///   Claimant.predicateUnconditional()
/// );
///
/// var createOp = CreateClaimableBalanceOperationBuilder(
///   [claimant],
///   asset,
///   "100.0"
/// ).setSourceAccount(senderAccountId).build();
///
/// // Step 2: Get balance ID from transaction result
/// // (balanceId is returned in transaction result)
///
/// // Step 3: Recipient claims the balance
/// var claimOp = ClaimClaimableBalanceOperationBuilder(
///   balanceId
/// ).setSourceAccount(recipientAccountId).build();
/// ```
///
/// See also:
/// - [CreateClaimableBalanceOperation] to create claimable balances
/// - [Claimant] for understanding claim predicates
/// - [ClawbackClaimableBalanceOperation] for issuer clawback
/// - [CAP-23](https://github.com/stellar/stellar-protocol/blob/master/core/cap-0023.md)
/// - [Stellar Claimable Balances Documentation](https://developers.stellar.org/docs/encyclopedia/claimable-balances)
class ClaimClaimableBalanceOperation extends Operation {
  String _balanceId;

  ClaimClaimableBalanceOperation(this._balanceId);

  /// The hex-encoded ID of the claimable balance to claim.
  String get balanceId => _balanceId;

  @override
  XdrOperationBody toOperationBody() {
    XdrClaimableBalanceID bId = XdrClaimableBalanceID.forId(balanceId);
    XdrOperationBody body =
        XdrOperationBody(XdrOperationType.CLAIM_CLAIMABLE_BALANCE);
    body.claimClaimableBalanceOp = XdrClaimClaimableBalanceOp(bId);
    return body;
  }

  static ClaimClaimableBalanceOperationBuilder builder(
      XdrClaimClaimableBalanceOp op) {
    String balanceId = Util.bytesToHex(op.balanceID.v0!.hash);
    return ClaimClaimableBalanceOperationBuilder(balanceId);
  }
}

/// Builder for [ClaimClaimableBalanceOperation].
///
/// Provides a fluent interface for constructing claim operations.
///
/// Example:
/// ```dart
/// var operation = ClaimClaimableBalanceOperationBuilder(
///   balanceId
/// ).setSourceAccount(claimantAccountId).build();
/// ```
class ClaimClaimableBalanceOperationBuilder {
  String _balanceId;
  MuxedAccount? _mSourceAccount;

  /// Creates a ClaimClaimableBalanceOperationBuilder.
  ///
  /// Parameters:
  /// - [_balanceId]: The hex-encoded ID of the claimable balance to claim.
  ClaimClaimableBalanceOperationBuilder(this._balanceId);

  /// Sets the source account for this operation.
  ///
  /// The source account must be listed as a claimant of the balance.
  ///
  /// Parameters:
  /// - [sourceAccountId]: The account ID of the claimant.
  ///
  /// Returns: This builder instance for method chaining.
  ClaimClaimableBalanceOperationBuilder setSourceAccount(
      String sourceAccountId) {
    MuxedAccount? sa = MuxedAccount.fromAccountId(sourceAccountId);
    _mSourceAccount = checkNotNull(sa, "invalid sourceAccountId");
    return this;
  }

  /// Sets the muxed source account for this operation.
  ///
  /// Parameters:
  /// - [sourceAccount]: The muxed source account (claimant).
  ///
  /// Returns: This builder instance for method chaining.
  ClaimClaimableBalanceOperationBuilder setMuxedSourceAccount(
      MuxedAccount sourceAccount) {
    _mSourceAccount = sourceAccount;
    return this;
  }

  /// Builds the claim claimable balance operation.
  ///
  /// Returns: A configured [ClaimClaimableBalanceOperation] instance.
  ClaimClaimableBalanceOperation build() {
    ClaimClaimableBalanceOperation operation =
        ClaimClaimableBalanceOperation(_balanceId);
    if (_mSourceAccount != null) {
      operation.sourceAccount = _mSourceAccount;
    }
    return operation;
  }
}
