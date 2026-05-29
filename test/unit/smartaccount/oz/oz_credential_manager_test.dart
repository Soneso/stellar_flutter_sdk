// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import 'oz_pipeline_fixtures.dart';

Uint8List _testPublicKey() {
  final out = Uint8List(SmartAccountConstants.secp256r1PublicKeySize);
  out[0] = SmartAccountConstants.uncompressedPubkeyPrefix;
  for (var i = 1; i < out.length; i++) {
    out[i] = i & 0xFF;
  }
  return out;
}

const String _contractA =
    'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK';
const String _contractB =
    'CADQOBYHA4DQOBYHA4DQOBYHA4DQOBYHA4DQOBYHA4DQOBYHA4DQP5KR';

LedgerEntry _fakeLedgerEntry() {
  return LedgerEntry.fromJson(<String, dynamic>{
    'key': 'AAAAAA==',
    'xdr': 'AAAAAA==',
    'lastModifiedLedgerSeq': 1000,
    'liveUntilLedgerSeq': 2000,
  });
}

({FakePipelineKit kit, OZCredentialManager manager}) _newKitWithManager({
  SorobanServer? sorobanServer,
}) {
  final kit = FakePipelineKit(sorobanServer: sorobanServer);
  return (kit: kit, manager: OZCredentialManager(kit));
}

