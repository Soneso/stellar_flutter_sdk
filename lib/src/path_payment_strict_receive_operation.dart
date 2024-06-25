// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:stellar_flutter_sdk/src/muxed_account.dart';

import 'operation.dart';
import 'assets.dart';
import 'util.dart';
import 'xdr/xdr_asset.dart';
import 'xdr/xdr_operation.dart';
import 'xdr/xdr_payment.dart';
import 'xdr/xdr_type.dart';

/// Represents <a href="https://developers.stellar.org/docs/start/list-of-operations/#path-payment-strict-receive" target="_blank">PathPaymentStrictReceive</a> operation.
/// See: <a href="https://developers.stellar.org/docs/start/list-of-operations/" target="_blank">List of Operations</a>
class PathPaymentStrictReceiveOperation extends Operation {
  Asset _sendAsset;
  String _sendMax;
  MuxedAccount _destination;
  Asset _destAsset;
  String _destAmount;
  late List<Asset> _path;

  PathPaymentStrictReceiveOperation(this._sendAsset, this._sendMax,
      this._destination, this._destAsset, this._destAmount, List<Asset>? path) {
    if (path == null) {
      this._path = List<Asset>.empty(growable: true);
    } else {
      checkArgument(
          path.length <= 5, "The maximum number of assets in the path is 5");
      this._path = path;
    }
  }

  /// The asset deducted from the sender's account.
  Asset get sendAsset => _sendAsset;

  /// The maximum amount of send asset to deduct (excluding fees)
  String get sendMax => _sendMax;

  /// Account that receives the payment.
  MuxedAccount get destination => _destination;

  /// The asset the destination account receives.
  Asset get destAsset => _destAsset;

  /// The amount of destination asset the destination account receives.
  String get destAmount => _destAmount;

  /// The assets (other than send asset and destination asset) involved in the offers the path takes. For example, if you can only find a path from USD to EUR through XLM and BTC, the path would be USD -&raquo; XLM -&raquo; BTC -&raquo; EUR and the path would contain XLM and BTC.
  List<Asset> get path => _path;

  @override
  XdrOperationBody toOperationBody() {
    // sendMax
    XdrBigInt64 sendMax = XdrBigInt64(Util.toXdrBigInt64Amount(this.sendMax));

    // destAmount
    XdrBigInt64 destAmount = XdrBigInt64(Util.toXdrBigInt64Amount(this.destAmount));

    // path
    List<XdrAsset> path = List<XdrAsset>.empty(growable: true);
    for (int i = 0; i < this.path.length; i++) {
      path.add(this.path[i].toXdr());
    }
    XdrPathPaymentStrictReceiveOp op = XdrPathPaymentStrictReceiveOp(
        sendAsset.toXdr(),
        sendMax,
        this._destination.toXdr(),
        destAsset.toXdr(),
        destAmount,
        path);

    XdrOperationBody body =
        XdrOperationBody(XdrOperationType.PATH_PAYMENT_STRICT_RECEIVE);
    body.pathPaymentStrictReceiveOp = op;
    return body;
  }

  /// Builds PathPaymentStrictReceiveOperation operation.
  static PathPaymentStrictReceiveOperationBuilder builder(
      XdrPathPaymentStrictReceiveOp op) {
    List<Asset> path = List<Asset>.empty(growable: true);
    for (int i = 0; i < op.path.length; i++) {
      path.add(Asset.fromXdr(op.path[i]));
    }
    return PathPaymentStrictReceiveOperationBuilder.forMuxedDestinationAccount(
            Asset.fromXdr(op.sendAsset),
            Util.fromXdrBigInt64Amount(op.sendMax.bigInt),
            MuxedAccount.fromXdr(op.destination),
            Asset.fromXdr(op.destAsset),
            Util.fromXdrBigInt64Amount(op.destAmount.bigInt))
        .setPath(path);
  }
}

class PathPaymentStrictReceiveOperationBuilder {
  Asset _sendAsset;
  String _sendMax;
  late MuxedAccount _destination;
  Asset _destAsset;
  String _destAmount;
  List<Asset> _path = List<Asset>.empty(growable: true);
  MuxedAccount? _mSourceAccount;

  /// Creates a PathPaymentStrictReceiveOperation builder.
  PathPaymentStrictReceiveOperationBuilder(this._sendAsset, this._sendMax,
      String destinationAccountId, this._destAsset, this._destAmount) {
    MuxedAccount? da = MuxedAccount.fromAccountId(destinationAccountId);
    checkNotNull(da, "invalid destinationAccountId");
    this._destination = da!;
  }

  /// Creates a PathPaymentStrictReceiveOperation builder for a MuxedAccount as a destination.
  PathPaymentStrictReceiveOperationBuilder.forMuxedDestinationAccount(
      this._sendAsset,
      this._sendMax,
      this._destination,
      this._destAsset,
      this._destAmount);

  /// Sets path for this operation
  PathPaymentStrictReceiveOperationBuilder setPath(List<Asset> path) {
    checkArgument(
        path.length <= 5, "The maximum number of assets in the path is 5");
    this._path = path;
    return this;
  }

  /// Sets the source account for this operation.
  PathPaymentStrictReceiveOperationBuilder setSourceAccount(
      String sourceAccountId) {
    MuxedAccount? sa = MuxedAccount.fromAccountId(sourceAccountId);
    _mSourceAccount = checkNotNull(sa, "invalid sourceAccountId");
    return this;
  }

  /// Sets the muxed source account for this operation.
  PathPaymentStrictReceiveOperationBuilder setMuxedSourceAccount(
      MuxedAccount sourceAccount) {
    _mSourceAccount = sourceAccount;
    return this;
  }

  /// Builds a PathPaymentStrictReceiveOperation.
  PathPaymentStrictReceiveOperation build() {
    PathPaymentStrictReceiveOperation operation =
        PathPaymentStrictReceiveOperation(
            _sendAsset, _sendMax, _destination, _destAsset, _destAmount, _path);
    if (_mSourceAccount != null) {
      operation.sourceAccount = _mSourceAccount;
    }
    return operation;
  }
}
