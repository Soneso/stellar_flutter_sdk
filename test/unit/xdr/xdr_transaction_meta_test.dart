// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('XDR Transaction Meta - Edge Cases & Complex Constructions', () {
    test('XdrPreconditionsV2 with null timeBounds encode/decode', () {
      var ledgerBounds = XdrLedgerBounds(
        XdrUint32(500),
        XdrUint32(1000),
      );

      var original = XdrPreconditionsV2(
        null,
        ledgerBounds,
        XdrSequenceNumber(BigInt.from(999999)),
        XdrUint64(BigInt.from(1800)),
        XdrUint32(3),
        [],
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrPreconditionsV2.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrPreconditionsV2.decode(input);

      expect(decoded.timeBounds, isNull);
      expect(decoded.ledgerBounds, isNotNull);
      expect(decoded.ledgerBounds!.minLedger.uint32, equals(500));
      expect(decoded.minSeqNum, isNotNull);
      expect(decoded.minSeqNum!.sequenceNumber, equals(BigInt.from(999999)));
    });

    test('XdrPreconditionsV2 with null ledgerBounds encode/decode', () {
      var timeBounds = XdrTimeBounds(
        XdrUint64(BigInt.from(3000000)),
        XdrUint64(BigInt.from(4000000)),
      );

      var original = XdrPreconditionsV2(
        timeBounds,
        null,
        null,
        XdrUint64(BigInt.from(2400)),
        XdrUint32(5),
        [],
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrPreconditionsV2.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrPreconditionsV2.decode(input);

      expect(decoded.timeBounds, isNotNull);
      expect(decoded.timeBounds!.minTime.uint64, equals(BigInt.from(3000000)));
      expect(decoded.ledgerBounds, isNull);
      expect(decoded.minSeqNum, isNull);
    });

    test('XdrPreconditionsV2 with multiple extraSigners of different types', () {
      var signerKey1 = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519);
      signerKey1.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAA)));

      var signerKey2 = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_PRE_AUTH_TX);
      signerKey2.preAuthTx = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xBB)));

      var signerKey3 = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_HASH_X);
      signerKey3.hashX = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xCC)));

      var original = XdrPreconditionsV2(
        null,
        null,
        null,
        XdrUint64(BigInt.from(3600)),
        XdrUint32(10),
        [signerKey1, signerKey2, signerKey3],
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrPreconditionsV2.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrPreconditionsV2.decode(input);

      expect(decoded.extraSigners.length, equals(3));
      expect(decoded.minSeqAge.uint64, equals(BigInt.from(3600)));
      expect(decoded.minSeqLedgerGap.uint32, equals(10));
    });

    test('XdrTransactionResultSet empty results encode/decode', () {
      var original = XdrTransactionResultSet([]);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionResultSet.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionResultSet.decode(input);

      expect(decoded.results.length, equals(0));
    });

    test('XdrTransactionSet empty envelopes encode/decode', () {
      var hash = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xCD)));

      var original = XdrTransactionSet(hash, []);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionSet.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionSet.decode(input);

      expect(decoded.txs.length, equals(0));
      expect(decoded.previousLedgerHash.hash.length, equals(32));
    });

    test('XdrSorobanResourcesExtV0 empty array encode/decode', () {
      var original = XdrSorobanResourcesExtV0([]);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSorobanResourcesExtV0.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSorobanResourcesExtV0.decode(input);

      expect(decoded.archivedSorobanEntries.length, equals(0));
    });

    test('XdrSorobanTransactionMeta with events including hash', () {
      var ext = XdrSorobanTransactionMetaExt(0);

      var eventExt = XdrExtensionPoint(0);
      var hash = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xDE)));
      var scVal = XdrSCVal(XdrSCValType.SCV_VOID);

      var bodyV0 = XdrContractEventV0([], scVal);
      var body = XdrContractEventBody(0);
      body.v0 = bodyV0;

      var contractEvent = XdrContractEvent(eventExt, hash, XdrContractEventType.CONTRACT, body);

      var returnValue = XdrSCVal(XdrSCValType.SCV_BOOL);
      returnValue.b = false;

      var original = XdrSorobanTransactionMeta(ext, [contractEvent], returnValue, []);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSorobanTransactionMeta.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSorobanTransactionMeta.decode(input);

      expect(decoded.events.length, equals(1));
      expect(decoded.events[0].hash, isNotNull);
      expect(decoded.returnValue.discriminant.value, equals(XdrSCValType.SCV_BOOL.value));
      expect(decoded.returnValue.b, equals(false));
    });

    test('XdrDiagnosticEvent inSuccessfulContractCall false', () {
      var ext = XdrExtensionPoint(0);
      var scVal = XdrSCVal(XdrSCValType.SCV_U32);
      scVal.u32 = XdrUint32(777);

      var bodyV0 = XdrContractEventV0([], scVal);
      var body = XdrContractEventBody(0);
      body.v0 = bodyV0;

      var contractEvent = XdrContractEvent(ext, null, XdrContractEventType.DIAGNOSTIC, body);

      var original = XdrDiagnosticEvent(false, contractEvent);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrDiagnosticEvent.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrDiagnosticEvent.decode(input);

      expect(decoded.inSuccessfulContractCall, equals(false));
      expect(decoded.event.type.value, equals(XdrContractEventType.DIAGNOSTIC.value));
    });

    test('XdrTransactionMeta discriminant 4 with V2 operation meta', () {
      var ext = XdrExtensionPoint(0);
      var txChangesBefore = XdrLedgerEntryChanges([]);
      var txChangesAfter = XdrLedgerEntryChanges([]);

      var opExt = XdrExtensionPoint(0);
      var opMeta1 = XdrOperationMetaV2(opExt, XdrLedgerEntryChanges([]), []);
      var opMeta2 = XdrOperationMetaV2(opExt, XdrLedgerEntryChanges([]), []);

      var sorobanMetaExt = XdrSorobanTransactionMetaExt(0);
      var sorobanMeta = XdrSorobanTransactionMetaV2(sorobanMetaExt, null);

      var v4 = XdrTransactionMetaV4(ext, txChangesBefore, [opMeta1, opMeta2], txChangesAfter, sorobanMeta, [], []);

      var original = XdrTransactionMeta(4);
      original.v4 = v4;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionMeta.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionMeta.decode(input);

      expect(decoded.discriminant, equals(4));
      expect(decoded.v4, isNotNull);
      expect(decoded.v4!.operations.length, equals(2));
    });
  });
}
