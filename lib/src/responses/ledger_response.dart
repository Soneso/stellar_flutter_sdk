// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'response.dart';

/// Represents a ledger response from Horizon.
///
/// A ledger captures the state of the Stellar network at a specific point in time.
/// Ledgers close approximately every 5 seconds and contain all transactions, operations,
/// and effects that occurred during that period.
///
/// Fields:
/// - [sequence]: Ledger sequence number (incremental, starting from 1)
/// - [hash]: Unique hash of this ledger
/// - [id]: Horizon ID for this ledger
/// - [pagingToken]: Cursor for pagination
/// - [prevHash]: Hash of the previous ledger
/// - [successfulTransactionCount]: Number of successful transactions in this ledger
/// - [failedTransactionCount]: Number of failed transactions in this ledger
/// - [operationCount]: Total number of operations in successful transactions
/// - [txSetOperationCount]: Total number of operations in the transaction set
/// - [closedAt]: ISO 8601 timestamp when this ledger closed
/// - [totalCoins]: Total XLM in circulation (in lumens)
/// - [feePool]: Total XLM available in the fee pool (in lumens)
/// - [baseFeeInStroops]: Network minimum base fee in stroops (1 stroop = 0.0000001 XLM)
/// - [baseReserveInStroops]: Network minimum account reserve in stroops
/// - [maxTxSetSize]: Maximum transaction set size for this ledger
/// - [protocolVersion]: Stellar protocol version used by this ledger
/// - [headerXdr]: Base64-encoded XDR representation of the ledger header
/// - [links]: Hypermedia links to related resources
///
/// Example:
/// ```dart
/// final ledger = await sdk.ledgers.ledger(12345);
/// print('Ledger ${ledger.sequence}');
/// print('  Hash: ${ledger.hash}');
/// print('  Transactions: ${ledger.successfulTransactionCount}');
/// print('  Operations: ${ledger.operationCount}');
/// print('  Base Fee: ${ledger.baseFeeInStroops} stroops');
/// ```
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
/// - [LedgersRequestBuilder] for querying ledgers
class LedgerResponse extends Response {
  /// Ledger sequence number (incremental, starting from 1)
  int sequence;

  /// Unique hash of this ledger
  String hash;

  /// Horizon ID for this ledger
  String id;

  /// Cursor for pagination
  String pagingToken;

  /// Hash of the previous ledger
  String? prevHash;

  /// Number of successful transactions in this ledger
  int successfulTransactionCount;

  /// Number of failed transactions in this ledger
  int failedTransactionCount;

  /// Total number of operations in successful transactions
  int operationCount;

  /// Total number of operations in the transaction set
  int txSetOperationCount;

  /// ISO 8601 timestamp when this ledger closed
  String closedAt;

  /// Total XLM in circulation (in lumens)
  String totalCoins;

  /// Total XLM available in the fee pool (in lumens)
  String feePool;

  /// Network minimum base fee in stroops (1 stroop = 0.0000001 XLM)
  int baseFeeInStroops;

  /// Network minimum account reserve in stroops
  int baseReserveInStroops;

  /// Maximum transaction set size for this ledger
  int maxTxSetSize;

  /// Stellar protocol version used by this ledger
  int protocolVersion;

  /// Base64-encoded XDR representation of the ledger header
  String headerXdr;

  /// Hypermedia links to related resources
  LedgerResponseLinks links;

  /// Creates a ledger response with ledger state and network information.
  LedgerResponse(
      this.sequence,
      this.hash,
      this.id,
      this.pagingToken,
      this.prevHash,
      this.successfulTransactionCount,
      this.failedTransactionCount,
      this.operationCount,
      this.txSetOperationCount,
      this.closedAt,
      this.totalCoins,
      this.feePool,
      this.baseFeeInStroops,
      this.baseReserveInStroops,
      this.maxTxSetSize,
      this.protocolVersion,
      this.headerXdr,
      this.links);

  /// Creates a ledger response from Horizon API JSON.
  factory LedgerResponse.fromJson(Map<String, dynamic> json) => LedgerResponse(
      convertInt(json['sequence'])!,
      json['hash'],
      json['id'],
      json['paging_token'],
      json['prev_hash'],
      convertInt(json['successful_transaction_count'])!,
      convertInt(json['failed_transaction_count'])!,
      convertInt(json['operation_count'])!,
      convertInt(json['tx_set_operation_count'])!,
      json['closed_at'],
      json['total_coins'],
      json['fee_pool'],
      convertInt(json['base_fee_in_stroops'])!,
      convertInt(json['base_reserve_in_stroops'])!,
      convertInt(json['max_tx_set_size'])!,
      convertInt(json['protocol_version'])!,
      json['header_xdr'],
      LedgerResponseLinks.fromJson(json['_links']))
    ..rateLimitLimit = convertInt(json['rateLimitLimit'])
    ..rateLimitRemaining = convertInt(json['rateLimitRemaining'])
    ..rateLimitReset = convertInt(json['rateLimitReset']);
}

/// HAL links for navigating related ledger resources.
///
/// Provides hypermedia links to related Horizon API endpoints for a ledger.
/// These links follow the HAL (Hypertext Application Language) standard and
/// enable navigation to:
/// - effects: All effects that occurred in this ledger
/// - operations: All operations included in this ledger
/// - self: This ledger's details endpoint
/// - transactions: All transactions included in this ledger
/// - payments: All payment operations in this ledger
///
/// See also:
/// - [LedgerResponse] for the parent ledger details
/// - [Link] for link structure details
class LedgerResponseLinks {
  /// Link to effects that occurred in this ledger.
  Link effects;

  /// Link to operations included in this ledger.
  Link operations;

  /// Link to this ledger's details endpoint.
  Link self;

  /// Link to transactions included in this ledger.
  Link transactions;

  /// Link to payment operations in this ledger.
  Link payments;

  /// Creates ledger response links with navigation to related resources.
  LedgerResponseLinks(this.effects, this.operations, this.self, this.transactions, this.payments);

  /// Creates ledger response links from Horizon API JSON.
  factory LedgerResponseLinks.fromJson(Map<String, dynamic> json) => LedgerResponseLinks(
      Link.fromJson(json['effects']),
      Link.fromJson(json['operations']),
      Link.fromJson(json['self']),
      Link.fromJson(json['transactions']),
      Link.fromJson(json['payments']));
}
