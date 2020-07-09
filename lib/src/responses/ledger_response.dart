// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'response.dart';

/// Represents ledger response received from the horizon server. Each ledger stores the state of the network at a point in time and contains all the changes - transactions, operations, effects, etc. - to that state.
/// See: <a href="https://developers.stellar.org/api/resources/ledgers/" target="_blank">Ledger documentation</a>
class LedgerResponse extends Response {
  int sequence;
  String hash;
  String pagingToken;
  String prevHash;
  int successfulTransactionCount;
  int failedTransactionCount;
  int operationCount;
  int txSetOperationCount;
  String closedAt;
  String totalCoins;
  String feePool;
  String baseReserve;
  String baseFeeInStroops;
  String baseReserveInStroops;
  int maxTxSetSize;
  int protocolVersion;
  String headerXdr;
  LedgerResponseLinks links;

  LedgerResponse(
      this.sequence,
      this.hash,
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
      this.baseReserve,
      this.baseReserveInStroops,
      this.maxTxSetSize,
      this.protocolVersion,
      this.headerXdr,
      this.links);

  factory LedgerResponse.fromJson(Map<String, dynamic> json) =>
      new LedgerResponse(
          convertInt(json['sequence']),
          json['hash'] as String,
          json['paging_token'] as String,
          json['prev_hash'] as String,
          convertInt(json['successful_transaction_count']),
          convertInt(json['failed_transaction_count']),
          convertInt(json['operation_count']),
          json['tx_set_operation_count'] == null
              ? null
              : convertInt(json['tx_set_operation_count']),
          json['closed_at'] as String,
          json['total_coins'] as String,
          json['fee_pool'] as String,
          json['base_fee_in_stroops'].toString(),
          json['base_reserve'] as String,
          json['base_reserve_in_stroops'].toString(),
          convertInt(json['max_tx_set_size']),
          convertInt(json['protocol_version']),
          json['header_xdr'] as String,
          json['_links'] == null
              ? null
              : new LedgerResponseLinks.fromJson(
                  json['_links'] as Map<String, dynamic>))
        ..rateLimitLimit = convertInt(json['rateLimitLimit'])
        ..rateLimitRemaining = convertInt(json['rateLimitRemaining'])
        ..rateLimitReset = convertInt(json['rateLimitReset']);
}

/// Links connected to a ledger response received from the horizon server.
class LedgerResponseLinks {
  Link effects;
  Link operations;
  Link self;
  Link transactions;

  LedgerResponseLinks(
      this.effects, this.operations, this.self, this.transactions);

  factory LedgerResponseLinks.fromJson(Map<String, dynamic> json) =>
      new LedgerResponseLinks(
          json['effects'] == null
              ? null
              : new Link.fromJson(json['effects'] as Map<String, dynamic>),
          json['operations'] == null
              ? null
              : new Link.fromJson(json['operations'] as Map<String, dynamic>),
          json['self'] == null
              ? null
              : new Link.fromJson(json['self'] as Map<String, dynamic>),
          json['transactions'] == null
              ? null
              : new Link.fromJson(
                  json['transactions'] as Map<String, dynamic>));
}
