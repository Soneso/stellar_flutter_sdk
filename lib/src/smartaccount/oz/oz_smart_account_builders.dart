// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import '../../util.dart';
import '../core/smart_account_constants.dart';
import 'oz_base64url.dart';
import 'oz_smart_account_types.dart';

/// Builder utilities for OpenZeppelin Smart Account signers.
///
/// Provides type-safe constructors and helper functions for creating and
/// inspecting OpenZeppelin Smart Account signer types:
///
/// - Signer builders for delegated, external, WebAuthn, and Ed25519 signers.
/// - Signer inspection (type checks, credential and address extraction).
/// - Signer matching (by credential ID, by address, equality).
/// - Signer deduplication.
///
/// All entry points are pure static functions over their arguments.
abstract class OZSmartAccountBuilders {
  OZSmartAccountBuilders._();

  // Signer builders

  /// Factory alias for `OZDelegatedSigner(publicKey)`.
  static OZDelegatedSigner createDelegatedSigner(String publicKey) {
    return OZDelegatedSigner(publicKey);
  }

  /// Factory alias for `OZExternalSigner(verifierAddress, keyData)`.
  static OZExternalSigner createExternalSigner(
    String verifierAddress,
    Uint8List keyData,
  ) {
    return OZExternalSigner(verifierAddress, keyData);
  }

  /// Factory alias for `OZExternalSigner.webAuthn(...)`.
  static OZExternalSigner createWebAuthnSigner({
    required String webauthnVerifierAddress,
    required Uint8List publicKey,
    required Uint8List credentialId,
  }) {
    return OZExternalSigner.webAuthn(
      verifierAddress: webauthnVerifierAddress,
      publicKey: publicKey,
      credentialId: credentialId,
    );
  }

  /// Factory alias for `OZExternalSigner.ed25519(...)`.
  static OZExternalSigner createEd25519Signer({
    required String ed25519VerifierAddress,
    required Uint8List publicKey,
  }) {
    return OZExternalSigner.ed25519(
      verifierAddress: ed25519VerifierAddress,
      publicKey: publicKey,
    );
  }

  // Signer inspection utilities

  /// Extracts the credential ID from a WebAuthn signer's key data.
  ///
  /// WebAuthn signers store their key data as a 65-byte uncompressed
  /// secp256r1 public key followed by the credential ID. Returns `null`
  /// for non-WebAuthn signers (delegated signers, or external signers
  /// whose key data is not longer than 65 bytes).
  static Uint8List? getCredentialIdFromSigner(OZSmartAccountSigner signer) {
    if (signer is! OZExternalSigner) return null;
    if (signer.keyData.length <=
        SmartAccountConstants.secp256r1PublicKeySize) {
      return null;
    }
    return Uint8List.fromList(
      signer.keyData.sublist(
        SmartAccountConstants.secp256r1PublicKeySize,
        signer.keyData.length,
      ),
    );
  }

  /// Extracts the secp256r1 public key from a WebAuthn signer's key data.
  ///
  /// WebAuthn signers store their key data as a 65-byte uncompressed
  /// secp256r1 public key followed by the credential ID. Returns the
  /// 65-byte public key, or `null` for non-WebAuthn signers (delegated
  /// signers, or external signers whose key data is not longer than 65
  /// bytes).
  static Uint8List? getPublicKeyFromSigner(OZSmartAccountSigner signer) {
    if (signer is! OZExternalSigner) return null;
    if (signer.keyData.length <=
        SmartAccountConstants.secp256r1PublicKeySize) {
      return null;
    }
    return Uint8List.fromList(
      signer.keyData.sublist(
        0,
        SmartAccountConstants.secp256r1PublicKeySize,
      ),
    );
  }

  /// Returns the WebAuthn signer credential ID as a Base64URL-encoded
  /// string without trailing `=` padding, or `null` for non-WebAuthn signers.
  ///
  /// Padding is stripped so the value matches the canonical unpadded form
  /// produced by the connect path and recommended by RFC 4648 §5 for URL-
  /// safe Base64 of WebAuthn credential IDs.
  static String? getCredentialIdStringFromSigner(OZSmartAccountSigner signer) {
    final credentialId = getCredentialIdFromSigner(signer);
    if (credentialId == null) return null;
    return ozBase64UrlEncode(credentialId);
  }

  static bool isDelegatedSigner(OZSmartAccountSigner signer) {
    return signer is OZDelegatedSigner;
  }

  static bool isExternalSigner(OZSmartAccountSigner signer) {
    return signer is OZExternalSigner;
  }

  // Signer matching

  /// Returns `true` when [signer] is a WebAuthn signer whose credential ID
  /// matches the given raw [credentialId] bytes.
  static bool signerMatchesCredential(
    OZSmartAccountSigner signer,
    Uint8List credentialId,
  ) {
    final signerCredId = getCredentialIdFromSigner(signer);
    if (signerCredId == null) return false;
    if (signerCredId.length != credentialId.length) return false;
    for (var i = 0; i < signerCredId.length; i++) {
      if (signerCredId[i] != credentialId[i]) return false;
    }
    return true;
  }

  /// Returns `true` when [signer] is a WebAuthn signer whose credential
  /// ID, encoded as Base64URL, equals [credentialId].
  ///
  /// The comparison ignores trailing `=` padding on either side so callers
  /// can pass a credential ID in either the padded or unpadded Base64URL
  /// form interchangeably.
  static bool signerMatchesCredentialId(
    OZSmartAccountSigner signer,
    String credentialId,
  ) {
    final signerCredId = getCredentialIdStringFromSigner(signer);
    if (signerCredId == null) return false;
    return signerCredId == ozStripBase64UrlPadding(credentialId);
  }

  /// Returns `true` when [signer] is an [OZDelegatedSigner] whose address
  /// equals [address].
  static bool signerMatchesAddress(
    OZSmartAccountSigner signer,
    String address,
  ) {
    if (signer is! OZDelegatedSigner) return false;
    return signer.address == address;
  }

  // Signer comparison and deduplication

  /// Compares two signers by type and field values.
  ///
  /// For delegated signers compares the address; for external signers
  /// compares the verifier address and the byte content of the key data.
  static bool signersEqual(OZSmartAccountSigner a, OZSmartAccountSigner b) {
    if (a is OZDelegatedSigner && b is OZDelegatedSigner) {
      return a.address == b.address;
    }
    if (a is OZExternalSigner && b is OZExternalSigner) {
      if (a.verifierAddress != b.verifierAddress) return false;
      return Util.constantTimeEquals(a.keyData, b.keyData);
    }
    return false;
  }

  static String getSignerKey(OZSmartAccountSigner signer) {
    return signer.uniqueKey;
  }

  /// Returns a list of unique signers preserving the first occurrence of
  /// each duplicate.
  ///
  /// Uses [getSignerKey] to determine uniqueness.
  static List<OZSmartAccountSigner> collectUniqueSigners(
    List<OZSmartAccountSigner> signers,
  ) {
    final signerMap = <String, OZSmartAccountSigner>{};
    for (final signer in signers) {
      final key = getSignerKey(signer);
      signerMap.putIfAbsent(key, () => signer);
    }
    return signerMap.values.toList(growable: false);
  }
}
