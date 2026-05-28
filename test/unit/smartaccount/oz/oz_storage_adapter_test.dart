import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

const String _testContractId =
    'CBCD1234EFGH5678IJKL9012MNOP3456QRST7890UVWX1234YZAB5678';

const String _validVerifier =
    'CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM';

Uint8List _testPublicKey({int seed = 0}) {
  final out = Uint8List(65);
  out[0] = 0x04;
  for (var i = 1; i < 65; i++) {
    out[i] = (i + seed) % 256;
  }
  return out;
}

StoredCredential _fullCredential({
  String id = 'cred-full-001',
  String contractId = _testContractId,
}) {
  return StoredCredential(
    credentialId: id,
    publicKey: _testPublicKey(seed: 1),
    contractId: contractId,
    deploymentStatus: CredentialDeploymentStatus.pending,
    createdAt: 1700000000000,
    lastUsedAt: 1700001000000,
    nickname: 'MacBook Pro Touch ID',
    isPrimary: true,
    transports: const ['internal', 'usb'],
    deviceType: 'multiDevice',
    backedUp: true,
  );
}

StoredCredential _minimalCredential({
  String id = 'cred-minimal-001',
}) {
  return StoredCredential(
    credentialId: id,
    publicKey: _testPublicKey(seed: 2),
    createdAt: 1700000000000,
  );
}

InMemoryStorageAdapter _newAdapter() => InMemoryStorageAdapter();

