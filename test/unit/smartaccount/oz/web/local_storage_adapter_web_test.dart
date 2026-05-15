// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.
//
// Browser-target tests for the localStorage-backed storage adapter. These
// run under `flutter test --platform chrome` only — on the Dart VM the
// test runner skips them via `@TestOn('browser')` because
// `dart:js_interop` types (and `package:web`) are not available off-target.

@TestOn('browser')
library;

import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/src/smartaccount/core/smart_account_errors.dart';
import 'package:stellar_flutter_sdk/src/smartaccount/oz/oz_storage_adapter.dart';
import 'package:stellar_flutter_sdk/src/smartaccount/oz/web/local_storage_adapter_web.dart';
import 'package:web/web.dart' as web;

/// Builds an in-memory Storage shim that conforms to the
/// [web.Storage] extension-type contract via a JS object whose
/// methods are wired to a Dart-side [Map]. The shim is structurally
/// indistinguishable from `window.localStorage` for the methods
/// [LocalStorageAdapter] uses.
web.Storage _makeFakeStorage({
  Map<String, String>? seed,
  bool throwQuotaExceeded = false,
  bool throwSecurityError = false,
}) {
  final store = <String, String>{};
  if (seed != null) store.addAll(seed);
  final obj = JSObject();

  obj.setProperty(
    'getItem'.toJS,
    ((JSString jsKey) {
      final value = store[jsKey.toDart];
      return value?.toJS;
    }).toJS,
  );

  obj.setProperty(
    'setItem'.toJS,
    ((JSString jsKey, JSString jsValue) {
      if (throwQuotaExceeded) {
        throw _domException(
          'QuotaExceededError',
          'localStorage quota exceeded',
        );
      }
      if (throwSecurityError) {
        throw _domException('SecurityError', 'Access denied');
      }
      store[jsKey.toDart] = jsValue.toDart;
    }).toJS,
  );

  obj.setProperty(
    'removeItem'.toJS,
    ((JSString jsKey) {
      store.remove(jsKey.toDart);
    }).toJS,
  );

  obj.setProperty(
    'clear'.toJS,
    (() {
      store.clear();
    }).toJS,
  );

  obj.setProperty(
    'key'.toJS,
    ((JSNumber index) {
      final i = index.toDartInt;
      if (i < 0 || i >= store.length) return null;
      return store.keys.elementAt(i).toJS;
    }).toJS,
  );

  obj.setProperty('length'.toJS, store.length.toJS);

  return obj as web.Storage;
}

JSObject _domException(String name, String message) {
  final obj = JSObject();
  obj.setProperty('name'.toJS, name.toJS);
  obj.setProperty('message'.toJS, message.toJS);
  return obj;
}

StoredCredential _credential({
  String credentialId = 'cred-1',
  String? contractId,
  bool isPrimary = false,
  int createdAt = 1_000_000,
  int? lastUsedAt,
  String? nickname,
  List<String>? transports,
  String? deviceType,
  bool? backedUp,
  CredentialDeploymentStatus deploymentStatus =
      CredentialDeploymentStatus.pending,
  String? deploymentError,
}) {
  return StoredCredential(
    credentialId: credentialId,
    publicKey: Uint8List.fromList(<int>[
      0x04,
      0x42,
      0x43,
      0x44,
      0x45,
      0x46,
      0x47,
      0x48,
    ]),
    contractId: contractId,
    isPrimary: isPrimary,
    createdAt: createdAt,
    lastUsedAt: lastUsedAt,
    nickname: nickname,
    transports: transports,
    deviceType: deviceType,
    backedUp: backedUp,
    deploymentStatus: deploymentStatus,
    deploymentError: deploymentError,
  );
}

StoredSession _session({
  String credentialId = 'cred-1',
  String contractId = 'CABCDEF',
  int connectedAt = 5_000,
  int expiresAt = 9_000_000_000_000,
}) =>
    StoredSession(
      credentialId: credentialId,
      contractId: contractId,
      connectedAt: connectedAt,
      expiresAt: expiresAt,
    );

