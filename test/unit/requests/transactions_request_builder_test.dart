// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

void main() {
  group('TransactionsRequestBuilder Tests', () {
    late Uri serverUri;

    setUp(() {
      serverUri = Uri.parse('https://horizon-testnet.stellar.org');
    });

    test('execute returns Page<TransactionResponse>', () async {
      final mockResponse = {
        '_links': {
          'self': {'href': 'https://horizon-testnet.stellar.org/transactions?limit=10'},
          'next': {'href': 'https://horizon-testnet.stellar.org/transactions?cursor=next'},
          'prev': {'href': 'https://horizon-testnet.stellar.org/transactions?cursor=prev'}
        },
        '_embedded': {
          'records': [
            {
              '_links': {
                'self': {'href': 'https://horizon-testnet.stellar.org/transactions/abc123'},
                'account': {'href': 'https://horizon-testnet.stellar.org/accounts/GABC'},
                'ledger': {'href': 'https://horizon-testnet.stellar.org/ledgers/12345'},
                'operations': {'href': 'https://horizon-testnet.stellar.org/transactions/abc123/operations'},
                'effects': {'href': 'https://horizon-testnet.stellar.org/transactions/abc123/effects'},
                'precedes': {'href': 'https://horizon-testnet.stellar.org/transactions?order=asc&cursor=123'},
                'succeeds': {'href': 'https://horizon-testnet.stellar.org/transactions?order=desc&cursor=123'}
              },
              'id': 'abc123def456',
              'paging_token': '12345-123',
              'successful': true,
              'hash': 'abc123def456',
              'ledger': 12345,
              'created_at': '2024-01-01T00:00:00Z',
              'source_account': 'GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B',
              'fee_account': 'GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B',
              'source_account_sequence': '123456789',
              'fee_charged': '100',
              'max_fee': '1000',
              'operation_count': 1,
              'envelope_xdr': 'AAAAAAAA...',
              'result_xdr': 'AAAAAAA...',
              'result_meta_xdr': 'AAAAAAA...',
              'fee_meta_xdr': 'AAAAAAA...',
              'memo_type': 'none',
              'signatures': ['sig1', 'sig2'],
              'valid_after': '1970-01-01T00:00:00Z',
              'valid_before': '2030-01-01T00:00:00Z',
              'preconditions': {
                'timebounds': {
                  'min_time': '0',
                  'max_time': '1893456000'
                }
              }
            }
          ]
        }
      };

      final mockClient = MockClient((request) async {
        return http.Response(json.encode(mockResponse), 200);
      });

      final builder = TransactionsRequestBuilder(mockClient, serverUri);
      final page = await builder.limit(10).execute();

      expect(page.records.length, equals(1));
      expect(page.records[0], isA<TransactionResponse>());
      expect(page.records[0].successful, isTrue);
      expect(page.links, isNotNull);
    });

    test('forAccount sets correct path segments', () {
      final mockClient = MockClient((request) async {
        return http.Response('{"_embedded": {"records": []}}', 200);
      });

      final accountId = 'GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B';
      final builder = TransactionsRequestBuilder(mockClient, serverUri);
      builder.forAccount(accountId);
      final uri = builder.buildUri();

      expect(uri.path, contains('/accounts/$accountId/transactions'));
    });

    test('forLedger sets correct path segments', () {
      final mockClient = MockClient((request) async {
        return http.Response('{"_embedded": {"records": []}}', 200);
      });

      final builder = TransactionsRequestBuilder(mockClient, serverUri);
      builder.forLedger(12345);
      final uri = builder.buildUri();

      expect(uri.path, contains('/ledgers/12345/transactions'));
    });

    test('includeFailed adds query parameter', () {
      final mockClient = MockClient((request) async {
        return http.Response('{"_embedded": {"records": []}}', 200);
      });

      final builder = TransactionsRequestBuilder(mockClient, serverUri);
      builder.includeFailed(true);
      final uri = builder.buildUri();

      expect(uri.queryParameters['include_failed'], equals('true'));
    });

    test('combining filters with pagination', () {
      final mockClient = MockClient((request) async {
        return http.Response('{"_embedded": {"records": []}}', 200);
      });

      final builder = TransactionsRequestBuilder(mockClient, serverUri);
      builder
          .forLedger(12345)
          .includeFailed(false)
          .limit(50)
          .order(RequestBuilderOrder.ASC)
          .cursor('cursor123');
      final uri = builder.buildUri();

      expect(uri.path, contains('/ledgers/12345/transactions'));
      expect(uri.queryParameters['include_failed'], equals('false'));
      expect(uri.queryParameters['limit'], equals('50'));
      expect(uri.queryParameters['order'], equals('asc'));
      expect(uri.queryParameters['cursor'], equals('cursor123'));
    });

    test('stream returns Stream<TransactionResponse>', () {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          '_embedded': {'records': []}
        }), 200);
      });

      final builder = TransactionsRequestBuilder(mockClient, serverUri);
      final stream = builder.stream();

      expect(stream, isA<Stream<TransactionResponse>>());
    });
  });
}
