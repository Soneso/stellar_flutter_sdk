// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:dio/dio.dart' as dio;
import 'package:meta/meta.dart';

import '../../account.dart';
import '../../invoke_host_function_operation.dart';
import '../../key_pair.dart';
import '../../memo.dart';
import '../../network.dart';
import '../../soroban/soroban_auth.dart';
import '../../soroban/soroban_server.dart';
import '../../transaction.dart';
import '../../util.dart';
import '../../xdr/xdr.dart';
import '../core/allow_credential.dart';
import '../core/smart_account_errors.dart';
import '../core/smart_account_utils.dart';
import 'oz_address_strkey.dart';
import 'oz_base64url.dart';
import 'oz_constants.dart';
import 'oz_internal_pipeline_interfaces.dart';
import 'oz_relayer_client.dart';
import 'oz_secure_nonce.dart';
import 'oz_smart_account_auth.dart';
import 'oz_smart_account_events.dart';
import 'oz_smart_account_signatures.dart';
import 'oz_smart_account_types.dart';
import 'oz_storage_adapter.dart';
import 'oz_submission_routing.dart';
import 'oz_transaction_timeout.dart';
import 'oz_validation.dart';

/// Result of a transaction submission and polling operation.
///
/// Contains the outcome of a transaction after it has been submitted to the
/// network and potentially confirmed on-chain. Use this to determine if a
/// transaction succeeded and retrieve its hash and ledger number.
///
/// Example:
///
/// ```dart
/// final result = await txOps.transfer(
///   tokenContract: 'CBCD...',
///   recipient: 'GA7Q...',
///   amount: '10',
/// );
///
/// if (result.success) {
///   print('Transaction succeeded. Hash: ${result.hash ?? "unknown"}');
/// } else {
///   print('Transaction failed: ${result.error ?? "unknown error"}');
/// }
/// ```
class OZTransactionResult {
  /// Constructs a transaction result. [success] is required; remaining
  /// fields are optional.
  const OZTransactionResult({
    required this.success,
    this.hash,
    this.ledger,
    this.error,
  });

  /// Whether the transaction was successful.
  final bool success;

  /// The transaction hash if submission succeeded, `null` otherwise.
  final String? hash;

  /// The ledger number where the transaction was confirmed, `null` when the
  /// transaction was not included in a ledger.
  final int? ledger;

  /// Error message if the transaction failed, `null` on success.
  final String? error;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OZTransactionResult) return false;
    return success == other.success &&
        hash == other.hash &&
        ledger == other.ledger &&
        error == other.error;
  }

  @override
  int get hashCode => Object.hash(success, hash, ledger, error);

  @override
  String toString() =>
      'OZTransactionResult(success: $success, hash: $hash, ledger: $ledger, error: $error)';
}

/// Callback for resolving context-rule IDs per authorization entry.
///
/// Called during the signing flow for each authorization entry that matches
/// the connected smart account. The callback receives the entry and its
/// index in the auth entries list and returns the context rule IDs to use
/// for that entry's invocation tree.
///
/// When no callback is provided the SDK resolves rule IDs automatically from
/// the connected signer and the active context rules. Provide a callback
/// when automatic resolution fails due to ambiguity (multiple matching
/// rules) or to bypass auto-resolution.
///
/// Example:
///
/// ```dart
/// // Simple case: same rule for all entries.
/// Future<List<int>> resolver(XdrSorobanAuthorizationEntry entry, int idx) async {
///   return <int>[ruleId];
/// }
/// ```
typedef OZResolveContextRuleIds = Future<List<int>> Function(
  XdrSorobanAuthorizationEntry entry,
  int index,
);

/// Transaction operations for OpenZeppelin smart accounts.
///
/// Provides high-level transaction building, signing, and submission for
/// smart account operations. Responsibilities include:
///
/// - Token transfers with automatic base-units conversion.
/// - Transaction simulation and fee estimation.
/// - Authorization-entry signing with WebAuthn.
/// - Relayer submission for fee sponsoring.
/// - Transaction polling and confirmation.
/// - Testnet wallet funding via Friendbot.
///
/// ## Fee sponsoring
///
/// When a relayer URL is configured via `config.relayerUrl`, transactions
/// can be fee-sponsored by the relayer. Two modes are used depending on the
/// authorization-entry shape:
///
/// - **Mode 1** (host function + auth): sent when no source-account auth
///   entry exists. The relayer wraps the host function and the signed auth
///   entries into a fee-bumped envelope; the inner transaction is not
///   signed by the source account.
/// - **Mode 2** (signed transaction XDR): sent when at least one
///   source-account auth entry is present. The transaction is fully signed
///   by the deployer (or temp keypair, for `fundWallet`) before being
///   wrapped by the relayer in a fee bump.
///
/// The mode is selected automatically based on the presence of source-account
/// credentials in the authorization entries.
///
/// This class works in tandem with the smart-account kit and is exposed via
/// `kit.transactionOperations` rather than constructed directly. The kit
/// supplies the configuration, RPC server, event emitter, storage, and
/// optional relayer / indexer clients used throughout the pipeline.
class OZTransactionOperations {
  /// Constructs the transaction-operations facade against the supplied kit.
  ///
  /// Marked [internal] to indicate consumers should reach this object via
  /// `kit.transactionOperations` rather than constructing one directly. The
  /// kit retains a strong reference; the lifetime of this object is bound to
  /// the kit's lifetime.
  @internal
  OZTransactionOperations(this._kit);

  final OZSmartAccountKitInterface _kit;

  // Public API: token transfer

  /// Transfers tokens from the connected smart account to a recipient.
  ///
  /// Works with any SEP-41 compatible token (XLM via SAC, custom Soroban
  /// tokens). [amount] is a decimal string converted to the token's base
  /// units before submission: [decimals] is used when supplied, otherwise the
  /// token's on-chain `decimals()` is fetched via [fetchTokenDecimals].
  ///
  /// Flow:
  ///
  /// 1. Validate recipient address and prevent self-transfer.
  /// 2. Resolve the token decimals and convert [amount] to base units.
  /// 3. Delegate to [contractCall], which builds the host function,
  ///    simulates it, signs auth entries via WebAuthn, re-simulates, and
  ///    submits.
  ///
  /// IMPORTANT: this method requires WebAuthn interaction. The user will be
  /// prompted for biometric authentication.
  ///
  /// [tokenContract] is the token contract address (C-address). [recipient]
  /// is the recipient address (G-address or C-address). [decimals] is the
  /// token's decimal scale used to convert [amount]; when `null` (default) it
  /// is fetched on-chain via [fetchTokenDecimals]. [forceMethod] optionally
  /// overrides the auto-detected submission method.
  ///
  /// Throws [SmartAccountWalletNotConnected] when no wallet is connected,
  /// [SmartAccountInvalidAddress] when the recipient address is malformed,
  /// [SmartAccountInvalidInput] when the recipient is the smart account itself,
  /// [SmartAccountInvalidAmount] when the amount is invalid or outside the
  /// supported i128 range, and [SmartAccountTransactionException] /
  /// [WebAuthnException] for downstream failures.
  ///
  /// The optional [cancelToken] can be cancelled to abort an in-flight
  /// request. Cancellation surfaces as a [SmartAccountTransactionException] from any
  /// network step that observes the cancellation between awaits.
  Future<OZTransactionResult> transfer({
    required String tokenContract,
    required String recipient,
    required String amount,
    int? decimals,
    OZSubmissionMethod? forceMethod,
    dio.CancelToken? cancelToken,
  }) async {
    _checkCancellation(cancelToken);

    final connected = await _kit.requireConnected();

    requireStellarAddress(recipient, fieldName: 'recipient');

    if (recipient == connected.contractId) {
      throw SmartAccountValidationException.invalidInput('recipient', 'Cannot transfer to self');
    }

    final resolvedDecimals =
        decimals ?? await fetchTokenDecimals(tokenContract);
    final baseUnits = amountToBaseUnits(amount, decimals: resolvedDecimals);

    final targetArgs = <XdrSCVal>[
      XdrSCVal.forAddress(Address.forContractId(connected.contractId).toXdr()),
      _addressScVal(recipient),
      baseUnitsToI128ScVal(baseUnits, amount: amount),
    ];

    return contractCall(
      target: tokenContract,
      targetFn: 'transfer',
      targetArgs: targetArgs,
      forceMethod: forceMethod,
      cancelToken: cancelToken,
    );
  }

