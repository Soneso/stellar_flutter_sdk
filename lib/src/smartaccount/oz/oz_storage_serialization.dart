// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import '../../util.dart';
import 'oz_storage_adapter.dart';

/// JSON-serialisable representation of [StoredCredential] used by
/// persistent storage adapters.
///
/// Persistent backends frequently cannot store binary blobs alongside the
/// rest of the credential metadata, so the [Uint8List] public-key field is
/// rendered as a lowercase hex string here. The deployment status is also
/// stored as its enum-name string so the encoded form remains stable as
/// the enum evolves.
///
/// Internal to the smart-account storage layer; not exported from the SDK
/// barrel. Persistent adapters import this file via its relative path.
class SerializableCredential {
  /// Constructs a serialisable credential record. Defaults match the
  /// corresponding [StoredCredential] defaults so consumers can omit
  /// unused metadata.
  const SerializableCredential({
    required this.credentialId,
    required this.publicKeyHex,
    this.contractId,
    this.deploymentStatus = 'pending',
    this.deploymentError,
    required this.createdAt,
    this.lastUsedAt,
    this.nickname,
    this.isPrimary = false,
    this.transports,
    this.deviceType,
    this.backedUp,
  });

  /// WebAuthn credential ID (Base64URL encoded).
  final String credentialId;

  /// Lowercase hex of the uncompressed secp256r1 public key.
  final String publicKeyHex;

  /// Smart account contract address, or `null` if not yet derived.
  final String? contractId;

  /// Deployment status name (`pending` or `failed`).
  final String deploymentStatus;

  /// Error message captured when deployment failed.
  final String? deploymentError;

  /// Creation timestamp in milliseconds since epoch.
  final int createdAt;

  /// Last-used-for-signing timestamp in milliseconds since epoch.
  final int? lastUsedAt;

  /// Optional user-friendly nickname.
  final String? nickname;

  /// Whether this is the primary credential for the smart account.
  final bool isPrimary;

  /// Authenticator transport hints (`usb`, `nfc`, `ble`, `internal`).
  final List<String>? transports;

  /// Authenticator device type (`singleDevice` or `multiDevice`).
  final String? deviceType;

  /// Whether the passkey is backed up or synced.
  final bool? backedUp;

  /// Encodes this record as a JSON-shaped [Map].
  Map<String, dynamic> toJson() => {
        'credentialId': credentialId,
        'publicKeyHex': publicKeyHex,
        if (contractId != null) 'contractId': contractId,
        'deploymentStatus': deploymentStatus,
        if (deploymentError != null) 'deploymentError': deploymentError,
        'createdAt': createdAt,
        if (lastUsedAt != null) 'lastUsedAt': lastUsedAt,
        if (nickname != null) 'nickname': nickname,
        'isPrimary': isPrimary,
        if (transports != null) 'transports': transports,
        if (deviceType != null) 'deviceType': deviceType,
        if (backedUp != null) 'backedUp': backedUp,
      };

  /// Decodes a [SerializableCredential] from a JSON-shaped [Map].
  ///
  /// Throws [FormatException] if a required field is missing or has the
  /// wrong type.
  factory SerializableCredential.fromJson(Map<String, dynamic> json) {
    final credentialId = json['credentialId'];
    if (credentialId is! String) {
      throw const FormatException(
        'SerializableCredential.fromJson: missing or non-string credentialId',
      );
    }
    final publicKeyHex = json['publicKeyHex'];
    if (publicKeyHex is! String) {
      throw const FormatException(
        'SerializableCredential.fromJson: missing or non-string publicKeyHex',
      );
    }
    final createdAt = json['createdAt'];
    if (createdAt is! int) {
      throw const FormatException(
        'SerializableCredential.fromJson: missing or non-int createdAt',
      );
    }
    return SerializableCredential(
      credentialId: credentialId,
      publicKeyHex: publicKeyHex,
      contractId: _readNullableString(json, 'contractId'),
      deploymentStatus: (json['deploymentStatus'] as String?) ?? 'pending',
      deploymentError: _readNullableString(json, 'deploymentError'),
      createdAt: createdAt,
      lastUsedAt: _readNullableInt(json, 'lastUsedAt'),
      nickname: _readNullableString(json, 'nickname'),
      isPrimary: (json['isPrimary'] as bool?) ?? false,
      transports: _readNullableStringList(json, 'transports'),
      deviceType: _readNullableString(json, 'deviceType'),
      backedUp: _readNullableBool(json, 'backedUp'),
    );
  }
}

/// JSON-serialisable representation of [StoredSession].
///
/// Internal to the smart-account storage layer; not exported from the SDK
/// barrel.
class SerializableSession {
  /// Constructs a serialisable session record.
  const SerializableSession({
    required this.credentialId,
    required this.contractId,
    required this.connectedAt,
    required this.expiresAt,
  });

  /// Credential ID associated with this session.
  final String credentialId;

  /// Smart account contract address.
  final String contractId;

  /// When the session was established (milliseconds since epoch).
  final int connectedAt;

  /// When the session expires (milliseconds since epoch).
  final int expiresAt;

