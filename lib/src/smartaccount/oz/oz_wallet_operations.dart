// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:dio/dio.dart' as dio;
import 'package:meta/meta.dart';

import '../../account.dart';
import '../../invoke_host_function_operation.dart';
import '../../memo.dart';
import '../../muxed_account.dart';
import '../../network.dart';
import '../../soroban/soroban_auth.dart';
import '../../soroban/soroban_server.dart';
import '../../transaction.dart';
import '../../util.dart';
import '../../xdr/xdr.dart';
import '../core/allow_credential.dart';
import '../core/smart_account_errors.dart';
import '../core/smart_account_utils.dart';
import '../core/web_authn_provider.dart';
import 'oz_base64url.dart';
import 'oz_constants.dart';
import 'oz_internal_pipeline_interfaces.dart';
import 'oz_policy_manager.dart';
import 'oz_relayer_client.dart';
import 'oz_secure_nonce.dart';
import 'oz_smart_account_events.dart';
import 'oz_smart_account_signatures.dart';
import 'oz_smart_account_types.dart';
import 'oz_storage_adapter.dart';
import 'oz_submission_routing.dart';
import 'oz_transaction_timeout.dart';
import 'oz_validation.dart';

// Public result types

/// Result of a wallet creation operation.
///
/// Contains the credential ID, contract address, public key, the signed
/// deploy transaction XDR (always present), and an optional transaction
/// hash when the wallet was auto-submitted.
///
/// The [signedTransactionXdr] field is always populated — the deploy
/// transaction is built and signed regardless of `autoSubmit`. When
/// `autoSubmit` is false the caller can use the XDR to submit externally
/// or store it for later submission via
/// [OZWalletOperations.deployPendingCredential].
class OZCreateWalletResult {
  /// Constructs a wallet-creation result.
  const OZCreateWalletResult({
    required this.credentialId,
    required this.contractId,
    required this.publicKey,
    required this.signedTransactionXdr,
    this.transactionHash,
    this.nickname,
  });

  /// Base64URL-encoded WebAuthn credential ID (no padding).
  final String credentialId;

  /// Smart account contract address (C-address).
  final String contractId;

  /// Uncompressed secp256r1 public key (65 bytes starting with `0x04`).
  final Uint8List publicKey;

  /// Base64-encoded signed deploy transaction envelope.
  final String signedTransactionXdr;

  /// Transaction hash when the wallet was auto-submitted, `null` otherwise.
  final String? transactionHash;

  /// User display name supplied at wallet-creation time.
  final String? nickname;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OZCreateWalletResult) return false;
    return credentialId == other.credentialId &&
        contractId == other.contractId &&
        Util.constantTimeEquals(publicKey, other.publicKey) &&
        signedTransactionXdr == other.signedTransactionXdr &&
        transactionHash == other.transactionHash &&
        nickname == other.nickname;
  }

  @override
  int get hashCode {
    var result = credentialId.hashCode;
    result = 31 * result + contractId.hashCode;
    result = 31 * result + _byteListContentHash(publicKey);
    result = 31 * result + signedTransactionXdr.hashCode;
    result = 31 * result + (transactionHash?.hashCode ?? 0);
    result = 31 * result + (nickname?.hashCode ?? 0);
    return result;
  }
}

/// Result of deploying a previously-pending credential.
///
/// Returned by [OZWalletOperations.deployPendingCredential] when retrying a
/// failed or deferred wallet deployment.
class OZDeployPendingResult {
  /// Constructs a deploy-pending result.
  const OZDeployPendingResult({
    required this.contractId,
    required this.signedTransactionXdr,
    this.transactionHash,
  });

  /// Smart account contract address (C-address).
  final String contractId;

  /// Base64-encoded signed deploy transaction envelope.
  final String signedTransactionXdr;

  /// Transaction hash when the deployment was auto-submitted, `null` when
  /// `autoSubmit` was false.
  final String? transactionHash;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OZDeployPendingResult) return false;
    return contractId == other.contractId &&
        signedTransactionXdr == other.signedTransactionXdr &&
        transactionHash == other.transactionHash;
  }

  @override
  int get hashCode =>
      Object.hash(contractId, signedTransactionXdr, transactionHash);
}

/// Result of a wallet connection attempt.
///
/// `connectWallet` returns one of two arms:
///
/// - [OZConnectWalletConnected]: a single contract was resolved for the
///   credential. The kit's connection state has been set and a session has
///   been saved.
/// - [OZConnectWalletAmbiguous]: the indexer reported multiple contracts for
///   the credential (the passkey is registered as a signer on more than
///   one contract). The kit's connection state has NOT been set — the
///   caller must let the user pick a contract and re-call `connectWallet`
///   with the chosen `contractId` to finalise.
///
/// [OZConnectWalletAmbiguous] is by construction unreachable when an
/// explicit `contractId` is supplied.
sealed class OZConnectWalletResult {
  /// Base sealed-class constructor.
  const OZConnectWalletResult();

  /// The credential ID (Base64URL-encoded, no padding).
  String get credentialId;
}

/// Wallet connection succeeded — a single contract resolved.
final class OZConnectWalletConnected extends OZConnectWalletResult {
  /// Constructs an [OZConnectWalletConnected] result.
  const OZConnectWalletConnected({
    required this.credentialId,
    required this.contractId,
    required this.restoredFromSession,
  });

  @override
  final String credentialId;

  /// Smart account contract address (C-address).
  final String contractId;

  /// Whether the connection was restored from a saved session.
  final bool restoredFromSession;

  /// Returns a copy of this result with the supplied fields replaced.
  OZConnectWalletConnected copyWith({
    String? credentialId,
    String? contractId,
    bool? restoredFromSession,
  }) {
    return OZConnectWalletConnected(
      credentialId: credentialId ?? this.credentialId,
      contractId: contractId ?? this.contractId,
      restoredFromSession: restoredFromSession ?? this.restoredFromSession,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OZConnectWalletConnected) return false;
    return credentialId == other.credentialId &&
        contractId == other.contractId &&
        restoredFromSession == other.restoredFromSession;
  }

  @override
  int get hashCode => Object.hash(credentialId, contractId, restoredFromSession);
}

/// Wallet connection produced multiple candidate contracts.
///
/// The kit's connected state is NOT set. Render a picker over [candidates]
/// and re-call `connectWallet` with the chosen contract.
final class OZConnectWalletAmbiguous extends OZConnectWalletResult {
  /// Constructs an [OZConnectWalletAmbiguous] result with the supplied
  /// candidates.
  const OZConnectWalletAmbiguous({
    required this.credentialId,
    required this.candidates,
  });

  @override
  final String credentialId;

  /// Candidate contract addresses returned by the indexer.
  final List<String> candidates;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OZConnectWalletAmbiguous) return false;
    return credentialId == other.credentialId &&
        _stringListEquals(candidates, other.candidates);
  }

  @override
  int get hashCode => Object.hash(credentialId, Object.hashAll(candidates));
}

/// Result of a successful headless [OZWalletOperations.connectToContract].
///
/// Carries only the connected contract address. Unlike
/// [OZConnectWalletConnected] there is no credential field: a headless
/// connection holds no passkey credential.
class OZConnectToContractResult {
  /// Constructs a headless connect result for [contractId].
  const OZConnectToContractResult({required this.contractId});

  /// Smart-account contract address now connected (C-address).
  final String contractId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OZConnectToContractResult) return false;
    return contractId == other.contractId;
  }

  @override
  int get hashCode => contractId.hashCode;
}

/// Result of standalone passkey authentication.
///
/// Contains the credential ID, normalised signature, and public key from a
/// WebAuthn authentication ceremony without connecting to a specific
/// wallet contract.
///
/// Use this with indexer lookups, manual contract connection, or
/// multi-signer flows that need pre-authenticated signatures.
class OZAuthenticatePasskeyResult {
  /// Constructs an authentication-result record.
  const OZAuthenticatePasskeyResult({
    required this.credentialId,
    required this.signature,
    required this.publicKey,
  });

  /// Base64URL-encoded credential ID (no padding).
  final String credentialId;

