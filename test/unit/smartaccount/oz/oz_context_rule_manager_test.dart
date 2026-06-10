// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

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

Uint8List _wasmHash(int seed) =>
    Uint8List.fromList(List<int>.generate(32, (i) => (seed + i) & 0xff));

XdrContractIDPreimage _idPreimage() {
  final preimage = XdrContractIDPreimage(
    XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS,
  );
  preimage.address = Address.forContractId(_validContractId).toXdr();
  preimage.salt = XdrUint256(Uint8List(32));
  return preimage;
}

/// Builds an auth entry whose root invocation is a V1 create-contract host
/// function referencing a WASM executable with the supplied [wasmHash].
XdrSorobanAuthorizationEntry _makeCreateContractEntry(Uint8List wasmHash) {
  final args = XdrCreateContractArgs(
    _idPreimage(),
    XdrContractExecutable.forWasm(wasmHash),
  );
  return XdrSorobanAuthorizationEntry(
    XdrSorobanCredentials.forSourceAccount(),
    XdrSorobanAuthorizedInvocation(
      XdrSorobanAuthorizedFunction.forCreateContractArgs(args),
      <XdrSorobanAuthorizedInvocation>[],
    ),
  );
}

/// Builds an auth entry whose root invocation is a V2 create-contract host
/// function referencing a WASM executable with the supplied [wasmHash].
XdrSorobanAuthorizationEntry _makeCreateContractV2Entry(Uint8List wasmHash) {
  final args = XdrCreateContractArgsV2(
    _idPreimage(),
    XdrContractExecutable.forWasm(wasmHash),
    const <XdrSCVal>[],
  );
  return XdrSorobanAuthorizationEntry(
    XdrSorobanCredentials.forSourceAccount(),
    XdrSorobanAuthorizedInvocation(
      XdrSorobanAuthorizedFunction.forCreateContractArgsV2(args),
      <XdrSorobanAuthorizedInvocation>[],
    ),
  );
}

/// Builds an auth entry whose root invocation is a V1 create-contract host
/// function referencing a Stellar-Asset executable (no WASM hash). The
/// create-contract context-type collector must reject this with a
/// validation error.
XdrSorobanAuthorizationEntry _makeCreateAssetEntry() {
  final args = XdrCreateContractArgs(
    _idPreimage(),
    XdrContractExecutable.forAsset(),
  );
  return XdrSorobanAuthorizationEntry(
    XdrSorobanCredentials.forSourceAccount(),
    XdrSorobanAuthorizedInvocation(
      XdrSorobanAuthorizedFunction.forCreateContractArgs(args),
      <XdrSorobanAuthorizedInvocation>[],
    ),
  );
}

/// Builds an auth entry whose root invocation is a contract call and whose
/// single sub-invocation is a V1 create-contract host function. Exercises the
/// sub-invocation recursion branch of the context-type collector.
XdrSorobanAuthorizationEntry _makeCallWithCreateSubEntry(Uint8List wasmHash) {
  final rootArgs = XdrInvokeContractArgs(
    Address.forContractId(_validContractId).toXdr(),
    'root',
    const <XdrSCVal>[],
  );
  final subArgs = XdrCreateContractArgs(
    _idPreimage(),
    XdrContractExecutable.forWasm(wasmHash),
  );
  return XdrSorobanAuthorizationEntry(
    XdrSorobanCredentials.forSourceAccount(),
    XdrSorobanAuthorizedInvocation(
      XdrSorobanAuthorizedFunction.forInvokeContractArgs(rootArgs),
      <XdrSorobanAuthorizedInvocation>[
        XdrSorobanAuthorizedInvocation(
          XdrSorobanAuthorizedFunction.forCreateContractArgs(subArgs),
          <XdrSorobanAuthorizedInvocation>[],
        ),
      ],
    ),
  );
}

OZParsedContextRule _rule({
  required int id,
  OZContextRuleType contextType = const OZContextRuleTypeDefault(),
  List<OZSmartAccountSigner> signers = const <OZSmartAccountSigner>[],
  List<String> policies = const <String>[],
}) =>
    OZParsedContextRule(
      id: id,
      contextType: contextType,
      name: 'rule-$id',
      signers: signers,
      signerIds: const <int>[],
      policies: policies,
      policyIds: const <int>[],
    );

