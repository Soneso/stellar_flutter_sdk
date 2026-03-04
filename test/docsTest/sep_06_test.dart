@Timeout(const Duration(seconds: 300))

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

void main() {
  final serviceAddress = "http://api.stellar.org/transfer/";
  final jwtToken =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJHQTZVSVhYUEVXWUZJTE5VSVdBQzM3WTRRUEVaTVFWREpIREtWV0ZaSjJLQ1dVQklVNUlYWk5EQSIsImp0aSI6IjE0NGQzNjdiY2IwZTcyY2FiZmRiZGU2MGVhZTBhZDczM2NjNjVkMmE2NTg3MDgzZGFiM2Q2MTZmODg1MTkwMjQiLCJpc3MiOiJodHRwczovL2ZsYXBweS1iaXJkLWRhcHAuZmlyZWJhc2VhcHAuY29tLyIsImlhdCI6MTUzNDI1Nzk5NCwiZXhwIjoxNTM0MzQ0Mzk0fQ.8nbB83Z6vGBgC1X9r3N6oQCFTBzDiITAfCJasRft0z0";
  final accountId = "GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP";

  // --- Mock JSON responses ---

  String infoJson() {
    return '{"deposit":{"USD":{"enabled":true,"authentication_required":true,"min_amount":0.1,"max_amount":1000,"fields":{"email_address":{"description":"your email address for transaction status updates","optional":true},"amount":{"description":"amount in USD that you plan to deposit"},"country_code":{"description":"The ISO 3166-1 alpha-3 code of the user\'s current address","choices":["USA","PRI"]},"type":{"description":"type of deposit to make","choices":["SEPA","SWIFT","cash"]}}},"ETH":{"enabled":true,"authentication_required":false}},"deposit-exchange":{"USD":{"authentication_required":true,"fields":{"email_address":{"description":"your email address for transaction status updates","optional":true},"amount":{"description":"amount in USD that you plan to deposit"},"country_code":{"description":"The ISO 3166-1 alpha-3 code of the user\'s current address","choices":["USA","PRI"]},"type":{"description":"type of deposit to make","choices":["SEPA","SWIFT","cash"]}}}},"withdraw":{"USD":{"enabled":true,"authentication_required":true,"min_amount":0.1,"max_amount":1000,"types":{"bank_account":{"fields":{"dest":{"description":"your bank account number"},"dest_extra":{"description":"your routing number"},"bank_branch":{"description":"address of your bank branch"},"phone_number":{"description":"your phone number in case there\'s an issue"},"country_code":{"description":"The ISO 3166-1 alpha-3 code of the user\'s current address","choices":["USA","PRI"]}}},"cash":{"fields":{"dest":{"description":"your email address. Your cashout PIN will be sent here.","optional":true}}}}},"ETH":{"enabled":false}},"withdraw-exchange":{"USD":{"authentication_required":true,"min_amount":0.1,"max_amount":1000,"types":{"bank_account":{"fields":{"dest":{"description":"your bank account number"},"dest_extra":{"description":"your routing number"}}}}}},"fee":{"enabled":true,"description":"Fees vary based on the assets transacted."},"transactions":{"enabled":true,"authentication_required":true},"transaction":{"enabled":true,"authentication_required":true},"features":{"account_creation":true,"claimable_balances":true}}';
  }

  String depositJson() {
    return '{"id":"9421871e-0623-4356-b7b5-5996da122f3e","instructions":{"organization.bank_number":{"value":"121122676","description":"US bank routing number"},"organization.bank_account_number":{"value":"13719713158835300","description":"US bank account number"}},"how":"Make a payment to Bank: 121122676 Account: 13719713158835300","fee_fixed":0.5,"fee_percent":1.0,"min_amount":10.0,"max_amount":10000.0,"eta":3600,"extra_info":{"message":"Please include your name in the memo."}}';
  }

  String withdrawJson() {
    return '{"account_id":"GCIBUCGPOHWMMMFPFTDWBSVHQRT4DIBJ7AD6BZJYDITBK2LCVBYW7HUQ","memo_type":"id","memo":"123","id":"9421871e-0623-4356-b7b5-5996da122f3e","fee_fixed":1.0,"fee_percent":0.5,"min_amount":5.0,"max_amount":50000.0,"eta":7200}';
  }

  String feeJson() {
    return '{"fee":0.013}';
  }

  String transactionsJson() {
    return '{"transactions":[{"id":"82fhs729f63dh0v4","kind":"deposit","status":"pending_external","status_eta":3600,"external_transaction_id":"2dd16cb409513026fbe7defc0c6f826c2d2c65c3da993f747d09bf7dafd31093","amount_in":"18.34","amount_out":"18.24","amount_fee":"0.1","started_at":"2017-03-20T17:05:32Z"},{"id":"52fys79f63dh3v2","kind":"deposit-exchange","status":"pending_anchor","status_eta":3600,"amount_in":"500","amount_in_asset":"iso4217:BRL","amount_out":"100","amount_out_asset":"stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN","amount_fee":"0.1","amount_fee_asset":"iso4217:BRL","started_at":"2021-06-11T17:05:32Z"},{"id":"82fhs729f63dh0v4","kind":"withdrawal","status":"completed","amount_in":"510","amount_out":"490","amount_fee":"5","started_at":"2017-03-20T17:00:02Z","completed_at":"2017-03-20T17:09:58Z","stellar_transaction_id":"17a670bc424ff5ce3b386dbfaae9990b66a2a37b4fbe51547e8794962a3f9e6a","external_transaction_id":"1238234","withdraw_anchor_account":"GBANAGOAXH5ONSBI2I6I5LHP2TCRHWMZIAMGUQH2TNKQNCOGJ7GC3ZOL","withdraw_memo":"186384","withdraw_memo_type":"id","refunds":{"amount_refunded":"10","amount_fee":"5","payments":[{"id":"b9d0b2292c4e09e8eb22d036171491e87b8d2086bf8b265874c8d182cb9c9020","id_type":"stellar","amount":"10","fee":"5"}]}}]}';
  }

  String transactionJson() {
    return '{"transaction":{"id":"82fhs729f63dh0v4","kind":"deposit","status":"pending_external","status_eta":3600,"external_transaction_id":"2dd16cb409513026fbe7defc0c6f826c2d2c65c3da993f747d09bf7dafd31093","amount_in":"18.34","amount_out":"18.24","amount_fee":"0.1","started_at":"2017-03-20T17:05:32Z","fee_details":{"total":"0.1","asset":"iso4217:USD"}}}';
  }

  String customerInfoNeededJson() {
    return '{"type":"non_interactive_customer_info_needed","fields":["family_name","given_name","address","tax_id"]}';
  }

  String customerInfoStatusJson() {
    return '{"type":"customer_info_status","status":"denied","more_info_url":"https://api.example.com/kycstatus?account=GACW7NONV43MZIFHCOKCQJAKSJSISSICFVUJ2C6EZIW5773OU3HD64VI"}';
  }

  String pendingInfoUpdateTransactionJson() {
    return '{"transaction":{"id":"82fhs729f63dh0v4","kind":"withdrawal","status":"pending_transaction_info_update","amount_in":"750.00","started_at":"2017-03-20T17:00:02Z","required_info_message":"Please provide the correct bank account.","required_info_updates":{"transaction":{"dest":{"description":"your bank account number"},"dest_extra":{"description":"your routing number"}}}}}';
  }

  // --- Tests corresponding to doc snippets ---

  test('sep-06: Creating the service - Direct URL', () {
    // Snippet from sep-06.md "Direct URL"
    TransferServerService transferService =
        TransferServerService("https://testanchor.stellar.org/sep6");

    expect(transferService, isNotNull);
  });

  test('sep-06: Querying anchor info', () async {
    // Snippet from sep-06.md "Querying anchor info"
    final transferService = TransferServerService(serviceAddress);
    transferService.httpClient = MockClient((request) async {
      if (request.url.toString().contains("info")) {
        return http.Response(infoJson(), 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    InfoResponse info = await transferService.info();

    // Check deposit assets and their limits
    expect(info.depositAssets, isNotNull);
    expect(info.depositAssets!.length, 2);

    DepositAsset usdDeposit = info.depositAssets!["USD"]!;
    expect(usdDeposit.enabled, true);
    expect(usdDeposit.authenticationRequired, true);
    expect(usdDeposit.minAmount, 0.1);
    expect(usdDeposit.maxAmount, 1000.0);

    // Check deposit asset fields
    expect(usdDeposit.fields, isNotNull);
    expect(usdDeposit.fields!["email_address"]!.optional, true);
    expect(usdDeposit.fields!["country_code"]!.choices!.contains("USA"), true);

    // Check withdrawal assets
    expect(info.withdrawAssets, isNotNull);
    WithdrawAsset withdrawUsd = info.withdrawAssets!["USD"]!;
    expect(withdrawUsd.enabled, true);
    expect(withdrawUsd.minAmount, 0.1);
    expect(withdrawUsd.maxAmount, 1000.0);

    // Check withdrawal types (nested map structure)
    expect(withdrawUsd.types, isNotNull);
    expect(withdrawUsd.types!.length, 2);
    Map<String, AnchorField>? bankFields = withdrawUsd.types!["bank_account"];
    expect(bankFields, isNotNull);
    expect(bankFields!["dest"]!.description, "your bank account number");

    // Check deposit-exchange assets
    expect(info.depositExchangeAssets, isNotNull);
    DepositExchangeAsset depExUsd = info.depositExchangeAssets!["USD"]!;
    expect(depExUsd.authenticationRequired, true);

    // Check withdraw-exchange assets
    expect(info.withdrawExchangeAssets, isNotNull);

    // Feature flags
    expect(info.featureFlags, isNotNull);
    expect(info.featureFlags!.accountCreation, true);
    expect(info.featureFlags!.claimableBalances, true);

    // Endpoint availability
    expect(info.feeInfo?.enabled, true);
    expect(info.transactionsInfo?.enabled, true);
    expect(info.transactionInfo?.enabled, true);
  });

  test('sep-06: Basic deposit request', () async {
    // Snippet from sep-06.md "Basic deposit request"
    final transferService = TransferServerService(serviceAddress);
    transferService.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      if (request.url.toString().contains("deposit") &&
          authHeader.contains(jwtToken)) {
        return http.Response(depositJson(), 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    DepositRequest request = DepositRequest(
      assetCode: "USD",
      account: accountId,
      jwt: jwtToken,
      type: "bank_account",
      amount: "100.00",
    );

    DepositResponse response = await transferService.deposit(request);

    // Verify deposit response fields from the doc
    expect(response.how, isNotNull);
    expect(response.how, contains("121122676"));

    expect(response.instructions, isNotNull);
    var bankNumberKey = "organization.bank_number";
    expect(response.instructions!.containsKey(bankNumberKey), true);
    expect(response.instructions![bankNumberKey]!.value, "121122676");
    expect(
        response.instructions![bankNumberKey]!.description, "US bank routing number");

    expect(response.id, "9421871e-0623-4356-b7b5-5996da122f3e");
    expect(response.feeFixed, 0.5);
    expect(response.feePercent, 1.0);
    expect(response.minAmount, 10.0);
    expect(response.maxAmount, 10000.0);
    expect(response.eta, 3600);
    expect(response.extraInfo?.message, "Please include your name in the memo.");
  });

  test('sep-06: Deposit with all options', () async {
    // Snippet from sep-06.md "Deposit with all options"
    final transferService = TransferServerService(serviceAddress);
    transferService.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      if (request.url.toString().contains("deposit") &&
          authHeader.contains(jwtToken)) {
        // Verify optional parameters are sent
        var url = request.url.toString();
        expect(url.contains("memo_type=id"), true);
        expect(url.contains("memo=12345"), true);
        expect(url.contains("SEPA"), true);
        expect(url.contains("lang=en"), true);
        expect(url.contains("country_code=USA"), true);
        expect(url.contains("claimable_balance_supported=true"), true);
        return http.Response(depositJson(), 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    DepositRequest request = DepositRequest(
      assetCode: "USD",
      account: accountId,
      memoType: "id",
      memo: "12345",
      emailAddress: "user@example.com",
      type: "SEPA",
      lang: "en",
      onChangeCallback: "https://wallet.example.com/callback",
      amount: "500.00",
      countryCode: "USA",
      claimableBalanceSupported: "true",
      customerId: "cust-123",
      locationId: "loc-456",
      extraFields: {"custom_field": "value"},
      jwt: jwtToken,
    );

    DepositResponse response = await transferService.deposit(request);
    expect(response.id, isNotNull);
  });

  test('sep-06: Basic withdrawal request', () async {
    // Snippet from sep-06.md "Basic withdrawal request"
    final transferService = TransferServerService(serviceAddress);
    transferService.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      if (request.url.toString().contains("withdraw") &&
          authHeader.contains(jwtToken)) {
        return http.Response(withdrawJson(), 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    WithdrawRequest request = WithdrawRequest(
      assetCode: "USDC",
      type: "bank_account",
      jwt: jwtToken,
      account: accountId,
      amount: "500.00",
    );

    WithdrawResponse response = await transferService.withdraw(request);

    // Verify withdraw response fields from the doc
    expect(response.accountId,
        "GCIBUCGPOHWMMMFPFTDWBSVHQRT4DIBJ7AD6BZJYDITBK2LCVBYW7HUQ");
    expect(response.memoType, "id");
    expect(response.memo, "123");
    expect(response.id, "9421871e-0623-4356-b7b5-5996da122f3e");
    expect(response.feeFixed, 1.0);
    expect(response.feePercent, 0.5);
    expect(response.minAmount, 5.0);
    expect(response.maxAmount, 50000.0);
    expect(response.eta, 7200);
  });

  test('sep-06: Withdrawal with all options', () async {
    // Snippet from sep-06.md "Withdrawal with all options"
    final transferService = TransferServerService(serviceAddress);
    transferService.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      if (request.url.toString().contains("withdraw") &&
          authHeader.contains(jwtToken)) {
        var url = request.url.toString();
        expect(url.contains("bank_account"), true);
        expect(url.contains("lang=en"), true);
        expect(url.contains("country_code=DEU"), true);
        return http.Response(withdrawJson(), 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    WithdrawRequest request = WithdrawRequest(
      assetCode: "USDC",
      type: "bank_account",
      account: accountId,
      lang: "en",
      onChangeCallback: "https://wallet.example.com/callback",
      amount: "1000.00",
      countryCode: "DEU",
      refundMemo: "refund-123",
      refundMemoType: "text",
      customerId: "cust-123",
      locationId: "loc-456",
      extraFields: {"bank_name": "Example Bank"},
      jwt: jwtToken,
    );

    WithdrawResponse response = await transferService.withdraw(request);
    expect(response.id, isNotNull);
  });

  test('sep-06: Deposit exchange', () async {
    // Snippet from sep-06.md "Deposit exchange"
    final transferService = TransferServerService(serviceAddress);
    transferService.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      if (request.url.toString().contains("deposit-exchange") &&
          authHeader.contains(jwtToken)) {
        var url = request.url.toString();
        expect(url.contains("USDC"), true);
        expect(url.contains("iso4217%3ABRL"), true);
        expect(url.contains("480"), true);
        expect(url.contains("282837"), true);
        return http.Response(depositJson(), 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    DepositExchangeRequest depositExchange = DepositExchangeRequest(
      destinationAsset: "USDC",
      sourceAsset: "iso4217:BRL",
      amount: "480.00",
      account: accountId,
      quoteId: "282837",
      type: "bank_account",
      jwt: jwtToken,
    );

    DepositResponse response =
        await transferService.depositExchange(depositExchange);
    expect(response.id, "9421871e-0623-4356-b7b5-5996da122f3e");
    expect(response.instructions, isNotNull);
  });

  test('sep-06: Withdraw exchange', () async {
    // Snippet from sep-06.md "Withdraw exchange"
    final transferService = TransferServerService(serviceAddress);
    transferService.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      if (request.url.toString().contains("withdraw-exchange") &&
          authHeader.contains(jwtToken)) {
        var url = request.url.toString();
        expect(url.contains("USDC"), true);
        expect(url.contains("iso4217%3ANGN"), true);
        expect(url.contains("100"), true);
        expect(url.contains("282838"), true);
        return http.Response(withdrawJson(), 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    WithdrawExchangeRequest withdrawExchange = WithdrawExchangeRequest(
      sourceAsset: "USDC",
      destinationAsset: "iso4217:NGN",
      amount: "100.00",
      type: "bank_account",
      quoteId: "282838",
      account: accountId,
      jwt: jwtToken,
    );

    WithdrawResponse response =
        await transferService.withdrawExchange(withdrawExchange);
    expect(response.accountId, isNotNull);
    expect(response.id, isNotNull);
    expect(response.memo, "123");
  });

  test('sep-06: Checking fees', () async {
    // Snippet from sep-06.md "Checking fees"
    final transferService = TransferServerService(serviceAddress);
    transferService.httpClient = MockClient((request) async {
      if (request.url.toString().contains("info")) {
        return http.Response(infoJson(), 200);
      }
      String? authHeader = request.headers["Authorization"];
      if (request.url.toString().contains("fee") &&
          authHeader != null &&
          authHeader.contains(jwtToken)) {
        return http.Response(feeJson(), 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    // Check if fee endpoint is enabled
    InfoResponse info = await transferService.info();
    expect(info.feeInfo?.enabled, true);

    FeeRequest feeRequest = FeeRequest(
      operation: "deposit",
      assetCode: "USD",
      amount: 100.00, // Note: amount is double, NOT a string
      type: "bank_account",
      jwt: jwtToken,
    );

    FeeResponse feeResponse = await transferService.fee(feeRequest);
    expect(feeResponse.fee, 0.013);
  });

  test('sep-06: Transaction history', () async {
    // Snippet from sep-06.md "Transaction history"
    final transferService = TransferServerService(serviceAddress);
    transferService.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      if (request.url.toString().contains("transactions") &&
          authHeader.contains(jwtToken)) {
        return http.Response(transactionsJson(), 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    AnchorTransactionsRequest request = AnchorTransactionsRequest(
      assetCode: "USD",
      account: accountId,
      jwt: jwtToken,
      limit: 10,
      kind: "deposit",
      lang: "en",
    );

    AnchorTransactionsResponse response =
        await transferService.transactions(request);

    expect(response.transactions.length, 3);

    // First transaction: deposit
    AnchorTransaction tx = response.transactions.first;
    expect(tx.id, "82fhs729f63dh0v4");
    expect(tx.kind, "deposit");
    expect(tx.status, "pending_external");
    expect(tx.statusEta, 3600);
    expect(tx.amountIn, "18.34");
    expect(tx.amountOut, "18.24");
    expect(tx.amountFee, "0.1");
    expect(tx.startedAt, "2017-03-20T17:05:32Z");

    // Second transaction: deposit-exchange with asset info
    AnchorTransaction tx2 = response.transactions[1];
    expect(tx2.kind, "deposit-exchange");
    expect(tx2.amountInAsset, "iso4217:BRL");
    expect(tx2.amountOutAsset,
        "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN");

    // Third transaction: withdrawal with refunds
    AnchorTransaction tx3 = response.transactions[2];
    expect(tx3.kind, "withdrawal");
    expect(tx3.status, "completed");
    expect(tx3.withdrawAnchorAccount,
        "GBANAGOAXH5ONSBI2I6I5LHP2TCRHWMZIAMGUQH2TNKQNCOGJ7GC3ZOL");
    expect(tx3.withdrawMemo, "186384");
    expect(tx3.withdrawMemoType, "id");
    expect(tx3.refunds, isNotNull);
    expect(tx3.refunds!.amountRefunded, "10");
    expect(tx3.refunds!.amountFee, "5");
    expect(tx3.refunds!.payments.length, 1);
    expect(tx3.refunds!.payments.first.idType, "stellar");
  });

  test('sep-06: Single transaction status', () async {
    // Snippet from sep-06.md "Single transaction status"
    final transferService = TransferServerService(serviceAddress);
    transferService.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      if (request.url.toString().contains("transaction") &&
          !request.url.toString().contains("transactions") &&
          authHeader.contains(jwtToken)) {
        return http.Response(transactionJson(), 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    // Query by anchor transaction ID
    AnchorTransactionRequest request = AnchorTransactionRequest();
    request.id = "82fhs729f63dh0v4";
    request.jwt = jwtToken;

    AnchorTransactionResponse response =
        await transferService.transaction(request);
    AnchorTransaction tx = response.transaction;

    expect(tx.id, "82fhs729f63dh0v4");
    expect(tx.kind, "deposit");
    expect(tx.status, "pending_external");
    expect(tx.statusEta, 3600);
    expect(tx.amountIn, "18.34");
    expect(tx.amountOut, "18.24");
    expect(tx.startedAt, "2017-03-20T17:05:32Z");

    // Fee details
    expect(tx.feeDetails, isNotNull);
    expect(tx.feeDetails!.total, "0.1");
    expect(tx.feeDetails!.asset, "iso4217:USD");

    // Also supports lookup by Stellar transaction hash
    AnchorTransactionRequest request2 = AnchorTransactionRequest();
    request2.stellarTransactionId =
        "17a670bc424ff5ce3b386dbfaae9990b66a2a37b4fbe51547e8794962a3f9e6a";
    request2.jwt = jwtToken;
    AnchorTransactionResponse response2 =
        await transferService.transaction(request2);
    expect(response2.transaction.id, "82fhs729f63dh0v4");

    // Or by external transaction ID
    AnchorTransactionRequest request3 = AnchorTransactionRequest();
    request3.externalTransactionId = "1238234";
    request3.jwt = jwtToken;
    AnchorTransactionResponse response3 =
        await transferService.transaction(request3);
    expect(response3.transaction.id, "82fhs729f63dh0v4");
  });

  test('sep-06: Updating pending transactions', () async {
    // Snippet from sep-06.md "Updating pending transactions"
    final transferService = TransferServerService(serviceAddress);
    transferService.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      if (request.method == "PATCH" &&
          request.url.toString().contains("transactions/82fhs729f63dh0v4") &&
          authHeader.contains(jwtToken)) {
        return http.Response("", 200);
      }
      if (request.url.toString().contains("transaction") &&
          !request.url.toString().contains("transactions") &&
          request.method == "GET" &&
          authHeader.contains(jwtToken)) {
        return http.Response(pendingInfoUpdateTransactionJson(), 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    // First, check what fields are required
    AnchorTransactionRequest txRequest = AnchorTransactionRequest();
    txRequest.id = "82fhs729f63dh0v4";
    txRequest.jwt = jwtToken;
    AnchorTransactionResponse txResponse =
        await transferService.transaction(txRequest);

    expect(txResponse.transaction.status, "pending_transaction_info_update");
    expect(txResponse.transaction.requiredInfoMessage, isNotNull);
    expect(txResponse.transaction.requiredInfoUpdates, isNotNull);
    expect(txResponse.transaction.requiredInfoUpdates!.length, 2);
    expect(txResponse.transaction.requiredInfoUpdates!["dest"]!.description,
        "your bank account number");

    // Submit the updated information
    // Note: id is a positional argument, not named
    PatchTransactionRequest patchRequest =
        PatchTransactionRequest("82fhs729f63dh0v4");
    patchRequest.fields = {
      "dest": "12345678901234",
      "dest_extra": "021000021",
    };
    patchRequest.jwt = jwtToken;

    http.Response patchResponse =
        await transferService.patchTransaction(patchRequest);
    expect(patchResponse.statusCode, 200);
  });

  test('sep-06: Error handling - CustomerInformationNeededException',
      () async {
    // Snippet from sep-06.md "Error handling"
    final transferService = TransferServerService(serviceAddress);
    transferService.httpClient = MockClient((request) async {
      if (request.url.toString().contains("deposit")) {
        return http.Response(customerInfoNeededJson(), 403);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    DepositRequest request = DepositRequest(
      assetCode: "USD",
      account: accountId,
      jwt: jwtToken,
    );

    bool thrown = false;
    try {
      await transferService.deposit(request);
    } on CustomerInformationNeededException catch (e) {
      thrown = true;
      expect(e.response.fields, isNotNull);
      expect(e.response.fields!.contains("family_name"), true);
      expect(e.response.fields!.contains("tax_id"), true);
    }
    expect(thrown, true);
  });

  test('sep-06: Error handling - CustomerInformationStatusException',
      () async {
    // Snippet from sep-06.md "Error handling"
    final transferService = TransferServerService(serviceAddress);
    transferService.httpClient = MockClient((request) async {
      if (request.url.toString().contains("deposit")) {
        return http.Response(customerInfoStatusJson(), 403);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    DepositRequest request = DepositRequest(
      assetCode: "USD",
      account: accountId,
      jwt: jwtToken,
    );

    bool thrown = false;
    try {
      await transferService.deposit(request);
    } on CustomerInformationStatusException catch (e) {
      thrown = true;
      expect(e.response.status, "denied");
      expect(e.response.moreInfoUrl,
          "https://api.example.com/kycstatus?account=GACW7NONV43MZIFHCOKCQJAKSJSISSICFVUJ2C6EZIW5773OU3HD64VI");
    }
    expect(thrown, true);
  });
}
