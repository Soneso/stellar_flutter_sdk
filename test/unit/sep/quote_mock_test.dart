import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:convert';

void main() {
  group('SEP38QuoteService Info Endpoint', () {
    test('get info with supported assets and delivery methods', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/info'));
        expect(request.headers['Content-Type'], 'application/json');

        return http.Response(json.encode({
          'assets': [
            {
              'asset': 'stellar:USDC:GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5',
              'sell_delivery_methods': [
                {
                  'name': 'WIRE',
                  'description': 'Wire transfer'
                },
                {
                  'name': 'ACH',
                  'description': 'ACH bank transfer'
                }
              ],
              'buy_delivery_methods': [
                {
                  'name': 'WIRE',
                  'description': 'Wire transfer'
                }
              ],
              'country_codes': ['USA', 'CAN']
            },
            {
              'asset': 'iso4217:USD',
              'sell_delivery_methods': [
                {
                  'name': 'WIRE',
                  'description': 'Wire transfer'
                }
              ]
            },
            {
              'asset': 'stellar:BTC:GDXTJEK4JZNSTNQAWA53RZNS2GIKTDRPEUWDXELFMKU52XNECNVDVXDI'
            }
          ]
        }), 200);
      });

      final service = SEP38QuoteService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final response = await service.info();

      expect(response.assets.length, 3);

      final usdc = response.assets[0];
      expect(usdc.asset, 'stellar:USDC:GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5');
      expect(usdc.sellDeliveryMethods, isNotNull);
      expect(usdc.sellDeliveryMethods!.length, 2);
      expect(usdc.sellDeliveryMethods![0].name, 'WIRE');
      expect(usdc.sellDeliveryMethods![0].description, 'Wire transfer');
      expect(usdc.sellDeliveryMethods![1].name, 'ACH');
      expect(usdc.buyDeliveryMethods, isNotNull);
      expect(usdc.buyDeliveryMethods!.length, 1);
      expect(usdc.countryCodes, ['USA', 'CAN']);

      final usd = response.assets[1];
      expect(usd.asset, 'iso4217:USD');
      expect(usd.sellDeliveryMethods, isNotNull);
      expect(usd.buyDeliveryMethods, isNull);

      final btc = response.assets[2];
      expect(btc.asset, contains('BTC'));
      expect(btc.sellDeliveryMethods, isNull);
    });

    test('get info with JWT authentication', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/info'));
        expect(request.headers['Authorization'], 'Bearer test-jwt');

        return http.Response(json.encode({
          'assets': []
        }), 200);
      });

      final service = SEP38QuoteService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      await service.info(jwtToken: 'test-jwt');
    });
  });

  group('SEP38QuoteService Prices Endpoint', () {
    test('get indicative prices for sell asset', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/prices'));
        expect(request.url.queryParameters['sell_asset'], 'iso4217:USD');
        expect(request.url.queryParameters['sell_amount'], '100');

        return http.Response(json.encode({
          'buy_assets': [
            {
              'asset': 'stellar:USDC:GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5',
              'price': '0.99',
              'decimals': 7
            },
            {
              'asset': 'stellar:BTC:GDXTJEK4JZNSTNQAWA53RZNS2GIKTDRPEUWDXELFMKU52XNECNVDVXDI',
              'price': '0.0000235',
              'decimals': 7
            }
          ]
        }), 200);
      });

      final service = SEP38QuoteService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final response = await service.prices(
        sellAsset: 'iso4217:USD',
        sellAmount: '100',
      );

      expect(response.buyAssets.length, 2);

      final usdc = response.buyAssets[0];
      expect(usdc.asset, contains('USDC'));
      expect(usdc.price, '0.99');
      expect(usdc.decimals, 7);

      final btc = response.buyAssets[1];
      expect(btc.asset, contains('BTC'));
      expect(btc.price, '0.0000235');
      expect(btc.decimals, 7);
    });

    test('get prices with delivery methods and country code', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/prices'));
        expect(request.url.queryParameters['sell_asset'], 'iso4217:USD');
        expect(request.url.queryParameters['sell_amount'], '500');
        expect(request.url.queryParameters['sell_delivery_method'], 'WIRE');
        expect(request.url.queryParameters['buy_delivery_method'], 'ACH');
        expect(request.url.queryParameters['country_code'], 'USA');

        return http.Response(json.encode({
          'buy_assets': []
        }), 200);
      });

      final service = SEP38QuoteService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      await service.prices(
        sellAsset: 'iso4217:USD',
        sellAmount: '500',
        sellDeliveryMethod: 'WIRE',
        buyDeliveryMethod: 'ACH',
        countryCode: 'USA',
      );
    });

    test('get prices with JWT token', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/prices'));
        expect(request.headers['Authorization'], 'Bearer test-jwt');

        return http.Response(json.encode({
          'buy_assets': []
        }), 200);
      });

      final service = SEP38QuoteService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      await service.prices(
        sellAsset: 'iso4217:USD',
        sellAmount: '100',
        jwtToken: 'test-jwt',
      );
    });
  });

  group('SEP38QuoteService Price Endpoint', () {
    test('get indicative price with sell amount', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/price'));
        expect(request.url.queryParameters['context'], 'sep6');
        expect(request.url.queryParameters['sell_asset'], 'iso4217:USD');
        expect(request.url.queryParameters['buy_asset'], 'stellar:USDC:GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5');
        expect(request.url.queryParameters['sell_amount'], '100');

        return http.Response(json.encode({
          'total_price': '1.01',
          'price': '1.00',
          'sell_amount': '100.00',
          'buy_amount': '99.00',
          'fee': {
            'total': '1.00',
            'asset': 'iso4217:USD',
            'details': [
              {
                'name': 'Service fee',
                'amount': '0.75',
                'description': 'Processing fee'
              },
              {
                'name': 'Network fee',
                'amount': '0.25',
                'description': 'Blockchain fee'
              }
            ]
          }
        }), 200);
      });

      final service = SEP38QuoteService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final response = await service.price(
        context: 'sep6',
        sellAsset: 'iso4217:USD',
        buyAsset: 'stellar:USDC:GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5',
        sellAmount: '100',
      );

      expect(response.totalPrice, '1.01');
      expect(response.price, '1.00');
      expect(response.sellAmount, '100.00');
      expect(response.buyAmount, '99.00');
      expect(response.fee.total, '1.00');
      expect(response.fee.asset, 'iso4217:USD');
      expect(response.fee.details, isNotNull);
      expect(response.fee.details!.length, 2);
      expect(response.fee.details![0].name, 'Service fee');
      expect(response.fee.details![0].amount, '0.75');
      expect(response.fee.details![0].description, 'Processing fee');
    });

    test('get indicative price with buy amount', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/price'));
        expect(request.url.queryParameters['context'], 'sep31');
        expect(request.url.queryParameters['sell_asset'], 'stellar:USDC:GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5');
        expect(request.url.queryParameters['buy_asset'], 'iso4217:USD');
        expect(request.url.queryParameters['buy_amount'], '200');

        return http.Response(json.encode({
          'total_price': '1.02',
          'price': '1.00',
          'sell_amount': '204.00',
          'buy_amount': '200.00',
          'fee': {
            'total': '4.00',
            'asset': 'stellar:USDC:GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5'
          }
        }), 200);
      });

      final service = SEP38QuoteService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final response = await service.price(
        context: 'sep31',
        sellAsset: 'stellar:USDC:GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5',
        buyAsset: 'iso4217:USD',
        buyAmount: '200',
      );

      expect(response.totalPrice, '1.02');
      expect(response.sellAmount, '204.00');
      expect(response.buyAmount, '200.00');
      expect(response.fee.total, '4.00');
    });

    test('get price with delivery methods and country code', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/price'));
        expect(request.url.queryParameters['sell_delivery_method'], 'WIRE');
        expect(request.url.queryParameters['buy_delivery_method'], 'ACH');
        expect(request.url.queryParameters['country_code'], 'CAN');

        return http.Response(json.encode({
          'total_price': '1.00',
          'price': '1.00',
          'sell_amount': '50.00',
          'buy_amount': '50.00',
          'fee': {
            'total': '0.00',
            'asset': 'iso4217:USD'
          }
        }), 200);
      });

      final service = SEP38QuoteService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      await service.price(
        context: 'sep6',
        sellAsset: 'iso4217:USD',
        buyAsset: 'iso4217:CAD',
        sellAmount: '50',
        sellDeliveryMethod: 'WIRE',
        buyDeliveryMethod: 'ACH',
        countryCode: 'CAN',
      );
    });
  });

  group('SEP38QuoteService POST Quote Endpoint', () {
    test('create firm quote with sell amount', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/quote'));
        expect(request.method, 'POST');
        expect(request.headers['Authorization'], 'Bearer test-jwt');
        expect(request.headers['Content-Type'], 'application/json');

        final body = json.decode(request.body);
        expect(body['context'], 'sep6');
        expect(body['sell_asset'], 'iso4217:USD');
        expect(body['buy_asset'], 'stellar:USDC:GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5');
        expect(body['sell_amount'], '100');

        return http.Response(json.encode({
          'id': 'quote-123',
          'expires_at': '2025-10-05T12:30:00Z',
          'total_price': '1.01',
          'price': '1.00',
          'sell_asset': 'iso4217:USD',
          'sell_amount': '100.00',
          'buy_asset': 'stellar:USDC:GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5',
          'buy_amount': '99.00',
          'fee': {
            'total': '1.00',
            'asset': 'iso4217:USD'
          }
        }), 201);
      });

      final service = SEP38QuoteService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = SEP38PostQuoteRequest(
        context: 'sep6',
        sellAsset: 'iso4217:USD',
        buyAsset: 'stellar:USDC:GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5',
        sellAmount: '100',
      );

      final response = await service.postQuote(request, 'test-jwt');

      expect(response.id, 'quote-123');
      expect(response.expiresAt, isA<DateTime>());
      expect(response.totalPrice, '1.01');
      expect(response.price, '1.00');
      expect(response.sellAsset, 'iso4217:USD');
      expect(response.sellAmount, '100.00');
      expect(response.buyAsset, contains('USDC'));
      expect(response.buyAmount, '99.00');
      expect(response.fee.total, '1.00');
      expect(response.fee.asset, 'iso4217:USD');
    });

    test('create firm quote with buy amount', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/quote'));
        expect(request.method, 'POST');

        final body = json.decode(request.body);
        expect(body['buy_amount'], '250');

        return http.Response(json.encode({
          'id': 'quote-456',
          'expires_at': '2025-10-05T13:00:00Z',
          'total_price': '1.02',
          'price': '1.00',
          'sell_asset': 'stellar:USDC:GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5',
          'sell_amount': '255.00',
          'buy_asset': 'iso4217:USD',
          'buy_amount': '250.00',
          'fee': {
            'total': '5.00',
            'asset': 'stellar:USDC:GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5'
          }
        }), 200);
      });

      final service = SEP38QuoteService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = SEP38PostQuoteRequest(
        context: 'sep31',
        sellAsset: 'stellar:USDC:GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5',
        buyAsset: 'iso4217:USD',
        buyAmount: '250',
      );

      final response = await service.postQuote(request, 'test-jwt');

      expect(response.id, 'quote-456');
      expect(response.sellAmount, '255.00');
      expect(response.buyAmount, '250.00');
    });

    test('create firm quote with expiration', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/quote'));

        final body = json.decode(request.body);
        expect(body['expire_after'], isNotNull);

        return http.Response(json.encode({
          'id': 'quote-789',
          'expires_at': '2025-10-05T14:00:00Z',
          'total_price': '1.00',
          'price': '1.00',
          'sell_asset': 'iso4217:USD',
          'sell_amount': '50.00',
          'buy_asset': 'stellar:USDC:GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5',
          'buy_amount': '50.00',
          'fee': {
            'total': '0.00',
            'asset': 'iso4217:USD'
          }
        }), 201);
      });

      final service = SEP38QuoteService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = SEP38PostQuoteRequest(
        context: 'sep6',
        sellAsset: 'iso4217:USD',
        buyAsset: 'stellar:USDC:GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5',
        sellAmount: '50',
        expireAfter: DateTime.now().add(Duration(minutes: 5)),
      );

      final response = await service.postQuote(request, 'test-jwt');

      expect(response.id, 'quote-789');
    });

    test('create firm quote with delivery methods and country code', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/quote'));

        final body = json.decode(request.body);
        expect(body['sell_delivery_method'], 'WIRE');
        expect(body['buy_delivery_method'], 'ACH');
        expect(body['country_code'], 'USA');

        return http.Response(json.encode({
          'id': 'quote-999',
          'expires_at': '2025-10-05T15:00:00Z',
          'total_price': '1.00',
          'price': '1.00',
          'sell_asset': 'iso4217:USD',
          'sell_amount': '75.00',
          'buy_asset': 'stellar:USDC:GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5',
          'buy_amount': '75.00',
          'fee': {
            'total': '0.00',
            'asset': 'iso4217:USD'
          }
        }), 201);
      });

      final service = SEP38QuoteService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = SEP38PostQuoteRequest(
        context: 'sep6',
        sellAsset: 'iso4217:USD',
        buyAsset: 'stellar:USDC:GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5',
        sellAmount: '75',
        sellDeliveryMethod: 'WIRE',
        buyDeliveryMethod: 'ACH',
        countryCode: 'USA',
      );

      await service.postQuote(request, 'test-jwt');
    });
  });

  group('SEP38QuoteService GET Quote Endpoint', () {
    test('retrieve firm quote by id', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/quote/quote-123'));
        expect(request.headers['Authorization'], 'Bearer test-jwt');

        return http.Response(json.encode({
          'id': 'quote-123',
          'expires_at': '2025-10-05T12:30:00Z',
          'total_price': '1.01',
          'price': '1.00',
          'sell_asset': 'iso4217:USD',
          'sell_amount': '100.00',
          'buy_asset': 'stellar:USDC:GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5',
          'buy_amount': '99.00',
          'fee': {
            'total': '1.00',
            'asset': 'iso4217:USD',
            'details': [
              {
                'name': 'Processing',
                'amount': '1.00'
              }
            ]
          }
        }), 200);
      });

      final service = SEP38QuoteService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final response = await service.getQuote('quote-123', 'test-jwt');

      expect(response.id, 'quote-123');
      expect(response.expiresAt, isA<DateTime>());
      expect(response.totalPrice, '1.01');
      expect(response.price, '1.00');
      expect(response.sellAsset, 'iso4217:USD');
      expect(response.sellAmount, '100.00');
      expect(response.buyAmount, '99.00');
      expect(response.fee.total, '1.00');
      expect(response.fee.details, isNotNull);
      expect(response.fee.details!.length, 1);
    });

    test('retrieve quote with detailed fee breakdown', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/quote/quote-456'));

        return http.Response(json.encode({
          'id': 'quote-456',
          'expires_at': '2025-10-05T13:00:00Z',
          'total_price': '1.05',
          'price': '1.00',
          'sell_asset': 'stellar:USDC:GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5',
          'sell_amount': '105.00',
          'buy_asset': 'iso4217:USD',
          'buy_amount': '100.00',
          'fee': {
            'total': '5.00',
            'asset': 'stellar:USDC:GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5',
            'details': [
              {
                'name': 'Service fee',
                'amount': '3.00',
                'description': 'Anchor processing fee'
              },
              {
                'name': 'Network fee',
                'amount': '2.00',
                'description': 'Stellar network fee'
              }
            ]
          }
        }), 200);
      });

      final service = SEP38QuoteService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final response = await service.getQuote('quote-456', 'test-jwt');

      expect(response.id, 'quote-456');
      expect(response.fee.total, '5.00');
      expect(response.fee.details!.length, 2);
      expect(response.fee.details![0].name, 'Service fee');
      expect(response.fee.details![0].amount, '3.00');
      expect(response.fee.details![0].description, 'Anchor processing fee');
    });
  });

  group('SEP38QuoteService Error Handling', () {
    test('handle 400 bad request error from info endpoint', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'error': 'Invalid request'
        }), 400);
      });

      final service = SEP38QuoteService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      expect(
        () => service.info(),
        throwsA(isA<SEP38BadRequest>()),
      );
    });

    test('handle 400 bad request from price endpoint', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'error': 'Both sell_amount and buy_amount provided'
        }), 400);
      });

      final service = SEP38QuoteService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      expect(
        () => service.price(
          context: 'sep6',
          sellAsset: 'iso4217:USD',
          buyAsset: 'stellar:USDC:G...',
          sellAmount: '100',
        ),
        throwsA(isA<SEP38BadRequest>()),
      );
    });

    test('handle 403 permission denied from postQuote', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'error': 'Invalid or expired JWT token'
        }), 403);
      });

      final service = SEP38QuoteService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = SEP38PostQuoteRequest(
        context: 'sep6',
        sellAsset: 'iso4217:USD',
        buyAsset: 'stellar:USDC:G...',
        sellAmount: '100',
      );

      expect(
        () => service.postQuote(request, 'invalid-jwt'),
        throwsA(isA<SEP38PermissionDenied>()),
      );
    });

    test('handle 404 not found from getQuote', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'error': 'Quote not found'
        }), 404);
      });

      final service = SEP38QuoteService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      expect(
        () => service.getQuote('nonexistent-quote', 'test-jwt'),
        throwsA(isA<SEP38NotFound>()),
      );
    });

    test('verify custom headers are passed', () async {
      final mockClient = MockClient((request) async {
        expect(request.headers['X-Custom-Header'], 'custom-value');

        return http.Response(json.encode({
          'assets': []
        }), 200);
      });

      final service = SEP38QuoteService(
        'https://api.example.com',
        httpClient: mockClient,
        httpRequestHeaders: {
          'X-Custom-Header': 'custom-value',
        },
      );

      await service.info();
    });
  });
}