  /// Reads the `decimals()` value from a SEP-41 token contract.
  ///
  /// Simulates the token contract's `decimals` function and returns the
  /// reported `u32` scale.
  ///
  /// [tokenContract] is the SEP-41 token contract address (C-address).
  ///
  /// Throws [SmartAccountInvalidAddress] when [tokenContract] is not a valid
  /// contract address, and [SmartAccountTransactionException] when the
  /// simulation fails or the contract does not return a valid `u32` value.
  Future<int> fetchTokenDecimals(String tokenContract) async {
    requireContractAddress(tokenContract, fieldName: 'tokenContract');

    final invokeArgs = XdrInvokeContractArgs(
      Address.forContractId(tokenContract).toXdr(),
      'decimals',
      const <XdrSCVal>[],
    );
    final hostFunction =
        XdrHostFunction.forInvokingContractWithArgs(invokeArgs);
    final result = await simulateAndExtractResult(hostFunction);

    final decimals = _scValToUInt32(result);
    if (decimals == null) {
      throw SmartAccountTransactionException.simulationFailed(
        'Token contract $tokenContract did not return a valid u32 decimals value',
      );
    }
    return decimals;
  }

  // Public API: direct contract call

  /// Invokes an arbitrary function on an external contract directly from the
  /// smart account.
  ///
  /// Builds a host function that calls `target.targetFn(targetArgs)`. The
  /// smart account authorises the call via `require_auth` triggered by the
  /// target contract; the matching `CallContract(target)` context rule is
  /// used for authorization.
  ///
  /// Use this for any external contract interaction (token approve, token
  /// transfer, DeFi protocol calls) where the smart account is the
  /// authorised party.
  ///
  /// [target] is the target contract address (C-address). [targetFn] is the
  /// function name. [targetArgs] is the pre-encoded list of arguments
  /// (defaulting to an empty list). [forceMethod] optionally overrides the
  /// auto-detected submission method. [resolveContextRuleIds] optionally
  /// supplies a per-entry callback resolving the context rule IDs. The
  /// optional [cancelToken] can be cancelled to abort an in-flight
  /// request; cancellation surfaces as a [SmartAccountTransactionException] from any
  /// network step that observes the cancellation between awaits.
  Future<OZTransactionResult> contractCall({
    required String target,
    required String targetFn,
    List<XdrSCVal> targetArgs = const <XdrSCVal>[],
    OZSubmissionMethod? forceMethod,
    OZResolveContextRuleIds? resolveContextRuleIds,
    dio.CancelToken? cancelToken,
  }) async {
    _checkCancellation(cancelToken);

    await _kit.requireConnected();

    requireContractAddress(target, fieldName: 'target');

    requireNonBlankFunctionName(targetFn);

    final invokeArgs = XdrInvokeContractArgs(
      Address.forContractId(target).toXdr(),
      targetFn,
      List<XdrSCVal>.from(targetArgs),
    );
    final hostFunction = XdrHostFunction.forInvokingContractWithArgs(invokeArgs);

    return submit(
      hostFunction: hostFunction,
      auth: const <XdrSorobanAuthorizationEntry>[],
      forceMethod: forceMethod,
      resolveContextRuleIds: resolveContextRuleIds,
      cancelToken: cancelToken,
    );
  }

  // Public API: smart-account-mediated execute call

  /// Executes an arbitrary contract call through the smart account's
  /// `execute(target, target_fn, target_args)` entry point.
  ///
  /// Builds an invocation of the smart account contract that calls the
  /// target on the smart account's behalf. The smart account's authorization
  /// rules (context rules, signers, policies) apply. The optional
  /// [cancelToken] can be cancelled to abort an in-flight request;
  /// cancellation surfaces as a [SmartAccountTransactionException] from any network
  /// step that observes the cancellation between awaits.
  Future<OZTransactionResult> executeAndSubmit({
    required String target,
    required String targetFn,
    List<XdrSCVal> targetArgs = const <XdrSCVal>[],
    OZSubmissionMethod? forceMethod,
    OZResolveContextRuleIds? resolveContextRuleIds,
    dio.CancelToken? cancelToken,
  }) async {
    _checkCancellation(cancelToken);

    final connected = await _kit.requireConnected();

    requireContractAddress(target, fieldName: 'target');

    requireNonBlankFunctionName(targetFn);

    final functionArgs = <XdrSCVal>[
      XdrSCVal.forAddress(Address.forContractId(target).toXdr()),
      XdrSCVal.forSymbol(targetFn),
      XdrSCVal.forVec(List<XdrSCVal>.from(targetArgs)),
    ];

    final invokeArgs = XdrInvokeContractArgs(
      Address.forContractId(connected.contractId).toXdr(),
      'execute',
      functionArgs,
    );
    final hostFunction = XdrHostFunction.forInvokingContractWithArgs(invokeArgs);

    return submit(
      hostFunction: hostFunction,
      auth: const <XdrSorobanAuthorizationEntry>[],
      forceMethod: forceMethod,
      resolveContextRuleIds: resolveContextRuleIds,
      cancelToken: cancelToken,
    );
  }

  // Public API: low-level submit

  /// Submits a host function with the full Soroban authorization flow.
  ///
  /// Requires a connected wallet. Simulates the transaction, collects auth
  /// entries, drives a WebAuthn ceremony for each entry that matches the
  /// smart account contract, re-simulates with real signatures to obtain
  /// accurate resource fees, then submits and polls for on-chain
  /// confirmation.
  ///
  /// The deployer keypair signs the transaction for direct RPC submissions
  /// and for relayer Mode 2 (source-account auth present). It is not used
  /// for relayer Mode 1, which lets the relayer supply its own channel
  /// account.
  ///
  /// The optional [cancelToken] can be cancelled to abort an in-flight
  /// network request; on cancellation the method throws a
  /// [SmartAccountTransactionException] wrapping a [dio.DioExceptionType.cancel].
  Future<OZTransactionResult> submit({
    required XdrHostFunction hostFunction,
    required List<XdrSorobanAuthorizationEntry> auth,
    OZSubmissionMethod? forceMethod,
    OZResolveContextRuleIds? resolveContextRuleIds,
    dio.CancelToken? cancelToken,
  }) async {
    _checkCancellation(cancelToken);

    final connected = await _kit.requireConnected();
    final credentialId = connected.credentialId;
    final contractId = connected.contractId;

    // Reject a headless connection before any decode, ceremony, or network
    // call. A kit connected via connectToContract has no passkey credential
    // (credentialId is null), so the single-passkey submit path cannot sign;
    // headless operations must use the multi-signer / external-signer
    // pipeline.
    if (credentialId == null) {
      throw SmartAccountValidationException.invalidInput(
        'credentialId',
        'This kit is connected headlessly (no passkey); use the multi-signer '
            'pipeline with explicit selectedSigners for headless operations.',
      );
    }

    final deployer = await _kit.getDeployer();
    final deployerAccount = await _fetchAccount(deployer.accountId);

    _checkCancellation(cancelToken);

    final operation = InvokeHostFunctionOperation(
      HostFunction.fromXdr(hostFunction),
      auth: _wrapAuthEntries(auth),
    );

    final initialTransaction = TransactionBuilder(deployerAccount)
        .setMaxOperationFee(AbstractTransaction.MIN_BASE_FEE)
        .addOperation(operation)
        .addMemo(Memo.none())
        .addPreconditions(buildTimeoutPreconditions(_kit.config.timeoutInSeconds))
        .build();

    final simulation = await _simulateInitial(initialTransaction);
    final simulatedAuthEntries = _extractAuthEntries(simulation);

    _checkCancellation(cancelToken);

    final signedAuthEntries = await _signSimulationAuthEntries(
      simulatedAuthEntries: simulatedAuthEntries,
      contractId: contractId,
      credentialId: credentialId,
      resolveContextRuleIds: resolveContextRuleIds,
      cancelToken: cancelToken,
    );

    if (signedAuthEntries.isNotEmpty) {
      try {
        await _kit.credentialManager.updateLastUsed(credentialId);
      } catch (_) {
        // Non-critical — credential tracking is best-effort.
      }
    }

    _kit.events.emit(OZSmartAccountEventTransactionSigned(
      contractId: contractId,
      credentialId: signedAuthEntries.isNotEmpty ? credentialId : null,
    ));

    _checkCancellation(cancelToken);

    // why: rebuild against a refreshed deployer-account sequence so the
    // re-simulated transaction reflects the latest sequence number.
    final refreshedDeployer = await _fetchAccount(deployer.accountId);
    final signedOperation = InvokeHostFunctionOperation(
      HostFunction.fromXdr(hostFunction),
      auth: _wrapAuthEntries(signedAuthEntries),
    );
    final signedTransaction = TransactionBuilder(refreshedDeployer)
        .setMaxOperationFee(AbstractTransaction.MIN_BASE_FEE)
        .addOperation(signedOperation)
        .addMemo(Memo.none())
        .addPreconditions(buildTimeoutPreconditions(_kit.config.timeoutInSeconds))
        .build();

    final reSimulation = await _reSimulateSigned(signedTransaction);
    _applySimulationToTransaction(signedTransaction, reSimulation);

    final submissionMethod = ozResolveSubmissionMethod(_kit, forceMethod);
    final useRelayer = submissionMethod == OZSubmissionMethod.relayer;

    return _submitOrRelay(
      transaction: signedTransaction,
      hostFunction: hostFunction,
      signedAuthEntries: signedAuthEntries,
      signer: deployer,
      useRelayer: useRelayer,
      cancelToken: cancelToken,
    );
  }

