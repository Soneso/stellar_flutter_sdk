// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'response.dart';

/// Represents the root endpoint response from a Horizon server.
///
/// RootResponse contains metadata about the Horizon instance and the Stellar
/// network it connects to. This is typically the first endpoint queried when
/// connecting to a Horizon server, providing essential information for:
/// - Verifying network connectivity
/// - Confirming the correct network (PUBNET, TESTNET, etc.)
/// - Checking server and protocol versions
/// - Determining ledger availability
///
/// The root endpoint is accessed at the base URL of the Horizon server.
///
/// Example:
/// ```dart
/// var sdk = StellarSDK.TESTNET;
/// var root = await sdk.root();
///
/// // Verify network connection
/// print('Horizon version: ${root.horizonVersion}');
/// print('Network: ${root.networkPassphrase}');
///
/// // Check server status
/// print('Latest ledger: ${root.historyLatestLedger}');
/// print('Protocol version: ${root.currentProtocolVersion}');
///
/// // Verify correct network
/// if (root.networkPassphrase == 'Test SDF Network ; September 2015') {
///   print('Connected to TESTNET');
/// } else if (root.networkPassphrase == 'Public Global Stellar Network ; September 2015') {
///   print('Connected to PUBNET');
/// }
/// ```
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
/// - [StellarSDK.root] for fetching the root endpoint
class RootResponse extends Response {
  /// Version of the Horizon server software.
  ///
  /// Example: "2.27.0"
  String horizonVersion;

  /// Version of the Stellar Core software that Horizon connects to.
  ///
  /// Example: "v19.14.0"
  String stellarCoreVersion;

  /// Latest ledger sequence number that has been ingested by Horizon.
  int ingestLatestLedger;

  /// Latest ledger sequence number stored in Horizon's history database.
  ///
  /// This represents the most recent ledger that can be queried for
  /// transactions, operations, and effects.
  int historyLatestLedger;

  /// ISO 8601 timestamp when the latest history ledger closed.
  ///
  /// Example: "2024-10-05T12:34:56Z"
  String historyLatestLedgerClosedAt;

  /// Oldest ledger sequence number available in Horizon's history.
  ///
  /// Ledgers older than this are not available for querying.
  int historyElderLedger;

  /// Latest ledger sequence number known to Stellar Core.
  int coreLatestLedger;

  /// Network passphrase identifying the Stellar network.
  ///
  /// Common values:
  /// - "Public Global Stellar Network ; September 2015" (PUBNET)
  /// - "Test SDF Network ; September 2015" (TESTNET)
  ///
  /// This should be verified to ensure you're connected to the correct network.
  String networkPassphrase;

  /// Current Stellar protocol version in use by the network.
  int currentProtocolVersion;

  /// Maximum protocol version supported by this Horizon instance.
  int supportedProtocolVersion;

  /// Protocol version supported by the connected Stellar Core.
  int coreSupportedProtocolVersion;

  /// Creates a RootResponse from Horizon API root endpoint data.
  ///
  /// This constructor is typically called internally when deserializing JSON responses
  /// from Horizon API root endpoints.
  ///
  /// Parameters:
  /// - [horizonVersion] Version of the Horizon server software
  /// - [stellarCoreVersion] Version of the Stellar Core software
  /// - [ingestLatestLedger] Latest ledger ingested by Horizon
  /// - [historyLatestLedger] Latest ledger in Horizon's history database
  /// - [historyLatestLedgerClosedAt] Timestamp when latest history ledger closed
  /// - [historyElderLedger] Oldest ledger available in Horizon's history
  /// - [coreLatestLedger] Latest ledger known to Stellar Core
  /// - [networkPassphrase] Network passphrase identifying the Stellar network
  /// - [currentProtocolVersion] Current Stellar protocol version
  /// - [supportedProtocolVersion] Maximum protocol version supported by Horizon
  /// - [coreSupportedProtocolVersion] Protocol version supported by Stellar Core
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

  /// Constructs a RootResponse from JSON returned by Horizon API root endpoint.
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
