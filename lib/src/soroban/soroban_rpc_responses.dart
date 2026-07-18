// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import '../xdr/xdr.dart';

/// Abstract class for soroban rpc responses.
abstract class SorobanRpcResponse {
  Map<String, dynamic>
      jsonResponse; // JSON response received from the rpc server
  SorobanRpcErrorResponse? error;

  /// Creates a SorobanRpcResponse with JSON response data.
  ///
  /// Base constructor for all Soroban RPC response types.
  SorobanRpcResponse(this.jsonResponse);

  bool get isErrorResponse => error != null;
}

/// General node health check response.
/// See: https://developers.stellar.org/network/soroban-rpc/api-reference/methods/getHealth
class GetHealthResponse extends SorobanRpcResponse {
  /// Health status e.g. "healthy"
  String? status;

  /// Maximum retention window configured. A full window state can be determined
  /// via: ledgerRetentionWindow = latestLedger - oldestLedger + 1
  int? ledgerRetentionWindow;

  /// Most recent known ledger sequence
  int? latestLedger;

  /// Oldest ledger sequence kept in history.
  int? oldestLedger;

  /// The unix timestamp (seconds) of the close time of the latest known
  /// ledger, as a string. Returned by RPC servers from v27.1.0; null when the
  /// server does not provide it.
  String? latestLedgerCloseTime;

  /// The unix timestamp (seconds) of the close time of the oldest ledger kept
  /// in history, as a string. Returned by RPC servers from v27.1.0; null when
  /// the server does not provide it.
  String? oldestLedgerCloseTime;

  static const String HEALTHY = "healthy";

  /// Creates a GetHealthResponse from JSON-RPC response.
  ///
  /// Contains health status and ledger retention information.
  GetHealthResponse(Map<String, dynamic> jsonResponse) : super(jsonResponse);

  factory GetHealthResponse.fromJson(Map<String, dynamic> json) {
    GetHealthResponse response = GetHealthResponse(json);
    if (json['result'] != null) {
      if (json['result']['status'] != null) {
        response.status = json['result']['status'];
      }
      if (json['result']['ledgerRetentionWindow'] != null) {
        response.ledgerRetentionWindow =
            json['result']['ledgerRetentionWindow'];
      }
      if (json['result']['latestLedger'] != null) {
        response.latestLedger = json['result']['latestLedger'];
      }
      if (json['result']['oldestLedger'] != null) {
        response.oldestLedger = json['result']['oldestLedger'];
      }
      if (json['result']['latestLedgerCloseTime'] != null) {
        response.latestLedgerCloseTime =
            json['result']['latestLedgerCloseTime'];
      }
      if (json['result']['oldestLedgerCloseTime'] != null) {
        response.oldestLedgerCloseTime =
            json['result']['oldestLedgerCloseTime'];
      }
    } else if (json['error'] != null) {
      response.error = SorobanRpcErrorResponse.fromJson(json);
    }
    return response;
  }
}

/// Version information about the RPC and Captive core.
/// RPC manages its own, pared-down version of Stellar Core optimized for its own subset of needs.
/// See: https://developers.stellar.org/docs/data/rpc/api-reference/methods/getVersionInfo
class GetVersionInfoResponse extends SorobanRpcResponse {
  /// The version of the RPC server.
  String? version;

  /// The commit hash of the RPC server.
  String? commitHash;

  /// The build timestamp of the RPC server.
  String? buildTimeStamp;

  /// The version of the Captive Core.
  String? captiveCoreVersion;

  /// The protocol version.
  int? protocolVersion;

  /// Creates a GetVersionInfoResponse from JSON-RPC response.
  ///
  /// Contains version information for RPC server and Captive Core.
  GetVersionInfoResponse(Map<String, dynamic> jsonResponse)
      : super(jsonResponse);

