// Copyright 2023 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:stellar_flutter_sdk/src/xdr/xdr_type.dart';

import 'muxed_account.dart';
import 'operation.dart';
import 'util.dart';
import 'xdr/xdr_operation.dart';
import 'xdr/xdr_account.dart';
import 'xdr/xdr_contract.dart';

/// Extends the time-to-live (TTL) of Soroban contract state entries.
///
/// This operation extends the TTL of active contract data entries, preventing them
/// from being archived. Soroban uses TTL-based state archival to manage ledger size.
/// Entries with expired TTLs are moved to cheaper archived storage. This operation
/// extends TTLs to keep entries in active, immediately accessible storage.
///
/// Soroban TTL Management:
/// - **TTL**: Number of ledgers until entry is archived
/// - **Minimum TTL**: Protocol-defined minimum value (varies by entry type)
/// - **Maximum TTL**: Upper bound on TTL extension
/// - **Cost**: Fees based on entry size and extension duration
///
/// TTL Extension Strategy:
/// - Extend frequently accessed data to avoid restoration costs
/// - Balance extension costs vs restoration costs
/// - Consider access patterns and data importance
/// - Monitor TTLs and extend before expiration
///
/// Parameters:
/// - **extendTo**: Number of ledgers to extend the TTL to (not by)
///
/// Use Cases:
/// - Prevent important contract data from archival
/// - Maintain active state for frequently used contracts
/// - Extend TTL after restoring archived entries
/// - Ensure contract availability during critical periods
///
/// Example - Extend Contract Data TTL:
/// ```dart
/// // Extend TTL to 100,000 ledgers (approximately 6 days)
/// var extendOp = ExtendFootprintTTLOperationBuilder(100000)
///   .setSourceAccount(accountId)
///   .build();
///
/// // Include footprint specifying which entries to extend
/// var footprint = SorobanTransactionData(
///   resources: SorobanResources(
///     footprint: LedgerFootprint(
///       readOnly: ledgerKeysToExtend
///     )
///   )
/// );
///
/// var transaction = TransactionBuilder(account)
///   .addOperation(extendOp)
///   .setSorobanData(footprint)
///   .build();
/// ```
///
/// Important Considerations:
/// - Extension cost increases with duration and entry size
/// - Cannot extend beyond maximum TTL
/// - Footprint must specify entries to extend
/// - Consider periodic extensions for critical data
/// - Batch extensions when possible to save fees
///
/// See also:
/// - [RestoreFootprintOperation] to restore archived entries
/// - [InvokeHostFunctionOperation] for contract invocation
/// - [Soroban State Archival Documentation](https://developers.stellar.org/docs/learn/encyclopedia/storage/state-archival)
class ExtendFootprintTTLOperation extends Operation {
  int _extendTo;

  /// The number of ledgers to extend the TTL to.
  int get extendTo => _extendTo;

  /// Creates an ExtendFootprintTTLOperation.
  ///
  /// Parameters:
  /// - [_extendTo] Number of ledgers to extend TTL to (absolute value, not increment).
  ExtendFootprintTTLOperation(this._extendTo);

  /// Converts this operation to its XDR representation.
  ///
  /// Returns: XDR operation body for the footprint TTL extension.
  @override
  XdrOperationBody toOperationBody() {
    XdrOperationBody body =
        XdrOperationBody(XdrOperationType.EXTEND_FOOTPRINT_TTL);
    body.bumpExpirationOp = XdrExtendFootprintTTLOp(
        XdrExtensionPoint(0), XdrUint32(this._extendTo));
    return body;
  }

  /// Creates a builder from an XDR extend footprint TTL operation.
  ///
  /// Parameters:
  /// - [op]: XDR extend footprint TTL operation.
  ///
  /// Returns: Builder initialized with operation parameters.
  static ExtendFootprintTTLOperationBuilder builder(
      XdrExtendFootprintTTLOp op) {
    return ExtendFootprintTTLOperationBuilder(op.extendTo.uint32);
  }
}

/// Builder for [ExtendFootprintTTLOperation].
///
/// Provides a fluent interface for constructing TTL extension operations.
///
/// Example:
/// ```dart
/// var operation = ExtendFootprintTTLOperationBuilder(100000)
///   .setSourceAccount(accountId)
///   .build();
/// ```
class ExtendFootprintTTLOperationBuilder {
  int _extendTo;
  MuxedAccount? _mSourceAccount;

  /// Creates an ExtendFootprintTTLOperationBuilder.
  ///
  /// Parameters:
  /// - [_extendTo] Number of ledgers to extend TTL to.
  ExtendFootprintTTLOperationBuilder(this._extendTo);

  /// Sets the source account for this operation.
  ///
  /// Parameters:
  /// - [sourceAccountId]: The account ID that will pay for TTL extension.
  ///
  /// Returns: This builder instance for method chaining.
  ExtendFootprintTTLOperationBuilder setSourceAccount(String sourceAccountId) {
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
  ExtendFootprintTTLOperationBuilder setMuxedSourceAccount(
      MuxedAccount sourceAccount) {
    _mSourceAccount = sourceAccount;
    return this;
  }

  /// Builds the extend footprint TTL operation.
  ///
  /// Returns: A configured [ExtendFootprintTTLOperation] instance.
  ExtendFootprintTTLOperation build() {
    ExtendFootprintTTLOperation operation =
        ExtendFootprintTTLOperation(_extendTo);
    if (_mSourceAccount != null) {
      operation.sourceAccount = _mSourceAccount;
    }
    return operation;
  }
}
