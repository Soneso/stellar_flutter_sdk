// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('XDR Offer Types - Deep Branch Testing', () {
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

      var successResultOffer = XdrManageOfferSuccessResultOffer(XdrManageOfferEffect.MANAGE_OFFER_CREATED);
      successResultOffer.offer = offerEntry;

      var successResult = XdrManageOfferSuccessResult([], successResultOffer);

      var original = XdrManageOfferResult(
        XdrManageOfferResultCode.MANAGE_SELL_OFFER_SUCCESS,
      );
      original.success = successResult;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrManageOfferResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrManageOfferResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrManageOfferResultCode.MANAGE_SELL_OFFER_SUCCESS.value));
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

      var successResultOffer = XdrManageOfferSuccessResultOffer(XdrManageOfferEffect.MANAGE_OFFER_UPDATED);
      successResultOffer.offer = offerEntry;

      var successResult = XdrManageOfferSuccessResult([], successResultOffer);

      var original = XdrManageOfferResult(
        XdrManageOfferResultCode.MANAGE_SELL_OFFER_SUCCESS,
      );
      original.success = successResult;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrManageOfferResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrManageOfferResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrManageOfferResultCode.MANAGE_SELL_OFFER_SUCCESS.value));
      expect(decoded.success, isNotNull);
      expect(decoded.success!.offer.discriminant.value, equals(XdrManageOfferEffect.MANAGE_OFFER_UPDATED.value));
      expect(decoded.success!.offer.offer, isNotNull);
      expect(decoded.success!.offer.offer!.offerID.uint64, equals(BigInt.from(99999)));
    });

    test('XdrManageOfferResult MANAGE_OFFER_SUCCESS with DELETED encode/decode', () {
      var successResultOffer = XdrManageOfferSuccessResultOffer(XdrManageOfferEffect.MANAGE_OFFER_DELETED);

      var successResult = XdrManageOfferSuccessResult([], successResultOffer);

      var original = XdrManageOfferResult(
        XdrManageOfferResultCode.MANAGE_SELL_OFFER_SUCCESS,
      );
      original.success = successResult;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrManageOfferResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrManageOfferResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrManageOfferResultCode.MANAGE_SELL_OFFER_SUCCESS.value));
      expect(decoded.success, isNotNull);
      expect(decoded.success!.offer.discriminant.value, equals(XdrManageOfferEffect.MANAGE_OFFER_DELETED.value));
      expect(decoded.success!.offer.offer, isNull);
    });
  });
}
