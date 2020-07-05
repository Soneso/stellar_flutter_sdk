// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'response.dart';

/// Represents fee stats response received from the horizon server. Fee stats are used to predict what fee to set for a transaction before submitting it to the network.
/// See: <a href="https://developers.stellar.org/api/aggregations/fee-stats/" target="_blank">Fee stats documentation</a>.
class FeeStatsResponse extends Response {
  String lastLedger;
  String lastLedgerBaseFee;
  String lastLedgerCapacityUsage;
  FeeChargedResponse feeCharged;
  MaxFeeResponse maxFee;

  FeeStatsResponse(this.lastLedger, this.lastLedgerBaseFee,
      this.lastLedgerCapacityUsage, this.feeCharged, this.maxFee);

  factory FeeStatsResponse.fromJson(Map<String, dynamic> json) =>
      new FeeStatsResponse(
          json['last_ledger'] as String,
          json['last_ledger_base_fee'] as String,
          json['ledger_capacity_usage'] as String,
          json['fee_charged'] == null
              ? null
              : new FeeChargedResponse.fromJson(
                  json['fee_charged'] as Map<String, dynamic>),
          json['max_fee'] == null
              ? null
              : new MaxFeeResponse.fromJson(
                  json['max_fee'] as Map<String, dynamic>));
}

class FeeChargedResponse extends Response {
  String max;
  String min;
  String mode;
  String p10;
  String p20;
  String p30;
  String p40;
  String p50;
  String p60;
  String p70;
  String p80;
  String p90;
  String p95;
  String p99;

  FeeChargedResponse(
      this.max,
      this.min,
      this.mode,
      this.p10,
      this.p20,
      this.p30,
      this.p40,
      this.p50,
      this.p60,
      this.p70,
      this.p80,
      this.p90,
      this.p95,
      this.p99);

  factory FeeChargedResponse.fromJson(Map<String, dynamic> json) =>
      new FeeChargedResponse(
          json['max'] as String,
          json['min'] as String,
          json['mode'] as String,
          json['p10'] as String,
          json['p20'] as String,
          json['p30'] as String,
          json['p40'] as String,
          json['p50'] as String,
          json['p60'] as String,
          json['p70'] as String,
          json['p80'] as String,
          json['p90'] as String,
          json['p95'] as String,
          json['p99'] as String);
}

class MaxFeeResponse extends Response {
  String max;
  String min;
  String mode;
  String p10;
  String p20;
  String p30;
  String p40;
  String p50;
  String p60;
  String p70;
  String p80;
  String p90;
  String p95;
  String p99;

  MaxFeeResponse(
      this.max,
      this.min,
      this.mode,
      this.p10,
      this.p20,
      this.p30,
      this.p40,
      this.p50,
      this.p60,
      this.p70,
      this.p80,
      this.p90,
      this.p95,
      this.p99);

  factory MaxFeeResponse.fromJson(Map<String, dynamic> json) =>
      new MaxFeeResponse(
          json['max'] as String,
          json['min'] as String,
          json['mode'] as String,
          json['p10'] as String,
          json['p20'] as String,
          json['p30'] as String,
          json['p40'] as String,
          json['p50'] as String,
          json['p60'] as String,
          json['p70'] as String,
          json['p80'] as String,
          json['p90'] as String,
          json['p95'] as String,
          json['p99'] as String);
}
