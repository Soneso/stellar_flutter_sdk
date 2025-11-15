// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:stellar_flutter_sdk/src/muxed_account.dart';
import 'package:stellar_flutter_sdk/src/xdr/xdr_ledger.dart';

import 'operation.dart';
import 'util.dart';
import 'xdr/xdr_operation.dart';
import 'xdr/xdr_account.dart';
import 'xdr/xdr_type.dart';
import 'claimant.dart';
import 'assets.dart';

/// Creates a claimable balance entry that can be claimed by specified accounts.
///
/// A claimable balance is an on-ledger entry that holds an asset amount until one
/// of the specified claimants claims it. Each claimant can have conditions (predicates)
/// that must be satisfied before they can claim. This operation was introduced in
/// Protocol 14 via CAP-23.
///
/// Use Cases:
/// - **Conditional payments**: Send payment that recipient claims when ready
/// - **Escrow**: Hold funds until time or condition is met
/// - **Airdrops**: Distribute tokens that users can claim
/// - **Refunds**: Create refundable payments with time limits
/// - **Multi-party agreements**: Payments claimable by any of several parties
///
/// Claimable Balance Features:
/// - Created by source account, deducting the amount immediately
/// - Stored on-ledger as a separate entry (requires base reserve)
/// - Can have multiple claimants with different predicates
/// - Claimant can be any account (doesn't need to exist yet)
/// - If never claimed, issuer can claw back (if clawback enabled)
///
/// Example - Simple Unconditional Payment:
/// ```dart
/// var claimant = Claimant(
///   recipientAccountId,
///   Claimant.predicateUnconditional()
/// );
///
/// var createBalance = CreateClaimableBalanceOperationBuilder(
///   [claimant],
///   usdAsset,
///   "100.0"
/// ).setSourceAccount(senderAccountId).build();
///
/// var transaction = TransactionBuilder(senderAccount)
///   .addOperation(createBalance)
///   .build();
/// ```
///
/// Example - Time-locked Payment:
/// ```dart
/// // Recipient can claim after 24 hours
/// var unlockTime = DateTime.now().add(Duration(hours: 24)).millisecondsSinceEpoch ~/ 1000;
/// var claimant = Claimant(
///   recipientAccountId,
///   Claimant.predicateNot(
///     Claimant.predicateBeforeAbsoluteTime(unlockTime)
///   )
/// );
///
/// var createBalance = CreateClaimableBalanceOperationBuilder(
///   [claimant],
///   asset,
///   "50.0"
/// ).build();
/// ```
///
/// Example - Multiple Claimants (Either Can Claim):
/// ```dart
/// var claimants = [
///   Claimant(accountA, Claimant.predicateUnconditional()),
///   Claimant(accountB, Claimant.predicateUnconditional())
/// ];
///
/// var createBalance = CreateClaimableBalanceOperationBuilder(
///   claimants,
///   asset,
///   "75.0"
/// ).build();
/// ```
///
/// See also:
/// - [Claimant] for creating claimants with predicates
/// - [ClaimClaimableBalanceOperation] to claim the balance
/// - [ClawbackClaimableBalanceOperation] for issuer clawback
/// - [CAP-23](https://github.com/stellar/stellar-protocol/blob/master/core/cap-0023.md)
/// - [Stellar developer docs](https://developers.stellar.org)
class CreateClaimableBalanceOperation extends Operation {
  List<Claimant> _claimants;
  Asset _asset;
  String _amount;

  /// Creates a CreateClaimableBalanceOperation.
  ///
  /// Parameters:
  /// - [_claimants] List of claimants who can claim the balance.
  /// - [_asset] The asset of the claimable balance.
  /// - [_amount] The amount in decimal string format (e.g., "100.50").
  CreateClaimableBalanceOperation(this._claimants, this._asset, this._amount);

  /// The list of claimants who can claim this balance.
  List<Claimant> get claimants => _claimants;

  /// The asset of the claimable balance.
  Asset get asset => _asset;

  /// The amount of the claimable balance in decimal string format.
  String get amount => _amount;

