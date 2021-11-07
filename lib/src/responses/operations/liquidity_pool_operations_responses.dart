// Copyright 2021 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import '../liquidity_pool_response.dart';
import 'operation_responses.dart';
import '../response.dart';

class LiquidityPoolDepositOperationResponse extends OperationResponse {
  String liquidityPoolId;
  List<ReserveResponse> reservesMax;
  String minPrice;
  LiquidityPoolPriceResponse minPriceR;
  String maxPrice;
  LiquidityPoolPriceResponse maxPriceR;
  List<ReserveResponse> reservesDeposited;
  String sharesReceived;

  LiquidityPoolDepositOperationResponse(
      {required this.liquidityPoolId,
      required this.reservesMax,
      required this.minPrice,
      required this.minPriceR,
      required this.maxPrice,
      required this.maxPriceR,
      required this.reservesDeposited,
      required this.sharesReceived});

  factory LiquidityPoolDepositOperationResponse.fromJson(
          Map<String, dynamic> json) =>
      LiquidityPoolDepositOperationResponse(
          liquidityPoolId: json['liquidity_pool_id'],
          reservesMax: json['reserves_max'] != null
              ? List<ReserveResponse>.from(json['reserves_max']
                  .map((e) => e == null ? null : ReserveResponse.fromJson(e)))
              : throw Exception("reserves_max is null in horizon response"),
          minPrice: json['min_price'],
          minPriceR: json['min_price_r'] == null
              ? throw Exception("min_price_r is null in horizon response")
              : LiquidityPoolPriceResponse.fromJson(json['min_price_r']),
          maxPrice: json['max_price'],
          maxPriceR: json['max_price_r'] == null
              ? throw Exception("max_price_r is null in horizon response")
              : LiquidityPoolPriceResponse.fromJson(json['max_price_r']),
          reservesDeposited: json['reserves_deposited'] != null
              ? List<ReserveResponse>.from(json['reserves_deposited']
                  .map((e) => e == null ? null : ReserveResponse.fromJson(e)))
              : throw Exception("reserves_max is null in horizon response"),
          sharesReceived: json['shares_received'])
        ..id = int.tryParse(json['id'])
        ..sourceAccount =
            json['source_account'] == null ? null : json['source_account']
        ..sourceAccountMuxed = json['source_account_muxed'] == null
            ? null
            : json['source_account_muxed']
        ..sourceAccountMuxedId = json['source_account_muxed_id'] == null
            ? null
            : json['source_account_muxed_id']
        ..pagingToken = json['paging_token']
        ..createdAt = json['created_at']
        ..transactionHash = json['transaction_hash']
        ..transactionSuccessful = json['transaction_successful']
        ..type = json['type']
        ..links = json['_links'] == null
            ? null
            : OperationResponseLinks.fromJson(json['_links']);
}

class LiquidityPoolWithdrawOperationResponse extends OperationResponse {
  String liquidityPoolId;
  List<ReserveResponse> reservesMin;
  String shares;
  List<ReserveResponse> reservesReceived;

  LiquidityPoolWithdrawOperationResponse(
      {required this.liquidityPoolId,
      required this.reservesMin,
      required this.shares,
      required this.reservesReceived});

  factory LiquidityPoolWithdrawOperationResponse.fromJson(
          Map<String, dynamic> json) =>
      LiquidityPoolWithdrawOperationResponse(
          liquidityPoolId: json['liquidity_pool_id'],
          reservesMin: json['reserves_min'] != null
              ? List<ReserveResponse>.from(json['reserves_min']
                  .map((e) => e == null ? null : ReserveResponse.fromJson(e)))
              : throw Exception("reserves_max is null in horizon response"),
          shares: json['shares'],
          reservesReceived: json['reserves_received'] != null
              ? List<ReserveResponse>.from(json['reserves_received']
                  .map((e) => e == null ? null : ReserveResponse.fromJson(e)))
              : throw Exception("reserves_max is null in horizon response"))
        ..id = int.tryParse(json['id'])
        ..sourceAccount =
            json['source_account'] == null ? null : json['source_account']
        ..sourceAccountMuxed = json['source_account_muxed'] == null
            ? null
            : json['source_account_muxed']
        ..sourceAccountMuxedId = json['source_account_muxed_id'] == null
            ? null
            : json['source_account_muxed_id']
        ..pagingToken = json['paging_token']
        ..createdAt = json['created_at']
        ..transactionHash = json['transaction_hash']
        ..transactionSuccessful = json['transaction_successful']
        ..type = json['type']
        ..links = json['_links'] == null
            ? null
            : OperationResponseLinks.fromJson(json['_links']);
}

class LiquidityPoolPriceResponse extends Response {
  int n;
  int d;

  LiquidityPoolPriceResponse(this.n, this.d);

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