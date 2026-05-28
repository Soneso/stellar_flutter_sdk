// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

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
  BigInt? nonce,
  int expirationLedger = 0,
}) {
  final addrXdr = XdrSCAddress.forContractId(kValidContractId);
  final cred = XdrSorobanAddressCredentials(
    addrXdr,
    XdrInt64(nonce ?? BigInt.from(123456)),
    XdrUint32(expirationLedger),
    XdrSCVal.forVoid(),
  );
  final wrapper = XdrSorobanCredentials.forAddressCredentials(cred);
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
  test('testSignAuthEntry_differentSignersProduceDistinctSerialisedEntries', () async {
    // Two different signers signing the same entry produce two distinct serialised entries.
    final entry = _buildEntry();
    final out1 = await OZSmartAccountAuth.signAuthEntry(
      entry: entry,
      signer: OZDelegatedSigner(kValidGAddress),
      signature: _webauthn(1),
      expirationLedger: 100,
    );
    final out2 = await OZSmartAccountAuth.signAuthEntry(
      entry: entry,
      signer: OZExternalSigner(kValidContractId, _bytes(8)),
      signature: _webauthn(2),
      expirationLedger: 100,
    );
    expect(out1.toBase64EncodedXdrString(),
        isNot(out2.toBase64EncodedXdrString()));
  });

  test('testSignAuthEntry_payloadHashChangesWithDifferentNonce', () async {
    final e1 = _buildEntry(nonce: BigInt.from(1));
    final e2 = _buildEntry(nonce: BigInt.from(2));
    final h1 = await OZSmartAccountAuth.buildAuthPayloadHash(
      e1,
      100,
      kNetworkPassphrase,
    );
    final h2 = await OZSmartAccountAuth.buildAuthPayloadHash(
      e2,
      100,
      kNetworkPassphrase,
    );
    expect(h1, isNot(h2));
  });

  test('testSignAuthEntry_payloadHashChangesWithDifferentExpiration',
      () async {
    final entry = _buildEntry();
    final h1 = await OZSmartAccountAuth.buildAuthPayloadHash(
      entry,
      100,
      kNetworkPassphrase,
    );
    final h2 = await OZSmartAccountAuth.buildAuthPayloadHash(
      entry,
      200,
      kNetworkPassphrase,
    );
    expect(h1, isNot(h2));
  });

  test('testSignAuthEntry_doesNotMutateOriginalEntry', () async {
    final entry = _buildEntry();
    final originalSig = entry.credentials.address!.signature.discriminant;
    await OZSmartAccountAuth.signAuthEntry(
      entry: entry,
      signer: OZDelegatedSigner(kValidGAddress),
      signature: _webauthn(),
      expirationLedger: 100,
    );
    expect(entry.credentials.address!.signature.discriminant, originalSig);
  });
}
