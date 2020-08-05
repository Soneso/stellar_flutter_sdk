// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'operation.dart';
import 'assets.dart';
import 'key_pair.dart';
import 'util.dart';
import 'muxed_account.dart';
import 'xdr/xdr_payment.dart';
import 'xdr/xdr_operation.dart';
import 'xdr/xdr_type.dart';

/// Represents <a href="https://developers.stellar.org/docs/start/list-of-operations/#payment" target="_blank">Payment</a> operation.
/// See: <a href="https://developers.stellar.org/docs/start/list-of-operations/" target="_blank">List of Operations</a>
class PaymentOperation extends Operation {
  MuxedAccount _destination;
  Asset _asset;
  String _amount;

  PaymentOperation(MuxedAccount destination, Asset asset, String amount) {
    this._destination = checkNotNull(destination, "destination cannot be null");
    this._asset = checkNotNull(asset, "asset cannot be null");
    this._amount = checkNotNull(amount, "amount cannot be null");
  }

  /// Account that receives the payment.
  MuxedAccount get destination => _destination;

  /// Asset to send to the destination account.
  Asset get asset => _asset;

  /// Amount of the asset to send.
  String get amount => _amount;

  @override
  XdrOperationBody toOperationBody() {
    XdrPaymentOp op = XdrPaymentOp();

    // destination
    op.destination = this._destination.toXdr();
    // asset
    op.asset = asset.toXdr();
    // amount
    XdrInt64 amount = XdrInt64();
    amount.int64 = Operation.toXdrAmount(this.amount);
    op.amount = amount;

    XdrOperationBody body = XdrOperationBody();
    body.discriminant = XdrOperationType.PAYMENT;
    body.paymentOp = op;
    return body;
  }

  /// Builds Payment operation.
  static PaymentOperationBuilder builder(XdrPaymentOp op) {
    return PaymentOperationBuilder.forMuxedDestinationAccount(
        MuxedAccount.fromXdr(op.destination),
        Asset.fromXdr(op.asset),
        Operation.fromXdrAmount(op.amount.int64));
  }
}

class PaymentOperationBuilder {
  MuxedAccount _destination;
  Asset _asset;
  String _amount;
  MuxedAccount _mSourceAccount;

  /// Creates a PaymentOperation builder.
  /// [destinationAccountId] account id of the receiver.
  /// [asset] Asset to be sent.
  /// [amount] Amount to be sent.
  PaymentOperationBuilder(
      String destinationAccountId, Asset asset, String amount) {
    this._destination = MuxedAccount(destinationAccountId, null);
    this._asset = asset;
    this._amount = amount;
  }

  /// Creates a PaymentOperation builder using a MuxedAccount as a destination.
  /// [destinationAccount] MuxedAccount having the accountId of the receiver.
  /// [asset] Asset to be sent.
  /// [amount] Amount to be sent.
  PaymentOperationBuilder.forMuxedDestinationAccount(
      MuxedAccount destinationAccount, Asset asset, String amount) {
    this._destination = destinationAccount;
    this._asset = asset;
    this._amount = amount;
  }

  /// Sets the source account for this operation.
  PaymentOperationBuilder setSourceAccount(String sourceAccountId) {
    _mSourceAccount = MuxedAccount(sourceAccountId, null);
    return this;
  }

  PaymentOperationBuilder setMuxedSourceAccount(MuxedAccount sourceAccount) {
    _mSourceAccount = sourceAccount;
    return this;
  }

  ///Builds an operation
  PaymentOperation build() {
    PaymentOperation operation =
        PaymentOperation(_destination, _asset, _amount);
    if (_mSourceAccount != null) {
      operation.sourceAccount = _mSourceAccount;
    }
    return operation;
  }
}
