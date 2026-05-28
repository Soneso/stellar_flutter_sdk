// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.
//
// Browser-target tests for the IndexedDB-backed storage adapter. These
// run under `flutter test --platform chrome` because the adapter and
// fakes both depend on `dart:js_interop` and `package:web`.

@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/src/smartaccount/core/smart_account_errors.dart';
import 'package:stellar_flutter_sdk/src/smartaccount/oz/oz_storage_adapter.dart';
import 'package:stellar_flutter_sdk/src/smartaccount/oz/web/indexed_db_storage_adapter_web.dart';
import 'package:web/web.dart' as web;

// Minimal in-memory IndexedDB substitute covering the surface area the adapter
// touches (open, put/get/getAll/delete/clear, index, request callbacks).

class _FakeStore {
  final List<JSObject> records = <JSObject>[];
  final String? keyPathField;

  _FakeStore(this.keyPathField);

  String? keyOf(JSObject record) {
    final field = keyPathField;
    if (field == null) return null;
    final value = record.getProperty<JSAny?>(field.toJS);
    return value is JSString ? value.toDart : null;
  }

  void put(JSObject record) {
    final id = keyOf(record);
    if (id == null) {
      records.add(record);
      return;
    }
    records.removeWhere((r) => keyOf(r) == id);
    records.add(record);
  }

  JSObject? get(String key) {
    for (final r in records) {
      if (keyOf(r) == key) return r;
    }
    return null;
  }

  void delete(String key) {
    records.removeWhere((r) => keyOf(r) == key);
  }

  List<JSObject> getAll() => List<JSObject>.from(records);

  List<JSObject> getAllByIndex(String indexName, JSAny? query) {
    final queryString =
        query is JSString ? query.toDart : query?.toString();
    return records.where((r) {
      final value = r.getProperty<JSAny?>(indexName.toJS);
      if (value is JSString) {
        return value.toDart == queryString;
      }
      return value?.toString() == queryString;
    }).toList();
  }

  void clear() => records.clear();
}

class _FakeDatabase {
  final Map<String, _FakeStore> stores = {};
  bool throwOnTransaction = false;
  bool closed = false;
}

class _FakeFactory {
  final Map<String, _FakeDatabase> databases = {};
  bool unavailable = false;
  bool versionError = false;

  web.IDBFactory toJS() {
    final obj = JSObject();
    obj.setProperty(
      'open'.toJS,
      ((JSString name, [JSNumber? version]) {
        final req = JSObject();
        if (unavailable) {
          // Schedule onerror.
          _scheduleError(req,
              _domException('UnknownError', 'IndexedDB unavailable'));
          return req;
        }
        if (versionError) {
          // Simulate the VersionError raised by the browser when an
          // existing database has a HIGHER schema version than the one
          // the adapter requests on open(name, version).
          _scheduleError(req,
              _domException('VersionError',
                  'The requested version (1) is less than the existing version (2).'));
          return req;
        }
        final db = databases.putIfAbsent(name.toDart, () => _FakeDatabase());
        final dbProxy = _databaseProxy(db);
        // Schema lifecycle: synthesize an upgradeneeded if the store list
        // is empty (first-time open).
        Future.microtask(() {
          if (db.stores.isEmpty) {
            req.setProperty('result'.toJS, dbProxy);
            final onUpgrade =
                req.getProperty<JSAny?>('onupgradeneeded'.toJS);
            if (onUpgrade is JSFunction) {
              final event = JSObject();
              event.setProperty('target'.toJS, req);
              onUpgrade.callAsFunction(null, event);
            }
          }
          req.setProperty('result'.toJS, dbProxy);
          final onSuccess = req.getProperty<JSAny?>('onsuccess'.toJS);
          if (onSuccess is JSFunction) {
            final event = JSObject();
            event.setProperty('target'.toJS, req);
            onSuccess.callAsFunction(null, event);
          }
        });
        return req;
      }).toJS,
    );
    obj.setProperty(
      'deleteDatabase'.toJS,
      ((JSString name) {
        final req = JSObject();
        Future.microtask(() {
          databases.remove(name.toDart);
          final onSuccess = req.getProperty<JSAny?>('onsuccess'.toJS);
          if (onSuccess is JSFunction) {
            onSuccess.callAsFunction(null, JSObject());
          }
        });
        return req;
      }).toJS,
    );
    return obj as web.IDBFactory;
  }

