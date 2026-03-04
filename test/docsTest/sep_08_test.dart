@Timeout(const Duration(seconds: 300))

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  StellarSDK sdk = StellarSDK.TESTNET;
  Network network = Network.TESTNET;

  String anchorDomain = 'regulated-asset-issuer.com';
  String anchorToml = '''
      VERSION="2.0.0"

      NETWORK_PASSPHRASE="Test SDF Network ; September 2015"

      [[CURRENCIES]]
      code="GOAT"
      regulated=true
      approval_server="https://goat.io/tx_approve"
      approval_criteria="The goat approval server will ensure that transactions are compliant with regulation"
     ''';

  late KeyPair issuerKp;
  late KeyPair senderKp;
  late KeyPair destinationKp;
  late StellarToml toml;
  late String testTxXdr;

  setUp(() async {
    issuerKp = KeyPair.random();
    senderKp = KeyPair.random();
    destinationKp = KeyPair.random();

    await FriendBot.fundTestAccount(issuerKp.accountId);
    await FriendBot.fundTestAccount(senderKp.accountId);
    await FriendBot.fundTestAccount(destinationKp.accountId);

    // Set AUTH_REQUIRED and AUTH_REVOCABLE flags on issuer account
    AccountResponse issuerAccount =
        await sdk.accounts.account(issuerKp.accountId);
    int flagsVal = AccountFlag.AUTH_REQUIRED_FLAG.value |
        AccountFlag.AUTH_REVOCABLE_FLAG.value;
    SetOptionsOperation setFlagsOp =
        SetOptionsOperationBuilder().setSetFlags(flagsVal).build();
    Transaction flagsTx =
        TransactionBuilder(issuerAccount).addOperation(setFlagsOp).build();
    flagsTx.sign(issuerKp, network);
    SubmitTransactionResponse flagsResponse =
        await sdk.submitTransaction(flagsTx);
    assert(flagsResponse.success);

    // Parse toml and set issuer
    toml = StellarToml(anchorToml);
    toml.currencies?.first.issuer = issuerKp.accountId;

    // Build a test transaction for use in approval tests
    AccountResponse senderAccount =
        await sdk.accounts.account(senderKp.accountId);
    RegulatedAssetsService tempService = RegulatedAssetsService(toml);
    RegulatedAsset goatAsset = tempService.regulatedAssets.first;

    Transaction tx = TransactionBuilder(senderAccount)
        .addOperation(
          PaymentOperationBuilder(destinationKp.accountId, goatAsset, '100')
              .build(),
        )
        .build();
    tx.sign(senderKp, network);
    testTxXdr = tx.toEnvelopeXdrBase64();
  });

  test('sep-08: Quick Start - service creation and asset discovery', () {
    // Snippet from sep-08.md "Quick Start"
    RegulatedAssetsService service = RegulatedAssetsService(toml);

    RegulatedAsset asset = service.regulatedAssets.first;
    expect(asset.code, 'GOAT');
    expect(asset.issuerId, issuerKp.accountId);
    expect(asset.approvalServer, 'https://goat.io/tx_approve');
  });

  test('sep-08: Creating the Service - from StellarToml data', () {
    // Snippet from sep-08.md "From StellarToml data"
    RegulatedAssetsService service = RegulatedAssetsService(toml);

    expect(service.regulatedAssets.length, 1);
    expect(service.network.networkPassphrase, Network.TESTNET.networkPassphrase);
  });

  test('sep-08: Creating the Service - fromDomain with mock', () async {
    // Snippet from sep-08.md "From domain (recommended)"
    http.Client mockClient = MockClient((request) async {
      if (request.url.toString().contains(anchorDomain) &&
          request.url.toString().contains('stellar.toml')) {
        return http.Response(anchorToml, 200);
      }
      return http.Response('Not found', 404);
    });

    RegulatedAssetsService service = await RegulatedAssetsService.fromDomain(
      anchorDomain,
      httpClient: mockClient,
    );

    expect(service.network.networkPassphrase, Network.TESTNET.networkPassphrase);
    // Note: assets from fromDomain won't have issuers matching our test accounts
    // because the toml returned by mock has no issuer set for GOAT
  });

  test('sep-08: Creating the Service - with custom HTTP client', () async {
    // Snippet from sep-08.md "With custom HTTP client"
    http.Client client = MockClient((request) async {
      if (request.url.toString().contains(anchorDomain) &&
          request.url.toString().contains('stellar.toml')) {
        return http.Response(anchorToml, 200);
      }
      return http.Response('Not found', 404);
    });

    RegulatedAssetsService service = await RegulatedAssetsService.fromDomain(
      anchorDomain,
      httpClient: client,
      httpRequestHeaders: {'User-Agent': 'MyWallet/1.0'},
    );

    expect(service.regulatedAssets, isNotNull);
  });

  test('sep-08: RegulatedAsset - properties', () {
    // Snippet from sep-08.md "RegulatedAsset"
    RegulatedAssetsService service = RegulatedAssetsService(toml);

    for (RegulatedAsset asset in service.regulatedAssets) {
      // Inherited from AssetTypeCreditAlphaNum
      expect(asset.code, isNotEmpty);
      expect(asset.issuerId, startsWith('G'));
      expect(asset.type, anyOf('credit_alphanum4', 'credit_alphanum12'));

      // SEP-08 specific fields
      expect(asset.approvalServer, isNotEmpty);
      // approvalCriteria may be null
    }
  });

  test('sep-08: Checking Authorization Flags', () async {
    // Snippet from sep-08.md "Checking Authorization Flags"
    RegulatedAssetsService service = RegulatedAssetsService(toml);
    RegulatedAsset asset = service.regulatedAssets.first;

    bool required = await service.authorizationRequired(asset);

    expect(required, true);
  });

  test('sep-08: postTransaction - success response', () async {
    // Snippet from sep-08.md "Handling All Response Types" - success case
    http.Client mockClient = MockClient((request) async {
      if (request.url.toString().contains('goat') &&
          request.method == 'POST') {
        String tx = json.decode(request.body)['tx'];
        var result = {'status': 'success', 'tx': tx, 'message': 'Approved'};
        return http.Response(jsonEncode(result), 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    RegulatedAssetsService service =
        RegulatedAssetsService(toml, httpClient: mockClient);
    RegulatedAsset goatAsset = service.regulatedAssets.first;

    PostTransactionResponse response =
        await service.postTransaction(testTxXdr, goatAsset.approvalServer);

    expect(response, isA<PostTransactionSuccess>());
    PostTransactionSuccess success = response as PostTransactionSuccess;
    expect(success.tx, testTxXdr);
    expect(success.message, 'Approved');
  });

  test('sep-08: postTransaction - revised response', () async {
    // Snippet from sep-08.md "Handling All Response Types" - revised case
    http.Client mockClient = MockClient((request) async {
      if (request.url.toString().contains('goat') &&
          request.method == 'POST') {
        String tx = json.decode(request.body)['tx'];
        var result = {
          'status': 'revised',
          'tx': tx,
          'message': 'Added authorization operations'
        };
        return http.Response(jsonEncode(result), 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    RegulatedAssetsService service =
        RegulatedAssetsService(toml, httpClient: mockClient);
    RegulatedAsset goatAsset = service.regulatedAssets.first;

    PostTransactionResponse response =
        await service.postTransaction(testTxXdr, goatAsset.approvalServer);

    expect(response, isA<PostTransactionRevised>());
    PostTransactionRevised revised = response as PostTransactionRevised;
    expect(revised.tx, testTxXdr);
    expect(revised.message, 'Added authorization operations');
  });

  test('sep-08: postTransaction - pending response', () async {
    // Snippet from sep-08.md "Handling All Response Types" - pending case
    http.Client mockClient = MockClient((request) async {
      if (request.url.toString().contains('goat') &&
          request.method == 'POST') {
        var result = {
          'status': 'pending',
          'timeout': 5000,
          'message': 'Compliance check in progress'
        };
        return http.Response(jsonEncode(result), 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    RegulatedAssetsService service =
        RegulatedAssetsService(toml, httpClient: mockClient);
    RegulatedAsset goatAsset = service.regulatedAssets.first;

    PostTransactionResponse response =
        await service.postTransaction(testTxXdr, goatAsset.approvalServer);

    expect(response, isA<PostTransactionPending>());
    PostTransactionPending pending = response as PostTransactionPending;
    // timeout is int (milliseconds), defaults to 0 if not provided
    expect(pending.timeout, 5000);
    expect(pending.message, 'Compliance check in progress');
  });

  test('sep-08: postTransaction - action_required response', () async {
    // Snippet from sep-08.md "Handling All Response Types" - action_required case
    String actionUrl = 'https://goat.io/kyc/action';

    http.Client mockClient = MockClient((request) async {
      if (request.url.toString().contains('goat') &&
          request.method == 'POST') {
        var result = {
          'status': 'action_required',
          'message': 'Please provide KYC information',
          'action_url': actionUrl,
          'action_method': 'POST',
          'action_fields': ['email_address', 'mobile_number']
        };
        return http.Response(jsonEncode(result), 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    RegulatedAssetsService service =
        RegulatedAssetsService(toml, httpClient: mockClient);
    RegulatedAsset goatAsset = service.regulatedAssets.first;

    PostTransactionResponse response =
        await service.postTransaction(testTxXdr, goatAsset.approvalServer);

    expect(response, isA<PostTransactionActionRequired>());
    PostTransactionActionRequired actionRequired =
        response as PostTransactionActionRequired;
    expect(actionRequired.message, 'Please provide KYC information');
    expect(actionRequired.actionUrl, actionUrl);
    expect(actionRequired.actionMethod, 'POST');
    expect(actionRequired.actionFields, contains('email_address'));
    expect(actionRequired.actionFields, contains('mobile_number'));
  });

  test('sep-08: postTransaction - rejected response', () async {
    // Snippet from sep-08.md "Handling All Response Types" - rejected case
    http.Client mockClient = MockClient((request) async {
      if (request.url.toString().contains('goat') &&
          request.method == 'POST') {
        var result = {
          'status': 'rejected',
          'error': 'Transaction not compliant with regulations'
        };
        return http.Response(jsonEncode(result), 400);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    RegulatedAssetsService service =
        RegulatedAssetsService(toml, httpClient: mockClient);
    RegulatedAsset goatAsset = service.regulatedAssets.first;

    PostTransactionResponse response =
        await service.postTransaction(testTxXdr, goatAsset.approvalServer);

    expect(response, isA<PostTransactionRejected>());
    PostTransactionRejected rejected = response as PostTransactionRejected;
    expect(rejected.error, 'Transaction not compliant with regulations');
  });

  test('sep-08: postAction - done response', () async {
    // Snippet from sep-08.md "postAction - Handling Action Required" - done case
    String actionUrl = 'https://goat.io/kyc/action';

    http.Client mockClient = MockClient((request) async {
      if (request.url.toString().contains(actionUrl) &&
          request.method == 'POST') {
        String email = json.decode(request.body)['email_address'];
        expect(email, 'user@example.com');
        String mobile = json.decode(request.body)['mobile_number'];
        expect(mobile, '+1234567890');

        var result = {'result': 'no_further_action_required'};
        return http.Response(jsonEncode(result), 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    RegulatedAssetsService service =
        RegulatedAssetsService(toml, httpClient: mockClient);

    PostActionResponse actionResponse = await service.postAction(
      actionUrl,
      {
        'email_address': 'user@example.com',
        'mobile_number': '+1234567890',
      },
    );

    expect(actionResponse, isA<PostActionDone>());
  });

  test('sep-08: postAction - next_url response', () async {
    // Snippet from sep-08.md "postAction - Handling Action Required" - next_url case
    String actionUrl = 'https://goat.io/kyc/action';
    String nextUrl = 'https://goat.io/kyc/next-step';

    http.Client mockClient = MockClient((request) async {
      if (request.url.toString().contains(actionUrl) &&
          request.method == 'POST') {
        var result = {
          'result': 'follow_next_url',
          'next_url': nextUrl,
          'message': 'Please complete verification in browser'
        };
        return http.Response(jsonEncode(result), 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    RegulatedAssetsService service =
        RegulatedAssetsService(toml, httpClient: mockClient);

    PostActionResponse actionResponse = await service.postAction(
      actionUrl,
      {'email_address': 'user@example.com'},
    );

    expect(actionResponse, isA<PostActionNextUrl>());
    PostActionNextUrl nextUrlResponse = actionResponse as PostActionNextUrl;
    expect(nextUrlResponse.nextUrl, nextUrl);
    expect(nextUrlResponse.message, 'Please complete verification in browser');
  });

  test('sep-08: Error handling - IncompleteInitData', () {
    // Snippet from sep-08.md "Error Handling" - IncompleteInitData
    String badToml = '''
      VERSION="2.0.0"

      [[CURRENCIES]]
      code="GOAT"
      regulated=true
      approval_server="https://goat.io/tx_approve"
    ''';

    // Missing NETWORK_PASSPHRASE should throw IncompleteInitData
    expect(
      () => RegulatedAssetsService(StellarToml(badToml)),
      throwsA(isA<IncompleteInitData>()),
    );
  });

  test('sep-08: Error handling - UnknownPostTransactionResponse', () async {
    // Snippet from sep-08.md "Error Handling" - UnknownPostTransactionResponse
    http.Client mockClient = MockClient((request) async {
      // Return 500 which is not 200 or 400
      return http.Response('Internal Server Error', 500);
    });

    RegulatedAssetsService service =
        RegulatedAssetsService(toml, httpClient: mockClient);
    RegulatedAsset goatAsset = service.regulatedAssets.first;

    expect(
      () => service.postTransaction(testTxXdr, goatAsset.approvalServer),
      throwsA(isA<UnknownPostTransactionResponse>()),
    );
  });

  test('sep-08: Error handling - UnknownPostActionResponse', () async {
    // Snippet from sep-08.md "Error Handling" - UnknownPostActionResponse
    http.Client mockClient = MockClient((request) async {
      return http.Response('Internal Server Error', 500);
    });

    RegulatedAssetsService service =
        RegulatedAssetsService(toml, httpClient: mockClient);

    expect(
      () => service.postAction('https://goat.io/action', {'field': 'value'}),
      throwsA(isA<UnknownPostActionResponse>()),
    );
  });

  test('sep-08: Error handling - IssuerAccountNotFound', () async {
    // Snippet from sep-08.md "Error Handling" - IssuerAccountNotFound
    String fakeToml = '''
      VERSION="2.0.0"
      NETWORK_PASSPHRASE="Test SDF Network ; September 2015"

      [[CURRENCIES]]
      code="FAKE"
      issuer="GBOGUSACCOUNTTHATDOESNOTEXISTONTHENETWORK1234567890AB"
      regulated=true
      approval_server="https://fake.io/tx_approve"
    ''';

    RegulatedAssetsService service =
        RegulatedAssetsService(StellarToml(fakeToml));
    RegulatedAsset fakeAsset = service.regulatedAssets.first;

    expect(
      () => service.authorizationRequired(fakeAsset),
      throwsA(isA<IssuerAccountNotFound>()),
    );
  });

  test('sep-08: Complete Workflow - build tx and get approval', () async {
    // Snippet from sep-08.md "Complete Workflow Example"
    RegulatedAssetsService service = RegulatedAssetsService(toml);
    RegulatedAsset regulatedAsset = service.regulatedAssets.first;

    // Verify issuer is properly configured
    bool authRequired = await service.authorizationRequired(regulatedAsset);
    expect(authRequired, true);

    if (regulatedAsset.approvalCriteria != null) {
      expect(regulatedAsset.approvalCriteria, isNotEmpty);
    }

    // Build and sign the transaction
    KeyPair senderKeyPair = senderKp;
    AccountResponse senderAccount =
        await service.sdk.accounts.account(senderKeyPair.accountId);

    Transaction tx = TransactionBuilder(senderAccount)
        .addOperation(
          PaymentOperationBuilder(
                  destinationKp.accountId, regulatedAsset, '100')
              .build(),
        )
        .build();
    tx.sign(senderKeyPair, service.network);
    String txXdr = tx.toEnvelopeXdrBase64();

    // Mock the approval server to return success
    http.Client mockClient = MockClient((request) async {
      if (request.url.toString().contains('goat') &&
          request.method == 'POST') {
        String submittedTx = json.decode(request.body)['tx'];
        var result = {'status': 'success', 'tx': submittedTx};
        return http.Response(jsonEncode(result), 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    service.httpClient = mockClient;

    // Submit for approval and handle response
    PostTransactionResponse response =
        await service.postTransaction(txXdr, regulatedAsset.approvalServer);

    String? approvedTxXdr;

    if (response is PostTransactionSuccess) {
      if (response.message != null) {
        expect(response.message, isNotEmpty);
      }
      approvedTxXdr = response.tx;
    } else if (response is PostTransactionRevised) {
      approvedTxXdr = response.tx;
    } else if (response is PostTransactionPending) {
      int waitMs = response.timeout;
      expect(waitMs, isA<int>());
    } else if (response is PostTransactionActionRequired) {
      expect(response.message, isNotEmpty);
      expect(response.actionUrl, isNotEmpty);
    } else if (response is PostTransactionRejected) {
      fail('Transaction rejected: ${response.error}');
    }

    expect(approvedTxXdr, isNotNull);
    expect(approvedTxXdr, txXdr);
  });

  test('sep-08: postTransaction with action_required then postAction done flow',
      () async {
    // Snippet from sep-08.md "postAction - Handling Action Required" - full flow
    String actionUrl = 'https://goat.io/kyc/action';

    // First mock: approval server returns action_required
    http.Client actionRequiredMock = MockClient((request) async {
      if (request.url.toString().contains('goat.io/tx_approve') &&
          request.method == 'POST') {
        var result = {
          'status': 'action_required',
          'message': 'Please provide KYC information',
          'action_url': actionUrl,
          'action_method': 'POST',
          'action_fields': ['email_address', 'mobile_number']
        };
        return http.Response(jsonEncode(result), 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    RegulatedAssetsService service =
        RegulatedAssetsService(toml, httpClient: actionRequiredMock);
    RegulatedAsset goatAsset = service.regulatedAssets.first;

    PostTransactionResponse response =
        await service.postTransaction(testTxXdr, goatAsset.approvalServer);
    expect(response, isA<PostTransactionActionRequired>());

    PostTransactionActionRequired actionRequired =
        response as PostTransactionActionRequired;

    if (actionRequired.actionMethod == 'POST') {
      // Second mock: action endpoint returns done, then approval returns success
      http.Client actionDoneMock = MockClient((request) async {
        if (request.url.toString().contains(actionUrl) &&
            request.method == 'POST') {
          var result = {'result': 'no_further_action_required'};
          return http.Response(jsonEncode(result), 200);
        }
        if (request.url.toString().contains('goat.io/tx_approve') &&
            request.method == 'POST') {
          String tx = json.decode(request.body)['tx'];
          var result = {'status': 'success', 'tx': tx};
          return http.Response(jsonEncode(result), 200);
        }
        return http.Response(json.encode({'error': 'Bad request'}), 400);
      });

      service.httpClient = actionDoneMock;

      PostActionResponse actionResponse = await service.postAction(
        actionRequired.actionUrl,
        {
          'email_address': 'user@example.com',
          'mobile_number': '+1234567890',
        },
      );

      expect(actionResponse, isA<PostActionDone>());

      // Resubmit original transaction after action done
      PostTransactionResponse retryResponse =
          await service.postTransaction(testTxXdr, goatAsset.approvalServer);
      expect(retryResponse, isA<PostTransactionSuccess>());
    }
  });

  test('sep-08: Pending timeout is int in milliseconds, defaults to 0',
      () async {
    // Snippet from sep-08.md "Common Pitfalls" - timeout handling
    http.Client mockClient = MockClient((request) async {
      if (request.url.toString().contains('goat') &&
          request.method == 'POST') {
        // Server does not provide timeout
        var result = {'status': 'pending'};
        return http.Response(jsonEncode(result), 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    RegulatedAssetsService service =
        RegulatedAssetsService(toml, httpClient: mockClient);
    RegulatedAsset goatAsset = service.regulatedAssets.first;

    PostTransactionResponse response =
        await service.postTransaction(testTxXdr, goatAsset.approvalServer);

    expect(response, isA<PostTransactionPending>());
    PostTransactionPending pending = response as PostTransactionPending;
    // timeout defaults to 0 when not provided by server
    expect(pending.timeout, 0);
    // message is nullable
    expect(pending.message, isNull);
  });

  test('sep-08: actionMethod defaults to GET when not provided', () async {
    // Snippet from sep-08.md "Common Pitfalls" - actionMethod default
    http.Client mockClient = MockClient((request) async {
      if (request.url.toString().contains('goat') &&
          request.method == 'POST') {
        // Server does not provide action_method
        var result = {
          'status': 'action_required',
          'message': 'Complete KYC',
          'action_url': 'https://goat.io/kyc',
        };
        return http.Response(jsonEncode(result), 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    RegulatedAssetsService service =
        RegulatedAssetsService(toml, httpClient: mockClient);
    RegulatedAsset goatAsset = service.regulatedAssets.first;

    PostTransactionResponse response =
        await service.postTransaction(testTxXdr, goatAsset.approvalServer);

    expect(response, isA<PostTransactionActionRequired>());
    PostTransactionActionRequired actionRequired =
        response as PostTransactionActionRequired;
    // actionMethod defaults to "GET" when server omits it
    expect(actionRequired.actionMethod, 'GET');
    expect(actionRequired.actionFields, isNull);
  });
}
