// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr/xdr_type.dart';
import 'xdr/xdr_ledger.dart';
import 'xdr/xdr_signing.dart';
import 'key_pair.dart';
import 'muxed_account.dart';
import 'operation.dart';
import 'xdr/xdr_operation.dart';
import 'xdr/xdr_account.dart';
import 'assets.dart';

/// Revokes sponsorship of a ledger entry or signer, transferring reserve responsibility.
///
/// This operation allows the current sponsor of a ledger entry or signer to revoke
/// their sponsorship. After revocation, the reserve requirement is transferred back
/// to the account that owns the entry. This is part of the sponsorship feature
/// introduced in Protocol 15 via CAP-33.
///
/// Revocable Entry Types:
/// - **Account**: Sponsorship of an account's base reserve
/// - **Trustline**: Sponsorship of a trustline entry
/// - **Offer**: Sponsorship of an offer entry
/// - **Data**: Sponsorship of a data entry
/// - **Claimable Balance**: Sponsorship of a claimable balance
/// - **Signer**: Sponsorship of an additional signer on an account
///
/// Requirements:
/// - Source account must be the current sponsor of the entry
/// - Sponsored account must have sufficient available balance to cover reserves
/// - After revocation, reserve responsibility returns to the entry owner
///
/// Use Cases:
/// - End temporary sponsorship agreements
/// - Transfer reserve responsibility back to users
/// - Clean up sponsorship relationships
/// - Reduce sponsor's reserve commitments
///
/// Example - Revoke Trustline Sponsorship:
/// ```dart
/// var revokeOp = RevokeSponsorshipOperationBuilder()
///   .revokeTrustlineSponsorship(userAccountId, usdAsset)
///   .setSourceAccount(sponsorAccountId)
///   .build();
///
/// var transaction = TransactionBuilder(sponsorAccount)
///   .addOperation(revokeOp)
///   .build();
/// ```
///
/// Example - Revoke Claimable Balance Sponsorship:
/// ```dart
/// var revokeOp = RevokeSponsorshipOperationBuilder()
///   .revokeClaimableBalanceSponsorship(balanceId)
///   .setSourceAccount(sponsorAccountId)
///   .build();
/// ```
///
/// Example - Revoke Signer Sponsorship:
/// ```dart
/// var revokeOp = RevokeSponsorshipOperationBuilder()
///   .revokeEd25519Signer(accountId, signerAccountId)
///   .setSourceAccount(sponsorAccountId)
///   .build();
/// ```
///
/// See also:
/// - [BeginSponsoringFutureReservesOperation] to establish sponsorship
/// - [EndSponsoringFutureReservesOperation] to complete sponsorship sandwich
/// - [CAP-33](https://github.com/stellar/stellar-protocol/blob/master/core/cap-0033.md)
/// - [Stellar Sponsorship Documentation](https://developers.stellar.org/docs/encyclopedia/sponsored-reserves)
class RevokeSponsorshipOperation extends Operation {
  XdrLedgerKey? _ledgerKey;
  String? _signerAccountId;
  XdrSignerKey? _signerKey;

  /// Creates a RevokeSponsorshipOperation.
  ///
  /// Parameters:
  /// - [_ledgerKey]: The ledger key of the entry (null if revoking signer).
  /// - [_signerAccountId]: The account ID containing the signer (null if revoking entry).
  /// - [_signerKey]: The signer key (null if revoking entry).
  RevokeSponsorshipOperation(
      this._ledgerKey, this._signerAccountId, this._signerKey);

  /// The ledger key of the entry to revoke sponsorship for (null if revoking signer).
  XdrLedgerKey? get ledgerKey => _ledgerKey;

  /// The account ID containing the signer (null if revoking ledger entry).
  String? get signerAccountId => _signerAccountId;

  /// The signer key to revoke sponsorship for (null if revoking ledger entry).
  XdrSignerKey? get signerKey => _signerKey;

  @override
  XdrOperationBody toOperationBody() {
    XdrOperationBody body =
        XdrOperationBody(XdrOperationType.REVOKE_SPONSORSHIP);

    if (_ledgerKey != null) {
      XdrRevokeSponsorshipOp op = XdrRevokeSponsorshipOp(
          XdrRevokeSponsorshipType.REVOKE_SPONSORSHIP_LEDGER_ENTRY);
      op.ledgerKey = this._ledgerKey;
      body.revokeSponsorshipOp = op;
    } else {
      XdrRevokeSponsorshipOp op = XdrRevokeSponsorshipOp(
          XdrRevokeSponsorshipType.REVOKE_SPONSORSHIP_SIGNER);

      XdrAccountID xAccountId = XdrAccountID(
          KeyPair.fromAccountId(this._signerAccountId!).xdrPublicKey);
      op.signer = XdrRevokeSponsorshipSigner(xAccountId, _signerKey!);
      body.revokeSponsorshipOp = op;
    }

    return body;
  }