  /// Encodes this record as a JSON-shaped [Map].
  Map<String, dynamic> toJson() => {
        'credentialId': credentialId,
        'contractId': contractId,
        'connectedAt': connectedAt,
        'expiresAt': expiresAt,
      };

  /// Decodes a [SerializableSession] from a JSON-shaped [Map].
  ///
  /// Throws [FormatException] if a required field is missing or has the
  /// wrong type.
  factory SerializableSession.fromJson(Map<String, dynamic> json) {
    final credentialId = json['credentialId'];
    if (credentialId is! String) {
      throw const FormatException(
        'SerializableSession.fromJson: missing or non-string credentialId',
      );
    }
    final contractId = json['contractId'];
    if (contractId is! String) {
      throw const FormatException(
        'SerializableSession.fromJson: missing or non-string contractId',
      );
    }
    final connectedAt = json['connectedAt'];
    if (connectedAt is! int) {
      throw const FormatException(
        'SerializableSession.fromJson: missing or non-int connectedAt',
      );
    }
    final expiresAt = json['expiresAt'];
    if (expiresAt is! int) {
      throw const FormatException(
        'SerializableSession.fromJson: missing or non-int expiresAt',
      );
    }
    return SerializableSession(
      credentialId: credentialId,
      contractId: contractId,
      connectedAt: connectedAt,
      expiresAt: expiresAt,
    );
  }
}

/// JSON-serialisable index of credential IDs.
///
/// Persistent key-value backends (UserDefaults, SharedPreferences,
/// localStorage) often lack key-prefix enumeration, so adapters maintain
/// an external list of credential IDs alongside the per-credential
/// records. This DTO is the on-disk shape of that index.
///
/// Internal to the smart-account storage layer.
class CredentialIndex {
  /// Constructs an index from the given credential [ids].
  const CredentialIndex({required this.ids});

  /// The list of credential IDs.
  final List<String> ids;

  /// Encodes this record as a JSON-shaped [Map].
  Map<String, dynamic> toJson() => {'ids': ids};

  /// Decodes a [CredentialIndex] from a JSON-shaped [Map].
  factory CredentialIndex.fromJson(Map<String, dynamic> json) {
    final raw = json['ids'];
    if (raw is! List) {
      throw const FormatException(
        'CredentialIndex.fromJson: missing or non-list ids',
      );
    }
    return CredentialIndex(
      ids: raw.map((e) => e as String).toList(growable: false),
    );
  }
}

/// Conversion helpers between [StoredCredential] / [StoredSession] and
/// their serialisable counterparts.
extension StoredCredentialSerialization on StoredCredential {
  /// Returns a [SerializableCredential] view of this credential, hex-
  /// encoding the public key and rendering the deployment status as its
  /// enum-name string.
  SerializableCredential toSerializable() {
    return SerializableCredential(
      credentialId: credentialId,
      publicKeyHex: Util.bytesToHex(publicKey),
      contractId: contractId,
      deploymentStatus: deploymentStatus.name,
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
}

/// Reverse-direction conversion for [SerializableCredential].
extension SerializableCredentialConversion on SerializableCredential {
  /// Reconstructs a [StoredCredential] from this serialisable form.
  ///
  /// Throws [ArgumentError] if [deploymentStatus] is not a known
  /// [CredentialDeploymentStatus] enum name. Throws [FormatException] if
  /// [publicKeyHex] is not valid hex.
  StoredCredential toStoredCredential() {
    final pubKeyBytes = Util.hexToBytes(publicKeyHex);
    return StoredCredential(
      credentialId: credentialId,
      publicKey: Uint8List.fromList(pubKeyBytes),
      contractId: contractId,
      deploymentStatus: _statusFromName(deploymentStatus),
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
}

/// Forward conversion from [StoredSession] to its serialisable form.
extension StoredSessionSerialization on StoredSession {
  /// Returns a [SerializableSession] view of this session.
  SerializableSession toSerializable() {
    return SerializableSession(
      credentialId: credentialId,
      contractId: contractId,
      connectedAt: connectedAt,
      expiresAt: expiresAt,
    );
  }
}

/// Reverse-direction conversion for [SerializableSession].
extension SerializableSessionConversion on SerializableSession {
  /// Reconstructs a [StoredSession] from this serialisable form.
  StoredSession toStoredSession() {
    return StoredSession(
      credentialId: credentialId,
      contractId: contractId,
      connectedAt: connectedAt,
      expiresAt: expiresAt,
    );
  }
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

String? _readNullableString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is String) return value;
  throw FormatException(
    'Expected String or null for "$key", got ${value.runtimeType}',
  );
}

int? _readNullableInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is int) return value;
  throw FormatException(
    'Expected int or null for "$key", got ${value.runtimeType}',
  );
}

bool? _readNullableBool(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is bool) return value;
  throw FormatException(
    'Expected bool or null for "$key", got ${value.runtimeType}',
  );
}

List<String>? _readNullableStringList(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is List) {
    return value.map((e) => e as String).toList(growable: false);
  }
  throw FormatException(
    'Expected List<String> or null for "$key", got ${value.runtimeType}',
  );
}
