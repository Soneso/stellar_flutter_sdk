// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('XDR Ledger Types - Deep Branch Testing Round 4', () {
    test('XdrConfigSettingEntry BUCKETLIST_SIZE_WINDOW encode/decode', () {
      var window = [
        XdrUint64(BigInt.from(1000)),
        XdrUint64(BigInt.from(2000)),
        XdrUint64(BigInt.from(3000)),
      ];

      var original = XdrConfigSettingEntry(XdrConfigSettingID.CONFIG_SETTING_LIVE_SOROBAN_STATE_SIZE_WINDOW);
      original.liveSorobanStateSizeWindow = window;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrConfigSettingEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrConfigSettingEntry.decode(input);

      expect(decoded.configSettingID.value, equals(XdrConfigSettingID.CONFIG_SETTING_LIVE_SOROBAN_STATE_SIZE_WINDOW.value));
      expect(decoded.liveSorobanStateSizeWindow, isNotNull);
      expect(decoded.liveSorobanStateSizeWindow!.length, equals(3));
      expect(decoded.liveSorobanStateSizeWindow![0].uint64, equals(BigInt.from(1000)));
    });

    test('XdrConfigSettingEntry BUCKETLIST_SIZE_WINDOW empty list encode/decode', () {
      var original = XdrConfigSettingEntry(XdrConfigSettingID.CONFIG_SETTING_LIVE_SOROBAN_STATE_SIZE_WINDOW);
      original.liveSorobanStateSizeWindow = [];

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrConfigSettingEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrConfigSettingEntry.decode(input);

      expect(decoded.configSettingID.value, equals(XdrConfigSettingID.CONFIG_SETTING_LIVE_SOROBAN_STATE_SIZE_WINDOW.value));
      expect(decoded.liveSorobanStateSizeWindow, isNotNull);
      expect(decoded.liveSorobanStateSizeWindow!.length, equals(0));
    });

    test('XdrConfigSettingEntry BUCKETLIST_SIZE_WINDOW single element encode/decode', () {
      var window = [XdrUint64(BigInt.from(5000))];

      var original = XdrConfigSettingEntry(XdrConfigSettingID.CONFIG_SETTING_LIVE_SOROBAN_STATE_SIZE_WINDOW);
      original.liveSorobanStateSizeWindow = window;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrConfigSettingEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrConfigSettingEntry.decode(input);

      expect(decoded.configSettingID.value, equals(XdrConfigSettingID.CONFIG_SETTING_LIVE_SOROBAN_STATE_SIZE_WINDOW.value));
      expect(decoded.liveSorobanStateSizeWindow!.length, equals(1));
      expect(decoded.liveSorobanStateSizeWindow![0].uint64, equals(BigInt.from(5000)));
    });

    test('XdrConfigSettingEntry BUCKETLIST_SIZE_WINDOW large values encode/decode', () {
      var window = [
        XdrUint64(BigInt.from(999999999)),
        XdrUint64(BigInt.from(888888888)),
        XdrUint64(BigInt.from(777777777)),
        XdrUint64(BigInt.from(666666666)),
        XdrUint64(BigInt.from(555555555)),
      ];

      var original = XdrConfigSettingEntry(XdrConfigSettingID.CONFIG_SETTING_LIVE_SOROBAN_STATE_SIZE_WINDOW);
      original.liveSorobanStateSizeWindow = window;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrConfigSettingEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrConfigSettingEntry.decode(input);

      expect(decoded.configSettingID.value, equals(XdrConfigSettingID.CONFIG_SETTING_LIVE_SOROBAN_STATE_SIZE_WINDOW.value));
      expect(decoded.liveSorobanStateSizeWindow!.length, equals(5));
      expect(decoded.liveSorobanStateSizeWindow![2].uint64, equals(BigInt.from(777777777)));
    });

    test('XdrClaimPredicate NOT with valid inner predicate encode/decode', () {
      var innerPredicate = XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME);
      innerPredicate.absBefore = XdrInt64(BigInt.from(1800000000));

      var original = XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_NOT);
      original.notPredicate = innerPredicate;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrClaimPredicate.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrClaimPredicate.decode(input);

      expect(decoded.discriminant.value, equals(XdrClaimPredicateType.CLAIM_PREDICATE_NOT.value));
      expect(decoded.notPredicate, isNotNull);
      expect(decoded.notPredicate!.absBefore!.int64, equals(BigInt.from(1800000000)));
    });

    test('XdrClaimPredicate nested AND with multiple levels encode/decode', () {
      var innerAnd1 = XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_UNCONDITIONAL);
      var innerAnd2 = XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_BEFORE_RELATIVE_TIME);
      innerAnd2.relBefore = XdrInt64(BigInt.from(7200));

      var nestedAnd = XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_AND);
      nestedAnd.andPredicates = [innerAnd1, innerAnd2];

      var timeCondition = XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME);
      timeCondition.absBefore = XdrInt64(BigInt.from(2000000000));

      var original = XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_AND);
      original.andPredicates = [nestedAnd, timeCondition];

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrClaimPredicate.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrClaimPredicate.decode(input);

      expect(decoded.discriminant.value, equals(XdrClaimPredicateType.CLAIM_PREDICATE_AND.value));
      expect(decoded.andPredicates!.length, equals(2));
      expect(decoded.andPredicates![0].discriminant.value, equals(XdrClaimPredicateType.CLAIM_PREDICATE_AND.value));
    });

    test('XdrClaimPredicate nested OR with NOT encode/decode', () {
      var notInner = XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME);
      notInner.absBefore = XdrInt64(BigInt.from(1500000000));

      var notPredicate = XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_NOT);
      notPredicate.notPredicate = notInner;

      var unconditional = XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_UNCONDITIONAL);

      var original = XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_OR);
      original.orPredicates = [notPredicate, unconditional];

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrClaimPredicate.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrClaimPredicate.decode(input);

      expect(decoded.discriminant.value, equals(XdrClaimPredicateType.CLAIM_PREDICATE_OR.value));
      expect(decoded.orPredicates!.length, equals(2));
      expect(decoded.orPredicates![0].discriminant.value, equals(XdrClaimPredicateType.CLAIM_PREDICATE_NOT.value));
    });

    test('XdrClaimPredicate empty AND predicates encode/decode', () {
      var original = XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_AND);
      original.andPredicates = [];

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrClaimPredicate.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrClaimPredicate.decode(input);

      expect(decoded.discriminant.value, equals(XdrClaimPredicateType.CLAIM_PREDICATE_AND.value));
      expect(decoded.andPredicates!.length, equals(0));
    });

    test('XdrClaimPredicate empty OR predicates encode/decode', () {
      var original = XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_OR);
      original.orPredicates = [];

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrClaimPredicate.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrClaimPredicate.decode(input);

      expect(decoded.discriminant.value, equals(XdrClaimPredicateType.CLAIM_PREDICATE_OR.value));
      expect(decoded.orPredicates!.length, equals(0));
    });

    test('XdrLedgerEntry with CONTRACT_DATA encode/decode', () {
      var contractIdBytes = Uint8List.fromList(List<int>.filled(32, 0xAB));
      var contractIdHex = Util.bytesToHex(contractIdBytes);
      var contractId = XdrSCAddress.forContractId(contractIdHex);
      var key = XdrSCVal.forBytes(Uint8List.fromList([0x11, 0x22, 0x33, 0x44]));
      var val = XdrSCVal.forString('testvalue');
      var durability = XdrContractDataDurability.TEMPORARY;

      var contractData = XdrContractDataEntry(
        XdrExtensionPoint(0),
        contractId,
        key,
        durability,
        val,
      );

      var data = XdrLedgerEntryData(XdrLedgerEntryType.CONTRACT_DATA);
      data.contractData = contractData;

      var entry = XdrLedgerEntry(
        XdrUint32(500),
        data,
        XdrLedgerEntryExt(0),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerEntry.encode(output, entry);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerEntry.decode(input);

      expect(decoded.lastModifiedLedgerSeq.uint32, equals(500));
      expect(decoded.data.discriminant.value, equals(XdrLedgerEntryType.CONTRACT_DATA.value));
      expect(decoded.data.contractData!.durability.value, equals(XdrContractDataDurability.TEMPORARY.value));
    });

    test('XdrLedgerEntry with TTL encode/decode', () {
      var keyHash = XdrHash(Uint8List.fromList(List<int>.filled(32, 0x99)));
      var ttl = XdrTTLEntry(keyHash, XdrUint32(500000));

      var data = XdrLedgerEntryData(XdrLedgerEntryType.TTL);
      data.expiration = ttl;

      var entry = XdrLedgerEntry(
        XdrUint32(600),
        data,
        XdrLedgerEntryExt(0),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerEntry.encode(output, entry);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerEntry.decode(input);

      expect(decoded.lastModifiedLedgerSeq.uint32, equals(600));
      expect(decoded.data.discriminant.value, equals(XdrLedgerEntryType.TTL.value));
      expect(decoded.data.expiration!.liveUntilLedgerSeq.uint32, equals(500000));
    });

    test('XdrLedgerKey CONFIG_SETTING with different ID encode/decode', () {
      var configSettingId = XdrConfigSettingID.CONFIG_SETTING_STATE_ARCHIVAL;

      var original = XdrLedgerKey(XdrLedgerEntryType.CONFIG_SETTING);
      original.configSetting = configSettingId;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerKey.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerKey.decode(input);

      expect(decoded.discriminant.value, equals(XdrLedgerEntryType.CONFIG_SETTING.value));
      expect(decoded.configSetting, isNotNull);
      expect(decoded.configSetting!.value, equals(XdrConfigSettingID.CONFIG_SETTING_STATE_ARCHIVAL.value));
    });

    test('XdrLedgerEntryChanges with single CREATED change encode/decode', () {
      var accountId = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var data = XdrLedgerEntryData(XdrLedgerEntryType.DATA);
      var dataEntry = XdrDataEntry(
        accountId,
        XdrString64('name'),
        XdrDataValue(Uint8List.fromList([0xAA, 0xBB])),
        XdrDataEntryExt(0),
      );
      data.data = dataEntry;

      var change = XdrLedgerEntryChange(XdrLedgerEntryChangeType.LEDGER_ENTRY_CREATED);
      change.created = XdrLedgerEntry(XdrUint32(10), data, XdrLedgerEntryExt(0));

      var original = XdrLedgerEntryChanges([change]);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerEntryChanges.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerEntryChanges.decode(input);

      expect(decoded.ledgerEntryChanges.length, equals(1));
      expect(decoded.ledgerEntryChanges[0].discriminant.value, equals(XdrLedgerEntryChangeType.LEDGER_ENTRY_CREATED.value));
    });

    test('XdrOfferEntry complete encode/decode', () {
      var sellerId = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var selling = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var buying = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);

      var offer = XdrOfferEntry(
        sellerId,
        XdrUint64(BigInt.from(12345)),
        selling,
        buying,
        XdrInt64(BigInt.from(50000)),
        XdrPrice(XdrInt32(10), XdrInt32(1)),
        XdrUint32(5),
        XdrOfferEntryExt(0),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOfferEntry.encode(output, offer);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOfferEntry.decode(input);

      expect(decoded.offerID.uint64, equals(BigInt.from(12345)));
      expect(decoded.amount.int64, equals(BigInt.from(50000)));
      expect(decoded.flags.uint32, equals(5));
    });

    test('XdrDataEntry with long key encode/decode', () {
      var accountId = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var data = XdrDataEntry(
        accountId,
        XdrString64('thisIsAVeryLongKeyNameForTestingPurposes'),
        XdrDataValue(Uint8List.fromList([0x01, 0x02, 0x03, 0x04, 0x05])),
        XdrDataEntryExt(0),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrDataEntry.encode(output, data);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrDataEntry.decode(input);

      expect(decoded.dataName.string64, equals('thisIsAVeryLongKeyNameForTestingPurposes'));
      expect(decoded.dataValue.dataValue.length, equals(5));
    });

    test('XdrClaimableBalanceEntry with multiple claimants encode/decode', () {
      var balanceId = XdrClaimableBalanceID(XdrClaimableBalanceIDType.CLAIMABLE_BALANCE_ID_TYPE_V0);
      balanceId.v0 = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xCC)));

      var accountId1 = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var predicate1 = XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_UNCONDITIONAL);
      var claimant1 = XdrClaimant(XdrClaimantType.CLAIMANT_TYPE_V0);
      claimant1.v0 = XdrClaimantV0(accountId1, predicate1);

      var accountId2 = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var predicate2 = XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME);
      predicate2.absBefore = XdrInt64(BigInt.from(3000000000));
      var claimant2 = XdrClaimant(XdrClaimantType.CLAIMANT_TYPE_V0);
      claimant2.v0 = XdrClaimantV0(accountId2, predicate2);

      var accountId3 = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var predicate3 = XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_BEFORE_RELATIVE_TIME);
      predicate3.relBefore = XdrInt64(BigInt.from(604800));
      var claimant3 = XdrClaimant(XdrClaimantType.CLAIMANT_TYPE_V0);
      claimant3.v0 = XdrClaimantV0(accountId3, predicate3);

      var claimableBalance = XdrClaimableBalanceEntry(
        balanceId,
        [claimant1, claimant2, claimant3],
        XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE),
        XdrInt64(BigInt.from(10000000)),
        XdrClaimableBalanceEntryExt(0),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrClaimableBalanceEntry.encode(output, claimableBalance);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrClaimableBalanceEntry.decode(input);

      expect(decoded.claimants.length, equals(3));
      expect(decoded.amount.int64, equals(BigInt.from(10000000)));
    });

    test('XdrLiquidityPoolEntry with different parameters encode/decode', () {
      var poolId = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xDD)));
      var body = XdrLiquidityPoolBody(XdrLiquidityPoolType.LIQUIDITY_POOL_CONSTANT_PRODUCT);
      var constantProduct = XdrConstantProduct(
        XdrLiquidityPoolConstantProductParameters(
          XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE),
          XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE),
          XdrInt32(50),
        ),
        XdrInt64(BigInt.from(500000)),
        XdrInt64(BigInt.from(600000)),
        XdrInt64(BigInt.from(550000)),
        XdrInt64(BigInt.from(25000)),
      );
      body.constantProduct = constantProduct;

      var liquidityPool = XdrLiquidityPoolEntry(poolId, body);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLiquidityPoolEntry.encode(output, liquidityPool);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLiquidityPoolEntry.decode(input);

      expect(decoded.body.discriminant.value, equals(XdrLiquidityPoolType.LIQUIDITY_POOL_CONSTANT_PRODUCT.value));
      expect(decoded.body.constantProduct!.params.fee.int32, equals(50));
    });

    test('XdrContractCodeEntry with different code encode/decode', () {
      var ext = XdrContractCodeEntryExt(0);
      var hash = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xEE)));
      var code = Uint8List.fromList([
        0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00,
        0x01, 0x04, 0x01, 0x60, 0x00, 0x00, 0x03, 0x02
      ]);

      var contractCode = XdrContractCodeEntry(ext, hash, XdrDataValue(code));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrContractCodeEntry.encode(output, contractCode);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrContractCodeEntry.decode(input);

      expect(decoded.code.dataValue.length, equals(16));
      expect(decoded.ext.discriminant, equals(0));
    });

    test('XdrTTLEntry with large ledger seq encode/decode', () {
      var keyHash = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xFF)));
      var ttl = XdrTTLEntry(keyHash, XdrUint32(9999999));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTTLEntry.encode(output, ttl);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTTLEntry.decode(input);

      expect(decoded.liveUntilLedgerSeq.uint32, equals(9999999));
    });

    test('XdrContractDataEntry with complex SCVal encode/decode', () {
      var contractIdBytes = Uint8List.fromList(List<int>.filled(32, 0x11));
      var contractIdHex = Util.bytesToHex(contractIdBytes);
      var contractId = XdrSCAddress.forContractId(contractIdHex);

      var keyMapEntries = [
        XdrSCMapEntry(XdrSCVal.forSymbol('key1'), XdrSCVal.forU32(100)),
        XdrSCMapEntry(XdrSCVal.forSymbol('key2'), XdrSCVal.forU32(200)),
      ];
      var key = XdrSCVal.forMap(keyMapEntries);

      var valVec = [
        XdrSCVal.forI32(10),
        XdrSCVal.forI32(20),
        XdrSCVal.forI32(30),
      ];
      var val = XdrSCVal.forVec(valVec);
      var durability = XdrContractDataDurability.PERSISTENT;

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

      expect(decoded.durability.value, equals(XdrContractDataDurability.PERSISTENT.value));
      expect(decoded.val.vec, isNotNull);
    });

    test('XdrStateArchivalSettings with various values encode/decode', () {
      var original = XdrStateArchivalSettings(
        XdrUint32(10000),
        XdrUint32(1000),
        XdrUint32(50000),
        XdrInt64(BigInt.from(25000)),
        XdrInt64(BigInt.from(2500)),
        XdrUint32(100),
        XdrUint32(100000),
        XdrUint32(5000),
        XdrUint32(5000),
        XdrUint32(500),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrStateArchivalSettings.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrStateArchivalSettings.decode(input);

      expect(decoded.maxEntryTTL.uint32, equals(10000));
      expect(decoded.minTemporaryTTL.uint32, equals(1000));
      expect(decoded.minPersistentTTL.uint32, equals(50000));
    });

    test('XdrContractCodeCostInputs with different values encode/decode', () {
      var original = XdrContractCodeCostInputs(
        XdrExtensionPoint(0),
        XdrInt32(10000),
        XdrInt32(5000),
        XdrInt32(1000),
        XdrInt32(500),
        XdrInt32(100),
        XdrInt32(50),
        XdrInt32(2000),
        XdrInt32(3000),
        XdrInt32(4000),
        XdrInt32(5000),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrContractCodeCostInputs.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrContractCodeCostInputs.decode(input);

      expect(decoded.nInstructions.int32, equals(10000));
      expect(decoded.nFunctions.int32, equals(5000));
      expect(decoded.nGlobals.int32, equals(1000));
    });

    test('XdrConfigUpgradeSetKey with different hashes encode/decode', () {
      var contractID = XdrHash(Uint8List.fromList(List<int>.generate(32, (i) => i)));
      var contentHash = XdrHash(Uint8List.fromList(List<int>.generate(32, (i) => 31 - i)));

      var original = XdrConfigUpgradeSetKey(contractID, contentHash);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrConfigUpgradeSetKey.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrConfigUpgradeSetKey.decode(input);

      expect(decoded.contractID.hash[0], equals(0));
      expect(decoded.contractID.hash[31], equals(31));
      expect(decoded.contentHash.hash[0], equals(31));
    });

    test('XdrConfigSettingContractLedgerCostV0 with different values encode/decode', () {
      var original = XdrConfigSettingContractLedgerCostV0(
        XdrUint32(5000),
        XdrUint32(2500),
        XdrUint32(10000),
        XdrUint32(7500),
        XdrUint32(500),
        XdrUint32(250),
        XdrUint32(1000),
        XdrUint32(750),
        XdrInt64(BigInt.from(5000)),
        XdrInt64(BigInt.from(500)),
        XdrInt64(BigInt.from(5000)),
        XdrInt64(BigInt.from(500)),
        XdrInt64(BigInt.from(5000)),
        XdrInt64(BigInt.from(500)),
        XdrUint32(50),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrConfigSettingContractLedgerCostV0.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrConfigSettingContractLedgerCostV0.decode(input);

      expect(decoded.ledgerMaxDiskReadEntries.uint32, equals(5000));
      expect(decoded.ledgerMaxDiskReadBytes.uint32, equals(2500));
      expect(decoded.txMaxDiskReadEntries.uint32, equals(500));
    });

    test('XdrEvictionIterator with different bucket levels encode/decode', () {
      var original = XdrEvictionIterator(
        XdrUint32(15),
        false,
        XdrUint64(BigInt.from(987654321)),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrEvictionIterator.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrEvictionIterator.decode(input);

      expect(decoded.bucketListLevel.uint32, equals(15));
      expect(decoded.isCurrBucket, equals(false));
      expect(decoded.bucketFileOffset.uint64, equals(BigInt.from(987654321)));
    });

    test('XdrConfigSettingSCPTiming with different timings encode/decode', () {
      var original = XdrConfigSettingSCPTiming(
        XdrUint32(5000),
        XdrUint32(10000),
        XdrUint32(15000),
        XdrUint32(20000),
        XdrUint32(25000),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrConfigSettingSCPTiming.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrConfigSettingSCPTiming.decode(input);

      expect(decoded.ledgerTargetCloseTimeMilliseconds.uint32, equals(5000));
      expect(decoded.nominationTimeoutInitialMilliseconds.uint32, equals(10000));
    });

    test('XdrAccountEntry with multiple signers encode/decode', () {
      var accountId = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');

      var signerKey1 = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519);
      signerKey1.ed25519 = XdrUint256(KeyPair.fromAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H').publicKey);
      var signer1 = XdrSigner(signerKey1, XdrUint32(10));

      var signerKey2 = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519);
      signerKey2.ed25519 = XdrUint256(KeyPair.fromAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H').publicKey);
      var signer2 = XdrSigner(signerKey2, XdrUint32(5));

      var account = XdrAccountEntry(
        accountId,
        XdrInt64(BigInt.from(200000000)),
        XdrSequenceNumber(XdrBigInt64(BigInt.from(100))),
        XdrUint32(5),
        accountId,
        XdrUint32(10),
        XdrString32('memo'),
        XdrThresholds(Uint8List.fromList([2, 3, 4, 5])),
        [signer1, signer2],
        XdrAccountEntryExt(0),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrAccountEntry.encode(output, account);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrAccountEntry.decode(input);

      expect(decoded.signers.length, equals(2));
      expect(decoded.signers[0].weight.uint32, equals(10));
      expect(decoded.signers[1].weight.uint32, equals(5));
    });

    test('XdrTrustLineEntry with limit encode/decode', () {
      var accountId = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var asset = XdrTrustlineAsset.fromXdrAsset(XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE));
      var trustLine = XdrTrustLineEntry(
        accountId,
        asset,
        XdrInt64(BigInt.from(100000000)),
        XdrInt64(BigInt.from(50000000)),
        XdrUint32(7),
        XdrTrustLineEntryExt(0),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTrustLineEntry.encode(output, trustLine);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTrustLineEntry.decode(input);

      expect(decoded.balance.int64, equals(BigInt.from(100000000)));
      expect(decoded.limit.int64, equals(BigInt.from(50000000)));
      expect(decoded.flags.uint32, equals(7));
    });

    test('XdrLedgerHeader with different ledger version encode/decode', () {
      var stellarValue = XdrStellarValue(
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0x66))),
        XdrUint64(BigInt.from(444444)),
        [],
        XdrStellarValueExt(0),
      );

      var ledgerHeader = XdrLedgerHeader(
        XdrUint32(22),
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0x77))),
        stellarValue,
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0x88))),
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0x99))),
        XdrUint32(1000),
        XdrInt64(BigInt.from(100000000)),
        XdrInt64(BigInt.from(1000)),
        XdrUint32(10000),
        XdrUint64(BigInt.from(10000)),
        XdrUint32(200),
        XdrUint32(25000000),
        XdrUint32(10000),
        List<XdrHash>.generate(4, (i) => XdrHash(Uint8List.fromList(List<int>.filled(32, 0xAA + i)))),
        XdrLedgerHeaderExt(0),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerHeader.encode(output, ledgerHeader);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerHeader.decode(input);

      expect(decoded.ledgerVersion.uint32, equals(22));
      expect(decoded.ledgerSeq.uint32, equals(1000));
    });

    test('XdrLedgerHeaderHistoryEntry complete encode/decode', () {
      var hash = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xC1)));

      var stellarValue = XdrStellarValue(
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0xC2))),
        XdrUint64(BigInt.from(666666)),
        [],
        XdrStellarValueExt(0),
      );

      var header = XdrLedgerHeader(
        XdrUint32(21),
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0xC3))),
        stellarValue,
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0xC4))),
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0xC5))),
        XdrUint32(1500),
        XdrInt64(BigInt.from(150000000)),
        XdrInt64(BigInt.from(1500)),
        XdrUint32(15000),
        XdrUint64(BigInt.from(15000)),
        XdrUint32(200),
        XdrUint32(30000000),
        XdrUint32(15000),
        List<XdrHash>.generate(4, (i) => XdrHash(Uint8List.fromList(List<int>.filled(32, 0xC6 + i)))),
        XdrLedgerHeaderExt(0),
      );

      var entry = XdrLedgerHeaderHistoryEntry(
        hash,
        header,
        XdrLedgerHeaderHistoryEntryExt(0),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerHeaderHistoryEntry.encode(output, entry);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerHeaderHistoryEntry.decode(input);

      expect(decoded.header.ledgerSeq.uint32, equals(1500));
    });

    test('XdrStellarValue with multiple upgrades encode/decode', () {
      var upgrade1 = XdrUpgradeType(Uint8List.fromList([0x10, 0x20, 0x30, 0x40]));
      var upgrade2 = XdrUpgradeType(Uint8List.fromList([0x50, 0x60, 0x70, 0x80]));
      var upgrade3 = XdrUpgradeType(Uint8List.fromList([0x90, 0xA0, 0xB0, 0xC0]));

      var original = XdrStellarValue(
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0xD1))),
        XdrUint64(BigInt.from(111111)),
        [upgrade1, upgrade2, upgrade3],
        XdrStellarValueExt(0),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrStellarValue.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrStellarValue.decode(input);

      expect(decoded.closeTime.uint64, equals(BigInt.from(111111)));
      expect(decoded.upgrades.length, equals(3));
    });

    test('XdrLiabilities with large values encode/decode', () {
      var original = XdrLiabilities(
        XdrInt64(BigInt.from(999999999)),
        XdrInt64(BigInt.from(888888888)),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLiabilities.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLiabilities.decode(input);

      expect(decoded.buying.int64, equals(BigInt.from(999999999)));
      expect(decoded.selling.int64, equals(BigInt.from(888888888)));
    });

    test('XdrAccountEntryV2 with mixed sponsor IDs encode/decode', () {
      var sponsor1 = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');

      var original = XdrAccountEntryV2(
        XdrUint32(2),
        XdrUint32(1),
        [sponsor1, null],
        XdrAccountEntryV2Ext(0),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrAccountEntryV2.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrAccountEntryV2.decode(input);

      expect(decoded.numSponsored.uint32, equals(2));
      expect(decoded.signerSponsoringIDs.length, equals(2));
      expect(decoded.signerSponsoringIDs[0], isNotNull);
      expect(decoded.signerSponsoringIDs[1], isNull);
    });

    test('XdrContractCostParams with many entries encode/decode', () {
      var entries = List.generate(10, (i) => XdrContractCostParamEntry(
        XdrExtensionPoint(0),
        XdrInt64(BigInt.from(1000 + i * 100)),
        XdrInt64(BigInt.from(100 + i * 10)),
      ));

      var original = XdrContractCostParams(entries);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrContractCostParams.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrContractCostParams.decode(input);

      expect(decoded.entries.length, equals(10));
      expect(decoded.entries[5].constTerm.int64, equals(BigInt.from(1500)));
    });

    test('XdrConstantProduct with different reserve amounts encode/decode', () {
      var constantProduct = XdrConstantProduct(
        XdrLiquidityPoolConstantProductParameters(
          XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE),
          XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE),
          XdrInt32(25),
        ),
        XdrInt64(BigInt.from(111111)),
        XdrInt64(BigInt.from(222222)),
        XdrInt64(BigInt.from(166666)),
        XdrInt64(BigInt.from(12345)),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrConstantProduct.encode(output, constantProduct);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrConstantProduct.decode(input);

      expect(decoded.reserveA.int64, equals(BigInt.from(111111)));
      expect(decoded.reserveB.int64, equals(BigInt.from(222222)));
      expect(decoded.totalPoolShares.int64, equals(BigInt.from(166666)));
      expect(decoded.poolSharesTrustLineCount.int64, equals(BigInt.from(12345)));
    });
  });
}
