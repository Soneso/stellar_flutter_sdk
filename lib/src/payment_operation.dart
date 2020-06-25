// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'operation.dart';
import 'assets.dart';
import 'key_pair.dart';
import 'util.dart';
import 'xdr/xdr_payment.dart';
import 'xdr/xdr_operation.dart';
import 'xdr/xdr_account.dart';
import 'xdr/xdr_type.dart';

/// Represents <a href="https://www.stellar.org/developers/learn/concepts/list-of-operations.html#payment" target="_blank">Payment</a> operation.
/// See: <a href="https://www.stellar.org/developers/learn/concepts/list-of-operations.html" target="_blank">List of Operations</a>
class PaymentOperation extends Operation {
  String _destination;
  Asset _asset;
  String _amount;

  PaymentOperation(String destination, Asset asset, String amount) {
    this._destination = checkNotNull(destination, "destination cannot be null");
    this._asset = checkNotNull(asset, "asset cannot be null");
    this._amount = checkNotNull(amount, "amount cannot be null");
  }

  /// Account that receives the payment.
  String get destination => _destination;

  /// Asset to send to the destination account.
  Asset get asset => _asset;

  /// Amount of the asset to send.
  String get amount => _amount;

  @override
  XdrOperationBody toOperationBody() {
    XdrPaymentOp op = XdrPaymentOp();

    // destination
    XdrAccountID destination = XdrAccountID();
    destination.accountID =
        KeyPair.fromAccountId(this._destination).xdrPublicKey;
    op.destination = destination;
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
    return PaymentOperationBuilder(
        KeyPair.fromXdrPublicKey(op.destination.accountID).accountId,
        Asset.fromXdr(op.asset),
        Operation.fromXdrAmount(op.amount.int64));
  }
}

class PaymentOperationBuilder {
  String _destination;
  Asset _asset;
  String _amount;
  String _mSourceAccount;

  /// Creates a PaymentOperation builder.
  /// [destinationAccountId] account id of the receiver.
  /// [asset] Asset to be sent.
  /// [amount] Amount to be sent.
  PaymentOperationBuilder(
      String destinationAccountId, Asset asset, String amount) {
    this._destination = destinationAccountId;
    this._asset = asset;
    this._amount = amount;
  }

  /// Sets the source account for this operation.
  PaymentOperationBuilder setSourceAccount(String sourceAccountId) {
    _mSourceAccount = sourceAccountId;
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