  /// Converts this operation to its XDR OperationBody representation.
  ///
  /// Returns: XDR OperationBody for this create claimable balance operation.
  @override
  XdrOperationBody toOperationBody() {
    List<XdrClaimant> xdrClaimants = List<XdrClaimant>.empty(growable: true);
    for (int i = 0; i < this.claimants.length; i++) {
      xdrClaimants.add(this.claimants[i].toXdr());
    }

    XdrBigInt64 amount = XdrBigInt64(Util.toXdrBigInt64Amount(this.amount));
    XdrCreateClaimableBalanceOp op =
        XdrCreateClaimableBalanceOp(this.asset.toXdr(), amount, xdrClaimants);

    XdrOperationBody body =
        XdrOperationBody(XdrOperationType.CREATE_CLAIMABLE_BALANCE);
    body.createClaimableBalanceOp = op;
    return body;
  }

  /// Creates a [CreateClaimableBalanceOperationBuilder] from XDR operation.
  ///
  /// Used for deserializing operations from XDR format.
  ///
  /// Parameters:
  /// - [op] The XDR create claimable balance operation data.
  ///
  /// Returns: A builder configured with claimants, asset, and amount from the XDR.
  static CreateClaimableBalanceOperationBuilder builder(
      XdrCreateClaimableBalanceOp op) {
    List<Claimant> claimants = List<Claimant>.empty(growable: true);
    for (int i = 0; i < op.claimants.length; i++) {
      claimants.add(Claimant.fromXdr(op.claimants[i]));
    }
    Asset asset = Asset.fromXdr(op.asset);
    String amount = Util.fromXdrBigInt64Amount(op.amount.bigInt);

    return CreateClaimableBalanceOperationBuilder(claimants, asset, amount);
  }
}

/// Builder for [CreateClaimableBalanceOperation].
///
/// Provides a fluent interface for constructing claimable balance creation operations.
///
/// Example:
/// ```dart
/// var operation = CreateClaimableBalanceOperationBuilder(
///   claimants,
///   asset,
///   "100.0"
/// ).setSourceAccount(sourceAccountId).build();
/// ```
class CreateClaimableBalanceOperationBuilder {
  List<Claimant> _claimants;
  Asset _asset;
  String _amount;
  MuxedAccount? _mSourceAccount;

  /// Creates a CreateClaimableBalanceOperationBuilder.
  ///
  /// Parameters:
  /// - [_claimants] List of claimants who can claim the balance.
  /// - [_asset] The asset of the claimable balance.
  /// - [_amount] The amount in decimal string format (e.g., "100.50").
  CreateClaimableBalanceOperationBuilder(
      this._claimants, this._asset, this._amount);

  /// Sets the source account for this operation.
  ///
  /// The source account will fund the claimable balance.
  ///
  /// Parameters:
  /// - [sourceAccountId]: The account ID that will create and fund the balance.
  ///
  /// Returns: This builder instance for method chaining.
  CreateClaimableBalanceOperationBuilder setSourceAccount(
      String sourceAccountId) {
    MuxedAccount? sa = MuxedAccount.fromAccountId(sourceAccountId);
    _mSourceAccount = checkNotNull(sa, "invalid sourceAccountId");
    return this;
  }

  /// Sets the muxed source account for this operation.
  ///
  /// Parameters:
  /// - [sourceAccount]: The muxed source account.
  ///
  /// Returns: This builder instance for method chaining.
  CreateClaimableBalanceOperationBuilder setMuxedSourceAccount(
      MuxedAccount sourceAccount) {
    _mSourceAccount = sourceAccount;
    return this;
  }

  /// Builds the create claimable balance operation.
  ///
  /// Returns: A configured [CreateClaimableBalanceOperation] instance.
  CreateClaimableBalanceOperation build() {
    CreateClaimableBalanceOperation operation =
        CreateClaimableBalanceOperation(_claimants, _asset, _amount);
    if (_mSourceAccount != null) {
      operation.sourceAccount = _mSourceAccount;
    }
    return operation;
  }
}
