// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

void main() {
  group('LiquidityPoolsRequestBuilder Tests', () {
    late Uri serverUri;

    setUp(() {
      serverUri = Uri.parse('https://horizon-testnet.stellar.org');
    });

    test('execute returns Page<LiquidityPoolResponse>', () async {
      final mockResponse = {
        '_links': {
          'self': {'href': 'https://horizon-testnet.stellar.org/liquidity_pools?limit=10'},
          'next': {'href': 'https://horizon-testnet.stellar.org/liquidity_pools?cursor=next'},
          'prev': {'href': 'https://horizon-testnet.stellar.org/liquidity_pools?cursor=prev'}
        },
        '_embedded': {
          'records': [
            {
              '_links': {
                'self': {'href': 'https://horizon-testnet.stellar.org/liquidity_pools/abc123'},
                'operations': {'href': 'https://horizon-testnet.stellar.org/liquidity_pools/abc123/operations'},
                'transactions': {'href': 'https://horizon-testnet.stellar.org/liquidity_pools/abc123/transactions'}
              },
              'id': 'dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7',
              'paging_token': 'dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7',
              'fee_bp': 30,
              'type': 'constant_product',
              'total_trustlines': '100',
              'total_shares': '1000.0000000',
              'reserves': [
                {
                  'asset': 'native',
                  'amount': '500.0000000'
                },
                {
                  'asset': 'USD:GBVOL67TMUQBGL4TZYNMY3ZQ5WGQYFPFD5VJRWXR72VA33VFNL225PL5',
                  'amount': '500.0000000'
                }
              ],
              'last_modified_ledger': 12345,
              'last_modified_time': '2024-01-01T00:00:00Z'
            }
          ]
        }
      };

      final mockClient = MockClient((request) async {
        return http.Response(json.encode(mockResponse), 200);
      });

      final builder = LiquidityPoolsRequestBuilder(mockClient, serverUri);
      final page = await builder.limit(10).execute();

      expect(page.records.length, equals(1));
      expect(page.records[0], isA<LiquidityPoolResponse>());
      expect(page.records[0].poolId, equals('dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7'));
      expect(page.links, isNotNull);
    });

    test('forAccount adds query parameter', () {
      final mockClient = MockClient((request) async {
        return http.Response('{"_embedded": {"records": []}}', 200);
      });

      final accountId = 'GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B';
      final builder = LiquidityPoolsRequestBuilder(mockClient, serverUri);
      builder.forAccount(accountId);
      final uri = builder.buildUri();

      expect(uri.queryParameters['account'], equals(accountId));
    });

    test('forReserveAssets adds reserves query parameter', () {
      final mockClient = MockClient((request) async {
        return http.Response('{"_embedded": {"records": []}}', 200);
      });

      final issuerId = 'GBVOL67TMUQBGL4TZYNMY3ZQ5WGQYFPFD5VJRWXR72VA33VFNL225PL5';
      final assetA = Asset.NATIVE;
      final assetB = AssetTypeCreditAlphaNum4('USD', issuerId);
      final builder = LiquidityPoolsRequestBuilder(mockClient, serverUri);
      builder.forReserveAssets(assetA, assetB);
      final uri = builder.buildUri();

      expect(uri.queryParameters['reserves'], isNotNull);
      expect(uri.queryParameters['reserves'], contains('native'));
      expect(uri.queryParameters['reserves'], contains('USD'));
      expect(uri.queryParameters['reserves'], contains(issuerId));
    });

    test('forReserveAssets with two credit assets', () {
      final mockClient = MockClient((request) async {
        return http.Response('{"_embedded": {"records": []}}', 200);
      });

      final issuerId = 'GBVOL67TMUQBGL4TZYNMY3ZQ5WGQYFPFD5VJRWXR72VA33VFNL225PL5';
      final assetA = AssetTypeCreditAlphaNum4('USD', issuerId);
      final assetB = AssetTypeCreditAlphaNum4('EUR', issuerId);
      final builder = LiquidityPoolsRequestBuilder(mockClient, serverUri);
      builder.forReserveAssets(assetA, assetB);
      final uri = builder.buildUri();

      expect(uri.queryParameters['reserves'], contains('USD'));
      expect(uri.queryParameters['reserves'], contains('EUR'));
      expect(uri.queryParameters['reserves'], contains(','));
    });

    test('combining filters with pagination', () {
      final mockClient = MockClient((request) async {
        return http.Response('{"_embedded": {"records": []}}', 200);
      });

      final accountId = 'GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B';
      final builder = LiquidityPoolsRequestBuilder(mockClient, serverUri);
      builder
          .forAccount(accountId)
          .limit(25)
          .order(RequestBuilderOrder.DESC)
          .cursor('cursor123');
      final uri = builder.buildUri();

      expect(uri.queryParameters['account'], equals(accountId));
      expect(uri.queryParameters['limit'], equals('25'));
      expect(uri.queryParameters['order'], equals('desc'));
      expect(uri.queryParameters['cursor'], equals('cursor123'));
    });

    // Note: LiquidityPoolsRequestBuilder does not have a stream() method

    test('basic builder creates correct URI', () {
      final mockClient = MockClient((request) async {
        return http.Response('{"_embedded": {"records": []}}', 200);
      });

      final builder = LiquidityPoolsRequestBuilder(mockClient, serverUri);
      final uri = builder.buildUri();

      expect(uri.path, contains('/liquidity_pools'));
    });

    test('chaining methods returns same builder instance', () {
      final mockClient = MockClient((request) async {
        return http.Response('{"_embedded": {"records": []}}', 200);
      });

      final accountId = 'GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B';
      final builder = LiquidityPoolsRequestBuilder(mockClient, serverUri);
      final result1 = builder.forAccount(accountId);
      final result2 = result1.cursor('test');
      final result3 = result2.limit(10);
      final result4 = result3.order(RequestBuilderOrder.ASC);

      expect(result1, same(builder));
      expect(result2, same(builder));
      expect(result3, same(builder));
      expect(result4, same(builder));
    });
  });
}
