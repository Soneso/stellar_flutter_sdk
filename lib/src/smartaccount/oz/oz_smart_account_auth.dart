// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

import '../../network.dart';
import '../../soroban/soroban_auth.dart';
import '../../xdr/xdr.dart';
import '../core/smart_account_errors.dart';
import 'oz_auth_digest_scheme.dart';
import 'oz_smart_account_auth_payload.dart';
import 'oz_smart_account_types.dart';
import 'oz_smart_account_signatures.dart';

/// The digest that the `__check_auth` of an OpenZeppelin smart account build
/// checks.
///
/// Every signer of one auth entry commits to the same digest. Its form
/// depends on the code the smart account runs, so the kit reads the wallet's
/// WASM hash before each signing operation and selects the scheme through
/// [OZSmartAccountConfig.authDigestSchemes].
enum OZAuthDigestScheme {
  /// The digest of stellar-accounts 0.7:
  /// `auth_digest = SHA-256(signature_payload || XDR(ScVal::Vec([ScVal::U32(id), ...])))`.
  /// Delegated signers authorize `__check_auth(Bytes(auth_digest))`.
  legacyConcat,

  /// The digest of stellar-accounts 0.8.0:
  /// `auth_digest = SHA-256(XDR(AuthDigestPreimage))`, where
  /// `AuthDigestPreimage` is the `ScVal::Map` with the Symbol keys `account`
  /// (the smart account address), `context_rule_ids` (`Vec` of `U32`) and
  /// `signature_payload` (32 `Bytes`). Delegated signers authorize
  /// `__check_auth(AuthDigestPreimage)`.
  preimageV1,
}

/// The digest material every signer of one smart account auth entry commits
/// to, as [OZSmartAccountAuth.computeEntryAuthDigest] returns it.
class OZEntryAuthDigest {
  /// Constructs the digest material of one auth entry.
  const OZEntryAuthDigest({
    required this.signaturePayload,
    required this.authDigest,
    required this.delegatedAuthArgs,
  });

  /// The 32-byte payload the host passes to `__check_auth`.
  final Uint8List signaturePayload;

  /// The 32-byte digest that External signers (passkeys, Ed25519 keys) sign.
  final Uint8List authDigest;

