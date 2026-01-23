// SEP-24 Interactive Deposits/Withdrawals - Mocked HTTP Tests
//
// Tests the TransferServerSEP24Service implementation using MockClient
// to verify correct HTTP request/response handling for all endpoints.
//
// Test coverage (32 tests):
// - Info endpoint: 3 tests (basic parsing, language param, auth required)
// - Fee endpoint: 4 tests (deposit/withdraw operations, error handling)
// - Deposit endpoint: 4 tests (interactive flow, parameters, errors)
// - Withdraw endpoint: 4 tests (interactive flow, parameters, errors)
// - Transactions endpoint: 5 tests (statuses, pagination, errors)
// - Transaction endpoint: 9 tests (by id/stellar_id/external_id, fields, errors)
// - Error handling: 3 tests (400/403 errors, custom headers)

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:convert';

void main() {
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
        expect(request.url.queryParameters['amount'], '100.0');
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
      expect(response.fee, 5.0);
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
