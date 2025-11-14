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
/// - [Stellar developer docs](https://developers.stellar.org)
class LiquidityPoolResponse extends Response {
  String poolId;
  int fee;
  String type;
  String totalTrustlines;
  String totalShares;
  List<ReserveResponse> reserves;
  String pagingToken;
  LiquidityPoolResponseLinks links;

  /// Creates a liquidity pool response with pool state and reserve information.
  LiquidityPoolResponse(
      {required this.poolId,
      required this.fee,
      required this.type,
      required this.totalTrustlines,
      required this.totalShares,
      required this.reserves,
      required this.pagingToken,
      required this.links});

  /// Creates a liquidity pool response from Horizon API JSON.
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

/// Represents one asset reserve in a liquidity pool.
///
/// Each constant product liquidity pool contains exactly two asset reserves.
/// The reserves represent the pool's holdings of each asset, which determine
/// the exchange rate between the assets based on the constant product formula:
/// reserve_a * reserve_b = k (constant).
///
/// See also:
/// - [LiquidityPoolResponse] for the parent pool details
/// - [Asset] for asset representation
class ReserveResponse {
  String amount;
  Asset asset;

  /// Creates a reserve response with asset amount and type.
  ReserveResponse(this.amount, this.asset);

  /// Creates a reserve response from Horizon API JSON.
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

/// HAL links for navigating related liquidity pool resources.
///
/// Provides hypermedia links to related Horizon API endpoints for a pool.
/// These links follow the HAL (Hypertext Application Language) standard and
/// enable navigation to:
/// - self: This liquidity pool's details endpoint
/// - operations: Operations involving this pool
/// - transactions: Transactions that affect this pool
///
/// See also:
/// - [LiquidityPoolResponse] for the parent pool details
/// - [Link] for link structure details
class LiquidityPoolResponseLinks {
  Link self;
  Link operations;
  Link transactions;

  /// Creates liquidity pool response links with navigation to related resources.
  LiquidityPoolResponseLinks(
      {required this.self,
      required this.transactions,
      required this.operations});

  /// Creates liquidity pool response links from Horizon API JSON.
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

/// Response containing a collection of trades for a liquidity pool.
///
/// Contains a list of trades executed against a specific liquidity pool,
/// including both the trade records and HAL links for navigation. This
/// response is returned when querying the trades endpoint for a pool.
///
/// See also:
/// - [TradeResponse] for individual trade details
/// - [LiquidityPoolResponse] for pool details
class LiquidityPoolTradesResponse extends Response {
  List<TradeResponse> records;
  LiquidityPoolTradesResponseLinks links;

  /// Creates a liquidity pool trades response with trade records and navigation links.
  LiquidityPoolTradesResponse({required this.records, required this.links});

  /// Creates a liquidity pool trades response from Horizon API JSON.
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

/// HAL links for navigating liquidity pool trades response.
///
/// Provides hypermedia link to the trades collection endpoint.
/// The self link points to the current page of trades for the pool.
///
/// See also:
/// - [LiquidityPoolTradesResponse] for the parent trades collection
/// - [Link] for link structure details
class LiquidityPoolTradesResponseLinks {
  Link self;

  /// Creates liquidity pool trades response links with self reference.
  LiquidityPoolTradesResponseLinks({required this.self});

  /// Creates liquidity pool trades response links from Horizon API JSON.
  factory LiquidityPoolTradesResponseLinks.fromJson(
          Map<String, dynamic> json) =>
      LiquidityPoolTradesResponseLinks(
          self: json['self'] == null
              ? throw Exception("self link is null in horizon response")
              : Link.fromJson(json['self']));
}
