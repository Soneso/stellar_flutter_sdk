import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:convert';

void main() {
  group('TransferServerService - fromDomain', () {
    test('creates instance from stellar.toml', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('.well-known/stellar.toml')) {
          return http.Response('''
TRANSFER_SERVER="https://api.example.com/transfer"
          ''', 200);
        }
        return http.Response('Not found', 404);
      });

      final service = await TransferServerService.fromDomain(
        'example.com',
        httpClient: mockClient,
      );

      expect(service, isNotNull);
    });

    test('throws when TRANSFER_SERVER not found in stellar.toml', () async {
      final mockClient = MockClient((request) async {
        return http.Response('', 200);
      });

      expect(
        () => TransferServerService.fromDomain(
          'example.com',
          httpClient: mockClient,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('uses custom HTTP headers', () async {
      final mockClient = MockClient((request) async {
        expect(request.headers['X-Custom-Header'], 'test-value');
        return http.Response('''
TRANSFER_SERVER="https://api.example.com/transfer"
        ''', 200);
      });

      await TransferServerService.fromDomain(
        'example.com',
        httpClient: mockClient,
        httpRequestHeaders: {'X-Custom-Header': 'test-value'},
      );
    });
  });

  group('TransferServerService - Deposit Exchange', () {
    test('successful deposit exchange with quote', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/deposit-exchange'));
        expect(request.url.queryParameters['destination_asset'], 'stellar:USDC:GXXXXXXX');
        expect(request.url.queryParameters['source_asset'], 'iso4217:BRL');
        expect(request.url.queryParameters['amount'], '1000.00');
        expect(request.url.queryParameters['quote_id'], 'quote-123');

        return http.Response(json.encode({
          'id': 'deposit-exchange-001',
          'how': 'Send BRL to receive USDC',
          'instructions': {
            'bank_account': {
              'value': '1234567890',
              'description': 'Send BRL to this account'
            }
          }
        }), 200);
      });

      final service = TransferServerService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = DepositExchangeRequest(
        destinationAsset: 'stellar:USDC:GXXXXXXX',
        sourceAsset: 'iso4217:BRL',
        amount: '1000.00',
        account: 'GXXXXXXX',
        quoteId: 'quote-123',
        jwt: 'test-jwt',
      );

      final response = await service.depositExchange(request);
      expect(response.id, 'deposit-exchange-001');
    });

    test('deposit exchange with all optional parameters', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/deposit-exchange'));
        expect(request.url.queryParameters['memo_type'], 'hash');
        expect(request.url.queryParameters['memo'], 'test-memo-hash');
        expect(request.url.queryParameters['email_address'], 'user@example.com');
        expect(request.url.queryParameters['type'], 'bank_transfer');
        expect(request.url.queryParameters['wallet_name'], 'TestWallet');
        expect(request.url.queryParameters['wallet_url'], 'https://wallet.example.com');
        expect(request.url.queryParameters['lang'], 'pt');
        expect(request.url.queryParameters['on_change_callback'], 'https://callback.example.com');
        expect(request.url.queryParameters['country_code'], 'BRA');
        expect(request.url.queryParameters['claimable_balance_supported'], 'true');
        expect(request.url.queryParameters['customer_id'], 'customer-456');
        expect(request.url.queryParameters['location_id'], 'location-789');

        return http.Response(json.encode({
          'id': 'deposit-exchange-002',
        }), 200);
      });

      final service = TransferServerService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = DepositExchangeRequest(
        destinationAsset: 'stellar:USDC:GXXXXXXX',
        sourceAsset: 'iso4217:BRL',
        amount: '1000.00',
        account: 'GXXXXXXX',
        memoType: 'hash',
        memo: 'test-memo-hash',
        emailAddress: 'user@example.com',
        type: 'bank_transfer',
        walletName: 'TestWallet',
        walletUrl: 'https://wallet.example.com',
        lang: 'pt',
        onChangeCallback: 'https://callback.example.com',
        countryCode: 'BRA',
        claimableBalanceSupported: 'true',
        customerId: 'customer-456',
        locationId: 'location-789',
        jwt: 'test-jwt',
      );

      await service.depositExchange(request);
    });

    test('deposit exchange with extra fields', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.queryParameters['custom_field_1'], 'value1');
        expect(request.url.queryParameters['custom_field_2'], 'value2');

        return http.Response(json.encode({
          'id': 'deposit-exchange-003',
        }), 200);
      });

      final service = TransferServerService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = DepositExchangeRequest(
        destinationAsset: 'stellar:USDC:GXXXXXXX',
        sourceAsset: 'iso4217:BRL',
        amount: '1000.00',
        account: 'GXXXXXXX',
        extraFields: {
          'custom_field_1': 'value1',
          'custom_field_2': 'value2',
        },
        jwt: 'test-jwt',
      );

      await service.depositExchange(request);
    });
  });

  group('TransferServerService - Withdraw Exchange', () {
    test('successful withdraw exchange with quote', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/withdraw-exchange'));
        expect(request.url.queryParameters['source_asset'], 'stellar:USDC:GXXXXXXX');
        expect(request.url.queryParameters['destination_asset'], 'iso4217:BRL');
        expect(request.url.queryParameters['amount'], '500.00');
        expect(request.url.queryParameters['type'], 'bank_account');
        expect(request.url.queryParameters['quote_id'], 'quote-456');

        return http.Response(json.encode({
          'id': 'withdraw-exchange-001',
          'account_id': 'GANCHORXXXXXXX',
          'memo_type': 'hash',
          'memo': 'withdraw-memo-hash',
        }), 200);
      });

      final service = TransferServerService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = WithdrawExchangeRequest(
        sourceAsset: 'stellar:USDC:GXXXXXXX',
        destinationAsset: 'iso4217:BRL',
        amount: '500.00',
        type: 'bank_account',
        quoteId: 'quote-456',
        jwt: 'test-jwt',
      );

      final response = await service.withdrawExchange(request);
      expect(response.id, 'withdraw-exchange-001');
      expect(response.accountId, 'GANCHORXXXXXXX');
    });

    test('withdraw exchange with all optional parameters', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/withdraw-exchange'));
        expect(request.url.queryParameters['dest'], 'bank-account-123');
        expect(request.url.queryParameters['dest_extra'], 'routing-456');
        expect(request.url.queryParameters['account'], 'GXXXXXXX');
        expect(request.url.queryParameters['memo'], 'user-memo');
        expect(request.url.queryParameters['memo_type'], 'text');
        expect(request.url.queryParameters['wallet_name'], 'MyWallet');
        expect(request.url.queryParameters['wallet_url'], 'https://mywallet.com');
        expect(request.url.queryParameters['lang'], 'es');
        expect(request.url.queryParameters['on_change_callback'], 'https://callback.com');
        expect(request.url.queryParameters['country_code'], 'ESP');
        expect(request.url.queryParameters['refund_memo'], 'refund-memo');
        expect(request.url.queryParameters['refund_memo_type'], 'hash');
        expect(request.url.queryParameters['customer_id'], 'customer-789');
        expect(request.url.queryParameters['location_id'], 'location-012');

        return http.Response(json.encode({
          'id': 'withdraw-exchange-002',
          'account_id': 'GANCHORXXXXXXX',
        }), 200);
      });

      final service = TransferServerService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = WithdrawExchangeRequest(
        sourceAsset: 'stellar:USDC:GXXXXXXX',
        destinationAsset: 'iso4217:EUR',
        amount: '500.00',
        type: 'bank_account',
        dest: 'bank-account-123',
        destExtra: 'routing-456',
        account: 'GXXXXXXX',
        memo: 'user-memo',
        memoType: 'text',
        walletName: 'MyWallet',
        walletUrl: 'https://mywallet.com',
        lang: 'es',
        onChangeCallback: 'https://callback.com',
        countryCode: 'ESP',
        refundMemo: 'refund-memo',
        refundMemoType: 'hash',
        customerId: 'customer-789',
        locationId: 'location-012',
        jwt: 'test-jwt',
      );

      await service.withdrawExchange(request);
    });

    test('withdraw exchange with extra fields', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.queryParameters['custom_withdraw_field'], 'custom-value');

        return http.Response(json.encode({
          'id': 'withdraw-exchange-003',
          'account_id': 'GANCHORXXXXXXX',
        }), 200);
      });

      final service = TransferServerService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = WithdrawExchangeRequest(
        sourceAsset: 'stellar:USDC:GXXXXXXX',
        destinationAsset: 'iso4217:EUR',
        amount: '500.00',
        type: 'bank_account',
        extraFields: {
          'custom_withdraw_field': 'custom-value',
        },
        jwt: 'test-jwt',
      );

      await service.withdrawExchange(request);
    });
  });

  group('TransferServerService - Deposit with All Parameters', () {
    test('deposit with email, wallet info, and callbacks', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.queryParameters['email_address'], 'user@test.com');
        expect(request.url.queryParameters['wallet_name'], 'TestWallet');
        expect(request.url.queryParameters['wallet_url'], 'https://testwallet.com');
        expect(request.url.queryParameters['lang'], 'fr');
        expect(request.url.queryParameters['on_change_callback'], 'https://callback.test.com');
        expect(request.url.queryParameters['country_code'], 'FRA');
        expect(request.url.queryParameters['customer_id'], 'customer-999');
        expect(request.url.queryParameters['location_id'], 'location-888');

        return http.Response(json.encode({
          'id': 'deposit-with-params',
        }), 200);
      });

      final service = TransferServerService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = DepositRequest(
        assetCode: 'EUR',
        account: 'GXXXXXXX',
        emailAddress: 'user@test.com',
        walletName: 'TestWallet',
        walletUrl: 'https://testwallet.com',
        lang: 'fr',
        onChangeCallback: 'https://callback.test.com',
        countryCode: 'FRA',
        customerId: 'customer-999',
        locationId: 'location-888',
        jwt: 'test-jwt',
      );

      await service.deposit(request);
    });

    test('deposit with extra fields', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.queryParameters['custom_deposit_field'], 'custom-deposit-value');
        expect(request.url.queryParameters['another_field'], 'another-value');

        return http.Response(json.encode({
          'id': 'deposit-extra',
        }), 200);
      });

      final service = TransferServerService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = DepositRequest(
        assetCode: 'USD',
        account: 'GXXXXXXX',
        extraFields: {
          'custom_deposit_field': 'custom-deposit-value',
          'another_field': 'another-value',
        },
        jwt: 'test-jwt',
      );

      await service.deposit(request);
    });
  });

  group('TransferServerService - Withdraw with All Parameters', () {
    test('withdraw with account, wallet info, and callbacks', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.queryParameters['account'], 'GXXXXXXX');
        expect(request.url.queryParameters['wallet_name'], 'UserWallet');
        expect(request.url.queryParameters['wallet_url'], 'https://userwallet.com');
        expect(request.url.queryParameters['lang'], 'de');
        expect(request.url.queryParameters['on_change_callback'], 'https://withdraw-callback.com');
        expect(request.url.queryParameters['country_code'], 'DEU');
        expect(request.url.queryParameters['refund_memo'], 'refund-memo-123');
        expect(request.url.queryParameters['refund_memo_type'], 'id');
        expect(request.url.queryParameters['customer_id'], 'customer-111');
        expect(request.url.queryParameters['location_id'], 'location-222');

        return http.Response(json.encode({
          'id': 'withdraw-with-params',
          'account_id': 'GANCHORXXXXXXX',
        }), 200);
      });

      final service = TransferServerService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = WithdrawRequest(
        assetCode: 'EUR',
        type: 'bank_account',
        account: 'GXXXXXXX',
        walletName: 'UserWallet',
        walletUrl: 'https://userwallet.com',
        lang: 'de',
        onChangeCallback: 'https://withdraw-callback.com',
        countryCode: 'DEU',
        refundMemo: 'refund-memo-123',
        refundMemoType: 'id',
        customerId: 'customer-111',
        locationId: 'location-222',
        jwt: 'test-jwt',
      );

      await service.withdraw(request);
    });

    test('withdraw with extra fields', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.queryParameters['custom_withdraw_param'], 'custom-withdraw-val');

        return http.Response(json.encode({
          'id': 'withdraw-extra',
          'account_id': 'GANCHORXXXXXXX',
        }), 200);
      });

      final service = TransferServerService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = WithdrawRequest(
        assetCode: 'USD',
        type: 'cash',
        extraFields: {
          'custom_withdraw_param': 'custom-withdraw-val',
        },
        jwt: 'test-jwt',
      );

      await service.withdraw(request);
    });
  });

  group('TransferServerService - PatchTransaction', () {
    test('successfully patches transaction with fields', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(request.url.path, endsWith('/transactions/tx-123'));
        expect(request.headers['Authorization'], 'Bearer test-jwt');

        return http.Response('', 200);
      });

      final service = TransferServerService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = PatchTransactionRequest(
        'tx-123',
        fields: {
          'dest': 'GB123...',
          'dest_extra': 'memo-value',
        },
        jwt: 'test-jwt',
      );

      final response = await service.patchTransaction(request);
      expect(response.statusCode, 200);
    });

    test('throws exception when fields is null', () async {
      final service = TransferServerService('https://api.example.com');

      final request = PatchTransactionRequest(
        'tx-123',
        fields: null,
        jwt: 'test-jwt',
      );

      expect(
        () => service.patchTransaction(request),
        throwsA(isA<Exception>()),
      );
    });

    test('patches transaction with custom HTTP headers', () async {
      final mockClient = MockClient((request) async {
        expect(request.headers['X-Custom-Header'], 'custom-value');
        return http.Response('', 200);
      });

      final service = TransferServerService(
        'https://api.example.com',
        httpClient: mockClient,
        httpRequestHeaders: {'X-Custom-Header': 'custom-value'},
      );

      final request = PatchTransactionRequest(
        'tx-456',
        fields: {'dest': 'GB456...'},
        jwt: 'test-jwt',
      );

      await service.patchTransaction(request);
    });
  });

  group('TransferServerService - Response Parsing', () {
    test('DepositResponse parses all fields correctly', () {
      final json = {
        'how': 'Send to bank account',
        'id': 'deposit-001',
        'eta': 3600,
        'min_amount': 10.0,
        'max_amount': 10000.0,
        'fee_fixed': 5.0,
        'fee_percent': 1.0,
        'extra_info': {
          'message': 'Include reference number'
        },
        'instructions': {
          'bank_account': {
            'value': '1234567890',
            'description': 'Account number'
          }
        }
      };

      final response = DepositResponse.fromJson(json);

      expect(response.how, 'Send to bank account');
      expect(response.id, 'deposit-001');
      expect(response.eta, 3600);
      expect(response.minAmount, 10.0);
      expect(response.maxAmount, 10000.0);
      expect(response.feeFixed, 5.0);
      expect(response.feePercent, 1.0);
      expect(response.extraInfo, isNotNull);
      expect(response.instructions, isNotNull);
    });

    test('DepositInstruction parses correctly', () {
      final json = {
        'value': '9876543210',
        'description': 'Routing number'
      };

      final instruction = DepositInstruction.fromJson(json);

      expect(instruction.value, '9876543210');
      expect(instruction.description, 'Routing number');
    });

    test('ExtraInfo parses message correctly', () {
      final json = {
        'message': 'Please include reference'
      };

      final extraInfo = ExtraInfo.fromJson(json);
      expect(extraInfo.message, 'Please include reference');
    });
  });

  group('TransferServerService - Constructor and Configuration', () {
    test('creates instance with custom HTTP client', () {
      final mockClient = MockClient((request) async {
        return http.Response('{}', 200);
      });

      final service = TransferServerService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      expect(service, isNotNull);
    });

    test('creates instance with custom headers', () {
      final service = TransferServerService(
        'https://api.example.com',
        httpRequestHeaders: {
          'X-API-Key': 'test-key',
          'X-Version': '2.0',
        },
      );

      expect(service, isNotNull);
    });

    test('creates instance with default HTTP client', () {
      final service = TransferServerService('https://api.example.com');
      expect(service, isNotNull);
    });
  });

  group('TransferServerService - Error Handling Edge Cases', () {
    test('handles HTTP 400 without error field', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'message': 'Bad request without error field'
        }), 400);
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
        throwsA(isA<Exception>()),
      );
    });

    test('handles deposit 403 non_interactive_customer_info_needed', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'type': 'non_interactive_customer_info_needed',
          'fields': ['email_address', 'mobile_number']
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

    test('handles deposit 403 customer_info_status', () async {
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

      final request = DepositRequest(
        assetCode: 'USD',
        account: 'GXXXXXXX',
        jwt: 'test-jwt',
      );

      expect(
        () => service.deposit(request),
        throwsA(isA<CustomerInformationStatusException>()),
      );
    });

    test('handles depositExchange 403 authentication_required', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'type': 'authentication_required'
        }), 403);
      });

      final service = TransferServerService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = DepositExchangeRequest(
        destinationAsset: 'stellar:USDC:GXXXXXXX',
        sourceAsset: 'iso4217:BRL',
        amount: '1000.00',
        account: 'GXXXXXXX',
      );

      expect(
        () => service.depositExchange(request),
        throwsA(isA<AuthenticationRequiredException>()),
      );
    });

    test('handles withdrawExchange 403 customer_info_status', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'type': 'customer_info_status',
          'status': 'denied'
        }), 403);
      });

      final service = TransferServerService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = WithdrawExchangeRequest(
        sourceAsset: 'stellar:USDC:GXXXXXXX',
        destinationAsset: 'iso4217:EUR',
        amount: '500.00',
        type: 'bank_account',
        jwt: 'test-jwt',
      );

      expect(
        () => service.withdrawExchange(request),
        throwsA(isA<CustomerInformationStatusException>()),
      );
    });
  });
}
