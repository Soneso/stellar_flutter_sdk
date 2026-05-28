// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

import '../../key_pair.dart';
import '../../util.dart';
import '../core/smart_account_constants.dart';
import '../core/smart_account_errors.dart';
import '../core/smart_account_utils.dart';
import 'oz_storage_adapter.dart';

// OZExternalEd25519SignerAdapter

/// Adapter for out-of-process Ed25519 signing sources.
///
/// Implement this abstract class to plug in a hardware wallet, remote signing
/// service, or any other signing backend into the multi-signer pipeline. The
/// manager consults the adapter before falling back to its in-memory keypair
/// registry (adapter-first precedence rule).
///
/// Example:
/// ```dart
/// class MyHardwareAdapter implements OZExternalEd25519SignerAdapter {
///   @override
///   bool canSignFor(String verifierAddress, Uint8List publicKey) =>
///       _wallet.hasSigner(publicKey);
///
///   @override
///   Future<Uint8List> signAuthDigest(
///       Uint8List authDigest, Uint8List publicKey) async =>
///       _wallet.sign(authDigest, publicKey);
/// }
///
/// final manager = OZExternalSignerManager(networkPassphrase: '...');
/// manager.setEd25519Adapter(MyHardwareAdapter());
/// ```
abstract class OZExternalEd25519SignerAdapter {
  /// Constructs an Ed25519 signer adapter.
  const OZExternalEd25519SignerAdapter();

  /// Returns whether this adapter can produce an Ed25519 signature for the
  /// given verifier-contract address and public-key pair.
  ///
  /// Called before the in-memory keypair registry is consulted. When this
  /// method returns `true`, the adapter must be able to fulfil a subsequent
  /// [signAuthDigest] call for the same key without error.
  ///
  /// [verifierAddress] is the C-strkey of the Ed25519 verifier contract
  /// identifying the on-chain signer slot. [publicKey] is the 32-byte
  /// Ed25519 public key identifying the signer slot.
  bool canSignFor(String verifierAddress, Uint8List publicKey);

  /// Produces a 64-byte Ed25519 signature over [authDigest].
  ///
  /// Called by the multi-signer pipeline when
  /// [canSignFor] returned `true` for the same [publicKey]. The pipeline
  /// locally verifies the returned signature before incorporating it into
  /// the authorization payload.
  ///
  /// [authDigest] is the 32-byte digest to sign, computed as
  /// `SHA-256(signaturePayload || contextRuleIds.toXDR())`.
  /// [publicKey] is the 32-byte Ed25519 public key that identifies which
  /// key to sign with.
  ///
  /// Returns the 64-byte raw Ed25519 signature over [authDigest].
  Future<Uint8List> signAuthDigest(Uint8List authDigest, Uint8List publicKey);
}

// Ed25519 storage key

/// Composite key for the Ed25519 signer registry.
///
/// Two entries with the same public key but different verifier addresses are
/// distinct on-chain signers and must be stored as separate entries. The
/// on-chain `External(verifierAddress, publicKey)` signer entry contains
/// both fields; this key mirrors that identity.
class _Ed25519SignerKey {
  _Ed25519SignerKey({
    required this.verifierAddress,
    required this.publicKey,
  });

  final String verifierAddress;
  final Uint8List publicKey;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! _Ed25519SignerKey) return false;
    if (verifierAddress != other.verifierAddress) return false;
    return Util.constantTimeEquals(publicKey, other.publicKey);
  }

  @override
  int get hashCode => SmartAccountUtils.hashBytes(verifierAddress.hashCode, publicKey);
}

// ExternalSignerType / ExternalSignerInfo / WalletConnectionStorage

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
class InMemoryWalletConnectionStorage extends WalletConnectionStorage {
  /// Constructs an empty in-memory wallet connection storage.
  InMemoryWalletConnectionStorage();

  final Map<String, String> _data = <String, String>{};
  Future<void> _tail = Future<void>.value();

