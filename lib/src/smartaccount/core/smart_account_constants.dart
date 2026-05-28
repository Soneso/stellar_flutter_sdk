// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

/// Cryptographic and protocol-level constants for Smart Account operations.
///
/// These constants describe public-key sizes and the uncompressed-point prefix
/// byte used by the elliptic-curve schemes that Smart Account signers support.
class SmartAccountConstants {
  /// Private constructor prevents instantiation; this class exposes only static constants.
  SmartAccountConstants._();

  /// Size in bytes of an Ed25519 public key (RFC 8032).
  static const int ed25519PublicKeySize = 32;

  /// Size in bytes of an Ed25519 secret seed (deterministic key material from
  /// which the keypair is derived). Required by
  /// [OZExternalSignerManager.addEd25519FromRawKey].
  static const int ed25519SecretSeedSize = 32;

  /// Size in bytes of a raw Ed25519 signature (the on-wire `BytesN<64>` payload
  /// the Ed25519 verifier contract expects).
  static const int ed25519SignatureSize = 64;

  /// Size in bytes of an uncompressed secp256r1 public key
  /// (1 prefix byte + 32 x-coordinate bytes + 32 y-coordinate bytes).
  static const int secp256r1PublicKeySize = 65;

  /// Uncompressed point prefix byte (`0x04`) as defined in SEC 1 for
  /// secp256r1 public keys. The byte is intentionally typed as a small
  /// integer; comparisons should be performed against this constant rather
  /// than the literal `0x04` so the intent is self-documenting.
  static const int uncompressedPubkeyPrefix = 0x04;
}
