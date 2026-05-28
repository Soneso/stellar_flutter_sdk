// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:meta/meta.dart';

import '../../account.dart';
import '../../invoke_host_function_operation.dart';
import '../../key_pair.dart';
import '../../memo.dart';
import '../../soroban/soroban_auth.dart';
import '../../soroban/soroban_server.dart';
import '../../transaction.dart';
import '../../util.dart';
import '../../xdr/xdr.dart';
import '../core/allow_credential.dart';
import '../core/smart_account_constants.dart';
import '../core/smart_account_errors.dart';
import '../core/smart_account_utils.dart';
import '../core/web_authn_provider.dart';
import 'oz_address_strkey.dart';
import 'oz_external_signer_manager.dart' show OZExternalSignerManager;
import 'oz_internal_pipeline_interfaces.dart';
import 'oz_secure_nonce.dart';
import 'oz_selected_signer.dart';
import 'oz_smart_account_auth.dart';
import 'oz_smart_account_signatures.dart';
import 'oz_smart_account_types.dart';
import 'oz_storage_adapter.dart';
import 'oz_transaction_operations.dart';
import 'oz_validation.dart';

// Re-export the SelectedSigner hierarchy; declarations live in oz_selected_signer.dart
// to avoid a circular import with the sibling managers.
export 'oz_selected_signer.dart';

/// Manager for multi-signature smart-account operations.
///
/// Provides functionality for executing multi-signer operations across
/// passkey and external-wallet signers. Signatures are collected
/// sequentially in the order the caller supplies via [SelectedSigner],
/// enabling fail-fast behaviour on user cancellation.
///
/// Each [SelectedSignerPasskey] triggers one OS WebAuthn authentication
/// prompt. Each [SelectedSignerWallet] signs via the configured
/// [ExternalWalletAdapter]. The connected passkey is NOT added
/// implicitly; if it should sign, include a [SelectedSignerPasskey]
/// referencing it.
///
/// Delegated wallet signers produce their own auth entries with Address
/// credentials targeting the smart account's `__check_auth` function;
/// the smart account's signature map carries an empty-bytes placeholder
/// per delegated signer.
class OZMultiSignerManager implements OZMultiSignerManagerInterface {
  /// Constructs a multi-signer manager bound to the supplied kit.
  /// Marked [internal] because consumers reach this manager via
  /// `kit.multiSignerManager`.
  @internal
  OZMultiSignerManager(this._kit);

  final OZSmartAccountWalletKitInterface _kit;

  // -------------------------------------------------------------------------
  // Multi-signer transfer
  // -------------------------------------------------------------------------

  /// Executes a SEP-41 token transfer signed by the explicit list of
  /// signers in [selectedSigners].
  ///
  /// Validates the recipient address, prevents self-transfer, converts
  /// [amount] to stroops via [Util.toXdrInt64Amount], builds a
  /// `transfer(from, to, amount)` host function, and routes through the
  /// multi-signer signing pipeline.
  Future<TransactionResult> multiSignerTransfer({
    required String tokenContract,
    required String recipient,
    required String amount,
    required List<SelectedSigner> selectedSigners,
    SubmissionMethod? forceMethod,
    ResolveContextRuleIds? resolveContextRuleIds,
  }) async {
    final connected = await _kit.requireConnected();

    requireStellarAddress(recipient, fieldName: 'recipient');

    if (recipient == connected.contractId) {
      throw ValidationException.invalidInput(
        'recipient',
        'Cannot transfer to self',
      );
    }

    final stroops = Util.toXdrInt64Amount(amount);

    final targetArgs = <XdrSCVal>[
      XdrSCVal.forAddress(Address.forContractId(connected.contractId).toXdr()),
      _addressScVal(recipient),
      Util.stroopsToI128ScVal(stroops),
    ];

    return multiSignerContractCall(
      target: tokenContract,
      targetFn: 'transfer',
      targetArgs: targetArgs,
      selectedSigners: selectedSigners,
      forceMethod: forceMethod,
      resolveContextRuleIds: resolveContextRuleIds,
    );
  }

  // -------------------------------------------------------------------------
  // Multi-signer direct contract call
  // -------------------------------------------------------------------------

