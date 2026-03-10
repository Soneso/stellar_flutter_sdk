// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('XDR Ledger Types - Deep Branch Testing Round 4', () {
    test('XdrConfigSettingEntry BUCKETLIST_SIZE_WINDOW empty list encode/decode', () {
      var original = XdrConfigSettingEntry(XdrConfigSettingID.CONFIG_SETTING_LIVE_SOROBAN_STATE_SIZE_WINDOW);
      original.liveSorobanStateSizeWindow = [];

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrConfigSettingEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrConfigSettingEntry.decode(input);

      expect(decoded.discriminant.value, equals(XdrConfigSettingID.CONFIG_SETTING_LIVE_SOROBAN_STATE_SIZE_WINDOW.value));
      expect(decoded.liveSorobanStateSizeWindow, isNotNull);
      expect(decoded.liveSorobanStateSizeWindow!.length, equals(0));
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
        XdrSequenceNumber(BigInt.from(100)),
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

    test('XdrStellarValue with multiple upgrades encode/decode', () {
      var upgrade1 = XdrUpgradeType(Uint8List.fromList([0x10, 0x20, 0x30, 0x40]));
      var upgrade2 = XdrUpgradeType(Uint8List.fromList([0x50, 0x60, 0x70, 0x80]));
      var upgrade3 = XdrUpgradeType(Uint8List.fromList([0x90, 0xA0, 0xB0, 0xC0]));

      var original = XdrStellarValue(
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0xD1))),
        XdrUint64(BigInt.from(111111)),
        [upgrade1, upgrade2, upgrade3],
        XdrStellarValueExt(XdrStellarValueType.STELLAR_VALUE_BASIC),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrStellarValue.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrStellarValue.decode(input);

      expect(decoded.closeTime.uint64, equals(BigInt.from(111111)));
      expect(decoded.upgrades.length, equals(3));
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

      expect(decoded.contractCostParams.length, equals(10));
      expect(decoded.contractCostParams[5].constTerm.int64, equals(BigInt.from(1500)));
    });
  });
}
