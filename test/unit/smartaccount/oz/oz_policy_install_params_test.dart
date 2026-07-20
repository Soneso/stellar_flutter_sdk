// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

OZSmartAccountSigner _delegated(String address) => OZDelegatedSigner(address);

OZSmartAccountSigner _external() => OZExternalSigner.ed25519(
      verifierAddress: 'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK',
      publicKey: Uint8List(32),
    );

void main() {
  group('OZSimpleThresholdPolicyParams', () {
    test('zeroThreshold throws SmartAccountValidationException with correct field', () {
      const params = OZSimpleThresholdPolicyParams(threshold: 0);
      try {
        params.toScVal();
        fail('Expected SmartAccountValidationException');
      } on SmartAccountValidationException catch (e) {
        expect(e, isA<SmartAccountInvalidInput>());
        expect(e.message, contains('Threshold must be greater than zero'));
      }
    });

    test('threshold of one builds ScVal map with single key', () {
      const params = OZSimpleThresholdPolicyParams(threshold: 1);
      final scVal = params.toScVal();
      expect(scVal.discriminant, XdrSCValType.SCV_MAP);
      final map = scVal.map;
      expect(map, isNotNull);
      expect(map!.length, 1);
      expect(map[0].key.sym, 'threshold');
      expect(map[0].val.u32?.uint32, 1);
    });

    test('large threshold value builds ScVal', () {
      const params = OZSimpleThresholdPolicyParams(threshold: 0x7FFFFFFE);
      final scVal = params.toScVal();
      expect(scVal.map![0].val.u32?.uint32, 0x7FFFFFFE);
    });

    test('ScVal map has threshold key', () {
      const params = OZSimpleThresholdPolicyParams(threshold: 5);
      final map = params.toScVal().map!;
      final keys = map.map((e) => e.key.sym).toList();
      expect(keys, contains('threshold'));
    });

    test('ScVal threshold value matches input', () {
      const params = OZSimpleThresholdPolicyParams(threshold: 42);
      final value = params.toScVal().map![0].val.u32!.uint32;
      expect(value, 42);
    });
  });

  group('OZWeightedThresholdPolicyParams', () {
    test('zero threshold throws SmartAccountValidationException', () {
      final params = OZWeightedThresholdPolicyParams(
        signerWeights: <OZSmartAccountSigner, int>{
          _delegated('GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX'): 1,
        },
        threshold: 0,
      );
      expect(() => params.toScVal(), throwsA(isA<SmartAccountValidationException>()));
    });

    test('empty signerWeights throws SmartAccountValidationException', () {
      final params = OZWeightedThresholdPolicyParams(
        signerWeights: const <OZSmartAccountSigner, int>{},
        threshold: 1,
      );
      expect(() => params.toScVal(), throwsA(isA<SmartAccountValidationException>()));
    });

    test('single signer builds ScVal', () {
      final params = OZWeightedThresholdPolicyParams(
        signerWeights: <OZSmartAccountSigner, int>{
          _delegated('GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX'): 50,
        },
        threshold: 50,
      );
      final scVal = params.toScVal();
      expect(scVal.discriminant, XdrSCValType.SCV_MAP);
      // Top-level keys: signer_weights then threshold (alphabetical).
      final keys = scVal.map!.map((e) => e.key.sym).toList();
      expect(keys, ['signer_weights', 'threshold']);
    });

    test('multiple signers builds ScVal', () {
      final params = OZWeightedThresholdPolicyParams(
        signerWeights: <OZSmartAccountSigner, int>{
          _delegated('GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX'): 50,
          _delegated('GBVRV25F7XA5I2L3ILSA6XW3OCWLKGGLG4OP2EHKTWC5IHQ3EV26FQLS'): 30,
        },
        threshold: 80,
      );
      final scVal = params.toScVal();
      final innerMap = scVal.map![0].val.map!;
      expect(innerMap.length, 2);
    });

    test('signer_weights map sorted in host key order', () {
      // Build with two signers; the inner map must come out in the host's
      // ScMap key order regardless of insertion order. The two same-shape
      // delegated-signer keys are fixed-width, so the host content order
      // equals the raw byte order of their encodings.
      final params = OZWeightedThresholdPolicyParams(
        signerWeights: <OZSmartAccountSigner, int>{
          _delegated('GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX'): 1,
          _delegated('GBVRV25F7XA5I2L3ILSA6XW3OCWLKGGLG4OP2EHKTWC5IHQ3EV26FQLS'): 2,
        },
        threshold: 1,
      );
      final innerEntries = params.toScVal().map![0].val.map!;
      // Verify the entries appear in deterministic order by encoded bytes.
      final firstKeyBytes = OZPolicyManager.scValToXdrBytes(innerEntries[0].key);
      final secondKeyBytes =
          OZPolicyManager.scValToXdrBytes(innerEntries[1].key);
      expect(_lexLess(firstKeyBytes, secondKeyBytes), isTrue);
    });

    test('top-level keys alphabetical: signer_weights then threshold', () {
      final params = OZWeightedThresholdPolicyParams(
        signerWeights: <OZSmartAccountSigner, int>{_external(): 1},
        threshold: 1,
      );
      final keys = params.toScVal().map!.map((e) => e.key.sym).toList();
      expect(keys, ['signer_weights', 'threshold']);
    });

    test('signer_weights map shape: address keys, U32 values', () {
      final params = OZWeightedThresholdPolicyParams(
        signerWeights: <OZSmartAccountSigner, int>{
          _delegated('GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX'): 7,
        },
        threshold: 7,
      );
      final innerMap = params.toScVal().map![0].val.map!;
      // Key is the signer ScVal (Vec); value is U32.
      expect(innerMap[0].val.u32?.uint32, 7);
    });

    test('threshold encoded as U32', () {
      final params = OZWeightedThresholdPolicyParams(
        signerWeights: <OZSmartAccountSigner, int>{_external(): 1},
        threshold: 100,
      );
      final thresholdValue = params.toScVal().map![1].val.u32?.uint32;
      expect(thresholdValue, 100);
    });

    test('mixed signer types: external and delegated', () {
      final params = OZWeightedThresholdPolicyParams(
        signerWeights: <OZSmartAccountSigner, int>{
          _delegated('GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX'): 30,
          _external(): 70,
        },
        threshold: 100,
      );
      final scVal = params.toScVal();
      final innerMap = scVal.map![0].val.map!;
      expect(innerMap.length, 2);
    });

    test('signer_weights value is map type', () {
      final params = OZWeightedThresholdPolicyParams(
        signerWeights: <OZSmartAccountSigner, int>{_external(): 1},
        threshold: 1,
      );
      final signerWeightsValue = params.toScVal().map![0].val;
      expect(signerWeightsValue.discriminant, XdrSCValType.SCV_MAP);
    });
  });

  group('OZSpendingLimitPolicyParams', () {
    test('zero amount throws SmartAccountValidationException', () {
      final params = OZSpendingLimitPolicyParams(
        spendingLimit: BigInt.zero,
        periodLedgers: 1,
      );
      expect(() => params.toScVal(), throwsA(isA<SmartAccountValidationException>()));
    });

    test('negative amount throws SmartAccountValidationException', () {
      final params = OZSpendingLimitPolicyParams(
        spendingLimit: BigInt.from(-1),
        periodLedgers: 1,
      );
      expect(() => params.toScVal(), throwsA(isA<SmartAccountValidationException>()));
    });

    test('zero periodLedgers throws SmartAccountValidationException', () {
      final params = OZSpendingLimitPolicyParams(
        spendingLimit: BigInt.from(100),
        periodLedgers: 0,
      );
      expect(() => params.toScVal(), throwsA(isA<SmartAccountValidationException>()));
    });

    test('valid input builds ScVal', () {
      final params = OZSpendingLimitPolicyParams(
        spendingLimit: BigInt.from(1000000000),
        periodLedgers: 17280,
      );
      final scVal = params.toScVal();
      expect(scVal.discriminant, XdrSCValType.SCV_MAP);
    });

    test('top-level keys alphabetical: period_ledgers then spending_limit', () {
      final params = OZSpendingLimitPolicyParams(
        spendingLimit: BigInt.from(100),
        periodLedgers: 1,
      );
      final keys = params.toScVal().map!.map((e) => e.key.sym).toList();
      expect(keys, ['period_ledgers', 'spending_limit']);
    });

    test('amount encoded as I128', () {
      final params = OZSpendingLimitPolicyParams(
        spendingLimit: BigInt.from(1234567),
        periodLedgers: 1,
      );
      final spendingLimitVal = params.toScVal().map![1].val;
      expect(spendingLimitVal.discriminant, XdrSCValType.SCV_I128);
    });

    test('periodLedgers encoded as U32', () {
      final params = OZSpendingLimitPolicyParams(
        spendingLimit: BigInt.from(100),
        periodLedgers: 720,
      );
      final value = params.toScVal().map![0].val.u32?.uint32;
      expect(value, 720);
    });

    test('large amount preserved as BigInt', () {
      final big = BigInt.parse('99999999999999999');
      final params = OZSpendingLimitPolicyParams(
        spendingLimit: big,
        periodLedgers: 1,
      );
      final scVal = params.toScVal();
      // I128 encoding round-trip will be tested elsewhere; here just
      // verify the call succeeds and emits an i128.
      expect(scVal.map![1].val.i128, isNotNull);
    });

    test('params class stores the precomputed base-units BigInt', () {
      final params = OZSpendingLimitPolicyParams(
        spendingLimit: BigInt.from(100) * BigInt.from(10000000),
        periodLedgers: 1,
      );
      expect(params.spendingLimit, BigInt.from(1000000000));
    });

    test('base-units value round-trips through the params class', () {
      final baseUnits =
          OZTransactionOperations.amountToBaseUnits('123.4567890', decimals: 7);
      final params = OZSpendingLimitPolicyParams(
        spendingLimit: baseUnits,
        periodLedgers: 1,
      );
      expect(params.spendingLimit, baseUnits);
    });
  });

  group('OZPolicyInstallParams sealed-class behaviour', () {
    test('OZSimpleThresholdPolicyParams is a OZPolicyInstallParams arm', () {
      const params = OZSimpleThresholdPolicyParams(threshold: 1);
      expect(params, isA<OZPolicyInstallParams>());
    });

    test('OZWeightedThresholdPolicyParams is a OZPolicyInstallParams arm', () {
      final params = OZWeightedThresholdPolicyParams(
        signerWeights: <OZSmartAccountSigner, int>{_external(): 1},
        threshold: 1,
      );
      expect(params, isA<OZPolicyInstallParams>());
    });

    test('OZSpendingLimitPolicyParams is a OZPolicyInstallParams arm', () {
      final params = OZSpendingLimitPolicyParams(
        spendingLimit: BigInt.from(1),
        periodLedgers: 1,
      );
      expect(params, isA<OZPolicyInstallParams>());
    });

    test('switch over OZPolicyInstallParams compiles exhaustively', () {
      String describe(OZPolicyInstallParams p) {
        return switch (p) {
          OZSimpleThresholdPolicyParams() => 'simple',
          OZWeightedThresholdPolicyParams() => 'weighted',
          OZSpendingLimitPolicyParams() => 'spending',
          OZRawPolicyParams() => 'raw',
        };
      }

      expect(
        describe(const OZSimpleThresholdPolicyParams(threshold: 1)),
        'simple',
      );
    });

    test('OZRawPolicyParams is a OZPolicyInstallParams arm', () {
      final params = OZRawPolicyParams(XdrSCVal.forVoid());
      expect(params, isA<OZPolicyInstallParams>());
    });

    test('OZRawPolicyParams.toScVal returns the wrapped value unchanged', () {
      final wrapped = XdrSCVal.forSymbol('payload');
      expect(identical(OZRawPolicyParams(wrapped).toScVal(), wrapped), isTrue);
    });

    test('OZRawPolicyParams equality by wrapped value', () {
      final a = OZRawPolicyParams(XdrSCVal.forU32(7));
      final b = OZRawPolicyParams(XdrSCVal.forU32(7));
      final c = OZRawPolicyParams(XdrSCVal.forU32(8));
      expect(a, b);
      expect(a, isNot(c));
    });

    test('OZSimpleThresholdPolicyParams equality by threshold', () {
      const a = OZSimpleThresholdPolicyParams(threshold: 5);
      const b = OZSimpleThresholdPolicyParams(threshold: 5);
      const c = OZSimpleThresholdPolicyParams(threshold: 6);
      expect(a, b);
      expect(a, isNot(c));
    });

    test('OZSpendingLimitPolicyParams equality by fields', () {
      final a = OZSpendingLimitPolicyParams(
        spendingLimit: BigInt.from(100),
        periodLedgers: 1,
      );
      final b = OZSpendingLimitPolicyParams(
        spendingLimit: BigInt.from(100),
        periodLedgers: 1,
      );
      final c = OZSpendingLimitPolicyParams(
        spendingLimit: BigInt.from(200),
        periodLedgers: 1,
      );
      expect(a, b);
      expect(a, isNot(c));
    });
  });
}

bool _lexLess(List<int> a, List<int> b) {
  final minLen = a.length < b.length ? a.length : b.length;
  for (var i = 0; i < minLen; i++) {
    final av = a[i] & 0xFF;
    final bv = b[i] & 0xFF;
    if (av != bv) return av < bv;
  }
  return a.length < b.length;
}
