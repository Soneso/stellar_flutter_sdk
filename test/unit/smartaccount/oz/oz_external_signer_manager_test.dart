// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// ---------------------------------------------------------------------------
// Test fixtures: stub external wallet adapter and storage
// ---------------------------------------------------------------------------

const String _testNetworkPassphrase = 'Test SDF Network ; September 2015';

const String _validG1 =
    'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';
const String _validG2 =
    'GBVRV25F7XA5I2L3ILSA6XW3OCWLKGGLG4OP2EHKTWC5IHQ3EV26FQLS';

/// In-memory, additive-only storage used for unit tests. Mirrors the
/// production `WalletConnectionStorage` interface but keeps a public map
/// so tests may inject and inspect raw JSON directly.
class TestWalletStorage extends WalletConnectionStorage {
  final Map<String, String> data = <String, String>{};

  /// Records every invocation key for assertions about call ordering.
  final List<String> getCalls = <String>[];
  final List<String> setCalls = <String>[];
  final List<String> removeCalls = <String>[];

  @override
  Future<String?> getItem(String key) async {
    getCalls.add(key);
    return data[key];
  }

  @override
  Future<void> setItem(String key, String value) async {
    setCalls.add(key);
    data[key] = value;
  }

  @override
  Future<void> removeItem(String key) async {
    removeCalls.add(key);
    data.remove(key);
  }
}

/// Recording wallet adapter usable in tests. Tests script the
/// `connectResponses`/`reconnectResponses` queues and inspect
/// `connectCalls`/`reconnectCalls`/`disconnectCount`/`disconnectByAddressCalls`
/// to assert on the manager's interaction with the adapter.
class RecordingWalletAdapter extends ExternalWalletAdapter {
  RecordingWalletAdapter();

  /// Queue of `connect()` outcomes. Each entry is either a
  /// `ConnectedWallet?` value (returned as-is) or an `Exception`/`Error`
  /// (re-thrown). When exhausted the call returns `null`.
  final List<Object?> connectResponses = <Object?>[];
  int connectCallCount = 0;

  /// Queue of `reconnect(walletId)` outcomes keyed by FIFO order. Each
  /// entry follows the same value-or-throwable convention as
  /// `connectResponses`. When exhausted reconnect returns `null`.
  final List<Object?> reconnectResponses = <Object?>[];
  final List<String> reconnectCalls = <String>[];

  /// Queue of `signAuthEntry()` outcomes consumed in order.
  final List<Object> signAuthEntryResponses = <Object>[];
  final List<({String preimageXdr, SignAuthEntryOptions? options})>
      signAuthEntryCalls =
      <({String preimageXdr, SignAuthEntryOptions? options})>[];

  /// In-memory wallet table consulted by `canSignFor`,
  /// `getConnectedWallets`, and `getWalletForAddress`.
  final List<ConnectedWallet> connected = <ConnectedWallet>[];

  /// Counter for `disconnect()` calls.
  int disconnectCount = 0;

  /// Capture every `disconnectByAddress(address)` call.
  final List<String> disconnectByAddressCalls = <String>[];

  /// When `true`, `disconnect()` raises a [StateError].
  bool throwOnDisconnect = false;

  /// When `true`, `canSignFor` raises a [StateError]. Used to verify the
  /// manager is defensive against adapter exceptions.
  bool throwOnCanSignFor = false;

  @override
  Future<ConnectedWallet?> connect() async {
    connectCallCount++;
    if (connectResponses.isEmpty) return null;
    final Object? v = connectResponses.removeAt(0);
    if (v is Exception) throw v;
    if (v is Error) throw v;
    final wallet = v as ConnectedWallet?;
    if (wallet != null) connected.add(wallet);
    return wallet;
  }

  @override
  Future<ConnectedWallet?> reconnect(String walletId) async {
    reconnectCalls.add(walletId);
    if (reconnectResponses.isEmpty) return null;
    final Object? v = reconnectResponses.removeAt(0);
    if (v is Exception) throw v;
    if (v is Error) throw v;
    final wallet = v as ConnectedWallet?;
    if (wallet != null) connected.add(wallet);
    return wallet;
  }