  /// Calls an arbitrary function on an external contract directly with
  /// multi-signer authorisation.
  ///
  /// The smart account's matching `CallContract(target)` context rule
  /// is used for authorisation, allowing per-contract multi-signer
  /// rules to take effect.
  Future<TransactionResult> multiSignerContractCall({
    required String target,
    required String targetFn,
    List<XdrSCVal> targetArgs = const <XdrSCVal>[],
    required List<SelectedSigner> selectedSigners,
    SubmissionMethod? forceMethod,
    ResolveContextRuleIds? resolveContextRuleIds,
  }) async {
    await _kit.requireConnected();
    _validateContractCallArgs(target, targetFn, selectedSigners);

    final hostFunction = XdrHostFunction.forInvokingContractWithArgs(
      XdrInvokeContractArgs(
        Address.forContractId(target).toXdr(),
        targetFn,
        List<XdrSCVal>.from(targetArgs),
      ),
    );

    return submitWithMultipleSigners(
      hostFunction: hostFunction,
      selectedSigners: selectedSigners,
      forceMethod: forceMethod,
      resolveContextRuleIds: resolveContextRuleIds,
    );
  }

  // -------------------------------------------------------------------------
  // Multi-signer execute (smart-account mediated)
  // -------------------------------------------------------------------------

  /// Executes an arbitrary contract call through the smart account's
  /// `execute(target, target_fn, target_args)` entry point with
  /// multi-signer authorisation.
  Future<TransactionResult> multiSignerExecuteAndSubmit({
    required String target,
    required String targetFn,
    List<XdrSCVal> targetArgs = const <XdrSCVal>[],
    required List<SelectedSigner> selectedSigners,
    SubmissionMethod? forceMethod,
    ResolveContextRuleIds? resolveContextRuleIds,
  }) async {
    final connected = await _kit.requireConnected();
    _validateContractCallArgs(target, targetFn, selectedSigners);

    final functionArgs = <XdrSCVal>[
      XdrSCVal.forAddress(Address.forContractId(target).toXdr()),
      XdrSCVal.forSymbol(targetFn),
      XdrSCVal.forVec(List<XdrSCVal>.from(targetArgs)),
    ];

    final hostFunction = XdrHostFunction.forInvokingContractWithArgs(
      XdrInvokeContractArgs(
        Address.forContractId(connected.contractId).toXdr(),
        'execute',
        functionArgs,
      ),
    );

    return submitWithMultipleSigners(
      hostFunction: hostFunction,
      selectedSigners: selectedSigners,
      forceMethod: forceMethod,
      resolveContextRuleIds: resolveContextRuleIds,
    );
  }

  // -------------------------------------------------------------------------
  // Internal shared signing pipeline
  // -------------------------------------------------------------------------