  /// WebAuthn signature with the normalised compact (low-S) signature.
  final OZWebAuthnSignature signature;

  /// Uncompressed secp256r1 public key (65 bytes) when the credential is in
  /// local storage; otherwise an empty list.
  final Uint8List publicKey;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OZAuthenticatePasskeyResult) return false;
    return credentialId == other.credentialId &&
        signature == other.signature &&
        Util.constantTimeEquals(publicKey, other.publicKey);
  }

  @override
  int get hashCode {
    var result = credentialId.hashCode;
    result = 31 * result + signature.hashCode;
    result = 31 * result + _byteListContentHash(publicKey);
    return result;
  }
}

/// Options for connecting to an existing wallet.
///
/// These options control how wallet connection is performed:
///
/// | Options                              | Behaviour |
/// |--------------------------------------|-----------|
/// | (default)                            | Silent session restore; returns null if no session |
/// | credentialId and/or contractId       | Direct connection; skips session check |
/// | fresh = true                         | Skip session; always WebAuthn |
/// | prompt = true                        | Session restore with WebAuthn fallback |
/// | fresh = true, prompt = true          | fresh takes priority; always WebAuthn |
class OZConnectWalletOptions {
  /// Constructs connection options with the supplied fields.
  const OZConnectWalletOptions({
    this.credentialId,
    this.contractId,
    this.fresh = false,
    this.prompt = false,
  });

  /// Connect directly with this credential ID. When non-null the cascade
  /// looks up the contract via storage, derivation, or indexer (subject to
  /// any explicit [contractId]).
  final String? credentialId;

  /// Connect directly to this contract. Must be accompanied by
  /// [credentialId]; supplying [contractId] alone is rejected.
  final String? contractId;

  /// Force fresh WebAuthn authentication, bypassing session restore.
  final bool fresh;

  /// Trigger WebAuthn when no valid session exists. When false (default)
  /// the absence of a session causes [OZWalletOperations.connectWallet] to
  /// return `null`.
  final bool prompt;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OZConnectWalletOptions) return false;
    return credentialId == other.credentialId &&
        contractId == other.contractId &&
        fresh == other.fresh &&
        prompt == other.prompt;
  }

  @override
  int get hashCode => Object.hash(credentialId, contractId, fresh, prompt);
}

// OZWalletOperations

/// Operations for creating, connecting to, and deploying OpenZeppelin smart
/// account wallets.
///
/// Provides high-level lifecycle management:
///
/// - Wallet creation with WebAuthn passkey generation.
/// - Contract deployment with deterministic address derivation.
/// - Wallet connection via session restoration or credential lookup
///   (storage → derivation → indexer cascade).
/// - Standalone passkey authentication for pre-connection flows.
/// - Retrying failed deployments via deploy-pending-credential.
///
/// Requires a WebAuthn provider to be configured on the kit before any
/// passkey-driven operation. The class works in tandem with the
/// smart-account kit; consumers reach it via `kit.walletOperations`.
class OZWalletOperations {
  /// Constructs the wallet-operations facade against the supplied kit.
  ///
  /// Marked [internal] to indicate consumers should reach this object via
  /// `kit.walletOperations` rather than constructing one directly. The kit
  /// retains a strong reference; the lifetime of this object is bound to
  /// the kit's lifetime.
  @internal
  OZWalletOperations(this._kit);

  final OZSmartAccountWalletKitInterface _kit;

  OZWalletCredentialManagerInterface get _credentialManager =>
      _kit.credentialManager;

  // Public API: create wallet

  /// Creates a new smart account wallet with WebAuthn passkey authentication.
  ///
  /// Registers a WebAuthn credential, derives the deterministic contract
  /// address, optionally deploys and funds the contract, then returns a
  /// [OZCreateWalletResult] containing the signed deploy transaction and the
  /// new contract address.
  ///
  /// [autoFund] requires [autoSubmit] to be `true` and a non-null
  /// [nativeTokenContract]; funding uses Friendbot and is testnet-only.
  ///
  /// The optional [policies] map installs policies on the new wallet's
  /// default context rule at deploy time (through the account constructor),
  /// keyed by policy contract address (C...) with the policy's install
  /// parameters as the value. When `null`,
  /// [OZSmartAccountConfig.defaultPolicies] applies; pass a map (including
  /// an empty one) to override it. At most [OZConstants.maxPolicies].
  /// Validated and encoded before the passkey ceremony, so an invalid
  /// policy configuration (including structurally invalid install
  /// parameters) fails without creating an orphaned credential.
  ///
  /// The optional [cancelToken] can be cancelled to abort an in-flight
  /// network request; cancellation surfaces as a [SmartAccountTransactionException].
  Future<OZCreateWalletResult> createWallet({
    String userName = 'Smart Account User',
    bool autoSubmit = false,
    bool autoFund = false,
    String? nativeTokenContract,
    OZSubmissionMethod? forceMethod,
    Map<String, OZPolicyInstallParams>? policies,
    dio.CancelToken? cancelToken,
  }) async {
    final webauthnProvider = _kit.config.webauthnProvider;
    if (webauthnProvider == null) {
      throw WebAuthnException.notSupported(
        details:
            'No WebAuthnProvider configured. Set webauthnProvider in config before calling createWallet().',
      );
    }

    if (autoFund && nativeTokenContract == null) {
      throw SmartAccountValidationException.invalidInput(
        'nativeTokenContract',
        'nativeTokenContract is required when autoFund is true',
      );
    }

    // Resolve, validate, and encode constructor policies before the passkey
    // ceremony, so an invalid policy configuration never orphans a freshly
    // created credential. Encoding runs here because the install params
    // validate their own structure in toScVal.
    final effectivePolicies = policies ?? _kit.config.defaultPolicies;
    requireValidPolicies(effectivePolicies);
    final encodedPolicies = <String, XdrSCVal>{
      for (final entry in effectivePolicies.entries)
        entry.key: entry.value.toScVal(),
    };

    _checkCancellation(cancelToken);

    final challengeData = _secureRandomBytes(32);
    final userIdData = _secureRandomBytes(32);

    final WebAuthnRegistrationResult registrationResult;
    try {
      registrationResult = await webauthnProvider.register(
        challenge: challengeData,
        userId: userIdData,
        userName: userName,
      );
    } catch (e) {
      if (e is WebAuthnException) rethrow;
      throw WebAuthnException.registrationFailed(
        'WebAuthn registration failed: $e',
        cause: e,
      );
    }

    final publicKey = SmartAccountUtils.extractPublicKeyFromRegistration(
      publicKey: registrationResult.publicKey,
      attestationObject: registrationResult.attestationObject,
    );

    final deployer = await _kit.getDeployer();
    final String contractId;
    try {
      contractId = SmartAccountUtils.deriveContractAddress(
        credentialId: registrationResult.credentialId,
        deployerPublicKey: deployer.accountId,
        networkPassphrase: _kit.config.networkPassphrase,
      );
    } on SmartAccountValidationException {
      rethrow;
    } on SmartAccountTransactionException {
      rethrow;
    } catch (e) {
      throw SmartAccountTransactionException.signingFailed(
        'Failed to derive contract address: $e',
        cause: e,
      );
    }

    final credentialIdBase64url =
        ozBase64UrlEncode(registrationResult.credentialId);

    final OZStoredCredential credential;
    try {
      credential = await _credentialManager.createPendingCredential(
        credentialId: credentialIdBase64url,
        publicKey: publicKey,
        contractId: contractId,
        nickname: userName,
        transports: registrationResult.transports,
        deviceType: registrationResult.deviceType,
        backedUp: registrationResult.backedUp,
      );
    } on SmartAccountCredentialException {
      rethrow;
    } on SmartAccountStorageException {
      rethrow;
    } catch (e) {
      throw SmartAccountStorageException.writeFailed(credentialIdBase64url, cause: e);
    }

    // Best-effort: marking the credential as primary is metadata-only.
    try {
      await _credentialManager.setPrimary(credentialIdBase64url);
    } catch (_) {
      // Non-critical — isPrimary is metadata only.
    }

    _kit.events.emit(OZSmartAccountEventCredentialCreated(credential: credential));

    await _kit.setConnectedState(
      credentialId: credentialIdBase64url,
      contractId: contractId,
    );

    _kit.events.emit(OZSmartAccountEventWalletConnected(
      contractId: contractId,
      credentialId: credentialIdBase64url,
    ));

    await _saveSession(
      credentialId: credentialIdBase64url,
      contractId: contractId,
    );

    _checkCancellation(cancelToken);

    final Transaction deployTransaction;
    try {
      deployTransaction = await _buildDeployTransaction(
        publicKey: publicKey,
        credentialId: registrationResult.credentialId,
        policies: encodedPolicies,
        forceMethod: forceMethod,
      );
    } catch (e) {
      try {
        await _credentialManager.markDeploymentFailed(
          credentialId: credentialIdBase64url,
          error: e is SmartAccountException ? e.message : 'Build failed: $e',
        );
      } catch (_) {
        // Non-critical — failure-marking is best-effort.
      }
      if (e is SmartAccountException) rethrow;
      throw SmartAccountTransactionException.submissionFailed(
        'Failed to build deploy transaction: $e',
        cause: e,
      );
    }
    final signedTxXdr = deployTransaction.toEnvelopeXdrBase64();

    String? transactionHash;
    if (autoSubmit) {
      _checkCancellation(cancelToken);
      transactionHash = await _submitDeployTransaction(
        transaction: deployTransaction,
        credentialIdBase64url: credentialIdBase64url,
        forceMethod: forceMethod,
        cancelToken: cancelToken,
      );

      if (autoFund) {
        final tokenContract = nativeTokenContract;
        if (tokenContract == null) {
          throw SmartAccountValidationException.invalidInput(
            'nativeTokenContract',
            'nativeTokenContract is required when autoFund is true',
          );
        }
        // Wait for RPC visibility of the deployed instance before fundWallet
        // simulates against it (see waitForContractVisibleToRpc).
        await waitForContractVisibleToRpc(contractId, cancelToken);
        await _kit.transactionOperations.fundWallet(
          nativeTokenContract: tokenContract,
          forceMethod: forceMethod,
          cancelToken: cancelToken,
        );
      }

      try {
        await _credentialManager.deleteCredential(
          credentialId: credentialIdBase64url,
        );
      } catch (_) {
        // Non-critical — credential is transitional after successful deploy.
      }
    }

    return OZCreateWalletResult(
      credentialId: credentialIdBase64url,
      contractId: contractId,
      publicKey: publicKey,
      signedTransactionXdr: signedTxXdr,
      transactionHash: transactionHash,
      nickname: userName,
    );
  }

