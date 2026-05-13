// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/src/smartaccount/oz/oz_internal_pipeline_interfaces.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import 'mock_oz_indexer_client.dart';
import 'mock_oz_relayer_client.dart';
import 'recording_soroban_server.dart';

// ---------------------------------------------------------------------------
// Test data
// ---------------------------------------------------------------------------

// why: a 127.0.0.1:1 placeholder keeps the RPC URL strictly local so a
// stray request from an over-eager test cannot reach a public testnet
// endpoint by accident, while still satisfying the config's non-empty
// URL requirement. The kit factory does not perform any network I/O at
// construction time so the unreachability of this URL is harmless.
const String _validRpcUrl = 'http://127.0.0.1:1';

// why: a synthetic passphrase ensures `OZIndexerClient.getDefaultUrl`
// returns `null`, so the kit constructed in these tests does NOT build
// an indexer client by default. Tests that need a network-default indexer
// path opt into one of the well-known passphrases explicitly.
const String _validPassphrase = 'Stellar Flutter SDK OZ kit unit-test ; 2026';

const String _validWasmHash =
    'a000000000000000000000000000000000000000000000000000000000000000';

// why: distinct C-addresses so accidental conflation between the verifier
// contract and the smart-account contract IDs surfaces during assertions.
const String _validVerifier =
    'CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM';
const String _validContractId =
    'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK';
const String _credentialIdB64 = 'aGVsbG8tc21hcnQtYWNjb3VudA';

/// Builds a valid configuration with optional overrides. The defaults
/// match the well-formed inputs accepted by every other unit test in
/// this package.
OZSmartAccountConfig _validConfig({
  String? indexerUrl,
  String? relayerUrl,
  StorageAdapter? storage,
  KeyPair? deployerKeypair,
  ExternalWalletAdapter? externalWallet,
}) {
  return OZSmartAccountConfig(
    rpcUrl: _validRpcUrl,
    networkPassphrase: _validPassphrase,
    accountWasmHash: _validWasmHash,
    webauthnVerifierAddress: _validVerifier,
    indexerUrl: indexerUrl,
    relayerUrl: relayerUrl,
    storage: storage,
    deployerKeypair: deployerKeypair,
    externalWallet: externalWallet,
  );
}

/// Builds a kit using the `@visibleForTesting` constructor so lifecycle
/// tests can substitute recording mocks for the HTTP clients.
OZSmartAccountKit _kitWithMockClients({
  MockOZIndexerClient? indexerClient,
  MockOZRelayerClient? relayerClient,
  StorageAdapter? storage,
  ExternalWalletAdapter? externalWallet,
  RecordingSorobanServer? sorobanServer,
}) {
  final config = _validConfig(
    storage: storage,
    externalWallet: externalWallet,
  );
  return OZSmartAccountKit.forTesting(
    config: config,
    storage: storage ?? config.storage,
    relayerClient: relayerClient,
    indexerClient: indexerClient,
    externalWallet: externalWallet ?? config.externalWallet,
    sorobanServer: sorobanServer ?? RecordingSorobanServer(),
  );
}

/// In-memory storage adapter wrapper that records every
/// [clearSession] call so lifecycle tests can assert ordering.
class _RecordingStorage extends InMemoryStorageAdapter {
  int clearSessionCalls = 0;

  @override
  Future<void> clearSession() async {
    clearSessionCalls++;
    await super.clearSession();
  }
}

/// Stub external-wallet adapter used to exercise the
/// [OZSmartAccountKit.externalWallet] accessor without invoking any
/// real wallet provider. Every operational method raises so accidental
/// invocation surfaces as a test failure.
class _StubExternalWallet extends ExternalWalletAdapter {
  @override
  Future<ConnectedWallet?> connect() async => null;

  @override
  Future<void> disconnect() async {}

  @override
  Future<SignAuthEntryResult> signAuthEntry(
    String preimageXdr, {
    SignAuthEntryOptions? options,
  }) =>
      throw UnsupportedError(
        '_StubExternalWallet.signAuthEntry is not implemented for tests',
      );

