// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr/xdr_type.dart';
import 'xdr/xdr_ledger.dart';
import 'xdr/xdr_signing.dart';
import 'key_pair.dart';
import 'muxed_account.dart';
import 'operation.dart';
import 'util.dart';
import 'xdr/xdr_operation.dart';
import 'xdr/xdr_account.dart';
import 'assets.dart';
import "dart:typed_data";

class RevokeSponsorshipOperation extends Operation {
  XdrLedgerKey _ledgerKey;
  String _signerAccountId;
  XdrSignerKey _signerKey;

  RevokeSponsorshipOperation(
      this._ledgerKey, this._signerAccountId, this._signerKey) {}

  XdrLedgerKey get ledgerKey => _ledgerKey;
  String get signerAccountId => _signerAccountId;
  XdrSignerKey get signerKey => _signerKey;

  @override
  XdrOperationBody toOperationBody() {
    XdrRevokeSponsorshipOp op = XdrRevokeSponsorshipOp();

    if (_ledgerKey != null) {
      op.discriminant =
          XdrRevokeSponsorshipType.REVOKE_SPONSORSHIP_LEDGER_ENTRY;
    } else {
      op.discriminant = XdrRevokeSponsorshipType.REVOKE_SPONSORSHIP_SIGNER;
    }

    XdrAccountID signerId = XdrAccountID();
    signerId.accountID =
        KeyPair.fromAccountId(this._signerAccountId).xdrPublicKey;

    XdrRevokeSponsorshipSigner signer = XdrRevokeSponsorshipSigner();
    signer.accountId = signerId;
    signer.signerKey = _signerKey;

    op.signer = signer;

    XdrOperationBody body = XdrOperationBody();
    body.discriminant = XdrOperationType.REVOKE_SPONSORSHIP;
    body.revokeSponsorshipOp = op;
    return body;
  }

  static RevokeSponsorshipOperation builder(XdrRevokeSponsorshipOp op) {
    switch (op.discriminant) {
      case XdrRevokeSponsorshipType.REVOKE_SPONSORSHIP_LEDGER_ENTRY:
        XdrLedgerKey ledgerKey = op.ledgerKey;
        return RevokeSponsorshipOperation(ledgerKey, null, null);
      case XdrRevokeSponsorshipType.REVOKE_SPONSORSHIP_SIGNER:
        String signerAccountId =
            KeyPair.fromXdrPublicKey(op.signer.accountId.accountID).accountId;
        XdrSignerKey signerKey = op.signer.signerKey;
        return RevokeSponsorshipOperation(null, signerAccountId, signerKey);
    }
  }
}

class RevokeSponsorshipOperationBuilder {
  XdrLedgerKey _ledgerKey;
  String _signerAccountId;
  XdrSignerKey _signerKey;
  MuxedAccount _mSourceAccount;

  RevokeSponsorshipOperationBuilder();

  RevokeSponsorshipOperationBuilder revokeAccountSponsorship(String accountId) {
    if (_ledgerKey != null || _signerKey != null) {
      throw new Exception("can not revoke multiple entries per builder");
    }
    checkNotNull(accountId, "accountId cannot be null");
    _ledgerKey = XdrLedgerKey();
    _ledgerKey.discriminant = XdrLedgerEntryType.ACCOUNT;
    XdrLedgerKeyAccount lacc = XdrLedgerKeyAccount();
    XdrAccountID accId = XdrAccountID();
    accId.accountID = KeyPair.fromAccountId(accountId).xdrPublicKey;
    lacc.accountID = accId;
    _ledgerKey.account = lacc;
    return this;
  }

  RevokeSponsorshipOperationBuilder revokeDataSponsorship(
      String accountId, String dataName) {
    if (_ledgerKey != null || _signerKey != null) {
      throw new Exception("can not revoke multiple entries per builder");
    }
    checkNotNull(accountId, "accountId cannot be null");
    checkNotNull(dataName, "dataName cannot be null");

    _ledgerKey = XdrLedgerKey();
    _ledgerKey.discriminant = XdrLedgerEntryType.DATA;

    XdrAccountID accId = XdrAccountID();
    accId.accountID = KeyPair.fromAccountId(accountId).xdrPublicKey;
    XdrLedgerKeyData data = XdrLedgerKeyData();
    data.accountID = accId;
    XdrString64 dName = XdrString64();
    dName.string64 = dataName;
    data.dataName = dName;
    _ledgerKey.data = data;
    return this;
  }

  RevokeSponsorshipOperationBuilder revokeTrustlineSponsorship(
      String accountId, Asset asset) {
    if (_ledgerKey != null || _signerKey != null) {
      throw new Exception("can not revoke multiple entries per builder");
    }
    checkNotNull(accountId, "accountId cannot be null");
    checkNotNull(asset, "asset cannot be null");

    _ledgerKey = XdrLedgerKey();
    _ledgerKey.discriminant = XdrLedgerEntryType.TRUSTLINE;

    XdrAccountID accId = XdrAccountID();
    accId.accountID = KeyPair.fromAccountId(accountId).xdrPublicKey;
    XdrLedgerKeyTrustLine lt = XdrLedgerKeyTrustLine();
    lt.accountID = accId;
    lt.asset = asset.toXdr();
    _ledgerKey.trustLine = lt;

    return this;
  }

