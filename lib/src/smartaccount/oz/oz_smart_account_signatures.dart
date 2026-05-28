// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import '../../util.dart';
import '../../xdr/xdr.dart';
import '../core/smart_account_constants.dart';
import '../core/smart_account_errors.dart';
import '../core/smart_account_utils.dart';

/// Base sealed class for OpenZeppelin Smart Account signature types.
///
/// The OpenZeppelin Smart Account contract on Stellar Soroban supports multiple
/// signature types for transaction authorisation:
///
/// - [OZWebAuthnSignature]: signatures from passkeys (biometric
///   authentication).
/// - [OZEd25519Signature]: signatures from traditional Ed25519 keypairs.
/// - [OZPolicySignature]: policy-based authorisation, encoded as an empty
///   map.
///
/// Each signature type can be converted to a Soroban [XdrSCVal] map that
/// the OpenZeppelin Smart Account contract can verify.
///
/// Example:
///
/// ```dart
/// final signature = OZWebAuthnSignature(
///   authenticatorData: authenticatorDataBytes,
///   clientData: clientDataBytes,
///   signature: signatureBytes,
/// );
/// final scVal = signature.toScVal();
/// ```
sealed class OZSmartAccountSignature {
  /// Constructs an [OZSmartAccountSignature]; intended for use only by
  /// concrete subtypes within this library.
  const OZSmartAccountSignature();

  /// XDR-encodes [scVal] and returns the resulting bytes.
  ///
  /// Throws [TransactionSigningFailed] when XDR encoding fails.
  /// Used by [OZWebAuthnSignature] and [OZPolicySignature]; not used by
  /// [OZEd25519Signature] (which returns raw bytes without XDR wrapping).
  static Uint8List _encodeScValToBytes(XdrSCVal scVal, String contextLabel) {
    final stream = XdrDataOutputStream();
    try {
      XdrSCVal.encode(stream, scVal);
      return Uint8List.fromList(stream.bytes);
    } catch (e) {
      throw TransactionException.signingFailed(
        'Failed to XDR encode $contextLabel signature ScVal',
        cause: e,
      );
    }
  }

  /// Converts this signature to its [XdrSCVal] on-wire representation.
  ///
  /// The exact shape is variant-dependent: [OZWebAuthnSignature] and
  /// [OZPolicySignature] return an [XdrSCVal] map; [OZEd25519Signature]
  /// returns [XdrSCVal.forBytes] holding the raw 64-byte signature.
  XdrSCVal toScVal();

  /// Returns the raw bytes to embed in the on-wire signers map of the
  /// [OZSmartAccountAuthPayload].
  ///
  /// The content is verifier-dependent:
  ///
  /// | Signature type      | Content                                      |
  /// |---------------------|----------------------------------------------|
  /// | [OZWebAuthnSignature] | XDR-encoded [XdrSCVal] (Map with 3 fields) |
  /// | [OZEd25519Signature]  | Raw 64-byte signature (no XDR wrapper)     |
  /// | [OZPolicySignature]   | XDR-encoded [XdrSCVal] (empty Map)         |
  ///
  /// For [OZEd25519Signature] the Ed25519 verifier contract expects
  /// `BytesN<64>` — exactly 64 raw bytes. XDR-wrapping inflates the
  /// payload beyond 64 bytes, causing the contract to reject it.
  ///
  /// Throws [TransactionSigningFailed] when XDR encoding fails
  /// (WebAuthn and Policy variants only; Ed25519 never throws).
  Uint8List toAuthPayloadBytes();
}

