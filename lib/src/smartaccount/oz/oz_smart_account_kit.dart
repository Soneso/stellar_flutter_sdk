// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../../key_pair.dart';
import '../../soroban/soroban_server.dart';
import '../core/smart_account_errors.dart';
import 'oz_constants.dart';
import 'oz_context_rule_manager.dart';
import 'oz_credential_manager.dart';
import 'oz_external_signer_manager.dart';
import 'oz_indexer_client.dart';
import 'oz_internal_pipeline_interfaces.dart';
import 'oz_multi_signer_manager.dart';
import 'oz_policy_manager.dart';
import 'oz_relayer_client.dart';
import 'oz_signer_manager.dart';
import 'oz_smart_account_config.dart';
import 'oz_smart_account_events.dart';
import 'oz_storage_adapter.dart';
import 'oz_transaction_operations.dart';
import 'oz_wallet_operations.dart';

/// Top-level entry point for OpenZeppelin smart-account operations on
/// Stellar / Soroban.
///
/// [OZSmartAccountKit] owns the lifetime of the underlying [SorobanServer],
/// optional [OZIndexerClient] and [OZRelayerClient] HTTP clients, and exposes
/// eight manager objects that cover the smart-account feature set. Seven are
/// instantiated lazily by the kit; the eighth ([externalSigners]) is
/// constructed by the kit from the supplied configuration:
///
/// - [walletOperations] — create / connect / disconnect wallet lifecycle.
/// - [transactionOperations] — host-function build, sign, and submit.
/// - [signerManager] — passkey / delegated / ed25519 signer management.
/// - [policyManager] — installable signature policies.
/// - [contextRuleManager] — context rules linking signers + policies.
/// - [credentialManager] — local credential persistence and lifecycle.
/// - [multiSignerManager] — multi-signer authorisation flow.
/// - [externalSigners] — unified external-signer manager, kit-constructed
///   from [OZSmartAccountConfig.externalWallet] and
///   [OZSmartAccountConfig.externalEd25519Adapter]. Non-null; available
///   immediately after kit construction.
///
/// Construction is via the static [create] factory so the configuration
/// invariants are validated once by [OZSmartAccountConfig] before the kit
/// allocates any resources. The constructor itself is library-private.
///
/// All manager properties return the same instance for the lifetime of the kit.
///
/// Thread safety: writes that interleave with an `await` are serialised
/// through [_withLock] so that `disconnect()`, `setConnectedState()`, and
/// `close()` cannot race against each other. The kit is safe for concurrent
/// access on the main isolate; do not call across isolates without explicit
/// handoff.
///
/// Example:
/// ```dart
/// final config = OZSmartAccountConfig(
///   rpcUrl: 'https://soroban-testnet.stellar.org',
///   networkPassphrase: Network.TESTNET.networkPassphrase,
///   accountWasmHash: '...',
///   webauthnVerifierAddress: 'C...',
///   relayerUrl: 'https://relayer.example.com',
/// );
/// final kit = OZSmartAccountKit.create(config: config);
/// try {
///   final wallet = await kit.walletOperations.createWallet(userName: 'me');
///   // use kit.signerManager / kit.policyManager / ...
/// } finally {
///   await kit.close();
/// }
/// ```
class OZSmartAccountKit implements OZSmartAccountWalletKitInterface {
  OZSmartAccountKit._({
    required this.config,
    required StorageAdapter storage,
    required this.relayerClient,
    required this.indexerClient,
    required OZExternalSignerManager externalSigners,
    required this.sorobanServer,
  })  : _storage = storage,
        _externalSigners = externalSigners;

  /// Test-only constructor; production consumers use [create].
  @visibleForTesting
  OZSmartAccountKit.forTesting({
    required OZSmartAccountConfig config,
    required StorageAdapter storage,
    required OZRelayerClient? relayerClient,
    required OZIndexerClient? indexerClient,
    required OZExternalSignerManager externalSigners,
    required SorobanServer sorobanServer,
  }) : this._(
          config: config,
          storage: storage,
          relayerClient: relayerClient,
          indexerClient: indexerClient,
          externalSigners: externalSigners,
          sorobanServer: sorobanServer,
        );

  // Configuration and held resources

  /// The configuration that defines network endpoints, contract
  /// addresses, and operational parameters in effect on this kit.
  @override
  final OZSmartAccountConfig config;

