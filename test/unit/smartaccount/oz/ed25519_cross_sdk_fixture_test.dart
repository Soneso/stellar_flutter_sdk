// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Path to the shared fixture, resolved relative to the SDK package root
// (tests run with the package root as the working directory).
const String _fixturePath = 'test/fixtures/ed25519_cross_sdk_fixture.json';

void main() {
  group('ed25519_cross_sdk_fixture', () {
    late List<dynamic> fixtureRows;

    setUpAll(() async {
      final file = File(_fixturePath);
      if (!file.existsSync()) {
        fixtureRows = const <dynamic>[];
        return;
      }
      final content = await file.readAsString();
      fixtureRows = jsonDecode(content) as List<dynamic>;
    });

    void _skipIfFixtureMissing() {
      if (fixtureRows.isEmpty) {
        markTestSkipped(
          'Shared Ed25519 auth-digest fixture not found at $_fixturePath. '
          'Run from the SDK package root or restore the file.',
        );
      }
    }

    test('test_crossSdkFixture_row0_producesByteIdenticalOutputs', () async {
      _skipIfFixtureMissing();
      if (fixtureRows.isEmpty) return;
      final row = fixtureRows[0] as Map<String, dynamic>;
      final keypair = _keypairFromRow(row);
      await _assertRow(row, 0, keypair);
    });

    test('test_crossSdkFixture_row1_producesByteIdenticalOutputs', () async {
      _skipIfFixtureMissing();
      if (fixtureRows.isEmpty) return;
      final row = fixtureRows[1] as Map<String, dynamic>;
      final keypair = _keypairFromRow(row);
      await _assertRow(row, 1, keypair);
    });

    test('test_crossSdkFixture_row2_producesByteIdenticalOutputs', () async {
      _skipIfFixtureMissing();
      if (fixtureRows.isEmpty) return;
      final row = fixtureRows[2] as Map<String, dynamic>;
      final keypair = _keypairFromRow(row);
      await _assertRow(row, 2, keypair);
    });
  });
}

// ---------------------------------------------------------------------------
// Per-row keypair derivation
// ---------------------------------------------------------------------------

/// Derives the signing [KeyPair] from the `signerInfo.secretKeyHex` field of
/// a fixture row. Each row carries its own 32-byte raw seed encoded as hex so
/// the test is fully self-contained and future-proof for fixtures that use
/// different seeds across rows.
KeyPair _keypairFromRow(Map<String, dynamic> row) {
  final signerInfo = row['signerInfo'] as Map<String, dynamic>;
  final secretKeyHex = signerInfo['secretKeyHex'] as String;
  final rawSeed = Uint8List.fromList(hex.decode(secretKeyHex));
  return KeyPair.fromSecretSeedList(rawSeed);
}

// ---------------------------------------------------------------------------
// Core assertion
// ---------------------------------------------------------------------------

