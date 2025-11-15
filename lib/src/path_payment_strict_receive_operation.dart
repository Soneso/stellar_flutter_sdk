// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:stellar_flutter_sdk/src/muxed_account.dart';

import 'operation.dart';
import 'assets.dart';
import 'util.dart';
import 'xdr/xdr_asset.dart';
import 'xdr/xdr_operation.dart';
import 'xdr/xdr_payment.dart';
import 'xdr/xdr_type.dart';

/// Sends a payment through a path, specifying the exact amount the destination receives.
///
/// PathPaymentStrictReceive allows you to send one asset and have the recipient receive
/// a different asset through automatic conversion along a path of offers. You specify
/// the exact amount the destination should receive, and the network determines how much
/// of the source asset needs to be sent (up to a maximum specified by sendMax).
///
/// Use this operation when:
/// - Converting assets during payment
/// - Guaranteeing a specific receive amount
/// - Using the DEX for automatic asset conversion
/// - Implementing cross-asset payments
///
/// Important notes:
/// - The destination receives exactly the specified amount
/// - The source may pay up to sendMax to achieve the destination amount
/// - The path can contain up to 5 intermediate assets
/// - Operation fails if the conversion cannot be completed within sendMax
/// - The destination must have appropriate trustlines for the received asset
///
/// Example:
/// ```dart
/// // Convert USD to EUR, ensuring recipient gets exactly 100 EUR
/// var usd = AssetTypeCreditAlphaNum4("USD", usdIssuer);
/// var eur = AssetTypeCreditAlphaNum4("EUR", eurIssuer);
/// var xlm = Asset.native();
///
/// var pathPayment = PathPaymentStrictReceiveOperationBuilder(
///   usd,           // Send USD
///   "150",         // Send at most 150 USD
///   destinationId, // Recipient account
///   eur,           // Receive EUR
///   "100"          // Receive exactly 100 EUR
/// ).setPath([xlm]).build(); // Convert through XLM
///
/// // Direct conversion without intermediate assets
/// var directPayment = PathPaymentStrictReceiveOperationBuilder(
///   usd,
///   "110",
///   destinationId,
///   eur,
///   "100"
/// ).build();
/// ```
///
/// See also:
/// - [PathPaymentStrictSendOperation] for specifying exact send amount instead
/// - [PaymentOperation] for simple same-asset payments
/// - [Operation] for general operation documentation
class PathPaymentStrictReceiveOperation extends Operation {
  Asset _sendAsset;
  String _sendMax;
  MuxedAccount _destination;
  Asset _destAsset;
  String _destAmount;
  late List<Asset> _path;

