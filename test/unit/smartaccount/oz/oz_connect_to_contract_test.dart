// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:dio/dio.dart' as dio;
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import 'mock_oz_multi_signer_manager.dart';
import 'oz_pipeline_fixtures.dart';

/// Valid smart-account contract address reused across the headless-connect
/// tests.
const String _contractA =
    'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK';

/// Valid recipient G-address for the transfer guard sub-case. Distinct from
/// [_contractA] so the self-transfer check does not fire before the guard.
const String _recipientG =
    'GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ';

/// Builds a non-null instance ledger entry signalling "contract exists".
LedgerEntry _existingInstanceEntry() => LedgerEntry('', '', 0, null, null);

/// Matcher for the single-passkey guard: a validation exception whose message
/// names the headless connection and directs the caller to the multi-signer
/// pipeline. Asserting the message distinguishes the guard from
/// address-validation, which also raises a [SmartAccountValidationException].
final Matcher _throwsHeadlessGuard = throwsA(
  isA<SmartAccountValidationException>()
      .having((e) => e.message, 'message', contains('headlessly'))
      .having((e) => e.message, 'message', contains('multi-signer pipeline')),
);

void main() {
  // -------------------------------------------------------------------------
  // OZConnectToContractResult value type
  // -------------------------------------------------------------------------
  group('OZConnectToContractResult value type', () {
    test('testConnectToContractResult_valueEqualityAndHashCode', () {
      const a = OZConnectToContractResult(contractId: _contractA);
      const b = OZConnectToContractResult(contractId: _contractA);
      const c = OZConnectToContractResult(
        contractId:
            'CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM',
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
      expect(a.contractId, equals(_contractA));
    });
  });

  // -------------------------------------------------------------------------
  // connectToContract: happy path
  // -------------------------------------------------------------------------
  group('connectToContract success', () {
    test('testConnectToContract_existingContract_setsConnectedState',
        () async {
      final soroban = MockSorobanServer();
      soroban.getContractDataResponses.add(_existingInstanceEntry());
      final kit = FakePipelineKit(sorobanServer: soroban);
      final ops = OZWalletOperations(kit);

      final result = await ops.connectToContract(_contractA);

      expect(kit.isConnected, isTrue);
      expect(kit.contractId, equals(_contractA));
      expect(kit.credentialId, isNull);
      expect(kit.isHeadless, isTrue);
      final state = await kit.requireConnected();
      expect(state.contractId, equals(_contractA));
      expect(state.credentialId, isNull);
      expect(state.isHeadless, isTrue);
      expect(result.contractId, equals(_contractA));
    });

    test('testConnectToContract_verifiesContractOnChain', () async {
      final soroban = MockSorobanServer();
      soroban.getContractDataResponses.add(_existingInstanceEntry());
      final kit = FakePipelineKit(sorobanServer: soroban);
      final ops = OZWalletOperations(kit);

      await ops.connectToContract(_contractA);

      // The single queued instance entry was consumed by the on-chain verify.
      expect(soroban.getContractDataResponses, isEmpty);
      expect(soroban.getContractDataCalls.length, equals(1));
      expect(soroban.getContractDataCalls.single.contractId, equals(_contractA));
    });

    test('testConnectToContract_emitsHeadlessConnectedEvent_only', () async {
      final soroban = MockSorobanServer();
      soroban.getContractDataResponses.add(_existingInstanceEntry());
      final kit = FakePipelineKit(sorobanServer: soroban);
      final ops = OZWalletOperations(kit);

      final headlessEvents = <OZSmartAccountEventHeadlessConnected>[];
      final walletEvents = <OZSmartAccountEventWalletConnected>[];
      kit.events.on<OZSmartAccountEventHeadlessConnected>(headlessEvents.add);
      kit.events.on<OZSmartAccountEventWalletConnected>(walletEvents.add);

      await ops.connectToContract(_contractA);

      expect(headlessEvents.length, equals(1));
      expect(headlessEvents.single.contractId, equals(_contractA));
      // No credential-bearing event — a headless connection carries no credential.
      expect(walletEvents, isEmpty);
    });

    test('testConnectToContract_doesNotSaveSession', () async {
      final soroban = MockSorobanServer();
      soroban.getContractDataResponses.add(_existingInstanceEntry());
      final kit = FakePipelineKit(sorobanServer: soroban);
      final ops = OZWalletOperations(kit);

      expect(await kit.getStorage().getSession(), isNull);
      await ops.connectToContract(_contractA);
      expect(await kit.getStorage().getSession(), isNull);
    });

    test('testConnectToContract_clearsPreexistingSession', () async {
      final soroban = MockSorobanServer();
      soroban.getContractDataResponses.add(_existingInstanceEntry());
      final kit = FakePipelineKit(sorobanServer: soroban);
      final ops = OZWalletOperations(kit);

      final now = DateTime.now().millisecondsSinceEpoch;
      await kit.getStorage().saveSession(
            OZStoredSession(
              credentialId: 'real-passkey-credential',
              contractId:
                  'CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM',
              connectedAt: now,
              expiresAt: now + 60_000,
            ),
          );
      expect(await kit.getStorage().getSession(), isNotNull);

      await ops.connectToContract(_contractA);

      // The stale passkey session is cleared so a later silent
      // connectWallet() cannot resurrect it over the headless connection.
      expect(await kit.getStorage().getSession(), isNull);
    });

    test('testConnectToContract_clearSessionFailure_stillConnects', () async {
      final soroban = MockSorobanServer();
      soroban.getContractDataResponses.add(_existingInstanceEntry());
      final kit = FakePipelineKit(
        sorobanServer: soroban,
        storage: _ClearSessionFaultStorage(),
      );
      final ops = OZWalletOperations(kit);

      // A stale passkey session is present before the headless connect.
      final now = DateTime.now().millisecondsSinceEpoch;
      await kit.getStorage().saveSession(
            OZStoredSession(
              credentialId: 'real-passkey-credential',
              contractId:
                  'CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM',
              connectedAt: now,
              expiresAt: now + 60_000,
            ),
          );

      final headlessEvents = <OZSmartAccountEventHeadlessConnected>[];
      kit.events.on<OZSmartAccountEventHeadlessConnected>(headlessEvents.add);

      // Clearing the persisted session is best-effort: a storage write
      // failure is swallowed rather than failing the connect, so the call
      // still resolves and the headless state is set.
      final result = await ops.connectToContract(_contractA);

      expect(result.contractId, equals(_contractA));
      expect(kit.contractId, equals(_contractA));
      final state = await kit.requireConnected();
      expect(state.contractId, equals(_contractA));
      expect(state.credentialId, isNull);
      expect(state.isHeadless, isTrue);

      // The dedicated headless event is emitted despite the clear failure.
      expect(headlessEvents.length, equals(1));
      expect(headlessEvents.single.contractId, equals(_contractA));

      // The clear failed and was swallowed, so the stale session survives —
      // the documented consequence of best-effort clearing.
      expect(await kit.getStorage().getSession(), isNotNull);
    });

    test('testConnectToContract_doesNotTouchCredentialManager', () async {
      final soroban = MockSorobanServer();
      soroban.getContractDataResponses.add(_existingInstanceEntry());
      final credentialManager = StubCredentialManager();
      final kit = FakePipelineKit(
        sorobanServer: soroban,
        credentialManager: credentialManager,
      );
      final ops = OZWalletOperations(kit);

      final deletedEvents = <OZSmartAccountEventCredentialDeleted>[];
      kit.events.on<OZSmartAccountEventCredentialDeleted>(deletedEvents.add);

      await ops.connectToContract(_contractA);

      // connectToContract performs no WebAuthn ceremony and writes nothing to
      // the credential store: no credential is created, deleted, or stored.
      expect(credentialManager.storedCredentialIds, isEmpty);
      expect(credentialManager.deletedCredentialIds, isEmpty);
      expect(deletedEvents, isEmpty);
    });

    test('testConnectToContract_isConnectedReflectsState', () async {
      final soroban = MockSorobanServer();
      soroban.getContractDataResponses.add(_existingInstanceEntry());
      final kit = FakePipelineKit(sorobanServer: soroban);
      final ops = OZWalletOperations(kit);

      // Before: not connected.
      expect(kit.contractId, isNull);
      await expectLater(
        () => kit.requireConnected(),
        throwsA(isA<SmartAccountWalletNotConnected>()),
      );

      await ops.connectToContract(_contractA);

      // After: connected headlessly (contract bound, no passkey credential).
      expect(kit.isConnected, isTrue);
      expect(kit.contractId, equals(_contractA));
      expect(kit.credentialId, isNull);
      expect(kit.isHeadless, isTrue);
      final state = await kit.requireConnected();
      expect(state.contractId, equals(_contractA));
      expect(state.credentialId, isNull);
      expect(state.isHeadless, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // connectToContract: error paths
  // -------------------------------------------------------------------------
  group('connectToContract errors', () {
    test('testConnectToContract_nonexistentContract_throwsNotFound', () async {
      final soroban = MockSorobanServer();
      // A null instance entry signals "no contract on-chain".
      soroban.getContractDataResponses.add(null);
      final kit = FakePipelineKit(sorobanServer: soroban);
      final ops = OZWalletOperations(kit);

      await expectLater(
        () => ops.connectToContract(_contractA),
        throwsA(isA<SmartAccountWalletNotFound>()),
      );

      // Connection state is not set on failure.
      expect(kit.contractId, isNull);
      await expectLater(
        () => kit.requireConnected(),
        throwsA(isA<SmartAccountWalletNotConnected>()),
      );
    });

    test('testConnectToContract_invalidContractId_throwsInvalidAddress',
        () async {
      final soroban = MockSorobanServer();
      final kit = FakePipelineKit(sorobanServer: soroban);
      final ops = OZWalletOperations(kit);

      await expectLater(
        () => ops.connectToContract('not-a-c-address'),
        throwsA(isA<SmartAccountInvalidAddress>()),
      );

      // Validation precedes any network call and leaves the state unset.
      expect(soroban.getContractDataCalls, isEmpty);
      expect(kit.contractId, isNull);
      await expectLater(
        () => kit.requireConnected(),
        throwsA(isA<SmartAccountWalletNotConnected>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // connectToContract: cancellation
  // -------------------------------------------------------------------------
  group('connectToContract cancellation', () {
    test('testConnectToContract_cancelledBeforeAwait_throwsSubmissionFailed',
        () async {
      final soroban = MockSorobanServer();
      // Seed an existing-contract entry that must never be consumed: the
      // entry-time cancellation check runs before the on-chain verify, so a
      // pre-cancelled token aborts before getContractData is ever reached.
      soroban.getContractDataResponses.add(_existingInstanceEntry());
      final kit = FakePipelineKit(sorobanServer: soroban);
      final ops = OZWalletOperations(kit);

      final token = dio.CancelToken();
      token.cancel('test');

      await expectLater(
        () => ops.connectToContract(_contractA, cancelToken: token),
        throwsA(isA<SmartAccountTransactionSubmissionFailed>().having(
          (e) => e.message,
          'message',
          contains('Operation cancelled'),
        )),
      );

      // Cancellation preceded the on-chain verify and the state set: the
      // queued instance entry is untouched, no getContractData lookup ran,
      // and the connection state was never established.
      expect(soroban.getContractDataResponses.length, equals(1));
      expect(soroban.getContractDataCalls, isEmpty);
      expect(kit.contractId, isNull);
      await expectLater(
        () => kit.requireConnected(),
        throwsA(isA<SmartAccountWalletNotConnected>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // Single-passkey guard after a headless connect
  // -------------------------------------------------------------------------
  group('connectToContract single-passkey guard', () {
    test('testConnectToContract_thenSinglePasskeySubmit_throwsGuard',
        () async {
      final soroban = MockSorobanServer();
      soroban.getContractDataResponses.add(_existingInstanceEntry());
      final kit = FakePipelineKit(sorobanServer: soroban);
      final ops = OZWalletOperations(kit);

      await ops.connectToContract(_contractA);
      // The connect verify consumed exactly one getContractData lookup.
      expect(soroban.getContractDataCalls.length, equals(1));

      final txOps = kit.transactionOperations;

      // Direct submit().
      final hostFunction = XdrHostFunction.forInvokingContractWithArgs(
        XdrInvokeContractArgs(
          Address.forContractId(_contractA).toXdr(),
          'noop',
          const <XdrSCVal>[],
        ),
      );
      await expectLater(
        () => txOps.submit(
          hostFunction: hostFunction,
          auth: const <XdrSorobanAuthorizationEntry>[],
        ),
        _throwsHeadlessGuard,
      );

      // executeAndSubmit() with a valid contract target.
      await expectLater(
        () => txOps.executeAndSubmit(target: _contractA, targetFn: 'noop'),
        _throwsHeadlessGuard,
      );

      // contractCall() with a valid contract target.
      await expectLater(
        () => txOps.contractCall(target: _contractA, targetFn: 'noop'),
        _throwsHeadlessGuard,
      );

      // transfer() with explicit decimals (no on-chain decimals lookup) and a
      // valid recipient distinct from the connected contract.
      await expectLater(
        () => txOps.transfer(
          tokenContract: _contractA,
          recipient: _recipientG,
          amount: '1',
          decimals: 7,
        ),
        _throwsHeadlessGuard,
      );

      // A manager call left at the default empty selectedSigners routes into
      // submit() via ozRouteSubmission and hits the same guard.
      final signerManager = OZSignerManager(kit);
      await expectLater(
        () => signerManager.removeSigner(contextRuleId: 0, signerId: 0),
        _throwsHeadlessGuard,
      );

      // The guard fires before any network step in every sub-case: no
      // additional getContractData lookup, no simulation, no send, no account
      // fetch beyond the single connect verify.
      expect(soroban.getContractDataCalls.length, equals(1));
      expect(soroban.simulateCalls, isEmpty);
      expect(soroban.sendCalls, isEmpty);
      expect(soroban.getAccountCalls, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // Multi-signer path composes with a headless connect
  // -------------------------------------------------------------------------
  group('connectToContract multi-signer path', () {
    test('testConnectToContract_thenMultiSignerRouting_reachesMultiSignerManager',
        () async {
      final soroban = MockSorobanServer();
      soroban.getContractDataResponses.add(_existingInstanceEntry());
      final kit = FakePipelineKit(sorobanServer: soroban);
      final multi = MockOZMultiSignerManager(kit);
      kit.setMultiSignerManager(multi);

      await OZWalletOperations(kit).connectToContract(_contractA);
      // The connect verify consumed exactly one getContractData lookup.
      expect(soroban.getContractDataCalls.length, equals(1));

      final ed25519Signer = OZSelectedSignerEd25519(
        verifierAddress: _contractA,
        publicKey: Uint8List.fromList(
          List<int>.generate(32, (i) => i & 0xFF),
        ),
      );

      // A real manager call carrying a NON-empty selectedSigners list routes
      // through the production ozRouteSubmission. Its non-empty branch must
      // reach submitWithMultipleSigners and never enter the guarded submit()
      // path. removeSigner mirrors the default-empty guard sub-case covered
      // by testConnectToContract_thenSinglePasskeySubmit_throwsGuard, which
      // routes the empty list into submit() and throws the headless guard;
      // here the non-empty list takes the multi-signer branch instead.
      final result = await OZSignerManager(kit).removeSigner(
        contextRuleId: 0,
        signerId: 0,
        selectedSigners: <OZSelectedSigner>[ed25519Signer],
      );

      expect(result.success, isTrue);

      // Routing reached the multi-signer manager with the supplied signer and
      // did not divert to multiSignerContractCall or the other entry points.
      final call = multi.submitWithMultipleSignersCalls.single;
      expect(call.selectedSigners.single, isA<OZSelectedSignerEd25519>());
      expect(multi.multiSignerContractCallCalls, isEmpty);

      // The single-passkey submit() path was not taken: no headless guard
      // threw (the call above completed), and no submit-side network ran
      // beyond the connect verify.
      expect(soroban.getContractDataCalls.length, equals(1));
      expect(soroban.simulateCalls, isEmpty);
      expect(soroban.sendCalls, isEmpty);
      expect(soroban.getAccountCalls, isEmpty);
    });
  });
}

/// Storage double whose [clearSession] always fails with the documented
/// [SmartAccountStorageWriteFailed]. Drives the best-effort session-clear
/// branch of [OZWalletOperations.connectToContract]: the failure must be
/// swallowed so the connect still completes. Save/read operations delegate to
/// the in-memory base so a pre-seeded session can be observed to survive the
/// failed clear.
class _ClearSessionFaultStorage extends OZInMemoryStorageAdapter {
  @override
  Future<void> clearSession() async {
    throw SmartAccountStorageException.writeFailed('session');
  }
}
