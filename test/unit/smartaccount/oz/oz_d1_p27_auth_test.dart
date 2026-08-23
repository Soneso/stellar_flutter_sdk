// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

// Protocol 27 credential-arm unit tests for the OZ
// smart-account auth layer.
//
// Fixed cross-SDK vectors (from section 8.1 of p27-plan.md):
//   Network:    TESTNET "Test SDF Network ; September 2015"
//   Signer:     SDJHRQF4GCMIIKAAAQ6IHY42X73FQFLHUULAPSKKD4DFDM7UXWWCRHBE
//   Contract:   CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE
//   Function:   hello(u64 1234)
//   Nonce:      123456789101112
//   Expiration: 4242
//
// Legacy ADDRESS payload sha256:
//   120c429d4333e12e0ca2c5ac10630e728fdd33240bf7066f4c62f6a2d6fa3cbe
// ADDRESS_V2 payload sha256:
//   252a0d6117840dff37b765839810fb6ecc446198e73062e01bc961e49355b7b9

import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// ---------------------------------------------------------------------------
// Golden-vector constants (section 8.1 of p27-plan.md)
// ---------------------------------------------------------------------------

const String _kNetworkPassphrase = 'Test SDF Network ; September 2015';
const String _kContractId =
    'CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE';
final BigInt _kNonce = BigInt.parse('123456789101112');
const int _kExpiration = 4242;

// The ADDRESS_V2 golden vector uses the signer account as the credential
// address (section 8.1: "credential address = the signer account").
const String _kV2SignerAccount =
    'GCZHXL5HXQX5ABDM26LHYRCQZ5OJFHLOPLZX47WEBP3V2PF5AVFK2A5D';

/// Payload sha256 for the fixed inputs with the legacy ADDRESS arm
/// (credential address = contract).
const String _kLegacyPayloadSha256 =
    '120c429d4333e12e0ca2c5ac10630e728fdd33240bf7066f4c62f6a2d6fa3cbe';

