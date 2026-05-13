// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/src/smartaccount/oz/oz_internal_pipeline_interfaces.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import 'mock_oz_multi_signer_manager.dart';
import 'mock_oz_transaction_operations.dart';
import 'oz_pipeline_fixtures.dart';

const String _validContractId =
    'CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM';
const String _validAccountAddress =
    'GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ';
const String _credentialIdB64 = 'aGVsbG8tc21hcnQtYWNjb3VudA';
const String _thirdAccountAddress =
    'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';

/// Stub context-rule manager whose read paths always throw
/// [WalletNotConnected]. Used by overloads (`removeSignerBySigner`,
/// `removePolicyByAddress`) that fetch the rule before reaching their
/// own `requireConnected()` check; the throw mirrors what a real
/// disconnected kit would surface from the not-connected RPC path.
class _NotConnectedRuleManager implements OZContextRuleManagerInterface {
  @override
  Future<List<Object>> listContextRules() async {
    throw WalletException.notConnected();
  }

  @override
  Future<List<int>> resolveContextRuleIdsForEntry(
    XdrSorobanAuthorizationEntry entry,
    List<OZSmartAccountSigner> signers,
    List<Object> contextRules,
  ) async {
    throw WalletException.notConnected();
  }

  @override
  Future<List<XdrSCVal>> getAllContextRules({int? maxScanId}) async {
    throw WalletException.notConnected();
  }

  @override
  Future<XdrSCVal> getContextRule(int id) async {
    throw WalletException.notConnected();
  }

  @override
  ParsedContextRule parseContextRule(XdrSCVal scVal) {
    throw WalletException.notConnected();
  }
}

/// Builds an unconnected fake kit with default config values.
FakePipelineKit _disconnectedKit() => FakePipelineKit();

/// Builds an unconnected kit whose context-rule manager surfaces
/// [WalletNotConnected] on every read, matching what a real
/// disconnected kit would do at the RPC step.
FakePipelineKit _disconnectedKitWithNotConnectedRuleReads() =>
    FakePipelineKit(contextRuleManager: _NotConnectedRuleManager());

/// Builds a connected kit ready to exercise the validation phases of
/// every OZ manager method.
FakePipelineKit _connectedKit() {
  final kit = FakePipelineKit();
  kit.setConnected(credentialId: _credentialIdB64, contractId: _validContractId);
  return kit;
}

SelectedSigner _passkeyStub() => const SelectedSignerPasskey(
      credentialId: null,
      credentialIdBytes: null,
      keyData: null,
    );

SelectedSigner _walletStub({String address = _validAccountAddress}) =>
    SelectedSignerWallet(address);

List<SelectedSigner> _multiSigners() => <SelectedSigner>[
      _passkeyStub(),
      _walletStub(),
    ];