  RevokeSponsorshipOperationBuilder revokeClaimableBalanceSponsorship(
      String balanceId) {
    if (_ledgerKey != null || _signerKey != null) {
      throw new Exception("can not revoke multiple entries per builder");
    }
    checkNotNull(balanceId, "balanceId cannot be null");

    _ledgerKey = XdrLedgerKey();
    _ledgerKey.discriminant = XdrLedgerEntryType.CLAIMABLE_BALANCE;

    XdrClaimableBalanceID bId = XdrClaimableBalanceID();
    bId.discriminant = XdrClaimableBalanceIDType.CLAIMABLE_BALANCE_ID_TYPE_V0;
    List<int> list = balanceId.codeUnits;
    Uint8List bytes = Uint8List.fromList(list);
    bId.v0.hash = bytes;
    _ledgerKey.balanceID = bId;

    return this;
  }

  RevokeSponsorshipOperationBuilder revokeOfferSponsorship(
      String accountId, int offerId) {
    if (_ledgerKey != null || _signerKey != null) {
      throw new Exception("can not revoke multiple entries per builder");
    }
    checkNotNull(accountId, "accountId cannot be null");
    checkNotNull(offerId, "dataName cannot be null");

    _ledgerKey = XdrLedgerKey();
    _ledgerKey.discriminant = XdrLedgerEntryType.OFFER;

    XdrAccountID accId = XdrAccountID();
    accId.accountID = KeyPair.fromAccountId(accountId).xdrPublicKey;

    XdrLedgerKeyOffer offer = XdrLedgerKeyOffer();
    offer.sellerID = accId;
    XdrUint64 offId = XdrUint64();
    offId.uint64 = offerId;
    offer.offerID = offId;
    _ledgerKey.offer = offer;
    return this;
  }

  RevokeSponsorshipOperationBuilder revokeEd25519Signer(
      String signerAccountId, String ed25519AccountId) {
    if (_ledgerKey != null || _signerKey != null) {
      throw new Exception("can not revoke multiple entries per builder");
    }
    checkNotNull(signerAccountId, "accountId cannot be null");
    checkNotNull(ed25519AccountId, "ed25519AccountId cannot be null");

    XdrAccountID accId = XdrAccountID();
    accId.accountID = KeyPair.fromAccountId(signerAccountId).xdrPublicKey;

    _signerKey = XdrSignerKey();
    _signerKey.discriminant = XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519;
    _signerKey.ed25519 = XdrUint256();
    _signerKey.ed25519.uint256 = StrKey.decodeStellarAccountId(ed25519AccountId);

    _signerAccountId = signerAccountId;

    return this;
  }

  RevokeSponsorshipOperationBuilder revokePreAuthTxSigner(
      String signerAccountId, String preAuthTx) {
    if (_ledgerKey != null || _signerKey != null) {
      throw new Exception("can not revoke multiple entries per builder");
    }
    checkNotNull(signerAccountId, "accountId cannot be null");
    checkNotNull(preAuthTx, "preAuthTx cannot be null");

    XdrAccountID accId = XdrAccountID();
    accId.accountID = KeyPair.fromAccountId(signerAccountId).xdrPublicKey;

    _signerKey = XdrSignerKey();
    _signerKey.discriminant = XdrSignerKeyType.SIGNER_KEY_TYPE_PRE_AUTH_TX;
    _signerKey.ed25519 = XdrUint256();
    _signerKey.ed25519.uint256 = StrKey.decodePreAuthTx(preAuthTx);

    _signerAccountId = signerAccountId;

    return this;
  }

  RevokeSponsorshipOperationBuilder revokeSha256HashSigner(
      String signerAccountId, String sha256Hash) {
    if (_ledgerKey != null || _signerKey != null) {
      throw new Exception("can not revoke multiple entries per builder");
    }
    checkNotNull(signerAccountId, "accountId cannot be null");
    checkNotNull(sha256Hash, "sha256Hash cannot be null");

    XdrAccountID accId = XdrAccountID();
    accId.accountID = KeyPair.fromAccountId(signerAccountId).xdrPublicKey;

    _signerKey = XdrSignerKey();
    _signerKey.discriminant = XdrSignerKeyType.SIGNER_KEY_TYPE_HASH_X;
    _signerKey.ed25519 = XdrUint256();
    _signerKey.ed25519.uint256 = StrKey.decodePreAuthTx(sha256Hash);

    _signerAccountId = signerAccountId;

    return this;
  }

  /// Sets the source account for this operation represented by [sourceAccount].
  RevokeSponsorshipOperationBuilder setSourceAccount(String sourceAccount) {
    checkNotNull(sourceAccount, "sourceAccount cannot be null");
    _mSourceAccount = MuxedAccount(sourceAccount, null);
    return this;
  }

  /// Sets the muxed source account for this operation represented by [sourceAccountId].
  RevokeSponsorshipOperationBuilder setMuxedSourceAccount(
      MuxedAccount sourceAccount) {
    _mSourceAccount =
        checkNotNull(sourceAccount, "sourceAccount cannot be null");
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
