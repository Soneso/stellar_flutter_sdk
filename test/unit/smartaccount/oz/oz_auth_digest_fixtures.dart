// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

/// One auth entry with the digest values both schemes give for it.
class AuthDigestVector {
  const AuthDigestVector({
    required this.name,
    required this.entryXdrBase64,
    required this.expirationLedger,
    required this.contextRuleIds,
    required this.signaturePayloadHex,
    required this.preimageV1DigestHex,
    required this.preimageV1ArgsXdrBase64,
    required this.legacyDigestHex,
    required this.legacyArgsXdrBase64,
  });

  final String name;
  final String entryXdrBase64;
  final int expirationLedger;
  final List<int> contextRuleIds;
  final String signaturePayloadHex;
  final String preimageV1DigestHex;
  final String preimageV1ArgsXdrBase64;
  final String legacyDigestHex;
  final String legacyArgsXdrBase64;

  XdrSorobanAuthorizationEntry entry() =>
      XdrSorobanAuthorizationEntry.fromBase64EncodedXdrString(entryXdrBase64);
}

/// The network of every vector.
const String vectorNetworkPassphrase = 'Test SDF Network ; September 2015';

const String _fixtureEntryXdrBase64 =
    'AAAAAgAAAAG+RSDwfubeCBGA2j8IjsapddrC1fpjzH1qwT+E3TPyhwAAAR9x+wTLAAAAAAAA'
    'AAEAAAAAAAAAAdeSi3LCcDzP6vfrn/TvTVBKVai5efybRQ6iyEK00c5hAAAACHRyYW5zZmVy'
    'AAAAAwAAABIAAAABvkUg8H7m3ggRgNo/CI7GqXXawtX6Y8x9asE/hN0z8ocAAAASAAAAAAAA'
    'AAA/DDS/k60NmXHQTMyQ9wVRHIOKrZc0pKL7DXoD/H/omgAAAAoAAAAAAAAAAAAAAAAAD0JA'
    'AAAAAA==';

/// The `entry` of `test/fixtures/auth_digest_cross_sdk_fixture.json`: a
/// native asset transfer authorized with ADDRESS_V2 credentials and nonce
/// 1234567890123. `oz_auth_digest_test.dart` checks these values against the
/// file; the browser cannot read it.
const AuthDigestVector fixtureEntryVector = AuthDigestVector(
  name: 'fixture entry, ADDRESS_V2',
  entryXdrBase64: _fixtureEntryXdrBase64,
  expirationLedger: 123456,
  contextRuleIds: <int>[0, 7],
  signaturePayloadHex:
      '06985c9d7f7cf0a1d6b15f5236061b06aed93fbcff637594b54d260be03f47c9',
  preimageV1DigestHex:
      '0d69bcc372549ca2895758603b5eff8845acbb414a97c894641c74669ba2eb91',
  preimageV1ArgsXdrBase64:
      'AAAAEQAAAAEAAAADAAAADwAAAAdhY2NvdW50AAAAABIAAAABvkUg8H7m3ggRgNo/CI7GqXXa'
      'wtX6Y8x9asE/hN0z8ocAAAAPAAAAEGNvbnRleHRfcnVsZV9pZHMAAAAQAAAAAQAAAAIAAAAD'
      'AAAAAAAAAAMAAAAHAAAADwAAABFzaWduYXR1cmVfcGF5bG9hZAAAAAAAAA0AAAAgBphcnX98'
      '8KHWsV9SNgYbBq7ZP7z/Y3WUtU0mC+A/R8k=',
  legacyDigestHex:
      '937a38f8d656cb7baa44083e169ba1bc82b4a649111830a65ac2bffa3901be00',
  legacyArgsXdrBase64:
      'AAAADQAAACCTejj41lbLe6pECD4Wm6G8grSmSREYMKZawr/6OQG+AA==',
);

/// A fixture entry variant for [vectorFromFixtureEntry]: the credential
/// [arm], a [nonce] above 2^53 and the expected values.
class BigNonceVector {
  const BigNonceVector({
    required this.arm,
    required this.nonce,
    required this.expected,
  });

  final XdrSorobanCredentialsType arm;
  final String nonce;
  final AuthDigestVector expected;
}

