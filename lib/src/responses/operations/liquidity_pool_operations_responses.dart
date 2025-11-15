// Copyright 2024 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:stellar_flutter_sdk/src/responses/effects/effect_responses.dart';

import 'operation_responses.dart';
import '../transaction_response.dart';
import '../response.dart';

/// Represents a liquidity pool deposit operation response from Horizon.
///
/// Deposits assets into an automated market maker (AMM) liquidity pool, receiving
/// pool shares proportional to the contribution. Depositors become liquidity providers
/// and earn trading fees from the pool.
///
/// The operation specifies maximum reserves to deposit and acceptable price ranges.
/// Actual deposited amounts and shares received may differ based on pool state.
///
/// Returned by: Horizon API operations endpoint when querying liquidity pool deposit operations
///
/// Example:
/// ```dart
/// final operations = await sdk.operations
///     .forLiquidityPool('pool_id')
///     .execute();
///
/// for (var op in operations.records) {
///   if (op is LiquidityPoolDepositOperationResponse) {
///     print('Pool ID: ${op.liquidityPoolId}');
///     print('Shares received: ${op.sharesReceived}');
///     for (var reserve in op.reservesDeposited) {
///       print('Deposited: ${reserve.amount} ${reserve.assetCode ?? "XLM"}');
///     }
///   }
/// }
/// ```
///
/// See also:
/// - [LiquidityPoolDepositOperation] for creating deposits
/// - [Stellar developer docs](https://developers.stellar.org)
class LiquidityPoolDepositOperationResponse extends OperationResponse {
  /// The liquidity pool identifier
  String liquidityPoolId;

  /// Maximum reserves willing to deposit for each asset
  List<AssetAmount> reservesMax;

  /// Minimum acceptable exchange rate as decimal string
  String minPrice;

  /// Minimum acceptable exchange rate as fraction (n/d)
  LiquidityPoolPriceResponse minPriceR;

  /// Maximum acceptable exchange rate as decimal string
  String maxPrice;

  /// Maximum acceptable exchange rate as fraction (n/d)
  LiquidityPoolPriceResponse maxPriceR;

  /// Actual reserves deposited for each asset
  List<AssetAmount> reservesDeposited;

  /// Liquidity pool shares received
  String sharesReceived;

  /// Creates a LiquidityPoolDepositOperationResponse from Horizon API operation data.
  ///
  /// This constructor is typically called internally when deserializing operation
  /// records from Horizon API responses.
  ///
  /// Parameters:
  /// - [links] Hypermedia links to related resources
  /// - [id] Unique operation identifier
  /// - [pagingToken] Pagination cursor
  /// - [transactionSuccessful] Whether the parent transaction succeeded
  /// - [sourceAccount] Operation source account ID
  /// - [sourceAccountMuxed] Muxed source account (if applicable)
  /// - [sourceAccountMuxedId] Muxed source account ID (if applicable)
  /// - [type] Operation type name
  /// - [type_i] Operation type as integer
  /// - [createdAt] Creation timestamp
  /// - [transactionHash] Parent transaction hash
  /// - [transaction] Full parent transaction
  /// - [sponsor] Account sponsoring the operation (if applicable)
  /// - [liquidityPoolId] The liquidity pool identifier
  /// - [reservesMax] Maximum reserves willing to deposit
  /// - [minPrice] Minimum acceptable exchange rate
  /// - [minPriceR] Minimum acceptable exchange rate as fraction
  /// - [maxPrice] Maximum acceptable exchange rate
  /// - [maxPriceR] Maximum acceptable exchange rate as fraction
  /// - [reservesDeposited] Actual reserves deposited
  /// - [sharesReceived] Liquidity pool shares received
  LiquidityPoolDepositOperationResponse(
      super.links,
      super.id,
      super.pagingToken,
      super.transactionSuccessful,
      super.sourceAccount,
      super.sourceAccountMuxed,
      super.sourceAccountMuxedId,
      super.type,
      super.type_i,
      super.createdAt,
      super.transactionHash,
      super.transaction,
      super.sponsor,
      {required this.liquidityPoolId,
      required this.reservesMax,
      required this.minPrice,
      required this.minPriceR,
      required this.maxPrice,
      required this.maxPriceR,
      required this.reservesDeposited,
      required this.sharesReceived});

  /// Deserializes a liquidity pool deposit operation response from JSON.
  factory LiquidityPoolDepositOperationResponse.fromJson(
          Map<String, dynamic> json) =>
      LiquidityPoolDepositOperationResponse(
          OperationResponseLinks.fromJson(json['_links']),
          json['id'],
          json['paging_token'],
          json['transaction_successful'],
          json['source_account'],
          json['source_account_muxed'],
          json['source_account_muxed_id'],
          json['type'],
          json['type_i'],
          json['created_at'],
          json['transaction_hash'],
          json['transaction'] == null
              ? null
              : TransactionResponse.fromJson(json['transaction']),
          json['sponsor'],
          liquidityPoolId: json['liquidity_pool_id'],
          reservesMax: List<AssetAmount>.from(
              json['reserves_max'].map((e) => AssetAmount.fromJson(e))),
          minPrice: json['min_price'],
          minPriceR: LiquidityPoolPriceResponse.fromJson(json['min_price_r']),
          maxPrice: json['max_price'],
          maxPriceR: LiquidityPoolPriceResponse.fromJson(json['max_price_r']),
          reservesDeposited: List<AssetAmount>.from(
              json['reserves_deposited'].map((e) => AssetAmount.fromJson(e))),
          sharesReceived: json['shares_received']);
}

