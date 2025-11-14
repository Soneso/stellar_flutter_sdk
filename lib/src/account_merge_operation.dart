// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:stellar_flutter_sdk/src/muxed_account.dart';

import 'operation.dart';
import 'util.dart';
import 'xdr/xdr_operation.dart';

/// Merges an account into another account, transferring all XLM and removing the source account.
///
/// This operation permanently deletes the source account from the ledger and transfers
/// its entire XLM balance to the destination account. This is an IRREVERSIBLE operation
/// that completely removes the account from the network.
///
/// Operation Process:
/// 1. Transfers all remaining XLM from source account to destination
/// 2. Permanently removes the source account from the ledger
/// 3. Releases the account's base reserve back to the network
/// 4. Cannot be undone - the account ID can never be used again
///
/// Critical Requirements:
/// - Source account must have exactly 0 subentries:
///   - No trustlines (remove all with ChangeTrustOperation)
///   - No open offers (cancel all with ManageOfferOperation)
///   - No data entries (remove all with ManageDataOperation)
///   - No additional signers (remove all with SetOptionsOperation)
/// - Destination account must exist and be different from source
/// - Minimum XLM balance will be transferred (at least base reserve)
///
/// Security Warnings:
/// - IRREVERSIBLE: Account deletion cannot be undone
/// - PERMANENT: Account ID can never be recreated or reused
/// - ALL XLM is transferred - ensure you intend to close the account
/// - Verify destination address carefully - typos cannot be corrected
///
/// Use Cases:
/// - **Account cleanup**: Remove unused or deprecated accounts
/// - **Key rotation**: Close old account and move to new keypair
/// - **Account consolidation**: Merge multiple accounts into one
/// - **Security**: Close compromised accounts after moving funds
/// - **Testing**: Clean up test accounts
///
/// Example - Simple Account Merge:
/// ```dart
/// var mergeOp = AccountMergeOperationBuilder(
///   destinationAccountId
/// ).setSourceAccount(sourceAccountId).build();
///
/// var transaction = TransactionBuilder(sourceAccount)
///   .addOperation(mergeOp)
///   .build();
///
/// // Source account will be permanently deleted after submission
/// ```
///
/// Example - Complete Account Closure Workflow:
/// ```dart
/// // Step 1: Remove all trustlines
/// for (var balance in account.balances) {
///   if (balance.assetType != 'native') {
///     var changeTrust = ChangeTrustOperationBuilder(
///       Asset.createNonNativeAsset(balance.assetCode, balance.assetIssuer),
///       "0"
///     ).build();
///     // Add to transaction
///   }
/// }
///
/// // Step 2: Cancel all offers
/// for (var offer in account.offers) {
///   var manageOffer = ManageOfferOperationBuilder(
///     selling,
///     buying,
///     "0",
///     price
///   ).setOfferId(offer.id).build();
///   // Add to transaction
/// }
///
/// // Step 3: Remove data entries
/// for (var entry in account.data) {
///   var manageData = ManageDataOperationBuilder(
///     entry.name,
///     null
///   ).build();
///   // Add to transaction
/// }
///
/// // Step 4: Merge account
/// var mergeOp = AccountMergeOperationBuilder(
///   destinationAccountId
/// ).build();
///
/// var transaction = TransactionBuilder(sourceAccount)
///   .addOperation(changeTrust)
///   .addOperation(manageOffer)
///   .addOperation(manageData)
///   .addOperation(mergeOp)
///   .build();
/// ```
///
/// See also:
/// - [ChangeTrustOperation] to remove trustlines before merging
/// - [ManageSellOfferOperation] and [ManageBuyOfferOperation] to cancel offers before merging
/// - [ManageDataOperation] to remove data entries before merging
/// - [SetOptionsOperation] to remove signers before merging
/// - [Stellar developer docs](https://developers.stellar.org)
class AccountMergeOperation extends Operation {
  MuxedAccount _destination;

  /// Creates an AccountMergeOperation.
  ///
  /// Parameters:
  /// - [_destination]: The account that will receive all remaining XLM from the merged account.
  AccountMergeOperation(this._destination);

  /// The account that receives the remaining XLM balance of the source account.
  MuxedAccount get destination => _destination;

  @override
  XdrOperationBody toOperationBody() {
    XdrOperationBody body =
        new XdrOperationBody(XdrOperationType.ACCOUNT_MERGE);
    body.destination = this.destination.toXdr();
    return body;
  }

  /// Creates an [AccountMergeOperationBuilder] from XDR operation body.
  ///
  /// Used for deserializing operations from XDR format.
  ///
  /// Parameters:
  /// - [op]: The XDR operation body containing the account merge data.
  ///
  /// Returns: A builder configured with the destination account from the XDR.
  static AccountMergeOperationBuilder builder(XdrOperationBody op) {
    MuxedAccount mux = MuxedAccount.fromXdr(op.destination!);
    return AccountMergeOperationBuilder.forMuxedDestinationAccount(mux);
  }
}

/// Builder for [AccountMergeOperation].
///
/// Provides a fluent interface for constructing account merge operations.
/// Remember that account merge is irreversible and permanently deletes the source account.
///
/// Example:
/// ```dart
/// var operation = AccountMergeOperationBuilder(
///   destinationAccountId
/// ).setSourceAccount(sourceAccountId).build();
/// ```
class AccountMergeOperationBuilder {
  late MuxedAccount _destination;
  MuxedAccount? _mSourceAccount;

  /// Creates an AccountMergeOperationBuilder.
  ///
  /// Parameters:
  /// - [destinationAccountId]: The account ID that will receive all XLM from the merged account.
  ///
  /// Throws: Exception if the destination account ID is invalid.
  AccountMergeOperationBuilder(String destinationAccountId) {
    MuxedAccount? dest = MuxedAccount.fromAccountId(destinationAccountId);
    this._destination = checkNotNull(dest, "invalid destination account id");
  }

  /// Creates an AccountMergeOperationBuilder for a muxed destination account.
  ///
  /// Parameters:
  /// - [_destination]: The muxed destination account.
  AccountMergeOperationBuilder.forMuxedDestinationAccount(this._destination);

  /// Sets the source account for this operation.
  ///
  /// The source account will be permanently deleted and all its XLM transferred
  /// to the destination account.
  ///
  /// Parameters:
  /// - [sourceAccountId]: The account ID to be merged and deleted.
  ///
  /// Returns: This builder instance for method chaining.
  AccountMergeOperationBuilder setSourceAccount(String sourceAccountId) {
    MuxedAccount? sa = MuxedAccount.fromAccountId(sourceAccountId);
    _mSourceAccount = checkNotNull(sa, "invalid sourceAccountId");
    return this;
  }

  /// Sets the muxed source account for this operation.
  ///
  /// Parameters:
  /// - [sourceAccount]: The muxed source account to be merged and deleted.
  ///
  /// Returns: This builder instance for method chaining.
  AccountMergeOperationBuilder setMuxedSourceAccount(
      MuxedAccount sourceAccount) {
    _mSourceAccount = sourceAccount;
    return this;
  }

  /// Builds the account merge operation.
  ///
  /// Returns: A configured [AccountMergeOperation] instance.
  AccountMergeOperation build() {
    AccountMergeOperation operation = new AccountMergeOperation(_destination);
    if (_mSourceAccount != null) {
      operation.sourceAccount = _mSourceAccount;
    }
    return operation;
  }
}
