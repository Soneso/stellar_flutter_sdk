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

class RevokeSponsorshipOperation extends Operation {
  XdrLedgerKey? _ledgerKey;
  String? _signerAccountId;
  XdrSignerKey? _signerKey;

  RevokeSponsorshipOperation(
      this._ledgerKey, this._signerAccountId, this._signerKey);

  XdrLedgerKey? get ledgerKey => _ledgerKey;
  String? get signerAccountId => _signerAccountId;
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

class RevokeSponsorshipOperationBuilder {
  XdrLedgerKey? _ledgerKey;
  String? _signerAccountId;
  XdrSignerKey? _signerKey;
  MuxedAccount? _mSourceAccount;

  RevokeSponsorshipOperationBuilder();

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

  /// Sets the source account for this operation represented by [sourceAccountId].
  RevokeSponsorshipOperationBuilder setSourceAccount(String sourceAccountId) {
    _mSourceAccount = MuxedAccount.fromAccountId(sourceAccountId);
    return this;
  }

  /// Sets the muxed source account for this operation represented by [sourceAccount].
  RevokeSponsorshipOperationBuilder setMuxedSourceAccount(
      MuxedAccount sourceAccount) {
    _mSourceAccount = sourceAccount;
    return this;
  }

  ///Builds an operation
  RevokeSponsorshipOperation build() {
    RevokeSponsorshipOperation operation =
        RevokeSponsorshipOperation(_ledgerKey, _signerAccountId, _signerKey);
    if (_mSourceAccount != null) {
      operation.sourceAccount = _mSourceAccount;
    }
    return operation;
  }
}