  /// Optional fee-sponsored relayer client. `null` when
  /// [OZSmartAccountConfig.relayerUrl] is unset on [config].
  @override
  final OZRelayerClient? relayerClient;

  /// Optional credential-to-contract indexer client. `null` when the
  /// configuration has no explicit [OZSmartAccountConfig.indexerUrl] and
  /// no network-default URL exists for the configured passphrase.
  @override
  final OZIndexerClient? indexerClient;

  /// Shared [SorobanServer] used by every manager for RPC simulation,
  /// submission, and on-chain lookups. Released by [close].
  @override
  final SorobanServer sorobanServer;

  /// Storage adapter held privately and surfaced through [getStorage].
  /// Lifetime is bound to the kit; the adapter is supplied by [config].
  final StorageAdapter _storage;

  /// Kit-owned external-signer manager constructed from the supplied
  /// configuration. Non-null; exposed through [externalSigners].
  final OZExternalSignerManager _externalSigners;

  // Event emitter

  /// Event emitter shared by every manager. Subscribers receive
  /// lifecycle notifications (wallet connected / disconnected, credential
  /// created / deleted, transaction signed / submitted, etc.).
  @override
  final SmartAccountEventEmitter events = SmartAccountEventEmitter();

  // Managers (lazy, identity-preserving)

  /// Wallet-lifecycle operations (create, connect, disconnect, deploy).
  late final OZWalletOperations walletOperations = OZWalletOperations(this);

  /// Transaction-pipeline operations (host function build, simulate, sign, submit, fund).
  @override
  late final OZTransactionOperations transactionOperations =
      OZTransactionOperations(this);

  /// Signer management (passkey, delegated, Ed25519 signers).
  late final OZSignerManager signerManager = OZSignerManager(this);

  /// Context-rule management (rules linking signers and policies).
  @override
  late final OZContextRuleManager contextRuleManager =
      OZContextRuleManager(this);

  /// Policy management (installable signature policies).
  late final OZPolicyManager policyManager = OZPolicyManager(this);

  /// Credential management (local credential persistence and lifecycle).
  @override
  late final OZCredentialManager credentialManager = OZCredentialManager(this);

  /// Multi-signer authorisation flow.
  @override
  late final OZMultiSignerManager multiSignerManager =
      OZMultiSignerManager(this);

  /// The unified external-signer manager, constructed by the kit from the
  /// supplied configuration. Provides in-memory keypair registration and
  /// adapter-backed signing for both G-address wallet signers and Ed25519
  /// external signers.
  ///
  /// Supply [OZSmartAccountConfig.externalWallet] and / or
  /// [OZSmartAccountConfig.externalEd25519Adapter] at kit construction to
  /// enable adapter-backed signing. Register in-memory keys at runtime via
  /// [OZExternalSignerManager.addFromSecret] (wallet) and
  /// [OZExternalSignerManager.addEd25519FromRawKey] (Ed25519).
  @override
  OZExternalSignerManager get externalSigners => _externalSigners;

  // Connection state

  /// Connected credential ID. Mutated through [_withLock] so the change
  /// cannot interleave against a concurrent [disconnect] or [close].
  String? _credentialId;

  /// Connected smart-account contract address. Mutated through
  /// [_withLock] so the change cannot interleave against a concurrent
  /// [disconnect] or [close].
  String? _contractId;

  /// Whether [close] has run. Idempotency guard for repeated [close]
  /// invocations and a sentinel that [disconnect] honours after teardown.
  /// The transition from `false` to `true` is performed inside [_withLock]
  /// so any concurrent caller observing `_closed == false` before the
  /// lock-acquire will re-check after acquiring the lock and abort
  /// cleanly when the kit is being torn down.
  bool _closed = false;

  /// Cached deployer keypair. Intentionally unsynchronised — the derivation
  /// is deterministic, so concurrent first-callers each compute the same
  /// keypair and the race window collapses after the first cache write.
  KeyPair? _cachedDeployer;

  /// FIFO async-lock tail. Mutations against [_credentialId],
  /// [_contractId], and [_closed] that interleave with `await` go through
  /// [_withLock] so the pre-await read and the post-await write cannot
  /// be interleaved by a sibling caller.
  Future<void> _tail = Future<void>.value();

