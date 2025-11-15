// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:stellar_flutter_sdk/src/muxed_account.dart';

import 'operation.dart';
import 'assets.dart';
import 'util.dart';
import 'xdr/xdr_asset.dart';
import 'xdr/xdr_payment.dart';
import 'xdr/xdr_operation.dart';
import 'xdr/xdr_type.dart';

/// Sends a payment through a path, specifying the exact amount to send.
///
/// PathPaymentStrictSend allows you to send one asset and have the recipient receive
/// a different asset through automatic conversion along a path of offers. You specify
/// the exact amount to send, and the network determines how much the destination will
/// receive (with a guaranteed minimum specified by destMin).
///
/// Use this operation when:
/// - Converting assets during payment
/// - Guaranteeing a specific send amount
/// - Using the DEX for automatic asset conversion
/// - Implementing cross-asset payments with known source amount
///
/// Important notes:
/// - The source pays exactly the specified amount
/// - The destination receives at least destMin (or the operation fails)
/// - The path can contain up to 5 intermediate assets
/// - Operation fails if the conversion results in less than destMin
/// - The destination must have appropriate trustlines for the received asset
///
/// Example:
/// ```dart
/// // Convert exactly 100 USD to EUR, expecting at least 90 EUR
/// var usd = AssetTypeCreditAlphaNum4("USD", usdIssuer);
/// var eur = AssetTypeCreditAlphaNum4("EUR", eurIssuer);
/// var xlm = Asset.native();
///
/// var pathPayment = PathPaymentStrictSendOperationBuilder(
///   usd,           // Send USD
///   "100",         // Send exactly 100 USD
///   destinationId, // Recipient account
///   eur,           // Receive EUR
///   "90"           // Receive at least 90 EUR
/// ).setPath([xlm]).build(); // Convert through XLM
///
/// // Direct conversion without intermediate assets
/// var directPayment = PathPaymentStrictSendOperationBuilder(
///   usd,
///   "100",
///   destinationId,
///   eur,
///   "90"
/// ).build();
/// ```
///
/// See also:
/// - [PathPaymentStrictReceiveOperation] for specifying exact receive amount instead
/// - [PaymentOperation] for simple same-asset payments
/// - [Operation] for general operation documentation
class PathPaymentStrictSendOperation extends Operation {
  Asset _sendAsset;
  String _sendAmount;
  MuxedAccount _destination;
  Asset _destAsset;
  String _destMin;
  late List<Asset> _path;

  /// Creates a PathPaymentStrictSend operation.
  ///
  /// Parameters:
  /// - [_sendAsset] Asset to be sent
  /// - [_sendAmount] Exact amount of sendAsset to be sent
  /// - [_destination] Muxed account receiving the payment
  /// - [_destAsset] Asset to be received
  /// - [_destMin] Minimum amount of destAsset to be received
  /// - [path] Optional list of assets for conversion path (max 5)
  PathPaymentStrictSendOperation(this._sendAsset, this._sendAmount,
      this._destination, this._destAsset, this._destMin, List<Asset>? path) {
    if (path == null) {
      this._path = List<Asset>.empty(growable: true);
    } else {
      checkArgument(
          path.length <= 5, "The maximum number of assets in the path is 5");
      this._path = path;
    }
  }

  /// The asset deducted from the sender's account.
  Asset get sendAsset => _sendAsset;

  /// The amount of send asset to deduct (excluding fees)
  String get sendAmount => _sendAmount;

  /// Account that receives the payment.
  MuxedAccount get destination => _destination;

  /// The asset the destination account receives.
  Asset get destAsset => _destAsset;

  /// The minimum amount of destination asset the destination account receives.
  String get destMin => _destMin;

  /// The intermediate assets involved in the conversion path.
  ///
  /// Contains the assets (other than send asset and destination asset) involved
  /// in the offers the path takes. For example, if you can only find a path from
  /// USD to EUR through XLM and BTC, the path would be USD -> XLM -> BTC -> EUR
  /// and this list would contain XLM and BTC.
  List<Asset> get path => _path;

  /// Converts this operation to its XDR OperationBody representation.
  ///
  /// Returns: XDR OperationBody for this path payment strict send operation.
  @override
  XdrOperationBody toOperationBody() {
    // sendMax
    XdrBigInt64 sendMax = XdrBigInt64(Util.toXdrBigInt64Amount(this.sendAmount));

    // destAmount
    XdrBigInt64 destAmount = XdrBigInt64(Util.toXdrBigInt64Amount(this.destMin));

    // path
    List<XdrAsset> path = List<XdrAsset>.empty(growable: true);
    for (int i = 0; i < this.path.length; i++) {
      path.add(this.path[i].toXdr());
    }
    XdrPathPaymentStrictSendOp op = XdrPathPaymentStrictSendOp(
        sendAsset.toXdr(),
        sendMax,
        this._destination.toXdr(),
        destAsset.toXdr(),
        destAmount,
        path);

    XdrOperationBody body =
        XdrOperationBody(XdrOperationType.PATH_PAYMENT_STRICT_SEND);
    body.pathPaymentStrictSendOp = op;
    return body;
  }

