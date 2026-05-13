// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
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

/// Asserts that [entries] are strictly sorted by their XDR-byte key
/// representation (i.e. each key's hex compares strictly less than the
/// next key's hex).
void _assertKeysSortedAscending(List<XdrSCMapEntry> entries) {
  for (var i = 0; i < entries.length - 1; i++) {
    final currentHex = _xdrHex(entries[i].key);
    final nextHex = _xdrHex(entries[i + 1].key);
    expect(
      currentHex.compareTo(nextHex) < 0,
      isTrue,
      reason: 'Key at index $i (hex=$currentHex) must be < key at '
          'index ${i + 1} (hex=$nextHex)',
    );
  }
}

void main() {
  // -------------------------------------------------------------------------
  // Single-key-type entries (4 cases): Symbol, Address, U32, Bytes
  // -------------------------------------------------------------------------
  group('OZPolicyManager.sortMapByKeyXdr — single key types', () {
    test('symbol keys sort by XDR-byte length-prefix then bytes', () {
      // XDR symbol encoding: [4-byte type][4-byte length][string][padding].
      // Length prefix dominates, so 5-char symbols precede 6-char symbols.
      // "alpha" (5) < "zebra" (5) < "middle" (6)
      final unsorted = <XdrSCMapEntry>[
        XdrSCMapEntry(XdrSCVal.forSymbol('zebra'), XdrSCVal.forU32(1)),
        XdrSCMapEntry(XdrSCVal.forSymbol('alpha'), XdrSCVal.forU32(2)),
        XdrSCMapEntry(XdrSCVal.forSymbol('middle'), XdrSCVal.forU32(3)),
      ];

      final sorted = OZPolicyManager.sortMapByKeyXdr(unsorted);

      expect(sorted.length, 3);
      expect(sorted[0].key.sym, 'alpha');
      expect(sorted[1].key.sym, 'zebra');
      expect(sorted[2].key.sym, 'middle');
    });

    test('address keys sort by their XDR byte representation', () {
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

    test('U32 keys sort by their big-endian XDR encoding', () {
      final unsorted = <XdrSCMapEntry>[
        XdrSCMapEntry(XdrSCVal.forU32(65536), XdrSCVal.forU32(1)),
        XdrSCMapEntry(XdrSCVal.forU32(1), XdrSCVal.forU32(2)),
        XdrSCMapEntry(XdrSCVal.forU32(256), XdrSCVal.forU32(3)),
      ];

      final sorted = OZPolicyManager.sortMapByKeyXdr(unsorted);

      expect(sorted.length, 3);
      // Big-endian U32: 1 < 256 < 65536.
      expect(sorted[0].key.u32!.uint32, 1);
      expect(sorted[1].key.u32!.uint32, 256);
      expect(sorted[2].key.u32!.uint32, 65536);
      _assertKeysSortedAscending(sorted);
    });

    test('Bytes keys sort by their XDR length-prefix then byte content',
        () {
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
      _assertKeysSortedAscending(sorted);
    });
  });

  // -------------------------------------------------------------------------
  // Mixed-key-type entries (6 cases): XDR discriminant byte ordering
  // -------------------------------------------------------------------------
  group('OZPolicyManager.sortMapByKeyXdr — mixed key types', () {
    test('mixed Symbol, U32, and Bytes keys sort by XDR bytes', () {
      // SCValType discriminants encode as 4-byte big-endian ints. Different
      // key types thus naturally separate by their discriminant value first.
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

    test('deep-nested map keys are sorted by XDR bytes of nested ScVal', () {
      // Use Vec keys that themselves embed sortable ScVal payloads. The
      // outer sort sees the full XDR byte stream of each Vec, including the
      // inner-element discriminants and payloads.
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
  // Round-trip with WeightedThresholdParams + policies map (4 cases)
  // -------------------------------------------------------------------------
  group('OZPolicyManager.sortMapByKeyXdr — policy round-trips', () {
    test('WeightedThresholdParams inner signer_weights map is sorted', () {
      // Pass signers in a deliberately unsorted order; the inner ScVal
      // map for `signer_weights` must come out sorted by XDR bytes.
      final params = WeightedThresholdParams(
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
        'WeightedThresholdParams XDR is deterministic across signer-input order',
        () {
      final s1 = OZDelegatedSigner(_gAddr1);
      final s2 = OZDelegatedSigner(_gAddr2);

      final paramsA = WeightedThresholdParams(
        signerWeights: <OZSmartAccountSigner, int>{s1: 50, s2: 30},
        threshold: 80,
      );
      final paramsB = WeightedThresholdParams(
        signerWeights: <OZSmartAccountSigner, int>{s2: 30, s1: 50},
        threshold: 80,
      );

      final hexA = _xdrHex(paramsA.toScVal());
      final hexB = _xdrHex(paramsB.toScVal());

      expect(hexA, hexB);
    });

    test('policies map (Address keys) is sorted by XDR bytes', () {
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