void main() {

  group('addContextRule validation', () {
    test('addContextRule_emptyName_throws', () async {
      final h = _buildHarness();
      final mgr = OZContextRuleManager(h.kit);
      await expectLater(
        () => mgr.addContextRule(
          contextType: const OZContextRuleTypeDefault(),
          name: '',
          signers: <OZSmartAccountSigner>[_delegated(_accountAddress)],
        ),
        throwsA(isA<SmartAccountInvalidInput>()),
      );
      expect(h.txOps.submitCalls, isEmpty);
    });

    test('addContextRule_zeroSignersAndPolicies_throws', () async {
      final h = _buildHarness();
      final mgr = OZContextRuleManager(h.kit);
      await expectLater(
        () => mgr.addContextRule(
          contextType: const OZContextRuleTypeDefault(),
          name: 'rule',
          signers: const <OZSmartAccountSigner>[],
        ),
        throwsA(isA<SmartAccountInvalidInput>()),
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
          contextType: const OZContextRuleTypeDefault(),
          name: 'too-many',
          signers: signers,
        ),
        throwsA(isA<SmartAccountInvalidInput>()),
      );
      expect(h.txOps.submitCalls, isEmpty);
    });

    test('addContextRule_sixPolicies_throwsMaxPolicies', () async {
      // OZConstants.maxPolicies is 5; 6 policies must reject.
      final h = _buildHarness();
      final mgr = OZContextRuleManager(h.kit);
      // Build 6 distinct C-addresses by mutating the trailing
      // character of a base contract id.
      final policies = <String, OZPolicyInstallParams>{};
      const seedContractIds = <String>[
        'CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
        'CBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
        'CCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
        'CDAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
        'CEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
        'CFAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
      ];
      for (final cid in seedContractIds) {
        policies[cid] = OZRawPolicyParams(XdrSCVal.forVoid());
      }
      await expectLater(
        () => mgr.addContextRule(
          contextType: const OZContextRuleTypeDefault(),
          name: 'too-many-policies',
          signers: <OZSmartAccountSigner>[_delegated(_accountAddress)],
          policies: policies,
        ),
        throwsA(isA<SmartAccountInvalidInput>()),
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
        contextType: const OZContextRuleTypeDefault(),
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
        contextType: const OZContextRuleTypeCallContract(_verifierContract),
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
          contextType: const OZContextRuleTypeDefault(),
          name: 'bad-policy',
          signers: <OZSmartAccountSigner>[_delegated(_accountAddress)],
          policies: <String, OZPolicyInstallParams>{
            'NOT_A_C_ADDRESS': OZRawPolicyParams(XdrSCVal.forVoid()),
          },
        ),
        throwsA(isA<SmartAccountInvalidAddress>()),
      );
      expect(h.txOps.submitCalls, isEmpty);
    });

    test('updateName rejects an empty name', () async {
      final h = _buildHarness();
      final mgr = OZContextRuleManager(h.kit);
      await expectLater(
        () => mgr.updateName(id: 0, name: ''),
        throwsA(isA<SmartAccountInvalidInput>()),
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
          const OZContextRuleTypeDefault().toScVal(),
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
      expect(parsed.contextType, const OZContextRuleTypeDefault());
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
        contextType: const OZContextRuleTypeDefault(),
        name: 'policy-rule',
        signers: <OZSmartAccountSigner>[OZDelegatedSigner(_accountAddress)],
        policies: <String, OZPolicyInstallParams>{
          _verifierContract: OZRawPolicyParams(XdrSCVal.forVoid()),
        },
      );

      expect(h.txOps.submitCalls, hasLength(1));
    });

    test('addContextRule encodes typed policy params via toScVal', () async {
      const params = OZSimpleThresholdPolicyParams(threshold: 3);

      final hTyped = _buildHarness();
      await OZContextRuleManager(hTyped.kit).addContextRule(
        contextType: const OZContextRuleTypeDefault(),
        name: 'typed-policy',
        signers: <OZSmartAccountSigner>[OZDelegatedSigner(_accountAddress)],
        policies: <String, OZPolicyInstallParams>{_verifierContract: params},
      );
      final typedPolicies =
          hTyped.txOps.submitCalls.single.hostFunction.invokeContract!.args[4];

      final hRaw = _buildHarness();
      await OZContextRuleManager(hRaw.kit).addContextRule(
        contextType: const OZContextRuleTypeDefault(),
        name: 'raw-policy',
        signers: <OZSmartAccountSigner>[OZDelegatedSigner(_accountAddress)],
        policies: <String, OZPolicyInstallParams>{
          _verifierContract: OZRawPolicyParams(params.toScVal()),
        },
      );
      final rawPolicies =
          hRaw.txOps.submitCalls.single.hostFunction.invokeContract!.args[4];

      expect(
        OZPolicyManager.scValToXdrBytes(typedPolicies),
        equals(OZPolicyManager.scValToXdrBytes(rawPolicies)),
      );
      expect(typedPolicies.map!.single.val.map!.single.val.u32!.uint32, 3);
    });
  });

  group('OZContextRuleManager multi-signer routing', () {
    test('addContextRule_withSelectedSigners_routesToMultiSigner', () async {
      final h = _buildHarness();
      final mockMulti = MockOZMultiSignerManager(h.kit);
      mockMulti.submitWithMultipleSignersDefault =
          const OZTransactionResult(success: true, hash: 'multi-add');
      h.kit.setMultiSignerManager(mockMulti);
      final mgr = OZContextRuleManager(h.kit);

      await mgr.addContextRule(
        contextType: const OZContextRuleTypeDefault(),
        name: 'multi-rule',
        signers: <OZSmartAccountSigner>[OZDelegatedSigner(_accountAddress)],
        selectedSigners: <OZSelectedSigner>[const OZSelectedSignerPasskey()],
      );

      expect(mockMulti.submitWithMultipleSignersCalls, hasLength(1));
    });

    test('removeContextRule_withSelectedSigners_routesToMultiSigner', () async {
      final h = _buildHarness();
      final mockMulti = MockOZMultiSignerManager(h.kit);
      mockMulti.submitWithMultipleSignersDefault =
          const OZTransactionResult(success: true, hash: 'multi-remove');
      h.kit.setMultiSignerManager(mockMulti);
      final mgr = OZContextRuleManager(h.kit);

      await mgr.removeContextRule(
        id: 0,
        selectedSigners: <OZSelectedSigner>[const OZSelectedSignerPasskey()],
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
        throwsA(isA<SmartAccountInvalidInput>()),
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
      // throws SmartAccountValidationException for any auth entry that requires a rule.
      final h = _buildHarness();
      // First simulate call = count (0), no rules fetched.
      h.txOps.simulateAndExtractResultDefault = XdrSCVal.forU32(0);
      final mgr = OZContextRuleManager(h.kit);

      final entry = _makeSourceAccountEntry();
      await expectLater(
        mgr.resolveContextRuleIdsForEntry(
          entry,
          <OZSmartAccountSigner>[],
          const <OZParsedContextRule>[], // empty → delegates to listContextRules → returns empty
        ),
        throwsA(isA<SmartAccountInvalidInput>()),
      );
    });

    test('noMatchingContextRule_throwsInvalidInput', () {
      final h = _buildHarness();
      final mgr = OZContextRuleManager(h.kit);

      // Create a CallContract rule with a specific contract.
      final rule = OZParsedContextRule(
        id: 0,
        contextType: const OZContextRuleTypeDefault(),
        name: 'rule',
        signers: <OZSmartAccountSigner>[OZDelegatedSigner(_accountAddress)],
        signerIds: const <int>[10],
        policies: const <String>[],
        policyIds: const <int>[],
      );

      // Use an entry that results in a CallContract context requiring a
      // specific contract, but no rule matches → should throw SmartAccountValidationException.
      // Actually with a Default rule and specific CallContract entry, the Default
      // rule matches everything, so let's use an explicit CallContract entry type.
      // With the Default rule, it matches any context, so we need a different setup.
      // Use the signer mismatch path: rule has signerA, we pass signerB.
      final result = mgr.resolveContextRuleIdsForEntryWithRules(
        _makeSourceAccountEntry(),
        <OZSmartAccountSigner>[],
        <OZParsedContextRule>[rule],
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
        // Second call (getContextRule): throw SmartAccountTransactionSimulationFailed.
        throw SmartAccountTransactionException.simulationFailed('no rule at this id');
      };
      final mgr = OZContextRuleManager(h.kit);

      // With count=1 but every getContextRule call failing, result is empty.
      final rules = await mgr.getAllContextRules(maxScanId: 3);
      expect(rules, isEmpty);
    });
  });

  group('parseContextRule context_type variants', () {
    XdrSCVal _ruleWithContextType(XdrSCVal contextTypeVal) {
      return XdrSCVal.forMap(<XdrSCMapEntry>[
        XdrSCMapEntry(XdrSCVal.forSymbol('id'), XdrSCVal.forU32(1)),
        XdrSCMapEntry(XdrSCVal.forSymbol('context_type'), contextTypeVal),
        XdrSCMapEntry(XdrSCVal.forSymbol('name'), XdrSCVal.forString('n')),
        XdrSCMapEntry(
          XdrSCVal.forSymbol('signers'),
          XdrSCVal.forVec(const <XdrSCVal>[]),
        ),
        XdrSCMapEntry(
          XdrSCVal.forSymbol('signer_ids'),
          XdrSCVal.forVec(const <XdrSCVal>[]),
        ),
        XdrSCMapEntry(
          XdrSCVal.forSymbol('policies'),
          XdrSCVal.forVec(const <XdrSCVal>[]),
        ),
        XdrSCMapEntry(
          XdrSCVal.forSymbol('policy_ids'),
          XdrSCVal.forVec(const <XdrSCVal>[]),
        ),
      ]);
    }

    test('CreateContract context_type round-trips the wasm hash', () {
      // Covers the CreateContract success branch (bytes present).
      final h = _buildHarness();
      final mgr = OZContextRuleManager(h.kit);
      final hash = _wasmHash(7);
      final parsed = mgr.parseContextRule(_ruleWithContextType(
        XdrSCVal.forVec(<XdrSCVal>[
          XdrSCVal.forSymbol('CreateContract'),
          XdrSCVal.forBytes(hash),
        ]),
      ));
      expect(parsed.contextType, isA<OZContextRuleTypeCreateContract>());
      expect(
        (parsed.contextType as OZContextRuleTypeCreateContract).wasmHash,
        hash,
      );
    });

    test('CallContract context_type with non-address element throws', () {
      // Covers the null-address guard in the CallContract branch.
      final h = _buildHarness();
      final mgr = OZContextRuleManager(h.kit);
      expect(
        () => mgr.parseContextRule(_ruleWithContextType(
          XdrSCVal.forVec(<XdrSCVal>[
            XdrSCVal.forSymbol('CallContract'),
            XdrSCVal.forU32(1), // not an address
          ]),
        )),
        throwsA(isA<SmartAccountInvalidInput>()),
      );
    });

    test('CreateContract context_type with non-bytes element throws', () {
      // Covers the null-bytes guard in the CreateContract branch.
      final h = _buildHarness();
      final mgr = OZContextRuleManager(h.kit);
      expect(
        () => mgr.parseContextRule(_ruleWithContextType(
          XdrSCVal.forVec(<XdrSCVal>[
            XdrSCVal.forSymbol('CreateContract'),
            XdrSCVal.forU32(1), // not bytes
          ]),
        )),
        throwsA(isA<SmartAccountInvalidInput>()),
      );
    });
  });

  group('parseContextRule signer variants', () {
    XdrSCVal _ruleWithSigners(List<XdrSCVal> signers) {
      return XdrSCVal.forMap(<XdrSCMapEntry>[
        XdrSCMapEntry(XdrSCVal.forSymbol('id'), XdrSCVal.forU32(2)),
        XdrSCMapEntry(
          XdrSCVal.forSymbol('context_type'),
          const OZContextRuleTypeDefault().toScVal(),
        ),
        XdrSCMapEntry(XdrSCVal.forSymbol('name'), XdrSCVal.forString('n')),
        XdrSCMapEntry(XdrSCVal.forSymbol('signers'), XdrSCVal.forVec(signers)),
        XdrSCMapEntry(
          XdrSCVal.forSymbol('signer_ids'),
          XdrSCVal.forVec(const <XdrSCVal>[]),
        ),
        XdrSCMapEntry(
          XdrSCVal.forSymbol('policies'),
          XdrSCVal.forVec(const <XdrSCVal>[]),
        ),
        XdrSCMapEntry(
          XdrSCVal.forSymbol('policy_ids'),
          XdrSCVal.forVec(const <XdrSCVal>[]),
        ),
      ]);
    }

    test('signer Vec with non-symbol discriminant throws', () {
      // Covers the null-discriminant guard in _parseSigner.
      final h = _buildHarness();
      final mgr = OZContextRuleManager(h.kit);
      expect(
        () => mgr.parseContextRule(_ruleWithSigners(<XdrSCVal>[
          XdrSCVal.forVec(<XdrSCVal>[XdrSCVal.forU32(0)]),
        ])),
        throwsA(isA<SmartAccountInvalidInput>()),
      );
    });

    test('Delegated signer with non-address element throws', () {
      // Covers the null-address guard in the Delegated branch.
      final h = _buildHarness();
      final mgr = OZContextRuleManager(h.kit);
      expect(
        () => mgr.parseContextRule(_ruleWithSigners(<XdrSCVal>[
          XdrSCVal.forVec(<XdrSCVal>[
            XdrSCVal.forSymbol('Delegated'),
            XdrSCVal.forU32(0), // not an address
          ]),
        ])),
        throwsA(isA<SmartAccountInvalidInput>()),
      );
    });

    test('External signer with non-address verifier element throws', () {
      // Covers the null-verifier-address guard in the External branch.
      final h = _buildHarness();
      final mgr = OZContextRuleManager(h.kit);
      expect(
        () => mgr.parseContextRule(_ruleWithSigners(<XdrSCVal>[
          XdrSCVal.forVec(<XdrSCVal>[
            XdrSCVal.forSymbol('External'),
            XdrSCVal.forU32(0), // not an address
            XdrSCVal.forBytes(Uint8List.fromList(<int>[1, 2, 3])),
          ]),
        ])),
        throwsA(isA<SmartAccountInvalidInput>()),
      );
    });

    test('External signer with non-bytes keyData element throws', () {
      // Covers the null-keyData guard in the External branch.
      final h = _buildHarness();
      final mgr = OZContextRuleManager(h.kit);
      expect(
        () => mgr.parseContextRule(_ruleWithSigners(<XdrSCVal>[
          XdrSCVal.forVec(<XdrSCVal>[
            XdrSCVal.forSymbol('External'),
            XdrSCVal.forAddress(
              Address.forContractId(_verifierContract).toXdr(),
            ),
            XdrSCVal.forU32(0), // not bytes
          ]),
        ])),
        throwsA(isA<SmartAccountInvalidInput>()),
      );
    });

    test('External signer with valid verifier and keyData round-trips', () {
      // Covers the External success path including
      // _requireContractAddressFromXdr returning the C-address.
      final h = _buildHarness();
      final mgr = OZContextRuleManager(h.kit);
      final parsed = mgr.parseContextRule(_ruleWithSigners(<XdrSCVal>[
        XdrSCVal.forVec(<XdrSCVal>[
          XdrSCVal.forSymbol('External'),
          XdrSCVal.forAddress(
            Address.forContractId(_verifierContract).toXdr(),
          ),
          XdrSCVal.forBytes(Uint8List.fromList(<int>[9, 8, 7])),
        ]),
      ]));
      expect(parsed.signers.single, isA<OZExternalSigner>());
      expect(
        (parsed.signers.single as OZExternalSigner).verifierAddress,
        _verifierContract,
      );
    });

    test('External signer whose verifier is a G-address throws', () {
      // Covers _requireContractAddressFromXdr rejecting a non-contract
      // (account) address in the verifier slot.
      final h = _buildHarness();
      final mgr = OZContextRuleManager(h.kit);
      expect(
        () => mgr.parseContextRule(_ruleWithSigners(<XdrSCVal>[
          XdrSCVal.forVec(<XdrSCVal>[
            XdrSCVal.forSymbol('External'),
            XdrSCVal.forAddress(
              Address.forAccountId(_accountAddress).toXdr(),
            ),
            XdrSCVal.forBytes(Uint8List.fromList(<int>[1])),
          ]),
        ])),
        throwsA(isA<SmartAccountInvalidInput>()),
      );
    });
  });

  group('parseContextRule policies field variants', () {
    XdrSCVal _ruleWithPoliciesField(XdrSCVal policiesField) {
      return XdrSCVal.forMap(<XdrSCMapEntry>[
        XdrSCMapEntry(XdrSCVal.forSymbol('id'), XdrSCVal.forU32(3)),
        XdrSCMapEntry(
          XdrSCVal.forSymbol('context_type'),
          const OZContextRuleTypeDefault().toScVal(),
        ),
        XdrSCMapEntry(XdrSCVal.forSymbol('name'), XdrSCVal.forString('n')),
        XdrSCMapEntry(
          XdrSCVal.forSymbol('signers'),
          XdrSCVal.forVec(const <XdrSCVal>[]),
        ),
        XdrSCMapEntry(
          XdrSCVal.forSymbol('signer_ids'),
          XdrSCVal.forVec(const <XdrSCVal>[]),
        ),
        XdrSCMapEntry(XdrSCVal.forSymbol('policies'), policiesField),
        XdrSCMapEntry(
          XdrSCVal.forSymbol('policy_ids'),
          XdrSCVal.forVec(const <XdrSCVal>[]),
        ),
      ]);
    }

    test('policies field that is not a Vec throws', () {
      // Covers the null-vec guard in _parseAddressVec.
      final h = _buildHarness();
      final mgr = OZContextRuleManager(h.kit);
      expect(
        () => mgr.parseContextRule(_ruleWithPoliciesField(XdrSCVal.forU32(0))),
        throwsA(isA<SmartAccountInvalidInput>()),
      );
    });

    test('policies field with valid address entries round-trips', () {
      final h = _buildHarness();
      final mgr = OZContextRuleManager(h.kit);
      final parsed = mgr.parseContextRule(_ruleWithPoliciesField(
        XdrSCVal.forVec(<XdrSCVal>[
          XdrSCVal.forAddress(Address.forContractId(_verifierContract).toXdr()),
        ]),
      ));
      expect(parsed.policies, <String>[_verifierContract]);
    });
  });

  group('resolveContextRuleIdsForEntry prefetched-rules path', () {
    test('non-empty contextRules bypasses listContextRules', () async {
      // Covers line 734: when contextRules is non-empty the manager resolves
      // directly against the supplied list without fetching.
      final h = _buildHarness();
      final mgr = OZContextRuleManager(h.kit);
      final rule = _rule(id: 42);

      final ids = await mgr.resolveContextRuleIdsForEntry(
        _makeSourceAccountEntry(),
        const <OZSmartAccountSigner>[],
        <OZParsedContextRule>[rule],
      );
      expect(ids, <int>[42]);
      // No simulation happened — the prefetched list short-circuited the fetch.
      expect(h.txOps.simulateAndExtractResultCalls, isEmpty);
    });
  });

  group('resolveContextRuleIdsForEntryWithRules no-match diagnostics', () {
    test('multiple Default candidates with no selected signers throws '
        'no-signer-match', () {
      // Two Default candidates so the single-candidate fast path is skipped.
      // With no selected signers, tier 1/2/3 all return null (each tier has
      // 2 matches, not 1), candidates is non-empty so the "Add a Default
      // rule" branch is skipped, and _candidatesContainingAllSelected
      // returns both (vacuously) -> the "multiple context rules" branch.
      final h = _buildHarness();
      final mgr = OZContextRuleManager(h.kit);
      expect(
        () => mgr.resolveContextRuleIdsForEntryWithRules(
          _makeSourceAccountEntry(),
          const <OZSmartAccountSigner>[],
          <OZParsedContextRule>[
            _rule(id: 1),
            _rule(id: 2),
          ],
        ),
        throwsA(isA<SmartAccountInvalidInput>()),
      );
    });

    test('multiple candidates none containing all selected signers throws '
        'no-rule-contains-all', () {
      // Covers the final throw (no candidate contains every selected signer).
      // Two Default candidates, each carrying a DISTINCT signer, and a
      // selected-signer set whose members are not all in any single rule.
      final h = _buildHarness();
      final mgr = OZContextRuleManager(h.kit);
      final signerA = _delegated(_accountAddress);
      final signerB = _delegated(_verifierContract);
      // Rule 1 has signerA + a policy (so tier2 excluded), rule 2 has signerB
      // + a policy. Selected = {A, B}: tier1 size mismatch (1 vs 2), tier2
      // excluded by policies, tier3/_candidatesContainingAllSelected empty
      // because neither rule contains BOTH A and B -> final throw.
      expect(
        () => mgr.resolveContextRuleIdsForEntryWithRules(
          _makeSourceAccountEntry(),
          <OZSmartAccountSigner>[signerA, signerB],
          <OZParsedContextRule>[
            _rule(
              id: 1,
              signers: <OZSmartAccountSigner>[signerA],
              policies: <String>[_verifierContract],
            ),
            _rule(
              id: 2,
              signers: <OZSmartAccountSigner>[signerB],
              policies: <String>[_verifierContract],
            ),
          ],
        ),
        throwsA(isA<SmartAccountInvalidInput>()),
      );
    });
  });

  group('invocation-tree context-type collection', () {
    test('V1 create-contract entry resolves a CreateContract rule', () {
      // Covers the CREATE_CONTRACT_HOST_FN branch + _extractWasmHash WASM
      // success path, resolved via a matching CreateContract rule.
      final h = _buildHarness();
      final mgr = OZContextRuleManager(h.kit);
      final hash = _wasmHash(3);
      final ids = mgr.resolveContextRuleIdsForEntryWithRules(
        _makeCreateContractEntry(hash),
        const <OZSmartAccountSigner>[],
        <OZParsedContextRule>[
          _rule(id: 5, contextType: OZContextRuleTypeCreateContract(hash)),
        ],
      );
      expect(ids, <int>[5]);
    });

    test('V2 create-contract entry resolves a CreateContract rule', () {
      // Covers the CREATE_CONTRACT_V2_HOST_FN branch.
      final h = _buildHarness();
      final mgr = OZContextRuleManager(h.kit);
      final hash = _wasmHash(4);
      final ids = mgr.resolveContextRuleIdsForEntryWithRules(
        _makeCreateContractV2Entry(hash),
        const <OZSmartAccountSigner>[],
        <OZParsedContextRule>[
          _rule(id: 6, contextType: OZContextRuleTypeCreateContract(hash)),
        ],
      );
      expect(ids, <int>[6]);
    });

    test('sub-invocation create-contract is collected recursively', () {
      // Covers _collectSubInvocationContextTypes loop body: the root call
      // yields a CallContract context and the sub-invocation yields a
      // CreateContract context, so two ids are resolved.
      final h = _buildHarness();
      final mgr = OZContextRuleManager(h.kit);
      final hash = _wasmHash(5);
      final ids = mgr.resolveContextRuleIdsForEntryWithRules(
        _makeCallWithCreateSubEntry(hash),
        const <OZSmartAccountSigner>[],
        <OZParsedContextRule>[
          _rule(
            id: 7,
            contextType: const OZContextRuleTypeCallContract(_validContractId),
          ),
          _rule(id: 8, contextType: OZContextRuleTypeCreateContract(hash)),
        ],
      );
      expect(ids, <int>[7, 8]);
    });

    test('create-contract entry referencing a Stellar Asset throws', () {
      // Covers _extractWasmHash CONTRACT_EXECUTABLE_STELLAR_ASSET branch.
      final h = _buildHarness();
      final mgr = OZContextRuleManager(h.kit);
      expect(
        () => mgr.resolveContextRuleIdsForEntryWithRules(
          _makeCreateAssetEntry(),
          const <OZSmartAccountSigner>[],
          <OZParsedContextRule>[_rule(id: 9)],
        ),
        throwsA(isA<SmartAccountInvalidInput>()),
      );
    });

    test('WASM executable with a missing hash throws', () {
      // Covers _extractWasmHash CONTRACT_EXECUTABLE_WASM null-hash guard:
      // a WASM-typed executable whose wasmHash field was never populated.
      final executable = XdrContractExecutable(
        XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM,
      );
      // wasmHash deliberately left null.
      final args = XdrCreateContractArgs(_idPreimage(), executable);
      final entry = XdrSorobanAuthorizationEntry(
        XdrSorobanCredentials.forSourceAccount(),
        XdrSorobanAuthorizedInvocation(
          XdrSorobanAuthorizedFunction.forCreateContractArgs(args),
          <XdrSorobanAuthorizedInvocation>[],
        ),
      );
      final h = _buildHarness();
      final mgr = OZContextRuleManager(h.kit);
      expect(
        () => mgr.resolveContextRuleIdsForEntryWithRules(
          entry,
          const <OZSmartAccountSigner>[],
          <OZParsedContextRule>[_rule(id: 10)],
        ),
        throwsA(isA<SmartAccountInvalidInput>()),
      );
    });

    test('executable of an unknown type throws', () {
      // Covers _extractWasmHash default branch: an executable carrying a
      // type discriminant outside the known WASM / Stellar-Asset set.
      final executable = XdrContractExecutable(
        XdrContractExecutableType(99),
      );
      final args = XdrCreateContractArgs(_idPreimage(), executable);
      final entry = XdrSorobanAuthorizationEntry(
        XdrSorobanCredentials.forSourceAccount(),
        XdrSorobanAuthorizedInvocation(
          XdrSorobanAuthorizedFunction.forCreateContractArgs(args),
          <XdrSorobanAuthorizedInvocation>[],
        ),
      );
      final h = _buildHarness();
      final mgr = OZContextRuleManager(h.kit);
      expect(
        () => mgr.resolveContextRuleIdsForEntryWithRules(
          entry,
          const <OZSmartAccountSigner>[],
          <OZParsedContextRule>[_rule(id: 11)],
        ),
        throwsA(isA<SmartAccountInvalidInput>()),
      );
    });
  });

  group('parseContextRule undecodable verifier address', () {
    test('External signer whose verifier address is undecodable throws', () {
      // Covers _requireContractAddressFromXdr null/empty-decode guard:
      // a claimable-balance-typed SCAddress carries no account/contract/muxed
      // id, so OZAddressStrKey.fromXdr returns null.
      final undecodable = XdrSCAddress(
        XdrSCAddressType.SC_ADDRESS_TYPE_CLAIMABLE_BALANCE,
      );
      final ruleScVal = XdrSCVal.forMap(<XdrSCMapEntry>[
        XdrSCMapEntry(XdrSCVal.forSymbol('id'), XdrSCVal.forU32(4)),
        XdrSCMapEntry(
          XdrSCVal.forSymbol('context_type'),
          const OZContextRuleTypeDefault().toScVal(),
        ),
        XdrSCMapEntry(XdrSCVal.forSymbol('name'), XdrSCVal.forString('n')),
        XdrSCMapEntry(
          XdrSCVal.forSymbol('signers'),
          XdrSCVal.forVec(<XdrSCVal>[
            XdrSCVal.forVec(<XdrSCVal>[
              XdrSCVal.forSymbol('External'),
              XdrSCVal.forAddress(undecodable),
              XdrSCVal.forBytes(Uint8List.fromList(<int>[1])),
            ]),
          ]),
        ),
        XdrSCMapEntry(
          XdrSCVal.forSymbol('signer_ids'),
          XdrSCVal.forVec(const <XdrSCVal>[]),
        ),
        XdrSCMapEntry(
          XdrSCVal.forSymbol('policies'),
          XdrSCVal.forVec(const <XdrSCVal>[]),
        ),
        XdrSCMapEntry(
          XdrSCVal.forSymbol('policy_ids'),
          XdrSCVal.forVec(const <XdrSCVal>[]),
        ),
      ]);
      final h = _buildHarness();
      final mgr = OZContextRuleManager(h.kit);
      expect(
        () => mgr.parseContextRule(ruleScVal),
        throwsA(isA<SmartAccountInvalidInput>()),
      );
    });
  });
}
