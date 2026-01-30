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

  group('TxRep - Transaction Conversion', () {
    test('converts simple payment transaction to TxRep', () {
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

      expect(txRep, contains('type: ENVELOPE_TYPE_TX'));
      expect(txRep, contains('tx.sourceAccount: ${sourceKeyPair.accountId}'));
      expect(txRep, contains('tx.operations.len: 1'));
      expect(txRep, contains('PAYMENT'));
    });

    test('converts transaction with multiple operations to TxRep', () {
      final paymentOp1 = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).build();

      final paymentOp2 = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "50.0"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp1)
        .addOperation(paymentOp2)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations.len: 2'));
      expect(txRep, contains('tx.operations[0].body.type: PAYMENT'));
      expect(txRep, contains('tx.operations[1].body.type: PAYMENT'));
    });

    test('converts transaction with MEMO_TEXT to TxRep', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .addMemo(Memo.text("Test payment"))
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.memo.type: MEMO_TEXT'));
      expect(txRep, contains('tx.memo.text: "Test payment"'));
    });

    test('converts transaction with MEMO_ID to TxRep', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .addMemo(Memo.id(BigInt.from(12345)))
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.memo.type: MEMO_ID'));
      expect(txRep, contains('tx.memo.id: 12345'));
    });

    test('converts transaction with MEMO_HASH to TxRep', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).build();

      final hash = Uint8List.fromList(List<int>.filled(32, 1));
      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .addMemo(Memo.hash(hash))
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.memo.type: MEMO_HASH'));
      expect(txRep, contains('tx.memo.hash:'));
    });

    test('converts transaction with MEMO_RETURN to TxRep', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).build();

      final hash = Uint8List.fromList(List<int>.filled(32, 2));
      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .addMemo(Memo.returnHash(hash))
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.memo.type: MEMO_RETURN'));
      expect(txRep, contains('tx.memo.retHash:'));
    });

    test('converts transaction with time bounds to TxRep', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).build();

      final timeBounds = TimeBounds(1000, 2000);
      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .addTimeBounds(timeBounds)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.cond.type: PRECOND_TIME'));
      expect(txRep, contains('tx.cond.timeBounds.minTime: 1000'));
      expect(txRep, contains('tx.cond.timeBounds.maxTime: 2000'));
    });

    test('converts CreateAccount operation to TxRep', () {
      final createAccountOp = CreateAccountOperationBuilder(
        destinationKeyPair.accountId,
        "1000"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(createAccountOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: CREATE_ACCOUNT'));
      expect(txRep, contains('tx.operations[0].body.createAccountOp.destination: ${destinationKeyPair.accountId}'));
      expect(txRep, contains('tx.operations[0].body.createAccountOp.startingBalance: 10000000000'));
    });

    test('converts PathPaymentStrictReceive operation to TxRep', () {
      final issuerKeyPair = KeyPair.random();
      final usd = AssetTypeCreditAlphaNum4("USD", issuerKeyPair.accountId);
      final eur = AssetTypeCreditAlphaNum4("EUR", issuerKeyPair.accountId);

      final pathPaymentOp = PathPaymentStrictReceiveOperationBuilder(
        usd,
        "100",
        destinationKeyPair.accountId,
        eur,
        "90"
      ).setPath([Asset.NATIVE]).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(pathPaymentOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: PATH_PAYMENT_STRICT_RECEIVE'));
      expect(txRep, contains('pathPaymentStrictReceiveOp'));
    });

    test('converts PathPaymentStrictSend operation to TxRep', () {
      final issuerKeyPair = KeyPair.random();
      final usd = AssetTypeCreditAlphaNum4("USD", issuerKeyPair.accountId);
      final eur = AssetTypeCreditAlphaNum4("EUR", issuerKeyPair.accountId);

      final pathPaymentOp = PathPaymentStrictSendOperationBuilder(
        usd,
        "100",
        destinationKeyPair.accountId,
        eur,
        "90"
      ).setPath([Asset.NATIVE]).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(pathPaymentOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: PATH_PAYMENT_STRICT_SEND'));
      expect(txRep, contains('pathPaymentStrictSendOp'));
    });

    test('converts ManageSellOffer operation to TxRep', () {
      final issuerKeyPair = KeyPair.random();
      final usd = AssetTypeCreditAlphaNum4("USD", issuerKeyPair.accountId);

      final manageSellOfferOp = ManageSellOfferOperationBuilder(
        usd,
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
      expect(txRep, contains('manageSellOfferOp'));
    });

    test('converts ManageBuyOffer operation to TxRep', () {
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
    });

    test('converts CreatePassiveSellOffer operation to TxRep', () {
      final issuerKeyPair = KeyPair.random();
      final usd = AssetTypeCreditAlphaNum4("USD", issuerKeyPair.accountId);

      final createPassiveSellOfferOp = CreatePassiveSellOfferOperationBuilder(
        usd,
        Asset.NATIVE,
        "100",
        "0.5"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(createPassiveSellOfferOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: CREATE_PASSIVE_SELL_OFFER'));
      expect(txRep, contains('createPassiveSellOfferOp'));
    });

    test('converts SetOptions operation to TxRep', () {
      final setOptionsOp = SetOptionsOperationBuilder()
        .setInflationDestination(destinationKeyPair.accountId)
        .setHomeDomain("example.com")
        .build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(setOptionsOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: SET_OPTIONS'));
      expect(txRep, contains('setOptionsOp'));
    });

    test('converts ChangeTrust operation to TxRep', () {
      final issuerKeyPair = KeyPair.random();
      final usd = AssetTypeCreditAlphaNum4("USD", issuerKeyPair.accountId);

      final changeTrustOp = ChangeTrustOperationBuilder(
        usd,
        "10000"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(changeTrustOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: CHANGE_TRUST'));
      expect(txRep, contains('changeTrustOp'));
    });

    test('converts AllowTrust operation to TxRep', () {
      final allowTrustOp = AllowTrustOperationBuilder(
        destinationKeyPair.accountId,
        "USD",
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
    });

    test('converts AccountMerge operation to TxRep', () {
      final accountMergeOp = AccountMergeOperationBuilder(
        destinationKeyPair.accountId
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(accountMergeOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: ACCOUNT_MERGE'));
    });

    test('converts ManageData operation to TxRep', () {
      final manageDataOp = ManageDataOperationBuilder(
        "test_key",
        Uint8List.fromList("test_value".codeUnits)
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(manageDataOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: MANAGE_DATA'));
      expect(txRep, contains('manageDataOp'));
    });

    test('converts BumpSequence operation to TxRep', () {
      final bumpSequenceOp = BumpSequenceOperationBuilder(
        BigInt.from(9999999999999999)
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(bumpSequenceOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.type: BUMP_SEQUENCE'));
      expect(txRep, contains('bumpSequenceOp'));
    });

    test('converts transaction with custom fee to TxRep', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .setMaxOperationFee(500)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.fee: 500'));
    });

    test('converts transaction with source account to TxRep', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).setSourceAccount(destinationKeyPair.accountId).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].sourceAccount._present: true'));
      expect(txRep, contains('tx.operations[0].sourceAccount: ${destinationKeyPair.accountId}'));
    });

    test('converts FeeBumpTransaction to TxRep', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).build();

      final innerTx = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .build();

      innerTx.sign(sourceKeyPair, testNetwork);

      final feeBumpTx = FeeBumpTransactionBuilder(innerTx)
        .setBaseFee(200)
        .setFeeAccount(destinationKeyPair.accountId)
        .build();

      feeBumpTx.sign(destinationKeyPair, testNetwork);

      final xdr = feeBumpTx.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('type: ENVELOPE_TYPE_TX_FEE_BUMP'));
      expect(txRep, contains('feeBump.tx.feeSource: ${destinationKeyPair.accountId}'));
      expect(txRep, contains('feeBump.tx.innerTx.type: ENVELOPE_TYPE_TX'));
    });

    test('includes signatures in TxRep', () {
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

      expect(txRep, contains('signatures.len: 1'));
      expect(txRep, contains('signatures[0].hint:'));
      expect(txRep, contains('signatures[0].signature:'));
    });

    test('includes multiple signatures in TxRep', () {
      final signer2 = KeyPair.random();
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

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('signatures.len: 2'));
      expect(txRep, contains('signatures[0].hint:'));
      expect(txRep, contains('signatures[1].hint:'));
    });
  });

  group('TxRep - Round-trip Conversion', () {
    test('round-trip: simple payment transaction', () {
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
      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);

      expect(reconstructedXdr, equals(xdr));
    });

    test('round-trip: transaction with MEMO_TEXT', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .addMemo(Memo.text("Test memo"))
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);
      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);

      expect(reconstructedXdr, equals(xdr));
    });

    test('round-trip: transaction with MEMO_ID', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .addMemo(Memo.id(BigInt.from(999888777)))
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);
      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);

      expect(reconstructedXdr, equals(xdr));
    });

    test('round-trip: transaction with MEMO_HASH', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).build();

      final hash = Uint8List.fromList(List<int>.filled(32, 5));
      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .addMemo(Memo.hash(hash))
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);
      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);

      expect(reconstructedXdr, equals(xdr));
    });

    test('round-trip: transaction with time bounds', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).build();

      final timeBounds = TimeBounds(5000, 10000);
      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .addTimeBounds(timeBounds)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);
      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);

      expect(reconstructedXdr, equals(xdr));
    });

    test('round-trip: transaction with multiple operations', () {
      final paymentOp1 = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).build();

      final paymentOp2 = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "50.0"
      ).build();

      final paymentOp3 = PaymentOperationBuilder(
        sourceKeyPair.accountId,
        Asset.NATIVE,
        "25.0"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp1)
        .addOperation(paymentOp2)
        .addOperation(paymentOp3)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);
      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);

      expect(reconstructedXdr, equals(xdr));
    });

    test('round-trip: CreateAccount operation', () {
      final createAccountOp = CreateAccountOperationBuilder(
        destinationKeyPair.accountId,
        "500"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(createAccountOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);
      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);

      expect(reconstructedXdr, equals(xdr));
    });

    test('round-trip: ManageData operation', () {
      final manageDataOp = ManageDataOperationBuilder(
        "config_key",
        Uint8List.fromList("config_value".codeUnits)
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(manageDataOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);
      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);

      expect(reconstructedXdr, equals(xdr));
    });

    test('round-trip: ChangeTrust operation', () {
      final issuerKeyPair = KeyPair.random();
      final usd = AssetTypeCreditAlphaNum4("USD", issuerKeyPair.accountId);

      final changeTrustOp = ChangeTrustOperationBuilder(
        usd,
        "5000"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(changeTrustOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);
      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);

      expect(reconstructedXdr, equals(xdr));
    });

    test('round-trip: FeeBumpTransaction', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).build();

      final innerTx = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
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
      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);

      expect(reconstructedXdr, equals(xdr));
    });
  });

  group('TxRep - Edge Cases', () {
    test('handles transaction with special characters in memo text', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .addMemo(Memo.text("Test: special chars @#\$%"))
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);
      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);

      expect(reconstructedXdr, equals(xdr));
    });

    test('handles transaction with large amount', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "922337203685.4775807"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations[0].body.paymentOp.amount:'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('handles transaction with zero amount', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "0"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);
      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);

      expect(reconstructedXdr, equals(xdr));
    });

    test('handles transaction with maximum operations count', () {
      final transaction = TransactionBuilder(sourceAccount);

      for (int i = 0; i < 100; i++) {
        transaction.addOperation(
          PaymentOperationBuilder(
            destinationKeyPair.accountId,
            Asset.NATIVE,
            "1"
          ).build()
        );
      }

      final tx = transaction.build();
      tx.sign(sourceKeyPair, testNetwork);

      final xdr = tx.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.operations.len: 100'));
    });

    test('handles transaction with AlphaNum12 asset', () {
      final issuerKeyPair = KeyPair.random();
      final longAsset = AssetTypeCreditAlphaNum12("LONGASSET123", issuerKeyPair.accountId);

      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        longAsset,
        "100.0"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);
      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);

      expect(reconstructedXdr, equals(xdr));
    });

    test('handles transaction with very large sequence number', () {
      final largeSeqAccount = Account(
        sourceKeyPair.accountId,
        BigInt.parse("9223372036854775800")
      );

      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "10.0"
      ).build();

      final transaction = TransactionBuilder(largeSeqAccount)
        .addOperation(paymentOp)
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.seqNum: 9223372036854775801'));
    });

    test('handles transaction with no memo (MEMO_NONE)', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .addMemo(Memo.none())
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains('tx.memo.type: MEMO_NONE'));

      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('parses TxRep with comments correctly', () {
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
      var txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      final lines = txRep.split('\n');
      final modifiedLines = lines.map((line) {
        if (line.startsWith('tx.fee:')) {
          return '$line (comment: base fee)';
        }
        return line;
      }).toList();

      txRep = modifiedLines.join('\n');
      final reconstructedXdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);

      final originalTx = AbstractTransaction.fromEnvelopeXdrString(xdr) as Transaction;
      final reconstructedTx = AbstractTransaction.fromEnvelopeXdrString(reconstructedXdr) as Transaction;

      expect(reconstructedTx.fee, equals(originalTx.fee));
    });
  });

  group('TxRep - Format Validation', () {
    test('TxRep output contains required fields', () {
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

      expect(txRep, contains('type:'));
      expect(txRep, contains('tx.sourceAccount:'));
      expect(txRep, contains('tx.fee:'));
      expect(txRep, contains('tx.seqNum:'));
      expect(txRep, contains('tx.memo.type:'));
      expect(txRep, contains('tx.operations.len:'));
    });

    test('TxRep uses proper key-value format', () {
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

      final lines = txRep.split('\n');
      for (var line in lines) {
        if (line.trim().isNotEmpty) {
          expect(line, contains(':'));
        }
      }
    });

    test('TxRep is line-based text format', () {
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

      expect(txRep.contains('\n'), isTrue);

      final lines = txRep.split('\n');
      expect(lines.length, greaterThan(10));
    });
  });
}