  /// Whether a wallet is currently connected.
  ///
  /// Returns `true` when both the credential ID and contract ID are
  /// non-null. Reflects in-memory state only; after an app restart a
  /// previously-saved session must be restored via
  /// [OZWalletOperations.connectWallet] before [isConnected] reads as
  /// `true` again.
  bool get isConnected => _credentialId != null && _contractId != null;

  /// Connected credential ID (Base64URL-encoded, no padding), or `null` when no wallet is connected.
  String? get credentialId => _credentialId;

  /// Connected smart-account contract address (C-address), or `null`
  /// when no wallet is connected.
  @override
  String? get contractId => _contractId;

  // Connection management

  /// Updates the connected state to the supplied [credentialId] /
  /// [contractId] pair.
  ///
  /// Called by [walletOperations] after wallet creation and after a
  /// successful connect or reconnect. The write is routed through
  /// [_withLock] so it cannot interleave against a concurrent
  /// [disconnect] or [close]. Both scalar field writes are performed
  /// inside the same lock acquisition so observers always see a
  /// coherent (`credentialId`, `contractId`) pair.
  @override
  Future<void> setConnectedState({
    required String credentialId,
    required String contractId,
  }) async {
    await _withLock<void>(() {
      _credentialId = credentialId;
      _contractId = contractId;
    });
  }

  /// Returns the connected credential ID and contract address, or throws
  /// [WalletNotConnected] when no wallet is connected.
  @override
  Future<OZConnectedState> requireConnected() async {
    return _withLock<OZConnectedState>(() {
      final cId = _credentialId;
      final ctId = _contractId;
      if (cId == null || ctId == null) {
        throw WalletException.notConnected(
          details:
              'No wallet connected. Call createWallet() or connectWallet() first.',
        );
      }
      return OZConnectedState(credentialId: cId, contractId: ctId);
    });
  }

  /// Disconnects the currently-connected wallet.
  ///
  /// Clears the in-memory connection state, removes the persisted
  /// session via [StorageAdapter.clearSession], and emits a
  /// [SmartAccountEventWalletDisconnected] event when a wallet was
  /// connected at the time of the call. The stored credential entries
  /// remain in storage and can be reconnected later via
  /// [OZWalletOperations.connectWallet].
  ///
  /// Safe to call when no wallet is connected; the call is a no-op aside
  /// from the storage-clear request. After [close] has run this method
  /// returns without touching the kit's resources. The close-state check
  /// is repeated inside [_withLock] so a caller that observed
  /// `_closed == false` before queueing but reaches the front of the
  /// lock queue after [close] has flipped the flag still aborts cleanly
  /// instead of mutating a torn-down kit.
  Future<void> disconnect() async {
    if (_closed) {
      return;
    }
    final String? capturedContractId = await _withLock<String?>(() {
      if (_closed) {
        return null;
      }
      final current = _contractId;
      _credentialId = null;
      _contractId = null;
      return current;
    });

    // why: storage I/O runs outside the lock so a slow adapter cannot
    // starve concurrent state reads on the kit. Errors propagate up to
    // the caller — clearing the session is best-effort but observable.
    await _storage.clearSession();

    if (capturedContractId != null) {
      events.emit(
        SmartAccountEventWalletDisconnected(contractId: capturedContractId),
      );
    }
  }

  // Resource management

  /// Releases every held HTTP-client resource and removes every
  /// registered event listener.
  ///
  /// Closes the shared [sorobanServer] transport first, then the optional
  /// [indexerClient] and [relayerClient] HTTP clients, and finally tears
  /// down the kit's [events] subscriptions. The Soroban RPC client is
  /// released first because every manager funnels through it; the
  /// auxiliary HTTP clients are torn down afterwards. Idempotent — a
  /// second invocation is a no-op. Storage and the connection state are
  /// not touched; call [disconnect] first when ending an active session.
  ///
  /// The kit is not usable for new operations after [close] returns. The
  /// `_closed` flag is set inside [_withLock] so concurrent callers of
  /// [setConnectedState] / [disconnect] that re-check `_closed` after
  /// acquiring the lock observe the closed state and abort cleanly
  /// instead of mutating a torn-down kit.
  ///
  Future<void> close() async {
    await _withLock<void>(() async {
      if (_closed) {
        return;
      }
      _closed = true;
      // why: the Soroban RPC transport is released first because every
      // manager pipes through it, after which the auxiliary HTTP clients
      // can be safely torn down. The listener teardown runs inside the
      // same critical section so a concurrent disconnect either fires
      // its event before the listeners disappear or aborts via the
      // re-checked `_closed` flag.
      sorobanServer.close();
      await indexerClient?.close();
      await relayerClient?.close();
      events.removeAllListeners();
    });
  }

