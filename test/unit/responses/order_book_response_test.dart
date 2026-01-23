import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('OrderBookResponse', () {
    test('parses JSON with all fields correctly', () {
      final json = {
        'base': {
          'asset_type': 'credit_alphanum4',
          'asset_code': 'USDC',
          'asset_issuer': 'GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5'
        },
        'counter': {
          'asset_type': 'native'
        },
        'asks': [
          {
            'amount': '100.0000000',
            'price': '2.5000000',
            'price_r': {'n': 5, 'd': 2}
          },
          {
            'amount': '200.0000000',
            'price': '2.6000000',
            'price_r': {'n': 13, 'd': 5}
          }
        ],
        'bids': [
          {
            'amount': '150.0000000',
            'price': '2.4000000',
            'price_r': {'n': 12, 'd': 5}
          },
          {
            'amount': '250.0000000',
            'price': '2.3000000',
            'price_r': {'n': 23, 'd': 10}
          }
        ]
      };

      final response = OrderBookResponse.fromJson(json);

      expect(response.base, isA<AssetTypeCreditAlphaNum4>());
      expect(response.counter, isA<AssetTypeNative>());
      expect(response.asks.length, equals(2));
      expect(response.bids.length, equals(2));
    });

    test('parses base asset correctly', () {
      final json = {
        'base': {
          'asset_type': 'credit_alphanum12',
          'asset_code': 'LONGERCODE',
          'asset_issuer': 'GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5'
        },
        'counter': {'asset_type': 'native'},
        'asks': [],
        'bids': []
      };

      final response = OrderBookResponse.fromJson(json);

      expect(response.base, isA<AssetTypeCreditAlphaNum12>());
      expect((response.base as AssetTypeCreditAlphaNum12).code, equals('LONGERCODE'));
    });

    test('parses counter asset correctly', () {
      final json = {
        'base': {'asset_type': 'native'},
        'counter': {
          'asset_type': 'credit_alphanum4',
          'asset_code': 'USD',
          'asset_issuer': 'GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5'
        },
        'asks': [],
        'bids': []
      };

      final response = OrderBookResponse.fromJson(json);

      expect(response.counter, isA<AssetTypeCreditAlphaNum4>());
      expect((response.counter as AssetTypeCreditAlphaNum4).code, equals('USD'));
    });

    test('parses asks correctly', () {
      final json = {
        'base': {'asset_type': 'native'},
        'counter': {'asset_type': 'native'},
        'asks': [
          {
            'amount': '100.0',
            'price': '2.5',
            'price_r': {'n': 5, 'd': 2}
          },
          {
            'amount': '200.0',
            'price': '2.6',
            'price_r': {'n': 13, 'd': 5}
          },
          {
            'amount': '300.0',
            'price': '2.7',
            'price_r': {'n': 27, 'd': 10}
          }
        ],
        'bids': []
      };

      final response = OrderBookResponse.fromJson(json);

      expect(response.asks.length, equals(3));
      expect(response.asks[0].amount, equals('100.0'));
      expect(response.asks[0].price, equals('2.5'));
      expect(response.asks[1].amount, equals('200.0'));
      expect(response.asks[2].amount, equals('300.0'));
    });

    test('parses bids correctly', () {
      final json = {
        'base': {'asset_type': 'native'},
        'counter': {'asset_type': 'native'},
        'asks': [],
        'bids': [
          {
            'amount': '150.0',
            'price': '2.4',
            'price_r': {'n': 12, 'd': 5}
          },
          {
            'amount': '250.0',
            'price': '2.3',
            'price_r': {'n': 23, 'd': 10}
          }
        ]
      };

      final response = OrderBookResponse.fromJson(json);

      expect(response.bids.length, equals(2));
      expect(response.bids[0].amount, equals('150.0'));
      expect(response.bids[0].price, equals('2.4'));
      expect(response.bids[1].amount, equals('250.0'));
    });

    test('handles empty order book', () {
      final json = {
        'base': {'asset_type': 'native'},
        'counter': {'asset_type': 'native'},
        'asks': [],
        'bids': []
      };

      final response = OrderBookResponse.fromJson(json);

      expect(response.asks.length, equals(0));
      expect(response.bids.length, equals(0));
    });

    test('parses native asset pairs correctly', () {
      final json = {
        'base': {'asset_type': 'native'},
        'counter': {'asset_type': 'native'},
        'asks': [],
        'bids': []
      };

      final response = OrderBookResponse.fromJson(json);

      expect(response.base, isA<AssetTypeNative>());
      expect(response.counter, isA<AssetTypeNative>());
    });
  });

  group('OrderBookRow', () {
    test('parses JSON correctly', () {
      final json = {
        'amount': '100.0000000',
        'price': '2.5000000',
        'price_r': {'n': 5, 'd': 2}
      };

      final row = OrderBookRow.fromJson(json);

      expect(row.amount, equals('100.0000000'));
      expect(row.price, equals('2.5000000'));
      expect(row.priceR.n, equals(5));
      expect(row.priceR.d, equals(2));
    });

    test('parses price ratio correctly', () {
      final json = {
        'amount': '500.0',
        'price': '1.5',
        'price_r': {'n': 3, 'd': 2}
      };

      final row = OrderBookRow.fromJson(json);

      expect(row.priceR.n, equals(3));
      expect(row.priceR.d, equals(2));
    });

    test('handles large amounts', () {
      final json = {
        'amount': '9999999.9999999',
        'price': '0.0001',
        'price_r': {'n': 1, 'd': 10000}
      };

      final row = OrderBookRow.fromJson(json);

      expect(row.amount, equals('9999999.9999999'));
      expect(row.price, equals('0.0001'));
    });

    test('handles small prices', () {
      final json = {
        'amount': '100.0',
        'price': '0.0000001',
        'price_r': {'n': 1, 'd': 10000000}
      };

      final row = OrderBookRow.fromJson(json);

      expect(row.price, equals('0.0000001'));
      expect(row.priceR.n, equals(1));
      expect(row.priceR.d, equals(10000000));
    });

    test('handles large prices', () {
      final json = {
        'amount': '1.0',
        'price': '10000.0',
        'price_r': {'n': 10000, 'd': 1}
      };

      final row = OrderBookRow.fromJson(json);

      expect(row.price, equals('10000.0'));
      expect(row.priceR.n, equals(10000));
      expect(row.priceR.d, equals(1));
    });
  });
}