  /// Shared signing pipeline for multi-signer operations.
  ///
  /// Validates wallet-signer reachability, simulates the transaction to
  /// discover auth entries, hoists the per-signer external-signer
  /// reconstruction outside the entry loop, signs each entry per signer
  /// (passkey signatures via WebAuthn, wallet signatures via
  /// [ExternalWalletAdapter]), re-simulates with the signed entries to
  /// pick up accurate resource fees, and routes through
  /// [OZTransactionOperations.submitMultiSignerTransaction] for the
  /// final relayer-or-RPC submission.
  Future<TransactionResult> submitWithMultipleSigners({
    required XdrHostFunction hostFunction,
    required List<SelectedSigner> selectedSigners,
    SubmissionMethod? forceMethod,
    ResolveContextRuleIds? resolveContextRuleIds,
  }) async {
    final connected = await _kit.requireConnected();

    final walletSigners =
        selectedSigners.whereType<SelectedSignerWallet>().toList(
              growable: false,
            );

    if (walletSigners.isNotEmpty && _kit.externalWallet == null) {
      throw ValidationException.invalidInput(
        'selectedSigners',
        'Wallet signers require an external wallet adapter to be configured',
      );
    }

    for (final walletSigner in walletSigners) {
      bool canSign;
      try {
        canSign = _kit.externalWallet!.canSignFor(walletSigner.address);
      } catch (_) {
        canSign = false;
      }
      if (!canSign) {
        throw ValidationException.invalidInput(
          'selectedSigners',
          'No signer available for address: ${walletSigner.address}. '
              'Use externalWallet.addFromSecret() or '
              'externalWallet.addFromWallet() to add a signer.',
        );
      }
    }

    // Validate Ed25519 signers: verifier address format, public-key length,
    // and signing-source availability. All precondition checks run before any
    // RPC call so failures surface cheaply.
    final ed25519Signers =
        selectedSigners.whereType<SelectedSignerEd25519>().toList(
              growable: false,
            );

    if (ed25519Signers.isNotEmpty) {
      final extManager = _kit.externalSignerManager;
      if (extManager == null) {
        throw ValidationException.invalidInput(
          'selectedSigners',
          'Ed25519 signers require OZExternalSignerManager to be configured '
              'on the kit',
        );
      }
      await _validateEd25519Signers(extManager, ed25519Signers);
    }

    // Step 1: simulate to discover auth entries.
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
        .build();

    final SimulateTransactionResponse simulation;
    try {
      simulation = await _kit.sorobanServer
          .simulateTransaction(SimulateTransactionRequest(transaction));
    } catch (e) {
      throw TransactionException.simulationFailed(
        'Failed to simulate multi-signer transaction: $e',
        cause: e,
      );
    }

    final initialError = _simulationErrorMessage(simulation);
    if (initialError != null) {
      throw TransactionException.simulationFailed(
        'Simulation error: $initialError',
      );
    }

    final sorobanAuth = simulation.sorobanAuth;
    if (sorobanAuth == null || sorobanAuth.isEmpty) {
      throw TransactionException.simulationFailed(
        'No auth entries returned from simulation',
      );
    }

    final authEntries = sorobanAuth
        .map((e) => e.toXdr())
        .toList(growable: false);

    // Step 2: latest ledger.
    final latestLedger = await _kit.sorobanServer.getLatestLedger();
    final ledgerSeq = latestLedger.sequence;
    if (ledgerSeq == null) {
      throw TransactionException.submissionFailed(
        'Failed to fetch latest ledger sequence',
      );
    }

    // Step 3: expiration.
    final expirationLedger =
        ledgerSeq + _kit.config.signatureExpirationLedgers;

    // Step 3b: pre-fetch context rules ONCE for every entry.
    final contextRules = await _kit.contextRuleManager.listContextRules();

    // Step 3c: hoist signer reconstruction outside the entry loop;
    // selectedSigners is invariant per call. Throws once if any
    // passkey lacks keyData (per the documented hoist invariant). Ed25519
    // signers are included so context-rule resolution counts them correctly.
    final smartAccountSigners = <OZSmartAccountSigner>[];
    for (final selectedSigner in selectedSigners) {
      if (selectedSigner is SelectedSignerPasskey) {
        final keyData = selectedSigner.keyData;
        if (keyData == null) {
          throw ValidationException.invalidInput(
            'selectedSigners',
            'keyData is required for passkey signers for rule resolution',
          );
        }
        smartAccountSigners.add(
          OZExternalSigner(_kit.config.webauthnVerifierAddress, keyData),
        );
      } else if (selectedSigner is SelectedSignerWallet) {
        smartAccountSigners.add(OZDelegatedSigner(selectedSigner.address));
      } else if (selectedSigner is SelectedSignerEd25519) {
        smartAccountSigners.add(
          OZExternalSigner.ed25519(
            verifierAddress: selectedSigner.verifierAddress,
            publicKey: selectedSigner.publicKey,
          ),
        );
      }
    }

    // Step 4: sign auth entries.
    final signedAuthEntries = <XdrSorobanAuthorizationEntry>[];

    for (var entryIndex = 0; entryIndex < authEntries.length; entryIndex++) {
      final entry = authEntries[entryIndex];

      final addressCreds = entry.credentials.address;
      if (entry.credentials.discriminant !=
              XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS ||
          addressCreds == null) {
        signedAuthEntries.add(entry);
        continue;
      }

      final entryAddress = _addressToString(addressCreds.address);
      if (entryAddress != connected.contractId) {
        SelectedSignerWallet? matching;
        for (final w in walletSigners) {
          if (w.address == entryAddress) {
            matching = w;
            break;
          }
        }
        if (matching != null) {
          final signedWalletEntry = await _signWalletAddressAuthEntry(
            entry: entry,
            walletSigner: matching,
            expirationLedger: expirationLedger,
          );
          signedAuthEntries.add(signedWalletEntry);
        } else {
          throw TransactionException.signingFailed(
            'Unsupported auth entry for $entryAddress. '
            'Add an external signer for that address or remove it from '
            'the transaction.',
          );
        }
        continue;
      }

      var signedEntry = _cloneEntryWithExpiration(entry, expirationLedger);

      final List<int> resolvedContextRuleIds;
      if (resolveContextRuleIds != null) {
        resolvedContextRuleIds =
            await resolveContextRuleIds(signedEntry, entryIndex);
      } else {
        resolvedContextRuleIds = await _kit.contextRuleManager
            .resolveContextRuleIdsForEntry(
                signedEntry, smartAccountSigners, contextRules);
      }

      final payloadHash = await OZSmartAccountAuth.buildAuthPayloadHash(
        signedEntry,
        expirationLedger,
        _kit.config.networkPassphrase,
      );

      final authDigest = await OZSmartAccountAuth.buildAuthDigest(
        payloadHash,
        resolvedContextRuleIds,
      );

      // Step 4a: per-passkey WebAuthn signing.
      for (var signerIndex = 0;
          signerIndex < selectedSigners.length;
          signerIndex++) {
        final selectedSigner = selectedSigners[signerIndex];
        if (selectedSigner is! SelectedSignerPasskey) continue;

        final webauthnProvider = _kit.config.webauthnProvider;
        if (webauthnProvider == null) {
          throw ValidationException.invalidInput(
            'webauthnProvider',
            'WebAuthn provider is required for passkey signers but is '
                'not configured',
          );
        }

        final allowCredentials = selectedSigner.credentialIdBytes != null
            ? <AllowCredential>[
                AllowCredential(
                  id: selectedSigner.credentialIdBytes!,
                  transports: selectedSigner.transports,
                ),
              ]
            : null;

        final WebAuthnAuthenticationResult authResult;
        try {
          authResult = await webauthnProvider.authenticate(
            challenge: authDigest,
            allowCredentials: allowCredentials,
          );
        } catch (e) {
          throw WebAuthnException.authenticationFailed(
            'WebAuthn authentication failed for passkey signer '
            '${signerIndex + 1}/${selectedSigners.length}: $e',
            cause: e,
          );
        }

        final compactSig =
            SmartAccountUtils.normalizeSignature(authResult.signature);

        final webAuthnSig = OZWebAuthnSignature(
          authenticatorData: authResult.authenticatorData,
          clientData: authResult.clientDataJSON,
          signature: compactSig,
        );

        // keyData is non-null here: the hoist above throws when any passkey lacks it.
        final passkeySigner = OZExternalSigner(
          _kit.config.webauthnVerifierAddress,
          selectedSigner.keyData!,
        );

        signedEntry = await OZSmartAccountAuth.signAuthEntry(
          entry: signedEntry,
          signer: passkeySigner,
          signature: webAuthnSig,
          expirationLedger: expirationLedger,
          contextRuleIds: resolvedContextRuleIds,
        );
      }

      // Step 4b: per-wallet delegated-signer auth entries plus
      // placeholders.
      for (final selectedSigner in selectedSigners) {
        if (selectedSigner is! SelectedSignerWallet) continue;

        final externalWallet = _kit.externalWallet!;

        final checkAuthInvocation = XdrSorobanAuthorizedInvocation(
          XdrSorobanAuthorizedFunction.forInvokeContractArgs(
            XdrInvokeContractArgs(
              Address.forContractId(connected.contractId).toXdr(),
              '__check_auth',
              <XdrSCVal>[XdrSCVal.forBytes(authDigest)],
            ),
          ),
          <XdrSorobanAuthorizedInvocation>[],
        );

        final signedDelegatedEntry = await _authorizeInvocation(
          publicKey: selectedSigner.address,
          validUntilLedgerSeq: expirationLedger,
          invocation: checkAuthInvocation,
          signer: (preimage) async {
            final stream = XdrDataOutputStream();
            XdrHashIDPreimage.encode(stream, preimage);
            final preimageXdr = base64Encode(stream.bytes);
            try {
              final result = await externalWallet.signAuthEntry(
                preimageXdr,
                options: SignAuthEntryOptions(
                  networkPassphrase: _kit.config.networkPassphrase,
                  address: selectedSigner.address,
                ),
              );
              final sigBytes = base64Decode(result.signedAuthEntry);
              final sigSignerAddress = result.signerAddress ??
                  selectedSigner.address;
              return _AuthSignature(
                publicKey: sigSignerAddress,
                signature: Uint8List.fromList(sigBytes),
              );
            } catch (e) {
              throw TransactionException.signingFailed(
                'External wallet signing failed for '
                '${selectedSigner.address}: $e',
                cause: e,
              );
            }
          },
        );
        signedAuthEntries.add(signedDelegatedEntry);

        final delegatedSigner = OZDelegatedSigner(selectedSigner.address);
        signedEntry = OZSmartAccountAuth.addRawSignatureMapEntry(
          entry: signedEntry,
          signerKey: delegatedSigner.toScVal(),
          signatureValue: XdrSCVal.forBytes(Uint8List(0)),
          contextRuleIds: resolvedContextRuleIds,
        );
      }

      // Step 4c: per-Ed25519 signer signing.
      signedEntry = await _signEntryWithEd25519Signers(
        workingEntry: signedEntry,
        authDigest: authDigest,
        expirationLedger: expirationLedger,
        resolvedContextRuleIds: resolvedContextRuleIds,
        ed25519Signers: ed25519Signers,
      );

      signedAuthEntries.add(signedEntry);
    }

    // Update lastUsedAt for each passkey signer that participated.
    for (final signer in selectedSigners) {
      if (signer is SelectedSignerPasskey && signer.credentialId != null) {
        try {
          await _kit.credentialManager.updateLastUsed(signer.credentialId!);
        } catch (_) {
          // why: credential metadata tracking is best-effort.
        }
      }
    }

    // Step 5: re-simulate signed envelope with fresh deployer account.
    final refetchedDeployerAccount = await _fetchAccount(deployer.accountId);

    final signedOperation = InvokeHostFunctionOperation(
      HostFunction.fromXdr(hostFunction),
      auth: signedAuthEntries
          .map(SorobanAuthorizationEntry.fromXdr)
          .toList(growable: false),
    );
    final signedTransaction = TransactionBuilder(refetchedDeployerAccount)
        .setMaxOperationFee(AbstractTransaction.MIN_BASE_FEE)
        .addOperation(signedOperation)
        .addMemo(Memo.none())
        .build();

    final SimulateTransactionResponse reSimulation;
    try {
      reSimulation = await _kit.sorobanServer.simulateTransaction(
        SimulateTransactionRequest(signedTransaction),
      );
    } catch (e) {
      throw TransactionException.simulationFailed(
        'Failed to re-simulate signed multi-signer transaction: $e',
        cause: e,
      );
    }

    final reSimError = _simulationErrorMessage(reSimulation);
    if (reSimError != null) {
      throw TransactionException.simulationFailed(
        'Re-simulation error: $reSimError',
      );
    }

    // Step 6: delegate to single-signer infrastructure for submission.
    return _kit.transactionOperations.submitMultiSignerTransaction(
      hostFunction: hostFunction,
      signedAuthEntries: signedAuthEntries,
      signedTransaction: signedTransaction,
      simulation: reSimulation,
      forceMethod: forceMethod,
    );
  }

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  /// Validates each [SelectedSignerEd25519] in [ed25519Signers] against the
  /// registered signing sources in [extManager].
  ///
  /// Checks (in order per signer):
  /// 1. [SelectedSignerEd25519.verifierAddress] is a valid C-strkey.
  /// 2. [SelectedSignerEd25519.publicKey] is exactly
  ///    [SmartAccountConstants.ed25519PublicKeySize] bytes.
  /// 3. [extManager.canSignEd25519For] returns true (keypair or adapter
  ///    registered).
  ///
  /// Throws [ValidationException.invalidInput] on the first violation found.
  /// All checks run synchronously via the manager's in-memory registry, so
  /// the method returns quickly before any RPC call is made.
  Future<void> _validateEd25519Signers(
    OZExternalSignerManager extManager,
    List<SelectedSignerEd25519> ed25519Signers,
  ) async {
    for (final ed25519Signer in ed25519Signers) {
      if (!StrKey.isValidContractId(ed25519Signer.verifierAddress)) {
        throw ValidationException.invalidInput(
          'selectedSigners',
          'Ed25519 signer has an invalid verifier address (must be a C... '
              'contract strkey): ${ed25519Signer.verifierAddress}',
        );
      }

      if (ed25519Signer.publicKey.length !=
          SmartAccountConstants.ed25519PublicKeySize) {
        throw ValidationException.invalidInput(
          'selectedSigners',
          'Ed25519 signer public key must be exactly '
              '${SmartAccountConstants.ed25519PublicKeySize} bytes, '
              'got ${ed25519Signer.publicKey.length}',
        );
      }

      final canSign = extManager.canSignEd25519For(
        verifierAddress: ed25519Signer.verifierAddress,
        publicKey: ed25519Signer.publicKey,
      );
      if (!canSign) {
        final prefix =
            SmartAccountUtils.truncateForLog(ed25519Signer.verifierAddress);
        throw ValidationException.invalidInput(
          'selectedSigners',
          'Ed25519 signer (verifier=$prefix...) has no registered keypair '
              'or adapter — register via '
              'OZExternalSignerManager.addEd25519FromRawKey(...) before '
              'signing',
        );
      }
    }
  }

