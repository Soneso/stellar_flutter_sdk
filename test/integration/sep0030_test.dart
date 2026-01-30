@Timeout(const Duration(seconds: 400))
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  final recoveryServer = "http://api.stellar.org/recovery";

  final addressA = "GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP";

  final signingAddress =
      "GDRUPBJM7YIJ2NUNAIQJDJ2DQ2JDERY5SJVJVMM6MGE4UBDAMXBHARIA";

  final String jwtToken =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJHQTZVSVhYUEVXWUZJTE5VSVdBQzM3WTRRUEVaTVFWREpIREtWV0ZaSjJLQ1dVQklVNUlYWk5EQSIsImp0aSI6IjE0NGQzNjdiY2IwZTcyY2FiZmRiZGU2MGVhZTBhZDczM2NjNjVkMmE2NTg3MDgzZGFiM2Q2MTZmODg1MTkwMjQiLCJpc3MiOiJodHRwczovL2ZsYXBweS1iaXJkLWRhcHAuZmlyZWJhc2VhcHAuY29tLyIsImlhdCI6MTUzNDI1Nzk5NCwiZXhwIjoxNTM0MzQ0Mzk0fQ.8nbB83Z6vGBgC1X9r3N6oQCFTBzDiITAfCJasRft0z0";

  var senderAddrAuth = SEP30AuthMethod("stellar_address",
      "GBUCAAMD7DYS7226CWUUOZ5Y2QF4JBJWIYU3UWJAFDGJVCR6EU5NJM5H");
  var senderPhoneAuth = SEP30AuthMethod("phone_number", "+10000000001");
  var senderEmailAuth = SEP30AuthMethod("email", "person1@example.com");

  var receiverAddrAuth = SEP30AuthMethod("stellar_address",
      "GDIL76BC2XGDWLDPXCZVYB3AIZX4MYBN6JUBQPAX5OHRWPSNX3XMLNCS");
  var receiverPhoneAuth = SEP30AuthMethod("phone_number", "+10000000002");
  var receiverEmailAuth = SEP30AuthMethod("email", "person2@example.com");

  var senderIdentity = SEP30RequestIdentity(
      "sender", [senderAddrAuth, senderPhoneAuth, senderEmailAuth]);
  var receiverIdentity = SEP30RequestIdentity(
      "receiver", [receiverAddrAuth, receiverPhoneAuth, receiverEmailAuth]);

  String requestRegisterSuccess() {
    return "{  \"address\": \"GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP\",  \"identities\": [    { \"role\": \"sender\" },    { \"role\": \"receiver\" }  ],  \"signers\": [    { \"key\": \"GDRUPBJM7YIJ2NUNAIQJDJ2DQ2JDERY5SJVJVMM6MGE4UBDAMXBHARIA\" }  ]}";
  }

  String requestDetailsSuccess() {
    return "{  \"address\": \"GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP\",  \"identities\": [    { \"role\": \"sender\", \"authenticated\": true },    { \"role\": \"receiver\" }  ],  \"signers\": [    { \"key\": \"GDRUPBJM7YIJ2NUNAIQJDJ2DQ2JDERY5SJVJVMM6MGE4UBDAMXBHARIA\" }  ]}";
  }

  String requestSignSuccess() {
    return "{  \"signature\": \"YpVelqPYVKxb8pH08s5AKsYTPwQhbaeSlgcktqwAKsYTPwQhbaeS\",  \"network_passphrase\": \"Test SDF Network ; September 2015\"}";
  }

  String requestListSuccess() {
    return "{  \"accounts\": [    {      \"address\": \"GBND3FJRQBNFJ4ACERGEXUXU4RKK3ZV2N3FRRFU3ONYU6SJUN6EZXPTD\",      \"identities\": [        {\"role\": \"owner\",  \"authenticated\": true }      ],      \"signers\": [        { \"key\": \"GBTPAH6NWK25GESZYJ3XWPTNQUIMYNK7VU7R4NSTMZXOEKCOBKJVJ2XY\" }      ]    },    {      \"address\": \"GA7BLNSL55T2UAON5DYLQHJTR43IPT2O4QG6PAMSNLJJL7JMXKZYYVFJ\",      \"identities\": [        { \"role\": \"sender\", \"authenticated\": true },        { \"role\": \"receiver\" }     ],      \"signers\": [        { \"key\": \"GAOCJE4737GYN2EGCGWPNNCDVDKX7XKC4UKOKIF7CRRYIFLPZLH3U3UN\" }      ]    },    {      \"address\": \"GD62WD2XTOCAENMB34FB2SEW6JHPB7AFYQAJ5OCQ3TYRW5MOJXLKGTMM\",      \"identities\": [        { \"role\": \"sender\" },        { \"role\": \"receiver\", \"authenticated\": true }     ],      \"signers\": [        { \"key\": \"GDFPM46I2L2DXB3TWAKPMLUMEW226WXLRWJNS4QHXXKJXEUW3M6OAFBY\" }      ]    }  ]}";
  }

  var transaction =
      "AAAAAgAAAABswQhbaeSlgckYVKxb8pH08s5tqVVpGXYw1kCpbqv6lQAAAGQAIa4PAAAAAQAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAABQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAACWhlbGxvLmNvbQAAAAAAAAAAAAAAAAAAAA==";
  var signature = "YpVelqPYVKxb8pH08s5AKsYTPwQhbaeSlgcktqwAKsYTPwQhbaeS";
  var networkPassphrase = "Test SDF Network ; September 2015";

  test('test register account success', () async {
    final service = SEP30RecoveryService(recoveryServer);
    service.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      if (request.url.toString().startsWith(recoveryServer) &&
          request.method == "POST" &&
          request.url.toString().contains("accounts") &&
          request.url.toString().contains(addressA) &&
          authHeader.contains(jwtToken)) {
        var identities = json.decode(request.body)["identities"];
        assert(2 == identities.length);

        return http.Response(requestRegisterSuccess(), 200); // OK
      }
      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    var request = SEP30Request([senderIdentity, receiverIdentity]);
    SEP30AccountResponse response =
        await service.registerAccount(addressA, request, jwtToken);
    assert(addressA == response.address);
    assert(2 == response.identities.length);
    assert(1 == response.signers.length);
  });

  test('test update account success', () async {
    final service = SEP30RecoveryService(recoveryServer);
    service.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      if (request.url.toString().startsWith(recoveryServer) &&
          request.method == "PUT" &&
          request.url.toString().contains("accounts") &&
          request.url.toString().contains(addressA) &&
          authHeader.contains(jwtToken)) {
        var identities = json.decode(request.body)["identities"];
        assert(2 == identities.length);

        return http.Response(requestRegisterSuccess(), 200); // OK
      }
      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    var request = SEP30Request([senderIdentity, receiverIdentity]);
    SEP30AccountResponse response =
        await service.updateIdentitiesForAccount(addressA, request, jwtToken);
    assert(addressA == response.address);
    assert(2 == response.identities.length);
    assert(1 == response.signers.length);
  });

  test('test sign success', () async {
    final service = SEP30RecoveryService(recoveryServer);
    service.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      if (request.url.toString().startsWith(recoveryServer) &&
          request.method == "POST" &&
          request.url.toString().contains("accounts") &&
          request.url.toString().contains("sign") &&
          request.url.toString().contains(addressA) &&
          request.url.toString().contains(signingAddress) &&
          authHeader.contains(jwtToken)) {
        var tx = json.decode(request.body)["transaction"];
        assert(transaction == tx);

        return http.Response(requestSignSuccess(), 200); // OK
      }
      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    SEP30SignatureResponse response = await service.signTransaction(
        addressA, signingAddress, transaction, jwtToken);
    assert(signature == response.signature);
    assert(networkPassphrase == response.networkPassphrase);
  });

  test('test get account details success', () async {
    final service = SEP30RecoveryService(recoveryServer);
    service.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      if (request.url.toString().startsWith(recoveryServer) &&
          request.method == "GET" &&
          request.url.toString().contains("accounts") &&
          request.url.toString().contains(addressA) &&
          authHeader.contains(jwtToken)) {
        return http.Response(requestDetailsSuccess(), 200); // OK
      }
      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    SEP30AccountResponse response =
        await service.accountDetails(addressA, jwtToken);
    assert(addressA == response.address);
    assert(2 == response.identities.length);
    assert(1 == response.signers.length);
    assert(response.identities[0].authenticated!);
  });

  test('test get account delete success', () async {
    final service = SEP30RecoveryService(recoveryServer);
    service.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      if (request.url.toString().startsWith(recoveryServer) &&
          request.method == "DELETE" &&
          request.url.toString().contains("accounts") &&
          request.url.toString().contains(addressA) &&
          authHeader.contains(jwtToken)) {
        return http.Response(requestDetailsSuccess(), 200); // OK
      }
      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    SEP30AccountResponse response =
        await service.deleteAccount(addressA, jwtToken);
    assert(addressA == response.address);
    assert(2 == response.identities.length);
    assert(1 == response.signers.length);
    assert(response.identities[0].authenticated!);
  });

  test('test list accounts success', () async {
    final service = SEP30RecoveryService(recoveryServer);
    service.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      if (request.url.toString().startsWith(recoveryServer) &&
          request.method == "GET" &&
          request.url.toString().contains("accounts") &&
          request.url.queryParameters.length == 1 &&
          authHeader.contains(jwtToken)) {
        return http.Response(requestListSuccess(), 200); // OK
      }
      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    SEP30AccountsResponse response = await service.accounts(jwtToken,
        after: "GA5TKKASNJZGZAP6FH65HO77CST7CJNYRTW4YPBNPXYMZAHHMTHDZKDQ");
    assert(3 == response.accounts.length);
  });

  test('test bad request', () async {
    final service = SEP30RecoveryService(recoveryServer);
    service.httpClient = MockClient((request) async {
      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    try {
      var request = SEP30Request([senderIdentity, receiverIdentity]);
      await service.registerAccount(addressA, request, jwtToken);
    } catch (e) {
      assert(e is SEP30BadRequestResponseException);
      return;
    }
    assert(false);
  });

  test('test unauthorized', () async {
    final service = SEP30RecoveryService(recoveryServer);
    service.httpClient = MockClient((request) async {
      final mapJson = {'error': "unauthorized"};
      return http.Response(json.encode(mapJson), 401);
    });

    try {
      var request = SEP30Request([senderIdentity, receiverIdentity]);
      await service.registerAccount(addressA, request, jwtToken);
    } catch (e) {
      assert(e is SEP30UnauthorizedResponseException);
      return;
    }
    assert(false);
  });

  test('test not found', () async {
    final service = SEP30RecoveryService(recoveryServer);
    service.httpClient = MockClient((request) async {
      final mapJson = {'error': "not found"};
      return http.Response(json.encode(mapJson), 404);
    });

    try {
      var request = SEP30Request([senderIdentity, receiverIdentity]);
      await service.registerAccount(addressA, request, jwtToken);
    } catch (e) {
      assert(e is SEP30NotFoundResponseException);
      return;
    }
    assert(false);
  });

  test('test conflict', () async {
    final service = SEP30RecoveryService(recoveryServer);
    service.httpClient = MockClient((request) async {
      final mapJson = {'error': "conflict message"};
      return http.Response(json.encode(mapJson), 409);
    });

    try {
      var request = SEP30Request([senderIdentity, receiverIdentity]);
      await service.registerAccount(addressA, request, jwtToken);
    } catch (e) {
      assert(e is SEP30ConflictResponseException);
      return;
    }
    assert(false);
  });

}
