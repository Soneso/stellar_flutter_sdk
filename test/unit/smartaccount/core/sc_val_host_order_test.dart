// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/src/smartaccount/core/sc_val_host_order.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

/// Host-order ScMap key comparator (`compareScValHostOrder`) and its effect
/// on the smart-account signer maps. The Soroban host orders keys by content
/// (Rust slice `Ord`), with length only a tiebreaker on a common prefix.
/// Sorting by the length-major XDR-byte encoding instead diverges for
/// variable-length keys whose lengths differ, producing a map the host
/// rejects with `InvalidInput`; this suite pins the correct order.
void main() {
  const verifier = 'CB26VN37RCVNTHJZDEPK6IRO2MMTS3Z2IEO5JD5BINY2OOJ5KKJG7NKY';
  const verifierOther =
      'CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC';

  XdrSCVal bytes(List<int> v) => XdrSCVal.forBytes(Uint8List.fromList(v));

  /// Builds an external signer: keyData = pub(65, first byte varied) +
  /// credId(len, zeros).
  OZExternalSigner externalSigner(
    int pubFirstByte,
    int credIdLen, {
    String verifierAddress = verifier,
  }) {
    final keyData = Uint8List(65 + credIdLen);
    keyData[0] = pubFirstByte;
    for (var i = 1; i < 65; i++) {
      keyData[i] = 0x01;
    }
    return OZExternalSigner(verifierAddress, keyData);
  }

  /// Builds an external signer's ScVal key.
  XdrSCVal signer(
    int pubFirstByte,
    int credIdLen, {
    String verifierAddress = verifier,
  }) => externalSigner(
    pubFirstByte,
    credIdLen,
    verifierAddress: verifierAddress,
  ).toScVal();

  /// Length-major comparison of raw XDR encodings, used to pin where the two
  /// orders diverge.
  int compareRawBytes(List<int> a, List<int> b) {
    final shared = a.length < b.length ? a.length : b.length;
    for (var i = 0; i < shared; i++) {
      final cmp = (a[i] & 0xFF).compareTo(b[i] & 0xFF);
      if (cmp != 0) return cmp;
    }
    return a.length.compareTo(b.length);
  }

  List<int> xdrBytes(XdrSCVal value) => OZPolicyManager.scValToXdrBytes(value);

  group('compareScValHostOrder', () {
    test('testBytes_contentBeforeLength', () {
      // Bytes compare by content, not length: [0x01,0x02] < [0xFF].
      final a = bytes(const <int>[0xFF]);
      final b = bytes(const <int>[0x01, 0x02]);
      expect(
        compareScValHostOrder(b, a) < 0,
        isTrue,
        reason: 'b (0x01..) must sort before a (0xFF)',
      );
      expect(compareScValHostOrder(a, b) > 0, isTrue);
    });

    test('testBytes_prefixShorterFirst', () {
      // Prefix tiebreaker: the shorter value sorts first.
      final a = bytes(const <int>[0x01]);
      final b = bytes(const <int>[0x01, 0x00]);
      expect(compareScValHostOrder(a, b) < 0, isTrue);
      expect(compareScValHostOrder(b, a) > 0, isTrue);
    });

    test('testSameVerifierSigners_hostOrderDivergesFromLengthMajor', () {
      // Two same-verifier signers with different-length keyData: host order
      // is by content and is the opposite of the length-major XDR-byte order.
      final signerA = signer(0x02, 16); // keyData 81 bytes, pub greater
      final signerB = signer(0x01, 20); // keyData 85 bytes, pub smaller

      // Host order: B before A (pubB 0x01 < pubA 0x02 in the first byte;
      // length irrelevant).
      expect(compareScValHostOrder(signerB, signerA) < 0, isTrue);
      expect(compareScValHostOrder(signerA, signerB) > 0, isTrue);

      // Length-major XDR-byte order puts the shorter signerA first — the
      // opposite of the host. Asserting the disagreement pins the divergence
      // at exactly the inputs where the two orders differ.
      final xdrA = xdrBytes(signerA);
      final xdrB = xdrBytes(signerB);
      expect(xdrA.length < xdrB.length, isTrue);
      expect(
        compareRawBytes(xdrA, xdrB) < 0,
        isTrue,
        reason: 'length-major XDR-byte order puts signerA first',
      );
      expect(
        compareScValHostOrder(signerA, signerB) > 0,
        isTrue,
        reason: 'host order puts signerA last',
      );
    });

    test('testSignerWeightsMap_hostOrder', () {
      // The weighted-threshold signer_weights map sorts the two signers in
      // host order [B, A].
      final signerA = signer(0x02, 16);
      final signerB = signer(0x01, 20);
      final entries = <XdrSCMapEntry>[
        XdrSCMapEntry(signerA, XdrSCVal.forU32(1)),
        XdrSCMapEntry(signerB, XdrSCVal.forU32(1)),
      ];
      final sorted = OZPolicyManager.sortMapByKeyXdr(entries);
      expect(sorted.length, 2);
      expect(xdrBytes(sorted[0].key), xdrBytes(signerB));
      expect(xdrBytes(sorted[1].key), xdrBytes(signerA));
    });

    test('testSameLengthSigners_contentOrder', () {
      // Same-length, different content: ordered by content, not spuriously
      // reordered.
      final low = signer(0x01, 16);
      final high = signer(0x02, 16);
      final entries = <XdrSCMapEntry>[
        XdrSCMapEntry(high, XdrSCVal.forU32(1)),
        XdrSCMapEntry(low, XdrSCVal.forU32(1)),
      ];
      final sorted = OZPolicyManager.sortMapByKeyXdr(entries);
      expect(xdrBytes(sorted[0].key), xdrBytes(low));
      expect(xdrBytes(sorted[1].key), xdrBytes(high));
    });

    test('testManySigners_strictTotalOrder', () {
      // 3+ signers with mixed lengths: the full sort is a strict total order
      // in host order.
      final s1 = signer(0x01, 16);
      final s2 = signer(0x02, 40);
      final s3 = signer(0x03, 8);
      final s4 = signer(0x02, 12);
      final entries = <XdrSCMapEntry>[
        XdrSCMapEntry(s3, XdrSCVal.forU32(1)),
        XdrSCMapEntry(s1, XdrSCVal.forU32(1)),
        XdrSCMapEntry(s4, XdrSCVal.forU32(1)),
        XdrSCMapEntry(s2, XdrSCVal.forU32(1)),
      ];
      final sorted = OZPolicyManager.sortMapByKeyXdr(entries);
      expect(sorted.length, 4);
      // First pub byte 0x01 is smallest; 0x03 is largest.
      expect(xdrBytes(sorted[0].key), xdrBytes(s1));
      expect(xdrBytes(sorted[3].key), xdrBytes(s3));
      for (var i = 0; i < sorted.length - 1; i++) {
        expect(
          compareScValHostOrder(sorted[i].key, sorted[i + 1].key) < 0,
          isTrue,
          reason: 'adjacent keys must be strictly increasing in host order',
        );
      }
    });

    test('testDifferentVerifiers_addressDecides', () {
      // Two signers on different verifiers with identical keyData: order is
      // decided by the Address element of the Vec key, not the trailing
      // Bytes.
      final signerX = signer(0x01, 16, verifierAddress: verifier);
      final signerY = signer(0x01, 16, verifierAddress: verifierOther);
      final addrCmp = compareScValHostOrder(
        XdrSCVal.forAddress(Address.forContractId(verifier).toXdr()),
        XdrSCVal.forAddress(Address.forContractId(verifierOther).toXdr()),
      );
      final signerCmp = compareScValHostOrder(signerX, signerY);
      expect(
        addrCmp != 0,
        isTrue,
        reason: 'the two verifier addresses must differ',
      );
      expect(
        (signerCmp < 0) == (addrCmp < 0),
        isTrue,
        reason:
            'signer order must follow the verifier Address element, '
            'not the identical keyData',
      );
    });

    test('testStringComparands_contentOrder', () {
      // String comparands compare by content, byte for byte, with the
      // shorter value first on a prefix tie.
      final a = XdrSCVal.forString('apple');
      final b = XdrSCVal.forString('banana');
      expect(compareScValHostOrder(a, b) < 0, isTrue);
      expect(compareScValHostOrder(b, a) > 0, isTrue);

      final prefix = XdrSCVal.forString('app');
      expect(
        compareScValHostOrder(prefix, a) < 0,
        isTrue,
        reason: 'a prefix sorts before its extension',
      );
      expect(compareScValHostOrder(a, XdrSCVal.forString('apple')), 0);
    });

    test('testExecutableTagComparands_contentOrder', () {
      // ExecutableTag comparands carry an SCString and compare by content,
      // byte for byte, with the shorter value first on a prefix tie.
      final a = XdrSCVal.forExecutableTag('apple');
      final b = XdrSCVal.forExecutableTag('banana');
      expect(compareScValHostOrder(a, b) < 0, isTrue);
      expect(compareScValHostOrder(b, a) > 0, isTrue);

      final prefix = XdrSCVal.forExecutableTag('app');
      expect(
        compareScValHostOrder(prefix, a) < 0,
        isTrue,
        reason: 'a prefix sorts before its extension',
      );
      expect(compareScValHostOrder(a, XdrSCVal.forExecutableTag('apple')), 0);
    });

    test('testExecutableTagComparands_binaryBytesOrder', () {
      // Tags that spell no text compare by their raw bytes. Read through a
      // replacement-based text decoding, both of these collapse to the same
      // replacement character and would compare equal.
      final c0 = XdrSCVal.forExecutableTagBytes(Uint8List.fromList([0xC0]));
      final ff = XdrSCVal.forExecutableTagBytes(Uint8List.fromList([0xFF]));
      expect(compareScValHostOrder(c0, ff) < 0, isTrue);
      expect(compareScValHostOrder(ff, c0) > 0, isTrue);
      expect(
        compareScValHostOrder(
          c0,
          XdrSCVal.forExecutableTagBytes(Uint8List.fromList([0xC0])),
        ),
        0,
      );
    });

    test('testVecComparands_prefixShorterFirst', () {
      // Vec comparands: on a shared prefix, the shorter vec sorts first.
      final shortVec = XdrSCVal.forVec(<XdrSCVal>[XdrSCVal.forSymbol('a')]);
      final longVec = XdrSCVal.forVec(<XdrSCVal>[
        XdrSCVal.forSymbol('a'),
        XdrSCVal.forSymbol('b'),
      ]);
      expect(compareScValHostOrder(shortVec, longVec) < 0, isTrue);
      expect(compareScValHostOrder(longVec, shortVec) > 0, isTrue);
    });

    test('testMapComparands_valueDecidesOnEqualKeys', () {
      // Map comparands with identical keys: the first differing value
      // decides.
      final lower = XdrSCVal.forMap(<XdrSCMapEntry>[
        XdrSCMapEntry(XdrSCVal.forSymbol('k'), XdrSCVal.forU32(1)),
      ]);
      final higher = XdrSCVal.forMap(<XdrSCMapEntry>[
        XdrSCMapEntry(XdrSCVal.forSymbol('k'), XdrSCVal.forU32(2)),
      ]);
      expect(compareScValHostOrder(lower, higher) < 0, isTrue);
      expect(compareScValHostOrder(higher, lower) > 0, isTrue);
    });

    test('testMapComparands_entryCountTiebreakerOnSharedPrefix', () {
      // Map comparands on a shared entry prefix: the map with fewer entries
      // sorts first.
      final oneEntry = XdrSCVal.forMap(<XdrSCMapEntry>[
        XdrSCMapEntry(XdrSCVal.forSymbol('a'), XdrSCVal.forU32(1)),
      ]);
      final twoEntries = XdrSCVal.forMap(<XdrSCMapEntry>[
        XdrSCMapEntry(XdrSCVal.forSymbol('a'), XdrSCVal.forU32(1)),
        XdrSCMapEntry(XdrSCVal.forSymbol('b'), XdrSCVal.forU32(2)),
      ]);
      expect(compareScValHostOrder(oneEntry, twoEntries) < 0, isTrue);
      expect(compareScValHostOrder(twoEntries, oneEntry) > 0, isTrue);
    });

    test('testMapComparands_entryWiseNotEntryCount', () {
      // Map comparands compare entry-wise (first differing key/value
      // decides), not by entry count.
      final oneEntry = XdrSCVal.forMap(<XdrSCMapEntry>[
        XdrSCMapEntry(XdrSCVal.forSymbol('b'), XdrSCVal.forU32(1)),
      ]);
      final twoEntries = XdrSCVal.forMap(<XdrSCMapEntry>[
        XdrSCMapEntry(XdrSCVal.forSymbol('a'), XdrSCVal.forU32(1)),
        XdrSCMapEntry(XdrSCVal.forSymbol('c'), XdrSCVal.forU32(2)),
      ]);
      // Entry-wise: the two-entry map's first key "a" sorts before "b", so
      // it comes first despite having more entries (entry count is only the
      // tiebreaker on a shared prefix).
      expect(compareScValHostOrder(twoEntries, oneEntry) < 0, isTrue);
      expect(compareScValHostOrder(oneEntry, twoEntries) > 0, isTrue);
    });

    test('testAuthPayloadWrite_signersMapInHostOrder', () {
      // The auth-payload write path emits the signers map in host order for
      // two same-verifier signers with different-length key data.
      final signerA = externalSigner(0x02, 16); // shorter keyData, greater pub
      final signerB = externalSigner(0x01, 20); // longer keyData, smaller pub
      final payload = OZSmartAccountAuthPayload(
        signers: <OZSmartAccountSigner, Uint8List>{
          signerA: Uint8List.fromList(List<int>.filled(64, 0x07)),
          signerB: Uint8List.fromList(List<int>.filled(64, 0x08)),
        },
        contextRuleIds: const <int>[0],
      );

      final written = OZSmartAccountAuthPayloadCodec.write(payload);
      final outerEntries = written.map!;
      final signersEntry = outerEntries.firstWhere(
        (e) => e.key.sym == 'signers',
      );
      final signerKeys = signersEntry.val.map!
          .map((e) => e.key)
          .toList(growable: false);

      expect(signerKeys.length, 2);
      // Signer ScVal instances carry byte payloads without value equality,
      // so compare the XDR encodings instead of the instances.
      expect(
        xdrBytes(signerKeys[0]),
        xdrBytes(signerB.toScVal()),
        reason: 'smaller pubkey content must sort first despite longer keyData',
      );
      expect(xdrBytes(signerKeys[1]), xdrBytes(signerA.toScVal()));
    });
  });
}