  // Internal: simulation helpers extracted from `submit`

  /// Performs the initial simulation against the unsigned transaction.
  ///
  /// Wraps the underlying `simulateTransaction` call so RPC failures are
  /// converted to [SmartAccountTransactionException]s with submission-failed/
  /// simulation-failed semantics.
  Future<SimulateTransactionResponse> _simulateInitial(
    Transaction transaction,
  ) async {
    final SimulateTransactionResponse simulation;
    try {
      simulation = await _kit.sorobanServer.simulateTransaction(
        SimulateTransactionRequest(
          transaction,
          useUpgradedAuth: _kit.config.useUpgradedAuth,
        ),
      );
    } catch (e) {
      throw SmartAccountTransactionException.submissionFailed(
        'Failed to simulate transaction: $e',
        cause: e,
      );
    }

    final initialError = _errorMessage(simulation);
    if (initialError != null) {
      throw SmartAccountTransactionException.simulationFailed(
        'Simulation error: $initialError',
      );
    }
    return simulation;
  }

  /// Re-simulates the signed transaction.
  ///
  /// why: real WebAuthn signatures are substantially larger than the
  /// placeholder bytes the initial simulation returns. Without
  /// re-simulation the resource-fee envelope is sized for the placeholders
  /// and the on-chain submission silently exhausts its budget.
  Future<SimulateTransactionResponse> _reSimulateSigned(
    Transaction signedTransaction,
  ) async {
    final SimulateTransactionResponse reSimulation;
    try {
      reSimulation = await _kit.sorobanServer.simulateTransaction(
        SimulateTransactionRequest(
          signedTransaction,
          useUpgradedAuth: _kit.config.useUpgradedAuth,
        ),
      );
    } catch (e) {
      throw SmartAccountTransactionException.submissionFailed(
        'Failed to re-simulate signed transaction: $e',
        cause: e,
      );
    }

    final reSimError = _errorMessage(reSimulation);
    if (reSimError != null) {
      throw SmartAccountTransactionException.simulationFailed(
        'Re-simulation error: $reSimError',
      );
    }
    return reSimulation;
  }

  /// Signs every auth entry that points at the connected smart account
  /// contract. Source-account, void, or non-matching entries pass through
  /// unchanged.
  ///
  /// why: fetches the latest ledger and the active context-rule list once
  /// before the loop. Per-entry round-trips would be wasteful and could
  /// observe slightly different ledger sequences between entries.
  Future<List<XdrSorobanAuthorizationEntry>> _signSimulationAuthEntries({
    required List<XdrSorobanAuthorizationEntry> simulatedAuthEntries,
    required String contractId,
    required String credentialId,
    required OZResolveContextRuleIds? resolveContextRuleIds,
    required dio.CancelToken? cancelToken,
  }) async {
    if (simulatedAuthEntries.isEmpty) {
      return const <XdrSorobanAuthorizationEntry>[];
    }

    final latestLedger = await _kit.sorobanServer.getLatestLedger();
    final ledgerSeq = latestLedger.sequence;
    if (ledgerSeq == null) {
      throw SmartAccountTransactionException.submissionFailed(
        'Failed to fetch latest ledger sequence',
      );
    }
    final expiration = ledgerSeq + _kit.config.signatureExpirationLedgers;

    final contextRules = await _kit.contextRuleManager.listContextRules();

    final signed = <XdrSorobanAuthorizationEntry>[];
    for (var entryIndex = 0;
        entryIndex < simulatedAuthEntries.length;
        entryIndex++) {
      _checkCancellation(cancelToken);
      final entry = simulatedAuthEntries[entryIndex];

      // Pass SOURCE_ACCOUNT entries through unchanged.
      if (entry.credentials.discriminant ==
          XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_SOURCE_ACCOUNT) {
        signed.add(entry);
        continue;
      }

      // ADDRESS_WITH_DELEGATES entries cannot be auto-signed by this flow.
      // Use SorobanAuthorizationEntry.sign with the forAddress parameter to
      // route signatures to the appropriate delegate nodes.
      if (entry.credentials.discriminant ==
          XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_WITH_DELEGATES) {
        throw SmartAccountTransactionException.signingFailed(
          'ADDRESS_WITH_DELEGATES auth entries cannot be auto-signed by the '
          'single-signer pipeline. Use SorobanAuthorizationEntry.sign with the '
          'forAddress parameter to sign each delegate node, then pass the '
          'pre-signed entries via the auth parameter.',
        );
      }

      // For ADDRESS and ADDRESS_V2: extract the inner credentials.
      final addressCreds = _innerAddressCredentialsXdr(entry.credentials);
      if (addressCreds == null) {
        // Unknown credential arm — fail fast.
        throw SmartAccountTransactionException.signingFailed(
          'Unrecognised credential arm '
          '${entry.credentials.discriminant} in auth entry; cannot sign.',
        );
      }

      final entryAddress = OZAddressStrKey.fromXdr(addressCreds.address);
      if (entryAddress != contractId) {
        // Auth entry does not point at our smart account — pass through.
        signed.add(entry);
        continue;
      }

      final payloadHash = await OZSmartAccountAuth.buildAuthPayloadHash(
        entry,
        expiration,
        _kit.config.networkPassphrase,
      );

      final webauthnProvider = _kit.config.webauthnProvider;
      if (webauthnProvider == null) {
        throw SmartAccountValidationException.invalidInput(
          'webauthnProvider',
          'WebAuthn provider is required for signing auth entries but is not configured',
        );
      }

      final Uint8List credIdBytes;
      try {
        credIdBytes = ozBase64UrlDecode(credentialId);
      } catch (e) {
        throw SmartAccountCredentialException.invalid(
          'Failed to decode credentialId from Base64URL: $credentialId',
          cause: e,
        );
      }

      // Resolve key data: first try local storage, then fall through to
      // on-chain context-rule scanning.
      OZStoredCredential? stored;
      try {
        stored = await _kit.getStorage().get(credentialId);
      } catch (_) {
        stored = null;
      }
      final Uint8List keyData;
      if (stored != null) {
        keyData = _concat(stored.publicKey, credIdBytes);
      } else {
        keyData = await _findKeyDataFromContextRules(credIdBytes);
      }

      final signer = OZExternalSigner(
        _kit.config.webauthnVerifierAddress,
        keyData,
      );

      final List<int> resolvedContextRuleIds;
      if (resolveContextRuleIds != null) {
        resolvedContextRuleIds = await resolveContextRuleIds(entry, entryIndex);
      } else {
        resolvedContextRuleIds = await _kit.contextRuleManager
            .resolveContextRuleIdsForEntry(
                entry, <OZSmartAccountSigner>[signer], contextRules);
      }

      final authDigest = await OZSmartAccountAuth.buildAuthDigest(
        payloadHash,
        resolvedContextRuleIds,
      );

      final authResult = await webauthnProvider.authenticate(
        challenge: authDigest,
        allowCredentials: <WebAuthnAllowCredential>[
          WebAuthnAllowCredential(id: credIdBytes, transports: stored?.transports),
        ],
      );

      // why: the WebAuthn provider is asked to authenticate against a
      // specific credential ID, but a misbehaving or compromised provider
      // could return a signature from a different credential. Verify the
      // result's credentialId matches the one we requested before using
      // its signature.
      if (!Util.constantTimeEquals(authResult.credentialId, credIdBytes)) {
        throw SmartAccountCredentialException.invalid(
          'WebAuthn provider returned a signature for a different credential than was requested',
        );
      }

      final compactSig =
          SmartAccountUtils.normalizeSignature(authResult.signature);

      final webAuthnSig = OZWebAuthnSignature(
        authenticatorData: authResult.authenticatorData,
        clientData: authResult.clientDataJSON,
        signature: compactSig,
      );

      final signedEntry = await OZSmartAccountAuth.signAuthEntry(
        entry: entry,
        signer: signer,
        signature: webAuthnSig,
        expirationLedger: expiration,
        contextRuleIds: resolvedContextRuleIds,
      );
      signed.add(signedEntry);
    }
    return signed;
  }

