// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

// The higher-level paths over XDR strings whose bytes are not UTF-8 or start
// with a byte order mark: transaction import, memos, TxRep, Horizon records,
// SEP-7, SEP-10, SEP-45, Soroban authorization payloads, events, host order
// and native conversion.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

Uint8List _hex(String hex) => Util.hexToBytes(hex);

final Uint8List _ffFe = _hex('fffe20616263');

const String _contract =
    'CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE';
const String _server =
    'GB6XJIMOUTHNC6KYHWTOECKQJY2UHCFRODONBGMNKG5KVBB5PZHTB5XB';

String _envelope(String name) =>
    _v1Cases.firstWhere(((String, String, String) c) => c.$1 == name).$2;

XdrSCMapEntry _entry(XdrSCVal key) => XdrSCMapEntry(key, XdrSCVal.forU32(1));

/// Expects the XDR layer to re-encode [envelope] byte for byte.
void _expectXdrRoundTrip(String envelope) {
  expect(
    XdrTransactionEnvelope.fromEnvelopeXdrString(
      envelope,
    ).toEnvelopeXdrBase64(),
    envelope,
  );
}

/// Signs [tx] with a fresh key and expects the signature to verify against
/// [hash].
void _expectSignatureOver(AbstractTransaction tx, String hash) {
  final KeyPair signer = KeyPair.random();
  tx.sign(signer, Network.TESTNET);
  expect(
    signer.verify(
      Util.hexToBytes(hash),
      tx.signatures.last.signature.signature,
    ),
    true,
  );
}

// (name, envelope, hash) of V1 envelopes whose string positions hold
// bytes that are not UTF-8, a leading byte order mark, or a memo cut
// inside a UTF-8 sequence. Hashes are on the test network.
final List<(String, String, String)> _v1Cases = <(String, String, String)>[
  (
    'memo-ffFe',
    'AAAAAgAAAAABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4fIAAAAGQAAAABAAAAAQAA'
        'AAAAAAABAAAABv/+IGFiYwAAAAAAAQAAAAAAAAABAAAAACEiIyQlJicoKSorLC0uLzAxMjM0'
        'NTY3ODk6Ozw9Pj9AAAAAAAAAAAAAmJaAAAAAAAAAAAEAAAAAAAAAQAAAAAAAAAAAAAAAAAAA'
        'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
    'afd8d9d1020027a501b4e3548523f60fdfc093b163a1a77a801514342bf9d1d9',
  ),
  (
    'memo-bom',
    'AAAAAgAAAAABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4fIAAAAGQAAAABAAAAAQAA'
        'AAAAAAABAAAABO+7v2EAAAABAAAAAAAAAAEAAAAAISIjJCUmJygpKissLS4vMDEyMzQ1Njc4'
        'OTo7PD0+P0AAAAAAAAAAAACYloAAAAAAAAAAAQAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAA'
        'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==',
    'd7cce4ebcf4c7aea1a94d145eb72eb1f6c31dcecf51e390aa43de916cdb00cfd',
  ),
  (
    'memo-cut28',
    'AAAAAgAAAAABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4fIAAAAGQAAAABAAAAAQAA'
        'AAAAAAABAAAAHGFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYcMAAAABAAAAAAAAAAEAAAAA'
        'ISIjJCUmJygpKissLS4vMDEyMzQ1Njc4OTo7PD0+P0AAAAAAAAAAAACYloAAAAAAAAAAAQAA'
        'AAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
        'AAAAAAAAAAAAAAAAAAAAAA==',
    'd99b04f76b7b09b523d59db35089e6256956d8fa89d4c2fdf00005a72ac182ea',
  ),
  (
    'memo-cut28b',
    'AAAAAgAAAAABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4fIAAAAGQAAAABAAAAAQAA'
        'AAAAAAABAAAAHGFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFh4oIAAAABAAAAAAAAAAEAAAAA'
        'ISIjJCUmJygpKissLS4vMDEyMzQ1Njc4OTo7PD0+P0AAAAAAAAAAAACYloAAAAAAAAAAAQAA'
        'AAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
        'AAAAAAAAAAAAAAAAAAAAAA==',
    'f2b1f6b938c090f68c163a71a0db74cb116ed2c7e28ef7a2e348077986224c9c',
  ),
  (
    'scvString-ffFe',
    'AAAAAgAAAAABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4fIAAAAGQAAAABAAAAAQAA'
        'AAAAAAAAAAAAAQAAAAAAAAAYAAAAAAAAAAFBQkNERUZHSElKS0xNTk9QUVJTVFVWV1hZWltc'
        'XV5fYAAAAAFmAAAAAAAAAQAAAA4AAAAG//4gYWJjAAAAAAAAAAAAAAAAAAEAAAAAAAAAQAAA'
        'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
        'AAAAAAAAAAA=',
    'd2271e8683ce85e52efbd45c6a2dbb1dac3ca61b16f4f36d8823b56486621b8c',
  ),
  (
    'scvString-bom',
    'AAAAAgAAAAABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4fIAAAAGQAAAABAAAAAQAA'
        'AAAAAAAAAAAAAQAAAAAAAAAYAAAAAAAAAAFBQkNERUZHSElKS0xNTk9QUVJTVFVWV1hZWltc'
        'XV5fYAAAAAFmAAAAAAAAAQAAAA4AAAAE77u/YQAAAAAAAAAAAAAAAQAAAAAAAABAAAAAAAAA'
        'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
        'AAAAAA==',
    '600608e5230c782b6385972888e34013ee0519031d5c0798cd32a55b9c164284',
  ),
  (
    'scvSymbol-ffFe',
    'AAAAAgAAAAABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4fIAAAAGQAAAABAAAAAQAA'
        'AAAAAAAAAAAAAQAAAAAAAAAYAAAAAAAAAAFBQkNERUZHSElKS0xNTk9QUVJTVFVWV1hZWltc'
        'XV5fYAAAAAFmAAAAAAAAAQAAAA8AAAAG//4gYWJjAAAAAAAAAAAAAAAAAAEAAAAAAAAAQAAA'
        'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
        'AAAAAAAAAAA=',
    'fe876329b5ab7aac3de3d7fbfee88cfd7bbd148fdb4c26bafd2e0bd483ea4983',
  ),
  (
    'scvSymbol-bom',
    'AAAAAgAAAAABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4fIAAAAGQAAAABAAAAAQAA'
        'AAAAAAAAAAAAAQAAAAAAAAAYAAAAAAAAAAFBQkNERUZHSElKS0xNTk9QUVJTVFVWV1hZWltc'
        'XV5fYAAAAAFmAAAAAAAAAQAAAA8AAAAE77u/YQAAAAAAAAAAAAAAAQAAAAAAAABAAAAAAAAA'
        'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
        'AAAAAA==',
    '9db200d7e94f46e9b46a3b09b8e99363939ea8fff5d8f6fd988ce8f949f0eb0c',
  ),
  (
    'fnName-ffFe',
    'AAAAAgAAAAABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4fIAAAAGQAAAABAAAAAQAA'
        'AAAAAAAAAAAAAQAAAAAAAAAYAAAAAAAAAAFBQkNERUZHSElKS0xNTk9QUVJTVFVWV1hZWltc'
        'XV5fYAAAAAb//iBhYmMAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAQAAAAAAAAAAAAAAAAAAA'
        'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
    '649e93a7e8a22e665be43f4850951f53ea8104949f60f121889d77a206976a4b',
  ),
  (
    'fnName-bom',
    'AAAAAgAAAAABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4fIAAAAGQAAAABAAAAAQAA'
        'AAAAAAAAAAAAAQAAAAAAAAAYAAAAAAAAAAFBQkNERUZHSElKS0xNTk9QUVJTVFVWV1hZWltc'
        'XV5fYAAAAATvu79hAAAAAAAAAAAAAAAAAAAAAQAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAA'
        'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==',
    '785e5a36182816ff9a2131446efd3b85e16cce555918d53a1d009ad00735d778',
  ),
  (
    'memo-bom2',
    'AAAAAgAAAAABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4fIAAAAGQAAAABAAAAAQAA'
        'AAAAAAABAAAAB++7v++7v2EAAAAAAQAAAAAAAAABAAAAACEiIyQlJicoKSorLC0uLzAxMjM0'
        'NTY3ODk6Ozw9Pj9AAAAAAAAAAAAAmJaAAAAAAAAAAAEAAAAAAAAAQAAAAAAAAAAAAAAAAAAA'
        'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
    '2a31d6472d0ee51764dd708a52fe149a83d11bc10e5ce8b9bfaa24158a90be22',
  ),
];

