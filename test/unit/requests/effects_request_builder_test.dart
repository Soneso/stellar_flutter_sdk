// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

void main() {
  group('EffectsRequestBuilder Tests', () {
    late Uri serverUri;

    setUp(() {
      serverUri = Uri.parse('https://horizon-testnet.stellar.org');
    });

    test('execute returns Page<EffectResponse>', () async {
      final mockResponse = {
        '_links': {
          'self': {'href': 'https://horizon-testnet.stellar.org/effects?limit=10'},
          'next': {'href': 'https://horizon-testnet.stellar.org/effects?cursor=next'},
          'prev': {'href': 'https://horizon-testnet.stellar.org/effects?cursor=prev'}
        },
        '_embedded': {
          'records': [
            {
              '_links': {
                'operation': {'href': 'https://horizon-testnet.stellar.org/operations/123'},
                'succeeds': {'href': 'https://horizon-testnet.stellar.org/effects?order=desc&cursor=123'},
                'precedes': {'href': 'https://horizon-testnet.stellar.org/effects?order=asc&cursor=123'}
              },
              'id': '0000123456789-0000000001',
              'paging_token': '0000123456789-0000000001',
              'account': 'GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B',
              'type': 'account_created',
              'type_i': 0,
              'created_at': '2024-01-01T00:00:00Z',
              'starting_balance': '10.0000000'
            },
            {
              '_links': {
                'operation': {'href': 'https://horizon-testnet.stellar.org/operations/124'},
                'succeeds': {'href': 'https://horizon-testnet.stellar.org/effects?order=desc&cursor=124'},
                'precedes': {'href': 'https://horizon-testnet.stellar.org/effects?order=asc&cursor=124'}
              },
              'id': '0000123456790-0000000001',
              'paging_token': '0000123456790-0000000001',
              'account': 'GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B',
              'type': 'account_debited',
              'type_i': 3,
              'created_at': '2024-01-01T00:01:00Z',
              'asset_type': 'native',
              'amount': '100.0000000'
            }
          ]
        }
      };

      final mockClient = MockClient((request) async {
        return http.Response(json.encode(mockResponse), 200);
      });

      final builder = EffectsRequestBuilder(mockClient, serverUri);
      final page = await builder.limit(10).execute();

      expect(page.records.length, equals(2));
      expect(page.records[0], isA<EffectResponse>());
      expect(page.links, isNotNull);
    });

    test('forAccount sets correct path segments', () {
      final mockClient = MockClient((request) async {
        return http.Response('{"_embedded": {"records": []}}', 200);
      });

      final accountId = 'GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B';
      final builder = EffectsRequestBuilder(mockClient, serverUri);
      builder.forAccount(accountId);
      final uri = builder.buildUri();

      expect(uri.path, contains('/accounts/$accountId/effects'));
    });

    test('forLedger sets correct path segments', () {
      final mockClient = MockClient((request) async {
        return http.Response('{"_embedded": {"records": []}}', 200);
      });

      final builder = EffectsRequestBuilder(mockClient, serverUri);
      builder.forLedger(12345);
      final uri = builder.buildUri();

      expect(uri.path, contains('/ledgers/12345/effects'));
    });

    test('forTransaction sets correct path segments', () {
      final mockClient = MockClient((request) async {
        return http.Response('{"_embedded": {"records": []}}', 200);
      });

      final txHash = 'abc123def456';
      final builder = EffectsRequestBuilder(mockClient, serverUri);
      builder.forTransaction(txHash);
      final uri = builder.buildUri();

      expect(uri.path, contains('/transactions/$txHash/effects'));
    });

    test('forOperation sets correct path segments', () {
      final mockClient = MockClient((request) async {
        return http.Response('{"_embedded": {"records": []}}', 200);
      });

      final operationId = '123456789';
      final builder = EffectsRequestBuilder(mockClient, serverUri);
      builder.forOperation(operationId);
      final uri = builder.buildUri();

      expect(uri.path, contains('/operations/$operationId/effects'));
    });

    test('combining filters with pagination', () {
      final mockClient = MockClient((request) async {
        return http.Response('{"_embedded": {"records": []}}', 200);
      });

      final accountId = 'GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B';
      final builder = EffectsRequestBuilder(mockClient, serverUri);
      builder
          .forAccount(accountId)
          .limit(30)
          .order(RequestBuilderOrder.ASC)
          .cursor('cursor123');
      final uri = builder.buildUri();

      expect(uri.path, contains('/accounts/$accountId/effects'));
      expect(uri.queryParameters['limit'], equals('30'));
      expect(uri.queryParameters['order'], equals('asc'));
      expect(uri.queryParameters['cursor'], equals('cursor123'));
    });

    test('stream returns Stream<EffectResponse>', () {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          '_embedded': {'records': []}
        }), 200);
      });

      final builder = EffectsRequestBuilder(mockClient, serverUri);
      final stream = builder.stream();

      expect(stream, isA<Stream<EffectResponse>>());
    });
  });
}
