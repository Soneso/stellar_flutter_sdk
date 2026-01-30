// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('XDR Account Types - Deep Branch Testing', () {
    test('XdrMuxedAccount KEY_TYPE_ED25519 encode/decode', () {
      var original = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      original.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x11)));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrMuxedAccount.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrMuxedAccount.decode(input);

      expect(decoded.discriminant.value, equals(XdrCryptoKeyType.KEY_TYPE_ED25519.value));
      expect(decoded.ed25519, isNotNull);
      expect(decoded.ed25519!.uint256, equals(original.ed25519!.uint256));
    });

    test('XdrMuxedAccount KEY_TYPE_MUXED_ED25519 encode/decode', () {
      var med25519 = XdrMuxedAccountMed25519(
        XdrUint64(BigInt.from(12345)),
        XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x22))),
      );

      var original = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_MUXED_ED25519);
      original.med25519 = med25519;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrMuxedAccount.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrMuxedAccount.decode(input);

      expect(decoded.discriminant.value, equals(XdrCryptoKeyType.KEY_TYPE_MUXED_ED25519.value));
      expect(decoded.med25519, isNotNull);
      expect(decoded.med25519!.id.uint64, equals(BigInt.from(12345)));
    });

    test('XdrMuxedAccountMed25519 encode/decode round-trip', () {
      var original = XdrMuxedAccountMed25519(
        XdrUint64(BigInt.from(99999)),
        XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x33))),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrMuxedAccountMed25519.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrMuxedAccountMed25519.decode(input);

      expect(decoded.id.uint64, equals(BigInt.from(99999)));
      expect(decoded.ed25519.uint256, equals(original.ed25519.uint256));
    });

    test('XdrMuxedAccountMed25519 encodeInverted/decodeInverted', () {
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

    test('XdrMuxedAccountMed25519 accountId getter', () {
      var med25519 = XdrMuxedAccountMed25519(
        XdrUint64(BigInt.from(12345)),
        XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xBB))),
      );

      var accountId = med25519.accountId;
      expect(accountId, isNotNull);
      expect(accountId, isA<String>());
      expect(accountId.startsWith('M'), true);
    });

    test('XdrAccountID encode/decode round-trip', () {
      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x44))));

      var original = XdrAccountID(pk);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrAccountID.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrAccountID.decode(input);

      expect(decoded.accountID.getDiscriminant().value, equals(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519.value));
      expect(decoded.accountID.getEd25519()!.uint256, equals(pk.getEd25519()!.uint256));
    });

    test('XdrAccountID forAccountId static method', () {
      var accountId = 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H';
      var xdrAccountId = XdrAccountID.forAccountId(accountId);

      expect(xdrAccountId, isNotNull);
      expect(xdrAccountId.accountID, isNotNull);
    });

    test('XdrAccountEntry encode/decode round-trip', () {
      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x55))));
      var accountID = XdrAccountID(pk);

      var thresholds = XdrThresholds(Uint8List.fromList([1, 2, 3, 4]));
      var homeDomain = XdrString32('test');
      var ext = XdrAccountEntryExt(0);

      var original = XdrAccountEntry(
        accountID,
        XdrInt64(BigInt.from(10000000000)),
        XdrSequenceNumber(XdrBigInt64(BigInt.from(123456))),
        XdrUint32(5),
        null,
        XdrUint32(0),
        homeDomain,
        thresholds,
        [],
        ext,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrAccountEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrAccountEntry.decode(input);

      expect(decoded.balance.int64, equals(BigInt.from(10000000000)));
      expect(decoded.seqNum.sequenceNumber.bigInt, equals(BigInt.from(123456)));
      expect(decoded.numSubEntries.uint32, equals(5));
      expect(decoded.inflationDest, isNull);
      expect(decoded.flags.uint32, equals(0));
      expect(decoded.homeDomain.string32, equals('test'));
    });

    test('XdrAccountEntry with inflationDest encode/decode', () {
      var pk1 = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk1.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x66))));
      var accountID = XdrAccountID(pk1);

      var pk2 = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk2.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x77))));
      var inflationDest = XdrAccountID(pk2);

      var thresholds = XdrThresholds(Uint8List.fromList([1, 1, 1, 1]));
      var homeDomain = XdrString32('');
      var ext = XdrAccountEntryExt(0);

      var original = XdrAccountEntry(
        accountID,
        XdrInt64(BigInt.from(5000000000)),
        XdrSequenceNumber(XdrBigInt64(BigInt.from(999999))),
        XdrUint32(0),
        inflationDest,
        XdrUint32(0),
        homeDomain,
        thresholds,
        [],
        ext,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrAccountEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrAccountEntry.decode(input);

      expect(decoded.inflationDest, isNotNull);
      expect(decoded.inflationDest!.accountID.getEd25519()!.uint256, equals(pk2.getEd25519()!.uint256));
    });

    test('XdrAccountEntry with multiple signers encode/decode', () {
      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x88))));
      var accountID = XdrAccountID(pk);

      var signerKey1 = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519);
      signerKey1.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x99)));
      var signer1 = XdrSigner(signerKey1, XdrUint32(10));

      var signerKey2 = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_HASH_X);
      signerKey2.hashX = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAA)));
      var signer2 = XdrSigner(signerKey2, XdrUint32(5));

      var thresholds = XdrThresholds(Uint8List.fromList([1, 2, 3, 4]));
      var homeDomain = XdrString32('testdomain12');
      var ext = XdrAccountEntryExt(0);

      var original = XdrAccountEntry(
        accountID,
        XdrInt64(BigInt.from(20000000000)),
        XdrSequenceNumber(XdrBigInt64(BigInt.from(555555))),
        XdrUint32(2),
        null,
        XdrUint32(1),
        homeDomain,
        thresholds,
        [signer1, signer2],
        ext,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrAccountEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrAccountEntry.decode(input);

      expect(decoded.signers.length, equals(2));
      expect(decoded.signers[0].weight.uint32, equals(10));
      expect(decoded.signers[1].weight.uint32, equals(5));
    });

    test('XdrAccountEntryExt with discriminant 0 encode/decode', () {
      var original = XdrAccountEntryExt(0);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrAccountEntryExt.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrAccountEntryExt.decode(input);

      expect(decoded.discriminant, equals(0));
      expect(decoded.v1, isNull);
    });

    test('XdrAccountEntryExt with discriminant 1 encode/decode', () {
      var liabilities = XdrLiabilities(
        XdrInt64(BigInt.from(1000)),
        XdrInt64(BigInt.from(2000)),
      );
      var v1Ext = XdrAccountEntryV1Ext(0);
      var v1 = XdrAccountEntryV1(liabilities, v1Ext);

      var original = XdrAccountEntryExt(1);
      original.v1 = v1;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrAccountEntryExt.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrAccountEntryExt.decode(input);

      expect(decoded.discriminant, equals(1));
      expect(decoded.v1, isNotNull);
      expect(decoded.v1!.liabilities.buying.int64, equals(BigInt.from(1000)));
      expect(decoded.v1!.liabilities.selling.int64, equals(BigInt.from(2000)));
    });

    test('XdrAccountEntryV1Ext with discriminant 0 encode/decode', () {
      var original = XdrAccountEntryV1Ext(0);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrAccountEntryV1Ext.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrAccountEntryV1Ext.decode(input);

      expect(decoded.discriminant, equals(0));
      expect(decoded.v2, isNull);
    });

    test('XdrAccountEntryV1Ext with discriminant 2 encode/decode', () {
      var v2Ext = XdrAccountEntryV2Ext(0);
      var v2 = XdrAccountEntryV2(XdrUint32(3), XdrUint32(2), [], v2Ext);

      var original = XdrAccountEntryV1Ext(2);
      original.v2 = v2;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrAccountEntryV1Ext.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrAccountEntryV1Ext.decode(input);

      expect(decoded.discriminant, equals(2));
      expect(decoded.v2, isNotNull);
      expect(decoded.v2!.numSponsored.uint32, equals(3));
      expect(decoded.v2!.numSponsoring.uint32, equals(2));
    });

    test('XdrAccountEntryV2 encode/decode round-trip', () {
      var ext = XdrAccountEntryV2Ext(0);

      var original = XdrAccountEntryV2(
        XdrUint32(10),
        XdrUint32(5),
        [],
        ext,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrAccountEntryV2.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrAccountEntryV2.decode(input);

      expect(decoded.numSponsored.uint32, equals(10));
      expect(decoded.numSponsoring.uint32, equals(5));
      expect(decoded.signerSponsoringIDs, isEmpty);
    });

    test('XdrAccountEntryV2 with signerSponsoringIDs encode/decode', () {
      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x88))));
      var sponsorID = XdrAccountID(pk);
      var ext = XdrAccountEntryV2Ext(0);

      var original = XdrAccountEntryV2(
        XdrUint32(3),
        XdrUint32(2),
        [sponsorID, null],
        ext,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrAccountEntryV2.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrAccountEntryV2.decode(input);

      expect(decoded.numSponsored.uint32, equals(3));
      expect(decoded.numSponsoring.uint32, equals(2));
      expect(decoded.signerSponsoringIDs.length, equals(2));
      expect(decoded.signerSponsoringIDs[0], isNotNull);
      expect(decoded.signerSponsoringIDs[1], isNull);
    });

    test('XdrAccountEntryV2Ext with discriminant 0 encode/decode', () {
      var original = XdrAccountEntryV2Ext(0);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrAccountEntryV2Ext.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrAccountEntryV2Ext.decode(input);

      expect(decoded.discriminant, equals(0));
      expect(decoded.v3, isNull);
    });

    test('XdrAccountEntryV2Ext with discriminant 3 encode/decode', () {
      var ext = XdrExtensionPoint(0);
      var v3 = XdrAccountEntryV3(ext, XdrUint32(1000), XdrUint64(BigInt.from(1234567890)));

      var original = XdrAccountEntryV2Ext(3);
      original.v3 = v3;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrAccountEntryV2Ext.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrAccountEntryV2Ext.decode(input);

      expect(decoded.discriminant, equals(3));
      expect(decoded.v3, isNotNull);
      expect(decoded.v3!.seqLedger.uint32, equals(1000));
      expect(decoded.v3!.seqTime.uint64, equals(BigInt.from(1234567890)));
    });

    test('XdrAccountEntryV3 encode/decode round-trip', () {
      var ext = XdrExtensionPoint(0);

      var original = XdrAccountEntryV3(
        ext,
        XdrUint32(12345),
        XdrUint64(BigInt.from(1609459200)),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrAccountEntryV3.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrAccountEntryV3.decode(input);

      expect(decoded.seqLedger.uint32, equals(12345));
      expect(decoded.seqTime.uint64, equals(BigInt.from(1609459200)));
      expect(decoded.ext.discriminant, equals(0));
    });

    test('XdrExtensionPoint encode/decode round-trip', () {
      var original = XdrExtensionPoint(0);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrExtensionPoint.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrExtensionPoint.decode(input);

      expect(decoded.discriminant, equals(0));
    });

    test('XdrThresholdIndexes enum all variants', () {
      final types = [
        XdrThresholdIndexes.THRESHOLD_MASTER_WEIGHT,
        XdrThresholdIndexes.THRESHOLD_LOW,
        XdrThresholdIndexes.THRESHOLD_MED,
        XdrThresholdIndexes.THRESHOLD_HIGH,
      ];

      for (var type in types) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrThresholdIndexes.encode(output, type);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrThresholdIndexes.decode(input);

        expect(decoded.value, equals(type.value));
      }
    });

    test('XdrAccountFlags enum all variants', () {
      final types = [
        XdrAccountFlags.AUTH_REQUIRED_FLAG,
        XdrAccountFlags.AUTH_REVOCABLE_FLAG,
        XdrAccountFlags.AUTH_IMMUTABLE_FLAG,
        XdrAccountFlags.AUTH_CLAWBACK_ENABLED_FLAG,
      ];

      for (var type in types) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrAccountFlags.encode(output, type);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrAccountFlags.decode(input);

        expect(decoded.value, equals(type.value));
      }
    });

    test('XdrSequenceNumber encode/decode round-trip', () {
      var original = XdrSequenceNumber(XdrBigInt64(BigInt.from(987654321)));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSequenceNumber.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSequenceNumber.decode(input);

      expect(decoded.sequenceNumber.bigInt, equals(BigInt.from(987654321)));
    });

    test('XdrLiabilities encode/decode round-trip', () {
      var original = XdrLiabilities(
        XdrInt64(BigInt.from(5000000)),
        XdrInt64(BigInt.from(3000000)),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLiabilities.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLiabilities.decode(input);

      expect(decoded.buying.int64, equals(BigInt.from(5000000)));
      expect(decoded.selling.int64, equals(BigInt.from(3000000)));
    });

    test('XdrSignerKey SIGNER_KEY_TYPE_ED25519 encode/decode', () {
      var original = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519);
      original.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xCC)));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSignerKey.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSignerKey.decode(input);

      expect(decoded.discriminant.value, equals(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519.value));
      expect(decoded.ed25519, isNotNull);
      expect(decoded.ed25519!.uint256, equals(original.ed25519!.uint256));
    });

    test('XdrSignerKey SIGNER_KEY_TYPE_PRE_AUTH_TX encode/decode', () {
      var original = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_PRE_AUTH_TX);
      original.preAuthTx = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xDD)));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSignerKey.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSignerKey.decode(input);

      expect(decoded.discriminant.value, equals(XdrSignerKeyType.SIGNER_KEY_TYPE_PRE_AUTH_TX.value));
      expect(decoded.preAuthTx, isNotNull);
      expect(decoded.preAuthTx!.uint256, equals(original.preAuthTx!.uint256));
    });

    test('XdrSignerKey SIGNER_KEY_TYPE_HASH_X encode/decode', () {
      var original = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_HASH_X);
      original.hashX = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xEE)));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSignerKey.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSignerKey.decode(input);

      expect(decoded.discriminant.value, equals(XdrSignerKeyType.SIGNER_KEY_TYPE_HASH_X.value));
      expect(decoded.hashX, isNotNull);
      expect(decoded.hashX!.uint256, equals(original.hashX!.uint256));
    });

    test('XdrSignerKey KEY_TYPE_ED25519_SIGNED_PAYLOAD encode/decode', () {
      var payload = XdrDataValue(Uint8List.fromList([1, 2, 3, 4, 5]));
      var signedPayload = XdrSignedPayload(
        XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xFF))),
        payload,
      );

      var original = XdrSignerKey(XdrSignerKeyType.KEY_TYPE_ED25519_SIGNED_PAYLOAD);
      original.signedPayload = signedPayload;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSignerKey.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSignerKey.decode(input);

      expect(decoded.discriminant.value, equals(XdrSignerKeyType.KEY_TYPE_ED25519_SIGNED_PAYLOAD.value));
      expect(decoded.signedPayload, isNotNull);
      expect(decoded.signedPayload!.ed25519.uint256, equals(signedPayload.ed25519.uint256));
    });

    test('XdrSignedPayload encode/decode round-trip', () {
      var payload = XdrDataValue(Uint8List.fromList([10, 20, 30, 40, 50]));
      var original = XdrSignedPayload(
        XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAB))),
        payload,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSignedPayload.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSignedPayload.decode(input);

      expect(decoded.ed25519.uint256, equals(original.ed25519.uint256));
      expect(decoded.payload.dataValue, equals(original.payload.dataValue));
    });

    test('XdrSigner encode/decode round-trip', () {
      var signerKey = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519);
      signerKey.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xCD)));

      var original = XdrSigner(signerKey, XdrUint32(100));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSigner.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSigner.decode(input);

      expect(decoded.weight.uint32, equals(100));
      expect(decoded.key.discriminant.value, equals(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519.value));
    });

    test('XdrAccountMergeResult SUCCESS encode/decode', () {
      var original = XdrAccountMergeResult(XdrAccountMergeResultCode.ACCOUNT_MERGE_SUCCESS);
      original.sourceAccountBalance = XdrInt64(BigInt.from(1000000000));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrAccountMergeResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrAccountMergeResult.decode(input);

      expect(decoded.discriminant, equals(XdrAccountMergeResultCode.ACCOUNT_MERGE_SUCCESS));
      expect(decoded.sourceAccountBalance, isNotNull);
      expect(decoded.sourceAccountBalance!.int64, equals(BigInt.from(1000000000)));
    });

    test('XdrAccountMergeResult failure codes encode/decode', () {
      final failureCodes = [
        XdrAccountMergeResultCode.ACCOUNT_MERGE_MALFORMED,
        XdrAccountMergeResultCode.ACCOUNT_MERGE_NO_ACCOUNT,
        XdrAccountMergeResultCode.ACCOUNT_MERGE_IMMUTABLE_SET,
        XdrAccountMergeResultCode.ACCOUNT_MERGE_HAS_SUB_ENTRIES,
        XdrAccountMergeResultCode.ACCOUNT_MERGE_SEQNUM_TOO_FAR,
        XdrAccountMergeResultCode.ACCOUNT_MERGE_DEST_FULL,
        XdrAccountMergeResultCode.ACCOUNT_MERGE_IS_SPONSOR,
      ];

      for (var code in failureCodes) {
        var original = XdrAccountMergeResult(code);

        XdrDataOutputStream output = XdrDataOutputStream();
        XdrAccountMergeResult.encode(output, original);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrAccountMergeResult.decode(input);

        expect(decoded.discriminant, equals(code));
      }
    });

    test('XdrAccountMergeResultCode all enum values', () {
      final codes = [
        XdrAccountMergeResultCode.ACCOUNT_MERGE_SUCCESS,
        XdrAccountMergeResultCode.ACCOUNT_MERGE_MALFORMED,
        XdrAccountMergeResultCode.ACCOUNT_MERGE_NO_ACCOUNT,
        XdrAccountMergeResultCode.ACCOUNT_MERGE_IMMUTABLE_SET,
        XdrAccountMergeResultCode.ACCOUNT_MERGE_HAS_SUB_ENTRIES,
        XdrAccountMergeResultCode.ACCOUNT_MERGE_SEQNUM_TOO_FAR,
        XdrAccountMergeResultCode.ACCOUNT_MERGE_DEST_FULL,
        XdrAccountMergeResultCode.ACCOUNT_MERGE_IS_SPONSOR,
      ];

      for (var code in codes) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrAccountMergeResultCode.encode(output, code);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrAccountMergeResultCode.decode(input);

        expect(decoded.value, equals(code.value));
      }
    });

    test('XdrBeginSponsoringFutureReservesResult SUCCESS encode/decode', () {
      var original = XdrBeginSponsoringFutureReservesResult(
        XdrBeginSponsoringFutureReservesResultCode.BEGIN_SPONSORING_FUTURE_RESERVES_SUCCESS);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrBeginSponsoringFutureReservesResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrBeginSponsoringFutureReservesResult.decode(input);

      expect(decoded.discriminant, equals(XdrBeginSponsoringFutureReservesResultCode.BEGIN_SPONSORING_FUTURE_RESERVES_SUCCESS));
    });

    test('XdrBeginSponsoringFutureReservesResultCode all enum values', () {
      final codes = [
        XdrBeginSponsoringFutureReservesResultCode.BEGIN_SPONSORING_FUTURE_RESERVES_SUCCESS,
        XdrBeginSponsoringFutureReservesResultCode.BEGIN_SPONSORING_FUTURE_RESERVES_MALFORMED,
        XdrBeginSponsoringFutureReservesResultCode.BEGIN_SPONSORING_FUTURE_RESERVES_ALREADY_SPONSORED,
        XdrBeginSponsoringFutureReservesResultCode.BEGIN_SPONSORING_FUTURE_RESERVES_RECURSIVE,
      ];

      for (var code in codes) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrBeginSponsoringFutureReservesResultCode.encode(output, code);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrBeginSponsoringFutureReservesResultCode.decode(input);

        expect(decoded.value, equals(code.value));
      }
    });

    test('XdrBeginSponsoringFutureReservesOp encode/decode', () {
      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x11))));
      var sponsoredID = XdrAccountID(pk);

      var original = XdrBeginSponsoringFutureReservesOp(sponsoredID);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrBeginSponsoringFutureReservesOp.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrBeginSponsoringFutureReservesOp.decode(input);

      expect(decoded.sponsoredID, isNotNull);
    });

    test('XdrEndSponsoringFutureReservesResult SUCCESS encode/decode', () {
      var original = XdrEndSponsoringFutureReservesResult(
        XdrEndSponsoringFutureReservesResultCode.END_SPONSORING_FUTURE_RESERVES_SUCCESS);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrEndSponsoringFutureReservesResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrEndSponsoringFutureReservesResult.decode(input);

      expect(decoded.discriminant, equals(XdrEndSponsoringFutureReservesResultCode.END_SPONSORING_FUTURE_RESERVES_SUCCESS));
    });

    test('XdrEndSponsoringFutureReservesResultCode all enum values', () {
      final codes = [
        XdrEndSponsoringFutureReservesResultCode.END_SPONSORING_FUTURE_RESERVES_SUCCESS,
        XdrEndSponsoringFutureReservesResultCode.END_SPONSORING_FUTURE_RESERVES_NOT_SPONSORED,
      ];

      for (var code in codes) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrEndSponsoringFutureReservesResultCode.encode(output, code);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrEndSponsoringFutureReservesResultCode.decode(input);

        expect(decoded.value, equals(code.value));
      }
    });

    test('XdrRevokeSponsorshipResult SUCCESS encode/decode', () {
      var original = XdrRevokeSponsorshipResult(XdrRevokeSponsorshipResultCode.REVOKE_SPONSORSHIP_SUCCESS);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrRevokeSponsorshipResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrRevokeSponsorshipResult.decode(input);

      expect(decoded.discriminant, equals(XdrRevokeSponsorshipResultCode.REVOKE_SPONSORSHIP_SUCCESS));
    });

    test('XdrRevokeSponsorshipResultCode all enum values', () {
      final codes = [
        XdrRevokeSponsorshipResultCode.REVOKE_SPONSORSHIP_SUCCESS,
        XdrRevokeSponsorshipResultCode.REVOKE_SPONSORSHIP_DOES_NOT_EXIST,
        XdrRevokeSponsorshipResultCode.REVOKE_SPONSORSHIP_NOT_SPONSOR,
        XdrRevokeSponsorshipResultCode.REVOKE_SPONSORSHIP_LOW_RESERVE,
        XdrRevokeSponsorshipResultCode.REVOKE_SPONSORSHIP_ONLY_TRANSFERABLE,
        XdrRevokeSponsorshipResultCode.REVOKE_SPONSORSHIP_MALFORMED,
      ];

      for (var code in codes) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrRevokeSponsorshipResultCode.encode(output, code);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrRevokeSponsorshipResultCode.decode(input);

        expect(decoded.value, equals(code.value));
      }
    });

    test('XdrRevokeSponsorshipType all enum values', () {
      final types = [
        XdrRevokeSponsorshipType.REVOKE_SPONSORSHIP_LEDGER_ENTRY,
        XdrRevokeSponsorshipType.REVOKE_SPONSORSHIP_SIGNER,
      ];

      for (var type in types) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrRevokeSponsorshipType.encode(output, type);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrRevokeSponsorshipType.decode(input);

        expect(decoded.value, equals(type.value));
      }
    });

    test('XdrCreateClaimableBalanceResultCode all enum values', () {
      final codes = [
        XdrCreateClaimableBalanceResultCode.CREATE_CLAIMABLE_BALANCE_SUCCESS,
        XdrCreateClaimableBalanceResultCode.CREATE_CLAIMABLE_BALANCE_MALFORMED,
        XdrCreateClaimableBalanceResultCode.CREATE_CLAIMABLE_BALANCE_LOW_RESERVE,
        XdrCreateClaimableBalanceResultCode.CREATE_CLAIMABLE_BALANCE_NO_TRUST,
        XdrCreateClaimableBalanceResultCode.CREATE_CLAIMABLE_BALANCE_NOT_AUTHORIZED,
        XdrCreateClaimableBalanceResultCode.CREATE_CLAIMABLE_BALANCE_UNDERFUNDED,
      ];

      for (var code in codes) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrCreateClaimableBalanceResultCode.encode(output, code);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrCreateClaimableBalanceResultCode.decode(input);

        expect(decoded.value, equals(code.value));
      }
    });

    test('XdrClaimClaimableBalanceResultCode all enum values', () {
      final codes = [
        XdrClaimClaimableBalanceResultCode.CLAIM_CLAIMABLE_BALANCE_SUCCESS,
        XdrClaimClaimableBalanceResultCode.CLAIM_CLAIMABLE_BALANCE_DOES_NOT_EXIST,
        XdrClaimClaimableBalanceResultCode.CLAIM_CLAIMABLE_BALANCE_CANNOT_CLAIM,
        XdrClaimClaimableBalanceResultCode.CLAIM_CLAIMABLE_BALANCE_LINE_FULL,
        XdrClaimClaimableBalanceResultCode.CLAIM_CLAIMABLE_BALANCE_NO_TRUST,
        XdrClaimClaimableBalanceResultCode.CLAIM_CLAIMABLE_BALANCE_NOT_AUTHORIZED,
      ];

      for (var code in codes) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrClaimClaimableBalanceResultCode.encode(output, code);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrClaimClaimableBalanceResultCode.decode(input);

        expect(decoded.value, equals(code.value));
      }
    });

    test('XdrClawbackClaimableBalanceResultCode all enum values', () {
      final codes = [
        XdrClawbackClaimableBalanceResultCode.CLAWBACK_CLAIMABLE_BALANCE_SUCCESS,
        XdrClawbackClaimableBalanceResultCode.CLAWBACK_CLAIMABLE_BALANCE_DOES_NOT_EXIST,
        XdrClawbackClaimableBalanceResultCode.CLAWBACK_CLAIMABLE_BALANCE_NOT_ISSUER,
        XdrClawbackClaimableBalanceResultCode.CLAWBACK_CLAIMABLE_BALANCE_NOT_CLAWBACK_ENABLED,
      ];

      for (var code in codes) {
        XdrDataOutputStream output = XdrDataOutputStream();
        output.writeInt(code.value);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrClawbackClaimableBalanceResultCode.decode(input);

        expect(decoded.value, equals(code.value));
      }
    });

    test('XdrBumpSequenceResultCode all enum values', () {
      final codes = [
        XdrBumpSequenceResultCode.BUMP_SEQUENCE_SUCCESS,
        XdrBumpSequenceResultCode.BUMP_SEQUENCE_BAD_SEQ,
      ];

      for (var code in codes) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrBumpSequenceResultCode.encode(output, code);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrBumpSequenceResultCode.decode(input);

        expect(decoded.value, equals(code.value));
      }
    });

    test('XdrBumpSequenceOp encode/decode', () {
      var original = XdrBumpSequenceOp(XdrSequenceNumber(XdrBigInt64(BigInt.from(999999999))));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrBumpSequenceOp.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrBumpSequenceOp.decode(input);

      expect(decoded.bumpTo.sequenceNumber.bigInt, equals(BigInt.from(999999999)));
    });

    test('XdrBumpSequenceResult SUCCESS encode/decode', () {
      var original = XdrBumpSequenceResult(XdrBumpSequenceResultCode.BUMP_SEQUENCE_SUCCESS);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrBumpSequenceResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrBumpSequenceResult.decode(input);

      expect(decoded.discriminant, equals(XdrBumpSequenceResultCode.BUMP_SEQUENCE_SUCCESS));
    });

    test('XdrCreateAccountResultCode all enum values', () {
      final codes = [
        XdrCreateAccountResultCode.CREATE_ACCOUNT_SUCCESS,
        XdrCreateAccountResultCode.CREATE_ACCOUNT_MALFORMED,
        XdrCreateAccountResultCode.CREATE_ACCOUNT_UNDERFUNDED,
        XdrCreateAccountResultCode.CREATE_ACCOUNT_LOW_RESERVE,
        XdrCreateAccountResultCode.CREATE_ACCOUNT_ALREADY_EXIST,
      ];

      for (var code in codes) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrCreateAccountResultCode.encode(output, code);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrCreateAccountResultCode.decode(input);

        expect(decoded.value, equals(code.value));
      }
    });

    test('XdrCreateAccountOp encode/decode', () {
      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x22))));
      var destination = XdrAccountID(pk);

      var original = XdrCreateAccountOp(destination, XdrBigInt64(BigInt.from(10000000)));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrCreateAccountOp.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrCreateAccountOp.decode(input);

      expect(decoded.startingBalance.bigInt, equals(BigInt.from(10000000)));
    });

    test('XdrCreateAccountResult SUCCESS encode/decode', () {
      var original = XdrCreateAccountResult(XdrCreateAccountResultCode.CREATE_ACCOUNT_SUCCESS);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrCreateAccountResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrCreateAccountResult.decode(input);

      expect(decoded.discriminant, equals(XdrCreateAccountResultCode.CREATE_ACCOUNT_SUCCESS));
    });

    test('XdrInflationPayout encode/decode', () {
      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x33))));
      var destination = XdrAccountID(pk);

      var original = XdrInflationPayout(destination, XdrInt64(BigInt.from(5000000)));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrInflationPayout.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrInflationPayout.decode(input);

      expect(decoded.amount.int64, equals(BigInt.from(5000000)));
    });

    test('XdrInflationResult SUCCESS with payouts encode/decode', () {
      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x44))));
      var destination = XdrAccountID(pk);
      var payout = XdrInflationPayout(destination, XdrInt64(BigInt.from(1000000)));

      var original = XdrInflationResult(XdrInflationResultCode.INFLATION_SUCCESS);
      original.payouts = [payout];

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrInflationResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrInflationResult.decode(input);

      expect(decoded.discriminant, equals(XdrInflationResultCode.INFLATION_SUCCESS));
      expect(decoded.payouts, isNotNull);
      expect(decoded.payouts!.length, equals(1));
      expect(decoded.payouts![0].amount.int64, equals(BigInt.from(1000000)));
    });

    test('XdrInflationResultCode all enum values', () {
      final codes = [
        XdrInflationResultCode.INFLATION_SUCCESS,
        XdrInflationResultCode.INFLATION_NOT_TIME,
      ];

      for (var code in codes) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrInflationResultCode.encode(output, code);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrInflationResultCode.decode(input);

        expect(decoded.value, equals(code.value));
      }
    });

    test('XdrManageDataOp with null dataValue encode/decode', () {
      var original = XdrManageDataOp(XdrString64('testkey'), null);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrManageDataOp.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrManageDataOp.decode(input);

      expect(decoded.dataName.string64, equals('testkey'));
      expect(decoded.dataValue, isNull);
    });

    test('XdrManageDataOp with non-null dataValue encode/decode', () {
      var dataValue = XdrDataValue(Uint8List.fromList([1, 2, 3, 4, 5]));
      var original = XdrManageDataOp(XdrString64('testkey2'), dataValue);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrManageDataOp.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrManageDataOp.decode(input);

      expect(decoded.dataName.string64, equals('testkey2'));
      expect(decoded.dataValue, isNotNull);
      expect(decoded.dataValue!.dataValue, equals(dataValue.dataValue));
    });

    test('XdrManageDataResult SUCCESS encode/decode', () {
      var original = XdrManageDataResult(XdrManageDataResultCode.MANAGE_DATA_SUCCESS);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrManageDataResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrManageDataResult.decode(input);

      expect(decoded.discriminant, equals(XdrManageDataResultCode.MANAGE_DATA_SUCCESS));
    });

    test('XdrManageDataResultCode all enum values', () {
      final codes = [
        XdrManageDataResultCode.MANAGE_DATA_SUCCESS,
        XdrManageDataResultCode.MANAGE_DATA_NOT_SUPPORTED_YET,
        XdrManageDataResultCode.MANAGE_DATA_NAME_NOT_FOUND,
        XdrManageDataResultCode.MANAGE_DATA_LOW_RESERVE,
        XdrManageDataResultCode.MANAGE_DATA_INVALID_NAME,
      ];

      for (var code in codes) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrManageDataResultCode.encode(output, code);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrManageDataResultCode.decode(input);

        expect(decoded.value, equals(code.value));
      }
    });

    test('XdrSetOptionsOp with all null optional fields encode/decode', () {
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

    test('XdrSetOptionsOp with all non-null optional fields encode/decode', () {
      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x55))));
      var inflationDest = XdrAccountID(pk);

      var signerKey = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519);
      signerKey.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x66)));
      var signer = XdrSigner(signerKey, XdrUint32(50));

      var original = XdrSetOptionsOp();
      original.inflationDest = inflationDest;
      original.clearFlags = XdrUint32(1);
      original.setFlags = XdrUint32(2);
      original.masterWeight = XdrUint32(100);
      original.lowThreshold = XdrUint32(10);
      original.medThreshold = XdrUint32(20);
      original.highThreshold = XdrUint32(30);
      original.homeDomain = XdrString32('example.org');
      original.signer = signer;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSetOptionsOp.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSetOptionsOp.decode(input);

      expect(decoded.inflationDest, isNotNull);
      expect(decoded.clearFlags, isNotNull);
      expect(decoded.clearFlags!.uint32, equals(1));
      expect(decoded.setFlags, isNotNull);
      expect(decoded.setFlags!.uint32, equals(2));
      expect(decoded.masterWeight, isNotNull);
      expect(decoded.masterWeight!.uint32, equals(100));
      expect(decoded.lowThreshold, isNotNull);
      expect(decoded.lowThreshold!.uint32, equals(10));
      expect(decoded.medThreshold, isNotNull);
      expect(decoded.medThreshold!.uint32, equals(20));
      expect(decoded.highThreshold, isNotNull);
      expect(decoded.highThreshold!.uint32, equals(30));
      expect(decoded.homeDomain, isNotNull);
      expect(decoded.homeDomain!.string32, equals('example.org'));
      expect(decoded.signer, isNotNull);
      expect(decoded.signer!.weight.uint32, equals(50));
    });

    test('XdrSetOptionsResult SUCCESS encode/decode', () {
      var original = XdrSetOptionsResult(XdrSetOptionsResultCode.SET_OPTIONS_SUCCESS);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSetOptionsResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSetOptionsResult.decode(input);

      expect(decoded.discriminant, equals(XdrSetOptionsResultCode.SET_OPTIONS_SUCCESS));
    });

    test('XdrSetOptionsResultCode all enum values', () {
      final codes = [
        XdrSetOptionsResultCode.SET_OPTIONS_SUCCESS,
        XdrSetOptionsResultCode.SET_OPTIONS_LOW_RESERVE,
        XdrSetOptionsResultCode.SET_OPTIONS_TOO_MANY_SIGNERS,
        XdrSetOptionsResultCode.SET_OPTIONS_BAD_FLAGS,
        XdrSetOptionsResultCode.SET_OPTIONS_INVALID_INFLATION,
        XdrSetOptionsResultCode.SET_OPTIONS_CANT_CHANGE,
        XdrSetOptionsResultCode.SET_OPTIONS_UNKNOWN_FLAG,
        XdrSetOptionsResultCode.SET_OPTIONS_THRESHOLD_OUT_OF_RANGE,
        XdrSetOptionsResultCode.SET_OPTIONS_BAD_SIGNER,
        XdrSetOptionsResultCode.SET_OPTIONS_INVALID_HOME_DOMAIN,
      ];

      for (var code in codes) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrSetOptionsResultCode.encode(output, code);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrSetOptionsResultCode.decode(input);

        expect(decoded.value, equals(code.value));
      }
    });

    test('XdrLiquidityPoolDepositOp encode/decode', () {
      var poolId = XdrHash(Uint8List.fromList(List<int>.filled(32, 0x77)));
      var price1 = XdrPrice(XdrInt32(1), XdrInt32(2));
      var price2 = XdrPrice(XdrInt32(3), XdrInt32(4));

      var original = XdrLiquidityPoolDepositOp(
        poolId,
        XdrBigInt64(BigInt.from(1000000)),
        XdrBigInt64(BigInt.from(2000000)),
        price1,
        price2,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLiquidityPoolDepositOp.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLiquidityPoolDepositOp.decode(input);

      expect(decoded.maxAmountA.bigInt, equals(BigInt.from(1000000)));
      expect(decoded.maxAmountB.bigInt, equals(BigInt.from(2000000)));
    });

    test('XdrLiquidityPoolDepositResult SUCCESS encode/decode', () {
      var original = XdrLiquidityPoolDepositResult(XdrLiquidityPoolDepositResultCode.LIQUIDITY_POOL_DEPOSIT_SUCCESS);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLiquidityPoolDepositResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLiquidityPoolDepositResult.decode(input);

      expect(decoded.discriminant, equals(XdrLiquidityPoolDepositResultCode.LIQUIDITY_POOL_DEPOSIT_SUCCESS));
    });

    test('XdrLiquidityPoolDepositResultCode all enum values', () {
      final codes = [
        XdrLiquidityPoolDepositResultCode.LIQUIDITY_POOL_DEPOSIT_SUCCESS,
        XdrLiquidityPoolDepositResultCode.LIQUIDITY_POOL_DEPOSIT_MALFORMED,
        XdrLiquidityPoolDepositResultCode.LIQUIDITY_POOL_DEPOSIT_NO_TRUST,
        XdrLiquidityPoolDepositResultCode.LIQUIDITY_POOL_DEPOSIT_NOT_AUTHORIZED,
        XdrLiquidityPoolDepositResultCode.LIQUIDITY_POOL_DEPOSIT_UNDERFUNDED,
        XdrLiquidityPoolDepositResultCode.LIQUIDITY_POOL_DEPOSIT_LINE_FULL,
        XdrLiquidityPoolDepositResultCode.LIQUIDITY_POOL_DEPOSIT_BAD_PRICE,
        XdrLiquidityPoolDepositResultCode.LIQUIDITY_POOL_DEPOSIT_POOL_FULL,
      ];

      for (var code in codes) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrLiquidityPoolDepositResultCode.encode(output, code);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrLiquidityPoolDepositResultCode.decode(input);

        expect(decoded.value, equals(code.value));
      }
    });

    test('XdrLiquidityPoolWithdrawOp encode/decode', () {
      var poolId = XdrHash(Uint8List.fromList(List<int>.filled(32, 0x88)));

      var original = XdrLiquidityPoolWithdrawOp(
        poolId,
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

    test('XdrLiquidityPoolWithdrawResult SUCCESS encode/decode', () {
      var original = XdrLiquidityPoolWithdrawResult(XdrLiquidityPoolWithdrawResultCode.LIQUIDITY_POOL_WITHDRAW_SUCCESS);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLiquidityPoolWithdrawResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLiquidityPoolWithdrawResult.decode(input);

      expect(decoded.discriminant, equals(XdrLiquidityPoolWithdrawResultCode.LIQUIDITY_POOL_WITHDRAW_SUCCESS));
    });

    test('XdrLiquidityPoolWithdrawResultCode all enum values', () {
      final codes = [
        XdrLiquidityPoolWithdrawResultCode.LIQUIDITY_POOL_WITHDRAW_SUCCESS,
        XdrLiquidityPoolWithdrawResultCode.LIQUIDITY_POOL_WITHDRAW_MALFORMED,
        XdrLiquidityPoolWithdrawResultCode.LIQUIDITY_POOL_WITHDRAW_NO_TRUST,
        XdrLiquidityPoolWithdrawResultCode.LIQUIDITY_POOL_WITHDRAW_UNDERFUNDED,
        XdrLiquidityPoolWithdrawResultCode.LIQUIDITY_POOL_WITHDRAW_LINE_FULL,
        XdrLiquidityPoolWithdrawResultCode.LIQUIDITY_POOL_WITHDRAW_UNDER_MINIMUM,
      ];

      for (var code in codes) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrLiquidityPoolWithdrawResultCode.encode(output, code);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrLiquidityPoolWithdrawResultCode.decode(input);

        expect(decoded.value, equals(code.value));
      }
    });
  });

  group('XDR Account Types - Additional Branch Coverage', () {
    test('XdrRevokeSponsorshipOp REVOKE_SPONSORSHIP_LEDGER_ENTRY encode/decode', () {
      var ledgerKey = XdrLedgerKey(XdrLedgerEntryType.ACCOUNT);
      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x11))));
      ledgerKey.account = XdrLedgerKeyAccount(XdrAccountID(pk));

      var original = XdrRevokeSponsorshipOp(XdrRevokeSponsorshipType.REVOKE_SPONSORSHIP_LEDGER_ENTRY);
      original.ledgerKey = ledgerKey;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrRevokeSponsorshipOp.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrRevokeSponsorshipOp.decode(input);

      expect(decoded.discriminant, equals(XdrRevokeSponsorshipType.REVOKE_SPONSORSHIP_LEDGER_ENTRY));
      expect(decoded.ledgerKey, isNotNull);
    });

    test('XdrRevokeSponsorshipOp REVOKE_SPONSORSHIP_SIGNER encode/decode', () {
      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x22))));
      var accountId = XdrAccountID(pk);

      var signerKey = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519);
      signerKey.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x33)));

      var signer = XdrRevokeSponsorshipSigner(accountId, signerKey);

      var original = XdrRevokeSponsorshipOp(XdrRevokeSponsorshipType.REVOKE_SPONSORSHIP_SIGNER);
      original.signer = signer;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrRevokeSponsorshipOp.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrRevokeSponsorshipOp.decode(input);

      expect(decoded.discriminant, equals(XdrRevokeSponsorshipType.REVOKE_SPONSORSHIP_SIGNER));
      expect(decoded.signer, isNotNull);
    });

    test('XdrRevokeSponsorshipSigner encode/decode round-trip', () {
      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x44))));
      var accountId = XdrAccountID(pk);

      var signerKey = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_HASH_X);
      signerKey.hashX = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x55)));

      var original = XdrRevokeSponsorshipSigner(accountId, signerKey);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrRevokeSponsorshipSigner.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrRevokeSponsorshipSigner.decode(input);

      expect(decoded.accountId, isNotNull);
      expect(decoded.signerKey.discriminant, equals(XdrSignerKeyType.SIGNER_KEY_TYPE_HASH_X));
    });

    test('XdrCreateClaimableBalanceOp encode/decode with multiple claimants', () {
      var asset = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);

      var pk1 = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk1.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x66))));
      var claimant1 = XdrClaimant(XdrClaimantType.CLAIMANT_TYPE_V0);
      claimant1.v0 = XdrClaimantV0(XdrAccountID(pk1), XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_UNCONDITIONAL));

      var pk2 = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk2.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x77))));
      var claimant2 = XdrClaimant(XdrClaimantType.CLAIMANT_TYPE_V0);
      claimant2.v0 = XdrClaimantV0(XdrAccountID(pk2), XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_UNCONDITIONAL));

      var original = XdrCreateClaimableBalanceOp(asset, XdrBigInt64(BigInt.from(1000000)), [claimant1, claimant2]);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrCreateClaimableBalanceOp.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrCreateClaimableBalanceOp.decode(input);

      expect(decoded.amount.bigInt, equals(BigInt.from(1000000)));
      expect(decoded.claimants.length, equals(2));
    });

    test('XdrCreateClaimableBalanceResult SUCCESS with balanceID encode/decode', () {
      var hash = XdrHash(Uint8List.fromList(List<int>.filled(32, 0x88)));
      var balanceID = XdrClaimableBalanceID(XdrClaimableBalanceIDType.CLAIMABLE_BALANCE_ID_TYPE_V0);
      balanceID.v0 = hash;

      var original = XdrCreateClaimableBalanceResult(XdrCreateClaimableBalanceResultCode.CREATE_CLAIMABLE_BALANCE_SUCCESS);
      original.balanceID = balanceID;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrCreateClaimableBalanceResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrCreateClaimableBalanceResult.decode(input);

      expect(decoded.discriminant, equals(XdrCreateClaimableBalanceResultCode.CREATE_CLAIMABLE_BALANCE_SUCCESS));
      expect(decoded.balanceID, isNotNull);
    });

    test('XdrCreateClaimableBalanceResult failure codes encode/decode', () {
      final failureCodes = [
        XdrCreateClaimableBalanceResultCode.CREATE_CLAIMABLE_BALANCE_MALFORMED,
        XdrCreateClaimableBalanceResultCode.CREATE_CLAIMABLE_BALANCE_LOW_RESERVE,
        XdrCreateClaimableBalanceResultCode.CREATE_CLAIMABLE_BALANCE_NO_TRUST,
        XdrCreateClaimableBalanceResultCode.CREATE_CLAIMABLE_BALANCE_NOT_AUTHORIZED,
        XdrCreateClaimableBalanceResultCode.CREATE_CLAIMABLE_BALANCE_UNDERFUNDED,
      ];

      for (var code in failureCodes) {
        var original = XdrCreateClaimableBalanceResult(code);

        XdrDataOutputStream output = XdrDataOutputStream();
        XdrCreateClaimableBalanceResult.encode(output, original);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrCreateClaimableBalanceResult.decode(input);

        expect(decoded.discriminant, equals(code));
      }
    });

    test('XdrClaimClaimableBalanceOp encode/decode', () {
      var hash = XdrHash(Uint8List.fromList(List<int>.filled(32, 0x99)));
      var balanceID = XdrClaimableBalanceID(XdrClaimableBalanceIDType.CLAIMABLE_BALANCE_ID_TYPE_V0);
      balanceID.v0 = hash;

      var original = XdrClaimClaimableBalanceOp(balanceID);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrClaimClaimableBalanceOp.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrClaimClaimableBalanceOp.decode(input);

      expect(decoded.balanceID, isNotNull);
    });

    test('XdrClaimClaimableBalanceResult SUCCESS encode/decode', () {
      var original = XdrClaimClaimableBalanceResult(XdrClaimClaimableBalanceResultCode.CLAIM_CLAIMABLE_BALANCE_SUCCESS);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrClaimClaimableBalanceResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrClaimClaimableBalanceResult.decode(input);

      expect(decoded.discriminant, equals(XdrClaimClaimableBalanceResultCode.CLAIM_CLAIMABLE_BALANCE_SUCCESS));
    });

    test('XdrClaimClaimableBalanceResult failure codes encode/decode', () {
      final failureCodes = [
        XdrClaimClaimableBalanceResultCode.CLAIM_CLAIMABLE_BALANCE_DOES_NOT_EXIST,
        XdrClaimClaimableBalanceResultCode.CLAIM_CLAIMABLE_BALANCE_CANNOT_CLAIM,
        XdrClaimClaimableBalanceResultCode.CLAIM_CLAIMABLE_BALANCE_LINE_FULL,
        XdrClaimClaimableBalanceResultCode.CLAIM_CLAIMABLE_BALANCE_NO_TRUST,
        XdrClaimClaimableBalanceResultCode.CLAIM_CLAIMABLE_BALANCE_NOT_AUTHORIZED,
      ];

      for (var code in failureCodes) {
        var original = XdrClaimClaimableBalanceResult(code);

        XdrDataOutputStream output = XdrDataOutputStream();
        XdrClaimClaimableBalanceResult.encode(output, original);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrClaimClaimableBalanceResult.decode(input);

        expect(decoded.discriminant, equals(code));
      }
    });

    test('XdrClawbackClaimableBalanceOp encode/decode', () {
      var hash = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xAA)));
      var balanceID = XdrClaimableBalanceID(XdrClaimableBalanceIDType.CLAIMABLE_BALANCE_ID_TYPE_V0);
      balanceID.v0 = hash;

      var original = XdrClawbackClaimableBalanceOp(balanceID);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrClawbackClaimableBalanceOp.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrClawbackClaimableBalanceOp.decode(input);

      expect(decoded.balanceID, isNotNull);
    });

    test('XdrClawbackClaimableBalanceResult SUCCESS encode/decode', () {
      var original = XdrClawbackClaimableBalanceResult(XdrClawbackClaimableBalanceResultCode.CLAWBACK_CLAIMABLE_BALANCE_SUCCESS);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrClawbackClaimableBalanceResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrClawbackClaimableBalanceResult.decode(input);

      expect(decoded.discriminant, equals(XdrClawbackClaimableBalanceResultCode.CLAWBACK_CLAIMABLE_BALANCE_SUCCESS));
    });

    test('XdrClawbackClaimableBalanceResult failure codes encode/decode', () {
      final failureCodes = [
        XdrClawbackClaimableBalanceResultCode.CLAWBACK_CLAIMABLE_BALANCE_DOES_NOT_EXIST,
        XdrClawbackClaimableBalanceResultCode.CLAWBACK_CLAIMABLE_BALANCE_NOT_ISSUER,
        XdrClawbackClaimableBalanceResultCode.CLAWBACK_CLAIMABLE_BALANCE_NOT_CLAWBACK_ENABLED,
      ];

      for (var code in failureCodes) {
        var original = XdrClawbackClaimableBalanceResult(code);

        XdrDataOutputStream output = XdrDataOutputStream();
        XdrClawbackClaimableBalanceResult.encode(output, original);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrClawbackClaimableBalanceResult.decode(input);

        expect(decoded.discriminant, equals(code));
      }
    });

    test('XdrBumpSequenceResult BAD_SEQ encode/decode', () {
      var original = XdrBumpSequenceResult(XdrBumpSequenceResultCode.BUMP_SEQUENCE_BAD_SEQ);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrBumpSequenceResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrBumpSequenceResult.decode(input);

      expect(decoded.discriminant, equals(XdrBumpSequenceResultCode.BUMP_SEQUENCE_BAD_SEQ));
    });

    test('XdrCreateAccountResult failure codes encode/decode', () {
      final failureCodes = [
        XdrCreateAccountResultCode.CREATE_ACCOUNT_MALFORMED,
        XdrCreateAccountResultCode.CREATE_ACCOUNT_UNDERFUNDED,
        XdrCreateAccountResultCode.CREATE_ACCOUNT_LOW_RESERVE,
        XdrCreateAccountResultCode.CREATE_ACCOUNT_ALREADY_EXIST,
      ];

      for (var code in failureCodes) {
        var original = XdrCreateAccountResult(code);

        XdrDataOutputStream output = XdrDataOutputStream();
        XdrCreateAccountResult.encode(output, original);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrCreateAccountResult.decode(input);

        expect(decoded.discriminant, equals(code));
      }
    });

    test('XdrInflationResult INFLATION_NOT_TIME encode/decode', () {
      var original = XdrInflationResult(XdrInflationResultCode.INFLATION_NOT_TIME);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrInflationResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrInflationResult.decode(input);

      expect(decoded.discriminant, equals(XdrInflationResultCode.INFLATION_NOT_TIME));
      expect(decoded.payouts, isNull);
    });

    test('XdrInflationResult SUCCESS with multiple payouts encode/decode', () {
      var pk1 = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk1.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xBB))));
      var destination1 = XdrAccountID(pk1);
      var payout1 = XdrInflationPayout(destination1, XdrInt64(BigInt.from(1000000)));

      var pk2 = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk2.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xCC))));
      var destination2 = XdrAccountID(pk2);
      var payout2 = XdrInflationPayout(destination2, XdrInt64(BigInt.from(2000000)));

      var original = XdrInflationResult(XdrInflationResultCode.INFLATION_SUCCESS);
      original.payouts = [payout1, payout2];

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrInflationResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrInflationResult.decode(input);

      expect(decoded.discriminant, equals(XdrInflationResultCode.INFLATION_SUCCESS));
      expect(decoded.payouts, isNotNull);
      expect(decoded.payouts!.length, equals(2));
      expect(decoded.payouts![0].amount.int64, equals(BigInt.from(1000000)));
      expect(decoded.payouts![1].amount.int64, equals(BigInt.from(2000000)));
    });

    test('XdrManageDataResult failure codes encode/decode', () {
      final failureCodes = [
        XdrManageDataResultCode.MANAGE_DATA_NOT_SUPPORTED_YET,
        XdrManageDataResultCode.MANAGE_DATA_NAME_NOT_FOUND,
        XdrManageDataResultCode.MANAGE_DATA_LOW_RESERVE,
        XdrManageDataResultCode.MANAGE_DATA_INVALID_NAME,
      ];

      for (var code in failureCodes) {
        var original = XdrManageDataResult(code);

        XdrDataOutputStream output = XdrDataOutputStream();
        XdrManageDataResult.encode(output, original);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrManageDataResult.decode(input);

        expect(decoded.discriminant, equals(code));
      }
    });

    test('XdrSetOptionsResult failure codes encode/decode', () {
      final failureCodes = [
        XdrSetOptionsResultCode.SET_OPTIONS_LOW_RESERVE,
        XdrSetOptionsResultCode.SET_OPTIONS_TOO_MANY_SIGNERS,
        XdrSetOptionsResultCode.SET_OPTIONS_BAD_FLAGS,
        XdrSetOptionsResultCode.SET_OPTIONS_INVALID_INFLATION,
        XdrSetOptionsResultCode.SET_OPTIONS_CANT_CHANGE,
        XdrSetOptionsResultCode.SET_OPTIONS_UNKNOWN_FLAG,
        XdrSetOptionsResultCode.SET_OPTIONS_THRESHOLD_OUT_OF_RANGE,
        XdrSetOptionsResultCode.SET_OPTIONS_BAD_SIGNER,
        XdrSetOptionsResultCode.SET_OPTIONS_INVALID_HOME_DOMAIN,
      ];

      for (var code in failureCodes) {
        var original = XdrSetOptionsResult(code);

        XdrDataOutputStream output = XdrDataOutputStream();
        XdrSetOptionsResult.encode(output, original);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrSetOptionsResult.decode(input);

        expect(decoded.discriminant, equals(code));
      }
    });

    test('XdrBeginSponsoringFutureReservesResult failure codes encode/decode', () {
      final failureCodes = [
        XdrBeginSponsoringFutureReservesResultCode.BEGIN_SPONSORING_FUTURE_RESERVES_MALFORMED,
        XdrBeginSponsoringFutureReservesResultCode.BEGIN_SPONSORING_FUTURE_RESERVES_ALREADY_SPONSORED,
        XdrBeginSponsoringFutureReservesResultCode.BEGIN_SPONSORING_FUTURE_RESERVES_RECURSIVE,
      ];

      for (var code in failureCodes) {
        var original = XdrBeginSponsoringFutureReservesResult(code);

        XdrDataOutputStream output = XdrDataOutputStream();
        XdrBeginSponsoringFutureReservesResult.encode(output, original);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrBeginSponsoringFutureReservesResult.decode(input);

        expect(decoded.discriminant, equals(code));
      }
    });

    test('XdrEndSponsoringFutureReservesResult NOT_SPONSORED encode/decode', () {
      var original = XdrEndSponsoringFutureReservesResult(
        XdrEndSponsoringFutureReservesResultCode.END_SPONSORING_FUTURE_RESERVES_NOT_SPONSORED);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrEndSponsoringFutureReservesResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrEndSponsoringFutureReservesResult.decode(input);

      expect(decoded.discriminant, equals(XdrEndSponsoringFutureReservesResultCode.END_SPONSORING_FUTURE_RESERVES_NOT_SPONSORED));
    });

    test('XdrRevokeSponsorshipResult failure codes encode/decode', () {
      final failureCodes = [
        XdrRevokeSponsorshipResultCode.REVOKE_SPONSORSHIP_DOES_NOT_EXIST,
        XdrRevokeSponsorshipResultCode.REVOKE_SPONSORSHIP_NOT_SPONSOR,
        XdrRevokeSponsorshipResultCode.REVOKE_SPONSORSHIP_LOW_RESERVE,
        XdrRevokeSponsorshipResultCode.REVOKE_SPONSORSHIP_ONLY_TRANSFERABLE,
        XdrRevokeSponsorshipResultCode.REVOKE_SPONSORSHIP_MALFORMED,
      ];

      for (var code in failureCodes) {
        var original = XdrRevokeSponsorshipResult(code);

        XdrDataOutputStream output = XdrDataOutputStream();
        XdrRevokeSponsorshipResult.encode(output, original);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrRevokeSponsorshipResult.decode(input);

        expect(decoded.discriminant, equals(code));
      }
    });

    test('XdrLiquidityPoolDepositResult failure codes encode/decode', () {
      final failureCodes = [
        XdrLiquidityPoolDepositResultCode.LIQUIDITY_POOL_DEPOSIT_MALFORMED,
        XdrLiquidityPoolDepositResultCode.LIQUIDITY_POOL_DEPOSIT_NO_TRUST,
        XdrLiquidityPoolDepositResultCode.LIQUIDITY_POOL_DEPOSIT_NOT_AUTHORIZED,
        XdrLiquidityPoolDepositResultCode.LIQUIDITY_POOL_DEPOSIT_UNDERFUNDED,
        XdrLiquidityPoolDepositResultCode.LIQUIDITY_POOL_DEPOSIT_LINE_FULL,
        XdrLiquidityPoolDepositResultCode.LIQUIDITY_POOL_DEPOSIT_BAD_PRICE,
        XdrLiquidityPoolDepositResultCode.LIQUIDITY_POOL_DEPOSIT_POOL_FULL,
      ];

      for (var code in failureCodes) {
        var original = XdrLiquidityPoolDepositResult(code);

        XdrDataOutputStream output = XdrDataOutputStream();
        XdrLiquidityPoolDepositResult.encode(output, original);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrLiquidityPoolDepositResult.decode(input);

        expect(decoded.discriminant, equals(code));
      }
    });

    test('XdrLiquidityPoolWithdrawResult failure codes encode/decode', () {
      final failureCodes = [
        XdrLiquidityPoolWithdrawResultCode.LIQUIDITY_POOL_WITHDRAW_MALFORMED,
        XdrLiquidityPoolWithdrawResultCode.LIQUIDITY_POOL_WITHDRAW_NO_TRUST,
        XdrLiquidityPoolWithdrawResultCode.LIQUIDITY_POOL_WITHDRAW_UNDERFUNDED,
        XdrLiquidityPoolWithdrawResultCode.LIQUIDITY_POOL_WITHDRAW_LINE_FULL,
        XdrLiquidityPoolWithdrawResultCode.LIQUIDITY_POOL_WITHDRAW_UNDER_MINIMUM,
      ];

      for (var code in failureCodes) {
        var original = XdrLiquidityPoolWithdrawResult(code);

        XdrDataOutputStream output = XdrDataOutputStream();
        XdrLiquidityPoolWithdrawResult.encode(output, original);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrLiquidityPoolWithdrawResult.decode(input);

        expect(decoded.discriminant, equals(code));
      }
    });

    test('XdrAccountEntry with empty string homeDomain encode/decode', () {
      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xDD))));
      var accountID = XdrAccountID(pk);

      var thresholds = XdrThresholds(Uint8List.fromList([0, 0, 0, 0]));
      var homeDomain = XdrString32('');
      var ext = XdrAccountEntryExt(0);

      var original = XdrAccountEntry(
        accountID,
        XdrInt64(BigInt.from(1)),
        XdrSequenceNumber(XdrBigInt64(BigInt.from(1))),
        XdrUint32(0),
        null,
        XdrUint32(0),
        homeDomain,
        thresholds,
        [],
        ext,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrAccountEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrAccountEntry.decode(input);

      expect(decoded.homeDomain.string32, equals(''));
    });

    test('XdrAccountEntryV2 with mixed null and non-null signerSponsoringIDs encode/decode', () {
      var pk1 = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk1.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xEE))));
      var sponsorID1 = XdrAccountID(pk1);

      var pk2 = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk2.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xFF))));
      var sponsorID2 = XdrAccountID(pk2);

      var ext = XdrAccountEntryV2Ext(0);

      var original = XdrAccountEntryV2(
        XdrUint32(5),
        XdrUint32(3),
        [sponsorID1, null, sponsorID2],
        ext,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrAccountEntryV2.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrAccountEntryV2.decode(input);

      expect(decoded.numSponsored.uint32, equals(5));
      expect(decoded.numSponsoring.uint32, equals(3));
      expect(decoded.signerSponsoringIDs.length, equals(3));
      expect(decoded.signerSponsoringIDs[0], isNotNull);
      expect(decoded.signerSponsoringIDs[1], isNull);
      expect(decoded.signerSponsoringIDs[2], isNotNull);
    });

    test('XdrSetOptionsOp with partial optional fields encode/decode', () {
      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x11))));
      var inflationDest = XdrAccountID(pk);

      var original = XdrSetOptionsOp();
      original.inflationDest = inflationDest;
      original.clearFlags = XdrUint32(2);
      original.lowThreshold = XdrUint32(5);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSetOptionsOp.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSetOptionsOp.decode(input);

      expect(decoded.inflationDest, isNotNull);
      expect(decoded.clearFlags, isNotNull);
      expect(decoded.clearFlags!.uint32, equals(2));
      expect(decoded.setFlags, isNull);
      expect(decoded.masterWeight, isNull);
      expect(decoded.lowThreshold, isNotNull);
      expect(decoded.lowThreshold!.uint32, equals(5));
      expect(decoded.medThreshold, isNull);
      expect(decoded.highThreshold, isNull);
      expect(decoded.homeDomain, isNull);
      expect(decoded.signer, isNull);
    });

    test('XdrAccountEntry with flags set encode/decode', () {
      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x12))));
      var accountID = XdrAccountID(pk);

      var thresholds = XdrThresholds(Uint8List.fromList([10, 20, 30, 40]));
      var homeDomain = XdrString32('stel');
      var ext = XdrAccountEntryExt(0);

      var original = XdrAccountEntry(
        accountID,
        XdrInt64(BigInt.from(5000000000)),
        XdrSequenceNumber(XdrBigInt64(BigInt.from(100))),
        XdrUint32(10),
        null,
        XdrUint32(3),
        homeDomain,
        thresholds,
        [],
        ext,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrAccountEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrAccountEntry.decode(input);

      expect(decoded.flags.uint32, equals(3));
      expect(decoded.thresholds.thresholds[0], equals(10));
      expect(decoded.thresholds.thresholds[1], equals(20));
      expect(decoded.thresholds.thresholds[2], equals(30));
      expect(decoded.thresholds.thresholds[3], equals(40));
    });

    test('XdrAccountEntryV3 with different values encode/decode', () {
      var ext = XdrExtensionPoint(0);

      var original = XdrAccountEntryV3(
        ext,
        XdrUint32(999),
        XdrUint64(BigInt.from(1234567890123)),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrAccountEntryV3.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrAccountEntryV3.decode(input);

      expect(decoded.seqLedger.uint32, equals(999));
      expect(decoded.seqTime.uint64, equals(BigInt.from(1234567890123)));
    });

    test('XdrAccountEntry with full extension chain v1 -> v2 -> v3 encode/decode', () {
      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x13))));
      var accountID = XdrAccountID(pk);

      var v3Ext = XdrExtensionPoint(0);
      var v3 = XdrAccountEntryV3(v3Ext, XdrUint32(500), XdrUint64(BigInt.from(9999999)));

      var v2Ext = XdrAccountEntryV2Ext(3);
      v2Ext.v3 = v3;
      var v2 = XdrAccountEntryV2(XdrUint32(7), XdrUint32(4), [], v2Ext);

      var liabilities = XdrLiabilities(XdrInt64(BigInt.from(500000)), XdrInt64(BigInt.from(300000)));
      var v1Ext = XdrAccountEntryV1Ext(2);
      v1Ext.v2 = v2;
      var v1 = XdrAccountEntryV1(liabilities, v1Ext);

      var ext = XdrAccountEntryExt(1);
      ext.v1 = v1;

      var thresholds = XdrThresholds(Uint8List.fromList([5, 10, 15, 20]));
      var homeDomain = XdrString32('testdomain12345678901234');

      var original = XdrAccountEntry(
        accountID,
        XdrInt64(BigInt.from(50000000000)),
        XdrSequenceNumber(XdrBigInt64(BigInt.from(12345))),
        XdrUint32(15),
        null,
        XdrUint32(1),
        homeDomain,
        thresholds,
        [],
        ext,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrAccountEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrAccountEntry.decode(input);

      expect(decoded.ext.discriminant, equals(1));
      expect(decoded.ext.v1, isNotNull);
      expect(decoded.ext.v1!.ext.discriminant, equals(2));
      expect(decoded.ext.v1!.ext.v2, isNotNull);
      expect(decoded.ext.v1!.ext.v2!.ext.discriminant, equals(3));
      expect(decoded.ext.v1!.ext.v2!.ext.v3, isNotNull);
      expect(decoded.ext.v1!.ext.v2!.ext.v3!.seqLedger.uint32, equals(500));
      expect(decoded.ext.v1!.ext.v2!.ext.v3!.seqTime.uint64, equals(BigInt.from(9999999)));
    });

    test('XdrSetOptionsOp with only signer set encode/decode', () {
      var signerKey = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_PRE_AUTH_TX);
      signerKey.preAuthTx = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x14)));
      var signer = XdrSigner(signerKey, XdrUint32(25));

      var original = XdrSetOptionsOp();
      original.signer = signer;

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
      expect(decoded.signer, isNotNull);
      expect(decoded.signer!.key.discriminant, equals(XdrSignerKeyType.SIGNER_KEY_TYPE_PRE_AUTH_TX));
    });

    test('XdrAccountEntry with large balance and seqNum encode/decode', () {
      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x15))));
      var accountID = XdrAccountID(pk);

      var thresholds = XdrThresholds(Uint8List.fromList([255, 255, 255, 255]));
      var homeDomain = XdrString32('verylongdomain1234567890');
      var ext = XdrAccountEntryExt(0);

      var original = XdrAccountEntry(
        accountID,
        XdrInt64(BigInt.parse('9223372036854775807')),
        XdrSequenceNumber(XdrBigInt64(BigInt.parse('9223372036854775807'))),
        XdrUint32(999999),
        null,
        XdrUint32(15),
        homeDomain,
        thresholds,
        [],
        ext,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrAccountEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrAccountEntry.decode(input);

      expect(decoded.balance.int64, equals(BigInt.parse('9223372036854775807')));
      expect(decoded.seqNum.sequenceNumber.bigInt, equals(BigInt.parse('9223372036854775807')));
      expect(decoded.numSubEntries.uint32, equals(999999));
    });

    test('XdrCreateClaimableBalanceOp with empty claimants list encode/decode', () {
      var asset = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var original = XdrCreateClaimableBalanceOp(asset, XdrBigInt64(BigInt.from(100)), []);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrCreateClaimableBalanceOp.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrCreateClaimableBalanceOp.decode(input);

      expect(decoded.amount.bigInt, equals(BigInt.from(100)));
      expect(decoded.claimants, isEmpty);
    });

    test('XdrAccountEntryV1 with large liabilities encode/decode', () {
      var liabilities = XdrLiabilities(
        XdrInt64(BigInt.parse('9223372036854775807')),
        XdrInt64(BigInt.parse('9223372036854775807')),
      );
      var v1Ext = XdrAccountEntryV1Ext(0);
      var original = XdrAccountEntryV1(liabilities, v1Ext);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrAccountEntryV1.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrAccountEntryV1.decode(input);

      expect(decoded.liabilities.buying.int64, equals(BigInt.parse('9223372036854775807')));
      expect(decoded.liabilities.selling.int64, equals(BigInt.parse('9223372036854775807')));
    });

    test('XdrAccountMergeResult with zero balance encode/decode', () {
      var original = XdrAccountMergeResult(XdrAccountMergeResultCode.ACCOUNT_MERGE_SUCCESS);
      original.sourceAccountBalance = XdrInt64(BigInt.zero);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrAccountMergeResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrAccountMergeResult.decode(input);

      expect(decoded.discriminant, equals(XdrAccountMergeResultCode.ACCOUNT_MERGE_SUCCESS));
      expect(decoded.sourceAccountBalance, isNotNull);
      expect(decoded.sourceAccountBalance!.int64, equals(BigInt.zero));
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

    test('should encode and decode inverted', () {
      final muxedAccount = XdrMuxedAccountMed25519(
        XdrUint64(BigInt.from(100)),
        XdrUint256(Uint8List.fromList(List.filled(32, 0xAB))),
      );

      final stream = XdrDataOutputStream();
      XdrMuxedAccountMed25519.encodeInverted(stream, muxedAccount);
      final bytes = Uint8List.fromList(stream.bytes);

      final decoded = XdrMuxedAccountMed25519.decodeInverted(XdrDataInputStream(bytes));
      expect(decoded.id.uint64, equals(BigInt.from(100)));
    });
  });

  group('XdrMuxedAccount discriminant setter', () {
    test('should set discriminant KEY_TYPE_ED25519', () {
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
