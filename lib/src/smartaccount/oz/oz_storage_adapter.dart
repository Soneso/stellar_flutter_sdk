// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import '../../util.dart';
import '../core/smart_account_errors.dart';

/// Deployment status of a smart account credential.
///
/// On a successful deployment the credential is removed from storage rather
/// than transitioned to a terminal "success" state, so the only persisted
/// states are [pending] and [failed]. A credential whose status was
/// [pending] disappears from storage once its smart-account contract has
/// been deployed.
enum OZCredentialDeploymentStatus {
  /// Credential created but smart account contract not yet deployed.
  pending,

  /// Deployment transaction failed.
  failed,
}

/// Stored smart account credential with deployment and usage metadata.
///
/// Represents a WebAuthn credential (passkey) associated with a smart
/// account. Tracks the credential's deployment status, contract address,
/// and usage history.
///
/// Equality is byte-content based.
class OZStoredCredential {
  /// Constructs a stored credential. [credentialId] and [publicKey] are
  /// required; all metadata fields default to safe non-set values.
  ///
  /// When [createdAt] is omitted the current wall-clock millisecond
  /// timestamp is captured.
  OZStoredCredential({
    required this.credentialId,
    required Uint8List publicKey,
    this.contractId,
    this.deploymentStatus = OZCredentialDeploymentStatus.pending,
    this.deploymentError,
    int? createdAt,
    this.lastUsedAt,
    this.nickname,
    this.isPrimary = false,
    this.transports,
    this.deviceType,
    this.backedUp,
  })  : publicKey = Uint8List.fromList(publicKey),
        createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  /// WebAuthn credential ID (Base64URL-encoded). The unique identifier
  /// returned by the browser during WebAuthn registration.
  final String credentialId;

  /// Uncompressed secp256r1 public key (65 bytes starting with `0x04`).
  /// Used for signature verification in the WebAuthn verifier contract.
  final Uint8List publicKey;

  /// Smart account contract address (C-address). Set during wallet
  /// creation. `null` while the contract address has not been derived yet.
  final String? contractId;

  /// Current deployment status of the smart account contract.
  final OZCredentialDeploymentStatus deploymentStatus;

  /// Error message captured when deployment failed.
  final String? deploymentError;

  /// Timestamp (milliseconds since epoch) when this credential was created.
  final int createdAt;

  /// Timestamp (milliseconds since epoch) when this credential was last
  /// used for signing. Updated after successful transaction signatures.
  final int? lastUsedAt;

  /// Optional user-friendly nickname. Examples: `MacBook Pro Touch ID`,
  /// `YubiKey 5`.
  final String? nickname;

  /// Whether this is the primary credential for this smart account. The
  /// primary credential is used as the default for signing operations.
  final bool isPrimary;

  /// Authenticator transport hints indicating how the browser can talk to
  /// the authenticator (e.g. `usb`, `nfc`, `ble`, `internal`). Used when
  /// constructing `allowCredentials` for future authentication ceremonies.
  final List<String>? transports;

  /// Authenticator device type. `singleDevice` (hardware key, not synced)
  /// or `multiDevice` (synced/cloud-backed). Corresponds to the
  /// `credentialDeviceType` flag in WebAuthn authenticator data.
  final String? deviceType;

  /// Whether the passkey is backed up or synced to a cloud provider. When
  /// `true` the credential is available across the user's devices via
  /// iCloud Keychain, Google Password Manager, or similar sync services.
  final bool? backedUp;

