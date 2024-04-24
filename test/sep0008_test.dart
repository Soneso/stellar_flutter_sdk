@Timeout(const Duration(seconds: 400))
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  String anchorDomain = 'api.anchor.org';
  String anchorToml = '''
      # Sample stellar.toml
      VERSION="2.0.0"
      
      NETWORK_PASSPHRASE="Test SDF Network ; September 2015"
      WEB_AUTH_ENDPOINT="https://api.anchor.org/auth"
      TRANSFER_SERVER_SEP0024="http://api.stellar.org/transfer-sep24/"
      ANCHOR_QUOTE_SERVER="http://api.stellar.org/quotes-sep38/"
      SIGNING_KEY="GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP"
      
      [[CURRENCIES]]
      code="GOAT"
      regulated=true
      approval_server="https://goat.io/tx_approve"
      approval_criteria="The goat approval server will ensure that transactions are compliant with NFO regulation"
      
      [[CURRENCIES]]
      code="NOP"
      issuer="GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP"
      display_decimals=2
      
      [[CURRENCIES]]
      code="JACK"
      regulated=true
      approval_server="https://jack.io/tx_approve"
      approval_criteria="The jack approval server will ensure that transactions are compliant with NFO regulation"
     ''';

  StellarSDK sdk = StellarSDK.TESTNET;
  Network network = Network.TESTNET;
  KeyPair asset1IssuerKp = KeyPair.random();
  KeyPair asset2IssuerKp = KeyPair.random();
  KeyPair accountAKp = KeyPair.random();
  StellarToml toml = StellarToml(anchorToml);

  setUp(() async {
    await FriendBot.fundTestAccount(asset1IssuerKp.accountId);
    print("funded Issuer 1: " + asset1IssuerKp.accountId);
    await FriendBot.fundTestAccount(asset2IssuerKp.accountId);
    print("funded Issuer 2: " + asset2IssuerKp.accountId);
    await FriendBot.fundTestAccount(accountAKp.accountId);
    print("funded Account A: " + accountAKp.accountId);

    var sourceAccountId = asset1IssuerKp.accountId;
    AccountResponse sourceAccount = await sdk.accounts.account(sourceAccountId);
    int flagsVal = AccountFlag.AUTH_REQUIRED_FLAG.value |
        AccountFlag.AUTH_REVOCABLE_FLAG.value;
    SetOptionsOperation so1 =
        SetOptionsOperationBuilder().setSetFlags(flagsVal).build();
    Transaction transaction =
        TransactionBuilder(sourceAccount).addOperation(so1).build();
    transaction.sign(asset1IssuerKp, network);
    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    assert(response.success);

    toml.currencies?.first.issuer = asset1IssuerKp.accountId;
    toml.currencies?.last.issuer = asset2IssuerKp.accountId;
  });

  test('test all', () async {
    var service = RegulatedAssetsService(toml);

    var regulatedAssets = service.regulatedAssets;
    assert(regulatedAssets.length == 2);
    var goatAsset = regulatedAssets.first;
    var authRequired = await service.authorizationRequired(goatAsset);
    assert(authRequired);
    assert(goatAsset.approvalServer == 'https://goat.io/tx_approve');
    assert(goatAsset.approvalCriteria ==
        'The goat approval server will ensure that transactions are compliant with NFO regulation');

    var jackAsset = regulatedAssets.last;
    authRequired = await service.authorizationRequired(jackAsset);
    assert(!authRequired);
    assert(jackAsset.approvalServer == 'https://jack.io/tx_approve');
    assert(jackAsset.approvalCriteria ==
        'The jack approval server will ensure that transactions are compliant with NFO regulation');

    assert(
        service.network.networkPassphrase == Network.TESTNET.networkPassphrase);

    http.Client anchorMock = MockClient((request) async {
      if (request.url.toString().contains(anchorDomain) &&
          request.url.toString().contains("stellar.toml")) {
        return http.Response(anchorToml, 200);
      }

      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    service = await RegulatedAssetsService.fromDomain(anchorDomain,
        httpClient: anchorMock);
    assert(
        service.network.networkPassphrase == Network.TESTNET.networkPassphrase);
    regulatedAssets = service.regulatedAssets;
    assert(regulatedAssets.length == 0);

    // post tx success
    anchorMock = MockClient((request) async {
      if (request.url.toString().contains('goat') && request.method == "POST") {
        var tx = json.decode(request.body)["tx"];
        assert(tx != null);

        var result = {'status': 'success', 'tx': tx, 'message': 'hello'};
        return http.Response(jsonEncode(result), 200); // OK
      }

      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    var accountAId = accountAKp.accountId;
    var accountA = await service.sdk.accounts.account(accountAId);

    // Operation 1: AllowTrust op where issuer fully authorizes account A, asset X
    var op1 = SetTrustLineFlagsOperationBuilder(
            accountAId, goatAsset, 0, XdrTrustLineFlags.AUTHORIZED_FLAG.value)
        .setSourceAccount(goatAsset.issuerId)
        .build();

    // Operation 2: Account A manages offer to buy asset X
    var op2 =
        ManageBuyOfferOperationBuilder(Asset.NATIVE, goatAsset, '10', '0.1')
            .build();

    // Operation 3: AllowTrust op where issuer sets account A, asset X to AUTHORIZED_TO_MAINTAIN_LIABILITIES_FLAG state
    var op3 = SetTrustLineFlagsOperationBuilder(accountAId, goatAsset, 0,
            XdrTrustLineFlags.AUTHORIZED_TO_MAINTAIN_LIABILITIES_FLAG.value)
        .setSourceAccount(goatAsset.issuerId)
        .build();

    var tx = TransactionBuilder(accountA)
        .addOperation(op1)
        .addOperation(op2)
        .addOperation(op3)
        .build();
    String testTx = tx.toXdrBase64();

    service = RegulatedAssetsService(toml, httpClient: anchorMock);
    goatAsset = service.regulatedAssets.first;
    var postResponse =
        await service.postTransaction(testTx, goatAsset.approvalServer);
    assert(postResponse is PostTransactionSuccess);
    postResponse = postResponse as PostTransactionSuccess;
    assert(postResponse.tx == testTx);
    assert(postResponse.message == 'hello');

    // post tx revised
    anchorMock = MockClient((request) async {
      if (request.url.toString().contains('goat') && request.method == "POST") {
        var tx = json.decode(request.body)["tx"];
        assert(tx != null);

        var result = {'status': 'revised', 'tx': tx + tx, 'message': 'hello'};
        return http.Response(jsonEncode(result), 200); // OK
      }

      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    service = RegulatedAssetsService(toml, httpClient: anchorMock);
    goatAsset = service.regulatedAssets.first;
    postResponse =
        await service.postTransaction(testTx, goatAsset.approvalServer);
    assert(postResponse is PostTransactionRevised);
    postResponse = postResponse as PostTransactionRevised;
    assert(postResponse.tx == testTx + testTx);
    assert(postResponse.message == 'hello');

    // post tx pending
    anchorMock = MockClient((request) async {
      if (request.url.toString().contains('goat') && request.method == "POST") {
        var tx = json.decode(request.body)["tx"];
        assert(tx != null);

        var result = {'status': 'pending', 'timeout': 3, 'message': 'hello'};
        return http.Response(jsonEncode(result), 200); // OK
      }

      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    service = RegulatedAssetsService(toml, httpClient: anchorMock);
    goatAsset = service.regulatedAssets.first;
    postResponse =
        await service.postTransaction(testTx, goatAsset.approvalServer);
    assert(postResponse is PostTransactionPending);
    postResponse = postResponse as PostTransactionPending;
    assert(postResponse.timeout == 3);
    assert(postResponse.message == 'hello');

    // post tx rejected
    anchorMock = MockClient((request) async {
      if (request.url.toString().contains('goat') && request.method == "POST") {
        var tx = json.decode(request.body)["tx"];
        assert(tx != null);

        var result = {'status': 'rejected', 'error': 'hello'};
        return http.Response(jsonEncode(result), 400);
      }

      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    service = RegulatedAssetsService(toml, httpClient: anchorMock);
    goatAsset = service.regulatedAssets.first;
    postResponse =
        await service.postTransaction(testTx, goatAsset.approvalServer);
    assert(postResponse is PostTransactionRejected);
    postResponse = postResponse as PostTransactionRejected;
    assert(postResponse.error == 'hello');

    String actionUrl = 'https://goat.io/action';

    // post tx action required
    anchorMock = MockClient((request) async {
      if (request.url.toString().contains('goat') && request.method == "POST") {
        var tx = json.decode(request.body)["tx"];
        assert(tx != null);

        var result = {
          'status': 'action_required',
          'message': 'hello',
          'action_url': actionUrl,
          'action_method': 'POST',
          'action_fields': ['email_address', 'mobile_number']
        };
        return http.Response(jsonEncode(result), 200); // OK
      }

      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    service = RegulatedAssetsService(toml, httpClient: anchorMock);
    goatAsset = service.regulatedAssets.first;
    postResponse =
        await service.postTransaction(testTx, goatAsset.approvalServer);
    assert(postResponse is PostTransactionActionRequired);
    postResponse = postResponse as PostTransactionActionRequired;
    assert(postResponse.message == 'hello');
    assert(postResponse.actionUrl == actionUrl);
    assert(postResponse.actionMethod == 'POST');
    assert(postResponse.actionFields!.contains('email_address'));
    assert(postResponse.actionFields!.contains('mobile_number'));

    // post action done
    anchorMock = MockClient((request) async {
      if (request.url.toString().contains(actionUrl) &&
          request.method == "POST") {
        var email = json.decode(request.body)["email_address"];
        assert(email == 'test@mail.com');
        var mobile = json.decode(request.body)["mobile_number"];
        assert(mobile == '+3472829839222');

        var result = {"result": "no_further_action_required"};
        return http.Response(jsonEncode(result), 200); // OK
      }

      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    service.httpClient = anchorMock;
    var actionResponse = await service.postAction(actionUrl,
        {'email_address': 'test@mail.com', 'mobile_number': '+3472829839222'});

    assert(actionResponse is PostActionDone);

    // post action next
    anchorMock = MockClient((request) async {
      if (request.url.toString().contains(actionUrl) &&
          request.method == "POST") {
        var result = {
          "result": "follow_next_url",
          "next_url": actionUrl,
          "message": "Please submit mobile number"
        };
        return http.Response(jsonEncode(result), 200); // OK
      }

      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    service.httpClient = anchorMock;
    actionResponse =
        await service.postAction(actionUrl, {'email_address': 'test@mail.com'});
    assert(actionResponse is PostActionNextUrl);
    actionResponse = actionResponse as PostActionNextUrl;
    assert(actionResponse.nextUrl == actionUrl);
    assert(actionResponse.message == "Please submit mobile number");
  });
}
