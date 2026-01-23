// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('XDR Ledger Types - XdrLedgerEntryType', () {
    test('XdrLedgerEntryType enum encode/decode round-trip', () {
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

    test('XdrLedgerEntryType value mapping verification', () {
      expect(XdrLedgerEntryType.ACCOUNT.value, equals(0));
      expect(XdrLedgerEntryType.TRUSTLINE.value, equals(1));
      expect(XdrLedgerEntryType.OFFER.value, equals(2));
      expect(XdrLedgerEntryType.DATA.value, equals(3));
      expect(XdrLedgerEntryType.CLAIMABLE_BALANCE.value, equals(4));
      expect(XdrLedgerEntryType.LIQUIDITY_POOL.value, equals(5));
      expect(XdrLedgerEntryType.CONTRACT_DATA.value, equals(6));
      expect(XdrLedgerEntryType.CONTRACT_CODE.value, equals(7));
      expect(XdrLedgerEntryType.CONFIG_SETTING.value, equals(8));
      expect(XdrLedgerEntryType.TTL.value, equals(9));
    });

    test('XdrLedgerEntryType decode invalid value throws exception', () {
      XdrDataOutputStream output = XdrDataOutputStream();
      output.writeInt(999);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      expect(() => XdrLedgerEntryType.decode(input), throwsException);
    });
  });

  group('XDR Ledger Types - XdrTrustLineFlags', () {
    test('XdrTrustLineFlags enum decode round-trip', () {
      final flagValues = [1, 2, 4];

      for (var flagValue in flagValues) {
        XdrDataOutputStream output = XdrDataOutputStream();
        output.writeInt(flagValue);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrTrustLineFlags.decode(input);

        expect(decoded.value, equals(flagValue));
      }
    });

    test('XdrTrustLineFlags value mapping verification', () {
      expect(XdrTrustLineFlags.AUTHORIZED_FLAG.value, equals(1));
      expect(XdrTrustLineFlags.AUTHORIZED_TO_MAINTAIN_LIABILITIES_FLAG.value, equals(2));
      expect(XdrTrustLineFlags.TRUSTLINE_CLAWBACK_ENABLED_FLAG.value, equals(4));
    });

    test('XdrTrustLineFlags decode invalid value throws exception', () {
      XdrDataOutputStream output = XdrDataOutputStream();
      output.writeInt(8);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      expect(() => XdrTrustLineFlags.decode(input), throwsException);
    });
  });

  group('XDR Ledger Types - XdrTrustlineAsset', () {
    test('XdrTrustlineAsset ASSET_TYPE_NATIVE encode/decode round-trip', () {
      var original = XdrTrustlineAsset(XdrAssetType.ASSET_TYPE_NATIVE);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTrustlineAsset.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTrustlineAsset.decode(input);

      expect(decoded.discriminant.value, equals(original.discriminant.value));
      expect(decoded.alphaNum4, isNull);
      expect(decoded.alphaNum12, isNull);
      expect(decoded.poolId, isNull);
    });

    test('XdrTrustlineAsset ASSET_TYPE_CREDIT_ALPHANUM4 encode/decode round-trip', () {
      var assetCode = Uint8List.fromList([0x55, 0x53, 0x44, 0x00]);
      var issuerBytes = Uint8List.fromList(List<int>.filled(32, 0x11));
      var issuer = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      issuer.accountID.setEd25519(XdrUint256(issuerBytes));

      var original = XdrTrustlineAsset(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4);
      original.alphaNum4 = XdrAssetAlphaNum4(assetCode, issuer);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTrustlineAsset.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTrustlineAsset.decode(input);

      expect(decoded.discriminant.value, equals(original.discriminant.value));
      expect(decoded.alphaNum4!.assetCode, equals(assetCode));
      expect(decoded.alphaNum4!.issuer.accountID.getEd25519()!.uint256, equals(issuerBytes));
    });

    test('XdrTrustlineAsset ASSET_TYPE_CREDIT_ALPHANUM12 encode/decode round-trip', () {
      var assetCode = Uint8List.fromList([0x4C, 0x4F, 0x4E, 0x47, 0x41, 0x53, 0x53, 0x45, 0x54, 0x00, 0x00, 0x00]);
      var issuerBytes = Uint8List.fromList(List<int>.filled(32, 0x22));
      var issuer = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      issuer.accountID.setEd25519(XdrUint256(issuerBytes));

      var original = XdrTrustlineAsset(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12);
      original.alphaNum12 = XdrAssetAlphaNum12(assetCode, issuer);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTrustlineAsset.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTrustlineAsset.decode(input);

      expect(decoded.discriminant.value, equals(original.discriminant.value));
      expect(decoded.alphaNum12!.assetCode, equals(assetCode));
      expect(decoded.alphaNum12!.issuer.accountID.getEd25519()!.uint256, equals(issuerBytes));
    });

    test('XdrTrustlineAsset ASSET_TYPE_POOL_SHARE encode/decode round-trip', () {
      var poolIdBytes = Uint8List.fromList(List<int>.filled(32, 0xAB));
      var original = XdrTrustlineAsset(XdrAssetType.ASSET_TYPE_POOL_SHARE);
      original.poolId = XdrHash(poolIdBytes);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTrustlineAsset.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTrustlineAsset.decode(input);

      expect(decoded.discriminant.value, equals(original.discriminant.value));
      expect(decoded.poolId!.hash, equals(poolIdBytes));
    });
  });

  group('XDR Ledger Types - XdrTrustLineEntry', () {
    test('XdrTrustLineEntry basic encode/decode round-trip', () {
      var accountIdBytes = Uint8List.fromList(List<int>.filled(32, 0x01));
      var accountId = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      accountId.accountID.setEd25519(XdrUint256(accountIdBytes));

      var asset = XdrTrustlineAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var balance = XdrInt64(BigInt.from(1000000));
      var limit = XdrInt64(BigInt.from(10000000));
      var flags = XdrUint32(1);
      var ext = XdrTrustLineEntryExt(0);

      var original = XdrTrustLineEntry(accountId, asset, balance, limit, flags, ext);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTrustLineEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTrustLineEntry.decode(input);

      expect(decoded.accountID.accountID.getEd25519()!.uint256, equals(accountIdBytes));
      expect(decoded.asset.discriminant.value, equals(asset.discriminant.value));
      expect(decoded.balance.int64, equals(balance.int64));
      expect(decoded.limit.int64, equals(limit.int64));
      expect(decoded.flags.uint32, equals(flags.uint32));
      expect(decoded.ext.discriminant, equals(0));
    });

    test('XdrTrustLineEntry with ASSET_TYPE_CREDIT_ALPHANUM4', () {
      var accountIdBytes = Uint8List.fromList(List<int>.filled(32, 0x02));
      var accountId = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      accountId.accountID.setEd25519(XdrUint256(accountIdBytes));

      var assetCode = Uint8List.fromList([0x55, 0x53, 0x44, 0x00]);
      var issuerBytes = Uint8List.fromList(List<int>.filled(32, 0x03));
      var issuer = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      issuer.accountID.setEd25519(XdrUint256(issuerBytes));

      var asset = XdrTrustlineAsset(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4);
      asset.alphaNum4 = XdrAssetAlphaNum4(assetCode, issuer);

      var balance = XdrInt64(BigInt.from(500000));
      var limit = XdrInt64(BigInt.from(5000000));
      var flags = XdrUint32(2);
      var ext = XdrTrustLineEntryExt(0);

      var original = XdrTrustLineEntry(accountId, asset, balance, limit, flags, ext);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTrustLineEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTrustLineEntry.decode(input);

      expect(decoded.accountID.accountID.getEd25519()!.uint256, equals(accountIdBytes));
      expect(decoded.asset.discriminant.value, equals(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4.value));
      expect(decoded.asset.alphaNum4!.assetCode, equals(assetCode));
      expect(decoded.balance.int64, equals(BigInt.from(500000)));
      expect(decoded.limit.int64, equals(BigInt.from(5000000)));
      expect(decoded.flags.uint32, equals(2));
    });

    test('XdrTrustLineEntry with zero balance and limit', () {
      var accountIdBytes = Uint8List.fromList(List<int>.filled(32, 0x04));
      var accountId = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      accountId.accountID.setEd25519(XdrUint256(accountIdBytes));

      var asset = XdrTrustlineAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var balance = XdrInt64(BigInt.zero);
      var limit = XdrInt64(BigInt.zero);
      var flags = XdrUint32(0);
      var ext = XdrTrustLineEntryExt(0);

      var original = XdrTrustLineEntry(accountId, asset, balance, limit, flags, ext);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTrustLineEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTrustLineEntry.decode(input);

      expect(decoded.balance.int64, equals(BigInt.zero));
      expect(decoded.limit.int64, equals(BigInt.zero));
      expect(decoded.flags.uint32, equals(0));
    });

    test('XdrTrustLineEntry with maximum values', () {
      var accountIdBytes = Uint8List.fromList(List<int>.filled(32, 0xFF));
      var accountId = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      accountId.accountID.setEd25519(XdrUint256(accountIdBytes));

      var asset = XdrTrustlineAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var balance = XdrInt64(BigInt.parse('9223372036854775807'));
      var limit = XdrInt64(BigInt.parse('9223372036854775807'));
      var flags = XdrUint32(2147483647);
      var ext = XdrTrustLineEntryExt(0);

      var original = XdrTrustLineEntry(accountId, asset, balance, limit, flags, ext);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTrustLineEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTrustLineEntry.decode(input);

      expect(decoded.balance.int64, equals(BigInt.parse('9223372036854775807')));
      expect(decoded.limit.int64, equals(BigInt.parse('9223372036854775807')));
      expect(decoded.flags.uint32, equals(2147483647));
    });
  });

  group('XDR Ledger Types - XdrTrustLineEntryExt', () {
    test('XdrTrustLineEntryExt discriminant 0 encode/decode round-trip', () {
      var original = XdrTrustLineEntryExt(0);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTrustLineEntryExt.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTrustLineEntryExt.decode(input);

      expect(decoded.discriminant, equals(0));
      expect(decoded.v1, isNull);
    });

    test('XdrTrustLineEntryExt discriminant 1 with v1 data', () {
      var liabilities = XdrLiabilities(XdrInt64(BigInt.from(1000)), XdrInt64(BigInt.from(2000)));
      var v1Ext = XdrTrustLineEntryV1Ext(0);
      var v1 = XdrTrustLineEntryV1(liabilities, v1Ext);

      var original = XdrTrustLineEntryExt(1);
      original.v1 = v1;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTrustLineEntryExt.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTrustLineEntryExt.decode(input);

      expect(decoded.discriminant, equals(1));
      expect(decoded.v1, isNotNull);
      expect(decoded.v1!.liabilities.buying.int64, equals(BigInt.from(1000)));
      expect(decoded.v1!.liabilities.selling.int64, equals(BigInt.from(2000)));
    });
  });

  group('XDR Ledger Types - XdrOfferEntry', () {
    test('XdrOfferEntry basic encode/decode round-trip', () {
      var sellerIdBytes = Uint8List.fromList(List<int>.filled(32, 0x05));
      var sellerId = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      sellerId.accountID.setEd25519(XdrUint256(sellerIdBytes));

      var offerId = XdrUint64(BigInt.from(12345));

      var selling = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);

      var assetCode = Uint8List.fromList([0x55, 0x53, 0x44, 0x00]);
      var issuerBytes = Uint8List.fromList(List<int>.filled(32, 0x06));
      var issuer = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      issuer.accountID.setEd25519(XdrUint256(issuerBytes));
      var buying = XdrAsset(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4);
      buying.alphaNum4 = XdrAssetAlphaNum4(assetCode, issuer);

      var amount = XdrInt64(BigInt.from(1000000));
      var price = XdrPrice(XdrInt32(1), XdrInt32(2));
      var flags = XdrUint32(0);
      var ext = XdrOfferEntryExt(0);

      var original = XdrOfferEntry(sellerId, offerId, selling, buying, amount, price, flags, ext);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOfferEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOfferEntry.decode(input);

      expect(decoded.sellerID.accountID.getEd25519()!.uint256, equals(sellerIdBytes));
      expect(decoded.offerID.uint64, equals(BigInt.from(12345)));
      expect(decoded.selling.discriminant.value, equals(XdrAssetType.ASSET_TYPE_NATIVE.value));
      expect(decoded.buying.discriminant.value, equals(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4.value));
      expect(decoded.amount.int64, equals(BigInt.from(1000000)));
      expect(decoded.price.n.int32, equals(1));
      expect(decoded.price.d.int32, equals(2));
      expect(decoded.flags.uint32, equals(0));
      expect(decoded.ext.discriminant, equals(0));
    });

    test('XdrOfferEntry with ALPHANUM12 assets', () {
      var sellerIdBytes = Uint8List.fromList(List<int>.filled(32, 0x07));
      var sellerId = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      sellerId.accountID.setEd25519(XdrUint256(sellerIdBytes));

      var offerId = XdrUint64(BigInt.from(67890));

      var sellingCode = Uint8List.fromList([0x41, 0x53, 0x53, 0x45, 0x54, 0x31, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]);
      var sellingIssuerBytes = Uint8List.fromList(List<int>.filled(32, 0x08));
      var sellingIssuer = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      sellingIssuer.accountID.setEd25519(XdrUint256(sellingIssuerBytes));
      var selling = XdrAsset(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12);
      selling.alphaNum12 = XdrAssetAlphaNum12(sellingCode, sellingIssuer);

      var buyingCode = Uint8List.fromList([0x42, 0x53, 0x53, 0x45, 0x54, 0x32, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]);
      var buyingIssuerBytes = Uint8List.fromList(List<int>.filled(32, 0x09));
      var buyingIssuer = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      buyingIssuer.accountID.setEd25519(XdrUint256(buyingIssuerBytes));
      var buying = XdrAsset(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12);
      buying.alphaNum12 = XdrAssetAlphaNum12(buyingCode, buyingIssuer);

      var amount = XdrInt64(BigInt.from(500000));
      var price = XdrPrice(XdrInt32(3), XdrInt32(4));
      var flags = XdrUint32(1);
      var ext = XdrOfferEntryExt(0);

      var original = XdrOfferEntry(sellerId, offerId, selling, buying, amount, price, flags, ext);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOfferEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOfferEntry.decode(input);

      expect(decoded.sellerID.accountID.getEd25519()!.uint256, equals(sellerIdBytes));
      expect(decoded.offerID.uint64, equals(BigInt.from(67890)));
      expect(decoded.selling.alphaNum12!.assetCode, equals(sellingCode));
      expect(decoded.buying.alphaNum12!.assetCode, equals(buyingCode));
      expect(decoded.amount.int64, equals(BigInt.from(500000)));
      expect(decoded.price.n.int32, equals(3));
      expect(decoded.price.d.int32, equals(4));
      expect(decoded.flags.uint32, equals(1));
    });

    test('XdrOfferEntry with different price ratios', () {
      final priceRatios = [
        [1, 1],
        [1, 10],
        [100, 1],
        [123, 456],
      ];

      for (var ratio in priceRatios) {
        var sellerIdBytes = Uint8List.fromList(List<int>.filled(32, 0x0A));
        var sellerId = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
        sellerId.accountID.setEd25519(XdrUint256(sellerIdBytes));

        var offerId = XdrUint64(BigInt.from(1));
        var selling = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
        var buying = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
        var amount = XdrInt64(BigInt.from(1000));
        var price = XdrPrice(XdrInt32(ratio[0]), XdrInt32(ratio[1]));
        var flags = XdrUint32(0);
        var ext = XdrOfferEntryExt(0);

        var original = XdrOfferEntry(sellerId, offerId, selling, buying, amount, price, flags, ext);

        XdrDataOutputStream output = XdrDataOutputStream();
        XdrOfferEntry.encode(output, original);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrOfferEntry.decode(input);

        expect(decoded.price.n.int32, equals(ratio[0]));
        expect(decoded.price.d.int32, equals(ratio[1]));
      }
    });
  });

  group('XDR Ledger Types - XdrOfferEntryFlags', () {
    test('XdrOfferEntryFlags PASSIVE_FLAG encode/decode round-trip', () {
      var flag = XdrOfferEntryFlags.PASSIVE_FLAG;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOfferEntryFlags.encode(output, flag);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOfferEntryFlags.decode(input);

      expect(decoded.value, equals(1));
    });

    test('XdrOfferEntryFlags value verification', () {
      expect(XdrOfferEntryFlags.PASSIVE_FLAG.value, equals(1));
    });
  });

  group('XDR Ledger Types - XdrDataEntry', () {
    test('XdrDataEntry basic encode/decode round-trip', () {
      var accountIdBytes = Uint8List.fromList(List<int>.filled(32, 0x0B));
      var accountId = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      accountId.accountID.setEd25519(XdrUint256(accountIdBytes));

      var dataName = XdrString64('config');
      var dataValue = XdrDataValue(Uint8List.fromList([0x01, 0x02, 0x03, 0x04]));
      var ext = XdrDataEntryExt(0);

      var original = XdrDataEntry(accountId, dataName, dataValue, ext);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrDataEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrDataEntry.decode(input);

      expect(decoded.accountID.accountID.getEd25519()!.uint256, equals(accountIdBytes));
      expect(decoded.dataName.string64, equals('config'));
      expect(decoded.dataValue.dataValue, equals(Uint8List.fromList([0x01, 0x02, 0x03, 0x04])));
      expect(decoded.ext.discriminant, equals(0));
    });

    test('XdrDataEntry with empty data value', () {
      var accountIdBytes = Uint8List.fromList(List<int>.filled(32, 0x0C));
      var accountId = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      accountId.accountID.setEd25519(XdrUint256(accountIdBytes));

      var dataName = XdrString64('empty');
      var dataValue = XdrDataValue(Uint8List(0));
      var ext = XdrDataEntryExt(0);

      var original = XdrDataEntry(accountId, dataName, dataValue, ext);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrDataEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrDataEntry.decode(input);

      expect(decoded.dataName.string64, equals('empty'));
      expect(decoded.dataValue.dataValue.length, equals(0));
    });

    test('XdrDataEntry with long data name', () {
      var accountIdBytes = Uint8List.fromList(List<int>.filled(32, 0x0D));
      var accountId = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      accountId.accountID.setEd25519(XdrUint256(accountIdBytes));

      var dataName = XdrString64('very_long_configuration_name_for_testing_purpose');
      var dataValue = XdrDataValue(Uint8List.fromList([0xFF, 0xEE, 0xDD]));
      var ext = XdrDataEntryExt(0);

      var original = XdrDataEntry(accountId, dataName, dataValue, ext);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrDataEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrDataEntry.decode(input);

      expect(decoded.dataName.string64, equals('very_long_configuration_name_for_testing_purpose'));
      expect(decoded.dataValue.dataValue, equals(Uint8List.fromList([0xFF, 0xEE, 0xDD])));
    });

    test('XdrDataEntry with large data value', () {
      var accountIdBytes = Uint8List.fromList(List<int>.filled(32, 0x0E));
      var accountId = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      accountId.accountID.setEd25519(XdrUint256(accountIdBytes));

      var dataName = XdrString64('large_data');
      var largeData = Uint8List.fromList(List<int>.generate(100, (i) => i % 256));
      var dataValue = XdrDataValue(largeData);
      var ext = XdrDataEntryExt(0);

      var original = XdrDataEntry(accountId, dataName, dataValue, ext);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrDataEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrDataEntry.decode(input);

      expect(decoded.dataName.string64, equals('large_data'));
      expect(decoded.dataValue.dataValue, equals(largeData));
    });
  });

  group('XDR Ledger Types - XdrDataValue', () {
    test('XdrDataValue encode/decode round-trip', () {
      var original = XdrDataValue(Uint8List.fromList([0xAA, 0xBB, 0xCC, 0xDD]));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrDataValue.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrDataValue.decode(input);

      expect(decoded.dataValue, equals(Uint8List.fromList([0xAA, 0xBB, 0xCC, 0xDD])));
    });

    test('XdrDataValue with various byte patterns', () {
      final patterns = [
        Uint8List.fromList([0x00]),
        Uint8List.fromList([0xFF]),
        Uint8List.fromList([0x00, 0xFF, 0x00, 0xFF]),
        Uint8List.fromList(List<int>.filled(64, 0x42)),
      ];

      for (var pattern in patterns) {
        var original = XdrDataValue(pattern);

        XdrDataOutputStream output = XdrDataOutputStream();
        XdrDataValue.encode(output, original);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrDataValue.decode(input);

        expect(decoded.dataValue, equals(pattern));
      }
    });
  });

  group('XDR Ledger Types - XdrLedgerEntry', () {
    test('XdrLedgerEntry with DATA entry type', () {
      var lastModifiedLedgerSeq = XdrUint32(12345);

      var accountIdBytes = Uint8List.fromList(List<int>.filled(32, 0x0F));
      var accountId = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      accountId.accountID.setEd25519(XdrUint256(accountIdBytes));

      var dataName = XdrString64('test_data');
      var dataValue = XdrDataValue(Uint8List.fromList([0x11, 0x22, 0x33]));
      var dataExt = XdrDataEntryExt(0);
      var dataEntry = XdrDataEntry(accountId, dataName, dataValue, dataExt);

      var data = XdrLedgerEntryData(XdrLedgerEntryType.DATA);
      data.data = dataEntry;

      var ext = XdrLedgerEntryExt(0);

      var original = XdrLedgerEntry(lastModifiedLedgerSeq, data, ext);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerEntry.decode(input);

      expect(decoded.lastModifiedLedgerSeq.uint32, equals(12345));
      expect(decoded.data.discriminant.value, equals(XdrLedgerEntryType.DATA.value));
      expect(decoded.data.data!.dataName.string64, equals('test_data'));
      expect(decoded.data.data!.dataValue.dataValue, equals(Uint8List.fromList([0x11, 0x22, 0x33])));
    });

    test('XdrLedgerEntry with TRUSTLINE entry type', () {
      var lastModifiedLedgerSeq = XdrUint32(54321);

      var accountIdBytes = Uint8List.fromList(List<int>.filled(32, 0x10));
      var accountId = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      accountId.accountID.setEd25519(XdrUint256(accountIdBytes));

      var asset = XdrTrustlineAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var balance = XdrInt64(BigInt.from(1000000));
      var limit = XdrInt64(BigInt.from(10000000));
      var flags = XdrUint32(1);
      var trustLineExt = XdrTrustLineEntryExt(0);

      var trustLineEntry = XdrTrustLineEntry(accountId, asset, balance, limit, flags, trustLineExt);

      var data = XdrLedgerEntryData(XdrLedgerEntryType.TRUSTLINE);
      data.trustLine = trustLineEntry;

      var ext = XdrLedgerEntryExt(0);

      var original = XdrLedgerEntry(lastModifiedLedgerSeq, data, ext);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerEntry.decode(input);

      expect(decoded.lastModifiedLedgerSeq.uint32, equals(54321));
      expect(decoded.data.discriminant.value, equals(XdrLedgerEntryType.TRUSTLINE.value));
      expect(decoded.data.trustLine!.balance.int64, equals(BigInt.from(1000000)));
      expect(decoded.data.trustLine!.limit.int64, equals(BigInt.from(10000000)));
    });

    test('XdrLedgerEntry with OFFER entry type', () {
      var lastModifiedLedgerSeq = XdrUint32(99999);

      var sellerIdBytes = Uint8List.fromList(List<int>.filled(32, 0x11));
      var sellerId = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      sellerId.accountID.setEd25519(XdrUint256(sellerIdBytes));

      var offerId = XdrUint64(BigInt.from(777));
      var selling = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var buying = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var amount = XdrInt64(BigInt.from(5000000));
      var price = XdrPrice(XdrInt32(1), XdrInt32(1));
      var flags = XdrUint32(0);
      var offerExt = XdrOfferEntryExt(0);

      var offerEntry = XdrOfferEntry(sellerId, offerId, selling, buying, amount, price, flags, offerExt);

      var data = XdrLedgerEntryData(XdrLedgerEntryType.OFFER);
      data.offer = offerEntry;

      var ext = XdrLedgerEntryExt(0);

      var original = XdrLedgerEntry(lastModifiedLedgerSeq, data, ext);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerEntry.decode(input);

      expect(decoded.lastModifiedLedgerSeq.uint32, equals(99999));
      expect(decoded.data.discriminant.value, equals(XdrLedgerEntryType.OFFER.value));
      expect(decoded.data.offer!.offerID.uint64, equals(BigInt.from(777)));
      expect(decoded.data.offer!.amount.int64, equals(BigInt.from(5000000)));
    });
  });

  group('XDR Ledger Types - XdrLedgerEntryExt', () {
    test('XdrLedgerEntryExt discriminant 0 encode/decode round-trip', () {
      var original = XdrLedgerEntryExt(0);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerEntryExt.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerEntryExt.decode(input);

      expect(decoded.discriminant, equals(0));
    });
  });

  group('XDR Ledger Types - XdrLedgerEntryData', () {
    test('XdrLedgerEntryData with ACCOUNT discriminant', () {
      var data = XdrLedgerEntryData(XdrLedgerEntryType.ACCOUNT);
      expect(data.discriminant.value, equals(XdrLedgerEntryType.ACCOUNT.value));
    });

    test('XdrLedgerEntryData with TRUSTLINE discriminant', () {
      var data = XdrLedgerEntryData(XdrLedgerEntryType.TRUSTLINE);
      expect(data.discriminant.value, equals(XdrLedgerEntryType.TRUSTLINE.value));
    });

    test('XdrLedgerEntryData with OFFER discriminant', () {
      var data = XdrLedgerEntryData(XdrLedgerEntryType.OFFER);
      expect(data.discriminant.value, equals(XdrLedgerEntryType.OFFER.value));
    });

    test('XdrLedgerEntryData with DATA discriminant', () {
      var data = XdrLedgerEntryData(XdrLedgerEntryType.DATA);
      expect(data.discriminant.value, equals(XdrLedgerEntryType.DATA.value));
    });
  });

  group('XDR Ledger Types - Complex Scenarios', () {
    test('Multiple TrustLineEntry with different assets', () {
      final assetTypes = [
        XdrAssetType.ASSET_TYPE_NATIVE,
        XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4,
        XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12,
      ];

      for (var assetType in assetTypes) {
        var accountIdBytes = Uint8List.fromList(List<int>.filled(32, 0x12));
        var accountId = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
        accountId.accountID.setEd25519(XdrUint256(accountIdBytes));

        var asset = XdrTrustlineAsset(assetType);
        if (assetType == XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4) {
          var assetCode = Uint8List.fromList([0x55, 0x53, 0x44, 0x00]);
          var issuerBytes = Uint8List.fromList(List<int>.filled(32, 0x13));
          var issuer = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
          issuer.accountID.setEd25519(XdrUint256(issuerBytes));
          asset.alphaNum4 = XdrAssetAlphaNum4(assetCode, issuer);
        } else if (assetType == XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12) {
          var assetCode = Uint8List.fromList([0x4C, 0x4F, 0x4E, 0x47, 0x41, 0x53, 0x53, 0x45, 0x54, 0x00, 0x00, 0x00]);
          var issuerBytes = Uint8List.fromList(List<int>.filled(32, 0x14));
          var issuer = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
          issuer.accountID.setEd25519(XdrUint256(issuerBytes));
          asset.alphaNum12 = XdrAssetAlphaNum12(assetCode, issuer);
        }

        var balance = XdrInt64(BigInt.from(1000000));
        var limit = XdrInt64(BigInt.from(10000000));
        var flags = XdrUint32(1);
        var ext = XdrTrustLineEntryExt(0);

        var original = XdrTrustLineEntry(accountId, asset, balance, limit, flags, ext);

        XdrDataOutputStream output = XdrDataOutputStream();
        XdrTrustLineEntry.encode(output, original);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrTrustLineEntry.decode(input);

        expect(decoded.asset.discriminant.value, equals(assetType.value));
      }
    });

    test('DataEntry with various data name patterns', () {
      final dataNames = [
        'a',
        'config',
        'user_settings',
        'app.configuration.advanced',
        'very_long_name_with_many_characters_to_test_limits',
      ];

      for (var name in dataNames) {
        var accountIdBytes = Uint8List.fromList(List<int>.filled(32, 0x15));
        var accountId = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
        accountId.accountID.setEd25519(XdrUint256(accountIdBytes));

        var dataName = XdrString64(name);
        var dataValue = XdrDataValue(Uint8List.fromList([0x01]));
        var ext = XdrDataEntryExt(0);

        var original = XdrDataEntry(accountId, dataName, dataValue, ext);

        XdrDataOutputStream output = XdrDataOutputStream();
        XdrDataEntry.encode(output, original);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrDataEntry.decode(input);

        expect(decoded.dataName.string64, equals(name));
      }
    });

    test('OfferEntry with different flag values', () {
      final flagValues = [0, 1];

      for (var flagValue in flagValues) {
        var sellerIdBytes = Uint8List.fromList(List<int>.filled(32, 0x16));
        var sellerId = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
        sellerId.accountID.setEd25519(XdrUint256(sellerIdBytes));

        var offerId = XdrUint64(BigInt.from(1));
        var selling = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
        var buying = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
        var amount = XdrInt64(BigInt.from(1000));
        var price = XdrPrice(XdrInt32(1), XdrInt32(1));
        var flags = XdrUint32(flagValue);
        var ext = XdrOfferEntryExt(0);

        var original = XdrOfferEntry(sellerId, offerId, selling, buying, amount, price, flags, ext);

        XdrDataOutputStream output = XdrDataOutputStream();
        XdrOfferEntry.encode(output, original);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrOfferEntry.decode(input);

        expect(decoded.flags.uint32, equals(flagValue));
      }
    });

    test('LedgerEntry with different lastModifiedLedgerSeq values', () {
      final seqValues = [1, 100, 10000, 1000000, 2147483647];

      for (var seqValue in seqValues) {
        var lastModifiedLedgerSeq = XdrUint32(seqValue);

        var accountIdBytes = Uint8List.fromList(List<int>.filled(32, 0x17));
        var accountId = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
        accountId.accountID.setEd25519(XdrUint256(accountIdBytes));

        var dataName = XdrString64('test');
        var dataValue = XdrDataValue(Uint8List.fromList([0x01]));
        var dataExt = XdrDataEntryExt(0);
        var dataEntry = XdrDataEntry(accountId, dataName, dataValue, dataExt);

        var data = XdrLedgerEntryData(XdrLedgerEntryType.DATA);
        data.data = dataEntry;

        var ext = XdrLedgerEntryExt(0);

        var original = XdrLedgerEntry(lastModifiedLedgerSeq, data, ext);

        XdrDataOutputStream output = XdrDataOutputStream();
        XdrLedgerEntry.encode(output, original);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrLedgerEntry.decode(input);

        expect(decoded.lastModifiedLedgerSeq.uint32, equals(seqValue));
      }
    });

    test('TrustLineEntry with different flag combinations', () {
      final flagCombinations = [
        0,
        1,
        2,
        3,
        4,
        5,
        6,
        7,
      ];

      for (var flagValue in flagCombinations) {
        var accountIdBytes = Uint8List.fromList(List<int>.filled(32, 0x18));
        var accountId = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
        accountId.accountID.setEd25519(XdrUint256(accountIdBytes));

        var asset = XdrTrustlineAsset(XdrAssetType.ASSET_TYPE_NATIVE);
        var balance = XdrInt64(BigInt.from(1000));
        var limit = XdrInt64(BigInt.from(10000));
        var flags = XdrUint32(flagValue);
        var ext = XdrTrustLineEntryExt(0);

        var original = XdrTrustLineEntry(accountId, asset, balance, limit, flags, ext);

        XdrDataOutputStream output = XdrDataOutputStream();
        XdrTrustLineEntry.encode(output, original);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrTrustLineEntry.decode(input);

        expect(decoded.flags.uint32, equals(flagValue));
      }
    });

    test('OfferEntry with zero amount', () {
      var sellerIdBytes = Uint8List.fromList(List<int>.filled(32, 0x19));
      var sellerId = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      sellerId.accountID.setEd25519(XdrUint256(sellerIdBytes));

      var offerId = XdrUint64(BigInt.from(1));
      var selling = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var buying = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var amount = XdrInt64(BigInt.zero);
      var price = XdrPrice(XdrInt32(1), XdrInt32(1));
      var flags = XdrUint32(0);
      var ext = XdrOfferEntryExt(0);

      var original = XdrOfferEntry(sellerId, offerId, selling, buying, amount, price, flags, ext);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOfferEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOfferEntry.decode(input);

      expect(decoded.amount.int64, equals(BigInt.zero));
    });

    test('DataEntry with special characters in name', () {
      var accountIdBytes = Uint8List.fromList(List<int>.filled(32, 0x1A));
      var accountId = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      accountId.accountID.setEd25519(XdrUint256(accountIdBytes));

      var dataName = XdrString64('config.app.settings');
      var dataValue = XdrDataValue(Uint8List.fromList([0x01, 0x02]));
      var ext = XdrDataEntryExt(0);

      var original = XdrDataEntry(accountId, dataName, dataValue, ext);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrDataEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrDataEntry.decode(input);

      expect(decoded.dataName.string64, equals('config.app.settings'));
    });

    test('TrustlineAsset with different pool IDs', () {
      final poolIds = [
        Uint8List.fromList(List<int>.filled(32, 0x00)),
        Uint8List.fromList(List<int>.filled(32, 0xFF)),
        Uint8List.fromList(List.generate(32, (i) => i)),
      ];

      for (var poolIdBytes in poolIds) {
        var original = XdrTrustlineAsset(XdrAssetType.ASSET_TYPE_POOL_SHARE);
        original.poolId = XdrHash(poolIdBytes);

        XdrDataOutputStream output = XdrDataOutputStream();
        XdrTrustlineAsset.encode(output, original);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrTrustlineAsset.decode(input);

        expect(decoded.poolId!.hash, equals(poolIdBytes));
      }
    });

    test('OfferEntry with very large offer ID', () {
      var sellerIdBytes = Uint8List.fromList(List<int>.filled(32, 0x1B));
      var sellerId = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      sellerId.accountID.setEd25519(XdrUint256(sellerIdBytes));

      var offerId = XdrUint64(BigInt.parse('18446744073709551615'));
      var selling = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var buying = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var amount = XdrInt64(BigInt.from(1000));
      var price = XdrPrice(XdrInt32(1), XdrInt32(1));
      var flags = XdrUint32(0);
      var ext = XdrOfferEntryExt(0);

      var original = XdrOfferEntry(sellerId, offerId, selling, buying, amount, price, flags, ext);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOfferEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOfferEntry.decode(input);

      expect(decoded.offerID.uint64, equals(BigInt.parse('18446744073709551615')));
    });

    test('DataValue with single byte', () {
      var original = XdrDataValue(Uint8List.fromList([0x42]));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrDataValue.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrDataValue.decode(input);

      expect(decoded.dataValue, equals(Uint8List.fromList([0x42])));
      expect(decoded.dataValue.length, equals(1));
    });

    test('TrustLineEntry balance equals limit', () {
      var accountIdBytes = Uint8List.fromList(List<int>.filled(32, 0x1C));
      var accountId = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      accountId.accountID.setEd25519(XdrUint256(accountIdBytes));

      var asset = XdrTrustlineAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var balance = XdrInt64(BigInt.from(5000000));
      var limit = XdrInt64(BigInt.from(5000000));
      var flags = XdrUint32(1);
      var ext = XdrTrustLineEntryExt(0);

      var original = XdrTrustLineEntry(accountId, asset, balance, limit, flags, ext);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTrustLineEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTrustLineEntry.decode(input);

      expect(decoded.balance.int64, equals(decoded.limit.int64));
    });

    test('OfferEntry price with equal numerator and denominator', () {
      var sellerIdBytes = Uint8List.fromList(List<int>.filled(32, 0x1D));
      var sellerId = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      sellerId.accountID.setEd25519(XdrUint256(sellerIdBytes));

      var offerId = XdrUint64(BigInt.from(100));
      var selling = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var buying = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var amount = XdrInt64(BigInt.from(1000));
      var price = XdrPrice(XdrInt32(100), XdrInt32(100));
      var flags = XdrUint32(0);
      var ext = XdrOfferEntryExt(0);

      var original = XdrOfferEntry(sellerId, offerId, selling, buying, amount, price, flags, ext);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOfferEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOfferEntry.decode(input);

      expect(decoded.price.n.int32, equals(decoded.price.d.int32));
      expect(decoded.price.n.int32, equals(100));
    });
  });
}
