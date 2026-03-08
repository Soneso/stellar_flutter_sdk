// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('XDR History Types - Edge Cases & Complex Constructions', () {
    test('XdrSCPHistoryEntryV0 with empty quorumSets', () {
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

    test('XdrSCPHistoryEntryV0 with empty messages', () {
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

    test('XdrTransactionHistoryEntry with empty txSet', () {
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
      expect(decoded.txSet.txs, isEmpty);
      expect(decoded.ext.discriminant, equals(0));
    });

    test('XdrTransactionHistoryResultEntry with empty results', () {
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

    test('XdrTransactionHistoryEntry with FeeBump envelope', () {
      var sourceAccount = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      sourceAccount.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x22)));

      var preconditions = XdrPreconditions(XdrPreconditionType.PRECOND_NONE);
      var memo = XdrMemo(XdrMemoType.MEMO_NONE);
      var operation = XdrOperation(null, XdrOperationBody(XdrOperationType.INFLATION));
      var txExt = XdrTransactionExt(0);

      var innerTx = XdrTransaction(
        sourceAccount,
        XdrUint32(100),
        XdrSequenceNumber(BigInt.from(8888888)),
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
      expect(decoded.txSet.txs.length, equals(1));
      expect(decoded.txSet.txs[0].discriminant.value, equals(XdrEnvelopeType.ENVELOPE_TYPE_TX_FEE_BUMP.value));
      expect(decoded.txSet.txs[0].feeBump!.tx.fee.int64, equals(BigInt.from(500)));
      expect(decoded.ext.discriminant, equals(0));
    });

    test('XdrSCPHistoryEntryV0 with nested quorum sets', () {
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