  /// Collects one Ed25519 signature per [SelectedSignerEd25519] entry in
  /// declaration order and chains each onto [workingEntry]'s signature map.
  ///
  /// The signing source is resolved via the adapter-first precedence rule
  /// documented on [OZExternalSignerManager.signEd25519AuthDigest]. After the
  /// adapter or in-memory keypair returns the 64-byte signature, the pipeline
  /// locally verifies it before accepting it. This prevents a signing source
  /// that returns a wrong signature from causing an opaque on-chain failure
  /// after submission.
  ///
  /// Non-Ed25519 entries in [selectedSigners] are skipped. When no Ed25519
  /// entries are present, [workingEntry] is returned unchanged.
  Future<XdrSorobanAuthorizationEntry> _signEntryWithEd25519Signers({
    required XdrSorobanAuthorizationEntry workingEntry,
    required Uint8List authDigest,
    required int expirationLedger,
    required List<int> resolvedContextRuleIds,
    required List<SelectedSignerEd25519> ed25519Signers,
  }) async {
    var currentEntry = workingEntry;

    if (ed25519Signers.isEmpty) return currentEntry;

    // validateSignerSet guarantees externalSignerManager is non-null whenever
    // Ed25519 signers are present.
    final extManager = _kit.externalSignerManager!;

    for (final selectedSigner in ed25519Signers) {
      final verifierAddress = selectedSigner.verifierAddress;
      final publicKey = selectedSigner.publicKey;

      // Request the 64-byte signature from the external signer manager. The
      // manager implements adapter-first precedence internally.
      final rawSignature = await extManager.signEd25519AuthDigest(
        verifierAddress: verifierAddress,
        publicKey: publicKey,
        authDigest: authDigest,
      );

      // Local signature verification: ensure the returned signature verifies
      // against the registered public key before trusting it downstream. This
      // makes failures actionable before submission rather than producing an
      // opaque on-chain auth failure.
      if (rawSignature.length != SmartAccountConstants.ed25519SignatureSize) {
        throw TransactionException.signingFailed(
          'Ed25519 signing source returned ${rawSignature.length} bytes for '
              'verifier $verifierAddress; expected '
              '${SmartAccountConstants.ed25519SignatureSize}',
        );
      }

      // KeyPair.verify takes the raw message bytes (no pre-hashing); it
      // internally constructs the signed-message structure.
      final verifierKeypair = KeyPair.fromPublicKey(publicKey);
      final signatureValid = verifierKeypair.verify(authDigest, rawSignature);
      if (!signatureValid) {
        throw TransactionException.signingFailed(
          'Ed25519 signing source returned a signature that does not verify '
              'against the registered public key for verifier $verifierAddress',
        );
      }

      // Wrap the verified 64-byte signature into the on-chain map shape and
      // attach it to the working entry.
      final ed25519Sig = OZEd25519Signature(
        publicKey: publicKey,
        signature: rawSignature,
      );
      final ed25519Signer = OZExternalSigner.ed25519(
        verifierAddress: verifierAddress,
        publicKey: publicKey,
      );

      currentEntry = await OZSmartAccountAuth.signAuthEntry(
        entry: currentEntry,
        signer: ed25519Signer,
        signature: ed25519Sig,
        expirationLedger: expirationLedger,
        contextRuleIds: resolvedContextRuleIds,
      );
    }

    return currentEntry;
  }

