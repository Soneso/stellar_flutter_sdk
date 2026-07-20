// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/src/smartaccount/core/sc_val_host_order.dart';
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

List<XdrSCVal> _signerKeys(XdrSCVal payloadScVal) {
  final entries = payloadScVal.map![1].val.map!;
  return entries.map((e) => e.key).toList(growable: false);
}

/// Asserts that [keys] are strictly ascending in the Soroban host's ScMap
/// key order.
void _assertKeysInHostOrder(List<XdrSCVal> keys) {
  for (var i = 1; i < keys.length; i++) {
    expect(compareScValHostOrder(keys[i - 1], keys[i]) < 0, isTrue,
        reason: 'key at index ${i - 1} must precede key at index $i '
            'in host order');
  }
}

void main() {
  group('ScMap key sorting', () {
    test('testCompareScValHostOrder_u32NumericOrder', () {
      // The codec sorts inner map keys in the host's ScMap key order.
      // Validate the underlying comparator on a controlled scalar input.
      final a = XdrSCVal.forU32(0x00000001);
      final b = XdrSCVal.forU32(0x00000002);
      expect(compareScValHostOrder(a, b) < 0, isTrue);
    });

    test('testSortMapByKeyXdrWithSymbolKeys', () {
      // Signer keys with different Vec shapes inside the inner signers Map:
      // build via the codec and assert the result is in host key order.
      final s1 = OZDelegatedSigner(kValidGAddress);
      final s2 = OZExternalSigner(kValidContractId, _bytes(8, 1));
      final out = _writePayloadWithSigners(
        <OZSmartAccountSigner, Uint8List>{s2: _bytes(4, 0), s1: _bytes(4, 0)},
      );
      _assertKeysInHostOrder(_signerKeys(out));
    });

    test('testSortMapByKeyXdrWithAddressKeys', () {
      final s1 = OZDelegatedSigner(kValidGAddress);
      final s2 = OZDelegatedSigner(kValidContractId);
      final out = _writePayloadWithSigners(
        <OZSmartAccountSigner, Uint8List>{s1: _bytes(4, 0), s2: _bytes(4, 0)},
      );
      final keys = _signerKeys(out);
      expect(keys.length, 2);
      _assertKeysInHostOrder(keys);
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
      _assertKeysInHostOrder(_signerKeys(out));
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
      // The production comparator over Bytes keys must agree with a
      // reference implementation of the host's content order (Rust slice
      // `Ord`: element-wise unsigned bytes, shorter first on a prefix tie).
      int referenceHostCompare(Uint8List a, Uint8List b) {
        for (var i = 0; i < a.length && i < b.length; i++) {
          if (a[i] != b[i]) return a[i] - b[i];
        }
        return a.length - b.length;
      }

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

        final sorted = OZPolicyManager.sortMapByKeyXdr(entries);
        final sortedHexes = sorted.map((e) => _xdrHex(e.key)).toList();
        final referenceSorted = List<XdrSCMapEntry>.from(entries)
          ..sort((a, b) => referenceHostCompare(
              a.key.bytes!.sCBytes, b.key.bytes!.sCBytes));
        final referenceHexes =
            referenceSorted.map((e) => _xdrHex(e.key)).toList();
        expect(sortedHexes, referenceHexes,
            reason: 'iteration $iter produced an ordering that differs '
                'from the reference host content order');
      }
    });

    test('golden case: prefix tie sorts the shorter symbol first', () {
      // Symbol("a") is a prefix of Symbol("ab"); on a prefix tie the
      // shorter value sorts first in host order.
      final a = XdrSCVal.forSymbol('a');
      final ab = XdrSCVal.forSymbol('ab');
      expect(compareScValHostOrder(a, ab) < 0, isTrue);
      expect(compareScValHostOrder(ab, a) > 0, isTrue);
    });

    test('golden case: middle vs zebra host order diverges from length-major',
        () {
      final zebra = XdrSCVal.forSymbol('zebra');
      final middle = XdrSCVal.forSymbol('middle');
      // Host order compares symbol content byte for byte: "middle" (0x6d)
      // sorts before "zebra" (0x7a) despite being longer. A length-major
      // XDR-byte sort would order the 5-char "zebra" before the 6-char
      // "middle" via the length prefix — the exact divergence the host
      // rejects. Pin both directions.
      expect(compareScValHostOrder(middle, zebra) < 0, isTrue);
      expect(_xdrHex(zebra).compareTo(_xdrHex(middle)) < 0, isTrue,
          reason: 'the length-major XDR-hex order disagrees with the host '
              'order for these symbols');
    });

    test('golden case: U32 keys ordered by numeric value', () {
      // For unsigned fixed-width scalars the host order equals the
      // big-endian XDR encoding order.
      final u1 = XdrSCVal.forU32(1);
      final u2 = XdrSCVal.forU32(256);
      final u3 = XdrSCVal.forU32(65536);
      expect(compareScValHostOrder(u1, u2) < 0, isTrue);
      expect(compareScValHostOrder(u2, u3) < 0, isTrue);
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
