// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('XDR Ledger Types - Additional Deep Branch Testing', () {
    test('XdrLedgerEntryV1 with null sponsoringID encode/decode', () {
      var v1 = XdrLedgerEntryV1(null, XdrLedgerEntryV1Ext(0));
      v1.sponsoringID = null;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerEntryV1.encode(output, v1);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerEntryV1.decode(input);

      expect(decoded.sponsoringID, isNull);
    });

    test('XdrLedgerEntry with all fields encode/decode', () {
      var accountId = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var data = XdrLedgerEntryData(XdrLedgerEntryType.ACCOUNT);
      var signerKey = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519);
      signerKey.ed25519 = XdrUint256(KeyPair.fromAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H').publicKey);
      var signer = XdrSigner(signerKey, XdrUint32(1));
      var account = XdrAccountEntry(
        accountId,
        XdrInt64(BigInt.from(10000000)),
        XdrSequenceNumber(BigInt.from(1)),
        XdrUint32(0),
        accountId,
        XdrUint32(0),
        XdrString32('test'),
        XdrThresholds(Uint8List.fromList([1, 2, 3, 4])),
        [signer],
        XdrAccountEntryExt(0),
      );
      data.account = account;

      var sponsoringID = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var v1 = XdrLedgerEntryV1(null, XdrLedgerEntryV1Ext(0));
      v1.sponsoringID = sponsoringID;

      var ext = XdrLedgerEntryExt(1);
      ext.v1 = v1;

      var entry = XdrLedgerEntry(
        XdrUint32(150),
        data,
        ext,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerEntry.encode(output, entry);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerEntry.decode(input);

      expect(decoded.lastModifiedLedgerSeq.uint32, equals(150));
      expect(decoded.ext.discriminant, equals(1));
      expect(decoded.ext.v1!.sponsoringID, isNotNull);
    });

    test('Complex nested XdrClaimPredicate AND with nested OR encode/decode', () {
      var innerOr1 = XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_UNCONDITIONAL);
      var innerOr2 = XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME);
      innerOr2.absBefore = XdrInt64(BigInt.from(9999999));

      var orPredicate = XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_OR);
      orPredicate.orPredicates = [innerOr1, innerOr2];

      var unconditional = XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_UNCONDITIONAL);

      var original = XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_AND);
      original.andPredicates = [orPredicate, unconditional];

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrClaimPredicate.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrClaimPredicate.decode(input);

      expect(decoded.discriminant.value, equals(XdrClaimPredicateType.CLAIM_PREDICATE_AND.value));
      expect(decoded.andPredicates!.length, equals(2));
      expect(decoded.andPredicates![0].discriminant.value, equals(XdrClaimPredicateType.CLAIM_PREDICATE_OR.value));
    });
  });
}
