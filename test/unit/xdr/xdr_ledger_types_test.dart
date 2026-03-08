// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('XDR Ledger Types - XdrLedgerEntryType', () {
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

  group('XDR Ledger Types - XdrTrustLineEntry', () {
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

  group('XDR Ledger Types - XdrOfferEntry', () {
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
    test('XdrOfferEntryFlags value verification', () {
      expect(XdrOfferEntryFlags.PASSIVE_FLAG.value, equals(1));
    });
  });

  group('XDR Ledger Types - XdrDataEntry', () {
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
        original.liquidityPoolID = XdrHash(poolIdBytes);

        XdrDataOutputStream output = XdrDataOutputStream();
        XdrTrustlineAsset.encode(output, original);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrTrustlineAsset.decode(input);

        expect(decoded.liquidityPoolID!.hash, equals(poolIdBytes));
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
