import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:typed_data';

void main() {
  late KeyPair sourceKeyPair;
  late Account sourceAccount;
  late KeyPair destinationKeyPair;
  late Network testNetwork;

  setUp(() {
    sourceKeyPair = KeyPair.fromSecretSeed('SDJHRQF4GCMIIKAAAQ6IHY42X73FQFLHUULAPSKKD4DFDM7UXWWCRHBE');
    sourceAccount = Account(sourceKeyPair.accountId, BigInt.from(2908908335136768));
    destinationKeyPair = KeyPair.fromSecretSeed('SAB5556L5AN5KSR5WF7UOEFDCIODEWEO7H2UR4S5R62DFTQOGLKOVZDY');
    testNetwork = Network.TESTNET;
  });

  group('TxRep Deep Testing - PathPaymentStrictSend', () {
    test('PathPaymentStrictSend with multiple path assets', () {
      final issuerKeyPair = KeyPair.random();
      final usd = AssetTypeCreditAlphaNum4("USD", issuerKeyPair.accountId);
      final eur = AssetTypeCreditAlphaNum4("EUR", issuerKeyPair.accountId);
      final gbp = AssetTypeCreditAlphaNum4("GBP", issuerKeyPair.accountId);
      final jpy = AssetTypeCreditAlphaNum12("JPYTOKEN1234", issuerKeyPair.accountId);

      final pathPaymentOp = PathPaymentStrictSendOperationBuilder(
        usd,
        "100.5",
        destinationKeyPair.accountId,
        eur,
        "85.0"
      ).setPath([Asset.NATIVE, gbp, jpy]).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(pathPaymentOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: PATH_PAYMENT_STRICT_SEND'));
      expect(txRep, contains('pathPaymentStrictSendOp'));
      expect(txRep, contains('path.len: 3'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('PathPaymentStrictSend with empty path', () {
      final issuerKeyPair = KeyPair.random();
      final usd = AssetTypeCreditAlphaNum4("USD", issuerKeyPair.accountId);
      final eur = AssetTypeCreditAlphaNum4("EUR", issuerKeyPair.accountId);

      final pathPaymentOp = PathPaymentStrictSendOperationBuilder(
        usd,
        "100",
        destinationKeyPair.accountId,
        eur,
        "90"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(pathPaymentOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: PATH_PAYMENT_STRICT_SEND'));
      expect(txRep, contains('path.len: 0'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });
  });

  group('TxRep Deep Testing - ManageBuyOffer', () {
    test('ManageBuyOffer create new offer', () {
      final issuerKeyPair = KeyPair.random();
      final usd = AssetTypeCreditAlphaNum4("USD", issuerKeyPair.accountId);

      final manageBuyOfferOp = ManageBuyOfferOperationBuilder(
        usd,
        Asset.NATIVE,
        "100",
        "0.5"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(manageBuyOfferOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: MANAGE_BUY_OFFER'));
      expect(txRep, contains('manageBuyOfferOp'));
      expect(txRep, contains('offerID: 0'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('ManageBuyOffer update existing offer', () {
      final issuerKeyPair = KeyPair.random();
      final usd = AssetTypeCreditAlphaNum4("USD", issuerKeyPair.accountId);

      final manageBuyOfferOp = ManageBuyOfferOperationBuilder(
        usd,
        Asset.NATIVE,
        "200",
        "0.75"
      ).setOfferId("12345").build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(manageBuyOfferOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: MANAGE_BUY_OFFER'));
      expect(txRep, contains('offerID: 12345'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('ManageBuyOffer delete offer', () {
      final issuerKeyPair = KeyPair.random();
      final usd = AssetTypeCreditAlphaNum4("USD", issuerKeyPair.accountId);

      final manageBuyOfferOp = ManageBuyOfferOperationBuilder(
        usd,
        Asset.NATIVE,
        "0",
        "0.5"
      ).setOfferId("67890").build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(manageBuyOfferOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: MANAGE_BUY_OFFER'));
      expect(txRep, contains('offerID: 67890'));
      expect(txRep, contains('buyAmount: 0'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });
  });

  group('TxRep Deep Testing - CreateClaimableBalance', () {
    test('CreateClaimableBalance with unconditional predicate', () {
      final claimant = Claimant(
        destinationKeyPair.accountId,
        Claimant.predicateUnconditional()
      );

      final createClaimableBalanceOp = CreateClaimableBalanceOperationBuilder(
        [claimant],
        Asset.NATIVE,
        "100"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(createClaimableBalanceOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: CREATE_CLAIMABLE_BALANCE'));
      expect(txRep, contains('createClaimableBalanceOp'));
      expect(txRep, contains('claimants.len: 1'));
      expect(txRep, contains('CLAIM_PREDICATE_UNCONDITIONAL'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('CreateClaimableBalance with time-based absolute predicate', () {
      final futureTime = 1893456000;
      final claimant = Claimant(
        destinationKeyPair.accountId,
        Claimant.predicateBeforeAbsoluteTime(futureTime)
      );

      final createClaimableBalanceOp = CreateClaimableBalanceOperationBuilder(
        [claimant],
        Asset.NATIVE,
        "50.5"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(createClaimableBalanceOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: CREATE_CLAIMABLE_BALANCE'));
      expect(txRep, contains('CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME'));
      expect(txRep, contains('absBefore: $futureTime'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('CreateClaimableBalance with time-based relative predicate', () {
      final relativeSeconds = 604800;
      final claimant = Claimant(
        destinationKeyPair.accountId,
        Claimant.predicateBeforeRelativeTime(relativeSeconds)
      );

      final createClaimableBalanceOp = CreateClaimableBalanceOperationBuilder(
        [claimant],
        Asset.NATIVE,
        "75"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(createClaimableBalanceOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: CREATE_CLAIMABLE_BALANCE'));
      expect(txRep, contains('CLAIM_PREDICATE_BEFORE_RELATIVE_TIME'));
      expect(txRep, contains('relBefore: $relativeSeconds'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('CreateClaimableBalance with AND predicate', () {
      final time1 = 1893456000;
      final time2 = 1925000000;
      final claimant = Claimant(
        destinationKeyPair.accountId,
        Claimant.predicateAnd(
          Claimant.predicateBeforeAbsoluteTime(time2),
          Claimant.predicateNot(Claimant.predicateBeforeAbsoluteTime(time1))
        )
      );

      final createClaimableBalanceOp = CreateClaimableBalanceOperationBuilder(
        [claimant],
        Asset.NATIVE,
        "125"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(createClaimableBalanceOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: CREATE_CLAIMABLE_BALANCE'));
      expect(txRep, contains('CLAIM_PREDICATE_AND'));
      expect(txRep, contains('CLAIM_PREDICATE_NOT'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('CreateClaimableBalance with OR predicate', () {
      final time1 = 1893456000;
      final relTime = 86400;
      final claimant = Claimant(
        destinationKeyPair.accountId,
        Claimant.predicateOr(
          Claimant.predicateBeforeAbsoluteTime(time1),
          Claimant.predicateBeforeRelativeTime(relTime)
        )
      );

      final createClaimableBalanceOp = CreateClaimableBalanceOperationBuilder(
        [claimant],
        Asset.NATIVE,
        "200"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(createClaimableBalanceOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: CREATE_CLAIMABLE_BALANCE'));
      expect(txRep, contains('CLAIM_PREDICATE_OR'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('CreateClaimableBalance with NOT predicate', () {
      final time = 1893456000;
      final claimant = Claimant(
        destinationKeyPair.accountId,
        Claimant.predicateNot(Claimant.predicateBeforeAbsoluteTime(time))
      );

      final createClaimableBalanceOp = CreateClaimableBalanceOperationBuilder(
        [claimant],
        Asset.NATIVE,
        "150"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(createClaimableBalanceOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: CREATE_CLAIMABLE_BALANCE'));
      expect(txRep, contains('CLAIM_PREDICATE_NOT'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('CreateClaimableBalance with multiple claimants', () {
      final claimant1 = Claimant(
        destinationKeyPair.accountId,
        Claimant.predicateUnconditional()
      );

      final claimant2KeyPair = KeyPair.random();
      final claimant2 = Claimant(
        claimant2KeyPair.accountId,
        Claimant.predicateBeforeAbsoluteTime(1893456000)
      );

      final claimant3KeyPair = KeyPair.random();
      final claimant3 = Claimant(
        claimant3KeyPair.accountId,
        Claimant.predicateBeforeRelativeTime(86400)
      );

      final createClaimableBalanceOp = CreateClaimableBalanceOperationBuilder(
        [claimant1, claimant2, claimant3],
        Asset.NATIVE,
        "300"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(createClaimableBalanceOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: CREATE_CLAIMABLE_BALANCE'));
      expect(txRep, contains('claimants.len: 3'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });
  });

  group('TxRep Deep Testing - ClaimClaimableBalance', () {
    test('ClaimClaimableBalance operation', () {
      final balanceId = '00000000da0d57da7d4850e7fc10d2a9d0ebc731f7afb40574c03395b17d49149b91f5be';

      final claimOp = ClaimClaimableBalanceOperationBuilder(balanceId).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(claimOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: CLAIM_CLAIMABLE_BALANCE'));
      expect(txRep, contains('claimClaimableBalanceOp'));
      expect(txRep, contains('balanceID'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });
  });

  group('TxRep Deep Testing - Sponsorship Operations', () {
    test('BeginSponsoringFutureReserves operation', () {
      final sponsoredKeyPair = KeyPair.random();

      final beginSponsoringOp = BeginSponsoringFutureReservesOperationBuilder(
        sponsoredKeyPair.accountId
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(beginSponsoringOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: BEGIN_SPONSORING_FUTURE_RESERVES'));
      expect(txRep, contains('beginSponsoringFutureReservesOp'));
      expect(txRep, contains('sponsoredID: ${sponsoredKeyPair.accountId}'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('EndSponsoringFutureReserves operation', () {
      final endSponsoringOp = EndSponsoringFutureReservesOperationBuilder().build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(endSponsoringOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: END_SPONSORING_FUTURE_RESERVES'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });
  });

  group('TxRep Deep Testing - RevokeSponsorship', () {
    test('RevokeSponsorship for account', () {
      final revokeOp = RevokeSponsorshipOperationBuilder()
        .revokeAccountSponsorship(destinationKeyPair.accountId)
        .build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(revokeOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: REVOKE_SPONSORSHIP'));
      expect(txRep, contains('revokeSponsorshipOp'));
      expect(txRep, contains('REVOKE_SPONSORSHIP_LEDGER_ENTRY'));
      expect(txRep, contains('type: ACCOUNT'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('RevokeSponsorship for trustline', () {
      final issuerKeyPair = KeyPair.random();
      final usd = AssetTypeCreditAlphaNum4("USD", issuerKeyPair.accountId);

      final revokeOp = RevokeSponsorshipOperationBuilder()
        .revokeTrustlineSponsorship(destinationKeyPair.accountId, usd)
        .build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(revokeOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: REVOKE_SPONSORSHIP'));
      expect(txRep, contains('type: TRUSTLINE'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('RevokeSponsorship for offer', () {
      final offerId = 123456;

      final revokeOp = RevokeSponsorshipOperationBuilder()
        .revokeOfferSponsorship(sourceKeyPair.accountId, offerId)
        .build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(revokeOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: REVOKE_SPONSORSHIP'));
      expect(txRep, contains('type: OFFER'));
      expect(txRep, contains('offerID: 123456'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('RevokeSponsorship for data', () {
      final dataName = 'config_key';

      final revokeOp = RevokeSponsorshipOperationBuilder()
        .revokeDataSponsorship(sourceKeyPair.accountId, dataName)
        .build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(revokeOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: REVOKE_SPONSORSHIP'));
      expect(txRep, contains('type: DATA'));
      expect(txRep, contains('dataName: "config_key"'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('RevokeSponsorship for claimable balance', () {
      final balanceId = '00000000da0d57da7d4850e7fc10d2a9d0ebc731f7afb40574c03395b17d49149b91f5be';

      final revokeOp = RevokeSponsorshipOperationBuilder()
        .revokeClaimableBalanceSponsorship(balanceId)
        .build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(revokeOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: REVOKE_SPONSORSHIP'));
      expect(txRep, contains('type: CLAIMABLE_BALANCE'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('RevokeSponsorship for signer', () {
      final signerKeyPair = KeyPair.random();

      final revokeOp = RevokeSponsorshipOperationBuilder()
        .revokeEd25519Signer(destinationKeyPair.accountId, signerKeyPair.accountId)
        .build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(revokeOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: REVOKE_SPONSORSHIP'));
      expect(txRep, contains('REVOKE_SPONSORSHIP_SIGNER'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });
  });

  group('TxRep Deep Testing - Clawback Operations', () {
    test('Clawback operation', () {
      final issuerKeyPair = KeyPair.random();
      final usd = AssetTypeCreditAlphaNum4("USD", issuerKeyPair.accountId);

      final clawbackOp = ClawbackOperationBuilder(
        usd,
        destinationKeyPair.accountId,
        "50.5"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(clawbackOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: CLAWBACK'));
      expect(txRep, contains('clawbackOp'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('ClawbackClaimableBalance operation', () {
      final balanceId = '00000000da0d57da7d4850e7fc10d2a9d0ebc731f7afb40574c03395b17d49149b91f5be';

      final clawbackOp = ClawbackClaimableBalanceOperationBuilder(balanceId).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(clawbackOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: CLAWBACK_CLAIMABLE_BALANCE'));
      expect(txRep, contains('clawbackClaimableBalanceOp'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });
  });

  group('TxRep Deep Testing - SetTrustLineFlags', () {
    test('SetTrustLineFlags set authorized flag', () {
      final issuerKeyPair = KeyPair.random();
      final usd = AssetTypeCreditAlphaNum4("USD", issuerKeyPair.accountId);

      final setFlagsOp = SetTrustLineFlagsOperationBuilder(
        destinationKeyPair.accountId,
        usd,
        0,
        1
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(setFlagsOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: SET_TRUST_LINE_FLAGS'));
      expect(txRep, contains('setTrustLineFlagsOp'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('SetTrustLineFlags clear authorized flag', () {
      final issuerKeyPair = KeyPair.random();
      final usd = AssetTypeCreditAlphaNum4("USD", issuerKeyPair.accountId);

      final setFlagsOp = SetTrustLineFlagsOperationBuilder(
        destinationKeyPair.accountId,
        usd,
        1,
        0
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(setFlagsOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: SET_TRUST_LINE_FLAGS'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('SetTrustLineFlags with multiple flags', () {
      final issuerKeyPair = KeyPair.random();
      final usd = AssetTypeCreditAlphaNum4("USD", issuerKeyPair.accountId);

      final setFlagsOp = SetTrustLineFlagsOperationBuilder(
        destinationKeyPair.accountId,
        usd,
        0,
        3
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(setFlagsOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: SET_TRUST_LINE_FLAGS'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });
  });

  group('TxRep Deep Testing - Liquidity Pool Operations', () {
    test('LiquidityPoolDeposit operation', () {
      final issuerKeyPair = KeyPair.random();
      final usd = AssetTypeCreditAlphaNum4("USD", issuerKeyPair.accountId);
      final poolId = 'dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7';

      final depositOp = LiquidityPoolDepositOperationBuilder(
        liquidityPoolId: poolId,
        maxAmountA: "100",
        maxAmountB: "200",
        minPrice: "0.5",
        maxPrice: "0.6"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(depositOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: LIQUIDITY_POOL_DEPOSIT'));
      expect(txRep, contains('liquidityPoolDepositOp'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('LiquidityPoolWithdraw operation', () {
      final poolId = 'dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7';

      final withdrawOp = LiquidityPoolWithdrawOperationBuilder(
        liquidityPoolId: poolId,
        amount: "50",
        minAmountA: "10",
        minAmountB: "20"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(withdrawOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: LIQUIDITY_POOL_WITHDRAW'));
      expect(txRep, contains('liquidityPoolWithdrawOp'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });
  });

  group('TxRep Deep Testing - SetOptions Advanced', () {
    test('SetOptions with all sub-fields', () {
      final signerKeyPair = KeyPair.random();

      final setOptionsOp = SetOptionsOperationBuilder()
        .setInflationDestination(destinationKeyPair.accountId)
        .setHomeDomain("example.stellar.org")
        .setClearFlags(1)
        .setSetFlags(2)
        .setMasterKeyWeight(100)
        .setLowThreshold(10)
        .setMediumThreshold(50)
        .setHighThreshold(100)
        .setSigner(signerKeyPair.xdrSignerKey, 5)
        .build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(setOptionsOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: SET_OPTIONS'));
      expect(txRep, contains('setOptionsOp'));
      expect(txRep, contains('homeDomain._present: true'));
      expect(txRep, contains('homeDomain: "example.stellar.org"'));
      expect(txRep, contains('inflationDest._present: true'));
      expect(txRep, contains('clearFlags._present: true'));
      expect(txRep, contains('setFlags._present: true'));
      expect(txRep, contains('masterWeight._present: true'));
      expect(txRep, contains('lowThreshold._present: true'));
      expect(txRep, contains('medThreshold._present: true'));
      expect(txRep, contains('highThreshold._present: true'));
      expect(txRep, contains('signer._present: true'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('SetOptions with AUTH_REQUIRED flag', () {
      final setOptionsOp = SetOptionsOperationBuilder()
        .setSetFlags(AccountFlag.AUTH_REQUIRED_FLAG.value)
        .build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(setOptionsOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: SET_OPTIONS'));
      expect(txRep, contains('setFlags._present: true'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('SetOptions with AUTH_REVOCABLE flag', () {
      final setOptionsOp = SetOptionsOperationBuilder()
        .setSetFlags(AccountFlag.AUTH_REVOCABLE_FLAG.value)
        .build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(setOptionsOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: SET_OPTIONS'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('SetOptions with AUTH_IMMUTABLE flag', () {
      final setOptionsOp = SetOptionsOperationBuilder()
        .setSetFlags(AccountFlag.AUTH_IMMUTABLE_FLAG.value)
        .build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(setOptionsOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: SET_OPTIONS'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('SetOptions with AUTH_CLAWBACK_ENABLED flag', () {
      final setOptionsOp = SetOptionsOperationBuilder()
        .setSetFlags(AccountFlag.AUTH_CLAWBACK_ENABLED_FLAG.value)
        .build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(setOptionsOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: SET_OPTIONS'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('SetOptions with ed25519 signer', () {
      final signerKeyPair = KeyPair.random();

      final setOptionsOp = SetOptionsOperationBuilder()
        .setSigner(signerKeyPair.xdrSignerKey, 10)
        .build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(setOptionsOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: SET_OPTIONS'));
      expect(txRep, contains('signer._present: true'));
      expect(txRep, contains('signer.key: ${signerKeyPair.accountId}'));
      expect(txRep, contains('signer.weight: 10'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('SetOptions with preauth_tx signer', () {
      final hash = Uint8List.fromList(List<int>.filled(32, 7));
      final signerKey = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_PRE_AUTH_TX);
      signerKey.preAuthTx = XdrUint256(hash);

      final setOptionsOp = SetOptionsOperationBuilder()
        .setSigner(signerKey, 15)
        .build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(setOptionsOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: SET_OPTIONS'));
      expect(txRep, contains('signer._present: true'));
      expect(txRep, contains('signer.weight: 15'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('SetOptions with sha256_hash signer', () {
      final hash = Uint8List.fromList(List<int>.filled(32, 9));
      final signerKey = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_HASH_X);
      signerKey.hashX = XdrUint256(hash);

      final setOptionsOp = SetOptionsOperationBuilder()
        .setSigner(signerKey, 20)
        .build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(setOptionsOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: SET_OPTIONS'));
      expect(txRep, contains('signer._present: true'));
      expect(txRep, contains('signer.weight: 20'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });
  });

  group('TxRep Deep Testing - Multiple Signatures', () {
    test('Transaction with 3 signatures', () {
      final signer2 = KeyPair.random();
      final signer3 = KeyPair.random();

      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);
      transaction.sign(signer2, testNetwork);
      transaction.sign(signer3, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('signatures.len: 3'));
      expect(txRep, contains('signatures[0].hint:'));
      expect(txRep, contains('signatures[1].hint:'));
      expect(txRep, contains('signatures[2].hint:'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('Transaction with 5 signatures', () {
      final signers = List.generate(5, (_) => KeyPair.random());

      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .build();

      for (var signer in signers) {
        transaction.sign(signer, testNetwork);
      }

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('signatures.len: 5'));
      for (int i = 0; i < 5; i++) {
        expect(txRep, contains('signatures[$i].hint:'));
        expect(txRep, contains('signatures[$i].signature:'));
      }

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });
  });

  group('TxRep Deep Testing - Large Number of Operations', () {
    test('Transaction with 5 operations', () {
      final transaction = TransactionBuilder(sourceAccount);

      for (int i = 0; i < 5; i++) {
        transaction.addOperation(
          PaymentOperationBuilder(
            destinationKeyPair.accountId,
            Asset.NATIVE,
            "${i + 10}"
          ).build()
        );
      }

      final tx = transaction.build();
      tx.sign(sourceKeyPair, testNetwork);

      final xdr = tx.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations.len: 5'));
      for (int i = 0; i < 5; i++) {
        expect(txRep, contains('tx.operations[$i].body.type: PAYMENT'));
      }

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('Transaction with 10 different operation types', () {
      final issuerKeyPair = KeyPair.random();
      final usd = AssetTypeCreditAlphaNum4("USD", issuerKeyPair.accountId);
      final newAccountKeyPair = KeyPair.random();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(CreateAccountOperationBuilder(newAccountKeyPair.accountId, "100").build())
        .addOperation(PaymentOperationBuilder(destinationKeyPair.accountId, Asset.NATIVE, "10").build())
        .addOperation(PathPaymentStrictReceiveOperationBuilder(usd, "50", destinationKeyPair.accountId, Asset.NATIVE, "45").build())
        .addOperation(ManageSellOfferOperationBuilder(usd, Asset.NATIVE, "100", "0.5").build())
        .addOperation(CreatePassiveSellOfferOperationBuilder(usd, Asset.NATIVE, "100", "0.5").build())
        .addOperation(SetOptionsOperationBuilder().setHomeDomain("example.com").build())
        .addOperation(ChangeTrustOperationBuilder(usd, "10000").build())
        .addOperation(ManageDataOperationBuilder("test_key", Uint8List.fromList("test".codeUnits)).build())
        .addOperation(BumpSequenceOperationBuilder(BigInt.parse('9999999999999999')).build())
        .addOperation(ManageBuyOfferOperationBuilder(usd, Asset.NATIVE, "100", "0.5").build())
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations.len: 10'));
      expect(txRep, contains('CREATE_ACCOUNT'));
      expect(txRep, contains('PAYMENT'));
      expect(txRep, contains('PATH_PAYMENT_STRICT_RECEIVE'));
      expect(txRep, contains('MANAGE_SELL_OFFER'));
      expect(txRep, contains('CREATE_PASSIVE_SELL_OFFER'));
      expect(txRep, contains('SET_OPTIONS'));
      expect(txRep, contains('CHANGE_TRUST'));
      expect(txRep, contains('MANAGE_DATA'));
      expect(txRep, contains('BUMP_SEQUENCE'));
      expect(txRep, contains('MANAGE_BUY_OFFER'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });
  });

  group('TxRep Deep Testing - FeeBumpTransaction Advanced', () {
    test('FeeBumpTransaction with CreateAccount inner operation', () {
      final newAccountKeyPair = KeyPair.random();
      final createAccountOp = CreateAccountOperationBuilder(
        newAccountKeyPair.accountId,
        "1000"
      ).build();

      final innerTx = TransactionBuilder(sourceAccount)
        .addOperation(createAccountOp)
        .build();

      innerTx.sign(sourceKeyPair, testNetwork);

      final feeBumpAccount = KeyPair.random();
      final feeBumpTx = FeeBumpTransactionBuilder(innerTx)
        .setBaseFee(300)
        .setFeeAccount(feeBumpAccount.accountId)
        .build();

      feeBumpTx.sign(feeBumpAccount, testNetwork);

      final xdr = feeBumpTx.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('type: ENVELOPE_TYPE_TX_FEE_BUMP'));
      expect(txRep, contains('feeBump.tx.innerTx.type: ENVELOPE_TYPE_TX'));
      expect(txRep, contains('CREATE_ACCOUNT'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('FeeBumpTransaction with ChangeTrust inner operation', () {
      final issuerKeyPair = KeyPair.random();
      final usd = AssetTypeCreditAlphaNum4("USD", issuerKeyPair.accountId);

      final changeTrustOp = ChangeTrustOperationBuilder(usd, "5000").build();

      final innerTx = TransactionBuilder(sourceAccount)
        .addOperation(changeTrustOp)
        .build();

      innerTx.sign(sourceKeyPair, testNetwork);

      final feeBumpAccount = KeyPair.random();
      final feeBumpTx = FeeBumpTransactionBuilder(innerTx)
        .setBaseFee(400)
        .setFeeAccount(feeBumpAccount.accountId)
        .build();

      feeBumpTx.sign(feeBumpAccount, testNetwork);

      final xdr = feeBumpTx.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('type: ENVELOPE_TYPE_TX_FEE_BUMP'));
      expect(txRep, contains('CHANGE_TRUST'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('FeeBumpTransaction with multiple inner operations', () {
      final paymentOp1 = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100"
      ).build();

      final paymentOp2 = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "50"
      ).build();

      final innerTx = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp1)
        .addOperation(paymentOp2)
        .build();

      innerTx.sign(sourceKeyPair, testNetwork);

      final feeBumpAccount = KeyPair.random();
      final feeBumpTx = FeeBumpTransactionBuilder(innerTx)
        .setBaseFee(500)
        .setFeeAccount(feeBumpAccount.accountId)
        .build();

      feeBumpTx.sign(feeBumpAccount, testNetwork);

      final xdr = feeBumpTx.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('type: ENVELOPE_TYPE_TX_FEE_BUMP'));
      expect(txRep, contains('feeBump.tx.innerTx.tx.operations.len: 2'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });
  });

  group('TxRep Deep Testing - Preconditions V2', () {
    test('Transaction with minSeqAge precondition', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).build();

      final preconditions = TransactionPreconditions();
      preconditions.minSeqAge = 300;

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .addPreconditions(preconditions)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.cond.type: PRECOND_V2'));
      expect(txRep, contains('v2.minSeqAge: 300'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('Transaction with minSeqLedgerGap precondition', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).build();

      final preconditions = TransactionPreconditions();
      preconditions.minSeqLedgerGap = 10;

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .addPreconditions(preconditions)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.cond.type: PRECOND_V2'));
      expect(txRep, contains('v2.minSeqLedgerGap: 10'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('Transaction with minSeqNum precondition', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).build();

      final preconditions = TransactionPreconditions();
      preconditions.minSeqNumber = BigInt.from(1000000);

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .addPreconditions(preconditions)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.cond.type: PRECOND_V2'));
      expect(txRep, contains('v2.minSeqNum: 1000000'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('Transaction with extraSigners precondition', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).build();

      final extraSigner1 = KeyPair.random();
      final extraSigner2 = KeyPair.random();

      final preconditions = TransactionPreconditions();
      preconditions.extraSigners = [
        extraSigner1.xdrSignerKey,
        extraSigner2.xdrSignerKey
      ];

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .addPreconditions(preconditions)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.cond.type: PRECOND_V2'));
      expect(txRep, contains('v2.extraSigners.len: 2'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('Transaction with combined preconditions', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).build();

      final extraSigner = KeyPair.random();

      final preconditions = TransactionPreconditions();
      preconditions.timeBounds = TimeBounds(1000, 2000);
      preconditions.minSeqAge = 500;
      preconditions.minSeqLedgerGap = 5;
      preconditions.minSeqNumber = BigInt.from(999999);
      preconditions.extraSigners = [extraSigner.xdrSignerKey];

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .addPreconditions(preconditions)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.cond.type: PRECOND_V2'));
      expect(txRep, contains('v2.timeBounds.minTime: 1000'));
      expect(txRep, contains('v2.timeBounds.maxTime: 2000'));
      expect(txRep, contains('v2.minSeqAge: 500'));
      expect(txRep, contains('v2.minSeqLedgerGap: 5'));
      expect(txRep, contains('v2.minSeqNum: 999999'));
      expect(txRep, contains('v2.extraSigners.len: 1'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('Transaction with ledgerBounds precondition', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).build();

      final preconditions = TransactionPreconditions();
      preconditions.ledgerBounds = LedgerBounds(100, 200);

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .addPreconditions(preconditions)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.cond.type: PRECOND_V2'));
      expect(txRep, contains('v2.ledgerBounds._present: true'));
      expect(txRep, contains('v2.ledgerBounds.minLedger: 100'));
      expect(txRep, contains('v2.ledgerBounds.maxLedger: 200'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });
  });

  group('TxRep Deep Testing - Memo Types', () {
    test('Transaction with MEMO_TEXT', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .addMemo(MemoText("Hello Stellar"))
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.memo.type: MEMO_TEXT'));
      expect(txRep, contains('tx.memo.text: "Hello Stellar"'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('Transaction with MEMO_ID', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .addMemo(MemoId(BigInt.from(123456789)))
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.memo.type: MEMO_ID'));
      expect(txRep, contains('tx.memo.id: 123456789'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('Transaction with MEMO_HASH', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).build();

      final hash = Uint8List.fromList(List<int>.filled(32, 42));
      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .addMemo(MemoHash(hash))
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.memo.type: MEMO_HASH'));
      expect(txRep, contains('tx.memo.hash:'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('Transaction with MEMO_RETURN', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).build();

      final hash = Uint8List.fromList(List<int>.filled(32, 99));
      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .addMemo(MemoReturnHash(hash))
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.memo.type: MEMO_RETURN'));
      expect(txRep, contains('tx.memo.retHash: 6363636363636363636363636363636363636363636363636363636363636363'));

      // Test round-trip encoding/decoding
      final parsedBack = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(parsedBack, equals(xdr));
    });

    test('Transaction with MEMO_NONE', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.memo.type: MEMO_NONE'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });
  });

  group('TxRep Deep Testing - Additional Operations', () {
    test('ALLOW_TRUST operation authorize', () {
      final issuerKeyPair = KeyPair.random();
      final usd = AssetTypeCreditAlphaNum4("USD", issuerKeyPair.accountId);

      final allowTrustOp = AllowTrustOperationBuilder(
        destinationKeyPair.accountId,
        usd.code,
        1
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(allowTrustOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: ALLOW_TRUST'));
      expect(txRep, contains('allowTrustOp'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('ALLOW_TRUST operation revoke', () {
      final issuerKeyPair = KeyPair.random();
      final usd = AssetTypeCreditAlphaNum4("USD", issuerKeyPair.accountId);

      final allowTrustOp = AllowTrustOperationBuilder(
        destinationKeyPair.accountId,
        usd.code,
        0
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(allowTrustOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: ALLOW_TRUST'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('ACCOUNT_MERGE operation', () {
      final mergeDestination = KeyPair.random();

      final accountMergeOp = AccountMergeOperationBuilder(
        mergeDestination.accountId
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(accountMergeOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: ACCOUNT_MERGE'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });
  });

  group('TxRep Deep Testing - AlphaNum12 Assets', () {
    test('Payment with AlphaNum12 asset', () {
      final issuerKeyPair = KeyPair.random();
      final token = AssetTypeCreditAlphaNum12("LONGTOKEN123", issuerKeyPair.accountId);

      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        token,
        "100.0"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: PAYMENT'));
      expect(txRep, contains('LONGTOKEN123'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('ChangeTrust with AlphaNum12 asset', () {
      final issuerKeyPair = KeyPair.random();
      final token = AssetTypeCreditAlphaNum12("SUPERTOKEN12", issuerKeyPair.accountId);

      final changeTrustOp = ChangeTrustOperationBuilder(token, "10000").build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(changeTrustOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: CHANGE_TRUST'));
      expect(txRep, contains('SUPERTOKEN12'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('ManageSellOffer with AlphaNum12 asset', () {
      final issuerKeyPair = KeyPair.random();
      final token = AssetTypeCreditAlphaNum12("CRYPTOASSET1", issuerKeyPair.accountId);

      final manageSellOfferOp = ManageSellOfferOperationBuilder(
        token,
        Asset.NATIVE,
        "100",
        "0.5"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(manageSellOfferOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: MANAGE_SELL_OFFER'));
      expect(txRep, contains('CRYPTOASSET1'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });
  });

  group('TxRep Deep Testing - Operations with Source Account', () {
    test('Payment with source account', () {
      final opSourceKeyPair = KeyPair.random();

      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).setSourceAccount(opSourceKeyPair.accountId).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].sourceAccount._present: true'));
      expect(txRep, contains('tx.operations[0].sourceAccount: ${opSourceKeyPair.accountId}'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('CreateAccount with source account', () {
      final opSourceKeyPair = KeyPair.random();
      final newAccountKeyPair = KeyPair.random();

      final createAccountOp = CreateAccountOperationBuilder(
        newAccountKeyPair.accountId,
        "100"
      ).setSourceAccount(opSourceKeyPair.accountId).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(createAccountOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].sourceAccount._present: true'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });
  });

  group('TxRep Deep Testing - Edge Cases', () {
    test('ManageData with null value deletes data', () {
      final manageDataOp = ManageDataOperationBuilder("delete_key", null).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(manageDataOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: MANAGE_DATA'));
      expect(txRep, contains('dataValue._present: false'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('ManageData with binary data', () {
      final binaryData = Uint8List.fromList([0, 1, 2, 3, 255, 254, 253]);
      final manageDataOp = ManageDataOperationBuilder("binary_key", binaryData).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(manageDataOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: MANAGE_DATA'));
      expect(txRep, contains('dataValue._present: true'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('Transaction with PRECOND_TIME', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .addTimeBounds(TimeBounds(1000, 2000))
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.cond.type: PRECOND_TIME'));
      expect(txRep, contains('timeBounds.minTime: 1000'));
      expect(txRep, contains('timeBounds.maxTime: 2000'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('CreatePassiveSellOffer with AlphaNum4 and AlphaNum12', () {
      final issuerKeyPair = KeyPair.random();
      final usd = AssetTypeCreditAlphaNum4("USD", issuerKeyPair.accountId);
      final longToken = AssetTypeCreditAlphaNum12("LONGASSET123", issuerKeyPair.accountId);

      final passiveOfferOp = CreatePassiveSellOfferOperationBuilder(
        usd,
        longToken,
        "100",
        "1.5"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(passiveOfferOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: CREATE_PASSIVE_SELL_OFFER'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('PathPaymentStrictReceive with AlphaNum12 in path', () {
      final issuerKeyPair = KeyPair.random();
      final usd = AssetTypeCreditAlphaNum4("USD", issuerKeyPair.accountId);
      final eur = AssetTypeCreditAlphaNum4("EUR", issuerKeyPair.accountId);
      final longToken = AssetTypeCreditAlphaNum12("BRIDGETOKEN1", issuerKeyPair.accountId);

      final pathPaymentOp = PathPaymentStrictReceiveOperationBuilder(
        usd,
        "100",
        destinationKeyPair.accountId,
        eur,
        "95"
      ).setPath([longToken]).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(pathPaymentOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: PATH_PAYMENT_STRICT_RECEIVE'));
      expect(txRep, contains('path.len: 1'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });
  });

  group('TxRep Deep Testing - RevokeSponsorship LedgerEntry Types', () {
    test('RevokeSponsorship for trustline with AlphaNum12', () {
      final issuerKeyPair = KeyPair.random();
      final token = AssetTypeCreditAlphaNum12("LONGASSET000", issuerKeyPair.accountId);

      final revokeOp = RevokeSponsorshipOperationBuilder()
        .revokeTrustlineSponsorship(destinationKeyPair.accountId, token)
        .build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(revokeOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: REVOKE_SPONSORSHIP'));
      expect(txRep, contains('type: TRUSTLINE'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

  });

  group('TxRep Deep Testing - Complex Scenarios', () {
    test('Transaction with all memo types in sequence', () {
      final transaction1 = TransactionBuilder(sourceAccount)
        .addOperation(PaymentOperationBuilder(destinationKeyPair.accountId, Asset.NATIVE, "1").build())
        .addMemo(MemoText("test"))
        .build();

      transaction1.sign(sourceKeyPair, testNetwork);
      final xdr1 = transaction1.toEnvelopeXdrBase64();
      final txRep1 = TxRep.fromTransactionEnvelopeXdrBase64(xdr1);
      expect(txRep1, contains('tx.memo.type: MEMO_TEXT'));
      final reconstructedXdr1 = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep1);
      expect(reconstructedXdr1, equals(xdr1));

      final sourceAccount2 = Account(sourceKeyPair.accountId, sourceAccount.sequenceNumber + BigInt.one);
      final transaction2 = TransactionBuilder(sourceAccount2)
        .addOperation(PaymentOperationBuilder(destinationKeyPair.accountId, Asset.NATIVE, "2").build())
        .addMemo(MemoId(BigInt.from(42)))
        .build();

      transaction2.sign(sourceKeyPair, testNetwork);
      final xdr2 = transaction2.toEnvelopeXdrBase64();
      final txRep2 = TxRep.fromTransactionEnvelopeXdrBase64(xdr2);
      expect(txRep2, contains('tx.memo.type: MEMO_ID'));
      final reconstructedXdr2 = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep2);
      expect(reconstructedXdr2, equals(xdr2));
    });

    test('Transaction with mixed asset types in operations', () {
      final issuerKeyPair = KeyPair.random();
      final usd = AssetTypeCreditAlphaNum4("USD", issuerKeyPair.accountId);
      final longToken = AssetTypeCreditAlphaNum12("VERYLONGNAME", issuerKeyPair.accountId);

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(PaymentOperationBuilder(destinationKeyPair.accountId, Asset.NATIVE, "10").build())
        .addOperation(PaymentOperationBuilder(destinationKeyPair.accountId, usd, "20").build())
        .addOperation(PaymentOperationBuilder(destinationKeyPair.accountId, longToken, "30").build())
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations.len: 3'));
      expect(txRep, contains('XLM'));
      expect(txRep, contains('USD'));
      expect(txRep, contains('VERYLONGNAME'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('SetOptions with only homeDomain', () {
      final setOptionsOp = SetOptionsOperationBuilder()
        .setHomeDomain("stellar.org")
        .build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(setOptionsOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: SET_OPTIONS'));
      expect(txRep, contains('homeDomain._present: true'));
      expect(txRep, contains('inflationDest._present: false'));
      expect(txRep, contains('clearFlags._present: false'));
      expect(txRep, contains('setFlags._present: false'));
      expect(txRep, contains('masterWeight._present: false'));
      expect(txRep, contains('lowThreshold._present: false'));
      expect(txRep, contains('medThreshold._present: false'));
      expect(txRep, contains('highThreshold._present: false'));
      expect(txRep, contains('signer._present: false'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });
  });

  group('TxRep Deep Testing - Error Handling fromTxRep', () {
    test('throws exception for missing sourceAccount', () {
      final txRep = '''
type: ENVELOPE_TYPE_TX
tx.fee: 100
tx.seqNum: 123456
tx.memo.type: MEMO_NONE
tx.operations.len: 0
tx.cond.type: PRECOND_NONE
tx.ext.v: 0
signatures.len: 0
''';

      expect(
        () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
        throwsException
      );
    });

    test('throws exception for invalid sourceAccount', () {
      final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: INVALID_ACCOUNT
tx.fee: 100
tx.seqNum: 123456
tx.memo.type: MEMO_NONE
tx.operations.len: 0
''';

      expect(
        () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
        throwsException
      );
    });

    test('throws exception for missing fee', () {
      final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: ${sourceKeyPair.accountId}
tx.seqNum: 123456
tx.memo.type: MEMO_NONE
tx.operations.len: 0
''';

      expect(
        () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
        throwsException
      );
    });

    test('throws exception for invalid fee', () {
      final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: ${sourceKeyPair.accountId}
tx.fee: invalid
tx.seqNum: 123456
tx.memo.type: MEMO_NONE
tx.operations.len: 0
''';

      expect(
        () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
        throwsException
      );
    });

    test('throws exception for missing seqNum', () {
      final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: ${sourceKeyPair.accountId}
tx.fee: 100
tx.memo.type: MEMO_NONE
tx.operations.len: 0
''';

      expect(
        () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
        throwsException
      );
    });

    test('throws exception for invalid seqNum', () {
      final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: ${sourceKeyPair.accountId}
tx.fee: 100
tx.seqNum: invalid
tx.memo.type: MEMO_NONE
tx.operations.len: 0
''';

      expect(
        () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
        throwsException
      );
    });

    test('throws exception for missing memo type', () {
      final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: ${sourceKeyPair.accountId}
tx.fee: 100
tx.seqNum: 123456
tx.operations.len: 0
''';

      expect(
        () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
        throwsException
      );
    });

    test('throws exception for missing operations.len', () {
      final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: ${sourceKeyPair.accountId}
tx.fee: 100
tx.seqNum: 123456
tx.memo.type: MEMO_NONE
''';

      expect(
        () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
        throwsException
      );
    });

    test('throws exception for invalid operations.len (too many)', () {
      final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: ${sourceKeyPair.accountId}
tx.fee: 100
tx.seqNum: 123456
tx.memo.type: MEMO_NONE
tx.operations.len: 101
tx.cond.type: PRECOND_NONE
tx.ext.v: 0
signatures.len: 0
''';

      expect(
        () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
        throwsException
      );
    });

    test('throws exception for invalid operations.len (not a number)', () {
      final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: ${sourceKeyPair.accountId}
tx.fee: 100
tx.seqNum: 123456
tx.memo.type: MEMO_NONE
tx.operations.len: invalid
''';

      expect(
        () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
        throwsA(anything)
      );
    });

    test('throws exception for invalid signatures.len (too many)', () {
      final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: ${sourceKeyPair.accountId}
tx.fee: 100
tx.seqNum: 123456
tx.memo.type: MEMO_NONE
tx.operations.len: 0
tx.cond.type: PRECOND_NONE
tx.ext.v: 0
signatures.len: 21
''';

      expect(
        () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
        throwsA(anything)
      );
    });

    test('throws exception for invalid signatures.len (not a number)', () {
      final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: ${sourceKeyPair.accountId}
tx.fee: 100
tx.seqNum: 123456
tx.memo.type: MEMO_NONE
tx.operations.len: 0
tx.cond.type: PRECOND_NONE
tx.ext.v: 0
signatures.len: invalid
''';

      expect(
        () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
        throwsA(anything)
      );
    });

    test('throws exception for feeBump missing fee', () {
      final txRep = '''
type: ENVELOPE_TYPE_TX_FEE_BUMP
feeBump.tx.feeSource: ${destinationKeyPair.accountId}
feeBump.tx.innerTx.type: ENVELOPE_TYPE_TX
feeBump.tx.innerTx.tx.sourceAccount: ${sourceKeyPair.accountId}
feeBump.tx.innerTx.tx.fee: 100
feeBump.tx.innerTx.tx.seqNum: 123456
feeBump.tx.innerTx.tx.memo.type: MEMO_NONE
feeBump.tx.innerTx.tx.operations.len: 0
''';

      expect(
        () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
        throwsException
      );
    });

    test('throws exception for feeBump invalid fee', () {
      final txRep = '''
type: ENVELOPE_TYPE_TX_FEE_BUMP
feeBump.tx.feeSource: ${destinationKeyPair.accountId}
feeBump.tx.fee: invalid
feeBump.tx.innerTx.type: ENVELOPE_TYPE_TX
feeBump.tx.innerTx.tx.sourceAccount: ${sourceKeyPair.accountId}
feeBump.tx.innerTx.tx.fee: 100
feeBump.tx.innerTx.tx.seqNum: 123456
feeBump.tx.innerTx.tx.memo.type: MEMO_NONE
feeBump.tx.innerTx.tx.operations.len: 0
''';

      expect(
        () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
        throwsException
      );
    });

    test('throws exception for feeBump missing feeSource', () {
      final txRep = '''
type: ENVELOPE_TYPE_TX_FEE_BUMP
feeBump.tx.fee: 200
feeBump.tx.innerTx.type: ENVELOPE_TYPE_TX
feeBump.tx.innerTx.tx.sourceAccount: ${sourceKeyPair.accountId}
feeBump.tx.innerTx.tx.fee: 100
feeBump.tx.innerTx.tx.seqNum: 123456
feeBump.tx.innerTx.tx.memo.type: MEMO_NONE
feeBump.tx.innerTx.tx.operations.len: 0
''';

      expect(
        () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
        throwsException
      );
    });

    test('throws exception for feeBump invalid feeSource', () {
      final txRep = '''
type: ENVELOPE_TYPE_TX_FEE_BUMP
feeBump.tx.feeSource: INVALID_ACCOUNT
feeBump.tx.fee: 200
feeBump.tx.innerTx.type: ENVELOPE_TYPE_TX
feeBump.tx.innerTx.tx.sourceAccount: ${sourceKeyPair.accountId}
feeBump.tx.innerTx.tx.fee: 100
feeBump.tx.innerTx.tx.seqNum: 123456
feeBump.tx.innerTx.tx.memo.type: MEMO_NONE
feeBump.tx.innerTx.tx.operations.len: 0
''';

      expect(
        () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
        throwsException
      );
    });
  });

  group('TxRep Deep Testing - Muxed Accounts', () {
    test('converts transaction with muxed source account', () {
      final muxedSourceAccount = Account(
        sourceKeyPair.accountId,
        BigInt.from(2908908335136768),
        muxedAccountMed25519Id: BigInt.from(1234567890)
      );

      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).build();

      final transaction = TransactionBuilder(muxedSourceAccount)
        .addOperation(paymentOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.sourceAccount: M'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('converts operation with muxed destination', () {
      final muxedDestination = MuxedAccount(destinationKeyPair.accountId, BigInt.from(9876543210));

      final paymentOp = PaymentOperationBuilder.forMuxedDestinationAccount(
        muxedDestination,
        Asset.NATIVE,
        "50.0"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.paymentOp.destination: M'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('converts FeeBumpTransaction with muxed fee account', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).build();

      final innerTx = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .build();

      innerTx.sign(sourceKeyPair, testNetwork);

      final muxedFeeAccount = MuxedAccount(destinationKeyPair.accountId, BigInt.from(555555));
      final feeBumpTx = FeeBumpTransactionBuilder(innerTx)
        .setBaseFee(200)
        .setMuxedFeeAccount(muxedFeeAccount)
        .build();

      feeBumpTx.sign(destinationKeyPair, testNetwork);

      final xdr = feeBumpTx.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('type: ENVELOPE_TYPE_TX_FEE_BUMP'));
      expect(txRep, contains('feeBump.tx.feeSource: M'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('converts AccountMerge with muxed destination', () {
      final muxedDestination = MuxedAccount(destinationKeyPair.accountId, BigInt.from(777777));

      final accountMergeOp = AccountMergeOperationBuilder.forMuxedDestinationAccount(
        muxedDestination
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(accountMergeOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: ACCOUNT_MERGE'));
      expect(txRep, contains('tx.operations[0].body.destination: M'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('converts PathPaymentStrictReceive with muxed destination', () {
      final issuerKeyPair = KeyPair.random();
      final usd = AssetTypeCreditAlphaNum4("USD", issuerKeyPair.accountId);
      final eur = AssetTypeCreditAlphaNum4("EUR", issuerKeyPair.accountId);
      final muxedDestination = MuxedAccount(destinationKeyPair.accountId, BigInt.from(888888));

      final pathPaymentOp = PathPaymentStrictReceiveOperationBuilder.forMuxedDestinationAccount(
        usd,
        "100",
        muxedDestination,
        eur,
        "90"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(pathPaymentOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: PATH_PAYMENT_STRICT_RECEIVE'));
      expect(txRep, contains('pathPaymentStrictReceiveOp.destination: M'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('converts PathPaymentStrictSend with muxed destination', () {
      final issuerKeyPair = KeyPair.random();
      final usd = AssetTypeCreditAlphaNum4("USD", issuerKeyPair.accountId);
      final eur = AssetTypeCreditAlphaNum4("EUR", issuerKeyPair.accountId);
      final muxedDestination = MuxedAccount(destinationKeyPair.accountId, BigInt.from(999999));

      final pathPaymentOp = PathPaymentStrictSendOperationBuilder.forMuxedDestinationAccount(
        usd,
        "100",
        muxedDestination,
        eur,
        "90"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(pathPaymentOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: PATH_PAYMENT_STRICT_SEND'));
      expect(txRep, contains('pathPaymentStrictSendOp.destination: M'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });
  });
}
