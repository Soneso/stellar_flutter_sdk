@Timeout(const Duration(seconds: 300))

import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

void main() {
  final serviceAddress = 'http://api.stellar.org/transfer-sep24/';
  final jwtToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJHQTZVSVhYUEVXWUZJTE5VSVdBQzM3WTRRUEVaTVFWREpIREtWV0ZaSjJLQ1dVQklVNUlYWk5EQSIsImp0aSI6IjE0NGQzNjdiY2IwZTcyY2FiZmRiZGU2MGVhZTBhZDczM2NjNjVkMmE2NTg3MDgzZGFiM2Q2MTZmODg1MTkwMjQiLCJpc3MiOiJodHRwczovL2ZsYXBweS1iaXJkLWRhcHAuZmlyZWJhc2VhcHAuY29tLyIsImlhdCI6MTUzNDI1Nzk5NCwiZXhwIjoxNTM0MzQ0Mzk0fQ.8nbB83Z6vGBgC1X9r3N6oQCFTBzDiITAfCJasRft0z0';

  String infoJson() {
    return '{"deposit":{"USD":{"enabled":true,"fee_fixed":5,"fee_percent":1,"min_amount":0.1,"max_amount":1000},"ETH":{"enabled":true,"fee_fixed":0.002,"fee_percent":0},"native":{"enabled":true,"fee_fixed":0.00001,"fee_percent":0}},"withdraw":{"USD":{"enabled":true,"fee_minimum":5,"fee_percent":0.5,"min_amount":0.1,"max_amount":1000},"ETH":{"enabled":false},"native":{"enabled":true}},"fee":{"enabled":false},"features":{"account_creation":true,"claimable_balances":true}}';
  }

  String feeJson() {
    return '{"fee": 0.013}';
  }

  String interactiveJson() {
    return '{"type":"interactive_customer_info_needed","url":"https://api.example.com/kycflow?account=GACW7NONV43MZIFHCOKCQJAKSJSISSICFVUJ2C6EZIW5773OU3HD64VI","id":"82fhs729f63dh0v4"}';
  }

  String transactionJson() {
    return '{"transaction":{"id":"82fhs729f63dh0v4","kind":"withdrawal","status":"completed","amount_in":"510","amount_out":"490","amount_fee":"5","started_at":"2017-03-20T17:00:02Z","completed_at":"2017-03-20T17:09:58Z","updated_at":"2017-03-20T17:09:58Z","more_info_url":"https://youranchor.com/tx/242523523","stellar_transaction_id":"17a670bc424ff5ce3b386dbfaae9990b66a2a37b4fbe51547e8794962a3f9e6a","external_transaction_id":"1941491","withdraw_anchor_account":"GBANAGOAXH5ONSBI2I6I5LHP2TCRHWMZIAMGUQH2TNKQNCOGJ7GC3ZOL","withdraw_memo":"186384","withdraw_memo_type":"id","refunds":{"amount_refunded":"10","amount_fee":"5","payments":[{"id":"b9d0b2292c4e09e8eb22d036171491e87b8d2086bf8b265874c8d182cb9c9020","id_type":"stellar","amount":"10","fee":"5"}]}}}';
  }

  String transactionsJson() {
    return '{"transactions":[{"id":"82fhs729f63dh0v4","kind":"deposit","status":"pending_external","status_eta":3600,"external_transaction_id":"2dd16cb409513026fbe7defc0c6f826c2d2c65c3da993f747d09bf7dafd31093","more_info_url":"https://youranchor.com/tx/242523523","amount_in":"18.34","amount_out":"18.24","amount_fee":"0.1","started_at":"2017-03-20T17:05:32Z","claimable_balance_id":null},{"id":"82fhs729f63dh0v4","kind":"withdrawal","status":"completed","amount_in":"510","amount_out":"490","amount_fee":"5","started_at":"2017-03-20T17:00:02Z","completed_at":"2017-03-20T17:09:58Z","updated_at":"2017-03-20T17:09:58Z","more_info_url":"https://youranchor.com/tx/242523523","stellar_transaction_id":"17a670bc424ff5ce3b386dbfaae9990b66a2a37b4fbe51547e8794962a3f9e6a","external_transaction_id":"1941491","withdraw_anchor_account":"GBANAGOAXH5ONSBI2I6I5LHP2TCRHWMZIAMGUQH2TNKQNCOGJ7GC3ZOL","withdraw_memo":"186384","withdraw_memo_type":"id","refunds":{"amount_refunded":"10","amount_fee":"5","payments":[{"id":"b9d0b2292c4e09e8eb22d036171491e87b8d2086bf8b265874c8d182cb9c9020","id_type":"stellar","amount":"10","fee":"5"}]}}]}';
  }

  // Helper to create a mock service for most tests
  TransferServerSEP24Service createMockService({
    String? infoOverride,
    String? feeOverride,
    String? depositOverride,
    String? withdrawOverride,
    String? transactionOverride,
    String? transactionsOverride,
    int depositStatus = 200,
    int withdrawStatus = 200,
    int transactionStatus = 200,
    int transactionsStatus = 200,
    int feeStatus = 200,
  }) {
    final service = TransferServerSEP24Service(serviceAddress);
    service.httpClient = MockClient((request) async {
      final url = request.url.toString();

      if (request.method == 'GET' && url.contains('info')) {
        return http.Response(infoOverride ?? infoJson(), 200);
      }

      if (request.method == 'GET' && url.contains('fee')) {
        return http.Response(feeOverride ?? feeJson(), feeStatus);
      }

      if (request.method == 'POST' &&
          url.contains('transactions/deposit/interactive')) {
        return http.Response(
            depositOverride ?? interactiveJson(), depositStatus);
      }

      if (request.method == 'POST' &&
          url.contains('transactions/withdraw/interactive')) {
        return http.Response(
            withdrawOverride ?? interactiveJson(), withdrawStatus);
      }

      // Important: 'transaction' singular match must come after 'transactions' plural
      if (request.method == 'GET' &&
          url.contains('transactions') &&
          !url.endsWith('transaction')) {
        // Check if it's the plural endpoint (has asset_code param typically)
        if (url.contains('asset_code') || !url.contains('id=')) {
          return http.Response(
              transactionsOverride ?? transactionsJson(), transactionsStatus);
        }
      }

      if (request.method == 'GET' && url.contains('transaction')) {
        return http.Response(
            transactionOverride ?? transactionJson(), transactionStatus);
      }

      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });
    return service;
  }

  // --- Quick example ---
  test('sep-24: Quick example - basic deposit', () async {
    // Corresponds to "Quick example" section
    final service = createMockService();

    SEP24DepositRequest request = SEP24DepositRequest()
      ..jwt = jwtToken
      ..assetCode = 'USD';

    SEP24InteractiveResponse response = await service.deposit(request);

    // Open this URL in a browser or webview for the user
    String interactiveUrl = response.url;
    String transactionId = response.id;

    expect(interactiveUrl, isNotEmpty);
    expect(transactionId, equals('82fhs729f63dh0v4'));
  });

  // --- Creating the interactive service ---
  test('sep-24: Creating service from direct URL', () {
    // Corresponds to "From a direct URL" section
    TransferServerSEP24Service service =
        TransferServerSEP24Service('https://api.anchor.com/sep24');

    expect(service, isNotNull);
  });

  // --- Getting anchor information ---
  test('sep-24: Getting anchor information', () async {
    // Corresponds to "Getting anchor information" section
    final service = createMockService();

    SEP24InfoResponse info = await service.info();

    // Check supported deposit assets
    expect(info.depositAssets, isNotNull);
    expect(info.depositAssets!.length, 3);

    info.depositAssets!.forEach((code, asset) {
      expect(code, isNotEmpty);
    });

    // Check USD deposit specifically
    SEP24DepositAsset usdDeposit = info.depositAssets!['USD']!;
    expect(usdDeposit.enabled, true);
    expect(usdDeposit.minAmount, 0.1);
    expect(usdDeposit.maxAmount, 1000.0);
    expect(usdDeposit.feeFixed, 5.0);
    expect(usdDeposit.feePercent, 1.0);
    expect(usdDeposit.feeMinimum, isNull);

    // Check supported withdrawal assets
    Map<String, SEP24WithdrawAsset>? withdrawAssets = info.withdrawAssets;
    expect(withdrawAssets, isNotNull);

    SEP24WithdrawAsset usdWithdraw = withdrawAssets!['USD']!;
    expect(usdWithdraw.enabled, true);
    expect(usdWithdraw.feeMinimum, 5.0);

    // Check feature support
    expect(info.featureFlags, isNotNull);
    expect(info.featureFlags!.accountCreation, true);
    expect(info.featureFlags!.claimableBalances, true);

    // Check fee endpoint info
    expect(info.feeEndpointInfo, isNotNull);
    expect(info.feeEndpointInfo!.enabled, false);
  });

  // --- Deposit flow: Basic deposit ---
  test('sep-24: Basic deposit', () async {
    // Corresponds to "Basic deposit" section
    final service = createMockService();

    SEP24DepositRequest request = SEP24DepositRequest()
      ..jwt = jwtToken
      ..assetCode = 'USD';

    SEP24InteractiveResponse response = await service.deposit(request);

    String url = response.url;
    String transactionId = response.id;

    expect(url, isNotEmpty);
    expect(transactionId, isNotEmpty);
  });

  // --- Deposit with amount and account options ---
  test('sep-24: Deposit with amount and account options', () async {
    // Corresponds to "Deposit with amount and account options" section
    final service = createMockService();

    SEP24DepositRequest request = SEP24DepositRequest()
      ..jwt = jwtToken
      ..assetCode = 'USD'
      ..amount = '100.0'
      ..account = 'GXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
      ..memo = '12345'
      ..memoType = 'id'
      ..lang = 'en-US';

    SEP24InteractiveResponse response = await service.deposit(request);
    expect(response.id, isNotEmpty);
  });

  // --- Deposit with asset issuer ---
  test('sep-24: Deposit with asset issuer', () async {
    // Corresponds to "Deposit with asset issuer" section
    final service = createMockService();

    SEP24DepositRequest request = SEP24DepositRequest()
      ..jwt = jwtToken
      ..assetCode = 'USD'
      ..assetIssuer =
          'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';

    SEP24InteractiveResponse response = await service.deposit(request);
    expect(response.id, isNotEmpty);
  });

  // --- Deposit with SEP-38 quote ---
  test('sep-24: Deposit with SEP-38 quote', () async {
    // Corresponds to "Deposit with SEP-38 quote" section
    final service = createMockService();

    String quoteId = 'quote-abc-123';

    SEP24DepositRequest request = SEP24DepositRequest()
      ..jwt = jwtToken
      ..assetCode = 'USDC'
      ..quoteId = quoteId
      ..sourceAsset = 'iso4217:EUR'
      ..amount = '100.0';

    SEP24InteractiveResponse response = await service.deposit(request);
    expect(response.id, isNotEmpty);
  });

  // --- Pre-filling KYC data ---
  test('sep-24: Deposit with KYC pre-fill', () async {
    // Corresponds to "Pre-filling KYC data" section
    final service = TransferServerSEP24Service(serviceAddress);
    service.httpClient = MockClient((request) async {
      if (request.method == 'POST' &&
          request.url.toString().contains('deposit/interactive')) {
        // Verify KYC fields are included in the multipart request body
        expect(request.body, contains('first_name'));
        expect(request.body, contains('Jane'));
        expect(request.body, contains('last_name'));
        expect(request.body, contains('Doe'));
        expect(request.body, contains('email_address'));
        expect(request.body, contains('jane@example.com'));
        return http.Response(interactiveJson(), 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    NaturalPersonKYCFields personFields = NaturalPersonKYCFields()
      ..firstName = 'Jane'
      ..lastName = 'Doe'
      ..emailAddress = 'jane@example.com'
      ..mobileNumber = '+1234567890';

    StandardKYCFields kycFields = StandardKYCFields()
      ..naturalPersonKYCFields = personFields;

    SEP24DepositRequest request = SEP24DepositRequest()
      ..jwt = jwtToken
      ..assetCode = 'USD'
      ..kycFields = kycFields;

    SEP24InteractiveResponse response = await service.deposit(request);
    expect(response.id, equals('82fhs729f63dh0v4'));
  });

  // --- Pre-filling organization KYC data ---
  test('sep-24: Deposit with organization KYC', () async {
    // Corresponds to "Pre-filling organization KYC data" section
    final service = TransferServerSEP24Service(serviceAddress);
    service.httpClient = MockClient((request) async {
      if (request.method == 'POST' &&
          request.url.toString().contains('deposit/interactive')) {
        expect(request.body, contains('organization.name'));
        expect(request.body, contains('Acme Corporation'));
        return http.Response(interactiveJson(), 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    OrganizationKYCFields orgFields = OrganizationKYCFields()
      ..name = 'Acme Corporation'
      ..registeredAddress = '123 Business St, Suite 100'
      ..email = 'contact@acme.com';

    StandardKYCFields kycFields = StandardKYCFields()
      ..organizationKYCFields = orgFields;

    SEP24DepositRequest request = SEP24DepositRequest()
      ..jwt = jwtToken
      ..assetCode = 'USD'
      ..kycFields = kycFields;

    SEP24InteractiveResponse response = await service.deposit(request);
    expect(response.id, isNotEmpty);
  });

  // --- Custom fields and files ---
  test('sep-24: Deposit with custom fields', () async {
    // Corresponds to "Custom fields and files" section
    final service = TransferServerSEP24Service(serviceAddress);
    service.httpClient = MockClient((request) async {
      if (request.method == 'POST' &&
          request.url.toString().contains('deposit/interactive')) {
        expect(request.body, contains('employer_name'));
        expect(request.body, contains('Tech Corp'));
        return http.Response(interactiveJson(), 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    SEP24DepositRequest request = SEP24DepositRequest()
      ..jwt = jwtToken
      ..assetCode = 'USD'
      ..customFields = {
        'employer_name': 'Tech Corp',
        'occupation': 'Software Engineer',
      }
      ..customFiles = {
        'proof_of_income': Uint8List.fromList([0x50, 0x44, 0x46]),
      };

    SEP24InteractiveResponse response = await service.deposit(request);
    expect(response.id, isNotEmpty);
  });

  // --- Deposit with claimable balance support ---
  test('sep-24: Deposit with claimable balance support', () async {
    // Corresponds to "Deposit with claimable balance support" section
    final service = createMockService();

    SEP24DepositRequest request = SEP24DepositRequest()
      ..jwt = jwtToken
      ..assetCode = 'USD'
      ..claimableBalanceSupported = 'true';

    SEP24InteractiveResponse response = await service.deposit(request);
    expect(response.id, isNotEmpty);
  });

  // --- Deposit native XLM ---
  test('sep-24: Deposit native XLM', () async {
    // Corresponds to "Deposit native XLM" section
    final service = createMockService();

    SEP24DepositRequest request = SEP24DepositRequest()
      ..jwt = jwtToken
      ..assetCode = 'native';

    SEP24InteractiveResponse response = await service.deposit(request);
    expect(response.id, isNotEmpty);
  });

  // --- Basic withdrawal ---
  test('sep-24: Basic withdrawal', () async {
    // Corresponds to "Basic withdrawal" section
    final service = createMockService();

    SEP24WithdrawRequest request = SEP24WithdrawRequest()
      ..jwt = jwtToken
      ..assetCode = 'USD';

    SEP24InteractiveResponse response = await service.withdraw(request);

    String url = response.url;
    String transactionId = response.id;

    expect(url, isNotEmpty);
    expect(transactionId, isNotEmpty);
  });

  // --- Withdrawal with options ---
  test('sep-24: Withdrawal with options', () async {
    // Corresponds to "Withdrawal with options" section
    final service = createMockService();

    SEP24WithdrawRequest request = SEP24WithdrawRequest()
      ..jwt = jwtToken
      ..assetCode = 'USD'
      ..amount = '500.0'
      ..account = 'GXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
      ..lang = 'de';

    SEP24InteractiveResponse response = await service.withdraw(request);
    expect(response.id, isNotEmpty);
  });

  // --- Withdrawal with refund memo ---
  test('sep-24: Withdrawal with refund memo', () async {
    // Corresponds to "Withdrawal with refund memo" section
    final service = createMockService();

    SEP24WithdrawRequest request = SEP24WithdrawRequest()
      ..jwt = jwtToken
      ..assetCode = 'USD'
      ..amount = '500.0'
      ..refundMemo = 'refund-123'
      ..refundMemoType = 'text';

    SEP24InteractiveResponse response = await service.withdraw(request);
    expect(response.id, isNotEmpty);
  });

  // --- Withdrawal with SEP-38 quote ---
  test('sep-24: Withdrawal with SEP-38 quote', () async {
    // Corresponds to "Withdrawal with SEP-38 quote" section
    final service = createMockService();

    String quoteId = 'quote-xyz-789';

    SEP24WithdrawRequest request = SEP24WithdrawRequest()
      ..jwt = jwtToken
      ..assetCode = 'USDC'
      ..quoteId = quoteId
      ..destinationAsset = 'iso4217:EUR'
      ..amount = '500.0';

    SEP24InteractiveResponse response = await service.withdraw(request);
    expect(response.id, isNotEmpty);
  });

  // --- Withdrawal with KYC data ---
  test('sep-24: Withdrawal with KYC data', () async {
    // Corresponds to "Withdrawal with KYC data" section
    final service = TransferServerSEP24Service(serviceAddress);
    service.httpClient = MockClient((request) async {
      if (request.method == 'POST' &&
          request.url.toString().contains('withdraw/interactive')) {
        expect(request.body, contains('first_name'));
        expect(request.body, contains('John'));
        expect(request.body, contains('bank_account_number'));
        expect(request.body, contains('123456789'));
        return http.Response(interactiveJson(), 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    NaturalPersonKYCFields personFields = NaturalPersonKYCFields()
      ..firstName = 'John'
      ..lastName = 'Smith'
      ..emailAddress = 'john@example.com';

    FinancialAccountKYCFields bankFields = FinancialAccountKYCFields()
      ..bankAccountNumber = '123456789'
      ..bankNumber = '987654321';
    personFields.financialAccountKYCFields = bankFields;

    StandardKYCFields kycFields = StandardKYCFields()
      ..naturalPersonKYCFields = personFields;

    SEP24WithdrawRequest request = SEP24WithdrawRequest()
      ..jwt = jwtToken
      ..assetCode = 'USD'
      ..kycFields = kycFields;

    SEP24InteractiveResponse response = await service.withdraw(request);
    expect(response.id, isNotEmpty);
  });

  // --- Get a single transaction by ID ---
  test('sep-24: Get single transaction by ID', () async {
    // Corresponds to "Get a single transaction by ID" section
    final service = createMockService();

    SEP24TransactionRequest request = SEP24TransactionRequest()
      ..jwt = jwtToken
      ..id = '82fhs729f63dh0v4';

    SEP24TransactionResponse response = await service.transaction(request);
    SEP24Transaction tx = response.transaction;

    expect(tx.id, equals('82fhs729f63dh0v4'));
    expect(tx.kind, equals('withdrawal'));
    expect(tx.status, equals('completed'));
    expect(tx.startedAt, isNotEmpty);

    expect(tx.amountIn, equals('510'));
    expect(tx.amountOut, equals('490'));
    expect(tx.amountFee, equals('5'));
    expect(tx.moreInfoUrl, isNotNull);
  });

  // --- Get transaction by Stellar transaction ID ---
  test('sep-24: Get transaction by Stellar transaction ID', () async {
    // Corresponds to "Get transaction by Stellar transaction ID" section
    final service = createMockService();

    SEP24TransactionRequest request = SEP24TransactionRequest()
      ..jwt = jwtToken
      ..stellarTransactionId =
          '17a670bc424ff5ce3b386dbfaae9990b66a2a37b4fbe51547e8794962a3f9e6a';

    SEP24TransactionResponse response = await service.transaction(request);
    expect(response.transaction.id, isNotEmpty);
  });

  // --- Get transaction by external transaction ID ---
  test('sep-24: Get transaction by external transaction ID', () async {
    // Corresponds to "Get transaction by external transaction ID" section
    final service = createMockService();

    SEP24TransactionRequest request = SEP24TransactionRequest()
      ..jwt = jwtToken
      ..externalTransactionId = 'BANK-REF-123456';

    SEP24TransactionResponse response = await service.transaction(request);
    expect(response.transaction.id, isNotEmpty);
  });

  // --- Get transaction history ---
  test('sep-24: Get transaction history', () async {
    // Corresponds to "Get transaction history" section
    final service = createMockService();

    SEP24TransactionsRequest request = SEP24TransactionsRequest()
      ..jwt = jwtToken
      ..assetCode = 'USD'
      ..limit = 10
      ..kind = 'deposit'
      ..noOlderThan = DateTime.utc(2024, 1, 1)
      ..lang = 'en';

    SEP24TransactionsResponse response = await service.transactions(request);

    expect(response.transactions, isNotEmpty);
    for (SEP24Transaction tx in response.transactions) {
      expect(tx.id, isNotEmpty);
      expect(tx.kind, isNotEmpty);
      expect(tx.status, isNotEmpty);
    }
  });

  // --- Pagination with paging ID ---
  test('sep-24: Pagination with paging ID', () async {
    // Corresponds to "Pagination with paging ID" section
    final service = createMockService();

    SEP24TransactionsRequest request = SEP24TransactionsRequest()
      ..jwt = jwtToken
      ..assetCode = 'USD'
      ..limit = 10;

    SEP24TransactionsResponse response = await service.transactions(request);
    List<SEP24Transaction> transactions = response.transactions;

    expect(transactions, isNotEmpty);

    // Get next page using the last transaction's ID
    if (transactions.isNotEmpty) {
      String lastId = transactions.last.id;
      expect(lastId, isNotEmpty);

      request.pagingId = lastId;
      SEP24TransactionsResponse nextPage =
          await service.transactions(request);
      expect(nextPage.transactions, isNotNull);
    }
  });

  // --- Reading transaction fields ---
  test('sep-24: Reading transaction fields', () async {
    // Corresponds to "Reading transaction fields" section
    final service = createMockService();

    SEP24TransactionRequest request = SEP24TransactionRequest()
      ..jwt = jwtToken
      ..id = '82fhs729f63dh0v4';

    SEP24TransactionResponse response = await service.transaction(request);
    SEP24Transaction tx = response.transaction;

    // Withdrawal-specific fields
    expect(tx.kind, equals('withdrawal'));
    expect(tx.status, equals('completed'));
    expect(tx.withdrawAnchorAccount,
        equals('GBANAGOAXH5ONSBI2I6I5LHP2TCRHWMZIAMGUQH2TNKQNCOGJ7GC3ZOL'));
    expect(tx.withdrawMemo, equals('186384'));
    expect(tx.withdrawMemoType, equals('id'));
  });

  // --- Handling refunds ---
  test('sep-24: Handling refunds', () async {
    // Corresponds to "Handling refunds" section
    final service = createMockService();

    SEP24TransactionRequest request = SEP24TransactionRequest()
      ..jwt = jwtToken
      ..id = '82fhs729f63dh0v4';

    SEP24TransactionResponse response = await service.transaction(request);
    SEP24Transaction tx = response.transaction;

    // The mock transaction has refunds
    expect(tx.refunds, isNotNull);

    Refund refund = tx.refunds!;
    expect(refund.amountRefunded, equals('10'));
    expect(refund.amountFee, equals('5'));

    // Individual refund payments
    expect(refund.payments, isNotEmpty);
    RefundPayment payment = refund.payments.first;
    expect(payment.id, isNotEmpty);
    expect(payment.idType, equals('stellar'));
    expect(payment.amount, equals('10'));
    expect(payment.fee, equals('5'));
  });

  // --- Error handling: authentication required ---
  test('sep-24: Error handling - authentication required', () async {
    // Corresponds to "Error handling" section - 403 case
    final service = TransferServerSEP24Service(serviceAddress);
    service.httpClient = MockClient((request) async {
      return http.Response(
          json.encode({'type': 'authentication_required'}), 403);
    });

    bool thrown = false;
    try {
      SEP24DepositRequest request = SEP24DepositRequest()
        ..jwt = jwtToken
        ..assetCode = 'USD';

      await service.deposit(request);
    } on SEP24AuthenticationRequiredException {
      thrown = true;
    }
    expect(thrown, true);
  });

  // --- Error handling: request error ---
  test('sep-24: Error handling - request error', () async {
    // Corresponds to "Error handling" section - 400 case
    final service = TransferServerSEP24Service(serviceAddress);
    service.httpClient = MockClient((request) async {
      return http.Response(
          json.encode(
              {'error': "This anchor doesn't support the given currency"}),
          400);
    });

    bool thrown = false;
    try {
      SEP24DepositRequest request = SEP24DepositRequest()
        ..jwt = jwtToken
        ..assetCode = 'USD';

      await service.deposit(request);
    } on RequestErrorException catch (e) {
      thrown = true;
      expect(e.error, isNotEmpty);
    }
    expect(thrown, true);
  });

  // --- Error handling: transaction not found ---
  test('sep-24: Error handling - transaction not found', () async {
    // Corresponds to "Error handling" section - 404 case
    final service = TransferServerSEP24Service(serviceAddress);
    service.httpClient = MockClient((request) async {
      return http.Response(json.encode({'error': 'not found'}), 404);
    });

    bool thrown = false;
    try {
      SEP24TransactionRequest txRequest = SEP24TransactionRequest()
        ..jwt = jwtToken
        ..id = 'invalid-or-unknown-id';

      await service.transaction(txRequest);
    } on SEP24TransactionNotFoundException {
      thrown = true;
    }
    expect(thrown, true);
  });

  // --- Fee information (deprecated) ---
  test('sep-24: Fee information (deprecated)', () async {
    // Corresponds to "Fee information (deprecated)" section
    final service = TransferServerSEP24Service(serviceAddress);
    service.httpClient = MockClient((request) async {
      final url = request.url.toString();
      if (request.method == 'GET' && url.contains('info')) {
        return http.Response(infoJson(), 200);
      }
      if (request.method == 'GET' && url.contains('fee')) {
        String authHeader = request.headers['Authorization']!;
        expect(authHeader, contains(jwtToken));
        return http.Response(feeJson(), 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    // The mock info has fee endpoint disabled, but we test the fee call anyway
    SEP24FeeRequest feeRequest = SEP24FeeRequest()
      ..operation = 'deposit'
      ..assetCode = 'USD'
      ..amount = 1000.0
      ..jwt = jwtToken
      ..type = 'bank_account';

    SEP24FeeResponse feeResponse = await service.fee(feeRequest);
    expect(feeResponse.fee, equals(0.013));
  });

  // --- Error handling for withdraw ---
  test('sep-24: Withdraw error handling - authentication required', () async {
    final service = TransferServerSEP24Service(serviceAddress);
    service.httpClient = MockClient((request) async {
      return http.Response(
          json.encode({'type': 'authentication_required'}), 403);
    });

    bool thrown = false;
    try {
      SEP24WithdrawRequest request = SEP24WithdrawRequest()
        ..jwt = jwtToken
        ..assetCode = 'USD';
      await service.withdraw(request);
    } on SEP24AuthenticationRequiredException {
      thrown = true;
    }
    expect(thrown, true);
  });

  // --- Error handling for transactions query ---
  test('sep-24: Transactions query error - authentication required', () async {
    final service = TransferServerSEP24Service(serviceAddress);
    service.httpClient = MockClient((request) async {
      return http.Response(
          json.encode({'type': 'authentication_required'}), 403);
    });

    bool thrown = false;
    try {
      SEP24TransactionsRequest request = SEP24TransactionsRequest()
        ..jwt = jwtToken
        ..assetCode = 'USD';
      await service.transactions(request);
    } on SEP24AuthenticationRequiredException {
      thrown = true;
    }
    expect(thrown, true);
  });
}
