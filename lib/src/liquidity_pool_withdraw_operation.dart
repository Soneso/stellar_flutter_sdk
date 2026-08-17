// Copyright 2021 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'operation.dart';
import 'util.dart';
import 'xdr/xdr.dart';

/// Withdraws assets from an AMM liquidity pool by burning pool shares.
///
/// This operation allows liquidity providers to redeem their pool shares for the
/// underlying assets. The withdrawer specifies the amount of shares to burn and
/// minimum amounts they're willing to receive of each asset, protecting against
/// slippage. This operation was introduced in Protocol 18 via CAP-38.
///
/// Withdrawal Mechanics:
/// - Burn pool shares to receive proportional amounts of both assets
/// - Minimum amounts protect against unfavorable price movements
/// - Receive pro-rata share of accumulated trading fees
/// - Reduces overall pool liquidity
///
/// Parameters:
/// - **liquidityPoolId**: The pool to withdraw from
/// - **amount**: Number of pool shares to burn
/// - **minAmountA**: Minimum acceptable amount of asset A to receive
/// - **minAmountB**: Minimum acceptable amount of asset B to receive
///
/// Use Cases:
/// - Exit liquidity provision position
/// - Realize trading fee profits
/// - Rebalance portfolio
/// - Reduce exposure to specific asset pair
///
/// Example - Withdraw from Pool:
/// ```dart
/// // Withdraw 100 pool shares, expecting at least 990 USD and 490 EUR
/// var withdrawOp = LiquidityPoolWithdrawOperationBuilder(
///   liquidityPoolId: poolId,
///   amount: "100.0",
///   minAmountA: "990.0",  // USD with 1% slippage tolerance
///   minAmountB: "490.0"   // EUR with 2% slippage tolerance
/// ).setSourceAccount(providerId).build();
///
/// var transaction = TransactionBuilder(providerAccount)
///   .addOperation(withdrawOp)
///   .build();
/// ```
///
/// Example - Complete Exit:
/// ```dart
/// // Withdraw all pool shares (get balance from account first)
/// var withdrawAll = LiquidityPoolWithdrawOperationBuilder(
///   liquidityPoolId: poolId,
///   amount: totalPoolShares,
///   minAmountA: calculatedMinA,
///   minAmountB: calculatedMinB
/// ).build();
/// ```
///
/// Important Considerations:
/// - Must hold sufficient pool shares
/// - Minimum amounts should account for recent price movements
/// - Larger withdrawals may experience more slippage
/// - Operation fails if minimums aren't met
/// - Trading fees are included in withdrawn amounts
///
/// See also:
/// - [LiquidityPoolDepositOperation] to provide liquidity
/// - [CAP-38](https://github.com/stellar/stellar-protocol/blob/master/core/cap-0038.md)
/// - [Stellar developer docs](https://developers.stellar.org)
class LiquidityPoolWithdrawOperation extends Operation {
  /// The hex-encoded liquidity pool ID or StrKey L format.
  String liquidityPoolId;

  /// Amount of pool shares to burn (decimal string format).
  String amount;

  /// Minimum amount of asset A to receive (decimal string format).
  String minAmountA;

  /// Minimum amount of asset B to receive (decimal string format).
  String minAmountB;

  /// Creates a LiquidityPoolWithdrawOperation.
  ///
  /// Parameters:
  /// - [liquidityPoolId] The liquidity pool ID (hex or StrKey L format).
  /// - [amount] Amount of pool shares to burn.
  /// - [minAmountA] Minimum amount of asset A to receive.
  /// - [minAmountB] Minimum amount of asset B to receive.
  LiquidityPoolWithdrawOperation(
      {required this.liquidityPoolId,
      required this.amount,
      required this.minAmountA,
      required this.minAmountB});

