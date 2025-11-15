// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:stellar_flutter_sdk/src/muxed_account.dart';

import 'operation.dart';
import 'assets.dart';
import 'util.dart';
import 'xdr/xdr_operation.dart';
import 'xdr/xdr_type.dart';
import 'xdr/xdr_trustline.dart';

/// Creates, updates, or removes a trustline for an asset.
///
/// The ChangeTrust operation establishes a trustline between an account and an asset issuer,
/// allowing the account to hold and transact with non-native assets. This is a fundamental
/// operation for working with custom assets on the Stellar network.
///
/// Trustline Operations:
/// - **Create Trustline**: Set limit to maximum value or specific amount
/// - **Update Trustline**: Change the trust limit to a new value
/// - **Remove Trustline**: Set limit to "0" (only works if balance is 0)
///
/// Trust Limit Behavior:
/// - Maximum limit: "922337203685.4775807" (available as MAX_LIMIT constant)
/// - Specific limit: Any positive decimal value (e.g., "1000.00")
/// - Zero limit: "0" removes the trustline (requires zero balance)
/// - Limit defines maximum asset amount the account can hold
///
/// Use Cases:
/// - Enable account to receive custom assets
/// - Establish trust relationship with asset issuer
/// - Limit exposure to specific assets
/// - Remove unwanted trustlines
/// - Prepare account for asset trades
///
/// Example - Create Trustline with Maximum Limit:
/// ```dart
/// // Create trustline for USD asset with maximum limit
/// var usdAsset = AssetTypeCreditAlphaNum4('USD', issuerAccountId);
/// var trustOp = ChangeTrustOperationBuilder(
///   usdAsset,
///   ChangeTrustOperationBuilder.MAX_LIMIT
/// ).build();
///
/// var transaction = TransactionBuilder(sourceAccount)
///   .addOperation(trustOp)
///   .build();
/// ```
///
/// Example - Create Trustline with Specific Limit:
/// ```dart
/// // Create trustline with specific limit of 5000 USD
/// var trustOp = ChangeTrustOperationBuilder(
///   usdAsset,
///   '5000.00'
/// ).build();
/// ```
///
/// Example - Remove Trustline:
/// ```dart
/// // Remove trustline (balance must be 0)
/// var removeTrustOp = ChangeTrustOperationBuilder(
///   usdAsset,
///   '0'
/// ).build();
/// ```
///
/// Example - Update Trust Limit:
/// ```dart
/// // Increase trust limit to 10000 USD
/// var updateTrustOp = ChangeTrustOperationBuilder(
///   usdAsset,
///   '10000.00'
/// ).build();
/// ```
///
/// Important Considerations:
/// - Account must have sufficient XLM balance for base reserve
/// - Cannot remove trustline with non-zero balance
/// - Issuer must have authorization flags properly configured
/// - Trustlines for pool shares use liquidity pool IDs
/// - Source account is the one creating the trustline
///
/// Authorization Requirements:
/// - If issuer requires authorization (AUTH_REQUIRED), issuer must authorize trustline
/// - Use SetTrustLineFlagsOperation for issuer to authorize trustlines
/// - Unauthorized trustlines cannot receive assets
///
/// See also:
/// - [SetTrustLineFlagsOperation] - For issuer to authorize trustlines
/// - [AllowTrustOperation] - Deprecated authorization method
/// - [Asset] - Asset types (Credit Alphanum 4/12, Liquidity Pool)
/// - [Stellar developer docs](https://developers.stellar.org)
///
/// Represents [ChangeTrust](https://developers.stellar.org) operation.
/// See: [Stellar developer docs](https://developers.stellar.org)
class ChangeTrustOperation extends Operation {
  Asset _asset;
  String _limit;

  /// Creates a ChangeTrustOperation.
  ///
  /// Parameters:
  /// - [_asset]: The asset for the trustline.
  /// - [_limit]: The trust limit as a string (use "0" to remove, MAX_LIMIT for maximum).
  ChangeTrustOperation(this._asset, this._limit);

  /// The asset of the trustline.
  ///
  /// This can be a credit asset (AlphaNum4/AlphaNum12) or a liquidity pool share.
  Asset get asset => _asset;

  /// The limit of the trustline.
  ///
  /// Maximum asset amount the account can hold. Use "0" to remove trustline.
  String get limit => _limit;

  /// Converts this operation to its XDR OperationBody representation.
  ///
  /// Returns: XDR OperationBody for this change trust operation.
  @override
  XdrOperationBody toOperationBody() {
    XdrBigInt64 limit = new XdrBigInt64(Util.toXdrBigInt64Amount(this.limit));
    XdrChangeTrustOp op =
        new XdrChangeTrustOp(asset.toXdrChangeTrustAsset(), limit);

    XdrOperationBody body = new XdrOperationBody(XdrOperationType.CHANGE_TRUST);
    body.changeTrustOp = op;
    return body;
  }

  /// Builds ChangeTrust operation from XDR operation.
  ///
  /// Reconstructs a ChangeTrustOperation from its XDR representation.
  ///
  /// Parameters:
  /// - [op]: The XDR ChangeTrust operation.
  ///
  /// Returns: A builder instance for constructing the operation.
  static ChangeTrustOperationBuilder builder(XdrChangeTrustOp op) {
    return ChangeTrustOperationBuilder(
        Asset.fromXdr(op.line), Util.fromXdrBigInt64Amount(op.limit.bigInt));
  }
}

/// Builder for [ChangeTrustOperation].
///
/// Provides a fluent interface for constructing trustline operations.
///
/// Example:
/// ```dart
/// var operation = ChangeTrustOperationBuilder(
///   asset,
///   ChangeTrustOperationBuilder.MAX_LIMIT
/// ).setSourceAccount(accountId).build();
/// ```
class ChangeTrustOperationBuilder {

  /// Maximum possible trustline limit.
  ///
  /// This constant represents the maximum amount that can be held in a trustline.
  static const MAX_LIMIT = "922337203685.4775807";

  Asset _asset;
  String _limit;
  MuxedAccount? _mSourceAccount;

  /// Creates a ChangeTrustOperationBuilder.
  ///
  /// Parameters:
  /// - [_asset]: The asset for the trustline.
  /// - [_limit]: The trust limit. Use MAX_LIMIT for maximum or "0" to remove.
  ChangeTrustOperationBuilder(this._asset, this._limit);

  /// Sets the source account for this operation.
  ///
  /// The source account will establish or modify the trustline.
  ///
  /// Parameters:
  /// - [sourceAccountId]: The account ID that will create/modify the trustline.
  ///
  /// Returns: This builder instance for method chaining.
  ChangeTrustOperationBuilder setSourceAccount(String sourceAccountId) {
    MuxedAccount? sa = MuxedAccount.fromAccountId(sourceAccountId);
    _mSourceAccount = checkNotNull(sa, "invalid sourceAccountId");
    return this;
  }

  /// Sets the muxed source account for this operation.
  ///
  /// Parameters:
  /// - [sourceAccount]: The muxed source account.
  ///
  /// Returns: This builder instance for method chaining.
  ChangeTrustOperationBuilder setMuxedSourceAccount(
      MuxedAccount sourceAccount) {
    _mSourceAccount = sourceAccount;
    return this;
  }

  /// Builds the change trust operation.
  ///
  /// Returns: A configured [ChangeTrustOperation] instance.
  ChangeTrustOperation build() {
    ChangeTrustOperation operation = new ChangeTrustOperation(_asset, _limit);
    if (_mSourceAccount != null) {
      operation.sourceAccount = _mSourceAccount!;
    }
    return operation;
  }
}
