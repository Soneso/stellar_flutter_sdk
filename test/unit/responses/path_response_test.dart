import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('PathResponse', () {
    test('parses JSON with all fields correctly', () {
      final json = {
        'destination_amount': '100.0000000',
        'destination_asset_type': 'credit_alphanum4',
        'destination_asset_code': 'USD',
        'destination_asset_issuer': 'GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5',
        'source_amount': '250.0000000',
        'source_asset_type': 'native',
        'source_asset_code': null,
        'source_asset_issuer': null,
        'path': [
          {
            'asset_type': 'credit_alphanum4',
            'asset_code': 'EUR',
            'asset_issuer': 'GCKG5WGBIJP74UDNRIRDFGENNIH5Y3KZ4KITCTUM4CWMB7LWPGDHKCPM'
          }
        ],
        '_links': {
          'self': {'href': 'https://horizon.stellar.org/paths/strict-send'}
        }
      };

      final response = PathResponse.fromJson(json);

      expect(response.destinationAmount, equals('100.0000000'));
      expect(response.destinationAssetType, equals('credit_alphanum4'));
      expect(response.destinationAssetCode, equals('USD'));
      expect(response.destinationAssetIssuer, equals('GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5'));
      expect(response.sourceAmount, equals('250.0000000'));
      expect(response.sourceAssetType, equals('native'));
      expect(response.sourceAssetCode, isNull);
      expect(response.sourceAssetIssuer, isNull);
    });

    test('parses destination asset correctly', () {
      final json = {
        'destination_amount': '100.0',
        'destination_asset_type': 'credit_alphanum12',
        'destination_asset_code': 'LONGERCODE',
        'destination_asset_issuer': 'GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5',
        'source_amount': '200.0',
        'source_asset_type': 'native',
        'source_asset_code': null,
        'source_asset_issuer': null,
        'path': [],
        '_links': null
      };

      final response = PathResponse.fromJson(json);
      final destAsset = response.destinationAsset;

      expect(destAsset, isA<AssetTypeCreditAlphaNum12>());
      expect((destAsset as AssetTypeCreditAlphaNum12).code, equals('LONGERCODE'));
      expect(destAsset.issuerId, equals('GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5'));
    });

    test('parses native destination asset correctly', () {
      final json = {
        'destination_amount': '50.0',
        'destination_asset_type': 'native',
        'destination_asset_code': null,
        'destination_asset_issuer': null,
        'source_amount': '100.0',
        'source_asset_type': 'credit_alphanum4',
        'source_asset_code': 'USD',
        'source_asset_issuer': 'GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5',
        'path': [],
        '_links': null
      };

      final response = PathResponse.fromJson(json);
      final destAsset = response.destinationAsset;

      expect(destAsset, isA<AssetTypeNative>());
    });

    test('parses source asset correctly', () {
      final json = {
        'destination_amount': '100.0',
        'destination_asset_type': 'native',
        'destination_asset_code': null,
        'destination_asset_issuer': null,
        'source_amount': '200.0',
        'source_asset_type': 'credit_alphanum4',
        'source_asset_code': 'USDC',
        'source_asset_issuer': 'GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5',
        'path': [],
        '_links': null
      };

      final response = PathResponse.fromJson(json);
      final sourceAsset = response.sourceAsset;

      expect(sourceAsset, isA<AssetTypeCreditAlphaNum4>());
      expect((sourceAsset as AssetTypeCreditAlphaNum4).code, equals('USDC'));
    });

    test('parses native source asset correctly', () {
      final json = {
        'destination_amount': '100.0',
        'destination_asset_type': 'credit_alphanum4',
        'destination_asset_code': 'USD',
        'destination_asset_issuer': 'GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5',
        'source_amount': '250.0',
        'source_asset_type': 'native',
        'source_asset_code': null,
        'source_asset_issuer': null,
        'path': [],
        '_links': null
      };

      final response = PathResponse.fromJson(json);
      final sourceAsset = response.sourceAsset;

      expect(sourceAsset, isA<AssetTypeNative>());
    });

    test('parses path with multiple intermediate assets', () {
      final json = {
        'destination_amount': '100.0',
        'destination_asset_type': 'credit_alphanum4',
        'destination_asset_code': 'USD',
        'destination_asset_issuer': 'GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5',
        'source_amount': '250.0',
        'source_asset_type': 'native',
        'source_asset_code': null,
        'source_asset_issuer': null,
        'path': [
          {
            'asset_type': 'credit_alphanum4',
            'asset_code': 'EUR',
            'asset_issuer': 'GCKG5WGBIJP74UDNRIRDFGENNIH5Y3KZ4KITCTUM4CWMB7LWPGDHKCPM'
          },
          {
            'asset_type': 'credit_alphanum4',
            'asset_code': 'GBP',
            'asset_issuer': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7'
          }
        ],
        '_links': null
      };

      final response = PathResponse.fromJson(json);

      expect(response.path.length, equals(2));
      expect((response.path[0] as AssetTypeCreditAlphaNum4).code, equals('EUR'));
      expect((response.path[1] as AssetTypeCreditAlphaNum4).code, equals('GBP'));
    });

    test('handles empty path for direct conversion', () {
      final json = {
        'destination_amount': '100.0',
        'destination_asset_type': 'credit_alphanum4',
        'destination_asset_code': 'USD',
        'destination_asset_issuer': 'GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5',
        'source_amount': '100.0',
        'source_asset_type': 'credit_alphanum4',
        'source_asset_code': 'USDC',
        'source_asset_issuer': 'GCKG5WGBIJP74UDNRIRDFGENNIH5Y3KZ4KITCTUM4CWMB7LWPGDHKCPM',
        'path': [],
        '_links': null
      };

      final response = PathResponse.fromJson(json);

      expect(response.path.length, equals(0));
    });

    test('handles null path field', () {
      final json = {
        'destination_amount': '100.0',
        'destination_asset_type': 'native',
        'destination_asset_code': null,
        'destination_asset_issuer': null,
        'source_amount': '100.0',
        'source_asset_type': 'native',
        'source_asset_code': null,
        'source_asset_issuer': null,
        'path': null,
        '_links': null
      };

      final response = PathResponse.fromJson(json);

      expect(response.path.length, equals(0));
    });

    test('parses links correctly', () {
      final json = {
        'destination_amount': '100.0',
        'destination_asset_type': 'native',
        'destination_asset_code': null,
        'destination_asset_issuer': null,
        'source_amount': '100.0',
        'source_asset_type': 'native',
        'source_asset_code': null,
        'source_asset_issuer': null,
        'path': [],
        '_links': {
          'self': {'href': 'https://horizon.stellar.org/paths/strict-send'}
        }
      };

      final response = PathResponse.fromJson(json);

      expect(response.links, isNotNull);
      expect(response.links!.self, isNotNull);
      expect(response.links!.self!.href, equals('https://horizon.stellar.org/paths/strict-send'));
    });

    test('handles null links field', () {
      final json = {
        'destination_amount': '100.0',
        'destination_asset_type': 'native',
        'destination_asset_code': null,
        'destination_asset_issuer': null,
        'source_amount': '100.0',
        'source_asset_type': 'native',
        'source_asset_code': null,
        'source_asset_issuer': null,
        'path': [],
        '_links': null
      };

      final response = PathResponse.fromJson(json);

      expect(response.links, isNull);
    });

    test('parses path with native asset', () {
      final json = {
        'destination_amount': '100.0',
        'destination_asset_type': 'credit_alphanum4',
        'destination_asset_code': 'USD',
        'destination_asset_issuer': 'GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5',
        'source_amount': '250.0',
        'source_asset_type': 'credit_alphanum4',
        'source_asset_code': 'EUR',
        'source_asset_issuer': 'GCKG5WGBIJP74UDNRIRDFGENNIH5Y3KZ4KITCTUM4CWMB7LWPGDHKCPM',
        'path': [
          {'asset_type': 'native'}
        ],
        '_links': null
      };

      final response = PathResponse.fromJson(json);

      expect(response.path.length, equals(1));
      expect(response.path[0], isA<AssetTypeNative>());
    });
  });

  group('PathResponseLinks', () {
    test('parses self link correctly', () {
      final json = {
        'self': {'href': 'https://horizon.stellar.org/paths/strict-send'}
      };

      final links = PathResponseLinks.fromJson(json);

      expect(links.self, isNotNull);
      expect(links.self!.href, equals('https://horizon.stellar.org/paths/strict-send'));
    });

    test('handles null self link', () {
      final json = {'self': null};

      final links = PathResponseLinks.fromJson(json);

      expect(links.self, isNull);
    });
  });
}
