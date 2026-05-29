// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Test fixtures

const String _testNetworkPassphrase = 'Test SDF Network ; September 2015';

const String _validG1 =
    'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';
const String _validG2 =
    'GBVRV25F7XA5I2L3ILSA6XW3OCWLKGGLG4OP2EHKTWC5IHQ3EV26FQLS';

/// In-memory [WalletConnectionStorage] with a public map for direct JSON inspection.
class TestWalletStorage extends WalletConnectionStorage {
  final Map<String, String> data = <String, String>{};

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

/// Recording [ExternalWalletAdapter]. FIFO queues: pop the next pre-configured
/// outcome per call (value or throwable); exhausted queues return null/default.
/// Inspect *Calls fields and *Count fields to assert interaction with the manager.
class RecordingWalletAdapter extends ExternalWalletAdapter {
  RecordingWalletAdapter();

  final List<Object?> connectResponses = <Object?>[];
  int connectCallCount = 0;

  final List<Object?> reconnectResponses = <Object?>[];
  final List<String> reconnectCalls = <String>[];

  final List<Object> signAuthEntryResponses = <Object>[];
  final List<({String preimageXdr, SignAuthEntryOptions? options})>
      signAuthEntryCalls =
      <({String preimageXdr, SignAuthEntryOptions? options})>[];

  final List<ConnectedWallet> connected = <ConnectedWallet>[];

  int disconnectCount = 0;

  final List<String> disconnectByAddressCalls = <String>[];

  bool throwOnDisconnect = false;

  /// When `true`, `canSignFor` raises a [StateError]; verifies the manager is
  /// defensive against adapter exceptions.
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

/// Well-formed C-strkey used as the Ed25519 verifier contract address in
/// tests.  Uses only the base32 alphabet (A-Z + 2-7); no 0/1/8/9.
const String _validContractVerifier =
    'CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM';

/// A second distinct verifier address for tests that exercise the
/// same-pubkey / different-verifier tuple semantics.
const String _validContractVerifier2 =
    'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK';

/// Adapter that always reports it can sign for every (verifierAddress,
/// publicKey) pair and signs using the supplied [keypair].
class _AlwaysSignAdapter extends OZExternalEd25519SignerAdapter {
  _AlwaysSignAdapter({required this.keypair});

  final KeyPair keypair;

  @override
  bool canSignFor(String verifierAddress, Uint8List publicKey) => true;

  @override
  Future<Uint8List> signAuthDigest(
    Uint8List authDigest,
    Uint8List publicKey,
  ) async {
    return Uint8List.fromList(keypair.sign(authDigest));
  }
}

/// Adapter that always reports it cannot sign for any (verifierAddress,
/// publicKey) pair.  Forces the fallback to the in-process keypair registry.
class _NeverSignAdapter extends OZExternalEd25519SignerAdapter {
  @override
  bool canSignFor(String verifierAddress, Uint8List publicKey) => false;

