// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

/// Selects a signer to participate in a multi-signature operation.
///
/// The caller explicitly lists every signer that should sign. There is
/// no implicit connected passkey: to include the connected passkey,
/// supply a [SelectedSignerPasskey] entry referencing it.
sealed class SelectedSigner {
  /// Constructor for the sealed `SelectedSigner` hierarchy.
  const SelectedSigner();
}

/// A WebAuthn passkey signer entry. Each instance triggers one OS
/// WebAuthn authentication prompt.
final class SelectedSignerPasskey extends SelectedSigner {
  /// Constructs a passkey selected-signer entry.
  ///
  /// All fields are optional because the connected passkey can be
  /// referenced via a default-constructed [SelectedSignerPasskey];
  /// non-connected passkeys must populate at least [credentialIdBytes]
  /// (used as the WebAuthn `allowCredentials` constraint) and [keyData]
  /// (used to reconstruct the on-chain external signer for context-rule
  /// resolution).
  const SelectedSignerPasskey({
    this.credentialId,
    this.credentialIdBytes,
    this.keyData,
    this.transports,
  });

  /// Base64URL-encoded credential ID for display and credential lookup.
  final String? credentialId;

  /// Raw credential ID bytes used for the WebAuthn `allowCredentials`
  /// constraint. When `null`, the browser/OS is free to prompt for any
  /// credential.
  final Uint8List? credentialIdBytes;

  /// External-signer key data (uncompressed secp256r1 public key
  /// concatenated with the credential ID bytes, in that order). When
  /// supplied the SDK uses it directly without an on-chain lookup;
  /// `OZMultiSignerManager.submitWithMultipleSigners` requires it to be
  /// non-null.
  final Uint8List? keyData;

  /// Optional WebAuthn transport hints (`internal`, `hybrid`, `usb`,
  /// `nfc`, `ble`) forwarded into the `allowCredentials` entry to drive
  /// cross-device authentication flows. When `credentialIdBytes` is
  /// `null` the transports are also dropped (the multi-signer pipeline
  /// then leaves `allowCredentials` unset entirely, allowing the
  /// browser or OS to surface a credential picker).
  final List<String>? transports;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SelectedSignerPasskey) return false;
    if (credentialId != other.credentialId) return false;
    if (!_bytesEqualNullable(credentialIdBytes, other.credentialIdBytes)) {
      return false;
    }
    if (!_bytesEqualNullable(keyData, other.keyData)) return false;
    if (!_listEqualsNullable(transports, other.transports)) return false;
    return true;
  }

  @override
  int get hashCode => Object.hash(
        credentialId,
        credentialIdBytes == null ? 0 : Object.hashAll(credentialIdBytes!),
        keyData == null ? 0 : Object.hashAll(keyData!),
        transports == null ? 0 : Object.hashAll(transports!),
      );
}

/// An Ed25519 external signer identified by the verifier contract address and
/// 32-byte public key.
///
/// The `(verifierAddress, publicKey)` pair identifies the on-chain
/// `External(verifierAddress, publicKey)` signer slot. Signing capability for
/// this signer must be registered separately via
/// `OZExternalSignerManager.addEd25519FromRawKey` (or by setting an
/// `OZExternalEd25519SignerAdapter`) before including this selector in a
/// multi-signer operation.
///
/// Unlike passkey selectors, this type carries no signing material — it is
/// a pure identifier.
final class SelectedSignerEd25519 extends SelectedSigner {
  /// Constructs an Ed25519 selected-signer entry.
  ///
  /// [verifierAddress] must be a valid C-strkey identifying the Ed25519
  /// verifier contract registered on-chain for this signer slot.
  /// [publicKey] must be the 32-byte Ed25519 public key for the signer.
  const SelectedSignerEd25519({
    required this.verifierAddress,
    required this.publicKey,
  });

  /// C-strkey of the Ed25519 verifier contract registered as part of the
  /// on-chain `External(verifierAddress, publicKey)` signer entry.
  final String verifierAddress;

  /// 32-byte Ed25519 public key identifying the signer slot on the smart
  /// account.
  final Uint8List publicKey;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SelectedSignerEd25519) return false;
    if (verifierAddress != other.verifierAddress) return false;
    return _bytesEqualNullable(publicKey, other.publicKey);
  }

  @override
  int get hashCode => Object.hash(
        verifierAddress,
        Object.hashAll(publicKey),
      );
}

/// A delegated wallet signer identified by its Stellar G-address.
///
/// The address must have been registered as a `Delegated` signer on the
/// smart-account contract and the external wallet adapter must be able
/// to sign for it.
final class SelectedSignerWallet extends SelectedSigner {
  /// Constructs a wallet selected-signer entry.
  const SelectedSignerWallet(this.address);

  /// Stellar G-address of the delegated signer.
  final String address;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SelectedSignerWallet) return false;
    return other.address == address;
  }

  @override
  int get hashCode => address.hashCode;
}

bool _bytesEqualNullable(Uint8List? a, Uint8List? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return false;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _listEqualsNullable<T>(List<T>? a, List<T>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return false;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
