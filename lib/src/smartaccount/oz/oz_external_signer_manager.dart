// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

import '../../key_pair.dart';
import '../core/smart_account_errors.dart';
import 'oz_storage_adapter.dart';

/// The type of an external signer managed by [OZExternalSignerManager].
enum ExternalSignerType {
  /// Ed25519 keypair-based signer. Stored in memory only, never persisted.
  keypair,

  /// External wallet signer (e.g. Freighter, LOBSTR). Connection metadata
  /// can be persisted to storage so connections survive app restarts.
  wallet,
}

/// Information about a managed external signer.
///
/// Represents either a keypair-based signer (in-memory Ed25519 key) or a
/// wallet-based signer (external wallet connection). Returned by
/// [OZExternalSignerManager.getAll] and the internal `get` helper.
class ExternalSignerInfo {
  /// Constructs a signer info record. [walletName] and [walletId] are
  /// only meaningful when [type] is [ExternalSignerType.wallet].
  const ExternalSignerInfo({
    required this.address,
    required this.type,
    this.walletName,
    this.walletId,
  });

  /// Stellar G-address of the signer.
  final String address;

  /// Whether this signer is keypair- or wallet-backed.
  final ExternalSignerType type;

  /// Human-readable wallet name (only present when [type] is
  /// [ExternalSignerType.wallet]).
  final String? walletName;

  /// Wallet identifier used for reconnection (only present when [type] is
  /// [ExternalSignerType.wallet]).
  final String? walletId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ExternalSignerInfo) return false;
    return other.address == address &&
        other.type == type &&
        other.walletName == walletName &&
        other.walletId == walletId;
  }

  @override
  int get hashCode => Object.hash(address, type, walletName, walletId);

  @override
  String toString() =>
      'ExternalSignerInfo(address: $address, type: $type, '
      'walletName: $walletName, walletId: $walletId)';
}

/// Simple key-value storage interface for persisting external wallet
/// connections.
///
/// Implementations must be safe for concurrent calls. Platform-specific
/// implementations can use SharedPreferences (Android), UserDefaults
/// (iOS), localStorage (Web), or any other persistent key-value store.
abstract class WalletConnectionStorage {
  /// Constructs a wallet-connection-storage base.
  const WalletConnectionStorage();

  /// Retrieves the value stored under [key], or `null` when no entry
  /// exists.
  Future<String?> getItem(String key);

  /// Stores [value] under [key], overwriting any existing value.
  Future<void> setItem(String key, String value);

  /// Removes the entry stored under [key]. No-ops when the key is absent.
  Future<void> removeItem(String key);
}

/// In-memory implementation of [WalletConnectionStorage] used as the
/// default fallback when no storage adapter is supplied. Data is not
/// retained across app launches.
class _InMemoryWalletConnectionStorage extends WalletConnectionStorage {
  _InMemoryWalletConnectionStorage();

  final Map<String, String> _data = <String, String>{};
  Future<void> _tail = Future<void>.value();

