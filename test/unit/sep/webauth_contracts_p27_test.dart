// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

// Tests for Protocol 27 credential-arm support in WebAuthForContracts.
//
// Covers:
// - _verifyServerSignature accepts ADDRESS, ADDRESS_V2, and ADDRESS_WITH_DELEGATES
//   entries, using the arm-correct preimage for each.
// - An ADDRESS_V2 entry signed over the wrong (legacy) preimage fails verification.
// - Legacy ADDRESS preimage produces a byte-identical hash to the cross-SDK golden
//   constant captured from the iOS implementation.
// - signAuthorizationEntries preserves the credential arm when stamping expiration.
// - Source-account credentials are passed through (not matched as a signing target)
//   and never cause an error in the sign flow.
// - validateChallenge recognises ADDRESS_V2 and ADDRESS_WITH_DELEGATES entries.

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// ============================================================================
// Cross-SDK golden constants (section 8.1 of p27-plan.md)
// Fixed inputs: TESTNET, signer seed SDJHRQF4GCMIIKAAAQ6IHY42X73FQFLHUULAPSKKD4DFDM7UXWWCRHBE,
// contract CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE,
// fn hello(u64 1234), nonce 123456789101112, signatureExpirationLedger 4242.
// ============================================================================

const _goldenSignerSeed =
    'SDJHRQF4GCMIIKAAAQ6IHY42X73FQFLHUULAPSKKD4DFDM7UXWWCRHBE';
const _goldenSignerAccount =
    'GCZHXL5HXQX5ABDM26LHYRCQZ5OJFHLOPLZX47WEBP3V2PF5AVFK2A5D';
const _goldenContract =
    'CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE';
const _goldenNonce = 123456789101112;
const _goldenExpiration = 4242;

// SHA-256 of the legacy ADDRESS (ENVELOPE_TYPE_SOROBAN_AUTHORIZATION) preimage.
const _goldenLegacyPayloadHex =
    '120c429d4333e12e0ca2c5ac10630e728fdd33240bf7066f4c62f6a2d6fa3cbe';

// SHA-256 of the ADDRESS_V2 (ENVELOPE_TYPE_SOROBAN_AUTHORIZATION_WITH_ADDRESS) preimage.
const _goldenV2PayloadHex =
    '252a0d6117840dff37b765839810fb6ecc446198e73062e01bc961e49355b7b9';

// Ed25519 signature produced by the fixed seed over the legacy payload.
const _goldenLegacySigHex =
    '3c69ceefc532f97e1d0e0eb9f204c9aa85cb2b68cf293bce832590b01455e060'
    'e89900ea3ba2c45257908769a1a71f25b6d3befbadffd220f896dc0058699008';

// ============================================================================
// Helpers
// ============================================================================

