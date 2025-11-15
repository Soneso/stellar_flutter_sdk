// Copyright 2021 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'effect_responses.dart';

/// Represents liquidity pool details in effect responses.
///
/// Provides pool information when liquidity pool effects occur. Contains pool
/// identification, configuration, and current state data.
///
/// Fields:
/// - [poolId] Unique pool identifier
/// - [fee] Trading fee in basis points
/// - [type] Pool type (currently "constant_product")
/// - [totalTrustlines] Number of accounts with pool shares
/// - [totalShares] Total outstanding pool share tokens
/// - [reserves] Current asset balances in the pool
///
/// Used by:
/// - [LiquidityPoolDepositedEffectResponse]
/// - [LiquidityPoolWithdrewEffectResponse]
/// - [LiquidityPoolTradeEffectResponse]
/// - [LiquidityPoolCreatedEffectResponse]
/// - [LiquidityPoolRevokedEffectResponse]
///
/// See also:
/// - [LiquidityPoolResponse] for full pool details
/// - [Stellar developer docs](https://developers.stellar.org)
class LiquidityPoolEffectResponse {
  /// Unique identifier for this liquidity pool (L... format).
  String poolId;

  /// Trading fee in basis points (e.g., 30 = 0.3% fee).
  int fee;

  /// Pool type (currently only "constant_product").
  String type;

  /// Number of accounts holding pool shares (decimal string format).
  String totalTrustlines;

  /// Total outstanding pool share tokens (decimal string format).
  String totalShares;
  List<AssetAmount> reserves;

  /// Creates a liquidity pool effect response with pool details.
  ///
  /// Parameters:
  /// - [poolId] Unique identifier for this liquidity pool
  /// - [fee] Trading fee in basis points
  /// - [type] Pool type (currently only "constant_product")
  /// - [totalTrustlines] Number of accounts holding pool shares
  /// - [totalShares] Total outstanding pool share tokens
  /// - [reserves] Current asset balances in the pool
  LiquidityPoolEffectResponse(
      {required this.poolId,
      required this.fee,
      required this.type,
      required this.totalTrustlines,
      required this.totalShares,
      required this.reserves});

  /// Creates a liquidity pool effect response from Horizon API JSON.
  factory LiquidityPoolEffectResponse.fromJson(Map<String, dynamic> json) {
    return LiquidityPoolEffectResponse(
        poolId: json['id'],
        fee: json['fee_bp'],
        type: json['type'],
        totalTrustlines: json['total_trustlines'],
        totalShares: json['total_shares'],
        reserves: List<AssetAmount>.from(
            json['reserves'].map((e) => AssetAmount.fromJson(e))));
  }
}

/// Represents a liquidity pool deposited effect response from Horizon.
///
/// This effect occurs when an account deposits assets into a liquidity pool and receives
/// pool shares in return. The depositor must maintain balanced reserves according to the pool ratio.
///
/// Triggered by: LiquidityPoolDepositOperation
/// Returned by: Horizon API effects endpoint when querying for liquidity pool deposit effects
///
/// Example:
/// ```dart
/// final effects = await sdk.effects.forAccount('account_id').execute();
/// for (var effect in effects.records) {
///   if (effect is LiquidityPoolDepositedEffectResponse) {
///     print('Deposited to pool ${effect.liquidityPool.poolId}');
///     print('Shares received: ${effect.sharesReceived}');
///   }
/// }
/// ```
///
/// See also:
/// - [LiquidityPoolDepositOperation] for depositing to pools
/// - [LiquidityPoolWithdrewEffectResponse] for withdrawals
/// - [Stellar developer docs](https://developers.stellar.org)
class LiquidityPoolDepositedEffectResponse extends EffectResponse {
  /// The liquidity pool details
  LiquidityPoolEffectResponse liquidityPool;

  /// The amounts of each reserve asset deposited
  List<AssetAmount> reservesDeposited;

  /// The number of pool shares received
  String sharesReceived;

  /// Creates a liquidity pool deposited effect response with deposit details.
  ///
  /// This constructor is typically called internally when deserializing effect
  /// records from Horizon API responses.
  ///
  /// Parameters:
  /// - [liquidityPool] The liquidity pool details
  /// - [reservesDeposited] Amounts of each reserve asset deposited
  /// - [sharesReceived] Number of pool shares received
  LiquidityPoolDepositedEffectResponse(super.id, super.type_i, super.type,
      super.createdAt, super.pagingToken, super.account, super.links,
      {required this.liquidityPool,
      required this.reservesDeposited,
      required this.sharesReceived});