  Future<T> _withLock<T>(FutureOr<T> Function() body) {
    final completer = Completer<T>();
    final previous = _tail;
    // why: chain each new operation onto the most recent tail. Once the
    // operation completes we reset `_tail` to a fresh resolved future
    // so the implicit reference chain through `previous` collapses and
    // earlier futures become eligible for GC. Without the reset the
    // chain grows unbounded for the lifetime of the storage instance.
    final next = previous.then((_) async {
      try {
        completer.complete(await body());
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    _tail = next;
    completer.future.whenComplete(() {
      if (identical(_tail, next)) {
        _tail = Future<void>.value();
      }
    });
    return completer.future;
  }

  @override
  Future<String?> getItem(String key) =>
      _withLock<String?>(() => _data[key]);

  @override
  Future<void> setItem(String key, String value) =>
      _withLock<void>(() => _data[key] = value);

  @override
  Future<void> removeItem(String key) =>
      _withLock<void>(() => _data.remove(key));
}

/// Storage key for persisted wallet connections.
const String _walletStorageKey = 'external_wallets';

/// Manager for external (non-passkey) signers used in multi-signature
/// smart-account operations.
///
/// Provides a unified interface for managing Stellar account signers that
/// originate from Ed25519 secret keys or external wallet connections such
/// as Freighter or LOBSTR. Two methods of adding signers are supported:
///
/// 1. Keypair signers (via [addFromSecret]) — created from a raw Ed25519
///    secret key. These are held in memory only and never persisted; the
///    secret key material is reachable only through the in-memory
///    [KeyPair] instance.
///
/// 2. Wallet signers (via [addFromWallet]) — connected through the
///    supplied [ExternalWalletAdapter]. Connection metadata (address,
///    wallet ID, wallet name) is persisted to [WalletConnectionStorage]
///    so connections can be restored across app launches via
///    [restoreConnections].
///
/// Concurrency: every mutation of `_keypairSigners` or the `_restored`
/// flag runs through the hand-rolled FIFO Future-chain `_withLock`
/// helper. The Dart isolate model ensures non-`await` execution is
/// already serialised; the lock guarantees serial ordering across
/// `await` suspension points.
///
/// Example:
/// ```dart
/// final manager = OZExternalSignerManager(
///   networkPassphrase: 'Test SDF Network ; September 2015',
///   walletAdapter: myWalletAdapter,
///   walletConnectionStorage: myStorage,
/// );
///
/// final address = await manager.addFromSecret('SCZANG...');
/// final wallet = await manager.addFromWallet();
/// if (await manager.canSignFor('GABC...')) {
///   final sig = await manager.signAuthEntry('GABC...', preimageXdr);
/// }
/// ```
class OZExternalSignerManager {
  /// Constructs a standalone external-signer manager.
  ///
  /// The manager is independent of any [OZSmartAccountKit] instance; it
  /// can be instantiated and used directly when signers are managed
  /// outside the smart-account flow.
  OZExternalSignerManager({
    required this.networkPassphrase,
    this.walletAdapter,
    WalletConnectionStorage? walletConnectionStorage,
  }) : walletConnectionStorage = walletConnectionStorage;

  /// Network passphrase used when delegating to [walletAdapter].
  final String networkPassphrase;

  /// Optional external wallet adapter. When `null`, only keypair signers
  /// are supported.
  final ExternalWalletAdapter? walletAdapter;

  /// Optional connection persistence layer. When `null`, wallet
  /// connections are not restored across app launches.
  final WalletConnectionStorage? walletConnectionStorage;

  // -------------------------------------------------------------------------
  // Internal state
  // -------------------------------------------------------------------------

  final Map<String, KeyPair> _keypairSigners = <String, KeyPair>{};
  bool _restored = false;
  Future<void> _tail = Future<void>.value();

  Future<T> _withLock<T>(FutureOr<T> Function() body) {
    final completer = Completer<T>();
    final previous = _tail;
    // why: chain each new operation onto the most recent tail, then
    // reset `_tail` to a fresh resolved future once the operation
    // completes so the implicit reference chain collapses and earlier
    // futures become eligible for GC. Without the reset the chain
    // grows unbounded for the lifetime of the manager.
    final next = previous.then((_) async {
      try {
        completer.complete(await body());
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    _tail = next;
    completer.future.whenComplete(() {
      if (identical(_tail, next)) {
        _tail = Future<void>.value();
      }
    });
    return completer.future;
  }

  /// Whether an external wallet adapter is configured. Wallet operations
  /// (`addFromWallet`, `restoreConnections`) require this to be `true`.
  bool get hasWalletAdapter => walletAdapter != null;

  // -------------------------------------------------------------------------
  // Add signers
  // -------------------------------------------------------------------------

  /// Adds an Ed25519 keypair signer derived from [secretKey].
  ///
  /// Validates the secret seed via [KeyPair.fromSecretSeed] and stores
  /// the resulting [KeyPair] in memory. The keypair is never persisted —
  /// it is lost when the application terminates.
  ///
  /// When a signer with the same G-address already exists (keypair or
  /// wallet), the keypair signer takes precedence and overwrites the
  /// existing entry. Any persisted wallet connection for that address is
  /// removed so it does not resurrect on the next [restoreConnections]
  /// call.
  ///
  /// Returns the derived G-address.
  ///
  /// Throws [SignerInvalid] when the secret key is invalid or keypair
  /// construction fails.
  Future<String> addFromSecret(String secretKey) async {
    final KeyPair keypair;
    try {
      keypair = KeyPair.fromSecretSeed(secretKey);
    } catch (e) {
      throw SignerException.invalid(
        'Invalid secret key. Must be a valid Stellar secret key (S...): $e',
        cause: e,
      );
    }

    final address = keypair.accountId;

    await _withLock<void>(() {
      _keypairSigners[address] = keypair;
    });

    // why: keypair signers take precedence at sign time. Without this
    // cleanup, a previously stored wallet entry for the same address
    // would resurrect on the next restoreConnections() call and then
    // appear in getAll() alongside the keypair entry.
    await _removeWalletFromStorage(address);

    return address;
  }

  /// Connects an external wallet via [walletAdapter] and adds it as a
  /// signer.
  ///
  /// Returns the connected wallet's metadata, or `null` when the user
  /// cancels the connection prompt. When [walletConnectionStorage] is
  /// configured the connection is persisted for later restoration.
  ///
  /// Throws [MissingConfig] when no wallet adapter is configured.
  Future<ConnectedWallet?> addFromWallet() async {
    final adapter = walletAdapter;
    if (adapter == null) {
      throw ConfigurationException.missingConfig(
        'walletAdapter: No wallet adapter configured. Pass an '
        'ExternalWalletAdapter to OZExternalSignerManager to enable '
        'wallet connections.',
      );
    }

    final wallet = await adapter.connect();
    if (wallet == null) return null;

    if (walletConnectionStorage != null) {
      await _saveWalletToStorage(wallet);
    }

    return wallet;
  }

  // -------------------------------------------------------------------------
  // Query signers
  // -------------------------------------------------------------------------

  /// Returns `true` when any managed signer (keypair or wallet) can sign
  /// for [address]. Keypair signers are checked first.
  Future<bool> canSignFor(String address) async {
    final hasKeypair = await _withLock<bool>(
      () => _keypairSigners.containsKey(address),
    );
    if (hasKeypair) return true;

    if (walletAdapter != null && walletAdapter!.canSignFor(address)) {
      return true;
    }

    return false;
  }

  /// Returns the signer info for [address], preferring keypair entries
  /// over wallet entries when both exist for the same address. Returns
  /// `null` when no signer is registered.
  Future<ExternalSignerInfo?> get(String address) async {
    final hasKeypair = await _withLock<bool>(
      () => _keypairSigners.containsKey(address),
    );
    if (hasKeypair) {
      return ExternalSignerInfo(
        address: address,
        type: ExternalSignerType.keypair,
      );
    }

    final adapter = walletAdapter;
    if (adapter != null) {
      final wallet = adapter.getWalletForAddress(address);
      if (wallet != null) {
        return ExternalSignerInfo(
          address: wallet.address,
          type: ExternalSignerType.wallet,
          walletName: wallet.walletName,
          walletId: wallet.walletId,
        );
      }
    }

    return null;
  }

  /// Lists every managed signer. Keypair signers come first; wallet
  /// signers whose addresses are also present as keypair signers are
  /// skipped because keypair signers take precedence.
  Future<List<ExternalSignerInfo>> getAll() async {
    final signers = <ExternalSignerInfo>[];
    final Set<String> keypairAddresses;

    keypairAddresses = await _withLock<Set<String>>(
      () => _keypairSigners.keys.toSet(),
    );

    for (final address in keypairAddresses) {
      signers.add(
        ExternalSignerInfo(
          address: address,
          type: ExternalSignerType.keypair,
        ),
      );
    }

    final adapter = walletAdapter;
    if (adapter != null) {
      final wallets = adapter.getConnectedWallets();
      for (final wallet in wallets) {
        if (!keypairAddresses.contains(wallet.address)) {
          signers.add(
            ExternalSignerInfo(
              address: wallet.address,
              type: ExternalSignerType.wallet,
              walletName: wallet.walletName,
              walletId: wallet.walletId,
            ),
          );
        }
      }
    }

    return signers;
  }

  /// Returns `true` when at least one signer (keypair or wallet) is
  /// registered.
  Future<bool> hasSigners() async {
    final hasKeypairs = await _withLock<bool>(
      () => _keypairSigners.isNotEmpty,
    );
    if (hasKeypairs) return true;

    final walletCount = walletAdapter?.getConnectedWallets().length ?? 0;
    return walletCount > 0;
  }

  // -------------------------------------------------------------------------
  // Sign auth entry
  // -------------------------------------------------------------------------

  /// Signs an authorisation-entry preimage for the supplied [address].
  ///
  /// For keypair signers the base64-encoded preimage is decoded, hashed
  /// with SHA-256, and signed with the in-memory Ed25519 keypair. For
  /// wallet signers the call is delegated to
  /// [ExternalWalletAdapter.signAuthEntry]. Keypair signers take
  /// precedence over wallet signers when both exist for the same address.
  ///
  /// Returns a [SignAuthEntryResult] carrying the base64-encoded
  /// signature and the signer's address.
  ///
  /// Throws [SignerNotFound] when no signer is available for [address]
  /// and [TransactionSigningFailed] when the signing operation fails.
  Future<SignAuthEntryResult> signAuthEntry(
    String address,
    String authEntry,
  ) async {
    final keypair = await _withLock<KeyPair?>(() => _keypairSigners[address]);

    if (keypair != null) {
      return _signWithKeypair(keypair, authEntry, address);
    }

    final adapter = walletAdapter;
    if (adapter != null && adapter.canSignFor(address)) {
      try {
        final result = await adapter.signAuthEntry(
          authEntry,
          options: SignAuthEntryOptions(
            networkPassphrase: networkPassphrase,
            address: address,
          ),
        );
        return SignAuthEntryResult(
          signedAuthEntry: result.signedAuthEntry,
          signerAddress: result.signerAddress ?? address,
        );
      } catch (e) {
        throw TransactionException.signingFailed(
          'External wallet signing failed for $address: $e',
          cause: e,
        );
      }
    }

    throw SignerException.notFound(address);
  }

  // -------------------------------------------------------------------------
  // Remove signers
  // -------------------------------------------------------------------------

  /// Removes the signer registered for [address].
  ///
  /// Removes the entry from the keypair map, asks the wallet adapter to
  /// release any per-address state via [ExternalWalletAdapter.disconnectByAddress],
  /// and removes the persisted wallet connection from storage. All three
  /// steps run unconditionally so a partially registered signer is fully
  /// cleaned up.
  Future<void> remove(String address) async {
    await _withLock<void>(() {
      _keypairSigners.remove(address);
    });

    await walletAdapter?.disconnectByAddress(address);
    await _removeWalletFromStorage(address);
  }

  /// Removes every managed signer.
  ///
  /// Clears the keypair map, disconnects every external wallet connection
  /// via [ExternalWalletAdapter.disconnect], and clears the persisted
  /// wallet connections from [walletConnectionStorage]. Failures from
  /// `disconnect()` or `removeItem()` propagate to the caller — there is
  /// no defensive try/catch wrapping them because the contract is "remove
  /// what we can; caller handles the rest".
  Future<void> removeAll() async {
    await _withLock<void>(() {
      _keypairSigners.clear();
    });

    await walletAdapter?.disconnect();
    await walletConnectionStorage?.removeItem(_walletStorageKey);
  }

  // -------------------------------------------------------------------------
  // Wallet connection persistence
  // -------------------------------------------------------------------------

  /// Restores previously connected wallets from [walletConnectionStorage].
  ///
  /// Reads the persisted connection list and asks
  /// [ExternalWalletAdapter.reconnect] to re-establish each one. Wallets
  /// whose `reconnect` returns `null` or throws are removed from storage.
  ///
  /// Idempotent: subsequent calls after the first successful restoration
  /// return the currently connected wallets without re-reading storage.
  /// Returns an empty list when [walletConnectionStorage] or
  /// [walletAdapter] is unset.
  Future<List<ConnectedWallet>> restoreConnections() async {
    final alreadyRestored = await _withLock<bool>(() {
      final current = _restored;
      _restored = true;
      return current;
    });

    if (alreadyRestored) {
      return walletAdapter?.getConnectedWallets() ?? const <ConnectedWallet>[];
    }

    if (walletConnectionStorage == null || walletAdapter == null) {
      return const <ConnectedWallet>[];
    }

    final stored = await _getStoredWallets();
    final restored = <ConnectedWallet>[];

    for (final saved in stored) {
      try {
        final wallet = await walletAdapter!.reconnect(saved.walletId);
        if (wallet != null) {
          restored.add(wallet);
        } else {
          await _removeWalletFromStorage(saved.address);
        }
      } catch (_) {
        await _removeWalletFromStorage(saved.address);
      }
    }

    return restored;
  }

  // -------------------------------------------------------------------------
  // Private signing helpers
  // -------------------------------------------------------------------------

  Future<SignAuthEntryResult> _signWithKeypair(
    KeyPair keypair,
    String preimageXdrBase64,
    String address,
  ) async {
    // why: `crypto.sha256.convert` cannot throw (the input is a plain
    // byte list and the algorithm is pure), so the only operations that
    // can fail are the base64 decode and the keypair sign. Wrapping
    // both in a single try/catch collapses three near-identical
    // catch blocks into one while preserving the rethrow as
    // [TransactionException.signingFailed] for the caller.
    try {
      final preimageBytes = base64Decode(preimageXdrBase64);
      final payload =
          Uint8List.fromList(crypto.sha256.convert(preimageBytes).bytes);
      final signature = keypair.sign(payload);
      return SignAuthEntryResult(
        signedAuthEntry: base64Encode(signature),
        signerAddress: address,
      );
    } catch (e) {
      throw TransactionException.signingFailed(
        'Ed25519 signing failed for $address: $e',
        cause: e,
      );
    }
  }

  // -------------------------------------------------------------------------
  // Private storage helpers
  // -------------------------------------------------------------------------

  Future<List<_StoredWalletConnection>> _getStoredWallets() async {
    final storage = walletConnectionStorage;
    if (storage == null) return const <_StoredWalletConnection>[];

    try {
      final data = await storage.getItem(_walletStorageKey);
      if (data == null) return const <_StoredWalletConnection>[];
      return _parseStoredWallets(data);
    } catch (_) {
      return const <_StoredWalletConnection>[];
    }
  }

  Future<void> _saveWalletToStorage(ConnectedWallet wallet) async {
    final storage = walletConnectionStorage;
    if (storage == null) return;

    // why: the read-modify-write happens under `_withLock` so a
    // concurrent add/remove cannot interleave between the load and the
    // setItem and silently drop one of the writes.
    await _withLock<void>(() async {
      final stored =
          List<_StoredWalletConnection>.from(await _getStoredWallets())
            ..removeWhere((w) => w.address == wallet.address)
            ..add(
              _StoredWalletConnection(
                address: wallet.address,
                walletId: wallet.walletId,
                walletName: wallet.walletName,
                connectedAt: DateTime.now().millisecondsSinceEpoch,
              ),
            );
      await storage.setItem(_walletStorageKey, _serializeWallets(stored));
    });
  }

  Future<void> _removeWalletFromStorage(String address) async {
    final storage = walletConnectionStorage;
    if (storage == null) return;

    // why: see [_saveWalletToStorage]; the same lock serialises this
    // mutation against concurrent saves.
    await _withLock<void>(() async {
      final stored =
          List<_StoredWalletConnection>.from(await _getStoredWallets())
            ..removeWhere((w) => w.address == address);
      if (stored.isEmpty) {
        await storage.removeItem(_walletStorageKey);
      } else {
        await storage.setItem(_walletStorageKey, _serializeWallets(stored));
      }
    });
  }

  String _serializeWallets(List<_StoredWalletConnection> wallets) {
    return jsonEncode(wallets.map((w) => w.toJson()).toList(growable: false));
  }

  List<_StoredWalletConnection> _parseStoredWallets(String jsonString) {
    final List<dynamic> decoded;
    try {
      final raw = jsonDecode(jsonString);
      if (raw is! List) return const <_StoredWalletConnection>[];
      decoded = raw;
    } catch (_) {
      return const <_StoredWalletConnection>[];
    }
    // why: per-entry try/catch so one tampered or shape-mismatched
    // record does not poison the entire stored set. The bad entry is
    // skipped silently; the surrounding restore loop will not see it
    // and the storage will be rewritten without it on the next save.
    final result = <_StoredWalletConnection>[];
    for (final m in decoded) {
      try {
        if (m is! Map<String, dynamic>) continue;
        result.add(_StoredWalletConnection.fromJson(m));
      } catch (_) {
        // Skip the malformed entry and keep parsing the rest.
      }
    }
    return List<_StoredWalletConnection>.unmodifiable(result);
  }
}

/// Returns a default in-memory wallet connection storage implementation
/// suitable as a fallback when no platform-backed adapter is supplied.
WalletConnectionStorage createInMemoryWalletConnectionStorage() =>
    _InMemoryWalletConnectionStorage();

/// Internal serialised wallet connection record. JSON encoding is
/// hand-rolled against `dart:convert` to avoid taking a runtime
/// dependency on a code-generation framework.
class _StoredWalletConnection {
  const _StoredWalletConnection({
    required this.address,
    required this.walletId,
    required this.walletName,
    required this.connectedAt,
  });

  final String address;
  final String walletId;
  final String walletName;
  final int connectedAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'address': address,
        'walletId': walletId,
        'walletName': walletName,
        'connectedAt': connectedAt,
      };

  factory _StoredWalletConnection.fromJson(Map<String, dynamic> json) {
    return _StoredWalletConnection(
      address: json['address'] as String,
      walletId: json['walletId'] as String,
      walletName: json['walletName'] as String,
      connectedAt: json['connectedAt'] as int,
    );
  }
}
