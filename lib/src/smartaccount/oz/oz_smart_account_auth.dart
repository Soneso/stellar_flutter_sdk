// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

import '../../xdr/xdr.dart';
import '../core/smart_account_errors.dart';
import 'oz_smart_account_auth_payload.dart';
import 'oz_smart_account_types.dart';
import 'oz_smart_account_signatures.dart';

/// Authentication helpers for OpenZeppelin Smart Account authorization entries.
///
/// Provides functions to sign authorisation entries and build authentication
/// payload hashes for OpenZeppelin Smart Account transactions. These helpers
/// handle the XDR encoding and signature-map construction required by the
/// Soroban authorisation protocol.
///
/// Responsibilities include:
///
/// - Computing the auth digest that binds context rule IDs to the signature
///   payload: `SHA-256(signaturePayload || contextRuleIds.toXDR())`.
/// - Building Soroban authorisation payload hashes for WebAuthn challenges.
/// - Attaching pre-computed signatures to authorisation entries.
/// - Managing signature expiration and map-entry ordering.
/// - Producing verifier-appropriate signature bytes for the auth payload.
///
/// All entry points are pure static functions over their arguments; safe to
/// call concurrently from any isolate. The [signAuthEntry] helper never
/// mutates its input entry — it clones via XDR round-trip and returns a new
/// entry.
abstract class OZSmartAccountAuth {
  /// Private constructor prevents instantiation; the class is used as a
  /// namespace for static methods.
  OZSmartAccountAuth._();

  // ==========================================================================
  // Payload hash building
  // ==========================================================================

  /// Computes the auth digest that binds context rule IDs to the signature
  /// payload.
  ///
  /// The digest is `SHA-256(signaturePayload || contextRuleIds.toXDR())`
  /// where `contextRuleIds.toXDR()` is the XDR encoding of
  /// `ScVal::Vec([ScVal::U32(id), ...])`. The OpenZeppelin Smart Account
  /// contract requires this binding so signers cannot be replayed against a
  /// different rule set.
  ///
  /// Throws [TransactionSigningFailed] when XDR encoding of the rule-IDs
  /// vector fails.
  static Future<Uint8List> buildAuthDigest(
    Uint8List signaturePayload,
    List<int> contextRuleIds,
  ) async {
    final ruleIdsScVal = XdrSCVal.forVec(
      contextRuleIds.map((id) => XdrSCVal.forU32(id)).toList(growable: false),
    );

    Uint8List ruleIdsXdr;
    try {
      final stream = XdrDataOutputStream();
      XdrSCVal.encode(stream, ruleIdsScVal);
      ruleIdsXdr = Uint8List.fromList(stream.bytes);
    } catch (e) {
      throw TransactionException.signingFailed(
        'Failed to XDR encode context rule IDs ScVal',
        cause: e,
      );
    }

    final concatenated = Uint8List(signaturePayload.length + ruleIdsXdr.length)
      ..setRange(0, signaturePayload.length, signaturePayload)
      ..setRange(
          signaturePayload.length,
          signaturePayload.length + ruleIdsXdr.length,
          ruleIdsXdr);
    return Uint8List.fromList(crypto.sha256.convert(concatenated).bytes);
  }

  /// Builds the authorisation payload hash for signing.
  ///
  /// Computes the hash that must be signed to authorise a Soroban
  /// operation. This hash is used as the WebAuthn challenge when
  /// collecting biometric signatures. The entry must have address
  /// credentials.
  ///
  /// The payload preimage is constructed as
  /// `HashIDPreimage::SorobanAuthorization { networkId,
  /// nonce: credentials.nonce, signatureExpirationLedger: expirationLedger,
  /// invocation: entry.rootInvocation }` and the returned value is
  /// `SHA-256(XDR_encode(preimage))`.
  ///
  /// Throws [TransactionSigningFailed] when [entry] does not have address
  /// credentials, or when XDR encoding fails.
  static Future<Uint8List> buildAuthPayloadHash(
    XdrSorobanAuthorizationEntry entry,
    int expirationLedger,
    String networkPassphrase,
  ) async {
    final credentials = entry.credentials.address;
    if (entry.credentials.discriminant !=
            XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS ||
        credentials == null) {
      throw TransactionException.signingFailed(
        'Credentials must be of type address to build auth payload hash',
      );
    }

    return _hashAuthPreimage(
      nonce: credentials.nonce,
      expirationLedger: expirationLedger,
      invocation: entry.rootInvocation,
      networkPassphrase: networkPassphrase,
    );
  }

