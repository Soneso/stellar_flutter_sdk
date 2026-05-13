// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../../key_pair.dart';
import '../../soroban/soroban_server.dart';
import '../../xdr/xdr.dart';
import 'oz_builders.dart';
import 'oz_indexer_client.dart';
import 'oz_relayer_client.dart';
import 'oz_selected_signer.dart';
import 'oz_smart_account_config.dart';
import 'oz_smart_account_events.dart';
import 'oz_smart_account_types.dart';
import 'oz_storage_adapter.dart';
import 'oz_transaction_operations.dart';

// ---------------------------------------------------------------------------
// Internal interfaces shared by the operations classes.
//
// This file is intentionally NOT re-exported by the public barrel
// `lib/stellar_flutter_sdk.dart`. It is imported privately from
// `oz_transaction_operations.dart` and `oz_wallet_operations.dart`, and
// reachable from test code via deep `src/` imports. Production consumers
// of the SDK never need these symbols — they are pipeline-internal
// abstractions used only to support test doubles and inversion of
// dependencies between the operations layer and the kit layer.
// ---------------------------------------------------------------------------

/// Internal abstraction over the credential store the transaction pipeline
/// reaches through. Concrete implementations are supplied by the wallet
/// lifecycle layer; this interface keeps the transaction operations
/// independent of any one credential-management implementation.
///
/// The contract intentionally exposes only the methods the transaction
/// pipeline calls; tests can satisfy it with a minimal stub.
@internal
abstract class OZCredentialManagerInterface {
  /// Looks up a stored credential by its Base64URL-encoded ID, returning
  /// `null` when no entry exists.
  Future<StoredCredential?> getCredential(String credentialId);

  /// Updates the `lastUsedAt` timestamp on the stored credential, if present.
  Future<void> updateLastUsed(String credentialId);
}

/// Internal abstraction over the context-rule manager the transaction
/// pipeline reaches through. Concrete implementations are supplied by the
/// context-rule manager layer.
@internal
abstract class OZContextRuleManagerInterface {
  /// Returns the parsed list of all context rules currently active on the
  /// connected smart account.
  Future<List<Object>> listContextRules();

  /// Resolves the context rule IDs that apply to the given auth entry under
  /// the supplied signers and pre-fetched context rules. Implementations
  /// must accept the [contextRules] returned by [listContextRules].
  Future<List<int>> resolveContextRuleIdsForEntry(
    XdrSorobanAuthorizationEntry entry,
    List<OZSmartAccountSigner> signers,
    List<Object> contextRules,
  );

  /// Returns the raw on-chain `ScVal` representations of every active
  /// context rule, used to discover external-signer key data when local
  /// storage does not have the credential.
  Future<List<XdrSCVal>> getAllContextRules();

  /// Returns the raw on-chain `ScVal` representation of a single rule
  /// identified by [id]. Sibling managers (signer manager, policy manager)
  /// use this together with [parseContextRule] to translate a value-form
  /// signer or policy lookup into the on-chain numeric ID before issuing
  /// the matching `remove_signer` / `remove_policy` invocation.
  Future<XdrSCVal> getContextRule(int id);

  /// Parses a raw context-rule `ScVal` into a [ParsedContextRule]
  /// instance. Exposed via the interface (rather than a class-level
  /// method) so the sibling managers can drive the parser through the
  /// kit's `contextRuleManager` accessor.
  ParsedContextRule parseContextRule(XdrSCVal scVal);
}

/// Internal abstraction over the multi-signer manager the
/// state-changing managers route through when the caller supplies a
/// non-empty `selectedSigners` list.
///
/// Sibling managers (signer, policy, context-rule) call
/// [submitWithMultipleSigners] through this interface so they avoid
/// the circular import between the concrete `OZMultiSignerManager` and
/// the kit interface that exposes it. The interface declares only the
/// surface the routing helpers need; the multi-signer manager retains
/// its richer typed API for direct consumer use.
@internal
abstract class OZMultiSignerManagerInterface {
  /// Submits [hostFunction] under the [selectedSigners] list, returning
  /// the same [TransactionResult] the concrete manager would yield. The
  /// optional [forceMethod] mirrors the named parameter on the concrete
  /// implementation and forces submission via RPC or relayer respectively
  /// instead of letting the SDK pick automatically.
  Future<TransactionResult> submitWithMultipleSigners({
    required XdrHostFunction hostFunction,
    required List<SelectedSigner> selectedSigners,
    SubmissionMethod? forceMethod,
  });
}

/// Connected-wallet state. Carries the Base64URL credential ID and the
/// smart-account contract address resolved during connection.
class OZConnectedState {
  /// Constructs a connected state record.
  const OZConnectedState({
    required this.credentialId,
    required this.contractId,
  });

  /// Base64URL-encoded WebAuthn credential ID.
  final String credentialId;

