// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../../soroban/soroban_auth.dart';
import '../../util.dart';
import '../../xdr/xdr.dart';
import '../core/smart_account_constants.dart';
import '../core/smart_account_errors.dart';
import '../core/web_authn_provider.dart';
import 'oz_internal_pipeline_interfaces.dart';
import 'oz_secure_nonce.dart';
import 'oz_selected_signer.dart';
import 'oz_smart_account_builders.dart';
import 'oz_smart_account_events.dart';
import 'oz_smart_account_types.dart';
import 'oz_transaction_operations.dart';

/// Result of the [OZSignerManager.addNewPasskeySigner] end-to-end flow.
///
/// Carries the WebAuthn credential information from the registration
/// ceremony together with the on-chain transaction result produced by
/// adding the new passkey as a signer on the smart-account contract.
class AddPasskeySignerResult {
  /// Constructs a result wrapping the credential metadata and the
  /// matching transaction outcome.
  const AddPasskeySignerResult({
    required this.credentialId,
    required this.publicKey,
    required this.transactionResult,
  });

  /// Base64URL-encoded WebAuthn credential ID. Carries no padding.
  final String credentialId;

  /// Uncompressed secp256r1 public key. 65 bytes starting with `0x04`.
  final Uint8List publicKey;

  /// Transaction result from the on-chain signer addition.
  final TransactionResult transactionResult;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AddPasskeySignerResult) return false;
    return other.credentialId == credentialId &&
        Util.constantTimeEquals(other.publicKey, publicKey) &&
        other.transactionResult == transactionResult;
  }

  @override
  int get hashCode => Object.hash(
        credentialId,
        Object.hashAll(publicKey),
        transactionResult,
      );

  @override
  String toString() =>
      'AddPasskeySignerResult(credentialId: $credentialId, '
      'publicKey: ${publicKey.length} bytes, '
      'transactionResult: $transactionResult)';
}

/// Manager for smart-account signer operations.
///
/// Provides high-level operations for adding and removing signers on a
/// smart account. Supports three signer kinds:
///
/// - WebAuthn passkeys: secp256r1 signature verification via the
///   WebAuthn verifier contract.
/// - Delegated signers: Stellar accounts or contracts that authorise via
///   the built-in Soroban `require_auth` mechanism.
/// - Ed25519 signers: traditional Ed25519 keys verified by a deployed
///   Ed25519 verifier contract.
///
/// Each context rule may carry up to 15 signers. Signers are identified
/// on-chain by their representation (address for delegated, verifier
/// plus key data for external).
///
/// Every state-changing method accepts an optional [SelectedSigner]
/// list. An empty list (the default) uses the single-signer path,
/// authorising through the connected passkey. A non-empty list routes
/// to [OZMultiSignerManager.submitWithMultipleSigners] for multi-signer
/// authorisation.
class OZSignerManager {
  /// Constructs a signer manager bound to the supplied kit. Marked
  /// [internal] because consumers access the manager via
  /// `kit.signerManager`.
  @internal
  OZSignerManager(this._kit);

  final OZSmartAccountKitInterface _kit;

  /// Generates 32 cryptographically secure random bytes used as a
  /// WebAuthn challenge or user-id.
  ///
  /// Routes through the shared [OZSecureNonce] helper so every CSPRNG
  /// site in the OZ stack draws from the same cached `Random.secure()`
  /// source rather than constructing a fresh secure RNG per call.
  static Uint8List _randomBytes32() => OZSecureNonce.bytes(32);

  /// Registers a new WebAuthn passkey and adds it as a signer to a
  /// context rule.
  ///
  /// Flow:
  ///
  /// 1. Validate that a wallet is connected and a WebAuthn provider is
  ///    configured.
  /// 2. Generate 32-byte random challenge and user-id values.
  /// 3. Trigger the platform WebAuthn registration ceremony (biometric
  ///    prompt).
  /// 4. Base64URL-encode the credential ID for storage.
  /// 5. Persist the credential locally as pending.
  /// 6. Emit a [SmartAccountEventCredentialCreated] event.
  /// 7. Add the passkey signer on-chain via [addPasskey].
  ///
  /// Throws [WebAuthnNotSupported] when no WebAuthn provider is
  /// configured, [WalletNotConnected] when no wallet is connected,
  /// [WebAuthnRegistrationFailed] when the registration ceremony fails
  /// or is cancelled, and [SmartAccountException] for downstream
  /// storage or on-chain failures.
  Future<AddPasskeySignerResult> addNewPasskeySigner({
    required int contextRuleId,
    required String userName,
    List<SelectedSigner> selectedSigners = const <SelectedSigner>[],
    SubmissionMethod? forceMethod,
  }) async {
    final connected = _kit.requireConnected();

    final webauthnProvider = _kit.config.webauthnProvider;
    if (webauthnProvider == null) {
      throw WebAuthnException.notSupported(
        details: 'No WebAuthnProvider configured. Set webauthnProvider '
            'in config before calling addNewPasskeySigner().',
      );
    }

    final challengeData = _randomBytes32();
    final userIdData = _randomBytes32();

    final WebAuthnRegistrationResult registrationResult;
    try {
      registrationResult = await webauthnProvider.register(
        challenge: challengeData,
        userId: userIdData,
        userName: userName,
      );
    } catch (e) {
      throw WebAuthnException.registrationFailed(
        e.toString(),
        cause: e,
      );
    }

    final credentialIdBase64url =
        _base64UrlEncode(registrationResult.credentialId);

    final credential = await _credentialManager.createPendingCredential(
      credentialId: credentialIdBase64url,
      publicKey: registrationResult.publicKey,
      contractId: connected.contractId,
      transports: registrationResult.transports,
      deviceType: registrationResult.deviceType,
      backedUp: registrationResult.backedUp,
    );

    _kit.events.emit(
      SmartAccountEventCredentialCreated(credential: credential),
    );

    final transactionResult = await addPasskey(
      contextRuleId: contextRuleId,
      publicKey: registrationResult.publicKey,
      credentialId: registrationResult.credentialId,
      selectedSigners: selectedSigners,
      forceMethod: forceMethod,
    );

    return AddPasskeySignerResult(
      credentialId: credentialIdBase64url,
      publicKey: registrationResult.publicKey,
      transactionResult: transactionResult,
    );
  }

