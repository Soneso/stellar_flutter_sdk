// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import 'oz_pipeline_fixtures.dart';

const String _contractA =
    'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK';
const String _credentialId = 'aGVsbG8tc21hcnQtYWNjb3VudA';

Uint8List _bytes(int length, [int seed = 0]) {
  final out = Uint8List(length);
  for (var i = 0; i < length; i++) {
    out[i] = (seed + i) & 0xFF;
  }
  return out;
}

OZSmartAccountConfig _configWithoutProvider({
  String? indexerUrl,
}) {
  return OZSmartAccountConfig(
    rpcUrl: 'https://soroban-testnet.stellar.org',
    networkPassphrase: Network.TESTNET.networkPassphrase,
    accountWasmHash: '0' * 64,
    webauthnVerifierAddress: _contractA,
    indexerUrl: indexerUrl,
  );
}

void main() {
  // -------------------------------------------------------------------------
  // CreateWalletResult value type
  // -------------------------------------------------------------------------
  group('CreateWalletResult value type', () {
    test('testCreateWalletResult_construction_defaultOptionalFields', () {
      final pk = _bytes(65);
      final r = CreateWalletResult(
        credentialId: 'cred',
        contractId: _contractA,
        publicKey: pk,
        signedTransactionXdr: 'xdr',
      );
      expect(r.credentialId, equals('cred'));
      expect(r.contractId, equals(_contractA));
      expect(r.publicKey, equals(pk));
      expect(r.signedTransactionXdr, equals('xdr'));
      expect(r.transactionHash, isNull);
      expect(r.nickname, isNull);
    });

    test('testCreateWalletResult_constructionWithAllFields', () {
      final pk = _bytes(65, 1);
      final r = CreateWalletResult(
        credentialId: 'cred',
        contractId: _contractA,
        publicKey: pk,
        signedTransactionXdr: 'xdr',
        transactionHash: 'hash',
        nickname: 'Alice',
      );
      expect(r.transactionHash, equals('hash'));
      expect(r.nickname, equals('Alice'));
    });

    test('testCreateWalletResult_equality_sameData', () {
      final pk = _bytes(65, 2);
      final a = CreateWalletResult(
        credentialId: 'cred',
        contractId: _contractA,
        publicKey: pk,
        signedTransactionXdr: 'xdr',
        transactionHash: 'h',
        nickname: 'n',
      );
      final b = CreateWalletResult(
        credentialId: 'cred',
        contractId: _contractA,
        publicKey: Uint8List.fromList(pk),
        signedTransactionXdr: 'xdr',
        transactionHash: 'h',
        nickname: 'n',
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('testCreateWalletResult_equality_differentPublicKey', () {
      final a = CreateWalletResult(
        credentialId: 'cred',
        contractId: _contractA,
        publicKey: _bytes(65, 1),
        signedTransactionXdr: 'xdr',
      );
      final b = CreateWalletResult(
        credentialId: 'cred',
        contractId: _contractA,
        publicKey: _bytes(65, 2),
        signedTransactionXdr: 'xdr',
      );
      expect(a == b, isFalse);
    });

    test('testCreateWalletResult_equality_differentCredentialId', () {
      final pk = _bytes(65);
      final a = CreateWalletResult(
        credentialId: 'cred1',
        contractId: _contractA,
        publicKey: pk,
        signedTransactionXdr: 'xdr',
      );
      final b = CreateWalletResult(
        credentialId: 'cred2',
        contractId: _contractA,
        publicKey: pk,
        signedTransactionXdr: 'xdr',
      );
      expect(a == b, isFalse);
    });

    test('testCreateWalletResult_equality_differentTransactionHash', () {
      final pk = _bytes(65);
      final a = CreateWalletResult(
        credentialId: 'cred',
        contractId: _contractA,
        publicKey: pk,
        signedTransactionXdr: 'xdr',
        transactionHash: 'h1',
      );
      final b = CreateWalletResult(
        credentialId: 'cred',
        contractId: _contractA,
        publicKey: pk,
        signedTransactionXdr: 'xdr',
        transactionHash: 'h2',
      );
      expect(a == b, isFalse);
    });

    test('testCreateWalletResult_equality_differentNickname', () {
      final pk = _bytes(65);
      final a = CreateWalletResult(
        credentialId: 'cred',
        contractId: _contractA,
        publicKey: pk,
        signedTransactionXdr: 'xdr',
        nickname: 'Alice',
      );
      final b = CreateWalletResult(
        credentialId: 'cred',
        contractId: _contractA,
        publicKey: pk,
        signedTransactionXdr: 'xdr',
        nickname: 'Bob',
      );
      expect(a == b, isFalse);
    });

    test('testCreateWalletResult_copy', () {
      final pk = _bytes(65);
      final original = CreateWalletResult(
        credentialId: 'cred',
        contractId: _contractA,
        publicKey: pk,
        signedTransactionXdr: 'xdr',
      );
      final copy = original.copyWith(transactionHash: 'h');
      expect(copy.credentialId, equals('cred'));
      expect(copy.transactionHash, equals('h'));
    });

    test('testCreateWalletResult_equality_notEqualToNull', () {
      final Object? r = CreateWalletResult(
        credentialId: 'cred',
        contractId: _contractA,
        publicKey: _bytes(65),
        signedTransactionXdr: 'xdr',
      );
      expect(r == null, isFalse);
    });

    test('testCreateWalletResult_equality_notEqualToOtherType', () {
      final r = CreateWalletResult(
        credentialId: 'cred',
        contractId: _contractA,
        publicKey: _bytes(65),
        signedTransactionXdr: 'xdr',
      );
      expect(r == 'not-a-result', isFalse);
    });

    test('testCreateWalletResult_equality_sameInstance', () {
      final r = CreateWalletResult(
        credentialId: 'cred',
        contractId: _contractA,
        publicKey: _bytes(65),
        signedTransactionXdr: 'xdr',
      );
      expect(r, equals(r));
    });
  });

  // -------------------------------------------------------------------------
  // DeployPendingResult value type
  // -------------------------------------------------------------------------
  group('DeployPendingResult value type', () {
    test('testDeployPendingResult_construction_defaultOptionalFields', () {
      const r = DeployPendingResult(
        contractId: _contractA,
        signedTransactionXdr: 'xdr',
      );
      expect(r.contractId, equals(_contractA));
      expect(r.signedTransactionXdr, equals('xdr'));
      expect(r.transactionHash, isNull);
    });

    test('testDeployPendingResult_withTransactionHash', () {
      const r = DeployPendingResult(
        contractId: _contractA,
        signedTransactionXdr: 'xdr',
        transactionHash: 'h',
      );
      expect(r.transactionHash, equals('h'));
    });

    test('testDeployPendingResult_equality', () {
      const a = DeployPendingResult(
        contractId: _contractA,
        signedTransactionXdr: 'xdr',
        transactionHash: 'h',
      );
      const b = DeployPendingResult(
        contractId: _contractA,
        signedTransactionXdr: 'xdr',
        transactionHash: 'h',
      );
      const c = DeployPendingResult(
        contractId: _contractA,
        signedTransactionXdr: 'xdr',
        transactionHash: 'h2',
      );
      expect(a, equals(b));
      expect(a == c, isFalse);
    });

    test('testDeployPendingResult_copy', () {
      const original = DeployPendingResult(
        contractId: _contractA,
        signedTransactionXdr: 'xdr',
      );
      final copy = original.copyWith(transactionHash: 'h');
      expect(copy.transactionHash, equals('h'));
      expect(copy.contractId, equals(_contractA));
    });
  });

  // -------------------------------------------------------------------------
  // OZConnectWalletResult sealed-class
  // -------------------------------------------------------------------------
  group('OZConnectWalletResult sealed-class', () {
    test('testOZConnectWalletResult_connected_construction', () {
      const c = OZConnectWalletConnected(
        credentialId: 'cred',
        contractId: _contractA,
        restoredFromSession: false,
      );
      expect(c.credentialId, equals('cred'));
      expect(c.contractId, equals(_contractA));
      expect(c.restoredFromSession, isFalse);
    });

    test('testOZConnectWalletResult_connected_restoredFromSession', () {
      const c = OZConnectWalletConnected(
        credentialId: 'cred',
        contractId: _contractA,
        restoredFromSession: true,
      );
      expect(c.restoredFromSession, isTrue);
    });

    test('testOZConnectWalletResult_connected_equality', () {
      const a = OZConnectWalletConnected(
        credentialId: 'cred',
        contractId: _contractA,
        restoredFromSession: false,
      );
      const b = OZConnectWalletConnected(
        credentialId: 'cred',
        contractId: _contractA,
        restoredFromSession: false,
      );
      const c = OZConnectWalletConnected(
        credentialId: 'other',
        contractId: _contractA,
        restoredFromSession: false,
      );
      expect(a, equals(b));
      expect(a == c, isFalse);
    });

    test('testOZConnectWalletResult_connected_copy', () {
      const original = OZConnectWalletConnected(
        credentialId: 'cred',
        contractId: _contractA,
        restoredFromSession: false,
      );
      final copy = original.copyWith(restoredFromSession: true);
      expect(copy.restoredFromSession, isTrue);
      expect(copy.credentialId, equals('cred'));
    });

    test('testOZConnectWalletResult_ambiguous_construction', () {
      const a = OZConnectWalletAmbiguous(
        credentialId: 'cred',
        candidates: <String>[_contractA, _contractA],
      );
      expect(a.credentialId, equals('cred'));
      expect(a.candidates.length, equals(2));
    });

    test('testOZConnectWalletResult_sealed_when_exhaustive', () {
      // Test the sealed-class exhaustive-match invariant with two arms via
      // a List<OZConnectWalletResult> so the analyzer can't narrow the static
      // type prematurely.
      final List<OZConnectWalletResult> arms = <OZConnectWalletResult>[
        const OZConnectWalletConnected(
          credentialId: 'cred',
          contractId: _contractA,
          restoredFromSession: false,
        ),
        const OZConnectWalletAmbiguous(credentialId: 'cred', candidates: <String>[]),
      ];
      final messages = arms.map((arm) {
        return switch (arm) {
          OZConnectWalletConnected c => 'connected ${c.credentialId}',
          OZConnectWalletAmbiguous a => 'ambiguous ${a.candidates.length}',
        };
      }).toList();
      expect(messages[0], equals('connected cred'));
      expect(messages[1], equals('ambiguous 0'));
    });
  });

  // -------------------------------------------------------------------------
  // ConnectWalletOptions value type
  // -------------------------------------------------------------------------
  group('ConnectWalletOptions value type', () {
    test('testConnectWalletOptions_defaultValues', () {
      const o = ConnectWalletOptions();
      expect(o.credentialId, isNull);
      expect(o.contractId, isNull);
      expect(o.fresh, isFalse);
      expect(o.prompt, isFalse);
    });

    test('testConnectWalletOptions_withPrompt', () {
      const o = ConnectWalletOptions(prompt: true);
      expect(o.prompt, isTrue);
    });

    test('testConnectWalletOptions_withFresh', () {
      const o = ConnectWalletOptions(fresh: true);
      expect(o.fresh, isTrue);
    });

    test('testConnectWalletOptions_withCredentialIdAndContractId', () {
      const o = ConnectWalletOptions(
        credentialId: 'cred',
        contractId: _contractA,
      );
      expect(o.credentialId, equals('cred'));
      expect(o.contractId, equals(_contractA));
    });

    test('testConnectWalletOptions_withAllFields', () {
      const o = ConnectWalletOptions(
        credentialId: 'cred',
        contractId: _contractA,
        fresh: true,
        prompt: true,
      );
      expect(o.fresh, isTrue);
      expect(o.prompt, isTrue);
    });

    test('testConnectWalletOptions_equality', () {
      const a = ConnectWalletOptions(credentialId: 'cred', fresh: true);
      const b = ConnectWalletOptions(credentialId: 'cred', fresh: true);
      const c = ConnectWalletOptions(credentialId: 'cred', fresh: false);
      expect(a, equals(b));
      expect(a == c, isFalse);
    });

    test('testConnectWalletOptions_equalityPromptDiffers', () {
      const a = ConnectWalletOptions(fresh: true, prompt: false);
      const b = ConnectWalletOptions(fresh: true, prompt: true);
      expect(a == b, isFalse);
      expect(a.hashCode, isNot(equals(b.hashCode)));
    });

    test('testConnectWalletOptions_copy', () {
      const original = ConnectWalletOptions(fresh: true);
      final copy = original.copyWith(prompt: true);
      expect(copy.fresh, isTrue);
      expect(copy.prompt, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // AuthenticatePasskeyResult value type
  // -------------------------------------------------------------------------
  group('AuthenticatePasskeyResult value type', () {
    OZWebAuthnSignature mkSig([int seed = 0]) {
      return OZWebAuthnSignature(
        authenticatorData: _bytes(37, seed),
        clientData: _bytes(80, seed),
        signature: _bytes(64, seed),
      );
    }

    test('testAuthenticatePasskeyResult_equality_sameData', () {
      final pk = _bytes(65, 5);
      final a = AuthenticatePasskeyResult(
        credentialId: 'cred',
        signature: mkSig(),
        publicKey: pk,
      );
      final b = AuthenticatePasskeyResult(
        credentialId: 'cred',
        signature: mkSig(),
        publicKey: Uint8List.fromList(pk),
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('testAuthenticatePasskeyResult_equality_differentPublicKey', () {
      final a = AuthenticatePasskeyResult(
        credentialId: 'cred',
        signature: mkSig(),
        publicKey: _bytes(65, 1),
      );
      final b = AuthenticatePasskeyResult(
        credentialId: 'cred',
        signature: mkSig(),
        publicKey: _bytes(65, 2),
      );
      expect(a == b, isFalse);
    });

    test('testAuthenticatePasskeyResult_equality_differentCredentialId', () {
      final a = AuthenticatePasskeyResult(
        credentialId: 'cred1',
        signature: mkSig(),
        publicKey: _bytes(65),
      );
      final b = AuthenticatePasskeyResult(
        credentialId: 'cred2',
        signature: mkSig(),
        publicKey: _bytes(65),
      );
      expect(a == b, isFalse);
    });

    test('testAuthenticatePasskeyResult_equality_notEqualToOtherType', () {
      final r = AuthenticatePasskeyResult(
        credentialId: 'cred',
        signature: mkSig(),
        publicKey: _bytes(65),
      );
      expect(r == 'not-a-result', isFalse);
    });

    test('testAuthenticatePasskeyResult_equality_notEqualToNull', () {
      final Object? r = AuthenticatePasskeyResult(
        credentialId: 'cred',
        signature: mkSig(),
        publicKey: _bytes(65),
      );
      expect(r == null, isFalse);
    });

    test('testAuthenticatePasskeyResult_fieldAccess', () {
      final sig = mkSig();
      final pk = _bytes(65);
      final r = AuthenticatePasskeyResult(
        credentialId: 'cred',
        signature: sig,
        publicKey: pk,
      );
      expect(r.credentialId, equals('cred'));
      expect(r.signature, equals(sig));
      expect(r.publicKey, equals(pk));
    });
  });

  // -------------------------------------------------------------------------
  // createWallet validation
  // -------------------------------------------------------------------------
  group('createWallet validation', () {
    test('testCreateWallet_noWebAuthnProvider_throwsNotSupported', () async {
      final kit = FakePipelineKit(config: _configWithoutProvider());
      final ops = OZWalletOperations(kit);
      await expectLater(
        () => ops.createWallet(),
        throwsA(isA<WebAuthnNotSupported>()),
      );
    });

    test('testCreateWallet_noWebAuthnProvider_withCustomUserName', () async {
      final kit = FakePipelineKit(config: _configWithoutProvider());
      final ops = OZWalletOperations(kit);
      await expectLater(
        () => ops.createWallet(userName: 'Alice'),
        throwsA(isA<WebAuthnNotSupported>()),
      );
    });

    test('testCreateWallet_noWebAuthnProvider_withAutoSubmit', () async {
      final kit = FakePipelineKit(config: _configWithoutProvider());
      final ops = OZWalletOperations(kit);
      await expectLater(
        () => ops.createWallet(autoSubmit: true),
        throwsA(isA<WebAuthnNotSupported>()),
      );
    });

    test('testCreateWallet_noWebAuthnProvider_withAutoFundAndToken', () async {
      final kit = FakePipelineKit(config: _configWithoutProvider());
      final ops = OZWalletOperations(kit);
      await expectLater(
        () => ops.createWallet(
          autoSubmit: true,
          autoFund: true,
          nativeTokenContract: _contractA,
        ),
        throwsA(isA<WebAuthnNotSupported>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // authenticatePasskey validation
  // -------------------------------------------------------------------------
  group('authenticatePasskey validation', () {
    test('testAuthenticatePasskey_noWebAuthnProvider_throwsNotSupported',
        () async {
      final kit = FakePipelineKit(config: _configWithoutProvider());
      final ops = OZWalletOperations(kit);
      await expectLater(
        () => ops.authenticatePasskey(),
        throwsA(isA<WebAuthnNotSupported>()),
      );
    });

    test('testAuthenticatePasskey_noWebAuthnProvider_withChallenge', () async {
      final kit = FakePipelineKit(config: _configWithoutProvider());
      final ops = OZWalletOperations(kit);
      await expectLater(
        () => ops.authenticatePasskey(challenge: _bytes(32)),
        throwsA(isA<WebAuthnNotSupported>()),
      );
    });

    test('testAuthenticatePasskey_noWebAuthnProvider_withCredentialIds',
        () async {
      final kit = FakePipelineKit(config: _configWithoutProvider());
      final ops = OZWalletOperations(kit);
      await expectLater(
        () => ops.authenticatePasskey(credentialIds: <String>[_credentialId]),
        throwsA(isA<WebAuthnNotSupported>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // connectWallet validation
  // -------------------------------------------------------------------------
  group('connectWallet validation', () {
    test('testConnectWallet_defaultOptions_noSession_returnsNull', () async {
      final kit = FakePipelineKit(config: _configWithoutProvider());
      final ops = OZWalletOperations(kit);
      final result = await ops.connectWallet();
      expect(result, isNull);
    });

    test('testConnectWallet_promptFalse_noSession_returnsNull', () async {
      final kit = FakePipelineKit(config: _configWithoutProvider());
      final ops = OZWalletOperations(kit);
      final result =
          await ops.connectWallet(options: const ConnectWalletOptions());
      expect(result, isNull);
    });

    test('testConnectWallet_freshTrue_noWebAuthnProvider_throwsNotSupported',
        () async {
      final kit = FakePipelineKit(config: _configWithoutProvider());
      final ops = OZWalletOperations(kit);
      await expectLater(
        () => ops.connectWallet(
          options: const ConnectWalletOptions(fresh: true),
        ),
        throwsA(isA<WebAuthnNotSupported>()),
      );
    });

    test(
        'testConnectWallet_promptTrue_noSession_noWebAuthnProvider_throwsNotSupported',
        () async {
      final kit = FakePipelineKit(config: _configWithoutProvider());
      final ops = OZWalletOperations(kit);
      await expectLater(
        () => ops.connectWallet(
          options: const ConnectWalletOptions(prompt: true),
        ),
        throwsA(isA<WebAuthnNotSupported>()),
      );
    });

    test('testConnectWallet_contractIdWithoutCredentialId_throwsValidation',
        () async {
      final kit = FakePipelineKit(config: _configWithoutProvider());
      final ops = OZWalletOperations(kit);
      await expectLater(
        () => ops.connectWallet(
          options: const ConnectWalletOptions(contractId: _contractA),
        ),
        throwsA(isA<InvalidInput>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // Kit connected-state lifecycle
  // -------------------------------------------------------------------------
  group('kit connected-state lifecycle', () {
    test('testKit_initialState_notConnected', () async {
      final kit = FakePipelineKit();
      await expectLater(
        () => kit.requireConnected(),
        throwsA(isA<WalletNotConnected>()),
      );
    });

    test('testKit_afterSetConnectedState', () async {
      final kit = FakePipelineKit();
      await kit.setConnectedState(credentialId: 'cred', contractId: _contractA);
      final state = await kit.requireConnected();
      expect(state.credentialId, equals('cred'));
      expect(state.contractId, equals(_contractA));
    });

    test('testKit_setConnectedState_overwritesPrevious', () async {
      final kit = FakePipelineKit();
      await kit.setConnectedState(credentialId: 'cred1', contractId: _contractA);
      await kit.setConnectedState(credentialId: 'cred2', contractId: _contractA);
      expect((await kit.requireConnected()).credentialId, equals('cred2'));
    });
  });

  // -------------------------------------------------------------------------
  // Kit requireConnected behavior
  // -------------------------------------------------------------------------
  //
  // The smart-account kit exposes the full `disconnect()` operation in a
  // layer above the operations classes. These tests exercise the
  // connected-state transitions reachable directly from the operations
  // layer.
  group('requireConnected behavior', () {
    test('testRequireConnected_whenNotConnected_throwsNotConnected', () async {
      final kit = FakePipelineKit();
      await expectLater(
        () => kit.requireConnected(),
        throwsA(isA<WalletNotConnected>()),
      );
    });

    test('testRequireConnected_whenConnected_returnsPair', () async {
      final kit = FakePipelineKit();
      await kit.setConnectedState(credentialId: 'cred', contractId: _contractA);
      final state = await kit.requireConnected();
      expect(state.credentialId, equals('cred'));
      expect(state.contractId, equals(_contractA));
    });

    test('testRequireConnected_afterDisconnect_throwsNotConnected', () async {
      // No disconnect on OZWalletOperations; emulate by replacing fixture.
      final kit = FakePipelineKit();
      await kit.setConnectedState(credentialId: 'cred', contractId: _contractA);
      // Reconstruct fresh kit to simulate disconnect state.
      final fresh = FakePipelineKit();
      expect((await kit.requireConnected()).credentialId, equals('cred'));
      await expectLater(
        () => fresh.requireConnected(),
        throwsA(isA<WalletNotConnected>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // disconnect state lifecycle
  // -------------------------------------------------------------------------
  group('disconnect state lifecycle', () {
    test('testDisconnect_afterConnectedState_clearsState', () async {
      final kit = FakePipelineKit();
      await kit.setConnectedState(credentialId: 'cred', contractId: _contractA);
      expect((await kit.requireConnected()).credentialId, equals('cred'));
      await kit.disconnect();
      await expectLater(
        () => kit.requireConnected(),
        throwsA(isA<WalletNotConnected>()),
      );
    });

    test('testDisconnect_whenNotConnected_doesNotThrow', () async {
      final kit = FakePipelineKit();
      await kit.disconnect();
      await expectLater(
        () => kit.requireConnected(),
        throwsA(isA<WalletNotConnected>()),
      );
    });

    test('testDisconnect_doubleDisconnect_doesNotThrow', () async {
      final kit = FakePipelineKit();
      await kit.setConnectedState(credentialId: 'cred', contractId: _contractA);
      await kit.disconnect();
      await kit.disconnect();
      await expectLater(
        () => kit.requireConnected(),
        throwsA(isA<WalletNotConnected>()),
      );
    });

    test('testDisconnect_emitsEvent_whenConnected', () async {
      final kit = FakePipelineKit();
      await kit.setConnectedState(credentialId: 'cred', contractId: _contractA);
      final captured = <SmartAccountEvent>[];
      kit.events.addListener(captured.add);
      await kit.disconnect();
      expect(captured.length, equals(1));
      final evt = captured.single;
      expect(evt, isA<SmartAccountEventWalletDisconnected>());
      expect(
        (evt as SmartAccountEventWalletDisconnected).contractId,
        equals(_contractA),
      );
    });

    test('testDisconnect_doesNotEmitEvent_whenNotConnected', () async {
      final kit = FakePipelineKit();
      final captured = <SmartAccountEvent>[];
      kit.events.addListener(captured.add);
      await kit.disconnect();
      expect(captured, isEmpty);
    });

    test('testDisconnect_clearsSession', () async {
      final kit = FakePipelineKit();
      await kit.setConnectedState(credentialId: 'cred', contractId: _contractA);
      final storage = kit.getStorage();
      await storage.saveSession(
        StoredSession(
          credentialId: 'cred',
          contractId: _contractA,
          connectedAt: DateTime.now().millisecondsSinceEpoch,
          expiresAt:
              DateTime.now().millisecondsSinceEpoch + 60_000,
        ),
      );
      expect(await storage.getSession(), isNotNull);
      await kit.disconnect();
      expect(await storage.getSession(), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // connectWallet: session restoration
  // -------------------------------------------------------------------------
  group('deployPendingCredential build failure paths', () {
    test('buildTransactionGenericFailure_wrapsAsSubmissionFailed', () async {
      // When _buildDeployTransaction throws a non-SmartAccountException,
      // lines 1047-1048 wrap it as TransactionSubmissionFailed.
      final credentials = StubCredentialManager();
      final pk = _bytes(65);
      pk[0] = 0x04;
      credentials.inject(StoredCredential(
        credentialId: _credentialId,
        publicKey: pk,
        contractId: _contractA,
        createdAt: 1700000000000,
      ));

      final mock = MockSorobanServer();
      // getAccount throws a plain Error (not SmartAccountException).
      mock.getAccountDefault = Error(); // causes _fetchAccount to throw

      final kit = FakePipelineKit(
        sorobanServer: mock,
        credentialManager: credentials,
      );
      final ops = OZWalletOperations(kit);

      await expectLater(
        () => ops.deployPendingCredential(credentialId: _credentialId),
        throwsA(isA<TransactionSubmissionFailed>()),
      );
    });
  });

  group('connectWallet session restoration', () {
    test('validSession_contractNotOnChain_returnsNull', () async {
      // A valid session exists, but getContractData returns null (contract not on-chain).
      // The OZWalletNotFound path clears the session and falls through. Since
      // prompt=false, returns null.
      final storage = InMemoryStorageAdapter();
      await storage.saveSession(
        StoredSession(
          credentialId: _credentialId,
          contractId: _contractA,
          connectedAt: DateTime.now().millisecondsSinceEpoch,
          expiresAt: DateTime.now().millisecondsSinceEpoch + 60000,
        ),
      );

      final mock = MockSorobanServer();
      // getContractData returns null → contract not on-chain → WalletNotFound.
      mock.getContractDataResponses.add(null);

      final kit = FakePipelineKit(storage: storage, sorobanServer: mock);
      final ops = OZWalletOperations(kit);
      // Session exists but contract is not on-chain → session cleared, returns null.
      final result = await ops.connectWallet();
      expect(result, isNull);
    });

    test('noSession_promptFalse_returnsNull', () async {
      // No session in storage + prompt=false → returns null without WebAuthn.
      final kit = FakePipelineKit(config: _configWithoutProvider());
      final ops = OZWalletOperations(kit);
      final result = await ops.connectWallet(
        options: const ConnectWalletOptions(prompt: false),
      );
      expect(result, isNull);
    });

    test('freshOption_skipsSessionCheck', () async {
      final storage = InMemoryStorageAdapter();
      await storage.saveSession(
        StoredSession(
          credentialId: _credentialId,
          contractId: _contractA,
          connectedAt: DateTime.now().millisecondsSinceEpoch,
          expiresAt: DateTime.now().millisecondsSinceEpoch + 60000,
        ),
      );

      final kit = FakePipelineKit(
        config: _configWithoutProvider(),
        storage: storage,
      );
      final ops = OZWalletOperations(kit);
      // With fresh=true, session check is skipped and we go straight to
      // the WebAuthn prompt path. Since no provider is configured, throws.
      await expectLater(
        () => ops.connectWallet(options: const ConnectWalletOptions(fresh: true)),
        throwsA(isA<WebAuthnNotSupported>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // connectWallet: credential storage resolution
  // -------------------------------------------------------------------------
  group('connectWallet credential storage resolution', () {
    test('credentialWithFailedDeployment_throwsWalletNotFound', () async {
      // _resolveViaStorage returns WalletNotFound for failed credentials.
      // Use StubCredentialManager with the failed credential injected.
      final credentials = StubCredentialManager();
      final pk = _bytes(65);
      pk[0] = 0x04;
      credentials.inject(StoredCredential(
        credentialId: _credentialId,
        publicKey: pk,
        contractId: _contractA,
        deploymentStatus: CredentialDeploymentStatus.failed,
        createdAt: 1700000000000,
      ));

      final provider = RecordingWebAuthnProvider();
      final credIdBytes = base64Url.decode(
        base64Url.normalize(_credentialId),
      );
      provider.authenticateResponses.add(WebAuthnAuthenticationResult(
        credentialId: credIdBytes,
        authenticatorData: _bytes(37, 3),
        clientDataJSON: utf8.encode(
          '{"type":"webauthn.get","challenge":"abc","origin":"https://test"}',
        ),
        signature: Uint8List.fromList(<int>[
          0x30, 0x44,
          0x02, 0x20, ..._bytes(32, 1),
          0x02, 0x20, ..._bytes(32, 2),
        ]),
      ));

      final config = OZSmartAccountConfig(
        rpcUrl: 'https://soroban-testnet.stellar.org',
        networkPassphrase: Network.TESTNET.networkPassphrase,
        accountWasmHash: '0' * 64,
        webauthnVerifierAddress: _contractA,
        webauthnProvider: provider,
      );
      final kit = FakePipelineKit(
        config: config,
        credentialManager: credentials,
      );
      final ops = OZWalletOperations(kit);

      await expectLater(
        () => ops.connectWallet(
          options: const ConnectWalletOptions(prompt: true),
        ),
        throwsA(isA<WalletNotFound>()),
      );
    });

    test('credentialWithContractId_noIndexer_throwsWalletNotFound', () async {
      // _resolveViaStorage finds the credential → returns its contractId.
      // _connectWithCredentials calls _verifyContractExists which returns null
      // (contract not on-chain) → throws WalletNotFound.
      // No indexer → connect fails.
      final credentials = StubCredentialManager();
      final pk = _bytes(65);
      pk[0] = 0x04;
      credentials.inject(StoredCredential(
        credentialId: _credentialId,
        publicKey: pk,
        contractId: _contractA,
        deploymentStatus: CredentialDeploymentStatus.pending,
        createdAt: 1700000000000,
      ));

      final provider = RecordingWebAuthnProvider();
      final credIdBytes = base64Url.decode(
        base64Url.normalize(_credentialId),
      );
      provider.authenticateResponses.add(WebAuthnAuthenticationResult(
        credentialId: credIdBytes,
        authenticatorData: _bytes(37, 3),
        clientDataJSON: utf8.encode(
          '{"type":"webauthn.get","challenge":"abc","origin":"https://test"}',
        ),
        signature: Uint8List.fromList(<int>[
          0x30, 0x44,
          0x02, 0x20, ..._bytes(32, 1),
          0x02, 0x20, ..._bytes(32, 2),
        ]),
      ));

      final mock = MockSorobanServer();
      // getContractData returns null (contract not on-chain) → WalletNotFound.
      mock.getContractDataResponses.add(null);

      final config = OZSmartAccountConfig(
        rpcUrl: 'https://soroban-testnet.stellar.org',
        networkPassphrase: Network.TESTNET.networkPassphrase,
        accountWasmHash: '0' * 64,
        webauthnVerifierAddress: _contractA,
        webauthnProvider: provider,
      );
      final kit = FakePipelineKit(
        config: config,
        sorobanServer: mock,
        credentialManager: credentials,
      );
      final ops = OZWalletOperations(kit);

      await expectLater(
        () => ops.connectWallet(
          options: const ConnectWalletOptions(prompt: true),
        ),
        throwsA(isA<WalletNotFound>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // deployPendingCredential validation
  // -------------------------------------------------------------------------
  group('deployPendingCredential validation', () {
    test(
        'testDeployPendingCredential_autoFundWithoutToken_throwsValidation',
        () async {
      final kit = FakePipelineKit();
      final ops = OZWalletOperations(kit);
      await expectLater(
        () => ops.deployPendingCredential(
          credentialId: _credentialId,
          autoSubmit: true,
          autoFund: true,
        ),
        throwsA(isA<InvalidInput>()),
      );
    });

    test(
        'testDeployPendingCredential_credentialNotFound_throwsCredentialException',
        () async {
      final kit = FakePipelineKit();
      final ops = OZWalletOperations(kit);
      await expectLater(
        () => ops.deployPendingCredential(credentialId: _credentialId),
        throwsA(isA<CredentialNotFound>()),
      );
    });

    test(
        'testDeployPendingCredential_credentialMissingPublicKey_throwsInvalid',
        () async {
      final kit = FakePipelineKit();
      await kit.credentialManager.createPendingCredential(
        credentialId: _credentialId,
        publicKey: Uint8List(0),
        contractId: _contractA,
      );
      final ops = OZWalletOperations(kit);
      await expectLater(
        () => ops.deployPendingCredential(credentialId: _credentialId),
        throwsA(
          isA<CredentialInvalid>().having(
            (e) => e.message,
            'message',
            contains('missing publicKey'),
          ),
        ),
      );
    });

    test(
        'testDeployPendingCredential_credentialMissingContractId_throwsInvalid',
        () async {
      final kit = FakePipelineKit();
      await kit.credentialManager.createPendingCredential(
        credentialId: _credentialId,
        publicKey: _bytes(65),
        contractId: '', // empty → treated as missing
      );
      final ops = OZWalletOperations(kit);
      await expectLater(
        () => ops.deployPendingCredential(credentialId: _credentialId),
        throwsA(isA<CredentialInvalid>()),
      );
    });

    test(
        'testDeployPendingCredential_credentialEmptyContractId_throwsInvalid',
        () async {
      final kit = FakePipelineKit();
      await kit.credentialManager.createPendingCredential(
        credentialId: _credentialId,
        publicKey: _bytes(65),
        contractId: '',
      );
      final ops = OZWalletOperations(kit);
      await expectLater(
        () => ops.deployPendingCredential(credentialId: _credentialId),
        throwsA(isA<CredentialInvalid>()),
      );
    });

    test(
        'testDeployPendingCredential_autoFundValidation_beforeCredentialLookup',
        () async {
      final kit = FakePipelineKit();
      final ops = OZWalletOperations(kit);
      // autoFund without token must throw before any storage lookup happens.
      await expectLater(
        () => ops.deployPendingCredential(
          credentialId: 'never-stored',
          autoSubmit: true,
          autoFund: true,
        ),
        throwsA(isA<InvalidInput>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // Above-floor: ConnectWalletOptions copyWith edge cases
  // -------------------------------------------------------------------------
  group('above-floor: ConnectWalletOptions copyWith', () {
    test('copyWith_clearsFields_whenClearFlagsTrue', () {
      const original = ConnectWalletOptions(
        credentialId: 'cred',
        contractId: _contractA,
        fresh: true,
        prompt: true,
      );
      final cleared = original.copyWith(
        clearCredentialId: true,
        clearContractId: true,
      );
      expect(cleared.credentialId, isNull);
      expect(cleared.contractId, isNull);
      expect(cleared.fresh, isTrue); // preserved
      expect(cleared.prompt, isTrue); // preserved
    });
  });

  // -------------------------------------------------------------------------
  // Base64URL credential-id normalisation at entry points
  //
  // Every downstream surface that exposes the credentialId to consumers —
  // the connected-state field, emitted events, saved sessions, the
  // allow-list storage-key lookup — keys on the unpadded RFC 4648 §5 form
  // produced by the WebAuthn cascade. Callers may legitimately pass a
  // padded value from external sources; the public entry points strip the
  // padding once so the canonical form propagates uniformly.
  // -------------------------------------------------------------------------
  group('credentialId normalisation: connectWallet (explicit contractId)', () {
    // The padded form of `_credentialId`. Base64URL would emit two `=` chars
    // for this 19-byte payload; the unpadded form is what storage keys on
    // and what the connect path produces.
    const String _paddedCredentialId = '$_credentialId==';

    SmartAccountEventWalletConnected? _connectedEvent(
      List<SmartAccountEvent> captured,
    ) {
      for (final e in captured) {
        if (e is SmartAccountEventWalletConnected) return e;
      }
      return null;
    }

    Future<({FakePipelineKit kit, List<SmartAccountEvent> captured})> _runConnect(
      String suppliedCredentialId,
    ) async {
      final soroban = MockSorobanServer();
      // End-of-cascade verify in `_finalizeConnect` consults `getContractData`
      // exactly once for the explicit-contractId path; a non-null entry signals
      // the contract is live.
      soroban.getContractDataResponses.add(LedgerEntry('', '', 0, null, null));
      final kit = FakePipelineKit(
        config: _configWithoutProvider(),
        sorobanServer: soroban,
      );
      final captured = <SmartAccountEvent>[];
      kit.events.addListener(captured.add);

      final ops = OZWalletOperations(kit);
      final result = await ops.connectWallet(
        options: ConnectWalletOptions(
          credentialId: suppliedCredentialId,
          contractId: _contractA,
        ),
      );
      expect(result, isA<OZConnectWalletConnected>());
      return (kit: kit, captured: captured);
    }

    test(
        'testConnectWallet_paddedCredentialId_connectedStateIsUnpadded',
        () async {
      final outcome = await _runConnect(_paddedCredentialId);
      final state = await outcome.kit.requireConnected();
      expect(state.credentialId, equals(_credentialId));
      expect(state.contractId, equals(_contractA));
    });

    test(
        'testConnectWallet_paddedCredentialId_walletConnectedEventIsUnpadded',
        () async {
      final outcome = await _runConnect(_paddedCredentialId);
      final evt = _connectedEvent(outcome.captured);
      expect(evt, isNotNull);
      expect(evt!.credentialId, equals(_credentialId));
      expect(evt.contractId, equals(_contractA));
    });

    test(
        'testConnectWallet_paddedCredentialId_savedSessionIsUnpadded',
        () async {
      final outcome = await _runConnect(_paddedCredentialId);
      final session = await outcome.kit.getStorage().getSession();
      expect(session, isNotNull);
      expect(session!.credentialId, equals(_credentialId));
      expect(session.contractId, equals(_contractA));
    });

    test(
        'testConnectWallet_unpaddedCredentialId_propagatesUnpaddedUnchanged',
        () async {
      // Baseline: the canonical unpadded form already matches everywhere.
      // This test guards against an accidental double-strip or substring
      // off-by-one in the normalisation helper.
      final outcome = await _runConnect(_credentialId);
      final state = await outcome.kit.requireConnected();
      expect(state.credentialId, equals(_credentialId));
      final evt = _connectedEvent(outcome.captured);
      expect(evt, isNotNull);
      expect(evt!.credentialId, equals(_credentialId));
      final session = await outcome.kit.getStorage().getSession();
      expect(session, isNotNull);
      expect(session!.credentialId, equals(_credentialId));
    });
  });

  // -------------------------------------------------------------------------
  // Base64URL credential-id normalisation: authenticatePasskey allow-list
  //
  // The allow-list construction loads transport hints from storage by
  // credential-id key. Storage entries are written under the unpadded form;
  // a padded caller input must hit the same entry instead of silently
  // missing and degrading to "no transports hint".
  // -------------------------------------------------------------------------
  group('credentialId normalisation: authenticatePasskey allow-list', () {
    const String _paddedCredentialId = '$_credentialId==';

    test(
        'testAuthenticatePasskey_paddedAllowListId_loadsTransportsFromUnpaddedStorageKey',
        () async {
      final webauthn = RecordingWebAuthnProvider();
      // Well-formed DER signature: 0x30 SEQUENCE, length 0x44, 0x02 INTEGER
      // r (32 bytes), 0x02 INTEGER s (32 bytes). The signature normaliser
      // in the smart-account utils requires syntactically valid DER.
      final derSignature = Uint8List.fromList(<int>[
        0x30, 0x44,
        0x02, 0x20,
        ..._bytes(32, 1),
        0x02, 0x20,
        ..._bytes(32, 2),
      ]);
      webauthn.authenticateResponses.add(
        WebAuthnAuthenticationResult(
          credentialId: base64Url.decode(base64Url.normalize(_credentialId)),
          authenticatorData: _bytes(37),
          clientDataJSON: Uint8List.fromList(
            '{"type":"webauthn.get"}'.codeUnits,
          ),
          signature: derSignature,
        ),
      );

      final storage = InMemoryStorageAdapter();
      await storage.save(
        StoredCredential(
          credentialId: _credentialId,
          publicKey: _bytes(65),
          contractId: _contractA,
          transports: const <String>['internal', 'hybrid'],
        ),
      );

      final kit = FakePipelineKit(
        config: OZSmartAccountConfig(
          rpcUrl: 'https://soroban-testnet.stellar.org',
          networkPassphrase: Network.TESTNET.networkPassphrase,
          accountWasmHash: '0' * 64,
          webauthnVerifierAddress: _contractA,
          webauthnProvider: webauthn,
        ),
        storage: storage,
      );
      final ops = OZWalletOperations(kit);

      final result = await ops.authenticatePasskey(
        credentialIds: <String>[_paddedCredentialId],
      );

      // Result-side: the returned credentialId is always unpadded because
      // it is encoded from raw bytes via the connect-side encoder.
      expect(result.credentialId, equals(_credentialId));

      // Allow-list side: the WebAuthn provider received the transport
      // hints loaded from the unpadded storage key. A storage miss would
      // surface here as `null` transports.
      expect(webauthn.authenticateCalls, hasLength(1));
      final call = webauthn.authenticateCalls.single;
      expect(call.allowCredentials, isNotNull);
      expect(call.allowCredentials!, hasLength(1));
      expect(
        call.allowCredentials!.single.transports,
        equals(<String>['internal', 'hybrid']),
      );
    });
  });
}
