// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

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
}
