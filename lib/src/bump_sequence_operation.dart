// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:stellar_flutter_sdk/src/muxed_account.dart';

import 'operation.dart';
import 'util.dart';
import 'xdr/xdr_account.dart';
import 'xdr/xdr_operation.dart';
import 'xdr/xdr_type.dart';

/// Bumps the sequence number of the source account.
///
/// BumpSequence allows an account to move its sequence number forward, invalidating
/// any pre-signed transactions with lower sequence numbers. This is useful for
/// invalidating cached transactions, implementing time locks, or managing transaction
/// ordering in complex scenarios.
///
/// Use this operation when:
/// - Invalidating pre-signed transactions that should no longer be valid
/// - Implementing time-based transaction controls
/// - Managing transaction replay protection
/// - Coordinating complex multi-step operations
///
/// Important notes:
/// - The new sequence number must be greater than the current sequence
/// - Cannot decrease or set to current sequence number
/// - Invalidates all transactions with sequence numbers less than bumpTo
/// - Does not affect the account's other properties
/// - Useful for security when pre-signed transactions may be compromised
///
/// Example:
/// ```dart
/// // Bump sequence to invalidate old transactions
/// var currentSeq = BigInt.from(12345);
/// var newSeq = currentSeq + BigInt.from(1000);
/// var bumpSeq = BumpSequenceOperationBuilder(newSeq).build();
///
/// // With custom source account
/// var bumpSeqWithSource = BumpSequenceOperationBuilder(newSeq)
///   .setSourceAccount(accountId)
///   .build();
///
/// // Common pattern: bump far ahead to invalidate pre-signed transactions
/// var farFuture = BigInt.from(99999999999);
/// var invalidateOld = BumpSequenceOperationBuilder(farFuture).build();
/// ```
///
/// See also:
/// - [Operation] for general operation documentation
/// - [Stellar Sequence Numbers Documentation](https://developers.stellar.org/docs/learn/fundamentals/transactions/transaction-queue)
class BumpSequenceOperation extends Operation {
  BigInt _bumpTo;

  /// Creates a BumpSequence operation.
  ///
  /// Parameters:
  /// - [_bumpTo] - New sequence number (must be greater than current)
  BumpSequenceOperation(this._bumpTo);

  /// The sequence number to bump to.
  BigInt get bumpTo => _bumpTo;

  @override
  XdrOperationBody toOperationBody() {
    XdrBigInt64 bumpTo = new XdrBigInt64(this._bumpTo);
    XdrOperationBody body =
        new XdrOperationBody(XdrOperationType.BUMP_SEQUENCE);
    body.bumpSequenceOp = new XdrBumpSequenceOp(XdrSequenceNumber(bumpTo));

    return body;
  }

  /// Constructs a BumpSequenceOperationBuilder from XDR.
  ///
  /// Parameters:
  /// - [op] - XDR BumpSequenceOp to build from
  ///
  /// Returns: Builder configured with XDR operation data
  static BumpSequenceOperationBuilder builder(XdrBumpSequenceOp op) {
    return BumpSequenceOperationBuilder(op.bumpTo.sequenceNumber.bigInt);
  }
}

/// Builder for constructing BumpSequence operations.
///
/// Provides a fluent interface for building BumpSequence operations with optional
/// parameters. Use this builder to bump account sequence numbers.
///
/// Example:
/// ```dart
/// var operation = BumpSequenceOperationBuilder(
///   BigInt.from(99999)
/// ).setSourceAccount(accountId).build();
/// ```
class BumpSequenceOperationBuilder {
  BigInt _bumpTo;
  MuxedAccount? _mSourceAccount;

  /// Creates a BumpSequence operation builder.
  ///
  /// Parameters:
  /// - [_bumpTo] - New sequence number (must be greater than current)
  BumpSequenceOperationBuilder(this._bumpTo);

  /// Sets the source account for this operation.
  ///
  /// Parameters:
  /// - [sourceAccountId] - Account ID of the operation source
  ///
  /// Returns: This builder instance for method chaining
  BumpSequenceOperationBuilder setSourceAccount(String sourceAccountId) {
    MuxedAccount? sa = MuxedAccount.fromAccountId(sourceAccountId);
    _mSourceAccount = checkNotNull(sa, "invalid sourceAccountId");
    return this;
  }

  /// Sets the muxed source account for this operation.
  ///
  /// Parameters:
  /// - [sourceAccount] - Muxed account to use as operation source
  ///
  /// Returns: This builder instance for method chaining
  BumpSequenceOperationBuilder setMuxedSourceAccount(
      MuxedAccount sourceAccount) {
    _mSourceAccount = sourceAccount;
    return this;
  }

  /// Builds the BumpSequence operation.
  ///
  /// Returns: Configured BumpSequenceOperation instance
  BumpSequenceOperation build() {
    BumpSequenceOperation operation = new BumpSequenceOperation(_bumpTo);
    if (_mSourceAccount != null) {
      operation.sourceAccount = _mSourceAccount;
    }
    return operation;
  }
}
