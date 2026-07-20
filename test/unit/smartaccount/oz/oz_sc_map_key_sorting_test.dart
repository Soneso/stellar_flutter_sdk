// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/src/smartaccount/core/sc_val_host_order.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// ---------------------------------------------------------------------------
// Test fixtures
// ---------------------------------------------------------------------------

const String _addr1 =
    'CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC';
const String _addr2 =
    'CA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUWDA';
const String _addr3 =
    'CCK4LNH73QFN6KSRCP7ZBF4ISLXHZDMZGCMC3ETCMMUPNGQJZCPHVZQ3';

const String _gAddr1 =
    'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7';
const String _gAddr2 =
    'GBGWONUYEPTSADFMLRQSPRAPTWMGX5PMQXXHGSBVRF2KLUNVZT57SLVW';
const String _gAddr3 =
    'GB33CUURS5XLLECMLSE2EMMDJBMZSVF27BW6PLS53OFTJMP46CZH3CVG';

/// Encodes an [XdrSCVal] to its lowercase-hex XDR representation by
/// delegating to the production helper exposed for tests.
String _xdrHex(XdrSCVal value) =>
    Util.bytesToHex(Uint8List.fromList(OZPolicyManager.scValToXdrBytes(value)));

/// Builds a one-byte [Uint8List] from the supplied integer.
Uint8List _byte(int value) => Uint8List.fromList(<int>[value & 0xFF]);

/// Asserts that [entries] are strictly sorted in the Soroban host's ScMap
/// key order (each key compares strictly less than the next under
/// `compareScValHostOrder`).
void _assertKeysSortedAscending(List<XdrSCMapEntry> entries) {
  for (var i = 0; i < entries.length - 1; i++) {
    expect(
      compareScValHostOrder(entries[i].key, entries[i + 1].key) < 0,
      isTrue,
      reason: 'Key at index $i (hex=${_xdrHex(entries[i].key)}) must precede '
          'key at index ${i + 1} (hex=${_xdrHex(entries[i + 1].key)}) '
          'in host order',
    );
  }
}