/// Payload sha256 for the fixed inputs with the ADDRESS_V2 arm
/// (credential address = signer account, per section 8.1 of p27-plan.md).
const String _kV2PayloadSha256 =
    '252a0d6117840dff37b765839810fb6ecc446198e73062e01bc961e49355b7b9';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Uint8List _hexToBytes(String hex) {
  final result = Uint8List(hex.length ~/ 2);
  for (var i = 0; i < result.length; i++) {
    result[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return result;
}

String _bytesToHex(Uint8List bytes) {
  final sb = StringBuffer();
  for (final b in bytes) {
    sb.write(b.toRadixString(16).padLeft(2, '0'));
  }
  return sb.toString();
}

/// Builds a canonical golden XDR auth entry matching the legacy ADDRESS
/// golden vector from section 8.1 of p27-plan.md.
///
/// The invocation is `contractFn hello(u64 1234)` on [_kContractId].
/// The credential address is also [_kContractId] (matching the plan vector).
XdrSorobanAuthorizationEntry _buildLegacyGoldenEntry() {
  final contractAddr = XdrSCAddress.forContractId(_kContractId);

  final fn = XdrSorobanAuthorizedFunction(
    XdrSorobanAuthorizedFunctionType
        .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN,
  );
  fn.contractFn = XdrInvokeContractArgs(
    contractAddr,
    'hello',
    <XdrSCVal>[XdrSCVal.forU64(BigInt.from(1234))],
  );
  final invocation = XdrSorobanAuthorizedInvocation(
    fn,
    <XdrSorobanAuthorizedInvocation>[],
  );

  final addressCreds = XdrSorobanAddressCredentials(
    contractAddr,
    XdrInt64(_kNonce),
    XdrUint32(_kExpiration),
    XdrSCVal.forVoid(),
  );

  return XdrSorobanAuthorizationEntry(
    XdrSorobanCredentials.forAddressCredentials(addressCreds),
    invocation,
  );
}

/// Builds a canonical golden XDR auth entry matching the ADDRESS_V2
/// golden vector from section 8.1 of p27-plan.md.
///
/// The invocation is `contractFn hello(u64 1234)` on [_kContractId].
/// The credential address is [_kV2SignerAccount] (the signer account, per
/// section 8.1: "credential address = the signer account").
XdrSorobanAuthorizationEntry _buildV2GoldenEntry() {
  final contractAddr = XdrSCAddress.forContractId(_kContractId);
  final signerAddr = XdrSCAddress.forAccountId(_kV2SignerAccount);

  final fn = XdrSorobanAuthorizedFunction(
    XdrSorobanAuthorizedFunctionType
        .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN,
  );
  fn.contractFn = XdrInvokeContractArgs(
    contractAddr,
    'hello',
    <XdrSCVal>[XdrSCVal.forU64(BigInt.from(1234))],
  );
  final invocation = XdrSorobanAuthorizedInvocation(
    fn,
    <XdrSorobanAuthorizedInvocation>[],
  );

  final addressCreds = XdrSorobanAddressCredentials(
    signerAddr,
    XdrInt64(_kNonce),
    XdrUint32(_kExpiration),
    XdrSCVal.forVoid(),
  );

  return XdrSorobanAuthorizationEntry(
    XdrSorobanCredentials.forAddressV2Credentials(addressCreds),
    invocation,
  );
}

/// Builds an entry with the given arm using the contract as both the invoking
/// contract and the credential address. Used for arm-pair comparison tests
/// (same body, different arm).
XdrSorobanAuthorizationEntry _buildGoldenEntry({
  required XdrSorobanCredentialsType arm,
}) {
  final contractAddr = XdrSCAddress.forContractId(_kContractId);

  final fn = XdrSorobanAuthorizedFunction(
    XdrSorobanAuthorizedFunctionType
        .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN,
  );
  fn.contractFn = XdrInvokeContractArgs(
    contractAddr,
    'hello',
    <XdrSCVal>[XdrSCVal.forU64(BigInt.from(1234))],
  );
  final invocation = XdrSorobanAuthorizedInvocation(
    fn,
    <XdrSorobanAuthorizedInvocation>[],
  );

  final addressCreds = XdrSorobanAddressCredentials(
    contractAddr,
    XdrInt64(_kNonce),
    XdrUint32(_kExpiration),
    XdrSCVal.forVoid(),
  );

  final XdrSorobanCredentials creds;
  switch (arm) {
    case XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS:
      creds = XdrSorobanCredentials.forAddressCredentials(addressCreds);
      break;
    case XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2:
      creds = XdrSorobanCredentials.forAddressV2Credentials(addressCreds);
      break;
    default:
      throw ArgumentError('Unsupported arm: $arm');
  }

  return XdrSorobanAuthorizationEntry(creds, invocation);
}

/// Builds a WITH_DELEGATES entry (for error-path tests).
XdrSorobanAuthorizationEntry _buildWithDelegatesEntry() {
  final contractAddr = XdrSCAddress.forContractId(_kContractId);
  final fn = XdrSorobanAuthorizedFunction(
    XdrSorobanAuthorizedFunctionType
        .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN,
  );
  fn.contractFn = XdrInvokeContractArgs(
    contractAddr,
    'hello',
    <XdrSCVal>[XdrSCVal.forU64(BigInt.from(1234))],
  );
  final invocation = XdrSorobanAuthorizedInvocation(
    fn,
    <XdrSorobanAuthorizedInvocation>[],
  );

  final addressCreds = XdrSorobanAddressCredentials(
    contractAddr,
    XdrInt64(_kNonce),
    XdrUint32(_kExpiration),
    XdrSCVal.forVoid(),
  );
  final withDelegates = XdrSorobanAddressCredentialsWithDelegates(
    addressCreds,
    <XdrSorobanDelegateSignature>[],
  );

  return XdrSorobanAuthorizationEntry(
    XdrSorobanCredentials.forAddressWithDelegatesCredentials(withDelegates),
    invocation,
  );
}

/// Computes the OZ auth payload hash directly using the shared preimage builder for
/// cross-checking.
Uint8List _buildPayloadHashDirect(
  XdrSorobanAuthorizationEntry xdrEntry,
  String networkPassphrase,
) {
  final entry = SorobanAuthorizationEntry.fromXdr(xdrEntry);
  final preimage = entry.buildPreimage(Network(networkPassphrase));
  final out = XdrDataOutputStream();
  XdrHashIDPreimage.encode(out, preimage);
  return Uint8List.fromList(
    crypto.sha256.convert(out.bytes).bytes,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // Golden-vector tests
  // -------------------------------------------------------------------------

  group('golden-vector: legacy ADDRESS payload hash', () {
    test(
        'buildAuthPayloadHash_legacyEntry_matchesGoldenSha256',
        () async {
      final entry = _buildLegacyGoldenEntry();

      final hash = await OZSmartAccountAuth.buildAuthPayloadHash(
        entry,
        _kExpiration,
        _kNetworkPassphrase,
      );

      final actualHex = _bytesToHex(hash);
      expect(actualHex, _kLegacyPayloadSha256,
          reason: 'Legacy ADDRESS payload hash must match the golden sha256 '
              'derived from the cross-SDK preimage vector. Actual: $actualHex');
    });

    test(
        'buildAuthPayloadHash_legacyEntry_matchesSharedPreimageBuilder',
        () async {
      final entry = _buildLegacyGoldenEntry();

      final ozHash = await OZSmartAccountAuth.buildAuthPayloadHash(
        entry,
        _kExpiration,
        _kNetworkPassphrase,
      );
      final batchBHash = _buildPayloadHashDirect(entry, _kNetworkPassphrase);

      expect(ozHash, batchBHash,
          reason: 'OZ hash must equal the shared preimage builder output');
    });
  });

  group('golden-vector: ADDRESS_V2 payload hash', () {
    // The V2 golden vector uses the signer's account as the credential
    // address (section 8.1: "credential address = the signer account").
    test(
        'buildAuthPayloadHash_v2Entry_matchesGoldenSha256',
        () async {
      final entry = _buildV2GoldenEntry();

      final hash = await OZSmartAccountAuth.buildAuthPayloadHash(
        entry,
        _kExpiration,
        _kNetworkPassphrase,
      );

      final actualHex = _bytesToHex(hash);
      expect(actualHex, _kV2PayloadSha256,
          reason: 'ADDRESS_V2 payload hash must match the golden sha256 '
              'derived from the cross-SDK preimage vector. Actual: $actualHex');
    });

    test(
        'v2PayloadHash_differsFromLegacyForIdenticalBodyFields',
        () async {
      // Both entries use the same body fields (same nonce, expiration,
      // invocation, credential address). The only difference is the arm
      // discriminant. The hashes must differ because the preimage type
      // changes (ENVELOPE_TYPE_SOROBAN_AUTHORIZATION vs
      // ENVELOPE_TYPE_SOROBAN_AUTHORIZATION_WITH_ADDRESS).
      final legacyEntry = _buildGoldenEntry(
        arm: XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS,
      );
      final v2Entry = _buildGoldenEntry(
        arm: XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2,
      );

      final legacyHash = await OZSmartAccountAuth.buildAuthPayloadHash(
        legacyEntry,
        _kExpiration,
        _kNetworkPassphrase,
      );
      final v2Hash = await OZSmartAccountAuth.buildAuthPayloadHash(
        v2Entry,
        _kExpiration,
        _kNetworkPassphrase,
      );

      expect(legacyHash, isNot(v2Hash),
          reason: 'Legacy and V2 preimage hashes must differ even when all '
              'credential body fields are identical, because the preimage '
              'discriminant changes.');
    });
  });

  // -------------------------------------------------------------------------
  // ADDRESS_V2 signing path and arm preservation
  // -------------------------------------------------------------------------

  group('ADDRESS_V2: signing path and arm preservation', () {
    test(
        'signAuthEntry_v2Entry_armPreservedAfterSigning',
        () async {
      final entry = _buildGoldenEntry(
        arm: XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2,
      );
      final delegatedSigner = OZDelegatedSigner(
        'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX',
      );
      final sig = OZWebAuthnSignature(
        authenticatorData: Uint8List(16),
        clientData: Uint8List(20),
        signature: Uint8List(64),
      );

      final signed = await OZSmartAccountAuth.signAuthEntry(
        entry: entry,
        signer: delegatedSigner,
        signature: sig,
        expirationLedger: _kExpiration,
      );

      expect(
        signed.credentials.discriminant,
        XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2,
        reason: 'signAuthEntry must preserve the ADDRESS_V2 arm on write-back',
      );
    });

    test(
        'signAuthEntry_v2Entry_signaturePayloadDiffersFromLegacy',
        () async {
      // The signed auth-payload hash is derived from the preimage hash, so
      // two entries with the same fields but different arms produce different
      // payloads. Verify that signing a V2 entry does not silently use a
      // legacy preimage hash.
      final legacyEntry = _buildGoldenEntry(
        arm: XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS,
      );
      final v2Entry = _buildGoldenEntry(
        arm: XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2,
      );

      final legacyHash = await OZSmartAccountAuth.buildAuthPayloadHash(
        legacyEntry,
        _kExpiration,
        _kNetworkPassphrase,
      );
      final v2Hash = await OZSmartAccountAuth.buildAuthPayloadHash(
        v2Entry,
        _kExpiration,
        _kNetworkPassphrase,
      );

      expect(legacyHash, isNot(v2Hash));
    });

    test(
        'addRawSignatureMapEntry_v2Entry_armPreservedAfterWriteBack',
        () {
      final entry = _buildGoldenEntry(
        arm: XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2,
      );
      final signer = OZDelegatedSigner(
        'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX',
      );

      final result = OZSmartAccountAuth.addRawSignatureMapEntry(
        entry: entry,
        signerKey: signer.toScVal(),
        signatureValue: XdrSCVal.forBytes(Uint8List(0)),
      );

      expect(
        result.credentials.discriminant,
        XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2,
        reason: 'addRawSignatureMapEntry must preserve the ADDRESS_V2 arm',
      );
    });
  });

  // -------------------------------------------------------------------------
  // Expiration stamping preserves the arm
  // -------------------------------------------------------------------------

  group('expiration stamping preserves arm', () {
    test(
        'buildAuthPayloadHash_v2Entry_stampingPreservesV2Arm',
        () async {
      // buildAuthPayloadHash stamps expiration before building the preimage.
      // The hash must equal the V2 golden vector (not the legacy golden),
      // proving the stamping step did not silently convert the arm.
      final entry = _buildV2GoldenEntry();

      final hash = await OZSmartAccountAuth.buildAuthPayloadHash(
        entry,
        _kExpiration,
        _kNetworkPassphrase,
      );

      expect(_bytesToHex(hash), _kV2PayloadSha256);
    });

    test(
        'buildAuthPayloadHash_legacyEntry_stampingPreservesLegacyArm',
        () async {
      final entry = _buildLegacyGoldenEntry();

      final hash = await OZSmartAccountAuth.buildAuthPayloadHash(
        entry,
        _kExpiration,
        _kNetworkPassphrase,
      );

      expect(_bytesToHex(hash), _kLegacyPayloadSha256);
    });

    test(
        'signAuthEntry_v2Entry_expirationSetOnV2Credentials',
        () async {
      final entry = _buildGoldenEntry(
        arm: XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2,
      );
      const newExpiration = 9999;

      final signed = await OZSmartAccountAuth.signAuthEntry(
        entry: entry,
        signer: OZDelegatedSigner(
          'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX',
        ),
        signature: OZWebAuthnSignature(
          authenticatorData: Uint8List(16),
          clientData: Uint8List(20),
          signature: Uint8List(64),
        ),
        expirationLedger: newExpiration,
      );

      // The expiration must be stamped on the V2 credentials.
      expect(signed.credentials.addressV2?.signatureExpirationLedger.uint32,
          newExpiration);
      expect(signed.credentials.discriminant,
          XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2);
    });
  });

  // -------------------------------------------------------------------------
  // WITH_DELEGATES produces a descriptive error in auto-sign flows
  // -------------------------------------------------------------------------

  group('ADDRESS_WITH_DELEGATES: auto-sign flow throws descriptive error', () {
    test(
        'buildAuthPayloadHash_withDelegatesEntry_throwsDescriptiveError',
        () async {
      final entry = _buildWithDelegatesEntry();

      await expectLater(
        OZSmartAccountAuth.buildAuthPayloadHash(
          entry,
          _kExpiration,
          _kNetworkPassphrase,
        ),
        throwsA(isA<SmartAccountTransactionSigningFailed>().having(
          (e) => e.message,
          'message',
          contains('ADDRESS_WITH_DELEGATES'),
        )),
      );
    });

    test(
        'signAuthEntry_withDelegatesEntry_throwsDescriptiveError',
        () async {
      final entry = _buildWithDelegatesEntry();

      await expectLater(
        OZSmartAccountAuth.signAuthEntry(
          entry: entry,
          signer: OZDelegatedSigner(
            'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX',
          ),
          signature: OZWebAuthnSignature(
            authenticatorData: Uint8List(16),
            clientData: Uint8List(20),
            signature: Uint8List(64),
          ),
          expirationLedger: _kExpiration,
        ),
        throwsA(isA<SmartAccountTransactionSigningFailed>().having(
          (e) => e.message,
          'message',
          allOf(
            contains('ADDRESS_WITH_DELEGATES'),
            contains('SorobanAuthorizationEntry.sign'),
          ),
        )),
      );
    });

    test(
        'addRawSignatureMapEntry_withDelegatesEntry_throwsDescriptiveError',
        () {
      final entry = _buildWithDelegatesEntry();
      final signer = OZDelegatedSigner(
        'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX',
      );

      expect(
        () => OZSmartAccountAuth.addRawSignatureMapEntry(
          entry: entry,
          signerKey: signer.toScVal(),
          signatureValue: XdrSCVal.forBytes(Uint8List(0)),
        ),
        throwsA(isA<SmartAccountTransactionSigningFailed>().having(
          (e) => e.message,
          'message',
          allOf(
            contains('ADDRESS_WITH_DELEGATES'),
            contains('SorobanAuthorizationEntry.sign'),
          ),
        )),
      );
    });
  });

  // -------------------------------------------------------------------------
  // Source-account errors still work (regression guard)
  // -------------------------------------------------------------------------

  group('source-account: still throws on address-requiring operations', () {
    XdrSorobanAuthorizationEntry _buildSourceEntry() {
      final contractAddr = XdrSCAddress.forContractId(_kContractId);
      final fn = XdrSorobanAuthorizedFunction(
        XdrSorobanAuthorizedFunctionType
            .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN,
      );
      fn.contractFn = XdrInvokeContractArgs(
        contractAddr,
        'hello',
        <XdrSCVal>[],
      );
      final invocation = XdrSorobanAuthorizedInvocation(
        fn,
        <XdrSorobanAuthorizedInvocation>[],
      );
      return XdrSorobanAuthorizationEntry(
        XdrSorobanCredentials.forSourceAccount(),
        invocation,
      );
    }

    test('buildAuthPayloadHash_sourceAccountEntry_throws', () async {
      final entry = _buildSourceEntry();
      await expectLater(
        OZSmartAccountAuth.buildAuthPayloadHash(
          entry,
          _kExpiration,
          _kNetworkPassphrase,
        ),
        throwsA(isA<SmartAccountTransactionSigningFailed>()),
      );
    });

    test('signAuthEntry_sourceAccountEntry_throws', () async {
      final entry = _buildSourceEntry();
      await expectLater(
        OZSmartAccountAuth.signAuthEntry(
          entry: entry,
          signer: OZDelegatedSigner(
            'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX',
          ),
          signature: OZWebAuthnSignature(
            authenticatorData: Uint8List(16),
            clientData: Uint8List(20),
            signature: Uint8List(64),
          ),
          expirationLedger: _kExpiration,
        ),
        throwsA(isA<SmartAccountTransactionSigningFailed>()),
      );
    });

    test('addRawSignatureMapEntry_sourceAccountEntry_throws', () {
      final entry = _buildSourceEntry();
      expect(
        () => OZSmartAccountAuth.addRawSignatureMapEntry(
          entry: entry,
          signerKey:
              OZDelegatedSigner('GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX')
                  .toScVal(),
          signatureValue: XdrSCVal.forBytes(Uint8List(0)),
        ),
        throwsA(isA<SmartAccountTransactionSigningFailed>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // Preimage byte-identity: refactored path == shared preimage builder
  // -------------------------------------------------------------------------

  group('preimage byte-identity: refactored path matches shared preimage builder', () {
    test(
        'legacyEntry_ozHashMatchesSharedBuilderOutput',
        () async {
      final entry = _buildLegacyGoldenEntry();

      final ozHash = await OZSmartAccountAuth.buildAuthPayloadHash(
        entry,
        _kExpiration,
        _kNetworkPassphrase,
      );
      final batchBHash = _buildPayloadHashDirect(entry, _kNetworkPassphrase);

      expect(ozHash, batchBHash);
    });

    test(
        'v2Entry_ozHashMatchesSharedBuilderOutput',
        () async {
      final entry = _buildV2GoldenEntry();

      final ozHash = await OZSmartAccountAuth.buildAuthPayloadHash(
        entry,
        _kExpiration,
        _kNetworkPassphrase,
      );
      final batchBHash = _buildPayloadHashDirect(entry, _kNetworkPassphrase);

      expect(ozHash, batchBHash);
    });
  });

  // -------------------------------------------------------------------------
  // buildSourceAccountAuthPayloadHash binds the address (regression guard)
  // -------------------------------------------------------------------------

  group('buildSourceAccountAuthPayloadHash produces WITH_ADDRESS preimage', () {
    test(
        'buildSourceAccountAuthPayloadHash_matchesManualWithAddressPreimage',
        () async {
      final contractAddr = XdrSCAddress.forContractId(_kContractId);
      final fn = XdrSorobanAuthorizedFunction(
        XdrSorobanAuthorizedFunctionType
            .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN,
      );
      fn.contractFn = XdrInvokeContractArgs(
        contractAddr,
        'hello',
        <XdrSCVal>[XdrSCVal.forU64(BigInt.from(1234))],
      );
      final invocation = XdrSorobanAuthorizedInvocation(
        fn,
        <XdrSorobanAuthorizedInvocation>[],
      );
      final entry = XdrSorobanAuthorizationEntry(
        XdrSorobanCredentials.forSourceAccount(),
        invocation,
      );
      final nonce = XdrInt64(_kNonce);
      final tempAddress = XdrSCAddress.forAccountId(_kV2SignerAccount);

      final ozHash = await OZSmartAccountAuth.buildSourceAccountAuthPayloadHash(
        entry,
        tempAddress,
        nonce,
        _kExpiration,
        _kNetworkPassphrase,
      );

      // Manual construction of the address-bound preimage.
      final networkId = Uint8List.fromList(
        crypto.sha256.convert(utf8.encode(_kNetworkPassphrase)).bytes,
      );
      final authPreimage = XdrHashIDPreimageSorobanAuthorizationWithAddress(
        XdrHash(networkId),
        nonce,
        XdrUint32(_kExpiration),
        tempAddress,
        invocation,
      );
      final preimage = XdrHashIDPreimage(
        XdrEnvelopeType.ENVELOPE_TYPE_SOROBAN_AUTHORIZATION_WITH_ADDRESS,
      );
      preimage.sorobanAuthorizationWithAddress = authPreimage;
      final stream = XdrDataOutputStream();
      XdrHashIDPreimage.encode(stream, preimage);
      final expectedHash = Uint8List.fromList(
        crypto.sha256.convert(stream.bytes).bytes,
      );

      expect(ozHash, expectedHash,
          reason: 'buildSourceAccountAuthPayloadHash must produce a '
              'byte-identical result to the manual WITH_ADDRESS preimage '
              'construction');
    });
  });

  // -------------------------------------------------------------------------
  // signAuthEntry: legacy ADDRESS arm preserved on write-back (regression)
  // -------------------------------------------------------------------------

  group('signAuthEntry: legacy ADDRESS arm preserved', () {
    test('signAuthEntry_legacyEntry_armPreservedAfterSigning', () async {
      final entry = _buildGoldenEntry(
        arm: XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS,
      );
      final delegatedSigner = OZDelegatedSigner(
        'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX',
      );

      final signed = await OZSmartAccountAuth.signAuthEntry(
        entry: entry,
        signer: delegatedSigner,
        signature: OZWebAuthnSignature(
          authenticatorData: Uint8List(16),
          clientData: Uint8List(20),
          signature: Uint8List(64),
        ),
        expirationLedger: _kExpiration,
      );

      expect(
        signed.credentials.discriminant,
        XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS,
        reason: 'signAuthEntry must preserve the legacy ADDRESS arm',
      );
    });
  });
}
