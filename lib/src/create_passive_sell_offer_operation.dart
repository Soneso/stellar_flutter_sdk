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

/// Creates a passive sell offer on the Stellar DEX.
///
/// CreatePassiveSellOffer creates an offer that does not take existing offers at the
/// same price. Unlike ManageSellOffer, passive offers will not immediately execute
/// against existing offers. They only execute when a new offer crosses them. This is
/// useful for market makers who want to provide liquidity without taking existing offers.
///
/// Use this operation when:
/// - Providing liquidity without immediately taking offers
/// - Creating maker-only orders
/// - Implementing market-making strategies
/// - Avoiding taking your own offers when creating markets
///
/// Important notes:
/// - Passive offers never take existing offers at the same price
/// - They only execute when a new offer crosses them
/// - Cannot update or delete passive offers (use ManageSellOffer to delete)
/// - Price is specified as amount of buying per unit of selling
/// - The source account must have sufficient balance of the selling asset
/// - Passive offers can be partially filled
///
/// Example:
/// ```dart
/// // Create a passive sell offer: sell 100 USD for XLM at 2.5 XLM per USD
/// var usd = AssetTypeCreditAlphaNum4("USD", issuerAccountId);
/// var passiveOffer = CreatePassiveSellOfferOperationBuilder(
///   usd,
///   Asset.native(),
///   "100.0",  // Sell 100 USD
///   "2.5"     // Price: 2.5 XLM per USD
/// ).build();
///
/// // Create with custom source account
/// var passiveOfferWithSource = CreatePassiveSellOfferOperationBuilder(
///   usd,
///   Asset.native(),
///   "100.0",
///   "2.5"
/// ).setSourceAccount(sourceAccountId).build();
/// ```
///
/// See also:
/// - [ManageSellOfferOperation] for regular sell offers that can take existing offers
/// - [ManageBuyOfferOperation] for creating buy offers
/// - [Operation] for general operation documentation
class CreatePassiveSellOfferOperation extends Operation {
  Asset _selling;
  Asset _buying;
  String _amount;
  String _price;

  /// Creates a CreatePassiveSellOffer operation.
  ///
  /// Parameters:
  /// - [_selling] Asset being offered for sale.
  /// - [_buying] Asset being purchased.
  /// - [_amount] Amount of selling asset to sell.
  /// - [_price] Price per unit of selling in terms of buying.
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

  /// Converts this operation to its XDR OperationBody representation.
  ///
  /// Returns: XDR OperationBody for this create passive sell offer operation.
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

  /// Constructs a CreatePassiveSellOfferOperationBuilder from XDR.
  ///
  /// Parameters:
  /// - [op] XDR CreatePassiveSellOfferOp to build from.
  ///
  /// Returns: Builder configured with XDR operation data.
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

/// Builder for constructing CreatePassiveSellOffer operations.
///
/// Provides a fluent interface for building CreatePassiveSellOffer operations with
/// optional parameters. Use this builder to create passive sell offers on the DEX.
///
/// Example:
/// ```dart
/// var operation = CreatePassiveSellOfferOperationBuilder(
///   sellingAsset,
///   buyingAsset,
///   "100.0",
///   "2.5"
/// ).setSourceAccount(sourceAccountId).build();
/// ```
class CreatePassiveSellOfferOperationBuilder {
  Asset _selling;
  Asset _buying;
  String _amount;
  String _price;
  MuxedAccount? _mSourceAccount;

  /// Creates a CreatePassiveSellOffer operation builder.
  ///
  /// Parameters:
  /// - [_selling] Asset being offered for sale.
  /// - [_buying] Asset being purchased.
  /// - [_amount] Amount of selling asset to sell.
  /// - [_price] Price per unit of selling in terms of buying.
  CreatePassiveSellOfferOperationBuilder(
      this._selling, this._buying, this._amount, this._price);

  /// Sets the source account for this operation.
  ///
  /// Parameters:
  /// - [sourceAccountId] Account ID of the operation source.
  ///
  /// Returns: This builder instance for method chaining.
  CreatePassiveSellOfferOperationBuilder setSourceAccount(
      String sourceAccountId) {
    MuxedAccount? sa = MuxedAccount.fromAccountId(sourceAccountId);
    _mSourceAccount = checkNotNull(sa, "invalid sourceAccountId");
    return this;
  }

  /// Sets the muxed source account for this operation.
  ///
  /// Parameters:
  /// - [sourceAccount] Muxed account to use as operation source.
  ///
  /// Returns: This builder instance for method chaining.
  CreatePassiveSellOfferOperationBuilder setMuxedSourceAccount(
      MuxedAccount sourceAccount) {
    _mSourceAccount = sourceAccount;
    return this;
  }

  /// Builds the CreatePassiveSellOffer operation.
  ///
  /// Returns: Configured CreatePassiveSellOfferOperation instance.
  CreatePassiveSellOfferOperation build() {
    CreatePassiveSellOfferOperation operation =
        new CreatePassiveSellOfferOperation(_selling, _buying, _amount, _price);
    if (_mSourceAccount != null) {
      operation.sourceAccount = _mSourceAccount;
    }
    return operation;
  }
}
