// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('XDR Trustline Types - Deep Branch Testing', () {
    test('XdrTrustLineFlags enum all variants', () {
      final flags = [
        XdrTrustLineFlags.AUTHORIZED_FLAG,
        XdrTrustLineFlags.AUTHORIZED_TO_MAINTAIN_LIABILITIES_FLAG,
        XdrTrustLineFlags.TRUSTLINE_CLAWBACK_ENABLED_FLAG,
      ];

      for (var flag in flags) {
        XdrDataOutputStream output = XdrDataOutputStream();
        output.writeInt(flag.value);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrTrustLineFlags.decode(input);

        expect(decoded.value, equals(flag.value));
      }
    });

    test('XdrTrustLineEntryExt discriminant 0 encode/decode', () {
      var original = XdrTrustLineEntryExt(0);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTrustLineEntryExt.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTrustLineEntryExt.decode(input);

      expect(decoded.discriminant, equals(0));
      expect(decoded.v1, isNull);
    });

    test('XdrTrustLineEntryExt discriminant 1 encode/decode', () {
      var liabilities = XdrLiabilities(
        XdrInt64(BigInt.from(1000000)),
        XdrInt64(BigInt.from(2000000)),
      );
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
      expect(decoded.v1!.liabilities.buying.int64, equals(BigInt.from(1000000)));
      expect(decoded.v1!.liabilities.selling.int64, equals(BigInt.from(2000000)));
    });

    test('XdrTrustLineEntryV1Ext discriminant 0 encode/decode', () {
      var original = XdrTrustLineEntryV1Ext(0);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTrustLineEntryV1Ext.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTrustLineEntryV1Ext.decode(input);

      expect(decoded.discriminant, equals(0));
      expect(decoded.ext, isNull);
    });

    test('XdrTrustLineEntryV1Ext discriminant 2 encode/decode', () {
      var v2Ext = TrustLineEntryExtensionV2Ext(0);
      var v2 = TrustLineEntryExtensionV2(XdrInt32(5), v2Ext);

      var original = XdrTrustLineEntryV1Ext(2);
      original.ext = v2;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTrustLineEntryV1Ext.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTrustLineEntryV1Ext.decode(input);

      expect(decoded.discriminant, equals(2));
      expect(decoded.ext, isNotNull);
      expect(decoded.ext!.liquidityPoolUseCount.int32, equals(5));
    });

    test('XdrChangeTrustResultCode enum all variants', () {
      final codes = [
        XdrChangeTrustResultCode.CHANGE_TRUST_SUCCESS,
        XdrChangeTrustResultCode.CHANGE_TRUST_MALFORMED,
        XdrChangeTrustResultCode.CHANGE_TRUST_NO_ISSUER,
        XdrChangeTrustResultCode.CHANGE_TRUST_INVALID_LIMIT,
        XdrChangeTrustResultCode.CHANGE_TRUST_LOW_RESERVE,
        XdrChangeTrustResultCode.CHANGE_TRUST_SELF_NOT_ALLOWED,
        XdrChangeTrustResultCode.CHANGE_TRUST_TRUST_LINE_MISSING,
        XdrChangeTrustResultCode.CHANGE_TRUST_CANNOT_DELETE,
        XdrChangeTrustResultCode.CHANGE_TRUST_NOT_AUTH_MAINTAIN_LIABILITIES,
      ];

      for (var code in codes) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrChangeTrustResultCode.encode(output, code);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrChangeTrustResultCode.decode(input);

        expect(decoded.value, equals(code.value));
      }
    });

    test('XdrChangeTrustResult CHANGE_TRUST_SUCCESS encode/decode', () {
      var original = XdrChangeTrustResult(XdrChangeTrustResultCode.CHANGE_TRUST_SUCCESS);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrChangeTrustResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrChangeTrustResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrChangeTrustResultCode.CHANGE_TRUST_SUCCESS.value));
    });

    test('XdrChangeTrustResult CHANGE_TRUST_MALFORMED encode/decode', () {
      var original = XdrChangeTrustResult(XdrChangeTrustResultCode.CHANGE_TRUST_MALFORMED);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrChangeTrustResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrChangeTrustResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrChangeTrustResultCode.CHANGE_TRUST_MALFORMED.value));
    });

    test('XdrChangeTrustResult CHANGE_TRUST_NO_ISSUER encode/decode', () {
      var original = XdrChangeTrustResult(XdrChangeTrustResultCode.CHANGE_TRUST_NO_ISSUER);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrChangeTrustResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrChangeTrustResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrChangeTrustResultCode.CHANGE_TRUST_NO_ISSUER.value));
    });

    test('XdrAllowTrustResultCode enum all variants', () {
      final codes = [
        XdrAllowTrustResultCode.ALLOW_TRUST_SUCCESS,
        XdrAllowTrustResultCode.ALLOW_TRUST_MALFORMED,
        XdrAllowTrustResultCode.ALLOW_TRUST_NO_TRUST_LINE,
        XdrAllowTrustResultCode.ALLOW_TRUST_TRUST_NOT_REQUIRED,
        XdrAllowTrustResultCode.ALLOW_TRUST_CANT_REVOKE,
        XdrAllowTrustResultCode.ALLOW_TRUST_SELF_NOT_ALLOWED,
        XdrAllowTrustResultCode.ALLOW_TRUST_LOW_RESERVE,
      ];

      for (var code in codes) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrAllowTrustResultCode.encode(output, code);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrAllowTrustResultCode.decode(input);

        expect(decoded.value, equals(code.value));
      }
    });

    test('XdrAllowTrustResult ALLOW_TRUST_SUCCESS encode/decode', () {
      var original = XdrAllowTrustResult(XdrAllowTrustResultCode.ALLOW_TRUST_SUCCESS);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrAllowTrustResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrAllowTrustResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrAllowTrustResultCode.ALLOW_TRUST_SUCCESS.value));
    });

    test('XdrAllowTrustResult ALLOW_TRUST_MALFORMED encode/decode', () {
      var original = XdrAllowTrustResult(XdrAllowTrustResultCode.ALLOW_TRUST_MALFORMED);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrAllowTrustResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrAllowTrustResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrAllowTrustResultCode.ALLOW_TRUST_MALFORMED.value));
    });

    test('XdrSetTrustLineFlagsResultCode enum all variants', () {
      final codes = [
        XdrSetTrustLineFlagsResultCode.SET_TRUST_LINE_FLAGS_SUCCESS,
        XdrSetTrustLineFlagsResultCode.SET_TRUST_LINE_FLAGS_MALFORMED,
        XdrSetTrustLineFlagsResultCode.SET_TRUST_LINE_FLAGS_NO_TRUST_LINE,
        XdrSetTrustLineFlagsResultCode.SET_TRUST_LINE_FLAGS_CANT_REVOKE,
        XdrSetTrustLineFlagsResultCode.SET_TRUST_LINE_FLAGS_INVALID_STATE,
        XdrSetTrustLineFlagsResultCode.SET_TRUST_LINE_FLAGS_LOW_RESERVE,
      ];

      for (var code in codes) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrSetTrustLineFlagsResultCode.encode(output, code);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrSetTrustLineFlagsResultCode.decode(input);

        expect(decoded.value, equals(code.value));
      }
    });

    test('XdrSetTrustLineFlagsResult SET_TRUST_LINE_FLAGS_SUCCESS encode/decode', () {
      var original = XdrSetTrustLineFlagsResult(XdrSetTrustLineFlagsResultCode.SET_TRUST_LINE_FLAGS_SUCCESS);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSetTrustLineFlagsResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSetTrustLineFlagsResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrSetTrustLineFlagsResultCode.SET_TRUST_LINE_FLAGS_SUCCESS.value));
    });

    test('XdrSetTrustLineFlagsResult SET_TRUST_LINE_FLAGS_MALFORMED encode/decode', () {
      var original = XdrSetTrustLineFlagsResult(XdrSetTrustLineFlagsResultCode.SET_TRUST_LINE_FLAGS_MALFORMED);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSetTrustLineFlagsResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSetTrustLineFlagsResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrSetTrustLineFlagsResultCode.SET_TRUST_LINE_FLAGS_MALFORMED.value));
    });

    test('XdrClawbackResultCode enum all variants', () {
      final codes = [
        XdrClawbackResultCode.CLAWBACK_SUCCESS,
        XdrClawbackResultCode.CLAWBACK_MALFORMED,
        XdrClawbackResultCode.CLAWBACK_NOT_ENABLED,
        XdrClawbackResultCode.CLAWBACK_NO_TRUST,
        XdrClawbackResultCode.CLAWBACK_UNDERFUNDED,
      ];

      for (var code in codes) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrClawbackResultCode.encode(output, code);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrClawbackResultCode.decode(input);

        expect(decoded.value, equals(code.value));
      }
    });

    test('XdrClawbackResult CLAWBACK_SUCCESS encode/decode', () {
      var original = XdrClawbackResult(XdrClawbackResultCode.CLAWBACK_SUCCESS);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrClawbackResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrClawbackResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrClawbackResultCode.CLAWBACK_SUCCESS.value));
    });

    test('XdrClawbackResult CLAWBACK_MALFORMED encode/decode', () {
      var original = XdrClawbackResult(XdrClawbackResultCode.CLAWBACK_MALFORMED);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrClawbackResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrClawbackResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrClawbackResultCode.CLAWBACK_MALFORMED.value));
    });

    test('XdrClawbackResult CLAWBACK_UNDERFUNDED encode/decode', () {
      var original = XdrClawbackResult(XdrClawbackResultCode.CLAWBACK_UNDERFUNDED);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrClawbackResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrClawbackResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrClawbackResultCode.CLAWBACK_UNDERFUNDED.value));
    });

    test('XdrTrustLineEntry encode/decode round-trip', () {
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

    test('XdrAllowTrustOpAsset ASSET_TYPE_CREDIT_ALPHANUM4 encode/decode', () {
      var assetCode4 = Uint8List.fromList([65, 66, 67, 68]);
      var original = XdrAllowTrustOpAsset(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4);
      original.assetCode4 = assetCode4;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrAllowTrustOpAsset.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrAllowTrustOpAsset.decode(input);

      expect(decoded.discriminant.value, equals(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4.value));
      expect(decoded.assetCode4, isNotNull);
      expect(decoded.assetCode4!.length, equals(4));
    });

    test('XdrAllowTrustOpAsset ASSET_TYPE_CREDIT_ALPHANUM12 encode/decode', () {
      var assetCode12 = Uint8List.fromList([65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76]);
      var original = XdrAllowTrustOpAsset(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12);
      original.assetCode12 = assetCode12;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrAllowTrustOpAsset.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrAllowTrustOpAsset.decode(input);

      expect(decoded.discriminant.value, equals(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12.value));
      expect(decoded.assetCode12, isNotNull);
      expect(decoded.assetCode12!.length, equals(12));
    });
  });

  group('XDR Remaining Coverage - Trustline', () {
    test('TrustLineEntryExtensionV2Ext discriminant 0 encode/decode', () {
      var original = TrustLineEntryExtensionV2Ext(0);

      XdrDataOutputStream output = XdrDataOutputStream();
      TrustLineEntryExtensionV2Ext.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = TrustLineEntryExtensionV2Ext.decode(input);

      expect(decoded.discriminant, equals(0));
    });

    test('TrustLineEntryExtensionV2 encode/decode', () {
      var ext = TrustLineEntryExtensionV2Ext(0);
      var original = TrustLineEntryExtensionV2(XdrInt32(10), ext);

      XdrDataOutputStream output = XdrDataOutputStream();
      TrustLineEntryExtensionV2.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = TrustLineEntryExtensionV2.decode(input);

      expect(decoded.liquidityPoolUseCount.int32, equals(10));
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

    test('XdrAllowTrustOp encode/decode', () {
      var trustor = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var asset = XdrAllowTrustOpAsset(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4);
      asset.assetCode4 = Uint8List.fromList([65, 66, 67, 68]);

      var original = XdrAllowTrustOp(trustor, asset, 1);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrAllowTrustOp.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrAllowTrustOp.decode(input);

      expect(decoded.authorize, equals(1));
      expect(decoded.asset.discriminant.value, equals(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4.value));
    });

    test('XdrChangeTrustOp encode/decode', () {
      var asset = XdrChangeTrustAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var original = XdrChangeTrustOp(asset, XdrBigInt64(BigInt.from(100000000)));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrChangeTrustOp.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrChangeTrustOp.decode(input);

      expect(decoded.limit.bigInt, equals(BigInt.from(100000000)));
    });

    test('XdrClawbackOp encode/decode', () {
      var asset = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var destAccount = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var from = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      from.ed25519 = destAccount.accountID.getEd25519();

      var original = XdrClawbackOp(asset, from, XdrBigInt64(BigInt.from(5000000)));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrClawbackOp.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrClawbackOp.decode(input);

      expect(decoded.amount.bigInt, equals(BigInt.from(5000000)));
    });

    test('XdrSetTrustLineFlagsOp encode/decode', () {
      var accountId = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var asset = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);

      var original = XdrSetTrustLineFlagsOp(
        accountId,
        asset,
        XdrUint32(1),
        XdrUint32(2),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSetTrustLineFlagsOp.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSetTrustLineFlagsOp.decode(input);

      expect(decoded.clearFlags.uint32, equals(1));
      expect(decoded.setFlags.uint32, equals(2));
    });
  });

  group('XDR Remaining Coverage - Offer', () {
    test('XdrOfferEntryFlags enum PASSIVE_FLAG', () {
      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOfferEntryFlags.encode(output, XdrOfferEntryFlags.PASSIVE_FLAG);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOfferEntryFlags.decode(input);

      expect(decoded.value, equals(XdrOfferEntryFlags.PASSIVE_FLAG.value));
      expect(decoded.value, equals(1));
    });

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
        null,
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

    test('XdrManageOfferResult error codes', () {
      final errorCodes = [
        XdrManageOfferResultCode.MANAGE_OFFER_SELL_NOT_AUTHORIZED,
        XdrManageOfferResultCode.MANAGE_OFFER_BUY_NOT_AUTHORIZED,
        XdrManageOfferResultCode.MANAGE_OFFER_LINE_FULL,
        XdrManageOfferResultCode.MANAGE_OFFER_CROSS_SELF,
        XdrManageOfferResultCode.MANAGE_OFFER_SELL_NO_ISSUER,
        XdrManageOfferResultCode.MANAGE_OFFER_BUY_NO_ISSUER,
        XdrManageOfferResultCode.MANAGE_OFFER_NOT_FOUND,
      ];

      for (var code in errorCodes) {
        var original = XdrManageOfferResult(code, null);

        XdrDataOutputStream output = XdrDataOutputStream();
        XdrManageOfferResult.encode(output, original);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrManageOfferResult.decode(input);

        expect(decoded.discriminant.value, equals(code.value));
        expect(decoded.success, isNull);
      }
    });
  });

  group('XDR Remaining Coverage - Payment', () {
    test('XdrPaymentResult remaining error codes', () {
      final errorCodes = [
        XdrPaymentResultCode.PAYMENT_SRC_NO_TRUST,
        XdrPaymentResultCode.PAYMENT_SRC_NOT_AUTHORIZED,
        XdrPaymentResultCode.PAYMENT_NO_DESTINATION,
        XdrPaymentResultCode.PAYMENT_NO_TRUST,
        XdrPaymentResultCode.PAYMENT_NOT_AUTHORIZED,
        XdrPaymentResultCode.PAYMENT_LINE_FULL,
        XdrPaymentResultCode.PAYMENT_NO_ISSUER,
      ];

      for (var code in errorCodes) {
        var original = XdrPaymentResult(code);

        XdrDataOutputStream output = XdrDataOutputStream();
        XdrPaymentResult.encode(output, original);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrPaymentResult.decode(input);

        expect(decoded.discriminant.value, equals(code.value));
      }
    });

    test('XdrPathPaymentStrictReceiveResult remaining error codes', () {
      final errorCodes = [
        XdrPathPaymentStrictReceiveResultCode.PATH_PAYMENT_STRICT_RECEIVE_UNDERFUNDED,
        XdrPathPaymentStrictReceiveResultCode.PATH_PAYMENT_STRICT_RECEIVE_SRC_NO_TRUST,
        XdrPathPaymentStrictReceiveResultCode.PATH_PAYMENT_STRICT_RECEIVE_SRC_NOT_AUTHORIZED,
        XdrPathPaymentStrictReceiveResultCode.PATH_PAYMENT_STRICT_RECEIVE_NO_DESTINATION,
        XdrPathPaymentStrictReceiveResultCode.PATH_PAYMENT_STRICT_RECEIVE_NO_TRUST,
        XdrPathPaymentStrictReceiveResultCode.PATH_PAYMENT_STRICT_RECEIVE_NOT_AUTHORIZED,
        XdrPathPaymentStrictReceiveResultCode.PATH_PAYMENT_STRICT_RECEIVE_LINE_FULL,
        XdrPathPaymentStrictReceiveResultCode.PATH_PAYMENT_STRICT_RECEIVE_TOO_FEW_OFFERS,
        XdrPathPaymentStrictReceiveResultCode.PATH_PAYMENT_STRICT_RECEIVE_OFFER_CROSS_SELF,
        XdrPathPaymentStrictReceiveResultCode.PATH_PAYMENT_STRICT_RECEIVE_OVER_SENDMAX,
      ];

      for (var code in errorCodes) {
        var original = XdrPathPaymentStrictReceiveResult(code);

        XdrDataOutputStream output = XdrDataOutputStream();
        XdrPathPaymentStrictReceiveResult.encode(output, original);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrPathPaymentStrictReceiveResult.decode(input);

        expect(decoded.discriminant.value, equals(code.value));
      }
    });

    test('XdrPathPaymentStrictSendResult remaining error codes', () {
      final errorCodes = [
        XdrPathPaymentStrictSendResultCode.PATH_PAYMENT_STRICT_SEND_MALFORMED,
        XdrPathPaymentStrictSendResultCode.PATH_PAYMENT_STRICT_SEND_UNDERFUNDED,
        XdrPathPaymentStrictSendResultCode.PATH_PAYMENT_STRICT_SEND_SRC_NO_TRUST,
        XdrPathPaymentStrictSendResultCode.PATH_PAYMENT_STRICT_SEND_SRC_NOT_AUTHORIZED,
        XdrPathPaymentStrictSendResultCode.PATH_PAYMENT_STRICT_SEND_NO_DESTINATION,
        XdrPathPaymentStrictSendResultCode.PATH_PAYMENT_STRICT_SEND_NO_TRUST,
        XdrPathPaymentStrictSendResultCode.PATH_PAYMENT_STRICT_SEND_NOT_AUTHORIZED,
        XdrPathPaymentStrictSendResultCode.PATH_PAYMENT_STRICT_SEND_LINE_FULL,
        XdrPathPaymentStrictSendResultCode.PATH_PAYMENT_STRICT_SEND_TOO_FEW_OFFERS,
        XdrPathPaymentStrictSendResultCode.PATH_PAYMENT_STRICT_SEND_OFFER_CROSS_SELF,
      ];

      for (var code in errorCodes) {
        var original = XdrPathPaymentStrictSendResult(code);

        XdrDataOutputStream output = XdrDataOutputStream();
        XdrPathPaymentStrictSendResult.encode(output, original);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrPathPaymentStrictSendResult.decode(input);

        expect(decoded.discriminant.value, equals(code.value));
      }
    });

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

  group('XDR Remaining Coverage - Data IO', () {
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

    test('DataOutput writeBigInt64 with large value', () {
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

  group('XDR Remaining Coverage - Other Types', () {
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
      var sellerEd25519 = XdrUint256(Uint8List(32));
      var asset = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);

      var v0 = XdrClaimOfferAtomV0(
        sellerEd25519,
        XdrUint64(BigInt.from(12345)),
        asset,
        XdrInt64(BigInt.from(1000)),
        asset,
        XdrInt64(BigInt.from(2000)),
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
      expect(decoded.v0!.offerID.uint64, equals(BigInt.from(12345)));
    });

    test('XdrClaimAtom CLAIM_ATOM_TYPE_LIQUIDITY_POOL encode/decode', () {
      var liquidityPoolID = XdrHash(Uint8List(32));
      var asset = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);

      var liquidityPool = XdrClaimLiquidityAtom(
        liquidityPoolID,
        asset,
        XdrInt64(BigInt.from(5000)),
        asset,
        XdrInt64(BigInt.from(6000)),
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
      expect(decoded.liquidityPool!.amountSold.int64, equals(BigInt.from(5000)));
    });

    test('XdrDontHave encode/decode', () {
      var reqHash = XdrUint256(Uint8List(32));
      var original = XdrDontHave(XdrMessageType.ERROR_MSG, reqHash);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrDontHave.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrDontHave.decode(input);

      expect(decoded.type.value, equals(XdrMessageType.ERROR_MSG.value));
    });

    test('XdrHello encode/decode', () {
      var networkID = XdrHash(Uint8List(32));
      var publicKey = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      publicKey.setEd25519(XdrUint256(Uint8List(32)));
      var peerID = XdrNodeID(publicKey);
      var cert = XdrAuthCert(XdrCurve25519Public(Uint8List(32)), XdrUint64(BigInt.from(100)), XdrSignature(Uint8List(64)));
      var nonce = XdrUint256(Uint8List(32));

      var original = XdrHello(
        XdrUint32(1),
        XdrUint32(2),
        XdrUint32(3),
        networkID,
        'test',
        8000,
        peerID,
        cert,
        nonce,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrHello.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrHello.decode(input);

      expect(decoded.ledgerVersion.uint32, equals(1));
      expect(decoded.overlayVersion.uint32, equals(2));
      expect(decoded.overlayMinVersion.uint32, equals(3));
      expect(decoded.versionStr, equals('test'));
      expect(decoded.listeningPort, equals(8000));
    });

    test('XdrLiabilities encode/decode', () {
      var original = XdrLiabilities(
        XdrInt64(BigInt.from(1111111)),
        XdrInt64(BigInt.from(2222222)),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLiabilities.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLiabilities.decode(input);

      expect(decoded.buying.int64, equals(BigInt.from(1111111)));
      expect(decoded.selling.int64, equals(BigInt.from(2222222)));
    });

    test('XdrPrice encode/decode', () {
      var original = XdrPrice(XdrInt32(123), XdrInt32(456));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrPrice.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrPrice.decode(input);

      expect(decoded.n.int32, equals(123));
      expect(decoded.d.int32, equals(456));
    });

    test('XdrMessageType enum additional variants', () {
      final types = [
        XdrMessageType.GET_PEERS,
        XdrMessageType.PEERS,
        XdrMessageType.GET_TX_SET,
        XdrMessageType.TX_SET,
        XdrMessageType.TRANSACTION,
        XdrMessageType.GET_SCP_QUORUMSET,
        XdrMessageType.SCP_QUORUMSET,
        XdrMessageType.SCP_MESSAGE,
        XdrMessageType.GET_SCP_STATE,
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

    test('XdrStellarValue encode/decode', () {
      var txSetHash = XdrHash(Uint8List(32));
      var upgrades = <XdrUpgradeType>[];
      var ext = XdrStellarValueExt(0);

      var original = XdrStellarValue(
        txSetHash,
        XdrUint64(BigInt.from(1234567890)),
        upgrades,
        ext,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrStellarValue.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrStellarValue.decode(input);

      expect(decoded.closeTime.uint64, equals(BigInt.from(1234567890)));
      expect(decoded.upgrades, isEmpty);
      expect(decoded.ext.discriminant, equals(0));
    });

    test('XdrStellarValueExt discriminant 0 encode/decode', () {
      var original = XdrStellarValueExt(0);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrStellarValueExt.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrStellarValueExt.decode(input);

      expect(decoded.discriminant, equals(0));
    });
  });
}