  Future<T> _withLock<T>(FutureOr<T> Function() body) {
    final completer = Completer<T>();
    final previous = _tail;
    // Lock-tail collapse — see _withLock in OZSmartAccountKit for the full rationale.
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
const String _walletStorageKey = 'oz_smart_account.connected_wallets';

/// Manager for external (non-passkey) signers used in multi-signature
/// smart-account operations.
///
/// Provides a unified interface for managing Stellar account signers that
/// originate from Ed25519 secret keys or external wallet connections such
/// as Freighter or LOBSTR. Two methods of adding signers are supported:
///
/// 1. Stellar keypair signers (via [addFromSecret]) — created from a Stellar
///    S-strkey. These are held in memory only and never persisted; the
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

  // Internal state

  final Map<String, KeyPair> _keypairSigners = <String, KeyPair>{};

  /// Ed25519 keypairs keyed by `(verifierAddress, publicKey)`. Memory-only,
  /// never persisted. The composite key mirrors the on-chain
  /// `External(verifierAddress, publicKey)` signer identity.
  final Map<_Ed25519SignerKey, KeyPair> _ed25519Signers =
      <_Ed25519SignerKey, KeyPair>{};

  /// Optional adapter for out-of-process Ed25519 signing.
  ///
  /// When set, the adapter is consulted via [OZExternalEd25519SignerAdapter.canSignFor]
  /// before the in-memory keypair registry (adapter-first precedence rule).
  /// Read via the [ed25519Adapter] getter. Write via [setEd25519Adapter].
  OZExternalEd25519SignerAdapter? _ed25519Adapter;

  /// The currently registered Ed25519 adapter, or `null` when none is set.
  OZExternalEd25519SignerAdapter? get ed25519Adapter => _ed25519Adapter;

  bool _restored = false;
  Future<void> _tail = Future<void>.value();

  Future<T> _withLock<T>(FutureOr<T> Function() body) {
    final completer = Completer<T>();
    final previous = _tail;
    // Lock-tail collapse — see _withLock in OZSmartAccountKit for the full rationale.
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

  // Add signers

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

  // Query signers

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

  // Sign auth entry

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

  // Remove signers

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
  /// Clears the keypair map, the Ed25519 keypair map, disconnects every
  /// external wallet connection via [ExternalWalletAdapter.disconnect], and
  /// clears the persisted wallet connections from [walletConnectionStorage].
  /// Failures from `disconnect()` or `removeItem()` propagate to the caller.
  Future<void> removeAll() async {
    await _withLock<void>(() {
      _keypairSigners.clear();
      _ed25519Signers.clear();
    });

    await walletAdapter?.disconnect();
    await walletConnectionStorage?.removeItem(_walletStorageKey);
  }

  // Ed25519 methods

  /// Registers the optional Ed25519 adapter consulted by the multi-signer
  /// pipeline. Pass `null` to clear.
  void setEd25519Adapter(OZExternalEd25519SignerAdapter? adapter) {
    _ed25519Adapter = adapter;
  }

  /// Registers an Ed25519 signing keypair derived from raw 32-byte secret key
  /// material and stores it in memory under the composite
  /// `(verifierAddress, publicKey)` key. The keypair is never persisted to
  /// storage and is lost when the application terminates.
  ///
  /// If a keypair is already registered for the same
  /// `(verifierAddress, publicKey)` pair it is silently overwritten.
  ///
  /// [secretKeyBytes] must be exactly 32 bytes — the raw Ed25519 seed.
  /// This is not a Stellar S-strkey; it is the raw seed material.
  /// For hardware wallets, HSMs, or remote signing services, use
  /// [setEd25519Adapter] instead — the raw secret never enters process memory.
  ///
  /// [verifierAddress] is the C-strkey of the Ed25519 verifier contract
  /// under which the signer is registered on-chain.
  ///
  /// Returns the derived 32-byte Ed25519 public key.
  ///
  /// Throws [InvalidInput] when [secretKeyBytes] is not exactly 32 bytes.
  /// Throws [SignerInvalid] when keypair construction fails.
  Uint8List addEd25519FromRawKey({
    required Uint8List secretKeyBytes,
    required String verifierAddress,
  }) {
    if (secretKeyBytes.length != SmartAccountConstants.ed25519SecretSeedSize) {
      throw ValidationException.invalidInput(
        'secretKeyBytes',
        'Ed25519 secret key must be exactly ${SmartAccountConstants.ed25519SecretSeedSize} bytes, got ${secretKeyBytes.length}',
      );
    }

    final KeyPair keypair;
    try {
      keypair = KeyPair.fromSecretSeedList(secretKeyBytes);
    } catch (e) {
      throw SignerException.invalid(
        'Failed to construct Ed25519 keypair from provided secret key bytes: $e',
        cause: e,
      );
    }

    final publicKey = Uint8List.fromList(keypair.publicKey);
    final storeKey = _Ed25519SignerKey(
      verifierAddress: verifierAddress,
      publicKey: publicKey,
    );
    _ed25519Signers[storeKey] = keypair;
    return publicKey;
  }

  /// Returns whether a signing source is available for the given Ed25519 signer.
  ///
  /// Checks the adapter first (adapter-first precedence rule). When the adapter
  /// returns `true` for [OZExternalEd25519SignerAdapter.canSignFor], this method
  /// returns `true` without consulting the in-memory registry. Falls back to
  /// checking whether an in-memory keypair is registered for
  /// `(verifierAddress, publicKey)`.
  ///
  /// [verifierAddress] is the C-strkey of the Ed25519 verifier contract.
  /// [publicKey] is the 32-byte Ed25519 public key identifying the signer slot.
  bool canSignEd25519For({
    required String verifierAddress,
    required Uint8List publicKey,
  }) {
    final adapter = _ed25519Adapter;
    if (adapter != null && adapter.canSignFor(verifierAddress, publicKey)) {
      return true;
    }
    final storeKey = _Ed25519SignerKey(
      verifierAddress: verifierAddress,
      publicKey: publicKey,
    );
    return _ed25519Signers.containsKey(storeKey);
  }

  /// Produces a 64-byte Ed25519 signature over [authDigest].
  ///
  /// Resolves the signing source using the adapter-first precedence rule:
  /// the adapter is consulted first via
  /// [OZExternalEd25519SignerAdapter.canSignFor]. If the adapter claims it
  /// can sign, it is invoked via
  /// [OZExternalEd25519SignerAdapter.signAuthDigest]. Otherwise the in-memory
  /// keypair registry is used. Throws when neither source is available.
  ///
  /// [verifierAddress] is the C-strkey of the Ed25519 verifier contract.
  /// [publicKey] is the 32-byte Ed25519 public key identifying the signer
  /// slot. [authDigest] is the 32-byte auth digest to sign.
  ///
  /// Returns the 64-byte raw Ed25519 signature over [authDigest].
  ///
  /// Throws [InvalidInput] when no signing source is registered;
  /// [TransactionSigningFailed] when the adapter or in-memory keypair fails.
  Future<Uint8List> signEd25519AuthDigest({
    required String verifierAddress,
    required Uint8List publicKey,
    required Uint8List authDigest,
  }) async {
    // Snapshot the adapter reference before any await so the adapter-first
    // check is consistent for the lifetime of this call.
    final adapterSnapshot = _ed25519Adapter;

    if (adapterSnapshot != null &&
        adapterSnapshot.canSignFor(verifierAddress, publicKey)) {
      final Uint8List rawSignature;
      try {
        rawSignature =
            await adapterSnapshot.signAuthDigest(authDigest, publicKey);
      } catch (e) {
        throw TransactionException.signingFailed(
          'Ed25519 adapter signing failed for verifier $verifierAddress: $e',
          cause: e,
        );
      }
      return rawSignature;
    }

    final storeKey = _Ed25519SignerKey(
      verifierAddress: verifierAddress,
      publicKey: publicKey,
    );
    final keypair = _ed25519Signers[storeKey];
    if (keypair == null) {
      final prefix = SmartAccountUtils.truncateForLog(verifierAddress);
      throw ValidationException.invalidInput(
        'selectedSigners',
        'Ed25519 signer (verifier=$prefix...) has no registered keypair or '
            'adapter — register via '
            'OZExternalSignerManager.addEd25519FromRawKey(...) before signing',
      );
    }

    if (!keypair.canSign()) {
      throw TransactionException.signingFailed(
        'Ed25519 keypair for verifier $verifierAddress is public-only and '
            'cannot sign',
      );
    }

    final signature = keypair.sign(authDigest);
    return Uint8List.fromList(signature);
  }

  /// Removes a registered Ed25519 signer from the in-memory registry.
  ///
  /// Clears the keypair stored under `(verifierAddress, publicKey)`. No-op
  /// when no keypair is registered for that pair. The adapter is not
  /// affected by this call.
  ///
  /// [verifierAddress] is the C-strkey of the Ed25519 verifier contract.
  /// [publicKey] is the 32-byte Ed25519 public key identifying the signer
  /// slot to remove.
  void removeEd25519({
    required String verifierAddress,
    required Uint8List publicKey,
  }) {
    final storeKey = _Ed25519SignerKey(
      verifierAddress: verifierAddress,
      publicKey: publicKey,
    );
    _ed25519Signers.remove(storeKey);
  }

  // Wallet connection persistence

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

  // Private signing helpers

  Future<SignAuthEntryResult> _signWithKeypair(
    KeyPair keypair,
    String preimageXdrBase64,
    String address,
  ) async {
    // KeyPair built via fromAccountId/fromPublicKey is public-only and yields
    // an unusable signature; surface a clear error before calling sign().
    if (!keypair.canSign()) {
      throw TransactionException.signingFailed(
        'Keypair for $address is public-only and cannot sign',
      );
    }
    // Single try/catch covers base64 decode + keypair.sign(); SHA-256 cannot throw.
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

  // Private storage helpers

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
    InMemoryWalletConnectionStorage();

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
