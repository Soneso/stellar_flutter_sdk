import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:convert';

void main() {
  group('TransferServerService Info Endpoint', () {
    test('parse deposit info with all asset types and configurations', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/info'));
        expect(request.headers['Authorization'], 'Bearer test-jwt');

        return http.Response(json.encode({
          'deposit': {
            'USD': {
              'enabled': true,
              'authentication_required': true,
              'fee_fixed': 5.0,
              'fee_percent': 1.0,
              'min_amount': 10.0,
              'max_amount': 10000.0,
              'fields': {
                'email_address': {
                  'description': 'Email address for transaction notifications',
                  'optional': false
                },
                'type': {
                  'description': 'Type of deposit',
                  'choices': ['SEPA', 'SWIFT', 'cash'],
                  'optional': true
                }
              }
            },
            'BTC': {
              'enabled': true,
              'authentication_required': false,
              'fee_fixed': 0.0001,
              'fee_percent': 0.5,
              'min_amount': 0.001,
              'max_amount': 10.0
            }
          },
          'withdraw': {
            'USD': {
              'enabled': true,
              'authentication_required': true,
              'fee_fixed': 10.0,
              'fee_percent': 0.5,
              'min_amount': 50.0,
              'max_amount': 5000.0,
              'fields': {
                'dest': {
                  'description': 'Bank account number',
                  'optional': false
                },
                'dest_extra': {
                  'description': 'Bank routing number',
                  'optional': false
                }
              }
            }
          },
          'fee': {
            'enabled': true,
            'description': 'Fee endpoint is available for fee queries',
            'authentication_required': false
          },
          'transactions': {
            'enabled': true,
            'authentication_required': true
          },
          'transaction': {
            'enabled': true,
            'authentication_required': true
          },
          'features': {
            'account_creation': true,
            'claimable_balances': true
          }
        }), 200);
      });

      final service = TransferServerService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final response = await service.info(jwt: 'test-jwt');

      expect(response.depositAssets, isNotNull);
      expect(response.depositAssets!.length, 2);

      final usdDeposit = response.depositAssets!['USD']!;
      expect(usdDeposit.enabled, true);
      expect(usdDeposit.authenticationRequired, true);
      expect(usdDeposit.feeFixed, 5.0);
      expect(usdDeposit.feePercent, 1.0);
      expect(usdDeposit.minAmount, 10.0);
      expect(usdDeposit.maxAmount, 10000.0);
      expect(usdDeposit.fields, isNotNull);
      expect(usdDeposit.fields!['email_address']!.description,
        'Email address for transaction notifications');
      expect(usdDeposit.fields!['email_address']!.optional, false);
      expect(usdDeposit.fields!['type']!.choices, ['SEPA', 'SWIFT', 'cash']);

      final btcDeposit = response.depositAssets!['BTC']!;
      expect(btcDeposit.enabled, true);
      expect(btcDeposit.authenticationRequired, false);
      expect(btcDeposit.feeFixed, 0.0001);
      expect(btcDeposit.minAmount, 0.001);

      expect(response.withdrawAssets, isNotNull);
      expect(response.withdrawAssets!.length, 1);

      final usdWithdraw = response.withdrawAssets!['USD']!;
      expect(usdWithdraw.enabled, true);
      expect(usdWithdraw.authenticationRequired, true);
      expect(usdWithdraw.feeFixed, 10.0);
      expect(usdWithdraw.minAmount, 50.0);

      expect(response.feeInfo, isNotNull);
      expect(response.feeInfo!.enabled, true);
      expect(response.feeInfo!.authenticationRequired, false);

      expect(response.transactionsInfo, isNotNull);
      expect(response.transactionsInfo!.enabled, true);

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

      final service = TransferServerService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      await service.info(language: 'es');
    });

    test('parse info without authentication', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/info'));
        expect(request.headers.containsKey('Authorization'), false);

        return http.Response(json.encode({
          'deposit': {},
          'withdraw': {}
        }), 200);
      });

      final service = TransferServerService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      await service.info();
    });
  });

  group('TransferServerService Deposit Endpoint', () {
    test('successful deposit response with instructions', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/deposit'));
        expect(request.url.queryParameters['asset_code'], 'USD');
        expect(request.url.queryParameters['account'], 'GXXXXXXX');
        expect(request.headers['Authorization'], 'Bearer test-jwt');

        return http.Response(json.encode({
          'id': 'deposit-123',
          'how': 'Send USD to bank account',
          'eta': 3600,
          'min_amount': 10.0,
          'max_amount': 10000.0,
          'fee_fixed': 5.0,
          'fee_percent': 1.0,
          'extra_info': {
            'message': 'Please include reference number in transfer'
          },
          'instructions': {
            'bank_account': {
              'value': '1234567890',
              'description': 'Bank account number to send funds to'
            },
            'routing_number': {
              'value': '987654321',
              'description': 'Bank routing number'
            }
          }
        }), 200);
      });

      final service = TransferServerService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = DepositRequest(
        assetCode: 'USD',
        account: 'GXXXXXXX',
        jwt: 'test-jwt',
      );

      final response = await service.deposit(request);

      expect(response.id, 'deposit-123');
      expect(response.how, 'Send USD to bank account');
      expect(response.eta, 3600);
      expect(response.minAmount, 10.0);
      expect(response.maxAmount, 10000.0);
      expect(response.feeFixed, 5.0);
      expect(response.feePercent, 1.0);
      expect(response.extraInfo, isNotNull);
      expect(response.extraInfo!.message, 'Please include reference number in transfer');
      expect(response.instructions, isNotNull);
      expect(response.instructions!['bank_account']!.value, '1234567890');
      expect(response.instructions!['bank_account']!.description,
        'Bank account number to send funds to');
      expect(response.instructions!['routing_number']!.value, '987654321');
    });

    test('deposit with memo parameters', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/deposit'));
        expect(request.url.queryParameters['asset_code'], 'USD');
        expect(request.url.queryParameters['account'], 'GXXXXXXX');
        expect(request.url.queryParameters['memo_type'], 'text');
        expect(request.url.queryParameters['memo'], 'test-memo');
        expect(request.url.queryParameters['type'], 'SEPA');
        expect(request.url.queryParameters['amount'], '500.50');

        return http.Response(json.encode({
          'id': 'deposit-456',
          'how': 'Send via SEPA'
        }), 200);
      });

      final service = TransferServerService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = DepositRequest(
        assetCode: 'USD',
        account: 'GXXXXXXX',
        memoType: 'text',
        memo: 'test-memo',
        type: 'SEPA',
        amount: '500.50',
        jwt: 'test-jwt',
      );

      final response = await service.deposit(request);
      expect(response.id, 'deposit-456');
    });

    test('deposit with claimable balance support', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/deposit'));
        expect(request.url.queryParameters['claimable_balance_supported'], 'true');

        return http.Response(json.encode({
          'id': 'deposit-789'
        }), 200);
      });

      final service = TransferServerService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = DepositRequest(
        assetCode: 'USD',
        account: 'GXXXXXXX',
        claimableBalanceSupported: 'true',
        jwt: 'test-jwt',
      );

      await service.deposit(request);
    });
  });

  group('TransferServerService Withdraw Endpoint', () {
    test('successful withdrawal response', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/withdraw'));
        expect(request.url.queryParameters['asset_code'], 'USD');
        expect(request.url.queryParameters['type'], 'bank_account');
        expect(request.headers['Authorization'], 'Bearer test-jwt');

        return http.Response(json.encode({
          'id': 'withdraw-123',
          'account_id': 'GANCHORXXXXXXX',
          'memo_type': 'hash',
          'memo': 'test-memo-hash',
          'eta': 7200,
          'min_amount': 50.0,
          'max_amount': 5000.0,
          'fee_fixed': 10.0,
          'fee_percent': 0.5,
          'extra_info': {
            'message': 'Withdrawal will be processed within 2 hours'
          }
        }), 200);
      });

      final service = TransferServerService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = WithdrawRequest(
        assetCode: 'USD',
        type: 'bank_account',
        jwt: 'test-jwt',
      );

      final response = await service.withdraw(request);

      expect(response.id, 'withdraw-123');
      expect(response.accountId, 'GANCHORXXXXXXX');
      expect(response.memoType, 'hash');
      expect(response.memo, 'test-memo-hash');
      expect(response.eta, 7200);
      expect(response.minAmount, 50.0);
      expect(response.maxAmount, 5000.0);
      expect(response.feeFixed, 10.0);
      expect(response.feePercent, 0.5);
      expect(response.extraInfo, isNotNull);
      expect(response.extraInfo!.message, 'Withdrawal will be processed within 2 hours');
    });

    test('withdrawal with destination parameters', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/withdraw'));
        expect(request.url.queryParameters['dest'], '9876543210');
        expect(request.url.queryParameters['dest_extra'], '123456789');
        expect(request.url.queryParameters['amount'], '1000.00');

        return http.Response(json.encode({
          'id': 'withdraw-456',
          'account_id': 'GANCHORXXXXXXX'
        }), 200);
      });

      final service = TransferServerService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = WithdrawRequest(
        assetCode: 'USD',
        type: 'bank_account',
        dest: '9876543210',
        destExtra: '123456789',
        amount: '1000.00',
        jwt: 'test-jwt',
      );

      final response = await service.withdraw(request);
      expect(response.id, 'withdraw-456');
    });

    test('withdrawal with memo parameters', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/withdraw'));
        expect(request.url.queryParameters['memo'], 'user-memo');
        expect(request.url.queryParameters['memo_type'], 'text');

        return http.Response(json.encode({
          'id': 'withdraw-789',
          'account_id': 'GANCHORXXXXXXX'
        }), 200);
      });

      final service = TransferServerService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = WithdrawRequest(
        assetCode: 'USD',
        type: 'cash',
        memo: 'user-memo',
        memoType: 'text',
        jwt: 'test-jwt',
      );

      await service.withdraw(request);
    });
  });

  group('TransferServerService Fee Endpoint', () {
    test('get fee for deposit operation', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/fee'));
        expect(request.url.queryParameters['operation'], 'deposit');
        expect(request.url.queryParameters['asset_code'], 'USD');
        expect(request.url.queryParameters['amount'], anyOf(equals('500.0'), equals('500')));
        expect(request.url.queryParameters['type'], 'SEPA');
        expect(request.headers['Authorization'], 'Bearer test-jwt');

        return http.Response(json.encode({
          'fee': 7.50
        }), 200);
      });

      final service = TransferServerService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = FeeRequest(
        operation: 'deposit',
        assetCode: 'USD',
        amount: 500.0,
        type: 'SEPA',
        jwt: 'test-jwt',
      );

      final response = await service.fee(request);
      expect(response.fee, equals(7.50));
    });

    test('get fee for withdraw operation', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/fee'));
        expect(request.url.queryParameters['operation'], 'withdraw');
        expect(request.url.queryParameters['asset_code'], 'BTC');
        expect(request.url.queryParameters['amount'], '0.5');

        return http.Response(json.encode({
          'fee': 0.0005
        }), 200);
      });

      final service = TransferServerService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = FeeRequest(
        operation: 'withdraw',
        assetCode: 'BTC',
        amount: 0.5,
        jwt: 'test-jwt',
      );

      final response = await service.fee(request);
      expect(response.fee, 0.0005);
    });
  });

  group('TransferServerService Transactions Endpoint', () {
    test('get transactions with all filters and pagination', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/transactions'));
        expect(request.url.queryParameters['asset_code'], 'USD');
        expect(request.url.queryParameters['account'], 'GXXXXXXX');
        expect(request.url.queryParameters['kind'], 'deposit');
        expect(request.url.queryParameters['limit'], '10');
        expect(request.url.queryParameters['paging_id'], 'page-token-123');
        expect(request.headers['Authorization'], 'Bearer test-jwt');

        return http.Response(json.encode({
          'transactions': [
            {
              'id': 'tx-001',
              'kind': 'deposit',
              'status': 'completed',
              'status_eta': 0,
              'amount_in': '100.00',
              'amount_in_asset': 'iso4217:USD',
              'amount_out': '98.50',
              'amount_out_asset': 'stellar:USD:GXXXXXXX',
              'amount_fee': '1.50',
              'amount_fee_asset': 'iso4217:USD',
              'started_at': '2025-10-01T12:00:00Z',
              'completed_at': '2025-10-01T13:00:00Z',
              'from': 'bank-account-123',
              'to': 'GXXXXXXX',
              'deposit_memo': 'tx-001-memo',
              'deposit_memo_type': 'text'
            },
            {
              'id': 'tx-002',
              'kind': 'deposit',
              'status': 'pending_user_transfer_start',
              'status_eta': 3600,
              'amount_in': '250.00',
              'amount_in_asset': 'iso4217:USD',
              'amount_out': '247.50',
              'amount_out_asset': 'stellar:USD:GXXXXXXX',
              'started_at': '2025-10-02T10:00:00Z',
              'more_info_url': 'https://anchor.com/tx/tx-002'
            }
          ]
        }), 200);
      });

      final service = TransferServerService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = AnchorTransactionsRequest(
        assetCode: 'USD',
        account: 'GXXXXXXX',
        kind: 'deposit',
        limit: 10,
        pagingId: 'page-token-123',
        jwt: 'test-jwt',
      );

      final response = await service.transactions(request);

      expect(response.transactions, isNotNull);
      expect(response.transactions!.length, 2);

      final tx1 = response.transactions![0];
      expect(tx1.id, 'tx-001');
      expect(tx1.kind, 'deposit');
      expect(tx1.status, 'completed');
      expect(tx1.statusEta, 0);
      expect(tx1.amountIn, '100.00');
      expect(tx1.amountInAsset, 'iso4217:USD');
      expect(tx1.amountOut, '98.50');
      expect(tx1.amountOutAsset, 'stellar:USD:GXXXXXXX');
      expect(tx1.amountFee, '1.50');
      expect(tx1.startedAt, '2025-10-01T12:00:00Z');
      expect(tx1.completedAt, '2025-10-01T13:00:00Z');
      expect(tx1.from, 'bank-account-123');
      expect(tx1.to, 'GXXXXXXX');
      expect(tx1.depositMemo, 'tx-001-memo');
      expect(tx1.depositMemoType, 'text');

      final tx2 = response.transactions![1];
      expect(tx2.id, 'tx-002');
      expect(tx2.status, 'pending_user_transfer_start');
      expect(tx2.statusEta, 3600);
      expect(tx2.moreInfoUrl, 'https://anchor.com/tx/tx-002');
    });

    test('get withdrawal transactions', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/transactions'));
        expect(request.url.queryParameters['kind'], 'withdrawal');

        return http.Response(json.encode({
          'transactions': [
            {
              'id': 'withdraw-001',
              'kind': 'withdrawal',
              'status': 'pending_anchor',
              'amount_in': '500.00',
              'amount_out': '485.00',
              'withdraw_anchor_account': 'GANCHORXXXXXXX',
              'withdraw_memo': 'withdraw-memo-001',
              'withdraw_memo_type': 'hash',
              'from': 'GUSERXXXXXXX',
              'to': 'bank-account-456'
            }
          ]
        }), 200);
      });

      final service = TransferServerService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = AnchorTransactionsRequest(
        assetCode: 'USD',
        account: 'GUSERXXXXXXX',
        kind: 'withdrawal',
        jwt: 'test-jwt',
      );

      final response = await service.transactions(request);

      expect(response.transactions!.length, 1);
      final tx = response.transactions![0];
      expect(tx.id, 'withdraw-001');
      expect(tx.kind, 'withdrawal');
      expect(tx.status, 'pending_anchor');
      expect(tx.withdrawAnchorAccount, 'GANCHORXXXXXXX');
      expect(tx.withdrawMemo, 'withdraw-memo-001');
      expect(tx.withdrawMemoType, 'hash');
      expect(tx.to, 'bank-account-456');
    });

    test('get transactions with no_older_than filter', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/transactions'));
        expect(request.url.queryParameters['no_older_than'], isNotNull);

        return http.Response(json.encode({
          'transactions': []
        }), 200);
      });

      final service = TransferServerService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = AnchorTransactionsRequest(
        assetCode: 'USD',
        account: 'GXXXXXXX',
        noOlderThan: DateTime.utc(2025, 9, 1),
        jwt: 'test-jwt',
      );

      await service.transactions(request);
    });
  });

  group('TransferServerService Transaction Endpoint', () {
    test('get single transaction by id', () async {
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
            'amount_in': '1000.00',
            'amount_in_asset': 'iso4217:USD',
            'amount_out': '995.00',
            'amount_out_asset': 'stellar:USD:GXXXXXXX',
            'amount_fee': '5.00',
            'amount_fee_asset': 'iso4217:USD',
            'fee_details': {
              'total': '5.00',
              'asset': 'iso4217:USD',
              'details': [
                {
                  'name': 'Service fee',
                  'amount': '3.00',
                  'description': 'Processing fee'
                },
                {
                  'name': 'Network fee',
                  'amount': '2.00',
                  'description': 'Blockchain transaction fee'
                }
              ]
            },
            'quote_id': 'quote-456',
            'started_at': '2025-10-05T09:00:00Z',
            'updated_at': '2025-10-05T10:00:00Z',
            'completed_at': '2025-10-05T10:30:00Z',
            'from': 'bank-account-789',
            'to': 'GXXXXXXX',
            'deposit_memo': 'deposit-memo-123',
            'deposit_memo_type': 'text',
            'external_extra': 'routing-123',
            'external_extra_text': 'Chase Bank',
            'more_info_url': 'https://anchor.com/tx/tx-123'
          }
        }), 200);
      });

      final service = TransferServerService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = AnchorTransactionRequest(
        id: 'tx-123',
        jwt: 'test-jwt',
      );

      final response = await service.transaction(request);

      expect(response.transaction, isNotNull);
      final tx = response.transaction;
      expect(tx.id, 'tx-123');
      expect(tx.kind, 'deposit');
      expect(tx.status, 'completed');
      expect(tx.statusEta, 0);
      expect(tx.amountIn, '1000.00');
      expect(tx.amountOut, '995.00');
      expect(tx.amountFee, '5.00');
      expect(tx.feeDetails, isNotNull);
      expect(tx.feeDetails!.total, '5.00');
      expect(tx.feeDetails!.asset, 'iso4217:USD');
      expect(tx.feeDetails!.details!.length, 2);
      expect(tx.feeDetails!.details![0].name, 'Service fee');
      expect(tx.feeDetails!.details![0].amount, '3.00');
      expect(tx.quoteId, 'quote-456');
      expect(tx.startedAt, '2025-10-05T09:00:00Z');
      expect(tx.updatedAt, '2025-10-05T10:00:00Z');
      expect(tx.completedAt, '2025-10-05T10:30:00Z');
      expect(tx.externalExtra, 'routing-123');
      expect(tx.externalExtraText, 'Chase Bank');
      expect(tx.moreInfoUrl, 'https://anchor.com/tx/tx-123');
    });

    test('get transaction with pending_user_transfer_start status', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/transaction'));

        return http.Response(json.encode({
          'transaction': {
            'id': 'tx-pending-001',
            'kind': 'deposit',
            'status': 'pending_user_transfer_start',
            'status_eta': 7200,
            'amount_in': '500.00',
            'more_info_url': 'https://anchor.com/instructions/tx-pending-001'
          }
        }), 200);
      });

      final service = TransferServerService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = AnchorTransactionRequest(
        id: 'tx-pending-001',
        jwt: 'test-jwt',
      );

      final response = await service.transaction(request);
      expect(response.transaction.status, 'pending_user_transfer_start');
      expect(response.transaction.statusEta, 7200);
    });

    test('get transaction with pending_anchor status', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'transaction': {
            'id': 'tx-pending-002',
            'kind': 'withdrawal',
            'status': 'pending_anchor',
            'status_eta': 3600,
            'amount_in': '300.00'
          }
        }), 200);
      });

      final service = TransferServerService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = AnchorTransactionRequest(
        id: 'tx-pending-002',
        jwt: 'test-jwt',
      );

      final response = await service.transaction(request);
      expect(response.transaction.status, 'pending_anchor');
    });

    test('get transaction with pending_stellar status', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'transaction': {
            'id': 'tx-stellar-001',
            'kind': 'deposit',
            'status': 'pending_stellar',
            'status_eta': 300,
            'amount_in': '150.00'
          }
        }), 200);
      });

      final service = TransferServerService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = AnchorTransactionRequest(
        id: 'tx-stellar-001',
        jwt: 'test-jwt',
      );

      final response = await service.transaction(request);
      expect(response.transaction.status, 'pending_stellar');
    });

    test('get transaction with pending_external status', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'transaction': {
            'id': 'tx-external-001',
            'kind': 'withdrawal',
            'status': 'pending_external',
            'status_eta': 86400,
            'amount_in': '750.00'
          }
        }), 200);
      });

      final service = TransferServerService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = AnchorTransactionRequest(
        id: 'tx-external-001',
        jwt: 'test-jwt',
      );

      final response = await service.transaction(request);
      expect(response.transaction.status, 'pending_external');
      expect(response.transaction.statusEta, 86400);
    });

    test('get transaction with error status', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'transaction': {
            'id': 'tx-error-001',
            'kind': 'deposit',
            'status': 'error',
            'status_eta': 0,
            'amount_in': '200.00',
            'message': 'Invalid bank account number provided'
          }
        }), 200);
      });

      final service = TransferServerService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = AnchorTransactionRequest(
        id: 'tx-error-001',
        jwt: 'test-jwt',
      );

      final response = await service.transaction(request);
      expect(response.transaction.status, 'error');
      expect(response.transaction.message, 'Invalid bank account number provided');
    });

    test('get transaction by stellar_transaction_id', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.queryParameters['stellar_transaction_id'],
          'stellar-tx-hash-123');

        return http.Response(json.encode({
          'transaction': {
            'id': 'tx-456',
            'kind': 'deposit',
            'status': 'completed',
            'stellar_transaction_id': 'stellar-tx-hash-123'
          }
        }), 200);
      });

      final service = TransferServerService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = AnchorTransactionRequest(
        stellarTransactionId: 'stellar-tx-hash-123',
        jwt: 'test-jwt',
      );

      final response = await service.transaction(request);
      expect(response.transaction.stellarTransactionId, 'stellar-tx-hash-123');
    });

    test('get transaction by external_transaction_id', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.queryParameters['external_transaction_id'],
          'external-ref-789');

        return http.Response(json.encode({
          'transaction': {
            'id': 'tx-789',
            'kind': 'withdrawal',
            'status': 'completed',
            'external_transaction_id': 'external-ref-789'
          }
        }), 200);
      });

      final service = TransferServerService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = AnchorTransactionRequest(
        externalTransactionId: 'external-ref-789',
        jwt: 'test-jwt',
      );

      final response = await service.transaction(request);
      expect(response.transaction.externalTransactionId, 'external-ref-789');
    });

    test('get transaction with language parameter', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.queryParameters['lang'], 'es');

        return http.Response(json.encode({
          'transaction': {
            'id': 'tx-999',
            'kind': 'deposit',
            'status': 'completed'
          }
        }), 200);
      });

      final service = TransferServerService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = AnchorTransactionRequest(
        id: 'tx-999',
        lang: 'es',
        jwt: 'test-jwt',
      );

      await service.transaction(request);
    });
  });

  group('TransferServerService Error Handling', () {
    test('handle 400 bad request error', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'error': 'Invalid asset_code parameter'
        }), 400);
      });

      final service = TransferServerService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      expect(
        () => service.info(jwt: 'test-jwt'),
        throwsA(isA<ErrorResponse>()),
      );
    });

    test('handle 403 authentication_required error', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'type': 'authentication_required'
        }), 403);
      });

      final service = TransferServerService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = DepositRequest(
        assetCode: 'USD',
        account: 'GXXXXXXX',
      );

      expect(
        () => service.deposit(request),
        throwsA(isA<AuthenticationRequiredException>()),
      );
    });

    test('handle 403 non_interactive_customer_info_needed error', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'type': 'non_interactive_customer_info_needed',
          'fields': ['first_name', 'last_name', 'email_address']
        }), 403);
      });

      final service = TransferServerService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = DepositRequest(
        assetCode: 'USD',
        account: 'GXXXXXXX',
        jwt: 'test-jwt',
      );

      expect(
        () => service.deposit(request),
        throwsA(isA<CustomerInformationNeededException>()),
      );
    });

    test('handle 403 customer_info_status error', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'type': 'customer_info_status',
          'status': 'pending'
        }), 403);
      });

      final service = TransferServerService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = WithdrawRequest(
        assetCode: 'USD',
        type: 'bank_account',
        jwt: 'test-jwt',
      );

      expect(
        () => service.withdraw(request),
        throwsA(isA<CustomerInformationStatusException>()),
      );
    });

    test('handle 404 not found error', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'error': 'Transaction not found'
        }), 404);
      });

      final service = TransferServerService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = AnchorTransactionRequest(
        id: 'nonexistent-tx',
        jwt: 'test-jwt',
      );

      expect(
        () => service.transaction(request),
        throwsA(isA<ErrorResponse>()),
      );
    });

    test('handle 500 internal server error', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'error': 'Internal server error'
        }), 500);
      });

      final service = TransferServerService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      expect(
        () => service.info(jwt: 'test-jwt'),
        throwsA(isA<ErrorResponse>()),
      );
    });

    test('handle 503 service unavailable error', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'error': 'Service temporarily unavailable'
        }), 503);
      });

      final service = TransferServerService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = FeeRequest(
        operation: 'deposit',
        assetCode: 'USD',
        amount: 100.0,
        jwt: 'test-jwt',
      );

      expect(
        () => service.fee(request),
        throwsA(isA<ErrorResponse>()),
      );
    });

    test('verify correct URL construction for all endpoints', () async {
      final List<String> capturedPaths = [];

      final mockClient = MockClient((request) async {
        capturedPaths.add(request.url.path);

        if (request.url.path.endsWith('/info')) {
          return http.Response(json.encode({
            'deposit': {},
            'withdraw': {}
          }), 200);
        } else if (request.url.path.endsWith('/deposit')) {
          return http.Response(json.encode({
            'id': 'test-deposit'
          }), 200);
        } else if (request.url.path.endsWith('/withdraw')) {
          return http.Response(json.encode({
            'id': 'test-withdraw',
            'account_id': 'GXXXXXXX'
          }), 200);
        } else if (request.url.path.endsWith('/fee')) {
          return http.Response(json.encode({
            'fee': 5.0
          }), 200);
        } else if (request.url.path.endsWith('/transactions')) {
          return http.Response(json.encode({
            'transactions': []
          }), 200);
        } else if (request.url.path.endsWith('/transaction')) {
          return http.Response(json.encode({
            'transaction': {
              'id': 'test-tx',
              'kind': 'deposit',
              'status': 'completed'
            }
          }), 200);
        }

        return http.Response('Not found', 404);
      });

      final service = TransferServerService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      await service.info(jwt: 'test-jwt');
      await service.deposit(DepositRequest(
        assetCode: 'USD',
        account: 'GXXXXXXX',
        jwt: 'test-jwt',
      ));
      await service.withdraw(WithdrawRequest(
        assetCode: 'USD',
        type: 'bank_account',
        jwt: 'test-jwt',
      ));
      await service.fee(FeeRequest(
        operation: 'deposit',
        assetCode: 'USD',
        amount: 100.0,
        jwt: 'test-jwt',
      ));
      await service.transactions(AnchorTransactionsRequest(
        assetCode: 'USD',
        account: 'GXXXXXXX',
        jwt: 'test-jwt',
      ));
      await service.transaction(AnchorTransactionRequest(
        id: 'test-tx',
        jwt: 'test-jwt',
      ));

      expect(capturedPaths.any((path) => path.endsWith('/info')), true);
      expect(capturedPaths.any((path) => path.endsWith('/deposit')), true);
      expect(capturedPaths.any((path) => path.endsWith('/withdraw')), true);
      expect(capturedPaths.any((path) => path.endsWith('/fee')), true);
      expect(capturedPaths.any((path) => path.endsWith('/transactions')), true);
      expect(capturedPaths.any((path) => path.endsWith('/transaction')), true);
    });

    test('verify custom headers are passed correctly', () async {
      final mockClient = MockClient((request) async {
        expect(request.headers['X-Custom-Header'], 'custom-value');
        expect(request.headers['X-API-Version'], '2.0');

        return http.Response(json.encode({
          'deposit': {},
          'withdraw': {}
        }), 200);
      });

      final service = TransferServerService(
        'https://api.example.com',
        httpClient: mockClient,
        httpRequestHeaders: {
          'X-Custom-Header': 'custom-value',
          'X-API-Version': '2.0',
        },
      );

      await service.info(jwt: 'test-jwt');
    });
  });
}
