@Timeout(const Duration(seconds: 300))

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  // Reusable mock federation data
  const testAccountId =
      'GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP';
  const testStellarAddress = 'bob*example.com';
  const testFederationServer = 'https://api.example.com/federation';

  /// Creates a MockClient that handles stellar.toml discovery and federation queries.
  MockClient createFederationMockClient({
    String stellarAddress = testStellarAddress,
    String accountId = testAccountId,
    String? memoType,
    String? memo,
    String federationServer = testFederationServer,
  }) {
    return MockClient((request) async {
      final url = request.url.toString();

      // stellar.toml discovery
      if (url.contains('.well-known/stellar.toml')) {
        return http.Response(
          'FEDERATION_SERVER="$federationServer"',
          200,
        );
      }

      // Federation query
      if (url.contains('/federation')) {
        final responseBody = <String, dynamic>{
          'stellar_address': stellarAddress,
          'account_id': accountId,
        };
        if (memoType != null) responseBody['memo_type'] = memoType;
        if (memo != null) responseBody['memo'] = memo;

        return http.Response(json.encode(responseBody), 200);
      }

      return http.Response('Not found', 404);
    });
  }

  test('sep-02: Quick example — resolve Stellar address', () async {
    // Snippet from sep-02.md "Quick example"
    final mockClient = createFederationMockClient(
      stellarAddress: 'bob*example.com',
      accountId: testAccountId,
      memoType: 'text',
      memo: 'hello',
    );

    FederationResponse response = await Federation.resolveStellarAddress(
      'bob*example.com',
      httpClient: mockClient,
    );

    expect(response.accountId, testAccountId);
    expect(response.memo, 'hello');
  });

  test('sep-02: Resolving Stellar addresses — full response fields', () async {
    // Snippet from sep-02.md "Resolving Stellar addresses"
    final mockClient = createFederationMockClient(
      stellarAddress: 'bob*example.com',
      accountId: testAccountId,
      memoType: 'text',
      memo: 'test memo',
    );

    FederationResponse response = await Federation.resolveStellarAddress(
      'bob*example.com',
      httpClient: mockClient,
    );

    // The destination account for payments
    String? accountId = response.accountId;
    expect(accountId, testAccountId);

    // Include memo if provided
    String? memo = response.memo;
    String? memoType = response.memoType;
    expect(memo, 'test memo');
    expect(memoType, 'text');

    // Original address for confirmation
    String? address = response.stellarAddress;
    expect(address, 'bob*example.com');
  });

  test('sep-02: Reverse lookup — account ID to address', () async {
    // Snippet from sep-02.md "Reverse lookup"
    final mockClient = MockClient((request) async {
      expect(request.url.queryParameters['type'], 'id');
      expect(request.url.queryParameters['q'], testAccountId);

      return http.Response(
        json.encode({
          'stellar_address': 'bob*example.com',
          'account_id': testAccountId,
        }),
        200,
      );
    });

    String accountId = testAccountId;
    String federationServer = testFederationServer;

    FederationResponse response = await Federation.resolveStellarAccountId(
      accountId,
      federationServer,
      httpClient: mockClient,
    );

    expect(response.stellarAddress, 'bob*example.com');
    expect(response.accountId, testAccountId);
  });

  test('sep-02: Transaction lookup', () async {
    // Snippet from sep-02.md "Transaction lookup"
    const txId =
        'c1b368c00e9852351361e07cc58c54277e7a6366580044ab152b8db9cd8ec52a';

    final mockClient = MockClient((request) async {
      expect(request.url.queryParameters['type'], 'txid');
      expect(request.url.queryParameters['q'], txId);

      return http.Response(
        json.encode({
          'stellar_address': 'sender*example.com',
          'account_id': testAccountId,
        }),
        200,
      );
    });

    FederationResponse response = await Federation.resolveStellarTransactionId(
      txId,
      testFederationServer,
      httpClient: mockClient,
    );

    expect(response.stellarAddress, 'sender*example.com');
    expect(response.accountId, testAccountId);
  });

  test('sep-02: Forward federation', () async {
    // Snippet from sep-02.md "Forward federation"
    final mockClient = MockClient((request) async {
      expect(request.url.queryParameters['type'], 'forward');
      expect(request.url.queryParameters['forward_type'], 'bank_account');
      expect(request.url.queryParameters['swift'], 'BOPBPHMM');
      expect(request.url.queryParameters['acct'], '2382376');

      return http.Response(
        json.encode({
          'account_id': testAccountId,
          'memo_type': 'id',
          'memo': '54321',
        }),
        200,
      );
    });

    Map<String, String> params = {
      'forward_type': 'bank_account',
      'swift': 'BOPBPHMM',
      'acct': '2382376',
    };

    FederationResponse response = await Federation.resolveForward(
      params,
      testFederationServer,
      httpClient: mockClient,
    );

    expect(response.accountId, testAccountId);
    expect(response.memoType, 'id');
    expect(response.memo, '54321');
  });

  test('sep-02: Building a payment with federation — memo handling', () async {
    // Snippet from sep-02.md "Building a payment with federation"
    // Tests the memo-building logic from the example

    // Test text memo
    FederationResponse textResponse =
        FederationResponse('alice*example.com', testAccountId, 'text', 'hello');
    Memo textMemo = Memo.text(textResponse.memo!);
    expect(textMemo, isA<MemoText>());

    // Test id memo
    FederationResponse idResponse =
        FederationResponse('alice*example.com', testAccountId, 'id', '12345');
    Memo idMemo = Memo.id(BigInt.parse(idResponse.memo!));
    expect(idMemo, isA<MemoId>());

    // Test hash memo
    final hashBytes = List.filled(32, 0);
    final hashBase64 = base64Encode(hashBytes);
    FederationResponse hashResponse =
        FederationResponse('alice*example.com', testAccountId, 'hash', hashBase64);
    Memo hashMemo = MemoHash(base64Decode(hashResponse.memo!));
    expect(hashMemo, isA<MemoHash>());
  });

  test('sep-02: Error handling — invalid address format', () async {
    // Snippet from sep-02.md "Error handling"
    // Invalid address format (missing *)
    try {
      await Federation.resolveStellarAddress('invalid-no-asterisk');
      fail('Should have thrown');
    } catch (e) {
      expect(e.toString(), contains('invalid federation address'));
    }
  });

  test('sep-02: Custom HTTP client — httpClient and headers', () async {
    // Snippet from sep-02.md "Custom HTTP client"
    final mockClient = MockClient((request) async {
      final url = request.url.toString();

      if (url.contains('.well-known/stellar.toml')) {
        return http.Response(
          'FEDERATION_SERVER="$testFederationServer"',
          200,
        );
      }

      if (url.contains('/federation')) {
        return http.Response(
          json.encode({
            'stellar_address': 'bob*example.com',
            'account_id': testAccountId,
          }),
          200,
        );
      }

      return http.Response('Not found', 404);
    });

    FederationResponse response = await Federation.resolveStellarAddress(
      'bob*example.com',
      httpClient: mockClient,
      httpRequestHeaders: {'User-Agent': 'MyWallet/1.0'},
    );

    expect(response.accountId, testAccountId);
  });

  test('sep-02: Finding the federation server — StellarToml', () async {
    // Snippet from sep-02.md "Finding the federation server"
    final mockClient = MockClient((request) async {
      if (request.url.toString().contains('.well-known/stellar.toml')) {
        return http.Response(
          'FEDERATION_SERVER="https://stellarid.io/federation/"',
          200,
        );
      }
      return http.Response('Not found', 404);
    });

    StellarToml stellarToml = await StellarToml.fromDomain(
      'example.com',
      httpClient: mockClient,
    );
    String? federationServer =
        stellarToml.generalInformation.federationServer;

    expect(federationServer, 'https://stellarid.io/federation/');
  });

  test('sep-02: FederationResponse properties — all nullable fields', () {
    // Snippet from sep-02.md "FederationResponse properties"
    FederationResponse response = FederationResponse(
      'bob*example.com',
      testAccountId,
      'text',
      'hello',
    );

    expect(response.stellarAddress, 'bob*example.com');
    expect(response.accountId, testAccountId);
    expect(response.memoType, 'text');
    expect(response.memo, 'hello');

    // Forward lookups may not return stellarAddress
    FederationResponse forwardResponse = FederationResponse(
      null,
      testAccountId,
      'id',
      '54321',
    );

    expect(forwardResponse.stellarAddress, isNull);
    expect(forwardResponse.accountId, testAccountId);
    expect(forwardResponse.memoType, 'id');
    expect(forwardResponse.memo, '54321');
  });

  test('sep-02: Testing with MockClient — full mock example', () async {
    // Snippet from sep-02.md "Testing with MockClient"
    final mockClient = MockClient((request) async {
      final url = request.url.toString();

      // First request: stellar.toml discovery
      if (url.contains('.well-known/stellar.toml')) {
        return http.Response(
          'FEDERATION_SERVER="https://api.example.com/federation"',
          200,
        );
      }

      // Second request: federation lookup
      if (url.contains('/federation')) {
        expect(request.url.queryParameters['q'], 'alice*example.com');
        expect(request.url.queryParameters['type'], 'name');

        return http.Response(
          json.encode({
            'stellar_address': 'alice*example.com',
            'account_id':
                'GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP',
            'memo_type': 'id',
            'memo': '12345',
          }),
          200,
        );
      }

      return http.Response('Not found', 404);
    });

    FederationResponse response = await Federation.resolveStellarAddress(
      'alice*example.com',
      httpClient: mockClient,
    );

    expect(response.stellarAddress, 'alice*example.com');
    expect(
        response.accountId,
        'GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP');
    expect(response.memoType, 'id');
    expect(response.memo, '12345');
  });
}
