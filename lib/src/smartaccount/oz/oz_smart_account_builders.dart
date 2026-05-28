// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import '../../util.dart';
import '../core/smart_account_constants.dart';
import '../core/smart_account_errors.dart';
import 'oz_smart_account_types.dart';

/// Builder utilities for OpenZeppelin Smart Account signers and policy
/// parameters.
///
/// Provides type-safe constructors and helper functions for creating and
/// inspecting OpenZeppelin Smart Account signer types, and for creating policy
/// parameters used by the higher-level managers:
///
/// - Signer builders for delegated, external, WebAuthn, and Ed25519 signers.
/// - Signer inspection (type checks, type description, credential and address
///   extraction).
/// - Signer matching (by credential ID, by address, equality).
/// - Signer deduplication.
/// - Simple threshold policy: at least N signers required.
/// - Weighted threshold policy: weighted signer set with a total-weight
///   requirement.
/// - Spending limit policy: restricts how much can be transferred within a
///   given period.
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

  /// Returns the WebAuthn signer credential ID as a Base64URL-encoded
  /// string without trailing `=` padding, or `null` for non-WebAuthn signers.
  ///
  /// Padding is stripped so the value matches the canonical unpadded form
  /// produced by the connect path and recommended by RFC 4648 §5 for URL-
  /// safe Base64 of WebAuthn credential IDs.
  static String? getCredentialIdStringFromSigner(OZSmartAccountSigner signer) {
    final credentialId = getCredentialIdFromSigner(signer);
    if (credentialId == null) return null;
    return _stripBase64UrlPadding(base64Url.encode(credentialId));
  }

  static String _stripBase64UrlPadding(String encoded) {
    var s = encoded;
    while (s.isNotEmpty && s.endsWith('=')) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }

  static bool isDelegatedSigner(OZSmartAccountSigner signer) {
    return signer is OZDelegatedSigner;
  }

  static bool isExternalSigner(OZSmartAccountSigner signer) {
    return signer is OZExternalSigner;
  }

  /// Returns a human-readable description of the signer type:
  /// `"Stellar Account"`, `"Passkey (WebAuthn)"`, `"Ed25519"`, or
  /// `"External Verifier"`.
  static String describeSignerType(OZSmartAccountSigner signer) {
    if (signer is OZDelegatedSigner) {
      return 'Stellar Account';
    }
    final external = signer as OZExternalSigner;
    if (external.keyData.length >
        SmartAccountConstants.secp256r1PublicKeySize) {
      return 'Passkey (WebAuthn)';
    }
    if (external.keyData.length ==
        SmartAccountConstants.ed25519PublicKeySize) {
      return 'Ed25519';
    }
    return 'External Verifier';
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
    return signerCredId == _stripBase64UrlPadding(credentialId);
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
      if (a.keyData.length != b.keyData.length) return false;
      for (var i = 0; i < a.keyData.length; i++) {
        if (a.keyData[i] != b.keyData[i]) return false;
      }
      return true;
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

  // Policy parameter builders

  /// Creates simple threshold policy parameters requiring at least
  /// [threshold] signers.
  ///
  /// Throws [InvalidInput] when [threshold] is less than 1.
  static OZSimpleThresholdParams createThresholdParams(int threshold) {
    if (threshold < 1) {
      throw ValidationException.invalidInput(
        'threshold',
        'Threshold must be at least 1, got: $threshold',
      );
    }
    return OZSimpleThresholdParams(threshold: threshold);
  }

  /// Creates weighted threshold policy parameters.
  ///
  /// Each signer has a weight; authorisation succeeds when the sum of
  /// weights of authenticated signers meets or exceeds [threshold].
  ///
  /// Throws [InvalidInput] when [threshold] is less than 1, when
  /// [signerWeights] is empty, when any weight is less than 1, or when
  /// the total weight is less than [threshold].
  static OZWeightedThresholdParams createWeightedThresholdParams({
    required int threshold,
    required Map<OZSmartAccountSigner, int> signerWeights,
  }) {
    if (threshold < 1) {
      throw ValidationException.invalidInput(
        'threshold',
        'Threshold must be at least 1, got: $threshold',
      );
    }
    if (signerWeights.isEmpty) {
      throw ValidationException.invalidInput(
        'signerWeights',
        'At least one signer weight must be provided',
      );
    }

    var totalWeight = 0;
    for (final weight in signerWeights.values) {
      if (weight < 1) {
        throw ValidationException.invalidInput(
          'signerWeights',
          'All weights must be positive integers, got: $weight',
        );
      }
      totalWeight += weight;
    }

    if (totalWeight < threshold) {
      throw ValidationException.invalidInput(
        'signerWeights',
        'Sum of weights ($totalWeight) must be >= threshold ($threshold)',
      );
    }

    return OZWeightedThresholdParams(
      threshold: threshold,
      signerWeights: signerWeights,
    );
  }

  /// Creates spending limit policy parameters.
  ///
  /// Restricts how much can be transferred within the supplied period.
  /// The [spendingLimit] is a decimal XLM string (for example `"100"` or
  /// `"10.5"`), converted to stroops via [Util.toXdrInt64Amount].
  /// The amount must be positive and use no more than seven decimal places.
  ///
  /// Common values for [periodLedgers] are
  /// [Util.ledgersPerHour] and
  /// [Util.ledgersPerDay].
  ///
  /// Throws [InvalidAmount] when the spending limit string is invalid or
  /// not positive, and [InvalidInput] when [periodLedgers] is less than 1.
  static OZSpendingLimitParams createSpendingLimitParams({
    required String spendingLimit,
    required int periodLedgers,
  }) {
    final stroops = Util.toXdrInt64Amount(spendingLimit);
    if (stroops <= BigInt.zero) {
      throw ValidationException.invalidAmount(
        spendingLimit,
        reason: 'must be greater than zero',
      );
    }
    if (periodLedgers < 1) {
      throw ValidationException.invalidInput(
        'periodLedgers',
        'Period must be at least 1 ledger, got: $periodLedgers',
      );
    }
    return OZSpendingLimitParams._internal(
      spendingLimit: stroops,
      periodLedgers: periodLedgers,
    );
  }
}

