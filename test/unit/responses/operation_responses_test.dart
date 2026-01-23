import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('OperationResponseLinks', () {
    test('should parse fromJson with all links', () {
      // Arrange
      final json = {
        'effects': {'href': 'https://horizon.stellar.org/operations/123/effects'},
        'precedes': {'href': 'https://horizon.stellar.org/operations/124'},
        'self': {'href': 'https://horizon.stellar.org/operations/123'},
        'succeeds': {'href': 'https://horizon.stellar.org/operations/122'},
        'transaction': {'href': 'https://horizon.stellar.org/transactions/abc123'},
      };

      // Act
      final links = OperationResponseLinks.fromJson(json);

      // Assert
      expect(links.effects.href, equals('https://horizon.stellar.org/operations/123/effects'));
      expect(links.precedes.href, equals('https://horizon.stellar.org/operations/124'));
      expect(links.self.href, equals('https://horizon.stellar.org/operations/123'));
      expect(links.succeeds.href, equals('https://horizon.stellar.org/operations/122'));
      expect(links.transaction.href, equals('https://horizon.stellar.org/transactions/abc123'));
    });
  });

  group('OperationResponse Factory', () {
    test('should create CreateAccountOperationResponse for type_i 0', () {
      // Arrange
      final json = {
        'type_i': 0,
        'type': 'create_account',
        'id': '12345',
        'paging_token': '12345',
        'transaction_successful': true,
        'source_account': 'GABC123',
        'created_at': '2024-01-01T00:00:00Z',
        'transaction_hash': 'txhash123',
        'funder': 'GDEF456',
        'starting_balance': '100.0',
        'account': 'GHIJ789',
        '_links': {
          'effects': {'href': 'url'},
          'precedes': {'href': 'url'},
          'self': {'href': 'url'},
          'succeeds': {'href': 'url'},
          'transaction': {'href': 'url'}
        }
      };

      // Act
      final operation = OperationResponse.fromJson(json);

      // Assert
      expect(operation, isA<CreateAccountOperationResponse>());
      expect(operation.type_i, equals(0));
    });

    test('should create PaymentOperationResponse for type_i 1', () {
      final json = {
        'type_i': 1,
        'type': 'payment',
        'id': '12346',
        'paging_token': '12346',
        'transaction_successful': true,
        'source_account': 'GABC123',
        'created_at': '2024-01-01T00:00:00Z',
        'transaction_hash': 'txhash123',
        'from': 'GABC123',
        'to': 'GDEF456',
        'amount': '50.0',
        'asset_type': 'native',
        '_links': {
          'effects': {'href': 'url'},
          'precedes': {'href': 'url'},
          'self': {'href': 'url'},
          'succeeds': {'href': 'url'},
          'transaction': {'href': 'url'}
        }
      };

      final operation = OperationResponse.fromJson(json);
      expect(operation, isA<PaymentOperationResponse>());
      expect(operation.type_i, equals(1));
    });

    test('should create correct operation for each type_i from 0 to 26', () {
      final typeMapping = {
        0: CreateAccountOperationResponse,
        1: PaymentOperationResponse,
        2: PathPaymentStrictReceiveOperationResponse,
        3: ManageSellOfferOperationResponse,
        4: CreatePassiveSellOfferOperationResponse,
        5: SetOptionsOperationResponse,
        6: ChangeTrustOperationResponse,
        7: AllowTrustOperationResponse,
        8: AccountMergeOperationResponse,
        9: InflationOperationResponse,
        10: ManageDataOperationResponse,
        11: BumpSequenceOperationResponse,
        12: ManageBuyOfferOperationResponse,
        13: PathPaymentStrictSendOperationResponse,
        14: CreateClaimableBalanceOperationResponse,
        15: ClaimClaimableBalanceOperationResponse,
        16: BeginSponsoringFutureReservesOperationResponse,
        17: EndSponsoringFutureReservesOperationResponse,
        18: RevokeSponsorshipOperationResponse,
        19: ClawbackOperationResponse,
        20: ClawbackClaimableBalanceOperationResponse,
        21: SetTrustlineFlagsOperationResponse,
        22: LiquidityPoolDepositOperationResponse,
        23: LiquidityPoolWithdrawOperationResponse,
        24: InvokeHostFunctionOperationResponse,
        25: ExtendFootprintTTLOperationResponse,
        26: RestoreFootprintOperationResponse,
      };

      typeMapping.forEach((typeI, expectedType) {
        final json = _createMinimalOperationJson(typeI);
        final operation = OperationResponse.fromJson(json);
        expect(operation.runtimeType, equals(expectedType),
            reason: 'Type $typeI should create ${expectedType.toString()}');
      });
    });

    test('should throw exception for unknown operation type', () {
      final json = _createMinimalOperationJson(27);
      expect(() => OperationResponse.fromJson(json), throwsException);
    });
  });

  group('CreateAccountOperationResponse', () {
    test('should parse all fields from JSON', () {
      // Arrange
      final json = {
        'type_i': 0,
        'type': 'create_account',
        'id': '123456789',
        'paging_token': '123456789',
        'transaction_successful': true,
        'source_account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
        'source_account_muxed': 'MAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
        'source_account_muxed_id': '12345',
        'created_at': '2024-01-15T10:30:00Z',
        'transaction_hash': 'abc123def456',
        'funder': 'GBXGQJWVLWOYHFLVTKWV5FGHA3LNYY2JQKM7OAJAUEQFU6LPCSEFVXON',
        'funder_muxed': 'MBXGQJWVLWOYHFLVTKWV5FGHA3LNYY2JQKM7OAJAUEQFU6LPCSEFVXON',
        'funder_muxed_id': '67890',
        'starting_balance': '1000.0',
        'account': 'GCFXHS4GXL6BVUCXBWXGTITROWLVYXQKQLF4YH5O5JT3YZXCYPAFBJZB',
        'sponsor': 'GDQP2KPQGKIHYJGXNUIYOMHARUARCA7DJT5FO2FFOOKY3B2WSQHG4W37',
        '_links': {
          'effects': {'href': 'https://horizon.stellar.org/operations/123456789/effects'},
          'precedes': {'href': 'https://horizon.stellar.org/operations/123456790'},
          'self': {'href': 'https://horizon.stellar.org/operations/123456789'},
          'succeeds': {'href': 'https://horizon.stellar.org/operations/123456788'},
          'transaction': {'href': 'https://horizon.stellar.org/transactions/abc123def456'}
        }
      };

      // Act
      final response = CreateAccountOperationResponse.fromJson(json);

      // Assert
      expect(response.id, equals('123456789'));
      expect(response.pagingToken, equals('123456789'));
      expect(response.transactionSuccessful, equals(true));
      expect(response.sourceAccount, equals('GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7'));
      expect(response.sourceAccountMuxed, equals('MAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7'));
      expect(response.sourceAccountMuxedId, equals('12345'));
      expect(response.type, equals('create_account'));
      expect(response.type_i, equals(0));
      expect(response.createdAt, equals('2024-01-15T10:30:00Z'));
      expect(response.transactionHash, equals('abc123def456'));
      expect(response.funder, equals('GBXGQJWVLWOYHFLVTKWV5FGHA3LNYY2JQKM7OAJAUEQFU6LPCSEFVXON'));
      expect(response.funderMuxed, equals('MBXGQJWVLWOYHFLVTKWV5FGHA3LNYY2JQKM7OAJAUEQFU6LPCSEFVXON'));
      expect(response.funderMuxedId, equals('67890'));
      expect(response.startingBalance, equals('1000.0'));
      expect(response.account, equals('GCFXHS4GXL6BVUCXBWXGTITROWLVYXQKQLF4YH5O5JT3YZXCYPAFBJZB'));
      expect(response.sponsor, equals('GDQP2KPQGKIHYJGXNUIYOMHARUARCA7DJT5FO2FFOOKY3B2WSQHG4W37'));
    });

    test('should handle optional fields as null', () {
      final json = {
        'type_i': 0,
        'type': 'create_account',
        'id': '123',
        'paging_token': '123',
        'transaction_successful': false,
        'source_account': 'GABC123',
        'created_at': '2024-01-01T00:00:00Z',
        'transaction_hash': 'hash123',
        'funder': 'GDEF456',
        'starting_balance': '10.0',
        'account': 'GHIJ789',
        '_links': {
          'effects': {'href': 'url'},
          'precedes': {'href': 'url'},
          'self': {'href': 'url'},
          'succeeds': {'href': 'url'},
          'transaction': {'href': 'url'}
        }
      };

      final response = CreateAccountOperationResponse.fromJson(json);

      expect(response.sourceAccountMuxed, isNull);
      expect(response.sourceAccountMuxedId, isNull);
      expect(response.funderMuxed, isNull);
      expect(response.funderMuxedId, isNull);
      expect(response.sponsor, isNull);
      expect(response.transaction, isNull);
    });
  });

  group('PaymentOperationResponse', () {
    test('should parse native asset payment', () {
      final json = {
        'type_i': 1,
        'type': 'payment',
        'id': '987654321',
        'paging_token': '987654321',
        'transaction_successful': true,
        'source_account': 'GABC123',
        'created_at': '2024-01-15T12:00:00Z',
        'transaction_hash': 'hash789',
        'from': 'GABC123',
        'to': 'GDEF456',
        'from_muxed': 'MABC123',
        'from_muxed_id': '111',
        'to_muxed': 'MDEF456',
        'to_muxed_id': '222',
        'amount': '100.5000000',
        'asset_type': 'native',
        '_links': {
          'effects': {'href': 'url'},
          'precedes': {'href': 'url'},
          'self': {'href': 'url'},
          'succeeds': {'href': 'url'},
          'transaction': {'href': 'url'}
        }
      };

      final response = PaymentOperationResponse.fromJson(json);

      expect(response.amount, equals('100.5000000'));
      expect(response.assetType, equals('native'));
      expect(response.assetCode, isNull);
      expect(response.assetIssuer, isNull);
      expect(response.from, equals('GABC123'));
      expect(response.to, equals('GDEF456'));
      expect(response.fromMuxed, equals('MABC123'));
      expect(response.fromMuxedId, equals('111'));
      expect(response.toMuxed, equals('MDEF456'));
      expect(response.toMuxedId, equals('222'));

      // Test asset getter
      final asset = response.asset;
      expect(asset, isA<AssetTypeNative>());
    });

    test('should parse credit asset payment', () {
      final json = {
        'type_i': 1,
        'type': 'payment',
        'id': '999',
        'paging_token': '999',
        'transaction_successful': true,
        'source_account': 'GABC123',
        'created_at': '2024-01-15T12:00:00Z',
        'transaction_hash': 'hash999',
        'from': 'GABC123',
        'to': 'GDEF456',
        'amount': '50.0',
        'asset_type': 'credit_alphanum4',
        'asset_code': 'USDC',
        'asset_issuer': 'GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN',
        '_links': {
          'effects': {'href': 'url'},
          'precedes': {'href': 'url'},
          'self': {'href': 'url'},
          'succeeds': {'href': 'url'},
          'transaction': {'href': 'url'}
        }
      };

      final response = PaymentOperationResponse.fromJson(json);

      expect(response.assetType, equals('credit_alphanum4'));
      expect(response.assetCode, equals('USDC'));
      expect(response.assetIssuer, equals('GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN'));

      // Test asset getter
      final asset = response.asset;
      expect(asset, isA<AssetTypeCreditAlphaNum>());
      expect((asset as AssetTypeCreditAlphaNum).code, equals('USDC'));
    });
  });

  group('ManageSellOfferOperationResponse', () {
    test('should parse all fields including price', () {
      final json = {
        'type_i': 3,
        'type': 'manage_sell_offer',
        'id': '555',
        'paging_token': '555',
        'transaction_successful': true,
        'source_account': 'GABC123',
        'created_at': '2024-01-15T13:00:00Z',
        'transaction_hash': 'hash555',
        'offer_id': '12345',
        'amount': '1000.0',
        'price': '0.1',
        'price_r': {'n': 1, 'd': 10},
        'buying_asset_type': 'credit_alphanum4',
        'buying_asset_code': 'USDC',
        'buying_asset_issuer': 'GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN',
        'selling_asset_type': 'native',
        '_links': {
          'effects': {'href': 'url'},
          'precedes': {'href': 'url'},
          'self': {'href': 'url'},
          'succeeds': {'href': 'url'},
          'transaction': {'href': 'url'}
        }
      };

      final response = ManageSellOfferOperationResponse.fromJson(json);

      expect(response.offerId, equals('12345'));
      expect(response.amount, equals('1000.0'));
      expect(response.price, equals('0.1'));
      expect(response.priceR.n, equals(1));
      expect(response.priceR.d, equals(10));
      expect(response.buyingAssetType, equals('credit_alphanum4'));
      expect(response.buyingAssetCode, equals('USDC'));
      expect(response.sellingAssetType, equals('native'));

      // Test asset getters
      expect(response.buyingAsset, isA<AssetTypeCreditAlphaNum>());
      expect(response.sellingAsset, isA<AssetTypeNative>());
    });

    test('should handle offer deletion with amount 0', () {
      final json = {
        'type_i': 3,
        'type': 'manage_sell_offer',
        'id': '556',
        'paging_token': '556',
        'transaction_successful': true,
        'source_account': 'GABC123',
        'created_at': '2024-01-15T13:00:00Z',
        'transaction_hash': 'hash556',
        'offer_id': '12345',
        'amount': '0',
        'price': '0.1',
        'price_r': {'n': 1, 'd': 10},
        'buying_asset_type': 'native',
        'selling_asset_type': 'native',
        '_links': {
          'effects': {'href': 'url'},
          'precedes': {'href': 'url'},
          'self': {'href': 'url'},
          'succeeds': {'href': 'url'},
          'transaction': {'href': 'url'}
        }
      };

      final response = ManageSellOfferOperationResponse.fromJson(json);
      expect(response.amount, equals('0'));
    });
  });

  group('PathPaymentStrictReceiveOperationResponse', () {
    test('should parse path payment with intermediate assets', () {
      final json = {
        'type_i': 2,
        'type': 'path_payment_strict_receive',
        'id': '777',
        'paging_token': '777',
        'transaction_successful': true,
        'source_account': 'GABC123',
        'created_at': '2024-01-15T14:00:00Z',
        'transaction_hash': 'hash777',
        'from': 'GABC123',
        'to': 'GDEF456',
        'amount': '100.0',
        'source_amount': '105.0',
        'source_max': '110.0',
        'asset_type': 'credit_alphanum4',
        'asset_code': 'USDC',
        'asset_issuer': 'GISSUER123',
        'source_asset_type': 'native',
        'path': [
          {
            'asset_type': 'credit_alphanum4',
            'asset_code': 'EUR',
            'asset_issuer': 'GEURISSUER'
          }
        ],
        '_links': {
          'effects': {'href': 'url'},
          'precedes': {'href': 'url'},
          'self': {'href': 'url'},
          'succeeds': {'href': 'url'},
          'transaction': {'href': 'url'}
        }
      };

      final response = PathPaymentStrictReceiveOperationResponse.fromJson(json);

      expect(response.amount, equals('100.0'));
      expect(response.sourceAmount, equals('105.0'));
      expect(response.sourceMax, equals('110.0'));
      expect(response.path, hasLength(1));
      expect(response.path![0], isA<Asset>());
    });
  });

  group('SetOptionsOperationResponse', () {
    test('should parse all option fields', () {
      final json = {
        'type_i': 5,
        'type': 'set_options',
        'id': '888',
        'paging_token': '888',
        'transaction_successful': true,
        'source_account': 'GABC123',
        'created_at': '2024-01-15T15:00:00Z',
        'transaction_hash': 'hash888',
        'signer_key': 'GDEF456',
        'signer_weight': 2,
        'master_key_weight': 1,
        'low_threshold': 1,
        'med_threshold': 2,
        'high_threshold': 3,
        'home_domain': 'example.com',
        'set_flags': [1, 2],
        'set_flags_s': ['auth_required', 'auth_revocable'],
        'clear_flags': [4],
        'clear_flags_s': ['auth_immutable'],
        '_links': {
          'effects': {'href': 'url'},
          'precedes': {'href': 'url'},
          'self': {'href': 'url'},
          'succeeds': {'href': 'url'},
          'transaction': {'href': 'url'}
        }
      };

      final response = SetOptionsOperationResponse.fromJson(json);

      expect(response.signerKey, equals('GDEF456'));
      expect(response.signerWeight, equals(2));
      expect(response.masterKeyWeight, equals(1));
      expect(response.lowThreshold, equals(1));
      expect(response.medThreshold, equals(2));
      expect(response.highThreshold, equals(3));
      expect(response.homeDomain, equals('example.com'));
      expect(response.setFlagsInt, equals([1, 2]));
      expect(response.setFlags, equals(['auth_required', 'auth_revocable']));
      expect(response.clearFlagsInt, equals([4]));
      expect(response.clearFlags, equals(['auth_immutable']));
    });
  });

  group('ChangeTrustOperationResponse', () {
    test('should parse trust line changes', () {
      final json = {
        'type_i': 6,
        'type': 'change_trust',
        'id': '444',
        'paging_token': '444',
        'transaction_successful': true,
        'source_account': 'GABC123',
        'created_at': '2024-01-15T16:00:00Z',
        'transaction_hash': 'hash444',
        'trustor': 'GABC123',
        'trustee': 'GDEF456',
        'asset_type': 'credit_alphanum4',
        'asset_code': 'USD',
        'asset_issuer': 'GDEF456',
        'limit': '10000.0',
        'liquidity_pool_id': 'pool123',
        '_links': {
          'effects': {'href': 'url'},
          'precedes': {'href': 'url'},
          'self': {'href': 'url'},
          'succeeds': {'href': 'url'},
          'transaction': {'href': 'url'}
        }
      };

      final response = ChangeTrustOperationResponse.fromJson(json);

      expect(response.trustor, equals('GABC123'));
      expect(response.trustee, equals('GDEF456'));
      expect(response.assetType, equals('credit_alphanum4'));
      expect(response.assetCode, equals('USD'));
      expect(response.assetIssuer, equals('GDEF456'));
      expect(response.limit, equals('10000.0'));
      expect(response.liquidityPoolId, equals('pool123'));
    });
  });

  group('ManageDataOperationResponse', () {
    test('should parse data entry operations', () {
      final json = {
        'type_i': 10,
        'type': 'manage_data',
        'id': '333',
        'paging_token': '333',
        'transaction_successful': true,
        'source_account': 'GABC123',
        'created_at': '2024-01-15T17:00:00Z',
        'transaction_hash': 'hash333',
        'name': 'config',
        'value': 'dmFsdWU=', // base64 for "value"
        '_links': {
          'effects': {'href': 'url'},
          'precedes': {'href': 'url'},
          'self': {'href': 'url'},
          'succeeds': {'href': 'url'},
          'transaction': {'href': 'url'}
        }
      };

      final response = ManageDataOperationResponse.fromJson(json);

      expect(response.name, equals('config'));
      expect(response.value, equals('dmFsdWU='));
    });

    test('should handle data deletion with null value', () {
      final json = {
        'type_i': 10,
        'type': 'manage_data',
        'id': '334',
        'paging_token': '334',
        'transaction_successful': true,
        'source_account': 'GABC123',
        'created_at': '2024-01-15T17:00:00Z',
        'transaction_hash': 'hash334',
        'name': 'config',
        'value': null,
        '_links': {
          'effects': {'href': 'url'},
          'precedes': {'href': 'url'},
          'self': {'href': 'url'},
          'succeeds': {'href': 'url'},
          'transaction': {'href': 'url'}
        }
      };

      final response = ManageDataOperationResponse.fromJson(json);
      expect(response.value, isNull);
    });
  });

  group('InvokeHostFunctionOperationResponse', () {
    test('should parse Soroban contract invocation', () {
      final json = {
        'type_i': 24,
        'type': 'invoke_host_function',
        'id': '111',
        'paging_token': '111',
        'transaction_successful': true,
        'source_account': 'GABC123',
        'created_at': '2024-01-15T18:00:00Z',
        'transaction_hash': 'hash111',
        'function': 'HostFunctionTypeInvokeContract',
        'address': 'CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC',
        'salt': 'salt123',
        'parameters': [
          {
            'type': 'Symbol',
            'value': 'AAAADwAAAAh0cmFuc2Zlcg==' // Valid XDR for Symbol "transfer"
          },
          {
            'type': 'Address',
            'value': 'AAAAEgAAAAG3hSx6F8b9GZ7E+3FP3PrRkPJBAAAAAAAAAAAAAAAA' // Valid XDR for Address
          }
        ],
        'asset_balance_changes': [
          {
            'type': 'transfer',
            'from': 'GABC123',
            'to': 'GDEF456',
            'amount': '100.0',
            'asset_type': 'native'
          }
        ],
        '_links': {
          'effects': {'href': 'url'},
          'precedes': {'href': 'url'},
          'self': {'href': 'url'},
          'succeeds': {'href': 'url'},
          'transaction': {'href': 'url'}
        }
      };

      final response = InvokeHostFunctionOperationResponse.fromJson(json);

      expect(response.function, equals('HostFunctionTypeInvokeContract'));
      expect(response.address, equals('CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC'));
      expect(response.salt, equals('salt123'));
      expect(response.parameters, hasLength(2));
      expect(response.parameters![0].type, equals('Symbol'));
      expect(response.parameters![0].value, equals('AAAADwAAAAh0cmFuc2Zlcg=='));
      expect(response.assetBalanceChanges, hasLength(1));
      expect(response.assetBalanceChanges![0].type, equals('transfer'));
      expect(response.assetBalanceChanges![0].amount, equals('100.0'));
    });

    test('should handle null parameters and balance changes', () {
      final json = {
        'type_i': 24,
        'type': 'invoke_host_function',
        'id': '112',
        'paging_token': '112',
        'transaction_successful': true,
        'source_account': 'GABC123',
        'created_at': '2024-01-15T18:00:00Z',
        'transaction_hash': 'hash112',
        'function': 'HostFunctionTypeCreateContract',
        'address': 'CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC',
        'salt': 'salt456',
        'parameters': null,
        'asset_balance_changes': null,
        '_links': {
          'effects': {'href': 'url'},
          'precedes': {'href': 'url'},
          'self': {'href': 'url'},
          'succeeds': {'href': 'url'},
          'transaction': {'href': 'url'}
        }
      };

      final response = InvokeHostFunctionOperationResponse.fromJson(json);

      expect(response.parameters, isNull);
      expect(response.assetBalanceChanges, isNull);
    });
  });

  group('ClaimableBalanceOperations', () {
    test('should parse CreateClaimableBalanceOperationResponse', () {
      final json = {
        'type_i': 14,
        'type': 'create_claimable_balance',
        'id': '222',
        'paging_token': '222',
        'transaction_successful': true,
        'source_account': 'GABC123',
        'created_at': '2024-01-15T19:00:00Z',
        'transaction_hash': 'hash222',
        'sponsor': 'GSPONSOR123',
        'asset': 'native',
        'amount': '500.0',
        'claimants': [
          {
            'destination': 'GDEST1',
            'predicate': {'unconditional': true}
          },
          {
            'destination': 'GDEST2',
            'predicate': {
              'relative_time': {
                'seconds': 3600
              }
            }
          }
        ],
        '_links': {
          'effects': {'href': 'url'},
          'precedes': {'href': 'url'},
          'self': {'href': 'url'},
          'succeeds': {'href': 'url'},
          'transaction': {'href': 'url'}
        }
      };

      final response = CreateClaimableBalanceOperationResponse.fromJson(json);

      expect(response.sponsor, equals('GSPONSOR123'));
      expect(response.asset, isA<Asset>());
      expect(response.amount, equals('500.0'));
      expect(response.claimants, hasLength(2));
    });

    test('should parse ClaimClaimableBalanceOperationResponse', () {
      final json = {
        'type_i': 15,
        'type': 'claim_claimable_balance',
        'id': '223',
        'paging_token': '223',
        'transaction_successful': true,
        'source_account': 'GABC123',
        'created_at': '2024-01-15T19:30:00Z',
        'transaction_hash': 'hash223',
        'claimant': 'GCLAIMANT',
        'claimant_muxed': 'MCLAIMANT',
        'claimant_muxed_id': '999',
        'balance_id': '00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072',
        '_links': {
          'effects': {'href': 'url'},
          'precedes': {'href': 'url'},
          'self': {'href': 'url'},
          'succeeds': {'href': 'url'},
          'transaction': {'href': 'url'}
        }
      };

      final response = ClaimClaimableBalanceOperationResponse.fromJson(json);

      expect(response.claimantAccountId, equals('GCLAIMANT'));
      expect(response.claimantMuxed, equals('MCLAIMANT'));
      expect(response.claimantMuxedId, equals('999'));
      expect(response.balanceId, equals('00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072'));
    });
  });

  group('SponsorshipOperations', () {
    test('should parse BeginSponsoringFutureReservesOperationResponse', () {
      final json = {
        'type_i': 16,
        'type': 'begin_sponsoring_future_reserves',
        'id': '666',
        'paging_token': '666',
        'transaction_successful': true,
        'source_account': 'GSPONSOR',
        'created_at': '2024-01-15T20:00:00Z',
        'transaction_hash': 'hash666',
        'sponsored_id': 'GSPONSORED',
        '_links': {
          'effects': {'href': 'url'},
          'precedes': {'href': 'url'},
          'self': {'href': 'url'},
          'succeeds': {'href': 'url'},
          'transaction': {'href': 'url'}
        }
      };

      final response = BeginSponsoringFutureReservesOperationResponse.fromJson(json);

      expect(response.sponsoredId, equals('GSPONSORED'));
    });

    test('should parse EndSponsoringFutureReservesOperationResponse', () {
      final json = {
        'type_i': 17,
        'type': 'end_sponsoring_future_reserves',
        'id': '667',
        'paging_token': '667',
        'transaction_successful': true,
        'source_account': 'GSPONSOR',
        'created_at': '2024-01-15T20:30:00Z',
        'transaction_hash': 'hash667',
        'begin_sponsor': 'GBEGIN',
        'begin_sponsor_muxed': 'MBEGIN',
        'begin_sponsor_muxed_id': '100',
        '_links': {
          'effects': {'href': 'url'},
          'precedes': {'href': 'url'},
          'self': {'href': 'url'},
          'succeeds': {'href': 'url'},
          'transaction': {'href': 'url'}
        }
      };

      final response = EndSponsoringFutureReservesOperationResponse.fromJson(json);

      expect(response.beginSponsor, equals('GBEGIN'));
      expect(response.beginSponsorMuxed, equals('MBEGIN'));
      expect(response.beginSponsorMuxedId, equals('100'));
    });

    test('should parse RevokeSponsorshipOperationResponse', () {
      final json = {
        'type_i': 18,
        'type': 'revoke_sponsorship',
        'id': '668',
        'paging_token': '668',
        'transaction_successful': true,
        'source_account': 'GSPONSOR',
        'created_at': '2024-01-15T21:00:00Z',
        'transaction_hash': 'hash668',
        'account_id': 'GREVOKED',
        'trustline_account_id': 'GTRUSTLINE',
        'trustline_asset': 'USD:GISSUER',
        'offer_id': '12345',
        'data_account_id': 'GDATA',
        'data_name': 'config',
        'claimable_balance_id': '00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072',
        'signer_account_id': 'GSIGNER',
        'signer_key': 'GKEY',
        '_links': {
          'effects': {'href': 'url'},
          'precedes': {'href': 'url'},
          'self': {'href': 'url'},
          'succeeds': {'href': 'url'},
          'transaction': {'href': 'url'}
        }
      };

      final response = RevokeSponsorshipOperationResponse.fromJson(json);

      expect(response.accountId, equals('GREVOKED'));
      expect(response.trustlineAccountId, equals('GTRUSTLINE'));
      expect(response.trustlineAsset, equals('USD:GISSUER'));
      expect(response.offerId, equals('12345'));
      expect(response.dataAccountId, equals('GDATA'));
      expect(response.dataName, equals('config'));
      expect(response.claimableBalanceId, equals('00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072'));
      expect(response.signerAccountId, equals('GSIGNER'));
      expect(response.signerKey, equals('GKEY'));
    });
  });

  group('LiquidityPoolOperations', () {
    test('should parse LiquidityPoolDepositOperationResponse', () {
      final json = {
        'type_i': 22,
        'type': 'liquidity_pool_deposit',
        'id': '777',
        'paging_token': '777',
        'transaction_successful': true,
        'source_account': 'GDEPOSITOR',
        'created_at': '2024-01-15T22:00:00Z',
        'transaction_hash': 'hash777',
        'liquidity_pool_id': 'pool789',
        'reserves_max': [
          {'asset': 'native', 'amount': '1000.0'},
          {'asset': 'USD:GISSUER', 'amount': '2000.0'}
        ],
        'min_price': '0.5',
        'min_price_r': {'n': 1, 'd': 2},
        'max_price': '2.0',
        'max_price_r': {'n': 2, 'd': 1},
        'reserves_deposited': [
          {'asset': 'native', 'amount': '999.0'},
          {'asset': 'USD:GISSUER', 'amount': '1998.0'}
        ],
        'shares_received': '1414.213562',
        '_links': {
          'effects': {'href': 'url'},
          'precedes': {'href': 'url'},
          'self': {'href': 'url'},
          'succeeds': {'href': 'url'},
          'transaction': {'href': 'url'}
        }
      };

      final response = LiquidityPoolDepositOperationResponse.fromJson(json);

      expect(response.liquidityPoolId, equals('pool789'));
      expect(response.reservesMax, hasLength(2));
      expect(response.minPrice, equals('0.5'));
      expect(response.maxPrice, equals('2.0'));
      expect(response.reservesDeposited, hasLength(2));
      expect(response.sharesReceived, equals('1414.213562'));
    });

    test('should parse LiquidityPoolWithdrawOperationResponse', () {
      final json = {
        'type_i': 23,
        'type': 'liquidity_pool_withdraw',
        'id': '778',
        'paging_token': '778',
        'transaction_successful': true,
        'source_account': 'GWITHDRAWER',
        'created_at': '2024-01-15T22:30:00Z',
        'transaction_hash': 'hash778',
        'liquidity_pool_id': 'pool789',
        'shares': '100.0',
        'reserves_min': [
          {'asset': 'native', 'amount': '70.0'},
          {'asset': 'USD:GISSUER', 'amount': '70.0'}
        ],
        'reserves_received': [
          {'asset': 'native', 'amount': '71.0'},
          {'asset': 'USD:GISSUER', 'amount': '71.0'}
        ],
        '_links': {
          'effects': {'href': 'url'},
          'precedes': {'href': 'url'},
          'self': {'href': 'url'},
          'succeeds': {'href': 'url'},
          'transaction': {'href': 'url'}
        }
      };

      final response = LiquidityPoolWithdrawOperationResponse.fromJson(json);

      expect(response.liquidityPoolId, equals('pool789'));
      expect(response.shares, equals('100.0'));
      expect(response.reservesMin, hasLength(2));
      expect(response.reservesReceived, hasLength(2));
    });
  });

  group('ClawbackOperations', () {
    test('should parse ClawbackOperationResponse', () {
      final json = {
        'type_i': 19,
        'type': 'clawback',
        'id': '890',
        'paging_token': '890',
        'transaction_successful': true,
        'source_account': 'GISSUER',
        'created_at': '2024-01-15T23:00:00Z',
        'transaction_hash': 'hash890',
        'asset_type': 'credit_alphanum4',
        'asset_code': 'USD',
        'asset_issuer': 'GISSUER',
        'from': 'GFROM',
        'from_muxed': 'MFROM',
        'from_muxed_id': '5555',
        'amount': '100.0',
        '_links': {
          'effects': {'href': 'url'},
          'precedes': {'href': 'url'},
          'self': {'href': 'url'},
          'succeeds': {'href': 'url'},
          'transaction': {'href': 'url'}
        }
      };

      final response = ClawbackOperationResponse.fromJson(json);

      expect(response.assetType, equals('credit_alphanum4'));
      expect(response.assetCode, equals('USD'));
      expect(response.assetIssuer, equals('GISSUER'));
      expect(response.from, equals('GFROM'));
      expect(response.fromMuxed, equals('MFROM'));
      expect(response.fromMuxedId, equals('5555'));
      expect(response.amount, equals('100.0'));
    });

    test('should parse ClawbackClaimableBalanceOperationResponse', () {
      final json = {
        'type_i': 20,
        'type': 'clawback_claimable_balance',
        'id': '891',
        'paging_token': '891',
        'transaction_successful': true,
        'source_account': 'GISSUER',
        'created_at': '2024-01-15T23:30:00Z',
        'transaction_hash': 'hash891',
        'balance_id': '00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072',
        '_links': {
          'effects': {'href': 'url'},
          'precedes': {'href': 'url'},
          'self': {'href': 'url'},
          'succeeds': {'href': 'url'},
          'transaction': {'href': 'url'}
        }
      };

      final response = ClawbackClaimableBalanceOperationResponse.fromJson(json);

      expect(response.balanceId, equals('00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072'));
    });
  });

  group('Other Operations', () {
    test('should parse AccountMergeOperationResponse', () {
      final json = {
        'type_i': 8,
        'type': 'account_merge',
        'id': '901',
        'paging_token': '901',
        'transaction_successful': true,
        'source_account': 'GMERGED',
        'created_at': '2024-01-16T00:00:00Z',
        'transaction_hash': 'hash901',
        'account': 'GMERGED',
        'account_muxed': 'MMERGED',
        'account_muxed_id': '7777',
        'into': 'GDESTINATION',
        'into_muxed': 'MDESTINATION',
        'into_muxed_id': '8888',
        '_links': {
          'effects': {'href': 'url'},
          'precedes': {'href': 'url'},
          'self': {'href': 'url'},
          'succeeds': {'href': 'url'},
          'transaction': {'href': 'url'}
        }
      };

      final response = AccountMergeOperationResponse.fromJson(json);

      expect(response.account, equals('GMERGED'));
      expect(response.accountMuxed, equals('MMERGED'));
      expect(response.accountMuxedId, equals('7777'));
      expect(response.into, equals('GDESTINATION'));
      expect(response.intoMuxed, equals('MDESTINATION'));
      expect(response.intoMuxedId, equals('8888'));
    });

    test('should parse BumpSequenceOperationResponse', () {
      final json = {
        'type_i': 11,
        'type': 'bump_sequence',
        'id': '902',
        'paging_token': '902',
        'transaction_successful': true,
        'source_account': 'GBUMP',
        'created_at': '2024-01-16T01:00:00Z',
        'transaction_hash': 'hash902',
        'bump_to': '12345678901234567',
        '_links': {
          'effects': {'href': 'url'},
          'precedes': {'href': 'url'},
          'self': {'href': 'url'},
          'succeeds': {'href': 'url'},
          'transaction': {'href': 'url'}
        }
      };

      final response = BumpSequenceOperationResponse.fromJson(json);

      expect(response.bumpTo, equals('12345678901234567'));
    });

    test('should parse InflationOperationResponse', () {
      final json = {
        'type_i': 9,
        'type': 'inflation',
        'id': '903',
        'paging_token': '903',
        'transaction_successful': true,
        'source_account': 'GINFLATION',
        'created_at': '2024-01-16T02:00:00Z',
        'transaction_hash': 'hash903',
        '_links': {
          'effects': {'href': 'url'},
          'precedes': {'href': 'url'},
          'self': {'href': 'url'},
          'succeeds': {'href': 'url'},
          'transaction': {'href': 'url'}
        }
      };

      final response = InflationOperationResponse.fromJson(json);

      expect(response.type, equals('inflation'));
      expect(response.sourceAccount, equals('GINFLATION'));
    });

    test('should parse SetTrustlineFlagsOperationResponse', () {
      final json = {
        'type_i': 21,
        'type': 'set_trustline_flags',
        'id': '904',
        'paging_token': '904',
        'transaction_successful': true,
        'source_account': 'GISSUER',
        'created_at': '2024-01-16T03:00:00Z',
        'transaction_hash': 'hash904',
        'trustor': 'GTRUSTOR',
        'asset_type': 'credit_alphanum4',
        'asset_code': 'USD',
        'asset_issuer': 'GISSUER',
        'set_flags': [1],
        'set_flags_s': ['authorized'],
        'clear_flags': [2],
        'clear_flags_s': ['authorized_to_maintain_liabilities'],
        '_links': {
          'effects': {'href': 'url'},
          'precedes': {'href': 'url'},
          'self': {'href': 'url'},
          'succeeds': {'href': 'url'},
          'transaction': {'href': 'url'}
        }
      };

      final response = SetTrustlineFlagsOperationResponse.fromJson(json);

      expect(response.trustor, equals('GTRUSTOR'));
      expect(response.assetType, equals('credit_alphanum4'));
      expect(response.assetCode, equals('USD'));
      expect(response.setFlagsInt, equals([1]));
      expect(response.setFlags, equals(['authorized']));
      expect(response.clearFlagsInt, equals([2]));
      expect(response.clearFlags, equals(['authorized_to_maintain_liabilities']));
    });

    test('should parse ExtendFootprintTTLOperationResponse', () {
      final json = {
        'type_i': 25,
        'type': 'extend_footprint_ttl',
        'id': '905',
        'paging_token': '905',
        'transaction_successful': true,
        'source_account': 'GEXTENDER',
        'created_at': '2024-01-16T04:00:00Z',
        'transaction_hash': 'hash905',
        'extend_to': 100000,
        '_links': {
          'effects': {'href': 'url'},
          'precedes': {'href': 'url'},
          'self': {'href': 'url'},
          'succeeds': {'href': 'url'},
          'transaction': {'href': 'url'}
        }
      };

      final response = ExtendFootprintTTLOperationResponse.fromJson(json);

      expect(response.extendTo, equals(100000));
    });

    test('should parse RestoreFootprintOperationResponse', () {
      final json = {
        'type_i': 26,
        'type': 'restore_footprint',
        'id': '906',
        'paging_token': '906',
        'transaction_successful': true,
        'source_account': 'GRESTORER',
        'created_at': '2024-01-16T05:00:00Z',
        'transaction_hash': 'hash906',
        '_links': {
          'effects': {'href': 'url'},
          'precedes': {'href': 'url'},
          'self': {'href': 'url'},
          'succeeds': {'href': 'url'},
          'transaction': {'href': 'url'}
        }
      };

      final response = RestoreFootprintOperationResponse.fromJson(json);

      expect(response.type, equals('restore_footprint'));
      expect(response.sourceAccount, equals('GRESTORER'));
    });

    test('should parse AllowTrustOperationResponse', () {
      final json = {
        'type_i': 7,
        'type': 'allow_trust',
        'id': '907',
        'paging_token': '907',
        'transaction_successful': true,
        'source_account': 'GISSUER',
        'created_at': '2024-01-16T06:00:00Z',
        'transaction_hash': 'hash907',
        'trustor': 'GTRUSTOR',
        'trustee': 'GISSUER',
        'trustee_muxed': 'MISSUER',
        'trustee_muxed_id': '9999',
        'asset_type': 'credit_alphanum4',
        'asset_code': 'EUR',
        'asset_issuer': 'GISSUER',
        'authorize': true,
        'authorize_to_maintain_liabilities': false,
        '_links': {
          'effects': {'href': 'url'},
          'precedes': {'href': 'url'},
          'self': {'href': 'url'},
          'succeeds': {'href': 'url'},
          'transaction': {'href': 'url'}
        }
      };

      final response = AllowTrustOperationResponse.fromJson(json);

      expect(response.trustor, equals('GTRUSTOR'));
      expect(response.trustee, equals('GISSUER'));
      expect(response.trusteeMuxed, equals('MISSUER'));
      expect(response.trusteeMuxedId, equals('9999'));
      expect(response.assetCode, equals('EUR'));
      expect(response.authorize, equals(true));
      expect(response.authorizeToMaintainLiabilities, equals(false));
    });

    test('should parse CreatePassiveSellOfferOperationResponse', () {
      final json = {
        'type_i': 4,
        'type': 'create_passive_sell_offer',
        'id': '908',
        'paging_token': '908',
        'transaction_successful': true,
        'source_account': 'GCREATOR',
        'created_at': '2024-01-16T07:00:00Z',
        'transaction_hash': 'hash908',
        'amount': '500.0',
        'price': '2.5',
        'price_r': {'n': 5, 'd': 2},
        'buying_asset_type': 'credit_alphanum12',
        'buying_asset_code': 'LONGASSETCODE',
        'buying_asset_issuer': 'GISSUER',
        'selling_asset_type': 'native',
        '_links': {
          'effects': {'href': 'url'},
          'precedes': {'href': 'url'},
          'self': {'href': 'url'},
          'succeeds': {'href': 'url'},
          'transaction': {'href': 'url'}
        }
      };

      final response = CreatePassiveSellOfferOperationResponse.fromJson(json);

      expect(response.amount, equals('500.0'));
      expect(response.price, equals('2.5'));
      expect(response.priceR.n, equals(5));
      expect(response.priceR.d, equals(2));
      expect(response.buyingAssetType, equals('credit_alphanum12'));
      expect(response.buyingAssetCode, equals('LONGASSETCODE'));
    });

    test('should parse ManageBuyOfferOperationResponse', () {
      final json = {
        'type_i': 12,
        'type': 'manage_buy_offer',
        'id': '909',
        'paging_token': '909',
        'transaction_successful': true,
        'source_account': 'GBUYER',
        'created_at': '2024-01-16T08:00:00Z',
        'transaction_hash': 'hash909',
        'offer_id': '999999',
        'amount': '250.0',
        'price': '0.8',
        'price_r': {'n': 4, 'd': 5},
        'buying_asset_type': 'native',
        'selling_asset_type': 'credit_alphanum4',
        'selling_asset_code': 'JPY',
        'selling_asset_issuer': 'GJPYISSUER',
        '_links': {
          'effects': {'href': 'url'},
          'precedes': {'href': 'url'},
          'self': {'href': 'url'},
          'succeeds': {'href': 'url'},
          'transaction': {'href': 'url'}
        }
      };

      final response = ManageBuyOfferOperationResponse.fromJson(json);

      expect(response.offerId, equals('999999'));
      expect(response.amount, equals('250.0'));
      expect(response.price, equals('0.8'));
      expect(response.sellingAssetCode, equals('JPY'));
    });

    test('should parse PathPaymentStrictSendOperationResponse', () {
      final json = {
        'type_i': 13,
        'type': 'path_payment_strict_send',
        'id': '910',
        'paging_token': '910',
        'transaction_successful': true,
        'source_account': 'GSENDER',
        'created_at': '2024-01-16T09:00:00Z',
        'transaction_hash': 'hash910',
        'from': 'GSENDER',
        'to': 'GRECEIVER',
        'source_amount': '100.0',
        'destination_min': '95.0',
        'amount': '97.0',
        'asset_type': 'credit_alphanum4',
        'asset_code': 'EUR',
        'asset_issuer': 'GEURISSUER',
        'source_asset_type': 'native',
        'path': [],
        '_links': {
          'effects': {'href': 'url'},
          'precedes': {'href': 'url'},
          'self': {'href': 'url'},
          'succeeds': {'href': 'url'},
          'transaction': {'href': 'url'}
        }
      };

      final response = PathPaymentStrictSendOperationResponse.fromJson(json);

      expect(response.sourceAmount, equals('100.0'));
      expect(response.destinationMin, equals('95.0'));
      expect(response.amount, equals('97.0'));
      expect(response.assetCode, equals('EUR'));
      expect(response.path, isEmpty);
    });
  });

  group('Nested Objects', () {
    test('should parse ParameterResponse with XDR value', () {
      final json = {
        'type': 'Symbol',
        'value': 'AAAADwAAAAh0cmFuc2Zlcg==' // Valid XDR for Symbol "transfer"
      };

      final parameter = ParameterResponse.fromJson(json);

      expect(parameter.type, equals('Symbol'));
      expect(parameter.value, equals('AAAADwAAAAh0cmFuc2Zlcg=='));

      // Test XDR decoding - just verify it doesn't throw
      expect(() => parameter.xdrValue(), returnsNormally);
    });

    test('should parse AssetBalanceChange with all fields', () {
      final json = {
        'type': 'transfer',
        'from': 'GFROM',
        'to': 'GTO',
        'amount': '123.456',
        'asset_type': 'credit_alphanum4',
        'asset_code': 'TEST',
        'asset_issuer': 'GISSUER',
        'destination_muxed_id': '54321'
      };

      final change = AssetBalanceChange.fromJson(json);

      expect(change.type, equals('transfer'));
      expect(change.from, equals('GFROM'));
      expect(change.to, equals('GTO'));
      expect(change.amount, equals('123.456'));
      expect(change.assetType, equals('credit_alphanum4'));
      expect(change.assetCode, equals('TEST'));
      expect(change.assetIssuer, equals('GISSUER'));
      expect(change.destinationMuxedId, equals('54321'));
    });

    test('should parse Price from JSON', () {
      final json = {'n': 3, 'd': 7};

      final price = Price.fromJson(json);

      expect(price.n, equals(3));
      expect(price.d, equals(7));
    });
  });

  group('Transaction embedding', () {
    test('should parse operation with embedded transaction', () {
      final json = {
        'type_i': 1,
        'type': 'payment',
        'id': '999',
        'paging_token': '999',
        'transaction_successful': true,
        'source_account': 'GABC123',
        'created_at': '2024-01-16T10:00:00Z',
        'transaction_hash': 'hash999',
        'from': 'GABC123',
        'to': 'GDEF456',
        'amount': '77.77',
        'asset_type': 'native',
        'transaction': {
          'id': 'tx999',
          'paging_token': 'tx999',
          'successful': true,
          'hash': 'hash999',
          'ledger': 12345,
          'created_at': '2024-01-16T10:00:00Z',
          'source_account': 'GABC123',
          'source_account_sequence': '98765432109876543',
          'fee_account': 'GABC123',
          'fee_charged': '100',
          'max_fee': '1000',
          'operation_count': 1,
          'envelope_xdr': 'AAAAAGL8HQvQkbK2HA3WVjRrKmjX00fG8sLI7m0ERwJW/AX3AAAAZAAAAAAAAAABAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAArqN6LeOagjxMaUP96Bzfs9e77YB9MoXn+/fD/d9ZC',
          'result_xdr': 'AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAA=',
          'result_meta_xdr': 'AAAAAQAAAAIAAAADAA==',
          'fee_meta_xdr': 'AAAAAgAAAAMAAAAA',
          'memo_type': 'none',
          'signatures': ['sig1', 'sig2'],
          '_links': {
            'self': {'href': 'url'},
            'account': {'href': 'url'},
            'ledger': {'href': 'url'},
            'operations': {'href': 'url'},
            'effects': {'href': 'url'},
            'precedes': {'href': 'url'},
            'succeeds': {'href': 'url'}
          }
        },
        '_links': {
          'effects': {'href': 'url'},
          'precedes': {'href': 'url'},
          'self': {'href': 'url'},
          'succeeds': {'href': 'url'},
          'transaction': {'href': 'url'}
        }
      };

      final response = PaymentOperationResponse.fromJson(json);

      expect(response.transaction, isNotNull);
      expect(response.transaction!.hash, equals('hash999'));
      expect(response.transaction!.ledger, equals(12345));
    });
  });
}