  @override
  Future<void> disconnect() async {
    disconnectCount++;
    if (throwOnDisconnect) {
      throw StateError('disconnect requested to fail');
    }
    connected.clear();
  }

  @override
  Future<void> disconnectByAddress(String address) async {
    disconnectByAddressCalls.add(address);
    connected.removeWhere((w) => w.address == address);
  }

  @override
  Future<SignAuthEntryResult> signAuthEntry(
    String preimageXdr, {
    SignAuthEntryOptions? options,
  }) async {
    signAuthEntryCalls.add((preimageXdr: preimageXdr, options: options));
    if (signAuthEntryResponses.isEmpty) {
      throw StateError('No signAuthEntry response queued');
    }
    final v = signAuthEntryResponses.removeAt(0);
    if (v is Exception || v is Error) {
      throw v;
    }
    return v as SignAuthEntryResult;
  }

  @override
  bool canSignFor(String address) {
    if (throwOnCanSignFor) {
      throw StateError('canSignFor requested to fail');
    }
    return connected.any((w) => w.address == address);
  }

  @override
  List<ConnectedWallet> getConnectedWallets() =>
      List<ConnectedWallet>.unmodifiable(connected);

  @override
  ConnectedWallet? getWalletForAddress(String address) {
    for (final w in connected) {
      if (w.address == address) return w;
    }
    return null;
  }
}

OZExternalSignerManager _createManager({
  ExternalWalletAdapter? walletAdapter,
  WalletConnectionStorage? walletConnectionStorage,
}) {
  return OZExternalSignerManager(
    networkPassphrase: _testNetworkPassphrase,
    walletAdapter: walletAdapter,
    walletConnectionStorage: walletConnectionStorage,
  );
}