  /// Returns a copy of this credential with the supplied fields replaced.
  ///
  /// Pass [setContractId] / [setDeploymentError] / [setLastUsedAt] /
  /// [setNickname] / [setTransports] / [setDeviceType] / [setBackedUp] as
  /// `true` together with the corresponding `null` argument to clear an
  /// optional field. Without these flags a `null` argument means
  /// "no change" — the existing value is retained.
  OZStoredCredential copyWith({
    String? credentialId,
    Uint8List? publicKey,
    String? contractId,
    bool setContractId = false,
    OZCredentialDeploymentStatus? deploymentStatus,
    String? deploymentError,
    bool setDeploymentError = false,
    int? createdAt,
    int? lastUsedAt,
    bool setLastUsedAt = false,
    String? nickname,
    bool setNickname = false,
    bool? isPrimary,
    List<String>? transports,
    bool setTransports = false,
    String? deviceType,
    bool setDeviceType = false,
    bool? backedUp,
    bool setBackedUp = false,
  }) {
    return OZStoredCredential(
      credentialId: credentialId ?? this.credentialId,
      publicKey: publicKey ?? this.publicKey,
      contractId: setContractId ? contractId : (contractId ?? this.contractId),
      deploymentStatus: deploymentStatus ?? this.deploymentStatus,
      deploymentError: setDeploymentError
          ? deploymentError
          : (deploymentError ?? this.deploymentError),
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt:
          setLastUsedAt ? lastUsedAt : (lastUsedAt ?? this.lastUsedAt),
      nickname: setNickname ? nickname : (nickname ?? this.nickname),
      isPrimary: isPrimary ?? this.isPrimary,
      transports:
          setTransports ? transports : (transports ?? this.transports),
      deviceType:
          setDeviceType ? deviceType : (deviceType ?? this.deviceType),
      backedUp: setBackedUp ? backedUp : (backedUp ?? this.backedUp),
    );
  }

  /// Applies the given partial [updates] to this credential and returns a
  /// new instance. Fields whose update value is `null` are left unchanged
  /// — there is no way to clear a previously-set field via this helper. To
  /// clear a field, save a full replacement [OZStoredCredential] through
  /// [OZStorageAdapter.save].
  OZStoredCredential applyUpdate(OZStoredCredentialUpdate updates) =>
      copyWith(
        deploymentStatus: updates.deploymentStatus,
        deploymentError: updates.deploymentError,
        contractId: updates.contractId,
        lastUsedAt: updates.lastUsedAt,
        nickname: updates.nickname,
        isPrimary: updates.isPrimary,
        transports: updates.transports,
        deviceType: updates.deviceType,
        backedUp: updates.backedUp,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OZStoredCredential) return false;
    if (credentialId != other.credentialId) return false;
    if (!Util.constantTimeEquals(publicKey, other.publicKey)) return false;
    if (contractId != other.contractId) return false;
    if (deploymentStatus != other.deploymentStatus) return false;
    if (deploymentError != other.deploymentError) return false;
    if (createdAt != other.createdAt) return false;
    if (lastUsedAt != other.lastUsedAt) return false;
    if (nickname != other.nickname) return false;
    if (isPrimary != other.isPrimary) return false;
    if (!_listEquals(transports, other.transports)) return false;
    if (deviceType != other.deviceType) return false;
    if (backedUp != other.backedUp) return false;
    return true;
  }

  @override
  int get hashCode {
    var result = credentialId.hashCode;
    result = 31 * result + _byteListHash(publicKey);
    result = 31 * result + (contractId?.hashCode ?? 0);
    result = 31 * result + deploymentStatus.hashCode;
    result = 31 * result + (deploymentError?.hashCode ?? 0);
    result = 31 * result + createdAt.hashCode;
    result = 31 * result + (lastUsedAt?.hashCode ?? 0);
    result = 31 * result + (nickname?.hashCode ?? 0);
    result = 31 * result + isPrimary.hashCode;
    result = 31 * result + _stringListHash(transports);
    result = 31 * result + (deviceType?.hashCode ?? 0);
    result = 31 * result + (backedUp?.hashCode ?? 0);
    return result;
  }
}

