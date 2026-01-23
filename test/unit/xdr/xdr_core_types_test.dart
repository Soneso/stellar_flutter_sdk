// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('XDR Core Types - XdrMemo', () {
    test('XdrMemoType enum encode/decode round-trip', () {
      final types = [
        XdrMemoType.MEMO_NONE,
        XdrMemoType.MEMO_TEXT,
        XdrMemoType.MEMO_ID,
        XdrMemoType.MEMO_HASH,
        XdrMemoType.MEMO_RETURN,
      ];

      for (var type in types) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrMemoType.encode(output, type);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrMemoType.decode(input);

        expect(decoded.value, equals(type.value));
      }
    });

    test('XdrMemo MEMO_NONE encode/decode round-trip', () {
      var original = XdrMemo(XdrMemoType.MEMO_NONE);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrMemo.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrMemo.decode(input);

      expect(decoded.discriminant.value, equals(original.discriminant.value));
      expect(decoded.text, isNull);
      expect(decoded.id, isNull);
      expect(decoded.hash, isNull);
      expect(decoded.retHash, isNull);
    });

    test('XdrMemo MEMO_TEXT encode/decode round-trip', () {
      var original = XdrMemo(XdrMemoType.MEMO_TEXT);
      original.text = 'Test memo text';

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrMemo.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrMemo.decode(input);

      expect(decoded.discriminant.value, equals(original.discriminant.value));
      expect(decoded.text, equals(original.text));
    });

    test('XdrMemo MEMO_ID encode/decode round-trip', () {
      var original = XdrMemo(XdrMemoType.MEMO_ID);
      original.id = XdrUint64(BigInt.from(123456789));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrMemo.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrMemo.decode(input);

      expect(decoded.discriminant.value, equals(original.discriminant.value));
      expect(decoded.id!.uint64, equals(original.id!.uint64));
    });

    test('XdrMemo MEMO_HASH encode/decode round-trip', () {
      var original = XdrMemo(XdrMemoType.MEMO_HASH);
      original.hash = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xAB)));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrMemo.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrMemo.decode(input);

      expect(decoded.discriminant.value, equals(original.discriminant.value));
      expect(decoded.hash!.hash, equals(original.hash!.hash));
    });

    test('XdrMemo MEMO_RETURN encode/decode round-trip', () {
      var original = XdrMemo(XdrMemoType.MEMO_RETURN);
      original.retHash = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xCD)));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrMemo.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrMemo.decode(input);

      expect(decoded.discriminant.value, equals(original.discriminant.value));
      expect(decoded.retHash!.hash, equals(original.retHash!.hash));
    });

    test('XdrMemo MEMO_TEXT with empty string', () {
      var original = XdrMemo(XdrMemoType.MEMO_TEXT);
      original.text = '';

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrMemo.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrMemo.decode(input);

      expect(decoded.text, equals(''));
    });

    test('XdrMemo MEMO_ID with max uint64', () {
      var original = XdrMemo(XdrMemoType.MEMO_ID);
      original.id = XdrUint64(BigInt.parse('18446744073709551615'));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrMemo.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrMemo.decode(input);

      expect(decoded.id!.uint64, equals(original.id!.uint64));
    });
  });

  group('XDR Core Types - XdrAsset', () {
    test('XdrAssetType enum encode/decode round-trip', () {
      final types = [
        XdrAssetType.ASSET_TYPE_NATIVE,
        XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4,
        XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12,
        XdrAssetType.ASSET_TYPE_POOL_SHARE,
      ];

      for (var type in types) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrAssetType.encode(output, type);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrAssetType.decode(input);

        expect(decoded.value, equals(type.value));
      }
    });

    test('XdrAsset ASSET_TYPE_NATIVE encode/decode round-trip', () {
      var original = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrAsset.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrAsset.decode(input);

      expect(decoded.discriminant.value, equals(original.discriminant.value));
      expect(decoded.alphaNum4, isNull);
      expect(decoded.alphaNum12, isNull);
    });

    test('XdrAsset ASSET_TYPE_CREDIT_ALPHANUM4 encode/decode round-trip', () {
      var assetCode = Uint8List.fromList([0x55, 0x53, 0x44, 0x00]); // USD
      var issuerBytes = Uint8List.fromList(List<int>.filled(32, 0x12));
      var issuer = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      issuer.accountID.setEd25519(XdrUint256(issuerBytes));

      var original = XdrAsset(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4);
      original.alphaNum4 = XdrAssetAlphaNum4(assetCode, issuer);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrAsset.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrAsset.decode(input);

      expect(decoded.discriminant.value, equals(original.discriminant.value));
      expect(decoded.alphaNum4!.assetCode, equals(assetCode));
      expect(decoded.alphaNum4!.issuer.accountID.getEd25519()!.uint256, equals(issuerBytes));
    });

    test('XdrAsset ASSET_TYPE_CREDIT_ALPHANUM12 encode/decode round-trip', () {
      var assetCode = Uint8List.fromList([0x4C, 0x4F, 0x4E, 0x47, 0x41, 0x53, 0x53, 0x45, 0x54, 0x00, 0x00, 0x00]); // LONGASSET
      var issuerBytes = Uint8List.fromList(List<int>.filled(32, 0x34));
      var issuer = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      issuer.accountID.setEd25519(XdrUint256(issuerBytes));

      var original = XdrAsset(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12);
      original.alphaNum12 = XdrAssetAlphaNum12(assetCode, issuer);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrAsset.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrAsset.decode(input);

      expect(decoded.discriminant.value, equals(original.discriminant.value));
      expect(decoded.alphaNum12!.assetCode, equals(assetCode));
      expect(decoded.alphaNum12!.issuer.accountID.getEd25519()!.uint256, equals(issuerBytes));
    });

    test('XdrAssetAlphaNum4 with different asset codes', () {
      final assetCodes = [
        Uint8List.fromList([0x58, 0x4C, 0x4D, 0x00]), // XLM
        Uint8List.fromList([0x42, 0x54, 0x43, 0x00]), // BTC
        Uint8List.fromList([0x45, 0x54, 0x48, 0x00]), // ETH
      ];

      for (var assetCode in assetCodes) {
        var issuerBytes = Uint8List.fromList(List<int>.filled(32, 0x01));
        var issuer = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
        issuer.accountID.setEd25519(XdrUint256(issuerBytes));

        var original = XdrAssetAlphaNum4(assetCode, issuer);

        XdrDataOutputStream output = XdrDataOutputStream();
        XdrAssetAlphaNum4.encode(output, original);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrAssetAlphaNum4.decode(input);

        expect(decoded.assetCode, equals(assetCode));
      }
    });
  });

  group('XDR Core Types - XdrOperationType', () {
    test('XdrOperationType all enum values encode/decode', () {
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

    test('XdrOperationType value mapping verification', () {
      expect(XdrOperationType.CREATE_ACCOUNT.value, equals(0));
      expect(XdrOperationType.PAYMENT.value, equals(1));
      expect(XdrOperationType.PATH_PAYMENT_STRICT_RECEIVE.value, equals(2));
      expect(XdrOperationType.MANAGE_SELL_OFFER.value, equals(3));
      expect(XdrOperationType.CREATE_PASSIVE_SELL_OFFER.value, equals(4));
      expect(XdrOperationType.SET_OPTIONS.value, equals(5));
      expect(XdrOperationType.CHANGE_TRUST.value, equals(6));
      expect(XdrOperationType.ALLOW_TRUST.value, equals(7));
      expect(XdrOperationType.ACCOUNT_MERGE.value, equals(8));
      expect(XdrOperationType.INFLATION.value, equals(9));
      expect(XdrOperationType.MANAGE_DATA.value, equals(10));
      expect(XdrOperationType.BUMP_SEQUENCE.value, equals(11));
      expect(XdrOperationType.MANAGE_BUY_OFFER.value, equals(12));
      expect(XdrOperationType.PATH_PAYMENT_STRICT_SEND.value, equals(13));
      expect(XdrOperationType.CREATE_CLAIMABLE_BALANCE.value, equals(14));
      expect(XdrOperationType.CLAIM_CLAIMABLE_BALANCE.value, equals(15));
      expect(XdrOperationType.BEGIN_SPONSORING_FUTURE_RESERVES.value, equals(16));
      expect(XdrOperationType.END_SPONSORING_FUTURE_RESERVES.value, equals(17));
      expect(XdrOperationType.REVOKE_SPONSORSHIP.value, equals(18));
      expect(XdrOperationType.CLAWBACK.value, equals(19));
      expect(XdrOperationType.CLAWBACK_CLAIMABLE_BALANCE.value, equals(20));
      expect(XdrOperationType.SET_TRUST_LINE_FLAGS.value, equals(21));
      expect(XdrOperationType.LIQUIDITY_POOL_DEPOSIT.value, equals(22));
      expect(XdrOperationType.LIQUIDITY_POOL_WITHDRAW.value, equals(23));
      expect(XdrOperationType.INVOKE_HOST_FUNCTION.value, equals(24));
      expect(XdrOperationType.EXTEND_FOOTPRINT_TTL.value, equals(25));
      expect(XdrOperationType.RESTORE_FOOTPRINT.value, equals(26));
    });

    test('XdrOperationType decode invalid value throws exception', () {
      XdrDataOutputStream output = XdrDataOutputStream();
      output.writeInt(999);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      expect(() => XdrOperationType.decode(input), throwsException);
    });
  });

  group('XDR Core Types - XdrTransaction', () {
    test('XdrTransaction minimal encode/decode round-trip', () {
      var sourceAccount = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      sourceAccount.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x01)));

      var fee = XdrUint32(100);
      var seqNum = XdrSequenceNumber(XdrBigInt64(BigInt.from(123456)));
      var cond = XdrPreconditions(XdrPreconditionType.NONE);
      var memo = XdrMemo(XdrMemoType.MEMO_NONE);
      var operations = <XdrOperation>[];
      var ext = XdrTransactionExt(0);

      var original = XdrTransaction(sourceAccount, fee, seqNum, cond, memo, operations, ext);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransaction.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransaction.decode(input);

      expect(decoded.sourceAccount.discriminant.value, equals(original.sourceAccount.discriminant.value));
      expect(decoded.fee.uint32, equals(original.fee.uint32));
      expect(decoded.seqNum.sequenceNumber.bigInt, equals(original.seqNum.sequenceNumber.bigInt));
      expect(decoded.preconditions.discriminant.value, equals(original.preconditions.discriminant.value));
      expect(decoded.memo.discriminant.value, equals(original.memo.discriminant.value));
      expect(decoded.operations.length, equals(0));
      expect(decoded.ext.discriminant, equals(0));
    });

    test('XdrTransaction with memo text', () {
      var sourceAccount = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      sourceAccount.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x02)));

      var fee = XdrUint32(1000);
      var seqNum = XdrSequenceNumber(XdrBigInt64(BigInt.from(999999)));
      var cond = XdrPreconditions(XdrPreconditionType.NONE);

      var memo = XdrMemo(XdrMemoType.MEMO_TEXT);
      memo.text = 'Payment for invoice 123';

      var operations = <XdrOperation>[];
      var ext = XdrTransactionExt(0);

      var original = XdrTransaction(sourceAccount, fee, seqNum, cond, memo, operations, ext);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransaction.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransaction.decode(input);

      expect(decoded.memo.discriminant.value, equals(XdrMemoType.MEMO_TEXT.value));
      expect(decoded.memo.text, equals('Payment for invoice 123'));
    });

    test('XdrTransaction with different fee values', () {
      final fees = [1, 100, 1000, 10000, 100000];

      for (var feeValue in fees) {
        var sourceAccount = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
        sourceAccount.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x01)));

        var fee = XdrUint32(feeValue);
        var seqNum = XdrSequenceNumber(XdrBigInt64(BigInt.from(1)));
        var cond = XdrPreconditions(XdrPreconditionType.NONE);
        var memo = XdrMemo(XdrMemoType.MEMO_NONE);
        var operations = <XdrOperation>[];
        var ext = XdrTransactionExt(0);

        var original = XdrTransaction(sourceAccount, fee, seqNum, cond, memo, operations, ext);

        XdrDataOutputStream output = XdrDataOutputStream();
        XdrTransaction.encode(output, original);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrTransaction.decode(input);

        expect(decoded.fee.uint32, equals(feeValue));
      }
    });

    test('XdrTransaction with large sequence number', () {
      var sourceAccount = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      sourceAccount.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x01)));

      var fee = XdrUint32(100);
      var seqNum = XdrSequenceNumber(XdrBigInt64(BigInt.parse('9223372036854775807')));
      var cond = XdrPreconditions(XdrPreconditionType.NONE);
      var memo = XdrMemo(XdrMemoType.MEMO_NONE);
      var operations = <XdrOperation>[];
      var ext = XdrTransactionExt(0);

      var original = XdrTransaction(sourceAccount, fee, seqNum, cond, memo, operations, ext);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransaction.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransaction.decode(input);

      expect(decoded.seqNum.sequenceNumber.bigInt, equals(BigInt.parse('9223372036854775807')));
    });

    test('XdrTransactionExt discriminant 0', () {
      var original = XdrTransactionExt(0);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionExt.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionExt.decode(input);

      expect(decoded.discriminant, equals(0));
      expect(decoded.sorobanTransactionData, isNull);
    });
  });

  group('XDR Core Types - XdrMuxedAccount', () {
    test('XdrMuxedAccount KEY_TYPE_ED25519 encode/decode round-trip', () {
      var original = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      original.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAB)));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrMuxedAccount.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrMuxedAccount.decode(input);

      expect(decoded.discriminant.value, equals(original.discriminant.value));
      expect(decoded.ed25519!.uint256, equals(original.ed25519!.uint256));
    });

    test('XdrMuxedAccount KEY_TYPE_MUXED_ED25519 encode/decode round-trip', () {
      var original = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_MUXED_ED25519);
      var med25519 = XdrMuxedAccountMed25519(
        XdrUint64(BigInt.from(12345)),
        XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xCD)))
      );
      original.med25519 = med25519;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrMuxedAccount.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrMuxedAccount.decode(input);

      expect(decoded.discriminant.value, equals(original.discriminant.value));
      expect(decoded.med25519!.id.uint64, equals(med25519.id.uint64));
      expect(decoded.med25519!.ed25519.uint256, equals(med25519.ed25519.uint256));
    });

    test('XdrMuxedAccountMed25519 with max uint64 id', () {
      var original = XdrMuxedAccountMed25519(
        XdrUint64(BigInt.parse('18446744073709551615')),
        XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xFF)))
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrMuxedAccountMed25519.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrMuxedAccountMed25519.decode(input);

      expect(decoded.id.uint64, equals(BigInt.parse('18446744073709551615')));
      expect(decoded.ed25519.uint256, equals(original.ed25519.uint256));
    });
  });

  group('XDR Core Types - XdrSequenceNumber', () {
    test('XdrSequenceNumber encode/decode round-trip', () {
      var original = XdrSequenceNumber(XdrBigInt64(BigInt.from(123456789)));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSequenceNumber.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSequenceNumber.decode(input);

      expect(decoded.sequenceNumber.bigInt, equals(original.sequenceNumber.bigInt));
    });

    test('XdrSequenceNumber with zero', () {
      var original = XdrSequenceNumber(XdrBigInt64(BigInt.zero));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSequenceNumber.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSequenceNumber.decode(input);

      expect(decoded.sequenceNumber.bigInt, equals(BigInt.zero));
    });

    test('XdrSequenceNumber with max value', () {
      var original = XdrSequenceNumber(XdrBigInt64(BigInt.parse('18446744073709551615')));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSequenceNumber.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSequenceNumber.decode(input);

      expect(decoded.sequenceNumber.bigInt, equals(BigInt.parse('18446744073709551615')));
    });
  });

  group('XDR Core Types - XdrAccountID', () {
    test('XdrAccountID encode/decode round-trip', () {
      var publicKey = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      publicKey.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x42))));
      var original = XdrAccountID(publicKey);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrAccountID.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrAccountID.decode(input);

      expect(decoded.accountID.getDiscriminant().value, equals(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519.value));
      expect(decoded.accountID.getEd25519()!.uint256, equals(original.accountID.getEd25519()!.uint256));
    });
  });

  group('XDR Core Types - Additional Base Types', () {
    test('XdrUint32 encode/decode round-trip', () {
      final values = [0, 1, 100, 1000, 2147483647];

      for (var value in values) {
        var original = XdrUint32(value);

        XdrDataOutputStream output = XdrDataOutputStream();
        XdrUint32.encode(output, original);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrUint32.decode(input);

        expect(decoded.uint32, equals(value));
      }
    });

    test('XdrUint64 encode/decode round-trip', () {
      final values = [
        BigInt.zero,
        BigInt.from(1),
        BigInt.from(1000000),
        BigInt.parse('9223372036854775807'),
        BigInt.parse('18446744073709551615'),
      ];

      for (var value in values) {
        var original = XdrUint64(value);

        XdrDataOutputStream output = XdrDataOutputStream();
        XdrUint64.encode(output, original);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrUint64.decode(input);

        expect(decoded.uint64, equals(value));
      }
    });

    test('XdrInt64 encode/decode round-trip', () {
      final values = [
        BigInt.zero,
        BigInt.from(1),
        BigInt.from(-1),
        BigInt.parse('9223372036854775807'),
        BigInt.parse('-9223372036854775808'),
      ];

      for (var value in values) {
        var original = XdrInt64(value);

        XdrDataOutputStream output = XdrDataOutputStream();
        XdrInt64.encode(output, original);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrInt64.decode(input);

        expect(decoded.int64, equals(value));
      }
    });

    test('XdrHash encode/decode round-trip', () {
      var hashBytes = Uint8List.fromList(List.generate(32, (i) => i * 7 % 256));
      var original = XdrHash(hashBytes);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrHash.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrHash.decode(input);

      expect(decoded.hash, equals(hashBytes));
    });

    test('XdrString32 encode/decode round-trip', () {
      final strings = ['', 'test', 'Hello World', 'Short string for testing'];

      for (var str in strings) {
        var original = XdrString32(str);

        XdrDataOutputStream output = XdrDataOutputStream();
        XdrString32.encode(output, original);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrString32.decode(input);

        expect(decoded.string32, equals(str));
      }
    });

    test('XdrUint256 encode/decode round-trip', () {
      var bytes = Uint8List.fromList(List.generate(32, (i) => (i * 3) % 256));
      var original = XdrUint256(bytes);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrUint256.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrUint256.decode(input);

      expect(decoded.uint256, equals(bytes));
    });
  });

  group('XDR Core Types - XdrCryptoKeyType', () {
    test('XdrCryptoKeyType enum values', () {
      expect(XdrCryptoKeyType.KEY_TYPE_ED25519.value, equals(0));
      expect(XdrCryptoKeyType.KEY_TYPE_PRE_AUTH_TX.value, equals(1));
      expect(XdrCryptoKeyType.KEY_TYPE_HASH_X.value, equals(2));
      expect(XdrCryptoKeyType.KEY_TYPE_MUXED_ED25519.value, equals(256));
    });

    test('XdrCryptoKeyType encode/decode round-trip', () {
      final types = [
        XdrCryptoKeyType.KEY_TYPE_ED25519,
        XdrCryptoKeyType.KEY_TYPE_PRE_AUTH_TX,
        XdrCryptoKeyType.KEY_TYPE_HASH_X,
        XdrCryptoKeyType.KEY_TYPE_MUXED_ED25519,
      ];

      for (var type in types) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrCryptoKeyType.encode(output, type);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrCryptoKeyType.decode(input);

        expect(decoded.value, equals(type.value));
      }
    });
  });

  group('XDR Core Types - XdrPreconditions', () {
    test('XdrPreconditions NONE encode/decode round-trip', () {
      var original = XdrPreconditions(XdrPreconditionType.NONE);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrPreconditions.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrPreconditions.decode(input);

      expect(decoded.discriminant.value, equals(original.discriminant.value));
      expect(decoded.timeBounds, isNull);
      expect(decoded.v2, isNull);
    });

    test('XdrPreconditionType enum values', () {
      expect(XdrPreconditionType.NONE.value, equals(0));
      expect(XdrPreconditionType.TIME.value, equals(1));
      expect(XdrPreconditionType.V2.value, equals(2));
    });
  });

  group('XDR Core Types - Complex Scenarios', () {
    test('Multiple XdrMemo types in sequence', () {
      var memos = [
        XdrMemo(XdrMemoType.MEMO_NONE),
        () {
          var m = XdrMemo(XdrMemoType.MEMO_TEXT);
          m.text = 'Test';
          return m;
        }(),
        () {
          var m = XdrMemo(XdrMemoType.MEMO_ID);
          m.id = XdrUint64(BigInt.from(999));
          return m;
        }(),
      ];

      XdrDataOutputStream output = XdrDataOutputStream();
      for (var memo in memos) {
        XdrMemo.encode(output, memo);
      }
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      for (var originalMemo in memos) {
        var decoded = XdrMemo.decode(input);
        expect(decoded.discriminant.value, equals(originalMemo.discriminant.value));
      }
    });

    test('XdrTransaction with all memo types', () {
      final memoTypes = [
        XdrMemoType.MEMO_NONE,
        XdrMemoType.MEMO_TEXT,
        XdrMemoType.MEMO_ID,
        XdrMemoType.MEMO_HASH,
        XdrMemoType.MEMO_RETURN,
      ];

      for (var memoType in memoTypes) {
        var sourceAccount = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
        sourceAccount.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x01)));

        var memo = XdrMemo(memoType);
        switch (memoType) {
          case XdrMemoType.MEMO_TEXT:
            memo.text = 'Test memo';
            break;
          case XdrMemoType.MEMO_ID:
            memo.id = XdrUint64(BigInt.from(12345));
            break;
          case XdrMemoType.MEMO_HASH:
            memo.hash = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xAA)));
            break;
          case XdrMemoType.MEMO_RETURN:
            memo.retHash = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xBB)));
            break;
          default:
            break;
        }

        var tx = XdrTransaction(
          sourceAccount,
          XdrUint32(100),
          XdrSequenceNumber(XdrBigInt64(BigInt.from(1))),
          XdrPreconditions(XdrPreconditionType.NONE),
          memo,
          [],
          XdrTransactionExt(0),
        );

        XdrDataOutputStream output = XdrDataOutputStream();
        XdrTransaction.encode(output, tx);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrTransaction.decode(input);

        expect(decoded.memo.discriminant.value, equals(memoType.value));
      }
    });
  });
}
