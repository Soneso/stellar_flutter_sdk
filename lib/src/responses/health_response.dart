// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'response.dart';

/// Represents health response received from the horizon server.
/// Health endpoint provides information about the current status of the Horizon server.
/// The actual Horizon API returns: {"database_connected": true, "core_up": true, "core_synced": true}
class HealthResponse extends Response {
  /// Indicates whether the Horizon database is connected.
  final bool databaseConnected;

  /// Indicates whether the Stellar Core instance is up and running.
  final bool coreUp;

  /// Indicates whether the Stellar Core instance is synced with the network.
  final bool coreSynced;

  HealthResponse({
    required this.databaseConnected,
    required this.coreUp,
    required this.coreSynced,
  });

  /// Creates a HealthResponse from a JSON object.
  factory HealthResponse.fromJson(Map<String, dynamic> json) {
    return HealthResponse(
      databaseConnected: json['database_connected'] as bool,
      coreUp: json['core_up'] as bool,
      coreSynced: json['core_synced'] as bool,
    );
  }

  /// Returns true if the server is healthy (all systems operational).
  /// The server is considered healthy when database is connected, core is up, and core is synced.
  bool get isHealthy => databaseConnected && coreUp && coreSynced;

  /// Converts this response to a JSON object.
  Map<String, dynamic> toJson() {
    return {
      'database_connected': databaseConnected,
      'core_up': coreUp,
      'core_synced': coreSynced,
    };
  }

  @override
  String toString() {
    return 'HealthResponse{databaseConnected: $databaseConnected, coreUp: $coreUp, coreSynced: $coreSynced}';
  }
}