  /// Creates a [RevokeSponsorshipOperation] from XDR operation.
  ///
  /// Used for deserializing operations from XDR format.
  ///
  /// Parameters:
  /// - [op]: The XDR revoke sponsorship operation data.
  ///
  /// Returns: A configured operation instance, or null if the type is unknown.
  static RevokeSponsorshipOperation? fromXdr(XdrRevokeSponsorshipOp op) {
    switch (op.discriminant) {
      case XdrRevokeSponsorshipType.REVOKE_SPONSORSHIP_LEDGER_ENTRY:
        XdrLedgerKey ledgerKey = op.ledgerKey!;
        return RevokeSponsorshipOperation(ledgerKey, null, null);
      case XdrRevokeSponsorshipType.REVOKE_SPONSORSHIP_SIGNER:
        String signerAccountId =
            KeyPair.fromXdrPublicKey(op.signer!.accountId.accountID).accountId;
        XdrSignerKey signerKey = op.signer!.signerKey;
        return RevokeSponsorshipOperation(null, signerAccountId, signerKey);
    }
    return null;
  }
}

/// Builder for [RevokeSponsorshipOperation].
///
/// Provides methods to revoke sponsorship of different ledger entry types and signers.
/// Only one revocation type can be specified per builder instance.
///
/// Example:
/// ```dart
/// var operation = RevokeSponsorshipOperationBuilder()
///   .revokeTrustlineSponsorship(accountId, asset)
///   .setSourceAccount(sponsorAccountId)
///   .build();
/// ```
class RevokeSponsorshipOperationBuilder {
  XdrLedgerKey? _ledgerKey;
  String? _signerAccountId;
  XdrSignerKey? _signerKey;
  MuxedAccount? _mSourceAccount;

  RevokeSponsorshipOperationBuilder();

  /// Revokes sponsorship of an account's base reserve.
  ///
  /// Parameters:
  /// - [accountId]: The account ID whose sponsorship will be revoked.
  ///
  /// Returns: This builder instance for method chaining.
  ///
  /// Throws: Exception if another entry type has already been specified.
  RevokeSponsorshipOperationBuilder revokeAccountSponsorship(String accountId) {
    if (_ledgerKey != null || _signerKey != null) {
      throw new Exception("can not revoke multiple entries per builder");
    }
    _ledgerKey = XdrLedgerKey(XdrLedgerEntryType.ACCOUNT);
    XdrLedgerKeyAccount lacc = XdrLedgerKeyAccount(
        XdrAccountID(KeyPair.fromAccountId(accountId).xdrPublicKey));
    _ledgerKey!.account = lacc;
    return this;
  }

  /// Revokes sponsorship of a data entry.
  ///
  /// Parameters:
  /// - [accountId]: The account ID that owns the data entry.
  /// - [dataName]: The name of the data entry.
  ///
  /// Returns: This builder instance for method chaining.
  ///
  /// Throws: Exception if another entry type has already been specified.
  RevokeSponsorshipOperationBuilder revokeDataSponsorship(
      String accountId, String dataName) {
    if (_ledgerKey != null || _signerKey != null) {
      throw new Exception("can not revoke multiple entries per builder");
    }

    _ledgerKey = XdrLedgerKey(XdrLedgerEntryType.DATA);

    XdrAccountID accountID =
        XdrAccountID(KeyPair.fromAccountId(accountId).xdrPublicKey);
    XdrString64 dName = XdrString64(dataName);
    _ledgerKey!.data = XdrLedgerKeyData(accountID, dName);
    return this;
  }

  /// Revokes sponsorship of a trustline.
  ///
  /// Parameters:
  /// - [accountId]: The account ID that holds the trustline.
  /// - [asset]: The asset of the trustline.
  ///
  /// Returns: This builder instance for method chaining.
  ///
  /// Throws: Exception if another entry type has already been specified.
  RevokeSponsorshipOperationBuilder revokeTrustlineSponsorship(
      String accountId, Asset asset) {
    if (_ledgerKey != null || _signerKey != null) {
      throw new Exception("can not revoke multiple entries per builder");
    }

    _ledgerKey = XdrLedgerKey(XdrLedgerEntryType.TRUSTLINE);

    _ledgerKey!.trustLine = XdrLedgerKeyTrustLine(
        XdrAccountID(KeyPair.fromAccountId(accountId).xdrPublicKey),
        asset.toXdrTrustLineAsset());

    return this;
  }

  /// Revokes sponsorship of a claimable balance.
  ///
  /// Parameters:
  /// - [balanceId]: The hex-encoded claimable balance ID.
  ///
  /// Returns: This builder instance for method chaining.
  ///
  /// Throws: Exception if another entry type has already been specified.
  RevokeSponsorshipOperationBuilder revokeClaimableBalanceSponsorship(
      String balanceId) {
    if (_ledgerKey != null || _signerKey != null) {
      throw new Exception("can not revoke multiple entries per builder");
    }

    _ledgerKey = XdrLedgerKey(XdrLedgerEntryType.CLAIMABLE_BALANCE);

    XdrClaimableBalanceID bId = XdrClaimableBalanceID.forId(balanceId);
    _ledgerKey!.balanceID = bId;
    return this;
  }

