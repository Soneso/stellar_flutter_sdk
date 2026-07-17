// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import '../xdr/xdr.dart';
import 'soroban_rpc_requests.dart';
import 'soroban_rpc_responses.dart';

/// Response for the getLedgers request.
/// See: https://developers.stellar.org/docs/data/rpc/api-reference/methods/getLedgers
class GetLedgersResponse extends SorobanRpcResponse {
  /// Array of ledger information
  List<LedgerInfo>? ledgers;

  /// The sequence number of the latest ledger known to Soroban RPC at the time it handled the request.
  int? latestLedger;

  /// The unix timestamp of the close time of the latest ledger known to Soroban RPC at the time it handled the request.
  int? latestLedgerCloseTime;

  /// The sequence number of the oldest ledger ingested by Soroban RPC at the time it handled the request.
  int? oldestLedger;

  /// The unix timestamp of the close time of the oldest ledger ingested by Soroban RPC at the time it handled the request.
  int? oldestLedgerCloseTime;

  /// A cursor value for use in pagination
  String? cursor;

  /// Creates a GetLedgersResponse from JSON-RPC response.
  ///
  /// Contains paginated list of ledger information.
  GetLedgersResponse(Map<String, dynamic> jsonResponse) : super(jsonResponse);

  factory GetLedgersResponse.fromJson(Map<String, dynamic> json) {
    GetLedgersResponse response = GetLedgersResponse(json);
    if (json['result'] != null) {
      if (json['result']['ledgers'] != null) {
        response.ledgers = List<LedgerInfo>.from(
            json['result']['ledgers'].map((e) => LedgerInfo.fromJson(e)));
      }
      response.latestLedger = json['result']['latestLedger'];
      response.latestLedgerCloseTime = json['result']['latestLedgerCloseTime'];
      response.oldestLedger = json['result']['oldestLedger'];
      response.oldestLedgerCloseTime = json['result']['oldestLedgerCloseTime'];
      response.cursor = json['result']['cursor'];
    } else if (json['error'] != null) {
      response.error = SorobanRpcErrorResponse.fromJson(json);
    }
    return response;
  }
}

/// Represents a single ledger in the getLedgers response.
/// See: https://developers.stellar.org/docs/data/rpc/api-reference/methods/getLedgers
class LedgerInfo {
  /// Hash of the ledger as a hex-encoded string
  String hash;

  /// Sequence number of the ledger
  int sequence;

  /// The unix timestamp of the close time of the ledger
  String ledgerCloseTime;

  /// Base64-encoded LedgerHeader XDR.
  String? headerXdr;

  /// Base64-encoded LedgerCloseMeta XDR containing ledger close metadata.
  String? metadataXdr;

  /// Creates a LedgerInfo with ledger details.
  ///
  /// Contains ledger hash, sequence, close time, and XDR data.
  LedgerInfo(
    this.hash,
    this.sequence,
    this.ledgerCloseTime,
    this.headerXdr,
    this.metadataXdr,
  );

  factory LedgerInfo.fromJson(Map<String, dynamic> json) {
    return LedgerInfo(
      json['hash'],
      json['sequence'],
      json['ledgerCloseTime'],
      json['headerXdr'],
      json['metadataXdr'],
    );
  }
}

