// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final _max64 = BigInt.parse('18446744073709551615');

/// The shared host-order vector, ascending: rs-soroban-env
/// `soroban-env-host/src/host/comparison.rs`, `Compare<ScVal>`.
List<XdrSCVal> _hostOrderVector() {
  XdrSCVal error(
    XdrSCErrorType type, {
    int? contractCode,
    XdrSCErrorCode? code,
  }) {
    final e = XdrSCError(type)..code = code;
    if (contractCode != null) e.contractCode = XdrUint32(contractCode);
    return XdrSCVal.forError(e);
  }

  Uint8List filled(int byte) => Uint8List(32)..fillRange(0, 32, byte);
  XdrSCVal muxed(int id, int byte) => XdrSCVal.forAddress(
    XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_MUXED_ACCOUNT)
      ..muxedAccount = XdrMuxedAccountMed25519(
        XdrUint64(BigInt.from(id)),
        XdrUint256(filled(byte)),
      ),
  );
  XdrSCVal bytes(List<int> v) => XdrSCVal.forBytes(Uint8List.fromList(v));
  XdrSCVal map(int k, int v) =>
      XdrSCVal.forMap([XdrSCMapEntry(XdrSCVal.forU32(k), XdrSCVal.forU32(v))]);
  final big = BigInt.from;

  return [
    XdrSCVal.forBool(false),
    XdrSCVal.forBool(true),
    XdrSCVal.forVoid(),
    error(XdrSCErrorType.SCE_CONTRACT, contractCode: 1),
    error(XdrSCErrorType.SCE_CONTRACT, contractCode: 2),
    error(XdrSCErrorType.SCE_WASM_VM, code: XdrSCErrorCode.SCEC_INVALID_INPUT),
    XdrSCVal.forU32(0),
    XdrSCVal.forU32(4294967295),
    XdrSCVal.forI32(-2147483648),
    XdrSCVal.forI32(-1),
    XdrSCVal.forI32(0),
    XdrSCVal.forI32(1),
    XdrSCVal.forU64(BigInt.zero),
    XdrSCVal.forU64(_max64),
    XdrSCVal.forI64(BigInt.parse('-9223372036854775808')),
    XdrSCVal.forI64(big(-1)),
    XdrSCVal.forI64(BigInt.zero),
    XdrSCVal.forTimepoint(BigInt.zero),
    XdrSCVal.forTimepoint(BigInt.one),
    XdrSCVal.forDuration(BigInt.zero),
    XdrSCVal.forU128Parts(BigInt.zero, BigInt.one),
    XdrSCVal.forU128Parts(BigInt.zero, _max64),
    XdrSCVal.forU128Parts(BigInt.one, BigInt.zero),
    XdrSCVal.forI128Parts(big(-1), _max64),
    XdrSCVal.forI128Parts(BigInt.zero, BigInt.zero),
    XdrSCVal.forI128Parts(BigInt.zero, _max64),
    XdrSCVal.forI128Parts(BigInt.one, BigInt.zero),
    XdrSCVal.forU256Parts(BigInt.zero, BigInt.zero, BigInt.zero, BigInt.one),
    XdrSCVal.forU256Parts(BigInt.one, BigInt.zero, BigInt.zero, BigInt.zero),
    XdrSCVal.forI256Parts(big(-1), _max64, _max64, _max64),
    XdrSCVal.forI256Parts(BigInt.zero, BigInt.zero, BigInt.zero, BigInt.zero),
    bytes([]),
    bytes([0x01]),
    bytes([0x01, 0x00]),
    bytes([0x02]),
    bytes([0xff]),
    XdrSCVal.forString(''),
    XdrSCVal.forString('a'),
    XdrSCVal.forString('ab'),
    XdrSCVal.forString('b'),
    XdrSCVal.forSymbol('A'),
    XdrSCVal.forSymbol('AB'),
    XdrSCVal.forSymbol('B'),
    XdrSCVal.forSymbol('_'),
    XdrSCVal.forSymbol('a'),
    XdrSCVal.forVec([]),
    XdrSCVal.forVec([XdrSCVal.forU32(1)]),
    XdrSCVal.forVec([XdrSCVal.forU32(1), XdrSCVal.forU32(0)]),
    XdrSCVal.forVec([XdrSCVal.forU32(2)]),
    XdrSCVal.forVec([XdrSCVal.forI32(-1)]),
    XdrSCVal.forMap([]),
    map(1, 1),
    map(1, 2),
    map(2, 0),
    XdrSCVal.forAccountAddress(StrKey.encodeStellarAccountId(filled(0x00))),
    XdrSCVal.forAccountAddress(StrKey.encodeStellarAccountId(filled(0xff))),
    XdrSCVal.forContractAddress(StrKey.encodeContractId(filled(0x00))),
    XdrSCVal.forContractAddress(StrKey.encodeContractId(filled(0xff))),
    muxed(0, 0xff),
    muxed(1, 0x00),
    XdrSCVal.forLedgerKeyContractInstance(),
    XdrSCVal.forLedgerKeyNonce(-1),
    XdrSCVal.forLedgerKeyNonce(0),
  ];
}

