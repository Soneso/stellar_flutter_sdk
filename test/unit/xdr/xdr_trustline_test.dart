// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('XDR Trustline - Factory Methods & Setters', () {
    test('XdrTrustLineEntry encode/decode with forAccountId factory', () {
      var accountId = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var asset = XdrTrustlineAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var ext = XdrTrustLineEntryExt(0);

      var original = XdrTrustLineEntry(
        accountId,
        asset,
        XdrInt64(BigInt.from(10000000)),
        XdrInt64(BigInt.from(100000000)),
        XdrUint32(1),
        ext,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTrustLineEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTrustLineEntry.decode(input);

      expect(decoded.balance.int64, equals(original.balance.int64));
      expect(decoded.limit.int64, equals(original.limit.int64));
      expect(decoded.flags.uint32, equals(original.flags.uint32));
      expect(decoded.ext.discriminant, equals(0));
    });

    test('TrustLineEntryExtensionV2 getters/setters', () {
      var ext = TrustLineEntryExtensionV2Ext(0);
      var entry = TrustLineEntryExtensionV2(XdrInt32(5), ext);

      expect(entry.liquidityPoolUseCount.int32, equals(5));
      expect(entry.ext.discriminant, equals(0));

      entry.liquidityPoolUseCount = XdrInt32(15);
      expect(entry.liquidityPoolUseCount.int32, equals(15));

      var newExt = TrustLineEntryExtensionV2Ext(0);
      entry.ext = newExt;
      expect(entry.ext.discriminant, equals(0));
    });
  });

  group('XDR Offer - Error Paths & Edge Cases', () {
    test('XdrOfferEntryFlags decode throws on unknown value', () {
      XdrDataOutputStream output = XdrDataOutputStream();
      output.writeInt(999);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);

      expect(() => XdrOfferEntryFlags.decode(input), throwsException);
    });

    test('XdrOfferEntryFlags toString', () {
      expect(XdrOfferEntryFlags.PASSIVE_FLAG.toString(), contains('OfferEntryFlags'));
    });

    test('XdrManageOfferSuccessResult with multiple offersClaimed', () {
      var sellerId = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var asset = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);

      var claimAtom1 = XdrClaimOfferAtom(
        sellerId,
        XdrUint64(BigInt.from(111)),
        asset,
        XdrInt64(BigInt.from(100)),
        asset,
        XdrInt64(BigInt.from(200)),
      );

      var claimAtom2 = XdrClaimOfferAtom(
        sellerId,
        XdrUint64(BigInt.from(222)),
        asset,
        XdrInt64(BigInt.from(300)),
        asset,
        XdrInt64(BigInt.from(400)),
      );

      var offer = XdrManageOfferSuccessResultOffer(
        XdrManageOfferEffect.MANAGE_OFFER_DELETED,
      );

      var offersClaimed = [
        XdrClaimAtom(XdrClaimAtomType.CLAIM_ATOM_TYPE_ORDER_BOOK),
        XdrClaimAtom(XdrClaimAtomType.CLAIM_ATOM_TYPE_ORDER_BOOK),
      ];
      offersClaimed[0].orderBook = claimAtom1;
      offersClaimed[1].orderBook = claimAtom2;

      var original = XdrManageOfferSuccessResult(offersClaimed, offer);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrManageOfferSuccessResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrManageOfferSuccessResult.decode(input);

      expect(decoded.offersClaimed.length, equals(2));
      expect(decoded.offersClaimed[0].orderBook!.offerID.uint64, equals(BigInt.from(111)));
      expect(decoded.offersClaimed[1].orderBook!.offerID.uint64, equals(BigInt.from(222)));
    });
  });

  group('XDR Payment - Complex Constructions', () {
    test('XdrPathPaymentResultSuccess with multiple offers', () {
      var sellerId = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var asset = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);

      var claimAtom = XdrClaimOfferAtom(
        sellerId,
        XdrUint64(BigInt.from(9999)),
        asset,
        XdrInt64(BigInt.from(500)),
        asset,
        XdrInt64(BigInt.from(600)),
      );

      var offers = [
        XdrClaimAtom(XdrClaimAtomType.CLAIM_ATOM_TYPE_ORDER_BOOK),
        XdrClaimAtom(XdrClaimAtomType.CLAIM_ATOM_TYPE_ORDER_BOOK),
        XdrClaimAtom(XdrClaimAtomType.CLAIM_ATOM_TYPE_ORDER_BOOK),
      ];
      offers[0].orderBook = claimAtom;
      offers[1].orderBook = claimAtom;
      offers[2].orderBook = claimAtom;

      var destination = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      destination.ed25519 = sellerId.accountID.getEd25519();

      var last = XdrSimplePaymentResult(
        destination,
        asset,
        XdrInt64(BigInt.from(7777777)),
      );

      var original = XdrPathPaymentResultSuccess(offers, last);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrPathPaymentResultSuccess.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrPathPaymentResultSuccess.decode(input);

      expect(decoded.offers.length, equals(3));
      expect(decoded.last.amount.int64, equals(BigInt.from(7777777)));
    });
  });

  group('XDR Data IO - Edge Cases', () {
    test('XdrDataOutputStream writeString with long string', () {
      var output = XdrDataOutputStream();
      var longString = 'A' * 100;

      output.writeString(longString);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = input.readString();

      expect(decoded, equals(longString));
      expect(decoded.length, equals(100));
    });

    test('XdrDataOutputStream writeIntArray', () {
      var output = XdrDataOutputStream();
      var array = [1, 2, 3, 4, 5, 10, 20, 30];

      output.writeIntArray(array);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = input.readIntArray();

      expect(decoded.length, equals(8));
      expect(decoded[0], equals(1));
      expect(decoded[4], equals(5));
      expect(decoded[7], equals(30));
    });

    test('XdrDataOutputStream writeFloatArray', () {
      var output = XdrDataOutputStream();
      var array = [1.5, 2.5, 3.5];

      output.writeFloatArray(array);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = input.readFloatArray();

      expect(decoded.length, equals(3));
      expect(decoded[0]!, closeTo(1.5, 0.01));
      expect(decoded[1]!, closeTo(2.5, 0.01));
      expect(decoded[2]!, closeTo(3.5, 0.01));
    });

    test('XdrDataOutputStream writeDoubleArray', () {
      var output = XdrDataOutputStream();
      var array = [1.23456789, 9.87654321, 5.555555555];

      output.writeDoubleArray(array);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = input.readDoubleArray();

      expect(decoded.length, equals(3));
      expect(decoded[0]!, closeTo(1.23456789, 0.0000001));
      expect(decoded[1]!, closeTo(9.87654321, 0.0000001));
      expect(decoded[2]!, closeTo(5.555555555, 0.0000001));
    });

    test('XdrDataInputStream readIntArray with empty array', () {
      var output = XdrDataOutputStream();
      output.writeIntArray([]);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = input.readIntArray();

      expect(decoded, isEmpty);
    });

    test('XdrDataInputStream readFloatArray with empty array', () {
      var output = XdrDataOutputStream();
      output.writeFloatArray([]);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = input.readFloatArray();

      expect(decoded, isEmpty);
    });

    test('XdrDataInputStream readDoubleArray with empty array', () {
      var output = XdrDataOutputStream();
      output.writeDoubleArray([]);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = input.readDoubleArray();

      expect(decoded, isEmpty);
    });

    test('DataOutput writeBigInt64 with max value', () {
      var output = XdrDataOutputStream();
      var largeValue = BigInt.parse('9223372036854775807');

      output.writeBigInt64(largeValue);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = input.readBigInt64();

      expect(decoded, equals(largeValue));
    });

    test('DataOutput writeBigInt64 with negative value', () {
      var output = XdrDataOutputStream();
      var negativeValue = BigInt.parse('-100000000000');

      output.writeBigInt64(negativeValue);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = input.readBigInt64Signed();

      expect(decoded, equals(negativeValue));
    });
  });
}