  factory GetVersionInfoResponse.fromJson(Map<String, dynamic> json) {
    GetVersionInfoResponse response = GetVersionInfoResponse(json);
    if (json['result'] != null) {
      response.version = json['result']['version'];

      if (json['result']['commit_hash'] != null) {
        response.commitHash =
            json['result']['commit_hash']; // protocol version < 22
      } else {
        response.commitHash =
            json['result']['commitHash']; // protocol version >= 22
      }

      if (json['result']['build_time_stamp'] != null) {
        response.buildTimeStamp =
            json['result']['build_time_stamp']; // protocol version < 22
      } else {
        response.buildTimeStamp =
            json['result']['buildTimestamp']; // protocol version >= 22
      }

      if (json['result']['captive_core_version'] != null) {
        response.captiveCoreVersion =
            json['result']['captive_core_version']; // protocol version < 22
      } else {
        response.captiveCoreVersion =
            json['result']['captiveCoreVersion']; // protocol version >= 22
      }

      if (json['result']['protocol_version'] != null) {
        response.protocolVersion =
            json['result']['protocol_version']; // protocol version < 22
      } else {
        response.protocolVersion =
            json['result']['protocolVersion']; // protocol version >= 22
      }
    } else if (json['error'] != null) {
      response.error = SorobanRpcErrorResponse.fromJson(json);
    }
    return response;
  }
}

/// Statistics for charged inclusion fees. The inclusion fee statistics are calculated
/// from the inclusion fees that were paid for the transactions to be included onto the ledger.
/// For Soroban transactions and Stellar transactions, they each have their own inclusion fees
/// and own surge pricing. Inclusion fees are used to prevent spam and prioritize transactions
/// during network traffic surge.
class GetFeeStatsResponse extends SorobanRpcResponse {
  /// Inclusion fee distribution statistics for Soroban transactions
  InclusionFee? sorobanInclusionFee;

  /// Fee distribution statistics for Stellar (i.e. non-Soroban) transactions.
  /// Statistics are normalized per operation.
  InclusionFee? inclusionFee;

  /// The sequence number of the latest ledger known to Soroban RPC at the time it handled the request.
  int? latestLedger;

  /// Creates a GetFeeStatsResponse from JSON-RPC response.
  ///
  /// Contains fee statistics for Soroban and classic transactions.
  GetFeeStatsResponse(Map<String, dynamic> jsonResponse) : super(jsonResponse);

  factory GetFeeStatsResponse.fromJson(Map<String, dynamic> json) {
    GetFeeStatsResponse response = GetFeeStatsResponse(json);
    if (json['result'] != null) {
      if (json['result']['sorobanInclusionFee'] != null) {
        response.sorobanInclusionFee =
            InclusionFee.fromJson(json['result']['sorobanInclusionFee']);
      }
      if (json['result']['inclusionFee'] != null) {
        response.inclusionFee =
            InclusionFee.fromJson(json['result']['inclusionFee']);
      }
      if (json['result']['latestLedger'] != null) {
        response.latestLedger = json['result']['latestLedger'];
      }
    } else if (json['error'] != null) {
      response.error = SorobanRpcErrorResponse.fromJson(json);
    }
    return response;
  }
}

/// Statistics about transaction inclusion fees on the Soroban network.
///
/// InclusionFee provides comprehensive fee distribution data to help estimate appropriate
/// fees for transaction inclusion in upcoming ledgers. The data represents fee statistics
/// from recent ledgers and includes percentile-based fee recommendations.
///
/// Fee Selection Strategy:
/// - Use [min] for non-urgent transactions (may take longer to confirm)
/// - Use [mode] for typical transactions (most common fee paid)
/// - Use [p50] (median) for balanced priority
/// - Use [p90] or [p99] for high-priority transactions requiring fast confirmation
/// - Use [max] to see the highest fee paid in the sample period
///
/// All fee values are represented as strings in stroops (1 stroop = 0.0000001 XLM).
/// The distribution is calculated from [ledgerCount] consecutive ledgers containing
/// [transactionCount] total transactions.
///
/// Fields:
/// - [min]: Minimum fee in the distribution
/// - [max]: Maximum fee in the distribution
/// - [mode]: Most frequently occurring fee (useful for typical transactions)
/// - [p10] to [p99]: Percentile-based fee recommendations
/// - [transactionCount]: Number of transactions in the sample
/// - [ledgerCount]: Number of ledgers analyzed
///
/// Example:
/// ```dart
/// final server = SorobanServer(rpcUrl);
/// final feeStats = await server.getFeeStats();
///
/// if (feeStats.sorobanInclusionFee != null) {
///   final fees = feeStats.sorobanInclusionFee!;
///   print('Recommended fee (median): ${fees.p50} stroops');
///   print('Fast confirmation fee (90th percentile): ${fees.p90} stroops');
///   print('Based on ${fees.transactionCount} transactions');
/// }
/// ```
///
/// See also:
/// - [GetFeeStatsResponse] for the complete fee statistics response
/// - [Soroban Fee Documentation](https://developers.stellar.org/docs/data/rpc/api-reference/methods/getFeeStats)
class InclusionFee {
  /// Maximum fee
  String max;