/// Response from the getEvents RPC method.
///
/// GetEventsResponse contains a paginated list of contract events emitted within a
/// specified ledger range. Events are the primary mechanism for smart contracts to
/// communicate state changes and emit notifications that applications can monitor
/// and react to.
///
/// The response provides:
/// - List of [EventInfo] objects with complete event details
/// - Pagination cursor for fetching subsequent pages
/// - Ledger range metadata (latest, oldest ledgers and timestamps)
///
/// Event Filtering:
/// Events can be filtered by:
/// - Ledger range (startLedger to endLedger)
/// - Contract IDs (specific contracts)
/// - Event topics (structured filters on event data)
/// - Event type (contract, system, diagnostic)
///
/// Use Cases:
/// - Monitor specific contract events (transfers, approvals, etc.)
/// - Build event-driven applications
/// - Track contract state changes
/// - Implement notification systems
/// - Generate analytics from contract activity
///
/// Fields:
/// - [events]: List of events in the queried range
/// - [latestLedger]: Latest ledger sequence on RPC server
/// - [cursor]: Pagination cursor for next page (protocol 22+)
/// - [latestLedgerCloseTime]: Unix timestamp of latest ledger close (protocol 23+)
/// - [oldestLedger]: Oldest available ledger on RPC server (protocol 23+)
/// - [oldestLedgerCloseTime]: Unix timestamp of oldest ledger close (protocol 23+)
///
/// Example - Basic event monitoring:
/// ```dart
/// final server = SorobanServer(rpcUrl);
///
/// // Query events from a contract
/// final contractIds = [StrKey.encodeContractIdHex(contractId)];
/// final request = GetEventsRequest(
///   startLedger: 1000000,
///   filters: [EventFilter(contractIds: contractIds)],
///   paginationOptions: PaginationOptions(limit: 100),
/// );
///
/// final response = await server.getEvents(request);
///
/// print('Found ${response.events?.length ?? 0} events');
/// print('Latest ledger: ${response.latestLedger}');
///
/// if (response.events != null) {
///   for (var event in response.events!) {
///     print('Event ID: ${event.id}');
///     print('Contract: ${event.contractId}');
///     print('Type: ${event.type}');
///     print('Topics: ${event.topic.length}');
///
///     // Decode event value
///     final value = event.valueXdr;
///     // Process value based on contract spec
///   }
/// }
/// ```
///
/// Example - Paginated event streaming:
/// ```dart
/// String? cursor;
///
/// do {
///   final request = GetEventsRequest(
///     startLedger: startLedger,
///     filters: [EventFilter(contractIds: [contractAddress])],
///     paginationOptions: PaginationOptions(cursor: cursor, limit: 100),
///   );
///
///   final response = await server.getEvents(request);
///
///   if (response.events != null) {
///     for (var event in response.events!) {
///       // Process each event
///       await processEvent(event);
///     }
///   }
///
///   cursor = response.cursor;
///
///   // Add delay to avoid rate limiting
///   await Future.delayed(Duration(milliseconds: 100));
/// } while (cursor != null);
/// ```
///
/// Example - Filtering by topics:
/// ```dart
/// // Filter events with specific topic structure
/// final topicFilter = TopicFilter(['*', 'transfer', '*']);
/// final filter = EventFilter(
///   contractIds: [contractAddress],
///   topics: [topicFilter],
/// );
///
/// final request = GetEventsRequest(
///   startLedger: startLedger,
///   filters: [filter],
/// );
///
/// final response = await server.getEvents(request);
/// ```
///
/// See also:
/// - [EventInfo] for individual event details
/// - [GetEventsRequest] for request parameters and filtering
/// - [EventFilter] for event filtering options
/// - [PaginationOptions] for pagination control
/// - [Soroban RPC Documentation](https://developers.stellar.org/docs/data/rpc/api-reference/methods/getEvents)
class GetEventsResponse extends SorobanRpcResponse {
  int? latestLedger;

  /// If error is present then results will not be in the response
  List<EventInfo>? events;

  /// For paging, only available for protocol version >= 22
  String? cursor;

  /// The unix timestamp of the close time of the latest ledger known to Soroban-RPC at the time it handled the request.
  /// Only available for protocol version >= 23
  String? latestLedgerCloseTime;

  /// The oldest ledger ingested by Soroban-RPC at the time it handled the request.
  /// Only available for protocol version >= 23
  int? oldestLedger;

  /// The unix timestamp of the close time of the oldest ledger ingested by Soroban-RPC at the time it handled the request.
  /// Only available for protocol version >= 23
  String? oldestLedgerCloseTime;

  /// Creates a GetEventsResponse from JSON-RPC response.
  ///
  /// Contains paginated list of contract events.
  GetEventsResponse(Map<String, dynamic> jsonResponse) : super(jsonResponse);

  factory GetEventsResponse.fromJson(Map<String, dynamic> json) {
    GetEventsResponse response = GetEventsResponse(json);
    if (json['result'] != null) {
      if (json['result']['events'] != null) {
        response.events = List<EventInfo>.from(
            json['result']['events'].map((e) => EventInfo.fromJson(e)));
      }
      response.latestLedger = json['result']['latestLedger'];
      response.cursor = json['result']['cursor'];
      response.latestLedgerCloseTime = json['result']['latestLedgerCloseTime'];
      response.oldestLedger = json['result']['oldestLedger'];
      response.oldestLedgerCloseTime = json['result']['oldestLedgerCloseTime'];
    } else if (json['error'] != null) {
      response.error = SorobanRpcErrorResponse.fromJson(json);
    }
    return response;
  }
}

