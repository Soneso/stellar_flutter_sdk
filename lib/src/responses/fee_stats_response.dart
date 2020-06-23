// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'response.dart';

/// Represents fee stats response received from the horizon server.
///
class FeeStatsResponse extends Response {
  int min;
  int mode;
  int lastLedgerBaseFee;
  int lastLedger;

  FeeStatsResponse(
      int min, int mode, int lastLedgerBaseFee, int lastLedger);

  factory FeeStatsResponse.fromJson(Map<String, dynamic> json) => new FeeStatsResponse(
        convertInt(json['min_accepted_fee']),
        convertInt(json['mode_accepted_fee']),
        convertInt(json['last_ledger_base_fee']),
        convertInt(json['last_ledger']));
}