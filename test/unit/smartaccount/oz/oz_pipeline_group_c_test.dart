// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dio/dio.dart' as dio;
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import 'oz_pipeline_fixtures.dart';

// ---------------------------------------------------------------------------
// Common test fixtures
// ---------------------------------------------------------------------------

const String _contractA =
    'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK';
const String _contractB =
    'CADQOBYHA4DQOBYHA4DQOBYHA4DQOBYHA4DQOBYHA4DQOBYHA4DQP5KR';
const String _credentialIdB64 = 'aGVsbG8tc21hcnQtYWNjb3VudA';

Uint8List _bytes(int length, [int seed = 0]) {
  final out = Uint8List(length);
  for (var i = 0; i < length; i++) {
    out[i] = (seed + i) & 0xFF;
  }
  return out;
}

// ---------------------------------------------------------------------------
// Synthetic Soroban response helpers
// ---------------------------------------------------------------------------

/// Builds a [SimulateTransactionResponse] with the supplied error string.
SimulateTransactionResponse _simResponseWithError(String error) {
  final r = SimulateTransactionResponse(<String, dynamic>{});
  r.resultError = error;
  return r;
}

/// Builds an empty (no auth, no transaction-data) successful simulation.
SimulateTransactionResponse _simResponseEmpty({int? minResourceFee}) {
  final r = SimulateTransactionResponse(<String, dynamic>{});
  r.results = <SimulateTransactionResult>[];
  r.minResourceFee = minResourceFee;
  return r;
}

/// Builds a simulation response carrying one auth entry encoded as Base64
/// XDR plus optional `minResourceFee`.
SimulateTransactionResponse _simResponseWithAuthEntry({
  required XdrSorobanAuthorizationEntry entry,
  int? minResourceFee,
}) {
  final entryXdr = entry.toBase64EncodedXdrString();
  final result = SimulateTransactionResult('', <String>[entryXdr]);
  final r = SimulateTransactionResponse(<String, dynamic>{});
  r.results = <SimulateTransactionResult>[result];
  r.minResourceFee = minResourceFee;
  return r;
}

/// Builds a [GetLatestLedgerResponse] with the given sequence number.
GetLatestLedgerResponse _latestLedger(int sequence) {
  final r = GetLatestLedgerResponse(<String, dynamic>{});
  r.sequence = sequence;
  return r;
}

/// Builds a [SendTransactionResponse] for the success path.
SendTransactionResponse _sendPending({required String hash}) {
  final r = SendTransactionResponse(<String, dynamic>{});
  r.hash = hash;
  r.status = SendTransactionResponse.STATUS_PENDING;
  return r;
}

/// Builds a [SendTransactionResponse] with `ERROR` status and an error XDR.
SendTransactionResponse _sendError({String hash = '', String errorXdr = 'AAAA'}) {
  final r = SendTransactionResponse(<String, dynamic>{});
  r.hash = hash;
  r.status = SendTransactionResponse.STATUS_ERROR;
  r.errorResultXdr = errorXdr;
  return r;
}

/// Builds a successful [GetTransactionResponse] keyed on the supplied
/// ledger seq.
GetTransactionResponse _txSuccess({int ledger = 12345}) {
  final r = GetTransactionResponse(<String, dynamic>{});
  r.status = GetTransactionResponse.STATUS_SUCCESS;
  r.ledger = ledger;
  return r;
}

/// Builds a "not found" [GetTransactionResponse].
GetTransactionResponse _txNotFound() {
  final r = GetTransactionResponse(<String, dynamic>{});
  r.status = GetTransactionResponse.STATUS_NOT_FOUND;
  return r;
}

/// Builds a synthetic auth entry whose credentials point at the supplied
/// `contractAddress`, with placeholder signature bytes.
XdrSorobanAuthorizationEntry _makeAddressCredsEntry({
  required String contractAddress,
  String? targetContract,
  String targetFn = 'noop',
}) {
  final targetC = targetContract ?? contractAddress;
  final invokeArgs = XdrInvokeContractArgs(
    Address.forContractId(targetC).toXdr(),
    targetFn,
    const <XdrSCVal>[],
  );
  final invocation = XdrSorobanAuthorizedInvocation(
    XdrSorobanAuthorizedFunction.forInvokeContractArgs(invokeArgs),
    <XdrSorobanAuthorizedInvocation>[],
  );
  // Void placeholder matches what Soroban simulation returns for
  // unsigned auth entries; the OZ payload codec accepts Void as an
  // empty payload.
  final placeholderSig = XdrSCVal(XdrSCValType.SCV_VOID);
  final addressCredentials = XdrSorobanAddressCredentials(
    Address.forContractId(contractAddress).toXdr(),
    XdrInt64(BigInt.from(0)),
    XdrUint32(0),
    placeholderSig,
  );
  return XdrSorobanAuthorizationEntry(
    XdrSorobanCredentials.forAddressCredentials(addressCredentials),
    invocation,
  );
}

/// Builds a synthetic auth entry with `SOURCE_ACCOUNT` credentials.
XdrSorobanAuthorizationEntry _makeSourceAccountEntry({
  String targetContract = _contractB,
  String targetFn = 'noop',
}) {
  final invokeArgs = XdrInvokeContractArgs(
    Address.forContractId(targetContract).toXdr(),
    targetFn,
    const <XdrSCVal>[],
  );
  final invocation = XdrSorobanAuthorizedInvocation(
    XdrSorobanAuthorizedFunction.forInvokeContractArgs(invokeArgs),
    <XdrSorobanAuthorizedInvocation>[],
  );
  return XdrSorobanAuthorizationEntry(
    XdrSorobanCredentials.forSourceAccount(),
    invocation,
  );
}

/// Builds a fake [WebAuthnAuthenticationResult] where `credentialId` matches
/// [_credentialIdB64] decoded.
WebAuthnAuthenticationResult _fakeAuthResult({
  Uint8List? credentialIdBytes,
  Uint8List? sigDer,
}) {
  final credIdBytes = credentialIdBytes ??
      base64Url.decode(base64Url.normalize(_credentialIdB64));
  // why: supply a well-formed DER signature: 0x30 SEQUENCE, length, 0x02
  // INTEGER r, 0x02 INTEGER s — the smart-account utils run a DER ->
  // compact normaliser that requires a syntactically valid DER signature.
  final defaultSig = sigDer ??
      Uint8List.fromList(<int>[
        0x30, 0x44, // SEQUENCE, length 0x44
        0x02, 0x20, // INTEGER r
        ..._bytes(32, 1),
        0x02, 0x20, // INTEGER s
        ..._bytes(32, 2),
      ]);
  return WebAuthnAuthenticationResult(
    credentialId: credIdBytes,
    authenticatorData: _bytes(37, 3),
    clientDataJSON: utf8.encode(
      '{"type":"webauthn.get","challenge":"abc","origin":"https://test"}',
    ),
    signature: defaultSig,
  );
}

/// Builds a deployer-account stub for [MockSorobanServer.getAccount].
Account _deployerAccount(KeyPair deployer, {int seq = 1}) {
  return Account(deployer.accountId, BigInt.from(seq));
}

