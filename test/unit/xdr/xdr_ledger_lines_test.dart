import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:typed_data';

/// Hex of the 32 byte hash the claimable balance id cases are built over.
const _balanceHashHex =
    'da0d57da7d4850e7fc10d2a9d0ebc731f7afb40574c03395b17d49149b91f5be';

/// Hex of the 32 byte hash the liquidity pool id cases are built over.
const _poolHashHex =
    'dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7';

void main() {
  group('XdrLedgerEntryChangeType', () {
    test('constructor and toString', () {
      final type = XdrLedgerEntryChangeType(2);
      expect(type.value, 2);
      expect(type.toString(), 'LedgerEntryChangeType.2');
    });

    test('decode unknown enum value throws', () {
      final bytes = Uint8List(4);
      bytes.buffer.asByteData().setInt32(0, 99);
      final stream = XdrDataInputStream(bytes);
      expect(() => XdrLedgerEntryChangeType.decode(stream), throwsException);
    });
  });

  group('XdrLedgerEntryType', () {
    test('constructor and toString', () {
      final type = XdrLedgerEntryType(5);
      expect(type.value, 5);
      expect(type.toString(), 'LedgerEntryType.5');
    });
  });

  group('XdrClaimPredicateType', () {
    test('constructor and toString', () {
      final type = XdrClaimPredicateType(3);
      expect(type.value, 3);
      expect(type.toString(), 'ClaimPredicateType.3');
    });

    test('decode unknown enum value throws', () {
      final bytes = Uint8List(4);
      bytes.buffer.asByteData().setInt32(0, 99);
      final stream = XdrDataInputStream(bytes);
      expect(() => XdrClaimPredicateType.decode(stream), throwsException);
    });
  });

  group('XdrClaimPredicate', () {
    test('encode NOT predicate with null notPredicate', () {
      final predicate =
          XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_NOT);
      predicate.notPredicate = null;

      final output = XdrDataOutputStream();
      XdrClaimPredicate.encode(output, predicate);
      expect(output.bytes.length, greaterThan(0));
    });
  });

  group('XdrClaimantType', () {
    test('constructor and toString', () {
      final type = XdrClaimantType(0);
      expect(type.value, 0);
      expect(type.toString(), 'ClaimantType.0');
    });

    test('decode unknown enum value throws', () {
      final bytes = Uint8List(4);
      bytes.buffer.asByteData().setInt32(0, 99);
      final stream = XdrDataInputStream(bytes);
      expect(() => XdrClaimantType.decode(stream), throwsException);
    });
  });

  group('XdrClaimableBalanceIDType', () {
    test('constructor and toString', () {
      final type = XdrClaimableBalanceIDType(0);
      expect(type.value, 0);
      expect(type.toString(), 'ClaimableBalanceIDType.0');
    });

    test('decode unknown enum value throws', () {
      final bytes = Uint8List(4);
      bytes.buffer.asByteData().setInt32(0, 99);
      final stream = XdrDataInputStream(bytes);
      expect(() => XdrClaimableBalanceIDType.decode(stream), throwsException);
    });
  });

  group('XdrClaimableBalanceID', () {
    test('discriminant setter', () {
      final id = XdrClaimableBalanceID(
          XdrClaimableBalanceIDType.CLAIMABLE_BALANCE_ID_TYPE_V0);
      id.discriminant = XdrClaimableBalanceIDType.CLAIMABLE_BALANCE_ID_TYPE_V0;
      expect(id.discriminant,
          XdrClaimableBalanceIDType.CLAIMABLE_BALANCE_ID_TYPE_V0);
    });

    test('forId with hex string', () {
      final id = XdrClaimableBalanceID.forId('00000000$_balanceHashHex');
      expect(id.discriminant,
          XdrClaimableBalanceIDType.CLAIMABLE_BALANCE_ID_TYPE_V0);
      expect(Util.bytesToHex(id.v0!.hash), _balanceHashHex);
    });

    test('forId with B prefix', () {
      final bId = StrKey.encodeClaimableBalanceIdHex(_balanceHashHex);
      final id = XdrClaimableBalanceID.forId(bId);
      expect(id.v0, isNotNull);
      expect(Util.bytesToHex(id.v0!.hash), _balanceHashHex);
    });

    test('forId with a hex id carrying its four byte discriminant', () {
      final id = XdrClaimableBalanceID.forId('00000000$_balanceHashHex');
      expect(id.v0, isNotNull);
      expect(Util.bytesToHex(id.v0!.hash), _balanceHashHex);
    });

    test('forId with a hex id carrying its one byte discriminant', () {
      final id = XdrClaimableBalanceID.forId('00$_balanceHashHex');
      expect(id.discriminant,
          XdrClaimableBalanceIDType.CLAIMABLE_BALANCE_ID_TYPE_V0);
      expect(Util.bytesToHex(id.v0!.hash), _balanceHashHex);
    });

    test('forId with a bare hex hash', () {
      final id = XdrClaimableBalanceID.forId(_balanceHashHex);
      expect(id.discriminant,
          XdrClaimableBalanceIDType.CLAIMABLE_BALANCE_ID_TYPE_V0);
      expect(Util.bytesToHex(id.v0!.hash), _balanceHashHex);
    });

    test('forId refuses a hex id whose discriminant names no type', () {
      // Both hex widths carry the balance id type: the one-byte discriminant
      // of the strkey form and the four-byte XDR union discriminant Horizon
      // writes. A non-zero value in either names no type the protocol defines,
      // and must not be dropped to leave a V0 id over the same hash.
      for (final taggedHex in <String>[
        '01$_balanceHashHex',
        '00000001$_balanceHashHex'
      ]) {
        XdrClaimableBalanceID? built;
        expect(
            () => built = XdrClaimableBalanceID.forId(taggedHex),
            throwsA(isA<FormatException>().having((e) => e.message, 'message',
                contains('carries the discriminant 1, '
                    'which names no claimable balance id type'))),
            reason: taggedHex);
        expect(built, isNull, reason: taggedHex);
      }
    });

    test('forId refuses a hex id of a width matching no accepted shape', () {
      // A width the codec does not define must be refused, not zero-padded or
      // truncated to a 32-byte hash that names a different balance. The pinned
      // count holds the message to reporting the actual width.
      for (final id in <String>[
        'dead',
        _balanceHashHex.substring(0, _balanceHashHex.length - 2),
        '0000000000$_balanceHashHex',
      ]) {
        expect(
            () => XdrClaimableBalanceID.forId(id),
            throwsA(isA<FormatException>().having((e) => e.message, 'message',
                contains('${id.length} characters given'))),
            reason: id);
      }

      // 58 characters is the strkey width, so that case names the strkey rule.
      // A lower case "b" lands here too, so the rule names the case as well.
      for (final id in <String>['a' * 58, 'b' * 58]) {
        expect(
            () => XdrClaimableBalanceID.forId(id),
            throwsA(isA<FormatException>().having(
                (e) => e.message,
                'message',
                contains('must be a strkey beginning with "B", '
                    'which is upper case'))),
            reason: id);
      }
    });

    test('forId reads a hex id in either case', () {
      // package:convert decodes hex case-insensitively, so the upper case
      // spelling of a hash names the same balance as the lower case one.
      for (final spelling in <String>[
        _balanceHashHex.toUpperCase(),
        '00${_balanceHashHex.toUpperCase()}',
        '00000000${_balanceHashHex.toUpperCase()}',
      ]) {
        expect(Util.bytesToHex(XdrClaimableBalanceID.forId(spelling).v0!.hash),
            _balanceHashHex,
            reason: spelling);
      }
    });

    test('paddedBalanceIdHex reports the id the way Horizon spells it', () {
      for (final spelling in <String>[
        _balanceHashHex,
        '00$_balanceHashHex',
        '00000000$_balanceHashHex',
        StrKey.encodeClaimableBalanceIdHex(_balanceHashHex),
      ]) {
        expect(XdrClaimableBalanceID.forId(spelling).paddedBalanceIdHex,
            '00000000$_balanceHashHex',
            reason: spelling);
      }
    });
  });

  group('XdrClaimableBalanceEntry', () {
    test('setters', () {
      final hash = Uint8List(32);
      final balanceId = XdrClaimableBalanceID(
          XdrClaimableBalanceIDType.CLAIMABLE_BALANCE_ID_TYPE_V0);
      balanceId.v0 = XdrHash(hash);

      final accountId = KeyPair.random().xdrPublicKey;
      final predicate = XdrClaimPredicate(
          XdrClaimPredicateType.CLAIM_PREDICATE_UNCONDITIONAL);
      final claimant =
          XdrClaimant(XdrClaimantType.CLAIMANT_TYPE_V0);
      claimant.v0 = XdrClaimantV0(XdrAccountID(accountId), predicate);

      final asset = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      final amount = XdrInt64(BigInt.from(100000000));
      final ext = XdrClaimableBalanceEntryExt(0);

      final entry = XdrClaimableBalanceEntry(
          balanceId, [claimant], asset, amount, ext);

      entry.balanceID = balanceId;
      entry.claimants = [claimant];
      entry.asset = asset;
      entry.amount = amount;
      entry.ext = ext;

      expect(entry.balanceID, balanceId);
      expect(entry.claimants, [claimant]);
      expect(entry.asset, asset);
      expect(entry.amount, amount);
      expect(entry.ext, ext);
    });
  });

  group('XdrClaimableBalanceEntryExt', () {
    test('discriminant setter', () {
      final ext = XdrClaimableBalanceEntryExt(0);
      ext.discriminant = 1;
      expect(ext.discriminant, 1);
    });
  });

  group('XdrClaimableBalanceEntryExtV1', () {
    test('setters', () {
      final flags = XdrUint32(2);
      final ext = XdrClaimableBalanceEntryExtV1(XdrClaimableBalanceEntryExtV1Ext(0), flags);

      ext.ext.discriminant = 0;
      ext.flags = XdrUint32(4);

      expect(ext.ext.discriminant, 0);
      expect(ext.flags.uint32, 4);
    });
  });

  group('XdrLedgerUpgradeType', () {
    test('constructor and toString', () {
      final type = XdrLedgerUpgradeType(3);
      expect(type.value, 3);
      expect(type.toString(), 'LedgerUpgradeType.3');
    });

    test('decode unknown enum value throws', () {
      final bytes = Uint8List(4);
      bytes.buffer.asByteData().setInt32(0, 99);
      final stream = XdrDataInputStream(bytes);
      expect(() => XdrLedgerUpgradeType.decode(stream), throwsException);
    });
  });

  group('XdrLedgerHeader', () {
    test('all setters', () {
      final hash = Uint8List(32);
      final header = XdrLedgerHeader(
        XdrUint32(20),
        XdrHash(hash),
        XdrStellarValue(XdrHash(hash), XdrUint64(BigInt.from(1000)), [], XdrStellarValueExt(XdrStellarValueType.STELLAR_VALUE_BASIC)),
        XdrHash(hash),
        XdrHash(hash),
        XdrUint32(100),
        XdrInt64(BigInt.from(1000000000)),
        XdrInt64(BigInt.from(5000)),
        XdrUint32(0),
        XdrUint64(BigInt.from(100)),
        XdrUint32(100),
        XdrUint32(100000),
        XdrUint32(1000),
        [XdrHash(hash), XdrHash(hash), XdrHash(hash), XdrHash(hash)],
        XdrLedgerHeaderExt(0),
      );

      header.ledgerVersion = XdrUint32(21);
      header.previousLedgerHash = XdrHash(hash);
      header.scpValue = XdrStellarValue(XdrHash(hash), XdrUint64(BigInt.from(2000)), [], XdrStellarValueExt(XdrStellarValueType.STELLAR_VALUE_BASIC));
      header.txSetResultHash = XdrHash(hash);
      header.bucketListHash = XdrHash(hash);
      header.ledgerSeq = XdrUint32(101);
      header.totalCoins = XdrInt64(BigInt.from(1000000001));
      header.feePool = XdrInt64(BigInt.from(5001));
      header.inflationSeq = XdrUint32(1);
      header.idPool = XdrUint64(BigInt.from(101));
      header.baseFee = XdrUint32(101);
      header.baseReserve = XdrUint32(100001);
      header.maxTxSetSize = XdrUint32(1001);
      header.skipList = [XdrHash(hash)];
      header.ext = XdrLedgerHeaderExt(0);

      expect(header.ledgerVersion.uint32, 21);
      expect(header.ledgerSeq.uint32, 101);
    });
  });

  group('XdrLedgerKey', () {
    test('forAccountId', () {
      final accountId = KeyPair.random().accountId;
      final key = XdrLedgerKey.forAccountId(accountId);
      expect(key.discriminant, XdrLedgerEntryType.ACCOUNT);
      expect(key.account, isNotNull);
    });

    test('forTrustLine', () {
      final accountId = KeyPair.random().accountId;
      final asset = Asset.createNonNativeAsset('USDC', KeyPair.random().accountId);
      final key = XdrLedgerKey.forTrustLine(accountId, asset.toXdr());
      expect(key.discriminant, XdrLedgerEntryType.TRUSTLINE);
      expect(key.trustLine, isNotNull);
    });

    test('forOffer', () {
      final sellerId = KeyPair.random().accountId;
      final key = XdrLedgerKey.forOffer(sellerId, 12345);
      expect(key.discriminant, XdrLedgerEntryType.OFFER);
      expect(key.offer, isNotNull);
    });

    test('forData', () {
      final accountId = KeyPair.random().accountId;
      final key = XdrLedgerKey.forData(accountId, 'test');
      expect(key.discriminant, XdrLedgerEntryType.DATA);
      expect(key.data, isNotNull);
    });

    test('forClaimableBalance', () {
      final key =
          XdrLedgerKey.forClaimableBalance('00000000$_balanceHashHex');
      expect(key.discriminant, XdrLedgerEntryType.CLAIMABLE_BALANCE);
      expect(Util.bytesToHex(key.balanceID!.v0!.hash), _balanceHashHex);
    });

    test('forLiquidityPool with hex id', () {
      final key = XdrLedgerKey.forLiquidityPool(_poolHashHex);
      expect(key.discriminant, XdrLedgerEntryType.LIQUIDITY_POOL);
      expect(Util.bytesToHex(key.liquidityPoolID!.hash), _poolHashHex);
    });

    test('forLiquidityPool with L prefix', () {
      final lId = StrKey.encodeLiquidityPoolId(Util.hexToBytes(_poolHashHex));
      final key = XdrLedgerKey.forLiquidityPool(lId);
      expect(key.discriminant, XdrLedgerEntryType.LIQUIDITY_POOL);
      expect(Util.bytesToHex(key.liquidityPoolID!.hash), _poolHashHex);
    });

    test('forLiquidityPool reports why an L id failed to decode', () {
      // An L-prefixed string is not hexadecimal, so a swallowed strkey failure
      // could only resurface as a hex parse error naming nothing useful.
      expect(
          () => XdrLedgerKey.forLiquidityPool('LINVALIDPOOLID'),
          throwsA(isA<FormatException>().having((e) => e.message, 'message',
              contains('Encoded string must be 56 characters, got 14'))));
    });

    test('forLiquidityPool refuses a hex id of a width other than 32 bytes', () {
      // A width the key cannot hold must be refused, not zero-padded or
      // truncated to a 32-byte hash that names a different pool.
      for (final entry in <String, int>{'00ff': 2, 'ff' * 40: 40}.entries) {
        expect(
            () => XdrLedgerKey.forLiquidityPool(entry.key),
            throwsA(isA<FormatException>().having(
                (e) => e.message,
                'message',
                'Liquidity pool id must be hex of a 32 byte hash; '
                    '${entry.value} bytes given')),
            reason: entry.key);
      }
    });

    test('forContractData', () {
      final contractId = Util.hexToBytes(
          'c5b72e9a00bf93dd6e54538e3ab40b9d5265b0634e228862de66cd7b4052a1d0');
      final address = XdrSCAddress.forContractId(
          StrKey.encodeContractId(contractId));
      final scKey = XdrSCVal.forU32(1);
      final key = XdrLedgerKey.forContractData(
          address, scKey, XdrContractDataDurability.TEMPORARY);
      expect(key.discriminant, XdrLedgerEntryType.CONTRACT_DATA);
      expect(key.contractData, isNotNull);
    });

    test('forContractCode', () {
      final code = Uint8List(32);
      final key = XdrLedgerKey.forContractCode(code);
      expect(key.discriminant, XdrLedgerEntryType.CONTRACT_CODE);
      expect(key.contractCode, isNotNull);
    });

    test('forConfigSetting', () {
      final key = XdrLedgerKey.forConfigSetting(
          XdrConfigSettingID.CONFIG_SETTING_CONTRACT_MAX_SIZE_BYTES);
      expect(key.discriminant, XdrLedgerEntryType.CONFIG_SETTING);
      expect(key.configSetting, isNotNull);
    });

    test('forTTL', () {
      final keyHash = Uint8List(32);
      final key = XdrLedgerKey.forTTL(keyHash);
      expect(key.discriminant, XdrLedgerEntryType.TTL);
      expect(key.ttl, isNotNull);
    });
  });
}