// (name, V0 envelope, the V1 form the import writes, hash).
final List<(String, String, String, String)>
_v0Cases = <(String, String, String, String)>[
  (
    'v0-memo-ffFe',
    'AAAAAAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8gAAAAZAAAAAEAAAABAAAAAAAA'
        'AAEAAAAG//4gYWJjAAAAAAABAAAAAAAAAAEAAAAAISIjJCUmJygpKissLS4vMDEyMzQ1Njc4'
        'OTo7PD0+P0AAAAAAAAAAAACYloAAAAAAAAAAAQAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAA'
        'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==',
    'AAAAAgAAAAABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4fIAAAAGQAAAABAAAAAQAA'
        'AAAAAAABAAAABv/+IGFiYwAAAAAAAQAAAAAAAAABAAAAACEiIyQlJicoKSorLC0uLzAxMjM0'
        'NTY3ODk6Ozw9Pj9AAAAAAAAAAAAAmJaAAAAAAAAAAAEAAAAAAAAAQAAAAAAAAAAAAAAAAAAA'
        'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
    'afd8d9d1020027a501b4e3548523f60fdfc093b163a1a77a801514342bf9d1d9',
  ),
  (
    'v0-memo-bom',
    'AAAAAAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8gAAAAZAAAAAEAAAABAAAAAAAA'
        'AAEAAAAE77u/YQAAAAEAAAAAAAAAAQAAAAAhIiMkJSYnKCkqKywtLi8wMTIzNDU2Nzg5Ojs8'
        'PT4/QAAAAAAAAAAAAJiWgAAAAAAAAAABAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
        'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
    'AAAAAgAAAAABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4fIAAAAGQAAAABAAAAAQAA'
        'AAAAAAABAAAABO+7v2EAAAABAAAAAAAAAAEAAAAAISIjJCUmJygpKissLS4vMDEyMzQ1Njc4'
        'OTo7PD0+P0AAAAAAAAAAAACYloAAAAAAAAAAAQAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAA'
        'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==',
    'd7cce4ebcf4c7aea1a94d145eb72eb1f6c31dcecf51e390aa43de916cdb00cfd',
  ),
  (
    'v0-memo-bom2',
    'AAAAAAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8gAAAAZAAAAAEAAAABAAAAAAAA'
        'AAEAAAAH77u/77u/YQAAAAABAAAAAAAAAAEAAAAAISIjJCUmJygpKissLS4vMDEyMzQ1Njc4'
        'OTo7PD0+P0AAAAAAAAAAAACYloAAAAAAAAAAAQAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAA'
        'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==',
    'AAAAAgAAAAABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4fIAAAAGQAAAABAAAAAQAA'
        'AAAAAAABAAAAB++7v++7v2EAAAAAAQAAAAAAAAABAAAAACEiIyQlJicoKSorLC0uLzAxMjM0'
        'NTY3ODk6Ozw9Pj9AAAAAAAAAAAAAmJaAAAAAAAAAAAEAAAAAAAAAQAAAAAAAAAAAAAAAAAAA'
        'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
    '2a31d6472d0ee51764dd708a52fe149a83d11bc10e5ce8b9bfaa24158a90be22',
  ),
  (
    'v0-2ops-fee200-memo-none',
    'AAAAAAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8gAAAAyAAAAAEAAAABAAAAAAAA'
        'AAAAAAACAAAAAAAAAAEAAAAAISIjJCUmJygpKissLS4vMDEyMzQ1Njc4OTo7PD0+P0AAAAAA'
        'AAAAAACYloAAAAAAAAAAAQAAAAAhIiMkJSYnKCkqKywtLi8wMTIzNDU2Nzg5Ojs8PT4/QAAA'
        'AAAAAAAAATEtAAAAAAAAAAABAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
        'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
    'AAAAAgAAAAABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4fIAAAAMgAAAABAAAAAQAA'
        'AAAAAAAAAAAAAgAAAAAAAAABAAAAACEiIyQlJicoKSorLC0uLzAxMjM0NTY3ODk6Ozw9Pj9A'
        'AAAAAAAAAAAAmJaAAAAAAAAAAAEAAAAAISIjJCUmJygpKissLS4vMDEyMzQ1Njc4OTo7PD0+'
        'P0AAAAAAAAAAAAExLQAAAAAAAAAAAQAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
        'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==',
    'a8da8515801f02678a926092014c2cdc5210aa5907da2dfcda6c0e69bb4542c9',
  ),
  (
    'v0-2ops-fee200-memo-ffFe',
    'AAAAAAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8gAAAAyAAAAAEAAAABAAAAAAAA'
        'AAEAAAAG//4gYWJjAAAAAAACAAAAAAAAAAEAAAAAISIjJCUmJygpKissLS4vMDEyMzQ1Njc4'
        'OTo7PD0+P0AAAAAAAAAAAACYloAAAAAAAAAAAQAAAAAhIiMkJSYnKCkqKywtLi8wMTIzNDU2'
        'Nzg5Ojs8PT4/QAAAAAAAAAAAATEtAAAAAAAAAAABAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAA'
        'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
    'AAAAAgAAAAABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4fIAAAAMgAAAABAAAAAQAA'
        'AAAAAAABAAAABv/+IGFiYwAAAAAAAgAAAAAAAAABAAAAACEiIyQlJicoKSorLC0uLzAxMjM0'
        'NTY3ODk6Ozw9Pj9AAAAAAAAAAAAAmJaAAAAAAAAAAAEAAAAAISIjJCUmJygpKissLS4vMDEy'
        'MzQ1Njc4OTo7PD0+P0AAAAAAAAAAAAExLQAAAAAAAAAAAQAAAAAAAABAAAAAAAAAAAAAAAAA'
        'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==',
    'f5bb99c62173175876a0f612a712addc62dc5193fafa55553fb73cb364637abd',
  ),
  (
    'v0-timebounds-memo-ffFe',
    'AAAAAAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8gAAAAZAAAAAEAAAABAAAAAQAA'
        'AAAAAAAAAAAAAGlVuQAAAAABAAAABv/+IGFiYwAAAAAAAQAAAAAAAAABAAAAACEiIyQlJico'
        'KSorLC0uLzAxMjM0NTY3ODk6Ozw9Pj9AAAAAAAAAAAAAmJaAAAAAAAAAAAEAAAAAAAAAQAAA'
        'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
        'AAAAAAAAAAA=',
    'AAAAAgAAAAABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4fIAAAAGQAAAABAAAAAQAA'
        'AAEAAAAAAAAAAAAAAABpVbkAAAAAAQAAAAb//iBhYmMAAAAAAAEAAAAAAAAAAQAAAAAhIiMk'
        'JSYnKCkqKywtLi8wMTIzNDU2Nzg5Ojs8PT4/QAAAAAAAAAAAAJiWgAAAAAAAAAABAAAAAAAA'
        'AEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
        'AAAAAAAAAAAAAAAA',
    '2da74931f32d2c36c3420a401105d1ac797a81a103d75fefba1155b6fef1b4b7',
  ),
  (
    'v0-2ops-fee200-timebounds-memo-valid',
    'AAAAAAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8gAAAAyAAAAAEAAAABAAAAAQAA'
        'AAAAAAAAAAAAAGlVuQAAAAABAAAAA8OpMQAAAAACAAAAAAAAAAEAAAAAISIjJCUmJygpKiss'
        'LS4vMDEyMzQ1Njc4OTo7PD0+P0AAAAAAAAAAAACYloAAAAAAAAAAAQAAAAAhIiMkJSYnKCkq'
        'KywtLi8wMTIzNDU2Nzg5Ojs8PT4/QAAAAAAAAAAAATEtAAAAAAAAAAABAAAAAAAAAEAAAAAA'
        'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
        'AAAAAAAA',
    'AAAAAgAAAAABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4fIAAAAMgAAAABAAAAAQAA'
        'AAEAAAAAAAAAAAAAAABpVbkAAAAAAQAAAAPDqTEAAAAAAgAAAAAAAAABAAAAACEiIyQlJico'
        'KSorLC0uLzAxMjM0NTY3ODk6Ozw9Pj9AAAAAAAAAAAAAmJaAAAAAAAAAAAEAAAAAISIjJCUm'
        'JygpKissLS4vMDEyMzQ1Njc4OTo7PD0+P0AAAAAAAAAAAAExLQAAAAAAAAAAAQAAAAAAAABA'
        'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
        'AAAAAAAAAAAAAA==',
    '6e3638fb3c7cb6581e1d8cf6169ce03f4c238d535d0b9cea44984e43fe5a1201',
  ),
];

