// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import '../transaction.dart';

/// Part of the SimulateTransactionRequest.
/// Allows budget instruction leeway used in preflight calculations to be configured.
class ResourceConfig {
  /// Configuration for how resources will be calculated.
  /// Allow this many extra instructions when budgeting resources.
  int instructionLeeway;

  /// Creates a ResourceConfig with instruction leeway.
  ///
  /// Allows extra instructions when budgeting resources for simulation.
  ResourceConfig(this.instructionLeeway);

  Map<String, dynamic> getRequestArgs() {
    var map = <String, dynamic>{};
    map['instructionLeeway'] = instructionLeeway;
    return map;
  }
}

/// Holds the request parameters for simulateTransaction.
/// See: https://developers.stellar.org/network/soroban-rpc/api-reference/methods/simulateTransaction
class SimulateTransactionRequest {
  /// The transaction to be submitted. In order for the RPC server to
  /// successfully simulate a Stellar transaction, the provided transaction
  /// must contain only a single operation of the type invokeHostFunction.
  Transaction transaction;

  /// Allows budget instruction leeway used in preflight calculations to be configured
  /// If not provided the leeway defaults to 3000000 instructions
  ResourceConfig? resourceConfig;

  /// Support for non-root authorization. Only available for protocol >= 23
  /// Possible values: "enforce" | "record" | "record_allow_nonroot"
  String? authMode;

  /// When true, requests that the RPC server record authorization entries using the
  /// ADDRESS_V2 credential format (protocol 27+). The key is omitted from the
  /// request when false (never sent as `"useUpgradedAuth": false`).
  ///
  /// RPCs that do not support this flag silently ignore it and return legacy
  /// ADDRESS entries. Whether the server honored the flag is detected by
  /// inspecting the credential arm of the returned entries, not by any error code.
  ///
  /// Emitting V2 entries on a network running below protocol 27 invalidates
  /// the transaction; set this only when targeting protocol 27+.
  bool useUpgradedAuth;

  /// Creates a SimulateTransactionRequest for transaction simulation.
  ///
  /// Contains transaction to simulate with optional resource config, auth mode,
  /// and the optional [useUpgradedAuth] flag (default false; key omitted when false).
  SimulateTransactionRequest(this.transaction,
      {this.resourceConfig, this.authMode, this.useUpgradedAuth = false});

  Map<String, dynamic> getRequestArgs() {
    var map = <String, dynamic>{};
    map['transaction'] = transaction.toEnvelopeXdrBase64();
    if (resourceConfig != null) {
      map['resourceConfig'] = resourceConfig!.getRequestArgs();
    }
    if (authMode != null) {
      map['authMode'] = authMode;
    }
    // Omit the key entirely when false; never emit "useUpgradedAuth": false.
    if (useUpgradedAuth) {
      map['useUpgradedAuth'] = true;
    }

    return map;
  }
}

/// Holds the request parameters for getTransactions.
/// See: https://developers.stellar.org/docs/data/rpc/api-reference/methods/getTransactions
class GetTransactionsRequest {
  /// Ledger sequence number to start fetching responses from (inclusive).
  /// Get Transactions will return an error if startLedger is less than the oldest ledger stored in this node,
  /// or greater than the latest ledger seen by this node.
  /// If a cursor is included in the request, startLedger must be omitted.
  int? startLedger;

  /// Pagination
  PaginationOptions? paginationOptions;

  /// Creates a GetTransactionsRequest with query parameters.
  ///
  /// Contains start ledger and pagination options for querying transactions.
  GetTransactionsRequest({this.startLedger, this.paginationOptions});

  Map<String, dynamic> getRequestArgs() {
    var map = <String, dynamic>{};
    if (startLedger != null) {
      map['startLedger'] = startLedger;
    }
    if (paginationOptions != null) {
      Map<String, dynamic> values = {};
      values.addAll(paginationOptions!.getRequestArgs());
      map['pagination'] = values;
    }
    return map;
  }
}

