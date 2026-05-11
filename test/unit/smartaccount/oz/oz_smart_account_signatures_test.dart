// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

Uint8List _bytes(int length, [int seed = 0]) {
  final out = Uint8List(length);
  for (var i = 0; i < length; i++) {
    out[i] = (i + seed) & 0xFF;
  }
  return out;
}

Uint8List _signature64([int seed = 1]) => _bytes(64, seed);
Uint8List _ed25519Pub([int seed = 2]) => _bytes(32, seed);

void main() {
  group('OZWebAuthnSignature', () {
    test('testWebAuthnToScVal_returnsMapType', () {
      final sig = OZWebAuthnSignature(
        authenticatorData: _bytes(16),
        clientData: _bytes(20),
        signature: _signature64(),
      );
      expect(sig.toScVal().discriminant, XdrSCValType.SCV_MAP);
    });

    test('testWebAuthnToScVal_hasExactlyThreeEntries', () {
      final sig = OZWebAuthnSignature(
        authenticatorData: _bytes(16),
        clientData: _bytes(20),
        signature: _signature64(),
      );
      expect(sig.toScVal().map?.length, 3);
    });

    test('testWebAuthnToScVal_keysInAlphabeticalOrder', () {
      final sig = OZWebAuthnSignature(
        authenticatorData: _bytes(16),
        clientData: _bytes(20),
        signature: _signature64(),
      );
      final keys = sig.toScVal().map!.map((e) => e.key.sym).toList();
      expect(keys, ['authenticator_data', 'client_data', 'signature']);
    });

    test('testWebAuthnToScVal_authenticatorDataEntry', () {
      final ad = _bytes(16, 5);
      final sig = OZWebAuthnSignature(
        authenticatorData: ad,
        clientData: _bytes(20),
        signature: _signature64(),
      );
      final entry = sig.toScVal().map![0];
      expect(entry.key.sym, 'authenticator_data');
      expect(entry.val.bytes!.sCBytes, ad);
    });

    test('testWebAuthnToScVal_clientDataEntry', () {
      final cd = _bytes(20, 9);
      final sig = OZWebAuthnSignature(
        authenticatorData: _bytes(16),
        clientData: cd,
        signature: _signature64(),
      );
      final entry = sig.toScVal().map![1];
      expect(entry.key.sym, 'client_data');
      expect(entry.val.bytes!.sCBytes, cd);
    });

    test('testWebAuthnToScVal_signatureEntry', () {
      final s = _signature64(11);
      final sig = OZWebAuthnSignature(
        authenticatorData: _bytes(16),
        clientData: _bytes(20),
        signature: s,
      );
      final entry = sig.toScVal().map![2];
      expect(entry.key.sym, 'signature');
      expect(entry.val.bytes!.sCBytes, s);
    });

    test('testWebAuthnToScVal_allZeroBytes', () {
      final sig = OZWebAuthnSignature(
        authenticatorData: Uint8List(16),
        clientData: Uint8List(20),
        signature: Uint8List(64),
      );
      expect(sig.toScVal().map?.length, 3);
    });

    test('testWebAuthnToScVal_emptyAuthenticatorDataAllowed', () {
      final sig = OZWebAuthnSignature(
        authenticatorData: Uint8List(0),
        clientData: _bytes(10),
        signature: _signature64(),
      );
      expect(sig.toScVal().map?.length, 3);
    });

    test('testWebAuthnToScVal_emptyClientDataAllowed', () {
      final sig = OZWebAuthnSignature(
        authenticatorData: _bytes(16),
        clientData: Uint8List(0),
        signature: _signature64(),
      );
      expect(sig.toScVal().map?.length, 3);
    });

    test('testWebAuthnToScVal_largeAuthenticatorData', () {
      final sig = OZWebAuthnSignature(
        authenticatorData: _bytes(2048),
        clientData: _bytes(20),
        signature: _signature64(),
      );
      expect(sig.toScVal().map?.length, 3);
      expect(sig.toScVal().map![0].val.bytes!.sCBytes.length, 2048);
    });

    test('testWebAuthnToScVal_calledTwiceReturnsSameStructure', () {
      final sig = OZWebAuthnSignature(
        authenticatorData: _bytes(16),
        clientData: _bytes(20),
        signature: _signature64(),
      );
      final first = sig.toScVal();
      final second = sig.toScVal();
      expect(first.map!.length, second.map!.length);
      for (var i = 0; i < first.map!.length; i++) {
        expect(first.map![i].key.sym, second.map![i].key.sym);
        expect(first.map![i].val.bytes!.sCBytes,
            second.map![i].val.bytes!.sCBytes);
      }
    });

    test('testWebAuthnToScVal_keyNameIsClientData_notClientDataJson', () {
      final sig = OZWebAuthnSignature(
        authenticatorData: _bytes(16),
        clientData: _bytes(20),
        signature: _signature64(),
      );
      final keys = sig.toScVal().map!.map((e) => e.key.sym).toList();
      expect(keys.contains('client_data'), isTrue);
      expect(keys.contains('client_data_json'), isFalse);
    });

    test('testWebAuthnToScVal_matchesManualScvConstruction', () {
      final ad = _bytes(16);
      final cd = _bytes(20);
      final s = _signature64();
      final sig = OZWebAuthnSignature(
        authenticatorData: ad,
        clientData: cd,
        signature: s,
      );
      final expected = XdrSCVal.forMap([
        XdrSCMapEntry(
          XdrSCVal.forSymbol('authenticator_data'),
          XdrSCVal.forBytes(ad),
        ),
        XdrSCMapEntry(
          XdrSCVal.forSymbol('client_data'),
          XdrSCVal.forBytes(cd),
        ),
        XdrSCMapEntry(
          XdrSCVal.forSymbol('signature'),
          XdrSCVal.forBytes(s),
        ),
      ]);
      final actual = sig.toScVal();
      expect(actual.map!.length, expected.map!.length);
      for (var i = 0; i < actual.map!.length; i++) {
        expect(actual.map![i].key.sym, expected.map![i].key.sym);
        expect(actual.map![i].val.bytes!.sCBytes,
            expected.map![i].val.bytes!.sCBytes);
      }
    });

    test('testWebAuthnToScVal_inputMutationDoesNotAffectOriginalFields', () {
      final ad = _bytes(16);
      final sig = OZWebAuthnSignature(
        authenticatorData: ad,
        clientData: _bytes(20),
        signature: _signature64(),
      );
      // Mutate the source array; the signature must keep its own copy.
      ad[0] = 0xAA;
      expect(sig.authenticatorData[0] != 0xAA, isTrue);
    });

    test('testWebAuthnValidation_errorMessageContainsFieldName', () {
      try {
        OZWebAuthnSignature(
          authenticatorData: _bytes(16),
          clientData: _bytes(20),
          signature: Uint8List(63),
        );
        fail('expected ValidationException');
      } catch (e) {
        expect(e, isA<InvalidInput>());
        expect(e.toString().contains('signature'), isTrue);
      }
    });

    test('testWebAuthnSignature_largeClientData_succeeds', () {
      final sig = OZWebAuthnSignature(
        authenticatorData: _bytes(16),
        clientData: _bytes(8192),
        signature: _signature64(),
      );
      expect(sig.toScVal().map![1].val.bytes!.sCBytes.length, 8192);
    });

    test('testWebAuthnToScVal_allKeysAreSymbols', () {
      final sig = OZWebAuthnSignature(
        authenticatorData: _bytes(16),
        clientData: _bytes(20),
        signature: _signature64(),
      );
      for (final entry in sig.toScVal().map!) {
        expect(entry.key.discriminant, XdrSCValType.SCV_SYMBOL);
      }
    });

    test('testWebAuthnToScVal_allValuesAreBytes', () {
      final sig = OZWebAuthnSignature(
        authenticatorData: _bytes(16),
        clientData: _bytes(20),
        signature: _signature64(),
      );
      for (final entry in sig.toScVal().map!) {
        expect(entry.val.discriminant, XdrSCValType.SCV_BYTES);
      }
    });

    test('testWebAuthnSignature_emptySignature_throws', () {
      expect(
        () => OZWebAuthnSignature(
          authenticatorData: _bytes(16),
          clientData: _bytes(20),
          signature: Uint8List(0),
        ),
        throwsA(isA<InvalidInput>()),
      );
    });

    test('testWebAuthnSignature_isOZSmartAccountSignature', () {
      final sig = OZWebAuthnSignature(
        authenticatorData: _bytes(16),
        clientData: _bytes(20),
        signature: _signature64(),
      );
      expect(sig, isA<OZSmartAccountSignature>());
    });

    test('testWebAuthnSignature_copyChangesSignature', () {
      final ad = _bytes(16);
      final cd = _bytes(20);
      final original = OZWebAuthnSignature(
        authenticatorData: ad,
        clientData: cd,
        signature: _signature64(1),
      );
      final modified = OZWebAuthnSignature(
        authenticatorData: ad,
        clientData: cd,
        signature: _signature64(99),
      );
      expect(original == modified, isFalse);
    });
  });

  group('OZWebAuthnSignature equality', () {
    test('testWebAuthnSignature_identicalFields_equals', () {
      final a = OZWebAuthnSignature(
        authenticatorData: _bytes(16),
        clientData: _bytes(20),
        signature: _signature64(),
      );
      final b = OZWebAuthnSignature(
        authenticatorData: _bytes(16),
        clientData: _bytes(20),
        signature: _signature64(),
      );
      expect(a == b, isTrue);
    });

    test('testWebAuthnSignature_sameInstance_equals', () {
      final sig = OZWebAuthnSignature(
        authenticatorData: _bytes(16),
        clientData: _bytes(20),
        signature: _signature64(),
      );
      expect(sig == sig, isTrue);
    });

    test('testWebAuthnSignature_differentAuthenticatorData_notEqual', () {
      final a = OZWebAuthnSignature(
        authenticatorData: _bytes(16, 1),
        clientData: _bytes(20),
        signature: _signature64(),
      );
      final b = OZWebAuthnSignature(
        authenticatorData: _bytes(16, 2),
        clientData: _bytes(20),
        signature: _signature64(),
      );
      expect(a == b, isFalse);
    });

    test('testWebAuthnSignature_differentClientData_notEqual', () {
      final a = OZWebAuthnSignature(
        authenticatorData: _bytes(16),
        clientData: _bytes(20, 3),
        signature: _signature64(),
      );
      final b = OZWebAuthnSignature(
        authenticatorData: _bytes(16),
        clientData: _bytes(20, 4),
        signature: _signature64(),
      );
      expect(a == b, isFalse);
    });

    test('testWebAuthnSignature_differentSignature_notEqual', () {
      final a = OZWebAuthnSignature(
        authenticatorData: _bytes(16),
        clientData: _bytes(20),
        signature: _signature64(5),
      );
      final b = OZWebAuthnSignature(
        authenticatorData: _bytes(16),
        clientData: _bytes(20),
        signature: _signature64(6),
      );
      expect(a == b, isFalse);
    });

    test('testWebAuthnSignature_notEqualToNull', () {
      final a = OZWebAuthnSignature(
        authenticatorData: _bytes(16),
        clientData: _bytes(20),
        signature: _signature64(),
      );
      // ignore: unnecessary_null_comparison
      final Object? other = null;
      // ignore: unrelated_type_equality_checks
      expect(a == other, isFalse);
    });

    test('testWebAuthnSignature_notEqualToDifferentType', () {
      final a = OZWebAuthnSignature(
        authenticatorData: _bytes(16),
        clientData: _bytes(20),
        signature: _signature64(),
      );
      expect(a == 'not a signature', isFalse);
    });

    test('testWebAuthnSignature_equalObjects_sameHashCode', () {
      final a = OZWebAuthnSignature(
        authenticatorData: _bytes(16),
        clientData: _bytes(20),
        signature: _signature64(),
      );
      final b = OZWebAuthnSignature(
        authenticatorData: _bytes(16),
        clientData: _bytes(20),
        signature: _signature64(),
      );
      expect(a.hashCode, b.hashCode);
    });

    test('testWebAuthnSignature_differentAuthenticatorData_differentHashCode',
        () {
      final a = OZWebAuthnSignature(
        authenticatorData: _bytes(16, 1),
        clientData: _bytes(20),
        signature: _signature64(),
      );
      final b = OZWebAuthnSignature(
        authenticatorData: _bytes(16, 2),
        clientData: _bytes(20),
        signature: _signature64(),
      );
      expect(a.hashCode != b.hashCode, isTrue);
    });

    test('testWebAuthnSignature_differentSignatureBytes_differentHashCode',
        () {
      final a = OZWebAuthnSignature(
        authenticatorData: _bytes(16),
        clientData: _bytes(20),
        signature: _signature64(7),
      );
      final b = OZWebAuthnSignature(
        authenticatorData: _bytes(16),
        clientData: _bytes(20),
        signature: _signature64(8),
      );
      expect(a.hashCode != b.hashCode, isTrue);
    });

    test('testWebAuthnSignature_hashCodeConsistentAcrossCalls', () {
      final a = OZWebAuthnSignature(
        authenticatorData: _bytes(16),
        clientData: _bytes(20),
        signature: _signature64(),
      );
      expect(a.hashCode, a.hashCode);
    });
  });

  group('OZEd25519Signature', () {
    test('testEd25519Signature_validSucceeds', () {
      final sig = OZEd25519Signature(
        publicKey: _ed25519Pub(),
        signature: _signature64(),
      );
      expect(sig, isA<OZSmartAccountSignature>());
    });

    test('testEd25519Signature_invalidPubkeyLength_throws', () {
      expect(
        () => OZEd25519Signature(
          publicKey: Uint8List(31),
          signature: _signature64(),
        ),
        throwsA(isA<InvalidInput>()),
      );
    });

    test('testEd25519Signature_invalidSigLength_throws', () {
      expect(
        () => OZEd25519Signature(
          publicKey: _ed25519Pub(),
          signature: Uint8List(63),
        ),
        throwsA(isA<InvalidInput>()),
      );
    });

    test('testEd25519ToScVal_keysInAlphabeticalOrder', () {
      final sig = OZEd25519Signature(
        publicKey: _ed25519Pub(),
        signature: _signature64(),
      );
      final keys = sig.toScVal().map!.map((e) => e.key.sym).toList();
      expect(keys, ['public_key', 'signature']);
    });

    test('testEd25519ToScVal_returnsMapWithTwoEntries', () {
      final sig = OZEd25519Signature(
        publicKey: _ed25519Pub(),
        signature: _signature64(),
      );
      expect(sig.toScVal().map?.length, 2);
    });

    test('testEd25519Signature_equality_identicalFields', () {
      final a = OZEd25519Signature(
        publicKey: _ed25519Pub(),
        signature: _signature64(),
      );
      final b = OZEd25519Signature(
        publicKey: _ed25519Pub(),
        signature: _signature64(),
      );
      expect(a == b, isTrue);
    });

    test('testEd25519Signature_equality_differentSignature', () {
      final a = OZEd25519Signature(
        publicKey: _ed25519Pub(),
        signature: _signature64(1),
      );
      final b = OZEd25519Signature(
        publicKey: _ed25519Pub(),
        signature: _signature64(2),
      );
      expect(a == b, isFalse);
    });

    test('testEd25519Signature_hashCode_isContentBased', () {
      final a = OZEd25519Signature(
        publicKey: _ed25519Pub(),
        signature: _signature64(),
      );
      final b = OZEd25519Signature(
        publicKey: _ed25519Pub(),
        signature: _signature64(),
      );
      expect(a.hashCode, b.hashCode);
    });

    test('testEd25519Signature_hashCode_changesWithKey', () {
      final a = OZEd25519Signature(
        publicKey: _ed25519Pub(1),
        signature: _signature64(),
      );
      final b = OZEd25519Signature(
        publicKey: _ed25519Pub(2),
        signature: _signature64(),
      );
      expect(a.hashCode != b.hashCode, isTrue);
    });
  });

  group('OZPolicySignature', () {
    test('testPolicySignatureToScVal_returnsMapType', () {
      expect(
          OZPolicySignature.instance.toScVal().discriminant, XdrSCValType.SCV_MAP);
    });

    test('testPolicySignatureToScVal_mapIsEmpty', () {
      expect(OZPolicySignature.instance.toScVal().map?.length, 0);
    });

    test('testPolicySignatureToScVal_calledTwiceReturnsSameStructure', () {
      final a = OZPolicySignature.instance.toScVal();
      final b = OZPolicySignature.instance.toScVal();
      expect(a.map?.length, b.map?.length);
    });

    test('testPolicySignature_isSingleton', () {
      expect(identical(OZPolicySignature.instance, OZPolicySignature.instance),
          isTrue);
    });

    test('testPolicySignature_isOZSmartAccountSignature', () {
      expect(OZPolicySignature.instance, isA<OZSmartAccountSignature>());
    });

    test('testPolicySignatureToScVal_matchesManualScvConstruction', () {
      final actual = OZPolicySignature.instance.toScVal();
      final expected = XdrSCVal.forMap(const <XdrSCMapEntry>[]);
      expect(actual.discriminant, expected.discriminant);
      expect(actual.map?.length, expected.map?.length);
    });

    test('testWebAuthnSignature_notEqualToPolicySignature', () {
      final a = OZWebAuthnSignature(
        authenticatorData: _bytes(16),
        clientData: _bytes(20),
        signature: _signature64(),
      );
      // ignore: unrelated_type_equality_checks
      expect(a == OZPolicySignature.instance, isFalse);
    });

    test('testPolicySignature_notEqualToWebAuthn', () {
      final a = OZWebAuthnSignature(
        authenticatorData: _bytes(16),
        clientData: _bytes(20),
        signature: _signature64(),
      );
      // ignore: unrelated_type_equality_checks
      expect(OZPolicySignature.instance == a, isFalse);
    });
  });

  group('OZSmartAccountSignature sealed exhaustiveness', () {
    test('testSealedClass_whenExhaustive', () {
      final List<OZSmartAccountSignature> all = [
        OZWebAuthnSignature(
          authenticatorData: _bytes(16),
          clientData: _bytes(20),
          signature: _signature64(),
        ),
        OZEd25519Signature(
          publicKey: _ed25519Pub(),
          signature: _signature64(),
        ),
        OZPolicySignature.instance,
      ];
      for (final sig in all) {
        expect(sig, isA<OZSmartAccountSignature>());
        expect(sig.toScVal().discriminant, XdrSCValType.SCV_MAP);
      }
    });
  });

  // Cross-SDK byte-identity golden vector (WebAuthnSignature).
  //
  // Pins the byte-level XDR encoding of `OZWebAuthnSignature.toScVal()`. The
  // fixture inputs (37 bytes 0xAA, 16 bytes 0xBB, 64 bytes 0xCC) are chosen
  // so any drift in field name (`client_data` vs `client_data_json`),
  // alphabetical key ordering, or value-bytes encoding produces a different
  // hex output and breaks the cross-SDK test in lockstep.
  group('phase4 cross-SDK WebAuthnSignature golden vector', () {
    test('phase4_goldenVector6_webAuthnSignatureWireShape_matchesFixture', () {
      final signature = OZWebAuthnSignature(
        authenticatorData: Uint8List.fromList(List<int>.filled(37, 0xAA)),
        clientData: Uint8List.fromList(List<int>.filled(16, 0xBB)),
        signature: Uint8List.fromList(List<int>.filled(64, 0xCC)),
      );
      final scVal = signature.toScVal();
      final stream = XdrDataOutputStream();
      XdrSCVal.encode(stream, scVal);
      final encoded = Uint8List.fromList(stream.bytes);
      final actualHex = Util.bytesToHex(encoded).toLowerCase();
      const expectedHex =
          '0000001100000001000000030000000f0000001261757468656e74696361746f725f6461746100000000000d00000025aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa0000000000000f0000000b636c69656e745f64617461000000000d00000010bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000f000000097369676e61747572650000000000000d00000040cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';
      expect(actualHex, expectedHex,
          reason: 'Golden vector 6 mismatch — actual: $actualHex');
    });
  });
}