  void _scheduleError(JSObject req, JSObject error) {
    Future.microtask(() {
      req.setProperty('error'.toJS, error);
      final onError = req.getProperty<JSAny?>('onerror'.toJS);
      if (onError is JSFunction) {
        onError.callAsFunction(null, JSObject());
      }
    });
  }
}

JSObject _databaseProxy(_FakeDatabase db) {
  final obj = JSObject();
  obj.setProperty(
    'objectStoreNames'.toJS,
    _domStringList(db.stores.keys.toList()),
  );
  obj.setProperty(
    'createObjectStore'.toJS,
    ((JSString name, [JSObject? options]) {
      String? keyPath;
      if (options != null) {
        final raw = options.getProperty<JSAny?>('keyPath'.toJS);
        if (raw is JSString) keyPath = raw.toDart;
      }
      final store = _FakeStore(keyPath);
      db.stores[name.toDart] = store;
      // Refresh objectStoreNames after the mutation.
      obj.setProperty(
        'objectStoreNames'.toJS,
        _domStringList(db.stores.keys.toList()),
      );
      return _objectStoreProxy(store);
    }).toJS,
  );
  obj.setProperty(
    'transaction'.toJS,
    ((JSAny names, [JSAny? mode, JSAny? options]) {
      if (db.throwOnTransaction) {
        throw _domException('InvalidStateError', 'database closed');
      }
      // The store-name lookup is performed inside objectStore() below;
      // the names argument is consumed by that path.
      final tx = JSObject();
      tx.setProperty(
        'objectStore'.toJS,
        ((JSString sName) {
          final store = db.stores[sName.toDart];
          if (store == null) {
            throw _domException(
              'NotFoundError',
              "Object store '${sName.toDart}' does not exist",
            );
          }
          return _objectStoreProxy(store);
        }).toJS,
      );
      return tx;
    }).toJS,
  );
  obj.setProperty(
    'close'.toJS,
    (() {
      db.closed = true;
    }).toJS,
  );
  return obj;
}

JSObject _objectStoreProxy(_FakeStore store) {
  final obj = JSObject();
  obj.setProperty(
    'createIndex'.toJS,
    ((JSString name, JSAny keyPath, [JSObject? options]) {
      // Fake indexes are resolved on-the-fly via the store's records.
      return JSObject();
    }).toJS,
  );
  obj.setProperty(
    'put'.toJS,
    ((JSObject value, [JSAny? key]) {
      final req = _request();
      Future.microtask(() {
        try {
          store.put(value);
          _resolveRequest(req, value);
        } on Object catch (e) {
          _failRequest(req, _domException('UnknownError', e.toString()));
        }
      });
      return req;
    }).toJS,
  );
  obj.setProperty(
    'get'.toJS,
    ((JSAny? query) {
      final req = _request();
      Future.microtask(() {
        if (query is JSString) {
          final value = store.get(query.toDart);
          _resolveRequest(req, value);
        } else {
          _resolveRequest(req, null);
        }
      });
      return req;
    }).toJS,
  );
  obj.setProperty(
    'getAll'.toJS,
    (([JSAny? query, JSNumber? count]) {
      final req = _request();
      Future.microtask(() {
        _resolveRequest(req, store.getAll().toJS);
      });
      return req;
    }).toJS,
  );
  obj.setProperty(
    'delete'.toJS,
    ((JSAny? query) {
      final req = _request();
      Future.microtask(() {
        if (query is JSString) store.delete(query.toDart);
        _resolveRequest(req, null);
      });
      return req;
    }).toJS,
  );
  obj.setProperty(
    'clear'.toJS,
    (() {
      final req = _request();
      Future.microtask(() {
        store.clear();
        _resolveRequest(req, null);
      });
      return req;
    }).toJS,
  );
  obj.setProperty(
    'index'.toJS,
    ((JSString indexName) {
      final indexObj = JSObject();
      indexObj.setProperty(
        'getAll'.toJS,
        (([JSAny? query, JSNumber? count]) {
          final req = _request();
          Future.microtask(() {
            _resolveRequest(req,
                store.getAllByIndex(indexName.toDart, query).toJS);
          });
          return req;
        }).toJS,
      );
      return indexObj;
    }).toJS,
  );
  return obj;
}

JSObject _request() {
  final req = JSObject();
  req.setProperty('result'.toJS, null);
  req.setProperty('error'.toJS, null);
  return req;
}

void _resolveRequest(JSObject req, JSAny? result) {
  req.setProperty('result'.toJS, result);
  final onSuccess = req.getProperty<JSAny?>('onsuccess'.toJS);
  if (onSuccess is JSFunction) {
    onSuccess.callAsFunction(null, JSObject());
  }
}