  // Public API: connect wallet

  /// Connects to an existing smart account wallet.
  ///
  /// Returns an [OZConnectWalletResult] on success, or `null` when no valid
  /// session exists and neither [OZConnectWalletOptions.prompt] nor
  /// [OZConnectWalletOptions.fresh] is set.
  ///
  /// Resolution order: stored session → credential/contract hint →
  /// WebAuthn authentication → credential cascade (storage → derivation →
  /// indexer). When the indexer returns multiple candidates,
  /// [OZConnectWalletAmbiguous] is returned without setting connection state.
  ///
  /// The optional [cancelToken] can be cancelled to abort an in-flight
  /// network request; cancellation surfaces from any network step that
  /// observes the cancellation between awaits.
  Future<OZConnectWalletResult?> connectWallet({
    OZConnectWalletOptions options = const OZConnectWalletOptions(),
    dio.CancelToken? cancelToken,
  }) async {
    _checkCancellation(cancelToken);

    if (options.credentialId != null || options.contractId != null) {
      return _connectWithCredentials(
        credentialId: options.credentialId,
        contractId: options.contractId,
        cancelToken: cancelToken,
      );
    }

    if (!options.fresh) {
      OZStoredSession? session;
      try {
        session = await _kit.getStorage().getSession();
      } catch (_) {
        session = null;
      }

      if (session != null && !session.isExpired) {
        try {
          final result = await _connectWithCredentials(
            credentialId: session.credentialId,
            contractId: session.contractId,
            cancelToken: cancelToken,
          );
          if (result is OZConnectWalletConnected) {
            return result.copyWith(restoredFromSession: true);
          }
          // why: the session-restore path supplies an explicit contractId,
          // which bypasses the cascade and never returns
          // OZConnectWalletAmbiguous. This branch is therefore unreachable
          // in practice but surfaces a distinctive error if anything ever
          // changes the contract above.
          throw StateError(
            'Unreachable: connectWithCredentials with explicit contractId never returns OZConnectWalletAmbiguous',
          );
        } on SmartAccountWalletNotFound {
          // The stored contract is not on-chain. Clear the stale session and
          // fall through to the WebAuthn fallback below.
          try {
            await _kit.getStorage().clearSession();
          } catch (_) {
            // Non-critical — clearing is best-effort.
          }
        }
      }

      if (session != null && session.isExpired) {
        _kit.events.emit(OZSmartAccountEventSessionExpired(
          contractId: session.contractId,
          credentialId: session.credentialId,
        ));
        try {
          await _kit.getStorage().clearSession();
        } catch (_) {
          // Non-critical — clearing is best-effort.
        }
      }

      if (!options.prompt) {
        return null;
      }
    }

    final webauthnProvider = _kit.config.webauthnProvider;
    if (webauthnProvider == null) {
      throw WebAuthnException.notSupported(
        details:
            'No WebAuthnProvider configured. Set webauthnProvider in config before calling connectWallet().',
      );
    }

    final challengeData = _secureRandomBytes(32);

    final WebAuthnAuthenticationResult authenticationResult;
    try {
      authenticationResult = await webauthnProvider.authenticate(
        challenge: challengeData,
      );
    } catch (e) {
      if (e is WebAuthnException) rethrow;
      throw WebAuthnException.authenticationFailed(
        'WebAuthn authentication failed: $e',
        cause: e,
      );
    }

    final credentialIdBase64url =
        ozBase64UrlEncode(authenticationResult.credentialId);

    _checkCancellation(cancelToken);

    String? contractId = await _resolveViaStorage(credentialIdBase64url);

    if (contractId == null) {
      contractId = await _resolveViaDerivation(
        authenticationResult.credentialId,
      );
    }

    _checkCancellation(cancelToken);

    if (contractId == null) {
      final indexerResolution = await _resolveViaIndexer(
        credentialIdBase64url,
      );
      switch (indexerResolution) {
        case _IndexerResolvedSingle(:final contractId):
          // ignore: parameter_assignments
          // single-candidate hit: continue to end-of-cascade verify.
          return _finalizeConnect(
            credentialIdBase64url: credentialIdBase64url,
            finalContractId: contractId,
          );
        case _IndexerResolvedAmbiguous(:final candidates):
          return OZConnectWalletAmbiguous(
            credentialId: credentialIdBase64url,
            candidates: candidates,
          );
      }
    }

    return _finalizeConnect(
      credentialIdBase64url: credentialIdBase64url,
      finalContractId: contractId,
    );
  }

