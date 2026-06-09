// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import '../oz_storage_adapter.dart';

/// Non-web stub of [OZLocalStorageAdapter].
///
/// Selected on targets without `dart:js_interop` (Dart VM, Flutter
/// mobile/desktop). Construction succeeds so consumer code can declare a
/// shared adapter handle that is overridden with a platform-specific
/// adapter at wiring time. Every storage operation throws
/// [UnsupportedError] with guidance toward an alternative.
class OZLocalStorageAdapter implements OZStorageAdapter {
  /// Default key prefix used for entries written by the browser
  /// implementation. Exposed so cross-target code can reference the same
  /// constant on either target.
  static const String defaultKeyPrefix = 'stellar_sa_';

  /// Prefix prepended to every storage key.
  final String keyPrefix;

  /// Constructs a [OZLocalStorageAdapter] stub with the given [keyPrefix].
  OZLocalStorageAdapter({this.keyPrefix = defaultKeyPrefix});

  Never _unsupported() => throw UnsupportedError(
        'OZLocalStorageAdapter is only available on Flutter web. '
        'On non-web targets supply a platform-appropriate OZStorageAdapter '
        '(e.g. a Keychain-backed implementation on iOS, an '
        'EncryptedSharedPreferences-backed implementation on Android, or '
        'OZInMemoryStorageAdapter for testing).',
      );

  // coverage:ignore-start
  @override
  Future<void> save(OZStoredCredential credential) async => _unsupported();

  @override
  Future<OZStoredCredential?> get(String credentialId) async => _unsupported();

  @override
  Future<List<OZStoredCredential>> getByContract(String contractId) async =>
      _unsupported();

  @override
  Future<List<OZStoredCredential>> getAll() async => _unsupported();

  @override
  Future<void> delete(String credentialId) async => _unsupported();

  @override
  Future<void> update(String credentialId, OZStoredCredentialUpdate updates) async =>
      _unsupported();

  @override
  Future<void> clear() async => _unsupported();

  @override
  Future<void> saveSession(OZStoredSession session) async => _unsupported();

  @override
  Future<OZStoredSession?> getSession() async => _unsupported();

  @override
  Future<void> clearSession() async => _unsupported();
  // coverage:ignore-end
}
