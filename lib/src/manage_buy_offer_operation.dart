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
import 'muxed_account.dart';

/// Creates, updates, or deletes a buy offer on the Stellar DEX.
///
/// ManageBuyOffer creates an offer to buy a specific amount of one asset in exchange
/// for another at a specified price. This is the buy-side equivalent of a limit order
/// on a traditional exchange. You specify how much you want to buy and at what price,
/// and the network matches it with compatible sell offers.
///
/// Use this operation when:
/// - Creating new buy orders on the DEX
/// - Updating existing buy offers
/// - Canceling buy offers (by setting amount to 0)
/// - Implementing trading functionality with guaranteed buy amounts
///
/// Important notes:
/// - Setting offerId to 0 creates a new offer
/// - Using an existing offerId updates or deletes that offer
/// - Setting amount to 0 deletes the offer
/// - Price is specified as amount of selling per unit of buying
/// - The source account must have sufficient balance of the selling asset
/// - Offers can be partially filled
///
/// Example:
/// ```dart
/// // Create a new buy offer: buy 100 EUR using USD at 1.1 USD per EUR
/// var usd = AssetTypeCreditAlphaNum4("USD", usdIssuer);
/// var eur = AssetTypeCreditAlphaNum4("EUR", eurIssuer);
/// var buyOffer = ManageBuyOfferOperationBuilder(
///   usd,
///   eur,
///   "100.0",  // Buy 100 EUR
///   "1.1"     // Price: 1.1 USD per EUR (pay up to 110 USD)
/// ).build();
///
/// // Update an existing offer
/// var updateOffer = ManageBuyOfferOperationBuilder(
///   usd,
///   eur,
///   "150.0",
///   "1.15"
/// ).setOfferId("12345").build();
///
/// // Cancel an offer
/// var cancelOffer = ManageBuyOfferOperationBuilder(
///   usd,
///   eur,
///   "0",      // Amount 0 cancels the offer
///   "1.1"
/// ).setOfferId("12345").build();
/// ```
///
/// See also:
/// - [ManageSellOfferOperation] for creating sell offers
/// - [CreatePassiveSellOfferOperation] for passive offers
/// - [Operation] for general operation documentation
class ManageBuyOfferOperation extends Operation {
  Asset _selling;
  Asset _buying;
  String _amount;
  String _price;
  String _offerId;

  /// Creates a ManageBuyOffer operation.
  ///
  /// Parameters:
  /// - [_selling] Asset being offered in exchange
  /// - [_buying] Asset being purchased
  /// - [_amount] Amount of buying asset to purchase (0 to delete offer)
  /// - [_price] Price per unit of buying in terms of selling
  /// - [_offerId] Offer ID (0 for new offer, existing ID to update/delete)
  ManageBuyOfferOperation(
      this._selling, this._buying, this._amount, this._price, this._offerId);

  /// The asset being sold in this operation
  Asset get selling => _selling;

  /// The asset being bought in this operation
  Asset get buying => _buying;

  /// Amount of selling being sold.
  String get amount => _amount;

  /// Price of 1 unit of selling in terms of buying.
  String get price => _price;

  /// The ID of the offer.
  String get offerId => _offerId;

  /// Converts this operation to its XDR OperationBody representation.
  ///
  /// Returns: XDR OperationBody for this manage buy offer operation.
  @override
  XdrOperationBody toOperationBody() {
    XdrBigInt64 amount =
        new XdrBigInt64(Util.toXdrBigInt64Amount(this.amount));
    Price price = Price.fromString(this.price);
    XdrUint64 offerId = new XdrUint64(int.parse(this.offerId));
    XdrManageBuyOfferOp op = new XdrManageBuyOfferOp(
        selling.toXdr(), buying.toXdr(), amount, price.toXdr(), offerId);

    XdrOperationBody body =
        new XdrOperationBody(XdrOperationType.MANAGE_BUY_OFFER);
    body.manageBuyOfferOp = op;

    return body;
  }