  /// Connects to an existing smart account by contract address alone, with no
  /// passkey credential.
  ///
  /// Intended for autonomous signing processes and backend services
  /// that operate a smart account through the multi-signer / external-signer
  /// path. Unlike [connectWallet], this method performs no WebAuthn ceremony,
  /// consults no indexer, and persists no session — it sets the in-memory
  /// connected state and returns.
  ///
  /// The resulting connection supports ONLY the multi-signer / external-signer
  /// pipeline (calls made with an explicit, non-empty `selectedSigners` list).
  /// The single-passkey operations — [OZTransactionOperations.submit],
  /// [OZTransactionOperations.executeAndSubmit],
  /// [OZTransactionOperations.transfer], [OZTransactionOperations.contractCall],
  /// and any manager call left at the default empty `selectedSigners` — throw
  /// [SmartAccountValidationException] because there is no passkey credential
  /// to sign with.
  ///
  /// Behaviour:
  /// 1. Validates [contractId] is a Stellar contract address (C-address).
  /// 2. Verifies the contract exists on-chain via the same instance-ledger
  ///    check used by [connectWallet].
  /// 3. Clears any persisted session (best-effort) so a later silent
  ///    reconnect does not resurrect a stale passkey session. Clearing is
  ///    best-effort: a persistent-storage write failure is swallowed rather
  ///    than failing the connect, so on such a failure a stale session may
  ///    survive and a later [connectWallet] could still restore it.
  /// 4. Sets the headless connected state: [contractId] is bound but no
  ///    passkey credential is present, so [OZSmartAccountKit.credentialId]
  ///    and [OZConnectedState.credentialId] read as `null` and
  ///    [OZSmartAccountKit.isHeadless] reads as `true`.
  /// 5. Emits [OZSmartAccountEventHeadlessConnected] (carrying only the
  ///    contract address — no credential).
  ///
  /// Does NOT save a session and does NOT touch the credential manager.
  ///
  /// The optional [cancelToken] can be cancelled to abort before the on-chain
  /// verification; cancellation surfaces as a [SmartAccountTransactionException].
  ///
  /// Throws [SmartAccountInvalidAddress] when [contractId] is not a valid
  /// C-address, and [SmartAccountWalletException.notFound] when no contract
  /// exists at [contractId].
  Future<OZConnectToContractResult> connectToContract(
    String contractId, {
    dio.CancelToken? cancelToken,
  }) async {
    _checkCancellation(cancelToken);

    // 1. Validate the address shape (CRC16-checked C-address).
    requireContractAddress(contractId, fieldName: 'contractId');

    // 2. Verify the contract exists on-chain (reuse the existing check).
    await _verifyContractExists(contractId);

    // 3. Clear any persisted session so a later silent connectWallet() restore
    //    cannot resurrect a stale passkey session that contradicts this
    //    headless in-memory state. Best-effort; a storage failure must not
    //    leave the kit unconnected.
    try {
      await _kit.getStorage().clearSession();
    } catch (_) {
      // Non-critical — clearing is best-effort.
    }

    // 4. Set the headless connected state: the contract address is bound but
    //    no passkey credential is present, so credentialId reads as null.
    await _kit.setHeadlessConnectedState(contractId: contractId);

    // 5. Emit the dedicated headless event. No WalletConnected event (its
    //    credentialId field is for passkey connections), no session save, no
    //    credential manager write.
    _kit.events.emit(
      OZSmartAccountEventHeadlessConnected(contractId: contractId),
    );

    return OZConnectToContractResult(contractId: contractId);
  }

  /// Performs the post-cascade verify, credential cleanup, state set,
  /// event emit, and session save. Used by both the WebAuthn cascade and
  /// (indirectly) by `_connectWithCredentials`.
  Future<OZConnectWalletConnected> _finalizeConnect({
    required String credentialIdBase64url,
    required String finalContractId,
  }) async {
    // End-of-cascade verify. Redundant for the derivation/indexer arms
    // but mandatory for storage hits and explicit-contractId paths.
    await _verifyContractExists(finalContractId);

    try {
      await _credentialManager.deleteCredential(
        credentialId: credentialIdBase64url,
      );
    } catch (_) {
      // Non-critical — credential is transitional once connected.
    }

    await _kit.setConnectedState(
      credentialId: credentialIdBase64url,
      contractId: finalContractId,
    );

    _kit.events.emit(OZSmartAccountEventWalletConnected(
      contractId: finalContractId,
      credentialId: credentialIdBase64url,
    ));

    await _saveSession(
      credentialId: credentialIdBase64url,
      contractId: finalContractId,
    );

    return OZConnectWalletConnected(
      credentialId: credentialIdBase64url,
      contractId: finalContractId,
      restoredFromSession: false,
    );
  }

  // Public API: authenticate passkey

  /// Authenticates with a passkey without connecting to a wallet.
  ///
  /// Performs a WebAuthn authentication ceremony and returns the credential
  /// ID, normalised signature, and public key (when available locally)
  /// without modifying the kit's connection state.
  ///
  /// Typical usage patterns:
  ///
  /// 1. Authenticate, then discover contracts via the indexer.
  /// 2. Pre-authenticate before contract selection.
  /// 3. Authenticate for multi-signer operations that need a signature but
  ///    not a connected wallet state.
  ///
  /// The optional [cancelToken] can be cancelled to abort an in-flight
  /// request; cancellation is observed between the credential-lookup
  /// awaits and surfaces as a [SmartAccountTransactionException] from
  /// [_checkCancellation].
  Future<OZAuthenticatePasskeyResult> authenticatePasskey({
    Uint8List? challenge,
    List<String>? credentialIds,
    dio.CancelToken? cancelToken,
  }) async {
    final webauthnProvider = _kit.config.webauthnProvider;
    if (webauthnProvider == null) {
      throw WebAuthnException.notSupported(
        details:
            'No WebAuthnProvider configured. Set webauthnProvider in config before calling authenticatePasskey().',
      );
    }

    _checkCancellation(cancelToken);

    final challengeData = challenge ?? _secureRandomBytes(32);

    List<WebAuthnAllowCredential>? allowCredentials;
    if (credentialIds != null) {
      allowCredentials = <WebAuthnAllowCredential>[];
      for (final rawCredIdStr in credentialIds) {
        _checkCancellation(cancelToken);
        // why: storage entries are keyed under the unpadded Base64URL form
        // produced by the connect path. Normalise here so a padded caller
        // input still hits the matching storage entry for transport hints.
        final credIdStr = ozStripBase64UrlPadding(rawCredIdStr);
        final idBytes = ozBase64UrlDecode(credIdStr);
        OZStoredCredential? stored;
        try {
          stored = await _kit.getStorage().get(credIdStr);
        } catch (_) {
          stored = null;
        }
        allowCredentials.add(WebAuthnAllowCredential(
          id: idBytes,
          transports: stored?.transports,
        ));
      }
    }

    _checkCancellation(cancelToken);

    final WebAuthnAuthenticationResult authenticationResult;
    try {
      authenticationResult = await webauthnProvider.authenticate(
        challenge: challengeData,
        allowCredentials: allowCredentials,
      );
    } catch (e) {
      if (e is WebAuthnException) rethrow;
      throw WebAuthnException.authenticationFailed(
        'WebAuthn authentication failed: $e',
        cause: e,
      );
    }

    // why: when the caller restricted the authentication to specific
    // credentialIds, verify the returned credentialId is in the list — a
    // misbehaving provider could otherwise hand back a signature from a
    // credential the caller didn't authorise.
    if (allowCredentials != null && allowCredentials.isNotEmpty) {
      var matched = false;
      for (final allow in allowCredentials) {
        if (Util.constantTimeEquals(allow.id, authenticationResult.credentialId)) {
          matched = true;
          break;
        }
      }
      if (!matched) {
        throw SmartAccountCredentialException.invalid(
          'WebAuthn provider returned a signature for a credential not in the requested allowCredentials set',
        );
      }
    }

    final credentialIdBase64url =
        ozBase64UrlEncode(authenticationResult.credentialId);

    final Uint8List normalizedSignature;
    try {
      normalizedSignature = SmartAccountUtils.normalizeSignature(
        authenticationResult.signature,
      );
    } on SmartAccountValidationException {
      rethrow;
    } catch (e) {
      throw SmartAccountValidationException.invalidInput(
        'signature',
        'Failed to normalize WebAuthn signature: $e',
        cause: e,
      );
    }

    final OZWebAuthnSignature webAuthnSignature;
    try {
      webAuthnSignature = OZWebAuthnSignature(
        authenticatorData: authenticationResult.authenticatorData,
        clientData: authenticationResult.clientDataJSON,
        signature: normalizedSignature,
      );
    } on SmartAccountValidationException {
      rethrow;
    } catch (e) {
      throw SmartAccountValidationException.invalidInput(
        'signature',
        'Failed to build WebAuthn signature: $e',
        cause: e,
      );
    }

    var publicKey = Uint8List(0);
    try {
      final storedCredential = await _credentialManager.getCredential(
        credentialIdBase64url,
      );
      if (storedCredential != null) {
        publicKey = storedCredential.publicKey;
      }
    } catch (_) {
      // Storage lookup failed — continue with an empty public key. Callers
      // can retrieve it from the indexer or chain state.
    }

    return OZAuthenticatePasskeyResult(
      credentialId: credentialIdBase64url,
      signature: webAuthnSignature,
      publicKey: publicKey,
    );
  }

