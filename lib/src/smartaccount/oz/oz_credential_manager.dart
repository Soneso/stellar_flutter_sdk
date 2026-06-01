// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../../xdr/xdr.dart';
import '../core/smart_account_constants.dart';
import '../core/smart_account_errors.dart';
import 'oz_internal_pipeline_interfaces.dart';
import 'oz_smart_account_events.dart';
import 'oz_storage_adapter.dart';

/// Manages the lifecycle of OpenZeppelin smart-account credentials.
///
/// Provides operations for creating, querying, updating, and deleting stored
/// passkey credentials. Handles credential deployment-state transitions and
/// integrity through validation and error handling.
///
/// Credential state machine:
///
/// - `pending` -> deploy success -> credential DELETED from storage
/// - `pending` -> deploy failure -> `failed` (with `deploymentError` set)
/// - `pending` -> sync discovers contract on-chain -> credential DELETED
/// - `failed` -> [deleteCredential] -> credential DELETED from storage
///
/// After a successful deployment (or sync discovery) the credential is
/// removed from storage. Reconnection is handled via sessions or the
/// indexer. Failed deployments can be retried by deleting the credential
/// and creating a new one.
///
/// Thread safety: every operation delegates to the [StorageAdapter], which
/// is responsible for serialising concurrent calls.
///
/// Example:
/// ```dart
/// final manager = kit.credentialManager;
///
/// final all = await manager.getAllCredentials();
/// final pending = await manager.getPendingCredentials();
///
/// final isDeployed = await manager.sync('base64url-id');
/// await manager.deleteCredential('base64url-id');
/// ```
class OZCredentialManager
    implements OZWalletCredentialManagerInterface {
  /// Constructs a credential manager bound to the supplied kit. Marked
  /// [internal] because consumers should reach the manager via
  /// `kit.credentialManager` rather than instantiating one directly.
  @internal
  OZCredentialManager(this._kit);

  final OZSmartAccountKitInterface _kit;

  StorageAdapter get _storage => _kit.getStorage();

  /// Creates a new pending credential in storage.
  ///
  /// The credential is created with `deploymentStatus = pending`,
  /// `isPrimary = false`, and `createdAt = currentTimeMillis`.
  ///
  /// Validation:
  ///
  /// - [publicKey] must be exactly 65 bytes (uncompressed secp256r1 format).
  /// - [credentialId] must not be empty.
  /// - [credentialId] must be unique (no existing credential with same ID).
  ///
  /// Throws [InvalidInput] when validation fails,
  /// [CredentialAlreadyExists] when a credential with the same ID exists,
  /// and [StorageWriteFailed] when persistence fails.
  @override
  Future<StoredCredential> createPendingCredential({
    required String credentialId,
    required Uint8List publicKey,
    required String contractId,
    String? nickname,
    List<String>? transports,
    String? deviceType,
    bool? backedUp,
  }) async {
    if (publicKey.length != SmartAccountConstants.secp256r1PublicKeySize) {
      throw ValidationException.invalidInput(
        'publicKey',
        'Expected ${SmartAccountConstants.secp256r1PublicKeySize} bytes, '
            'got ${publicKey.length}',
      );
    }

    if (credentialId.isEmpty) {
      throw ValidationException.invalidInput(
        'credentialId',
        'Credential ID cannot be empty',
      );
    }

    final existing = await _storage.get(credentialId);
    if (existing != null) {
      throw CredentialException.alreadyExists(credentialId);
    }

    final credential = StoredCredential(
      credentialId: credentialId,
      publicKey: publicKey,
      contractId: contractId,
      deploymentStatus: CredentialDeploymentStatus.pending,
      isPrimary: false,
      nickname: nickname,
      transports: transports,
      deviceType: deviceType,
      backedUp: backedUp,
    );

    try {
      await _storage.save(credential);
    } on CredentialException {
      rethrow;
    } on StorageException {
      rethrow;
    } catch (e) {
      throw StorageException.writeFailed(credentialId, cause: e);
    }

    return credential;
  }

  /// Saves a credential to storage with looser semantics than
  /// [createPendingCredential].
  ///
  /// Persists the credential with `deploymentStatus = pending` and
  /// `isPrimary = false`. Unlike [createPendingCredential], deployment
  /// metadata fields ([transports], [deviceType], [backedUp]) are not
  /// retained, no duplicate check is performed, and any existing credential
  /// with the same ID is silently overwritten. A `null` [contractId] is
  /// stored as the empty string.
  ///
  /// Throws [InvalidInput] when [credentialId] is empty or [publicKey] is
  /// the wrong size, and [StorageWriteFailed] when persistence fails.
  Future<StoredCredential> saveCredential({
    required String credentialId,
    required Uint8List publicKey,
    String? nickname,
    String? contractId,
  }) async {
    if (credentialId.isEmpty) {
      throw ValidationException.invalidInput(
        'credentialId',
        'Credential ID cannot be empty',
      );
    }

    if (publicKey.length != SmartAccountConstants.secp256r1PublicKeySize) {
      throw ValidationException.invalidInput(
        'publicKey',
        'Expected ${SmartAccountConstants.secp256r1PublicKeySize} bytes, '
            'got ${publicKey.length}',
      );
    }

    final credential = StoredCredential(
      credentialId: credentialId,
      publicKey: publicKey,
      contractId: contractId ?? '',
      nickname: nickname,
      deploymentStatus: CredentialDeploymentStatus.pending,
    );

    try {
      await _storage.save(credential);
    } on StorageException {
      rethrow;
    } catch (e) {
      throw StorageException.writeFailed(credentialId, cause: e);
    }

    return credential;
  }

  /// Marks a credential as failed deployment.
  ///
  /// Updates the credential's deployment status to `failed` and records the
  /// supplied [error] message. Marked [internal] because failure marking is
  /// driven by the wallet-operations layer, not by consumer code.
  ///
  /// Throws [CredentialNotFound] when the credential does not exist and
  /// [StorageWriteFailed] when the update fails.
  @override
  @internal
  Future<void> markDeploymentFailed({
    required String credentialId,
    required String error,
  }) async {
    final existing = await _storage.get(credentialId);
    if (existing == null) {
      throw CredentialException.notFound(credentialId);
    }

    final update = StoredCredentialUpdate(
      deploymentStatus: CredentialDeploymentStatus.failed,
      deploymentError: error,
    );

    try {
      await _storage.update(credentialId, update);
    } on CredentialException {
      rethrow;
    } on StorageException {
      rethrow;
    } catch (e) {
      throw StorageException.writeFailed(credentialId, cause: e);
    }
  }

  /// Synchronises a credential with on-chain state.
  ///
  /// Checks whether the smart-account contract for this credential exists
  /// on-chain by querying the contract instance via Soroban RPC. When the
  /// contract is found the credential is removed from storage (deployment
  /// is confirmed) and `true` is returned. When the contract is missing or
  /// the on-chain check fails (network error, deletion failure, RPC error)
  /// the method returns `false`.
  ///
  /// The broad catch is intentional: transient RPC failures are reported
  /// as "not deployed" rather than surfacing a thrown exception that
  /// callers cannot recover from. The trade-off is a false negative on
  /// RPC outages. Swallowed exceptions are emitted as
  /// [SmartAccountEventCredentialSyncFailed] so consumers can observe
  /// transient failures without losing the documented stable-return
  /// contract.
  ///
  /// Throws [CredentialNotFound] when the credential does not exist in
  /// storage and [StorageReadFailed] when the read itself fails.
  Future<bool> sync(String credentialId) async {
    final StoredCredential? credential;
    try {
      credential = await _storage.get(credentialId);
    } on StorageException {
      rethrow;
    } catch (e) {
      throw StorageException.readFailed(credentialId, cause: e);
    }

    if (credential == null) {
      throw CredentialException.notFound(credentialId);
    }

    final contractAddress = credential.contractId;
    if (contractAddress == null || contractAddress.isEmpty) {
      return false;
    }

    try {
      final result = await _kit.sorobanServer.getContractData(
        contractAddress,
        XdrSCVal.forLedgerKeyContractInstance(),
        XdrContractDataDurability.PERSISTENT,
      );
      if (result != null) {
        await _storage.delete(credentialId);
        return true;
      }
      return false;
    } on Exception catch (e, stackTrace) {
      // why: narrowed from a bare catch so programmer errors still
      // propagate; transient failures are absorbed and surfaced via the
      // event emitter.
      _kit.events.emit(
        SmartAccountEventCredentialSyncFailed(
          credentialId: credentialId,
          error: e,
          stackTrace: stackTrace,
        ),
      );
      return false;
    }
  }

  /// Synchronises every stored credential with on-chain state.
  ///
  /// Iterates through all stored credentials, calling [sync] on each.
  /// Credentials confirmed as deployed are removed from storage by [sync].
  /// Returns a summary [SyncResult] tally.
  ///
  /// Throws [StorageReadFailed] when reading credentials fails.
  Future<SyncResult> syncAll() async {
    final List<StoredCredential> all;
    try {
      all = await _storage.getAll();
    } on StorageException {
      rethrow;
    } catch (e) {
      throw StorageException.readFailed('all', cause: e);
    }

    var deployed = 0;
    var pending = 0;
    var failed = 0;

    for (final credential in all) {
      bool exists;
      try {
        exists = await sync(credential.credentialId);
      } on CredentialException {
        // why: sync may have already removed the credential during this
        // loop iteration. Treat that as "not deployed" and move on.
        exists = false;
      }

      if (exists) {
        deployed++;
      } else if (credential.deploymentStatus ==
          CredentialDeploymentStatus.failed) {
        failed++;
      } else {
        pending++;
      }
    }

    return SyncResult(deployed: deployed, pending: pending, failed: failed);
  }

  /// Deletes a credential from storage with a defensive deploy guard.
  ///
  /// Calls [sync] first; when the contract is already deployed on-chain the
  /// deletion is rejected because the wallet exists on-chain. After
  /// successful deletion a [SmartAccountEventCredentialDeleted] event is
  /// emitted on the kit's event emitter.
  ///
  /// Throws [CredentialNotFound] when the credential is missing,
  /// [CredentialInvalid] when the credential is already deployed, and
  /// [StorageWriteFailed] when deletion fails.
  @override
  Future<void> deleteCredential({required String credentialId}) async {
    final StoredCredential? credential;
    try {
      credential = await _storage.get(credentialId);
    } on StorageException {
      rethrow;
    } catch (e) {
      throw StorageException.readFailed(credentialId, cause: e);
    }

    if (credential == null) {
      throw CredentialException.notFound(credentialId);
    }

    final isDeployed = await sync(credentialId);
    if (isDeployed) {
      throw CredentialException.invalid(
        'Cannot delete a deployed credential. The wallet exists on-chain.',
      );
    }

    try {
      await _storage.delete(credentialId);
    } on StorageException {
      rethrow;
    } catch (e) {
      throw StorageException.writeFailed(credentialId, cause: e);
    }

    _kit.events.emit(
      SmartAccountEventCredentialDeleted(credentialId: credentialId),
    );
  }

  /// Retrieves a credential by its ID.
  ///
  /// Returns `null` when no credential is stored under [credentialId].
  /// Throws [StorageReadFailed] when the read fails.
  @override
  Future<StoredCredential?> getCredential(String credentialId) async {
    try {
      return await _storage.get(credentialId);
    } on StorageException {
      rethrow;
    } catch (e) {
      throw StorageException.readFailed(credentialId, cause: e);
    }
  }

  /// Retrieves all credentials whose [StoredCredential.contractId] matches
  /// the supplied [contractId]. Returns an empty list when no credentials
  /// match. Throws [StorageReadFailed] when reading fails.
  Future<List<StoredCredential>> getCredentialsByContract(
    String contractId,
  ) async {
    try {
      return await _storage.getByContract(contractId);
    } on StorageException {
      rethrow;
    } catch (e) {
      throw StorageException.readFailed(
        'contract:$contractId',
        cause: e,
      );
    }
  }

  /// Retrieves all stored credentials regardless of deployment status or
  /// associated contract. Throws [StorageReadFailed] when reading fails.
  Future<List<StoredCredential>> getAllCredentials() async {
    try {
      return await _storage.getAll();
    } on StorageException {
      rethrow;
    } catch (e) {
      throw StorageException.readFailed('all', cause: e);
    }
  }

  /// Retrieves credentials for the currently connected wallet. Returns an
  /// empty list when no wallet is connected (rather than throwing) so
  /// consumer code can render a "no wallet" state without exception
  /// handling.
  Future<List<StoredCredential>> getForConnectedWallet() async {
    final contractId = _kit.contractId;
    if (contractId == null) return const <StoredCredential>[];
    return getCredentialsByContract(contractId);
  }

  /// Retrieves credentials whose deployment status is `pending` or
  /// `failed`, useful for surfacing wallets that still need attention
  /// (retry, sync, or delete).
  ///
  /// Throws [StorageReadFailed] when reading fails.
  Future<List<StoredCredential>> getPendingCredentials() async {
    final List<StoredCredential> all;
    try {
      all = await _storage.getAll();
    } on StorageException {
      rethrow;
    } catch (e) {
      throw StorageException.readFailed('all', cause: e);
    }

    return all
        .where(
          (c) =>
              c.deploymentStatus == CredentialDeploymentStatus.pending ||
              c.deploymentStatus == CredentialDeploymentStatus.failed,
        )
        .toList(growable: false);
  }

  /// Applies a partial [updates] specification to the credential under
  /// [credentialId]. Only non-null fields in [updates] are written.
  ///
  /// Marked [internal] because the broad update surface leaks
  /// implementation detail; consumers use the named partial-update methods
  /// such as [updateNickname] or the internal [updateLastUsed]/[setPrimary].
  ///
  /// Throws [CredentialNotFound] when the credential does not exist and
  /// [StorageWriteFailed] when the write fails.
  @internal
  Future<void> updateCredential(
    String credentialId,
    StoredCredentialUpdate updates,
  ) async {
    final existing = await _storage.get(credentialId);
    if (existing == null) {
      throw CredentialException.notFound(credentialId);
    }

    try {
      await _storage.update(credentialId, updates);
    } on CredentialException {
      rethrow;
    } on StorageException {
      rethrow;
    } catch (e) {
      throw StorageException.writeFailed(credentialId, cause: e);
    }
  }

  /// Updates the `lastUsedAt` timestamp on the stored credential when one
  /// exists. Internal because the timestamp is driven by the signing
  /// pipeline, not consumer code.
  @override
  @internal
  Future<void> updateLastUsed(String credentialId) async {
    final update = StoredCredentialUpdate(
      lastUsedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await updateCredential(credentialId, update);
  }

  /// Updates the nickname of an existing credential. Pass `null` to leave
  /// the nickname unchanged (the partial-update semantics of
  /// [StoredCredentialUpdate] do not allow clearing a value to null).
  ///
  /// Throws [CredentialNotFound] when the credential does not exist and
  /// [StorageWriteFailed] when the update fails.
  Future<void> updateNickname(String credentialId, String? nickname) async {
    final update = StoredCredentialUpdate(nickname: nickname);
    await updateCredential(credentialId, update);
  }

  /// Sets a credential as the primary credential for its contract.
  ///
  /// First unsets `isPrimary = true` on every other matching credential
  /// (best effort: per-record errors are swallowed because the new primary
  /// is set regardless), then writes `isPrimary = true` on the target
  /// credential.
  ///
  /// Marked [internal] because the wallet lifecycle layer drives primary
  /// assignment.
  ///
  /// Throws [CredentialNotFound] when the credential does not exist and
  /// [StorageWriteFailed] when the write fails.
  @override
  @internal
  Future<void> setPrimary(String credentialId) async {
    final credential = await _storage.get(credentialId);
    if (credential == null) {
      throw CredentialException.notFound(credentialId);
    }

    final contractId = credential.contractId;
    final List<StoredCredential> allCredentials = contractId != null
        ? await _storage.getByContract(contractId)
        : await _storage.getAll();

    for (final cred in allCredentials) {
      if (cred.isPrimary && cred.credentialId != credentialId) {
        try {
          await _storage.update(
            cred.credentialId,
            const StoredCredentialUpdate(isPrimary: false),
          );
        } catch (_) {
          // why: best-effort. The new primary is set regardless. Two
          // credentials briefly marked primary only affects which one
          // wins on auto-connect (first match wins), not correctness.
        }
      }
    }

    const update = StoredCredentialUpdate(isPrimary: true);
    try {
      await _storage.update(credentialId, update);
    } on CredentialException {
      rethrow;
    } on StorageException {
      rethrow;
    } catch (e) {
      throw StorageException.writeFailed(credentialId, cause: e);
    }
  }

  /// Clears every credential from storage. Irreversible; intended for
  /// account-deletion or reset flows.
  ///
  /// Throws [StorageWriteFailed] when clearing fails.
  Future<void> clearAll() async {
    try {
      await _storage.clear();
    } on StorageException {
      rethrow;
    } catch (e) {
      throw StorageException.writeFailed('all', cause: e);
    }
  }
}

/// Result of synchronising every credential against on-chain state.
///
/// Returned by [OZCredentialManager.syncAll]; carries the count of
/// credentials confirmed as deployed (and removed from storage), the
/// count still pending deployment, and the count whose deployment is
/// marked as failed.
class SyncResult {
  /// Constructs a sync result with the supplied counts.
  const SyncResult({
    required this.deployed,
    required this.pending,
    required this.failed,
  });

  /// Number of credentials confirmed as deployed on-chain. The
  /// corresponding credential rows have been removed from storage.
  final int deployed;

  /// Number of credentials still pending deployment.
  final int pending;

  /// Number of credentials whose deployment is marked as failed.
  final int failed;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SyncResult) return false;
    return other.deployed == deployed &&
        other.pending == pending &&
        other.failed == failed;
  }

  @override
  int get hashCode => Object.hash(deployed, pending, failed);

  @override
  String toString() =>
      'SyncResult(deployed: $deployed, pending: $pending, failed: $failed)';
}
