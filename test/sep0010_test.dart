@Timeout(const Duration(seconds: 400))
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/src/sep/0010/webauth.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';

void main() {

  final domain = "place.domain.com";
  final authServer = "http://api.stellar.org/auth";

  final serverAccountId =
      "GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP";
  final serverSecretSeed =
      "SAWDHXQG6ROJSU4QGCW7NSTYFHPTPIVC2NC7QKVTO7PZCSO2WEBGM54W";
  final serverKeyPair = KeyPair.fromSecretSeed(serverSecretSeed);

  final clientAccountId =
      "GB4L7JUU5DENUXYH3ANTLVYQL66KQLDDJTN5SF7MWEDGWSGUA375V44V";
  final clientSecretSeed =
      "SBAYNYLQFXVLVAHW4BXDQYNJLMDQMZ5NQDDOHVJD3PTBAUIJRNRK5LGX";

  final wrongServerSecretSeed =
      "SAT4GUGO2N7RVVVD2TSL7TZ6T5A6PM7PJD5NUGQI5DDH67XO4KNO2QOW";
  final String successJWTToken =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJHQTZVSVhYUEVXWUZJTE5VSVdBQzM3WTRRUEVaTVFWREpIREtWV0ZaSjJLQ1dVQklVNUlYWk5EQSIsImp0aSI6IjE0NGQzNjdiY2IwZTcyY2FiZmRiZGU2MGVhZTBhZDczM2NjNjVkMmE2NTg3MDgzZGFiM2Q2MTZmODg1MTkwMjQiLCJpc3MiOiJodHRwczovL2ZsYXBweS1iaXJkLWRhcHAuZmlyZWJhc2VhcHAuY29tLyIsImlhdCI6MTUzNDI1Nzk5NCwiZXhwIjoxNTM0MzQ0Mzk0fQ.8nbB83Z6vGBgC1X9r3N6oQCFTBzDiITAfCJasRft0z0";

  final Random _random = Random.secure();

  Uint8List generateNonce([int length = 64]) {
    var values = List<int>.generate(length, (i) => _random.nextInt(256));
    return Uint8List.fromList(base64Url.encode(values).codeUnits);
  }

  TimeBounds validTimeBounds() {
    return TimeBounds(DateTime.now().millisecondsSinceEpoch,
        DateTime.now().millisecondsSinceEpoch + 3000);
  }

  TimeBounds invalidTimeBounds() {
    return TimeBounds(DateTime.now().millisecondsSinceEpoch - 6000,
        DateTime.now().millisecondsSinceEpoch - 3000);
  }

  ManageDataOperation validFirstManageDataOp(String accountId) {
    final ManageDataOperationBuilder builder =
        ManageDataOperationBuilder(domain + " auth", generateNonce())
            .setSourceAccount(accountId);
    return builder.build();
  }

  ManageDataOperation invalidHomeDomainOp(String accountId) {
    final ManageDataOperationBuilder builder =
        ManageDataOperationBuilder("fake.com" + " auth", generateNonce())
            .setSourceAccount(accountId);
    return builder.build();
  }

  ManageDataOperation validSecondManageDataOp() {
    final ManageDataOperationBuilder builder = ManageDataOperationBuilder(
            "web_auth_domain", Uint8List.fromList("api.stellar.org".codeUnits))
        .setSourceAccount(serverAccountId);
    return builder.build();
  }

  ManageDataOperation secondManageDataOpInvalidSourceAccount() {
    final ManageDataOperationBuilder builder = ManageDataOperationBuilder(
            "web_auth_domain", Uint8List.fromList("api.stellar.org".codeUnits))
        .setSourceAccount(clientAccountId); // invalid, must be server
    return builder.build();
  }

  ManageDataOperation invalidWebAuthOp() {
    final ManageDataOperationBuilder builder = ManageDataOperationBuilder(
            "web_auth_domain", Uint8List.fromList("api.fake.org".codeUnits))
        .setSourceAccount(serverAccountId);
    return builder.build();
  }

  String requestChallengeSuccess(String accountId) {
    final transactionAccount = Account(serverAccountId, -1);
    final Transaction transaction = new TransactionBuilder(transactionAccount)
        .addOperation(validFirstManageDataOp(accountId))
        .addOperation(validSecondManageDataOp())
        .addMemo(Memo.none())
        .addTimeBounds(validTimeBounds())
        .build();
    transaction.sign(serverKeyPair, Network.TESTNET);
    final mapJson = {'transaction': transaction.toEnvelopeXdrBase64()};
    return json.encode(mapJson);
  }

  String requestChallengeInvalidSequenceNumber(String accountId) {
    final transactionAccount = Account(serverAccountId, 2803983);
    final Transaction transaction = new TransactionBuilder(transactionAccount)
        .addOperation(validFirstManageDataOp(accountId))
        .addOperation(validSecondManageDataOp())
        .addMemo(Memo.none())
        .addTimeBounds(validTimeBounds())
        .build();
    transaction.sign(serverKeyPair, Network.TESTNET);
    final mapJson = {'transaction': transaction.toEnvelopeXdrBase64()};
    return json.encode(mapJson);
  }

  String requestChallengeInvalidFirstOpSourceAccount() {
    final transactionAccount = Account(serverAccountId, -1);
    final Transaction transaction = new TransactionBuilder(transactionAccount)
        .addOperation(validFirstManageDataOp(
            serverAccountId)) // invalid because must be client account id
        .addOperation(validSecondManageDataOp())
        .addMemo(Memo.none())
        .addTimeBounds(validTimeBounds())
        .build();
    transaction.sign(serverKeyPair, Network.TESTNET);
    final mapJson = {'transaction': transaction.toEnvelopeXdrBase64()};
    return json.encode(mapJson);
  }

  String requestChallengeInvalidSecondOpSourceAccount(String accountId) {
    final transactionAccount = Account(serverAccountId, -1);
    final Transaction transaction = new TransactionBuilder(transactionAccount)
        .addOperation(validFirstManageDataOp(accountId))
        .addOperation(secondManageDataOpInvalidSourceAccount())
        .addMemo(Memo.none())
        .addTimeBounds(validTimeBounds())
        .build();
    transaction.sign(serverKeyPair, Network.TESTNET);
    final mapJson = {'transaction': transaction.toEnvelopeXdrBase64()};
    return json.encode(mapJson);
  }

  String requestChallengeInvalidHomeDomain(String accountId) {
    final transactionAccount = Account(serverAccountId, -1);
    final Transaction transaction = new TransactionBuilder(transactionAccount)
        .addOperation(invalidHomeDomainOp(accountId))
        .addOperation(validSecondManageDataOp())
        .addMemo(Memo.none())
        .addTimeBounds(validTimeBounds())
        .build();
    transaction.sign(serverKeyPair, Network.TESTNET);
    final mapJson = {'transaction': transaction.toEnvelopeXdrBase64()};
    return json.encode(mapJson);
  }

  String requestChallengeInvalidWebAuth(String accountId) {
    final transactionAccount = Account(serverAccountId, -1);
    final Transaction transaction = new TransactionBuilder(transactionAccount)
        .addOperation(validFirstManageDataOp(accountId))
        .addOperation(invalidWebAuthOp())
        .addMemo(Memo.none())
        .addTimeBounds(validTimeBounds())
        .build();
    transaction.sign(serverKeyPair, Network.TESTNET);
    final mapJson = {'transaction': transaction.toEnvelopeXdrBase64()};
    return json.encode(mapJson);
  }

  String requestChallengeInvalidTimeBounds(String accountId) {
    final transactionAccount = Account(serverAccountId, -1);
    final Transaction transaction = new TransactionBuilder(transactionAccount)
        .addOperation(validFirstManageDataOp(accountId))
        .addOperation(validSecondManageDataOp())
        .addMemo(Memo.none())
        .addTimeBounds(invalidTimeBounds())
        .build();
    transaction.sign(serverKeyPair, Network.TESTNET);
    final mapJson = {'transaction': transaction.toEnvelopeXdrBase64()};
    return json.encode(mapJson);
  }

  String requestChallengeInvalidOperationType(String accountId) {
    final transactionAccount = Account(serverAccountId, -1);
    final Transaction transaction = new TransactionBuilder(transactionAccount)
        .addOperation(validFirstManageDataOp(accountId))
        .addOperation(validSecondManageDataOp())
        .addOperation(
            PaymentOperationBuilder(serverAccountId, Asset.NATIVE, "100")
                .setSourceAccount(serverAccountId)
                .build()) // not allowed.
        .addMemo(Memo.none())
        .addTimeBounds(validTimeBounds())
        .build();
    transaction.sign(serverKeyPair, Network.TESTNET);
    final mapJson = {'transaction': transaction.toEnvelopeXdrBase64()};
    return json.encode(mapJson);
  }

  String requestChallengeInvalidSignature(String accountId) {
    final transactionAccount = Account(serverAccountId, -1);
    final Transaction transaction = new TransactionBuilder(transactionAccount)
        .addOperation(validFirstManageDataOp(accountId))
        .addOperation(validSecondManageDataOp())
        .addMemo(Memo.none())
        .addTimeBounds(validTimeBounds())
        .build();
    final kp = KeyPair.fromSecretSeed(wrongServerSecretSeed);
    transaction.sign(kp, Network.TESTNET);
    final mapJson = {'transaction': transaction.toEnvelopeXdrBase64()};
    return json.encode(mapJson);
  }

  String requestChallengeMultipleSignature(String accountId) {
    final transactionAccount = Account(serverAccountId, -1);
    final Transaction transaction = new TransactionBuilder(transactionAccount)
        .addOperation(validFirstManageDataOp(accountId))
        .addOperation(validSecondManageDataOp())
        .addMemo(Memo.none())
        .addTimeBounds(validTimeBounds())
        .build();
    transaction.sign(serverKeyPair, Network.TESTNET);
    final kp = KeyPair.fromSecretSeed(wrongServerSecretSeed);
    transaction.sign(kp, Network.TESTNET);
    final mapJson = {'transaction': transaction.toEnvelopeXdrBase64()};
    return json.encode(mapJson);
  }

  String requestJWTSuccess() {
    final mapJson = {'token': successJWTToken};
    return json.encode(mapJson);
  }

  test('test success', () async {
    final webAuth =
        WebAuth(authServer, Network.TESTNET, serverAccountId, domain);
    webAuth.httpClient = MockClient((request) async {
      if (request.url.toString().startsWith(authServer) &&
          request.method == "GET" &&
          request.url.toString().contains(clientAccountId)) {
        return http.Response(requestChallengeSuccess(clientAccountId), 200);
      }
      if (request.url.toString().startsWith(authServer) &&
          request.method == "POST") {
        // validate if the challenge transaction has been signed by the client
        String signedTransaction = request.body;
        XdrTransactionEnvelope envelopeXdr =
            XdrTransactionEnvelope.fromEnvelopeXdrString(signedTransaction);
        final signatures = envelopeXdr.v1.signatures;
        if (signatures.length == 2) {
          final clientSignature = envelopeXdr.v1.signatures[1];
          final clientKeyPair = KeyPair.fromAccountId(clientAccountId);
          final transactionHash =
              AbstractTransaction.fromEnvelopeXdr(envelopeXdr)
                  .hash(Network.TESTNET);
          final valid = clientKeyPair.verify(
              transactionHash, clientSignature.signature.signature);
          if (valid) {
            return http.Response(requestJWTSuccess(), 200); // OK
          }
        }
      }
      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    String jwtToken =
        await webAuth.jwtToken(KeyPair.fromSecretSeed(clientSecretSeed));
    assert(jwtToken == successJWTToken);
  });

  test('test get challenge failure', () async {
    final webAuth =
        WebAuth(authServer, Network.TESTNET, serverAccountId, domain);
    webAuth.httpClient = MockClient((request) async {
      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });
    try {
      String jwtToken =
          await webAuth.jwtToken(KeyPair.fromSecretSeed(clientSecretSeed));
    } catch (e) {
      print(e.toString());
      assert(e is ChallengeRequestErrorResponse);
      return;
    }
    assert(false);
  });

  test('test get challenge invalid sequence number', () async {
    final webAuth =
        WebAuth(authServer, Network.TESTNET, serverAccountId, domain);
    webAuth.httpClient = MockClient((request) async {
      if (request.url.toString().startsWith(authServer) &&
          request.method == "GET" &&
          request.url.toString().contains(clientAccountId)) {
        return http.Response(
            requestChallengeInvalidSequenceNumber(clientAccountId), 200);
      }
      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });
    try {
      String jwtToken =
          await webAuth.jwtToken(KeyPair.fromSecretSeed(clientSecretSeed));
    } catch (e) {
      print(e.toString());
      assert(e is ChallengeValidationErrorInvalidSeqNr);
      return;
    }
    assert(false);
  });

  test('test get challenge invalid first op source account', () async {
    final webAuth =
        WebAuth(authServer, Network.TESTNET, serverAccountId, domain);
    webAuth.httpClient = MockClient((request) async {
      if (request.url.toString().startsWith(authServer) &&
          request.method == "GET" &&
          request.url.toString().contains(clientAccountId)) {
        return http.Response(
            requestChallengeInvalidFirstOpSourceAccount(), 200);
      }
      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });
    try {
      String jwtToken =
          await webAuth.jwtToken(KeyPair.fromSecretSeed(clientSecretSeed));
    } catch (e) {
      print(e.toString());
      assert(e is ChallengeValidationErrorInvalidSourceAccount);
      return;
    }
    assert(false);
  });

  test('test get challenge invalid second op source account', () async {
    final webAuth =
        WebAuth(authServer, Network.TESTNET, serverAccountId, domain);
    webAuth.httpClient = MockClient((request) async {
      if (request.url.toString().startsWith(authServer) &&
          request.method == "GET" &&
          request.url.toString().contains(clientAccountId)) {
        return http.Response(
            requestChallengeInvalidSecondOpSourceAccount(clientAccountId), 200);
      }
      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });
    try {
      String jwtToken =
          await webAuth.jwtToken(KeyPair.fromSecretSeed(clientSecretSeed));
    } catch (e) {
      print(e.toString());
      assert(e is ChallengeValidationErrorInvalidSourceAccount);
      return;
    }
    assert(false);
  });

  test('test get challenge invalid home domain', () async {
    final webAuth =
        WebAuth(authServer, Network.TESTNET, serverAccountId, domain);
    webAuth.httpClient = MockClient((request) async {
      if (request.url.toString().startsWith(authServer) &&
          request.method == "GET" &&
          request.url.toString().contains(clientAccountId)) {
        return http.Response(
            requestChallengeInvalidHomeDomain(clientAccountId), 200);
      }
      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });
    try {
      String jwtToken =
          await webAuth.jwtToken(KeyPair.fromSecretSeed(clientSecretSeed));
    } catch (e) {
      print(e.toString());
      assert(e is ChallengeValidationErrorInvalidHomeDomain);
      return;
    }
    assert(false);
  });

  test('test get challenge invalid web auth domain', () async {
    final webAuth =
        WebAuth(authServer, Network.TESTNET, serverAccountId, domain);
    webAuth.httpClient = MockClient((request) async {
      if (request.url.toString().startsWith(authServer) &&
          request.method == "GET" &&
          request.url.toString().contains(clientAccountId)) {
        return http.Response(
            requestChallengeInvalidWebAuth(clientAccountId), 200);
      }
      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });
    try {
      String jwtToken =
          await webAuth.jwtToken(KeyPair.fromSecretSeed(clientSecretSeed));
    } catch (e) {
      print(e.toString());
      assert(e is ChallengeValidationErrorInvalidWebAuthDomain);
      return;
    }
    assert(false);
  });

  test('test get challenge invalid time bounds', () async {
    final webAuth =
        WebAuth(authServer, Network.TESTNET, serverAccountId, domain);
    webAuth.httpClient = MockClient((request) async {
      if (request.url.toString().startsWith(authServer) &&
          request.method == "GET" &&
          request.url.toString().contains(clientAccountId)) {
        return http.Response(
            requestChallengeInvalidTimeBounds(clientAccountId), 200);
      }
      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });
    try {
      String jwtToken =
          await webAuth.jwtToken(KeyPair.fromSecretSeed(clientSecretSeed));
    } catch (e) {
      print(e.toString());
      assert(e is ChallengeValidationErrorInvalidTimeBounds);
      return;
    }
    assert(false);
  });

  test('test get challenge invalid operation type', () async {
    final webAuth =
        WebAuth(authServer, Network.TESTNET, serverAccountId, domain);
    webAuth.httpClient = MockClient((request) async {
      if (request.url.toString().startsWith(authServer) &&
          request.method == "GET" &&
          request.url.toString().contains(clientAccountId)) {
        return http.Response(
            requestChallengeInvalidOperationType(clientAccountId), 200);
      }
      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });
    try {
      String jwtToken =
          await webAuth.jwtToken(KeyPair.fromSecretSeed(clientSecretSeed));
    } catch (e) {
      print(e.toString());
      assert(e is ChallengeValidationErrorInvalidOperationType);
      return;
    }
    assert(false);
  });

  test('test get challenge invalid signature', () async {
    final webAuth =
        WebAuth(authServer, Network.TESTNET, serverAccountId, domain);
    webAuth.httpClient = MockClient((request) async {
      if (request.url.toString().startsWith(authServer) &&
          request.method == "GET" &&
          request.url.toString().contains(clientAccountId)) {
        return http.Response(
            requestChallengeInvalidSignature(clientAccountId), 200);
      }
      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });
    try {
      String jwtToken =
          await webAuth.jwtToken(KeyPair.fromSecretSeed(clientSecretSeed));
    } catch (e) {
      print(e.toString());
      assert(e is ChallengeValidationErrorInvalidSignature);
      return;
    }
    assert(false);
  });

  test('test get challenge too many signatures', () async {
    final webAuth =
        WebAuth(authServer, Network.TESTNET, serverAccountId, domain);
    webAuth.httpClient = MockClient((request) async {
      if (request.url.toString().startsWith(authServer) &&
          request.method == "GET" &&
          request.url.toString().contains(clientAccountId)) {
        return http.Response(
            requestChallengeMultipleSignature(clientAccountId), 200);
      }
      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });
    try {
      String jwtToken =
          await webAuth.jwtToken(KeyPair.fromSecretSeed(clientSecretSeed));
    } catch (e) {
      print(e.toString());
      assert(e is ChallengeValidationErrorInvalidSignature);
      return;
    }
    assert(false);
  });
}