  /// Constructs a ManageBuyOfferOperationBuilder from XDR.
  ///
  /// Parameters:
  /// - [op] XDR ManageBuyOfferOp to build from
  ///
  /// Returns: Builder configured with XDR operation data
  static ManageBuyOfferOperationBuilder builder(XdrManageBuyOfferOp op) {
    int n = op.price.n.int32.toInt();
    int d = op.price.d.int32.toInt();

    return ManageBuyOfferOperationBuilder(
      Asset.fromXdr(op.selling),
      Asset.fromXdr(op.buying),
      Util.fromXdrBigInt64Amount(op.amount.bigInt),
      removeTailZero((BigInt.from(n) / BigInt.from(d)).toString()),
    ).setOfferId(op.offerID.uint64.toInt().toString());
  }
}

/// Builder for constructing ManageBuyOffer operations.
///
/// Provides a fluent interface for building ManageBuyOffer operations with optional
/// parameters. Use this builder to create, update, or delete buy offers on the DEX.
///
/// Example:
/// ```dart
/// // Create new buy offer
/// var operation = ManageBuyOfferOperationBuilder(
///   sellingAsset,
///   buyingAsset,
///   "100.0",
///   "1.1"
/// ).build();
///
/// // Update existing offer
/// var updateOperation = ManageBuyOfferOperationBuilder(
///   sellingAsset,
///   buyingAsset,
///   "150.0",
///   "1.15"
/// ).setOfferId("12345").build();
/// ```
class ManageBuyOfferOperationBuilder {
  Asset _selling;
  Asset _buying;
  String _amount;
  String _price;
  String _offerId = "0";
  MuxedAccount? _mSourceAccount;

  /// Creates a ManageBuyOffer operation builder.
  ///
  /// Parameters:
  /// - [_selling] Asset being offered in exchange
  /// - [_buying] Asset being purchased
  /// - [_amount] Amount of buying asset to purchase (0 to delete offer)
  /// - [_price] Price per unit of buying in terms of selling
  ///
  /// Note: Offer ID defaults to 0 (new offer). Use setOfferId to update existing offers.
  ManageBuyOfferOperationBuilder(
      this._selling, this._buying, this._amount, this._price);

  /// Sets the offer ID.
  ///
  /// Parameters:
  /// - [offerId] Offer ID (0 creates new offer, existing ID updates/deletes)
  ///
  /// Returns: This builder instance for method chaining
  ManageBuyOfferOperationBuilder setOfferId(String offerId) {
    this._offerId = offerId;
    return this;
  }

  /// Sets the source account for this operation.
  ///
  /// Parameters:
  /// - [sourceAccountId] Account ID of the operation source
  ///
  /// Returns: This builder instance for method chaining
  ManageBuyOfferOperationBuilder setSourceAccount(String sourceAccountId) {
    MuxedAccount? sa = MuxedAccount.fromAccountId(sourceAccountId);
    _mSourceAccount = checkNotNull(sa, "invalid sourceAccountId");
    return this;
  }

  /// Sets the muxed source account for this operation.
  ///
  /// Parameters:
  /// - [sourceAccount] Muxed account to use as operation source
  ///
  /// Returns: This builder instance for method chaining
  ManageBuyOfferOperationBuilder setMuxedSourceAccount(
      MuxedAccount sourceAccount) {
    _mSourceAccount = sourceAccount;
    return this;
  }

  /// Builds the ManageBuyOffer operation.
  ///
  /// Returns: Configured ManageBuyOfferOperation instance
  ManageBuyOfferOperation build() {
    ManageBuyOfferOperation operation = new ManageBuyOfferOperation(
        _selling, _buying, _amount, _price, _offerId);
    if (_mSourceAccount != null) {
      operation.sourceAccount = _mSourceAccount;
    }
    return operation;
  }
}
