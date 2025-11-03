// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'response.dart';

/// Represents fee stats response received from the horizon server. Fee stats are used to predict what fee to set for a transaction before submitting it to the network.
/// See: [Fee stats documentation](https://developers.stellar.org/api/aggregations/fee-stats/).
class FeeStatsResponse extends Response {
  String lastLedger;
  String lastLedgerBaseFee;
  String lastLedgerCapacityUsage;
  FeeChargedResponse feeCharged;
  MaxFeeResponse maxFee;

  FeeStatsResponse(this.lastLedger, this.lastLedgerBaseFee, this.lastLedgerCapacityUsage,
      this.feeCharged, this.maxFee);

  factory FeeStatsResponse.fromJson(Map<String, dynamic> json) => FeeStatsResponse(
      json['last_ledger'],
      json['last_ledger_base_fee'],
      json['ledger_capacity_usage'],
      FeeChargedResponse.fromJson(json['fee_charged']),
      MaxFeeResponse.fromJson(json['max_fee']));
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

  FeeChargedResponse(this.max, this.min, this.mode, this.p10, this.p20, this.p30, this.p40,
      this.p50, this.p60, this.p70, this.p80, this.p90, this.p95, this.p99);

  factory FeeChargedResponse.fromJson(Map<String, dynamic> json) => FeeChargedResponse(
      json['max'],
      json['min'],
      json['mode'],
      json['p10'],
      json['p20'],
      json['p30'],
      json['p40'],
      json['p50'],
      json['p60'],
      json['p70'],
      json['p80'],
      json['p90'],
      json['p95'],
      json['p99']);
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

  MaxFeeResponse(this.max, this.min, this.mode, this.p10, this.p20, this.p30, this.p40, this.p50,
      this.p60, this.p70, this.p80, this.p90, this.p95, this.p99);

  factory MaxFeeResponse.fromJson(Map<String, dynamic> json) => MaxFeeResponse(
      json['max'],
      json['min'],
      json['mode'],
      json['p10'],
      json['p20'],
      json['p30'],
      json['p40'],
      json['p50'],
      json['p60'],
      json['p70'],
      json['p80'],
      json['p90'],
      json['p95'],
      json['p99']);
}