bool _listEquals<T>(List<T>? a, List<T>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return false;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

int _byteListHash(Uint8List bytes) {
  var hash = 1;
  for (final byte in bytes) {
    hash = 31 * hash + byte;
  }
  return hash;
}

int _stringListHash(List<String>? values) {
  if (values == null) return 0;
  var hash = 1;
  for (final value in values) {
    hash = 31 * hash + value.hashCode;
  }
  return hash;
}

/// Stored user session for silent reconnection.
///
/// Sessions enable users to reconnect to their smart account wallet without
/// re-authentication, as long as the session has not expired.
class OZStoredSession {
  /// Constructs a stored session with the four required timestamps and
  /// identifiers.
  const OZStoredSession({
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

  /// Whether the session has expired against wall-clock time.
  bool get isExpired =>
      DateTime.now().millisecondsSinceEpoch >= expiresAt;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OZStoredSession) return false;
    return credentialId == other.credentialId &&
        contractId == other.contractId &&
        connectedAt == other.connectedAt &&
        expiresAt == other.expiresAt;
  }

  @override
  int get hashCode =>
      Object.hash(credentialId, contractId, connectedAt, expiresAt);
}

/// Partial updates for a stored credential.
///
/// Only non-null fields are applied during an update operation. A `null`
/// value means "no change" and does not clear the field. To reset a field
/// to `null`, replace the whole credential via [OZStorageAdapter.save].
class OZStoredCredentialUpdate {
  /// Constructs a partial update specification for [OZStoredCredential]. All
  /// fields default to `null` (no change).
  const OZStoredCredentialUpdate({
    this.deploymentStatus,
    this.deploymentError,
    this.contractId,
    this.lastUsedAt,
    this.nickname,
    this.isPrimary,
    this.transports,
    this.deviceType,
    this.backedUp,
  });

  final OZCredentialDeploymentStatus? deploymentStatus;
  final String? deploymentError;
  final String? contractId;
  final int? lastUsedAt;
  final String? nickname;
  final bool? isPrimary;
  final List<String>? transports;

  /// `singleDevice` or `multiDevice`; `null` means no change.
  final String? deviceType;

  final bool? backedUp;
}

/// Protocol for persisting smart account credentials and sessions.
///
/// Storage adapters provide a pluggable persistence layer. Implementations
/// must be safe for concurrent calls from a single Dart isolate; persistent
/// implementations that span multiple isolates or processes are responsible
/// for any additional synchronisation those environments require.
///
/// The default implementation is [OZInMemoryStorageAdapter] (memory only).
/// Platform-specific implementations can provide persistent storage.
abstract class OZStorageAdapter {
  /// Throws [SmartAccountStorageWriteFailed] if persistence fails.
  Future<void> save(OZStoredCredential credential);

  /// Returns `null` if not found. Throws [SmartAccountStorageReadFailed] if reading fails.
  Future<OZStoredCredential?> get(String credentialId);

  /// Returns an empty list when no credentials match.
  ///
  /// Throws [SmartAccountStorageReadFailed] if reading fails.
  Future<List<OZStoredCredential>> getByContract(String contractId);

  /// Throws [SmartAccountStorageReadFailed] if reading fails.
  Future<List<OZStoredCredential>> getAll();

  /// Silently no-ops if no credential with [credentialId] exists.
  ///
  /// Throws [SmartAccountStorageWriteFailed] if deletion fails.
  Future<void> delete(String credentialId);

  /// Throws [SmartAccountCredentialNotFound] if no credential with [credentialId] exists.
  /// Throws [SmartAccountStorageWriteFailed] if persistence fails.
  Future<void> update(String credentialId, OZStoredCredentialUpdate updates);

  /// Throws [SmartAccountStorageWriteFailed] if clearing fails.
  Future<void> clear();

  /// Throws [SmartAccountStorageWriteFailed] if saving fails.
  Future<void> saveSession(OZStoredSession session);

  /// Returns `null` when no session exists or when the saved session has
  /// already expired; an expired session is auto-cleared so callers always
  /// observe "valid session or none". Throws [SmartAccountStorageReadFailed] if reading
  /// fails.
  Future<OZStoredSession?> getSession();

  /// Throws [SmartAccountStorageWriteFailed] if clearing fails.
  Future<void> clearSession();
}

/// In-memory storage adapter for credentials and sessions.
///
/// Stores all data in a Dart-isolate-local map and does not persist across
/// application restarts. Concurrent calls are serialised through an
/// internal [Future]-based lock so that interleaved reads and writes never
/// observe a partially-applied update.
///
/// All [OZInMemoryStorageAdapter] instances compare equal because two
/// freshly-created instances are functionally identical (both empty); this
/// makes the adapter usable as a default value of an enclosing data class
/// without breaking that data class's structural equality.
///
/// Security: this adapter is **not secure** and stores credential public-key
/// bytes and session metadata in plain process memory. Suitable only for
/// testing and development. Production apps must supply a platform-backed
/// secure storage adapter (for example a Keychain-backed implementation on
/// Apple platforms or an EncryptedSharedPreferences-backed implementation on
/// Android) via [OZSmartAccountConfig.storage].
class OZInMemoryStorageAdapter implements OZStorageAdapter {
  OZInMemoryStorageAdapter();

  final Map<String, OZStoredCredential> _credentials = {};
  OZStoredSession? _session;
  Future<void> _tail = Future<void>.value();

  // why: in-memory FIFO serialization without a runtime dependency.
  // We chain every call onto `_tail` so requests run strictly in arrival
  // order. The per-call `Completer` isolates body-thrown errors from the
  // chain itself: if a body throws, the completer rejects but `_tail`
  // resolves cleanly, so a single failed write does not poison every
  // subsequent call.
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

  @override
  Future<void> save(OZStoredCredential credential) {
    return _withLock<void>(() {
      _credentials[credential.credentialId] = credential;
    });
  }

  @override
  Future<OZStoredCredential?> get(String credentialId) {
    return _withLock<OZStoredCredential?>(() => _credentials[credentialId]);
  }

  @override
  Future<List<OZStoredCredential>> getByContract(String contractId) {
    return _withLock<List<OZStoredCredential>>(() => _credentials.values
        .where((credential) => credential.contractId == contractId)
        .toList(growable: false));
  }

  @override
  Future<List<OZStoredCredential>> getAll() {
    return _withLock<List<OZStoredCredential>>(
        () => _credentials.values.toList(growable: false));
  }

  @override
  Future<void> delete(String credentialId) {
    return _withLock<void>(() {
      _credentials.remove(credentialId);
    });
  }

  @override
  Future<void> update(String credentialId, OZStoredCredentialUpdate updates) {
    return _withLock<void>(() {
      final existing = _credentials[credentialId];
      if (existing == null) {
        throw SmartAccountCredentialException.notFound(credentialId);
      }
      _credentials[credentialId] = existing.applyUpdate(updates);
    });
  }

  @override
  Future<void> clear() {
    return _withLock<void>(() {
      _credentials.clear();
    });
  }

  @override
  Future<void> saveSession(OZStoredSession session) {
    return _withLock<void>(() {
      _session = session;
    });
  }

  @override
  Future<OZStoredSession?> getSession() {
    return _withLock<OZStoredSession?>(() {
      final current = _session;
      if (current == null) return null;
      if (current.isExpired) {
        _session = null;
        return null;
      }
      return current;
    });
  }

  @override
  Future<void> clearSession() {
    return _withLock<void>(() {
      _session = null;
    });
  }

  @override
  bool operator ==(Object other) => other is OZInMemoryStorageAdapter;

  @override
  int get hashCode => (OZInMemoryStorageAdapter).hashCode;
}

/// Information about an externally connected wallet.
///
/// Returned by [OZExternalWalletAdapter.connect] and
/// [OZExternalWalletAdapter.getConnectedWallets] to identify which wallet is
/// connected and its signing address.
class OZConnectedWallet {
  /// Constructs a connected-wallet record.
  const OZConnectedWallet({
    required this.address,
    required this.walletId,
    required this.walletName,
  });

  /// Stellar G-address of the connected wallet.
  final String address;

  /// Unique wallet identifier (e.g. `freighter`, `lobstr`). Used for
  /// reconnection via [OZExternalWalletAdapter.reconnect].
  final String walletId;

  /// Human-readable display name for the wallet (e.g. `Freighter`,
  /// `LOBSTR`).
  final String walletName;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OZConnectedWallet) return false;
    return address == other.address &&
        walletId == other.walletId &&
        walletName == other.walletName;
  }

  @override
  int get hashCode => Object.hash(address, walletId, walletName);
}

