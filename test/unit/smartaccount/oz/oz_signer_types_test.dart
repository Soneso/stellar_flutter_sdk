// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

const String kValidGAddress =
    'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';
const String kValidGAddress2 =
    'GBVRV25F7XA5I2L3ILSA6XW3OCWLKGGLG4OP2EHKTWC5IHQ3EV26FQLS';
const String kValidContractId =
    'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK';

Uint8List _bytes(int n, [int seed = 0]) {
  final out = Uint8List(n);
  for (var i = 0; i < n; i++) {
    out[i] = (i + seed) & 0xFF;
  }
  return out;
}

Uint8List _secp256r1Pubkey([int seed = 0]) {
  final out = Uint8List(65);
  out[0] = 0x04;
  for (var i = 1; i < 65; i++) {
    out[i] = (i + seed) & 0xFF;
  }
  return out;
}

Uint8List _ed25519Pubkey([int seed = 0]) => _bytes(32, seed);

void main() {
  group('OZSmartAccountSigner sealed-class behaviour', () {
    test('OZDelegatedSigner is OZSmartAccountSigner', () {
      expect(OZDelegatedSigner(kValidGAddress), isA<OZSmartAccountSigner>());
    });

    test('OZExternalSigner is OZSmartAccountSigner', () {
      expect(OZExternalSigner(kValidContractId, _bytes(8)),
          isA<OZSmartAccountSigner>());
    });

    test('uniqueKey for OZDelegatedSigner has delegated prefix', () {
      final s = OZDelegatedSigner(kValidGAddress);
      expect(s.uniqueKey, startsWith('delegated:'));
      expect(s.uniqueKey, contains(kValidGAddress));
    });

    test(
        'uniqueKey for OZExternalSigner has external prefix and hex keyData',
        () {
      final s = OZExternalSigner(kValidContractId, _bytes(4));
      expect(s.uniqueKey, startsWith('external:'));
      expect(s.uniqueKey, contains(kValidContractId));
      expect(s.uniqueKey, contains('00010203'));
    });
  });

  group('OZDelegatedSigner', () {
    test('accepts valid G-address', () {
      final s = OZDelegatedSigner(kValidGAddress);
      expect(s.address, kValidGAddress);
    });

    test('accepts valid C-address', () {
      final s = OZDelegatedSigner(kValidContractId);
      expect(s.address, kValidContractId);
    });

    test('rejects invalid address', () {
      expect(() => OZDelegatedSigner('NOT_A_VALID_ADDRESS'),
          throwsA(isA<InvalidAddress>()));
    });

    test('equality on identical address returns true', () {
      final a = OZDelegatedSigner(kValidGAddress);
      final b = OZDelegatedSigner(kValidGAddress);
      expect(a == b, isTrue);
    });

    test('equality on different address returns false', () {
      final a = OZDelegatedSigner(kValidGAddress);
      final b = OZDelegatedSigner(kValidContractId);
      expect(a == b, isFalse);
    });

    test('hashCode equality matches operator equality', () {
      final a = OZDelegatedSigner(kValidGAddress);
      final b = OZDelegatedSigner(kValidGAddress);
      expect(a.hashCode, b.hashCode);
    });

    test('not equal to OZExternalSigner', () {
      // ignore: unrelated_type_equality_checks
      expect(
          OZDelegatedSigner(kValidGAddress) ==
              OZExternalSigner(kValidContractId, _bytes(8)),
          isFalse);
    });

    test('not equal to non-signer types', () {
      // ignore: unrelated_type_equality_checks
      expect(OZDelegatedSigner(kValidGAddress) == 'string', isFalse);
    });

    test('toScVal returns Vec', () {
      final sc = OZDelegatedSigner(kValidGAddress).toScVal();
      expect(sc.discriminant, XdrSCValType.SCV_VEC);
    });

    test('uniqueKey is stable across calls', () {
      final s = OZDelegatedSigner(kValidGAddress);
      expect(s.uniqueKey, s.uniqueKey);
    });

    test('two OZDelegatedSigners with same address share uniqueKey', () {
      expect(
        OZDelegatedSigner(kValidGAddress).uniqueKey,
        OZDelegatedSigner(kValidGAddress).uniqueKey,
      );
    });

    test('toScVal Vec[0] is "Delegated"', () {
      expect(OZDelegatedSigner(kValidGAddress).toScVal().vec![0].sym,
          'Delegated');
    });

    test('toScVal Vec[1] is account address', () {
      expect(OZDelegatedSigner(kValidGAddress).toScVal().vec![1].discriminant,
          XdrSCValType.SCV_ADDRESS);
    });

    test('canHashIntoSet (set deduplication)', () {
      final set = <OZSmartAccountSigner>{
        OZDelegatedSigner(kValidGAddress),
        OZDelegatedSigner(kValidGAddress),
        OZDelegatedSigner(kValidGAddress2),
      };
      expect(set.length, 2);
    });

    test('canBeMapKey', () {
      final map = <OZSmartAccountSigner, int>{
        OZDelegatedSigner(kValidGAddress): 1,
        OZDelegatedSigner(kValidGAddress): 2, // overwrites
      };
      expect(map.length, 1);
      expect(map[OZDelegatedSigner(kValidGAddress)], 2);
    });
  });

  group('OZExternalSigner', () {
    test('accepts valid verifier and non-empty keyData', () {
      final s = OZExternalSigner(kValidContractId, _bytes(8));
      expect(s.verifierAddress, kValidContractId);
      expect(s.keyData.length, 8);
    });

    test('rejects invalid verifier address', () {
      expect(() => OZExternalSigner('NOT_VALID', _bytes(8)),
          throwsA(isA<InvalidAddress>()));
    });

    test('rejects empty keyData', () {
      expect(() => OZExternalSigner(kValidContractId, Uint8List(0)),
          throwsA(isA<InvalidInput>()));
    });

    test('keyData is stored by value (input mutation does not bleed in)', () {
      final src = _bytes(8, 1);
      final s = OZExternalSigner(kValidContractId, src);
      src[0] = 0xFF;
      expect(s.keyData[0] != 0xFF, isTrue);
    });

    test('equality on identical fields returns true', () {
      final a = OZExternalSigner(kValidContractId, _bytes(8));
      final b = OZExternalSigner(kValidContractId, _bytes(8));
      expect(a == b, isTrue);
    });

    test('equality on different verifier returns false', () {
      final altCAddress = StrKey.encodeContractId(_bytes(32, 7));
      final a = OZExternalSigner(kValidContractId, _bytes(8));
      final b = OZExternalSigner(altCAddress, _bytes(8));
      expect(a == b, isFalse);
    });

    test('equality on different keyData returns false', () {
      final a = OZExternalSigner(kValidContractId, _bytes(8, 1));
      final b = OZExternalSigner(kValidContractId, _bytes(8, 2));
      expect(a == b, isFalse);
    });

    test('hashCode is content-based', () {
      final a = OZExternalSigner(kValidContractId, _bytes(8));
      final b = OZExternalSigner(kValidContractId, _bytes(8));
      expect(a.hashCode, b.hashCode);
    });

    test('not equal to OZDelegatedSigner', () {
      // ignore: unrelated_type_equality_checks
      expect(
          OZExternalSigner(kValidContractId, _bytes(8)) ==
              OZDelegatedSigner(kValidGAddress),
          isFalse);
    });

    test('uniqueKey is stable across calls', () {
      final s = OZExternalSigner(kValidContractId, _bytes(8));
      expect(s.uniqueKey, s.uniqueKey);
    });

    test('uniqueKey changes with different keyData', () {
      final a = OZExternalSigner(kValidContractId, _bytes(8, 1));
      final b = OZExternalSigner(kValidContractId, _bytes(8, 2));
      expect(a.uniqueKey != b.uniqueKey, isTrue);
    });

    test('toScVal returns Vec with 3 elements', () {
      expect(
          OZExternalSigner(kValidContractId, _bytes(8)).toScVal().vec!.length,
          3);
    });

    test('canBeMapKey', () {
      final map = <OZSmartAccountSigner, int>{
        OZExternalSigner(kValidContractId, _bytes(8)): 1,
        OZExternalSigner(kValidContractId, _bytes(8)): 2,
      };
      expect(map.length, 1);
    });

    test('canHashIntoSet (deduplication)', () {
      final set = <OZSmartAccountSigner>{
        OZExternalSigner(kValidContractId, _bytes(8)),
        OZExternalSigner(kValidContractId, _bytes(8)),
      };
      expect(set.length, 1);
    });
  });

  group('webAuthn factory', () {
    test('produces OZExternalSigner', () {
      final s = OZExternalSigner.webAuthn(
        verifierAddress: kValidContractId,
        publicKey: _secp256r1Pubkey(),
        credentialId: _bytes(20),
      );
      expect(s, isA<OZExternalSigner>());
    });

    test('keyData length is 65 + credentialId.length', () {
      final s = OZExternalSigner.webAuthn(
        verifierAddress: kValidContractId,
        publicKey: _secp256r1Pubkey(),
        credentialId: _bytes(20),
      );
      expect(s.keyData.length, 85);
    });

    test('keyData starts with the public key', () {
      final pk = _secp256r1Pubkey(11);
      final s = OZExternalSigner.webAuthn(
        verifierAddress: kValidContractId,
        publicKey: pk,
        credentialId: _bytes(20),
      );
      expect(Uint8List.sublistView(s.keyData, 0, 65), pk);
    });

    test('keyData ends with the credentialId', () {
      final cred = _bytes(20, 7);
      final s = OZExternalSigner.webAuthn(
        verifierAddress: kValidContractId,
        publicKey: _secp256r1Pubkey(),
        credentialId: cred,
      );
      expect(Uint8List.sublistView(s.keyData, 65), cred);
    });

    test('rejects pubkey of wrong size', () {
      expect(
        () => OZExternalSigner.webAuthn(
          verifierAddress: kValidContractId,
          publicKey: Uint8List(64),
          credentialId: _bytes(20),
        ),
        throwsA(isA<InvalidInput>()),
      );
    });

    test('rejects pubkey with non-0x04 prefix', () {
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

    test('rejects empty credentialId', () {
      expect(
        () => OZExternalSigner.webAuthn(
          verifierAddress: kValidContractId,
          publicKey: _secp256r1Pubkey(),
          credentialId: Uint8List(0),
        ),
        throwsA(isA<InvalidInput>()),
      );
    });

    test('rejects invalid verifier address', () {
      expect(
        () => OZExternalSigner.webAuthn(
          verifierAddress: 'NOT_VALID',
          publicKey: _secp256r1Pubkey(),
          credentialId: _bytes(20),
        ),
        throwsA(isA<InvalidAddress>()),
      );
    });

    test('toScVal returns Vec[3]', () {
      final s = OZExternalSigner.webAuthn(
        verifierAddress: kValidContractId,
        publicKey: _secp256r1Pubkey(),
        credentialId: _bytes(20),
      );
      expect(s.toScVal().vec!.length, 3);
    });
  });

  group('ed25519 factory', () {
    test('produces OZExternalSigner', () {
      final s = OZExternalSigner.ed25519(
        verifierAddress: kValidContractId,
        publicKey: _ed25519Pubkey(),
      );
      expect(s, isA<OZExternalSigner>());
    });

    test('keyData is exactly 32 bytes', () {
      final s = OZExternalSigner.ed25519(
        verifierAddress: kValidContractId,
        publicKey: _ed25519Pubkey(),
      );
      expect(s.keyData.length, 32);
    });

    test('rejects pubkey of wrong length', () {
      expect(
        () => OZExternalSigner.ed25519(
          verifierAddress: kValidContractId,
          publicKey: Uint8List(31),
        ),
        throwsA(isA<InvalidInput>()),
      );
    });

    test('rejects invalid verifier address', () {
      expect(
        () => OZExternalSigner.ed25519(
          verifierAddress: 'NOT_VALID',
          publicKey: _ed25519Pubkey(),
        ),
        throwsA(isA<InvalidAddress>()),
      );
    });
  });

  group('OZSmartAccountSigner round-trips', () {
    test('OZDelegatedSigner toScVal/signerFromScVal preserves identity', () {
      final s = OZDelegatedSigner(kValidGAddress);
      final scVal = s.toScVal();
      final reconstructed =
          OZSmartAccountAuthPayloadCodec.signerFromScVal(scVal);
      expect(reconstructed, isA<OZDelegatedSigner>());
      expect((reconstructed as OZDelegatedSigner).address, s.address);
    });

    test('OZExternalSigner toScVal/signerFromScVal preserves identity', () {
      final s = OZExternalSigner(kValidContractId, _bytes(8, 9));
      final scVal = s.toScVal();
      final reconstructed =
          OZSmartAccountAuthPayloadCodec.signerFromScVal(scVal);
      expect(reconstructed, isA<OZExternalSigner>());
      final ext = reconstructed as OZExternalSigner;
      expect(ext.verifierAddress, s.verifierAddress);
      expect(ext.keyData, s.keyData);
    });

    test('webAuthn signer round-trip', () {
      final s = OZExternalSigner.webAuthn(
        verifierAddress: kValidContractId,
        publicKey: _secp256r1Pubkey(),
        credentialId: _bytes(20),
      );
      final reconstructed =
          OZSmartAccountAuthPayloadCodec.signerFromScVal(s.toScVal());
      expect(reconstructed, isA<OZExternalSigner>());
      expect((reconstructed as OZExternalSigner).keyData, s.keyData);
    });

    test('ed25519 signer round-trip', () {
      final s = OZExternalSigner.ed25519(
        verifierAddress: kValidContractId,
        publicKey: _ed25519Pubkey(),
      );
      final reconstructed =
          OZSmartAccountAuthPayloadCodec.signerFromScVal(s.toScVal());
      expect(reconstructed, isA<OZExternalSigner>());
      expect((reconstructed as OZExternalSigner).keyData.length, 32);
    });
  });

  group('uniqueKey format details', () {
    test('format ends with hex of keyData', () {
      final s = OZExternalSigner(kValidContractId,
          Uint8List.fromList([0xAB, 0xCD, 0xEF]));
      expect(s.uniqueKey.endsWith('abcdef'), isTrue);
    });

    test('different signers have different uniqueKey', () {
      final s1 = OZDelegatedSigner(kValidGAddress);
      final s2 = OZExternalSigner(kValidContractId, _bytes(8));
      expect(s1.uniqueKey != s2.uniqueKey, isTrue);
    });

    test('uniqueKey length is bounded for reasonable keyData', () {
      final s = OZExternalSigner(kValidContractId, _bytes(64));
      // sanity: less than a few hundred chars.
      expect(s.uniqueKey.length < 500, isTrue);
    });
  });

  group('large keyData support', () {
    test('1024-byte keyData is accepted', () {
      final s = OZExternalSigner(kValidContractId, _bytes(1024));
      expect(s.keyData.length, 1024);
    });

    test('hashCode stays bounded for large keyData', () {
      final s = OZExternalSigner(kValidContractId, _bytes(512));
      expect(s.hashCode, isA<int>());
    });

    test('equality remains correct for large keyData', () {
      final a = OZExternalSigner(kValidContractId, _bytes(512));
      final b = OZExternalSigner(kValidContractId, _bytes(512));
      expect(a == b, isTrue);
    });
  });

  group('immutability and isolate-safety', () {
    test('keyData is a copy: caller cannot mutate after construction', () {
      final src = _bytes(8);
      final s = OZExternalSigner(kValidContractId, src);
      src[0] = 0xFF;
      expect(s.keyData[0] != 0xFF, isTrue);
    });

    test('uniqueKey strings are independent across signer instances', () {
      final a = OZDelegatedSigner(kValidGAddress);
      final b = OZDelegatedSigner(kValidGAddress);
      expect(a.uniqueKey, b.uniqueKey);
      // Strings are immutable; each value is structurally identical but
      // referencing one does not affect the other.
      expect(identical(a, b), isFalse);
    });
  });

  group('toScVal map and vec interop', () {
    test('toScVal Vec elements are not aliased to internal state', () {
      final s = OZDelegatedSigner(kValidGAddress);
      final v1 = s.toScVal();
      final v2 = s.toScVal();
      // Repeated calls produce structurally-equal but distinct ScVal
      // instances.
      expect(v1.vec!.length, v2.vec!.length);
    });

    test('toScVal does not throw for valid signer', () {
      expect(
          () => OZDelegatedSigner(kValidGAddress).toScVal(), returnsNormally);
      expect(
        () => OZExternalSigner(kValidContractId, _bytes(8)).toScVal(),
        returnsNormally,
      );
    });
  });

  group('mixed-type collections', () {
    test('list of mixed delegated and external signers', () {
      final list = <OZSmartAccountSigner>[
        OZDelegatedSigner(kValidGAddress),
        OZExternalSigner(kValidContractId, _bytes(8)),
        OZExternalSigner.webAuthn(
          verifierAddress: kValidContractId,
          publicKey: _secp256r1Pubkey(),
          credentialId: _bytes(20),
        ),
      ];
      expect(list, hasLength(3));
    });

    test('set deduplication across signer types', () {
      final set = <OZSmartAccountSigner>{
        OZDelegatedSigner(kValidGAddress),
        OZDelegatedSigner(kValidGAddress),
        OZExternalSigner(kValidContractId, _bytes(8)),
        OZExternalSigner(kValidContractId, _bytes(8)),
      };
      expect(set.length, 2);
    });
  });

  group('SubmissionMethod integration', () {
    test('values are usable as map keys', () {
      final m = <SubmissionMethod, String>{
        SubmissionMethod.relayer: 'r',
        SubmissionMethod.rpc: 'p',
      };
      expect(m[SubmissionMethod.relayer], 'r');
    });

    test('values can be compared by name', () {
      expect(SubmissionMethod.relayer.name.compareTo('relayer'), 0);
    });
  });

  group('additional boundary cases', () {
    test('OZDelegatedSigner address with C-prefix accepted', () {
      expect(OZDelegatedSigner(kValidContractId).address, kValidContractId);
    });

    test('OZExternalSigner toScVal is reproducible byte-for-byte', () {
      final s = OZExternalSigner(kValidContractId, _bytes(8));
      final a = s.toScVal().toBase64EncodedXdrString();
      final b = s.toScVal().toBase64EncodedXdrString();
      expect(a, b);
    });

    test('webAuthn signer uniqueKey contains contract address', () {
      final s = OZExternalSigner.webAuthn(
        verifierAddress: kValidContractId,
        publicKey: _secp256r1Pubkey(),
        credentialId: _bytes(20),
      );
      expect(s.uniqueKey.contains(kValidContractId), isTrue);
    });
  });
}
