// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'allow_credential.dart';
import 'smart_account_errors.dart';

/// WebAuthn authentication result from a passkey ceremony.
///
/// Contains the complete attestation data required to verify biometric or
/// security-key authentication. Equality is byte-content based on every field.
class WebAuthnAuthenticationResult {
  final Uint8List credentialId;
  final Uint8List authenticatorData;
  final Uint8List clientDataJSON;

  /// ECDSA signature in DER format. Callers normalise this to 64-byte compact
  /// `r || s` form before submitting on-chain; the field stores the unmodified
  /// DER bytes returned by the platform authenticator.
  final Uint8List signature;

  const WebAuthnAuthenticationResult({
    required this.credentialId,
    required this.authenticatorData,
    required this.clientDataJSON,
    required this.signature,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! WebAuthnAuthenticationResult) return false;
    final a = _constantTimeEquals(credentialId, other.credentialId);
    final b = _constantTimeEquals(authenticatorData, other.authenticatorData);
    final c = _constantTimeEquals(clientDataJSON, other.clientDataJSON);
    final d = _constantTimeEquals(signature, other.signature);
    return a && b && c && d;
  }

  @override
  int get hashCode {
    var result = _byteListHash(credentialId);
    result = 31 * result + _byteListHash(authenticatorData);
    result = 31 * result + _byteListHash(clientDataJSON);
    result = 31 * result + _byteListHash(signature);
    return result;
  }
}

/// WebAuthn registration result from a passkey creation ceremony.
///
/// Contains the public key and credential information needed to deploy a
/// smart-account contract, plus optional metadata about the authenticator
/// and passkey characteristics. Equality is byte-content based on the three
/// required byte fields and value-equal on the optional metadata fields.
class WebAuthnRegistrationResult {
  /// The WebAuthn credential identifier (raw bytes).
  final Uint8List credentialId;

  /// Uncompressed secp256r1 public key (65 bytes, starting with `0x04`).
  ///
  /// This is the primary extraction path. If the platform WebAuthn API wraps
  /// the key in COSE/SPKI encoding, pass the raw bytes here and rely on the
  /// 3-strategy extraction utility for fallback decoding.
  final Uint8List publicKey;

  /// Raw attestation object from WebAuthn registration.
  ///
  /// Always provided by the WebAuthn ceremony. Used for public-key extraction
  /// when the platform returns the key in COSE or SPKI encoding rather than
  /// as a raw 65-byte uncompressed key.
  final Uint8List attestationObject;

  /// Authenticator transport hints indicating how the browser/OS can
  /// communicate with the authenticator (`usb`, `nfc`, `ble`, `internal`,
  /// `hybrid`).
  ///
  /// Used when constructing allow-credential lists for future authentication
  /// ceremonies.
  final List<String>? transports;

  /// Authenticator device type: `singleDevice` for hardware security keys or
  /// `multiDevice` for synced/cloud-backed passkeys. Corresponds to the
  /// `credentialDeviceType` field derived from WebAuthn authenticator-data
  /// flags.
  final String? deviceType;

  /// Whether the passkey is currently backed up or synced to a cloud
  /// provider. When `true`, the credential is available across the user's
  /// devices. Corresponds to the `credentialBackedUp` flag in WebAuthn
  /// authenticator data.
  final bool? backedUp;

  /// Constructs a [WebAuthnRegistrationResult]. The three byte-array fields
  /// are required; the metadata fields default to `null`.
  const WebAuthnRegistrationResult({
    required this.credentialId,
    required this.publicKey,
    required this.attestationObject,
    this.transports,
    this.deviceType,
    this.backedUp,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! WebAuthnRegistrationResult) return false;
    final a = _constantTimeEquals(credentialId, other.credentialId);
    final b = _constantTimeEquals(publicKey, other.publicKey);
    final c = _constantTimeEquals(attestationObject, other.attestationObject);
    final bytesMatch = a && b && c;
    return bytesMatch &&
        _stringListEquals(transports, other.transports) &&
        deviceType == other.deviceType &&
        backedUp == other.backedUp;
  }

