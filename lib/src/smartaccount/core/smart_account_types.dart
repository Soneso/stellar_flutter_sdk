// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import '../../key_pair.dart';
import '../../soroban/soroban_auth.dart';
import '../../util.dart';
import '../../xdr/xdr.dart';
import 'smart_account_constants.dart';
import 'smart_account_errors.dart';

/// Represents a signer that can authorise smart-account transactions.
///
/// Smart-account signers define who can authorise transactions on a smart
/// account. Two concrete forms exist:
///
/// - [DelegatedSigner]: a Soroban address (G or C) using the built-in
///   `require_auth` verification mechanism.
/// - [ExternalSigner]: a verifier contract plus public-key bytes that
///   delegate signature validation to a Soroban contract — used to support
///   non-native schemes such as WebAuthn (secp256r1) and Ed25519.
///
/// Example:
///
/// ```dart
/// // Create a delegated signer
/// final delegated = DelegatedSigner('GA7QYNF7SOWQ...');
///
/// // Create a WebAuthn signer
/// final webauthn = ExternalSigner.webAuthn(
///   verifierAddress: 'CBCD...',
///   publicKey: publicKeyData,
///   credentialId: credentialIdData,
/// );
///
/// // Convert to on-chain representation
/// final scVal = delegated.toScVal();
/// ```
sealed class SmartAccountSigner {
  /// Constructor for the sealed `SmartAccountSigner` hierarchy.
  const SmartAccountSigner();

  /// Converts this signer to its `ScVal` representation for contract calls.
  ///
  /// Throws [ValidationException] when the underlying address or key data
  /// cannot be encoded.
  XdrSCVal toScVal();

  /// Unique identifier for deduplication.
  ///
  /// The format depends on the concrete signer type:
  ///
  /// - delegated signers: `"delegated:<address>"`
  /// - external signers: `"external:<verifierAddress>:<keyDataHex>"`
  String get uniqueKey;
}

/// A delegated signer using a Soroban address with built-in `require_auth`
/// verification.
///
/// Delegated signers are Stellar accounts (G-address) or smart contracts
/// (C-address) that use the native Soroban authorization mechanism. The
/// smart-account contract calls `require_auth_for_args()` on the address to
/// verify authorisation.
///
/// Example:
///
/// ```dart
/// // Account signer
/// final account = DelegatedSigner('GA7QYNF7SOWQ...');
///
/// // Contract signer
/// final contract = DelegatedSigner('CBCD1234...');
/// ```
final class DelegatedSigner extends SmartAccountSigner {
  /// Constructs a delegated signer for the given Stellar [address].
  ///
  /// The [address] must be either a valid Stellar account ID (G-address) or a
  /// valid contract ID (C-address). Throws an [InvalidAddress] exception
  /// otherwise.
  DelegatedSigner(this.address) {
    if (!StrKey.isValidStellarAccountId(address) &&
        !StrKey.isValidContractId(address)) {
      throw ValidationException.invalidAddress(
        'Address must be a valid Stellar address (G... or C...), got: '
        '$address',
      );
    }
  }

  /// The Stellar address of the signer
  /// (G-address for accounts, C-address for contracts).
  final String address;

  /// Converts the delegated signer to its on-chain representation.
  ///
  /// Returns `ScVal::Vec([Symbol("Delegated"), Address(address)])`. Throws
  /// an [InvalidInput] validation exception if the address cannot be
  /// converted to an `XdrSCAddress`.
  @override
  XdrSCVal toScVal() {
    try {
      final scAddress = StrKey.isValidContractId(address)
          ? Address.forContractId(address).toXdr()
          : Address.forAccountId(address).toXdr();
      return XdrSCVal.forVec([
        XdrSCVal.forSymbol('Delegated'),
        XdrSCVal.forAddress(scAddress),
      ]);
    } catch (e) {
      throw ValidationException.invalidInput(
        'address',
        'Failed to convert DelegatedSigner to ScVal: $e',
        cause: e,
      );
    }
  }

