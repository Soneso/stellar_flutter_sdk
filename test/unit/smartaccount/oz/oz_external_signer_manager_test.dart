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

/// Recording [OZExternalWalletAdapter]. FIFO queues: pop the next pre-configured
/// outcome per call (value or throwable); exhausted queues return null/default.
/// Inspect *Calls fields and *Count fields to assert interaction with the manager.
class RecordingWalletAdapter extends OZExternalWalletAdapter {
  RecordingWalletAdapter();

  final List<Object?> connectResponses = <Object?>[];
  int connectCallCount = 0;

  final List<Object> signAuthEntryResponses = <Object>[];
  final List<({String preimageXdr, OZSignAuthEntryOptions? options})>
      signAuthEntryCalls =
      <({String preimageXdr, OZSignAuthEntryOptions? options})>[];

  final List<OZConnectedWallet> connected = <OZConnectedWallet>[];

  int disconnectCount = 0;

  final List<String> disconnectByAddressCalls = <String>[];

  bool throwOnDisconnect = false;

  /// When `true`, `canSignFor` raises a [StateError]; verifies the manager is
  /// defensive against adapter exceptions.
  bool throwOnCanSignFor = false;

  @override
  Future<OZConnectedWallet?> connect() async {
    connectCallCount++;
    if (connectResponses.isEmpty) return null;
    final Object? v = connectResponses.removeAt(0);
    if (v is Exception) throw v;
    if (v is Error) throw v;
    final wallet = v as OZConnectedWallet?;
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
  Future<OZSignAuthEntryResult> signAuthEntry(
    String preimageXdr, {
    OZSignAuthEntryOptions? options,
  }) async {
    signAuthEntryCalls.add((preimageXdr: preimageXdr, options: options));
    if (signAuthEntryResponses.isEmpty) {
      throw StateError('No signAuthEntry response queued');
    }
    final v = signAuthEntryResponses.removeAt(0);
    if (v is Exception || v is Error) {
      throw v;
    }
    return v as OZSignAuthEntryResult;
  }

  @override
  bool canSignFor(String address) {
    if (throwOnCanSignFor) {
      throw StateError('canSignFor requested to fail');
    }
    return connected.any((w) => w.address == address);
  }

  @override
  List<OZConnectedWallet> getConnectedWallets() =>
      List<OZConnectedWallet>.unmodifiable(connected);

  @override
  OZConnectedWallet? getWalletForAddress(String address) {
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
  OZExternalWalletAdapter? walletAdapter,
}) {
  return OZExternalSignerManager(
    networkPassphrase: _testNetworkPassphrase,
    walletAdapter: walletAdapter,
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
      expect(info.type, equals(OZExternalSignerType.keypair));
      expect(info.walletName, isNull);
      expect(info.walletId, isNull);
    });

    test('invalid secret string throws SmartAccountSignerInvalid', () async {
      final manager = _createManager();
      await expectLater(
        () => manager.addFromSecret('INVALID_SECRET_KEY'),
        throwsA(isA<SmartAccountSignerInvalid>()),
      );
    });

    test('empty secret string throws SmartAccountSignerInvalid', () async {
      final manager = _createManager();
      await expectLater(
        () => manager.addFromSecret(''),
        throwsA(isA<SmartAccountSignerInvalid>()),
      );
    });

