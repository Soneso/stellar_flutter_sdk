@Timeout(const Duration(seconds: 300))

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  final recoveryServer = "http://recovery.example.com";

  final addressA =
      "GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP";

  final signingAddress =
      "GDRUPBJM7YIJ2NUNAIQJDJ2DQ2JDERY5SJVJVMM6MGE4UBDAMXBHARIA";

  final String jwtToken =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJHQTZVSVhYUEVXWUZJTE5VSVdBQzM3WTRRUEVaTVFWREpIREtWV0ZaSjJLQ1dVQklVNUlYWk5EQSIsImp0aSI6IjE0NGQzNjdiY2IwZTcyY2FiZmRiZGU2MGVhZTBhZDczM2NjNjVkMmE2NTg3MDgzZGFiM2Q2MTZmODg1MTkwMjQiLCJpc3MiOiJodHRwczovL2ZsYXBweS1iaXJkLWRhcHAuZmlyZWJhc2VhcHAuY29tLyIsImlhdCI6MTUzNDI1Nzk5NCwiZXhwIjoxNTM0MzQ0Mzk0fQ.8nbB83Z6vGBgC1X9r3N6oQCFTBzDiITAfCJasRft0z0";

  String requestRegisterSuccess() {
    return '{"address": "$addressA", "identities": [{"role": "sender"}, {"role": "receiver"}], "signers": [{"key": "$signingAddress"}]}';
  }

  String requestDetailsSuccess() {
    return '{"address": "$addressA", "identities": [{"role": "sender", "authenticated": true}, {"role": "receiver"}], "signers": [{"key": "$signingAddress"}]}';
  }

  String requestSignSuccess() {
    return '{"signature": "YpVelqPYVKxb8pH08s5AKsYTPwQhbaeSlgcktqwAKsYTPwQhbaeS", "network_passphrase": "Test SDF Network ; September 2015"}';
  }

  String requestListSuccess() {
    return '{"accounts": [{"address": "GBND3FJRQBNFJ4ACERGEXUXU4RKK3ZV2N3FRRFU3ONYU6SJUN6EZXPTD", "identities": [{"role": "owner", "authenticated": true}], "signers": [{"key": "GBTPAH6NWK25GESZYJ3XWPTNQUIMYNK7VU7R4NSTMZXOEKCOBKJVJ2XY"}]}, {"address": "GA7BLNSL55T2UAON5DYLQHJTR43IPT2O4QG6PAMSNLJJL7JMXKZYYVFJ", "identities": [{"role": "sender", "authenticated": true}, {"role": "receiver"}], "signers": [{"key": "GAOCJE4737GYN2EGCGWPNNCDVDKX7XKC4UKOKIF7CRRYIFLPZLH3U3UN"}]}]}';
  }

  // -- Section: Creating the Service --

  test('sep-30: Creating the Service', () {
    // Snippet from sep-30.md "Creating the Service"
    final service = SEP30RecoveryService("https://recovery.example.com");

    expect(service, isNotNull);
  });

  test('sep-30: Creating the Service with custom HTTP client', () {
    // Snippet from sep-30.md "Creating the Service" (custom client)
    final service = SEP30RecoveryService(
      "https://recovery.example.com",
      httpClient: http.Client(),
      httpRequestHeaders: {'X-Custom-Header': 'value'},
    );

    expect(service, isNotNull);
  });

  test('sep-30: Creating the Service and setting httpClient directly', () {
    // Snippet from sep-30.md "Creating the Service" (set httpClient after construction)
    final service = SEP30RecoveryService("https://recovery.example.com");
    service.httpClient = MockClient((request) async {
      return http.Response('{}', 200);
    });

    expect(service, isNotNull);
  });

  // -- Section: Registering an Account --

  test('sep-30: Registering an Account', () async {
    // Snippet from sep-30.md "Registering an Account"
    final service = SEP30RecoveryService(recoveryServer);
    service.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      if (request.url.toString().startsWith(recoveryServer) &&
          request.method == "POST" &&
          request.url.toString().contains("accounts") &&
          request.url.toString().contains(addressA) &&
          authHeader.contains(jwtToken)) {
        var identities = json.decode(request.body)["identities"];
        expect(identities.length, 1);
        expect(identities[0]["role"], "owner");
        expect(identities[0]["auth_methods"].length, 3);

        return http.Response(requestRegisterSuccess(), 200);
      }
      return http.Response(json.encode({'error': "Bad request"}), 400);
    });

    // Build authentication methods
    final emailAuth = SEP30AuthMethod("email", "person@example.com");
    final phoneAuth = SEP30AuthMethod("phone_number", "+10000000001");
    final stellarAuth = SEP30AuthMethod(
      "stellar_address",
      "GBUCAAMD7DYS7226CWUUOZ5Y2QF4JBJWIYU3UWJAFDGJVCR6EU5NJM5H",
    );

    // Single identity with role "owner"
    final ownerIdentity =
        SEP30RequestIdentity("owner", [emailAuth, phoneAuth, stellarAuth]);
    final request = SEP30Request([ownerIdentity]);

    SEP30AccountResponse response =
        await service.registerAccount(addressA, request, jwtToken);

    expect(response.address, addressA);
    expect(response.signers.length, 1);
    expect(response.signers[0].key, signingAddress);
    expect(response.identities.length, 2);
  });

  test('sep-30: Registering with multiple identities (sender + receiver)',
      () async {
    // Snippet from sep-30.md "Registering an Account" (multiple identities)
    final service = SEP30RecoveryService(recoveryServer);
    service.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      if (request.method == "POST" &&
          request.url.toString().contains("accounts") &&
          authHeader.contains(jwtToken)) {
        var identities = json.decode(request.body)["identities"];
        expect(identities.length, 2);
        expect(identities[0]["role"], "sender");
        expect(identities[1]["role"], "receiver");

        return http.Response(requestRegisterSuccess(), 200);
      }
      return http.Response(json.encode({'error': "Bad request"}), 400);
    });

    final senderIdentity = SEP30RequestIdentity("sender", [
      SEP30AuthMethod("stellar_address",
          "GBUCAAMD7DYS7226CWUUOZ5Y2QF4JBJWIYU3UWJAFDGJVCR6EU5NJM5H"),
      SEP30AuthMethod("phone_number", "+10000000001"),
      SEP30AuthMethod("email", "person1@example.com"),
    ]);
    final receiverIdentity = SEP30RequestIdentity("receiver", [
      SEP30AuthMethod("stellar_address",
          "GDIL76BC2XGDWLDPXCZVYB3AIZX4MYBN6JUBQPAX5OHRWPSNX3XMLNCS"),
      SEP30AuthMethod("phone_number", "+10000000002"),
      SEP30AuthMethod("email", "person2@example.com"),
    ]);

    final request = SEP30Request([senderIdentity, receiverIdentity]);
    SEP30AccountResponse response =
        await service.registerAccount(addressA, request, jwtToken);

    expect(response.address, addressA);
    expect(response.identities.length, 2);
  });

  // -- Section: Signing a Recovery Transaction --

  test('sep-30: Signing a Recovery Transaction', () async {
    // Snippet from sep-30.md "Signing a Recovery Transaction"
    final service = SEP30RecoveryService(recoveryServer);

    // Mock for accountDetails call
    // Mock for signTransaction call
    var callCount = 0;
    service.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      if (!authHeader.contains(jwtToken)) {
        return http.Response(json.encode({'error': "unauthorized"}), 401);
      }

      // accountDetails GET request
      if (request.method == "GET" &&
          request.url.toString().contains("accounts/$addressA") &&
          !request.url.toString().contains("sign")) {
        callCount++;
        return http.Response(requestDetailsSuccess(), 200);
      }

      // signTransaction POST request
      if (request.method == "POST" &&
          request.url.toString().contains("sign") &&
          request.url.toString().contains(signingAddress)) {
        callCount++;
        var tx = json.decode(request.body)["transaction"];
        expect(tx, isNotNull);
        expect(tx, isA<String>());
        return http.Response(requestSignSuccess(), 200);
      }

      return http.Response(json.encode({'error': "Bad request"}), 400);
    });

    // Step 1: Find the signing address
    final accountDetails =
        await service.accountDetails(addressA, jwtToken);
    final signingAddr = accountDetails.signers[0].key;
    expect(signingAddr, signingAddress);

    // Step 2: signTransaction expects a base64 XDR string
    final txBase64 =
        "AAAAAgAAAABswQhbaeSlgckYVKxb8pH08s5tqVVpGXYw1kCpbqv6lQAAAGQAIa4PAAAAAQAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAABQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAACWhlbGxvLmNvbQAAAAAAAAAAAAAAAAAAAA==";

    // Step 3: Request the recovery server to sign it
    SEP30SignatureResponse signatureResponse = await service.signTransaction(
      addressA,
      signingAddr,
      txBase64,
      jwtToken,
    );

    expect(signatureResponse.signature,
        "YpVelqPYVKxb8pH08s5AKsYTPwQhbaeSlgcktqwAKsYTPwQhbaeS");
    expect(signatureResponse.networkPassphrase,
        "Test SDF Network ; September 2015");

    // Step 4: Attach signature (verify the API for creating decorated signatures)
    final signerKeyPair = KeyPair.fromAccountId(signingAddr);
    final hint = signerKeyPair.signatureHint;
    final signatureBytes = base64Decode(signatureResponse.signature);
    final decoratedSignature =
        XdrDecoratedSignature(hint, XdrSignature(signatureBytes));
    expect(decoratedSignature, isNotNull);
    expect(hint.signatureHint.length, 4);

    expect(callCount, 2);
  });

  // -- Section: Updating Identity Information --

  test('sep-30: Updating Identity Information', () async {
    // Snippet from sep-30.md "Updating Identity Information"
    final service = SEP30RecoveryService(recoveryServer);
    service.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      if (request.method == "PUT" &&
          request.url.toString().contains("accounts") &&
          request.url.toString().contains(addressA) &&
          authHeader.contains(jwtToken)) {
        var identities = json.decode(request.body)["identities"];
        expect(identities.length, 1);
        expect(identities[0]["role"], "owner");
        expect(identities[0]["auth_methods"].length, 2);
        expect(identities[0]["auth_methods"][0]["type"], "email");
        expect(identities[0]["auth_methods"][0]["value"],
            "newemail@example.com");

        return http.Response(requestRegisterSuccess(), 200);
      }
      return http.Response(json.encode({'error': "Bad request"}), 400);
    });

    final newEmail = SEP30AuthMethod("email", "newemail@example.com");
    final newPhone = SEP30AuthMethod("phone_number", "+14155559999");
    final ownerIdentity = SEP30RequestIdentity("owner", [newEmail, newPhone]);

    final request = SEP30Request([ownerIdentity]);
    SEP30AccountResponse response =
        await service.updateIdentitiesForAccount(addressA, request, jwtToken);

    expect(response.address, addressA);
    expect(response.identities.length, 2);
  });

  // -- Section: Getting Account Details --

  test('sep-30: Getting Account Details', () async {
    // Snippet from sep-30.md "Getting Account Details"
    final service = SEP30RecoveryService(recoveryServer);
    service.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      if (request.method == "GET" &&
          request.url.toString().contains("accounts") &&
          request.url.toString().contains(addressA) &&
          authHeader.contains(jwtToken)) {
        return http.Response(requestDetailsSuccess(), 200);
      }
      return http.Response(json.encode({'error': "Bad request"}), 400);
    });

    SEP30AccountResponse response =
        await service.accountDetails(addressA, jwtToken);

    expect(response.address, addressA);
    expect(response.identities.length, 2);
    expect(response.signers.length, 1);

    // Check authenticated field (bool?)
    final authStatus =
        response.identities[0].authenticated == true ? " (authenticated)" : "";
    expect(authStatus, " (authenticated)");
    expect(response.identities[0].role, "sender");

    // Use the signer key for recovery
    final signingAddr = response.signers[0].key;
    expect(signingAddr, signingAddress);
  });

  // -- Section: Listing Accounts --

  test('sep-30: Listing Accounts', () async {
    // Snippet from sep-30.md "Listing Accounts"
    final service = SEP30RecoveryService(recoveryServer);
    service.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      if (request.method == "GET" &&
          request.url.toString().contains("accounts") &&
          authHeader.contains(jwtToken)) {
        return http.Response(requestListSuccess(), 200);
      }
      return http.Response(json.encode({'error': "Bad request"}), 400);
    });

    // First page (no cursor)
    SEP30AccountsResponse response = await service.accounts(jwtToken);

    expect(response.accounts.length, 2);
    expect(response.accounts[0].address,
        "GBND3FJRQBNFJ4ACERGEXUXU4RKK3ZV2N3FRRFU3ONYU6SJUN6EZXPTD");

    // Check identities on first account
    expect(response.accounts[0].identities.length, 1);
    expect(response.accounts[0].identities[0].role, "owner");
    expect(response.accounts[0].identities[0].authenticated, true);
  });

  test('sep-30: Listing Accounts with pagination', () async {
    // Snippet from sep-30.md "Listing Accounts" (pagination)
    final service = SEP30RecoveryService(recoveryServer);
    service.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      if (request.method == "GET" &&
          request.url.toString().contains("accounts") &&
          authHeader.contains(jwtToken)) {
        // Check if "after" query parameter is present for pagination
        if (request.url.queryParameters.containsKey("after")) {
          // Return empty second page
          return http.Response('{"accounts": []}', 200);
        }
        return http.Response(requestListSuccess(), 200);
      }
      return http.Response(json.encode({'error': "Bad request"}), 400);
    });

    SEP30AccountsResponse response = await service.accounts(jwtToken);
    expect(response.accounts.isNotEmpty, true);

    // Next page: pass the last account address as cursor
    final lastAddress = response.accounts.last.address;
    SEP30AccountsResponse nextPage =
        await service.accounts(jwtToken, after: lastAddress);
    expect(nextPage.accounts.length, 0);
  });

  // -- Section: Deleting a Registration --

  test('sep-30: Deleting a Registration', () async {
    // Snippet from sep-30.md "Deleting a Registration"
    final service = SEP30RecoveryService(recoveryServer);
    service.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      if (request.method == "DELETE" &&
          request.url.toString().contains("accounts") &&
          request.url.toString().contains(addressA) &&
          authHeader.contains(jwtToken)) {
        return http.Response(requestDetailsSuccess(), 200);
      }
      if (request.method == "GET" &&
          request.url.toString().contains("accounts") &&
          request.url.toString().contains(addressA) &&
          authHeader.contains(jwtToken)) {
        return http.Response(requestDetailsSuccess(), 200);
      }
      return http.Response(json.encode({'error': "Bad request"}), 400);
    });

    // Get signer key before deletion
    final details = await service.accountDetails(addressA, jwtToken);
    final signerToRemove = details.signers[0].key;
    expect(signerToRemove, signingAddress);

    // Delete from recovery server
    SEP30AccountResponse response =
        await service.deleteAccount(addressA, jwtToken);
    expect(response.address, addressA);
    expect(response.identities.length, 2);
    expect(response.signers.length, 1);
  });

  // -- Section: Error Handling --

  test('sep-30: Error Handling - Bad Request (400)', () async {
    // Snippet from sep-30.md "Error Handling"
    final service = SEP30RecoveryService(recoveryServer);
    service.httpClient = MockClient((request) async {
      return http.Response(
          json.encode({'error': "Invalid request data"}), 400);
    });

    final emailAuth = SEP30AuthMethod("email", "user@example.com");
    final ownerIdentity = SEP30RequestIdentity("owner", [emailAuth]);
    final request = SEP30Request([ownerIdentity]);

    try {
      await service.registerAccount(addressA, request, jwtToken);
      fail("Should have thrown");
    } on SEP30BadRequestResponseException catch (e) {
      expect(e.error, "Invalid request data");
    }
  });

  test('sep-30: Error Handling - Unauthorized (401)', () async {
    // Snippet from sep-30.md "Error Handling"
    final service = SEP30RecoveryService(recoveryServer);
    service.httpClient = MockClient((request) async {
      return http.Response(
          json.encode({'error': "JWT token expired"}), 401);
    });

    final emailAuth = SEP30AuthMethod("email", "user@example.com");
    final ownerIdentity = SEP30RequestIdentity("owner", [emailAuth]);
    final request = SEP30Request([ownerIdentity]);

    try {
      await service.registerAccount(addressA, request, jwtToken);
      fail("Should have thrown");
    } on SEP30UnauthorizedResponseException catch (e) {
      expect(e.error, "JWT token expired");
    }
  });

  test('sep-30: Error Handling - Not Found (404)', () async {
    // Snippet from sep-30.md "Error Handling"
    final service = SEP30RecoveryService(recoveryServer);
    service.httpClient = MockClient((request) async {
      return http.Response(
          json.encode({'error': "Account not registered"}), 404);
    });

    final emailAuth = SEP30AuthMethod("email", "user@example.com");
    final ownerIdentity = SEP30RequestIdentity("owner", [emailAuth]);
    final request = SEP30Request([ownerIdentity]);

    try {
      await service.registerAccount(addressA, request, jwtToken);
      fail("Should have thrown");
    } on SEP30NotFoundResponseException catch (e) {
      expect(e.error, "Account not registered");
    }
  });

  test('sep-30: Error Handling - Conflict (409)', () async {
    // Snippet from sep-30.md "Error Handling"
    final service = SEP30RecoveryService(recoveryServer);
    service.httpClient = MockClient((request) async {
      return http.Response(
          json.encode({'error': "Account already registered"}), 409);
    });

    final emailAuth = SEP30AuthMethod("email", "user@example.com");
    final ownerIdentity = SEP30RequestIdentity("owner", [emailAuth]);
    final request = SEP30Request([ownerIdentity]);

    try {
      await service.registerAccount(addressA, request, jwtToken);
      fail("Should have thrown");
    } on SEP30ConflictResponseException catch (e) {
      expect(e.error, "Account already registered");
    }
  });

  test('sep-30: Error Handling - Unknown (5xx)', () async {
    // Snippet from sep-30.md "Error Handling"
    final service = SEP30RecoveryService(recoveryServer);
    service.httpClient = MockClient((request) async {
      return http.Response("Internal Server Error", 500);
    });

    final emailAuth = SEP30AuthMethod("email", "user@example.com");
    final ownerIdentity = SEP30RequestIdentity("owner", [emailAuth]);
    final request = SEP30Request([ownerIdentity]);

    try {
      await service.registerAccount(addressA, request, jwtToken);
      fail("Should have thrown");
    } on SEP30UnknownResponseException catch (e) {
      expect(e.code, 500);
      expect(e.body, "Internal Server Error");
    }
  });

  // -- Section: Request and Response Objects --

  test('sep-30: SEP30AuthMethod construction', () {
    // Snippet from sep-30.md "Request and Response Objects"
    final emailAuth = SEP30AuthMethod("email", "person@example.com");
    final phoneAuth = SEP30AuthMethod("phone_number", "+10000000001");
    final stellarAuth = SEP30AuthMethod("stellar_address",
        "GBUCAAMD7DYS7226CWUUOZ5Y2QF4JBJWIYU3UWJAFDGJVCR6EU5NJM5H");

    expect(emailAuth.type, "email");
    expect(emailAuth.value, "person@example.com");
    expect(phoneAuth.type, "phone_number");
    expect(phoneAuth.value, "+10000000001");
    expect(stellarAuth.type, "stellar_address");
    expect(stellarAuth.value,
        "GBUCAAMD7DYS7226CWUUOZ5Y2QF4JBJWIYU3UWJAFDGJVCR6EU5NJM5H");
  });

  test('sep-30: SEP30RequestIdentity construction', () {
    // Snippet from sep-30.md "Request and Response Objects"
    final emailAuth = SEP30AuthMethod("email", "user@example.com");
    final identity = SEP30RequestIdentity("owner", [emailAuth]);

    expect(identity.role, "owner");
    expect(identity.authMethods.length, 1);
    expect(identity.authMethods[0].type, "email");
  });

  test('sep-30: SEP30Request construction', () {
    // Snippet from sep-30.md "Request and Response Objects"
    final emailAuth = SEP30AuthMethod("email", "user@example.com");
    final identity = SEP30RequestIdentity("owner", [emailAuth]);
    final request = SEP30Request([identity]);

    expect(request.identities.length, 1);
    expect(request.identities[0].role, "owner");
  });

  // -- Section: Common Pitfalls --

  test('sep-30: Common Pitfall - re-registering throws conflict', () async {
    // Snippet from sep-30.md "Common Pitfalls" - re-registering
    final service = SEP30RecoveryService(recoveryServer);
    service.httpClient = MockClient((request) async {
      if (request.method == "POST") {
        return http.Response(
            json.encode({'error': "Account already registered"}), 409);
      }
      if (request.method == "PUT") {
        return http.Response(requestRegisterSuccess(), 200);
      }
      return http.Response(json.encode({'error': "Bad request"}), 400);
    });

    final emailAuth = SEP30AuthMethod("email", "user@example.com");
    final ownerIdentity = SEP30RequestIdentity("owner", [emailAuth]);
    final request = SEP30Request([ownerIdentity]);

    // WRONG: registerAccount on already-registered account throws conflict
    try {
      await service.registerAccount(addressA, request, jwtToken);
      fail("Should have thrown");
    } on SEP30ConflictResponseException {
      // expected
    }

    // CORRECT: use updateIdentitiesForAccount
    SEP30AccountResponse response =
        await service.updateIdentitiesForAccount(addressA, request, jwtToken);
    expect(response.address, addressA);
  });

  test('sep-30: Common Pitfall - signatureHint from signing address', () {
    // Snippet from sep-30.md "Common Pitfalls" - signature hint
    // CORRECT: use the signing address (server's signer key)
    final hint = KeyPair.fromAccountId(signingAddress).signatureHint;
    expect(hint.signatureHint.length, 4);

    // Verify the signature can be constructed
    final signatureBytes = base64Decode(
        "YpVelqPYVKxb8pH08s5AKsYTPwQhbaeSlgcktqwAKsYTPwQhbaeS");
    final decoratedSig =
        XdrDecoratedSignature(hint, XdrSignature(signatureBytes));
    expect(decoratedSig, isNotNull);
  });

  test('sep-30: Common Pitfall - phone number format', () {
    // Snippet from sep-30.md "Common Pitfalls" - phone number format
    // CORRECT: E.164 format
    final phone = SEP30AuthMethod("phone_number", "+14155551234");
    expect(phone.type, "phone_number");
    expect(phone.value, "+14155551234");
  });

  test('sep-30: Common Pitfall - null-check authenticated', () async {
    // Snippet from sep-30.md "Common Pitfalls" - authenticated is bool?
    final service = SEP30RecoveryService(recoveryServer);
    service.httpClient = MockClient((request) async {
      if (request.method == "GET") {
        return http.Response(requestDetailsSuccess(), 200);
      }
      return http.Response(json.encode({'error': "Bad request"}), 400);
    });

    SEP30AccountResponse response =
        await service.accountDetails(addressA, jwtToken);

    // CORRECT: explicit comparison with bool?
    if (response.identities[0].authenticated == true) {
      expect(true, true); // authenticated identity
    }

    // CORRECT: null-coalescing
    final isAuth = response.identities[0].authenticated ?? false;
    expect(isAuth, true);

    // Second identity is not authenticated (null or false)
    final isAuth2 = response.identities[1].authenticated ?? false;
    expect(isAuth2, false);
  });
}
