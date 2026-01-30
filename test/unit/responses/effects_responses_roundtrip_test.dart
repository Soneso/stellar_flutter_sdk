// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('Sponsorship Effect Responses', () {
    final testLinks = {
      '_links': {
        'operation': {'href': 'https://horizon.stellar.org/operations/123'},
        'precedes': {'href': 'https://horizon.stellar.org/effects?cursor=prev'},
        'succeeds': {'href': 'https://horizon.stellar.org/effects?cursor=next'},
      }
    };

    test('AccountSponsorshipCreatedEffectResponse fromJson', () {
      final json = {
        'id': 'effect-123',
        'type_i': 60,
        'type': 'account_sponsorship_created',
        'created_at': '2021-01-01T00:00:00Z',
        'paging_token': 'token-123',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'sponsor': 'GASPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ',
        ...testLinks,
      };

      final response = AccountSponsorshipCreatedEffectResponse.fromJson(json);

      expect(response.id, equals('effect-123'));
      expect(response.type_i, equals(60));
      expect(response.type, equals('account_sponsorship_created'));
      expect(response.createdAt, equals('2021-01-01T00:00:00Z'));
      expect(response.pagingToken, equals('token-123'));
      expect(
          response.account,
          equals(
              'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H'));
      expect(response.sponsor,
          equals('GASPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'));
      expect(response.links, isNotNull);
    });

    test('AccountSponsorshipUpdatedEffectResponse fromJson', () {
      final json = {
        'id': 'effect-124',
        'type_i': 61,
        'type': 'account_sponsorship_updated',
        'created_at': '2021-01-02T00:00:00Z',
        'paging_token': 'token-124',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'new_sponsor': 'GANEWSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ',
        'former_sponsor':
            'GAFORMERSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVW',
        ...testLinks,
      };

      final response = AccountSponsorshipUpdatedEffectResponse.fromJson(json);

      expect(response.id, equals('effect-124'));
      expect(response.type_i, equals(61));
      expect(response.type, equals('account_sponsorship_updated'));
      expect(response.newSponsor,
          equals('GANEWSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'));
      expect(response.formerSponsor,
          equals('GAFORMERSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVW'));
    });

    test('AccountSponsorshipRemovedEffectResponse fromJson', () {
      final json = {
        'id': 'effect-125',
        'type_i': 62,
        'type': 'account_sponsorship_removed',
        'created_at': '2021-01-03T00:00:00Z',
        'paging_token': 'token-125',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'former_sponsor':
            'GAFORMERSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVW',
        ...testLinks,
      };

      final response = AccountSponsorshipRemovedEffectResponse.fromJson(json);

      expect(response.id, equals('effect-125'));
      expect(response.type_i, equals(62));
      expect(response.type, equals('account_sponsorship_removed'));
      expect(response.formerSponsor,
          equals('GAFORMERSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVW'));
    });

    test('TrustlineSponsorshipCreatedEffectResponse fromJson - asset', () {
      final json = {
        'id': 'effect-126',
        'type_i': 63,
        'type': 'trustline_sponsorship_created',
        'created_at': '2021-01-04T00:00:00Z',
        'paging_token': 'token-126',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'sponsor': 'GASPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ',
        'asset': 'USD:GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX',
        'asset_type': 'credit_alphanum4',
        'liquidity_pool_id': null,
        ...testLinks,
      };

      final response =
          TrustlineSponsorshipCreatedEffectResponse.fromJson(json);

      expect(response.id, equals('effect-126'));
      expect(response.type_i, equals(63));
      expect(response.sponsor,
          equals('GASPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'));
      expect(response.asset,
          equals('USD:GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX'));
      expect(response.assetType, equals('credit_alphanum4'));
      expect(response.liquidityPoolId, isNull);
    });

    test('TrustlineSponsorshipCreatedEffectResponse fromJson - pool', () {
      final json = {
        'id': 'effect-127',
        'type_i': 63,
        'type': 'trustline_sponsorship_created',
        'created_at': '2021-01-05T00:00:00Z',
        'paging_token': 'token-127',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'sponsor': 'GASPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ',
        'asset': null,
        'asset_type': 'liquidity_pool_shares',
        'liquidity_pool_id': 'abc123def456',
        ...testLinks,
      };

      final response =
          TrustlineSponsorshipCreatedEffectResponse.fromJson(json);

      expect(response.assetType, equals('liquidity_pool_shares'));
      expect(response.asset, isNull);
      expect(response.liquidityPoolId, equals('abc123def456'));
    });

    test('TrustlineSponsorshipUpdatedEffectResponse fromJson', () {
      final json = {
        'id': 'effect-128',
        'type_i': 64,
        'type': 'trustline_sponsorship_updated',
        'created_at': '2021-01-06T00:00:00Z',
        'paging_token': 'token-128',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'new_sponsor': 'GANEWSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ',
        'former_sponsor':
            'GAFORMERSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVW',
        'asset': 'EUR:GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX',
        'asset_type': 'credit_alphanum4',
        'liquidity_pool_id': null,
        ...testLinks,
      };

      final response =
          TrustlineSponsorshipUpdatedEffectResponse.fromJson(json);

      expect(response.type_i, equals(64));
      expect(response.newSponsor,
          equals('GANEWSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'));
      expect(response.formerSponsor,
          equals('GAFORMERSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVW'));
      expect(response.asset,
          equals('EUR:GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX'));
    });

    test('TrustlineSponsorshipRemovedEffectResponse fromJson', () {
      final json = {
        'id': 'effect-129',
        'type_i': 65,
        'type': 'trustline_sponsorship_removed',
        'created_at': '2021-01-07T00:00:00Z',
        'paging_token': 'token-129',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'former_sponsor':
            'GAFORMERSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVW',
        'asset': 'GBP:GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX',
        'asset_type': 'credit_alphanum4',
        'liquidity_pool_id': null,
        ...testLinks,
      };

      final response =
          TrustlineSponsorshipRemovedEffectResponse.fromJson(json);

      expect(response.type_i, equals(65));
      expect(response.formerSponsor,
          equals('GAFORMERSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVW'));
      expect(response.asset,
          equals('GBP:GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX'));
    });

    test('DataSponsorshipCreatedEffectResponse fromJson', () {
      final json = {
        'id': 'effect-130',
        'type_i': 66,
        'type': 'data_sponsorship_created',
        'created_at': '2021-01-08T00:00:00Z',
        'paging_token': 'token-130',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'sponsor': 'GASPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ',
        'data_name': 'config_key',
        ...testLinks,
      };

      final response = DataSponsorshipCreatedEffectResponse.fromJson(json);

      expect(response.type_i, equals(66));
      expect(response.sponsor,
          equals('GASPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'));
      expect(response.dataName, equals('config_key'));
    });

    test('DataSponsorshipUpdatedEffectResponse fromJson', () {
      final json = {
        'id': 'effect-131',
        'type_i': 67,
        'type': 'data_sponsorship_updated',
        'created_at': '2021-01-09T00:00:00Z',
        'paging_token': 'token-131',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'new_sponsor': 'GANEWSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ',
        'former_sponsor':
            'GAFORMERSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVW',
        'data_name': 'config_key',
        ...testLinks,
      };

      final response = DataSponsorshipUpdatedEffectResponse.fromJson(json);

      expect(response.type_i, equals(67));
      expect(response.newSponsor,
          equals('GANEWSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'));
      expect(response.formerSponsor,
          equals('GAFORMERSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVW'));
      expect(response.dataName, equals('config_key'));
    });

    test('DataSponsorshipRemovedEffectResponse fromJson', () {
      final json = {
        'id': 'effect-132',
        'type_i': 68,
        'type': 'data_sponsorship_removed',
        'created_at': '2021-01-10T00:00:00Z',
        'paging_token': 'token-132',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'former_sponsor':
            'GAFORMERSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVW',
        'data_name': 'config_key',
        ...testLinks,
      };

      final response = DataSponsorshipRemovedEffectResponse.fromJson(json);

      expect(response.type_i, equals(68));
      expect(response.formerSponsor,
          equals('GAFORMERSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVW'));
      expect(response.dataName, equals('config_key'));
    });

    test('ClaimableBalanceSponsorshipCreatedEffectResponse fromJson', () {
      final json = {
        'id': 'effect-133',
        'type_i': 69,
        'type': 'claimable_balance_sponsorship_created',
        'created_at': '2021-01-11T00:00:00Z',
        'paging_token': 'token-133',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'sponsor': 'GASPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ',
        'balance_id':
            '00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072',
        ...testLinks,
      };

      final response =
          ClaimableBalanceSponsorshipCreatedEffectResponse.fromJson(json);

      expect(response.type_i, equals(69));
      expect(response.sponsor,
          equals('GASPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'));
      expect(
          response.balanceId,
          equals(
              '00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072'));
    });

    test('ClaimableBalanceSponsorshipUpdatedEffectResponse fromJson', () {
      final json = {
        'id': 'effect-134',
        'type_i': 70,
        'type': 'claimable_balance_sponsorship_updated',
        'created_at': '2021-01-12T00:00:00Z',
        'paging_token': 'token-134',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'new_sponsor': 'GANEWSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ',
        'former_sponsor':
            'GAFORMERSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVW',
        'balance_id':
            '00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072',
        ...testLinks,
      };

      final response =
          ClaimableBalanceSponsorshipUpdatedEffectResponse.fromJson(json);

      expect(response.type_i, equals(70));
      expect(response.newSponsor,
          equals('GANEWSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'));
      expect(response.formerSponsor,
          equals('GAFORMERSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVW'));
      expect(
          response.balanceId,
          equals(
              '00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072'));
    });

    test('ClaimableBalanceSponsorshipRemovedEffectResponse fromJson', () {
      final json = {
        'id': 'effect-135',
        'type_i': 71,
        'type': 'claimable_balance_sponsorship_removed',
        'created_at': '2021-01-13T00:00:00Z',
        'paging_token': 'token-135',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'former_sponsor':
            'GAFORMERSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVW',
        'balance_id':
            '00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072',
        ...testLinks,
      };

      final response =
          ClaimableBalanceSponsorshipRemovedEffectResponse.fromJson(json);

      expect(response.type_i, equals(71));
      expect(response.formerSponsor,
          equals('GAFORMERSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVW'));
      expect(
          response.balanceId,
          equals(
              '00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072'));
    });

    test('SignerSponsorshipCreatedEffectResponse fromJson', () {
      final json = {
        'id': 'effect-136',
        'type_i': 72,
        'type': 'signer_sponsorship_created',
        'created_at': '2021-01-14T00:00:00Z',
        'paging_token': 'token-136',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'sponsor': 'GASPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ',
        'signer': 'GASIGNER123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ',
        ...testLinks,
      };

      final response = SignerSponsorshipCreatedEffectResponse.fromJson(json);

      expect(response.type_i, equals(72));
      expect(response.sponsor,
          equals('GASPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'));
      expect(response.signer,
          equals('GASIGNER123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'));
    });

    test('SignerSponsorshipUpdatedEffectResponse fromJson', () {
      final json = {
        'id': 'effect-137',
        'type_i': 73,
        'type': 'signer_sponsorship_updated',
        'created_at': '2021-01-15T00:00:00Z',
        'paging_token': 'token-137',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'new_sponsor': 'GANEWSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ',
        'former_sponsor':
            'GAFORMERSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVW',
        'signer': 'GASIGNER123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ',
        ...testLinks,
      };

      final response = SignerSponsorshipUpdatedEffectResponse.fromJson(json);

      expect(response.type_i, equals(73));
      expect(response.newSponsor,
          equals('GANEWSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'));
      expect(response.formerSponsor,
          equals('GAFORMERSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVW'));
      expect(response.signer,
          equals('GASIGNER123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'));
    });

    test('SignerSponsorshipRemovedEffectResponse fromJson', () {
      final json = {
        'id': 'effect-138',
        'type_i': 74,
        'type': 'signer_sponsorship_removed',
        'created_at': '2021-01-16T00:00:00Z',
        'paging_token': 'token-138',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'former_sponsor':
            'GAFORMERSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVW',
        'signer': 'GASIGNER123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ',
        ...testLinks,
      };

      final response = SignerSponsorshipRemovedEffectResponse.fromJson(json);

      expect(response.type_i, equals(74));
      expect(response.formerSponsor,
          equals('GAFORMERSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVW'));
      expect(response.signer,
          equals('GASIGNER123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'));
    });

    test('ClaimableBalanceClawedBackEffectResponse fromJson', () {
      final json = {
        'id': 'effect-139',
        'type_i': 80,
        'type': 'claimable_balance_clawed_back',
        'created_at': '2021-01-17T00:00:00Z',
        'paging_token': 'token-139',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'balance_id':
            '00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072',
        ...testLinks,
      };

      final response =
          ClaimableBalanceClawedBackEffectResponse.fromJson(json);

      expect(response.type_i, equals(80));
      expect(
          response.balanceId,
          equals(
              '00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072'));
    });
  });

  group('Account Effect Responses', () {
    final testLinks = {
      '_links': {
        'operation': {'href': 'https://horizon.stellar.org/operations/123'},
        'precedes': {'href': 'https://horizon.stellar.org/effects?cursor=prev'},
        'succeeds': {'href': 'https://horizon.stellar.org/effects?cursor=next'},
      }
    };

    test('AccountCreatedEffectResponse fromJson', () {
      final json = {
        'id': 'effect-200',
        'type_i': 0,
        'type': 'account_created',
        'created_at': '2021-02-01T00:00:00Z',
        'paging_token': 'token-200',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'starting_balance': '10.0000000',
        ...testLinks,
      };

      final response = AccountCreatedEffectResponse.fromJson(json);

      expect(response.type_i, equals(0));
      expect(response.type, equals('account_created'));
      expect(response.startingBalance, equals('10.0000000'));
    });

    test('AccountRemovedEffectResponse fromJson', () {
      final json = {
        'id': 'effect-201',
        'type_i': 1,
        'type': 'account_removed',
        'created_at': '2021-02-02T00:00:00Z',
        'paging_token': 'token-201',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        ...testLinks,
      };

      final response = AccountRemovedEffectResponse.fromJson(json);

      expect(response.type_i, equals(1));
      expect(response.type, equals('account_removed'));
    });

    test('AccountCreditedEffectResponse fromJson - native', () {
      final json = {
        'id': 'effect-202',
        'type_i': 2,
        'type': 'account_credited',
        'created_at': '2021-02-03T00:00:00Z',
        'paging_token': 'token-202',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'amount': '100.0000000',
        'asset_type': 'native',
        'asset_code': null,
        'asset_issuer': null,
        ...testLinks,
      };

      final response = AccountCreditedEffectResponse.fromJson(json);

      expect(response.type_i, equals(2));
      expect(response.amount, equals('100.0000000'));
      expect(response.assetType, equals('native'));
      expect(response.assetCode, isNull);
      expect(response.assetIssuer, isNull);
      expect(response.asset.type, equals('native'));
    });

    test('AccountCreditedEffectResponse fromJson - credit', () {
      final json = {
        'id': 'effect-203',
        'type_i': 2,
        'type': 'account_credited',
        'created_at': '2021-02-04T00:00:00Z',
        'paging_token': 'token-203',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'amount': '50.0000000',
        'asset_type': 'credit_alphanum4',
        'asset_code': 'USD',
        'asset_issuer':
            'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX',
        ...testLinks,
      };

      final response = AccountCreditedEffectResponse.fromJson(json);

      expect(response.amount, equals('50.0000000'));
      expect(response.assetType, equals('credit_alphanum4'));
      expect(response.assetCode, equals('USD'));
      expect(response.assetIssuer,
          equals('GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX'));
      expect((response.asset as AssetTypeCreditAlphaNum).code, equals('USD'));
    });

    test('AccountDebitedEffectResponse fromJson - native', () {
      final json = {
        'id': 'effect-204',
        'type_i': 3,
        'type': 'account_debited',
        'created_at': '2021-02-05T00:00:00Z',
        'paging_token': 'token-204',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'amount': '25.0000000',
        'asset_type': 'native',
        'asset_code': null,
        'asset_issuer': null,
        ...testLinks,
      };

      final response = AccountDebitedEffectResponse.fromJson(json);

      expect(response.type_i, equals(3));
      expect(response.amount, equals('25.0000000'));
      expect(response.assetType, equals('native'));
      expect(response.asset.type, equals('native'));
    });

    test('AccountThresholdsUpdatedEffectResponse fromJson', () {
      final json = {
        'id': 'effect-205',
        'type_i': 4,
        'type': 'account_thresholds_updated',
        'created_at': '2021-02-06T00:00:00Z',
        'paging_token': 'token-205',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'low_threshold': 1,
        'med_threshold': 2,
        'high_threshold': 3,
        ...testLinks,
      };

      final response = AccountThresholdsUpdatedEffectResponse.fromJson(json);

      expect(response.type_i, equals(4));
      expect(response.lowThreshold, equals(1));
      expect(response.medThreshold, equals(2));
      expect(response.highThreshold, equals(3));
    });

    test('AccountHomeDomainUpdatedEffectResponse fromJson', () {
      final json = {
        'id': 'effect-206',
        'type_i': 5,
        'type': 'account_home_domain_updated',
        'created_at': '2021-02-07T00:00:00Z',
        'paging_token': 'token-206',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'home_domain': 'example.com',
        ...testLinks,
      };

      final response = AccountHomeDomainUpdatedEffectResponse.fromJson(json);

      expect(response.type_i, equals(5));
      expect(response.homeDomain, equals('example.com'));
    });

    test('AccountFlagsUpdatedEffectResponse fromJson', () {
      final json = {
        'id': 'effect-207',
        'type_i': 6,
        'type': 'account_flags_updated',
        'created_at': '2021-02-08T00:00:00Z',
        'paging_token': 'token-207',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'auth_required_flag': true,
        'auth_revokable_flag': false,
        ...testLinks,
      };

      final response = AccountFlagsUpdatedEffectResponse.fromJson(json);

      expect(response.type_i, equals(6));
      expect(response.authRequiredFlag, isTrue);
      expect(response.authRevokableFlag, isFalse);
    });
  });

  group('Trade Effect Responses', () {
    final testLinks = {
      '_links': {
        'operation': {'href': 'https://horizon.stellar.org/operations/123'},
        'precedes': {'href': 'https://horizon.stellar.org/effects?cursor=prev'},
        'succeeds': {'href': 'https://horizon.stellar.org/effects?cursor=next'},
      }
    };

    test('TradeEffectResponse fromJson - native to credit', () {
      final json = {
        'id': 'effect-300',
        'type_i': 33,
        'type': 'trade',
        'created_at': '2021-03-01T00:00:00Z',
        'paging_token': 'token-300',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'seller': 'GASELLER123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ',
        'seller_muxed': null,
        'seller_muxed_id': null,
        'offer_id': '12345',
        'sold_amount': '100.0000000',
        'sold_asset_type': 'native',
        'sold_asset_code': null,
        'sold_asset_issuer': null,
        'bought_amount': '50.0000000',
        'bought_asset_type': 'credit_alphanum4',
        'bought_asset_code': 'USD',
        'bought_asset_issuer':
            'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX',
        ...testLinks,
      };

      final response = TradeEffectResponse.fromJson(json);

      expect(response.type_i, equals(33));
      expect(response.seller,
          equals('GASELLER123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'));
      expect(response.offerId, equals('12345'));
      expect(response.soldAmount, equals('100.0000000'));
      expect(response.soldAssetType, equals('native'));
      expect(response.boughtAmount, equals('50.0000000'));
      expect(response.boughtAssetCode, equals('USD'));
      expect(response.soldAsset.type, equals('native'));
      expect(
          (response.boughtAsset as AssetTypeCreditAlphaNum).code, equals('USD'));
    });

    test('TradeEffectResponse fromJson - credit to credit', () {
      final json = {
        'id': 'effect-301',
        'type_i': 33,
        'type': 'trade',
        'created_at': '2021-03-02T00:00:00Z',
        'paging_token': 'token-301',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'seller': 'GASELLER123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ',
        'seller_muxed': null,
        'seller_muxed_id': null,
        'offer_id': '67890',
        'sold_amount': '200.0000000',
        'sold_asset_type': 'credit_alphanum4',
        'sold_asset_code': 'EUR',
        'sold_asset_issuer':
            'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX',
        'bought_amount': '220.0000000',
        'bought_asset_type': 'credit_alphanum4',
        'bought_asset_code': 'USD',
        'bought_asset_issuer':
            'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX',
        ...testLinks,
      };

      final response = TradeEffectResponse.fromJson(json);

      expect(response.soldAmount, equals('200.0000000'));
      expect(response.soldAssetCode, equals('EUR'));
      expect(response.boughtAmount, equals('220.0000000'));
      expect(response.boughtAssetCode, equals('USD'));
      expect((response.soldAsset as AssetTypeCreditAlphaNum).code, equals('EUR'));
      expect(
          (response.boughtAsset as AssetTypeCreditAlphaNum).code, equals('USD'));
    });
  });

  group('Claimable Balance Effect Responses', () {
    final testLinks = {
      '_links': {
        'operation': {'href': 'https://horizon.stellar.org/operations/123'},
        'precedes': {'href': 'https://horizon.stellar.org/effects?cursor=prev'},
        'succeeds': {'href': 'https://horizon.stellar.org/effects?cursor=next'},
      }
    };

    test('ClaimableBalanceCreatedEffectResponse fromJson', () {
      final json = {
        'id': 'effect-400',
        'type_i': 50,
        'type': 'claimable_balance_created',
        'created_at': '2021-04-01T00:00:00Z',
        'paging_token': 'token-400',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'balance_id':
            '00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072',
        'asset': 'native',
        'amount': '100.0000000',
        ...testLinks,
      };

      final response = ClaimableBalanceCreatedEffectResponse.fromJson(json);

      expect(response.type_i, equals(50));
      expect(
          response.balanceId,
          equals(
              '00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072'));
      expect(response.asset.type, equals('native'));
      expect(response.amount, equals('100.0000000'));
    });

    test('ClaimableBalanceClaimantCreatedEffectResponse fromJson', () {
      final json = {
        'id': 'effect-401',
        'type_i': 51,
        'type': 'claimable_balance_claimant_created',
        'created_at': '2021-04-02T00:00:00Z',
        'paging_token': 'token-401',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'balance_id':
            '00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072',
        'asset': 'native',
        'amount': '100.0000000',
        'predicate': {'unconditional': true},
        ...testLinks,
      };

      final response =
          ClaimableBalanceClaimantCreatedEffectResponse.fromJson(json);

      expect(response.type_i, equals(51));
      expect(response.amount, equals('100.0000000'));
      expect(response.predicate, isNotNull);
    });

    test('ClaimableBalanceClaimedEffectResponse fromJson', () {
      final json = {
        'id': 'effect-402',
        'type_i': 52,
        'type': 'claimable_balance_claimed',
        'created_at': '2021-04-03T00:00:00Z',
        'paging_token': 'token-402',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'balance_id':
            '00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072',
        'asset': 'native',
        'amount': '100.0000000',
        ...testLinks,
      };

      final response = ClaimableBalanceClaimedEffectResponse.fromJson(json);

      expect(response.type_i, equals(52));
      expect(response.amount, equals('100.0000000'));
    });
  });

  group('Liquidity Pool Effect Responses', () {
    final testLinks = {
      '_links': {
        'operation': {'href': 'https://horizon.stellar.org/operations/123'},
        'precedes': {'href': 'https://horizon.stellar.org/effects?cursor=prev'},
        'succeeds': {'href': 'https://horizon.stellar.org/effects?cursor=next'},
      }
    };

    test('LiquidityPoolDepositedEffectResponse fromJson', () {
      final json = {
        'id': 'effect-500',
        'type_i': 90,
        'type': 'liquidity_pool_deposited',
        'created_at': '2021-05-01T00:00:00Z',
        'paging_token': 'token-500',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'liquidity_pool': {
          'id': 'pool-123',
          'fee_bp': 30,
          'type': 'constant_product',
          'total_trustlines': '100',
          'total_shares': '1000.0000000',
          'reserves': [
            {'asset': 'native', 'amount': '500.0000000'},
            {
              'asset':
                  'USD:GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX',
              'amount': '500.0000000'
            }
          ]
        },
        'reserves_deposited': [
          {'asset': 'native', 'amount': '10.0000000'},
          {
            'asset':
                'USD:GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX',
            'amount': '10.0000000'
          }
        ],
        'shares_received': '20.0000000',
        ...testLinks,
      };

      final response = LiquidityPoolDepositedEffectResponse.fromJson(json);

      expect(response.type_i, equals(90));
      expect(response.liquidityPool.poolId, equals('pool-123'));
      expect(response.liquidityPool.fee, equals(30));
      expect(response.reservesDeposited.length, equals(2));
      expect(response.sharesReceived, equals('20.0000000'));
    });

    test('LiquidityPoolWithdrewEffectResponse fromJson', () {
      final json = {
        'id': 'effect-501',
        'type_i': 91,
        'type': 'liquidity_pool_withdrew',
        'created_at': '2021-05-02T00:00:00Z',
        'paging_token': 'token-501',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'liquidity_pool': {
          'id': 'pool-123',
          'fee_bp': 30,
          'type': 'constant_product',
          'total_trustlines': '99',
          'total_shares': '980.0000000',
          'reserves': [
            {'asset': 'native', 'amount': '490.0000000'},
            {
              'asset':
                  'USD:GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX',
              'amount': '490.0000000'
            }
          ]
        },
        'reserves_received': [
          {'asset': 'native', 'amount': '10.0000000'},
          {
            'asset':
                'USD:GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX',
            'amount': '10.0000000'
          }
        ],
        'shares_redeemed': '20.0000000',
        ...testLinks,
      };

      final response = LiquidityPoolWithdrewEffectResponse.fromJson(json);

      expect(response.type_i, equals(91));
      expect(response.sharesRedeemed, equals('20.0000000'));
      expect(response.reservesReceived.length, equals(2));
    });

    test('LiquidityPoolTradeEffectResponse fromJson', () {
      final json = {
        'id': 'effect-502',
        'type_i': 92,
        'type': 'liquidity_pool_trade',
        'created_at': '2021-05-03T00:00:00Z',
        'paging_token': 'token-502',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'liquidity_pool': {
          'id': 'pool-123',
          'fee_bp': 30,
          'type': 'constant_product',
          'total_trustlines': '99',
          'total_shares': '980.0000000',
          'reserves': [
            {'asset': 'native', 'amount': '495.0000000'},
            {
              'asset':
                  'USD:GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX',
              'amount': '485.0000000'
            }
          ]
        },
        'sold': {'asset': 'native', 'amount': '5.0000000'},
        'bought': {
          'asset':
              'USD:GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX',
          'amount': '5.0000000'
        },
        ...testLinks,
      };

      final response = LiquidityPoolTradeEffectResponse.fromJson(json);

      expect(response.type_i, equals(92));
      expect(response.sold.amount, equals('5.0000000'));
      expect(response.bought.amount, equals('5.0000000'));
    });

    test('LiquidityPoolCreatedEffectResponse fromJson', () {
      final json = {
        'id': 'effect-503',
        'type_i': 93,
        'type': 'liquidity_pool_created',
        'created_at': '2021-05-04T00:00:00Z',
        'paging_token': 'token-503',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'liquidity_pool': {
          'id': 'pool-new',
          'fee_bp': 30,
          'type': 'constant_product',
          'total_trustlines': '1',
          'total_shares': '0.0000000',
          'reserves': [
            {'asset': 'native', 'amount': '0.0000000'},
            {
              'asset':
                  'EUR:GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX',
              'amount': '0.0000000'
            }
          ]
        },
        ...testLinks,
      };

      final response = LiquidityPoolCreatedEffectResponse.fromJson(json);

      expect(response.type_i, equals(93));
      expect(response.liquidityPool.poolId, equals('pool-new'));
      expect(response.liquidityPool.type, equals('constant_product'));
    });

    test('LiquidityPoolRemovedEffectResponse fromJson', () {
      final json = {
        'id': 'effect-504',
        'type_i': 94,
        'type': 'liquidity_pool_removed',
        'created_at': '2021-05-05T00:00:00Z',
        'paging_token': 'token-504',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'liquidity_pool_id': 'pool-removed',
        ...testLinks,
      };

      final response = LiquidityPoolRemovedEffectResponse.fromJson(json);

      expect(response.type_i, equals(94));
      expect(response.liquidityPoolId, equals('pool-removed'));
    });

    test('LiquidityPoolRevokedEffectResponse fromJson', () {
      final json = {
        'id': 'effect-505',
        'type_i': 95,
        'type': 'liquidity_pool_revoked',
        'created_at': '2021-05-06T00:00:00Z',
        'paging_token': 'token-505',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'liquidity_pool': {
          'id': 'pool-revoked',
          'fee_bp': 30,
          'type': 'constant_product',
          'total_trustlines': '98',
          'total_shares': '960.0000000',
          'reserves': [
            {'asset': 'native', 'amount': '480.0000000'},
            {
              'asset':
                  'USD:GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX',
              'amount': '480.0000000'
            }
          ]
        },
        'reserves_revoked': [
          {
            'asset': 'native',
            'amount': '10.0000000',
            'claimable_balance_id': 'balance-id-1'
          },
          {
            'asset':
                'USD:GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX',
            'amount': '10.0000000',
            'claimable_balance_id': 'balance-id-2'
          }
        ],
        'shares_revoked': '20.0000000',
        ...testLinks,
      };

      final response = LiquidityPoolRevokedEffectResponse.fromJson(json);

      expect(response.type_i, equals(95));
      expect(response.sharesRevoked, equals('20.0000000'));
      expect(response.reservesRevoked.length, equals(2));
      expect(response.reservesRevoked[0].claimableBalanceId,
          equals('balance-id-1'));
    });
  });

  group('Muxed Account Support', () {
    final testLinks = {
      '_links': {
        'operation': {'href': 'https://horizon.stellar.org/operations/123'},
        'precedes': {'href': 'https://horizon.stellar.org/effects?cursor=prev'},
        'succeeds': {'href': 'https://horizon.stellar.org/effects?cursor=next'},
      }
    };

    test('Effect with muxed account fields', () {
      final json = {
        'id': 'effect-600',
        'type_i': 2,
        'type': 'account_credited',
        'created_at': '2021-06-01T00:00:00Z',
        'paging_token': 'token-600',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'account_muxed': 'MAAAAAAAAAAAAAB7BQ2L7E5NBWMXDUCMZSIPOBKRDSBYVLMXGSSKF6YNPIB7Y77ITLVL6',
        'account_muxed_id': '123456789',
        'amount': '100.0000000',
        'asset_type': 'native',
        'asset_code': null,
        'asset_issuer': null,
        ...testLinks,
      };

      final response = AccountCreditedEffectResponse.fromJson(json);

      expect(response.accountMuxed,
          equals('MAAAAAAAAAAAAAB7BQ2L7E5NBWMXDUCMZSIPOBKRDSBYVLMXGSSKF6YNPIB7Y77ITLVL6'));
      expect(response.accountMuxedId, equals('123456789'));
    });

    test('TradeEffect with muxed seller', () {
      final json = {
        'id': 'effect-601',
        'type_i': 33,
        'type': 'trade',
        'created_at': '2021-06-02T00:00:00Z',
        'paging_token': 'token-601',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'seller': 'GASELLER123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ',
        'seller_muxed': 'MAAAAAAAAAAAAAB7BQ2L7E5NBWMXDUCMZSIPOBKRDSBYVLMXGSSKF6YNPIB7Y77ITLVL6',
        'seller_muxed_id': '987654321',
        'offer_id': '11111',
        'sold_amount': '10.0000000',
        'sold_asset_type': 'native',
        'sold_asset_code': null,
        'sold_asset_issuer': null,
        'bought_amount': '5.0000000',
        'bought_asset_type': 'native',
        'bought_asset_code': null,
        'bought_asset_issuer': null,
        ...testLinks,
      };

      final response = TradeEffectResponse.fromJson(json);

      expect(response.sellerMuxed,
          equals('MAAAAAAAAAAAAAB7BQ2L7E5NBWMXDUCMZSIPOBKRDSBYVLMXGSSKF6YNPIB7Y77ITLVL6'));
      expect(response.sellerMuxedId, equals('987654321'));
    });
  });

  group('Account Effects - Deep Coverage', () {
    final testLinks = {
      '_links': {
        'operation': {'href': 'https://horizon.stellar.org/operations/123'},
        'precedes': {'href': 'https://horizon.stellar.org/effects?cursor=prev'},
        'succeeds': {'href': 'https://horizon.stellar.org/effects?cursor=next'},
      }
    };

    test('AccountInflationDestinationUpdatedEffectResponse fromJson', () {
      final json = {
        'id': 'effect-inflation',
        'type_i': 7,
        'type': 'account_inflation_destination_updated',
        'created_at': '2021-01-01T00:00:00Z',
        'paging_token': 'token-inflation',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        ...testLinks,
      };

      final response =
          AccountInflationDestinationUpdatedEffectResponse.fromJson(json);

      expect(response.id, equals('effect-inflation'));
      expect(response.type_i, equals(7));
      expect(response.type, equals('account_inflation_destination_updated'));
    });

    test('AccountFlagsUpdatedEffectResponse with both flags', () {
      final json = {
        'id': 'effect-flags-all',
        'type_i': 6,
        'type': 'account_flags_updated',
        'created_at': '2021-01-01T00:00:00Z',
        'paging_token': 'token-flags',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'auth_required_flag': true,
        'auth_revokable_flag': true,
        ...testLinks,
      };

      final response = AccountFlagsUpdatedEffectResponse.fromJson(json);

      expect(response.authRequiredFlag, isTrue);
      expect(response.authRevokableFlag, isTrue);
    });

    test('AccountFlagsUpdatedEffectResponse with all flags false', () {
      final json = {
        'id': 'effect-flags-none',
        'type_i': 6,
        'type': 'account_flags_updated',
        'created_at': '2021-01-01T00:00:00Z',
        'paging_token': 'token-flags-none',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'auth_required_flag': false,
        'auth_revokable_flag': false,
        ...testLinks,
      };

      final response = AccountFlagsUpdatedEffectResponse.fromJson(json);

      expect(response.authRequiredFlag, isFalse);
      expect(response.authRevokableFlag, isFalse);
    });
  });

  group('Signer Effects', () {
    final testLinks = {
      '_links': {
        'operation': {'href': 'https://horizon.stellar.org/operations/123'},
        'precedes': {'href': 'https://horizon.stellar.org/effects?cursor=prev'},
        'succeeds': {'href': 'https://horizon.stellar.org/effects?cursor=next'},
      }
    };

    test('SignerCreatedEffectResponse fromJson', () {
      final json = {
        'id': 'effect-signer-created',
        'type_i': 10,
        'type': 'signer_created',
        'created_at': '2021-02-01T00:00:00Z',
        'paging_token': 'token-signer-created',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'weight': 5,
        'public_key': 'GASIGNER123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ',
        'key': 'signer_key',
        ...testLinks,
      };

      final response = SignerCreatedEffectResponse.fromJson(json);

      expect(response.type_i, equals(10));
      expect(response.weight, equals(5));
      expect(response.publicKey,
          equals('GASIGNER123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'));
      expect(response.key, equals('signer_key'));
    });

    test('SignerRemovedEffectResponse fromJson', () {
      final json = {
        'id': 'effect-signer-removed',
        'type_i': 11,
        'type': 'signer_removed',
        'created_at': '2021-02-02T00:00:00Z',
        'paging_token': 'token-signer-removed',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'weight': 0,
        'public_key': 'GASIGNER123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ',
        'key': 'removed_key',
        ...testLinks,
      };

      final response = SignerRemovedEffectResponse.fromJson(json);

      expect(response.type_i, equals(11));
      expect(response.weight, equals(0));
    });

    test('SignerUpdatedEffectResponse fromJson', () {
      final json = {
        'id': 'effect-signer-updated',
        'type_i': 12,
        'type': 'signer_updated',
        'created_at': '2021-02-03T00:00:00Z',
        'paging_token': 'token-signer-updated',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'weight': 10,
        'public_key': 'GASIGNER123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ',
        'key': 'updated_key',
        ...testLinks,
      };

      final response = SignerUpdatedEffectResponse.fromJson(json);

      expect(response.type_i, equals(12));
      expect(response.weight, equals(10));
    });
  });

  group('Trustline Effects', () {
    final testLinks = {
      '_links': {
        'operation': {'href': 'https://horizon.stellar.org/operations/123'},
        'precedes': {'href': 'https://horizon.stellar.org/effects?cursor=prev'},
        'succeeds': {'href': 'https://horizon.stellar.org/effects?cursor=next'},
      }
    };

    test('TrustlineCreatedEffectResponse fromJson', () {
      final json = {
        'id': 'effect-trustline-created',
        'type_i': 20,
        'type': 'trustline_created',
        'created_at': '2021-03-01T00:00:00Z',
        'paging_token': 'token-trustline-created',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'asset_type': 'credit_alphanum4',
        'asset_code': 'USD',
        'asset_issuer':
            'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX',
        'limit': '1000000.0000000',
        ...testLinks,
      };

      final response = TrustlineCreatedEffectResponse.fromJson(json);

      expect(response.type_i, equals(20));
      expect(response.assetCode, equals('USD'));
      expect(response.limit, equals('1000000.0000000'));
    });

    test('TrustlineRemovedEffectResponse fromJson', () {
      final json = {
        'id': 'effect-trustline-removed',
        'type_i': 21,
        'type': 'trustline_removed',
        'created_at': '2021-03-02T00:00:00Z',
        'paging_token': 'token-trustline-removed',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'asset_type': 'credit_alphanum4',
        'asset_code': 'EUR',
        'asset_issuer':
            'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX',
        'limit': '0.0000000',
        ...testLinks,
      };

      final response = TrustlineRemovedEffectResponse.fromJson(json);

      expect(response.type_i, equals(21));
      expect(response.assetCode, equals('EUR'));
    });

    test('TrustlineUpdatedEffectResponse fromJson', () {
      final json = {
        'id': 'effect-trustline-updated',
        'type_i': 22,
        'type': 'trustline_updated',
        'created_at': '2021-03-03T00:00:00Z',
        'paging_token': 'token-trustline-updated',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'asset_type': 'credit_alphanum4',
        'asset_code': 'GBP',
        'asset_issuer':
            'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX',
        'limit': '5000000.0000000',
        ...testLinks,
      };

      final response = TrustlineUpdatedEffectResponse.fromJson(json);

      expect(response.type_i, equals(22));
      expect(response.assetCode, equals('GBP'));
      expect(response.limit, equals('5000000.0000000'));
    });

    test('TrustlineAuthorizedEffectResponse fromJson', () {
      final json = {
        'id': 'effect-trustline-authorized',
        'type_i': 23,
        'type': 'trustline_authorized',
        'created_at': '2021-03-04T00:00:00Z',
        'paging_token': 'token-trustline-authorized',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'asset_type': 'credit_alphanum4',
        'asset_code': 'JPY',
        'asset_issuer':
            'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX',
        'trustor': 'GATRUSTEE123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ',
        ...testLinks,
      };

      final response = TrustlineAuthorizedEffectResponse.fromJson(json);

      expect(response.type_i, equals(23));
      expect(response.assetCode, equals('JPY'));
      expect(response.trustor,
          equals('GATRUSTEE123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'));
    });

    test('TrustlineDeauthorizedEffectResponse fromJson', () {
      final json = {
        'id': 'effect-trustline-deauthorized',
        'type_i': 24,
        'type': 'trustline_deauthorized',
        'created_at': '2021-03-05T00:00:00Z',
        'paging_token': 'token-trustline-deauthorized',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'asset_type': 'credit_alphanum4',
        'asset_code': 'CNY',
        'asset_issuer':
            'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX',
        'trustor': 'GATRUSTEE123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ',
        ...testLinks,
      };

      final response = TrustlineDeauthorizedEffectResponse.fromJson(json);

      expect(response.type_i, equals(24));
      expect(response.assetCode, equals('CNY'));
    });

    test('TrustlineAuthorizedToMaintainLiabilitiesEffectResponse fromJson',
        () {
      final json = {
        'id': 'effect-trustline-maintain-liabilities',
        'type_i': 25,
        'type': 'trustline_authorized_to_maintain_liabilities',
        'created_at': '2021-03-06T00:00:00Z',
        'paging_token': 'token-maintain-liabilities',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'asset_type': 'credit_alphanum4',
        'asset_code': 'INR',
        'asset_issuer':
            'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX',
        'trustor': 'GATRUSTEE123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ',
        ...testLinks,
      };

      final response =
          TrustlineAuthorizedToMaintainLiabilitiesEffectResponse.fromJson(json);

      expect(response.type_i, equals(25));
      expect(response.assetCode, equals('INR'));
    });

    test('TrustLineFlagsUpdatedEffectResponse fromJson', () {
      final json = {
        'id': 'effect-trustline-flags-updated',
        'type_i': 26,
        'type': 'trustline_flags_updated',
        'created_at': '2021-03-07T00:00:00Z',
        'paging_token': 'token-trustline-flags',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'asset_type': 'credit_alphanum4',
        'asset_code': 'BRL',
        'asset_issuer':
            'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX',
        'trustor': 'GATRUSTEE123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ',
        'authorized_flag': true,
        'clawback_enabled_flag': true,
        ...testLinks,
      };

      final response = TrustLineFlagsUpdatedEffectResponse.fromJson(json);

      expect(response.type_i, equals(26));
      expect(response.authorizedFlag, isTrue);
      expect(response.clawbackEnabledFlag, isTrue);
    });
  });

  group('Trading Effects', () {
    final testLinks = {
      '_links': {
        'operation': {'href': 'https://horizon.stellar.org/operations/123'},
        'precedes': {'href': 'https://horizon.stellar.org/effects?cursor=prev'},
        'succeeds': {'href': 'https://horizon.stellar.org/effects?cursor=next'},
      }
    };

    test('OfferCreatedEffectResponse fromJson', () {
      final json = {
        'id': 'effect-offer-created',
        'type_i': 30,
        'type': 'offer_created',
        'created_at': '2021-04-01T00:00:00Z',
        'paging_token': 'token-offer-created',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        ...testLinks,
      };

      final response = OfferCreatedEffectResponse.fromJson(json);

      expect(response.type_i, equals(30));
      expect(response.type, equals('offer_created'));
    });

    test('OfferRemovedEffectResponse fromJson', () {
      final json = {
        'id': 'effect-offer-removed',
        'type_i': 31,
        'type': 'offer_removed',
        'created_at': '2021-04-02T00:00:00Z',
        'paging_token': 'token-offer-removed',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        ...testLinks,
      };

      final response = OfferRemovedEffectResponse.fromJson(json);

      expect(response.type_i, equals(31));
      expect(response.type, equals('offer_removed'));
    });

    test('OfferUpdatedEffectResponse fromJson', () {
      final json = {
        'id': 'effect-offer-updated',
        'type_i': 32,
        'type': 'offer_updated',
        'created_at': '2021-04-03T00:00:00Z',
        'paging_token': 'token-offer-updated',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        ...testLinks,
      };

      final response = OfferUpdatedEffectResponse.fromJson(json);

      expect(response.type_i, equals(32));
      expect(response.type, equals('offer_updated'));
    });
  });

  group('Data Effects', () {
    final testLinks = {
      '_links': {
        'operation': {'href': 'https://horizon.stellar.org/operations/123'},
        'precedes': {'href': 'https://horizon.stellar.org/effects?cursor=prev'},
        'succeeds': {'href': 'https://horizon.stellar.org/effects?cursor=next'},
      }
    };

    test('DataCreatedEffectResponse fromJson', () {
      final json = {
        'id': 'effect-data-created',
        'type_i': 40,
        'type': 'data_entry_created',
        'created_at': '2021-05-01T00:00:00Z',
        'paging_token': 'token-data-created',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'name': 'config',
        'value': 'dGVzdF92YWx1ZQ==',
        ...testLinks,
      };

      final response = DataCreatedEffectResponse.fromJson(json);

      expect(response.type_i, equals(40));
      expect(response.name, equals('config'));
      expect(response.value, equals('dGVzdF92YWx1ZQ=='));
    });

    test('DataRemovedEffectResponse fromJson', () {
      final json = {
        'id': 'effect-data-removed',
        'type_i': 41,
        'type': 'data_entry_removed',
        'created_at': '2021-05-02T00:00:00Z',
        'paging_token': 'token-data-removed',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'name': 'old_config',
        ...testLinks,
      };

      final response = DataRemovedEffectResponse.fromJson(json);

      expect(response.type_i, equals(41));
      expect(response.name, equals('old_config'));
    });

    test('DataUpdatedEffectResponse fromJson', () {
      final json = {
        'id': 'effect-data-updated',
        'type_i': 42,
        'type': 'data_entry_updated',
        'created_at': '2021-05-03T00:00:00Z',
        'paging_token': 'token-data-updated',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'name': 'updated_config',
        'value': 'bmV3X3ZhbHVl',
        ...testLinks,
      };

      final response = DataUpdatedEffectResponse.fromJson(json);

      expect(response.type_i, equals(42));
      expect(response.name, equals('updated_config'));
      expect(response.value, equals('bmV3X3ZhbHVl'));
    });
  });

  group('Sequence Effects', () {
    final testLinks = {
      '_links': {
        'operation': {'href': 'https://horizon.stellar.org/operations/123'},
        'precedes': {'href': 'https://horizon.stellar.org/effects?cursor=prev'},
        'succeeds': {'href': 'https://horizon.stellar.org/effects?cursor=next'},
      }
    };

    test('SequenceBumpedEffectResponse fromJson', () {
      final json = {
        'id': 'effect-sequence-bumped',
        'type_i': 43,
        'type': 'sequence_bumped',
        'created_at': '2021-06-01T00:00:00Z',
        'paging_token': 'token-sequence-bumped',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'new_seq': 123456789,
        ...testLinks,
      };

      final response = SequenceBumpedEffectResponse.fromJson(json);

      expect(response.type_i, equals(43));
      expect(response.newSequence, equals(123456789));
    });
  });

  group('Soroban Effects', () {
    final testLinks = {
      '_links': {
        'operation': {'href': 'https://horizon.stellar.org/operations/123'},
        'precedes': {'href': 'https://horizon.stellar.org/effects?cursor=prev'},
        'succeeds': {'href': 'https://horizon.stellar.org/effects?cursor=next'},
      }
    };

    test('ContractCreditedEffectResponse fromJson', () {
      final json = {
        'id': 'effect-contract-credited',
        'type_i': 96,
        'type': 'contract_credited',
        'created_at': '2021-07-01T00:00:00Z',
        'paging_token': 'token-contract-credited',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'contract':
            'CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC',
        'asset_type': 'native',
        'amount': '100.0000000',
        ...testLinks,
      };

      final response = ContractCreditedEffectResponse.fromJson(json);

      expect(response.type_i, equals(96));
      expect(response.contract,
          equals('CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC'));
      expect(response.amount, equals('100.0000000'));
      expect(response.assetType, equals('native'));
    });

    test('ContractDebitedEffectResponse fromJson', () {
      final json = {
        'id': 'effect-contract-debited',
        'type_i': 97,
        'type': 'contract_debited',
        'created_at': '2021-07-02T00:00:00Z',
        'paging_token': 'token-contract-debited',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'contract':
            'CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC',
        'asset_type': 'credit_alphanum4',
        'asset_code': 'USDC',
        'asset_issuer':
            'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX',
        'amount': '50.0000000',
        ...testLinks,
      };

      final response = ContractDebitedEffectResponse.fromJson(json);

      expect(response.type_i, equals(97));
      expect(response.contract,
          equals('CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC'));
      expect(response.amount, equals('50.0000000'));
      expect(response.assetCode, equals('USDC'));
    });
  });

  group('EffectResponseLinks', () {
    test('fromJson parses all links correctly', () {
      final json = {
        'operation': {'href': 'https://horizon.stellar.org/operations/456'},
        'precedes': {'href': 'https://horizon.stellar.org/effects?cursor=789'},
        'succeeds': {'href': 'https://horizon.stellar.org/effects?cursor=012'},
      };

      final links = EffectResponseLinks.fromJson(json);

      expect(links.operation.href,
          equals('https://horizon.stellar.org/operations/456'));
      expect(links.precedes.href,
          equals('https://horizon.stellar.org/effects?cursor=789'));
      expect(links.succeeds.href,
          equals('https://horizon.stellar.org/effects?cursor=012'));
    });

    test('toJson converts links back to JSON', () {
      final link1 = Link.fromJson({'href': 'https://horizon.stellar.org/operations/123', 'templated': false});
      final link2 = Link.fromJson({'href': 'https://horizon.stellar.org/effects?cursor=prev', 'templated': false});
      final link3 = Link.fromJson({'href': 'https://horizon.stellar.org/effects?cursor=next', 'templated': false});

      final links = EffectResponseLinks(link1, link2, link3);

      final json = links.toJson();

      expect(json['operation'], isNotNull);
      expect(json['precedes'], isNotNull);
      expect(json['succeeds'], isNotNull);
    });
  });

  group('AssetAmount', () {
    test('fromJson with native asset', () {
      final json = {
        'amount': '100.0000000',
        'asset': 'native',
      };

      final assetAmount = AssetAmount.fromJson(json);

      expect(assetAmount.amount, equals('100.0000000'));
      expect(assetAmount.asset, isNotNull);
      expect(assetAmount.asset!.type, equals('native'));
    });

    test('fromJson with credit asset', () {
      final json = {
        'amount': '50.5000000',
        'asset':
            'USD:GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX',
      };

      final assetAmount = AssetAmount.fromJson(json);

      expect(assetAmount.amount, equals('50.5000000'));
      expect(assetAmount.asset, isNotNull);
      expect((assetAmount.asset as AssetTypeCreditAlphaNum).code, equals('USD'));
    });

    test('fromJson handles null asset', () {
      final json = {
        'amount': '0.0000000',
        'asset': null,
      };

      final assetAmount = AssetAmount.fromJson(json);

      expect(assetAmount.amount, equals('0.0000000'));
      expect(assetAmount.asset, isNull);
    });
  });

  group('EffectResponse factory', () {
    final testLinks = {
      '_links': {
        'operation': {'href': 'https://horizon.stellar.org/operations/123'},
        'precedes': {'href': 'https://horizon.stellar.org/effects?cursor=prev'},
        'succeeds': {'href': 'https://horizon.stellar.org/effects?cursor=next'},
      }
    };

    test('throws exception for unknown effect type', () {
      final json = {
        'id': 'unknown-effect',
        'type_i': 9999,
        'type': 'unknown_effect_type',
        'created_at': '2021-01-01T00:00:00Z',
        'paging_token': 'token-unknown',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        ...testLinks,
      };

      expect(() => EffectResponse.fromJson(json), throwsException);
    });
  });

  group('Effects Final Coverage Tests', () {
    group('EffectResponse Factory Tests - Core Coverage', () {
      // Test factory method for all effect types by their type_i discriminator

      test('fromJson creates AccountRemovedEffectResponse (type 1)', () {
        final json = {
          'id': 'effect_id',
          'type_i': 1,
          'type': 'account_removed',
          'created_at': '2024-01-01T00:00:00Z',
          'paging_token': 'token',
          'account': 'GABC123',
          '_links': {
            'operation': {'href': 'op_link'},
            'precedes': {'href': 'pre_link'},
            'succeeds': {'href': 'succ_link'},
          },
        };

        final effect = EffectResponse.fromJson(json);
        expect(effect, isA<AccountRemovedEffectResponse>());
      });

      test('fromJson creates AccountThresholdsUpdatedEffectResponse (type 4)', () {
        final json = {
          'id': 'effect_id',
          'type_i': 4,
          'type': 'account_thresholds_updated',
          'created_at': '2024-01-01T00:00:00Z',
          'paging_token': 'token',
          'account': 'GABC123',
          'low_threshold': 1,
          'med_threshold': 2,
          'high_threshold': 3,
          '_links': {
            'operation': {'href': 'op_link'},
            'precedes': {'href': 'pre_link'},
            'succeeds': {'href': 'succ_link'},
          },
        };

        final effect = EffectResponse.fromJson(json);
        expect(effect, isA<AccountThresholdsUpdatedEffectResponse>());
      });

      test('fromJson creates AccountHomeDomainUpdatedEffectResponse (type 5)', () {
        final json = {
          'id': 'effect_id',
          'type_i': 5,
          'type': 'account_home_domain_updated',
          'created_at': '2024-01-01T00:00:00Z',
          'paging_token': 'token',
          'account': 'GABC123',
          'home_domain': 'example.com',
          '_links': {
            'operation': {'href': 'op_link'},
            'precedes': {'href': 'pre_link'},
            'succeeds': {'href': 'succ_link'},
          },
        };

        final effect = EffectResponse.fromJson(json);
        expect(effect, isA<AccountHomeDomainUpdatedEffectResponse>());
      });

      test('fromJson creates AccountFlagsUpdatedEffectResponse (type 6)', () {
        final json = {
          'id': 'effect_id',
          'type_i': 6,
          'type': 'account_flags_updated',
          'created_at': '2024-01-01T00:00:00Z',
          'paging_token': 'token',
          'account': 'GABC123',
          '_links': {
            'operation': {'href': 'op_link'},
            'precedes': {'href': 'pre_link'},
            'succeeds': {'href': 'succ_link'},
          },
        };

        final effect = EffectResponse.fromJson(json);
        expect(effect, isA<AccountFlagsUpdatedEffectResponse>());
      });

      test('fromJson creates AccountInflationDestinationUpdatedEffectResponse (type 7)', () {
        final json = {
          'id': 'effect_id',
          'type_i': 7,
          'type': 'account_inflation_destination_updated',
          'created_at': '2024-01-01T00:00:00Z',
          'paging_token': 'token',
          'account': 'GABC123',
          '_links': {
            'operation': {'href': 'op_link'},
            'precedes': {'href': 'pre_link'},
            'succeeds': {'href': 'succ_link'},
          },
        };

        final effect = EffectResponse.fromJson(json);
        expect(effect, isA<AccountInflationDestinationUpdatedEffectResponse>());
      });

      test('fromJson creates SignerUpdatedEffectResponse (type 12)', () {
        final json = {
          'id': 'effect_id',
          'type_i': 12,
          'type': 'signer_updated',
          'created_at': '2024-01-01T00:00:00Z',
          'paging_token': 'token',
          'account': 'GABC123',
          'weight': 2,
          'public_key': 'GDEF456',
          'key': 'test_key',
          '_links': {
            'operation': {'href': 'op_link'},
            'precedes': {'href': 'pre_link'},
            'succeeds': {'href': 'succ_link'},
          },
        };

        final effect = EffectResponse.fromJson(json);
        expect(effect, isA<SignerUpdatedEffectResponse>());
      });

      test('fromJson creates TrustlineRemovedEffectResponse (type 21)', () {
        final json = {
          'id': 'effect_id',
          'type_i': 21,
          'type': 'trustline_removed',
          'created_at': '2024-01-01T00:00:00Z',
          'paging_token': 'token',
          'account': 'GABC123',
          'asset_type': 'credit_alphanum4',
          'asset_code': 'USD',
          'asset_issuer': 'GDEF456',
          'limit': '1000.0',
          '_links': {
            'operation': {'href': 'op_link'},
            'precedes': {'href': 'pre_link'},
            'succeeds': {'href': 'succ_link'},
          },
        };

        final effect = EffectResponse.fromJson(json);
        expect(effect, isA<TrustlineRemovedEffectResponse>());
      });

      test('fromJson creates TrustlineUpdatedEffectResponse (type 22)', () {
        final json = {
          'id': 'effect_id',
          'type_i': 22,
          'type': 'trustline_updated',
          'created_at': '2024-01-01T00:00:00Z',
          'paging_token': 'token',
          'account': 'GABC123',
          'asset_type': 'credit_alphanum4',
          'asset_code': 'USD',
          'asset_issuer': 'GDEF456',
          'limit': '1000.0',
          '_links': {
            'operation': {'href': 'op_link'},
            'precedes': {'href': 'pre_link'},
            'succeeds': {'href': 'succ_link'},
          },
        };

        final effect = EffectResponse.fromJson(json);
        expect(effect, isA<TrustlineUpdatedEffectResponse>());
      });

      test('fromJson creates TrustLineFlagsUpdatedEffectResponse (type 26)', () {
        final json = {
          'id': 'effect_id',
          'type_i': 26,
          'type': 'trustline_flags_updated',
          'created_at': '2024-01-01T00:00:00Z',
          'paging_token': 'token',
          'account': 'GABC123',
          'asset_type': 'credit_alphanum4',
          'asset_code': 'USD',
          'asset_issuer': 'GDEF456',
          'trustor': 'GABC123',
          '_links': {
            'operation': {'href': 'op_link'},
            'precedes': {'href': 'pre_link'},
            'succeeds': {'href': 'succ_link'},
          },
        };

        final effect = EffectResponse.fromJson(json);
        expect(effect, isA<TrustLineFlagsUpdatedEffectResponse>());
      });

      test('fromJson creates OfferRemovedEffectResponse (type 31)', () {
        final json = {
          'id': 'effect_id',
          'type_i': 31,
          'type': 'offer_removed',
          'created_at': '2024-01-01T00:00:00Z',
          'paging_token': 'token',
          'account': 'GABC123',
          '_links': {
            'operation': {'href': 'op_link'},
            'precedes': {'href': 'pre_link'},
            'succeeds': {'href': 'succ_link'},
          },
        };

        final effect = EffectResponse.fromJson(json);
        expect(effect, isA<OfferRemovedEffectResponse>());
      });

      test('fromJson creates OfferUpdatedEffectResponse (type 32)', () {
        final json = {
          'id': 'effect_id',
          'type_i': 32,
          'type': 'offer_updated',
          'created_at': '2024-01-01T00:00:00Z',
          'paging_token': 'token',
          'account': 'GABC123',
          '_links': {
            'operation': {'href': 'op_link'},
            'precedes': {'href': 'pre_link'},
            'succeeds': {'href': 'succ_link'},
          },
        };

        final effect = EffectResponse.fromJson(json);
        expect(effect, isA<OfferUpdatedEffectResponse>());
      });

      test('fromJson creates DataRemovedEffectResponse (type 41)', () {
        final json = {
          'id': 'effect_id',
          'type_i': 41,
          'type': 'data_removed',
          'created_at': '2024-01-01T00:00:00Z',
          'paging_token': 'token',
          'account': 'GABC123',
          'name': 'test_data_key',
          '_links': {
            'operation': {'href': 'op_link'},
            'precedes': {'href': 'pre_link'},
            'succeeds': {'href': 'succ_link'},
          },
        };

        final effect = EffectResponse.fromJson(json);
        expect(effect, isA<DataRemovedEffectResponse>());
        expect((effect as DataRemovedEffectResponse).name, 'test_data_key');
      });

      test('fromJson creates DataUpdatedEffectResponse (type 42)', () {
        final json = {
          'id': 'effect_id',
          'type_i': 42,
          'type': 'data_updated',
          'created_at': '2024-01-01T00:00:00Z',
          'paging_token': 'token',
          'account': 'GABC123',
          'name': 'test_data_key',
          'value': 'dGVzdF92YWx1ZQ==',
          '_links': {
            'operation': {'href': 'op_link'},
            'precedes': {'href': 'pre_link'},
            'succeeds': {'href': 'succ_link'},
          },
        };

        final effect = EffectResponse.fromJson(json);
        expect(effect, isA<DataUpdatedEffectResponse>());
        final updated = effect as DataUpdatedEffectResponse;
        expect(updated.name, 'test_data_key');
        expect(updated.value, 'dGVzdF92YWx1ZQ==');
      });

      test('fromJson creates SequenceBumpedEffectResponse (type 43)', () {
        final json = {
          'id': 'effect_id',
          'type_i': 43,
          'type': 'sequence_bumped',
          'created_at': '2024-01-01T00:00:00Z',
          'paging_token': 'token',
          'account': 'GABC123',
          'new_seq': '123456',
          '_links': {
            'operation': {'href': 'op_link'},
            'precedes': {'href': 'pre_link'},
            'succeeds': {'href': 'succ_link'},
          },
        };

        final effect = EffectResponse.fromJson(json);
        expect(effect, isA<SequenceBumpedEffectResponse>());
      });

      test('fromJson creates ClaimableBalanceClaimantCreatedEffectResponse (type 51)', () {
        final json = {
          'id': 'effect_id',
          'type_i': 51,
          'type': 'claimable_balance_claimant_created',
          'created_at': '2024-01-01T00:00:00Z',
          'paging_token': 'token',
          'account': 'GABC123',
          'balance_id': 'balance_123',
          'asset': 'native',
          'amount': '100.0',
          'predicate': {'unconditional': true},
          '_links': {
            'operation': {'href': 'op_link'},
            'precedes': {'href': 'pre_link'},
            'succeeds': {'href': 'succ_link'},
          },
        };

        final effect = EffectResponse.fromJson(json);
        expect(effect, isA<ClaimableBalanceClaimantCreatedEffectResponse>());
        final claimant = effect as ClaimableBalanceClaimantCreatedEffectResponse;
        expect(claimant.balanceId, 'balance_123');
        expect(claimant.amount, '100.0');
        expect(claimant.predicate.unconditional, true);
      });

      test('fromJson creates ClaimableBalanceClaimedEffectResponse (type 52)', () {
        final json = {
          'id': 'effect_id',
          'type_i': 52,
          'type': 'claimable_balance_claimed',
          'created_at': '2024-01-01T00:00:00Z',
          'paging_token': 'token',
          'account': 'GABC123',
          'balance_id': 'balance_123',
          'asset': 'native',
          'amount': '100.0',
          '_links': {
            'operation': {'href': 'op_link'},
            'precedes': {'href': 'pre_link'},
            'succeeds': {'href': 'succ_link'},
          },
        };

        final effect = EffectResponse.fromJson(json);
        expect(effect, isA<ClaimableBalanceClaimedEffectResponse>());
      });

      test('fromJson creates AccountSponsorshipUpdatedEffectResponse (type 61)', () {
        final json = {
          'id': 'effect_id',
          'type_i': 61,
          'type': 'account_sponsorship_updated',
          'created_at': '2024-01-01T00:00:00Z',
          'paging_token': 'token',
          'account': 'GABC123',
          'former_sponsor': 'GDEF456',
          'new_sponsor': 'GHIJ789',
          '_links': {
            'operation': {'href': 'op_link'},
            'precedes': {'href': 'pre_link'},
            'succeeds': {'href': 'succ_link'},
          },
        };

        final effect = EffectResponse.fromJson(json);
        expect(effect, isA<AccountSponsorshipUpdatedEffectResponse>());
      });

      test('fromJson creates AccountSponsorshipRemovedEffectResponse (type 62)', () {
        final json = {
          'id': 'effect_id',
          'type_i': 62,
          'type': 'account_sponsorship_removed',
          'created_at': '2024-01-01T00:00:00Z',
          'paging_token': 'token',
          'account': 'GABC123',
          'former_sponsor': 'GDEF456',
          '_links': {
            'operation': {'href': 'op_link'},
            'precedes': {'href': 'pre_link'},
            'succeeds': {'href': 'succ_link'},
          },
        };

        final effect = EffectResponse.fromJson(json);
        expect(effect, isA<AccountSponsorshipRemovedEffectResponse>());
      });

      test('fromJson creates TrustlineSponsorshipUpdatedEffectResponse (type 64)', () {
        final json = {
          'id': 'effect_id',
          'type_i': 64,
          'type': 'trustline_sponsorship_updated',
          'created_at': '2024-01-01T00:00:00Z',
          'paging_token': 'token',
          'account': 'GABC123',
          'asset': 'native',
          'asset_type': 'native',
          'former_sponsor': 'GDEF456',
          'new_sponsor': 'GHIJ789',
          '_links': {
            'operation': {'href': 'op_link'},
            'precedes': {'href': 'pre_link'},
            'succeeds': {'href': 'succ_link'},
          },
        };

        final effect = EffectResponse.fromJson(json);
        expect(effect, isA<TrustlineSponsorshipUpdatedEffectResponse>());
        final updated = effect as TrustlineSponsorshipUpdatedEffectResponse;
        expect(updated.formerSponsor, 'GDEF456');
        expect(updated.newSponsor, 'GHIJ789');
        expect(updated.assetType, 'native');
      });

      test('fromJson creates TrustlineSponsorshipRemovedEffectResponse (type 65)', () {
        final json = {
          'id': 'effect_id',
          'type_i': 65,
          'type': 'trustline_sponsorship_removed',
          'created_at': '2024-01-01T00:00:00Z',
          'paging_token': 'token',
          'account': 'GABC123',
          'asset': 'native',
          'asset_type': 'native',
          'former_sponsor': 'GDEF456',
          '_links': {
            'operation': {'href': 'op_link'},
            'precedes': {'href': 'pre_link'},
            'succeeds': {'href': 'succ_link'},
          },
        };

        final effect = EffectResponse.fromJson(json);
        expect(effect, isA<TrustlineSponsorshipRemovedEffectResponse>());
        final removed = effect as TrustlineSponsorshipRemovedEffectResponse;
        expect(removed.formerSponsor, 'GDEF456');
        expect(removed.assetType, 'native');
      });

      test('fromJson creates DataSponsorshipUpdatedEffectResponse (type 67)', () {
        final json = {
          'id': 'effect_id',
          'type_i': 67,
          'type': 'data_sponsorship_updated',
          'created_at': '2024-01-01T00:00:00Z',
          'paging_token': 'token',
          'account': 'GABC123',
          'data_name': 'test_data',
          'former_sponsor': 'GDEF456',
          'new_sponsor': 'GHIJ789',
          '_links': {
            'operation': {'href': 'op_link'},
            'precedes': {'href': 'pre_link'},
            'succeeds': {'href': 'succ_link'},
          },
        };

        final effect = EffectResponse.fromJson(json);
        expect(effect, isA<DataSponsorshipUpdatedEffectResponse>());
      });

      test('fromJson creates DataSponsorshipRemovedEffectResponse (type 68)', () {
        final json = {
          'id': 'effect_id',
          'type_i': 68,
          'type': 'data_sponsorship_removed',
          'created_at': '2024-01-01T00:00:00Z',
          'paging_token': 'token',
          'account': 'GABC123',
          'data_name': 'test_data',
          'former_sponsor': 'GDEF456',
          '_links': {
            'operation': {'href': 'op_link'},
            'precedes': {'href': 'pre_link'},
            'succeeds': {'href': 'succ_link'},
          },
        };

        final effect = EffectResponse.fromJson(json);
        expect(effect, isA<DataSponsorshipRemovedEffectResponse>());
      });

      test('fromJson creates ClaimableBalanceSponsorshipUpdatedEffectResponse (type 70)', () {
        final json = {
          'id': 'effect_id',
          'type_i': 70,
          'type': 'claimable_balance_sponsorship_updated',
          'created_at': '2024-01-01T00:00:00Z',
          'paging_token': 'token',
          'account': 'GABC123',
          'balance_id': 'balance_123',
          'former_sponsor': 'GDEF456',
          'new_sponsor': 'GHIJ789',
          '_links': {
            'operation': {'href': 'op_link'},
            'precedes': {'href': 'pre_link'},
            'succeeds': {'href': 'succ_link'},
          },
        };

        final effect = EffectResponse.fromJson(json);
        expect(effect, isA<ClaimableBalanceSponsorshipUpdatedEffectResponse>());
      });

      test('fromJson creates ClaimableBalanceSponsorshipRemovedEffectResponse (type 71)', () {
        final json = {
          'id': 'effect_id',
          'type_i': 71,
          'type': 'claimable_balance_sponsorship_removed',
          'created_at': '2024-01-01T00:00:00Z',
          'paging_token': 'token',
          'account': 'GABC123',
          'balance_id': 'balance_123',
          'former_sponsor': 'GDEF456',
          '_links': {
            'operation': {'href': 'op_link'},
            'precedes': {'href': 'pre_link'},
            'succeeds': {'href': 'succ_link'},
          },
        };

        final effect = EffectResponse.fromJson(json);
        expect(effect, isA<ClaimableBalanceSponsorshipRemovedEffectResponse>());
      });

      test('fromJson creates SignerSponsorshipUpdatedEffectResponse (type 73)', () {
        final json = {
          'id': 'effect_id',
          'type_i': 73,
          'type': 'signer_sponsorship_updated',
          'created_at': '2024-01-01T00:00:00Z',
          'paging_token': 'token',
          'account': 'GABC123',
          'signer': 'GDEF456',
          'former_sponsor': 'GDEF456',
          'new_sponsor': 'GHIJ789',
          '_links': {
            'operation': {'href': 'op_link'},
            'precedes': {'href': 'pre_link'},
            'succeeds': {'href': 'succ_link'},
          },
        };

        final effect = EffectResponse.fromJson(json);
        expect(effect, isA<SignerSponsorshipUpdatedEffectResponse>());
      });

      test('fromJson creates SignerSponsorshipRemovedEffectResponse (type 74)', () {
        final json = {
          'id': 'effect_id',
          'type_i': 74,
          'type': 'signer_sponsorship_removed',
          'created_at': '2024-01-01T00:00:00Z',
          'paging_token': 'token',
          'account': 'GABC123',
          'signer': 'GDEF456',
          'former_sponsor': 'GDEF456',
          '_links': {
            'operation': {'href': 'op_link'},
            'precedes': {'href': 'pre_link'},
            'succeeds': {'href': 'succ_link'},
          },
        };

        final effect = EffectResponse.fromJson(json);
        expect(effect, isA<SignerSponsorshipRemovedEffectResponse>());
      });

      test('fromJson creates ClaimableBalanceClawedBackEffectResponse (type 80)', () {
        final json = {
          'id': 'effect_id',
          'type_i': 80,
          'type': 'claimable_balance_clawed_back',
          'created_at': '2024-01-01T00:00:00Z',
          'paging_token': 'token',
          'account': 'GABC123',
          'balance_id': 'balance_123',
          '_links': {
            'operation': {'href': 'op_link'},
            'precedes': {'href': 'pre_link'},
            'succeeds': {'href': 'succ_link'},
          },
        };

        final effect = EffectResponse.fromJson(json);
        expect(effect, isA<ClaimableBalanceClawedBackEffectResponse>());
      });

      test('fromJson creates LiquidityPoolRemovedEffectResponse (type 94)', () {
        final json = {
          'id': 'effect_id',
          'type_i': 94,
          'type': 'liquidity_pool_removed',
          'created_at': '2024-01-01T00:00:00Z',
          'paging_token': 'token',
          'account': 'GABC123',
          'liquidity_pool_id': 'pool_123',
          '_links': {
            'operation': {'href': 'op_link'},
            'precedes': {'href': 'pre_link'},
            'succeeds': {'href': 'succ_link'},
          },
        };

        final effect = EffectResponse.fromJson(json);
        expect(effect, isA<LiquidityPoolRemovedEffectResponse>());
      });

      test('fromJson creates ContractCreditedEffectResponse (type 96)', () {
        final json = {
          'id': 'effect_id',
          'type_i': 96,
          'type': 'contract_credited',
          'created_at': '2024-01-01T00:00:00Z',
          'paging_token': 'token',
          'account': 'GABC123',
          'contract': 'CDEF456',
          'asset_type': 'native',
          'amount': '100.0',
          '_links': {
            'operation': {'href': 'op_link'},
            'precedes': {'href': 'pre_link'},
            'succeeds': {'href': 'succ_link'},
          },
        };

        final effect = EffectResponse.fromJson(json);
        expect(effect, isA<ContractCreditedEffectResponse>());
      });

      test('fromJson creates ContractDebitedEffectResponse (type 97)', () {
        final json = {
          'id': 'effect_id',
          'type_i': 97,
          'type': 'contract_debited',
          'created_at': '2024-01-01T00:00:00Z',
          'paging_token': 'token',
          'account': 'GABC123',
          'contract': 'CDEF456',
          'asset_type': 'native',
          'amount': '100.0',
          '_links': {
            'operation': {'href': 'op_link'},
            'precedes': {'href': 'pre_link'},
            'succeeds': {'href': 'succ_link'},
          },
        };

        final effect = EffectResponse.fromJson(json);
        expect(effect, isA<ContractDebitedEffectResponse>());
      });

      test('fromJson throws on unknown effect type', () {
        final json = {
          'id': 'effect_id',
          'type_i': 999,
          'type': 'unknown_effect',
          'created_at': '2024-01-01T00:00:00Z',
          'paging_token': 'token',
          'account': 'GABC123',
          '_links': {
            'operation': {'href': 'op_link'},
            'precedes': {'href': 'pre_link'},
            'succeeds': {'href': 'succ_link'},
          },
        };

        expect(
          () => EffectResponse.fromJson(json),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('EffectResponseLinks Tests', () {
      test('toJson serializes correctly', () {
        final links = EffectResponseLinks(
          Link('https://horizon.stellar.org/operations/123', false),
          Link('https://horizon.stellar.org/effects/122', false),
          Link('https://horizon.stellar.org/effects/124', false),
        );

        final json = links.toJson();

        expect(json, isA<Map<String, dynamic>>());
        expect(json['operation'], isNotNull);
        expect(json['precedes'], isNotNull);
        expect(json['succeeds'], isNotNull);
      });
    });
  });

  group('Sponsorship Effects - Trustline', () {
    final testLinks = {
      '_links': {
        'operation': {'href': 'https://horizon.stellar.org/operations/123'},
        'precedes': {'href': 'https://horizon.stellar.org/effects?cursor=prev'},
        'succeeds': {'href': 'https://horizon.stellar.org/effects?cursor=next'},
      }
    };

    test('TrustlineSponsorshipUpdatedEffectResponse fromJson with asset', () {
      final json = {
        'id': 'effect-64',
        'type_i': 64,
        'type': 'trustline_sponsorship_updated',
        'created_at': '2021-01-05T00:00:00Z',
        'paging_token': 'token-64',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'asset': 'USD:GCRCUE2C5TBNIPYHMEP7NK5RWTT2WBSZ75CMARH7GDOHDDCQH3XANFOB',
        'asset_type': 'credit_alphanum4',
        'new_sponsor': 'GANEWSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ',
        'former_sponsor':
            'GAFORMERSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVW',
        ...testLinks,
      };

      final response = TrustlineSponsorshipUpdatedEffectResponse.fromJson(json);

      expect(response.id, equals('effect-64'));
      expect(response.type_i, equals(64));
      expect(response.type, equals('trustline_sponsorship_updated'));
      expect(response.asset, isNotNull);
      expect(response.assetType, equals('credit_alphanum4'));
      expect(response.newSponsor,
          equals('GANEWSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'));
      expect(response.formerSponsor,
          equals('GAFORMERSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVW'));
    });

    test(
        'TrustlineSponsorshipUpdatedEffectResponse fromJson with liquidity pool',
        () {
      final json = {
        'id': 'effect-64-lp',
        'type_i': 64,
        'type': 'trustline_sponsorship_updated',
        'created_at': '2021-01-05T00:00:00Z',
        'paging_token': 'token-64-lp',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'asset_type': 'liquidity_pool_shares',
        'liquidity_pool_id':
            'dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7',
        'new_sponsor': 'GANEWSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ',
        'former_sponsor':
            'GAFORMERSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVW',
        ...testLinks,
      };

      final response = TrustlineSponsorshipUpdatedEffectResponse.fromJson(json);

      expect(response.type_i, equals(64));
      expect(response.assetType, equals('liquidity_pool_shares'));
      expect(response.liquidityPoolId, isNotNull);
      expect(response.liquidityPoolId,
          equals('dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7'));
      expect(response.newSponsor,
          equals('GANEWSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'));
    });

    test('TrustlineSponsorshipRemovedEffectResponse fromJson with asset', () {
      final json = {
        'id': 'effect-65',
        'type_i': 65,
        'type': 'trustline_sponsorship_removed',
        'created_at': '2021-01-06T00:00:00Z',
        'paging_token': 'token-65',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'asset': 'EUR:GCRCUE2C5TBNIPYHMEP7NK5RWTT2WBSZ75CMARH7GDOHDDCQH3XANFOB',
        'asset_type': 'credit_alphanum4',
        'former_sponsor':
            'GAFORMERSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVW',
        ...testLinks,
      };

      final response = TrustlineSponsorshipRemovedEffectResponse.fromJson(json);

      expect(response.id, equals('effect-65'));
      expect(response.type_i, equals(65));
      expect(response.type, equals('trustline_sponsorship_removed'));
      expect(response.asset, isNotNull);
      expect(response.assetType, equals('credit_alphanum4'));
      expect(response.formerSponsor,
          equals('GAFORMERSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVW'));
    });

    test(
        'TrustlineSponsorshipRemovedEffectResponse fromJson with liquidity pool',
        () {
      final json = {
        'id': 'effect-65-lp',
        'type_i': 65,
        'type': 'trustline_sponsorship_removed',
        'created_at': '2021-01-06T00:00:00Z',
        'paging_token': 'token-65-lp',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'asset_type': 'liquidity_pool_shares',
        'liquidity_pool_id':
            'aa7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7',
        'former_sponsor':
            'GAFORMERSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVW',
        ...testLinks,
      };

      final response = TrustlineSponsorshipRemovedEffectResponse.fromJson(json);

      expect(response.type_i, equals(65));
      expect(response.assetType, equals('liquidity_pool_shares'));
      expect(response.liquidityPoolId, isNotNull);
      expect(response.liquidityPoolId,
          equals('aa7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7'));
      expect(response.formerSponsor,
          equals('GAFORMERSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVW'));
    });
  });

  group('Sponsorship Effects - Data', () {
    final testLinks = {
      '_links': {
        'operation': {'href': 'https://horizon.stellar.org/operations/123'},
        'precedes': {'href': 'https://horizon.stellar.org/effects?cursor=prev'},
        'succeeds': {'href': 'https://horizon.stellar.org/effects?cursor=next'},
      }
    };

    test('DataSponsorshipUpdatedEffectResponse fromJson', () {
      final json = {
        'id': 'effect-67',
        'type_i': 67,
        'type': 'data_sponsorship_updated',
        'created_at': '2021-01-08T00:00:00Z',
        'paging_token': 'token-67',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'data_name': 'config',
        'new_sponsor': 'GANEWSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ',
        'former_sponsor':
            'GAFORMERSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVW',
        ...testLinks,
      };

      final response = DataSponsorshipUpdatedEffectResponse.fromJson(json);

      expect(response.id, equals('effect-67'));
      expect(response.type_i, equals(67));
      expect(response.type, equals('data_sponsorship_updated'));
      expect(response.dataName, equals('config'));
      expect(response.newSponsor,
          equals('GANEWSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'));
      expect(response.formerSponsor,
          equals('GAFORMERSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVW'));
    });

    test('DataSponsorshipRemovedEffectResponse fromJson', () {
      final json = {
        'id': 'effect-68',
        'type_i': 68,
        'type': 'data_sponsorship_removed',
        'created_at': '2021-01-09T00:00:00Z',
        'paging_token': 'token-68',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'data_name': 'settings',
        'former_sponsor':
            'GAFORMERSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVW',
        ...testLinks,
      };

      final response = DataSponsorshipRemovedEffectResponse.fromJson(json);

      expect(response.id, equals('effect-68'));
      expect(response.type_i, equals(68));
      expect(response.type, equals('data_sponsorship_removed'));
      expect(response.dataName, equals('settings'));
      expect(response.formerSponsor,
          equals('GAFORMERSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVW'));
    });
  });

  group('Sponsorship Effects - Claimable Balance', () {
    final testLinks = {
      '_links': {
        'operation': {'href': 'https://horizon.stellar.org/operations/123'},
        'precedes': {'href': 'https://horizon.stellar.org/effects?cursor=prev'},
        'succeeds': {'href': 'https://horizon.stellar.org/effects?cursor=next'},
      }
    };

    test('ClaimableBalanceSponsorshipUpdatedEffectResponse fromJson', () {
      final json = {
        'id': 'effect-70',
        'type_i': 70,
        'type': 'claimable_balance_sponsorship_updated',
        'created_at': '2021-01-11T00:00:00Z',
        'paging_token': 'token-70',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'balance_id':
            '00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072',
        'new_sponsor': 'GANEWSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ',
        'former_sponsor':
            'GAFORMERSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVW',
        ...testLinks,
      };

      final response =
          ClaimableBalanceSponsorshipUpdatedEffectResponse.fromJson(json);

      expect(response.id, equals('effect-70'));
      expect(response.type_i, equals(70));
      expect(response.type, equals('claimable_balance_sponsorship_updated'));
      expect(response.balanceId,
          equals('00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072'));
      expect(response.newSponsor,
          equals('GANEWSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'));
      expect(response.formerSponsor,
          equals('GAFORMERSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVW'));
    });

    test('ClaimableBalanceSponsorshipRemovedEffectResponse fromJson', () {
      final json = {
        'id': 'effect-71',
        'type_i': 71,
        'type': 'claimable_balance_sponsorship_removed',
        'created_at': '2021-01-12T00:00:00Z',
        'paging_token': 'token-71',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'balance_id':
            '00000000a29b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072',
        'former_sponsor':
            'GAFORMERSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVW',
        ...testLinks,
      };

      final response =
          ClaimableBalanceSponsorshipRemovedEffectResponse.fromJson(json);

      expect(response.id, equals('effect-71'));
      expect(response.type_i, equals(71));
      expect(response.type, equals('claimable_balance_sponsorship_removed'));
      expect(response.balanceId,
          equals('00000000a29b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072'));
      expect(response.formerSponsor,
          equals('GAFORMERSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVW'));
    });
  });

  group('Sponsorship Effects - Signer', () {
    final testLinks = {
      '_links': {
        'operation': {'href': 'https://horizon.stellar.org/operations/123'},
        'precedes': {'href': 'https://horizon.stellar.org/effects?cursor=prev'},
        'succeeds': {'href': 'https://horizon.stellar.org/effects?cursor=next'},
      }
    };

    test('SignerSponsorshipUpdatedEffectResponse fromJson', () {
      final json = {
        'id': 'effect-73',
        'type_i': 73,
        'type': 'signer_sponsorship_updated',
        'created_at': '2021-01-14T00:00:00Z',
        'paging_token': 'token-73',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'signer': 'GASIGNER123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ',
        'new_sponsor': 'GANEWSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ',
        'former_sponsor':
            'GAFORMERSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVW',
        ...testLinks,
      };

      final response = SignerSponsorshipUpdatedEffectResponse.fromJson(json);

      expect(response.id, equals('effect-73'));
      expect(response.type_i, equals(73));
      expect(response.type, equals('signer_sponsorship_updated'));
      expect(response.signer,
          equals('GASIGNER123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'));
      expect(response.newSponsor,
          equals('GANEWSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'));
      expect(response.formerSponsor,
          equals('GAFORMERSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVW'));
    });

    test('SignerSponsorshipRemovedEffectResponse fromJson', () {
      final json = {
        'id': 'effect-74',
        'type_i': 74,
        'type': 'signer_sponsorship_removed',
        'created_at': '2021-01-15T00:00:00Z',
        'paging_token': 'token-74',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'signer': 'GASIGNER987654321ZYXWVUTSRQPONMLKJIHGFEDCBA',
        'former_sponsor':
            'GAFORMERSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVW',
        ...testLinks,
      };

      final response = SignerSponsorshipRemovedEffectResponse.fromJson(json);

      expect(response.id, equals('effect-74'));
      expect(response.type_i, equals(74));
      expect(response.type, equals('signer_sponsorship_removed'));
      expect(response.signer,
          equals('GASIGNER987654321ZYXWVUTSRQPONMLKJIHGFEDCBA'));
      expect(response.formerSponsor,
          equals('GAFORMERSPONSOR123456789ABCDEFGHIJKLMNOPQRSTUVW'));
    });
  });

  group('EffectResponse Factory Edge Cases', () {
    final testLinks = {
      '_links': {
        'operation': {'href': 'https://horizon.stellar.org/operations/123'},
        'precedes': {'href': 'https://horizon.stellar.org/effects?cursor=prev'},
        'succeeds': {'href': 'https://horizon.stellar.org/effects?cursor=next'},
      }
    };

    test('fromJson throws exception for unknown effect type', () {
      final json = {
        'id': 'effect-unknown',
        'type_i': 9999,
        'type': 'unknown_effect',
        'created_at': '2021-01-01T00:00:00Z',
        'paging_token': 'token-unknown',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        ...testLinks,
      };

      expect(() => EffectResponse.fromJson(json), throwsException);
    });

    test('EffectResponseLinks toJson returns correct structure', () {
      final links = EffectResponseLinks(
        Link.fromJson({'href': 'https://example.com/operation'}),
        Link.fromJson({'href': 'https://example.com/precedes'}),
        Link.fromJson({'href': 'https://example.com/succeeds'}),
      );

      final json = links.toJson();

      expect(json, isA<Map<String, dynamic>>());
      expect(json['operation'], isNotNull);
      expect(json['precedes'], isNotNull);
      expect(json['succeeds'], isNotNull);
    });

    test('AssetAmount fromJson with null asset for failed transaction', () {
      final json = {
        'amount': '100.0000000',
        'asset': null,
      };

      final assetAmount = AssetAmount.fromJson(json);

      expect(assetAmount.amount, equals('100.0000000'));
      expect(assetAmount.asset, isNull);
    });

    test('AssetAmount fromJson with native asset', () {
      final json = {
        'amount': '50.5000000',
        'asset': 'native',
      };

      final assetAmount = AssetAmount.fromJson(json);

      expect(assetAmount.amount, equals('50.5000000'));
      expect(assetAmount.asset, isA<AssetTypeNative>());
    });

    test('AssetAmount fromJson with credit asset', () {
      final json = {
        'amount': '25.0000000',
        'asset': 'USD:GCRCUE2C5TBNIPYHMEP7NK5RWTT2WBSZ75CMARH7GDOHDDCQH3XANFOB',
      };

      final assetAmount = AssetAmount.fromJson(json);

      expect(assetAmount.amount, equals('25.0000000'));
      expect(assetAmount.asset, isA<AssetTypeCreditAlphaNum4>());
    });
  });

  group('Effect Response Muxed Account Fields', () {
    final testLinks = {
      '_links': {
        'operation': {'href': 'https://horizon.stellar.org/operations/123'},
        'precedes': {'href': 'https://horizon.stellar.org/effects?cursor=prev'},
        'succeeds': {'href': 'https://horizon.stellar.org/effects?cursor=next'},
      }
    };

    test('AccountCreatedEffectResponse with muxed account', () {
      final json = {
        'id': 'effect-muxed-1',
        'type_i': 0,
        'type': 'account_created',
        'created_at': '2021-01-01T00:00:00Z',
        'paging_token': 'token-muxed-1',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'account_muxed':
            'MAAAAAAAAAAAAAB7BQ2L7E5NBWMXDUCMZSIPOBKRDSBYVLMXGSSKF6YNPIB7Y77ITLVL6',
        'account_muxed_id': '1234567890',
        'starting_balance': '10000.0000000',
        ...testLinks,
      };

      final response = AccountCreatedEffectResponse.fromJson(json);

      expect(response.accountMuxed,
          equals('MAAAAAAAAAAAAAB7BQ2L7E5NBWMXDUCMZSIPOBKRDSBYVLMXGSSKF6YNPIB7Y77ITLVL6'));
      expect(response.accountMuxedId, equals('1234567890'));
    });

    test('AccountCreditedEffectResponse with muxed account', () {
      final json = {
        'id': 'effect-muxed-2',
        'type_i': 2,
        'type': 'account_credited',
        'created_at': '2021-01-02T00:00:00Z',
        'paging_token': 'token-muxed-2',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'account_muxed':
            'MAAAAAAAAAAAAAB7BQ2L7E5NBWMXDUCMZSIPOBKRDSBYVLMXGSSKF6YNPIB7Y77ITLVL6',
        'account_muxed_id': '9876543210',
        'asset_type': 'native',
        'amount': '100.0000000',
        ...testLinks,
      };

      final response = AccountCreditedEffectResponse.fromJson(json);

      expect(response.accountMuxed,
          equals('MAAAAAAAAAAAAAB7BQ2L7E5NBWMXDUCMZSIPOBKRDSBYVLMXGSSKF6YNPIB7Y77ITLVL6'));
      expect(response.accountMuxedId, equals('9876543210'));
    });

    test('TradeEffectResponse with muxed accounts', () {
      final json = {
        'id': 'effect-muxed-3',
        'type_i': 33,
        'type': 'trade',
        'created_at': '2021-01-03T00:00:00Z',
        'paging_token': 'token-muxed-3',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'account_muxed':
            'MAAAAAAAAAAAAAB7BQ2L7E5NBWMXDUCMZSIPOBKRDSBYVLMXGSSKF6YNPIB7Y77ITLVL6',
        'account_muxed_id': '1111111111',
        'seller': 'GATRADER123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ',
        'seller_muxed':
            'MAAAAAAAAAAAAAB7BQ2L7E5NBWMXDUCMZSIPOBKRDSBYVLMXGSSKF6YNPIB7Y77ITLVL7',
        'seller_muxed_id': '2222222222',
        'offer_id': '12345',
        'sold_amount': '10.0000000',
        'sold_asset_type': 'native',
        'bought_amount': '5.0000000',
        'bought_asset_type': 'credit_alphanum4',
        'bought_asset_code': 'USD',
        'bought_asset_issuer':
            'GCRCUE2C5TBNIPYHMEP7NK5RWTT2WBSZ75CMARH7GDOHDDCQH3XANFOB',
        ...testLinks,
      };

      final response = TradeEffectResponse.fromJson(json);

      expect(response.accountMuxed,
          equals('MAAAAAAAAAAAAAB7BQ2L7E5NBWMXDUCMZSIPOBKRDSBYVLMXGSSKF6YNPIB7Y77ITLVL6'));
      expect(response.accountMuxedId, equals('1111111111'));
      expect(response.sellerMuxed,
          equals('MAAAAAAAAAAAAAB7BQ2L7E5NBWMXDUCMZSIPOBKRDSBYVLMXGSSKF6YNPIB7Y77ITLVL7'));
      expect(response.sellerMuxedId, equals('2222222222'));
    });
  });

  group('Liquidity Pool Effects with Asset Amounts', () {
    final testLinks = {
      '_links': {
        'operation': {'href': 'https://horizon.stellar.org/operations/123'},
        'precedes': {'href': 'https://horizon.stellar.org/effects?cursor=prev'},
        'succeeds': {'href': 'https://horizon.stellar.org/effects?cursor=next'},
      }
    };

    test('LiquidityPoolDepositedEffectResponse with detailed reserves', () {
      final json = {
        'id': 'effect-lp-deposit',
        'type_i': 90,
        'type': 'liquidity_pool_deposited',
        'created_at': '2021-02-01T00:00:00Z',
        'paging_token': 'token-lp-deposit',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'liquidity_pool': {
          'id': 'dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7',
          'fee_bp': 30,
          'type': 'constant_product',
          'total_trustlines': '300',
          'total_shares': '5000',
          'reserves': [
            {
              'amount': '1000.0000000',
              'asset': 'EURT:GAP5LETOV6YIE62YAM56STDANPRDO7ZFDBGSNHJQIYGGKSMOZAHOOS2S'
            },
            {
              'amount': '2000.0000000',
              'asset': 'PHP:GAP5LETOV6YIE62YAM56STDANPRDO7ZFDBGSNHJQIYGGKSMOZAHOOS2S'
            },
          ]
        },
        'reserves_deposited': [
          {
            'amount': '100.0000000',
            'asset': 'EURT:GAP5LETOV6YIE62YAM56STDANPRDO7ZFDBGSNHJQIYGGKSMOZAHOOS2S'
          },
          {
            'amount': '200.0000000',
            'asset': 'PHP:GAP5LETOV6YIE62YAM56STDANPRDO7ZFDBGSNHJQIYGGKSMOZAHOOS2S'
          },
        ],
        'shares_received': '150.0000000',
        ...testLinks,
      };

      final response = LiquidityPoolDepositedEffectResponse.fromJson(json);

      expect(response.type_i, equals(90));
      expect(response.liquidityPool, isNotNull);
      expect(response.reservesDeposited, isNotNull);
      expect(response.reservesDeposited!.length, equals(2));
      expect(response.reservesDeposited![0].amount, equals('100.0000000'));
      expect(response.reservesDeposited![1].amount, equals('200.0000000'));
      expect(response.sharesReceived, equals('150.0000000'));
    });

    test('LiquidityPoolWithdrewEffectResponse with detailed reserves', () {
      final json = {
        'id': 'effect-lp-withdraw',
        'type_i': 91,
        'type': 'liquidity_pool_withdrew',
        'created_at': '2021-02-02T00:00:00Z',
        'paging_token': 'token-lp-withdraw',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'liquidity_pool': {
          'id': 'dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7',
          'fee_bp': 30,
          'type': 'constant_product',
          'total_trustlines': '250',
          'total_shares': '4850',
          'reserves': [
            {
              'amount': '900.0000000',
              'asset': 'EURT:GAP5LETOV6YIE62YAM56STDANPRDO7ZFDBGSNHJQIYGGKSMOZAHOOS2S'
            },
            {
              'amount': '1800.0000000',
              'asset': 'PHP:GAP5LETOV6YIE62YAM56STDANPRDO7ZFDBGSNHJQIYGGKSMOZAHOOS2S'
            },
          ]
        },
        'reserves_received': [
          {
            'amount': '50.0000000',
            'asset': 'EURT:GAP5LETOV6YIE62YAM56STDANPRDO7ZFDBGSNHJQIYGGKSMOZAHOOS2S'
          },
          {
            'amount': '100.0000000',
            'asset': 'PHP:GAP5LETOV6YIE62YAM56STDANPRDO7ZFDBGSNHJQIYGGKSMOZAHOOS2S'
          },
        ],
        'shares_redeemed': '75.0000000',
        ...testLinks,
      };

      final response = LiquidityPoolWithdrewEffectResponse.fromJson(json);

      expect(response.type_i, equals(91));
      expect(response.liquidityPool, isNotNull);
      expect(response.reservesReceived, isNotNull);
      expect(response.reservesReceived!.length, equals(2));
      expect(response.reservesReceived![0].amount, equals('50.0000000'));
      expect(response.reservesReceived![1].amount, equals('100.0000000'));
      expect(response.sharesRedeemed, equals('75.0000000'));
    });

    test('LiquidityPoolTradeEffectResponse with bought and sold details', () {
      final json = {
        'id': 'effect-lp-trade',
        'type_i': 92,
        'type': 'liquidity_pool_trade',
        'created_at': '2021-02-03T00:00:00Z',
        'paging_token': 'token-lp-trade',
        'account': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'liquidity_pool': {
          'id': 'dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7',
          'fee_bp': 30,
          'type': 'constant_product',
          'total_trustlines': '260',
          'total_shares': '4900',
          'reserves': [
            {
              'amount': '920.0000000',
              'asset': 'EURT:GAP5LETOV6YIE62YAM56STDANPRDO7ZFDBGSNHJQIYGGKSMOZAHOOS2S'
            },
            {
              'amount': '1840.0000000',
              'asset': 'PHP:GAP5LETOV6YIE62YAM56STDANPRDO7ZFDBGSNHJQIYGGKSMOZAHOOS2S'
            },
          ]
        },
        'sold': {
          'amount': '20.0000000',
          'asset': 'EURT:GAP5LETOV6YIE62YAM56STDANPRDO7ZFDBGSNHJQIYGGKSMOZAHOOS2S'
        },
        'bought': {
          'amount': '40.0000000',
          'asset': 'PHP:GAP5LETOV6YIE62YAM56STDANPRDO7ZFDBGSNHJQIYGGKSMOZAHOOS2S'
        },
        ...testLinks,
      };

      final response = LiquidityPoolTradeEffectResponse.fromJson(json);

      expect(response.type_i, equals(92));
      expect(response.liquidityPool, isNotNull);
      expect(response.sold, isNotNull);
      expect(response.sold!.amount, equals('20.0000000'));
      expect(response.bought, isNotNull);
      expect(response.bought!.amount, equals('40.0000000'));
    });
  });
}