  @override
  Future<Uint8List> signAuthDigest(
    Uint8List authDigest,
    Uint8List publicKey,
  ) async {
    throw UnsupportedError('_NeverSignAdapter.signAuthDigest must never be called');
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
  group('addFromSecret', () {
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
        'the same address', () async {
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
      storage.data['oz_smart_account.connected_wallets'] = jsonEncode([
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
      expect(storage.data.containsKey('oz_smart_account.connected_wallets'), isFalse);
      // removeItem must have been called at least once for cleanup.
      expect(storage.removeCalls, contains('oz_smart_account.connected_wallets'));
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
  group('addFromWallet', () {
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
      expect(storage.data.containsKey('oz_smart_account.connected_wallets'), isTrue);
      final json = jsonDecode(storage.data['oz_smart_account.connected_wallets']!) as List;
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
  group('canSignFor', () {
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
  group('signAuthEntry', () {
    test('keypair signs SHA-256 of preimage with Ed25519',
        () async {
      final manager = _createManager();
      final keypair = KeyPair.random();
      final address =
          await manager.addFromSecret(keypair.secretSeed);

      // Construct an arbitrary preimage and verify the SDK signs the
      // SHA-256 hash of those bytes. We do this by directly verifying the
      // resulting signature against the same hash.
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

    test('no signer registered throws SignerNotFound', () async {
      final manager = _createManager();
      await expectLater(
        () => manager.signAuthEntry(_validG1, base64Encode(Uint8List(32))),
        throwsA(isA<SignerNotFound>()),
      );
    });

    test(
        'keypair takes precedence: wallet adapter is NOT consulted', () async {
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
  group('getAll / get / hasSigners', () {
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
  group('remove / removeAll', () {
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

    test('removeAll clears every keypair and disconnects adapter',
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
      storage.data['oz_smart_account.connected_wallets'] =
          '[{"address":"$_validG1","walletId":"w","walletName":"W","connectedAt":1}]';

      final manager = _createManager(
        walletAdapter: adapter,
        walletConnectionStorage: storage,
      );

      await manager.removeAll();

      expect(storage.data.containsKey('oz_smart_account.connected_wallets'), isFalse);
      expect(storage.removeCalls, contains('oz_smart_account.connected_wallets'));
    });
  });
  group('restoreConnections', () {
    test('idempotent: second call returns adapter snapshot without '
        're-reading storage', () async {
      final adapter = RecordingWalletAdapter();
      final storage = TestWalletStorage();
      storage.data['oz_smart_account.connected_wallets'] = jsonEncode([
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
      storage.data['oz_smart_account.connected_wallets'] = jsonEncode([
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
      expect(storage.data.containsKey('oz_smart_account.connected_wallets'), isFalse);
    });

    test('reconnect succeeds: returned wallet appears in result', () async {
      final adapter = RecordingWalletAdapter();
      final storage = TestWalletStorage();
      storage.data['oz_smart_account.connected_wallets'] = jsonEncode([
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
      storage.data['oz_smart_account.connected_wallets'] = jsonEncode([
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
  group('JSON storage', () {
    test('serialise empty list yields valid JSON array', () async {
      final adapter = RecordingWalletAdapter();
      final storage = TestWalletStorage();
      // Pre-seed with an entry, then remove it via the manager: the
      // resulting state must clear the storage key entirely.
      storage.data['oz_smart_account.connected_wallets'] = jsonEncode([
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
      expect(storage.data['oz_smart_account.connected_wallets'], isNull);
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

      final raw = storage.data['oz_smart_account.connected_wallets']!;
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
      storage.data['oz_smart_account.connected_wallets'] = jsonEncode([
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

    test('malformed JSON returns empty list',
        () async {
      final adapter = RecordingWalletAdapter();
      final storage = TestWalletStorage();
      // Plain garbage in storage; restoreConnections must return empty.
      storage.data['oz_smart_account.connected_wallets'] = 'not really json {';

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
      storage.data['oz_smart_account.connected_wallets'] = jsonEncode([
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

      expect(storage.data.containsKey('oz_smart_account.connected_wallets'), isFalse);
      expect(storage.removeCalls, contains('oz_smart_account.connected_wallets'));
    });
  });
  group('addEd25519FromRawKey', () {
    test(
        'test_addEd25519FromRawKey_validBytes_storesKeypairAndReturnsPublicKey',
        () {
      final manager = _createManager();
      final rawSeed = Uint8List.fromList(List<int>.generate(32, (i) => i));

      final publicKey = manager.addEd25519FromRawKey(
        secretKeyBytes: rawSeed,
        verifierAddress: _validContractVerifier,
      );

      expect(publicKey.length, equals(32));
      expect(
        manager.canSignEd25519For(
          verifierAddress: _validContractVerifier,
          publicKey: publicKey,
        ),
        isTrue,
      );
    });

    test(
        'test_addEd25519FromRawKey_tooShort_throwsInvalidInput',
        () {
      final manager = _createManager();

      expect(
        () => manager.addEd25519FromRawKey(
          secretKeyBytes: Uint8List.fromList(List<int>.generate(16, (i) => i)),
          verifierAddress: _validContractVerifier,
        ),
        throwsA(isA<InvalidInput>()),
      );
    });

    test(
        'test_addEd25519FromRawKey_tooLong_throwsInvalidInput',
        () {
      final manager = _createManager();

      expect(
        () => manager.addEd25519FromRawKey(
          secretKeyBytes: Uint8List.fromList(List<int>.generate(33, (i) => i)),
          verifierAddress: _validContractVerifier,
        ),
        throwsA(isA<InvalidInput>()),
      );
    });

    test(
        'test_addEd25519FromRawKey_sameKeyTwoVerifiers_storedAsDistinctEntries',
        () {
      final manager = _createManager();
      final rawSeed = Uint8List.fromList(List<int>.generate(32, (i) => i));

      final pk1 = manager.addEd25519FromRawKey(
        secretKeyBytes: rawSeed,
        verifierAddress: _validContractVerifier,
      );
      final pk2 = manager.addEd25519FromRawKey(
        secretKeyBytes: rawSeed,
        verifierAddress: _validContractVerifier2,
      );

      // Both keys are equal (same keypair), but two distinct registry slots
      // exist because the verifier addresses differ.
      expect(pk1, orderedEquals(pk2));
      expect(
        manager.canSignEd25519For(
          verifierAddress: _validContractVerifier,
          publicKey: pk1,
        ),
        isTrue,
      );
      expect(
        manager.canSignEd25519For(
          verifierAddress: _validContractVerifier2,
          publicKey: pk2,
        ),
        isTrue,
      );
    });
  });
  group('canSignEd25519For', () {
    test('test_canSignEd25519For_registered_returnsTrue', () {
      final manager = _createManager();
      final rawSeed = Uint8List.fromList(List<int>.generate(32, (i) => i + 1));
      final publicKey = manager.addEd25519FromRawKey(
        secretKeyBytes: rawSeed,
        verifierAddress: _validContractVerifier,
      );

      expect(
        manager.canSignEd25519For(
          verifierAddress: _validContractVerifier,
          publicKey: publicKey,
        ),
        isTrue,
      );
    });

    test('test_canSignEd25519For_unregistered_returnsFalse', () {
      final manager = _createManager();
      final randomKey = Uint8List.fromList(KeyPair.random().publicKey);

      expect(
        manager.canSignEd25519For(
          verifierAddress: _validContractVerifier,
          publicKey: randomKey,
        ),
        isFalse,
      );
    });
  });
  group('signEd25519AuthDigest', () {
    test(
        'test_signEd25519AuthDigest_registered_returnsValidSignature',
        () async {
      final manager = _createManager();
      final rawSeed = Uint8List.fromList(List<int>.generate(32, (i) => i + 2));
      final publicKey = manager.addEd25519FromRawKey(
        secretKeyBytes: rawSeed,
        verifierAddress: _validContractVerifier,
      );

      final authDigest = Uint8List.fromList(
        List<int>.generate(32, (i) => (i * 7) & 0xFF),
      );

      final signature = await manager.signEd25519AuthDigest(
        verifierAddress: _validContractVerifier,
        publicKey: publicKey,
        authDigest: authDigest,
      );

      expect(signature.length, equals(64));

      // Verify the signature against the public key and the raw auth digest
      // (no pre-hashing; Ed25519 signs the message directly).
      final verifier = KeyPair.fromPublicKey(publicKey);
      expect(verifier.verify(authDigest, signature), isTrue);
    });

    test(
        'test_signEd25519AuthDigest_unregistered_throwsValidation',
        () async {
      final manager = _createManager();
      final randomKey = Uint8List.fromList(KeyPair.random().publicKey);
      final authDigest = Uint8List(32);

      await expectLater(
        () => manager.signEd25519AuthDigest(
          verifierAddress: _validContractVerifier,
          publicKey: randomKey,
          authDigest: authDigest,
        ),
        throwsA(isA<InvalidInput>()),
      );
    });
  });
  group('removeEd25519', () {
    test('test_removeEd25519_clearsRegistration', () {
      final manager = _createManager();
      final rawSeed = Uint8List.fromList(List<int>.generate(32, (i) => i + 3));
      final publicKey = manager.addEd25519FromRawKey(
        secretKeyBytes: rawSeed,
        verifierAddress: _validContractVerifier,
      );

      expect(
        manager.canSignEd25519For(
          verifierAddress: _validContractVerifier,
          publicKey: publicKey,
        ),
        isTrue,
      );

      manager.removeEd25519(
        verifierAddress: _validContractVerifier,
        publicKey: publicKey,
      );

      expect(
        manager.canSignEd25519For(
          verifierAddress: _validContractVerifier,
          publicKey: publicKey,
        ),
        isFalse,
      );
    });
  });
  group('Ed25519 adapter precedence', () {
    test(
        'test_ed25519Adapter_takesPrecedenceForCanSignForTrue',
        () async {
      final keypair = KeyPair.random();
      final publicKey = Uint8List.fromList(keypair.publicKey);

      // Adapter injected at construction — always claims it can sign.
      final manager = OZExternalSignerManager(
        networkPassphrase: _testNetworkPassphrase,
        ed25519Adapter: _AlwaysSignAdapter(keypair: keypair),
      );

      expect(
        manager.canSignEd25519For(
          verifierAddress: _validContractVerifier,
          publicKey: publicKey,
        ),
        isTrue,
      );

      final authDigest = Uint8List.fromList(
        List<int>.generate(32, (i) => i & 0xFF),
      );
      final signature = await manager.signEd25519AuthDigest(
        verifierAddress: _validContractVerifier,
        publicKey: publicKey,
        authDigest: authDigest,
      );
      expect(signature.length, equals(64));
      final verifier = KeyPair.fromPublicKey(publicKey);
      expect(verifier.verify(authDigest, signature), isTrue);
    });

    test(
        'test_ed25519Adapter_falsyAdapterFallsBackToInProcessKeypair',
        () async {
      // Adapter injected at construction — claims it cannot sign for any key.
      final manager = OZExternalSignerManager(
        networkPassphrase: _testNetworkPassphrase,
        ed25519Adapter: _NeverSignAdapter(),
      );
      final rawSeed = Uint8List.fromList(List<int>.generate(32, (i) => i + 4));
      final publicKey = manager.addEd25519FromRawKey(
        secretKeyBytes: rawSeed,
        verifierAddress: _validContractVerifier,
      );

      // canSignEd25519For still returns true via the in-memory fallback.
      expect(
        manager.canSignEd25519For(
          verifierAddress: _validContractVerifier,
          publicKey: publicKey,
        ),
        isTrue,
      );

      final authDigest = Uint8List.fromList(
        List<int>.generate(32, (i) => (i + 3) & 0xFF),
      );
      final signature = await manager.signEd25519AuthDigest(
        verifierAddress: _validContractVerifier,
        publicKey: publicKey,
        authDigest: authDigest,
      );
      final verifier = KeyPair.fromPublicKey(publicKey);
      expect(verifier.verify(authDigest, signature), isTrue);
    });
  });
  group('removeAll clears Ed25519 registrations', () {
    test(
        'test_removeAll_clearsEd25519RegistrationsAlongsideWalletSigners',
        () async {
      final adapter = RecordingWalletAdapter();
      final manager = _createManager(walletAdapter: adapter);

      // Register one wallet signer.
      final walletKeypair = KeyPair.random();
      await manager.addFromSecret(walletKeypair.secretSeed);
      final walletAddress = walletKeypair.accountId;

      // Register one Ed25519 signer.
      final ed25519RawSeed =
          Uint8List.fromList(List<int>.generate(32, (i) => i + 5));
      final ed25519PublicKey = manager.addEd25519FromRawKey(
        secretKeyBytes: ed25519RawSeed,
        verifierAddress: _validContractVerifier,
      );

      // Confirm both are reachable before removeAll.
      expect(await manager.canSignFor(walletAddress), isTrue);
      expect(
        manager.canSignEd25519For(
          verifierAddress: _validContractVerifier,
          publicKey: ed25519PublicKey,
        ),
        isTrue,
      );

      await manager.removeAll();

      expect(await manager.canSignFor(walletAddress), isFalse);
      expect(
        manager.canSignEd25519For(
          verifierAddress: _validContractVerifier,
          publicKey: ed25519PublicKey,
        ),
        isFalse,
      );
    });
  });

  group('ExternalSignerInfo equality and hashCode', () {
    test('equalInstances_areEqual', () {
      // Non-const to avoid Dart canonicalization making identical() true.
      final a = ExternalSignerInfo(
        address: _validG1,
        type: ExternalSignerType.keypair,
        walletName: 'Freighter',
        walletId: 'freighter',
      );
      final b = ExternalSignerInfo(
        address: _validG1,
        type: ExternalSignerType.keypair,
        walletName: 'Freighter',
        walletId: 'freighter',
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('differentWalletName_notEqual', () {
      // Exercises lines 151-152 in oz_external_signer_manager.dart.
      final a = ExternalSignerInfo(
        address: _validG1,
        type: ExternalSignerType.wallet,
        walletName: 'Freighter',
        walletId: 'freighter',
      );
      final b = ExternalSignerInfo(
        address: _validG1,
        type: ExternalSignerType.wallet,
        walletName: 'LOBSTR',
        walletId: 'freighter',
      );
      expect(a == b, isFalse);
    });

    test('differentWalletId_notEqual', () {
      final a = ExternalSignerInfo(
        address: _validG1,
        type: ExternalSignerType.wallet,
        walletName: 'Freighter',
        walletId: 'freighter',
      );
      final b = ExternalSignerInfo(
        address: _validG1,
        type: ExternalSignerType.wallet,
        walletName: 'Freighter',
        walletId: 'lobstr',
      );
      expect(a == b, isFalse);
    });

    test('differentAddress_notEqual', () {
      final a = ExternalSignerInfo(address: _validG1, type: ExternalSignerType.keypair);
      final b = ExternalSignerInfo(address: _validG2, type: ExternalSignerType.keypair);
      expect(a == b, isFalse);
    });

    test('differentType_notEqual', () {
      final a = ExternalSignerInfo(address: _validG1, type: ExternalSignerType.keypair);
      final b = ExternalSignerInfo(address: _validG1, type: ExternalSignerType.wallet);
      expect(a == b, isFalse);
    });

    test('toString_containsFields', () {
      final a = ExternalSignerInfo(
        address: _validG1,
        type: ExternalSignerType.keypair,
        walletName: 'Freighter',
      );
      expect(a.toString(), contains(_validG1));
    });

    test('nonSignerInfoType_notEqual', () {
      final a = ExternalSignerInfo(address: _validG1, type: ExternalSignerType.keypair);
      expect(a == 'not-a-signer-info', isFalse);
    });

    test('identical_isEqual', () {
      final a = ExternalSignerInfo(address: _validG1, type: ExternalSignerType.keypair);
      expect(a == a, isTrue);
    });
  });

  group('addFromWallet error paths', () {
    test('noWalletAdapter_throwsMissingConfig', () async {
      final manager = _createManager(); // no walletAdapter
      await expectLater(
        manager.addFromWallet(),
        throwsA(isA<MissingConfig>()),
      );
    });

    test('adapterReturnsNull_returnsNull', () async {
      final adapter = RecordingWalletAdapter();
      // connectResponses empty -> connect() returns null
      final manager = _createManager(walletAdapter: adapter);
      final result = await manager.addFromWallet();
      expect(result, isNull);
    });

    test('adapterReturnsWallet_withStorage_savesConnection', () async {
      final adapter = RecordingWalletAdapter();
      const wallet = ConnectedWallet(
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
      // Storage should have been written.
      expect(storage.setCalls, isNotEmpty);
    });
  });

  group('restoreConnections', () {
    test('noStorageAndNoAdapter_returnsEmpty', () async {
      final manager = _createManager();
      final restored = await manager.restoreConnections();
      expect(restored, isEmpty);
    });

    test('withStorageAndAdapter_restoresConnections', () async {
      final adapter = RecordingWalletAdapter();
      const wallet = ConnectedWallet(
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

      // First add a wallet so it is stored.
      await manager.addFromWallet();
      // Now restore (reset manager state by creating fresh instance with same storage).
      final manager2 = OZExternalSignerManager(
        networkPassphrase: _testNetworkPassphrase,
        walletAdapter: adapter,
        walletConnectionStorage: storage,
      );
      adapter.reconnectResponses.add(wallet);

      final restored = await manager2.restoreConnections();
      expect(restored, isNotEmpty);
    });
  });

  group('get (getSignerInfo) not-found', () {
    test('unknownAddress_returnsNull', () async {
      final manager = _createManager();
      final info = await manager.get('GDAT5HWTGIU4TSSZ4752OUC4SABDLTLZFRPZUJ3D6LKBNEPA7V2CIG54');
      expect(info, isNull);
    });

    test('keypairAddress_returnsKeypairInfo', () async {
      final manager = _createManager();
      final keypair = KeyPair.random();
      await manager.addFromSecret(keypair.secretSeed!);
      final info = await manager.get(keypair.accountId);
      expect(info, isNotNull);
      expect(info!.type, ExternalSignerType.keypair);
    });
  });

  group('InMemoryWalletConnectionStorage concurrent ordering', () {
    test('concurrentWrites_areOrdered', () async {
      final storage = InMemoryWalletConnectionStorage();

      await Future.wait(<Future<void>>[
        storage.setItem('key1', 'value1'),
        storage.setItem('key2', 'value2'),
        storage.setItem('key3', 'value3'),
      ]);

      expect(await storage.getItem('key1'), 'value1');
      expect(await storage.getItem('key2'), 'value2');
      expect(await storage.getItem('key3'), 'value3');
    });

    test('removeItem_onMissingKey_doesNotThrow', () async {
      final storage = InMemoryWalletConnectionStorage();
      await expectLater(storage.removeItem('missing'), completes);
    });
  });
}
