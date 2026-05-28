// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

const String kValidGAddress =
    'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';
const String kValidContractId =
    'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK';
const String kNetworkPassphrase = 'Test SDF Network ; September 2015';

Uint8List _bytes(int n, [int seed = 0]) {
  final out = Uint8List(n);
  for (var i = 0; i < n; i++) {
    out[i] = (i + seed) & 0xFF;
  }
  return out;
}

XdrSorobanAuthorizationEntry _buildEntry({
  String address = kValidContractId,
  BigInt? nonce,
  int expirationLedger = 0,
  XdrSCVal? signature,
}) {
  final addrXdr = XdrSCAddress.forContractId(address);
  final cred = XdrSorobanAddressCredentials(
    addrXdr,
    XdrInt64(nonce ?? BigInt.from(123456)),
    XdrUint32(expirationLedger),
    signature ?? XdrSCVal.forVoid(),
  );
  final credsWrapper = XdrSorobanCredentials.forAddressCredentials(cred);

  // Construct a minimal root invocation: a contract-fn invocation with no
  // sub-invocations.
  final fn = XdrSorobanAuthorizedFunction(
    XdrSorobanAuthorizedFunctionType
        .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN,
  );
  fn.contractFn = XdrInvokeContractArgs(
    addrXdr,
    'test',
    <XdrSCVal>[],
  );
  final invocation = XdrSorobanAuthorizedInvocation(
    fn,
    <XdrSorobanAuthorizedInvocation>[],
  );
  return XdrSorobanAuthorizationEntry(credsWrapper, invocation);
}

XdrSorobanAuthorizationEntry _buildSourceAccountEntry() {
  final addrXdr = XdrSCAddress.forContractId(kValidContractId);
  final wrapper = XdrSorobanCredentials.forSourceAccount();
  final fn = XdrSorobanAuthorizedFunction(
    XdrSorobanAuthorizedFunctionType
        .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN,
  );
  fn.contractFn = XdrInvokeContractArgs(
    addrXdr,
    'test',
    <XdrSCVal>[],
  );
  final invocation = XdrSorobanAuthorizedInvocation(
    fn,
    <XdrSorobanAuthorizedInvocation>[],
  );
  return XdrSorobanAuthorizationEntry(wrapper, invocation);
}

OZWebAuthnSignature _webauthn([int seed = 0]) => OZWebAuthnSignature(
      authenticatorData: _bytes(16, seed),
      clientData: _bytes(20, seed),
      signature: _bytes(64, seed),
    );