// (name, fee bump envelope, outer hash, inner hash).
final List<(String, String, String, String)>
_feeBumpCases = <(String, String, String, String)>[
  (
    'feebump-memo-ffFe',
    'AAAABQAAAABhYmNkZWZnaGlqa2xtbm9wcXJzdHV2d3h5ent8fX5/gAAAAAAAAAGQAAAAAgAA'
        'AAABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4fIAAAAGQAAAABAAAAAQAAAAAAAAAB'
        'AAAABv/+IGFiYwAAAAAAAQAAAAAAAAABAAAAACEiIyQlJicoKSorLC0uLzAxMjM0NTY3ODk6'
        'Ozw9Pj9AAAAAAAAAAAAAmJaAAAAAAAAAAAEAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAA'
        'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAA'
        'AAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
        'AAAAAAAAAAAAAAAAAAAAAA==',
    'd8db2bb148d0a5b11885818541b9abe4bc44e3ad43de5e64a3b74bea2c748537',
    'afd8d9d1020027a501b4e3548523f60fdfc093b163a1a77a801514342bf9d1d9',
  ),
  (
    'feebump-memo-bom',
    'AAAABQAAAABhYmNkZWZnaGlqa2xtbm9wcXJzdHV2d3h5ent8fX5/gAAAAAAAAAGQAAAAAgAA'
        'AAABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4fIAAAAGQAAAABAAAAAQAAAAAAAAAB'
        'AAAABO+7v2EAAAABAAAAAAAAAAEAAAAAISIjJCUmJygpKissLS4vMDEyMzQ1Njc4OTo7PD0+'
        'P0AAAAAAAAAAAACYloAAAAAAAAAAAQAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
        'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAA'
        'AEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
        'AAAAAAAAAAAAAAAA',
    'd50d964ee0e4ded79a0c8a527438daac87685040c8456c603cc709d5e0877c0e',
    'd7cce4ebcf4c7aea1a94d145eb72eb1f6c31dcecf51e390aa43de916cdb00cfd',
  ),
  (
    'feebump-memo-bom2',
    'AAAABQAAAABhYmNkZWZnaGlqa2xtbm9wcXJzdHV2d3h5ent8fX5/gAAAAAAAAAGQAAAAAgAA'
        'AAABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4fIAAAAGQAAAABAAAAAQAAAAAAAAAB'
        'AAAAB++7v++7v2EAAAAAAQAAAAAAAAABAAAAACEiIyQlJicoKSorLC0uLzAxMjM0NTY3ODk6'
        'Ozw9Pj9AAAAAAAAAAAAAmJaAAAAAAAAAAAEAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAA'
        'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAA'
        'AAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
        'AAAAAAAAAAAAAAAAAAAAAA==',
    '34e6f71d40bf353d481cd37a493d78a4153eb7d163490093cb120ae6b56892c7',
    '2a31d6472d0ee51764dd708a52fe149a83d11bc10e5ce8b9bfaa24158a90be22',
  ),
];