  // Internal: multi-signer submission (consumed by the multi-signer manager)

  /// Submits a multi-signer transaction by reusing the same submission
  /// branch as [submit] but skipping the WebAuthn signing pass.
  ///
  /// Called after the multi-signer manager has already collected every
  /// signature and applied them to the auth entries. Re-simulation has
  /// already been performed by the caller; this method only applies the
  /// re-simulation result, signs the envelope when required, and submits.
  @internal
  Future<OZTransactionResult> submitMultiSignerTransaction({
    required XdrHostFunction hostFunction,
    required List<XdrSorobanAuthorizationEntry> signedAuthEntries,
    required Transaction signedTransaction,
    required SimulateTransactionResponse simulation,
    OZSubmissionMethod? forceMethod,
  }) async {
    final deployer = await _kit.getDeployer();
    _applySimulationToTransaction(signedTransaction, simulation);

    final useRelayer = ozResolveSubmissionMethod(_kit, forceMethod) == OZSubmissionMethod.relayer;

    return _submitOrRelay(
      transaction: signedTransaction,
      hostFunction: hostFunction,
      signedAuthEntries: signedAuthEntries,
      signer: deployer,
      useRelayer: useRelayer,
    );
  }

  // Internal: simulation result extraction (consumed by contract-rule reads)

  /// Simulates a host function and returns its return-value `ScVal`.
  ///
  /// Used for read-only queries (e.g. token balance lookups) where no
  /// submission is performed. Throws [SmartAccountTransactionException] on simulation
  /// failure or when the simulation produced no result entry.
  @internal
  Future<XdrSCVal> simulateAndExtractResult(XdrHostFunction hostFunction) async {
    final deployer = await _kit.getDeployer();
    final deployerAccount = await _fetchAccount(deployer.accountId);

    final operation = InvokeHostFunctionOperation(
      HostFunction.fromXdr(hostFunction),
      auth: const <SorobanAuthorizationEntry>[],
    );
    final transaction = TransactionBuilder(deployerAccount)
        .setMaxOperationFee(AbstractTransaction.MIN_BASE_FEE)
        .addOperation(operation)
        .addMemo(Memo.none())
        .addPreconditions(buildTimeoutPreconditions(_kit.config.timeoutInSeconds))
        .build();

    final SimulateTransactionResponse simulation;
    try {
      simulation = await _kit.sorobanServer.simulateTransaction(
        SimulateTransactionRequest(
          transaction,
          useUpgradedAuth: _kit.config.useUpgradedAuth,
        ),
      );
    } catch (e) {
      throw SmartAccountTransactionException.simulationFailed(
        'Failed to simulate read-only host function: $e',
        cause: e,
      );
    }

    final err = _errorMessage(simulation);
    if (err != null) {
      throw SmartAccountTransactionException.simulationFailed('Simulation error: $err');
    }

    final results = simulation.results;
    if (results == null || results.isEmpty) {
      throw SmartAccountTransactionException.simulationFailed('No results returned from simulation');
    }
    final result = results[0].resultValue;
    if (result == null) {
      throw SmartAccountTransactionException.simulationFailed('No return value in simulation result');
    }
    return result;
  }

  // Public API: testnet funding

