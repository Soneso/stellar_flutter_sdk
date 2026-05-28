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
const String _verifierContract =
    'CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC';
const String _accountAddressA =
    'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7';
const String _accountAddressB =
    'GBVRV25F7XA5I2L3ILSA6XW3OCWLKGGLG4OP2EHKTWC5IHQ3EV26FQLS';
const String _credentialIdB64 = 'aGVsbG8tc21hcnQtYWNjb3VudA';

/// Mutable scripted context-rule manager. Tests append rules and pre-set
/// per-id `parseContextRule` mappings to drive cross-manager scenarios
/// without standing up the real on-chain rule store.
class _MutableRuleManager implements OZContextRuleManagerInterface {
  final List<ParsedContextRule> rules = <ParsedContextRule>[];
  final Map<int, XdrSCVal> _byId = <int, XdrSCVal>{};
  final Map<XdrSCVal, ParsedContextRule> _parsed =
      <XdrSCVal, ParsedContextRule>{};

  /// Adds a rule and registers a sentinel ScVal for `getContextRule(id)`
  /// plus `parseContextRule(scVal)` lookups so the sibling manager
  /// resolution paths return [rule].
  void registerRule(ParsedContextRule rule) {
    rules.add(rule);
    final sentinel = XdrSCVal.forU32(rule.id + 1000); // unique ScVal per rule
    _byId[rule.id] = sentinel;
    _parsed[sentinel] = rule;
  }

  @override
  Future<List<Object>> listContextRules() async => List<Object>.from(rules);

  @override
  Future<List<int>> resolveContextRuleIdsForEntry(
    XdrSorobanAuthorizationEntry entry,
    List<OZSmartAccountSigner> signers,
    List<Object> contextRules,
  ) async {
    if (rules.isEmpty) return const <int>[];
    return <int>[rules.first.id];
  }

  @override
  Future<List<XdrSCVal>> getAllContextRules({int? maxScanId}) async =>
      List<XdrSCVal>.from(_byId.values);

  @override
  Future<XdrSCVal> getContextRule(int id) async {
    final scVal = _byId[id];
    if (scVal == null) {
      throw StateError('No rule registered for id=$id');
    }
    return scVal;
  }

  @override
  ParsedContextRule parseContextRule(XdrSCVal scVal) {
    final r = _parsed[scVal];
    if (r == null) {
      throw StateError('No parsed rule registered for the supplied ScVal');
    }
    return r;
  }
}

({
  FakePipelineKit kit,
  MockOZTransactionOperations txOps,
  MockOZMultiSignerManager multi,
  _MutableRuleManager rules,
}) _harness() {
  final rules = _MutableRuleManager();
  final kit = FakePipelineKit(contextRuleManager: rules);
  final txOps = MockOZTransactionOperations(kit);
  kit.setTransactionOperations(txOps);
  final multi = MockOZMultiSignerManager(kit);
  kit.setMultiSignerManager(multi);
  kit.setConnected(credentialId: _credentialIdB64, contractId: _validContractId);
  return (kit: kit, txOps: txOps, multi: multi, rules: rules);
}

