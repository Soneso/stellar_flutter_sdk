// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/src/smartaccount/oz/oz_auth_digest_scheme.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import 'oz_auth_digest_fixtures.dart';

// The two auth digest schemes of OpenZeppelin smart accounts against
// `auth_digest_cross_sdk_fixture.json`, the file the KMP SDK carries
// byte-identical. Its preimage vectors are the smart-account-kit vectors,
// generated with `AuthDigestPreimage { .. }.to_xdr()` and `.digest()` from
// OpenZeppelin/stellar-contracts@6eb047d5, and the digest the `auth_digest`
// view of a 0.8.0 wallet on testnet returned. Its entry values were computed
// outside the SDK with the Stellar CLI `stellar xdr encode`, SHA-256 and an
// Ed25519 library, with one signature over each digest by the fixture key of
// `ed25519_cross_sdk_fixture.json`.

const String _fixturePath = 'test/fixtures/auth_digest_cross_sdk_fixture.json';

const String _kitAccount =
    'CC7EKIHQP3TN4CARQDND6CEOY2UXLWWC2X5GHTD5NLAT7BG5GPZIOM3F';

String _xdrHex(XdrSCVal value) {
  final stream = XdrDataOutputStream();
  XdrSCVal.encode(stream, value);
  return Util.bytesToHex(Uint8List.fromList(stream.bytes));
}

List<int> _ruleIds(Object? json) =>
    (json as List<dynamic>).map((id) => id as int).toList(growable: false);

