// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

void main() {
  group('LedgersRequestBuilder Tests', () {
    late Uri serverUri;

    setUp(() {
      serverUri = Uri.parse('https://horizon-testnet.stellar.org');
    });

    test('execute returns Page<LedgerResponse>', () async {
      final mockResponse = {
        '_links': {
          'self': {'href': 'https://horizon-testnet.stellar.org/ledgers?limit=10'},
          'next': {'href': 'https://horizon-testnet.stellar.org/ledgers?cursor=next'},
          'prev': {'href': 'https://horizon-testnet.stellar.org/ledgers?cursor=prev'}
        },
        '_embedded': {
          'records': [
            {
              '_links': {
                'self': {'href': 'https://horizon-testnet.stellar.org/ledgers/12345'},
                'transactions': {'href': 'https://horizon-testnet.stellar.org/ledgers/12345/transactions'},
                'operations': {'href': 'https://horizon-testnet.stellar.org/ledgers/12345/operations'},
                'payments': {'href': 'https://horizon-testnet.stellar.org/ledgers/12345/payments'},
                'effects': {'href': 'https://horizon-testnet.stellar.org/ledgers/12345/effects'}
              },
              'id': 'ledger-hash-12345',
              'paging_token': '12345',
              'hash': 'abc123def456',
              'prev_hash': 'prev123hash456',
              'sequence': 12345,
              'successful_transaction_count': 10,
              'failed_transaction_count': 0,
              'operation_count': 25,
              'tx_set_operation_count': 25,
              'closed_at': '2024-01-01T00:00:00Z',
              'total_coins': '105443902087.3472865',
              'fee_pool': '1524638386.7985412',
              'base_fee_in_stroops': 100,
              'base_reserve_in_stroops': 5000000,
              'max_tx_set_size': 1000,
              'protocol_version': 20,
              'header_xdr': 'AAAAAAAA...'
            },
            {
              '_links': {
                'self': {'href': 'https://horizon-testnet.stellar.org/ledgers/12346'},
                'transactions': {'href': 'https://horizon-testnet.stellar.org/ledgers/12346/transactions'},
                'operations': {'href': 'https://horizon-testnet.stellar.org/ledgers/12346/operations'},
                'payments': {'href': 'https://horizon-testnet.stellar.org/ledgers/12346/payments'},
                'effects': {'href': 'https://horizon-testnet.stellar.org/ledgers/12346/effects'}
              },
              'id': 'ledger-hash-12346',
              'paging_token': '12346',
              'hash': 'def456ghi789',
              'prev_hash': 'abc123def456',
              'sequence': 12346,
              'successful_transaction_count': 15,
              'failed_transaction_count': 1,
              'operation_count': 30,
              'tx_set_operation_count': 30,
              'closed_at': '2024-01-01T00:00:05Z',
              'total_coins': '105443902087.3472865',
              'fee_pool': '1524638386.7985412',
              'base_fee_in_stroops': 100,
              'base_reserve_in_stroops': 5000000,
              'max_tx_set_size': 1000,
              'protocol_version': 20,
              'header_xdr': 'BBBBBBBB...'
            }
          ]
        }
      };

      final mockClient = MockClient((request) async {
        return http.Response(json.encode(mockResponse), 200);
      });

      final builder = LedgersRequestBuilder(mockClient, serverUri);
      final page = await builder.limit(10).execute();

      expect(page.records.length, equals(2));
      expect(page.records[0], isA<LedgerResponse>());
      expect(page.records[0].sequence, equals(12345));
      expect(page.records[1].sequence, equals(12346));
      expect(page.links, isNotNull);
      expect(page.links!.next, isNotNull);
    });

    test('basic builder creates correct URI', () {
      final mockClient = MockClient((request) async {
        return http.Response('{"_embedded": {"records": []}}', 200);
      });

      final builder = LedgersRequestBuilder(mockClient, serverUri);
      final uri = builder.buildUri();

      expect(uri.path, contains('/ledgers'));
    });

    test('with pagination parameters', () {
      final mockClient = MockClient((request) async {
        return http.Response('{"_embedded": {"records": []}}', 200);
      });

      final builder = LedgersRequestBuilder(mockClient, serverUri);
      builder.limit(25).order(RequestBuilderOrder.DESC).cursor('12345');
      final uri = builder.buildUri();

      expect(uri.queryParameters['limit'], equals('25'));
      expect(uri.queryParameters['order'], equals('desc'));
      expect(uri.queryParameters['cursor'], equals('12345'));
    });

    test('stream returns Stream<LedgerResponse>', () {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          '_embedded': {'records': []}
        }), 200);
      });

      final builder = LedgersRequestBuilder(mockClient, serverUri);
      final stream = builder.stream();

      expect(stream, isA<Stream<LedgerResponse>>());
    });

    test('chaining methods returns same builder instance', () {
      final mockClient = MockClient((request) async {
        return http.Response('{"_embedded": {"records": []}}', 200);
      });

      final builder = LedgersRequestBuilder(mockClient, serverUri);
      final result1 = builder.cursor('test');
      final result2 = result1.limit(10);
      final result3 = result2.order(RequestBuilderOrder.ASC);

      expect(result1, same(builder));
      expect(result2, same(builder));
      expect(result3, same(builder));
    });
  });
}