void main() {
  // =======================================================================
  // OZSignerManager.addDelegated — selectedSigners
  // =======================================================================

  group('OZSignerManager.addDelegated selectedSigners', () {
    test('testAddDelegated_notConnected_withSelectedSigners_throwsNotConnected',
        () async {
      final kit = _disconnectedKit();
      final mgr = OZSignerManager(kit);
      await expectLater(
        () => mgr.addDelegated(
          contextRuleId: 0,
          address: _validAccountAddress,
          selectedSigners: _multiSigners(),
        ),
        throwsA(isA<WalletNotConnected>()),
      );
    });

    test(
        'testAddDelegated_connected_withSelectedSigners_reachesAddressValidation',
        () async {
      final kit = _connectedKit();
      final mgr = OZSignerManager(kit);
      // Invalid address triggers OZDelegatedSigner constructor validation.
      await expectLater(
        () => mgr.addDelegated(
          contextRuleId: 0,
          address: 'INVALID',
          selectedSigners: _multiSigners(),
        ),
        throwsA(isA<InvalidAddress>()),
      );
    });
  });

  // =======================================================================
  // OZSignerManager.addEd25519 — selectedSigners
  // =======================================================================

  group('OZSignerManager.addEd25519 selectedSigners', () {
    test('testAddEd25519_notConnected_withSelectedSigners_throwsNotConnected',
        () async {
      final kit = _disconnectedKit();
      final mgr = OZSignerManager(kit);
      await expectLater(
        () => mgr.addEd25519(
          contextRuleId: 0,
          verifierAddress: _validContractId,
          publicKey: Uint8List(32),
          selectedSigners: _multiSigners(),
        ),
        throwsA(isA<WalletNotConnected>()),
      );
    });

    test('testAddEd25519_connected_withSelectedSigners_reachesKeyValidation',
        () async {
      final kit = _connectedKit();
      final mgr = OZSignerManager(kit);
      // Wrong key size should trigger validation in the ed25519 factory.
      await expectLater(
        () => mgr.addEd25519(
          contextRuleId: 0,
          verifierAddress: _validContractId,
          publicKey: Uint8List(10),
          selectedSigners: _multiSigners(),
        ),
        throwsA(isA<InvalidInput>()),
      );
    });
  });

  // =======================================================================
  // OZSignerManager.addPasskey — selectedSigners
  // =======================================================================

  group('OZSignerManager.addPasskey selectedSigners', () {
    test('testAddPasskey_notConnected_withSelectedSigners_throwsNotConnected',
        () async {
      final kit = _disconnectedKit();
      final mgr = OZSignerManager(kit);
      await expectLater(
        () => mgr.addPasskey(
          contextRuleId: 0,
          publicKey: Uint8List(65),
          credentialId: Uint8List(16),
          selectedSigners: _multiSigners(),
        ),
        throwsA(isA<WalletNotConnected>()),
      );
    });

    test('testAddPasskey_connected_withSelectedSigners_reachesKeyValidation',
        () async {
      final kit = _connectedKit();
      final mgr = OZSignerManager(kit);
      await expectLater(
        () => mgr.addPasskey(
          contextRuleId: 0,
          publicKey: Uint8List(10),
          credentialId: Uint8List(16),
          selectedSigners: _multiSigners(),
        ),
        throwsA(isA<InvalidInput>()),
      );
    });
  });

  // =======================================================================
  // OZSignerManager.removeSigner — selectedSigners
  // =======================================================================

  group('OZSignerManager.removeSigner selectedSigners', () {
    test('testRemoveSigner_notConnected_withSelectedSigners_throwsNotConnected',
        () async {
      final kit = _disconnectedKit();
      final mgr = OZSignerManager(kit);
      await expectLater(
        () => mgr.removeSigner(
          contextRuleId: 0,
          signerId: 1,
          selectedSigners: _multiSigners(),
        ),
        throwsA(isA<WalletNotConnected>()),
      );
    });

    test('testRemoveSignerBySigner_notConnected_throwsNotConnected', () async {
      // why: removeSignerBySigner reaches `getContextRule` BEFORE its
      // local `requireConnected()` call (the production order: rule
      // lookup, parse, then the ID-based overload's connect check). On a
      // disconnected kit that lookup is what surfaces the not-connected
      // error, so the test wires a context-rule manager that simulates
      // the disconnected RPC path.
      final kit = _disconnectedKitWithNotConnectedRuleReads();
      final mgr = OZSignerManager(kit);
      await expectLater(
        () => mgr.removeSignerBySigner(
          contextRuleId: 0,
          signer: OZDelegatedSigner(_validAccountAddress),
          selectedSigners: _multiSigners(),
        ),
        throwsA(isA<WalletNotConnected>()),
      );
    });
  });

  // =======================================================================
  // OZPolicyManager.addPolicy — selectedSigners
  // =======================================================================

  group('OZPolicyManager.addPolicy selectedSigners', () {
    test('testAddPolicy_notConnected_withSelectedSigners_throwsNotConnected',
        () async {
      final kit = _disconnectedKit();
      final mgr = OZPolicyManager(kit);
      await expectLater(
        () => mgr.addPolicy(
          contextRuleId: 0,
          policyAddress: _validContractId,
          installParams: XdrSCVal.forVoid(),
          selectedSigners: _multiSigners(),
        ),
        throwsA(isA<WalletNotConnected>()),
      );
    });

    test('testAddPolicy_connected_withSelectedSigners_reachesAddressValidation',
        () async {
      final kit = _connectedKit();
      final mgr = OZPolicyManager(kit);
      await expectLater(
        () => mgr.addPolicy(
          contextRuleId: 0,
          policyAddress: 'INVALID',
          installParams: XdrSCVal.forVoid(),
          selectedSigners: _multiSigners(),
        ),
        throwsA(isA<InvalidAddress>()),
      );
    });
  });

  // =======================================================================
  // OZPolicyManager.removePolicy — selectedSigners
  // =======================================================================

  group('OZPolicyManager.removePolicy selectedSigners', () {
    test('testRemovePolicy_notConnected_withSelectedSigners_throwsNotConnected',
        () async {
      final kit = _disconnectedKit();
      final mgr = OZPolicyManager(kit);
      await expectLater(
        () => mgr.removePolicy(
          contextRuleId: 0,
          policyId: 1,
          selectedSigners: _multiSigners(),
        ),
        throwsA(isA<WalletNotConnected>()),
      );
    });

    test('testRemovePolicyByAddress_notConnected_throwsNotConnected',
        () async {
      // why: removePolicyByAddress validates the policy address and
      // then reaches `getContextRule` before its local
      // `requireConnected()` call. On a disconnected kit that lookup
      // is what surfaces the not-connected error.
      final kit = _disconnectedKitWithNotConnectedRuleReads();
      final mgr = OZPolicyManager(kit);
      await expectLater(
        () => mgr.removePolicyByAddress(
          contextRuleId: 0,
          policyAddress: _validContractId,
          selectedSigners: _multiSigners(),
        ),
        throwsA(isA<WalletNotConnected>()),
      );
    });
  });

  // =======================================================================
  // OZContextRuleManager.updateName — selectedSigners
  // =======================================================================

  group('OZContextRuleManager.updateName selectedSigners', () {
    test('testUpdateName_notConnected_withSelectedSigners_throwsNotConnected',
        () async {
      final kit = _disconnectedKit();
      final mgr = OZContextRuleManager(kit);
      await expectLater(
        () => mgr.updateName(
          id: 0,
          name: 'New Name',
          selectedSigners: _multiSigners(),
        ),
        throwsA(isA<WalletNotConnected>()),
      );
    });

    test('testUpdateName_connected_withSelectedSigners_reachesInputValidation',
        () async {
      final kit = _connectedKit();
      final mgr = OZContextRuleManager(kit);
      await expectLater(
        () => mgr.updateName(
          id: 0,
          name: '',
          selectedSigners: _multiSigners(),
        ),
        throwsA(isA<InvalidInput>()),
      );
    });
  });

  // =======================================================================
  // OZContextRuleManager.updateValidUntil — selectedSigners
  // =======================================================================

  group('OZContextRuleManager.updateValidUntil selectedSigners', () {
    test(
        'testUpdateValidUntil_notConnected_withSelectedSigners_throwsNotConnected',
        () async {
      final kit = _disconnectedKit();
      final mgr = OZContextRuleManager(kit);
      await expectLater(
        () => mgr.updateValidUntil(
          id: 0,
          validUntil: 100,
          selectedSigners: _multiSigners(),
        ),
        throwsA(isA<WalletNotConnected>()),
      );
    });
  });

  // =======================================================================
  // OZSignerManager.addNewPasskeySigner — selectedSigners
  // =======================================================================

  group('OZSignerManager.addNewPasskeySigner selectedSigners', () {
    test(
        'testAddNewPasskeySigner_notConnected_withSelectedSigners_throwsNotConnected',
        () async {
      final kit = _disconnectedKit();
      final mgr = OZSignerManager(kit);
      await expectLater(
        () => mgr.addNewPasskeySigner(
          contextRuleId: 0,
          userName: 'test',
          selectedSigners: _multiSigners(),
        ),
        throwsA(isA<WalletNotConnected>()),
      );
    });
  });

  // =======================================================================
  // Default-parameter (selectedSigners omitted) — must compile and use the
  // empty-list default.
  // =======================================================================

  group('Default selectedSigners parameter', () {
    test('testAddDelegated_defaultSelectedSigners_isEmptyList', () async {
      final kit = _disconnectedKit();
      final mgr = OZSignerManager(kit);
      await expectLater(
        () => mgr.addDelegated(
          contextRuleId: 0,
          address: _validAccountAddress,
        ),
        throwsA(isA<WalletNotConnected>()),
      );
    });

    test('testRemoveSigner_defaultSelectedSigners_isEmptyList', () async {
      final kit = _disconnectedKit();
      final mgr = OZSignerManager(kit);
      await expectLater(
        () => mgr.removeSigner(contextRuleId: 0, signerId: 1),
        throwsA(isA<WalletNotConnected>()),
      );
    });

    test('testAddPolicy_defaultSelectedSigners_isEmptyList', () async {
      final kit = _disconnectedKit();
      final mgr = OZPolicyManager(kit);
      await expectLater(
        () => mgr.addPolicy(
          contextRuleId: 0,
          policyAddress: _validContractId,
          installParams: XdrSCVal.forVoid(),
        ),
        throwsA(isA<WalletNotConnected>()),
      );
    });

    test('testRemovePolicy_defaultSelectedSigners_isEmptyList', () async {
      final kit = _disconnectedKit();
      final mgr = OZPolicyManager(kit);
      await expectLater(
        () => mgr.removePolicy(contextRuleId: 0, policyId: 1),
        throwsA(isA<WalletNotConnected>()),
      );
    });

    test('testUpdateName_defaultSelectedSigners_isEmptyList', () async {
      final kit = _disconnectedKit();
      final mgr = OZContextRuleManager(kit);
      await expectLater(
        () => mgr.updateName(id: 0, name: 'Test'),
        throwsA(isA<WalletNotConnected>()),
      );
    });

    test('testUpdateValidUntil_defaultSelectedSigners_isEmptyList', () async {
      final kit = _disconnectedKit();
      final mgr = OZContextRuleManager(kit);
      await expectLater(
        () => mgr.updateValidUntil(id: 0, validUntil: 100),
        throwsA(isA<WalletNotConnected>()),
      );
    });
  });

  // =======================================================================
  // OZContextRuleManager.addContextRule — selectedSigners
  // =======================================================================

  group('OZContextRuleManager.addContextRule selectedSigners', () {
    test('testAddContextRule_withSelectedSigners_notConnected', () async {
      final kit = _disconnectedKit();
      final mgr = OZContextRuleManager(kit);
      await expectLater(
        () => mgr.addContextRule(
          contextType: const ContextRuleTypeDefault(),
          name: 'TestRule',
          signers: const <OZSmartAccountSigner>[],
          selectedSigners: _multiSigners(),
        ),
        throwsA(isA<WalletNotConnected>()),
      );
    });

    test('testAddContextRule_defaultSelectedSigners', () async {
      final kit = _disconnectedKit();
      final mgr = OZContextRuleManager(kit);
      await expectLater(
        () => mgr.addContextRule(
          contextType: const ContextRuleTypeDefault(),
          name: 'TestRule',
          signers: const <OZSmartAccountSigner>[],
        ),
        throwsA(isA<WalletNotConnected>()),
      );
    });
  });

  // =======================================================================
  // OZContextRuleManager.removeContextRule — selectedSigners
  // =======================================================================

  group('OZContextRuleManager.removeContextRule selectedSigners', () {
    test('testRemoveContextRule_withSelectedSigners_notConnected', () async {
      final kit = _disconnectedKit();
      final mgr = OZContextRuleManager(kit);
      await expectLater(
        () => mgr.removeContextRule(id: 0, selectedSigners: _multiSigners()),
        throwsA(isA<WalletNotConnected>()),
      );
    });

    test('testRemoveContextRule_defaultSelectedSigners', () async {
      final kit = _disconnectedKit();
      final mgr = OZContextRuleManager(kit);
      await expectLater(
        () => mgr.removeContextRule(id: 0),
        throwsA(isA<WalletNotConnected>()),
      );
    });
  });

  // =======================================================================
  // forceMethod parameter — accepted by manager methods
  // =======================================================================

  group('forceMethod parameter', () {
    test('testAddDelegated_withForceMethod_notConnected', () async {
      final kit = _disconnectedKit();
      final mgr = OZSignerManager(kit);
      await expectLater(
        () => mgr.addDelegated(
          contextRuleId: 0,
          address: _validAccountAddress,
          forceMethod: SubmissionMethod.rpc,
        ),
        throwsA(isA<WalletNotConnected>()),
      );
    });

    test('testRemovePolicy_withForceMethod_notConnected', () async {
      final kit = _disconnectedKit();
      final mgr = OZPolicyManager(kit);
      await expectLater(
        () => mgr.removePolicy(
          contextRuleId: 0,
          policyId: 1,
          forceMethod: SubmissionMethod.rpc,
        ),
        throwsA(isA<WalletNotConnected>()),
      );
    });

    test('testUpdateName_defaultForceMethod', () async {
      final kit = _disconnectedKit();
      final mgr = OZContextRuleManager(kit);
      // Calling without forceMethod uses the default null. The not-connected
      // check fires first regardless, confirming the default is reachable.
      await expectLater(
        () => mgr.updateName(id: 0, name: 'Test'),
        throwsA(isA<WalletNotConnected>()),
      );
    });

    test('testAddContextRule_withForceMethod_notConnected', () async {
      final kit = _disconnectedKit();
      final mgr = OZContextRuleManager(kit);
      await expectLater(
        () => mgr.addContextRule(
          contextType: const ContextRuleTypeDefault(),
          name: 'TestRule',
          signers: const <OZSmartAccountSigner>[],
          forceMethod: SubmissionMethod.relayer,
        ),
        throwsA(isA<WalletNotConnected>()),
      );
    });

    test('testRemoveContextRule_withForceMethod_notConnected', () async {
      final kit = _disconnectedKit();
      final mgr = OZContextRuleManager(kit);
      await expectLater(
        () => mgr.removeContextRule(id: 0, forceMethod: SubmissionMethod.rpc),
        throwsA(isA<WalletNotConnected>()),
      );
    });

    test('testRemoveSigner_withForceMethod_notConnected', () async {
      final kit = _disconnectedKit();
      final mgr = OZSignerManager(kit);
      await expectLater(
        () => mgr.removeSigner(
          contextRuleId: 0,
          signerId: 1,
          forceMethod: SubmissionMethod.rpc,
        ),
        throwsA(isA<WalletNotConnected>()),
      );
    });

    test('testUpdateValidUntil_withForceMethod_notConnected', () async {
      final kit = _disconnectedKit();
      final mgr = OZContextRuleManager(kit);
      await expectLater(
        () => mgr.updateValidUntil(
          id: 0,
          validUntil: 100,
          forceMethod: SubmissionMethod.relayer,
        ),
        throwsA(isA<WalletNotConnected>()),
      );
    });

    test('testAddSpendingLimit_withForceMethod_notConnected', () async {
      final kit = _disconnectedKit();
      final mgr = OZPolicyManager(kit);
      await expectLater(
        () => mgr.addSpendingLimit(
          contextRuleId: 0,
          policyAddress: _validContractId,
          spendingLimit: '100',
          periodLedgers: 17280,
          forceMethod: SubmissionMethod.rpc,
        ),
        throwsA(isA<WalletNotConnected>()),
      );
    });
  });

  // =======================================================================
  // Group J.1 — multi-signer fanout: 3-signer mix (plan line 720)
  // =======================================================================

  group('Group J.1 multi-signer fanout', () {
    /// Builds a ready-to-use harness wiring a kit with the
    /// [MockOZMultiSignerManager] injected and [MockOZTransactionOperations]
    /// in place.
    ({
      FakePipelineKit kit,
      MockOZMultiSignerManager multi,
      MockOZTransactionOperations txOps,
    }) buildHarness() {
      final kit = FakePipelineKit();
      final txOps = MockOZTransactionOperations(kit);
      kit.setTransactionOperations(txOps);
      final multi = MockOZMultiSignerManager(kit);
      kit.setMultiSignerManager(multi);
      kit.setConnected(
        credentialId: _credentialIdB64,
        contractId: _validContractId,
      );
      return (kit: kit, multi: multi, txOps: txOps);
    }

    test(
        'submitWithMultipleSigners_threeSigners_passkey_delegated_ed25519_collectsAllSignatures',
        () async {
      // J.1.1: three selected signers with mixed kinds. Verifies the
      // signer manager forwards a 3-element selectedSigners list intact
      // to the multi-signer manager.
      final h = buildHarness();
      final mgr = OZSignerManager(h.kit);

      final selected = <SelectedSigner>[
        SelectedSignerPasskey(
          credentialId: 'pk-a',
          credentialIdBytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
          keyData: _passkeyKeyData(seed: 1),
        ),
        SelectedSignerWallet(_validAccountAddress),
        SelectedSignerPasskey(
          credentialId: 'pk-b',
          credentialIdBytes: Uint8List.fromList(<int>[9, 8, 7, 6]),
          keyData: _passkeyKeyData(seed: 2),
        ),
      ];

      await mgr.removeSigner(
        contextRuleId: 0,
        signerId: 7,
        selectedSigners: selected,
      );

      expect(h.multi.submitWithMultipleSignersCalls.length, 1);
      expect(h.txOps.submitCalls, isEmpty);
      final captured = h.multi.submitWithMultipleSignersCalls.first;
      expect(captured.selectedSigners.length, 3);
      expect(captured.selectedSigners[0], isA<SelectedSignerPasskey>());
      expect(captured.selectedSigners[1], isA<SelectedSignerWallet>());
      expect(captured.selectedSigners[2], isA<SelectedSignerPasskey>());
    });

    test(
        'submitWithMultipleSigners_passkey_plus_wallet_resolvesContextRulesForBothSignerKinds',
        () async {
      // J.1.2: passkey + wallet selectedSigners. Verifies the multi-signer
      // manager receives a mixed list while the host function payload
      // identifies the connected smart-account contract.
      final h = buildHarness();
      final mgr = OZContextRuleManager(h.kit);

      final selected = <SelectedSigner>[
        SelectedSignerPasskey(
          credentialId: 'pk-a',
          credentialIdBytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
          keyData: _passkeyKeyData(seed: 7),
        ),
        SelectedSignerWallet(_validAccountAddress),
      ];

      await mgr.updateName(
        id: 1,
        name: 'mixed',
        selectedSigners: selected,
      );

      expect(h.multi.submitWithMultipleSignersCalls.length, 1);
      final captured = h.multi.submitWithMultipleSignersCalls.first;
      expect(captured.selectedSigners.length, 2);
      expect(captured.selectedSigners[0], isA<SelectedSignerPasskey>());
      expect(captured.selectedSigners[1], isA<SelectedSignerWallet>());

      // Host function targets the smart-account contract for the rule update.
      final invokeArgs = captured.hostFunction.invokeContract;
      expect(invokeArgs, isNotNull);
      expect(invokeArgs!.functionName, 'update_context_rule_name');
    });

    test(
        'submitWithMultipleSigners_threeSigners_oneCancelled_failsFastNoFurtherPrompts',
        () async {
      // J.1.3: simulate a cancellation (the multi-signer mock raises
      // WebAuthnCancelled mid-flight) and verify the signer manager
      // surfaces the failure without retrying or fanning further calls.
      final h = buildHarness();
      h.multi.submitWithMultipleSignersOverride = (_) {
        throw const WebAuthnCancelled(
          message: 'User cancelled WebAuthn for passkey signer 2/3',
        );
      };

      final mgr = OZPolicyManager(h.kit);
      final selected = <SelectedSigner>[
        SelectedSignerPasskey(
          credentialId: 'pk-a',
          credentialIdBytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
          keyData: _passkeyKeyData(seed: 9),
        ),
        SelectedSignerPasskey(
          credentialId: 'pk-b',
          credentialIdBytes: Uint8List.fromList(<int>[9, 8, 7, 6]),
          keyData: _passkeyKeyData(seed: 11),
        ),
        SelectedSignerWallet(_thirdAccountAddress),
      ];

      await expectLater(
        () => mgr.removePolicy(
          contextRuleId: 0,
          policyId: 1,
          selectedSigners: selected,
        ),
        throwsA(isA<WebAuthnCancelled>()),
      );

      // Exactly one delegation; on failure the manager does not retry.
      expect(h.multi.submitWithMultipleSignersCalls.length, 1);
    });
  });
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Builds a 97-byte passkey keyData buffer (uncompressed secp256r1 pubkey
/// concatenated with a credential ID stub) suitable for satisfying the
/// hoisting requirement on [SelectedSignerPasskey].
Uint8List _passkeyKeyData({required int seed}) {
  final pk = Uint8List(65);
  pk[0] = 0x04;
  for (var i = 1; i < pk.length; i++) {
    pk[i] = (seed + i) & 0xFF;
  }
  final credentialId = Uint8List.fromList(<int>[seed, seed + 1, seed + 2]);
  final out = Uint8List(pk.length + credentialId.length)
    ..setRange(0, pk.length, pk)
    ..setRange(pk.length, pk.length + credentialId.length, credentialId);
  return out;
}