/// The fixture entry with ADDRESS and ADDRESS_V2 credentials, a nonce above
/// 2^53, the u32 maximum as signature expiration and the rule ids 0 and
/// 4294967295. The values were computed outside the SDK, XDR by hand with
/// Python's struct and SHA-256 with hashlib; the same computation reproduces
/// every value of [fixtureEntryVector].
const List<BigNonceVector> bigNonceVectors = <BigNonceVector>[
  BigNonceVector(
    arm: XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS,
    nonce: '9223372036854775807',
    expected: AuthDigestVector(
      name: 'ADDRESS, nonce 2^63-1',
      entryXdrBase64:
          'AAAAAQAAAAG+RSDwfubeCBGA2j8IjsapddrC1fpjzH1qwT+E3TPyh3//////////AAAA'
          'AAAAAAEAAAAAAAAAAdeSi3LCcDzP6vfrn/TvTVBKVai5efybRQ6iyEK00c5hAAAACHRy'
          'YW5zZmVyAAAAAwAAABIAAAABvkUg8H7m3ggRgNo/CI7GqXXawtX6Y8x9asE/hN0z8ocA'
          'AAASAAAAAAAAAAA/DDS/k60NmXHQTMyQ9wVRHIOKrZc0pKL7DXoD/H/omgAAAAoAAAAA'
          'AAAAAAAAAAAAD0JAAAAAAA==',
      expirationLedger: 4294967295,
      contextRuleIds: <int>[0, 4294967295],
      signaturePayloadHex:
          '2de118b011e4cbe6fce307d2275b0e6829e97d2c2346391205cf10495e455d99',
      preimageV1DigestHex:
          'a4bb894572cc70821ede6ac6443691f421929455a094ca0d4c0fb395c4d91fa4',
      preimageV1ArgsXdrBase64:
          'AAAAEQAAAAEAAAADAAAADwAAAAdhY2NvdW50AAAAABIAAAABvkUg8H7m3ggRgNo/CI7G'
          'qXXawtX6Y8x9asE/hN0z8ocAAAAPAAAAEGNvbnRleHRfcnVsZV9pZHMAAAAQAAAAAQAA'
          'AAIAAAADAAAAAAAAAAP/////AAAADwAAABFzaWduYXR1cmVfcGF5bG9hZAAAAAAAAA0A'
          'AAAgLeEYsBHky+b84wfSJ1sOaCnpfSwjRjkSBc8QSV5FXZk=',
      legacyDigestHex:
          '23752ff337ad58c4a4b3a0f0407c6609cfb9eb382069e5df4d40a8a1b563a799',
      legacyArgsXdrBase64:
          'AAAADQAAACAjdS/zN61YxKSzoPBAfGYJz7nrOCBp5d9NQKihtWOnmQ==',
    ),
  ),
  BigNonceVector(
    arm: XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2,
    nonce: '9007199254740993',
    expected: AuthDigestVector(
      name: 'ADDRESS_V2, nonce 2^53+1',
      entryXdrBase64:
          'AAAAAgAAAAG+RSDwfubeCBGA2j8IjsapddrC1fpjzH1qwT+E3TPyhwAgAAAAAAABAAAA'
          'AAAAAAEAAAAAAAAAAdeSi3LCcDzP6vfrn/TvTVBKVai5efybRQ6iyEK00c5hAAAACHRy'
          'YW5zZmVyAAAAAwAAABIAAAABvkUg8H7m3ggRgNo/CI7GqXXawtX6Y8x9asE/hN0z8ocA'
          'AAASAAAAAAAAAAA/DDS/k60NmXHQTMyQ9wVRHIOKrZc0pKL7DXoD/H/omgAAAAoAAAAA'
          'AAAAAAAAAAAAD0JAAAAAAA==',
      expirationLedger: 4294967295,
      contextRuleIds: <int>[0, 4294967295],
      signaturePayloadHex:
          'e863fa3a8043f9c431daba054084fbc9e9d354a8888c77e6caa99c534f2478ac',
      preimageV1DigestHex:
          'bfa781aac77973dab260e7c7ce6dabcd0108ad6d4bbf26e5546c69d44664139a',
      preimageV1ArgsXdrBase64:
          'AAAAEQAAAAEAAAADAAAADwAAAAdhY2NvdW50AAAAABIAAAABvkUg8H7m3ggRgNo/CI7G'
          'qXXawtX6Y8x9asE/hN0z8ocAAAAPAAAAEGNvbnRleHRfcnVsZV9pZHMAAAAQAAAAAQAA'
          'AAIAAAADAAAAAAAAAAP/////AAAADwAAABFzaWduYXR1cmVfcGF5bG9hZAAAAAAAAA0A'
          'AAAg6GP6OoBD+cQx2roFQIT7yenTVKiIjHfmyqmcU08keKw=',
      legacyDigestHex:
          '49fa0ba0f11444ae2aa0def52bd97cb9354d1f88bdda88998a23fb6a3487b22c',
      legacyArgsXdrBase64:
          'AAAADQAAACBJ+gug8RREriqg3vUr2Xy5NU0fiL3aiJmKI/tqNIeyLA==',
    ),
  ),
];