/// Represents a liquidity pool withdraw operation response from Horizon.
///
/// Withdraws assets from an automated market maker (AMM) liquidity pool by burning
/// pool shares. Liquidity providers redeem their shares to retrieve their portion
/// of the pool's reserves.
///
/// The operation specifies the amount of shares to burn and minimum acceptable reserves.
/// Actual received amounts may differ based on current pool state and trading activity.
///
/// Returned by: Horizon API operations endpoint when querying liquidity pool withdraw operations
///
/// Example:
/// ```dart
/// final operations = await sdk.operations
///     .forLiquidityPool('pool_id')
///     .execute();
///
/// for (var op in operations.records) {
///   if (op is LiquidityPoolWithdrawOperationResponse) {
///     print('Pool ID: ${op.liquidityPoolId}');
///     print('Shares burned: ${op.shares}');
///     for (var reserve in op.reservesReceived) {
///       print('Received: ${reserve.amount} ${reserve.assetCode ?? "XLM"}');
///     }
///   }
/// }
/// ```
///
/// See also:
/// - [LiquidityPoolWithdrawOperation] for creating withdrawals
/// - [Stellar developer docs](https://developers.stellar.org)
class LiquidityPoolWithdrawOperationResponse extends OperationResponse {
  /// The liquidity pool identifier
  String liquidityPoolId;

  /// Minimum reserves willing to receive for each asset
  List<AssetAmount> reservesMin;

  /// Liquidity pool shares burned
  String shares;

  /// Actual reserves received for each asset
  List<AssetAmount> reservesReceived;

  /// Creates a LiquidityPoolWithdrawOperationResponse from Horizon API operation data.
  ///
  /// This constructor is typically called internally when deserializing operation
  /// records from Horizon API responses.
  ///
  /// Parameters:
  /// - [links] Hypermedia links to related resources
  /// - [id] Unique operation identifier
  /// - [pagingToken] Pagination cursor
  /// - [transactionSuccessful] Whether the parent transaction succeeded
  /// - [sourceAccount] Operation source account ID
  /// - [sourceAccountMuxed] Muxed source account (if applicable)
  /// - [sourceAccountMuxedId] Muxed source account ID (if applicable)
  /// - [type] Operation type name
  /// - [type_i] Operation type as integer
  /// - [createdAt] Creation timestamp
  /// - [transactionHash] Parent transaction hash
  /// - [transaction] Full parent transaction
  /// - [sponsor] Account sponsoring the operation (if applicable)
  /// - [liquidityPoolId] The liquidity pool identifier
  /// - [reservesMin] Minimum reserves willing to receive
  /// - [shares] Liquidity pool shares burned
  /// - [reservesReceived] Actual reserves received
  LiquidityPoolWithdrawOperationResponse(
      super.links,
      super.id,
      super.pagingToken,
      super.transactionSuccessful,
      super.sourceAccount,
      super.sourceAccountMuxed,
      super.sourceAccountMuxedId,
      super.type,
      super.type_i,
      super.createdAt,
      super.transactionHash,
      super.transaction,
      super.sponsor,
      {required this.liquidityPoolId,
      required this.reservesMin,
      required this.shares,
      required this.reservesReceived});

  /// Deserializes a liquidity pool withdraw operation response from JSON.
  factory LiquidityPoolWithdrawOperationResponse.fromJson(
          Map<String, dynamic> json) =>
      LiquidityPoolWithdrawOperationResponse(
          OperationResponseLinks.fromJson(json['_links']),
          json['id'],
          json['paging_token'],
          json['transaction_successful'],
          json['source_account'],
          json['source_account_muxed'],
          json['source_account_muxed_id'],
          json['type'],
          json['type_i'],
          json['created_at'],
          json['transaction_hash'],
          json['transaction'] == null
              ? null
              : TransactionResponse.fromJson(json['transaction']),
          json['sponsor'],
          liquidityPoolId: json['liquidity_pool_id'],
          reservesMin: List<AssetAmount>.from(
              json['reserves_min'].map((e) => AssetAmount.fromJson(e))),
          shares: json['shares'],
          reservesReceived: List<AssetAmount>.from(
              json['reserves_received'].map((e) => AssetAmount.fromJson(e))));
}

/// Represents a price in a liquidity pool as a rational number.
///
/// Prices in liquidity pools are represented as fractions (numerator/denominator)
/// to maintain precision. This is used in deposit and withdraw operations to
/// specify acceptable price ranges for the exchange rate between pooled assets.
///
/// The actual price is calculated as: n / d
///
/// Example:
/// If n = 3 and d = 2, the price is 1.5 (meaning 1.5 units of asset A per 1 unit of asset B)
class LiquidityPoolPriceResponse extends Response {
  /// Price numerator
  int n;

  /// Price denominator
  int d;

  /// Creates a LiquidityPoolPriceResponse from Horizon API data.
  ///
  /// This constructor is typically called internally when deserializing price
  /// data from Horizon API responses.
  ///
  /// Parameters:
  /// - [n] Price numerator
  /// - [d] Price denominator
  LiquidityPoolPriceResponse(this.n, this.d);

  /// Deserializes a liquidity pool price response from JSON.
  factory LiquidityPoolPriceResponse.fromJson(Map<String, dynamic> json) {
    int pn = json['n'] == null
        ? throw Exception("n is null in horizon response")
        : json['n']!;
    int pd = json['d'] == null
        ? throw Exception("d is null in horizon response")
        : json['d']!;
    return LiquidityPoolPriceResponse(pn, pd);
  }
}
