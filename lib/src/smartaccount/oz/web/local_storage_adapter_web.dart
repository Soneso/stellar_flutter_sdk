// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:meta/meta.dart';
import 'package:web/web.dart' as web;

import '../../core/smart_account_errors.dart';
import '../oz_storage_adapter.dart';
import '../oz_storage_serialization.dart';

/// Storage adapter backed by the browser's `localStorage` API.
///
/// Provides persistent credential and session storage that survives page
/// reloads and browser restarts. Data is serialized as JSON and byte
/// arrays are encoded as lowercase hex strings via the existing SDK hex
/// helpers.
///
/// Limitations:
/// - Storage is limited to approximately 5 MB per origin.
/// - Data is not encrypted; any script on the same origin can read it.
/// - Available only in browser environments. On non-web targets the
///   conditional-export wiring routes consumers to a stub that throws
///   [UnsupportedError] from each operation.
///
/// For production web applications consider [IndexedDBStorageAdapter]
/// instead — it scales beyond the per-origin localStorage cap and
/// supports indexed contract-ID lookups.
///
/// Storage key scheme:
/// - Credentials: `{prefix}cred_{credentialId}` (credentialId is the
///   raw WebAuthn base64URL-safe identifier)
/// - Credential index: `{prefix}credential_index`
/// - Session: `{prefix}session_current`
class LocalStorageAdapter implements StorageAdapter {
  /// Default key prefix for localStorage entries.
  static const String defaultKeyPrefix = 'stellar_sa_';

  static const String _credKeyPrefix = 'cred_';
  static const String _credIndexKey = 'credential_index';
  static const String _sessionKey = 'session_current';

  /// Prefix prepended to every localStorage key written by this adapter.
  final String keyPrefix;

  /// Optional injected [web.Storage] handle used by tests to drive the
  /// adapter against a fake storage backend without depending on
  /// `window.localStorage`.
  final web.Storage? _injectedStorage;

  Future<void> _tail = Future<void>.value();

  /// Constructs a [LocalStorageAdapter] backed by `window.localStorage`.
  LocalStorageAdapter({this.keyPrefix = defaultKeyPrefix})
      : _injectedStorage = null;

  /// Constructs a [LocalStorageAdapter] backed by an injected
  /// [web.Storage]. Test seam — production code uses the unnamed
  /// constructor.
  @visibleForTesting
  LocalStorageAdapter.withStorage({
    required web.Storage storage,
    this.keyPrefix = defaultKeyPrefix,
  }) : _injectedStorage = storage;

  // why: in-browser FIFO serialization without a runtime mutex package.
  // We chain every call onto `_tail` so requests run strictly in arrival
  // order; the per-call `Completer` isolates body-thrown errors from the
  // chain itself, so a single failed write does not poison subsequent
  // calls.
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
  // Credential operations
  // ---------------------------------------------------------------------------

  @override
  Future<void> save(StoredCredential credential) {
    return _withLock<void>(() {
      final storage = _requireLocalStorage();
      try {
        final json = _serializeCredential(credential);
        final key = _credentialKey(credential.credentialId);
        storage.setItem(key, json);
        _addToIndex(storage, credential.credentialId);
      } on Object catch (e) {
        final messageStr = _readJsErrorMessage(e) ?? 'Unknown error';
        if (messageStr.toLowerCase().contains('quota')) {
          throw StorageException.writeFailed(
            'credential:${credential.credentialId}',
            cause: Exception('localStorage quota exceeded: $messageStr'),
          );
        }
        throw StorageException.writeFailed(
          'credential:${credential.credentialId}',
          cause: Exception(messageStr),
        );
      }
    });
  }

  @override
  Future<StoredCredential?> get(String credentialId) {
    return _withLock<StoredCredential?>(() {
      final storage = _requireLocalStorage();
      final key = _credentialKey(credentialId);
      final json = storage.getItem(key);
      if (json == null) return null;
      try {
        return _deserializeCredential(json);
      } on Object catch (e) {
        throw StorageException.readFailed(
          'credential:$credentialId',
          cause: Exception(
            _readJsErrorMessage(e) ?? 'Failed to deserialize credential',
          ),
        );
      }
    });
  }