  /// Reads the simulation-result error message, falling back to the JSON-RPC
  /// transport error when the result itself is absent.
  ///
  /// `SimulateTransactionResponse` carries two distinct error fields:
  ///
  /// - `resultError`: the simulation's own error string, populated when the
  ///   RPC call succeeded at the transport level but the contract execution
  ///   inside the simulation returned an error. With debug-enabled RPC
  ///   servers this string contains the full host-error text and the
  ///   diagnostic event log.
  /// - `error`: the JSON-RPC transport error, populated only when the RPC
  ///   request itself failed (network, parse, generic JSON-RPC error).
  ///
  /// Checking only `error` would miss the simulation-result error and let the
  /// caller proceed to submission with a transaction whose signed auth
  /// entries do not pass enforcement.
  String? _simulationErrorMessage(SimulateTransactionResponse simulation) {
    final resultError = simulation.resultError;
    if (resultError != null && resultError.isNotEmpty) {
      return resultError;
    }
    final rpcError = simulation.error;
    final rpcMessage = rpcError?.message;
    if (rpcMessage != null && rpcMessage.isNotEmpty) {
      return rpcMessage;
    }
    return null;
  }

  void _validateContractCallArgs(
    String target,
    String targetFn,
    List<SelectedSigner> selectedSigners,
  ) {
    requireContractAddress(target, fieldName: 'target');

    if (targetFn.trim().isEmpty) {
      throw ValidationException.invalidInput(
        'targetFn',
        'Function name cannot be empty',
      );
    }

    if (selectedSigners.isEmpty) {
      throw ValidationException.invalidInput(
        'selectedSigners',
        'At least one signer must be provided',
      );
    }
  }

