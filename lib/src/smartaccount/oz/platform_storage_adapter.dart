// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';

import '../core/smart_account_errors.dart';
import 'oz_storage_adapter.dart';
import 'oz_storage_serialization.dart';

/// Method-channel name used by the platform storage bridge.
///
/// The native iOS/Android storage handler registered on this channel.
const String _storageChannelName =
    'com.soneso.stellar_flutter_sdk/smartaccount/storage';

/// `PlatformException.code` strings emitted by the native storage handler.
const String _codeReadFailed = 'STORAGE_READ_FAILED';
const String _codeWriteFailed = 'STORAGE_WRITE_FAILED';
const String _codeNotFound = 'CREDENTIAL_NOT_FOUND';

/// `StorageAdapter` implementation that dispatches to the native platform's
/// secure-storage plugin via a Flutter method channel.
///
/// On Android the underlying storage is `EncryptedSharedPreferences` backed
/// by the Android Keystore (AES-256-GCM for values, AES-256-SIV for keys).
/// On iOS and macOS the underlying storage is the platform Keychain via the
/// Security framework's `SecItem*` primitives.
///
/// ### Thread safety
///
/// Method-channel calls are dispatched on the platform thread in arrival
/// order. The native handlers serialise concurrent operations using a
/// platform-specific mutex (Kotlin coroutines `Mutex` on Android, Swift
/// `actor` isolation on iOS / macOS). Callers do NOT need to wrap calls on
/// this adapter in a Dart-side lock; the native side provides actual mutual
/// exclusion of read-modify-write sequences.
///
/// ### Asymmetric corruption handling (matches the native handler contract)
///
/// - [get] returns `null` if the stored payload is corrupt or unreadable;
///   the corruption is logged on the native side but not surfaced to Dart
///   to keep "look up an entry that may not exist" calls non-fatal.
/// - [getAll] skips corrupted entries (logged) and returns the valid
///   subset.
/// - [update] throws [StorageReadFailed] when the entry to be updated is
///   corrupt, because the read-modify-write sequence cannot proceed safely
///   without a known prior state. Callers that want lossy semantics should
///   delete the corrupt entry and `save` a replacement.
class PlatformStorageAdapter implements StorageAdapter {
  /// Constructs a platform storage adapter.
  ///
  /// The optional [methodChannel] parameter exists so unit tests can
  /// substitute a mock channel via
  /// `TestDefaultBinaryMessengerBinding.defaultBinaryMessenger.setMockMethodCallHandler`.
  /// Production code MUST omit this argument so the shared channel name is
  /// used and consumers' native overlays continue to receive calls.
  PlatformStorageAdapter({MethodChannel? methodChannel})
      : _channel = methodChannel ?? const MethodChannel(_storageChannelName);

  final MethodChannel _channel;

  // StorageAdapter — Credential operations

  @override
  Future<void> save(StoredCredential credential) async {
    final args = <String, Object?>{
      'credential': credential.toSerializable().toJson(),
    };
    try {
      await _channel.invokeMethod<void>('storage.save', args);
    } on PlatformException catch (e) {
      throw _mapStorageException(e, 'credential:${credential.credentialId}');
    }
  }

  @override
  Future<StoredCredential?> get(String credentialId) async {
    try {
      final raw = await _channel.invokeMapMethod<Object?, Object?>(
        'storage.get',
        <String, Object?>{'credentialId': credentialId},
      );
      if (raw == null) return null;
      return _decodeCredential(raw);
    } on PlatformException catch (e) {
      throw _mapStorageException(e, 'credential:$credentialId');
    }
  }

  @override
  Future<List<StoredCredential>> getByContract(String contractId) async {
    try {
      final raw = await _channel.invokeListMethod<Object?>(
        'storage.getByContract',
        <String, Object?>{'contractId': contractId},
      );
      if (raw == null) return const <StoredCredential>[];
      return raw
          .whereType<Map<Object?, Object?>>()
          .map(_decodeCredential)
          .toList(growable: false);
    } on PlatformException catch (e) {
      throw _mapStorageException(e, 'credentials:contract:$contractId');
    }
  }

  @override
  Future<List<StoredCredential>> getAll() async {
    try {
      final raw =
          await _channel.invokeListMethod<Object?>('storage.getAll', null);
      if (raw == null) return const <StoredCredential>[];
      return raw
          .whereType<Map<Object?, Object?>>()
          .map(_decodeCredential)
          .toList(growable: false);
    } on PlatformException catch (e) {
      throw _mapStorageException(e, 'credentials:all');
    }
  }

  @override
  Future<void> delete(String credentialId) async {
    try {
      await _channel.invokeMethod<void>(
        'storage.delete',
        <String, Object?>{'credentialId': credentialId},
      );
    } on PlatformException catch (e) {
      throw _mapStorageException(e, 'credential:$credentialId');
    }
  }

