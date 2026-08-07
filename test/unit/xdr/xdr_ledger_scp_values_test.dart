// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('XDR Ledger Types - Deep Branch Testing Round 3', () {
    test('XdrLedgerSCPMessages with empty messages encode/decode', () {
      var original = XdrLedgerSCPMessages(XdrUint32(100), []);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerSCPMessages.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerSCPMessages.decode(input);

      expect(decoded.ledgerSeq.uint32, equals(100));
      expect(decoded.messages.length, equals(0));
    });

    test(
      'XdrInvokeHostFunctionSuccessPreImage with empty events encode/decode',
      () {
        var returnValue = XdrSCVal.forU32(12345);

        var original = XdrInvokeHostFunctionSuccessPreImage(returnValue, []);

        XdrDataOutputStream output = XdrDataOutputStream();
        XdrInvokeHostFunctionSuccessPreImage.encode(output, original);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrInvokeHostFunctionSuccessPreImage.decode(input);

        expect(decoded.returnValue.u32!.uint32, equals(12345));
        expect(decoded.events.length, equals(0));
      },
    );

    test('XdrStellarValue with empty upgrades encode/decode', () {
      var original = XdrStellarValue(
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0x88))),
        XdrUint64(BigInt.from(123456)),
        [],
        XdrStellarValueExt(XdrStellarValueType.STELLAR_VALUE_BASIC),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrStellarValue.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrStellarValue.decode(input);

      expect(decoded.closeTime.uint64, equals(BigInt.from(123456)));
      expect(decoded.upgrades.length, equals(0));
    });

    test('XdrStellarValue with proposed value ext encode/decode', () {
      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAA))));
      var signature = XdrLedgerCloseValueSignature(
        XdrNodeID(pk),
        XdrSignature(Uint8List.fromList(List<int>.filled(64, 0xCC))),
      );
      var proposed = XdrStellarValueProposedValue(
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0x11))),
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0x22))),
        XdrUint32(26),
        signature,
      );
      // The proposed value is mutable after construction.
      proposed.txSetHash = XdrHash(
        Uint8List.fromList(List<int>.filled(32, 0x33)),
      );
      proposed.previousLedgerHash = XdrHash(
        Uint8List.fromList(List<int>.filled(32, 0x44)),
      );
      proposed.previousLedgerVersion = XdrUint32(27);
      proposed.lcValueSignature = signature;

      var ext = XdrStellarValueExt(
        XdrStellarValueType.STELLAR_VALUE_EMPTY_TX_SET,
      );
      ext.proposedValue = proposed;
      var original = XdrStellarValue(
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0x88))),
        XdrUint64(BigInt.from(123456)),
        [],
        ext,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrStellarValue.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrStellarValue.decode(input);

      expect(
        decoded.ext.discriminant,
        equals(XdrStellarValueType.STELLAR_VALUE_EMPTY_TX_SET),
      );
      var decodedProposed = decoded.ext.proposedValue!;
      expect(decodedProposed.txSetHash.hash, equals(proposed.txSetHash.hash));
      expect(
        decodedProposed.previousLedgerHash.hash,
        equals(proposed.previousLedgerHash.hash),
      );
      expect(decodedProposed.previousLedgerVersion.uint32, equals(27));
      expect(
        decodedProposed.lcValueSignature.signature.signature,
        equals(signature.signature.signature),
      );
    });

    // SponsorshipDescriptor is `AccountID*`, so every element of
    // signerSponsoringIDs carries a four-byte presence flag ahead of its value
    // and an unsponsored signer is written as the flag alone. The base64 in
    // these cases is the encoding the XDR-JSON reference implementation named
    // by SEP-0051 produces for the same value.
    const String sponsorA =
        'GAAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQDZ7H';
    const String sponsorB =
        'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H';

    test('XdrAccountEntryV2 with empty signerSponsoringIDs encode/decode', () {
      var original = XdrAccountEntryV2(
        XdrUint32(0),
        XdrUint32(0),
        [],
        XdrAccountEntryV2Ext(0),
      );

      expect(
        original.toBase64EncodedXdrString(),
        equals('AAAAAAAAAAAAAAAAAAAAAA=='),
      );

      var decoded = XdrAccountEntryV2.fromBase64EncodedXdrString(
        'AAAAAAAAAAAAAAAAAAAAAA==',
      );

      expect(decoded.numSponsored.uint32, equals(0));
      expect(decoded.numSponsoring.uint32, equals(0));
      expect(decoded.signerSponsoringIDs, isEmpty);
    });

    test('XdrAccountEntryV2 writes an absent sponsor as a presence flag', () {
      var original = XdrAccountEntryV2(XdrUint32(0), XdrUint32(1), [
        null,
      ], XdrAccountEntryV2Ext(0));

      expect(
        original.toBase64EncodedXdrString(),
        equals('AAAAAAAAAAEAAAABAAAAAAAAAAA='),
      );

      var decoded = XdrAccountEntryV2.fromBase64EncodedXdrString(
        'AAAAAAAAAAEAAAABAAAAAAAAAAA=',
      );

      expect(decoded.numSponsoring.uint32, equals(1));
      expect(decoded.signerSponsoringIDs, equals([null]));
    });

    test('XdrAccountEntryV2 writes a present sponsor behind its flag', () {
      var original = XdrAccountEntryV2(XdrUint32(0), XdrUint32(1), [
        XdrAccountID.forAccountId(sponsorA),
      ], XdrAccountEntryV2Ext(0));

      expect(
        original.toBase64EncodedXdrString(),
        equals(
          'AAAAAAAAAAEAAAABAAAAAQAAAAABAQEBAQEBAQEBAQEBAQEBAQEBAQEB'
          'AQEBAQEBAQEBAQAAAAA=',
        ),
      );

      var decoded = XdrAccountEntryV2.fromBase64EncodedXdrString(
        'AAAAAAAAAAEAAAABAAAAAQAAAAABAQEBAQEBAQEBAQEBAQEBAQEBAQEB'
        'AQEBAQEBAQEBAQAAAAA=',
      );

      expect(decoded.signerSponsoringIDs.length, equals(1));
      expect(
        decoded.signerSponsoringIDs.single!.accountID.getEd25519()!.uint256,
        equals(KeyPair.fromAccountId(sponsorA).publicKey),
      );
    });

    test('XdrAccountEntryV2 mixes present and absent sponsors', () {
      const String encoded =
          'AAAAAgAAAAMAAAADAAAAAQAAAAABAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEB'
          'AQEBAQAAAAAAAAABAAAAAGL8HQvQkbK2HA3WVjRrKmjX00fG8sLI7m0ERwJW/AX3'
          'AAAAAA==';

      var original = XdrAccountEntryV2(XdrUint32(2), XdrUint32(3), [
        XdrAccountID.forAccountId(sponsorA),
        null,
        XdrAccountID.forAccountId(sponsorB),
      ], XdrAccountEntryV2Ext(0));

      expect(original.toBase64EncodedXdrString(), equals(encoded));

      var decoded = XdrAccountEntryV2.fromBase64EncodedXdrString(encoded);

      expect(decoded.numSponsored.uint32, equals(2));
      expect(decoded.numSponsoring.uint32, equals(3));
      expect(decoded.signerSponsoringIDs.length, equals(3));
      expect(
        decoded.signerSponsoringIDs[0]!.accountID.getEd25519()!.uint256,
        equals(KeyPair.fromAccountId(sponsorA).publicKey),
      );
      expect(decoded.signerSponsoringIDs[1], isNull);
      expect(
        decoded.signerSponsoringIDs[2]!.accountID.getEd25519()!.uint256,
        equals(KeyPair.fromAccountId(sponsorB).publicKey),
      );
    });

    test('XdrAccountEntry with full v2 extension encode/decode', () {
      var accountId = XdrAccountID.forAccountId(
        'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
      );
      var signerKey = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519);
      signerKey.ed25519 = XdrUint256(
        KeyPair.fromAccountId(
          'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
        ).publicKey,
      );
      var signer = XdrSigner(signerKey, XdrUint32(1));

      var liabilities = XdrLiabilities(
        XdrInt64(BigInt.from(2000)),
        XdrInt64(BigInt.from(3000)),
      );

      var sponsor = XdrAccountID.forAccountId(
        'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
      );
      var v2 = XdrAccountEntryV2(XdrUint32(1), XdrUint32(1), [
        sponsor,
      ], XdrAccountEntryV2Ext(0));

      var v1Ext = XdrAccountEntryV1Ext(2);
      v1Ext.v2 = v2;

      var v1 = XdrAccountEntryV1(liabilities, v1Ext);
      var ext = XdrAccountEntryExt(1);
      ext.v1 = v1;

      var account = XdrAccountEntry(
        accountId,
        XdrInt64(BigInt.from(50000000)),
        XdrSequenceNumber(BigInt.from(5)),
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
      var accountId = XdrAccountID.forAccountId(
        'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
      );
      var asset = XdrTrustlineAsset.fromXdrAsset(
        XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE),
      );

      var liabilities = XdrLiabilities(
        XdrInt64(BigInt.from(4000)),
        XdrInt64(BigInt.from(6000)),
      );

      var v2 = XdrTrustLineEntryExtensionV2(
        XdrInt32(50),
        XdrTrustLineEntryExtensionV2Ext(0),
      );

      var v1Ext = XdrTrustLineEntryV1Ext(2);
      v1Ext.v2 = v2;

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
      expect(decoded.ext.v1!.ext.v2, isNotNull);
      expect(decoded.ext.v1!.ext.v2!.liquidityPoolUseCount.int32, equals(50));
    });

    test('XdrLedgerEntryChanges with all change types encode/decode', () {
      var accountId = XdrAccountID.forAccountId(
        'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H',
      );

      var change1 = XdrLedgerEntryChange(
        XdrLedgerEntryChangeType.LEDGER_ENTRY_CREATED,
      );
      var data1 = XdrLedgerEntryData(XdrLedgerEntryType.DATA);
      var dataEntry1 = XdrDataEntry(
        accountId,
        XdrString64('test'),
        XdrDataValue(Uint8List.fromList([0x01, 0x02, 0x03, 0x04])),
        XdrDataEntryExt(0),
      );
      data1.data = dataEntry1;
      change1.created = XdrLedgerEntry(
        XdrUint32(100),
        data1,
        XdrLedgerEntryExt(0),
      );

      var change2 = XdrLedgerEntryChange(
        XdrLedgerEntryChangeType.LEDGER_ENTRY_UPDATED,
      );
      var data2 = XdrLedgerEntryData(XdrLedgerEntryType.DATA);
      var dataEntry2 = XdrDataEntry(
        accountId,
        XdrString64('test'),
        XdrDataValue(Uint8List.fromList([0x05, 0x06, 0x07, 0x08])),
        XdrDataEntryExt(0),
      );
      data2.data = dataEntry2;
      change2.updated = XdrLedgerEntry(
        XdrUint32(101),
        data2,
        XdrLedgerEntryExt(0),
      );

      var change3 = XdrLedgerEntryChange(
        XdrLedgerEntryChangeType.LEDGER_ENTRY_REMOVED,
      );
      var keyData = XdrLedgerKeyData(accountId, XdrString64('test'));
      var key = XdrLedgerKey(XdrLedgerEntryType.DATA);
      key.data = keyData;
      change3.removed = key;

      var change4 = XdrLedgerEntryChange(
        XdrLedgerEntryChangeType.LEDGER_ENTRY_STATE,
      );
      var data4 = XdrLedgerEntryData(XdrLedgerEntryType.DATA);
      var dataEntry4 = XdrDataEntry(
        accountId,
        XdrString64('test'),
        XdrDataValue(Uint8List.fromList([0x09, 0x0A, 0x0B, 0x0C])),
        XdrDataEntryExt(0),
      );
      data4.data = dataEntry4;
      change4.state = XdrLedgerEntry(
        XdrUint32(102),
        data4,
        XdrLedgerEntryExt(0),
      );

      var change5 = XdrLedgerEntryChange(
        XdrLedgerEntryChangeType.LEDGER_ENTRY_RESTORED,
      );
      var data5 = XdrLedgerEntryData(XdrLedgerEntryType.DATA);
      var dataEntry5 = XdrDataEntry(
        accountId,
        XdrString64('test'),
        XdrDataValue(Uint8List.fromList([0x0D, 0x0E, 0x0F, 0x10])),
        XdrDataEntryExt(0),
      );
      data5.data = dataEntry5;
      change5.restored = XdrLedgerEntry(
        XdrUint32(103),
        data5,
        XdrLedgerEntryExt(0),
      );

      var original = XdrLedgerEntryChanges([
        change1,
        change2,
        change3,
        change4,
        change5,
      ]);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerEntryChanges.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerEntryChanges.decode(input);

      expect(decoded.ledgerEntryChanges.length, equals(5));
      expect(
        decoded.ledgerEntryChanges[0].discriminant.value,
        equals(XdrLedgerEntryChangeType.LEDGER_ENTRY_CREATED.value),
      );
      expect(
        decoded.ledgerEntryChanges[1].discriminant.value,
        equals(XdrLedgerEntryChangeType.LEDGER_ENTRY_UPDATED.value),
      );
      expect(
        decoded.ledgerEntryChanges[2].discriminant.value,
        equals(XdrLedgerEntryChangeType.LEDGER_ENTRY_REMOVED.value),
      );
      expect(
        decoded.ledgerEntryChanges[3].discriminant.value,
        equals(XdrLedgerEntryChangeType.LEDGER_ENTRY_STATE.value),
      );
      expect(
        decoded.ledgerEntryChanges[4].discriminant.value,
        equals(XdrLedgerEntryChangeType.LEDGER_ENTRY_RESTORED.value),
      );
    });
  });
}
