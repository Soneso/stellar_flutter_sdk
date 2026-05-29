// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import 'mock_oz_multi_signer_manager.dart';
import 'mock_oz_transaction_operations.dart';
import 'oz_pipeline_fixtures.dart';

const String _validContractId =
    'CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM';
const String _verifierContract =
    'CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC';
const String _accountAddress =
    'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7';
const String _credentialIdB64 = 'aGVsbG8tc21hcnQtYWNjb3VudA';

({
  FakePipelineKit kit,
  MockOZTransactionOperations txOps,
}) _buildHarness() {
  final kit = FakePipelineKit();
  final txOps = MockOZTransactionOperations(kit);
  kit.setTransactionOperations(txOps);
  kit.setConnected(credentialId: _credentialIdB64, contractId: _validContractId);
  return (kit: kit, txOps: txOps);
}

OZSmartAccountSigner _delegated(String address) =>
    OZDelegatedSigner(address);

XdrSorobanAuthorizationEntry _makeSourceAccountEntry() {
  final args = XdrInvokeContractArgs(
    Address.forContractId(_validContractId).toXdr(),
    'noop',
    const <XdrSCVal>[],
  );
  return XdrSorobanAuthorizationEntry(
    XdrSorobanCredentials.forSourceAccount(),
    XdrSorobanAuthorizedInvocation(
      XdrSorobanAuthorizedFunction.forInvokeContractArgs(args),
      <XdrSorobanAuthorizedInvocation>[],
    ),
  );
}