  /// Revokes sponsorship of an offer.
  ///
  /// Parameters:
  /// - [accountId]: The account ID of the offer seller.
  /// - [offerId]: The offer ID.
  ///
  /// Returns: This builder instance for method chaining.
  ///
  /// Throws: Exception if another entry type has already been specified.
  RevokeSponsorshipOperationBuilder revokeOfferSponsorship(
      String accountId, int offerId) {
    if (_ledgerKey != null || _signerKey != null) {
      throw new Exception("can not revoke multiple entries per builder");
    }

    _ledgerKey = XdrLedgerKey(XdrLedgerEntryType.OFFER);

    XdrAccountID sellerID =
        XdrAccountID(KeyPair.fromAccountId(accountId).xdrPublicKey);
    XdrUint64 offId = XdrUint64(offerId);
    _ledgerKey!.offer = XdrLedgerKeyOffer(sellerID, offId);
    return this;
  }

  /// Revokes sponsorship of an Ed25519 signer.
  ///
  /// Parameters:
  /// - [signerAccountId]: The account ID that has the signer.
  /// - [ed25519AccountId]: The Ed25519 public key of the signer (account ID format).
  ///
  /// Returns: This builder instance for method chaining.
  ///
  /// Throws: Exception if another entry type has already been specified.
  RevokeSponsorshipOperationBuilder revokeEd25519Signer(
      String signerAccountId, String ed25519AccountId) {
    if (_ledgerKey != null || _signerKey != null) {
      throw new Exception("can not revoke multiple entries per builder");
    }

    _signerKey = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519);
    _signerKey!.ed25519 = XdrUint256(StrKey.decodeStellarAccountId(ed25519AccountId));
    _signerAccountId = signerAccountId;

    return this;
  }

  /// Revokes sponsorship of a pre-authorized transaction signer.
  ///
  /// Parameters:
  /// - [signerAccountId]: The account ID that has the signer.
  /// - [preAuthTx]: The pre-authorized transaction hash (StrKey T format).
  ///
  /// Returns: This builder instance for method chaining.
  ///
  /// Throws: Exception if another entry type has already been specified.
  RevokeSponsorshipOperationBuilder revokePreAuthTxSigner(
      String signerAccountId, String preAuthTx) {
    if (_ledgerKey != null || _signerKey != null) {
      throw new Exception("can not revoke multiple entries per builder");
    }

    _signerKey = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_PRE_AUTH_TX);
    _signerKey!.preAuthTx = XdrUint256(StrKey.decodePreAuthTx(preAuthTx));
    _signerAccountId = signerAccountId;

    return this;
  }

  /// Revokes sponsorship of a SHA256 hash signer.
  ///
  /// Parameters:
  /// - [signerAccountId]: The account ID that has the signer.
  /// - [sha256Hash]: The SHA256 hash (StrKey X format).
  ///
  /// Returns: This builder instance for method chaining.
  ///
  /// Throws: Exception if another entry type has already been specified.
  RevokeSponsorshipOperationBuilder revokeSha256HashSigner(
      String signerAccountId, String sha256Hash) {
    if (_ledgerKey != null || _signerKey != null) {
      throw new Exception("can not revoke multiple entries per builder");
    }

    _signerKey = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_HASH_X);
    _signerKey!.hashX = XdrUint256(StrKey.decodeSha256Hash(sha256Hash));
    _signerAccountId = signerAccountId;

    return this;
  }

  /// Sets the source account for this operation.
  ///
  /// The source account must be the current sponsor of the entry or signer.
  ///
  /// Parameters:
  /// - [sourceAccountId]: The account ID of the current sponsor.
  ///
  /// Returns: This builder instance for method chaining.
  RevokeSponsorshipOperationBuilder setSourceAccount(String sourceAccountId) {
    _mSourceAccount = MuxedAccount.fromAccountId(sourceAccountId);
    return this;
  }

  /// Sets the muxed source account for this operation.
  ///
  /// Parameters:
  /// - [sourceAccount]: The muxed source account (current sponsor).
  ///
  /// Returns: This builder instance for method chaining.
  RevokeSponsorshipOperationBuilder setMuxedSourceAccount(
      MuxedAccount sourceAccount) {
    _mSourceAccount = sourceAccount;
    return this;
  }

  /// Builds the revoke sponsorship operation.
  ///
  /// Returns: A configured [RevokeSponsorshipOperation] instance.
  RevokeSponsorshipOperation build() {
    RevokeSponsorshipOperation operation =
        RevokeSponsorshipOperation(_ledgerKey, _signerAccountId, _signerKey);
    if (_mSourceAccount != null) {
      operation.sourceAccount = _mSourceAccount;
    }
    return operation;
  }
}
