// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'response.dart';

/// Represents fee statistics from Horizon.
///
/// Fee stats provide statistical data about recent transaction fees on the Stellar network.
/// This information helps you choose an appropriate fee for your transaction based on network
/// congestion and your urgency requirements.
///
/// Transaction fees on Stellar use a market-based approach where validators prioritize
/// transactions with higher fees when the network is congested. Fee stats help you:
/// - Estimate the minimum fee needed for transaction inclusion
/// - Choose fees based on desired confirmation urgency
/// - Understand current network capacity utilization
///
/// Example:
/// ```dart
/// var feeStats = await sdk.feeStats.execute();
///
/// // Check network capacity
/// print('Network capacity usage: ${feeStats.lastLedgerCapacityUsage}');
///
/// // Choose fee based on urgency
/// String chosenFee;
/// if (urgency == 'low') {
///   // Use p10 - 10% of transactions paid this or less (slower confirmation)
///   chosenFee = feeStats.feeCharged.p10;
/// } else if (urgency == 'normal') {
///   // Use p50 (median) - balanced approach
///   chosenFee = feeStats.feeCharged.p50;
/// } else {
///   // Use p95 - high priority, faster confirmation
///   chosenFee = feeStats.feeCharged.p95;
/// }
///
/// // Build transaction with chosen fee
/// var transaction = TransactionBuilder(account)
///     .addOperation(operation)
///     .build();
/// transaction.fee = int.parse(chosenFee);
/// ```
///
/// See also:
/// - [TransactionBuilder] for building transactions with fees
/// - [Horizon Fee Stats API](https://developers.stellar.org/docs/data/horizon/api-reference/aggregations/fee-stats)
class FeeStatsResponse extends Response {
  /// Ledger sequence number of the most recent ledger included in fee stats.
  String lastLedger;

  /// Base fee (in stroops) for the last ledger. This is the network minimum fee.
  String lastLedgerBaseFee;

  /// Capacity usage ratio for the last ledger (e.g., "0.5" means 50% full).
  ///
  /// Higher values indicate network congestion. When approaching 1.0, validators
  /// prioritize transactions with higher fees. Values consistently near 1.0 suggest
  /// you should use higher percentile fees for reliable confirmation.
  String lastLedgerCapacityUsage;

  /// Statistics about fees actually charged in recent transactions.
  ///
  /// Use these percentiles to select an appropriate fee based on your urgency:
  /// - p10: Low priority (slower confirmation possible)
  /// - p50: Normal priority (median fee)
  /// - p95-p99: High priority (faster confirmation likely)
  FeeChargedResponse feeCharged;

  /// Statistics about maximum fees users were willing to pay.
  ///
  /// These represent the fee caps set by users, not necessarily what was charged.
  /// Generally less useful than feeCharged for fee selection.
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

/// Statistics about fees actually charged in recent transactions.
///
/// Provides fee distribution data using percentiles. Each percentile represents the fee
/// value at that point in the distribution. For example, p10 means 10% of transactions
/// paid this fee or less, while 90% paid more.
///
/// Use these percentiles to select appropriate fees:
/// - Lower percentiles (p10-p30): Suitable when network is not congested, slower confirmation
/// - Middle percentiles (p40-p60): Balanced approach for normal priority
/// - Higher percentiles (p70-p99): Higher priority, faster confirmation when congested
class FeeChargedResponse extends Response {
  /// Maximum fee charged across all recent transactions.
  String max;

  /// Minimum fee charged across all recent transactions.
  String min;

  /// Most common fee value (mode of the distribution).
  String mode;

  /// 10th percentile: 10% of transactions paid this fee or less.
  String p10;

  /// 20th percentile: 20% of transactions paid this fee or less.
  String p20;

  /// 30th percentile: 30% of transactions paid this fee or less.
  String p30;

  /// 40th percentile: 40% of transactions paid this fee or less.
  String p40;

  /// 50th percentile (median): Half of transactions paid this fee or less.
  String p50;

  /// 60th percentile: 60% of transactions paid this fee or less.
  String p60;

  /// 70th percentile: 70% of transactions paid this fee or less.
  String p70;

  /// 80th percentile: 80% of transactions paid this fee or less.
  String p80;

  /// 90th percentile: 90% of transactions paid this fee or less.
  String p90;

  /// 95th percentile: 95% of transactions paid this fee or less.
  String p95;

  /// 99th percentile: 99% of transactions paid this fee or less.
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

/// Statistics about maximum fees users set when submitting transactions.
///
/// These values represent the fee caps users were willing to pay, not the actual fees charged.
/// The actual fee charged is typically lower and is reflected in [FeeChargedResponse].
///
/// This data is generally less useful for fee selection than [FeeChargedResponse], but can
/// provide insight into what users consider acceptable maximum fees.
class MaxFeeResponse extends Response {
  /// Maximum of all max_fee values set by users.
  String max;

  /// Minimum of all max_fee values set by users.
  String min;

  /// Most common max_fee value (mode of the distribution).
  String mode;

  /// 10th percentile of max_fee values.
  String p10;

  /// 20th percentile of max_fee values.
  String p20;

  /// 30th percentile of max_fee values.
  String p30;

  /// 40th percentile of max_fee values.
  String p40;

  /// 50th percentile (median) of max_fee values.
  String p50;

  /// 60th percentile of max_fee values.
  String p60;

  /// 70th percentile of max_fee values.
  String p70;

  /// 80th percentile of max_fee values.
  String p80;

  /// 90th percentile of max_fee values.
  String p90;

  /// 95th percentile of max_fee values.
  String p95;

  /// 99th percentile of max_fee values.
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