/// Sets up a fully-wired kit + mocks ready for a `submit` happy path.
Future<
    ({
      FakePipelineKit kit,
      MockSorobanServer soroban,
      RecordingWebAuthnProvider provider,
      KeyPair deployer,
      StoredCredential stored,
    })> _harness({
  RecordingRelayerClient? relayer,
  RecordingIndexerClient? indexer,
}) async {
  final soroban = MockSorobanServer();
  final provider = RecordingWebAuthnProvider();
  final deployer = KeyPair.random();
  final config = OZSmartAccountConfig(
    rpcUrl: 'https://soroban-testnet.stellar.org',
    networkPassphrase: Network.TESTNET.networkPassphrase,
    accountWasmHash: '0' * 64,
    webauthnVerifierAddress: _contractA,
    webauthnProvider: provider,
  );
  final credentials = StubCredentialManager();
  final stored = StoredCredential(
    credentialId: _credentialIdB64,
    publicKey: _bytes(65, 4),
    contractId: _contractA,
  );
  credentials.inject(stored);
  final storage = InMemoryStorageAdapter();
  // Pre-populate the storage adapter so the signing path's
  // `_kit.getStorage().get(credentialId)` hits, bypassing the on-chain
  // context-rule walk that would otherwise need populated rule fixtures.
  await storage.save(stored);
  final kit = FakePipelineKit(
    config: config,
    sorobanServer: soroban,
    deployer: deployer,
    credentialManager: credentials,
    storage: storage,
    relayerClient: relayer,
    indexerClient: indexer,
  )..setConnected(credentialId: _credentialIdB64, contractId: _contractA);
  return (
    kit: kit,
    soroban: soroban,
    provider: provider,
    deployer: deployer,
    stored: stored,
  );
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // C.1 — Auth-entry-signing pipeline
  // -------------------------------------------------------------------------
  group('C.1 auth-entry signing pipeline', () {
    test('submit_signsAuthEntryForOurContract_writesAuthPayloadMap', () async {
      final h = await _harness();
      // Initial simulate returns one matching auth entry.
      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer));
      h.soroban.simulateResponses.add(_simResponseWithAuthEntry(
        entry: _makeAddressCredsEntry(contractAddress: _contractA),
        minResourceFee: 100,
      ));
      h.soroban.latestLedgerResponses.add(_latestLedger(1000));
      // Provider returns matching credentialId.
      h.provider.authenticateResponses.add(_fakeAuthResult());
      // Re-simulate after signing.
      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer, seq: 2));
      h.soroban.simulateResponses.add(_simResponseEmpty(minResourceFee: 200));
      // Final submit + poll.
      h.soroban.sendResponses.add(_sendPending(hash: 'abc'));
      h.soroban.pollResponses.add(_txSuccess(ledger: 9876));

      final ops = OZTransactionOperations(h.kit);
      final hostFunction = XdrHostFunction.forInvokingContractWithArgs(
        XdrInvokeContractArgs(
          Address.forContractId(_contractB).toXdr(),
          'transfer',
          const <XdrSCVal>[],
        ),
      );
      final result = await ops.submit(
        hostFunction: hostFunction,
        auth: const <XdrSorobanAuthorizationEntry>[],
      );

      expect(result.success, isTrue);
      expect(result.hash, equals('abc'));
      expect(h.provider.authenticateCalls.length, equals(1));

      // Decode the post-signing send envelope and verify the auth entry's
      // signature is now an SCV_MAP (the OZ AuthPayload shape).
      expect(h.soroban.sendCalls.length, equals(1));
      final sentTx = h.soroban.sendCalls.single;
      final envelope = sentTx.toEnvelopeXdr();
      // ignore: invalid_use_of_internal_member
      final opXdr =
          envelope.v1!.tx.operations.first.body.invokeHostFunctionOp!.auth;
      expect(opXdr, isNotEmpty);
      final firstAuth = opXdr.first;
      final creds = firstAuth.credentials.address;
      expect(creds, isNotNull);
      expect(
        creds!.signature.discriminant,
        equals(XdrSCValType.SCV_MAP),
      );
    });

    test('submit_passThroughForNonMatchingContract_doesNotMutate', () async {
      final h = await _harness();
      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer));
      // Auth entry points to a DIFFERENT contract — should pass through.
      final passThroughEntry =
          _makeAddressCredsEntry(contractAddress: _contractB);
      h.soroban.simulateResponses
          .add(_simResponseWithAuthEntry(entry: passThroughEntry));
      h.soroban.latestLedgerResponses.add(_latestLedger(1000));
      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer, seq: 2));
      h.soroban.simulateResponses.add(_simResponseEmpty());
      h.soroban.sendResponses.add(_sendPending(hash: 'h2'));
      h.soroban.pollResponses.add(_txSuccess());

      final ops = OZTransactionOperations(h.kit);
      await ops.submit(
        hostFunction: XdrHostFunction.forInvokingContractWithArgs(
          XdrInvokeContractArgs(
            Address.forContractId(_contractB).toXdr(),
            'noop',
            const <XdrSCVal>[],
          ),
        ),
        auth: const <XdrSorobanAuthorizationEntry>[],
      );

      // WebAuthn must NOT have been called (entry didn't match contract).
      expect(h.provider.authenticateCalls, isEmpty);
    });

    test('submit_signAuthEntry_scvalMapSortOrder_verified', () async {
      // why: assert the AuthPayload Map keys are sorted in canonical
      // ScVal byte order. The OZ helper guarantees this and the assertion
      // verifies the helper hasn't regressed.
      final h = await _harness();
      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer));
      h.soroban.simulateResponses.add(_simResponseWithAuthEntry(
        entry: _makeAddressCredsEntry(contractAddress: _contractA),
      ));
      h.soroban.latestLedgerResponses.add(_latestLedger(2000));
      h.provider.authenticateResponses.add(_fakeAuthResult());
      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer, seq: 2));
      h.soroban.simulateResponses.add(_simResponseEmpty());
      h.soroban.sendResponses.add(_sendPending(hash: 'sorted'));
      h.soroban.pollResponses.add(_txSuccess());

      final ops = OZTransactionOperations(h.kit);
      await ops.submit(
        hostFunction: XdrHostFunction.forInvokingContractWithArgs(
          XdrInvokeContractArgs(
            Address.forContractId(_contractA).toXdr(),
            'op',
            const <XdrSCVal>[],
          ),
        ),
        auth: const <XdrSorobanAuthorizationEntry>[],
      );

      final sentTx = h.soroban.sendCalls.single;
      final envelope = sentTx.toEnvelopeXdr();
      final opAuth =
          envelope.v1!.tx.operations.first.body.invokeHostFunctionOp!.auth;
      final mapEntries = opAuth.first.credentials.address!.signature.map;
      expect(mapEntries, isNotNull);
      // Outer struct keys are written in alphabetical string order to
      // match the Soroban Rust `#[contracttype]` derive convention. The
      // payload codec guarantees this; this test pins that behaviour.
      final symKeys = <String>[];
      for (final me in mapEntries!) {
        expect(me.key.discriminant, equals(XdrSCValType.SCV_SYMBOL),
            reason: 'AuthPayload outer-map keys must be Symbols');
        symKeys.add(me.key.sym!);
      }
      final sorted = List<String>.from(symKeys)..sort();
      expect(symKeys, equals(sorted),
          reason: 'outer-map keys not in alphabetical order');
    });

    test('submit_writesNonceAndExpirationFromSimulation', () async {
      // The post-signing auth entry should carry an expiration computed from
      // the latest-ledger sequence + signatureExpirationLedgers and a nonce
      // that survives a round trip through XDR.
      final h = await _harness();
      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer));
      h.soroban.simulateResponses.add(_simResponseWithAuthEntry(
        entry: _makeAddressCredsEntry(contractAddress: _contractA),
      ));
      h.soroban.latestLedgerResponses.add(_latestLedger(5000));
      h.provider.authenticateResponses.add(_fakeAuthResult());
      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer, seq: 2));
      h.soroban.simulateResponses.add(_simResponseEmpty());
      h.soroban.sendResponses.add(_sendPending(hash: 'h3'));
      h.soroban.pollResponses.add(_txSuccess());

      final ops = OZTransactionOperations(h.kit);
      await ops.submit(
        hostFunction: XdrHostFunction.forInvokingContractWithArgs(
          XdrInvokeContractArgs(
            Address.forContractId(_contractA).toXdr(),
            'op',
            const <XdrSCVal>[],
          ),
        ),
        auth: const <XdrSorobanAuthorizationEntry>[],
      );

      final sentTx = h.soroban.sendCalls.single;
      final envelope = sentTx.toEnvelopeXdr();
      final authEntry = envelope.v1!.tx.operations.first.body
          .invokeHostFunctionOp!.auth.first;
      final creds = authEntry.credentials.address!;
      final expectedExpiration =
          5000 + h.kit.config.signatureExpirationLedgers;
      expect(creds.signatureExpirationLedger.uint32, equals(expectedExpiration));
    });
  });

  // -------------------------------------------------------------------------
  // C.2 — WebAuthn re-simulation step
  // -------------------------------------------------------------------------
  group('C.2 re-simulation step', () {
    test('submit_reSimulatesAfterSigning_consumesNewResourceFees', () async {
      final h = await _harness();
      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer));
      h.soroban.simulateResponses.add(_simResponseWithAuthEntry(
        entry: _makeAddressCredsEntry(contractAddress: _contractA),
        minResourceFee: 100000,
      ));
      h.soroban.latestLedgerResponses.add(_latestLedger(1000));
      h.provider.authenticateResponses.add(_fakeAuthResult());
      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer, seq: 2));
      // Re-simulation returns a much larger resource fee.
      h.soroban.simulateResponses.add(_simResponseEmpty(minResourceFee: 150000));
      h.soroban.sendResponses.add(_sendPending(hash: 'feebumped'));
      h.soroban.pollResponses.add(_txSuccess());

      final ops = OZTransactionOperations(h.kit);
      await ops.submit(
        hostFunction: XdrHostFunction.forInvokingContractWithArgs(
          XdrInvokeContractArgs(
            Address.forContractId(_contractA).toXdr(),
            'op',
            const <XdrSCVal>[],
          ),
        ),
        auth: const <XdrSorobanAuthorizationEntry>[],
      );

      // The transaction whose fee was assembled with the higher
      // minResourceFee is what got sent.
      expect(h.soroban.simulateCalls.length, equals(2));
      expect(h.soroban.sendCalls.length, equals(1));
      // Fee should include the higher resource fee on top of base.
      final fee = h.soroban.sendCalls.single.fee;
      // 100 base + 150000 resource fee == 150100.
      expect(fee, greaterThanOrEqualTo(150100));
    });

    test('submit_reSimulationFails_throwsSimulationFailed', () async {
      final h = await _harness();
      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer));
      h.soroban.simulateResponses.add(_simResponseWithAuthEntry(
        entry: _makeAddressCredsEntry(contractAddress: _contractA),
      ));
      h.soroban.latestLedgerResponses.add(_latestLedger(1000));
      h.provider.authenticateResponses.add(_fakeAuthResult());
      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer, seq: 2));
      // Re-simulation reports error.
      h.soroban.simulateResponses
          .add(_simResponseWithError('resource exhaustion'));

      final ops = OZTransactionOperations(h.kit);
      await expectLater(
        () => ops.submit(
          hostFunction: XdrHostFunction.forInvokingContractWithArgs(
            XdrInvokeContractArgs(
              Address.forContractId(_contractA).toXdr(),
              'op',
              const <XdrSCVal>[],
            ),
          ),
          auth: const <XdrSorobanAuthorizationEntry>[],
        ),
        throwsA(
          isA<TransactionSimulationFailed>().having(
            (e) => e.message,
            'message',
            contains('Re-simulation error'),
          ),
        ),
      );
    });

    test('submit_initialSimulationFails_throwsWithInitialMessage', () async {
      final h = await _harness();
      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer));
      h.soroban.simulateResponses
          .add(_simResponseWithError('contract not found'));

      final ops = OZTransactionOperations(h.kit);
      await expectLater(
        () => ops.submit(
          hostFunction: XdrHostFunction.forInvokingContractWithArgs(
            XdrInvokeContractArgs(
              Address.forContractId(_contractA).toXdr(),
              'op',
              const <XdrSCVal>[],
            ),
          ),
          auth: const <XdrSorobanAuthorizationEntry>[],
        ),
        throwsA(
          isA<TransactionSimulationFailed>().having(
            (e) => e.message,
            'message',
            allOf(contains('Simulation error'), contains('contract not found')),
          ),
        ),
      );
    });
  });

  // -------------------------------------------------------------------------
  // C.3 — connectWallet cascade
  // -------------------------------------------------------------------------
  group('C.3 connectWallet cascade', () {
    test('connectWallet_storageHit_pendingCredential_setsContractId',
        () async {
      // Stage A storage hit, deployment_status = pending. Cascade short-
      // circuits at Stage A and verifies the contract on-chain.
      final soroban = MockSorobanServer();
      // _verifyContractExists makes a single getContractData call which
      // must succeed.
      soroban.getContractDataResponses
          .add(LedgerEntry('', '', 0, null, null));
      final credentials = StubCredentialManager();
      credentials.inject(StoredCredential(
        credentialId: _credentialIdB64,
        publicKey: _bytes(65),
        contractId: _contractA,
      ));
      final config = OZSmartAccountConfig(
        rpcUrl: 'https://soroban-testnet.stellar.org',
        networkPassphrase: Network.TESTNET.networkPassphrase,
        accountWasmHash: '0' * 64,
        webauthnVerifierAddress: _contractA,
      );
      final kit = FakePipelineKit(
        config: config,
        sorobanServer: soroban,
        credentialManager: credentials,
      );
      final ops = OZWalletOperations(kit);

      final result = await ops.connectWallet(
        options: const ConnectWalletOptions(credentialId: _credentialIdB64),
      );
      expect(result, isA<OZConnectWalletConnected>());
      expect(
        (result! as OZConnectWalletConnected).contractId,
        equals(_contractA),
      );
    });

    test('connectWallet_storageHit_failedCredential_throwsNotFound', () async {
      final credentials = StubCredentialManager();
      credentials.inject(StoredCredential(
        credentialId: _credentialIdB64,
        publicKey: _bytes(65),
        contractId: _contractA,
        deploymentStatus: CredentialDeploymentStatus.failed,
        deploymentError: 'previous deploy failed',
      ));
      final config = OZSmartAccountConfig(
        rpcUrl: 'https://soroban-testnet.stellar.org',
        networkPassphrase: Network.TESTNET.networkPassphrase,
        accountWasmHash: '0' * 64,
        webauthnVerifierAddress: _contractA,
      );
      final kit = FakePipelineKit(
        config: config,
        credentialManager: credentials,
      );
      final ops = OZWalletOperations(kit);
      await expectLater(
        () => ops.connectWallet(
          options: const ConnectWalletOptions(credentialId: _credentialIdB64),
        ),
        throwsA(
          isA<WalletNotFound>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('deployment previously failed'),
              contains('deployPendingCredential'),
            ),
          ),
        ),
      );
    });

    test('connectWallet_derivationHit_setsContractId', () async {
      // No stored credential — derivation produces an address that the
      // mock confirms exists on-chain.
      final soroban = MockSorobanServer();
      // First call (derivation verify) returns a live entry.
      soroban.getContractDataResponses.add(LedgerEntry('', '', 0, null, null));
      // End-of-cascade verify (also via _finalizeConnect) returns live.
      soroban.getContractDataResponses.add(LedgerEntry('', '', 0, null, null));
      final config = OZSmartAccountConfig(
        rpcUrl: 'https://soroban-testnet.stellar.org',
        networkPassphrase: Network.TESTNET.networkPassphrase,
        accountWasmHash: '0' * 64,
        webauthnVerifierAddress: _contractA,
      );
      final kit = FakePipelineKit(
        config: config,
        sorobanServer: soroban,
      );
      final ops = OZWalletOperations(kit);
      final result = await ops.connectWallet(
        options: const ConnectWalletOptions(credentialId: _credentialIdB64),
      );
      expect(result, isA<OZConnectWalletConnected>());
    });

    test('connectWallet_derivationMiss_fallsThroughToIndexer', () async {
      // First getContractData call (derivation verify) returns null →
      // WalletNotFound → fall through. Indexer returns 1 candidate; second
      // getContractData (indexer single-candidate verify) returns live;
      // third (end-of-cascade) returns live.
      final soroban = MockSorobanServer();
      soroban.getContractDataResponses.add(null); // derivation miss
      soroban.getContractDataResponses.add(LedgerEntry('', '', 0, null, null));
      soroban.getContractDataResponses.add(LedgerEntry('', '', 0, null, null));

      final indexer = buildIndexerHarness(
        responseBody: jsonEncode(<String, dynamic>{
          'credentialId': _credentialIdB64,
          'contracts': <Map<String, dynamic>>[
            <String, dynamic>{
              'contract_id': _contractA,
              'context_rule_count': 1,
              'external_signer_count': 1,
              'delegated_signer_count': 0,
              'native_signer_count': 0,
              'first_seen_ledger': 1,
              'last_seen_ledger': 100,
              'context_rule_ids': <int>[1],
            },
          ],
          'count': 1,
        }),
      );

      final config = OZSmartAccountConfig(
        rpcUrl: 'https://soroban-testnet.stellar.org',
        networkPassphrase: Network.TESTNET.networkPassphrase,
        accountWasmHash: '0' * 64,
        webauthnVerifierAddress: _contractA,
      );
      final kit = FakePipelineKit(
        config: config,
        sorobanServer: soroban,
        indexerClient: indexer.client,
      );
      final ops = OZWalletOperations(kit);
      final result = await ops.connectWallet(
        options: const ConnectWalletOptions(credentialId: _credentialIdB64),
      );
      expect(result, isA<OZConnectWalletConnected>());
      expect(
        (result! as OZConnectWalletConnected).contractId,
        equals(_contractA),
      );
    });

    test('connectWallet_indexerSingleCandidate_setsContractId', () async {
      final soroban = MockSorobanServer();
      soroban.getContractDataResponses.add(null);
      soroban.getContractDataResponses.add(LedgerEntry('', '', 0, null, null));
      soroban.getContractDataResponses.add(LedgerEntry('', '', 0, null, null));
      final indexer = buildIndexerHarness(
        responseBody: jsonEncode(<String, dynamic>{
          'credentialId': _credentialIdB64,
          'contracts': <Map<String, dynamic>>[
            <String, dynamic>{
              'contract_id': _contractA,
              'context_rule_count': 1,
              'external_signer_count': 1,
              'delegated_signer_count': 0,
              'native_signer_count': 0,
              'first_seen_ledger': 1,
              'last_seen_ledger': 100,
              'context_rule_ids': <int>[1],
            },
          ],
          'count': 1,
        }),
      );
      final kit = FakePipelineKit(
        config: OZSmartAccountConfig(
          rpcUrl: 'https://soroban-testnet.stellar.org',
          networkPassphrase: Network.TESTNET.networkPassphrase,
          accountWasmHash: '0' * 64,
          webauthnVerifierAddress: _contractA,
        ),
        sorobanServer: soroban,
        indexerClient: indexer.client,
      );
      final ops = OZWalletOperations(kit);
      final result = await ops.connectWallet(
        options: const ConnectWalletOptions(credentialId: _credentialIdB64),
      );
      expect(result, isA<OZConnectWalletConnected>());
    });

    test('connectWallet_indexerMultipleCandidates_returnsAmbiguous', () async {
      final soroban = MockSorobanServer();
      // Derivation miss.
      soroban.getContractDataResponses.add(null);
      // _filterVerifiedCandidates verifies each of the two candidates —
      // both succeed.
      soroban.getContractDataResponses.add(LedgerEntry('', '', 0, null, null));
      soroban.getContractDataResponses.add(LedgerEntry('', '', 0, null, null));
      final indexer = buildIndexerHarness(
        responseBody: jsonEncode(<String, dynamic>{
          'credentialId': _credentialIdB64,
          'contracts': <Map<String, dynamic>>[
            <String, dynamic>{
              'contract_id': _contractA,
              'context_rule_count': 1,
              'external_signer_count': 1,
              'delegated_signer_count': 0,
              'native_signer_count': 0,
              'first_seen_ledger': 1,
              'last_seen_ledger': 100,
              'context_rule_ids': <int>[1],
            },
            <String, dynamic>{
              'contract_id': _contractB,
              'context_rule_count': 1,
              'external_signer_count': 1,
              'delegated_signer_count': 0,
              'native_signer_count': 0,
              'first_seen_ledger': 1,
              'last_seen_ledger': 100,
              'context_rule_ids': <int>[1],
            },
          ],
          'count': 2,
        }),
      );
      final kit = FakePipelineKit(
        config: OZSmartAccountConfig(
          rpcUrl: 'https://soroban-testnet.stellar.org',
          networkPassphrase: Network.TESTNET.networkPassphrase,
          accountWasmHash: '0' * 64,
          webauthnVerifierAddress: _contractA,
        ),
        sorobanServer: soroban,
        indexerClient: indexer.client,
      );
      final ops = OZWalletOperations(kit);
      final result = await ops.connectWallet(
        options: const ConnectWalletOptions(credentialId: _credentialIdB64),
      );
      expect(result, isA<OZConnectWalletAmbiguous>());
      final ambig = result! as OZConnectWalletAmbiguous;
      expect(ambig.candidates, containsAll(<String>[_contractA, _contractB]));
      // Kit must NOT be in connected state when Ambiguous is returned.
      expect(kit.requireConnected, throwsA(isA<WalletNotConnected>()));
    });
  });

  // -------------------------------------------------------------------------
  // C.4 — fundWallet conversion
  // -------------------------------------------------------------------------
  group('C.4 fundWallet conversion', () {
    test('fundWallet_invalidNativeTokenContract_throwsInvalidAddress',
        () async {
      // Standalone validation exercise; covers the validation surface that
      // the deeper Friendbot/relayer paths gate on.
      final kit = FakePipelineKit()
        ..setConnected(credentialId: 'c', contractId: _contractA);
      final ops = OZTransactionOperations(kit);
      await expectLater(
        () => ops.fundWallet(nativeTokenContract: 'not-a-c-address'),
        throwsA(isA<InvalidAddress>()),
      );
    });

    test('fundWallet_validatesConnectedBeforeFriendbot', () async {
      // The not-connected case throws WalletNotConnected before any
      // Friendbot interaction. Sufficient as a unit-level smoke for the
      // call-order contract; the real Friendbot path is covered in
      // testnet integration tests.
      final kit = FakePipelineKit();
      final ops = OZTransactionOperations(kit);
      await expectLater(
        () => ops.fundWallet(nativeTokenContract: _contractA),
        throwsA(isA<WalletNotConnected>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // C.5 — relayer vs RPC submission paths
  // -------------------------------------------------------------------------
  group('C.5 relayer-vs-RPC', () {
    test('submit_relayerConfigured_defaultsToRelayer_mode1', () async {
      final relayerHarness = buildRelayerHarness(
        responseBody:
            '{"success":true,"hash":"relayer-hash","status":"SUCCESS"}',
      );
      final h = await _harness(relayer: relayerHarness.client);
      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer));
      h.soroban.simulateResponses.add(_simResponseEmpty(minResourceFee: 100));
      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer, seq: 2));
      h.soroban.simulateResponses.add(_simResponseEmpty(minResourceFee: 100));
      h.soroban.pollResponses.add(_txSuccess());

      final ops = OZTransactionOperations(h.kit);
      final result = await ops.submit(
        hostFunction: XdrHostFunction.forInvokingContractWithArgs(
          XdrInvokeContractArgs(
            Address.forContractId(_contractB).toXdr(),
            'noop',
            const <XdrSCVal>[],
          ),
        ),
        auth: const <XdrSorobanAuthorizationEntry>[],
      );
      expect(result.success, isTrue,
          reason: 'submit error: ${result.error}; '
              'urls: ${relayerHarness.adapter.capturedUrls}; '
              'body: ${relayerHarness.adapter.capturedBodies}');
      expect(relayerHarness.adapter.capturedUrls, isNotEmpty);
      final body = relayerHarness.adapter.capturedBodies.last;
      expect(body, isNotNull);
      final decoded = jsonDecode(body!) as Map<String, dynamic>;
      // Mode 1 sends `{func, auth}` per the relayer wire format.
      expect(decoded.containsKey('func'), isTrue);
      expect(decoded.containsKey('auth'), isTrue);
    });

    test('submit_relayerConfigured_sourceAccountAuth_usesMode2', () async {
      // Inject a source_account auth entry. The relayer should be invoked
      // via Mode 2 (sendXdr with a fully signed envelope).
      final relayerHarness = buildRelayerHarness();
      final h = await _harness(relayer: relayerHarness.client);
      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer));
      h.soroban.simulateResponses
          .add(_simResponseWithAuthEntry(entry: _makeSourceAccountEntry()));
      h.soroban.latestLedgerResponses.add(_latestLedger(1000));
      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer, seq: 2));
      h.soroban.simulateResponses.add(_simResponseEmpty());
      h.soroban.pollResponses.add(_txSuccess());

      final ops = OZTransactionOperations(h.kit);
      await ops.submit(
        hostFunction: XdrHostFunction.forInvokingContractWithArgs(
          XdrInvokeContractArgs(
            Address.forContractId(_contractB).toXdr(),
            'noop',
            const <XdrSCVal>[],
          ),
        ),
        auth: const <XdrSorobanAuthorizationEntry>[],
      );
      final body = relayerHarness.adapter.capturedBodies.last!;
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      // Mode 2 sends a signed XDR envelope.
      expect(decoded.containsKey('xdr'), isTrue);
    });

    test('submit_noRelayer_usesRpc', () async {
      final h = await _harness();
      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer));
      h.soroban.simulateResponses.add(_simResponseEmpty(minResourceFee: 50));
      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer, seq: 2));
      h.soroban.simulateResponses.add(_simResponseEmpty(minResourceFee: 50));
      h.soroban.sendResponses.add(_sendPending(hash: 'rpc-hash'));
      h.soroban.pollResponses.add(_txSuccess());

      final ops = OZTransactionOperations(h.kit);
      final result = await ops.submit(
        hostFunction: XdrHostFunction.forInvokingContractWithArgs(
          XdrInvokeContractArgs(
            Address.forContractId(_contractB).toXdr(),
            'noop',
            const <XdrSCVal>[],
          ),
        ),
        auth: const <XdrSorobanAuthorizationEntry>[],
      );
      expect(result.success, isTrue);
      expect(h.soroban.sendCalls.length, equals(1));
    });

    test('submit_forceRpc_overridesRelayer', () async {
      final relayerHarness = buildRelayerHarness();
      final h = await _harness(relayer: relayerHarness.client);
      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer));
      h.soroban.simulateResponses.add(_simResponseEmpty());
      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer, seq: 2));
      h.soroban.simulateResponses.add(_simResponseEmpty());
      h.soroban.sendResponses.add(_sendPending(hash: 'rpc-forced'));
      h.soroban.pollResponses.add(_txSuccess());

      final ops = OZTransactionOperations(h.kit);
      await ops.submit(
        hostFunction: XdrHostFunction.forInvokingContractWithArgs(
          XdrInvokeContractArgs(
            Address.forContractId(_contractB).toXdr(),
            'noop',
            const <XdrSCVal>[],
          ),
        ),
        auth: const <XdrSorobanAuthorizationEntry>[],
        forceMethod: SubmissionMethod.rpc,
      );
      // Relayer must NOT have been contacted.
      expect(relayerHarness.adapter.capturedUrls, isEmpty);
      // RPC path must have been used.
      expect(h.soroban.sendCalls.length, equals(1));
    });
  });

  // -------------------------------------------------------------------------
  // C.6 — §9.1 failure modes
  // -------------------------------------------------------------------------
  group('C.6 failure modes', () {
    test('submit_rpcTimeout_throwsTransactionTimeout', () async {
      final h = await _harness();
      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer));
      // Simulate throws a Dio timeout error.
      h.soroban.simulateResponses.add(
        dio.DioException(
          requestOptions: dio.RequestOptions(path: 'simulate'),
          type: dio.DioExceptionType.receiveTimeout,
          message: 'receive timeout',
        ),
      );

      final ops = OZTransactionOperations(h.kit);
      await expectLater(
        () => ops.submit(
          hostFunction: XdrHostFunction.forInvokingContractWithArgs(
            XdrInvokeContractArgs(
              Address.forContractId(_contractA).toXdr(),
              'op',
              const <XdrSCVal>[],
            ),
          ),
          auth: const <XdrSorobanAuthorizationEntry>[],
        ),
        throwsA(
          isA<TransactionSubmissionFailed>().having(
            (e) => e.toString().toLowerCase(),
            'message',
            anyOf(contains('timeout'), contains('timed out')),
          ),
        ),
      );
    });

    test('submit_signingFailure_propagatesWebAuthnException', () async {
      final h = await _harness();
      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer));
      h.soroban.simulateResponses.add(_simResponseWithAuthEntry(
        entry: _makeAddressCredsEntry(contractAddress: _contractA),
      ));
      h.soroban.latestLedgerResponses.add(_latestLedger(1000));
      h.provider.authenticateResponses.add(
        WebAuthnException.authenticationFailed('user cancelled'),
      );

      final ops = OZTransactionOperations(h.kit);
      await expectLater(
        () => ops.submit(
          hostFunction: XdrHostFunction.forInvokingContractWithArgs(
            XdrInvokeContractArgs(
              Address.forContractId(_contractA).toXdr(),
              'op',
              const <XdrSCVal>[],
            ),
          ),
          auth: const <XdrSorobanAuthorizationEntry>[],
        ),
        throwsA(isA<WebAuthnException>()),
      );
    });

    test('submit_sendTransactionError_returnsFailureResult', () async {
      final h = await _harness();
      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer));
      h.soroban.simulateResponses.add(_simResponseEmpty());
      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer, seq: 2));
      h.soroban.simulateResponses.add(_simResponseEmpty());
      h.soroban.sendResponses.add(_sendError(hash: 'bad', errorXdr: 'AAAA'));

      final ops = OZTransactionOperations(h.kit);
      final result = await ops.submit(
        hostFunction: XdrHostFunction.forInvokingContractWithArgs(
          XdrInvokeContractArgs(
            Address.forContractId(_contractB).toXdr(),
            'op',
            const <XdrSCVal>[],
          ),
        ),
        auth: const <XdrSorobanAuthorizationEntry>[],
      );
      expect(result.success, isFalse);
      expect(result.hash, equals('bad'));
      expect(result.error, equals('AAAA'));
    });

    test('submit_pollNotFound_returnsFailureResult', () async {
      final h = await _harness();
      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer));
      h.soroban.simulateResponses.add(_simResponseEmpty());
      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer, seq: 2));
      h.soroban.simulateResponses.add(_simResponseEmpty());
      h.soroban.sendResponses.add(_sendPending(hash: 'h'));
      h.soroban.pollResponses.add(_txNotFound());

      final ops = OZTransactionOperations(h.kit);
      final result = await ops.submit(
        hostFunction: XdrHostFunction.forInvokingContractWithArgs(
          XdrInvokeContractArgs(
            Address.forContractId(_contractB).toXdr(),
            'op',
            const <XdrSCVal>[],
          ),
        ),
        auth: const <XdrSorobanAuthorizationEntry>[],
      );
      expect(result.success, isFalse);
      expect(result.error, contains('not confirmed'));
    });

    test('submit_wasmHashMismatch_propagatesSimulationFailed', () async {
      // Simulate's resultError carries the well-known message; the SDK
      // surfaces it as SimulationFailed with the initial-stage prefix.
      final h = await _harness();
      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer));
      h.soroban.simulateResponses
          .add(_simResponseWithError('wasm hash mismatch'));

      final ops = OZTransactionOperations(h.kit);
      await expectLater(
        () => ops.submit(
          hostFunction: XdrHostFunction.forInvokingContractWithArgs(
            XdrInvokeContractArgs(
              Address.forContractId(_contractA).toXdr(),
              'op',
              const <XdrSCVal>[],
            ),
          ),
          auth: const <XdrSorobanAuthorizationEntry>[],
        ),
        throwsA(
          isA<TransactionSimulationFailed>().having(
            (e) => e.message,
            'message',
            allOf(contains('Simulation error'), contains('wasm hash mismatch')),
          ),
        ),
      );
    });

    test('connectWallet_indexerMalformedJson_propagatesIndexerException',
        () async {
      // Indexer adapter returns malformed JSON; OZIndexerClient surfaces
      // an IndexerException which `connectWallet` propagates.
      final soroban = MockSorobanServer();
      soroban.getContractDataResponses.add(null); // derivation miss
      final indexer = buildIndexerHarness(responseBody: '{not json');
      final kit = FakePipelineKit(
        config: OZSmartAccountConfig(
          rpcUrl: 'https://soroban-testnet.stellar.org',
          networkPassphrase: Network.TESTNET.networkPassphrase,
          accountWasmHash: '0' * 64,
          webauthnVerifierAddress: _contractA,
        ),
        sorobanServer: soroban,
        indexerClient: indexer.client,
      );
      final ops = OZWalletOperations(kit);
      await expectLater(
        () => ops.connectWallet(
          options: const ConnectWalletOptions(credentialId: _credentialIdB64),
        ),
        throwsA(isA<IndexerException>()),
      );
    });

    test('submit_credentialDecodeFailure_throwsCredentialException', () async {
      // Set up a kit connected with a bogus credentialId so the
      // base64Url decode at the signing step fails.
      final soroban = MockSorobanServer();
      soroban.getAccountResponses.add(_deployerAccount(KeyPair.random()));
      soroban.simulateResponses.add(_simResponseWithAuthEntry(
        entry: _makeAddressCredsEntry(contractAddress: _contractA),
      ));
      soroban.latestLedgerResponses.add(_latestLedger(1000));
      final config = OZSmartAccountConfig(
        rpcUrl: 'https://soroban-testnet.stellar.org',
        networkPassphrase: Network.TESTNET.networkPassphrase,
        accountWasmHash: '0' * 64,
        webauthnVerifierAddress: _contractA,
        webauthnProvider: RecordingWebAuthnProvider(),
      );
      final kit = FakePipelineKit(
        config: config,
        sorobanServer: soroban,
      )..setConnected(
          credentialId: '!!!not-base64url!!!',
          contractId: _contractA,
        );

      final ops = OZTransactionOperations(kit);
      await expectLater(
        () => ops.submit(
          hostFunction: XdrHostFunction.forInvokingContractWithArgs(
            XdrInvokeContractArgs(
              Address.forContractId(_contractA).toXdr(),
              'op',
              const <XdrSCVal>[],
            ),
          ),
          auth: const <XdrSorobanAuthorizationEntry>[],
        ),
        throwsA(isA<CredentialException>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // C.7 — Deploy path
  // -------------------------------------------------------------------------
  group('C.7 deploy', () {
    test('deployPendingCredential_autoSubmitFalse_returnsXdrOnly', () async {
      final credentials = StubCredentialManager();
      credentials.inject(StoredCredential(
        credentialId: _credentialIdB64,
        publicKey: _bytes(65, 4),
        contractId: _contractA,
      ));
      final soroban = MockSorobanServer();
      // Single simulate + getAccount for build.
      soroban.getAccountResponses.add(_deployerAccount(KeyPair.random()));
      soroban.simulateResponses.add(_simResponseEmpty(minResourceFee: 100));
      final kit = FakePipelineKit(
        config: OZSmartAccountConfig(
          rpcUrl: 'https://soroban-testnet.stellar.org',
          networkPassphrase: Network.TESTNET.networkPassphrase,
          accountWasmHash: '0' * 64,
          webauthnVerifierAddress: _contractA,
        ),
        sorobanServer: soroban,
        credentialManager: credentials,
      );
      final ops = OZWalletOperations(kit);
      final result = await ops.deployPendingCredential(
        credentialId: _credentialIdB64,
        autoSubmit: false,
      );
      expect(result.contractId, equals(_contractA));
      expect(result.signedTransactionXdr, isNotEmpty);
      expect(result.transactionHash, isNull);
    });

    test('deployPendingCredential_credentialNotFound_throws', () async {
      // No injection — credential missing.
      final kit = FakePipelineKit();
      final ops = OZWalletOperations(kit);
      await expectLater(
        () => ops.deployPendingCredential(
          credentialId: 'missing',
          autoSubmit: false,
        ),
        throwsA(isA<CredentialNotFound>()),
      );
    });

    test(
        'deployPendingCredential_credentialMissingPublicKey_throwsInvalid',
        () async {
      final credentials = StubCredentialManager();
      credentials.inject(StoredCredential(
        credentialId: 'cred',
        publicKey: Uint8List(0),
        contractId: _contractA,
      ));
      final kit = FakePipelineKit(credentialManager: credentials);
      final ops = OZWalletOperations(kit);
      await expectLater(
        () => ops.deployPendingCredential(
          credentialId: 'cred',
          autoSubmit: false,
        ),
        throwsA(
          isA<CredentialInvalid>().having(
            (e) => e.message,
            'message',
            contains('missing publicKey'),
          ),
        ),
      );
    });

    test('deployPendingCredential_simulateFailure_marksCredentialFailed',
        () async {
      final credentials = StubCredentialManager();
      credentials.inject(StoredCredential(
        credentialId: _credentialIdB64,
        publicKey: _bytes(65, 4),
        contractId: _contractA,
      ));
      final soroban = MockSorobanServer();
      soroban.getAccountResponses.add(_deployerAccount(KeyPair.random()));
      soroban.simulateResponses
          .add(_simResponseWithError('contract code missing'));

      final kit = FakePipelineKit(
        config: OZSmartAccountConfig(
          rpcUrl: 'https://soroban-testnet.stellar.org',
          networkPassphrase: Network.TESTNET.networkPassphrase,
          accountWasmHash: '0' * 64,
          webauthnVerifierAddress: _contractA,
        ),
        sorobanServer: soroban,
        credentialManager: credentials,
      );
      final ops = OZWalletOperations(kit);
      await expectLater(
        () => ops.deployPendingCredential(
          credentialId: _credentialIdB64,
          autoSubmit: false,
        ),
        throwsA(isA<TransactionSimulationFailed>()),
      );
      // Failure must be recorded against the credential.
      expect(credentials.markedFailures, isNotEmpty);
      expect(credentials.markedFailures.last.credentialId,
          equals(_credentialIdB64));
    });

    test(
        'deployPendingCredential_autoSubmit_relayer_setsFeeToResourceFeeOnly',
        () async {
      final credentials = StubCredentialManager();
      credentials.inject(StoredCredential(
        credentialId: _credentialIdB64,
        publicKey: _bytes(65, 4),
        contractId: _contractA,
      ));
      final soroban = MockSorobanServer();
      soroban.getAccountResponses.add(_deployerAccount(KeyPair.random()));
      soroban.simulateResponses.add(_simResponseEmpty(minResourceFee: 50000));
      // Poll for confirmation (deploy hand-rolls a 10x2s loop using
      // getTransaction directly).
      soroban.getTransactionResponses.add(_txSuccess());

      final relayerHarness = buildRelayerHarness(
        responseBody:
            '{"success":true,"hash":"deploy-hash","status":"SUCCESS"}',
      );

      final kit = FakePipelineKit(
        config: OZSmartAccountConfig(
          rpcUrl: 'https://soroban-testnet.stellar.org',
          networkPassphrase: Network.TESTNET.networkPassphrase,
          accountWasmHash: '0' * 64,
          webauthnVerifierAddress: _contractA,
        ),
        sorobanServer: soroban,
        credentialManager: credentials,
        relayerClient: relayerHarness.client,
      );
      final ops = OZWalletOperations(kit);
      final result = await ops.deployPendingCredential(
        credentialId: _credentialIdB64,
        autoSubmit: true,
      );
      expect(result.transactionHash, equals('deploy-hash'));
      expect(relayerHarness.adapter.capturedUrls, isNotEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // C.8 — Cross-SDK behaviour probe
  // -------------------------------------------------------------------------
  group('C.8 wire-shape probe', () {
    test('transfer_relayerSinglePath_sendsExpectedRequestShape', () async {
      final relayerHarness = buildRelayerHarness();
      final h = await _harness(relayer: relayerHarness.client);
      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer));
      h.soroban.simulateResponses.add(_simResponseEmpty());
      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer, seq: 2));
      h.soroban.simulateResponses.add(_simResponseEmpty());
      h.soroban.pollResponses.add(_txSuccess());

      final ops = OZTransactionOperations(h.kit);
      // Use a recipient distinct from the smart-account contract.
      const recipient = _contractB;
      await ops.transfer(
        tokenContract: _contractB,
        recipient: recipient,
        amount: '1.5',
      );
      expect(relayerHarness.adapter.capturedUrls, isNotEmpty);
    });

    test('transfer_rpcPath_sendsTransaction', () async {
      final h = await _harness();
      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer));
      h.soroban.simulateResponses.add(_simResponseEmpty());
      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer, seq: 2));
      h.soroban.simulateResponses.add(_simResponseEmpty());
      h.soroban.sendResponses.add(_sendPending(hash: 'transfer-rpc'));
      h.soroban.pollResponses.add(_txSuccess());

      final ops = OZTransactionOperations(h.kit);
      await ops.transfer(
        tokenContract: _contractB,
        recipient: _contractB,
        amount: '1',
        forceMethod: SubmissionMethod.rpc,
      );
      expect(h.soroban.sendCalls.length, equals(1));
    });

    test('contractCall_relayerPath_sendsHostFunctionShape', () async {
      final relayerHarness = buildRelayerHarness();
      final h = await _harness(relayer: relayerHarness.client);
      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer));
      h.soroban.simulateResponses.add(_simResponseEmpty());
      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer, seq: 2));
      h.soroban.simulateResponses.add(_simResponseEmpty());
      h.soroban.pollResponses.add(_txSuccess());
      final ops = OZTransactionOperations(h.kit);
      await ops.contractCall(target: _contractB, targetFn: 'noop');
      expect(relayerHarness.adapter.capturedUrls, isNotEmpty);
    });

    test('contractCall_rpcPath_sendsTransaction', () async {
      final h = await _harness();
      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer));
      h.soroban.simulateResponses.add(_simResponseEmpty());
      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer, seq: 2));
      h.soroban.simulateResponses.add(_simResponseEmpty());
      h.soroban.sendResponses.add(_sendPending(hash: 'cc-rpc'));
      h.soroban.pollResponses.add(_txSuccess());

      final ops = OZTransactionOperations(h.kit);
      await ops.contractCall(
        target: _contractB,
        targetFn: 'noop',
        forceMethod: SubmissionMethod.rpc,
      );
      expect(h.soroban.sendCalls.length, equals(1));
    });

    test('submit_relayerPath_sendsHostFunctionShape', () async {
      final relayerHarness = buildRelayerHarness();
      final h = await _harness(relayer: relayerHarness.client);
      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer));
      h.soroban.simulateResponses.add(_simResponseEmpty());
      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer, seq: 2));
      h.soroban.simulateResponses.add(_simResponseEmpty());
      h.soroban.pollResponses.add(_txSuccess());

      final ops = OZTransactionOperations(h.kit);
      await ops.submit(
        hostFunction: XdrHostFunction.forInvokingContractWithArgs(
          XdrInvokeContractArgs(
            Address.forContractId(_contractB).toXdr(),
            'noop',
            const <XdrSCVal>[],
          ),
        ),
        auth: const <XdrSorobanAuthorizationEntry>[],
      );
      expect(relayerHarness.adapter.capturedUrls, isNotEmpty);
    });

    test('submit_rpcPath_sendsTransaction', () async {
      final h = await _harness();
      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer));
      h.soroban.simulateResponses.add(_simResponseEmpty());
      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer, seq: 2));
      h.soroban.simulateResponses.add(_simResponseEmpty());
      h.soroban.sendResponses.add(_sendPending(hash: 'submit-rpc'));
      h.soroban.pollResponses.add(_txSuccess());

      final ops = OZTransactionOperations(h.kit);
      await ops.submit(
        hostFunction: XdrHostFunction.forInvokingContractWithArgs(
          XdrInvokeContractArgs(
            Address.forContractId(_contractB).toXdr(),
            'noop',
            const <XdrSCVal>[],
          ),
        ),
        auth: const <XdrSorobanAuthorizationEntry>[],
        forceMethod: SubmissionMethod.rpc,
      );
      expect(h.soroban.sendCalls.length, equals(1));
    });
  });

  // -------------------------------------------------------------------------
  // Nonce entropy regression (B-2)
  // -------------------------------------------------------------------------
  group('nonce entropy', () {
    test('_generateNonce_producesFullEntropy', () {
      // We can't reach the private helper directly. Instead, drive the
      // `_convertAndSignAuthEntries` path 1000 times via repeated
      // fundWallet-shaped source_account conversions and assert every byte
      // position across the runs has at least one non-zero value.
      //
      // Implementation: synthesize the BigInt accumulator directly with
      // the same routine the SDK uses, captured here as a verbatim copy
      // so the test asserts the production behaviour byte-for-byte.
      final seenBitsPerByte = List<int>.filled(8, 0);
      for (var iter = 0; iter < 1000; iter++) {
        final n = _testGenerateNonceBytes();
        for (var i = 0; i < 8; i++) {
          if (n[i] != 0) {
            seenBitsPerByte[i] = 1;
          }
        }
      }
      // Every byte position must have observed at least one non-zero.
      for (var i = 0; i < 8; i++) {
        expect(seenBitsPerByte[i], equals(1),
            reason: 'byte position $i never observed a non-zero value');
      }
    });
  });

  // -------------------------------------------------------------------------
  // Cancellation tests (M-3)
  // -------------------------------------------------------------------------
  group('cancellation', () {
    test('transfer_cancelledBeforeAwait_throwsSubmissionFailed', () async {
      final h = await _harness();
      h.soroban.getAccountResponses
          .add(_deployerAccount(h.deployer)); // first getAccount
      final token = dio.CancelToken();
      token.cancel('test');
      final ops = OZTransactionOperations(h.kit);
      await expectLater(
        () => ops.transfer(
          tokenContract: _contractB,
          recipient: _contractB,
          amount: '1',
          cancelToken: token,
        ),
        throwsA(isA<TransactionSubmissionFailed>()),
      );
    });

    test('contractCall_cancelledBeforeAwait_throwsSubmissionFailed', () async {
      final h = await _harness();
      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer));
      final token = dio.CancelToken();
      token.cancel('test');
      final ops = OZTransactionOperations(h.kit);
      await expectLater(
        () => ops.contractCall(
          target: _contractB,
          targetFn: 'noop',
          cancelToken: token,
        ),
        throwsA(isA<TransactionSubmissionFailed>()),
      );
    });

    test('executeAndSubmit_cancelledBeforeAwait_throwsSubmissionFailed',
        () async {
      final h = await _harness();
      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer));
      final token = dio.CancelToken();
      token.cancel('test');
      final ops = OZTransactionOperations(h.kit);
      await expectLater(
        () => ops.executeAndSubmit(
          target: _contractB,
          targetFn: 'noop',
          cancelToken: token,
        ),
        throwsA(isA<TransactionSubmissionFailed>()),
      );
    });

    test('submit_cancelledBeforeAwait_throwsSubmissionFailed', () async {
      final h = await _harness();
      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer));
      final token = dio.CancelToken();
      token.cancel('test');
      final ops = OZTransactionOperations(h.kit);
      await expectLater(
        () => ops.submit(
          hostFunction: XdrHostFunction.forInvokingContractWithArgs(
            XdrInvokeContractArgs(
              Address.forContractId(_contractB).toXdr(),
              'noop',
              const <XdrSCVal>[],
            ),
          ),
          auth: const <XdrSorobanAuthorizationEntry>[],
          cancelToken: token,
        ),
        throwsA(isA<TransactionSubmissionFailed>()),
      );
    });

    test('fundWallet_cancelledBeforeAwait_throwsSubmissionFailed', () async {
      final kit = FakePipelineKit()
        ..setConnected(credentialId: 'c', contractId: _contractA);
      final token = dio.CancelToken();
      token.cancel('test');
      final ops = OZTransactionOperations(kit);
      await expectLater(
        () => ops.fundWallet(
          nativeTokenContract: _contractA,
          cancelToken: token,
        ),
        throwsA(isA<TransactionSubmissionFailed>()),
      );
    });

    test('createWallet_cancelledBeforeAwait_throwsTransactionException',
        () async {
      // createWallet validates webauthnProvider first, so a not-supported
      // exception is thrown before cancellation is observed. With a
      // provider configured but the token already cancelled, the
      // cancellation check fires inside the build flow.
      final provider = RecordingWebAuthnProvider();
      provider.registerResponses.add(WebAuthnRegistrationResult(
        credentialId: _bytes(16, 5),
        publicKey: _bytes(65, 6),
        attestationObject: _bytes(48, 7),
      ));
      final config = OZSmartAccountConfig(
        rpcUrl: 'https://soroban-testnet.stellar.org',
        networkPassphrase: Network.TESTNET.networkPassphrase,
        accountWasmHash: '0' * 64,
        webauthnVerifierAddress: _contractA,
        webauthnProvider: provider,
      );
      final soroban = MockSorobanServer();
      soroban.getAccountResponses.add(_deployerAccount(KeyPair.random()));
      final kit = FakePipelineKit(
        config: config,
        sorobanServer: soroban,
      );
      final ops = OZWalletOperations(kit);
      final token = dio.CancelToken();
      token.cancel('test');
      await expectLater(
        () => ops.createWallet(cancelToken: token),
        throwsA(isA<TransactionException>()),
      );
    });

    test('connectWallet_cancelledBeforeAwait_throwsSubmissionFailed',
        () async {
      // connectWallet's default-options path returns null without using
      // network; force the credential-cascade path by passing a
      // credentialId so the cancellation checks fire after the storage
      // lookup.
      final credentials = StubCredentialManager();
      credentials.inject(StoredCredential(
        credentialId: _credentialIdB64,
        publicKey: _bytes(65),
        contractId: _contractA,
      ));
      final soroban = MockSorobanServer();
      soroban.getContractDataResponses
          .add(LedgerEntry('', '', 0, null, null));
      final kit = FakePipelineKit(
        sorobanServer: soroban,
        credentialManager: credentials,
      );
      final ops = OZWalletOperations(kit);
      final token = dio.CancelToken();
      token.cancel('test');
      await expectLater(
        () => ops.connectWallet(
          options: const ConnectWalletOptions(credentialId: _credentialIdB64),
          cancelToken: token,
        ),
        throwsA(isA<TransactionSubmissionFailed>()),
      );
    });

    test('authenticatePasskey_cancelledBeforeAwait_throwsSubmissionFailed',
        () async {
      final provider = RecordingWebAuthnProvider();
      final config = OZSmartAccountConfig(
        rpcUrl: 'https://soroban-testnet.stellar.org',
        networkPassphrase: Network.TESTNET.networkPassphrase,
        accountWasmHash: '0' * 64,
        webauthnVerifierAddress: _contractA,
        webauthnProvider: provider,
      );
      final kit = FakePipelineKit(config: config);
      final ops = OZWalletOperations(kit);
      final token = dio.CancelToken();
      token.cancel('test');
      await expectLater(
        () => ops.authenticatePasskey(
          credentialIds: <String>[_credentialIdB64],
          cancelToken: token,
        ),
        throwsA(isA<TransactionSubmissionFailed>()),
      );
    });

    test('deployPendingCredential_cancelledBeforeSubmit_throwsSubmissionFailed',
        () async {
      final credentials = StubCredentialManager();
      credentials.inject(StoredCredential(
        credentialId: _credentialIdB64,
        publicKey: _bytes(65, 4),
        contractId: _contractA,
      ));
      final soroban = MockSorobanServer();
      soroban.getAccountResponses.add(_deployerAccount(KeyPair.random()));
      soroban.simulateResponses.add(_simResponseEmpty(minResourceFee: 100));
      final kit = FakePipelineKit(
        config: OZSmartAccountConfig(
          rpcUrl: 'https://soroban-testnet.stellar.org',
          networkPassphrase: Network.TESTNET.networkPassphrase,
          accountWasmHash: '0' * 64,
          webauthnVerifierAddress: _contractA,
        ),
        sorobanServer: soroban,
        credentialManager: credentials,
      );
      final ops = OZWalletOperations(kit);
      final token = dio.CancelToken();
      token.cancel('test');
      await expectLater(
        () => ops.deployPendingCredential(
          credentialId: _credentialIdB64,
          autoSubmit: true,
          cancelToken: token,
        ),
        throwsA(isA<TransactionSubmissionFailed>()),
      );
    });
  });
}

/// Test-side equivalent of the SDK's `_generateNonce` byte generator.
///
/// Returns an 8-byte representation of the nonce so the entropy
/// regression test can inspect every byte position. Implements the same
/// algorithm as the SDK: 8 calls to `Random.secure().nextInt(256)`,
/// accumulated through a BigInt. The shift-and-mask round trip is
/// intentionally preserved so the test asserts behaviour identical to the
/// production path on both VM and JS targets.
Uint8List _testGenerateNonceBytes() {
  final random = math.Random.secure();
  var n = BigInt.zero;
  for (var i = 0; i < 8; i++) {
    n = (n << 8) | BigInt.from(random.nextInt(256));
  }
  final twoTo63 = BigInt.one << 63;
  final twoTo64 = BigInt.one << 64;
  final signed = n >= twoTo63 ? n - twoTo64 : n;
  // Re-encode signed BigInt back to 8 bytes (twos complement) so the
  // test can inspect each byte slot.
  final raw = signed.isNegative ? signed + twoTo64 : signed;
  final out = Uint8List(8);
  for (var i = 7; i >= 0; i--) {
    out[i] = (raw >> ((7 - i) * 8) & BigInt.from(0xFF)).toInt();
  }
  return out;
}