  /// Minimum fee
  String min;

  /// Fee value which occurs the most often
  String mode;

  /// 10th nearest-rank fee percentile
  String p10;

  /// 20th nearest-rank fee percentile
  String p20;

  /// 30th nearest-rank fee percentile
  String p30;

  /// 40th nearest-rank fee percentile
  String p40;

  /// 50th nearest-rank fee percentile
  String p50;

  /// 60th nearest-rank fee percentile
  String p60;

  /// 70th nearest-rank fee percentile
  String p70;

  /// 80th nearest-rank fee percentile
  String p80;

  /// 90th nearest-rank fee percentile
  String p90;

  /// 99th nearest-rank fee percentile
  String p99;

  /// How many transactions are part of the distribution
  String transactionCount;

  /// How many consecutive ledgers form the distribution
  int ledgerCount;

  /// Creates an InclusionFee with fee distribution statistics.
  ///
  /// Contains percentile-based fee recommendations for transaction inclusion.
  InclusionFee(
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
      this.p99,
      this.transactionCount,
      this.ledgerCount);

  factory InclusionFee.fromJson(Map<String, dynamic> json) {
    return InclusionFee(
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
      json['p99'],
      json['transactionCount'],
      json['ledgerCount'],
    );
  }
}

/// See: https://developers.stellar.org/network/soroban-rpc/api-reference/methods/getLatestLedger
class GetLatestLedgerResponse extends SorobanRpcResponse {
  /// Hash identifier of the latest ledger (as a hex-encoded string) known to Soroban RPC at the time it handled the request.
  String? id;

  /// Stellar Core protocol version associated with the latest ledger.
  int? protocolVersion;

  /// The sequence number of the latest ledger known to Soroban RPC at the time it handled the request.
  int? sequence;

  /// The unix timestamp of when the latest ledger was closed.
  int? closeTime;

  /// Base64-encoded LedgerHeader XDR.
  String? headerXdr;

  /// Base64-encoded LedgerCloseMeta XDR containing ledger close metadata.
  String? metadataXdr;

  /// Creates a GetLatestLedgerResponse from JSON-RPC response.
  ///
  /// Contains the latest ledger sequence and hash information.
  GetLatestLedgerResponse(Map<String, dynamic> jsonResponse)
      : super(jsonResponse);

  factory GetLatestLedgerResponse.fromJson(Map<String, dynamic> json) {
    GetLatestLedgerResponse response = GetLatestLedgerResponse(json);
    if (json['result'] != null) {
      response.id = json['result']['id'];
      response.protocolVersion = json['result']['protocolVersion'];
      response.sequence = json['result']['sequence'];
      if (json['result']['closeTime'] != null) {
        response.closeTime = json['result']['closeTime'] is String
            ? int.parse(json['result']['closeTime'])
            : json['result']['closeTime'];
      }
      response.headerXdr = json['result']['headerXdr'];
      response.metadataXdr = json['result']['metadataXdr'];
    } else if (json['error'] != null) {
      response.error = SorobanRpcErrorResponse.fromJson(json);
    }
    return response;
  }
}

/// Error response.
class SorobanRpcErrorResponse {
  Map<String, dynamic>
      jsonResponse; // JSON response received from the rpc server
  String? code; // error code
  String? message;
  Map<String, dynamic>? data;

  /// Creates a SorobanRpcErrorResponse from error JSON.
  ///
  /// Contains error code, message, and optional additional data.
  SorobanRpcErrorResponse(this.jsonResponse);