void main() {
  group('LocalStorageAdapter (web)', () {
    test('test_save_and_get_credential_round_trip', () async {
      final adapter = LocalStorageAdapter.withStorage(
        storage: _makeFakeStorage(),
      );
      final cred = _credential();
      await adapter.save(cred);
      final loaded = await adapter.get(cred.credentialId);
      expect(loaded, isNotNull);
      expect(loaded!.credentialId, cred.credentialId);
      expect(loaded.publicKey, cred.publicKey);
    });

    test('test_save_and_get_session_round_trip', () async {
      final adapter = LocalStorageAdapter.withStorage(
        storage: _makeFakeStorage(),
      );
      final session = _session();
      await adapter.saveSession(session);
      final loaded = await adapter.getSession();
      expect(loaded, equals(session));
    });

    test('test_get_by_contract_id_filters', () async {
      final adapter = LocalStorageAdapter.withStorage(
        storage: _makeFakeStorage(),
      );
      await adapter.save(_credential(credentialId: 'a', contractId: 'X'));
      await adapter.save(_credential(credentialId: 'b', contractId: 'Y'));
      await adapter.save(_credential(credentialId: 'c', contractId: 'X'));
      final hits = await adapter.getByContract('X');
      expect(hits.map((c) => c.credentialId).toSet(), {'a', 'c'});
    });

    test('test_clear_removes_all', () async {
      final adapter = LocalStorageAdapter.withStorage(
        storage: _makeFakeStorage(),
      );
      await adapter.save(_credential(credentialId: 'a'));
      await adapter.save(_credential(credentialId: 'b'));
      await adapter.saveSession(_session());
      await adapter.clear();
      expect(await adapter.getAll(), isEmpty);
      expect(await adapter.getSession(), isNull);
    });

    test('test_quota_exceeded_error_handled', () async {
      final adapter = LocalStorageAdapter.withStorage(
        storage: _makeFakeStorage(throwQuotaExceeded: true),
      );
      await expectLater(
        adapter.save(_credential()),
        throwsA(
          isA<StorageWriteFailed>()
              .having((e) => e.cause.toString(), 'cause', contains('quota')),
        ),
      );
    });

    test('test_oversized_payload_rejected_5mb_cap', () async {
      // Reuse the quota path — the adapter cannot inspect payload size
      // directly; the browser raises QuotaExceededError when the cap is
      // reached.
      final adapter = LocalStorageAdapter.withStorage(
        storage: _makeFakeStorage(throwQuotaExceeded: true),
      );
      await expectLater(
        adapter.save(_credential()),
        throwsA(isA<StorageWriteFailed>()),
      );
    });

    test('test_concurrent_writes_no_partial_state', () async {
      final adapter = LocalStorageAdapter.withStorage(
        storage: _makeFakeStorage(),
      );
      final futures = <Future<void>>[];
      for (var i = 0; i < 10; i++) {
        futures.add(adapter.save(_credential(credentialId: 'cred-$i')));
      }
      await Future.wait(futures);
      final all = await adapter.getAll();
      expect(all.length, 10);
      expect(
        all.map((c) => c.credentialId).toSet(),
        List<int>.generate(10, (i) => i).map((i) => 'cred-$i').toSet(),
      );
    });

    test('test_credential_update_atomic', () async {
      final adapter = LocalStorageAdapter.withStorage(
        storage: _makeFakeStorage(),
      );
      await adapter.save(_credential());
      await adapter.update(
        'cred-1',
        const StoredCredentialUpdate(nickname: 'Touch ID'),
      );
      final loaded = await adapter.get('cred-1');
      expect(loaded?.nickname, 'Touch ID');
    });

    test('test_localstorage_unavailable_private_mode_error', () async {
      final fake = JSObject();
      JSAny? getItemImpl(JSString _) {
        throw _domException('SecurityError', 'denied');
      }

      void setItemImpl(JSString _, JSString __) {
        throw _domException('SecurityError', 'denied');
      }

      void removeItemImpl(JSString _) {
        throw _domException('SecurityError', 'denied');
      }

      JSAny? keyImpl(JSNumber _) => null;
      void clearImpl() {}

      fake.setProperty('getItem'.toJS, getItemImpl.toJS);
      fake.setProperty('setItem'.toJS, setItemImpl.toJS);
      fake.setProperty('removeItem'.toJS, removeItemImpl.toJS);
      fake.setProperty('clear'.toJS, clearImpl.toJS);
      fake.setProperty('key'.toJS, keyImpl.toJS);
      fake.setProperty('length'.toJS, 0.toJS);
      final adapter = LocalStorageAdapter.withStorage(
        storage: fake as web.Storage,
      );
      await expectLater(
        adapter.save(_credential()),
        throwsA(isA<StorageWriteFailed>()),
      );
    });

    test('test_save_credential_with_all_fields_populated', () async {
      final adapter = LocalStorageAdapter.withStorage(
        storage: _makeFakeStorage(),
      );
      final cred = _credential(
        credentialId: 'full',
        contractId: 'CABC',
        isPrimary: true,
        createdAt: 12345,
        lastUsedAt: 67890,
        nickname: 'YubiKey',
        transports: const ['usb', 'nfc'],
        deviceType: 'singleDevice',
        backedUp: false,
        deploymentStatus: CredentialDeploymentStatus.failed,
        deploymentError: 'Out of fee',
      );
      await adapter.save(cred);
      final loaded = await adapter.get('full');
      expect(loaded, equals(cred));
    });

    test('test_save_credential_with_minimal_fields', () async {
      final adapter = LocalStorageAdapter.withStorage(
        storage: _makeFakeStorage(),
      );
      final cred = StoredCredential(
        credentialId: 'min',
        publicKey: Uint8List.fromList(<int>[0x04, 0x01]),
      );
      await adapter.save(cred);
      final loaded = await adapter.get('min');
      expect(loaded?.credentialId, 'min');
      expect(loaded?.publicKey, cred.publicKey);
    });

    test('test_get_nonexistent_credential_returns_null', () async {
      final adapter = LocalStorageAdapter.withStorage(
        storage: _makeFakeStorage(),
      );
      expect(await adapter.get('missing'), isNull);
    });

    test('test_save_existing_credential_overwrites', () async {
      final adapter = LocalStorageAdapter.withStorage(
        storage: _makeFakeStorage(),
      );
      await adapter.save(_credential(nickname: 'Old'));
      await adapter.save(_credential(nickname: 'New'));
      final loaded = await adapter.get('cred-1');
      expect(loaded?.nickname, 'New');
    });

    test('test_delete_credential', () async {
      final adapter = LocalStorageAdapter.withStorage(
        storage: _makeFakeStorage(),
      );
      await adapter.save(_credential());
      await adapter.delete('cred-1');
      expect(await adapter.get('cred-1'), isNull);
    });

    test('test_delete_nonexistent_credential_does_not_throw', () async {
      final adapter = LocalStorageAdapter.withStorage(
        storage: _makeFakeStorage(),
      );
      await expectLater(adapter.delete('missing'), completes);
    });

    test('test_delete_removes_only_target_credential', () async {
      final adapter = LocalStorageAdapter.withStorage(
        storage: _makeFakeStorage(),
      );
      await adapter.save(_credential(credentialId: 'a'));
      await adapter.save(_credential(credentialId: 'b'));
      await adapter.delete('a');
      expect((await adapter.getAll()).map((c) => c.credentialId), ['b']);
    });

    test('test_get_all_empty_returns_empty_list', () async {
      final adapter = LocalStorageAdapter.withStorage(
        storage: _makeFakeStorage(),
      );
      expect(await adapter.getAll(), isEmpty);
    });

    test('test_get_all_with_multiple_credentials', () async {
      final adapter = LocalStorageAdapter.withStorage(
        storage: _makeFakeStorage(),
      );
      for (var i = 0; i < 5; i++) {
        await adapter.save(_credential(credentialId: 'c-$i'));
      }
      final all = await adapter.getAll();
      expect(all.length, 5);
    });

    test('test_get_by_contract_id_no_match_returns_empty_list', () async {
      final adapter = LocalStorageAdapter.withStorage(
        storage: _makeFakeStorage(),
      );
      await adapter.save(_credential(contractId: 'X'));
      expect(await adapter.getByContract('Y'), isEmpty);
    });

    test('test_update_nonexistent_credential_throws', () async {
      final adapter = LocalStorageAdapter.withStorage(
        storage: _makeFakeStorage(),
      );
      await expectLater(
        adapter.update('missing', const StoredCredentialUpdate()),
        throwsA(isA<CredentialNotFound>()),
      );
    });

    test('test_clear_on_empty_adapter_does_not_throw', () async {
      final adapter = LocalStorageAdapter.withStorage(
        storage: _makeFakeStorage(),
      );
      await expectLater(adapter.clear(), completes);
    });

    test('test_get_session_when_none_exists_returns_null', () async {
      final adapter = LocalStorageAdapter.withStorage(
        storage: _makeFakeStorage(),
      );
      expect(await adapter.getSession(), isNull);
    });

    test('test_save_session_overwrites_previous', () async {
      final adapter = LocalStorageAdapter.withStorage(
        storage: _makeFakeStorage(),
      );
      await adapter.saveSession(_session(contractId: 'OLD'));
      await adapter.saveSession(_session(contractId: 'NEW'));
      final loaded = await adapter.getSession();
      expect(loaded?.contractId, 'NEW');
    });

    test('test_expired_session_auto_cleared_on_get_session', () async {
      final storage = _makeFakeStorage();
      final adapter =
          LocalStorageAdapter.withStorage(storage: storage);
      // Manually inject an already-expired session.
      await adapter.saveSession(
        _session(connectedAt: 0, expiresAt: 1),
      );
      expect(await adapter.getSession(), isNull);
      // Verify the underlying storage no longer holds the session entry.
      expect(storage.getItem('stellar_sa_session_current'), isNull);
    });

    test('test_clear_session', () async {
      final adapter = LocalStorageAdapter.withStorage(
        storage: _makeFakeStorage(),
      );
      await adapter.saveSession(_session());
      await adapter.clearSession();
      expect(await adapter.getSession(), isNull);
    });

    test('test_clear_session_when_none_exists_does_not_throw', () async {
      final adapter = LocalStorageAdapter.withStorage(
        storage: _makeFakeStorage(),
      );
      await expectLater(adapter.clearSession(), completes);
    });

    test('test_get_by_contract_excludes_null_contract_id', () async {
      final adapter = LocalStorageAdapter.withStorage(
        storage: _makeFakeStorage(),
      );
      await adapter.save(_credential(credentialId: 'no-contract'));
      await adapter.save(
        _credential(credentialId: 'with-contract', contractId: 'C'),
      );
      final hits = await adapter.getByContract('C');
      expect(hits.map((c) => c.credentialId), ['with-contract']);
    });

    test('test_update_is_primary', () async {
      final adapter = LocalStorageAdapter.withStorage(
        storage: _makeFakeStorage(),
      );
      await adapter.save(_credential());
      await adapter.update(
        'cred-1',
        const StoredCredentialUpdate(isPrimary: true),
      );
      final loaded = await adapter.get('cred-1');
      expect(loaded?.isPrimary, isTrue);
    });

    test('test_update_transports', () async {
      final adapter = LocalStorageAdapter.withStorage(
        storage: _makeFakeStorage(),
      );
      await adapter.save(_credential());
      await adapter.update(
        'cred-1',
        const StoredCredentialUpdate(transports: ['internal', 'hybrid']),
      );
      final loaded = await adapter.get('cred-1');
      expect(loaded?.transports, ['internal', 'hybrid']);
    });

    test('test_update_contract_id', () async {
      final adapter = LocalStorageAdapter.withStorage(
        storage: _makeFakeStorage(),
      );
      await adapter.save(_credential());
      await adapter.update(
        'cred-1',
        const StoredCredentialUpdate(contractId: 'CXYZ'),
      );
      final loaded = await adapter.get('cred-1');
      expect(loaded?.contractId, 'CXYZ');
    });

    test('test_update_last_used_at', () async {
      final adapter = LocalStorageAdapter.withStorage(
        storage: _makeFakeStorage(),
      );
      await adapter.save(_credential());
      await adapter.update(
        'cred-1',
        const StoredCredentialUpdate(lastUsedAt: 999),
      );
      final loaded = await adapter.get('cred-1');
      expect(loaded?.lastUsedAt, 999);
    });

    test(
        'test_local_storage_adapter_implements_storage_adapter_interface',
        () {
      final adapter = LocalStorageAdapter.withStorage(
        storage: _makeFakeStorage(),
      );
      expect(adapter, isA<StorageAdapter>());
    });

    test('test_get_all_skips_corrupted_credentials', () async {
      final storage = _makeFakeStorage();
      final adapter = LocalStorageAdapter.withStorage(storage: storage);
      await adapter.save(_credential(credentialId: 'good'));
      // Inject corruption directly into the underlying storage by
      // adding a garbage entry that the index references.
      storage.setItem('stellar_sa_cred_index',
          jsonEncode(<String>['good', 'bad']));
      // Insert a fake credential entry whose JSON is not a valid object.
      const corruptKey = 'stellar_sa_cred_bad';
      storage.setItem(corruptKey, '"not-an-object"');
      final all = await adapter.getAll();
      expect(all.map((c) => c.credentialId), ['good']);
    });

    test('test_get_corrupted_credential_throws', () async {
      final storage = _makeFakeStorage();
      final adapter = LocalStorageAdapter.withStorage(storage: storage);
      // Direct read of a single corrupted credential surfaces the
      // deserialization failure as StorageReadFailed.
      const corruptKey = 'stellar_sa_cred_bad';
      storage.setItem(corruptKey, '{not-valid-json}');
      await expectLater(
        adapter.get('bad'),
        throwsA(isA<StorageReadFailed>()),
      );
    });
  });
}