  Future<XdrSorobanAuthorizationEntry> _signWalletAddressAuthEntry({
    required XdrSorobanAuthorizationEntry entry,
    required SelectedSignerWallet walletSigner,
    required int expirationLedger,
  }) async {
    final externalWallet = _kit.externalWallet!;

    final signedEntry = _cloneEntryWithExpiration(entry, expirationLedger);

    final credentials = signedEntry.credentials.address;
    if (credentials == null) {
      throw TransactionException.signingFailed(
        'Expected Address credentials on wallet auth entry for '
        '${walletSigner.address}',
      );
    }

    final networkId = _sha256(utf8.encode(_kit.config.networkPassphrase));

    final authPreimage = XdrHashIDPreimageSorobanAuthorization(
      XdrHash(networkId),
      credentials.nonce,
      credentials.signatureExpirationLedger,
      signedEntry.rootInvocation,
    );
    final preimage = XdrHashIDPreimage(
      XdrEnvelopeType.ENVELOPE_TYPE_SOROBAN_AUTHORIZATION,
    )..sorobanAuthorization = authPreimage;

    final stream = XdrDataOutputStream();
    XdrHashIDPreimage.encode(stream, preimage);
    final preimageXdr = base64Encode(stream.bytes);

    final SignAuthEntryResult signResult;
    try {
      signResult = await externalWallet.signAuthEntry(
        preimageXdr,
        options: SignAuthEntryOptions(
          networkPassphrase: _kit.config.networkPassphrase,
          address: walletSigner.address,
        ),
      );
    } catch (e) {
      throw TransactionException.signingFailed(
        'External wallet signing failed for ${walletSigner.address}: $e',
        cause: e,
      );
    }

    final signatureBytes = base64Decode(signResult.signedAuthEntry);

    final publicKeyBytes =
        KeyPair.fromAccountId(walletSigner.address).publicKey;

    final sigMap = <XdrSCMapEntry>[
      XdrSCMapEntry(
        XdrSCVal.forSymbol('public_key'),
        XdrSCVal.forBytes(publicKeyBytes),
      ),
      XdrSCMapEntry(
        XdrSCVal.forSymbol('signature'),
        XdrSCVal.forBytes(Uint8List.fromList(signatureBytes)),
      ),
    ];
    final signatureScVal = XdrSCVal.forVec(<XdrSCVal>[
      XdrSCVal.forMap(sigMap),
    ]);

    final updatedCredentials = XdrSorobanAddressCredentials(
      credentials.address,
      credentials.nonce,
      credentials.signatureExpirationLedger,
      signatureScVal,
    );

    return XdrSorobanAuthorizationEntry(
      XdrSorobanCredentials.forAddressCredentials(updatedCredentials),
      signedEntry.rootInvocation,
    );
  }