  /// Creates a liquidity pool deposited effect from Horizon API JSON.
  factory LiquidityPoolDepositedEffectResponse.fromJson(
          Map<String, dynamic> json) =>
      LiquidityPoolDepositedEffectResponse(
          json['id'],
          json['type_i'],
          json['type'],
          json['created_at'],
          json['paging_token'],
          json['account'],
          EffectResponseLinks.fromJson(json['_links']),
          liquidityPool:
              LiquidityPoolEffectResponse.fromJson(json['liquidity_pool']),
          reservesDeposited: List<AssetAmount>.from(
              json['reserves_deposited'].map((e) => AssetAmount.fromJson(e))),
          sharesReceived: json['shares_received'])
        ..accountMuxed = json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'];
}

/// Represents a liquidity pool withdrew effect response from Horizon.
///
/// This effect occurs when an account redeems pool shares to withdraw assets from a liquidity pool.
/// The account receives a proportional share of each reserve asset based on shares redeemed.
///
/// Triggered by: LiquidityPoolWithdrawOperation
/// Returned by: Horizon API effects endpoint when querying for liquidity pool withdrawal effects
///
/// Example:
/// ```dart
/// final effects = await sdk.effects.forAccount('account_id').execute();
/// for (var effect in effects.records) {
///   if (effect is LiquidityPoolWithdrewEffectResponse) {
///     print('Withdrew from pool ${effect.liquidityPool.poolId}');
///     print('Shares redeemed: ${effect.sharesRedeemed}');
///   }
/// }
/// ```
///
/// See also:
/// - [LiquidityPoolWithdrawOperation] for withdrawing from pools
/// - [LiquidityPoolDepositedEffectResponse] for deposits
/// - [Stellar developer docs](https://developers.stellar.org)
class LiquidityPoolWithdrewEffectResponse extends EffectResponse {
  /// The liquidity pool details
  LiquidityPoolEffectResponse liquidityPool;

  /// The amounts of each reserve asset received
  List<AssetAmount> reservesReceived;

  /// The number of pool shares redeemed
  String sharesRedeemed;

  /// Creates a liquidity pool withdrew effect response with withdrawal details.
  ///
  /// This constructor is typically called internally when deserializing effect
  /// records from Horizon API responses.
  ///
  /// Parameters:
  /// - [liquidityPool] The liquidity pool details
  /// - [reservesReceived] Amounts of each reserve asset received
  /// - [sharesRedeemed] Number of pool shares redeemed
  LiquidityPoolWithdrewEffectResponse(super.id, super.type_i, super.type,
      super.createdAt, super.pagingToken, super.account, super.links,
      {required this.liquidityPool,
      required this.reservesReceived,
      required this.sharesRedeemed});

  /// Creates a liquidity pool withdrew effect from Horizon API JSON.
  factory LiquidityPoolWithdrewEffectResponse.fromJson(
          Map<String, dynamic> json) =>
      LiquidityPoolWithdrewEffectResponse(
          json['id'],
          json['type_i'],
          json['type'],
          json['created_at'],
          json['paging_token'],
          json['account'],
          EffectResponseLinks.fromJson(json['_links']),
          liquidityPool:
              LiquidityPoolEffectResponse.fromJson(json['liquidity_pool']),
          reservesReceived: List<AssetAmount>.from(
              json['reserves_received'].map((e) => AssetAmount.fromJson(e))),
          sharesRedeemed: json['shares_redeemed'])
        ..accountMuxed = json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'];
}

/// Represents a liquidity pool trade effect response from Horizon.
///
/// This effect occurs when a trade is executed against a liquidity pool through path payments
/// or offers. The pool's reserves are automatically adjusted based on the constant product formula.
///
/// Triggered by: Path payment operations or offer operations that match with the pool
/// Returned by: Horizon API effects endpoint when querying for liquidity pool trade effects
///
/// Example:
/// ```dart
/// final effects = await sdk.effects.forAccount('account_id').execute();
/// for (var effect in effects.records) {
///   if (effect is LiquidityPoolTradeEffectResponse) {
///     print('Pool trade in ${effect.liquidityPool.poolId}');
///     print('Sold: ${effect.sold.amount} ${effect.sold.asset}');
///     print('Bought: ${effect.bought.amount} ${effect.bought.asset}');
///   }
/// }
/// ```
///
/// See also:
/// - [PathPaymentStrictSendOperation] and [PathPaymentStrictReceiveOperation]
/// - [Stellar developer docs](https://developers.stellar.org)
class LiquidityPoolTradeEffectResponse extends EffectResponse {
  /// The liquidity pool details
  LiquidityPoolEffectResponse liquidityPool;

  /// The asset and amount sold in the trade
  AssetAmount sold;

  /// The asset and amount bought in the trade
  AssetAmount bought;

  /// Creates a liquidity pool trade effect response with trade details.
  ///
  /// This constructor is typically called internally when deserializing effect
  /// records from Horizon API responses.
  ///
  /// Parameters:
  /// - [liquidityPool] The liquidity pool details
  /// - [sold] Asset and amount sold in the trade
  /// - [bought] Asset and amount bought in the trade
  LiquidityPoolTradeEffectResponse(super.id, super.type_i, super.type,
      super.createdAt, super.pagingToken, super.account, super.links,
      {required this.liquidityPool, required this.sold, required this.bought});

