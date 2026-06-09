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

/// Well-formed Ed25519 verifier contract address used in Ed25519 routing tests.
const String _verifierA =
    'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK';

/// Stub context-rule manager whose read paths always throw [SmartAccountWalletNotConnected].
class _NotConnectedRuleManager implements OZContextRuleManagerInterface {
  @override
  Future<List<OZParsedContextRule>> listContextRules() async {
    throw SmartAccountWalletException.notConnected();
  }

  @override
  Future<List<int>> resolveContextRuleIdsForEntry(
    XdrSorobanAuthorizationEntry entry,
    List<OZSmartAccountSigner> signers,
    List<OZParsedContextRule> contextRules,
  ) async {
    throw SmartAccountWalletException.notConnected();
  }

  @override
  Future<List<XdrSCVal>> getAllContextRules({int? maxScanId}) async {
    throw SmartAccountWalletException.notConnected();
  }

  @override
  Future<XdrSCVal> getContextRule(int id) async {
    throw SmartAccountWalletException.notConnected();
  }

  @override
  OZParsedContextRule parseContextRule(XdrSCVal scVal) {
    throw SmartAccountWalletException.notConnected();
  }
}

/// Builds an unconnected fake kit with default config values.
FakePipelineKit _disconnectedKit() => FakePipelineKit();

/// Builds an unconnected kit whose context-rule manager surfaces
/// [SmartAccountWalletNotConnected] on every read, matching what a real
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

OZSelectedSigner _passkeyStub() => const OZSelectedSignerPasskey(
      credentialId: null,
      credentialIdBytes: null,
      keyData: null,
    );

OZSelectedSigner _walletStub({String address = _validAccountAddress}) =>
    OZSelectedSignerWallet(address);

List<OZSelectedSigner> _multiSigners() => <OZSelectedSigner>[
      _passkeyStub(),
      _walletStub(),
    ];