  @override
  int get hashCode {
    var result = _byteListHash(credentialId);
    result = 31 * result + _byteListHash(publicKey);
    result = 31 * result + _byteListHash(attestationObject);
    result = 31 * result +
        (transports == null ? 0 : Object.hashAll(transports as Iterable<Object?>));
    result = 31 * result + (deviceType == null ? 0 : deviceType.hashCode);
    result = 31 * result + (backedUp == null ? 0 : backedUp.hashCode);
    return result;
  }
}

/// Platform-specific WebAuthn provider interface.
///
/// Implementations trigger platform-specific biometric or security-key
/// prompts, handle WebAuthn credential creation and assertion, and return
/// properly formatted results with raw byte arrays.
///
/// Each platform target (Apple, Android, Web) ships its own concrete
/// implementation; this interface is the contract those implementations
/// satisfy.
///
/// Concrete implementations performing native platform calls typically must
/// run on the platform's UI thread; such implementations SHOULD declare any
/// isolate-affinity restrictions in their own dartdoc.
abstract class WebAuthnProvider {
  const WebAuthnProvider();

  /// Registers a new WebAuthn credential (passkey creation).
  ///
  /// Triggers the platform's credential-creation flow, prompting the user to
  /// create a new passkey using biometric authentication or a security key,
  /// generates a secp256r1 keypair and credential ID, and returns the public
  /// key and attestation data.
  ///
  /// IMPORTANT: the [challenge] parameter MUST be used as-is in the WebAuthn
  /// registration request. It is a cryptographic hash that binds the
  /// credential to the smart-account deployment.
  ///
  /// - [challenge] The challenge bytes to sign (typically 32 bytes).
  /// - [userId] User identifier bytes (typically random; used for
  ///   discoverable credentials).
  /// - [userName] User-friendly name for the credential.
  ///
  /// Returns a [WebAuthnRegistrationResult] with credential ID, public key,
  /// and attestation data.
  ///
  /// Throws [WebAuthnException] (specifically
  /// [WebAuthnRegistrationFailed], [WebAuthnNotSupported], or
  /// [WebAuthnCancelled]) if registration fails or the user cancels.
  Future<WebAuthnRegistrationResult> register({
    required Uint8List challenge,
    required Uint8List userId,
    required String userName,
  });

  /// Authenticates with an existing WebAuthn credential (passkey assertion).
  ///
  /// Triggers the platform's credential-assertion flow, prompting the user
  /// to authenticate with their passkey using biometric authentication or a
  /// security key, signs the challenge, and returns the signature and
  /// authenticator data.
  ///
  /// IMPORTANT: the [challenge] parameter MUST be used as-is in the WebAuthn
  /// authentication request. It is the authorization payload hash that
  /// authorises the transaction.
  ///
  /// - [challenge] The challenge bytes to sign (authorization payload hash,
  ///   typically 32 bytes).
  /// - [allowCredentials] Optional list of credential descriptors with
  ///   transport hints. Constrains which passkey the authenticator uses and
  ///   indicates how the client can reach the authenticator. When `null`,
  ///   discoverable-credential selection is used (the user picks which
  ///   passkey to use). Including transport hints (e.g. `hybrid`) enables
  ///   cross-device authentication flows such as QR-code scanning.
  ///
  /// Returns a [WebAuthnAuthenticationResult] with signature and attestation
  /// data.
  ///
  /// Throws [WebAuthnException] (specifically
  /// [WebAuthnAuthenticationFailed], [WebAuthnNotSupported], or
  /// [WebAuthnCancelled]) if authentication fails or the user cancels.
  Future<WebAuthnAuthenticationResult> authenticate({
    required Uint8List challenge,
    List<AllowCredential>? allowCredentials,
  });
}

/// Byte-content equality over [a] and [b].
bool _constantTimeEquals(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  var acc = 0;
  for (var i = 0; i < a.length; i++) {
    acc |= a[i] ^ b[i];
  }
  return acc == 0;
}

/// Computes a hash code over the bytes of [data] consistent with the
/// `Arrays.hashCode(byte[])` formula, so that byte-equal arrays hash to the
/// same value.
int _byteListHash(Uint8List data) {
  var result = 1;
  for (var i = 0; i < data.length; i++) {
    result = 31 * result + (data[i] & 0xFF);
  }
  return result;
}

/// Compares two optional string lists. `null` and the empty list are NOT
/// considered equal.
bool _stringListEquals(List<String>? a, List<String>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return false;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