  /// Builds the authorisation payload hash for source-account credentials.
  ///
  /// Used when converting source-account credentials to address
  /// credentials, typically for relayer fee sponsoring. The preimage is
  /// constructed identically to [buildAuthPayloadHash] but uses the
  /// supplied [nonce] and [expirationLedger] instead of reading them from
  /// existing credentials.
  ///
  /// Throws [TransactionSigningFailed] when XDR encoding fails.
  static Future<Uint8List> buildSourceAccountAuthPayloadHash(
    XdrSorobanAuthorizationEntry entry,
    XdrInt64 nonce,
    int expirationLedger,
    String networkPassphrase,
  ) async {
    return _hashAuthPreimage(
      nonce: nonce,
      expirationLedger: expirationLedger,
      invocation: entry.rootInvocation,
      networkPassphrase: networkPassphrase,
    );
  }

  // ==========================================================================
  // Entry signing
  // ==========================================================================

  /// Attaches a pre-computed [signature] to an authorisation entry.
  ///
  /// This method does not perform cryptographic signing. The caller is
  /// responsible for computing the signature over the correct payload hash
  /// produced by [buildAuthPayloadHash] using the same [expirationLedger].
  ///
  /// The procedure clones the input entry via XDR round-trip, sets the
  /// signature expiration on the cloned credentials, builds the signer-key
  /// ScVal, produces the verifier-appropriate signature bytes, reads the
  /// existing AuthPayload (if any), upserts the new signer entry, writes
  /// the payload back, and returns a new authorisation entry with the updated
  /// credentials. The input entry is never mutated.
  ///
  /// When [contextRuleIds] is non-empty it overrides any existing
  /// context-rule IDs in the payload; otherwise the existing value is
  /// preserved.
  ///
  /// Throws [TransactionSigningFailed] when credentials are not address
  /// type, when the entry cannot be cloned via XDR, when [signer] cannot
  /// be encoded as an ScVal, or when [OZSmartAccountSignature.toAuthPayloadBytes]
  /// fails (WebAuthn and Policy variants only).
  static Future<XdrSorobanAuthorizationEntry> signAuthEntry({
    required XdrSorobanAuthorizationEntry entry,
    required OZSmartAccountSigner signer,
    required OZSmartAccountSignature signature,
    required int expirationLedger,
    List<int> contextRuleIds = const <int>[],
  }) async {
    // Step 1: clone the entry via XDR round-trip so the caller's instance
    // is never mutated.
    Uint8List entryBytes;
    try {
      final stream = XdrDataOutputStream();
      XdrSorobanAuthorizationEntry.encode(stream, entry);
      entryBytes = Uint8List.fromList(stream.bytes);
    } catch (e) {
      throw TransactionException.signingFailed(
        'Failed to XDR encode authorization entry for cloning',
        cause: e,
      );
    }

    XdrSorobanAuthorizationEntry entryCopy;
    try {
      entryCopy = XdrSorobanAuthorizationEntry.decode(
        XdrDataInputStream(entryBytes),
      );
    } catch (e) {
      throw TransactionException.signingFailed(
        'Failed to XDR decode authorization entry after cloning',
        cause: e,
      );
    }

    // Step 2: extract the address credentials from the cloned entry.
    final credentialsCopy = entryCopy.credentials.address;
    if (entryCopy.credentials.discriminant !=
            XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS ||
        credentialsCopy == null) {
      throw TransactionException.signingFailed(
        'Credentials must be of type address to sign auth entry',
      );
    }

    // Step 3: produce the bytes for the on-wire signers Map. The exact
    // content is verifier-dependent: WebAuthn/Policy XDR-encode their
    // ScVal; Ed25519 passes the raw 64-byte signature directly (see
    // OZSmartAccountSignature.toAuthPayloadBytes).
    Uint8List sigXdrBytes;
    try {
      sigXdrBytes = signature.toAuthPayloadBytes();
    } catch (e) {
      throw TransactionException.signingFailed(
        'Failed to encode signature bytes for auth payload',
        cause: e,
      );
    }

    // Step 4: read the existing payload from the cloned credentials,
    // override or preserve context rule IDs, upsert the signer entry, and
    // write the payload back.
    final existingPayload =
        OZSmartAccountAuthPayloadCodec.read(credentialsCopy.signature);

    final updatedPayload = OZSmartAccountAuthPayload(
      signers: existingPayload.signers,
      contextRuleIds: contextRuleIds.isNotEmpty
          ? List<int>.from(contextRuleIds)
          : existingPayload.contextRuleIds,
    );

    OZSmartAccountAuthPayloadCodec.upsertSigner(
      updatedPayload,
      signer,
      sigXdrBytes,
    );

    final payloadScVal = OZSmartAccountAuthPayloadCodec.write(updatedPayload);

    final updatedCredentials = XdrSorobanAddressCredentials(
      credentialsCopy.address,
      credentialsCopy.nonce,
      XdrUint32(expirationLedger),
      payloadScVal,
    );

    final updatedCredsWrapper =
        XdrSorobanCredentials.forAddressCredentials(updatedCredentials);
    return XdrSorobanAuthorizationEntry(
      updatedCredsWrapper,
      entryCopy.rootInvocation,
    );
  }

