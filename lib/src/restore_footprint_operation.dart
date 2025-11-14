// Copyright 2023 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'muxed_account.dart';
import 'operation.dart';
import 'util.dart';
import 'xdr/xdr_operation.dart';
import 'xdr/xdr_account.dart';
import 'xdr/xdr_contract.dart';

/// Restores archived Soroban contract state entries back to active storage.
///
/// This operation restores ledger entries that have been archived due to TTL
/// expiration. Soroban uses a tiered storage model where unused contract data
/// is archived to reduce ledger size. This operation brings archived entries
/// back to active storage, making them accessible again.
///
/// Soroban State Archival:
/// - **Active storage**: Immediately accessible, has TTL (time-to-live)
/// - **Archived storage**: Cheaper storage, must be restored before use
/// - **TTL expiration**: Entries move to archive when TTL reaches zero
/// - **Restoration**: Returns entries to active storage with new TTL
///
/// Use Cases:
/// - Restore contract data that was archived
/// - Reactivate dormant contracts
/// - Prepare archived state for contract invocation
/// - Recover expired contract instances
///
/// Requirements:
/// - Transaction must include correct footprint (SorobanTransactionData)
/// - Footprint specifies which entries to restore
/// - Must pay fees for restoration (based on entry size)
/// - Entries must exist in archived state
///
/// Example - Restore Archived Contract Data:
/// ```dart
/// // Build footprint with archived entries to restore
/// var footprint = SorobanTransactionData(
///   resources: SorobanResources(
///     footprint: LedgerFootprint(
///       readWrite: archivedLedgerKeys
///     ),
///     readBytes: calculatedReadBytes,
///     writeBytes: calculatedWriteBytes
///   )
/// );
///
/// var restoreOp = RestoreFootprintOperationBuilder()
///   .setSourceAccount(accountId)
///   .build();
///
/// var transaction = TransactionBuilder(account)
///   .addOperation(restoreOp)
///   .setSorobanData(footprint)
///   .build();
/// ```
///
/// Important Considerations:
/// - Restoration costs depend on entry size
/// - Restored entries start with minimum TTL
/// - Use ExtendFootprintTTL to extend TTL after restoration
/// - Footprint must accurately specify archived entries
/// - Operation fails if entries don't exist or aren't archived
///
/// See also:
/// - [ExtendFootprintTTLOperation] to extend entry TTLs
/// - [InvokeHostFunctionOperation] for contract invocation
/// - [Soroban State Archival Documentation](https://developers.stellar.org/docs/learn/fundamentals/contract-development/storage/state-archival)
class RestoreFootprintOperation extends Operation {
  /// Creates a RestoreFootprintOperation.
  ///
  /// The operation has no parameters - restoration targets are specified
  /// in the transaction's Soroban footprint.
  RestoreFootprintOperation();

  /// Converts this operation to its XDR representation.
  ///
  /// Returns: XDR operation body for the footprint restoration.
  @override
  XdrOperationBody toOperationBody() {
    XdrOperationBody body =
        XdrOperationBody(XdrOperationType.RESTORE_FOOTPRINT);
    body.restoreFootprintOp = XdrRestoreFootprintOp(XdrExtensionPoint(0));
    return body;
  }

  /// Creates a builder from an XDR restore footprint operation.
  ///
  /// Parameters:
  /// - [op]: XDR restore footprint operation.
  ///
  /// Returns: Builder initialized with operation parameters.
  static RestoreFootprintOperationBuilder builder(XdrRestoreFootprintOp op) {
    return RestoreFootprintOperationBuilder();
  }
}

/// Builder for [RestoreFootprintOperation].
///
/// Provides a fluent interface for constructing state restoration operations.
///
/// Example:
/// ```dart
/// var operation = RestoreFootprintOperationBuilder()
///   .setSourceAccount(accountId)
///   .build();
/// ```
class RestoreFootprintOperationBuilder {
  MuxedAccount? _mSourceAccount;

  /// Creates a RestoreFootprintOperationBuilder.
  ///
  /// The operation requires no parameters - archived entries are specified
  /// in the transaction's Soroban footprint.
  RestoreFootprintOperationBuilder();

  /// Sets the source account for this operation.
  ///
  /// Parameters:
  /// - [sourceAccountId]: The account ID that will pay for restoration.
  ///
  /// Returns: This builder instance for method chaining.
  RestoreFootprintOperationBuilder setSourceAccount(String sourceAccountId) {
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
  RestoreFootprintOperationBuilder setMuxedSourceAccount(
      MuxedAccount sourceAccount) {
    _mSourceAccount = sourceAccount;
    return this;
  }

  /// Builds the restore footprint operation.
  ///
  /// Returns: A configured [RestoreFootprintOperation] instance.
  RestoreFootprintOperation build() {
    RestoreFootprintOperation operation = RestoreFootprintOperation();
    if (_mSourceAccount != null) {
      operation.sourceAccount = _mSourceAccount;
    }
    return operation;
  }
}
