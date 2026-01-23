// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('XDR Transaction Types - Third Round Deep Branch Testing', () {
    test('XdrTransactionMeta V0 with operation metadata entries encode/decode', () {
      var ledgerKey = XdrLedgerKey(XdrLedgerEntryType.ACCOUNT);
      ledgerKey.account = XdrLedgerKeyAccount(XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519)));
      ledgerKey.account!.accountID.accountID.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x11))));

      var ledgerEntry = XdrLedgerEntry(
        XdrUint32(0),
        XdrLedgerEntryData(XdrLedgerEntryType.ACCOUNT),
        XdrLedgerEntryExt(0),
      );

      var accountID = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      accountID.accountID.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x22))));

      var accountEntry = XdrAccountEntry(
        accountID,
        XdrInt64(BigInt.from(1000000)),
        XdrSequenceNumber(XdrBigInt64(BigInt.from(1))),
        XdrUint32(0),
        null,
        XdrUint32(0),
        XdrString32("home"),
        XdrThresholds(Uint8List.fromList([1, 1, 1, 1])),
        [],
        XdrAccountEntryExt(0),
      );
      ledgerEntry.data.account = accountEntry;

      var ledgerEntryChange = XdrLedgerEntryChange(XdrLedgerEntryChangeType.LEDGER_ENTRY_CREATED);
      ledgerEntryChange.created = ledgerEntry;

      var changes = XdrLedgerEntryChanges([ledgerEntryChange]);
      var opMeta = XdrOperationMeta(changes);

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
      expect(decoded.operations![0].changes.ledgerEntryChanges.length, equals(1));
    });

    test('XdrTransactionMetaV1 with transaction changes and operations encode/decode', () {
      var ledgerKey = XdrLedgerKey(XdrLedgerEntryType.ACCOUNT);
      ledgerKey.account = XdrLedgerKeyAccount(XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519)));
      ledgerKey.account!.accountID.accountID.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x33))));

      var ledgerEntry = XdrLedgerEntry(
        XdrUint32(0),
        XdrLedgerEntryData(XdrLedgerEntryType.ACCOUNT),
        XdrLedgerEntryExt(0),
      );

      var accountID2 = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      accountID2.accountID.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x44))));

      var accountEntry = XdrAccountEntry(
        accountID2,
        XdrInt64(BigInt.from(2000000)),
        XdrSequenceNumber(XdrBigInt64(BigInt.from(2))),
        XdrUint32(0),
        null,
        XdrUint32(0),
        XdrString32("home"),
        XdrThresholds(Uint8List.fromList([1, 1, 1, 1])),
        [],
        XdrAccountEntryExt(0),
      );
      ledgerEntry.data.account = accountEntry;

      var ledgerEntryChange = XdrLedgerEntryChange(XdrLedgerEntryChangeType.LEDGER_ENTRY_UPDATED);
      ledgerEntryChange.updated = ledgerEntry;

      var txChanges = XdrLedgerEntryChanges([ledgerEntryChange]);
      var opMeta = XdrOperationMeta(XdrLedgerEntryChanges([]));

      var original = XdrTransactionMetaV1(txChanges, [opMeta]);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionMetaV1.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionMetaV1.decode(input);

      expect(decoded.txChanges.ledgerEntryChanges.length, equals(1));
      expect(decoded.operations.length, equals(1));
    });

    test('XdrTransactionMetaV2 with before and after changes encode/decode', () {
      var ledgerEntry1 = XdrLedgerEntry(
        XdrUint32(0),
        XdrLedgerEntryData(XdrLedgerEntryType.ACCOUNT),
        XdrLedgerEntryExt(0),
      );

      var accountID3 = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      accountID3.accountID.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x55))));

      var accountEntry1 = XdrAccountEntry(
        accountID3,
        XdrInt64(BigInt.from(3000000)),
        XdrSequenceNumber(XdrBigInt64(BigInt.from(3))),
        XdrUint32(0),
        null,
        XdrUint32(0),
        XdrString32("home"),
        XdrThresholds(Uint8List.fromList([1, 1, 1, 1])),
        [],
        XdrAccountEntryExt(0),
      );
      ledgerEntry1.data.account = accountEntry1;

      var changeBefore = XdrLedgerEntryChange(XdrLedgerEntryChangeType.LEDGER_ENTRY_STATE);
      changeBefore.state = ledgerEntry1;

      var ledgerEntry2 = XdrLedgerEntry(
        XdrUint32(0),
        XdrLedgerEntryData(XdrLedgerEntryType.ACCOUNT),
        XdrLedgerEntryExt(0),
      );

      var accountID4 = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      accountID4.accountID.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x66))));

      var accountEntry2 = XdrAccountEntry(
        accountID4,
        XdrInt64(BigInt.from(3500000)),
        XdrSequenceNumber(XdrBigInt64(BigInt.from(4))),
        XdrUint32(0),
        null,
        XdrUint32(0),
        XdrString32("home"),
        XdrThresholds(Uint8List.fromList([1, 1, 1, 1])),
        [],
        XdrAccountEntryExt(0),
      );
      ledgerEntry2.data.account = accountEntry2;

      var changeAfter = XdrLedgerEntryChange(XdrLedgerEntryChangeType.LEDGER_ENTRY_UPDATED);
      changeAfter.updated = ledgerEntry2;

      var txChangesBefore = XdrLedgerEntryChanges([changeBefore]);
      var txChangesAfter = XdrLedgerEntryChanges([changeAfter]);
      var opMeta = XdrOperationMeta(XdrLedgerEntryChanges([]));

      var original = XdrTransactionMetaV2(txChangesBefore, [opMeta], txChangesAfter);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionMetaV2.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionMetaV2.decode(input);

      expect(decoded.txChangesBefore.ledgerEntryChanges.length, equals(1));
      expect(decoded.txChangesAfter.ledgerEntryChanges.length, equals(1));
      expect(decoded.operations.length, equals(1));
    });

    test('XdrTransactionMetaV3 with diagnostic events encode/decode', () {
      var ext = XdrExtensionPoint(0);
      var txChangesBefore = XdrLedgerEntryChanges([]);
      var txChangesAfter = XdrLedgerEntryChanges([]);

      var contractEventExt = XdrExtensionPoint(0);
      var scVal = XdrSCVal(XdrSCValType.SCV_U32);
      scVal.u32 = XdrUint32(123);

      var bodyV0 = XdrContractEventBodyV0([], scVal);
      var body = XdrContractEventBody(0);
      body.v0 = bodyV0;

      var contractEvent = XdrContractEvent(
        contractEventExt,
        null,
        XdrContractEventType.CONTRACT_EVENT_TYPE_DIAGNOSTIC,
        body,
      );

      var diagnosticEvent = XdrDiagnosticEvent(false, contractEvent);

      var sorobanMetaExt = XdrSorobanTransactionMetaExt(0);
      var returnValue = XdrSCVal(XdrSCValType.SCV_I32);
      returnValue.i32 = XdrInt32(-42);

      var sorobanMeta = XdrSorobanTransactionMeta(sorobanMetaExt, [], returnValue, [diagnosticEvent]);

      var original = XdrTransactionMetaV3(ext, txChangesBefore, [], txChangesAfter, sorobanMeta);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionMetaV3.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionMetaV3.decode(input);

      expect(decoded.sorobanMeta, isNotNull);
      expect(decoded.sorobanMeta!.diagnosticEvents.length, equals(1));
      expect(decoded.sorobanMeta!.diagnosticEvents[0].inSuccessfulContractCall, equals(false));
    });

    test('XdrSorobanTransactionMeta with multiple events encode/decode', () {
      var ext = XdrSorobanTransactionMetaExt(0);

      var contractEventExt1 = XdrExtensionPoint(0);
      var scVal1 = XdrSCVal(XdrSCValType.SCV_STRING);
      scVal1.str = "test";

      var bodyV01 = XdrContractEventBodyV0([], scVal1);
      var body1 = XdrContractEventBody(0);
      body1.v0 = bodyV01;

      var contractEvent1 = XdrContractEvent(
        contractEventExt1,
        null,
        XdrContractEventType.CONTRACT_EVENT_TYPE_SYSTEM,
        body1,
      );

      var diagnosticEvent1 = XdrDiagnosticEvent(true, contractEvent1);

      var contractEventExt2 = XdrExtensionPoint(0);
      var scVal2 = XdrSCVal(XdrSCValType.SCV_BOOL);
      scVal2.b = true;

      var bodyV02 = XdrContractEventBodyV0([], scVal2);
      var body2 = XdrContractEventBody(0);
      body2.v0 = bodyV02;

      var contractEvent2 = XdrContractEvent(
        contractEventExt2,
        null,
        XdrContractEventType.CONTRACT_EVENT_TYPE_CONTRACT,
        body2,
      );

      var diagnosticEvent2 = XdrDiagnosticEvent(true, contractEvent2);

      var returnValue = XdrSCVal(XdrSCValType.SCV_VOID);

      var original = XdrSorobanTransactionMeta(ext, [], returnValue, [diagnosticEvent1, diagnosticEvent2]);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSorobanTransactionMeta.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSorobanTransactionMeta.decode(input);

      expect(decoded.diagnosticEvents.length, equals(2));
      expect(decoded.returnValue.discriminant.value, equals(XdrSCValType.SCV_VOID.value));
    });

    test('XdrInnerTransactionResultResult with txINTERNAL_ERROR encode/decode', () {
      var original = XdrInnerTransactionResultResult(XdrTransactionResultCode.txINTERNAL_ERROR, null);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrInnerTransactionResultResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrInnerTransactionResultResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrTransactionResultCode.txINTERNAL_ERROR.value));
      expect(decoded.results, isNull);
    });

    test('XdrInnerTransactionResultResult with txBAD_SPONSORSHIP encode/decode', () {
      var original = XdrInnerTransactionResultResult(XdrTransactionResultCode.txBAD_SPONSORSHIP, null);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrInnerTransactionResultResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrInnerTransactionResultResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrTransactionResultCode.txBAD_SPONSORSHIP.value));
      expect(decoded.results, isNull);
    });

    test('XdrTransactionResultResult with txNO_ACCOUNT encode/decode', () {
      var original = XdrTransactionResultResult(XdrTransactionResultCode.txNO_ACCOUNT, null, null);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionResultResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionResultResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrTransactionResultCode.txNO_ACCOUNT.value));
    });

    test('XdrTransactionResultResult with txINSUFFICIENT_FEE encode/decode', () {
      var original = XdrTransactionResultResult(XdrTransactionResultCode.txINSUFFICIENT_FEE, null, null);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionResultResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionResultResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrTransactionResultCode.txINSUFFICIENT_FEE.value));
    });

    test('XdrTransactionResultResult with txBAD_AUTH_EXTRA encode/decode', () {
      var original = XdrTransactionResultResult(XdrTransactionResultCode.txBAD_AUTH_EXTRA, null, null);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionResultResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionResultResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrTransactionResultCode.txBAD_AUTH_EXTRA.value));
    });

    test('XdrTransactionResultResult with txINTERNAL_ERROR encode/decode', () {
      var original = XdrTransactionResultResult(XdrTransactionResultCode.txINTERNAL_ERROR, null, null);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionResultResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionResultResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrTransactionResultCode.txINTERNAL_ERROR.value));
    });

    test('XdrTransactionResultResult with txBAD_SPONSORSHIP encode/decode', () {
      var original = XdrTransactionResultResult(XdrTransactionResultCode.txBAD_SPONSORSHIP, null, null);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionResultResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionResultResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrTransactionResultCode.txBAD_SPONSORSHIP.value));
    });

    test('XdrInnerTransactionResultResult with txNO_ACCOUNT encode/decode', () {
      var original = XdrInnerTransactionResultResult(XdrTransactionResultCode.txNO_ACCOUNT, null);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrInnerTransactionResultResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrInnerTransactionResultResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrTransactionResultCode.txNO_ACCOUNT.value));
      expect(decoded.results, isNull);
    });

    test('XdrInnerTransactionResultResult with txINSUFFICIENT_BALANCE encode/decode', () {
      var original = XdrInnerTransactionResultResult(XdrTransactionResultCode.txINSUFFICIENT_BALANCE, null);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrInnerTransactionResultResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrInnerTransactionResultResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrTransactionResultCode.txINSUFFICIENT_BALANCE.value));
    });

    test('XdrInnerTransactionResultResult with txSOROBAN_INVALID encode/decode', () {
      var original = XdrInnerTransactionResultResult(XdrTransactionResultCode.txSOROBAN_INVALID, null);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrInnerTransactionResultResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrInnerTransactionResultResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrTransactionResultCode.txSOROBAN_INVALID.value));
    });

    test('XdrLedgerEntryChange LEDGER_ENTRY_REMOVED encode/decode', () {
      var ledgerKey = XdrLedgerKey(XdrLedgerEntryType.ACCOUNT);
      ledgerKey.account = XdrLedgerKeyAccount(XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519)));
      ledgerKey.account!.accountID.accountID.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x77))));

      var original = XdrLedgerEntryChange(XdrLedgerEntryChangeType.LEDGER_ENTRY_REMOVED);
      original.removed = ledgerKey;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerEntryChange.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerEntryChange.decode(input);

      expect(decoded.discriminant.value, equals(XdrLedgerEntryChangeType.LEDGER_ENTRY_REMOVED.value));
      expect(decoded.removed, isNotNull);
    });

    test('XdrOperationMeta with multiple ledger entry changes encode/decode', () {
      var ledgerEntry1 = XdrLedgerEntry(
        XdrUint32(0),
        XdrLedgerEntryData(XdrLedgerEntryType.ACCOUNT),
        XdrLedgerEntryExt(0),
      );

      var accountID5 = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      accountID5.accountID.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x88))));

      var accountEntry1 = XdrAccountEntry(
        accountID5,
        XdrInt64(BigInt.from(5000000)),
        XdrSequenceNumber(XdrBigInt64(BigInt.from(10))),
        XdrUint32(0),
        null,
        XdrUint32(0),
        XdrString32("home"),
        XdrThresholds(Uint8List.fromList([1, 1, 1, 1])),
        [],
        XdrAccountEntryExt(0),
      );
      ledgerEntry1.data.account = accountEntry1;

      var change1 = XdrLedgerEntryChange(XdrLedgerEntryChangeType.LEDGER_ENTRY_CREATED);
      change1.created = ledgerEntry1;

      var ledgerKey = XdrLedgerKey(XdrLedgerEntryType.ACCOUNT);
      ledgerKey.account = XdrLedgerKeyAccount(XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519)));
      ledgerKey.account!.accountID.accountID.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x99))));

      var change2 = XdrLedgerEntryChange(XdrLedgerEntryChangeType.LEDGER_ENTRY_REMOVED);
      change2.removed = ledgerKey;

      var changes = XdrLedgerEntryChanges([change1, change2]);
      var original = XdrOperationMeta(changes);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationMeta.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationMeta.decode(input);

      expect(decoded.changes.ledgerEntryChanges.length, equals(2));
    });

    test('XdrPreconditionsV2 with null timeBounds encode/decode', () {
      var ledgerBounds = XdrLedgerBounds(
        XdrUint32(500),
        XdrUint32(1000),
      );

      var original = XdrPreconditionsV2(
        XdrUint64(BigInt.from(1800)),
        XdrUint32(3),
        [],
      );
      original.timeBounds = null;
      original.ledgerBounds = ledgerBounds;
      original.sequenceNumber = XdrBigInt64(BigInt.from(999999));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrPreconditionsV2.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrPreconditionsV2.decode(input);

      expect(decoded.timeBounds, isNull);
      expect(decoded.ledgerBounds, isNotNull);
      expect(decoded.ledgerBounds!.minLedger.uint32, equals(500));
      expect(decoded.sequenceNumber, isNotNull);
      expect(decoded.sequenceNumber!.bigInt, equals(BigInt.from(999999)));
    });

    test('XdrPreconditionsV2 with null ledgerBounds encode/decode', () {
      var timeBounds = XdrTimeBounds(
        XdrUint64(BigInt.from(3000000)),
        XdrUint64(BigInt.from(4000000)),
      );

      var original = XdrPreconditionsV2(
        XdrUint64(BigInt.from(2400)),
        XdrUint32(5),
        [],
      );
      original.timeBounds = timeBounds;
      original.ledgerBounds = null;
      original.sequenceNumber = null;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrPreconditionsV2.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrPreconditionsV2.decode(input);

      expect(decoded.timeBounds, isNotNull);
      expect(decoded.timeBounds!.minTime.uint64, equals(BigInt.from(3000000)));
      expect(decoded.ledgerBounds, isNull);
      expect(decoded.sequenceNumber, isNull);
    });

    test('XdrPreconditionsV2 with multiple extraSigners encode/decode', () {
      var signerKey1 = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519);
      signerKey1.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAA)));

      var signerKey2 = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_PRE_AUTH_TX);
      signerKey2.preAuthTx = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xBB)));

      var signerKey3 = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_HASH_X);
      signerKey3.hashX = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xCC)));

      var original = XdrPreconditionsV2(
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

    test('XdrTransactionSignaturePayloadTaggedTransaction ENVELOPE_TYPE_TX encode/decode', () {
      var sourceAccount = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      sourceAccount.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xDD)));

      var preconditions = XdrPreconditions(XdrPreconditionType.NONE);
      var memo = XdrMemo(XdrMemoType.MEMO_NONE);
      var operation = XdrOperation(XdrOperationBody(XdrOperationType.INFLATION));
      var ext = XdrTransactionExt(0);

      var tx = XdrTransaction(
        sourceAccount,
        XdrUint32(100),
        XdrSequenceNumber(XdrBigInt64(BigInt.from(12345))),
        preconditions,
        memo,
        [operation],
        ext,
      );

      var original = XdrTransactionSignaturePayloadTaggedTransaction(XdrEnvelopeType.ENVELOPE_TYPE_TX);
      original.tx = tx;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionSignaturePayloadTaggedTransaction.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionSignaturePayloadTaggedTransaction.decode(input);

      expect(decoded.discriminant.value, equals(XdrEnvelopeType.ENVELOPE_TYPE_TX.value));
      expect(decoded.tx, isNotNull);
      expect(decoded.tx!.fee.uint32, equals(100));
    });

    test('XdrFeeBumpTransactionInnerTx ENVELOPE_TYPE_TX encode/decode', () {
      var sourceAccount = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      sourceAccount.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xEE)));

      var preconditions = XdrPreconditions(XdrPreconditionType.NONE);
      var memo = XdrMemo(XdrMemoType.MEMO_NONE);
      var operation = XdrOperation(XdrOperationBody(XdrOperationType.INFLATION));
      var ext = XdrTransactionExt(0);

      var tx = XdrTransaction(
        sourceAccount,
        XdrUint32(200),
        XdrSequenceNumber(XdrBigInt64(BigInt.from(54321))),
        preconditions,
        memo,
        [operation],
        ext,
      );

      var envelope = XdrTransactionV1Envelope(tx, []);

      var original = XdrFeeBumpTransactionInnerTx(XdrEnvelopeType.ENVELOPE_TYPE_TX);
      original.v1 = envelope;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrFeeBumpTransactionInnerTx.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrFeeBumpTransactionInnerTx.decode(input);

      expect(decoded.discriminant.value, equals(XdrEnvelopeType.ENVELOPE_TYPE_TX.value));
      expect(decoded.v1, isNotNull);
      expect(decoded.v1!.tx.fee.uint32, equals(200));
    });

    test('XdrContractEventBody discriminant 0 encode/decode', () {
      var scVal = XdrSCVal(XdrSCValType.SCV_U64);
      scVal.u64 = XdrUint64(BigInt.from(9876543210));

      var bodyV0 = XdrContractEventBodyV0([], scVal);

      var original = XdrContractEventBody(0);
      original.v0 = bodyV0;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrContractEventBody.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrContractEventBody.decode(input);

      expect(decoded.discriminant, equals(0));
      expect(decoded.v0, isNotNull);
      expect(decoded.v0!.data.u64!.uint64, equals(BigInt.from(9876543210)));
    });

    test('XdrContractEventBodyV0 with topics encode/decode', () {
      var topic1 = XdrSCVal(XdrSCValType.SCV_BOOL);
      topic1.b = true;

      var topic2 = XdrSCVal(XdrSCValType.SCV_U32);
      topic2.u32 = XdrUint32(456);

      var data = XdrSCVal(XdrSCValType.SCV_STRING);
      data.str = "data";

      var original = XdrContractEventBodyV0([topic1, topic2], data);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrContractEventBodyV0.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrContractEventBodyV0.decode(input);

      expect(decoded.topics.length, equals(2));
      expect(decoded.topics[0].b, equals(true));
      expect(decoded.topics[1].u32!.uint32, equals(456));
      expect(decoded.data.str, equals("data"));
    });

    test('XdrTransactionEvent TRANSACTION_EVENT_STAGE_BEFORE_ALL_TXS encode/decode', () {
      var ext = XdrExtensionPoint(0);
      var scVal = XdrSCVal(XdrSCValType.SCV_I64);
      scVal.i64 = XdrInt64(BigInt.from(-999999));

      var bodyV0 = XdrContractEventBodyV0([], scVal);
      var body = XdrContractEventBody(0);
      body.v0 = bodyV0;

      var contractEvent = XdrContractEvent(ext, null, XdrContractEventType.CONTRACT_EVENT_TYPE_SYSTEM, body);

      var original = XdrTransactionEvent(XdrTransactionEventStage.TRANSACTION_EVENT_STAGE_BEFORE_ALL_TXS, contractEvent);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionEvent.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionEvent.decode(input);

      expect(decoded.stage.value, equals(XdrTransactionEventStage.TRANSACTION_EVENT_STAGE_BEFORE_ALL_TXS.value));
    });

    test('XdrTransactionEvent TRANSACTION_EVENT_STAGE_AFTER_ALL_TXS encode/decode', () {
      var ext = XdrExtensionPoint(0);
      var scVal = XdrSCVal(XdrSCValType.SCV_BYTES);
      scVal.bytes = XdrDataValue(Uint8List.fromList([1, 2, 3, 4]));

      var bodyV0 = XdrContractEventBodyV0([], scVal);
      var body = XdrContractEventBody(0);
      body.v0 = bodyV0;

      var contractEvent = XdrContractEvent(ext, null, XdrContractEventType.CONTRACT_EVENT_TYPE_CONTRACT, body);

      var original = XdrTransactionEvent(XdrTransactionEventStage.TRANSACTION_EVENT_STAGE_AFTER_ALL_TXS, contractEvent);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionEvent.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionEvent.decode(input);

      expect(decoded.stage.value, equals(XdrTransactionEventStage.TRANSACTION_EVENT_STAGE_AFTER_ALL_TXS.value));
    });

    test('XdrTransactionMetaV4 with transaction events encode/decode', () {
      var ext = XdrExtensionPoint(0);
      var txChangesBefore = XdrLedgerEntryChanges([]);
      var txChangesAfter = XdrLedgerEntryChanges([]);

      var sorobanMetaExt = XdrSorobanTransactionMetaExt(0);
      var sorobanMeta = XdrSorobanTransactionMetaV2(sorobanMetaExt, null);

      var eventExt = XdrExtensionPoint(0);
      var scVal = XdrSCVal(XdrSCValType.SCV_SYMBOL);
      scVal.sym = "test";

      var bodyV0 = XdrContractEventBodyV0([], scVal);
      var body = XdrContractEventBody(0);
      body.v0 = bodyV0;

      var contractEvent = XdrContractEvent(eventExt, null, XdrContractEventType.CONTRACT_EVENT_TYPE_SYSTEM, body);
      var txEvent = XdrTransactionEvent(XdrTransactionEventStage.TRANSACTION_EVENT_STAGE_AFTER_TX, contractEvent);

      var original = XdrTransactionMetaV4(ext, txChangesBefore, [], txChangesAfter, sorobanMeta, [txEvent], []);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionMetaV4.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionMetaV4.decode(input);

      expect(decoded.events.length, equals(1));
      expect(decoded.events[0].stage.value, equals(XdrTransactionEventStage.TRANSACTION_EVENT_STAGE_AFTER_TX.value));
    });

    test('XdrSorobanTransactionMetaExtV1 encode/decode', () {
      var ext = XdrExtensionPoint(0);

      var original = XdrSorobanTransactionMetaExtV1(
        ext,
        XdrInt64(BigInt.from(5000)),
        XdrInt64(BigInt.from(2500)),
        XdrInt64(BigInt.from(750)),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSorobanTransactionMetaExtV1.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSorobanTransactionMetaExtV1.decode(input);

      expect(decoded.totalNonRefundableResourceFeeCharged.int64, equals(BigInt.from(5000)));
      expect(decoded.totalRefundableResourceFeeCharged.int64, equals(BigInt.from(2500)));
      expect(decoded.rentFeeCharged.int64, equals(BigInt.from(750)));
    });

    test('XdrTransactionResultExt discriminant 0 encode/decode', () {
      var original = XdrTransactionResultExt(0);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionResultExt.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionResultExt.decode(input);

      expect(decoded.discriminant, equals(0));
    });

    test('XdrTransaction with multiple operations encode/decode', () {
      var sourceAccount = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      sourceAccount.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xFF)));

      var preconditions = XdrPreconditions(XdrPreconditionType.NONE);
      var memo = XdrMemo(XdrMemoType.MEMO_NONE);

      var operation1 = XdrOperation(XdrOperationBody(XdrOperationType.INFLATION));
      var operation2 = XdrOperation(XdrOperationBody(XdrOperationType.INFLATION));
      var operation3 = XdrOperation(XdrOperationBody(XdrOperationType.INFLATION));

      var ext = XdrTransactionExt(0);

      var original = XdrTransaction(
        sourceAccount,
        XdrUint32(300),
        XdrSequenceNumber(XdrBigInt64(BigInt.from(111111))),
        preconditions,
        memo,
        [operation1, operation2, operation3],
        ext,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransaction.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransaction.decode(input);

      expect(decoded.operations.length, equals(3));
      expect(decoded.fee.uint32, equals(300));
    });

    test('XdrTransactionV0 with multiple operations encode/decode', () {
      var sourceAccountEd25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAB)));
      var timeBounds = XdrTimeBounds(
        XdrUint64(BigInt.from(500000)),
        XdrUint64(BigInt.from(600000)),
      );
      var memo = XdrMemo(XdrMemoType.MEMO_NONE);

      var operation1 = XdrOperation(XdrOperationBody(XdrOperationType.INFLATION));
      var operation2 = XdrOperation(XdrOperationBody(XdrOperationType.INFLATION));

      var ext = XdrTransactionV0Ext(0);

      var original = XdrTransactionV0(
        sourceAccountEd25519,
        XdrUint32(250),
        XdrSequenceNumber(XdrBigInt64(BigInt.from(222222))),
        timeBounds,
        memo,
        [operation1, operation2],
        ext,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionV0.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionV0.decode(input);

      expect(decoded.operations.length, equals(2));
      expect(decoded.fee.uint32, equals(250));
      expect(decoded.timeBounds, isNotNull);
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

      expect(decoded.txEnvelopes.length, equals(0));
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

    test('XdrSorobanTransactionMeta with events encode/decode', () {
      var ext = XdrSorobanTransactionMetaExt(0);

      var eventExt = XdrExtensionPoint(0);
      var hash = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xDE)));
      var scVal = XdrSCVal(XdrSCValType.SCV_VOID);

      var bodyV0 = XdrContractEventBodyV0([], scVal);
      var body = XdrContractEventBody(0);
      body.v0 = bodyV0;

      var contractEvent = XdrContractEvent(eventExt, hash, XdrContractEventType.CONTRACT_EVENT_TYPE_CONTRACT, body);

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

    test('XdrDiagnosticEvent inSuccessfulContractCall false encode/decode', () {
      var ext = XdrExtensionPoint(0);
      var scVal = XdrSCVal(XdrSCValType.SCV_U32);
      scVal.u32 = XdrUint32(777);

      var bodyV0 = XdrContractEventBodyV0([], scVal);
      var body = XdrContractEventBody(0);
      body.v0 = bodyV0;

      var contractEvent = XdrContractEvent(ext, null, XdrContractEventType.CONTRACT_EVENT_TYPE_DIAGNOSTIC, body);

      var original = XdrDiagnosticEvent(false, contractEvent);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrDiagnosticEvent.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrDiagnosticEvent.decode(input);

      expect(decoded.inSuccessfulContractCall, equals(false));
      expect(decoded.event.type.value, equals(XdrContractEventType.CONTRACT_EVENT_TYPE_DIAGNOSTIC.value));
    });

    test('XdrHashIDPreimage ENVELOPE_TYPE_AUTH encode/decode', () {
      var original = XdrHashIDPreimage(XdrEnvelopeType.ENVELOPE_TYPE_AUTH);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrHashIDPreimage.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrHashIDPreimage.decode(input);

      expect(decoded.discriminant.value, equals(XdrEnvelopeType.ENVELOPE_TYPE_AUTH.value));
    });

    test('XdrHashIDPreimage ENVELOPE_TYPE_SCPVALUE encode/decode', () {
      var original = XdrHashIDPreimage(XdrEnvelopeType.ENVELOPE_TYPE_SCPVALUE);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrHashIDPreimage.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrHashIDPreimage.decode(input);

      expect(decoded.discriminant.value, equals(XdrEnvelopeType.ENVELOPE_TYPE_SCPVALUE.value));
    });

    test('XdrHashIDPreimage ENVELOPE_TYPE_TX_FEE_BUMP encode/decode', () {
      var original = XdrHashIDPreimage(XdrEnvelopeType.ENVELOPE_TYPE_TX_FEE_BUMP);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrHashIDPreimage.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrHashIDPreimage.decode(input);

      expect(decoded.discriminant.value, equals(XdrEnvelopeType.ENVELOPE_TYPE_TX_FEE_BUMP.value));
    });

    test('XdrTransactionMeta discriminant 4 with operations encode/decode', () {
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
