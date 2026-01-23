// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('XDR Transaction Types - Deep Branch Testing Part 4', () {
    // These tests target remaining uncovered branches in xdr_transaction.dart

    test('XdrOperationResult opBAD_AUTH encode/decode', () {
      var original = XdrOperationResult(XdrOperationResultCode.opBAD_AUTH);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrOperationResultCode.opBAD_AUTH.value));
    });

    test('XdrOperationResult opNOT_SUPPORTED encode/decode', () {
      var original = XdrOperationResult(XdrOperationResultCode.opNOT_SUPPORTED);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrOperationResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrOperationResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrOperationResultCode.opNOT_SUPPORTED.value));
    });

    test('XdrLedgerEntryChange LEDGER_ENTRY_REMOVED encode/decode', () {
      var account = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');

      var key = XdrLedgerKey(XdrLedgerEntryType.ACCOUNT);
      key.account = XdrLedgerKeyAccount(account);

      var change = XdrLedgerEntryChange(XdrLedgerEntryChangeType.LEDGER_ENTRY_REMOVED);
      change.removed = key;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerEntryChange.encode(output, change);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerEntryChange.decode(input);

      expect(decoded.discriminant.value, equals(XdrLedgerEntryChangeType.LEDGER_ENTRY_REMOVED.value));
    });

    test('XdrTransactionMeta V0 with empty operations encode/decode', () {
      var original = XdrTransactionMeta(0);
      original.operations = [];

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionMeta.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionMeta.decode(input);

      expect(decoded.discriminant, equals(0));
      expect(decoded.operations, isEmpty);
    });

    test('XdrTransactionMeta V1 with empty operations encode/decode', () {
      var txChanges = XdrLedgerEntryChanges([]);
      var metaV1 = XdrTransactionMetaV1(txChanges, []);

      var original = XdrTransactionMeta(1);
      original.v1 = metaV1;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionMeta.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionMeta.decode(input);

      expect(decoded.discriminant, equals(1));
      expect(decoded.v1!.operations, isEmpty);
    });

    test('XdrTransactionMeta V2 with empty operations encode/decode', () {
      var txChangesBefore = XdrLedgerEntryChanges([]);
      var txChangesAfter = XdrLedgerEntryChanges([]);
      var metaV2 = XdrTransactionMetaV2(txChangesBefore, [], txChangesAfter);

      var original = XdrTransactionMeta(2);
      original.v2 = metaV2;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionMeta.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionMeta.decode(input);

      expect(decoded.discriminant, equals(2));
      expect(decoded.v2!.operations, isEmpty);
    });

    test('XdrSorobanTransactionData encode/decode', () {
      var ext = XdrSorobanTransactionDataExt(0);
      var footprint = XdrLedgerFootprint([], []);
      var resources = XdrSorobanResources(footprint, XdrUint32(100000), XdrUint32(10000), XdrUint32(1000));

      var original = XdrSorobanTransactionData(ext, resources, XdrInt64(BigInt.from(1000)));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSorobanTransactionData.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSorobanTransactionData.decode(input);

      expect(decoded.ext.discriminant, equals(0));
      expect(decoded.resources.instructions.uint32, equals(100000));
    });

    test('XdrSorobanResources encode/decode', () {
      var address = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT);
      address.contractId = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xAA)));

      var key = XdrSCVal(XdrSCValType.SCV_U32);
      key.u32 = XdrUint32(1);

      var contractData = XdrLedgerKey(XdrLedgerEntryType.CONTRACT_DATA);
      contractData.contractData = XdrLedgerKeyContractData(
        address,
        key,
        XdrContractDataDurability.PERSISTENT,
      );

      var footprint = XdrLedgerFootprint([contractData], []);

      var original = XdrSorobanResources(footprint, XdrUint32(200000), XdrUint32(20000), XdrUint32(2000));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSorobanResources.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSorobanResources.decode(input);

      expect(decoded.footprint.readOnly.length, equals(1));
      expect(decoded.instructions.uint32, equals(200000));
    });
  });
}
