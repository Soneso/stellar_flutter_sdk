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
  group('OperationsRequestBuilder Tests', () {
    late Uri serverUri;

    setUp(() {
      serverUri = Uri.parse('https://horizon-testnet.stellar.org');
    });

    test('execute returns Page<OperationResponse>', () async {
      final mockResponse = {
        '_links': {
          'self': {'href': 'https://horizon-testnet.stellar.org/operations?limit=10'},
          'next': {'href': 'https://horizon-testnet.stellar.org/operations?cursor=next'},
          'prev': {'href': 'https://horizon-testnet.stellar.org/operations?cursor=prev'}
        },
        '_embedded': {
          'records': [
            {
              '_links': {
                'self': {'href': 'https://horizon-testnet.stellar.org/operations/123'},
                'transaction': {'href': 'https://horizon-testnet.stellar.org/transactions/abc'},
                'effects': {'href': 'https://horizon-testnet.stellar.org/operations/123/effects'},
                'succeeds': {'href': 'https://horizon-testnet.stellar.org/effects?order=desc&cursor=123'},
                'precedes': {'href': 'https://horizon-testnet.stellar.org/effects?order=asc&cursor=123'}
              },
              'id': '123456789',
              'paging_token': '123456789',
              'transaction_successful': true,
              'source_account': 'GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B',
              'type': 'create_account',
              'type_i': 0,
              'created_at': '2024-01-01T00:00:00Z',
              'transaction_hash': 'abc123def456',
              'starting_balance': '10.0000000',
              'funder': 'GBVOL67TMUQBGL4TZYNMY3ZQ5WGQYFPFD5VJRWXR72VA33VFNL225PL5',
              'account': 'GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B'
            },
            {
              '_links': {
                'self': {'href': 'https://horizon-testnet.stellar.org/operations/124'},
                'transaction': {'href': 'https://horizon-testnet.stellar.org/transactions/def'},
                'effects': {'href': 'https://horizon-testnet.stellar.org/operations/124/effects'},
                'succeeds': {'href': 'https://horizon-testnet.stellar.org/effects?order=desc&cursor=124'},
                'precedes': {'href': 'https://horizon-testnet.stellar.org/effects?order=asc&cursor=124'}
              },
              'id': '123456790',
              'paging_token': '123456790',
              'transaction_successful': true,
              'source_account': 'GBVOL67TMUQBGL4TZYNMY3ZQ5WGQYFPFD5VJRWXR72VA33VFNL225PL5',
              'type': 'payment',
              'type_i': 1,
              'created_at': '2024-01-01T00:01:00Z',
              'transaction_hash': 'def456ghi789',
              'asset_type': 'native',
              'from': 'GBVOL67TMUQBGL4TZYNMY3ZQ5WGQYFPFD5VJRWXR72VA33VFNL225PL5',
              'to': 'GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B',
              'amount': '100.0000000'
            }
          ]
        }
      };

      final mockClient = MockClient((request) async {
        return http.Response(json.encode(mockResponse), 200);
      });

      final builder = OperationsRequestBuilder(mockClient, serverUri);
      final page = await builder.limit(10).execute();

      expect(page.records.length, equals(2));
      expect(page.records[0], isA<CreateAccountOperationResponse>());
      expect(page.records[1], isA<PaymentOperationResponse>());
      expect(page.links, isNotNull);
      expect(page.links!.next, isNotNull);
    });

    test('forAccount sets correct path segments', () {
      final mockClient = MockClient((request) async {
        return http.Response('{"_embedded": {"records": []}}', 200);
      });

      final accountId = 'GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B';
      final builder = OperationsRequestBuilder(mockClient, serverUri);
      builder.forAccount(accountId);
      final uri = builder.buildUri();

      expect(uri.path, contains('/accounts/$accountId/operations'));
    });

    test('forLedger sets correct path segments', () {
      final mockClient = MockClient((request) async {
        return http.Response('{"_embedded": {"records": []}}', 200);
      });

      final builder = OperationsRequestBuilder(mockClient, serverUri);
      builder.forLedger(12345);
      final uri = builder.buildUri();

      expect(uri.path, contains('/ledgers/12345/operations'));
    });

    test('forTransaction sets correct path segments', () {
      final mockClient = MockClient((request) async {
        return http.Response('{"_embedded": {"records": []}}', 200);
      });

      final txHash = 'abc123def456';
      final builder = OperationsRequestBuilder(mockClient, serverUri);
      builder.forTransaction(txHash);
      final uri = builder.buildUri();

      expect(uri.path, contains('/transactions/$txHash/operations'));
    });

    test('includeFailed adds query parameter', () {
      final mockClient = MockClient((request) async {
        return http.Response('{"_embedded": {"records": []}}', 200);
      });

      final builder = OperationsRequestBuilder(mockClient, serverUri);
      builder.includeFailed(true);
      final uri = builder.buildUri();

      expect(uri.queryParameters['include_failed'], equals('true'));
    });

    test('combining filters with pagination', () {
      final mockClient = MockClient((request) async {
        return http.Response('{"_embedded": {"records": []}}', 200);
      });

      final accountId = 'GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B';
      final builder = OperationsRequestBuilder(mockClient, serverUri);
      builder
          .forAccount(accountId)
          .includeFailed(true)
          .limit(50)
          .order(RequestBuilderOrder.DESC)
          .cursor('cursor123');
      final uri = builder.buildUri();

      expect(uri.path, contains('/accounts/$accountId/operations'));
      expect(uri.queryParameters['include_failed'], equals('true'));
      expect(uri.queryParameters['limit'], equals('50'));
      expect(uri.queryParameters['order'], equals('desc'));
      expect(uri.queryParameters['cursor'], equals('cursor123'));
    });

    test('stream returns Stream<OperationResponse>', () {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          '_embedded': {'records': []}
        }), 200);
      });

      final builder = OperationsRequestBuilder(mockClient, serverUri);
      final stream = builder.stream();

      expect(stream, isA<Stream<OperationResponse>>());
    });
  });

  group('OperationsRequestBuilder strkey id validation', () {
    final serverUri = Uri.parse('https://horizon-testnet.stellar.org');

    test('forLiquidityPool converts L strkey id to hex', () {
      final poolHexId =
          '0a1b2c3d4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f9';
      final strKeyId =
          StrKey.encodeLiquidityPoolId(Util.hexToBytes(poolHexId));

      final builder =
          OperationsRequestBuilder(http.Client(), serverUri).forLiquidityPool(strKeyId);

      expect(builder.buildUri().path, contains('/liquidity_pools/$poolHexId'));
    });

    test('forLiquidityPool throws on invalid L-prefixed id', () {
      expect(
        () => OperationsRequestBuilder(http.Client(), serverUri)
            .forLiquidityPool('LINVALIDPOOLID'),
        throwsArgumentError,
      );
    });

    test('forClaimableBalance converts B strkey id to hex', () {
      final cbHashHex =
          '0a1b2c3d4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f9';
      final strKeyId = StrKey.encodeClaimableBalanceIdHex(cbHashHex);

      final builder =
          OperationsRequestBuilder(http.Client(), serverUri).forClaimableBalance(strKeyId);

      expect(
        builder.buildUri().path,
        matches(
            RegExp('/claimable_balances/00000000$cbHashHex/operations\$')),
      );
    });

    test('forClaimableBalance normalizes a bare hex id to the Horizon form', () {
      final cbHashHex =
          '0a1b2c3d4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f9';

      final builder = OperationsRequestBuilder(http.Client(), serverUri)
          .forClaimableBalance(cbHashHex);

      expect(
        builder.buildUri().path,
        matches(
            RegExp('/claimable_balances/00000000$cbHashHex/operations\$')),
      );
    });

    test('forClaimableBalance normalizes a one byte tagged hex id', () {
      // The single discriminant byte is the width the strkey payload carries.
      // It names the same balance as the four byte XDR union discriminant.
      final cbHashHex =
          '0a1b2c3d4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f9';

      final builder = OperationsRequestBuilder(http.Client(), serverUri)
          .forClaimableBalance('00$cbHashHex');

      expect(
        builder.buildUri().path,
        matches(
            RegExp('/claimable_balances/00000000$cbHashHex/operations\$')),
      );
    });

    test('forClaimableBalance throws on invalid B-prefixed id', () {
      expect(
        () => OperationsRequestBuilder(http.Client(), serverUri)
            .forClaimableBalance('BINVALIDBALANCEID'),
        throwsArgumentError,
      );
    });
  });

  group('OperationsRequestBuilder single fetch and stream', () {
    final serverUri = Uri.parse('https://horizon-testnet.stellar.org');
    final funder = 'GBVOL67TMUQBGL4TZYNMY3ZQ5WGQYFPFD5VJRWXR72VA33VFNL225PL5';
    final account = 'GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B';
    final operationRecord = {
      '_links': {
        'self': {'href': 'x'},
        'transaction': {'href': 'x'},
        'effects': {'href': 'x'},
        'succeeds': {'href': 'x'},
        'precedes': {'href': 'x'}
      },
      'id': '123456789',
      'paging_token': '123456789',
      'transaction_successful': true,
      'source_account': account,
      'type': 'create_account',
      'type_i': 0,
      'created_at': '2024-01-01T00:00:00Z',
      'transaction_hash': 'abc123def456',
      'starting_balance': '10.0000000',
      'funder': funder,
      'account': account
    };

    test('operation(id) fetches a single operation', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, contains('/operations/123456789'));
        return http.Response(json.encode(operationRecord), 200);
      });

      final builder = OperationsRequestBuilder(mockClient, serverUri);
      final operation = await builder.operation('123456789');

      expect(operation, isA<CreateAccountOperationResponse>());
      final created = operation as CreateAccountOperationResponse;
      expect(created.account, equals(account));
      expect(created.funder, equals(funder));
      expect(created.startingBalance, equals('10.0000000'));
    });

    test('stream parses an SSE data frame into an operation', () async {
      final mockClient = MockClient.streaming((request, bodyStream) async {
        final controller = StreamController<List<int>>();
        controller.add(utf8.encode('event: open\ndata: "hello"\n\n'));
        controller
            .add(utf8.encode('data: ${json.encode(operationRecord)}\n\n'));
        return http.StreamedResponse(controller.stream, 200,
            headers: {'content-type': 'text/event-stream'});
      });

      final builder = OperationsRequestBuilder(mockClient, serverUri);
      final completer = Completer<OperationResponse>();
      final subscription = builder.stream().listen((event) {
        if (!completer.isCompleted) {
          completer.complete(event);
        }
      });

      final event = await completer.future.timeout(const Duration(seconds: 10));
      await subscription.cancel();

      expect(event, isA<CreateAccountOperationResponse>());
      final created = event as CreateAccountOperationResponse;
      expect(created.account, equals(account));
      expect(created.funder, equals(funder));
    });
  });

}