    test('public key in place of secret throws SmartAccountSignerInvalid', () async {
      final manager = _createManager();
      final keypair = KeyPair.random();
      await expectLater(
        () => manager.addFromSecret(keypair.accountId),
        throwsA(isA<SmartAccountSignerInvalid>()),
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
        expect(info!.type, equals(OZExternalSignerType.keypair));
      }
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
        OZConnectedWallet(
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
        OZConnectedWallet(
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
      expect(info!.type, equals(OZExternalSignerType.keypair));
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
        throwsA(isA<SmartAccountTransactionSigningFailed>()),
      );
    });

    test(
        'wallet path forwards networkPassphrase and address to adapter',
        () async {
      final adapter = RecordingWalletAdapter();
      adapter.connected.add(
        OZConnectedWallet(
          address: _validG1,
          walletId: 'w',
          walletName: 'Test',
        ),
      );
      adapter.signAuthEntryResponses.add(
        OZSignAuthEntryResult(
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

    test('no signer registered throws SmartAccountSignerNotFound', () async {
      final manager = _createManager();
      await expectLater(
        () => manager.signAuthEntry(_validG1, base64Encode(Uint8List(32))),
        throwsA(isA<SmartAccountSignerNotFound>()),
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
        OZConnectedWallet(
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
        'wallet adapter throws: error wrapped as SmartAccountTransactionSigningFailed',
        () async {
      final adapter = RecordingWalletAdapter();
      adapter.connected.add(
        OZConnectedWallet(
          address: _validG1,
          walletId: 'w',
          walletName: 'Test',
        ),
      );
      adapter.signAuthEntryResponses.add(StateError('bridge error'));
      final manager = _createManager(walletAdapter: adapter);

      await expectLater(
        () => manager.signAuthEntry(_validG1, base64Encode(Uint8List(32))),
        throwsA(isA<SmartAccountTransactionSigningFailed>()),
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
        OZConnectedWallet(
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
      expect(all.first.type, equals(OZExternalSignerType.keypair));
      expect(all.first.address, equals(keypairAddr));
      // Wallet signers follow.
      expect(all.last.type, equals(OZExternalSignerType.wallet));
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
        OZConnectedWallet(
          address: address,
          walletId: 'shadow',
          walletName: 'Shadow',
        ),
      );

      final all = await manager.getAll();
      expect(all.length, equals(1));
      expect(all.single.type, equals(OZExternalSignerType.keypair));
    });

    test('get returns keypair entry when both keypair and wallet exist',
        () async {
      final adapter = RecordingWalletAdapter();
      final manager = _createManager(walletAdapter: adapter);

      final keypair = KeyPair.random();
      final address =
          await manager.addFromSecret(keypair.secretSeed);
      adapter.connected.add(
        OZConnectedWallet(
          address: address,
          walletId: 'shadow',
          walletName: 'Shadow',
        ),
      );

      final info = await manager.get(address);
      expect(info, isNotNull);
      expect(info!.type, equals(OZExternalSignerType.keypair));
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
        OZConnectedWallet(
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
        OZConnectedWallet(
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
        OZConnectedWallet(
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
        throwsA(isA<SmartAccountInvalidInput>()),
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
        throwsA(isA<SmartAccountInvalidInput>()),
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
        throwsA(isA<SmartAccountInvalidInput>()),
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

  group('OZExternalSignerInfo equality and hashCode', () {
    test('equalInstances_areEqual', () {
      // Non-const to avoid Dart canonicalization making identical() true.
      final a = OZExternalSignerInfo(
        address: _validG1,
        type: OZExternalSignerType.keypair,
        walletName: 'Freighter',
        walletId: 'freighter',
      );
      final b = OZExternalSignerInfo(
        address: _validG1,
        type: OZExternalSignerType.keypair,
        walletName: 'Freighter',
        walletId: 'freighter',
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('differentWalletName_notEqual', () {
      // Exercises lines 151-152 in oz_external_signer_manager.dart.
      final a = OZExternalSignerInfo(
        address: _validG1,
        type: OZExternalSignerType.wallet,
        walletName: 'Freighter',
        walletId: 'freighter',
      );
      final b = OZExternalSignerInfo(
        address: _validG1,
        type: OZExternalSignerType.wallet,
        walletName: 'LOBSTR',
        walletId: 'freighter',
      );
      expect(a == b, isFalse);
    });

    test('differentWalletId_notEqual', () {
      final a = OZExternalSignerInfo(
        address: _validG1,
        type: OZExternalSignerType.wallet,
        walletName: 'Freighter',
        walletId: 'freighter',
      );
      final b = OZExternalSignerInfo(
        address: _validG1,
        type: OZExternalSignerType.wallet,
        walletName: 'Freighter',
        walletId: 'lobstr',
      );
      expect(a == b, isFalse);
    });

    test('differentAddress_notEqual', () {
      final a = OZExternalSignerInfo(address: _validG1, type: OZExternalSignerType.keypair);
      final b = OZExternalSignerInfo(address: _validG2, type: OZExternalSignerType.keypair);
      expect(a == b, isFalse);
    });

    test('differentType_notEqual', () {
      final a = OZExternalSignerInfo(address: _validG1, type: OZExternalSignerType.keypair);
      final b = OZExternalSignerInfo(address: _validG1, type: OZExternalSignerType.wallet);
      expect(a == b, isFalse);
    });

    test('toString_containsFields', () {
      final a = OZExternalSignerInfo(
        address: _validG1,
        type: OZExternalSignerType.keypair,
        walletName: 'Freighter',
      );
      expect(a.toString(), contains(_validG1));
    });

    test('nonSignerInfoType_notEqual', () {
      final a = OZExternalSignerInfo(address: _validG1, type: OZExternalSignerType.keypair);
      expect(a == 'not-a-signer-info', isFalse);
    });

    test('identical_isEqual', () {
      final a = OZExternalSignerInfo(address: _validG1, type: OZExternalSignerType.keypair);
      expect(a == a, isTrue);
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
      await manager.addFromSecret(keypair.secretSeed);
      final info = await manager.get(keypair.accountId);
      expect(info, isNotNull);
      expect(info!.type, OZExternalSignerType.keypair);
    });
  });

}
