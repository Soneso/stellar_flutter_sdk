// Copyright 2021 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'effect_responses.dart';
import '../liquidity_pool_response.dart';
import '../response.dart';

class LiquidityPoolEffectResponse extends Response {
  String poolId;
  int fee;
  String type;
  String totalTrustlines;
  String totalShares;
  List<ReserveResponse> reserves;

  LiquidityPoolEffectResponse(
      {required this.poolId,
      required this.fee,
      required this.type,
      required this.totalTrustlines,
      required this.totalShares,
      required this.reserves});

  factory LiquidityPoolEffectResponse.fromJson(Map<String, dynamic> json) {
    int feebp = json['fee_bp'] == null
        ? throw Exception("fee_bp is null in horizon response")
        : json['fee_bp']!;

    return LiquidityPoolEffectResponse(
        poolId: json['id'],
        fee: feebp,
        type: json['type'],
        totalTrustlines: json['total_trustlines'],
        totalShares: json['total_shares'],
        reserves: json['reserves'] != null
            ? List<ReserveResponse>.from(json['reserves']
                .map((e) => e == null ? null : ReserveResponse.fromJson(e)))
            : throw Exception("reserves is null in horizon response"));
  }
}

class LiquidityPoolDepositedEffectResponse extends EffectResponse {
  LiquidityPoolEffectResponse liquidityPool;
  List<ReserveResponse> reservesDeposited;
  String sharesReceived;

  LiquidityPoolDepositedEffectResponse(
      {required this.liquidityPool,
      required this.reservesDeposited,
      required this.sharesReceived});

  factory LiquidityPoolDepositedEffectResponse.fromJson(
          Map<String, dynamic> json) =>
      LiquidityPoolDepositedEffectResponse(
          liquidityPool: json['liquidity_pool'] == null
              ? throw Exception("liquidity_pool is null in horizon response")
              : LiquidityPoolEffectResponse.fromJson(json['liquidity_pool']),
          reservesDeposited: json['reserves_deposited'] != null
              ? List<ReserveResponse>.from(json['reserves_deposited']
                  .map((e) => e == null ? null : ReserveResponse.fromJson(e)))
              : throw Exception(
                  "reserves_deposited is null in horizon response"),
          sharesReceived: json['shares_received'])
        ..id = json['id']
        ..account = json['account'] == null ? null : json['account']
        ..accountMuxed =
            json['account_muxed'] == null ? null : json['account_muxed']
        ..accountMuxedId =
            json['account_muxed_id'] == null ? null : json['account_muxed_id']
        ..type = json['type']
        ..createdAt = json['created_at']
        ..pagingToken = json['paging_token']
        ..links = json['_links'] == null
            ? null
            : EffectResponseLinks.fromJson(json['_links']);
}

class LiquidityPoolWithdrewEffectResponse extends EffectResponse {
  LiquidityPoolEffectResponse liquidityPool;
  List<ReserveResponse> reservesReceived;
  String sharesRedeemed;

  LiquidityPoolWithdrewEffectResponse(
      {required this.liquidityPool,
      required this.reservesReceived,
      required this.sharesRedeemed});

  factory LiquidityPoolWithdrewEffectResponse.fromJson(
          Map<String, dynamic> json) =>
      LiquidityPoolWithdrewEffectResponse(
          liquidityPool: json['liquidity_pool'] == null
              ? throw Exception("liquidity_pool is null in horizon response")
              : LiquidityPoolEffectResponse.fromJson(json['liquidity_pool']),
          reservesReceived: json['reserves_received'] != null
              ? List<ReserveResponse>.from(json['reserves_received']
                  .map((e) => e == null ? null : ReserveResponse.fromJson(e)))
              : throw Exception(
                  "reserves_received is null in horizon response"),
          sharesRedeemed: json['shares_redeemed'])
        ..id = json['id']
        ..account = json['account'] == null ? null : json['account']
        ..accountMuxed =
            json['account_muxed'] == null ? null : json['account_muxed']
        ..accountMuxedId =
            json['account_muxed_id'] == null ? null : json['account_muxed_id']
        ..type = json['type']
        ..createdAt = json['created_at']
        ..pagingToken = json['paging_token']
        ..links = json['_links'] == null
            ? null
            : EffectResponseLinks.fromJson(json['_links']);
}

class LiquidityPoolTradeEffectResponse extends EffectResponse {
  LiquidityPoolEffectResponse liquidityPool;
  List<ReserveResponse> reserves;
  ReserveResponse sold;
  ReserveResponse bought;

  LiquidityPoolTradeEffectResponse(
      {required this.liquidityPool,
      required this.reserves,
      required this.sold,
      required this.bought});

