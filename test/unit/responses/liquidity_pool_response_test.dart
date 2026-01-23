import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('LiquidityPoolResponse', () {
    test('parses JSON with all fields correctly', () {
      final json = {
        'id': 'dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7',
        'fee_bp': 30,
        'type': 'constant_product',
        'total_trustlines': '150',
        'total_shares': '5000.0000000',
        'reserves': [
          {'amount': '1000.0000000', 'asset': 'USDC:GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5'},
          {'amount': '2000.0000000', 'asset': 'native'}
        ],
        'paging_token': 'test-token',
        '_links': {
          'self': {'href': 'https://horizon.stellar.org/liquidity_pools/dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7'},
          'operations': {'href': 'https://horizon.stellar.org/liquidity_pools/dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7/operations'},
          'transactions': {'href': 'https://horizon.stellar.org/liquidity_pools/dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7/transactions'}
        }
      };

      final response = LiquidityPoolResponse.fromJson(json);

      expect(response.poolId, equals('dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7'));
      expect(response.fee, equals(30));
      expect(response.type, equals('constant_product'));
      expect(response.totalTrustlines, equals('150'));
      expect(response.totalShares, equals('5000.0000000'));
      expect(response.pagingToken, equals('test-token'));
    });

    test('parses reserves correctly', () {
      final json = {
        'id': 'test-pool-id',
        'fee_bp': 30,
        'type': 'constant_product',
        'total_trustlines': '10',
        'total_shares': '100.0',
        'reserves': [
          {'amount': '50.0', 'asset': 'USDC:GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5'},
          {'amount': '100.0', 'asset': 'native'}
        ],
        'paging_token': 'token',
        '_links': {
          'self': {'href': 'https://example.com'},
          'operations': {'href': 'https://example.com/operations'},
          'transactions': {'href': 'https://example.com/transactions'}
        }
      };

      final response = LiquidityPoolResponse.fromJson(json);

      expect(response.reserves.length, equals(2));
      expect(response.reserves[0].amount, equals('50.0'));
      expect(response.reserves[0].asset, isA<AssetTypeCreditAlphaNum4>());
      expect((response.reserves[0].asset as AssetTypeCreditAlphaNum4).code, equals('USDC'));
      expect(response.reserves[1].amount, equals('100.0'));
      expect(response.reserves[1].asset, isA<AssetTypeNative>());
    });

    test('parses links correctly', () {
      final json = {
        'id': 'test-pool-id',
        'fee_bp': 30,
        'type': 'constant_product',
        'total_trustlines': '10',
        'total_shares': '100.0',
        'reserves': [
          {'amount': '50.0', 'asset': 'native'}
        ],
        'paging_token': 'token',
        '_links': {
          'self': {'href': 'https://horizon.stellar.org/liquidity_pools/test'},
          'operations': {'href': 'https://horizon.stellar.org/liquidity_pools/test/operations'},
          'transactions': {'href': 'https://horizon.stellar.org/liquidity_pools/test/transactions'}
        }
      };

      final response = LiquidityPoolResponse.fromJson(json);

      expect(response.links.self.href, equals('https://horizon.stellar.org/liquidity_pools/test'));
      expect(response.links.operations.href, equals('https://horizon.stellar.org/liquidity_pools/test/operations'));
      expect(response.links.transactions.href, equals('https://horizon.stellar.org/liquidity_pools/test/transactions'));
    });

    test('converts fee basis points to integer', () {
      final json = {
        'id': 'test-pool-id',
        'fee_bp': 30,
        'type': 'constant_product',
        'total_trustlines': '10',
        'total_shares': '100.0',
        'reserves': [
          {'amount': '50.0', 'asset': 'native'}
        ],
        'paging_token': 'token',
        '_links': {
          'self': {'href': 'https://example.com'},
          'operations': {'href': 'https://example.com/operations'},
          'transactions': {'href': 'https://example.com/transactions'}
        }
      };

      final response = LiquidityPoolResponse.fromJson(json);

      expect(response.fee, isA<int>());
      expect(response.fee, equals(30));
    });

    test('throws exception when fee is null', () {
      final json = {
        'id': 'test-pool-id',
        'fee_bp': null,
        'type': 'constant_product',
        'total_trustlines': '10',
        'total_shares': '100.0',
        'reserves': [
          {'amount': '50.0', 'asset': 'native'}
        ],
        'paging_token': 'token',
        '_links': {
          'self': {'href': 'https://example.com'},
          'operations': {'href': 'https://example.com/operations'},
          'transactions': {'href': 'https://example.com/transactions'}
        }
      };

      expect(() => LiquidityPoolResponse.fromJson(json), throwsException);
    });

    test('throws exception when reserves are null', () {
      final json = {
        'id': 'test-pool-id',
        'fee_bp': 30,
        'type': 'constant_product',
        'total_trustlines': '10',
        'total_shares': '100.0',
        'reserves': null,
        'paging_token': 'token',
        '_links': {
          'self': {'href': 'https://example.com'},
          'operations': {'href': 'https://example.com/operations'},
          'transactions': {'href': 'https://example.com/transactions'}
        }
      };

      expect(() => LiquidityPoolResponse.fromJson(json), throwsException);
    });

    test('throws exception when links are null', () {
      final json = {
        'id': 'test-pool-id',
        'fee_bp': 30,
        'type': 'constant_product',
        'total_trustlines': '10',
        'total_shares': '100.0',
        'reserves': [
          {'amount': '50.0', 'asset': 'native'}
        ],
        'paging_token': 'token',
        '_links': null
      };

      expect(() => LiquidityPoolResponse.fromJson(json), throwsException);
    });
  });

  group('ReserveResponse', () {
    test('parses JSON with credit asset correctly', () {
      final json = {
        'amount': '1000.0000000',
        'asset': 'USDC:GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5'
      };

      final reserve = ReserveResponse.fromJson(json);

      expect(reserve.amount, equals('1000.0000000'));
      expect(reserve.asset, isA<AssetTypeCreditAlphaNum4>());
      expect((reserve.asset as AssetTypeCreditAlphaNum4).code, equals('USDC'));
    });

    test('parses JSON with native asset correctly', () {
      final json = {'amount': '500.0', 'asset': 'native'};

      final reserve = ReserveResponse.fromJson(json);

      expect(reserve.amount, equals('500.0'));
      expect(reserve.asset, isA<AssetTypeNative>());
    });

    test('throws exception for invalid asset', () {
      final json = {'amount': '100.0', 'asset': 'invalid-asset-format'};

      expect(() => ReserveResponse.fromJson(json), throwsException);
    });
  });

  group('LiquidityPoolResponseLinks', () {
    test('parses all links correctly', () {
      final json = {
        'self': {'href': 'https://horizon.stellar.org/liquidity_pools/test'},
        'operations': {'href': 'https://horizon.stellar.org/liquidity_pools/test/operations'},
        'transactions': {'href': 'https://horizon.stellar.org/liquidity_pools/test/transactions'}
      };

      final links = LiquidityPoolResponseLinks.fromJson(json);

      expect(links.self.href, equals('https://horizon.stellar.org/liquidity_pools/test'));
      expect(links.operations.href, equals('https://horizon.stellar.org/liquidity_pools/test/operations'));
      expect(links.transactions.href, equals('https://horizon.stellar.org/liquidity_pools/test/transactions'));
    });

    test('throws exception when self link is null', () {
      final json = {
        'self': null,
        'operations': {'href': 'https://example.com'},
        'transactions': {'href': 'https://example.com'}
      };

      expect(() => LiquidityPoolResponseLinks.fromJson(json), throwsException);
    });

    test('throws exception when operations link is null', () {
      final json = {
        'self': {'href': 'https://example.com'},
        'operations': null,
        'transactions': {'href': 'https://example.com'}
      };

      expect(() => LiquidityPoolResponseLinks.fromJson(json), throwsException);
    });

    test('throws exception when transactions link is null', () {
      final json = {
        'self': {'href': 'https://example.com'},
        'operations': {'href': 'https://example.com'},
        'transactions': null
      };

      expect(() => LiquidityPoolResponseLinks.fromJson(json), throwsException);
    });
  });

  group('LiquidityPoolTradesResponse', () {
    test('parses JSON correctly', () {
      final json = {
        '_embedded': {
          'records': [
            {
              'id': '123-0',
              'paging_token': 'token-1',
              'ledger_close_time': '2023-08-15T10:30:45Z',
              'offer_id': null,
              'base_is_seller': true,
              'base_account': null,
              'base_offer_id': null,
              'base_amount': '100.0',
              'base_asset_type': 'native',
              'base_asset_code': null,
              'base_asset_issuer': null,
              'counter_account': null,
              'counter_offer_id': null,
              'counter_amount': '200.0',
              'counter_asset_type': 'credit_alphanum4',
              'counter_asset_code': 'USDC',
              'counter_asset_issuer': 'GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5',
              'trade_type': 'liquidity_pool',
              'base_liquidity_pool_id': 'pool-1',
              'counter_liquidity_pool_id': null,
              'liquidity_pool_fee_bp': 30,
              'price': {'n': 2, 'd': 1},
              '_links': {
                'base': {'href': 'https://example.com/base'},
                'counter': {'href': 'https://example.com/counter'},
                'operation': {'href': 'https://example.com/operation'}
              }
            }
          ]
        },
        '_links': {
          'self': {'href': 'https://horizon.stellar.org/liquidity_pools/test/trades'}
        }
      };

      final response = LiquidityPoolTradesResponse.fromJson(json);

      expect(response.records.length, equals(1));
      expect(response.records[0].id, equals('123-0'));
      expect(response.links.self.href, equals('https://horizon.stellar.org/liquidity_pools/test/trades'));
    });

    test('throws exception when records are null', () {
      final json = {
        '_embedded': {'records': null},
        '_links': {'self': {'href': 'https://example.com'}}
      };

      expect(() => LiquidityPoolTradesResponse.fromJson(json), throwsException);
    });

    test('throws exception when links are null', () {
      final json = {
        '_embedded': {'records': []},
        '_links': null
      };

      expect(() => LiquidityPoolTradesResponse.fromJson(json), throwsException);
    });
  });

  group('LiquidityPoolTradesResponseLinks', () {
    test('parses self link correctly', () {
      final json = {
        'self': {'href': 'https://horizon.stellar.org/liquidity_pools/test/trades'}
      };

      final links = LiquidityPoolTradesResponseLinks.fromJson(json);

      expect(links.self.href, equals('https://horizon.stellar.org/liquidity_pools/test/trades'));
    });

    test('throws exception when self link is null', () {
      final json = {'self': null};

      expect(() => LiquidityPoolTradesResponseLinks.fromJson(json), throwsException);
    });
  });
}
