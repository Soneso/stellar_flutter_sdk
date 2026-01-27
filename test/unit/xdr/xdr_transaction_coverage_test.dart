import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:typed_data';

void main() {
  group('XdrFeeBumpTransactionInnerTx setters', () {
    test('should set discriminant', () {
      final innerTx = XdrFeeBumpTransactionInnerTx(XdrEnvelopeType.ENVELOPE_TYPE_TX);
      innerTx.discriminant = XdrEnvelopeType.ENVELOPE_TYPE_TX;
      expect(innerTx.discriminant, equals(XdrEnvelopeType.ENVELOPE_TYPE_TX));
    });
  });

  group('XdrFeeBumpTransactionExt setters', () {
    test('should set discriminant', () {
      final ext = XdrFeeBumpTransactionExt(0);
      ext.discriminant = 0;
      expect(ext.discriminant, equals(0));
    });
  });

  group('XdrTransactionV0Ext setters', () {
    test('should set discriminant', () {
      final ext = XdrTransactionV0Ext(0);
      ext.discriminant = 0;
      expect(ext.discriminant, equals(0));
    });
  });

  group('XdrTransactionEnvelope setters', () {
    test('should set discriminant', () {
      final envelope = XdrTransactionEnvelope(XdrEnvelopeType.ENVELOPE_TYPE_TX);
      envelope.discriminant = XdrEnvelopeType.ENVELOPE_TYPE_TX_V0;
      expect(envelope.discriminant, equals(XdrEnvelopeType.ENVELOPE_TYPE_TX_V0));
    });
  });

  group('XdrTransactionV1Envelope setters', () {
    test('should set tx and signatures', () {
      final sourceAccount = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      sourceAccount.ed25519 = XdrUint256(Uint8List(32));
      final preconditions = XdrPreconditions(XdrPreconditionType.NONE);
      final tx = XdrTransaction(
        sourceAccount,
        XdrUint32(100),
        XdrSequenceNumber(XdrBigInt64(BigInt.from(1))),
        preconditions,
        XdrMemo(XdrMemoType.MEMO_NONE),
        [],
        XdrTransactionExt(0),
      );
      final envelope = XdrTransactionV1Envelope(tx, []);

      final newTx = XdrTransaction(
        sourceAccount,
        XdrUint32(200),
        XdrSequenceNumber(XdrBigInt64(BigInt.from(2))),
        preconditions,
        XdrMemo(XdrMemoType.MEMO_NONE),
        [],
        XdrTransactionExt(0),
      );
      envelope.tx = newTx;
      expect(envelope.tx, equals(newTx));

      final sig = XdrDecoratedSignature(XdrSignatureHint(Uint8List(4)), XdrSignature(Uint8List(64)));
      envelope.signatures = [sig];
      expect(envelope.signatures.length, equals(1));
    });
  });

  group('XdrFeeBumpTransactionEnvelope setters', () {
    test('should set tx and signatures', () {
      final feeSource = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      feeSource.ed25519 = XdrUint256(Uint8List(32));

      final innerTx = XdrFeeBumpTransactionInnerTx(XdrEnvelopeType.ENVELOPE_TYPE_TX);
      final sourceAccount = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      sourceAccount.ed25519 = XdrUint256(Uint8List(32));
      final preconditions = XdrPreconditions(XdrPreconditionType.NONE);
      final tx = XdrTransaction(
        sourceAccount,
        XdrUint32(100),
        XdrSequenceNumber(XdrBigInt64(BigInt.from(1))),
        preconditions,
        XdrMemo(XdrMemoType.MEMO_NONE),
        [],
        XdrTransactionExt(0),
      );
      innerTx.v1 = XdrTransactionV1Envelope(tx, []);

      final feeBumpTx = XdrFeeBumpTransaction(
        feeSource,
        XdrInt64(BigInt.from(2000)),
        innerTx,
        XdrFeeBumpTransactionExt(0),
      );
      final envelope = XdrFeeBumpTransactionEnvelope(feeBumpTx, []);

      final newFeeBumpTx = XdrFeeBumpTransaction(
        feeSource,
        XdrInt64(BigInt.from(3000)),
        innerTx,
        XdrFeeBumpTransactionExt(0),
      );
      envelope.tx = newFeeBumpTx;
      expect(envelope.tx, equals(newFeeBumpTx));

      final sig = XdrDecoratedSignature(XdrSignatureHint(Uint8List(4)), XdrSignature(Uint8List(64)));
      envelope.signatures = [sig];
      expect(envelope.signatures.length, equals(1));
    });
  });

  group('XdrTransactionV0Envelope setters', () {
    test('should set tx and signatures', () {
      final timeBounds = XdrTimeBounds(XdrUint64(BigInt.zero), XdrUint64(BigInt.from(999999999999)));
      final tx = XdrTransactionV0(
        XdrUint256(Uint8List(32)),
        XdrUint32(100),
        XdrSequenceNumber(XdrBigInt64(BigInt.from(1))),
        timeBounds,
        XdrMemo(XdrMemoType.MEMO_NONE),
        [],
        XdrTransactionV0Ext(0),
      );
      final envelope = XdrTransactionV0Envelope(tx, []);

      final newTx = XdrTransactionV0(
        XdrUint256(Uint8List(32)),
        XdrUint32(200),
        XdrSequenceNumber(XdrBigInt64(BigInt.from(2))),
        timeBounds,
        XdrMemo(XdrMemoType.MEMO_NONE),
        [],
        XdrTransactionV0Ext(0),
      );
      envelope.tx = newTx;
      expect(envelope.tx, equals(newTx));

      final sig = XdrDecoratedSignature(XdrSignatureHint(Uint8List(4)), XdrSignature(Uint8List(64)));
      envelope.signatures = [sig];
      expect(envelope.signatures.length, equals(1));
    });
  });

  group('XdrMemo setters', () {
    test('should set discriminant', () {
      final memo = XdrMemo(XdrMemoType.MEMO_NONE);
      memo.discriminant = XdrMemoType.MEMO_TEXT;
      expect(memo.discriminant, equals(XdrMemoType.MEMO_TEXT));
    });

    test('should set text', () {
      final memo = XdrMemo(XdrMemoType.MEMO_TEXT);
      memo.text = 'test memo';
      expect(memo.text, equals('test memo'));
    });

    test('should set id', () {
      final memo = XdrMemo(XdrMemoType.MEMO_ID);
      memo.id = XdrUint64(BigInt.from(12345));
      expect(memo.id!.uint64, equals(BigInt.from(12345)));
    });

    test('should set hash', () {
      final memo = XdrMemo(XdrMemoType.MEMO_HASH);
      final hash = XdrHash(Uint8List(32));
      memo.hash = hash;
      expect(memo.hash, equals(hash));
    });

    test('should set retHash', () {
      final memo = XdrMemo(XdrMemoType.MEMO_RETURN);
      final hash = XdrHash(Uint8List(32));
      memo.retHash = hash;
      expect(memo.retHash, equals(hash));
    });
  });

  group('XdrTimeBounds setters', () {
    test('should set minTime and maxTime', () {
      final timeBounds = XdrTimeBounds(
        XdrUint64(BigInt.zero),
        XdrUint64(BigInt.from(999999999999)),
      );
      final newMinTime = XdrUint64(BigInt.from(1000));
      timeBounds.minTime = newMinTime;
      expect(timeBounds.minTime, equals(newMinTime));

      final newMaxTime = XdrUint64(BigInt.from(2000));
      timeBounds.maxTime = newMaxTime;
      expect(timeBounds.maxTime, equals(newMaxTime));
    });
  });

  group('XdrLedgerBounds setters', () {
    test('should set minLedger and maxLedger', () {
      final ledgerBounds = XdrLedgerBounds(XdrUint32(100), XdrUint32(200));
      ledgerBounds.minLedger = XdrUint32(150);
      expect(ledgerBounds.minLedger.uint32, equals(150));

      ledgerBounds.maxLedger = XdrUint32(250);
      expect(ledgerBounds.maxLedger.uint32, equals(250));
    });
  });

  group('XdrPreconditions setters', () {
    test('should set discriminant', () {
      final preconditions = XdrPreconditions(XdrPreconditionType.NONE);
      preconditions.discriminant = XdrPreconditionType.TIME;
      expect(preconditions.discriminant, equals(XdrPreconditionType.TIME));
    });

    test('should set timeBounds', () {
      final preconditions = XdrPreconditions(XdrPreconditionType.TIME);
      final timeBounds = XdrTimeBounds(
        XdrUint64(BigInt.zero),
        XdrUint64(BigInt.from(999999999999)),
      );
      preconditions.timeBounds = timeBounds;
      expect(preconditions.timeBounds, equals(timeBounds));
    });

    test('should set v2', () {
      final preconditions = XdrPreconditions(XdrPreconditionType.V2);
      final v2 = XdrPreconditionsV2(
        XdrUint64(BigInt.zero),
        XdrUint32(0),
        [],
      );
      preconditions.v2 = v2;
      expect(preconditions.v2, equals(v2));
    });
  });

  group('XdrPreconditionsV2 setters', () {
    test('should set timeBounds', () {
      final v2 = XdrPreconditionsV2(
        XdrUint64(BigInt.zero),
        XdrUint32(0),
        [],
      );
      final timeBounds = XdrTimeBounds(
        XdrUint64(BigInt.from(1000)),
        XdrUint64(BigInt.from(2000)),
      );
      v2.timeBounds = timeBounds;
      expect(v2.timeBounds, equals(timeBounds));
    });

    test('should set ledgerBounds', () {
      final v2 = XdrPreconditionsV2(
        XdrUint64(BigInt.zero),
        XdrUint32(0),
        [],
      );
      final ledgerBounds = XdrLedgerBounds(XdrUint32(100), XdrUint32(200));
      v2.ledgerBounds = ledgerBounds;
      expect(v2.ledgerBounds, equals(ledgerBounds));
    });

    test('should set sequenceNumber (minSeqNum)', () {
      final v2 = XdrPreconditionsV2(
        XdrUint64(BigInt.zero),
        XdrUint32(0),
        [],
      );
      final newMinSeqNum = XdrBigInt64(BigInt.from(5000));
      v2.sequenceNumber = newMinSeqNum;
      expect(v2.sequenceNumber, equals(newMinSeqNum));
    });

    test('should set minSeqAge', () {
      final v2 = XdrPreconditionsV2(
        XdrUint64(BigInt.zero),
        XdrUint32(0),
        [],
      );
      v2.minSeqAge = XdrUint64(BigInt.from(3600));
      expect(v2.minSeqAge.uint64, equals(BigInt.from(3600)));
    });

    test('should set minSeqLedgerGap', () {
      final v2 = XdrPreconditionsV2(
        XdrUint64(BigInt.zero),
        XdrUint32(0),
        [],
      );
      v2.minSeqLedgerGap = XdrUint32(10);
      expect(v2.minSeqLedgerGap.uint32, equals(10));
    });

    test('should set extraSigners', () {
      final v2 = XdrPreconditionsV2(
        XdrUint64(BigInt.zero),
        XdrUint32(0),
        [],
      );
      final signer = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519);
      signer.ed25519 = XdrUint256(Uint8List(32));
      v2.extraSigners = [signer];
      expect(v2.extraSigners.length, equals(1));
    });
  });
}
