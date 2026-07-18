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
  group('AccountsRequestBuilder Tests', () {
    late Uri serverUri;

    setUp(() {
      serverUri = Uri.parse('https://horizon-testnet.stellar.org');
    });

    test('execute returns Page<AccountResponse>', () async {
      final mockResponse = {
        '_links': {
          'self': {'href': 'https://horizon-testnet.stellar.org/accounts?limit=10'},
          'next': {'href': 'https://horizon-testnet.stellar.org/accounts?cursor=next'},
          'prev': {'href': 'https://horizon-testnet.stellar.org/accounts?cursor=prev'}
        },
        '_embedded': {
          'records': [
            {
              '_links': {
                'self': {'href': 'https://horizon-testnet.stellar.org/accounts/GABC'},
                'transactions': {'href': 'https://horizon-testnet.stellar.org/accounts/GABC/transactions'},
                'operations': {'href': 'https://horizon-testnet.stellar.org/accounts/GABC/operations'},
                'payments': {'href': 'https://horizon-testnet.stellar.org/accounts/GABC/payments'},
                'effects': {'href': 'https://horizon-testnet.stellar.org/accounts/GABC/effects'},
                'offers': {'href': 'https://horizon-testnet.stellar.org/accounts/GABC/offers'},
                'trades': {'href': 'https://horizon-testnet.stellar.org/accounts/GABC/trades'},
                'data': {'href': 'https://horizon-testnet.stellar.org/accounts/GABC/data/{key}', 'templated': true}
              },
              'id': 'GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B',
              'account_id': 'GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B',
              'sequence': '123456789',
              'subentry_count': 0,
              'last_modified_ledger': 12345,
              'last_modified_time': '2024-01-01T00:00:00Z',
              'thresholds': {
                'low_threshold': 0,
                'med_threshold': 0,
                'high_threshold': 0
              },
              'flags': {
                'auth_required': false,
                'auth_revocable': false,
                'auth_immutable': false,
                'auth_clawback_enabled': false
              },
              'balances': [
                {
                  'balance': '1000.0000000',
                  'buying_liabilities': '0.0000000',
                  'selling_liabilities': '0.0000000',
                  'asset_type': 'native'
                }
              ],
              'signers': [
                {
                  'weight': 1,
                  'key': 'GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B',
                  'type': 'ed25519_public_key'
                }
              ],
              'data': {},
              'num_sponsoring': 0,
              'num_sponsored': 0,
              'paging_token': 'GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B'
            }
          ]
        }
      };

      final mockClient = MockClient((request) async {
        return http.Response(json.encode(mockResponse), 200);
      });

      final builder = AccountsRequestBuilder(mockClient, serverUri);
      final page = await builder.limit(10).execute();

      expect(page.records.length, equals(1));
      expect(page.records[0], isA<AccountResponse>());
      expect(page.records[0].accountId, equals('GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B'));
      expect(page.links, isNotNull);
    });

    test('forSigner adds query parameter', () {
      final mockClient = MockClient((request) async {
        return http.Response('{"_embedded": {"records": []}}', 200);
      });

      final accountId = 'GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B';
      final builder = AccountsRequestBuilder(mockClient, serverUri);
      builder.forSigner(accountId);
      final uri = builder.buildUri();

      expect(uri.queryParameters['signer'], equals(accountId));
    });

    test('forAsset with native asset adds query parameter', () {
      final mockClient = MockClient((request) async {
        return http.Response('{"_embedded": {"records": []}}', 200);
      });

      final builder = AccountsRequestBuilder(mockClient, serverUri);
      builder.forAsset(Asset.NATIVE);
      final uri = builder.buildUri();

      expect(uri.queryParameters['asset'], equals('native'));
    });

    test('forAsset with credit asset adds query parameter', () {
      final mockClient = MockClient((request) async {
        return http.Response('{"_embedded": {"records": []}}', 200);
      });

      final issuerId = 'GBVOL67TMUQBGL4TZYNMY3ZQ5WGQYFPFD5VJRWXR72VA33VFNL225PL5';
      final asset = AssetTypeCreditAlphaNum4('USD', issuerId);
      final builder = AccountsRequestBuilder(mockClient, serverUri);
      builder.forAsset(asset);
      final uri = builder.buildUri();

      expect(uri.queryParameters['asset'], equals('USD:$issuerId'));
    });

    test('forSponsor adds query parameter', () {
      final mockClient = MockClient((request) async {
        return http.Response('{"_embedded": {"records": []}}', 200);
      });

      final sponsorId = 'GBVOL67TMUQBGL4TZYNMY3ZQ5WGQYFPFD5VJRWXR72VA33VFNL225PL5';
      final builder = AccountsRequestBuilder(mockClient, serverUri);
      builder.forSponsor(sponsorId);
      final uri = builder.buildUri();

      expect(uri.queryParameters['sponsor'], equals(sponsorId));
    });

    test('combining filters with pagination', () {
      final mockClient = MockClient((request) async {
        return http.Response('{"_embedded": {"records": []}}', 200);
      });

      final signerId = 'GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B';
      final builder = AccountsRequestBuilder(mockClient, serverUri);
      builder
          .forSigner(signerId)
          .limit(50)
          .order(RequestBuilderOrder.ASC)
          .cursor('cursor123');
      final uri = builder.buildUri();

      expect(uri.queryParameters['signer'], equals(signerId));
      expect(uri.queryParameters['limit'], equals('50'));
      expect(uri.queryParameters['order'], equals('asc'));
      expect(uri.queryParameters['cursor'], equals('cursor123'));
    });

    test('stream returns Stream<AccountResponse>', () {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          '_embedded': {'records': []}
        }), 200);
      });

      final builder = AccountsRequestBuilder(mockClient, serverUri);
      final stream = builder.stream();

      expect(stream, isA<Stream<AccountResponse>>());
    });
  });

  group('AccountsRequestBuilder strkey id validation', () {
    final serverUri = Uri.parse('https://horizon-testnet.stellar.org');

    test('forLiquidityPool converts L strkey id to hex', () {
      final poolHexId =
          '0a1b2c3d4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f9';
      final strKeyId =
          StrKey.encodeLiquidityPoolId(Util.hexToBytes(poolHexId));

      final builder =
          AccountsRequestBuilder(http.Client(), serverUri).forLiquidityPool(strKeyId);

      expect(builder.buildUri().queryParameters['liquidity_pool'],
          equals(poolHexId));
    });

    test('forLiquidityPool throws on invalid L-prefixed id', () {
      expect(
        () => AccountsRequestBuilder(http.Client(), serverUri)
            .forLiquidityPool('LINVALIDPOOLID'),
        throwsArgumentError,
      );
    });
  });

  group('AccountsRequestBuilder stream event delivery', () {
    final serverUri = Uri.parse('https://horizon-testnet.stellar.org');
    final accountId =
        'GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B';
    final accountRecord = {
      '_links': {
        'self': {'href': 'https://horizon-testnet.stellar.org/accounts/GABC'},
        'transactions': {'href': 'x'},
        'operations': {'href': 'x'},
        'payments': {'href': 'x'},
        'effects': {'href': 'x'},
        'offers': {'href': 'x'},
        'trades': {'href': 'x'},
        'data': {'href': 'x'}
      },
      'id': accountId,
      'account_id': accountId,
      'sequence': '123456789',
      'subentry_count': 3,
      'last_modified_ledger': 12345,
      'last_modified_time': '2024-01-01T00:00:00Z',
      'thresholds': {
        'low_threshold': 0,
        'med_threshold': 0,
        'high_threshold': 0
      },
      'flags': {
        'auth_required': false,
        'auth_revocable': false,
        'auth_immutable': false,
        'auth_clawback_enabled': false
      },
      'balances': [
        {
          'balance': '1000.0000000',
          'buying_liabilities': '0.0000000',
          'selling_liabilities': '0.0000000',
          'asset_type': 'native'
        }
      ],
      'signers': [
        {'weight': 1, 'key': accountId, 'type': 'ed25519_public_key'}
      ],
      'data': {},
      'num_sponsoring': 0,
      'num_sponsored': 0,
      'paging_token': accountId
    };

    test('stream parses an SSE data frame into a typed account', () async {
      final mockClient = MockClient.streaming((request, bodyStream) async {
        final controller = StreamController<List<int>>();
        controller.add(utf8.encode('event: open\ndata: "hello"\n\n'));
        controller.add(utf8.encode('data: ${json.encode(accountRecord)}\n\n'));
        return http.StreamedResponse(controller.stream, 200,
            headers: {'content-type': 'text/event-stream'});
      });

      final builder = AccountsRequestBuilder(mockClient, serverUri);
      final completer = Completer<AccountResponse>();
      final subscription = builder.stream().listen((event) {
        if (!completer.isCompleted) {
          completer.complete(event);
        }
      });

      final event = await completer.future.timeout(const Duration(seconds: 10));
      await subscription.cancel();

      expect(event, isA<AccountResponse>());
      expect(event.accountId, equals(accountId));
      expect(event.sequenceNumber, equals(BigInt.from(123456789)));
      expect(event.subentryCount, equals(3));
    });
  });

}