  // ==========================================================================
  // Signature map manipulation
  // ==========================================================================

  /// Adds a raw key/value entry to the auth entry's signature map.
  ///
  /// Used for delegated-signer placeholders where the value is `Bytes`
  /// (often empty). Uses the AuthPayload format with `context_rule_ids`
  /// and `signers` fields.
  ///
  /// When [signatureValue] is `XdrSCVal.SCV_BYTES` its raw bytes are
  /// stored directly; otherwise the value is XDR-encoded and the resulting
  /// bytes are stored.
  ///
  /// Throws [TransactionSigningFailed] when [entry] does not have address
  /// credentials, or when XDR encoding of the signature value fails.
  static XdrSorobanAuthorizationEntry addRawSignatureMapEntry({
    required XdrSorobanAuthorizationEntry entry,
    required XdrSCVal signerKey,
    required XdrSCVal signatureValue,
    List<int> contextRuleIds = const <int>[],
  }) {
    final credentials = entry.credentials.address;
    if (entry.credentials.discriminant !=
            XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS ||
        credentials == null) {
      throw TransactionException.signingFailed(
        'Credentials must be of type address to add signature map entry',
      );
    }

    final existingPayload =
        OZSmartAccountAuthPayloadCodec.read(credentials.signature);

    final updatedPayload = OZSmartAccountAuthPayload(
      signers: existingPayload.signers,
      contextRuleIds: contextRuleIds.isNotEmpty
          ? List<int>.from(contextRuleIds)
          : existingPayload.contextRuleIds,
    );

    Uint8List sigBytes;
    if (signatureValue.discriminant == XdrSCValType.SCV_BYTES &&
        signatureValue.bytes != null) {
      sigBytes = Uint8List.fromList(signatureValue.bytes!.sCBytes);
    } else {
      try {
        final stream = XdrDataOutputStream();
        XdrSCVal.encode(stream, signatureValue);
        sigBytes = Uint8List.fromList(stream.bytes);
      } catch (e) {
        throw TransactionException.signingFailed(
          'Failed to XDR-encode raw signature value',
          cause: e,
        );
      }
    }

    final signer = OZSmartAccountAuthPayloadCodec.signerFromScVal(signerKey);
    updatedPayload.signers[signer] = sigBytes;

    final payloadScVal = OZSmartAccountAuthPayloadCodec.write(updatedPayload);

    final updatedCredentials = XdrSorobanAddressCredentials(
      credentials.address,
      credentials.nonce,
      credentials.signatureExpirationLedger,
      payloadScVal,
    );

    final updatedCredsWrapper =
        XdrSorobanCredentials.forAddressCredentials(updatedCredentials);
    return XdrSorobanAuthorizationEntry(
      updatedCredsWrapper,
      entry.rootInvocation,
    );
  }

  // ==========================================================================
  // Helper functions
  // ==========================================================================

  /// Hashes a Soroban authorisation preimage.
  ///
  /// Constructs `HashIDPreimage::SorobanAuthorization` from the given
  /// parameters, XDR-encodes it, and returns `SHA-256(encoded bytes)`.
  /// Used by both [buildAuthPayloadHash] and
  /// [buildSourceAccountAuthPayloadHash].
  static Future<Uint8List> _hashAuthPreimage({
    required XdrInt64 nonce,
    required int expirationLedger,
    required XdrSorobanAuthorizedInvocation invocation,
    required String networkPassphrase,
  }) async {
    final networkId = Uint8List.fromList(
      crypto.sha256.convert(utf8.encode(networkPassphrase)).bytes,
    );

    final authPreimage = XdrHashIDPreimageSorobanAuthorization(
      XdrHash(networkId),
      nonce,
      XdrUint32(expirationLedger),
      invocation,
    );

    final preimage = XdrHashIDPreimage(
      XdrEnvelopeType.ENVELOPE_TYPE_SOROBAN_AUTHORIZATION,
    );
    preimage.sorobanAuthorization = authPreimage;

    Uint8List encodedPreimage;
    try {
      final stream = XdrDataOutputStream();
      XdrHashIDPreimage.encode(stream, preimage);
      encodedPreimage = Uint8List.fromList(stream.bytes);
    } catch (e) {
      throw TransactionException.signingFailed(
        'Failed to XDR encode auth payload preimage',
        cause: e,
      );
    }

    return Uint8List.fromList(crypto.sha256.convert(encodedPreimage).bytes);
  }
}