// Policy parameter data classes

/// Parameters for a simple threshold policy in the OpenZeppelin Smart Account.
///
/// Authorisation succeeds when at least [threshold] signers on the
/// context rule provide valid signatures.
class OZSimpleThresholdParams {
  /// Constructs simple threshold parameters with the given [threshold].
  const OZSimpleThresholdParams({required this.threshold});

  /// Minimum number of signers required (must be at least 1).
  final int threshold;
}

/// Parameters for a weighted threshold policy in the OpenZeppelin Smart Account.
///
/// Each signer has an integer weight; authorisation succeeds when the sum
/// of weights of authenticated signers meets or exceeds [threshold].
///
/// Instances expose a [signerWeights] map by reference; the binding is
/// `final` but the map content is not. Treat instances as immutable in
/// practice, or take a copy of [signerWeights] before sharing across
/// isolates.
class OZWeightedThresholdParams {
  /// Constructs weighted threshold parameters with the given [threshold]
  /// and [signerWeights].
  const OZWeightedThresholdParams({
    required this.threshold,
    required this.signerWeights,
  });

  /// Total weight required for authorisation (at least 1).
  final int threshold;

  /// Map of signers to their integer weights (each weight at least 1).
  final Map<OZSmartAccountSigner, int> signerWeights;
}

/// Parameters for a spending-limit policy in the OpenZeppelin Smart Account.
///
/// Restricts how much can be transferred within a given time period.
/// Construct instances using
/// [OZSmartAccountBuilders.createSpendingLimitParams], which validates
/// inputs and converts the spending limit from a decimal XLM string to
/// stroops.
class OZSpendingLimitParams {
  /// Internal constructor invoked by
  /// [OZSmartAccountBuilders.createSpendingLimitParams] after the spending
  /// limit has been validated and converted to stroops.
  ///
  /// Direct construction is intentionally not part of the public API; use
  /// the builder method to obtain instances.
  const OZSpendingLimitParams._internal({
    required this.spendingLimit,
    required this.periodLedgers,
  });

  /// Maximum amount allowed in the period, expressed in stroops.
  final BigInt spendingLimit;

  /// Number of ledgers in the period (at least 1). On the Stellar network
  /// a ledger closes approximately every five seconds.
  final int periodLedgers;
}