/// Holds the request parameters for getLedgers.
/// See: https://developers.stellar.org/docs/data/rpc/api-reference/methods/getLedgers
class GetLedgersRequest {
  /// Ledger sequence number to start fetching responses from (inclusive).
  /// GetLedgers will return an error if startLedger is less than the oldest ledger stored in this node,
  /// or greater than the latest ledger seen by this node.
  /// If a cursor is included in the request, startLedger must be omitted.
  int? startLedger;

  /// Pagination options for the request
  PaginationOptions? paginationOptions;

  /// Creates a GetLedgersRequest with query parameters.
  ///
  /// Contains start ledger and pagination options for querying ledgers.
  GetLedgersRequest({this.startLedger, this.paginationOptions});

  Map<String, dynamic> getRequestArgs() {
    var map = <String, dynamic>{};
    if (startLedger != null) {
      map['startLedger'] = startLedger;
    }
    if (paginationOptions != null) {
      Map<String, dynamic> values = {};
      values.addAll(paginationOptions!.getRequestArgs());
      map['pagination'] = values;
    }
    return map;
  }
}

/// Holds the request parameters for getEvents.
/// See: https://developers.stellar.org/network/soroban-rpc/api-reference/methods/getEvents
class GetEventsRequest {
  /// ledger sequence number to fetch events after (inclusive).
  /// The getEvents method will return an error if startLedger is less than the oldest ledger stored in this node,
  /// or greater than the latest ledger seen by this node.
  /// If a cursor is included in the request, startLedger must be omitted.
  int? startLedger;

  /// Ledger sequence number represents the end of search window (exclusive).
  /// If a cursor is included in the request, endLedger must be omitted.
  int? endLedger;

  /// List of filters for the returned events. Events matching any of the filters are included.
  /// To match a filter, an event must match both a contractId and a topic.
  /// Maximum 5 filters are allowed per request.
  List<EventFilter>? filters;

  /// Pagination
  PaginationOptions? paginationOptions;

  /// Creates a GetEventsRequest with event query parameters.
  ///
  /// Contains ledger range, event filters, and pagination options.
  GetEventsRequest(
      {this.startLedger, this.endLedger, this.filters, this.paginationOptions});

  Map<String, dynamic> getRequestArgs() {
    var map = <String, dynamic>{};
    if (startLedger != null) {
      map['startLedger'] = startLedger;
    }
    if (endLedger != null) {
      map['endLedger'] = endLedger;
    }
    if (filters != null) {
      List<Map<String, dynamic>> values =
          List<Map<String, dynamic>>.empty(growable: true);
      for (EventFilter filter in filters!) {
        values.add(filter.getRequestArgs());
      }
      map['filters'] = values;
    }
    if (paginationOptions != null) {
      Map<String, dynamic> values = {};
      values.addAll(paginationOptions!.getRequestArgs());
      map['pagination'] = values;
    }
    return map;
  }
}

/// Event filter for the getEvents request.
/// See: https://developers.stellar.org/network/soroban-rpc/api-reference/methods/getEvents
class EventFilter {
  /// (optional) A comma separated list of event types (system, contract, or diagnostic)
  /// used to filter events. If omitted, all event types are included.
  String? type;

  /// (optional) List of contract ids to query for events.
  /// If omitted, return events for all contracts.
  /// Maximum 5 contract IDs are allowed per request.
  List<String>? contractIds;

  /// (optional) List of topic filters. If omitted, query for all events.
  /// If multiple filters are specified, events will be included if they match any of the filters.
  /// Maximum 5 filters are allowed per request.
  List<TopicFilter>? topics;

  /// Creates an EventFilter with filtering criteria.
  ///
  /// Contains event type, contract IDs, and topic filters.
  EventFilter({this.type, this.contractIds, this.topics});