  factory SorobanRpcErrorResponse.fromJson(Map<String, dynamic> json) {
    SorobanRpcErrorResponse response = SorobanRpcErrorResponse(json);
    if (json['error'] != null) {
      var jErrCode = json['error']['code'];
      if (jErrCode != null) {
        response.code = jErrCode.toString();
      }
      response.message = json['error']['message'];
      response.data = json['error']['data'];
    }
    return response;
  }
}

/// Response from the getLedgerEntries RPC method.
///
/// GetLedgerEntriesResponse contains ledger entries retrieved from the Soroban network.
/// Ledger entries represent contract state, contract code, and other on-chain data stored
/// in the ledger. This method allows querying the current state of contracts and their data.
///
/// The response includes:
/// - A list of [LedgerEntry] objects containing the requested entries
/// - The latest known ledger sequence for context
///
/// Use Cases:
/// - Query contract data storage (contract persistent/temporary data)
/// - Retrieve contract WASM code
/// - Read contract instance configuration
/// - Access account contract data entries
///
/// Fields:
/// - [entries]: List of ledger entries matching the query
/// - [latestLedger]: Latest ledger sequence known to RPC server
///
/// Example:
/// ```dart
/// final server = SorobanServer(rpcUrl);
///
/// // Create ledger keys for contract data
/// final contractId = StrKey.decodeContractIdHex('CABC...');
/// final dataKey = XdrSCVal.forSymbol('balance');
/// final ledgerKey = XdrLedgerKey.forContractData(contractId, dataKey);
///
/// // Query ledger entries
/// final request = GetLedgerEntriesRequest([ledgerKey]);
/// final response = await server.getLedgerEntries(request);
///
/// if (response.entries != null) {
///   for (var entry in response.entries!) {
///     print('Entry last modified: ${entry.lastModifiedLedgerSeq}');
///     print('Entry expires at ledger: ${entry.liveUntilLedgerSeq}');
///     // Decode entry data
///     final data = entry.ledgerEntryDataXdr;
///   }
/// }
/// ```
///
/// See also:
/// - [LedgerEntry] for individual entry details
/// - [SorobanServer.getLedgerEntries] for the method to fetch ledger entries
/// - [Soroban RPC Documentation](https://developers.stellar.org/docs/data/rpc/api-reference/methods/getLedgerEntries)
class GetLedgerEntriesResponse extends SorobanRpcResponse {
  /// Entries
  List<LedgerEntry>? entries;

  /// The sequence number of the latest ledger known to Soroban RPC at the time it handled the request.
  int? latestLedger;

  /// Creates a GetLedgerEntriesResponse from JSON-RPC response.
  ///
  /// Contains ledger entries retrieved from the network.
  GetLedgerEntriesResponse(Map<String, dynamic> jsonResponse)
      : super(jsonResponse);

  factory GetLedgerEntriesResponse.fromJson(Map<String, dynamic> json) {
    GetLedgerEntriesResponse response = GetLedgerEntriesResponse(json);

    if (json['result'] != null) {
      response.entries = List<LedgerEntry>.from(
          json['result']['entries'].map((e) => LedgerEntry.fromJson(e)));
      response.latestLedger = json['result']['latestLedger'];
    } else if (json['error'] != null) {
      response.error = SorobanRpcErrorResponse.fromJson(json);
    }
    return response;
  }
}