/// Detailed information about a single event emitted by a Soroban smart contract.
///
/// EventInfo represents an event generated during contract execution. Events are the
/// primary mechanism for contracts to communicate state changes and emit structured
/// notifications that applications can monitor, filter, and react to.
///
/// Event Structure:
/// Events consist of:
/// - Topics: Indexed fields for efficient filtering (similar to Ethereum event topics)
/// - Value: The event data payload (XDR-encoded SCVal)
/// - Metadata: Contract ID, ledger, transaction hash, timestamps
///
/// Events can be:
/// - Contract events: Explicitly emitted by contract code
/// - System events: Generated by the Soroban runtime
/// - Diagnostic events: For debugging and internal monitoring
///
/// Topic Filtering:
/// Topics are indexed and can be filtered efficiently:
/// - `Topic[0]`: Often the event name or identifier
/// - `Topic[1..n]`: Event-specific indexed parameters
/// - Use wildcards ('*') in topic filters for flexible matching
///
/// Fields:
/// - [type]: Event type (contract, system, diagnostic)
/// - [ledger]: Ledger sequence number where event was emitted
/// - [ledgerCloseAt]: ISO8601 timestamp of ledger close
/// - [contractId]: Contract that emitted the event (C... address)
/// - [id]: Unique event identifier
/// - [topic]: List of base64-encoded XDR topic values for filtering
/// - [value]: Base64-encoded XDR event data payload
/// - [inSuccessfulContractCall]: Whether event was in successful call
/// - [txHash]: Transaction hash that generated the event
/// - [opIndex]: Operation index in transaction (protocol 23+)
/// - [txIndex]: Transaction index in ledger (protocol 23+)
///
/// Example - Processing events:
/// ```dart
/// final response = await server.getEvents(request);
///
/// if (response.events != null) {
///   for (var event in response.events!) {
///     print('Event from contract: ${event.contractId}');
///     print('Transaction: ${event.txHash}');
///     print('Ledger: ${event.ledger} at ${event.ledgerCloseAt}');
///     print('Topics: ${event.topic.length}');
///
///     // Decode event value
///     final value = event.valueXdr;
///     if (value.map != null) {
///       // Process map data
///       for (var entry in value.map!.entries) {
///         print('Key: ${entry.key}, Value: ${entry.val}');
///       }
///     }
///
///     // Process topics
///     for (var topicXdr in event.topic) {
///       final topic = XdrSCVal.fromBase64EncodedXdrString(topicXdr);
///       if (topic.sym != null) {
///         print('Topic symbol: ${topic.sym}');
///       }
///     }
///   }
/// }
/// ```
///
/// Example - Filtering by event signature:
/// ```dart
/// // Listen for "transfer" events
/// final transferEvents = response.events?.where((event) {
///   if (event.topic.isEmpty) return false;
///
///   // First topic often contains event name
///   final firstTopic = XdrSCVal.fromBase64EncodedXdrString(event.topic.first);
///   return firstTopic.sym == 'transfer';
/// }).toList();
///
/// for (var event in transferEvents ?? []) {
///   // Decode transfer event data
///   final value = event.valueXdr;
///   print('Transfer event: $value');
/// }
/// ```
///
/// Example - Monitoring contract state changes:
/// ```dart
/// // Stream events and update local state
/// await for (var batch in getEventStream(contractId)) {
///   for (var event in batch) {
///     if (event.inSuccessfulContractCall ?? false) {
///       // Decode and process event
///       final eventData = event.valueXdr;
///
///       // Update local cache/state based on event
///       await updateLocalState(event.contractId, eventData);
///
///       print('State updated from ledger ${event.ledger}');
///     }
///   }
/// }
/// ```
///
/// See also:
/// - [GetEventsResponse] for querying events
/// - [EventFilter] for filtering by contract, topics, and type
/// - [XdrSCVal] for decoding event topics and values
/// - [XdrContractEvent] for the underlying XDR structure
class EventInfo {
  /// Event type (contract, system, or diagnostic).
  String type;

  /// Ledger sequence number when this event was emitted.
  int ledger;

  /// ISO 8601 timestamp when the ledger closed.
  String ledgerCloseAt;

  /// Contract ID (C... format) that emitted this event.
  String contractId;

  /// Unique event identifier.
  String id;

  /// List of base64-encoded event topics for filtering.
  List<String> topic;

  /// Base64-encoded event value (XdrSCVal format).
  String value;

  bool? inSuccessfulContractCall;

  /// Transaction hash that triggered this event.
  String txHash;
  // starting from protocol 23 opIndex, txIndex will be filled.
  int? opIndex;
  int? txIndex;

  /// Creates an EventInfo with event details.
  ///
  /// Contains complete event information including topics, value, and metadata.
  EventInfo(
    this.type,
    this.ledger,
    this.ledgerCloseAt,
    this.contractId,
    this.id,
    this.topic,
    this.value,
    this.inSuccessfulContractCall,
    this.txHash,
    this.opIndex,
    this.txIndex,
  );

  factory EventInfo.fromJson(Map<String, dynamic> json) {
    List<String> topic = List<String>.from(json['topic'].map((e) => e));
    String value = "";

    if (json['value'] is Map) {
      value = json['value']['xdr'];
    } else {
      value = json['value'];
    }

    return EventInfo(
      json['type'],
      json['ledger'],
      json['ledgerClosedAt'],
      json['contractId'],
      json['id'],
      topic,
      value,
      json['inSuccessfulContractCall'],
      json['txHash'],
      json['opIndex'],
      json['txIndex'],
    );
  }

  XdrSCVal get valueXdr => XdrSCVal.fromBase64EncodedXdrString(value);
}
