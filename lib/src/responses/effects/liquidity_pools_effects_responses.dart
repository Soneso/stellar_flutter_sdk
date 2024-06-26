// Copyright 2021 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'effect_responses.dart';

class LiquidityPoolEffectResponse {
  String poolId;
  int fee;
  String type;
  String totalTrustlines;
  String totalShares;
  List<AssetAmount> reserves;

  LiquidityPoolEffectResponse(
      {required this.poolId,
      required this.fee,
      required this.type,
      required this.totalTrustlines,
      required this.totalShares,
      required this.reserves});

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

/// Effect Liquidity Pool Deposited occurs when a liquidity pool incurs a deposit.
class LiquidityPoolDepositedEffectResponse extends EffectResponse {
  LiquidityPoolEffectResponse liquidityPool;
  List<AssetAmount> reservesDeposited;
  String sharesReceived;

  LiquidityPoolDepositedEffectResponse(super.id, super.type_i, super.type,
      super.createdAt, super.pagingToken, super.account, super.links,
      {required this.liquidityPool,
      required this.reservesDeposited,
      required this.sharesReceived});

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

/// Effect Liquidity Pool Withdrew occurs when a liquidity pool incurs a withdrawal.
class LiquidityPoolWithdrewEffectResponse extends EffectResponse {
  LiquidityPoolEffectResponse liquidityPool;
  List<AssetAmount> reservesReceived;
  String sharesRedeemed;

  LiquidityPoolWithdrewEffectResponse(super.id, super.type_i, super.type,
      super.createdAt, super.pagingToken, super.account, super.links,
      {required this.liquidityPool,
      required this.reservesReceived,
      required this.sharesRedeemed});

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

/// Effect Liquidity Pool Trade occurs when a trade happens in a liquidity pool.
class LiquidityPoolTradeEffectResponse extends EffectResponse {
  LiquidityPoolEffectResponse liquidityPool;
  AssetAmount sold;
  AssetAmount bought;

  LiquidityPoolTradeEffectResponse(super.id, super.type_i, super.type,
      super.createdAt, super.pagingToken, super.account, super.links,
      {required this.liquidityPool, required this.sold, required this.bought});

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

/// Effect Liquidity Pool Created occurs when a liquidity pool is created
class LiquidityPoolCreatedEffectResponse extends EffectResponse {
  LiquidityPoolEffectResponse liquidityPool;

  LiquidityPoolCreatedEffectResponse(super.id, super.type_i, super.type,
      super.createdAt, super.pagingToken, super.account, super.links,
      {required this.liquidityPool});

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

/// Effect Liquidity Pool Removed occurs when a liquidity pool is removed
class LiquidityPoolRemovedEffectResponse extends EffectResponse {
  String liquidityPoolId;

  LiquidityPoolRemovedEffectResponse(super.id, super.type_i, super.type,
      super.createdAt, super.pagingToken, super.account, super.links,
      {required this.liquidityPoolId});

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

class LiquidityPoolClaimableAssetAmount {
  String asset;
  String amount;
  String claimableBalanceId;

  LiquidityPoolClaimableAssetAmount(
      this.asset, this.amount, this.claimableBalanceId);

  factory LiquidityPoolClaimableAssetAmount.fromJson(
      Map<String, dynamic> json) {
    return LiquidityPoolClaimableAssetAmount(
        json['asset'], json['amount'], json['claimable_balance_id']);
  }
}

/// Effect Liquidity Pool Revoked occurs when a liquidity pool is revoked.
class LiquidityPoolRevokedEffectResponse extends EffectResponse {
  LiquidityPoolEffectResponse liquidityPool;
  List<LiquidityPoolClaimableAssetAmount> reservesRevoked;
  String sharesRevoked;

  LiquidityPoolRevokedEffectResponse(super.id, super.type_i, super.type,
      super.createdAt, super.pagingToken, super.account, super.links,
      {required this.liquidityPool,
      required this.reservesRevoked,
      required this.sharesRevoked});

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