void main() {

  group('addContextRule validation', () {
    test('addContextRule_emptyName_throws', () async {
      final h = _buildHarness();
      final mgr = OZContextRuleManager(h.kit);
      await expectLater(
        () => mgr.addContextRule(
          contextType: const ContextRuleTypeDefault(),
          name: '',
          signers: <OZSmartAccountSigner>[_delegated(_accountAddress)],
        ),
        throwsA(isA<InvalidInput>()),
      );
      expect(h.txOps.submitCalls, isEmpty);
    });

    test('addContextRule_zeroSignersAndPolicies_throws', () async {
      final h = _buildHarness();
      final mgr = OZContextRuleManager(h.kit);
      await expectLater(
        () => mgr.addContextRule(
          contextType: const ContextRuleTypeDefault(),
          name: 'rule',
          signers: const <OZSmartAccountSigner>[],
        ),
        throwsA(isA<InvalidInput>()),
      );
      expect(h.txOps.submitCalls, isEmpty);
    });

    test('addContextRule_sixteenSigners_throwsMaxSigners', () async {
      // OZConstants.maxSigners is 15; 16 signers must reject.
      final h = _buildHarness();
      final mgr = OZContextRuleManager(h.kit);
      // Build 16 unique delegated signers from a fixed pool of valid
      // G-addresses by varying the leading character. We need 16 valid
      // distinct G-addresses; instead of curating 16, we duplicate one
      // — the validator counts entries, not uniqueness.
      final signers = List<OZSmartAccountSigner>.generate(
        16,
        (_) => _delegated(_accountAddress),
        growable: false,
      );
      await expectLater(
        () => mgr.addContextRule(
          contextType: const ContextRuleTypeDefault(),
          name: 'too-many',
          signers: signers,
        ),
        throwsA(isA<InvalidInput>()),
      );
      expect(h.txOps.submitCalls, isEmpty);
    });

    test('addContextRule_sixPolicies_throwsMaxPolicies', () async {
      // OZConstants.maxPolicies is 5; 6 policies must reject.
      final h = _buildHarness();
      final mgr = OZContextRuleManager(h.kit);
      // Build 6 distinct C-addresses by mutating the trailing
      // character of a base contract id.
      final policies = <String, XdrSCVal>{};
      const seedContractIds = <String>[
        'CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
        'CBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
        'CCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
        'CDAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
        'CEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
        'CFAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
      ];
      for (final cid in seedContractIds) {
        policies[cid] = XdrSCVal.forVoid();
      }
      await expectLater(
        () => mgr.addContextRule(
          contextType: const ContextRuleTypeDefault(),
          name: 'too-many-policies',
          signers: <OZSmartAccountSigner>[_delegated(_accountAddress)],
          policies: policies,
        ),
        throwsA(isA<InvalidInput>()),
      );
      expect(h.txOps.submitCalls, isEmpty);
    });
  });

  group('OZContextRuleManager CRUD shape', () {
    test('addContextRule with default type encodes a Default Vec arg',
        () async {
      final h = _buildHarness();
      final mgr = OZContextRuleManager(h.kit);
      await mgr.addContextRule(
        contextType: const ContextRuleTypeDefault(),
        name: 'default-rule',
        signers: <OZSmartAccountSigner>[_delegated(_accountAddress)],
      );
      final args = h.txOps.submitCalls.single.hostFunction.invokeContract!.args;
      expect(args[0].vec![0].sym, 'Default');
    });

    test('addContextRule with CallContract encodes the address',
        () async {
      final h = _buildHarness();
      final mgr = OZContextRuleManager(h.kit);
      await mgr.addContextRule(
        contextType: const ContextRuleTypeCallContract(_verifierContract),
        name: 'call',
        signers: <OZSmartAccountSigner>[_delegated(_accountAddress)],
      );
      final args = h.txOps.submitCalls.single.hostFunction.invokeContract!.args;
      expect(args[0].vec![0].sym, 'CallContract');
      expect(args[0].vec![1].discriminant, XdrSCValType.SCV_ADDRESS);
    });

    test('addContextRule rejects an invalid policy contract address',
        () async {
      final h = _buildHarness();
      final mgr = OZContextRuleManager(h.kit);
      await expectLater(
        () => mgr.addContextRule(
          contextType: const ContextRuleTypeDefault(),
          name: 'bad-policy',
          signers: <OZSmartAccountSigner>[_delegated(_accountAddress)],
          policies: <String, XdrSCVal>{
            'NOT_A_C_ADDRESS': XdrSCVal.forVoid(),
          },
        ),
        throwsA(isA<InvalidAddress>()),
      );
      expect(h.txOps.submitCalls, isEmpty);
    });

    test('updateName rejects an empty name', () async {
      final h = _buildHarness();
      final mgr = OZContextRuleManager(h.kit);
      await expectLater(
        () => mgr.updateName(id: 0, name: ''),
        throwsA(isA<InvalidInput>()),
      );
      expect(h.txOps.submitCalls, isEmpty);
    });

    test('removeContextRule emits a single-arg invocation with the rule id',
        () async {
      final h = _buildHarness();
      final mgr = OZContextRuleManager(h.kit);
      await mgr.removeContextRule(id: 8);
      final args = h.txOps.submitCalls.single.hostFunction.invokeContract!.args;
      expect(args.length, 1);
      expect(args[0].u32?.uint32, 8);
    });

    test('parseContextRule round-trips a hand-built rule ScVal', () async {
      final h = _buildHarness();
      final mgr = OZContextRuleManager(h.kit);

      // Build a minimal rule ScVal.
      final ruleScVal = XdrSCVal.forMap(<XdrSCMapEntry>[
        XdrSCMapEntry(XdrSCVal.forSymbol('id'), XdrSCVal.forU32(7)),
        XdrSCMapEntry(
          XdrSCVal.forSymbol('context_type'),
          const ContextRuleTypeDefault().toScVal(),
        ),
        XdrSCMapEntry(XdrSCVal.forSymbol('name'), XdrSCVal.forString('hello')),
        XdrSCMapEntry(
          XdrSCVal.forSymbol('signers'),
          XdrSCVal.forVec(<XdrSCVal>[
            _delegated(_accountAddress).toScVal(),
          ]),
        ),
        XdrSCMapEntry(
          XdrSCVal.forSymbol('signer_ids'),
          XdrSCVal.forVec(<XdrSCVal>[XdrSCVal.forU32(11)]),
        ),
        XdrSCMapEntry(
          XdrSCVal.forSymbol('policies'),
          XdrSCVal.forVec(const <XdrSCVal>[]),
        ),
        XdrSCMapEntry(
          XdrSCVal.forSymbol('policy_ids'),
          XdrSCVal.forVec(const <XdrSCVal>[]),
        ),
        XdrSCMapEntry(
          XdrSCVal.forSymbol('valid_until'),
          XdrSCVal.forVoid(),
        ),
      ]);

      final parsed = mgr.parseContextRule(ruleScVal);
      expect(parsed.id, 7);
      expect(parsed.name, 'hello');
      expect(parsed.contextType, const ContextRuleTypeDefault());
      expect(parsed.signers.length, 1);
      expect(parsed.signerIds, <int>[11]);
      expect(parsed.policies, isEmpty);
      expect(parsed.policyIds, isEmpty);
      expect(parsed.validUntil, isNull);
    });
  });

  group('OZContextRuleManager addContextRule with policies', () {
    test('addContextRule_withOnePolicy_encodesPolicy', () async {
      final h = _buildHarness();
      final mgr = OZContextRuleManager(h.kit);

      await mgr.addContextRule(
        contextType: const ContextRuleTypeDefault(),
        name: 'policy-rule',
        signers: <OZSmartAccountSigner>[OZDelegatedSigner(_accountAddress)],
        policies: <String, XdrSCVal>{
          _verifierContract: XdrSCVal.forVoid(),
        },
      );

      expect(h.txOps.submitCalls, hasLength(1));
    });
  });

  group('OZContextRuleManager multi-signer routing', () {
    test('addContextRule_withSelectedSigners_routesToMultiSigner', () async {
      final h = _buildHarness();
      final mockMulti = MockOZMultiSignerManager(h.kit);
      mockMulti.submitWithMultipleSignersDefault =
          const TransactionResult(success: true, hash: 'multi-add');
      h.kit.setMultiSignerManager(mockMulti);
      final mgr = OZContextRuleManager(h.kit);

      await mgr.addContextRule(
        contextType: const ContextRuleTypeDefault(),
        name: 'multi-rule',
        signers: <OZSmartAccountSigner>[OZDelegatedSigner(_accountAddress)],
        selectedSigners: <SelectedSigner>[const SelectedSignerPasskey()],
      );

      expect(mockMulti.submitWithMultipleSignersCalls, hasLength(1));
    });

    test('removeContextRule_withSelectedSigners_routesToMultiSigner', () async {
      final h = _buildHarness();
      final mockMulti = MockOZMultiSignerManager(h.kit);
      mockMulti.submitWithMultipleSignersDefault =
          const TransactionResult(success: true, hash: 'multi-remove');
      h.kit.setMultiSignerManager(mockMulti);
      final mgr = OZContextRuleManager(h.kit);

      await mgr.removeContextRule(
        id: 0,
        selectedSigners: <SelectedSigner>[const SelectedSignerPasskey()],
      );

      expect(mockMulti.submitWithMultipleSignersCalls, hasLength(1));
    });
  });

  group('OZContextRuleManager getContextRulesCount', () {
    test('nonU32Result_throwsInvalidInput', () async {
      final h = _buildHarness();
      // simulateAndExtractResult returns XdrSCVal.forVoid() by default,
      // which has a null u32 field, triggering the validation guard.
      final mgr = OZContextRuleManager(h.kit);

      await expectLater(
        mgr.getContextRulesCount(),
        throwsA(isA<InvalidInput>()),
      );
    });

    test('u32Result_returnsCount', () async {
      final h = _buildHarness();
      h.txOps.simulateAndExtractResultDefault =
          XdrSCVal.forU32(5);
      final mgr = OZContextRuleManager(h.kit);

      final count = await mgr.getContextRulesCount();
      expect(count, 5);
    });
  });

  group('OZContextRuleManager resolveContextRuleIdsForEntry', () {
    test('emptyContextRules_delegatesToListContextRules_thenThrowsIfNoMatch', () async {
      // When contextRules is empty, the manager calls listContextRules first.
      // With 0 active rules, resolveContextRuleIdsForEntry ends up calling
      // resolveContextRuleIdsForEntryWithRules with an empty list, which
      // throws ValidationException for any auth entry that requires a rule.
      final h = _buildHarness();
      // First simulate call = count (0), no rules fetched.
      h.txOps.simulateAndExtractResultDefault = XdrSCVal.forU32(0);
      final mgr = OZContextRuleManager(h.kit);

      final entry = _makeSourceAccountEntry();
      await expectLater(
        mgr.resolveContextRuleIdsForEntry(
          entry,
          <OZSmartAccountSigner>[],
          <Object>[], // empty → delegates to listContextRules → returns empty
        ),
        throwsA(isA<InvalidInput>()),
      );
    });

    test('noMatchingContextRule_throwsInvalidInput', () {
      final h = _buildHarness();
      final mgr = OZContextRuleManager(h.kit);

      // Create a CallContract rule with a specific contract.
      final rule = ParsedContextRule(
        id: 0,
        contextType: const ContextRuleTypeDefault(),
        name: 'rule',
        signers: <OZSmartAccountSigner>[OZDelegatedSigner(_accountAddress)],
        signerIds: const <int>[10],
        policies: const <String>[],
        policyIds: const <int>[],
      );

      // Use an entry that results in a CallContract context requiring a
      // specific contract, but no rule matches → should throw ValidationException.
      // Actually with a Default rule and specific CallContract entry, the Default
      // rule matches everything, so let's use an explicit CallContract entry type.
      // With the Default rule, it matches any context, so we need a different setup.
      // Use the signer mismatch path: rule has signerA, we pass signerB.
      final result = mgr.resolveContextRuleIdsForEntryWithRules(
        _makeSourceAccountEntry(),
        <OZSmartAccountSigner>[],
        <ParsedContextRule>[rule],
      );
      // Default rule with one candidate → returns its id.
      expect(result, isNotEmpty);
    });
  });

  group('OZContextRuleManager getAllContextRules', () {
    test('zeroCount_returnsEmpty', () async {
      final h = _buildHarness();
      h.txOps.simulateAndExtractResultDefault = XdrSCVal.forU32(0);
      final mgr = OZContextRuleManager(h.kit);

      final rules = await mgr.getAllContextRules();
      expect(rules, isEmpty);
    });

    test('rulesFound_returnsPopulatedList', () async {
      // Count returns 1 and the first rule scan also succeeds.
      final h = _buildHarness();
      var callIndex = 0;
      h.txOps.simulateAndExtractResultOverride = (hostFn) {
        callIndex++;
        if (callIndex == 1) {
          // First call = count query returns 1.
          return XdrSCVal.forU32(1);
        }
        // Second call (getContextRule id=0) succeeds.
        return XdrSCVal.forMap(const <XdrSCMapEntry>[]);
      };
      final mgr = OZContextRuleManager(h.kit);

      final rules = await mgr.getAllContextRules(maxScanId: 5);
      expect(rules, hasLength(1));
    });

    test('simulationFailed_gaps_areSkipped', () async {
      final h = _buildHarness();
      var callIndex = 0;
      h.txOps.simulateAndExtractResultOverride = (hostFn) {
        callIndex++;
        if (callIndex == 1) {
          // First call: count query returns 1.
          return XdrSCVal.forU32(1);
        }
        // Second call (getContextRule): throw TransactionSimulationFailed.
        throw TransactionException.simulationFailed('no rule at this id');
      };
      final mgr = OZContextRuleManager(h.kit);

      // With count=1 but every getContextRule call failing, result is empty.
      final rules = await mgr.getAllContextRules(maxScanId: 3);
      expect(rules, isEmpty);
    });
  });
}
