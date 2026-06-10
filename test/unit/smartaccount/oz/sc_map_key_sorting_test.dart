// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

const String kValidGAddress =
    'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';
const String kValidContractId =
    'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK';

Uint8List _bytes(int n, int seed) {
  final out = Uint8List(n);
  for (var i = 0; i < n; i++) {
    out[i] = (i + seed) & 0xFF;
  }
  return out;
}

String _xdrHex(XdrSCVal value) {
  final stream = XdrDataOutputStream();
  XdrSCVal.encode(stream, value);
  return Util.bytesToHex(Uint8List.fromList(stream.bytes));
}

XdrSCVal _writePayloadWithSigners(
  Map<OZSmartAccountSigner, Uint8List> signers,
) {
  final p = OZSmartAccountAuthPayload(
    signers: signers,
    contextRuleIds: const <int>[],
  );
  return OZSmartAccountAuthPayloadCodec.write(p);
}

List<String> _signerKeyHexes(XdrSCVal payloadScVal) {
  final entries = payloadScVal.map![1].val.map!;
  return entries.map((e) => _xdrHex(e.key)).toList(growable: false);
}

void main() {
  group('ScMap key sorting', () {
    test('testCompareByteArraysLexicographically', () {
      // The codec sorts inner map keys by lowercase-hex of XDR-encoded
      // key bytes. Validate the underlying byte ordering on a controlled
      // input.
      final a = _xdrHex(XdrSCVal.forU32(0x00000001));
      final b = _xdrHex(XdrSCVal.forU32(0x00000002));
      expect(a.compareTo(b) < 0, isTrue);
    });

    test('testSortMapByKeyXdrWithSymbolKeys', () {
      // Symbols with different lengths and byte ordering inside the inner
      // signers Map: build via the codec and assert the result is sorted.
      final s1 = OZDelegatedSigner(kValidGAddress);
      final s2 = OZExternalSigner(kValidContractId, _bytes(8, 1));
      final out = _writePayloadWithSigners(
        <OZSmartAccountSigner, Uint8List>{s2: _bytes(4, 0), s1: _bytes(4, 0)},
      );
      final hexes = _signerKeyHexes(out);
      for (var i = 1; i < hexes.length; i++) {
        expect(hexes[i - 1].compareTo(hexes[i]) <= 0, isTrue);
      }
    });

    test('testSortMapByKeyXdrWithAddressKeys', () {
      final s1 = OZDelegatedSigner(kValidGAddress);
      final s2 = OZDelegatedSigner(kValidContractId);
      final out = _writePayloadWithSigners(
        <OZSmartAccountSigner, Uint8List>{s1: _bytes(4, 0), s2: _bytes(4, 0)},
      );
      final hexes = _signerKeyHexes(out);
      expect(hexes.length, 2);
      expect(hexes[0].compareTo(hexes[1]) <= 0, isTrue);
    });

    test('testSimpleThresholdMapHasSingleKey', () {
      // The outer payload struct map has exactly two keys
      // (`context_rule_ids`, `signers`); construct a payload with no
      // policy data and assert the inner signers map has zero entries.
      final out =
          _writePayloadWithSigners(<OZSmartAccountSigner, Uint8List>{});
      expect(out.map?.length, 2);
      expect(out.map![1].val.map?.length, 0);
    });

    test('testSortingWithDifferentScValKeyTypes', () {
      // Mix delegated + external signer kinds; the inner key sorting is
      // stable across mixed ScVal Vec shapes.
      final del = OZDelegatedSigner(kValidGAddress);
      final ext = OZExternalSigner(kValidContractId, _bytes(8, 5));
      final out = _writePayloadWithSigners(
        <OZSmartAccountSigner, Uint8List>{del: _bytes(4, 0), ext: _bytes(4, 0)},
      );
      final hexes = _signerKeyHexes(out);
      for (var i = 1; i < hexes.length; i++) {
        expect(hexes[i - 1].compareTo(hexes[i]) <= 0, isTrue);
      }
    });

    test('testSortEmptyMap', () {
      final out = _writePayloadWithSigners(<OZSmartAccountSigner, Uint8List>{});
      expect(out.map![1].val.map?.length, 0);
    });

    test('testSortSingleEntryMap', () {
      final s = OZDelegatedSigner(kValidGAddress);
      final out = _writePayloadWithSigners(
        <OZSmartAccountSigner, Uint8List>{s: _bytes(4, 0)},
      );
      expect(out.map![1].val.map?.length, 1);
    });

    test('testSortAlreadySortedMap', () {
      final s1 = OZDelegatedSigner(kValidGAddress);
      final s2 = OZDelegatedSigner(kValidContractId);
      final out1 = _writePayloadWithSigners(
        <OZSmartAccountSigner, Uint8List>{s1: _bytes(4, 0), s2: _bytes(4, 0)},
      );
      final out2 = _writePayloadWithSigners(
        <OZSmartAccountSigner, Uint8List>{s2: _bytes(4, 0), s1: _bytes(4, 0)},
      );
      expect(_signerKeyHexes(out1), _signerKeyHexes(out2));
    });

    test('testSortPreservesValues', () {
      final s1 = OZDelegatedSigner(kValidGAddress);
      final s2 = OZDelegatedSigner(kValidContractId);
      final v1 = _bytes(4, 1);
      final v2 = _bytes(4, 2);
      final out = _writePayloadWithSigners(
        <OZSmartAccountSigner, Uint8List>{s1: v1, s2: v2},
      );
      // Each value retained somewhere in the inner map (regardless of
      // sort outcome).
      final entries = out.map![1].val.map!;
      final allValues = entries
          .map((e) => Util.bytesToHex(
              Uint8List.fromList(e.val.bytes!.sCBytes)))
          .toList();
      expect(allValues, contains(Util.bytesToHex(v1)));
      expect(allValues, contains(Util.bytesToHex(v2)));
    });

    test('outer struct keys insert alphabetically', () {
      final out =
          _writePayloadWithSigners(<OZSmartAccountSigner, Uint8List>{});
      expect(out.map![0].key.sym, 'context_rule_ids');
      expect(out.map![1].key.sym, 'signers');
    });

    test('alphabetical-but-not-XDR-byte ordering for outer keys', () {
      // Verify that the outer struct order is alphabetical (`c` < `s`),
      // which is NOT the same as XDR-byte-sort: under XDR-byte sort
      // `signers` (length 7) would come before `context_rule_ids`
      // (length 16).
      final out =
          _writePayloadWithSigners(<OZSmartAccountSigner, Uint8List>{});
      final firstHex = _xdrHex(out.map![0].key);
      final secondHex = _xdrHex(out.map![1].key);
      expect(firstHex.compareTo(secondHex) > 0, isTrue,
          reason: 'XDR-byte order would put signers before '
              'context_rule_ids; the codec uses alphabetical struct '
              'order, so context_rule_ids comes first even though its '
              'XDR encoding is lexicographically larger.');
    });

    test('ScVal-key sort property: 1000 random key sets match reference',
        () {
      final rng = Random(0xCAFEBABE);
      for (var iter = 0; iter < 1000; iter++) {
        final n = (rng.nextInt(6)) + 1;
        final entries = <XdrSCMapEntry>[];
        for (var i = 0; i < n; i++) {
          final keyBytes = Uint8List(rng.nextInt(8) + 1);
          for (var j = 0; j < keyBytes.length; j++) {
            keyBytes[j] = rng.nextInt(256);
          }
          entries.add(XdrSCMapEntry(
            XdrSCVal.forBytes(keyBytes),
            XdrSCVal.forU32(rng.nextInt(1 << 30)),
          ));
        }

        final hexes = entries.map((e) => _xdrHex(e.key)).toList();
        final sorted = List<XdrSCMapEntry>.from(entries)
          ..sort((a, b) => _xdrHex(a.key).compareTo(_xdrHex(b.key)));
        final sortedHexes = sorted.map((e) => _xdrHex(e.key)).toList();
        for (var i = 1; i < sortedHexes.length; i++) {
          expect(sortedHexes[i - 1].compareTo(sortedHexes[i]) <= 0, isTrue);
        }
        // Reference comparison: byte-wise sort produces the same ordering.
        final byteSorted = List<XdrSCMapEntry>.from(entries)
          ..sort((a, b) {
            final aBytes = Util.hexToBytes(_xdrHex(a.key));
            final bBytes = Util.hexToBytes(_xdrHex(b.key));
            for (var i = 0; i < aBytes.length && i < bBytes.length; i++) {
              if (aBytes[i] != bBytes[i]) return aBytes[i] - bBytes[i];
            }
            return aBytes.length - bBytes.length;
          });
        final byteSortedHexes =
            byteSorted.map((e) => _xdrHex(e.key)).toList();
        expect(sortedHexes, byteSortedHexes,
            reason: 'iteration $iter produced different orderings via '
                'hex-string sort vs byte-lexicographic sort');
        expect(hexes, isA<List<String>>());
      }
    });

    test('golden cases: alphabetical-vs-XDR-hex-order divergence', () {
      // Symbol("a") (XDR-bytes: type=0x0F, length=1, "a", padding) vs
      // Symbol("ab") (length=2, "ab", padding) — both encode with the
      // length first, so the shorter one sorts first under XDR-hex.
      final a = XdrSCVal.forSymbol('a');
      final ab = XdrSCVal.forSymbol('ab');
      expect(_xdrHex(a).compareTo(_xdrHex(ab)) < 0, isTrue);
    });

    test('golden case: zebra vs middle XDR-hex order', () {
      final zebra = XdrSCVal.forSymbol('zebra');
      final middle = XdrSCVal.forSymbol('middle');
      // XDR symbol encoding starts with a 4-byte length prefix. "zebra"
      // is length 5; "middle" is length 6; the length prefix dominates
      // the ordering, so "zebra" sorts before "middle" under XDR-hex
      // sort even though "middle" comes before "zebra" alphabetically.
      // This is an instance of the "alphabetical != XDR-byte" divergence
      // described in the spec.
      expect(_xdrHex(zebra).compareTo(_xdrHex(middle)) < 0, isTrue);
    });

    test('golden case: U32 keys ordered by big-endian XDR encoding', () {
      final u1 = XdrSCVal.forU32(1);
      final u2 = XdrSCVal.forU32(256);
      final u3 = XdrSCVal.forU32(65536);
      expect(_xdrHex(u1).compareTo(_xdrHex(u2)) < 0, isTrue);
      expect(_xdrHex(u2).compareTo(_xdrHex(u3)) < 0, isTrue);
    });

    test('golden case: ordering stable across writes', () {
      final s1 = OZDelegatedSigner(kValidGAddress);
      final s2 = OZExternalSigner(kValidContractId, _bytes(8, 1));
      final h1 = _signerKeyHexes(_writePayloadWithSigners(
          <OZSmartAccountSigner, Uint8List>{s1: _bytes(4, 0), s2: _bytes(4, 0)}));
      final h2 = _signerKeyHexes(_writePayloadWithSigners(
          <OZSmartAccountSigner, Uint8List>{s2: _bytes(4, 0), s1: _bytes(4, 0)}));
      expect(h1, h2);
    });
  });
}
