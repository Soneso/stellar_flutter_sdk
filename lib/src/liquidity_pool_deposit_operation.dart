// Copyright 2021 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:stellar_flutter_sdk/src/key_pair.dart';

import 'muxed_account.dart';
import 'operation.dart';
import 'util.dart';
import 'xdr/xdr_operation.dart';
import 'xdr/xdr_account.dart';
import 'xdr/xdr_type.dart';
import 'xdr/xdr_other.dart';
import 'price.dart';

/// Deposits assets into an automated market maker (AMM) liquidity pool.
///
/// This operation allows liquidity providers to deposit both assets of a pool pair,
/// receiving pool shares in return. The depositor specifies maximum amounts and price
/// bounds to control slippage. This operation was introduced in Protocol 18 via CAP-38
/// as part of Stellar's native AMM implementation.
///
/// AMM Liquidity Pools:
/// - **Constant product formula**: x * y = k (like Uniswap)
/// - **Pool shares**: Represent proportional ownership of the pool
/// - **Fees**: Trading fees are distributed to liquidity providers
/// - **No impermanent loss protection**: Standard AMM risks apply
///
/// Deposit Mechanics:
/// - Must deposit both assets in proportion to current pool ratio
/// - Receive pool shares proportional to deposit size
/// - Price bounds protect against front-running and slippage
/// - Operation fails if price moves outside specified range
///
/// Parameters:
/// - **liquidityPoolId**: The ID of the target liquidity pool
/// - **maxAmountA**: Maximum amount of asset A to deposit
/// - **maxAmountB**: Maximum amount of asset B to deposit
/// - **minPrice**: Minimum acceptable price (A/B ratio)
/// - **maxPrice**: Maximum acceptable price (A/B ratio)
///
/// Use Cases:
/// - Provide liquidity to earn trading fees
/// - Market making on Stellar DEX
/// - Initial pool creation (first deposit)
/// - Increasing pool depth for better trades
///
/// Example - Deposit to USD/EUR Pool:
/// ```dart
/// // Deposit up to 1000 USD and 900 EUR with 1% slippage protection
/// var depositOp = LiquidityPoolDepositOperationBuilder(
///   liquidityPoolId: poolId,
///   maxAmountA: "1000.0",
///   maxAmountB: "900.0",
///   minPrice: "0.89",   // Min acceptable EUR/USD rate
///   maxPrice: "0.91"    // Max acceptable EUR/USD rate
/// ).setSourceAccount(liquidityProviderId).build();
///
/// var transaction = TransactionBuilder(providerAccount)
///   .addOperation(depositOp)
///   .build();
/// ```
///
/// Example - Initial Pool Creation:
/// ```dart
/// // First deposit creates the pool ratio
/// var initialDeposit = LiquidityPoolDepositOperationBuilder(
///   liquidityPoolId: newPoolId,
///   maxAmountA: "10000.0",
///   maxAmountB: "5000.0",
///   minPrice: "0.49",
///   maxPrice: "0.51"  // Establishes 1:0.5 ratio
/// ).build();
/// ```
///
/// Important Considerations:
/// - Account must have sufficient balance of both assets
/// - Deposit must respect minimum pool requirements
/// - Price bounds should account for recent price volatility
/// - Pool shares can be redeemed later via withdraw operation
/// - Trading fees accumulate in the pool, increasing share value
///
/// See also:
/// - [LiquidityPoolWithdrawOperation] to withdraw liquidity
/// - [ChangeTrustOperation] to establish pool share trustline first
/// - [CAP-38](https://github.com/stellar/stellar-protocol/blob/master/core/cap-0038.md)
/// - [Stellar developer docs](https://developers.stellar.org)
class LiquidityPoolDepositOperation extends Operation {
  /// The hex-encoded liquidity pool ID or StrKey L format.
  String liquidityPoolId;

  /// Maximum amount of asset A to deposit (decimal string format).
  String maxAmountA;

  /// Maximum amount of asset B to deposit (decimal string format).
  String maxAmountB;

  /// Minimum acceptable price (A/B ratio) as decimal string.
  String minPrice;

  /// Maximum acceptable price (A/B ratio) as decimal string.
  String maxPrice;

  /// Creates a LiquidityPoolDepositOperation.
  ///
  /// Parameters:
  /// - [liquidityPoolId] The liquidity pool ID (hex or StrKey L format).
  /// - [maxAmountA] Maximum amount of asset A to deposit.
  /// - [maxAmountB] Maximum amount of asset B to deposit.
  /// - [minPrice] Minimum acceptable price ratio (A/B).
  /// - [maxPrice] Maximum acceptable price ratio (A/B).
  LiquidityPoolDepositOperation(
      {required this.liquidityPoolId,
      required this.maxAmountA,
      required this.maxAmountB,
      required this.minPrice,
      required this.maxPrice});

