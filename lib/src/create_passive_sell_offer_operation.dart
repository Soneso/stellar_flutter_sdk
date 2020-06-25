// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'operation.dart';
import 'assets.dart';
import 'util.dart';
import 'xdr/xdr_operation.dart';
import 'xdr/xdr_type.dart';
import 'xdr/xdr_offer.dart';
import 'price.dart';

/// Represents <a href="https://www.stellar.org/developers/learn/concepts/list-of-operations.html#create-passive-sell-offer" target="_blank">CreatePassiveSellOffer</a> operation.
// See: <a href="https://www.stellar.org/developers/learn/concepts/list-of-operations.html" target="_blank">List of Operations</a>
class CreatePassiveSellOfferOperation extends Operation {
  Asset _selling;
  Asset _buying;
  String _amount;
  String _price;

  CreatePassiveSellOfferOperation(
      Asset selling, Asset buying, String amount, String price) {
    this._selling = checkNotNull(selling, "selling cannot be null");
    this._buying = checkNotNull(buying, "buying cannot be null");
    this._amount = checkNotNull(amount, "amount cannot be null");
    this._price = checkNotNull(price, "price cannot be null");
  }

  /// The asset being sold in this operation
  Asset get selling => _selling;

  /// The asset being bought in this operation
  Asset get buying => _buying;

  /// Amount of selling being sold.
  String get amount => _amount;

  /// Price of 1 unit of selling in terms of buying.
  String get price => _price;

  @override
  XdrOperationBody toOperationBody() {
    XdrCreatePassiveSellOfferOp op = new XdrCreatePassiveSellOfferOp();
    op.selling = selling.toXdr();
    op.buying = buying.toXdr();
    XdrInt64 amount = new XdrInt64();
    amount.int64 = Operation.toXdrAmount(this.amount);
    op.amount = amount;
    Price price = Price.fromString(this.price);
    op.price = price.toXdr();

    XdrOperationBody body = new XdrOperationBody();
    body.discriminant = XdrOperationType.CREATE_PASSIVE_SELL_OFFER;
    body.createPassiveOfferOp = op;

    return body;
  }

  ///Construct a new CreatePassiveSellOffer builder from a CreatePassiveSellOfferOp XDR.
  static CreatePassiveSellOfferOperationBuilder builder(
      XdrCreatePassiveSellOfferOp op) {
    int n = op.price.n.int32;
    int d = op.price.d.int32;

    return CreatePassiveSellOfferOperationBuilder(
        Asset.fromXdr(op.selling),
        Asset.fromXdr(op.buying),
        Operation.fromXdrAmount(op.amount.int64),
        removeTailZero((BigInt.from(n) / BigInt.from(d)).toString()));
  }
}

class CreatePassiveSellOfferOperationBuilder {
  Asset _selling;
  Asset _buying;
  String _amount;
  String _price;
  String _mSourceAccount;

  /// Creates a new CreatePassiveSellOffer builder.
  CreatePassiveSellOfferOperationBuilder(
      Asset selling, Asset buying, String amount, String price) {
    this._selling = checkNotNull(selling, "selling cannot be null");
    this._buying = checkNotNull(buying, "buying cannot be null");
    this._amount = checkNotNull(amount, "amount cannot be null");
    this._price = checkNotNull(price, "price cannot be null");
  }

  /// Sets the source account for this operation.
  CreatePassiveSellOfferOperationBuilder setSourceAccount(
      String sourceAccount) {
    _mSourceAccount =
        checkNotNull(sourceAccount, "sourceAccount cannot be null");
    return this;
  }

  /// Builds a CreatePassiveSellOfferOperation.
  CreatePassiveSellOfferOperation build() {
    CreatePassiveSellOfferOperation operation =
        new CreatePassiveSellOfferOperation(_selling, _buying, _amount, _price);
    if (_mSourceAccount != null) {
      operation.sourceAccount = _mSourceAccount;
    }
    return operation;
  }
}