  /// Unique identifier for deduplication.
  ///
  /// Format: `"delegated:<address>"`.
  @override
  String get uniqueKey => 'delegated:$address';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DelegatedSigner && other.address == address;
  }

  @override
  int get hashCode => address.hashCode;
}

/// An external signer using a verifier contract for custom signature
/// validation.
///
/// External signers delegate signature verification to a Soroban contract.
/// The verifier contract receives the public-key data and the signature, and
/// returns whether the signature is valid. This enables support for
/// non-native signature schemes such as WebAuthn (secp256r1) and Ed25519.
///
/// The verifier contract address must be a C-address, and `keyData` contains
/// the public-key bytes plus any additional authentication data such as
/// WebAuthn credential IDs.
///
/// Example:
///
/// ```dart
/// // WebAuthn signer
/// final webAuthn = ExternalSigner.webAuthn(
///   verifierAddress: 'CBCD1234...',
///   publicKey: secp256r1PublicKey,
///   credentialId: webAuthnCredentialId,
/// );
///
/// // Ed25519 signer
/// final ed = ExternalSigner.ed25519(
///   verifierAddress: 'CDEF5678...',
///   publicKey: ed25519PublicKey,
/// );
/// ```
final class ExternalSigner extends SmartAccountSigner {
  /// Constructs an external signer for the given [verifierAddress] and
  /// [keyData].
  ///
  /// The [verifierAddress] must be a valid contract ID (C-address) and
  /// [keyData] must be non-empty. Throws an [InvalidAddress] exception when
  /// the verifier address is invalid, or an [InvalidInput] exception when the
  /// key data is empty.
  ExternalSigner(this.verifierAddress, Uint8List keyData)
      : keyData = Uint8List.fromList(keyData) {
    if (!StrKey.isValidContractId(verifierAddress)) {
      throw ValidationException.invalidAddress(
        'Verifier address must be a valid contract address (C...), got: '
        '$verifierAddress',
      );
    }
    if (keyData.isEmpty) {
      throw ValidationException.invalidInput(
        'keyData',
        'Key data cannot be empty',
      );
    }
  }

  /// The contract address of the signature verifier (C-address).
  final String verifierAddress;

  /// The public-key bytes plus any additional authentication data
  /// (e.g. WebAuthn credential ID for WebAuthn signers).
  final Uint8List keyData;

  /// Creates a WebAuthn external signer with secp256r1 signature verification.
  ///
  /// WebAuthn signers use an uncompressed secp256r1 public key (65 bytes
  /// starting with `0x04`) combined with a WebAuthn credential ID for
  /// authentication. The resulting `keyData` is `publicKey || credentialId`.
  ///
  /// Throws an [InvalidInput] exception if [publicKey] is not exactly
  /// [SmartAccountConstants.secp256r1PublicKeySize] bytes, does not start
  /// with [SmartAccountConstants.uncompressedPubkeyPrefix], or if
  /// [credentialId] is empty.
  static ExternalSigner webAuthn({
    required String verifierAddress,
    required Uint8List publicKey,
    required Uint8List credentialId,
  }) {
    if (publicKey.length != SmartAccountConstants.secp256r1PublicKeySize) {
      throw ValidationException.invalidInput(
        'publicKey',
        'WebAuthn public key must be '
            '${SmartAccountConstants.secp256r1PublicKeySize} bytes '
            '(uncompressed secp256r1), got: ${publicKey.length}',
      );
    }
    if (publicKey[0] != SmartAccountConstants.uncompressedPubkeyPrefix) {
      final firstByteHex =
          Util.bytesToHex(Uint8List.fromList([publicKey[0]])).toLowerCase();
      throw ValidationException.invalidInput(
        'publicKey',
        'WebAuthn public key must start with 0x04 (uncompressed format), '
            'got: 0x$firstByteHex',
      );
    }
    if (credentialId.isEmpty) {
      throw ValidationException.invalidInput(
        'credentialId',
        'WebAuthn credential ID cannot be empty',
      );
    }
    final keyData = Uint8List(publicKey.length + credentialId.length)
      ..setRange(0, publicKey.length, publicKey)
      ..setRange(publicKey.length, publicKey.length + credentialId.length,
          credentialId);
    return ExternalSigner(verifierAddress, keyData);
  }

