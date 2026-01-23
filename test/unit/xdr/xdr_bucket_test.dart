// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('XDR Bucket Types - Complete Testing', () {
    test('XdrBucketEntryType enum METAENTRY', () {
      XdrDataOutputStream output = XdrDataOutputStream();
      XdrBucketEntryType.encode(output, XdrBucketEntryType.METAENTRY);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrBucketEntryType.decode(input);

      expect(decoded.value, equals(XdrBucketEntryType.METAENTRY.value));
      expect(decoded.value, equals(-1));
    });

    test('XdrBucketEntryType enum LIVEENTRY', () {
      XdrDataOutputStream output = XdrDataOutputStream();
      XdrBucketEntryType.encode(output, XdrBucketEntryType.LIVEENTRY);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrBucketEntryType.decode(input);

      expect(decoded.value, equals(XdrBucketEntryType.LIVEENTRY.value));
      expect(decoded.value, equals(0));
    });

    test('XdrBucketEntryType enum DEADENTRY', () {
      XdrDataOutputStream output = XdrDataOutputStream();
      XdrBucketEntryType.encode(output, XdrBucketEntryType.DEADENTRY);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrBucketEntryType.decode(input);

      expect(decoded.value, equals(XdrBucketEntryType.DEADENTRY.value));
      expect(decoded.value, equals(1));
    });

    test('XdrBucketEntryType enum INITENTRY', () {
      XdrDataOutputStream output = XdrDataOutputStream();
      XdrBucketEntryType.encode(output, XdrBucketEntryType.INITENTRY);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrBucketEntryType.decode(input);

      expect(decoded.value, equals(XdrBucketEntryType.INITENTRY.value));
      expect(decoded.value, equals(2));
    });

    test('XdrBucketEntryType decode throws on unknown value', () {
      XdrDataOutputStream output = XdrDataOutputStream();
      output.writeInt(999);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);

      expect(() => XdrBucketEntryType.decode(input), throwsException);
    });

    test('XdrBucketEntryType toString', () {
      expect(XdrBucketEntryType.METAENTRY.toString(), contains('BucketEntryType'));
      expect(XdrBucketEntryType.LIVEENTRY.toString(), contains('BucketEntryType'));
      expect(XdrBucketEntryType.DEADENTRY.toString(), contains('BucketEntryType'));
      expect(XdrBucketEntryType.INITENTRY.toString(), contains('BucketEntryType'));
    });

    test('XdrBucketEntry LIVEENTRY encode/decode', () {
      var accountId = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var accountData = XdrAccountEntry(
        accountId,
        XdrInt64(BigInt.from(10000000)),
        XdrSequenceNumber(XdrBigInt64(BigInt.from(1))),
        XdrUint32(0),
        accountId,
        XdrUint32(0),
        XdrString32('testtest'),
        XdrThresholds(Uint8List.fromList([1, 1, 1, 1])),
        [],
        XdrAccountEntryExt(0),
      );

      var ledgerData = XdrLedgerEntryData(XdrLedgerEntryType.ACCOUNT);
      ledgerData.account = accountData;
      var ledgerEntry = XdrLedgerEntry(XdrUint32(0), ledgerData, XdrLedgerEntryExt(0));

      var original = XdrBucketEntry(XdrBucketEntryType.LIVEENTRY);
      original.liveEntry = ledgerEntry;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrBucketEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrBucketEntry.decode(input);

      expect(decoded.discriminant.value, equals(XdrBucketEntryType.LIVEENTRY.value));
      expect(decoded.liveEntry, isNotNull);
      expect(decoded.liveEntry!.data!.account!.balance.int64, equals(BigInt.from(10000000)));
    });

    test('XdrBucketEntry DEADENTRY encode/decode', () {
      var accountId = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var ledgerKey = XdrLedgerKey(XdrLedgerEntryType.ACCOUNT);
      ledgerKey.account = XdrLedgerKeyAccount(accountId);

      var original = XdrBucketEntry(XdrBucketEntryType.DEADENTRY);
      original.deadEntry = ledgerKey;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrBucketEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrBucketEntry.decode(input);

      expect(decoded.discriminant.value, equals(XdrBucketEntryType.DEADENTRY.value));
      expect(decoded.deadEntry, isNotNull);
      expect(decoded.deadEntry!.discriminant.value, equals(XdrLedgerEntryType.ACCOUNT.value));
    });

    test('XdrBucketEntry METAENTRY encode/decode', () {
      var original = XdrBucketEntry(XdrBucketEntryType.METAENTRY);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrBucketEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrBucketEntry.decode(input);

      expect(decoded.discriminant.value, equals(XdrBucketEntryType.METAENTRY.value));
      expect(decoded.liveEntry, isNull);
      expect(decoded.deadEntry, isNull);
    });

    test('XdrBucketEntry INITENTRY encode/decode', () {
      var original = XdrBucketEntry(XdrBucketEntryType.INITENTRY);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrBucketEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrBucketEntry.decode(input);

      expect(decoded.discriminant.value, equals(XdrBucketEntryType.INITENTRY.value));
      expect(decoded.liveEntry, isNull);
      expect(decoded.deadEntry, isNull);
    });

    test('XdrBucketEntry discriminant getter/setter', () {
      var entry = XdrBucketEntry(XdrBucketEntryType.LIVEENTRY);
      expect(entry.discriminant.value, equals(0));

      entry.discriminant = XdrBucketEntryType.DEADENTRY;
      expect(entry.discriminant.value, equals(1));
    });

    test('XdrBucketEntry liveEntry getter/setter', () {
      var accountId = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var accountData = XdrAccountEntry(
        accountId,
        XdrInt64(BigInt.from(5000000)),
        XdrSequenceNumber(XdrBigInt64(BigInt.from(2))),
        XdrUint32(0),
        accountId,
        XdrUint32(0),
        XdrString32('testtest'),
        XdrThresholds(Uint8List.fromList([1, 1, 1, 1])),
        [],
        XdrAccountEntryExt(0),
      );

      var ledgerData = XdrLedgerEntryData(XdrLedgerEntryType.ACCOUNT);
      ledgerData.account = accountData;
      var ledgerEntry = XdrLedgerEntry(XdrUint32(0), ledgerData, XdrLedgerEntryExt(0));

      var entry = XdrBucketEntry(XdrBucketEntryType.LIVEENTRY);
      entry.liveEntry = ledgerEntry;

      expect(entry.liveEntry, isNotNull);
      expect(entry.liveEntry!.data!.account!.balance.int64, equals(BigInt.from(5000000)));
    });

    test('XdrBucketEntry deadEntry getter/setter', () {
      var accountId = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var ledgerKey = XdrLedgerKey(XdrLedgerEntryType.ACCOUNT);
      ledgerKey.account = XdrLedgerKeyAccount(accountId);

      var entry = XdrBucketEntry(XdrBucketEntryType.DEADENTRY);
      entry.deadEntry = ledgerKey;

      expect(entry.deadEntry, isNotNull);
      expect(entry.deadEntry!.discriminant.value, equals(XdrLedgerEntryType.ACCOUNT.value));
    });

    test('XdrBucketEntry with TRUSTLINE liveEntry', () {
      var accountId = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var asset = XdrTrustlineAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var ext = XdrTrustLineEntryExt(0);
      var trustlineEntry = XdrTrustLineEntry(
        accountId,
        asset,
        XdrInt64(BigInt.from(1000000)),
        XdrInt64(BigInt.from(10000000)),
        XdrUint32(1),
        ext,
      );

      var ledgerData = XdrLedgerEntryData(XdrLedgerEntryType.TRUSTLINE);
      ledgerData.trustLine = trustlineEntry;
      var ledgerEntry = XdrLedgerEntry(XdrUint32(0), ledgerData, XdrLedgerEntryExt(0));

      var original = XdrBucketEntry(XdrBucketEntryType.LIVEENTRY);
      original.liveEntry = ledgerEntry;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrBucketEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrBucketEntry.decode(input);

      expect(decoded.discriminant.value, equals(XdrBucketEntryType.LIVEENTRY.value));
      expect(decoded.liveEntry, isNotNull);
      expect(decoded.liveEntry!.data!.trustLine!.balance.int64, equals(BigInt.from(1000000)));
    });

    test('XdrBucketEntry with TRUSTLINE deadEntry', () {
      var accountId = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var asset = XdrTrustlineAsset(XdrAssetType.ASSET_TYPE_NATIVE);

      var ledgerKey = XdrLedgerKey(XdrLedgerEntryType.TRUSTLINE);
      ledgerKey.trustLine = XdrLedgerKeyTrustLine(accountId, asset);

      var original = XdrBucketEntry(XdrBucketEntryType.DEADENTRY);
      original.deadEntry = ledgerKey;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrBucketEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrBucketEntry.decode(input);

      expect(decoded.discriminant.value, equals(XdrBucketEntryType.DEADENTRY.value));
      expect(decoded.deadEntry, isNotNull);
      expect(decoded.deadEntry!.discriminant.value, equals(XdrLedgerEntryType.TRUSTLINE.value));
    });

    test('XdrBucketEntry with OFFER deadEntry', () {
      var accountId = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');

      var ledgerKey = XdrLedgerKey(XdrLedgerEntryType.OFFER);
      ledgerKey.offer = XdrLedgerKeyOffer(accountId, XdrUint64(BigInt.from(12345)));

      var original = XdrBucketEntry(XdrBucketEntryType.DEADENTRY);
      original.deadEntry = ledgerKey;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrBucketEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrBucketEntry.decode(input);

      expect(decoded.discriminant.value, equals(XdrBucketEntryType.DEADENTRY.value));
      expect(decoded.deadEntry, isNotNull);
      expect(decoded.deadEntry!.discriminant.value, equals(XdrLedgerEntryType.OFFER.value));
      expect(decoded.deadEntry!.offer!.offerID.uint64, equals(BigInt.from(12345)));
    });

    test('XdrBucketEntry with DATA deadEntry', () {
      var accountId = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var dataName = XdrString64('testdata');

      var ledgerKey = XdrLedgerKey(XdrLedgerEntryType.DATA);
      ledgerKey.data = XdrLedgerKeyData(accountId, dataName);

      var original = XdrBucketEntry(XdrBucketEntryType.DEADENTRY);
      original.deadEntry = ledgerKey;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrBucketEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrBucketEntry.decode(input);

      expect(decoded.discriminant.value, equals(XdrBucketEntryType.DEADENTRY.value));
      expect(decoded.deadEntry, isNotNull);
      expect(decoded.deadEntry!.discriminant.value, equals(XdrLedgerEntryType.DATA.value));
    });

    test('Multiple XdrBucketEntry encode/decode in sequence', () {
      var accountId = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');

      var liveEntry = XdrBucketEntry(XdrBucketEntryType.LIVEENTRY);
      var accountData = XdrAccountEntry(
        accountId,
        XdrInt64(BigInt.from(3000000)),
        XdrSequenceNumber(XdrBigInt64(BigInt.from(3))),
        XdrUint32(0),
        accountId,
        XdrUint32(0),
        XdrString32('testtest'),
        XdrThresholds(Uint8List.fromList([1, 1, 1, 1])),
        [],
        XdrAccountEntryExt(0),
      );
      var ledgerData = XdrLedgerEntryData(XdrLedgerEntryType.ACCOUNT);
      ledgerData.account = accountData;
      var ledgerEntry = XdrLedgerEntry(XdrUint32(0), ledgerData, XdrLedgerEntryExt(0));
      liveEntry.liveEntry = ledgerEntry;

      var deadEntry = XdrBucketEntry(XdrBucketEntryType.DEADENTRY);
      var ledgerKey = XdrLedgerKey(XdrLedgerEntryType.ACCOUNT);
      ledgerKey.account = XdrLedgerKeyAccount(accountId);
      deadEntry.deadEntry = ledgerKey;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrBucketEntry.encode(output, liveEntry);
      XdrBucketEntry.encode(output, deadEntry);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded1 = XdrBucketEntry.decode(input);
      var decoded2 = XdrBucketEntry.decode(input);

      expect(decoded1.discriminant.value, equals(XdrBucketEntryType.LIVEENTRY.value));
      expect(decoded2.discriminant.value, equals(XdrBucketEntryType.DEADENTRY.value));
    });
  });
}
