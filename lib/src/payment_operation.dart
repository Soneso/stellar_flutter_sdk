// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'operation.dart';
import 'assets.dart';
import 'util.dart';
import 'muxed_account.dart';
import 'xdr/xdr_payment.dart';
import 'xdr/xdr_operation.dart';
import 'xdr/xdr_type.dart';

/// Sends a payment of a specified asset to a destination account.
///
/// The Payment operation sends an amount of a specific asset to a destination account.
/// This is the most common operation for transferring value on the Stellar network.
/// The destination account must already exist and must have a trustline for the asset
/// if it's not the native asset (XLM).
///
/// Use this operation when:
/// - Sending payments between user accounts
/// - Transferring assets in your application
/// - Making peer-to-peer transfers
/// - Implementing payment flows
///
/// Important notes:
/// - The destination account must already exist (use CreateAccountOperation for new accounts)
/// - For non-native assets, the destination must have a trustline
/// - The source account must have sufficient balance to cover the payment
/// - The payment amount must be positive
///
/// Example:
/// ```dart
/// // Send 100 XLM to another account
/// var payment = PaymentOperationBuilder(
///   destinationAccountId,
///   Asset.native(),
///   "100.0"
/// ).build();
///
/// // Send custom asset with specific source
/// var customAsset = AssetTypeCreditAlphaNum4("USD", issuerAccountId);
/// var paymentWithSource = PaymentOperationBuilder(
///   destinationAccountId,
///   customAsset,
///   "50.0"
/// ).setSourceAccount(sourceAccountId).build();
///
/// // Add to transaction
/// var transaction = TransactionBuilder(sourceAccount)
///   .addOperation(payment)
///   .build();
/// ```
///
/// See also:
/// - [PathPaymentStrictReceiveOperation] for path payments with exact receive amount
/// - [PathPaymentStrictSendOperation] for path payments with exact send amount
/// - [CreateAccountOperation] for creating and funding new accounts
/// - [Operation] for general operation documentation
class PaymentOperation extends Operation {
  MuxedAccount _destination;
  Asset _asset;
  String _amount;

  /// Creates a Payment operation.
  ///
  /// Parameters:
  /// - [_destination] - Muxed account that receives the payment
  /// - [_asset] - Asset to send
  /// - [_amount] - Amount of the asset to send
  PaymentOperation(this._destination, this._asset, this._amount);

  /// Account that receives the payment.
  MuxedAccount get destination => _destination;

  /// Asset to send to the destination account.
  Asset get asset => _asset;

  /// Amount of the asset to send.
  String get amount => _amount;

  @override
  XdrOperationBody toOperationBody() {
    // amount
    XdrBigInt64 amount = XdrBigInt64(Util.toXdrBigInt64Amount(this.amount));

    XdrPaymentOp op =
        XdrPaymentOp(this._destination.toXdr(), asset.toXdr(), amount);

    XdrOperationBody body = XdrOperationBody(XdrOperationType.PAYMENT);
    body.paymentOp = op;
    return body;
  }

  /// Constructs a PaymentOperationBuilder from XDR.
  ///
  /// Parameters:
  /// - [op] - XDR PaymentOp to build from
  ///
  /// Returns: Builder configured with XDR operation data
  static PaymentOperationBuilder builder(XdrPaymentOp op) {
    return PaymentOperationBuilder.forMuxedDestinationAccount(
        MuxedAccount.fromXdr(op.destination),
        Asset.fromXdr(op.asset),
        Util.fromXdrBigInt64Amount(op.amount.bigInt));
  }
}

/// Builder for constructing Payment operations.
///
/// Provides a fluent interface for building Payment operations with optional
/// parameters. Supports both regular account IDs and muxed accounts as destinations.
///
/// Example:
/// ```dart
/// // Using account ID
/// var operation = PaymentOperationBuilder(
///   destinationAccountId,
///   Asset.native(),
///   "100.0"
/// ).setSourceAccount(sourceAccountId).build();
///
/// // Using muxed account
/// var operation = PaymentOperationBuilder.forMuxedDestinationAccount(
///   muxedDestination,
///   asset,
///   "50.0"
/// ).build();
/// ```
class PaymentOperationBuilder {
  late MuxedAccount _destination;
  Asset _asset;
  String _amount;
  MuxedAccount? _mSourceAccount;

  /// Creates a Payment operation builder with an account ID destination.
  ///
  /// Parameters:
  /// - [destinationAccountId] - Account ID of the payment receiver
  /// - [_asset] - Asset to be sent
  /// - [_amount] - Amount of the asset to send
  PaymentOperationBuilder(
      String destinationAccountId, this._asset, this._amount) {
    MuxedAccount? dest = MuxedAccount.fromAccountId(destinationAccountId);
    this._destination = checkNotNull(dest, "invalid destinationAccountId");
  }

  /// Creates a Payment operation builder with a muxed account destination.
  ///
  /// Parameters:
  /// - [_destination] - Muxed account of the payment receiver
  /// - [_asset] - Asset to be sent
  /// - [_amount] - Amount of the asset to send
  PaymentOperationBuilder.forMuxedDestinationAccount(
      this._destination, this._asset, this._amount);

  /// Sets the source account for this operation.
  ///
  /// Parameters:
  /// - [sourceAccountId] - Account ID of the operation source
  ///
  /// Returns: This builder instance for method chaining
  PaymentOperationBuilder setSourceAccount(String sourceAccountId) {
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
  PaymentOperationBuilder setMuxedSourceAccount(MuxedAccount sourceAccount) {
    _mSourceAccount = sourceAccount;
    return this;
  }

  /// Builds the Payment operation.
  ///
  /// Returns: Configured PaymentOperation instance
  PaymentOperation build() {
    PaymentOperation operation =
        PaymentOperation(_destination, _asset, _amount);
    if (_mSourceAccount != null) {
      operation.sourceAccount = _mSourceAccount;
    }
    return operation;
  }
}