  /// Converts this operation to its XDR representation.
  ///
  /// Returns: XDR operation body for the liquidity pool withdrawal.
  ///
  /// Throws:
  /// - [ArgumentError]: if [liquidityPoolId] is neither a liquidity pool
  ///   strkey (L...) nor the hex of a 32 byte pool hash
  @override
  XdrOperationBody toOperationBody() {
    final XdrHash xLiquidityPoolID;
    try {
      xLiquidityPoolID = Util.liquidityPoolIdToXdrHash(liquidityPoolId);
    } on FormatException catch (e) {
      throw ArgumentError(
          "invalid liquidity pool id: $liquidityPoolId (${e.message})");
    }
    XdrInt64 amountA = XdrInt64(Util.decimalStringToStroops(this.minAmountA));
    XdrInt64 amountB = XdrInt64(Util.decimalStringToStroops(this.minAmountB));
    XdrInt64 a = XdrInt64(Util.decimalStringToStroops(this.amount));

    XdrOperationBody body =
        XdrOperationBody(XdrOperationType.LIQUIDITY_POOL_WITHDRAW);
    body.liquidityPoolWithdrawOp =
        XdrLiquidityPoolWithdrawOp(xLiquidityPoolID, a, amountA, amountB);
    return body;
  }

  /// Creates a builder from an XDR liquidity pool withdraw operation.
  ///
  /// Parameters:
  /// - [op] XDR liquidity pool withdraw operation.
  ///
  /// Returns: Builder initialized with operation parameters.
  static LiquidityPoolWithdrawOperationBuilder builder(
      XdrLiquidityPoolWithdrawOp op) {
    String lpId = Util.bytesToHex(op.liquidityPoolID.hash);
    String minA = Util.stroopsToDecimalString(op.minAmountA.int64);
    String minB = Util.stroopsToDecimalString(op.minAmountB.int64);
    String amount = Util.stroopsToDecimalString(op.amount.int64);

    return LiquidityPoolWithdrawOperationBuilder(
        liquidityPoolId: lpId, amount: amount, minAmountA: minA, minAmountB: minB);
  }
}

/// Builder for [LiquidityPoolWithdrawOperation].
///
/// Provides a fluent interface for constructing liquidity pool withdrawal operations.
///
/// Example:
/// ```dart
/// var operation = LiquidityPoolWithdrawOperationBuilder(
///   liquidityPoolId: poolId,
///   amount: "100.0",
///   minAmountA: "990.0",
///   minAmountB: "490.0"
/// ).setSourceAccount(providerId).build();
/// ```
class LiquidityPoolWithdrawOperationBuilder
    extends OperationBuilder<LiquidityPoolWithdrawOperationBuilder> {
  /// The hex-encoded liquidity pool ID or StrKey L format.
  String liquidityPoolId;

  /// Minimum amount of asset A to receive (decimal string format).
  String minAmountA;

  /// Minimum amount of asset B to receive (decimal string format).
  String minAmountB;

  /// Amount of pool shares to burn (decimal string format).
  String amount;

  /// Creates a LiquidityPoolWithdrawOperationBuilder.
  ///
  /// Parameters:
  /// - [liquidityPoolId] The pool ID (hex or StrKey L format).
  /// - [amount] Amount of pool shares to burn.
  /// - [minAmountA] Minimum amount of asset A to receive.
  /// - [minAmountB] Minimum amount of asset B to receive.
  LiquidityPoolWithdrawOperationBuilder(
      {required this.liquidityPoolId,
      required this.amount,
      required this.minAmountA,
      required this.minAmountB});

  /// Builds the liquidity pool withdraw operation.
  ///
  /// Returns: A configured [LiquidityPoolWithdrawOperation] instance.
  LiquidityPoolWithdrawOperation build() {
    LiquidityPoolWithdrawOperation operation = LiquidityPoolWithdrawOperation(
        liquidityPoolId: liquidityPoolId,
        amount: amount,
        minAmountA: minAmountA,
        minAmountB: minAmountB);
    return applySourceAccount(operation);
  }
}
