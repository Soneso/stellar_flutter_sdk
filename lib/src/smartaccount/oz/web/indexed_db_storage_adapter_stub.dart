// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import '../oz_storage_adapter.dart';

/// Non-web stub of [IndexedDBStorageAdapter].
///
/// Selected on targets without `dart:js_interop`. Construction succeeds and
/// [close] is a no-op so cross-target code can call lifecycle methods
/// unconditionally during shutdown. Storage operations and
/// [deleteDatabase] throw [UnsupportedError] because they depend on the
/// browser-only IndexedDB API.
//
// ignore: camel_case_types
class IndexedDBStorageAdapter implements StorageAdapter {
  /// Default IndexedDB database name used by the browser implementation.
  static const String defaultDbName = 'stellar_smart_account';

  /// Database schema version used by the browser implementation.
  static const int dbVersion = 1;

  /// Database name (matches the value the browser implementation would
  /// have used had this code been executing on a web target).
  final String dbName;

  /// Constructs an [IndexedDBStorageAdapter] stub.
  IndexedDBStorageAdapter({this.dbName = defaultDbName});

  Never _unsupported() => throw UnsupportedError(
        'IndexedDBStorageAdapter is only available on Flutter web. '
        'On non-web targets supply a platform-appropriate StorageAdapter '
        '(e.g. a Keychain-backed implementation on iOS, an '
        'EncryptedSharedPreferences-backed implementation on Android, or '
        'InMemoryStorageAdapter for testing).',
      );

  @override
  Future<void> save(StoredCredential credential) async => _unsupported();

  @override
  Future<StoredCredential?> get(String credentialId) async => _unsupported();

  @override
  Future<List<StoredCredential>> getByContract(String contractId) async =>
      _unsupported();

  @override
  Future<List<StoredCredential>> getAll() async => _unsupported();

  @override
  Future<void> delete(String credentialId) async => _unsupported();

  @override
  Future<void> update(String credentialId, StoredCredentialUpdate updates) async =>
      _unsupported();

  @override
  Future<void> clear() async => _unsupported();

  @override
  Future<void> saveSession(StoredSession session) async => _unsupported();

  @override
  Future<StoredSession?> getSession() async => _unsupported();

  @override
  Future<void> clearSession() async => _unsupported();

  /// Closes the database connection. No-op on the stub because no
  /// connection is ever opened on non-web targets; safe to call from
  /// cross-target shutdown code.
  Future<void> close() async {}

  /// Deletes the named database. Always throws [UnsupportedError] on
  /// non-web targets — there is no database to delete, so calling this
  /// outside the web target indicates a wiring bug worth surfacing.
  Future<void> deleteDatabase({String? name}) async => _unsupported();
}
