// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('XDR History Types - Deep Branch Testing', () {
    test('XdrSCPHistoryEntry with discriminant 0 encode/decode', () {
      var quorumSet = XdrSCPQuorumSet(
        XdrUint32(2),
        [],
        [],
      );

      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x11))));
      var nodeID = XdrNodeID(pk);

      var nomination = XdrSCPNomination(
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0x22))),
        [],
        [],
      );

      var pledges = XdrSCPStatementPledges(XdrSCPStatementType.SCP_ST_NOMINATE);
      pledges.nominate = nomination;

      var statement = XdrSCPStatement(
        nodeID,
        XdrUint64(BigInt.from(12345)),
        pledges,
      );

      var signature = XdrSignature(Uint8List.fromList(List<int>.filled(64, 0x33)));
      var envelope = XdrSCPEnvelope(statement, signature);

      var ledgerMessages = XdrLedgerSCPMessages(
        XdrUint32(100),
        [envelope],
      );

      var v0 = XdrSCPHistoryEntryV0([quorumSet], ledgerMessages);
      var original = XdrSCPHistoryEntry(0);
      original.v0 = v0;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCPHistoryEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCPHistoryEntry.decode(input);

      expect(decoded.discriminant, equals(0));
      expect(decoded.v0, isNotNull);
      expect(decoded.v0!.quorumSets.length, equals(1));
      expect(decoded.v0!.ledgerMessages.ledgerSeq.uint32, equals(100));
      expect(decoded.v0!.ledgerMessages.messages.length, equals(1));
    });

    test('XdrSCPHistoryEntryV0 with empty quorumSets encode/decode', () {
      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAA))));
      var nodeID = XdrNodeID(pk);

      var nomination = XdrSCPNomination(
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0xBB))),
        [],
        [],
      );

      var pledges = XdrSCPStatementPledges(XdrSCPStatementType.SCP_ST_NOMINATE);
      pledges.nominate = nomination;

      var statement = XdrSCPStatement(
        nodeID,
        XdrUint64(BigInt.from(99999)),
        pledges,
      );

      var signature = XdrSignature(Uint8List.fromList(List<int>.filled(64, 0xCC)));
      var envelope = XdrSCPEnvelope(statement, signature);

      var ledgerMessages = XdrLedgerSCPMessages(
        XdrUint32(200),
        [envelope],
      );

      var original = XdrSCPHistoryEntryV0([], ledgerMessages);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCPHistoryEntryV0.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCPHistoryEntryV0.decode(input);

      expect(decoded.quorumSets, isEmpty);
      expect(decoded.ledgerMessages.ledgerSeq.uint32, equals(200));
      expect(decoded.ledgerMessages.messages.length, equals(1));
    });

    test('XdrSCPHistoryEntryV0 with multiple quorumSets encode/decode', () {
      var pk1 = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk1.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x11))));

      var pk2 = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk2.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x22))));

      var quorumSet1 = XdrSCPQuorumSet(
        XdrUint32(1),
        [pk1],
        [],
      );

      var quorumSet2 = XdrSCPQuorumSet(
        XdrUint32(2),
        [pk2],
        [],
      );

      var nodeID = XdrNodeID(pk1);

      var nomination = XdrSCPNomination(
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0x33))),
        [],
        [],
      );

      var pledges = XdrSCPStatementPledges(XdrSCPStatementType.SCP_ST_NOMINATE);
      pledges.nominate = nomination;

      var statement = XdrSCPStatement(
        nodeID,
        XdrUint64(BigInt.from(54321)),
        pledges,
      );

      var signature = XdrSignature(Uint8List.fromList(List<int>.filled(64, 0x44)));
      var envelope = XdrSCPEnvelope(statement, signature);

      var ledgerMessages = XdrLedgerSCPMessages(
        XdrUint32(300),
        [envelope],
      );

      var original = XdrSCPHistoryEntryV0([quorumSet1, quorumSet2], ledgerMessages);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCPHistoryEntryV0.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCPHistoryEntryV0.decode(input);

      expect(decoded.quorumSets.length, equals(2));
      expect(decoded.quorumSets[0].threshold.uint32, equals(1));
      expect(decoded.quorumSets[1].threshold.uint32, equals(2));
      expect(decoded.ledgerMessages.ledgerSeq.uint32, equals(300));
    });

    test('XdrSCPHistoryEntryV0 with empty messages encode/decode', () {
      var quorumSet = XdrSCPQuorumSet(
        XdrUint32(3),
        [],
        [],
      );

      var ledgerMessages = XdrLedgerSCPMessages(
        XdrUint32(400),
        [],
      );

      var original = XdrSCPHistoryEntryV0([quorumSet], ledgerMessages);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCPHistoryEntryV0.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCPHistoryEntryV0.decode(input);

      expect(decoded.quorumSets.length, equals(1));
      expect(decoded.ledgerMessages.ledgerSeq.uint32, equals(400));
      expect(decoded.ledgerMessages.messages, isEmpty);
    });

    test('XdrTransactionHistoryEntry encode/decode with empty txSet', () {
      var txSet = XdrTransactionSet(
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0xAA))),
        [],
      );

      var ext = XdrTransactionHistoryEntryExt(0);

      var original = XdrTransactionHistoryEntry(
        XdrUint32(1000),
        txSet,
        ext,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionHistoryEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionHistoryEntry.decode(input);

      expect(decoded.ledgerSeq.uint32, equals(1000));
      expect(decoded.txSet.txEnvelopes, isEmpty);
      expect(decoded.ext.discriminant, equals(0));
    });

    test('XdrTransactionHistoryEntry encode/decode with txSet containing envelope', () {
      var sourceAccount = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      sourceAccount.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x11)));

      var preconditions = XdrPreconditions(XdrPreconditionType.NONE);
      var memo = XdrMemo(XdrMemoType.MEMO_NONE);
      var operation = XdrOperation(XdrOperationBody(XdrOperationType.INFLATION));
      var txExt = XdrTransactionExt(0);

      var transaction = XdrTransaction(
        sourceAccount,
        XdrUint32(100),
        XdrSequenceNumber(XdrBigInt64(BigInt.from(1234567))),
        preconditions,
        memo,
        [operation],
        txExt,
      );

      var signature = XdrDecoratedSignature(
        XdrSignatureHint(Uint8List.fromList([1, 2, 3, 4])),
        XdrSignature(Uint8List.fromList(List<int>.filled(64, 0x55))),
      );

      var txV1Envelope = XdrTransactionV1Envelope(
        transaction,
        [signature],
      );

      var txEnvelope = XdrTransactionEnvelope(XdrEnvelopeType.ENVELOPE_TYPE_TX);
      txEnvelope.v1 = txV1Envelope;

      var txSet = XdrTransactionSet(
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0xBB))),
        [txEnvelope],
      );

      var ext = XdrTransactionHistoryEntryExt(0);

      var original = XdrTransactionHistoryEntry(
        XdrUint32(2000),
        txSet,
        ext,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionHistoryEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionHistoryEntry.decode(input);

      expect(decoded.ledgerSeq.uint32, equals(2000));
      expect(decoded.txSet.txEnvelopes.length, equals(1));
      expect(decoded.txSet.txEnvelopes[0].discriminant.value, equals(XdrEnvelopeType.ENVELOPE_TYPE_TX.value));
      expect(decoded.ext.discriminant, equals(0));
    });

    test('XdrTransactionHistoryEntryExt with discriminant 0 encode/decode', () {
      var original = XdrTransactionHistoryEntryExt(0);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionHistoryEntryExt.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionHistoryEntryExt.decode(input);

      expect(decoded.discriminant, equals(0));
    });

    test('XdrTransactionHistoryResultEntry encode/decode with empty results', () {
      var txResultSet = XdrTransactionResultSet([]);
      var ext = XdrTransactionHistoryResultEntryExt(0);

      var original = XdrTransactionHistoryResultEntry(
        XdrUint32(3000),
        txResultSet,
        ext,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionHistoryResultEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionHistoryResultEntry.decode(input);

      expect(decoded.ledgerSeq.uint32, equals(3000));
      expect(decoded.txResultSet.results, isEmpty);
      expect(decoded.ext.discriminant, equals(0));
    });

    test('XdrTransactionHistoryResultEntry encode/decode with result pair', () {
      var txHash = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xCC)));

      var resultResult = XdrTransactionResultResult(
        XdrTransactionResultCode.txSUCCESS,
        [],
        null,
      );

      var resultExt = XdrTransactionResultExt(0);

      var result = XdrTransactionResult(
        XdrInt64(BigInt.from(100)),
        resultResult,
        resultExt,
      );

      var resultPair = XdrTransactionResultPair(txHash, result);
      var txResultSet = XdrTransactionResultSet([resultPair]);
      var ext = XdrTransactionHistoryResultEntryExt(0);

      var original = XdrTransactionHistoryResultEntry(
        XdrUint32(4000),
        txResultSet,
        ext,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionHistoryResultEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionHistoryResultEntry.decode(input);

      expect(decoded.ledgerSeq.uint32, equals(4000));
      expect(decoded.txResultSet.results.length, equals(1));
      expect(decoded.txResultSet.results[0].transactionHash.hash, equals(txHash.hash));
      expect(decoded.ext.discriminant, equals(0));
    });

    test('XdrTransactionHistoryResultEntry encode/decode with multiple results', () {
      var txHash1 = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xDD)));
      var txHash2 = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xEE)));

      var resultResult1 = XdrTransactionResultResult(
        XdrTransactionResultCode.txSUCCESS,
        [],
        null,
      );

      var resultResult2 = XdrTransactionResultResult(
        XdrTransactionResultCode.txFAILED,
        [],
        null,
      );

      var resultExt = XdrTransactionResultExt(0);

      var result1 = XdrTransactionResult(
        XdrInt64(BigInt.from(100)),
        resultResult1,
        resultExt,
      );

      var result2 = XdrTransactionResult(
        XdrInt64(BigInt.from(200)),
        resultResult2,
        resultExt,
      );

      var resultPair1 = XdrTransactionResultPair(txHash1, result1);
      var resultPair2 = XdrTransactionResultPair(txHash2, result2);

      var txResultSet = XdrTransactionResultSet([resultPair1, resultPair2]);
      var ext = XdrTransactionHistoryResultEntryExt(0);

      var original = XdrTransactionHistoryResultEntry(
        XdrUint32(5000),
        txResultSet,
        ext,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionHistoryResultEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionHistoryResultEntry.decode(input);

      expect(decoded.ledgerSeq.uint32, equals(5000));
      expect(decoded.txResultSet.results.length, equals(2));
      expect(decoded.txResultSet.results[0].transactionHash.hash, equals(txHash1.hash));
      expect(decoded.txResultSet.results[1].transactionHash.hash, equals(txHash2.hash));
      expect(decoded.ext.discriminant, equals(0));
    });

    test('XdrTransactionHistoryResultEntryExt with discriminant 0 encode/decode', () {
      var original = XdrTransactionHistoryResultEntryExt(0);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionHistoryResultEntryExt.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionHistoryResultEntryExt.decode(input);

      expect(decoded.discriminant, equals(0));
    });

    test('XdrSCPHistoryEntryV0 with multiple messages encode/decode', () {
      var quorumSet = XdrSCPQuorumSet(
        XdrUint32(2),
        [],
        [],
      );

      var pk1 = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk1.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x55))));
      var nodeID1 = XdrNodeID(pk1);

      var pk2 = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk2.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x66))));
      var nodeID2 = XdrNodeID(pk2);

      var nomination1 = XdrSCPNomination(
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0x77))),
        [],
        [],
      );

      var nomination2 = XdrSCPNomination(
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0x88))),
        [],
        [],
      );

      var pledges1 = XdrSCPStatementPledges(XdrSCPStatementType.SCP_ST_NOMINATE);
      pledges1.nominate = nomination1;

      var pledges2 = XdrSCPStatementPledges(XdrSCPStatementType.SCP_ST_NOMINATE);
      pledges2.nominate = nomination2;

      var statement1 = XdrSCPStatement(
        nodeID1,
        XdrUint64(BigInt.from(11111)),
        pledges1,
      );

      var statement2 = XdrSCPStatement(
        nodeID2,
        XdrUint64(BigInt.from(22222)),
        pledges2,
      );

      var signature1 = XdrSignature(Uint8List.fromList(List<int>.filled(64, 0x99)));
      var signature2 = XdrSignature(Uint8List.fromList(List<int>.filled(64, 0xAA)));

      var envelope1 = XdrSCPEnvelope(statement1, signature1);
      var envelope2 = XdrSCPEnvelope(statement2, signature2);

      var ledgerMessages = XdrLedgerSCPMessages(
        XdrUint32(500),
        [envelope1, envelope2],
      );

      var original = XdrSCPHistoryEntryV0([quorumSet], ledgerMessages);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCPHistoryEntryV0.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCPHistoryEntryV0.decode(input);

      expect(decoded.quorumSets.length, equals(1));
      expect(decoded.ledgerMessages.ledgerSeq.uint32, equals(500));
      expect(decoded.ledgerMessages.messages.length, equals(2));
      expect(decoded.ledgerMessages.messages[0].statement.slotIndex.uint64, equals(BigInt.from(11111)));
      expect(decoded.ledgerMessages.messages[1].statement.slotIndex.uint64, equals(BigInt.from(22222)));
    });

    test('XdrTransactionHistoryEntry with multiple transactions encode/decode', () {
      var sourceAccount = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      sourceAccount.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x11)));

      var preconditions = XdrPreconditions(XdrPreconditionType.NONE);
      var memo = XdrMemo(XdrMemoType.MEMO_NONE);
      var operation = XdrOperation(XdrOperationBody(XdrOperationType.INFLATION));
      var txExt = XdrTransactionExt(0);

      var transaction1 = XdrTransaction(
        sourceAccount,
        XdrUint32(100),
        XdrSequenceNumber(XdrBigInt64(BigInt.from(1111111))),
        preconditions,
        memo,
        [operation],
        txExt,
      );

      var transaction2 = XdrTransaction(
        sourceAccount,
        XdrUint32(200),
        XdrSequenceNumber(XdrBigInt64(BigInt.from(2222222))),
        preconditions,
        memo,
        [operation],
        txExt,
      );

      var signature = XdrDecoratedSignature(
        XdrSignatureHint(Uint8List.fromList([1, 2, 3, 4])),
        XdrSignature(Uint8List.fromList(List<int>.filled(64, 0x55))),
      );

      var txV1Envelope1 = XdrTransactionV1Envelope(
        transaction1,
        [signature],
      );

      var txV1Envelope2 = XdrTransactionV1Envelope(
        transaction2,
        [signature],
      );

      var txEnvelope1 = XdrTransactionEnvelope(XdrEnvelopeType.ENVELOPE_TYPE_TX);
      txEnvelope1.v1 = txV1Envelope1;

      var txEnvelope2 = XdrTransactionEnvelope(XdrEnvelopeType.ENVELOPE_TYPE_TX);
      txEnvelope2.v1 = txV1Envelope2;

      var txSet = XdrTransactionSet(
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0xFF))),
        [txEnvelope1, txEnvelope2],
      );

      var ext = XdrTransactionHistoryEntryExt(0);

      var original = XdrTransactionHistoryEntry(
        XdrUint32(6000),
        txSet,
        ext,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionHistoryEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionHistoryEntry.decode(input);

      expect(decoded.ledgerSeq.uint32, equals(6000));
      expect(decoded.txSet.txEnvelopes.length, equals(2));
      expect(decoded.txSet.txEnvelopes[0].v1!.tx.fee.uint32, equals(100));
      expect(decoded.txSet.txEnvelopes[1].v1!.tx.fee.uint32, equals(200));
      expect(decoded.ext.discriminant, equals(0));
    });

    test('XdrTransactionHistoryEntry with V0 envelope encode/decode', () {
      var sourceAccount = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x11)));

      var memo = XdrMemo(XdrMemoType.MEMO_NONE);
      var operation = XdrOperation(XdrOperationBody(XdrOperationType.INFLATION));
      var txExt = XdrTransactionV0Ext(0);

      var timeBounds = XdrTimeBounds(
        XdrUint64(BigInt.from(1000000)),
        XdrUint64(BigInt.from(2000000)),
      );

      var transaction = XdrTransactionV0(
        sourceAccount,
        XdrUint32(100),
        XdrSequenceNumber(XdrBigInt64(BigInt.from(9999999))),
        timeBounds,
        memo,
        [operation],
        txExt,
      );

      var signature = XdrDecoratedSignature(
        XdrSignatureHint(Uint8List.fromList([5, 6, 7, 8])),
        XdrSignature(Uint8List.fromList(List<int>.filled(64, 0x77))),
      );

      var txV0Envelope = XdrTransactionV0Envelope(
        transaction,
        [signature],
      );

      var txEnvelope = XdrTransactionEnvelope(XdrEnvelopeType.ENVELOPE_TYPE_TX_V0);
      txEnvelope.v0 = txV0Envelope;

      var txSet = XdrTransactionSet(
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0x88))),
        [txEnvelope],
      );

      var ext = XdrTransactionHistoryEntryExt(0);

      var original = XdrTransactionHistoryEntry(
        XdrUint32(7000),
        txSet,
        ext,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionHistoryEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionHistoryEntry.decode(input);

      expect(decoded.ledgerSeq.uint32, equals(7000));
      expect(decoded.txSet.txEnvelopes.length, equals(1));
      expect(decoded.txSet.txEnvelopes[0].discriminant.value, equals(XdrEnvelopeType.ENVELOPE_TYPE_TX_V0.value));
      expect(decoded.txSet.txEnvelopes[0].v0!.tx.fee.uint32, equals(100));
      expect(decoded.ext.discriminant, equals(0));
    });

    test('XdrTransactionHistoryEntry with FeeBump envelope encode/decode', () {
      var sourceAccount = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      sourceAccount.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x22)));

      var preconditions = XdrPreconditions(XdrPreconditionType.NONE);
      var memo = XdrMemo(XdrMemoType.MEMO_NONE);
      var operation = XdrOperation(XdrOperationBody(XdrOperationType.INFLATION));
      var txExt = XdrTransactionExt(0);

      var innerTx = XdrTransaction(
        sourceAccount,
        XdrUint32(100),
        XdrSequenceNumber(XdrBigInt64(BigInt.from(8888888))),
        preconditions,
        memo,
        [operation],
        txExt,
      );

      var signature = XdrDecoratedSignature(
        XdrSignatureHint(Uint8List.fromList([9, 10, 11, 12])),
        XdrSignature(Uint8List.fromList(List<int>.filled(64, 0x88))),
      );

      var txV1Envelope = XdrTransactionV1Envelope(
        innerTx,
        [signature],
      );

      var innerTxEnvelope = XdrFeeBumpTransactionInnerTx(XdrEnvelopeType.ENVELOPE_TYPE_TX);
      innerTxEnvelope.v1 = txV1Envelope;

      var feeSource = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      feeSource.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x33)));

      var feeBumpTx = XdrFeeBumpTransaction(
        feeSource,
        XdrInt64(BigInt.from(500)),
        innerTxEnvelope,
        XdrFeeBumpTransactionExt(0),
      );

      var feeBumpEnvelope = XdrFeeBumpTransactionEnvelope(
        feeBumpTx,
        [signature],
      );

      var txEnvelope = XdrTransactionEnvelope(XdrEnvelopeType.ENVELOPE_TYPE_TX_FEE_BUMP);
      txEnvelope.feeBump = feeBumpEnvelope;

      var txSet = XdrTransactionSet(
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0x99))),
        [txEnvelope],
      );

      var ext = XdrTransactionHistoryEntryExt(0);

      var original = XdrTransactionHistoryEntry(
        XdrUint32(8000),
        txSet,
        ext,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionHistoryEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionHistoryEntry.decode(input);

      expect(decoded.ledgerSeq.uint32, equals(8000));
      expect(decoded.txSet.txEnvelopes.length, equals(1));
      expect(decoded.txSet.txEnvelopes[0].discriminant.value, equals(XdrEnvelopeType.ENVELOPE_TYPE_TX_FEE_BUMP.value));
      expect(decoded.txSet.txEnvelopes[0].feeBump!.tx.fee.int64, equals(BigInt.from(500)));
      expect(decoded.ext.discriminant, equals(0));
    });

    test('XdrSCPHistoryEntryV0 with nested quorum sets encode/decode', () {
      var innerQuorumSet = XdrSCPQuorumSet(
        XdrUint32(1),
        [],
        [],
      );

      var outerQuorumSet = XdrSCPQuorumSet(
        XdrUint32(2),
        [],
        [innerQuorumSet],
      );

      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAB))));
      var nodeID = XdrNodeID(pk);

      var nomination = XdrSCPNomination(
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0xCD))),
        [],
        [],
      );

      var pledges = XdrSCPStatementPledges(XdrSCPStatementType.SCP_ST_NOMINATE);
      pledges.nominate = nomination;

      var statement = XdrSCPStatement(
        nodeID,
        XdrUint64(BigInt.from(77777)),
        pledges,
      );

      var signature = XdrSignature(Uint8List.fromList(List<int>.filled(64, 0xEF)));
      var envelope = XdrSCPEnvelope(statement, signature);

      var ledgerMessages = XdrLedgerSCPMessages(
        XdrUint32(600),
        [envelope],
      );

      var original = XdrSCPHistoryEntryV0([outerQuorumSet], ledgerMessages);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCPHistoryEntryV0.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCPHistoryEntryV0.decode(input);

      expect(decoded.quorumSets.length, equals(1));
      expect(decoded.quorumSets[0].threshold.uint32, equals(2));
      expect(decoded.quorumSets[0].innerSets.length, equals(1));
      expect(decoded.quorumSets[0].innerSets[0].threshold.uint32, equals(1));
      expect(decoded.ledgerMessages.ledgerSeq.uint32, equals(600));
    });
  });
}
