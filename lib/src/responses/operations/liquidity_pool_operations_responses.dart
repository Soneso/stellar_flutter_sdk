// Copyright 2024 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:stellar_flutter_sdk/src/responses/effects/effect_responses.dart';

import 'operation_responses.dart';
import '../transaction_response.dart';
import '../response.dart';

class LiquidityPoolDepositOperationResponse extends OperationResponse {
  String liquidityPoolId;
  List<AssetAmount> reservesMax;
  String minPrice;
  LiquidityPoolPriceResponse minPriceR;
  String maxPrice;
  LiquidityPoolPriceResponse maxPriceR;
  List<AssetAmount> reservesDeposited;
  String sharesReceived;

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

class LiquidityPoolWithdrawOperationResponse extends OperationResponse {
  String liquidityPoolId;
  List<AssetAmount> reservesMin;
  String shares;
  List<AssetAmount> reservesReceived;

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
