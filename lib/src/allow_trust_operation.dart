// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'operation.dart';
import 'dart:convert';
import 'key_pair.dart';
import 'util.dart';
import 'xdr/xdr_operation.dart';
import 'xdr/xdr_account.dart';
import 'xdr/xdr_trustline.dart';
import 'xdr/xdr_asset.dart';
import 'muxed_account.dart';

/// Represents <a href="https://developers.stellar.org/docs/start/list-of-operations/#allow-trust" target="_blank">AllowTrust</a> operation.
/// See <a href="https://developers.stellar.org/docs/start/list-of-operations/" target="_blank">List of Operations</a>
class AllowTrustOperation extends Operation {
  String _trustor;
  String _assetCode;
  bool _authorize;
  bool _authorizeToMaintainLiabilities;

  AllowTrustOperation(String trustor, String assetCode, bool authorize,
      bool authorizeToMaintainLiabilities) {
    this._trustor = checkNotNull(trustor, "trustor cannot be null");
    this._assetCode = checkNotNull(assetCode, "assetCode cannot be null");
    this._authorize = authorize;
    this._authorizeToMaintainLiabilities = authorizeToMaintainLiabilities;
  }

  /// The account id of the recipient of the trustline.
  String get trustor => _trustor;

  /// The asset of the trustline the source account is authorizing. For example, if a gateway wants to allow another account to hold its USD credit, the type is USD.
  String get assetCode => _assetCode;

  /// Flag indicating whether the trustline is authorized.
  bool get authorize => _authorize;

  /// Flag indicating whether the trustline is authorized to maintain liabilities.
  bool get authorizeToMaintainLiabilities => _authorizeToMaintainLiabilities;

  @override
  XdrOperationBody toOperationBody() {
    XdrAllowTrustOp op = new XdrAllowTrustOp();

    // trustor
    XdrAccountID trustor = new XdrAccountID();
    trustor.accountID = KeyPair.fromAccountId(this._trustor).xdrPublicKey;
    op.trustor = trustor;
    // asset
    XdrAllowTrustOpAsset asset = new XdrAllowTrustOpAsset();
    if (_assetCode.length <= 4) {
      asset.discriminant = XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4;
      asset.assetCode4 = Util.paddedByteArray(utf8.encode(_assetCode), 4);
    } else {
      asset.discriminant = XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12;
      asset.assetCode12 = Util.paddedByteArray(utf8.encode(_assetCode), 12);
    }
    op.asset = asset;

    // authorize
    if (authorize) {
      op.authorize = XdrTrustLineFlags.AUTHORIZED_FLAG.value;
    } else if (authorizeToMaintainLiabilities) {
      op.authorize =
          XdrTrustLineFlags.AUTHORIZED_TO_MAINTAIN_LIABILITIES_FLAG.value;
    } else {
      op.authorize = 0;
    }

    XdrOperationBody body = new XdrOperationBody();
    body.discriminant = XdrOperationType.ALLOW_TRUST;
    body.allowTrustOp = op;
    return body;
  }

  /// Builds AllowTrust operation.
  static AllowTrustOperationBuilder builder(XdrAllowTrustOp op) {
    String assetCode;
    switch (op.asset.discriminant) {
      case XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4:
        assetCode = Util.paddedByteArrayToString(op.asset.assetCode4);
        break;
      case XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12:
        assetCode = Util.paddedByteArrayToString(op.asset.assetCode12);
        break;
      default:
        throw new Exception("Unknown asset code");
    }

    return AllowTrustOperationBuilder(
        KeyPair.fromXdrPublicKey(op.trustor.accountID).accountId,
        assetCode,
        op.authorize);
  }
}

class AllowTrustOperationBuilder {
  String _trustor;
  String _assetCode;
  int _authorize;

  MuxedAccount _mSourceAccount;

  ///Creates a new AllowTrust builder.
  AllowTrustOperationBuilder(String trustor, String assetCode, int authorize) {
    this._trustor = trustor;
    this._assetCode = assetCode;
    this._authorize = authorize;
  }

  ///Set source account of this operation
  AllowTrustOperationBuilder setSourceAccount(String sourceAccount) {
    _mSourceAccount = MuxedAccount(sourceAccount, null);
    return this;
  }

  AllowTrustOperationBuilder setMuxedSourceAccount(MuxedAccount sourceAccount) {
    _mSourceAccount = sourceAccount;
    return this;
  }

  ///Builds an operation
  AllowTrustOperation build() {
    bool tAuthorized = _authorize == XdrTrustLineFlags.AUTHORIZED_FLAG.value;
    bool tAuthorizedToMaintain = _authorize ==
        XdrTrustLineFlags.AUTHORIZED_TO_MAINTAIN_LIABILITIES_FLAG.value;
    AllowTrustOperation operation = new AllowTrustOperation(
        _trustor, _assetCode, tAuthorized, tAuthorizedToMaintain);
    if (_mSourceAccount != null) {
      operation.sourceAccount = _mSourceAccount;
    }
    return operation;
  }
}