  /// Converts this operation to its XDR representation.
  ///
  /// Returns: XDR operation body for the liquidity pool deposit.
  @override
  XdrOperationBody toOperationBody() {
    var id = liquidityPoolId;
    if (id.startsWith("L")) {
      try {
        id = Util.bytesToHex(
            StrKey.decodeLiquidityPoolId(liquidityPoolId));
      } catch (_) {}
    }
    XdrHash xLiquidityPoolID = Util.stringIdToXdrHash(id);
    var amountA = XdrBigInt64(Util.toXdrBigInt64Amount(this.maxAmountA));
    var amountB = XdrBigInt64(Util.toXdrBigInt64Amount(this.maxAmountB));
    XdrPrice xMinPrice = Price.fromString(minPrice).toXdr();
    XdrPrice xMaxPrice = Price.fromString(maxPrice).toXdr();

    XdrOperationBody body =
        XdrOperationBody(XdrOperationType.LIQUIDITY_POOL_DEPOSIT);
    body.liquidityPoolDepositOp = XdrLiquidityPoolDepositOp(
        xLiquidityPoolID, amountA, amountB, xMinPrice, xMaxPrice);
    return body;
  }

  /// Creates a builder from an XDR liquidity pool deposit operation.
  ///
  /// Parameters:
  /// - [op] XDR liquidity pool deposit operation.
  ///
  /// Returns: Builder initialized with operation parameters.
  static LiquidityPoolDepositOperationBuilder builder(
      XdrLiquidityPoolDepositOp op) {
    String lpId = Util.bytesToHex(op.liquidityPoolID.hash);
    String maxA = Util.fromXdrBigInt64Amount(op.maxAmountA.bigInt);
    String maxB = Util.fromXdrBigInt64Amount(op.maxAmountB.bigInt);
    int n = op.minPrice.n.int32;
    int d = op.minPrice.d.int32;
    String minP = removeTailZero((BigInt.from(n) / BigInt.from(d)).toString());
    n = op.maxPrice.n.int32;
    d = op.maxPrice.d.int32;
    String maxP = removeTailZero((BigInt.from(n) / BigInt.from(d)).toString());

    return LiquidityPoolDepositOperationBuilder(
        liquidityPoolId: lpId,
        maxAmountA: maxA,
        maxAmountB: maxB,
        minPrice: minP,
        maxPrice: maxP);
  }
}

/// Builder for [LiquidityPoolDepositOperation].
///
/// Provides a fluent interface for constructing liquidity pool deposit operations.
///
/// Example:
/// ```dart
/// var operation = LiquidityPoolDepositOperationBuilder(
///   liquidityPoolId: poolId,
///   maxAmountA: "1000.0",
///   maxAmountB: "500.0",
///   minPrice: "0.49",
///   maxPrice: "0.51"
/// ).setSourceAccount(providerId).build();
/// ```
class LiquidityPoolDepositOperationBuilder {
  /// The hex-encoded liquidity pool ID or StrKey L format.
  String liquidityPoolId;

  /// Maximum amount of asset A to deposit (decimal string format).
  String maxAmountA;

  /// Maximum amount of asset B to deposit (decimal string format).
  String maxAmountB;

  /// Minimum acceptable price (A/B ratio) as decimal string.
  String minPrice;

  /// Maximum acceptable price (A/B ratio) as decimal string.
  String maxPrice;

  MuxedAccount? _mSourceAccount;

  /// Creates a LiquidityPoolDepositOperationBuilder.
  ///
  /// Parameters:
  /// - [liquidityPoolId] The pool ID (hex or StrKey L format).
  /// - [maxAmountA] Maximum amount of asset A to deposit.
  /// - [maxAmountB] Maximum amount of asset B to deposit.
  /// - [minPrice] Minimum acceptable price ratio (A/B).
  /// - [maxPrice] Maximum acceptable price ratio (A/B).
  LiquidityPoolDepositOperationBuilder(
      {required this.liquidityPoolId,
      required this.maxAmountA,
      required this.maxAmountB,
      required this.minPrice,
      required this.maxPrice});

  /// Sets the source account for this operation.
  ///
  /// Parameters:
  /// - [sourceAccountId] The account ID of the liquidity provider.
  ///
  /// Returns: This builder instance for method chaining.
  LiquidityPoolDepositOperationBuilder setSourceAccount(
      String sourceAccountId) {
    MuxedAccount? sa = MuxedAccount.fromAccountId(sourceAccountId);
    _mSourceAccount = checkNotNull(sa, "invalid sourceAccountId");
    return this;
  }

  /// Sets the muxed source account for this operation.
  ///
  /// Parameters:
  /// - [sourceAccount] The muxed source account (liquidity provider).
  ///
  /// Returns: This builder instance for method chaining.
  LiquidityPoolDepositOperationBuilder setMuxedSourceAccount(
      MuxedAccount sourceAccount) {
    _mSourceAccount = sourceAccount;
    return this;
  }

  /// Builds the liquidity pool deposit operation.
  ///
  /// Returns: A configured [LiquidityPoolDepositOperation] instance.
  LiquidityPoolDepositOperation build() {
    LiquidityPoolDepositOperation operation = LiquidityPoolDepositOperation(
        liquidityPoolId: liquidityPoolId,
        maxAmountA: maxAmountA,
        maxAmountB: maxAmountB,
        minPrice: minPrice,
        maxPrice: maxPrice);
    if (_mSourceAccount != null) {
      operation.sourceAccount = _mSourceAccount;
    }
    return operation;
  }
}