  @override
  Future<List<StoredCredential>> getByContract(String contractId) {
    return _withLock<List<StoredCredential>>(() {
      final storage = _requireLocalStorage();
      final index = _readIndex(storage);
      final result = <StoredCredential>[];
      for (final id in index) {
        final key = _credentialKey(id);
        final json = storage.getItem(key);
        if (json == null) continue;
        try {
          final cred = _deserializeCredential(json);
          if (cred.contractId == contractId) {
            result.add(cred);
          }
        } on Object catch (e) {
          final message = _readJsErrorMessage(e) ?? 'unknown error';
          developer.log(
            "LocalStorageAdapter: corrupted credential data for '$id', "
            'skipping: $message',
            name: 'LocalStorageAdapter',
            level: 900,
          );
        }
      }
      return List<StoredCredential>.unmodifiable(result);
    });
  }

  @override
  Future<List<StoredCredential>> getAll() {
    return _withLock<List<StoredCredential>>(() {
      final storage = _requireLocalStorage();
      final index = _readIndex(storage);
      final result = <StoredCredential>[];
      for (final credentialId in index) {
        final key = _credentialKey(credentialId);
        final json = storage.getItem(key);
        if (json == null) continue;
        try {
          result.add(_deserializeCredential(json));
        } on Object catch (e) {
          final message = _readJsErrorMessage(e) ?? 'unknown error';
          developer.log(
            "LocalStorageAdapter: corrupted credential data for "
            "'$credentialId', skipping: $message",
            name: 'LocalStorageAdapter',
            level: 900,
          );
        }
      }
      return List<StoredCredential>.unmodifiable(result);
    });
  }

  @override
  Future<void> delete(String credentialId) {
    return _withLock<void>(() {
      final storage = _requireLocalStorage();
      final key = _credentialKey(credentialId);
      storage.removeItem(key);
      _removeFromIndex(storage, credentialId);
    });
  }

  @override
  Future<void> update(String credentialId, StoredCredentialUpdate updates) {
    return _withLock<void>(() {
      final storage = _requireLocalStorage();
      final key = _credentialKey(credentialId);
      final json = storage.getItem(key);
      if (json == null) {
        throw CredentialException.notFound(credentialId);
      }
      StoredCredential existing;
      try {
        existing = _deserializeCredential(json);
      } on Object catch (e) {
        throw StorageException.readFailed(
          'credential:$credentialId',
          cause: Exception(
            _readJsErrorMessage(e) ?? 'Failed to deserialize credential',
          ),
        );
      }
      final updated = existing.applyUpdate(updates);
      final updatedJson = _serializeCredential(updated);
      try {
        storage.setItem(key, updatedJson);
      } on Object catch (e) {
        final message = _readJsErrorMessage(e) ?? 'Unknown error';
        throw StorageException.writeFailed(
          'credential:$credentialId',
          cause: Exception(message),
        );
      }
    });
  }

  @override
  Future<void> clear() {
    return _withLock<void>(() {
      final storage = _requireLocalStorage();
      final index = _readIndex(storage);
      for (final credentialId in index) {
        storage.removeItem(_credentialKey(credentialId));
      }
      storage.removeItem(_prefixedKey(_credIndexKey));
      _clearSessionUnlocked(storage);
    });
  }

  // ---------------------------------------------------------------------------
  // Session operations
  // ---------------------------------------------------------------------------

  @override
  Future<void> saveSession(StoredSession session) {
    return _withLock<void>(() {
      final storage = _requireLocalStorage();
      try {
        final json = _serializeSession(session);
        storage.setItem(_prefixedKey(_sessionKey), json);
      } on Object catch (e) {
        final message = _readJsErrorMessage(e) ?? 'Unknown error';
        throw StorageException.writeFailed(
          'session',
          cause: Exception(message),
        );
      }
    });
  }

