// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('XDR Payment Types - Deep Branch Testing', () {
    test('XdrPaymentResultCode enum all variants', () {
      final codes = [
        XdrPaymentResultCode.PAYMENT_SUCCESS,
        XdrPaymentResultCode.PAYMENT_MALFORMED,
        XdrPaymentResultCode.PAYMENT_UNDERFUNDED,
        XdrPaymentResultCode.PAYMENT_SRC_NO_TRUST,
        XdrPaymentResultCode.PAYMENT_SRC_NOT_AUTHORIZED,
        XdrPaymentResultCode.PAYMENT_NO_DESTINATION,
        XdrPaymentResultCode.PAYMENT_NO_TRUST,
        XdrPaymentResultCode.PAYMENT_NOT_AUTHORIZED,
        XdrPaymentResultCode.PAYMENT_LINE_FULL,
        XdrPaymentResultCode.PAYMENT_NO_ISSUER,
      ];

      for (var code in codes) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrPaymentResultCode.encode(output, code);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrPaymentResultCode.decode(input);

        expect(decoded.value, equals(code.value));
      }
    });

    test('XdrPaymentResult PAYMENT_SUCCESS encode/decode', () {
      var original = XdrPaymentResult(XdrPaymentResultCode.PAYMENT_SUCCESS);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrPaymentResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrPaymentResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrPaymentResultCode.PAYMENT_SUCCESS.value));
    });

    test('XdrPaymentResult PAYMENT_MALFORMED encode/decode', () {
      var original = XdrPaymentResult(XdrPaymentResultCode.PAYMENT_MALFORMED);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrPaymentResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrPaymentResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrPaymentResultCode.PAYMENT_MALFORMED.value));
    });

    test('XdrPaymentResult PAYMENT_UNDERFUNDED encode/decode', () {
      var original = XdrPaymentResult(XdrPaymentResultCode.PAYMENT_UNDERFUNDED);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrPaymentResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrPaymentResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrPaymentResultCode.PAYMENT_UNDERFUNDED.value));
    });

    test('XdrPathPaymentStrictReceiveResultCode enum all variants', () {
      final codes = [
        XdrPathPaymentStrictReceiveResultCode.PATH_PAYMENT_STRICT_RECEIVE_SUCCESS,
        XdrPathPaymentStrictReceiveResultCode.PATH_PAYMENT_STRICT_RECEIVE_MALFORMED,
        XdrPathPaymentStrictReceiveResultCode.PATH_PAYMENT_STRICT_RECEIVE_UNDERFUNDED,
        XdrPathPaymentStrictReceiveResultCode.PATH_PAYMENT_STRICT_RECEIVE_SRC_NO_TRUST,
        XdrPathPaymentStrictReceiveResultCode.PATH_PAYMENT_STRICT_RECEIVE_SRC_NOT_AUTHORIZED,
        XdrPathPaymentStrictReceiveResultCode.PATH_PAYMENT_STRICT_RECEIVE_NO_DESTINATION,
        XdrPathPaymentStrictReceiveResultCode.PATH_PAYMENT_STRICT_RECEIVE_NO_TRUST,
        XdrPathPaymentStrictReceiveResultCode.PATH_PAYMENT_STRICT_RECEIVE_NOT_AUTHORIZED,
        XdrPathPaymentStrictReceiveResultCode.PATH_PAYMENT_STRICT_RECEIVE_LINE_FULL,
        XdrPathPaymentStrictReceiveResultCode.PATH_PAYMENT_STRICT_RECEIVE_NO_ISSUER,
        XdrPathPaymentStrictReceiveResultCode.PATH_PAYMENT_STRICT_RECEIVE_TOO_FEW_OFFERS,
        XdrPathPaymentStrictReceiveResultCode.PATH_PAYMENT_STRICT_RECEIVE_OFFER_CROSS_SELF,
        XdrPathPaymentStrictReceiveResultCode.PATH_PAYMENT_STRICT_RECEIVE_OVER_SENDMAX,
      ];

      for (var code in codes) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrPathPaymentStrictReceiveResultCode.encode(output, code);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrPathPaymentStrictReceiveResultCode.decode(input);

        expect(decoded.value, equals(code.value));
      }
    });

    test('XdrPathPaymentStrictReceiveResult SUCCESS with offers encode/decode', () {
      var destAccount = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var destination = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      destination.ed25519 = destAccount.accountID.getEd25519();
      var asset = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);

      var simpleResult = XdrSimplePaymentResult(
        destination,
        asset,
        XdrInt64(BigInt.from(10000000)),
      );

      var success = XdrPathPaymentResultSuccess([], simpleResult);

      var original = XdrPathPaymentStrictReceiveResult(
        XdrPathPaymentStrictReceiveResultCode.PATH_PAYMENT_STRICT_RECEIVE_SUCCESS,
      );
      original.success = success;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrPathPaymentStrictReceiveResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrPathPaymentStrictReceiveResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrPathPaymentStrictReceiveResultCode.PATH_PAYMENT_STRICT_RECEIVE_SUCCESS.value));
      expect(decoded.success, isNotNull);
      expect(decoded.success!.last.amount.int64, equals(BigInt.from(10000000)));
    });

    test('XdrPathPaymentStrictReceiveResult NO_ISSUER encode/decode', () {
      var noIssuerAsset = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);

      var original = XdrPathPaymentStrictReceiveResult(
        XdrPathPaymentStrictReceiveResultCode.PATH_PAYMENT_STRICT_RECEIVE_NO_ISSUER,
      );
      original.noIssuer = noIssuerAsset;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrPathPaymentStrictReceiveResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrPathPaymentStrictReceiveResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrPathPaymentStrictReceiveResultCode.PATH_PAYMENT_STRICT_RECEIVE_NO_ISSUER.value));
      expect(decoded.noIssuer, isNotNull);
    });

    test('XdrPathPaymentStrictReceiveResult MALFORMED encode/decode', () {
      var original = XdrPathPaymentStrictReceiveResult(
        XdrPathPaymentStrictReceiveResultCode.PATH_PAYMENT_STRICT_RECEIVE_MALFORMED,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrPathPaymentStrictReceiveResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrPathPaymentStrictReceiveResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrPathPaymentStrictReceiveResultCode.PATH_PAYMENT_STRICT_RECEIVE_MALFORMED.value));
    });

    test('XdrPathPaymentStrictSendResultCode enum all variants', () {
      final codes = [
        XdrPathPaymentStrictSendResultCode.PATH_PAYMENT_STRICT_SEND_SUCCESS,
        XdrPathPaymentStrictSendResultCode.PATH_PAYMENT_STRICT_SEND_MALFORMED,
        XdrPathPaymentStrictSendResultCode.PATH_PAYMENT_STRICT_SEND_UNDERFUNDED,
        XdrPathPaymentStrictSendResultCode.PATH_PAYMENT_STRICT_SEND_SRC_NO_TRUST,
        XdrPathPaymentStrictSendResultCode.PATH_PAYMENT_STRICT_SEND_SRC_NOT_AUTHORIZED,
        XdrPathPaymentStrictSendResultCode.PATH_PAYMENT_STRICT_SEND_NO_DESTINATION,
        XdrPathPaymentStrictSendResultCode.PATH_PAYMENT_STRICT_SEND_NO_TRUST,
        XdrPathPaymentStrictSendResultCode.PATH_PAYMENT_STRICT_SEND_NOT_AUTHORIZED,
        XdrPathPaymentStrictSendResultCode.PATH_PAYMENT_STRICT_SEND_LINE_FULL,
        XdrPathPaymentStrictSendResultCode.PATH_PAYMENT_STRICT_SEND_NO_ISSUER,
        XdrPathPaymentStrictSendResultCode.PATH_PAYMENT_STRICT_SEND_TOO_FEW_OFFERS,
        XdrPathPaymentStrictSendResultCode.PATH_PAYMENT_STRICT_SEND_OFFER_CROSS_SELF,
        XdrPathPaymentStrictSendResultCode.PATH_PAYMENT_STRICT_SEND_UNDER_DESTMIN,
      ];

      for (var code in codes) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrPathPaymentStrictSendResultCode.encode(output, code);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrPathPaymentStrictSendResultCode.decode(input);

        expect(decoded.value, equals(code.value));
      }
    });

    test('XdrPathPaymentStrictSendResult SUCCESS encode/decode', () {
      var destAccount = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var destination = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      destination.ed25519 = destAccount.accountID.getEd25519();
      var asset = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);

      var simpleResult = XdrSimplePaymentResult(
        destination,
        asset,
        XdrInt64(BigInt.from(5000000)),
      );

      var success = XdrPathPaymentResultSuccess([], simpleResult);

      var original = XdrPathPaymentStrictSendResult(
        XdrPathPaymentStrictSendResultCode.PATH_PAYMENT_STRICT_SEND_SUCCESS,
      );
      original.success = success;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrPathPaymentStrictSendResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrPathPaymentStrictSendResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrPathPaymentStrictSendResultCode.PATH_PAYMENT_STRICT_SEND_SUCCESS.value));
      expect(decoded.success, isNotNull);
      expect(decoded.success!.last.amount.int64, equals(BigInt.from(5000000)));
    });

    test('XdrPathPaymentStrictSendResult NO_ISSUER encode/decode', () {
      var noIssuerAsset = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);

      var original = XdrPathPaymentStrictSendResult(
        XdrPathPaymentStrictSendResultCode.PATH_PAYMENT_STRICT_SEND_NO_ISSUER,
      );
      original.noIssuer = noIssuerAsset;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrPathPaymentStrictSendResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrPathPaymentStrictSendResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrPathPaymentStrictSendResultCode.PATH_PAYMENT_STRICT_SEND_NO_ISSUER.value));
      expect(decoded.noIssuer, isNotNull);
    });

    test('XdrPathPaymentStrictSendResult UNDER_DESTMIN encode/decode', () {
      var original = XdrPathPaymentStrictSendResult(
        XdrPathPaymentStrictSendResultCode.PATH_PAYMENT_STRICT_SEND_UNDER_DESTMIN,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrPathPaymentStrictSendResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrPathPaymentStrictSendResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrPathPaymentStrictSendResultCode.PATH_PAYMENT_STRICT_SEND_UNDER_DESTMIN.value));
    });

    test('XdrSimplePaymentResult encode/decode round-trip', () {
      var destAccount = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var destination = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      destination.ed25519 = destAccount.accountID.getEd25519();
      var asset = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);

      var original = XdrSimplePaymentResult(
        destination,
        asset,
        XdrInt64(BigInt.from(12345678)),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSimplePaymentResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSimplePaymentResult.decode(input);

      expect(decoded.amount.int64, equals(original.amount.int64));
      expect(decoded.asset.discriminant.value, equals(original.asset.discriminant.value));
    });

    test('XdrPaymentOp encode/decode round-trip', () {
      var destAccount = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var destination = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      destination.ed25519 = destAccount.accountID.getEd25519();
      var asset = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);

      var original = XdrPaymentOp(
        destination,
        asset,
        XdrBigInt64(BigInt.from(100000000)),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrPaymentOp.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrPaymentOp.decode(input);

      expect(decoded.amount.bigInt, equals(original.amount.bigInt));
      expect(decoded.asset.discriminant.value, equals(original.asset.discriminant.value));
    });

    test('XdrPathPaymentStrictReceiveOp encode/decode with empty path', () {
      var sendAsset = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var destAsset = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var destAccount = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var destination = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      destination.ed25519 = destAccount.accountID.getEd25519();

      var original = XdrPathPaymentStrictReceiveOp(
        sendAsset,
        XdrBigInt64(BigInt.from(200000000)),
        destination,
        destAsset,
        XdrBigInt64(BigInt.from(100000000)),
        [],
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrPathPaymentStrictReceiveOp.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrPathPaymentStrictReceiveOp.decode(input);

      expect(decoded.sendMax.bigInt, equals(original.sendMax.bigInt));
      expect(decoded.destAmount.bigInt, equals(original.destAmount.bigInt));
      expect(decoded.path, isEmpty);
    });

    test('XdrPathPaymentStrictReceiveOp encode/decode with path', () {
      var sendAsset = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var destAsset = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var pathAsset1 = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var pathAsset2 = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var destAccount = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var destination = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      destination.ed25519 = destAccount.accountID.getEd25519();

      var original = XdrPathPaymentStrictReceiveOp(
        sendAsset,
        XdrBigInt64(BigInt.from(300000000)),
        destination,
        destAsset,
        XdrBigInt64(BigInt.from(150000000)),
        [pathAsset1, pathAsset2],
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrPathPaymentStrictReceiveOp.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrPathPaymentStrictReceiveOp.decode(input);

      expect(decoded.sendMax.bigInt, equals(original.sendMax.bigInt));
      expect(decoded.destAmount.bigInt, equals(original.destAmount.bigInt));
      expect(decoded.path.length, equals(2));
    });

    test('XdrPathPaymentStrictSendOp encode/decode with empty path', () {
      var sendAsset = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var destAsset = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var destAccount = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var destination = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      destination.ed25519 = destAccount.accountID.getEd25519();

      var original = XdrPathPaymentStrictSendOp(
        sendAsset,
        XdrBigInt64(BigInt.from(100000000)),
        destination,
        destAsset,
        XdrBigInt64(BigInt.from(90000000)),
        [],
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrPathPaymentStrictSendOp.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrPathPaymentStrictSendOp.decode(input);

      expect(decoded.sendMax.bigInt, equals(original.sendMax.bigInt));
      expect(decoded.destAmount.bigInt, equals(original.destAmount.bigInt));
      expect(decoded.path, isEmpty);
    });

    test('XdrPathPaymentStrictSendOp encode/decode with path', () {
      var sendAsset = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var destAsset = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var pathAsset1 = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var destAccount = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var destination = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      destination.ed25519 = destAccount.accountID.getEd25519();

      var original = XdrPathPaymentStrictSendOp(
        sendAsset,
        XdrBigInt64(BigInt.from(50000000)),
        destination,
        destAsset,
        XdrBigInt64(BigInt.from(45000000)),
        [pathAsset1],
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrPathPaymentStrictSendOp.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrPathPaymentStrictSendOp.decode(input);

      expect(decoded.sendMax.bigInt, equals(original.sendMax.bigInt));
      expect(decoded.destAmount.bigInt, equals(original.destAmount.bigInt));
      expect(decoded.path.length, equals(1));
    });
  });
}
