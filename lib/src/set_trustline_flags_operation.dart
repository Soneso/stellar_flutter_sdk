// Copyright 2021 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'key_pair.dart';
import 'muxed_account.dart';
import 'operation.dart';
import 'util.dart';
import 'xdr/xdr_operation.dart';
import 'xdr/xdr_account.dart';
import 'assets.dart';
import 'xdr/xdr_trustline.dart';
import 'xdr/xdr_type.dart';

class SetTrustLineFlagsOperation extends Operation {
  String? _trustorId;
  Asset? _asset;
  int? _clearFlags;
  int? _setFlags;

  SetTrustLineFlagsOperation(String? trustorId, Asset? asset, int? clearFlags, int? setFlags) {
    this._trustorId = checkNotNull(trustorId, "trustorId cannot be null");
    this._asset = checkNotNull(asset, "asset cannot be null");
    this._clearFlags = checkNotNull(clearFlags, "clearFlags cannot be null");
    this._setFlags = checkNotNull(setFlags, "setFlags cannot be null");
  }

  String? get trustorId => _trustorId;

  Asset? get asset => _asset;

  int? get clearFlags => _clearFlags;

  int? get setFlags => _setFlags;

  @override
  XdrOperationBody toOperationBody() {
    XdrSetTrustLineFlagsOp op = XdrSetTrustLineFlagsOp();

    op.accountID = XdrAccountID(KeyPair.fromAccountId(this.trustorId!).xdrPublicKey);
    op.asset = asset?.toXdr();

    XdrUint32 clearFlags = new XdrUint32();
    clearFlags.uint32 = this.clearFlags;
    op.clearFlags = clearFlags;

    XdrUint32 setFlags = new XdrUint32();
    setFlags.uint32 = this.setFlags;
    op.setFlags = setFlags;

    XdrOperationBody body = XdrOperationBody();
    body.discriminant = XdrOperationType.SET_TRUST_LINE_FLAGS;
    body.setTrustLineFlagsOp = op;
    return body;
  }

  static SetTrustLineFlagsOperationBuilder builder(XdrSetTrustLineFlagsOp op) {
    String trustorId = KeyPair.fromXdrPublicKey(op.accountID!.accountID).accountId;
    int clearFlags = op.clearFlags!.uint32!;
    int setFlags = op.setFlags!.uint32!;
    return SetTrustLineFlagsOperationBuilder(trustorId, Asset.fromXdr(op.asset!), clearFlags, setFlags);
  }
}

class SetTrustLineFlagsOperationBuilder {
  String? _trustorId;
  Asset? _asset;
  int? _clearFlags;
  int? _setFlags;
  MuxedAccount? _mSourceAccount;

  SetTrustLineFlagsOperationBuilder(this._trustorId, this._asset, this._clearFlags, this._setFlags);

  /// Sets the source account for this operation represented by [sourceAccountId].
  SetTrustLineFlagsOperationBuilder setSourceAccount(String sourceAccountId) {
    checkNotNull(sourceAccountId, "sourceAccountId cannot be null");
    _mSourceAccount = MuxedAccount.fromAccountId(sourceAccountId);
    return this;
  }

  /// Sets the muxed source account for this operation represented by [sourceAccount].
  SetTrustLineFlagsOperationBuilder setMuxedSourceAccount(MuxedAccount sourceAccount) {
    _mSourceAccount = checkNotNull(sourceAccount, "sourceAccount cannot be null");
    return this;
  }

  ///Builds an operation
  SetTrustLineFlagsOperation build() {
    SetTrustLineFlagsOperation operation =
        SetTrustLineFlagsOperation(_trustorId, _asset, _clearFlags, _setFlags);
    if (_mSourceAccount != null) {
      operation.sourceAccount = _mSourceAccount;
    }
    return operation;
  }
}