void main() {
  group('OZCredentialManager.getAllCredentials', () {
    test('empty storage returns an empty list', () async {
      final ctx = _newKitWithManager();
      final all = await ctx.manager.getAllCredentials();
      expect(all, isEmpty);
    });

    test('returns every persisted credential', () async {
      final ctx = _newKitWithManager();

      await ctx.manager.createPendingCredential(
        credentialId: 'cred-1',
        publicKey: _testPublicKey(),
        contractId: _contractA,
      );
      await ctx.manager.createPendingCredential(
        credentialId: 'cred-2',
        publicKey: _testPublicKey(),
        contractId: _contractA,
      );

      final all = await ctx.manager.getAllCredentials();
      expect(all.length, 2);
      final ids = all.map((c) => c.credentialId).toSet();
      expect(ids, containsAll(<String>['cred-1', 'cred-2']));
    });
  });

  group('OZCredentialManager.getPendingCredentials', () {
    test('returns both pending and failed credentials', () async {
      final ctx = _newKitWithManager();

      await ctx.manager.createPendingCredential(
        credentialId: 'cred-pending',
        publicKey: _testPublicKey(),
        contractId: _contractA,
      );
      await ctx.manager.createPendingCredential(
        credentialId: 'cred-failed',
        publicKey: _testPublicKey(),
        contractId: _contractB,
      );
      await ctx.manager.markDeploymentFailed(
        credentialId: 'cred-failed',
        error: 'Insufficient balance',
      );

      final pending = await ctx.manager.getPendingCredentials();
      expect(pending.length, 2);
      final ids = pending.map((c) => c.credentialId).toSet();
      expect(ids, containsAll(<String>['cred-pending', 'cred-failed']));

      final failed =
          pending.firstWhere((c) => c.credentialId == 'cred-failed');
      expect(failed.deploymentStatus, CredentialDeploymentStatus.failed);
    });

    test('returns an empty list when no pending credentials exist', () async {
      final ctx = _newKitWithManager();
      final pending = await ctx.manager.getPendingCredentials();
      expect(pending, isEmpty);
    });
  });

  group('OZCredentialManager.saveCredential', () {
    test('persists the credential and reads back round-trips', () async {
      final ctx = _newKitWithManager();

      final saved = await ctx.manager.saveCredential(
        credentialId: 'saved-cred',
        publicKey: _testPublicKey(),
        nickname: 'My MacBook',
        contractId: _contractA,
      );

      expect(saved.credentialId, 'saved-cred');
      expect(saved.nickname, 'My MacBook');
      expect(saved.deploymentStatus, CredentialDeploymentStatus.pending);

      final retrieved = await ctx.manager.getCredential('saved-cred');
      expect(retrieved, isNotNull);
      expect(retrieved!.nickname, 'My MacBook');
    });

    test('empty credentialId throws InvalidInput', () async {
      final ctx = _newKitWithManager();
      await expectLater(
        ctx.manager.saveCredential(
          credentialId: '',
          publicKey: _testPublicKey(),
        ),
        throwsA(isA<InvalidInput>()),
      );
    });

    test('publicKey of wrong size throws InvalidInput', () async {
      final ctx = _newKitWithManager();
      await expectLater(
        ctx.manager.saveCredential(
          credentialId: 'invalid-key-cred',
          publicKey: Uint8List(32),
        ),
        throwsA(isA<InvalidInput>()),
      );
    });
  });

  group('OZCredentialManager.updateNickname', () {
    test('updates the nickname on an existing credential', () async {
      final ctx = _newKitWithManager();

      await ctx.manager.createPendingCredential(
        credentialId: 'nick-cred',
        publicKey: _testPublicKey(),
        contractId: _contractA,
      );

      await ctx.manager.updateNickname('nick-cred', 'YubiKey 5');

      final updated = await ctx.manager.getCredential('nick-cred');
      expect(updated, isNotNull);
      expect(updated!.nickname, 'YubiKey 5');
    });

    test('non-existent credential throws CredentialNotFound', () async {
      final ctx = _newKitWithManager();
      await expectLater(
        ctx.manager.updateNickname('nonexistent', 'Name'),
        throwsA(isA<CredentialNotFound>()),
      );
    });
  });

  group('OZCredentialManager.updateCredential', () {
    test('partial update preserves untouched fields', () async {
      final ctx = _newKitWithManager();

      await ctx.manager.createPendingCredential(
        credentialId: 'update-cred',
        publicKey: _testPublicKey(),
        contractId: _contractA,
      );

      await ctx.manager.updateCredential(
        'update-cred',
        const StoredCredentialUpdate(
          nickname: 'Updated Name',
          isPrimary: false,
        ),
      );

      final updated = await ctx.manager.getCredential('update-cred');
      expect(updated, isNotNull);
      expect(updated!.nickname, 'Updated Name');
      expect(updated.isPrimary, false);
      // deploymentStatus must be unchanged
      expect(updated.deploymentStatus, CredentialDeploymentStatus.pending);
    });

    test('non-existent credential throws CredentialNotFound', () async {
      final ctx = _newKitWithManager();
      await expectLater(
        ctx.manager.updateCredential(
          'nonexistent',
          const StoredCredentialUpdate(nickname: 'Fail'),
        ),
        throwsA(isA<CredentialNotFound>()),
      );
    });
  });

  group('OZCredentialManager.createPendingCredential', () {
    test('duplicate credentialId throws CredentialAlreadyExists', () async {
      final ctx = _newKitWithManager();

      await ctx.manager.createPendingCredential(
        credentialId: 'dup-cred',
        publicKey: _testPublicKey(),
        contractId: _contractA,
      );

      await expectLater(
        ctx.manager.createPendingCredential(
          credentialId: 'dup-cred',
          publicKey: _testPublicKey(),
          contractId: _contractB,
        ),
        throwsA(isA<CredentialAlreadyExists>()),
      );
    });

    test('isPrimary is false for newly-created pending credentials', () async {
      final ctx = _newKitWithManager();

      final credential = await ctx.manager.createPendingCredential(
        credentialId: 'primary-cred',
        publicKey: _testPublicKey(),
        contractId: _contractA,
      );

      expect(credential.isPrimary, isFalse);
    });

    test('persists transports, deviceType, and backedUp metadata', () async {
      final ctx = _newKitWithManager();

      final credential = await ctx.manager.createPendingCredential(
        credentialId: 'full-cred',
        publicKey: _testPublicKey(),
        contractId: _contractA,
        transports: const <String>['internal', 'usb'],
        deviceType: 'multiDevice',
        backedUp: true,
      );

      expect(credential.transports, <String>['internal', 'usb']);
      expect(credential.deviceType, 'multiDevice');
      expect(credential.backedUp, true);
    });
  });

  group('OZCredentialManager.clearAll', () {
    test('removes every stored credential', () async {
      final ctx = _newKitWithManager();

      await ctx.manager.createPendingCredential(
        credentialId: 'clear-1',
        publicKey: _testPublicKey(),
        contractId: _contractA,
      );
      await ctx.manager.createPendingCredential(
        credentialId: 'clear-2',
        publicKey: _testPublicKey(),
        contractId: _contractB,
      );

      await ctx.manager.clearAll();

      final all = await ctx.manager.getAllCredentials();
      expect(all, isEmpty);
    });

    test('empty storage clear is a no-op', () async {
      final ctx = _newKitWithManager();
      await ctx.manager.clearAll();
      // Should not throw.
      final all = await ctx.manager.getAllCredentials();
      expect(all, isEmpty);
    });
  });

  group('OZCredentialManager.getCredentialsByContract', () {
    test('filters credentials by contract address', () async {
      final ctx = _newKitWithManager();

      await ctx.manager.createPendingCredential(
        credentialId: 'cred-a1',
        publicKey: _testPublicKey(),
        contractId: _contractA,
      );
      await ctx.manager.createPendingCredential(
        credentialId: 'cred-a2',
        publicKey: _testPublicKey(),
        contractId: _contractA,
      );
      await ctx.manager.createPendingCredential(
        credentialId: 'cred-b1',
        publicKey: _testPublicKey(),
        contractId: _contractB,
      );

      final aCreds = await ctx.manager.getCredentialsByContract(_contractA);
      expect(aCreds.length, 2);

      final bCreds = await ctx.manager.getCredentialsByContract(_contractB);
      expect(bCreds.length, 1);
      expect(bCreds[0].credentialId, 'cred-b1');
    });

    test('no match returns an empty list', () async {
      final ctx = _newKitWithManager();

      await ctx.manager.createPendingCredential(
        credentialId: 'cred-1',
        publicKey: _testPublicKey(),
        contractId: _contractA,
      );

      final result = await ctx.manager.getCredentialsByContract(
        'CXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
      );
      expect(result, isEmpty);
    });
  });

  group('OZCredentialManager.getForConnectedWallet', () {
    test('returns an empty list when no wallet is connected', () async {
      final ctx = _newKitWithManager();

      await ctx.manager.createPendingCredential(
        credentialId: 'cred-1',
        publicKey: _testPublicKey(),
        contractId: _contractA,
      );

      // Kit is not connected; getForConnectedWallet must return empty
      // rather than throwing.
      final result = await ctx.manager.getForConnectedWallet();
      expect(result, isEmpty);
    });

    test('returns credentials for the connected contract only', () async {
      final ctx = _newKitWithManager();

      await ctx.manager.createPendingCredential(
        credentialId: 'cred-1',
        publicKey: _testPublicKey(),
        contractId: _contractA,
      );
      await ctx.manager.createPendingCredential(
        credentialId: 'cred-other',
        publicKey: _testPublicKey(),
        contractId: _contractB,
      );

      ctx.kit
          .setConnectedState(credentialId: 'cred-1', contractId: _contractA);

      final result = await ctx.manager.getForConnectedWallet();
      expect(result.length, 1);
      expect(result[0].credentialId, 'cred-1');
    });
  });

  group('OZCredentialManager.updateLastUsed', () {
    test('sets a non-null timestamp on the stored credential', () async {
      final ctx = _newKitWithManager();

      await ctx.manager.createPendingCredential(
        credentialId: 'used-cred',
        publicKey: _testPublicKey(),
        contractId: _contractA,
      );

      await ctx.manager.updateLastUsed('used-cred');

      final updated = await ctx.manager.getCredential('used-cred');
      expect(updated, isNotNull);
      expect(updated!.lastUsedAt, isNotNull);
      expect(updated.lastUsedAt!, greaterThan(0));
    });
  });

  group('OZCredentialManager.setPrimary', () {
    test('unsets every previous primary before promoting the target',
        () async {
      final ctx = _newKitWithManager();

      // First credential ends up flagged isPrimary=true via the explicit
      // update below; createPendingCredential always writes isPrimary=false
      // so cred-a is promoted directly through updateCredential.
      await ctx.manager.createPendingCredential(
        credentialId: 'cred-a',
        publicKey: _testPublicKey(),
        contractId: _contractA,
      );
      await ctx.manager.updateCredential(
        'cred-a',
        const StoredCredentialUpdate(isPrimary: true),
      );

      // saveCredential overwrites without duplicate check; the second
      // credential starts as a non-primary entry on the same contract.
      await ctx.manager.saveCredential(
        credentialId: 'cred-b',
        publicKey: _testPublicKey(),
        contractId: _contractA,
      );

      await ctx.manager.setPrimary('cred-b');

      final credA = await ctx.manager.getCredential('cred-a');
      final credB = await ctx.manager.getCredential('cred-b');

      expect(credA, isNotNull);
      expect(credB, isNotNull);
      expect(credA!.isPrimary, false);
      expect(credB!.isPrimary, true);
    });

    test('non-existent credential throws CredentialNotFound', () async {
      final ctx = _newKitWithManager();
      await expectLater(
        ctx.manager.setPrimary('nonexistent'),
        throwsA(isA<CredentialNotFound>()),
      );
    });
  });

  group('OZCredentialManager.sync swallowed-exception event emission', () {
    test(
        'sync emits SmartAccountEventCredentialSyncFailed when getContractData throws Exception',
        () async {
      // The narrowed catch in `sync` keeps the stable boolean return
      // contract for transient RPC failures while surfacing the swallowed
      // exception through the kit's event emitter so consumers can
      // observe it (logging, metrics, retry).
      final mock = MockSorobanServer();
      mock.getContractDataResponses
          .add(Exception('connection reset by peer'));

      final ctx = _newKitWithManager(sorobanServer: mock);

      await ctx.manager.createPendingCredential(
        credentialId: 'sync-cred',
        publicKey: _testPublicKey(),
        contractId: _contractA,
      );

      final received = <SmartAccountEventCredentialSyncFailed>[];
      ctx.kit.events.on<SmartAccountEventCredentialSyncFailed>(received.add);

      final isDeployed = await ctx.manager.sync('sync-cred');
      expect(isDeployed, isFalse);

      expect(received, hasLength(1));
      expect(received.single.credentialId, 'sync-cred');
      expect(received.single.error, isA<Exception>());
      expect(
        received.single.error.toString(),
        contains('connection reset by peer'),
      );
    });

    test(
        'sync does NOT emit when getContractData returns null (contract simply absent)',
        () async {
      // why: a `null` ledger entry means "no contract on-chain" — the
      // expected outcome for a pending deploy. No exception is thrown,
      // so no event is emitted; only the boolean return communicates
      // the result.
      final mock = MockSorobanServer();
      mock.getContractDataResponses.add(<Object?>[null].first);

      final ctx = _newKitWithManager(sorobanServer: mock);

      await ctx.manager.createPendingCredential(
        credentialId: 'sync-cred-absent',
        publicKey: _testPublicKey(),
        contractId: _contractA,
      );

      final received = <SmartAccountEventCredentialSyncFailed>[];
      ctx.kit.events.on<SmartAccountEventCredentialSyncFailed>(received.add);

      final isDeployed = await ctx.manager.sync('sync-cred-absent');
      expect(isDeployed, isFalse);

      expect(
        received,
        isEmpty,
        reason: 'a null contract-data response is not an exception path',
      );
    });
  });

  // =========================================================================
  // Fault-injection tests using a delegating adapter that throws on demand.
  // =========================================================================

  group('OZCredentialManager.createPendingCredential fault injection', () {
    test('wrong publicKey size throws InvalidInput', () async {
      final ctx = _newKitWithManager();
      await expectLater(
        ctx.manager.createPendingCredential(
          credentialId: 'cred-bad-key',
          publicKey: Uint8List(32), // wrong: should be 65
          contractId: _contractA,
        ),
        throwsA(isA<InvalidInput>()),
      );
    });

    test('empty credentialId throws InvalidInput', () async {
      final ctx = _newKitWithManager();
      await expectLater(
        ctx.manager.createPendingCredential(
          credentialId: '',
          publicKey: _testPublicKey(),
          contractId: _contractA,
        ),
        throwsA(isA<InvalidInput>()),
      );
    });

    test('storage save throws rethrows StorageWriteFailed', () async {
      final faulting = _FaultingStorageAdapter(
        saveError: StorageException.writeFailed('cred-save-fail'),
      );
      final kit = FakePipelineKit(storage: faulting);
      final manager = OZCredentialManager(kit);

      await expectLater(
        manager.createPendingCredential(
          credentialId: 'cred-save-fail',
          publicKey: _testPublicKey(),
          contractId: _contractA,
        ),
        throwsA(isA<StorageWriteFailed>()),
      );
    });

    test('storage save throws non-StorageException wraps as StorageWriteFailed', () async {
      // Throwing a plain Exception (not StorageException) hits the generic
      // catch (e) branch → wraps as StorageWriteFailed.
      final faulting = _FaultingStorageAdapter(
        saveError: Exception('generic io error'),
      );
      final kit = FakePipelineKit(storage: faulting);
      final manager = OZCredentialManager(kit);

      await expectLater(
        manager.createPendingCredential(
          credentialId: 'cred-generic-err',
          publicKey: _testPublicKey(),
          contractId: _contractA,
        ),
        throwsA(isA<StorageWriteFailed>()),
      );
    });
  });

  group('OZCredentialManager.saveCredential fault injection', () {
    test('storage throws rethrows StorageWriteFailed', () async {
      final faulting = _FaultingStorageAdapter(
        saveError: StorageException.writeFailed('save-fault'),
      );
      final kit = FakePipelineKit(storage: faulting);
      final manager = OZCredentialManager(kit);

      await expectLater(
        manager.saveCredential(
          credentialId: 'save-fault',
          publicKey: _testPublicKey(),
        ),
        throwsA(isA<StorageWriteFailed>()),
      );
    });

    test('storage throws non-StorageException wraps as StorageWriteFailed', () async {
      final faulting = _FaultingStorageAdapter(
        saveError: Exception('io error in saveCredential'),
      );
      final kit = FakePipelineKit(storage: faulting);
      final manager = OZCredentialManager(kit);

      await expectLater(
        manager.saveCredential(
          credentialId: 'save-generic-err',
          publicKey: _testPublicKey(),
        ),
        throwsA(isA<StorageWriteFailed>()),
      );
    });
  });

  group('OZCredentialManager.markDeploymentFailed fault injection', () {
    test('credential not found throws CredentialNotFound', () async {
      final ctx = _newKitWithManager();
      await expectLater(
        ctx.manager.markDeploymentFailed(
          credentialId: 'missing-cred',
          error: 'some error',
        ),
        throwsA(isA<CredentialNotFound>()),
      );
    });

    test('storage update throws rethrows StorageException', () async {
      final faulting = _FaultingStorageAdapter(
        getResult: StoredCredential(
          credentialId: 'fault-cred',
          publicKey: _testPublicKey(),
          contractId: _contractA,
          createdAt: 1700000000000,
        ),
        updateError: StorageException.writeFailed('fault-cred'),
      );
      final kit = FakePipelineKit(storage: faulting);
      final manager = OZCredentialManager(kit);

      await expectLater(
        manager.markDeploymentFailed(
          credentialId: 'fault-cred',
          error: 'deploy failed',
        ),
        throwsA(isA<StorageWriteFailed>()),
      );
    });

    test('storage update throws non-StorageException wraps as StorageWriteFailed', () async {
      final faulting = _FaultingStorageAdapter(
        getResult: StoredCredential(
          credentialId: 'fault-generic',
          publicKey: _testPublicKey(),
          contractId: _contractA,
          createdAt: 1700000000000,
        ),
        updateError: Exception('update io error'),
      );
      final kit = FakePipelineKit(storage: faulting);
      final manager = OZCredentialManager(kit);

      await expectLater(
        manager.markDeploymentFailed(
          credentialId: 'fault-generic',
          error: 'deploy failed',
        ),
        throwsA(isA<StorageWriteFailed>()),
      );
    });
  });

  group('OZCredentialManager.sync fault injection', () {
    test('storage get throws StorageException rethrows', () async {
      final faulting = _FaultingStorageAdapter(
        getError: StorageException.readFailed('cred-sync-fault'),
      );
      final kit = FakePipelineKit(storage: faulting);
      final manager = OZCredentialManager(kit);

      await expectLater(
        manager.sync('cred-sync-fault'),
        throwsA(isA<StorageReadFailed>()),
      );
    });

    test('sync on missing credential throws CredentialNotFound', () async {
      final ctx = _newKitWithManager();
      await expectLater(
        ctx.manager.sync('no-such-cred'),
        throwsA(isA<CredentialNotFound>()),
      );
    });
  });

  group('OZCredentialManager.deleteCredential fault injection', () {
    test('successful delete emits CredentialDeleted event', () async {
      final mock = MockSorobanServer();
      // sync() returns false (contract not deployed).
      mock.getContractDataResponses.add(null);

      final ctx = _newKitWithManager(sorobanServer: mock);
      await ctx.manager.createPendingCredential(
        credentialId: 'del-success',
        publicKey: _testPublicKey(),
        contractId: _contractA,
      );

      final received = <SmartAccountEventCredentialDeleted>[];
      ctx.kit.events.on<SmartAccountEventCredentialDeleted>(received.add);

      await ctx.manager.deleteCredential(credentialId: 'del-success');

      expect(received, hasLength(1));
      expect(received.single.credentialId, 'del-success');
    });

    test('deleting missing credential throws CredentialNotFound', () async {
      final ctx = _newKitWithManager();
      await expectLater(
        ctx.manager.deleteCredential(credentialId: 'ghost-cred'),
        throwsA(isA<CredentialNotFound>()),
      );
    });

    test('credential_alreadyDeployed_throwsCredentialInvalid', () async {
      // When sync() returns true (contract deployed), deleteCredential throws
      // CredentialInvalid (line 355).
      final mock = MockSorobanServer();
      // getContractData returns a LedgerEntry (contract IS deployed).
      mock.getContractDataResponses.add(_fakeLedgerEntry());

      final ctx = _newKitWithManager(sorobanServer: mock);
      await ctx.manager.createPendingCredential(
        credentialId: 'deployed-cred',
        publicKey: _testPublicKey(),
        contractId: _contractA,
      );

      await expectLater(
        ctx.manager.deleteCredential(credentialId: 'deployed-cred'),
        throwsA(isA<CredentialInvalid>()),
      );
    });

    test('storage get throws StorageException rethrows', () async {
      final faulting = _FaultingStorageAdapter(
        getError: StorageException.readFailed('del-get-fault'),
      );
      final kit = FakePipelineKit(storage: faulting);
      final manager = OZCredentialManager(kit);

      await expectLater(
        manager.deleteCredential(credentialId: 'del-get-fault'),
        throwsA(isA<StorageReadFailed>()),
      );
    });

    test('storage get throws generic Exception wraps as StorageReadFailed', () async {
      final faulting = _FaultingStorageAdapter(
        getError: Exception('read error'),
      );
      final kit = FakePipelineKit(storage: faulting);
      final manager = OZCredentialManager(kit);

      await expectLater(
        manager.deleteCredential(credentialId: 'del-generic-err'),
        throwsA(isA<StorageReadFailed>()),
      );
    });

    test('storage delete throws StorageWriteFailed', () async {
      // sync() calls getContractData; return null (not deployed) so sync
      // succeeds and we reach the delete step where we inject the fault.
      final mock = MockSorobanServer();
      mock.getContractDataResponses.add(null);

      final faulting = _FaultingStorageAdapter(
        deleteError: StorageException.writeFailed('del-fault'),
      );
      // Pre-populate so get() returns the credential and delete() faults.
      // saveError is not set on this adapter instance so save() delegates cleanly.
      await faulting.save(StoredCredential(
        credentialId: 'del-fault',
        publicKey: _testPublicKey(),
        contractId: _contractA,
        createdAt: 1700000000000,
      ));

      final kit = FakePipelineKit(storage: faulting, sorobanServer: mock);
      final manager = OZCredentialManager(kit);

      await expectLater(
        manager.deleteCredential(credentialId: 'del-fault'),
        throwsA(isA<StorageWriteFailed>()),
      );
    });

    test('storage delete throws generic Exception wraps as StorageWriteFailed', () async {
      final mock = MockSorobanServer();
      mock.getContractDataResponses.add(null);

      final faulting = _FaultingStorageAdapter(
        deleteError: Exception('delete io error'),
      );
      await faulting.save(StoredCredential(
        credentialId: 'del-generic-fault',
        publicKey: _testPublicKey(),
        contractId: _contractA,
        createdAt: 1700000000000,
      ));

      final kit = FakePipelineKit(storage: faulting, sorobanServer: mock);
      final manager = OZCredentialManager(kit);

      await expectLater(
        manager.deleteCredential(credentialId: 'del-generic-fault'),
        throwsA(isA<StorageWriteFailed>()),
      );
    });
  });

  group('OZCredentialManager.syncAll', () {
    test('syncAll_emptyStorage_returnsZeroCounts', () async {
      final ctx = _newKitWithManager();
      final result = await ctx.manager.syncAll();
      expect(result.deployed, 0);
      expect(result.pending, 0);
      expect(result.failed, 0);
    });

    test('syncAll_pendingCredential_returnsPendingCount', () async {
      final mock = MockSorobanServer();
      // getContractData returns null (contract not deployed). Use queue entry
      // for null rather than default (which throws when fallback is null).
      mock.getContractDataResponses.add(null);
      final ctx = _newKitWithManager(sorobanServer: mock);

      await ctx.manager.createPendingCredential(
        credentialId: 'cred-sync-1',
        publicKey: _testPublicKey(),
        contractId: _contractA,
      );

      final result = await ctx.manager.syncAll();
      expect(result.pending, 1);
      expect(result.deployed, 0);
    });

    test('SyncResult_equalityAndHashCode', () {
      const a = SyncResult(deployed: 1, pending: 2, failed: 3);
      const b = SyncResult(deployed: 1, pending: 2, failed: 3);
      const c = SyncResult(deployed: 0, pending: 2, failed: 3);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a == c, isFalse);
      expect(a == 'not-a-result', isFalse);
    });

    test('SyncResult_equalityWithNonConstInstances', () {
      // Use non-const so identical() is false, exercising the == body.
      final a = SyncResult(deployed: 1, pending: 2, failed: 3);
      final b = SyncResult(deployed: 1, pending: 2, failed: 3);
      final c = SyncResult(deployed: 1, pending: 2, failed: 0);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a == c, isFalse);
    });

    test('syncAll_storageError_rethrowsStorageReadFailed', () async {
      final faulting = _FaultingStorageAdapter(
        getAllError: StorageException.readFailed('syncAll-fault'),
      );
      final kit = FakePipelineKit(storage: faulting);
      final manager = OZCredentialManager(kit);

      await expectLater(
        manager.syncAll(),
        throwsA(isA<StorageReadFailed>()),
      );
    });

    test('syncAll_genericStorageError_wrapsAsStorageReadFailed', () async {
      // Throwing a non-StorageException hits the generic catch (e) → wraps.
      final faulting = _FaultingStorageAdapter(
        getAllError: Exception('generic syncAll error'),
      );
      final kit = FakePipelineKit(storage: faulting);
      final manager = OZCredentialManager(kit);

      await expectLater(
        manager.syncAll(),
        throwsA(isA<StorageReadFailed>()),
      );
    });
  });

  group('OZCredentialManager.setPrimary', () {
    test('setPrimary_updatesCredential', () async {
      final ctx = _newKitWithManager();
      await ctx.manager.createPendingCredential(
        credentialId: 'primary-test',
        publicKey: _testPublicKey(),
        contractId: _contractA,
      );
      await ctx.manager.setPrimary('primary-test');
      final cred = await ctx.manager.getCredential('primary-test');
      expect(cred!.isPrimary, isTrue);
    });

    test('setPrimary_notFound_throwsCredentialNotFound', () async {
      final ctx = _newKitWithManager();
      await expectLater(
        ctx.manager.setPrimary('no-such-cred'),
        throwsA(isA<CredentialNotFound>()),
      );
    });
  });

  group('OZCredentialManager.getPendingCredentials fault injection', () {
    test('getAllGenericException_wrapsAsStorageReadFailed', () async {
      final faulting = _FaultingStorageAdapter(
        getAllError: Exception('generic getPending error'),
      );
      final kit = FakePipelineKit(storage: faulting);
      final manager = OZCredentialManager(kit);

      await expectLater(
        manager.getPendingCredentials(),
        throwsA(isA<StorageReadFailed>()),
      );
    });
  });

  group('OZCredentialManager.updateCredential fault injection', () {
    test('update_genericException_wrapsAsStorageWriteFailed', () async {
      final faulting = _FaultingStorageAdapter(
        updateError: Exception('generic update error'),
      );
      await faulting.save(StoredCredential(
        credentialId: 'update-generic-fault',
        publicKey: _testPublicKey(),
        contractId: _contractA,
        createdAt: 1700000000000,
      ));
      final kit = FakePipelineKit(storage: faulting);
      final manager = OZCredentialManager(kit);

      await expectLater(
        manager.updateCredential(
          'update-generic-fault',
          const StoredCredentialUpdate(nickname: 'New Name'),
        ),
        throwsA(isA<StorageWriteFailed>()),
      );
    });
  });

  group('OZCredentialManager.setPrimary fault injection', () {
    test('update_genericException_wrapsAsStorageWriteFailed', () async {
      final faulting = _FaultingStorageAdapter(
        updateError: Exception('generic setPrimary update error'),
        getResult: StoredCredential(
          credentialId: 'primary-fault',
          publicKey: _testPublicKey(),
          contractId: _contractA,
          createdAt: 1700000000000,
        ),
      );
      final kit = FakePipelineKit(storage: faulting);
      final manager = OZCredentialManager(kit);

      await expectLater(
        manager.setPrimary('primary-fault'),
        throwsA(isA<StorageWriteFailed>()),
      );
    });
  });

  group('OZCredentialManager.clearAll fault injection', () {
    test('clear_genericException_wrapsAsStorageWriteFailed', () async {
      // Need to override clear to throw a generic exception.
      // Use a custom adapter that throws on clear().
      final faulting = _ClearFaultAdapter();
      final kit = FakePipelineKit(storage: faulting);
      final manager = OZCredentialManager(kit);

      await expectLater(
        manager.clearAll(),
        throwsA(isA<StorageWriteFailed>()),
      );
    });
  });

  group('OZCredentialManager.clearAll', () {
    test('clearAll_removesAllCredentials', () async {
      final ctx = _newKitWithManager();
      await ctx.manager.createPendingCredential(
        credentialId: 'c1',
        publicKey: _testPublicKey(),
        contractId: _contractA,
      );
      await ctx.manager.clearAll();
      final all = await ctx.manager.getAllCredentials();
      expect(all, isEmpty);
    });
  });

  group('OZCredentialManager.updateLastUsed', () {
    test('updateLastUsed_existingCredential_updatesTimestamp', () async {
      final ctx = _newKitWithManager();
      await ctx.manager.createPendingCredential(
        credentialId: 'last-used-cred',
        publicKey: _testPublicKey(),
        contractId: _contractA,
      );
      await ctx.manager.updateLastUsed('last-used-cred');
      final cred = await ctx.manager.getCredential('last-used-cred');
      expect(cred!.lastUsedAt, isNotNull);
    });

    test('updateLastUsed_nonExistent_throwsCredentialNotFound', () async {
      final ctx = _newKitWithManager();
      await expectLater(
        ctx.manager.updateLastUsed('ghost-cred'),
        throwsA(isA<CredentialNotFound>()),
      );
    });
  });

  group('OZCredentialManager read fault injection', () {
    test('getCredential storage throws rethrows StorageReadFailed', () async {
      final faulting = _FaultingStorageAdapter(
        getError: StorageException.readFailed('read-fault'),
      );
      final kit = FakePipelineKit(storage: faulting);
      final manager = OZCredentialManager(kit);

      await expectLater(
        manager.getCredential('read-fault'),
        throwsA(isA<StorageReadFailed>()),
      );
    });

    test('getCredential_genericException_wrapsAsStorageReadFailed', () async {
      final faulting = _FaultingStorageAdapter(
        getError: Exception('generic read error'),
      );
      final kit = FakePipelineKit(storage: faulting);
      final manager = OZCredentialManager(kit);

      await expectLater(
        manager.getCredential('read-fault'),
        throwsA(isA<StorageReadFailed>()),
      );
    });

    test('getAllCredentials storage throws rethrows StorageReadFailed', () async {
      final faulting = _FaultingStorageAdapter(
        getAllError: StorageException.readFailed('all-read-fault'),
      );
      final kit = FakePipelineKit(storage: faulting);
      final manager = OZCredentialManager(kit);

      await expectLater(
        manager.getAllCredentials(),
        throwsA(isA<StorageReadFailed>()),
      );
    });

    test('getAllCredentials_genericException_wrapsAsStorageReadFailed', () async {
      final faulting = _FaultingStorageAdapter(
        getAllError: Exception('generic getAll error'),
      );
      final kit = FakePipelineKit(storage: faulting);
      final manager = OZCredentialManager(kit);

      await expectLater(
        manager.getAllCredentials(),
        throwsA(isA<StorageReadFailed>()),
      );
    });

    test('getCredentialsByContract storage throws rethrows StorageReadFailed', () async {
      final faulting = _FaultingStorageAdapter(
        getByContractError: StorageException.readFailed('contract-read-fault'),
      );
      final kit = FakePipelineKit(storage: faulting);
      final manager = OZCredentialManager(kit);

      await expectLater(
        manager.getCredentialsByContract(_contractA),
        throwsA(isA<StorageReadFailed>()),
      );
    });

    test('getCredentialsByContract_genericException_wrapsAsStorageReadFailed', () async {
      final faulting = _FaultingStorageAdapter(
        getByContractError: Exception('generic getByContract error'),
      );
      final kit = FakePipelineKit(storage: faulting);
      final manager = OZCredentialManager(kit);

      await expectLater(
        manager.getCredentialsByContract(_contractA),
        throwsA(isA<StorageReadFailed>()),
      );
    });
  });
}

