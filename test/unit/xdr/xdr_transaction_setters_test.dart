import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:typed_data';

void main() {
  group('XdrTransactionExt', () {
    test('should set discriminant', () {
      final ext = XdrTransactionExt(0);
      ext.discriminant = 1;
      expect(ext.discriminant, equals(1));
    });

    test('should set sorobanTransactionData', () {
      final ext = XdrTransactionExt(1);
      final sorobanData = XdrSorobanTransactionData(
        XdrSorobanTransactionDataExt(0),
        XdrSorobanResources(
          XdrLedgerFootprint([], []),
          XdrUint32(1000),
          XdrUint32(2000),
          XdrUint32(3000),
        ),
        XdrInt64(BigInt.from(5000)),
      );
      ext.sorobanTransactionData = sorobanData;
      expect(ext.sorobanTransactionData, equals(sorobanData));
    });

    test('should encode and decode with discriminant 1', () {
      final ext = XdrTransactionExt(1);
      ext.sorobanTransactionData = XdrSorobanTransactionData(
        XdrSorobanTransactionDataExt(0),
        XdrSorobanResources(
          XdrLedgerFootprint([], []),
          XdrUint32(1000),
          XdrUint32(2000),
          XdrUint32(3000),
        ),
        XdrInt64(BigInt.from(5000)),
      );

      final stream = XdrDataOutputStream();
      XdrTransactionExt.encode(stream, ext);
      final bytes = Uint8List.fromList(stream.bytes);

      final decoded = XdrTransactionExt.decode(XdrDataInputStream(bytes));
      expect(decoded.discriminant, equals(1));
      expect(decoded.sorobanTransactionData, isNotNull);
    });
  });

  group('XdrFeeBumpTransaction setters', () {
    test('should set feeSource', () {
      final muxedAccount = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      muxedAccount.ed25519 = XdrUint256(Uint8List(32));
      final tx = XdrFeeBumpTransaction(
        muxedAccount,
        XdrInt64(BigInt.from(1000)),
        XdrFeeBumpTransactionInnerTx(XdrEnvelopeType.ENVELOPE_TYPE_TX),
        XdrFeeBumpTransactionExt(0),
      );

      final newMuxedAccount = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      newMuxedAccount.ed25519 = XdrUint256(Uint8List.fromList(List.filled(32, 1)));
      tx.feeSource = newMuxedAccount;
      expect(tx.feeSource, equals(newMuxedAccount));
    });

    test('should set fee', () {
      final muxedAccount = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      muxedAccount.ed25519 = XdrUint256(Uint8List(32));
      final tx = XdrFeeBumpTransaction(
        muxedAccount,
        XdrInt64(BigInt.from(1000)),
        XdrFeeBumpTransactionInnerTx(XdrEnvelopeType.ENVELOPE_TYPE_TX),
        XdrFeeBumpTransactionExt(0),
      );

      tx.fee = XdrInt64(BigInt.from(2000));
      expect(tx.fee.int64, equals(BigInt.from(2000)));
    });

    test('should set innerTx', () {
      final muxedAccount = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      muxedAccount.ed25519 = XdrUint256(Uint8List(32));
      final tx = XdrFeeBumpTransaction(
        muxedAccount,
        XdrInt64(BigInt.from(1000)),
        XdrFeeBumpTransactionInnerTx(XdrEnvelopeType.ENVELOPE_TYPE_TX),
        XdrFeeBumpTransactionExt(0),
      );

      final newInnerTx = XdrFeeBumpTransactionInnerTx(XdrEnvelopeType.ENVELOPE_TYPE_TX_V0);
      tx.innerTx = newInnerTx;
      expect(tx.innerTx.discriminant, equals(XdrEnvelopeType.ENVELOPE_TYPE_TX_V0));
    });

    test('should set ext', () {
      final muxedAccount = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      muxedAccount.ed25519 = XdrUint256(Uint8List(32));
      final tx = XdrFeeBumpTransaction(
        muxedAccount,
        XdrInt64(BigInt.from(1000)),
        XdrFeeBumpTransactionInnerTx(XdrEnvelopeType.ENVELOPE_TYPE_TX),
        XdrFeeBumpTransactionExt(0),
      );

      final newExt = XdrFeeBumpTransactionExt(1);
      tx.ext = newExt;
      expect(tx.ext.discriminant, equals(1));
    });
  });

  group('XdrTransactionV0 setters', () {
    test('should set sourceAccountEd25519', () {
      final tx = XdrTransactionV0(
        XdrUint256(Uint8List(32)),
        XdrUint32(100),
        XdrSequenceNumber(XdrBigInt64(BigInt.one)),
        null,
        XdrMemo(XdrMemoType.MEMO_NONE),
        [],
        XdrTransactionV0Ext(0),
      );

      final newAccount = XdrUint256(Uint8List.fromList(List.filled(32, 1)));
      tx.sourceAccountEd25519 = newAccount;
      expect(tx.sourceAccountEd25519, equals(newAccount));
    });

    test('should set fee', () {
      final tx = XdrTransactionV0(
        XdrUint256(Uint8List(32)),
        XdrUint32(100),
        XdrSequenceNumber(XdrBigInt64(BigInt.one)),
        null,
        XdrMemo(XdrMemoType.MEMO_NONE),
        [],
        XdrTransactionV0Ext(0),
      );

      tx.fee = XdrUint32(200);
      expect(tx.fee.uint32, equals(200));
    });

    test('should set seqNum', () {
      final tx = XdrTransactionV0(
        XdrUint256(Uint8List(32)),
        XdrUint32(100),
        XdrSequenceNumber(XdrBigInt64(BigInt.one)),
        null,
        XdrMemo(XdrMemoType.MEMO_NONE),
        [],
        XdrTransactionV0Ext(0),
      );

      tx.seqNum = XdrSequenceNumber(XdrBigInt64(BigInt.from(999)));
      expect(tx.seqNum.sequenceNumber.bigInt, equals(BigInt.from(999)));
    });

    test('should set timeBounds', () {
      final tx = XdrTransactionV0(
        XdrUint256(Uint8List(32)),
        XdrUint32(100),
        XdrSequenceNumber(XdrBigInt64(BigInt.one)),
        null,
        XdrMemo(XdrMemoType.MEMO_NONE),
        [],
        XdrTransactionV0Ext(0),
      );

      final timeBounds = XdrTimeBounds(XdrUint64(BigInt.from(1000)), XdrUint64(BigInt.from(2000)));
      tx.timeBounds = timeBounds;
      expect(tx.timeBounds, equals(timeBounds));
    });

    test('should set memo', () {
      final tx = XdrTransactionV0(
        XdrUint256(Uint8List(32)),
        XdrUint32(100),
        XdrSequenceNumber(XdrBigInt64(BigInt.one)),
        null,
        XdrMemo(XdrMemoType.MEMO_NONE),
        [],
        XdrTransactionV0Ext(0),
      );

      final newMemo = XdrMemo(XdrMemoType.MEMO_TEXT);
      newMemo.text = 'test';
      tx.memo = newMemo;
      expect(tx.memo.discriminant, equals(XdrMemoType.MEMO_TEXT));
    });

    test('should set operations', () {
      final tx = XdrTransactionV0(
        XdrUint256(Uint8List(32)),
        XdrUint32(100),
        XdrSequenceNumber(XdrBigInt64(BigInt.one)),
        null,
        XdrMemo(XdrMemoType.MEMO_NONE),
        [],
        XdrTransactionV0Ext(0),
      );

      final ops = <XdrOperation>[
        XdrOperation(XdrOperationBody(XdrOperationType.BUMP_SEQUENCE)),
      ];
      tx.operations = ops;
      expect(tx.operations.length, equals(1));
    });

    test('should set ext', () {
      final tx = XdrTransactionV0(
        XdrUint256(Uint8List(32)),
        XdrUint32(100),
        XdrSequenceNumber(XdrBigInt64(BigInt.one)),
        null,
        XdrMemo(XdrMemoType.MEMO_NONE),
        [],
        XdrTransactionV0Ext(0),
      );

      final newExt = XdrTransactionV0Ext(1);
      tx.ext = newExt;
      expect(tx.ext.discriminant, equals(1));
    });
  });

  group('XdrTransactionMeta', () {
    test('should convert fromBase64EncodedXdrString', () {
      final meta = XdrTransactionMeta(0);
      meta.operations = [];
      final base64 = meta.toBase64EncodedXdrString();

      final decoded = XdrTransactionMeta.fromBase64EncodedXdrString(base64);
      expect(decoded.discriminant, equals(0));
    });

    test('should encode and decode discriminant 4', () {
      final meta = XdrTransactionMeta(4);
      meta.v4 = XdrTransactionMetaV4(
        XdrExtensionPoint(0),
        XdrLedgerEntryChanges([]),
        [],
        XdrLedgerEntryChanges([]),
        null,
        [],
        [],
      );

      final stream = XdrDataOutputStream();
      XdrTransactionMeta.encode(stream, meta);
      final bytes = Uint8List.fromList(stream.bytes);

      final decoded = XdrTransactionMeta.decode(XdrDataInputStream(bytes));
      expect(decoded.discriminant, equals(4));
      expect(decoded.v4, isNotNull);
    });
  });

  group('XdrSorobanTransactionMetaExtV1 setters', () {
    test('should set totalNonRefundableResourceFeeCharged', () {
      final metaExt = XdrSorobanTransactionMetaExtV1(
        XdrExtensionPoint(0),
        XdrInt64(BigInt.from(100)),
        XdrInt64(BigInt.from(200)),
        XdrInt64(BigInt.from(50)),
      );

      metaExt.totalNonRefundableResourceFeeCharged = XdrInt64(BigInt.from(300));
      expect(metaExt.totalNonRefundableResourceFeeCharged.int64, equals(BigInt.from(300)));
    });
  });

  group('XdrSorobanTransactionMeta setters', () {
    test('should set events', () {
      final meta = XdrSorobanTransactionMeta(
        XdrSorobanTransactionMetaExt(0),
        [],
        XdrSCVal.forU32(0),
        [],
      );

      final events = [
        XdrContractEvent(
          XdrExtensionPoint(0),
          null,
          XdrContractEventType.CONTRACT_EVENT_TYPE_SYSTEM,
          XdrContractEventBody(0)
            ..v0 = XdrContractEventBodyV0([], XdrSCVal.forU32(0)),
        ),
      ];
      meta.events = events;
      expect(meta.events.length, equals(1));
    });

    test('should set returnValue', () {
      final meta = XdrSorobanTransactionMeta(
        XdrSorobanTransactionMetaExt(0),
        [],
        XdrSCVal.forU32(0),
        [],
      );

      final returnValue = XdrSCVal.forU64(BigInt.from(999));
      meta.returnValue = returnValue;
      expect(meta.returnValue, equals(returnValue));
    });

    test('should set diagnosticEvents', () {
      final meta = XdrSorobanTransactionMeta(
        XdrSorobanTransactionMetaExt(0),
        [],
        XdrSCVal.forU32(0),
        [],
      );

      final diagnosticEvents = [
        XdrDiagnosticEvent(
          true,
          XdrContractEvent(
            XdrExtensionPoint(0),
            XdrHash(Uint8List(32)),
            XdrContractEventType(0),
            XdrContractEventBody(0),
          ),
        ),
      ];
      meta.diagnosticEvents = diagnosticEvents;
      expect(meta.diagnosticEvents.length, equals(1));
    });
  });

  group('XdrTransactionMetaV3 setters', () {
    test('should set ext', () {
      final meta = XdrTransactionMetaV3(
        XdrExtensionPoint(0),
        XdrLedgerEntryChanges([]),
        [],
        XdrLedgerEntryChanges([]),
        null,
      );

      final newExt = XdrExtensionPoint(1);
      meta.ext = newExt;
      expect(meta.ext.discriminant, equals(1));
    });

    test('should set txChangesBefore', () {
      final meta = XdrTransactionMetaV3(
        XdrExtensionPoint(0),
        XdrLedgerEntryChanges([]),
        [],
        XdrLedgerEntryChanges([]),
        null,
      );

      final changes = XdrLedgerEntryChanges([
        XdrLedgerEntryChange(XdrLedgerEntryChangeType.LEDGER_ENTRY_STATE),
      ]);
      meta.txChangesBefore = changes;
      expect(meta.txChangesBefore.ledgerEntryChanges.length, equals(1));
    });

    test('should set operations', () {
      final meta = XdrTransactionMetaV3(
        XdrExtensionPoint(0),
        XdrLedgerEntryChanges([]),
        [],
        XdrLedgerEntryChanges([]),
        null,
      );

      final ops = [
        XdrOperationMeta(XdrLedgerEntryChanges([])),
      ];
      meta.operations = ops;
      expect(meta.operations.length, equals(1));
    });

    test('should set txChangesAfter', () {
      final meta = XdrTransactionMetaV3(
        XdrExtensionPoint(0),
        XdrLedgerEntryChanges([]),
        [],
        XdrLedgerEntryChanges([]),
        null,
      );

      final changes = XdrLedgerEntryChanges([
        XdrLedgerEntryChange(XdrLedgerEntryChangeType.LEDGER_ENTRY_CREATED),
      ]);
      meta.txChangesAfter = changes;
      expect(meta.txChangesAfter.ledgerEntryChanges.length, equals(1));
    });

    test('should set sorobanMeta', () {
      final meta = XdrTransactionMetaV3(
        XdrExtensionPoint(0),
        XdrLedgerEntryChanges([]),
        [],
        XdrLedgerEntryChanges([]),
        null,
      );

      final sorobanMeta = XdrSorobanTransactionMeta(
        XdrSorobanTransactionMetaExt(0),
        [],
        XdrSCVal.forU32(0),
        [],
      );
      meta.sorobanMeta = sorobanMeta;
      expect(meta.sorobanMeta, isNotNull);
    });
  });

  group('XdrTransactionEvent', () {
    test('should convert toBase64EncodedXdrString', () {
      final event = XdrTransactionEvent(
        XdrTransactionEventStage.TRANSACTION_EVENT_STAGE_BEFORE_ALL_TXS,
        XdrContractEvent(
          XdrExtensionPoint(0),
          null,
          XdrContractEventType.CONTRACT_EVENT_TYPE_SYSTEM,
          XdrContractEventBody(0)
            ..v0 = XdrContractEventBodyV0([], XdrSCVal.forU32(0)),
        ),
      );

      final base64 = event.toBase64EncodedXdrString();
      expect(base64, isNotEmpty);
    });

    test('should convert fromBase64EncodedXdrString', () {
      final event = XdrTransactionEvent(
        XdrTransactionEventStage.TRANSACTION_EVENT_STAGE_AFTER_TX,
        XdrContractEvent(
          XdrExtensionPoint(0),
          null,
          XdrContractEventType.CONTRACT_EVENT_TYPE_SYSTEM,
          XdrContractEventBody(0)
            ..v0 = XdrContractEventBodyV0([], XdrSCVal.forU32(0)),
        ),
      );

      final base64 = event.toBase64EncodedXdrString();
      final decoded = XdrTransactionEvent.fromBase64EncodedXdrString(base64);
      expect(decoded.stage, equals(XdrTransactionEventStage.TRANSACTION_EVENT_STAGE_AFTER_TX));
    });
  });

  group('XdrTransactionMetaV4 setters', () {
    test('should set ext', () {
      final meta = XdrTransactionMetaV4(
        XdrExtensionPoint(0),
        XdrLedgerEntryChanges([]),
        [],
        XdrLedgerEntryChanges([]),
        null,
        [],
        [],
      );

      final newExt = XdrExtensionPoint(1);
      meta.ext = newExt;
      expect(meta.ext.discriminant, equals(1));
    });

    test('should set txChangesBefore', () {
      final meta = XdrTransactionMetaV4(
        XdrExtensionPoint(0),
        XdrLedgerEntryChanges([]),
        [],
        XdrLedgerEntryChanges([]),
        null,
        [],
        [],
      );

      final changes = XdrLedgerEntryChanges([
        XdrLedgerEntryChange(XdrLedgerEntryChangeType.LEDGER_ENTRY_STATE),
      ]);
      meta.txChangesBefore = changes;
      expect(meta.txChangesBefore.ledgerEntryChanges.length, equals(1));
    });

    test('should set operations', () {
      final meta = XdrTransactionMetaV4(
        XdrExtensionPoint(0),
        XdrLedgerEntryChanges([]),
        [],
        XdrLedgerEntryChanges([]),
        null,
        [],
        [],
      );

      final ops = <XdrOperationMetaV2>[
        XdrOperationMetaV2(
          XdrExtensionPoint(0),
          XdrLedgerEntryChanges([]),
          [],
        ),
      ];
      meta.operations = ops;
      expect(meta.operations.length, equals(1));
    });

    test('should set txChangesAfter', () {
      final meta = XdrTransactionMetaV4(
        XdrExtensionPoint(0),
        XdrLedgerEntryChanges([]),
        [],
        XdrLedgerEntryChanges([]),
        null,
        [],
        [],
      );

      final changes = XdrLedgerEntryChanges([
        XdrLedgerEntryChange(XdrLedgerEntryChangeType.LEDGER_ENTRY_UPDATED),
      ]);
      meta.txChangesAfter = changes;
      expect(meta.txChangesAfter.ledgerEntryChanges.length, equals(1));
    });

    test('should set sorobanMeta', () {
      final meta = XdrTransactionMetaV4(
        XdrExtensionPoint(0),
        XdrLedgerEntryChanges([]),
        [],
        XdrLedgerEntryChanges([]),
        null,
        [],
        [],
      );

      final sorobanMeta = XdrSorobanTransactionMetaV2(
        XdrSorobanTransactionMetaExt(0),
        XdrSCVal.forU32(0),
      );
      meta.sorobanMeta = sorobanMeta;
      expect(meta.sorobanMeta, isNotNull);
    });

    test('should set events', () {
      final meta = XdrTransactionMetaV4(
        XdrExtensionPoint(0),
        XdrLedgerEntryChanges([]),
        [],
        XdrLedgerEntryChanges([]),
        null,
        [],
        [],
      );

      final events = [
        XdrTransactionEvent(
          XdrTransactionEventStage.TRANSACTION_EVENT_STAGE_AFTER_ALL_TXS,
          XdrContractEvent(
            XdrExtensionPoint(0),
            XdrHash(Uint8List(32)),
            XdrContractEventType(0),
            XdrContractEventBody(0),
          ),
        ),
      ];
      meta.events = events;
      expect(meta.events.length, equals(1));
    });

    test('should set diagnosticEvents', () {
      final meta = XdrTransactionMetaV4(
        XdrExtensionPoint(0),
        XdrLedgerEntryChanges([]),
        [],
        XdrLedgerEntryChanges([]),
        null,
        [],
        [],
      );

      final diagnosticEvents = [
        XdrDiagnosticEvent(
          false,
          XdrContractEvent(
            XdrExtensionPoint(0),
            XdrHash(Uint8List(32)),
            XdrContractEventType(0),
            XdrContractEventBody(0),
          ),
        ),
      ];
      meta.diagnosticEvents = diagnosticEvents;
      expect(meta.diagnosticEvents.length, equals(1));
    });
  });
}
