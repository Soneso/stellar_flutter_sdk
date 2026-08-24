// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// ---------------------------------------------------------------------------
// Shared test fixtures
// ---------------------------------------------------------------------------

/// Seed from the golden vector specification.
const _kSeed = 'SDJHRQF4GCMIIKAAAQ6IHY42X73FQFLHUULAPSKKD4DFDM7UXWWCRHBE';

/// Known contract for golden vectors.
const _kContractId = 'CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE';

/// Nonce from the golden vector specification.
final BigInt _kNonce = BigInt.parse('123456789101112');

/// Expiration ledger from the golden vector specification.
const int _kExpiration = 4242;

/// Expected legacy (ADDRESS arm) preimage encoded as base64.
const _kLegacyPreimageB64 =
    'AAAACc7gMC1ZhE0yvcqRXIID3USzP7t+3BkFHqN6vt8o7NRyAABwSIYPOjgAABCSAAAAAAAAAAE2Pqo4Z'
    '4QfutD07YjHeeT+ZuVqJHDcmMDsnAc9BcexAwAAAAVoZWxsbwAAAAAAAAEAAAAFAAAAAAAABNIAAAAA';

/// Expected legacy payload hash (hex).
const _kLegacyPayloadHex =
    '120c429d4333e12e0ca2c5ac10630e728fdd33240bf7066f4c62f6a2d6fa3cbe';

/// Expected legacy Ed25519 signature (hex, 64 bytes).
const _kLegacySigHex =
    '3c69ceefc532f97e1d0e0eb9f204c9aa85cb2b68cf293bce832590b01455e06'
    '0e89900ea3ba2c45257908769a1a71f25b6d3befbadffd220f896dc005869900'
    '8';

/// Expected ADDRESS_V2 preimage encoded as base64.
const _kV2PreimageB64 =
    'AAAACs7gMC1ZhE0yvcqRXIID3USzP7t+3BkFHqN6vt8o7NRyAABwSIYPOjgAABCSAAAAAAAAAACye6+n'
    'vC/QBGzXlnxEUM9ckp1uevN+fsQL9108vQVKrQAAAAAAAAABNj6qOGeEH7rQ9O2Ix3nk/mblaiRw3Jj'
    'A7JwHPQXHsQMAAAAFaGVsbG8AAAAAAAABAAAABQAAAAAAAATSAAAAAA==';

/// Expected V2 payload hash (hex).
const _kV2PayloadHex =
    '252a0d6117840dff37b765839810fb6ecc446198e73062e01bc961e49355b7b9';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

SorobanAuthorizedInvocation _buildHelloInvocation() {
  final contractAddr = Address.forContractId(_kContractId);
  final fn = SorobanAuthorizedFunction.forContractFunction(
    contractAddr,
    'hello',
    [XdrSCVal.forU64(BigInt.from(1234))],
  );
  return SorobanAuthorizedInvocation(fn);
}