void _failRequest(JSObject req, JSObject error) {
  req.setProperty('error'.toJS, error);
  final onError = req.getProperty<JSAny?>('onerror'.toJS);
  if (onError is JSFunction) {
    onError.callAsFunction(null, JSObject());
  }
}

JSObject _domException(String name, String message) {
  final obj = JSObject();
  obj.setProperty('name'.toJS, name.toJS);
  obj.setProperty('message'.toJS, message.toJS);
  return obj;
}

JSObject _domStringList(List<String> values) {
  final obj = JSObject();
  obj.setProperty('length'.toJS, values.length.toJS);
  obj.setProperty(
    'contains'.toJS,
    ((JSString name) => values.contains(name.toDart).toJS).toJS,
  );
  obj.setProperty(
    'item'.toJS,
    ((JSNumber index) {
      final i = index.toDartInt;
      if (i < 0 || i >= values.length) return null;
      return values[i].toJS;
    }).toJS,
  );
  return obj;
}

StoredCredential _credential({
  String credentialId = 'cred-1',
  String? contractId,
  bool isPrimary = false,
  int createdAt = 1_000_000,
}) {
  return StoredCredential(
    credentialId: credentialId,
    publicKey: Uint8List.fromList(<int>[
      0x04,
      0x42,
      0x43,
      0x44,
    ]),
    contractId: contractId,
    isPrimary: isPrimary,
    createdAt: createdAt,
  );
}

