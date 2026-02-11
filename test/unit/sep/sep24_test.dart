// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('SEP24DepositAsset', () {
    test('fromJson with all fields', () {
      final json = {
        'enabled': true,
        'min_amount': 10.0,
        'max_amount': 1000.0,
        'fee_fixed': 1.5,
        'fee_percent': 0.5,
        'fee_minimum': 0.5,
      };

      final asset = SEP24DepositAsset.fromJson(json);

      expect(asset.enabled, isTrue);
      expect(asset.minAmount, equals(10.0));
      expect(asset.maxAmount, equals(1000.0));
      expect(asset.feeFixed, equals(1.5));
      expect(asset.feePercent, equals(0.5));
      expect(asset.feeMinimum, equals(0.5));
    });

    test('fromJson with minimal fields', () {
      final json = {
        'enabled': false,
      };

      final asset = SEP24DepositAsset.fromJson(json);

      expect(asset.enabled, isFalse);
      expect(asset.minAmount, isNull);
      expect(asset.maxAmount, isNull);
      expect(asset.feeFixed, isNull);
      expect(asset.feePercent, isNull);
      expect(asset.feeMinimum, isNull);
    });

    test('fromJson with null fee fields', () {
      final json = {
        'enabled': true,
        'min_amount': 5.0,
        'max_amount': 500.0,
        'fee_fixed': null,
        'fee_percent': null,
        'fee_minimum': null,
      };

      final asset = SEP24DepositAsset.fromJson(json);

      expect(asset.enabled, isTrue);
      expect(asset.minAmount, equals(5.0));
      expect(asset.maxAmount, equals(500.0));
      expect(asset.feeFixed, isNull);
      expect(asset.feePercent, isNull);
      expect(asset.feeMinimum, isNull);
    });
  });

  group('SEP24WithdrawAsset', () {
    test('fromJson with all fields', () {
      final json = {
        'enabled': true,
        'min_amount': 20.0,
        'max_amount': 5000.0,
        'fee_fixed': 2.0,
        'fee_percent': 1.0,
        'fee_minimum': 1.0,
      };

      final asset = SEP24WithdrawAsset.fromJson(json);

      expect(asset.enabled, isTrue);
      expect(asset.minAmount, equals(20.0));
      expect(asset.maxAmount, equals(5000.0));
      expect(asset.feeFixed, equals(2.0));
      expect(asset.feePercent, equals(1.0));
      expect(asset.feeMinimum, equals(1.0));
    });

    test('fromJson with disabled asset', () {
      final json = {
        'enabled': false,
        'min_amount': 0.0,
        'max_amount': 0.0,
      };

      final asset = SEP24WithdrawAsset.fromJson(json);

      expect(asset.enabled, isFalse);
    });
  });

  group('FeeEndpointInfo', () {
    test('fromJson with authentication required', () {
      final json = {
        'enabled': true,
        'authentication_required': true,
      };

      final info = FeeEndpointInfo.fromJson(json);

      expect(info.enabled, isTrue);
      expect(info.authenticationRequired, isTrue);
    });

    test('fromJson without authentication required', () {
      final json = {
        'enabled': true,
        'authentication_required': false,
      };

      final info = FeeEndpointInfo.fromJson(json);

      expect(info.enabled, isTrue);
      expect(info.authenticationRequired, isFalse);
    });

    test('fromJson with null authentication required defaults to false', () {
      final json = {
        'enabled': true,
      };

      final info = FeeEndpointInfo.fromJson(json);

      expect(info.enabled, isTrue);
      expect(info.authenticationRequired, isFalse);
    });

    test('fromJson with disabled endpoint', () {
      final json = {
        'enabled': false,
        'authentication_required': false,
      };

      final info = FeeEndpointInfo.fromJson(json);

      expect(info.enabled, isFalse);
    });
  });

  group('FeatureFlags', () {
    test('fromJson with both features enabled', () {
      final json = {
        'account_creation': true,
        'claimable_balances': true,
      };

      final flags = FeatureFlags.fromJson(json);

      expect(flags.accountCreation, isTrue);
      expect(flags.claimableBalances, isTrue);
    });

    test('fromJson with both features disabled', () {
      final json = {
        'account_creation': false,
        'claimable_balances': false,
      };

      final flags = FeatureFlags.fromJson(json);

      expect(flags.accountCreation, isFalse);
      expect(flags.claimableBalances, isFalse);
    });

    test('fromJson with defaults when fields are null', () {
      final json = <String, dynamic>{};

      final flags = FeatureFlags.fromJson(json);

      expect(flags.accountCreation, isTrue);
      expect(flags.claimableBalances, isFalse);
    });

    test('fromJson with partial fields', () {
      final json = {
        'account_creation': false,
      };

      final flags = FeatureFlags.fromJson(json);

      expect(flags.accountCreation, isFalse);
      expect(flags.claimableBalances, isFalse);
    });
  });

  group('SEP24InfoResponse', () {
    test('fromJson with deposit and withdraw assets', () {
      final json = {
        'deposit': {
          'USD': {
            'enabled': true,
            'min_amount': 10.0,
            'max_amount': 1000.0,
          },
          'EUR': {
            'enabled': false,
          },
        },
        'withdraw': {
          'USD': {
            'enabled': true,
            'min_amount': 20.0,
            'max_amount': 500.0,
          },
        },
        'fee': {
          'enabled': true,
          'authentication_required': true,
        },
        'features': {
          'account_creation': true,
          'claimable_balances': false,
        },
      };

      final response = SEP24InfoResponse.fromJson(json);

      expect(response.depositAssets, isNotNull);
      expect(response.depositAssets!.length, equals(2));
      expect(response.depositAssets!['USD']!.enabled, isTrue);
      expect(response.depositAssets!['EUR']!.enabled, isFalse);

      expect(response.withdrawAssets, isNotNull);
      expect(response.withdrawAssets!.length, equals(1));
      expect(response.withdrawAssets!['USD']!.enabled, isTrue);

      expect(response.feeEndpointInfo, isNotNull);
      expect(response.feeEndpointInfo!.enabled, isTrue);

      expect(response.featureFlags, isNotNull);
      expect(response.featureFlags!.accountCreation, isTrue);
    });

    test('fromJson with no  assets', () {
      final json = {
        'deposit': {
          'BTC': {
            'enabled': true,
          },
        },
        'withdraw': {
          'BTC': {
            'enabled': false,
          },
        },
        'fee': null,
        'features': null,
      };

      final response = SEP24InfoResponse.fromJson(json);

      expect(response.depositAssets!.length, equals(1));
      expect(response.withdrawAssets!.length, equals(1));
      expect(response.feeEndpointInfo, isNull);
      expect(response.featureFlags, isNull);
    });
  });

  group('SEP24FeeResponse', () {
    test('fromJson with fee amount', () {
      final json = {
        'fee': 5.50,
      };

      final response = SEP24FeeResponse.fromJson(json);

      expect(response.fee, equals(5.50));
    });

    test('fromJson with zero fee', () {
      final json = {
        'fee': 0.0,
      };

      final response = SEP24FeeResponse.fromJson(json);

      expect(response.fee, equals(0.0));
    });

    test('fromJson with null fee', () {
      final json = {
        'fee': null,
      };

      final response = SEP24FeeResponse.fromJson(json);

      expect(response.fee, isNull);
    });
  });

  group('SEP24InteractiveResponse', () {
    test('fromJson with all fields', () {
      final json = {
        'type': 'interactive_customer_info_needed',
        'url': 'https://anchor.example.com/kyc?id=12345',
        'id': 'transaction_12345',
      };

      final response = SEP24InteractiveResponse.fromJson(json);

      expect(response.type, equals('interactive_customer_info_needed'));
      expect(response.url,
          equals('https://anchor.example.com/kyc?id=12345'));
      expect(response.id, equals('transaction_12345'));
    });

    test('fromJson with different transaction ID', () {
      final json = {
        'type': 'interactive_customer_info_needed',
        'url': 'https://another-anchor.com/deposit',
        'id': 'tx_abc_def_ghi',
      };

      final response = SEP24InteractiveResponse.fromJson(json);

      expect(response.id, equals('tx_abc_def_ghi'));
    });
  });

  group('SEP24Transaction', () {
    test('fromJson with complete transaction data', () {
      final json = {
        'id': 'tx_001',
        'kind': 'deposit',
        'status': 'completed',
        'status_eta': 300,
        'kyc_verified': true,
        'more_info_url': 'https://anchor.com/more/tx_001',
        'amount_in': '100.0',
        'amount_in_asset': 'USD',
        'amount_out': '99.5',
        'amount_out_asset': 'USDC',
        'amount_fee': '0.5',
        'amount_fee_asset': 'USD',
        'quote_id': 'quote_123',
        'started_at': '2021-01-01T00:00:00Z',
        'completed_at': '2021-01-01T01:00:00Z',
        'updated_at': '2021-01-01T01:00:00Z',
        'user_action_required_by': '2021-01-02T00:00:00Z',
        'stellar_transaction_id': 'stellar_tx_456',
        'external_transaction_id': 'external_tx_789',
        'message': 'Transaction completed successfully',
        'refunded': false,
        'from': 'bank_account_001',
        'to': 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        'deposit_memo': 'memo_001',
        'deposit_memo_type': 'text',
        'claimable_balance_id': 'balance_001',
        'withdraw_anchor_account': null,
        'withdraw_memo': null,
        'withdraw_memo_type': null,
      };

      final transaction = SEP24Transaction.fromJson(json);

      expect(transaction.id, equals('tx_001'));
      expect(transaction.kind, equals('deposit'));
      expect(transaction.status, equals('completed'));
      expect(transaction.statusEta, equals(300));
      expect(transaction.kycVerified, isTrue);
      expect(transaction.amountIn, equals('100.0'));
      expect(transaction.amountOut, equals('99.5'));
      expect(transaction.amountFee, equals('0.5'));
      expect(transaction.quoteId, equals('quote_123'));
      expect(transaction.refunded, isFalse);
    });

    test('fromJson with refunds object', () {
      final json = {
        'id': 'tx_002',
        'kind': 'withdrawal',
        'status': 'refunded',
        'more_info_url': 'https://anchor.com/more/tx_002',
        'started_at': '2021-02-01T00:00:00Z',
        'refunds': {
          'amount_refunded': '95.0',
          'amount_fee': '5.0',
          'payments': [
            {
              'id': 'refund_payment_001',
              'id_type': 'stellar',
              'amount': '95.0',
              'fee': '5.0',
            }
          ],
        },
      };

      final transaction = SEP24Transaction.fromJson(json);

      expect(transaction.refunds, isNotNull);
      expect(transaction.refunds!.amountRefunded, equals('95.0'));
      expect(transaction.refunds!.amountFee, equals('5.0'));
      expect(transaction.refunds!.payments.length, equals(1));
    });

    test('fromJson with minimal fields', () {
      final json = {
        'id': 'tx_003',
        'kind': 'deposit',
        'status': 'pending_user_transfer_start',
        'more_info_url': 'https://anchor.com/more/tx_003',
        'started_at': '2021-03-01T00:00:00Z',
      };

      final transaction = SEP24Transaction.fromJson(json);

      expect(transaction.id, equals('tx_003'));
      expect(transaction.statusEta, isNull);
      expect(transaction.amountIn, isNull);
      expect(transaction.refunds, isNull);
    });

    test('fromJson with withdrawal fields', () {
      final json = {
        'id': 'tx_004',
        'kind': 'withdrawal',
        'status': 'pending_stellar',
        'more_info_url': 'https://anchor.com/more/tx_004',
        'started_at': '2021-04-01T00:00:00Z',
        'withdraw_anchor_account':
            'GAANCHOR123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ',
        'withdraw_memo': '123456',
        'withdraw_memo_type': 'id',
      };

      final transaction = SEP24Transaction.fromJson(json);

      expect(transaction.kind, equals('withdrawal'));
      expect(transaction.withdrawAnchorAccount,
          equals('GAANCHOR123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'));
      expect(transaction.withdrawMemo, equals('123456'));
      expect(transaction.withdrawMemoType, equals('id'));
    });
  });

  group('Refund', () {
    test('fromJson with multiple payments', () {
      final json = {
        'amount_refunded': '100.0',
        'amount_fee': '10.0',
        'payments': [
          {
            'id': 'payment_001',
            'id_type': 'stellar',
            'amount': '50.0',
            'fee': '5.0',
          },
          {
            'id': 'payment_002',
            'id_type': 'external',
            'amount': '50.0',
            'fee': '5.0',
          },
        ],
      };

      final refund = Refund.fromJson(json);

      expect(refund.amountRefunded, equals('100.0'));
      expect(refund.amountFee, equals('10.0'));
      expect(refund.payments.length, equals(2));
      expect(refund.payments[0].id, equals('payment_001'));
      expect(refund.payments[1].idType, equals('external'));
    });

    test('fromJson with empty payments list', () {
      final json = {
        'amount_refunded': '0.0',
        'amount_fee': '0.0',
        'payments': [],
      };

      final refund = Refund.fromJson(json);

      expect(refund.payments.length, equals(0));
    });
  });

  group('RefundPayment', () {
    test('fromJson with all fields', () {
      final json = {
        'id': 'stellar_tx_hash_123',
        'id_type': 'stellar',
        'amount': '75.5',
        'fee': '4.5',
      };

      final payment = RefundPayment.fromJson(json);

      expect(payment.id, equals('stellar_tx_hash_123'));
      expect(payment.idType, equals('stellar'));
      expect(payment.amount, equals('75.5'));
      expect(payment.fee, equals('4.5'));
    });

    test('fromJson with external payment', () {
      final json = {
        'id': 'bank_ref_456',
        'id_type': 'external',
        'amount': '100.0',
        'fee': '10.0',
      };

      final payment = RefundPayment.fromJson(json);

      expect(payment.idType, equals('external'));
      expect(payment.id, equals('bank_ref_456'));
    });
  });

  group('SEP24TransactionsResponse', () {
    test('fromJson with multiple transactions', () {
      final json = {
        'transactions': [
          {
            'id': 'tx_001',
            'kind': 'deposit',
            'status': 'completed',
            'more_info_url': 'https://anchor.com/more/tx_001',
            'started_at': '2021-01-01T00:00:00Z',
          },
          {
            'id': 'tx_002',
            'kind': 'withdrawal',
            'status': 'pending',
            'more_info_url': 'https://anchor.com/more/tx_002',
            'started_at': '2021-01-02T00:00:00Z',
          },
        ],
      };

      final response = SEP24TransactionsResponse.fromJson(json);

      expect(response.transactions.length, equals(2));
      expect(response.transactions[0].id, equals('tx_001'));
      expect(response.transactions[1].kind, equals('withdrawal'));
    });

    test('fromJson with empty transactions list', () {
      final json = {
        'transactions': [],
      };

      final response = SEP24TransactionsResponse.fromJson(json);

      expect(response.transactions.length, equals(0));
    });
  });

  group('SEP24TransactionResponse', () {
    test('fromJson wraps single transaction', () {
      final json = {
        'transaction': {
          'id': 'tx_single',
          'kind': 'deposit',
          'status': 'completed',
          'more_info_url': 'https://anchor.com/more/tx_single',
          'started_at': '2021-05-01T00:00:00Z',
        },
      };

      final response = SEP24TransactionResponse.fromJson(json);

      expect(response.transaction.id, equals('tx_single'));
      expect(response.transaction.kind, equals('deposit'));
    });
  });

  group('SEP24 Exceptions', () {
    test('RequestErrorException toString returns error message', () {
      final exception = RequestErrorException('Invalid parameters');

      expect(exception.toString(), equals('Invalid parameters'));
    });

    test('SEP24AuthenticationRequiredException has correct message', () {
      final exception = SEP24AuthenticationRequiredException();

      expect(exception.toString(),
          equals('The endpoint requires authentication.'));
    });

    test('SEP24TransactionNotFoundException has correct message', () {
      final exception = SEP24TransactionNotFoundException();

      expect(exception.toString(),
          equals('The anchor could not find the transaction'));
    });
  });

  group('SEP24 Request classes', () {
    test('SEP24FeeRequest has correct fields', () {
      final request = SEP24FeeRequest()
        ..operation = 'deposit'
        ..type = 'SEPA'
        ..assetCode = 'USD'
        ..amount = 100.0
        ..jwt = 'test_jwt_token';

      expect(request.operation, equals('deposit'));
      expect(request.type, equals('SEPA'));
      expect(request.assetCode, equals('USD'));
      expect(request.amount, equals(100.0));
      expect(request.jwt, equals('test_jwt_token'));
    });

    test('SEP24DepositRequest has correct fields', () {
      final request = SEP24DepositRequest()
        ..jwt = 'test_jwt'
        ..assetCode = 'EUR'
        ..assetIssuer = 'GAISSUER...'
        ..sourceAsset = 'iso4217:EUR'
        ..amount = '500.0'
        ..quoteId = 'quote_123'
        ..account = 'GABC...'
        ..memo = 'test_memo'
        ..memoType = 'text'
        ..walletName = 'TestWallet'
        ..walletUrl = 'https://wallet.example.com'
        ..lang = 'en-US'
        ..claimableBalanceSupported = 'true';

      expect(request.assetCode, equals('EUR'));
      expect(request.amount, equals('500.0'));
      expect(request.walletName, equals('TestWallet'));
      expect(request.claimableBalanceSupported, equals('true'));
    });

    test('SEP24DepositRequest with KYC fields and custom data', () {
      final request = SEP24DepositRequest()
        ..jwt = 'test_jwt'
        ..assetCode = 'USD'
        ..customFields = {'custom_field': 'custom_value'}
        ..customFiles = {'document': Uint8List.fromList([1, 2, 3])};

      expect(request.customFields, isNotNull);
      expect(request.customFields!['custom_field'], equals('custom_value'));
      expect(request.customFiles, isNotNull);
    });

    test('SEP24WithdrawRequest has correct fields', () {
      final request = SEP24WithdrawRequest()
        ..jwt = 'test_jwt'
        ..assetCode = 'GBP'
        ..destinationAsset = 'iso4217:GBP'
        ..amount = '200.0'
        ..quoteId = 'quote_456'
        ..account = 'GXYZ...'
        ..walletName = 'WithdrawWallet'
        ..walletUrl = 'https://withdraw.example.com'
        ..lang = 'en-GB'
        ..refundMemo = 'refund_memo'
        ..refundMemoType = 'hash';

      expect(request.assetCode, equals('GBP'));
      expect(request.destinationAsset, equals('iso4217:GBP'));
      expect(request.refundMemo, equals('refund_memo'));
      expect(request.refundMemoType, equals('hash'));
    });

    test('SEP24TransactionsRequest has correct fields', () {
      final request = SEP24TransactionsRequest()
        ..jwt = 'test_jwt'
        ..assetCode = 'BTC'
        ..noOlderThan = DateTime(2021, 1, 1)
        ..limit = 10
        ..kind = 'deposit'
        ..pagingId = 'paging_123'
        ..lang = 'es-ES';

      expect(request.assetCode, equals('BTC'));
      expect(request.limit, equals(10));
      expect(request.kind, equals('deposit'));
      expect(request.lang, equals('es-ES'));
    });

    test('SEP24TransactionRequest has correct fields', () {
      final request = SEP24TransactionRequest()
        ..jwt = 'test_jwt'
        ..id = 'tx_id_123'
        ..stellarTransactionId = 'stellar_tx_456'
        ..externalTransactionId = 'external_tx_789'
        ..lang = 'fr-FR';

      expect(request.id, equals('tx_id_123'));
      expect(request.stellarTransactionId, equals('stellar_tx_456'));
      expect(request.externalTransactionId, equals('external_tx_789'));
      expect(request.lang, equals('fr-FR'));
    });
  });

  group('SEP-24 Info Endpoint', () {
    test('parse info with all deposit and withdraw asset configurations', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/info'));
        expect(request.headers.containsKey('Authorization'), false);

        return http.Response(json.encode({
          'deposit': {
            'USD': {
              'enabled': true,
              'min_amount': 10.0,
              'max_amount': 10000.0,
              'fee_fixed': 5.0,
              'fee_percent': 1.0,
              'fee_minimum': 2.0
            },
            'BTC': {
              'enabled': true,
              'min_amount': 0.001,
              'max_amount': 10.0,
              'fee_fixed': 0.0001,
              'fee_percent': 0.5,
              'fee_minimum': 0.00005
            }
          },
          'withdraw': {
            'USD': {
              'enabled': true,
              'min_amount': 50.0,
              'max_amount': 5000.0,
              'fee_fixed': 10.0,
              'fee_percent': 0.5,
              'fee_minimum': 5.0
            }
          },
          'fee': {
            'enabled': true,
            'authentication_required': false
          },
          'features': {
            'account_creation': true,
            'claimable_balances': true
          }
        }), 200);
      });

      final service = TransferServerSEP24Service(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final response = await service.info();

      expect(response.depositAssets, isNotNull);
      expect(response.depositAssets!.length, 2);

      final usdDeposit = response.depositAssets!['USD']!;
      expect(usdDeposit.enabled, true);
      expect(usdDeposit.minAmount, 10.0);
      expect(usdDeposit.maxAmount, 10000.0);
      expect(usdDeposit.feeFixed, 5.0);
      expect(usdDeposit.feePercent, 1.0);
      expect(usdDeposit.feeMinimum, 2.0);

      final btcDeposit = response.depositAssets!['BTC']!;
      expect(btcDeposit.enabled, true);
      expect(btcDeposit.minAmount, 0.001);
      expect(btcDeposit.feeFixed, 0.0001);

      expect(response.withdrawAssets, isNotNull);
      expect(response.withdrawAssets!.length, 1);

      final usdWithdraw = response.withdrawAssets!['USD']!;
      expect(usdWithdraw.enabled, true);
      expect(usdWithdraw.minAmount, 50.0);
      expect(usdWithdraw.feeFixed, 10.0);
      expect(usdWithdraw.feeMinimum, 5.0);

      expect(response.feeEndpointInfo, isNotNull);
      expect(response.feeEndpointInfo!.enabled, true);
      expect(response.feeEndpointInfo!.authenticationRequired, false);

      expect(response.featureFlags, isNotNull);
      expect(response.featureFlags!.accountCreation, true);
      expect(response.featureFlags!.claimableBalances, true);
    });

    test('parse info with language parameter', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/info'));
        expect(request.url.queryParameters['lang'], 'es');

        return http.Response(json.encode({
          'deposit': {},
          'withdraw': {}
        }), 200);
      });

      final service = TransferServerSEP24Service(
        'https://api.example.com',
        httpClient: mockClient,
      );

      await service.info('es');
    });

    test('parse info with authentication required fee endpoint', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'deposit': {},
          'withdraw': {},
          'fee': {
            'enabled': true,
            'authentication_required': true
          }
        }), 200);
      });

      final service = TransferServerSEP24Service(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final response = await service.info();
      expect(response.feeEndpointInfo!.enabled, true);
      expect(response.feeEndpointInfo!.authenticationRequired, true);
    });
  });

  group('SEP-24 Fee Endpoint', () {
    test('get fee for deposit operation with authentication', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/fee'));
        expect(request.url.queryParameters['operation'], 'deposit');
        expect(request.url.queryParameters['asset_code'], 'USD');
        expect(request.url.queryParameters['amount'], anyOf(equals('100.0'), equals('100')));
        expect(request.headers['Authorization'], 'Bearer test-jwt');

        return http.Response(json.encode({
          'fee': 5.0
        }), 200);
      });

      final service = TransferServerSEP24Service(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = SEP24FeeRequest()
        ..operation = 'deposit'
        ..assetCode = 'USD'
        ..amount = 100.0
        ..jwt = 'test-jwt';

      final response = await service.fee(request);
      expect(response.fee, equals(5.0));
    });

    test('get fee for withdraw operation with type', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/fee'));
        expect(request.url.queryParameters['operation'], 'withdraw');
        expect(request.url.queryParameters['asset_code'], 'BTC');
        expect(request.url.queryParameters['amount'], '0.5');
        expect(request.url.queryParameters['type'], 'SEPA');
        expect(request.headers['Authorization'], 'Bearer test-jwt');

        return http.Response(json.encode({
          'fee': 0.0005
        }), 200);
      });

      final service = TransferServerSEP24Service(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = SEP24FeeRequest()
        ..operation = 'withdraw'
        ..assetCode = 'BTC'
        ..amount = 0.5
        ..type = 'SEPA'
        ..jwt = 'test-jwt';

      final response = await service.fee(request);
      expect(response.fee, 0.0005);
    });

    test('fee endpoint throws authentication required exception', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'type': 'authentication_required'
        }), 403);
      });

      final service = TransferServerSEP24Service(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = SEP24FeeRequest()
        ..operation = 'deposit'
        ..assetCode = 'USD'
        ..amount = 100.0;

      expect(
        () => service.fee(request),
        throwsA(isA<SEP24AuthenticationRequiredException>()),
      );
    });

    test('fee endpoint throws request error exception', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'error': 'Invalid asset_code parameter'
        }), 400);
      });

      final service = TransferServerSEP24Service(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = SEP24FeeRequest()
        ..operation = 'deposit'
        ..assetCode = 'INVALID'
        ..amount = 100.0
        ..jwt = 'test-jwt';

      expect(
        () => service.fee(request),
        throwsA(isA<RequestErrorException>()),
      );
    });
  });

  group('SEP-24 Deposit Endpoint', () {
    test('deposit returns interactive URL with all fields', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/transactions/deposit/interactive'));
        expect(request.method, 'POST');
        expect(request.headers['Authorization'], 'Bearer test-jwt');

        return http.Response(json.encode({
          'type': 'interactive_customer_info_needed',
          'url': 'https://anchor.example.com/deposit/interactive?id=abc123',
          'id': 'deposit-abc123'
        }), 200);
      });

      final service = TransferServerSEP24Service(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = SEP24DepositRequest()
        ..assetCode = 'USD'
        ..account = 'GXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
        ..amount = '100.0'
        ..jwt = 'test-jwt';

      final response = await service.deposit(request);

      expect(response.type, 'interactive_customer_info_needed');
      expect(response.url, 'https://anchor.example.com/deposit/interactive?id=abc123');
      expect(response.id, 'deposit-abc123');
    });

    test('deposit with all optional parameters', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/transactions/deposit/interactive'));
        expect(request.method, 'POST');

        return http.Response(json.encode({
          'type': 'interactive_customer_info_needed',
          'url': 'https://anchor.example.com/deposit/interactive',
          'id': 'deposit-xyz789'
        }), 200);
      });

      final service = TransferServerSEP24Service(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = SEP24DepositRequest()
        ..assetCode = 'USD'
        ..assetIssuer = 'GISSUERXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
        ..sourceAsset = 'iso4217:USD'
        ..amount = '500.0'
        ..quoteId = 'quote-123'
        ..account = 'GXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
        ..memo = 'test-memo'
        ..memoType = 'text'
        ..walletName = 'Test Wallet'
        ..walletUrl = 'https://wallet.example.com'
        ..lang = 'es'
        ..claimableBalanceSupported = 'true'
        ..jwt = 'test-jwt';

      final response = await service.deposit(request);

      expect(response.id, 'deposit-xyz789');
    });

    test('deposit throws authentication required exception', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'type': 'authentication_required'
        }), 403);
      });

      final service = TransferServerSEP24Service(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = SEP24DepositRequest()
        ..assetCode = 'USD'
        ..account = 'GXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
        ..jwt = 'test-jwt';

      expect(
        () => service.deposit(request),
        throwsA(isA<SEP24AuthenticationRequiredException>()),
      );
    });

    test('deposit throws request error exception', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'error': 'Unsupported asset'
        }), 400);
      });

      final service = TransferServerSEP24Service(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = SEP24DepositRequest()
        ..assetCode = 'UNSUPPORTED'
        ..account = 'GXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
        ..jwt = 'test-jwt';

      expect(
        () => service.deposit(request),
        throwsA(isA<RequestErrorException>()),
      );
    });
  });

  group('SEP-24 Withdraw Endpoint', () {
    test('withdraw returns interactive URL with all fields', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/transactions/withdraw/interactive'));
        expect(request.method, 'POST');
        expect(request.headers['Authorization'], 'Bearer test-jwt');

        return http.Response(json.encode({
          'type': 'interactive_customer_info_needed',
          'url': 'https://anchor.example.com/withdraw/interactive?id=def456',
          'id': 'withdraw-def456'
        }), 200);
      });

      final service = TransferServerSEP24Service(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = SEP24WithdrawRequest()
        ..assetCode = 'USD'
        ..account = 'GXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
        ..amount = '50.0'
        ..jwt = 'test-jwt';

      final response = await service.withdraw(request);

      expect(response.type, 'interactive_customer_info_needed');
      expect(response.url, 'https://anchor.example.com/withdraw/interactive?id=def456');
      expect(response.id, 'withdraw-def456');
    });

    test('withdraw with all optional parameters', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/transactions/withdraw/interactive'));
        expect(request.method, 'POST');

        return http.Response(json.encode({
          'type': 'interactive_customer_info_needed',
          'url': 'https://anchor.example.com/withdraw/interactive',
          'id': 'withdraw-uvw123'
        }), 200);
      });

      final service = TransferServerSEP24Service(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = SEP24WithdrawRequest()
        ..assetCode = 'USD'
        ..assetIssuer = 'GISSUERXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
        ..destinationAsset = 'iso4217:EUR'
        ..amount = '1000.0'
        ..quoteId = 'quote-456'
        ..account = 'GXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
        ..memo = 'withdraw-memo'
        ..memoType = 'id'
        ..walletName = 'Test Wallet'
        ..walletUrl = 'https://wallet.example.com'
        ..lang = 'fr'
        ..refundMemo = 'refund-memo'
        ..refundMemoType = 'text'
        ..jwt = 'test-jwt';

      final response = await service.withdraw(request);

      expect(response.id, 'withdraw-uvw123');
    });

    test('withdraw throws authentication required exception', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'type': 'authentication_required'
        }), 403);
      });

      final service = TransferServerSEP24Service(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = SEP24WithdrawRequest()
        ..assetCode = 'USD'
        ..account = 'GXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
        ..jwt = 'test-jwt';

      expect(
        () => service.withdraw(request),
        throwsA(isA<SEP24AuthenticationRequiredException>()),
      );
    });

    test('withdraw throws request error exception', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'error': 'Amount exceeds maximum'
        }), 400);
      });

      final service = TransferServerSEP24Service(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = SEP24WithdrawRequest()
        ..assetCode = 'USD'
        ..amount = '999999.0'
        ..jwt = 'test-jwt';

      expect(
        () => service.withdraw(request),
        throwsA(isA<RequestErrorException>()),
      );
    });
  });

  group('SEP-24 Transactions Endpoint', () {
    test('get transactions with all statuses', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/transactions'));
        expect(request.url.queryParameters['asset_code'], 'USD');
        expect(request.headers['Authorization'], 'Bearer test-jwt');

        return http.Response(json.encode({
          'transactions': [
            {
              'id': 'tx-001',
              'kind': 'deposit',
              'status': 'completed',
              'status_eta': 0,
              'more_info_url': 'https://anchor.example.com/tx/tx-001',
              'amount_in': '100.00',
              'amount_in_asset': 'iso4217:USD',
              'amount_out': '98.50',
              'amount_out_asset': 'stellar:USD:GXXXXXXX',
              'amount_fee': '1.50',
              'amount_fee_asset': 'iso4217:USD',
              'started_at': '2025-10-01T12:00:00Z',
              'completed_at': '2025-10-01T13:00:00Z'
            },
            {
              'id': 'tx-002',
              'kind': 'deposit',
              'status': 'pending_user_transfer_start',
              'status_eta': 3600,
              'more_info_url': 'https://anchor.example.com/tx/tx-002',
              'started_at': '2025-10-02T10:00:00Z'
            },
            {
              'id': 'tx-003',
              'kind': 'withdrawal',
              'status': 'pending_anchor',
              'status_eta': 1800,
              'more_info_url': 'https://anchor.example.com/tx/tx-003',
              'started_at': '2025-10-02T11:00:00Z'
            }
          ]
        }), 200);
      });

      final service = TransferServerSEP24Service(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = SEP24TransactionsRequest()
        ..assetCode = 'USD'
        ..jwt = 'test-jwt';

      final response = await service.transactions(request);

      expect(response.transactions, isNotNull);
      expect(response.transactions.length, 3);

      final tx1 = response.transactions[0];
      expect(tx1.id, 'tx-001');
      expect(tx1.kind, 'deposit');
      expect(tx1.status, 'completed');
      expect(tx1.statusEta, 0);
      expect(tx1.amountIn, '100.00');
      expect(tx1.amountOut, '98.50');
      expect(tx1.amountFee, '1.50');

      final tx2 = response.transactions[1];
      expect(tx2.status, 'pending_user_transfer_start');
      expect(tx2.statusEta, 3600);

      final tx3 = response.transactions[2];
      expect(tx3.kind, 'withdrawal');
      expect(tx3.status, 'pending_anchor');
    });

    test('get transactions with pagination and filters', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/transactions'));
        expect(request.url.queryParameters['asset_code'], 'USD');
        expect(request.url.queryParameters['kind'], 'deposit');
        expect(request.url.queryParameters['limit'], '10');
        expect(request.url.queryParameters['paging_id'], 'page-token-123');
        expect(request.url.queryParameters['lang'], 'es');
        expect(request.url.queryParameters.containsKey('no_older_than'), true);

        return http.Response(json.encode({
          'transactions': []
        }), 200);
      });

      final service = TransferServerSEP24Service(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = SEP24TransactionsRequest()
        ..assetCode = 'USD'
        ..kind = 'deposit'
        ..limit = 10
        ..pagingId = 'page-token-123'
        ..noOlderThan = DateTime.utc(2025, 9, 1)
        ..lang = 'es'
        ..jwt = 'test-jwt';

      await service.transactions(request);
    });

    test('transactions with pending_stellar status', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'transactions': [
            {
              'id': 'tx-stellar-001',
              'kind': 'deposit',
              'status': 'pending_stellar',
              'status_eta': 300,
              'more_info_url': 'https://anchor.example.com/tx/tx-stellar-001',
              'stellar_transaction_id': 'stellar-hash-123',
              'started_at': '2025-10-03T10:00:00Z'
            }
          ]
        }), 200);
      });

      final service = TransferServerSEP24Service(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = SEP24TransactionsRequest()
        ..assetCode = 'USD'
        ..jwt = 'test-jwt';

      final response = await service.transactions(request);

      expect(response.transactions[0].status, 'pending_stellar');
      expect(response.transactions[0].stellarTransactionId, 'stellar-hash-123');
    });

    test('transactions with error status', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'transactions': [
            {
              'id': 'tx-error-001',
              'kind': 'deposit',
              'status': 'error',
              'status_eta': 0,
              'more_info_url': 'https://anchor.example.com/tx/tx-error-001',
              'message': 'Invalid bank account number',
              'started_at': '2025-10-03T11:00:00Z'
            }
          ]
        }), 200);
      });

      final service = TransferServerSEP24Service(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = SEP24TransactionsRequest()
        ..assetCode = 'USD'
        ..jwt = 'test-jwt';

      final response = await service.transactions(request);

      expect(response.transactions[0].status, 'error');
      expect(response.transactions[0].message, 'Invalid bank account number');
    });

    test('transactions throws authentication required exception', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'type': 'authentication_required'
        }), 403);
      });

      final service = TransferServerSEP24Service(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = SEP24TransactionsRequest()
        ..assetCode = 'USD'
        ..jwt = 'test-jwt';

      expect(
        () => service.transactions(request),
        throwsA(isA<SEP24AuthenticationRequiredException>()),
      );
    });
  });

  group('SEP-24 Transaction Endpoint', () {
    test('get transaction by id with all fields', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/transaction'));
        expect(request.url.queryParameters['id'], 'tx-123');
        expect(request.headers['Authorization'], 'Bearer test-jwt');

        return http.Response(json.encode({
          'transaction': {
            'id': 'tx-123',
            'kind': 'deposit',
            'status': 'completed',
            'status_eta': 0,
            'kyc_verified': true,
            'more_info_url': 'https://anchor.example.com/tx/tx-123',
            'amount_in': '1000.00',
            'amount_in_asset': 'iso4217:USD',
            'amount_out': '995.00',
            'amount_out_asset': 'stellar:USD:GXXXXXXX',
            'amount_fee': '5.00',
            'amount_fee_asset': 'iso4217:USD',
            'quote_id': 'quote-456',
            'started_at': '2025-10-05T09:00:00Z',
            'updated_at': '2025-10-05T10:00:00Z',
            'completed_at': '2025-10-05T10:30:00Z',
            'stellar_transaction_id': 'stellar-hash-abc',
            'external_transaction_id': 'external-ref-123',
            'message': 'Transaction completed successfully',
            'from': 'bank-account-789',
            'to': 'GXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
            'deposit_memo': 'deposit-memo-123',
            'deposit_memo_type': 'text'
          }
        }), 200);
      });

      final service = TransferServerSEP24Service(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = SEP24TransactionRequest()
        ..id = 'tx-123'
        ..jwt = 'test-jwt';

      final response = await service.transaction(request);

      expect(response.transaction, isNotNull);
      final tx = response.transaction;
      expect(tx.id, 'tx-123');
      expect(tx.kind, 'deposit');
      expect(tx.status, 'completed');
      expect(tx.statusEta, 0);
      expect(tx.kycVerified, true);
      expect(tx.amountIn, '1000.00');
      expect(tx.amountOut, '995.00');
      expect(tx.amountFee, '5.00');
      expect(tx.quoteId, 'quote-456');
      expect(tx.stellarTransactionId, 'stellar-hash-abc');
      expect(tx.externalTransactionId, 'external-ref-123');
      expect(tx.depositMemo, 'deposit-memo-123');
      expect(tx.depositMemoType, 'text');
    });

    test('get transaction by stellar_transaction_id', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/transaction'));
        expect(request.url.queryParameters['stellar_transaction_id'], 'stellar-hash-xyz');

        return http.Response(json.encode({
          'transaction': {
            'id': 'tx-456',
            'kind': 'deposit',
            'status': 'completed',
            'more_info_url': 'https://anchor.example.com/tx/tx-456',
            'stellar_transaction_id': 'stellar-hash-xyz',
            'started_at': '2025-10-05T09:00:00Z'
          }
        }), 200);
      });

      final service = TransferServerSEP24Service(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = SEP24TransactionRequest()
        ..stellarTransactionId = 'stellar-hash-xyz'
        ..jwt = 'test-jwt';

      final response = await service.transaction(request);
      expect(response.transaction.stellarTransactionId, 'stellar-hash-xyz');
    });

    test('get transaction by external_transaction_id', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/transaction'));
        expect(request.url.queryParameters['external_transaction_id'], 'external-ref-789');

        return http.Response(json.encode({
          'transaction': {
            'id': 'tx-789',
            'kind': 'withdrawal',
            'status': 'completed',
            'more_info_url': 'https://anchor.example.com/tx/tx-789',
            'external_transaction_id': 'external-ref-789',
            'started_at': '2025-10-05T09:00:00Z'
          }
        }), 200);
      });

      final service = TransferServerSEP24Service(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = SEP24TransactionRequest()
        ..externalTransactionId = 'external-ref-789'
        ..jwt = 'test-jwt';

      final response = await service.transaction(request);
      expect(response.transaction.externalTransactionId, 'external-ref-789');
    });

    test('get withdrawal transaction with withdraw fields', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'transaction': {
            'id': 'withdraw-001',
            'kind': 'withdrawal',
            'status': 'pending_anchor',
            'more_info_url': 'https://anchor.example.com/tx/withdraw-001',
            'withdraw_anchor_account': 'GANCHORXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
            'withdraw_memo': 'withdraw-memo-001',
            'withdraw_memo_type': 'hash',
            'from': 'GUSERXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
            'to': 'bank-account-456',
            'started_at': '2025-10-05T10:00:00Z'
          }
        }), 200);
      });

      final service = TransferServerSEP24Service(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = SEP24TransactionRequest()
        ..id = 'withdraw-001'
        ..jwt = 'test-jwt';

      final response = await service.transaction(request);

      expect(response.transaction.kind, 'withdrawal');
      expect(response.transaction.withdrawAnchorAccount, 'GANCHORXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX');
      expect(response.transaction.withdrawMemo, 'withdraw-memo-001');
      expect(response.transaction.withdrawMemoType, 'hash');
    });

    test('get transaction with refunds', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'transaction': {
            'id': 'tx-refund-001',
            'kind': 'deposit',
            'status': 'refunded',
            'more_info_url': 'https://anchor.example.com/tx/tx-refund-001',
            'refunds': {
              'amount_refunded': '95.00',
              'amount_fee': '5.00',
              'payments': [
                {
                  'id': 'refund-payment-001',
                  'id_type': 'stellar',
                  'amount': '95.00',
                  'fee': '5.00'
                }
              ]
            },
            'started_at': '2025-10-05T11:00:00Z'
          }
        }), 200);
      });

      final service = TransferServerSEP24Service(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = SEP24TransactionRequest()
        ..id = 'tx-refund-001'
        ..jwt = 'test-jwt';

      final response = await service.transaction(request);

      expect(response.transaction.status, 'refunded');
      expect(response.transaction.refunds, isNotNull);
      expect(response.transaction.refunds!.amountRefunded, '95.00');
      expect(response.transaction.refunds!.amountFee, '5.00');
      expect(response.transaction.refunds!.payments.length, 1);
      expect(response.transaction.refunds!.payments[0].id, 'refund-payment-001');
      expect(response.transaction.refunds!.payments[0].idType, 'stellar');
    });

    test('get transaction with claimable_balance_id', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'transaction': {
            'id': 'tx-cb-001',
            'kind': 'deposit',
            'status': 'completed',
            'more_info_url': 'https://anchor.example.com/tx/tx-cb-001',
            'claimable_balance_id': 'claimable-balance-id-123',
            'started_at': '2025-10-05T12:00:00Z'
          }
        }), 200);
      });

      final service = TransferServerSEP24Service(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = SEP24TransactionRequest()
        ..id = 'tx-cb-001'
        ..jwt = 'test-jwt';

      final response = await service.transaction(request);
      expect(response.transaction.claimableBalanceId, 'claimable-balance-id-123');
    });

    test('get transaction with language parameter', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.queryParameters['lang'], 'fr');

        return http.Response(json.encode({
          'transaction': {
            'id': 'tx-lang-001',
            'kind': 'deposit',
            'status': 'completed',
            'more_info_url': 'https://anchor.example.com/tx/tx-lang-001',
            'started_at': '2025-10-05T13:00:00Z'
          }
        }), 200);
      });

      final service = TransferServerSEP24Service(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = SEP24TransactionRequest()
        ..id = 'tx-lang-001'
        ..lang = 'fr'
        ..jwt = 'test-jwt';

      await service.transaction(request);
    });

    test('transaction throws not found exception', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'error': 'Transaction not found'
        }), 404);
      });

      final service = TransferServerSEP24Service(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = SEP24TransactionRequest()
        ..id = 'nonexistent-tx'
        ..jwt = 'test-jwt';

      expect(
        () => service.transaction(request),
        throwsA(isA<SEP24TransactionNotFoundException>()),
      );
    });

    test('transaction throws authentication required exception', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'type': 'authentication_required'
        }), 403);
      });

      final service = TransferServerSEP24Service(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = SEP24TransactionRequest()
        ..id = 'tx-123'
        ..jwt = 'test-jwt';

      expect(
        () => service.transaction(request),
        throwsA(isA<SEP24AuthenticationRequiredException>()),
      );
    });
  });

  group('SEP-24 Error Handling', () {
    test('handle 400 bad request with error message', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'error': 'Invalid asset_code parameter'
        }), 400);
      });

      final service = TransferServerSEP24Service(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = SEP24DepositRequest()
        ..assetCode = 'USD'
        ..jwt = 'test-jwt';

      expect(
        () => service.deposit(request),
        throwsA(isA<RequestErrorException>()),
      );
    });

    test('handle 403 with error message', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'error': 'Account not found'
        }), 400);
      });

      final service = TransferServerSEP24Service(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = SEP24WithdrawRequest()
        ..assetCode = 'USD'
        ..jwt = 'test-jwt';

      expect(
        () => service.withdraw(request),
        throwsA(isA<RequestErrorException>()),
      );
    });

    test('verify custom headers are passed correctly', () async {
      final mockClient = MockClient((request) async {
        expect(request.headers['X-Custom-Header'], 'custom-value');

        return http.Response(json.encode({
          'deposit': {},
          'withdraw': {}
        }), 200);
      });

      final service = TransferServerSEP24Service(
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