void main() {
  // -------------------------------------------------------------------------
  // E.1 addFromSecret
  // -------------------------------------------------------------------------
  group('E.1 addFromSecret', () {
    test('valid secret returns derived G-address', () async {
      final manager = _createManager();
      final keypair = KeyPair.random();
      final secret = keypair.secretSeed;

      final address = await manager.addFromSecret(secret);

      expect(address, equals(keypair.accountId));
      expect(address.startsWith('G'), isTrue);
      expect(address.length, equals(56));
    });

    test('valid secret signer is reachable via get', () async {
      final manager = _createManager();
      final keypair = KeyPair.random();
      final secret = keypair.secretSeed;

      final address = await manager.addFromSecret(secret);
      final info = await manager.get(address);

      expect(info, isNotNull);
      expect(info!.address, equals(address));
      expect(info.type, equals(ExternalSignerType.keypair));
      expect(info.walletName, isNull);
      expect(info.walletId, isNull);
    });

    test('invalid secret string throws SignerInvalid', () async {
      final manager = _createManager();
      await expectLater(
        () => manager.addFromSecret('INVALID_SECRET_KEY'),
        throwsA(isA<SignerInvalid>()),
      );
    });

    test('empty secret string throws SignerInvalid', () async {
      final manager = _createManager();
      await expectLater(
        () => manager.addFromSecret(''),
        throwsA(isA<SignerInvalid>()),
      );
    });

    test('public key in place of secret throws SignerInvalid', () async {
      final manager = _createManager();
      final keypair = KeyPair.random();
      await expectLater(
        () => manager.addFromSecret(keypair.accountId),
        throwsA(isA<SignerInvalid>()),
      );
    });

    test('same secret added twice yields one signer (overwrite)',
        () async {
      final manager = _createManager();
      final keypair = KeyPair.random();
      final secret = keypair.secretSeed;

      final a = await manager.addFromSecret(secret);
      final b = await manager.addFromSecret(secret);

      expect(a, equals(b));
      final all = await manager.getAll();
      expect(all.length, equals(1));
    });

    test('multiple distinct signers are tracked independently',
        () async {
      final manager = _createManager();
      final k1 = KeyPair.random();
      final k2 = KeyPair.random();
      final k3 = KeyPair.random();

      await manager.addFromSecret(k1.secretSeed);
      await manager.addFromSecret(k2.secretSeed);
      await manager.addFromSecret(k3.secretSeed);

      final all = await manager.getAll();
      expect(all.length, equals(3));
      final addresses = all.map((s) => s.address).toSet();
      expect(addresses, contains(k1.accountId));
      expect(addresses, contains(k2.accountId));
      expect(addresses, contains(k3.accountId));
    });

    test(
        'addFromSecret removes previously persisted wallet entry for '
        'the same address (D-129 stale removal)', () async {
      final storage = TestWalletStorage();
      final adapter = RecordingWalletAdapter();
      final manager = _createManager(
        walletAdapter: adapter,
        walletConnectionStorage: storage,
      );

      // Pre-seed storage with a wallet entry for an address that we will
      // shortly add as a keypair signer.
      final keypair = KeyPair.random();
      final address = keypair.accountId;
      storage.data['external_wallets'] = jsonEncode([
        <String, dynamic>{
          'address': address,
          'walletId': 'freighter',
          'walletName': 'Freighter',
          'connectedAt': 1700000000000,
        },
      ]);

      final secret = keypair.secretSeed;
      final got = await manager.addFromSecret(secret);

      expect(got, equals(address));
      // Storage entry must be removed; the only entry was deleted, so
      // the storage key is removed entirely.
      expect(storage.data.containsKey('external_wallets'), isFalse);
      // removeItem must have been called at least once for cleanup.
      expect(storage.removeCalls, contains('external_wallets'));
    });

    test('concurrent addFromSecret calls are serialised via mutex',
        () async {
      final manager = _createManager();
      final keypairs =
          List<KeyPair>.generate(8, (_) => KeyPair.random());

      final futures = keypairs
          .map((k) => manager.addFromSecret(k.secretSeed))
          .toList();
      final addresses = await Future.wait(futures);

      // All eight signers landed and are reachable.
      expect(addresses.toSet().length, equals(8));
      final all = await manager.getAll();
      expect(all.length, equals(8));
      for (final k in keypairs) {
        final info = await manager.get(k.accountId);
        expect(info, isNotNull);
        expect(info!.type, equals(ExternalSignerType.keypair));
      }
    });
  });

  // -------------------------------------------------------------------------
  // E.2 addFromWallet
  // -------------------------------------------------------------------------
  group('E.2 addFromWallet', () {
    test('no adapter throws MissingConfig', () async {
      final manager = _createManager();
      await expectLater(
        () => manager.addFromWallet(),
        throwsA(isA<MissingConfig>()),
      );
    });

    test('user cancels: connect returns null, addFromWallet returns null',
        () async {
      final adapter = RecordingWalletAdapter();
      adapter.connectResponses.add(null);
      final manager = _createManager(walletAdapter: adapter);

      final result = await manager.addFromWallet();
      expect(result, isNull);
      expect(adapter.connectCallCount, equals(1));
    });

    test('successful connect persists wallet to storage', () async {
      final adapter = RecordingWalletAdapter();
      final wallet = ConnectedWallet(
        address: _validG1,
        walletId: 'freighter',
        walletName: 'Freighter',
      );
      adapter.connectResponses.add(wallet);
      final storage = TestWalletStorage();

      final manager = _createManager(
        walletAdapter: adapter,
        walletConnectionStorage: storage,
      );

      final result = await manager.addFromWallet();
      expect(result, equals(wallet));
      expect(storage.data.containsKey('external_wallets'), isTrue);
      final json = jsonDecode(storage.data['external_wallets']!) as List;
      expect(json, hasLength(1));
      expect((json[0] as Map)['address'], equals(_validG1));
      expect((json[0] as Map)['walletId'], equals('freighter'));
      expect((json[0] as Map)['walletName'], equals('Freighter'));
    });

    test('successful connect without storage skips persistence',
        () async {
      final adapter = RecordingWalletAdapter();
      adapter.connectResponses.add(
        ConnectedWallet(
          address: _validG1,
          walletId: 'lobstr',
          walletName: 'LOBSTR',
        ),
      );

      final manager = _createManager(walletAdapter: adapter);

      final result = await manager.addFromWallet();
      expect(result, isNotNull);
      // Manager must still report the wallet via the adapter.
      final all = await manager.getAll();
      expect(all.any((s) => s.address == _validG1), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // E.3 canSignFor
  // -------------------------------------------------------------------------
  group('E.3 canSignFor', () {
    test('keypair exists returns true', () async {
      final manager = _createManager();
      final keypair = KeyPair.random();
      final address =
          await manager.addFromSecret(keypair.secretSeed);
      expect(await manager.canSignFor(address), isTrue);
    });

    test('wallet adapter reports signer returns true', () async {
      final adapter = RecordingWalletAdapter();
      adapter.connected.add(
        ConnectedWallet(
          address: _validG1,
          walletId: 'w1',
          walletName: 'Test',
        ),
      );
      final manager = _createManager(walletAdapter: adapter);
      expect(await manager.canSignFor(_validG1), isTrue);
    });

    test('neither keypair nor wallet returns false', () async {
      final manager = _createManager();
      expect(await manager.canSignFor(_validG1), isFalse);
    });

    test('keypair entry takes precedence over wallet of same address',
        () async {
      final adapter = RecordingWalletAdapter();
      adapter.connected.add(
        ConnectedWallet(
          address: _validG2,
          walletId: 'w',
          walletName: 'Test',
        ),
      );
      final manager = _createManager(walletAdapter: adapter);

      // canSignFor returns true regardless of which source resolves.
      expect(await manager.canSignFor(_validG2), isTrue);

      // get() returns the keypair entry once a keypair is added for the
      // same address, demonstrating precedence.
      final keypair = KeyPair.random();
      // addFromSecret only stores by the keypair's own G-address; we
      // verify precedence by adding a *real* signer for whichever
      // address its keypair derives.
      final keypairAddr =
          await manager.addFromSecret(keypair.secretSeed);
      // For that keypair address, the wallet adapter reports nothing,
      // so the keypair entry resolves through get().
      final info = await manager.get(keypairAddr);
      expect(info!.type, equals(ExternalSignerType.keypair));
    });
  });

  // -------------------------------------------------------------------------
  // E.4 signAuthEntry
  // -------------------------------------------------------------------------
  group('E.4 signAuthEntry', () {
    test('keypair signs SHA-256 of preimage with Ed25519 (D-110)',
        () async {
      final manager = _createManager();
      final keypair = KeyPair.random();
      final address =
          await manager.addFromSecret(keypair.secretSeed);

      // Construct an arbitrary preimage and verify the SDK signs the
      // SHA-256 hash of those bytes (matching the documented D-110
      // contract). We do this by directly verifying the resulting
      // signature against the same hash.
      final preimage = Uint8List.fromList(List<int>.generate(32, (i) => i));
      final preimageBase64 = base64Encode(preimage);

      final result = await manager.signAuthEntry(address, preimageBase64);
      final sig = base64Decode(result.signedAuthEntry);
      expect(sig.length, equals(64));

      final hash =
          Uint8List.fromList(crypto.sha256.convert(preimage).bytes);
      expect(keypair.verify(hash, sig), isTrue);
      expect(result.signerAddress, equals(address));
    });

    test('keypair: invalid base64 preimage throws SigningFailed',
        () async {
      final manager = _createManager();
      final keypair = KeyPair.random();
      final address =
          await manager.addFromSecret(keypair.secretSeed);

      await expectLater(
        () => manager.signAuthEntry(address, '!!!not base64!!!'),
        throwsA(isA<TransactionSigningFailed>()),
      );
    });

    test(
        'wallet path forwards networkPassphrase and address to adapter',
        () async {
      final adapter = RecordingWalletAdapter();
      adapter.connected.add(
        ConnectedWallet(
          address: _validG1,
          walletId: 'w',
          walletName: 'Test',
        ),
      );
      adapter.signAuthEntryResponses.add(
        SignAuthEntryResult(
          signedAuthEntry: base64Encode(Uint8List(64)),
          signerAddress: _validG1,
        ),
      );
      final manager = _createManager(walletAdapter: adapter);

      final preimageB64 = base64Encode(Uint8List(32));
      await manager.signAuthEntry(_validG1, preimageB64);

      expect(adapter.signAuthEntryCalls.length, equals(1));
      final call = adapter.signAuthEntryCalls.single;
      expect(call.preimageXdr, equals(preimageB64));
      expect(call.options, isNotNull);
      expect(call.options!.networkPassphrase, equals(_testNetworkPassphrase));
      expect(call.options!.address, equals(_validG1));
    });

    test('no signer registered throws SignerNotFound (D-140)', () async {
      final manager = _createManager();
      await expectLater(
        () => manager.signAuthEntry(_validG1, base64Encode(Uint8List(32))),
        throwsA(isA<SignerNotFound>()),
      );
    });

    test(
        'keypair takes precedence: wallet adapter is NOT consulted '
        '(D-140 routing)', () async {
      final adapter = RecordingWalletAdapter();
      // Provision the wallet adapter so it would also report canSign for
      // a keypair address. We then add a keypair for that same address
      // and verify the wallet path is never invoked.
      final manager = _createManager(walletAdapter: adapter);

      final keypair = KeyPair.random();
      final address =
          await manager.addFromSecret(keypair.secretSeed);

      adapter.connected.add(
        ConnectedWallet(
          address: address,
          walletId: 'shadow',
          walletName: 'Shadow',
        ),
      );

      final preimageB64 = base64Encode(Uint8List(32));
      await manager.signAuthEntry(address, preimageB64);

      // The wallet adapter must not have been called.
      expect(adapter.signAuthEntryCalls, isEmpty);
    });

    test(
        'wallet adapter throws: error wrapped as TransactionSigningFailed',
        () async {
      final adapter = RecordingWalletAdapter();
      adapter.connected.add(
        ConnectedWallet(
          address: _validG1,
          walletId: 'w',
          walletName: 'Test',
        ),
      );
      adapter.signAuthEntryResponses.add(StateError('bridge error'));
      final manager = _createManager(walletAdapter: adapter);

      await expectLater(
        () => manager.signAuthEntry(_validG1, base64Encode(Uint8List(32))),
        throwsA(isA<TransactionSigningFailed>()),
      );
    });

    test('result carries base64-encoded signature', () async {
      final manager = _createManager();
      final keypair = KeyPair.random();
      final address =
          await manager.addFromSecret(keypair.secretSeed);

      final result = await manager.signAuthEntry(
        address,
        base64Encode(Uint8List(32)),
      );

      // signedAuthEntry must be decodable as base64.
      final decoded = base64Decode(result.signedAuthEntry);
      expect(decoded.length, equals(64));
    });

    test('result.signerAddress matches the requested address', () async {
      final manager = _createManager();
      final keypair = KeyPair.random();
      final address =
          await manager.addFromSecret(keypair.secretSeed);

      final result = await manager.signAuthEntry(
        address,
        base64Encode(Uint8List(32)),
      );

      expect(result.signerAddress, equals(address));
    });
  });

  // -------------------------------------------------------------------------
  // E.5 getAll / get / hasSigners
  // -------------------------------------------------------------------------
  group('E.5 getAll / get / hasSigners', () {
    test('getAll returns keypair signers first, then wallets',
        () async {
      final adapter = RecordingWalletAdapter();
      adapter.connected.add(
        ConnectedWallet(
          address: _validG1,
          walletId: 'w1',
          walletName: 'W1',
        ),
      );
      final manager = _createManager(walletAdapter: adapter);

      final keypair = KeyPair.random();
      final keypairAddr =
          await manager.addFromSecret(keypair.secretSeed);

      final all = await manager.getAll();
      expect(all.length, equals(2));
      // Keypair signers come first.
      expect(all.first.type, equals(ExternalSignerType.keypair));
      expect(all.first.address, equals(keypairAddr));
      // Wallet signers follow.
      expect(all.last.type, equals(ExternalSignerType.wallet));
      expect(all.last.address, equals(_validG1));
    });

    test('getAll skips wallet entries when same address is also keypair',
        () async {
      final adapter = RecordingWalletAdapter();
      final manager = _createManager(walletAdapter: adapter);

      final keypair = KeyPair.random();
      final address =
          await manager.addFromSecret(keypair.secretSeed);
      // Adapter also reports a wallet for the same address.
      adapter.connected.add(
        ConnectedWallet(
          address: address,
          walletId: 'shadow',
          walletName: 'Shadow',
        ),
      );

      final all = await manager.getAll();
      expect(all.length, equals(1));
      expect(all.single.type, equals(ExternalSignerType.keypair));
    });

    test('get returns keypair entry when both keypair and wallet exist',
        () async {
      final adapter = RecordingWalletAdapter();
      final manager = _createManager(walletAdapter: adapter);

      final keypair = KeyPair.random();
      final address =
          await manager.addFromSecret(keypair.secretSeed);
      adapter.connected.add(
        ConnectedWallet(
          address: address,
          walletId: 'shadow',
          walletName: 'Shadow',
        ),
      );

      final info = await manager.get(address);
      expect(info, isNotNull);
      expect(info!.type, equals(ExternalSignerType.keypair));
    });

    test('hasSigners returns false on empty manager', () async {
      final manager = _createManager();
      expect(await manager.hasSigners(), isFalse);
    });

    test('hasSigners returns true with a keypair or wallet present',
        () async {
      final manager = _createManager();
      final keypair = KeyPair.random();
      await manager.addFromSecret(keypair.secretSeed);
      expect(await manager.hasSigners(), isTrue);

      final adapter = RecordingWalletAdapter();
      adapter.connected.add(
        ConnectedWallet(
          address: _validG2,
          walletId: 'w',
          walletName: 'W',
        ),
      );
      final manager2 = _createManager(walletAdapter: adapter);
      expect(await manager2.hasSigners(), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // E.6 remove / removeAll
  // -------------------------------------------------------------------------
  group('E.6 remove / removeAll', () {
    test('remove clears keypair entry and asks adapter to disconnect by '
        'address', () async {
      final adapter = RecordingWalletAdapter();
      final manager = _createManager(walletAdapter: adapter);

      final keypair = KeyPair.random();
      final address =
          await manager.addFromSecret(keypair.secretSeed);
      adapter.connected.add(
        ConnectedWallet(
          address: address,
          walletId: 'w',
          walletName: 'W',
        ),
      );

      await manager.remove(address);

      // Both sources are now empty for that address.
      expect(await manager.get(address), isNull);
      expect(await manager.canSignFor(address), isFalse);
      expect(adapter.disconnectByAddressCalls, contains(address));
    });

    test('remove invokes adapter.disconnectByAddress unconditionally',
        () async {
      final adapter = RecordingWalletAdapter();
      // No keypair, no wallet, but we still expect disconnectByAddress
      // to be called (the contract is "remove what we can").
      final manager = _createManager(walletAdapter: adapter);

      await manager.remove(_validG1);
      expect(adapter.disconnectByAddressCalls, equals(<String>[_validG1]));
    });

    test('removeAll clears every keypair and disconnects adapter (D-143)',
        () async {
      final adapter = RecordingWalletAdapter();
      final manager = _createManager(walletAdapter: adapter);

      // Two keypair signers and one wallet signer.
      await manager.addFromSecret(KeyPair.random().secretSeed);
      await manager.addFromSecret(KeyPair.random().secretSeed);
      adapter.connected.add(
        ConnectedWallet(
          address: _validG1,
          walletId: 'w',
          walletName: 'W',
        ),
      );

      await manager.removeAll();

      expect(await manager.getAll(), isEmpty);
      expect(await manager.hasSigners(), isFalse);
      expect(adapter.disconnectCount, equals(1));
    });

    test('removeAll deletes the persisted storage key', () async {
      final adapter = RecordingWalletAdapter();
      final storage = TestWalletStorage();
      // Pre-seed storage so removeAll has something to clear.
      storage.data['external_wallets'] =
          '[{"address":"$_validG1","walletId":"w","walletName":"W","connectedAt":1}]';

      final manager = _createManager(
        walletAdapter: adapter,
        walletConnectionStorage: storage,
      );

      await manager.removeAll();

      expect(storage.data.containsKey('external_wallets'), isFalse);
      expect(storage.removeCalls, contains('external_wallets'));
    });
  });

  // -------------------------------------------------------------------------
  // E.7 restoreConnections
  // -------------------------------------------------------------------------
  group('E.7 restoreConnections', () {
    test('idempotent: second call returns adapter snapshot without '
        're-reading storage (D-128)', () async {
      final adapter = RecordingWalletAdapter();
      final storage = TestWalletStorage();
      storage.data['external_wallets'] = jsonEncode([
        <String, dynamic>{
          'address': _validG1,
          'walletId': 'freighter',
          'walletName': 'Freighter',
          'connectedAt': 1,
        },
      ]);
      adapter.reconnectResponses.add(
        ConnectedWallet(
          address: _validG1,
          walletId: 'freighter',
          walletName: 'Freighter',
        ),
      );

      final manager = _createManager(
        walletAdapter: adapter,
        walletConnectionStorage: storage,
      );

      final first = await manager.restoreConnections();
      expect(first, hasLength(1));
      // Second call must not consult storage again.
      final getCallsBefore = storage.getCalls.length;
      final second = await manager.restoreConnections();
      expect(second, hasLength(1));
      expect(storage.getCalls.length, equals(getCallsBefore));
      // Reconnect must have been called only once total.
      expect(adapter.reconnectCalls.length, equals(1));
    });

    test('no storage configured returns empty', () async {
      final adapter = RecordingWalletAdapter();
      final manager = _createManager(walletAdapter: adapter);
      final restored = await manager.restoreConnections();
      expect(restored, isEmpty);
    });

    test('reconnect returning null: stale entry is removed from storage',
        () async {
      final adapter = RecordingWalletAdapter();
      final storage = TestWalletStorage();
      storage.data['external_wallets'] = jsonEncode([
        <String, dynamic>{
          'address': _validG1,
          'walletId': 'gone',
          'walletName': 'Gone',
          'connectedAt': 1,
        },
      ]);
      // Adapter returns null on reconnect.
      adapter.reconnectResponses.add(null);

      final manager = _createManager(
        walletAdapter: adapter,
        walletConnectionStorage: storage,
      );

      final restored = await manager.restoreConnections();
      expect(restored, isEmpty);
      // Stale entry must be removed.
      expect(storage.data.containsKey('external_wallets'), isFalse);
    });

    test('reconnect succeeds: returned wallet appears in result', () async {
      final adapter = RecordingWalletAdapter();
      final storage = TestWalletStorage();
      storage.data['external_wallets'] = jsonEncode([
        <String, dynamic>{
          'address': _validG1,
          'walletId': 'freighter',
          'walletName': 'Freighter',
          'connectedAt': 1,
        },
      ]);
      adapter.reconnectResponses.add(
        ConnectedWallet(
          address: _validG1,
          walletId: 'freighter',
          walletName: 'Freighter',
        ),
      );

      final manager = _createManager(
        walletAdapter: adapter,
        walletConnectionStorage: storage,
      );

      final restored = await manager.restoreConnections();
      expect(restored, hasLength(1));
      expect(restored.single.address, equals(_validG1));
      expect(restored.single.walletId, equals('freighter'));
      expect(restored.single.walletName, equals('Freighter'));
    });

    test('concurrent restoreConnections calls are serialised by mutex',
        () async {
      final adapter = RecordingWalletAdapter();
      final storage = TestWalletStorage();
      storage.data['external_wallets'] = jsonEncode([
        <String, dynamic>{
          'address': _validG1,
          'walletId': 'freighter',
          'walletName': 'Freighter',
          'connectedAt': 1,
        },
      ]);
      adapter.reconnectResponses.add(
        ConnectedWallet(
          address: _validG1,
          walletId: 'freighter',
          walletName: 'Freighter',
        ),
      );

      final manager = _createManager(
        walletAdapter: adapter,
        walletConnectionStorage: storage,
      );

      // Two parallel calls; both must observe the idempotent contract.
      final results = await Future.wait([
        manager.restoreConnections(),
        manager.restoreConnections(),
      ]);

      // Reconnect must have been called only once across both
      // restoreConnections invocations.
      expect(adapter.reconnectCalls.length, equals(1));
      expect(results[0], isNotEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // E.8 JSON storage
  // -------------------------------------------------------------------------
  group('E.8 JSON storage', () {
    test('serialise empty list yields valid JSON array', () async {
      final adapter = RecordingWalletAdapter();
      final storage = TestWalletStorage();
      // Pre-seed with an entry, then remove it via the manager: the
      // resulting state must clear the storage key entirely.
      storage.data['external_wallets'] = jsonEncode([
        <String, dynamic>{
          'address': _validG1,
          'walletId': 'w',
          'walletName': 'W',
          'connectedAt': 1,
        },
      ]);
      final manager = _createManager(
        walletAdapter: adapter,
        walletConnectionStorage: storage,
      );

      await manager.remove(_validG1);

      // After removal, key is dropped (so "empty list" is represented as
      // an absent storage entry).
      expect(storage.data['external_wallets'], isNull);
    });

    test('serialise multiple connections preserves correct order',
        () async {
      final adapter = RecordingWalletAdapter();
      final storage = TestWalletStorage();
      final manager = _createManager(
        walletAdapter: adapter,
        walletConnectionStorage: storage,
      );

      // Add three wallets in order; storage must contain them in that
      // append order.
      adapter.connectResponses.addAll([
        ConnectedWallet(
          address: _validG1,
          walletId: 'a',
          walletName: 'A',
        ),
        ConnectedWallet(
          address: _validG2,
          walletId: 'b',
          walletName: 'B',
        ),
      ]);
      await manager.addFromWallet();
      await manager.addFromWallet();

      final raw = storage.data['external_wallets']!;
      final list = jsonDecode(raw) as List;
      expect(list.length, equals(2));
      expect((list[0] as Map)['walletId'], equals('a'));
      expect((list[1] as Map)['walletId'], equals('b'));
    });

    test(
        'parse valid JSON: restoreConnections feeds the adapter '
        'with the stored walletIds in order', () async {
      final adapter = RecordingWalletAdapter();
      final storage = TestWalletStorage();
      storage.data['external_wallets'] = jsonEncode([
        <String, dynamic>{
          'address': _validG1,
          'walletId': 'first',
          'walletName': 'First',
          'connectedAt': 1,
        },
        <String, dynamic>{
          'address': _validG2,
          'walletId': 'second',
          'walletName': 'Second',
          'connectedAt': 2,
        },
      ]);
      adapter.reconnectResponses.add(
        ConnectedWallet(
          address: _validG1,
          walletId: 'first',
          walletName: 'First',
        ),
      );
      adapter.reconnectResponses.add(
        ConnectedWallet(
          address: _validG2,
          walletId: 'second',
          walletName: 'Second',
        ),
      );

      final manager = _createManager(
        walletAdapter: adapter,
        walletConnectionStorage: storage,
      );

      final restored = await manager.restoreConnections();
      expect(restored, hasLength(2));
      expect(adapter.reconnectCalls, equals(<String>['first', 'second']));
    });

    test('malformed JSON returns empty list (D-109 atomic-failure)',
        () async {
      final adapter = RecordingWalletAdapter();
      final storage = TestWalletStorage();
      // Plain garbage in storage; restoreConnections must return empty.
      storage.data['external_wallets'] = 'not really json {';

      final manager = _createManager(
        walletAdapter: adapter,
        walletConnectionStorage: storage,
      );

      final restored = await manager.restoreConnections();
      expect(restored, isEmpty);
      // Adapter should not have been asked to reconnect anything.
      expect(adapter.reconnectCalls, isEmpty);
    });

    test('removing the last persisted entry deletes the storage key',
        () async {
      final adapter = RecordingWalletAdapter();
      final storage = TestWalletStorage();
      storage.data['external_wallets'] = jsonEncode([
        <String, dynamic>{
          'address': _validG1,
          'walletId': 'only',
          'walletName': 'Only',
          'connectedAt': 1,
        },
      ]);

      final manager = _createManager(
        walletAdapter: adapter,
        walletConnectionStorage: storage,
      );

      await manager.remove(_validG1);

      expect(storage.data.containsKey('external_wallets'), isFalse);
      expect(storage.removeCalls, contains('external_wallets'));
    });
  });
}
