// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'operation.dart';
import 'assets.dart';
import 'price.dart';
import 'util.dart';
import 'xdr/xdr_offer.dart';
import 'xdr/xdr_operation.dart';
import 'xdr/xdr_type.dart';
import 'muxed_account.dart';

/// Creates, updates, or deletes a sell offer on the Stellar DEX.
///
/// ManageSellOffer creates an offer to sell a specific amount of one asset for another
/// at a specified price. This is the sell-side equivalent of a limit order on a traditional
/// exchange. You specify how much you want to sell and at what price, and the network
/// matches it with compatible buy offers.
///
/// Use this operation when:
/// - Creating new sell orders on the DEX
/// - Updating existing sell offers
/// - Canceling sell offers (by setting amount to 0)
/// - Implementing trading functionality
///
/// Important notes:
/// - Setting offerId to 0 creates a new offer
/// - Using an existing offerId updates or deletes that offer
/// - Setting amount to 0 deletes the offer
/// - Price is specified as amount of buying per unit of selling
/// - The source account must have sufficient balance of the selling asset
/// - Offers can be partially filled
///
/// Example:
/// ```dart
/// // Create a new sell offer: sell 100 USD for XLM at 2.5 XLM per USD
/// var usd = AssetTypeCreditAlphaNum4("USD", issuerAccountId);
/// var sellOffer = ManageSellOfferOperationBuilder(
///   usd,
///   Asset.native(),
///   "100.0",  // Sell 100 USD
///   "2.5"     // Price: 2.5 XLM per USD
/// ).build();
///
/// // Update an existing offer
/// var updateOffer = ManageSellOfferOperationBuilder(
///   usd,
///   Asset.native(),
///   "150.0",
///   "2.6"
/// ).setOfferId("12345").build();
///
/// // Cancel an offer
/// var cancelOffer = ManageSellOfferOperationBuilder(
///   usd,
///   Asset.native(),
///   "0",      // Amount 0 cancels the offer
///   "2.5"
/// ).setOfferId("12345").build();
/// ```
///
/// See also:
/// - [ManageBuyOfferOperation] for creating buy offers
/// - [CreatePassiveSellOfferOperation] for passive offers
/// - [Operation] for general operation documentation
class ManageSellOfferOperation extends Operation {
  Asset _selling;
  Asset _buying;
  String _amount;
  String _price;
  String _offerId;

  /// Creates a ManageSellOffer operation.
  ///
  /// Parameters:
  /// - [_selling] - Asset being offered for sale
  /// - [_buying] - Asset being purchased
  /// - [_amount] - Amount of selling asset to sell (0 to delete offer)
  /// - [_price] - Price per unit of selling in terms of buying
  /// - [_offerId] - Offer ID (0 for new offer, existing ID to update/delete)
  ManageSellOfferOperation(
      this._selling, this._buying, this._amount, this._price, this._offerId);

  /// The asset being sold in this operation.
  Asset get selling => _selling;

  /// The asset being bought in this operation.
  Asset get buying => _buying;

  /// Amount of selling being sold.
  String get amount => _amount;

  /// Price of 1 unit of selling in terms of buying.
  String get price => _price;

  /// The ID of the offer.
  String get offerId => _offerId;

  @override
  XdrOperationBody toOperationBody() {
    XdrBigInt64 amount =
        new XdrBigInt64(Util.toXdrBigInt64Amount(this.amount));
    Price price = Price.fromString(this.price);
    XdrUint64 offerId = new XdrUint64(int.parse(this.offerId));

    XdrOperationBody body =
        new XdrOperationBody(XdrOperationType.MANAGE_SELL_OFFER);
    body.manageSellOfferOp = new XdrManageSellOfferOp(
        selling.toXdr(), buying.toXdr(), amount, price.toXdr(), offerId);
    ;

    return body;
  }

  /// Constructs a ManageSellOfferOperationBuilder from XDR.
  ///
  /// Parameters:
  /// - [op] - XDR ManageSellOfferOp to build from
  ///
  /// Returns: Builder configured with XDR operation data
  static ManageSellOfferOperationBuilder builder(XdrManageSellOfferOp op) {
    int n = op.price.n.int32.toInt();
    int d = op.price.d.int32.toInt();

    return ManageSellOfferOperationBuilder(
      Asset.fromXdr(op.selling),
      Asset.fromXdr(op.buying),
      Util.fromXdrBigInt64Amount(op.amount.bigInt),
      removeTailZero((BigInt.from(n) / BigInt.from(d)).toString()),
    ).setOfferId(op.offerID.uint64.toInt().toString());
  }
}

/// Builder for constructing ManageSellOffer operations.
///
/// Provides a fluent interface for building ManageSellOffer operations with optional
/// parameters. Use this builder to create, update, or delete sell offers on the DEX.
///
/// Example:
/// ```dart
/// // Create new sell offer
/// var operation = ManageSellOfferOperationBuilder(
///   sellingAsset,
///   buyingAsset,
///   "100.0",
///   "2.5"
/// ).build();
///
/// // Update existing offer
/// var updateOperation = ManageSellOfferOperationBuilder(
///   sellingAsset,
///   buyingAsset,
///   "150.0",
///   "2.6"
/// ).setOfferId("12345").build();
/// ```
class ManageSellOfferOperationBuilder {
  Asset _selling;
  Asset _buying;
  String _amount;
  String _price;
  String _offerId = "0";
  MuxedAccount? _mSourceAccount;

  /// Creates a ManageSellOffer operation builder.
  ///
  /// Parameters:
  /// - [_selling] - Asset being offered for sale
  /// - [_buying] - Asset being purchased
  /// - [_amount] - Amount of selling asset to sell (0 to delete offer)
  /// - [_price] - Price per unit of selling in terms of buying
  ///
  /// Note: Offer ID defaults to 0 (new offer). Use setOfferId to update existing offers.
  ManageSellOfferOperationBuilder(
      this._selling, this._buying, this._amount, this._price);

  /// Sets the offer ID.
  ///
  /// Parameters:
  /// - [offerId] - Offer ID (0 creates new offer, existing ID updates/deletes)
  ///
  /// Returns: This builder instance for method chaining
  ManageSellOfferOperationBuilder setOfferId(String offerId) {
    this._offerId = offerId;
    return this;
  }

  /// Sets the source account for this operation.
  ///
  /// Parameters:
  /// - [sourceAccountId] - Account ID of the operation source
  ///
  /// Returns: This builder instance for method chaining
  ManageSellOfferOperationBuilder setSourceAccount(String sourceAccountId) {
    MuxedAccount? sa = MuxedAccount.fromAccountId(sourceAccountId);
    _mSourceAccount = checkNotNull(sa, "invalid sourceAccountId");
    return this;
  }

  /// Sets the muxed source account for this operation.
  ///
  /// Parameters:
  /// - [sourceAccount] - Muxed account to use as operation source
  ///
  /// Returns: This builder instance for method chaining
  ManageSellOfferOperationBuilder setMuxedSourceAccount(
      MuxedAccount sourceAccount) {
    _mSourceAccount = sourceAccount;
    return this;
  }

  /// Builds the ManageSellOffer operation.
  ///
  /// Returns: Configured ManageSellOfferOperation instance
  ManageSellOfferOperation build() {
    ManageSellOfferOperation operation = new ManageSellOfferOperation(
        _selling, _buying, _amount, _price, _offerId);
    if (_mSourceAccount != null) {
      operation.sourceAccount = _mSourceAccount;
    }
    return operation;
  }
}