// ---------------------------------------------------------------------------
// Fault-injecting StorageAdapter for testing error paths in OZCredentialManager.
// ---------------------------------------------------------------------------

/// A [StorageAdapter] that delegates to an [InMemoryStorageAdapter] but throws
/// pre-configured errors on specific operations. Used to drive catch branches
/// in the credential manager without depending on platform-channel machinery.
/// An adapter whose clear() throws a generic (non-StorageException) exception
/// to exercise the generic catch (e) block at line 567 in oz_credential_manager.dart.
class _ClearFaultAdapter extends InMemoryStorageAdapter {
  @override
  Future<void> clear() async {
    throw Exception('generic clear error');
  }
}

class _FaultingStorageAdapter implements StorageAdapter {
  _FaultingStorageAdapter({
    this.saveError,
    this.getError,
    this.getResult,
    this.getByContractError,
    this.getAllError,
    this.deleteError,
    this.updateError,
  });

  final Exception? saveError;
  final Exception? getError;
  final StoredCredential? getResult;
  final Exception? getByContractError;
  final Exception? getAllError;
  final Exception? deleteError;
  final Exception? updateError;

  final InMemoryStorageAdapter _delegate = InMemoryStorageAdapter();

  @override
  Future<void> save(StoredCredential credential) async {
    final err = saveError;
    if (err != null) throw err;
    await _delegate.save(credential);
  }

  @override
  Future<StoredCredential?> get(String credentialId) async {
    final err = getError;
    if (err != null) throw err;
    if (getResult != null) return getResult;
    return _delegate.get(credentialId);
  }

  @override
  Future<List<StoredCredential>> getByContract(String contractId) async {
    final err = getByContractError;
    if (err != null) throw err;
    return _delegate.getByContract(contractId);
  }

  @override
  Future<List<StoredCredential>> getAll() async {
    final err = getAllError;
    if (err != null) throw err;
    return _delegate.getAll();
  }

  @override
  Future<void> delete(String credentialId) async {
    final err = deleteError;
    if (err != null) throw err;
    await _delegate.delete(credentialId);
  }

  @override
  Future<void> update(String credentialId, StoredCredentialUpdate updates) async {
    final err = updateError;
    if (err != null) throw err;
    await _delegate.update(credentialId, updates);
  }

  @override
  Future<void> clear() async => _delegate.clear();

  @override
  Future<void> saveSession(StoredSession session) async =>
      _delegate.saveSession(session);

  @override
  Future<StoredSession?> getSession() async => _delegate.getSession();

  @override
  Future<void> clearSession() async => _delegate.clearSession();
}