  Map<String, dynamic> getRequestArgs() {
    var map = <String, dynamic>{};
    if (type != null) {
      map['type'] = type!;
    }
    if (contractIds != null) {
      map['contractIds'] = contractIds!;
    }
    if (topics != null) {
      List<List<String>> values = List<List<String>>.empty(growable: true);
      for (TopicFilter filter in topics!) {
        values.add(filter.getRequestArgs());
      }
      map['topics'] = values;
    }
    return map;
  }
}

/// Part of the getEvents request parameters.
/// https://developers.stellar.org/network/soroban-rpc/api-reference/methods/getEvents
/// ```dart
/// TopicFilter topicFilter = TopicFilter(
///           ["*", XdrSCVal.forSymbol('increment').toBase64EncodedXdrString()]);
/// ```
class TopicFilter {
  List<String> segmentMatchers;

  /// Creates a TopicFilter with segment matchers.
  ///
  /// Contains list of topic segments for pattern matching.
  TopicFilter(this.segmentMatchers);

  List<String> getRequestArgs() {
    return this.segmentMatchers;
  }
}

/// Pagination parameters for Soroban RPC methods that return large result sets.
///
/// PaginationOptions controls the pagination behavior when querying data that may
/// span multiple pages. Use this to efficiently retrieve large datasets by fetching
/// manageable chunks and iterating through pages using continuation cursors.
///
/// Pagination Workflow:
/// 1. Make initial request with optional [limit]
/// 2. Process returned results
/// 3. Check response for continuation [cursor]
/// 4. Make subsequent request with cursor to fetch next page
/// 5. Repeat until cursor is null (no more pages)
///
/// Fields:
/// - [cursor]: Continuation token from previous response (null for first page)
/// - [limit]: Maximum number of results per page (server may have its own limit)
///
/// Applicable Methods:
/// - getEvents: Paginate through contract events
/// - getTransactions: Paginate through transaction history
/// - getLedgers: Paginate through ledger data
///
/// Example - Basic pagination:
/// ```dart
/// final server = SorobanServer(rpcUrl);
/// String? cursor;
/// var pageNum = 1;
///
/// do {
///   final request = GetEventsRequest(
///     startLedger: 1000000,
///     paginationOptions: PaginationOptions(cursor: cursor, limit: 100),
///   );
///
///   final response = await server.getEvents(request);
///
///   print('Page $pageNum: ${response.events?.length ?? 0} events');
///
///   // Process events
///   if (response.events != null) {
///     for (var event in response.events!) {
///       // Process each event
///     }
///   }
///
///   // Get cursor for next page
///   cursor = response.cursor;
///   pageNum++;
/// } while (cursor != null);
/// ```
///
/// Example - Limited iteration:
/// ```dart
/// // Fetch only first 500 events across multiple pages
/// var totalFetched = 0;
/// const maxEvents = 500;
/// String? cursor;
///
/// while (totalFetched < maxEvents) {
///   final remaining = maxEvents - totalFetched;
///   final pageSize = remaining > 100 ? 100 : remaining;
///
///   final request = GetTransactionsRequest(
///     paginationOptions: PaginationOptions(cursor: cursor, limit: pageSize),
///   );
///
///   final response = await server.getTransactions(request);
///
///   if (response.transactions == null || response.transactions!.isEmpty) {
///     break;
///   }
///
///   totalFetched += response.transactions!.length;
///   cursor = response.cursor;
/// }
/// ```
///
/// See also:
/// - [GetEventsRequest] for event pagination
/// - [GetTransactionsRequest] for transaction pagination
/// - [GetLedgersRequest] for ledger pagination
class PaginationOptions {
  String? cursor;
  int? limit;

  /// Creates a PaginationOptions with cursor and limit.
  ///
  /// Contains pagination parameters for paginated RPC methods.
  PaginationOptions({this.cursor, this.limit});

  Map<String, dynamic> getRequestArgs() {
    var map = <String, dynamic>{};
    if (cursor != null) {
      map['cursor'] = cursor!;
    }
    if (limit != null) {
      map['limit'] = limit!;
    }
    return map;
  }
}
