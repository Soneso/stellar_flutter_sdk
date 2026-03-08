// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  // Tests that go beyond simple roundtrip encode/decode (which is covered by
  // auto-generated tests in test/unit/xdr/generated/).

  group('XdrMuxedAccountMed25519 special methods', () {
    test('encodeInverted/decodeInverted', () {
      var original = XdrMuxedAccountMed25519(
        XdrUint64(BigInt.from(77777)),
        XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAA))),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrMuxedAccountMed25519.encodeInverted(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrMuxedAccountMed25519.decodeInverted(input);

      expect(decoded.id.uint64, equals(BigInt.from(77777)));
      expect(decoded.ed25519.uint256, equals(original.ed25519.uint256));
    });

    test('accountId getter returns M-address', () {
      var med25519 = XdrMuxedAccountMed25519(
        XdrUint64(BigInt.from(12345)),
        XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xBB))),
      );

      var accountId = med25519.accountId;
      expect(accountId, isNotNull);
      expect(accountId, isA<String>());
      expect(accountId.startsWith('M'), true);
    });
  });

  group('XdrAccountID factory method', () {
    test('forAccountId static method', () {
      var accountId = 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H';
      var xdrAccountId = XdrAccountID.forAccountId(accountId);

      expect(xdrAccountId, isNotNull);
      expect(xdrAccountId.accountID, isNotNull);
    });
  });

  group('XdrAccountEntry edge cases', () {
    test('with null inflationDest roundtrip', () {
      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x55))));
      var accountID = XdrAccountID(pk);

      var original = XdrAccountEntry(
        accountID,
        XdrInt64(BigInt.from(10000000000)),
        XdrSequenceNumber(BigInt.from(123456)),
        XdrUint32(5),
        null,
        XdrUint32(0),
        XdrString32('test'),
        XdrThresholds(Uint8List.fromList([1, 2, 3, 4])),
        [],
        XdrAccountEntryExt(0),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrAccountEntry.encode(output, original);
      var decoded = XdrAccountEntry.decode(
        XdrDataInputStream(Uint8List.fromList(output.bytes)));

      expect(decoded.inflationDest, isNull);
    });

    test('with non-null inflationDest roundtrip', () {
      var pk1 = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk1.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x66))));

      var pk2 = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk2.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x77))));

      var original = XdrAccountEntry(
        XdrAccountID(pk1),
        XdrInt64(BigInt.from(5000000000)),
        XdrSequenceNumber(BigInt.from(999999)),
        XdrUint32(0),
        XdrAccountID(pk2),
        XdrUint32(0),
        XdrString32(''),
        XdrThresholds(Uint8List.fromList([1, 1, 1, 1])),
        [],
        XdrAccountEntryExt(0),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrAccountEntry.encode(output, original);
      var decoded = XdrAccountEntry.decode(
        XdrDataInputStream(Uint8List.fromList(output.bytes)));

      expect(decoded.inflationDest, isNotNull);
    });

    test('with multiple signers', () {
      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x88))));

      var signerKey1 = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519);
      signerKey1.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x99)));
      var signer1 = XdrSigner(signerKey1, XdrUint32(10));

      var signerKey2 = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_HASH_X);
      signerKey2.hashX = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAA)));
      var signer2 = XdrSigner(signerKey2, XdrUint32(5));

      var original = XdrAccountEntry(
        XdrAccountID(pk),
        XdrInt64(BigInt.from(20000000000)),
        XdrSequenceNumber(BigInt.from(555555)),
        XdrUint32(2),
        null,
        XdrUint32(1),
        XdrString32('testdomain12'),
        XdrThresholds(Uint8List.fromList([1, 2, 3, 4])),
        [signer1, signer2],
        XdrAccountEntryExt(0),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrAccountEntry.encode(output, original);
      var decoded = XdrAccountEntry.decode(
        XdrDataInputStream(Uint8List.fromList(output.bytes)));

      expect(decoded.signers.length, equals(2));
      expect(decoded.signers[0].weight.uint32, equals(10));
      expect(decoded.signers[1].weight.uint32, equals(5));
    });

    test('with empty string homeDomain', () {
      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xDD))));

      var original = XdrAccountEntry(
        XdrAccountID(pk),
        XdrInt64(BigInt.from(1)),
        XdrSequenceNumber(BigInt.from(1)),
        XdrUint32(0),
        null,
        XdrUint32(0),
        XdrString32(''),
        XdrThresholds(Uint8List.fromList([0, 0, 0, 0])),
        [],
        XdrAccountEntryExt(0),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrAccountEntry.encode(output, original);
      var decoded = XdrAccountEntry.decode(
        XdrDataInputStream(Uint8List.fromList(output.bytes)));

      expect(decoded.homeDomain.string32, equals(''));
    });

    test('with max int64 balance and seqNum', () {
      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x15))));

      var original = XdrAccountEntry(
        XdrAccountID(pk),
        XdrInt64(BigInt.parse('9223372036854775807')),
        XdrSequenceNumber(BigInt.parse('9223372036854775807')),
        XdrUint32(999999),
        null,
        XdrUint32(15),
        XdrString32('verylongdomain1234567890'),
        XdrThresholds(Uint8List.fromList([255, 255, 255, 255])),
        [],
        XdrAccountEntryExt(0),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrAccountEntry.encode(output, original);
      var decoded = XdrAccountEntry.decode(
        XdrDataInputStream(Uint8List.fromList(output.bytes)));

      expect(decoded.balance.int64, equals(BigInt.parse('9223372036854775807')));
      expect(decoded.seqNum.sequenceNumber, equals(BigInt.parse('9223372036854775807')));
    });

    test('full extension chain v1 -> v2 -> v3', () {
      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x13))));

      var v3 = XdrAccountEntryV3(XdrExtensionPoint(0), XdrUint32(500), XdrUint64(BigInt.from(9999999)));
      var v2Ext = XdrAccountEntryV2Ext(3);
      v2Ext.v3 = v3;
      var v2 = XdrAccountEntryV2(XdrUint32(7), XdrUint32(4), [], v2Ext);
      var v1Ext = XdrAccountEntryV1Ext(2);
      v1Ext.v2 = v2;
      var v1 = XdrAccountEntryV1(
        XdrLiabilities(XdrInt64(BigInt.from(500000)), XdrInt64(BigInt.from(300000))),
        v1Ext);
      var ext = XdrAccountEntryExt(1);
      ext.v1 = v1;

      var original = XdrAccountEntry(
        XdrAccountID(pk),
        XdrInt64(BigInt.from(50000000000)),
        XdrSequenceNumber(BigInt.from(12345)),
        XdrUint32(15),
        null,
        XdrUint32(1),
        XdrString32('testdomain12345678901234'),
        XdrThresholds(Uint8List.fromList([5, 10, 15, 20])),
        [],
        ext,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrAccountEntry.encode(output, original);
      var decoded = XdrAccountEntry.decode(
        XdrDataInputStream(Uint8List.fromList(output.bytes)));

      expect(decoded.ext.discriminant, equals(1));
      expect(decoded.ext.v1, isNotNull);
      expect(decoded.ext.v1!.ext.discriminant, equals(2));
      expect(decoded.ext.v1!.ext.v2, isNotNull);
      expect(decoded.ext.v1!.ext.v2!.ext.discriminant, equals(3));
      expect(decoded.ext.v1!.ext.v2!.ext.v3, isNotNull);
      expect(decoded.ext.v1!.ext.v2!.ext.v3!.seqLedger.uint32, equals(500));
      expect(decoded.ext.v1!.ext.v2!.ext.v3!.seqTime.uint64, equals(BigInt.from(9999999)));
    });
  });

  group('XdrAccountEntryV1 edge cases', () {
    test('with max int64 liabilities', () {
      var liabilities = XdrLiabilities(
        XdrInt64(BigInt.parse('9223372036854775807')),
        XdrInt64(BigInt.parse('9223372036854775807')),
      );
      var original = XdrAccountEntryV1(liabilities, XdrAccountEntryV1Ext(0));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrAccountEntryV1.encode(output, original);
      var decoded = XdrAccountEntryV1.decode(
        XdrDataInputStream(Uint8List.fromList(output.bytes)));

      expect(decoded.liabilities.buying.int64, equals(BigInt.parse('9223372036854775807')));
      expect(decoded.liabilities.selling.int64, equals(BigInt.parse('9223372036854775807')));
    });
  });

  group('XdrAccountMergeResult edge cases', () {
    test('SUCCESS with zero balance', () {
      var original = XdrAccountMergeResult(XdrAccountMergeResultCode.ACCOUNT_MERGE_SUCCESS);
      original.sourceAccountBalance = XdrInt64(BigInt.zero);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrAccountMergeResult.encode(output, original);
      var decoded = XdrAccountMergeResult.decode(
        XdrDataInputStream(Uint8List.fromList(output.bytes)));

      expect(decoded.sourceAccountBalance!.int64, equals(BigInt.zero));
    });
  });

  group('XdrSetOptionsOp optional field combinations', () {
    test('with all fields null', () {
      var original = XdrSetOptionsOp(null, null, null, null, null, null, null, null, null);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSetOptionsOp.encode(output, original);
      var decoded = XdrSetOptionsOp.decode(
        XdrDataInputStream(Uint8List.fromList(output.bytes)));

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

    test('with all fields non-null', () {
      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x55))));

      var signerKey = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519);
      signerKey.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x66)));

      var original = XdrSetOptionsOp(null, null, null, null, null, null, null, null, null);
      original.inflationDest = XdrAccountID(pk);
      original.clearFlags = XdrUint32(1);
      original.setFlags = XdrUint32(2);
      original.masterWeight = XdrUint32(100);
      original.lowThreshold = XdrUint32(10);
      original.medThreshold = XdrUint32(20);
      original.highThreshold = XdrUint32(30);
      original.homeDomain = XdrString32('example.org');
      original.signer = XdrSigner(signerKey, XdrUint32(50));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSetOptionsOp.encode(output, original);
      var decoded = XdrSetOptionsOp.decode(
        XdrDataInputStream(Uint8List.fromList(output.bytes)));

      expect(decoded.inflationDest, isNotNull);
      expect(decoded.clearFlags!.uint32, equals(1));
      expect(decoded.setFlags!.uint32, equals(2));
      expect(decoded.masterWeight!.uint32, equals(100));
      expect(decoded.lowThreshold!.uint32, equals(10));
      expect(decoded.medThreshold!.uint32, equals(20));
      expect(decoded.highThreshold!.uint32, equals(30));
      expect(decoded.homeDomain!.string32, equals('example.org'));
      expect(decoded.signer!.weight.uint32, equals(50));
    });

    test('with partial optional fields', () {
      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x11))));

      var original = XdrSetOptionsOp(null, null, null, null, null, null, null, null, null);
      original.inflationDest = XdrAccountID(pk);
      original.clearFlags = XdrUint32(2);
      original.lowThreshold = XdrUint32(5);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSetOptionsOp.encode(output, original);
      var decoded = XdrSetOptionsOp.decode(
        XdrDataInputStream(Uint8List.fromList(output.bytes)));

      expect(decoded.inflationDest, isNotNull);
      expect(decoded.clearFlags!.uint32, equals(2));
      expect(decoded.setFlags, isNull);
      expect(decoded.masterWeight, isNull);
      expect(decoded.lowThreshold!.uint32, equals(5));
      expect(decoded.medThreshold, isNull);
      expect(decoded.highThreshold, isNull);
      expect(decoded.homeDomain, isNull);
      expect(decoded.signer, isNull);
    });
  });

  group('XdrManageDataOp optional field', () {
    test('with null dataValue (delete)', () {
      var original = XdrManageDataOp(XdrString64('testkey'), null);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrManageDataOp.encode(output, original);
      var decoded = XdrManageDataOp.decode(
        XdrDataInputStream(Uint8List.fromList(output.bytes)));

      expect(decoded.dataName.string64, equals('testkey'));
      expect(decoded.dataValue, isNull);
    });
  });

  group('XdrInflationResult edge cases', () {
    test('SUCCESS with multiple payouts', () {
      var pk1 = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk1.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xBB))));
      var pk2 = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk2.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xCC))));

      var original = XdrInflationResult(XdrInflationResultCode.INFLATION_SUCCESS);
      original.payouts = [
        XdrInflationPayout(XdrAccountID(pk1), XdrInt64(BigInt.from(1000000))),
        XdrInflationPayout(XdrAccountID(pk2), XdrInt64(BigInt.from(2000000))),
      ];

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrInflationResult.encode(output, original);
      var decoded = XdrInflationResult.decode(
        XdrDataInputStream(Uint8List.fromList(output.bytes)));

      expect(decoded.payouts!.length, equals(2));
      expect(decoded.payouts![0].amount.int64, equals(BigInt.from(1000000)));
      expect(decoded.payouts![1].amount.int64, equals(BigInt.from(2000000)));
    });

    test('NOT_TIME has null payouts', () {
      var original = XdrInflationResult(XdrInflationResultCode.INFLATION_NOT_TIME);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrInflationResult.encode(output, original);
      var decoded = XdrInflationResult.decode(
        XdrDataInputStream(Uint8List.fromList(output.bytes)));

      expect(decoded.payouts, isNull);
    });
  });

  group('XdrCreateClaimableBalanceOp edge cases', () {
    test('with empty claimants list', () {
      var asset = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var original = XdrCreateClaimableBalanceOp(asset, XdrInt64(BigInt.from(100)), []);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrCreateClaimableBalanceOp.encode(output, original);
      var decoded = XdrCreateClaimableBalanceOp.decode(
        XdrDataInputStream(Uint8List.fromList(output.bytes)));

      expect(decoded.claimants, isEmpty);
    });

    test('with multiple claimants', () {
      var asset = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);

      var pk1 = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk1.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x66))));
      var claimant1 = XdrClaimant(XdrClaimantType.CLAIMANT_TYPE_V0);
      claimant1.v0 = XdrClaimantV0(XdrAccountID(pk1),
        XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_UNCONDITIONAL));

      var pk2 = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk2.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x77))));
      var claimant2 = XdrClaimant(XdrClaimantType.CLAIMANT_TYPE_V0);
      claimant2.v0 = XdrClaimantV0(XdrAccountID(pk2),
        XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_UNCONDITIONAL));

      var original = XdrCreateClaimableBalanceOp(asset, XdrInt64(BigInt.from(1000000)), [claimant1, claimant2]);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrCreateClaimableBalanceOp.encode(output, original);
      var decoded = XdrCreateClaimableBalanceOp.decode(
        XdrDataInputStream(Uint8List.fromList(output.bytes)));

      expect(decoded.claimants.length, equals(2));
    });
  });

  group('XdrMuxedAccountMed25519 setters', () {
    test('should set id', () {
      final muxedAccount = XdrMuxedAccountMed25519(
        XdrUint64(BigInt.from(100)),
        XdrUint256(Uint8List(32)),
      );

      muxedAccount.id = XdrUint64(BigInt.from(200));
      expect(muxedAccount.id.uint64, equals(BigInt.from(200)));
    });

    test('should set ed25519', () {
      final muxedAccount = XdrMuxedAccountMed25519(
        XdrUint64(BigInt.from(100)),
        XdrUint256(Uint8List(32)),
      );

      final newEd25519 = XdrUint256(Uint8List.fromList(List.filled(32, 1)));
      muxedAccount.ed25519 = newEd25519;
      expect(muxedAccount.ed25519, equals(newEd25519));
    });
  });

  group('XdrMuxedAccount discriminant setter', () {
    test('should set discriminant', () {
      final muxedAccount = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      muxedAccount.ed25519 = XdrUint256(Uint8List(32));

      muxedAccount.discriminant = XdrCryptoKeyType.KEY_TYPE_MUXED_ED25519;
      expect(muxedAccount.discriminant, equals(XdrCryptoKeyType.KEY_TYPE_MUXED_ED25519));
    });

    test('should set ed25519', () {
      final muxedAccount = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);

      final ed25519 = XdrUint256(Uint8List.fromList(List.filled(32, 1)));
      muxedAccount.ed25519 = ed25519;
      expect(muxedAccount.ed25519, equals(ed25519));
    });

    test('should set med25519', () {
      final muxedAccount = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_MUXED_ED25519);

      final med25519 = XdrMuxedAccountMed25519(
        XdrUint64(BigInt.from(100)),
        XdrUint256(Uint8List(32)),
      );
      muxedAccount.med25519 = med25519;
      expect(muxedAccount.med25519, equals(med25519));
    });
  });

  group('XdrSigner setters', () {
    test('should set key', () {
      final signer = XdrSigner(
        XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519),
        XdrUint32(1),
      );

      final newKey = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_PRE_AUTH_TX);
      signer.key = newKey;
      expect(signer.key.discriminant, equals(XdrSignerKeyType.SIGNER_KEY_TYPE_PRE_AUTH_TX));
    });

    test('should set weight', () {
      final signer = XdrSigner(
        XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519),
        XdrUint32(1),
      );

      signer.weight = XdrUint32(5);
      expect(signer.weight.uint32, equals(5));
    });
  });
}
