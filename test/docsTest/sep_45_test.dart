@Timeout(const Duration(seconds: 300))

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  // Server configuration -- matches integration test values
  const domain = 'example.stellar.org';
  const authServer = 'https://auth.example.stellar.org';
  const serverAccountId =
      'GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP';
  const serverSecretSeed =
      'SAWDHXQG6ROJSU4QGCW7NSTYFHPTPIVC2NC7QKVTO7PZCSO2WEBGM54W';
  late KeyPair serverKeyPair;
  const clientContractId =
      'CDZJIDQW5WTPAZ64PGIJGVEIDNK72LL3LKUZWG3G6GWXYQKI2JNIVFNV';
  const webAuthContractId =
      'CA7A3N2BB35XMTFPAYWVZEF4TEYXW7DAEWDXJNQGUPR5SWSM2UVZCJM2';
  const successJwt =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJDRFpKSURRVzVXVFBBWjY0UEdJSkdWRUlETks3MkxMM0xLVVpXRzNHNkdXWFlRS0kySkFJVkZOViIsImlzcyI6ImV4YW1wbGUuc3RlbGxhci5vcmciLCJpYXQiOjE3Mzc3NjAwMDAsImV4cCI6MTczNzc2MzYwMH0.test';

  setUp(() {
    serverKeyPair = KeyPair.fromSecretSeed(serverSecretSeed);
  });

  // Helper: build args map as XdrSCVal
  XdrSCVal buildArgsMap({
    required String account,
    required String homeDomain,
    required String webAuthDomain,
    required String webAuthDomainAccount,
    required String nonce,
    String? clientDomain,
    String? clientDomainAccount,
  }) {
    final mapEntries = <XdrSCMapEntry>[];

    mapEntries.add(XdrSCMapEntry(
      XdrSCVal.forSymbol('account'),
      XdrSCVal.forString(account),
    ));
    mapEntries.add(XdrSCMapEntry(
      XdrSCVal.forSymbol('home_domain'),
      XdrSCVal.forString(homeDomain),
    ));
    mapEntries.add(XdrSCMapEntry(
      XdrSCVal.forSymbol('web_auth_domain'),
      XdrSCVal.forString(webAuthDomain),
    ));
    mapEntries.add(XdrSCMapEntry(
      XdrSCVal.forSymbol('web_auth_domain_account'),
      XdrSCVal.forString(webAuthDomainAccount),
    ));
    mapEntries.add(XdrSCMapEntry(
      XdrSCVal.forSymbol('nonce'),
      XdrSCVal.forString(nonce),
    ));

    if (clientDomain != null) {
      mapEntries.add(XdrSCMapEntry(
        XdrSCVal.forSymbol('client_domain'),
        XdrSCVal.forString(clientDomain),
      ));
    }

    if (clientDomainAccount != null) {
      mapEntries.add(XdrSCMapEntry(
        XdrSCVal.forSymbol('client_domain_account'),
        XdrSCVal.forString(clientDomainAccount),
      ));
    }

    return XdrSCVal.forMap(mapEntries);
  }

  // Helper: build a single authorization entry
  SorobanAuthorizationEntry buildAuthEntry({
    required String credentialsAddress,
    required String contractId,
    required String functionName,
    required XdrSCVal argsMap,
    required BigInt nonce,
    required int expirationLedger,
  }) {
    Address address;
    if (credentialsAddress.startsWith('C')) {
      address = Address.forContractId(credentialsAddress);
    } else {
      address = Address.forAccountId(credentialsAddress);
    }

    final credentials = SorobanCredentials.forAddress(
      address,
      nonce,
      expirationLedger,
      XdrSCVal.forVec([]),
    );

    final contractAddress = Address.forContractId(contractId);
    final contractFn = XdrInvokeContractArgs(
      contractAddress.toXdr(),
      functionName,
      [argsMap],
    );

    final function_ = SorobanAuthorizedFunction(contractFn: contractFn);
    final invocation =
        SorobanAuthorizedInvocation(function_, subInvocations: []);
    return SorobanAuthorizationEntry(credentials, invocation);
  }

  // Helper: encode authorization entries to base64 XDR
  String encodeAuthEntries(List<SorobanAuthorizationEntry> entries) {
    final out = XdrDataOutputStream();
    out.writeInt(entries.length);
    for (final entry in entries) {
      XdrSorobanAuthorizationEntry.encode(out, entry.toXdr());
    }
    return base64Encode(out.bytes);
  }

  // Helper: build a complete valid challenge
  String buildValidChallenge({
    required String nonce,
    String? clientDomain,
    String? clientDomainAccount,
    bool signServerEntry = true,
  }) {
    final argsMap = buildArgsMap(
      account: clientContractId,
      homeDomain: domain,
      webAuthDomain: 'auth.example.stellar.org',
      webAuthDomainAccount: serverAccountId,
      nonce: nonce,
      clientDomain: clientDomain,
      clientDomainAccount: clientDomainAccount,
    );

    final entries = <SorobanAuthorizationEntry>[];

    // Server entry
    final serverEntry = buildAuthEntry(
      credentialsAddress: serverAccountId,
      contractId: webAuthContractId,
      functionName: 'web_auth_verify',
      argsMap: argsMap,
      nonce: BigInt.from(12345),
      expirationLedger: 1000000,
    );
    if (signServerEntry) {
      serverEntry.sign(serverKeyPair, Network.TESTNET);
    }
    entries.add(serverEntry);

    // Client entry
    final clientEntry = buildAuthEntry(
      credentialsAddress: clientContractId,
      contractId: webAuthContractId,
      functionName: 'web_auth_verify',
      argsMap: argsMap,
      nonce: BigInt.from(12346),
      expirationLedger: 1000000,
    );
    entries.add(clientEntry);

    // Client domain entry
    if (clientDomainAccount != null) {
      final clientDomainEntry = buildAuthEntry(
        credentialsAddress: clientDomainAccount,
        contractId: webAuthContractId,
        functionName: 'web_auth_verify',
        argsMap: argsMap,
        nonce: BigInt.from(12347),
        expirationLedger: 1000000,
      );
      entries.add(clientDomainEntry);
    }

    return encodeAuthEntries(entries);
  }

  // --- Quick example ---

  test('sep-45: Quick example - basic authentication', () async {
    // Snippet from sep-45.md "Quick example"
    final nonce = 'nonce_${DateTime.now().millisecondsSinceEpoch}';
    final challengeXdr = buildValidChallenge(nonce: nonce);

    final mockClient = MockClient((request) async {
      if (request.method == 'GET') {
        return http.Response(
          json.encode({
            'authorization_entries': challengeXdr,
            'network_passphrase': 'Test SDF Network ; September 2015',
          }),
          200,
        );
      }
      return http.Response(json.encode({'token': successJwt}), 200);
    });

    const contractId =
        'CDZJIDQW5WTPAZ64PGIJGVEIDNK72LL3LKUZWG3G6GWXYQKI2JNIVFNV';
    final signer = KeyPair.random();

    final webAuth = WebAuthForContracts(
      authServer,
      webAuthContractId,
      serverAccountId,
      domain,
      Network.TESTNET,
      httpClient: mockClient,
    );
    final jwtToken = await webAuth.jwtToken(contractId, [signer]);

    expect(jwtToken, equals(successJwt));
    expect(jwtToken.substring(0, 50).length, 50);
  });

  // --- Manual configuration ---

  test('sep-45: Manual configuration', () {
    // Snippet from sep-45.md "Manual configuration"
    final webAuth = WebAuthForContracts(
      'https://anchor.example.com/auth/sep45',
      'CCALHRGH5RXIDJDRLPPG4ZX2S563TB2QKKJR4STWKVQCYB6JVPYQXHRG',
      'GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP',
      'anchor.example.com',
      Network.TESTNET,
    );

    expect(webAuth, isNotNull);
  });

  // --- Custom Soroban RPC URL ---

  test('sep-45: Custom Soroban RPC URL', () {
    // Snippet from sep-45.md "Custom Soroban RPC URL"
    final webAuth = WebAuthForContracts(
      'https://anchor.example.com/auth/sep45',
      'CCALHRGH5RXIDJDRLPPG4ZX2S563TB2QKKJR4STWKVQCYB6JVPYQXHRG',
      'GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP',
      'anchor.example.com',
      Network.TESTNET,
      sorobanRpcUrl: 'https://your-custom-rpc.example.com',
    );

    expect(webAuth, isNotNull);
  });

  // --- Basic authentication ---

  test('sep-45: Basic authentication', () async {
    // Snippet from sep-45.md "Basic authentication"
    final nonce = 'nonce_${DateTime.now().millisecondsSinceEpoch}';
    final challengeXdr = buildValidChallenge(nonce: nonce);

    final mockClient = MockClient((request) async {
      if (request.method == 'GET') {
        return http.Response(
          json.encode({
            'authorization_entries': challengeXdr,
            'network_passphrase': 'Test SDF Network ; September 2015',
          }),
          200,
        );
      }
      return http.Response(json.encode({'token': successJwt}), 200);
    });

    const contractId =
        'CDZJIDQW5WTPAZ64PGIJGVEIDNK72LL3LKUZWG3G6GWXYQKI2JNIVFNV';
    final signer = KeyPair.random();

    final webAuth = WebAuthForContracts(
      authServer,
      webAuthContractId,
      serverAccountId,
      domain,
      Network.TESTNET,
      httpClient: mockClient,
    );
    final jwtToken = await webAuth.jwtToken(contractId, [signer]);

    expect(jwtToken, equals(successJwt));
  });

  // --- Custom expiration ---

  test('sep-45: Custom expiration', () async {
    // Snippet from sep-45.md "Custom expiration"
    final nonce = 'nonce_${DateTime.now().millisecondsSinceEpoch}';
    final challengeXdr = buildValidChallenge(nonce: nonce);

    final mockClient = MockClient((request) async {
      if (request.method == 'GET') {
        return http.Response(
          json.encode({
            'authorization_entries': challengeXdr,
            'network_passphrase': 'Test SDF Network ; September 2015',
          }),
          200,
        );
      }
      return http.Response(json.encode({'token': successJwt}), 200);
    });

    final webAuth = WebAuthForContracts(
      authServer,
      webAuthContractId,
      serverAccountId,
      domain,
      Network.TESTNET,
      httpClient: mockClient,
    );

    final jwtToken = await webAuth.jwtToken(
      clientContractId,
      [KeyPair.random()],
      signatureExpirationLedger: 1500000,
    );

    expect(jwtToken, equals(successJwt));
  });

  // --- Empty signers ---

  test('sep-45: Contracts without signature requirements', () async {
    // Snippet from sep-45.md "Contracts without signature requirements"
    final nonce = 'nonce_${DateTime.now().millisecondsSinceEpoch}';
    final challengeXdr = buildValidChallenge(nonce: nonce);

    final mockClient = MockClient((request) async {
      if (request.method == 'GET') {
        return http.Response(
          json.encode({
            'authorization_entries': challengeXdr,
            'network_passphrase': 'Test SDF Network ; September 2015',
          }),
          200,
        );
      }
      return http.Response(json.encode({'token': successJwt}), 200);
    });

    final webAuth = WebAuthForContracts(
      authServer,
      webAuthContractId,
      serverAccountId,
      domain,
      Network.TESTNET,
      httpClient: mockClient,
    );

    // Empty signers list - no signatures will be added
    final jwtToken = await webAuth.jwtToken(clientContractId, []);

    expect(jwtToken, equals(successJwt));
  });

  // --- Client domain verification (local signing) ---

  test('sep-45: Client domain verification - local signing', () async {
    // Snippet from sep-45.md "Client domain verification - Local signing"
    final clientDomainKeyPair = KeyPair.random();
    final nonce = 'nonce_${DateTime.now().millisecondsSinceEpoch}';
    final challengeXdr = buildValidChallenge(
      nonce: nonce,
      clientDomain: 'wallet.example.com',
      clientDomainAccount: clientDomainKeyPair.accountId,
    );

    final mockClient = MockClient((request) async {
      if (request.method == 'GET') {
        return http.Response(
          json.encode({
            'authorization_entries': challengeXdr,
            'network_passphrase': 'Test SDF Network ; September 2015',
          }),
          200,
        );
      }
      return http.Response(json.encode({'token': successJwt}), 200);
    });

    final webAuth = WebAuthForContracts(
      authServer,
      webAuthContractId,
      serverAccountId,
      domain,
      Network.TESTNET,
      httpClient: mockClient,
    );

    final jwtToken = await webAuth.jwtToken(
      clientContractId,
      [KeyPair.random()],
      homeDomain: domain,
      clientDomain: 'wallet.example.com',
      clientDomainAccountKeyPair: clientDomainKeyPair,
    );

    expect(jwtToken, equals(successJwt));
  });

  // --- Client domain verification (remote signing via callback) ---

  test('sep-45: Client domain verification - remote signing callback',
      () async {
    // Snippet from sep-45.md "Remote signing via callback"
    final clientDomainKeyPair = KeyPair.random();
    final nonce = 'nonce_${DateTime.now().millisecondsSinceEpoch}';
    final challengeXdr = buildValidChallenge(
      nonce: nonce,
      clientDomain: 'wallet.example.com',
      clientDomainAccount: clientDomainKeyPair.accountId,
    );

    var requestCount = 0;
    final mockClient = MockClient((request) async {
      requestCount++;
      if (requestCount == 1 && request.method == 'GET') {
        // Challenge response
        return http.Response(
          json.encode({
            'authorization_entries': challengeXdr,
            'network_passphrase': 'Test SDF Network ; September 2015',
          }),
          200,
        );
      }
      if (requestCount == 2) {
        // stellar.toml fetch for client domain signing key
        return http.Response(
          'SIGNING_KEY = "${clientDomainKeyPair.accountId}"',
          200,
        );
      }
      // Token POST response
      return http.Response(json.encode({'token': successJwt}), 200);
    });

    // Callback that signs locally (simulates remote signing)
    Future<SorobanAuthorizationEntry> signingCallback(
        SorobanAuthorizationEntry entry) async {
      entry.sign(clientDomainKeyPair, Network.TESTNET);
      return entry;
    }

    final webAuth = WebAuthForContracts(
      authServer,
      webAuthContractId,
      serverAccountId,
      domain,
      Network.TESTNET,
      httpClient: mockClient,
    );

    final jwtToken = await webAuth.jwtToken(
      clientContractId,
      [KeyPair.random()],
      clientDomain: 'wallet.example.com',
      clientDomainSigningCallback: signingCallback,
    );

    expect(jwtToken, equals(successJwt));
  });

  // --- Step-by-step authentication ---

  test('sep-45: Step-by-step authentication', () async {
    // Snippet from sep-45.md "Step-by-step authentication"
    final nonce = 'nonce_${DateTime.now().millisecondsSinceEpoch}';
    final challengeXdr = buildValidChallenge(nonce: nonce);

    final mockClient = MockClient((request) async {
      if (request.method == 'GET') {
        return http.Response(
          json.encode({
            'authorization_entries': challengeXdr,
            'network_passphrase': 'Test SDF Network ; September 2015',
          }),
          200,
        );
      }
      return http.Response(json.encode({'token': successJwt}), 200);
    });

    final webAuth = WebAuthForContracts(
      authServer,
      webAuthContractId,
      serverAccountId,
      domain,
      Network.TESTNET,
      httpClient: mockClient,
    );

    // Step 1: Get challenge from server
    final challengeResponse = await webAuth.getChallenge(
      clientContractId,
      homeDomain: domain,
    );
    expect(challengeResponse.authorizationEntries, isNotEmpty);

    // Step 2: Decode authorization entries from base64 XDR
    final authEntries = webAuth.decodeAuthorizationEntries(
      challengeResponse.authorizationEntries,
    );
    expect(authEntries.length, 2); // server + client

    // Step 3: Validate challenge (security checks)
    webAuth.validateChallenge(
      authEntries,
      clientContractId,
      homeDomain: domain,
    );

    // Step 4: Use a custom expiration ledger (skip Soroban RPC in test)
    const expirationLedger = 1500000;

    // Step 5: Sign authorization entries
    final signedEntries = await webAuth.signAuthorizationEntries(
      authEntries,
      clientContractId,
      [KeyPair.random()],
      expirationLedger,
      null, // clientDomainKeyPair
      null, // clientDomainAccountId
      null, // clientDomainSigningCallback
    );
    expect(signedEntries.length, 2);

    // Step 6: Submit signed entries for JWT token
    final jwtToken = await webAuth.sendSignedChallenge(signedEntries);
    expect(jwtToken, equals(successJwt));
  });

  // --- Request format configuration ---

  test('sep-45: Request format - JSON', () async {
    // Snippet from sep-45.md "Request format configuration"
    final nonce = 'nonce_${DateTime.now().millisecondsSinceEpoch}';
    final challengeXdr = buildValidChallenge(nonce: nonce);

    final mockClient = MockClient((request) async {
      if (request.method == 'GET') {
        return http.Response(
          json.encode({
            'authorization_entries': challengeXdr,
            'network_passphrase': 'Test SDF Network ; September 2015',
          }),
          200,
        );
      }
      // Verify JSON content type on POST
      expect(request.headers['content-type'],
          contains('application/json'));
      return http.Response(json.encode({'token': successJwt}), 200);
    });

    final webAuth = WebAuthForContracts(
      authServer,
      webAuthContractId,
      serverAccountId,
      domain,
      Network.TESTNET,
      httpClient: mockClient,
    );

    // Use JSON format instead of form-urlencoded
    webAuth.useFormUrlEncoded = false;

    final jwtToken = await webAuth.jwtToken(clientContractId, [KeyPair.random()]);
    expect(jwtToken, equals(successJwt));
  });

  // --- Error handling ---

  test('sep-45: Error handling - challenge request error', () async {
    // Snippet from sep-45.md "Error handling" - ContractChallengeRequestErrorResponse
    final mockClient = MockClient((request) async {
      return http.Response(
        json.encode({'error': 'Invalid account'}),
        400,
      );
    });

    final webAuth = WebAuthForContracts(
      authServer,
      webAuthContractId,
      serverAccountId,
      domain,
      Network.TESTNET,
      httpClient: mockClient,
    );

    expect(
      () => webAuth.jwtToken(clientContractId, [KeyPair.random()],
          homeDomain: domain),
      throwsA(isA<ContractChallengeRequestErrorResponse>()),
    );
  });

  test('sep-45: Error handling - invalid contract address', () async {
    // Snippet from sep-45.md "Error handling" - ContractChallengeValidationErrorInvalidContractAddress
    final nonce = 'nonce_${DateTime.now().millisecondsSinceEpoch}';
    const wrongContractId =
        'CCJCTOZFKPNTFLMORB7RBNKDQU42PBKGVTI4DIWVEMUCXRHWCYXGRRV7';

    final argsMap = buildArgsMap(
      account: clientContractId,
      homeDomain: domain,
      webAuthDomain: 'auth.example.stellar.org',
      webAuthDomainAccount: serverAccountId,
      nonce: nonce,
    );

    final entries = <SorobanAuthorizationEntry>[];
    final serverEntry = buildAuthEntry(
      credentialsAddress: serverAccountId,
      contractId: wrongContractId, // Wrong contract
      functionName: 'web_auth_verify',
      argsMap: argsMap,
      nonce: BigInt.from(12345),
      expirationLedger: 1000000,
    );
    serverEntry.sign(serverKeyPair, Network.TESTNET);
    entries.add(serverEntry);

    final clientEntry = buildAuthEntry(
      credentialsAddress: clientContractId,
      contractId: wrongContractId,
      functionName: 'web_auth_verify',
      argsMap: argsMap,
      nonce: BigInt.from(12346),
      expirationLedger: 1000000,
    );
    entries.add(clientEntry);

    final challengeXdr = encodeAuthEntries(entries);

    final mockClient = MockClient((request) async {
      return http.Response(
        json.encode({'authorization_entries': challengeXdr}),
        200,
      );
    });

    final webAuth = WebAuthForContracts(
      authServer,
      webAuthContractId,
      serverAccountId,
      domain,
      Network.TESTNET,
      httpClient: mockClient,
    );

    expect(
      () => webAuth.jwtToken(clientContractId, [KeyPair.random()],
          homeDomain: domain),
      throwsA(isA<ContractChallengeValidationErrorInvalidContractAddress>()),
    );
  });

  test('sep-45: Error handling - submit challenge error', () async {
    // Snippet from sep-45.md "Error handling" - SubmitContractChallengeErrorResponseException
    final nonce = 'nonce_${DateTime.now().millisecondsSinceEpoch}';
    final challengeXdr = buildValidChallenge(nonce: nonce);

    final mockClient = MockClient((request) async {
      if (request.method == 'GET') {
        return http.Response(
          json.encode({
            'authorization_entries': challengeXdr,
            'network_passphrase': 'Test SDF Network ; September 2015',
          }),
          200,
        );
      }
      return http.Response(
        json.encode({'error': 'Invalid signature'}),
        400,
      );
    });

    final webAuth = WebAuthForContracts(
      authServer,
      webAuthContractId,
      serverAccountId,
      domain,
      Network.TESTNET,
      httpClient: mockClient,
    );

    expect(
      () => webAuth.jwtToken(clientContractId, [KeyPair.random()],
          homeDomain: domain),
      throwsA(isA<SubmitContractChallengeErrorResponseException>()),
    );
  });

  test('sep-45: Error handling - submit challenge timeout', () async {
    // Snippet from sep-45.md "Error handling" - SubmitContractChallengeTimeoutResponseException
    final nonce = 'nonce_${DateTime.now().millisecondsSinceEpoch}';
    final challengeXdr = buildValidChallenge(nonce: nonce);

    final mockClient = MockClient((request) async {
      if (request.method == 'GET') {
        return http.Response(
          json.encode({
            'authorization_entries': challengeXdr,
            'network_passphrase': 'Test SDF Network ; September 2015',
          }),
          200,
        );
      }
      return http.Response('Gateway Timeout', 504);
    });

    final webAuth = WebAuthForContracts(
      authServer,
      webAuthContractId,
      serverAccountId,
      domain,
      Network.TESTNET,
      httpClient: mockClient,
    );

    expect(
      () => webAuth.jwtToken(clientContractId, [KeyPair.random()],
          homeDomain: domain),
      throwsA(isA<SubmitContractChallengeTimeoutResponseException>()),
    );
  });

  test('sep-45: Error handling - submit challenge unknown response', () async {
    // Snippet from sep-45.md "Error handling" - SubmitContractChallengeUnknownResponseException
    final nonce = 'nonce_${DateTime.now().millisecondsSinceEpoch}';
    final challengeXdr = buildValidChallenge(nonce: nonce);

    final mockClient = MockClient((request) async {
      if (request.method == 'GET') {
        return http.Response(
          json.encode({
            'authorization_entries': challengeXdr,
            'network_passphrase': 'Test SDF Network ; September 2015',
          }),
          200,
        );
      }
      return http.Response('Internal Server Error', 500);
    });

    final webAuth = WebAuthForContracts(
      authServer,
      webAuthContractId,
      serverAccountId,
      domain,
      Network.TESTNET,
      httpClient: mockClient,
    );

    expect(
      () => webAuth.jwtToken(clientContractId, [KeyPair.random()],
          homeDomain: domain),
      throwsA(isA<SubmitContractChallengeUnknownResponseException>()),
    );
  });

  // --- Validation errors ---

  test('sep-45: Error handling - sub-invocations found', () async {
    final nonce = 'nonce_${DateTime.now().millisecondsSinceEpoch}';

    final argsMap = buildArgsMap(
      account: clientContractId,
      homeDomain: domain,
      webAuthDomain: 'auth.example.stellar.org',
      webAuthDomainAccount: serverAccountId,
      nonce: nonce,
    );

    // Build an entry WITH sub-invocations (invalid)
    final address = Address.forAccountId(serverAccountId);
    final credentials = SorobanCredentials.forAddress(
      address,
      BigInt.from(12345),
      1000000,
      XdrSCVal.forVec([]),
    );

    final contractAddress = Address.forContractId(webAuthContractId);
    final contractFn = XdrInvokeContractArgs(
      contractAddress.toXdr(),
      'web_auth_verify',
      [argsMap],
    );

    final function_ = SorobanAuthorizedFunction(contractFn: contractFn);

    // Sub-invocation
    final subContractFn = XdrInvokeContractArgs(
      contractAddress.toXdr(),
      'some_other_function',
      [],
    );
    final subFunction = SorobanAuthorizedFunction(contractFn: subContractFn);
    final subInvocation =
        SorobanAuthorizedInvocation(subFunction, subInvocations: []);

    // Root invocation with sub-invocations
    final invocation =
        SorobanAuthorizedInvocation(function_, subInvocations: [subInvocation]);

    final serverEntry = SorobanAuthorizationEntry(credentials, invocation);
    serverEntry.sign(serverKeyPair, Network.TESTNET);

    final challengeXdr = encodeAuthEntries([serverEntry]);

    final mockClient = MockClient((request) async {
      return http.Response(
        json.encode({'authorization_entries': challengeXdr}),
        200,
      );
    });

    final webAuth = WebAuthForContracts(
      authServer,
      webAuthContractId,
      serverAccountId,
      domain,
      Network.TESTNET,
      httpClient: mockClient,
    );

    expect(
      () => webAuth.jwtToken(clientContractId, [KeyPair.random()],
          homeDomain: domain),
      throwsA(isA<ContractChallengeValidationErrorSubInvocationsFound>()),
    );
  });

  test('sep-45: Error handling - invalid server signature', () async {
    final nonce = 'nonce_${DateTime.now().millisecondsSinceEpoch}';
    // Build challenge without signing server entry
    final challengeXdr =
        buildValidChallenge(nonce: nonce, signServerEntry: false);

    final mockClient = MockClient((request) async {
      return http.Response(
        json.encode({'authorization_entries': challengeXdr}),
        200,
      );
    });

    final webAuth = WebAuthForContracts(
      authServer,
      webAuthContractId,
      serverAccountId,
      domain,
      Network.TESTNET,
      httpClient: mockClient,
    );

    expect(
      () => webAuth.jwtToken(clientContractId, [KeyPair.random()],
          homeDomain: domain),
      throwsA(isA<ContractChallengeValidationErrorInvalidServerSignature>()),
    );
  });

  test('sep-45: Error handling - missing server entry', () async {
    final nonce = 'nonce_${DateTime.now().millisecondsSinceEpoch}';

    final argsMap = buildArgsMap(
      account: clientContractId,
      homeDomain: domain,
      webAuthDomain: 'auth.example.stellar.org',
      webAuthDomainAccount: serverAccountId,
      nonce: nonce,
    );

    // Only client entry, no server entry
    final clientEntry = buildAuthEntry(
      credentialsAddress: clientContractId,
      contractId: webAuthContractId,
      functionName: 'web_auth_verify',
      argsMap: argsMap,
      nonce: BigInt.from(12346),
      expirationLedger: 1000000,
    );

    final challengeXdr = encodeAuthEntries([clientEntry]);

    final mockClient = MockClient((request) async {
      return http.Response(
        json.encode({'authorization_entries': challengeXdr}),
        200,
      );
    });

    final webAuth = WebAuthForContracts(
      authServer,
      webAuthContractId,
      serverAccountId,
      domain,
      Network.TESTNET,
      httpClient: mockClient,
    );

    expect(
      () => webAuth.jwtToken(clientContractId, [KeyPair.random()],
          homeDomain: domain),
      throwsA(isA<ContractChallengeValidationErrorMissingServerEntry>()),
    );
  });

  test('sep-45: Error handling - missing client entry', () async {
    final nonce = 'nonce_${DateTime.now().millisecondsSinceEpoch}';

    final argsMap = buildArgsMap(
      account: clientContractId,
      homeDomain: domain,
      webAuthDomain: 'auth.example.stellar.org',
      webAuthDomainAccount: serverAccountId,
      nonce: nonce,
    );

    // Only server entry, no client entry
    final serverEntry = buildAuthEntry(
      credentialsAddress: serverAccountId,
      contractId: webAuthContractId,
      functionName: 'web_auth_verify',
      argsMap: argsMap,
      nonce: BigInt.from(12345),
      expirationLedger: 1000000,
    );
    serverEntry.sign(serverKeyPair, Network.TESTNET);

    final challengeXdr = encodeAuthEntries([serverEntry]);

    final mockClient = MockClient((request) async {
      return http.Response(
        json.encode({'authorization_entries': challengeXdr}),
        200,
      );
    });

    final webAuth = WebAuthForContracts(
      authServer,
      webAuthContractId,
      serverAccountId,
      domain,
      Network.TESTNET,
      httpClient: mockClient,
    );

    expect(
      () => webAuth.jwtToken(clientContractId, [KeyPair.random()],
          homeDomain: domain),
      throwsA(isA<ContractChallengeValidationErrorMissingClientEntry>()),
    );
  });

  // --- Network support ---

  test('sep-45: Network support', () {
    // Snippet from sep-45.md "Network support"
    // Testnet
    final webAuthTestnet = WebAuthForContracts(
      authServer,
      webAuthContractId,
      serverAccountId,
      domain,
      Network.TESTNET,
    );
    expect(webAuthTestnet, isNotNull);

    // Public network (mainnet)
    final webAuthPubnet = WebAuthForContracts(
      authServer,
      webAuthContractId,
      serverAccountId,
      domain,
      Network.PUBLIC,
    );
    expect(webAuthPubnet, isNotNull);
  });
}