  OZWalletCredentialManagerInterface get _credentialManager =>
      _kit.credentialManager as OZWalletCredentialManagerInterface;

  /// Adds a WebAuthn passkey signer to [contextRuleId].
  ///
  /// Validates that [publicKey] is exactly 65 bytes, starts with the
  /// uncompressed-prefix byte `0x04`, and that [credentialId] is
  /// non-empty. Constructs an [OZExternalSigner] for WebAuthn and
  /// delegates to the private [_addSigner] helper.
  ///
  /// Throws [InvalidInput] on validation failure and propagates any
  /// transaction failures from the signing pipeline.
  Future<TransactionResult> addPasskey({
    required int contextRuleId,
    required Uint8List publicKey,
    required Uint8List credentialId,
    List<SelectedSigner> selectedSigners = const <SelectedSigner>[],
    SubmissionMethod? forceMethod,
  }) async {
    _kit.requireConnected();

    if (publicKey.length != SmartAccountConstants.secp256r1PublicKeySize) {
      throw ValidationException.invalidInput(
        'publicKey',
        'Public key must be ${SmartAccountConstants.secp256r1PublicKeySize} '
            'bytes, got: ${publicKey.length}',
      );
    }

    if (publicKey[0] != SmartAccountConstants.uncompressedPubkeyPrefix) {
      throw ValidationException.invalidInput(
        'publicKey',
        'Public key must start with 0x04 (uncompressed format), '
            'got: 0x${publicKey[0].toRadixString(16).padLeft(2, '0')}',
      );
    }

    if (credentialId.isEmpty) {
      throw ValidationException.invalidInput(
        'credentialId',
        'Credential ID cannot be empty',
      );
    }

    final signer = OZExternalSigner.webAuthn(
      verifierAddress: _kit.config.webauthnVerifierAddress,
      publicKey: publicKey,
      credentialId: credentialId,
    );

    return _addSigner(
      contextRuleId: contextRuleId,
      signer: signer,
      selectedSigners: selectedSigners,
      forceMethod: forceMethod,
    );
  }

  /// Adds a delegated signer to [contextRuleId].
  ///
  /// Builds an [OZDelegatedSigner] for [address] (validation happens in
  /// the signer constructor) and delegates to [_addSigner].
  Future<TransactionResult> addDelegated({
    required int contextRuleId,
    required String address,
    List<SelectedSigner> selectedSigners = const <SelectedSigner>[],
    SubmissionMethod? forceMethod,
  }) async {
    _kit.requireConnected();

    final signer = OZDelegatedSigner(address);

    return _addSigner(
      contextRuleId: contextRuleId,
      signer: signer,
      selectedSigners: selectedSigners,
      forceMethod: forceMethod,
    );
  }

  /// Adds an Ed25519 signer to [contextRuleId].
  ///
  /// Constructs an [OZExternalSigner] via the Ed25519 factory
  /// (validation happens in the factory) and delegates to [_addSigner].
  Future<TransactionResult> addEd25519({
    required int contextRuleId,
    required String verifierAddress,
    required Uint8List publicKey,
    List<SelectedSigner> selectedSigners = const <SelectedSigner>[],
    SubmissionMethod? forceMethod,
  }) async {
    _kit.requireConnected();

    final signer = OZExternalSigner.ed25519(
      verifierAddress: verifierAddress,
      publicKey: publicKey,
    );

    return _addSigner(
      contextRuleId: contextRuleId,
      signer: signer,
      selectedSigners: selectedSigners,
      forceMethod: forceMethod,
    );
  }

