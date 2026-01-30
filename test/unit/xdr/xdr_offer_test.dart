// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('XDR Offer Types - Deep Branch Testing', () {
    test('XdrManageOfferResultCode enum all variants', () {
      final codes = [
        XdrManageOfferResultCode.MANAGE_OFFER_SUCCESS,
        XdrManageOfferResultCode.MANAGE_OFFER_MALFORMED,
        XdrManageOfferResultCode.MANAGE_OFFER_SELL_NO_TRUST,
        XdrManageOfferResultCode.MANAGE_OFFER_BUY_NO_TRUST,
        XdrManageOfferResultCode.MANAGE_OFFER_SELL_NOT_AUTHORIZED,
        XdrManageOfferResultCode.MANAGE_OFFER_BUY_NOT_AUTHORIZED,
        XdrManageOfferResultCode.MANAGE_OFFER_LINE_FULL,
        XdrManageOfferResultCode.MANAGE_OFFER_UNDERFUNDED,
        XdrManageOfferResultCode.MANAGE_OFFER_CROSS_SELF,
        XdrManageOfferResultCode.MANAGE_OFFER_SELL_NO_ISSUER,
        XdrManageOfferResultCode.MANAGE_OFFER_BUY_NO_ISSUER,
        XdrManageOfferResultCode.MANAGE_OFFER_NOT_FOUND,
        XdrManageOfferResultCode.MANAGE_OFFER_LOW_RESERVE,
      ];

      for (var code in codes) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrManageOfferResultCode.encode(output, code);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrManageOfferResultCode.decode(input);

        expect(decoded.value, equals(code.value));
      }
    });

    test('XdrManageOfferEffect enum all variants', () {
      final effects = [
        XdrManageOfferEffect.MANAGE_OFFER_CREATED,
        XdrManageOfferEffect.MANAGE_OFFER_UPDATED,
        XdrManageOfferEffect.MANAGE_OFFER_DELETED,
      ];

      for (var effect in effects) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrManageOfferEffect.encode(output, effect);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrManageOfferEffect.decode(input);

        expect(decoded.value, equals(effect.value));
      }
    });

    test('XdrManageOfferResult MANAGE_OFFER_SUCCESS with CREATED encode/decode', () {
      var sellerId = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var selling = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var buying = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var price = XdrPrice(XdrInt32(1), XdrInt32(2));
      var ext = XdrOfferEntryExt(0);

      var offerEntry = XdrOfferEntry(
        sellerId,
        XdrUint64(BigInt.from(12345)),
        selling,
        buying,
        XdrInt64(BigInt.from(1000000)),
        price,
        XdrUint32(0),
        ext,
      );

      var successResultOffer = XdrManageOfferSuccessResultOffer(
        XdrManageOfferEffect.MANAGE_OFFER_CREATED,
        offerEntry,
      );

      var successResult = XdrManageOfferSuccessResult([], successResultOffer);

      var original = XdrManageOfferResult(
        XdrManageOfferResultCode.MANAGE_OFFER_SUCCESS,
        successResult,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrManageOfferResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrManageOfferResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrManageOfferResultCode.MANAGE_OFFER_SUCCESS.value));
      expect(decoded.success, isNotNull);
      expect(decoded.success!.offer.discriminant.value, equals(XdrManageOfferEffect.MANAGE_OFFER_CREATED.value));
      expect(decoded.success!.offer.offer, isNotNull);
      expect(decoded.success!.offer.offer!.offerID.uint64, equals(BigInt.from(12345)));
    });

    test('XdrManageOfferResult MANAGE_OFFER_SUCCESS with UPDATED encode/decode', () {
      var sellerId = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var selling = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var buying = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var price = XdrPrice(XdrInt32(3), XdrInt32(4));
      var ext = XdrOfferEntryExt(0);

      var offerEntry = XdrOfferEntry(
        sellerId,
        XdrUint64(BigInt.from(99999)),
        selling,
        buying,
        XdrInt64(BigInt.from(2000000)),
        price,
        XdrUint32(0),
        ext,
      );

      var successResultOffer = XdrManageOfferSuccessResultOffer(
        XdrManageOfferEffect.MANAGE_OFFER_UPDATED,
        offerEntry,
      );

      var successResult = XdrManageOfferSuccessResult([], successResultOffer);

      var original = XdrManageOfferResult(
        XdrManageOfferResultCode.MANAGE_OFFER_SUCCESS,
        successResult,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrManageOfferResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrManageOfferResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrManageOfferResultCode.MANAGE_OFFER_SUCCESS.value));
      expect(decoded.success, isNotNull);
      expect(decoded.success!.offer.discriminant.value, equals(XdrManageOfferEffect.MANAGE_OFFER_UPDATED.value));
      expect(decoded.success!.offer.offer, isNotNull);
      expect(decoded.success!.offer.offer!.offerID.uint64, equals(BigInt.from(99999)));
    });

    test('XdrManageOfferResult MANAGE_OFFER_SUCCESS with DELETED encode/decode', () {
      var successResultOffer = XdrManageOfferSuccessResultOffer(
        XdrManageOfferEffect.MANAGE_OFFER_DELETED,
        null,
      );

      var successResult = XdrManageOfferSuccessResult([], successResultOffer);

      var original = XdrManageOfferResult(
        XdrManageOfferResultCode.MANAGE_OFFER_SUCCESS,
        successResult,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrManageOfferResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrManageOfferResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrManageOfferResultCode.MANAGE_OFFER_SUCCESS.value));
      expect(decoded.success, isNotNull);
      expect(decoded.success!.offer.discriminant.value, equals(XdrManageOfferEffect.MANAGE_OFFER_DELETED.value));
      expect(decoded.success!.offer.offer, isNull);
    });

    test('XdrManageOfferResult MANAGE_OFFER_MALFORMED encode/decode', () {
      var original = XdrManageOfferResult(
        XdrManageOfferResultCode.MANAGE_OFFER_MALFORMED,
        null,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrManageOfferResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrManageOfferResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrManageOfferResultCode.MANAGE_OFFER_MALFORMED.value));
      expect(decoded.success, isNull);
    });

    test('XdrManageOfferResult MANAGE_OFFER_SELL_NO_TRUST encode/decode', () {
      var original = XdrManageOfferResult(
        XdrManageOfferResultCode.MANAGE_OFFER_SELL_NO_TRUST,
        null,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrManageOfferResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrManageOfferResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrManageOfferResultCode.MANAGE_OFFER_SELL_NO_TRUST.value));
    });

    test('XdrManageOfferResult MANAGE_OFFER_BUY_NO_TRUST encode/decode', () {
      var original = XdrManageOfferResult(
        XdrManageOfferResultCode.MANAGE_OFFER_BUY_NO_TRUST,
        null,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrManageOfferResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrManageOfferResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrManageOfferResultCode.MANAGE_OFFER_BUY_NO_TRUST.value));
    });

    test('XdrManageOfferResult MANAGE_OFFER_UNDERFUNDED encode/decode', () {
      var original = XdrManageOfferResult(
        XdrManageOfferResultCode.MANAGE_OFFER_UNDERFUNDED,
        null,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrManageOfferResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrManageOfferResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrManageOfferResultCode.MANAGE_OFFER_UNDERFUNDED.value));
    });

    test('XdrManageOfferResult MANAGE_OFFER_LOW_RESERVE encode/decode', () {
      var original = XdrManageOfferResult(
        XdrManageOfferResultCode.MANAGE_OFFER_LOW_RESERVE,
        null,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrManageOfferResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrManageOfferResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrManageOfferResultCode.MANAGE_OFFER_LOW_RESERVE.value));
    });

    test('XdrOfferEntry encode/decode round-trip', () {
      var sellerId = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var selling = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var buying = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var price = XdrPrice(XdrInt32(5), XdrInt32(6));
      var ext = XdrOfferEntryExt(0);

      var original = XdrOfferEntry(
        sellerId,
        XdrUint64(BigInt.from(777777)),
        selling,
        buying,
        XdrInt64(BigInt.from(5000000)),
        price,
        XdrUint32(1),
        ext,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOfferEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOfferEntry.decode(input);

      expect(decoded.offerID.uint64, equals(original.offerID.uint64));
      expect(decoded.amount.int64, equals(original.amount.int64));
      expect(decoded.price.n.int32, equals(original.price.n.int32));
      expect(decoded.price.d.int32, equals(original.price.d.int32));
      expect(decoded.flags.uint32, equals(original.flags.uint32));
      expect(decoded.ext.discriminant, equals(0));
    });

    test('XdrOfferEntryExt discriminant 0 encode/decode', () {
      var original = XdrOfferEntryExt(0);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOfferEntryExt.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOfferEntryExt.decode(input);

      expect(decoded.discriminant, equals(0));
    });

    test('XdrManageSellOfferOp encode/decode round-trip', () {
      var selling = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var buying = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var price = XdrPrice(XdrInt32(10), XdrInt32(20));

      var original = XdrManageSellOfferOp(
        selling,
        buying,
        XdrBigInt64(BigInt.from(3000000)),
        price,
        XdrUint64(BigInt.from(12345)),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrManageSellOfferOp.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrManageSellOfferOp.decode(input);

      expect(decoded.amount.bigInt, equals(original.amount.bigInt));
      expect(decoded.offerID.uint64, equals(original.offerID.uint64));
      expect(decoded.price.n.int32, equals(original.price.n.int32));
    });

    test('XdrManageBuyOfferOp encode/decode round-trip', () {
      var selling = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var buying = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var price = XdrPrice(XdrInt32(7), XdrInt32(8));

      var original = XdrManageBuyOfferOp(
        selling,
        buying,
        XdrBigInt64(BigInt.from(4000000)),
        price,
        XdrUint64(BigInt.from(54321)),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrManageBuyOfferOp.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrManageBuyOfferOp.decode(input);

      expect(decoded.amount.bigInt, equals(original.amount.bigInt));
      expect(decoded.offerID.uint64, equals(original.offerID.uint64));
      expect(decoded.price.n.int32, equals(original.price.n.int32));
    });

    test('XdrCreatePassiveSellOfferOp encode/decode round-trip', () {
      var selling = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var buying = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var price = XdrPrice(XdrInt32(15), XdrInt32(30));

      var original = XdrCreatePassiveSellOfferOp(
        selling,
        buying,
        XdrBigInt64(BigInt.from(6000000)),
        price,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrCreatePassiveSellOfferOp.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrCreatePassiveSellOfferOp.decode(input);

      expect(decoded.amount.bigInt, equals(original.amount.bigInt));
      expect(decoded.price.n.int32, equals(original.price.n.int32));
      expect(decoded.price.d.int32, equals(original.price.d.int32));
    });
  });
}
