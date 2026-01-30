// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('XDR Other Types - Deep Branch Testing', () {
    test('XdrClaimAtomType enum all variants', () {
      final types = [
        XdrClaimAtomType.CLAIM_ATOM_TYPE_V0,
        XdrClaimAtomType.CLAIM_ATOM_TYPE_ORDER_BOOK,
        XdrClaimAtomType.CLAIM_ATOM_TYPE_LIQUIDITY_POOL,
      ];

      for (var type in types) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrClaimAtomType.encode(output, type);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrClaimAtomType.decode(input);

        expect(decoded.value, equals(type.value));
      }
    });

    test('XdrClaimAtom CLAIM_ATOM_TYPE_V0 encode/decode', () {
      var v0 = XdrClaimOfferAtomV0(
        XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x11))),
        XdrUint64(BigInt.from(123)),
        XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE),
        XdrInt64(BigInt.from(1000000)),
        XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE),
        XdrInt64(BigInt.from(2000000)),
      );

      var original = XdrClaimAtom(XdrClaimAtomType.CLAIM_ATOM_TYPE_V0);
      original.v0 = v0;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrClaimAtom.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrClaimAtom.decode(input);

      expect(decoded.discriminant.value, equals(XdrClaimAtomType.CLAIM_ATOM_TYPE_V0.value));
      expect(decoded.v0, isNotNull);
      expect(decoded.v0!.offerID.uint64, equals(v0.offerID.uint64));
      expect(decoded.v0!.amountSold.int64, equals(v0.amountSold.int64));
      expect(decoded.v0!.amountBought.int64, equals(v0.amountBought.int64));
    });

    test('XdrClaimAtom CLAIM_ATOM_TYPE_ORDER_BOOK encode/decode', () {
      var accountId = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');

      var orderBook = XdrClaimOfferAtom(
        accountId,
        XdrUint64(BigInt.from(456)),
        XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE),
        XdrInt64(BigInt.from(3000000)),
        XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE),
        XdrInt64(BigInt.from(4000000)),
      );

      var original = XdrClaimAtom(XdrClaimAtomType.CLAIM_ATOM_TYPE_ORDER_BOOK);
      original.orderBook = orderBook;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrClaimAtom.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrClaimAtom.decode(input);

      expect(decoded.discriminant.value, equals(XdrClaimAtomType.CLAIM_ATOM_TYPE_ORDER_BOOK.value));
      expect(decoded.orderBook, isNotNull);
      expect(decoded.orderBook!.offerID.uint64, equals(orderBook.offerID.uint64));
      expect(decoded.orderBook!.amountSold.int64, equals(orderBook.amountSold.int64));
    });

    test('XdrClaimAtom CLAIM_ATOM_TYPE_LIQUIDITY_POOL encode/decode', () {
      var liquidityPool = XdrClaimLiquidityAtom(
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0xAA))),
        XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE),
        XdrInt64(BigInt.from(5000000)),
        XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE),
        XdrInt64(BigInt.from(6000000)),
      );

      var original = XdrClaimAtom(XdrClaimAtomType.CLAIM_ATOM_TYPE_LIQUIDITY_POOL);
      original.liquidityPool = liquidityPool;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrClaimAtom.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrClaimAtom.decode(input);

      expect(decoded.discriminant.value, equals(XdrClaimAtomType.CLAIM_ATOM_TYPE_LIQUIDITY_POOL.value));
      expect(decoded.liquidityPool, isNotNull);
      expect(decoded.liquidityPool!.liquidityPoolID.hash, equals(liquidityPool.liquidityPoolID.hash));
      expect(decoded.liquidityPool!.amountSold.int64, equals(liquidityPool.amountSold.int64));
    });

    test('XdrClaimOfferAtomV0 encode/decode round-trip', () {
      var original = XdrClaimOfferAtomV0(
        XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x22))),
        XdrUint64(BigInt.from(789)),
        XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE),
        XdrInt64(BigInt.from(100)),
        XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE),
        XdrInt64(BigInt.from(200)),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrClaimOfferAtomV0.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrClaimOfferAtomV0.decode(input);

      expect(decoded.sellerEd25519.uint256, equals(original.sellerEd25519.uint256));
      expect(decoded.offerID.uint64, equals(original.offerID.uint64));
      expect(decoded.amountSold.int64, equals(original.amountSold.int64));
      expect(decoded.amountBought.int64, equals(original.amountBought.int64));
    });

    test('XdrClaimOfferAtom encode/decode round-trip', () {
      var accountId = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');

      var original = XdrClaimOfferAtom(
        accountId,
        XdrUint64(BigInt.from(999)),
        XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE),
        XdrInt64(BigInt.from(300)),
        XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE),
        XdrInt64(BigInt.from(400)),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrClaimOfferAtom.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrClaimOfferAtom.decode(input);

      expect(decoded.offerID.uint64, equals(original.offerID.uint64));
      expect(decoded.amountSold.int64, equals(original.amountSold.int64));
      expect(decoded.amountBought.int64, equals(original.amountBought.int64));
    });

    test('XdrClaimLiquidityAtom encode/decode round-trip', () {
      var original = XdrClaimLiquidityAtom(
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0xBB))),
        XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE),
        XdrInt64(BigInt.from(500)),
        XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE),
        XdrInt64(BigInt.from(600)),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrClaimLiquidityAtom.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrClaimLiquidityAtom.decode(input);

      expect(decoded.liquidityPoolID.hash, equals(original.liquidityPoolID.hash));
      expect(decoded.amountSold.int64, equals(original.amountSold.int64));
      expect(decoded.amountBought.int64, equals(original.amountBought.int64));
    });

    test('XdrDontHave encode/decode round-trip', () {
      var original = XdrDontHave(
        XdrMessageType.GET_TX_SET,
        XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xCC))),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrDontHave.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrDontHave.decode(input);

      expect(decoded.type.value, equals(original.type.value));
      expect(decoded.reqHash.uint256, equals(original.reqHash.uint256));
    });

    test('XdrHello encode/decode round-trip', () {
      var peerID = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      peerID.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xDD))));
      var nodeID = XdrNodeID(peerID);

      var cert = XdrAuthCert(
        XdrCurve25519Public(Uint8List.fromList(List<int>.filled(32, 0xEE))),
        XdrUint64(BigInt.from(1000000)),
        XdrSignature(Uint8List.fromList(List<int>.filled(64, 0x01))),
      );

      var original = XdrHello(
        XdrUint32(21),
        XdrUint32(30),
        XdrUint32(25),
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0xFF))),
        'v21.0.0',
        11625,
        nodeID,
        cert,
        XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x00))),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrHello.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrHello.decode(input);

      expect(decoded.ledgerVersion.uint32, equals(original.ledgerVersion.uint32));
      expect(decoded.overlayVersion.uint32, equals(original.overlayVersion.uint32));
      expect(decoded.overlayMinVersion.uint32, equals(original.overlayMinVersion.uint32));
      expect(decoded.networkID.hash, equals(original.networkID.hash));
      expect(decoded.versionStr, equals(original.versionStr));
      expect(decoded.listeningPort, equals(original.listeningPort));
      expect(decoded.nonce.uint256, equals(original.nonce.uint256));
    });

    test('XdrLiabilities encode/decode round-trip', () {
      var original = XdrLiabilities(
        XdrInt64(BigInt.from(1000000)),
        XdrInt64(BigInt.from(2000000)),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLiabilities.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLiabilities.decode(input);

      expect(decoded.buying.int64, equals(original.buying.int64));
      expect(decoded.selling.int64, equals(original.selling.int64));
    });

    test('XdrPrice encode/decode round-trip', () {
      var original = XdrPrice(
        XdrInt32(1),
        XdrInt32(2),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrPrice.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrPrice.decode(input);

      expect(decoded.n.int32, equals(original.n.int32));
      expect(decoded.d.int32, equals(original.d.int32));
    });

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

    test('XdrMessageType enum all variants', () {
      final types = [
        XdrMessageType.ERROR_MSG,
        XdrMessageType.AUTH,
        XdrMessageType.DONT_HAVE,
        XdrMessageType.GET_PEERS,
        XdrMessageType.PEERS,
        XdrMessageType.GET_TX_SET,
        XdrMessageType.TX_SET,
        XdrMessageType.TRANSACTION,
        XdrMessageType.GET_SCP_QUORUMSET,
        XdrMessageType.SCP_QUORUMSET,
        XdrMessageType.SCP_MESSAGE,
        XdrMessageType.GET_SCP_STATE,
        XdrMessageType.HELLO,
        XdrMessageType.SURVEY_REQUEST,
        XdrMessageType.SURVEY_RESPONSE,
      ];

      for (var type in types) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrMessageType.encode(output, type);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrMessageType.decode(input);

        expect(decoded.value, equals(type.value));
      }
    });

    test('XdrStellarMessage ERROR_MSG discriminant encode/decode', () {
      var error = XdrError(XdrErrorCode.ERR_MISC, 'Test error');

      var original = XdrStellarMessage(XdrMessageType.ERROR_MSG);
      original.error = error;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrStellarMessage.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrStellarMessage.decode(input);

      expect(decoded.discriminant.value, equals(XdrMessageType.ERROR_MSG.value));
      expect(decoded.error, isNotNull);
      expect(decoded.error!.msg, equals('Test error'));
    });

    test('XdrStellarMessage HELLO discriminant encode/decode', () {
      var peerID = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      peerID.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x11))));
      var nodeID = XdrNodeID(peerID);

      var cert = XdrAuthCert(
        XdrCurve25519Public(Uint8List.fromList(List<int>.filled(32, 0x22))),
        XdrUint64(BigInt.from(2000000)),
        XdrSignature(Uint8List.fromList(List<int>.filled(64, 0x02))),
      );

      var hello = XdrHello(
        XdrUint32(21),
        XdrUint32(30),
        XdrUint32(25),
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0x33))),
        'v21.0.0',
        11625,
        nodeID,
        cert,
        XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x44))),
      );

      var original = XdrStellarMessage(XdrMessageType.HELLO);
      original.hello = hello;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrStellarMessage.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrStellarMessage.decode(input);

      expect(decoded.discriminant.value, equals(XdrMessageType.HELLO.value));
      expect(decoded.hello, isNotNull);
      expect(decoded.hello!.versionStr, equals('v21.0.0'));
    });

    test('XdrStellarMessage AUTH discriminant encode/decode', () {
      var auth = XdrAuth(0);

      var original = XdrStellarMessage(XdrMessageType.AUTH);
      original.auth = auth;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrStellarMessage.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrStellarMessage.decode(input);

      expect(decoded.discriminant.value, equals(XdrMessageType.AUTH.value));
      expect(decoded.auth, isNotNull);
    });

    test('XdrStellarMessage DONT_HAVE discriminant encode/decode', () {
      var dontHave = XdrDontHave(
        XdrMessageType.GET_TX_SET,
        XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x55))),
      );

      var original = XdrStellarMessage(XdrMessageType.DONT_HAVE);
      original.dontHave = dontHave;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrStellarMessage.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrStellarMessage.decode(input);

      expect(decoded.discriminant.value, equals(XdrMessageType.DONT_HAVE.value));
      expect(decoded.dontHave, isNotNull);
      expect(decoded.dontHave!.type.value, equals(XdrMessageType.GET_TX_SET.value));
    });

    test('XdrStellarMessage GET_PEERS discriminant encode/decode', () {
      var original = XdrStellarMessage(XdrMessageType.GET_PEERS);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrStellarMessage.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrStellarMessage.decode(input);

      expect(decoded.discriminant.value, equals(XdrMessageType.GET_PEERS.value));
    });

    test('XdrStellarMessage GET_TX_SET discriminant encode/decode', () {
      var original = XdrStellarMessage(XdrMessageType.GET_TX_SET);
      original.txSetHash = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x66)));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrStellarMessage.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrStellarMessage.decode(input);

      expect(decoded.discriminant.value, equals(XdrMessageType.GET_TX_SET.value));
      expect(decoded.txSetHash, isNotNull);
      expect(decoded.txSetHash!.uint256, equals(original.txSetHash!.uint256));
    });

    test('XdrStellarMessage GET_SCP_QUORUMSET discriminant encode/decode', () {
      var original = XdrStellarMessage(XdrMessageType.GET_SCP_QUORUMSET);
      original.qSetHash = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x77)));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrStellarMessage.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrStellarMessage.decode(input);

      expect(decoded.discriminant.value, equals(XdrMessageType.GET_SCP_QUORUMSET.value));
      expect(decoded.qSetHash, isNotNull);
      expect(decoded.qSetHash!.uint256, equals(original.qSetHash!.uint256));
    });

    test('XdrStellarMessage GET_SCP_STATE discriminant encode/decode', () {
      var original = XdrStellarMessage(XdrMessageType.GET_SCP_STATE);
      original.getSCPLedgerSeq = XdrUint32(12345);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrStellarMessage.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrStellarMessage.decode(input);

      expect(decoded.discriminant.value, equals(XdrMessageType.GET_SCP_STATE.value));
      expect(decoded.getSCPLedgerSeq, isNotNull);
      expect(decoded.getSCPLedgerSeq!.uint32, equals(12345));
    });

    test('XdrStellarValue encode/decode round-trip with empty upgrades', () {
      var ext = XdrStellarValueExt(0);

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
      expect(decoded.ext.discriminant, equals(0));
    });

    test('XdrStellarValue encode/decode round-trip with upgrades', () {
      var ext = XdrStellarValueExt(0);

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
      expect(decoded.ext.discriminant, equals(0));
    });

    test('XdrStellarValue encode/decode with multiple upgrades', () {
      var ext = XdrStellarValueExt(0);

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
      expect(decoded.ext.discriminant, equals(0));
    });

    test('XdrStellarValueExt encode/decode with discriminant 0', () {
      var original = XdrStellarValueExt(0);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrStellarValueExt.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrStellarValueExt.decode(input);

      expect(decoded.discriminant, equals(0));
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
        XdrMessageType.GET_PEERS,
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
