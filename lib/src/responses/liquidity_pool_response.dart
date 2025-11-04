// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import '../assets.dart';
import 'response.dart';
import 'trade_response.dart';

/// Represents a liquidity pool response from the Horizon API.
///
/// Liquidity pools enable automated market making on the Stellar network through
/// constant product market makers (x * y = k formula). Pools hold reserves of two
/// assets and allow users to trade between them or provide liquidity.
///
/// Key fields:
/// - [poolId]: Unique identifier for the liquidity pool
/// - [fee]: Trading fee in basis points (e.g., 30 = 0.3%)
/// - [type]: Pool type (currently only "constant_product")
/// - [totalTrustlines]: Number of accounts holding pool shares
/// - [totalShares]: Total outstanding pool share tokens
/// - [reserves]: Current balances of each asset in the pool
///
/// Returned by:
/// - `sdk.liquidityPools.liquidityPool(poolId)` - Get specific pool
/// - `sdk.liquidityPools.forReserves(assets)` - Find pools by assets
///
/// Example:
/// ```dart
/// // Get liquidity pool details
/// LiquidityPoolResponse pool = await sdk.liquidityPools
///   .liquidityPool(poolId)
///   .execute();
///
/// print('Pool ID: ${pool.poolId}');
/// print('Fee: ${pool.fee} basis points');
/// print('Total shares: ${pool.totalShares}');
/// print('Reserve 1: ${pool.reserves[0].amount} ${pool.reserves[0].asset}');
/// print('Reserve 2: ${pool.reserves[1].amount} ${pool.reserves[1].asset}');
/// ```
///
/// See also:
/// - [ReserveResponse] for reserve details
/// - [LiquidityPoolDepositOperation] for depositing to pools
/// - [LiquidityPoolWithdrawOperation] for withdrawing from pools
/// - [Horizon Liquidity Pools API](https://developers.stellar.org/docs/data/horizon/api-reference/resources/liquiditypools)
class LiquidityPoolResponse extends Response {
  String poolId;
  int fee;
  String type;
  String totalTrustlines;
  String totalShares;
  List<ReserveResponse> reserves;
  String pagingToken;
  LiquidityPoolResponseLinks links;

  LiquidityPoolResponse(
      {required this.poolId,
      required this.fee,
      required this.type,
      required this.totalTrustlines,
      required this.totalShares,
      required this.reserves,
      required this.pagingToken,
      required this.links});

  factory LiquidityPoolResponse.fromJson(Map<String, dynamic> json) =>
      LiquidityPoolResponse(
          poolId: json['id'],
          fee: json['fee_bp'] == null
              ? throw Exception("fee is null in horizon response")
              : convertInt(json['fee_bp'])!,
          type: json['type'],
          totalTrustlines: json['total_trustlines'],
          totalShares: json['total_shares'],
          reserves: json['reserves'] != null
              ? List<ReserveResponse>.from(json['reserves'].map((e) => e == null
                  ? throw Exception("reserve null in horizon response")
                  : ReserveResponse.fromJson(e)))
              : throw Exception("reserves are null in horizon response"),
          pagingToken: json['paging_token'],
          links: json['_links'] == null
              ? throw Exception("links are null in horizon response")
              : LiquidityPoolResponseLinks.fromJson(json['_links']));
}

class ReserveResponse {
  String amount;
  Asset asset;

  ReserveResponse(this.amount, this.asset);

  factory ReserveResponse.fromJson(Map<String, dynamic> json) {
    String amount = json['amount'];
    Asset? asset = Asset.createFromCanonicalForm(json['asset']);
    if (asset == null) {
      throw Exception(
          "not a valid asset in horizon response: " + json['asset']);
    }
    return ReserveResponse(amount, asset);
  }
}

class LiquidityPoolResponseLinks {
  Link self;
  Link operations;
  Link transactions;

  LiquidityPoolResponseLinks(
      {required this.self,
      required this.transactions,
      required this.operations});

  factory LiquidityPoolResponseLinks.fromJson(Map<String, dynamic> json) =>
      LiquidityPoolResponseLinks(
        self: json['self'] == null
            ? throw Exception("self link is null in horizon response")
            : Link.fromJson(json['self']),
        transactions: json['transactions'] == null
            ? throw Exception("transaction links are null in horizon response")
            : Link.fromJson(json['transactions']),
        operations: json['operations'] == null
            ? throw Exception("operation links are null in horizon response")
            : Link.fromJson(json['operations']),
      );
}

class LiquidityPoolTradesResponse extends Response {
  List<TradeResponse> records;
  LiquidityPoolTradesResponseLinks links;

  LiquidityPoolTradesResponse({required this.records, required this.links});

  factory LiquidityPoolTradesResponse.fromJson(Map<String, dynamic> json) =>
      LiquidityPoolTradesResponse(
          records: json["_embedded"]['records'] != null
              ? List<TradeResponse>.from(json["_embedded"]['records'].map((e) =>
                  ResponseConverter.fromJson<TradeResponse>(e)
                      as TradeResponse))
              : throw Exception("trade records are null in horizon response"),
          links: json['_links'] == null
              ? throw Exception("links are null in horizon response")
              : LiquidityPoolTradesResponseLinks.fromJson(json['_links']));
}

class LiquidityPoolTradesResponseLinks {
  Link self;

  LiquidityPoolTradesResponseLinks({required this.self});

  factory LiquidityPoolTradesResponseLinks.fromJson(
          Map<String, dynamic> json) =>
      LiquidityPoolTradesResponseLinks(
          self: json['self'] == null
              ? throw Exception("self link is null in horizon response")
              : Link.fromJson(json['self']));
}
