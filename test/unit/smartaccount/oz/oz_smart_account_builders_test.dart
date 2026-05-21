// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

const String kValidGAddress =
    'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';
const String kValidContractId =
    'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK';

String get kValidContractIdAlt {
  final altBytes = Uint8List.fromList(
    List<int>.generate(32, (i) => (i * 7 + 3) & 0xFF),
  );
  return StrKey.encodeContractId(altBytes);
}

Uint8List _secp256r1Pub({int seed = 0x10}) {
  final out = Uint8List(65);
  out[0] = 0x04;
  for (var i = 1; i < 65; i++) {
    out[i] = (i + seed) & 0xFF;
  }
  return out;
}

Uint8List _ed25519Pub({int seed = 0x20}) {
  final out = Uint8List(32);
  for (var i = 0; i < 32; i++) {
    out[i] = (i + seed) & 0xFF;
  }
  return out;
}

Uint8List _credentialId({int seed = 0xA0, int length = 16}) {
  final out = Uint8List(length);
  for (var i = 0; i < length; i++) {
    out[i] = (i + seed) & 0xFF;
  }
  return out;
}

void main() {
  // ==========================================================================
  // Signer builder functions
  // ==========================================================================

  group('signer key and dedup', () {
    test('testGetSignerKey_delegatedSigner_returnsUniqueKeyWithDelegatedPrefix',
        () {
      final signer =
          OZSmartAccountBuilders.createDelegatedSigner(kValidGAddress);
      final key = OZSmartAccountBuilders.getSignerKey(signer);
      expect(key, startsWith('delegated:'));
      expect(key, contains(kValidGAddress));
    });

    test(
        'testGetSignerKey_externalSigner_returnsUniqueKeyWithExternalPrefixAndHexKeyData',
        () {
      final signer = OZSmartAccountBuilders.createWebAuthnSigner(
        webauthnVerifierAddress: kValidContractId,
        publicKey: _secp256r1Pub(),
        credentialId: _credentialId(),
      );
      final key = OZSmartAccountBuilders.getSignerKey(signer);
      expect(key, startsWith('external:'));
      expect(key, contains(kValidContractId));
    });

    test('testGetSignerKey_matchesDelegatedSignerUniqueKey', () {
      final signer =
          OZSmartAccountBuilders.createDelegatedSigner(kValidGAddress);
      expect(OZSmartAccountBuilders.getSignerKey(signer),
          equals(signer.uniqueKey));
    });

    test('testGetSignerKey_matchesExternalSignerUniqueKey', () {
      final signer = OZSmartAccountBuilders.createWebAuthnSigner(
        webauthnVerifierAddress: kValidContractId,
        publicKey: _secp256r1Pub(),
        credentialId: _credentialId(),
      );
      expect(OZSmartAccountBuilders.getSignerKey(signer),
          equals(signer.uniqueKey));
    });

    test('testCollectUniqueSigners_emptyList_returnsEmpty', () {
      expect(
          OZSmartAccountBuilders.collectUniqueSigners(<OZSmartAccountSigner>[]),
          isEmpty);
    });

    test('testCollectUniqueSigners_singleSigner_returnsSameSigner', () {
      final s =
          OZSmartAccountBuilders.createDelegatedSigner(kValidGAddress);
      final out = OZSmartAccountBuilders.collectUniqueSigners([s]);
      expect(out, hasLength(1));
      expect(out.first, same(s));
    });

    test(
        'testCollectUniqueSigners_duplicateDelegatedSigners_deduplicatesToOne',
        () {
      final a =
          OZSmartAccountBuilders.createDelegatedSigner(kValidGAddress);
      final b =
          OZSmartAccountBuilders.createDelegatedSigner(kValidGAddress);
      final out = OZSmartAccountBuilders.collectUniqueSigners([a, b, a]);
      expect(out, hasLength(1));
    });

    test(
        'testCollectUniqueSigners_duplicateExternalSigners_deduplicatesToOne',
        () {
      final a = OZSmartAccountBuilders.createExternalSigner(
        kValidContractId,
        _ed25519Pub(),
      );
      final b = OZSmartAccountBuilders.createExternalSigner(
        kValidContractId,
        _ed25519Pub(),
      );
      final out = OZSmartAccountBuilders.collectUniqueSigners([a, b]);
      expect(out, hasLength(1));
    });

    test('testCollectUniqueSigners_differentSigners_allKept', () {
      final a =
          OZSmartAccountBuilders.createDelegatedSigner(kValidGAddress);
      final b =
          OZSmartAccountBuilders.createDelegatedSigner(kValidContractId);
      final out = OZSmartAccountBuilders.collectUniqueSigners([a, b]);
      expect(out, hasLength(2));
    });

    test('testCollectUniqueSigners_preservesOrderFirstOccurrence', () {
      final a =
          OZSmartAccountBuilders.createDelegatedSigner(kValidGAddress);
      final b =
          OZSmartAccountBuilders.createDelegatedSigner(kValidContractId);
      final out = OZSmartAccountBuilders.collectUniqueSigners([a, b, a]);
      expect(out.first, same(a));
      expect(out.last, same(b));
    });

    test(
        'testCollectUniqueSigners_mixedDuplicates_preservesInsertionOrder',
        () {
      final d =
          OZSmartAccountBuilders.createDelegatedSigner(kValidGAddress);
      final e = OZSmartAccountBuilders.createExternalSigner(
        kValidContractId,
        _ed25519Pub(),
      );
      final dDup =
          OZSmartAccountBuilders.createDelegatedSigner(kValidGAddress);
      final out = OZSmartAccountBuilders.collectUniqueSigners([d, e, dDup]);
      expect(out, hasLength(2));
      expect(out.first, same(d));
      expect(out.last, same(e));
    });
  });

  group('describeSignerType', () {
    test('testDescribeSignerType_delegatedSigner_returnsStellarAccount', () {
      final s =
          OZSmartAccountBuilders.createDelegatedSigner(kValidGAddress);
      expect(OZSmartAccountBuilders.describeSignerType(s), 'Stellar Account');
    });

    test('testDescribeSignerType_webAuthnSigner_returnsPasskeyWebAuthn', () {
      final s = OZSmartAccountBuilders.createWebAuthnSigner(
        webauthnVerifierAddress: kValidContractId,
        publicKey: _secp256r1Pub(),
        credentialId: _credentialId(),
      );
      expect(
          OZSmartAccountBuilders.describeSignerType(s), 'Passkey (WebAuthn)');
    });

    test(
        'testDescribeSignerType_externalSignerWithOtherKeySize_returnsExternalVerifier',
        () {
      // 16-byte key is neither 32 (Ed25519) nor >65 (WebAuthn).
      final s = OZSmartAccountBuilders.createExternalSigner(
        kValidContractId,
        Uint8List(16),
      );
      expect(
          OZSmartAccountBuilders.describeSignerType(s), 'External Verifier');
    });

    test('testDescribeSignerType_ed25519Signer_returnsEd25519', () {
      final s = OZSmartAccountBuilders.createEd25519Signer(
        ed25519VerifierAddress: kValidContractId,
        publicKey: _ed25519Pub(),
      );
      expect(OZSmartAccountBuilders.describeSignerType(s), 'Ed25519');
    });
  });

  group('signersEqual', () {
    test('testSignersEqual_sameDelegatedSigner_returnsTrue', () {
      final a =
          OZSmartAccountBuilders.createDelegatedSigner(kValidGAddress);
      final b =
          OZSmartAccountBuilders.createDelegatedSigner(kValidGAddress);
      expect(OZSmartAccountBuilders.signersEqual(a, b), isTrue);
    });

    test('testSignersEqual_differentDelegatedSigners_returnsFalse', () {
      final a =
          OZSmartAccountBuilders.createDelegatedSigner(kValidGAddress);
      final b =
          OZSmartAccountBuilders.createDelegatedSigner(kValidContractId);
      expect(OZSmartAccountBuilders.signersEqual(a, b), isFalse);
    });

    test('testSignersEqual_sameExternalSigner_returnsTrue', () {
      final a = OZSmartAccountBuilders.createExternalSigner(
          kValidContractId, _ed25519Pub());
      final b = OZSmartAccountBuilders.createExternalSigner(
          kValidContractId, _ed25519Pub());
      expect(OZSmartAccountBuilders.signersEqual(a, b), isTrue);
    });

    test('testSignersEqual_externalSignersDifferentVerifier_returnsFalse', () {
      final a = OZSmartAccountBuilders.createExternalSigner(
          kValidContractId, _ed25519Pub());
      final b = OZSmartAccountBuilders.createExternalSigner(
          kValidContractIdAlt, _ed25519Pub());
      expect(OZSmartAccountBuilders.signersEqual(a, b), isFalse);
    });

    test('testSignersEqual_externalSignersDifferentKeyData_returnsFalse', () {
      final a = OZSmartAccountBuilders.createExternalSigner(
          kValidContractId, _ed25519Pub(seed: 1));
      final b = OZSmartAccountBuilders.createExternalSigner(
          kValidContractId, _ed25519Pub(seed: 2));
      expect(OZSmartAccountBuilders.signersEqual(a, b), isFalse);
    });

    test('testSignersEqual_delegatedVsExternal_returnsFalse', () {
      final a =
          OZSmartAccountBuilders.createDelegatedSigner(kValidGAddress);
      final b = OZSmartAccountBuilders.createExternalSigner(
          kValidContractId, _ed25519Pub());
      expect(OZSmartAccountBuilders.signersEqual(a, b), isFalse);
    });

    test('testSignersEqual_externalVsDelegated_returnsFalse', () {
      final a = OZSmartAccountBuilders.createExternalSigner(
          kValidContractId, _ed25519Pub());
      final b =
          OZSmartAccountBuilders.createDelegatedSigner(kValidGAddress);
      expect(OZSmartAccountBuilders.signersEqual(a, b), isFalse);
    });
  });

  group('signerMatchesCredentialId', () {
    test('testSignerMatchesCredentialId_matchingCredentialId_returnsTrue', () {
      final cred = _credentialId();
      final signer = OZSmartAccountBuilders.createWebAuthnSigner(
        webauthnVerifierAddress: kValidContractId,
        publicKey: _secp256r1Pub(),
        credentialId: cred,
      );
      final encoded = base64Url.encode(cred);
      expect(
          OZSmartAccountBuilders.signerMatchesCredentialId(signer, encoded),
          isTrue);
    });

    test(
        'testSignerMatchesCredentialId_nonMatchingCredentialId_returnsFalse',
        () {
      final signer = OZSmartAccountBuilders.createWebAuthnSigner(
        webauthnVerifierAddress: kValidContractId,
        publicKey: _secp256r1Pub(),
        credentialId: _credentialId(seed: 0xA0),
      );
      final differentEncoded = base64Url.encode(
        _credentialId(seed: 0xB0),
      );
      expect(
          OZSmartAccountBuilders.signerMatchesCredentialId(
              signer, differentEncoded),
          isFalse);
    });

    test('testSignerMatchesCredentialId_delegatedSigner_returnsFalse', () {
      final signer =
          OZSmartAccountBuilders.createDelegatedSigner(kValidGAddress);
      expect(
          OZSmartAccountBuilders.signerMatchesCredentialId(signer, 'abc'),
          isFalse);
    });

    test(
        'testSignerMatchesCredentialId_emptyCredentialIdString_returnsFalse',
        () {
      final signer = OZSmartAccountBuilders.createWebAuthnSigner(
        webauthnVerifierAddress: kValidContractId,
        publicKey: _secp256r1Pub(),
        credentialId: _credentialId(),
      );
      expect(
          OZSmartAccountBuilders.signerMatchesCredentialId(signer, ''),
          isFalse);
    });

    test(
        'testSignerMatchesCredentialId_acceptsPaddedAndUnpaddedBase64UrlInputs',
        () {
      // A 1-byte credential ID is the shortest input that produces a
      // padded Base64URL string ("AQ==" padded vs "AQ" unpadded). The
      // matcher must treat both forms as equivalent so callers using
      // either convention interoperate.
      final signer = OZSmartAccountBuilders.createWebAuthnSigner(
        webauthnVerifierAddress: kValidContractId,
        publicKey: _secp256r1Pub(),
        credentialId: Uint8List.fromList([0x01]),
      );
      expect(
          OZSmartAccountBuilders.signerMatchesCredentialId(signer, 'AQ=='),
          isTrue);
      expect(
          OZSmartAccountBuilders.signerMatchesCredentialId(signer, 'AQ'),
          isTrue);
    });
  });

  group('signerMatchesAddress', () {
    test(
        'testSignerMatchesAddress_delegatedSignerMatchingAddress_returnsTrue',
        () {
      final signer =
          OZSmartAccountBuilders.createDelegatedSigner(kValidGAddress);
      expect(
          OZSmartAccountBuilders.signerMatchesAddress(signer, kValidGAddress),
          isTrue);
    });

    test(
        'testSignerMatchesAddress_delegatedSignerDifferentAddress_returnsFalse',
        () {
      final signer =
          OZSmartAccountBuilders.createDelegatedSigner(kValidGAddress);
      expect(
          OZSmartAccountBuilders.signerMatchesAddress(
              signer, kValidContractId),
          isFalse);
    });

    test('testSignerMatchesAddress_externalSigner_returnsFalse', () {
      final signer = OZSmartAccountBuilders.createExternalSigner(
          kValidContractId, _ed25519Pub());
      expect(
          OZSmartAccountBuilders.signerMatchesAddress(
              signer, kValidContractId),
          isFalse);
    });

    test('testSignerMatchesAddress_webAuthnSigner_returnsFalse', () {
      final signer = OZSmartAccountBuilders.createWebAuthnSigner(
        webauthnVerifierAddress: kValidContractId,
        publicKey: _secp256r1Pub(),
        credentialId: _credentialId(),
      );
      expect(
          OZSmartAccountBuilders.signerMatchesAddress(
              signer, kValidContractId),
          isFalse);
    });
  });

  group('isDelegatedSigner / isExternalSigner', () {
    test('testIsDelegatedSigner_withDelegatedSigner_returnsTrue', () {
      final s =
          OZSmartAccountBuilders.createDelegatedSigner(kValidGAddress);
      expect(OZSmartAccountBuilders.isDelegatedSigner(s), isTrue);
    });

    test('testIsDelegatedSigner_withExternalSigner_returnsFalse', () {
      final s = OZSmartAccountBuilders.createExternalSigner(
          kValidContractId, _ed25519Pub());
      expect(OZSmartAccountBuilders.isDelegatedSigner(s), isFalse);
    });

    test('testIsExternalSigner_withExternalSigner_returnsTrue', () {
      final s = OZSmartAccountBuilders.createExternalSigner(
          kValidContractId, _ed25519Pub());
      expect(OZSmartAccountBuilders.isExternalSigner(s), isTrue);
    });

    test('testIsExternalSigner_withDelegatedSigner_returnsFalse', () {
      final s =
          OZSmartAccountBuilders.createDelegatedSigner(kValidGAddress);
      expect(OZSmartAccountBuilders.isExternalSigner(s), isFalse);
    });

    test('testIsDelegatedSigner_webAuthnSigner_returnsFalse', () {
      final s = OZSmartAccountBuilders.createWebAuthnSigner(
        webauthnVerifierAddress: kValidContractId,
        publicKey: _secp256r1Pub(),
        credentialId: _credentialId(),
      );
      expect(OZSmartAccountBuilders.isDelegatedSigner(s), isFalse);
    });

    test('testIsExternalSigner_webAuthnSigner_returnsTrue', () {
      final s = OZSmartAccountBuilders.createWebAuthnSigner(
        webauthnVerifierAddress: kValidContractId,
        publicKey: _secp256r1Pub(),
        credentialId: _credentialId(),
      );
      expect(OZSmartAccountBuilders.isExternalSigner(s), isTrue);
    });
  });

  group('signerMatchesCredential (raw bytes)', () {
    test('testSignerMatchesCredential_matchingCredentialBytes_returnsTrue', () {
      final cred = _credentialId();
      final s = OZSmartAccountBuilders.createWebAuthnSigner(
        webauthnVerifierAddress: kValidContractId,
        publicKey: _secp256r1Pub(),
        credentialId: cred,
      );
      expect(OZSmartAccountBuilders.signerMatchesCredential(s, cred), isTrue);
    });

    test(
        'testSignerMatchesCredential_nonMatchingCredentialBytes_returnsFalse',
        () {
      final s = OZSmartAccountBuilders.createWebAuthnSigner(
        webauthnVerifierAddress: kValidContractId,
        publicKey: _secp256r1Pub(),
        credentialId: _credentialId(seed: 1),
      );
      expect(
          OZSmartAccountBuilders.signerMatchesCredential(
              s, _credentialId(seed: 2)),
          isFalse);
    });

    test('testSignerMatchesCredential_delegatedSigner_returnsFalse', () {
      final s =
          OZSmartAccountBuilders.createDelegatedSigner(kValidGAddress);
      expect(
          OZSmartAccountBuilders.signerMatchesCredential(s, _credentialId()),
          isFalse);
    });
  });

  group('credential id extraction', () {
    test('testGetCredentialIdFromSigner_delegatedSigner_returnsNull', () {
      final s =
          OZSmartAccountBuilders.createDelegatedSigner(kValidGAddress);
      expect(OZSmartAccountBuilders.getCredentialIdFromSigner(s), isNull);
    });

    test(
        'testGetCredentialIdFromSigner_webAuthnSigner_returnsCredentialIdBytes',
        () {
      final cred = _credentialId();
      final s = OZSmartAccountBuilders.createWebAuthnSigner(
        webauthnVerifierAddress: kValidContractId,
        publicKey: _secp256r1Pub(),
        credentialId: cred,
      );
      expect(
          OZSmartAccountBuilders.getCredentialIdFromSigner(s), equals(cred));
    });

    test(
        'testGetCredentialIdFromSigner_webAuthnSigner_returnsOnlyCredentialIdPortion',
        () {
      final cred = _credentialId(length: 8);
      final s = OZSmartAccountBuilders.createWebAuthnSigner(
        webauthnVerifierAddress: kValidContractId,
        publicKey: _secp256r1Pub(),
        credentialId: cred,
      );
      final extracted =
          OZSmartAccountBuilders.getCredentialIdFromSigner(s);
      expect(extracted, isNotNull);
      expect(extracted!.length, cred.length);
      expect(extracted, cred);
    });

    test('testGetCredentialIdStringFromSigner_delegatedSigner_returnsNull', () {
      final s =
          OZSmartAccountBuilders.createDelegatedSigner(kValidGAddress);
      expect(
          OZSmartAccountBuilders.getCredentialIdStringFromSigner(s), isNull);
    });

    test(
        'testGetCredentialIdStringFromSigner_webAuthnSigner_roundTripsWithMatchFunction',
        () {
      final cred = _credentialId();
      final s = OZSmartAccountBuilders.createWebAuthnSigner(
        webauthnVerifierAddress: kValidContractId,
        publicKey: _secp256r1Pub(),
        credentialId: cred,
      );
      final encoded =
          OZSmartAccountBuilders.getCredentialIdStringFromSigner(s);
      expect(encoded, isNotNull);
      expect(
          OZSmartAccountBuilders.signerMatchesCredentialId(s, encoded!),
          isTrue);
    });

    test(
        'testGetCredentialIdStringFromSigner_webAuthnSigner_outputHasNoBase64Padding',
        () {
      // A 1-byte credential ID encodes to a Base64URL string with two
      // padding characters; the helper must strip them so the output
      // matches the canonical unpadded form.
      final s = OZSmartAccountBuilders.createWebAuthnSigner(
        webauthnVerifierAddress: kValidContractId,
        publicKey: _secp256r1Pub(),
        credentialId: Uint8List.fromList([0x01]),
      );
      final encoded =
          OZSmartAccountBuilders.getCredentialIdStringFromSigner(s);
      expect(encoded, isNotNull);
      expect(encoded!.endsWith('='), isFalse);
    });
  });

  group('builder validation', () {
    test('testCreateExternalSigner_invalidCAddress_throwsInvalidAddress', () {
      expect(
        () => OZSmartAccountBuilders.createExternalSigner(
          'NOT_A_VALID_CONTRACT',
          _ed25519Pub(),
        ),
        throwsA(isA<InvalidAddress>()),
      );
    });

    test('testCreateWebAuthnSigner_invalidCAddress_throwsInvalidAddress', () {
      expect(
        () => OZSmartAccountBuilders.createWebAuthnSigner(
          webauthnVerifierAddress: 'NOT_A_VALID_CONTRACT',
          publicKey: _secp256r1Pub(),
          credentialId: _credentialId(),
        ),
        throwsA(isA<InvalidAddress>()),
      );
    });

    test('testCreateEd25519Signer_invalidCAddress_throwsInvalidAddress', () {
      expect(
        () => OZSmartAccountBuilders.createEd25519Signer(
          ed25519VerifierAddress: 'NOT_A_VALID_CONTRACT',
          publicKey: _ed25519Pub(),
        ),
        throwsA(isA<InvalidAddress>()),
      );
    });
  });

  // ==========================================================================
  // Policy parameter builders
  // ==========================================================================

  group('OZSmartAccountBuilders — createThresholdParams', () {
    test('testCreateThresholdParams_thresholdZero_throwsInvalidInput', () {
      expect(() => OZSmartAccountBuilders.createThresholdParams(0),
          throwsA(isA<InvalidInput>()));
    });

    test('testCreateThresholdParams_thresholdNegative_throwsInvalidInput', () {
      expect(() => OZSmartAccountBuilders.createThresholdParams(-1),
          throwsA(isA<InvalidInput>()));
    });

    test('testCreateThresholdParams_happyPath', () {
      final p = OZSmartAccountBuilders.createThresholdParams(2);
      expect(p.threshold, 2);
    });

    test('testCreateThresholdParams_thresholdOne_succeeds', () {
      final p = OZSmartAccountBuilders.createThresholdParams(1);
      expect(p.threshold, 1);
    });

    test('testCreateThresholdParams_returnsOZSimpleThresholdParams', () {
      final p = OZSmartAccountBuilders.createThresholdParams(3);
      expect(p, isA<OZSimpleThresholdParams>());
    });
  });

  group('OZSmartAccountBuilders — createWeightedThresholdParams', () {
    test(
        'testCreateWeightedThresholdParams_emptySignerWeights_throwsInvalidInput',
        () {
      expect(
        () => OZSmartAccountBuilders.createWeightedThresholdParams(
          threshold: 1,
          signerWeights: <OZSmartAccountSigner, int>{},
        ),
        throwsA(isA<InvalidInput>()),
      );
    });

    test(
        'testCreateWeightedThresholdParams_zeroWeight_throwsInvalidInput', () {
      final s =
          OZSmartAccountBuilders.createDelegatedSigner(kValidGAddress);
      expect(
        () => OZSmartAccountBuilders.createWeightedThresholdParams(
          threshold: 1,
          signerWeights: <OZSmartAccountSigner, int>{s: 0},
        ),
        throwsA(isA<InvalidInput>()),
      );
    });

    test(
        'testCreateWeightedThresholdParams_totalWeightLessThanThreshold_throwsInvalidInput',
        () {
      final s =
          OZSmartAccountBuilders.createDelegatedSigner(kValidGAddress);
      expect(
        () => OZSmartAccountBuilders.createWeightedThresholdParams(
          threshold: 100,
          signerWeights: <OZSmartAccountSigner, int>{s: 50},
        ),
        throwsA(isA<InvalidInput>()),
      );
    });

    test(
        'testCreateWeightedThresholdParams_thresholdZero_throwsInvalidInput',
        () {
      final s =
          OZSmartAccountBuilders.createDelegatedSigner(kValidGAddress);
      expect(
        () => OZSmartAccountBuilders.createWeightedThresholdParams(
          threshold: 0,
          signerWeights: <OZSmartAccountSigner, int>{s: 1},
        ),
        throwsA(isA<InvalidInput>()),
      );
    });

    test('testCreateWeightedThresholdParams_happyPath', () {
      final s =
          OZSmartAccountBuilders.createDelegatedSigner(kValidGAddress);
      final p = OZSmartAccountBuilders.createWeightedThresholdParams(
        threshold: 5,
        signerWeights: <OZSmartAccountSigner, int>{s: 5},
      );
      expect(p.threshold, 5);
      expect(p.signerWeights, hasLength(1));
    });

    test(
        'testCreateWeightedThresholdParams_returnsOZWeightedThresholdParams',
        () {
      final s =
          OZSmartAccountBuilders.createDelegatedSigner(kValidGAddress);
      final p = OZSmartAccountBuilders.createWeightedThresholdParams(
        threshold: 1,
        signerWeights: <OZSmartAccountSigner, int>{s: 1},
      );
      expect(p, isA<OZWeightedThresholdParams>());
    });
  });

  group('OZSmartAccountBuilders — createSpendingLimitParams', () {
    test(
        'testCreateSpendingLimitParams_periodLedgersZero_throwsInvalidInput',
        () {
      expect(
        () => OZSmartAccountBuilders.createSpendingLimitParams(
          spendingLimit: '100',
          periodLedgers: 0,
        ),
        throwsA(isA<InvalidInput>()),
      );
    });

    test('testCreateSpendingLimitParams_zeroAmount_throwsInvalidAmount', () {
      expect(
        () => OZSmartAccountBuilders.createSpendingLimitParams(
          spendingLimit: '0',
          periodLedgers: 100,
        ),
        throwsA(isA<InvalidAmount>()),
      );
    });

    test('testCreateSpendingLimitParams_happyPath', () {
      final p = OZSmartAccountBuilders.createSpendingLimitParams(
        spendingLimit: '100',
        periodLedgers: Util.ledgersPerDay,
      );
      expect(p.spendingLimit, BigInt.parse('1000000000'));
      expect(p.periodLedgers, Util.ledgersPerDay);
    });

    test('testCreateSpendingLimitParams_returnsOZSpendingLimitParams', () {
      final p = OZSmartAccountBuilders.createSpendingLimitParams(
        spendingLimit: '10.5',
        periodLedgers: Util.ledgersPerHour,
      );
      expect(p, isA<OZSpendingLimitParams>());
    });

    test(
        'testCreateSpendingLimitParams_fractionalAmount_convertsToStroops', () {
      final p = OZSmartAccountBuilders.createSpendingLimitParams(
        spendingLimit: '1.5',
        periodLedgers: 100,
      );
      expect(p.spendingLimit, BigInt.parse('15000000'));
    });
  });

  group('OZSimpleThresholdParams', () {
    test('testOZSimpleThresholdParams_thresholdIsStored', () {
      const p = OZSimpleThresholdParams(threshold: 7);
      expect(p.threshold, 7);
    });
  });

  group('OZWeightedThresholdParams', () {
    test('testOZWeightedThresholdParams_fieldsAreStored', () {
      final s =
          OZSmartAccountBuilders.createDelegatedSigner(kValidGAddress);
      final p = OZWeightedThresholdParams(
        threshold: 3,
        signerWeights: {s: 3},
      );
      expect(p.threshold, 3);
      expect(p.signerWeights, hasLength(1));
    });
  });

  group('OZSpendingLimitParams', () {
    test('testOZSpendingLimitParams_fieldsAreAccessible', () {
      final p = OZSmartAccountBuilders.createSpendingLimitParams(
        spendingLimit: '50',
        periodLedgers: 720,
      );
      expect(p.spendingLimit > BigInt.zero, isTrue);
      expect(p.periodLedgers, 720);
    });
  });
}