// (name, authorization entry, preimage, payload hash) with nonce 1234567,
// signature expiration ledger 1000 and signer bytes 129 to 160.
final List<(String, String, String, String)>
_authCases = <(String, String, String, String)>[
  (
    'auth-fn-ffFe',
    'AAAAAQAAAAAAAAAAgYKDhIWGh4iJiouMjY6PkJGSk5SVlpeYmZqbnJ2en6AAAAAAABLWhwAA'
        'A+gAAAABAAAAAAAAAAFBQkNERUZHSElKS0xNTk9QUVJTVFVWV1hZWltcXV5fYAAAAAb//iBh'
        'YmMAAAAAAAAAAAAA',
    'AAAACc7gMC1ZhE0yvcqRXIID3USzP7t+3BkFHqN6vt8o7NRyAAAAAAAS1ocAAAPoAAAAAAAA'
        'AAFBQkNERUZHSElKS0xNTk9QUVJTVFVWV1hZWltcXV5fYAAAAAb//iBhYmMAAAAAAAAAAAAA',
    'd0a19f113ebb858c5459673806b3ec674fe893f60b0cb0fa731fc497c6d24d99',
  ),
  (
    'auth-fn-bom',
    'AAAAAQAAAAAAAAAAgYKDhIWGh4iJiouMjY6PkJGSk5SVlpeYmZqbnJ2en6AAAAAAABLWhwAA'
        'A+gAAAABAAAAAAAAAAFBQkNERUZHSElKS0xNTk9QUVJTVFVWV1hZWltcXV5fYAAAAATvu79h'
        'AAAAAAAAAAA=',
    'AAAACc7gMC1ZhE0yvcqRXIID3USzP7t+3BkFHqN6vt8o7NRyAAAAAAAS1ocAAAPoAAAAAAAA'
        'AAFBQkNERUZHSElKS0xNTk9QUVJTVFVWV1hZWltcXV5fYAAAAATvu79hAAAAAAAAAAA=',
    'b7e14047c0a7289fcd94da522ddaab04acd063db75e3b4a5189e352ba0ec84a6',
  ),
  (
    'auth-arg-string-ffFe',
    'AAAAAQAAAAAAAAAAgYKDhIWGh4iJiouMjY6PkJGSk5SVlpeYmZqbnJ2en6AAAAAAABLWhwAA'
        'A+gAAAABAAAAAAAAAAFBQkNERUZHSElKS0xNTk9QUVJTVFVWV1hZWltcXV5fYAAAAAh0cmFu'
        'c2ZlcgAAAAEAAAAOAAAABv/+IGFiYwAAAAAAAA==',
    'AAAACc7gMC1ZhE0yvcqRXIID3USzP7t+3BkFHqN6vt8o7NRyAAAAAAAS1ocAAAPoAAAAAAAA'
        'AAFBQkNERUZHSElKS0xNTk9QUVJTVFVWV1hZWltcXV5fYAAAAAh0cmFuc2ZlcgAAAAEAAAAO'
        'AAAABv/+IGFiYwAAAAAAAA==',
    '85a9809802da0bc78328f29b3a6671f7b67732ae79f4e3697b0b56bdc4690c33',
  ),
  (
    'auth-arg-symbol-ffFe',
    'AAAAAQAAAAAAAAAAgYKDhIWGh4iJiouMjY6PkJGSk5SVlpeYmZqbnJ2en6AAAAAAABLWhwAA'
        'A+gAAAABAAAAAAAAAAFBQkNERUZHSElKS0xNTk9QUVJTVFVWV1hZWltcXV5fYAAAAAh0cmFu'
        'c2ZlcgAAAAEAAAAPAAAABv/+IGFiYwAAAAAAAA==',
    'AAAACc7gMC1ZhE0yvcqRXIID3USzP7t+3BkFHqN6vt8o7NRyAAAAAAAS1ocAAAPoAAAAAAAA'
        'AAFBQkNERUZHSElKS0xNTk9QUVJTVFVWV1hZWltcXV5fYAAAAAh0cmFuc2ZlcgAAAAEAAAAP'
        'AAAABv/+IGFiYwAAAAAAAA==',
    '2bb12e4f019acfc3557c522e30ebe9f8028329f937e63b78eeb85a52d5c4285f',
  ),
  (
    'auth-arg-string-bom',
    'AAAAAQAAAAAAAAAAgYKDhIWGh4iJiouMjY6PkJGSk5SVlpeYmZqbnJ2en6AAAAAAABLWhwAA'
        'A+gAAAABAAAAAAAAAAFBQkNERUZHSElKS0xNTk9QUVJTVFVWV1hZWltcXV5fYAAAAAh0cmFu'
        'c2ZlcgAAAAEAAAAOAAAABO+7v2EAAAAA',
    'AAAACc7gMC1ZhE0yvcqRXIID3USzP7t+3BkFHqN6vt8o7NRyAAAAAAAS1ocAAAPoAAAAAAAA'
        'AAFBQkNERUZHSElKS0xNTk9QUVJTVFVWV1hZWltcXV5fYAAAAAh0cmFuc2ZlcgAAAAEAAAAO'
        'AAAABO+7v2EAAAAA',
    'f2319301b2ced3a8dcf2dc6d044ad8f1949e5ee3233aa5417b8d2e646636c3a5',
  ),
];