void main() {
  // Read synchronously so a missing fixture fails every test.
  final fixture =
      jsonDecode(File(_fixturePath).readAsStringSync()) as Map<String, dynamic>;
  final entryFixture = fixture['entry'] as Map<String, dynamic>;
  final preimageV1 = entryFixture['preimageV1'] as Map<String, dynamic>;
  final legacyConcat = entryFixture['legacyConcat'] as Map<String, dynamic>;

  /// The fixture key's signature over [digest] verifies, so [digest] is the
  /// digest the fixture signed.
  void expectFixtureSignature(Map<String, dynamic> scheme, Uint8List digest) {
    final publicKey = KeyPair.fromPublicKey(
      Util.hexToBytes(entryFixture['ed25519PublicKeyHex'] as String),
    );
    expect(
      publicKey.verify(
        digest,
        Util.hexToBytes(scheme['ed25519SignatureHex'] as String),
      ),
      isTrue,
      reason:
          'The fixture signature must verify over ${Util.bytesToHex(digest)}',
    );
  }

  group('ozBuildAuthDigestPreimage', () {
    test('the fixture vectors match the contract encoding and digest', () {
      final vectors = (fixture['preimageVectors'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      expect(
        vectors,
        hasLength(4),
        reason: 'Three kit vectors and the live auth_digest reading',
      );
      for (final vector in vectors) {
        final preimage = ozBuildAuthDigestPreimage(
          XdrSCAddress.forContractId(vector['account'] as String),
          Util.hexToBytes(vector['signaturePayloadHex'] as String),
          _ruleIds(vector['contextRuleIds']),
        );
        final preimageHex = _xdrHex(preimage);
        expect(
          preimageHex,
          vector['preimageXdrHex'],
          reason: 'Preimage XDR for ${vector['name']}',
        );
        expect(
          crypto.sha256.convert(Util.hexToBytes(preimageHex)).toString(),
          vector['authDigestHex'],
          reason: 'Preimage digest for ${vector['name']}',
        );
      }
    });

    test('a payload that is not 32 bytes is refused', () {
      for (final size in <int>[0, 31, 33]) {
        expect(
          () => ozBuildAuthDigestPreimage(
            XdrSCAddress.forContractId(_kitAccount),
            Uint8List(size),
            const <int>[0],
          ),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              'Signature payload must be 32 bytes, got $size',
            ),
          ),
        );
      }
    });
  });

  group('computeEntryAuthDigest against the entry fixture', () {
    test('the shared vector holds the fixture entry values', () {
      expect(fixtureEntryVector.entryXdrBase64, entryFixture['entryXdrBase64']);
      expect(vectorNetworkPassphrase, entryFixture['networkPassphrase']);
      expect(
        fixtureEntryVector.expirationLedger,
        entryFixture['signatureExpirationLedger'],
      );
      expect(
        fixtureEntryVector.contextRuleIds,
        _ruleIds(entryFixture['contextRuleIds']),
      );
      expect(
        fixtureEntryVector.signaturePayloadHex,
        entryFixture['signaturePayloadHex'],
      );
      expect(
        fixtureEntryVector.preimageV1DigestHex,
        preimageV1['authDigestHex'],
      );
      expect(<String>[
        fixtureEntryVector.preimageV1ArgsXdrBase64,
      ], preimageV1['delegatedAuthArgsXdrBase64']);
      expect(fixtureEntryVector.legacyDigestHex, legacyConcat['authDigestHex']);
      expect(<String>[
        fixtureEntryVector.legacyArgsXdrBase64,
      ], legacyConcat['delegatedAuthArgsXdrBase64']);
    });

    for (final scheme in OZAuthDigestScheme.values) {
      test('the fixture key signed the ${scheme.name} digest', () async {
        final digest = await OZSmartAccountAuth.computeEntryAuthDigest(
          fixtureEntryVector.entry(),
          fixtureEntryVector.expirationLedger,
          vectorNetworkPassphrase,
          fixtureEntryVector.contextRuleIds,
          scheme,
        );
        expectFixtureSignature(
          scheme == OZAuthDigestScheme.preimageV1 ? preimageV1 : legacyConcat,
          digest.authDigest,
        );
      });
    }

    test('the preimage binds the credential address', () async {
      const otherAccount =
          'CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC';
      final entry = fixtureEntryVector.entry();
      final credentials = entry.credentials.addressV2!;
      final otherEntry = XdrSorobanAuthorizationEntry(
        XdrSorobanCredentials.forAddressCredentials(
          XdrSorobanAddressCredentials(
            XdrSCAddress.forContractId(otherAccount),
            credentials.nonce,
            credentials.signatureExpirationLedger,
            credentials.signature,
          ),
        ),
        entry.rootInvocation,
      );

      final digest = await OZSmartAccountAuth.computeEntryAuthDigest(
        otherEntry,
        fixtureEntryVector.expirationLedger,
        vectorNetworkPassphrase,
        fixtureEntryVector.contextRuleIds,
        OZAuthDigestScheme.preimageV1,
      );

      final expectedPreimage = IndependentAuthDigest.preimage(
        otherAccount,
        digest.signaturePayload,
        fixtureEntryVector.contextRuleIds,
      );
      expect(digest.delegatedAuthArgs.map(_xdrHex).toList(), <String>[
        _xdrHex(expectedPreimage),
      ]);
      expect(
        digest.authDigest,
        IndependentAuthDigest.preimageDigest(
          otherAccount,
          digest.signaturePayload,
          fixtureEntryVector.contextRuleIds,
        ),
      );
      expect(
        Util.bytesToHex(digest.authDigest),
        isNot(fixtureEntryVector.preimageV1DigestHex),
      );
    });

    test('source-account and delegate-tree credentials are refused', () async {
      final entry = fixtureEntryVector.entry();
      final withDelegates =
          XdrSorobanCredentials(
              XdrSorobanCredentialsType
                  .SOROBAN_CREDENTIALS_ADDRESS_WITH_DELEGATES,
            )
            ..addressWithDelegates = XdrSorobanAddressCredentialsWithDelegates(
              entry.credentials.addressV2!,
              <XdrSorobanDelegateSignature>[],
            );
      for (final credentials in <XdrSorobanCredentials>[
        XdrSorobanCredentials.forSourceAccount(),
        withDelegates,
      ]) {
        for (final scheme in OZAuthDigestScheme.values) {
          await expectLater(
            OZSmartAccountAuth.computeEntryAuthDigest(
              XdrSorobanAuthorizationEntry(credentials, entry.rootInvocation),
              fixtureEntryVector.expirationLedger,
              vectorNetworkPassphrase,
              fixtureEntryVector.contextRuleIds,
              scheme,
            ),
            throwsA(isA<SmartAccountTransactionSigningFailed>()),
          );
        }
      }
    });

    test(
      'the deprecated buildAuthDigest still returns the 0.7 digest',
      () async {
        final digest = await OZSmartAccountAuth.buildAuthDigest(
          Util.hexToBytes(fixtureEntryVector.signaturePayloadHex),
          fixtureEntryVector.contextRuleIds,
        );
        expect(Util.bytesToHex(digest), fixtureEntryVector.legacyDigestHex);
      },
    );
  });
}
