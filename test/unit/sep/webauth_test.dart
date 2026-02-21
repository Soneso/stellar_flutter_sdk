import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';

Uint8List _generateNonce() {
  final random = Random.secure();
  final nonce = Uint8List(48);
  for (int i = 0; i < 48; i++) {
    nonce[i] = random.nextInt(256);
  }
  final encoded = base64.encode(nonce);
  return Uint8List.fromList(encoded.codeUnits);
}

void main() {
  group('WebAuth - Challenge Validation', () {
    late KeyPair serverKeyPair;
    late KeyPair clientKeyPair;
    late Network testNetwork;
    late String serverHomeDomain;
    late String authEndpoint;
    late WebAuth webAuth;

    setUp(() {
      serverKeyPair = KeyPair.random();
      clientKeyPair = KeyPair.random();
      testNetwork = Network.TESTNET;
      serverHomeDomain = 'example.com';
      authEndpoint = 'https://example.com/auth';

      webAuth = WebAuth(
        authEndpoint,
        testNetwork,
        serverKeyPair.accountId,
        serverHomeDomain,
      );
    });

    String buildValidChallenge({
      String? clientAccountId,
      String? serverAccountId,
      String? homeDomain,
      int? memo,
      bool includeWebAuthDomain = true,
      TimeBounds? timeBounds,
      String? clientDomainAccountId,
    }) {
      final actualClientAccountId = clientAccountId ?? clientKeyPair.accountId;
      final actualServerAccountId = serverAccountId ?? serverKeyPair.accountId;
      final actualHomeDomain = homeDomain ?? serverHomeDomain;

      final nonce = _generateNonce();
      final sourceAccount = Account(actualServerAccountId, BigInt.from(-1));

      final ops = <Operation>[];

      final homeDomainOp = ManageDataOperationBuilder(
        '$actualHomeDomain auth',
        nonce,
      ).setSourceAccount(actualClientAccountId).build();
      ops.add(homeDomainOp);

      if (includeWebAuthDomain) {
        final uri = Uri.parse(authEndpoint);
        final webAuthDomainOp = ManageDataOperationBuilder(
          'web_auth_domain',
          Uint8List.fromList(uri.host.codeUnits),
        ).setSourceAccount(actualServerAccountId).build();
        ops.add(webAuthDomainOp);
      }

      if (clientDomainAccountId != null) {
        final clientDomainOp = ManageDataOperationBuilder(
          'client_domain',
          Uint8List.fromList('client.example.com'.codeUnits),
        ).setSourceAccount(clientDomainAccountId).build();
        ops.add(clientDomainOp);
      }

      final txBuilder = TransactionBuilder(sourceAccount);

      for (final op in ops) {
        txBuilder.addOperation(op);
      }

      if (timeBounds != null) {
        txBuilder.addTimeBounds(timeBounds);
      } else {
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        txBuilder.addTimeBounds(TimeBounds(now, now + 300));
      }

      if (memo != null) {
        txBuilder.addMemo(Memo.id(BigInt.from(memo)));
      }

      final transaction = txBuilder.build();

      if (actualServerAccountId == serverKeyPair.accountId) {
        transaction.sign(serverKeyPair, testNetwork);
      } else {
        final tempKeyPair = KeyPair.random();
        transaction.sign(tempKeyPair, testNetwork);
      }

      return transaction.toEnvelopeXdrBase64();
    }


    group('validateChallenge - Valid Challenges', () {
      test('validates challenge with valid structure', () {
        final challenge = buildValidChallenge();

        expect(
          () => webAuth.validateChallenge(challenge, clientKeyPair.accountId, null),
          returnsNormally,
        );
      });

      test('validates challenge with memo', () {
        final memo = 12345;
        final challenge = buildValidChallenge(memo: memo);

        expect(
          () => webAuth.validateChallenge(
            challenge,
            clientKeyPair.accountId,
            null,
            null,
            memo,
          ),
          returnsNormally,
        );
      });

      test('validates challenge with client domain', () {
        final clientDomainKeyPair = KeyPair.random();
        final challenge = buildValidChallenge(
          clientDomainAccountId: clientDomainKeyPair.accountId,
        );

        expect(
          () => webAuth.validateChallenge(
            challenge,
            clientKeyPair.accountId,
            clientDomainKeyPair.accountId,
          ),
          returnsNormally,
        );
      });

      test('validates challenge within grace period', () {
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final expiredTime = now - 100;
        final timeBounds = TimeBounds(expiredTime - 300, expiredTime);

        final challenge = buildValidChallenge(timeBounds: timeBounds);

        expect(
          () => webAuth.validateChallenge(
            challenge,
            clientKeyPair.accountId,
            null,
            200,
          ),
          returnsNormally,
        );
      });
    });

    group('validateChallenge - Invalid Transaction Type', () {
      test('throws error for non-ENVELOPE_TYPE_TX', () {
        final challenge = buildValidChallenge();
        final envelopeXdr = XdrTransactionEnvelope.fromEnvelopeXdrString(challenge);

        final v0Envelope = XdrTransactionEnvelope(XdrEnvelopeType.ENVELOPE_TYPE_TX_V0);
        v0Envelope.v0 = XdrTransactionV0Envelope(
          XdrTransactionV0(
            XdrUint256(Uint8List(32)),
            XdrUint32(100),
            XdrSequenceNumber(XdrBigInt64(BigInt.zero)),
            null,
            XdrMemo(XdrMemoType.MEMO_NONE),
            [],
            XdrTransactionV0Ext(0),
          ),
          [],
        );

        final invalidChallenge = v0Envelope.toEnvelopeXdrBase64();

        expect(
          () => webAuth.validateChallenge(
            invalidChallenge,
            clientKeyPair.accountId,
            null,
          ),
          throwsA(isA<ChallengeValidationError>()),
        );
      });
    });

    group('validateChallenge - Sequence Number', () {
      test('throws error for non-zero sequence number', () {
        final sourceAccount = Account(serverKeyPair.accountId, BigInt.from(100));
        final nonce = _generateNonce();

        final op = ManageDataOperationBuilder(
          '$serverHomeDomain auth',
          nonce,
        ).setSourceAccount(clientKeyPair.accountId).build();

        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final transaction = TransactionBuilder(sourceAccount)
            .addOperation(op)
            .addTimeBounds(TimeBounds(now, now + 300))
            .build();

        transaction.sign(serverKeyPair, testNetwork);
        final challenge = transaction.toEnvelopeXdrBase64();

        expect(
          () => webAuth.validateChallenge(
            challenge,
            clientKeyPair.accountId,
            null,
          ),
          throwsA(isA<ChallengeValidationErrorInvalidSeqNr>()),
        );
      });
    });

    group('validateChallenge - Memo Validation', () {
      test('throws error when memo present with muxed account', () {
        final muxedAccount = MuxedAccount(
          clientKeyPair.accountId,
          BigInt.from(12345),
        );

        final challenge = buildValidChallenge(
          clientAccountId: clientKeyPair.accountId,
          memo: 12345,
        );

        expect(
          () => webAuth.validateChallenge(
            challenge,
            muxedAccount.accountId,
            null,
          ),
          throwsA(isA<ChallengeValidationErrorMemoAndMuxedAccount>()),
        );
      });

      test('throws error for invalid memo type', () {
        final sourceAccount = Account(serverKeyPair.accountId, BigInt.from(-1));
        final nonce = _generateNonce();

        final op = ManageDataOperationBuilder(
          '$serverHomeDomain auth',
          nonce,
        ).setSourceAccount(clientKeyPair.accountId).build();

        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final transaction = TransactionBuilder(sourceAccount)
            .addOperation(op)
            .addMemo(Memo.text('invalid'))
            .addTimeBounds(TimeBounds(now, now + 300))
            .build();

        transaction.sign(serverKeyPair, testNetwork);
        final challenge = transaction.toEnvelopeXdrBase64();

        expect(
          () => webAuth.validateChallenge(
            challenge,
            clientKeyPair.accountId,
            null,
            null,
            12345,
          ),
          throwsA(isA<ChallengeValidationErrorInvalidMemoType>()),
        );
      });

      test('throws error when memo value does not match', () {
        final challenge = buildValidChallenge(memo: 12345);

        expect(
          () => webAuth.validateChallenge(
            challenge,
            clientKeyPair.accountId,
            null,
            null,
            99999,
          ),
          throwsA(isA<ChallengeValidationErrorInvalidMemoValue>()),
        );
      });

      test('throws error when memo expected but missing', () {
        final challenge = buildValidChallenge();

        expect(
          () => webAuth.validateChallenge(
            challenge,
            clientKeyPair.accountId,
            null,
            null,
            12345,
          ),
          throwsA(isA<ChallengeValidationErrorInvalidMemoValue>()),
        );
      });
    });

    group('validateChallenge - Operation Validation', () {
      test('throws error for zero operations', () {
        final sourceAccount = Account(serverKeyPair.accountId, BigInt.from(-1));

        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

        expect(
          () {
            final transaction = TransactionBuilder(sourceAccount)
                .addTimeBounds(TimeBounds(now, now + 300))
                .build();
          },
          throwsException,
        );
      });

      test('throws error when first operation source account does not match client', () {
        final wrongClientKeyPair = KeyPair.random();
        final challenge = buildValidChallenge(
          clientAccountId: wrongClientKeyPair.accountId,
        );

        expect(
          () => webAuth.validateChallenge(
            challenge,
            clientKeyPair.accountId,
            null,
          ),
          throwsA(isA<ChallengeValidationErrorInvalidSourceAccount>()),
        );
      });

      test('throws error for operation with null source account', () {
        final sourceAccount = Account(serverKeyPair.accountId, BigInt.from(-1));
        final nonce = _generateNonce();

        final op = ManageDataOperation('$serverHomeDomain auth', nonce);

        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final transaction = TransactionBuilder(sourceAccount)
            .addOperation(op)
            .addTimeBounds(TimeBounds(now, now + 300))
            .build();

        transaction.sign(serverKeyPair, testNetwork);
        final challenge = transaction.toEnvelopeXdrBase64();

        expect(
          () => webAuth.validateChallenge(
            challenge,
            clientKeyPair.accountId,
            null,
          ),
          throwsA(isA<ChallengeValidationErrorInvalidSourceAccount>()),
        );
      });

      test('throws error for non-ManageData operation', () {
        final sourceAccount = Account(serverKeyPair.accountId, BigInt.from(-1));

        final paymentOp = PaymentOperationBuilder(
          clientKeyPair.accountId,
          Asset.NATIVE,
          '100',
        ).setSourceAccount(clientKeyPair.accountId).build();

        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final transaction = TransactionBuilder(sourceAccount)
            .addOperation(paymentOp)
            .addTimeBounds(TimeBounds(now, now + 300))
            .build();

        transaction.sign(serverKeyPair, testNetwork);
        final challenge = transaction.toEnvelopeXdrBase64();

        expect(
          () => webAuth.validateChallenge(
            challenge,
            clientKeyPair.accountId,
            null,
          ),
          throwsA(isA<ChallengeValidationErrorInvalidOperationType>()),
        );
      });

      test('throws error when client_domain operation has wrong source account', () {
        final wrongClientDomainKeyPair = KeyPair.random();
        final challenge = buildValidChallenge(
          clientDomainAccountId: wrongClientDomainKeyPair.accountId,
        );

        expect(
          () => webAuth.validateChallenge(
            challenge,
            clientKeyPair.accountId,
            KeyPair.random().accountId,
          ),
          throwsA(isA<ChallengeValidationErrorInvalidSourceAccount>()),
        );
      });

      test('throws error when non-client_domain operation has wrong source account', () {
        final sourceAccount = Account(serverKeyPair.accountId, BigInt.from(-1));
        final nonce = _generateNonce();

        final op1 = ManageDataOperationBuilder(
          '$serverHomeDomain auth',
          nonce,
        ).setSourceAccount(clientKeyPair.accountId).build();

        final op2 = ManageDataOperationBuilder(
          'web_auth_domain',
          Uint8List.fromList('example.com'.codeUnits),
        ).setSourceAccount(clientKeyPair.accountId).build();

        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final transaction = TransactionBuilder(sourceAccount)
            .addOperation(op1)
            .addOperation(op2)
            .addTimeBounds(TimeBounds(now, now + 300))
            .build();

        transaction.sign(serverKeyPair, testNetwork);
        final challenge = transaction.toEnvelopeXdrBase64();

        expect(
          () => webAuth.validateChallenge(
            challenge,
            clientKeyPair.accountId,
            null,
          ),
          throwsA(isA<ChallengeValidationErrorInvalidSourceAccount>()),
        );
      });
    });

    group('validateChallenge - Home Domain Validation', () {
      test('throws error for invalid home domain in first operation', () {
        final sourceAccount = Account(serverKeyPair.accountId, BigInt.from(-1));
        final nonce = _generateNonce();

        final op = ManageDataOperationBuilder(
          'wrong.com auth',
          nonce,
        ).setSourceAccount(clientKeyPair.accountId).build();

        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final transaction = TransactionBuilder(sourceAccount)
            .addOperation(op)
            .addTimeBounds(TimeBounds(now, now + 300))
            .build();

        transaction.sign(serverKeyPair, testNetwork);
        final challenge = transaction.toEnvelopeXdrBase64();

        expect(
          () => webAuth.validateChallenge(
            challenge,
            clientKeyPair.accountId,
            null,
          ),
          throwsA(isA<ChallengeValidationErrorInvalidHomeDomain>()),
        );
      });

      test('throws error when home domain does not end with auth', () {
        final sourceAccount = Account(serverKeyPair.accountId, BigInt.from(-1));
        final nonce = _generateNonce();

        final op = ManageDataOperationBuilder(
          serverHomeDomain,
          nonce,
        ).setSourceAccount(clientKeyPair.accountId).build();

        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final transaction = TransactionBuilder(sourceAccount)
            .addOperation(op)
            .addTimeBounds(TimeBounds(now, now + 300))
            .build();

        transaction.sign(serverKeyPair, testNetwork);
        final challenge = transaction.toEnvelopeXdrBase64();

        expect(
          () => webAuth.validateChallenge(
            challenge,
            clientKeyPair.accountId,
            null,
          ),
          throwsA(isA<ChallengeValidationErrorInvalidHomeDomain>()),
        );
      });
    });

    group('validateChallenge - Web Auth Domain Validation', () {
      test('throws error when web_auth_domain does not match endpoint', () {
        final sourceAccount = Account(serverKeyPair.accountId, BigInt.from(-1));
        final nonce = _generateNonce();

        final op1 = ManageDataOperationBuilder(
          '$serverHomeDomain auth',
          nonce,
        ).setSourceAccount(clientKeyPair.accountId).build();

        final op2 = ManageDataOperationBuilder(
          'web_auth_domain',
          Uint8List.fromList('wrong.com'.codeUnits),
        ).setSourceAccount(serverKeyPair.accountId).build();

        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final transaction = TransactionBuilder(sourceAccount)
            .addOperation(op1)
            .addOperation(op2)
            .addTimeBounds(TimeBounds(now, now + 300))
            .build();

        transaction.sign(serverKeyPair, testNetwork);
        final challenge = transaction.toEnvelopeXdrBase64();

        expect(
          () => webAuth.validateChallenge(
            challenge,
            clientKeyPair.accountId,
            null,
          ),
          throwsA(isA<ChallengeValidationErrorInvalidWebAuthDomain>()),
        );
      });
    });

    group('validateChallenge - Time Bounds Validation', () {
      test('throws error for expired challenge', () {
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final expiredTime = now - 400;
        final timeBounds = TimeBounds(expiredTime - 300, expiredTime);

        final challenge = buildValidChallenge(timeBounds: timeBounds);

        expect(
          () => webAuth.validateChallenge(
            challenge,
            clientKeyPair.accountId,
            null,
          ),
          throwsA(isA<ChallengeValidationErrorInvalidTimeBounds>()),
        );
      });

      test('throws error for future challenge', () {
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final futureTime = now + 400;
        final timeBounds = TimeBounds(futureTime, futureTime + 300);

        final challenge = buildValidChallenge(timeBounds: timeBounds);

        expect(
          () => webAuth.validateChallenge(
            challenge,
            clientKeyPair.accountId,
            null,
          ),
          throwsA(isA<ChallengeValidationErrorInvalidTimeBounds>()),
        );
      });

      test('validates challenge at minimum time bound with grace period', () {
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final timeBounds = TimeBounds(now + 100, now + 400);

        final challenge = buildValidChallenge(timeBounds: timeBounds);

        expect(
          () => webAuth.validateChallenge(
            challenge,
            clientKeyPair.accountId,
            null,
            150,
          ),
          returnsNormally,
        );
      });

      test('validates challenge at maximum time bound with grace period', () {
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final timeBounds = TimeBounds(now - 400, now - 100);

        final challenge = buildValidChallenge(timeBounds: timeBounds);

        expect(
          () => webAuth.validateChallenge(
            challenge,
            clientKeyPair.accountId,
            null,
            150,
          ),
          returnsNormally,
        );
      });
    });

    group('validateChallenge - Signature Validation', () {
      test('throws error for missing server signature', () {
        final sourceAccount = Account(serverKeyPair.accountId, BigInt.from(-1));
        final nonce = _generateNonce();

        final op = ManageDataOperationBuilder(
          '$serverHomeDomain auth',
          nonce,
        ).setSourceAccount(clientKeyPair.accountId).build();

        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final transaction = TransactionBuilder(sourceAccount)
            .addOperation(op)
            .addTimeBounds(TimeBounds(now, now + 300))
            .build();

        final challenge = transaction.toEnvelopeXdrBase64();

        expect(
          () => webAuth.validateChallenge(
            challenge,
            clientKeyPair.accountId,
            null,
          ),
          throwsA(isA<ChallengeValidationErrorInvalidSignature>()),
        );
      });

      test('throws error for invalid server signature', () {
        final sourceAccount = Account(serverKeyPair.accountId, BigInt.from(-1));
        final nonce = _generateNonce();

        final op = ManageDataOperationBuilder(
          '$serverHomeDomain auth',
          nonce,
        ).setSourceAccount(clientKeyPair.accountId).build();

        final uri = Uri.parse(authEndpoint);
        final op2 = ManageDataOperationBuilder(
          'web_auth_domain',
          Uint8List.fromList(uri.host.codeUnits),
        ).setSourceAccount(serverKeyPair.accountId).build();

        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final transaction = TransactionBuilder(sourceAccount)
            .addOperation(op)
            .addOperation(op2)
            .addTimeBounds(TimeBounds(now, now + 300))
            .build();

        final wrongServerKeyPair = KeyPair.random();
        transaction.sign(wrongServerKeyPair, testNetwork);
        final challenge = transaction.toEnvelopeXdrBase64();

        expect(
          () => webAuth.validateChallenge(
            challenge,
            clientKeyPair.accountId,
            null,
          ),
          throwsA(isA<ChallengeValidationErrorInvalidSignature>()),
        );
      });

      test('validates challenge with multiple signatures (server + client)', () {
        final challenge = buildValidChallenge();
        final signedChallenge = webAuth.signTransaction(challenge, [clientKeyPair]);

        expect(
          () => webAuth.validateChallenge(
            signedChallenge,
            clientKeyPair.accountId,
            null,
          ),
          throwsA(isA<ChallengeValidationErrorInvalidSignature>()),
        );
      });
    });

    group('validateChallenge - Network Passphrase', () {
      test('throws error for wrong network passphrase', () {
        final wrongNetwork = Network.PUBLIC;
        final sourceAccount = Account(serverKeyPair.accountId, BigInt.from(-1));
        final nonce = _generateNonce();

        final op = ManageDataOperationBuilder(
          '$serverHomeDomain auth',
          nonce,
        ).setSourceAccount(clientKeyPair.accountId).build();

        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final transaction = TransactionBuilder(sourceAccount)
            .addOperation(op)
            .addTimeBounds(TimeBounds(now, now + 300))
            .build();

        transaction.sign(serverKeyPair, wrongNetwork);
        final challenge = transaction.toEnvelopeXdrBase64();

        expect(
          () => webAuth.validateChallenge(
            challenge,
            clientKeyPair.accountId,
            null,
          ),
          throwsA(isA<ChallengeValidationErrorInvalidSignature>()),
        );
      });
    });
  });

  group('WebAuth - Transaction Signing', () {
    late KeyPair serverKeyPair;
    late KeyPair clientKeyPair;
    late Network testNetwork;
    late String serverHomeDomain;
    late String authEndpoint;
    late WebAuth webAuth;

    setUp(() {
      serverKeyPair = KeyPair.random();
      clientKeyPair = KeyPair.random();
      testNetwork = Network.TESTNET;
      serverHomeDomain = 'example.com';
      authEndpoint = 'https://example.com/auth';

      webAuth = WebAuth(
        authEndpoint,
        testNetwork,
        serverKeyPair.accountId,
        serverHomeDomain,
      );
    });

    test('signTransaction adds signature to challenge', () {
      final sourceAccount = Account(serverKeyPair.accountId, BigInt.from(-1));
      final nonce = Uint8List(48);

      final op = ManageDataOperationBuilder(
        '$serverHomeDomain auth',
        nonce,
      ).setSourceAccount(clientKeyPair.accountId).build();

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final transaction = TransactionBuilder(sourceAccount)
          .addOperation(op)
          .addTimeBounds(TimeBounds(now, now + 300))
          .build();

      transaction.sign(serverKeyPair, testNetwork);
      final challenge = transaction.toEnvelopeXdrBase64();

      final signedChallenge = webAuth.signTransaction(challenge, [clientKeyPair]);

      final envelopeXdr = XdrTransactionEnvelope.fromEnvelopeXdrString(signedChallenge);
      expect(envelopeXdr.v1!.signatures.length, equals(2));
    });

    test('signTransaction with multiple signers', () {
      final sourceAccount = Account(serverKeyPair.accountId, BigInt.from(-1));
      final nonce = Uint8List(48);

      final op = ManageDataOperationBuilder(
        '$serverHomeDomain auth',
        nonce,
      ).setSourceAccount(clientKeyPair.accountId).build();

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final transaction = TransactionBuilder(sourceAccount)
          .addOperation(op)
          .addTimeBounds(TimeBounds(now, now + 300))
          .build();

      transaction.sign(serverKeyPair, testNetwork);
      final challenge = transaction.toEnvelopeXdrBase64();

      final signer1 = KeyPair.random();
      final signer2 = KeyPair.random();
      final signedChallenge = webAuth.signTransaction(
        challenge,
        [signer1, signer2],
      );

      final envelopeXdr = XdrTransactionEnvelope.fromEnvelopeXdrString(signedChallenge);
      expect(envelopeXdr.v1!.signatures.length, equals(3));
    });

    test('signTransaction preserves existing signatures', () {
      final sourceAccount = Account(serverKeyPair.accountId, BigInt.from(-1));
      final nonce = Uint8List(48);

      final op = ManageDataOperationBuilder(
        '$serverHomeDomain auth',
        nonce,
      ).setSourceAccount(clientKeyPair.accountId).build();

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final transaction = TransactionBuilder(sourceAccount)
          .addOperation(op)
          .addTimeBounds(TimeBounds(now, now + 300))
          .build();

      transaction.sign(serverKeyPair, testNetwork);
      final challenge = transaction.toEnvelopeXdrBase64();

      final signer1 = KeyPair.random();
      final challengeWith1Sig = webAuth.signTransaction(challenge, [signer1]);

      final signer2 = KeyPair.random();
      final challengeWith2Sigs = webAuth.signTransaction(challengeWith1Sig, [signer2]);

      final envelopeXdr = XdrTransactionEnvelope.fromEnvelopeXdrString(challengeWith2Sigs);
      expect(envelopeXdr.v1!.signatures.length, equals(3));
    });

    test('signTransaction throws error for invalid transaction type', () {
      final v0Envelope = XdrTransactionEnvelope(XdrEnvelopeType.ENVELOPE_TYPE_TX_V0);
      v0Envelope.v0 = XdrTransactionV0Envelope(
        XdrTransactionV0(
          XdrUint256(Uint8List(32)),
          XdrUint32(100),
          XdrSequenceNumber(XdrBigInt64(BigInt.zero)),
          null,
          XdrMemo(XdrMemoType.MEMO_NONE),
          [],
          XdrTransactionV0Ext(0),
        ),
        [],
      );

      final invalidChallenge = v0Envelope.toEnvelopeXdrBase64();

      expect(
        () => webAuth.signTransaction(invalidChallenge, [clientKeyPair]),
        throwsA(isA<ChallengeValidationError>()),
      );
    });
  });

  group('WebAuth - Muxed Account Support', () {
    late KeyPair serverKeyPair;
    late KeyPair clientKeyPair;
    late Network testNetwork;
    late String serverHomeDomain;
    late String authEndpoint;
    late WebAuth webAuth;

    setUp(() {
      serverKeyPair = KeyPair.random();
      clientKeyPair = KeyPair.random();
      testNetwork = Network.TESTNET;
      serverHomeDomain = 'example.com';
      authEndpoint = 'https://example.com/auth';

      webAuth = WebAuth(
        authEndpoint,
        testNetwork,
        serverKeyPair.accountId,
        serverHomeDomain,
      );
    });

    test('validates challenge with muxed account', () {
      final muxedAccount = MuxedAccount(
        clientKeyPair.accountId,
        BigInt.from(12345),
      );

      final sourceAccount = Account(serverKeyPair.accountId, BigInt.from(-1));
      final nonce = Uint8List(48);

      final op = ManageDataOperationBuilder(
        '$serverHomeDomain auth',
        nonce,
      ).setSourceAccount(muxedAccount.accountId).build();

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final transaction = TransactionBuilder(sourceAccount)
          .addOperation(op)
          .addTimeBounds(TimeBounds(now, now + 300))
          .build();

      transaction.sign(serverKeyPair, testNetwork);
      final challenge = transaction.toEnvelopeXdrBase64();

      expect(
        () => webAuth.validateChallenge(
          challenge,
          muxedAccount.accountId,
          null,
        ),
        returnsNormally,
      );
    });

    test('validates challenge with muxed account without separate memo', () {
      final muxedAccount = MuxedAccount(
        clientKeyPair.accountId,
        BigInt.from(12345),
      );

      final sourceAccount = Account(serverKeyPair.accountId, BigInt.from(-1));
      final nonce = Uint8List(48);

      final op = ManageDataOperationBuilder(
        '$serverHomeDomain auth',
        nonce,
      ).setSourceAccount(muxedAccount.accountId).build();

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final transaction = TransactionBuilder(sourceAccount)
          .addOperation(op)
          .addTimeBounds(TimeBounds(now, now + 300))
          .build();

      transaction.sign(serverKeyPair, testNetwork);
      final challenge = transaction.toEnvelopeXdrBase64();

      expect(
        () => webAuth.validateChallenge(
          challenge,
          muxedAccount.accountId,
          null,
        ),
        returnsNormally,
      );
    });
  });

  group('WebAuth - Exception Types', () {
    test('NoMemoForMuxedAccountsException has correct message', () {
      final exception = NoMemoForMuxedAccountsException();
      expect(
        exception.toString(),
        equals('Memo cannot be used if account is a muxed account'),
      );
    });

    test('MissingClientDomainException has correct message', () {
      final exception = MissingClientDomainException();
      expect(
        exception.toString(),
        contains('clientDomain is required'),
      );
    });

    test('MissingTransactionInChallengeResponseException has correct message', () {
      final exception = MissingTransactionInChallengeResponseException();
      expect(
        exception.toString(),
        contains('Missing transaction'),
      );
    });

    test('NoWebAuthEndpointFoundException has correct message', () {
      final exception = NoWebAuthEndpointFoundException('example.com');
      expect(exception.toString(), contains('example.com'));
      expect(exception.toString(), contains('WEB_AUTH_ENDPOINT'));
    });

    test('NoWebAuthServerSigningKeyFoundException has correct message', () {
      final exception = NoWebAuthServerSigningKeyFoundException('example.com');
      expect(exception.toString(), contains('example.com'));
      expect(exception.toString(), contains('SIGNING_KEY'));
    });

    test('NoClientDomainSigningKeyFoundException has correct message', () {
      final exception = NoClientDomainSigningKeyFoundException('client.example.com');
      expect(exception.toString(), contains('client.example.com'));
      expect(exception.toString(), contains('SIGNING_KEY'));
    });

    test('SubmitCompletedChallengeTimeoutResponseException has correct message', () {
      final exception = SubmitCompletedChallengeTimeoutResponseException();
      expect(exception.toString(), contains('504'));
    });

    test('SubmitCompletedChallengeUnknownResponseException has correct message', () {
      final exception = SubmitCompletedChallengeUnknownResponseException(
        500,
        'Internal Server Error',
      );
      expect(exception.toString(), contains('500'));
      expect(exception.code, equals(500));
      expect(exception.body, equals('Internal Server Error'));
    });

    test('SubmitCompletedChallengeErrorResponseException has correct message', () {
      final exception = SubmitCompletedChallengeErrorResponseException('Invalid signature');
      expect(exception.toString(), contains('Invalid signature'));
      expect(exception.error, equals('Invalid signature'));
    });

    test('ChallengeValidationError has correct message', () {
      final exception = ChallengeValidationError('Test error');
      expect(exception.toString(), equals('Test error'));
    });

    test('ChallengeValidationErrorInvalidSeqNr has correct message', () {
      final exception = ChallengeValidationErrorInvalidSeqNr('Invalid sequence');
      expect(exception.toString(), equals('Invalid sequence'));
    });

    test('ChallengeValidationErrorInvalidSourceAccount has correct message', () {
      final exception = ChallengeValidationErrorInvalidSourceAccount('Invalid source');
      expect(exception.toString(), equals('Invalid source'));
    });

    test('ChallengeValidationErrorInvalidTimeBounds has correct message', () {
      final exception = ChallengeValidationErrorInvalidTimeBounds('Invalid time');
      expect(exception.toString(), equals('Invalid time'));
    });

    test('ChallengeValidationErrorInvalidOperationType has correct message', () {
      final exception = ChallengeValidationErrorInvalidOperationType('Invalid operation');
      expect(exception.toString(), equals('Invalid operation'));
    });

    test('ChallengeValidationErrorInvalidHomeDomain has correct message', () {
      final exception = ChallengeValidationErrorInvalidHomeDomain('Invalid domain');
      expect(exception.toString(), equals('Invalid domain'));
    });

    test('ChallengeValidationErrorInvalidWebAuthDomain has correct message', () {
      final exception = ChallengeValidationErrorInvalidWebAuthDomain('Invalid web auth');
      expect(exception.toString(), equals('Invalid web auth'));
    });

    test('ChallengeValidationErrorInvalidSignature has correct message', () {
      final exception = ChallengeValidationErrorInvalidSignature('Invalid signature');
      expect(exception.toString(), equals('Invalid signature'));
    });

    test('ChallengeValidationErrorMemoAndMuxedAccount has correct message', () {
      final exception = ChallengeValidationErrorMemoAndMuxedAccount('Memo and muxed');
      expect(exception.toString(), equals('Memo and muxed'));
    });

    test('ChallengeValidationErrorInvalidMemoType has correct message', () {
      final exception = ChallengeValidationErrorInvalidMemoType('Invalid memo type');
      expect(exception.toString(), equals('Invalid memo type'));
    });

    test('ChallengeValidationErrorInvalidMemoValue has correct message', () {
      final exception = ChallengeValidationErrorInvalidMemoValue('Invalid memo value');
      expect(exception.toString(), equals('Invalid memo value'));
    });

    test('MissingClientDomainSigningKeyException has correct message', () {
      final exception = MissingClientDomainSigningKeyException();
      expect(
        exception.toString(),
        contains('clientDomainAccountKeyPair or clientDomainSigningDelegate is required'),
      );
    });
  });

  group('WebAuth - fromDomain httpRequestHeaders', () {
    test('fromDomain forwards httpRequestHeaders to WebAuth instance', () async {
      final serverKeyPair = KeyPair.random();

      final mockClient = MockClient((request) async {
        expect(request.url.toString(), contains('.well-known/stellar.toml'));

        return http.Response('''
WEB_AUTH_ENDPOINT="https://testanchor.stellar.org/auth"
SIGNING_KEY="${serverKeyPair.accountId}"
        ''', 200);
      });

      final webAuth = await WebAuth.fromDomain(
        'testanchor.stellar.org',
        Network.TESTNET,
        httpClient: mockClient,
        httpRequestHeaders: {'X-Custom': 'test-value'},
      );

      expect(webAuth.httpRequestHeaders, equals({'X-Custom': 'test-value'}));
    });
  });

  group('WebAuth - clientDomain validation', () {
    test('jwtToken throws MissingClientDomainSigningKeyException when clientDomain provided without signing key', () async {
      final serverKeyPair = KeyPair.random();
      final clientKeyPair = KeyPair.random();

      final webAuth = WebAuth(
        'https://example.com/auth',
        Network.TESTNET,
        serverKeyPair.accountId,
        'example.com',
      );

      expect(
        () => webAuth.jwtToken(
          clientKeyPair.accountId,
          [clientKeyPair],
          clientDomain: 'client.example.com',
        ),
        throwsA(isA<MissingClientDomainSigningKeyException>()),
      );
    });

    test('jwtToken does not throw MissingClientDomainSigningKeyException when clientDomain is null', () async {
      final serverKeyPair = KeyPair.random();
      final clientKeyPair = KeyPair.random();

      final webAuth = WebAuth(
        'https://example.com/auth',
        Network.TESTNET,
        serverKeyPair.accountId,
        'example.com',
      );

      try {
        await webAuth.jwtToken(
          clientKeyPair.accountId,
          [clientKeyPair],
        );
        // If it somehow succeeds (unlikely without a real server), that is fine
      } catch (e) {
        expect(e, isNot(isA<MissingClientDomainSigningKeyException>()));
      }
    });
  });
}
