// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('XDR Transaction Types - Deep Branch Testing', () {
    test('XdrPreconditionType enum all variants', () {
      final types = [
        XdrPreconditionType.NONE,
        XdrPreconditionType.TIME,
        XdrPreconditionType.V2,
      ];

      for (var type in types) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrPreconditionType.encode(output, type);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrPreconditionType.decode(input);

        expect(decoded.value, equals(type.value));
      }
    });

    test('XdrPreconditions NONE encode/decode', () {
      var original = XdrPreconditions(XdrPreconditionType.NONE);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrPreconditions.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrPreconditions.decode(input);

      expect(decoded.discriminant.value, equals(XdrPreconditionType.NONE.value));
    });

    test('XdrPreconditions TIME encode/decode', () {
      var timeBounds = XdrTimeBounds(
        XdrUint64(BigInt.from(1234567890)),
        XdrUint64(BigInt.from(1234567900)),
      );

      var original = XdrPreconditions(XdrPreconditionType.TIME);
      original.timeBounds = timeBounds;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrPreconditions.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrPreconditions.decode(input);

      expect(decoded.discriminant.value, equals(XdrPreconditionType.TIME.value));
      expect(decoded.timeBounds, isNotNull);
      expect(decoded.timeBounds!.minTime.uint64, equals(BigInt.from(1234567890)));
      expect(decoded.timeBounds!.maxTime.uint64, equals(BigInt.from(1234567900)));
    });

    test('XdrPreconditions V2 encode/decode', () {
      var v2 = XdrPreconditionsV2(
        XdrUint64(BigInt.from(3600)),
        XdrUint32(5),
        [],
      );

      var original = XdrPreconditions(XdrPreconditionType.V2);
      original.v2 = v2;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrPreconditions.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrPreconditions.decode(input);

      expect(decoded.discriminant.value, equals(XdrPreconditionType.V2.value));
      expect(decoded.v2, isNotNull);
      expect(decoded.v2!.minSeqAge.uint64, equals(BigInt.from(3600)));
      expect(decoded.v2!.minSeqLedgerGap.uint32, equals(5));
    });

    test('XdrPreconditionsV2 encode/decode with all fields', () {
      var timeBounds = XdrTimeBounds(
        XdrUint64(BigInt.from(1000000)),
        XdrUint64(BigInt.from(2000000)),
      );

      var ledgerBounds = XdrLedgerBounds(
        XdrUint32(100),
        XdrUint32(200),
      );

      var signerKey = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519);
      signerKey.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAA)));

      var original = XdrPreconditionsV2(
        XdrUint64(BigInt.from(7200)),
        XdrUint32(10),
        [signerKey],
      );
      original.timeBounds = timeBounds;
      original.ledgerBounds = ledgerBounds;
      original.sequenceNumber = XdrBigInt64(BigInt.from(123456789));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrPreconditionsV2.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrPreconditionsV2.decode(input);

      expect(decoded.timeBounds, isNotNull);
      expect(decoded.timeBounds!.minTime.uint64, equals(BigInt.from(1000000)));
      expect(decoded.ledgerBounds, isNotNull);
      expect(decoded.ledgerBounds!.minLedger.uint32, equals(100));
      expect(decoded.sequenceNumber, isNotNull);
      expect(decoded.sequenceNumber!.bigInt, equals(BigInt.from(123456789)));
      expect(decoded.minSeqAge.uint64, equals(BigInt.from(7200)));
      expect(decoded.minSeqLedgerGap.uint32, equals(10));
      expect(decoded.extraSigners.length, equals(1));
    });

    test('XdrTransaction encode/decode round-trip', () {
      var sourceAccount = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      sourceAccount.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x11)));

      var preconditions = XdrPreconditions(XdrPreconditionType.NONE);
      var memo = XdrMemo(XdrMemoType.MEMO_NONE);
      var operation = XdrOperation(XdrOperationBody(XdrOperationType.INFLATION));
      var ext = XdrTransactionExt(0);

      var original = XdrTransaction(
        sourceAccount,
        XdrUint32(100),
        XdrSequenceNumber(XdrBigInt64(BigInt.from(1234567))),
        preconditions,
        memo,
        [operation],
        ext,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransaction.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransaction.decode(input);

      expect(decoded.fee.uint32, equals(100));
      expect(decoded.seqNum.sequenceNumber.bigInt, equals(BigInt.from(1234567)));
      expect(decoded.operations.length, equals(1));
    });

    test('XdrTransactionExt with discriminant 0 encode/decode', () {
      var original = XdrTransactionExt(0);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionExt.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionExt.decode(input);

      expect(decoded.discriminant, equals(0));
      expect(decoded.sorobanTransactionData, isNull);
    });

    test('XdrTransactionExt with discriminant 1 and SorobanTransactionData encode/decode', () {
      var footprint = XdrLedgerFootprint([], []);
      var resources = XdrSorobanResources(
        footprint,
        XdrUint32(1000000),
        XdrUint32(5000),
        XdrUint32(3000),
      );
      var sorobanData = XdrSorobanTransactionData(
        XdrSorobanTransactionDataExt(0),
        resources,
        XdrInt64(BigInt.from(500000)),
      );

      var original = XdrTransactionExt(1);
      original.sorobanTransactionData = sorobanData;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionExt.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionExt.decode(input);

      expect(decoded.discriminant, equals(1));
      expect(decoded.sorobanTransactionData, isNotNull);
      expect(decoded.sorobanTransactionData!.resources.instructions.uint32, equals(1000000));
      expect(decoded.sorobanTransactionData!.resourceFee.int64, equals(BigInt.from(500000)));
    });

    test('XdrTransactionV1Envelope encode/decode round-trip', () {
      var sourceAccount = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      sourceAccount.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x22)));

      var preconditions = XdrPreconditions(XdrPreconditionType.NONE);
      var memo = XdrMemo(XdrMemoType.MEMO_NONE);
      var operation = XdrOperation(XdrOperationBody(XdrOperationType.INFLATION));
      var ext = XdrTransactionExt(0);

      var tx = XdrTransaction(
        sourceAccount,
        XdrUint32(200),
        XdrSequenceNumber(XdrBigInt64(BigInt.from(7654321))),
        preconditions,
        memo,
        [operation],
        ext,
      );

      var signature = XdrDecoratedSignature(
        XdrSignatureHint(Uint8List.fromList([1, 2, 3, 4])),
        XdrSignature(Uint8List.fromList(List<int>.filled(64, 0x99))),
      );

      var original = XdrTransactionV1Envelope(tx, [signature]);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionV1Envelope.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionV1Envelope.decode(input);

      expect(decoded.tx.fee.uint32, equals(200));
      expect(decoded.signatures.length, equals(1));
    });

    test('XdrTransactionEnvelope ENVELOPE_TYPE_TX encode/decode', () {
      var sourceAccount = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      sourceAccount.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x33)));

      var preconditions = XdrPreconditions(XdrPreconditionType.NONE);
      var memo = XdrMemo(XdrMemoType.MEMO_NONE);
      var operation = XdrOperation(XdrOperationBody(XdrOperationType.INFLATION));
      var ext = XdrTransactionExt(0);

      var tx = XdrTransaction(
        sourceAccount,
        XdrUint32(300),
        XdrSequenceNumber(XdrBigInt64(BigInt.from(9999999))),
        preconditions,
        memo,
        [operation],
        ext,
      );

      var envelope = XdrTransactionV1Envelope(tx, []);

      var original = XdrTransactionEnvelope(XdrEnvelopeType.ENVELOPE_TYPE_TX);
      original.v1 = envelope;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionEnvelope.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionEnvelope.decode(input);

      expect(decoded.discriminant.value, equals(XdrEnvelopeType.ENVELOPE_TYPE_TX.value));
      expect(decoded.v1, isNotNull);
      expect(decoded.v1!.tx.fee.uint32, equals(300));
    });

    test('XdrTransactionEnvelope ENVELOPE_TYPE_TX_V0 encode/decode', () {
      var sourceAccountEd25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x44)));
      var timeBounds = XdrTimeBounds(
        XdrUint64(BigInt.from(100000)),
        XdrUint64(BigInt.from(200000)),
      );
      var memo = XdrMemo(XdrMemoType.MEMO_NONE);
      var operation = XdrOperation(XdrOperationBody(XdrOperationType.INFLATION));
      var ext = XdrTransactionV0Ext(0);

      var tx = XdrTransactionV0(
        sourceAccountEd25519,
        XdrUint32(400),
        XdrSequenceNumber(XdrBigInt64(BigInt.from(8888888))),
        timeBounds,
        memo,
        [operation],
        ext,
      );

      var v0Envelope = XdrTransactionV0Envelope(tx, []);

      var original = XdrTransactionEnvelope(XdrEnvelopeType.ENVELOPE_TYPE_TX_V0);
      original.v0 = v0Envelope;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionEnvelope.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionEnvelope.decode(input);

      expect(decoded.discriminant.value, equals(XdrEnvelopeType.ENVELOPE_TYPE_TX_V0.value));
      expect(decoded.v0, isNotNull);
      expect(decoded.v0!.tx.fee.uint32, equals(400));
    });

    test('XdrTransactionV0 with null timeBounds encode/decode', () {
      var sourceAccountEd25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x55)));
      var memo = XdrMemo(XdrMemoType.MEMO_NONE);
      var operation = XdrOperation(XdrOperationBody(XdrOperationType.INFLATION));
      var ext = XdrTransactionV0Ext(0);

      var original = XdrTransactionV0(
        sourceAccountEd25519,
        XdrUint32(500),
        XdrSequenceNumber(XdrBigInt64(BigInt.from(7777777))),
        null,
        memo,
        [operation],
        ext,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionV0.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionV0.decode(input);

      expect(decoded.fee.uint32, equals(500));
      expect(decoded.timeBounds, isNull);
    });

    test('XdrTransactionEnvelope ENVELOPE_TYPE_TX_FEE_BUMP encode/decode', () {
      var feeSource = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      feeSource.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x66)));

      var sourceAccount = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      sourceAccount.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x77)));

      var preconditions = XdrPreconditions(XdrPreconditionType.NONE);
      var memo = XdrMemo(XdrMemoType.MEMO_NONE);
      var operation = XdrOperation(XdrOperationBody(XdrOperationType.INFLATION));
      var ext = XdrTransactionExt(0);

      var tx = XdrTransaction(
        sourceAccount,
        XdrUint32(600),
        XdrSequenceNumber(XdrBigInt64(BigInt.from(6666666))),
        preconditions,
        memo,
        [operation],
        ext,
      );

      var innerTxEnvelope = XdrTransactionV1Envelope(tx, []);
      var innerTx = XdrFeeBumpTransactionInnerTx(XdrEnvelopeType.ENVELOPE_TYPE_TX);
      innerTx.v1 = innerTxEnvelope;

      var feeBumpTx = XdrFeeBumpTransaction(
        feeSource,
        XdrInt64(BigInt.from(10000)),
        innerTx,
        XdrFeeBumpTransactionExt(0),
      );

      var feeBumpEnvelope = XdrFeeBumpTransactionEnvelope(feeBumpTx, []);

      var original = XdrTransactionEnvelope(XdrEnvelopeType.ENVELOPE_TYPE_TX_FEE_BUMP);
      original.feeBump = feeBumpEnvelope;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionEnvelope.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionEnvelope.decode(input);

      expect(decoded.discriminant.value, equals(XdrEnvelopeType.ENVELOPE_TYPE_TX_FEE_BUMP.value));
      expect(decoded.feeBump, isNotNull);
      expect(decoded.feeBump!.tx.fee.int64, equals(BigInt.from(10000)));
    });

    test('XdrSorobanResources encode/decode round-trip', () {
      var footprint = XdrLedgerFootprint([], []);

      var original = XdrSorobanResources(
        footprint,
        XdrUint32(1000000),
        XdrUint32(5000),
        XdrUint32(3000),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSorobanResources.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSorobanResources.decode(input);

      expect(decoded.instructions.uint32, equals(1000000));
      expect(decoded.diskReadBytes.uint32, equals(5000));
      expect(decoded.writeBytes.uint32, equals(3000));
    });

    test('XdrSorobanTransactionDataExt with discriminant 0 encode/decode', () {
      var original = XdrSorobanTransactionDataExt(0);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSorobanTransactionDataExt.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSorobanTransactionDataExt.decode(input);

      expect(decoded.discriminant, equals(0));
      expect(decoded.resourceExt, isNull);
    });

    test('XdrSorobanTransactionDataExt with discriminant 1 encode/decode', () {
      var resourceExt = XdrSorobanResourcesExtV0([XdrUint32(1), XdrUint32(2), XdrUint32(3)]);

      var original = XdrSorobanTransactionDataExt(1);
      original.resourceExt = resourceExt;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSorobanTransactionDataExt.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSorobanTransactionDataExt.decode(input);

      expect(decoded.discriminant, equals(1));
      expect(decoded.resourceExt, isNotNull);
      expect(decoded.resourceExt!.archivedSorobanEntries.length, equals(3));
      expect(decoded.resourceExt!.archivedSorobanEntries[0].uint32, equals(1));
    });

    test('XdrEnvelopeType enum all variants', () {
      final types = [
        XdrEnvelopeType.ENVELOPE_TYPE_TX_V0,
        XdrEnvelopeType.ENVELOPE_TYPE_SCP,
        XdrEnvelopeType.ENVELOPE_TYPE_TX,
        XdrEnvelopeType.ENVELOPE_TYPE_AUTH,
        XdrEnvelopeType.ENVELOPE_TYPE_SCPVALUE,
        XdrEnvelopeType.ENVELOPE_TYPE_TX_FEE_BUMP,
        XdrEnvelopeType.ENVELOPE_TYPE_OP_ID,
        XdrEnvelopeType.ENVELOPE_TYPE_POOL_REVOKE_OP_ID,
        XdrEnvelopeType.ENVELOPE_TYPE_CONTRACT_ID,
        XdrEnvelopeType.ENVELOPE_TYPE_SOROBAN_AUTHORIZATION,
      ];

      for (var type in types) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrEnvelopeType.encode(output, type);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrEnvelopeType.decode(input);

        expect(decoded.value, equals(type.value));
      }
    });

    test('XdrTimeBounds encode/decode round-trip', () {
      var original = XdrTimeBounds(
        XdrUint64(BigInt.from(1609459200)),
        XdrUint64(BigInt.from(1609545600)),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTimeBounds.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTimeBounds.decode(input);

      expect(decoded.minTime.uint64, equals(BigInt.from(1609459200)));
      expect(decoded.maxTime.uint64, equals(BigInt.from(1609545600)));
    });

    test('XdrLedgerBounds encode/decode round-trip', () {
      var original = XdrLedgerBounds(
        XdrUint32(12345),
        XdrUint32(67890),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerBounds.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerBounds.decode(input);

      expect(decoded.minLedger.uint32, equals(12345));
      expect(decoded.maxLedger.uint32, equals(67890));
    });

    test('XdrTransactionMeta with discriminant 0 encode/decode', () {
      var opMeta = XdrOperationMeta(XdrLedgerEntryChanges([]));
      var original = XdrTransactionMeta(0);
      original.operations = [opMeta];

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionMeta.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionMeta.decode(input);

      expect(decoded.discriminant, equals(0));
      expect(decoded.operations, isNotNull);
      expect(decoded.operations!.length, equals(1));
    });

    test('XdrTransactionMeta with discriminant 1 encode/decode', () {
      var txChanges = XdrLedgerEntryChanges([]);
      var v1 = XdrTransactionMetaV1(txChanges, []);

      var original = XdrTransactionMeta(1);
      original.v1 = v1;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionMeta.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionMeta.decode(input);

      expect(decoded.discriminant, equals(1));
      expect(decoded.v1, isNotNull);
    });

    test('XdrTransactionMeta with discriminant 2 encode/decode', () {
      var txChangesBefore = XdrLedgerEntryChanges([]);
      var txChangesAfter = XdrLedgerEntryChanges([]);
      var v2 = XdrTransactionMetaV2(txChangesBefore, [], txChangesAfter);

      var original = XdrTransactionMeta(2);
      original.v2 = v2;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionMeta.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionMeta.decode(input);

      expect(decoded.discriminant, equals(2));
      expect(decoded.v2, isNotNull);
    });

    test('XdrTransactionMeta with discriminant 3 encode/decode', () {
      var ext = XdrExtensionPoint(0);
      var txChangesBefore = XdrLedgerEntryChanges([]);
      var txChangesAfter = XdrLedgerEntryChanges([]);
      var v3 = XdrTransactionMetaV3(ext, txChangesBefore, [], txChangesAfter, null);

      var original = XdrTransactionMeta(3);
      original.v3 = v3;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionMeta.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionMeta.decode(input);

      expect(decoded.discriminant, equals(3));
      expect(decoded.v3, isNotNull);
      expect(decoded.v3!.sorobanMeta, isNull);
    });

    test('XdrTransactionMeta with discriminant 4 encode/decode', () {
      var ext = XdrExtensionPoint(0);
      var txChangesBefore = XdrLedgerEntryChanges([]);
      var txChangesAfter = XdrLedgerEntryChanges([]);
      var v4 = XdrTransactionMetaV4(ext, txChangesBefore, [], txChangesAfter, null, [], []);

      var original = XdrTransactionMeta(4);
      original.v4 = v4;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionMeta.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionMeta.decode(input);

      expect(decoded.discriminant, equals(4));
      expect(decoded.v4, isNotNull);
      expect(decoded.v4!.sorobanMeta, isNull);
    });

    test('XdrTransactionMetaV3 with sorobanMeta encode/decode', () {
      var ext = XdrExtensionPoint(0);
      var txChangesBefore = XdrLedgerEntryChanges([]);
      var txChangesAfter = XdrLedgerEntryChanges([]);

      var scVal = XdrSCVal(XdrSCValType.SCV_BOOL);
      scVal.b = true;

      var sorobanMetaExt = XdrSorobanTransactionMetaExt(0);
      var sorobanMeta = XdrSorobanTransactionMeta(sorobanMetaExt, [], scVal, []);

      var original = XdrTransactionMetaV3(ext, txChangesBefore, [], txChangesAfter, sorobanMeta);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionMetaV3.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionMetaV3.decode(input);

      expect(decoded.sorobanMeta, isNotNull);
      expect(decoded.sorobanMeta!.returnValue.discriminant.value, equals(XdrSCValType.SCV_BOOL.value));
    });

    test('XdrSorobanTransactionMetaExt with discriminant 0 encode/decode', () {
      var original = XdrSorobanTransactionMetaExt(0);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSorobanTransactionMetaExt.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSorobanTransactionMetaExt.decode(input);

      expect(decoded.discriminant, equals(0));
      expect(decoded.v1, isNull);
    });

    test('XdrSorobanTransactionMetaExt with discriminant 1 encode/decode', () {
      var ext = XdrExtensionPoint(0);
      var v1 = XdrSorobanTransactionMetaExtV1(
        ext,
        XdrInt64(BigInt.from(1000)),
        XdrInt64(BigInt.from(500)),
        XdrInt64(BigInt.from(200)),
      );

      var original = XdrSorobanTransactionMetaExt(1);
      original.v1 = v1;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSorobanTransactionMetaExt.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSorobanTransactionMetaExt.decode(input);

      expect(decoded.discriminant, equals(1));
      expect(decoded.v1, isNotNull);
      expect(decoded.v1!.totalNonRefundableResourceFeeCharged.int64, equals(BigInt.from(1000)));
      expect(decoded.v1!.totalRefundableResourceFeeCharged.int64, equals(BigInt.from(500)));
      expect(decoded.v1!.rentFeeCharged.int64, equals(BigInt.from(200)));
    });

    test('XdrSorobanTransactionMetaV2 with null returnValue encode/decode', () {
      var ext = XdrSorobanTransactionMetaExt(0);
      var original = XdrSorobanTransactionMetaV2(ext, null);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSorobanTransactionMetaV2.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSorobanTransactionMetaV2.decode(input);

      expect(decoded.returnValue, isNull);
    });

    test('XdrSorobanTransactionMetaV2 with returnValue encode/decode', () {
      var ext = XdrSorobanTransactionMetaExt(0);
      var scVal = XdrSCVal(XdrSCValType.SCV_U32);
      scVal.u32 = XdrUint32(42);

      var original = XdrSorobanTransactionMetaV2(ext, scVal);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSorobanTransactionMetaV2.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSorobanTransactionMetaV2.decode(input);

      expect(decoded.returnValue, isNotNull);
      expect(decoded.returnValue!.u32!.uint32, equals(42));
    });

    test('XdrTransactionMetaV4 with sorobanMeta encode/decode', () {
      var ext = XdrExtensionPoint(0);
      var txChangesBefore = XdrLedgerEntryChanges([]);
      var txChangesAfter = XdrLedgerEntryChanges([]);

      var sorobanMetaExt = XdrSorobanTransactionMetaExt(0);
      var sorobanMeta = XdrSorobanTransactionMetaV2(sorobanMetaExt, null);

      var original = XdrTransactionMetaV4(ext, txChangesBefore, [], txChangesAfter, sorobanMeta, [], []);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionMetaV4.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionMetaV4.decode(input);

      expect(decoded.sorobanMeta, isNotNull);
    });

    test('XdrContractEventType enum all variants', () {
      final types = [
        XdrContractEventType.CONTRACT_EVENT_TYPE_SYSTEM,
        XdrContractEventType.CONTRACT_EVENT_TYPE_CONTRACT,
        XdrContractEventType.CONTRACT_EVENT_TYPE_DIAGNOSTIC,
      ];

      for (var type in types) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrContractEventType.encode(output, type);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrContractEventType.decode(input);

        expect(decoded.value, equals(type.value));
      }
    });

    test('XdrDiagnosticEvent encode/decode', () {
      var ext = XdrExtensionPoint(0);
      var scVal = XdrSCVal(XdrSCValType.SCV_BOOL);
      scVal.b = true;
      var bodyV0 = XdrContractEventBodyV0([], scVal);
      var body = XdrContractEventBody(0);
      body.v0 = bodyV0;
      var contractEvent = XdrContractEvent(ext, null, XdrContractEventType.CONTRACT_EVENT_TYPE_SYSTEM, body);

      var original = XdrDiagnosticEvent(true, contractEvent);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrDiagnosticEvent.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrDiagnosticEvent.decode(input);

      expect(decoded.inSuccessfulContractCall, equals(true));
    });

    test('XdrContractEvent with hash encode/decode', () {
      var ext = XdrExtensionPoint(0);
      var hash = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xBB)));
      var scVal = XdrSCVal(XdrSCValType.SCV_BOOL);
      scVal.b = true;
      var bodyV0 = XdrContractEventBodyV0([], scVal);
      var body = XdrContractEventBody(0);
      body.v0 = bodyV0;

      var original = XdrContractEvent(ext, hash, XdrContractEventType.CONTRACT_EVENT_TYPE_CONTRACT, body);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrContractEvent.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrContractEvent.decode(input);

      expect(decoded.hash, isNotNull);
      expect(decoded.type.value, equals(XdrContractEventType.CONTRACT_EVENT_TYPE_CONTRACT.value));
    });

    test('XdrContractEvent with null hash encode/decode', () {
      var ext = XdrExtensionPoint(0);
      var scVal = XdrSCVal(XdrSCValType.SCV_BOOL);
      scVal.b = true;
      var bodyV0 = XdrContractEventBodyV0([], scVal);
      var body = XdrContractEventBody(0);
      body.v0 = bodyV0;

      var original = XdrContractEvent(ext, null, XdrContractEventType.CONTRACT_EVENT_TYPE_DIAGNOSTIC, body);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrContractEvent.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrContractEvent.decode(input);

      expect(decoded.hash, isNull);
      expect(decoded.type.value, equals(XdrContractEventType.CONTRACT_EVENT_TYPE_DIAGNOSTIC.value));
    });

    test('XdrTransactionEventStage enum all variants', () {
      final stages = [
        XdrTransactionEventStage.TRANSACTION_EVENT_STAGE_BEFORE_ALL_TXS,
        XdrTransactionEventStage.TRANSACTION_EVENT_STAGE_AFTER_TX,
        XdrTransactionEventStage.TRANSACTION_EVENT_STAGE_AFTER_ALL_TXS,
      ];

      for (var stage in stages) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrTransactionEventStage.encode(output, stage);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrTransactionEventStage.decode(input);

        expect(decoded.value, equals(stage.value));
      }
    });

    test('XdrTransactionEvent encode/decode', () {
      var ext = XdrExtensionPoint(0);
      var scVal = XdrSCVal(XdrSCValType.SCV_BOOL);
      scVal.b = true;
      var bodyV0 = XdrContractEventBodyV0([], scVal);
      var body = XdrContractEventBody(0);
      body.v0 = bodyV0;
      var contractEvent = XdrContractEvent(ext, null, XdrContractEventType.CONTRACT_EVENT_TYPE_SYSTEM, body);

      var original = XdrTransactionEvent(XdrTransactionEventStage.TRANSACTION_EVENT_STAGE_AFTER_TX, contractEvent);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionEvent.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionEvent.decode(input);

      expect(decoded.stage.value, equals(XdrTransactionEventStage.TRANSACTION_EVENT_STAGE_AFTER_TX.value));
    });

    test('XdrTransactionResultCode enum all variants', () {
      final codes = [
        XdrTransactionResultCode.txSUCCESS,
        XdrTransactionResultCode.txFEE_BUMP_INNER_SUCCESS,
        XdrTransactionResultCode.txFAILED,
        XdrTransactionResultCode.txTOO_EARLY,
        XdrTransactionResultCode.txTOO_LATE,
        XdrTransactionResultCode.txMISSING_OPERATION,
        XdrTransactionResultCode.txBAD_SEQ,
        XdrTransactionResultCode.txBAD_AUTH,
        XdrTransactionResultCode.txINSUFFICIENT_BALANCE,
        XdrTransactionResultCode.txNO_ACCOUNT,
        XdrTransactionResultCode.txINSUFFICIENT_FEE,
        XdrTransactionResultCode.txBAD_AUTH_EXTRA,
        XdrTransactionResultCode.txINTERNAL_ERROR,
        XdrTransactionResultCode.txNOT_SUPPORTED,
        XdrTransactionResultCode.txFEE_BUMP_INNER_FAILED,
        XdrTransactionResultCode.txBAD_SPONSORSHIP,
        XdrTransactionResultCode.txBAD_MIN_SEQ_AGE_OR_GAP,
        XdrTransactionResultCode.txMALFORMED,
        XdrTransactionResultCode.txSOROBAN_INVALID,
      ];

      for (var code in codes) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrTransactionResultCode.encode(output, code);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrTransactionResultCode.decode(input);

        // Verify encode/decode round-trip preserves the value
        expect(decoded.value, equals(code.value));
      }
    });

    test('XdrTransactionResultResult with txSUCCESS encode/decode', () {
      var opResult = XdrOperationResult(XdrOperationResultCode.opINNER);
      opResult.tr = XdrOperationResultTr(XdrOperationType.INFLATION);
      opResult.tr!.inflationResult = XdrInflationResult(XdrInflationResultCode.INFLATION_NOT_TIME);

      var original = XdrTransactionResultResult(XdrTransactionResultCode.txSUCCESS, [opResult], null);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionResultResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionResultResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrTransactionResultCode.txSUCCESS.value));
      expect(decoded.results, isNotNull);
      expect(decoded.results!.length, equals(1));
    });

    test('XdrTransactionResultResult with txFAILED encode/decode', () {
      var opResult = XdrOperationResult(XdrOperationResultCode.opINNER);
      opResult.tr = XdrOperationResultTr(XdrOperationType.INFLATION);
      opResult.tr!.inflationResult = XdrInflationResult(XdrInflationResultCode.INFLATION_NOT_TIME);

      var original = XdrTransactionResultResult(XdrTransactionResultCode.txFAILED, [opResult], null);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionResultResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionResultResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrTransactionResultCode.txFAILED.value));
      expect(decoded.results, isNotNull);
    });

    test('XdrTransactionResultResult with txFEE_BUMP_INNER_SUCCESS encode/decode', () {
      var hash = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xCC)));
      var innerResultResult = XdrInnerTransactionResultResult(XdrTransactionResultCode.txSUCCESS, []);
      var innerResult = XdrInnerTransactionResult(XdrInt64(BigInt.from(100)), innerResultResult, XdrTransactionResultExt(0));
      var innerResultPair = XdrInnerTransactionResultPair(hash, innerResult);

      var original = XdrTransactionResultResult(XdrTransactionResultCode.txFEE_BUMP_INNER_SUCCESS, null, innerResultPair);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionResultResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionResultResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrTransactionResultCode.txFEE_BUMP_INNER_SUCCESS.value));
      expect(decoded.innerResultPair, isNotNull);
    });

    test('XdrTransactionResultResult with txFEE_BUMP_INNER_FAILED encode/decode', () {
      var hash = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xDD)));
      var innerResultResult = XdrInnerTransactionResultResult(XdrTransactionResultCode.txFAILED, []);
      var innerResult = XdrInnerTransactionResult(XdrInt64(BigInt.from(100)), innerResultResult, XdrTransactionResultExt(0));
      var innerResultPair = XdrInnerTransactionResultPair(hash, innerResult);

      var original = XdrTransactionResultResult(XdrTransactionResultCode.txFEE_BUMP_INNER_FAILED, null, innerResultPair);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionResultResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionResultResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrTransactionResultCode.txFEE_BUMP_INNER_FAILED.value));
      expect(decoded.innerResultPair, isNotNull);
    });

    test('XdrTransactionResultResult with txTOO_EARLY (default branch) encode/decode', () {
      var original = XdrTransactionResultResult(XdrTransactionResultCode.txTOO_EARLY, null, null);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionResultResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionResultResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrTransactionResultCode.txTOO_EARLY.value));
      expect(decoded.results, isNull);
      expect(decoded.innerResultPair, isNull);
    });

    test('XdrTransactionResult encode/decode', () {
      var resultResult = XdrTransactionResultResult(XdrTransactionResultCode.txSUCCESS, [], null);
      var original = XdrTransactionResult(XdrInt64(BigInt.from(1000)), resultResult, XdrTransactionResultExt(0));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionResult.decode(input);

      expect(decoded.feeCharged.int64, equals(BigInt.from(1000)));
    });

    test('XdrTransactionResultSet encode/decode', () {
      var hash = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xEE)));
      var resultResult = XdrTransactionResultResult(XdrTransactionResultCode.txSUCCESS, [], null);
      var result = XdrTransactionResult(XdrInt64(BigInt.from(1000)), resultResult, XdrTransactionResultExt(0));
      var resultPair = XdrTransactionResultPair(hash, result);

      var original = XdrTransactionResultSet([resultPair]);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionResultSet.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionResultSet.decode(input);

      expect(decoded.results.length, equals(1));
    });

    test('XdrTransactionSet encode/decode', () {
      var hash = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xFF)));

      var sourceAccount = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      sourceAccount.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x88)));

      var preconditions = XdrPreconditions(XdrPreconditionType.NONE);
      var memo = XdrMemo(XdrMemoType.MEMO_NONE);
      var operation = XdrOperation(XdrOperationBody(XdrOperationType.INFLATION));
      var ext = XdrTransactionExt(0);

      var tx = XdrTransaction(
        sourceAccount,
        XdrUint32(700),
        XdrSequenceNumber(XdrBigInt64(BigInt.from(5555555))),
        preconditions,
        memo,
        [operation],
        ext,
      );

      var txEnvelope = XdrTransactionV1Envelope(tx, []);
      var envelope = XdrTransactionEnvelope(XdrEnvelopeType.ENVELOPE_TYPE_TX);
      envelope.v1 = txEnvelope;

      var original = XdrTransactionSet(hash, [envelope]);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionSet.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionSet.decode(input);

      expect(decoded.txEnvelopes.length, equals(1));
    });

    test('XdrTransactionSignaturePayload encode/decode', () {
      var networkId = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xAB)));

      var sourceAccount = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      sourceAccount.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x99)));

      var preconditions = XdrPreconditions(XdrPreconditionType.NONE);
      var memo = XdrMemo(XdrMemoType.MEMO_NONE);
      var operation = XdrOperation(XdrOperationBody(XdrOperationType.INFLATION));
      var ext = XdrTransactionExt(0);

      var tx = XdrTransaction(
        sourceAccount,
        XdrUint32(800),
        XdrSequenceNumber(XdrBigInt64(BigInt.from(4444444))),
        preconditions,
        memo,
        [operation],
        ext,
      );

      var taggedTx = XdrTransactionSignaturePayloadTaggedTransaction(XdrEnvelopeType.ENVELOPE_TYPE_TX);
      taggedTx.tx = tx;

      var original = XdrTransactionSignaturePayload(networkId, taggedTx);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionSignaturePayload.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionSignaturePayload.decode(input);

      expect(decoded.taggedTransaction.tx, isNotNull);
      expect(decoded.taggedTransaction.tx!.fee.uint32, equals(800));
    });

    test('XdrSorobanAuthorizedFunctionType enum all variants', () {
      final types = [
        XdrSorobanAuthorizedFunctionType.SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN,
        XdrSorobanAuthorizedFunctionType.SOROBAN_AUTHORIZED_FUNCTION_TYPE_CREATE_CONTRACT_HOST_FN,
        XdrSorobanAuthorizedFunctionType.SOROBAN_AUTHORIZED_FUNCTION_TYPE_CREATE_CONTRACT_V2_HOST_FN,
      ];

      for (var type in types) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrSorobanAuthorizedFunctionType.encode(output, type);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrSorobanAuthorizedFunctionType.decode(input);

        expect(decoded.value, equals(type.value));
      }
    });

    test('XdrSorobanAuthorizedFunction CONTRACT_FN encode/decode', () {
      var contractAddress = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT);
      contractAddress.accountId = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      contractAddress.accountId!.accountID.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAA))));

      var functionName = "test";
      var args = XdrInvokeContractArgs(contractAddress, functionName, []);

      var original = XdrSorobanAuthorizedFunction.forInvokeContractArgs(args);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSorobanAuthorizedFunction.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSorobanAuthorizedFunction.decode(input);

      expect(decoded.type.value, equals(XdrSorobanAuthorizedFunctionType.SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN.value));
      expect(decoded.contractFn, isNotNull);
    });

    test('XdrSorobanAuthorizedFunction CREATE_CONTRACT_HOST_FN encode/decode', () {
      var contractIDPreimage = XdrContractIDPreimage(XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS);
      var address = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT);
      address.accountId = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      address.accountId!.accountID.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xBB))));
      contractIDPreimage.address = address;
      contractIDPreimage.salt = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xCC)));

      var executable = XdrContractExecutable(XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM);
      executable.wasmHash = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xDD)));

      var args = XdrCreateContractArgs(contractIDPreimage, executable);

      var original = XdrSorobanAuthorizedFunction.forCreateContractArgs(args);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSorobanAuthorizedFunction.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSorobanAuthorizedFunction.decode(input);

      expect(decoded.type.value, equals(XdrSorobanAuthorizedFunctionType.SOROBAN_AUTHORIZED_FUNCTION_TYPE_CREATE_CONTRACT_HOST_FN.value));
      expect(decoded.createContractHostFn, isNotNull);
    });

    test('XdrSorobanAuthorizedInvocation encode/decode', () {
      var contractAddress = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT);
      contractAddress.accountId = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      contractAddress.accountId!.accountID.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xEE))));

      var functionName = "test";
      var args = XdrInvokeContractArgs(contractAddress, functionName, []);

      var function = XdrSorobanAuthorizedFunction.forInvokeContractArgs(args);

      var original = XdrSorobanAuthorizedInvocation(function, []);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSorobanAuthorizedInvocation.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSorobanAuthorizedInvocation.decode(input);

      expect(decoded.subInvocations.length, equals(0));
    });

    test('XdrSorobanAddressCredentials encode/decode', () {
      var address = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT);
      address.accountId = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      address.accountId!.accountID.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xFF))));

      var signature = XdrSCVal(XdrSCValType.SCV_BOOL);
      signature.b = true;

      var original = XdrSorobanAddressCredentials(address, XdrInt64(BigInt.from(12345)), XdrUint32(10000), signature);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSorobanAddressCredentials.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSorobanAddressCredentials.decode(input);

      expect(decoded.nonce.int64, equals(BigInt.from(12345)));
      expect(decoded.signatureExpirationLedger.uint32, equals(10000));
    });

    test('XdrSorobanAuthorizationEntry encode/decode', () {
      var credentials = XdrSorobanCredentials(XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_SOURCE_ACCOUNT);

      var contractAddress = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT);
      contractAddress.accountId = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      contractAddress.accountId!.accountID.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAB))));

      var functionName = "test";
      var args = XdrInvokeContractArgs(contractAddress, functionName, []);

      var function = XdrSorobanAuthorizedFunction.forInvokeContractArgs(args);
      var rootInvocation = XdrSorobanAuthorizedInvocation(function, []);

      var original = XdrSorobanAuthorizationEntry(credentials, rootInvocation);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSorobanAuthorizationEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSorobanAuthorizationEntry.decode(input);

      expect(decoded.credentials.type.value, equals(XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_SOURCE_ACCOUNT.value));
    });

    test('XdrHashIDPreimage ENVELOPE_TYPE_OP_ID encode/decode', () {
      var sourceAccount = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      sourceAccount.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAC)));

      var opID = XdrHashIDPreimageOperationID(
        sourceAccount,
        XdrSequenceNumber(XdrBigInt64(BigInt.from(1000))),
        XdrUint32(0),
      );

      var original = XdrHashIDPreimage(XdrEnvelopeType.ENVELOPE_TYPE_OP_ID);
      original.operationID = opID;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrHashIDPreimage.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrHashIDPreimage.decode(input);

      expect(decoded.discriminant.value, equals(XdrEnvelopeType.ENVELOPE_TYPE_OP_ID.value));
      expect(decoded.operationID, isNotNull);
    });

    test('XdrHashIDPreimage ENVELOPE_TYPE_POOL_REVOKE_OP_ID encode/decode', () {
      var accountID = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      accountID.accountID.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAD))));

      var asset = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);

      var revokeID = XdrHashIDPreimageRevokeID(
        accountID,
        XdrSequenceNumber(XdrBigInt64(BigInt.from(2000))),
        XdrUint32(1),
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0xBB))),
        asset,
      );

      var original = XdrHashIDPreimage(XdrEnvelopeType.ENVELOPE_TYPE_POOL_REVOKE_OP_ID);
      original.revokeID = revokeID;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrHashIDPreimage.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrHashIDPreimage.decode(input);

      expect(decoded.discriminant.value, equals(XdrEnvelopeType.ENVELOPE_TYPE_POOL_REVOKE_OP_ID.value));
      expect(decoded.revokeID, isNotNull);
    });

    test('XdrHashIDPreimage ENVELOPE_TYPE_CONTRACT_ID encode/decode', () {
      var networkID = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xCC)));

      var contractIDPreimage = XdrContractIDPreimage(XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS);
      var address = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT);
      address.accountId = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      address.accountId!.accountID.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xDD))));
      contractIDPreimage.address = address;
      contractIDPreimage.salt = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xEE)));

      var contractID = XdrHashIDPreimageContractID(networkID, contractIDPreimage);

      var original = XdrHashIDPreimage(XdrEnvelopeType.ENVELOPE_TYPE_CONTRACT_ID);
      original.contractID = contractID;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrHashIDPreimage.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrHashIDPreimage.decode(input);

      expect(decoded.discriminant.value, equals(XdrEnvelopeType.ENVELOPE_TYPE_CONTRACT_ID.value));
      expect(decoded.contractID, isNotNull);
    });

    test('XdrHashIDPreimage ENVELOPE_TYPE_SOROBAN_AUTHORIZATION encode/decode', () {
      var networkID = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xFF)));

      var contractAddress = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT);
      contractAddress.accountId = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      contractAddress.accountId!.accountID.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAE))));

      var functionName = "test";
      var args = XdrInvokeContractArgs(contractAddress, functionName, []);

      var function = XdrSorobanAuthorizedFunction.forInvokeContractArgs(args);
      var invocation = XdrSorobanAuthorizedInvocation(function, []);

      var sorobanAuth = XdrHashIDPreimageSorobanAuthorization(
        networkID,
        XdrInt64(BigInt.from(54321)),
        XdrUint32(20000),
        invocation,
      );

      var original = XdrHashIDPreimage(XdrEnvelopeType.ENVELOPE_TYPE_SOROBAN_AUTHORIZATION);
      original.sorobanAuthorization = sorobanAuth;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrHashIDPreimage.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrHashIDPreimage.decode(input);

      expect(decoded.discriminant.value, equals(XdrEnvelopeType.ENVELOPE_TYPE_SOROBAN_AUTHORIZATION.value));
      expect(decoded.sorobanAuthorization, isNotNull);
      expect(decoded.sorobanAuthorization!.nonce.int64, equals(BigInt.from(54321)));
    });
  });
}