// Helper function to create minimal operation JSON for factory tests
Map<String, dynamic> _createMinimalOperationJson(int typeI) {
  final baseJson = {
    'type_i': typeI,
    'type': 'operation_type_$typeI',
    'id': '1000$typeI',
    'paging_token': '1000$typeI',
    'transaction_successful': true,
    'source_account': 'GABC123',
    'created_at': '2024-01-01T00:00:00Z',
    'transaction_hash': 'hash$typeI',
    '_links': {
      'effects': {'href': 'url'},
      'precedes': {'href': 'url'},
      'self': {'href': 'url'},
      'succeeds': {'href': 'url'},
      'transaction': {'href': 'url'}
    }
  };

  // Add type-specific required fields
  switch (typeI) {
    case 0: // CreateAccount
      baseJson.addAll({
        'funder': 'GFUNDER',
        'starting_balance': '100.0',
        'account': 'GNEWACCOUNT',
      });
      break;
    case 1: // Payment
      baseJson.addAll({
        'from': 'GFROM',
        'to': 'GTO',
        'amount': '50.0',
        'asset_type': 'native',
      });
      break;
    case 2: // PathPaymentStrictReceive
      baseJson.addAll({
        'from': 'GFROM',
        'to': 'GTO',
        'amount': '100.0',
        'source_amount': '105.0',
        'source_max': '110.0',
        'asset_type': 'native',
        'source_asset_type': 'native',
        'path': [],
      });
      break;
    case 3: // ManageSellOffer
      baseJson.addAll({
        'offer_id': '0',
        'amount': '100.0',
        'price': '1.0',
        'price_r': {'n': 1, 'd': 1},
        'buying_asset_type': 'native',
        'selling_asset_type': 'native',
      });
      break;
    case 4: // CreatePassiveSellOffer
      baseJson.addAll({
        'amount': '100.0',
        'price': '1.0',
        'price_r': {'n': 1, 'd': 1},
        'buying_asset_type': 'native',
        'selling_asset_type': 'native',
      });
      break;
    case 5: // SetOptions
      // No required fields beyond base
      break;
    case 6: // ChangeTrust
      baseJson.addAll({
        'trustor': 'GTRUSTOR',
        'asset_type': 'native',
        'limit': '1000.0',
      });
      break;
    case 7: // AllowTrust
      baseJson.addAll({
        'trustor': 'GTRUSTOR',
        'trustee': 'GTRUSTEE',
        'asset_type': 'credit_alphanum4',
        'asset_code': 'TEST',
        'asset_issuer': 'GISSUER',
        'authorize': false,
        'authorize_to_maintain_liabilities': false,
      });
      break;
    case 8: // AccountMerge
      baseJson.addAll({
        'account': 'GACCOUNT',
        'into': 'GINTO',
      });
      break;
    case 9: // Inflation
      // No required fields beyond base
      break;
    case 10: // ManageData
      baseJson.addAll({
        'name': 'test',
        'value': 'dGVzdA==',
      });
      break;
    case 11: // BumpSequence
      baseJson.addAll({
        'bump_to': '123456789',
      });
      break;
    case 12: // ManageBuyOffer
      baseJson.addAll({
        'offer_id': '0',
        'amount': '100.0',
        'price': '1.0',
        'price_r': {'n': 1, 'd': 1},
        'buying_asset_type': 'native',
        'selling_asset_type': 'native',
      });
      break;
    case 13: // PathPaymentStrictSend
      baseJson.addAll({
        'from': 'GFROM',
        'to': 'GTO',
        'source_amount': '100.0',
        'destination_min': '95.0',
        'amount': '97.0',
        'asset_type': 'native',
        'source_asset_type': 'native',
        'path': [],
      });
      break;
    case 14: // CreateClaimableBalance
      baseJson.addAll({
        'sponsor': 'GSPONSOR',
        'asset': 'native',
        'amount': '100.0',
        'claimants': [],
      });
      break;
    case 15: // ClaimClaimableBalance
      baseJson.addAll({
        'claimant': 'GCLAIMANT',
        'balance_id': '00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072',
      });
      break;
    case 16: // BeginSponsoringFutureReserves
      baseJson.addAll({
        'sponsored_id': 'GSPONSORED',
      });
      break;
    case 17: // EndSponsoringFutureReserves
      baseJson.addAll({
        'begin_sponsor': 'GBEGIN',
      });
      break;
    case 18: // RevokeSponsorship
      // No strictly required fields beyond base
      break;
    case 19: // Clawback
      baseJson.addAll({
        'asset_type': 'native',
        'from': 'GFROM',
        'amount': '100.0',
      });
      break;
    case 20: // ClawbackClaimableBalance
      baseJson.addAll({
        'balance_id': '00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072',
      });
      break;
    case 21: // SetTrustlineFlags
      baseJson.addAll({
        'trustor': 'GTRUSTOR',
        'asset_type': 'native',
      });
      break;
    case 22: // LiquidityPoolDeposit
      baseJson.addAll({
        'liquidity_pool_id': 'pool123',
        'reserves_max': [],
        'min_price': '0.5',
        'min_price_r': {'n': 1, 'd': 2},
        'max_price': '2.0',
        'max_price_r': {'n': 2, 'd': 1},
        'reserves_deposited': [],
        'shares_received': '100.0',
      });
      break;
    case 23: // LiquidityPoolWithdraw
      baseJson.addAll({
        'liquidity_pool_id': 'pool123',
        'shares': '100.0',
        'reserves_min': [],
        'reserves_received': [],
      });
      break;
    case 24: // InvokeHostFunction
      baseJson.addAll({
        'function': 'HostFunctionTypeInvokeContract',
        'address': 'CCONTRACT',
        'salt': 'salt',
      });
      break;
    case 25: // ExtendFootprintTTL
      baseJson.addAll({
        'extend_to': 100000,
      });
      break;
    case 26: // RestoreFootprint
      // No required fields beyond base
      break;
  }

  return baseJson;
}