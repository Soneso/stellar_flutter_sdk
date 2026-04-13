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
        BigInt.parse('9999999999999999')
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

    test('MEMO_TEXT with non-ASCII uses SEP-0011 \\xNN UTF-8 byte escaping', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .addMemo(Memo.text("café"))
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      // Per SEP-0011, U+00E9 (é) is encoded as its UTF-8 bytes 0xC3 0xA9
      // using \xNN escapes, not as the JSON \u00e9 form.
      expect(txRep, contains(r'tx.memo.text: "caf\xc3\xa9"'));
      expect(txRep, isNot(contains(r'\u00e9')));

      // And it must round-trip back to the original XDR.
      final reconstructedXdr =
          TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('MEMO_TEXT decode accepts legacy \\uNNNN JSON escapes', () {
      // Build a reference envelope using the new \xNN encoding, then
      // rewrite the memo line to use the legacy \u00e9 form that older
      // versions of this SDK produced. Decoding must still succeed and
      // yield the same XDR.
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .addMemo(Memo.text("café"))
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);
      final legacyTxRep = txRep.replaceFirst(
        r'tx.memo.text: "caf\xc3\xa9"',
        r'tx.memo.text: "caf\u00e9"',
      );
      expect(legacyTxRep, isNot(equals(txRep)));

      final reconstructedXdr =
          TxRep.transactionEnvelopeXdrBase64FromTxRep(legacyTxRep);
      expect(reconstructedXdr, equals(xdr));
    });

    // Helper: build a signed envelope carrying the given memo text and
    // assert that TxRep encode/decode round-trips back to the same XDR.
    String memoTextRoundTrip(String memoText) {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0",
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .addMemo(Memo.text(memoText))
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);
      final reconstructedXdr =
          TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      expect(reconstructedXdr, equals(xdr));
      return txRep;
    }

    test('MEMO_TEXT with newline uses \\n short escape', () {
      final txRep = memoTextRoundTrip('line1\nline2');
      expect(txRep, contains(r'tx.memo.text: "line1\nline2"'));
    });

    test('MEMO_TEXT with 4-byte UTF-8 (emoji) encodes as four \\xNN bytes', () {
      // U+1F680 ROCKET = F0 9F 9A 80
      final txRep = memoTextRoundTrip('go \u{1F680}');
      expect(txRep, contains(r'tx.memo.text: "go \xf0\x9f\x9a\x80"'));
    });

    test('MEMO_TEXT empty string round-trips', () {
      final txRep = memoTextRoundTrip('');
      expect(txRep, contains('tx.memo.text: ""'));
    });

    test('MEMO_TEXT containing literal backslash-u is not misrouted', () {
      // The text contains the literal 2-char sequence \u (backslash + u).
      // After SEP-0011 escaping the backslash doubles, so the encoded form
      // contains \\u — the legacy-detection regex must NOT treat that as a
      // \uNNNN escape, and decode must preserve the original text.
      final txRep = memoTextRoundTrip(r'lit \user');
      expect(txRep, contains(r'tx.memo.text: "lit \\user"'));
    });

    test('MEMO_TEXT at 28-byte UTF-8 boundary with multibyte chars', () {
      // 14 x 'é' = 28 UTF-8 bytes (2 bytes each), the Stellar memo text limit.
      final txRep = memoTextRoundTrip('é' * 14);
      expect(txRep, contains(r'\xc3\xa9' * 14));
    });

    test('MEMO_TEXT legacy decode preserves embedded quote escapes', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0",
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .addMemo(Memo.text('café "x"'))
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      // Legacy form (older SDK output): JSON \uNNNN escapes plus \" for quotes.
      final legacyTxRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr)
          .replaceFirst(
            r'tx.memo.text: "caf\xc3\xa9 \"x\""',
            r'tx.memo.text: "caf\u00e9 \"x\""',
          );

      final reconstructedXdr =
          TxRep.transactionEnvelopeXdrBase64FromTxRep(legacyTxRep);
      expect(reconstructedXdr, equals(xdr));
    });

    test('MEMO_TEXT missing text field throws', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0",
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .addMemo(Memo.text('hello'))
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(
        transaction.toEnvelopeXdrBase64(),
      );
      // Drop the tx.memo.text line entirely.
      final broken = txRep
          .split('\n')
          .where((l) => !l.startsWith('tx.memo.text:'))
          .join('\n');

      expect(
        () => TxRep.transactionEnvelopeXdrBase64FromTxRep(broken),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('missing tx.memo.text'),
          ),
        ),
      );
    });

    test('MEMO_TEXT malformed legacy \\uNNNN sequence throws', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0",
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .addMemo(Memo.text('hello'))
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(
        transaction.toEnvelopeXdrBase64(),
      );
      // Contains a valid-looking \u0041 (trips the legacy-unicode heuristic)
      // followed by an invalid JSON escape \z, so jsonDecode throws and the
      // facade rewraps the FormatException.
      final broken = txRep.replaceFirst(
        'tx.memo.text: "hello"',
        r'tx.memo.text: "\u0041\z"',
      );

      expect(
        () => TxRep.transactionEnvelopeXdrBase64FromTxRep(broken),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('invalid tx.memo.text (legacy'),
          ),
        ),
      );
    });

    test('MEMO_TEXT malformed \\xNN UTF-8 sequence throws', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0",
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .addMemo(Memo.text('hello'))
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(
        transaction.toEnvelopeXdrBase64(),
      );
      // A lone 0xC3 is an incomplete UTF-8 sequence (0xC3 is a 2-byte
      // lead byte); decoding must throw FormatException which the facade
      // rewraps as a TxRep-style Exception.
      final broken = txRep.replaceFirst(
        'tx.memo.text: "hello"',
        r'tx.memo.text: "\xc3"',
      );

      expect(
        () => TxRep.transactionEnvelopeXdrBase64FromTxRep(broken),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('invalid tx.memo.text'),
          ),
        ),
      );
    });

    test('encodes V0 envelope without time bounds', () {
      // Build a V0 transaction envelope directly (legacy format).
      final sourceBytes = StrKey.decodeStellarAccountId(sourceKeyPair.accountId);
      final v0tx = XdrTransactionV0(
        XdrUint256(sourceBytes),
        XdrUint32(100),
        XdrSequenceNumber(BigInt.from(1)),
        null, // no time bounds → exercises PRECOND_NONE branch
        XdrMemo(XdrMemoType.MEMO_NONE),
        [],
        XdrTransactionV0Ext(0),
      );
      final envelope =
          XdrTransactionEnvelope(XdrEnvelopeType.ENVELOPE_TYPE_TX_V0)
            ..v0 = XdrTransactionV0Envelope(v0tx, []);

      final txRep =
          TxRep.fromTransactionEnvelopeXdrBase64(envelope.toBase64EncodedXdrString());

      expect(txRep, contains('type: ENVELOPE_TYPE_TX'));
      expect(txRep, contains('tx.sourceAccount: ${sourceKeyPair.accountId}'));
      expect(txRep, contains('tx.cond.type: PRECOND_NONE'));
    });

    test('encodes V0 envelope with time bounds', () {
      final sourceBytes = StrKey.decodeStellarAccountId(sourceKeyPair.accountId);
      final tb = XdrTimeBounds(
        XdrUint64(BigInt.from(1000)),
        XdrUint64(BigInt.from(2000)),
      );
      final v0tx = XdrTransactionV0(
        XdrUint256(sourceBytes),
        XdrUint32(100),
        XdrSequenceNumber(BigInt.from(1)),
        tb, // time bounds present → exercises PRECOND_TIME branch
        XdrMemo(XdrMemoType.MEMO_NONE),
        [],
        XdrTransactionV0Ext(0),
      );
      final envelope =
          XdrTransactionEnvelope(XdrEnvelopeType.ENVELOPE_TYPE_TX_V0)
            ..v0 = XdrTransactionV0Envelope(v0tx, []);

      final txRep =
          TxRep.fromTransactionEnvelopeXdrBase64(envelope.toBase64EncodedXdrString());

      expect(txRep, contains('tx.cond.type: PRECOND_TIME'));
      expect(txRep, contains('tx.cond.timeBounds.minTime: 1000'));
      expect(txRep, contains('tx.cond.timeBounds.maxTime: 2000'));
    });

    test('decodes legacy tx.timeBounds._present format', () {
      // Hand-written TxRep using the legacy tx.timeBounds._present: true
      // shape instead of tx.cond.
      final txRep = [
        'type: ENVELOPE_TYPE_TX',
        'tx.sourceAccount: ${sourceKeyPair.accountId}',
        'tx.fee: 100',
        'tx.seqNum: 1',
        'tx.timeBounds._present: true',
        'tx.timeBounds.minTime: 1000',
        'tx.timeBounds.maxTime: 2000',
        'tx.memo.type: MEMO_NONE',
        'tx.operations.len: 0',
        'tx.ext.v: 0',
        'signatures.len: 0',
      ].join('\n');

      final reconstructed = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
      final envelope = XdrTransactionEnvelope.fromEnvelopeXdrString(
        reconstructed,
      );
      expect(
        envelope.v1!.tx.cond.discriminant,
        equals(XdrPreconditionType.PRECOND_TIME),
      );
      expect(
        envelope.v1!.tx.cond.timeBounds!.minTime.uint64,
        equals(BigInt.from(1000)),
      );
      expect(
        envelope.v1!.tx.cond.timeBounds!.maxTime.uint64,
        equals(BigInt.from(2000)),
      );
    });

    test('decode throws on missing type header', () {
      final txRep = [
        'tx.sourceAccount: ${sourceKeyPair.accountId}',
        'tx.fee: 100',
      ].join('\n');

      expect(
        () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('unsupported or missing TxRep type'),
          ),
        ),
      );
    });

    test('decode throws on fee-bump inner type mismatch', () {
      // Build a real fee-bump TxRep by round-tripping a fee-bump envelope,
      // then flip the inner type to something unexpected.
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0",
      ).build();
      final inner = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .build();
      inner.sign(sourceKeyPair, testNetwork);

      final feeBump = FeeBumpTransactionBuilder(inner)
        .setBaseFee(200)
        .setFeeAccount(sourceKeyPair.accountId)
        .build();
      feeBump.sign(sourceKeyPair, testNetwork);

      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(
        feeBump.toEnvelopeXdrBase64(),
      );
      final broken = txRep.replaceFirst(
        'feeBump.tx.innerTx.type: ENVELOPE_TYPE_TX',
        'feeBump.tx.innerTx.type: ENVELOPE_TYPE_TX_V0',
      );

      expect(
        () => TxRep.transactionEnvelopeXdrBase64FromTxRep(broken),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('unexpected feeBump.tx.innerTx.type'),
          ),
        ),
      );
    });

    test('decode throws on unknown memo type', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0",
      ).build();
      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .build();
      transaction.sign(sourceKeyPair, testNetwork);

      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(
        transaction.toEnvelopeXdrBase64(),
      );
      final broken = txRep.replaceFirst(
        'tx.memo.type: MEMO_NONE',
        'tx.memo.type: MEMO_BOGUS',
      );

      expect(
        () => TxRep.transactionEnvelopeXdrBase64FromTxRep(broken),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('unknown memo type: MEMO_BOGUS'),
          ),
        ),
      );
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

    test('handles memo text with quotes and backslashes', () {
      final paymentOp = PaymentOperationBuilder(
        destinationKeyPair.accountId,
        Asset.NATIVE,
        "100.0"
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .addMemo(Memo.text('Say "hi" \\ ok'))
        .build();

      transaction.sign(sourceKeyPair, testNetwork);

      final xdr = transaction.toEnvelopeXdrBase64();
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

      expect(txRep, contains(r'Say \"hi\" \\ ok'));

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
