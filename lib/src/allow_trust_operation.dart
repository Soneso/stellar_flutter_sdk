// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'operation.dart';
import 'dart:convert';
import 'key_pair.dart';
import 'util.dart';
import 'xdr/xdr_operation.dart';
import 'xdr/xdr_account.dart';
import 'xdr/xdr_trustline.dart';
import 'xdr/xdr_asset.dart';
import 'muxed_account.dart';

/// Represents [AllowTrust](https://developers.stellar.org/docs/start/list-of-operations/#allow-trust) operation.
/// See [List of Operations](https://developers.stellar.org/docs/start/list-of-operations/)
class AllowTrustOperation extends Operation {
  String _trustor;
  String _assetCode;
  bool _authorize;
  bool _authorizeToMaintainLiabilities;

  AllowTrustOperation(this._trustor, this._assetCode, this._authorize,
      this._authorizeToMaintainLiabilities);

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
    XdrAccountID trustor =
        new XdrAccountID(KeyPair.fromAccountId(this._trustor).xdrPublicKey);
    // asset
    XdrAssetType discriminant = XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4;
    Uint8List? assetCode4;
    Uint8List? assetCode12;

    if (_assetCode.length <= 4) {
      assetCode4 =
          Util.paddedByteArray(Uint8List.fromList(utf8.encode(_assetCode)), 4);
    } else {
      discriminant = XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12;
      assetCode12 =
          Util.paddedByteArray(Uint8List.fromList(utf8.encode(_assetCode)), 12);
    }
    XdrAllowTrustOpAsset asset = new XdrAllowTrustOpAsset(discriminant);
    asset.assetCode4 = assetCode4;
    asset.assetCode12 = assetCode12;

    int xdrAuthorize = 0;
    // authorize
    if (authorize) {
      xdrAuthorize = XdrTrustLineFlags.AUTHORIZED_FLAG.value;
    } else if (authorizeToMaintainLiabilities) {
      xdrAuthorize =
          XdrTrustLineFlags.AUTHORIZED_TO_MAINTAIN_LIABILITIES_FLAG.value;
    }

    XdrAllowTrustOp op = new XdrAllowTrustOp(trustor, asset, xdrAuthorize);

    XdrOperationBody body = new XdrOperationBody(XdrOperationType.ALLOW_TRUST);
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

  MuxedAccount? _mSourceAccount;

  ///Creates a new AllowTrust builder.
  AllowTrustOperationBuilder(this._trustor, this._assetCode, this._authorize);

  ///Set source account of this operation
  AllowTrustOperationBuilder setSourceAccount(String sourceAccountId) {
    MuxedAccount? sa = MuxedAccount.fromAccountId(sourceAccountId);
    _mSourceAccount = checkNotNull(sa, "invalid sourceAccountId");
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
