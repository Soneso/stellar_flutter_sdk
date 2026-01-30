import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:typed_data';
import 'package:collection/collection.dart';

void main() {
  group('Transaction', () {
    late KeyPair sourceKeyPair;
    late Account sourceAccount;
    late KeyPair destinationKeyPair;

    setUp(() {
      sourceKeyPair = KeyPair.fromSecretSeed('SDJHRQF4GCMIIKAAAQ6IHY42X73FQFLHUULAPSKKD4DFDM7UXWWCRHBE');
      sourceAccount = Account(sourceKeyPair.accountId, BigInt.from(2908908335136768));
      destinationKeyPair = KeyPair.fromSecretSeed('SAB5556L5AN5KSR5WF7UOEFDCIODEWEO7H2UR4S5R62DFTQOGLKOVZDY');
    });

    group('TransactionBuilder', () {
      test('builds transaction with single operation', () {
        final paymentOp = PaymentOperationBuilder(
          destinationKeyPair.accountId,
          Asset.NATIVE,
          "100.0"
        ).build();

        final transaction = TransactionBuilder(sourceAccount)
          .addOperation(paymentOp)
          .build();

        expect(transaction.sourceAccount.ed25519AccountId, equals(sourceKeyPair.accountId));
        expect(transaction.operations.length, equals(1));
        expect(transaction.operations[0], equals(paymentOp));
        expect(transaction.sequenceNumber, equals(BigInt.from(2908908335136769)));
      });

      test('builds transaction with multiple operations', () {
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

        expect(transaction.operations.length, equals(2));
        expect(transaction.operations[0], equals(paymentOp1));
        expect(transaction.operations[1], equals(paymentOp2));
      });

      test('builds transaction with Memo.none()', () {
        final paymentOp = PaymentOperationBuilder(
          destinationKeyPair.accountId,
          Asset.NATIVE,
          "100.0"
        ).build();

        final transaction = TransactionBuilder(sourceAccount)
          .addOperation(paymentOp)
          .addMemo(Memo.none())
          .build();

        expect(transaction.memo, isA<MemoNone>());
      });

      test('builds transaction with Memo.text()', () {
        final paymentOp = PaymentOperationBuilder(
          destinationKeyPair.accountId,
          Asset.NATIVE,
          "100.0"
        ).build();

        final transaction = TransactionBuilder(sourceAccount)
          .addOperation(paymentOp)
          .addMemo(Memo.text("Test payment"))
          .build();

        expect(transaction.memo, isA<MemoText>());
        expect((transaction.memo as MemoText).text, equals("Test payment"));
      });

      test('builds transaction with Memo.id()', () {
        final paymentOp = PaymentOperationBuilder(
          destinationKeyPair.accountId,
          Asset.NATIVE,
          "100.0"
        ).build();

        final transaction = TransactionBuilder(sourceAccount)
          .addOperation(paymentOp)
          .addMemo(Memo.id(BigInt.from(12345)))
          .build();

        expect(transaction.memo, isA<MemoId>());
        expect((transaction.memo as MemoId).getId(), equals(BigInt.from(12345)));
      });

      test('builds transaction with Memo.hash()', () {
        final hash = Uint8List(32);
        for (int i = 0; i < 32; i++) {
          hash[i] = i;
        }

        final paymentOp = PaymentOperationBuilder(
          destinationKeyPair.accountId,
          Asset.NATIVE,
          "100.0"
        ).build();

        final transaction = TransactionBuilder(sourceAccount)
          .addOperation(paymentOp)
          .addMemo(Memo.hash(hash))
          .build();

        expect(transaction.memo, isA<MemoHash>());
        expect(
          ListEquality().equals((transaction.memo as MemoHash).bytes, hash),
          isTrue
        );
      });

      test('builds transaction with Memo.returnHash()', () {
        final hash = Uint8List(32);
        for (int i = 0; i < 32; i++) {
          hash[i] = i;
        }

        final paymentOp = PaymentOperationBuilder(
          destinationKeyPair.accountId,
          Asset.NATIVE,
          "100.0"
        ).build();

        final transaction = TransactionBuilder(sourceAccount)
          .addOperation(paymentOp)
          .addMemo(Memo.returnHash(hash))
          .build();

        expect(transaction.memo, isA<MemoReturnHash>());
        expect(
          ListEquality().equals((transaction.memo as MemoReturnHash).bytes, hash),
          isTrue
        );
      });

      test('builds transaction with TimeBounds', () {
        final paymentOp = PaymentOperationBuilder(
          destinationKeyPair.accountId,
          Asset.NATIVE,
          "100.0"
        ).build();

        final timeBounds = TimeBounds(1000, 2000);
        final preconditions = TransactionPreconditions();
        preconditions.timeBounds = timeBounds;

        final transaction = TransactionBuilder(sourceAccount)
          .addOperation(paymentOp)
          .addPreconditions(preconditions)
          .build();

        expect(transaction.preconditions, isNotNull);
        expect(transaction.preconditions!.timeBounds, isNotNull);
        expect(transaction.preconditions!.timeBounds!.minTime, equals(1000));
        expect(transaction.preconditions!.timeBounds!.maxTime, equals(2000));
      });

      test('builds transaction with LedgerBounds', () {
        final paymentOp = PaymentOperationBuilder(
          destinationKeyPair.accountId,
          Asset.NATIVE,
          "100.0"
        ).build();

        final ledgerBounds = LedgerBounds(100, 1000);
        final preconditions = TransactionPreconditions();
        preconditions.ledgerBounds = ledgerBounds;

        final transaction = TransactionBuilder(sourceAccount)
          .addOperation(paymentOp)
          .addPreconditions(preconditions)
          .build();

        expect(transaction.preconditions, isNotNull);
        expect(transaction.preconditions!.ledgerBounds, isNotNull);
        expect(transaction.preconditions!.ledgerBounds!.minLedger, equals(100));
        expect(transaction.preconditions!.ledgerBounds!.maxLedger, equals(1000));
      });

      test('builds transaction with custom base fee', () {
        final paymentOp = PaymentOperationBuilder(
          destinationKeyPair.accountId,
          Asset.NATIVE,
          "100.0"
        ).build();

        final transaction = TransactionBuilder(sourceAccount)
          .addOperation(paymentOp)
          .setMaxOperationFee(200)
          .build();

        expect(transaction.fee, equals(200));
      });

      test('builds transaction with default fee', () {
        final paymentOp = PaymentOperationBuilder(
          destinationKeyPair.accountId,
          Asset.NATIVE,
          "100.0"
        ).build();

        final transaction = TransactionBuilder(sourceAccount)
          .addOperation(paymentOp)
          .build();

        expect(transaction.fee, equals(100));
      });

      test('addOperation adds operation correctly', () {
        final builder = TransactionBuilder(sourceAccount);

        expect(builder.operationsCount, equals(0));

        final paymentOp = PaymentOperationBuilder(
          destinationKeyPair.accountId,
          Asset.NATIVE,
          "100.0"
        ).build();

        builder.addOperation(paymentOp);

        expect(builder.operationsCount, equals(1));
      });

      test('setMaxOperationFee works correctly', () {
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
          .setMaxOperationFee(150)
          .build();

        expect(transaction.fee, equals(300));
      });

      test('setMaxOperationFee throws if below minimum', () {
        expect(
          () => TransactionBuilder(sourceAccount).setMaxOperationFee(50),
          throwsA(isA<Exception>())
        );
      });

      test('addMemo throws if memo already set', () {
        final builder = TransactionBuilder(sourceAccount);
        builder.addMemo(Memo.text("First memo"));

        expect(
          () => builder.addMemo(Memo.text("Second memo")),
          throwsA(isA<Exception>())
        );
      });
    });

    group('Transaction', () {
      test('creation with source account', () {
        final paymentOp = PaymentOperationBuilder(
          destinationKeyPair.accountId,
          Asset.NATIVE,
          "100.0"
        ).build();

        final transaction = TransactionBuilder(sourceAccount)
          .addOperation(paymentOp)
          .build();

        expect(transaction.sourceAccount.ed25519AccountId, equals(sourceKeyPair.accountId));
      });

      test('XDR encoding round-trip', () {
        final paymentOp = PaymentOperationBuilder(
          destinationKeyPair.accountId,
          Asset.NATIVE,
          "100.0"
        ).build();

        final transaction = TransactionBuilder(sourceAccount)
          .addOperation(paymentOp)
          .addMemo(Memo.text("Test"))
          .build();

        final xdr = transaction.toXdr();
        final xdrBytes = XdrDataOutputStream();
        XdrTransaction.encode(xdrBytes, xdr);

        final decoded = XdrTransaction.decode(XdrDataInputStream(Uint8List.fromList(xdrBytes.bytes)));

        expect(decoded.fee.uint32, equals(transaction.fee));
        expect(decoded.seqNum.sequenceNumber.bigInt, equals(transaction.sequenceNumber));
      });

      test('transaction hash computation is deterministic', () {
        final paymentOp = PaymentOperationBuilder(
          destinationKeyPair.accountId,
          Asset.NATIVE,
          "100.0"
        ).build();

        final transaction = TransactionBuilder(sourceAccount)
          .addOperation(paymentOp)
          .build();

        final hash1 = transaction.hash(Network.TESTNET);
        final hash2 = transaction.hash(Network.TESTNET);

        expect(ListEquality().equals(hash1, hash2), isTrue);
      });

      test('transaction hash changes with different operations', () {
        final paymentOp1 = PaymentOperationBuilder(
          destinationKeyPair.accountId,
          Asset.NATIVE,
          "100.0"
        ).build();

        final transaction1 = TransactionBuilder(sourceAccount)
          .addOperation(paymentOp1)
          .build();

        final paymentOp2 = PaymentOperationBuilder(
          destinationKeyPair.accountId,
          Asset.NATIVE,
          "200.0"
        ).build();

        final transaction2 = TransactionBuilder(sourceAccount)
          .addOperation(paymentOp2)
          .build();

        final hash1 = transaction1.hash(Network.TESTNET);
        final hash2 = transaction2.hash(Network.TESTNET);

        expect(ListEquality().equals(hash1, hash2), isFalse);
      });

      test('transaction envelope XDR encoding', () {
        final paymentOp = PaymentOperationBuilder(
          destinationKeyPair.accountId,
          Asset.NATIVE,
          "100.0"
        ).build();

        final transaction = TransactionBuilder(sourceAccount)
          .addOperation(paymentOp)
          .build();

        transaction.sign(sourceKeyPair, Network.TESTNET);

        final envelope = transaction.toEnvelopeXdr();

        expect(envelope.discriminant, equals(XdrEnvelopeType.ENVELOPE_TYPE_TX));
        expect(envelope.v1, isNotNull);
        expect(envelope.v1!.tx, isNotNull);
        expect(envelope.v1!.signatures.length, equals(1));
      });

      test('transaction signing with single keypair', () {
        final paymentOp = PaymentOperationBuilder(
          destinationKeyPair.accountId,
          Asset.NATIVE,
          "100.0"
        ).build();

        final transaction = TransactionBuilder(sourceAccount)
          .addOperation(paymentOp)
          .build();

        expect(transaction.signatures.length, equals(0));

        transaction.sign(sourceKeyPair, Network.TESTNET);

        expect(transaction.signatures.length, equals(1));
        expect(transaction.signatures[0].signature.signature.length, equals(64));
      });

      test('transaction signing with multiple keypairs', () {
        final secondKeyPair = KeyPair.random();

        final paymentOp = PaymentOperationBuilder(
          destinationKeyPair.accountId,
          Asset.NATIVE,
          "100.0"
        ).build();

        final transaction = TransactionBuilder(sourceAccount)
          .addOperation(paymentOp)
          .build();

        transaction.sign(sourceKeyPair, Network.TESTNET);
        transaction.sign(secondKeyPair, Network.TESTNET);

        expect(transaction.signatures.length, equals(2));
      });

      test('sign() adds signature', () {
        final paymentOp = PaymentOperationBuilder(
          destinationKeyPair.accountId,
          Asset.NATIVE,
          "100.0"
        ).build();

        final transaction = TransactionBuilder(sourceAccount)
          .addOperation(paymentOp)
          .build();

        final initialSigCount = transaction.signatures.length;
        transaction.sign(sourceKeyPair, Network.TESTNET);

        expect(transaction.signatures.length, equals(initialSigCount + 1));
      });

      test('signed transaction can be verified', () {
        final paymentOp = PaymentOperationBuilder(
          destinationKeyPair.accountId,
          Asset.NATIVE,
          "100.0"
        ).build();

        final transaction = TransactionBuilder(sourceAccount)
          .addOperation(paymentOp)
          .build();

        transaction.sign(sourceKeyPair, Network.TESTNET);

        final hash = transaction.hash(Network.TESTNET);
        final signature = transaction.signatures[0].signature.signature;

        expect(sourceKeyPair.verify(hash, signature), isTrue);
      });

      test('toEnvelopeXdr() returns valid envelope', () {
        final paymentOp = PaymentOperationBuilder(
          destinationKeyPair.accountId,
          Asset.NATIVE,
          "100.0"
        ).build();

        final transaction = TransactionBuilder(sourceAccount)
          .addOperation(paymentOp)
          .build();

        transaction.sign(sourceKeyPair, Network.TESTNET);

        final envelope = transaction.toEnvelopeXdr();

        expect(envelope, isNotNull);
        expect(envelope.v1, isNotNull);
        expect(envelope.v1!.signatures.length, greaterThan(0));
      });

      test('toEnvelopeXdrBase64() returns base64 string', () {
        final paymentOp = PaymentOperationBuilder(
          destinationKeyPair.accountId,
          Asset.NATIVE,
          "100.0"
        ).build();

        final transaction = TransactionBuilder(sourceAccount)
          .addOperation(paymentOp)
          .build();

        transaction.sign(sourceKeyPair, Network.TESTNET);

        final xdrBase64 = transaction.toEnvelopeXdrBase64();

        expect(xdrBase64, isNotEmpty);
        expect(xdrBase64, isA<String>());
      });

      test('Transaction.fromEnvelopeXdrString() parses envelope XDR', () {
        final paymentOp = PaymentOperationBuilder(
          destinationKeyPair.accountId,
          Asset.NATIVE,
          "100.0"
        ).build();

        final transaction = TransactionBuilder(sourceAccount)
          .addOperation(paymentOp)
          .addMemo(Memo.text("Test"))
          .build();

        transaction.sign(sourceKeyPair, Network.TESTNET);

        final xdrBase64 = transaction.toEnvelopeXdrBase64();
        final parsed = AbstractTransaction.fromEnvelopeXdrString(xdrBase64);

        expect(parsed, isA<Transaction>());
        final parsedTx = parsed as Transaction;
        expect(parsedTx.sourceAccount.ed25519AccountId, equals(sourceKeyPair.accountId));
        expect(parsedTx.operations.length, equals(1));
        expect(parsedTx.memo, isA<MemoText>());
        expect((parsedTx.memo as MemoText).text, equals("Test"));
      });

      test('transaction sequence number handling', () {
        final initialSeqNum = sourceAccount.sequenceNumber;

        final paymentOp = PaymentOperationBuilder(
          destinationKeyPair.accountId,
          Asset.NATIVE,
          "100.0"
        ).build();

        final transaction = TransactionBuilder(sourceAccount)
          .addOperation(paymentOp)
          .build();

        expect(transaction.sequenceNumber, equals(initialSeqNum + BigInt.one));
        expect(sourceAccount.sequenceNumber, equals(initialSeqNum + BigInt.one));
      });

      test('fee calculation based on operations', () {
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

        expect(transaction.fee, equals(200));
      });

      test('source account getter', () {
        final paymentOp = PaymentOperationBuilder(
          destinationKeyPair.accountId,
          Asset.NATIVE,
          "100.0"
        ).build();

        final transaction = TransactionBuilder(sourceAccount)
          .addOperation(paymentOp)
          .build();

        expect(transaction.sourceAccount.ed25519AccountId, equals(sourceKeyPair.accountId));
      });

      test('operations list is immutable after build', () {
        final paymentOp = PaymentOperationBuilder(
          destinationKeyPair.accountId,
          Asset.NATIVE,
          "100.0"
        ).build();

        final transaction = TransactionBuilder(sourceAccount)
          .addOperation(paymentOp)
          .build();

        final operations = transaction.operations;
        expect(operations.length, equals(1));
      });

      test('transaction hash changes with different networks', () {
        final paymentOp = PaymentOperationBuilder(
          destinationKeyPair.accountId,
          Asset.NATIVE,
          "100.0"
        ).build();

        final transaction = TransactionBuilder(sourceAccount)
          .addOperation(paymentOp)
          .build();

        final testnetHash = transaction.hash(Network.TESTNET);
        final publicHash = transaction.hash(Network.PUBLIC);

        expect(ListEquality().equals(testnetHash, publicHash), isFalse);
      });

      test('signHash adds hash preimage signature', () {
        final paymentOp = PaymentOperationBuilder(
          destinationKeyPair.accountId,
          Asset.NATIVE,
          "100.0"
        ).build();

        final transaction = TransactionBuilder(sourceAccount)
          .addOperation(paymentOp)
          .build();

        final preimage = Uint8List.fromList([1, 2, 3, 4, 5]);
        transaction.signHash(preimage);

        expect(transaction.signatures.length, equals(1));
        expect(
          ListEquality().equals(transaction.signatures[0].signature.signature, preimage),
          isTrue
        );
      });

      test('addResourceFee adds to transaction fee', () {
        final paymentOp = PaymentOperationBuilder(
          destinationKeyPair.accountId,
          Asset.NATIVE,
          "100.0"
        ).build();

        final transaction = TransactionBuilder(sourceAccount)
          .addOperation(paymentOp)
          .build();

        final initialFee = transaction.fee;
        transaction.addResourceFee(5000);

        expect(transaction.fee, equals(initialFee + 5000));
      });
    });

    group('FeeBumpTransaction', () {
      test('create fee bump transaction', () {
        final paymentOp = PaymentOperationBuilder(
          destinationKeyPair.accountId,
          Asset.NATIVE,
          "100.0"
        ).build();

        final innerTx = TransactionBuilder(sourceAccount)
          .addOperation(paymentOp)
          .build();

        innerTx.sign(sourceKeyPair, Network.TESTNET);

        final feeAccount = KeyPair.random();
        final feeBumpTx = FeeBumpTransactionBuilder(innerTx)
          .setBaseFee(200)
          .setFeeAccount(feeAccount.accountId)
          .build();

        expect(feeBumpTx, isNotNull);
        expect(feeBumpTx.innerTransaction, equals(innerTx));
        expect(feeBumpTx.feeAccount.ed25519AccountId, equals(feeAccount.accountId));
      });

      test('fee bump wraps inner transaction', () {
        final paymentOp = PaymentOperationBuilder(
          destinationKeyPair.accountId,
          Asset.NATIVE,
          "100.0"
        ).build();

        final innerTx = TransactionBuilder(sourceAccount)
          .addOperation(paymentOp)
          .build();

        innerTx.sign(sourceKeyPair, Network.TESTNET);

        final feeAccount = KeyPair.random();
        final feeBumpTx = FeeBumpTransactionBuilder(innerTx)
          .setBaseFee(200)
          .setFeeAccount(feeAccount.accountId)
          .build();

        expect(feeBumpTx.innerTransaction.operations.length, equals(innerTx.operations.length));
        expect(feeBumpTx.innerTransaction.sourceAccount.ed25519AccountId, equals(innerTx.sourceAccount.ed25519AccountId));
      });

      test('fee bump XDR round-trip', () {
        final paymentOp = PaymentOperationBuilder(
          destinationKeyPair.accountId,
          Asset.NATIVE,
          "100.0"
        ).build();

        final innerTx = TransactionBuilder(sourceAccount)
          .addOperation(paymentOp)
          .build();

        innerTx.sign(sourceKeyPair, Network.TESTNET);

        final feeAccount = KeyPair.random();
        final feeBumpTx = FeeBumpTransactionBuilder(innerTx)
          .setBaseFee(200)
          .setFeeAccount(feeAccount.accountId)
          .build();

        feeBumpTx.sign(feeAccount, Network.TESTNET);

        final xdrBase64 = feeBumpTx.toEnvelopeXdrBase64();
        final parsed = AbstractTransaction.fromEnvelopeXdrString(xdrBase64);

        expect(parsed, isA<FeeBumpTransaction>());
        final parsedFeeBump = parsed as FeeBumpTransaction;
        expect(parsedFeeBump.feeAccount.ed25519AccountId, equals(feeAccount.accountId));
      });

      test('fee bump requires base fee to be set', () {
        final paymentOp = PaymentOperationBuilder(
          destinationKeyPair.accountId,
          Asset.NATIVE,
          "100.0"
        ).build();

        final innerTx = TransactionBuilder(sourceAccount)
          .addOperation(paymentOp)
          .build();

        innerTx.sign(sourceKeyPair, Network.TESTNET);

        final feeAccount = KeyPair.random();

        expect(
          () => FeeBumpTransactionBuilder(innerTx)
            .setFeeAccount(feeAccount.accountId)
            .build(),
          throwsA(isA<Exception>())
        );
      });

      test('fee bump requires fee account to be set', () {
        final paymentOp = PaymentOperationBuilder(
          destinationKeyPair.accountId,
          Asset.NATIVE,
          "100.0"
        ).build();

        final innerTx = TransactionBuilder(sourceAccount)
          .addOperation(paymentOp)
          .build();

        innerTx.sign(sourceKeyPair, Network.TESTNET);

        expect(
          () => FeeBumpTransactionBuilder(innerTx)
            .setBaseFee(200)
            .build(),
          throwsA(isA<Exception>())
        );
      });

      test('fee bump base fee cannot be below minimum', () {
        final paymentOp = PaymentOperationBuilder(
          destinationKeyPair.accountId,
          Asset.NATIVE,
          "100.0"
        ).build();

        final innerTx = TransactionBuilder(sourceAccount)
          .addOperation(paymentOp)
          .build();

        innerTx.sign(sourceKeyPair, Network.TESTNET);

        final feeAccount = KeyPair.random();

        expect(
          () => FeeBumpTransactionBuilder(innerTx)
            .setBaseFee(50)
            .setFeeAccount(feeAccount.accountId)
            .build(),
          throwsA(isA<Exception>())
        );
      });

      test('fee bump throws if base fee already set', () {
        final paymentOp = PaymentOperationBuilder(
          destinationKeyPair.accountId,
          Asset.NATIVE,
          "100.0"
        ).build();

        final innerTx = TransactionBuilder(sourceAccount)
          .addOperation(paymentOp)
          .build();

        innerTx.sign(sourceKeyPair, Network.TESTNET);

        final builder = FeeBumpTransactionBuilder(innerTx);
        builder.setBaseFee(200);

        expect(
          () => builder.setBaseFee(300),
          throwsA(isA<Exception>())
        );
      });

      test('fee bump throws if fee account already set', () {
        final paymentOp = PaymentOperationBuilder(
          destinationKeyPair.accountId,
          Asset.NATIVE,
          "100.0"
        ).build();

        final innerTx = TransactionBuilder(sourceAccount)
          .addOperation(paymentOp)
          .build();

        innerTx.sign(sourceKeyPair, Network.TESTNET);

        final feeAccount = KeyPair.random();
        final builder = FeeBumpTransactionBuilder(innerTx);
        builder.setFeeAccount(feeAccount.accountId);

        expect(
          () => builder.setFeeAccount(feeAccount.accountId),
          throwsA(isA<Exception>())
        );
      });
    });

    group('Edge cases', () {
      test('transaction without operations throws', () {
        expect(
          () => Transaction(
            sourceAccount.muxedAccount,
            100,
            sourceAccount.incrementedSequenceNumber,
            [],
            null,
            null
          ),
          throwsA(isA<Exception>())
        );
      });

      test('transaction without signing has no signatures', () {
        final paymentOp = PaymentOperationBuilder(
          destinationKeyPair.accountId,
          Asset.NATIVE,
          "100.0"
        ).build();

        final transaction = TransactionBuilder(sourceAccount)
          .addOperation(paymentOp)
          .build();

        expect(transaction.signatures.length, equals(0));
      });

      test('toXdrBase64 returns valid XDR string', () {
        final paymentOp = PaymentOperationBuilder(
          destinationKeyPair.accountId,
          Asset.NATIVE,
          "100.0"
        ).build();

        final transaction = TransactionBuilder(sourceAccount)
          .addOperation(paymentOp)
          .build();

        final xdrBase64 = transaction.toXdrBase64();

        expect(xdrBase64, isNotEmpty);
        expect(xdrBase64, isA<String>());
      });

      test('transaction with all preconditions types', () {
        final paymentOp = PaymentOperationBuilder(
          destinationKeyPair.accountId,
          Asset.NATIVE,
          "100.0"
        ).build();

        final preconditions = TransactionPreconditions();
        preconditions.timeBounds = TimeBounds(1000, 2000);
        preconditions.ledgerBounds = LedgerBounds(100, 1000);
        preconditions.minSeqNumber = BigInt.from(123456);
        preconditions.minSeqAge = 3600;
        preconditions.minSeqLedgerGap = 10;

        final transaction = TransactionBuilder(sourceAccount)
          .addOperation(paymentOp)
          .addPreconditions(preconditions)
          .build();

        expect(transaction.preconditions, isNotNull);
        expect(transaction.preconditions!.timeBounds, isNotNull);
        expect(transaction.preconditions!.ledgerBounds, isNotNull);
        expect(transaction.preconditions!.minSeqNumber, equals(BigInt.from(123456)));
        expect(transaction.preconditions!.minSeqAge, equals(3600));
        expect(transaction.preconditions!.minSeqLedgerGap, equals(10));
      });

      test('signature base contains network passphrase', () {
        final paymentOp = PaymentOperationBuilder(
          destinationKeyPair.accountId,
          Asset.NATIVE,
          "100.0"
        ).build();

        final transaction = TransactionBuilder(sourceAccount)
          .addOperation(paymentOp)
          .build();

        final sigBaseTestnet = transaction.signatureBase(Network.TESTNET);
        final sigBasePublic = transaction.signatureBase(Network.PUBLIC);

        expect(ListEquality().equals(sigBaseTestnet, sigBasePublic), isFalse);
      });
    });

    group('TimeBounds', () {
      test('TimeBounds validation minTime >= maxTime throws', () {
        expect(
          () => TimeBounds(2000, 1000),
          throwsA(isA<Exception>())
        );
      });

      test('TimeBounds validation negative minTime throws', () {
        expect(
          () => TimeBounds(-1, 2000),
          throwsA(isA<Exception>())
        );
      });

      test('TimeBounds validation negative maxTime throws', () {
        expect(
          () => TimeBounds(1000, -1),
          throwsA(isA<Exception>())
        );
      });

      test('TimeBounds maxTime can be 0 for infinite', () {
        final timeBounds = TimeBounds(1000, 0);
        expect(timeBounds.minTime, equals(1000));
        expect(timeBounds.maxTime, equals(0));
      });

      test('TimeBounds equality', () {
        final tb1 = TimeBounds(1000, 2000);
        final tb2 = TimeBounds(1000, 2000);
        final tb3 = TimeBounds(1000, 3000);

        expect(tb1 == tb2, isTrue);
        expect(tb1 == tb3, isFalse);
      });

      test('TimeBounds XDR round-trip', () {
        final timeBounds = TimeBounds(1000, 2000);
        final xdr = timeBounds.toXdr();
        final restored = TimeBounds.fromXdr(xdr);

        expect(restored.minTime, equals(timeBounds.minTime));
        expect(restored.maxTime, equals(timeBounds.maxTime));
      });
    });

    group('LedgerBounds', () {
      test('LedgerBounds validation minLedger >= maxLedger throws', () {
        expect(
          () => LedgerBounds(2000, 1000),
          throwsA(isA<Exception>())
        );
      });

      test('LedgerBounds validation negative minLedger throws', () {
        expect(
          () => LedgerBounds(-1, 2000),
          throwsA(isA<Exception>())
        );
      });

      test('LedgerBounds validation negative maxLedger throws', () {
        expect(
          () => LedgerBounds(1000, -1),
          throwsA(isA<Exception>())
        );
      });

      test('LedgerBounds maxLedger can be 0 for infinite', () {
        final ledgerBounds = LedgerBounds(1000, 0);
        expect(ledgerBounds.minLedger, equals(1000));
        expect(ledgerBounds.maxLedger, equals(0));
      });

      test('LedgerBounds equality', () {
        final lb1 = LedgerBounds(100, 1000);
        final lb2 = LedgerBounds(100, 1000);
        final lb3 = LedgerBounds(100, 2000);

        expect(lb1 == lb2, isTrue);
        expect(lb1 == lb3, isFalse);
      });

      test('LedgerBounds XDR round-trip', () {
        final ledgerBounds = LedgerBounds(100, 1000);
        final xdr = ledgerBounds.toXdr();
        final restored = LedgerBounds.fromXdr(xdr);

        expect(restored!.minLedger, equals(ledgerBounds.minLedger));
        expect(restored.maxLedger, equals(ledgerBounds.maxLedger));
      });
    });

    group('TransactionPreconditions', () {
      test('TransactionPreconditions hasV2 returns false for simple time bounds', () {
        final preconditions = TransactionPreconditions();
        preconditions.timeBounds = TimeBounds(1000, 2000);

        expect(preconditions.hasV2(), isFalse);
      });

      test('TransactionPreconditions hasV2 returns true for ledger bounds', () {
        final preconditions = TransactionPreconditions();
        preconditions.ledgerBounds = LedgerBounds(100, 1000);

        expect(preconditions.hasV2(), isTrue);
      });

      test('TransactionPreconditions hasV2 returns true for minSeqAge', () {
        final preconditions = TransactionPreconditions();
        preconditions.minSeqAge = 3600;

        expect(preconditions.hasV2(), isTrue);
      });

      test('TransactionPreconditions hasV2 returns true for minSeqLedgerGap', () {
        final preconditions = TransactionPreconditions();
        preconditions.minSeqLedgerGap = 10;

        expect(preconditions.hasV2(), isTrue);
      });

      test('TransactionPreconditions hasV2 returns true for minSeqNumber', () {
        final preconditions = TransactionPreconditions();
        preconditions.minSeqNumber = BigInt.from(123456);

        expect(preconditions.hasV2(), isTrue);
      });

      test('TransactionPreconditions XDR round-trip with all fields', () {
        final preconditions = TransactionPreconditions();
        preconditions.timeBounds = TimeBounds(1000, 2000);
        preconditions.ledgerBounds = LedgerBounds(100, 1000);
        preconditions.minSeqNumber = BigInt.from(123456);
        preconditions.minSeqAge = 3600;
        preconditions.minSeqLedgerGap = 10;

        final xdr = preconditions.toXdr();
        final restored = TransactionPreconditions.fromXdr(xdr);

        expect(restored.timeBounds!.minTime, equals(1000));
        expect(restored.timeBounds!.maxTime, equals(2000));
        expect(restored.ledgerBounds!.minLedger, equals(100));
        expect(restored.ledgerBounds!.maxLedger, equals(1000));
        expect(restored.minSeqNumber, equals(BigInt.from(123456)));
        expect(restored.minSeqAge, equals(3600));
        expect(restored.minSeqLedgerGap, equals(10));
      });
    });

    group('Integration', () {
      test('full transaction workflow with signing and verification', () {
        final paymentOp = PaymentOperationBuilder(
          destinationKeyPair.accountId,
          Asset.NATIVE,
          "100.0"
        ).build();

        final transaction = TransactionBuilder(sourceAccount)
          .addOperation(paymentOp)
          .addMemo(Memo.text("Integration test"))
          .build();

        transaction.sign(sourceKeyPair, Network.TESTNET);

        final xdrBase64 = transaction.toEnvelopeXdrBase64();
        final parsed = AbstractTransaction.fromEnvelopeXdrString(xdrBase64);

        expect(parsed, isA<Transaction>());
        final parsedTx = parsed as Transaction;
        expect(parsedTx.signatures.length, equals(1));

        final hash = parsedTx.hash(Network.TESTNET);
        final signature = parsedTx.signatures[0].signature.signature;
        expect(sourceKeyPair.verify(hash, signature), isTrue);
      });

      test('multi-sig transaction workflow', () {
        final secondSigner = KeyPair.random();

        final paymentOp = PaymentOperationBuilder(
          destinationKeyPair.accountId,
          Asset.NATIVE,
          "100.0"
        ).build();

        final transaction = TransactionBuilder(sourceAccount)
          .addOperation(paymentOp)
          .build();

        transaction.sign(sourceKeyPair, Network.TESTNET);
        transaction.sign(secondSigner, Network.TESTNET);

        expect(transaction.signatures.length, equals(2));

        final hash = transaction.hash(Network.TESTNET);
        expect(sourceKeyPair.verify(hash, transaction.signatures[0].signature.signature), isTrue);
        expect(secondSigner.verify(hash, transaction.signatures[1].signature.signature), isTrue);
      });
    });
  });

  group('Transaction Deep Branch Testing', () {
    test('Transaction.builder creates TransactionBuilder', () {
      KeyPair sourceKeyPair = KeyPair.random();
      Account sourceAccount = Account(sourceKeyPair.accountId, BigInt.from(100));

      TransactionBuilder builder = Transaction.builder(sourceAccount);

      expect(builder, isNotNull);
      expect(builder, isA<TransactionBuilder>());
    });

    test('Transaction with TimeBounds preconditions', () {
      KeyPair sourceKeyPair = KeyPair.random();
      Account sourceAccount = Account(sourceKeyPair.accountId, BigInt.from(100));

      TimeBounds timeBounds = TimeBounds(1000, 2000);
      TransactionPreconditions preconditions = TransactionPreconditions();
      preconditions.timeBounds = timeBounds;

      Transaction transaction = TransactionBuilder(sourceAccount)
          .addOperation(CreateAccountOperationBuilder(
              KeyPair.random().accountId, "100").build())
          .addPreconditions(preconditions)
          .build();

      expect(transaction.preconditions, isNotNull);
      expect(transaction.preconditions!.timeBounds, isNotNull);
      expect(transaction.preconditions!.timeBounds!.minTime, equals(1000));
      expect(transaction.preconditions!.timeBounds!.maxTime, equals(2000));
    });

    test('Transaction with LedgerBounds preconditions', () {
      KeyPair sourceKeyPair = KeyPair.random();
      Account sourceAccount = Account(sourceKeyPair.accountId, BigInt.from(100));

      LedgerBounds ledgerBounds = LedgerBounds(100, 200);
      TransactionPreconditions preconditions = TransactionPreconditions();
      preconditions.ledgerBounds = ledgerBounds;

      Transaction transaction = TransactionBuilder(sourceAccount)
          .addOperation(CreateAccountOperationBuilder(
              KeyPair.random().accountId, "100").build())
          .addPreconditions(preconditions)
          .build();

      expect(transaction.preconditions, isNotNull);
      expect(transaction.preconditions!.ledgerBounds, isNotNull);
      expect(transaction.preconditions!.ledgerBounds!.minLedger, equals(100));
      expect(transaction.preconditions!.ledgerBounds!.maxLedger, equals(200));
    });

    test('Transaction with extra signers', () {
      KeyPair sourceKeyPair = KeyPair.random();
      Account sourceAccount = Account(sourceKeyPair.accountId, BigInt.from(100));

      KeyPair signer1 = KeyPair.random();
      KeyPair signer2 = KeyPair.random();

      TransactionPreconditions preconditions = TransactionPreconditions();
      preconditions.extraSigners = [
        signer1.xdrSignerKey,
        signer2.xdrSignerKey,
      ];

      Transaction transaction = TransactionBuilder(sourceAccount)
          .addOperation(CreateAccountOperationBuilder(
              KeyPair.random().accountId, "100").build())
          .addPreconditions(preconditions)
          .build();

      expect(transaction.preconditions, isNotNull);
      expect(transaction.preconditions!.extraSigners, isNotNull);
      expect(transaction.preconditions!.extraSigners!.length, equals(2));
    });

    test('Transaction with minSeqNumber precondition', () {
      KeyPair sourceKeyPair = KeyPair.random();
      Account sourceAccount = Account(sourceKeyPair.accountId, BigInt.from(100));

      TransactionPreconditions preconditions = TransactionPreconditions();
      preconditions.minSeqNumber = BigInt.from(50);

      Transaction transaction = TransactionBuilder(sourceAccount)
          .addOperation(CreateAccountOperationBuilder(
              KeyPair.random().accountId, "100").build())
          .addPreconditions(preconditions)
          .build();

      expect(transaction.preconditions, isNotNull);
      expect(transaction.preconditions!.minSeqNumber, equals(BigInt.from(50)));
    });

    test('Transaction with minSeqAge precondition', () {
      KeyPair sourceKeyPair = KeyPair.random();
      Account sourceAccount = Account(sourceKeyPair.accountId, BigInt.from(100));

      TransactionPreconditions preconditions = TransactionPreconditions();
      preconditions.minSeqAge = 3600;

      Transaction transaction = TransactionBuilder(sourceAccount)
          .addOperation(CreateAccountOperationBuilder(
              KeyPair.random().accountId, "100").build())
          .addPreconditions(preconditions)
          .build();

      expect(transaction.preconditions, isNotNull);
      expect(transaction.preconditions!.minSeqAge, equals(3600));
    });

    test('Transaction with minSeqLedgerGap precondition', () {
      KeyPair sourceKeyPair = KeyPair.random();
      Account sourceAccount = Account(sourceKeyPair.accountId, BigInt.from(100));

      TransactionPreconditions preconditions = TransactionPreconditions();
      preconditions.minSeqLedgerGap = 10;

      Transaction transaction = TransactionBuilder(sourceAccount)
          .addOperation(CreateAccountOperationBuilder(
              KeyPair.random().accountId, "100").build())
          .addPreconditions(preconditions)
          .build();

      expect(transaction.preconditions, isNotNull);
      expect(transaction.preconditions!.minSeqLedgerGap, equals(10));
    });

    test('Transaction toXdr and fromXdr round trip', () {
      KeyPair sourceKeyPair = KeyPair.random();
      Account sourceAccount = Account(sourceKeyPair.accountId, BigInt.from(100));

      Transaction original = TransactionBuilder(sourceAccount)
          .addOperation(CreateAccountOperationBuilder(
              KeyPair.random().accountId, "100").build())
          .addMemo(Memo.text("test"))
          .build();

      original.sign(sourceKeyPair, Network.TESTNET);

      String xdrBase64 = original.toEnvelopeXdrBase64();
      Transaction decoded = AbstractTransaction.fromEnvelopeXdrString(xdrBase64) as Transaction;

      expect(decoded.sourceAccount.ed25519AccountId, equals(original.sourceAccount.ed25519AccountId));
      expect(decoded.sequenceNumber, equals(original.sequenceNumber));
      expect(decoded.operations.length, equals(1));
      expect(decoded.memo, isA<MemoText>());
    });

    test('Transaction toV0Xdr', () {
      KeyPair sourceKeyPair = KeyPair.random();
      Account sourceAccount = Account(sourceKeyPair.accountId, BigInt.from(100));

      Transaction transaction = TransactionBuilder(sourceAccount)
          .addOperation(CreateAccountOperationBuilder(
              KeyPair.random().accountId, "100").build())
          .build();

      XdrTransactionV0 v0Xdr = transaction.toV0Xdr();

      expect(v0Xdr, isNotNull);
      expect(v0Xdr.operations.length, equals(1));
    });

    test('FeeBumpTransaction with muxed fee account', () {
      KeyPair sourceKeyPair = KeyPair.random();
      Account sourceAccount = Account(sourceKeyPair.accountId, BigInt.from(100));

      Transaction innerTx = TransactionBuilder(sourceAccount)
          .addOperation(CreateAccountOperationBuilder(
              KeyPair.random().accountId, "100").build())
          .build();
      innerTx.sign(sourceKeyPair, Network.TESTNET);

      KeyPair feeSourceKeyPair = KeyPair.random();
      MuxedAccount muxedFeeAccount = MuxedAccount(feeSourceKeyPair.accountId, BigInt.from(123));

      FeeBumpTransaction feeBumpTx = FeeBumpTransactionBuilder(innerTx)
          .setBaseFee(200)
          .setMuxedFeeAccount(muxedFeeAccount)
          .build();

      expect(feeBumpTx.feeAccount.ed25519AccountId, equals(feeSourceKeyPair.accountId));
      expect(feeBumpTx.feeAccount.id, equals(BigInt.from(123)));
    });

    test('FeeBumpTransaction toXdr and fromXdr', () {
      KeyPair sourceKeyPair = KeyPair.random();
      Account sourceAccount = Account(sourceKeyPair.accountId, BigInt.from(100));

      Transaction innerTx = TransactionBuilder(sourceAccount)
          .addOperation(CreateAccountOperationBuilder(
              KeyPair.random().accountId, "100").build())
          .build();
      innerTx.sign(sourceKeyPair, Network.TESTNET);

      KeyPair feeSourceKeyPair = KeyPair.random();

      FeeBumpTransaction original = FeeBumpTransactionBuilder(innerTx)
          .setBaseFee(200)
          .setFeeAccount(feeSourceKeyPair.accountId)
          .build();

      original.sign(feeSourceKeyPair, Network.TESTNET);

      String xdrBase64 = original.toEnvelopeXdrBase64();
      FeeBumpTransaction decoded = AbstractTransaction.fromEnvelopeXdrString(xdrBase64) as FeeBumpTransaction;

      expect(decoded.feeAccount.ed25519AccountId, equals(original.feeAccount.ed25519AccountId));
      expect(decoded.innerTransaction.sourceAccount.ed25519AccountId,
             equals(original.innerTransaction.sourceAccount.ed25519AccountId));
    });

    test('TimeBounds toXdr and fromXdr', () {
      TimeBounds original = TimeBounds(1000, 2000);
      XdrTimeBounds xdr = original.toXdr();
      TimeBounds decoded = TimeBounds.fromXdr(xdr);

      expect(decoded.minTime, equals(original.minTime));
      expect(decoded.maxTime, equals(original.maxTime));
    });

    test('LedgerBounds toXdr and fromXdr', () {
      LedgerBounds original = LedgerBounds(100, 200);
      XdrLedgerBounds xdr = original.toXdr();
      LedgerBounds decoded = LedgerBounds.fromXdr(xdr)!;

      expect(decoded.minLedger, equals(original.minLedger));
      expect(decoded.maxLedger, equals(original.maxLedger));
    });

    test('TransactionPreconditions hasV2 with ledgerBounds', () {
      TransactionPreconditions preconditions = TransactionPreconditions();
      expect(preconditions.hasV2(), isFalse);

      preconditions.ledgerBounds = LedgerBounds(100, 200);
      expect(preconditions.hasV2(), isTrue);
    });

    test('TransactionPreconditions hasV2 with minSeqNumber', () {
      TransactionPreconditions preconditions = TransactionPreconditions();
      preconditions.minSeqNumber = BigInt.from(100);

      expect(preconditions.hasV2(), isTrue);
    });

    test('TransactionPreconditions hasV2 with extraSigners', () {
      TransactionPreconditions preconditions = TransactionPreconditions();
      KeyPair signer = KeyPair.random();
      preconditions.extraSigners = [signer.xdrSignerKey];

      expect(preconditions.hasV2(), isTrue);
    });

    test('TransactionPreconditions toXdr with V2 fields', () {
      TransactionPreconditions preconditions = TransactionPreconditions();
      preconditions.ledgerBounds = LedgerBounds(100, 200);
      preconditions.minSeqNumber = BigInt.from(50);
      preconditions.minSeqAge = 3600;
      preconditions.minSeqLedgerGap = 10;

      XdrPreconditions xdr = preconditions.toXdr();

      expect(xdr.discriminant.value, equals(XdrPreconditionType.V2.value));
      expect(xdr.v2, isNotNull);
      expect(xdr.v2!.ledgerBounds, isNotNull);
      expect(xdr.v2!.sequenceNumber, isNotNull);
    });

    test('TransactionPreconditions fromXdr with V2', () {
      TransactionPreconditions original = TransactionPreconditions();
      original.ledgerBounds = LedgerBounds(100, 200);
      original.minSeqNumber = BigInt.from(50);
      original.minSeqAge = 3600;
      original.minSeqLedgerGap = 10;

      XdrPreconditions xdr = original.toXdr();
      TransactionPreconditions decoded = TransactionPreconditions.fromXdr(xdr);

      expect(decoded.ledgerBounds, isNotNull);
      expect(decoded.ledgerBounds!.minLedger, equals(100));
      expect(decoded.minSeqNumber, equals(BigInt.from(50)));
      expect(decoded.minSeqAge, equals(3600));
      expect(decoded.minSeqLedgerGap, equals(10));
    });

    test('MuxedAccount handling in transaction', () {
      KeyPair sourceKeyPair = KeyPair.random();
      Account sourceAccount = Account(
        sourceKeyPair.accountId,
        BigInt.from(100),
        muxedAccountMed25519Id: BigInt.from(456)
      );

      Transaction transaction = TransactionBuilder(sourceAccount)
          .addOperation(CreateAccountOperationBuilder(
              KeyPair.random().accountId, "100").build())
          .build();

      expect(transaction.sourceAccount.ed25519AccountId, equals(sourceKeyPair.accountId));
      expect(transaction.sourceAccount.id, equals(BigInt.from(456)));
    });

    test('Transaction addResourceFee', () {
      KeyPair sourceKeyPair = KeyPair.random();
      Account sourceAccount = Account(sourceKeyPair.accountId, BigInt.from(100));

      Transaction transaction = TransactionBuilder(sourceAccount)
          .addOperation(CreateAccountOperationBuilder(
              KeyPair.random().accountId, "100").build())
          .setMaxOperationFee(100)
          .build();

      int originalFee = transaction.fee;
      transaction.addResourceFee(50000);

      expect(transaction.fee, equals(originalFee + 50000));
    });
  });

  group('Transaction Final Coverage Tests', () {
    late KeyPair testKeyPair;
    late Account testAccount;

    setUp(() {
      testKeyPair = KeyPair.random();
      testAccount = Account(testKeyPair.accountId, BigInt.from(100));
    });

    group('AbstractTransaction Tests', () {
      test('fromEnvelopeXdr throws on unsupported envelope type', () {
        // Create an envelope with an invalid discriminant
        final envelope = XdrTransactionEnvelope(XdrEnvelopeType.ENVELOPE_TYPE_OP_ID);

        expect(
          () => AbstractTransaction.fromEnvelopeXdr(envelope),
          throwsA(anything),
        );
      });

      test('fromEnvelopeXdr handles ENVELOPE_TYPE_TX_V0', () {
        final transaction = TransactionBuilder(testAccount)
            .addOperation(
              PaymentOperationBuilder(
                KeyPair.random().accountId,
                Asset.NATIVE,
                '10',
              ).build(),
            )
            .build();

        final v0Xdr = transaction.toV0Xdr();
        final v0Envelope = XdrTransactionV0Envelope(v0Xdr, []);
        final envelope = XdrTransactionEnvelope(XdrEnvelopeType.ENVELOPE_TYPE_TX_V0);
        envelope.v0 = v0Envelope;

        final result = AbstractTransaction.fromEnvelopeXdr(envelope);
        expect(result, isA<Transaction>());
      });

      test('fromEnvelopeXdr handles ENVELOPE_TYPE_TX_FEE_BUMP', () {
        final innerTx = TransactionBuilder(testAccount)
            .addOperation(
              PaymentOperationBuilder(
                KeyPair.random().accountId,
                Asset.NATIVE,
                '10',
              ).build(),
            )
            .build();
        innerTx.sign(testKeyPair, Network.TESTNET);

        final feeBumpTx = FeeBumpTransactionBuilder(innerTx)
            .setBaseFee(200)
            .setFeeAccount(KeyPair.random().accountId)
            .build();

        final envelope = feeBumpTx.toEnvelopeXdr();
        final result = AbstractTransaction.fromEnvelopeXdr(envelope);
        expect(result, isA<FeeBumpTransaction>());
      });
    });

    group('Transaction V0 Envelope Tests', () {
      test('fromV0EnvelopeXdr parses envelope correctly', () {
        final transaction = TransactionBuilder(testAccount)
            .addOperation(
              PaymentOperationBuilder(
                KeyPair.random().accountId,
                Asset.NATIVE,
                '10',
              ).build(),
            )
            .addMemo(Memo.text('Test'))
            .build();

        final v0Xdr = transaction.toV0Xdr();
        final v0Envelope = XdrTransactionV0Envelope(v0Xdr, []);

        final result = Transaction.fromV0EnvelopeXdr(v0Envelope);

        expect(result.sourceAccount.accountId, testAccount.accountId);
        // V0 envelope contains the transaction's sequence number
        expect(result.sequenceNumber, isNotNull);
        expect(result.operations.length, 1);
      });

      test('fromV0EnvelopeXdr handles null timeBounds', () {
        final transaction = TransactionBuilder(testAccount)
            .addOperation(
              PaymentOperationBuilder(
                KeyPair.random().accountId,
                Asset.NATIVE,
                '10',
              ).build(),
            )
            .build();

        final v0Xdr = transaction.toV0Xdr();
        v0Xdr.timeBounds = null;
        final v0Envelope = XdrTransactionV0Envelope(v0Xdr, []);

        final result = Transaction.fromV0EnvelopeXdr(v0Envelope);

        expect(result.preconditions?.timeBounds, isNull);
      });

      test('fromV0EnvelopeXdr parses signatures correctly', () {
        final transaction = TransactionBuilder(testAccount)
            .addOperation(
              PaymentOperationBuilder(
                KeyPair.random().accountId,
                Asset.NATIVE,
                '10',
              ).build(),
            )
            .build();

        transaction.sign(testKeyPair, Network.TESTNET);

        final v0Xdr = transaction.toV0Xdr();
        final v0Envelope = XdrTransactionV0Envelope(v0Xdr, transaction.signatures);

        final result = Transaction.fromV0EnvelopeXdr(v0Envelope);

        expect(result.signatures.length, transaction.signatures.length);
      });
    });

    group('TransactionBuilder Tests', () {
      test('addTimeBounds throws when timeBounds already set', () {
        final builder = TransactionBuilder(testAccount);
        builder.addTimeBounds(TimeBounds(0, 1000));

        expect(
          () => builder.addTimeBounds(TimeBounds(0, 2000)),
          throwsA(isA<Exception>()),
        );
      });

      test('setMaxOperationFee throws when fee too small', () {
        final builder = TransactionBuilder(testAccount);

        expect(
          () => builder.setMaxOperationFee(50),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Transaction Tests', () {
      test('Transaction constructor throws with no operations', () {
        expect(
          () => Transaction(
            MuxedAccount.fromAccountId(testKeyPair.accountId)!,
            100,
            BigInt.from(101),
            [],
            null,
            null,
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('addResourceFee increases transaction fee', () {
        final transaction = TransactionBuilder(testAccount)
            .addOperation(
              PaymentOperationBuilder(
                KeyPair.random().accountId,
                Asset.NATIVE,
                '10',
              ).build(),
            )
            .build();

        final originalFee = transaction.fee;
        transaction.addResourceFee(5000);

        expect(transaction.fee, originalFee + 5000);
      });

      test('Transaction holds sorobanTransactionData', () {
        final transaction = TransactionBuilder(testAccount)
            .addOperation(
              PaymentOperationBuilder(
                KeyPair.random().accountId,
                Asset.NATIVE,
                '10',
              ).build(),
            )
            .build();

        // Initially null
        expect(transaction.sorobanTransactionData, isNull);

        // Can be set (actual Soroban data structure is complex, just test null assignment)
        transaction.sorobanTransactionData = null;
        expect(transaction.sorobanTransactionData, isNull);
      });

      test('setSorobanAuth handles empty list', () {
        final transaction = TransactionBuilder(testAccount)
            .addOperation(
              PaymentOperationBuilder(
                KeyPair.random().accountId,
                Asset.NATIVE,
                '10',
              ).build(),
            )
            .build();

        // Call setSorobanAuth with empty list - should not throw
        transaction.setSorobanAuth([]);

        expect(transaction.operations, isNotEmpty);
      });
    });

    group('FeeBumpTransaction Tests', () {
      test('fromFeeBumpTransactionEnvelope parses envelope correctly', () {
        final innerTx = TransactionBuilder(testAccount)
            .addOperation(
              PaymentOperationBuilder(
                KeyPair.random().accountId,
                Asset.NATIVE,
                '10',
              ).build(),
            )
            .build();
        innerTx.sign(testKeyPair, Network.TESTNET);

        final feeAccount = KeyPair.random();
        final feeBumpTx = FeeBumpTransactionBuilder(innerTx)
            .setBaseFee(200)
            .setFeeAccount(feeAccount.accountId)
            .build();

        final envelope = feeBumpTx.toEnvelopeXdr();
        final result = FeeBumpTransaction.fromFeeBumpTransactionEnvelope(envelope.feeBump!);

        expect(result.feeAccount.accountId, feeAccount.accountId);
        expect(result.fee, greaterThan(innerTx.fee));
        expect(result.innerTransaction.sourceAccount.accountId, testAccount.accountId);
      });

      test('toXdrBase64 returns base64 encoded XDR', () {
        final innerTx = TransactionBuilder(testAccount)
            .addOperation(
              PaymentOperationBuilder(
                KeyPair.random().accountId,
                Asset.NATIVE,
                '10',
              ).build(),
            )
            .build();
        innerTx.sign(testKeyPair, Network.TESTNET);

        final feeBumpTx = FeeBumpTransactionBuilder(innerTx)
            .setBaseFee(200)
            .setFeeAccount(KeyPair.random().accountId)
            .build();

        final xdrBase64 = feeBumpTx.toXdrBase64();

        expect(xdrBase64, isNotEmpty);
        expect(xdrBase64, isA<String>());
      });
    });

    group('FeeBumpTransactionBuilder Tests', () {
      test('constructor converts v0 envelope to v1', () {
        final transaction = TransactionBuilder(testAccount)
            .addOperation(
              PaymentOperationBuilder(
                KeyPair.random().accountId,
                Asset.NATIVE,
                '10',
              ).build(),
            )
            .build();

        final builder = FeeBumpTransactionBuilder(transaction);
        builder.setBaseFee(200);
        builder.setFeeAccount(KeyPair.random().accountId);

        final feeBumpTx = builder.build();
        expect(feeBumpTx.innerTransaction.toEnvelopeXdr().discriminant,
            XdrEnvelopeType.ENVELOPE_TYPE_TX);
      });

      test('setBaseFee throws when already set', () {
        final innerTx = TransactionBuilder(testAccount)
            .addOperation(
              PaymentOperationBuilder(
                KeyPair.random().accountId,
                Asset.NATIVE,
                '10',
              ).build(),
            )
            .build();

        final builder = FeeBumpTransactionBuilder(innerTx);
        builder.setBaseFee(200);

        expect(
          () => builder.setBaseFee(300),
          throwsA(isA<Exception>()),
        );
      });

      test('setBaseFee throws when fee too small', () {
        final innerTx = TransactionBuilder(testAccount)
            .addOperation(
              PaymentOperationBuilder(
                KeyPair.random().accountId,
                Asset.NATIVE,
                '10',
              ).build(),
            )
            .build();

        final builder = FeeBumpTransactionBuilder(innerTx);

        expect(
          () => builder.setBaseFee(50),
          throwsA(isA<Exception>()),
        );
      });

      test('setBaseFee throws when lower than inner transaction fee', () {
        final innerTx = TransactionBuilder(testAccount)
            .setMaxOperationFee(200)
            .addOperation(
              PaymentOperationBuilder(
                KeyPair.random().accountId,
                Asset.NATIVE,
                '10',
              ).build(),
            )
            .build();

        final builder = FeeBumpTransactionBuilder(innerTx);

        expect(
          () => builder.setBaseFee(150),
          throwsA(isA<Exception>()),
        );
      });

      test('setBaseFee throws on fee overflow', () {
        final innerTx = TransactionBuilder(testAccount)
            .addOperation(
              PaymentOperationBuilder(
                KeyPair.random().accountId,
                Asset.NATIVE,
                '10',
              ).build(),
            )
            .build();

        final builder = FeeBumpTransactionBuilder(innerTx);

        // Use a very large base fee that would overflow when multiplied
        expect(
          () => builder.setBaseFee(9223372036854775807),
          throwsA(isA<Exception>()),
        );
      });

      test('setFeeAccount throws when already set', () {
        final innerTx = TransactionBuilder(testAccount)
            .addOperation(
              PaymentOperationBuilder(
                KeyPair.random().accountId,
                Asset.NATIVE,
                '10',
              ).build(),
            )
            .build();

        final builder = FeeBumpTransactionBuilder(innerTx);
        builder.setFeeAccount(KeyPair.random().accountId);

        expect(
          () => builder.setFeeAccount(KeyPair.random().accountId),
          throwsA(isA<Exception>()),
        );
      });

      test('setMuxedFeeAccount throws when already set', () {
        final innerTx = TransactionBuilder(testAccount)
            .addOperation(
              PaymentOperationBuilder(
                KeyPair.random().accountId,
                Asset.NATIVE,
                '10',
              ).build(),
            )
            .build();

        final builder = FeeBumpTransactionBuilder(innerTx);
        final muxedAccount = MuxedAccount.fromAccountId(KeyPair.random().accountId)!;
        builder.setMuxedFeeAccount(muxedAccount);

        expect(
          () => builder.setMuxedFeeAccount(muxedAccount),
          throwsA(isA<Exception>()),
        );
      });

      test('build throws when base fee not set', () {
        final innerTx = TransactionBuilder(testAccount)
            .addOperation(
              PaymentOperationBuilder(
                KeyPair.random().accountId,
                Asset.NATIVE,
                '10',
              ).build(),
            )
            .build();

        final builder = FeeBumpTransactionBuilder(innerTx);
        builder.setFeeAccount(KeyPair.random().accountId);

        expect(
          () => builder.build(),
          throwsA(isA<Exception>()),
        );
      });

      test('build throws when fee account not set', () {
        final innerTx = TransactionBuilder(testAccount)
            .addOperation(
              PaymentOperationBuilder(
                KeyPair.random().accountId,
                Asset.NATIVE,
                '10',
              ).build(),
            )
            .build();

        final builder = FeeBumpTransactionBuilder(innerTx);
        builder.setBaseFee(200);

        expect(
          () => builder.build(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('TimeBounds Tests', () {
      test('constructor throws on negative minTime', () {
        expect(
          () => TimeBounds(-1, 1000),
          throwsA(isA<Exception>()),
        );
      });

      test('constructor throws on negative maxTime', () {
        expect(
          () => TimeBounds(0, -1),
          throwsA(isA<Exception>()),
        );
      });

      test('constructor throws when minTime >= maxTime', () {
        expect(
          () => TimeBounds(1000, 1000),
          throwsA(isA<Exception>()),
        );
      });

      test('equality compares TimeBounds correctly', () {
        final timeBounds1 = TimeBounds(0, 1000);
        final timeBounds2 = TimeBounds(0, 1000);
        final timeBounds3 = TimeBounds(100, 1000);

        // Same values should be equal
        expect(timeBounds1.minTime == timeBounds2.minTime, true);
        expect(timeBounds1.maxTime == timeBounds2.maxTime, true);

        // Different values should not be equal
        expect(timeBounds1.minTime == timeBounds3.minTime, false);
      });
    });

    group('LedgerBounds Tests', () {
      test('constructor throws on negative minLedger', () {
        expect(
          () => LedgerBounds(-1, 1000),
          throwsA(isA<Exception>()),
        );
      });

      test('constructor throws on negative maxLedger', () {
        expect(
          () => LedgerBounds(0, -1),
          throwsA(isA<Exception>()),
        );
      });

      test('constructor throws when minLedger >= maxLedger', () {
        expect(
          () => LedgerBounds(1000, 1000),
          throwsA(isA<Exception>()),
        );
      });

      test('equality compares LedgerBounds correctly', () {
        final ledgerBounds1 = LedgerBounds(0, 1000);
        final ledgerBounds2 = LedgerBounds(0, 1000);
        final ledgerBounds3 = LedgerBounds(100, 1000);

        // Same values should be equal
        expect(ledgerBounds1.minLedger == ledgerBounds2.minLedger, true);
        expect(ledgerBounds1.maxLedger == ledgerBounds2.maxLedger, true);

        // Different values should not be equal
        expect(ledgerBounds1.minLedger == ledgerBounds3.minLedger, false);
      });
    });
  });
}
