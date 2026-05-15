// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:convert/convert.dart' as convert;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channelName =
      'com.soneso.stellar_flutter_sdk/smartaccount/storage.test';

  late MethodChannel channel;
  late List<MethodCall> recordedCalls;
  late Object? Function(MethodCall call) handler;

  setUp(() {
    channel = const MethodChannel(channelName);
    recordedCalls = <MethodCall>[];
    handler = (MethodCall call) => null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      recordedCalls.add(call);
      return handler(call);
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  PlatformStorageAdapter newAdapter() =>
      PlatformStorageAdapter(methodChannel: channel);

  Uint8List bytes(List<int> values) => Uint8List.fromList(values);

  StoredCredential sampleCredential({
    String id = 'cred-001',
    String? contractId = 'CBCD0000000000000000000000000000000000000000000000000000',
    bool primary = true,
  }) {
    return StoredCredential(
      credentialId: id,
      publicKey: bytes(List<int>.generate(65, (i) => i & 0xff)),
      contractId: contractId,
      deploymentStatus: CredentialDeploymentStatus.pending,
      createdAt: 1700000000000,
      lastUsedAt: 1700001000000,
      nickname: 'Test Device',
      isPrimary: primary,
      transports: const <String>['internal'],
      deviceType: 'multiDevice',
      backedUp: true,
    );
  }

  Map<String, Object?> credentialJson(StoredCredential credential) {
    return <String, Object?>{
      'credentialId': credential.credentialId,
      'publicKeyHex': convert.hex.encode(credential.publicKey),
      if (credential.contractId != null) 'contractId': credential.contractId,
      'deploymentStatus': credential.deploymentStatus.name,
      if (credential.deploymentError != null)
        'deploymentError': credential.deploymentError,
      'createdAt': credential.createdAt,
      if (credential.lastUsedAt != null) 'lastUsedAt': credential.lastUsedAt,
      if (credential.nickname != null) 'nickname': credential.nickname,
      'isPrimary': credential.isPrimary,
      if (credential.transports != null)
        'transports': List<String>.from(credential.transports!),
      if (credential.deviceType != null) 'deviceType': credential.deviceType,
      if (credential.backedUp != null) 'backedUp': credential.backedUp,
    };
  }

  Map<String, Object?> sessionJson(StoredSession session) {
    return <String, Object?>{
      'credentialId': session.credentialId,
      'contractId': session.contractId,
      'connectedAt': session.connectedAt,
      'expiresAt': session.expiresAt,
    };
  }

  group('save / get', () {
    test('save round trip marshals credential map', () async {
      final credential = sampleCredential();
      handler = (call) {
        expect(call.method, 'storage.save');
        final args = (call.arguments as Map).cast<String, Object?>();
        final wire = (args['credential'] as Map).cast<String, Object?>();
        expect(wire['credentialId'], 'cred-001');
        expect(wire['publicKeyHex'], isA<String>());
        expect(wire['contractId'], isNotNull);
        expect(wire['deploymentStatus'], 'pending');
        expect(wire['isPrimary'], true);
        expect(wire['transports'], <String>['internal']);
        return null;
      };

      await newAdapter().save(credential);
      expect(recordedCalls, hasLength(1));
    });

    test('get returns typed credential when present', () async {
      final credential = sampleCredential();
      handler = (call) {
        expect(call.method, 'storage.get');
        final args = (call.arguments as Map).cast<String, Object?>();
        expect(args['credentialId'], 'cred-001');
        return credentialJson(credential);
      };

      final loaded = await newAdapter().get('cred-001');
      expect(loaded, equals(credential));
    });

    test('get returns null when not found', () async {
      handler = (call) => null;

      final loaded = await newAdapter().get('missing-credential');
      expect(loaded, isNull);
    });
  });

  group('getByContract / getAll', () {
    test('getByContract filters', () async {
      final c1 = sampleCredential(id: 'cred-1');
      final c2 = sampleCredential(id: 'cred-2');
      handler = (call) {
        expect(call.method, 'storage.getByContract');
        final args = (call.arguments as Map).cast<String, Object?>();
        expect(args['contractId'], isNotEmpty);
        return <Object?>[credentialJson(c1), credentialJson(c2)];
      };

      final loaded = await newAdapter().getByContract(c1.contractId!);
      expect(loaded, hasLength(2));
      expect(loaded.map((c) => c.credentialId), <String>['cred-1', 'cred-2']);
    });

    test('getAll returns empty list when none', () async {
      handler = (call) {
        expect(call.method, 'storage.getAll');
        return <Object?>[];
      };

      final loaded = await newAdapter().getAll();
      expect(loaded, isEmpty);
    });
  });

  group('delete / clear', () {
    test('delete invokes storage.delete channel', () async {
      handler = (call) {
        expect(call.method, 'storage.delete');
        final args = (call.arguments as Map).cast<String, Object?>();
        expect(args['credentialId'], 'cred-001');
        return null;
      };

      await newAdapter().delete('cred-001');
      expect(recordedCalls, hasLength(1));
    });

    test('clear invokes storage.clear channel', () async {
      handler = (call) {
        expect(call.method, 'storage.clear');
        return null;
      };

      await newAdapter().clear();
      expect(recordedCalls, hasLength(1));
    });
  });

  group('update', () {
    test('marshals partial updates only non null fields', () async {
      handler = (call) {
        expect(call.method, 'storage.update');
        final args = (call.arguments as Map).cast<String, Object?>();
        expect(args['credentialId'], 'cred-001');
        final updates = (args['updates'] as Map).cast<String, Object?>();
        expect(updates['contractId'], 'C-NEW');
        expect(updates['lastUsedAt'], 1700002000000);
        expect(updates['transports'], <String>['internal', 'hybrid']);
        expect(updates.containsKey('isPrimary'), false);
        expect(updates.containsKey('deploymentError'), false);
        return null;
      };

      await newAdapter().update(
        'cred-001',
        const StoredCredentialUpdate(
          contractId: 'C-NEW',
          lastUsedAt: 1700002000000,
          transports: <String>['internal', 'hybrid'],
        ),
      );
    });

    test('CREDENTIAL_NOT_FOUND rethrows typed', () async {
      handler = (call) {
        throw PlatformException(
          code: 'CREDENTIAL_NOT_FOUND',
          message: 'Credential not found: cred-001',
        );
      };

      try {
        await newAdapter().update(
          'cred-001',
          const StoredCredentialUpdate(nickname: 'New nickname'),
        );
        fail('expected CredentialNotFound');
      } on CredentialNotFound catch (e) {
        expect(e.code.code, 3001);
        expect(e.message, contains('cred-001'));
        expect(e.cause, isA<PlatformException>());
      }
    });

    test('STORAGE_READ_FAILED for corruption rethrows typed', () async {
      handler = (call) {
        throw PlatformException(
          code: 'STORAGE_READ_FAILED',
          message: 'Corrupted JSON during update',
        );
      };

      try {
        await newAdapter().update(
          'cred-001',
          const StoredCredentialUpdate(nickname: 'New'),
        );
        fail('expected StorageReadFailed');
      } on StorageReadFailed catch (e) {
        expect(e.code.code, 8001);
        expect(e.message, contains('credential:cred-001'));
      }
    });
  });

  group('session operations', () {
    test('save session round trip', () async {
      final session = StoredSession(
        credentialId: 'cred-1',
        contractId: 'CBCD000',
        connectedAt: 1700000000000,
        expiresAt: 1700604800000,
      );
      handler = (call) {
        if (call.method == 'storage.saveSession') {
          final args = (call.arguments as Map).cast<String, Object?>();
          final wire = (args['session'] as Map).cast<String, Object?>();
          expect(wire['credentialId'], 'cred-1');
          expect(wire['contractId'], 'CBCD000');
          expect(wire['connectedAt'], 1700000000000);
          expect(wire['expiresAt'], 1700604800000);
          return null;
        }
        if (call.method == 'storage.getSession') {
          return sessionJson(session);
        }
        fail('unexpected method ${call.method}');
      };

      final adapter = newAdapter();
      await adapter.saveSession(session);
      final loaded = await adapter.getSession();
      expect(loaded, equals(session));
    });

    test('get session auto cleared expired returns null', () async {
      // The native handler is responsible for the auto-clear behaviour and
      // returns `null` to the bridge. The bridge surfaces `null` as no
      // session.
      handler = (call) {
        expect(call.method, 'storage.getSession');
        return null;
      };

      final loaded = await newAdapter().getSession();
      expect(loaded, isNull);
    });
  });
}
