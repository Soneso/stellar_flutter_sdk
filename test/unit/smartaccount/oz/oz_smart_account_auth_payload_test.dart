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

OZDelegatedSigner _del([String addr = kValidGAddress]) =>
    OZDelegatedSigner(addr);

OZExternalSigner _ext({int seed = 1}) => OZExternalSigner(
      kValidContractId,
      _bytes(32, seed),
    );

void main() {
  group('OZSmartAccountAuthPayload data class', () {
    test('testPayloadConstruction_emptySignersAndRuleIds', () {
      final p = OZSmartAccountAuthPayload(
        signers: <OZSmartAccountSigner, Uint8List>{},
        contextRuleIds: const <int>[],
      );
      expect(p.signers, isEmpty);
      expect(p.contextRuleIds, isEmpty);
    });

    test('testPayloadConstruction_withSignersAndRuleIds', () {
      final s = _del();
      final p = OZSmartAccountAuthPayload(
        signers: <OZSmartAccountSigner, Uint8List>{s: _bytes(8)},
        contextRuleIds: const <int>[1, 2, 3],
      );
      expect(p.signers, hasLength(1));
      expect(p.contextRuleIds, [1, 2, 3]);
    });

    test('testPayloadSignersMap_isMutable', () {
      final p = OZSmartAccountAuthPayload(
        signers: <OZSmartAccountSigner, Uint8List>{},
        contextRuleIds: const <int>[],
      );
      p.signers[_del()] = _bytes(8);
      expect(p.signers, hasLength(1));
    });
  });

  group('Codec.read', () {
    test('testRead_voidReturnsEmptyPayload', () {
      final out = OZSmartAccountAuthPayloadCodec.read(XdrSCVal.forVoid());
      expect(out.signers, isEmpty);
      expect(out.contextRuleIds, isEmpty);
    });

    test('testRead_nonMapNonVoidThrows', () {
      expect(
        () => OZSmartAccountAuthPayloadCodec.read(XdrSCVal.forU32(7)),
        throwsA(isA<TransactionSigningFailed>()),
      );
    });

    test('testRead_symbolScValThrows', () {
      expect(
        () => OZSmartAccountAuthPayloadCodec.read(XdrSCVal.forSymbol('foo')),
        throwsA(isA<TransactionSigningFailed>()),
      );
    });

    test('testRead_bytesScValThrows', () {
      expect(
        () => OZSmartAccountAuthPayloadCodec.read(XdrSCVal.forBytes(_bytes(4))),
        throwsA(isA<TransactionSigningFailed>()),
      );
    });

    test('testRead_vecScValThrows', () {
      expect(
        () => OZSmartAccountAuthPayloadCodec.read(XdrSCVal.forVec([])),
        throwsA(isA<TransactionSigningFailed>()),
      );
    });

    test('testRead_emptyMapReturnsEmptyPayload', () {
      final out = OZSmartAccountAuthPayloadCodec.read(XdrSCVal.forMap([]));
      expect(out.signers, isEmpty);
      expect(out.contextRuleIds, isEmpty);
    });

    test('testRead_contextRuleIdsOnly', () {
      final scVal = XdrSCVal.forMap([
        XdrSCMapEntry(
          XdrSCVal.forSymbol('context_rule_ids'),
          XdrSCVal.forVec([XdrSCVal.forU32(1), XdrSCVal.forU32(2)]),
        ),
      ]);
      final out = OZSmartAccountAuthPayloadCodec.read(scVal);
      expect(out.contextRuleIds, [1, 2]);
      expect(out.signers, isEmpty);
    });

    test('testRead_signersOnly_delegatedSigner', () {
      final s = _del();
      final scVal = XdrSCVal.forMap([
        XdrSCMapEntry(
          XdrSCVal.forSymbol('signers'),
          XdrSCVal.forMap([
            XdrSCMapEntry(s.toScVal(), XdrSCVal.forBytes(_bytes(4))),
          ]),
        ),
      ]);
      final out = OZSmartAccountAuthPayloadCodec.read(scVal);
      expect(out.signers, hasLength(1));
    });

    test('testRead_signersOnly_externalSigner', () {
      final s = _ext();
      final scVal = XdrSCVal.forMap([
        XdrSCMapEntry(
          XdrSCVal.forSymbol('signers'),
          XdrSCVal.forMap([
            XdrSCMapEntry(s.toScVal(), XdrSCVal.forBytes(_bytes(4))),
          ]),
        ),
      ]);
      final out = OZSmartAccountAuthPayloadCodec.read(scVal);
      expect(out.signers, hasLength(1));
    });

    test('testRead_multipleSigners', () {
      final s1 = _del();
      final s2 = _ext();
      final scVal = XdrSCVal.forMap([
        XdrSCMapEntry(
          XdrSCVal.forSymbol('signers'),
          XdrSCVal.forMap([
            XdrSCMapEntry(s1.toScVal(), XdrSCVal.forBytes(_bytes(4))),
            XdrSCMapEntry(s2.toScVal(), XdrSCVal.forBytes(_bytes(8))),
          ]),
        ),
      ]);
      final out = OZSmartAccountAuthPayloadCodec.read(scVal);
      expect(out.signers, hasLength(2));
    });

    test('testRead_signerWithNonBytesValueThrows', () {
      final s = _del();
      final scVal = XdrSCVal.forMap([
        XdrSCMapEntry(
          XdrSCVal.forSymbol('signers'),
          XdrSCVal.forMap([
            XdrSCMapEntry(s.toScVal(), XdrSCVal.forU32(7)),
          ]),
        ),
      ]);
      expect(
        () => OZSmartAccountAuthPayloadCodec.read(scVal),
        throwsA(isA<TransactionSigningFailed>()),
      );
    });

    test('testRead_unknownKeysAreIgnored', () {
      final scVal = XdrSCVal.forMap([
        XdrSCMapEntry(
          XdrSCVal.forSymbol('unknown_key'),
          XdrSCVal.forU32(123),
        ),
      ]);
      final out = OZSmartAccountAuthPayloadCodec.read(scVal);
      expect(out.signers, isEmpty);
      expect(out.contextRuleIds, isEmpty);
    });

    test('testRead_nonSymbolKeysAreSkipped', () {
      final scVal = XdrSCVal.forMap([
        XdrSCMapEntry(XdrSCVal.forU32(0), XdrSCVal.forU32(1)),
      ]);
      final out = OZSmartAccountAuthPayloadCodec.read(scVal);
      expect(out.signers, isEmpty);
      expect(out.contextRuleIds, isEmpty);
    });

    test('testRead_emptyContextRuleIdsVec', () {
      final scVal = XdrSCVal.forMap([
        XdrSCMapEntry(
          XdrSCVal.forSymbol('context_rule_ids'),
          XdrSCVal.forVec(<XdrSCVal>[]),
        ),
      ]);
      final out = OZSmartAccountAuthPayloadCodec.read(scVal);
      expect(out.contextRuleIds, isEmpty);
    });

    test('testRead_contextRuleIdsNotVecIsIgnored', () {
      final scVal = XdrSCVal.forMap([
        XdrSCMapEntry(
          XdrSCVal.forSymbol('context_rule_ids'),
          XdrSCVal.forU32(7),
        ),
      ]);
      final out = OZSmartAccountAuthPayloadCodec.read(scVal);
      expect(out.contextRuleIds, isEmpty);
    });

    test('testRead_signersNotMapIsIgnored', () {
      final scVal = XdrSCVal.forMap([
        XdrSCMapEntry(
          XdrSCVal.forSymbol('signers'),
          XdrSCVal.forU32(7),
        ),
      ]);
      final out = OZSmartAccountAuthPayloadCodec.read(scVal);
      expect(out.signers, isEmpty);
    });

    test('testRead_singleContextRuleId', () {
      final scVal = XdrSCVal.forMap([
        XdrSCMapEntry(
          XdrSCVal.forSymbol('context_rule_ids'),
          XdrSCVal.forVec([XdrSCVal.forU32(42)]),
        ),
      ]);
      final out = OZSmartAccountAuthPayloadCodec.read(scVal);
      expect(out.contextRuleIds, [42]);
    });

    test('testRead_contextRuleIdBoundaryValues', () {
      final scVal = XdrSCVal.forMap([
        XdrSCMapEntry(
          XdrSCVal.forSymbol('context_rule_ids'),
          XdrSCVal.forVec([
            XdrSCVal.forU32(0),
            XdrSCVal.forU32(0xFFFFFFFF),
          ]),
        ),
      ]);
      final out = OZSmartAccountAuthPayloadCodec.read(scVal);
      expect(out.contextRuleIds, [0, 0xFFFFFFFF]);
    });
  });

  group('Codec.write', () {
    test('testWrite_emptyPayload', () {
      final p = OZSmartAccountAuthPayload(
        signers: <OZSmartAccountSigner, Uint8List>{},
        contextRuleIds: const <int>[],
      );
      final out = OZSmartAccountAuthPayloadCodec.write(p);
      expect(out.discriminant, XdrSCValType.SCV_MAP);
      expect(out.map?.length, 2);
      expect(out.map![0].key.sym, 'context_rule_ids');
      expect(out.map![1].key.sym, 'signers');
    });

    test('testWrite_withContextRuleIds', () {
      final p = OZSmartAccountAuthPayload(
        signers: <OZSmartAccountSigner, Uint8List>{},
        contextRuleIds: const <int>[1, 2, 3],
      );
      final out = OZSmartAccountAuthPayloadCodec.write(p);
      final ruleVec = out.map![0].val.vec;
      expect(ruleVec, isNotNull);
      expect(ruleVec!.length, 3);
      expect(ruleVec[0].u32!.uint32, 1);
      expect(ruleVec[2].u32!.uint32, 3);
    });

    test('testWrite_withSingleOZDelegatedSigner', () {
      final s = _del();
      final p = OZSmartAccountAuthPayload(
        signers: <OZSmartAccountSigner, Uint8List>{s: _bytes(8)},
        contextRuleIds: const <int>[],
      );
      final out = OZSmartAccountAuthPayloadCodec.write(p);
      final signersMap = out.map![1].val.map;
      expect(signersMap, isNotNull);
      expect(signersMap!.length, 1);
    });

    test('testWrite_withSingleOZExternalSigner', () {
      final s = _ext();
      final p = OZSmartAccountAuthPayload(
        signers: <OZSmartAccountSigner, Uint8List>{s: _bytes(8)},
        contextRuleIds: const <int>[],
      );
      final out = OZSmartAccountAuthPayloadCodec.write(p);
      final signersMap = out.map![1].val.map;
      expect(signersMap, isNotNull);
      expect(signersMap!.length, 1);
    });

    test('testWrite_outputMapHasCorrectFieldOrder', () {
      final p = OZSmartAccountAuthPayload(
        signers: <OZSmartAccountSigner, Uint8List>{_del(): _bytes(4)},
        contextRuleIds: const <int>[5],
      );
      final out = OZSmartAccountAuthPayloadCodec.write(p);
      // outer struct uses alphabetical insertion order so c < s.
      expect(out.map![0].key.sym, 'context_rule_ids');
      expect(out.map![1].key.sym, 'signers');
    });

    test('testWrite_signersSortedDeterministically', () {
      final s1 = _del(kValidGAddress);
      final s2 = _del(kValidGAddress2);
      final p1 = OZSmartAccountAuthPayload(
        signers: <OZSmartAccountSigner, Uint8List>{s1: _bytes(4), s2: _bytes(8)},
        contextRuleIds: const <int>[],
      );
      final p2 = OZSmartAccountAuthPayload(
        signers: <OZSmartAccountSigner, Uint8List>{s2: _bytes(8), s1: _bytes(4)},
        contextRuleIds: const <int>[],
      );
      final out1 = OZSmartAccountAuthPayloadCodec.write(p1);
      final out2 = OZSmartAccountAuthPayloadCodec.write(p2);
      // Order of inner map entries should be identical.
      expect(out1.map![1].val.map!.length, out2.map![1].val.map!.length);
      for (var i = 0; i < out1.map![1].val.map!.length; i++) {
        final keyA = out1.map![1].val.map![i].key.toBase64EncodedXdrString();
        final keyB = out2.map![1].val.map![i].key.toBase64EncodedXdrString();
        expect(keyA, keyB);
      }
    });
  });

  group('Codec round-trip', () {
    test('testRoundTrip_emptyPayload', () {
      final p = OZSmartAccountAuthPayload(
        signers: <OZSmartAccountSigner, Uint8List>{},
        contextRuleIds: const <int>[],
      );
      final encoded = OZSmartAccountAuthPayloadCodec.write(p);
      final decoded = OZSmartAccountAuthPayloadCodec.read(encoded);
      expect(decoded.signers, isEmpty);
      expect(decoded.contextRuleIds, isEmpty);
    });

    test('testRoundTrip_contextRuleIdsOnly', () {
      final p = OZSmartAccountAuthPayload(
        signers: <OZSmartAccountSigner, Uint8List>{},
        contextRuleIds: const <int>[1, 2, 99],
      );
      final encoded = OZSmartAccountAuthPayloadCodec.write(p);
      final decoded = OZSmartAccountAuthPayloadCodec.read(encoded);
      expect(decoded.contextRuleIds, [1, 2, 99]);
    });

    test('testRoundTrip_delegatedSignerWithContextRuleIds', () {
      final s = _del();
      final sig = _bytes(8);
      final p = OZSmartAccountAuthPayload(
        signers: <OZSmartAccountSigner, Uint8List>{s: sig},
        contextRuleIds: const <int>[7],
      );
      final encoded = OZSmartAccountAuthPayloadCodec.write(p);
      final decoded = OZSmartAccountAuthPayloadCodec.read(encoded);
      expect(decoded.contextRuleIds, [7]);
      expect(decoded.signers, hasLength(1));
    });

    test('testRoundTrip_externalSignerWithContextRuleIds', () {
      final s = _ext();
      final sig = _bytes(20);
      final p = OZSmartAccountAuthPayload(
        signers: <OZSmartAccountSigner, Uint8List>{s: sig},
        contextRuleIds: const <int>[3, 4],
      );
      final encoded = OZSmartAccountAuthPayloadCodec.write(p);
      final decoded = OZSmartAccountAuthPayloadCodec.read(encoded);
      expect(decoded.contextRuleIds, [3, 4]);
      expect(decoded.signers, hasLength(1));
    });

    test('testRoundTrip_multipleSignersMixed', () {
      final s1 = _del();
      final s2 = _ext();
      final p = OZSmartAccountAuthPayload(
        signers: <OZSmartAccountSigner, Uint8List>{
          s1: _bytes(4),
          s2: _bytes(8),
        },
        contextRuleIds: const <int>[1],
      );
      final encoded = OZSmartAccountAuthPayloadCodec.write(p);
      final decoded = OZSmartAccountAuthPayloadCodec.read(encoded);
      expect(decoded.signers, hasLength(2));
      expect(decoded.contextRuleIds, [1]);
    });

    test('testFullRoundTrip_complexPayload', () {
      final s1 = _del(kValidGAddress);
      final s2 = _del(kValidGAddress2);
      final s3 = _ext(seed: 1);
      final s4 = _ext(seed: 2);
      final p = OZSmartAccountAuthPayload(
        signers: <OZSmartAccountSigner, Uint8List>{
          s1: _bytes(8),
          s2: _bytes(16),
          s3: _bytes(20),
          s4: _bytes(24),
        },
        contextRuleIds: const <int>[1, 2, 3],
      );
      final encoded = OZSmartAccountAuthPayloadCodec.write(p);
      final decoded = OZSmartAccountAuthPayloadCodec.read(encoded);
      expect(decoded.signers, hasLength(4));
      expect(decoded.contextRuleIds, [1, 2, 3]);
    });

    test('testCodecRead_voidReturnsEmptyPayload', () {
      final out = OZSmartAccountAuthPayloadCodec.read(XdrSCVal.forVoid());
      expect(out.signers, isEmpty);
    });

    test('testCodecRead_nonMapThrows', () {
      expect(
        () => OZSmartAccountAuthPayloadCodec.read(XdrSCVal.forU32(0)),
        throwsA(isA<TransactionSigningFailed>()),
      );
    });

    test('testCodecWriteRead_roundTrip', () {
      final s = _del();
      final p = OZSmartAccountAuthPayload(
        signers: <OZSmartAccountSigner, Uint8List>{s: _bytes(8)},
        contextRuleIds: const <int>[42],
      );
      final encoded = OZSmartAccountAuthPayloadCodec.write(p);
      final decoded = OZSmartAccountAuthPayloadCodec.read(encoded);
      expect(decoded.contextRuleIds, [42]);
      expect(decoded.signers, hasLength(1));
    });

    test('testCodecWriteRead_emptyPayloadRoundTrip', () {
      final p = OZSmartAccountAuthPayload(
        signers: <OZSmartAccountSigner, Uint8List>{},
        contextRuleIds: const <int>[],
      );
      final encoded = OZSmartAccountAuthPayloadCodec.write(p);
      final decoded = OZSmartAccountAuthPayloadCodec.read(encoded);
      expect(decoded.signers, isEmpty);
      expect(decoded.contextRuleIds, isEmpty);
    });

    test('testCodecWrite_producesMapWithTwoEntries', () {
      final p = OZSmartAccountAuthPayload(
        signers: <OZSmartAccountSigner, Uint8List>{},
        contextRuleIds: const <int>[],
      );
      final encoded = OZSmartAccountAuthPayloadCodec.write(p);
      expect(encoded.map?.length, 2);
    });

    test('testCodecUpsertSigner_replacesExisting', () {
      final s = _del();
      final p = OZSmartAccountAuthPayload(
        signers: <OZSmartAccountSigner, Uint8List>{s: _bytes(4, 1)},
        contextRuleIds: const <int>[],
      );
      OZSmartAccountAuthPayloadCodec.upsertSigner(p, s, _bytes(4, 9));
      expect(p.signers, hasLength(1));
      expect(p.signers.values.first[0], 9);
    });

    test('testCodecUpsertSigner_addsNewSigner', () {
      final p = OZSmartAccountAuthPayload(
        signers: <OZSmartAccountSigner, Uint8List>{_del(): _bytes(4)},
        contextRuleIds: const <int>[],
      );
      OZSmartAccountAuthPayloadCodec.upsertSigner(p, _ext(), _bytes(8));
      expect(p.signers, hasLength(2));
    });

    test('testCodecSignerFromScVal_parsesDelegated', () {
      final s = _del();
      final out = OZSmartAccountAuthPayloadCodec.signerFromScVal(s.toScVal());
      expect(out, isA<OZDelegatedSigner>());
    });

    test('testCodecSignerFromScVal_parsesExternal', () {
      final s = _ext();
      final out = OZSmartAccountAuthPayloadCodec.signerFromScVal(s.toScVal());
      expect(out, isA<OZExternalSigner>());
    });

    test('testCodecSignerFromScVal_throwsOnNonVec', () {
      expect(
        () => OZSmartAccountAuthPayloadCodec.signerFromScVal(XdrSCVal.forU32(0)),
        throwsA(isA<TransactionSigningFailed>()),
      );
    });

    test('testCodecSignerFromScVal_throwsOnUnknownTag', () {
      expect(
        () => OZSmartAccountAuthPayloadCodec.signerFromScVal(
          XdrSCVal.forVec([
            XdrSCVal.forSymbol('UnknownTag'),
            XdrSCVal.forAddressStrKey(kValidContractId),
          ]),
        ),
        throwsA(isA<TransactionSigningFailed>()),
      );
    });

    test('testCodecSignerFromScVal_throwsOnEmptyVec', () {
      expect(
        () => OZSmartAccountAuthPayloadCodec.signerFromScVal(XdrSCVal.forVec([])),
        throwsA(isA<TransactionSigningFailed>()),
      );
    });

    test('testCodecWrite_signersSortedByXdrKey', () {
      final s1 = _del(kValidGAddress);
      final s2 = _del(kValidGAddress2);
      final p = OZSmartAccountAuthPayload(
        signers: <OZSmartAccountSigner, Uint8List>{s2: _bytes(8), s1: _bytes(4)},
        contextRuleIds: const <int>[],
      );
      final encoded = OZSmartAccountAuthPayloadCodec.write(p);
      final entries = encoded.map![1].val.map!;
      // Verify the XDR-encoded keys are in ascending order.
      String keyHex(int i) {
        final stream = XdrDataOutputStream();
        XdrSCVal.encode(stream, entries[i].key);
        return Util.bytesToHex(Uint8List.fromList(stream.bytes));
      }

      for (var i = 1; i < entries.length; i++) {
        expect(keyHex(i - 1).compareTo(keyHex(i)) <= 0, isTrue);
      }
    });
  });

  group('upsertSigner', () {
    test('testUpsertSigner_addToEmptyPayload', () {
      final p = OZSmartAccountAuthPayload(
        signers: <OZSmartAccountSigner, Uint8List>{},
        contextRuleIds: const <int>[],
      );
      OZSmartAccountAuthPayloadCodec.upsertSigner(p, _del(), _bytes(4));
      expect(p.signers, hasLength(1));
    });

    test('testUpsertSigner_addSecondDistinctSigner', () {
      final p = OZSmartAccountAuthPayload(
        signers: <OZSmartAccountSigner, Uint8List>{_del(): _bytes(4)},
        contextRuleIds: const <int>[],
      );
      OZSmartAccountAuthPayloadCodec.upsertSigner(p, _ext(), _bytes(8));
      expect(p.signers, hasLength(2));
    });

    test('testUpsertSigner_replacesExistingOZDelegatedSigner', () {
      final s = _del();
      final p = OZSmartAccountAuthPayload(
        signers: <OZSmartAccountSigner, Uint8List>{s: _bytes(4, 1)},
        contextRuleIds: const <int>[],
      );
      OZSmartAccountAuthPayloadCodec.upsertSigner(
          p, _del(kValidGAddress), _bytes(4, 9));
      expect(p.signers, hasLength(1));
      expect(p.signers.values.first[0], 9);
    });

    test('testUpsertSigner_replacesExistingOZExternalSigner', () {
      final s = _ext(seed: 1);
      final p = OZSmartAccountAuthPayload(
        signers: <OZSmartAccountSigner, Uint8List>{s: _bytes(4, 1)},
        contextRuleIds: const <int>[],
      );
      OZSmartAccountAuthPayloadCodec.upsertSigner(
          p, _ext(seed: 1), _bytes(4, 9));
      expect(p.signers, hasLength(1));
    });

    test('testUpsertSigner_doesNotReplaceDifferentSignerType', () {
      final p = OZSmartAccountAuthPayload(
        signers: <OZSmartAccountSigner, Uint8List>{_del(): _bytes(4)},
        contextRuleIds: const <int>[],
      );
      OZSmartAccountAuthPayloadCodec.upsertSigner(p, _ext(), _bytes(8));
      expect(p.signers, hasLength(2));
    });

    test('testUpsertSigner_preservesContextRuleIds', () {
      final p = OZSmartAccountAuthPayload(
        signers: <OZSmartAccountSigner, Uint8List>{},
        contextRuleIds: const <int>[1, 2, 3],
      );
      OZSmartAccountAuthPayloadCodec.upsertSigner(p, _del(), _bytes(4));
      expect(p.contextRuleIds, [1, 2, 3]);
    });

    test('testUpsertSigner_multipleUpsertsOnSameSigner', () {
      final s = _del();
      final p = OZSmartAccountAuthPayload(
        signers: <OZSmartAccountSigner, Uint8List>{},
        contextRuleIds: const <int>[],
      );
      for (var i = 0; i < 5; i++) {
        OZSmartAccountAuthPayloadCodec.upsertSigner(p, s, _bytes(4, i));
      }
      expect(p.signers, hasLength(1));
      expect(p.signers.values.first[0], 4);
    });

    test('testUpsertThenWriteAndRead_replacedSignerNotPresent', () {
      final s = _del();
      final p = OZSmartAccountAuthPayload(
        signers: <OZSmartAccountSigner, Uint8List>{s: _bytes(4, 1)},
        contextRuleIds: const <int>[],
      );
      OZSmartAccountAuthPayloadCodec.upsertSigner(p, s, _bytes(4, 9));
      final encoded = OZSmartAccountAuthPayloadCodec.write(p);
      final decoded = OZSmartAccountAuthPayloadCodec.read(encoded);
      expect(decoded.signers, hasLength(1));
      expect(decoded.signers.values.first[0], 9);
    });
  });

  group('signerFromScVal validation', () {
    test('testSignerFromScVal_delegatedSigner', () {
      final s = _del();
      final out = OZSmartAccountAuthPayloadCodec.signerFromScVal(s.toScVal());
      expect(out, isA<OZDelegatedSigner>());
    });

    test('testSignerFromScVal_delegatedSignerWithContractAddress', () {
      final s = OZDelegatedSigner(kValidContractId);
      final out = OZSmartAccountAuthPayloadCodec.signerFromScVal(s.toScVal());
      expect(out, isA<OZDelegatedSigner>());
    });

    test('testSignerFromScVal_externalSigner', () {
      final s = _ext();
      final out = OZSmartAccountAuthPayloadCodec.signerFromScVal(s.toScVal());
      expect(out, isA<OZExternalSigner>());
    });

    test('testSignerFromScVal_nonVecThrows', () {
      expect(
        () => OZSmartAccountAuthPayloadCodec.signerFromScVal(XdrSCVal.forU32(0)),
        throwsA(isA<TransactionSigningFailed>()),
      );
    });

    test('testSignerFromScVal_emptyVecThrows', () {
      expect(
        () => OZSmartAccountAuthPayloadCodec.signerFromScVal(XdrSCVal.forVec([])),
        throwsA(isA<TransactionSigningFailed>()),
      );
    });

    test('testSignerFromScVal_firstElementNotSymbolThrows', () {
      expect(
        () => OZSmartAccountAuthPayloadCodec.signerFromScVal(
          XdrSCVal.forVec([
            XdrSCVal.forU32(0),
            XdrSCVal.forAddressStrKey(kValidGAddress),
          ]),
        ),
        throwsA(isA<TransactionSigningFailed>()),
      );
    });

    test('testSignerFromScVal_unknownTypeTagThrows', () {
      expect(
        () => OZSmartAccountAuthPayloadCodec.signerFromScVal(
          XdrSCVal.forVec([
            XdrSCVal.forSymbol('UnknownTag'),
            XdrSCVal.forAddressStrKey(kValidContractId),
          ]),
        ),
        throwsA(isA<TransactionSigningFailed>()),
      );
    });

    test('testSignerFromScVal_delegatedWithTooFewElementsThrows', () {
      expect(
        () => OZSmartAccountAuthPayloadCodec.signerFromScVal(
          XdrSCVal.forVec([XdrSCVal.forSymbol('Delegated')]),
        ),
        throwsA(isA<TransactionSigningFailed>()),
      );
    });

    test('testSignerFromScVal_delegatedSecondElementNotAddressThrows', () {
      expect(
        () => OZSmartAccountAuthPayloadCodec.signerFromScVal(
          XdrSCVal.forVec([
            XdrSCVal.forSymbol('Delegated'),
            XdrSCVal.forU32(7),
          ]),
        ),
        throwsA(isA<TransactionSigningFailed>()),
      );
    });

    test('testSignerFromScVal_externalWithTooFewElementsThrows', () {
      expect(
        () => OZSmartAccountAuthPayloadCodec.signerFromScVal(
          XdrSCVal.forVec([
            XdrSCVal.forSymbol('External'),
            XdrSCVal.forAddressStrKey(kValidContractId),
          ]),
        ),
        throwsA(isA<TransactionSigningFailed>()),
      );
    });

    test('testSignerFromScVal_externalSecondElementNotAddressThrows', () {
      expect(
        () => OZSmartAccountAuthPayloadCodec.signerFromScVal(
          XdrSCVal.forVec([
            XdrSCVal.forSymbol('External'),
            XdrSCVal.forU32(7),
            XdrSCVal.forBytes(_bytes(4)),
          ]),
        ),
        throwsA(isA<TransactionSigningFailed>()),
      );
    });

    test('testSignerFromScVal_externalThirdElementNotBytesThrows', () {
      expect(
        () => OZSmartAccountAuthPayloadCodec.signerFromScVal(
          XdrSCVal.forVec([
            XdrSCVal.forSymbol('External'),
            XdrSCVal.forAddressStrKey(kValidContractId),
            XdrSCVal.forU32(7),
          ]),
        ),
        throwsA(isA<TransactionSigningFailed>()),
      );
    });

    test('testSignerFromScVal_externalWithOnlySymbolThrows', () {
      expect(
        () => OZSmartAccountAuthPayloadCodec.signerFromScVal(
          XdrSCVal.forVec([XdrSCVal.forSymbol('External')]),
        ),
        throwsA(isA<TransactionSigningFailed>()),
      );
    });
  });

  // Cross-SDK byte-identity golden vector (AuthPayload codec).
  //
  // Pins the byte-level XDR encoding of the OZ AuthPayload outer named-struct
  // map plus inner signer-map sort. Uses deterministic strkey constants
  // (rather than randomly-generated KeyPairs) so the encoded bytes are
  // reproducible across SDKs. The expected hex is byte-identical to the
  // matching fixture in the sibling SDK and must be updated in lockstep.
  group('cross-SDK AuthPayload codec golden vector', () {
    test(
        'goldenVector5_authPayloadWithTwoDelegatedSigners_matchesFixture',
        () {
      final signerA = OZDelegatedSigner(kValidGAddress);
      final signerB = OZDelegatedSigner(kValidContractId);
      final payload = OZSmartAccountAuthPayload(
        signers: <OZSmartAccountSigner, Uint8List>{
          signerA: Uint8List.fromList(const <int>[0xAA, 0xBB]),
          signerB: Uint8List.fromList(const <int>[0xCC, 0xDD]),
        },
        contextRuleIds: const <int>[7, 11],
      );

      final scVal = OZSmartAccountAuthPayloadCodec.write(payload);
      final stream = XdrDataOutputStream();
      XdrSCVal.encode(stream, scVal);
      final encoded = Uint8List.fromList(stream.bytes);
      final actualHex = Util.bytesToHex(encoded).toLowerCase();
      const expectedHex =
          '0000001100000001000000020000000f00000010636f6e746578745f72756c655f6964730000001000000001000000020000000300000007000000030000000b0000000f000000077369676e657273000000001100000001000000020000001000000001000000020000000f0000000944656c656761746564000000000000120000000000000000e8a61a861e60af60f80773e06346e5c72cbe59dcadda37608d58ef42511d9fdc0000000d00000002aabb00000000001000000001000000020000000f0000000944656c6567617465640000000000001200000001c58b2bfbc4f054e7324f6bf20cad3e026e41bbad1a6d20c3d7d4918ded1654110000000d00000002ccdd0000';
      expect(actualHex, expectedHex,
          reason: 'Golden vector 5 mismatch — actual: $actualHex');
    });
  });
}