  /// The `__check_auth` arguments that Delegated signers authorize.
  final List<XdrSCVal> delegatedAuthArgs;
}

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
///   payload, in the [OZAuthDigestScheme] of the code the smart account
///   runs: `SHA-256(signaturePayload || contextRuleIds.toXDR())` for
///   stellar-accounts 0.7 and `SHA-256(XDR(AuthDigestPreimage))` for
///   stellar-accounts 0.8.0 ([computeEntryAuthDigest]).
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

  /// Computes the stellar-accounts 0.7 auth digest,
  /// [OZAuthDigestScheme.legacyConcat] only.
  ///
  /// The digest is `SHA-256(signaturePayload || contextRuleIds.toXDR())`
  /// where `contextRuleIds.toXDR()` is the XDR encoding of
  /// `ScVal::Vec([ScVal::U32(id), ...])`. The OpenZeppelin Smart Account
  /// contract requires this binding so signers cannot be replayed against a
  /// different rule set. A wallet on stellar-accounts 0.8.0 checks the
  /// [OZAuthDigestScheme.preimageV1] digest instead, which this function
  /// cannot produce.
  ///
  /// Throws [SmartAccountTransactionSigningFailed] when XDR encoding of the rule-IDs
  /// vector fails.
  @Deprecated(
    'Computes the stellar-accounts 0.7 digest only. Use computeEntryAuthDigest '
    'with the OZAuthDigestScheme of the code the wallet runs.',
  )
  static Future<Uint8List> buildAuthDigest(
    Uint8List signaturePayload,
    List<int> contextRuleIds,
  ) async => _legacyAuthDigest(signaturePayload, contextRuleIds);

  /// Computes the signature payload, the auth digest and the delegated
  /// `__check_auth` arguments of a smart account auth [entry] for [scheme].
  ///
  /// The signature payload is [buildAuthPayloadHash] of the entry. With
  /// [OZAuthDigestScheme.legacyConcat] the digest is
  /// `SHA-256(signature_payload || XDR(ScVal::Vec([ScVal::U32(id), ...])))`
  /// and Delegated signers authorize `Bytes(auth_digest)`. With
  /// [OZAuthDigestScheme.preimageV1] the digest is
  /// `SHA-256(XDR(AuthDigestPreimage))`, the preimage binding the entry's
  /// credential address as the smart account, and Delegated signers
  /// authorize the preimage itself.
  ///
  /// The scheme must be the one the wallet's `__check_auth` checks. A
  /// signature over the other digest is rejected by the contract when the
  /// transaction is simulated or submitted, after every signer has signed,
  /// and nothing executes.
  ///
  /// ```dart
  /// final digest = await OZSmartAccountAuth.computeEntryAuthDigest(
  ///   authEntry,
  ///   latestLedger + 100,
  ///   Network.TESTNET.networkPassphrase,
  ///   <int>[0],
  ///   OZAuthDigestScheme.preimageV1,
  /// );
  /// // digest.authDigest is the WebAuthn challenge and the message an
  /// // Ed25519 signer signs.
  /// ```
  ///
  /// Parameters:
  ///
  /// - [entry]: the smart account authorization entry, with ADDRESS or
  ///   ADDRESS_V2 credentials.
  /// - [expirationLedger]: the ledger at which the signatures expire, a u32
  ///   value.
  /// - [networkPassphrase]: the network passphrase.
  /// - [contextRuleIds]: the context rule IDs the signatures satisfy, one
  ///   per auth context, each a u32 value.
  /// - [scheme]: the digest scheme of the code the smart account runs.
  ///
  /// Throws [SmartAccountInvalidInput] when [expirationLedger] or a context
  /// rule ID lies outside 0 to 4294967295, and
  /// [SmartAccountTransactionSigningFailed] when the credentials are not
  /// ADDRESS or ADDRESS_V2 or XDR encoding fails.
  static Future<OZEntryAuthDigest> computeEntryAuthDigest(
    XdrSorobanAuthorizationEntry entry,
    int expirationLedger,
    String networkPassphrase,
    List<int> contextRuleIds,
    OZAuthDigestScheme scheme,
  ) async {
    _requireUint32('expirationLedger', expirationLedger);
    for (final id in contextRuleIds) {
      _requireUint32('contextRuleIds', id);
    }

    final signaturePayload = await buildAuthPayloadHash(
      entry,
      expirationLedger,
      networkPassphrase,
    );
    switch (scheme) {
      case OZAuthDigestScheme.legacyConcat:
        final authDigest = _legacyAuthDigest(signaturePayload, contextRuleIds);
        return OZEntryAuthDigest(
          signaturePayload: signaturePayload,
          authDigest: authDigest,
          delegatedAuthArgs: <XdrSCVal>[XdrSCVal.forBytes(authDigest)],
        );
      case OZAuthDigestScheme.preimageV1:
        // buildAuthPayloadHash has already refused credentials without an
        // address.
        final account = _innerAddressCredentials(entry.credentials)!.address;
        final preimage = ozBuildAuthDigestPreimage(
          account,
          signaturePayload,
          contextRuleIds,
        );
        return OZEntryAuthDigest(
          signaturePayload: signaturePayload,
          authDigest: _sha256(_encodeScVal(preimage, 'AuthDigestPreimage')),
          delegatedAuthArgs: <XdrSCVal>[preimage],
        );
    }
  }

  static const int _uint32Max = 0xFFFFFFFF;

  /// Refuses a [value] that the XDR u32 encoding would wrap.
  static void _requireUint32(String field, int value) {
    if (value < 0 || value > _uint32Max) {
      throw SmartAccountValidationException.invalidInput(
        field,
        'must be a u32 value (0 to $_uint32Max), got: $value',
      );
    }
  }

  static Uint8List _legacyAuthDigest(
    Uint8List signaturePayload,
    List<int> contextRuleIds,
  ) {
    final ruleIdsScVal = XdrSCVal.forVec(
      contextRuleIds.map((id) => XdrSCVal.forU32(id)).toList(growable: false),
    );
    final ruleIdsXdr = _encodeScVal(ruleIdsScVal, 'context rule IDs ScVal');

    final concatenated = Uint8List(signaturePayload.length + ruleIdsXdr.length)
      ..setRange(0, signaturePayload.length, signaturePayload)
      ..setRange(
        signaturePayload.length,
        signaturePayload.length + ruleIdsXdr.length,
        ruleIdsXdr,
      );
    return _sha256(concatenated);
  }

  /// XDR-encodes [value].
  ///
  /// Throws [SmartAccountTransactionSigningFailed] naming [description] when
  /// XDR encoding fails.
  static Uint8List _encodeScVal(XdrSCVal value, String description) {
    try {
      final stream = XdrDataOutputStream();
      XdrSCVal.encode(stream, value);
      return Uint8List.fromList(stream.bytes);
    } catch (e) {
      throw SmartAccountTransactionException.signingFailed(
        'Failed to XDR encode $description',
        cause: e,
      );
    }
  }

  static Uint8List _sha256(Uint8List bytes) =>
      Uint8List.fromList(crypto.sha256.convert(bytes).bytes);

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
  /// Used when converting source-account credentials to fresh address
  /// credentials, typically for relayer fee sponsoring. [address], [nonce]
  /// and [expirationLedger] are the values the new credentials will carry;
  /// there are no existing address credentials to read them from.
  ///
  /// [useUpgradedAuth] selects the arm of those new credentials and with it
  /// the preimage:
  /// - `true` (the default): ADDRESS_V2 and the address-bound
  ///   ENVELOPE_TYPE_SOROBAN_AUTHORIZATION_WITH_ADDRESS
  ///   (networkID, nonce, signatureExpirationLedger, address, invocation).
  /// - `false`: legacy ADDRESS and ENVELOPE_TYPE_SOROBAN_AUTHORIZATION
  ///   (networkID, nonce, signatureExpirationLedger, invocation), which does
  ///   not cover the address.
  ///
  /// The returned hash is `SHA-256(XDR_encode(preimage))`. The host
  /// reconstructs the preimage from the submitted credentials, so [address]
  /// must be the address those credentials carry.
  ///
  /// Throws [SmartAccountTransactionSigningFailed] when XDR encoding fails.
  static Future<Uint8List> buildSourceAccountAuthPayloadHash(
    XdrSorobanAuthorizationEntry entry,
    XdrSCAddress address,
    XdrInt64 nonce,
    int expirationLedger,
    String networkPassphrase, {
    bool useUpgradedAuth = true,
  }) async {
    final addressCredentials = XdrSorobanAddressCredentials(
      address,
      nonce,
      XdrUint32(expirationLedger),
      XdrSCVal.forVoid(),
    );
    final syntheticEntry = XdrSorobanAuthorizationEntry(
      useUpgradedAuth
          ? XdrSorobanCredentials.forAddressV2Credentials(addressCredentials)
          : XdrSorobanCredentials.forAddressCredentials(addressCredentials),
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
    final existingPayload = OZSmartAccountAuthPayloadCodec.read(
      credentialsCopy.signature,
    );

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

    final existingPayload = OZSmartAccountAuthPayloadCodec.read(
      credentials.signature,
    );

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