  /// Creates a liquidity pool trade effect from Horizon API JSON.
  factory LiquidityPoolTradeEffectResponse.fromJson(
          Map<String, dynamic> json) =>
      LiquidityPoolTradeEffectResponse(
          json['id'],
          json['type_i'],
          json['type'],
          json['created_at'],
          json['paging_token'],
          json['account'],
          EffectResponseLinks.fromJson(json['_links']),
          liquidityPool:
              LiquidityPoolEffectResponse.fromJson(json['liquidity_pool']),
          sold: AssetAmount.fromJson(json['sold']),
          bought: AssetAmount.fromJson(json['bought']))
        ..accountMuxed = json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'];
}

/// Represents a liquidity pool created effect response from Horizon.
///
/// This effect occurs when a new liquidity pool is created on the network. The pool is created
/// automatically when the first account establishes a trustline to the pool's shares.
///
/// Triggered by: ChangeTrustOperation for liquidity pool shares
/// Returned by: Horizon API effects endpoint when querying for liquidity pool creation effects
///
/// Example:
/// ```dart
/// final effects = await sdk.effects.forAccount('account_id').execute();
/// for (var effect in effects.records) {
///   if (effect is LiquidityPoolCreatedEffectResponse) {
///     print('Liquidity pool created: ${effect.liquidityPool.poolId}');
///     print('Type: ${effect.liquidityPool.type}');
///   }
/// }
/// ```
///
/// See also:
/// - [ChangeTrustOperation] for creating pool trustlines
/// - [LiquidityPoolRemovedEffectResponse] for pool removal
/// - [Stellar developer docs](https://developers.stellar.org)
class LiquidityPoolCreatedEffectResponse extends EffectResponse {
  /// The created liquidity pool details
  LiquidityPoolEffectResponse liquidityPool;

  /// Creates a liquidity pool created effect response with pool details.
  ///
  /// This constructor is typically called internally when deserializing effect
  /// records from Horizon API responses.
  ///
  /// Parameters:
  /// - [liquidityPool] The created liquidity pool details
  LiquidityPoolCreatedEffectResponse(super.id, super.type_i, super.type,
      super.createdAt, super.pagingToken, super.account, super.links,
      {required this.liquidityPool});

  /// Creates a liquidity pool created effect from Horizon API JSON.
  factory LiquidityPoolCreatedEffectResponse.fromJson(
          Map<String, dynamic> json) =>
      LiquidityPoolCreatedEffectResponse(
          json['id'],
          json['type_i'],
          json['type'],
          json['created_at'],
          json['paging_token'],
          json['account'],
          EffectResponseLinks.fromJson(json['_links']),
          liquidityPool:
              LiquidityPoolEffectResponse.fromJson(json['liquidity_pool']))
        ..accountMuxed = json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'];
}

/// Represents a liquidity pool removed effect response from Horizon.
///
/// This effect occurs when a liquidity pool is removed from the network. This happens when
/// the last trustline to the pool's shares is removed and the pool has no remaining reserves.
///
/// Triggered by: ChangeTrustOperation removing the last pool share trustline
/// Returned by: Horizon API effects endpoint when querying for liquidity pool removal effects
///
/// Example:
/// ```dart
/// final effects = await sdk.effects.forAccount('account_id').execute();
/// for (var effect in effects.records) {
///   if (effect is LiquidityPoolRemovedEffectResponse) {
///     print('Liquidity pool removed: ${effect.liquidityPoolId}');
///   }
/// }
/// ```
///
/// See also:
/// - [ChangeTrustOperation] for managing pool trustlines
/// - [LiquidityPoolCreatedEffectResponse] for pool creation
/// - [Stellar developer docs](https://developers.stellar.org)
class LiquidityPoolRemovedEffectResponse extends EffectResponse {
  /// The ID of the removed liquidity pool
  String liquidityPoolId;

  /// Creates a liquidity pool removed effect response with pool ID.
  ///
  /// This constructor is typically called internally when deserializing effect
  /// records from Horizon API responses.
  ///
  /// Parameters:
  /// - [liquidityPoolId] Unique identifier of the removed liquidity pool
  LiquidityPoolRemovedEffectResponse(super.id, super.type_i, super.type,
      super.createdAt, super.pagingToken, super.account, super.links,
      {required this.liquidityPoolId});

  /// Creates a liquidity pool removed effect from Horizon API JSON.
  factory LiquidityPoolRemovedEffectResponse.fromJson(
          Map<String, dynamic> json) =>
      LiquidityPoolRemovedEffectResponse(
          json['id'],
          json['type_i'],
          json['type'],
          json['created_at'],
          json['paging_token'],
          json['account'],
          EffectResponseLinks.fromJson(json['_links']),
          liquidityPoolId: json['liquidity_pool_id'])
        ..accountMuxed = json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'];
}