/// Converts a hex string to Uint8List.
Uint8List _hexDecode(String hex) {
  final result = Uint8List(hex.length ~/ 2);
  for (var i = 0; i < result.length; i++) {
    result[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return result;
}

/// Builds a web_auth_verify args map SCVal for use in test auth entries.
XdrSCVal _buildArgsMap({
  required String account,
  required String homeDomain,
  required String webAuthDomain,
  required String webAuthDomainAccount,
  required String nonce,
}) {
  XdrSCMapEntry makeEntry(String key, String value) => XdrSCMapEntry(
        XdrSCVal.forSymbol(key),
        XdrSCVal.forString(value),
      );

  return XdrSCVal.forMap([
    makeEntry('account', account),
    makeEntry('home_domain', homeDomain),
    makeEntry('nonce', nonce),
    makeEntry('web_auth_domain', webAuthDomain),
    makeEntry('web_auth_domain_account', webAuthDomainAccount),
  ]);
}

/// Builds a minimal SorobanAuthorizationEntry with web_auth_verify invocation
/// and no sub-invocations, using the provided credentials.
SorobanAuthorizationEntry _buildWebAuthEntry({
  required SorobanCredentials credentials,
  required String webAuthContractId,
  required XdrSCVal argsMap,
}) {
  final contractAddr = Address.forContractId(webAuthContractId);
  final function = SorobanAuthorizedFunction.forContractFunction(
    contractAddr,
    'web_auth_verify',
    [argsMap],
  );
  final invocation = SorobanAuthorizedInvocation(function);
  return SorobanAuthorizationEntry(credentials, invocation);
}

/// Returns the SHA-256 payload for [entry] encoded as a hex string.
String _computePayloadHex(SorobanAuthorizationEntry entry, Network network) {
  final preimage = entry.buildPreimage(network);
  final out = XdrDataOutputStream();
  XdrHashIDPreimage.encode(out, preimage);
  final hash = Util.hash(Uint8List.fromList(out.bytes));
  return hash.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

/// Builds a fully-signed server entry using [serverKeyPair], for the given
/// credential arm and contract/args. Stamps expiration before signing.
SorobanAuthorizationEntry _buildSignedServerEntry({
  required KeyPair serverKeyPair,
  required SorobanCredentials credentials,
  required String webAuthContractId,
  required XdrSCVal argsMap,
  required Network network,
  required int signatureExpirationLedger,
}) {
  // Stamp expiration on the inner credentials before building the preimage.
  final inner = credentials.innerAddressCredentials!;
  inner.signatureExpirationLedger = signatureExpirationLedger;

  final entry = _buildWebAuthEntry(
    credentials: credentials,
    webAuthContractId: webAuthContractId,
    argsMap: argsMap,
  );
  entry.sign(serverKeyPair, network);
  return entry;
}

// ============================================================================
// Test constants shared across groups
// ============================================================================

const _webAuthContractId =
    'CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE';
const _authEndpoint = 'https://testanchor.stellar.org/auth';
const _homeDomain = 'testanchor.stellar.org';
const _webAuthDomain = 'testanchor.stellar.org';
// Contract address used as the "client" account in tests.
// Stored as strkey; passed through the XDR round-trip where needed so that
// the Address object holds a hex contractId (as it would in a real decode).
const _clientAccountId =
    'CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM';

/// Returns an [Address] for a contract strkey whose [contractId] field stores
/// the hex representation (matching the XDR-decode path used in production).
Address _contractAddress(String strkey) =>
    Address.fromXdr(XdrSCAddress.forContractId(strkey));
const _nonce = '42';

// ============================================================================

void main() {
  // ---------------------------------------------------------------------------
  // Golden-vector tests
  // ---------------------------------------------------------------------------
  group('WebAuthForContracts - golden payload vectors', () {
    test('legacy ADDRESS preimage produces golden SHA-256 payload', () {
      final signer = KeyPair.fromSecretSeed(_goldenSignerSeed);
      final address = Address.forAccountId(_goldenSignerAccount);
      final innerCreds = SorobanAddressCredentials(
        address,
        BigInt.from(_goldenNonce),
        _goldenExpiration,
        XdrSCVal.forVoid(),
      );
      final credentials = SorobanCredentials(addressCredentials: innerCreds);

      final contractAddr = Address.forContractId(_goldenContract);
      final invocation = SorobanAuthorizedInvocation(
        SorobanAuthorizedFunction.forContractFunction(
          contractAddr,
          'hello',
          [XdrSCVal.forU64(BigInt.from(1234))],
        ),
      );
      final entry =
          SorobanAuthorizationEntry(credentials, invocation);

      final payloadHex = _computePayloadHex(entry, Network.TESTNET);
      expect(payloadHex, equals(_goldenLegacyPayloadHex));

      // Also verify the ed25519 signature matches the golden constant.
      final payloadBytes = _hexDecode(payloadHex);
      final sigBytes = signer.sign(payloadBytes);
      expect(
        sigBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
        equals(_goldenLegacySigHex),
      );
    });

    test('ADDRESS_V2 preimage produces golden SHA-256 payload', () {
      final address = Address.forAccountId(_goldenSignerAccount);
      final innerCreds = SorobanAddressCredentials(
        address,
        BigInt.from(_goldenNonce),
        _goldenExpiration,
        XdrSCVal.forVoid(),
      );
      final credentials = SorobanCredentials.forAddressV2(innerCreds);

      final contractAddr = Address.forContractId(_goldenContract);
      final invocation = SorobanAuthorizedInvocation(
        SorobanAuthorizedFunction.forContractFunction(
          contractAddr,
          'hello',
          [XdrSCVal.forU64(BigInt.from(1234))],
        ),
      );
      final entry = SorobanAuthorizationEntry(credentials, invocation);

      final payloadHex = _computePayloadHex(entry, Network.TESTNET);
      expect(payloadHex, equals(_goldenV2PayloadHex));
    });

    test('ADDRESS and ADDRESS_V2 preimages differ for otherwise identical fields', () {
      final address = Address.forAccountId(_goldenSignerAccount);
      final innerCreds1 = SorobanAddressCredentials(
        address,
        BigInt.from(_goldenNonce),
        _goldenExpiration,
        XdrSCVal.forVoid(),
      );
      final innerCreds2 = SorobanAddressCredentials(
        address,
        BigInt.from(_goldenNonce),
        _goldenExpiration,
        XdrSCVal.forVoid(),
      );

      final contractAddr = Address.forContractId(_goldenContract);
      final function = SorobanAuthorizedFunction.forContractFunction(
        contractAddr,
        'hello',
        [XdrSCVal.forU64(BigInt.from(1234))],
      );
      final invocation1 = SorobanAuthorizedInvocation(function);
      final invocation2 = SorobanAuthorizedInvocation(function);

      final legacyEntry = SorobanAuthorizationEntry(
        SorobanCredentials(addressCredentials: innerCreds1),
        invocation1,
      );
      final v2Entry = SorobanAuthorizationEntry(
        SorobanCredentials.forAddressV2(innerCreds2),
        invocation2,
      );

      expect(
        _computePayloadHex(legacyEntry, Network.TESTNET),
        isNot(equals(_computePayloadHex(v2Entry, Network.TESTNET))),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // _verifyServerSignature path through validateChallenge
  // ---------------------------------------------------------------------------
  group('WebAuthForContracts - _verifyServerSignature arm coverage', () {
    late KeyPair serverKeyPair;
    late String serverAccountId;
    late XdrSCVal argsMap;
    late WebAuthForContracts webAuth;

    setUp(() {
      serverKeyPair = KeyPair.random();
      serverAccountId = serverKeyPair.accountId;

      argsMap = _buildArgsMap(
        account: _clientAccountId,
        homeDomain: _homeDomain,
        webAuthDomain: _webAuthDomain,
        webAuthDomainAccount: serverAccountId,
        nonce: _nonce,
      );

      webAuth = WebAuthForContracts(
        _authEndpoint,
        _webAuthContractId,
        serverAccountId,
        _homeDomain,
        Network.TESTNET,
      );
    });

    test('legacy ADDRESS server entry verifies successfully', () {
      final innerCreds = SorobanAddressCredentials(
        Address.forAccountId(serverAccountId),
        BigInt.from(1),
        9999,
        XdrSCVal.forVoid(),
      );
      final credentials =
          SorobanCredentials(addressCredentials: innerCreds);

      final serverEntry = _buildSignedServerEntry(
        serverKeyPair: serverKeyPair,
        credentials: credentials,
        webAuthContractId: _webAuthContractId,
        argsMap: argsMap,
        network: Network.TESTNET,
        signatureExpirationLedger: 9999,
      );

      final clientInnerCreds = SorobanAddressCredentials(
        _contractAddress(_clientAccountId),
        BigInt.from(2),
        9999,
        XdrSCVal.forVoid(),
      );
      final clientEntry = _buildWebAuthEntry(
        credentials: SorobanCredentials(addressCredentials: clientInnerCreds),
        webAuthContractId: _webAuthContractId,
        argsMap: argsMap,
      );

      // validateChallenge must not throw — the server entry has a valid
      // legacy-preimage signature.
      expect(
        () => webAuth.validateChallenge(
          [serverEntry, clientEntry],
          _clientAccountId,
        ),
        returnsNormally,
      );
    });

    test('ADDRESS_V2 server entry verifies successfully with WITH_ADDRESS preimage', () {
      final innerCreds = SorobanAddressCredentials(
        Address.forAccountId(serverAccountId),
        BigInt.from(1),
        9999,
        XdrSCVal.forVoid(),
      );
      final credentials = SorobanCredentials.forAddressV2(innerCreds);

      final serverEntry = _buildSignedServerEntry(
        serverKeyPair: serverKeyPair,
        credentials: credentials,
        webAuthContractId: _webAuthContractId,
        argsMap: argsMap,
        network: Network.TESTNET,
        signatureExpirationLedger: 9999,
      );

      // Arm must be preserved after signing.
      expect(
        serverEntry.credentials.arm,
        equals(XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2),
      );

      final clientInnerCreds = SorobanAddressCredentials(
        _contractAddress(_clientAccountId),
        BigInt.from(2),
        9999,
        XdrSCVal.forVoid(),
      );
      final clientEntry = _buildWebAuthEntry(
        credentials: SorobanCredentials(addressCredentials: clientInnerCreds),
        webAuthContractId: _webAuthContractId,
        argsMap: argsMap,
      );

      // validateChallenge must not throw.
      expect(
        () => webAuth.validateChallenge(
          [serverEntry, clientEntry],
          _clientAccountId,
        ),
        returnsNormally,
      );
    });

    test(
        'ADDRESS_V2 server entry signed over the wrong (legacy) preimage fails verification',
        () {
      // Build V2 credentials but sign manually over the LEGACY preimage.
      final innerCreds = SorobanAddressCredentials(
        Address.forAccountId(serverAccountId),
        BigInt.from(1),
        9999,
        XdrSCVal.forVoid(),
      );
      innerCreds.signatureExpirationLedger = 9999;

      final v2Credentials = SorobanCredentials.forAddressV2(innerCreds);
      final serverEntry = _buildWebAuthEntry(
        credentials: v2Credentials,
        webAuthContractId: _webAuthContractId,
        argsMap: argsMap,
      );

      // Construct the WRONG (legacy) preimage manually and sign over it.
      final legacyCreds = SorobanAddressCredentials(
        Address.forAccountId(serverAccountId),
        BigInt.from(1),
        9999,
        XdrSCVal.forVoid(),
      );
      final legacyEntry = _buildWebAuthEntry(
        credentials: SorobanCredentials(addressCredentials: legacyCreds),
        webAuthContractId: _webAuthContractId,
        argsMap: argsMap,
      );
      // Compute the legacy payload hash.
      final legacyPreimage = legacyEntry.buildPreimage(Network.TESTNET);
      final legacyOut = XdrDataOutputStream();
      XdrHashIDPreimage.encode(legacyOut, legacyPreimage);
      final legacyPayload =
          Util.hash(Uint8List.fromList(legacyOut.bytes));

      // Sign the V2 entry's credential using the legacy payload hash.
      final sigBytes = serverKeyPair.sign(legacyPayload);
      final sig = AccountEd25519Signature(serverKeyPair.xdrPublicKey, sigBytes);
      final sigVec = XdrSCVal.forVec([sig.toXdrSCVal()]);
      serverEntry.credentials.innerAddressCredentials!.signature = sigVec;

      final clientInnerCreds = SorobanAddressCredentials(
        _contractAddress(_clientAccountId),
        BigInt.from(2),
        9999,
        XdrSCVal.forVoid(),
      );
      final clientEntry = _buildWebAuthEntry(
        credentials: SorobanCredentials(addressCredentials: clientInnerCreds),
        webAuthContractId: _webAuthContractId,
        argsMap: argsMap,
      );

      // validateChallenge must throw because the signature is over the wrong preimage.
      expect(
        () => webAuth.validateChallenge(
          [serverEntry, clientEntry],
          _clientAccountId,
        ),
        throwsA(
          isA<ContractChallengeValidationErrorInvalidServerSignature>(),
        ),
      );
    });

    test('ADDRESS_WITH_DELEGATES server entry verifies successfully', () {
      // Build an ADDRESS entry and convert to WITH_DELEGATES.
      final innerCreds = SorobanAddressCredentials(
        Address.forAccountId(serverAccountId),
        BigInt.from(1),
        9999,
        XdrSCVal.forVoid(),
      );
      final baseEntry = _buildWebAuthEntry(
        credentials: SorobanCredentials(addressCredentials: innerCreds),
        webAuthContractId: _webAuthContractId,
        argsMap: argsMap,
      );

      // Delegate to a different G-address (distinct from server address).
      final delegateKeyPair = KeyPair.random();
      final delegateAddress = delegateKeyPair.accountId;

      final withDelegatesEntry = SorobanAuthorizationEntry.withDelegates(
        baseEntry,
        [SorobanDelegateDescriptor(delegateAddress)],
        9999,
      );

      // Sign at the top level (server address) since it is a G-address.
      withDelegatesEntry.sign(serverKeyPair, Network.TESTNET);

      expect(
        withDelegatesEntry.credentials.arm,
        equals(
            XdrSorobanCredentialsType
                .SOROBAN_CREDENTIALS_ADDRESS_WITH_DELEGATES),
      );

      final clientInnerCreds = SorobanAddressCredentials(
        _contractAddress(_clientAccountId),
        BigInt.from(2),
        9999,
        XdrSCVal.forVoid(),
      );
      final clientEntry = _buildWebAuthEntry(
        credentials: SorobanCredentials(addressCredentials: clientInnerCreds),
        webAuthContractId: _webAuthContractId,
        argsMap: argsMap,
      );

      // validateChallenge must not throw.
      expect(
        () => webAuth.validateChallenge(
          [withDelegatesEntry, clientEntry],
          _clientAccountId,
        ),
        returnsNormally,
      );
    });

    test('source-account server entry is not matched as server entry', () {
      // A source-account entry cannot be the server entry because
      // innerAddressCredentials is null and the address check is skipped.
      // validateChallenge must throw ContractChallengeValidationErrorMissingServerEntry.
      final sourceAccountEntry = _buildWebAuthEntry(
        credentials: SorobanCredentials.forSourceAccount(),
        webAuthContractId: _webAuthContractId,
        argsMap: argsMap,
      );

      final clientInnerCreds = SorobanAddressCredentials(
        _contractAddress(_clientAccountId),
        BigInt.from(2),
        9999,
        XdrSCVal.forVoid(),
      );
      final clientEntry = _buildWebAuthEntry(
        credentials: SorobanCredentials(addressCredentials: clientInnerCreds),
        webAuthContractId: _webAuthContractId,
        argsMap: argsMap,
      );

      expect(
        () => webAuth.validateChallenge(
          [sourceAccountEntry, clientEntry],
          _clientAccountId,
        ),
        throwsA(
          isA<ContractChallengeValidationErrorMissingServerEntry>(),
        ),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // signAuthorizationEntries — arm preservation through expiration stamping
  // ---------------------------------------------------------------------------
  group('WebAuthForContracts - signAuthorizationEntries arm preservation', () {
    late KeyPair serverKeyPair;
    late String serverAccountId;
    late KeyPair clientKeyPair;
    late String clientAccountId;
    late XdrSCVal argsMap;

    setUp(() {
      serverKeyPair = KeyPair.random();
      serverAccountId = serverKeyPair.accountId;
      clientKeyPair = KeyPair.random();
      clientAccountId = clientKeyPair.accountId;

      argsMap = _buildArgsMap(
        account: clientAccountId,
        homeDomain: _homeDomain,
        webAuthDomain: _webAuthDomain,
        webAuthDomainAccount: serverAccountId,
        nonce: _nonce,
      );
    });

    test('ADDRESS arm preserved after expiration stamping', () async {
      final innerCreds = SorobanAddressCredentials(
        Address.forAccountId(clientAccountId),
        BigInt.from(1),
        0,
        XdrSCVal.forVoid(),
      );
      final entry = _buildWebAuthEntry(
        credentials: SorobanCredentials(addressCredentials: innerCreds),
        webAuthContractId: _webAuthContractId,
        argsMap: argsMap,
      );

      final webAuth = WebAuthForContracts(
        _authEndpoint,
        _webAuthContractId,
        serverAccountId,
        _homeDomain,
        Network.TESTNET,
      );

      final signed = await webAuth.signAuthorizationEntries(
        [entry],
        clientAccountId,
        [clientKeyPair],
        5000,
        null,
        null,
        null,
      );

      expect(signed.length, equals(1));
      expect(
        signed[0].credentials.arm,
        equals(XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS),
      );
      expect(
        signed[0].credentials.innerAddressCredentials!.signatureExpirationLedger,
        equals(5000),
      );
    });

    test('ADDRESS_V2 arm preserved after expiration stamping and signing', () async {
      final innerCreds = SorobanAddressCredentials(
        Address.forAccountId(clientAccountId),
        BigInt.from(1),
        0,
        XdrSCVal.forVoid(),
      );
      final entry = _buildWebAuthEntry(
        credentials: SorobanCredentials.forAddressV2(innerCreds),
        webAuthContractId: _webAuthContractId,
        argsMap: argsMap,
      );

      final webAuth = WebAuthForContracts(
        _authEndpoint,
        _webAuthContractId,
        serverAccountId,
        _homeDomain,
        Network.TESTNET,
      );

      final signed = await webAuth.signAuthorizationEntries(
        [entry],
        clientAccountId,
        [clientKeyPair],
        6000,
        null,
        null,
        null,
      );

      expect(signed.length, equals(1));
      expect(
        signed[0].credentials.arm,
        equals(XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2),
      );
      expect(
        signed[0].credentials.innerAddressCredentials!.signatureExpirationLedger,
        equals(6000),
      );
      // The signature vector must be non-empty after signing.
      final sigVec = signed[0].credentials.innerAddressCredentials!.signature;
      expect(sigVec.discriminant, equals(XdrSCValType.SCV_VEC));
      expect(sigVec.vec, isNotEmpty);
    });

    test('ADDRESS_WITH_DELEGATES arm preserved after expiration stamping', () async {
      final innerCreds = SorobanAddressCredentials(
        Address.forAccountId(clientAccountId),
        BigInt.from(1),
        0,
        XdrSCVal.forVoid(),
      );
      final baseEntry = _buildWebAuthEntry(
        credentials: SorobanCredentials(addressCredentials: innerCreds),
        webAuthContractId: _webAuthContractId,
        argsMap: argsMap,
      );

      final delegateKey = KeyPair.random();
      final withDelegates = SorobanAuthorizationEntry.withDelegates(
        baseEntry,
        [SorobanDelegateDescriptor(delegateKey.accountId)],
        0,
      );

      final webAuth = WebAuthForContracts(
        _authEndpoint,
        _webAuthContractId,
        serverAccountId,
        _homeDomain,
        Network.TESTNET,
      );

      final signed = await webAuth.signAuthorizationEntries(
        [withDelegates],
        clientAccountId,
        [clientKeyPair],
        7000,
        null,
        null,
        null,
      );

      expect(signed.length, equals(1));
      expect(
        signed[0].credentials.arm,
        equals(
            XdrSorobanCredentialsType
                .SOROBAN_CREDENTIALS_ADDRESS_WITH_DELEGATES),
      );
      expect(
        signed[0].credentials.innerAddressCredentials!.signatureExpirationLedger,
        equals(7000),
      );
    });

    test('source-account entry passes through unsigned', () async {
      final sourceEntry = _buildWebAuthEntry(
        credentials: SorobanCredentials.forSourceAccount(),
        webAuthContractId: _webAuthContractId,
        argsMap: argsMap,
      );

      final webAuth = WebAuthForContracts(
        _authEndpoint,
        _webAuthContractId,
        serverAccountId,
        _homeDomain,
        Network.TESTNET,
      );

      // Must not throw even though source-account credentials carry no address.
      final result = await webAuth.signAuthorizationEntries(
        [sourceEntry],
        clientAccountId,
        [clientKeyPair],
        5000,
        null,
        null,
        null,
      );

      expect(result.length, equals(1));
      expect(
        result[0].credentials.arm,
        equals(XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_SOURCE_ACCOUNT),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // validateChallenge — ADDRESS_V2 and WITH_DELEGATES client entries accepted
  // ---------------------------------------------------------------------------
  group('WebAuthForContracts - validateChallenge arm detection', () {
    test('ADDRESS_V2 client entry is recognised and does not block validation', () {
      final serverKeyPair = KeyPair.random();
      final serverAccountId = serverKeyPair.accountId;

      final argsMap = _buildArgsMap(
        account: _clientAccountId,
        homeDomain: _homeDomain,
        webAuthDomain: _webAuthDomain,
        webAuthDomainAccount: serverAccountId,
        nonce: _nonce,
      );

      final webAuth = WebAuthForContracts(
        _authEndpoint,
        _webAuthContractId,
        serverAccountId,
        _homeDomain,
        Network.TESTNET,
      );

      // Build a signed server entry (legacy arm is fine for the server).
      final serverEntry = _buildSignedServerEntry(
        serverKeyPair: serverKeyPair,
        credentials: SorobanCredentials(
          addressCredentials: SorobanAddressCredentials(
            Address.forAccountId(serverAccountId),
            BigInt.from(1),
            9999,
            XdrSCVal.forVoid(),
          ),
        ),
        webAuthContractId: _webAuthContractId,
        argsMap: argsMap,
        network: Network.TESTNET,
        signatureExpirationLedger: 9999,
      );

      // Client entry uses ADDRESS_V2 arm.
      final clientInnerCreds = SorobanAddressCredentials(
        _contractAddress(_clientAccountId),
        BigInt.from(2),
        9999,
        XdrSCVal.forVoid(),
      );
      final clientEntry = _buildWebAuthEntry(
        credentials: SorobanCredentials.forAddressV2(clientInnerCreds),
        webAuthContractId: _webAuthContractId,
        argsMap: argsMap,
      );

      // validateChallenge must locate the client entry via innerAddressCredentials
      // and not throw ContractChallengeValidationErrorMissingClientEntry.
      expect(
        () => webAuth.validateChallenge(
          [serverEntry, clientEntry],
          _clientAccountId,
        ),
        returnsNormally,
      );
    });

    test('ADDRESS_WITH_DELEGATES client entry is recognised', () {
      final serverKeyPair = KeyPair.random();
      final serverAccountId = serverKeyPair.accountId;

      final clientContractId = _clientAccountId;
      final argsMap = _buildArgsMap(
        account: clientContractId,
        homeDomain: _homeDomain,
        webAuthDomain: _webAuthDomain,
        webAuthDomainAccount: serverAccountId,
        nonce: _nonce,
      );

      final webAuth = WebAuthForContracts(
        _authEndpoint,
        _webAuthContractId,
        serverAccountId,
        _homeDomain,
        Network.TESTNET,
      );

      final serverEntry = _buildSignedServerEntry(
        serverKeyPair: serverKeyPair,
        credentials: SorobanCredentials(
          addressCredentials: SorobanAddressCredentials(
            Address.forAccountId(serverAccountId),
            BigInt.from(1),
            9999,
            XdrSCVal.forVoid(),
          ),
        ),
        webAuthContractId: _webAuthContractId,
        argsMap: argsMap,
        network: Network.TESTNET,
        signatureExpirationLedger: 9999,
      );

      // Build a WITH_DELEGATES client entry; top-level address is the
      // contract clientContractId, delegate is an arbitrary G-address.
      final clientInnerCreds = SorobanAddressCredentials(
        _contractAddress(clientContractId),
        BigInt.from(2),
        0,
        XdrSCVal.forVoid(),
      );
      final clientBaseEntry = _buildWebAuthEntry(
        credentials: SorobanCredentials(addressCredentials: clientInnerCreds),
        webAuthContractId: _webAuthContractId,
        argsMap: argsMap,
      );
      final delegateKey = KeyPair.random();
      final clientWithDelegates = SorobanAuthorizationEntry.withDelegates(
        clientBaseEntry,
        [SorobanDelegateDescriptor(delegateKey.accountId)],
        9999,
      );

      // validateChallenge must locate the client entry by its top-level address.
      expect(
        () => webAuth.validateChallenge(
          [serverEntry, clientWithDelegates],
          clientContractId,
        ),
        returnsNormally,
      );
    });
  });
}