  XdrSorobanAuthorizationEntry _cloneEntryWithExpiration(
    XdrSorobanAuthorizationEntry entry,
    int expirationLedger,
  ) {
    final stream = XdrDataOutputStream();
    XdrSorobanAuthorizationEntry.encode(stream, entry);
    final cloned = XdrSorobanAuthorizationEntry.decode(
      XdrDataInputStream(Uint8List.fromList(stream.bytes)),
    );

    final credentials = cloned.credentials.address;
    if (credentials == null) return cloned;

    final updated = XdrSorobanAddressCredentials(
      credentials.address,
      credentials.nonce,
      XdrUint32(expirationLedger),
      credentials.signature,
    );

    return XdrSorobanAuthorizationEntry(
      XdrSorobanCredentials.forAddressCredentials(updated),
      cloned.rootInvocation,
    );
  }

  Future<XdrSorobanAuthorizationEntry> _authorizeInvocation({
    required String publicKey,
    required int validUntilLedgerSeq,
    required XdrSorobanAuthorizedInvocation invocation,
    required Future<_AuthSignature> Function(XdrHashIDPreimage preimage) signer,
  }) async {
    final nonce = _generateNonce();

    final networkId = _sha256(utf8.encode(_kit.config.networkPassphrase));

    final authPreimage = XdrHashIDPreimageSorobanAuthorization(
      XdrHash(networkId),
      nonce,
      XdrUint32(validUntilLedgerSeq),
      invocation,
    );
    final preimage = XdrHashIDPreimage(
      XdrEnvelopeType.ENVELOPE_TYPE_SOROBAN_AUTHORIZATION,
    )..sorobanAuthorization = authPreimage;

    final result = await signer(preimage);

    final pubKeyBytes = KeyPair.fromAccountId(result.publicKey).publicKey;

    final sigMap = <XdrSCMapEntry>[
      XdrSCMapEntry(
        XdrSCVal.forSymbol('public_key'),
        XdrSCVal.forBytes(pubKeyBytes),
      ),
      XdrSCMapEntry(
        XdrSCVal.forSymbol('signature'),
        XdrSCVal.forBytes(result.signature),
      ),
    ];
    final signatureScVal = XdrSCVal.forVec(<XdrSCVal>[
      XdrSCVal.forMap(sigMap),
    ]);

    final credentials = XdrSorobanAddressCredentials(
      Address.forAccountId(publicKey).toXdr(),
      nonce,
      XdrUint32(validUntilLedgerSeq),
      signatureScVal,
    );

    return XdrSorobanAuthorizationEntry(
      XdrSorobanCredentials.forAddressCredentials(credentials),
      invocation,
    );
  }

