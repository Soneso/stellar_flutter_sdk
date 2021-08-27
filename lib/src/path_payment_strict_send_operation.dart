// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:stellar_flutter_sdk/src/muxed_account.dart';

import 'operation.dart';
import 'assets.dart';
import 'key_pair.dart';
import 'util.dart';
import 'xdr/xdr_asset.dart';
import 'xdr/xdr_payment.dart';
import 'xdr/xdr_operation.dart';
import 'xdr/xdr_type.dart';

/// Represents <a href="https://developers.stellar.org/docs/start/list-of-operations/#path-payment-strict-send" target="_blank">PathPaymentStrictSend</a> operation.
/// @see <a href="https://developers.stellar.org/docs/start/list-of-operations/" target="_blank">List of Operations</a>
class PathPaymentStrictSendOperation extends Operation {
  Asset? _sendAsset;
  String? _sendAmount;
  MuxedAccount? _destination;
  Asset? _destAsset;
  String? _destMin;
  List<Asset?>? _path;

  PathPaymentStrictSendOperation(Asset? sendAsset, String? sendAmount, MuxedAccount? destination,
      Asset? destAsset, String? destMin, List<Asset?>? path) {
    this._sendAsset = checkNotNull(sendAsset, "sendAsset cannot be null");
    this._sendAmount = checkNotNull(sendAmount, "sendAmount cannot be null");
    this._destination = checkNotNull(destination, "destination cannot be null");
    this._destAsset = checkNotNull(destAsset, "destAsset cannot be null");
    this._destMin = checkNotNull(destMin, "destMin cannot be null");
    if (path == null) {
      // this._path = List<Asset>(0);
      this._path = []..length = 0;
    } else {
      checkArgument(path.length <= 5, "The maximum number of assets in the path is 5");
      this._path = path;
    }
  }

  /// The asset deducted from the sender's account.
  Asset? get sendAsset => _sendAsset;

  /// The amount of send asset to deduct (excluding fees)
  String? get sendAmount => _sendAmount;

  /// Account that receives the payment.
  MuxedAccount? get destination => _destination;

  /// The asset the destination account receives.
  Asset? get destAsset => _destAsset;

  /// The minimum amount of destination asset the destination account receives.
  String? get destMin => _destMin;

  /// The assets (other than send asset and destination asset) involved in the offers the path takes. For example, if you can only find a path from USD to EUR through XLM and BTC, the path would be USD -&raquo; XLM -&raquo; BTC -&raquo; EUR and the path would contain XLM and BTC.
  List<Asset?>? get path => _path;

  @override
  XdrOperationBody toOperationBody() {
    XdrPathPaymentStrictSendOp op = XdrPathPaymentStrictSendOp();

    // sendAsset
    op.sendAsset = sendAsset?.toXdr();
    // sendMax
    XdrInt64 sendMax = XdrInt64();
    sendMax.int64 = Operation.toXdrAmount(this.sendAmount!);
    op.sendMax = sendMax;
    // destination
    op.destination = this._destination?.toXdr();
    // destAsset
    op.destAsset = destAsset?.toXdr();
    // destAmount
    XdrInt64 destAmount = XdrInt64();
    destAmount.int64 = Operation.toXdrAmount(this.destMin!);
    op.destAmount = destAmount;
    // path
    // List<XdrAsset> path = List<XdrAsset>(this.path.length);
    List<XdrAsset> path = []..length = this.path!.length;
    for (int i = 0; i < this.path!.length; i++) {
      path[i] = this.path![i]!.toXdr();
    }
    op.path = path;

    XdrOperationBody body = XdrOperationBody();
    body.discriminant = XdrOperationType.PATH_PAYMENT_STRICT_SEND;
    body.pathPaymentStrictSendOp = op;
    return body;
  }

  /// Builds PathPayment operation.
  static PathPaymentStrictSendOperationBuilder builder(XdrPathPaymentStrictSendOp op) {
    // List<Asset> path = List<Asset>(op.path.length);
    List<Asset> path = []..length = op.path!.length;
    for (int i = 0; i < op.path!.length; i++) {
      path[i] = Asset.fromXdr(op.path![i]!);
    }
    return PathPaymentStrictSendOperationBuilder.forMuxedDestinationAccount(
            Asset.fromXdr(op.sendAsset!),
            Operation.fromXdrAmount(op.sendMax!.int64!),
            MuxedAccount.fromXdr(op.destination!),
            Asset.fromXdr(op.destAsset!),
            Operation.fromXdrAmount(op.destAmount!.int64!))
        .setPath(path);
  }
}

class PathPaymentStrictSendOperationBuilder {
  Asset? _sendAsset;
  String? _sendAmount;
  MuxedAccount? _destination;
  Asset? _destAsset;
  String? _destMin;
  List<Asset?>? _path;
  MuxedAccount? _mSourceAccount;

  /// Creates a PathPaymentStrictSendOperation builder.
  PathPaymentStrictSendOperationBuilder(
      Asset sendAsset, String sendAmount, String destination, Asset destAsset, String destMin) {
    this._sendAsset = checkNotNull(sendAsset, "sendAsset cannot be null");
    this._sendAmount = checkNotNull(sendAmount, "sendAmount cannot be null");
    checkNotNull(destination, "destination cannot be null");
    this._destination = MuxedAccount(destination, null);
    this._destAsset = checkNotNull(destAsset, "destAsset cannot be null");
    this._destMin = checkNotNull(destMin, "destMin cannot be null");
  }

  /// Creates a PathPaymentStrictSendOperation builder for a MuxedAccount as a destination.
  PathPaymentStrictSendOperationBuilder.forMuxedDestinationAccount(Asset sendAsset,
      String sendAmount, MuxedAccount? destination, Asset destAsset, String destMin) {
    this._sendAsset = checkNotNull(sendAsset, "sendAsset cannot be null");
    this._sendAmount = checkNotNull(sendAmount, "sendAmount cannot be null");
    checkNotNull(destination, "destination cannot be null");
    this._destination = destination;
    this._destAsset = checkNotNull(destAsset, "destAsset cannot be null");
    this._destMin = checkNotNull(destMin, "destMin cannot be null");
  }

  /// Sets path for this operation
  PathPaymentStrictSendOperationBuilder setPath(List<Asset?> path) {
    checkNotNull(path, "path cannot be null");
    checkArgument(path.length <= 5, "The maximum number of assets in the path is 5");
    this._path = path;
    return this;
  }

  /// Sets the source account for this operation.
  PathPaymentStrictSendOperationBuilder setSourceAccount(String sourceAccount) {
    checkNotNull(sourceAccount, "sourceAccount cannot be null");
    _mSourceAccount = MuxedAccount(sourceAccount, null);
    return this;
  }

  /// Sets the muxed source account for this operation.
  PathPaymentStrictSendOperationBuilder setMuxedSourceAccount(MuxedAccount? sourceAccount) {
    checkNotNull(sourceAccount, "sourceAccount cannot be null");
    _mSourceAccount = sourceAccount;
    return this;
  }

  /// Builds a PathPaymentStrictSendOperation.
  PathPaymentStrictSendOperation build() {
    PathPaymentStrictSendOperation operation = PathPaymentStrictSendOperation(
        _sendAsset, _sendAmount, _destination, _destAsset, _destMin, _path);
    if (_mSourceAccount != null) {
      operation.sourceAccount = _mSourceAccount;
    }
    return operation;
  }
}