/// WebAuthn signature from a passkey authentication ceremony.
///
/// WebAuthn signatures contain the complete attestation data required to
/// verify biometric or security-key authentication. The `signature` field
/// must be in compact format (64 bytes) with a normalised low-S value to
/// prevent signature malleability.
///
/// Field ordering in the SCVal map is alphabetical and is critical for
/// contract compatibility:
///
/// 1. `authenticator_data`
/// 2. `client_data`
/// 3. `signature`
///
/// The map field name is `client_data`, not `client_data_json`.
///
/// Byte fields are defensively copied at construction.
final class OZWebAuthnSignature extends OZSmartAccountSignature {
  /// Constructs an [OZWebAuthnSignature].
  ///
  /// Throws [InvalidInput] when [signature] is not exactly 64 bytes.
  OZWebAuthnSignature({
    required Uint8List authenticatorData,
    required Uint8List clientData,
    required Uint8List signature,
  })  : authenticatorData = Uint8List.fromList(authenticatorData),
        clientData = Uint8List.fromList(clientData),
        signature = Uint8List.fromList(signature) {
    if (signature.length != 64) {
      throw ValidationException.invalidInput(
        'signature',
        'WebAuthn signature must be exactly 64 bytes, '
            'got ${signature.length}',
      );
    }
  }

  /// Raw authenticator data from the WebAuthn authentication ceremony.
  final Uint8List authenticatorData;

  /// Client data JSON from the WebAuthn ceremony.
  ///
  /// The field is stored as `client_data` in the on-chain map, not as
  /// `client_data_json`.
  final Uint8List clientData;

  /// ECDSA signature in compact 64-byte format (`r || s`).
  ///
  /// The signature must already be normalised (S in the lower half of the
  /// curve order) to avoid signature malleability.
  final Uint8List signature;

  /// Converts the WebAuthn signature to a Soroban [XdrSCVal] map.
  ///
  /// The resulting map has keys in alphabetical order
  /// (`authenticator_data`, `client_data`, `signature`) so the
  /// OpenZeppelin Smart Account contract verifies the signature correctly.
  @override
  XdrSCVal toScVal() {
    return XdrSCVal.forMap([
      XdrSCMapEntry(
        XdrSCVal.forSymbol('authenticator_data'),
        XdrSCVal.forBytes(authenticatorData),
      ),
      XdrSCMapEntry(
        XdrSCVal.forSymbol('client_data'),
        XdrSCVal.forBytes(clientData),
      ),
      XdrSCMapEntry(
        XdrSCVal.forSymbol('signature'),
        XdrSCVal.forBytes(signature),
      ),
    ]);
  }

  /// Returns the XDR-encoded [XdrSCVal] map for inclusion in the on-wire
  /// signers map of [OZSmartAccountAuthPayload].
  ///
  /// The WebAuthn verifier contract deserialises a `WebAuthnSigData` struct
  /// from these bytes, so the full XDR encoding of the 3-field map is
  /// required.
  ///
  /// Throws [TransactionSigningFailed] when XDR encoding fails.
  @override
  Uint8List toAuthPayloadBytes() =>
      OZSmartAccountSignature._encodeScValToBytes(toScVal(), 'WebAuthn');

  /// Byte-content equality across all fields.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OZWebAuthnSignature) return false;
    final a = Util.constantTimeEquals(
        authenticatorData, other.authenticatorData);
    final b =
        Util.constantTimeEquals(clientData, other.clientData);
    final c = Util.constantTimeEquals(signature, other.signature);
    return ((a ? 1 : 0) & (b ? 1 : 0) & (c ? 1 : 0)) == 1;
  }

  /// Content-based hash code combining the three byte fields with a
  /// polynomial accumulator.
  @override
  int get hashCode {
    var result = SmartAccountUtils.hashBytes(1, authenticatorData);
    result = 0x1fffffff & (31 * result + SmartAccountUtils.hashBytes(1, clientData));
    result = 0x1fffffff & (31 * result + SmartAccountUtils.hashBytes(1, signature));
    return result;
  }
}

