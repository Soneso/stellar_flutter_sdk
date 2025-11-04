// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:http/http.dart' as http;
import 'dart:async';
import 'request_builder.dart';
import '../responses/response.dart';
import '../responses/fee_stats_response.dart';

/// Builds requests for fee statistics.
///
/// Fee stats provide information about transaction fees recently accepted by the
/// network. This data helps applications determine an appropriate fee to ensure
/// transactions are included in the ledger promptly.
///
/// The fee stats response includes:
/// - last_ledger: Most recent ledger used for fee statistics
/// - last_ledger_base_fee: Base fee in the most recent ledger
/// - ledger_capacity_usage: Measure of ledger capacity utilization
/// - fee_charged: Statistics about fees actually charged (min, mode, p10-p99)
/// - max_fee: Statistics about max fees set by transactions (min, mode, p10-p99)
///
/// Fee percentiles (p10, p20, etc.) represent the fee values at which that
/// percentage of transactions were included. For example, p50 is the median fee.
///
/// Example:
/// ```dart
/// // Get current fee statistics
/// var feeStats = await sdk.feeStats.execute();
///
/// print('Last ledger: ${feeStats.lastLedger}');
/// print('Base fee: ${feeStats.lastLedgerBaseFee}');
/// print('Median fee charged: ${feeStats.feeCharged.p50}');
/// print('95th percentile: ${feeStats.feeCharged.p95}');
///
/// // Use fee stats to set transaction fee
/// var recommendedFee = feeStats.feeCharged.mode;
/// var transaction = TransactionBuilder(sourceAccount)
///     .addOperation(operation)
///     .addMemo(memo)
///     .build();
///
/// // For time-sensitive transactions, use higher percentile
/// var urgentFee = feeStats.feeCharged.p95;
/// ```
///
/// See also:
/// - [Horizon Fee Stats API](https://developers.stellar.org/docs/data/horizon/api-reference/aggregations/fee-stats)
class FeeStatsRequestBuilder extends RequestBuilder {
  FeeStatsRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, ["fee_stats"]);

  /// Builds and executes the request.
  ///
  /// Returns: FeeStatsResponse containing fee statistics from recent ledgers
  ///
  /// The response includes percentile distributions for both fees charged and
  /// max fees set, allowing applications to choose an appropriate fee based on
  /// their priority level and urgency.
  ///
  /// Example:
  /// ```dart
  /// var feeStats = await sdk.feeStats.execute();
  ///
  /// // Check ledger capacity usage
  /// print('Capacity usage: ${feeStats.ledgerCapacityUsage}');
  ///
  /// // Get fee statistics
  /// print('Minimum fee: ${feeStats.feeCharged.min}');
  /// print('Mode (most common): ${feeStats.feeCharged.mode}');
  /// print('p50 (median): ${feeStats.feeCharged.p50}');
  /// print('p95 (high priority): ${feeStats.feeCharged.p95}');
  /// print('p99 (urgent): ${feeStats.feeCharged.p99}');
  ///
  /// // Choose fee based on priority
  /// int fee;
  /// if (urgentTransaction) {
  ///   fee = feeStats.feeCharged.p95;
  /// } else {
  ///   fee = feeStats.feeCharged.mode;
  /// }
  /// ```
  ///
  /// See also:
  /// - [FeeStatsResponse] for response structure
  /// - [Horizon Fee Stats API](https://developers.stellar.org/docs/data/horizon/api-reference/aggregations/fee-stats)
  Future<FeeStatsResponse> execute() async {
    TypeToken<FeeStatsResponse> type = new TypeToken<FeeStatsResponse>();
    ResponseHandler<FeeStatsResponse> responseHandler = new ResponseHandler<FeeStatsResponse>(type);

    return await httpClient.get(this.buildUri(), headers: RequestBuilder.headers).then((response) {
      return responseHandler.handleResponse(response);
    });
  }
}