  // Public API: deploy pending credential

  /// Deploys a wallet from a previously-created pending credential.
  ///
  /// Use this to retry a failed deployment, or to submit a wallet that was
  /// created with `autoSubmit = false`. The credential must already exist
  /// in local storage with a non-empty `publicKey` and `contractId`.
  ///
  /// Sets the kit's connected state on success, in line with [createWallet],
  /// so the kit is ready immediately after a successful deployment.
  ///
  /// The optional [policies] map installs policies on the wallet's default
  /// context rule at deploy time (through the account constructor), keyed
  /// by policy contract address (C...). When `null`,
  /// [OZSmartAccountConfig.defaultPolicies] applies; pass a map (including
  /// an empty one) to override it. At most [OZConstants.maxPolicies].
  /// Constructor arguments are not part of the contract-address preimage,
  /// so the derived address is unchanged by the policies.
  Future<OZDeployPendingResult> deployPendingCredential({
    required String credentialId,
    bool autoSubmit = true,
    bool autoFund = false,
    String? nativeTokenContract,
    OZSubmissionMethod? forceMethod,
    Map<String, OZPolicyInstallParams>? policies,
    dio.CancelToken? cancelToken,
  }) async {
    if (autoFund && nativeTokenContract == null) {
      throw SmartAccountValidationException.invalidInput(
        'nativeTokenContract',
        'nativeTokenContract is required when autoFund is true',
      );
    }

    // Resolve, validate, and encode constructor policies early, before any
    // storage or network access. Encoding runs here because the install
    // params validate their own structure in toScVal.
    final effectivePolicies = policies ?? _kit.config.defaultPolicies;
    requireValidPolicies(effectivePolicies);
    final encodedPolicies = <String, XdrSCVal>{
      for (final entry in effectivePolicies.entries)
        entry.key: entry.value.toScVal(),
    };

    // Normalise to the canonical unpadded Base64URL form; see
    // ozStripBase64UrlPadding.
    credentialId = ozStripBase64UrlPadding(credentialId);

    _checkCancellation(cancelToken);

    final credential = await _credentialManager.getCredential(credentialId);
    if (credential == null) {
      throw SmartAccountCredentialException.notFound(credentialId);
    }

    final publicKey = credential.publicKey;
    if (publicKey.isEmpty) {
      throw SmartAccountCredentialException.invalid(
        "Credential '$credentialId' is missing publicKey",
      );
    }
    final contractId = credential.contractId;
    if (contractId == null || contractId.isEmpty) {
      throw SmartAccountCredentialException.invalid(
        "Credential '$credentialId' is missing contractId",
      );
    }

    final Uint8List credentialIdBytes;
    try {
      credentialIdBytes = ozBase64UrlDecode(credentialId);
    } catch (e) {
      throw SmartAccountCredentialException.invalid(
        'Invalid Base64URL-encoded credential ID: $credentialId',
        cause: e,
      );
    }

    await _kit.setConnectedState(
      credentialId: credentialId,
      contractId: contractId,
    );

    _kit.events.emit(OZSmartAccountEventWalletConnected(
      contractId: contractId,
      credentialId: credentialId,
    ));

    await _saveSession(
      credentialId: credentialId,
      contractId: contractId,
    );

    final Transaction deployTransaction;
    try {
      deployTransaction = await _buildDeployTransaction(
        publicKey: publicKey,
        credentialId: credentialIdBytes,
        policies: encodedPolicies,
        forceMethod: forceMethod,
      );
    } catch (e) {
      try {
        await _credentialManager.markDeploymentFailed(
          credentialId: credentialId,
          error: e is SmartAccountException ? e.message : 'Build failed: $e',
        );
      } catch (_) {
        // Non-critical — failure-marking is best-effort.
      }
      if (e is SmartAccountException) rethrow;
      throw SmartAccountTransactionException.submissionFailed(
        'Failed to build deploy transaction: $e',
        cause: e,
      );
    }
    final signedTxXdr = deployTransaction.toEnvelopeXdrBase64();

    if (!autoSubmit) {
      return OZDeployPendingResult(
        contractId: contractId,
        signedTransactionXdr: signedTxXdr,
      );
    }

    _checkCancellation(cancelToken);

    final hash = await _submitDeployTransaction(
      transaction: deployTransaction,
      credentialIdBase64url: credentialId,
      forceMethod: forceMethod,
      cancelToken: cancelToken,
    );

    if (autoFund) {
      // Wait for RPC visibility of the deployed instance before fundWallet
      // simulates against it (see waitForContractVisibleToRpc).
      await waitForContractVisibleToRpc(contractId, cancelToken);
      await _kit.transactionOperations.fundWallet(
        nativeTokenContract: nativeTokenContract!,
        forceMethod: forceMethod,
        cancelToken: cancelToken,
      );
    }

    try {
      await _credentialManager.deleteCredential(credentialId: credentialId);
    } catch (_) {
      // Non-critical — credential is transitional after a successful deploy.
    }

    return OZDeployPendingResult(
      contractId: contractId,
      signedTransactionXdr: signedTxXdr,
      transactionHash: hash,
    );
  }

  // Private: connect-with-credentials (the cascade implementation)

  Future<OZConnectWalletResult> _connectWithCredentials({
    String? credentialId,
    String? contractId,
    dio.CancelToken? cancelToken,
  }) async {
    if (contractId != null && credentialId == null) {
      throw SmartAccountValidationException.invalidInput(
        'contractId',
        'contractId option requires credentialId to be provided',
      );
    }

    // Normalise to the canonical unpadded Base64URL form; see
    // ozStripBase64UrlPadding.
    if (credentialId != null) {
      credentialId = ozStripBase64UrlPadding(credentialId);
    }

    String? finalContractId = contractId;

    // why: the explicit-contractId path bypasses the cascade, so without
    // this guard a caller could connect to a stored credential whose
    // deployment is known to have failed. Apply the deployment-status
    // check up-front whenever a credentialId is supplied so the error
    // surfaces consistently regardless of whether contractId is also
    // provided.
    OZStoredCredential? storedCredential;
    if (credentialId != null) {
      storedCredential = await _fetchStoredCredential(credentialId);
      if (storedCredential != null &&
          storedCredential.deploymentStatus ==
              OZCredentialDeploymentStatus.failed) {
        throw SmartAccountWalletException.notFound(
          'Smart account deployment previously failed for credential $credentialId. '
          'Call deployPendingCredential() to retry, or deleteCredential() to start over.',
        );
      }
    }

    _checkCancellation(cancelToken);

    if (credentialId != null && finalContractId == null) {
      // Storage stage: reuse the credential we already fetched.
      if (storedCredential != null) {
        finalContractId = storedCredential.contractId;
      }

      if (finalContractId == null) {
        final Uint8List credentialIdBytes;
        try {
          credentialIdBytes = ozBase64UrlDecode(credentialId);
        } catch (e) {
          throw SmartAccountValidationException.invalidInput(
            'credentialId',
            'Invalid Base64URL-encoded credential ID',
            cause: e,
          );
        }
        finalContractId = await _resolveViaDerivation(credentialIdBytes);
      }

      _checkCancellation(cancelToken);

      if (finalContractId == null) {
        final indexerResolution = await _resolveViaIndexer(credentialId);
        switch (indexerResolution) {
          case _IndexerResolvedSingle(:final contractId):
            finalContractId = contractId;
          case _IndexerResolvedAmbiguous(:final candidates):
            return OZConnectWalletAmbiguous(
              credentialId: credentialId,
              candidates: candidates,
            );
        }
      }
    }

    if (credentialId == null || finalContractId == null) {
      throw SmartAccountWalletException.notFound(
        'Could not determine credential ID or contract ID',
      );
    }

    return _finalizeConnect(
      credentialIdBase64url: credentialId,
      finalContractId: finalContractId,
    );
  }

