import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('ClaimableBalanceResponse', () {
    test('parses JSON with all fields correctly', () {
      final json = {
        'id': '00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072',
        'asset': 'USDC:GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5',
        'amount': '10.0000000',
        'sponsor': 'GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5',
        'last_modified_ledger': 1234567,
        'last_modified_time': '2023-08-15T10:30:45Z',
        'claimants': [
          {
            'destination': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
            'predicate': {'unconditional': true}
          }
        ],
        '_links': {
          'self': {
            'href': 'https://horizon.stellar.org/claimable_balances/00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072'
          }
        },
        'flags': {'clawback_enabled': true}
      };

      final response = ClaimableBalanceResponse.fromJson(json);

      expect(response.balanceId, equals('00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072'));
      expect(response.amount, equals('10.0000000'));
      expect(response.sponsor, equals('GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5'));
      expect(response.lastModifiedLedger, equals(1234567));
      expect(response.lastModifiedTime, equals('2023-08-15T10:30:45Z'));
    });

    test('parses asset field correctly', () {
      final json = {
        'id': 'test-id',
        'asset': 'USDC:GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5',
        'amount': '100.0',
        'sponsor': null,
        'last_modified_ledger': 123,
        'last_modified_time': '2023-08-15T10:30:45Z',
        'claimants': [],
        '_links': {'self': {'href': 'https://example.com'}},
        'flags': {'clawback_enabled': false}
      };

      final response = ClaimableBalanceResponse.fromJson(json);

      expect(response.asset, isA<AssetTypeCreditAlphaNum4>());
      expect((response.asset as AssetTypeCreditAlphaNum4).code, equals('USDC'));
      expect((response.asset as AssetTypeCreditAlphaNum4).issuerId, equals('GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5'));
    });

    test('parses native asset correctly', () {
      final json = {
        'id': 'test-id',
        'asset': 'native',
        'amount': '50.0',
        'sponsor': null,
        'last_modified_ledger': 123,
        'last_modified_time': '2023-08-15T10:30:45Z',
        'claimants': [],
        '_links': {'self': {'href': 'https://example.com'}},
        'flags': {'clawback_enabled': false}
      };

      final response = ClaimableBalanceResponse.fromJson(json);

      expect(response.asset, isA<AssetTypeNative>());
    });

    test('handles null sponsor field', () {
      final json = {
        'id': 'test-id',
        'asset': 'native',
        'amount': '25.0',
        'sponsor': null,
        'last_modified_ledger': 456,
        'last_modified_time': '2023-08-15T10:30:45Z',
        'claimants': [],
        '_links': {'self': {'href': 'https://example.com'}},
        'flags': {'clawback_enabled': false}
      };

      final response = ClaimableBalanceResponse.fromJson(json);

      expect(response.sponsor, isNull);
    });

    test('parses multiple claimants correctly', () {
      final json = {
        'id': 'test-id',
        'asset': 'native',
        'amount': '10.0',
        'sponsor': null,
        'last_modified_ledger': 123,
        'last_modified_time': '2023-08-15T10:30:45Z',
        'claimants': [
          {
            'destination': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
            'predicate': {'unconditional': true}
          },
          {
            'destination': 'GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5',
            'predicate': {'abs_before': '2024-12-31T23:59:59Z'}
          }
        ],
        '_links': {'self': {'href': 'https://example.com'}},
        'flags': {'clawback_enabled': false}
      };

      final response = ClaimableBalanceResponse.fromJson(json);

      expect(response.claimants.length, equals(2));
      expect(response.claimants[0].destination, equals('GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7'));
      expect(response.claimants[1].destination, equals('GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5'));
    });

    test('parses links correctly', () {
      final json = {
        'id': 'test-id',
        'asset': 'native',
        'amount': '10.0',
        'sponsor': null,
        'last_modified_ledger': 123,
        'last_modified_time': '2023-08-15T10:30:45Z',
        'claimants': [],
        '_links': {
          'self': {'href': 'https://horizon.stellar.org/claimable_balances/test-id'}
        },
        'flags': {'clawback_enabled': false}
      };

      final response = ClaimableBalanceResponse.fromJson(json);

      expect(response.links.self, isNotNull);
      expect(response.links.self!.href, equals('https://horizon.stellar.org/claimable_balances/test-id'));
    });

    test('parses flags correctly', () {
      final json = {
        'id': 'test-id',
        'asset': 'native',
        'amount': '10.0',
        'sponsor': null,
        'last_modified_ledger': 123,
        'last_modified_time': '2023-08-15T10:30:45Z',
        'claimants': [],
        '_links': {'self': {'href': 'https://example.com'}},
        'flags': {'clawback_enabled': true}
      };

      final response = ClaimableBalanceResponse.fromJson(json);

      expect(response.flags.clawbackEnabled, isTrue);
    });

    test('ClaimableBalanceFlags parses correctly', () {
      final json = {'clawback_enabled': false};

      final flags = ClaimableBalanceFlags.fromJson(json);

      expect(flags.clawbackEnabled, isFalse);
    });
  });

  group('ClaimantResponse', () {
    test('parses JSON correctly', () {
      final json = {
        'destination': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
        'predicate': {'unconditional': true}
      };

      final claimant = ClaimantResponse.fromJson(json);

      expect(claimant.destination, equals('GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7'));
      expect(claimant.predicate, isA<ClaimantPredicateResponse>());
    });
  });

  group('ClaimantPredicateResponse', () {
    test('parses unconditional predicate', () {
      final json = {'unconditional': true};

      final predicate = ClaimantPredicateResponse.fromJson(json);

      expect(predicate.unconditional, isTrue);
      expect(predicate.and, isNull);
      expect(predicate.or, isNull);
      expect(predicate.not, isNull);
      expect(predicate.beforeAbsoluteTime, isNull);
      expect(predicate.beforeRelativeTime, isNull);
    });

    test('parses beforeAbsoluteTime predicate', () {
      final json = {'abs_before': '2024-12-31T23:59:59Z'};

      final predicate = ClaimantPredicateResponse.fromJson(json);

      expect(predicate.beforeAbsoluteTime, equals('2024-12-31T23:59:59Z'));
      expect(predicate.unconditional, isNull);
    });

    test('parses beforeRelativeTime predicate', () {
      final json = {'rel_before': '86400'};

      final predicate = ClaimantPredicateResponse.fromJson(json);

      expect(predicate.beforeRelativeTime, equals('86400'));
      expect(predicate.unconditional, isNull);
    });

    test('parses AND predicate with nested conditions', () {
      final json = {
        'and': [
          {'abs_before': '2024-12-31T23:59:59Z'},
          {'rel_before': '86400'}
        ]
      };

      final predicate = ClaimantPredicateResponse.fromJson(json);

      expect(predicate.and, isNotNull);
      expect(predicate.and!.length, equals(2));
      expect(predicate.and![0].beforeAbsoluteTime, equals('2024-12-31T23:59:59Z'));
      expect(predicate.and![1].beforeRelativeTime, equals('86400'));
    });

    test('parses OR predicate with nested conditions', () {
      final json = {
        'or': [
          {'unconditional': true},
          {'abs_before': '2024-12-31T23:59:59Z'}
        ]
      };

      final predicate = ClaimantPredicateResponse.fromJson(json);

      expect(predicate.or, isNotNull);
      expect(predicate.or!.length, equals(2));
      expect(predicate.or![0].unconditional, isTrue);
      expect(predicate.or![1].beforeAbsoluteTime, equals('2024-12-31T23:59:59Z'));
    });

    test('parses NOT predicate', () {
      final json = {
        'not': {'abs_before': '2024-01-01T00:00:00Z'}
      };

      final predicate = ClaimantPredicateResponse.fromJson(json);

      expect(predicate.not, isNotNull);
      expect(predicate.not!.beforeAbsoluteTime, equals('2024-01-01T00:00:00Z'));
    });

    test('parses complex nested predicate', () {
      final json = {
        'and': [
          {
            'or': [
              {'unconditional': true},
              {'abs_before': '2024-12-31T23:59:59Z'}
            ]
          },
          {
            'not': {'rel_before': '3600'}
          }
        ]
      };

      final predicate = ClaimantPredicateResponse.fromJson(json);

      expect(predicate.and, isNotNull);
      expect(predicate.and!.length, equals(2));
      expect(predicate.and![0].or, isNotNull);
      expect(predicate.and![0].or!.length, equals(2));
      expect(predicate.and![1].not, isNotNull);
    });
  });

  group('ClaimableBalanceResponseLinks', () {
    test('parses links with self', () {
      final json = {
        'self': {'href': 'https://horizon.stellar.org/claimable_balances/test-id'}
      };

      final links = ClaimableBalanceResponseLinks.fromJson(json);

      expect(links.self, isNotNull);
      expect(links.self!.href, equals('https://horizon.stellar.org/claimable_balances/test-id'));
    });

    test('handles null self link', () {
      final json = {'self': null};

      final links = ClaimableBalanceResponseLinks.fromJson(json);

      expect(links.self, isNull);
    });
  });
}