  /// Smart-account contract address (C-address).
  final String contractId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OZConnectedState) return false;
    return credentialId == other.credentialId &&
        contractId == other.contractId;
  }

  @override
  int get hashCode => Object.hash(credentialId, contractId);
}

/// Internal interface the transaction and wallet operations expect their
/// owning kit to satisfy. Concrete implementations are supplied by the
/// smart-account kit layer; this interface keeps the operations classes
/// independent of any one kit implementation and supports test doubles.
///
/// The contract intentionally exposes only the surface the operations call;
/// tests can satisfy it with a minimal stub.
@internal
abstract class OZSmartAccountKitInterface {
  /// The configuration in effect on this kit.
  OZSmartAccountConfig get config;

  /// Soroban RPC client used for simulation, submission, and lookups.
  SorobanServer get sorobanServer;

  /// Event emitter for lifecycle notifications. Operations emit signing,
  /// submission, and connection events through this emitter.
  SmartAccountEventEmitter get events;

  /// Indexer client, when configured. `null` when the kit has no indexer.
  OZIndexerClient? get indexerClient;

  /// Relayer client, when configured. `null` when the kit has no relayer.
  OZRelayerClient? get relayerClient;

  /// Credential manager exposed for transaction-pipeline use.
  OZCredentialManagerInterface get credentialManager;

  /// Context-rule manager exposed for transaction-pipeline use.
  OZContextRuleManagerInterface get contextRuleManager;

  /// Returns the deployer keypair. Asynchronous because the default deployer
  /// is derived from a fixed seed.
  Future<KeyPair> getDeployer();

  /// Returns the storage adapter currently in use by the kit.
  StorageAdapter getStorage();

  /// Returns the active connected state, throwing [WalletNotConnected] when
  /// no wallet is connected.
  ///
  /// Implementations route the paired read of credential ID + contract ID
  /// through their state-mutation lock so callers always observe a coherent
  /// snapshot relative to [setConnectedState] / `disconnect` / `close`.
  Future<OZConnectedState> requireConnected();

  /// Sets the kit's connected state to the supplied credential and contract.
  ///
  /// Implementations route both scalar field writes through their
  /// state-mutation lock so concurrent [requireConnected] / `disconnect` /
  /// `close` calls observe a coherent (credentialId, contractId) pair.
  Future<void> setConnectedState({
    required String credentialId,
    required String contractId,
  });

  /// The currently connected smart-account contract address, or `null`
  /// when no wallet is connected. Distinct from [requireConnected]: the
  /// throwing path is for state-changing flows that cannot proceed
  /// unconnected; this nullable accessor supports query methods that
  /// gracefully degrade to an empty result when no wallet is bound to
  /// the kit.
  String? get contractId;

  /// The external wallet adapter currently configured on the kit, or
  /// `null` when no adapter is set. Consumed by the multi-signer
  /// pipeline for delegated wallet signers.
  ExternalWalletAdapter? get externalWallet;

  /// The multi-signer manager handle exposed through the kit
  /// interface. Typed as [Object] to avoid a circular import between
  /// the pipeline interfaces and the concrete manager classes; cast to
  /// the concrete `OZMultiSignerManager` (or to
  /// [OZMultiSignerManagerInterface] for pipeline-internal use) when
  /// the call site needs the typed surface.
  Object get multiSignerManager;
}

/// Internal abstraction over the credential-store mutations the wallet
/// lifecycle reaches through. Concrete implementations are supplied by the
/// credential-manager layer.
@internal
abstract class OZWalletCredentialManagerInterface
    implements OZCredentialManagerInterface {
  /// Persists a freshly-registered credential in `pending` status with the
  /// supplied metadata.
  Future<StoredCredential> createPendingCredential({
    required String credentialId,
    required Uint8List publicKey,
    required String contractId,
    String? nickname,
    List<String>? transports,
    String? deviceType,
    bool? backedUp,
  });

  /// Marks the credential's deployment status as `failed` with the supplied
  /// error message.
  Future<void> markDeploymentFailed({
    required String credentialId,
    required String error,
  });

  /// Marks the credential as the primary credential for its contract.
  Future<void> setPrimary(String credentialId);

  /// Deletes a credential from local storage, no-oping when no entry exists.
  Future<void> deleteCredential({required String credentialId});
}

/// Interface the wallet operations expect the owning kit to satisfy.
/// Extends the transaction-pipeline interface with the wallet-lifecycle
/// methods specific to wallet creation, connection, and deployment.
@internal
abstract class OZSmartAccountWalletKitInterface
    implements OZSmartAccountKitInterface {
  /// Credential manager with full lifecycle write access.
  @override
  OZWalletCredentialManagerInterface get credentialManager;

  /// Transaction operations exposed for autoFund flows in createWallet and
  /// deployPendingCredential.
  OZTransactionOperations get transactionOperations;
}