/// A single ledger entry retrieved from the Soroban network.
///
/// LedgerEntry represents a piece of data stored on the Stellar ledger, including
/// contract code, contract instance data, contract persistent data, contract temporary data,
/// and other ledger state. Each entry has a unique key and contains XDR-encoded data.
///
/// Entry Types:
/// - Contract Code: WASM bytecode for deployed smart contracts
/// - Contract Data: Persistent or temporary storage for contract state
/// - Contract Instance: Configuration and metadata for contract instances
/// - Account Data: Contract-related data attached to accounts
///
/// Expiration Management:
/// - Contract code and data entries have TTL (time-to-live) managed by [liveUntilLedgerSeq]
/// - Entries must be restored before expiration to remain accessible
/// - Use RestoreFootprint operation to extend expired entries
///
/// Fields:
/// - [key]: Unique identifier for the entry (base64-encoded XDR)
/// - [xdr]: Entry data content (base64-encoded XDR)
/// - [lastModifiedLedgerSeq]: Ledger when entry was last updated
/// - [liveUntilLedgerSeq]: Expiration ledger (contract code/data only)
/// - [ext]: Extension field (protocol 23+)
///
/// Example - Reading contract data:
/// ```dart
/// final response = await server.getLedgerEntries(request);
///
/// for (var entry in response.entries!) {
///   // Access the entry key
///   final keyValue = entry.keyValue;
///
///   // Decode entry data
///   final entryData = entry.ledgerEntryDataXdr;
///
///   // Check expiration
///   if (entry.liveUntilLedgerSeq != null) {
///     final ledgersUntilExpiry = entry.liveUntilLedgerSeq! - currentLedger;
///     if (ledgersUntilExpiry < 100) {
///       print('Entry expires soon, consider restoring');
///     }
///   }
/// }
/// ```
///
/// Example - Working with contract data:
/// ```dart
/// if (entry.ledgerEntryData.contractData != null) {
///   final contractData = entry.ledgerEntryData.contractData!;
///   final value = contractData.val;
///   print('Contract data value: $value');
/// }
/// ```
///
/// See also:
/// - [GetLedgerEntriesResponse] for querying entries
/// - [XdrLedgerEntryData] for decoded entry structure
/// - [RestoreFootprintOperation] for extending entry TTL
class LedgerEntry {
  /// The key of the ledger entry (serialized in a base64 string)
  String key;

  /// The current value of the given ledger entry (serialized in a base64 string)
  String xdr;

  /// The ledger sequence number of the last time this entry was updated.
  int lastModifiedLedgerSeq;

  /// The ledger sequence number after which the ledger entry would expire. This field exists only for ContractCodeEntry and ContractDataEntry ledger entries (optional).
  int? liveUntilLedgerSeq;

  /// The entry's "Ext" field. Only available for protocol version >= 23
  String? ext;

  XdrLedgerEntryData get ledgerEntryDataXdr =>
      XdrLedgerEntryData.fromBase64EncodedXdrString(xdr);

  /// Creates a LedgerEntry with entry data.
  ///
  /// Contains ledger entry key, value, and TTL information.
  LedgerEntry(this.key, this.xdr, this.lastModifiedLedgerSeq,
      this.liveUntilLedgerSeq, this.ext);

  factory LedgerEntry.fromJson(Map<String, dynamic> json) {
    String key = json['key'];
    String xdr = json['xdr'];
    int lastModifiedLedgerSeq = json['lastModifiedLedgerSeq'];
    int? liveUntilLedgerSeq = json['liveUntilLedgerSeq'];
    return LedgerEntry(
        key, xdr, lastModifiedLedgerSeq, liveUntilLedgerSeq, json['ext']);
  }

  XdrLedgerEntryData get ledgerEntryData =>
      XdrLedgerEntryData.fromBase64EncodedXdrString(xdr);

  XdrSCVal get keyValue => XdrSCVal.fromBase64EncodedXdrString(key);
}

/// General information about the currently configured network. This response
/// will contain all the information needed to successfully submit transactions
/// to the network this node serves.
/// See: https://developers.stellar.org/network/soroban-rpc/api-reference/methods/getNetwork
class GetNetworkResponse extends SorobanRpcResponse {
  String? friendbotUrl;
  String? passphrase;
  int? protocolVersion;

  /// Creates a GetNetworkResponse from JSON-RPC response.
  ///
  /// Contains network passphrase and protocol version.
  GetNetworkResponse(Map<String, dynamic> jsonResponse) : super(jsonResponse);

  factory GetNetworkResponse.fromJson(Map<String, dynamic> json) {
    GetNetworkResponse response = GetNetworkResponse(json);
    if (json['result'] != null) {
      response.friendbotUrl = json['result']['friendbotUrl'];
      response.passphrase = json['result']['passphrase'];
      response.protocolVersion = json['result']['protocolVersion'];
    } else if (json['error'] != null) {
      response.error = SorobanRpcErrorResponse.fromJson(json);
    }
    return response;
  }
}