  /// Funds the connected smart-account wallet on testnet via Friendbot.
  ///
  /// Creates a temporary Stellar keypair, funds it through Friendbot, then
  /// transfers the temporary account's balance (minus a small reserve) to
  /// the smart account via the supplied SEP-41 native-token contract.
  /// Supports relayer fee sponsoring by converting source-account auth
  /// entries on the transfer to address credentials carrying the temp
  /// account's address and signed by the temp keypair;
  /// [OZSmartAccountConfig.useUpgradedAuth] selects the ADDRESS_V2 or the
  /// legacy ADDRESS arm.
  ///
  /// Returns the funded amount as a decimal XLM string. Throws
  /// [SmartAccountTransactionException] when Friendbot funding, balance lookup, or
  /// submission fails. Only valid on testnet — Friendbot is testnet-only.
  ///
  /// The optional [cancelToken] can be cancelled to abort the operation;
  /// cancellation is observed before/after each major awaitable step,
  /// including the Soroban RPC account-visibility poll that follows
  /// Friendbot funding (see [waitForAccountVisibleToRpc]).
  Future<String> fundWallet({
    required String nativeTokenContract,
    OZSubmissionMethod? forceMethod,
    dio.CancelToken? cancelToken,
  }) async {
    _checkCancellation(cancelToken);

    final connected = await _kit.requireConnected();

    requireContractAddress(nativeTokenContract, fieldName: 'nativeTokenContract');

    final tempKeypair = KeyPair.random();

    _checkCancellation(cancelToken);

    final funded = await FriendBot.fundTestAccount(tempKeypair.accountId);
    if (!funded) {
      throw SmartAccountTransactionException.submissionFailed('Friendbot funding failed');
    }

    // Wait for RPC visibility of the funded account before the native SAC
    // balance read simulates against it (see waitForAccountVisibleToRpc).
    await waitForAccountVisibleToRpc(tempKeypair.accountId, cancelToken);

    final tempAccount = await _fetchAccount(tempKeypair.accountId);

    final reserveStroops =
        BigInt.from(OZConstants.friendbotReserveXlm) * BigInt.from(Util.stroopsPerXlm);

    final balanceArgs = <XdrSCVal>[
      XdrSCVal.forAddress(Address.forAccountId(tempKeypair.accountId).toXdr()),
    ];
    final balanceInvokeArgs = XdrInvokeContractArgs(
      Address.forContractId(nativeTokenContract).toXdr(),
      'balance',
      balanceArgs,
    );
    final balanceHostFunction =
        XdrHostFunction.forInvokingContractWithArgs(balanceInvokeArgs);
    final balanceResult = await simulateAndExtractResult(balanceHostFunction);
    final BigInt balanceStroops;
    try {
      balanceStroops = _scValToBigInt(balanceResult);
    } catch (e) {
      throw SmartAccountTransactionException.submissionFailed(
        'Failed to query temp account balance',
        cause: e,
      );
    }

    if (balanceStroops <= reserveStroops) {
      throw SmartAccountTransactionException.submissionFailed(
        'Insufficient balance after Friendbot funding',
      );
    }

    final transferStroops = balanceStroops - reserveStroops;

    final functionArgs = <XdrSCVal>[
      XdrSCVal.forAddress(Address.forAccountId(tempKeypair.accountId).toXdr()),
      XdrSCVal.forAddress(Address.forContractId(connected.contractId).toXdr()),
      Util.bigIntToI128ScVal(transferStroops),
    ];
    final invokeArgs = XdrInvokeContractArgs(
      Address.forContractId(nativeTokenContract).toXdr(),
      'transfer',
      functionArgs,
    );
    final hostFunction = XdrHostFunction.forInvokingContractWithArgs(invokeArgs);

    final operation = InvokeHostFunctionOperation(
      HostFunction.fromXdr(hostFunction),
      auth: const <SorobanAuthorizationEntry>[],
    );
    final transaction = TransactionBuilder(tempAccount)
        .setMaxOperationFee(AbstractTransaction.MIN_BASE_FEE)
        .addOperation(operation)
        .addMemo(Memo.none())
        .addPreconditions(buildTimeoutPreconditions(_kit.config.timeoutInSeconds))
        .build();

    final SimulateTransactionResponse simulation;
    try {
      simulation = await _kit.sorobanServer.simulateTransaction(
        SimulateTransactionRequest(
          transaction,
          useUpgradedAuth: _kit.config.useUpgradedAuth,
        ),
      );
    } catch (e) {
      throw SmartAccountTransactionException.submissionFailed(
        'Failed to simulate funding transfer: $e',
        cause: e,
      );
    }

    final simErr = _errorMessage(simulation);
    if (simErr != null) {
      throw SmartAccountTransactionException.simulationFailed(
        'Failed to simulate funding transfer: $simErr',
      );
    }

    final simulatedAuthEntries = _extractAuthEntries(simulation);

    final latestLedger = await _kit.sorobanServer.getLatestLedger();
    final ledgerSeq = latestLedger.sequence;
    if (ledgerSeq == null) {
      throw SmartAccountTransactionException.submissionFailed('Failed to fetch latest ledger sequence');
    }
    final expirationLedger = ledgerSeq + Util.ledgersPerHour;

    _checkCancellation(cancelToken);

    final signedAuthEntries = await _convertAndSignAuthEntries(
      authEntries: simulatedAuthEntries,
      tempKeypair: tempKeypair,
      expirationLedger: expirationLedger,
    );

    final tempAccountRefresh = await _fetchAccount(tempKeypair.accountId);

    final signedOperation = InvokeHostFunctionOperation(
      HostFunction.fromXdr(hostFunction),
      auth: _wrapAuthEntries(signedAuthEntries),
    );
    final signedTransaction = TransactionBuilder(tempAccountRefresh)
        .setMaxOperationFee(AbstractTransaction.MIN_BASE_FEE)
        .addOperation(signedOperation)
        .addMemo(Memo.none())
        .addPreconditions(buildTimeoutPreconditions(_kit.config.timeoutInSeconds))
        .build();

    final SimulateTransactionResponse reSimulation;
    try {
      reSimulation = await _kit.sorobanServer.simulateTransaction(
        SimulateTransactionRequest(
          signedTransaction,
          useUpgradedAuth: _kit.config.useUpgradedAuth,
        ),
      );
    } catch (e) {
      throw SmartAccountTransactionException.submissionFailed(
        'Failed to re-simulate funding transfer: $e',
        cause: e,
      );
    }
    final reSimError = _errorMessage(reSimulation);
    if (reSimError != null) {
      throw SmartAccountTransactionException.simulationFailed('Re-simulation error: $reSimError');
    }

    _applySimulationToTransaction(signedTransaction, reSimulation);

    final submissionMethod = ozResolveSubmissionMethod(_kit, forceMethod);
    final useRelayer = submissionMethod == OZSubmissionMethod.relayer;

    final result = await _submitOrRelay(
      transaction: signedTransaction,
      hostFunction: hostFunction,
      signedAuthEntries: signedAuthEntries,
      signer: tempKeypair,
      useRelayer: useRelayer,
      emitEvents: false,
      cancelToken: cancelToken,
    );

    if (!result.success) {
      throw SmartAccountTransactionException.submissionFailed(
        'Funding transaction failed: ${result.error ?? 'unknown error'}',
      );
    }

    return _formatXlmString(transferStroops);
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
    // Poll the cancellation flag every 100ms so a cancel takes effect
    // promptly without spinning the event loop hot.
    final end = DateTime.now().add(duration);
    while (DateTime.now().isBefore(end)) {
      _checkCancellation(cancelToken);
      final remaining = end.difference(DateTime.now());
      final step =
          remaining < const Duration(milliseconds: 100) ? remaining : const Duration(milliseconds: 100);
      await Future<void>.delayed(step);
    }
    _checkCancellation(cancelToken);
  }

  // Private helpers