  // Private: cascade-stage helpers

  /// Returns the stored credential under [credentialId] or `null` when
  /// storage misses or raises. Swallows storage exceptions because storage
  /// is an optional cache for the credential lifecycle.
  Future<OZStoredCredential?> _fetchStoredCredential(String credentialId) async {
    try {
      return await _credentialManager.getCredential(credentialId);
    } catch (_) {
      return null;
    }
  }

  /// Stage A of the credential cascade: storage lookup.
  ///
  /// Returns the stored credential's `contractId` when present and the
  /// credential's deployment status is not `failed`. Throws
  /// [SmartAccountWalletException.notFound] when the credential is present but its
  /// deployment is marked failed.
  Future<String?> _resolveViaStorage(String credentialIdBase64url) async {
    final stored = await _fetchStoredCredential(credentialIdBase64url);
    if (stored == null) return null;
    if (stored.deploymentStatus == OZCredentialDeploymentStatus.failed) {
      throw SmartAccountWalletException.notFound(
        'Smart account deployment previously failed for credential $credentialIdBase64url. '
        'Call deployPendingCredential() to retry, or deleteCredential() to start over.',
      );
    }
    return stored.contractId;
  }

  /// Stage B of the credential cascade: deterministic address derivation.
  ///
  /// Returns the derived `contractId` when the on-chain instance exists;
  /// returns `null` when the derived address has no contract (Stage C
  /// fallback). Errors other than [SmartAccountWalletNotFound] propagate so callers
  /// can distinguish "not deployed" from "lookup failed".
  Future<String?> _resolveViaDerivation(Uint8List credentialIdBytes) async {
    final deployer = await _kit.getDeployer();
    final derivedContractId = SmartAccountUtils.deriveContractAddress(
      credentialId: credentialIdBytes,
      deployerPublicKey: deployer.accountId,
      networkPassphrase: _kit.config.networkPassphrase,
    );
    try {
      await _verifyContractExists(derivedContractId);
      return derivedContractId;
    } on SmartAccountWalletNotFound {
      return null;
    }
  }

  /// Stage C of the credential cascade: indexer lookup.
  ///
  /// Filters the indexer's candidate set through [_verifyContractExists];
  /// returns an [_IndexerResolvedSingle] when exactly one candidate
  /// verifies, or an [_IndexerResolvedAmbiguous] when two or more do.
  /// Throws [SmartAccountWalletException.notFound] when no indexer is configured, the
  /// indexer returned no candidates, or every candidate failed to verify.
  Future<_IndexerResolved> _resolveViaIndexer(String credentialId) async {
    final indexer = _kit.indexerClient;
    if (indexer == null) {
      throw SmartAccountWalletException.notFound(
        'Could not resolve contract for credential $credentialId. '
        'No contract was found at the derived address and no indexer is configured.',
      );
    }
    final response = await indexer.lookupByCredentialId(credentialId);
    final candidates = response.contracts;
    if (candidates.isEmpty) {
      throw SmartAccountWalletException.notFound(
        'No contract found for credential $credentialId.',
      );
    }
    if (candidates.length == 1) {
      final candidate = candidates.first.contractId;
      await _verifyContractExists(candidate);
      return _IndexerResolvedSingle(candidate);
    }
    // why: indexer results may include candidates that no longer
    // exist on-chain. Verify each candidate; collapse to a single
    // hit when only one verifies, treat an empty set as not-found,
    // and surface Ambiguous only when two or more remain.
    final verifiedCandidates = await _filterVerifiedCandidates(
      candidates.map((c) => c.contractId),
    );
    if (verifiedCandidates.isEmpty) {
      throw SmartAccountWalletException.notFound(
        'No on-chain contract found for credential $credentialId.',
      );
    }
    if (verifiedCandidates.length == 1) {
      return _IndexerResolvedSingle(verifiedCandidates.first);
    }
    return _IndexerResolvedAmbiguous(
      List<String>.unmodifiable(verifiedCandidates),
    );
  }

  // Private: verify contract on-chain

  /// Returns the subset of [candidateContractIds] whose contracts can be
  /// confirmed to exist on-chain via [_verifyContractExists].
  ///
  /// Candidates whose verification raises [SmartAccountWalletNotFound] are silently
  /// dropped; other errors propagate so callers can distinguish "missing
  /// on-chain" from "inconclusive lookup".
  Future<List<String>> _filterVerifiedCandidates(
    Iterable<String> candidateContractIds,
  ) async {
    final verified = <String>[];
    for (final id in candidateContractIds) {
      try {
        await _verifyContractExists(id);
        verified.add(id);
      } on SmartAccountWalletNotFound {
        // Indexer surfaced a stale or unmaterialised contract; skip it.
      }
    }
    return verified;
  }

  /// Verifies a smart account contract exists on-chain by checking its
  /// instance ledger entry.
  ///
  /// Returns normally when the entry is present (live or archived — the
  /// RPC's `getLedgerEntries` surfaces archived entries as real entries).
  /// Throws [SmartAccountWalletNotFound] when the contract address is malformed or
  /// when no entry exists. Other exceptions propagate so the caller can
  /// distinguish "not on-chain" from "inconclusive lookup".
  Future<void> _verifyContractExists(String contractId) async {
    final LedgerEntry? instanceEntry;
    try {
      instanceEntry = await _kit.sorobanServer.getContractData(
        contractId,
        XdrSCVal.forLedgerKeyContractInstance(),
        XdrContractDataDurability.PERSISTENT,
      );
    } on ArgumentError catch (e) {
      // Malformed C-address — by definition cannot have a contract.
      throw SmartAccountWalletException.notFound(
        'Invalid contract address: $contractId (${e.message})',
      );
    } catch (e) {
      // Non-ArgumentError exceptions from the contract-data lookup may be
      // caused by malformed addresses raised as plain exceptions; classify
      // by inspecting the message for the well-known "Invalid contract"
      // pattern, otherwise rethrow as-is.
      final msg = e.toString();
      if (msg.contains('Invalid contract') ||
          msg.contains('Could not convert contract id')) {
        throw SmartAccountWalletException.notFound(
          'Invalid contract address: $contractId ($msg)',
        );
      }
      rethrow;
    }
    if (instanceEntry == null) {
      throw SmartAccountWalletException.notFound(
        'Contract not found at address: $contractId',
      );
    }
  }

  // Private: session persistence