  /// Generates an 8-byte cryptographically-random Soroban
  /// address-credentials nonce.
  ///
  /// Delegated to [OZSecureNonce.generate] so this manager and the
  /// single-signer transaction pipeline draw nonces from the exact same
  /// generator; see [OZSecureNonce] for the implementation rationale
  /// (in particular, why the work happens through [BigInt] rather than
  /// native `int` arithmetic).
  @visibleForTesting
  XdrInt64 generateNonceForTest() => _generateNonce();

  XdrInt64 _generateNonce() => OZSecureNonce.generate();

  Uint8List _sha256(List<int> data) =>
      Uint8List.fromList(crypto.sha256.convert(data).bytes);

  Future<Account> _fetchAccount(String accountId) async {
    final account = await _kit.sorobanServer.getAccount(accountId);
    if (account == null) {
      throw TransactionException.submissionFailed(
        'Failed to fetch deployer account $accountId',
      );
    }
    return account;
  }

  XdrSCVal _addressScVal(String address) {
    if (StrKey.isValidContractId(address)) {
      return XdrSCVal.forAddress(Address.forContractId(address).toXdr());
    }
    return XdrSCVal.forAddress(Address.forAccountId(address).toXdr());
  }

  String? _addressToString(XdrSCAddress addressXdr) =>
      OZAddressStrKey.fromXdr(addressXdr);
}

class _AuthSignature {
  const _AuthSignature({required this.publicKey, required this.signature});
  final String publicKey;
  final Uint8List signature;
}