/// Options for signing an authorization entry with an external wallet.
///
/// Allows specifying a network passphrase and a particular address when
/// multiple wallets are connected.
class OZSignAuthEntryOptions {
  /// Constructs a sign-auth-entry options record. All fields default to
  /// `null` so callers can omit any combination.
  const OZSignAuthEntryOptions({
    this.networkPassphrase,
    this.address,
  });

  /// Network passphrase for signing context.
  final String? networkPassphrase;

  /// Specific address to sign with, if multiple wallets are connected.
  final String? address;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OZSignAuthEntryOptions) return false;
    return networkPassphrase == other.networkPassphrase &&
        address == other.address;
  }

  @override
  int get hashCode => Object.hash(networkPassphrase, address);
}

/// Result of signing an authorization preimage with an external wallet.
///
/// Carries the raw Ed25519 signature and optionally the signer address,
/// which may differ from the requested address in some wallet
/// implementations.
class OZSignAuthEntryResult {
  /// Constructs a sign-auth-entry result.
  const OZSignAuthEntryResult({
    required this.signedAuthEntry,
    this.signerAddress,
  });

  /// Base64-encoded raw Ed25519 signature (64 bytes).
  ///
  /// The wallet hashes the preimage with SHA-256 and signs the resulting
  /// 32-byte payload with Ed25519. This field carries the 64-byte raw
  /// signature.
  final String signedAuthEntry;

