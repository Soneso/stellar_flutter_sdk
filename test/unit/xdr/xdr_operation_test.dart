// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('XDR Operation Types - Deep Branch Testing', () {
    test('XdrOperationType enum all variants', () {
      final types = [
        XdrOperationType.CREATE_ACCOUNT,
        XdrOperationType.PAYMENT,
        XdrOperationType.PATH_PAYMENT_STRICT_RECEIVE,
        XdrOperationType.MANAGE_SELL_OFFER,
        XdrOperationType.CREATE_PASSIVE_SELL_OFFER,
        XdrOperationType.SET_OPTIONS,
        XdrOperationType.CHANGE_TRUST,
        XdrOperationType.ALLOW_TRUST,
        XdrOperationType.ACCOUNT_MERGE,
        XdrOperationType.INFLATION,
        XdrOperationType.MANAGE_DATA,
        XdrOperationType.BUMP_SEQUENCE,
        XdrOperationType.MANAGE_BUY_OFFER,
        XdrOperationType.PATH_PAYMENT_STRICT_SEND,
        XdrOperationType.CREATE_CLAIMABLE_BALANCE,
        XdrOperationType.CLAIM_CLAIMABLE_BALANCE,
        XdrOperationType.BEGIN_SPONSORING_FUTURE_RESERVES,
        XdrOperationType.END_SPONSORING_FUTURE_RESERVES,
        XdrOperationType.REVOKE_SPONSORSHIP,
        XdrOperationType.CLAWBACK,
        XdrOperationType.CLAWBACK_CLAIMABLE_BALANCE,
        XdrOperationType.SET_TRUST_LINE_FLAGS,
        XdrOperationType.LIQUIDITY_POOL_DEPOSIT,
        XdrOperationType.LIQUIDITY_POOL_WITHDRAW,
        XdrOperationType.INVOKE_HOST_FUNCTION,
        XdrOperationType.EXTEND_FOOTPRINT_TTL,
        XdrOperationType.RESTORE_FOOTPRINT,
      ];

      for (var type in types) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrOperationType.encode(output, type);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrOperationType.decode(input);

        expect(decoded.value, equals(type.value));
      }
    });

    test('XdrOperation with no sourceAccount encode/decode', () {
      var body = XdrOperationBody(XdrOperationType.INFLATION);
      var original = XdrOperation(body);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperation.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperation.decode(input);

      expect(decoded.sourceAccount, isNull);
      expect(decoded.body.discriminant.value, equals(XdrOperationType.INFLATION.value));
    });

    test('XdrOperation with sourceAccount encode/decode', () {
      var sourceAccount = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      sourceAccount.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAA)));

      var body = XdrOperationBody(XdrOperationType.INFLATION);
      var original = XdrOperation(body);
      original.sourceAccount = sourceAccount;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperation.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperation.decode(input);

      expect(decoded.sourceAccount, isNotNull);
      expect(decoded.sourceAccount!.discriminant.value, equals(XdrCryptoKeyType.KEY_TYPE_ED25519.value));
    });

    test('XdrOperationBody INFLATION encode/decode', () {
      var original = XdrOperationBody(XdrOperationType.INFLATION);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationBody.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationBody.decode(input);

      expect(decoded.discriminant.value, equals(XdrOperationType.INFLATION.value));
    });

    test('XdrOperationBody CREATE_ACCOUNT encode/decode', () {
      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x11))));
      var destination = XdrAccountID(pk);

      var createAccountOp = XdrCreateAccountOp(
        destination,
        XdrBigInt64(BigInt.from(10000000)),
      );

      var original = XdrOperationBody(XdrOperationType.CREATE_ACCOUNT);
      original.createAccountOp = createAccountOp;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationBody.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationBody.decode(input);

      expect(decoded.discriminant.value, equals(XdrOperationType.CREATE_ACCOUNT.value));
      expect(decoded.createAccountOp, isNotNull);
      expect(decoded.createAccountOp!.startingBalance.bigInt, equals(BigInt.from(10000000)));
    });

    test('XdrOperationBody PAYMENT encode/decode', () {
      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x22))));
      var destination = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      destination.ed25519 = pk.getEd25519();

      var asset = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);

      var paymentOp = XdrPaymentOp(
        destination,
        asset,
        XdrBigInt64(BigInt.from(5000000)),
      );

      var original = XdrOperationBody(XdrOperationType.PAYMENT);
      original.paymentOp = paymentOp;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationBody.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationBody.decode(input);

      expect(decoded.discriminant.value, equals(XdrOperationType.PAYMENT.value));
      expect(decoded.paymentOp, isNotNull);
      expect(decoded.paymentOp!.amount.bigInt, equals(BigInt.from(5000000)));
    });

    test('XdrOperationBody MANAGE_DATA encode/decode', () {
      var dataName = XdrString64('test_data');
      var dataValue = XdrDataValue(Uint8List.fromList([1, 2, 3, 4, 5]));

      var manageDataOp = XdrManageDataOp(dataName, dataValue);

      var original = XdrOperationBody(XdrOperationType.MANAGE_DATA);
      original.manageDataOp = manageDataOp;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationBody.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationBody.decode(input);

      expect(decoded.discriminant.value, equals(XdrOperationType.MANAGE_DATA.value));
      expect(decoded.manageDataOp, isNotNull);
      expect(decoded.manageDataOp!.dataName.string64, equals('test_data'));
    });

    test('XdrOperationBody BUMP_SEQUENCE encode/decode', () {
      var bumpSequenceOp = XdrBumpSequenceOp(
        XdrSequenceNumber(XdrBigInt64(BigInt.from(999999999))),
      );

      var original = XdrOperationBody(XdrOperationType.BUMP_SEQUENCE);
      original.bumpSequenceOp = bumpSequenceOp;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationBody.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationBody.decode(input);

      expect(decoded.discriminant.value, equals(XdrOperationType.BUMP_SEQUENCE.value));
      expect(decoded.bumpSequenceOp, isNotNull);
      expect(decoded.bumpSequenceOp!.bumpTo.sequenceNumber.bigInt, equals(BigInt.from(999999999)));
    });

    test('XdrOperationBody ACCOUNT_MERGE encode/decode', () {
      var destination = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      destination.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x33)));

      var original = XdrOperationBody(XdrOperationType.ACCOUNT_MERGE);
      original.destination = destination;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationBody.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationBody.decode(input);

      expect(decoded.discriminant.value, equals(XdrOperationType.ACCOUNT_MERGE.value));
      expect(decoded.destination, isNotNull);
      expect(decoded.destination!.discriminant.value, equals(XdrCryptoKeyType.KEY_TYPE_ED25519.value));
    });

    test('XdrOperationBody SET_OPTIONS encode/decode', () {
      var setOptionsOp = XdrSetOptionsOp();
      setOptionsOp.masterWeight = XdrUint32(100);
      setOptionsOp.lowThreshold = XdrUint32(10);
      setOptionsOp.medThreshold = XdrUint32(50);
      setOptionsOp.highThreshold = XdrUint32(100);

      var original = XdrOperationBody(XdrOperationType.SET_OPTIONS);
      original.setOptionsOp = setOptionsOp;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationBody.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationBody.decode(input);

      expect(decoded.discriminant.value, equals(XdrOperationType.SET_OPTIONS.value));
      expect(decoded.setOptionsOp, isNotNull);
      expect(decoded.setOptionsOp!.masterWeight, isNotNull);
      expect(decoded.setOptionsOp!.masterWeight!.uint32, equals(100));
    });

    test('XdrCreateAccountOp encode/decode round-trip', () {
      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x44))));
      var destination = XdrAccountID(pk);

      var original = XdrCreateAccountOp(
        destination,
        XdrBigInt64(BigInt.from(20000000)),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrCreateAccountOp.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrCreateAccountOp.decode(input);

      expect(decoded.startingBalance.bigInt, equals(BigInt.from(20000000)));
    });

    test('XdrBumpSequenceOp encode/decode round-trip', () {
      var original = XdrBumpSequenceOp(
        XdrSequenceNumber(XdrBigInt64(BigInt.from(12345678))),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrBumpSequenceOp.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrBumpSequenceOp.decode(input);

      expect(decoded.bumpTo.sequenceNumber.bigInt, equals(BigInt.from(12345678)));
    });

    test('XdrManageDataOp with null dataValue encode/decode', () {
      var dataName = XdrString64('to_delete');

      var original = XdrManageDataOp(dataName, null);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrManageDataOp.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrManageDataOp.decode(input);

      expect(decoded.dataName.string64, equals('to_delete'));
      expect(decoded.dataValue, isNull);
    });

    test('XdrSetOptionsOp with all fields null encode/decode', () {
      var original = XdrSetOptionsOp();

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSetOptionsOp.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSetOptionsOp.decode(input);

      expect(decoded.inflationDest, isNull);
      expect(decoded.clearFlags, isNull);
      expect(decoded.setFlags, isNull);
      expect(decoded.masterWeight, isNull);
      expect(decoded.lowThreshold, isNull);
      expect(decoded.medThreshold, isNull);
      expect(decoded.highThreshold, isNull);
      expect(decoded.homeDomain, isNull);
      expect(decoded.signer, isNull);
    });

    test('XdrSetOptionsOp with signer encode/decode', () {
      var signerKey = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519);
      signerKey.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x55)));

      var signer = XdrSigner(signerKey, XdrUint32(10));

      var original = XdrSetOptionsOp();
      original.signer = signer;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSetOptionsOp.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSetOptionsOp.decode(input);

      expect(decoded.signer, isNotNull);
      expect(decoded.signer!.weight.uint32, equals(10));
    });

    test('XdrLiquidityPoolDepositOp encode/decode round-trip', () {
      var poolID = XdrHash(Uint8List.fromList(List<int>.filled(32, 0x66)));

      var original = XdrLiquidityPoolDepositOp(
        poolID,
        XdrBigInt64(BigInt.from(1000000)),
        XdrBigInt64(BigInt.from(2000000)),
        XdrPrice(XdrInt32(1), XdrInt32(2)),
        XdrPrice(XdrInt32(2), XdrInt32(1)),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLiquidityPoolDepositOp.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLiquidityPoolDepositOp.decode(input);

      expect(decoded.maxAmountA.bigInt, equals(BigInt.from(1000000)));
      expect(decoded.maxAmountB.bigInt, equals(BigInt.from(2000000)));
      expect(decoded.minPrice.n.int32, equals(1));
      expect(decoded.minPrice.d.int32, equals(2));
    });

    test('XdrLiquidityPoolWithdrawOp encode/decode round-trip', () {
      var poolID = XdrHash(Uint8List.fromList(List<int>.filled(32, 0x77)));

      var original = XdrLiquidityPoolWithdrawOp(
        poolID,
        XdrBigInt64(BigInt.from(500000)),
        XdrBigInt64(BigInt.from(100000)),
        XdrBigInt64(BigInt.from(200000)),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLiquidityPoolWithdrawOp.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLiquidityPoolWithdrawOp.decode(input);

      expect(decoded.amount.bigInt, equals(BigInt.from(500000)));
      expect(decoded.minAmountA.bigInt, equals(BigInt.from(100000)));
      expect(decoded.minAmountB.bigInt, equals(BigInt.from(200000)));
    });

    test('XdrOperationMeta encode/decode round-trip', () {
      var changes = XdrLedgerEntryChanges([]);

      var original = XdrOperationMeta(changes);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationMeta.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationMeta.decode(input);

      expect(decoded.changes.ledgerEntryChanges, isEmpty);
    });

    test('XdrOperationResult opINNER encode/decode', () {
      var original = XdrOperationResult(XdrOperationResultCode.opINNER);
      var tr = XdrOperationResultTr(XdrOperationType.INFLATION);
      var inflationResult = XdrInflationResult(XdrInflationResultCode.INFLATION_SUCCESS);
      inflationResult.payouts = [];
      tr.inflationResult = inflationResult;
      original.tr = tr;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrOperationResultCode.opINNER.value));
      expect(decoded.tr, isNotNull);
    });

    test('XdrOperationResult opBAD_AUTH encode/decode', () {
      var original = XdrOperationResult(XdrOperationResultCode.opBAD_AUTH);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrOperationResultCode.opBAD_AUTH.value));
      expect(decoded.tr, isNull);
    });

    test('XdrOperationResultCode enum all variants', () {
      final types = [
        XdrOperationResultCode.opINNER,
        XdrOperationResultCode.opBAD_AUTH,
        XdrOperationResultCode.opNO_ACCOUNT,
        XdrOperationResultCode.opNOT_SUPPORTED,
        XdrOperationResultCode.opTOO_MANY_SUBENTRIES,
        XdrOperationResultCode.opEXCEEDED_WORK_LIMIT,
      ];

      for (var type in types) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrOperationResultCode.encode(output, type);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrOperationResultCode.decode(input);

        expect(decoded.value, equals(type.value));
      }
    });

    test('XdrOperationBody MANAGE_SELL_OFFER encode/decode', () {
      var selling = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var buying = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);

      var manageSellOfferOp = XdrManageSellOfferOp(
        selling,
        buying,
        XdrBigInt64(BigInt.from(1000000)),
        XdrPrice(XdrInt32(1), XdrInt32(1)),
        XdrUint64(BigInt.from(123)),
      );

      var original = XdrOperationBody(XdrOperationType.MANAGE_SELL_OFFER);
      original.manageSellOfferOp = manageSellOfferOp;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationBody.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationBody.decode(input);

      expect(decoded.discriminant.value, equals(XdrOperationType.MANAGE_SELL_OFFER.value));
      expect(decoded.manageSellOfferOp, isNotNull);
      expect(decoded.manageSellOfferOp!.amount.bigInt, equals(BigInt.from(1000000)));
      expect(decoded.manageSellOfferOp!.offerID.uint64, equals(BigInt.from(123)));
    });

    test('XdrOperationBody MANAGE_BUY_OFFER encode/decode', () {
      var selling = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var buying = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);

      var manageBuyOfferOp = XdrManageBuyOfferOp(
        selling,
        buying,
        XdrBigInt64(BigInt.from(2000000)),
        XdrPrice(XdrInt32(2), XdrInt32(1)),
        XdrUint64(BigInt.from(456)),
      );

      var original = XdrOperationBody(XdrOperationType.MANAGE_BUY_OFFER);
      original.manageBuyOfferOp = manageBuyOfferOp;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationBody.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationBody.decode(input);

      expect(decoded.discriminant.value, equals(XdrOperationType.MANAGE_BUY_OFFER.value));
      expect(decoded.manageBuyOfferOp, isNotNull);
      expect(decoded.manageBuyOfferOp!.amount.bigInt, equals(BigInt.from(2000000)));
      expect(decoded.manageBuyOfferOp!.offerID.uint64, equals(BigInt.from(456)));
    });

    test('XdrOperationBody CREATE_PASSIVE_SELL_OFFER encode/decode', () {
      var selling = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var buying = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);

      var createPassiveSellOfferOp = XdrCreatePassiveSellOfferOp(
        selling,
        buying,
        XdrBigInt64(BigInt.from(3000000)),
        XdrPrice(XdrInt32(1), XdrInt32(2)),
      );

      var original = XdrOperationBody(XdrOperationType.CREATE_PASSIVE_SELL_OFFER);
      original.createPassiveOfferOp = createPassiveSellOfferOp;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationBody.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationBody.decode(input);

      expect(decoded.discriminant.value, equals(XdrOperationType.CREATE_PASSIVE_SELL_OFFER.value));
      expect(decoded.createPassiveSellOfferOp, isNotNull);
      expect(decoded.createPassiveSellOfferOp!.amount.bigInt, equals(BigInt.from(3000000)));
    });

    test('XdrOperationBody PATH_PAYMENT_STRICT_RECEIVE encode/decode', () {
      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x88))));
      var destination = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      destination.ed25519 = pk.getEd25519();

      var sendAsset = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var destAsset = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);

      var pathPaymentOp = XdrPathPaymentStrictReceiveOp(
        sendAsset,
        XdrBigInt64(BigInt.from(1000000)),
        destination,
        destAsset,
        XdrBigInt64(BigInt.from(900000)),
        [],
      );

      var original = XdrOperationBody(XdrOperationType.PATH_PAYMENT_STRICT_RECEIVE);
      original.pathPaymentStrictReceiveOp = pathPaymentOp;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationBody.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationBody.decode(input);

      expect(decoded.discriminant.value, equals(XdrOperationType.PATH_PAYMENT_STRICT_RECEIVE.value));
      expect(decoded.pathPaymentStrictReceiveOp, isNotNull);
      expect(decoded.pathPaymentStrictReceiveOp!.sendMax.bigInt, equals(BigInt.from(1000000)));
      expect(decoded.pathPaymentStrictReceiveOp!.destAmount.bigInt, equals(BigInt.from(900000)));
    });

    test('XdrOperationBody PATH_PAYMENT_STRICT_SEND encode/decode', () {
      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x99))));
      var destination = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      destination.ed25519 = pk.getEd25519();

      var sendAsset = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var destAsset = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);

      var pathPaymentOp = XdrPathPaymentStrictSendOp(
        sendAsset,
        XdrBigInt64(BigInt.from(1000000)),
        destination,
        destAsset,
        XdrBigInt64(BigInt.from(900000)),
        [],
      );

      var original = XdrOperationBody(XdrOperationType.PATH_PAYMENT_STRICT_SEND);
      original.pathPaymentStrictSendOp = pathPaymentOp;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationBody.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationBody.decode(input);

      expect(decoded.discriminant.value, equals(XdrOperationType.PATH_PAYMENT_STRICT_SEND.value));
      expect(decoded.pathPaymentStrictSendOp, isNotNull);
      expect(decoded.pathPaymentStrictSendOp!.sendMax.bigInt, equals(BigInt.from(1000000)));
      expect(decoded.pathPaymentStrictSendOp!.destAmount.bigInt, equals(BigInt.from(900000)));
    });

    test('XdrOperationBody CHANGE_TRUST encode/decode', () {
      var changeTrustAsset = XdrChangeTrustAsset(XdrAssetType.ASSET_TYPE_NATIVE);

      var changeTrustOp = XdrChangeTrustOp(
        changeTrustAsset,
        XdrBigInt64(BigInt.from(1000000)),
      );

      var original = XdrOperationBody(XdrOperationType.CHANGE_TRUST);
      original.changeTrustOp = changeTrustOp;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationBody.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationBody.decode(input);

      expect(decoded.discriminant.value, equals(XdrOperationType.CHANGE_TRUST.value));
      expect(decoded.changeTrustOp, isNotNull);
      expect(decoded.changeTrustOp!.limit.bigInt, equals(BigInt.from(1000000)));
    });

    test('XdrOperationBody ALLOW_TRUST encode/decode', () {
      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAA))));
      var trustor = XdrAccountID(pk);

      var allowTrustOpAsset = XdrAllowTrustOpAsset(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4);
      allowTrustOpAsset.assetCode4 = Uint8List.fromList([65, 66, 67, 68]);

      var allowTrustOp = XdrAllowTrustOp(trustor, allowTrustOpAsset, 1);

      var original = XdrOperationBody(XdrOperationType.ALLOW_TRUST);
      original.allowTrustOp = allowTrustOp;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationBody.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationBody.decode(input);

      expect(decoded.discriminant.value, equals(XdrOperationType.ALLOW_TRUST.value));
      expect(decoded.allowTrustOp, isNotNull);
      expect(decoded.allowTrustOp!.authorize, equals(1));
    });

    test('XdrOperationBody CREATE_CLAIMABLE_BALANCE encode/decode', () {
      var asset = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);

      var createClaimableBalanceOp = XdrCreateClaimableBalanceOp(
        asset,
        XdrBigInt64(BigInt.from(5000000)),
        [],
      );

      var original = XdrOperationBody(XdrOperationType.CREATE_CLAIMABLE_BALANCE);
      original.createClaimableBalanceOp = createClaimableBalanceOp;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationBody.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationBody.decode(input);

      expect(decoded.discriminant.value, equals(XdrOperationType.CREATE_CLAIMABLE_BALANCE.value));
      expect(decoded.createClaimableBalanceOp, isNotNull);
      expect(decoded.createClaimableBalanceOp!.amount.bigInt, equals(BigInt.from(5000000)));
    });

    test('XdrOperationBody CLAIM_CLAIMABLE_BALANCE encode/decode', () {
      var balanceID = XdrClaimableBalanceID(XdrClaimableBalanceIDType.CLAIMABLE_BALANCE_ID_TYPE_V0);
      balanceID.v0 = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xBB)));

      var claimClaimableBalanceOp = XdrClaimClaimableBalanceOp(balanceID);

      var original = XdrOperationBody(XdrOperationType.CLAIM_CLAIMABLE_BALANCE);
      original.claimClaimableBalanceOp = claimClaimableBalanceOp;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationBody.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationBody.decode(input);

      expect(decoded.discriminant.value, equals(XdrOperationType.CLAIM_CLAIMABLE_BALANCE.value));
      expect(decoded.claimClaimableBalanceOp, isNotNull);
    });

    test('XdrOperationBody BEGIN_SPONSORING_FUTURE_RESERVES encode/decode', () {
      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xCC))));
      var sponsoredID = XdrAccountID(pk);

      var beginSponsoringOp = XdrBeginSponsoringFutureReservesOp(sponsoredID);

      var original = XdrOperationBody(XdrOperationType.BEGIN_SPONSORING_FUTURE_RESERVES);
      original.beginSponsoringFutureReservesOp = beginSponsoringOp;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationBody.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationBody.decode(input);

      expect(decoded.discriminant.value, equals(XdrOperationType.BEGIN_SPONSORING_FUTURE_RESERVES.value));
      expect(decoded.beginSponsoringFutureReservesOp, isNotNull);
    });

    test('XdrOperationBody END_SPONSORING_FUTURE_RESERVES encode/decode', () {
      var original = XdrOperationBody(XdrOperationType.END_SPONSORING_FUTURE_RESERVES);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationBody.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationBody.decode(input);

      expect(decoded.discriminant.value, equals(XdrOperationType.END_SPONSORING_FUTURE_RESERVES.value));
    });

    test('XdrOperationBody CLAWBACK encode/decode', () {
      var asset = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xDD))));
      var from = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      from.ed25519 = pk.getEd25519();

      var clawbackOp = XdrClawbackOp(
        asset,
        from,
        XdrBigInt64(BigInt.from(100000)),
      );

      var original = XdrOperationBody(XdrOperationType.CLAWBACK);
      original.clawbackOp = clawbackOp;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationBody.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationBody.decode(input);

      expect(decoded.discriminant.value, equals(XdrOperationType.CLAWBACK.value));
      expect(decoded.clawbackOp, isNotNull);
      expect(decoded.clawbackOp!.amount.bigInt, equals(BigInt.from(100000)));
    });

    test('XdrOperationBody CLAWBACK_CLAIMABLE_BALANCE encode/decode', () {
      var balanceID = XdrClaimableBalanceID(XdrClaimableBalanceIDType.CLAIMABLE_BALANCE_ID_TYPE_V0);
      balanceID.v0 = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xEE)));

      var clawbackClaimableBalanceOp = XdrClawbackClaimableBalanceOp(balanceID);

      var original = XdrOperationBody(XdrOperationType.CLAWBACK_CLAIMABLE_BALANCE);
      original.clawbackClaimableBalanceOp = clawbackClaimableBalanceOp;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationBody.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationBody.decode(input);

      expect(decoded.discriminant.value, equals(XdrOperationType.CLAWBACK_CLAIMABLE_BALANCE.value));
      expect(decoded.clawbackClaimableBalanceOp, isNotNull);
    });

    test('XdrOperationBody SET_TRUST_LINE_FLAGS encode/decode', () {
      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xFF))));
      var trustor = XdrAccountID(pk);

      var asset = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);

      var setTrustLineFlagsOp = XdrSetTrustLineFlagsOp(
        trustor,
        asset,
        XdrUint32(0),
        XdrUint32(1),
      );

      var original = XdrOperationBody(XdrOperationType.SET_TRUST_LINE_FLAGS);
      original.setTrustLineFlagsOp = setTrustLineFlagsOp;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationBody.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationBody.decode(input);

      expect(decoded.discriminant.value, equals(XdrOperationType.SET_TRUST_LINE_FLAGS.value));
      expect(decoded.setTrustLineFlagsOp, isNotNull);
      expect(decoded.setTrustLineFlagsOp!.clearFlags.uint32, equals(0));
      expect(decoded.setTrustLineFlagsOp!.setFlags.uint32, equals(1));
    });

    test('XdrOperationResultTr CREATE_ACCOUNT encode/decode', () {
      var original = XdrOperationResultTr(XdrOperationType.CREATE_ACCOUNT);
      var createAccountResult = XdrCreateAccountResult(XdrCreateAccountResultCode.CREATE_ACCOUNT_SUCCESS);
      original.createAccountResult = createAccountResult;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationResultTr.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationResultTr.decode(input);

      expect(decoded.discriminant.value, equals(XdrOperationType.CREATE_ACCOUNT.value));
      expect(decoded.createAccountResult, isNotNull);
    });

    test('XdrOperationResultTr PAYMENT encode/decode', () {
      var original = XdrOperationResultTr(XdrOperationType.PAYMENT);
      var paymentResult = XdrPaymentResult(XdrPaymentResultCode.PAYMENT_SUCCESS);
      original.paymentResult = paymentResult;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationResultTr.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationResultTr.decode(input);

      expect(decoded.discriminant.value, equals(XdrOperationType.PAYMENT.value));
      expect(decoded.paymentResult, isNotNull);
    });

    test('XdrOperationResultTr CHANGE_TRUST encode/decode', () {
      var original = XdrOperationResultTr(XdrOperationType.CHANGE_TRUST);
      var changeTrustResult = XdrChangeTrustResult(XdrChangeTrustResultCode.CHANGE_TRUST_SUCCESS);
      original.changeTrustResult = changeTrustResult;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationResultTr.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationResultTr.decode(input);

      expect(decoded.discriminant.value, equals(XdrOperationType.CHANGE_TRUST.value));
      expect(decoded.changeTrustResult, isNotNull);
    });

    test('XdrOperationResultTr ALLOW_TRUST encode/decode', () {
      var original = XdrOperationResultTr(XdrOperationType.ALLOW_TRUST);
      var allowTrustResult = XdrAllowTrustResult(XdrAllowTrustResultCode.ALLOW_TRUST_SUCCESS);
      original.allowTrustResult = allowTrustResult;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationResultTr.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationResultTr.decode(input);

      expect(decoded.discriminant.value, equals(XdrOperationType.ALLOW_TRUST.value));
      expect(decoded.allowTrustResult, isNotNull);
    });

    test('XdrOperationResultTr CLAWBACK encode/decode', () {
      var original = XdrOperationResultTr(XdrOperationType.CLAWBACK);
      var clawbackResult = XdrClawbackResult(XdrClawbackResultCode.CLAWBACK_SUCCESS);
      original.clawbackResult = clawbackResult;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationResultTr.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationResultTr.decode(input);

      expect(decoded.discriminant.value, equals(XdrOperationType.CLAWBACK.value));
      expect(decoded.clawbackResult, isNotNull);
    });

    test('XdrOperationResultTr MANAGE_SELL_OFFER encode/decode', () {
      var original = XdrOperationResultTr(XdrOperationType.MANAGE_SELL_OFFER);
      var manageOfferResult = XdrManageOfferResult(XdrManageOfferResultCode.MANAGE_OFFER_MALFORMED, null);
      original.manageOfferResult = manageOfferResult;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationResultTr.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationResultTr.decode(input);

      expect(decoded.discriminant.value, equals(XdrOperationType.MANAGE_SELL_OFFER.value));
      expect(decoded.manageOfferResult, isNotNull);
    });

    test('XdrOperationResultTr MANAGE_BUY_OFFER encode/decode', () {
      var original = XdrOperationResultTr(XdrOperationType.MANAGE_BUY_OFFER);
      var manageOfferResult = XdrManageOfferResult(XdrManageOfferResultCode.MANAGE_OFFER_MALFORMED, null);
      original.manageOfferResult = manageOfferResult;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationResultTr.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationResultTr.decode(input);

      expect(decoded.discriminant.value, equals(XdrOperationType.MANAGE_BUY_OFFER.value));
      expect(decoded.manageOfferResult, isNotNull);
    });

    test('XdrOperationResultTr CREATE_PASSIVE_SELL_OFFER encode/decode', () {
      var original = XdrOperationResultTr(XdrOperationType.CREATE_PASSIVE_SELL_OFFER);
      var createPassiveOfferResult = XdrManageOfferResult(XdrManageOfferResultCode.MANAGE_OFFER_MALFORMED, null);
      original.createPassiveOfferResult = createPassiveOfferResult;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationResultTr.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationResultTr.decode(input);

      expect(decoded.discriminant.value, equals(XdrOperationType.CREATE_PASSIVE_SELL_OFFER.value));
      expect(decoded.createPassiveOfferResult, isNotNull);
    });

    test('XdrOperationResultTr PATH_PAYMENT_STRICT_RECEIVE encode/decode', () {
      var original = XdrOperationResultTr(XdrOperationType.PATH_PAYMENT_STRICT_RECEIVE);
      var pathPaymentResult = XdrPathPaymentStrictReceiveResult(
        XdrPathPaymentStrictReceiveResultCode.PATH_PAYMENT_STRICT_RECEIVE_MALFORMED,
      );
      original.pathPaymentStrictReceiveResult = pathPaymentResult;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationResultTr.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationResultTr.decode(input);

      expect(decoded.discriminant.value, equals(XdrOperationType.PATH_PAYMENT_STRICT_RECEIVE.value));
      expect(decoded.pathPaymentStrictReceiveResult, isNotNull);
    });

    test('XdrOperationResultTr PATH_PAYMENT_STRICT_SEND encode/decode', () {
      var original = XdrOperationResultTr(XdrOperationType.PATH_PAYMENT_STRICT_SEND);
      var pathPaymentResult = XdrPathPaymentStrictSendResult(
        XdrPathPaymentStrictSendResultCode.PATH_PAYMENT_STRICT_SEND_MALFORMED,
      );
      original.pathPaymentStrictSendResult = pathPaymentResult;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationResultTr.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationResultTr.decode(input);

      expect(decoded.discriminant.value, equals(XdrOperationType.PATH_PAYMENT_STRICT_SEND.value));
      expect(decoded.pathPaymentStrictSendResult, isNotNull);
    });

    test('XdrOperationResultTr SET_OPTIONS encode/decode', () {
      var original = XdrOperationResultTr(XdrOperationType.SET_OPTIONS);
      var setOptionsResult = XdrSetOptionsResult(XdrSetOptionsResultCode.SET_OPTIONS_SUCCESS);
      original.setOptionsResult = setOptionsResult;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationResultTr.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationResultTr.decode(input);

      expect(decoded.discriminant.value, equals(XdrOperationType.SET_OPTIONS.value));
      expect(decoded.setOptionsResult, isNotNull);
    });

    test('XdrOperationResultTr ACCOUNT_MERGE encode/decode', () {
      var original = XdrOperationResultTr(XdrOperationType.ACCOUNT_MERGE);
      var accountMergeResult = XdrAccountMergeResult(XdrAccountMergeResultCode.ACCOUNT_MERGE_SUCCESS);
      accountMergeResult.sourceAccountBalance = XdrInt64(BigInt.from(1000000));
      original.accountMergeResult = accountMergeResult;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationResultTr.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationResultTr.decode(input);

      expect(decoded.discriminant.value, equals(XdrOperationType.ACCOUNT_MERGE.value));
      expect(decoded.accountMergeResult, isNotNull);
      expect(decoded.accountMergeResult!.sourceAccountBalance, isNotNull);
      expect(decoded.accountMergeResult!.sourceAccountBalance!.int64, equals(BigInt.from(1000000)));
    });

    test('XdrOperationResultTr MANAGE_DATA encode/decode', () {
      var original = XdrOperationResultTr(XdrOperationType.MANAGE_DATA);
      var manageDataResult = XdrManageDataResult(XdrManageDataResultCode.MANAGE_DATA_SUCCESS);
      original.manageDataResult = manageDataResult;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationResultTr.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationResultTr.decode(input);

      expect(decoded.discriminant.value, equals(XdrOperationType.MANAGE_DATA.value));
      expect(decoded.manageDataResult, isNotNull);
    });

    test('XdrOperationResultTr BUMP_SEQUENCE encode/decode', () {
      var original = XdrOperationResultTr(XdrOperationType.BUMP_SEQUENCE);
      var bumpSeqResult = XdrBumpSequenceResult(XdrBumpSequenceResultCode.BUMP_SEQUENCE_SUCCESS);
      original.bumpSeqResult = bumpSeqResult;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationResultTr.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationResultTr.decode(input);

      expect(decoded.discriminant.value, equals(XdrOperationType.BUMP_SEQUENCE.value));
      expect(decoded.bumpSeqResult, isNotNull);
    });

    test('XdrOperationResultTr CREATE_CLAIMABLE_BALANCE encode/decode', () {
      var original = XdrOperationResultTr(XdrOperationType.CREATE_CLAIMABLE_BALANCE);
      var createClaimableBalanceResult = XdrCreateClaimableBalanceResult(
        XdrCreateClaimableBalanceResultCode.CREATE_CLAIMABLE_BALANCE_MALFORMED,
      );
      original.createClaimableBalanceResult = createClaimableBalanceResult;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationResultTr.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationResultTr.decode(input);

      expect(decoded.discriminant.value, equals(XdrOperationType.CREATE_CLAIMABLE_BALANCE.value));
      expect(decoded.createClaimableBalanceResult, isNotNull);
    });

    test('XdrOperationResultTr CLAIM_CLAIMABLE_BALANCE encode/decode', () {
      var original = XdrOperationResultTr(XdrOperationType.CLAIM_CLAIMABLE_BALANCE);
      var claimClaimableBalanceResult = XdrClaimClaimableBalanceResult(
        XdrClaimClaimableBalanceResultCode.CLAIM_CLAIMABLE_BALANCE_SUCCESS,
      );
      original.claimClaimableBalanceResult = claimClaimableBalanceResult;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationResultTr.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationResultTr.decode(input);

      expect(decoded.discriminant.value, equals(XdrOperationType.CLAIM_CLAIMABLE_BALANCE.value));
      expect(decoded.claimClaimableBalanceResult, isNotNull);
    });

    test('XdrOperationResultTr BEGIN_SPONSORING_FUTURE_RESERVES encode/decode', () {
      var original = XdrOperationResultTr(XdrOperationType.BEGIN_SPONSORING_FUTURE_RESERVES);
      var beginSponsoringResult = XdrBeginSponsoringFutureReservesResult(
        XdrBeginSponsoringFutureReservesResultCode.BEGIN_SPONSORING_FUTURE_RESERVES_SUCCESS,
      );
      original.beginSponsoringFutureReservesResult = beginSponsoringResult;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationResultTr.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationResultTr.decode(input);

      expect(decoded.discriminant.value, equals(XdrOperationType.BEGIN_SPONSORING_FUTURE_RESERVES.value));
      expect(decoded.beginSponsoringFutureReservesResult, isNotNull);
    });

    test('XdrOperationResultTr END_SPONSORING_FUTURE_RESERVES encode/decode', () {
      var original = XdrOperationResultTr(XdrOperationType.END_SPONSORING_FUTURE_RESERVES);
      var endSponsoringResult = XdrEndSponsoringFutureReservesResult(
        XdrEndSponsoringFutureReservesResultCode.END_SPONSORING_FUTURE_RESERVES_SUCCESS,
      );
      original.endSponsoringFutureReservesResult = endSponsoringResult;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationResultTr.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationResultTr.decode(input);

      expect(decoded.discriminant.value, equals(XdrOperationType.END_SPONSORING_FUTURE_RESERVES.value));
      expect(decoded.endSponsoringFutureReservesResult, isNotNull);
    });

    test('XdrOperationResultTr REVOKE_SPONSORSHIP encode/decode', () {
      var original = XdrOperationResultTr(XdrOperationType.REVOKE_SPONSORSHIP);
      var revokeSponsorshipResult = XdrRevokeSponsorshipResult(
        XdrRevokeSponsorshipResultCode.REVOKE_SPONSORSHIP_SUCCESS,
      );
      original.revokeSponsorshipResult = revokeSponsorshipResult;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationResultTr.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationResultTr.decode(input);

      expect(decoded.discriminant.value, equals(XdrOperationType.REVOKE_SPONSORSHIP.value));
      expect(decoded.revokeSponsorshipResult, isNotNull);
    });

    test('XdrOperationResultTr CLAWBACK_CLAIMABLE_BALANCE encode/decode', () {
      var original = XdrOperationResultTr(XdrOperationType.CLAWBACK_CLAIMABLE_BALANCE);
      var clawbackClaimableBalanceResult = XdrClawbackClaimableBalanceResult(
        XdrClawbackClaimableBalanceResultCode.CLAWBACK_CLAIMABLE_BALANCE_SUCCESS,
      );
      original.clawbackClaimableBalanceResult = clawbackClaimableBalanceResult;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationResultTr.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationResultTr.decode(input);

      expect(decoded.discriminant.value, equals(XdrOperationType.CLAWBACK_CLAIMABLE_BALANCE.value));
      expect(decoded.clawbackClaimableBalanceResult, isNotNull);
    });

    test('XdrOperationResultTr SET_TRUST_LINE_FLAGS encode/decode', () {
      var original = XdrOperationResultTr(XdrOperationType.SET_TRUST_LINE_FLAGS);
      var setTrustLineFlagsResult = XdrSetTrustLineFlagsResult(
        XdrSetTrustLineFlagsResultCode.SET_TRUST_LINE_FLAGS_SUCCESS,
      );
      original.setTrustLineFlagsResult = setTrustLineFlagsResult;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationResultTr.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationResultTr.decode(input);

      expect(decoded.discriminant.value, equals(XdrOperationType.SET_TRUST_LINE_FLAGS.value));
      expect(decoded.setTrustLineFlagsResult, isNotNull);
    });

    test('XdrOperationResultTr LIQUIDITY_POOL_DEPOSIT encode/decode', () {
      var original = XdrOperationResultTr(XdrOperationType.LIQUIDITY_POOL_DEPOSIT);
      var liquidityPoolDepositResult = XdrLiquidityPoolDepositResult(
        XdrLiquidityPoolDepositResultCode.LIQUIDITY_POOL_DEPOSIT_SUCCESS,
      );
      original.liquidityPoolDepositResult = liquidityPoolDepositResult;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationResultTr.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationResultTr.decode(input);

      expect(decoded.discriminant.value, equals(XdrOperationType.LIQUIDITY_POOL_DEPOSIT.value));
      expect(decoded.liquidityPoolDepositResult, isNotNull);
    });

    test('XdrOperationResultTr LIQUIDITY_POOL_WITHDRAW encode/decode', () {
      var original = XdrOperationResultTr(XdrOperationType.LIQUIDITY_POOL_WITHDRAW);
      var liquidityPoolWithdrawResult = XdrLiquidityPoolWithdrawResult(
        XdrLiquidityPoolWithdrawResultCode.LIQUIDITY_POOL_WITHDRAW_SUCCESS,
      );
      original.liquidityPoolWithdrawResult = liquidityPoolWithdrawResult;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationResultTr.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationResultTr.decode(input);

      expect(decoded.discriminant.value, equals(XdrOperationType.LIQUIDITY_POOL_WITHDRAW.value));
      expect(decoded.liquidityPoolWithdrawResult, isNotNull);
    });

    test('XdrOperationResultTr INVOKE_HOST_FUNCTION encode/decode', () {
      var original = XdrOperationResultTr(XdrOperationType.INVOKE_HOST_FUNCTION);
      var invokeHostFunctionResult = XdrInvokeHostFunctionResult(
        XdrInvokeHostFunctionResultCode.INVOKE_HOST_FUNCTION_MALFORMED,
      );
      original.invokeHostFunctionResult = invokeHostFunctionResult;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationResultTr.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationResultTr.decode(input);

      expect(decoded.discriminant.value, equals(XdrOperationType.INVOKE_HOST_FUNCTION.value));
      expect(decoded.invokeHostFunctionResult, isNotNull);
    });

    test('XdrOperationResultTr EXTEND_FOOTPRINT_TTL encode/decode', () {
      var original = XdrOperationResultTr(XdrOperationType.EXTEND_FOOTPRINT_TTL);
      var bumpExpirationResult = XdrExtendFootprintTTLResult(
        XdrExtendFootprintTTLResultCode.EXTEND_FOOTPRINT_TTL_SUCCESS,
      );
      original.bumpExpirationResult = bumpExpirationResult;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationResultTr.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationResultTr.decode(input);

      expect(decoded.discriminant.value, equals(XdrOperationType.EXTEND_FOOTPRINT_TTL.value));
      expect(decoded.bumpExpirationResult, isNotNull);
    });

    test('XdrOperationResultTr RESTORE_FOOTPRINT encode/decode', () {
      var original = XdrOperationResultTr(XdrOperationType.RESTORE_FOOTPRINT);
      var restoreFootprintResult = XdrRestoreFootprintResult(
        XdrRestoreFootprintResultCode.RESTORE_FOOTPRINT_SUCCESS,
      );
      original.restoreFootprintResult = restoreFootprintResult;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationResultTr.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationResultTr.decode(input);

      expect(decoded.discriminant.value, equals(XdrOperationType.RESTORE_FOOTPRINT.value));
      expect(decoded.restoreFootprintResult, isNotNull);
    });
  });
}
