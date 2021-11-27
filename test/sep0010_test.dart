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
  final clientAccountIdM =
      "MB4L7JUU5DENUXYH3ANTLVYQL66KQLDDJTN5SF7MWEDGWSGUA375UAAAAAAACMICQP7P4";
  final int testMemo = 19989123;

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
    return TimeBounds(DateTime.now().millisecondsSinceEpoch ~/ 1000,
        DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3);
  }

  TimeBounds invalidTimeBounds() {
    return TimeBounds(DateTime.now().millisecondsSinceEpoch ~/ 1000 - 700,
        DateTime.now().millisecondsSinceEpoch ~/ 1000 - 400);
  }

  ManageDataOperation validFirstManageDataOp(String accountId) {
    MuxedAccount? muxedAccount = MuxedAccount.fromAccountId(accountId);
    final ManageDataOperationBuilder builder =
        ManageDataOperationBuilder(domain + " auth", generateNonce())
            .setMuxedSourceAccount(muxedAccount);
    return builder.build();
  }

  ManageDataOperation invalidClientDomainManageDataOp() {
    final ManageDataOperationBuilder builder = ManageDataOperationBuilder(
            "client_domain", Uint8List.fromList("place.client.com".codeUnits))
        .setSourceAccount(serverAccountId);
    return builder.build();
  }

  ManageDataOperation validClientDomainManageDataOp(
      String clientDomainAccountId) {
    final ManageDataOperationBuilder builder = ManageDataOperationBuilder(
            "client_domain", Uint8List.fromList("place.client.com".codeUnits))
        .setSourceAccount(clientDomainAccountId);
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

  Memo memoForId(int? id) {
    if (id != null) {
      return MemoId(id);
    }
    return Memo.none();
  }

  String requestChallengeSuccess(String accountId, [int? memo]) {
    final transactionAccount = Account(serverAccountId, -1);
    final Transaction transaction = new TransactionBuilder(transactionAccount)
        .addOperation(validFirstManageDataOp(accountId))
        .addOperation(validSecondManageDataOp())
        .addMemo(memoForId(memo))
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

  String requestChallengeInvalidClientDomainOpSourceAccount(String accountId) {
    final transactionAccount = Account(serverAccountId, -1);
    final Transaction transaction = new TransactionBuilder(transactionAccount)
        .addOperation(validFirstManageDataOp(accountId))
        .addOperation(validSecondManageDataOp())
        .addOperation(invalidClientDomainManageDataOp())
        .addMemo(Memo.none())
        .addTimeBounds(validTimeBounds())
        .build();
    transaction.sign(serverKeyPair, Network.TESTNET);
    final mapJson = {'transaction': transaction.toEnvelopeXdrBase64()};
    return json.encode(mapJson);
  }

  String requestChallengeValidClientDomainOpSourceAccount(
      String accountId, String clientDomainAccountId) {
    final transactionAccount = Account(serverAccountId, -1);
    final Transaction transaction = new TransactionBuilder(transactionAccount)
        .addOperation(validFirstManageDataOp(accountId))
        .addOperation(validSecondManageDataOp())
        .addOperation(validClientDomainManageDataOp(clientDomainAccountId))
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

  String requestChallengeInvalidMemoType(String accountId) {
    final transactionAccount = Account(serverAccountId, -1);
    final Transaction transaction = new TransactionBuilder(transactionAccount)
        .addOperation(validFirstManageDataOp(accountId))
        .addOperation(validSecondManageDataOp())
        .addMemo(MemoText("blue sky"))
        .addTimeBounds(validTimeBounds())
        .build();
    transaction.sign(serverKeyPair, Network.TESTNET);
    final mapJson = {'transaction': transaction.toEnvelopeXdrBase64()};
    return json.encode(mapJson);
  }

  String requestChallengeInvalidMemoValue(String accountId) {
    final transactionAccount = Account(serverAccountId, -1);
    final Transaction transaction = new TransactionBuilder(transactionAccount)
        .addOperation(validFirstManageDataOp(accountId))
        .addOperation(validSecondManageDataOp())
        .addMemo(memoForId(testMemo - 200))
        .addTimeBounds(validTimeBounds())
        .build();
    transaction.sign(serverKeyPair, Network.TESTNET);
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

  test('test default success', () async {
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
        final signatures = envelopeXdr.v1!.signatures;
        if (signatures!.length == 2) {
          final clientSignature = envelopeXdr.v1!.signatures![1];
          final clientKeyPair = KeyPair.fromAccountId(clientAccountId);
          final transactionHash =
              AbstractTransaction.fromEnvelopeXdr(envelopeXdr)
                  .hash(Network.TESTNET);
          final valid = clientKeyPair.verify(
              transactionHash!, clientSignature!.signature!.signature!);
          if (valid) {
            return http.Response(requestJWTSuccess(), 200); // OK
          }
        }
      }
      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    KeyPair userKeyPair = KeyPair.fromSecretSeed(clientSecretSeed);
    String userAccountId = userKeyPair.accountId;
    String jwtToken = await webAuth.jwtToken(userAccountId, [userKeyPair]);
    assert(jwtToken == successJWTToken);
  });

  test('test memo success', () async {
    final webAuth =
        WebAuth(authServer, Network.TESTNET, serverAccountId, domain);
    webAuth.httpClient = MockClient((request) async {
      if (request.url.toString().startsWith(authServer) &&
          request.method == "GET" &&
          request.url.toString().contains(clientAccountId)) {
        return http.Response(
            requestChallengeSuccess(clientAccountId, testMemo), 200);
      }
      if (request.url.toString().startsWith(authServer) &&
          request.method == "POST") {
        // validate if the challenge transaction has been signed by the client
        String signedTransaction = request.body;
        XdrTransactionEnvelope envelopeXdr =
            XdrTransactionEnvelope.fromEnvelopeXdrString(signedTransaction);
        final signatures = envelopeXdr.v1!.signatures;
        if (signatures!.length == 2) {
          final clientSignature = envelopeXdr.v1!.signatures![1];
          final clientKeyPair = KeyPair.fromAccountId(clientAccountId);
          final transactionHash =
              AbstractTransaction.fromEnvelopeXdr(envelopeXdr)
                  .hash(Network.TESTNET);
          final valid = clientKeyPair.verify(
              transactionHash!, clientSignature!.signature!.signature!);
          if (valid) {
            return http.Response(requestJWTSuccess(), 200); // OK
          }
        }
      }
      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    KeyPair userKeyPair = KeyPair.fromSecretSeed(clientSecretSeed);
    String userAccountId = userKeyPair.accountId;
    String jwtToken =
        await webAuth.jwtToken(userAccountId, [userKeyPair], memo: testMemo);
    assert(jwtToken == successJWTToken);
  });

  test('test muxed success', () async {
    final webAuth =
        WebAuth(authServer, Network.TESTNET, serverAccountId, domain);
    webAuth.httpClient = MockClient((request) async {
      if (request.url.toString().startsWith(authServer) &&
          request.method == "GET" &&
          request.url.toString().contains(clientAccountIdM)) {
        return http.Response(requestChallengeSuccess(clientAccountIdM), 200);
      }
      if (request.url.toString().startsWith(authServer) &&
          request.method == "POST") {
        // validate if the challenge transaction has been signed by the client
        String signedTransaction = request.body;
        XdrTransactionEnvelope envelopeXdr =
            XdrTransactionEnvelope.fromEnvelopeXdrString(signedTransaction);
        final signatures = envelopeXdr.v1!.signatures;
        if (signatures!.length == 2) {
          final clientSignature = envelopeXdr.v1!.signatures![1];
          final clientKeyPair = KeyPair.fromAccountId(clientAccountIdM);
          final transactionHash =
              AbstractTransaction.fromEnvelopeXdr(envelopeXdr)
                  .hash(Network.TESTNET);
          final valid = clientKeyPair.verify(
              transactionHash!, clientSignature!.signature!.signature!);
          if (valid) {
            return http.Response(requestJWTSuccess(), 200); // OK
          }
        }
      }
      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    KeyPair userKeyPair = KeyPair.fromSecretSeed(clientSecretSeed);
    String jwtToken = await webAuth.jwtToken(clientAccountIdM, [userKeyPair]);
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
      KeyPair userKeyPair = KeyPair.fromSecretSeed(clientSecretSeed);
      String userAccountId = userKeyPair.accountId;
      String jwtToken = await webAuth.jwtToken(userAccountId, [userKeyPair]);
    } catch (e) {
      print(e.toString());
      assert(e is ChallengeRequestErrorResponse);
      return;
    }
    assert(false);
  });

  test('test invalid added memo and muxed', () async {
    final webAuth =
        WebAuth(authServer, Network.TESTNET, serverAccountId, domain);
    try {
      KeyPair userKeyPair = KeyPair.fromSecretSeed(clientSecretSeed);
      String jwtToken = await webAuth.jwtToken(clientAccountIdM, [userKeyPair],
          memo: testMemo);
      print(jwtToken);
    } catch (e) {
      print(e.toString());
      assert(true);
      return;
    }
    assert(false);
  });

  test('test get challenge invalid memo type', () async {
    final webAuth =
        WebAuth(authServer, Network.TESTNET, serverAccountId, domain);
    webAuth.httpClient = MockClient((request) async {
      if (request.url.toString().startsWith(authServer) &&
          request.method == "GET" &&
          request.url.toString().contains(clientAccountId)) {
        return http.Response(
            requestChallengeInvalidMemoType(clientAccountId), 200);
      }
      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });
    try {
      KeyPair userKeyPair = KeyPair.fromSecretSeed(clientSecretSeed);
      String userAccountId = userKeyPair.accountId;
      String jwtToken =
          await webAuth.jwtToken(userAccountId, [userKeyPair], memo: testMemo);
    } catch (e) {
      print(e.toString());
      assert(e is ChallengeValidationErrorInvalidMemoType);
      return;
    }
    assert(false);
  });

  test('test get challenge invalid memo value', () async {
    final webAuth =
        WebAuth(authServer, Network.TESTNET, serverAccountId, domain);
    webAuth.httpClient = MockClient((request) async {
      if (request.url.toString().startsWith(authServer) &&
          request.method == "GET" &&
          request.url.toString().contains(clientAccountId)) {
        return http.Response(
            requestChallengeInvalidMemoValue(clientAccountId), 200);
      }
      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });
    try {
      KeyPair userKeyPair = KeyPair.fromSecretSeed(clientSecretSeed);
      String userAccountId = userKeyPair.accountId;
      String jwtToken =
          await webAuth.jwtToken(userAccountId, [userKeyPair], memo: testMemo);
    } catch (e) {
      print(e.toString());
      assert(e is ChallengeValidationErrorInvalidMemoValue);
      return;
    }
    assert(false);
  });

  test('test get challenge invalid server mix memo and muxed', () async {
    final webAuth =
        WebAuth(authServer, Network.TESTNET, serverAccountId, domain);
    webAuth.httpClient = MockClient((request) async {
      if (request.url.toString().startsWith(authServer) &&
          request.method == "GET" &&
          request.url.toString().contains(clientAccountIdM)) {
        return http.Response(
            requestChallengeSuccess(clientAccountIdM, testMemo), 200);
      }
      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });
    try {
      KeyPair userKeyPair = KeyPair.fromSecretSeed(clientSecretSeed);
      String jwtToken = await webAuth.jwtToken(clientAccountIdM, [userKeyPair]);
    } catch (e) {
      print(e.toString());
      assert(e is ChallengeValidationErrorMemoAndMuxedAccount);
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
      KeyPair userKeyPair = KeyPair.fromSecretSeed(clientSecretSeed);
      String userAccountId = userKeyPair.accountId;
      String jwtToken = await webAuth.jwtToken(userAccountId, [userKeyPair]);
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
      KeyPair userKeyPair = KeyPair.fromSecretSeed(clientSecretSeed);
      String userAccountId = userKeyPair.accountId;
      String jwtToken = await webAuth.jwtToken(userAccountId, [userKeyPair]);
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
      KeyPair userKeyPair = KeyPair.fromSecretSeed(clientSecretSeed);
      String userAccountId = userKeyPair.accountId;
      String jwtToken = await webAuth.jwtToken(userAccountId, [userKeyPair]);
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
      KeyPair userKeyPair = KeyPair.fromSecretSeed(clientSecretSeed);
      String userAccountId = userKeyPair.accountId;
      String jwtToken = await webAuth.jwtToken(userAccountId, [userKeyPair]);
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
      KeyPair userKeyPair = KeyPair.fromSecretSeed(clientSecretSeed);
      String userAccountId = userKeyPair.accountId;
      String jwtToken = await webAuth.jwtToken(userAccountId, [userKeyPair]);
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
      KeyPair userKeyPair = KeyPair.fromSecretSeed(clientSecretSeed);
      String userAccountId = userKeyPair.accountId;
      String jwtToken = await webAuth.jwtToken(userAccountId, [userKeyPair]);
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
      KeyPair userKeyPair = KeyPair.fromSecretSeed(clientSecretSeed);
      String userAccountId = userKeyPair.accountId;
      String jwtToken = await webAuth.jwtToken(userAccountId, [userKeyPair]);
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
      KeyPair userKeyPair = KeyPair.fromSecretSeed(clientSecretSeed);
      String userAccountId = userKeyPair.accountId;
      String jwtToken = await webAuth.jwtToken(userAccountId, [userKeyPair]);
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
      KeyPair userKeyPair = KeyPair.fromSecretSeed(clientSecretSeed);
      String userAccountId = userKeyPair.accountId;
      String jwtToken = await webAuth.jwtToken(userAccountId, [userKeyPair]);
    } catch (e) {
      print(e.toString());
      assert(e is ChallengeValidationErrorInvalidSignature);
      return;
    }
    assert(false);
  });

  test('test get challenge invalid client domain source account', () async {
    final webAuth =
        WebAuth(authServer, Network.TESTNET, serverAccountId, domain);
    webAuth.httpClient = MockClient((request) async {
      if (request.url.toString().startsWith(authServer) &&
          request.method == "GET" &&
          request.url.toString().contains(clientAccountId)) {
        return http.Response(
            requestChallengeInvalidClientDomainOpSourceAccount(clientAccountId),
            200);
      }
      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });
    try {
      KeyPair userKeyPair = KeyPair.fromSecretSeed(clientSecretSeed);
      String userAccountId = userKeyPair.accountId;
      String jwtToken = await webAuth.jwtToken(userAccountId, [userKeyPair]);
    } catch (e) {
      print(e.toString());
      assert(e is ChallengeValidationErrorInvalidSourceAccount);
      return;
    }
    assert(false);
  });

  test('test get challenge valid client domain source account', () async {
    final KeyPair clientDomainAccountKeyPair = KeyPair.random();
    final webAuth =
        WebAuth(authServer, Network.TESTNET, serverAccountId, domain);
    webAuth.httpClient = MockClient((request) async {
      if (request.url.toString().startsWith(authServer) &&
          request.method == "GET" &&
          request.url.toString().contains(clientAccountId)) {
        return http.Response(
            requestChallengeValidClientDomainOpSourceAccount(
                clientAccountId, clientDomainAccountKeyPair.accountId),
            200);
      }
      if (request.url.toString().startsWith(authServer) &&
          request.method == "POST") {
        // validate if the challenge transaction has been signed by the client
        String signedTransaction = request.body;
        XdrTransactionEnvelope envelopeXdr =
            XdrTransactionEnvelope.fromEnvelopeXdrString(signedTransaction);
        final signatures = envelopeXdr.v1!.signatures;
        if (signatures!.length == 3) {
          final clientSignature = envelopeXdr.v1!.signatures![1];
          final clientKeyPair = KeyPair.fromAccountId(clientAccountId);
          final transactionHash =
              AbstractTransaction.fromEnvelopeXdr(envelopeXdr)
                  .hash(Network.TESTNET);
          final validCS = clientKeyPair.verify(
              transactionHash!, clientSignature!.signature!.signature!);
          final clientDomainSignature = envelopeXdr.v1!.signatures![2];
          final validCDS = clientDomainAccountKeyPair.verify(
              transactionHash, clientDomainSignature!.signature!.signature!);
          if (validCS && validCDS) {
            return http.Response(requestJWTSuccess(), 200); // OK
          }
        }
      }
      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });
    try {
      KeyPair userKeyPair = KeyPair.fromSecretSeed(clientSecretSeed);
      String userAccountId = userKeyPair.accountId;
      String jwtToken = await webAuth.jwtToken(userAccountId, [userKeyPair],
          clientDomain: "place.domain.com",
          clientDomainAccountKeyPair: clientDomainAccountKeyPair);
      print(jwtToken);
    } catch (e) {
      print(e.toString());
      assert(false);
      return;
    }
    assert(true);
  });
}
