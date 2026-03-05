@Timeout(const Duration(seconds: 300))

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  final quoteServer = 'http://api.stellar.org/quote';

  final String jwtToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJHQTZVSVhYUEVXWUZJTE5VSVdBQzM3WTRRUEVaTVFWREpIREtWV0ZaSjJLQ1dVQklVNUlYWk5EQSIsImp0aSI6IjE0NGQzNjdiY2IwZTcyY2FiZmRiZGU2MGVhZTBhZDczM2NjNjVkMmE2NTg3MDgzZGFiM2Q2MTZmODg1MTkwMjQiLCJpc3MiOiJodHRwczovL2ZsYXBweS1iaXJkLWRhcHAuZmlyZWJhc2VhcHAuY29tLyIsImlhdCI6MTUzNDI1Nzk5NCwiZXhwIjoxNTM0MzQ0Mzk0fQ.8nbB83Z6vGBgC1X9r3N6oQCFTBzDiITAfCJasRft0z0';

  final usdcAsset =
      'stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN';

  // --- Mock response JSON builders ---

  String infoResponseJson() {
    return json.encode({
      'assets': [
        {'asset': usdcAsset},
        {
          'asset':
              'stellar:BRL:GDVKY2GU2DRXWTBEYJJWSFXIGBZV6AZNBVVSUHEPZI54LIS6BA7DVVSP'
        },
        {
          'asset': 'iso4217:BRL',
          'country_codes': ['BRA'],
          'sell_delivery_methods': [
            {
              'name': 'cash',
              'description':
                  'Deposit cash BRL at one of our agent locations.'
            },
            {
              'name': 'ACH',
              'description':
                  "Send BRL directly to the Anchor's bank account."
            },
            {
              'name': 'PIX',
              'description':
                  "Send BRL directly to the Anchor's bank account."
            }
          ],
          'buy_delivery_methods': [
            {
              'name': 'cash',
              'description':
                  'Pick up cash BRL at one of our payout locations.'
            },
            {
              'name': 'ACH',
              'description':
                  'Have BRL sent directly to your bank account.'
            },
            {
              'name': 'PIX',
              'description':
                  'Have BRL sent directly to the account of your choice.'
            }
          ]
        }
      ]
    });
  }

  String pricesResponseJson() {
    return json.encode({
      'buy_assets': [
        {'asset': 'iso4217:BRL', 'price': '0.18', 'decimals': 2}
      ]
    });
  }

  String priceResponseSellBrl500Json() {
    return json.encode({
      'total_price': '5.42',
      'price': '5.00',
      'sell_amount': '542',
      'buy_amount': '100',
      'fee': {'total': '42.00', 'asset': 'iso4217:BRL'}
    });
  }

  String priceResponseBuyUsdc100Json() {
    return json.encode({
      'total_price': '5.42',
      'price': '5.00',
      'sell_amount': '542',
      'buy_amount': '100',
      'fee': {
        'total': '8.40',
        'asset': usdcAsset,
        'details': [
          {'name': 'Service fee', 'amount': '8.40'}
        ]
      }
    });
  }

  String priceResponseSellUsdc90Json() {
    return json.encode({
      'total_price': '0.20',
      'price': '0.18',
      'sell_amount': '100',
      'buy_amount': '500',
      'fee': {
        'total': '55.5556',
        'asset': 'iso4217:BRL',
        'details': [
          {
            'name': 'PIX fee',
            'description':
                'Fee charged in order to process the outgoing PIX transaction.',
            'amount': '55.5556'
          }
        ]
      }
    });
  }

  String priceResponseBuyBrl500Json() {
    return json.encode({
      'total_price': '0.20',
      'price': '0.18',
      'sell_amount': '100',
      'buy_amount': '500',
      'fee': {
        'total': '10.00',
        'asset': usdcAsset,
        'details': [
          {'name': 'Service fee', 'amount': '5.00'},
          {
            'name': 'PIX fee',
            'description':
                'Fee charged in order to process the outgoing BRL PIX transaction.',
            'amount': '5.00'
          }
        ]
      }
    });
  }

  String firmQuoteResponseJson() {
    return json.encode({
      'id': 'de762cda-a193-4961-861e-57b31fed6eb3',
      'expires_at': '2024-02-01T10:40:14+0000',
      'total_price': '5.42',
      'price': '5.00',
      'sell_asset': 'iso4217:BRL',
      'sell_amount': '542',
      'buy_asset': usdcAsset,
      'buy_amount': '100',
      'fee': {
        'total': '8.40',
        'asset': usdcAsset,
        'details': [
          {'name': 'Service fee', 'amount': '8.40'}
        ]
      }
    });
  }

  // --- Tests corresponding to doc snippets ---

  test('sep-38: Quick example - info and prices', () async {
    // Snippet from sep-38.md "Quick example"
    final service = SEP38QuoteService(quoteServer);
    int callCount = 0;

    service.httpClient = MockClient((request) async {
      if (request.url.toString().contains('info')) {
        callCount++;
        return http.Response(infoResponseJson(), 200);
      }
      if (request.url.toString().contains('prices')) {
        callCount++;
        return http.Response(pricesResponseJson(), 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    // Get available assets for trading
    SEP38InfoResponse info = await service.info();
    expect(info.assets.length, 3);
    expect(info.assets[0].asset, usdcAsset);

    // Get indicative prices for selling 100 USD
    SEP38PricesResponse prices = await service.prices(
      sellAsset: 'iso4217:USD',
      sellAmount: '100',
    );

    expect(prices.buyAssets.length, 1);
    expect(prices.buyAssets[0].asset, 'iso4217:BRL');
    expect(prices.buyAssets[0].price, '0.18');
    expect(callCount, 2);
  });

  test('sep-38: Creating the service with direct URL', () {
    // Snippet from sep-38.md "With a direct URL"
    SEP38QuoteService quoteService =
        SEP38QuoteService('https://anchor.example.com/sep38');
    expect(quoteService, isNotNull);
  });

  test('sep-38: Getting available assets (GET /info)', () async {
    // Snippet from sep-38.md "Getting available assets (GET /info)"
    final service = SEP38QuoteService(quoteServer);

    service.httpClient = MockClient((request) async {
      if (request.url.toString().contains('info')) {
        String? authHeader = request.headers['Authorization'];
        if (authHeader != null && authHeader.contains(jwtToken)) {
          return http.Response(infoResponseJson(), 200);
        }
        // Also allow unauthenticated
        return http.Response(infoResponseJson(), 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    SEP38InfoResponse info = await service.info(jwtToken: jwtToken);

    List<SEP38Asset> assets = info.assets;
    expect(assets.length, 3);
    expect(assets[0].asset, usdcAsset);
    expect(assets[2].asset, 'iso4217:BRL');

    // Check country restrictions for fiat assets
    expect(assets[2].countryCodes, isNotNull);
    expect(assets[2].countryCodes!.length, 1);
    expect(assets[2].countryCodes![0], 'BRA');

    // Check sell delivery methods
    expect(assets[2].sellDeliveryMethods, isNotNull);
    expect(assets[2].sellDeliveryMethods!.length, 3);
    expect(assets[2].sellDeliveryMethods![0].name, 'cash');
    expect(assets[2].sellDeliveryMethods![0].description,
        'Deposit cash BRL at one of our agent locations.');
    expect(assets[2].sellDeliveryMethods![1].name, 'ACH');
    expect(assets[2].sellDeliveryMethods![2].name, 'PIX');

    // Check buy delivery methods
    expect(assets[2].buyDeliveryMethods, isNotNull);
    expect(assets[2].buyDeliveryMethods!.length, 3);
    expect(assets[2].buyDeliveryMethods![0].name, 'cash');
    expect(assets[2].buyDeliveryMethods![0].description,
        'Pick up cash BRL at one of our payout locations.');
    expect(assets[2].buyDeliveryMethods![1].name, 'ACH');
    expect(assets[2].buyDeliveryMethods![2].name, 'PIX');
  });

  test('sep-38: Getting indicative prices (GET /prices)', () async {
    // Snippet from sep-38.md "Getting indicative prices (GET /prices)"
    final service = SEP38QuoteService(quoteServer);

    service.httpClient = MockClient((request) async {
      if (request.url.toString().contains('prices')) {
        return http.Response(pricesResponseJson(), 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    // Basic prices request
    SEP38PricesResponse prices = await service.prices(
      sellAsset: 'iso4217:USD',
      sellAmount: '100',
    );

    expect(prices.buyAssets.length, 1);
    expect(prices.buyAssets[0].asset, 'iso4217:BRL');
    expect(prices.buyAssets[0].price, '0.18');
    expect(prices.buyAssets[0].decimals, 2);
  });

  test('sep-38: Prices with delivery method and country code', () async {
    // Snippet from sep-38.md "With delivery method and country code"
    final service = SEP38QuoteService(quoteServer);

    service.httpClient = MockClient((request) async {
      if (request.url.toString().contains('prices') &&
          request.url.queryParameters['sell_delivery_method'] == 'PIX' &&
          request.url.queryParameters['country_code'] == 'BRA') {
        return http.Response(pricesResponseJson(), 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    SEP38PricesResponse prices = await service.prices(
      sellAsset: 'iso4217:BRL',
      sellAmount: '500',
      sellDeliveryMethod: 'PIX',
      countryCode: 'BRA',
      jwtToken: jwtToken,
    );

    expect(prices.buyAssets.length, 1);
    expect(prices.buyAssets[0].asset, 'iso4217:BRL');
    expect(prices.buyAssets[0].price, '0.18');
  });

  test('sep-38: Getting a price for a specific pair (GET /price)', () async {
    // Snippet from sep-38.md "Getting a price for a specific pair"
    final service = SEP38QuoteService(quoteServer);

    service.httpClient = MockClient((request) async {
      if (request.url.toString().contains('price?') ||
          request.url.toString().contains('price&')) {
        var params = request.url.queryParameters;
        if (params['sell_asset'] == 'iso4217:BRL' &&
            params['sell_amount'] == '500') {
          return http.Response(priceResponseSellBrl500Json(), 200);
        }
        if (params['sell_asset'] == 'iso4217:BRL' &&
            params['buy_amount'] == '100') {
          return http.Response(priceResponseBuyUsdc100Json(), 200);
        }
        if (params['sell_asset'] == usdcAsset &&
            params['sell_amount'] == '90') {
          return http.Response(priceResponseSellUsdc90Json(), 200);
        }
        if (params['sell_asset'] == usdcAsset &&
            params['buy_amount'] == '500') {
          return http.Response(priceResponseBuyBrl500Json(), 200);
        }
        // Fallback for sell_asset=iso4217:USD, sellAmount=100
        if (params['sell_asset'] == 'iso4217:USD' &&
            params['sell_amount'] == '100') {
          return http.Response(priceResponseSellBrl500Json(), 200);
        }
        // Fallback for buyAmount=50
        if (params['buy_amount'] == '50') {
          return http.Response(priceResponseSellBrl500Json(), 200);
        }
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    // How much USDC do I get for 100 USD? (SEP-6 deposit context)
    SEP38PriceResponse price = await service.price(
      context: 'sep6',
      sellAsset: 'iso4217:USD',
      buyAsset: usdcAsset,
      sellAmount: '100',
      jwtToken: jwtToken,
    );

    expect(price.totalPrice, '5.42');
    expect(price.price, '5.00');
    expect(price.sellAmount, '542');
    expect(price.buyAmount, '100');
    expect(price.fee.total, '42.00');
    expect(price.fee.asset, 'iso4217:BRL');

    // Query by buy amount
    price = await service.price(
      context: 'sep6',
      sellAsset: 'iso4217:USD',
      buyAsset: usdcAsset,
      buyAmount: '50',
      jwtToken: jwtToken,
    );

    expect(price.sellAmount, isNotNull);
    expect(price.buyAmount, isNotNull);
  });

  test('sep-38: Price with delivery methods (sep31 context)', () async {
    // Snippet from sep-38.md "With delivery methods" - uses context: "sep31"
    final service = SEP38QuoteService(quoteServer);

    service.httpClient = MockClient((request) async {
      if (request.url.toString().contains('price')) {
        var params = request.url.queryParameters;
        if (params['context'] == 'sep31' &&
            params['sell_delivery_method'] == 'PIX') {
          return http.Response(priceResponseSellBrl500Json(), 200);
        }
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    // BRL to USDC via PIX in Brazil, for SEP-31 cross-border payment
    SEP38PriceResponse price = await service.price(
      context: 'sep31',
      sellAsset: 'iso4217:BRL',
      buyAsset: usdcAsset,
      sellAmount: '500',
      sellDeliveryMethod: 'PIX',
      countryCode: 'BRA',
      jwtToken: jwtToken,
    );

    expect(price.totalPrice, '5.42');
    expect(price.price, '5.00');
  });

  test('sep-38: Working with fee details', () async {
    // Snippet from sep-38.md "Working with fee details"
    final service = SEP38QuoteService(quoteServer);

    service.httpClient = MockClient((request) async {
      if (request.url.toString().contains('price')) {
        return http.Response(priceResponseBuyBrl500Json(), 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    SEP38PriceResponse price = await service.price(
      context: 'sep6',
      sellAsset: 'iso4217:BRL',
      buyAsset: usdcAsset,
      sellAmount: '500',
      jwtToken: jwtToken,
    );

    expect(price.fee.total, '10.00');
    expect(price.fee.asset, usdcAsset);

    // Check for detailed fee breakdown
    expect(price.fee.details, isNotNull);
    expect(price.fee.details!.length, 2);
    expect(price.fee.details![0].name, 'Service fee');
    expect(price.fee.details![0].amount, '5.00');
    expect(price.fee.details![0].description, isNull);
    expect(price.fee.details![1].name, 'PIX fee');
    expect(price.fee.details![1].amount, '5.00');
    expect(price.fee.details![1].description,
        'Fee charged in order to process the outgoing BRL PIX transaction.');
  });

  test('sep-38: Requesting a firm quote (POST /quote)', () async {
    // Snippet from sep-38.md "Requesting a firm quote (POST /quote)"
    final service = SEP38QuoteService(quoteServer);

    service.httpClient = MockClient((request) async {
      if (request.method == 'POST' &&
          request.url.toString().contains('quote')) {
        String? authHeader = request.headers['Authorization'];
        if (authHeader != null && authHeader.contains(jwtToken)) {
          return http.Response(firmQuoteResponseJson(), 200);
        }
        return http.Response(json.encode({'error': 'Unauthorized'}), 403);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    // Build the quote request
    SEP38PostQuoteRequest request = SEP38PostQuoteRequest(
      context: 'sep6',
      sellAsset: 'iso4217:USD',
      buyAsset: usdcAsset,
      sellAmount: '100',
    );

    // Submit the request (JWT is required, positional parameter)
    SEP38QuoteResponse quote = await service.postQuote(request, jwtToken);

    expect(quote.id, 'de762cda-a193-4961-861e-57b31fed6eb3');
    expect(quote.expiresAt, DateTime.parse('2024-02-01T10:40:14+0000'));
    expect(quote.totalPrice, '5.42');
    expect(quote.price, '5.00');
    expect(quote.sellAsset, 'iso4217:BRL');
    expect(quote.sellAmount, '542');
    expect(quote.buyAsset, usdcAsset);
    expect(quote.buyAmount, '100');
    expect(quote.fee.total, '8.40');
    expect(quote.fee.asset, usdcAsset);
    expect(quote.fee.details, isNotNull);
    expect(quote.fee.details!.length, 1);
    expect(quote.fee.details![0].name, 'Service fee');
    expect(quote.fee.details![0].amount, '8.40');
  });

  test('sep-38: Firm quote with expiration preference', () async {
    // Snippet from sep-38.md "With expiration preference"
    final service = SEP38QuoteService(quoteServer);

    service.httpClient = MockClient((request) async {
      if (request.method == 'POST' &&
          request.url.toString().contains('quote')) {
        // Verify expire_after is in the request body
        var body = json.decode(request.body);
        expect(body['expire_after'], isNotNull);
        return http.Response(firmQuoteResponseJson(), 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    SEP38PostQuoteRequest request = SEP38PostQuoteRequest(
      context: 'sep6',
      sellAsset: 'iso4217:USD',
      buyAsset: usdcAsset,
      sellAmount: '100',
      expireAfter: DateTime.now().add(Duration(hours: 1)),
    );

    SEP38QuoteResponse quote = await service.postQuote(request, jwtToken);
    expect(quote.id, isNotNull);
    expect(quote.expiresAt, isNotNull);
  });

  test('sep-38: Firm quote with delivery methods', () async {
    // Snippet from sep-38.md "With delivery methods" (POST /quote)
    final service = SEP38QuoteService(quoteServer);

    service.httpClient = MockClient((request) async {
      if (request.method == 'POST' &&
          request.url.toString().contains('quote')) {
        var body = json.decode(request.body);
        expect(body['sell_delivery_method'], 'ACH');
        expect(body['country_code'], 'BRA');
        return http.Response(firmQuoteResponseJson(), 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    SEP38PostQuoteRequest request = SEP38PostQuoteRequest(
      context: 'sep6',
      sellAsset: 'iso4217:BRL',
      buyAsset: usdcAsset,
      sellAmount: '1000',
      sellDeliveryMethod: 'ACH',
      countryCode: 'BRA',
    );

    SEP38QuoteResponse quote = await service.postQuote(request, jwtToken);
    expect(quote.id, isNotNull);
  });

  test('sep-38: Retrieving a previous quote (GET /quote/:id)', () async {
    // Snippet from sep-38.md "Retrieving a previous quote"
    final service = SEP38QuoteService(quoteServer);

    service.httpClient = MockClient((request) async {
      if (request.method == 'GET' &&
          request.url
              .toString()
              .endsWith('quote/de762cda-a193-4961-861e-57b31fed6eb3')) {
        String? authHeader = request.headers['Authorization'];
        if (authHeader != null && authHeader.contains(jwtToken)) {
          return http.Response(firmQuoteResponseJson(), 200);
        }
        return http.Response(json.encode({'error': 'Unauthorized'}), 403);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    String quoteId = 'de762cda-a193-4961-861e-57b31fed6eb3';
    SEP38QuoteResponse quote = await service.getQuote(quoteId, jwtToken);

    expect(quote.id, 'de762cda-a193-4961-861e-57b31fed6eb3');
    expect(quote.expiresAt, DateTime.parse('2024-02-01T10:40:14+0000'));
    expect(quote.totalPrice, '5.42');
    expect(quote.price, '5.00');
    expect(quote.sellAsset, 'iso4217:BRL');
    expect(quote.buyAsset, usdcAsset);
    expect(quote.sellAmount, '542');
    expect(quote.buyAmount, '100');

    // Validity check from the doc snippet
    // (quote.expiresAt is in 2024 so it won't be valid now, but we test the check runs)
    bool isValid = quote.expiresAt.isAfter(DateTime.now());
    expect(isValid, isFalse); // expired in 2024
  });

  test('sep-38: Error handling - ArgumentError for both amounts', () async {
    // Snippet from sep-38.md "Error handling" - providing both amounts
    final service = SEP38QuoteService(quoteServer);

    service.httpClient = MockClient((request) async {
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    // Providing both sellAmount and buyAmount should throw ArgumentError
    expect(
      () async => await service.price(
        context: 'sep6',
        sellAsset: 'iso4217:USD',
        buyAsset: usdcAsset,
        sellAmount: '100',
        buyAmount: '95',
      ),
      throwsArgumentError,
    );

    // Providing neither should also throw ArgumentError
    expect(
      () async => await service.price(
        context: 'sep6',
        sellAsset: 'iso4217:USD',
        buyAsset: usdcAsset,
      ),
      throwsArgumentError,
    );
  });

  test('sep-38: Error handling - postQuote ArgumentError', () async {
    // Providing both amounts to postQuote should throw ArgumentError
    final service = SEP38QuoteService(quoteServer);

    service.httpClient = MockClient((request) async {
      return http.Response(firmQuoteResponseJson(), 200);
    });

    expect(
      () async {
        SEP38PostQuoteRequest request = SEP38PostQuoteRequest(
          context: 'sep6',
          sellAsset: 'iso4217:USD',
          buyAsset: usdcAsset,
          sellAmount: '100',
          buyAmount: '95',
        );
        await service.postQuote(request, jwtToken);
      },
      throwsArgumentError,
    );
  });

  test('sep-38: Error handling - SEP38PermissionDenied', () async {
    // Snippet from sep-38.md "Error handling" - permission denied
    final service = SEP38QuoteService(quoteServer);

    service.httpClient = MockClient((request) async {
      if (request.method == 'POST') {
        return http.Response(
            json.encode({'error': 'Token expired'}), 403);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    expect(
      () async {
        SEP38PostQuoteRequest request = SEP38PostQuoteRequest(
          context: 'sep6',
          sellAsset: 'iso4217:USD',
          buyAsset: usdcAsset,
          sellAmount: '100',
        );
        await service.postQuote(request, jwtToken);
      },
      throwsA(isA<SEP38PermissionDenied>()),
    );
  });

  test('sep-38: Error handling - SEP38NotFound', () async {
    // getQuote with non-existent ID
    final service = SEP38QuoteService(quoteServer);

    service.httpClient = MockClient((request) async {
      if (request.method == 'GET' &&
          request.url.toString().contains('quote/')) {
        return http.Response(
            json.encode({'error': 'Quote not found'}), 404);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    expect(
      () async => await service.getQuote('nonexistent-id', jwtToken),
      throwsA(isA<SEP38NotFound>()),
    );
  });

  test('sep-38: Error handling - SEP38BadRequest', () async {
    // Invalid request returns 400
    final service = SEP38QuoteService(quoteServer);

    service.httpClient = MockClient((request) async {
      return http.Response(
          json.encode({'error': 'Invalid asset format'}), 400);
    });

    expect(
      () async => await service.info(),
      throwsA(isA<SEP38BadRequest>()),
    );
  });

  test('sep-38: Error handling - SEP38UnknownResponse', () async {
    // Server error returns 500
    final service = SEP38QuoteService(quoteServer);

    service.httpClient = MockClient((request) async {
      return http.Response('Internal Server Error', 500);
    });

    expect(
      () async => await service.info(),
      throwsA(isA<SEP38UnknownResponse>()),
    );
  });
}