String _bytesToHex(Uint8List bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

Uint8List _hexToBytes(String hex) {
  final result = Uint8List(hex.length ~/ 2);
  for (int i = 0; i < result.length; i++) {
    result[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return result;
}

Uint8List _encodePreimage(XdrHashIDPreimage preimage) {
  final out = XdrDataOutputStream();
  XdrHashIDPreimage.encode(out, preimage);
  return Uint8List.fromList(out.bytes);
}

// Encode XdrSCAddress to bytes for comparison.
Uint8List _encodeXdrSCAddress(XdrSCAddress addr) {
  final out = XdrDataOutputStream();
  XdrSCAddress.encode(out, addr);
  return Uint8List.fromList(out.bytes);
}

// Build a 130-deep nested XdrSorobanDelegateSignature for the depth guard test.
XdrSorobanDelegateSignature _build130DeepXdrTree() {
  final addr = XdrSCAddress.forAccountId(
      KeyPair.fromSecretSeed(_kSeed).accountId);
  final sig = XdrSCVal.forVoid();
  XdrSorobanDelegateSignature current =
      XdrSorobanDelegateSignature(addr, sig, []);
  // Build 130 levels of nesting
  for (int i = 0; i < 130; i++) {
    current = XdrSorobanDelegateSignature(addr, sig, [current]);
  }
  return current;
}

void main() {
  // -------------------------------------------------------------------------
  // GROUP: XdrSorobanCredentials wrapper round-trip fidelity
  // -------------------------------------------------------------------------
  group('XdrSorobanCredentials wrapper round-trip fidelity', () {
    final signer = KeyPair.fromSecretSeed(_kSeed);
    final accountStrKey = signer.accountId;
    final accountXdrAddr = XdrSCAddress.forAccountId(accountStrKey);
    final contractXdrAddr = XdrSCAddress.forContractId(_kContractId);

    // Helper: encode XdrSorobanCredentials to base64 and decode back.
    // XdrSorobanCredentials inherits toBase64EncodedXdrString() from the base
    // class, but the static fromBase64EncodedXdrString is only on the base.
    // We decode via XdrSorobanCredentials.decode to keep the subtype.
    XdrSorobanCredentials decodeFromB64(XdrSorobanCredentials src) {
      final bytes = base64Decode(src.toBase64EncodedXdrString());
      return XdrSorobanCredentials.decode(XdrDataInputStream(bytes));
    }

    test('ADDRESS arm: XDR encode/decode round-trip preserves arm and payload',
        () {
      final addrCreds = XdrSorobanAddressCredentials(
        accountXdrAddr,
        XdrInt64(_kNonce),
        XdrUint32(_kExpiration),
        XdrSCVal.forVoid(),
      );
      final xdrCreds =
          XdrSorobanCredentials.forAddressCredentials(addrCreds);

      final decoded = decodeFromB64(xdrCreds);

      expect(decoded.discriminant,
          equals(XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS));
      expect(decoded.address, isNotNull);
      expect(decoded.addressV2, isNull);
      expect(decoded.addressWithDelegates, isNull);
      expect(decoded.address!.signatureExpirationLedger.uint32,
          equals(_kExpiration));
    });

    test('ADDRESS_V2 arm: XDR encode/decode round-trip preserves arm',
        () {
      final addrCreds = XdrSorobanAddressCredentials(
        accountXdrAddr,
        XdrInt64(_kNonce),
        XdrUint32(_kExpiration),
        XdrSCVal.forVoid(),
      );
      final xdrCreds =
          XdrSorobanCredentials.forAddressV2Credentials(addrCreds);

      final decoded = decodeFromB64(xdrCreds);

      expect(decoded.discriminant,
          equals(XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2));
      expect(decoded.addressV2, isNotNull);
      expect(decoded.address, isNull);
      expect(decoded.addressWithDelegates, isNull);
      expect(decoded.addressV2!.signatureExpirationLedger.uint32,
          equals(_kExpiration));
    });

    test('ADDRESS_WITH_DELEGATES arm: XDR encode/decode round-trip', () {
      final innerCreds = XdrSorobanAddressCredentials(
        accountXdrAddr,
        XdrInt64(_kNonce),
        XdrUint32(_kExpiration),
        XdrSCVal.forVoid(),
      );
      final delegateSig = XdrSorobanDelegateSignature(
          contractXdrAddr, XdrSCVal.forVoid(), []);
      final withDels = XdrSorobanAddressCredentialsWithDelegates(
          innerCreds, [delegateSig]);
      final xdrCreds = XdrSorobanCredentials.forAddressWithDelegatesCredentials(
          withDels);

      final decoded = decodeFromB64(xdrCreds);

      expect(
          decoded.discriminant,
          equals(XdrSorobanCredentialsType
              .SOROBAN_CREDENTIALS_ADDRESS_WITH_DELEGATES));
      expect(decoded.addressWithDelegates, isNotNull);
      expect(decoded.address, isNull);
      expect(decoded.addressV2, isNull);
      expect(decoded.addressWithDelegates!.delegates.length, equals(1));
    });

    test('SOURCE_ACCOUNT arm: XDR encode/decode round-trip', () {
      final xdrCreds = XdrSorobanCredentials.forSourceAccount();

      final decoded = decodeFromB64(xdrCreds);

      expect(
          decoded.discriminant,
          equals(
              XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_SOURCE_ACCOUNT));
    });

    // fromTxRep must preserve V2/WithDelegates fields through the round-trip
    test(
        'ADDRESS_V2 TxRep round-trip: fromTxRep preserves addressV2 data (regression)',
        () {
      final addrCreds = XdrSorobanAddressCredentials(
        accountXdrAddr,
        XdrInt64(_kNonce),
        XdrUint32(_kExpiration),
        XdrSCVal.forVoid(),
      );
      final xdrCreds =
          XdrSorobanCredentials.forAddressV2Credentials(addrCreds);

      final lines = <String>[];
      xdrCreds.toTxRep('creds', lines);
      final map = Map.fromEntries(
          lines.map((l) => l.split(': ')).map((p) => MapEntry(p[0], p[1])));

      final restored = XdrSorobanCredentials.fromTxRep(map, 'creds');

      expect(restored.discriminant,
          equals(XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2));
      // Critically: addressV2 must not be null after fromTxRep
      expect(restored.addressV2, isNotNull,
          reason: 'addressV2 must be populated by fromTxRep');
      expect(restored.address, isNull);
      expect(restored.addressWithDelegates, isNull);
    });

    test(
        'ADDRESS_WITH_DELEGATES TxRep round-trip: fromTxRep preserves data (regression)',
        () {
      final innerCreds = XdrSorobanAddressCredentials(
        accountXdrAddr,
        XdrInt64(_kNonce),
        XdrUint32(_kExpiration),
        XdrSCVal.forVoid(),
      );
      final delegateSig = XdrSorobanDelegateSignature(
          contractXdrAddr, XdrSCVal.forVoid(), []);
      final withDels = XdrSorobanAddressCredentialsWithDelegates(
          innerCreds, [delegateSig]);
      final xdrCreds = XdrSorobanCredentials.forAddressWithDelegatesCredentials(
          withDels);

      final lines = <String>[];
      xdrCreds.toTxRep('creds', lines);
      final map = <String, String>{};
      for (final l in lines) {
        final idx = l.indexOf(': ');
        if (idx >= 0) {
          map[l.substring(0, idx)] = l.substring(idx + 2);
        }
      }

      final restored = XdrSorobanCredentials.fromTxRep(map, 'creds');

      expect(
          restored.discriminant,
          equals(XdrSorobanCredentialsType
              .SOROBAN_CREDENTIALS_ADDRESS_WITH_DELEGATES));
      expect(restored.addressWithDelegates, isNotNull,
          reason: 'addressWithDelegates must be populated by fromTxRep');
      expect(restored.address, isNull);
      expect(restored.addressV2, isNull);
      expect(restored.addressWithDelegates!.delegates.length, equals(1));
    });
  });

  // -------------------------------------------------------------------------
  // GROUP: SorobanCredentials (high-level wrapper) round-trip
  // -------------------------------------------------------------------------
  group('SorobanCredentials high-level round-trip', () {
    final signer = KeyPair.fromSecretSeed(_kSeed);
    final accountAddr = Address.forAccountId(signer.accountId);

    test('fromXdr -> toXdr preserves ADDRESS arm', () {
      final creds = SorobanCredentials.forAddressLegacy(
          accountAddr, _kNonce, _kExpiration, XdrSCVal.forVoid());
      final roundTripped =
          SorobanCredentials.fromXdr(creds.toXdr());

      expect(roundTripped.arm,
          equals(XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS));
      expect(roundTripped.addressCredentials, isNotNull);
      expect(roundTripped.addressCredentials!.signatureExpirationLedger,
          equals(_kExpiration));
    });

    test('fromXdr -> toXdr preserves ADDRESS_V2 arm', () {
      final inner = SorobanAddressCredentials(
          accountAddr, _kNonce, _kExpiration, XdrSCVal.forVoid());
      final creds = SorobanCredentials.forAddressV2(inner);
      final roundTripped =
          SorobanCredentials.fromXdr(creds.toXdr());

      expect(roundTripped.arm,
          equals(XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2));
      expect(roundTripped.addressV2Credentials, isNotNull,
          reason: 'V2 data must survive fromXdr -> toXdr round-trip');
      expect(roundTripped.addressCredentials, isNull);
      expect(roundTripped.addressWithDelegatesCredentials, isNull);
    });

    test('fromXdr -> toXdr preserves ADDRESS_WITH_DELEGATES arm', () {
      final contractAddr = Address.forContractId(_kContractId);
      final inner = SorobanAddressCredentials(
          accountAddr, _kNonce, _kExpiration, XdrSCVal.forVoid());
      final delegateDesc = SorobanDelegateDescriptor(contractAddr.contractId!);
      final entry = SorobanAuthorizationEntry.withDelegates(
        SorobanAuthorizationEntry(
          SorobanCredentials.forAddressV2(inner),
          _buildHelloInvocation(),
        ),
        [delegateDesc],
        _kExpiration,
      );
      final roundTripped =
          SorobanCredentials.fromXdr(entry.credentials.toXdr());

      expect(
          roundTripped.arm,
          equals(XdrSorobanCredentialsType
              .SOROBAN_CREDENTIALS_ADDRESS_WITH_DELEGATES));
      expect(roundTripped.addressWithDelegatesCredentials, isNotNull,
          reason:
              'WITH_DELEGATES data must survive fromXdr -> toXdr round-trip');
    });

    test('fromXdr -> toXdr preserves SOURCE_ACCOUNT arm', () {
      final creds = SorobanCredentials.forSourceAccount();
      final roundTripped =
          SorobanCredentials.fromXdr(creds.toXdr());

      expect(
          roundTripped.arm,
          equals(
              XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_SOURCE_ACCOUNT));
    });

    test('innerAddressCredentials returns null for SOURCE_ACCOUNT', () {
      final creds = SorobanCredentials.forSourceAccount();
      expect(creds.innerAddressCredentials, isNull);
    });

    test('innerAddressCredentials returns payload for ADDRESS arm', () {
      final creds = SorobanCredentials.forAddressLegacy(
          accountAddr, _kNonce, _kExpiration, XdrSCVal.forVoid());
      final inner = creds.innerAddressCredentials;
      expect(inner, isNotNull);
      expect(inner!.nonce, equals(_kNonce));
    });

    test('innerAddressCredentials returns payload for ADDRESS_V2 arm', () {
      final inner = SorobanAddressCredentials(
          accountAddr, _kNonce, _kExpiration, XdrSCVal.forVoid());
      final creds = SorobanCredentials.forAddressV2(inner);
      final got = creds.innerAddressCredentials;
      expect(got, isNotNull);
      expect(got!.nonce, equals(_kNonce));
    });

    test(
        'innerAddressCredentials returns addressCredentials for ADDRESS_WITH_DELEGATES arm',
        () {
      final inner = SorobanAddressCredentials(
          accountAddr, _kNonce, _kExpiration, XdrSCVal.forVoid());
      final withDels = SorobanAddressCredentialsWithDelegates(inner, []);
      final creds = SorobanCredentials.forAddressWithDelegates(withDels);
      final got = creds.innerAddressCredentials;
      expect(got, isNotNull);
      expect(got!.nonce, equals(_kNonce));
    });

    test(
        'factory arm selection: forAddress/forAddressCredentials build '
        'ADDRESS_V2, Legacy factories build ADDRESS, forAddressV2 unchanged',
        () {
      final inner = SorobanAddressCredentials(
          accountAddr, _kNonce, _kExpiration, XdrSCVal.forVoid());

      final byAddress = SorobanCredentials.forAddress(
          accountAddr, _kNonce, _kExpiration, XdrSCVal.forVoid());
      expect(byAddress.arm,
          equals(XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2));
      expect(byAddress.addressV2Credentials, isNotNull);
      expect(byAddress.addressCredentials, isNull);

      final byCredentials = SorobanCredentials.forAddressCredentials(inner);
      expect(byCredentials.arm,
          equals(XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2));
      expect(byCredentials.addressV2Credentials, isNotNull);
      expect(byCredentials.addressCredentials, isNull);

      final byAddressLegacy = SorobanCredentials.forAddressLegacy(
          accountAddr, _kNonce, _kExpiration, XdrSCVal.forVoid());
      expect(byAddressLegacy.arm,
          equals(XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS));
      expect(byAddressLegacy.addressCredentials, isNotNull);
      expect(byAddressLegacy.addressV2Credentials, isNull);

      final byCredentialsLegacy =
          SorobanCredentials.forAddressCredentialsLegacy(inner);
      expect(byCredentialsLegacy.arm,
          equals(XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS));
      expect(byCredentialsLegacy.addressCredentials, isNotNull);
      expect(byCredentialsLegacy.addressV2Credentials, isNull);

      final byV2 = SorobanCredentials.forAddressV2(inner);
      expect(byV2.arm,
          equals(XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2));
      expect(byV2.addressV2Credentials, isNotNull);
      expect(byV2.addressCredentials, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // GROUP: Golden byte-identity vectors
  // -------------------------------------------------------------------------
  group('Golden byte-identity vectors', () {
    late KeyPair signer;
    late Address accountAddr;
    late SorobanAuthorizedInvocation rootInvocation;

    setUp(() {
      signer = KeyPair.fromSecretSeed(_kSeed);
      accountAddr = Address.forAccountId(signer.accountId);
      rootInvocation = _buildHelloInvocation();
    });

    test('signer account ID matches golden vector', () {
      expect(signer.accountId,
          equals('GCZHXL5HXQX5ABDM26LHYRCQZ5OJFHLOPLZX47WEBP3V2PF5AVFK2A5D'));
    });

    test('legacy ADDRESS preimage matches golden base64', () {
      final creds = SorobanCredentials.forAddressLegacy(
          accountAddr, _kNonce, _kExpiration, XdrSCVal.forVoid());
      final entry = SorobanAuthorizationEntry(creds, rootInvocation);

      final preimage = entry.buildPreimage(Network.TESTNET);
      final encoded = base64Encode(_encodePreimage(preimage));

      expect(encoded, equals(_kLegacyPreimageB64));
    });

    test('legacy ADDRESS payload SHA-256 matches golden hex', () {
      final creds = SorobanCredentials.forAddressLegacy(
          accountAddr, _kNonce, _kExpiration, XdrSCVal.forVoid());
      final entry = SorobanAuthorizationEntry(creds, rootInvocation);

      final preimage = entry.buildPreimage(Network.TESTNET);
      final preimageBytes = _encodePreimage(preimage);
      final payloadHash = Util.hash(preimageBytes);

      expect(_bytesToHex(payloadHash), equals(_kLegacyPayloadHex));
    });

    test('legacy ADDRESS Ed25519 signature matches golden hex', () {
      final creds = SorobanCredentials.forAddressLegacy(
          accountAddr, _kNonce, _kExpiration, XdrSCVal.forVoid());
      final entry = SorobanAuthorizationEntry(creds, rootInvocation);

      final preimage = entry.buildPreimage(Network.TESTNET);
      final preimageBytes = _encodePreimage(preimage);
      final payloadHash = Util.hash(preimageBytes);
      final sigBytes = signer.sign(payloadHash);

      // The golden is a 64-byte hex string (128 hex chars); normalize spacing
      final goldenNorm = _kLegacySigHex.replaceAll(' ', '');
      expect(_bytesToHex(sigBytes), equals(goldenNorm));
    });

    test('ADDRESS_V2 preimage matches golden base64', () {
      final inner = SorobanAddressCredentials(
          accountAddr, _kNonce, _kExpiration, XdrSCVal.forVoid());
      final creds = SorobanCredentials.forAddressV2(inner);
      final entry = SorobanAuthorizationEntry(creds, rootInvocation);

      final preimage = entry.buildPreimage(Network.TESTNET);
      final encoded = base64Encode(_encodePreimage(preimage));

      expect(encoded, equals(_kV2PreimageB64));
    });

    test('ADDRESS_V2 payload SHA-256 matches golden hex', () {
      final inner = SorobanAddressCredentials(
          accountAddr, _kNonce, _kExpiration, XdrSCVal.forVoid());
      final creds = SorobanCredentials.forAddressV2(inner);
      final entry = SorobanAuthorizationEntry(creds, rootInvocation);

      final preimage = entry.buildPreimage(Network.TESTNET);
      final preimageBytes = _encodePreimage(preimage);
      final payloadHash = Util.hash(preimageBytes);

      expect(_bytesToHex(payloadHash), equals(_kV2PayloadHex));
    });

    test('forAddress entry matches golden ADDRESS_V2 preimage and payload', () {
      final creds = SorobanCredentials.forAddress(
          accountAddr, _kNonce, _kExpiration, XdrSCVal.forVoid());
      final entry = SorobanAuthorizationEntry(creds, rootInvocation);

      final preimage = entry.buildPreimage(Network.TESTNET);
      final preimageBytes = _encodePreimage(preimage);
      final payloadHash = Util.hash(preimageBytes);

      expect(base64Encode(preimageBytes), equals(_kV2PreimageB64));
      expect(_bytesToHex(payloadHash), equals(_kV2PayloadHex));
    });

    test('ADDRESS and ADDRESS_V2 preimages differ for identical fields', () {
      final inner = SorobanAddressCredentials(
          accountAddr, _kNonce, _kExpiration, XdrSCVal.forVoid());

      final legacyEntry = SorobanAuthorizationEntry(
        SorobanCredentials.forAddressCredentialsLegacy(inner),
        rootInvocation,
      );
      final v2Entry = SorobanAuthorizationEntry(
        SorobanCredentials.forAddressV2(inner),
        rootInvocation,
      );

      final legacyEncoded =
          base64Encode(_encodePreimage(legacyEntry.buildPreimage(Network.TESTNET)));
      final v2Encoded =
          base64Encode(_encodePreimage(v2Entry.buildPreimage(Network.TESTNET)));

      expect(legacyEncoded, isNot(equals(v2Encoded)),
          reason:
              'ADDRESS and ADDRESS_V2 must produce different preimages for the same credentials');
    });
  });

  // -------------------------------------------------------------------------
  // GROUP: Preimage discriminant per arm
  // -------------------------------------------------------------------------
  group('Preimage discriminant per arm', () {
    late Address accountAddr;
    late SorobanAuthorizedInvocation rootInvocation;

    setUp(() {
      final signer = KeyPair.fromSecretSeed(_kSeed);
      accountAddr = Address.forAccountId(signer.accountId);
      rootInvocation = _buildHelloInvocation();
    });

    test('ADDRESS arm -> ENVELOPE_TYPE_SOROBAN_AUTHORIZATION', () {
      final entry = SorobanAuthorizationEntry(
        SorobanCredentials.forAddressLegacy(
            accountAddr, _kNonce, _kExpiration, XdrSCVal.forVoid()),
        rootInvocation,
      );
      final preimage = entry.buildPreimage(Network.TESTNET);
      expect(preimage.discriminant,
          equals(XdrEnvelopeType.ENVELOPE_TYPE_SOROBAN_AUTHORIZATION));
    });

    test('ADDRESS_V2 arm -> ENVELOPE_TYPE_SOROBAN_AUTHORIZATION_WITH_ADDRESS',
        () {
      final inner = SorobanAddressCredentials(
          accountAddr, _kNonce, _kExpiration, XdrSCVal.forVoid());
      final entry = SorobanAuthorizationEntry(
        SorobanCredentials.forAddressV2(inner),
        rootInvocation,
      );
      final preimage = entry.buildPreimage(Network.TESTNET);
      expect(preimage.discriminant,
          equals(XdrEnvelopeType.ENVELOPE_TYPE_SOROBAN_AUTHORIZATION_WITH_ADDRESS));
    });

    test(
        'ADDRESS_WITH_DELEGATES arm -> ENVELOPE_TYPE_SOROBAN_AUTHORIZATION_WITH_ADDRESS',
        () {
      final contractAddr = Address.forContractId(_kContractId);
      final inner = SorobanAddressCredentials(
          accountAddr, _kNonce, _kExpiration, XdrSCVal.forVoid());
      final entry = SorobanAuthorizationEntry.withDelegates(
        SorobanAuthorizationEntry(
          SorobanCredentials.forAddressV2(inner),
          rootInvocation,
        ),
        [SorobanDelegateDescriptor(contractAddr.contractId!)],
        _kExpiration,
      );
      final preimage = entry.buildPreimage(Network.TESTNET);
      expect(preimage.discriminant,
          equals(XdrEnvelopeType.ENVELOPE_TYPE_SOROBAN_AUTHORIZATION_WITH_ADDRESS));
    });

    test('buildPreimage throws for SOURCE_ACCOUNT credentials', () {
      final entry = SorobanAuthorizationEntry(
        SorobanCredentials.forSourceAccount(),
        rootInvocation,
      );
      expect(() => entry.buildPreimage(Network.TESTNET), throwsException);
    });
  });

  // -------------------------------------------------------------------------
  // GROUP: Preimage address binding for WITH_DELEGATES
  // -------------------------------------------------------------------------
  group('Preimage address == top-level credential address for WITH_DELEGATES',
      () {
    test(
        'WITH_DELEGATES preimage address is the top-level credential address, not a delegate',
        () {
      final signer = KeyPair.fromSecretSeed(_kSeed);
      final accountAddr = Address.forAccountId(signer.accountId);
      final contractAddr = Address.forContractId(_kContractId);
      final inner = SorobanAddressCredentials(
          accountAddr, _kNonce, _kExpiration, XdrSCVal.forVoid());
      final entry = SorobanAuthorizationEntry.withDelegates(
        SorobanAuthorizationEntry(
          SorobanCredentials.forAddressV2(inner),
          _buildHelloInvocation(),
        ),
        [SorobanDelegateDescriptor(contractAddr.contractId!)],
        _kExpiration,
      );

      final preimage = entry.buildPreimage(Network.TESTNET);
      final withAddr = preimage.sorobanAuthorizationWithAddress;
      expect(withAddr, isNotNull);

      // The address in the preimage must be the account (top-level), not the contract delegate
      expect(withAddr!.address.discriminant,
          equals(XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT));
      final preimageAddrKey =
          KeyPair.fromXdrPublicKey(withAddr.address.accountId!.accountID)
              .accountId;
      expect(preimageAddrKey, equals(signer.accountId));
    });
  });

  // -------------------------------------------------------------------------
  // GROUP: Expiration-before-hash
  // -------------------------------------------------------------------------
  group('Expiration is stamped before hashing', () {
    test(
        'sign() uses the signatureExpirationLedger set on credentials at call time',
        () {
      final signer = KeyPair.fromSecretSeed(_kSeed);
      final accountAddr = Address.forAccountId(signer.accountId);

      // Build entry with stale expiration
      final creds = SorobanCredentials.forAddressLegacy(
          accountAddr, _kNonce, 100, XdrSCVal.forVoid());
      final entry = SorobanAuthorizationEntry(creds, _buildHelloInvocation());

      // Update expiration before signing (simulates "set expiration then sign")
      entry.credentials.addressCredentials!.signatureExpirationLedger =
          _kExpiration;
      entry.sign(signer, Network.TESTNET);

      // The signed hash should match the golden vector for expiration=4242
      final inner = entry.credentials.addressCredentials!;
      expect(inner.signatureExpirationLedger, equals(_kExpiration));

      // Verify the signature produced matches the golden vector
      final sig = inner.signature;
      expect(sig.vec, isNotNull);
      expect(sig.vec!.length, equals(1));

      final sigMap = sig.vec!.first.map!;
      final sigEntry = sigMap.firstWhere((e) =>
          e.key.sym != null && e.key.sym == 'signature');
      final actualSig = sigEntry.val.bytes!.sCBytes;
      final goldenNorm = _kLegacySigHex.replaceAll(' ', '');
      expect(_bytesToHex(actualSig), equals(goldenNorm));
    });
  });

  // -------------------------------------------------------------------------
  // GROUP: Delegate sort order (XDR bytes, not strkey)
  // -------------------------------------------------------------------------
  group('Delegate sort order is by XDR-encoded address bytes', () {
    test('G-address sorts before C-address (XDR byte order, opposite strkey)',
        () {
      final signer = KeyPair.fromSecretSeed(_kSeed);
      // strkey "C" < "G" alphabetically, but XDR account-type (0) < contract-type (1)
      // so the G-address should appear first in XDR sort order.
      final accountStrKey = signer.accountId; // G...
      final contractStrKey = _kContractId;    // C...

      final accountXdrAddr = XdrSCAddress.forAccountId(accountStrKey);
      final contractXdrAddr = XdrSCAddress.forContractId(contractStrKey);

      final accountBytes = _encodeXdrSCAddress(accountXdrAddr);
      final contractBytes = _encodeXdrSCAddress(contractXdrAddr);

      // Verify that in XDR bytes, account < contract (first differing byte)
      int cmp = 0;
      for (int i = 0; i < accountBytes.length && i < contractBytes.length; i++) {
        cmp = accountBytes[i].compareTo(contractBytes[i]);
        if (cmp != 0) break;
      }
      expect(cmp, lessThan(0),
          reason:
              'Account address (type=0) must XDR-sort before contract address (type=1)');

      // Build a with-delegates entry putting the contract address FIRST in input
      final inner = SorobanAddressCredentials(
          Address.forAccountId(accountStrKey), _kNonce, _kExpiration, XdrSCVal.forVoid());
      final entry = SorobanAuthorizationEntry.withDelegates(
        SorobanAuthorizationEntry(
          SorobanCredentials.forAddressV2(inner),
          _buildHelloInvocation(),
        ),
        [
          SorobanDelegateDescriptor(contractStrKey), // C... first in input
          SorobanDelegateDescriptor(accountStrKey),  // G... second in input
        ],
        _kExpiration,
      );

      final delegates =
          entry.credentials.addressWithDelegatesCredentials!.delegates;
      expect(delegates.length, equals(2));
      // After sort: G-address (account) must be at index 0
      expect(delegates[0].address.discriminant,
          equals(XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT),
          reason:
              'G-address must sort to index 0 because XDR type-0 < type-1');
      expect(delegates[1].address.discriminant,
          equals(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT));
    });

    test('duplicate address within one delegate array throws', () {
      final signer = KeyPair.fromSecretSeed(_kSeed);
      final accountAddr = Address.forAccountId(signer.accountId);
      final inner = SorobanAddressCredentials(
          accountAddr, _kNonce, _kExpiration, XdrSCVal.forVoid());

      expect(
        () => SorobanAuthorizationEntry.withDelegates(
          SorobanAuthorizationEntry(
            SorobanCredentials.forAddressV2(inner),
            _buildHelloInvocation(),
          ),
          [
            SorobanDelegateDescriptor(_kContractId),
            SorobanDelegateDescriptor(_kContractId), // duplicate
          ],
          _kExpiration,
        ),
        throwsArgumentError,
        reason: 'Duplicate address within one array must throw',
      );
    });

    test('same address at two different levels is legal', () {
      final signer = KeyPair.fromSecretSeed(_kSeed);
      final accountAddr = Address.forAccountId(signer.accountId);
      final inner = SorobanAddressCredentials(
          accountAddr, _kNonce, _kExpiration, XdrSCVal.forVoid());

      // Contract address both as top-level delegate and nested delegate
      expect(
        () => SorobanAuthorizationEntry.withDelegates(
          SorobanAuthorizationEntry(
            SorobanCredentials.forAddressV2(inner),
            _buildHelloInvocation(),
          ),
          [
            SorobanDelegateDescriptor(_kContractId, nestedDelegates: [
              SorobanDelegateDescriptor(_kContractId),
            ]),
          ],
          _kExpiration,
        ),
        returnsNormally,
        reason:
            'Same address at two different nesting levels must be accepted',
      );
    });
  });

  // -------------------------------------------------------------------------
  // GROUP: withDelegates factory constraints
  // -------------------------------------------------------------------------
  group('SorobanAuthorizationEntry.withDelegates constraints', () {
    late SorobanAuthorizedInvocation rootInvocation;
    late SorobanAddressCredentials inner;

    setUp(() {
      final signer = KeyPair.fromSecretSeed(_kSeed);
      rootInvocation = _buildHelloInvocation();
      inner = SorobanAddressCredentials(
          Address.forAccountId(signer.accountId),
          _kNonce,
          _kExpiration,
          XdrSCVal.forVoid());
    });

    test('source entry already WITH_DELEGATES throws', () {
      final v2Entry = SorobanAuthorizationEntry(
          SorobanCredentials.forAddressV2(inner), rootInvocation);
      final withDelEntry = SorobanAuthorizationEntry.withDelegates(
          v2Entry, [SorobanDelegateDescriptor(_kContractId)], _kExpiration);

      expect(
        () => SorobanAuthorizationEntry.withDelegates(
            withDelEntry, [SorobanDelegateDescriptor(_kContractId)],
            _kExpiration),
        throwsArgumentError,
        reason: 'Nesting WITH_DELEGATES inside WITH_DELEGATES must throw',
      );
    });

    test('source entry with SOURCE_ACCOUNT credentials throws', () {
      final sourceEntry = SorobanAuthorizationEntry(
          SorobanCredentials.forSourceAccount(), rootInvocation);

      expect(
        () => SorobanAuthorizationEntry.withDelegates(
            sourceEntry, [SorobanDelegateDescriptor(_kContractId)],
            _kExpiration),
        throwsArgumentError,
        reason:
            'SOURCE_ACCOUNT entry used as source for withDelegates must throw',
      );
    });

    test('muxed address (M...) as delegate throws', () {
      final muxedAddr =
          'MAAAAAAAAAAAJURAAB2X52XFQP6FBXLGT6LWOOWMEXWHEWBDVRZ7V5WH34Y22MPFBHUHY';
      final entry = SorobanAuthorizationEntry(
          SorobanCredentials.forAddressV2(inner), rootInvocation);

      expect(
        () => SorobanAuthorizationEntry.withDelegates(
            entry, [SorobanDelegateDescriptor(muxedAddr)], _kExpiration),
        throwsArgumentError,
        reason: 'Muxed addresses must be rejected as delegate addresses',
      );
    });

    test(
        'withDelegates from ADDRESS arm source produces WITH_DELEGATES result',
        () {
      final addressEntry = SorobanAuthorizationEntry(
          SorobanCredentials.forAddressCredentialsLegacy(inner),
          rootInvocation);

      final result = SorobanAuthorizationEntry.withDelegates(
          addressEntry, [SorobanDelegateDescriptor(_kContractId)], _kExpiration);

      expect(result.credentials.arm,
          equals(XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_WITH_DELEGATES));
    });

    test('top-level signature is void after withDelegates', () {
      final v2Entry = SorobanAuthorizationEntry(
          SorobanCredentials.forAddressV2(inner), rootInvocation);
      final result = SorobanAuthorizationEntry.withDelegates(
          v2Entry, [SorobanDelegateDescriptor(_kContractId)], _kExpiration);

      final topSig = result.credentials.addressWithDelegatesCredentials!
          .addressCredentials.signature;
      expect(topSig.discriminant, equals(XdrSCValType.SCV_VOID),
          reason: 'Top-level signature must default to void');
    });

    test('signatureExpirationLedger is stamped from parameter', () {
      final v2Entry = SorobanAuthorizationEntry(
          SorobanCredentials.forAddressV2(inner), rootInvocation);
      final newExpiration = 9999;
      final result = SorobanAuthorizationEntry.withDelegates(
          v2Entry, [SorobanDelegateDescriptor(_kContractId)], newExpiration);

      expect(
          result.credentials.addressWithDelegatesCredentials!.addressCredentials
              .signatureExpirationLedger,
          equals(newExpiration));
    });
  });

  // -------------------------------------------------------------------------
  // GROUP: sign() forAddress routing
  // -------------------------------------------------------------------------
  group('sign() with forAddress routing', () {
    late KeyPair signer;
    late SorobanAuthorizedInvocation rootInvocation;

    setUp(() {
      signer = KeyPair.fromSecretSeed(_kSeed);
      rootInvocation = _buildHelloInvocation();
    });

    test('forAddress null signs top-level ADDRESS arm', () {
      final creds = SorobanCredentials.forAddressLegacy(
          Address.forAccountId(signer.accountId),
          _kNonce,
          _kExpiration,
          XdrSCVal.forVoid());
      final entry = SorobanAuthorizationEntry(creds, rootInvocation);

      entry.sign(signer, Network.TESTNET); // forAddress == null

      final inner = entry.credentials.addressCredentials!;
      expect(inner.signature.vec, isNotNull);
      expect(inner.signature.vec!.length, equals(1));
    });

    test('forAddress matching top-level address routes to top-level', () {
      final inner = SorobanAddressCredentials(
          Address.forAccountId(signer.accountId),
          _kNonce,
          _kExpiration,
          XdrSCVal.forVoid());
      final creds = SorobanCredentials.forAddressV2(inner);
      final entry = SorobanAuthorizationEntry(creds, rootInvocation);

      entry.sign(signer, Network.TESTNET, forAddress: signer.accountId);

      expect(entry.credentials.addressV2Credentials!.signature.vec, isNotNull);
      expect(
          entry.credentials.addressV2Credentials!.signature.vec!.length,
          equals(1));
    });

    test(
        'forAddress with distinct top-level (A) and delegate (B): signs both nodes independently',
        () {
      // Build a delegate keypair distinct from the top-level signer
      final delegateKp =
          KeyPair.fromSecretSeed('SCZANGBA5YHTNYVVV4C3U252E2B6P6F5T3U6MM63WBSBZATAQI3EBTQ4');

      final topAddr = Address.forAccountId(signer.accountId);
      final delegateAddr = delegateKp.accountId; // C or G

      final inner = SorobanAddressCredentials(
          topAddr, _kNonce, _kExpiration, XdrSCVal.forVoid());

      final entry = SorobanAuthorizationEntry.withDelegates(
        SorobanAuthorizationEntry(
          SorobanCredentials.forAddressV2(inner),
          rootInvocation,
        ),
        [SorobanDelegateDescriptor(delegateAddr)],
        _kExpiration,
      );

      // Sign top-level with signer A
      entry.sign(signer, Network.TESTNET, forAddress: signer.accountId);
      // Sign delegate with signer B
      entry.sign(delegateKp, Network.TESTNET, forAddress: delegateAddr);

      final topSig =
          entry.credentials.addressWithDelegatesCredentials!.addressCredentials.signature;
      expect(topSig.vec, isNotNull);
      expect(topSig.vec!.length, equals(1),
          reason: 'Top-level must have exactly 1 signature');

      final delegates =
          entry.credentials.addressWithDelegatesCredentials!.delegates;
      expect(delegates[0].signature.vec, isNotNull);
      expect(delegates[0].signature.vec!.length, equals(1),
          reason: 'Delegate must have exactly 1 signature');
    });

    test('forAddress no match throws', () {
      final creds = SorobanCredentials.forAddress(
          Address.forAccountId(signer.accountId),
          _kNonce,
          _kExpiration,
          XdrSCVal.forVoid());
      final entry = SorobanAuthorizationEntry(creds, rootInvocation);

      expect(
        () => entry.sign(signer, Network.TESTNET,
            forAddress: _kContractId),
        throwsException,
        reason: 'forAddress with no matching node must throw',
      );
    });

    test('forAddress with muxed address (M...) throws', () {
      final creds = SorobanCredentials.forAddress(
          Address.forAccountId(signer.accountId),
          _kNonce,
          _kExpiration,
          XdrSCVal.forVoid());
      final entry = SorobanAuthorizationEntry(creds, rootInvocation);
      const muxed =
          'MAAAAAAAAAAAJURAAB2X52XFQP6FBXLGT6LWOOWMEXWHEWBDVRZ7V5WH34Y22MPFBHUHY';

      expect(
        () => entry.sign(signer, Network.TESTNET, forAddress: muxed),
        throwsException,
        reason: 'Muxed address target must throw',
      );
    });

    test('signing source-account credentials throws', () {
      final entry = SorobanAuthorizationEntry(
          SorobanCredentials.forSourceAccount(), rootInvocation);

      expect(
        () => entry.sign(signer, Network.TESTNET),
        throwsException,
        reason: 'Signing source-account entry must throw',
      );
    });
  });

  // -------------------------------------------------------------------------
  // GROUP: Append semantics
  // -------------------------------------------------------------------------
  group('Append semantics for signature vectors', () {
    late KeyPair signer;
    late KeyPair signer2;
    late SorobanAuthorizedInvocation rootInvocation;

    setUp(() {
      signer = KeyPair.fromSecretSeed(_kSeed);
      signer2 = KeyPair.fromSecretSeed(
          'SCZANGBA5YHTNYVVV4C3U252E2B6P6F5T3U6MM63WBSBZATAQI3EBTQ4');
      rootInvocation = _buildHelloInvocation();
    });

    test('void top-level becomes one-element vec after first sign()', () {
      final creds = SorobanCredentials.forAddress(
          Address.forAccountId(signer.accountId),
          _kNonce,
          _kExpiration,
          XdrSCVal.forVoid());
      final entry = SorobanAuthorizationEntry(creds, rootInvocation);

      expect(entry.credentials.innerAddressCredentials!.signature.discriminant,
          equals(XdrSCValType.SCV_VOID));

      entry.sign(signer, Network.TESTNET);

      expect(entry.credentials.innerAddressCredentials!.signature.vec,
          isNotNull);
      expect(entry.credentials.innerAddressCredentials!.signature.vec!.length,
          equals(1));
    });

    test('second sign() appends without removing existing signature', () {
      final creds = SorobanCredentials.forAddress(
          Address.forAccountId(signer.accountId),
          _kNonce,
          _kExpiration,
          XdrSCVal.forVoid());
      final entry = SorobanAuthorizationEntry(creds, rootInvocation);

      entry.sign(signer, Network.TESTNET);
      entry.sign(signer2, Network.TESTNET);

      expect(entry.credentials.innerAddressCredentials!.signature.vec!.length,
          equals(2));
    });
  });

  // -------------------------------------------------------------------------
  // GROUP: Decode depth guard
  // -------------------------------------------------------------------------
  group('Decode depth guard for XdrSorobanDelegateSignature', () {
    test('decoding a 130-deep nested tree throws before stack exhaustion', () {
      final deepTree = _build130DeepXdrTree();
      final out = XdrDataOutputStream();
      XdrSorobanDelegateSignature.encode(out, deepTree);
      final encoded = Uint8List.fromList(out.bytes);

      expect(
        () => XdrSorobanDelegateSignature.decode(XdrDataInputStream(encoded)),
        throwsException,
        reason:
            'A 130-deep tree must be rejected by the depth guard (limit=128)',
      );
    });

    test('decoding a shallow tree succeeds', () {
      final signer = KeyPair.fromSecretSeed(_kSeed);
      final addr = XdrSCAddress.forAccountId(signer.accountId);
      // 2 levels deep: root -> child (depth 1 during decode)
      final child = XdrSorobanDelegateSignature(addr, XdrSCVal.forVoid(), []);
      final root = XdrSorobanDelegateSignature(addr, XdrSCVal.forVoid(), [child]);

      final out = XdrDataOutputStream();
      XdrSorobanDelegateSignature.encode(out, root);
      final encoded = Uint8List.fromList(out.bytes);

      final decoded =
          XdrSorobanDelegateSignature.decode(XdrDataInputStream(encoded));
      expect(decoded.nestedDelegates.length, equals(1));
    });
  });

  // -------------------------------------------------------------------------
  // GROUP: SorobanAuthorizationEntry TxRep round-trip for P27 arms
  // -------------------------------------------------------------------------
  group('SorobanAuthorizationEntry TxRep round-trip (P27 arms)', () {
    late KeyPair signer;
    late Address accountAddr;
    late SorobanAuthorizedInvocation rootInvocation;

    setUp(() {
      signer = KeyPair.fromSecretSeed(_kSeed);
      accountAddr = Address.forAccountId(signer.accountId);
      rootInvocation = _buildHelloInvocation();
    });

    test('ADDRESS_V2 entry TxRep round-trip', () {
      final inner = SorobanAddressCredentials(
          accountAddr, _kNonce, _kExpiration, XdrSCVal.forVoid());
      final entry = SorobanAuthorizationEntry(
          SorobanCredentials.forAddressV2(inner), rootInvocation);

      // Encode to XDR base64 and decode back
      final b64 = entry.toBase64EncodedXdrString();
      final restored = SorobanAuthorizationEntry.fromBase64EncodedXdr(b64);

      expect(restored.credentials.arm,
          equals(XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2));
      expect(restored.credentials.addressV2Credentials, isNotNull);
      expect(
          restored.credentials.addressV2Credentials!.signatureExpirationLedger,
          equals(_kExpiration));
    });

    test(
        'ADDRESS_WITH_DELEGATES entry XDR round-trip with non-empty delegates',
        () {
      final contractAddr = Address.forContractId(_kContractId);
      final inner = SorobanAddressCredentials(
          accountAddr, _kNonce, _kExpiration, XdrSCVal.forVoid());
      final entry = SorobanAuthorizationEntry.withDelegates(
        SorobanAuthorizationEntry(
          SorobanCredentials.forAddressV2(inner),
          rootInvocation,
        ),
        [
          SorobanDelegateDescriptor(contractAddr.contractId!,
              nestedDelegates: [
                SorobanDelegateDescriptor(signer.accountId),
              ]),
        ],
        _kExpiration,
      );

      final b64 = entry.toBase64EncodedXdrString();
      final restored = SorobanAuthorizationEntry.fromBase64EncodedXdr(b64);

      expect(
          restored.credentials.arm,
          equals(XdrSorobanCredentialsType
              .SOROBAN_CREDENTIALS_ADDRESS_WITH_DELEGATES));
      expect(restored.credentials.addressWithDelegatesCredentials, isNotNull);

      final delegates =
          restored.credentials.addressWithDelegatesCredentials!.delegates;
      expect(delegates.length, equals(1));
      // The delegate is the contract (C...) — it sorted after the account in XDR
      // Wait: entry has only one top-level delegate (contract), with one nested (account).
      // After XDR round-trip, the nested delegate under the contract should be the account.
      final nested = delegates[0].nestedDelegates;
      expect(nested.length, equals(1),
          reason: 'Nested delegate must survive XDR round-trip');
    });
  });

  // -------------------------------------------------------------------------
  // GROUP: Missing private key / wrong address error paths
  // -------------------------------------------------------------------------
  group('Error paths', () {
    late KeyPair signer;
    late SorobanAuthorizedInvocation rootInvocation;

    setUp(() {
      signer = KeyPair.fromSecretSeed(_kSeed);
      rootInvocation = _buildHelloInvocation();
    });

    test(
        'ADDRESS_V2 arm: signing with non-matching forAddress on ADDRESS-only entry throws',
        () {
      final inner = SorobanAddressCredentials(
          Address.forAccountId(signer.accountId),
          _kNonce,
          _kExpiration,
          XdrSCVal.forVoid());
      final entry = SorobanAuthorizationEntry(
          SorobanCredentials.forAddressV2(inner), rootInvocation);

      // Request signature for a contract address that is not a delegate or top-level
      expect(
        () => entry.sign(signer, Network.TESTNET, forAddress: _kContractId),
        throwsException,
        reason: 'No node matches forAddress in V2 entry, must throw',
      );
    });

    test(
        'ADDRESS_WITH_DELEGATES arm: signing with non-matching forAddress throws',
        () {
      final nonExistentAddr = KeyPair.random().accountId;
      final inner = SorobanAddressCredentials(
          Address.forAccountId(signer.accountId),
          _kNonce,
          _kExpiration,
          XdrSCVal.forVoid());
      final entry = SorobanAuthorizationEntry.withDelegates(
        SorobanAuthorizationEntry(
          SorobanCredentials.forAddressV2(inner),
          rootInvocation,
        ),
        [SorobanDelegateDescriptor(_kContractId)],
        _kExpiration,
      );

      expect(
        () => entry.sign(signer, Network.TESTNET, forAddress: nonExistentAddr),
        throwsException,
        reason: 'Non-matching forAddress in WITH_DELEGATES entry must throw',
      );
    });
  });
}