  /// Stellar G-address that produced the signature. May be `null` if the
  /// wallet does not report the signer address; in that case callers can
  /// assume the signature came from the requested address.
  final String? signerAddress;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OZSignAuthEntryResult) return false;
    return signedAuthEntry == other.signedAuthEntry &&
        signerAddress == other.signerAddress;
  }

  @override
  int get hashCode => Object.hash(signedAuthEntry, signerAddress);
}

/// Protocol for integrating external wallet adapters for multi-signer
/// support.
///
/// External wallet adapters enable signing with external wallets like
/// Freighter or Albedo for multi-signature smart accounts. They handle
/// wallet connection, signature collection, and wallet reconnection.
///
/// Concrete adapters extend this class so they can inherit the no-op
/// defaults for [disconnectByAddress], [getWalletForAddress], and
/// [reconnect].
abstract class OZExternalWalletAdapter {
  /// Constructs an external wallet adapter base.
  const OZExternalWalletAdapter();

  /// Connects to the external wallet, prompting the user to authorise the
  /// connection through the wallet's UI.
  ///
  /// Returns the connected-wallet info, or `null` if the user cancelled.
  /// Throws a [SmartAccountWalletException] if connection fails.
  Future<OZConnectedWallet?> connect();

  /// Disconnects all external wallets.
  ///
  /// Throws a [SmartAccountWalletException] if disconnection fails.
  Future<void> disconnect();

  /// Disconnects a specific wallet by its Stellar [address].
  ///
  /// Override this when the adapter needs to release per-address runtime
  /// state when a single signer is removed. The default implementation is
  /// a no-op.
  Future<void> disconnectByAddress(String address) async {}

  /// Signs an authorization preimage with the external wallet.
  ///
  /// The SDK supplies a base64-encoded `HashIDPreimage` XDR. The wallet
  /// must:
  /// 1. Base64-decode the preimage bytes
  /// 2. SHA-256 hash the preimage bytes
  /// 3. Ed25519-sign the 32-byte hash
  /// 4. Return the 64-byte raw signature as base64
  ///
  /// The SDK handles auth-entry construction and signature framing — the
  /// wallet only produces the raw Ed25519 signature.
  ///
  /// Contract: the returned signature MUST verify against the wallet's
  /// public key as `verify(signature, sha256(preimageBytes))`. Adapters
  /// that omit the SHA-256 step, sign a different payload, or return a
  /// non-canonical encoding produce a signature that the Soroban host
  /// rejects at submission time. That rejection surfaces in the SDK as
  /// `SmartAccountTransactionException.simulationFailed` during the post-sign
  /// re-simulation, not as a direct error from this method.
  ///
  /// Throws [SmartAccountTransactionSigningFailed] if signing fails or is rejected.
  Future<OZSignAuthEntryResult> signAuthEntry(
    String preimageXdr, {
    OZSignAuthEntryOptions? options,
  });

  /// Returns all currently connected wallets.
  List<OZConnectedWallet> getConnectedWallets();

  /// Returns whether a wallet is connected that can sign for [address].
  bool canSignFor(String address);

  /// Returns wallet info for a specific [address] when known. Default
  /// implementation returns `null`.
  OZConnectedWallet? getWalletForAddress(String address) => null;

  /// Reconnects to a previously connected wallet by its [walletId].
  ///
  /// Used for restoring wallet connections after page reloads or app
  /// restarts. The default implementation returns `null`, indicating
  /// reconnection is not supported by this adapter.
  Future<OZConnectedWallet?> reconnect(String walletId) async => null;
}
