// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('XDR Ledger Types - Additional Deep Branch Testing', () {
    test('XdrAccountEntryExt with discriminant 1 encode/decode', () {
      var liabilities = XdrLiabilities(
        XdrInt64(BigInt.from(1000)),
        XdrInt64(BigInt.from(2000)),
      );
      var v1 = XdrAccountEntryV1(liabilities, XdrAccountEntryV1Ext(0));

      var original = XdrAccountEntryExt(1);
      original.v1 = v1;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrAccountEntryExt.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrAccountEntryExt.decode(input);

      expect(decoded.discriminant, equals(1));
      expect(decoded.v1, isNotNull);
      expect(decoded.v1!.liabilities.buying.int64, equals(BigInt.from(1000)));
      expect(decoded.v1!.liabilities.selling.int64, equals(BigInt.from(2000)));
    });

    test('XdrAccountEntryV1Ext with discriminant 2 encode/decode', () {
      var v2 = XdrAccountEntryV2(
        XdrUint32(5),
        XdrUint32(3),
        [],
        XdrAccountEntryV2Ext(0),
      );
      var v1Ext = XdrAccountEntryV1Ext(2);
      v1Ext.v2 = v2;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrAccountEntryV1Ext.encode(output, v1Ext);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrAccountEntryV1Ext.decode(input);

      expect(decoded.discriminant, equals(2));
      expect(decoded.v2, isNotNull);
      expect(decoded.v2!.numSponsored.uint32, equals(5));
    });

    test('XdrTrustLineEntryExt with discriminant 1 encode/decode', () {
      var liabilities = XdrLiabilities(
        XdrInt64(BigInt.from(500)),
        XdrInt64(BigInt.from(1500)),
      );
      var v1 = XdrTrustLineEntryV1(liabilities, XdrTrustLineEntryV1Ext(0));

      var original = XdrTrustLineEntryExt(1);
      original.v1 = v1;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTrustLineEntryExt.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTrustLineEntryExt.decode(input);

      expect(decoded.discriminant, equals(1));
      expect(decoded.v1, isNotNull);
      expect(decoded.v1!.liabilities.buying.int64, equals(BigInt.from(500)));
    });

    test('XdrTrustLineEntryV1Ext with discriminant 2 encode/decode', () {
      var v2 = TrustLineEntryExtensionV2(
        XdrInt32(100),
        TrustLineEntryExtensionV2Ext(0),
      );
      var v1Ext = XdrTrustLineEntryV1Ext(2);
      v1Ext.ext = v2;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTrustLineEntryV1Ext.encode(output, v1Ext);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTrustLineEntryV1Ext.decode(input);

      expect(decoded.discriminant, equals(2));
      expect(decoded.ext, isNotNull);
      expect(decoded.ext!.liquidityPoolUseCount.int32, equals(100));
    });

    test('XdrLedgerEntryExt with discriminant 1 encode/decode', () {
      var sponsoringID = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var v1 = XdrLedgerEntryV1(XdrLedgerEntryV1Ext(0));
      v1.sponsoringID = sponsoringID;

      var original = XdrLedgerEntryExt(1);
      original.ledgerEntryExtensionV1 = v1;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerEntryExt.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerEntryExt.decode(input);

      expect(decoded.discriminant, equals(1));
      expect(decoded.ledgerEntryExtensionV1, isNotNull);
      expect(decoded.ledgerEntryExtensionV1!.sponsoringID, isNotNull);
    });

    test('XdrLedgerEntryV1 with null sponsoringID encode/decode', () {
      var v1 = XdrLedgerEntryV1(XdrLedgerEntryV1Ext(0));
      v1.sponsoringID = null;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerEntryV1.encode(output, v1);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerEntryV1.decode(input);

      expect(decoded.sponsoringID, isNull);
    });

    test('XdrLedgerEntryV1 with sponsoringID encode/decode', () {
      var sponsoringID = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var v1 = XdrLedgerEntryV1(XdrLedgerEntryV1Ext(0));
      v1.sponsoringID = sponsoringID;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerEntryV1.encode(output, v1);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerEntryV1.decode(input);

      expect(decoded.sponsoringID, isNotNull);
    });

    test('XdrClaimPredicate nested NOT with UNCONDITIONAL encode/decode', () {
      var innerPredicate = XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_UNCONDITIONAL);

      var original = XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_NOT);
      original.notPredicate = innerPredicate;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrClaimPredicate.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrClaimPredicate.decode(input);

      expect(decoded.discriminant.value, equals(XdrClaimPredicateType.CLAIM_PREDICATE_NOT.value));
      expect(decoded.notPredicate, isNotNull);
    });

    test('XdrClaimableBalanceEntryExt with discriminant 0 encode/decode', () {
      var original = XdrClaimableBalanceEntryExt(0);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrClaimableBalanceEntryExt.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrClaimableBalanceEntryExt.decode(input);

      expect(decoded.discriminant, equals(0));
    });

    test('XdrContractCodeEntryExt with discriminant 0 encode/decode', () {
      var original = XdrContractCodeEntryExt(0);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrContractCodeEntryExt.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrContractCodeEntryExt.decode(input);

      expect(decoded.discriminant, equals(0));
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

    test('XdrLedgerHeader with version and extensions encode/decode', () {
      var stellarValue = XdrStellarValue(
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0x77))),
        XdrUint64(BigInt.from(999999)),
        [],
        XdrStellarValueExt(0),
      );

      var ext = XdrLedgerHeaderExt(0);

      var ledgerHeader = XdrLedgerHeader(
        XdrUint32(21),
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0xAA))),
        stellarValue,
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0xBB))),
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0xCC))),
        XdrUint32(500),
        XdrInt64(BigInt.from(50000000)),
        XdrInt64(BigInt.from(500)),
        XdrUint32(5000),
        XdrUint64(BigInt.from(5000)),
        XdrUint32(100),
        XdrUint32(10000000),
        XdrUint32(5000),
        List<XdrHash>.generate(4, (i) => XdrHash(Uint8List.fromList(List<int>.filled(32, 0xDD)))),
        ext,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerHeader.encode(output, ledgerHeader);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerHeader.decode(input);

      expect(decoded.ledgerSeq.uint32, equals(500));
      expect(decoded.ext.discriminant, equals(0));
    });

    test('XdrConfigSettingEntry CONTRACT_COST_PARAMS_CPU_INSTRUCTIONS multiple entries encode/decode', () {
      var params = XdrContractCostParams([
        XdrContractCostParamEntry(
          XdrExtensionPoint(0),
          XdrInt64(BigInt.from(100)),
          XdrInt64(BigInt.from(10)),
        ),
        XdrContractCostParamEntry(
          XdrExtensionPoint(0),
          XdrInt64(BigInt.from(200)),
          XdrInt64(BigInt.from(20)),
        ),
      ]);

      var original = XdrConfigSettingEntry(XdrConfigSettingID.CONFIG_SETTING_CONTRACT_COST_PARAMS_CPU_INSTRUCTIONS);
      original.contractCostParamsCpuInsns = params;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrConfigSettingEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrConfigSettingEntry.decode(input);

      expect(decoded.configSettingID.value, equals(XdrConfigSettingID.CONFIG_SETTING_CONTRACT_COST_PARAMS_CPU_INSTRUCTIONS.value));
      expect(decoded.contractCostParamsCpuInsns, isNotNull);
      expect(decoded.contractCostParamsCpuInsns!.entries.length, equals(2));
    });

    test('XdrDataEntryExt with discriminant 0 encode/decode', () {
      var original = XdrDataEntryExt(0);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrDataEntryExt.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrDataEntryExt.decode(input);

      expect(decoded.discriminant, equals(0));
    });

    test('XdrLedgerEntry with all fields encode/decode', () {
      var accountId = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var data = XdrLedgerEntryData(XdrLedgerEntryType.ACCOUNT);
      var signerKey = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519);
      signerKey.ed25519 = XdrUint256(KeyPair.fromAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H').publicKey);
      var signer = XdrSigner(signerKey, XdrUint32(1));
      var account = XdrAccountEntry(
        accountId,
        XdrInt64(BigInt.from(10000000)),
        XdrSequenceNumber(XdrBigInt64(BigInt.from(1))),
        XdrUint32(0),
        accountId,
        XdrUint32(0),
        XdrString32('test'),
        XdrThresholds(Uint8List.fromList([1, 2, 3, 4])),
        [signer],
        XdrAccountEntryExt(0),
      );
      data.account = account;

      var sponsoringID = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var v1 = XdrLedgerEntryV1(XdrLedgerEntryV1Ext(0));
      v1.sponsoringID = sponsoringID;

      var ext = XdrLedgerEntryExt(1);
      ext.ledgerEntryExtensionV1 = v1;

      var entry = XdrLedgerEntry(
        XdrUint32(150),
        data,
        ext,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerEntry.encode(output, entry);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerEntry.decode(input);

      expect(decoded.lastModifiedLedgerSeq.uint32, equals(150));
      expect(decoded.ext.discriminant, equals(1));
      expect(decoded.ext.ledgerEntryExtensionV1!.sponsoringID, isNotNull);
    });

    test('XdrLedgerEntryChanges with multiple changes encode/decode', () {
      var accountId = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');

      var change1 = XdrLedgerEntryChange(XdrLedgerEntryChangeType.LEDGER_ENTRY_CREATED);
      var data1 = XdrLedgerEntryData(XdrLedgerEntryType.ACCOUNT);
      var signerKey = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519);
      signerKey.ed25519 = XdrUint256(KeyPair.fromAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H').publicKey);
      var signer = XdrSigner(signerKey, XdrUint32(1));
      var account = XdrAccountEntry(
        accountId,
        XdrInt64(BigInt.from(10000000)),
        XdrSequenceNumber(XdrBigInt64(BigInt.from(1))),
        XdrUint32(0),
        accountId,
        XdrUint32(0),
        XdrString32(''),
        XdrThresholds(Uint8List.fromList([1, 1, 1, 1])),
        [signer],
        XdrAccountEntryExt(0),
      );
      data1.account = account;
      change1.created = XdrLedgerEntry(XdrUint32(100), data1, XdrLedgerEntryExt(0));

      var change2 = XdrLedgerEntryChange(XdrLedgerEntryChangeType.LEDGER_ENTRY_UPDATED);
      var data2 = XdrLedgerEntryData(XdrLedgerEntryType.ACCOUNT);
      var account2 = XdrAccountEntry(
        accountId,
        XdrInt64(BigInt.from(20000000)),
        XdrSequenceNumber(XdrBigInt64(BigInt.from(2))),
        XdrUint32(0),
        accountId,
        XdrUint32(0),
        XdrString32(''),
        XdrThresholds(Uint8List.fromList([1, 1, 1, 1])),
        [signer],
        XdrAccountEntryExt(0),
      );
      data2.account = account2;
      change2.updated = XdrLedgerEntry(XdrUint32(101), data2, XdrLedgerEntryExt(0));

      var original = XdrLedgerEntryChanges([change1, change2]);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerEntryChanges.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerEntryChanges.decode(input);

      expect(decoded.ledgerEntryChanges.length, equals(2));
      expect(decoded.ledgerEntryChanges[0].discriminant.value, equals(XdrLedgerEntryChangeType.LEDGER_ENTRY_CREATED.value));
      expect(decoded.ledgerEntryChanges[1].discriminant.value, equals(XdrLedgerEntryChangeType.LEDGER_ENTRY_UPDATED.value));
    });

    test('XdrTrustLineEntry with extension v1 encode/decode', () {
      var accountId = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var asset = XdrTrustlineAsset.fromXdrAsset(XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE));

      var liabilities = XdrLiabilities(
        XdrInt64(BigInt.from(1000)),
        XdrInt64(BigInt.from(2000)),
      );
      var v1 = XdrTrustLineEntryV1(liabilities, XdrTrustLineEntryV1Ext(0));
      var ext = XdrTrustLineEntryExt(1);
      ext.v1 = v1;

      var trustLine = XdrTrustLineEntry(
        accountId,
        asset,
        XdrInt64(BigInt.from(5000000)),
        XdrInt64(BigInt.from(10000000)),
        XdrUint32(1),
        ext,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTrustLineEntry.encode(output, trustLine);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTrustLineEntry.decode(input);

      expect(decoded.ext.discriminant, equals(1));
      expect(decoded.ext.v1, isNotNull);
      expect(decoded.ext.v1!.liabilities.buying.int64, equals(BigInt.from(1000)));
    });

    test('XdrAccountEntry with extension v1 encode/decode', () {
      var accountId = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var signerKey = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519);
      signerKey.ed25519 = XdrUint256(KeyPair.fromAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H').publicKey);
      var signer = XdrSigner(signerKey, XdrUint32(1));

      var liabilities = XdrLiabilities(
        XdrInt64(BigInt.from(3000)),
        XdrInt64(BigInt.from(4000)),
      );
      var v1 = XdrAccountEntryV1(liabilities, XdrAccountEntryV1Ext(0));
      var ext = XdrAccountEntryExt(1);
      ext.v1 = v1;

      var account = XdrAccountEntry(
        accountId,
        XdrInt64(BigInt.from(100000000)),
        XdrSequenceNumber(XdrBigInt64(BigInt.from(10))),
        XdrUint32(2),
        accountId,
        XdrUint32(4),
        XdrString32('star'),
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
      expect(decoded.ext.v1!.liabilities.buying.int64, equals(BigInt.from(3000)));
    });

    test('XdrLiquidityPoolEntry complete encode/decode', () {
      var poolId = XdrHash(Uint8List.fromList(List<int>.filled(32, 0x99)));
      var body = XdrLiquidityPoolBody(XdrLiquidityPoolType.LIQUIDITY_POOL_CONSTANT_PRODUCT);
      var constantProduct = XdrConstantProduct(
        XdrLiquidityPoolConstantProductParameters(
          XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE),
          XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE),
          XdrInt32(30),
        ),
        XdrInt64(BigInt.from(100000)),
        XdrInt64(BigInt.from(200000)),
        XdrInt64(BigInt.from(150000)),
        XdrInt64(BigInt.from(5000)),
      );
      body.constantProduct = constantProduct;

      var liquidityPool = XdrLiquidityPoolEntry(poolId, body);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLiquidityPoolEntry.encode(output, liquidityPool);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLiquidityPoolEntry.decode(input);

      expect(decoded.body.discriminant.value, equals(XdrLiquidityPoolType.LIQUIDITY_POOL_CONSTANT_PRODUCT.value));
      expect(decoded.body.constantProduct!.reserveA.int64, equals(BigInt.from(100000)));
    });

    test('XdrContractDataEntry with TEMPORARY durability encode/decode', () {
      var contractIdBytes = Uint8List.fromList(List<int>.filled(32, 0xEE));
      var contractIdHex = Util.bytesToHex(contractIdBytes);
      var contractId = XdrSCAddress.forContractId(contractIdHex);
      var key = XdrSCVal.forU64(BigInt.from(99999));
      var val = XdrSCVal.forI32(-12345);
      var durability = XdrContractDataDurability.TEMPORARY;

      var contractData = XdrContractDataEntry(
        XdrExtensionPoint(0),
        contractId,
        key,
        durability,
        val,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrContractDataEntry.encode(output, contractData);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrContractDataEntry.decode(input);

      expect(decoded.durability.value, equals(XdrContractDataDurability.TEMPORARY.value));
    });

    test('XdrTTLEntry encode/decode', () {
      var keyHash = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xFE)));
      var ttl = XdrTTLEntry(keyHash, XdrUint32(999999));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTTLEntry.encode(output, ttl);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTTLEntry.decode(input);

      expect(decoded.liveUntilLedgerSeq.uint32, equals(999999));
    });

    test('XdrConfigSettingContractLedgerCostExtV0 encode/decode', () {
      var original = XdrConfigSettingContractLedgerCostExtV0(
        XdrUint32(50),
        XdrInt64(BigInt.from(25)),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrConfigSettingContractLedgerCostExtV0.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrConfigSettingContractLedgerCostExtV0.decode(input);

      expect(decoded.txMaxFootprintEntries.uint32, equals(50));
      expect(decoded.feeWrite1KB.int64, equals(BigInt.from(25)));
    });

    test('XdrContractCostParamEntry encode/decode', () {
      var original = XdrContractCostParamEntry(
        XdrExtensionPoint(0),
        XdrInt64(BigInt.from(999)),
        XdrInt64(BigInt.from(888)),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrContractCostParamEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrContractCostParamEntry.decode(input);

      expect(decoded.constTerm.int64, equals(BigInt.from(999)));
      expect(decoded.linearTerm.int64, equals(BigInt.from(888)));
    });

    test('XdrContractCostParams with multiple entries encode/decode', () {
      var entries = [
        XdrContractCostParamEntry(
          XdrExtensionPoint(0),
          XdrInt64(BigInt.from(100)),
          XdrInt64(BigInt.from(10)),
        ),
        XdrContractCostParamEntry(
          XdrExtensionPoint(0),
          XdrInt64(BigInt.from(200)),
          XdrInt64(BigInt.from(20)),
        ),
        XdrContractCostParamEntry(
          XdrExtensionPoint(0),
          XdrInt64(BigInt.from(300)),
          XdrInt64(BigInt.from(30)),
        ),
      ];

      var original = XdrContractCostParams(entries);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrContractCostParams.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrContractCostParams.decode(input);

      expect(decoded.entries.length, equals(3));
      expect(decoded.entries[1].constTerm.int64, equals(BigInt.from(200)));
    });

    test('XdrStateArchivalSettings complete encode/decode', () {
      var original = XdrStateArchivalSettings(
        XdrUint32(2000),
        XdrUint32(200),
        XdrUint32(10000),
        XdrInt64(BigInt.from(5000)),
        XdrInt64(BigInt.from(500)),
        XdrUint32(50),
        XdrUint32(50000),
        XdrUint32(1000),
        XdrUint32(1000),
        XdrUint32(100),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrStateArchivalSettings.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrStateArchivalSettings.decode(input);

      expect(decoded.maxEntryTTL.uint32, equals(2000));
      expect(decoded.minTemporaryTTL.uint32, equals(200));
    });

    test('XdrEvictionIterator with isCurrBucket true encode/decode', () {
      var original = XdrEvictionIterator(
        XdrUint32(42),
        true,
        XdrUint64(BigInt.from(123456)),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrEvictionIterator.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrEvictionIterator.decode(input);

      expect(decoded.bucketListLevel.uint32, equals(42));
      expect(decoded.isCurrBucket, equals(true));
      expect(decoded.bucketFileOffset.uint64, equals(BigInt.from(123456)));
    });

    test('XdrEvictionIterator with isCurrBucket false encode/decode', () {
      var original = XdrEvictionIterator(
        XdrUint32(7),
        false,
        XdrUint64(BigInt.from(654321)),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrEvictionIterator.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrEvictionIterator.decode(input);

      expect(decoded.bucketListLevel.uint32, equals(7));
      expect(decoded.isCurrBucket, equals(false));
      expect(decoded.bucketFileOffset.uint64, equals(BigInt.from(654321)));
    });

    test('XdrConfigSettingContractParallelComputeV0 encode/decode', () {
      var original = XdrConfigSettingContractParallelComputeV0(
        XdrUint32(4096),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrConfigSettingContractParallelComputeV0.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrConfigSettingContractParallelComputeV0.decode(input);

      expect(decoded.ledgerMaxDependentTxClusters.uint32, equals(4096));
    });

    test('XdrConfigSettingSCPTiming encode/decode', () {
      var original = XdrConfigSettingSCPTiming(
        XdrUint32(10000),
        XdrUint32(20000),
        XdrUint32(30000),
        XdrUint32(40000),
        XdrUint32(50000),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrConfigSettingSCPTiming.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrConfigSettingSCPTiming.decode(input);

      expect(decoded.ledgerTargetCloseTimeMilliseconds.uint32, equals(10000));
      expect(decoded.nominationTimeoutInitialMilliseconds.uint32, equals(20000));
    });

    test('XdrContractCodeCostInputs encode/decode', () {
      var original = XdrContractCodeCostInputs(
        XdrExtensionPoint(0),
        XdrInt32(5000),
        XdrInt32(2500),
        XdrInt32(500),
        XdrInt32(250),
        XdrInt32(50),
        XdrInt32(25),
        XdrInt32(1000),
        XdrInt32(1500),
        XdrInt32(2000),
        XdrInt32(3000),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrContractCodeCostInputs.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrContractCodeCostInputs.decode(input);

      expect(decoded.nInstructions.int32, equals(5000));
      expect(decoded.nFunctions.int32, equals(2500));
    });

    test('XdrConfigSettingContractComputeV0 encode/decode', () {
      var original = XdrConfigSettingContractComputeV0(
        XdrInt64(BigInt.from(50000)),
        XdrInt64(BigInt.from(25000)),
        XdrInt64(BigInt.from(5000)),
        XdrUint32(1024),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrConfigSettingContractComputeV0.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrConfigSettingContractComputeV0.decode(input);

      expect(decoded.ledgerMaxInstructions.int64, equals(BigInt.from(50000)));
      expect(decoded.txMaxInstructions.int64, equals(BigInt.from(25000)));
    });

    test('XdrConfigSettingContractLedgerCostV0 encode/decode', () {
      var original = XdrConfigSettingContractLedgerCostV0(
        XdrUint32(2000),
        XdrUint32(1000),
        XdrUint32(4000),
        XdrUint32(3000),
        XdrUint32(6000),
        XdrUint32(200),
        XdrUint32(100),
        XdrUint32(400),
        XdrInt64(BigInt.from(2000)),
        XdrInt64(BigInt.from(200)),
        XdrInt64(BigInt.from(2000)),
        XdrInt64(BigInt.from(200)),
        XdrInt64(BigInt.from(2000)),
        XdrInt64(BigInt.from(200)),
        XdrUint32(20),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrConfigSettingContractLedgerCostV0.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrConfigSettingContractLedgerCostV0.decode(input);

      expect(decoded.ledgerMaxDiskReadEntries.uint32, equals(2000));
      expect(decoded.ledgerMaxDiskReadBytes.uint32, equals(1000));
    });

    test('XdrConfigSettingContractHistoricalDataV0 encode/decode', () {
      var original = XdrConfigSettingContractHistoricalDataV0(
        XdrInt64(BigInt.from(7500)),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrConfigSettingContractHistoricalDataV0.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrConfigSettingContractHistoricalDataV0.decode(input);

      expect(decoded.feeHistorical1KB.int64, equals(BigInt.from(7500)));
    });

    test('XdrConfigSettingContractEventsV0 encode/decode', () {
      var original = XdrConfigSettingContractEventsV0(
        XdrUint32(5000),
        XdrInt64(BigInt.from(500)),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrConfigSettingContractEventsV0.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrConfigSettingContractEventsV0.decode(input);

      expect(decoded.txMaxContractEventsSizeBytes.uint32, equals(5000));
      expect(decoded.feeContractEvents1KB.int64, equals(BigInt.from(500)));
    });

    test('XdrConfigSettingContractBandwidthV0 encode/decode', () {
      var original = XdrConfigSettingContractBandwidthV0(
        XdrUint32(50000),
        XdrUint32(5000),
        XdrInt64(BigInt.from(1500)),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrConfigSettingContractBandwidthV0.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrConfigSettingContractBandwidthV0.decode(input);

      expect(decoded.ledgerMaxTxsSizeBytes.uint32, equals(50000));
      expect(decoded.txMaxSizeBytes.uint32, equals(5000));
    });

    test('XdrConfigSettingContractExecutionLanesV0 encode/decode', () {
      var original = XdrConfigSettingContractExecutionLanesV0(XdrUint32(8));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrConfigSettingContractExecutionLanesV0.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrConfigSettingContractExecutionLanesV0.decode(input);

      expect(decoded.ledgerMaxTxCount.uint32, equals(8));
    });

    test('XdrLedgerHeaderHistoryEntryExt with discriminant 0 encode/decode', () {
      var original = XdrLedgerHeaderHistoryEntryExt(0);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerHeaderHistoryEntryExt.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerHeaderHistoryEntryExt.decode(input);

      expect(decoded.discriminant, equals(0));
    });

    test('Complex nested XdrClaimPredicate AND with nested OR encode/decode', () {
      var innerOr1 = XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_UNCONDITIONAL);
      var innerOr2 = XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME);
      innerOr2.absBefore = XdrInt64(BigInt.from(9999999));

      var orPredicate = XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_OR);
      orPredicate.orPredicates = [innerOr1, innerOr2];

      var unconditional = XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_UNCONDITIONAL);

      var original = XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_AND);
      original.andPredicates = [orPredicate, unconditional];

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrClaimPredicate.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrClaimPredicate.decode(input);

      expect(decoded.discriminant.value, equals(XdrClaimPredicateType.CLAIM_PREDICATE_AND.value));
      expect(decoded.andPredicates!.length, equals(2));
      expect(decoded.andPredicates![0].discriminant.value, equals(XdrClaimPredicateType.CLAIM_PREDICATE_OR.value));
    });

    test('XdrClaimableBalanceEntry with complex predicates encode/decode', () {
      var balanceId = XdrClaimableBalanceID(XdrClaimableBalanceIDType.CLAIMABLE_BALANCE_ID_TYPE_V0);
      balanceId.v0 = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xAB)));

      var accountId1 = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var predicate1 = XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME);
      predicate1.absBefore = XdrInt64(BigInt.from(1234567890));

      var claimant1 = XdrClaimant(XdrClaimantType.CLAIMANT_TYPE_V0);
      claimant1.v0 = XdrClaimantV0(accountId1, predicate1);

      var accountId2 = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var predicate2 = XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_BEFORE_RELATIVE_TIME);
      predicate2.relBefore = XdrInt64(BigInt.from(86400));

      var claimant2 = XdrClaimant(XdrClaimantType.CLAIMANT_TYPE_V0);
      claimant2.v0 = XdrClaimantV0(accountId2, predicate2);

      var claimableBalance = XdrClaimableBalanceEntry(
        balanceId,
        [claimant1, claimant2],
        XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE),
        XdrInt64(BigInt.from(5000000)),
        XdrClaimableBalanceEntryExt(0),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrClaimableBalanceEntry.encode(output, claimableBalance);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrClaimableBalanceEntry.decode(input);

      expect(decoded.claimants.length, equals(2));
      expect(decoded.amount.int64, equals(BigInt.from(5000000)));
    });
  });
}
