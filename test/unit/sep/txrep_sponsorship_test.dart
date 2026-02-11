import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:typed_data';

void main() {
  group('TxRep Coverage Tests - Uncovered Branches', () {
    late KeyPair sourceKeyPair;
    late KeyPair destinationKeyPair;
    late String sourceAccountId;
    late String destinationAccountId;

    setUp(() {
      sourceKeyPair = KeyPair.fromSecretSeed(
          'SDJHRQF4GCMIIKAAAQ6IHY42X73FQFLHUULAPSKKD4DFDM7UXWWCRHBE');
      sourceAccountId = sourceKeyPair.accountId;
      destinationKeyPair = KeyPair.fromSecretSeed(
          'SAB5556L5AN5KSR5WF7UOEFDCIODEWEO7H2UR4S5R62DFTQOGLKOVZDY');
      destinationAccountId = destinationKeyPair.accountId;
    });

    group('BEGIN_SPONSORING_FUTURE_RESERVES Operation', () {
      test('toTxRep converts BEGIN_SPONSORING_FUTURE_RESERVES', () {
        final sourceAccount =
            Account(sourceAccountId, BigInt.from(2908908335136768));
        final sponsoredId = KeyPair.random().accountId;
        final operation =
            BeginSponsoringFutureReservesOperation(sponsoredId);

        final transaction =
            TransactionBuilder(sourceAccount).addOperation(operation).build();

        transaction.sign(sourceKeyPair, Network.TESTNET);
        final xdr = transaction.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep,
            contains('tx.operations[0].body.type: BEGIN_SPONSORING_FUTURE_RESERVES'));
        expect(txRep, contains('sponsoredID: $sponsoredId'));
      });

      test('fromTxRep parses BEGIN_SPONSORING_FUTURE_RESERVES', () {
        final sponsoredId = KeyPair.random().accountId;
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: BEGIN_SPONSORING_FUTURE_RESERVES
tx.operations[0].body.beginSponsoringFutureReservesOp.sponsoredID: $sponsoredId
signatures.len: 0
''';

        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('BEGIN_SPONSORING_FUTURE_RESERVES'));
        expect(roundTrip, contains(sponsoredId));
      });
    });

    group('END_SPONSORING_FUTURE_RESERVES Operation', () {
      test('toTxRep converts END_SPONSORING_FUTURE_RESERVES', () {
        final sourceAccount =
            Account(sourceAccountId, BigInt.from(2908908335136768));
        final operation = EndSponsoringFutureReservesOperation();

        final transaction =
            TransactionBuilder(sourceAccount).addOperation(operation).build();

        transaction.sign(sourceKeyPair, Network.TESTNET);
        final xdr = transaction.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep,
            contains('tx.operations[0].body.type: END_SPONSORING_FUTURE_RESERVES'));
      });

      test('fromTxRep parses END_SPONSORING_FUTURE_RESERVES', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: END_SPONSORING_FUTURE_RESERVES
signatures.len: 0
''';

        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('END_SPONSORING_FUTURE_RESERVES'));
      });
    });

    group('REVOKE_SPONSORSHIP Operation - Account', () {
      test('toTxRep converts REVOKE_SPONSORSHIP for account', () {
        final sourceAccount =
            Account(sourceAccountId, BigInt.from(2908908335136768));
        final accountToRevoke = KeyPair.random().accountId;
        final operation =
            RevokeSponsorshipOperationBuilder()
                .revokeAccountSponsorship(accountToRevoke)
                .build();

        final transaction =
            TransactionBuilder(sourceAccount).addOperation(operation).build();

        transaction.sign(sourceKeyPair, Network.TESTNET);
        final xdr = transaction.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep, contains('tx.operations[0].body.type: REVOKE_SPONSORSHIP'));
        expect(txRep, contains('type: REVOKE_SPONSORSHIP_LEDGER_ENTRY'));
        expect(txRep, contains('ledgerKey.type: ACCOUNT'));
        expect(txRep, contains(accountToRevoke));
      });

      test('fromTxRep parses REVOKE_SPONSORSHIP for account', () {
        final accountToRevoke = KeyPair.random().accountId;
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: REVOKE_SPONSORSHIP
tx.operations[0].body.revokeSponsorshipOp.type: REVOKE_SPONSORSHIP_LEDGER_ENTRY
tx.operations[0].body.revokeSponsorshipOp.ledgerKey.type: ACCOUNT
tx.operations[0].body.revokeSponsorshipOp.ledgerKey.account.accountID: $accountToRevoke
signatures.len: 0
''';

        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('REVOKE_SPONSORSHIP'));
        expect(roundTrip, contains(accountToRevoke));
      });
    });

    group('REVOKE_SPONSORSHIP Operation - Trustline', () {
      test('toTxRep converts REVOKE_SPONSORSHIP for trustline', () {
        final sourceAccount =
            Account(sourceAccountId, BigInt.from(2908908335136768));
        final issuer = KeyPair.random();
        final asset = AssetTypeCreditAlphaNum4('USD', issuer.accountId);
        final operation =
            RevokeSponsorshipOperationBuilder()
                .revokeTrustlineSponsorship(destinationAccountId, asset)
                .build();

        final transaction =
            TransactionBuilder(sourceAccount).addOperation(operation).build();

        transaction.sign(sourceKeyPair, Network.TESTNET);
        final xdr = transaction.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep, contains('tx.operations[0].body.type: REVOKE_SPONSORSHIP'));
        expect(txRep, contains('ledgerKey.type: TRUSTLINE'));
        expect(txRep, contains('USD'));
      });

      test('fromTxRep parses REVOKE_SPONSORSHIP for trustline', () {
        final issuer = KeyPair.random();
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: REVOKE_SPONSORSHIP
tx.operations[0].body.revokeSponsorshipOp.type: REVOKE_SPONSORSHIP_LEDGER_ENTRY
tx.operations[0].body.revokeSponsorshipOp.ledgerKey.type: TRUSTLINE
tx.operations[0].body.revokeSponsorshipOp.ledgerKey.trustLine.accountID: $destinationAccountId
tx.operations[0].body.revokeSponsorshipOp.ledgerKey.trustLine.asset: USD:${issuer.accountId}
signatures.len: 0
''';

        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('REVOKE_SPONSORSHIP'));
        expect(roundTrip, contains('TRUSTLINE'));
      });
    });

    group('REVOKE_SPONSORSHIP Operation - Offer', () {
      test('toTxRep converts REVOKE_SPONSORSHIP for offer', () {
        final sourceAccount =
            Account(sourceAccountId, BigInt.from(2908908335136768));
        final sellerId = KeyPair.random().accountId;
        final operation =
            RevokeSponsorshipOperationBuilder()
                .revokeOfferSponsorship(sellerId, 12345)
                .build();

        final transaction =
            TransactionBuilder(sourceAccount).addOperation(operation).build();

        transaction.sign(sourceKeyPair, Network.TESTNET);
        final xdr = transaction.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep, contains('tx.operations[0].body.type: REVOKE_SPONSORSHIP'));
        expect(txRep, contains('ledgerKey.type: OFFER'));
        expect(txRep, contains('offerID: 12345'));
      });

      test('fromTxRep parses REVOKE_SPONSORSHIP for offer', () {
        final sellerId = KeyPair.random().accountId;
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: REVOKE_SPONSORSHIP
tx.operations[0].body.revokeSponsorshipOp.type: REVOKE_SPONSORSHIP_LEDGER_ENTRY
tx.operations[0].body.revokeSponsorshipOp.ledgerKey.type: OFFER
tx.operations[0].body.revokeSponsorshipOp.ledgerKey.offer.sellerID: $sellerId
tx.operations[0].body.revokeSponsorshipOp.ledgerKey.offer.offerID: 12345
signatures.len: 0
''';

        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('REVOKE_SPONSORSHIP'));
        expect(roundTrip, contains('offerID: 12345'));
      });
    });

    group('REVOKE_SPONSORSHIP Operation - Data', () {
      test('toTxRep converts REVOKE_SPONSORSHIP for data entry', () {
        final sourceAccount =
            Account(sourceAccountId, BigInt.from(2908908335136768));
        final operation =
            RevokeSponsorshipOperationBuilder()
                .revokeDataSponsorship(destinationAccountId, 'test_key')
                .build();

        final transaction =
            TransactionBuilder(sourceAccount).addOperation(operation).build();

        transaction.sign(sourceKeyPair, Network.TESTNET);
        final xdr = transaction.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep, contains('tx.operations[0].body.type: REVOKE_SPONSORSHIP'));
        expect(txRep, contains('ledgerKey.type: DATA'));
        expect(txRep, contains('test_key'));
      });

      test('fromTxRep parses REVOKE_SPONSORSHIP for data entry', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: REVOKE_SPONSORSHIP
tx.operations[0].body.revokeSponsorshipOp.type: REVOKE_SPONSORSHIP_LEDGER_ENTRY
tx.operations[0].body.revokeSponsorshipOp.ledgerKey.type: DATA
tx.operations[0].body.revokeSponsorshipOp.ledgerKey.data.accountID: $destinationAccountId
tx.operations[0].body.revokeSponsorshipOp.ledgerKey.data.dataName: "test_key"
signatures.len: 0
''';

        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('REVOKE_SPONSORSHIP'));
        expect(roundTrip, contains('test_key'));
      });
    });

    group('REVOKE_SPONSORSHIP Operation - Signer variations', () {
      test('toTxRep converts REVOKE_SPONSORSHIP for ed25519 signer', () {
        final sourceAccount =
            Account(sourceAccountId, BigInt.from(2908908335136768));
        final signerKey = KeyPair.random().accountId;
        final operation =
            RevokeSponsorshipOperationBuilder()
                .revokeEd25519Signer(destinationAccountId, signerKey)
                .build();

        final transaction =
            TransactionBuilder(sourceAccount).addOperation(operation).build();

        transaction.sign(sourceKeyPair, Network.TESTNET);
        final xdr = transaction.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep, contains('tx.operations[0].body.type: REVOKE_SPONSORSHIP'));
        expect(txRep, contains('type: REVOKE_SPONSORSHIP_SIGNER'));
        expect(txRep, contains('signerKey: $signerKey'));
      });

      test('fromTxRep parses REVOKE_SPONSORSHIP for ed25519 signer', () {
        final signerKey = KeyPair.random().accountId;
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: REVOKE_SPONSORSHIP
tx.operations[0].body.revokeSponsorshipOp.type: REVOKE_SPONSORSHIP_SIGNER
tx.operations[0].body.revokeSponsorshipOp.signer.accountID: $destinationAccountId
tx.operations[0].body.revokeSponsorshipOp.signer.signerKey: $signerKey
signatures.len: 0
''';

        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('REVOKE_SPONSORSHIP'));
        expect(roundTrip, contains('REVOKE_SPONSORSHIP_SIGNER'));
      });
    });

    group('CLAWBACK_CLAIMABLE_BALANCE Operation', () {
      test('toTxRep converts CLAWBACK_CLAIMABLE_BALANCE', () {
        final sourceAccount =
            Account(sourceAccountId, BigInt.from(2908908335136768));
        final balanceId =
            'da0d57da7d4850e7fc10d2a9d0ebc731f7afb40574c03395b17d49149b91f5be';
        final operation = ClawbackClaimableBalanceOperation(balanceId);

        final transaction =
            TransactionBuilder(sourceAccount).addOperation(operation).build();

        transaction.sign(sourceKeyPair, Network.TESTNET);
        final xdr = transaction.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep,
            contains('tx.operations[0].body.type: CLAWBACK_CLAIMABLE_BALANCE'));
        expect(txRep, contains('balanceID.type: CLAIMABLE_BALANCE_ID_TYPE_V0'));
        expect(txRep, contains(balanceId));
      });

      test('fromTxRep parses CLAWBACK_CLAIMABLE_BALANCE', () {
        final balanceId =
            'da0d57da7d4850e7fc10d2a9d0ebc731f7afb40574c03395b17d49149b91f5be';
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: CLAWBACK_CLAIMABLE_BALANCE
tx.operations[0].body.clawbackClaimableBalanceOp.balanceID.type: CLAIMABLE_BALANCE_ID_TYPE_V0
tx.operations[0].body.clawbackClaimableBalanceOp.balanceID.v0: $balanceId
signatures.len: 0
''';

        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('CLAWBACK_CLAIMABLE_BALANCE'));
      });
    });

    group('CREATE_CLAIMABLE_BALANCE with complex predicates', () {
      test('toTxRep converts CREATE_CLAIMABLE_BALANCE with AND predicate', () {
        final sourceAccount =
            Account(sourceAccountId, BigInt.from(2908908335136768));
        final issuer = KeyPair.random();
        final asset = AssetTypeCreditAlphaNum4('USD', issuer.accountId);

        final pred1 =
            XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_UNCONDITIONAL);
        final pred2 =
            XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME);
        pred2.absBefore = XdrInt64(BigInt.from(1234567890));

        final andPredicate = XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_AND);
        andPredicate.andPredicates = [pred1, pred2];

        final claimant = Claimant(destinationAccountId, andPredicate);

        final operation =
            CreateClaimableBalanceOperation([claimant], asset, '100');

        final transaction =
            TransactionBuilder(sourceAccount).addOperation(operation).build();

        transaction.sign(sourceKeyPair, Network.TESTNET);
        final xdr = transaction.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep,
            contains('tx.operations[0].body.type: CREATE_CLAIMABLE_BALANCE'));
        expect(txRep, contains('predicate.type: CLAIM_PREDICATE_AND'));
        expect(txRep, contains('andPredicates.len: 2'));
      });

      test('toTxRep converts CREATE_CLAIMABLE_BALANCE with OR predicate', () {
        final sourceAccount =
            Account(sourceAccountId, BigInt.from(2908908335136768));
        final issuer = KeyPair.random();
        final asset = AssetTypeCreditAlphaNum4('USD', issuer.accountId);

        final pred1 =
            XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_UNCONDITIONAL);
        final pred2 =
            XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_BEFORE_RELATIVE_TIME);
        pred2.relBefore = XdrInt64(BigInt.from(3600));

        final orPredicate = XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_OR);
        orPredicate.orPredicates = [pred1, pred2];

        final claimant = Claimant(destinationAccountId, orPredicate);

        final operation =
            CreateClaimableBalanceOperation([claimant], asset, '100');

        final transaction =
            TransactionBuilder(sourceAccount).addOperation(operation).build();

        transaction.sign(sourceKeyPair, Network.TESTNET);
        final xdr = transaction.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep,
            contains('tx.operations[0].body.type: CREATE_CLAIMABLE_BALANCE'));
        expect(txRep, contains('predicate.type: CLAIM_PREDICATE_OR'));
        expect(txRep, contains('orPredicates.len: 2'));
      });

      test('toTxRep converts CREATE_CLAIMABLE_BALANCE with NOT predicate', () {
        final sourceAccount =
            Account(sourceAccountId, BigInt.from(2908908335136768));
        final issuer = KeyPair.random();
        final asset = AssetTypeCreditAlphaNum4('USD', issuer.accountId);

        final innerPred =
            XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME);
        innerPred.absBefore = XdrInt64(BigInt.from(9999999999));

        final notPredicate = XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_NOT);
        notPredicate.notPredicate = innerPred;

        final claimant = Claimant(destinationAccountId, notPredicate);

        final operation =
            CreateClaimableBalanceOperation([claimant], asset, '100');

        final transaction =
            TransactionBuilder(sourceAccount).addOperation(operation).build();

        transaction.sign(sourceKeyPair, Network.TESTNET);
        final xdr = transaction.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep,
            contains('tx.operations[0].body.type: CREATE_CLAIMABLE_BALANCE'));
        expect(txRep, contains('predicate.type: CLAIM_PREDICATE_NOT'));
      });
    });

    group('PATH_PAYMENT_STRICT_SEND Operation', () {
      test('toTxRep converts PATH_PAYMENT_STRICT_SEND', () {
        final sourceAccount =
            Account(sourceAccountId, BigInt.from(2908908335136768));
        final issuer = KeyPair.random();
        final usd = AssetTypeCreditAlphaNum4('USD', issuer.accountId);

        final operation = PathPaymentStrictSendOperationBuilder(
            Asset.NATIVE, '1000', destinationAccountId, usd, '95').build();

        final transaction =
            TransactionBuilder(sourceAccount).addOperation(operation).build();

        transaction.sign(sourceKeyPair, Network.TESTNET);
        final xdr = transaction.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep,
            contains('tx.operations[0].body.type: PATH_PAYMENT_STRICT_SEND'));
        expect(txRep, contains('sendAsset: XLM'));
        expect(txRep, contains('destMin:'));
      });

      test('fromTxRep parses PATH_PAYMENT_STRICT_SEND', () {
        final issuer = KeyPair.random();
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: PATH_PAYMENT_STRICT_SEND
tx.operations[0].body.pathPaymentStrictSendOp.sendAsset: XLM
tx.operations[0].body.pathPaymentStrictSendOp.sendAmount: 10000000000
tx.operations[0].body.pathPaymentStrictSendOp.destination: $destinationAccountId
tx.operations[0].body.pathPaymentStrictSendOp.destAsset: USD:${issuer.accountId}
tx.operations[0].body.pathPaymentStrictSendOp.destMin: 950000000
tx.operations[0].body.pathPaymentStrictSendOp.path.len: 0
signatures.len: 0
''';

        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('PATH_PAYMENT_STRICT_SEND'));
      });
    });

    group('SET_OPTIONS with preAuthTx signer', () {
      test('toTxRep converts SET_OPTIONS with preAuthTx signer', () {
        final sourceAccount =
            Account(sourceAccountId, BigInt.from(2908908335136768));
        final hash = Uint8List(32);
        for (int i = 0; i < 32; i++) {
          hash[i] = i * 2;
        }
        final xdrSignerKey = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_PRE_AUTH_TX);
        xdrSignerKey.preAuthTx = XdrUint256(hash);

        final operation =
            SetOptionsOperationBuilder().setSigner(xdrSignerKey, 15).build();

        final transaction =
            TransactionBuilder(sourceAccount).addOperation(operation).build();

        transaction.sign(sourceKeyPair, Network.TESTNET);
        final xdr = transaction.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep, contains('tx.operations[0].body.type: SET_OPTIONS'));
        expect(txRep, contains('signer.weight: 15'));
      });
    });

    group('SET_OPTIONS with all fields populated', () {
      test('toTxRep converts SET_OPTIONS with all fields', () {
        final sourceAccount =
            Account(sourceAccountId, BigInt.from(2908908335136768));
        final signerKey = KeyPair.random();
        final xdrSignerKey = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519);
        xdrSignerKey.ed25519 =
            XdrUint256(KeyPair.fromAccountId(signerKey.accountId).publicKey);

        final operation = SetOptionsOperationBuilder()
            .setInflationDestination(destinationAccountId)
            .setClearFlags(1)
            .setSetFlags(2)
            .setMasterKeyWeight(10)
            .setLowThreshold(5)
            .setMediumThreshold(7)
            .setHighThreshold(9)
            .setHomeDomain('example.com')
            .setSigner(xdrSignerKey, 5)
            .build();

        final transaction =
            TransactionBuilder(sourceAccount).addOperation(operation).build();

        transaction.sign(sourceKeyPair, Network.TESTNET);
        final xdr = transaction.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep, contains('tx.operations[0].body.type: SET_OPTIONS'));
        expect(txRep, contains('inflationDest: $destinationAccountId'));
        expect(txRep, contains('clearFlags: 1'));
        expect(txRep, contains('setFlags: 2'));
        expect(txRep, contains('masterWeight: 10'));
        expect(txRep, contains('lowThreshold: 5'));
        expect(txRep, contains('medThreshold: 7'));
        expect(txRep, contains('highThreshold: 9'));
        expect(txRep, contains('example.com'));
        expect(txRep, contains('signer.weight: 5'));
      });

      test('fromTxRep parses SET_OPTIONS with all fields', () {
        final signerKey = KeyPair.random().accountId;
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: SET_OPTIONS
tx.operations[0].body.setOptionsOp.inflationDest._present: true
tx.operations[0].body.setOptionsOp.inflationDest: $destinationAccountId
tx.operations[0].body.setOptionsOp.clearFlags._present: true
tx.operations[0].body.setOptionsOp.clearFlags: 1
tx.operations[0].body.setOptionsOp.setFlags._present: true
tx.operations[0].body.setOptionsOp.setFlags: 2
tx.operations[0].body.setOptionsOp.masterWeight._present: true
tx.operations[0].body.setOptionsOp.masterWeight: 10
tx.operations[0].body.setOptionsOp.lowThreshold._present: true
tx.operations[0].body.setOptionsOp.lowThreshold: 5
tx.operations[0].body.setOptionsOp.medThreshold._present: true
tx.operations[0].body.setOptionsOp.medThreshold: 7
tx.operations[0].body.setOptionsOp.highThreshold._present: true
tx.operations[0].body.setOptionsOp.highThreshold: 9
tx.operations[0].body.setOptionsOp.homeDomain._present: true
tx.operations[0].body.setOptionsOp.homeDomain: "example.com"
tx.operations[0].body.setOptionsOp.signer._present: true
tx.operations[0].body.setOptionsOp.signer.key: $signerKey
tx.operations[0].body.setOptionsOp.signer.weight: 5
signatures.len: 0
''';

        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('SET_OPTIONS'));
        expect(roundTrip, contains('inflationDest'));
      });
    });

    group('PRECOND_V2 with signed payload signer', () {
      test('fromTxRep parses PRECOND_V2 with signed payload extra signer', () {
        final sourceAccount =
            Account(sourceAccountId, BigInt.from(2908908335136768));
        final payload = Uint8List.fromList([1, 2, 3, 4, 5]);
        final ed25519 = KeyPair.random();
        final xdrPayload =
            XdrSignedPayload(XdrUint256(ed25519.publicKey), XdrDataValue(payload));
        final payloadStr = StrKey.encodeXdrSignedPayload(xdrPayload);

        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_V2
tx.cond.v2.timeBounds._present: false
tx.cond.v2.ledgerBounds._present: false
tx.cond.v2.minSeqNum._present: false
tx.cond.v2.minSeqAge: 0
tx.cond.v2.minSeqLedgerGap: 0
tx.cond.v2.extraSigners.len: 1
tx.cond.v2.extraSigners[0]: $payloadStr
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: PAYMENT
tx.operations[0].body.paymentOp.destination: $destinationAccountId
tx.operations[0].body.paymentOp.asset: XLM
tx.operations[0].body.paymentOp.amount: 1000000000
signatures.len: 0
''';

        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('PRECOND_V2'));
        expect(roundTrip, contains('extraSigners.len: 1'));
      });

      test('toTxRep converts transaction with signed payload extra signer', () {
        final sourceAccount =
            Account(sourceAccountId, BigInt.from(2908908335136768));
        final payload = Uint8List.fromList([10, 20, 30]);
        final ed25519 = KeyPair.random();

        final xdrSignerKey = XdrSignerKey(XdrSignerKeyType.KEY_TYPE_ED25519_SIGNED_PAYLOAD);
        xdrSignerKey.signedPayload =
            XdrSignedPayload(XdrUint256(ed25519.publicKey), XdrDataValue(payload));

        final preconditions = TransactionPreconditions();
        preconditions.minSeqAge = 0;
        preconditions.minSeqLedgerGap = 0;
        preconditions.extraSigners = [xdrSignerKey];

        final operation = PaymentOperation(
            MuxedAccount.fromAccountId(destinationAccountId)!,
            Asset.NATIVE,
            '100');

        final transaction = TransactionBuilder(sourceAccount)
            .addOperation(operation)
            .addPreconditions(preconditions)
            .build();

        transaction.sign(sourceKeyPair, Network.TESTNET);
        final xdr = transaction.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep, contains('tx.cond.type: PRECOND_V2'));
        expect(txRep, contains('extraSigners.len: 1'));
        expect(txRep, contains('extraSigners[0]: P'));
      });
    });

    group('Transaction with V0 envelope', () {
      test('TxRep handles transaction properly', () {
        final sourceAccount =
            Account(sourceAccountId, BigInt.from(2908908335136768));
        final operation = PaymentOperation(
            MuxedAccount.fromAccountId(destinationAccountId)!,
            Asset.NATIVE,
            '100');

        final transaction =
            TransactionBuilder(sourceAccount).addOperation(operation).build();

        transaction.sign(sourceKeyPair, Network.TESTNET);

        final xdr = transaction.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep, contains('type: ENVELOPE_TYPE_TX'));
        expect(txRep, contains('PAYMENT'));
        expect(txRep, contains('signatures.len: 1'));
      });
    });

    group('Fee bump transaction with signatures', () {
      test('toTxRep converts fee bump with multiple signatures', () {
        final sourceAccount =
            Account(sourceAccountId, BigInt.from(2908908335136768));
        final operation = PaymentOperation(
            MuxedAccount.fromAccountId(destinationAccountId)!,
            Asset.NATIVE,
            '100');

        final innerTx =
            TransactionBuilder(sourceAccount).addOperation(operation).build();

        innerTx.sign(sourceKeyPair, Network.TESTNET);

        final feeBumpTx = FeeBumpTransactionBuilder(innerTx)
            .setBaseFee(200)
            .setMuxedFeeAccount(MuxedAccount.fromAccountId(sourceAccountId)!)
            .build();

        feeBumpTx.sign(sourceKeyPair, Network.TESTNET);

        final xdr = feeBumpTx.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep, contains('type: ENVELOPE_TYPE_TX_FEE_BUMP'));
        expect(txRep, contains('feeBump.tx.innerTx.signatures.len: 1'));
        expect(txRep, contains('feeBump.signatures.len: 1'));
      });

      test('fromTxRep parses fee bump with inner and outer signatures', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX_FEE_BUMP
feeBump.tx.feeSource: $sourceAccountId
feeBump.tx.fee: 200
feeBump.tx.innerTx.type: ENVELOPE_TYPE_TX
feeBump.tx.innerTx.tx.sourceAccount: $sourceAccountId
feeBump.tx.innerTx.tx.fee: 100
feeBump.tx.innerTx.tx.seqNum: 2908908335136769
feeBump.tx.innerTx.tx.cond.type: PRECOND_NONE
feeBump.tx.innerTx.tx.memo.type: MEMO_NONE
feeBump.tx.innerTx.tx.ext.v: 0
feeBump.tx.innerTx.tx.operations.len: 1
feeBump.tx.innerTx.tx.operations[0].sourceAccount._present: false
feeBump.tx.innerTx.tx.operations[0].body.type: PAYMENT
feeBump.tx.innerTx.tx.operations[0].body.paymentOp.destination: $destinationAccountId
feeBump.tx.innerTx.tx.operations[0].body.paymentOp.asset: XLM
feeBump.tx.innerTx.tx.operations[0].body.paymentOp.amount: 1000000000
feeBump.tx.innerTx.signatures.len: 1
feeBump.tx.innerTx.signatures[0].hint: 01020304
feeBump.tx.innerTx.signatures[0].signature: 0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f40
feeBump.tx.ext.v: 0
feeBump.signatures.len: 1
feeBump.signatures[0].hint: 05060708
feeBump.signatures[0].signature: 1102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f40
''';

        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('ENVELOPE_TYPE_TX_FEE_BUMP'));
        expect(roundTrip, contains('feeBump.tx.innerTx.signatures.len: 1'));
      });
    });

    group('Transaction with muxed fee source in fee bump', () {
      test('toTxRep converts fee bump with muxed fee source', () {
        final sourceAccount =
            Account(sourceAccountId, BigInt.from(2908908335136768));
        final muxedId = BigInt.from(9876543210);
        final muxedFeeSource = MuxedAccount(sourceAccountId, muxedId);

        final operation = PaymentOperation(
            MuxedAccount.fromAccountId(destinationAccountId)!,
            Asset.NATIVE,
            '100');

        final innerTx =
            TransactionBuilder(sourceAccount).addOperation(operation).build();

        innerTx.sign(sourceKeyPair, Network.TESTNET);

        final feeBumpTx = FeeBumpTransactionBuilder(innerTx)
            .setBaseFee(200)
            .setMuxedFeeAccount(muxedFeeSource)
            .build();

        final xdr = feeBumpTx.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep, contains('type: ENVELOPE_TYPE_TX_FEE_BUMP'));
        expect(txRep, contains('feeBump.tx.feeSource: M'));
      });
    });

    group('Error handling - missing fields in parsing', () {
      test('throws on missing BEGIN_SPONSORING_FUTURE_RESERVES sponsoredID', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: BEGIN_SPONSORING_FUTURE_RESERVES
signatures.len: 0
''';

        expect(
          () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
          throwsException,
        );
      });

      test('throws on missing REVOKE_SPONSORSHIP type', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: REVOKE_SPONSORSHIP
signatures.len: 0
''';

        expect(
          () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
          throwsException,
        );
      });

      test('throws on invalid REVOKE_SPONSORSHIP ledger key type', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: REVOKE_SPONSORSHIP
tx.operations[0].body.revokeSponsorshipOp.type: REVOKE_SPONSORSHIP_LEDGER_ENTRY
signatures.len: 0
''';

        expect(
          () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
          throwsException,
        );
      });

      test('throws on missing CLAWBACK_CLAIMABLE_BALANCE balanceID', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: CLAWBACK_CLAIMABLE_BALANCE
tx.operations[0].body.clawbackClaimableBalanceOp.balanceID.type: CLAIMABLE_BALANCE_ID_TYPE_V0
signatures.len: 0
''';

        expect(
          () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
          throwsException,
        );
      });

      test('throws on missing PATH_PAYMENT_STRICT_SEND destMin', () {
        final issuer = KeyPair.random();
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: PATH_PAYMENT_STRICT_SEND
tx.operations[0].body.pathPaymentStrictSendOp.sendAsset: XLM
tx.operations[0].body.pathPaymentStrictSendOp.sendAmount: 10000000000
tx.operations[0].body.pathPaymentStrictSendOp.destination: $destinationAccountId
tx.operations[0].body.pathPaymentStrictSendOp.destAsset: USD:${issuer.accountId}
tx.operations[0].body.pathPaymentStrictSendOp.path.len: 0
signatures.len: 0
''';

        expect(
          () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
          throwsException,
        );
      });
    });

    group('Amount formatting with comments', () {
      test('_removeComment helper strips amount comments correctly', () {
        final sourceAccount =
            Account(sourceAccountId, BigInt.from(2908908335136768));
        final operation = PaymentOperation(
            MuxedAccount.fromAccountId(destinationAccountId)!,
            Asset.NATIVE,
            '123.4567890');

        final transaction =
            TransactionBuilder(sourceAccount).addOperation(operation).build();

        transaction.sign(sourceKeyPair, Network.TESTNET);
        final xdr = transaction.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep, contains('amount: 1234567890'));

        final roundTrip = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(roundTrip, isNotEmpty);
      });
    });

    group('Multiple operations parsing', () {
      test('fromTxRep parses transaction with 5 operations', () {
        final operations = StringBuffer();
        for (int i = 0; i < 5; i++) {
          operations.write('''
tx.operations[$i].sourceAccount._present: false
tx.operations[$i].body.type: BUMP_SEQUENCE
tx.operations[$i].body.bumpSequenceOp.bumpTo: ${BigInt.parse('9999999999999999') + BigInt.from(i)}
''');
        }

        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 500
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 5
$operations
signatures.len: 0
''';

        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('tx.operations.len: 5'));
      });
    });

    group('Transaction with maximum operations', () {
      test('fromTxRep accepts maximum operations', () {
        final operations = StringBuffer();
        for (int i = 0; i < 100; i++) {
          operations.write('''
tx.operations[$i].sourceAccount._present: false
tx.operations[$i].body.type: BUMP_SEQUENCE
tx.operations[$i].body.bumpSequenceOp.bumpTo: ${BigInt.parse('9999999999999999') + BigInt.from(i)}
''');
        }

        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 10000
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 100
$operations
signatures.len: 0
''';

        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);
      });

      test('fromTxRep rejects too many operations', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 101
signatures.len: 0
''';

        expect(
          () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
          throwsException,
        );
      });
    });

    group('Price edge cases', () {
      test('toTxRep converts MANAGE_SELL_OFFER with high precision price', () {
        final sourceAccount =
            Account(sourceAccountId, BigInt.from(2908908335136768));
        final issuer = KeyPair.random();
        final usd = AssetTypeCreditAlphaNum4('USD', issuer.accountId);

        final operation = ManageSellOfferOperation(
            Asset.NATIVE, usd, '1000', '123456789.1234567', '0');

        final transaction =
            TransactionBuilder(sourceAccount).addOperation(operation).build();

        transaction.sign(sourceKeyPair, Network.TESTNET);
        final xdr = transaction.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep, contains('tx.operations[0].body.type: MANAGE_SELL_OFFER'));
        expect(txRep, contains('price.n:'));
        expect(txRep, contains('price.d:'));
      });

      test('toTxRep converts MANAGE_BUY_OFFER with fractional price', () {
        final sourceAccount =
            Account(sourceAccountId, BigInt.from(2908908335136768));
        final issuer = KeyPair.random();
        final usd = AssetTypeCreditAlphaNum4('USD', issuer.accountId);

        final operation = ManageBuyOfferOperation(
            Asset.NATIVE, usd, '1000', '0.5', '0');

        final transaction =
            TransactionBuilder(sourceAccount).addOperation(operation).build();

        transaction.sign(sourceKeyPair, Network.TESTNET);
        final xdr = transaction.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep, contains('tx.operations[0].body.type: MANAGE_BUY_OFFER'));
        expect(txRep, contains('price.n:'));
        expect(txRep, contains('price.d:'));
      });
    });
  });
}