  /// Creates an Ed25519 external signer.
  ///
  /// Ed25519 signers use a 32-byte Ed25519 public key for signature
  /// verification.
  ///
  /// Throws an [InvalidInput] exception if [publicKey] is not exactly
  /// [SmartAccountConstants.ed25519PublicKeySize] bytes.
  static ExternalSigner ed25519({
    required String verifierAddress,
    required Uint8List publicKey,
  }) {
    if (publicKey.length != SmartAccountConstants.ed25519PublicKeySize) {
      throw ValidationException.invalidInput(
        'publicKey',
        'Ed25519 public key must be '
            '${SmartAccountConstants.ed25519PublicKeySize} bytes, '
            'got: ${publicKey.length}',
      );
    }
    return ExternalSigner(verifierAddress, publicKey);
  }

  /// Converts the external signer to its on-chain representation.
  ///
  /// Returns
  /// `ScVal::Vec([Symbol("External"), Address(verifier), Bytes(keyData)])`.
  /// Throws an [InvalidInput] validation exception if the verifier address
  /// cannot be encoded.
  @override
  XdrSCVal toScVal() {
    try {
      final scAddress = Address.forContractId(verifierAddress).toXdr();
      return XdrSCVal.forVec([
        XdrSCVal.forSymbol('External'),
        XdrSCVal.forAddress(scAddress),
        XdrSCVal.forBytes(keyData),
      ]);
    } catch (e) {
      throw ValidationException.invalidInput(
        'verifierAddress',
        'Failed to convert ExternalSigner to ScVal: $e',
        cause: e,
      );
    }
  }

  /// Unique identifier for deduplication.
  ///
  /// Format: `"external:<verifierAddress>:<keyDataHex>"` where `<keyDataHex>`
  /// is the lowercase hex encoding of [keyData].
  @override
  String get uniqueKey =>
      'external:$verifierAddress:${Util.bytesToHex(keyData).toLowerCase()}';

  /// Equality operator using a constant-time comparison on [keyData] to
  /// prevent timing side-channel attacks. Two external signers are equal when
  /// they share the same [verifierAddress] and byte-identical [keyData].
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ExternalSigner) return false;
    final addressMatch = verifierAddress == other.verifierAddress;
    final keyMatch = _constantTimeEquals(keyData, other.keyData);
    // Bitwise AND avoids early-exit short-circuiting that would otherwise
    // leak timing information about which check failed.
    return (addressMatch ? 1 : 0) & (keyMatch ? 1 : 0) == 1;
  }

  /// Content-based hash code that combines [verifierAddress] with a content
  /// hash of [keyData], so logically equal signers hash equally.
  @override
  int get hashCode {
    var result = verifierAddress.hashCode;
    result = 0x1fffffff & (31 * result + _byteListContentHash(keyData));
    return result;
  }

  static int _byteListContentHash(Uint8List bytes) {
    // FNV-1a-like rolling hash for byte content (matches a typical
    // `contentHashCode()` implementation).
    var hash = 1;
    for (final b in bytes) {
      hash = 0x1fffffff & (31 * hash + b);
    }
    return hash;
  }

  static bool _constantTimeEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) {
      return false;
    }
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}

/// Determines how a transaction is submitted to the network.
///
/// By default the SDK uses the relayer when one is configured, otherwise it
/// submits directly via Soroban RPC. Pass a [SubmissionMethod] value as the
/// `forceMethod` parameter on transaction methods to override this default.
///
/// Example:
///
/// ```dart
/// // Force direct RPC submission even when a relayer is configured.
/// final result = await txOps.transfer(
///   tokenContract: 'CBCD...',
///   recipient: 'GA7Q...',
///   amount: '10',
///   forceMethod: SubmissionMethod.rpc,
/// );
/// ```
enum SubmissionMethod {
  /// Submit via the relayer proxy for fee-sponsored transactions. Fails when
  /// no relayer is configured.
  relayer,

  /// Submit directly via Soroban RPC. Always available regardless of relayer
  /// configuration.
  rpc,
}