  // Internal helpers

  /// Returns the deployer keypair, resolving to the deterministic
  /// default when [OZSmartAccountConfig.deployerKeypair] is unset.
  ///
  /// The first call resolves the deployer via
  /// [OZSmartAccountConfig.effectiveDeployer] and caches the result.
  /// Subsequent calls return the cached keypair. The cache is not
  /// synchronised; concurrent first-callers may each call
  /// [OZSmartAccountConfig.effectiveDeployer] but the derivation is
  /// deterministic so the redundant work is functionally idempotent.
  @override
  Future<KeyPair> getDeployer() async {
    final cached = _cachedDeployer;
    if (cached != null) {
      return cached;
    }
    final deployer = await config.effectiveDeployer();
    _cachedDeployer = deployer;
    return deployer;
  }

  /// Returns the storage adapter currently in use by the kit.
  ///
  /// Operations modules reach storage through this accessor so the kit
  /// remains the single owner of the adapter reference.
  @override
  StorageAdapter getStorage() => _storage;

  /// Serialises an async [body] against the kit's state-mutation tail.
  ///
  /// The lock is a Future-chain FIFO: each invocation chains its work onto the
  /// previous tail. The cleanup step resets [_tail] to a fresh resolved future
  /// so newly arriving callers do not hold onto every prior completion.
  ///
  /// Errors raised inside [body] propagate to the returned future. The cleanup
  /// step runs regardless of success or failure and does not spawn an orphan
  /// future that could surface as an unhandled-future error in the zone.
  Future<T> _withLock<T>(FutureOr<T> Function() body) {
    final completer = Completer<T>();
    final previous = _tail;
    late final Future<void> next;
    next = previous.then((_) async {
      try {
        final value = await body();
        completer.complete(value);
      } catch (e, st) {
        completer.completeError(e, st);
      } finally {
        // why: collapse the tail only when no later caller has chained
        // onto this slot yet. Performed inside the same `then` body so
        // we do not register a second observer of `completer.future`
        // (which would otherwise leak the error as an unhandled async
        // error when the body throws).
        if (identical(_tail, next)) {
          _tail = Future<void>.value();
        }
      }
    });
    _tail = next;
    return completer.future;
  }

  // Static factory

  /// Creates a new [OZSmartAccountKit] instance.
  ///
  /// Construction is total — every required input has already been
  /// validated by the [OZSmartAccountConfig] constructor so this factory
  /// performs no additional invariant checks. Constructs a [SorobanServer],
  /// and conditionally an [OZRelayerClient] and [OZIndexerClient], according
  /// to the supplied [config]. No network requests are made; wallet sessions
  /// stored from a previous run are restored via
  /// [OZWalletOperations.connectWallet].
  static OZSmartAccountKit create({required OZSmartAccountConfig config}) {
    final relayerUrl = config.relayerUrl;
    final OZRelayerClient? relayerClient = relayerUrl == null
        ? null
        : OZRelayerClient(
            relayerUrl,
            timeout: const Duration(
              milliseconds: OZConstants.defaultRelayerTimeoutMs,
            ),
          );

    final indexerUrl = config.effectiveIndexerUrl();
    final OZIndexerClient? indexerClient = indexerUrl == null
        ? null
        : OZIndexerClient(
            indexerUrl,
            timeout: const Duration(
              milliseconds: OZConstants.defaultIndexerTimeoutMs,
            ),
          );

    final externalSigners = OZExternalSignerManager(
      networkPassphrase: config.networkPassphrase,
      walletAdapter: config.externalWallet,
      walletConnectionStorage: null,
      ed25519Adapter: config.externalEd25519Adapter,
    );

    return OZSmartAccountKit._(
      config: config,
      storage: config.storage,
      relayerClient: relayerClient,
      indexerClient: indexerClient,
      externalSigners: externalSigners,
      sorobanServer: SorobanServer(config.rpcUrl),
    );
  }
}
