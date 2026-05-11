// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import '../../util.dart';
import '../../xdr/xdr.dart';
import '../core/smart_account_constants.dart';
import '../core/smart_account_errors.dart';

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
/// Instances are immutable value types and may be safely shared across Dart
/// isolates; concrete subtypes preserve this guarantee.
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

  /// Converts this signature to its [XdrSCVal] representation.
  ///
  /// The keys in the resulting map are alphabetically sorted because the
  /// OpenZeppelin Smart Account verifier contract requires that ordering.
  XdrSCVal toScVal();
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
/// Instances are immutable value types and may be safely shared across Dart
/// isolates. The byte fields are defensively copied at construction.
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

  /// Constant-time equality.
  ///
  /// Each byte field is compared using [Util.constantTimeEquals]
  /// and the three boolean results are combined with bitwise `and` (rather
  /// than the short-circuit `&&` operator) so that a difference in one
  /// field cannot leak through the timing of the boolean reduction.
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
    var result = _byteListContentHash(authenticatorData);
    result = 0x1fffffff & (31 * result + _byteListContentHash(clientData));
    result = 0x1fffffff & (31 * result + _byteListContentHash(signature));
    return result;
  }
}

/// Ed25519 signature from a traditional keypair.
///
/// Ed25519 signatures are 64 bytes and provide deterministic signing with
/// strong side-channel resistance.
///
/// Field ordering in the SCVal map is alphabetical and is critical for
/// contract compatibility:
///
/// 1. `public_key`
/// 2. `signature`
///
/// Instances are immutable value types and may be safely shared across Dart
/// isolates. The byte fields are defensively copied at construction.
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
  final Uint8List publicKey;

  /// Ed25519 signature (64 bytes).
  final Uint8List signature;

  /// Converts the Ed25519 signature to a Soroban [XdrSCVal] map.
  ///
  /// The resulting map has keys in alphabetical order (`public_key`,
  /// `signature`).
  @override
  XdrSCVal toScVal() {
    return XdrSCVal.forMap([
      XdrSCMapEntry(
        XdrSCVal.forSymbol('public_key'),
        XdrSCVal.forBytes(publicKey),
      ),
      XdrSCMapEntry(
        XdrSCVal.forSymbol('signature'),
        XdrSCVal.forBytes(signature),
      ),
    ]);
  }

  /// Constant-time equality.
  ///
  /// Both byte fields are compared using
  /// [Util.constantTimeEquals]; the boolean results are
  /// combined with bitwise `and` to avoid early-exit timing leaks.
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
    var result = _byteListContentHash(publicKey);
    result = 0x1fffffff & (31 * result + _byteListContentHash(signature));
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
///
/// The canonical instance may be shared across any number of isolates.
final class OZPolicySignature extends OZSmartAccountSignature {
  const OZPolicySignature._();

  /// Canonical singleton instance.
  static const OZPolicySignature instance = OZPolicySignature._();

  /// Converts the policy signature to an empty Soroban [XdrSCVal] map.
  @override
  XdrSCVal toScVal() {
    return XdrSCVal.forMap(const <XdrSCMapEntry>[]);
  }
}

/// Polynomial content-hash for byte arrays, matching the convention used
/// by the rest of the smart-account library (`31 * acc + byte`).
int _byteListContentHash(Uint8List bytes) {
  var hash = 1;
  for (final b in bytes) {
    hash = 0x1fffffff & (31 * hash + (b & 0xFF));
  }
  return hash;
}