  @override
  Future<StoredSession?> getSession() {
    return _withLock<StoredSession?>(() {
      final storage = _requireLocalStorage();
      final json = storage.getItem(_prefixedKey(_sessionKey));
      if (json == null) return null;
      try {
        final session = _deserializeSession(json);
        if (session.isExpired) {
          _clearSessionUnlocked(storage);
          return null;
        }
        return session;
      } on Object catch (e) {
        throw StorageException.readFailed(
          'session',
          cause: Exception(
            _readJsErrorMessage(e) ?? 'Failed to deserialize session',
          ),
        );
      }
    });
  }

  @override
  Future<void> clearSession() {
    return _withLock<void>(() {
      _clearSessionUnlocked(_requireLocalStorage());
    });
  }

  /// Removes the session entry without acquiring [_withLock]. Must only
  /// be called from inside a lock-held body.
  void _clearSessionUnlocked(web.Storage storage) {
    storage.removeItem(_prefixedKey(_sessionKey));
  }

  // ---------------------------------------------------------------------------
  // Key helpers
  // ---------------------------------------------------------------------------

  String _prefixedKey(String suffix) => '$keyPrefix$suffix';

  // why: credential ids are WebAuthn base64URL-safe identifiers, so they
  // can be embedded directly in a localStorage key. Consumers can locate
  // their per-credential entries under `<keyPrefix><cred_><credentialId>`.
  String _credentialKey(String credentialId) =>
      _prefixedKey('$_credKeyPrefix$credentialId');

  // ---------------------------------------------------------------------------
  // Index management
  // ---------------------------------------------------------------------------

  List<String> _readIndex(web.Storage storage) {
    final indexKey = _prefixedKey(_credIndexKey);
    final raw = storage.getItem(indexKey);
    if (raw == null) return const <String>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <String>[];
      return decoded.map((e) => e as String).toList(growable: false);
    } on Object {
      return const <String>[];
    }
  }

  void _writeIndex(web.Storage storage, List<String> index) {
    final indexKey = _prefixedKey(_credIndexKey);
    storage.setItem(indexKey, jsonEncode(index));
  }

  void _addToIndex(web.Storage storage, String credentialId) {
    final index = List<String>.from(_readIndex(storage));
    if (!index.contains(credentialId)) {
      index.add(credentialId);
    }
    _writeIndex(storage, index);
  }

  void _removeFromIndex(web.Storage storage, String credentialId) {
    final index = List<String>.from(_readIndex(storage));
    index.remove(credentialId);
    _writeIndex(storage, index);
  }

  // ---------------------------------------------------------------------------
  // Environment guard (Guard 1 from the security checklist)
  // ---------------------------------------------------------------------------

  web.Storage _requireLocalStorage() {
    final injected = _injectedStorage;
    if (injected != null) return injected;
    try {
      return web.window.localStorage;
    } on Object {
      throw StorageException.readFailed(
        'localStorage',
        cause: Exception(
          'localStorage is not available in this environment. '
          'LocalStorageAdapter requires a browser environment.',
        ),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// JSON serialization helpers (file-private)
// ---------------------------------------------------------------------------

String _serializeCredential(StoredCredential credential) {
  return jsonEncode(credential.toSerializable().toJson());
}

StoredCredential _deserializeCredential(String json) {
  final decoded = jsonDecode(json);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException(
      'Stored credential JSON is not an object',
    );
  }
  return SerializableCredential.fromJson(decoded).toStoredCredential();
}

String _serializeSession(StoredSession session) {
  return jsonEncode(session.toSerializable().toJson());
}

StoredSession _deserializeSession(String json) {
  final decoded = jsonDecode(json);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException(
      'Stored session JSON is not an object',
    );
  }
  return SerializableSession.fromJson(decoded).toStoredSession();
}

/// Reads the `message` property from a JS-thrown error, returning `null`
/// when the value is absent, not a string, or unreachable.
String? _readJsErrorMessage(Object error) {
  if (error is SmartAccountException) return error.message;
  if (error is Exception || error is Error) {
    return error.toString();
  }
  if (error is JSObject) {
    try {
      final value = error.getProperty<JSAny?>('message'.toJS);
      if (value is JSString) {
        return value.toDart;
      }
    } on Object {
      // Fall through.
    }
  }
  return error.toString();
}
