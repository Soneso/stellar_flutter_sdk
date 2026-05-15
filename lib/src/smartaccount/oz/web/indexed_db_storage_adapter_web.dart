// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:web/web.dart' as web;

import '../../core/smart_account_errors.dart';
import '../oz_storage_adapter.dart';

/// Storage adapter backed by the browser's IndexedDB API.
///
/// Recommended for production web applications. Provides structured
/// storage with indexing support, larger storage limits than
/// `localStorage`, and an async API that does not block the main thread.
///
/// Features:
/// - Upsert semantics for credential saves (uses IndexedDB `put`)
/// - Efficient contract ID lookups via an IndexedDB index
/// - Transactional integrity for every operation
/// - Automatic schema creation via `onupgradeneeded`
/// - Binary data support without JSON encoding overhead
///
/// Limitations:
/// - Data is not encrypted; any script on the same origin can read it.
///   Sensitive material such as private keys MUST NOT be persisted via
///   this adapter.
/// - Available only in browser environments. On non-web targets the
///   conditional-export wiring routes consumers to a stub that throws
///   [UnsupportedError] from each operation.
///
/// Schema:
/// - Object store `credentials`: keyPath `credentialId`, indexes on
///   `contractId`, `createdAt`, `isPrimary`.
/// - Object store `sessions`: keyPath `key`; the only session is stored
///   under sentinel key `current`.
//
// ignore: camel_case_types
class IndexedDBStorageAdapter implements StorageAdapter {
  /// Default IndexedDB database name.
  static const String defaultDbName = 'stellar_smart_account';

  /// Database schema version.
  static const int dbVersion = 1;

  /// Object store name for credential records.
  @visibleForTesting
  static const String storeCredentials = 'credentials';

  /// Object store name for the session record.
  @visibleForTesting
  static const String storeSessions = 'sessions';

  /// Index on the credential record's `contractId` field.
  @visibleForTesting
  static const String indexContractId = 'contractId';

  /// Index on the credential record's `createdAt` field.
  @visibleForTesting
  static const String indexCreatedAt = 'createdAt';

  /// Index on the credential record's `isPrimary` field.
  @visibleForTesting
  static const String indexIsPrimary = 'isPrimary';

  /// Sentinel key under which the current session record is stored.
  @visibleForTesting
  static const String sessionKey = 'current';

  /// Database name passed to `indexedDB.open`.
  final String dbName;

  /// Optional injected [web.IDBFactory] handle used by tests to drive the
  /// adapter against a fake IndexedDB implementation.
  final web.IDBFactory? _injectedFactory;

  web.IDBDatabase? _cachedDb;

  Future<void> _tail = Future<void>.value();

  /// Constructs an [IndexedDBStorageAdapter] backed by `window.indexedDB`.
  IndexedDBStorageAdapter({this.dbName = defaultDbName})
      : _injectedFactory = null;

  /// Constructs an [IndexedDBStorageAdapter] backed by an injected
  /// [web.IDBFactory]. Test seam — production code uses the unnamed
  /// constructor.
  @visibleForTesting
  IndexedDBStorageAdapter.withFactory({
    required web.IDBFactory factory,
    this.dbName = defaultDbName,
  }) : _injectedFactory = factory;

