@Timeout(const Duration(seconds: 400))
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

  String requestInfo() {
    return "{\"deposit\": {  \"USD\": {    \"enabled\": true,    \"authentication_required\": true,    \"fee_fixed\": 5,    \"fee_percent\": 1,    \"min_amount\": 0.1,    \"max_amount\": 1000,    \"fields\": {      \"email_address\" : {        \"description\": \"your email address for transaction status updates\",        \"optional\": true      },      \"amount\" : {        \"description\": \"amount in USD that you plan to deposit\"      },      \"country_code\": {        \"description\": \"The ISO 3166-1 alpha-3 code of the user's current address\",        \"choices\": [\"USA\", \"PRI\"]      },      \"type\" : {        \"description\": \"type of deposit to make\",        \"choices\": [\"SEPA\", \"SWIFT\", \"cash\"]      }    }  },  \"ETH\": {    \"enabled\": true,    \"authentication_required\": false,    \"fee_fixed\": 0.002,    \"fee_percent\": 0  }},\"withdraw\": {  \"USD\": {    \"enabled\": true,    \"authentication_required\": true,    \"fee_fixed\": 5,    \"fee_percent\": 0,    \"min_amount\": 0.1,    \"max_amount\": 1000,    \"types\": {      \"bank_account\": {        \"fields\": {            \"dest\": {\"description\": \"your bank account number\" },            \"dest_extra\": { \"description\": \"your routing number\" },            \"bank_branch\": { \"description\": \"address of your bank branch\" },            \"phone_number\": { \"description\": \"your phone number in case there's an issue\" },            \"country_code\": {               \"description\": \"The ISO 3166-1 alpha-3 code of the user's current address\",              \"choices\": [\"USA\", \"PRI\"]            }        }      },      \"cash\": {        \"fields\": {          \"dest\": {             \"description\": \"your email address. Your cashout PIN will be sent here. If not provided, your account's default email will be used\",            \"optional\": true          }        }      }    }  },  \"ETH\": {    \"enabled\": false  }},\"fee\": {  \"enabled\": false},\"transactions\": {  \"enabled\": true,   \"authentication_required\": true},\"transaction\": {  \"enabled\": false,  \"authentication_required\": true}}";
  }

  String requestFee() {
    return "{\"fee\": 0.013}";
  }

  String requestBTCDeposit() {
    return "{\"how\" : \"1Nh7uHdvY6fNwtQtM1G5EZAFPLC33B59rB\",\"id\": \"9421871e-0623-4356-b7b5-5996da122f3e\",\"fee_fixed\" : 0.0002}";
  }

  String requestRippleDeposit() {
    return "{\"how\" : \"Ripple address: rNXEkKCxvfLcM1h4HJkaj2FtmYuAWrHGbf tag: 88\",\"id\": \"9421871e-0623-4356-b7b5-5996da122f3e\",\"eta\": 60,\"fee_percent\" : 0.1,\"extra_info\": {  \"message\": \"You must include the tag. If the amount is more than 1000 XRP, deposit will take 24h to complete.\"}}";
  }

  String requestMXNDeposit() {
    return "{\"how\" : \"Make a payment to Bank: STP Account: 646180111803859359\",\"id\": \"9421871e-0623-4356-b7b5-5996da122f3e\",\"eta\": 1800}";
  }

  String requestWithdrawSuccess() {
    return "{\"account_id\": \"GCIBUCGPOHWMMMFPFTDWBSVHQRT4DIBJ7AD6BZJYDITBK2LCVBYW7HUQ\",\"memo_type\": \"id\",\"memo\": \"123\",\"id\": \"9421871e-0623-4356-b7b5-5996da122f3e\"}";
  }

  String requestCustomerInformationNeeded() {
    return "{\"type\": \"non_interactive_customer_info_needed\",\"fields\" : [\"family_name\", \"given_name\", \"address\", \"tax_id\"]}";
  }

  String requestCustomerInformationStatus() {
    return "{\"type\": \"customer_info_status\",\"status\": \"denied\",\"more_info_url\": \"https:\/\/api.example.com\/kycstatus?account=GACW7NONV43MZIFHCOKCQJAKSJSISSICFVUJ2C6EZIW5773OU3HD64VI\"}";
  }

  String requestTransactions() {
    return "{\"transactions\": [  {    \"id\": \"82fhs729f63dh0v4\",    \"kind\": \"deposit\",    \"status\": \"pending_external\",    \"status_eta\": 3600,    \"external_transaction_id\": \"2dd16cb409513026fbe7defc0c6f826c2d2c65c3da993f747d09bf7dafd31093\",    \"amount_in\": \"18.34\",    \"amount_out\": \"18.24\",    \"amount_fee\": \"0.1\",    \"started_at\": \"2017-03-20T17:05:32Z\"  },  {    \"id\": \"82fhs729f63dh0v4\",    \"kind\": \"withdrawal\",    \"status\": \"completed\",    \"amount_in\": \"500\",    \"amount_out\": \"495\",    \"amount_fee\": \"3\",    \"started_at\": \"2017-03-20T17:00:02Z\",    \"completed_at\": \"2017-03-20T17:09:58Z\",    \"stellar_transaction_id\": \"17a670bc424ff5ce3b386dbfaae9990b66a2a37b4fbe51547e8794962a3f9e6a\",    \"external_transaction_id\": \"2dd16cb409513026fbe7defc0c6f826c2d2c65c3da993f747d09bf7dafd31093\"  },  {    \"id\": \"52fys79f63dh3v1\",    \"kind\": \"withdrawal\",    \"status\": \"pending_transaction_info_update\",    \"amount_in\": \"750.00\",    \"amount_out\": null,    \"amount_fee\": null,    \"started_at\": \"2017-03-20T17:00:02Z\",    \"required_info_message\": \"We were unable to send funds to the provided bank account. Bank error: 'Account does not exist'. Please provide the correct bank account address.\",    \"required_info_updates\": {      \"transaction\": {        \"dest\": {\"description\": \"your bank account number\" },        \"dest_extra\": { \"description\": \"your routing number\" }      }    }  }]}";
  }

  String requestTransaction() {
    return "{\"transaction\": {    \"id\": \"82fhs729f63dh0v4\",    \"kind\": \"deposit\",    \"status\": \"pending_external\",    \"status_eta\": 3600,    \"external_transaction_id\": \"2dd16cb409513026fbe7defc0c6f826c2d2c65c3da993f747d09bf7dafd31093\",    \"amount_in\": \"18.34\",    \"amount_out\": \"18.24\",    \"amount_fee\": \"0.1\",    \"started_at\": \"2017-03-20T17:05:32Z\"  }}";
  }

  test('test info', () async {
    final transferService = TransferServerService(serviceAddress);
    transferService.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      if (request.url.toString().startsWith(serviceAddress) &&
          request.method == "GET" &&
          request.url.toString().contains("info") &&
          authHeader.contains(jwtToken)) {
        return http.Response(requestInfo(), 200);
      }

      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    InfoResponse? infoResponse = await transferService.info("en", jwtToken);

    assert(infoResponse != null);
    assert(infoResponse!.depositAssets!.length == 2);
    DepositAsset? depositAssetUSD = infoResponse!.depositAssets!["USD"];
    assert(depositAssetUSD != null);
    assert(depositAssetUSD!.enabled!);
    assert(depositAssetUSD!.authenticationRequired!);
    assert(depositAssetUSD!.feeFixed == 5.0);
    assert(depositAssetUSD!.feePercent == 1.0);
    assert(depositAssetUSD!.minAmount == 0.1);
    assert(depositAssetUSD!.maxAmount == 1000.0);
    Map<String, AnchorField>? dusdfields = depositAssetUSD!.fields;
    assert(dusdfields != null);
    assert(dusdfields!.length == 4);
    AnchorField? emailAddress = dusdfields!["email_address"];
    assert(emailAddress != null);
    assert(emailAddress!.description == "your email address for transaction status updates");
    assert(emailAddress!.optional!);
    assert(dusdfields["country_code"]!.choices!.contains("USA"));
    assert(dusdfields["type"]!.choices!.contains("SWIFT"));

    WithdrawAsset? withdrawAssetUSD = infoResponse.withdrawAssets!["USD"];
    assert(withdrawAssetUSD != null);
    assert(withdrawAssetUSD!.enabled!);
    assert(withdrawAssetUSD!.authenticationRequired!);
    assert(withdrawAssetUSD!.feeFixed == 5.0);
    assert(withdrawAssetUSD!.feePercent == 0);
    assert(withdrawAssetUSD!.minAmount == 0.1);
    assert(withdrawAssetUSD!.maxAmount == 1000.0);

    Map<String, Map<String, AnchorField>?>? types = withdrawAssetUSD!.types;
    assert(types != null);
    assert(types!.length == 2);
    Map<String, AnchorField>? bankAccountFields = types!["bank_account"];
    assert(bankAccountFields != null);
    assert(bankAccountFields!["country_code"]!.choices!.contains("PRI"));
    assert(types["cash"]!["dest"]!.optional!);

    assert(!infoResponse.withdrawAssets!["ETH"]!.enabled!);

    assert(!infoResponse.feeInfo!.enabled!);
    assert(infoResponse.transactionsInfo!.enabled!);
    assert(infoResponse.transactionsInfo!.authenticationRequired!);
    assert(!infoResponse.transactionInfo!.enabled!);
    assert(infoResponse.transactionInfo!.authenticationRequired!);
  });

  test('test fee', () async {
    final transferService = TransferServerService(serviceAddress);
    transferService.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      if (request.url.toString().startsWith(serviceAddress) &&
          request.method == "GET" &&
          request.url.toString().contains("fee") &&
          authHeader.contains(jwtToken)) {
        print(request.url.toString());
        return http.Response(requestFee(), 200);
      }

      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    FeeRequest feeRequest = FeeRequest();
    feeRequest.operation = "deposit";
    feeRequest.type = "SEPA";
    feeRequest.assetCode = "ETH";
    feeRequest.amount = 2034.09;
    feeRequest.jwt = jwtToken;

    FeeResponse? feeResponse = await transferService.fee(feeRequest);

    assert(feeResponse != null);
    assert(feeResponse!.fee == 0.013);
  });

  test('test deposit btc success', () async {
    final transferService = TransferServerService(serviceAddress);
    transferService.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      if (request.url.toString().startsWith(serviceAddress) &&
          request.method == "GET" &&
          request.url.toString().contains("deposit") &&
          authHeader.contains(jwtToken)) {
        print(request.url.toString());
        return http.Response(requestBTCDeposit(), 200);
      }

      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    DepositRequest depositRequest = DepositRequest();
    depositRequest.assetCode = "BTC";
    depositRequest.account = accountId;
    depositRequest.amount = "3.123";
    depositRequest.jwt = jwtToken;

    DepositResponse? depositResponse = await transferService.deposit(depositRequest);

    assert(depositResponse != null);
    assert(depositResponse!.how == "1Nh7uHdvY6fNwtQtM1G5EZAFPLC33B59rB");
    assert(depositResponse!.id == "9421871e-0623-4356-b7b5-5996da122f3e");
    assert(depositResponse!.feeFixed == 0.0002);
  });

  test('test deposit ripple success', () async {
    final transferService = TransferServerService(serviceAddress);
    transferService.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      if (request.url.toString().startsWith(serviceAddress) &&
          request.method == "GET" &&
          request.url.toString().contains("deposit") &&
          authHeader.contains(jwtToken)) {
        print(request.url.toString());
        return http.Response(requestRippleDeposit(), 200);
      }

      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    DepositRequest depositRequest = DepositRequest();
    depositRequest.assetCode = "XRP";
    depositRequest.account = accountId;
    depositRequest.amount = "300.0";
    depositRequest.jwt = jwtToken;

    DepositResponse? depositResponse = await transferService.deposit(depositRequest);

    assert(depositResponse != null);
    assert(depositResponse!.how == "Ripple address: rNXEkKCxvfLcM1h4HJkaj2FtmYuAWrHGbf tag: 88");
    assert(depositResponse!.id == "9421871e-0623-4356-b7b5-5996da122f3e");
    assert(depositResponse!.eta == 60);
    assert(depositResponse!.feePercent == 0.1);
    assert(depositResponse!.extraInfo!.message ==
        "You must include the tag. If the amount is more than 1000 XRP, deposit will take 24h to complete.");
  });

  test('test deposit MXN success', () async {
    final transferService = TransferServerService(serviceAddress);
    transferService.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      if (request.url.toString().startsWith(serviceAddress) &&
          request.method == "GET" &&
          request.url.toString().contains("deposit") &&
          authHeader.contains(jwtToken)) {
        print(request.url.toString());
        return http.Response(requestMXNDeposit(), 200);
      }

      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    DepositRequest depositRequest = DepositRequest();
    depositRequest.assetCode = "MXN";
    depositRequest.account = accountId;
    depositRequest.amount = "120.0";
    depositRequest.jwt = jwtToken;

    DepositResponse? depositResponse = await transferService.deposit(depositRequest);

    assert(depositResponse != null);
    assert(depositResponse!.how == "Make a payment to Bank: STP Account: 646180111803859359");
    assert(depositResponse!.id == "9421871e-0623-4356-b7b5-5996da122f3e");
    assert(depositResponse!.eta == 1800);
  });

  test('test withdraw success', () async {
    final transferService = TransferServerService(serviceAddress);
    transferService.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      if (request.url.toString().startsWith(serviceAddress) &&
          request.method == "GET" &&
          request.url.toString().contains("withdraw") &&
          authHeader.contains(jwtToken)) {
        print(request.url.toString());
        return http.Response(requestWithdrawSuccess(), 200);
      }

      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    WithdrawRequest withdrawRequest = WithdrawRequest();
    withdrawRequest.assetCode = "XLM";
    withdrawRequest.type = "crypto";
    withdrawRequest.dest = "GCTTGO5ABSTHABXWL2FMHPZ2XFOZDXJYJN5CKFRKXMPAAWZW3Y3JZ3JK";
    withdrawRequest.account = accountId;
    withdrawRequest.amount = "120.0";
    withdrawRequest.jwt = jwtToken;

    WithdrawResponse? withdrawResponse = await transferService.withdraw(withdrawRequest);

    assert(withdrawResponse != null);
    assert(
        withdrawResponse!.accountId == "GCIBUCGPOHWMMMFPFTDWBSVHQRT4DIBJ7AD6BZJYDITBK2LCVBYW7HUQ");
    assert(withdrawResponse!.memoType == "id");
    assert(withdrawResponse!.memo == "123");
    assert(withdrawResponse!.id == "9421871e-0623-4356-b7b5-5996da122f3e");
  });

  test('test deposit customer information needed', () async {
    final transferService = TransferServerService(serviceAddress);
    transferService.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      if (request.url.toString().startsWith(serviceAddress) &&
          request.method == "GET" &&
          request.url.toString().contains("deposit") &&
          authHeader.contains(jwtToken)) {
        print(request.url.toString());
        return http.Response(requestCustomerInformationNeeded(), 403);
      }

      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    DepositRequest depositRequest = DepositRequest();
    depositRequest.assetCode = "MXN";
    depositRequest.account = accountId;
    depositRequest.amount = "120.0";
    depositRequest.jwt = jwtToken;

    bool thrown = false;
    try {
      await transferService.deposit(depositRequest);
    } on CustomerInformationNeededException catch (e) {
      thrown = true;
      assert(e.response.fields!.contains("tax_id"));
    }
    assert(thrown);
  });

  test('test withdraw customer information needed', () async {
    final transferService = TransferServerService(serviceAddress);
    transferService.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      if (request.url.toString().startsWith(serviceAddress) &&
          request.method == "GET" &&
          request.url.toString().contains("withdraw") &&
          authHeader.contains(jwtToken)) {
        print(request.url.toString());
        return http.Response(requestCustomerInformationNeeded(), 403);
      }

      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    WithdrawRequest withdrawRequest = WithdrawRequest();
    withdrawRequest.assetCode = "XLM";
    withdrawRequest.type = "crypto";
    withdrawRequest.dest = "GCTTGO5ABSTHABXWL2FMHPZ2XFOZDXJYJN5CKFRKXMPAAWZW3Y3JZ3JK";
    withdrawRequest.account = accountId;
    withdrawRequest.amount = "120.0";
    withdrawRequest.jwt = jwtToken;

    bool thrown = false;
    try {
      await transferService.withdraw(withdrawRequest);
    } on CustomerInformationNeededException catch (e) {
      thrown = true;
      assert(e.response.fields!.contains("tax_id"));
    }
    assert(thrown);
  });

  test('test deposit customer information status', () async {
    final transferService = TransferServerService(serviceAddress);
    transferService.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      if (request.url.toString().startsWith(serviceAddress) &&
          request.method == "GET" &&
          request.url.toString().contains("deposit") &&
          authHeader.contains(jwtToken)) {
        print(request.url.toString());
        return http.Response(requestCustomerInformationStatus(), 403);
      }

      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    DepositRequest depositRequest = DepositRequest();
    depositRequest.assetCode = "MXN";
    depositRequest.account = accountId;
    depositRequest.amount = "120.0";
    depositRequest.jwt = jwtToken;

    bool thrown = false;
    try {
      await transferService.deposit(depositRequest);
    } on CustomerInformationStatusException catch (e) {
      thrown = true;
      assert(e.response.status == "denied");
      assert(e.response.moreInfoUrl ==
          "https://api.example.com/kycstatus?account=GACW7NONV43MZIFHCOKCQJAKSJSISSICFVUJ2C6EZIW5773OU3HD64VI");
    }
    assert(thrown);
  });

  test('test get transactions', () async {
    final transferService = TransferServerService(serviceAddress);
    transferService.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      if (request.url.toString().startsWith(serviceAddress) &&
          request.method == "GET" &&
          request.url.toString().contains("transactions") &&
          authHeader.contains(jwtToken)) {
        print(request.url.toString());
        return http.Response(requestTransactions(), 200);
      }

      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    AnchorTransactionsRequest request = AnchorTransactionsRequest();
    request.assetCode = "XLM";
    request.account = "GCTTGO5ABSTHABXWL2FMHPZ2XFOZDXJYJN5CKFRKXMPAAWZW3Y3JZ3JK";
    request.jwt = jwtToken;

    AnchorTransactionsResponse? response = await transferService.transactions(request);

    assert(response != null);
    assert(response!.transactions!.length == 3);
    assert(response!.transactions!.first!.id == "82fhs729f63dh0v4");
    assert(response!.transactions!.first!.kind == "deposit");
    assert(response!.transactions!.first!.status == "pending_external");
    assert(response!.transactions!.first!.statusEta == 3600);
    assert(response!.transactions!.first!.externalTransactionId ==
        "2dd16cb409513026fbe7defc0c6f826c2d2c65c3da993f747d09bf7dafd31093");
    assert(response!.transactions!.first!.amountIn == "18.34");
    assert(response!.transactions!.first!.amountOut == "18.24");
    assert(response!.transactions!.first!.amountFee == "0.1");
    assert(response!.transactions!.first!.startedAt == "2017-03-20T17:05:32Z");

    assert(response!.transactions!.last!.requiredInfoMessage ==
        "We were unable to send funds to the provided bank account. Bank error: 'Account does not exist'. Please provide the correct bank account address.");
    assert(response!.transactions!.last!.requiredInfoUpdates!["dest"]!.description ==
        "your bank account number");
  });

  test('test get transaction', () async {
    final transferService = TransferServerService(serviceAddress);
    transferService.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      if (request.url.toString().startsWith(serviceAddress) &&
          request.method == "GET" &&
          request.url.toString().contains("transaction") &&
          authHeader.contains(jwtToken)) {
        print(request.url.toString());
        return http.Response(requestTransaction(), 200);
      }

      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    AnchorTransactionRequest request = AnchorTransactionRequest();
    request.id = "82fhs729f63dh0v4";
    request.stallarTransactionId =
        "17a670bc424ff5ce3b386dbfaae9990b66a2a37b4fbe51547e8794962a3f9e6a";
    request.jwt = jwtToken;

    AnchorTransactionResponse? response = await transferService.transaction(request);

    assert(response != null);
    assert(response!.transaction != null);
    assert(response!.transaction!.id == "82fhs729f63dh0v4");
    assert(response!.transaction!.kind == "deposit");
    assert(response!.transaction!.status == "pending_external");
    assert(response!.transaction!.statusEta == 3600);
    assert(response!.transaction!.externalTransactionId ==
        "2dd16cb409513026fbe7defc0c6f826c2d2c65c3da993f747d09bf7dafd31093");
    assert(response!.transaction!.amountIn == "18.34");
    assert(response!.transaction!.amountOut == "18.24");
    assert(response!.transaction!.amountFee == "0.1");
    assert(response!.transaction!.startedAt == "2017-03-20T17:05:32Z");
  });

  test('test patch transaction', () async {
    final transferService = TransferServerService(serviceAddress);
    transferService.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      if (request.url.toString().startsWith(serviceAddress) &&
          request.method == "PATCH" &&
          request.url.toString().contains("transactions/82fhs729f63dh0v4") &&
          authHeader.contains(jwtToken)) {
        print(request.url.toString());
        return http.Response("", 200);
      }

      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    PatchTransactionRequest request = PatchTransactionRequest();
    request.id = "82fhs729f63dh0v4";
    request.fields = {};
    request.fields!["dest"] = "12345678901234";
    request.fields!["dest_extra"] = "021000021";
    request.jwt = jwtToken;

    http.Response? response = await transferService.patchTransaction(request);

    assert(response != null);
    assert(response!.statusCode == 200);
  });
}
