// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'response.dart';

/// Represents root endpoint response received from the horizon server.
class RootResponse extends Response {
  String horizonVersion;
  String stellarCoreVersion;
  int ingestLatestLedger;
  int historyLatestLedger;
  String historyLatestLedgerClosedAt;
  int historyElderLedger;
  int coreLatestLedger;
  String networkPassphrase;
  int currentProtocolVersion;
  int supportedProtocolVersion;
  int coreSupportedProtocolVersion;

  RootResponse(
      this.horizonVersion,
      this.stellarCoreVersion,
      this.ingestLatestLedger,
      this.historyLatestLedger,
      this.historyLatestLedgerClosedAt,
      this.historyElderLedger,
      this.coreLatestLedger,
      this.networkPassphrase,
      this.currentProtocolVersion,
      this.supportedProtocolVersion,
      this.coreSupportedProtocolVersion);

  factory RootResponse.fromJson(Map<String, dynamic> json) => new RootResponse(
      json['horizon_version'],
      json['core_version'],
      convertInt(json['ingest_latest_ledger'])!,
      convertInt(json['history_latest_ledger'])!,
      json['history_latest_ledger_closed_at'],
      convertInt(json['history_elder_ledger'])!,
      convertInt(json['core_latest_ledger'])!,
      json['network_passphrase'],
      convertInt(json['current_protocol_version'])!,
      convertInt(json['supported_protocol_version'])!,
      convertInt(json['core_supported_protocol_version'])!)
    ..rateLimitLimit = convertInt(json['rateLimitLimit'])
    ..rateLimitRemaining = convertInt(json['rateLimitRemaining'])
    ..rateLimitReset = convertInt(json['rateLimitReset']);
}