  /// Creates a PathPaymentStrictReceive operation.
  ///
  /// Parameters:
  /// - [_sendAsset] Asset to be sent
  /// - [_sendMax] Maximum amount of sendAsset to be sent
  /// - [_destination] Muxed account receiving the payment
  /// - [_destAsset] Asset to be received
  /// - [_destAmount] Exact amount of destAsset to be received
  /// - [path] Optional list of assets for conversion path (max 5)
  PathPaymentStrictReceiveOperation(this._sendAsset, this._sendMax,
      this._destination, this._destAsset, this._destAmount, List<Asset>? path) {
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

  /// The maximum amount of send asset to deduct (excluding fees)
  String get sendMax => _sendMax;

  /// Account that receives the payment.
  MuxedAccount get destination => _destination;

  /// The asset the destination account receives.
  Asset get destAsset => _destAsset;

  /// The amount of destination asset the destination account receives.
  String get destAmount => _destAmount;

  /// The intermediate assets involved in the conversion path.
  ///
  /// Contains the assets (other than send asset and destination asset) involved
  /// in the offers the path takes. For example, if you can only find a path from
  /// USD to EUR through XLM and BTC, the path would be USD -> XLM -> BTC -> EUR
  /// and this list would contain XLM and BTC.
  List<Asset> get path => _path;

  /// Converts this operation to its XDR OperationBody representation.
  ///
  /// Returns: XDR OperationBody for this path payment strict receive operation.
  @override
  XdrOperationBody toOperationBody() {
    // sendMax
    XdrBigInt64 sendMax = XdrBigInt64(Util.toXdrBigInt64Amount(this.sendMax));

    // destAmount
    XdrBigInt64 destAmount = XdrBigInt64(Util.toXdrBigInt64Amount(this.destAmount));

    // path
    List<XdrAsset> path = List<XdrAsset>.empty(growable: true);
    for (int i = 0; i < this.path.length; i++) {
      path.add(this.path[i].toXdr());
    }
    XdrPathPaymentStrictReceiveOp op = XdrPathPaymentStrictReceiveOp(
        sendAsset.toXdr(),
        sendMax,
        this._destination.toXdr(),
        destAsset.toXdr(),
        destAmount,
        path);

    XdrOperationBody body =
        XdrOperationBody(XdrOperationType.PATH_PAYMENT_STRICT_RECEIVE);
    body.pathPaymentStrictReceiveOp = op;
    return body;
  }

  /// Constructs a PathPaymentStrictReceiveOperationBuilder from XDR.
  ///
  /// Parameters:
  /// - [op] XDR PathPaymentStrictReceiveOp to build from
  ///
  /// Returns: Builder configured with XDR operation data
  static PathPaymentStrictReceiveOperationBuilder builder(
      XdrPathPaymentStrictReceiveOp op) {
    List<Asset> path = List<Asset>.empty(growable: true);
    for (int i = 0; i < op.path.length; i++) {
      path.add(Asset.fromXdr(op.path[i]));
    }
    return PathPaymentStrictReceiveOperationBuilder.forMuxedDestinationAccount(
            Asset.fromXdr(op.sendAsset),
            Util.fromXdrBigInt64Amount(op.sendMax.bigInt),
            MuxedAccount.fromXdr(op.destination),
            Asset.fromXdr(op.destAsset),
            Util.fromXdrBigInt64Amount(op.destAmount.bigInt))
        .setPath(path);
  }
}

/// Builder for constructing PathPaymentStrictReceive operations.
///
/// Provides a fluent interface for building PathPaymentStrictReceive operations
/// with optional parameters. Supports both regular account IDs and muxed accounts
/// as destinations.
///
/// Example:
/// ```dart
/// var operation = PathPaymentStrictReceiveOperationBuilder(
///   sendAsset,
///   "150.0",
///   destinationAccountId,
///   destAsset,
///   "100.0"
/// ).setPath([intermediateAsset]).build();
/// ```
class PathPaymentStrictReceiveOperationBuilder {
  Asset _sendAsset;
  String _sendMax;
  late MuxedAccount _destination;
  Asset _destAsset;
  String _destAmount;
  List<Asset> _path = List<Asset>.empty(growable: true);
  MuxedAccount? _mSourceAccount;

  /// Creates a PathPaymentStrictReceive operation builder with an account ID destination.
  ///
  /// Parameters:
  /// - [_sendAsset] Asset to be sent
  /// - [_sendMax] Maximum amount of sendAsset to be sent
  /// - [destinationAccountId] Account ID of the payment receiver
  /// - [_destAsset] Asset to be received
  /// - [_destAmount] Exact amount of destAsset to be received
  PathPaymentStrictReceiveOperationBuilder(this._sendAsset, this._sendMax,
      String destinationAccountId, this._destAsset, this._destAmount) {
    MuxedAccount? da = MuxedAccount.fromAccountId(destinationAccountId);
    checkNotNull(da, "invalid destinationAccountId");
    this._destination = da!;
  }

  /// Creates a PathPaymentStrictReceive operation builder with a muxed account destination.
  ///
  /// Parameters:
  /// - [_sendAsset] Asset to be sent
  /// - [_sendMax] Maximum amount of sendAsset to be sent
  /// - [_destination] Muxed account of the payment receiver
  /// - [_destAsset] Asset to be received
  /// - [_destAmount] Exact amount of destAsset to be received
  PathPaymentStrictReceiveOperationBuilder.forMuxedDestinationAccount(
      this._sendAsset,
      this._sendMax,
      this._destination,
      this._destAsset,
      this._destAmount);

  /// Sets the conversion path for this operation.
  ///
  /// Parameters:
  /// - [path] List of intermediate assets (max 5)
  ///
  /// Returns: This builder instance for method chaining
  PathPaymentStrictReceiveOperationBuilder setPath(List<Asset> path) {
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
  PathPaymentStrictReceiveOperationBuilder setSourceAccount(
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
  PathPaymentStrictReceiveOperationBuilder setMuxedSourceAccount(
      MuxedAccount sourceAccount) {
    _mSourceAccount = sourceAccount;
    return this;
  }

  /// Builds the PathPaymentStrictReceive operation.
  ///
  /// Returns: Configured PathPaymentStrictReceiveOperation instance
  PathPaymentStrictReceiveOperation build() {
    PathPaymentStrictReceiveOperation operation =
        PathPaymentStrictReceiveOperation(
            _sendAsset, _sendMax, _destination, _destAsset, _destAmount, _path);
    if (_mSourceAccount != null) {
      operation.sourceAccount = _mSourceAccount;
    }
    return operation;
  }
}