  @override
  Future<void> update(
    String credentialId,
    StoredCredentialUpdate updates,
  ) async {
    final args = <String, Object?>{
      'credentialId': credentialId,
      'updates': _encodeUpdates(updates),
    };
    try {
      await _channel.invokeMethod<void>('storage.update', args);
    } on PlatformException catch (e) {
      if (e.code == _codeNotFound) {
        throw CredentialException.notFound(credentialId, cause: e);
      }
      throw _mapStorageException(e, 'credential:$credentialId');
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _channel.invokeMethod<void>('storage.clear', null);
    } on PlatformException catch (e) {
      throw _mapStorageException(e, 'credentials:all');
    }
  }

  // StorageAdapter — Session operations

  @override
  Future<void> saveSession(StoredSession session) async {
    final args = <String, Object?>{
      'session': session.toSerializable().toJson(),
    };
    try {
      await _channel.invokeMethod<void>('storage.saveSession', args);
    } on PlatformException catch (e) {
      throw _mapStorageException(e, 'session');
    }
  }

  @override
  Future<StoredSession?> getSession() async {
    try {
      final raw = await _channel.invokeMapMethod<Object?, Object?>(
        'storage.getSession',
        null,
      );
      if (raw == null) return null;
      return _decodeSession(raw);
    } on PlatformException catch (e) {
      throw _mapStorageException(e, 'session');
    }
  }

  @override
  Future<void> clearSession() async {
    try {
      await _channel.invokeMethod<void>('storage.clearSession', null);
    } on PlatformException catch (e) {
      throw _mapStorageException(e, 'session');
    }
  }

  // Marshaling helpers

  StoredCredential _decodeCredential(Map<Object?, Object?> raw) {
    final json = _stringKeyedMap(raw);
    return SerializableCredential.fromJson(json).toStoredCredential();
  }

  StoredSession _decodeSession(Map<Object?, Object?> raw) {
    final json = _stringKeyedMap(raw);
    return SerializableSession.fromJson(json).toStoredSession();
  }

  /// Serialises a [StoredCredentialUpdate] to a JSON-shaped map. Only
  /// non-null fields are included so the wire payload matches the partial-
  /// update semantics documented on [StoredCredentialUpdate].
  Map<String, Object?> _encodeUpdates(StoredCredentialUpdate updates) {
    final map = <String, Object?>{};
    if (updates.deploymentStatus != null) {
      map['deploymentStatus'] = updates.deploymentStatus!.name;
    }
    if (updates.deploymentError != null) {
      map['deploymentError'] = updates.deploymentError;
    }
    if (updates.contractId != null) map['contractId'] = updates.contractId;
    if (updates.lastUsedAt != null) map['lastUsedAt'] = updates.lastUsedAt;
    if (updates.nickname != null) map['nickname'] = updates.nickname;
    if (updates.isPrimary != null) map['isPrimary'] = updates.isPrimary;
    if (updates.transports != null) {
      map['transports'] = List<String>.from(updates.transports!);
    }
    if (updates.deviceType != null) map['deviceType'] = updates.deviceType;
    if (updates.backedUp != null) map['backedUp'] = updates.backedUp;
    return map;
  }

  Map<String, dynamic> _stringKeyedMap(Map<Object?, Object?> raw) {
    final out = <String, dynamic>{};
    raw.forEach((key, value) {
      if (key is String) {
        out[key] = _coerceForJson(value);
      }
    });
    return out;
  }

  /// Recursively coerces nested method-channel values into types the
  /// `SerializableCredential` / `SerializableSession` JSON decoders accept
  /// (`int`, `String`, `bool`, `List<dynamic>`, `Map<String, dynamic>`).
  Object? _coerceForJson(Object? value) {
    if (value is Map) {
      return _stringKeyedMap(value.cast<Object?, Object?>());
    }
    if (value is List) {
      return value
          .map<dynamic>((dynamic e) => _coerceForJson(e as Object?))
          .toList(growable: false);
    }
    return value;
  }

  StorageException _mapStorageException(PlatformException e, String key) {
    switch (e.code) {
      case _codeReadFailed:
        return StorageException.readFailed(key, cause: e);
      case _codeWriteFailed:
        return StorageException.writeFailed(key, cause: e);
      default:
        // Unmapped codes are surfaced as write failures because the most
        // common producer of an unmapped code is a native-side bug while
        // attempting to mutate storage. Read-only methods can still receive
        // this fallback; the wrapped `PlatformException.cause` carries the
        // original code so callers can disambiguate if needed.
        return StorageException.writeFailed(key, cause: e);
    }
  }
}
