// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'response.dart';

/// Represents root endpoint response received from the horizon server.
class RootResponse extends Response {
  String horizonVersion;
  String stellarCoreVersion;
  int historyLatestLedger;
  int historyElderLedger;
  int coreLatestLedger;
  String networkPassphrase;
  int protocolVersion;
  int currentProtocolVersion;
  int coreSupportedProtocolVersion;

  RootResponse(
      this.horizonVersion,
      this.stellarCoreVersion,
      this.historyLatestLedger,
      this.historyElderLedger,
      this.coreLatestLedger,
      this.networkPassphrase,
      this.protocolVersion,
      this.currentProtocolVersion,
      this.coreSupportedProtocolVersion);

  factory RootResponse.fromJson(Map<String, dynamic> json) => new RootResponse(
      json['horizon_version'] as String,
      json['core_version'] as String,
      convertInt(json['history_latest_ledger']),
      convertInt(json['history_elder_ledger']),
      convertInt(json['core_latest_ledger']),
      json['network_passphrase'] as String,
      convertInt(json['protocol_version']),
      convertInt(json['current_protocol_version']),
      convertInt(json['core_supported_protocol_version']))
    ..rateLimitLimit = convertInt(json['rateLimitLimit'])
    ..rateLimitRemaining = convertInt(json['rateLimitRemaining'])
    ..rateLimitReset = convertInt(json['rateLimitReset']);
}