// A testnet transaction record whose text memo is ff fe 20 61 62 63.
const String _liveTransactionJson = r'''
{
  "memo": "\ufffd\ufffd abc",
  "memo_bytes": "//4gYWJj",
  "_links": {"self":{"href":"https://horizon-testnet.stellar.org/transactions/b7fb286bcb380d0f3b9ace77c8b513cc348e89805ddf16a076f2085ee8dc0816"},"account":{"href":"https://horizon-testnet.stellar.org/accounts/GB6XJIMOUTHNC6KYHWTOECKQJY2UHCFRODONBGMNKG5KVBB5PZHTB5XB"},"ledger":{"href":"https://horizon-testnet.stellar.org/ledgers/5830015"},"operations":{"href":"https://horizon-testnet.stellar.org/transactions/b7fb286bcb380d0f3b9ace77c8b513cc348e89805ddf16a076f2085ee8dc0816/operations{?cursor,limit,order}","templated":true},"effects":{"href":"https://horizon-testnet.stellar.org/transactions/b7fb286bcb380d0f3b9ace77c8b513cc348e89805ddf16a076f2085ee8dc0816/effects{?cursor,limit,order}","templated":true},"precedes":{"href":"https://horizon-testnet.stellar.org/transactions?order=asc&cursor=25039723760209920"},"succeeds":{"href":"https://horizon-testnet.stellar.org/transactions?order=desc&cursor=25039723760209920"},"transaction":{"href":"https://horizon-testnet.stellar.org/transactions/b7fb286bcb380d0f3b9ace77c8b513cc348e89805ddf16a076f2085ee8dc0816"}},
  "id": "b7fb286bcb380d0f3b9ace77c8b513cc348e89805ddf16a076f2085ee8dc0816",
  "paging_token": "25039723760209920",
  "successful": true,
  "hash": "b7fb286bcb380d0f3b9ace77c8b513cc348e89805ddf16a076f2085ee8dc0816",
  "ledger": 5830015,
  "created_at": "2026-11-20T11:21:55Z",
  "source_account": "GB6XJIMOUTHNC6KYHWTOECKQJY2UHCFRODONBGMNKG5KVBB5PZHTB5XB",
  "source_account_sequence": "25039715170254849",
  "fee_account": "GB6XJIMOUTHNC6KYHWTOECKQJY2UHCFRODONBGMNKG5KVBB5PZHTB5XB",
  "fee_charged": "100",
  "max_fee": "1000",
  "operation_count": 1,
  "envelope_xdr": "AAAAAgAAAAB9dKGOpM7ReVg9puIJUE41Q4ixcNzQmY1RuqqEPX5PMAAAA+gAWPV9AAAAAQAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAb//iBhYmMAAAAAAAEAAAAAAAAAAQAAAACkQeBd9iE/juL6rqj0VVFw2v8aYlIFPrDcDVEpm7RX1AAAAAAAAAAAAJiWgAAAAAAAAAABPX5PMAAAAEAqERgvj65qzoHGjnHgWnfheLjxKwOqWTLzvu/v3OwwOi2Qkejhk2V7ODCcq9/yVZ0M6rvDcOIIUrlecenAIGYP",
  "result_xdr": "AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAA=",
  "fee_meta_xdr": "AAAAAgAAAAMAWPV9AAAAAAAAAAB9dKGOpM7ReVg9puIJUE41Q4ixcNzQmY1RuqqEPX5PMAAAABdIdugAAFj1fQAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAEAWPV/AAAAAAAAAAB9dKGOpM7ReVg9puIJUE41Q4ixcNzQmY1RuqqEPX5PMAAAABdIduecAFj1fQAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAA==",
  "memo_type": "text",
  "signatures": ["KhEYL4+uas6Bxo5x4Fp34Xi48SsDqlky877v79zsMDotkJHo4ZNlezgwnKvf8lWdDOq7w3DiCFK5XnHpwCBmDw=="],
  "preconditions": {"timebounds":{"min_time":"0"}}
}
''';

