// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'key_pair.dart';
import 'muxed_account.dart';
import 'operation.dart';
import 'util.dart';
import 'xdr/xdr_operation.dart';
import 'xdr/xdr_account.dart';

/// Begins sponsoring the base reserves and future reserve requirements of another account.
///
/// This operation establishes a sponsorship relationship where the source account (sponsor)
/// agrees to pay the base reserves for entries created by the sponsored account. This is
/// part of the sponsorship feature introduced in Protocol 15 via CAP-33, which enables
/// accounts to have their reserves paid by other accounts.
///
/// Sponsorship Pattern:
/// Sponsorship operations must be used in a "sandwich" pattern:
/// 1. BeginSponsoringFutureReservesOperation (sponsor is source)
/// 2. One or more sponsored operations (sponsored account is source)
/// 3. EndSponsoringFutureReservesOperation (sponsored account is source)
///
/// The sponsor pays for:
/// - Trustlines created by the sponsored account
/// - Offers created by the sponsored account
/// - Data entries created by the sponsored account
/// - Claimable balances created by the sponsored account
/// - Account creation (if sponsor creates the account)
///
/// Use Cases:
/// - Onboarding new users without requiring them to fund their account first
/// - Services paying reserves for their users' activities
/// - Sponsored account creation for better user experience
/// - Temporary sponsorship for specific operations
///
/// Example:
/// ```dart
/// // Sponsor creates a trustline for a user
/// var beginSponsoring = BeginSponsoringFutureReservesOperationBuilder(
///   userAccountId
/// ).setSourceAccount(sponsorAccountId).build();
///
/// var changeTrust = ChangeTrustOperationBuilder(
///   usdAsset,
///   "1000"
/// ).setSourceAccount(userAccountId).build();
///
/// var endSponsoring = EndSponsoringFutureReservesOperationBuilder()
///   .setSourceAccount(userAccountId).build();
///
/// var transaction = TransactionBuilder(sponsorAccount)
///   .addOperation(beginSponsoring)
///   .addOperation(changeTrust)
///   .addOperation(endSponsoring)
///   .build();
/// ```
///
/// See also:
/// - [EndSponsoringFutureReservesOperation] to complete the sponsorship sandwich
/// - [RevokeSponsorshipOperation] to revoke existing sponsorships
/// - [CAP-33](https://github.com/stellar/stellar-protocol/blob/master/core/cap-0033.md)
/// - [Stellar Sponsorship Documentation](https://developers.stellar.org/docs/encyclopedia/sponsored-reserves)
class BeginSponsoringFutureReservesOperation extends Operation {
  String _sponsoredId;

  /// Creates a BeginSponsoringFutureReservesOperation.
  ///
  /// Parameters:
  /// - [_sponsoredId]: The account ID of the account to be sponsored.
  BeginSponsoringFutureReservesOperation(this._sponsoredId);

  /// The account ID of the account being sponsored.
  String get sponsoredId => _sponsoredId;

  @override
  XdrOperationBody toOperationBody() {
    XdrOperationBody body =
        XdrOperationBody(XdrOperationType.BEGIN_SPONSORING_FUTURE_RESERVES);
    body.beginSponsoringFutureReservesOp = XdrBeginSponsoringFutureReservesOp(
        XdrAccountID(KeyPair.fromAccountId(this.sponsoredId).xdrPublicKey));
    return body;
  }

  /// Creates a [BeginSponsoringFutureReservesOperation] from XDR operation.
  ///
  /// Used for deserializing operations from XDR format.
  ///
  /// Parameters:
  /// - [op]: The XDR begin sponsoring future reserves operation data.
  ///
  /// Returns: A configured operation instance with the sponsored account.
  static BeginSponsoringFutureReservesOperation builder(
      XdrBeginSponsoringFutureReservesOp op) {
    String sponsoredId =
        KeyPair.fromXdrPublicKey(op.sponsoredID.accountID).accountId;
    return BeginSponsoringFutureReservesOperation(sponsoredId);
  }
}

/// Builder for [BeginSponsoringFutureReservesOperation].
///
/// Provides a fluent interface for constructing sponsorship operations.
///
/// Example:
/// ```dart
/// var operation = BeginSponsoringFutureReservesOperationBuilder(
///   sponsoredAccountId
/// ).setSourceAccount(sponsorAccountId).build();
/// ```
class BeginSponsoringFutureReservesOperationBuilder {
  String _sponsoredId;
  MuxedAccount? _mSourceAccount;

  /// Creates a BeginSponsoringFutureReservesOperationBuilder.
  ///
  /// Parameters:
  /// - [_sponsoredId]: The account ID of the account to be sponsored.
  BeginSponsoringFutureReservesOperationBuilder(this._sponsoredId);

  /// Sets the source account for this operation.
  ///
  /// The source account will be the sponsor paying for the reserves.
  ///
  /// Parameters:
  /// - [sourceAccountId]: The account ID of the sponsoring account.
  ///
  /// Returns: This builder instance for method chaining.
  BeginSponsoringFutureReservesOperationBuilder setSourceAccount(
      String sourceAccountId) {
    MuxedAccount? sa = MuxedAccount.fromAccountId(sourceAccountId);
    _mSourceAccount = checkNotNull(sa, "invalid sourceAccountId");
    return this;
  }

  /// Sets the muxed source account for this operation.
  ///
  /// Parameters:
  /// - [sourceAccount]: The muxed source account (sponsor).
  ///
  /// Returns: This builder instance for method chaining.
  BeginSponsoringFutureReservesOperationBuilder setMuxedSourceAccount(
      MuxedAccount sourceAccount) {
    _mSourceAccount = sourceAccount;
    return this;
  }

  /// Builds the begin sponsoring future reserves operation.
  ///
  /// Returns: A configured [BeginSponsoringFutureReservesOperation] instance.
  BeginSponsoringFutureReservesOperation build() {
    BeginSponsoringFutureReservesOperation operation =
        BeginSponsoringFutureReservesOperation(_sponsoredId);
    if (_mSourceAccount != null) {
      operation.sourceAccount = _mSourceAccount;
    }
    return operation;
  }
}
