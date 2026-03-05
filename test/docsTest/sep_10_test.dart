@Timeout(const Duration(seconds: 300))

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  // Server configuration - matches the integration test pattern
  const domain = 'place.domain.com';
  const authServer = 'http://api.stellar.org/auth';

  const serverAccountId =
      'GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP';
  const serverSecretSeed =
      'SAWDHXQG6ROJSU4QGCW7NSTYFHPTPIVC2NC7QKVTO7PZCSO2WEBGM54W';
  final serverKeyPair = KeyPair.fromSecretSeed(serverSecretSeed);

  const clientSecretSeed =
      'SBAYNYLQFXVLVAHW4BXDQYNJLMDQMZ5NQDDOHVJD3PTBAUIJRNRK5LGX';
  final clientKeyPair = KeyPair.fromSecretSeed(clientSecretSeed);
  final clientAccountId = clientKeyPair.accountId;

  const successJWTToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJHQTZVSVhYUEVXWUZJTE5VSVdBQzM3WTRRUEVaTVFWREpIREtWV0ZaSjJLQ1dVQklVNUlYWk5EQSIsImp0aSI6IjE0NGQzNjdiY2IwZTcyY2FiZmRiZGU2MGVhZTBhZDczM2NjNjVkMmE2NTg3MDgzZGFiM2Q2MTZmODg1MTkwMjQiLCJpc3MiOiJodHRwczovL2ZsYXBweS1iaXJkLWRhcHAuZmlyZWJhc2VhcHAuY29tLyIsImlhdCI6MTUzNDI1Nzk5NCwiZXhwIjoxNTM0MzQ0Mzk0fQ.8nbB83Z6vGBgC1X9r3N6oQCFTBzDiITAfCJasRft0z0';

  final Random _random = Random.secure();

  Uint8List generateNonce([int length = 64]) {
    var values = List<int>.generate(length, (i) => _random.nextInt(256));
    return Uint8List.fromList(base64Url.encode(values).codeUnits);
  }

  TransactionPreconditions validTimeBounds() {
    TransactionPreconditions result = TransactionPreconditions();
    result.timeBounds = TimeBounds(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3);
    return result;
  }

  ManageDataOperation validFirstManageDataOp(String accountId) {
    MuxedAccount muxedAccount = MuxedAccount.fromAccountId(accountId)!;
    final ManageDataOperationBuilder builder =
        ManageDataOperationBuilder(domain + ' auth', generateNonce())
            .setMuxedSourceAccount(muxedAccount);
    return builder.build();
  }

  ManageDataOperation validSecondManageDataOp() {
    final ManageDataOperationBuilder builder = ManageDataOperationBuilder(
            'web_auth_domain',
            Uint8List.fromList('api.stellar.org'.codeUnits))
        .setSourceAccount(serverAccountId);
    return builder.build();
  }

  Memo memoForId(int? id) {
    if (id != null) {
      return MemoId(BigInt.from(id));
    }
    return Memo.none();
  }

  String requestChallengeSuccess(String accountId, [int? memo]) {
    final transactionAccount = Account(serverAccountId, BigInt.from(-1));
    final Transaction transaction = TransactionBuilder(transactionAccount)
        .addOperation(validFirstManageDataOp(accountId))
        .addOperation(validSecondManageDataOp())
        .addMemo(memoForId(memo))
        .addPreconditions(validTimeBounds())
        .build();
    transaction.sign(serverKeyPair, Network.TESTNET);
    final mapJson = {'transaction': transaction.toEnvelopeXdrBase64()};
    return json.encode(mapJson);
  }

  String requestChallengeInvalidSeqNr(String accountId) {
    final transactionAccount = Account(serverAccountId, BigInt.from(2803983));
    final Transaction transaction = TransactionBuilder(transactionAccount)
        .addOperation(validFirstManageDataOp(accountId))
        .addOperation(validSecondManageDataOp())
        .addMemo(Memo.none())
        .addPreconditions(validTimeBounds())
        .build();
    transaction.sign(serverKeyPair, Network.TESTNET);
    final mapJson = {'transaction': transaction.toEnvelopeXdrBase64()};
    return json.encode(mapJson);
  }

  String requestJWTSuccess() {
    final mapJson = {'token': successJWTToken};
    return json.encode(mapJson);
  }

  // -- sep-10.md: "Creating WebAuth — Manual construction" --
  test('sep-10: manual WebAuth construction', () {
    // Snippet from sep-10.md "Manual construction"
    final webAuth = WebAuth(
      'https://testanchor.stellar.org/auth',
      Network.TESTNET,
      'GCUZ6YLL5RQBTYLTTQLPCM73C5XAIUGK2TIMWQH7HPSGWVS2KJ2F3CHS',
      'testanchor.stellar.org',
    );

    // WebAuth should be constructed successfully
    expect(webAuth, isNotNull);
  });

  // -- sep-10.md: "Standard authentication" via mock --
  test('sep-10: standard authentication with mock', () async {
    // Snippet from sep-10.md "Testing" section
    final webAuth =
        WebAuth(authServer, Network.TESTNET, serverAccountId, domain);

    webAuth.httpClient = MockClient((request) async {
      if (request.url.toString().startsWith(authServer) &&
          request.method == 'GET' &&
          request.url.toString().contains(clientAccountId)) {
        return http.Response(requestChallengeSuccess(clientAccountId), 200);
      }
      if (request.url.toString().startsWith(authServer) &&
          request.method == 'POST') {
        // Validate the challenge transaction has been signed by the client
        XdrTransactionEnvelope envelopeXdr =
            XdrTransactionEnvelope.fromEnvelopeXdrString(
                json.decode(request.body)['transaction']);
        final signatures = envelopeXdr.v1!.signatures;
        if (signatures.length == 2) {
          final clientSignature = envelopeXdr.v1!.signatures[1];
          final clientKp = KeyPair.fromAccountId(clientAccountId);
          final transactionHash =
              AbstractTransaction.fromEnvelopeXdr(envelopeXdr)
                  .hash(Network.TESTNET);
          final valid = clientKp.verify(
              transactionHash, clientSignature.signature.signature);
          if (valid) {
            return http.Response(requestJWTSuccess(), 200);
          }
        }
      }
      final mapJson = {'error': 'Bad request'};
      return http.Response(json.encode(mapJson), 400);
    });

    KeyPair userKeyPair = KeyPair.fromSecretSeed(clientSecretSeed);
    String jwtToken =
        await webAuth.jwtToken(userKeyPair.accountId, [userKeyPair]);
    expect(jwtToken, equals(successJWTToken));
  });

  // -- sep-10.md: "Muxed accounts" --
  test('sep-10: muxed account authentication', () async {
    final clientAccountIdM =
        'MB4L7JUU5DENUXYH3ANTLVYQL66KQLDDJTN5SF7MWEDGWSGUA375UAAAAAAACMICQP7P4';

    final webAuth =
        WebAuth(authServer, Network.TESTNET, serverAccountId, domain);

    webAuth.httpClient = MockClient((request) async {
      if (request.url.toString().startsWith(authServer) &&
          request.method == 'GET' &&
          request.url.toString().contains(Uri.encodeComponent(clientAccountIdM))) {
        return http.Response(requestChallengeSuccess(clientAccountIdM), 200);
      }
      if (request.url.toString().startsWith(authServer) &&
          request.method == 'POST') {
        XdrTransactionEnvelope envelopeXdr =
            XdrTransactionEnvelope.fromEnvelopeXdrString(
                json.decode(request.body)['transaction']);
        if (envelopeXdr.v1!.signatures.length == 2) {
          return http.Response(requestJWTSuccess(), 200);
        }
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    KeyPair userKeyPair = KeyPair.fromSecretSeed(clientSecretSeed);
    String jwtToken =
        await webAuth.jwtToken(clientAccountIdM, [userKeyPair]);
    expect(jwtToken, equals(successJWTToken));
  });

  // -- sep-10.md: "Memo-based user separation" --
  test('sep-10: memo-based authentication', () async {
    const int testMemo = 19989123;

    final webAuth =
        WebAuth(authServer, Network.TESTNET, serverAccountId, domain);

    webAuth.httpClient = MockClient((request) async {
      if (request.url.toString().startsWith(authServer) &&
          request.method == 'GET' &&
          request.url.toString().contains(clientAccountId)) {
        return http.Response(
            requestChallengeSuccess(clientAccountId, testMemo), 200);
      }
      if (request.url.toString().startsWith(authServer) &&
          request.method == 'POST') {
        XdrTransactionEnvelope envelopeXdr =
            XdrTransactionEnvelope.fromEnvelopeXdrString(
                json.decode(request.body)['transaction']);
        if (envelopeXdr.v1!.signatures.length == 2) {
          return http.Response(requestJWTSuccess(), 200);
        }
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    KeyPair userKeyPair = KeyPair.fromSecretSeed(clientSecretSeed);
    String jwtToken = await webAuth.jwtToken(
      userKeyPair.accountId,
      [userKeyPair],
      memo: testMemo,
    );
    expect(jwtToken, equals(successJWTToken));
  });

  // -- sep-10.md: "Error handling" — validation error case --
  test('sep-10: invalid sequence number throws ChallengeValidationErrorInvalidSeqNr',
      () async {
    final webAuth =
        WebAuth(authServer, Network.TESTNET, serverAccountId, domain);

    webAuth.httpClient = MockClient((request) async {
      if (request.url.toString().startsWith(authServer) &&
          request.method == 'GET') {
        return http.Response(
            requestChallengeInvalidSeqNr(clientAccountId), 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    KeyPair userKeyPair = KeyPair.fromSecretSeed(clientSecretSeed);
    expect(
      () => webAuth.jwtToken(userKeyPair.accountId, [userKeyPair]),
      throwsA(isA<ChallengeValidationErrorInvalidSeqNr>()),
    );
  });

  // -- sep-10.md: memo with muxed account throws exception --
  test('sep-10: memo with muxed account throws NoMemoForMuxedAccountsException',
      () async {
    final clientAccountIdM =
        'MB4L7JUU5DENUXYH3ANTLVYQL66KQLDDJTN5SF7MWEDGWSGUA375UAAAAAAACMICQP7P4';

    final webAuth =
        WebAuth(authServer, Network.TESTNET, serverAccountId, domain);

    // Should throw before any HTTP request is made
    KeyPair userKeyPair = KeyPair.fromSecretSeed(clientSecretSeed);
    expect(
      () => webAuth.jwtToken(clientAccountIdM, [userKeyPair], memo: 12345),
      throwsA(isA<NoMemoForMuxedAccountsException>()),
    );
  });
}
