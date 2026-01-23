import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('EffectResponse', () {
    group('fromJson type discrimination', () {
      test('parses type 0 as AccountCreatedEffectResponse', () {
        final json = {
          'id': '0000000012884905985-0000000001',
          'type_i': 0,
          'type': 'account_created',
          'created_at': '2024-01-15T10:00:00Z',
          'paging_token': '12884905985-1',
          'account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'starting_balance': '10000.0000000',
          '_links': {
            'operation': {'href': '/operations/123'},
            'precedes': {'href': '/effects?order=asc&cursor=123'},
            'succeeds': {'href': '/effects?order=desc&cursor=123'},
          },
        };

        final effect = EffectResponse.fromJson(json);

        expect(effect, isA<AccountCreatedEffectResponse>());
        expect(effect.type_i, equals(0));
        expect(effect.type, equals('account_created'));
      });

      test('throws exception for unknown effect type', () {
        final json = {
          'id': '123',
          'type_i': 9999,
          'type': 'unknown_type',
          'created_at': '2024-01-15T10:00:00Z',
          'paging_token': '123',
          'account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          '_links': {
            'operation': {'href': '/operations/123'},
            'precedes': {'href': '/effects?order=asc&cursor=123'},
            'succeeds': {'href': '/effects?order=desc&cursor=123'},
          },
        };

        expect(
          () => EffectResponse.fromJson(json),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('EffectResponseLinks', () {
      test('parses links from JSON', () {
        final json = {
          'operation': {'href': '/operations/123'},
          'precedes': {'href': '/effects?order=asc&cursor=123'},
          'succeeds': {'href': '/effects?order=desc&cursor=123'},
        };

        final links = EffectResponseLinks.fromJson(json);

        expect(links.operation.href, equals('/operations/123'));
        expect(links.precedes.href, equals('/effects?order=asc&cursor=123'));
        expect(links.succeeds.href, equals('/effects?order=desc&cursor=123'));
      });

      test('converts links to JSON', () {
        final links = EffectResponseLinks(
          Link('/operations/123', null),
          Link('/effects?order=asc&cursor=123', null),
          Link('/effects?order=desc&cursor=123', null),
        );

        final json = links.toJson();

        expect(json['operation'], isNotNull);
        expect(json['precedes'], isNotNull);
        expect(json['succeeds'], isNotNull);
      });
    });

    group('AssetAmount', () {
      test('parses native asset amount from JSON', () {
        final json = {
          'amount': '100.0000000',
          'asset': 'native',
        };

        final assetAmount = AssetAmount.fromJson(json);

        expect(assetAmount.amount, equals('100.0000000'));
        expect(assetAmount.asset, isA<AssetTypeNative>());
      });

      test('parses credit asset amount from JSON', () {
        final json = {
          'amount': '50.0000000',
          'asset': 'USD:GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
        };

        final assetAmount = AssetAmount.fromJson(json);

        expect(assetAmount.amount, equals('50.0000000'));
        expect(assetAmount.asset, isA<AssetTypeCreditAlphaNum4>());
        expect((assetAmount.asset as AssetTypeCreditAlphaNum4).code, equals('USD'));
      });
    });
  });

  group('Account Effects', () {
    group('AccountCreatedEffectResponse', () {
      test('parses account created effect with all fields', () {
        final json = {
          'id': '0000000012884905985-0000000001',
          'type_i': 0,
          'type': 'account_created',
          'created_at': '2024-01-15T10:00:00Z',
          'paging_token': '12884905985-1',
          'account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'starting_balance': '10000.0000000',
          '_links': {
            'operation': {'href': '/operations/123'},
            'precedes': {'href': '/effects?order=asc&cursor=123'},
            'succeeds': {'href': '/effects?order=desc&cursor=123'},
          },
        };

        final effect = AccountCreatedEffectResponse.fromJson(json);

        expect(effect.id, equals('0000000012884905985-0000000001'));
        expect(effect.type_i, equals(0));
        expect(effect.type, equals('account_created'));
        expect(effect.createdAt, equals('2024-01-15T10:00:00Z'));
        expect(effect.pagingToken, equals('12884905985-1'));
        expect(effect.account, equals('GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7'));
        expect(effect.startingBalance, equals('10000.0000000'));
        expect(effect.accountMuxed, isNull);
        expect(effect.accountMuxedId, isNull);
      });

      test('parses account created effect with muxed account', () {
        final json = {
          'id': '123',
          'type_i': 0,
          'type': 'account_created',
          'created_at': '2024-01-15T10:00:00Z',
          'paging_token': '123',
          'account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'account_muxed': 'MAAAAAAA...',
          'account_muxed_id': '12345',
          'starting_balance': '5000.0',
          '_links': {
            'operation': {'href': '/operations/123'},
            'precedes': {'href': '/effects?order=asc&cursor=123'},
            'succeeds': {'href': '/effects?order=desc&cursor=123'},
          },
        };

        final effect = AccountCreatedEffectResponse.fromJson(json);

        expect(effect.accountMuxed, equals('MAAAAAAA...'));
        expect(effect.accountMuxedId, equals('12345'));
      });
    });

    group('AccountRemovedEffectResponse', () {
      test('parses account removed effect', () {
        final json = {
          'id': '123',
          'type_i': 1,
          'type': 'account_removed',
          'created_at': '2024-01-15T10:00:00Z',
          'paging_token': '123',
          'account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          '_links': {
            'operation': {'href': '/operations/123'},
            'precedes': {'href': '/effects?order=asc&cursor=123'},
            'succeeds': {'href': '/effects?order=desc&cursor=123'},
          },
        };

        final effect = AccountRemovedEffectResponse.fromJson(json);

        expect(effect.type_i, equals(1));
        expect(effect.type, equals('account_removed'));
        expect(effect.account, equals('GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7'));
      });
    });

    group('AccountCreditedEffectResponse', () {
      test('parses account credited with native asset', () {
        final json = {
          'id': '123',
          'type_i': 2,
          'type': 'account_credited',
          'created_at': '2024-01-15T10:00:00Z',
          'paging_token': '123',
          'account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'amount': '100.0000000',
          'asset_type': 'native',
          '_links': {
            'operation': {'href': '/operations/123'},
            'precedes': {'href': '/effects?order=asc&cursor=123'},
            'succeeds': {'href': '/effects?order=desc&cursor=123'},
          },
        };

        final effect = AccountCreditedEffectResponse.fromJson(json);

        expect(effect.type_i, equals(2));
        expect(effect.type, equals('account_credited'));
        expect(effect.amount, equals('100.0000000'));
        expect(effect.assetType, equals('native'));
        expect(effect.assetCode, isNull);
        expect(effect.assetIssuer, isNull);
      });

      test('parses account credited with credit asset', () {
        final json = {
          'id': '123',
          'type_i': 2,
          'type': 'account_credited',
          'created_at': '2024-01-15T10:00:00Z',
          'paging_token': '123',
          'account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'amount': '50.0000000',
          'asset_type': 'credit_alphanum4',
          'asset_code': 'USD',
          'asset_issuer': 'GBCD1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXA',
          '_links': {
            'operation': {'href': '/operations/123'},
            'precedes': {'href': '/effects?order=asc&cursor=123'},
            'succeeds': {'href': '/effects?order=desc&cursor=123'},
          },
        };

        final effect = AccountCreditedEffectResponse.fromJson(json);

        expect(effect.amount, equals('50.0000000'));
        expect(effect.assetType, equals('credit_alphanum4'));
        expect(effect.assetCode, equals('USD'));
        expect(effect.assetIssuer, equals('GBCD1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXA'));
      });
    });

    group('AccountDebitedEffectResponse', () {
      test('parses account debited with native asset', () {
        final json = {
          'id': '123',
          'type_i': 3,
          'type': 'account_debited',
          'created_at': '2024-01-15T10:00:00Z',
          'paging_token': '123',
          'account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'amount': '25.0000000',
          'asset_type': 'native',
          '_links': {
            'operation': {'href': '/operations/123'},
            'precedes': {'href': '/effects?order=asc&cursor=123'},
            'succeeds': {'href': '/effects?order=desc&cursor=123'},
          },
        };

        final effect = AccountDebitedEffectResponse.fromJson(json);

        expect(effect.type_i, equals(3));
        expect(effect.type, equals('account_debited'));
        expect(effect.amount, equals('25.0000000'));
        expect(effect.assetType, equals('native'));
      });
    });

    group('AccountThresholdsUpdatedEffectResponse', () {
      test('parses account thresholds updated effect', () {
        final json = {
          'id': '123',
          'type_i': 4,
          'type': 'account_thresholds_updated',
          'created_at': '2024-01-15T10:00:00Z',
          'paging_token': '123',
          'account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'low_threshold': 1,
          'med_threshold': 2,
          'high_threshold': 3,
          '_links': {
            'operation': {'href': '/operations/123'},
            'precedes': {'href': '/effects?order=asc&cursor=123'},
            'succeeds': {'href': '/effects?order=desc&cursor=123'},
          },
        };

        final effect = AccountThresholdsUpdatedEffectResponse.fromJson(json);

        expect(effect.type_i, equals(4));
        expect(effect.type, equals('account_thresholds_updated'));
        expect(effect.lowThreshold, equals(1));
        expect(effect.medThreshold, equals(2));
        expect(effect.highThreshold, equals(3));
      });
    });

    group('AccountHomeDomainUpdatedEffectResponse', () {
      test('parses account home domain updated effect', () {
        final json = {
          'id': '123',
          'type_i': 5,
          'type': 'account_home_domain_updated',
          'created_at': '2024-01-15T10:00:00Z',
          'paging_token': '123',
          'account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'home_domain': 'example.com',
          '_links': {
            'operation': {'href': '/operations/123'},
            'precedes': {'href': '/effects?order=asc&cursor=123'},
            'succeeds': {'href': '/effects?order=desc&cursor=123'},
          },
        };

        final effect = AccountHomeDomainUpdatedEffectResponse.fromJson(json);

        expect(effect.type_i, equals(5));
        expect(effect.type, equals('account_home_domain_updated'));
        expect(effect.homeDomain, equals('example.com'));
      });
    });

    group('AccountFlagsUpdatedEffectResponse', () {
      test('parses account flags updated effect', () {
        final json = {
          'id': '123',
          'type_i': 6,
          'type': 'account_flags_updated',
          'created_at': '2024-01-15T10:00:00Z',
          'paging_token': '123',
          'account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'auth_required_flag': true,
          'auth_revokable_flag': false,
          '_links': {
            'operation': {'href': '/operations/123'},
            'precedes': {'href': '/effects?order=asc&cursor=123'},
            'succeeds': {'href': '/effects?order=desc&cursor=123'},
          },
        };

        final effect = AccountFlagsUpdatedEffectResponse.fromJson(json);

        expect(effect.type_i, equals(6));
        expect(effect.type, equals('account_flags_updated'));
        expect(effect.authRequiredFlag, isTrue);
        expect(effect.authRevokableFlag, isFalse);
      });
    });

    group('AccountInflationDestinationUpdatedEffectResponse', () {
      test('parses account inflation destination updated effect', () {
        final json = {
          'id': '123',
          'type_i': 7,
          'type': 'account_inflation_destination_updated',
          'created_at': '2024-01-15T10:00:00Z',
          'paging_token': '123',
          'account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          '_links': {
            'operation': {'href': '/operations/123'},
            'precedes': {'href': '/effects?order=asc&cursor=123'},
            'succeeds': {'href': '/effects?order=desc&cursor=123'},
          },
        };

        final effect = AccountInflationDestinationUpdatedEffectResponse.fromJson(json);

        expect(effect.type_i, equals(7));
        expect(effect.type, equals('account_inflation_destination_updated'));
      });
    });
  });

  group('Signer Effects', () {
    group('SignerCreatedEffectResponse', () {
      test('parses signer created effect', () {
        final json = {
          'id': '123',
          'type_i': 10,
          'type': 'signer_created',
          'created_at': '2024-01-15T10:00:00Z',
          'paging_token': '123',
          'account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'weight': 5,
          'public_key': 'GBCD1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXA',
          'key': 'GBCD1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXA',
          '_links': {
            'operation': {'href': '/operations/123'},
            'precedes': {'href': '/effects?order=asc&cursor=123'},
            'succeeds': {'href': '/effects?order=desc&cursor=123'},
          },
        };

        final effect = SignerCreatedEffectResponse.fromJson(json);

        expect(effect.type_i, equals(10));
        expect(effect.type, equals('signer_created'));
        expect(effect.weight, equals(5));
        expect(effect.publicKey, equals('GBCD1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXA'));
        expect(effect.key, equals('GBCD1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXA'));
      });
    });

    group('SignerRemovedEffectResponse', () {
      test('parses signer removed effect', () {
        final json = {
          'id': '123',
          'type_i': 11,
          'type': 'signer_removed',
          'created_at': '2024-01-15T10:00:00Z',
          'paging_token': '123',
          'account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'weight': 0,
          'public_key': 'GBCD1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXA',
          'key': 'GBCD1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXA',
          '_links': {
            'operation': {'href': '/operations/123'},
            'precedes': {'href': '/effects?order=asc&cursor=123'},
            'succeeds': {'href': '/effects?order=desc&cursor=123'},
          },
        };

        final effect = SignerRemovedEffectResponse.fromJson(json);

        expect(effect.type_i, equals(11));
        expect(effect.type, equals('signer_removed'));
        expect(effect.weight, equals(0));
      });
    });

    group('SignerUpdatedEffectResponse', () {
      test('parses signer updated effect', () {
        final json = {
          'id': '123',
          'type_i': 12,
          'type': 'signer_updated',
          'created_at': '2024-01-15T10:00:00Z',
          'paging_token': '123',
          'account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'weight': 10,
          'public_key': 'GBCD1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXA',
          'key': 'GBCD1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXA',
          '_links': {
            'operation': {'href': '/operations/123'},
            'precedes': {'href': '/effects?order=asc&cursor=123'},
            'succeeds': {'href': '/effects?order=desc&cursor=123'},
          },
        };

        final effect = SignerUpdatedEffectResponse.fromJson(json);

        expect(effect.type_i, equals(12));
        expect(effect.type, equals('signer_updated'));
        expect(effect.weight, equals(10));
      });
    });
  });

  group('Trustline Effects', () {
    group('TrustlineCreatedEffectResponse', () {
      test('parses trustline created effect', () {
        final json = {
          'id': '123',
          'type_i': 20,
          'type': 'trustline_created',
          'created_at': '2024-01-15T10:00:00Z',
          'paging_token': '123',
          'account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'asset_type': 'credit_alphanum4',
          'asset_code': 'USD',
          'asset_issuer': 'GBCD1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXA',
          'limit': '1000.0000000',
          '_links': {
            'operation': {'href': '/operations/123'},
            'precedes': {'href': '/effects?order=asc&cursor=123'},
            'succeeds': {'href': '/effects?order=desc&cursor=123'},
          },
        };

        final effect = TrustlineCreatedEffectResponse.fromJson(json);

        expect(effect.type_i, equals(20));
        expect(effect.type, equals('trustline_created'));
        expect(effect.assetType, equals('credit_alphanum4'));
        expect(effect.assetCode, equals('USD'));
        expect(effect.assetIssuer, equals('GBCD1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXA'));
        expect(effect.limit, equals('1000.0000000'));
      });
    });

    group('TrustlineRemovedEffectResponse', () {
      test('parses trustline removed effect', () {
        final json = {
          'id': '123',
          'type_i': 21,
          'type': 'trustline_removed',
          'created_at': '2024-01-15T10:00:00Z',
          'paging_token': '123',
          'account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'asset_type': 'credit_alphanum4',
          'asset_code': 'USD',
          'asset_issuer': 'GBCD1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXA',
          'limit': '0.0000000',
          '_links': {
            'operation': {'href': '/operations/123'},
            'precedes': {'href': '/effects?order=asc&cursor=123'},
            'succeeds': {'href': '/effects?order=desc&cursor=123'},
          },
        };

        final effect = TrustlineRemovedEffectResponse.fromJson(json);

        expect(effect.type_i, equals(21));
        expect(effect.type, equals('trustline_removed'));
      });
    });

    group('TrustlineUpdatedEffectResponse', () {
      test('parses trustline updated effect', () {
        final json = {
          'id': '123',
          'type_i': 22,
          'type': 'trustline_updated',
          'created_at': '2024-01-15T10:00:00Z',
          'paging_token': '123',
          'account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'asset_type': 'credit_alphanum4',
          'asset_code': 'USD',
          'asset_issuer': 'GBCD1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXA',
          'limit': '2000.0000000',
          '_links': {
            'operation': {'href': '/operations/123'},
            'precedes': {'href': '/effects?order=asc&cursor=123'},
            'succeeds': {'href': '/effects?order=desc&cursor=123'},
          },
        };

        final effect = TrustlineUpdatedEffectResponse.fromJson(json);

        expect(effect.type_i, equals(22));
        expect(effect.type, equals('trustline_updated'));
        expect(effect.limit, equals('2000.0000000'));
      });
    });

    group('TrustlineAuthorizedEffectResponse', () {
      test('parses trustline authorized effect', () {
        final json = {
          'id': '123',
          'type_i': 23,
          'type': 'trustline_authorized',
          'created_at': '2024-01-15T10:00:00Z',
          'paging_token': '123',
          'account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'trustor': 'GBCD1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXA',
          'asset_type': 'credit_alphanum4',
          'asset_code': 'USD',
          '_links': {
            'operation': {'href': '/operations/123'},
            'precedes': {'href': '/effects?order=asc&cursor=123'},
            'succeeds': {'href': '/effects?order=desc&cursor=123'},
          },
        };

        final effect = TrustlineAuthorizedEffectResponse.fromJson(json);

        expect(effect.type_i, equals(23));
        expect(effect.type, equals('trustline_authorized'));
        expect(effect.trustor, equals('GBCD1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXA'));
        expect(effect.assetType, equals('credit_alphanum4'));
        expect(effect.assetCode, equals('USD'));
      });
    });

    group('TrustlineDeauthorizedEffectResponse', () {
      test('parses trustline deauthorized effect', () {
        final json = {
          'id': '123',
          'type_i': 24,
          'type': 'trustline_deauthorized',
          'created_at': '2024-01-15T10:00:00Z',
          'paging_token': '123',
          'account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'trustor': 'GBCD1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXA',
          'asset_type': 'credit_alphanum4',
          'asset_code': 'USD',
          '_links': {
            'operation': {'href': '/operations/123'},
            'precedes': {'href': '/effects?order=asc&cursor=123'},
            'succeeds': {'href': '/effects?order=desc&cursor=123'},
          },
        };

        final effect = TrustlineDeauthorizedEffectResponse.fromJson(json);

        expect(effect.type_i, equals(24));
        expect(effect.type, equals('trustline_deauthorized'));
      });
    });

    group('TrustlineAuthorizedToMaintainLiabilitiesEffectResponse', () {
      test('parses trustline authorized to maintain liabilities effect', () {
        final json = {
          'id': '123',
          'type_i': 25,
          'type': 'trustline_authorized_to_maintain_liabilities',
          'created_at': '2024-01-15T10:00:00Z',
          'paging_token': '123',
          'account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'trustor': 'GBCD1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXA',
          'asset_type': 'credit_alphanum4',
          'asset_code': 'USD',
          '_links': {
            'operation': {'href': '/operations/123'},
            'precedes': {'href': '/effects?order=asc&cursor=123'},
            'succeeds': {'href': '/effects?order=desc&cursor=123'},
          },
        };

        final effect = TrustlineAuthorizedToMaintainLiabilitiesEffectResponse.fromJson(json);

        expect(effect.type_i, equals(25));
        expect(effect.type, equals('trustline_authorized_to_maintain_liabilities'));
      });
    });

    group('TrustLineFlagsUpdatedEffectResponse', () {
      test('parses trustline flags updated effect', () {
        final json = {
          'id': '123',
          'type_i': 26,
          'type': 'trustline_flags_updated',
          'created_at': '2024-01-15T10:00:00Z',
          'paging_token': '123',
          'account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'trustor': 'GBCD1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXA',
          'asset_type': 'credit_alphanum4',
          'asset_code': 'USD',
          'authorized_flag': true,
          'authorized_to_maintain_liabilities_flag': false,
          'clawback_enabled_flag': true,
          '_links': {
            'operation': {'href': '/operations/123'},
            'precedes': {'href': '/effects?order=asc&cursor=123'},
            'succeeds': {'href': '/effects?order=desc&cursor=123'},
          },
        };

        final effect = TrustLineFlagsUpdatedEffectResponse.fromJson(json);

        expect(effect.type_i, equals(26));
        expect(effect.type, equals('trustline_flags_updated'));
        expect(effect.authorizedFlag, isTrue);
        expect(effect.authorizedToMaintainLiabilitiesFlag, isFalse);
        expect(effect.clawbackEnabledFlag, isTrue);
      });
    });
  });

  group('Trade Effects', () {
    group('OfferCreatedEffectResponse', () {
      test('parses offer created effect', () {
        final json = {
          'id': '123',
          'type_i': 30,
          'type': 'offer_created',
          'created_at': '2024-01-15T10:00:00Z',
          'paging_token': '123',
          'account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          '_links': {
            'operation': {'href': '/operations/123'},
            'precedes': {'href': '/effects?order=asc&cursor=123'},
            'succeeds': {'href': '/effects?order=desc&cursor=123'},
          },
        };

        final effect = OfferCreatedEffectResponse.fromJson(json);

        expect(effect.type_i, equals(30));
        expect(effect.type, equals('offer_created'));
      });
    });

    group('OfferRemovedEffectResponse', () {
      test('parses offer removed effect', () {
        final json = {
          'id': '123',
          'type_i': 31,
          'type': 'offer_removed',
          'created_at': '2024-01-15T10:00:00Z',
          'paging_token': '123',
          'account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          '_links': {
            'operation': {'href': '/operations/123'},
            'precedes': {'href': '/effects?order=asc&cursor=123'},
            'succeeds': {'href': '/effects?order=desc&cursor=123'},
          },
        };

        final effect = OfferRemovedEffectResponse.fromJson(json);

        expect(effect.type_i, equals(31));
        expect(effect.type, equals('offer_removed'));
      });
    });

    group('OfferUpdatedEffectResponse', () {
      test('parses offer updated effect', () {
        final json = {
          'id': '123',
          'type_i': 32,
          'type': 'offer_updated',
          'created_at': '2024-01-15T10:00:00Z',
          'paging_token': '123',
          'account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          '_links': {
            'operation': {'href': '/operations/123'},
            'precedes': {'href': '/effects?order=asc&cursor=123'},
            'succeeds': {'href': '/effects?order=desc&cursor=123'},
          },
        };

        final effect = OfferUpdatedEffectResponse.fromJson(json);

        expect(effect.type_i, equals(32));
        expect(effect.type, equals('offer_updated'));
      });
    });

    group('TradeEffectResponse', () {
      test('parses trade effect with complete fields', () {
        final json = {
          'id': '123',
          'type_i': 33,
          'type': 'trade',
          'created_at': '2024-01-15T10:00:00Z',
          'paging_token': '123',
          'account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'seller': 'GBCD1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXA',
          'offer_id': '12345',
          'sold_amount': '100.0000000',
          'sold_asset_type': 'native',
          'bought_amount': '50.0000000',
          'bought_asset_type': 'credit_alphanum4',
          'bought_asset_code': 'USD',
          'bought_asset_issuer': 'GBISSUER1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMP',
          '_links': {
            'operation': {'href': '/operations/123'},
            'precedes': {'href': '/effects?order=asc&cursor=123'},
            'succeeds': {'href': '/effects?order=desc&cursor=123'},
          },
        };

        final effect = TradeEffectResponse.fromJson(json);

        expect(effect.type_i, equals(33));
        expect(effect.type, equals('trade'));
        expect(effect.seller, equals('GBCD1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXA'));
        expect(effect.offerId, equals('12345'));
        expect(effect.soldAmount, equals('100.0000000'));
        expect(effect.soldAssetType, equals('native'));
        expect(effect.boughtAmount, equals('50.0000000'));
        expect(effect.boughtAssetType, equals('credit_alphanum4'));
        expect(effect.boughtAssetCode, equals('USD'));
        expect(effect.boughtAssetIssuer, equals('GBISSUER1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMP'));
      });
    });
  });

  group('Data Effects', () {
    group('DataCreatedEffectResponse', () {
      test('parses data created effect', () {
        final json = {
          'id': '123',
          'type_i': 40,
          'type': 'data_created',
          'created_at': '2024-01-15T10:00:00Z',
          'paging_token': '123',
          'account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'name': 'my_data_key',
          'value': 'bXlfdmFsdWU=',
          '_links': {
            'operation': {'href': '/operations/123'},
            'precedes': {'href': '/effects?order=asc&cursor=123'},
            'succeeds': {'href': '/effects?order=desc&cursor=123'},
          },
        };

        final effect = DataCreatedEffectResponse.fromJson(json);

        expect(effect.type_i, equals(40));
        expect(effect.type, equals('data_created'));
        expect(effect.name, equals('my_data_key'));
        expect(effect.value, equals('bXlfdmFsdWU='));
      });
    });

    group('DataRemovedEffectResponse', () {
      test('parses data removed effect', () {
        final json = {
          'id': '123',
          'type_i': 41,
          'type': 'data_removed',
          'created_at': '2024-01-15T10:00:00Z',
          'paging_token': '123',
          'account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'name': 'my_data_key',
          '_links': {
            'operation': {'href': '/operations/123'},
            'precedes': {'href': '/effects?order=asc&cursor=123'},
            'succeeds': {'href': '/effects?order=desc&cursor=123'},
          },
        };

        final effect = DataRemovedEffectResponse.fromJson(json);

        expect(effect.type_i, equals(41));
        expect(effect.type, equals('data_removed'));
        expect(effect.name, equals('my_data_key'));
      });
    });

    group('DataUpdatedEffectResponse', () {
      test('parses data updated effect', () {
        final json = {
          'id': '123',
          'type_i': 42,
          'type': 'data_updated',
          'created_at': '2024-01-15T10:00:00Z',
          'paging_token': '123',
          'account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'name': 'my_data_key',
          'value': 'bmV3X3ZhbHVl',
          '_links': {
            'operation': {'href': '/operations/123'},
            'precedes': {'href': '/effects?order=asc&cursor=123'},
            'succeeds': {'href': '/effects?order=desc&cursor=123'},
          },
        };

        final effect = DataUpdatedEffectResponse.fromJson(json);

        expect(effect.type_i, equals(42));
        expect(effect.type, equals('data_updated'));
        expect(effect.name, equals('my_data_key'));
        expect(effect.value, equals('bmV3X3ZhbHVl'));
      });
    });
  });

  group('Misc Effects', () {
    group('SequenceBumpedEffectResponse', () {
      test('parses sequence bumped effect', () {
        final json = {
          'id': '123',
          'type_i': 43,
          'type': 'sequence_bumped',
          'created_at': '2024-01-15T10:00:00Z',
          'paging_token': '123',
          'account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'new_seq': 123456789,
          '_links': {
            'operation': {'href': '/operations/123'},
            'precedes': {'href': '/effects?order=asc&cursor=123'},
            'succeeds': {'href': '/effects?order=desc&cursor=123'},
          },
        };

        final effect = SequenceBumpedEffectResponse.fromJson(json);

        expect(effect.type_i, equals(43));
        expect(effect.type, equals('sequence_bumped'));
        expect(effect.newSequence, equals(123456789));
      });
    });
  });

  group('Claimable Balance Effects', () {
    group('ClaimableBalanceCreatedEffectResponse', () {
      test('parses claimable balance created effect', () {
        final json = {
          'id': '123',
          'type_i': 50,
          'type': 'claimable_balance_created',
          'created_at': '2024-01-15T10:00:00Z',
          'paging_token': '123',
          'account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'balance_id': '00000000da0d57da7d4850e7fc10d2a9d0ebc731f7afb40574c03395b17d49149b91f5be',
          'asset': 'USD:GBCD1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXA',
          'amount': '100.0000000',
          '_links': {
            'operation': {'href': '/operations/123'},
            'precedes': {'href': '/effects?order=asc&cursor=123'},
            'succeeds': {'href': '/effects?order=desc&cursor=123'},
          },
        };

        final effect = ClaimableBalanceCreatedEffectResponse.fromJson(json);

        expect(effect.type_i, equals(50));
        expect(effect.type, equals('claimable_balance_created'));
        expect(effect.balanceId, equals('00000000da0d57da7d4850e7fc10d2a9d0ebc731f7afb40574c03395b17d49149b91f5be'));
        expect(effect.amount, equals('100.0000000'));
        expect(effect.asset, isA<AssetTypeCreditAlphaNum4>());
      });
    });

    group('ClaimableBalanceClaimantCreatedEffectResponse', () {
      test('parses claimable balance claimant created effect', () {
        final json = {
          'id': '123',
          'type_i': 51,
          'type': 'claimable_balance_claimant_created',
          'created_at': '2024-01-15T10:00:00Z',
          'paging_token': '123',
          'account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'balance_id': '00000000da0d57da7d4850e7fc10d2a9d0ebc731f7afb40574c03395b17d49149b91f5be',
          'asset': 'USD:GBCD1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXA',
          'amount': '100.0000000',
          'predicate': {
            'unconditional': true,
          },
          '_links': {
            'operation': {'href': '/operations/123'},
            'precedes': {'href': '/effects?order=asc&cursor=123'},
            'succeeds': {'href': '/effects?order=desc&cursor=123'},
          },
        };

        final effect = ClaimableBalanceClaimantCreatedEffectResponse.fromJson(json);

        expect(effect.type_i, equals(51));
        expect(effect.type, equals('claimable_balance_claimant_created'));
        expect(effect.balanceId, equals('00000000da0d57da7d4850e7fc10d2a9d0ebc731f7afb40574c03395b17d49149b91f5be'));
        expect(effect.predicate, isNotNull);
      });
    });

    group('ClaimableBalanceClaimedEffectResponse', () {
      test('parses claimable balance claimed effect', () {
        final json = {
          'id': '123',
          'type_i': 52,
          'type': 'claimable_balance_claimed',
          'created_at': '2024-01-15T10:00:00Z',
          'paging_token': '123',
          'account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'balance_id': '00000000da0d57da7d4850e7fc10d2a9d0ebc731f7afb40574c03395b17d49149b91f5be',
          'asset': 'USD:GBCD1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXA',
          'amount': '100.0000000',
          '_links': {
            'operation': {'href': '/operations/123'},
            'precedes': {'href': '/effects?order=asc&cursor=123'},
            'succeeds': {'href': '/effects?order=desc&cursor=123'},
          },
        };

        final effect = ClaimableBalanceClaimedEffectResponse.fromJson(json);

        expect(effect.type_i, equals(52));
        expect(effect.type, equals('claimable_balance_claimed'));
        expect(effect.balanceId, equals('00000000da0d57da7d4850e7fc10d2a9d0ebc731f7afb40574c03395b17d49149b91f5be'));
      });
    });

    group('ClaimableBalanceClawedBackEffectResponse', () {
      test('parses claimable balance clawed back effect', () {
        final json = {
          'id': '123',
          'type_i': 80,
          'type': 'claimable_balance_clawed_back',
          'created_at': '2024-01-15T10:00:00Z',
          'paging_token': '123',
          'account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'balance_id': '00000000da0d57da7d4850e7fc10d2a9d0ebc731f7afb40574c03395b17d49149b91f5be',
          '_links': {
            'operation': {'href': '/operations/123'},
            'precedes': {'href': '/effects?order=asc&cursor=123'},
            'succeeds': {'href': '/effects?order=desc&cursor=123'},
          },
        };

        final effect = ClaimableBalanceClawedBackEffectResponse.fromJson(json);

        expect(effect.type_i, equals(80));
        expect(effect.type, equals('claimable_balance_clawed_back'));
        expect(effect.balanceId, equals('00000000da0d57da7d4850e7fc10d2a9d0ebc731f7afb40574c03395b17d49149b91f5be'));
      });
    });
  });

  group('Sponsorship Effects', () {
    group('AccountSponsorshipCreatedEffectResponse', () {
      test('parses account sponsorship created effect', () {
        final json = {
          'id': '123',
          'type_i': 60,
          'type': 'account_sponsorship_created',
          'created_at': '2024-01-15T10:00:00Z',
          'paging_token': '123',
          'account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'sponsor': 'GBSPONSOR1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPL',
          '_links': {
            'operation': {'href': '/operations/123'},
            'precedes': {'href': '/effects?order=asc&cursor=123'},
            'succeeds': {'href': '/effects?order=desc&cursor=123'},
          },
        };

        final effect = AccountSponsorshipCreatedEffectResponse.fromJson(json);

        expect(effect.type_i, equals(60));
        expect(effect.type, equals('account_sponsorship_created'));
        expect(effect.sponsor, equals('GBSPONSOR1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPL'));
      });
    });

    group('AccountSponsorshipUpdatedEffectResponse', () {
      test('parses account sponsorship updated effect', () {
        final json = {
          'id': '123',
          'type_i': 61,
          'type': 'account_sponsorship_updated',
          'created_at': '2024-01-15T10:00:00Z',
          'paging_token': '123',
          'account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'new_sponsor': 'GBNEW1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXA',
          'former_sponsor': 'GBOLD1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXA',
          '_links': {
            'operation': {'href': '/operations/123'},
            'precedes': {'href': '/effects?order=asc&cursor=123'},
            'succeeds': {'href': '/effects?order=desc&cursor=123'},
          },
        };

        final effect = AccountSponsorshipUpdatedEffectResponse.fromJson(json);

        expect(effect.type_i, equals(61));
        expect(effect.type, equals('account_sponsorship_updated'));
        expect(effect.newSponsor, equals('GBNEW1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXA'));
        expect(effect.formerSponsor, equals('GBOLD1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXA'));
      });
    });

    group('AccountSponsorshipRemovedEffectResponse', () {
      test('parses account sponsorship removed effect', () {
        final json = {
          'id': '123',
          'type_i': 62,
          'type': 'account_sponsorship_removed',
          'created_at': '2024-01-15T10:00:00Z',
          'paging_token': '123',
          'account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'former_sponsor': 'GBOLD1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXA',
          '_links': {
            'operation': {'href': '/operations/123'},
            'precedes': {'href': '/effects?order=asc&cursor=123'},
            'succeeds': {'href': '/effects?order=desc&cursor=123'},
          },
        };

        final effect = AccountSponsorshipRemovedEffectResponse.fromJson(json);

        expect(effect.type_i, equals(62));
        expect(effect.type, equals('account_sponsorship_removed'));
        expect(effect.formerSponsor, equals('GBOLD1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXA'));
      });
    });

    group('TrustlineSponsorshipCreatedEffectResponse', () {
      test('parses trustline sponsorship created effect', () {
        final json = {
          'id': '123',
          'type_i': 63,
          'type': 'trustline_sponsorship_created',
          'created_at': '2024-01-15T10:00:00Z',
          'paging_token': '123',
          'account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'sponsor': 'GBSPONSOR1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPL',
          'asset': 'USD:GBISSUER1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMP',
          'asset_type': 'credit_alphanum4',
          '_links': {
            'operation': {'href': '/operations/123'},
            'precedes': {'href': '/effects?order=asc&cursor=123'},
            'succeeds': {'href': '/effects?order=desc&cursor=123'},
          },
        };

        final effect = TrustlineSponsorshipCreatedEffectResponse.fromJson(json);

        expect(effect.type_i, equals(63));
        expect(effect.type, equals('trustline_sponsorship_created'));
        expect(effect.sponsor, equals('GBSPONSOR1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPL'));
        expect(effect.assetType, equals('credit_alphanum4'));
      });
    });

    group('DataSponsorshipCreatedEffectResponse', () {
      test('parses data sponsorship created effect', () {
        final json = {
          'id': '123',
          'type_i': 66,
          'type': 'data_sponsorship_created',
          'created_at': '2024-01-15T10:00:00Z',
          'paging_token': '123',
          'account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'sponsor': 'GBSPONSOR1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPL',
          'data_name': 'my_data_key',
          '_links': {
            'operation': {'href': '/operations/123'},
            'precedes': {'href': '/effects?order=asc&cursor=123'},
            'succeeds': {'href': '/effects?order=desc&cursor=123'},
          },
        };

        final effect = DataSponsorshipCreatedEffectResponse.fromJson(json);

        expect(effect.type_i, equals(66));
        expect(effect.type, equals('data_sponsorship_created'));
        expect(effect.sponsor, equals('GBSPONSOR1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPL'));
        expect(effect.dataName, equals('my_data_key'));
      });
    });

    group('ClaimableBalanceSponsorshipCreatedEffectResponse', () {
      test('parses claimable balance sponsorship created effect', () {
        final json = {
          'id': '123',
          'type_i': 69,
          'type': 'claimable_balance_sponsorship_created',
          'created_at': '2024-01-15T10:00:00Z',
          'paging_token': '123',
          'account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'sponsor': 'GBSPONSOR1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPL',
          'balance_id': '00000000da0d57da7d4850e7fc10d2a9d0ebc731f7afb40574c03395b17d49149b91f5be',
          '_links': {
            'operation': {'href': '/operations/123'},
            'precedes': {'href': '/effects?order=asc&cursor=123'},
            'succeeds': {'href': '/effects?order=desc&cursor=123'},
          },
        };

        final effect = ClaimableBalanceSponsorshipCreatedEffectResponse.fromJson(json);

        expect(effect.type_i, equals(69));
        expect(effect.type, equals('claimable_balance_sponsorship_created'));
        expect(effect.sponsor, equals('GBSPONSOR1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPL'));
        expect(effect.balanceId, equals('00000000da0d57da7d4850e7fc10d2a9d0ebc731f7afb40574c03395b17d49149b91f5be'));
      });
    });

    group('SignerSponsorshipCreatedEffectResponse', () {
      test('parses signer sponsorship created effect', () {
        final json = {
          'id': '123',
          'type_i': 72,
          'type': 'signer_sponsorship_created',
          'created_at': '2024-01-15T10:00:00Z',
          'paging_token': '123',
          'account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'sponsor': 'GBSPONSOR1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPL',
          'signer': 'GBSIGNER1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE',
          '_links': {
            'operation': {'href': '/operations/123'},
            'precedes': {'href': '/effects?order=asc&cursor=123'},
            'succeeds': {'href': '/effects?order=desc&cursor=123'},
          },
        };

        final effect = SignerSponsorshipCreatedEffectResponse.fromJson(json);

        expect(effect.type_i, equals(72));
        expect(effect.type, equals('signer_sponsorship_created'));
        expect(effect.sponsor, equals('GBSPONSOR1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPL'));
        expect(effect.signer, equals('GBSIGNER1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE'));
      });
    });
  });

  group('Liquidity Pool Effects', () {
    group('LiquidityPoolDepositedEffectResponse', () {
      test('parses liquidity pool deposited effect', () {
        final json = {
          'id': '123',
          'type_i': 90,
          'type': 'liquidity_pool_deposited',
          'created_at': '2024-01-15T10:00:00Z',
          'paging_token': '123',
          'account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'liquidity_pool': {
            'id': 'dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7',
            'fee_bp': 30,
            'type': 'constant_product',
            'total_trustlines': '100',
            'total_shares': '10000.0000000',
            'reserves': [
              {'amount': '5000.0000000', 'asset': 'native'},
              {'amount': '5000.0000000', 'asset': 'USD:GBCD1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXA'},
            ],
          },
          'reserves_deposited': [
            {'amount': '100.0000000', 'asset': 'native'},
            {'amount': '100.0000000', 'asset': 'USD:GBCD1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXA'},
          ],
          'shares_received': '200.0000000',
          '_links': {
            'operation': {'href': '/operations/123'},
            'precedes': {'href': '/effects?order=asc&cursor=123'},
            'succeeds': {'href': '/effects?order=desc&cursor=123'},
          },
        };

        final effect = LiquidityPoolDepositedEffectResponse.fromJson(json);

        expect(effect.type_i, equals(90));
        expect(effect.type, equals('liquidity_pool_deposited'));
        expect(effect.liquidityPool.poolId, equals('dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7'));
        expect(effect.liquidityPool.fee, equals(30));
        expect(effect.liquidityPool.type, equals('constant_product'));
        expect(effect.liquidityPool.totalTrustlines, equals('100'));
        expect(effect.liquidityPool.totalShares, equals('10000.0000000'));
        expect(effect.liquidityPool.reserves.length, equals(2));
        expect(effect.reservesDeposited.length, equals(2));
        expect(effect.sharesReceived, equals('200.0000000'));
      });
    });

    group('LiquidityPoolWithdrewEffectResponse', () {
      test('parses liquidity pool withdrew effect', () {
        final json = {
          'id': '123',
          'type_i': 91,
          'type': 'liquidity_pool_withdrew',
          'created_at': '2024-01-15T10:00:00Z',
          'paging_token': '123',
          'account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'liquidity_pool': {
            'id': 'dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7',
            'fee_bp': 30,
            'type': 'constant_product',
            'total_trustlines': '100',
            'total_shares': '9800.0000000',
            'reserves': [
              {'amount': '4900.0000000', 'asset': 'native'},
              {'amount': '4900.0000000', 'asset': 'USD:GBCD1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXA'},
            ],
          },
          'reserves_received': [
            {'amount': '100.0000000', 'asset': 'native'},
            {'amount': '100.0000000', 'asset': 'USD:GBCD1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXA'},
          ],
          'shares_redeemed': '200.0000000',
          '_links': {
            'operation': {'href': '/operations/123'},
            'precedes': {'href': '/effects?order=asc&cursor=123'},
            'succeeds': {'href': '/effects?order=desc&cursor=123'},
          },
        };

        final effect = LiquidityPoolWithdrewEffectResponse.fromJson(json);

        expect(effect.type_i, equals(91));
        expect(effect.type, equals('liquidity_pool_withdrew'));
        expect(effect.reservesReceived.length, equals(2));
        expect(effect.sharesRedeemed, equals('200.0000000'));
      });
    });

    group('LiquidityPoolTradeEffectResponse', () {
      test('parses liquidity pool trade effect', () {
        final json = {
          'id': '123',
          'type_i': 92,
          'type': 'liquidity_pool_trade',
          'created_at': '2024-01-15T10:00:00Z',
          'paging_token': '123',
          'account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'liquidity_pool': {
            'id': 'dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7',
            'fee_bp': 30,
            'type': 'constant_product',
            'total_trustlines': '100',
            'total_shares': '10000.0000000',
            'reserves': [
              {'amount': '5100.0000000', 'asset': 'native'},
              {'amount': '4900.0000000', 'asset': 'USD:GBCD1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXA'},
            ],
          },
          'sold': {'amount': '100.0000000', 'asset': 'native'},
          'bought': {'amount': '95.0000000', 'asset': 'USD:GBCD1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXA'},
          '_links': {
            'operation': {'href': '/operations/123'},
            'precedes': {'href': '/effects?order=asc&cursor=123'},
            'succeeds': {'href': '/effects?order=desc&cursor=123'},
          },
        };

        final effect = LiquidityPoolTradeEffectResponse.fromJson(json);

        expect(effect.type_i, equals(92));
        expect(effect.type, equals('liquidity_pool_trade'));
        expect(effect.sold.amount, equals('100.0000000'));
        expect(effect.bought.amount, equals('95.0000000'));
      });
    });

    group('LiquidityPoolCreatedEffectResponse', () {
      test('parses liquidity pool created effect', () {
        final json = {
          'id': '123',
          'type_i': 93,
          'type': 'liquidity_pool_created',
          'created_at': '2024-01-15T10:00:00Z',
          'paging_token': '123',
          'account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'liquidity_pool': {
            'id': 'dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7',
            'fee_bp': 30,
            'type': 'constant_product',
            'total_trustlines': '1',
            'total_shares': '0.0000000',
            'reserves': [
              {'amount': '0.0000000', 'asset': 'native'},
              {'amount': '0.0000000', 'asset': 'USD:GBCD1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXA'},
            ],
          },
          '_links': {
            'operation': {'href': '/operations/123'},
            'precedes': {'href': '/effects?order=asc&cursor=123'},
            'succeeds': {'href': '/effects?order=desc&cursor=123'},
          },
        };

        final effect = LiquidityPoolCreatedEffectResponse.fromJson(json);

        expect(effect.type_i, equals(93));
        expect(effect.type, equals('liquidity_pool_created'));
        expect(effect.liquidityPool.poolId, equals('dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7'));
      });
    });

    group('LiquidityPoolRemovedEffectResponse', () {
      test('parses liquidity pool removed effect', () {
        final json = {
          'id': '123',
          'type_i': 94,
          'type': 'liquidity_pool_removed',
          'created_at': '2024-01-15T10:00:00Z',
          'paging_token': '123',
          'account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'liquidity_pool_id': 'dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7',
          '_links': {
            'operation': {'href': '/operations/123'},
            'precedes': {'href': '/effects?order=asc&cursor=123'},
            'succeeds': {'href': '/effects?order=desc&cursor=123'},
          },
        };

        final effect = LiquidityPoolRemovedEffectResponse.fromJson(json);

        expect(effect.type_i, equals(94));
        expect(effect.type, equals('liquidity_pool_removed'));
        expect(effect.liquidityPoolId, equals('dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7'));
      });
    });

    group('LiquidityPoolRevokedEffectResponse', () {
      test('parses liquidity pool revoked effect', () {
        final json = {
          'id': '123',
          'type_i': 95,
          'type': 'liquidity_pool_revoked',
          'created_at': '2024-01-15T10:00:00Z',
          'paging_token': '123',
          'account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'liquidity_pool': {
            'id': 'dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7',
            'fee_bp': 30,
            'type': 'constant_product',
            'total_trustlines': '0',
            'total_shares': '0.0000000',
            'reserves': [
              {'amount': '0.0000000', 'asset': 'native'},
              {'amount': '0.0000000', 'asset': 'USD:GBCD1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXA'},
            ],
          },
          'reserves_revoked': [
            {
              'amount': '100.0000000',
              'asset': 'native',
              'claimable_balance_id': '00000000da0d57da7d4850e7fc10d2a9d0ebc731f7afb40574c03395b17d49149b91f5be',
            },
            {
              'amount': '100.0000000',
              'asset': 'USD:GBCD1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXA',
              'claimable_balance_id': '00000000da0d57da7d4850e7fc10d2a9d0ebc731f7afb40574c03395b17d49149b91f5bf',
            },
          ],
          'shares_revoked': '200.0000000',
          '_links': {
            'operation': {'href': '/operations/123'},
            'precedes': {'href': '/effects?order=asc&cursor=123'},
            'succeeds': {'href': '/effects?order=desc&cursor=123'},
          },
        };

        final effect = LiquidityPoolRevokedEffectResponse.fromJson(json);

        expect(effect.type_i, equals(95));
        expect(effect.type, equals('liquidity_pool_revoked'));
        expect(effect.reservesRevoked.length, equals(2));
        expect(effect.sharesRevoked, equals('200.0000000'));
        expect(effect.reservesRevoked[0].claimableBalanceId, isNotEmpty);
        expect(effect.reservesRevoked[1].claimableBalanceId, isNotEmpty);
      });
    });
  });

  group('Soroban Effects', () {
    group('ContractCreditedEffectResponse', () {
      test('parses contract credited effect', () {
        final json = {
          'id': '123',
          'type_i': 96,
          'type': 'contract_credited',
          'created_at': '2024-01-15T10:00:00Z',
          'paging_token': '123',
          'account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'contract': 'CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC',
          'amount': '100.0000000',
          'asset_type': 'native',
          '_links': {
            'operation': {'href': '/operations/123'},
            'precedes': {'href': '/effects?order=asc&cursor=123'},
            'succeeds': {'href': '/effects?order=desc&cursor=123'},
          },
        };

        final effect = ContractCreditedEffectResponse.fromJson(json);

        expect(effect.type_i, equals(96));
        expect(effect.type, equals('contract_credited'));
        expect(effect.contract, equals('CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC'));
        expect(effect.amount, equals('100.0000000'));
        expect(effect.assetType, equals('native'));
      });
    });

    group('ContractDebitedEffectResponse', () {
      test('parses contract debited effect', () {
        final json = {
          'id': '123',
          'type_i': 97,
          'type': 'contract_debited',
          'created_at': '2024-01-15T10:00:00Z',
          'paging_token': '123',
          'account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'contract': 'CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC',
          'amount': '50.0000000',
          'asset_type': 'credit_alphanum4',
          'asset_code': 'USD',
          'asset_issuer': 'GBCD1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXA',
          '_links': {
            'operation': {'href': '/operations/123'},
            'precedes': {'href': '/effects?order=asc&cursor=123'},
            'succeeds': {'href': '/effects?order=desc&cursor=123'},
          },
        };

        final effect = ContractDebitedEffectResponse.fromJson(json);

        expect(effect.type_i, equals(97));
        expect(effect.type, equals('contract_debited'));
        expect(effect.contract, equals('CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC'));
        expect(effect.amount, equals('50.0000000'));
        expect(effect.assetType, equals('credit_alphanum4'));
        expect(effect.assetCode, equals('USD'));
        expect(effect.assetIssuer, equals('GBCD1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXA'));
      });
    });
  });
}
