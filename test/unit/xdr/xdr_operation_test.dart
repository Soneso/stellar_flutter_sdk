// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  // Tests for XDR Operation types that go beyond simple roundtrip encode/decode.
  // Simple roundtrips are covered by auto-generated tests in test/unit/xdr/generated/.

  group('XdrOperation optional sourceAccount', () {
    test('XdrOperation with no sourceAccount encode/decode', () {
      var body = XdrOperationBody(XdrOperationType.INFLATION);
      var original = XdrOperation(null, body);

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
      var original = XdrOperation(sourceAccount, body);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperation.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperation.decode(input);

      expect(decoded.sourceAccount, isNotNull);
      expect(decoded.sourceAccount!.discriminant.value, equals(XdrCryptoKeyType.KEY_TYPE_ED25519.value));
    });
  });

  group('XdrManageDataOp optional dataValue', () {
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
  });

  group('XdrSetOptionsOp optional fields', () {
    test('XdrSetOptionsOp with all fields null encode/decode', () {
      var original = XdrSetOptionsOp(null, null, null, null, null, null, null, null, null);

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

      var original = XdrSetOptionsOp(null, null, null, null, null, null, null, null, null);
      original.signer = signer;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSetOptionsOp.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSetOptionsOp.decode(input);

      expect(decoded.signer, isNotNull);
      expect(decoded.signer!.weight.uint32, equals(10));
    });

    test('XdrSetOptionsOp with threshold weights set via setters', () {
      var setOptionsOp = XdrSetOptionsOp(null, null, null, null, null, null, null, null, null);
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

      expect(decoded.setOptionsOp!.masterWeight, isNotNull);
      expect(decoded.setOptionsOp!.masterWeight!.uint32, equals(100));
    });
  });

  group('XdrOperationMeta edge cases', () {
    test('XdrOperationMeta with empty changes', () {
      var changes = XdrLedgerEntryChanges([]);

      var original = XdrOperationMeta(changes);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationMeta.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationMeta.decode(input);

      expect(decoded.changes.ledgerEntryChanges, isEmpty);
    });
  });

  group('XdrOperationResult union branches', () {
    test('XdrOperationResult opINNER with nested result', () {
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

    test('XdrOperationResult opBAD_AUTH has null tr', () {
      var original = XdrOperationResult(XdrOperationResultCode.opBAD_AUTH);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrOperationResultCode.opBAD_AUTH.value));
      expect(decoded.tr, isNull);
    });
  });
}