  // why: in-browser FIFO serialization without a runtime mutex package.
  // Every operation runs through `_withLock` so that interleaved IndexedDB
  // requests cannot observe a half-applied state. The per-call Completer
  // isolates body errors from the chain.
  Future<T> _withLock<T>(FutureOr<T> Function() body) {
    final completer = Completer<T>();
    final previous = _tail;
    _tail = previous.then((_) async {
      try {
        completer.complete(await body());
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    return completer.future;
  }

  // ---------------------------------------------------------------------------
  // Database lifecycle
  // ---------------------------------------------------------------------------

  Future<web.IDBDatabase> _getDb() async {
    final existing = _cachedDb;
    if (existing != null) return existing;
    final database = await _openDatabase();
    _cachedDb = database;
    return database;
  }

  Future<web.IDBDatabase> _openDatabase() {
    final completer = Completer<web.IDBDatabase>();
    final factory = _resolveFactory();
    if (factory == null) {
      completer.completeError(
        StorageException.readFailed(
          'indexedDB',
          cause: Exception(
            'IndexedDB is not available in this environment. '
            'IndexedDBStorageAdapter requires a browser environment.',
          ),
        ),
      );
      return completer.future;
    }

    final web.IDBOpenDBRequest request;
    try {
      request = factory.open(dbName, dbVersion);
    } on Object catch (e) {
      completer.completeError(
        StorageException.readFailed(
          'indexedDB:open',
          cause: Exception(
              "Failed to open IndexedDB '$dbName': ${e.toString()}"),
        ),
      );
      return completer.future;
    }

    request.onsuccess = ((web.Event _) {
      if (completer.isCompleted) return;
      final db = request.result;
      if (db is! web.IDBDatabase) {
        completer.completeError(
          StorageException.readFailed(
            'indexedDB:open',
            cause: Exception(
                "Failed to open IndexedDB '$dbName': result is not an IDBDatabase"),
          ),
        );
        return;
      }
      completer.complete(db);
    }).toJS;

    request.onerror = ((web.Event _) {
      if (completer.isCompleted) return;
      final errorMsg = request.error?.message ?? 'Unknown error';
      completer.completeError(
        StorageException.readFailed(
          'indexedDB:open',
          cause: Exception(
              "Failed to open IndexedDB '$dbName': $errorMsg"),
        ),
      );
    }).toJS;

    request.onupgradeneeded = ((web.Event _) {
      final db = request.result;
      if (db is web.IDBDatabase) {
        _createSchema(db);
      }
    }).toJS;

    return completer.future;
  }

  void _createSchema(web.IDBDatabase database) {
    final names = database.objectStoreNames;
    if (!_containsStoreName(names, storeCredentials)) {
      final credStore = database.createObjectStore(
        storeCredentials,
        web.IDBObjectStoreParameters(keyPath: 'credentialId'.toJS),
      );
      credStore.createIndex(
        indexContractId,
        indexContractId.toJS,
        web.IDBIndexParameters(unique: false),
      );
      credStore.createIndex(
        indexCreatedAt,
        indexCreatedAt.toJS,
        web.IDBIndexParameters(unique: false),
      );
      credStore.createIndex(
        indexIsPrimary,
        indexIsPrimary.toJS,
        web.IDBIndexParameters(unique: false),
      );
    }
    if (!_containsStoreName(names, storeSessions)) {
      database.createObjectStore(
        storeSessions,
        web.IDBObjectStoreParameters(keyPath: 'key'.toJS),
      );
    }
  }

  bool _containsStoreName(web.DOMStringList names, String name) {
    return names.contains(name);
  }

  /// Closes the database connection. After [close], the adapter reopens
  /// the database on the next operation. Safe to call multiple times.
  Future<void> close() {
    return _withLock<void>(() {
      final existing = _cachedDb;
      if (existing != null) {
        existing.close();
      }
      _cachedDb = null;
    });
  }

  // ---------------------------------------------------------------------------
  // Credential operations
  // ---------------------------------------------------------------------------

  @override
  Future<void> save(StoredCredential credential) {
    return _withLock<void>(() async {
      final database = await _getDb();
      final obj = _credentialToJs(credential);
      try {
        await _withObjectStore(
          database,
          storeCredentials,
          'readwrite',
          (store) => store.put(obj),
        );
      } on Object catch (e) {
        throw StorageException.writeFailed(
          'credential:${credential.credentialId}',
          cause: e is Exception ? e : Exception(e.toString()),
        );
      }
    });
  }

  @override
  Future<StoredCredential?> get(String credentialId) {
    return _withLock<StoredCredential?>(() async {
      final database = await _getDb();
      final JSAny? result;
      try {
        result = await _withObjectStore(
          database,
          storeCredentials,
          'readonly',
          (store) => store.get(credentialId.toJS),
        );
      } on Object catch (e) {
        throw StorageException.readFailed(
          'credential:$credentialId',
          cause: e is Exception ? e : Exception(e.toString()),
        );
      }
      if (result == null || !result.isA<JSObject>()) return null;
      return _jsToCredential(result as JSObject);
    });
  }

  @override
  Future<List<StoredCredential>> getByContract(String contractId) {
    return _withLock<List<StoredCredential>>(() async {
      final database = await _getDb();
      final JSAny? results;
      try {
        results = await _withIndex(
          database,
          storeCredentials,
          indexContractId,
          'readonly',
          (index) => index.getAll(contractId.toJS),
        );
      } on Object catch (e) {
        throw StorageException.readFailed(
          'credentials:contractId=$contractId',
          cause: e is Exception ? e : Exception(e.toString()),
        );
      }
      return _jsArrayToCredentials(results);
    });
  }

  @override
  Future<List<StoredCredential>> getAll() {
    return _withLock<List<StoredCredential>>(() async {
      final database = await _getDb();
      final JSAny? results;
      try {
        results = await _withObjectStore(
          database,
          storeCredentials,
          'readonly',
          (store) => store.getAll(),
        );
      } on Object catch (e) {
        throw StorageException.readFailed(
          'credentials:all',
          cause: e is Exception ? e : Exception(e.toString()),
        );
      }
      return _jsArrayToCredentials(results);
    });
  }

  @override
  Future<void> delete(String credentialId) {
    return _withLock<void>(() async {
      final database = await _getDb();
      try {
        await _withObjectStore(
          database,
          storeCredentials,
          'readwrite',
          (store) => store.delete(credentialId.toJS),
        );
      } on Object catch (e) {
        throw StorageException.writeFailed(
          'credential:$credentialId',
          cause: e is Exception ? e : Exception(e.toString()),
        );
      }
    });
  }

  @override
  Future<void> update(String credentialId, StoredCredentialUpdate updates) {
    return _withLock<void>(() async {
      final database = await _getDb();
      final JSAny? result;
      try {
        result = await _withObjectStore(
          database,
          storeCredentials,
          'readonly',
          (store) => store.get(credentialId.toJS),
        );
      } on Object catch (e) {
        throw StorageException.readFailed(
          'credential:$credentialId',
          cause: e is Exception ? e : Exception(e.toString()),
        );
      }
      if (result == null || !result.isA<JSObject>()) {
        throw CredentialException.notFound(credentialId);
      }
      final existing = _jsToCredential(result as JSObject);
      final updated = existing.applyUpdate(updates);
      final obj = _credentialToJs(updated);
      try {
        await _withObjectStore(
          database,
          storeCredentials,
          'readwrite',
          (store) => store.put(obj),
        );
      } on Object catch (e) {
        throw StorageException.writeFailed(
          'credential:$credentialId',
          cause: e is Exception ? e : Exception(e.toString()),
        );
      }
    });
  }

  @override
  Future<void> clear() {
    return _withLock<void>(() async {
      final database = await _getDb();
      try {
        await _withObjectStore(
          database,
          storeCredentials,
          'readwrite',
          (store) => store.clear(),
        );
      } on Object catch (e) {
        throw StorageException.writeFailed(
          'credentials:clear',
          cause: e is Exception ? e : Exception(e.toString()),
        );
      }
      await _clearSessionUnlocked(database);
    });
  }

  // ---------------------------------------------------------------------------
  // Session operations
  // ---------------------------------------------------------------------------

  @override
  Future<void> saveSession(StoredSession session) {
    return _withLock<void>(() async {
      final database = await _getDb();
      final obj = _sessionToJs(session);
      try {
        await _withObjectStore(
          database,
          storeSessions,
          'readwrite',
          (store) => store.put(obj),
        );
      } on Object catch (e) {
        throw StorageException.writeFailed(
          'session',
          cause: e is Exception ? e : Exception(e.toString()),
        );
      }
    });
  }

  @override
  Future<StoredSession?> getSession() {
    return _withLock<StoredSession?>(() async {
      final database = await _getDb();
      final JSAny? result;
      try {
        result = await _withObjectStore(
          database,
          storeSessions,
          'readonly',
          (store) => store.get(sessionKey.toJS),
        );
      } on Object catch (e) {
        throw StorageException.readFailed(
          'session',
          cause: e is Exception ? e : Exception(e.toString()),
        );
      }
      if (result == null || !result.isA<JSObject>()) return null;
      final session = _jsToSession(result as JSObject);
      if (session.isExpired) {
        await _clearSessionUnlocked(database);
        return null;
      }
      return session;
    });
  }

  @override
  Future<void> clearSession() {
    return _withLock<void>(() async {
      final database = await _getDb();
      await _clearSessionUnlocked(database);
    });
  }

  /// Deletes the session record without acquiring [_withLock]. Must only
  /// be called from inside a lock-held body.
  Future<void> _clearSessionUnlocked(web.IDBDatabase database) async {
    try {
      await _withObjectStore(
        database,
        storeSessions,
        'readwrite',
        (store) => store.delete(sessionKey.toJS),
      );
    } on Object catch (e) {
      throw StorageException.writeFailed(
        'session:clear',
        cause: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Database deletion
  // ---------------------------------------------------------------------------

  /// Deletes the entire IndexedDB database identified by [name] (or the
  /// adapter's configured [dbName] when [name] is `null`). Destructive:
  /// removes every stored credential and session permanently.
  Future<void> deleteDatabase({String? name}) async {
    final target = name ?? dbName;
    await close();
    final completer = Completer<void>();
    final factory = _resolveFactory();
    if (factory == null) {
      completer.completeError(
        StorageException.writeFailed(
          'indexedDB:delete',
          cause: Exception('IndexedDB is not available'),
        ),
      );
      return completer.future;
    }
    final web.IDBOpenDBRequest request;
    try {
      request = factory.deleteDatabase(target);
    } on Object catch (e) {
      completer.completeError(
        StorageException.writeFailed(
          'indexedDB:delete',
          cause: Exception(
              "Failed to delete database '$target': ${e.toString()}"),
        ),
      );
      return completer.future;
    }
    request.onsuccess = ((web.Event _) {
      if (completer.isCompleted) return;
      completer.complete();
    }).toJS;
    request.onerror = ((web.Event _) {
      if (completer.isCompleted) return;
      final errorMsg = request.error?.message ?? 'Unknown error';
      completer.completeError(
        StorageException.writeFailed(
          'indexedDB:delete',
          cause: Exception(
              "Failed to delete database '$target': $errorMsg"),
        ),
      );
    }).toJS;
    return completer.future;
  }

  // ---------------------------------------------------------------------------
  // Transaction helpers
  // ---------------------------------------------------------------------------

  Future<JSAny?> _withObjectStore(
    web.IDBDatabase database,
    String storeName,
    String mode,
    web.IDBRequest Function(web.IDBObjectStore store) block,
  ) {
    final completer = Completer<JSAny?>();
    web.IDBRequest request;
    try {
      final transaction = database.transaction(storeName.toJS, mode);
      final store = transaction.objectStore(storeName);
      request = block(store);
    } on Object catch (e) {
      completer.completeError(e);
      return completer.future;
    }
    request.onsuccess = ((web.Event _) {
      if (completer.isCompleted) return;
      completer.complete(request.result);
    }).toJS;
    request.onerror = ((web.Event _) {
      if (completer.isCompleted) return;
      final errorMsg = request.error?.message ?? 'IndexedDB operation failed';
      completer.completeError(Exception(errorMsg));
    }).toJS;
    return completer.future;
  }

  Future<JSAny?> _withIndex(
    web.IDBDatabase database,
    String storeName,
    String indexName,
    String mode,
    web.IDBRequest Function(web.IDBIndex index) block,
  ) {
    final completer = Completer<JSAny?>();
    web.IDBRequest request;
    try {
      final transaction = database.transaction(storeName.toJS, mode);
      final store = transaction.objectStore(storeName);
      final index = store.index(indexName);
      request = block(index);
    } on Object catch (e) {
      completer.completeError(e);
      return completer.future;
    }
    request.onsuccess = ((web.Event _) {
      if (completer.isCompleted) return;
      completer.complete(request.result);
    }).toJS;
    request.onerror = ((web.Event _) {
      if (completer.isCompleted) return;
      final errorMsg =
          request.error?.message ?? 'IndexedDB index query failed';
      completer.completeError(Exception(errorMsg));
    }).toJS;
    return completer.future;
  }

  // ---------------------------------------------------------------------------
  // JS object conversion
  // ---------------------------------------------------------------------------

  JSObject _credentialToJs(StoredCredential credential) {
    final obj = JSObject();
    obj.setProperty('credentialId'.toJS, credential.credentialId.toJS);
    obj.setProperty('publicKey'.toJS, _byteArrayToJs(credential.publicKey));
    obj.setProperty(
      'contractId'.toJS,
      credential.contractId == null ? null : credential.contractId!.toJS,
    );
    obj.setProperty(
      'deploymentStatus'.toJS,
      credential.deploymentStatus.name.toJS,
    );
    obj.setProperty(
      'deploymentError'.toJS,
      credential.deploymentError == null
          ? null
          : credential.deploymentError!.toJS,
    );
    obj.setProperty('createdAt'.toJS, credential.createdAt.toJS);
    obj.setProperty(
      'lastUsedAt'.toJS,
      credential.lastUsedAt == null ? null : credential.lastUsedAt!.toJS,
    );
    obj.setProperty(
      'nickname'.toJS,
      credential.nickname == null ? null : credential.nickname!.toJS,
    );
    obj.setProperty('isPrimary'.toJS, credential.isPrimary.toJS);
    obj.setProperty(
      'transports'.toJS,
      credential.transports == null
          ? null
          : credential.transports!.map((t) => t.toJS).toList().toJS,
    );
    obj.setProperty(
      'deviceType'.toJS,
      credential.deviceType == null ? null : credential.deviceType!.toJS,
    );
    obj.setProperty(
      'backedUp'.toJS,
      credential.backedUp == null ? null : credential.backedUp!.toJS,
    );
    return obj;
  }

  StoredCredential _jsToCredential(JSObject obj) {
    final credentialId =
        (obj.getProperty<JSString>('credentialId'.toJS)).toDart;
    final publicKey =
        _jsArrayToByteArray(obj.getProperty<JSAny?>('publicKey'.toJS));
    final contractIdRaw = obj.getProperty<JSAny?>('contractId'.toJS);
    final contractId =
        contractIdRaw is JSString ? contractIdRaw.toDart : null;
    final statusName =
        (obj.getProperty<JSString>('deploymentStatus'.toJS)).toDart;
    final deploymentStatus = _statusFromName(statusName);
    final deploymentErrorRaw = obj.getProperty<JSAny?>('deploymentError'.toJS);
    final deploymentError = deploymentErrorRaw is JSString
        ? deploymentErrorRaw.toDart
        : null;
    final createdAt = _jsToInt(obj.getProperty<JSAny?>('createdAt'.toJS))!;
    final lastUsedAt = _jsToInt(obj.getProperty<JSAny?>('lastUsedAt'.toJS));
    final nicknameRaw = obj.getProperty<JSAny?>('nickname'.toJS);
    final nickname = nicknameRaw is JSString ? nicknameRaw.toDart : null;
    final isPrimary =
        (obj.getProperty<JSBoolean>('isPrimary'.toJS)).toDart;
    final transportsRaw = obj.getProperty<JSAny?>('transports'.toJS);
    List<String>? transports;
    if (transportsRaw is JSArray) {
      transports = transportsRaw.toDart
          .map((e) => (e as JSString).toDart)
          .toList(growable: false);
    }
    final deviceTypeRaw = obj.getProperty<JSAny?>('deviceType'.toJS);
    final deviceType =
        deviceTypeRaw is JSString ? deviceTypeRaw.toDart : null;
    final backedUpRaw = obj.getProperty<JSAny?>('backedUp'.toJS);
    final backedUp = backedUpRaw is JSBoolean ? backedUpRaw.toDart : null;
    return StoredCredential(
      credentialId: credentialId,
      publicKey: publicKey,
      contractId: contractId,
      deploymentStatus: deploymentStatus,
      deploymentError: deploymentError,
      createdAt: createdAt,
      lastUsedAt: lastUsedAt,
      nickname: nickname,
      isPrimary: isPrimary,
      transports: transports,
      deviceType: deviceType,
      backedUp: backedUp,
    );
  }

  JSObject _sessionToJs(StoredSession session) {
    final obj = JSObject();
    obj.setProperty('key'.toJS, sessionKey.toJS);
    obj.setProperty('credentialId'.toJS, session.credentialId.toJS);
    obj.setProperty('contractId'.toJS, session.contractId.toJS);
    obj.setProperty('connectedAt'.toJS, session.connectedAt.toJS);
    obj.setProperty('expiresAt'.toJS, session.expiresAt.toJS);
    return obj;
  }

  StoredSession _jsToSession(JSObject obj) {
    return StoredSession(
      credentialId:
          (obj.getProperty<JSString>('credentialId'.toJS)).toDart,
      contractId: (obj.getProperty<JSString>('contractId'.toJS)).toDart,
      connectedAt: _jsToInt(obj.getProperty<JSAny?>('connectedAt'.toJS))!,
      expiresAt: _jsToInt(obj.getProperty<JSAny?>('expiresAt'.toJS))!,
    );
  }

  /// Converts a [Uint8List] to a JS `Array<number>`. IndexedDB's
  /// structured-clone algorithm preserves either typed arrays or plain
  /// number arrays; the SDK uses plain arrays for cross-target on-disk
  /// shape stability.
  JSArray<JSNumber> _byteArrayToJs(Uint8List bytes) {
    final list = <JSNumber>[];
    for (final byte in bytes) {
      list.add((byte & 0xFF).toJS);
    }
    return list.toJS;
  }

  /// Converts a JS array (either `Array<number>` or `Uint8Array`) into a
  /// [Uint8List]. Accepts both forms because IndexedDB may surface the
  /// stored bytes as either depending on the originating writer.
  Uint8List _jsArrayToByteArray(JSAny? value) {
    if (value == null) return Uint8List(0);
    if (value.isA<JSUint8Array>()) {
      return (value as JSUint8Array).toDart;
    }
    if (value.isA<JSArray>()) {
      final array = (value as JSArray).toDart;
      final bytes = Uint8List(array.length);
      for (var i = 0; i < array.length; i++) {
        final element = array[i];
        if (element is JSNumber) {
          bytes[i] = element.toDartInt & 0xFF;
        } else {
          throw const FormatException(
            'IndexedDB credential publicKey array contains non-numeric element',
          );
        }
      }
      return bytes;
    }
    throw const FormatException(
      'IndexedDB credential publicKey field is neither a typed array nor a '
      'plain JS array',
    );
  }

  List<StoredCredential> _jsArrayToCredentials(JSAny? value) {
    if (value == null || !value.isA<JSArray>()) {
      return const <StoredCredential>[];
    }
    final array = (value as JSArray).toDart;
    final result = List<StoredCredential>.generate(
      array.length,
      (i) => _jsToCredential(array[i] as JSObject),
      growable: false,
    );
    return result;
  }

  CredentialDeploymentStatus _statusFromName(String name) {
    for (final status in CredentialDeploymentStatus.values) {
      if (status.name == name) return status;
    }
    throw ArgumentError.value(
      name,
      'deploymentStatus',
      'Unknown CredentialDeploymentStatus name',
    );
  }

  /// Reads an integer from a JS value that may be a [JSNumber] or
  /// `null` / `undefined`. Returns `null` when the field is absent.
  int? _jsToInt(JSAny? value) {
    if (value == null) return null;
    if (value is JSNumber) return value.toDartInt;
    return null;
  }

  // ---------------------------------------------------------------------------
  // Environment guard
  // ---------------------------------------------------------------------------

  web.IDBFactory? _resolveFactory() {
    final injected = _injectedFactory;
    if (injected != null) return injected;
    try {
      return web.window.indexedDB;
    } on Object {
      return null;
    }
  }
}
