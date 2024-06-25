// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:stellar_flutter_sdk/src/muxed_account.dart';

import 'operation.dart';
import 'assets.dart';
import 'util.dart';
import 'xdr/xdr_operation.dart';
import 'xdr/xdr_type.dart';
import 'xdr/xdr_offer.dart';
import 'price.dart';

/// Represents <a href="https://developers.stellar.org/docs/start/list-of-operations/#create-passive-sell-offer" target="_blank">CreatePassiveSellOffer</a> operation.
// See: <a href="https://developers.stellar.org/docs/start/list-of-operations/" target="_blank">List of Operations</a>
class CreatePassiveSellOfferOperation extends Operation {
  Asset _selling;
  Asset _buying;
  String _amount;
  String _price;

  CreatePassiveSellOfferOperation(
      this._selling, this._buying, this._amount, this._price);

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
    var amount = new XdrBigInt64(Util.toXdrBigInt64Amount(this.amount));
    var price = Price.fromString(this.price);
    XdrOperationBody body =
        new XdrOperationBody(XdrOperationType.CREATE_PASSIVE_SELL_OFFER);
    body.createPassiveOfferOp = new XdrCreatePassiveSellOfferOp(
        selling.toXdr(), buying.toXdr(), amount, price.toXdr());

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
        Util.fromXdrBigInt64Amount(op.amount.bigInt),
        removeTailZero((BigInt.from(n) / BigInt.from(d)).toString()));
  }
}

class CreatePassiveSellOfferOperationBuilder {
  Asset _selling;
  Asset _buying;
  String _amount;
  String _price;
  MuxedAccount? _mSourceAccount;

  /// Creates a new CreatePassiveSellOffer builder.
  CreatePassiveSellOfferOperationBuilder(
      this._selling, this._buying, this._amount, this._price);

  /// Sets the source account for this operation.
  CreatePassiveSellOfferOperationBuilder setSourceAccount(
      String sourceAccountId) {
    MuxedAccount? sa = MuxedAccount.fromAccountId(sourceAccountId);
    _mSourceAccount = checkNotNull(sa, "invalid sourceAccountId");
    return this;
  }

  /// Sets the muxed source account for this operation.
  CreatePassiveSellOfferOperationBuilder setMuxedSourceAccount(
      MuxedAccount sourceAccount) {
    _mSourceAccount = sourceAccount;
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
