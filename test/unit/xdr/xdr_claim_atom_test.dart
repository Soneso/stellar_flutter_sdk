// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('XDR Other Types - Deep Branch Testing', () {
    test('XdrPrice encode/decode with negative values', () {
      var original = XdrPrice(
        XdrInt32(-100),
        XdrInt32(50),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrPrice.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrPrice.decode(input);

      expect(decoded.n.int32, equals(original.n.int32));
      expect(decoded.d.int32, equals(original.d.int32));
    });

    test('XdrPrice encode/decode with large values', () {
      var original = XdrPrice(
        XdrInt32(2147483647),
        XdrInt32(1),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrPrice.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrPrice.decode(input);

      expect(decoded.n.int32, equals(original.n.int32));
      expect(decoded.d.int32, equals(original.d.int32));
    });

    test('XdrStellarValue encode/decode round-trip with empty upgrades', () {
      var ext = XdrStellarValueExt(XdrStellarValueType.STELLAR_VALUE_BASIC);

      var original = XdrStellarValue(
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0x66))),
        XdrUint64(BigInt.from(1234567890)),
        [],
        ext,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrStellarValue.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrStellarValue.decode(input);

      expect(decoded.txSetHash.hash, equals(original.txSetHash.hash));
      expect(decoded.closeTime.uint64, equals(original.closeTime.uint64));
      expect(decoded.upgrades, isEmpty);
      expect(decoded.ext.discriminant, equals(XdrStellarValueType.STELLAR_VALUE_BASIC));
    });

    test('XdrStellarValue encode/decode round-trip with upgrades', () {
      var ext = XdrStellarValueExt(XdrStellarValueType.STELLAR_VALUE_BASIC);

      var upgrade = XdrUpgradeType(Uint8List.fromList([1, 2, 3, 4]));

      var original = XdrStellarValue(
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0x77))),
        XdrUint64(BigInt.from(9876543210)),
        [upgrade],
        ext,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrStellarValue.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrStellarValue.decode(input);

      expect(decoded.txSetHash.hash, equals(original.txSetHash.hash));
      expect(decoded.closeTime.uint64, equals(original.closeTime.uint64));
      expect(decoded.upgrades.length, equals(1));
      expect(decoded.upgrades[0].upgradeType, equals(upgrade.upgradeType));
      expect(decoded.ext.discriminant, equals(XdrStellarValueType.STELLAR_VALUE_BASIC));
    });

    test('XdrStellarValue encode/decode with multiple upgrades', () {
      var ext = XdrStellarValueExt(XdrStellarValueType.STELLAR_VALUE_BASIC);

      var upgrade1 = XdrUpgradeType(Uint8List.fromList([1, 2, 3, 4]));
      var upgrade2 = XdrUpgradeType(Uint8List.fromList([5, 6, 7, 8]));

      var original = XdrStellarValue(
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0x88))),
        XdrUint64(BigInt.from(5555555555)),
        [upgrade1, upgrade2],
        ext,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrStellarValue.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrStellarValue.decode(input);

      expect(decoded.txSetHash.hash, equals(original.txSetHash.hash));
      expect(decoded.closeTime.uint64, equals(original.closeTime.uint64));
      expect(decoded.upgrades.length, equals(2));
      expect(decoded.upgrades[0].upgradeType, equals(upgrade1.upgradeType));
      expect(decoded.upgrades[1].upgradeType, equals(upgrade2.upgradeType));
      expect(decoded.ext.discriminant, equals(XdrStellarValueType.STELLAR_VALUE_BASIC));
    });

    test('XdrClaimOfferAtomV0 with different asset types', () {
      var assetCode = XdrAssetAlphaNum4(
        Uint8List.fromList('USD '.codeUnits),
        XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H'),
      );
      var asset = XdrAsset(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4);
      asset.alphaNum4 = assetCode;

      var original = XdrClaimOfferAtomV0(
        XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x99))),
        XdrUint64(BigInt.from(1111)),
        asset,
        XdrInt64(BigInt.from(9999)),
        XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE),
        XdrInt64(BigInt.from(8888)),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrClaimOfferAtomV0.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrClaimOfferAtomV0.decode(input);

      expect(decoded.sellerEd25519.uint256, equals(original.sellerEd25519.uint256));
      expect(decoded.offerID.uint64, equals(original.offerID.uint64));
      expect(decoded.assetSold.discriminant, equals(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4));
      expect(decoded.amountSold.int64, equals(original.amountSold.int64));
      expect(decoded.amountBought.int64, equals(original.amountBought.int64));
    });

    test('XdrLiabilities with zero values', () {
      var original = XdrLiabilities(
        XdrInt64(BigInt.zero),
        XdrInt64(BigInt.zero),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLiabilities.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLiabilities.decode(input);

      expect(decoded.buying.int64, equals(BigInt.zero));
      expect(decoded.selling.int64, equals(BigInt.zero));
    });

    test('XdrLiabilities with large values', () {
      var original = XdrLiabilities(
        XdrInt64(BigInt.parse('9223372036854775807')),
        XdrInt64(BigInt.parse('9223372036854775806')),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLiabilities.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLiabilities.decode(input);

      expect(decoded.buying.int64, equals(original.buying.int64));
      expect(decoded.selling.int64, equals(original.selling.int64));
    });

    test('XdrDontHave with different message types', () {
      final messageTypes = [
        XdrMessageType.SEND_MORE,
        XdrMessageType.GET_SCP_QUORUMSET,
        XdrMessageType.TRANSACTION,
      ];

      for (var msgType in messageTypes) {
        var original = XdrDontHave(
          msgType,
          XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAA))),
        );

        XdrDataOutputStream output = XdrDataOutputStream();
        XdrDontHave.encode(output, original);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrDontHave.decode(input);

        expect(decoded.type.value, equals(msgType.value));
        expect(decoded.reqHash.uint256, equals(original.reqHash.uint256));
      }
    });

    test('XdrHello with different version strings', () {
      final versionStrings = ['v20.1.0', 'v21.2.0', 'test1234'];

      for (var versionStr in versionStrings) {
        var peerID = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
        peerID.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x11))));
        var nodeID = XdrNodeID(peerID);

        var cert = XdrAuthCert(
          XdrCurve25519Public(Uint8List.fromList(List<int>.filled(32, 0x22))),
          XdrUint64(BigInt.from(1000000)),
          XdrSignature(Uint8List.fromList(List<int>.filled(64, 0x01))),
        );

        var original = XdrHello(
          XdrUint32(20),
          XdrUint32(28),
          XdrUint32(24),
          XdrHash(Uint8List.fromList(List<int>.filled(32, 0x33))),
          versionStr,
          11625,
          nodeID,
          cert,
          XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x44))),
        );

        XdrDataOutputStream output = XdrDataOutputStream();
        XdrHello.encode(output, original);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrHello.decode(input);

        expect(decoded.versionStr, equals(versionStr));
        expect(decoded.listeningPort, equals(11625));
      }
    });

    test('XdrPrice with zero denominator edge case', () {
      var original = XdrPrice(
        XdrInt32(100),
        XdrInt32(0),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrPrice.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrPrice.decode(input);

      expect(decoded.n.int32, equals(100));
      expect(decoded.d.int32, equals(0));
    });

    test('XdrClaimAtomType unknown value throws exception', () {
      XdrDataOutputStream output = XdrDataOutputStream();
      output.writeInt(999);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);

      expect(() => XdrClaimAtomType.decode(input), throwsException);
    });

    test('XdrMessageType unknown value throws exception', () {
      XdrDataOutputStream output = XdrDataOutputStream();
      output.writeInt(999);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);

      expect(() => XdrMessageType.decode(input), throwsException);
    });
  });
}