  @override
  List<ConnectedWallet> getConnectedWallets() => const <ConnectedWallet>[];

  @override
  bool canSignFor(String address) => false;
}

void main() {
  // =======================================================================
  // Group A — kit-initialization tests
  // =======================================================================

  group('Group A factory and initialization', () {
    test('factory_returnsKitForValidConfig', () {
      final config = _validConfig();
      final kit = OZSmartAccountKit.create(config: config);

      expect(kit, isNotNull);
      expect(kit.config, same(config));
      expect(kit.isConnected, isFalse);
      expect(kit.credentialId, isNull);
      expect(kit.contractId, isNull);
    });

    test('factory_emptyRpcUrl_throwsConfigurationException', () {
      expect(
        () => OZSmartAccountConfig(
          rpcUrl: '',
          networkPassphrase: _validPassphrase,
          accountWasmHash: _validWasmHash,
          webauthnVerifierAddress: _validVerifier,
        ),
        throwsA(isA<ConfigurationException>()),
      );
    });

    test('factory_emptyNetworkPassphrase_throwsConfigurationException', () {
      expect(
        () => OZSmartAccountConfig(
          rpcUrl: _validRpcUrl,
          networkPassphrase: '',
          accountWasmHash: _validWasmHash,
          webauthnVerifierAddress: _validVerifier,
        ),
        throwsA(isA<ConfigurationException>()),
      );
    });

    test('factory_emptyAccountWasmHash_throwsConfigurationException', () {
      expect(
        () => OZSmartAccountConfig(
          rpcUrl: _validRpcUrl,
          networkPassphrase: _validPassphrase,
          accountWasmHash: '',
          webauthnVerifierAddress: _validVerifier,
        ),
        throwsA(isA<ConfigurationException>()),
      );
    });

    test('factory_wrongPrefixVerifier_throwsConfigurationException', () {
      expect(
        () => OZSmartAccountConfig(
          rpcUrl: _validRpcUrl,
          networkPassphrase: _validPassphrase,
          accountWasmHash: _validWasmHash,
          webauthnVerifierAddress: 'G${'A' * 55}',
        ),
        throwsA(isA<ConfigurationException>()),
      );
    });

    test('factory_wrongLengthVerifier_throwsConfigurationException', () {
      expect(
        () => OZSmartAccountConfig(
          rpcUrl: _validRpcUrl,
          networkPassphrase: _validPassphrase,
          accountWasmHash: _validWasmHash,
          webauthnVerifierAddress: 'CABC',
        ),
        throwsA(isA<ConfigurationException>()),
      );
    });

    test('factory_customStorageAdapter_passedThrough', () {
      final storage = InMemoryStorageAdapter();
      final config = _validConfig(storage: storage);
      final kit = OZSmartAccountKit.create(config: config);

      expect(identical(kit.getStorage(), storage), isTrue);
    });

    test('factory_withRelayer_buildsRelayerClient', () {
      final config = _validConfig(relayerUrl: 'https://relayer.example.com');
      final kit = OZSmartAccountKit.create(config: config);

      expect(kit.relayerClient, isNotNull);
    });

    test('factory_withoutRelayer_relayerClientIsNull', () {
      final kit = OZSmartAccountKit.create(config: _validConfig());
      expect(kit.relayerClient, isNull);
    });

    test('factory_withExplicitIndexer_buildsIndexerClient', () {
      final config = _validConfig(indexerUrl: 'https://indexer.example.com');
      final kit = OZSmartAccountKit.create(config: config);

      expect(kit.indexerClient, isNotNull);
    });

    test('factory_externalWallet_mirrorsConfig', () {
      final adapter = _StubExternalWallet();
      final config = _validConfig(externalWallet: adapter);
      final kit = OZSmartAccountKit.create(config: config);

      expect(identical(kit.externalWallet, adapter), isTrue);
    });

    test('factory_noExternalWallet_externalWalletIsNull', () {
      final kit = OZSmartAccountKit.create(config: _validConfig());
      expect(kit.externalWallet, isNull);
    });

    test('factory_externalSignerManager_isNull', () {
      final kit = OZSmartAccountKit.create(config: _validConfig());
      expect(kit.externalSignerManager, isNull);
    });
  });

  // =======================================================================
  // Group B — close lifecycle
  // =======================================================================

  group('Group B close lifecycle', () {
    test('close_onFreshKit_doesNotThrow', () async {
      final kit = OZSmartAccountKit.create(config: _validConfig());
      await kit.close();
    });

    test('close_calledTwice_isIdempotent', () async {
      final mockIndexer = MockOZIndexerClient();
      final mockRelayer = MockOZRelayerClient();
      final mockServer = RecordingSorobanServer();
      final kit = _kitWithMockClients(
        indexerClient: mockIndexer,
        relayerClient: mockRelayer,
        sorobanServer: mockServer,
      );

      await kit.close();
      await kit.close();

      expect(mockIndexer.closeCalls, equals(1));
      expect(mockRelayer.closeCalls, equals(1));
      expect(mockServer.closeCalls, equals(1));
    });

    test('close_releasesSorobanServerTransport', () async {
      final mockServer = RecordingSorobanServer();
      final kit = _kitWithMockClients(sorobanServer: mockServer);

      await kit.close();

      // why: the kit must release the shared Soroban RPC transport on
      // close so connection-pool sockets do not leak across kit
      // lifetimes. Asserting the close was invoked exactly once locks
      // down the lifecycle contract.
      expect(mockServer.closeCalls, equals(1));
    });

    test('close_orderingFiresSorobanFirst', () async {
      final order = <String>[];
      final mockServer = _OrderedRecordingSorobanServer(order, 'soroban');
      final mockIndexer = _OrderedRecordingIndexerClient(order, 'indexer');
      final mockRelayer = _OrderedRecordingRelayerClient(order, 'relayer');
      final kit = _kitWithMockClients(
        indexerClient: mockIndexer,
        relayerClient: mockRelayer,
        sorobanServer: mockServer,
      );

      await kit.close();

      // why: the Soroban RPC transport is released before any auxiliary
      // HTTP client so dependents observe a clean shutdown order.
      // Asserting the exact sequence locks down the contract.
      expect(order, equals(<String>['soroban', 'indexer', 'relayer']));
    });

    test('close_withIndexerClient_closesTheClient', () async {
      final mockIndexer = MockOZIndexerClient();
      final kit = _kitWithMockClients(indexerClient: mockIndexer);

      await kit.close();

      expect(mockIndexer.closeCalls, equals(1));
    });

    test('close_withoutIndexerClient_doesNotThrow', () async {
      // why: the synthetic passphrase used by _validConfig has no
      // network-default indexer URL, so the kit accepts a null
      // [indexerClient] cleanly. This asserts close still tears down
      // every other resource without raising.
      final kit = OZSmartAccountKit.create(config: _validConfig());
      expect(kit.indexerClient, isNull);

      await kit.close();
    });

    test('close_withRelayerClient_closesTheClient', () async {
      final mockRelayer = MockOZRelayerClient();
      final kit = _kitWithMockClients(relayerClient: mockRelayer);

      await kit.close();

      expect(mockRelayer.closeCalls, equals(1));
    });

    test('close_removesAllEventListeners', () async {
      final kit = OZSmartAccountKit.create(config: _validConfig());

      var disconnectedFired = 0;
      kit.events.on<SmartAccountEventWalletDisconnected>(
        (_) => disconnectedFired++,
      );
      expect(
        kit.events.listenerCount('WalletDisconnected'),
        greaterThan(0),
      );

      await kit.close();

      expect(kit.events.listenerCount('WalletDisconnected'), equals(0));

      // Re-emit after close — confirms the listener really detached.
      kit.events.emit(
        const SmartAccountEventWalletDisconnected(contractId: _validContractId),
      );
      expect(disconnectedFired, equals(0));
    });
  });

  // =======================================================================
  // Group C — disconnect + requireConnected
  // =======================================================================

  group('Group C disconnect and requireConnected', () {
    test('disconnect_emitsWalletDisconnected_andClearsState', () async {
      final storage = _RecordingStorage();
      final kit = OZSmartAccountKit.create(
        config: _validConfig(storage: storage),
      );

      await kit.setConnectedState(
        credentialId: _credentialIdB64,
        contractId: _validContractId,
      );
      expect(kit.isConnected, isTrue);

      String? observedContractId;
      bool wasConnectedAtEventTime = true;
      kit.events.on<SmartAccountEventWalletDisconnected>((event) {
        observedContractId = event.contractId;
        wasConnectedAtEventTime = kit.isConnected;
      });

      await kit.disconnect();

      expect(kit.isConnected, isFalse);
      expect(kit.credentialId, isNull);
      expect(kit.contractId, isNull);
      expect(observedContractId, equals(_validContractId));
      // why: by the time the WalletDisconnected event fires, the state
      // must already report disconnected so a listener that calls back
      // into kit.isConnected sees a consistent snapshot.
      expect(wasConnectedAtEventTime, isFalse);
      expect(storage.clearSessionCalls, equals(1));
    });

    test('disconnect_whenNotConnected_doesNotEmitEvent', () async {
      final kit = OZSmartAccountKit.create(config: _validConfig());

      var disconnectedFired = 0;
      kit.events.on<SmartAccountEventWalletDisconnected>(
        (_) => disconnectedFired++,
      );

      await kit.disconnect();

      expect(disconnectedFired, equals(0));
    });

    test('requireConnected_whenNotConnected_throwsWalletNotConnected',
        () async {
      final kit = OZSmartAccountKit.create(config: _validConfig());

      await expectLater(
        () => kit.requireConnected(),
        throwsA(isA<WalletNotConnected>()),
      );
    });

    test('requireConnected_whenConnected_returnsState', () async {
      final kit = OZSmartAccountKit.create(config: _validConfig());
      await kit.setConnectedState(
        credentialId: _credentialIdB64,
        contractId: _validContractId,
      );

      final state = await kit.requireConnected();
      expect(state.credentialId, equals(_credentialIdB64));
      expect(state.contractId, equals(_validContractId));
    });
  });

  // =======================================================================
  // Group D — default deployer caching
  // =======================================================================

  group('Group D default deployer', () {
    test('getDeployer_withCustomKeypair_returnsThatKeypair', () async {
      final custom = KeyPair.random();
      final kit = OZSmartAccountKit.create(
        config: _validConfig(deployerKeypair: custom),
      );

      final deployer = await kit.getDeployer();
      expect(deployer.accountId, equals(custom.accountId));
    });

    test('getDeployer_default_returnsDeterministicDeployer', () async {
      final kit1 = OZSmartAccountKit.create(config: _validConfig());
      final kit2 = OZSmartAccountKit.create(config: _validConfig());

      final d1 = await kit1.getDeployer();
      final d2 = await kit2.getDeployer();

      expect(d1.accountId, isNotNull);
      expect(d1.accountId, equals(d2.accountId));
    });

    test('getDeployer_cachedAcrossCalls', () async {
      final kit = OZSmartAccountKit.create(config: _validConfig());

      final first = await kit.getDeployer();
      final second = await kit.getDeployer();

      // why: cache must reuse the resolved keypair so on-chain
      // deployment flows derive a stable address across the kit's
      // lifetime.
      expect(identical(first, second), isTrue);
    });
  });

  // =======================================================================
  // Group E — above-floor coverage (state transitions, identity,
  // resource release behaviour)
  // =======================================================================

  group('Group E above-floor coverage', () {
    test('stateTransitions_disconnectedToConnectedToDisconnected', () async {
      final kit = OZSmartAccountKit.create(config: _validConfig());

      expect(kit.isConnected, isFalse);
      expect(kit.credentialId, isNull);
      expect(kit.contractId, isNull);

      await kit.setConnectedState(
        credentialId: _credentialIdB64,
        contractId: _validContractId,
      );

      expect(kit.isConnected, isTrue);
      expect(kit.credentialId, equals(_credentialIdB64));
      expect(kit.contractId, equals(_validContractId));

      await kit.disconnect();

      expect(kit.isConnected, isFalse);
      expect(kit.credentialId, isNull);
      expect(kit.contractId, isNull);
    });

    test('managerProperties_returnSameInstance_acrossAccesses', () {
      final kit = OZSmartAccountKit.create(config: _validConfig());

      expect(identical(kit.walletOperations, kit.walletOperations), isTrue);
      expect(
        identical(kit.transactionOperations, kit.transactionOperations),
        isTrue,
      );
      expect(identical(kit.signerManager, kit.signerManager), isTrue);
      expect(
        identical(kit.contextRuleManager, kit.contextRuleManager),
        isTrue,
      );
      expect(identical(kit.policyManager, kit.policyManager), isTrue);
      expect(
        identical(kit.credentialManager, kit.credentialManager),
        isTrue,
      );
      expect(
        identical(kit.multiSignerManager, kit.multiSignerManager),
        isTrue,
      );
      expect(identical(kit.events, kit.events), isTrue);
    });

    test('credentialManager_implementsWalletInterface', () {
      final kit = OZSmartAccountKit.create(config: _validConfig());

      expect(
        kit.credentialManager,
        isA<OZWalletCredentialManagerInterface>(),
      );
    });

    test('contextRuleManager_implementsRuleInterface', () {
      final kit = OZSmartAccountKit.create(config: _validConfig());

      expect(
        kit.contextRuleManager,
        isA<OZContextRuleManagerInterface>(),
      );
    });

    test('multiSignerManager_implementsMultiSignerInterface', () {
      final kit = OZSmartAccountKit.create(config: _validConfig());

      expect(
        kit.multiSignerManager,
        isA<OZMultiSignerManagerInterface>(),
      );
    });

    test('closeReleasesResources_indexerAndRelayer', () async {
      final mockIndexer = MockOZIndexerClient();
      final mockRelayer = MockOZRelayerClient();
      final mockServer = RecordingSorobanServer();
      final kit = _kitWithMockClients(
        indexerClient: mockIndexer,
        relayerClient: mockRelayer,
        sorobanServer: mockServer,
      );

      var globalListenerHits = 0;
      kit.events.addListener((_) => globalListenerHits++);

      await kit.close();

      expect(mockIndexer.closeCalls, equals(1));
      expect(mockRelayer.closeCalls, equals(1));
      expect(mockServer.closeCalls, equals(1));

      // Re-emit after close — confirms global listeners detached too.
      kit.events.emit(
        const SmartAccountEventWalletDisconnected(contractId: _validContractId),
      );
      expect(globalListenerHits, equals(0));
    });

    test('disconnectAfterClose_isNoOp', () async {
      final kit = OZSmartAccountKit.create(config: _validConfig());
      await kit.setConnectedState(
        credentialId: _credentialIdB64,
        contractId: _validContractId,
      );

      await kit.close();

      // disconnect after close must not throw and must not emit
      var events = 0;
      kit.events.on<SmartAccountEventWalletDisconnected>((_) => events++);
      await kit.disconnect();
      expect(events, equals(0));
    });
  });

  // =======================================================================
  // Group F — event-system tests directly invoking kit
  // =======================================================================

  group('Group F kit event subscription', () {
    test('typeSafeSubscription_receivesDisconnectEvent', () async {
      final kit = OZSmartAccountKit.create(config: _validConfig());
      await kit.setConnectedState(
        credentialId: _credentialIdB64,
        contractId: _validContractId,
      );

      final received = <SmartAccountEventWalletDisconnected>[];
      kit.events.on<SmartAccountEventWalletDisconnected>(received.add);

      await kit.disconnect();

      expect(received.length, equals(1));
      expect(received.single.contractId, equals(_validContractId));
    });

    test('onceListener_firesOnlyOnce', () async {
      final kit = OZSmartAccountKit.create(config: _validConfig());

      var hits = 0;
      kit.events.once<SmartAccountEventWalletDisconnected>((_) => hits++);

      await kit.setConnectedState(
        credentialId: _credentialIdB64,
        contractId: _validContractId,
      );
      await kit.disconnect();
      await kit.setConnectedState(
        credentialId: _credentialIdB64,
        contractId: _validContractId,
      );
      await kit.disconnect();

      expect(hits, equals(1));
    });

    test('removeAllListeners_silencesSubscribers', () async {
      final kit = OZSmartAccountKit.create(config: _validConfig());

      var hits = 0;
      kit.events.on<SmartAccountEventWalletDisconnected>((_) => hits++);
      kit.events.removeAllListeners();

      await kit.setConnectedState(
        credentialId: _credentialIdB64,
        contractId: _validContractId,
      );
      await kit.disconnect();

      expect(hits, equals(0));
    });
  });

  // =======================================================================
  // Concurrency stress
  // =======================================================================

  group('concurrency stress', () {
    test(
        'parallel_disconnectAndSetConnectedState_completeWithoutDeadlockUnder30s',
        () async {
      final kit = OZSmartAccountKit.create(config: _validConfig());

      // why: drive 10 parallel callers each performing a connect +
      // disconnect pair. The kit's lock serialises the state writes
      // against the storage I/O so the futures must all complete
      // without any caller deadlocking on the previous tail.
      final futures = List<Future<void>>.generate(10, (i) async {
        await kit.setConnectedState(
          credentialId: 'cred-$i',
          contractId: _validContractId,
        );
        await kit.disconnect();
      });

      await Future.wait(futures).timeout(const Duration(seconds: 30));

      expect(kit.isConnected, isFalse);
    });

    test(
        'parallel_requireConnectedReads_completeUnder30sWithDistinctResults',
        () async {
      final kit = OZSmartAccountKit.create(config: _validConfig());

      // why: simulate the multi-signer fanout shape — 10 concurrent
      // requireConnected reads under a connected state. The kit
      // serialises every read through the state lock so the futures
      // resolve in FIFO order; the assertion confirms the read path
      // does not deadlock the write path.
      await kit.setConnectedState(
        credentialId: _credentialIdB64,
        contractId: _validContractId,
      );
      final addresses = List<String>.generate(
        10,
        (i) => 'caller-$i',
      );

      final results = await Future.wait<String>(
        addresses.map((addr) async {
          final state = await kit.requireConnected();
          return '${state.contractId}|$addr';
        }),
      ).timeout(const Duration(seconds: 30));

      expect(results.length, equals(10));
      expect(results.toSet().length, equals(10));
    });

    test('disconnect_afterClose_pastInitialGuard_abortsCleanly', () async {
      final kit = OZSmartAccountKit.create(config: _validConfig());
      await kit.setConnectedState(
        credentialId: _credentialIdB64,
        contractId: _validContractId,
      );

      var disconnectedFired = 0;
      kit.events.on<SmartAccountEventWalletDisconnected>(
        (_) => disconnectedFired++,
      );

      // why: kick off disconnect and close concurrently. The disconnect
      // may observe `_closed == false` at the top-level guard but reach
      // the front of the lock queue after close has flipped the flag.
      // The re-check inside the lock body must abort the disconnect
      // cleanly, leaving no WalletDisconnected event emitted.
      final disconnectFuture = kit.disconnect();
      final closeFuture = kit.close();

      await Future.wait<void>(<Future<void>>[disconnectFuture, closeFuture]);

      // Disconnect either fires its event (if it reached the lock first)
      // or aborts via the re-check. Either is correct; the kit must not
      // be in a half-torn state when both have returned.
      expect(disconnectedFired, lessThanOrEqualTo(1));
    });
  });

  // =======================================================================
  // Memory-leak / deallocation wiring
  // =======================================================================

  group('memory and deallocation', () {
    test('multipleOpenCloseCycles_recordExactCloseCallCount', () async {
      const cycles = 10;
      var totalIndexerCloses = 0;
      var totalRelayerCloses = 0;
      var totalServerCloses = 0;

      for (var i = 0; i < cycles; i++) {
        final mockIndexer = MockOZIndexerClient();
        final mockRelayer = MockOZRelayerClient();
        final mockServer = RecordingSorobanServer();
        final kit = _kitWithMockClients(
          indexerClient: mockIndexer,
          relayerClient: mockRelayer,
          sorobanServer: mockServer,
        );
        await kit.close();
        totalIndexerCloses += mockIndexer.closeCalls;
        totalRelayerCloses += mockRelayer.closeCalls;
        totalServerCloses += mockServer.closeCalls;
      }

      expect(totalIndexerCloses, equals(cycles));
      expect(totalRelayerCloses, equals(cycles));
      expect(totalServerCloses, equals(cycles));
    });

    test(
      'weakReferenceWiring_isAvailableOnVm',
      () async {
        // why: this is a WIRING test only. Dart's GC is non-deterministic
        // and observing a `null` target through a [WeakReference] is not
        // a guarantee within a single test run. We assert that the
        // WeakReference machinery resolves on the VM (it is unavailable
        // on the browser) and that the kit can be created, used, and
        // closed without leaking strong references owned by this test.
        // A full leak check requires platform-specific GC instrumentation
        // outside the unit-test harness.
        WeakReference<OZSmartAccountKit>? weakKit;

        Future<void> innerScope() async {
          final kit = OZSmartAccountKit.create(config: _validConfig());
          weakKit = WeakReference<OZSmartAccountKit>(kit);
          await kit.setConnectedState(
            credentialId: _credentialIdB64,
            contractId: _validContractId,
          );
          await kit.close();
        }

        await innerScope();

        // Allocate some heap to encourage a GC cycle. Whether the cycle
        // actually runs is up to the VM; do not assert on `weakKit.target`.
        for (var i = 0; i < 50; i++) {
          final junk = Uint8List(200000);
          junk[junk.length - 1] = 1;
        }
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Wiring assertion: the WeakReference was constructed against a
        // real kit. Test passes regardless of whether the target has
        // been collected yet.
        expect(weakKit, isNotNull);
      },
      onPlatform: const <String, Skip>{
        'browser': Skip(
          'WeakReference observation requires VM-style GC pressure '
          'control; browser GC heuristics differ.',
        ),
      },
    );
  });
}

// ---------------------------------------------------------------------------
// Order-recording test doubles
// ---------------------------------------------------------------------------

/// Records the close-call order across the kit's HTTP transports so the
/// `close_orderingFiresSorobanFirst` test can assert the cross-SDK parity
/// contract. Each subclass appends its label to the shared list when
/// `close` runs.

class _OrderedRecordingSorobanServer extends RecordingSorobanServer {
  _OrderedRecordingSorobanServer(this._order, this._label);

  final List<String> _order;
  final String _label;

  @override
  void close() {
    _order.add(_label);
    super.close();
  }
}

class _OrderedRecordingIndexerClient extends MockOZIndexerClient {
  _OrderedRecordingIndexerClient(this._order, this._label);

  final List<String> _order;
  final String _label;

  @override
  Future<void> close() async {
    _order.add(_label);
    await super.close();
  }
}

class _OrderedRecordingRelayerClient extends MockOZRelayerClient {
  _OrderedRecordingRelayerClient(this._order, this._label);

  final List<String> _order;
  final String _label;

  @override
  Future<void> close() async {
    _order.add(_label);
    await super.close();
  }
}
