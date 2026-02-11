import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('AccountResponse', () {
    group('fromJson', () {
      test('parses complete account response with all fields', () {
        final json = {
          'account_id': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'sequence': '123456789012345',
          'paging_token': '123456789012345',
          'subentry_count': 5,
          'inflation_destination': 'GBCD1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXA',
          'home_domain': 'example.com',
          'last_modified_ledger': 987654,
          'last_modified_time': '2024-01-15T10:30:00Z',
          'thresholds': {
            'low_threshold': 1,
            'med_threshold': 2,
            'high_threshold': 3,
          },
          'flags': {
            'auth_required': true,
            'auth_revocable': false,
            'auth_immutable': false,
            'auth_clawback_enabled': true,
          },
          'balances': [
            {
              'asset_type': 'native',
              'balance': '1000.0000000',
              'buying_liabilities': '0.0000000',
              'selling_liabilities': '0.0000000',
            },
          ],
          'signers': [
            {
              'key': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
              'type': 'ed25519_public_key',
              'weight': 1,
            },
          ],
          'data': <String, dynamic>{},
          '_links': {
            'effects': {'href': '/accounts/test/effects'},
            'offers': {'href': '/accounts/test/offers'},
            'operations': {'href': '/accounts/test/operations'},
            'self': {'href': '/accounts/test'},
            'transactions': {'href': '/accounts/test/transactions'},
            'payments': {'href': '/accounts/test/payments'},
            'trades': {'href': '/accounts/test/trades'},
            'data': {'href': '/accounts/test/data/{key}', 'templated': true},
          },
          'sponsor': 'GBSPONSOR1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPL',
          'num_sponsoring': 2,
          'num_sponsored': 1,
          'sequence_ledger': 987650,
          'sequence_time': '2024-01-15T10:25:00Z',
        };

        final account = AccountResponse.fromJson(json);

        expect(account.accountId, equals('GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7'));
        expect(account.sequenceNumber, equals(BigInt.parse('123456789012345')));
        expect(account.pagingToken, equals('123456789012345'));
        expect(account.subentryCount, equals(5));
        expect(account.inflationDestination, equals('GBCD1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXA'));
        expect(account.homeDomain, equals('example.com'));
        expect(account.lastModifiedLedger, equals(987654));
        expect(account.lastModifiedTime, equals('2024-01-15T10:30:00Z'));
        expect(account.sponsor, equals('GBSPONSOR1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPL'));
        expect(account.numSponsoring, equals(2));
        expect(account.numSponsored, equals(1));
        expect(account.sequenceLedger, equals(987650));
        expect(account.sequenceTime, equals('2024-01-15T10:25:00Z'));
      });

      test('parses account response with null optional fields', () {
        final json = {
          'account_id': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'sequence': '100',
          'paging_token': '100',
          'subentry_count': 0,
          'last_modified_ledger': 10,
          'thresholds': {
            'low_threshold': 0,
            'med_threshold': 0,
            'high_threshold': 0,
          },
          'flags': {
            'auth_required': false,
            'auth_revocable': false,
            'auth_immutable': false,
            'auth_clawback_enabled': false,
          },
          'balances': [],
          'signers': [],
          'data': <String, dynamic>{},
          '_links': {
            'effects': {'href': '/accounts/test/effects'},
            'offers': {'href': '/accounts/test/offers'},
            'operations': {'href': '/accounts/test/operations'},
            'self': {'href': '/accounts/test'},
            'transactions': {'href': '/accounts/test/transactions'},
            'payments': {'href': '/accounts/test/payments'},
            'trades': {'href': '/accounts/test/trades'},
            'data': {'href': '/accounts/test/data/{key}', 'templated': true},
          },
          'num_sponsoring': 0,
          'num_sponsored': 0,
        };

        final account = AccountResponse.fromJson(json);

        expect(account.accountId, equals('GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7'));
        expect(account.inflationDestination, isNull);
        expect(account.homeDomain, isNull);
        expect(account.lastModifiedTime, isNull);
        expect(account.sponsor, isNull);
        expect(account.sequenceLedger, isNull);
        expect(account.sequenceTime, isNull);
        expect(account.balances, isEmpty);
        expect(account.signers, isEmpty);
      });

      test('parses multiple balances correctly', () {
        final json = {
          'account_id': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'sequence': '100',
          'paging_token': '100',
          'subentry_count': 3,
          'last_modified_ledger': 10,
          'thresholds': {
            'low_threshold': 0,
            'med_threshold': 0,
            'high_threshold': 0,
          },
          'flags': {
            'auth_required': false,
            'auth_revocable': false,
            'auth_immutable': false,
            'auth_clawback_enabled': false,
          },
          'balances': [
            {
              'asset_type': 'native',
              'balance': '500.0000000',
              'buying_liabilities': '10.0000000',
              'selling_liabilities': '5.0000000',
            },
            {
              'asset_type': 'credit_alphanum4',
              'asset_code': 'USD',
              'asset_issuer': 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX',
              'balance': '100.0000000',
              'limit': '1000.0000000',
              'buying_liabilities': '0.0000000',
              'selling_liabilities': '0.0000000',
              'is_authorized': true,
            },
            {
              'asset_type': 'credit_alphanum12',
              'asset_code': 'LONGCOIN',
              'asset_issuer': 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX',
              'balance': '250.5000000',
              'limit': '5000.0000000',
              'buying_liabilities': '1.0000000',
              'selling_liabilities': '2.0000000',
              'is_authorized': true,
              'is_authorized_to_maintain_liabilities': false,
            },
          ],
          'signers': [],
          'data': <String, dynamic>{},
          '_links': {
            'effects': {'href': '/accounts/test/effects'},
            'offers': {'href': '/accounts/test/offers'},
            'operations': {'href': '/accounts/test/operations'},
            'self': {'href': '/accounts/test'},
            'transactions': {'href': '/accounts/test/transactions'},
            'payments': {'href': '/accounts/test/payments'},
            'trades': {'href': '/accounts/test/trades'},
            'data': {'href': '/accounts/test/data/{key}', 'templated': true},
          },
          'num_sponsoring': 0,
          'num_sponsored': 0,
        };

        final account = AccountResponse.fromJson(json);

        expect(account.balances.length, equals(3));

        final nativeBalance = account.balances[0];
        expect(nativeBalance.assetType, equals('native'));
        expect(nativeBalance.balance, equals('500.0000000'));
        expect(nativeBalance.assetCode, isNull);
        expect(nativeBalance.assetIssuer, isNull);

        final usdBalance = account.balances[1];
        expect(usdBalance.assetType, equals('credit_alphanum4'));
        expect(usdBalance.assetCode, equals('USD'));
        expect(usdBalance.assetIssuer, equals('GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX'));
        expect(usdBalance.balance, equals('100.0000000'));
        expect(usdBalance.limit, equals('1000.0000000'));
        expect(usdBalance.isAuthorized, equals(true));

        final longcoinBalance = account.balances[2];
        expect(longcoinBalance.assetType, equals('credit_alphanum12'));
        expect(longcoinBalance.assetCode, equals('LONGCOIN'));
      });

      test('parses multiple signers correctly', () {
        final json = {
          'account_id': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'sequence': '100',
          'paging_token': '100',
          'subentry_count': 2,
          'last_modified_ledger': 10,
          'thresholds': {
            'low_threshold': 1,
            'med_threshold': 2,
            'high_threshold': 3,
          },
          'flags': {
            'auth_required': false,
            'auth_revocable': false,
            'auth_immutable': false,
            'auth_clawback_enabled': false,
          },
          'balances': [],
          'signers': [
            {
              'key': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
              'type': 'ed25519_public_key',
              'weight': 1,
            },
            {
              'key': 'GBCD1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXA',
              'type': 'ed25519_public_key',
              'weight': 2,
              'sponsor': 'GBSPONSOR1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPL',
            },
            {
              'key': 'TAQCSRX2RIDJNHFIFHWD63X7D7D6TRT5Y2S6E3TEMXTG5W3OECHZ2OG4',
              'type': 'preauth_tx',
              'weight': 1,
            },
          ],
          'data': <String, dynamic>{},
          '_links': {
            'effects': {'href': '/accounts/test/effects'},
            'offers': {'href': '/accounts/test/offers'},
            'operations': {'href': '/accounts/test/operations'},
            'self': {'href': '/accounts/test'},
            'transactions': {'href': '/accounts/test/transactions'},
            'payments': {'href': '/accounts/test/payments'},
            'trades': {'href': '/accounts/test/trades'},
            'data': {'href': '/accounts/test/data/{key}', 'templated': true},
          },
          'num_sponsoring': 0,
          'num_sponsored': 0,
        };

        final account = AccountResponse.fromJson(json);

        expect(account.signers.length, equals(3));

        final masterSigner = account.signers[0];
        expect(masterSigner.key, equals('GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7'));
        expect(masterSigner.type, equals('ed25519_public_key'));
        expect(masterSigner.weight, equals(1));
        expect(masterSigner.sponsor, isNull);

        final secondSigner = account.signers[1];
        expect(secondSigner.weight, equals(2));
        expect(secondSigner.sponsor, equals('GBSPONSOR1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPL'));

        final preauthSigner = account.signers[2];
        expect(preauthSigner.type, equals('preauth_tx'));
        expect(preauthSigner.weight, equals(1));
      });

      test('parses account data entries correctly', () {
        final json = {
          'account_id': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'sequence': '100',
          'paging_token': '100',
          'subentry_count': 2,
          'last_modified_ledger': 10,
          'thresholds': {
            'low_threshold': 0,
            'med_threshold': 0,
            'high_threshold': 0,
          },
          'flags': {
            'auth_required': false,
            'auth_revocable': false,
            'auth_immutable': false,
            'auth_clawback_enabled': false,
          },
          'balances': [],
          'signers': [],
          'data': {
            'test_key': 'dGVzdF92YWx1ZQ==',
            'another_key': 'YW5vdGhlcl92YWx1ZQ==',
          },
          '_links': {
            'effects': {'href': '/accounts/test/effects'},
            'offers': {'href': '/accounts/test/offers'},
            'operations': {'href': '/accounts/test/operations'},
            'self': {'href': '/accounts/test'},
            'transactions': {'href': '/accounts/test/transactions'},
            'payments': {'href': '/accounts/test/payments'},
            'trades': {'href': '/accounts/test/trades'},
            'data': {'href': '/accounts/test/data/{key}', 'templated': true},
          },
          'num_sponsoring': 0,
          'num_sponsored': 0,
        };

        final account = AccountResponse.fromJson(json);

        expect(account.data.length, equals(2));
        expect(account.data['test_key'], equals('dGVzdF92YWx1ZQ=='));
        expect(account.data['another_key'], equals('YW5vdGhlcl92YWx1ZQ=='));
        expect(account.data.keys, contains('test_key'));
        expect(account.data.keys, contains('another_key'));
      });
    });

    group('TransactionBuilderAccount interface', () {
      test('implements keypair property', () {
        final json = {
          'account_id': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'sequence': '100',
          'paging_token': '100',
          'subentry_count': 0,
          'last_modified_ledger': 10,
          'thresholds': {
            'low_threshold': 0,
            'med_threshold': 0,
            'high_threshold': 0,
          },
          'flags': {
            'auth_required': false,
            'auth_revocable': false,
            'auth_immutable': false,
            'auth_clawback_enabled': false,
          },
          'balances': [],
          'signers': [],
          'data': <String, dynamic>{},
          '_links': {
            'effects': {'href': '/accounts/test/effects'},
            'offers': {'href': '/accounts/test/offers'},
            'operations': {'href': '/accounts/test/operations'},
            'self': {'href': '/accounts/test'},
            'transactions': {'href': '/accounts/test/transactions'},
            'payments': {'href': '/accounts/test/payments'},
            'trades': {'href': '/accounts/test/trades'},
            'data': {'href': '/accounts/test/data/{key}', 'templated': true},
          },
          'num_sponsoring': 0,
          'num_sponsored': 0,
        };

        final account = AccountResponse.fromJson(json);
        final keypair = account.keypair;

        expect(keypair.accountId, equals('GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7'));
      });

      test('implements incrementedSequenceNumber correctly', () {
        final json = {
          'account_id': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'sequence': '100',
          'paging_token': '100',
          'subentry_count': 0,
          'last_modified_ledger': 10,
          'thresholds': {
            'low_threshold': 0,
            'med_threshold': 0,
            'high_threshold': 0,
          },
          'flags': {
            'auth_required': false,
            'auth_revocable': false,
            'auth_immutable': false,
            'auth_clawback_enabled': false,
          },
          'balances': [],
          'signers': [],
          'data': <String, dynamic>{},
          '_links': {
            'effects': {'href': '/accounts/test/effects'},
            'offers': {'href': '/accounts/test/offers'},
            'operations': {'href': '/accounts/test/operations'},
            'self': {'href': '/accounts/test'},
            'transactions': {'href': '/accounts/test/transactions'},
            'payments': {'href': '/accounts/test/payments'},
            'trades': {'href': '/accounts/test/trades'},
            'data': {'href': '/accounts/test/data/{key}', 'templated': true},
          },
          'num_sponsoring': 0,
          'num_sponsored': 0,
        };

        final account = AccountResponse.fromJson(json);

        expect(account.sequenceNumber, equals(BigInt.from(100)));
        expect(account.incrementedSequenceNumber, equals(BigInt.from(101)));
        expect(account.sequenceNumber, equals(BigInt.from(100)));
      });

      test('implements incrementSequenceNumber correctly', () {
        final json = {
          'account_id': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'sequence': '100',
          'paging_token': '100',
          'subentry_count': 0,
          'last_modified_ledger': 10,
          'thresholds': {
            'low_threshold': 0,
            'med_threshold': 0,
            'high_threshold': 0,
          },
          'flags': {
            'auth_required': false,
            'auth_revocable': false,
            'auth_immutable': false,
            'auth_clawback_enabled': false,
          },
          'balances': [],
          'signers': [],
          'data': <String, dynamic>{},
          '_links': {
            'effects': {'href': '/accounts/test/effects'},
            'offers': {'href': '/accounts/test/offers'},
            'operations': {'href': '/accounts/test/operations'},
            'self': {'href': '/accounts/test'},
            'transactions': {'href': '/accounts/test/transactions'},
            'payments': {'href': '/accounts/test/payments'},
            'trades': {'href': '/accounts/test/trades'},
            'data': {'href': '/accounts/test/data/{key}', 'templated': true},
          },
          'num_sponsoring': 0,
          'num_sponsored': 0,
        };

        final account = AccountResponse.fromJson(json);

        expect(account.sequenceNumber, equals(BigInt.from(100)));
        account.incrementSequenceNumber();
        expect(account.sequenceNumber, equals(BigInt.from(101)));
        account.incrementSequenceNumber();
        expect(account.sequenceNumber, equals(BigInt.from(102)));
      });

      test('implements muxedAccount correctly', () {
        final json = {
          'account_id': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'sequence': '100',
          'paging_token': '100',
          'subentry_count': 0,
          'last_modified_ledger': 10,
          'thresholds': {
            'low_threshold': 0,
            'med_threshold': 0,
            'high_threshold': 0,
          },
          'flags': {
            'auth_required': false,
            'auth_revocable': false,
            'auth_immutable': false,
            'auth_clawback_enabled': false,
          },
          'balances': [],
          'signers': [],
          'data': <String, dynamic>{},
          '_links': {
            'effects': {'href': '/accounts/test/effects'},
            'offers': {'href': '/accounts/test/offers'},
            'operations': {'href': '/accounts/test/operations'},
            'self': {'href': '/accounts/test'},
            'transactions': {'href': '/accounts/test/transactions'},
            'payments': {'href': '/accounts/test/payments'},
            'trades': {'href': '/accounts/test/trades'},
            'data': {'href': '/accounts/test/data/{key}', 'templated': true},
          },
          'num_sponsoring': 0,
          'num_sponsored': 0,
        };

        final account = AccountResponse.fromJson(json);
        final muxedAccount = account.muxedAccount;

        expect(muxedAccount.accountId, equals('GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7'));
        expect(muxedAccount.id, isNull);
      });
    });

    group('Thresholds', () {
      test('parses thresholds correctly', () {
        final json = {
          'low_threshold': 1,
          'med_threshold': 5,
          'high_threshold': 10,
        };

        final thresholds = Thresholds.fromJson(json);

        expect(thresholds.lowThreshold, equals(1));
        expect(thresholds.medThreshold, equals(5));
        expect(thresholds.highThreshold, equals(10));
      });

      test('parses zero thresholds correctly', () {
        final json = {
          'low_threshold': 0,
          'med_threshold': 0,
          'high_threshold': 0,
        };

        final thresholds = Thresholds.fromJson(json);

        expect(thresholds.lowThreshold, equals(0));
        expect(thresholds.medThreshold, equals(0));
        expect(thresholds.highThreshold, equals(0));
      });
    });

    group('Flags', () {
      test('parses all flags true', () {
        final json = {
          'auth_required': true,
          'auth_revocable': true,
          'auth_immutable': true,
          'auth_clawback_enabled': true,
        };

        final flags = Flags.fromJson(json);

        expect(flags.authRequired, isTrue);
        expect(flags.authRevocable, isTrue);
        expect(flags.authImmutable, isTrue);
        expect(flags.clawbackEnabled, isTrue);
      });

      test('parses all flags false', () {
        final json = {
          'auth_required': false,
          'auth_revocable': false,
          'auth_immutable': false,
          'auth_clawback_enabled': false,
        };

        final flags = Flags.fromJson(json);

        expect(flags.authRequired, isFalse);
        expect(flags.authRevocable, isFalse);
        expect(flags.authImmutable, isFalse);
        expect(flags.clawbackEnabled, isFalse);
      });
    });

    group('Balance', () {
      test('parses native balance correctly', () {
        final json = {
          'asset_type': 'native',
          'balance': '1000.0000000',
          'buying_liabilities': '10.0000000',
          'selling_liabilities': '5.0000000',
        };

        final balance = Balance.fromJson(json);

        expect(balance.assetType, equals('native'));
        expect(balance.balance, equals('1000.0000000'));
        expect(balance.buyingLiabilities, equals('10.0000000'));
        expect(balance.sellingLiabilities, equals('5.0000000'));
        expect(balance.assetCode, isNull);
        expect(balance.assetIssuer, isNull);
        expect(balance.limit, isNull);
      });

      test('parses credit asset balance with authorization flags', () {
        final json = {
          'asset_type': 'credit_alphanum4',
          'asset_code': 'USD',
          'asset_issuer': 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX',
          'balance': '100.0000000',
          'limit': '1000.0000000',
          'buying_liabilities': '0.0000000',
          'selling_liabilities': '0.0000000',
          'is_authorized': true,
          'is_authorized_to_maintain_liabilities': false,
          'is_clawback_enabled': true,
        };

        final balance = Balance.fromJson(json);

        expect(balance.assetType, equals('credit_alphanum4'));
        expect(balance.assetCode, equals('USD'));
        expect(balance.assetIssuer, equals('GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX'));
        expect(balance.balance, equals('100.0000000'));
        expect(balance.limit, equals('1000.0000000'));
        expect(balance.isAuthorized, isTrue);
        expect(balance.isAuthorizedToMaintainLiabilities, isFalse);
        expect(balance.isClawbackEnabled, isTrue);
      });

      test('parses liquidity pool shares balance', () {
        final json = {
          'asset_type': 'liquidity_pool_shares',
          'liquidity_pool_id': 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
          'balance': '500.0000000',
          'limit': '10000.0000000',
          'buying_liabilities': '0.0000000',
          'selling_liabilities': '0.0000000',
        };

        final balance = Balance.fromJson(json);

        expect(balance.assetType, equals('liquidity_pool_shares'));
        expect(balance.liquidityPoolId, equals('abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890'));
        expect(balance.balance, equals('500.0000000'));
      });

      test('returns correct Asset for native balance', () {
        final json = {
          'asset_type': 'native',
          'balance': '1000.0000000',
        };

        final balance = Balance.fromJson(json);
        final asset = balance.asset;

        expect(asset, isA<AssetTypeNative>());
        expect(asset.type, equals('native'));
      });

      test('returns correct Asset for credit asset balance', () {
        final json = {
          'asset_type': 'credit_alphanum4',
          'asset_code': 'USD',
          'asset_issuer': 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX',
          'balance': '100.0000000',
          'limit': '1000.0000000',
        };

        final balance = Balance.fromJson(json);
        final asset = balance.asset;

        expect(asset.type, equals('credit_alphanum4'));
      });
    });

    group('Signer', () {
      test('parses ed25519 public key signer', () {
        final json = {
          'key': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'type': 'ed25519_public_key',
          'weight': 1,
        };

        final signer = Signer.fromJson(json);

        expect(signer.key, equals('GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7'));
        expect(signer.type, equals('ed25519_public_key'));
        expect(signer.weight, equals(1));
        expect(signer.sponsor, isNull);
        expect(signer.accountId, equals('GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7'));
      });

      test('parses sponsored signer', () {
        final json = {
          'key': 'GBCD1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXA',
          'type': 'ed25519_public_key',
          'weight': 2,
          'sponsor': 'GBSPONSOR1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPL',
        };

        final signer = Signer.fromJson(json);

        expect(signer.weight, equals(2));
        expect(signer.sponsor, equals('GBSPONSOR1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPL'));
      });

      test('parses preauth_tx signer', () {
        final json = {
          'key': 'TAQCSRX2RIDJNHFIFHWD63X7D7D6TRT5Y2S6E3TEMXTG5W3OECHZ2OG4',
          'type': 'preauth_tx',
          'weight': 1,
        };

        final signer = Signer.fromJson(json);

        expect(signer.type, equals('preauth_tx'));
        expect(signer.weight, equals(1));
      });

      test('parses sha256_hash signer', () {
        final json = {
          'key': 'XDRPF6NZRR7EEVO7ESIWUDXHAOMM2QSKIQQBJK6I2FB7YKDZES5UCLWD',
          'type': 'sha256_hash',
          'weight': 1,
        };

        final signer = Signer.fromJson(json);

        expect(signer.type, equals('sha256_hash'));
        expect(signer.weight, equals(1));
      });
    });

    group('AccountResponseData', () {
      test('provides access to data entries', () {
        final dataMap = {
          'key1': 'dGVzdF92YWx1ZQ==',
          'key2': 'YW5vdGhlcl92YWx1ZQ==',
        };

        final data = AccountResponseData(dataMap);

        expect(data.length, equals(2));
        expect(data['key1'], equals('dGVzdF92YWx1ZQ=='));
        expect(data['key2'], equals('YW5vdGhlcl92YWx1ZQ=='));
      });

      test('provides keys iterable', () {
        final dataMap = {
          'key1': 'value1',
          'key2': 'value2',
        };

        final data = AccountResponseData(dataMap);

        expect(data.keys.length, equals(2));
        expect(data.keys, contains('key1'));
        expect(data.keys, contains('key2'));
      });

      test('handles empty data map', () {
        final dataMap = <String, dynamic>{};

        final data = AccountResponseData(dataMap);

        expect(data.length, equals(0));
        expect(data.keys, isEmpty);
      });

      test('decodes base64 data correctly', () {
        final dataMap = {
          'test': 'dGVzdF92YWx1ZQ==',
        };

        final data = AccountResponseData(dataMap);
        final decoded = data.getDecoded('test');

        expect(decoded, isNotNull);
        expect(String.fromCharCodes(decoded), equals('test_value'));
      });
    });

    group('AccountResponseLinks', () {
      test('parses all links correctly', () {
        final json = {
          'effects': {'href': '/accounts/test/effects'},
          'offers': {'href': '/accounts/test/offers'},
          'operations': {'href': '/accounts/test/operations'},
          'self': {'href': '/accounts/test'},
          'transactions': {'href': '/accounts/test/transactions'},
          'payments': {'href': '/accounts/test/payments'},
          'trades': {'href': '/accounts/test/trades'},
          'data': {'href': '/accounts/test/data/{key}', 'templated': true},
        };

        final links = AccountResponseLinks.fromJson(json);

        expect(links.effects.href, equals('/accounts/test/effects'));
        expect(links.offers.href, equals('/accounts/test/offers'));
        expect(links.operations.href, equals('/accounts/test/operations'));
        expect(links.self.href, equals('/accounts/test'));
        expect(links.transactions.href, equals('/accounts/test/transactions'));
        expect(links.payments.href, equals('/accounts/test/payments'));
        expect(links.trades.href, equals('/accounts/test/trades'));
        expect(links.data.href, equals('/accounts/test/data/{key}'));
      });
    });
  });
}
