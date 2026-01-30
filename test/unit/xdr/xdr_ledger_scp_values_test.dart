// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('XDR Ledger Types - Deep Branch Testing Round 3', () {
    test('XdrLedgerSCPMessages with empty messages encode/decode', () {
      var original = XdrLedgerSCPMessages(
        XdrUint32(100),
        [],
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerSCPMessages.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerSCPMessages.decode(input);

      expect(decoded.ledgerSeq.uint32, equals(100));
      expect(decoded.messages.length, equals(0));
    });

    test('XdrLedgerSCPMessages with single message encode/decode', () {
      var publicKey = XdrPublicKey.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var nodeId = XdrNodeID(publicKey);
      var slotIndex = XdrUint64(BigInt.from(1000));

      var nomination = XdrSCPNomination(
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0x11))),
        [],
        [],
      );

      var statement = XdrSCPStatement(nodeId, slotIndex, XdrSCPStatementPledges(XdrSCPStatementType.SCP_ST_NOMINATE));
      statement.pledges.nominate = nomination;

      var envelope = XdrSCPEnvelope(statement, XdrSignature(Uint8List.fromList(List<int>.filled(64, 0x22))));

      var original = XdrLedgerSCPMessages(
        XdrUint32(200),
        [envelope],
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerSCPMessages.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerSCPMessages.decode(input);

      expect(decoded.ledgerSeq.uint32, equals(200));
      expect(decoded.messages.length, equals(1));
    });

    test('XdrLedgerSCPMessages with multiple messages encode/decode', () {
      var publicKey = XdrPublicKey.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var nodeId = XdrNodeID(publicKey);

      var nomination1 = XdrSCPNomination(
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0x33))),
        [],
        [],
      );
      var statement1 = XdrSCPStatement(nodeId, XdrUint64(BigInt.from(1000)), XdrSCPStatementPledges(XdrSCPStatementType.SCP_ST_NOMINATE));
      statement1.pledges.nominate = nomination1;
      var envelope1 = XdrSCPEnvelope(statement1, XdrSignature(Uint8List.fromList(List<int>.filled(64, 0x44))));

      var nomination2 = XdrSCPNomination(
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0x55))),
        [],
        [],
      );
      var statement2 = XdrSCPStatement(nodeId, XdrUint64(BigInt.from(2000)), XdrSCPStatementPledges(XdrSCPStatementType.SCP_ST_NOMINATE));
      statement2.pledges.nominate = nomination2;
      var envelope2 = XdrSCPEnvelope(statement2, XdrSignature(Uint8List.fromList(List<int>.filled(64, 0x66))));

      var original = XdrLedgerSCPMessages(
        XdrUint32(300),
        [envelope1, envelope2],
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerSCPMessages.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerSCPMessages.decode(input);

      expect(decoded.ledgerSeq.uint32, equals(300));
      expect(decoded.messages.length, equals(2));
    });

    test('XdrInvokeHostFunctionSuccessPreImage with empty events encode/decode', () {
      var returnValue = XdrSCVal.forU32(12345);

      var original = XdrInvokeHostFunctionSuccessPreImage(
        returnValue,
        [],
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrInvokeHostFunctionSuccessPreImage.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrInvokeHostFunctionSuccessPreImage.decode(input);

      expect(decoded.returnValue.u32!.uint32, equals(12345));
      expect(decoded.events.length, equals(0));
    });

    test('XdrInvokeHostFunctionSuccessPreImage with single event encode/decode', () {
      var returnValue = XdrSCVal.forI32(-9999);

      var topics = [XdrSCVal.forU32(111)];
      var data = XdrSCVal.forBytes(Uint8List.fromList([1, 2, 3, 4]));

      var eventBody = XdrContractEventBody(0);
      eventBody.v0 = XdrContractEventBodyV0(topics, data);

      var event = XdrContractEvent(
        XdrExtensionPoint(0),
        null,
        XdrContractEventType.CONTRACT_EVENT_TYPE_CONTRACT,
        eventBody,
      );

      var original = XdrInvokeHostFunctionSuccessPreImage(
        returnValue,
        [event],
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrInvokeHostFunctionSuccessPreImage.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrInvokeHostFunctionSuccessPreImage.decode(input);

      expect(decoded.returnValue.i32!.int32, equals(-9999));
      expect(decoded.events.length, equals(1));
    });

    test('XdrInvokeHostFunctionSuccessPreImage with multiple events encode/decode', () {
      var returnValue = XdrSCVal.forU64(BigInt.from(999999));

      var topics1 = [XdrSCVal.forU32(100), XdrSCVal.forU32(200)];
      var data1 = XdrSCVal.forString('test');
      var eventBody1 = XdrContractEventBody(0);
      eventBody1.v0 = XdrContractEventBodyV0(topics1, data1);
      var event1 = XdrContractEvent(
        XdrExtensionPoint(0),
        null,
        XdrContractEventType.CONTRACT_EVENT_TYPE_CONTRACT,
        eventBody1,
      );

      var topics2 = [XdrSCVal.forBool(true)];
      var data2 = XdrSCVal.forI32(500);
      var eventBody2 = XdrContractEventBody(0);
      eventBody2.v0 = XdrContractEventBodyV0(topics2, data2);
      var event2 = XdrContractEvent(
        XdrExtensionPoint(0),
        null,
        XdrContractEventType.CONTRACT_EVENT_TYPE_SYSTEM,
        eventBody2,
      );

      var original = XdrInvokeHostFunctionSuccessPreImage(
        returnValue,
        [event1, event2],
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrInvokeHostFunctionSuccessPreImage.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrInvokeHostFunctionSuccessPreImage.decode(input);

      expect(decoded.returnValue.u64!.uint64, equals(BigInt.from(999999)));
      expect(decoded.events.length, equals(2));
    });

    test('XdrLedgerHeaderExt with discriminant 0 encode/decode', () {
      var original = XdrLedgerHeaderExt(0);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerHeaderExt.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerHeaderExt.decode(input);

      expect(decoded.discriminant, equals(0));
    });

    test('XdrAccountEntryV2Ext with discriminant 0 encode/decode', () {
      var original = XdrAccountEntryV2Ext(0);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrAccountEntryV2Ext.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrAccountEntryV2Ext.decode(input);

      expect(decoded.discriminant, equals(0));
    });

    test('TrustLineEntryExtensionV2Ext with discriminant 0 encode/decode', () {
      var original = TrustLineEntryExtensionV2Ext(0);

      XdrDataOutputStream output = XdrDataOutputStream();
      TrustLineEntryExtensionV2Ext.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = TrustLineEntryExtensionV2Ext.decode(input);

      expect(decoded.discriminant, equals(0));
    });

    test('XdrOfferEntryExt with discriminant 0 encode/decode', () {
      var original = XdrOfferEntryExt(0);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOfferEntryExt.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOfferEntryExt.decode(input);

      expect(decoded.discriminant, equals(0));
    });

    test('XdrStellarValueExt with discriminant 0 encode/decode', () {
      var original = XdrStellarValueExt(0);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrStellarValueExt.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrStellarValueExt.decode(input);

      expect(decoded.discriminant, equals(0));
    });

    test('XdrStellarValue with upgrades encode/decode', () {
      var upgrade1 = XdrUpgradeType(Uint8List.fromList([0x00, 0x01, 0x02, 0x03]));
      var upgrade2 = XdrUpgradeType(Uint8List.fromList([0x04, 0x05, 0x06, 0x07]));

      var original = XdrStellarValue(
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0x99))),
        XdrUint64(BigInt.from(987654)),
        [upgrade1, upgrade2],
        XdrStellarValueExt(0),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrStellarValue.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrStellarValue.decode(input);

      expect(decoded.closeTime.uint64, equals(BigInt.from(987654)));
      expect(decoded.upgrades.length, equals(2));
    });

    test('XdrStellarValue with empty upgrades encode/decode', () {
      var original = XdrStellarValue(
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0x88))),
        XdrUint64(BigInt.from(123456)),
        [],
        XdrStellarValueExt(0),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrStellarValue.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrStellarValue.decode(input);

      expect(decoded.closeTime.uint64, equals(BigInt.from(123456)));
      expect(decoded.upgrades.length, equals(0));
    });

    test('XdrLiabilities encode/decode', () {
      var original = XdrLiabilities(
        XdrInt64(BigInt.from(5000)),
        XdrInt64(BigInt.from(7000)),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLiabilities.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLiabilities.decode(input);

      expect(decoded.buying.int64, equals(BigInt.from(5000)));
      expect(decoded.selling.int64, equals(BigInt.from(7000)));
    });

    test('XdrAccountEntryV2 with signerSponsoringIDs encode/decode', () {
      var sponsor1 = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var sponsor2 = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');

      var original = XdrAccountEntryV2(
        XdrUint32(3),
        XdrUint32(2),
        [sponsor1, sponsor2],
        XdrAccountEntryV2Ext(0),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrAccountEntryV2.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrAccountEntryV2.decode(input);

      expect(decoded.numSponsored.uint32, equals(3));
      expect(decoded.numSponsoring.uint32, equals(2));
      expect(decoded.signerSponsoringIDs.length, equals(2));
    });

    test('XdrAccountEntryV2 with empty signerSponsoringIDs encode/decode', () {
      var original = XdrAccountEntryV2(
        XdrUint32(0),
        XdrUint32(0),
        [],
        XdrAccountEntryV2Ext(0),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrAccountEntryV2.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrAccountEntryV2.decode(input);

      expect(decoded.numSponsored.uint32, equals(0));
      expect(decoded.numSponsoring.uint32, equals(0));
      expect(decoded.signerSponsoringIDs.length, equals(0));
    });

    test('XdrAccountEntryV2 with null signerSponsoringIDs encode/decode', () {
      var original = XdrAccountEntryV2(
        XdrUint32(1),
        XdrUint32(0),
        [null],
        XdrAccountEntryV2Ext(0),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrAccountEntryV2.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrAccountEntryV2.decode(input);

      expect(decoded.numSponsored.uint32, equals(1));
      expect(decoded.signerSponsoringIDs.length, equals(1));
      expect(decoded.signerSponsoringIDs[0], isNull);
    });

    test('XdrAccountEntry with full v2 extension encode/decode', () {
      var accountId = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var signerKey = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519);
      signerKey.ed25519 = XdrUint256(KeyPair.fromAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H').publicKey);
      var signer = XdrSigner(signerKey, XdrUint32(1));

      var liabilities = XdrLiabilities(
        XdrInt64(BigInt.from(2000)),
        XdrInt64(BigInt.from(3000)),
      );

      var sponsor = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var v2 = XdrAccountEntryV2(
        XdrUint32(1),
        XdrUint32(1),
        [sponsor],
        XdrAccountEntryV2Ext(0),
      );

      var v1Ext = XdrAccountEntryV1Ext(2);
      v1Ext.v2 = v2;

      var v1 = XdrAccountEntryV1(liabilities, v1Ext);
      var ext = XdrAccountEntryExt(1);
      ext.v1 = v1;

      var account = XdrAccountEntry(
        accountId,
        XdrInt64(BigInt.from(50000000)),
        XdrSequenceNumber(XdrBigInt64(BigInt.from(5))),
        XdrUint32(1),
        accountId,
        XdrUint32(2),
        XdrString32('memo'),
        XdrThresholds(Uint8List.fromList([1, 2, 3, 4])),
        [signer],
        ext,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrAccountEntry.encode(output, account);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrAccountEntry.decode(input);

      expect(decoded.ext.discriminant, equals(1));
      expect(decoded.ext.v1, isNotNull);
      expect(decoded.ext.v1!.ext.discriminant, equals(2));
      expect(decoded.ext.v1!.ext.v2, isNotNull);
      expect(decoded.ext.v1!.ext.v2!.numSponsored.uint32, equals(1));
    });

    test('XdrTrustLineEntry with full v2 extension encode/decode', () {
      var accountId = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var asset = XdrTrustlineAsset.fromXdrAsset(XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE));

      var liabilities = XdrLiabilities(
        XdrInt64(BigInt.from(4000)),
        XdrInt64(BigInt.from(6000)),
      );

      var v2 = TrustLineEntryExtensionV2(
        XdrInt32(50),
        TrustLineEntryExtensionV2Ext(0),
      );

      var v1Ext = XdrTrustLineEntryV1Ext(2);
      v1Ext.ext = v2;

      var v1 = XdrTrustLineEntryV1(liabilities, v1Ext);
      var ext = XdrTrustLineEntryExt(1);
      ext.v1 = v1;

      var trustLine = XdrTrustLineEntry(
        accountId,
        asset,
        XdrInt64(BigInt.from(8000000)),
        XdrInt64(BigInt.from(12000000)),
        XdrUint32(3),
        ext,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTrustLineEntry.encode(output, trustLine);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTrustLineEntry.decode(input);

      expect(decoded.ext.discriminant, equals(1));
      expect(decoded.ext.v1, isNotNull);
      expect(decoded.ext.v1!.ext.discriminant, equals(2));
      expect(decoded.ext.v1!.ext.ext, isNotNull);
      expect(decoded.ext.v1!.ext.ext!.liquidityPoolUseCount.int32, equals(50));
    });

    test('XdrLedgerEntry with complete v1 extension encode/decode', () {
      var accountId = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var data = XdrLedgerEntryData(XdrLedgerEntryType.DATA);
      var dataEntry = XdrDataEntry(
        accountId,
        XdrString64('key1'),
        XdrDataValue(Uint8List.fromList([0xAA, 0xBB, 0xCC, 0xDD])),
        XdrDataEntryExt(0),
      );
      data.data = dataEntry;

      var sponsoringID = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var v1 = XdrLedgerEntryV1(XdrLedgerEntryV1Ext(0));
      v1.sponsoringID = sponsoringID;

      var ext = XdrLedgerEntryExt(1);
      ext.ledgerEntryExtensionV1 = v1;

      var entry = XdrLedgerEntry(
        XdrUint32(250),
        data,
        ext,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerEntry.encode(output, entry);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerEntry.decode(input);

      expect(decoded.lastModifiedLedgerSeq.uint32, equals(250));
      expect(decoded.ext.discriminant, equals(1));
      expect(decoded.ext.ledgerEntryExtensionV1, isNotNull);
      expect(decoded.ext.ledgerEntryExtensionV1!.sponsoringID, isNotNull);
    });

    test('XdrLedgerEntryChanges with all change types encode/decode', () {
      var accountId = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');

      var change1 = XdrLedgerEntryChange(XdrLedgerEntryChangeType.LEDGER_ENTRY_CREATED);
      var data1 = XdrLedgerEntryData(XdrLedgerEntryType.DATA);
      var dataEntry1 = XdrDataEntry(
        accountId,
        XdrString64('test'),
        XdrDataValue(Uint8List.fromList([0x01, 0x02, 0x03, 0x04])),
        XdrDataEntryExt(0),
      );
      data1.data = dataEntry1;
      change1.created = XdrLedgerEntry(XdrUint32(100), data1, XdrLedgerEntryExt(0));

      var change2 = XdrLedgerEntryChange(XdrLedgerEntryChangeType.LEDGER_ENTRY_UPDATED);
      var data2 = XdrLedgerEntryData(XdrLedgerEntryType.DATA);
      var dataEntry2 = XdrDataEntry(
        accountId,
        XdrString64('test'),
        XdrDataValue(Uint8List.fromList([0x05, 0x06, 0x07, 0x08])),
        XdrDataEntryExt(0),
      );
      data2.data = dataEntry2;
      change2.updated = XdrLedgerEntry(XdrUint32(101), data2, XdrLedgerEntryExt(0));

      var change3 = XdrLedgerEntryChange(XdrLedgerEntryChangeType.LEDGER_ENTRY_REMOVED);
      var keyData = XdrLedgerKeyData(accountId, XdrString64('test'));
      var key = XdrLedgerKey(XdrLedgerEntryType.DATA);
      key.data = keyData;
      change3.removed = key;

      var change4 = XdrLedgerEntryChange(XdrLedgerEntryChangeType.LEDGER_ENTRY_STATE);
      var data4 = XdrLedgerEntryData(XdrLedgerEntryType.DATA);
      var dataEntry4 = XdrDataEntry(
        accountId,
        XdrString64('test'),
        XdrDataValue(Uint8List.fromList([0x09, 0x0A, 0x0B, 0x0C])),
        XdrDataEntryExt(0),
      );
      data4.data = dataEntry4;
      change4.state = XdrLedgerEntry(XdrUint32(102), data4, XdrLedgerEntryExt(0));

      var change5 = XdrLedgerEntryChange(XdrLedgerEntryChangeType.LEDGER_ENTRY_RESTORED);
      var data5 = XdrLedgerEntryData(XdrLedgerEntryType.DATA);
      var dataEntry5 = XdrDataEntry(
        accountId,
        XdrString64('test'),
        XdrDataValue(Uint8List.fromList([0x0D, 0x0E, 0x0F, 0x10])),
        XdrDataEntryExt(0),
      );
      data5.data = dataEntry5;
      change5.restored = XdrLedgerEntry(XdrUint32(103), data5, XdrLedgerEntryExt(0));

      var original = XdrLedgerEntryChanges([change1, change2, change3, change4, change5]);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerEntryChanges.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerEntryChanges.decode(input);

      expect(decoded.ledgerEntryChanges.length, equals(5));
      expect(decoded.ledgerEntryChanges[0].discriminant.value, equals(XdrLedgerEntryChangeType.LEDGER_ENTRY_CREATED.value));
      expect(decoded.ledgerEntryChanges[1].discriminant.value, equals(XdrLedgerEntryChangeType.LEDGER_ENTRY_UPDATED.value));
      expect(decoded.ledgerEntryChanges[2].discriminant.value, equals(XdrLedgerEntryChangeType.LEDGER_ENTRY_REMOVED.value));
      expect(decoded.ledgerEntryChanges[3].discriminant.value, equals(XdrLedgerEntryChangeType.LEDGER_ENTRY_STATE.value));
      expect(decoded.ledgerEntryChanges[4].discriminant.value, equals(XdrLedgerEntryChangeType.LEDGER_ENTRY_RESTORED.value));
    });

    test('XdrContractCodeEntry with full v1 extension encode/decode', () {
      var ext = XdrContractCodeEntryExt(1);
      var costInputs = XdrContractCodeCostInputs(
        XdrExtensionPoint(0),
        XdrInt32(2000),
        XdrInt32(1000),
        XdrInt32(200),
        XdrInt32(100),
        XdrInt32(20),
        XdrInt32(10),
        XdrInt32(500),
        XdrInt32(600),
        XdrInt32(700),
        XdrInt32(800),
      );
      var v1 = XdrContractCodeEntryExtV1(
        XdrExtensionPoint(0),
        costInputs,
      );
      ext.v1 = v1;

      var hash = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xDD)));
      var code = Uint8List.fromList([0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00]);

      var contractCode = XdrContractCodeEntry(ext, hash, XdrDataValue(code));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrContractCodeEntry.encode(output, contractCode);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrContractCodeEntry.decode(input);

      expect(decoded.ext.discriminant, equals(1));
      expect(decoded.ext.v1, isNotNull);
      expect(decoded.ext.v1!.costInputs.nInstructions.int32, equals(2000));
    });

    test('XdrClaimableBalanceEntry with full v1 extension encode/decode', () {
      var balanceId = XdrClaimableBalanceID(XdrClaimableBalanceIDType.CLAIMABLE_BALANCE_ID_TYPE_V0);
      balanceId.v0 = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xEE)));

      var accountId = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var predicate = XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_UNCONDITIONAL);
      var claimant = XdrClaimant(XdrClaimantType.CLAIMANT_TYPE_V0);
      claimant.v0 = XdrClaimantV0(accountId, predicate);

      var ext = XdrClaimableBalanceEntryExt(1);
      var v1 = XdrClaimableBalanceEntryExtV1(
        0,
        XdrUint32(2000),
      );
      ext.v1 = v1;

      var claimableBalance = XdrClaimableBalanceEntry(
        balanceId,
        [claimant],
        XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE),
        XdrInt64(BigInt.from(3000000)),
        ext,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrClaimableBalanceEntry.encode(output, claimableBalance);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrClaimableBalanceEntry.decode(input);

      expect(decoded.ext.discriminant, equals(1));
      expect(decoded.ext.v1, isNotNull);
      expect(decoded.ext.v1!.flags.uint32, equals(2000));
    });

    test('XdrLedgerHeader with v0 extension encode/decode', () {
      var stellarValue = XdrStellarValue(
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0xFF))),
        XdrUint64(BigInt.from(555555)),
        [],
        XdrStellarValueExt(0),
      );

      var ext = XdrLedgerHeaderExt(0);

      var ledgerHeader = XdrLedgerHeader(
        XdrUint32(20),
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0xA1))),
        stellarValue,
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0xA2))),
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0xA3))),
        XdrUint32(600),
        XdrInt64(BigInt.from(60000000)),
        XdrInt64(BigInt.from(600)),
        XdrUint32(6000),
        XdrUint64(BigInt.from(6000)),
        XdrUint32(100),
        XdrUint32(15000000),
        XdrUint32(6000),
        List<XdrHash>.generate(4, (i) => XdrHash(Uint8List.fromList(List<int>.filled(32, 0xA4)))),
        ext,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerHeader.encode(output, ledgerHeader);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerHeader.decode(input);

      expect(decoded.ledgerSeq.uint32, equals(600));
      expect(decoded.ext.discriminant, equals(0));
    });

    test('XdrLedgerHeaderHistoryEntry with v0 extension encode/decode', () {
      var hash = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xB1)));

      var stellarValue = XdrStellarValue(
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0xB2))),
        XdrUint64(BigInt.from(777777)),
        [],
        XdrStellarValueExt(0),
      );

      var headerExt = XdrLedgerHeaderExt(0);

      var header = XdrLedgerHeader(
        XdrUint32(19),
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0xB3))),
        stellarValue,
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0xB4))),
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0xB5))),
        XdrUint32(700),
        XdrInt64(BigInt.from(70000000)),
        XdrInt64(BigInt.from(700)),
        XdrUint32(7000),
        XdrUint64(BigInt.from(7000)),
        XdrUint32(100),
        XdrUint32(20000000),
        XdrUint32(7000),
        List<XdrHash>.generate(4, (i) => XdrHash(Uint8List.fromList(List<int>.filled(32, 0xB6)))),
        headerExt,
      );

      var ext = XdrLedgerHeaderHistoryEntryExt(0);

      var entry = XdrLedgerHeaderHistoryEntry(
        hash,
        header,
        ext,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerHeaderHistoryEntry.encode(output, entry);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerHeaderHistoryEntry.decode(input);

      expect(decoded.header.ledgerSeq.uint32, equals(700));
      expect(decoded.header.ext.discriminant, equals(0));
      expect(decoded.ext.discriminant, equals(0));
    });

    test('XdrLedgerKeyAccount with different account encode/decode', () {
      var accountId = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var keyAccount = XdrLedgerKeyAccount(accountId);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerKeyAccount.encode(output, keyAccount);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerKeyAccount.decode(input);

      expect(decoded.accountID, isNotNull);
    });

    test('XdrLedgerKeyTrustLine with trustline asset encode/decode', () {
      var accountId = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var asset = XdrTrustlineAsset.fromXdrAsset(XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE));
      var keyTrustLine = XdrLedgerKeyTrustLine(accountId, asset);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerKeyTrustLine.encode(output, keyTrustLine);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerKeyTrustLine.decode(input);

      expect(decoded.accountID, isNotNull);
      expect(decoded.asset, isNotNull);
    });

    test('XdrLedgerKeyOffer with offer ID encode/decode', () {
      var sellerId = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var keyOffer = XdrLedgerKeyOffer(sellerId, XdrUint64(BigInt.from(999)));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerKeyOffer.encode(output, keyOffer);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerKeyOffer.decode(input);

      expect(decoded.sellerID, isNotNull);
      expect(decoded.offerID.uint64, equals(BigInt.from(999)));
    });

    test('XdrLedgerKeyData with data name encode/decode', () {
      var accountId = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var keyData = XdrLedgerKeyData(accountId, XdrString64('data'));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerKeyData.encode(output, keyData);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerKeyData.decode(input);

      expect(decoded.accountID, isNotNull);
      expect(decoded.dataName.string64, equals('data'));
    });

    test('XdrLedgerKeyContractData with contract address encode/decode', () {
      var contractIdBytes = Uint8List.fromList(List<int>.filled(32, 0xC1));
      var contractIdHex = Util.bytesToHex(contractIdBytes);
      var contractId = XdrSCAddress.forContractId(contractIdHex);
      var key = XdrSCVal.forU32(88888);
      var durability = XdrContractDataDurability.PERSISTENT;
      var keyContractData = XdrLedgerKeyContractData(contractId, key, durability);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerKeyContractData.encode(output, keyContractData);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerKeyContractData.decode(input);

      expect(decoded.contract, isNotNull);
      expect(decoded.key.u32!.uint32, equals(88888));
      expect(decoded.durability.value, equals(XdrContractDataDurability.PERSISTENT.value));
    });

    test('XdrLedgerKeyContractCode with hash encode/decode', () {
      var hash = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xD1)));
      var keyContractCode = XdrLedgerKeyContractCode(hash);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerKeyContractCode.encode(output, keyContractCode);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerKeyContractCode.decode(input);

      expect(decoded.hash.hash, equals(hash.hash));
    });

    test('XdrLedgerKeyTTL with key hash encode/decode', () {
      var keyHash = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xE1)));
      var keyTTL = XdrLedgerKeyTTL(keyHash);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerKeyTTL.encode(output, keyTTL);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerKeyTTL.decode(input);

      expect(decoded.hashKey.hash, equals(keyHash.hash));
    });

    test('XdrConfigUpgradeSetKey complete encode/decode', () {
      var contractID = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xF1)));
      var contentHash = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xF2)));

      var original = XdrConfigUpgradeSetKey(contractID, contentHash);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrConfigUpgradeSetKey.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrConfigUpgradeSetKey.decode(input);

      expect(decoded.contractID.hash, equals(contractID.hash));
      expect(decoded.contentHash.hash, equals(contentHash.hash));
    });
  });
}
