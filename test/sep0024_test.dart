@Timeout(const Duration(seconds: 400))
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

void main() {
  final serviceAddress = "http://api.stellar.org/transfer-sep24/";
  final jwtToken =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJHQTZVSVhYUEVXWUZJTE5VSVdBQzM3WTRRUEVaTVFWREpIREtWV0ZaSjJLQ1dVQklVNUlYWk5EQSIsImp0aSI6IjE0NGQzNjdiY2IwZTcyY2FiZmRiZGU2MGVhZTBhZDczM2NjNjVkMmE2NTg3MDgzZGFiM2Q2MTZmODg1MTkwMjQiLCJpc3MiOiJodHRwczovL2ZsYXBweS1iaXJkLWRhcHAuZmlyZWJhc2VhcHAuY29tLyIsImlhdCI6MTUzNDI1Nzk5NCwiZXhwIjoxNTM0MzQ0Mzk0fQ.8nbB83Z6vGBgC1X9r3N6oQCFTBzDiITAfCJasRft0z0";

  String requestInfo() {
    return "{  \"deposit\": {    \"USD\": {      \"enabled\": true,      \"fee_fixed\": 5,      \"fee_percent\": 1,      \"min_amount\": 0.1,      \"max_amount\": 1000    },    \"ETH\": {      \"enabled\": true,      \"fee_fixed\": 0.002,      \"fee_percent\": 0    },    \"native\": {      \"enabled\": true,      \"fee_fixed\": 0.00001,      \"fee_percent\": 0    }  },  \"withdraw\": {    \"USD\": {      \"enabled\": true,      \"fee_minimum\": 5,      \"fee_percent\": 0.5,      \"min_amount\": 0.1,      \"max_amount\": 1000    },    \"ETH\": {      \"enabled\": false    },    \"native\": {      \"enabled\": true    }  },  \"fee\": {    \"enabled\": false  },  \"features\": {    \"account_creation\": true,    \"claimable_balances\": true  }}";
  }

  String requestFee() {
    return "{\"fee\": 0.013}";
  }

  String requestInteractive() {
    return "{  \"type\": \"completed\",  \"url\": \"https://api.example.com/kycflow?account=GACW7NONV43MZIFHCOKCQJAKSJSISSICFVUJ2C6EZIW5773OU3HD64VI\",  \"id\": \"82fhs729f63dh0v4\"}";
  }

  String requestTransactions() {
    return "{  \"transactions\": [    {      \"id\": \"82fhs729f63dh0v4\",      \"kind\": \"deposit\",      \"status\": \"pending_external\",      \"status_eta\": 3600,      \"external_transaction_id\": \"2dd16cb409513026fbe7defc0c6f826c2d2c65c3da993f747d09bf7dafd31093\",      \"more_info_url\": \"https://youranchor.com/tx/242523523\",      \"amount_in\": \"18.34\",      \"amount_out\": \"18.24\",      \"amount_fee\": \"0.1\",      \"started_at\": \"2017-03-20T17:05:32Z\",      \"claimable_balance_id\": null    },    {      \"id\": \"82fhs729f63dh0v4\",      \"kind\": \"withdrawal\",      \"status\": \"completed\",      \"amount_in\": \"510\",      \"amount_out\": \"490\",      \"amount_fee\": \"5\",      \"started_at\": \"2017-03-20T17:00:02Z\",      \"completed_at\": \"2017-03-20T17:09:58Z\",      \"updated_at\": \"2017-03-20T17:09:58Z\",      \"more_info_url\": \"https://youranchor.com/tx/242523523\",      \"stellar_transaction_id\": \"17a670bc424ff5ce3b386dbfaae9990b66a2a37b4fbe51547e8794962a3f9e6a\",      \"external_transaction_id\": \"1941491\",      \"withdraw_anchor_account\": \"GBANAGOAXH5ONSBI2I6I5LHP2TCRHWMZIAMGUQH2TNKQNCOGJ7GC3ZOL\",      \"withdraw_memo\": \"186384\",      \"withdraw_memo_type\": \"id\",      \"refunds\": {        \"amount_refunded\": \"10\",        \"amount_fee\": \"5\",        \"payments\": [          {            \"id\": \"b9d0b2292c4e09e8eb22d036171491e87b8d2086bf8b265874c8d182cb9c9020\",            \"id_type\": \"stellar\",            \"amount\": \"10\",            \"fee\": \"5\"          }        ]      }    },    {      \"id\": \"92fhs729f63dh0v3\",      \"kind\": \"deposit\",      \"status\": \"completed\",      \"amount_in\": \"510\",      \"amount_out\": \"490\",      \"amount_fee\": \"5\",      \"started_at\": \"2017-03-20T17:00:02Z\",      \"completed_at\": \"2017-03-20T17:09:58Z\",      \"updated_at\": \"2017-03-20T17:09:58Z\",      \"more_info_url\": \"https://youranchor.com/tx/242523526\",      \"stellar_transaction_id\": \"17a670bc424ff5ce3b386dbfaae9990b66a2a37b4fbe51547e8794962a3f9e6a\",      \"external_transaction_id\": \"1947101\",      \"refunds\": {        \"amount_refunded\": \"10\",        \"amount_fee\": \"5\",        \"payments\": [          {            \"id\": \"1937103\",            \"id_type\": \"external\",            \"amount\": \"10\",            \"fee\": \"5\"          }        ]      }    },    {      \"id\": \"92fhs729f63dh0v3\",      \"kind\": \"deposit\",      \"status\": \"pending_anchor\",      \"amount_in\": \"510\",      \"amount_out\": \"490\",      \"amount_fee\": \"5\",      \"started_at\": \"2017-03-20T17:00:02Z\",      \"updated_at\": \"2017-03-20T17:05:58Z\",      \"more_info_url\": \"https://youranchor.com/tx/242523526\",      \"stellar_transaction_id\": \"17a670bc424ff5ce3b386dbfaae9990b66a2a37b4fbe51547e8794962a3f9e6a\",      \"external_transaction_id\": \"1947101\",      \"refunds\": {        \"amount_refunded\": \"10\",        \"amount_fee\": \"5\",        \"payments\": [          {            \"id\": \"1937103\",            \"id_type\": \"external\",            \"amount\": \"10\",            \"fee\": \"5\"          }        ]      }    }  ]}";
  }

  String requestTransaction() {
    return "{  \"transaction\": {      \"id\": \"82fhs729f63dh0v4\",      \"kind\": \"withdrawal\",      \"status\": \"completed\",      \"amount_in\": \"510\",      \"amount_out\": \"490\",      \"amount_fee\": \"5\",      \"started_at\": \"2017-03-20T17:00:02Z\",      \"completed_at\": \"2017-03-20T17:09:58Z\",      \"updated_at\": \"2017-03-20T17:09:58Z\",      \"more_info_url\": \"https://youranchor.com/tx/242523523\",      \"stellar_transaction_id\": \"17a670bc424ff5ce3b386dbfaae9990b66a2a37b4fbe51547e8794962a3f9e6a\",      \"external_transaction_id\": \"1941491\",      \"withdraw_anchor_account\": \"GBANAGOAXH5ONSBI2I6I5LHP2TCRHWMZIAMGUQH2TNKQNCOGJ7GC3ZOL\",      \"withdraw_memo\": \"186384\",      \"withdraw_memo_type\": \"id\",      \"refunds\": {        \"amount_refunded\": \"10\",        \"amount_fee\": \"5\",        \"payments\": [          {            \"id\": \"b9d0b2292c4e09e8eb22d036171491e87b8d2086bf8b265874c8d182cb9c9020\",            \"id_type\": \"stellar\",            \"amount\": \"10\",            \"fee\": \"5\"          }        ]      }    }}";
  }

  String requestEmptyTransactions() {
    return "{  \"transactions\": []}";
  }

  test('test info', () async {
    final transferService = TransferServerSEP24Service(serviceAddress);
    transferService.httpClient = MockClient((request) async {
      if (request.url.toString().startsWith(serviceAddress) &&
          request.method == "GET" &&
          request.url.toString().contains("info")) {
        return http.Response(requestInfo(), 200);
      }

      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    SEP24InfoResponse infoResponse = await transferService.info("en");

    assert(infoResponse.depositAssets!.length == 3);
    SEP24DepositAsset depositAssetUSD = infoResponse.depositAssets!["USD"]!;
    assert(depositAssetUSD.enabled);
    assert(depositAssetUSD.feeFixed == 5.0);
    assert(depositAssetUSD.feePercent == 1.0);
    assert(depositAssetUSD.feeMinimum == null);
    assert(depositAssetUSD.minAmount == 0.1);
    assert(depositAssetUSD.maxAmount == 1000.0);
    SEP24DepositAsset depositAssetETH = infoResponse.depositAssets!["ETH"]!;
    assert(depositAssetETH.enabled);
    assert(depositAssetETH.feeFixed == 0.002);
    assert(depositAssetETH.feePercent == 0.0);
    assert(depositAssetETH.feeMinimum == null);
    assert(depositAssetETH.minAmount == null);
    assert(depositAssetETH.maxAmount == null);
    SEP24DepositAsset depositAssetNative = infoResponse.depositAssets!["native"]!;
    assert(depositAssetNative.enabled);
    assert(depositAssetNative.feeFixed == 0.00001);
    assert(depositAssetNative.feePercent == 0.0);
    assert(depositAssetNative.feeMinimum == null);
    assert(depositAssetNative.minAmount == null);
    assert(depositAssetNative.maxAmount == null);


    SEP24WithdrawAsset withdrawAssetUSD = infoResponse.withdrawAssets!["USD"]!;
    assert(withdrawAssetUSD.enabled);
    assert(withdrawAssetUSD.feeMinimum == 5.0);
    assert(withdrawAssetUSD.feePercent == 0.5);
    assert(withdrawAssetUSD.minAmount == 0.1);
    assert(withdrawAssetUSD.maxAmount == 1000.0);
    assert(withdrawAssetUSD.feeFixed == null);

    SEP24WithdrawAsset withdrawAssetETH = infoResponse.withdrawAssets!["ETH"]!;
    assert(!withdrawAssetETH.enabled);
    SEP24WithdrawAsset withdrawAssetNative = infoResponse.withdrawAssets!["native"]!;
    assert(withdrawAssetNative.enabled);

    assert(!infoResponse.feeEndpointInfo!.enabled);
    assert(infoResponse.featureFlags!.accountCreation);
    assert(infoResponse.featureFlags!.claimableBalances);
  });

  test('test fee', () async {
    final transferService = TransferServerSEP24Service(serviceAddress);
    transferService.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      if (request.url.toString().startsWith(serviceAddress) &&
          request.method == "GET" &&
          request.url.toString().contains("fee") &&
          authHeader.contains(jwtToken)) {
        return http.Response(requestFee(), 200);
      }

      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    SEP24FeeRequest feeRequest = SEP24FeeRequest();
    feeRequest.operation = "deposit";
    feeRequest.type = "SEPA";
    feeRequest.assetCode = "ETH";
    feeRequest.amount = 2034.09;
    feeRequest.jwt = jwtToken;

    SEP24FeeResponse feeResponse = await transferService.fee(feeRequest);
    assert(feeResponse.fee == 0.013);
  });

  test('deposit sep 24', () async {
    final transferService = TransferServerSEP24Service(serviceAddress);
    transferService.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      String contentType = request.headers["content-type"]!;
      if (request.url.toString().startsWith(serviceAddress) &&
          request.method == "POST" &&
          request.url.toString().contains("transactions/deposit/interactive") &&
          authHeader.contains(jwtToken) &&
          contentType.startsWith("multipart/form-data;")) {

        // print(request.body);
        assert(request.body.contains('first_name'));
        assert(request.body.contains('George'));
        assert(request.body.contains('bank_account_number'));
        assert(request.body.contains('XX18981288373773'));
        assert(request.body.contains('name'));
        assert(request.body.contains('George Ltd.'));
        assert(request.body.contains('organization.bank_account_number'));
        assert(request.body.contains('YY76253437289616234'));
        return http.Response(requestInteractive(), 200);
      }

      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    SEP24DepositRequest request = new SEP24DepositRequest();
    request.assetCode = "USD";
    request.jwt = jwtToken;

    var personFields = NaturalPersonKYCFields();
    personFields.firstName = 'George';
    var personFinancial = FinancialAccountKYCFields();
    personFinancial.bankAccountNumber = 'XX18981288373773';
    personFields.financialAccountKYCFields = personFinancial;

    var orgFields = OrganizationKYCFields();
    orgFields.name = 'George Ltd.';
    var orgFinancial = FinancialAccountKYCFields();
    orgFinancial.bankAccountNumber = 'YY76253437289616234';
    orgFields.financialAccountKYCFields = orgFinancial;

    var kycFields = new StandardKYCFields();
    kycFields.naturalPersonKYCFields = personFields;
    kycFields.organizationKYCFields = orgFields;

    request.kycFields = kycFields;

    SEP24InteractiveResponse response = await transferService.deposit(request);

    assert("82fhs729f63dh0v4" == response.id);
    assert("completed" == response.type);
    assert("https://api.example.com/kycflow?account=GACW7NONV43MZIFHCOKCQJAKSJSISSICFVUJ2C6EZIW5773OU3HD64VI" == response.url);
  });

  test('withdraw sep 24', () async {
    final transferService = TransferServerSEP24Service(serviceAddress);
    transferService.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      String contentType = request.headers["content-type"]!;
      if (request.url.toString().startsWith(serviceAddress) &&
          request.method == "POST" &&
          request.url.toString().contains("transactions/withdraw/interactive") &&
          authHeader.contains(jwtToken) &&
          contentType.startsWith("multipart/form-data;")) {
        return http.Response(requestInteractive(), 200);
      }

      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    SEP24WithdrawRequest request = new SEP24WithdrawRequest();
    request.assetCode = "USD";
    request.jwt = jwtToken;

    SEP24InteractiveResponse response = await transferService.withdraw(request);

    assert("82fhs729f63dh0v4" == response.id);
    assert("completed" == response.type);
    assert("https://api.example.com/kycflow?account=GACW7NONV43MZIFHCOKCQJAKSJSISSICFVUJ2C6EZIW5773OU3HD64VI" == response.url);
  });

  test('test multiple transactions', () async {
    final transferService = TransferServerSEP24Service(serviceAddress);
    transferService.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      if (request.url.toString().startsWith(serviceAddress) &&
          request.method == "GET" &&
          request.url.toString().contains("transactions") &&
          authHeader.contains(jwtToken)) {
        return http.Response(requestTransactions(), 200);
      }

      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    SEP24TransactionsRequest request = SEP24TransactionsRequest();
    request.assetCode = "ETH";
    request.jwt = jwtToken;

    SEP24TransactionsResponse response = await transferService.transactions(request);
    List<SEP24Transaction> transactions = response.transactions;
    assert(transactions.length == 4);

    SEP24Transaction transaction = transactions.first;
    assert("82fhs729f63dh0v4" == transaction.id);
    assert("deposit" == transaction.kind);
    assert("pending_external" == transaction.status);
    assert(3600 == transaction.statusEta);
    assert("2dd16cb409513026fbe7defc0c6f826c2d2c65c3da993f747d09bf7dafd31093" == transaction.externalTransactionId);
    assert("https://youranchor.com/tx/242523523" == transaction.moreInfoUrl);
    assert("18.34" == transaction.amountIn);
    assert("18.24" == transaction.amountOut);
    assert("0.1" == transaction.amountFee);
    assert("2017-03-20T17:05:32Z" == transaction.startedAt);
    assert(null == transaction.claimableBalanceId);

    transaction = transactions[1];
    assert("82fhs729f63dh0v4" == transaction.id);
    assert("withdrawal" == transaction.kind);
    assert("completed" == transaction.status);
    assert("510" == transaction.amountIn);
    assert("490" == transaction.amountOut);
    assert("5" == transaction.amountFee);
    assert("2017-03-20T17:00:02Z" == transaction.startedAt);
    assert("2017-03-20T17:09:58Z" == transaction.completedAt);
    assert("2017-03-20T17:09:58Z" == transaction.updatedAt);
    assert("https://youranchor.com/tx/242523523" == transaction.moreInfoUrl);
    assert("17a670bc424ff5ce3b386dbfaae9990b66a2a37b4fbe51547e8794962a3f9e6a" == transaction.stellarTransactionId);
    assert("1941491" == transaction.externalTransactionId);
    assert("GBANAGOAXH5ONSBI2I6I5LHP2TCRHWMZIAMGUQH2TNKQNCOGJ7GC3ZOL" == transaction.withdrawAnchorAccount);
    assert("186384" == transaction.withdrawMemo);
    assert("id" == transaction.withdrawMemoType);
    assert("10" == transaction.refunds!.amountRefunded);
    assert("5" == transaction.refunds!.amountFee);
    List<RefundPayment> refundPayments = transaction.refunds!.payments;
    assert(refundPayments.length == 1);
    RefundPayment refundPayment = refundPayments.first;
    assert("b9d0b2292c4e09e8eb22d036171491e87b8d2086bf8b265874c8d182cb9c9020" == refundPayment.id);
    assert("stellar" == refundPayment.idType);
    assert("10" == refundPayment.amount);
    assert("5" == refundPayment.fee);
  });

  test('test single transaction', () async {
    final transferService = TransferServerSEP24Service(serviceAddress);
    transferService.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      if (request.url.toString().startsWith(serviceAddress) &&
          request.method == "GET" &&
          request.url.toString().contains("transaction") &&
          authHeader.contains(jwtToken)) {
        return http.Response(requestTransaction(), 200);
      }

      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    SEP24TransactionRequest request = SEP24TransactionRequest();
    request.stellarTransactionId = "17a670bc424ff5ce3b386dbfaae9990b66a2a37b4fbe51547e8794962a3f9e6a";
    request.jwt = jwtToken;

    SEP24TransactionResponse response = await transferService.transaction(request);
    SEP24Transaction transaction  = response.transaction;

    assert("82fhs729f63dh0v4" == transaction.id);
    assert("withdrawal" == transaction.kind);
    assert("completed" == transaction.status);
    assert("510" == transaction.amountIn);
    assert("490" == transaction.amountOut);
    assert("5" == transaction.amountFee);
    assert("2017-03-20T17:00:02Z" == transaction.startedAt);
    assert("2017-03-20T17:09:58Z" == transaction.completedAt);
    assert("2017-03-20T17:09:58Z" == transaction.updatedAt);
    assert("https://youranchor.com/tx/242523523" == transaction.moreInfoUrl);
    assert("17a670bc424ff5ce3b386dbfaae9990b66a2a37b4fbe51547e8794962a3f9e6a" == transaction.stellarTransactionId);
    assert("1941491" == transaction.externalTransactionId);
    assert("GBANAGOAXH5ONSBI2I6I5LHP2TCRHWMZIAMGUQH2TNKQNCOGJ7GC3ZOL" == transaction.withdrawAnchorAccount);
    assert("186384" == transaction.withdrawMemo);
    assert("id" == transaction.withdrawMemoType);
    assert("10" == transaction.refunds!.amountRefunded);
    assert("5" == transaction.refunds!.amountFee);
    List<RefundPayment> refundPayments = transaction.refunds!.payments;
    assert(refundPayments.length == 1);
    RefundPayment refundPayment = refundPayments.first;
    assert("b9d0b2292c4e09e8eb22d036171491e87b8d2086bf8b265874c8d182cb9c9020" == refundPayment.id);
    assert("stellar" == refundPayment.idType);
    assert("10" == refundPayment.amount);
    assert("5" == refundPayment.fee);
  });

  test('test empty transactions result', () async {
    final transferService = TransferServerSEP24Service(serviceAddress);
    transferService.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      if (request.url.toString().startsWith(serviceAddress) &&
          request.method == "GET" &&
          request.url.toString().contains("transactions") &&
          authHeader.contains(jwtToken)) {
        return http.Response(requestEmptyTransactions(), 200);
      }

      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    SEP24TransactionsRequest request = SEP24TransactionsRequest();
    request.assetCode = "ETH";
    request.jwt = jwtToken;

    SEP24TransactionsResponse response = await transferService.transactions(request);
    List<SEP24Transaction> transactions = response.transactions;
    assert(transactions.length == 0);
  });

  test('test not found transaction', () async {
    final transferService = TransferServerSEP24Service(serviceAddress);
    transferService.httpClient = MockClient((request) async {
      final mapJson = {'error': "not found"};
      return http.Response(json.encode(mapJson), 404);
    });

    SEP24TransactionRequest request = SEP24TransactionRequest();
    request.stellarTransactionId = "17a670bc424ff5ce3b386dbfaae9990b66a2a37b4fbe51547e8794962a3f9e6a";
    request.jwt = jwtToken;

    bool thrown = false;
    try {
      await transferService.transaction(request);
    } catch(e) {
      if (e is SEP24TransactionNotFoundException) {
        thrown = true;
      }
    }
    assert(thrown);
  });

  test('test forbidden', () async {
    final transferService = TransferServerSEP24Service(serviceAddress);
    transferService.httpClient = MockClient((request) async {
      final mapJson = {"type": "authentication_required"};
      return http.Response(json.encode(mapJson), 403);
    });


    bool thrown = false;
    try {
      SEP24FeeRequest feeRequest = SEP24FeeRequest();
      feeRequest.operation = "deposit";
      feeRequest.type = "SEPA";
      feeRequest.assetCode = "ETH";
      feeRequest.amount = 2034.09;
      feeRequest.jwt = jwtToken;

      await transferService.fee(feeRequest);
    } catch(e) {
      if (e is SEP24AuthenticationRequiredException) {
        thrown = true;
      }
    }

    assert(thrown);
    thrown = false;
    try {
      SEP24DepositRequest request = new SEP24DepositRequest();
      request.assetCode = "USD";
      request.jwt = jwtToken;
      await transferService.deposit(request);
    } catch(e) {
      if (e is SEP24AuthenticationRequiredException) {
        thrown = true;
      }
    }
    assert(thrown);

    thrown = false;
    try {
      SEP24WithdrawRequest request = new SEP24WithdrawRequest();
      request.assetCode = "USD";
      request.jwt = jwtToken;

      await transferService.withdraw(request);
    } catch(e) {
      if (e is SEP24AuthenticationRequiredException) {
        thrown = true;
      }
    }
    assert(thrown);

    thrown = false;
    try {
      SEP24TransactionRequest request = SEP24TransactionRequest();
      request.stellarTransactionId = "17a670bc424ff5ce3b386dbfaae9990b66a2a37b4fbe51547e8794962a3f9e6a";
      request.jwt = jwtToken;
      await transferService.transaction(request);
    } catch(e) {
      if (e is SEP24AuthenticationRequiredException) {
        thrown = true;
      }
    }
    assert(thrown);

    thrown = false;
    try {
      SEP24TransactionRequest request = SEP24TransactionRequest();
      request.stellarTransactionId = "17a670bc424ff5ce3b386dbfaae9990b66a2a37b4fbe51547e8794962a3f9e6a";
      request.jwt = jwtToken;
      await transferService.transaction(request);
    } catch(e) {
      if (e is SEP24AuthenticationRequiredException) {
        thrown = true;
      }
    }
    assert(thrown);
  });

  test('test request error', () async {
    final transferService = TransferServerSEP24Service(serviceAddress);
    transferService.httpClient = MockClient((request) async {
      final mapJson = {"error": "This anchor doesn't support the given currency code: ETH"};
      return http.Response(json.encode(mapJson), 400);
    });


    bool thrown = false;
    try {
      SEP24FeeRequest feeRequest = SEP24FeeRequest();
      feeRequest.operation = "deposit";
      feeRequest.type = "SEPA";
      feeRequest.assetCode = "ETH";
      feeRequest.amount = 2034.09;
      feeRequest.jwt = jwtToken;

      await transferService.fee(feeRequest);
    } catch(e) {
      if (e is RequestErrorException) {
        thrown = true;
      }
    }

    assert(thrown);
    thrown = false;
    try {
      SEP24DepositRequest request = new SEP24DepositRequest();
      request.assetCode = "USD";
      request.jwt = jwtToken;
      await transferService.deposit(request);
    } catch(e) {
      if (e is RequestErrorException) {
        thrown = true;
      }
    }
    assert(thrown);

    thrown = false;
    try {
      SEP24WithdrawRequest request = new SEP24WithdrawRequest();
      request.assetCode = "USD";
      request.jwt = jwtToken;

      await transferService.withdraw(request);
    } catch(e) {
      if (e is RequestErrorException) {
        thrown = true;
      }
    }
    assert(thrown);

    thrown = false;
    try {
      SEP24TransactionRequest request = SEP24TransactionRequest();
      request.stellarTransactionId = "17a670bc424ff5ce3b386dbfaae9990b66a2a37b4fbe51547e8794962a3f9e6a";
      request.jwt = jwtToken;
      await transferService.transaction(request);
    } catch(e) {
      if (e is RequestErrorException) {
        thrown = true;
      }
    }
    assert(thrown);

    thrown = false;
    try {
      SEP24TransactionRequest request = SEP24TransactionRequest();
      request.stellarTransactionId = "17a670bc424ff5ce3b386dbfaae9990b66a2a37b4fbe51547e8794962a3f9e6a";
      request.jwt = jwtToken;
      await transferService.transaction(request);
    } catch(e) {
      if (e is RequestErrorException) {
        thrown = true;
      }
    }
    assert(thrown);
  });
}