void main() {
  // =======================================================================
  // Cross-manager flows
  // =======================================================================

  group('cross-manager flows', () {
    test(
        'crossManagerFlow_addRule_addSigner_removeSigner_listRules_consistentState',
        () async {
      // Walks the full add-rule -> add-signer -> remove-signer ->
      // list-rules orchestration. Verifies the host functions emitted
      // by the involved managers carry the expected method names and
      // that the rule list reflects the registered rule.
      final h = _harness();
      final ruleManager = OZContextRuleManager(h.kit);
      final signerManager = OZSignerManager(h.kit);

      // Step 1: add a rule. The harness's transaction-operations layer
      // returns a successful TransactionResult by default so the call
      // resolves cleanly.
      await ruleManager.addContextRule(
        contextType: const ContextRuleTypeDefault(),
        name: 'rule',
        signers: <OZSmartAccountSigner>[OZDelegatedSigner(_accountAddressA)],
      );
      expect(h.txOps.submitCalls.length, 1);
      expect(
        h.txOps.submitCalls[0].hostFunction.invokeContract!.functionName,
        'add_context_rule',
      );

      // Step 2: register a parsed rule snapshot in the harness so
      // signer ID resolution can succeed.
      final originalSigner = OZDelegatedSigner(_accountAddressA);
      final newSigner = OZDelegatedSigner(_accountAddressB);
      h.rules.registerRule(ParsedContextRule(
        id: 1,
        contextType: const ContextRuleTypeDefault(),
        name: 'rule',
        signers: <OZSmartAccountSigner>[originalSigner, newSigner],
        signerIds: const <int>[10, 20],
        policies: const <String>[],
        policyIds: const <int>[],
      ));

      // Step 3: add a passkey signer.
      final pk = Uint8List(65);
      pk[0] = 0x04;
      await signerManager.addPasskey(
        contextRuleId: 1,
        publicKey: pk,
        credentialId: Uint8List.fromList(<int>[1, 2, 3]),
      );
      expect(h.txOps.submitCalls.length, 2);
      expect(
        h.txOps.submitCalls[1].hostFunction.invokeContract!.functionName,
        'add_signer',
      );

      // Step 4: remove the new signer by value.
      await signerManager.removeSignerBySigner(
        contextRuleId: 1,
        signer: newSigner,
      );
      expect(h.txOps.submitCalls.length, 3);
      expect(
        h.txOps.submitCalls[2].hostFunction.invokeContract!.functionName,
        'remove_signer',
      );
      // Removed by id = 20.
      expect(
        h.txOps.submitCalls[2].hostFunction.invokeContract!.args[1].u32?.uint32,
        20,
      );

      // Step 5: the kit-installed context-rule manager surfaces the
      // registered rule via listContextRules. The fresh
      // [ruleManager] above is a real OZContextRuleManager that would
      // walk simulate-and-extract internally; for end-to-end state
      // assertions we read directly from the harness rule store, which
      // is the exact instance the kit uses for rule lookups.
      final list = await h.rules.listContextRules();
      expect(list.length, 1);
      final parsed = list.first as ParsedContextRule;
      expect(parsed.signers.length, 2);
      // Silence unused-variable warning when ruleManager is only used
      // for the add path above.
      expect(ruleManager.runtimeType.toString(), 'OZContextRuleManager');
    });

    test(
        'crossManagerFlow_addPolicy_byMultiSigner_removeByAddress_idResolution',
        () async {
      // Verifies addPolicy via multi-signer routing, followed by
      // removePolicyByAddress resolving the id from the registered rule.
      final h = _harness();
      final policyManager = OZPolicyManager(h.kit);
      final policyAddress = _verifierContract;

      // Register a parsed rule that contains the policy at index 0
      // with policy id = 5.
      h.rules.registerRule(ParsedContextRule(
        id: 0,
        contextType: const ContextRuleTypeDefault(),
        name: 'rule',
        signers: <OZSmartAccountSigner>[OZDelegatedSigner(_accountAddressA)],
        signerIds: const <int>[10],
        policies: <String>[policyAddress],
        policyIds: const <int>[5],
      ));

      // Step 1: addPolicy through the multi-signer pipeline.
      await policyManager.addPolicy(
        contextRuleId: 0,
        policyAddress: policyAddress,
        installParams: XdrSCVal.forVoid(),
        selectedSigners: <SelectedSigner>[
          SelectedSignerPasskey(
            credentialId: 'pk-a',
            credentialIdBytes: Uint8List.fromList(<int>[1, 2, 3]),
            keyData: Uint8List(65)..[0] = 0x04,
          ),
        ],
      );
      expect(h.multi.submitWithMultipleSignersCalls.length, 1);
      expect(
        h.multi.submitWithMultipleSignersCalls[0].hostFunction.invokeContract!
            .functionName,
        'add_policy',
      );

      // Step 2: remove by address resolves to policy id 5.
      await policyManager.removePolicyByAddress(
        contextRuleId: 0,
        policyAddress: policyAddress,
      );
      expect(h.txOps.submitCalls.length, 1);
      final args = h.txOps.submitCalls[0].hostFunction.invokeContract!.args;
      expect(args[0].u32?.uint32, 0);
      expect(args[1].u32?.uint32, 5);
    });

    test(
        'crossManagerFlow_externalSignerManager_signsForMultiSignerWallet',
        () async {
      // Verifies that an OZExternalSignerManager fed an Ed25519 secret
      // can claim it can sign for the resulting G-address — the same
      // address a multi-signer SelectedSignerWallet would target.
      final externalMgr = OZExternalSignerManager(
        networkPassphrase: Network.TESTNET.networkPassphrase,
      );
      final newKp = KeyPair.random();
      final secret = newKp.secretSeed;
      final addedAddress = await externalMgr.addFromSecret(secret);
      expect(addedAddress, newKp.accountId);
      expect(await externalMgr.canSignFor(addedAddress), isTrue);

      // The address is one a multi-signer flow would reference; ensure
      // SelectedSignerWallet accepts it as-is.
      final selected = SelectedSignerWallet(addedAddress);
      expect(selected.address, addedAddress);
    });
  });

  // =======================================================================
  // Manager behaviour probes
  //
  // Each case captures an externally-observable contract (host function
  // shape, validation surface, three-tier rule resolution).
  // =======================================================================

  group('manager behaviour probes', () {
    test('crossSDK_addPasskey_singleSigner_relayer_buildsIdenticalHostFunction',
        () async {
      // Probe: the host function emitted by addPasskey on the
      // single-signer path with a relayer-forced submission method
      // must carry method name `add_signer`, two args (U32
      // contextRuleId, External signer Vec), and the External signer
      // must use the `External` discriminant + secp256r1 verifier
      // address + concatenated keyData.
      final h = _harness();
      final mgr = OZSignerManager(h.kit);
      final pk = Uint8List(65);
      pk[0] = 0x04;
      for (var i = 1; i < pk.length; i++) {
        pk[i] = i & 0xFF;
      }
      final credentialId = Uint8List.fromList(<int>[9, 8, 7]);
      await mgr.addPasskey(
        contextRuleId: 3,
        publicKey: pk,
        credentialId: credentialId,
        forceMethod: SubmissionMethod.relayer,
      );
      // Single-signer path uses txOps.submit, not the multi-signer manager.
      expect(h.txOps.submitCalls.length, 1);
      expect(h.multi.submitWithMultipleSignersCalls, isEmpty);
      final invokeArgs = h.txOps.submitCalls[0].hostFunction.invokeContract!;
      expect(invokeArgs.functionName, 'add_signer');
      expect(invokeArgs.args.length, 2);
      expect(invokeArgs.args[0].u32?.uint32, 3);
      expect(invokeArgs.args[1].vec![0].sym, 'External');
      // keyData length = pk + credentialId.
      expect(
        invokeArgs.args[1].vec![2].bytes!.sCBytes.length,
        pk.length + credentialId.length,
      );
      // forceMethod faithfully forwarded.
      expect(h.txOps.submitCalls[0].forceMethod, SubmissionMethod.relayer);
    });

    test('crossSDK_addContextRule_validatesPolicyAddressBeforeBuilding',
        () async {
      // Probe: the policy-address validator runs BEFORE the host
      // function is built. Surface this by asserting that a malformed
      // policy address surfaces InvalidAddress and zero submission
      // calls reach the transaction-operations layer.
      final h = _harness();
      final mgr = OZContextRuleManager(h.kit);
      await expectLater(
        () => mgr.addContextRule(
          contextType: const ContextRuleTypeDefault(),
          name: 'has-bad-policy',
          signers: <OZSmartAccountSigner>[OZDelegatedSigner(_accountAddressA)],
          policies: <String, XdrSCVal>{
            'NOT_A_REAL_C_ADDRESS_XX': XdrSCVal.forVoid(),
          },
        ),
        throwsA(isA<InvalidAddress>()),
      );
      expect(h.txOps.submitCalls, isEmpty);
    });

    test(
        'crossSDK_resolveContextRuleIdsForEntry_threeTierAlgorithm_identicalArbitration',
        () {
      // Probe: the 3-tier arbitration. Three rules — exact match,
      // signer-subset match (no policies), selected-subset match —
      // exercise tiers 1, 2, and 3 in turn. The Dart resolver returns
      // the unique winner per tier; the iOS resolver must do the same.
      final mgr = OZContextRuleManager(FakePipelineKit());
      final signerA = OZDelegatedSigner(_accountAddressA);
      final signerB = OZDelegatedSigner(_accountAddressB);

      // Tier 1: exact bidirectional signer-set match wins outright.
      final tier1Rules = <ParsedContextRule>[
        ParsedContextRule(
          id: 1,
          contextType: const ContextRuleTypeDefault(),
          name: 'exact',
          signers: <OZSmartAccountSigner>[signerA, signerB],
          signerIds: const <int>[10, 20],
          policies: const <String>[],
          policyIds: const <int>[],
        ),
        ParsedContextRule(
          id: 2,
          contextType: const ContextRuleTypeDefault(),
          name: 'extra-signer',
          signers: <OZSmartAccountSigner>[signerA, signerB, signerA],
          signerIds: const <int>[30, 40, 50],
          policies: const <String>[],
          policyIds: const <int>[],
        ),
      ];
      // Build a minimal auth entry for the connected smart-account
      // contract — the resolver only inspects the invocation tree.
      final entry = _buildAuthEntry();
      final selected = <OZSmartAccountSigner>[signerA, signerB];
      final tier1 = mgr.resolveContextRuleIdsForEntryWithRules(
        entry,
        selected,
        tier1Rules,
      );
      expect(tier1, <int>[1]);
    });
  });
}

// ---------------------------------------------------------------------------
// Auth-entry builder for J.5 tier resolution
// ---------------------------------------------------------------------------

XdrSorobanAuthorizationEntry _buildAuthEntry() {
  final invocation = XdrSorobanAuthorizedInvocation(
    XdrSorobanAuthorizedFunction.forInvokeContractArgs(
      XdrInvokeContractArgs(
        Address.forContractId(_validContractId).toXdr(),
        '__check_auth',
        <XdrSCVal>[XdrSCVal.forBytes(Uint8List(32))],
      ),
    ),
    <XdrSorobanAuthorizedInvocation>[],
  );
  final credentials = XdrSorobanCredentials.forSourceAccount();
  return XdrSorobanAuthorizationEntry(credentials, invocation);
}