/// Ed25519 signature from a traditional keypair.
///
/// Ed25519 signatures are 64 bytes and provide deterministic signing with
/// strong side-channel resistance.
///
/// [toScVal] returns the raw 64-byte signature as `XdrSCVal.forBytes(...)`.
/// The Ed25519 verifier contract (`BytesN<64>` expectation) receives the
/// signature directly; the corresponding public key is supplied separately
/// from the smart account's on-chain `External(verifier, key_data)` storage
/// and is NOT transmitted in the auth payload.
///
/// The [publicKey] field is retained on the struct for local Ed25519
/// signature verification before submission. Byte fields are defensively
/// copied at construction.
final class OZEd25519Signature extends OZSmartAccountSignature {
  /// Constructs an [OZEd25519Signature].
  ///
  /// Throws [InvalidInput] when [publicKey] is not exactly
  /// [SmartAccountConstants.ed25519PublicKeySize] bytes, or when
  /// [signature] is not exactly 64 bytes.
  OZEd25519Signature({
    required Uint8List publicKey,
    required Uint8List signature,
  })  : publicKey = Uint8List.fromList(publicKey),
        signature = Uint8List.fromList(signature) {
    if (publicKey.length != SmartAccountConstants.ed25519PublicKeySize) {
      throw ValidationException.invalidInput(
        'publicKey',
        'Ed25519 public key must be exactly '
            '${SmartAccountConstants.ed25519PublicKeySize} bytes, '
            'got ${publicKey.length}',
      );
    }
    if (signature.length != 64) {
      throw ValidationException.invalidInput(
        'signature',
        'Ed25519 signature must be exactly 64 bytes, '
            'got ${signature.length}',
      );
    }
  }

  /// Ed25519 public key (32 bytes).
  ///
  /// Used for local signature verification before the transaction is submitted.
  /// Not transmitted in the on-chain auth payload — the verifier contract
  /// retrieves the public key from its `External(verifier, key_data)` storage.
  final Uint8List publicKey;

  /// Ed25519 signature (64 bytes).
  final Uint8List signature;

  /// Returns the raw 64-byte Ed25519 signature as `XdrSCVal.forBytes(...)`.
  ///
  /// The Ed25519 verifier contract expects `BytesN<64>` directly as `sig_data`.
  /// The public key is supplied separately from the smart account's on-chain
  /// `External(verifier, key_data)` storage and is NOT transmitted here.
  @override
  XdrSCVal toScVal() {
    return XdrSCVal.forBytes(signature);
  }

  /// Returns the raw 64-byte Ed25519 signature for inclusion in the on-wire
  /// signers map of [OZSmartAccountAuthPayload].
  ///
  /// The Ed25519 verifier contract expects `BytesN<64>` — exactly 64 raw
  /// bytes. XDR-wrapping inflates the payload beyond 64 bytes and causes
  /// the verifier to reject it, so no XDR envelope is applied here.
  ///
  /// This method never throws.
  @override
  Uint8List toAuthPayloadBytes() {
    return signature;
  }

  /// Byte-content equality across all fields.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OZEd25519Signature) return false;
    final a = Util.constantTimeEquals(publicKey, other.publicKey);
    final b = Util.constantTimeEquals(signature, other.signature);
    return ((a ? 1 : 0) & (b ? 1 : 0)) == 1;
  }

  /// Content-based hash code combining both byte fields with a polynomial
  /// accumulator.
  @override
  int get hashCode {
    var result = SmartAccountUtils.hashBytes(1, publicKey);
    result = 0x1fffffff & (31 * result + SmartAccountUtils.hashBytes(1, signature));
    return result;
  }
}

/// Policy signature representing policy-based authorisation.
///
/// Policy signatures are encoded as empty maps and indicate that
/// authorisation is determined by the OpenZeppelin Smart Account's policy
/// evaluation (for example spending limits, threshold signatures, or
/// time-based restrictions).
///
/// The class is a singleton; obtain the canonical value via
/// [OZPolicySignature.instance].
final class OZPolicySignature extends OZSmartAccountSignature {
  const OZPolicySignature._();

  /// Canonical singleton instance.
  static const OZPolicySignature instance = OZPolicySignature._();

  /// Converts the policy signature to an empty Soroban [XdrSCVal] map.
  @override
  XdrSCVal toScVal() {
    return XdrSCVal.forMap(const <XdrSCMapEntry>[]);
  }

  /// Returns the XDR-encoded empty [XdrSCVal] map for inclusion in the
  /// on-wire signers map of [OZSmartAccountAuthPayload].
  ///
  /// Policy-based authorisation requires the same XDR encoding that the
  /// policy verifier contract expects when reading the signature slot.
  ///
  /// Throws [TransactionSigningFailed] when XDR encoding fails.
  @override
  Uint8List toAuthPayloadBytes() =>
      OZSmartAccountSignature._encodeScValToBytes(toScVal(), 'Policy');
}

