import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('OfferResponse', () {
    test('parses JSON with all fields correctly', () {
      final json = {
        'id': '123456',
        'paging_token': 'token-123456',
        'seller': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
        'selling': {
          'asset_type': 'credit_alphanum4',
          'asset_code': 'USDC',
          'asset_issuer': 'GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5'
        },
        'buying': {
          'asset_type': 'native'
        },
        'amount': '100.0000000',
        'price': '2.5000000',
        'price_r': {'n': 5, 'd': 2},
        'sponsor': 'GCKG5WGBIJP74UDNRIRDFGENNIH5Y3KZ4KITCTUM4CWMB7LWPGDHKCPM',
        'last_modified_ledger': 1234567,
        'last_modified_time': '2023-08-15T10:30:45Z',
        '_links': {
          'self': {'href': 'https://horizon.stellar.org/offers/123456'},
          'offer_maker': {'href': 'https://horizon.stellar.org/accounts/GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7'}
        }
      };

      final response = OfferResponse.fromJson(json);

      expect(response.id, equals('123456'));
      expect(response.pagingToken, equals('token-123456'));
      expect(response.seller, equals('GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7'));
      expect(response.amount, equals('100.0000000'));
      expect(response.price, equals('2.5000000'));
      expect(response.sponsor, equals('GCKG5WGBIJP74UDNRIRDFGENNIH5Y3KZ4KITCTUM4CWMB7LWPGDHKCPM'));
      expect(response.lastModifiedLedger, equals(1234567));
      expect(response.lastModifiedTime, equals('2023-08-15T10:30:45Z'));
    });

    test('parses selling asset correctly', () {
      final json = {
        'id': '123',
        'paging_token': 'token',
        'seller': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
        'selling': {
          'asset_type': 'credit_alphanum4',
          'asset_code': 'USDC',
          'asset_issuer': 'GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5'
        },
        'buying': {'asset_type': 'native'},
        'amount': '100.0',
        'price': '1.0',
        'price_r': {'n': 1, 'd': 1},
        'sponsor': null,
        'last_modified_ledger': 123,
        'last_modified_time': '2023-08-15T10:30:45Z',
        '_links': {
          'self': {'href': 'https://example.com'},
          'offer_maker': {'href': 'https://example.com'}
        }
      };

      final response = OfferResponse.fromJson(json);

      expect(response.selling, isA<AssetTypeCreditAlphaNum4>());
      expect((response.selling as AssetTypeCreditAlphaNum4).code, equals('USDC'));
      expect((response.selling as AssetTypeCreditAlphaNum4).issuerId, equals('GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5'));
    });

    test('parses buying asset correctly', () {
      final json = {
        'id': '123',
        'paging_token': 'token',
        'seller': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
        'selling': {'asset_type': 'native'},
        'buying': {
          'asset_type': 'credit_alphanum12',
          'asset_code': 'LONGERCODE',
          'asset_issuer': 'GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5'
        },
        'amount': '100.0',
        'price': '1.0',
        'price_r': {'n': 1, 'd': 1},
        'sponsor': null,
        'last_modified_ledger': 123,
        'last_modified_time': '2023-08-15T10:30:45Z',
        '_links': {
          'self': {'href': 'https://example.com'},
          'offer_maker': {'href': 'https://example.com'}
        }
      };

      final response = OfferResponse.fromJson(json);

      expect(response.buying, isA<AssetTypeCreditAlphaNum12>());
      expect((response.buying as AssetTypeCreditAlphaNum12).code, equals('LONGERCODE'));
    });

    test('parses price ratio correctly', () {
      final json = {
        'id': '123',
        'paging_token': 'token',
        'seller': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
        'selling': {'asset_type': 'native'},
        'buying': {'asset_type': 'native'},
        'amount': '100.0',
        'price': '1.5',
        'price_r': {'n': 3, 'd': 2},
        'sponsor': null,
        'last_modified_ledger': 123,
        'last_modified_time': '2023-08-15T10:30:45Z',
        '_links': {
          'self': {'href': 'https://example.com'},
          'offer_maker': {'href': 'https://example.com'}
        }
      };

      final response = OfferResponse.fromJson(json);

      expect(response.priceR.n, equals(3));
      expect(response.priceR.d, equals(2));
    });

    test('handles null sponsor field', () {
      final json = {
        'id': '123',
        'paging_token': 'token',
        'seller': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
        'selling': {'asset_type': 'native'},
        'buying': {'asset_type': 'native'},
        'amount': '100.0',
        'price': '1.0',
        'price_r': {'n': 1, 'd': 1},
        'sponsor': null,
        'last_modified_ledger': 123,
        'last_modified_time': '2023-08-15T10:30:45Z',
        '_links': {
          'self': {'href': 'https://example.com'},
          'offer_maker': {'href': 'https://example.com'}
        }
      };

      final response = OfferResponse.fromJson(json);

      expect(response.sponsor, isNull);
    });

    test('parses links correctly', () {
      final json = {
        'id': '123',
        'paging_token': 'token',
        'seller': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
        'selling': {'asset_type': 'native'},
        'buying': {'asset_type': 'native'},
        'amount': '100.0',
        'price': '1.0',
        'price_r': {'n': 1, 'd': 1},
        'sponsor': null,
        'last_modified_ledger': 123,
        'last_modified_time': '2023-08-15T10:30:45Z',
        '_links': {
          'self': {'href': 'https://horizon.stellar.org/offers/123'},
          'offer_maker': {'href': 'https://horizon.stellar.org/accounts/GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7'}
        }
      };

      final response = OfferResponse.fromJson(json);

      expect(response.links.self.href, equals('https://horizon.stellar.org/offers/123'));
      expect(response.links.offerMaker.href, equals('https://horizon.stellar.org/accounts/GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7'));
    });

    test('parses native assets correctly', () {
      final json = {
        'id': '123',
        'paging_token': 'token',
        'seller': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
        'selling': {'asset_type': 'native'},
        'buying': {'asset_type': 'native'},
        'amount': '100.0',
        'price': '1.0',
        'price_r': {'n': 1, 'd': 1},
        'sponsor': null,
        'last_modified_ledger': 123,
        'last_modified_time': '2023-08-15T10:30:45Z',
        '_links': {
          'self': {'href': 'https://example.com'},
          'offer_maker': {'href': 'https://example.com'}
        }
      };

      final response = OfferResponse.fromJson(json);

      expect(response.selling, isA<AssetTypeNative>());
      expect(response.buying, isA<AssetTypeNative>());
    });

    test('converts last_modified_ledger to int', () {
      final json = {
        'id': '123',
        'paging_token': 'token',
        'seller': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
        'selling': {'asset_type': 'native'},
        'buying': {'asset_type': 'native'},
        'amount': '100.0',
        'price': '1.0',
        'price_r': {'n': 1, 'd': 1},
        'sponsor': null,
        'last_modified_ledger': 9876543,
        'last_modified_time': '2023-08-15T10:30:45Z',
        '_links': {
          'self': {'href': 'https://example.com'},
          'offer_maker': {'href': 'https://example.com'}
        }
      };

      final response = OfferResponse.fromJson(json);

      expect(response.lastModifiedLedger, isA<int>());
      expect(response.lastModifiedLedger, equals(9876543));
    });
  });

  group('OfferResponseLinks', () {
    test('parses both links correctly', () {
      final json = {
        'self': {'href': 'https://horizon.stellar.org/offers/123456'},
        'offer_maker': {'href': 'https://horizon.stellar.org/accounts/GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7'}
      };

      final links = OfferResponseLinks.fromJson(json);

      expect(links.self.href, equals('https://horizon.stellar.org/offers/123456'));
      expect(links.offerMaker.href, equals('https://horizon.stellar.org/accounts/GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7'));
    });
  });
}