  /// Converts source-account auth entries to fresh address credentials
  /// carrying the temporary account's address. The arm follows
  /// [OZSmartAccountConfig.useUpgradedAuth]: ADDRESS_V2 signed over the
  /// address-bound WITH_ADDRESS preimage, or legacy ADDRESS signed over
  /// ENVELOPE_TYPE_SOROBAN_AUTHORIZATION. Address-credentialed entries are
  /// re-signed in place to refresh their signature, preserving their
  /// credential arm.
  ///
  /// For source-account entries this writes a classical Stellar Ed25519
  /// signature ScVal of shape `Vec([Map({public_key, signature})])` — not
  /// the smart-account `AuthPayload` map. The two shapes are not
  /// interchangeable; using the AuthPayload map here would fail the
  /// classical transaction verifier for the temp account.
  Future<List<XdrSorobanAuthorizationEntry>> _convertAndSignAuthEntries({
    required List<XdrSorobanAuthorizationEntry> authEntries,
    required KeyPair tempKeypair,
    required int expirationLedger,
  }) async {
    final tempPubKey = tempKeypair.publicKey;
    final useUpgradedAuth = _kit.config.useUpgradedAuth;
    final result = <XdrSorobanAuthorizationEntry>[];
    for (final entry in authEntries) {
      if (entry.credentials.discriminant ==
          XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_SOURCE_ACCOUNT) {
        final nonce = _generateNonce();
        final tempAddress = Address.forAccountId(tempKeypair.accountId).toXdr();

        // The payload hash covers the preimage the host rebuilds from the
        // credentials written below, so both are built from the same arm.
        // Under ADDRESS_V2 that preimage carries the temporary account
        // address, which is why the address must be identical in both places.
        final payloadHash = await OZSmartAccountAuth.buildSourceAccountAuthPayloadHash(
          entry,
          tempAddress,
          nonce,
          expirationLedger,
          _kit.config.networkPassphrase,
          useUpgradedAuth: useUpgradedAuth,
        );
        final signature = tempKeypair.sign(payloadHash);

        // Standard Ed25519 format: Vec([Map({public_key, signature})]) — the
        // shape the classical Stellar account verifier expects.
        final signatureMap = XdrSCVal.forMap(<XdrSCMapEntry>[
          XdrSCMapEntry(
            XdrSCVal.forSymbol('public_key'),
            XdrSCVal.forBytes(tempPubKey),
          ),
          XdrSCMapEntry(
            XdrSCVal.forSymbol('signature'),
            XdrSCVal.forBytes(signature),
          ),
        ]);
        final signatureVec = XdrSCVal.forVec(<XdrSCVal>[signatureMap]);

        final addressCredentials = XdrSorobanAddressCredentials(
          tempAddress,
          nonce,
          XdrUint32(expirationLedger),
          signatureVec,
        );
        result.add(XdrSorobanAuthorizationEntry(
          useUpgradedAuth
              ? XdrSorobanCredentials.forAddressV2Credentials(
                  addressCredentials)
              : XdrSorobanCredentials.forAddressCredentials(addressCredentials),
          _cloneInvocation(entry.rootInvocation),
        ));
      } else if (entry.credentials.discriminant ==
              XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS ||
          entry.credentials.discriminant ==
              XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2) {
        final entryCopy = _cloneAuthEntry(entry);
        final credentials = _innerAddressCredentialsXdr(entryCopy.credentials);
        if (credentials == null) {
          throw SmartAccountTransactionException.signingFailed(
            'Address credentials unexpectedly null after clone for arm '
            '${entryCopy.credentials.discriminant}',
          );
        }

        // buildAuthPayloadHash handles both ADDRESS and ADDRESS_V2: it stamps
        // the expiration and selects the preimage type based on the arm.
        final payloadHash = await OZSmartAccountAuth.buildAuthPayloadHash(
          entryCopy,
          expirationLedger,
          _kit.config.networkPassphrase,
        );
        final signature = tempKeypair.sign(payloadHash);

        final signatureMap = XdrSCVal.forMap(<XdrSCMapEntry>[
          XdrSCMapEntry(
            XdrSCVal.forSymbol('public_key'),
            XdrSCVal.forBytes(tempPubKey),
          ),
          XdrSCMapEntry(
            XdrSCVal.forSymbol('signature'),
            XdrSCVal.forBytes(signature),
          ),
        ]);
        final signatureVec = XdrSCVal.forVec(<XdrSCVal>[signatureMap]);

        final updatedCredentials = XdrSorobanAddressCredentials(
          credentials.address,
          credentials.nonce,
          XdrUint32(expirationLedger),
          signatureVec,
        );
        // Preserve the credential arm on write-back.
        result.add(XdrSorobanAuthorizationEntry(
          _rebuildCredentialsXdr(entryCopy.credentials, updatedCredentials),
          entryCopy.rootInvocation,
        ));
      } else if (entry.credentials.discriminant ==
          XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_WITH_DELEGATES) {
        // ADDRESS_WITH_DELEGATES entries require caller-policy routing.
        // The fundWallet flow cannot determine which delegate node to sign.
        throw SmartAccountTransactionException.signingFailed(
          'ADDRESS_WITH_DELEGATES auth entries cannot be signed by the '
          'fundWallet flow. Use SorobanAuthorizationEntry.sign with the '
          'forAddress parameter to sign delegate nodes before calling fundWallet.',
        );
      } else {
        // Unknown credential arm — fail fast rather than passing through unsigned.
        throw SmartAccountTransactionException.signingFailed(
          'Unrecognised credential arm '
          '${entry.credentials.discriminant} in auth entry; cannot sign.',
        );
      }
    }
    return result;
  }

  /// Returns `true` when relayer Mode 2 (signed transaction XDR) is required
  /// for the given auth-entry set. Mode 2 is required whenever any entry
  /// carries source-account credentials, because the relayer needs a
  /// fully-signed envelope to fee-bump in that case.
  bool _shouldUseRelayerMode2(List<XdrSorobanAuthorizationEntry> authEntries) {
    for (final entry in authEntries) {
      if (entry.credentials.discriminant ==
          XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_SOURCE_ACCOUNT) {
        return true;
      }
    }
    return false;
  }

  /// Discovers a WebAuthn signer's keyData by walking the on-chain context
  /// rules. Used when the credential is not in local storage (for example
  /// cross-device passkeys, or when the credential cache has been wiped).
  ///
  /// Each signer is encoded on-chain as
  /// `Vec([Symbol('External'), Address(verifier), Bytes(keyData)])`. The
  /// keyData layout is `publicKey || credentialId`; matching by the
  /// suffix-bytes recovers the full key data.
  Future<Uint8List> _findKeyDataFromContextRules(Uint8List credentialIdBytes) async {
    final allRules = await _kit.contextRuleManager.getAllContextRules();
    const pubKeySize = 65; // secp256r1 uncompressed pubkey size
    for (final ruleScVal in allRules) {
      final mapEntries = ruleScVal.map;
      if (mapEntries == null) continue;
      for (final entry in mapEntries) {
        final keySym = entry.key.sym;
        if (keySym != 'signers') continue;
        final signerVec = entry.val.vec;
        if (signerVec == null) break;
        for (final signerScVal in signerVec) {
          final parts = signerScVal.vec;
          if (parts == null || parts.isEmpty) continue;
          final tag = parts[0].sym;
          if (tag != 'External' || parts.length < 3) continue;
          final keyDataBytes = parts[2].bytes?.sCBytes;
          if (keyDataBytes == null || keyDataBytes.length <= pubKeySize) continue;
          final suffix = Uint8List.fromList(
            keyDataBytes.sublist(pubKeySize, keyDataBytes.length),
          );
          if (Util.constantTimeEquals(suffix, credentialIdBytes)) {
            return Uint8List.fromList(keyDataBytes);
          }
        }
        break;
      }
    }
    throw SmartAccountCredentialException.notFound(
      'No signer found on-chain for credential ID: ${ozBase64UrlEncode(credentialIdBytes)}',
    );
  }

  /// Submits or relays the fully-assembled transaction.
  ///
  /// Signs the envelope when the path requires it (direct RPC submission
  /// always; relayer Mode 2 when source-account auth is present). Polls for
  /// confirmation on the RPC path and after Mode 1 relayer submission.
  Future<OZTransactionResult> _submitOrRelay({
    required Transaction transaction,
    required XdrHostFunction hostFunction,
    required List<XdrSorobanAuthorizationEntry> signedAuthEntries,
    required KeyPair signer,
    required bool useRelayer,
    bool emitEvents = true,
    dio.CancelToken? cancelToken,
  }) async {
    final hasSourceAuth = _shouldUseRelayerMode2(signedAuthEntries);

    if (!useRelayer || hasSourceAuth) {
      transaction.sign(signer, Network(_kit.config.networkPassphrase));
    }

    _checkCancellation(cancelToken);

    if (useRelayer) {
      final relayer = _kit.relayerClient;
      if (relayer == null) {
        throw SmartAccountTransactionException.submissionFailed('Relayer is not configured');
      }

      final OZRelayerResponse relayerResponse;
      if (hasSourceAuth) {
        relayerResponse = await relayer.sendXdr(
          transaction.toEnvelopeXdr(),
          cancelToken: cancelToken,
        );
      } else {
        relayerResponse = await relayer.send(
          hostFunction,
          signedAuthEntries,
          cancelToken: cancelToken,
        );
      }

      if (emitEvents && relayerResponse.hash != null) {
        _kit.events.emit(OZSmartAccountEventTransactionSubmitted(
          hash: relayerResponse.hash!,
          success: relayerResponse.success,
        ));
      }

      if (relayerResponse.success && relayerResponse.hash != null) {
        return _pollForConfirmation(relayerResponse.hash!, cancelToken);
      }
      return OZTransactionResult(
        success: false,
        hash: relayerResponse.hash,
        error: relayerResponse.error ?? 'Relayer submission failed',
      );
    }

    // RPC path
    final SendTransactionResponse sendResult;
    try {
      sendResult = await _kit.sorobanServer.sendTransaction(transaction);
    } catch (e) {
      throw SmartAccountTransactionException.submissionFailed(
        'Failed to send transaction: $e',
        cause: e,
      );
    }

    final status = sendResult.status;
    if (status == SendTransactionResponse.STATUS_ERROR) {
      return OZTransactionResult(
        success: false,
        hash: sendResult.hash ?? '',
        error: sendResult.errorResultXdr ?? 'Transaction rejected by network',
      );
    }
    if (status == SendTransactionResponse.STATUS_TRY_AGAIN_LATER) {
      return OZTransactionResult(
        success: false,
        hash: sendResult.hash ?? '',
        error: 'Network is congested. Try again later.',
      );
    }

    final hash = sendResult.hash;
    if (hash == null) {
      throw SmartAccountTransactionException.submissionFailed(
        'No transaction hash returned from send result',
      );
    }

    if (emitEvents) {
      _kit.events.emit(OZSmartAccountEventTransactionSubmitted(
        hash: hash,
        success: true,
      ));
    }
    return _pollForConfirmation(hash, cancelToken);
  }