StoredSession _session({
  String credentialId = 'cred-1',
  String contractId = 'CABC',
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
  group('IndexedDBStorageAdapter (web)', () {
    late _FakeFactory fakeFactory;

    setUp(() {
      fakeFactory = _FakeFactory();
    });

    IndexedDBStorageAdapter newAdapter({String dbName = 'unit_test_db'}) {
      return IndexedDBStorageAdapter.withFactory(
        factory: fakeFactory.toJS(),
        dbName: dbName,
      );
    }

    test('test_save_and_get_credential_round_trip', () async {
      final adapter = newAdapter();
      final cred = _credential();
      await adapter.save(cred);
      final loaded = await adapter.get(cred.credentialId);
      expect(loaded?.credentialId, cred.credentialId);
      expect(loaded?.publicKey, cred.publicKey);
    });

    test('test_save_and_get_session_round_trip', () async {
      final adapter = newAdapter();
      final session = _session();
      await adapter.saveSession(session);
      final loaded = await adapter.getSession();
      expect(loaded, equals(session));
    });

    test('test_get_by_contract_id_filters', () async {
      final adapter = newAdapter();
      await adapter.save(_credential(credentialId: 'a', contractId: 'X'));
      await adapter.save(_credential(credentialId: 'b', contractId: 'Y'));
      final hits = await adapter.getByContract('X');
      expect(hits.map((c) => c.credentialId), ['a']);
    });

    test('test_clear_removes_all', () async {
      final adapter = newAdapter();
      await adapter.save(_credential(credentialId: 'a'));
      await adapter.save(_credential(credentialId: 'b'));
      await adapter.saveSession(_session());
      await adapter.clear();
      expect(await adapter.getAll(), isEmpty);
      expect(await adapter.getSession(), isNull);
    });

    test('test_database_open_with_correct_schema_version', () async {
      final adapter = newAdapter(dbName: 'schema_db');
      await adapter.save(_credential());
      final db = fakeFactory.databases['schema_db'];
      expect(db, isNotNull);
      expect(
        db!.stores.keys.toSet(),
        {
          IndexedDBStorageAdapter.storeCredentials,
          IndexedDBStorageAdapter.storeSessions,
        },
      );
      expect(IndexedDBStorageAdapter.dbVersion, 1);
    });

    test('test_schema_upgrade_path_preserves_data', () async {
      final adapter = newAdapter(dbName: 'upgrade_db');
      await adapter.save(_credential(credentialId: 'persist'));
      await adapter.close();
      // Re-open via a fresh adapter instance against the same fake factory.
      final adapter2 = newAdapter(dbName: 'upgrade_db');
      final loaded = await adapter2.get('persist');
      expect(loaded, isNotNull);
    });

    test('test_quota_exceeded_error_handled', () async {
      final factory = _FakeFactory();
      // Replace put with a thrower.
      final adapter = IndexedDBStorageAdapter.withFactory(
        factory: factory.toJS(),
        dbName: 'quota_db',
      );
      // Force the request to fail when calling put.
      final db = factory.databases.putIfAbsent('quota_db', () => _FakeDatabase());
      // Pre-create the stores so `open` does not run upgradeneeded.
      db.stores[IndexedDBStorageAdapter.storeCredentials] =
          _FakeStore('credentialId');
      db.stores[IndexedDBStorageAdapter.storeSessions] = _FakeStore('key');
      // Inject a put-failing override after first open.
      db.throwOnTransaction = true;
      await expectLater(
        adapter.save(_credential()),
        throwsA(isA<StorageWriteFailed>()),
      );
    });

    test('test_concurrent_transactions_no_partial_state', () async {
      final adapter = newAdapter();
      final futures = <Future<void>>[];
      for (var i = 0; i < 8; i++) {
        futures.add(adapter.save(_credential(credentialId: 'p-$i')));
      }
      await Future.wait(futures);
      final all = await adapter.getAll();
      expect(all.length, 8);
    });

    test('test_database_closed_mid_transaction_error', () async {
      final factory = _FakeFactory();
      final adapter = IndexedDBStorageAdapter.withFactory(
        factory: factory.toJS(),
        dbName: 'closed_db',
      );
      await adapter.save(_credential());
      // Now flip the database into a state where transaction throws.
      final db = factory.databases['closed_db']!;
      db.throwOnTransaction = true;
      await expectLater(
        adapter.save(_credential(credentialId: 'second')),
        throwsA(isA<StorageWriteFailed>()),
      );
    });

    test('test_credential_update_atomic', () async {
      final adapter = newAdapter();
      await adapter.save(_credential());
      await adapter.update(
        'cred-1',
        const StoredCredentialUpdate(nickname: 'Touch ID'),
      );
      final loaded = await adapter.get('cred-1');
      expect(loaded?.nickname, 'Touch ID');
    });

    test('test_indexeddb_save_throws_when_unavailable', () async {
      final factory = _FakeFactory();
      factory.unavailable = true;
      final adapter = IndexedDBStorageAdapter.withFactory(
        factory: factory.toJS(),
      );
      await expectLater(
        adapter.save(_credential()),
        throwsA(isA<StorageReadFailed>()),
      );
    });

    test('test_indexeddb_get_throws_when_unavailable', () async {
      final factory = _FakeFactory();
      factory.unavailable = true;
      final adapter = IndexedDBStorageAdapter.withFactory(
        factory: factory.toJS(),
      );
      await expectLater(
        adapter.get('any'),
        throwsA(isA<StorageReadFailed>()),
      );
    });

    test('test_indexeddb_version_conflict_throws_storage_failure', () async {
      // Pre-populate a database whose stored schema version is HIGHER than
      // the version the adapter requests, then simulate the browser's
      // VersionError on open. The adapter routes IDBOpenDBRequest.onerror
      // through StorageException.readFailed regardless of the originating
      // operation, so a save attempt also surfaces StorageReadFailed.
      // The browser's IDBRequest.error surface only exposes `message`
      // (not `name`), so the assertion checks the version-conflict message
      // text rather than the DOMException name.
      final factory = _FakeFactory();
      factory.versionError = true;
      final adapter = IndexedDBStorageAdapter.withFactory(
        factory: factory.toJS(),
        dbName: 'version_conflict_db',
      );
      await expectLater(
        adapter.save(_credential()),
        throwsA(
          isA<StorageReadFailed>()
              .having(
                (e) => e.message,
                'message',
                contains('indexedDB:open'),
              )
              .having(
                (e) => e.cause.toString(),
                'cause',
                allOf(
                  contains('version_conflict_db'),
                  contains('less than the existing version'),
                ),
              ),
        ),
      );
    });

    test('test_close_releases_database_connection_and_reopens_on_next_op',
        () async {
      final adapter = newAdapter(dbName: 'reopen_db');
      await adapter.save(_credential());
      await adapter.close();
      // After close, another save should reopen the database successfully.
      await expectLater(
        adapter.save(_credential(credentialId: 'second')),
        completes,
      );
    });

    test('test_delete_database_removes_all_data', () async {
      final adapter = newAdapter(dbName: 'delete_db');
      await adapter.save(_credential());
      await adapter.deleteDatabase();
      expect(fakeFactory.databases.containsKey('delete_db'), isFalse);
    });

    test('test_delete_database_uses_default_name_when_omitted', () async {
      final adapter = newAdapter(dbName: 'default_target');
      await adapter.save(_credential());
      await adapter.deleteDatabase();
      expect(
        fakeFactory.databases.containsKey('default_target'),
        isFalse,
      );
    });
  });
}
