// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import 'oz_pipeline_fixtures.dart';

/// Returns a deterministic 65-byte secp256r1 uncompressed public key
/// (`0x04` prefix + 64 bytes derived from the index).
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

/// Builds a fresh [FakePipelineKit] paired with a real [OZCredentialManager]
/// bound to it.
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
      // rather than throwing (per D-122).
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
      // why: F-CQ-Flu-6 contract — narrowed catch in `sync` keeps the
      // stable boolean return contract for transient RPC failures while
      // surfacing the swallowed exception through the kit's event
      // emitter so consumers can observe it (logging, metrics, retry).
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
}