/// The fixture entry at signature expiration 0 with no rule ids, the lower
/// ends of both u32 inputs, computed as [bigNonceVectors].
const AuthDigestVector lowerBoundVector = AuthDigestVector(
  name: 'fixture entry, expiration 0, no rule ids',
  entryXdrBase64: _fixtureEntryXdrBase64,
  expirationLedger: 0,
  contextRuleIds: <int>[],
  signaturePayloadHex:
      '0a539c6c9c806ba7acb4cc1ec15c394eb19f0534b83d07bcac1fd02e07ccbc40',
  preimageV1DigestHex:
      '9825ae6de4aee956b4bf4d82ec3e517d103e381c44e887e5012a6cc6c05039b6',
  preimageV1ArgsXdrBase64:
      'AAAAEQAAAAEAAAADAAAADwAAAAdhY2NvdW50AAAAABIAAAABvkUg8H7m3ggRgNo/CI7GqXXa'
      'wtX6Y8x9asE/hN0z8ocAAAAPAAAAEGNvbnRleHRfcnVsZV9pZHMAAAAQAAAAAQAAAAAAAAAP'
      'AAAAEXNpZ25hdHVyZV9wYXlsb2FkAAAAAAAADQAAACAKU5xsnIBrp6y0zB7BXDlOsZ8FNLg9'
      'B7ysH9AuB8y8QA==',
  legacyDigestHex:
      '02eb544ea63464bb40fe7ce1438f1c1383e0202303fd598883594c522e4347ca',
  legacyArgsXdrBase64:
      'AAAADQAAACAC61ROpjRku0D+fOFDjxwTg+AgIwP9WYiDWUxSLkNHyg==',
);

/// The fixture entry with [arm] credentials and the [nonce] built as a
/// `BigInt`, signature expiration 0 and a Void signature.
XdrSorobanAuthorizationEntry vectorFromFixtureEntry(
  XdrSorobanCredentialsType arm,
  BigInt nonce,
) {
  final fixture = fixtureEntryVector.entry();
  final credentials = XdrSorobanAddressCredentials(
    fixture.credentials.addressV2!.address,
    XdrInt64(nonce),
    XdrUint32(0),
    XdrSCVal.forVoid(),
  );
  return XdrSorobanAuthorizationEntry(
    arm == XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS
        ? XdrSorobanCredentials.forAddressCredentials(credentials)
        : XdrSorobanCredentials.forAddressV2Credentials(credentials),
    fixture.rootInvocation,
  );
}

/// The XDR of [value], base64 encoded.
String scValXdrBase64(XdrSCVal value) {
  final stream = XdrDataOutputStream();
  XdrSCVal.encode(stream, value);
  return base64Encode(stream.bytes);
}

/// The two stellar-accounts auth digests built from their definitions with
/// raw XDR types and `package:crypto`, so a pipeline test compares the
/// digest a signer receives with a value the SDK's digest code did not
/// produce. The signature payload comes from the caller.
abstract final class IndependentAuthDigest {
  /// `AuthDigestPreimage` of stellar-accounts 0.8.0: a Map with the Symbol
  /// keys in name order.
  static XdrSCVal preimage(
    String account,
    Uint8List signaturePayload,
    List<int> contextRuleIds,
  ) {
    final map = XdrSCVal(XdrSCValType.SCV_MAP)
      ..map = <XdrSCMapEntry>[
        XdrSCMapEntry(
          XdrSCVal(XdrSCValType.SCV_SYMBOL)..sym = 'account',
          XdrSCVal(XdrSCValType.SCV_ADDRESS)
            ..address = XdrSCAddress.forContractId(account),
        ),
        XdrSCMapEntry(
          XdrSCVal(XdrSCValType.SCV_SYMBOL)..sym = 'context_rule_ids',
          _ruleIdsVec(contextRuleIds),
        ),
        XdrSCMapEntry(
          XdrSCVal(XdrSCValType.SCV_SYMBOL)..sym = 'signature_payload',
          XdrSCVal(XdrSCValType.SCV_BYTES)
            ..bytes = XdrSCBytes(signaturePayload),
        ),
      ];
    return map;
  }

  /// `SHA-256(XDR(AuthDigestPreimage))`, the stellar-accounts 0.8.0 digest.
  static Uint8List preimageDigest(
    String account,
    Uint8List signaturePayload,
    List<int> contextRuleIds,
  ) => _sha256(_xdr(preimage(account, signaturePayload, contextRuleIds)));

  /// `SHA-256(signature_payload ++ XDR(Vec<U32>))`, the stellar-accounts 0.7
  /// digest.
  static Uint8List legacyDigest(
    Uint8List signaturePayload,
    List<int> contextRuleIds,
  ) => _sha256(
    Uint8List.fromList(<int>[
      ...signaturePayload,
      ..._xdr(_ruleIdsVec(contextRuleIds)),
    ]),
  );

  static XdrSCVal _ruleIdsVec(List<int> contextRuleIds) =>
      XdrSCVal(XdrSCValType.SCV_VEC)
        ..vec = <XdrSCVal>[
          for (final id in contextRuleIds)
            XdrSCVal(XdrSCValType.SCV_U32)..u32 = XdrUint32(id),
        ];

  static Uint8List _xdr(XdrSCVal value) {
    final stream = XdrDataOutputStream();
    XdrSCVal.encode(stream, value);
    return Uint8List.fromList(stream.bytes);
  }

  static Uint8List _sha256(Uint8List bytes) =>
      Uint8List.fromList(crypto.sha256.convert(bytes).bytes);
}