void main() {
  group('transaction import', () {
    for (final (String name, String envelope, String hash) in _v1Cases) {
      test('a V1 envelope with $name re-encodes and hashes exactly', () {
        final AbstractTransaction tx =
            AbstractTransaction.fromEnvelopeXdrString(envelope);
        expect(tx.toEnvelopeXdrBase64(), envelope);
        expect(Util.bytesToHex(tx.hash(Network.TESTNET)), hash);
        _expectXdrRoundTrip(envelope);
        _expectSignatureOver(tx, hash);
      });
    }

    for (final (String name, String v0, String v1, String hash) in _v0Cases) {
      test('a V0 envelope $name imports in its V1 form', () {
        final AbstractTransaction tx =
            AbstractTransaction.fromEnvelopeXdrString(v0);
        expect(tx.toEnvelopeXdrBase64(), v1);
        expect(Util.bytesToHex(tx.hash(Network.TESTNET)), hash);
        if (name.contains('2ops')) {
          expect((tx as Transaction).fee, 200);
        }
        _expectXdrRoundTrip(v0);
        _expectSignatureOver(tx, hash);
      });
    }

    for (final (String name, String envelope, String hash, String innerHash)
        in _feeBumpCases) {
      test('a fee bump $name keeps the outer and inner hashes', () {
        final FeeBumpTransaction tx =
            AbstractTransaction.fromEnvelopeXdrString(envelope)
                as FeeBumpTransaction;
        expect(tx.toEnvelopeXdrBase64(), envelope);
        expect(Util.bytesToHex(tx.hash(Network.TESTNET)), hash);
        expect(
          Util.bytesToHex(tx.innerTransaction.hash(Network.TESTNET)),
          innerHash,
        );
        _expectXdrRoundTrip(envelope);
        _expectSignatureOver(tx, hash);
      });
    }

    test('an invoked function name keeps its bytes through the operation', () {
      final Transaction tx =
          AbstractTransaction.fromEnvelopeXdrString(_envelope('fnName-ffFe'))
              as Transaction;
      final InvokeContractHostFunction function =
          (tx.operations.single as InvokeHostFunctionOperation).function
              as InvokeContractHostFunction;
      expect(function.functionNameBytes, _ffFe);
      expect(() => function.functionName, throwsFormatException);
      final InvokeContractHostFunction named = InvokeContractHostFunction(
        _contract,
        'hello',
      );
      expect(named.functionNameBytes, utf8.encode('hello'));
      named.functionNameBytes = _ffFe;
      expect(named.toXdr().invokeContract!.functionNameBytes, _ffFe);
    });
  });

  group('MemoText', () {
    test('holds bytes that are not UTF-8', () {
      final MemoText memo = MemoText.fromBytes(_ffFe);
      expect(memo.bytes, _ffFe);
      expect(() => memo.text, throwsFormatException);
      expect(memo.toXdr().textBytes, _ffFe);
      final Memo decoded = Memo.fromXdr(memo.toXdr());
      expect((decoded as MemoText).bytes, _ffFe);
    });

    test('keeps a copy of the bytes it is given', () {
      final Uint8List bytes = Uint8List.fromList(_ffFe);
      final MemoText memo = MemoText.fromBytes(bytes);
      bytes[0] = 0x61;
      expect(memo.bytes, _ffFe);
    });

    test('reads a leading byte order mark as text', () {
      final MemoText memo = MemoText.fromBytes(_hex('efbbbf61'));
      expect(memo.text, '${String.fromCharCode(0xFEFF)}a');
      expect(MemoText(memo.text!).bytes, _hex('efbbbf61'));
    });

    test('equality and hashing compare the bytes', () {
      expect(
        MemoText.fromBytes(_ffFe),
        MemoText.fromBytes(_hex('fffe20616263')),
      );
      expect(
        MemoText.fromBytes(_ffFe).hashCode,
        MemoText.fromBytes(_hex('fffe20616263')).hashCode,
      );
      expect(
        MemoText.fromBytes(_ffFe),
        isNot(MemoText.fromBytes(_hex('fffe'))),
      );
      expect(MemoText('a'), MemoText.fromBytes(_hex('61')));
      expect(MemoText('a').hashCode, MemoText.fromBytes(_hex('61')).hashCode);
    });

    test('refuses more than 28 bytes', () {
      expect(MemoText.fromBytes(Uint8List(28)).bytes, hasLength(28));
      expect(
        () => MemoText.fromBytes(Uint8List(29)),
        throwsA(isA<MemoTooLongException>()),
      );
    });
  });

  group('TxRep', () {
    test('writes and reads the memo bytes', () {
      for (final (String name, String escaped) in <(String, String)>[
        ('memo-ffFe', r'"\xff\xfe abc"'),
        ('memo-bom', r'"\xef\xbb\xbfa"'),
        ('memo-cut28', r'"aaaaaaaaaaaaaaaaaaaaaaaaaaa\xc3"'),
      ]) {
        final String txRep = TxRep.fromTransactionEnvelopeXdrBase64(
          _envelope(name),
        );
        expect(txRep, contains('tx.memo.text: $escaped'));
        expect(
          TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
          _envelope(name),
        );
      }
    });

    test('reads unquoted memo text as its UTF-8 bytes', () {
      final String txRep = TxRep.fromTransactionEnvelopeXdrBase64(
        _envelope('memo-ffFe'),
      ).replaceFirst(r'tx.memo.text: "\xff\xfe abc"', 'tx.memo.text: plain');
      final Transaction tx =
          AbstractTransaction.fromEnvelopeXdrString(
                TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
              )
              as Transaction;
      expect((tx.memo as MemoText).bytes, utf8.encode('plain'));
    });

    test('round-trips string values and function names', () {
      for (final String name in <String>[
        'scvString-ffFe',
        'scvSymbol-bom',
        'fnName-ffFe',
      ]) {
        final String txRep = TxRep.fromTransactionEnvelopeXdrBase64(
          _envelope(name),
        );
        expect(
          TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
          _envelope(name),
        );
      }
    });
  });

  group('Horizon transaction records', () {
    Map<String, dynamic> record({String? memo, String? memoBytes}) {
      final Map<String, dynamic> json =
          jsonDecode(_liveTransactionJson) as Map<String, dynamic>;
      if (memo != null) json['memo'] = memo;
      if (memoBytes != null) json['memo_bytes'] = memoBytes;
      return json;
    }

    final String replacement = String.fromCharCode(0xFFFD);

    test('the text memo comes from memo_bytes', () {
      final TransactionResponse response = TransactionResponse.fromJson(
        record(),
      );
      expect((response.memo as MemoText).bytes, _ffFe);
      final AbstractTransaction tx = AbstractTransaction.fromEnvelopeXdrString(
        response.envelopeXdr,
      );
      expect(Util.bytesToHex(tx.hash(Network.TESTNET)), response.hash);
      expect(tx.toEnvelopeXdrBase64(), response.envelopeXdr);
      _expectXdrRoundTrip(response.envelopeXdr);
      expect(((tx as Transaction).memo as MemoText).bytes, _ffFe);
    });

    test('a memo of 28 ff bytes and a memo cut inside a sequence decode', () {
      final TransactionResponse full = TransactionResponse.fromJson(
        record(
          memo: replacement * 28,
          memoBytes: '/////////////////////////////////////w==',
        ),
      );
      expect(
        (full.memo as MemoText).bytes,
        Uint8List.fromList(List<int>.filled(28, 0xff)),
      );
      final TransactionResponse cut = TransactionResponse.fromJson(
        record(
          memo: '${'a' * 27}$replacement',
          memoBytes: 'YWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhww==',
        ),
      );
      expect(
        (cut.memo as MemoText).bytes,
        Uint8List.fromList(<int>[...List<int>.filled(27, 0x61), 0xc3]),
      );
    });

    test('a text memo without memo_bytes comes from memo', () {
      final Memo memo = Memo.fromJson(<String, dynamic>{
        'memo_type': 'text',
        'memo': 'hello',
      });
      expect((memo as MemoText).bytes, utf8.encode('hello'));
    });
  });

  group('SEP-7', () {
    test('accepts and signs a transaction whose memo is not UTF-8', () async {
      final String envelope = _envelope('memo-ffFe');
      String? posted;
      final URIScheme uriScheme = URIScheme(
        httpClient: MockClient((http.Request request) async {
          posted = Uri.splitQueryString(request.body)['xdr'];
          return http.Response('{}', 200);
        }),
      );
      final String url = uriScheme.generateSignTransactionURI(
        envelope,
        callback: 'url:https://example.com/callback',
      );
      expect(uriScheme.isValidSep7Url(url).result, true);

      await uriScheme.signAndSubmitTransaction(
        url,
        KeyPair.random(),
        network: Network.TESTNET,
      );
      final Transaction signed =
          AbstractTransaction.fromEnvelopeXdrString(posted!) as Transaction;
      expect(
        Util.bytesToHex(signed.hash(Network.TESTNET)),
        'afd8d9d1020027a501b4e3548523f60fdfc093b163a1a77a801514342bf9d1d9',
      );
      expect(signed.signatures, hasLength(2));
      expect((signed.memo as MemoText).bytes, _ffFe);
    });
  });

  group('SEP-10', () {
    test('a challenge with a text memo that is not UTF-8 has the wrong memo '
        'type', () {
      final XdrTransactionEnvelope challenge =
          XdrTransactionEnvelope.fromEnvelopeXdrString(_envelope('memo-ffFe'));
      challenge.v1!.tx.seqNum = XdrSequenceNumber(BigInt.zero);
      final WebAuth webAuth = WebAuth(
        'https://example.com/auth',
        Network.TESTNET,
        _server,
        'example.com',
      );
      expect(
        () => webAuth.validateChallenge(
          challenge.toEnvelopeXdrBase64(),
          _server,
          null,
        ),
        throwsA(isA<ChallengeValidationErrorInvalidMemoType>()),
      );
    });
  });

  group('SEP-45', () {
    test('an entry whose function name is not UTF-8 has the wrong name', () {
      final SorobanAuthorizationEntry entry = SorobanAuthorizationEntry(
        SorobanCredentials(
          addressCredentials: SorobanAddressCredentials(
            Address.forAccountId(_server),
            BigInt.one,
            9999,
            XdrSCVal.forVoid(),
          ),
        ),
        SorobanAuthorizedInvocation(
          SorobanAuthorizedFunction(
            contractFn: XdrInvokeContractArgs.withFunctionNameBytes(
              Address.forContractId(_contract).toXdr(),
              _ffFe,
              <XdrSCVal>[],
            ),
          ),
        ),
      );
      final WebAuthForContracts webAuth = WebAuthForContracts(
        'https://example.com/auth',
        _contract,
        _server,
        'example.com',
        Network.TESTNET,
      );
      expect(
        () => webAuth.validateChallenge(<SorobanAuthorizationEntry>[
          entry,
        ], _contract),
        throwsA(isA<ContractChallengeValidationErrorInvalidFunctionName>()),
      );
    });
  });

  group('Soroban authorization payloads', () {
    for (final (String name, String entry, String preimage, String hash)
        in _authCases) {
      test('$name builds the exact preimage', () {
        final SorobanAuthorizationEntry decoded =
            SorobanAuthorizationEntry.fromBase64EncodedXdr(entry);
        expect(decoded.toBase64EncodedXdrString(), entry);
        final XdrDataOutputStream stream = XdrDataOutputStream();
        XdrHashIDPreimage.encode(
          stream,
          decoded.buildPreimage(Network.TESTNET),
        );
        final Uint8List bytes = Uint8List.fromList(stream.bytes);
        expect(base64Encode(bytes), preimage);
        expect(Util.bytesToHex(Util.hash(bytes)), hash);
      });
    }
  });

  group('events, host order and native conversion', () {
    test('an event value whose string is not UTF-8 decodes', () {
      final EventInfo info = EventInfo.fromJson(<String, dynamic>{
        'type': 'contract',
        'ledger': 1234,
        'ledgerClosedAt': '2026-01-01T00:00:00Z',
        'contractId': _contract,
        'id': '0000000000001234-0000000001',
        'topic': <String>[
          XdrSCVal.forSymbol('transfer').toBase64EncodedXdrString(),
        ],
        'value': <String, dynamic>{'xdr': 'AAAADgAAAAb//iBhYmMAAA=='},
        'inSuccessfulContractCall': true,
        'txHash': 'deadbeef',
      });
      expect(info.valueXdr.strBytes, _ffFe);
    });

    test('host order compares the stored bytes', () {
      final Uint8List c0 = _hex('c0');
      final Uint8List ff = _hex('ff');
      expect(
        compareScValHostOrder(
          XdrSCVal.forStringBytes(c0),
          XdrSCVal.forStringBytes(ff),
        ),
        lessThan(0),
      );
      expect(
        compareScValHostOrder(
          XdrSCVal.forSymbolBytes(ff),
          XdrSCVal.forSymbolBytes(c0),
        ),
        greaterThan(0),
      );
      final XdrSCVal sorted = sortedScMap(<XdrSCMapEntry>[
        _entry(XdrSCVal.forStringBytes(ff)),
        _entry(XdrSCVal.forStringBytes(c0)),
      ]);
      expect(
        sorted.map!.map((XdrSCMapEntry e) => e.key.strBytes).toList(),
        <Uint8List>[c0, ff],
      );
    });

    test('text that is not UTF-8 has no native form', () {
      final XdrSCVal top = XdrSCVal.forStringBytes(_hex('ff61'));
      expect(identical(top.toNative(), top), true);
      final XdrSCVal symbol = XdrSCVal.forSymbolBytes(_hex('ff61'));
      expect(identical(symbol.toNative(), symbol), true);
      final XdrSCVal oneKey = XdrSCVal.forMap(<XdrSCMapEntry>[
        _entry(XdrSCVal.forStringBytes(_hex('ff61'))),
      ]);
      expect(identical(oneKey.toNative(), oneKey), true);
      final XdrSCVal twoKeys = XdrSCVal.forMap(<XdrSCMapEntry>[
        _entry(XdrSCVal.forStringBytes(_hex('ff61'))),
        _entry(XdrSCVal.forSymbolBytes(_hex('fe61'))),
      ]);
      expect(identical(twoKeys.toNative(), twoKeys), true);
      final XdrSCVal valid = XdrSCVal.forMap(<XdrSCMapEntry>[
        _entry(XdrSCVal.forStringBytes(_hex('c3a9'))),
        _entry(XdrSCVal.forStringBytes(_hex('61'))),
      ]);
      expect(valid.toNative(), <String, int>{
        String.fromCharCode(0xe9): 1,
        'a': 1,
      });
    });
  });
}