void main() {
  group('buildSourceAccountAuthPayloadHash', () {
    test('testBuildSourceAccountAuthPayloadHash_differentNoncesProduceDifferentHashes',
        () async {
      final entry = _buildSourceAccountEntry();
      final h1 = await OZSmartAccountAuth.buildSourceAccountAuthPayloadHash(
        entry,
        XdrInt64(BigInt.from(1)),
        100,
        kNetworkPassphrase,
      );
      final h2 = await OZSmartAccountAuth.buildSourceAccountAuthPayloadHash(
        entry,
        XdrInt64(BigInt.from(2)),
        100,
        kNetworkPassphrase,
      );
      expect(h1, isNot(h2));
    });

    test(
        'testBuildSourceAccountAuthPayloadHash_differentExpirationProducesDifferentHash',
        () async {
      final entry = _buildSourceAccountEntry();
      final h1 = await OZSmartAccountAuth.buildSourceAccountAuthPayloadHash(
        entry,
        XdrInt64(BigInt.from(1)),
        100,
        kNetworkPassphrase,
      );
      final h2 = await OZSmartAccountAuth.buildSourceAccountAuthPayloadHash(
        entry,
        XdrInt64(BigInt.from(1)),
        200,
        kNetworkPassphrase,
      );
      expect(h1, isNot(h2));
    });

    test(
        'testBuildSourceAccountAuthPayloadHash_differentNetworkPassphraseProducesDifferentHash',
        () async {
      final entry = _buildSourceAccountEntry();
      final h1 = await OZSmartAccountAuth.buildSourceAccountAuthPayloadHash(
        entry,
        XdrInt64(BigInt.from(1)),
        100,
        'Public Global Stellar Network ; September 2015',
      );
      final h2 = await OZSmartAccountAuth.buildSourceAccountAuthPayloadHash(
        entry,
        XdrInt64(BigInt.from(1)),
        100,
        kNetworkPassphrase,
      );
      expect(h1, isNot(h2));
    });

    test('testBuildSourceAccountAuthPayloadHash_isConsistent', () async {
      final entry = _buildSourceAccountEntry();
      final h1 = await OZSmartAccountAuth.buildSourceAccountAuthPayloadHash(
        entry,
        XdrInt64(BigInt.from(1)),
        100,
        kNetworkPassphrase,
      );
      final h2 = await OZSmartAccountAuth.buildSourceAccountAuthPayloadHash(
        entry,
        XdrInt64(BigInt.from(1)),
        100,
        kNetworkPassphrase,
      );
      expect(h1, h2);
    });

    test('testBuildSourceAccountAuthPayloadHash_matchesManualPreimageConstruction',
        () async {
      final entry = _buildSourceAccountEntry();
      final nonce = XdrInt64(BigInt.from(7));
      final h1 = await OZSmartAccountAuth.buildSourceAccountAuthPayloadHash(
        entry,
        nonce,
        50,
        kNetworkPassphrase,
      );

      final networkId = Uint8List.fromList(
        crypto.sha256.convert(utf8.encode(kNetworkPassphrase)).bytes,
      );
      final auth = XdrHashIDPreimageSorobanAuthorization(
        XdrHash(networkId),
        nonce,
        XdrUint32(50),
        entry.rootInvocation,
      );
      final preimage = XdrHashIDPreimage(
        XdrEnvelopeType.ENVELOPE_TYPE_SOROBAN_AUTHORIZATION,
      );
      preimage.sorobanAuthorization = auth;
      final stream = XdrDataOutputStream();
      XdrHashIDPreimage.encode(stream, preimage);
      final manual = Uint8List.fromList(
        crypto.sha256.convert(stream.bytes).bytes,
      );
      expect(h1, manual);
    });
  });

  group('buildAuthPayloadHash', () {
    test('testBuildAuthPayloadHash_throwsOnVoidCredentials', () async {
      final entry = _buildSourceAccountEntry();
      await expectLater(
        OZSmartAccountAuth.buildAuthPayloadHash(entry, 100, kNetworkPassphrase),
        throwsA(isA<TransactionSigningFailed>()),
      );
    });

    test(
        'testBuildAuthPayloadHash_andBuildSourceAccountAuthPayloadHash_sameInputsProduceSameHash',
        () async {
      final addrEntry = _buildEntry(nonce: BigInt.from(99));
      final srcEntry = _buildSourceAccountEntry();
      final h1 = await OZSmartAccountAuth.buildAuthPayloadHash(
          addrEntry, 100, kNetworkPassphrase);
      final h2 = await OZSmartAccountAuth.buildSourceAccountAuthPayloadHash(
        srcEntry,
        XdrInt64(BigInt.from(99)),
        100,
        kNetworkPassphrase,
      );
      expect(h1, h2);
    });
  });

  group('addRawSignatureMapEntry', () {
    test('testAddRawSignatureMapEntry_addsEntryToVoidSignatureEntry', () {
      final entry = _buildEntry();
      final signer = OZDelegatedSigner(kValidGAddress);
      final out = OZSmartAccountAuth.addRawSignatureMapEntry(
        entry: entry,
        signerKey: signer.toScVal(),
        signatureValue: XdrSCVal.forBytes(_bytes(0)),
      );
      final cred = out.credentials.address!;
      final payload = OZSmartAccountAuthPayloadCodec.read(cred.signature);
      expect(payload.signers, hasLength(1));
    });

    test('testAddRawSignatureMapEntry_mapEntryHasCorrectKeyAndValue', () {
      final entry = _buildEntry();
      final signer = OZDelegatedSigner(kValidGAddress);
      final out = OZSmartAccountAuth.addRawSignatureMapEntry(
        entry: entry,
        signerKey: signer.toScVal(),
        signatureValue: XdrSCVal.forBytes(_bytes(8, 5)),
      );
      final cred = out.credentials.address!;
      final payload = OZSmartAccountAuthPayloadCodec.read(cred.signature);
      expect(payload.signers.values.first, _bytes(8, 5));
    });

    test('testAddRawSignatureMapEntry_secondCallProducesTwoEntries', () {
      final entry = _buildEntry();
      final s1 = OZDelegatedSigner(kValidGAddress);
      final s2 = OZExternalSigner(kValidContractId, _bytes(8));
      final out1 = OZSmartAccountAuth.addRawSignatureMapEntry(
        entry: entry,
        signerKey: s1.toScVal(),
        signatureValue: XdrSCVal.forBytes(_bytes(4)),
      );
      final out2 = OZSmartAccountAuth.addRawSignatureMapEntry(
        entry: out1,
        signerKey: s2.toScVal(),
        signatureValue: XdrSCVal.forBytes(_bytes(8)),
      );
      final cred = out2.credentials.address!;
      final payload = OZSmartAccountAuthPayloadCodec.read(cred.signature);
      expect(payload.signers, hasLength(2));
    });

    test('testAddRawSignatureMapEntry_mapEntriesAreSortedByXdrEncodedKey', () {
      final entry = _buildEntry();
      final s1 = OZDelegatedSigner(kValidGAddress);
      final s2 = OZExternalSigner(kValidContractId, _bytes(8, 9));
      final out = OZSmartAccountAuth.addRawSignatureMapEntry(
        entry: OZSmartAccountAuth.addRawSignatureMapEntry(
          entry: entry,
          signerKey: s2.toScVal(),
          signatureValue: XdrSCVal.forBytes(_bytes(4, 1)),
        ),
        signerKey: s1.toScVal(),
        signatureValue: XdrSCVal.forBytes(_bytes(4, 2)),
      );
      final cred = out.credentials.address!;
      final entries = cred.signature.map![1].val.map!;
      String hex(XdrSCVal v) {
        final s = XdrDataOutputStream();
        XdrSCVal.encode(s, v);
        return Util.bytesToHex(Uint8List.fromList(s.bytes));
      }

      for (var i = 1; i < entries.length; i++) {
        expect(hex(entries[i - 1].key).compareTo(hex(entries[i].key)) <= 0,
            isTrue);
      }
    });

    test('testAddRawSignatureMapEntry_throwsOnSourceAccountCredentials', () {
      final entry = _buildSourceAccountEntry();
      final signer = OZDelegatedSigner(kValidGAddress);
      expect(
        () => OZSmartAccountAuth.addRawSignatureMapEntry(
          entry: entry,
          signerKey: signer.toScVal(),
          signatureValue: XdrSCVal.forBytes(_bytes(0)),
        ),
        throwsA(isA<TransactionSigningFailed>()),
      );
    });

    test('testAddRawSignatureMapEntry_doesNotMutateOriginalEntry', () {
      final entry = _buildEntry();
      final originalSigKind = entry.credentials.address!.signature.discriminant;
      OZSmartAccountAuth.addRawSignatureMapEntry(
        entry: entry,
        signerKey: OZDelegatedSigner(kValidGAddress).toScVal(),
        signatureValue: XdrSCVal.forBytes(_bytes(0)),
      );
      expect(entry.credentials.address!.signature.discriminant,
          originalSigKind);
    });

    test('testAddRawSignatureMapEntry_rawBytesAreStoredAsScvBytes', () {
      final entry = _buildEntry();
      final signer = OZDelegatedSigner(kValidGAddress);
      final out = OZSmartAccountAuth.addRawSignatureMapEntry(
        entry: entry,
        signerKey: signer.toScVal(),
        signatureValue: XdrSCVal.forBytes(_bytes(8, 9)),
      );
      final cred = out.credentials.address!;
      final entries = cred.signature.map![1].val.map!;
      expect(entries.first.val.discriminant, XdrSCValType.SCV_BYTES);
    });

    test('testAddRawSignatureMapEntry_contextRuleIdsAreSet', () {
      final entry = _buildEntry();
      final signer = OZDelegatedSigner(kValidGAddress);
      final out = OZSmartAccountAuth.addRawSignatureMapEntry(
        entry: entry,
        signerKey: signer.toScVal(),
        signatureValue: XdrSCVal.forBytes(_bytes(0)),
        contextRuleIds: const <int>[42, 99],
      );
      final cred = out.credentials.address!;
      final payload = OZSmartAccountAuthPayloadCodec.read(cred.signature);
      expect(payload.contextRuleIds, [42, 99]);
    });

    test('addRawSignatureMapEntry encodes non-Bytes signatureValue via XDR',
        () {
      final entry = _buildEntry();
      final signer = OZDelegatedSigner(kValidGAddress);
      // Pass a U32 signatureValue: it is not Bytes, so the codec must
      // XDR-encode the ScVal and store the raw bytes.
      final out = OZSmartAccountAuth.addRawSignatureMapEntry(
        entry: entry,
        signerKey: signer.toScVal(),
        signatureValue: XdrSCVal.forU32(0xDEADBEEF),
      );
      final cred = out.credentials.address!;
      final payload = OZSmartAccountAuthPayloadCodec.read(cred.signature);
      expect(payload.signers, hasLength(1));
      // Stored bytes are the XDR encoding of the U32 ScVal (5 bytes for
      // discriminant + 4 bytes for the value).
      expect(payload.signers.values.first.length, 8);
    });
  });

  group('signAuthEntry', () {
    test('testSignAuthEntry_throwsOnVoidCredentials', () async {
      final entry = _buildSourceAccountEntry();
      await expectLater(
        OZSmartAccountAuth.signAuthEntry(
          entry: entry,
          signer: OZDelegatedSigner(kValidGAddress),
          signature: _webauthn(),
          expirationLedger: 100,
        ),
        throwsA(isA<TransactionSigningFailed>()),
      );
    });

    test('testSignAuthEntry_twoSignersAccumulateCorrectly', () async {
      final entry = _buildEntry();
      final out1 = await OZSmartAccountAuth.signAuthEntry(
        entry: entry,
        signer: OZDelegatedSigner(kValidGAddress),
        signature: _webauthn(1),
        expirationLedger: 100,
      );
      final out2 = await OZSmartAccountAuth.signAuthEntry(
        entry: out1,
        signer: OZExternalSigner(kValidContractId, _bytes(8, 7)),
        signature: _webauthn(2),
        expirationLedger: 100,
      );
      final cred = out2.credentials.address!;
      final payload = OZSmartAccountAuthPayloadCodec.read(cred.signature);
      expect(payload.signers, hasLength(2));
    });

    test('testSignAuthEntry_twoSignersResultIsSortedByXdrEncodedKey',
        () async {
      final entry = _buildEntry();
      final s1 = OZDelegatedSigner(kValidGAddress);
      final s2 = OZExternalSigner(kValidContractId, _bytes(8, 7));
      final out = await OZSmartAccountAuth.signAuthEntry(
        entry: await OZSmartAccountAuth.signAuthEntry(
          entry: entry,
          signer: s2,
          signature: _webauthn(2),
          expirationLedger: 100,
        ),
        signer: s1,
        signature: _webauthn(1),
        expirationLedger: 100,
      );
      final cred = out.credentials.address!;
      final entries = cred.signature.map![1].val.map!;
      String hex(XdrSCVal v) {
        final s = XdrDataOutputStream();
        XdrSCVal.encode(s, v);
        return Util.bytesToHex(Uint8List.fromList(s.bytes));
      }

      for (var i = 1; i < entries.length; i++) {
        expect(hex(entries[i - 1].key).compareTo(hex(entries[i].key)) <= 0,
            isTrue);
      }
    });

    test('testSignAuthEntry_followedByAddRawSignatureMapEntry_bothEntriesPresent',
        () async {
      final entry = _buildEntry();
      final signed = await OZSmartAccountAuth.signAuthEntry(
        entry: entry,
        signer: OZDelegatedSigner(kValidGAddress),
        signature: _webauthn(),
        expirationLedger: 100,
      );
      final out = OZSmartAccountAuth.addRawSignatureMapEntry(
        entry: signed,
        signerKey: OZExternalSigner(kValidContractId, _bytes(8)).toScVal(),
        signatureValue: XdrSCVal.forBytes(_bytes(0)),
      );
      final cred = out.credentials.address!;
      final payload = OZSmartAccountAuthPayloadCodec.read(cred.signature);
      expect(payload.signers, hasLength(2));
    });

    test(
        'testSignAuthEntry_policySignatureWithDelegatedSignerHasCorrectStructure',
        () async {
      final entry = _buildEntry();
      final out = await OZSmartAccountAuth.signAuthEntry(
        entry: entry,
        signer: OZDelegatedSigner(kValidGAddress),
        signature: OZPolicySignature.instance,
        expirationLedger: 100,
      );
      final cred = out.credentials.address!;
      final payload = OZSmartAccountAuthPayloadCodec.read(cred.signature);
      expect(payload.signers, hasLength(1));
    });

    test('testSignAuthEntry_webAuthnSignatureTypeIsStoredCorrectly', () async {
      final entry = _buildEntry();
      final webauthn = _webauthn(7);
      final out = await OZSmartAccountAuth.signAuthEntry(
        entry: entry,
        signer: OZDelegatedSigner(kValidGAddress),
        signature: webauthn,
        expirationLedger: 100,
      );
      final cred = out.credentials.address!;
      final payload = OZSmartAccountAuthPayloadCodec.read(cred.signature);
      // The double-encoded bytes correspond to the WebAuthn ScVal map.
      final sigBytes = payload.signers.values.first;
      final reader = XdrDataInputStream(sigBytes);
      final reconstructed = XdrSCVal.decode(reader);
      expect(reconstructed.discriminant, XdrSCValType.SCV_MAP);
      expect(reconstructed.map?.length, 3);
    });

    test('testSignAuthEntry_contextRuleIdsArePreservedInPayload', () async {
      final entry = _buildEntry();
      final out = await OZSmartAccountAuth.signAuthEntry(
        entry: entry,
        signer: OZDelegatedSigner(kValidGAddress),
        signature: _webauthn(),
        expirationLedger: 100,
        contextRuleIds: const <int>[1, 2, 3],
      );
      final cred = out.credentials.address!;
      final payload = OZSmartAccountAuthPayloadCodec.read(cred.signature);
      expect(payload.contextRuleIds, [1, 2, 3]);
    });

    test('testSignAuthEntry_emptyContextRuleIdsProducesEmptyVec', () async {
      final entry = _buildEntry();
      final out = await OZSmartAccountAuth.signAuthEntry(
        entry: entry,
        signer: OZDelegatedSigner(kValidGAddress),
        signature: _webauthn(),
        expirationLedger: 100,
      );
      final cred = out.credentials.address!;
      final payload = OZSmartAccountAuthPayloadCodec.read(cred.signature);
      expect(payload.contextRuleIds, isEmpty);
    });

    test('testSignAuthEntry_secondSignerPreservesContextRuleIds', () async {
      final entry = _buildEntry();
      final out1 = await OZSmartAccountAuth.signAuthEntry(
        entry: entry,
        signer: OZDelegatedSigner(kValidGAddress),
        signature: _webauthn(),
        expirationLedger: 100,
        contextRuleIds: const <int>[5, 6],
      );
      final out2 = await OZSmartAccountAuth.signAuthEntry(
        entry: out1,
        signer: OZExternalSigner(kValidContractId, _bytes(8)),
        signature: _webauthn(2),
        expirationLedger: 100,
        // Empty contextRuleIds should preserve the existing [5, 6].
      );
      final cred = out2.credentials.address!;
      final payload = OZSmartAccountAuthPayloadCodec.read(cred.signature);
      expect(payload.contextRuleIds, [5, 6]);
    });

    test('testSignAuthEntry_setsExpirationWithContextRuleIds', () async {
      final entry = _buildEntry();
      final out = await OZSmartAccountAuth.signAuthEntry(
        entry: entry,
        signer: OZDelegatedSigner(kValidGAddress),
        signature: _webauthn(),
        expirationLedger: 12345,
        contextRuleIds: const <int>[7],
      );
      final cred = out.credentials.address!;
      expect(cred.signatureExpirationLedger.uint32, 12345);
      final payload = OZSmartAccountAuthPayloadCodec.read(cred.signature);
      expect(payload.contextRuleIds, [7]);
    });
  });

  group('codec read/write covered through OZSmartAccountAuth', () {
    test('testCodecRead_voidReturnsEmptyPayload', () {
      final out = OZSmartAccountAuthPayloadCodec.read(XdrSCVal.forVoid());
      expect(out.signers, isEmpty);
    });

    test('testCodecRead_nonMapThrows', () {
      expect(
        () => OZSmartAccountAuthPayloadCodec.read(XdrSCVal.forU32(0)),
        throwsA(isA<TransactionSigningFailed>()),
      );
    });

    test('testCodecWriteRead_roundTrip', () {
      final s = OZDelegatedSigner(kValidGAddress);
      final p = OZSmartAccountAuthPayload(
        signers: <OZSmartAccountSigner, Uint8List>{s: _bytes(8)},
        contextRuleIds: const <int>[5],
      );
      final encoded = OZSmartAccountAuthPayloadCodec.write(p);
      final decoded = OZSmartAccountAuthPayloadCodec.read(encoded);
      expect(decoded.contextRuleIds, [5]);
      expect(decoded.signers, hasLength(1));
    });

    test('testCodecWriteRead_emptyPayloadRoundTrip', () {
      final p = OZSmartAccountAuthPayload(
        signers: <OZSmartAccountSigner, Uint8List>{},
        contextRuleIds: const <int>[],
      );
      final encoded = OZSmartAccountAuthPayloadCodec.write(p);
      final decoded = OZSmartAccountAuthPayloadCodec.read(encoded);
      expect(decoded.signers, isEmpty);
    });

    test('testCodecWrite_producesMapWithTwoEntries', () {
      final encoded = OZSmartAccountAuthPayloadCodec.write(
        OZSmartAccountAuthPayload(
          signers: <OZSmartAccountSigner, Uint8List>{},
          contextRuleIds: const <int>[],
        ),
      );
      expect(encoded.map?.length, 2);
    });

    test('testCodecUpsertSigner_replacesExisting', () {
      final s = OZDelegatedSigner(kValidGAddress);
      final p = OZSmartAccountAuthPayload(
        signers: <OZSmartAccountSigner, Uint8List>{s: _bytes(4, 1)},
        contextRuleIds: const <int>[],
      );
      OZSmartAccountAuthPayloadCodec.upsertSigner(p, s, _bytes(4, 9));
      expect(p.signers.values.first[0], 9);
    });

    test('testCodecUpsertSigner_addsNewSigner', () {
      final p = OZSmartAccountAuthPayload(
        signers: <OZSmartAccountSigner, Uint8List>{
          OZDelegatedSigner(kValidGAddress): _bytes(4)
        },
        contextRuleIds: const <int>[],
      );
      OZSmartAccountAuthPayloadCodec.upsertSigner(
          p, OZExternalSigner(kValidContractId, _bytes(8)), _bytes(4));
      expect(p.signers, hasLength(2));
    });

    test('testCodecSignerFromScVal_parsesDelegated', () {
      final s = OZDelegatedSigner(kValidGAddress);
      expect(OZSmartAccountAuthPayloadCodec.signerFromScVal(s.toScVal()),
          isA<OZDelegatedSigner>());
    });

    test('testCodecSignerFromScVal_parsesExternal', () {
      final s = OZExternalSigner(kValidContractId, _bytes(8));
      expect(OZSmartAccountAuthPayloadCodec.signerFromScVal(s.toScVal()),
          isA<OZExternalSigner>());
    });

    test('testCodecSignerFromScVal_throwsOnNonVec', () {
      expect(
        () => OZSmartAccountAuthPayloadCodec.signerFromScVal(XdrSCVal.forU32(0)),
        throwsA(isA<TransactionSigningFailed>()),
      );
    });

    test('testCodecSignerFromScVal_throwsOnUnknownTag', () {
      expect(
        () => OZSmartAccountAuthPayloadCodec.signerFromScVal(XdrSCVal.forVec([
          XdrSCVal.forSymbol('UnknownTag'),
          XdrSCVal.forAddressStrKey(kValidContractId),
        ])),
        throwsA(isA<TransactionSigningFailed>()),
      );
    });

    test('testCodecSignerFromScVal_throwsOnEmptyVec', () {
      expect(
        () => OZSmartAccountAuthPayloadCodec.signerFromScVal(XdrSCVal.forVec([])),
        throwsA(isA<TransactionSigningFailed>()),
      );
    });

    test('testCodecWrite_signersSortedByXdrKey', () {
      final s1 = OZDelegatedSigner(kValidGAddress);
      final s2 = OZExternalSigner(kValidContractId, _bytes(8, 5));
      final p = OZSmartAccountAuthPayload(
        signers: <OZSmartAccountSigner, Uint8List>{s2: _bytes(4), s1: _bytes(4)},
        contextRuleIds: const <int>[],
      );
      final encoded = OZSmartAccountAuthPayloadCodec.write(p);
      final entries = encoded.map![1].val.map!;
      String hex(XdrSCVal v) {
        final s = XdrDataOutputStream();
        XdrSCVal.encode(s, v);
        return Util.bytesToHex(Uint8List.fromList(s.bytes));
      }

      for (var i = 1; i < entries.length; i++) {
        expect(hex(entries[i - 1].key).compareTo(hex(entries[i].key)) <= 0,
            isTrue);
      }
    });
  });

  group('buildAuthDigest', () {
    test('testBuildAuthDigest_changesWithDifferentRuleIds', () async {
      final payload = _bytes(32);
      final h1 = await OZSmartAccountAuth.buildAuthDigest(payload, const [1]);
      final h2 = await OZSmartAccountAuth.buildAuthDigest(payload, const [2]);
      expect(h1, isNot(h2));
    });

    test('testBuildAuthDigest_isConsistent', () async {
      final payload = _bytes(32);
      final h1 = await OZSmartAccountAuth.buildAuthDigest(payload, const [1, 2]);
      final h2 = await OZSmartAccountAuth.buildAuthDigest(payload, const [1, 2]);
      expect(h1, h2);
    });

    test('testBuildAuthDigest_emptyRuleIdsProducesDifferentDigestThanNonEmpty',
        () async {
      final payload = _bytes(32);
      final h1 =
          await OZSmartAccountAuth.buildAuthDigest(payload, const <int>[]);
      final h2 = await OZSmartAccountAuth.buildAuthDigest(payload, const [1]);
      expect(h1, isNot(h2));
    });
  });

  // Auth-digest golden vectors.
  //
  // These tests pin the byte-level output of the OZ auth-digest formula so
  // wire-format regressions fail immediately rather than shipping silently.
  // Update the expected hex strings whenever the formula changes.
  group('auth-digest golden vectors', () {
    Uint8List sha256OfUtf8(String s) =>
        Uint8List.fromList(crypto.sha256.convert(utf8.encode(s)).bytes);

    test('goldenVector1_emptyRulesMinimalPayload_authDigest_matchesFixture',
        () async {
      final signaturePayload = sha256OfUtf8('test1');
      final digest = await OZSmartAccountAuth.buildAuthDigest(
        signaturePayload,
        const <int>[],
      );
      final actualHex = Util.bytesToHex(digest).toLowerCase();
      const expectedHex =
          '78946b8d3c459fd2e9d6d786a49c0c37d3d37d2baff912ed4be618dd6a8712bd';
      expect(actualHex, expectedHex,
          reason: 'Golden vector 1 mismatch — actual: $actualHex');
    });

    test('goldenVector2_singleContextRule_authDigest_matchesFixture',
        () async {
      final signaturePayload = sha256OfUtf8('test2');
      final digest = await OZSmartAccountAuth.buildAuthDigest(
        signaturePayload,
        const <int>[42],
      );
      final actualHex = Util.bytesToHex(digest).toLowerCase();
      const expectedHex =
          '7f8310bb95276dd3c34ed9f3cd0a1bca75fea31643758738ba91a3894922a627';
      expect(actualHex, expectedHex,
          reason: 'Golden vector 2 mismatch — actual: $actualHex');
    });

    test('goldenVector3_unsortedContextRules_authDigest_matchesFixture',
        () async {
      // contextRuleIds must be bound in INSERTION order, not sorted. The
      // Vec encoding [3, 1, 2] must NOT silently become [1, 2, 3] — a sort
      // would weaken the digest's binding semantics.
      final signaturePayload = sha256OfUtf8('test3');
      final digest = await OZSmartAccountAuth.buildAuthDigest(
        signaturePayload,
        const <int>[3, 1, 2],
      );
      final actualHex = Util.bytesToHex(digest).toLowerCase();
      const expectedHex =
          '574421ac5094e4b6de31938a52a3c641f61b8504c92c3ee40fc94810f8f9d752';
      expect(actualHex, expectedHex,
          reason: 'Golden vector 3 mismatch — actual: $actualHex');

      // Cross-check: the same payload with [1, 2, 3] must produce a
      // different digest, proving the codec preserves insertion order.
      final sortedDigest = await OZSmartAccountAuth.buildAuthDigest(
        signaturePayload,
        const <int>[1, 2, 3],
      );
      expect(digest, isNot(sortedDigest),
          reason:
              'Insertion-ordered and sorted contextRuleIds must produce different digests');
    });

    test('goldenVector4_longSignaturePayload_authDigest_matchesFixture',
        () async {
      // 256-byte deterministic signaturePayload built from 8 sha256 chunks
      // exercising the multi-block hashing path.
      final builder = BytesBuilder();
      for (final tag in const [
        'test4-a',
        'test4-b',
        'test4-c',
        'test4-d',
        'test4-e',
        'test4-f',
        'test4-g',
        'test4-h',
      ]) {
        builder.add(sha256OfUtf8(tag));
      }
      final signaturePayload = Uint8List.fromList(builder.toBytes());
      expect(signaturePayload.length, 256);

      final digest = await OZSmartAccountAuth.buildAuthDigest(
        signaturePayload,
        const <int>[100, 200],
      );
      final actualHex = Util.bytesToHex(digest).toLowerCase();
      const expectedHex =
          '3f1b91ae753b805962516838fab26cc1933e01c8750290a852256ab0cba338d9';
      expect(actualHex, expectedHex,
          reason: 'Golden vector 4 mismatch — actual: $actualHex');
    });
  });
}
