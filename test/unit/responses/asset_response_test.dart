import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('AssetResponse', () {
    test('parses JSON with all fields correctly', () {
      final json = {
        'asset_type': 'credit_alphanum4',
        'asset_code': 'USDC',
        'asset_issuer': 'GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5',
        'accounts': {
          'authorized': 150,
          'authorized_to_maintain_liabilities': 10,
          'unauthorized': 5
        },
        'num_claimable_balances': 25,
        'balances': {
          'authorized': '1000000.0000000',
          'authorized_to_maintain_liabilities': '50000.0000000',
          'unauthorized': '100.0000000'
        },
        'claimable_balances_amount': '5000.0000000',
        'paging_token': 'USDC_GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5_credit_alphanum4',
        'num_liquidity_pools': 12,
        'liquidity_pools_amount': '75000.0000000',
        'flags': {
          'auth_required': true,
          'auth_revocable': true,
          'auth_immutable': false,
          'auth_clawback_enabled': true
        },
        '_links': {
          'toml': {'href': 'https://example.com/.well-known/stellar.toml'}
        },
        'num_contracts': 8,
        'contracts_amount': '20000.0000000',
        'contract_id': 'CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC'
      };

      final response = AssetResponse.fromJson(json);

      expect(response.assetType, equals('credit_alphanum4'));
      expect(response.assetCode, equals('USDC'));
      expect(response.assetIssuer, equals('GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5'));
      expect(response.pagingToken, equals('USDC_GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5_credit_alphanum4'));
      expect(response.numClaimableBalances, equals(25));
      expect(response.claimableBalancesAmount, equals('5000.0000000'));
      expect(response.numLiquidityPools, equals(12));
      expect(response.liquidityPoolsAmount, equals('75000.0000000'));
      expect(response.numContracts, equals(8));
      expect(response.contractsAmount, equals('20000.0000000'));
      expect(response.contractId, equals('CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC'));
    });

    test('parses accounts statistics correctly', () {
      final json = {
        'asset_type': 'credit_alphanum4',
        'asset_code': 'USD',
        'asset_issuer': 'GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5',
        'accounts': {
          'authorized': 100,
          'authorized_to_maintain_liabilities': 20,
          'unauthorized': 5
        },
        'num_claimable_balances': 0,
        'balances': {
          'authorized': '100.0',
          'authorized_to_maintain_liabilities': '10.0',
          'unauthorized': '1.0'
        },
        'claimable_balances_amount': '0.0',
        'paging_token': 'token',
        'num_liquidity_pools': 0,
        'liquidity_pools_amount': '0.0',
        'flags': {
          'auth_required': false,
          'auth_revocable': false,
          'auth_immutable': false,
          'auth_clawback_enabled': false
        },
        '_links': {'toml': {'href': 'https://example.com/.well-known/stellar.toml'}},
        'num_contracts': 0,
        'contracts_amount': '0.0',
        'contract_id': null
      };

      final response = AssetResponse.fromJson(json);

      expect(response.accounts.authorized, equals(100));
      expect(response.accounts.authorizedToMaintainLiabilities, equals(20));
      expect(response.accounts.unauthorized, equals(5));
    });

    test('parses balances statistics correctly', () {
      final json = {
        'asset_type': 'credit_alphanum4',
        'asset_code': 'USD',
        'asset_issuer': 'GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5',
        'accounts': {
          'authorized': 100,
          'authorized_to_maintain_liabilities': 20,
          'unauthorized': 5
        },
        'num_claimable_balances': 0,
        'balances': {
          'authorized': '500000.0000000',
          'authorized_to_maintain_liabilities': '25000.0000000',
          'unauthorized': '500.0000000'
        },
        'claimable_balances_amount': '0.0',
        'paging_token': 'token',
        'num_liquidity_pools': 0,
        'liquidity_pools_amount': '0.0',
        'flags': {
          'auth_required': false,
          'auth_revocable': false,
          'auth_immutable': false,
          'auth_clawback_enabled': false
        },
        '_links': {'toml': {'href': 'https://example.com/.well-known/stellar.toml'}},
        'num_contracts': 0,
        'contracts_amount': '0.0',
        'contract_id': null
      };

      final response = AssetResponse.fromJson(json);

      expect(response.balances.authorized, equals('500000.0000000'));
      expect(response.balances.authorizedToMaintainLiabilities, equals('25000.0000000'));
      expect(response.balances.unauthorized, equals('500.0000000'));
    });

    test('parses flags correctly', () {
      final json = {
        'asset_type': 'credit_alphanum4',
        'asset_code': 'USD',
        'asset_issuer': 'GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5',
        'accounts': {
          'authorized': 0,
          'authorized_to_maintain_liabilities': 0,
          'unauthorized': 0
        },
        'num_claimable_balances': 0,
        'balances': {
          'authorized': '0.0',
          'authorized_to_maintain_liabilities': '0.0',
          'unauthorized': '0.0'
        },
        'claimable_balances_amount': '0.0',
        'paging_token': 'token',
        'num_liquidity_pools': 0,
        'liquidity_pools_amount': '0.0',
        'flags': {
          'auth_required': true,
          'auth_revocable': true,
          'auth_immutable': false,
          'auth_clawback_enabled': true
        },
        '_links': {'toml': {'href': 'https://example.com/.well-known/stellar.toml'}},
        'num_contracts': 0,
        'contracts_amount': '0.0',
        'contract_id': null
      };

      final response = AssetResponse.fromJson(json);

      expect(response.flags.authRequired, isTrue);
      expect(response.flags.authRevocable, isTrue);
      expect(response.flags.authImmutable, isFalse);
      expect(response.flags.clawbackEnabled, isTrue);
    });

    test('parses links correctly', () {
      final json = {
        'asset_type': 'credit_alphanum4',
        'asset_code': 'USD',
        'asset_issuer': 'GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5',
        'accounts': {
          'authorized': 0,
          'authorized_to_maintain_liabilities': 0,
          'unauthorized': 0
        },
        'num_claimable_balances': 0,
        'balances': {
          'authorized': '0.0',
          'authorized_to_maintain_liabilities': '0.0',
          'unauthorized': '0.0'
        },
        'claimable_balances_amount': '0.0',
        'paging_token': 'token',
        'num_liquidity_pools': 0,
        'liquidity_pools_amount': '0.0',
        'flags': {
          'auth_required': false,
          'auth_revocable': false,
          'auth_immutable': false,
          'auth_clawback_enabled': false
        },
        '_links': {
          'toml': {'href': 'https://stellar.org/.well-known/stellar.toml'}
        },
        'num_contracts': 0,
        'contracts_amount': '0.0',
        'contract_id': null
      };

      final response = AssetResponse.fromJson(json);

      expect(response.links.toml.href, equals('https://stellar.org/.well-known/stellar.toml'));
    });

    test('converts to Asset object correctly', () {
      final json = {
        'asset_type': 'credit_alphanum4',
        'asset_code': 'USDC',
        'asset_issuer': 'GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5',
        'accounts': {
          'authorized': 0,
          'authorized_to_maintain_liabilities': 0,
          'unauthorized': 0
        },
        'num_claimable_balances': 0,
        'balances': {
          'authorized': '0.0',
          'authorized_to_maintain_liabilities': '0.0',
          'unauthorized': '0.0'
        },
        'claimable_balances_amount': '0.0',
        'paging_token': 'token',
        'num_liquidity_pools': 0,
        'liquidity_pools_amount': '0.0',
        'flags': {
          'auth_required': false,
          'auth_revocable': false,
          'auth_immutable': false,
          'auth_clawback_enabled': false
        },
        '_links': {'toml': {'href': 'https://example.com/.well-known/stellar.toml'}},
        'num_contracts': 0,
        'contracts_amount': '0.0',
        'contract_id': null
      };

      final response = AssetResponse.fromJson(json);
      final asset = response.asset;

      expect(asset, isA<AssetTypeCreditAlphaNum4>());
      expect((asset as AssetTypeCreditAlphaNum4).code, equals('USDC'));
      expect(asset.issuerId, equals('GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5'));
    });

    test('handles null contract_id field', () {
      final json = {
        'asset_type': 'credit_alphanum4',
        'asset_code': 'USD',
        'asset_issuer': 'GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5',
        'accounts': {
          'authorized': 0,
          'authorized_to_maintain_liabilities': 0,
          'unauthorized': 0
        },
        'num_claimable_balances': 0,
        'balances': {
          'authorized': '0.0',
          'authorized_to_maintain_liabilities': '0.0',
          'unauthorized': '0.0'
        },
        'claimable_balances_amount': '0.0',
        'paging_token': 'token',
        'num_liquidity_pools': 0,
        'liquidity_pools_amount': '0.0',
        'flags': {
          'auth_required': false,
          'auth_revocable': false,
          'auth_immutable': false,
          'auth_clawback_enabled': false
        },
        '_links': {'toml': {'href': 'https://example.com/.well-known/stellar.toml'}},
        'num_contracts': 0,
        'contracts_amount': '0.0',
        'contract_id': null
      };

      final response = AssetResponse.fromJson(json);

      expect(response.contractId, isNull);
    });
  });

  group('AssetAccounts', () {
    test('parses JSON correctly', () {
      final json = {
        'authorized': 150,
        'authorized_to_maintain_liabilities': 25,
        'unauthorized': 10
      };

      final accounts = AssetAccounts.fromJson(json);

      expect(accounts.authorized, equals(150));
      expect(accounts.authorizedToMaintainLiabilities, equals(25));
      expect(accounts.unauthorized, equals(10));
    });
  });

  group('AssetBalances', () {
    test('parses JSON correctly', () {
      final json = {
        'authorized': '1000000.0000000',
        'authorized_to_maintain_liabilities': '50000.0000000',
        'unauthorized': '1000.0000000'
      };

      final balances = AssetBalances.fromJson(json);

      expect(balances.authorized, equals('1000000.0000000'));
      expect(balances.authorizedToMaintainLiabilities, equals('50000.0000000'));
      expect(balances.unauthorized, equals('1000.0000000'));
    });
  });

  group('AssetResponseLinks', () {
    test('parses toml link correctly', () {
      final json = {
        'toml': {'href': 'https://stellar.org/.well-known/stellar.toml'}
      };

      final links = AssetResponseLinks.fromJson(json);

      expect(links.toml.href, equals('https://stellar.org/.well-known/stellar.toml'));
    });

    test('toJson converts back to JSON correctly', () {
      final json = {
        'toml': {'href': 'https://stellar.org/.well-known/stellar.toml'}
      };

      final links = AssetResponseLinks.fromJson(json);
      final convertedJson = links.toJson();

      expect(convertedJson['toml'], isA<Link>());
    });
  });
}