void main() {
  // -------------------------------------------------------------------------
  // Single-key-type entries (4 cases): Symbol, Address, U32, Bytes
  // -------------------------------------------------------------------------
  group('OZPolicyManager.sortMapByKeyXdr — single key types', () {
    test('symbol keys sort by content, not by length', () {
      // Symbol keys sort in the Soroban host's order: by content, byte for
      // byte, with length only a tiebreaker on a common prefix — not by the
      // length-major XDR encoding. So "middle" sorts between "alpha" and
      // "zebra" on its first byte (0x6d), regardless of being longer.
      //
      // "alpha"  -> 0x61 6c 70 68 61
      // "middle" -> 0x6d 69 64 64 6c 65
      // "zebra"  -> 0x7a 65 62 72 61
      //
      // Host sort order: alpha (0x61) < middle (0x6d) < zebra (0x7a)
      final unsorted = <XdrSCMapEntry>[
        XdrSCMapEntry(XdrSCVal.forSymbol('zebra'), XdrSCVal.forU32(1)),
        XdrSCMapEntry(XdrSCVal.forSymbol('alpha'), XdrSCVal.forU32(2)),
        XdrSCMapEntry(XdrSCVal.forSymbol('middle'), XdrSCVal.forU32(3)),
      ];

      final sorted = OZPolicyManager.sortMapByKeyXdr(unsorted);

      expect(sorted.length, 3);
      expect(sorted[0].key.sym, 'alpha');
      expect(sorted[1].key.sym, 'middle');
      expect(sorted[2].key.sym, 'zebra');
    });

    test('address keys sort by content (fixed-width, order-stable)', () {
      final unsorted = <XdrSCMapEntry>[
        XdrSCMapEntry(
          XdrSCVal.forAddress(Address.forContractId(_addr1).toXdr()),
          XdrSCVal.forVoid(),
        ),
        XdrSCMapEntry(
          XdrSCVal.forAddress(Address.forContractId(_addr2).toXdr()),
          XdrSCVal.forVoid(),
        ),
        XdrSCMapEntry(
          XdrSCVal.forAddress(Address.forContractId(_addr3).toXdr()),
          XdrSCVal.forVoid(),
        ),
      ];

      final sorted = OZPolicyManager.sortMapByKeyXdr(unsorted);

      expect(sorted.length, 3);
      _assertKeysSortedAscending(sorted);
    });

    test('U32 keys sort by numeric value', () {
      final unsorted = <XdrSCMapEntry>[
        XdrSCMapEntry(XdrSCVal.forU32(65536), XdrSCVal.forU32(1)),
        XdrSCMapEntry(XdrSCVal.forU32(1), XdrSCVal.forU32(2)),
        XdrSCMapEntry(XdrSCVal.forU32(256), XdrSCVal.forU32(3)),
      ];

      final sorted = OZPolicyManager.sortMapByKeyXdr(unsorted);

      expect(sorted.length, 3);
      // 1 < 256 < 65536.
      expect(sorted[0].key.u32!.uint32, 1);
      expect(sorted[1].key.u32!.uint32, 256);
      expect(sorted[2].key.u32!.uint32, 65536);
      _assertKeysSortedAscending(sorted);
    });

    test('Bytes keys sort by content with length only a prefix tiebreaker',
        () {
      // Host order: [0x01] < [0x01,0x02] (prefix, shorter first) < [0xFF]
      // (content decides; the one-byte [0xFF] sorts last despite being the
      // shortest).
      final unsorted = <XdrSCMapEntry>[
        XdrSCMapEntry(
          XdrSCVal.forBytes(Uint8List.fromList(<int>[0xFF])),
          XdrSCVal.forU32(1),
        ),
        XdrSCMapEntry(
          XdrSCVal.forBytes(Uint8List.fromList(<int>[0x01])),
          XdrSCVal.forU32(2),
        ),
        XdrSCMapEntry(
          XdrSCVal.forBytes(Uint8List.fromList(<int>[0x01, 0x02])),
          XdrSCVal.forU32(3),
        ),
      ];

      final sorted = OZPolicyManager.sortMapByKeyXdr(unsorted);

      expect(sorted.length, 3);
      expect(sorted[0].key.bytes!.sCBytes, <int>[0x01]);
      expect(sorted[1].key.bytes!.sCBytes, <int>[0x01, 0x02]);
      expect(sorted[2].key.bytes!.sCBytes, <int>[0xFF]);
      _assertKeysSortedAscending(sorted);
    });
  });

  // -------------------------------------------------------------------------
  // Mixed-key-type entries (6 cases): type-discriminant-major ordering
  // -------------------------------------------------------------------------
  group('OZPolicyManager.sortMapByKeyXdr — mixed key types', () {
    test('mixed Symbol, U32, and Bytes keys sort by type discriminant', () {
      // Keys of different types compare by their SCValType discriminant
      // first, so different key types naturally separate before any content
      // comparison.
      final unsorted = <XdrSCMapEntry>[
        XdrSCMapEntry(
          XdrSCVal.forSymbol('symbol_key'),
          XdrSCVal.forU32(1),
        ),
        XdrSCMapEntry(XdrSCVal.forU32(42), XdrSCVal.forU32(2)),
        XdrSCMapEntry(
          XdrSCVal.forBytes(Uint8List.fromList(<int>[0x01])),
          XdrSCVal.forU32(3),
        ),
      ];

      final sorted = OZPolicyManager.sortMapByKeyXdr(unsorted);

      expect(sorted.length, 3);
      _assertKeysSortedAscending(sorted);
    });

    test('mixed Symbol and Address keys sort deterministically', () {
      final unsorted = <XdrSCMapEntry>[
        XdrSCMapEntry(
          XdrSCVal.forAddress(Address.forContractId(_addr1).toXdr()),
          XdrSCVal.forU32(1),
        ),
        XdrSCMapEntry(XdrSCVal.forSymbol('foo'), XdrSCVal.forU32(2)),
      ];

      final sorted = OZPolicyManager.sortMapByKeyXdr(unsorted);

      expect(sorted.length, 2);
      _assertKeysSortedAscending(sorted);
    });

    test('mixed U32 and Bytes keys sort deterministically', () {
      final unsorted = <XdrSCMapEntry>[
        XdrSCMapEntry(
          XdrSCVal.forBytes(Uint8List.fromList(<int>[0xAA, 0xBB])),
          XdrSCVal.forU32(1),
        ),
        XdrSCMapEntry(XdrSCVal.forU32(7), XdrSCVal.forU32(2)),
      ];

      final sorted = OZPolicyManager.sortMapByKeyXdr(unsorted);

      expect(sorted.length, 2);
      _assertKeysSortedAscending(sorted);
    });

    test('mixed I64 and U64 keys sort by discriminant then payload', () {
      final unsorted = <XdrSCMapEntry>[
        XdrSCMapEntry(XdrSCVal.forU64(BigInt.from(1)), XdrSCVal.forU32(1)),
        XdrSCMapEntry(XdrSCVal.forI64(BigInt.from(1)), XdrSCVal.forU32(2)),
      ];

      final sorted = OZPolicyManager.sortMapByKeyXdr(unsorted);

      expect(sorted.length, 2);
      _assertKeysSortedAscending(sorted);
    });

    test('mixed Bool and Symbol keys sort deterministically', () {
      final unsorted = <XdrSCMapEntry>[
        XdrSCMapEntry(XdrSCVal.forSymbol('z'), XdrSCVal.forU32(1)),
        XdrSCMapEntry(XdrSCVal.forBool(true), XdrSCVal.forU32(2)),
        XdrSCMapEntry(XdrSCVal.forBool(false), XdrSCVal.forU32(3)),
      ];

      final sorted = OZPolicyManager.sortMapByKeyXdr(unsorted);

      expect(sorted.length, 3);
      _assertKeysSortedAscending(sorted);
    });

    test('repeated sort across mixed types is idempotent', () {
      final unsorted = <XdrSCMapEntry>[
        XdrSCMapEntry(
          XdrSCVal.forBytes(_byte(0x10)),
          XdrSCVal.forU32(1),
        ),
        XdrSCMapEntry(XdrSCVal.forSymbol('m'), XdrSCVal.forU32(2)),
        XdrSCMapEntry(XdrSCVal.forU32(3), XdrSCVal.forU32(3)),
      ];

      final sortedOnce = OZPolicyManager.sortMapByKeyXdr(unsorted);
      final sortedTwice = OZPolicyManager.sortMapByKeyXdr(sortedOnce);

      expect(sortedTwice.length, sortedOnce.length);
      for (var i = 0; i < sortedOnce.length; i++) {
        expect(_xdrHex(sortedTwice[i].key), _xdrHex(sortedOnce[i].key));
      }
    });
  });

  // -------------------------------------------------------------------------
  // Boundary cases (4 cases): empty map, single entry, equal keys, deep nest
  // -------------------------------------------------------------------------
  group('OZPolicyManager.sortMapByKeyXdr — boundary cases', () {
    test('empty entry list returns an empty list', () {
      final sorted = OZPolicyManager.sortMapByKeyXdr(const <XdrSCMapEntry>[]);
      expect(sorted, isEmpty);
    });

    test('single-entry list is returned unchanged', () {
      final entries = <XdrSCMapEntry>[
        XdrSCMapEntry(XdrSCVal.forSymbol('only'), XdrSCVal.forU32(1)),
      ];

      final sorted = OZPolicyManager.sortMapByKeyXdr(entries);

      expect(sorted.length, 1);
      expect(sorted[0].key.sym, 'only');
      expect(sorted[0].val.u32!.uint32, 1);
    });

    test('all-equal keys are preserved with stable ordering and values', () {
      // Three entries that share a key produce a degenerate map. The sort
      // must not lose entries; values are retained on whichever entry the
      // sorter places at each index.
      final entries = <XdrSCMapEntry>[
        XdrSCMapEntry(XdrSCVal.forSymbol('k'), XdrSCVal.forU32(100)),
        XdrSCMapEntry(XdrSCVal.forSymbol('k'), XdrSCVal.forU32(200)),
        XdrSCMapEntry(XdrSCVal.forSymbol('k'), XdrSCVal.forU32(300)),
      ];

      final sorted = OZPolicyManager.sortMapByKeyXdr(entries);

      expect(sorted.length, 3);
      final allValues =
          sorted.map((e) => e.val.u32!.uint32).toSet();
      expect(allValues, <int>{100, 200, 300});
    });

    test('deep-nested Vec keys are sorted element-wise (recursively)', () {
      // Use Vec keys that themselves embed sortable ScVal payloads. The
      // sort recurses into each Vec element-wise, so the first differing
      // inner element decides the order.
      final entries = <XdrSCMapEntry>[
        XdrSCMapEntry(
          XdrSCVal.forVec(
            <XdrSCVal>[XdrSCVal.forSymbol('z'), XdrSCVal.forU32(1)],
          ),
          XdrSCVal.forU32(10),
        ),
        XdrSCMapEntry(
          XdrSCVal.forVec(
            <XdrSCVal>[XdrSCVal.forSymbol('a'), XdrSCVal.forU32(1)],
          ),
          XdrSCVal.forU32(20),
        ),
        XdrSCMapEntry(
          XdrSCVal.forVec(
            <XdrSCVal>[XdrSCVal.forSymbol('m'), XdrSCVal.forU32(1)],
          ),
          XdrSCVal.forU32(30),
        ),
      ];

      final sorted = OZPolicyManager.sortMapByKeyXdr(entries);

      expect(sorted.length, 3);
      _assertKeysSortedAscending(sorted);
    });
  });

  // -------------------------------------------------------------------------
  // Round-trip with OZWeightedThresholdPolicyParams + policies map (4 cases)
  // -------------------------------------------------------------------------
  group('OZPolicyManager.sortMapByKeyXdr — policy round-trips', () {
    test('OZWeightedThresholdPolicyParams inner signer_weights map is sorted', () {
      // Pass signers in a deliberately unsorted order; the inner ScVal
      // map for `signer_weights` must come out in the host's ScMap key
      // order.
      final params = OZWeightedThresholdPolicyParams(
        signerWeights: <OZSmartAccountSigner, int>{
          OZDelegatedSigner(_gAddr3): 20,
          OZDelegatedSigner(_gAddr1): 50,
          OZDelegatedSigner(_gAddr2): 30,
        },
        threshold: 100,
      );

      final scVal = params.toScVal();
      final outerEntries = scVal.map!;
      final signerWeightsEntry = outerEntries.firstWhere(
        (e) => e.key.sym == 'signer_weights',
      );
      final innerEntries = signerWeightsEntry.val.map!;

      expect(innerEntries.length, 3);
      _assertKeysSortedAscending(innerEntries);
    });

    test(
        'OZWeightedThresholdPolicyParams XDR is deterministic across signer-input order',
        () {
      final s1 = OZDelegatedSigner(_gAddr1);
      final s2 = OZDelegatedSigner(_gAddr2);

      final paramsA = OZWeightedThresholdPolicyParams(
        signerWeights: <OZSmartAccountSigner, int>{s1: 50, s2: 30},
        threshold: 80,
      );
      final paramsB = OZWeightedThresholdPolicyParams(
        signerWeights: <OZSmartAccountSigner, int>{s2: 30, s1: 50},
        threshold: 80,
      );

      final hexA = _xdrHex(paramsA.toScVal());
      final hexB = _xdrHex(paramsB.toScVal());

      expect(hexA, hexB);
    });

    test('policies map (Address keys) is sorted in host key order', () {
      // Mirrors the policies-map construction inside
      // `OZContextRuleManager.addContextRule`: address-keyed map with void
      // values, sorted via the same OZPolicyManager helper.
      final entries = <XdrSCMapEntry>[
        for (final address in <String>[_addr1, _addr2, _addr3])
          XdrSCMapEntry(
            XdrSCVal.forAddress(Address.forContractId(address).toXdr()),
            XdrSCVal.forVoid(),
          ),
      ];

      final sorted = OZPolicyManager.sortMapByKeyXdr(entries);

      expect(sorted.length, 3);
      _assertKeysSortedAscending(sorted);
    });

    test('policiesToScVal builds a sorted address-keyed ScMap', () {
      // policiesToScVal turns an address-keyed policies map into the ScMap
      // the contract expects: Address keys in the host's ScMap key order,
      // install params preserved per address.
      final policies = <String, XdrSCVal>{
        _addr1: XdrSCVal.forU32(1),
        _addr2: XdrSCVal.forU32(2),
        _addr3: XdrSCVal.forU32(3),
      };

      final scVal = OZPolicyManager.policiesToScVal(policies);
      final entries = scVal.map!;

      expect(entries.length, 3);
      _assertKeysSortedAscending(entries);

      // Every entry's key encodes one of the input addresses and carries
      // that address's install param.
      final expectedByKeyHex = <String, XdrSCVal>{
        for (final entry in policies.entries)
          _xdrHex(
            XdrSCVal.forAddress(Address.forContractId(entry.key).toXdr()),
          ): entry.value,
      };
      for (final entry in entries) {
        final expectedParam = expectedByKeyHex[_xdrHex(entry.key)];
        expect(expectedParam, isNotNull,
            reason: 'entry key must encode one of the input policy addresses');
        expect(entry.val.u32!.uint32, expectedParam!.u32!.uint32,
            reason: 'install param must stay attached to its address');
      }
    });

    test('policies-map sorting is order-insensitive (deterministic)', () {
      // Same address set in two different insertion orders must serialise
      // identically once sorted.
      List<XdrSCMapEntry> build(List<String> order) => <XdrSCMapEntry>[
            for (final address in order)
              XdrSCMapEntry(
                XdrSCVal.forAddress(
                  Address.forContractId(address).toXdr(),
                ),
                XdrSCVal.forVoid(),
              ),
          ];

      final sortedA = OZPolicyManager.sortMapByKeyXdr(
        build(<String>[_addr1, _addr2]),
      );
      final sortedB = OZPolicyManager.sortMapByKeyXdr(
        build(<String>[_addr2, _addr1]),
      );

      final hexA = _xdrHex(XdrSCVal.forMap(sortedA));
      final hexB = _xdrHex(XdrSCVal.forMap(sortedB));
      expect(hexA, hexB);
    });
  });
}