  factory LiquidityPoolTradeEffectResponse.fromJson(
          Map<String, dynamic> json) =>
      LiquidityPoolTradeEffectResponse(
          liquidityPool: json['liquidity_pool'] == null
              ? throw Exception("liquidity_pool is null in horizon response")
              : LiquidityPoolEffectResponse.fromJson(json['liquidity_pool']),
          reserves: json['reserves'] != null
              ? List<ReserveResponse>.from(json['reserves']
                  .map((e) => e == null ? null : ReserveResponse.fromJson(e)))
              : throw Exception("reserves is null in horizon response"),
          sold: json['sold'] == null
              ? throw Exception("sold is null in horizon response")
              : ReserveResponse.fromJson(json['sold']),
          bought: json['bought'] == null
              ? throw Exception("bought is null in horizon response")
              : ReserveResponse.fromJson(json['bought']))
        ..id = json['id']
        ..account = json['account'] == null ? null : json['account']
        ..accountMuxed =
            json['account_muxed'] == null ? null : json['account_muxed']
        ..accountMuxedId =
            json['account_muxed_id'] == null ? null : json['account_muxed_id']
        ..type = json['type']
        ..createdAt = json['created_at']
        ..pagingToken = json['paging_token']
        ..links = json['_links'] == null
            ? null
            : EffectResponseLinks.fromJson(json['_links']);
}

class LiquidityPoolCreatedEffectResponse extends EffectResponse {
  LiquidityPoolEffectResponse liquidityPool;

  LiquidityPoolCreatedEffectResponse({required this.liquidityPool});

  factory LiquidityPoolCreatedEffectResponse.fromJson(
          Map<String, dynamic> json) =>
      LiquidityPoolCreatedEffectResponse(
          liquidityPool: json['liquidity_pool'] == null
              ? throw Exception("liquidity_pool is null in horizon response")
              : LiquidityPoolEffectResponse.fromJson(json['liquidity_pool']))
        ..id = json['id']
        ..account = json['account'] == null ? null : json['account']
        ..accountMuxed =
            json['account_muxed'] == null ? null : json['account_muxed']
        ..accountMuxedId =
            json['account_muxed_id'] == null ? null : json['account_muxed_id']
        ..type = json['type']
        ..createdAt = json['created_at']
        ..pagingToken = json['paging_token']
        ..links = json['_links'] == null
            ? null
            : EffectResponseLinks.fromJson(json['_links']);
}

class LiquidityPoolRemovedEffectResponse extends EffectResponse {
  String liquidityPoolId;

  LiquidityPoolRemovedEffectResponse({required this.liquidityPoolId});

  factory LiquidityPoolRemovedEffectResponse.fromJson(
          Map<String, dynamic> json) =>
      LiquidityPoolRemovedEffectResponse(
          liquidityPoolId: json['liquidity_pool_id'])
        ..id = json['id']
        ..account = json['account'] == null ? null : json['account']
        ..accountMuxed =
            json['account_muxed'] == null ? null : json['account_muxed']
        ..accountMuxedId =
            json['account_muxed_id'] == null ? null : json['account_muxed_id']
        ..type = json['type']
        ..createdAt = json['created_at']
        ..pagingToken = json['paging_token']
        ..links = json['_links'] == null
            ? null
            : EffectResponseLinks.fromJson(json['_links']);
}

class LiquidityPoolRevokedEffectResponse extends EffectResponse {
  LiquidityPoolEffectResponse liquidityPool;
  List<ReserveResponse> reservesRevoked;
  String sharesRevoked;

  LiquidityPoolRevokedEffectResponse(
      {required this.liquidityPool,
      required this.reservesRevoked,
      required this.sharesRevoked});

  factory LiquidityPoolRevokedEffectResponse.fromJson(
          Map<String, dynamic> json) =>
      LiquidityPoolRevokedEffectResponse(
          liquidityPool: json['liquidity_pool'] == null
              ? throw Exception("liquidity_pool is null in horizon response")
              : LiquidityPoolEffectResponse.fromJson(json['liquidity_pool']),
          reservesRevoked: json['reserves_revoked'] != null
              ? List<ReserveResponse>.from(json['reserves_revoked']
                  .map((e) => e == null ? null : ReserveResponse.fromJson(e)))
              : throw Exception("reserves_revoked is null in horizon response"),
          sharesRevoked: json['shares_revoked'])
        ..id = json['id']
        ..account = json['account'] == null ? null : json['account']
        ..accountMuxed =
            json['account_muxed'] == null ? null : json['account_muxed']
        ..accountMuxedId =
            json['account_muxed_id'] == null ? null : json['account_muxed_id']
        ..type = json['type']
        ..createdAt = json['created_at']
        ..pagingToken = json['paging_token']
        ..links = json['_links'] == null
            ? null
            : EffectResponseLinks.fromJson(json['_links']);
}