Future<void> _assertRow(
  Map<String, dynamic> row,
  int rowIndex,
  KeyPair keypair,
) async {
  final inputs = row['inputs'] as Map<String, dynamic>;
  final outputs = row['outputs'] as Map<String, dynamic>;
  final signerInfo = row['signerInfo'] as Map<String, dynamic>;

  final networkPassphrase = inputs['networkPassphrase'] as String;
  final nonce = inputs['nonce'] as int;
  final signatureExpirationLedger = inputs['signatureExpirationLedger'] as int;
  final invocationXdrBase64 = inputs['invocationXdrBase64'] as String;
  final contextRuleIds = (inputs['contextRuleIds'] as List<dynamic>)
      .map((v) => v as int)
      .toList(growable: false);

  final expectedPreimageB64 = outputs['authPreimageXdrBase64'] as String;
  final expectedDigestHex = outputs['authDigestSha256Hex'] as String;
  final expectedPayloadB64 = outputs['authPayloadSignatureScvalXdrBase64'] as String;

  final publicKeyHex = signerInfo['publicKeyHex'] as String;

  // Row 2 uses verifierAddressB; rows 0-1 use verifierAddress.
  final verifierAddress =
      (signerInfo['verifierAddressB'] as String?) ??
      (signerInfo['verifierAddress'] as String?) ??
      (signerInfo['verifierAddressA'] as String);

  // Confirm the keypair's public key matches the fixture's publicKeyHex.
  final expectedPkBytes = Uint8List.fromList(hex.decode(publicKeyHex));
  final actualPkBytes = Uint8List.fromList(keypair.publicKey);
  expect(
    hex.encode(actualPkBytes),
    equals(publicKeyHex),
    reason: 'Row $rowIndex: keypair public key must match fixture publicKeyHex',
  );

  // Decode the invocation from XDR.
  final invocationBytes = base64Decode(invocationXdrBase64);
  final invocation = XdrSorobanAuthorizedInvocation.decode(
    XdrDataInputStream(invocationBytes),
  );

  // Build the auth preimage: the same computation the production pipeline
  // performs when constructing the hash for the authorization entry.
  final networkId = Uint8List.fromList(
    crypto.sha256.convert(utf8.encode(networkPassphrase)).bytes,
  );

  final authPreimage = XdrHashIDPreimageSorobanAuthorization(
    XdrHash(networkId),
    XdrInt64(BigInt.from(nonce)),
    XdrUint32(signatureExpirationLedger),
    invocation,
  );
  final preimageWrapper =
      XdrHashIDPreimage(XdrEnvelopeType.ENVELOPE_TYPE_SOROBAN_AUTHORIZATION)
        ..sorobanAuthorization = authPreimage;

  final preimageStream = XdrDataOutputStream();
  XdrHashIDPreimage.encode(preimageStream, preimageWrapper);
  final preimageBytes = Uint8List.fromList(preimageStream.bytes);
  final preimageB64 = base64Encode(preimageBytes);

  // Compute the auth digest:
  //   signaturePayload = SHA-256(preimageBytes)
  //   authDigest       = SHA-256(signaturePayload || contextRuleIds.toXDR())
  final signaturePayload =
      Uint8List.fromList(crypto.sha256.convert(preimageBytes).bytes);
  final authDigest = await OZSmartAccountAuth.buildAuthDigest(
    signaturePayload,
    contextRuleIds,
  );
  final authDigestHex = hex.encode(authDigest);

  // Sign the auth digest with the fixture keypair and wrap in the Ed25519
  // auth-payload map shape.
  final rawSignature = Uint8List.fromList(keypair.sign(authDigest));
  final ed25519Sig = OZEd25519Signature(
    publicKey: expectedPkBytes,
    signature: rawSignature,
  );
  final ed25519Signer = OZExternalSigner.ed25519(
    verifierAddress: verifierAddress,
    publicKey: expectedPkBytes,
  );

  // Build a minimal auth entry with address credentials and sign it.
  final addrXdr = XdrSCAddress.forContractId(verifierAddress);
  final cred = XdrSorobanAddressCredentials(
    addrXdr,
    XdrInt64(BigInt.from(nonce)),
    XdrUint32(signatureExpirationLedger),
    XdrSCVal.forVoid(),
  );
  final credsWrapper = XdrSorobanCredentials.forAddressCredentials(cred);
  final baseEntry = XdrSorobanAuthorizationEntry(credsWrapper, invocation);

  final signedEntry = await OZSmartAccountAuth.signAuthEntry(
    entry: baseEntry,
    signer: ed25519Signer,
    signature: ed25519Sig,
    expirationLedger: signatureExpirationLedger,
    contextRuleIds: contextRuleIds,
  );

  // Extract the payload ScVal and XDR-encode it.
  final signedCreds = signedEntry.credentials.address!;
  final payloadScVal = signedCreds.signature;

  final payloadStream = XdrDataOutputStream();
  XdrSCVal.encode(payloadStream, payloadScVal);
  final payloadB64 = base64Encode(payloadStream.bytes);

  // --- Assertions with byte-level diff messages ---

  expect(
    preimageB64,
    equals(expectedPreimageB64),
    reason: 'Row $rowIndex: authPreimageXdrBase64 mismatch.\n'
        '  Flutter : $preimageB64\n'
        '  Fixture : $expectedPreimageB64',
  );

  expect(
    authDigestHex,
    equals(expectedDigestHex),
    reason: 'Row $rowIndex: authDigestSha256Hex mismatch.\n'
        '  Flutter : $authDigestHex\n'
        '  Fixture : $expectedDigestHex',
  );

  expect(
    payloadB64,
    equals(expectedPayloadB64),
    reason: 'Row $rowIndex: authPayloadSignatureScvalXdrBase64 mismatch.\n'
        '  Flutter : $payloadB64\n'
        '  Fixture : $expectedPayloadB64',
  );
}