bool _bytesEqual(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

void main() {
  group('InMemoryStorageAdapter - StorageAdapterTest', () {
    test('testSaveAndRetrieveCredential', () async {
      final adapter = _newAdapter();
      final credential = _fullCredential();

      await adapter.save(credential);

      final retrieved = await adapter.get(credential.credentialId);
      expect(retrieved, isNotNull);
      expect(retrieved!.credentialId, credential.credentialId);
      expect(_bytesEqual(retrieved.publicKey, credential.publicKey), isTrue);
      expect(retrieved.contractId, credential.contractId);
      expect(retrieved.deploymentStatus, credential.deploymentStatus);
      expect(retrieved.nickname, credential.nickname);
      expect(retrieved.isPrimary, credential.isPrimary);
    });

    test('testSaveCredentialWithAllFieldsPopulated', () async {
      final adapter = _newAdapter();
      final credential = _fullCredential();

      await adapter.save(credential);
      final retrieved = await adapter.get(credential.credentialId);

      expect(retrieved, isNotNull);
      expect(retrieved!.credentialId, 'cred-full-001');
      expect(_bytesEqual(_testPublicKey(seed: 1), retrieved.publicKey), isTrue);
      expect(retrieved.contractId, _testContractId);
      expect(retrieved.deploymentStatus, CredentialDeploymentStatus.pending);
      expect(retrieved.deploymentError, isNull);
      expect(retrieved.createdAt, 1700000000000);
      expect(retrieved.lastUsedAt, 1700001000000);
      expect(retrieved.nickname, 'MacBook Pro Touch ID');
      expect(retrieved.isPrimary, isTrue);
      expect(retrieved.transports, ['internal', 'usb']);
      expect(retrieved.deviceType, 'multiDevice');
      expect(retrieved.backedUp, isTrue);
    });

    test('testSaveCredentialWithMinimalFields', () async {
      final adapter = _newAdapter();
      final credential = _minimalCredential();

      await adapter.save(credential);
      final retrieved = await adapter.get(credential.credentialId);

      expect(retrieved, isNotNull);
      expect(retrieved!.credentialId, 'cred-minimal-001');
      expect(_bytesEqual(_testPublicKey(seed: 2), retrieved.publicKey), isTrue);
      expect(retrieved.contractId, isNull);
      expect(retrieved.deploymentStatus, CredentialDeploymentStatus.pending);
      expect(retrieved.deploymentError, isNull);
      expect(retrieved.lastUsedAt, isNull);
      expect(retrieved.nickname, isNull);
      expect(retrieved.isPrimary, isFalse);
      expect(retrieved.transports, isNull);
      expect(retrieved.deviceType, isNull);
      expect(retrieved.backedUp, isNull);
    });

    test('testGetNonexistentCredentialReturnsNull', () async {
      final adapter = _newAdapter();
      final result = await adapter.get('nonexistent-id');
      expect(result, isNull);
    });

    test('testSaveExistingCredentialOverwrites', () async {
      final adapter = _newAdapter();
      final original = StoredCredential(
        credentialId: 'cred-upsert',
        publicKey: _testPublicKey(seed: 10),
        contractId: 'CONTRACT_A',
        deploymentStatus: CredentialDeploymentStatus.pending,
        createdAt: 1700000000000,
        nickname: 'Original Name',
      );
      await adapter.save(original);

      final replacement = StoredCredential(
        credentialId: 'cred-upsert',
        publicKey: _testPublicKey(seed: 20),
        contractId: 'CONTRACT_B',
        deploymentStatus: CredentialDeploymentStatus.failed,
        createdAt: 1700002000000,
        nickname: 'Replaced Name',
        deploymentError: 'Insufficient balance',
      );
      await adapter.save(replacement);

      final retrieved = await adapter.get('cred-upsert');
      expect(retrieved, isNotNull);
      expect(_bytesEqual(_testPublicKey(seed: 20), retrieved!.publicKey), isTrue);
      expect(retrieved.contractId, 'CONTRACT_B');
      expect(retrieved.deploymentStatus, CredentialDeploymentStatus.failed);
      expect(retrieved.nickname, 'Replaced Name');
      expect(retrieved.deploymentError, 'Insufficient balance');

      final all = await adapter.getAll();
      expect(all.length, 1);
    });

    test('testUpdateCredentialDeploymentStatus', () async {
      final adapter = _newAdapter();
      await adapter.save(_fullCredential());

      await adapter.update(
        'cred-full-001',
        const StoredCredentialUpdate(
          deploymentStatus: CredentialDeploymentStatus.failed,
          deploymentError: 'Transaction failed: insufficient balance',
        ),
      );

      final updated = await adapter.get('cred-full-001');
      expect(updated, isNotNull);
      expect(updated!.deploymentStatus, CredentialDeploymentStatus.failed);
      expect(
        updated.deploymentError,
        'Transaction failed: insufficient balance',
      );
      expect(updated.nickname, 'MacBook Pro Touch ID');
      expect(updated.isPrimary, isTrue);
    });

    test('testUpdateCredentialLastUsedAt', () async {
      final adapter = _newAdapter();
      await adapter.save(_fullCredential());

      const newTimestamp = 1700099000000;
      await adapter.update(
        'cred-full-001',
        const StoredCredentialUpdate(lastUsedAt: newTimestamp),
      );

      final updated = await adapter.get('cred-full-001');
      expect(updated, isNotNull);
      expect(updated!.lastUsedAt, newTimestamp);
      expect(updated.nickname, 'MacBook Pro Touch ID');
    });

    test('testUpdateCredentialNickname', () async {
      final adapter = _newAdapter();
      await adapter.save(_fullCredential());

      await adapter.update(
        'cred-full-001',
        const StoredCredentialUpdate(nickname: 'YubiKey 5'),
      );

      final updated = await adapter.get('cred-full-001');
      expect(updated, isNotNull);
      expect(updated!.nickname, 'YubiKey 5');
      expect(updated.lastUsedAt, 1700001000000);
      expect(updated.isPrimary, isTrue);
    });

    test('testUpdateCredentialPrimaryFlag', () async {
      final adapter = _newAdapter();
      await adapter.save(_fullCredential());

      await adapter.update(
        'cred-full-001',
        const StoredCredentialUpdate(isPrimary: false),
      );

      final updated = await adapter.get('cred-full-001');
      expect(updated, isNotNull);
      expect(updated!.isPrimary, isFalse);
    });

    test('testUpdateCredentialTransports', () async {
      final adapter = _newAdapter();
      await adapter.save(_fullCredential());

      await adapter.update(
        'cred-full-001',
        const StoredCredentialUpdate(transports: ['ble', 'nfc']),
      );

      final updated = await adapter.get('cred-full-001');
      expect(updated, isNotNull);
      expect(updated!.transports, ['ble', 'nfc']);
    });

    test('testUpdateCredentialDeviceTypeAndBackedUp', () async {
      final adapter = _newAdapter();
      await adapter.save(_fullCredential());

      await adapter.update(
        'cred-full-001',
        const StoredCredentialUpdate(
          deviceType: 'singleDevice',
          backedUp: false,
        ),
      );

      final updated = await adapter.get('cred-full-001');
      expect(updated, isNotNull);
      expect(updated!.deviceType, 'singleDevice');
      expect(updated.backedUp, isFalse);
    });

    test('testUpdateCredentialContractId', () async {
      final adapter = _newAdapter();
      await adapter.save(_minimalCredential());

      const newContractId =
          'CNEW1234CONT5678RACT9012ADDR3456GOES7890HERE1234ABCD5678';
      await adapter.update(
        'cred-minimal-001',
        const StoredCredentialUpdate(contractId: newContractId),
      );

      final updated = await adapter.get('cred-minimal-001');
      expect(updated, isNotNull);
      expect(updated!.contractId, newContractId);
    });

    test('testUpdateOnlyNonNullFieldsAreApplied', () async {
      final adapter = _newAdapter();
      final original = _fullCredential();
      await adapter.save(original);

      await adapter.update(
        'cred-full-001',
        const StoredCredentialUpdate(nickname: 'Updated Name'),
      );

      final updated = await adapter.get('cred-full-001');
      expect(updated, isNotNull);
      expect(updated!.nickname, 'Updated Name');
      expect(updated.contractId, original.contractId);
      expect(updated.deploymentStatus, original.deploymentStatus);
      expect(updated.deploymentError, original.deploymentError);
      expect(updated.lastUsedAt, original.lastUsedAt);
      expect(updated.isPrimary, original.isPrimary);
      expect(updated.transports, original.transports);
      expect(updated.deviceType, original.deviceType);
      expect(updated.backedUp, original.backedUp);
    });

    test('testUpdateNonexistentCredentialThrows', () async {
      final adapter = _newAdapter();

      await expectLater(
        adapter.update(
          'nonexistent-id',
          const StoredCredentialUpdate(nickname: 'Should fail'),
        ),
        throwsA(isA<CredentialNotFound>()),
      );
    });

    test('testUpdateMultipleFieldsAtOnce', () async {
      final adapter = _newAdapter();
      await adapter.save(_fullCredential());

      await adapter.update(
        'cred-full-001',
        const StoredCredentialUpdate(
          deploymentStatus: CredentialDeploymentStatus.failed,
          deploymentError: 'Network timeout',
          lastUsedAt: 1700099000000,
          nickname: 'Updated Device',
          isPrimary: false,
        ),
      );

      final updated = await adapter.get('cred-full-001');
      expect(updated, isNotNull);
      expect(updated!.deploymentStatus, CredentialDeploymentStatus.failed);
      expect(updated.deploymentError, 'Network timeout');
      expect(updated.lastUsedAt, 1700099000000);
      expect(updated.nickname, 'Updated Device');
      expect(updated.isPrimary, isFalse);
      expect(updated.transports, ['internal', 'usb']);
      expect(updated.deviceType, 'multiDevice');
      expect(updated.backedUp, isTrue);
    });

    test('testDeleteCredential', () async {
      final adapter = _newAdapter();
      await adapter.save(_fullCredential());

      await adapter.delete('cred-full-001');

      final result = await adapter.get('cred-full-001');
      expect(result, isNull);
    });

    test('testDeleteNonexistentCredentialDoesNotThrow', () async {
      final adapter = _newAdapter();
      await adapter.delete('nonexistent-id');
    });

    test('testDeleteRemovesOnlyTargetCredential', () async {
      final adapter = _newAdapter();
      await adapter.save(_fullCredential(id: 'cred-a'));
      await adapter.save(_fullCredential(id: 'cred-b'));
      await adapter.save(_fullCredential(id: 'cred-c'));

      await adapter.delete('cred-b');

      expect(await adapter.get('cred-a'), isNotNull);
      expect(await adapter.get('cred-b'), isNull);
      expect(await adapter.get('cred-c'), isNotNull);
      expect((await adapter.getAll()).length, 2);
    });

    test('testGetAllEmptyReturnsEmptyList', () async {
      final adapter = _newAdapter();
      final all = await adapter.getAll();
      expect(all, isEmpty);
    });

    test('testGetAllWithMultipleCredentials', () async {
      final adapter = _newAdapter();
      await adapter.save(_fullCredential(id: 'cred-1'));
      await adapter.save(_fullCredential(id: 'cred-2'));
      await adapter.save(_minimalCredential(id: 'cred-3'));

      final all = await adapter.getAll();
      expect(all.length, 3);

      final ids = all.map((c) => c.credentialId).toSet();
      expect(ids.contains('cred-1'), isTrue);
      expect(ids.contains('cred-2'), isTrue);
      expect(ids.contains('cred-3'), isTrue);
    });

    test('testGetByContractIdReturnsMatchingCredentials', () async {
      final adapter = _newAdapter();
      const contractA =
          'CAAA1234AAAA5678AAAA9012AAAA3456AAAA7890AAAA1234AAAA5678';
      const contractB =
          'CBBB1234BBBB5678BBBB9012BBBB3456BBBB7890BBBB1234BBBB5678';

      await adapter.save(_fullCredential(id: 'cred-a1', contractId: contractA));
      await adapter.save(_fullCredential(id: 'cred-a2', contractId: contractA));
      await adapter.save(_fullCredential(id: 'cred-b1', contractId: contractB));

      final resultA = await adapter.getByContract(contractA);
      expect(resultA.length, 2);
      final idsA = resultA.map((c) => c.credentialId).toSet();
      expect(idsA.contains('cred-a1'), isTrue);
      expect(idsA.contains('cred-a2'), isTrue);

      final resultB = await adapter.getByContract(contractB);
      expect(resultB.length, 1);
      expect(resultB[0].credentialId, 'cred-b1');
    });

    test('testGetByContractIdNoMatchReturnsEmptyList', () async {
      final adapter = _newAdapter();
      await adapter.save(_fullCredential());

      final result = await adapter.getByContract('NONEXISTENT_CONTRACT_ID');
      expect(result, isEmpty);
    });

    test('testGetByContractIdExcludesNullContractIds', () async {
      final adapter = _newAdapter();
      await adapter.save(_minimalCredential(id: 'cred-no-contract'));
      await adapter.save(_fullCredential(id: 'cred-with-contract'));

      final result = await adapter.getByContract(_fullCredential().contractId!);
      expect(result.length, 1);
      expect(result[0].credentialId, 'cred-with-contract');
    });

    test('testClearRemovesAllCredentials', () async {
      final adapter = _newAdapter();
      await adapter.save(_fullCredential(id: 'cred-1'));
      await adapter.save(_fullCredential(id: 'cred-2'));
      await adapter.save(_minimalCredential(id: 'cred-3'));

      await adapter.clear();

      final all = await adapter.getAll();
      expect(all, isEmpty);
      expect(await adapter.get('cred-1'), isNull);
      expect(await adapter.get('cred-2'), isNull);
      expect(await adapter.get('cred-3'), isNull);
    });

    test('testClearOnEmptyAdapterDoesNotThrow', () async {
      final adapter = _newAdapter();
      await adapter.clear();
      expect(await adapter.getAll(), isEmpty);
    });

    test('testSaveAndRetrieveSession', () async {
      final adapter = _newAdapter();
      const now = 1700000000000;
      const expiresAt = 9007199254740991;
      final session = StoredSession(
        credentialId: 'cred-session-001',
        contractId:
            'CSESS1234CONT5678RACT9012ADDR3456GOES7890HERE1234ABCD5678',
        connectedAt: now,
        expiresAt: expiresAt,
      );

      await adapter.saveSession(session);

      final retrieved = await adapter.getSession();
      expect(retrieved, isNotNull);
      expect(retrieved!.credentialId, 'cred-session-001');
      expect(
        retrieved.contractId,
        'CSESS1234CONT5678RACT9012ADDR3456GOES7890HERE1234ABCD5678',
      );
      expect(retrieved.connectedAt, now);
      expect(retrieved.expiresAt, expiresAt);
    });

    test('testGetSessionWhenNoneExistsReturnsNull', () async {
      final adapter = _newAdapter();
      final result = await adapter.getSession();
      expect(result, isNull);
    });

    test('testSaveSessionOverwritesPrevious', () async {
      final adapter = _newAdapter();
      const now = 1700000000000;

      final session1 = StoredSession(
        credentialId: 'cred-session-1',
        contractId: 'CONTRACT_1',
        connectedAt: now,
        expiresAt: 9007199254740991,
      );
      await adapter.saveSession(session1);

      final session2 = StoredSession(
        credentialId: 'cred-session-2',
        contractId: 'CONTRACT_2',
        connectedAt: now + 1000,
        expiresAt: 9007199254740991,
      );
      await adapter.saveSession(session2);

      final retrieved = await adapter.getSession();
      expect(retrieved, isNotNull);
      expect(retrieved!.credentialId, 'cred-session-2');
      expect(retrieved.contractId, 'CONTRACT_2');
    });

    test('testClearSession', () async {
      final adapter = _newAdapter();
      const now = 1700000000000;
      await adapter.saveSession(StoredSession(
        credentialId: 'cred-session',
        contractId: 'CONTRACT',
        connectedAt: now,
        expiresAt: now + 7 * 24 * 60 * 60 * 1000,
      ));

      await adapter.clearSession();

      final result = await adapter.getSession();
      expect(result, isNull);
    });

    test('testClearSessionWhenNoneExistsDoesNotThrow', () async {
      final adapter = _newAdapter();
      await adapter.clearSession();
      expect(await adapter.getSession(), isNull);
    });

    test('testExpiredSessionAutoClearedOnGetSession', () async {
      final adapter = _newAdapter();
      const session = StoredSession(
        credentialId: 'cred-expired',
        contractId: 'CONTRACT_EXPIRED',
        connectedAt: 1000,
        expiresAt: 2000,
      );
      await adapter.saveSession(session);

      final result = await adapter.getSession();
      expect(result, isNull,
          reason: 'Expired session should be auto-cleared and return null');

      final secondResult = await adapter.getSession();
      expect(secondResult, isNull,
          reason: 'Session should remain cleared after auto-eviction');
    });

    test('testNonExpiredSessionIsReturned', () async {
      final adapter = _newAdapter();
      const session = StoredSession(
        credentialId: 'cred-valid',
        contractId: 'CONTRACT_VALID',
        connectedAt: 1700000000000,
        expiresAt: 9007199254740991,
      );
      await adapter.saveSession(session);

      final result = await adapter.getSession();
      expect(result, isNotNull);
      expect(result!.credentialId, 'cred-valid');
    });

    test('testClearCredentialsDoesNotAffectSession', () async {
      final adapter = _newAdapter();
      await adapter.save(_fullCredential());
      await adapter.saveSession(const StoredSession(
        credentialId: 'cred-full-001',
        contractId: 'CONTRACT',
        connectedAt: 1700000000000,
        expiresAt: 9007199254740991,
      ));

      await adapter.clear();

      expect((await adapter.getAll()), isEmpty,
          reason: 'Credentials should be cleared');
      expect(await adapter.getSession(), isNotNull,
          reason: 'Session should not be affected by clear()');
    });

    test('testClearSessionDoesNotAffectCredentials', () async {
      final adapter = _newAdapter();
      await adapter.save(_fullCredential());
      await adapter.saveSession(const StoredSession(
        credentialId: 'cred-full-001',
        contractId: 'CONTRACT',
        connectedAt: 1700000000000,
        expiresAt: 9007199254740991,
      ));

      await adapter.clearSession();

      expect(await adapter.getSession(), isNull,
          reason: 'Session should be cleared');
      expect((await adapter.getAll()).length, 1,
          reason: 'Credentials should not be affected by clearSession()');
    });

    test('testCredentialIdWithSpecialCharacters', () async {
      final adapter = _newAdapter();
      const specialIds = [
        'cred-with-dashes',
        'cred_with_underscores',
        'cred.with.dots',
        'cred/with/slashes',
        'cred+with+plus',
        'cred=with=equals',
        'cred with spaces',
        'Scz0fXNlcjoxMjM0NTY3ODkw',
        '-__-SomeCredId',
        'cred@user:domain#fragment?query=1',
      ];

      for (final id in specialIds) {
        await adapter.save(StoredCredential(
          credentialId: id,
          publicKey: _testPublicKey(),
          createdAt: 1700000000000,
        ));
      }

      for (final id in specialIds) {
        final retrieved = await adapter.get(id);
        expect(retrieved, isNotNull,
            reason: 'Should retrieve credential with ID: $id');
        expect(retrieved!.credentialId, id);
      }

      expect((await adapter.getAll()).length, specialIds.length);
    });

    test('testCredentialIdWithEmptyString', () async {
      final adapter = _newAdapter();
      final credential = StoredCredential(
        credentialId: '',
        publicKey: _testPublicKey(),
        createdAt: 1700000000000,
      );

      await adapter.save(credential);

      final retrieved = await adapter.get('');
      expect(retrieved, isNotNull);
      expect(retrieved!.credentialId, '');
    });

    test('testLargePublicKey', () async {
      final adapter = _newAdapter();
      final largeKey =
          Uint8List.fromList(List<int>.generate(1024, (i) => i % 256));
      final credential = StoredCredential(
        credentialId: 'cred-large-key',
        publicKey: largeKey,
        createdAt: 1700000000000,
      );

      await adapter.save(credential);

      final retrieved = await adapter.get('cred-large-key');
      expect(retrieved, isNotNull);
      expect(_bytesEqual(largeKey, retrieved!.publicKey), isTrue);
    });

    test('testLargeNickname', () async {
      final adapter = _newAdapter();
      final longNickname = 'A' * 10000;
      final credential = StoredCredential(
        credentialId: 'cred-long-name',
        publicKey: _testPublicKey(),
        nickname: longNickname,
        createdAt: 1700000000000,
      );

      await adapter.save(credential);

      final retrieved = await adapter.get('cred-long-name');
      expect(retrieved, isNotNull);
      expect(retrieved!.nickname, longNickname);
    });

    test('testLargeTransportsList', () async {
      final adapter = _newAdapter();
      final manyTransports =
          List<String>.generate(100, (i) => 'transport-${i + 1}');
      final credential = StoredCredential(
        credentialId: 'cred-many-transports',
        publicKey: _testPublicKey(),
        transports: manyTransports,
        createdAt: 1700000000000,
      );

      await adapter.save(credential);

      final retrieved = await adapter.get('cred-many-transports');
      expect(retrieved, isNotNull);
      expect(retrieved!.transports?.length, 100);
      expect(retrieved.transports?.first, 'transport-1');
      expect(retrieved.transports?.last, 'transport-100');
    });

    test('testMultipleCredentialsForSameContractId', () async {
      final adapter = _newAdapter();
      const sharedContract =
          'CSHARED1234ABCD5678EFGH9012IJKL3456MNOP7890QRST1234UVWX';

      final cred1 = StoredCredential(
        credentialId: 'cred-primary',
        publicKey: _testPublicKey(seed: 1),
        contractId: sharedContract,
        isPrimary: true,
        nickname: 'Primary Passkey',
        createdAt: 1700000000000,
      );
      final cred2 = StoredCredential(
        credentialId: 'cred-backup',
        publicKey: _testPublicKey(seed: 2),
        contractId: sharedContract,
        isPrimary: false,
        nickname: 'Backup YubiKey',
        createdAt: 1700000001000,
      );
      final cred3 = StoredCredential(
        credentialId: 'cred-recovery',
        publicKey: _testPublicKey(seed: 3),
        contractId: sharedContract,
        isPrimary: false,
        nickname: 'Recovery Key',
        createdAt: 1700000002000,
      );

      await adapter.save(cred1);
      await adapter.save(cred2);
      await adapter.save(cred3);

      final byContract = await adapter.getByContract(sharedContract);
      expect(byContract.length, 3);

      final ids = byContract.map((c) => c.credentialId).toSet();
      expect(ids.contains('cred-primary'), isTrue);
      expect(ids.contains('cred-backup'), isTrue);
      expect(ids.contains('cred-recovery'), isTrue);
    });

    test('testRapidSaveAndRetrieveCycle', () async {
      final adapter = _newAdapter();

      for (var i = 1; i <= 50; i++) {
        final id = 'cred-rapid-$i';
        final credential = StoredCredential(
          credentialId: id,
          publicKey: _testPublicKey(seed: i),
          contractId: 'CONTRACT_RAPID',
          createdAt: 1700000000000 + i,
        );
        await adapter.save(credential);

        final retrieved = await adapter.get(id);
        expect(retrieved, isNotNull,
            reason: 'Should retrieve credential $id immediately after save');
        expect(retrieved!.credentialId, id);
      }

      expect((await adapter.getAll()).length, 50);
    });

    test('testRapidUpdateCycle', () async {
      final adapter = _newAdapter();
      await adapter.save(_fullCredential());

      for (var i = 1; i <= 20; i++) {
        await adapter.update(
          'cred-full-001',
          StoredCredentialUpdate(
            lastUsedAt: 1700000000000 + i * 1000,
            nickname: 'Update #$i',
          ),
        );
      }

      final finalState = await adapter.get('cred-full-001');
      expect(finalState, isNotNull);
      expect(finalState!.lastUsedAt, 1700000000000 + 20 * 1000);
      expect(finalState.nickname, 'Update #20');
    });

    test('testDeploymentStatusTransition', () async {
      final adapter = _newAdapter();
      final credential = StoredCredential(
        credentialId: 'cred-deploy',
        publicKey: _testPublicKey(),
        deploymentStatus: CredentialDeploymentStatus.pending,
        createdAt: 1700000000000,
      );
      await adapter.save(credential);

      await adapter.update(
        'cred-deploy',
        const StoredCredentialUpdate(
          deploymentStatus: CredentialDeploymentStatus.failed,
          deploymentError: 'Transaction rejected',
        ),
      );

      final failed = await adapter.get('cred-deploy');
      expect(failed, isNotNull);
      expect(failed!.deploymentStatus, CredentialDeploymentStatus.failed);
      expect(failed.deploymentError, 'Transaction rejected');

      await adapter.update(
        'cred-deploy',
        const StoredCredentialUpdate(
          deploymentStatus: CredentialDeploymentStatus.pending,
        ),
      );

      final retrying = await adapter.get('cred-deploy');
      expect(retrying, isNotNull);
      expect(retrying!.deploymentStatus, CredentialDeploymentStatus.pending);
      expect(retrying.deploymentError, 'Transaction rejected');
    });

    test('testDeleteThenReSave', () async {
      final adapter = _newAdapter();
      await adapter.save(_fullCredential(id: 'cred-lifecycle'));

      await adapter.delete('cred-lifecycle');
      expect(await adapter.get('cred-lifecycle'), isNull);

      final newCredential = StoredCredential(
        credentialId: 'cred-lifecycle',
        publicKey: _testPublicKey(seed: 99),
        contractId: 'NEW_CONTRACT',
        createdAt: 1700099000000,
        nickname: 'Reborn',
      );
      await adapter.save(newCredential);

      final retrieved = await adapter.get('cred-lifecycle');
      expect(retrieved, isNotNull);
      expect(retrieved!.contractId, 'NEW_CONTRACT');
      expect(retrieved.nickname, 'Reborn');
    });

    test('testUpdateAfterDeleteThrows', () async {
      final adapter = _newAdapter();
      await adapter.save(_fullCredential(id: 'cred-deleted'));

      await adapter.delete('cred-deleted');

      await expectLater(
        adapter.update(
          'cred-deleted',
          const StoredCredentialUpdate(nickname: 'Should fail'),
        ),
        throwsA(isA<CredentialNotFound>()),
      );
    });

    test('testClearThenAddNewCredentials', () async {
      final adapter = _newAdapter();
      await adapter.save(_fullCredential(id: 'cred-old-1'));
      await adapter.save(_fullCredential(id: 'cred-old-2'));

      await adapter.clear();

      await adapter.save(_minimalCredential(id: 'cred-new-1'));
      expect((await adapter.getAll()).length, 1);
      expect(await adapter.get('cred-new-1'), isNotNull);
      expect(await adapter.get('cred-old-1'), isNull);
    });

    test('testStoredSessionIsExpiredProperty', () {
      const expired = StoredSession(
        credentialId: 'cred',
        contractId: 'CONTRACT',
        connectedAt: 1000,
        expiresAt: 2000,
      );
      expect(expired.isExpired, isTrue,
          reason: 'Session expiring at epoch 2000ms should be expired');

      const valid = StoredSession(
        credentialId: 'cred',
        contractId: 'CONTRACT',
        connectedAt: 1700000000000,
        expiresAt: 9007199254740991,
      );
      expect(valid.isExpired, isFalse,
          reason:
              'Session expiring at Long.MAX_VALUE should not be expired');
    });

    test('testStoredCredentialEqualityWithSameData', () {
      final key = _testPublicKey(seed: 5);
      final cred1 = StoredCredential(
        credentialId: 'cred-eq',
        publicKey: Uint8List.fromList(key),
        contractId: 'CONTRACT',
        createdAt: 1700000000000,
        nickname: 'Test',
      );
      final cred2 = StoredCredential(
        credentialId: 'cred-eq',
        publicKey: Uint8List.fromList(key),
        contractId: 'CONTRACT',
        createdAt: 1700000000000,
        nickname: 'Test',
      );

      expect(cred1, equals(cred2),
          reason: 'Credentials with same content should be equal');
      expect(cred1.hashCode, cred2.hashCode,
          reason: 'Equal credentials should have same hashCode');
    });

    test('testStoredCredentialInequalityWithDifferentPublicKey', () {
      final cred1 = StoredCredential(
        credentialId: 'cred-neq',
        publicKey: _testPublicKey(seed: 1),
        createdAt: 1700000000000,
      );
      final cred2 = StoredCredential(
        credentialId: 'cred-neq',
        publicKey: _testPublicKey(seed: 2),
        createdAt: 1700000000000,
      );

      expect(cred1 == cred2, isFalse,
          reason:
              'Credentials with different public keys should not be equal');
    });

    test('testInMemoryStorageAdapterImplementsStorageAdapterInterface', () {
      final StorageAdapter adapter = InMemoryStorageAdapter();
      expect(adapter, isNotNull);
    });
  });

  group('SessionManager - in-scope cases', () {
    const contractId = 'CBCD1234AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';

    test('testStoredSession_expiresAtZero_isExpired', () {
      const session = StoredSession(
        credentialId: 'cred',
        contractId: contractId,
        connectedAt: 0,
        expiresAt: 0,
      );
      expect(session.isExpired, isTrue,
          reason: 'Session with expiresAt=0 should be expired');
    });

    test('testStoredSession_expiresAtMaxValue_notExpired', () {
      const session = StoredSession(
        credentialId: 'cred',
        contractId: contractId,
        connectedAt: 1700000000000,
        expiresAt: 9007199254740991,
      );
      expect(session.isExpired, isFalse,
          reason:
              'Session with expiresAt=Long.MAX_VALUE should not be expired');
    });

    test('testStoredSession_expiresAtInPast_isExpired', () {
      const session = StoredSession(
        credentialId: 'cred',
        contractId: contractId,
        connectedAt: 1000,
        expiresAt: 5000,
      );
      expect(session.isExpired, isTrue);
    });

    test('testStoredSession_allFieldsAccessible', () {
      const session = StoredSession(
        credentialId: 'cred-abc',
        contractId: 'CONTRACT-XYZ',
        connectedAt: 1700000000000,
        expiresAt: 1700604800000,
      );

      expect(session.credentialId, 'cred-abc');
      expect(session.contractId, 'CONTRACT-XYZ');
      expect(session.connectedAt, 1700000000000);
      expect(session.expiresAt, 1700604800000);
    });

    test('testStoredSession_equalityCheck', () {
      const session1 = StoredSession(
        credentialId: 'cred',
        contractId: 'CONTRACT',
        connectedAt: 1000,
        expiresAt: 2000,
      );
      const session2 = StoredSession(
        credentialId: 'cred',
        contractId: 'CONTRACT',
        connectedAt: 1000,
        expiresAt: 2000,
      );

      expect(session1, equals(session2));
      expect(session1.hashCode, session2.hashCode);
    });

    test('testSaveSession_thenRetrieve', () async {
      final storage = InMemoryStorageAdapter();

      const session = StoredSession(
        credentialId: 'cred-session',
        contractId: contractId,
        connectedAt: 1700000000000,
        expiresAt: 9007199254740991,
      );
      await storage.saveSession(session);

      final retrieved = await storage.getSession();
      expect(retrieved, isNotNull);
      expect(retrieved!.credentialId, 'cred-session');
      expect(retrieved.contractId, contractId);
    });

    test('testGetSession_noneExists_returnsNull', () async {
      final storage = InMemoryStorageAdapter();
      final result = await storage.getSession();
      expect(result, isNull);
    });

    test('testSaveSession_overwritesPreviousSession', () async {
      final storage = InMemoryStorageAdapter();

      const session1 = StoredSession(
        credentialId: 'cred-1',
        contractId: 'CONTRACT_1',
        connectedAt: 1700000000000,
        expiresAt: 9007199254740991,
      );
      await storage.saveSession(session1);

      const session2 = StoredSession(
        credentialId: 'cred-2',
        contractId: 'CONTRACT_2',
        connectedAt: 1700001000000,
        expiresAt: 9007199254740991,
      );
      await storage.saveSession(session2);

      final retrieved = await storage.getSession();
      expect(retrieved, isNotNull);
      expect(retrieved!.credentialId, 'cred-2');
      expect(retrieved.contractId, 'CONTRACT_2');
    });

    test('testClearSession_removesSession', () async {
      final storage = InMemoryStorageAdapter();

      await storage.saveSession(StoredSession(
        credentialId: 'cred',
        contractId: contractId,
        connectedAt: 1700000000000,
        expiresAt: 9007199254740991,
      ));

      await storage.clearSession();

      expect(await storage.getSession(), isNull);
    });

    test('testClearSession_whenNoneExists_noOp', () async {
      final storage = InMemoryStorageAdapter();
      await storage.clearSession();
      expect(await storage.getSession(), isNull);
    });

    test('testExpiredSession_autoClearedOnGet', () async {
      final storage = InMemoryStorageAdapter();

      const expiredSession = StoredSession(
        credentialId: 'expired-cred',
        contractId: 'CBCD1234AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
        connectedAt: 1000,
        expiresAt: 2000,
      );
      await storage.saveSession(expiredSession);

      final result = await storage.getSession();
      expect(result, isNull,
          reason: 'Expired session should return null');

      final secondResult = await storage.getSession();
      expect(secondResult, isNull,
          reason: 'Expired session should remain cleared');
    });

    test('testConfigSessionExpiryMs_default', () {
      final config = OZSmartAccountConfig(
        rpcUrl: 'https://soroban-testnet.stellar.org',
        networkPassphrase: 'Test SDF Network ; September 2015',
        accountWasmHash:
            'a000000000000000000000000000000000000000000000000000000000000000',
        webauthnVerifierAddress: _validVerifier,
      );

      expect(config.sessionExpiryMs, OZConstants.defaultSessionExpiryMs);
    });

    test('testConfigSessionExpiryMs_custom', () {
      const oneDayMs = 86400000;
      final config = OZSmartAccountConfig(
        rpcUrl: 'https://soroban-testnet.stellar.org',
        networkPassphrase: 'Test SDF Network ; September 2015',
        accountWasmHash:
            'a000000000000000000000000000000000000000000000000000000000000000',
        webauthnVerifierAddress: _validVerifier,
        sessionExpiryMs: oneDayMs,
      );

      expect(config.sessionExpiryMs, oneDayMs);
    });

    // Above-floor concurrency.
    test('test_concurrent_writes_10_parallel_no_partial_state', () async {
      const iterations = 100;
      for (var run = 0; run < iterations; run++) {
        final adapter = InMemoryStorageAdapter();
        const writerCount = 10;
        const id = 'cred-concurrent';

        final writes = <Future<void>>[];
        final expectedKeys = <int>[];
        for (var i = 0; i < writerCount; i++) {
          expectedKeys.add(i);
          writes.add(adapter.save(StoredCredential(
            credentialId: id,
            publicKey: _testPublicKey(seed: i),
            contractId: 'CONTRACT_$i',
            createdAt: 1700000000000 + i,
            nickname: 'writer-$i',
          )));
        }
        await Future.wait(writes);

        final retrieved = await adapter.get(id);
        expect(retrieved, isNotNull);

        // Recover which writer's payload "won" by matching nickname (a
        // bijection) and assert every other field matches that writer's
        // outputs bit-for-bit (no partial / torn state).
        final nick = retrieved!.nickname;
        expect(nick, isNotNull);
        expect(nick!.startsWith('writer-'), isTrue);
        final winner = int.parse(nick.substring('writer-'.length));
        expect(expectedKeys.contains(winner), isTrue);

        final expectedPubKey = _testPublicKey(seed: winner);
        expect(_bytesEqual(retrieved.publicKey, expectedPubKey), isTrue,
            reason: 'publicKey must match the winning writer ($winner)');
        expect(retrieved.contractId, 'CONTRACT_$winner',
            reason: 'contractId must match the winning writer ($winner)');
        expect(retrieved.createdAt, 1700000000000 + winner,
            reason: 'createdAt must match the winning writer ($winner)');

        final all = await adapter.getAll();
        expect(all.length, 1,
            reason: 'concurrent writes to the same key must not duplicate');
      }
    });
  });

  group('SessionManager - kit and storage lifecycle integration', () {
    // why: every kit-level test below builds the real `OZSmartAccountKit`
    // through `_makeKit(storage:)` so the assertions exercise the production
    // wiring (lock-protected state, eager-init managers, storage delegation)
    // rather than a mock seam.

    const String _validRpcUrl = 'https://soroban-testnet.stellar.org';
    const String _validVerifier =
        'CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM';
    const String _validWasmHash =
        'a000000000000000000000000000000000000000000000000000000000000000';
    const String _kitContractId =
        'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK';

    OZSmartAccountKit _makeKit({StorageAdapter? storage}) {
      final resolvedStorage = storage ?? InMemoryStorageAdapter();
      final config = OZSmartAccountConfig(
        rpcUrl: _validRpcUrl,
        networkPassphrase: 'Test SDF Network ; September 2015',
        accountWasmHash: _validWasmHash,
        webauthnVerifierAddress: _validVerifier,
        storage: resolvedStorage,
      );
      return OZSmartAccountKit.create(config: config);
    }

    /// Disconnect must remove the persisted [StoredSession] from storage even
    /// when the in-memory connection state has already been pre-seeded with a
    /// matching credential / contract pair. Asserts the storage-side effect
    /// in isolation: after `kit.disconnect()` the storage adapter's
    /// `getSession()` returns `null`.
    test('testKitDisconnect_clearsSession', () async {
      final storage = InMemoryStorageAdapter();
      final kit = _makeKit(storage: storage);

      const session = StoredSession(
        credentialId: 'session-cred',
        contractId: _kitContractId,
        connectedAt: 1700000000000,
        // why: a max-int expiry guarantees the session has not auto-cleared
        // through the storage's expiry check before disconnect runs.
        expiresAt: 9223372036854775807,
      );
      await storage.saveSession(session);

      await kit.setConnectedState(
        credentialId: 'session-cred',
        contractId: _kitContractId,
      );

      // Sanity check: the session is durable up to the disconnect call.
      final preDisconnect = await storage.getSession();
      expect(preDisconnect, isNotNull,
          reason: 'Session must be present before disconnect');

      await kit.disconnect();

      final postDisconnect = await storage.getSession();
      expect(postDisconnect, isNull,
          reason: 'Disconnect must remove the stored session');
    });

    /// Stored credentials and the active session live in independent storage
    /// slots. Saving / clearing one must not modify the other. Asserts the
    /// orthogonality contract that the OZ smart account relies on for
    /// credential persistence across disconnect/reconnect cycles.
    test('testSessionIndependentFromCredentials', () async {
      final storage = InMemoryStorageAdapter();
      // why: instantiating the kit eagerly initialises every manager and
      // wires storage through the production code path; the kit handle is
      // unused after construction because the assertions target storage.
      _makeKit(storage: storage);

      final credential = StoredCredential(
        credentialId: 'cred-shared',
        publicKey: _testPublicKey(seed: 1),
        contractId: _kitContractId,
        deploymentStatus: CredentialDeploymentStatus.pending,
        createdAt: 1700000000000,
        nickname: 'primary',
        isPrimary: true,
      );
      await storage.save(credential);

      const session = StoredSession(
        credentialId: 'cred-shared',
        contractId: _kitContractId,
        connectedAt: 1700000000000,
        expiresAt: 9223372036854775807,
      );
      await storage.saveSession(session);

      // Clearing the session must not delete the credential.
      await storage.clearSession();
      final credentialAfterSessionClear = await storage.get('cred-shared');
      expect(credentialAfterSessionClear, isNotNull,
          reason: 'Credential must survive session clear');
      expect(credentialAfterSessionClear!.contractId, equals(_kitContractId));
      expect(await storage.getSession(), isNull);

      // Re-save the session, then delete the credential.
      await storage.saveSession(session);
      await storage.delete('cred-shared');
      final sessionAfterCredentialDelete = await storage.getSession();
      expect(sessionAfterCredentialDelete, isNotNull,
          reason: 'Session must survive credential delete');
      expect(sessionAfterCredentialDelete!.credentialId, equals('cred-shared'));
      expect(await storage.get('cred-shared'), isNull);
    });

    /// Kit-level disconnect clears the persisted session but leaves every
    /// stored credential untouched. The credentials remain available for
    /// `OZWalletOperations.connectWallet()` to reconnect against.
    test('testClearSessionDoesNotAffectCredentials', () async {
      final storage = InMemoryStorageAdapter();
      final kit = _makeKit(storage: storage);

      final primaryCredential = StoredCredential(
        credentialId: 'cred-primary',
        publicKey: _testPublicKey(seed: 1),
        contractId: _kitContractId,
        deploymentStatus: CredentialDeploymentStatus.pending,
        createdAt: 1700000000000,
        nickname: 'primary',
        isPrimary: true,
      );
      final secondaryCredential = StoredCredential(
        credentialId: 'cred-secondary',
        publicKey: _testPublicKey(seed: 2),
        contractId: _kitContractId,
        deploymentStatus: CredentialDeploymentStatus.failed,
        createdAt: 1700000000001,
        nickname: 'secondary',
      );
      await storage.save(primaryCredential);
      await storage.save(secondaryCredential);

      const session = StoredSession(
        credentialId: 'cred-primary',
        contractId: _kitContractId,
        connectedAt: 1700000000000,
        expiresAt: 9223372036854775807,
      );
      await storage.saveSession(session);

      await kit.setConnectedState(
        credentialId: 'cred-primary',
        contractId: _kitContractId,
      );
      expect(kit.isConnected, isTrue);

      await kit.disconnect();

      // Session is gone.
      expect(await storage.getSession(), isNull);
      // Both credentials are still present and structurally intact.
      final allCredentials = await storage.getAll();
      expect(allCredentials.length, equals(2));
      final primaryAfter = await storage.get('cred-primary');
      final secondaryAfter = await storage.get('cred-secondary');
      expect(primaryAfter, isNotNull);
      expect(secondaryAfter, isNotNull);
      expect(primaryAfter!.deploymentStatus,
          equals(CredentialDeploymentStatus.pending));
      expect(primaryAfter.isPrimary, isTrue);
      expect(secondaryAfter!.deploymentStatus,
          equals(CredentialDeploymentStatus.failed));
      expect(secondaryAfter.contractId, equals(_kitContractId));
    });

    /// A freshly-constructed kit has no in-memory connection state. Asserts
    /// the public state accessors all reflect the disconnected baseline,
    /// which is the precondition every consumer relies on before invoking
    /// `connectWallet()` or `createWallet()`.
    test('testKitIsConnected_initiallyFalse', () async {
      final kit = _makeKit();

      expect(kit.isConnected, isFalse,
          reason: 'Fresh kit must not report a connection');
      expect(kit.credentialId, isNull,
          reason: 'Fresh kit must expose null credentialId');
      expect(kit.contractId, isNull,
          reason: 'Fresh kit must expose null contractId');
      await expectLater(
        () => kit.requireConnected(),
        throwsA(isA<WalletNotConnected>()),
      );
    });

    /// `setConnectedState` is the single source of truth for the kit's
    /// in-memory connection state. Asserts every public accessor
    /// (`isConnected`, `credentialId`, `contractId`, `requireConnected`) is
    /// updated consistently after a single write, and that subsequent writes
    /// overwrite without any residual state from the prior connection.
    test('testKitIsConnected_afterSetConnectedState', () async {
      final kit = _makeKit();

      const initialCredential = 'cred-initial';
      const initialContract = _kitContractId;
      await kit.setConnectedState(
        credentialId: initialCredential,
        contractId: initialContract,
      );

      expect(kit.isConnected, isTrue);
      expect(kit.credentialId, equals(initialCredential));
      expect(kit.contractId, equals(initialContract));
      final initialSnapshot = await kit.requireConnected();
      expect(initialSnapshot.credentialId, equals(initialCredential));
      expect(initialSnapshot.contractId, equals(initialContract));

      // Overwriting connection state must replace both fields atomically.
      const overwriteCredential = 'cred-overwrite';
      const overwriteContract =
          'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK';
      await kit.setConnectedState(
        credentialId: overwriteCredential,
        contractId: overwriteContract,
      );

      expect(kit.isConnected, isTrue);
      expect(kit.credentialId, equals(overwriteCredential));
      expect(kit.contractId, equals(overwriteContract));
      final overwriteSnapshot = await kit.requireConnected();
      expect(overwriteSnapshot.credentialId, equals(overwriteCredential));
      expect(overwriteSnapshot.contractId, equals(overwriteContract));
    });

    /// Disconnect when no wallet is connected must be a no-op: it does not
    /// throw, it does not flip `isConnected` (already false), and it must
    /// not emit a `walletDisconnected` event because no contract id is
    /// available to populate the payload. Asserts the documented "safe to
    /// call even when no wallet is connected" contract on the disconnect
    /// path, distinct from the connected-disconnect coverage in
    /// `oz_smart_account_kit_test.dart`.
    test('testKitIsConnected_afterDisconnect', () async {
      final storage = InMemoryStorageAdapter();
      final kit = _makeKit(storage: storage);

      expect(kit.isConnected, isFalse);

      var disconnectedFired = 0;
      kit.events.on<SmartAccountEventWalletDisconnected>(
        (_) => disconnectedFired++,
      );

      // Calling disconnect with no prior connection must succeed silently.
      await kit.disconnect();

      expect(kit.isConnected, isFalse);
      expect(kit.credentialId, isNull);
      expect(kit.contractId, isNull);
      expect(await storage.getSession(), isNull);
      expect(disconnectedFired, equals(0),
          reason:
              'Disconnect from idle state must not emit walletDisconnected');

      // A second disconnect from the same idle baseline is also a no-op.
      await kit.disconnect();
      expect(disconnectedFired, equals(0));
    });

    /// `requireConnected` throws [WalletNotConnected] whenever the kit's
    /// in-memory state has no credential / contract pair. The message must
    /// be the kit-level guidance pointing the caller at `createWallet()` /
    /// `connectWallet()`. Also asserts the post-disconnect transition
    /// produces the same error type, distinct from the initial-state
    /// coverage in `oz_smart_account_kit_test.dart`.
    test('testKitRequireConnected_throwsWhenNotConnected', () async {
      final kit = _makeKit();

      // Initial state — never connected.
      try {
        await kit.requireConnected();
        fail('requireConnected must throw when no wallet is connected');
      } on WalletNotConnected catch (e) {
        expect(
          e.message,
          equals(
            'No wallet connected. Call createWallet() or connectWallet() first.',
          ),
        );
      }

      // After a connect/disconnect round trip the same error must surface.
      await kit.setConnectedState(
        credentialId: 'cred',
        contractId: _kitContractId,
      );
      final connectedSnapshot = await kit.requireConnected();
      expect(connectedSnapshot.contractId, equals(_kitContractId));

      await kit.disconnect();
      try {
        await kit.requireConnected();
        fail('requireConnected must throw after disconnect');
      } on WalletNotConnected catch (e) {
        expect(
          e.message,
          equals(
            'No wallet connected. Call createWallet() or connectWallet() first.',
          ),
        );
      }
    });
  });
}
