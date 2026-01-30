// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('XDR Ledger Types - Deep Branch Testing', () {
    test('XdrLedgerEntryType enum all variants', () {
      final types = [
        XdrLedgerEntryType.ACCOUNT,
        XdrLedgerEntryType.TRUSTLINE,
        XdrLedgerEntryType.OFFER,
        XdrLedgerEntryType.DATA,
        XdrLedgerEntryType.CLAIMABLE_BALANCE,
        XdrLedgerEntryType.LIQUIDITY_POOL,
        XdrLedgerEntryType.CONTRACT_DATA,
        XdrLedgerEntryType.CONTRACT_CODE,
        XdrLedgerEntryType.CONFIG_SETTING,
        XdrLedgerEntryType.TTL,
      ];

      for (var type in types) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrLedgerEntryType.encode(output, type);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrLedgerEntryType.decode(input);

        expect(decoded.value, equals(type.value));
      }
    });

    test('XdrLedgerEntryChangeType enum all variants', () {
      final types = [
        XdrLedgerEntryChangeType.LEDGER_ENTRY_CREATED,
        XdrLedgerEntryChangeType.LEDGER_ENTRY_UPDATED,
        XdrLedgerEntryChangeType.LEDGER_ENTRY_REMOVED,
        XdrLedgerEntryChangeType.LEDGER_ENTRY_STATE,
        XdrLedgerEntryChangeType.LEDGER_ENTRY_RESTORED,
      ];

      for (var type in types) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrLedgerEntryChangeType.encode(output, type);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrLedgerEntryChangeType.decode(input);

        expect(decoded.value, equals(type.value));
      }
    });

    test('XdrClaimPredicateType enum all variants', () {
      final types = [
        XdrClaimPredicateType.CLAIM_PREDICATE_UNCONDITIONAL,
        XdrClaimPredicateType.CLAIM_PREDICATE_AND,
        XdrClaimPredicateType.CLAIM_PREDICATE_OR,
        XdrClaimPredicateType.CLAIM_PREDICATE_NOT,
        XdrClaimPredicateType.CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME,
        XdrClaimPredicateType.CLAIM_PREDICATE_BEFORE_RELATIVE_TIME,
      ];

      for (var type in types) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrClaimPredicateType.encode(output, type);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrClaimPredicateType.decode(input);

        expect(decoded.value, equals(type.value));
      }
    });

    test('XdrClaimPredicate UNCONDITIONAL encode/decode', () {
      var original = XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_UNCONDITIONAL);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrClaimPredicate.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrClaimPredicate.decode(input);

      expect(decoded.discriminant.value, equals(XdrClaimPredicateType.CLAIM_PREDICATE_UNCONDITIONAL.value));
    });

    test('XdrClaimPredicate AND encode/decode', () {
      var predicate1 = XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_UNCONDITIONAL);
      var predicate2 = XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_UNCONDITIONAL);

      var original = XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_AND);
      original.andPredicates = [predicate1, predicate2];

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrClaimPredicate.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrClaimPredicate.decode(input);

      expect(decoded.discriminant.value, equals(XdrClaimPredicateType.CLAIM_PREDICATE_AND.value));
      expect(decoded.andPredicates, isNotNull);
      expect(decoded.andPredicates!.length, equals(2));
    });

    test('XdrClaimPredicate OR encode/decode', () {
      var predicate1 = XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_UNCONDITIONAL);
      var predicate2 = XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_UNCONDITIONAL);

      var original = XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_OR);
      original.orPredicates = [predicate1, predicate2];

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrClaimPredicate.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrClaimPredicate.decode(input);

      expect(decoded.discriminant.value, equals(XdrClaimPredicateType.CLAIM_PREDICATE_OR.value));
      expect(decoded.orPredicates, isNotNull);
      expect(decoded.orPredicates!.length, equals(2));
    });

    test('XdrClaimPredicate NOT encode/decode', () {
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

    test('XdrClaimPredicate BEFORE_ABSOLUTE_TIME encode/decode', () {
      var original = XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME);
      original.absBefore = XdrInt64(BigInt.from(1234567890));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrClaimPredicate.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrClaimPredicate.decode(input);

      expect(decoded.discriminant.value, equals(XdrClaimPredicateType.CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME.value));
      expect(decoded.absBefore, isNotNull);
      expect(decoded.absBefore!.int64, equals(BigInt.from(1234567890)));
    });

    test('XdrClaimPredicate BEFORE_RELATIVE_TIME encode/decode', () {
      var original = XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_BEFORE_RELATIVE_TIME);
      original.relBefore = XdrInt64(BigInt.from(3600));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrClaimPredicate.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrClaimPredicate.decode(input);

      expect(decoded.discriminant.value, equals(XdrClaimPredicateType.CLAIM_PREDICATE_BEFORE_RELATIVE_TIME.value));
      expect(decoded.relBefore, isNotNull);
      expect(decoded.relBefore!.int64, equals(BigInt.from(3600)));
    });

    test('XdrClaimableBalanceID CLAIMABLE_BALANCE_ID_TYPE_V0 encode/decode', () {
      var original = XdrClaimableBalanceID(XdrClaimableBalanceIDType.CLAIMABLE_BALANCE_ID_TYPE_V0);
      original.v0 = XdrHash(Uint8List.fromList(List<int>.filled(32, 0x88)));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrClaimableBalanceID.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrClaimableBalanceID.decode(input);

      expect(decoded.discriminant.value, equals(XdrClaimableBalanceIDType.CLAIMABLE_BALANCE_ID_TYPE_V0.value));
      expect(decoded.v0, isNotNull);
      expect(decoded.v0!.hash, equals(original.v0!.hash));
    });

    test('XdrLiquidityPoolType LIQUIDITY_POOL_CONSTANT_PRODUCT encode/decode', () {
      var type = XdrLiquidityPoolType.LIQUIDITY_POOL_CONSTANT_PRODUCT;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLiquidityPoolType.encode(output, type);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLiquidityPoolType.decode(input);

      expect(decoded.value, equals(type.value));
    });

    test('XdrLiquidityPoolParameters LIQUIDITY_POOL_CONSTANT_PRODUCT encode/decode', () {
      var constantProduct = XdrLiquidityPoolConstantProductParameters(
        XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE),
        XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE),
        XdrInt32(30),
      );

      var original = XdrLiquidityPoolParameters(XdrLiquidityPoolType.LIQUIDITY_POOL_CONSTANT_PRODUCT);
      original.constantProduct = constantProduct;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLiquidityPoolParameters.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLiquidityPoolParameters.decode(input);

      expect(decoded.discriminant.value, equals(XdrLiquidityPoolType.LIQUIDITY_POOL_CONSTANT_PRODUCT.value));
      expect(decoded.constantProduct, isNotNull);
      expect(decoded.constantProduct!.fee.int32, equals(30));
    });

    test('XdrLedgerUpgradeType enum all variants', () {
      final types = [
        XdrLedgerUpgradeType.LEDGER_UPGRADE_VERSION,
        XdrLedgerUpgradeType.LEDGER_UPGRADE_BASE_FEE,
        XdrLedgerUpgradeType.LEDGER_UPGRADE_MAX_TX_SET_SIZE,
        XdrLedgerUpgradeType.LEDGER_UPGRADE_BASE_RESERVE,
        XdrLedgerUpgradeType.LEDGER_UPGRADE_FLAGS,
        XdrLedgerUpgradeType.LEDGER_UPGRADE_CONFIG,
        XdrLedgerUpgradeType.LEDGER_UPGRADE_MAX_SOROBAN_TX_SET_SIZE,
      ];

      for (var type in types) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrLedgerUpgradeType.encode(output, type);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrLedgerUpgradeType.decode(input);

        expect(decoded.value, equals(type.value));
      }
    });

    test('XdrLedgerUpgrade LEDGER_UPGRADE_VERSION encode/decode', () {
      var original = XdrLedgerUpgrade(XdrLedgerUpgradeType.LEDGER_UPGRADE_VERSION);
      original.newLedgerVersion = XdrUint32(21);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerUpgrade.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerUpgrade.decode(input);

      expect(decoded.discriminant.value, equals(XdrLedgerUpgradeType.LEDGER_UPGRADE_VERSION.value));
      expect(decoded.newLedgerVersion, isNotNull);
      expect(decoded.newLedgerVersion!.uint32, equals(21));
    });

    test('XdrLedgerUpgrade LEDGER_UPGRADE_BASE_FEE encode/decode', () {
      var original = XdrLedgerUpgrade(XdrLedgerUpgradeType.LEDGER_UPGRADE_BASE_FEE);
      original.newBaseFee = XdrUint32(100);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerUpgrade.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerUpgrade.decode(input);

      expect(decoded.discriminant.value, equals(XdrLedgerUpgradeType.LEDGER_UPGRADE_BASE_FEE.value));
      expect(decoded.newBaseFee, isNotNull);
      expect(decoded.newBaseFee!.uint32, equals(100));
    });

    test('XdrLedgerUpgrade LEDGER_UPGRADE_MAX_TX_SET_SIZE encode/decode', () {
      var original = XdrLedgerUpgrade(XdrLedgerUpgradeType.LEDGER_UPGRADE_MAX_TX_SET_SIZE);
      original.newMaxTxSetSize = XdrUint32(1000);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerUpgrade.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerUpgrade.decode(input);

      expect(decoded.discriminant.value, equals(XdrLedgerUpgradeType.LEDGER_UPGRADE_MAX_TX_SET_SIZE.value));
      expect(decoded.newMaxTxSetSize, isNotNull);
      expect(decoded.newMaxTxSetSize!.uint32, equals(1000));
    });

    test('XdrLedgerUpgrade LEDGER_UPGRADE_BASE_RESERVE encode/decode', () {
      var original = XdrLedgerUpgrade(XdrLedgerUpgradeType.LEDGER_UPGRADE_BASE_RESERVE);
      original.newBaseReserve = XdrUint32(5000000);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerUpgrade.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerUpgrade.decode(input);

      expect(decoded.discriminant.value, equals(XdrLedgerUpgradeType.LEDGER_UPGRADE_BASE_RESERVE.value));
      expect(decoded.newBaseReserve, isNotNull);
      expect(decoded.newBaseReserve!.uint32, equals(5000000));
    });

    test('XdrLedgerUpgrade LEDGER_UPGRADE_FLAGS encode/decode', () {
      var original = XdrLedgerUpgrade(XdrLedgerUpgradeType.LEDGER_UPGRADE_FLAGS);
      original.newFlags = XdrUint32(4);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerUpgrade.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerUpgrade.decode(input);

      expect(decoded.discriminant.value, equals(XdrLedgerUpgradeType.LEDGER_UPGRADE_FLAGS.value));
      expect(decoded.newFlags, isNotNull);
      expect(decoded.newFlags!.uint32, equals(4));
    });

    test('XdrLedgerUpgrade LEDGER_UPGRADE_MAX_SOROBAN_TX_SET_SIZE encode/decode', () {
      var original = XdrLedgerUpgrade(XdrLedgerUpgradeType.LEDGER_UPGRADE_MAX_SOROBAN_TX_SET_SIZE);
      original.newMaxSorobanTxSetSize = XdrUint32(100000);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerUpgrade.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerUpgrade.decode(input);

      expect(decoded.discriminant.value, equals(XdrLedgerUpgradeType.LEDGER_UPGRADE_MAX_SOROBAN_TX_SET_SIZE.value));
      expect(decoded.newMaxSorobanTxSetSize, isNotNull);
      expect(decoded.newMaxSorobanTxSetSize!.uint32, equals(100000));
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

    test('XdrLedgerEntryExt with discriminant 0 encode/decode', () {
      var original = XdrLedgerEntryExt(0);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerEntryExt.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerEntryExt.decode(input);

      expect(decoded.discriminant, equals(0));
    });


    test('XdrClaimantType CLAIMANT_TYPE_V0 encode/decode', () {
      var accountId = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var predicate = XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_UNCONDITIONAL);
      var v0 = XdrClaimantV0(accountId, predicate);

      var original = XdrClaimant(XdrClaimantType.CLAIMANT_TYPE_V0);
      original.v0 = v0;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrClaimant.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrClaimant.decode(input);

      expect(decoded.discriminant.value, equals(XdrClaimantType.CLAIMANT_TYPE_V0.value));
      expect(decoded.v0, isNotNull);
    });

    // NEW TESTS - XdrLedgerEntryData with all discriminants
    test('XdrLedgerEntryData ACCOUNT encode/decode', () {
      var accountId = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var signerKey = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519);
      signerKey.ed25519 = XdrUint256(KeyPair.fromAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H').publicKey);
      var signer = XdrSigner(signerKey, XdrUint32(1));

      var account = XdrAccountEntry(
        accountId,
        XdrInt64(BigInt.from(10000000)),
        XdrSequenceNumber(XdrBigInt64(BigInt.from(1))),
        XdrUint32(0),
        XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H'),
        XdrUint32(0),
        XdrString32(''),
        XdrThresholds(Uint8List.fromList([1, 1, 1, 1])),
        [signer],
        XdrAccountEntryExt(0),
      );

      var original = XdrLedgerEntryData(XdrLedgerEntryType.ACCOUNT);
      original.account = account;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerEntryData.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerEntryData.decode(input);

      expect(decoded.discriminant.value, equals(XdrLedgerEntryType.ACCOUNT.value));
      expect(decoded.account, isNotNull);
    });

    test('XdrLedgerEntryData TRUSTLINE encode/decode', () {
      var accountId = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var asset = XdrTrustlineAsset.fromXdrAsset(XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE));
      var trustLine = XdrTrustLineEntry(
        accountId,
        asset,
        XdrInt64(BigInt.from(1000000)),
        XdrInt64(BigInt.from(0)),
        XdrUint32(0),
        XdrTrustLineEntryExt(0),
      );

      var original = XdrLedgerEntryData(XdrLedgerEntryType.TRUSTLINE);
      original.trustLine = trustLine;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerEntryData.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerEntryData.decode(input);

      expect(decoded.discriminant.value, equals(XdrLedgerEntryType.TRUSTLINE.value));
      expect(decoded.trustLine, isNotNull);
    });

    test('XdrLedgerEntryData OFFER encode/decode', () {
      var sellerId = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var selling = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var buying = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var offer = XdrOfferEntry(
        sellerId,
        XdrUint64(BigInt.from(1)),
        selling,
        buying,
        XdrInt64(BigInt.from(1000)),
        XdrPrice(XdrInt32(1), XdrInt32(1)),
        XdrUint32(0),
        XdrOfferEntryExt(0),
      );

      var original = XdrLedgerEntryData(XdrLedgerEntryType.OFFER);
      original.offer = offer;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerEntryData.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerEntryData.decode(input);

      expect(decoded.discriminant.value, equals(XdrLedgerEntryType.OFFER.value));
      expect(decoded.offer, isNotNull);
    });

    test('XdrLedgerEntryData DATA encode/decode', () {
      var accountId = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var data = XdrDataEntry(
        accountId,
        XdrString64('testkey'),
        XdrDataValue(Uint8List.fromList([1, 2, 3, 4])),
        XdrDataEntryExt(0),
      );

      var original = XdrLedgerEntryData(XdrLedgerEntryType.DATA);
      original.data = data;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerEntryData.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerEntryData.decode(input);

      expect(decoded.discriminant.value, equals(XdrLedgerEntryType.DATA.value));
      expect(decoded.data, isNotNull);
    });

    test('XdrLedgerEntryData CLAIMABLE_BALANCE encode/decode', () {
      var balanceId = XdrClaimableBalanceID(XdrClaimableBalanceIDType.CLAIMABLE_BALANCE_ID_TYPE_V0);
      balanceId.v0 = XdrHash(Uint8List.fromList(List<int>.filled(32, 0x88)));

      var accountId = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var predicate = XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_UNCONDITIONAL);
      var claimant = XdrClaimant(XdrClaimantType.CLAIMANT_TYPE_V0);
      claimant.v0 = XdrClaimantV0(accountId, predicate);

      var claimableBalance = XdrClaimableBalanceEntry(
        balanceId,
        [claimant],
        XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE),
        XdrInt64(BigInt.from(1000000)),
        XdrClaimableBalanceEntryExt(0),
      );

      var original = XdrLedgerEntryData(XdrLedgerEntryType.CLAIMABLE_BALANCE);
      original.claimableBalance = claimableBalance;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerEntryData.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerEntryData.decode(input);

      expect(decoded.discriminant.value, equals(XdrLedgerEntryType.CLAIMABLE_BALANCE.value));
      expect(decoded.claimableBalance, isNotNull);
    });

    test('XdrLedgerEntryData LIQUIDITY_POOL encode/decode', () {
      var poolId = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xAA)));
      var body = XdrLiquidityPoolBody(XdrLiquidityPoolType.LIQUIDITY_POOL_CONSTANT_PRODUCT);
      var constantProduct = XdrConstantProduct(
        XdrLiquidityPoolConstantProductParameters(
          XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE),
          XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE),
          XdrInt32(30),
        ),
        XdrInt64(BigInt.from(1000)),
        XdrInt64(BigInt.from(2000)),
        XdrInt64(BigInt.from(1500)),
        XdrInt64(BigInt.from(100)),
      );
      body.constantProduct = constantProduct;

      var liquidityPool = XdrLiquidityPoolEntry(poolId, body);

      var original = XdrLedgerEntryData(XdrLedgerEntryType.LIQUIDITY_POOL);
      original.liquidityPool = liquidityPool;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerEntryData.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerEntryData.decode(input);

      expect(decoded.discriminant.value, equals(XdrLedgerEntryType.LIQUIDITY_POOL.value));
      expect(decoded.liquidityPool, isNotNull);
    });

    test('XdrLedgerEntryData CONTRACT_DATA encode/decode', () {
      var contractIdBytes = Uint8List.fromList(List<int>.filled(32, 0xBB));
      var contractIdHex = Util.bytesToHex(contractIdBytes);
      var contractId = XdrSCAddress.forContractId(contractIdHex);
      var key = XdrSCVal.forLedgerKeyContractInstance();
      var val = XdrSCVal.forU32(12345);
      var durability = XdrContractDataDurability.PERSISTENT;

      var contractData = XdrContractDataEntry(
        XdrExtensionPoint(0),
        contractId,
        key,
        durability,
        val,
      );

      var original = XdrLedgerEntryData(XdrLedgerEntryType.CONTRACT_DATA);
      original.contractData = contractData;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerEntryData.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerEntryData.decode(input);

      expect(decoded.discriminant.value, equals(XdrLedgerEntryType.CONTRACT_DATA.value));
      expect(decoded.contractData, isNotNull);
    });

    test('XdrLedgerEntryData CONTRACT_CODE encode/decode', () {
      var ext = XdrContractCodeEntryExt(0);
      var hash = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xCC)));
      var code = Uint8List.fromList([0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00]);

      var contractCode = XdrContractCodeEntry(ext, hash, XdrDataValue(code));

      var original = XdrLedgerEntryData(XdrLedgerEntryType.CONTRACT_CODE);
      original.contractCode = contractCode;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerEntryData.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerEntryData.decode(input);

      expect(decoded.discriminant.value, equals(XdrLedgerEntryType.CONTRACT_CODE.value));
      expect(decoded.contractCode, isNotNull);
    });

    test('XdrLedgerEntryData CONFIG_SETTING encode/decode', () {
      var configSetting = XdrConfigSettingEntry(
        XdrConfigSettingID.CONFIG_SETTING_CONTRACT_MAX_SIZE_BYTES,
      );
      configSetting.contractMaxSizeBytes = XdrUint32(65536);

      var original = XdrLedgerEntryData(XdrLedgerEntryType.CONFIG_SETTING);
      original.configSetting = configSetting;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerEntryData.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerEntryData.decode(input);

      expect(decoded.discriminant.value, equals(XdrLedgerEntryType.CONFIG_SETTING.value));
      expect(decoded.configSetting, isNotNull);
      expect(decoded.configSetting!.contractMaxSizeBytes!.uint32, equals(65536));
    });

    test('XdrLedgerEntryData TTL encode/decode', () {
      var keyHash = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xDD)));
      var ttl = XdrTTLEntry(keyHash, XdrUint32(100000));

      var original = XdrLedgerEntryData(XdrLedgerEntryType.TTL);
      original.expiration = ttl;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerEntryData.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerEntryData.decode(input);

      expect(decoded.discriminant.value, equals(XdrLedgerEntryType.TTL.value));
      expect(decoded.expiration, isNotNull);
    });

    // NEW TESTS - XdrLedgerKey with all discriminants
    test('XdrLedgerKey ACCOUNT encode/decode', () {
      var accountId = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var keyAccount = XdrLedgerKeyAccount(accountId);

      var original = XdrLedgerKey(XdrLedgerEntryType.ACCOUNT);
      original.account = keyAccount;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerKey.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerKey.decode(input);

      expect(decoded.discriminant.value, equals(XdrLedgerEntryType.ACCOUNT.value));
      expect(decoded.account, isNotNull);
    });

    test('XdrLedgerKey TRUSTLINE encode/decode', () {
      var accountId = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var asset = XdrTrustlineAsset.fromXdrAsset(XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE));
      var keyTrustLine = XdrLedgerKeyTrustLine(accountId, asset);

      var original = XdrLedgerKey(XdrLedgerEntryType.TRUSTLINE);
      original.trustLine = keyTrustLine;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerKey.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerKey.decode(input);

      expect(decoded.discriminant.value, equals(XdrLedgerEntryType.TRUSTLINE.value));
      expect(decoded.trustLine, isNotNull);
    });

    test('XdrLedgerKey OFFER encode/decode', () {
      var sellerId = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var keyOffer = XdrLedgerKeyOffer(sellerId, XdrUint64(BigInt.from(123)));

      var original = XdrLedgerKey(XdrLedgerEntryType.OFFER);
      original.offer = keyOffer;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerKey.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerKey.decode(input);

      expect(decoded.discriminant.value, equals(XdrLedgerEntryType.OFFER.value));
      expect(decoded.offer, isNotNull);
    });

    test('XdrLedgerKey DATA encode/decode', () {
      var accountId = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var keyData = XdrLedgerKeyData(accountId, XdrString64('testkey'));

      var original = XdrLedgerKey(XdrLedgerEntryType.DATA);
      original.data = keyData;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerKey.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerKey.decode(input);

      expect(decoded.discriminant.value, equals(XdrLedgerEntryType.DATA.value));
      expect(decoded.data, isNotNull);
    });

    // XdrLedgerKey for CLAIMABLE_BALANCE is not implemented in this SDK version

    // XdrLedgerKey for LIQUIDITY_POOL is not implemented in this SDK version

    test('XdrLedgerKey CONTRACT_DATA encode/decode', () {
      var contractIdBytes = Uint8List.fromList(List<int>.filled(32, 0xBB));
      var contractIdHex = Util.bytesToHex(contractIdBytes);
      var contractId = XdrSCAddress.forContractId(contractIdHex);
      var key = XdrSCVal.forU32(12345);
      var durability = XdrContractDataDurability.PERSISTENT;
      var keyContractData = XdrLedgerKeyContractData(contractId, key, durability);

      var original = XdrLedgerKey(XdrLedgerEntryType.CONTRACT_DATA);
      original.contractData = keyContractData;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerKey.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerKey.decode(input);

      expect(decoded.discriminant.value, equals(XdrLedgerEntryType.CONTRACT_DATA.value));
      expect(decoded.contractData, isNotNull);
    });

    test('XdrLedgerKey CONTRACT_CODE encode/decode', () {
      var hash = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xCC)));
      var keyContractCode = XdrLedgerKeyContractCode(hash);

      var original = XdrLedgerKey(XdrLedgerEntryType.CONTRACT_CODE);
      original.contractCode = keyContractCode;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerKey.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerKey.decode(input);

      expect(decoded.discriminant.value, equals(XdrLedgerEntryType.CONTRACT_CODE.value));
      expect(decoded.contractCode, isNotNull);
    });

    test('XdrLedgerKey CONFIG_SETTING encode/decode', () {
      var configSettingId = XdrConfigSettingID.CONFIG_SETTING_CONTRACT_MAX_SIZE_BYTES;

      var original = XdrLedgerKey(XdrLedgerEntryType.CONFIG_SETTING);
      original.configSetting = configSettingId;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerKey.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerKey.decode(input);

      expect(decoded.discriminant.value, equals(XdrLedgerEntryType.CONFIG_SETTING.value));
      expect(decoded.configSetting, isNotNull);
    });

    test('XdrLedgerKey TTL encode/decode', () {
      var keyHash = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xDD)));
      var keyTTL = XdrLedgerKeyTTL(keyHash);

      var original = XdrLedgerKey(XdrLedgerEntryType.TTL);
      original.ttl = keyTTL;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerKey.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerKey.decode(input);

      expect(decoded.discriminant.value, equals(XdrLedgerEntryType.TTL.value));
      expect(decoded.ttl, isNotNull);
    });

    // NEW TESTS - XdrLedgerEntryChange with all discriminants
    test('XdrLedgerEntryChange LEDGER_ENTRY_CREATED encode/decode', () {
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
        XdrString32(''),
        XdrThresholds(Uint8List.fromList([1, 1, 1, 1])),
        [signer],
        XdrAccountEntryExt(0),
      );
      data.account = account;

      var entry = XdrLedgerEntry(
        XdrUint32(100),
        data,
        XdrLedgerEntryExt(0),
      );

      var original = XdrLedgerEntryChange(XdrLedgerEntryChangeType.LEDGER_ENTRY_CREATED);
      original.created = entry;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerEntryChange.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerEntryChange.decode(input);

      expect(decoded.discriminant.value, equals(XdrLedgerEntryChangeType.LEDGER_ENTRY_CREATED.value));
      expect(decoded.created, isNotNull);
    });

    test('XdrLedgerEntryChange LEDGER_ENTRY_UPDATED encode/decode', () {
      var accountId = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var data = XdrLedgerEntryData(XdrLedgerEntryType.ACCOUNT);
      var signerKey = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519);
      signerKey.ed25519 = XdrUint256(KeyPair.fromAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H').publicKey);
      var signer = XdrSigner(signerKey, XdrUint32(1));
      var account = XdrAccountEntry(
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
      data.account = account;

      var entry = XdrLedgerEntry(
        XdrUint32(200),
        data,
        XdrLedgerEntryExt(0),
      );

      var original = XdrLedgerEntryChange(XdrLedgerEntryChangeType.LEDGER_ENTRY_UPDATED);
      original.updated = entry;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerEntryChange.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerEntryChange.decode(input);

      expect(decoded.discriminant.value, equals(XdrLedgerEntryChangeType.LEDGER_ENTRY_UPDATED.value));
      expect(decoded.updated, isNotNull);
    });

    test('XdrLedgerEntryChange LEDGER_ENTRY_REMOVED encode/decode', () {
      var accountId = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var keyAccount = XdrLedgerKeyAccount(accountId);
      var key = XdrLedgerKey(XdrLedgerEntryType.ACCOUNT);
      key.account = keyAccount;

      var original = XdrLedgerEntryChange(XdrLedgerEntryChangeType.LEDGER_ENTRY_REMOVED);
      original.removed = key;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerEntryChange.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerEntryChange.decode(input);

      expect(decoded.discriminant.value, equals(XdrLedgerEntryChangeType.LEDGER_ENTRY_REMOVED.value));
      expect(decoded.removed, isNotNull);
    });

    test('XdrLedgerEntryChange LEDGER_ENTRY_STATE encode/decode', () {
      var accountId = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var data = XdrLedgerEntryData(XdrLedgerEntryType.ACCOUNT);
      var signerKey = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519);
      signerKey.ed25519 = XdrUint256(KeyPair.fromAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H').publicKey);
      var signer = XdrSigner(signerKey, XdrUint32(1));
      var account = XdrAccountEntry(
        accountId,
        XdrInt64(BigInt.from(30000000)),
        XdrSequenceNumber(XdrBigInt64(BigInt.from(3))),
        XdrUint32(0),
        accountId,
        XdrUint32(0),
        XdrString32(''),
        XdrThresholds(Uint8List.fromList([1, 1, 1, 1])),
        [signer],
        XdrAccountEntryExt(0),
      );
      data.account = account;

      var entry = XdrLedgerEntry(
        XdrUint32(300),
        data,
        XdrLedgerEntryExt(0),
      );

      var original = XdrLedgerEntryChange(XdrLedgerEntryChangeType.LEDGER_ENTRY_STATE);
      original.state = entry;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerEntryChange.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerEntryChange.decode(input);

      expect(decoded.discriminant.value, equals(XdrLedgerEntryChangeType.LEDGER_ENTRY_STATE.value));
      expect(decoded.state, isNotNull);
    });

    test('XdrLedgerEntryChange LEDGER_ENTRY_RESTORED encode/decode', () {
      var accountId = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var data = XdrLedgerEntryData(XdrLedgerEntryType.ACCOUNT);
      var signerKey = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519);
      signerKey.ed25519 = XdrUint256(KeyPair.fromAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H').publicKey);
      var signer = XdrSigner(signerKey, XdrUint32(1));
      var account = XdrAccountEntry(
        accountId,
        XdrInt64(BigInt.from(40000000)),
        XdrSequenceNumber(XdrBigInt64(BigInt.from(4))),
        XdrUint32(0),
        accountId,
        XdrUint32(0),
        XdrString32(''),
        XdrThresholds(Uint8List.fromList([1, 1, 1, 1])),
        [signer],
        XdrAccountEntryExt(0),
      );
      data.account = account;

      var entry = XdrLedgerEntry(
        XdrUint32(400),
        data,
        XdrLedgerEntryExt(0),
      );

      var original = XdrLedgerEntryChange(XdrLedgerEntryChangeType.LEDGER_ENTRY_RESTORED);
      original.restored = entry;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerEntryChange.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerEntryChange.decode(input);

      expect(decoded.discriminant.value, equals(XdrLedgerEntryChangeType.LEDGER_ENTRY_RESTORED.value));
      expect(decoded.restored, isNotNull);
    });

    // NEW TESTS - XdrConfigSettingEntry with all discriminants
    test('XdrConfigSettingEntry CONTRACT_MAX_SIZE_BYTES encode/decode', () {
      var original = XdrConfigSettingEntry(XdrConfigSettingID.CONFIG_SETTING_CONTRACT_MAX_SIZE_BYTES);
      original.contractMaxSizeBytes = XdrUint32(65536);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrConfigSettingEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrConfigSettingEntry.decode(input);

      expect(decoded.configSettingID.value, equals(XdrConfigSettingID.CONFIG_SETTING_CONTRACT_MAX_SIZE_BYTES.value));
      expect(decoded.contractMaxSizeBytes!.uint32, equals(65536));
    });

    test('XdrConfigSettingEntry CONTRACT_COMPUTE_V0 encode/decode', () {
      var compute = XdrConfigSettingContractComputeV0(
        XdrInt64(BigInt.from(10000)),
        XdrInt64(BigInt.from(5000)),
        XdrInt64(BigInt.from(1000)),
        XdrUint32(256),
      );

      var original = XdrConfigSettingEntry(XdrConfigSettingID.CONFIG_SETTING_CONTRACT_COMPUTE_V0);
      original.contractCompute = compute;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrConfigSettingEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrConfigSettingEntry.decode(input);

      expect(decoded.configSettingID.value, equals(XdrConfigSettingID.CONFIG_SETTING_CONTRACT_COMPUTE_V0.value));
      expect(decoded.contractCompute, isNotNull);
    });

    test('XdrConfigSettingEntry CONTRACT_LEDGER_COST_V0 encode/decode', () {
      var ledgerCost = XdrConfigSettingContractLedgerCostV0(
        XdrUint32(1000),
        XdrUint32(500),
        XdrUint32(2000),
        XdrUint32(1500),
        XdrUint32(3000),
        XdrUint32(100),
        XdrUint32(50),
        XdrUint32(200),
        XdrInt64(BigInt.from(1000)),
        XdrInt64(BigInt.from(100)),
        XdrInt64(BigInt.from(1000)),
        XdrInt64(BigInt.from(100)),
        XdrInt64(BigInt.from(1000)),
        XdrInt64(BigInt.from(100)),
        XdrUint32(10),
      );

      var original = XdrConfigSettingEntry(XdrConfigSettingID.CONFIG_SETTING_CONTRACT_LEDGER_COST_V0);
      original.contractLedgerCost = ledgerCost;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrConfigSettingEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrConfigSettingEntry.decode(input);

      expect(decoded.configSettingID.value, equals(XdrConfigSettingID.CONFIG_SETTING_CONTRACT_LEDGER_COST_V0.value));
      expect(decoded.contractLedgerCost, isNotNull);
    });

    test('XdrConfigSettingEntry CONTRACT_HISTORICAL_DATA_V0 encode/decode', () {
      var historicalData = XdrConfigSettingContractHistoricalDataV0(
        XdrInt64(BigInt.from(1000)),
      );

      var original = XdrConfigSettingEntry(XdrConfigSettingID.CONFIG_SETTING_CONTRACT_HISTORICAL_DATA_V0);
      original.contractHistoricalData = historicalData;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrConfigSettingEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrConfigSettingEntry.decode(input);

      expect(decoded.configSettingID.value, equals(XdrConfigSettingID.CONFIG_SETTING_CONTRACT_HISTORICAL_DATA_V0.value));
      expect(decoded.contractHistoricalData, isNotNull);
    });

    test('XdrConfigSettingEntry CONTRACT_EVENTS_V0 encode/decode', () {
      var events = XdrConfigSettingContractEventsV0(
        XdrUint32(1000),
        XdrInt64(BigInt.from(100)),
      );

      var original = XdrConfigSettingEntry(XdrConfigSettingID.CONFIG_SETTING_CONTRACT_EVENTS_V0);
      original.contractEvents = events;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrConfigSettingEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrConfigSettingEntry.decode(input);

      expect(decoded.configSettingID.value, equals(XdrConfigSettingID.CONFIG_SETTING_CONTRACT_EVENTS_V0.value));
      expect(decoded.contractEvents, isNotNull);
    });

    test('XdrConfigSettingEntry CONTRACT_BANDWIDTH_V0 encode/decode', () {
      var bandwidth = XdrConfigSettingContractBandwidthV0(
        XdrUint32(10000),
        XdrUint32(1000),
        XdrInt64(BigInt.from(100)),
      );

      var original = XdrConfigSettingEntry(XdrConfigSettingID.CONFIG_SETTING_CONTRACT_BANDWIDTH_V0);
      original.contractBandwidth = bandwidth;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrConfigSettingEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrConfigSettingEntry.decode(input);

      expect(decoded.configSettingID.value, equals(XdrConfigSettingID.CONFIG_SETTING_CONTRACT_BANDWIDTH_V0.value));
      expect(decoded.contractBandwidth, isNotNull);
    });

    test('XdrConfigSettingEntry CONTRACT_COST_PARAMS_CPU_INSTRUCTIONS encode/decode', () {
      var params = XdrContractCostParams([
        XdrContractCostParamEntry(
          XdrExtensionPoint(0),
          XdrInt64(BigInt.from(100)),
          XdrInt64(BigInt.from(10)),
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
    });

    test('XdrConfigSettingEntry CONTRACT_COST_PARAMS_MEMORY_BYTES encode/decode', () {
      var params = XdrContractCostParams([
        XdrContractCostParamEntry(
          XdrExtensionPoint(0),
          XdrInt64(BigInt.from(200)),
          XdrInt64(BigInt.from(20)),
        ),
      ]);

      var original = XdrConfigSettingEntry(XdrConfigSettingID.CONFIG_SETTING_CONTRACT_COST_PARAMS_MEMORY_BYTES);
      original.contractCostParamsMemBytes = params;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrConfigSettingEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrConfigSettingEntry.decode(input);

      expect(decoded.configSettingID.value, equals(XdrConfigSettingID.CONFIG_SETTING_CONTRACT_COST_PARAMS_MEMORY_BYTES.value));
      expect(decoded.contractCostParamsMemBytes, isNotNull);
    });

    test('XdrConfigSettingEntry CONTRACT_DATA_KEY_SIZE_BYTES encode/decode', () {
      var original = XdrConfigSettingEntry(XdrConfigSettingID.CONFIG_SETTING_CONTRACT_DATA_KEY_SIZE_BYTES);
      original.contractDataKeySizeBytes = XdrUint32(4096);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrConfigSettingEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrConfigSettingEntry.decode(input);

      expect(decoded.configSettingID.value, equals(XdrConfigSettingID.CONFIG_SETTING_CONTRACT_DATA_KEY_SIZE_BYTES.value));
      expect(decoded.contractDataKeySizeBytes!.uint32, equals(4096));
    });

    test('XdrConfigSettingEntry CONTRACT_DATA_ENTRY_SIZE_BYTES encode/decode', () {
      var original = XdrConfigSettingEntry(XdrConfigSettingID.CONFIG_SETTING_CONTRACT_DATA_ENTRY_SIZE_BYTES);
      original.contractDataEntrySizeBytes = XdrUint32(8192);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrConfigSettingEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrConfigSettingEntry.decode(input);

      expect(decoded.configSettingID.value, equals(XdrConfigSettingID.CONFIG_SETTING_CONTRACT_DATA_ENTRY_SIZE_BYTES.value));
      expect(decoded.contractDataEntrySizeBytes!.uint32, equals(8192));
    });

    test('XdrConfigSettingEntry STATE_ARCHIVAL encode/decode', () {
      var archival = XdrStateArchivalSettings(
        XdrUint32(1000),
        XdrUint32(5000),
        XdrUint32(100),
        XdrInt64(BigInt.from(1000)),
        XdrInt64(BigInt.from(100)),
        XdrUint32(10),
        XdrUint32(10000),
        XdrUint32(500),
        XdrUint32(500),
        XdrUint32(0),
      );

      var original = XdrConfigSettingEntry(XdrConfigSettingID.CONFIG_SETTING_STATE_ARCHIVAL);
      original.stateArchivalSettings = archival;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrConfigSettingEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrConfigSettingEntry.decode(input);

      expect(decoded.configSettingID.value, equals(XdrConfigSettingID.CONFIG_SETTING_STATE_ARCHIVAL.value));
      expect(decoded.stateArchivalSettings, isNotNull);
    });

    test('XdrConfigSettingEntry CONTRACT_EXECUTION_LANES encode/decode', () {
      var lanes = XdrConfigSettingContractExecutionLanesV0(XdrUint32(4));

      var original = XdrConfigSettingEntry(XdrConfigSettingID.CONFIG_SETTING_CONTRACT_EXECUTION_LANES);
      original.contractExecutionLanes = lanes;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrConfigSettingEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrConfigSettingEntry.decode(input);

      expect(decoded.configSettingID.value, equals(XdrConfigSettingID.CONFIG_SETTING_CONTRACT_EXECUTION_LANES.value));
      expect(decoded.contractExecutionLanes, isNotNull);
    });

    // CONFIG_SETTING_LIVE_SOROBAN_STATE_SIZE_WINDOW - not included for simplicity

    test('XdrConfigSettingEntry EVICTION_ITERATOR encode/decode', () {
      var iterator = XdrEvictionIterator(
        XdrUint32(100),
        true,
        XdrUint64(BigInt.from(500)),
      );

      var original = XdrConfigSettingEntry(XdrConfigSettingID.CONFIG_SETTING_EVICTION_ITERATOR);
      original.evictionIterator = iterator;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrConfigSettingEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrConfigSettingEntry.decode(input);

      expect(decoded.configSettingID.value, equals(XdrConfigSettingID.CONFIG_SETTING_EVICTION_ITERATOR.value));
      expect(decoded.evictionIterator, isNotNull);
    });

    test('XdrConfigSettingEntry CONTRACT_PARALLEL_COMPUTE_V0 encode/decode', () {
      var parallel = XdrConfigSettingContractParallelComputeV0(
        XdrUint32(1000),
      );

      var original = XdrConfigSettingEntry(XdrConfigSettingID.CONFIG_SETTING_CONTRACT_PARALLEL_COMPUTE_V0);
      original.contractParallelCompute = parallel;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrConfigSettingEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrConfigSettingEntry.decode(input);

      expect(decoded.configSettingID.value, equals(XdrConfigSettingID.CONFIG_SETTING_CONTRACT_PARALLEL_COMPUTE_V0.value));
      expect(decoded.contractParallelCompute, isNotNull);
    });

    test('XdrConfigSettingEntry CONTRACT_LEDGER_COST_EXT_V0 encode/decode', () {
      var costExt = XdrConfigSettingContractLedgerCostExtV0(
        XdrUint32(100),
        XdrInt64(BigInt.from(50)),
      );

      var original = XdrConfigSettingEntry(XdrConfigSettingID.CONFIG_SETTING_CONTRACT_LEDGER_COST_EXT_V0);
      original.contractLedgerCostExt = costExt;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrConfigSettingEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrConfigSettingEntry.decode(input);

      expect(decoded.configSettingID.value, equals(XdrConfigSettingID.CONFIG_SETTING_CONTRACT_LEDGER_COST_EXT_V0.value));
      expect(decoded.contractLedgerCostExt, isNotNull);
    });

    test('XdrConfigSettingEntry SCP_TIMING encode/decode', () {
      var timing = XdrConfigSettingSCPTiming(
        XdrUint32(1000),
        XdrUint32(2000),
        XdrUint32(3000),
        XdrUint32(4000),
        XdrUint32(5000),
      );

      var original = XdrConfigSettingEntry(XdrConfigSettingID.CONFIG_SETTING_SCP_TIMING);
      original.contractSCPTiming = timing;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrConfigSettingEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrConfigSettingEntry.decode(input);

      expect(decoded.configSettingID.value, equals(XdrConfigSettingID.CONFIG_SETTING_SCP_TIMING.value));
      expect(decoded.contractSCPTiming, isNotNull);
    });

    // NEW TESTS - Extension types with discriminant 1
    // XdrLedgerEntryExt with v1 is not available in this SDK version

    test('XdrClaimableBalanceEntryExt with discriminant 1 encode/decode', () {
      var v1 = XdrClaimableBalanceEntryExtV1(
        0,
        XdrUint32(1000),
      );

      var original = XdrClaimableBalanceEntryExt(1);
      original.v1 = v1;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrClaimableBalanceEntryExt.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrClaimableBalanceEntryExt.decode(input);

      expect(decoded.discriminant, equals(1));
      expect(decoded.v1, isNotNull);
    });

    test('XdrContractCodeEntryExt with discriminant 1 encode/decode', () {
      var v1 = XdrContractCodeEntryExtV1(
        XdrExtensionPoint(0),
        XdrContractCodeCostInputs(
          XdrExtensionPoint(0),
          XdrInt32(1000),
          XdrInt32(500),
          XdrInt32(100),
          XdrInt32(50),
          XdrInt32(10),
          XdrInt32(5),
          XdrInt32(200),
          XdrInt32(300),
          XdrInt32(400),
          XdrInt32(600),
        ),
      );

      var original = XdrContractCodeEntryExt(1);
      original.v1 = v1;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrContractCodeEntryExt.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrContractCodeEntryExt.decode(input);

      expect(decoded.discriminant, equals(1));
      expect(decoded.v1, isNotNull);
    });

    // NEW TESTS - Additional struct types
    test('XdrLedgerHeader encode/decode', () {
      var stellarValue = XdrStellarValue(
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0x44))),
        XdrUint64(BigInt.from(123456)),
        [],
        XdrStellarValueExt(0),
      );

      var ledgerHeader = XdrLedgerHeader(
        XdrUint32(0),
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0x11))),
        stellarValue,
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0x22))),
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0x33))),
        XdrUint32(100),
        XdrInt64(BigInt.from(10000000)),
        XdrInt64(BigInt.from(100)),
        XdrUint32(1000),
        XdrUint64(BigInt.from(1000)),
        XdrUint32(100),
        XdrUint32(5000000),
        XdrUint32(1000),
        List<XdrHash>.generate(4, (i) => XdrHash(Uint8List.fromList(List<int>.filled(32, 0x11)))),
        XdrLedgerHeaderExt(0),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerHeader.encode(output, ledgerHeader);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerHeader.decode(input);

      expect(decoded.ledgerSeq.uint32, equals(100));
    });

    test('XdrLedgerHeaderHistoryEntry encode/decode', () {
      var hash = XdrHash(Uint8List.fromList(List<int>.filled(32, 0x44)));

      var stellarValue = XdrStellarValue(
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0x55))),
        XdrUint64(BigInt.from(234567)),
        [],
        XdrStellarValueExt(0),
      );

      var header = XdrLedgerHeader(
        XdrUint32(0),
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0x11))),
        stellarValue,
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0x22))),
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0x33))),
        XdrUint32(200),
        XdrInt64(BigInt.from(20000000)),
        XdrInt64(BigInt.from(200)),
        XdrUint32(2000),
        XdrUint64(BigInt.from(2000)),
        XdrUint32(100),
        XdrUint32(5000000),
        XdrUint32(2000),
        List<XdrHash>.generate(4, (i) => XdrHash(Uint8List.fromList(List<int>.filled(32, 0x11)))),
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

      expect(decoded.header.ledgerSeq.uint32, equals(200));
    });

    test('XdrLiquidityPoolBody CONSTANT_PRODUCT encode/decode', () {
      var constantProduct = XdrConstantProduct(
        XdrLiquidityPoolConstantProductParameters(
          XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE),
          XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE),
          XdrInt32(30),
        ),
        XdrInt64(BigInt.from(5000)),
        XdrInt64(BigInt.from(10000)),
        XdrInt64(BigInt.from(7000)),
        XdrInt64(BigInt.from(500)),
      );

      var original = XdrLiquidityPoolBody(XdrLiquidityPoolType.LIQUIDITY_POOL_CONSTANT_PRODUCT);
      original.constantProduct = constantProduct;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLiquidityPoolBody.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLiquidityPoolBody.decode(input);

      expect(decoded.discriminant.value, equals(XdrLiquidityPoolType.LIQUIDITY_POOL_CONSTANT_PRODUCT.value));
      expect(decoded.constantProduct, isNotNull);
    });

    test('XdrContractDataDurability enum all variants', () {
      final types = [
        XdrContractDataDurability.TEMPORARY,
        XdrContractDataDurability.PERSISTENT,
      ];

      for (var type in types) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrContractDataDurability.encode(output, type);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrContractDataDurability.decode(input);

        expect(decoded.value, equals(type.value));
      }
    });

    test('XdrConfigUpgradeSetKey encode/decode', () {
      var contractID = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xEE)));
      var contentHash = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xFF)));

      var original = XdrConfigUpgradeSetKey(contractID, contentHash);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrConfigUpgradeSetKey.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrConfigUpgradeSetKey.decode(input);

      expect(decoded.contractID.hash, equals(contractID.hash));
      expect(decoded.contentHash.hash, equals(contentHash.hash));
    });

    test('XdrLedgerUpgrade LEDGER_UPGRADE_CONFIG encode/decode', () {
      var upgradeKey = XdrConfigUpgradeSetKey(
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0xAB))),
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0xCD))),
      );

      var original = XdrLedgerUpgrade(XdrLedgerUpgradeType.LEDGER_UPGRADE_CONFIG);
      original.newConfig = upgradeKey;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerUpgrade.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerUpgrade.decode(input);

      expect(decoded.discriminant.value, equals(XdrLedgerUpgradeType.LEDGER_UPGRADE_CONFIG.value));
      expect(decoded.newConfig, isNotNull);
    });
  });
}
