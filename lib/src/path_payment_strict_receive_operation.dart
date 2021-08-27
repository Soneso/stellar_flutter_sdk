// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:stellar_flutter_sdk/src/muxed_account.dart';

import 'operation.dart';
import 'assets.dart';
import 'key_pair.dart';
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
  List<Asset> _path;

  PathPaymentStrictReceiveOperation(Asset sendAsset, String sendMax, MuxedAccount destination,
      Asset destAsset, String destAmount, List<Asset> path) {
    this._sendAsset = checkNotNull(sendAsset, "sendAsset cannot be null");
    this._sendMax = checkNotNull(sendMax, "sendMax cannot be null");
    this._destination = checkNotNull(destination, "destination cannot be null");
    this._destAsset = checkNotNull(destAsset, "destAsset cannot be null");
    this._destAmount = checkNotNull(destAmount, "destAmount cannot be null");
    if (path == null) {
      this._path = List<Asset>(0);
    } else {
      checkArgument(path.length <= 5, "The maximum number of assets in the path is 5");
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
    XdrPathPaymentStrictReceiveOp op = XdrPathPaymentStrictReceiveOp();

    // sendAsset
    op.sendAsset = sendAsset.toXdr();
    // sendMax
    XdrInt64 sendMax = XdrInt64();
    sendMax.int64 = Operation.toXdrAmount(this.sendMax);
    op.sendMax = sendMax;
    // destination
    op.destination = this._destination.toXdr();
    // destAsset
    op.destAsset = destAsset.toXdr();
    // destAmount
    XdrInt64 destAmount = XdrInt64();
    destAmount.int64 = Operation.toXdrAmount(this.destAmount);
    op.destAmount = destAmount;
    // path
    List<XdrAsset> path = List<XdrAsset>(this.path.length);
    for (int i = 0; i < this.path.length; i++) {
      path[i] = this.path[i].toXdr();
    }
    op.path = path;

    XdrOperationBody body = XdrOperationBody();
    body.discriminant = XdrOperationType.PATH_PAYMENT_STRICT_RECEIVE;
    body.pathPaymentStrictReceiveOp = op;
    return body;
  }

  /// Builds PathPaymentStrictReceiveOperation operation.
  static PathPaymentStrictReceiveOperationBuilder builder(XdrPathPaymentStrictReceiveOp op) {
    List<Asset> path = List<Asset>(op.path.length);
    for (int i = 0; i < op.path.length; i++) {
      path[i] = Asset.fromXdr(op.path[i]);
    }
    return PathPaymentStrictReceiveOperationBuilder.forMuxedDestinationAccount(
            Asset.fromXdr(op.sendAsset),
            Operation.fromXdrAmount(op.sendMax.int64),
            MuxedAccount.fromXdr(op.destination),
            Asset.fromXdr(op.destAsset),
            Operation.fromXdrAmount(op.destAmount.int64))
        .setPath(path);
  }
}

class PathPaymentStrictReceiveOperationBuilder {
  Asset? _sendAsset;
  String? _sendMax;
  MuxedAccount? _destination;
  Asset? _destAsset;
  String? _destAmount;
  List<Asset?>? _path;
  MuxedAccount? _mSourceAccount;

  /// Creates a PathPaymentStrictReceiveOperation builder.
  PathPaymentStrictReceiveOperationBuilder(
      Asset sendAsset, String sendMax, String destination, Asset destAsset, String destAmount) {
    this._sendAsset = checkNotNull(sendAsset, "sendAsset cannot be null");
    this._sendMax = checkNotNull(sendMax, "sendMax cannot be null");
    checkNotNull(destination, "destination cannot be null");
    this._destination = MuxedAccount(destination, null);
    this._destAsset = checkNotNull(destAsset, "destAsset cannot be null");
    this._destAmount = checkNotNull(destAmount, "destAmount cannot be null");
  }

  /// Creates a PathPaymentStrictReceiveOperation builder for a MuxedAccount as a destination.
  PathPaymentStrictReceiveOperationBuilder.forMuxedDestinationAccount(Asset sendAsset,
      String sendMax, MuxedAccount? destination, Asset destAsset, String destAmount) {
    this._sendAsset = checkNotNull(sendAsset, "sendAsset cannot be null");
    this._sendMax = checkNotNull(sendMax, "sendMax cannot be null");
    this._destination = checkNotNull(destination, "destination cannot be null");
    this._destAsset = checkNotNull(destAsset, "destAsset cannot be null");
    this._destAmount = checkNotNull(destAmount, "destAmount cannot be null");
  }

  /// Sets path for this operation
  PathPaymentStrictReceiveOperationBuilder setPath(List<Asset?> path) {
    checkNotNull(path, "path cannot be null");
    checkArgument(path.length <= 5, "The maximum number of assets in the path is 5");
    this._path = path;
    return this;
  }

  /// Sets the source account for this operation.
  PathPaymentStrictReceiveOperationBuilder setSourceAccount(String sourceAccount) {
    checkNotNull(sourceAccount, "sourceAccount cannot be null");
    _mSourceAccount = MuxedAccount(sourceAccount, null);
    return this;
  }

  /// Sets the muxed source account for this operation.
  PathPaymentStrictReceiveOperationBuilder setMuxedSourceAccount(MuxedAccount? sourceAccount) {
    _mSourceAccount = checkNotNull(sourceAccount, "sourceAccount cannot be null");
    return this;
  }

  /// Builds a PathPaymentStrictReceiveOperation.
  PathPaymentStrictReceiveOperation build() {
    PathPaymentStrictReceiveOperation operation = PathPaymentStrictReceiveOperation(
        _sendAsset, _sendMax, _destination, _destAsset, _destAmount, _path);
    if (_mSourceAccount != null) {
      operation.sourceAccount = _mSourceAccount;
    }
    return operation;
  }
}