void main() {

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
        throwsA(isA<SmartAccountWalletNotConnected>()),
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
        throwsA(isA<SmartAccountInvalidAddress>()),
      );
    });
  });

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
        throwsA(isA<SmartAccountWalletNotConnected>()),
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
        throwsA(isA<SmartAccountInvalidInput>()),
      );
    });
  });

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
        throwsA(isA<SmartAccountWalletNotConnected>()),
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
        throwsA(isA<SmartAccountInvalidInput>()),
      );
    });
  });

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
        throwsA(isA<SmartAccountWalletNotConnected>()),
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
        throwsA(isA<SmartAccountWalletNotConnected>()),
      );
    });
  });

  group('OZPolicyManager.addPolicy selectedSigners', () {
    test('testAddPolicy_notConnected_withSelectedSigners_throwsNotConnected',
        () async {
      final kit = _disconnectedKit();
      final mgr = OZPolicyManager(kit);
      await expectLater(
        () => mgr.addPolicy(
          contextRuleId: 0,
          policyAddress: _validContractId,
          installParams: OZRawPolicyParams(XdrSCVal.forVoid()),
          selectedSigners: _multiSigners(),
        ),
        throwsA(isA<SmartAccountWalletNotConnected>()),
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
          installParams: OZRawPolicyParams(XdrSCVal.forVoid()),
          selectedSigners: _multiSigners(),
        ),
        throwsA(isA<SmartAccountInvalidAddress>()),
      );
    });
  });

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
        throwsA(isA<SmartAccountWalletNotConnected>()),
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
        throwsA(isA<SmartAccountWalletNotConnected>()),
      );
    });
  });

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
        throwsA(isA<SmartAccountWalletNotConnected>()),
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
        throwsA(isA<SmartAccountInvalidInput>()),
      );
    });
  });

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
        throwsA(isA<SmartAccountWalletNotConnected>()),
      );
    });
  });

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
        throwsA(isA<SmartAccountWalletNotConnected>()),
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
        throwsA(isA<SmartAccountWalletNotConnected>()),
      );
    });

    test('testRemoveSigner_defaultSelectedSigners_isEmptyList', () async {
      final kit = _disconnectedKit();
      final mgr = OZSignerManager(kit);
      await expectLater(
        () => mgr.removeSigner(contextRuleId: 0, signerId: 1),
        throwsA(isA<SmartAccountWalletNotConnected>()),
      );
    });

    test('testAddPolicy_defaultSelectedSigners_isEmptyList', () async {
      final kit = _disconnectedKit();
      final mgr = OZPolicyManager(kit);
      await expectLater(
        () => mgr.addPolicy(
          contextRuleId: 0,
          policyAddress: _validContractId,
          installParams: OZRawPolicyParams(XdrSCVal.forVoid()),
        ),
        throwsA(isA<SmartAccountWalletNotConnected>()),
      );
    });

    test('testRemovePolicy_defaultSelectedSigners_isEmptyList', () async {
      final kit = _disconnectedKit();
      final mgr = OZPolicyManager(kit);
      await expectLater(
        () => mgr.removePolicy(contextRuleId: 0, policyId: 1),
        throwsA(isA<SmartAccountWalletNotConnected>()),
      );
    });

    test('testUpdateName_defaultSelectedSigners_isEmptyList', () async {
      final kit = _disconnectedKit();
      final mgr = OZContextRuleManager(kit);
      await expectLater(
        () => mgr.updateName(id: 0, name: 'Test'),
        throwsA(isA<SmartAccountWalletNotConnected>()),
      );
    });

    test('testUpdateValidUntil_defaultSelectedSigners_isEmptyList', () async {
      final kit = _disconnectedKit();
      final mgr = OZContextRuleManager(kit);
      await expectLater(
        () => mgr.updateValidUntil(id: 0, validUntil: 100),
        throwsA(isA<SmartAccountWalletNotConnected>()),
      );
    });
  });

  group('OZContextRuleManager.addContextRule selectedSigners', () {
    test('testAddContextRule_withSelectedSigners_notConnected', () async {
      final kit = _disconnectedKit();
      final mgr = OZContextRuleManager(kit);
      await expectLater(
        () => mgr.addContextRule(
          contextType: const OZContextRuleTypeDefault(),
          name: 'TestRule',
          signers: const <OZSmartAccountSigner>[],
          selectedSigners: _multiSigners(),
        ),
        throwsA(isA<SmartAccountWalletNotConnected>()),
      );
    });

    test('testAddContextRule_defaultSelectedSigners', () async {
      final kit = _disconnectedKit();
      final mgr = OZContextRuleManager(kit);
      await expectLater(
        () => mgr.addContextRule(
          contextType: const OZContextRuleTypeDefault(),
          name: 'TestRule',
          signers: const <OZSmartAccountSigner>[],
        ),
        throwsA(isA<SmartAccountWalletNotConnected>()),
      );
    });
  });

  group('OZContextRuleManager.removeContextRule selectedSigners', () {
    test('testRemoveContextRule_withSelectedSigners_notConnected', () async {
      final kit = _disconnectedKit();
      final mgr = OZContextRuleManager(kit);
      await expectLater(
        () => mgr.removeContextRule(id: 0, selectedSigners: _multiSigners()),
        throwsA(isA<SmartAccountWalletNotConnected>()),
      );
    });

    test('testRemoveContextRule_defaultSelectedSigners', () async {
      final kit = _disconnectedKit();
      final mgr = OZContextRuleManager(kit);
      await expectLater(
        () => mgr.removeContextRule(id: 0),
        throwsA(isA<SmartAccountWalletNotConnected>()),
      );
    });
  });

  group('forceMethod parameter', () {
    test('testAddDelegated_withForceMethod_notConnected', () async {
      final kit = _disconnectedKit();
      final mgr = OZSignerManager(kit);
      await expectLater(
        () => mgr.addDelegated(
          contextRuleId: 0,
          address: _validAccountAddress,
          forceMethod: OZSubmissionMethod.rpc,
        ),
        throwsA(isA<SmartAccountWalletNotConnected>()),
      );
    });

    test('testRemovePolicy_withForceMethod_notConnected', () async {
      final kit = _disconnectedKit();
      final mgr = OZPolicyManager(kit);
      await expectLater(
        () => mgr.removePolicy(
          contextRuleId: 0,
          policyId: 1,
          forceMethod: OZSubmissionMethod.rpc,
        ),
        throwsA(isA<SmartAccountWalletNotConnected>()),
      );
    });

    test('testUpdateName_defaultForceMethod', () async {
      final kit = _disconnectedKit();
      final mgr = OZContextRuleManager(kit);
      // Calling without forceMethod uses the default null. The not-connected
      // check fires first regardless, confirming the default is reachable.
      await expectLater(
        () => mgr.updateName(id: 0, name: 'Test'),
        throwsA(isA<SmartAccountWalletNotConnected>()),
      );
    });

    test('testAddContextRule_withForceMethod_notConnected', () async {
      final kit = _disconnectedKit();
      final mgr = OZContextRuleManager(kit);
      await expectLater(
        () => mgr.addContextRule(
          contextType: const OZContextRuleTypeDefault(),
          name: 'TestRule',
          signers: const <OZSmartAccountSigner>[],
          forceMethod: OZSubmissionMethod.relayer,
        ),
        throwsA(isA<SmartAccountWalletNotConnected>()),
      );
    });

    test('testRemoveContextRule_withForceMethod_notConnected', () async {
      final kit = _disconnectedKit();
      final mgr = OZContextRuleManager(kit);
      await expectLater(
        () => mgr.removeContextRule(id: 0, forceMethod: OZSubmissionMethod.rpc),
        throwsA(isA<SmartAccountWalletNotConnected>()),
      );
    });

    test('testRemoveSigner_withForceMethod_notConnected', () async {
      final kit = _disconnectedKit();
      final mgr = OZSignerManager(kit);
      await expectLater(
        () => mgr.removeSigner(
          contextRuleId: 0,
          signerId: 1,
          forceMethod: OZSubmissionMethod.rpc,
        ),
        throwsA(isA<SmartAccountWalletNotConnected>()),
      );
    });

    test('testUpdateValidUntil_withForceMethod_notConnected', () async {
      final kit = _disconnectedKit();
      final mgr = OZContextRuleManager(kit);
      await expectLater(
        () => mgr.updateValidUntil(
          id: 0,
          validUntil: 100,
          forceMethod: OZSubmissionMethod.relayer,
        ),
        throwsA(isA<SmartAccountWalletNotConnected>()),
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
          forceMethod: OZSubmissionMethod.rpc,
        ),
        throwsA(isA<SmartAccountWalletNotConnected>()),
      );
    });
  });

  group('multi-signer fanout', () {
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
      // Three selected signers with mixed kinds. Verifies the signer manager
      // forwards a 3-element selectedSigners list intact to the multi-signer manager.
      final h = buildHarness();
      final mgr = OZSignerManager(h.kit);

      final selected = <OZSelectedSigner>[
        OZSelectedSignerPasskey(
          credentialId: 'pk-a',
          credentialIdBytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
          keyData: _passkeyKeyData(seed: 1),
        ),
        OZSelectedSignerWallet(_validAccountAddress),
        OZSelectedSignerPasskey(
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
      expect(captured.selectedSigners[0], isA<OZSelectedSignerPasskey>());
      expect(captured.selectedSigners[1], isA<OZSelectedSignerWallet>());
      expect(captured.selectedSigners[2], isA<OZSelectedSignerPasskey>());
    });

    test(
        'submitWithMultipleSigners_passkey_plus_wallet_resolvesContextRulesForBothSignerKinds',
        () async {
      // Passkey + wallet selectedSigners. Verifies the multi-signer manager
      // receives a mixed list while the host function payload identifies
      // the connected smart-account contract.
      final h = buildHarness();
      final mgr = OZContextRuleManager(h.kit);

      final selected = <OZSelectedSigner>[
        OZSelectedSignerPasskey(
          credentialId: 'pk-a',
          credentialIdBytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
          keyData: _passkeyKeyData(seed: 7),
        ),
        OZSelectedSignerWallet(_validAccountAddress),
      ];

      await mgr.updateName(
        id: 1,
        name: 'mixed',
        selectedSigners: selected,
      );

      expect(h.multi.submitWithMultipleSignersCalls.length, 1);
      final captured = h.multi.submitWithMultipleSignersCalls.first;
      expect(captured.selectedSigners.length, 2);
      expect(captured.selectedSigners[0], isA<OZSelectedSignerPasskey>());
      expect(captured.selectedSigners[1], isA<OZSelectedSignerWallet>());

      // Host function targets the smart-account contract for the rule update.
      final invokeArgs = captured.hostFunction.invokeContract;
      expect(invokeArgs, isNotNull);
      expect(invokeArgs!.functionName, 'update_context_rule_name');
    });

    test(
        'test_addContextRule_ed25519SelectedSigner_routesThroughMultiSignerPipeline',
        () async {
      final h = buildHarness();
      final extManager = OZExternalSignerManager(
        networkPassphrase: 'Test SDF Network ; September 2015',
      );
      final rawSeed = Uint8List.fromList(List<int>.generate(32, (i) => i));
      final publicKey = extManager.addEd25519FromRawKey(
        secretKeyBytes: rawSeed,
        verifierAddress: _verifierA,
      );
      h.kit.setExternalSigners(extManager);

      final mgr = OZContextRuleManager(h.kit);
      final ed25519Signer = OZSelectedSignerEd25519(
        verifierAddress: _verifierA,
        publicKey: publicKey,
      );

      // addContextRule requires at least one signer or one policy; pass the
      // Ed25519 signer as the contract-level signer being added to the rule.
      final contractSigner = OZExternalSigner.ed25519(
        verifierAddress: _verifierA,
        publicKey: publicKey,
      );
      await mgr.addContextRule(
        contextType: const OZContextRuleTypeDefault(),
        name: 'ed25519-rule',
        signers: [contractSigner],
        selectedSigners: [ed25519Signer],
      );

      expect(h.multi.submitWithMultipleSignersCalls.length, equals(1));
      final call = h.multi.submitWithMultipleSignersCalls.single;
      expect(call.selectedSigners.length, equals(1));
      expect(call.selectedSigners.single, isA<OZSelectedSignerEd25519>());
      final forwarded = call.selectedSigners.single as OZSelectedSignerEd25519;
      expect(forwarded.verifierAddress, equals(_verifierA));
      expect(forwarded.publicKey, orderedEquals(publicKey));
    });

    test(
        'test_addPasskey_ed25519SelectedSigner_routesThroughMultiSignerPipeline',
        () async {
      final h = buildHarness();
      final extManager = OZExternalSignerManager(
        networkPassphrase: 'Test SDF Network ; September 2015',
      );
      final rawSeed = Uint8List.fromList(List<int>.generate(32, (i) => i + 1));
      final publicKey = extManager.addEd25519FromRawKey(
        secretKeyBytes: rawSeed,
        verifierAddress: _verifierA,
      );
      h.kit.setExternalSigners(extManager);

      final mgr = OZSignerManager(h.kit);
      final ed25519Signer = OZSelectedSignerEd25519(
        verifierAddress: _verifierA,
        publicKey: publicKey,
      );

      await mgr.addPasskey(
        contextRuleId: 0,
        publicKey: Uint8List(65)..setAll(0, [0x04]),
        credentialId: Uint8List(16),
        selectedSigners: [ed25519Signer],
      );

      expect(h.multi.submitWithMultipleSignersCalls.length, equals(1));
      final call = h.multi.submitWithMultipleSignersCalls.single;
      expect(call.selectedSigners.length, equals(1));
      expect(call.selectedSigners.single, isA<OZSelectedSignerEd25519>());
    });

    test(
        'test_addSimpleThreshold_ed25519SelectedSigner_routesThroughMultiSignerPipeline',
        () async {
      final h = buildHarness();
      final extManager = OZExternalSignerManager(
        networkPassphrase: 'Test SDF Network ; September 2015',
      );
      final rawSeed = Uint8List.fromList(List<int>.generate(32, (i) => i + 2));
      final publicKey = extManager.addEd25519FromRawKey(
        secretKeyBytes: rawSeed,
        verifierAddress: _verifierA,
      );
      h.kit.setExternalSigners(extManager);

      final mgr = OZPolicyManager(h.kit);
      final ed25519Signer = OZSelectedSignerEd25519(
        verifierAddress: _verifierA,
        publicKey: publicKey,
      );

      await mgr.addPolicy(
        contextRuleId: 0,
        policyAddress: _validContractId,
        installParams: OZRawPolicyParams(XdrSCVal.forVoid()),
        selectedSigners: [ed25519Signer],
      );

      expect(h.multi.submitWithMultipleSignersCalls.length, equals(1));
      final call = h.multi.submitWithMultipleSignersCalls.single;
      expect(call.selectedSigners.length, equals(1));
      expect(call.selectedSigners.single, isA<OZSelectedSignerEd25519>());
      final forwarded = call.selectedSigners.single as OZSelectedSignerEd25519;
      expect(forwarded.verifierAddress, equals(_verifierA));
    });

    test(
        'submitWithMultipleSigners_threeSigners_oneCancelled_failsFastNoFurtherPrompts',
        () async {
      // Simulates a cancellation (the multi-signer mock raises WebAuthnCancelled
      // mid-flight) and verifies the signer manager surfaces the failure without
      // retrying or fanning further calls.
      final h = buildHarness();
      h.multi.submitWithMultipleSignersOverride = (_) {
        throw const WebAuthnCancelled(
          message: 'User cancelled WebAuthn for passkey signer 2/3',
        );
      };

      final mgr = OZPolicyManager(h.kit);
      final selected = <OZSelectedSigner>[
        OZSelectedSignerPasskey(
          credentialId: 'pk-a',
          credentialIdBytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
          keyData: _passkeyKeyData(seed: 9),
        ),
        OZSelectedSignerPasskey(
          credentialId: 'pk-b',
          credentialIdBytes: Uint8List.fromList(<int>[9, 8, 7, 6]),
          keyData: _passkeyKeyData(seed: 11),
        ),
        OZSelectedSignerWallet(_thirdAccountAddress),
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

/// Builds a 97-byte passkey keyData buffer (uncompressed secp256r1 pubkey
/// concatenated with a credential ID stub) suitable for satisfying the
/// hoisting requirement on [OZSelectedSignerPasskey].
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