  /// Removes a signer from [contextRuleId] by its on-chain ID.
  ///
  /// Builds a `remove_signer(context_rule_id, signer_id)` invocation and
  /// routes through the single-signer or multi-signer path depending
  /// on whether [selectedSigners] is empty.
  ///
  /// IMPORTANT: the contract rejects removing the last signer from a
  /// rule that has no policies. Callers must ensure either at least
  /// one signer remains or that policies provide an authorisation path.
  Future<TransactionResult> removeSigner({
    required int contextRuleId,
    required int signerId,
    List<SelectedSigner> selectedSigners = const <SelectedSigner>[],
    SubmissionMethod? forceMethod,
  }) async {
    final connected = _kit.requireConnected();

    final functionArgs = <XdrSCVal>[
      XdrSCVal.forU32(contextRuleId),
      XdrSCVal.forU32(signerId),
    ];

    final hostFunction = XdrHostFunction.forInvokingContractWithArgs(
      XdrInvokeContractArgs(
        Address.forContractId(connected.contractId).toXdr(),
        'remove_signer',
        functionArgs,
      ),
    );

    return _route(hostFunction, selectedSigners, forceMethod);
  }

  /// Removes a signer from [contextRuleId] by matching the [signer]
  /// value.
  ///
  /// Fetches the target rule (single RPC), parses it, finds the
  /// matching signer index by [OZSmartAccountBuilders.signersEqual],
  /// and delegates to the ID-based [removeSigner] overload.
  ///
  /// Renamed from `removeSigner` (the ID-based form) because Dart does
  /// not support overload-by-parameter-type. The `BySigner` suffix
  /// mirrors the existing Flutter SDK convention for type-disambiguated
  /// overloads.
  ///
  /// Throws [InvalidInput] when the signer is not found on the rule or
  /// when the parsed `signerIds` list is shorter than `signers`.
  Future<TransactionResult> removeSignerBySigner({
    required int contextRuleId,
    required OZSmartAccountSigner signer,
    List<SelectedSigner> selectedSigners = const <SelectedSigner>[],
    SubmissionMethod? forceMethod,
  }) async {
    final ruleScVal = await _kit.contextRuleManager.getContextRule(
      contextRuleId,
    );
    final rule = _kit.contextRuleManager.parseContextRule(ruleScVal);

    var signerIndex = -1;
    for (var i = 0; i < rule.signers.length; i++) {
      if (OZSmartAccountBuilders.signersEqual(rule.signers[i], signer)) {
        signerIndex = i;
        break;
      }
    }

    if (signerIndex == -1) {
      throw ValidationException.invalidInput(
        'signer',
        'Signer not found on context rule $contextRuleId',
      );
    }

    if (signerIndex >= rule.signerIds.length) {
      throw ValidationException.invalidInput(
        'signer',
        'Signer found at index $signerIndex but signerIds has only '
            '${rule.signerIds.length} entries',
      );
    }

    return removeSigner(
      contextRuleId: contextRuleId,
      signerId: rule.signerIds[signerIndex],
      selectedSigners: selectedSigners,
      forceMethod: forceMethod,
    );
  }

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  Future<TransactionResult> _addSigner({
    required int contextRuleId,
    required OZSmartAccountSigner signer,
    required List<SelectedSigner> selectedSigners,
    required SubmissionMethod? forceMethod,
  }) async {
    final connected = _kit.requireConnected();

    final signerScVal = signer.toScVal();

    final functionArgs = <XdrSCVal>[
      XdrSCVal.forU32(contextRuleId),
      signerScVal,
    ];

    final hostFunction = XdrHostFunction.forInvokingContractWithArgs(
      XdrInvokeContractArgs(
        Address.forContractId(connected.contractId).toXdr(),
        'add_signer',
        functionArgs,
      ),
    );

    return _route(hostFunction, selectedSigners, forceMethod);
  }

  Future<TransactionResult> _route(
    XdrHostFunction hostFunction,
    List<SelectedSigner> selectedSigners,
    SubmissionMethod? forceMethod,
  ) async {
    if (selectedSigners.isEmpty) {
      return _transactionOperations.submit(
        hostFunction: hostFunction,
        auth: const <XdrSorobanAuthorizationEntry>[],
        forceMethod: forceMethod,
      );
    }
    final manager =
        _kit.multiSignerManager as OZMultiSignerManagerInterface;
    return manager.submitWithMultipleSigners(
      hostFunction: hostFunction,
      selectedSigners: selectedSigners,
      forceMethod: forceMethod,
    );
  }

  OZTransactionOperations get _transactionOperations =>
      (_kit as OZSmartAccountWalletKitInterface).transactionOperations;
}

String _base64UrlEncode(Uint8List bytes) {
  var encoded = base64Url.encode(bytes);
  while (encoded.isNotEmpty && encoded.endsWith('=')) {
    encoded = encoded.substring(0, encoded.length - 1);
  }
  return encoded;
}
