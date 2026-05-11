// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

const String kValidGAddress =
    'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';
const String kValidContractId =
    'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK';

Uint8List _bytes(int n, [int seed = 0]) {
  final out = Uint8List(n);
  for (var i = 0; i < n; i++) {
    out[i] = (i + seed) & 0xFF;
  }
  return out;
}

void main() {
  group('Delegated signer ScVal shape', () {
    test('produces Vec with 2 elements', () {
      final sc = OZDelegatedSigner(kValidGAddress).toScVal();
      expect(sc.discriminant, XdrSCValType.SCV_VEC);
      expect(sc.vec, isNotNull);
      expect(sc.vec!.length, 2);
    });

    test('first element is Symbol("Delegated")', () {
      final sc = OZDelegatedSigner(kValidGAddress).toScVal();
      expect(sc.vec![0].discriminant, XdrSCValType.SCV_SYMBOL);
      expect(sc.vec![0].sym, 'Delegated');
    });

    test('second element is Address', () {
      final sc = OZDelegatedSigner(kValidGAddress).toScVal();
      expect(sc.vec![1].discriminant, XdrSCValType.SCV_ADDRESS);
      expect(sc.vec![1].address, isNotNull);
    });

    test('contract address variant produces contract Address', () {
      final sc = OZDelegatedSigner(kValidContractId).toScVal();
      expect(sc.vec![1].address!.discriminant,
          XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT);
    });

    test('account address variant produces account Address', () {
      final sc = OZDelegatedSigner(kValidGAddress).toScVal();
      expect(sc.vec![1].address!.discriminant,
          XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT);
    });

    test('invalid address throws InvalidAddress', () {
      expect(() => OZDelegatedSigner('NOT_A_VALID'),
          throwsA(isA<InvalidAddress>()));
    });

    test('toScVal called twice produces structurally identical Vecs', () {
      final s = OZDelegatedSigner(kValidGAddress);
      final a = s.toScVal();
      final b = s.toScVal();
      expect(a.vec!.length, b.vec!.length);
      expect(a.vec![0].sym, b.vec![0].sym);
    });
  });

  group('External signer ScVal shape', () {
    test('produces Vec with 3 elements', () {
      final s = OZExternalSigner(kValidContractId, _bytes(8));
      final sc = s.toScVal();
      expect(sc.discriminant, XdrSCValType.SCV_VEC);
      expect(sc.vec!.length, 3);
    });

    test('first element is Symbol("External")', () {
      final sc = OZExternalSigner(kValidContractId, _bytes(8)).toScVal();
      expect(sc.vec![0].sym, 'External');
    });

    test('second element is contract Address', () {
      final sc = OZExternalSigner(kValidContractId, _bytes(8)).toScVal();
      expect(sc.vec![1].discriminant, XdrSCValType.SCV_ADDRESS);
      expect(sc.vec![1].address!.discriminant,
          XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT);
    });

    test('third element is Bytes carrying keyData', () {
      final keyData = _bytes(16, 7);
      final sc = OZExternalSigner(kValidContractId, keyData).toScVal();
      expect(sc.vec![2].discriminant, XdrSCValType.SCV_BYTES);
      expect(sc.vec![2].bytes!.sCBytes, keyData);
    });

    test('invalid verifier address throws InvalidAddress', () {
      expect(() => OZExternalSigner('NOT_VALID', _bytes(8)),
          throwsA(isA<InvalidAddress>()));
    });

    test('empty keyData throws InvalidInput', () {
      expect(() => OZExternalSigner(kValidContractId, Uint8List(0)),
          throwsA(isA<InvalidInput>()));
    });

    test('webAuthn factory produces 65+credId keyData', () {
      final pk = Uint8List(65)..[0] = 0x04;
      final s = OZExternalSigner.webAuthn(
        verifierAddress: kValidContractId,
        publicKey: pk,
        credentialId: _bytes(20),
      );
      expect(s.keyData.length, 65 + 20);
    });

    test('webAuthn factory rejects pubkey of wrong length', () {
      expect(
        () => OZExternalSigner.webAuthn(
          verifierAddress: kValidContractId,
          publicKey: Uint8List(64),
          credentialId: _bytes(20),
        ),
        throwsA(isA<InvalidInput>()),
      );
    });

    test('webAuthn factory rejects pubkey not starting with 0x04', () {
      final pk = Uint8List(65)..[0] = 0x02;
      expect(
        () => OZExternalSigner.webAuthn(
          verifierAddress: kValidContractId,
          publicKey: pk,
          credentialId: _bytes(20),
        ),
        throwsA(isA<InvalidInput>()),
      );
    });

    test('webAuthn factory rejects empty credentialId', () {
      final pk = Uint8List(65)..[0] = 0x04;
      expect(
        () => OZExternalSigner.webAuthn(
          verifierAddress: kValidContractId,
          publicKey: pk,
          credentialId: Uint8List(0),
        ),
        throwsA(isA<InvalidInput>()),
      );
    });

    test('ed25519 factory produces 32-byte keyData', () {
      final s = OZExternalSigner.ed25519(
        verifierAddress: kValidContractId,
        publicKey: _bytes(32),
      );
      expect(s.keyData.length, 32);
    });

    test('ed25519 factory rejects pubkey of wrong length', () {
      expect(
        () => OZExternalSigner.ed25519(
          verifierAddress: kValidContractId,
          publicKey: Uint8List(31),
        ),
        throwsA(isA<InvalidInput>()),
      );
    });

    test('toScVal produces deterministic structure across calls', () {
      final s = OZExternalSigner(kValidContractId, _bytes(8));
      final a = s.toScVal();
      final b = s.toScVal();
      expect(a.vec!.length, b.vec!.length);
      expect(a.vec![2].bytes!.sCBytes, b.vec![2].bytes!.sCBytes);
    });
  });

  group('SubmissionMethod', () {
    test('has exactly two values', () {
      expect(SubmissionMethod.values.length, 2);
    });

    test('values are relayer and rpc', () {
      expect(SubmissionMethod.values, [
        SubmissionMethod.relayer,
        SubmissionMethod.rpc,
      ]);
    });

    test('relayer name is "relayer"', () {
      expect(SubmissionMethod.relayer.name, 'relayer');
    });

    test('rpc name is "rpc"', () {
      expect(SubmissionMethod.rpc.name, 'rpc');
    });

    test('values can be used in equality', () {
      expect(SubmissionMethod.relayer == SubmissionMethod.relayer, isTrue);
      expect(SubmissionMethod.relayer == SubmissionMethod.rpc, isFalse);
    });

    test('values support hashCode', () {
      expect(SubmissionMethod.relayer.hashCode,
          SubmissionMethod.relayer.hashCode);
    });
  });
}
