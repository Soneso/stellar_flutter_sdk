// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

import '../../network.dart';
import '../../soroban/soroban_auth.dart';
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
///
/// Credential arm handling:
/// - ADDRESS: legacy preimage (ENVELOPE_TYPE_SOROBAN_AUTHORIZATION).
/// - ADDRESS_V2: address-bound preimage
///   (ENVELOPE_TYPE_SOROBAN_AUTHORIZATION_WITH_ADDRESS). Handled identically
///   to ADDRESS in the signing flow; the arm is preserved on write-back.
/// - ADDRESS_WITH_DELEGATES: cannot be auto-signed by these flows. Use
///   [SorobanAuthorizationEntry.sign] with the [forAddress] parameter instead.
/// - SOURCE_ACCOUNT: not signable; throws on all entry points that require
///   address credentials.
abstract class OZSmartAccountAuth {
  OZSmartAccountAuth._();

  // Payload hash building

  /// Computes the auth digest that binds context rule IDs to the signature
  /// payload.
  ///
  /// The digest is `SHA-256(signaturePayload || contextRuleIds.toXDR())`
  /// where `contextRuleIds.toXDR()` is the XDR encoding of
  /// `ScVal::Vec([ScVal::U32(id), ...])`. The OpenZeppelin Smart Account
  /// contract requires this binding so signers cannot be replayed against a
  /// different rule set.
  ///
  /// Throws [SmartAccountTransactionSigningFailed] when XDR encoding of the rule-IDs
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
      throw SmartAccountTransactionException.signingFailed(
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
  /// collecting biometric signatures.
  ///
  /// Preimage selection follows the credential arm:
  /// - ADDRESS: ENVELOPE_TYPE_SOROBAN_AUTHORIZATION (legacy).
  /// - ADDRESS_V2: ENVELOPE_TYPE_SOROBAN_AUTHORIZATION_WITH_ADDRESS.
  /// - ADDRESS_WITH_DELEGATES: not supported by this flow; throws a
  ///   [SmartAccountTransactionSigningFailed] directing the caller to use
  ///   [SorobanAuthorizationEntry.sign] with the [forAddress] parameter.
  ///
  /// [expirationLedger] is stamped onto the credentials before the preimage
  /// is built. The returned hash is `SHA-256(XDR_encode(preimage))`.
  ///
  /// Throws [SmartAccountTransactionSigningFailed] when the entry does not carry
  /// address credentials or when XDR encoding fails.
  static Future<Uint8List> buildAuthPayloadHash(
    XdrSorobanAuthorizationEntry entry,
    int expirationLedger,
    String networkPassphrase,
  ) async {
    _requireAddressOrV2Credentials(entry.credentials);

    final inner = _innerAddressCredentials(entry.credentials)!;
    // Stamp the expiration before building the preimage so the hash covers
    // the submitted expiration value.
    final stampedInner = XdrSorobanAddressCredentials(
      inner.address,
      inner.nonce,
      XdrUint32(expirationLedger),
      inner.signature,
    );
    final stampedEntry = _rebuildEntry(entry, stampedInner);

    return _hashPreimage(stampedEntry, networkPassphrase);
  }

  /// Builds the authorisation payload hash for source-account credentials.
  ///
  /// Used when converting source-account credentials to fresh ADDRESS_V2
  /// credentials, typically for relayer fee sponsoring. [address], [nonce]
  /// and [expirationLedger] are the values the new credentials will carry;
  /// there are no existing address credentials to read them from.
  ///
  /// The preimage is the address-bound
  /// ENVELOPE_TYPE_SOROBAN_AUTHORIZATION_WITH_ADDRESS
  /// (networkID, nonce, signatureExpirationLedger, address, invocation) and
  /// the returned hash is `SHA-256(XDR_encode(preimage))`. The host
  /// reconstructs that preimage from the submitted ADDRESS_V2 credentials,
  /// so [address] must be the address those credentials carry.
  ///
  /// Throws [SmartAccountTransactionSigningFailed] when XDR encoding fails.
  static Future<Uint8List> buildSourceAccountAuthPayloadHash(
    XdrSorobanAuthorizationEntry entry,
    XdrSCAddress address,
    XdrInt64 nonce,
    int expirationLedger,
    String networkPassphrase,
  ) async {
    final addressCredentials = XdrSorobanAddressCredentials(
      address,
      nonce,
      XdrUint32(expirationLedger),
      XdrSCVal.forVoid(),
    );
    final syntheticEntry = XdrSorobanAuthorizationEntry(
      XdrSorobanCredentials.forAddressV2Credentials(addressCredentials),
      entry.rootInvocation,
    );
    return _hashPreimage(syntheticEntry, networkPassphrase);
  }

  // Entry signing

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
  /// The credential arm is preserved on write-back: an ADDRESS_V2 entry stays
  /// ADDRESS_V2 after signing.
  ///
  /// When [contextRuleIds] is non-empty it overrides any existing
  /// context-rule IDs in the payload; otherwise the existing value is
  /// preserved.
  ///
  /// ADDRESS_WITH_DELEGATES entries are not supported here; the caller must
  /// use [SorobanAuthorizationEntry.sign] with the [forAddress] parameter to
  /// route signatures to the appropriate delegate nodes.
  ///
  /// Throws [SmartAccountTransactionSigningFailed] when credentials are not address
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
      throw SmartAccountTransactionException.signingFailed(
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
      throw SmartAccountTransactionException.signingFailed(
        'Failed to XDR decode authorization entry after cloning',
        cause: e,
      );
    }

    // Step 2: extract the address credentials from the cloned entry.
    // ADDRESS_WITH_DELEGATES is not supported in this auto-sign flow.
    _requireAddressOrV2Credentials(entryCopy.credentials);
    final credentialsCopy = _innerAddressCredentials(entryCopy.credentials)!;

    // Step 3: produce the bytes for the on-wire signers Map. The exact
    // content is verifier-dependent: WebAuthn/Policy XDR-encode their
    // ScVal; Ed25519 passes the raw 64-byte signature directly (see
    // OZSmartAccountSignature.toAuthPayloadBytes).
    Uint8List sigXdrBytes;
    try {
      sigXdrBytes = signature.toAuthPayloadBytes();
    } catch (e) {
      throw SmartAccountTransactionException.signingFailed(
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

    final updatedCredsWrapper = _rebuildCredentials(
      entryCopy.credentials,
      updatedCredentials,
    );
    return XdrSorobanAuthorizationEntry(
      updatedCredsWrapper,
      entryCopy.rootInvocation,
    );
  }

  // Signature map manipulation

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
  /// The credential arm is preserved on write-back.
  ///
  /// ADDRESS_WITH_DELEGATES entries are not supported here; use
  /// [SorobanAuthorizationEntry.sign] with the [forAddress] parameter instead.
  ///
  /// Throws [SmartAccountTransactionSigningFailed] when [entry] does not have address
  /// credentials, or when XDR encoding of the signature value fails.
  static XdrSorobanAuthorizationEntry addRawSignatureMapEntry({
    required XdrSorobanAuthorizationEntry entry,
    required XdrSCVal signerKey,
    required XdrSCVal signatureValue,
    List<int> contextRuleIds = const <int>[],
  }) {
    // ADDRESS_WITH_DELEGATES is not supported in this auto-sign flow.
    _requireAddressOrV2Credentials(entry.credentials);
    final credentials = _innerAddressCredentials(entry.credentials)!;

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
        throw SmartAccountTransactionException.signingFailed(
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

    final updatedCredsWrapper = _rebuildCredentials(
      entry.credentials,
      updatedCredentials,
    );
    return XdrSorobanAuthorizationEntry(
      updatedCredsWrapper,
      entry.rootInvocation,
    );
  }

  // Helper functions

  /// Returns the inner [XdrSorobanAddressCredentials] for any address arm
  /// (ADDRESS, ADDRESS_V2, or ADDRESS_WITH_DELEGATES), or null for
  /// SOURCE_ACCOUNT.
  static XdrSorobanAddressCredentials? _innerAddressCredentials(
    XdrSorobanCredentials creds,
  ) {
    switch (creds.discriminant) {
      case XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS:
        return creds.address;
      case XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2:
        return creds.addressV2;
      case XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_WITH_DELEGATES:
        return creds.addressWithDelegates?.addressCredentials;
      default:
        return null;
    }
  }

  /// Rebuilds a [XdrSorobanCredentials] wrapper from the same discriminant arm,
  /// replacing the inner [XdrSorobanAddressCredentials] with [updated].
  ///
  /// Preserves the credential arm: an ADDRESS_V2 entry stays ADDRESS_V2.
  /// Throws [SmartAccountTransactionSigningFailed] for SOURCE_ACCOUNT or unknown arms.
  static XdrSorobanCredentials _rebuildCredentials(
    XdrSorobanCredentials original,
    XdrSorobanAddressCredentials updated,
  ) {
    switch (original.discriminant) {
      case XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS:
        return XdrSorobanCredentials.forAddressCredentials(updated);
      case XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2:
        return XdrSorobanCredentials.forAddressV2Credentials(updated);
      default:
        throw SmartAccountTransactionException.signingFailed(
          'Cannot rebuild credentials for arm: ${original.discriminant}',
        );
    }
  }

  /// Validates that [creds] carries ADDRESS or ADDRESS_V2 credentials.
  ///
  /// Throws [SmartAccountTransactionSigningFailed] for SOURCE_ACCOUNT (no address
  /// credentials available) and for ADDRESS_WITH_DELEGATES (delegate routing
  /// is caller policy; use [SorobanAuthorizationEntry.sign] with the
  /// [forAddress] parameter to route signatures to specific delegate nodes).
  static void _requireAddressOrV2Credentials(XdrSorobanCredentials creds) {
    switch (creds.discriminant) {
      case XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS:
      case XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2:
        return;
      case XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_WITH_DELEGATES:
        throw SmartAccountTransactionException.signingFailed(
          'ADDRESS_WITH_DELEGATES entries cannot be auto-signed by the OZ auth flow. '
          'Use SorobanAuthorizationEntry.sign(signer, network, forAddress: address) '
          'to route signatures to specific delegate nodes before calling these helpers.',
        );
      default:
        throw SmartAccountTransactionException.signingFailed(
          'Credentials must be of type ADDRESS or ADDRESS_V2 to sign auth entry',
        );
    }
  }

  /// Hashes the authorisation preimage for the given entry.
  ///
  /// Promotes the XDR entry to the higher-level [SorobanAuthorizationEntry]
  /// and delegates preimage construction to
  /// [SorobanAuthorizationEntry.buildPreimage]. This ensures a single
  /// canonical preimage-construction path is used for all credential arms:
  /// - ADDRESS -> ENVELOPE_TYPE_SOROBAN_AUTHORIZATION
  /// - ADDRESS_V2 -> ENVELOPE_TYPE_SOROBAN_AUTHORIZATION_WITH_ADDRESS
  ///
  /// Returns `SHA-256(XDR_encode(preimage))`.
  static Future<Uint8List> _hashPreimage(
    XdrSorobanAuthorizationEntry xdrEntry,
    String networkPassphrase,
  ) async {
    final entry = SorobanAuthorizationEntry.fromXdr(xdrEntry);
    final network = Network(networkPassphrase);
    XdrHashIDPreimage preimage;
    try {
      preimage = entry.buildPreimage(network);
    } catch (e) {
      throw SmartAccountTransactionException.signingFailed(
        'Failed to build auth payload preimage',
        cause: e,
      );
    }

    Uint8List encodedPreimage;
    try {
      final stream = XdrDataOutputStream();
      XdrHashIDPreimage.encode(stream, preimage);
      encodedPreimage = Uint8List.fromList(stream.bytes);
    } catch (e) {
      throw SmartAccountTransactionException.signingFailed(
        'Failed to XDR encode auth payload preimage',
        cause: e,
      );
    }

    return Uint8List.fromList(crypto.sha256.convert(encodedPreimage).bytes);
  }

  /// Rebuilds an [XdrSorobanAuthorizationEntry] with [stampedInner] as the
  /// credentials body, preserving the credential arm.
  static XdrSorobanAuthorizationEntry _rebuildEntry(
    XdrSorobanAuthorizationEntry original,
    XdrSorobanAddressCredentials stampedInner,
  ) {
    return XdrSorobanAuthorizationEntry(
      _rebuildCredentials(original.credentials, stampedInner),
      original.rootInvocation,
    );
  }
}