  /// Polls Soroban RPC for transaction confirmation using the SDK's built-in
  /// poll loop. Uses 30 attempts at 3-second intervals (90-second budget)
  /// to absorb ledger-close jitter and network congestion. Cancellation is
  /// observed each time the sleep strategy fires.
  Future<OZTransactionResult> _pollForConfirmation(
    String hash, [
    dio.CancelToken? cancelToken,
  ]) async {
    final GetTransactionResponse response;
    try {
      response = await _kit.sorobanServer.pollTransaction(
        hash,
        maxAttempts: 30,
        sleepStrategy: (_) {
          _checkCancellation(cancelToken);
          return const Duration(seconds: 3);
        },
      );
    } catch (e) {
      throw SmartAccountTransactionException.submissionFailed(
        'Failed to poll for transaction confirmation: $e',
        cause: e,
      );
    }

    switch (response.status) {
      case GetTransactionResponse.STATUS_SUCCESS:
        return OZTransactionResult(
          success: true,
          hash: hash,
          ledger: response.ledger,
        );
      case GetTransactionResponse.STATUS_FAILED:
        return OZTransactionResult(
          success: false,
          hash: hash,
          ledger: response.ledger,
          error: response.resultXdr ?? 'Transaction failed on-chain',
        );
      default:
        return OZTransactionResult(
          success: false,
          hash: hash,
          error: 'Transaction not confirmed after 30 polling attempts',
        );
    }
  }

  /// Generates an 8-byte cryptographically-random nonce reinterpreted as a
  /// signed `Int64`. Source-account auth conversion writes this into the
  /// Soroban address-credentials nonce field, which the contract uses to
  /// prevent replay.
  ///
  /// Delegates to [OZSecureNonce.generate] so the multi-signer manager
  /// and this single-signer pipeline draw nonces from the exact same
  /// generator; see [OZSecureNonce] for the implementation rationale.
  XdrInt64 _generateNonce() => OZSecureNonce.generate();

  /// Throws a [SmartAccountTransactionException] when [cancelToken] has been
  /// cancelled. Called between long-running awaits in the pipeline so
  /// callers can abort in flight even when the wrapped network calls
  /// themselves don't expose cancellation.
  void _checkCancellation(dio.CancelToken? cancelToken) {
    if (cancelToken != null && cancelToken.isCancelled) {
      throw SmartAccountTransactionException.submissionFailed(
        'Operation cancelled',
        cause: cancelToken.cancelError,
      );
    }
  }

