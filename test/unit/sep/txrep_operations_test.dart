import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:typed_data';

void main() {
  group('TxRep Operation-Specific Coverage Tests', () {
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

    group('ALLOW_TRUST with AlphaNum12', () {
      test('toTxRep converts ALLOW_TRUST with alphanum12 asset', () {
        final sourceAccount = Account(sourceAccountId, BigInt.from(2908908335136768));
        final longAssetCode = 'LONGASSET123';
        final operation = AllowTrustOperationBuilder(destinationAccountId, longAssetCode, 1).build();

        final transaction = TransactionBuilder(sourceAccount)
            .addOperation(operation)
            .build();

        transaction.sign(sourceKeyPair, Network.TESTNET);
        final xdr = transaction.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep, contains('tx.operations[0].body.type: ALLOW_TRUST'));
        expect(txRep, contains('asset: $longAssetCode'));
        expect(txRep, contains('authorize: 1'));
      });

      test('fromTxRep parses ALLOW_TRUST with alphanum12 asset', () {
        final longAssetCode = 'LONGASSET123';
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
tx.operations[0].body.type: ALLOW_TRUST
tx.operations[0].body.allowTrustOp.trustor: $destinationAccountId
tx.operations[0].body.allowTrustOp.asset: $longAssetCode
tx.operations[0].body.allowTrustOp.authorize: 2
signatures.len: 0
''';

        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('ALLOW_TRUST'));
        expect(roundTrip, contains(longAssetCode));
        expect(roundTrip, contains('authorize: 2'));
      });
    });

    group('PATH_PAYMENT_STRICT_RECEIVE with paths', () {
      test('toTxRep converts PATH_PAYMENT_STRICT_RECEIVE with 3 path assets', () {
        final sourceAccount = Account(sourceAccountId, BigInt.from(2908908335136768));
        final issuer = KeyPair.random();
        final usd = AssetTypeCreditAlphaNum4('USD', issuer.accountId);
        final eur = AssetTypeCreditAlphaNum4('EUR', issuer.accountId);
        final gbp = AssetTypeCreditAlphaNum4('GBP', issuer.accountId);

        final operation = PathPaymentStrictReceiveOperationBuilder(
                Asset.NATIVE, '1000', destinationAccountId, usd, '100')
            .setPath([eur, gbp, Asset.NATIVE])
            .build();

        final transaction = TransactionBuilder(sourceAccount)
            .addOperation(operation)
            .build();

        transaction.sign(sourceKeyPair, Network.TESTNET);
        final xdr = transaction.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep, contains('tx.operations[0].body.type: PATH_PAYMENT_STRICT_RECEIVE'));
        expect(txRep, contains('path.len: 3'));
        expect(txRep, contains('path[0]:'));
        expect(txRep, contains('path[1]:'));
        expect(txRep, contains('path[2]:'));
      });

      test('fromTxRep parses PATH_PAYMENT_STRICT_RECEIVE with path', () {
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
tx.operations[0].body.type: PATH_PAYMENT_STRICT_RECEIVE
tx.operations[0].body.pathPaymentStrictReceiveOp.sendAsset: XLM
tx.operations[0].body.pathPaymentStrictReceiveOp.sendMax: 10000000000
tx.operations[0].body.pathPaymentStrictReceiveOp.destination: $destinationAccountId
tx.operations[0].body.pathPaymentStrictReceiveOp.destAsset: USD:${issuer.accountId}
tx.operations[0].body.pathPaymentStrictReceiveOp.destAmount: 1000000000
tx.operations[0].body.pathPaymentStrictReceiveOp.path.len: 2
tx.operations[0].body.pathPaymentStrictReceiveOp.path[0]: EUR:${issuer.accountId}
tx.operations[0].body.pathPaymentStrictReceiveOp.path[1]: XLM
signatures.len: 0
''';

        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('PATH_PAYMENT_STRICT_RECEIVE'));
        expect(roundTrip, contains('path.len: 2'));
      });
    });

    group('MANAGE_SELL_OFFER edge cases', () {
      test('toTxRep converts MANAGE_SELL_OFFER with zero price', () {
        final sourceAccount = Account(sourceAccountId, BigInt.from(2908908335136768));
        final issuer = KeyPair.random();
        final usd = AssetTypeCreditAlphaNum4('USD', issuer.accountId);

        final operation = ManageSellOfferOperation(
            Asset.NATIVE, usd, '1000', '0', '0');

        final transaction = TransactionBuilder(sourceAccount)
            .addOperation(operation)
            .build();

        transaction.sign(sourceKeyPair, Network.TESTNET);
        final xdr = transaction.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep, contains('tx.operations[0].body.type: MANAGE_SELL_OFFER'));
        expect(txRep, contains('price.n: 0'));
      });

      test('toTxRep converts MANAGE_SELL_OFFER delete with offerID', () {
        final sourceAccount = Account(sourceAccountId, BigInt.from(2908908335136768));
        final issuer = KeyPair.random();
        final usd = AssetTypeCreditAlphaNum4('USD', issuer.accountId);

        final operation = ManageSellOfferOperation(
            Asset.NATIVE, usd, '0', '1.5', '12345');

        final transaction = TransactionBuilder(sourceAccount)
            .addOperation(operation)
            .build();

        transaction.sign(sourceKeyPair, Network.TESTNET);
        final xdr = transaction.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep, contains('tx.operations[0].body.type: MANAGE_SELL_OFFER'));
        expect(txRep, contains('amount: 0'));
        expect(txRep, contains('offerID: 12345'));
      });
    });

    group('BUMP_SEQUENCE Operation', () {
      test('toTxRep converts BUMP_SEQUENCE operation', () {
        final sourceAccount = Account(sourceAccountId, BigInt.from(2908908335136768));
        final bumpTo = BigInt.from(9999999999999999);
        final operation = BumpSequenceOperation(bumpTo);

        final transaction = TransactionBuilder(sourceAccount)
            .addOperation(operation)
            .build();

        transaction.sign(sourceKeyPair, Network.TESTNET);
        final xdr = transaction.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep, contains('tx.operations[0].body.type: BUMP_SEQUENCE'));
        expect(txRep, contains('bumpTo: $bumpTo'));
      });

      test('fromTxRep parses BUMP_SEQUENCE operation', () {
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
tx.operations[0].body.type: BUMP_SEQUENCE
tx.operations[0].body.bumpSequenceOp.bumpTo: 9999999999999999
signatures.len: 0
''';

        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('BUMP_SEQUENCE'));
        expect(roundTrip, contains('9999999999999999'));
      });
    });

    group('SET_TRUSTLINE_FLAGS all combinations', () {
      test('toTxRep converts SET_TRUSTLINE_FLAGS with both set and clear', () {
        final sourceAccount = Account(sourceAccountId, BigInt.from(2908908335136768));
        final issuer = KeyPair.random();
        final usd = AssetTypeCreditAlphaNum4('USD', issuer.accountId);

        final operation = SetTrustLineFlagsOperationBuilder(
                destinationAccountId, usd, 1, 2)
            .build();

        final transaction = TransactionBuilder(sourceAccount)
            .addOperation(operation)
            .build();

        transaction.sign(sourceKeyPair, Network.TESTNET);
        final xdr = transaction.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep, contains('tx.operations[0].body.type: SET_TRUST_LINE_FLAGS'));
        expect(txRep, contains('clearFlags: 1'));
        expect(txRep, contains('setFlags: 2'));
      });

      test('toTxRep converts SET_TRUSTLINE_FLAGS with all clear flags', () {
        final sourceAccount = Account(sourceAccountId, BigInt.from(2908908335136768));
        final issuer = KeyPair.random();
        final usd = AssetTypeCreditAlphaNum4('USD', issuer.accountId);

        final operation = SetTrustLineFlagsOperationBuilder(
                destinationAccountId, usd, 7, 0)
            .build();

        final transaction = TransactionBuilder(sourceAccount)
            .addOperation(operation)
            .build();

        transaction.sign(sourceKeyPair, Network.TESTNET);
        final xdr = transaction.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep, contains('tx.operations[0].body.type: SET_TRUST_LINE_FLAGS'));
        expect(txRep, contains('clearFlags: 7'));
      });

      test('fromTxRep parses SET_TRUSTLINE_FLAGS with both set and clear', () {
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
tx.operations[0].body.type: SET_TRUST_LINE_FLAGS
tx.operations[0].body.setTrustLineFlagsOp.trustor: $destinationAccountId
tx.operations[0].body.setTrustLineFlagsOp.asset: USD:${issuer.accountId}
tx.operations[0].body.setTrustLineFlagsOp.clearFlags: 1
tx.operations[0].body.setTrustLineFlagsOp.setFlags: 2
signatures.len: 0
''';

        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('SET_TRUST_LINE_FLAGS'));
        expect(roundTrip, contains('clearFlags: 1'));
        expect(roundTrip, contains('setFlags: 2'));
      });
    });

    group('Transaction with no signatures', () {
      test('toTxRep converts transaction with zero signatures', () {
        final sourceAccount = Account(sourceAccountId, BigInt.from(2908908335136768));
        final destination = MuxedAccount.fromAccountId(destinationAccountId)!;
        final operation = PaymentOperation(destination, Asset.NATIVE, '100');

        final transaction = TransactionBuilder(sourceAccount)
            .addOperation(operation)
            .build();

        final xdr = transaction.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep, contains('signatures.len: 0'));
        expect(txRep, contains('tx.operations.len: 1'));
      });
    });

    group('Operations with muxed source accounts', () {
      test('toTxRep converts operation with muxed source account', () {
        final sourceAccount = Account(sourceAccountId, BigInt.from(2908908335136768));
        final muxedId = BigInt.from(9876543210);
        final muxedSource = MuxedAccount(destinationAccountId, muxedId);
        final operation = PaymentOperationBuilder(destinationAccountId, Asset.NATIVE, '100')
            .setMuxedSourceAccount(muxedSource)
            .build();

        final transaction = TransactionBuilder(sourceAccount)
            .addOperation(operation)
            .build();

        transaction.sign(sourceKeyPair, Network.TESTNET);
        final xdr = transaction.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep, contains('sourceAccount._present: true'));
        expect(txRep, contains('sourceAccount: MBKHPLNGLNIWZNYM3RTIBUGBJAQD62AAURRYMFJDYK2VCUWHLUMU'));
      });

      test('toTxRep converts CREATE_ACCOUNT with muxed source', () {
        final sourceAccount = Account(sourceAccountId, BigInt.from(2908908335136768));
        final muxedId = BigInt.from(1234567890);
        final muxedSource = MuxedAccount(destinationAccountId, muxedId);

        final newAccount = KeyPair.random();
        final operation = CreateAccountOperationBuilder(newAccount.accountId, '1000')
            .setMuxedSourceAccount(muxedSource)
            .build();

        final transaction = TransactionBuilder(sourceAccount)
            .addOperation(operation)
            .build();

        transaction.sign(sourceKeyPair, Network.TESTNET);
        final xdr = transaction.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep, contains('tx.operations[0].body.type: CREATE_ACCOUNT'));
        expect(txRep, contains('sourceAccount._present: true'));
      });
    });

    group('Very large amounts', () {
      test('toTxRep converts payment with maximum amount', () {
        final sourceAccount = Account(sourceAccountId, BigInt.from(2908908335136768));
        final destination = MuxedAccount.fromAccountId(destinationAccountId)!;
        final maxAmount = '922337203685.4775807';
        final operation = PaymentOperation(destination, Asset.NATIVE, maxAmount);

        final transaction = TransactionBuilder(sourceAccount)
            .addOperation(operation)
            .build();

        transaction.sign(sourceKeyPair, Network.TESTNET);
        final xdr = transaction.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep, contains('tx.operations[0].body.type: PAYMENT'));
        expect(txRep, contains('amount: 9223372036854775807'));
      });

      test('fromTxRep parses payment with maximum amount', () {
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
tx.operations[0].body.type: PAYMENT
tx.operations[0].body.paymentOp.destination: $destinationAccountId
tx.operations[0].body.paymentOp.asset: XLM
tx.operations[0].body.paymentOp.amount: 9223372036854775807
signatures.len: 0
''';

        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('amount: 9223372036854775807'));
      });
    });

    group('Empty memo vs no memo', () {
      test('toTxRep converts transaction with empty MEMO_TEXT', () {
        final sourceAccount = Account(sourceAccountId, BigInt.from(2908908335136768));
        final destination = MuxedAccount.fromAccountId(destinationAccountId)!;
        final operation = PaymentOperation(destination, Asset.NATIVE, '100');

        final transaction = TransactionBuilder(sourceAccount)
            .addOperation(operation)
            .addMemo(MemoText(''))
            .build();

        transaction.sign(sourceKeyPair, Network.TESTNET);
        final xdr = transaction.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep, contains('tx.memo.type: MEMO_TEXT'));
        expect(txRep, contains('tx.memo.text: ""'));
      });

      test('fromTxRep parses transaction with empty MEMO_TEXT', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_TEXT
tx.memo.text: ""
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
        expect(roundTrip, contains('tx.memo.type: MEMO_TEXT'));
      });
    });

    group('CLAWBACK operation variants', () {
      test('toTxRep converts CLAWBACK with alphanum12', () {
        final sourceAccount = Account(sourceAccountId, BigInt.from(2908908335136768));
        final issuer = KeyPair.random();
        final longAsset = AssetTypeCreditAlphaNum12('LONGASSET123', issuer.accountId);
        final from = MuxedAccount.fromAccountId(destinationAccountId)!;

        final operation = ClawbackOperation(from, longAsset, '500.5');

        final transaction = TransactionBuilder(sourceAccount)
            .addOperation(operation)
            .build();

        transaction.sign(sourceKeyPair, Network.TESTNET);
        final xdr = transaction.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep, contains('tx.operations[0].body.type: CLAWBACK'));
        expect(txRep, contains('LONGASSET123'));
      });

    });

    group('SET_OPTIONS with signer variations', () {
      test('toTxRep converts SET_OPTIONS with ed25519 public key signer', () {
        final sourceAccount = Account(sourceAccountId, BigInt.from(2908908335136768));
        final signerKey = KeyPair.random();
        final xdrSignerKey = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519);
        xdrSignerKey.ed25519 = XdrUint256(KeyPair.fromAccountId(signerKey.accountId).publicKey);

        final operation = SetOptionsOperationBuilder()
            .setSigner(xdrSignerKey, 10)
            .build();

        final transaction = TransactionBuilder(sourceAccount)
            .addOperation(operation)
            .build();

        transaction.sign(sourceKeyPair, Network.TESTNET);
        final xdr = transaction.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep, contains('tx.operations[0].body.type: SET_OPTIONS'));
        expect(txRep, contains('signer.weight: 10'));
        expect(txRep, contains('signer.key:'));
      });

      test('toTxRep converts SET_OPTIONS with hashX signer', () {
        final sourceAccount = Account(sourceAccountId, BigInt.from(2908908335136768));
        final hash = Uint8List(32);
        for (int i = 0; i < 32; i++) {
          hash[i] = i;
        }
        final xdrSignerKey = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_HASH_X);
        xdrSignerKey.hashX = XdrUint256(hash);

        final operation = SetOptionsOperationBuilder()
            .setSigner(xdrSignerKey, 5)
            .build();

        final transaction = TransactionBuilder(sourceAccount)
            .addOperation(operation)
            .build();

        transaction.sign(sourceKeyPair, Network.TESTNET);
        final xdr = transaction.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep, contains('tx.operations[0].body.type: SET_OPTIONS'));
        expect(txRep, contains('signer.weight: 5'));
        expect(txRep, contains('signer.key:'));
      });
    });

    group('MEMO_RETURN handling', () {
      test('toTxRep converts transaction with MEMO_RETURN', () {
        final sourceAccount = Account(sourceAccountId, BigInt.from(2908908335136768));
        final destination = MuxedAccount.fromAccountId(destinationAccountId)!;
        final operation = PaymentOperation(destination, Asset.NATIVE, '100');
        final hash = Uint8List(32);
        for (int i = 0; i < 32; i++) {
          hash[i] = 255 - i;
        }

        final transaction = TransactionBuilder(sourceAccount)
            .addOperation(operation)
            .addMemo(MemoReturnHash(hash))
            .build();

        transaction.sign(sourceKeyPair, Network.TESTNET);
        final xdr = transaction.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep, contains('tx.memo.type: MEMO_RETURN'));
        expect(txRep, contains('tx.memo.retHash:'));
      });

    });

    group('CREATE_PASSIVE_SELL_OFFER edge cases', () {
      test('toTxRep converts CREATE_PASSIVE_SELL_OFFER with alphanum12', () {
        final sourceAccount = Account(sourceAccountId, BigInt.from(2908908335136768));
        final issuer = KeyPair.random();
        final longAsset = AssetTypeCreditAlphaNum12('LONGASSET123', issuer.accountId);

        final operation = CreatePassiveSellOfferOperation(
            longAsset, Asset.NATIVE, '1000.5', '1.75');

        final transaction = TransactionBuilder(sourceAccount)
            .addOperation(operation)
            .build();

        transaction.sign(sourceKeyPair, Network.TESTNET);
        final xdr = transaction.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep, contains('tx.operations[0].body.type: CREATE_PASSIVE_SELL_OFFER'));
        expect(txRep, contains('LONGASSET123'));
      });

      test('fromTxRep parses CREATE_PASSIVE_SELL_OFFER', () {
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
tx.operations[0].body.type: CREATE_PASSIVE_SELL_OFFER
tx.operations[0].body.createPassiveSellOfferOp.selling: USD:${issuer.accountId}
tx.operations[0].body.createPassiveSellOfferOp.buying: XLM
tx.operations[0].body.createPassiveSellOfferOp.amount: 10000000000
tx.operations[0].body.createPassiveSellOfferOp.price.n: 7
tx.operations[0].body.createPassiveSellOfferOp.price.d: 4
signatures.len: 0
''';

        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('CREATE_PASSIVE_SELL_OFFER'));
      });
    });

    group('Amount formatting edge cases', () {
      test('toTxRep formats small amounts correctly', () {
        final sourceAccount = Account(sourceAccountId, BigInt.from(2908908335136768));
        final destination = MuxedAccount.fromAccountId(destinationAccountId)!;
        final operation = PaymentOperation(destination, Asset.NATIVE, '0.0000001');

        final transaction = TransactionBuilder(sourceAccount)
            .addOperation(operation)
            .build();

        transaction.sign(sourceKeyPair, Network.TESTNET);
        final xdr = transaction.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep, contains('amount: 1'));
      });

      test('toTxRep formats amounts with trailing zeros', () {
        final sourceAccount = Account(sourceAccountId, BigInt.from(2908908335136768));
        final destination = MuxedAccount.fromAccountId(destinationAccountId)!;
        final operation = PaymentOperation(destination, Asset.NATIVE, '100.0000000');

        final transaction = TransactionBuilder(sourceAccount)
            .addOperation(operation)
            .build();

        transaction.sign(sourceKeyPair, Network.TESTNET);
        final xdr = transaction.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep, contains('amount: 1000000000'));
      });
    });

    group('MANAGE_BUY_OFFER edge cases', () {
      test('toTxRep converts MANAGE_BUY_OFFER with complex price', () {
        final sourceAccount = Account(sourceAccountId, BigInt.from(2908908335136768));
        final issuer = KeyPair.random();
        final usd = AssetTypeCreditAlphaNum4('USD', issuer.accountId);

        final operation = ManageBuyOfferOperation(
            Asset.NATIVE, usd, '1000', '0.123456789', '0');

        final transaction = TransactionBuilder(sourceAccount)
            .addOperation(operation)
            .build();

        transaction.sign(sourceKeyPair, Network.TESTNET);
        final xdr = transaction.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep, contains('tx.operations[0].body.type: MANAGE_BUY_OFFER'));
        expect(txRep, contains('price.n:'));
        expect(txRep, contains('price.d:'));
      });

      test('fromTxRep parses MANAGE_BUY_OFFER with zero offerID', () {
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
tx.operations[0].body.type: MANAGE_BUY_OFFER
tx.operations[0].body.manageBuyOfferOp.selling: XLM
tx.operations[0].body.manageBuyOfferOp.buying: USD:${issuer.accountId}
tx.operations[0].body.manageBuyOfferOp.buyAmount: 10000000000
tx.operations[0].body.manageBuyOfferOp.price.n: 1
tx.operations[0].body.manageBuyOfferOp.price.d: 1
tx.operations[0].body.manageBuyOfferOp.offerID: 0
signatures.len: 0
''';

        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('MANAGE_BUY_OFFER'));
        expect(roundTrip, contains('offerID: 0'));
      });
    });


    group('Multiple operations with different source accounts', () {
      test('toTxRep converts transaction with mixed source accounts', () {
        final sourceAccount = Account(sourceAccountId, BigInt.from(2908908335136768));
        final opSource1 = KeyPair.random();
        final opSource2 = KeyPair.random();
        final destination = MuxedAccount.fromAccountId(destinationAccountId)!;

        final op1 = PaymentOperationBuilder(destinationAccountId, Asset.NATIVE, '100')
            .setSourceAccount(opSource1.accountId)
            .build();

        final op2 = PaymentOperationBuilder(destinationAccountId, Asset.NATIVE, '200')
            .setSourceAccount(opSource2.accountId)
            .build();

        final op3 = PaymentOperation(destination, Asset.NATIVE, '300');

        final transaction = TransactionBuilder(sourceAccount)
            .addOperation(op1)
            .addOperation(op2)
            .addOperation(op3)
            .build();

        transaction.sign(sourceKeyPair, Network.TESTNET);
        final xdr = transaction.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep, contains('tx.operations.len: 3'));
        expect(txRep, contains(opSource1.accountId));
        expect(txRep, contains(opSource2.accountId));
      });
    });

    group('CHANGE_TRUST with limit variations', () {
      test('toTxRep converts CHANGE_TRUST with max limit', () {
        final sourceAccount = Account(sourceAccountId, BigInt.from(2908908335136768));
        final issuer = KeyPair.random();
        final usd = AssetTypeCreditAlphaNum4('USD', issuer.accountId);

        final operation = ChangeTrustOperation(usd, '922337203685.4775807');

        final transaction = TransactionBuilder(sourceAccount)
            .addOperation(operation)
            .build();

        transaction.sign(sourceKeyPair, Network.TESTNET);
        final xdr = transaction.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep, contains('tx.operations[0].body.type: CHANGE_TRUST'));
        expect(txRep, contains('limit: 9223372036854775807'));
      });

      test('toTxRep converts CHANGE_TRUST delete (limit 0)', () {
        final sourceAccount = Account(sourceAccountId, BigInt.from(2908908335136768));
        final issuer = KeyPair.random();
        final usd = AssetTypeCreditAlphaNum4('USD', issuer.accountId);

        final operation = ChangeTrustOperation(usd, '0');

        final transaction = TransactionBuilder(sourceAccount)
            .addOperation(operation)
            .build();

        transaction.sign(sourceKeyPair, Network.TESTNET);
        final xdr = transaction.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep, contains('tx.operations[0].body.type: CHANGE_TRUST'));
        expect(txRep, contains('limit: 0'));
      });
    });

    group('Asset code edge cases', () {
      test('toTxRep handles asset code with 4 characters exactly', () {
        final sourceAccount = Account(sourceAccountId, BigInt.from(2908908335136768));
        final issuer = KeyPair.random();
        final asset = AssetTypeCreditAlphaNum4('ABCD', issuer.accountId);
        final destination = MuxedAccount.fromAccountId(destinationAccountId)!;

        final operation = PaymentOperation(destination, asset, '100');

        final transaction = TransactionBuilder(sourceAccount)
            .addOperation(operation)
            .build();

        transaction.sign(sourceKeyPair, Network.TESTNET);
        final xdr = transaction.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep, contains('asset: ABCD:'));
      });

      test('toTxRep handles asset code with 12 characters exactly', () {
        final sourceAccount = Account(sourceAccountId, BigInt.from(2908908335136768));
        final issuer = KeyPair.random();
        final asset = AssetTypeCreditAlphaNum12('ABCDEFGHIJKL', issuer.accountId);
        final destination = MuxedAccount.fromAccountId(destinationAccountId)!;

        final operation = PaymentOperation(destination, asset, '100');

        final transaction = TransactionBuilder(sourceAccount)
            .addOperation(operation)
            .build();

        transaction.sign(sourceKeyPair, Network.TESTNET);
        final xdr = transaction.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep, contains('asset: ABCDEFGHIJKL:'));
      });

      test('toTxRep handles asset code with 5 characters (alphanum12)', () {
        final sourceAccount = Account(sourceAccountId, BigInt.from(2908908335136768));
        final issuer = KeyPair.random();
        final asset = AssetTypeCreditAlphaNum12('ABCDE', issuer.accountId);
        final destination = MuxedAccount.fromAccountId(destinationAccountId)!;

        final operation = PaymentOperation(destination, asset, '100');

        final transaction = TransactionBuilder(sourceAccount)
            .addOperation(operation)
            .build();

        transaction.sign(sourceKeyPair, Network.TESTNET);
        final xdr = transaction.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep, contains('asset: ABCDE:'));
      });
    });
  });
}
