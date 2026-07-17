// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:async';
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

  group('TransactionsRequestBuilder strkey id validation', () {
    final serverUri = Uri.parse('https://horizon-testnet.stellar.org');

    test('forLiquidityPool converts L strkey id to hex', () {
      final poolHexId =
          '0a1b2c3d4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f9';
      final strKeyId =
          StrKey.encodeLiquidityPoolId(Util.hexToBytes(poolHexId));

      final builder =
          TransactionsRequestBuilder(http.Client(), serverUri).forLiquidityPool(strKeyId);

      expect(builder.buildUri().path, contains('/liquidity_pools/$poolHexId'));
    });

    test('forLiquidityPool throws on invalid L-prefixed id', () {
      expect(
        () => TransactionsRequestBuilder(http.Client(), serverUri)
            .forLiquidityPool('LINVALIDPOOLID'),
        throwsArgumentError,
      );
    });

    test('forClaimableBalance converts B strkey id to hex', () {
      final cbHexId =
          '000000000a1b2c3d4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f9';
      final strKeyId = StrKey.encodeClaimableBalanceIdHex(cbHexId);

      final builder =
          TransactionsRequestBuilder(http.Client(), serverUri).forClaimableBalance(strKeyId);

      expect(builder.buildUri().path, contains('/claimable_balances/$cbHexId'));
    });

    test('forClaimableBalance throws on invalid B-prefixed id', () {
      expect(
        () => TransactionsRequestBuilder(http.Client(), serverUri)
            .forClaimableBalance('BINVALIDBALANCEID'),
        throwsArgumentError,
      );
    });
  });

  group('TransactionsRequestBuilder single fetch and stream', () {
    final serverUri = Uri.parse('https://horizon-testnet.stellar.org');
    final sourceAccount =
        'GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B';
    final transactionRecord = {
      '_links': {},
      'id': 'abc123def456',
      'paging_token': '12345-123',
      'successful': true,
      'hash': 'abc123def456',
      'ledger': 12345,
      'created_at': '2024-01-01T00:00:00Z',
      'source_account': sourceAccount,
      'fee_account': sourceAccount,
      'source_account_sequence': '123456789',
      'fee_charged': '100',
      'max_fee': '1000',
      'operation_count': 1,
      'envelope_xdr': 'AAAAAAAA...',
      'result_xdr': 'AAAAAAA...',
      'result_meta_xdr': 'AAAAAAA...',
      'fee_meta_xdr': 'AAAAAAA...',
      'memo_type': 'none',
      'signatures': ['sig1', 'sig2']
    };

    test('transaction(id) fetches a single transaction', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, contains('/transactions/abc123def456'));
        return http.Response(json.encode(transactionRecord), 200);
      });

      final builder = TransactionsRequestBuilder(mockClient, serverUri);
      final tx = await builder.transaction('abc123def456');

      expect(tx, isA<TransactionResponse>());
      expect(tx.hash, equals('abc123def456'));
      expect(tx.ledger, equals(12345));
      expect(tx.successful, isTrue);
      expect(tx.sourceAccount, equals(sourceAccount));
    });

    test('stream parses an SSE data frame into a transaction', () async {
      final mockClient = MockClient.streaming((request, bodyStream) async {
        final controller = StreamController<List<int>>();
        controller.add(utf8.encode('event: open\ndata: "hello"\n\n'));
        controller
            .add(utf8.encode('data: ${json.encode(transactionRecord)}\n\n'));
        return http.StreamedResponse(controller.stream, 200,
            headers: {'content-type': 'text/event-stream'});
      });

      final builder = TransactionsRequestBuilder(mockClient, serverUri);
      final completer = Completer<TransactionResponse>();
      final subscription = builder.stream().listen((event) {
        if (!completer.isCompleted) {
          completer.complete(event);
        }
      });

      final event = await completer.future.timeout(const Duration(seconds: 10));
      await subscription.cancel();

      expect(event, isA<TransactionResponse>());
      expect(event.successful, isTrue);
      expect(event.hash, equals('abc123def456'));
      expect(event.ledger, equals(12345));
    });
  });

}
