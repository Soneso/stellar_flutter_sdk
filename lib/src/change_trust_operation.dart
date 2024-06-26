// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:stellar_flutter_sdk/src/muxed_account.dart';

import 'operation.dart';
import 'assets.dart';
import 'util.dart';
import 'xdr/xdr_operation.dart';
import 'xdr/xdr_type.dart';
import 'xdr/xdr_trustline.dart';

/// Represents <a href="https://developers.stellar.org/docs/start/list-of-operations/#change-trust" target="_blank">ChangeTrust</a> operation.
/// See: <a href="https://developers.stellar.org/docs/start/list-of-operations/" target="_blank">List of Operations</a>
class ChangeTrustOperation extends Operation {
  Asset _asset;
  String _limit;

  ChangeTrustOperation(this._asset, this._limit);

  /// The asset of the trustline. For example, if a gateway extends a trustline of up to 200 USD to a user, the line is USD.
  Asset get asset => _asset;

  /// The limit of the trustline. For example, if a gateway extends a trustline of up to 200 USD to a user, the limit is 200.
  String get limit => _limit;

  @override
  XdrOperationBody toOperationBody() {
    XdrBigInt64 limit = new XdrBigInt64(Util.toXdrBigInt64Amount(this.limit));
    XdrChangeTrustOp op =
        new XdrChangeTrustOp(asset.toXdrChangeTrustAsset(), limit);

    XdrOperationBody body = new XdrOperationBody(XdrOperationType.CHANGE_TRUST);
    body.changeTrustOp = op;
    return body;
  }

  /// Builds ChangeTrust operation.
  static ChangeTrustOperationBuilder builder(XdrChangeTrustOp op) {
    return ChangeTrustOperationBuilder(
        Asset.fromXdr(op.line), Util.fromXdrBigInt64Amount(op.limit.bigInt));
  }
}

class ChangeTrustOperationBuilder {

  static const MAX_LIMIT = "922337203685.4775807";

  Asset _asset;
  String _limit;
  MuxedAccount? _mSourceAccount;

  /// Creates a new ChangeTrust builder.
  ChangeTrustOperationBuilder(this._asset, this._limit);

  /// Set source account of this operation.
  ChangeTrustOperationBuilder setSourceAccount(String sourceAccountId) {
    MuxedAccount? sa = MuxedAccount.fromAccountId(sourceAccountId);
    _mSourceAccount = checkNotNull(sa, "invalid sourceAccountId");
    return this;
  }

  /// Set muxed source account of this operation.
  ChangeTrustOperationBuilder setMuxedSourceAccount(
      MuxedAccount sourceAccount) {
    _mSourceAccount = sourceAccount;
    return this;
  }

  /// Builds the change trust operation.
  ChangeTrustOperation build() {
    ChangeTrustOperation operation = new ChangeTrustOperation(_asset, _limit);
    if (_mSourceAccount != null) {
      operation.sourceAccount = _mSourceAccount!;
    }
    return operation;
  }
}