  /// Polls the Soroban RPC until the account identified by [accountId] is
  /// visible as a classic account ledger entry, then returns.
  ///
  /// Friendbot returns once Horizon has confirmed the deposit, but the
  /// Soroban RPC simulation endpoint can lag behind by one or more ledger
  /// closes under testnet congestion. Simulating a contract call that reads
  /// the account entry before the RPC has applied the funding ledger fails
  /// with an opaque "account entry is missing" contract error, so callers
  /// must wait until the RPC sees the account.
  ///
  /// [SorobanServer.getAccount] queries the RPC's `getLedgerEntries` for the
  /// account ledger key and returns `null` while the entry is not yet
  /// present; a non-null result is the visibility signal polled here. The
  /// poll runs every [pollInterval] up to [timeout]; both default to the
  /// [OZConstants.rpcVisibilityPollIntervalMs] /
  /// [OZConstants.rpcVisibilityTimeoutSeconds] budgets and are
  /// overridable so the behaviour can be exercised in tests.
  ///
  /// A thrown RPC error (transport failure, 5xx) is treated as transient and
  /// retried until the deadline, and the most recent one is attached to the
  /// timeout error as its cause. An in-band JSON-RPC error envelope (HTTP 200
  /// with an `error` member) is instead returned by [SorobanServer.getAccount]
  /// as a `null` result, indistinguishable from a not-yet-visible account, so
  /// it is retried the same way and the timeout error then carries no cause.
  ///
  /// [cancelToken] is observed before each poll and during each inter-poll
  /// sleep so the caller can abort in flight. Throws
  /// [SmartAccountTransactionException.timeout] when the account does
  /// not become visible within [timeout].
  @visibleForTesting
  Future<void> waitForAccountVisibleToRpc(
    String accountId,
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
        final account = await _kit.sorobanServer.getAccount(accountId);
        if (account != null) {
          return;
        }
      } on Exception catch (e) {
        // Transient RPC exceptions are treated as "not yet visible" and
        // retried until the deadline; the most recent one is surfaced as the
        // timeout cause. The production caller always passes a valid accountId,
        // so in practice these are RPC-level failures (congestion, 5xx). Error
        // subclasses (programmer/RPC-client bugs) are not caught here, so they
        // propagate immediately instead of being masked for the full timeout
        // budget.
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
      details: 'Funding account $accountId not visible to the Soroban RPC '
          'within $timeoutLabel after Friendbot funding; testnet propagation '
          'may be delayed. Retry shortly.',
      cause: lastError,
    );
  }

  /// Fetches an account from Soroban RPC, throwing
  /// [SmartAccountTransactionException.submissionFailed] when the account is not found
  /// or when the RPC call fails.
  Future<Account> _fetchAccount(String accountId) async {
    final Account? account;
    try {
      account = await _kit.sorobanServer.getAccount(accountId);
    } catch (e) {
      throw SmartAccountTransactionException.submissionFailed(
        'Failed to fetch account $accountId: $e',
        cause: e,
      );
    }
    if (account == null) {
      throw SmartAccountTransactionException.submissionFailed(
        'Account not found: $accountId',
      );
    }
    return account;
  }

  /// Applies a simulation result's soroban data, auth entries, and minimum
  /// resource fee to the supplied transaction. Behaves like
  /// [SorobanServer.prepareTransaction] but does not sign the envelope.
  void _applySimulationToTransaction(
    Transaction transaction,
    SimulateTransactionResponse simulation,
  ) {
    final transactionData = simulation.transactionData;
    if (transactionData != null) {
      transaction.sorobanTransactionData = transactionData;
    }

    final minResourceFee = simulation.minResourceFee;
    if (minResourceFee != null) {
      transaction.addResourceFee(minResourceFee);
    }

    final sorobanAuth = simulation.getSorobanAuth();
    if (sorobanAuth != null) {
      transaction.setSorobanAuth(sorobanAuth);
    }
  }

  /// Formats the supplied stroop value as a Stellar XLM decimal string.
  ///
  /// Trims trailing zeros from the fractional component so a whole-number
  /// amount renders as e.g. `"100000"` rather than `"100000.0000000"`.
  String _formatXlmString(BigInt stroops) {
    final divisor = BigInt.from(Util.stroopsPerXlm);
    final whole = stroops ~/ divisor;
    final fraction = stroops % divisor;
    if (fraction == BigInt.zero) {
      return whole.toString();
    }
    var fractionStr = fraction.toString().padLeft(7, '0');
    while (fractionStr.isNotEmpty && fractionStr.endsWith('0')) {
      fractionStr = fractionStr.substring(0, fractionStr.length - 1);
    }
    if (fractionStr.isEmpty) {
      return whole.toString();
    }
    return '$whole.$fractionStr';
  }

  /// Reads the optional `error` field from a simulation response, returning
  /// either the `resultError` string or the JSON-RPC error message.
  String? _errorMessage(SimulateTransactionResponse simulation) {
    if (simulation.resultError != null && simulation.resultError!.isNotEmpty) {
      return simulation.resultError;
    }
    final rpcError = simulation.error;
    if (rpcError != null && rpcError.message != null && rpcError.message!.isNotEmpty) {
      return rpcError.message;
    }
    return null;
  }

  /// Parses auth entries from the first simulation result, returning an
  /// empty list when no entries are present.
  List<XdrSorobanAuthorizationEntry> _extractAuthEntries(
    SimulateTransactionResponse simulation,
  ) {
    final results = simulation.results;
    if (results == null || results.isEmpty) {
      return const <XdrSorobanAuthorizationEntry>[];
    }
    final authBase64 = results[0].auth;
    final out = <XdrSorobanAuthorizationEntry>[];
    for (final encoded in authBase64) {
      out.add(XdrSorobanAuthorizationEntry.fromBase64EncodedXdrString(encoded));
    }
    return out;
  }

  /// Wraps a list of XDR auth entries in the SDK's higher-level
  /// `SorobanAuthorizationEntry` type, which is what
  /// `InvokeHostFunctionOperation` accepts.
  List<SorobanAuthorizationEntry> _wrapAuthEntries(
    List<XdrSorobanAuthorizationEntry> entries,
  ) {
    return entries
        .map(SorobanAuthorizationEntry.fromXdr)
        .toList(growable: true);
  }

  /// Builds an `XdrSCVal` of address type from a G- or C-address string.
  XdrSCVal _addressScVal(String address) {
    if (StrKey.isValidContractId(address)) {
      return XdrSCVal.forAddress(Address.forContractId(address).toXdr());
    }
    return XdrSCVal.forAddress(Address.forAccountId(address).toXdr());
  }

  /// Decodes an SCV_I128 ScVal to a [BigInt] interpreting the parts as a
  /// signed 128-bit integer (`hi` signed Int64 high half, `lo` unsigned
  /// Uint64 low half).
  BigInt _scValToBigInt(XdrSCVal value) {
    final i128 = value.i128;
    if (i128 == null) {
      throw ArgumentError('expected SCV_I128 value');
    }
    final hi = i128.hi.int64;
    final lo = i128.lo.uint64;
    final shifted = hi << 64;
    return shifted + lo;
  }

  /// Concatenates two byte arrays into a fresh [Uint8List].
  Uint8List _concat(Uint8List a, Uint8List b) {
    final out = Uint8List(a.length + b.length)
      ..setRange(0, a.length, a)
      ..setRange(a.length, a.length + b.length, b);
    return out;
  }

  /// Round-trips an auth entry through XDR so the cloned copy can be safely
  /// mutated without touching the original.
  XdrSorobanAuthorizationEntry _cloneAuthEntry(XdrSorobanAuthorizationEntry entry) {
    final stream = XdrDataOutputStream();
    XdrSorobanAuthorizationEntry.encode(stream, entry);
    final bytes = Uint8List.fromList(stream.bytes);
    return XdrSorobanAuthorizationEntry.decode(XdrDataInputStream(bytes));
  }

  /// Round-trips a soroban authorized invocation through XDR so the source
  /// account → address-credential conversion path can substitute the
  /// credentials without sharing structural state with the original entry.
  XdrSorobanAuthorizedInvocation _cloneInvocation(
    XdrSorobanAuthorizedInvocation invocation,
  ) {
    final stream = XdrDataOutputStream();
    XdrSorobanAuthorizedInvocation.encode(stream, invocation);
    final bytes = Uint8List.fromList(stream.bytes);
    return XdrSorobanAuthorizedInvocation.decode(XdrDataInputStream(bytes));
  }

  /// Returns the inner [XdrSorobanAddressCredentials] for ADDRESS or
  /// ADDRESS_V2 arms, or null for SOURCE_ACCOUNT and unknown arms.
  ///
  /// ADDRESS_WITH_DELEGATES is intentionally excluded: the callers that use
  /// this helper enforce the WITH_DELEGATES restriction before calling.
  static XdrSorobanAddressCredentials? _innerAddressCredentialsXdr(
    XdrSorobanCredentials creds,
  ) {
    switch (creds.discriminant) {
      case XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS:
        return creds.address;
      case XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2:
        return creds.addressV2;
      default:
        return null;
    }
  }

  /// Rebuilds a [XdrSorobanCredentials] wrapper preserving the original
  /// credential arm, replacing the inner credentials with [updated].
  ///
  /// Only ADDRESS and ADDRESS_V2 arms are supported; other arms throw
  /// [SmartAccountTransactionSigningFailed].
  static XdrSorobanCredentials _rebuildCredentialsXdr(
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

  // Static amount helpers

  /// Maximum number of decimal places accepted by [amountToBaseUnits].
  ///
  /// `10^38` already exceeds the i128 range used for token amounts, so a
  /// larger scale could never produce a representable base-units value.
  static const int maxTokenDecimals = 38;

  /// Converts a positive decimal [amount] string to its base-units value
  /// scaled by [decimals] decimal places.
  ///
  /// Rejects scientific notation, empty or non-numeric strings, values less
  /// than or equal to zero, and values carrying more fractional digits than
  /// [decimals] allows. Accepted shape: `^[0-9]+(\.[0-9]+)?$` with at most
  /// [decimals] fractional digits and a result greater than zero.
  ///
  /// [decimals] is the token's decimal scale and must be in
  /// `0..maxTokenDecimals`; a value of `0` accepts only integer amounts.
  ///
  /// Throws [SmartAccountInvalidAmount] when [amount] is invalid or [decimals]
  /// is out of range.
  static BigInt amountToBaseUnits(String amount, {required int decimals}) {
    if (decimals < 0) {
      throw SmartAccountValidationException.invalidAmount(
        amount,
        reason: 'Token decimals must not be negative',
      );
    }
    if (decimals > maxTokenDecimals) {
      throw SmartAccountValidationException.invalidAmount(
        amount,
        reason: 'Token decimals must not exceed $maxTokenDecimals',
      );
    }

    final trimmed = amount.trim();
    if (trimmed.isEmpty) {
      throw SmartAccountValidationException.invalidAmount(
        amount,
        reason: 'Amount must not be empty',
      );
    }

    if (!RegExp(r'^[0-9]+(\.[0-9]+)?$').hasMatch(trimmed)) {
      throw SmartAccountValidationException.invalidAmount(
        amount,
        reason: 'Amount must be a positive decimal number',
      );
    }

    final parts = trimmed.split('.');
    final wholePart = parts[0];
    final fractionPart = parts.length > 1 ? parts[1] : '';

    if (fractionPart.length > decimals) {
      throw SmartAccountValidationException.invalidAmount(
        amount,
        reason: 'Amount has more than $decimals fractional digits',
      );
    }

    final paddedFraction = fractionPart.padRight(decimals, '0');
    final baseUnits = BigInt.parse(wholePart + paddedFraction);

    if (baseUnits <= BigInt.zero) {
      throw SmartAccountValidationException.invalidAmount(
        amount,
        reason: 'Amount must be greater than zero',
      );
    }
    return baseUnits;
  }

  /// Encodes a [baseUnits] value as an i128 [XdrSCVal], surfacing an
  /// out-of-range value as a tagged validation error.
  ///
  /// [amount] is the original caller-supplied amount, used for the error
  /// message.
  @internal
  static XdrSCVal baseUnitsToI128ScVal(
    BigInt baseUnits, {
    required String amount,
  }) {
    try {
      return Util.bigIntToI128ScVal(baseUnits);
    } catch (e) {
      throw SmartAccountValidationException.invalidAmount(
        amount,
        reason: 'Amount is outside the supported i128 range',
        cause: e,
      );
    }
  }

  /// Extracts a `u32` from [value], used to parse a token contract's
  /// `decimals()` return value. Returns `null` when [value] is not a `u32`.
  static int? _scValToUInt32(XdrSCVal value) {
    if (value.discriminant != XdrSCValType.SCV_U32) {
      return null;
    }
    return value.u32?.uint32;
  }
}