  /// Constructs a PathPaymentStrictSendOperationBuilder from XDR.
  ///
  /// Parameters:
  /// - [op] XDR PathPaymentStrictSendOp to build from
  ///
  /// Returns: Builder configured with XDR operation data
  static PathPaymentStrictSendOperationBuilder builder(
      XdrPathPaymentStrictSendOp op) {
    List<Asset> path = List<Asset>.empty(growable: true);
    for (int i = 0; i < op.path.length; i++) {
      path.add(Asset.fromXdr(op.path[i]));
    }
    return PathPaymentStrictSendOperationBuilder.forMuxedDestinationAccount(
            Asset.fromXdr(op.sendAsset),
            Util.fromXdrBigInt64Amount(op.sendMax.bigInt),
            MuxedAccount.fromXdr(op.destination),
            Asset.fromXdr(op.destAsset),
            Util.fromXdrBigInt64Amount(op.destAmount.bigInt))
        .setPath(path);
  }
}

/// Builder for constructing PathPaymentStrictSend operations.
///
/// Provides a fluent interface for building PathPaymentStrictSend operations
/// with optional parameters. Supports both regular account IDs and muxed accounts
/// as destinations.
///
/// Example:
/// ```dart
/// var operation = PathPaymentStrictSendOperationBuilder(
///   sendAsset,
///   "100.0",
///   destinationAccountId,
///   destAsset,
///   "90.0"
/// ).setPath([intermediateAsset]).build();
/// ```
class PathPaymentStrictSendOperationBuilder {
  Asset _sendAsset;
  String _sendAmount;
  late MuxedAccount _destination;
  Asset _destAsset;
  String _destMin;
  List<Asset> _path = List<Asset>.empty(growable: true);
  MuxedAccount? _mSourceAccount;

  /// Creates a PathPaymentStrictSend operation builder with an account ID destination.
  ///
  /// Parameters:
  /// - [_sendAsset] Asset to be sent
  /// - [_sendAmount] Exact amount of sendAsset to be sent
  /// - [destinationAccountId] Account ID of the payment receiver
  /// - [_destAsset] Asset to be received
  /// - [_destMin] Minimum amount of destAsset to be received
  PathPaymentStrictSendOperationBuilder(this._sendAsset, this._sendAmount,
      String destinationAccountId, this._destAsset, this._destMin) {
    MuxedAccount? da = MuxedAccount.fromAccountId(destinationAccountId);
    checkNotNull(da, "invalid destinationAccountId");
    this._destination = da!;
  }

  /// Creates a PathPaymentStrictSend operation builder with a muxed account destination.
  ///
  /// Parameters:
  /// - [_sendAsset] Asset to be sent
  /// - [_sendAmount] Exact amount of sendAsset to be sent
  /// - [_destination] Muxed account of the payment receiver
  /// - [_destAsset] Asset to be received
  /// - [_destMin] Minimum amount of destAsset to be received
  PathPaymentStrictSendOperationBuilder.forMuxedDestinationAccount(
      this._sendAsset,
      this._sendAmount,
      this._destination,
      this._destAsset,
      this._destMin);

  /// Sets the conversion path for this operation.
  ///
  /// Parameters:
  /// - [path] List of intermediate assets (max 5)
  ///
  /// Returns: This builder instance for method chaining
  PathPaymentStrictSendOperationBuilder setPath(List<Asset> path) {
    checkArgument(
        path.length <= 5, "The maximum number of assets in the path is 5");
    this._path = path;
    return this;
  }

  /// Sets the source account for this operation.
  ///
  /// Parameters:
  /// - [sourceAccountId] Account ID of the operation source
  ///
  /// Returns: This builder instance for method chaining
  PathPaymentStrictSendOperationBuilder setSourceAccount(
      String sourceAccountId) {
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
  PathPaymentStrictSendOperationBuilder setMuxedSourceAccount(
      MuxedAccount sourceAccount) {
    _mSourceAccount = sourceAccount;
    return this;
  }

  /// Builds the PathPaymentStrictSend operation.
  ///
  /// Returns: Configured PathPaymentStrictSendOperation instance
  PathPaymentStrictSendOperation build() {
    PathPaymentStrictSendOperation operation = PathPaymentStrictSendOperation(
        _sendAsset, _sendAmount, _destination, _destAsset, _destMin, _path);
    if (_mSourceAccount != null) {
      operation.sourceAccount = _mSourceAccount;
    }
    return operation;
  }
}