/// The fixed shuffle: reverse, then swap each pair of neighbours.
List<T> _shuffled<T>(List<T> items) {
  final out = items.reversed.toList();
  for (var i = 0; i + 1 < out.length; i += 2) {
    final first = out[i];
    out[i] = out[i + 1];
    out[i + 1] = first;
  }
  return out;
}

List<String> _keysXdr(XdrSCVal map) =>
    map.map!.map((e) => e.key.toBase64EncodedXdrString()).toList();

List<String> _xdrList(Iterable<XdrSCVal> values) =>
    values.map((v) => v.toBase64EncodedXdrString()).toList();

/// Host-order ScMap key comparator (`compareScValHostOrder`), the sorted map
/// builder (`sortedScMap`), and their effect on the ContractSpec conversions
/// and the smart-account signer maps. The Soroban host orders keys by content
/// (Rust slice `Ord`), with length only a tiebreaker on a common prefix, and
/// rejects an out-of-order map with `InvalidInput`.
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

  group('host order vector', () {
    void expectAscending(List<XdrSCVal> keys) {
      for (var i = 0; i < keys.length; i++) {
        expect(compareScValHostOrder(keys[i], keys[i]), 0, reason: '#${i + 1}');
        for (var j = i + 1; j < keys.length; j++) {
          expect(
            compareScValHostOrder(keys[i], keys[j]) < 0,
            isTrue,
            reason: '#${i + 1} < #${j + 1}',
          );
          expect(
            compareScValHostOrder(keys[j], keys[i]) > 0,
            isTrue,
            reason: '#${j + 1} > #${i + 1}',
          );
        }
      }
    }

    test('every pair of the vector compares in vector order', () {
      final keys = _hostOrderVector();
      expect(keys.length, 63);
      expectAscending(keys);
    });

    test('ContractInstance compares by executable, then storage', () {
      XdrSCVal instance(
        XdrContractExecutable executable, [
        Map<int, int>? storage,
      ]) => XdrSCVal.forContractInstance(
        XdrSCContractInstance(
          executable,
          storage?.entries
              .map(
                (e) => XdrSCMapEntry(
                  XdrSCVal.forU32(e.key),
                  XdrSCVal.forI32(e.value),
                ),
              )
              .toList(),
        ),
      );
      final wasm = XdrContractExecutable.forWasm(Uint8List(32));
      final owner = XdrSCAddress.forContractId(
        StrKey.encodeContractId(Uint8List(32)),
      );
      expectAscending([
        instance(wasm),
        instance(wasm, {1: -1}),
        instance(wasm, {1: 0}),
        instance(wasm, {1: 0, 2: 0}),
        instance(wasm, {2: 0}),
        instance(XdrContractExecutable.forWasm(Uint8List(32)..[0] = 1)),
        instance(XdrContractExecutable.forAsset()),
        instance(XdrContractExecutable.forExternalRef(owner, 'ab')),
        instance(XdrContractExecutable.forExternalRef(owner, 'b')),
      ]);
    });

    test('sortedScMap restores the vector order from the fixed shuffle', () {
      final keys = _hostOrderVector();
      final entries = [
        for (var i = 0; i < keys.length; i++)
          XdrSCMapEntry(keys[i], XdrSCVal.forU32(i)),
      ];
      final shuffled = _shuffled(entries);
      final map = sortedScMap(shuffled);
      expect(_keysXdr(map), _xdrList(keys));
      expect(
        map.map!.map((e) => e.val.u32!.uint32),
        orderedEquals(List.generate(keys.length, (i) => i)),
      );
      expect(
        _xdrList(shuffled.map((e) => e.key)),
        _xdrList(_shuffled(keys)),
        reason: 'the input list is left unchanged',
      );
    });

    test('sortedScMap rejects a duplicate key built separately', () {
      final entries = [
        XdrSCMapEntry(XdrSCVal.forSymbol('owner'), XdrSCVal.forU32(1)),
        XdrSCMapEntry(XdrSCVal.forU32(7), XdrSCVal.forU32(2)),
        XdrSCMapEntry(XdrSCVal.forSymbol('owner'), XdrSCVal.forU32(3)),
      ];
      expect(
        () => sortedScMap(entries),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.toString(),
            'message',
            contains('owner'),
          ),
        ),
      );
    });
  });

  group('ContractSpec map conversions', () {
    final spec = ContractSpec([]);

    test('spec-driven map emits keys in host order', () {
      final keys = _hostOrderVector();
      final mapType = XdrSCSpecTypeDef.forMap(
        XdrSCSpecTypeMap(XdrSCSpecTypeDef.forVal(), XdrSCSpecTypeDef.forU32()),
      );
      final result = spec.nativeToXdrSCVal({
        for (final key in _shuffled(keys)) key: 1,
      }, mapType);
      expect(_keysXdr(result), _xdrList(keys));
    });

    test('inferred map emits keys in host order', () {
      // Vector entries a Dart value infers to, by 1-based vector position.
      final native = <int, Object>{
        1: false,
        2: true,
        7: 0,
        8: 4294967295,
        9: -2147483648,
        10: -1,
        15: -9223372036854775808,
        24: BigInt.from(-1),
        25: BigInt.zero,
        26: _max64,
        27: _max64 + BigInt.one,
        32: Uint8List(0),
        33: Uint8List.fromList([0x01]),
        34: Uint8List.fromList([0x01, 0x00]),
        35: Uint8List.fromList([0x02]),
        36: Uint8List.fromList([0xff]),
        37: '',
        38: 'a',
        39: 'ab',
        40: 'b',
        46: <int>[],
        47: [1],
        48: [1, 0],
        49: [2],
        50: [-1],
        51: <int, int>{},
        52: {1: 1},
        53: {1: 2},
        54: {2: 0},
      };
      final vector = _hostOrderVector();
      final result = spec.nativeToXdrSCVal({
        for (final position in _shuffled(native.keys.toList()))
          native[position]: position,
      }, XdrSCSpecTypeDef.forVal());
      expect(
        _keysXdr(result),
        _xdrList(native.keys.map((position) => vector[position - 1])),
      );
    });

    test('map-encoded struct emits field keys in host order', () {
      final structEntry =
          XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_STRUCT_V0)
            ..udtStructV0 = XdrSCSpecUDTStructV0('', '', 'Pair', [
              XdrSCSpecUDTStructFieldV0('', 'zeta', XdrSCSpecTypeDef.forU32()),
              XdrSCSpecUDTStructFieldV0('', 'alpha', XdrSCSpecTypeDef.forU32()),
            ]);
      final result = ContractSpec([structEntry]).nativeToXdrSCVal({
        'zeta': 1,
        'alpha': 2,
      }, XdrSCSpecTypeDef.forUdt(XdrSCSpecTypeUDT('Pair')));
      expect(
        result.map!.map((e) => e.key.sym),
        orderedEquals(['alpha', 'zeta']),
      );
    });

    test('a map with two keys equal in host order throws', () {
      final mapType = XdrSCSpecTypeDef.forMap(
        XdrSCSpecTypeMap(
          XdrSCSpecTypeDef.forBytes(),
          XdrSCSpecTypeDef.forU32(),
        ),
      );
      expect(
        () => spec.nativeToXdrSCVal({
          Uint8List.fromList([0x01]): 1,
          Uint8List.fromList([0x01]): 2,
        }, mapType),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('a decoded map keeps its key order when encoded again', () {
      final unordered = XdrSCVal.forMap([
        XdrSCMapEntry(XdrSCVal.forI32(1), XdrSCVal.forU32(0)),
        XdrSCMapEntry(XdrSCVal.forI32(-1), XdrSCVal.forU32(1)),
      ]).toBase64EncodedXdrString();
      final decoded = XdrSCVal.fromBase64EncodedXdrString(unordered);
      expect(decoded.toBase64EncodedXdrString(), unordered);
      final mapType = XdrSCSpecTypeDef.forMap(
        XdrSCSpecTypeMap(XdrSCSpecTypeDef.forI32(), XdrSCSpecTypeDef.forU32()),
      );
      expect(
        spec.nativeToXdrSCVal(decoded, mapType).toBase64EncodedXdrString(),
        unordered,
      );
    });
  });
}
