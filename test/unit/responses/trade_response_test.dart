import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('TradeResponse', () {
    test('parses orderbook trade JSON correctly', () {
      final json = {
        'id': '123456-0',
        'paging_token': '123456-0',
        'ledger_close_time': '2023-08-15T10:30:45Z',
        'offer_id': '98765',
        'base_is_seller': true,
        'base_account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
        'base_offer_id': '98765',
        'base_amount': '100.0000000',
        'base_asset_type': 'credit_alphanum4',
        'base_asset_code': 'USDC',
        'base_asset_issuer': 'GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5',
        'counter_account': 'GCKG5WGBIJP74UDNRIRDFGENNIH5Y3KZ4KITCTUM4CWMB7LWPGDHKCPM',
        'counter_offer_id': '12345',
        'counter_amount': '250.0000000',
        'counter_asset_type': 'native',
        'counter_asset_code': null,
        'counter_asset_issuer': null,
        'trade_type': 'orderbook',
        'base_liquidity_pool_id': null,
        'counter_liquidity_pool_id': null,
        'liquidity_pool_fee_bp': null,
        'price': {'n': 5, 'd': 2},
        '_links': {
          'base': {'href': 'https://horizon.stellar.org/accounts/GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7'},
          'counter': {'href': 'https://horizon.stellar.org/accounts/GCKG5WGBIJP74UDNRIRDFGENNIH5Y3KZ4KITCTUM4CWMB7LWPGDHKCPM'},
          'operation': {'href': 'https://horizon.stellar.org/operations/123456'}
        }
      };

      final response = TradeResponse.fromJson(json);

      expect(response.id, equals('123456-0'));
      expect(response.pagingToken, equals('123456-0'));
      expect(response.ledgerCloseTime, equals('2023-08-15T10:30:45Z'));
      expect(response.offerId, equals('98765'));
      expect(response.baseIsSeller, isTrue);
      expect(response.baseAccount, equals('GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7'));
      expect(response.baseOfferId, equals('98765'));
      expect(response.baseAmount, equals('100.0000000'));
      expect(response.counterAccount, equals('GCKG5WGBIJP74UDNRIRDFGENNIH5Y3KZ4KITCTUM4CWMB7LWPGDHKCPM'));
      expect(response.counterOfferId, equals('12345'));
      expect(response.counterAmount, equals('250.0000000'));
      expect(response.tradeType, equals('orderbook'));
    });

    test('parses liquidity pool trade JSON correctly', () {
      final json = {
        'id': '789012-0',
        'paging_token': '789012-0',
        'ledger_close_time': '2023-08-15T11:00:00Z',
        'offer_id': null,
        'base_is_seller': false,
        'base_account': null,
        'base_offer_id': null,
        'base_amount': '50.0000000',
        'base_asset_type': 'native',
        'base_asset_code': null,
        'base_asset_issuer': null,
        'counter_account': null,
        'counter_offer_id': null,
        'counter_amount': '100.0000000',
        'counter_asset_type': 'credit_alphanum4',
        'counter_asset_code': 'USDC',
        'counter_asset_issuer': 'GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5',
        'trade_type': 'liquidity_pool',
        'base_liquidity_pool_id': 'dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7',
        'counter_liquidity_pool_id': null,
        'liquidity_pool_fee_bp': 30,
        'price': {'n': 2, 'd': 1},
        '_links': {
          'base': {'href': 'https://horizon.stellar.org/liquidity_pools/dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7'},
          'counter': {'href': 'https://horizon.stellar.org/accounts/GCKG5WGBIJP74UDNRIRDFGENNIH5Y3KZ4KITCTUM4CWMB7LWPGDHKCPM'},
          'operation': {'href': 'https://horizon.stellar.org/operations/789012'}
        }
      };

      final response = TradeResponse.fromJson(json);

      expect(response.tradeType, equals('liquidity_pool'));
      expect(response.baseLiquidityPoolId, equals('dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7'));
      expect(response.liquidityPoolFeeBp, equals(30));
      expect(response.baseAccount, isNull);
      expect(response.counterAccount, isNull);
    });

    test('parses base asset correctly', () {
      final json = {
        'id': '123-0',
        'paging_token': '123-0',
        'ledger_close_time': '2023-08-15T10:30:45Z',
        'offer_id': null,
        'base_is_seller': true,
        'base_account': 'GABC',
        'base_offer_id': '123',
        'base_amount': '100.0',
        'base_asset_type': 'credit_alphanum4',
        'base_asset_code': 'USD',
        'base_asset_issuer': 'GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5',
        'counter_account': 'GDEF',
        'counter_offer_id': '456',
        'counter_amount': '200.0',
        'counter_asset_type': 'native',
        'counter_asset_code': null,
        'counter_asset_issuer': null,
        'trade_type': 'orderbook',
        'base_liquidity_pool_id': null,
        'counter_liquidity_pool_id': null,
        'liquidity_pool_fee_bp': null,
        'price': {'n': 2, 'd': 1},
        '_links': {
          'base': {'href': 'https://example.com'},
          'counter': {'href': 'https://example.com'},
          'operation': {'href': 'https://example.com'}
        }
      };

      final response = TradeResponse.fromJson(json);
      final baseAsset = response.baseAsset;

      expect(baseAsset, isA<AssetTypeCreditAlphaNum4>());
      expect((baseAsset as AssetTypeCreditAlphaNum4).code, equals('USD'));
      expect(baseAsset.issuerId, equals('GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5'));
    });

    test('parses counter asset correctly', () {
      final json = {
        'id': '123-0',
        'paging_token': '123-0',
        'ledger_close_time': '2023-08-15T10:30:45Z',
        'offer_id': null,
        'base_is_seller': true,
        'base_account': 'GABC',
        'base_offer_id': '123',
        'base_amount': '100.0',
        'base_asset_type': 'native',
        'base_asset_code': null,
        'base_asset_issuer': null,
        'counter_account': 'GDEF',
        'counter_offer_id': '456',
        'counter_amount': '200.0',
        'counter_asset_type': 'credit_alphanum12',
        'counter_asset_code': 'LONGERCODE',
        'counter_asset_issuer': 'GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5',
        'trade_type': 'orderbook',
        'base_liquidity_pool_id': null,
        'counter_liquidity_pool_id': null,
        'liquidity_pool_fee_bp': null,
        'price': {'n': 2, 'd': 1},
        '_links': {
          'base': {'href': 'https://example.com'},
          'counter': {'href': 'https://example.com'},
          'operation': {'href': 'https://example.com'}
        }
      };

      final response = TradeResponse.fromJson(json);
      final counterAsset = response.counterAsset;

      expect(counterAsset, isA<AssetTypeCreditAlphaNum12>());
      expect((counterAsset as AssetTypeCreditAlphaNum12).code, equals('LONGERCODE'));
    });

    test('parses price correctly', () {
      final json = {
        'id': '123-0',
        'paging_token': '123-0',
        'ledger_close_time': '2023-08-15T10:30:45Z',
        'offer_id': null,
        'base_is_seller': true,
        'base_account': 'GABC',
        'base_offer_id': '123',
        'base_amount': '100.0',
        'base_asset_type': 'native',
        'base_asset_code': null,
        'base_asset_issuer': null,
        'counter_account': 'GDEF',
        'counter_offer_id': '456',
        'counter_amount': '200.0',
        'counter_asset_type': 'native',
        'counter_asset_code': null,
        'counter_asset_issuer': null,
        'trade_type': 'orderbook',
        'base_liquidity_pool_id': null,
        'counter_liquidity_pool_id': null,
        'liquidity_pool_fee_bp': null,
        'price': {'n': 3, 'd': 2},
        '_links': {
          'base': {'href': 'https://example.com'},
          'counter': {'href': 'https://example.com'},
          'operation': {'href': 'https://example.com'}
        }
      };

      final response = TradeResponse.fromJson(json);

      expect(response.price.n, equals(3));
      expect(response.price.d, equals(2));
    });

    test('handles null accounts for liquidity pool trade', () {
      final json = {
        'id': '123-0',
        'paging_token': '123-0',
        'ledger_close_time': '2023-08-15T10:30:45Z',
        'offer_id': null,
        'base_is_seller': false,
        'base_account': null,
        'base_offer_id': null,
        'base_amount': '100.0',
        'base_asset_type': 'native',
        'base_asset_code': null,
        'base_asset_issuer': null,
        'counter_account': null,
        'counter_offer_id': null,
        'counter_amount': '200.0',
        'counter_asset_type': 'native',
        'counter_asset_code': null,
        'counter_asset_issuer': null,
        'trade_type': 'liquidity_pool',
        'base_liquidity_pool_id': 'pool-id',
        'counter_liquidity_pool_id': null,
        'liquidity_pool_fee_bp': 30,
        'price': {'n': 2, 'd': 1},
        '_links': {
          'base': {'href': 'https://example.com'},
          'counter': {'href': 'https://example.com'},
          'operation': {'href': 'https://example.com'}
        }
      };

      final response = TradeResponse.fromJson(json);

      expect(response.baseAccount, isNull);
      expect(response.counterAccount, isNull);
    });

    test('parses links correctly', () {
      final json = {
        'id': '123-0',
        'paging_token': '123-0',
        'ledger_close_time': '2023-08-15T10:30:45Z',
        'offer_id': null,
        'base_is_seller': true,
        'base_account': 'GABC',
        'base_offer_id': '123',
        'base_amount': '100.0',
        'base_asset_type': 'native',
        'base_asset_code': null,
        'base_asset_issuer': null,
        'counter_account': 'GDEF',
        'counter_offer_id': '456',
        'counter_amount': '200.0',
        'counter_asset_type': 'native',
        'counter_asset_code': null,
        'counter_asset_issuer': null,
        'trade_type': 'orderbook',
        'base_liquidity_pool_id': null,
        'counter_liquidity_pool_id': null,
        'liquidity_pool_fee_bp': null,
        'price': {'n': 1, 'd': 1},
        '_links': {
          'base': {'href': 'https://horizon.stellar.org/accounts/GABC'},
          'counter': {'href': 'https://horizon.stellar.org/accounts/GDEF'},
          'operation': {'href': 'https://horizon.stellar.org/operations/123'}
        }
      };

      final response = TradeResponse.fromJson(json);

      expect(response.links.base.href, equals('https://horizon.stellar.org/accounts/GABC'));
      expect(response.links.counter.href, equals('https://horizon.stellar.org/accounts/GDEF'));
      expect(response.links.operation.href, equals('https://horizon.stellar.org/operations/123'));
    });

    test('handles null liquidity pool fee for orderbook trade', () {
      final json = {
        'id': '123-0',
        'paging_token': '123-0',
        'ledger_close_time': '2023-08-15T10:30:45Z',
        'offer_id': '789',
        'base_is_seller': true,
        'base_account': 'GABC',
        'base_offer_id': '123',
        'base_amount': '100.0',
        'base_asset_type': 'native',
        'base_asset_code': null,
        'base_asset_issuer': null,
        'counter_account': 'GDEF',
        'counter_offer_id': '456',
        'counter_amount': '200.0',
        'counter_asset_type': 'native',
        'counter_asset_code': null,
        'counter_asset_issuer': null,
        'trade_type': 'orderbook',
        'base_liquidity_pool_id': null,
        'counter_liquidity_pool_id': null,
        'liquidity_pool_fee_bp': null,
        'price': {'n': 1, 'd': 1},
        '_links': {
          'base': {'href': 'https://example.com'},
          'counter': {'href': 'https://example.com'},
          'operation': {'href': 'https://example.com'}
        }
      };

      final response = TradeResponse.fromJson(json);

      expect(response.liquidityPoolFeeBp, isNull);
    });
  });

  group('TradeResponseLinks', () {
    test('parses all links correctly', () {
      final json = {
        'base': {'href': 'https://horizon.stellar.org/accounts/GABC'},
        'counter': {'href': 'https://horizon.stellar.org/accounts/GDEF'},
        'operation': {'href': 'https://horizon.stellar.org/operations/123456'}
      };

      final links = TradeResponseLinks.fromJson(json);

      expect(links.base.href, equals('https://horizon.stellar.org/accounts/GABC'));
      expect(links.counter.href, equals('https://horizon.stellar.org/accounts/GDEF'));
      expect(links.operation.href, equals('https://horizon.stellar.org/operations/123456'));
    });
  });
}
