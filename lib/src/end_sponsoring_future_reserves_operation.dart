// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'operation.dart';
import 'xdr/xdr.dart';

/// Ends the sponsorship established by BeginSponsoringFutureReservesOperation.
///
/// This operation completes the sponsorship "sandwich" pattern and must be included
/// after BeginSponsoringFutureReservesOperation and any sponsored operations. The
/// source account for this operation must be the sponsored account (not the sponsor).
///
/// Sponsorship Pattern:
/// 1. BeginSponsoringFutureReservesOperation (source: sponsor account)
/// 2. Sponsored operations (source: sponsored account)
/// 3. EndSponsoringFutureReservesOperation (source: sponsored account) <- This operation
///
/// Requirements:
/// - Must follow a BeginSponsoringFutureReservesOperation
/// - Source account must be the sponsored account
/// - Completes the atomic sponsorship transaction
/// - All operations between Begin and End are sponsored together
///
/// Important Notes:
/// - This operation has no parameters - it simply closes the sponsorship block
/// - The entire sequence (Begin -> Operations -> End) must be in one transaction
/// - If any operation in the sandwich fails, the entire transaction fails
/// - The sponsored account must sign the transaction to authorize the sponsorship
///
/// Example:
/// ```dart
/// // Complete sponsorship sandwich
/// var beginSponsoring = BeginSponsoringFutureReservesOperationBuilder(
///   userAccountId
/// ).setSourceAccount(sponsorAccountId).build();
///
/// var createTrustline = ChangeTrustOperationBuilder(
///   usdAsset,
///   "1000"
/// ).setSourceAccount(userAccountId).build();
///
/// var endSponsoring = EndSponsoringFutureReservesOperationBuilder()
///   .setSourceAccount(userAccountId).build();
///
/// var transaction = TransactionBuilder(sponsorAccount)
///   .addOperation(beginSponsoring)
///   .addOperation(createTrustline)
///   .addOperation(endSponsoring)
///   .build();
///
/// // Both sponsor and sponsored account must sign
/// transaction.sign(sponsorKeyPair, network);
/// transaction.sign(userKeyPair, network);
/// ```
///
/// See also:
/// - [BeginSponsoringFutureReservesOperation] to start the sponsorship
/// - [RevokeSponsorshipOperation] to revoke existing sponsorships
/// - [CAP-33](https://github.com/stellar/stellar-protocol/blob/master/core/cap-0033.md)
/// - [Stellar developer docs](https://developers.stellar.org)
class EndSponsoringFutureReservesOperation extends Operation {
  /// Creates an EndSponsoringFutureReservesOperation.
  ///
  /// This operation has no parameters as it simply closes the sponsorship block.
  EndSponsoringFutureReservesOperation() {}

  /// Converts this operation to its XDR OperationBody representation.
  ///
  /// Returns: XDR OperationBody for this end sponsoring future reserves operation.
  @override
  XdrOperationBody toOperationBody() {
    XdrOperationBody body =
        XdrOperationBody(XdrOperationType.END_SPONSORING_FUTURE_RESERVES);
    return body;
  }

  /// Creates an [EndSponsoringFutureReservesOperation] from XDR.
  ///
  /// Used for deserializing operations from XDR format.
  ///
  /// Returns: A new operation instance.
  static EndSponsoringFutureReservesOperation builder() {
    return EndSponsoringFutureReservesOperation();
  }
}

/// Builder for [EndSponsoringFutureReservesOperation].
///
/// Provides a fluent interface for constructing the operation that completes
/// a sponsorship sandwich.
///
/// The source account set via [setSourceAccount] must be the sponsored
/// account (not the sponsor).
///
/// Example:
/// ```dart
/// var operation = EndSponsoringFutureReservesOperationBuilder()
///   .setSourceAccount(sponsoredAccountId).build();
/// ```
class EndSponsoringFutureReservesOperationBuilder
    extends OperationBuilder<EndSponsoringFutureReservesOperationBuilder> {
  /// Creates an EndSponsoringFutureReservesOperationBuilder.
  ///
  /// This operation has no parameters but requires the source account
  /// to be set to the sponsored account.
  EndSponsoringFutureReservesOperationBuilder();

  /// Builds the end sponsoring future reserves operation.
  ///
  /// Returns: A configured [EndSponsoringFutureReservesOperation] instance.
  EndSponsoringFutureReservesOperation build() {
    EndSponsoringFutureReservesOperation operation =
        EndSponsoringFutureReservesOperation();
    return applySourceAccount(operation);
  }
}