/// Represents an asset amount converted to a claimable balance from a liquidity pool.
///
/// Used in liquidity pool revoked effects to describe reserve assets that have been
/// converted to claimable balances when pool share authorization is revoked by an issuer.
/// This allows users to claim their assets even after authorization revocation.
///
/// Fields:
/// - [asset] Asset identifier in canonical form (e.g., "native" or "CODE:ISSUER")
/// - [amount] Amount of the asset converted to claimable balance
/// - [claimableBalanceId] Unique identifier for the created claimable balance
///
/// See also:
/// - [LiquidityPoolRevokedEffectResponse] which uses this class
/// - [ClaimableBalanceResponse] for claiming the balance
class LiquidityPoolClaimableAssetAmount {
  /// Asset identifier in canonical form.
  String asset;

  /// Amount of the asset converted to claimable balance.
  String amount;

  /// Unique identifier for the created claimable balance.
  String claimableBalanceId;

  /// Creates a liquidity pool claimable asset amount with asset details and claimable balance ID.
  ///
  /// Parameters:
  /// - [asset] Asset identifier in canonical form
  /// - [amount] Amount of the asset converted to claimable balance
  /// - [claimableBalanceId] Unique identifier for the created claimable balance
  LiquidityPoolClaimableAssetAmount(
      this.asset, this.amount, this.claimableBalanceId);

  /// Creates a liquidity pool claimable asset amount from Horizon API JSON.
  factory LiquidityPoolClaimableAssetAmount.fromJson(
      Map<String, dynamic> json) {
    return LiquidityPoolClaimableAssetAmount(
        json['asset'], json['amount'], json['claimable_balance_id']);
  }
}

/// Represents a liquidity pool revoked effect response from Horizon.
///
/// This effect occurs when an asset issuer revokes authorization for pool shares, causing
/// the pool shares to be converted to claimable balances. The issuer must have revocable
/// authorization enabled for this to occur.
///
/// Triggered by: SetTrustLineFlagsOperation revoking pool share authorization
/// Returned by: Horizon API effects endpoint when querying for liquidity pool revocation effects
///
/// Example:
/// ```dart
/// final effects = await sdk.effects.forAccount('account_id').execute();
/// for (var effect in effects.records) {
///   if (effect is LiquidityPoolRevokedEffectResponse) {
///     print('Pool shares revoked: ${effect.sharesRevoked}');
///     print('Pool ID: ${effect.liquidityPool.poolId}');
///   }
/// }
/// ```
///
/// See also:
/// - [SetTrustLineFlagsOperation] for managing trustline flags
/// - [LiquidityPoolDepositedEffectResponse] for deposits
/// - [Stellar developer docs](https://developers.stellar.org)
class LiquidityPoolRevokedEffectResponse extends EffectResponse {
  /// The liquidity pool details
  LiquidityPoolEffectResponse liquidityPool;

  /// The reserve amounts converted to claimable balances
  List<LiquidityPoolClaimableAssetAmount> reservesRevoked;

  /// The number of pool shares that were revoked
  String sharesRevoked;

  /// Creates a liquidity pool revoked effect response with revocation details.
  ///
  /// This constructor is typically called internally when deserializing effect
  /// records from Horizon API responses.
  ///
  /// Parameters:
  /// - [liquidityPool] The liquidity pool details
  /// - [reservesRevoked] Reserve amounts converted to claimable balances
  /// - [sharesRevoked] Number of pool shares that were revoked
  LiquidityPoolRevokedEffectResponse(super.id, super.type_i, super.type,
      super.createdAt, super.pagingToken, super.account, super.links,
      {required this.liquidityPool,
      required this.reservesRevoked,
      required this.sharesRevoked});

  /// Creates a liquidity pool revoked effect from Horizon API JSON.
  factory LiquidityPoolRevokedEffectResponse.fromJson(
          Map<String, dynamic> json) =>
      LiquidityPoolRevokedEffectResponse(
          json['id'],
          json['type_i'],
          json['type'],
          json['created_at'],
          json['paging_token'],
          json['account'],
          EffectResponseLinks.fromJson(json['_links']),
          liquidityPool:
              LiquidityPoolEffectResponse.fromJson(json['liquidity_pool']),
          reservesRevoked: List<LiquidityPoolClaimableAssetAmount>.from(
              json['reserves_revoked']
                  .map((e) => LiquidityPoolClaimableAssetAmount.fromJson(e))),
          sharesRevoked: json['shares_revoked'])
        ..accountMuxed = json['account_muxed']
        ..accountMuxedId = json['account_muxed_id'];
}