  Future<void> _saveSession({
    required String credentialId,
    required String contractId,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final session = OZStoredSession(
      credentialId: credentialId,
      contractId: contractId,
      connectedAt: now,
      expiresAt: now + _kit.config.sessionExpiryMs,
    );
    await _kit.getStorage().saveSession(session);
  }

  // Private: build deploy transaction

  /// Builds, simulates, assembles, and signs the deploy transaction.
  ///
  /// Side-effect-free: callers handle failure-marking outside this method.
  /// When a relayer is configured (and [forceMethod] does not override) the
  /// fee is set to the resource fee only — the relayer wraps the
  /// transaction in a fee-bump with the outer fee.
  ///
  /// [policies] carries the pre-validated and pre-encoded constructor
  /// policies for the default context rule (policy contract address to
  /// encoded install-param ScVal); an empty map
  /// installs none.
  Future<Transaction> _buildDeployTransaction({
    required Uint8List publicKey,
    required Uint8List credentialId,
    required Map<String, XdrSCVal> policies,
    OZSubmissionMethod? forceMethod,
  }) async {
    final keyData = Uint8List(publicKey.length + credentialId.length)
      ..setRange(0, publicKey.length, publicKey)
      ..setRange(publicKey.length, publicKey.length + credentialId.length,
          credentialId);

    final OZExternalSigner webauthnSigner;
    try {
      webauthnSigner = OZExternalSigner(
        _kit.config.webauthnVerifierAddress,
        keyData,
      );
    } catch (e) {
      throw SmartAccountTransactionException.signingFailed(
        'Failed to create WebAuthn signer: $e',
        cause: e,
      );
    }

    final XdrSCVal signersScVal;
    try {
      signersScVal = XdrSCVal.forVec(<XdrSCVal>[webauthnSigner.toScVal()]);
    } catch (e) {
      throw SmartAccountTransactionException.signingFailed(
        'Failed to convert signer to ScVal: $e',
        cause: e,
      );
    }

    // Policies installed on the default context rule, keyed by policy
    // contract address and sorted into the host's ScMap key order. The keys
    // were validated and the values encoded before this method runs.
    final policiesScVal = OZPolicyManager.policiesToScVal(policies);

    final constructorArgs = <XdrSCVal>[signersScVal, policiesScVal];

    final deployer = await _kit.getDeployer();
    final salt = SmartAccountUtils.getContractSalt(credentialId);

    final deployerSCAddress = Address.forAccountId(deployer.accountId).toXdr();
    final contractIdPreimage = XdrContractIDPreimage.forAddress(
      deployerSCAddress,
      salt,
    );

    final wasmHashBytes = Util.hexToBytes(_kit.config.accountWasmHash);
    final contractExecutable = XdrContractExecutable.forWasm(wasmHashBytes);

    final createContractArgs = XdrCreateContractArgsV2(
      contractIdPreimage,
      contractExecutable,
      constructorArgs,
    );
    final hostFunction = XdrHostFunction(
      XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT_V2,
    );
    hostFunction.createContractV2 = createContractArgs;

    final operation = InvokeHostFunctionOperation(
      HostFunction.fromXdr(hostFunction),
      auth: const <SorobanAuthorizationEntry>[],
    );
    operation.sourceAccount = MuxedAccount.fromAccountId(deployer.accountId);

    final Account deployerAccount;
    try {
      final fetched = await _kit.sorobanServer.getAccount(deployer.accountId);
      if (fetched == null) {
        throw SmartAccountTransactionException.submissionFailed(
          'Deployer account not found: ${deployer.accountId}',
        );
      }
      deployerAccount = fetched;
    } catch (e) {
      if (e is SmartAccountTransactionException) rethrow;
      throw SmartAccountTransactionException.submissionFailed(
        'Failed to fetch deployer account: $e',
        cause: e,
      );
    }

    final Transaction transaction;
    try {
      transaction = TransactionBuilder(deployerAccount)
          .setMaxOperationFee(AbstractTransaction.MIN_BASE_FEE)
          .addOperation(operation)
          .addMemo(Memo.none())
          .addPreconditions(
              buildTimeoutPreconditions(_kit.config.timeoutInSeconds))
          .build();
    } catch (e) {
      throw SmartAccountTransactionException.signingFailed(
        'Failed to build transaction: $e',
        cause: e,
      );
    }

    final SimulateTransactionResponse simulation;
    try {
      simulation = await _kit.sorobanServer
          .simulateTransaction(SimulateTransactionRequest(transaction));
    } catch (e) {
      throw SmartAccountTransactionException.simulationFailed(
        'Failed to simulate deployment transaction: $e',
        cause: e,
      );
    }

    final simError = simulation.resultError ?? simulation.error?.message;
    if (simError != null && simError.isNotEmpty) {
      throw SmartAccountTransactionException.simulationFailed('Simulation error: $simError');
    }

    final minResourceFee = simulation.minResourceFee;
    if (minResourceFee == null) {
      throw SmartAccountTransactionException.submissionFailed(
        'Failed to get min resource fee from simulation',
      );
    }

    final useRelayer = ozResolveSubmissionMethod(_kit, forceMethod) ==
        OZSubmissionMethod.relayer;

    if (simulation.transactionData != null) {
      transaction.sorobanTransactionData = simulation.transactionData;
    }
    final sorobanAuth = simulation.getSorobanAuth();
    if (sorobanAuth != null) {
      transaction.setSorobanAuth(sorobanAuth);
    }

    if (useRelayer) {
      // why: the relayer wraps the inner transaction in a fee-bump, so the
      // inner fee must equal exactly the resource fee (the relayer pays the
      // base fee on the outer fee bump). Without this adjustment the
      // relayer-bumped envelope double-charges the base fee.
      transaction.fee = minResourceFee;
    } else {
      transaction.addResourceFee(minResourceFee);
    }

    try {
      transaction.sign(deployer, Network(_kit.config.networkPassphrase));
    } catch (e) {
      throw SmartAccountTransactionException.signingFailed(
        'Failed to sign transaction: $e',
        cause: e,
      );
    }

    return transaction;
  }

  // Private: submit deploy transaction

  /// Submits a pre-built and pre-signed deploy transaction via relayer or
  /// direct RPC. Marks the credential as failed on submission errors and
  /// polls for on-chain confirmation. Returns the confirmed transaction
  /// hash.
  Future<String> _submitDeployTransaction({
    required Transaction transaction,
    required String credentialIdBase64url,
    OZSubmissionMethod? forceMethod,
    dio.CancelToken? cancelToken,
  }) async {
    final useRelayer = ozResolveSubmissionMethod(_kit, forceMethod) ==
        OZSubmissionMethod.relayer;

    final String transactionHash;
    if (useRelayer) {
      final relayer = _kit.relayerClient;
      if (relayer == null) {
        throw SmartAccountTransactionException.submissionFailed(
          'Relayer was selected but no relayer is configured',
        );
      }
      final txEnvelope = transaction.toEnvelopeXdr();

      final OZRelayerResponse relayerResponse;
      try {
        relayerResponse = await relayer.sendXdr(
          txEnvelope,
          cancelToken: cancelToken,
        );
      } catch (e) {
        try {
          await _credentialManager.markDeploymentFailed(
            credentialId: credentialIdBase64url,
            error: 'Relayer submission failed: $e',
          );
        } catch (_) {}
        throw SmartAccountTransactionException.submissionFailed(
          'Failed to submit deployment via relayer: $e',
          cause: e,
        );
      }

      if (!relayerResponse.success) {
        final errorMsg =
            relayerResponse.error ?? 'Relayer submission failed';
        try {
          await _credentialManager.markDeploymentFailed(
            credentialId: credentialIdBase64url,
            error: 'Relayer error: $errorMsg',
          );
        } catch (_) {}
        throw SmartAccountTransactionException.submissionFailed(
          'Deployment relayer error: $errorMsg',
        );
      }

      final hash = relayerResponse.hash;
      if (hash == null) {
        throw SmartAccountTransactionException.submissionFailed(
          'No transaction hash returned from relayer',
        );
      }
      transactionHash = hash;
    } else {
      // why: the deployer account must be funded with XLM to pay fees for
      // direct RPC submission. The default deployer is the deterministic
      // shared deployer; production apps typically override it.
      final SendTransactionResponse sendResult;
      try {
        sendResult = await _kit.sorobanServer.sendTransaction(transaction);
      } catch (e) {
        try {
          await _credentialManager.markDeploymentFailed(
            credentialId: credentialIdBase64url,
            error: 'Failed to send transaction: $e',
          );
        } catch (_) {}
        throw SmartAccountTransactionException.submissionFailed(
          'Failed to send deployment transaction: $e',
          cause: e,
        );
      }

      // A PENDING submission was accepted into the network's transaction
      // queue and a DUPLICATE one names a transaction already in that queue,
      // so both poll to the true outcome below. Any other status reports a
      // submission the network did not queue, so polling its hash cannot
      // find a result.
      final sendStatus = sendResult.status;
      if (sendStatus != SendTransactionResponse.STATUS_PENDING &&
          sendStatus != SendTransactionResponse.STATUS_DUPLICATE) {
        var error = 'Deployment transaction failed with status: $sendStatus';
        if (sendResult.errorResultXdr != null) {
          error +=
              ', error transaction result xdr: ${sendResult.errorResultXdr}';
        }
        try {
          await _credentialManager.markDeploymentFailed(
            credentialId: credentialIdBase64url,
            error: error,
          );
        } catch (_) {}
        throw SmartAccountTransactionException.submissionFailed(error);
      }

      final hash = sendResult.hash;
      if (hash == null) {
        throw SmartAccountTransactionException.submissionFailed(
          'No transaction hash returned from submission',
        );
      }
      transactionHash = hash;
    }

    // Hand-rolled poll loop — 10 attempts × 2-second delay.
    //
    // why: deploy operations finalise faster than complex contract calls;
    // a tighter polling budget (20s) is appropriate. The transaction-result
    // pipeline uses the SDK's pollTransaction with a longer 90s budget.
    var confirmed = false;
    for (var attempt = 1; attempt <= 10; attempt++) {
      await _cancellableDelay(
        const Duration(milliseconds: 2000),
        cancelToken,
      );

      final GetTransactionResponse txStatus;
      try {
        txStatus = await _kit.sorobanServer.getTransaction(transactionHash);
      } catch (_) {
        if (attempt < 10) continue;
        try {
          await _credentialManager.markDeploymentFailed(
            credentialId: credentialIdBase64url,
            error: 'Deployment confirmation timed out',
          );
        } catch (_) {}
        throw SmartAccountTransactionException.timeout(
          details: 'Deployment confirmation timed out',
        );
      }

      switch (txStatus.status) {
        case GetTransactionResponse.STATUS_SUCCESS:
          confirmed = true;
          break;
        case GetTransactionResponse.STATUS_FAILED:
          try {
            await _credentialManager.markDeploymentFailed(
              credentialId: credentialIdBase64url,
              error: txStatus.resultXdr ?? 'Deployment failed on-chain',
            );
          } catch (_) {}
          throw SmartAccountTransactionException.submissionFailed(
            'Deployment failed: ${txStatus.resultXdr ?? 'unknown'}',
          );
        default:
          // NOT_FOUND or unknown — continue polling.
          continue;
      }

      if (confirmed) break;
    }

    if (!confirmed) {
      try {
        await _credentialManager.markDeploymentFailed(
          credentialId: credentialIdBase64url,
          error: 'Deployment confirmation timed out',
        );
      } catch (_) {}
      throw SmartAccountTransactionException.timeout(
        details: 'Deployment confirmation timed out',
      );
    }

    return transactionHash;
  }

  // Private: post-deploy contract visibility wait

  /// Polls the Soroban RPC until the deployed smart-account contract instance
  /// identified by [contractId] is visible as a persistent contract-data
  /// ledger entry, then returns.
  ///
  /// The deploy transaction confirms once the network applies it, but the
  /// Soroban RPC simulation endpoint can lag behind by one or more ledger
  /// closes under testnet congestion. Simulating against the contract (as the
  /// autoFund flow does via `fundWallet`) before the RPC has applied the deploy
  /// ledger fails because the contract instance is not yet in the RPC's view,
  /// so callers must wait until the RPC sees the instance entry.
  ///
  /// [SorobanServer.getContractData] queries the RPC's `getLedgerEntries` for
  /// the contract's instance ledger key (the contract-data entry keyed by
  /// [XdrSCVal.forLedgerKeyContractInstance] under
  /// [XdrContractDataDurability.PERSISTENT]). It returns `null` while the entry
  /// is not yet present; a non-null result is the visibility signal polled
  /// here. The poll runs every [pollInterval] up to [timeout]; both default to
  /// the [OZConstants.rpcVisibilityPollIntervalMs] /
  /// [OZConstants.rpcVisibilityTimeoutSeconds] budgets and are overridable so
  /// the behaviour can be exercised in tests.
  ///
  /// A thrown RPC error (transport failure, 5xx) is treated as transient and
  /// retried until the deadline, and the most recent one is attached to the
  /// timeout error as its cause. An in-band JSON-RPC error envelope (HTTP 200
  /// with an `error` member) is instead returned by
  /// [SorobanServer.getContractData] as a `null` result, indistinguishable
  /// from a not-yet-visible instance, so it is retried the same way and the
  /// timeout error then carries no cause.
  ///
  /// [cancelToken] is observed before each poll and during each inter-poll
  /// sleep so the caller can abort in flight. Throws
  /// [SmartAccountTransactionException.timeout] when the contract does
  /// not become visible within [timeout].
  @visibleForTesting
  Future<void> waitForContractVisibleToRpc(
    String contractId,
    dio.CancelToken? cancelToken, {
    Duration pollInterval = const Duration(
        milliseconds: OZConstants.rpcVisibilityPollIntervalMs),
    Duration timeout = const Duration(
        seconds: OZConstants.rpcVisibilityTimeoutSeconds),
  }) async {
    final deadline = DateTime.now().add(timeout);
    Object? lastError;
    while (true) {
      _checkCancellation(cancelToken);
      try {
        final entry = await _kit.sorobanServer.getContractData(
          contractId,
          XdrSCVal.forLedgerKeyContractInstance(),
          XdrContractDataDurability.PERSISTENT,
        );
        if (entry != null) {
          return;
        }
      } on Exception catch (e) {
        // Transient RPC exceptions are treated as "not yet visible" and
        // retried until the deadline; the most recent one is surfaced as the
        // timeout cause. The production caller always passes a freshly-deployed
        // contractId, so in practice these are RPC-level failures (congestion,
        // 5xx). Error subclasses (programmer/RPC-client bugs) are not caught
        // here, so they propagate immediately instead of being masked for the
        // full timeout budget.
        lastError = e;
      }
      if (!DateTime.now().isBefore(deadline)) {
        break;
      }
      await _cancellableDelay(pollInterval, cancelToken);
    }
    final timeoutLabel = timeout.inSeconds >= 1
        ? '${timeout.inSeconds}s'
        : '${timeout.inMilliseconds}ms';
    throw SmartAccountTransactionException.timeout(
      details: 'Smart-account contract $contractId not visible to the Soroban '
          'RPC within $timeoutLabel after deployment; testnet propagation may '
          'be delayed. Retry shortly.',
      cause: lastError,
    );
  }

  // Private: cancellation plumbing

  /// Throws a [SmartAccountTransactionException] when [cancelToken] has been
  /// cancelled. Called between long-running awaits in the wallet
  /// lifecycle so callers can abort in flight even when the wrapped
  /// network calls themselves don't expose cancellation.
  void _checkCancellation(dio.CancelToken? cancelToken) {
    if (cancelToken != null && cancelToken.isCancelled) {
      throw SmartAccountTransactionException.submissionFailed(
        'Operation cancelled',
        cause: cancelToken.cancelError,
      );
    }
  }

  /// Sleeps for [duration] while observing [cancelToken]. Throws via
  /// [_checkCancellation] when the wait races a cancellation.
  Future<void> _cancellableDelay(
    Duration duration,
    dio.CancelToken? cancelToken,
  ) async {
    if (cancelToken == null) {
      await Future<void>.delayed(duration);
      return;
    }
    final end = DateTime.now().add(duration);
    while (DateTime.now().isBefore(end)) {
      _checkCancellation(cancelToken);
      final remaining = end.difference(DateTime.now());
      final step = remaining < const Duration(milliseconds: 100)
          ? remaining
          : const Duration(milliseconds: 100);
      await Future<void>.delayed(step);
    }
    _checkCancellation(cancelToken);
  }

  /// Draws from the shared cached CSPRNG via [OZSecureNonce.bytes].
  Uint8List _secureRandomBytes(int length) => OZSecureNonce.bytes(length);
}

// File-private helpers

int _byteListContentHash(Uint8List bytes) {
  var hash = 1;
  for (final b in bytes) {
    hash = 0x1fffffff & (31 * hash + (b & 0xFF));
  }
  return hash;
}

bool _stringListEquals(List<String> a, List<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

// File-private sealed types for the cascade-stage helpers

/// Outcome of the indexer-resolution stage. Either a single verified
/// candidate contractId or a list of candidates that all verified.
sealed class _IndexerResolved {
  const _IndexerResolved();
}

final class _IndexerResolvedSingle extends _IndexerResolved {
  const _IndexerResolvedSingle(this.contractId);
  final String contractId;
}

final class _IndexerResolvedAmbiguous extends _IndexerResolved {
  const _IndexerResolvedAmbiguous(this.candidates);
  final List<String> candidates;
}
