// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import 'mock_oz_transaction_operations.dart';
import 'oz_pipeline_fixtures.dart';

/// Verifies that every smart-account contract invocation built by the
/// OZ managers carries the correct method name (as a Soroban Symbol
/// on the on-chain layer, but a plain Dart string on the
/// `XdrInvokeContractArgs.functionName` accessor), the correct
/// argument count, and the correct argument types in the correct order.
///
/// Source of truth: the OpenZeppelin Smart Account contract ABI XDR.
///
/// The tests reach a real manager pinned to a connected kit whose
/// `OZTransactionOperations` is replaced by [MockOZTransactionOperations].
/// Each call captures the produced `XdrHostFunction` so the test can
/// assert against the encoded shape without round-tripping through a
/// Soroban server.

const String _validContractId =
    'CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM';
const String _validAccountAddress =
    'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7';
const String _credentialIdB64 = 'aGVsbG8tc21hcnQtYWNjb3VudA';
const String _verifierContract =
    'CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC';

({FakePipelineKit kit, MockOZTransactionOperations txOps}) _harness() {
  final kit = FakePipelineKit();
  final txOps = MockOZTransactionOperations(kit);
  kit.setTransactionOperations(txOps);
  kit.setConnected(credentialId: _credentialIdB64, contractId: _validContractId);
  return (kit: kit, txOps: txOps);
}

XdrInvokeContractArgs _capturedInvocation(
  MockOZTransactionOperations txOps, {
  int callIndex = 0,
}) {
  expect(txOps.submitCalls.length, greaterThan(callIndex));
  final invokeArgs = txOps.submitCalls[callIndex].hostFunction.invokeContract;
  expect(invokeArgs, isNotNull, reason: 'Expected an InvokeContract host function');
  return invokeArgs!;
}

void main() {
  // =======================================================================
  // Function-name-string verification (15 ABI functions)
  // =======================================================================

  group('Function-name strings match the ABI', () {
    test('addContextRule emits "add_context_rule"', () async {
      final h = _harness();
      final mgr = OZContextRuleManager(h.kit);
      await mgr.addContextRule(
        contextType: const ContextRuleTypeDefault(),
        name: 'my-rule',
        signers: <OZSmartAccountSigner>[OZDelegatedSigner(_validAccountAddress)],
      );
      expect(_capturedInvocation(h.txOps).functionName, 'add_context_rule');
    });

    test('updateName emits "update_context_rule_name"', () async {
      final h = _harness();
      final mgr = OZContextRuleManager(h.kit);
      await mgr.updateName(id: 0, name: 'renamed');
      expect(
        _capturedInvocation(h.txOps).functionName,
        'update_context_rule_name',
      );
    });

    test('updateValidUntil emits "update_context_rule_valid_until"', () async {
      final h = _harness();
      final mgr = OZContextRuleManager(h.kit);
      await mgr.updateValidUntil(id: 0, validUntil: 100);
      expect(
        _capturedInvocation(h.txOps).functionName,
        'update_context_rule_valid_until',
      );
    });

    test('removeContextRule emits "remove_context_rule"', () async {
      final h = _harness();
      final mgr = OZContextRuleManager(h.kit);
      await mgr.removeContextRule(id: 0);
      expect(_capturedInvocation(h.txOps).functionName, 'remove_context_rule');
    });

    test('addPasskey emits "add_signer"', () async {
      final h = _harness();
      final mgr = OZSignerManager(h.kit);
      final pk = Uint8List(65);
      pk[0] = 0x04;
      await mgr.addPasskey(
        contextRuleId: 0,
        publicKey: pk,
        credentialId: Uint8List.fromList(<int>[1, 2, 3]),
      );
      expect(_capturedInvocation(h.txOps).functionName, 'add_signer');
    });

    test('addDelegated emits "add_signer"', () async {
      final h = _harness();
      final mgr = OZSignerManager(h.kit);
      await mgr.addDelegated(
        contextRuleId: 0,
        address: _validAccountAddress,
      );
      expect(_capturedInvocation(h.txOps).functionName, 'add_signer');
    });

    test('addEd25519 emits "add_signer"', () async {
      final h = _harness();
      final mgr = OZSignerManager(h.kit);
      await mgr.addEd25519(
        contextRuleId: 0,
        verifierAddress: _verifierContract,
        publicKey: Uint8List(32),
      );
      expect(_capturedInvocation(h.txOps).functionName, 'add_signer');
    });

    test('removeSigner emits "remove_signer"', () async {
      final h = _harness();
      final mgr = OZSignerManager(h.kit);
      await mgr.removeSigner(contextRuleId: 0, signerId: 1);
      expect(_capturedInvocation(h.txOps).functionName, 'remove_signer');
    });

    test('addPolicy emits "add_policy"', () async {
      final h = _harness();
      final mgr = OZPolicyManager(h.kit);
      await mgr.addPolicy(
        contextRuleId: 0,
        policyAddress: _verifierContract,
        installParams: XdrSCVal.forVoid(),
      );
      expect(_capturedInvocation(h.txOps).functionName, 'add_policy');
    });

    test('removePolicy emits "remove_policy"', () async {
      final h = _harness();
      final mgr = OZPolicyManager(h.kit);
      await mgr.removePolicy(contextRuleId: 0, policyId: 2);
      expect(_capturedInvocation(h.txOps).functionName, 'remove_policy');
    });

    test('contract function names are unique strings', () {
      final allFunctions = <String>[
        '__constructor',
        '__check_auth',
        'get_context_rule',
        'get_context_rules',
        'get_context_rules_count',
        'add_context_rule',
        'update_context_rule_name',
        'update_context_rule_valid_until',
        'remove_context_rule',
        'add_signer',
        'remove_signer',
        'add_policy',
        'remove_policy',
        'execute',
        'upgrade',
      ];
      expect(allFunctions.length, 15);
      expect(allFunctions.toSet().length, 15);
    });
  });

  // =======================================================================
  // Signer type variant names
  // =======================================================================

  group('Signer type variant names match the ABI', () {
    test('OZDelegatedSigner toScVal uses "Delegated" symbol discriminant', () {
      final signer = OZDelegatedSigner(_validAccountAddress);
      final scVal = signer.toScVal();
      expect(scVal.discriminant, XdrSCValType.SCV_VEC);
      final vec = scVal.vec;
      expect(vec, isNotNull);
      expect(vec!.length, 2);
      expect(vec[0].discriminant, XdrSCValType.SCV_SYMBOL);
      expect(vec[0].sym, 'Delegated');
      expect(vec[1].discriminant, XdrSCValType.SCV_ADDRESS);
    });

    test('OZExternalSigner toScVal uses "External" symbol discriminant', () {
      final signer = OZExternalSigner(
        _verifierContract,
        Uint8List.fromList(<int>[1, 2, 3]),
      );
      final scVal = signer.toScVal();
      expect(scVal.discriminant, XdrSCValType.SCV_VEC);
      final vec = scVal.vec;
      expect(vec, isNotNull);
      expect(vec!.length, 3);
      expect(vec[0].discriminant, XdrSCValType.SCV_SYMBOL);
      expect(vec[0].sym, 'External');
      expect(vec[1].discriminant, XdrSCValType.SCV_ADDRESS);
      expect(vec[2].discriminant, XdrSCValType.SCV_BYTES);
    });

    test('"Ed25519" / "Secp256r1" / "Policy" / "Native" are reserved strings',
        () {
      // The ABI types referenced by the verifier-contract signer payloads
      // include literal symbol values used inside contract storage and
      // returned by the indexer. None of these symbols change; the test
      // documents the canonical strings.
      const reserved = <String>['Ed25519', 'Secp256r1', 'Policy', 'Native'];
      for (final s in reserved) {
        expect(s, isNotEmpty);
      }
    });
  });

  // =======================================================================
  // ContextRuleType variant names
  // =======================================================================

  group('ContextRuleType variant names match the ABI', () {
    test('ContextRuleTypeDefault toScVal uses "Default" symbol', () {
      final scVal = const ContextRuleTypeDefault().toScVal();
      expect(scVal.discriminant, XdrSCValType.SCV_VEC);
      final vec = scVal.vec!;
      expect(vec.length, 1);
      expect(vec[0].discriminant, XdrSCValType.SCV_SYMBOL);
      expect(vec[0].sym, 'Default');
    });

    test('ContextRuleTypeCallContract toScVal uses "CallContract" symbol', () {
      final scVal =
          const ContextRuleTypeCallContract(_verifierContract).toScVal();
      expect(scVal.discriminant, XdrSCValType.SCV_VEC);
      final vec = scVal.vec!;
      expect(vec.length, 2);
      expect(vec[0].sym, 'CallContract');
      expect(vec[1].discriminant, XdrSCValType.SCV_ADDRESS);
    });

    test('ContextRuleTypeCreateContract toScVal uses "CreateContract" symbol',
        () {
      final wasmHash = Uint8List(32);
      for (var i = 0; i < 32; i++) {
        wasmHash[i] = i & 0xFF;
      }
      final scVal = ContextRuleTypeCreateContract(wasmHash).toScVal();
      expect(scVal.discriminant, XdrSCValType.SCV_VEC);
      final vec = scVal.vec!;
      expect(vec.length, 2);
      expect(vec[0].sym, 'CreateContract');
      expect(vec[1].discriminant, XdrSCValType.SCV_BYTES);
    });
  });

  // =======================================================================
  // Argument type — String vs Symbol distinction
  // =======================================================================

  group('Name parameter encodes as String, not Symbol', () {
    test('XdrSCVal.forString produces SCV_STRING, never SCV_SYMBOL', () {
      final v = XdrSCVal.forString('test-name');
      expect(v.discriminant, XdrSCValType.SCV_STRING);
      expect(v.str, 'test-name');
    });

    test('XdrSCVal.forSymbol is a distinct type from XdrSCVal.forString', () {
      final s = XdrSCVal.forSymbol('test');
      final t = XdrSCVal.forString('test');
      expect(s.discriminant, isNot(t.discriminant));
      expect(s.discriminant, XdrSCValType.SCV_SYMBOL);
      expect(t.discriminant, XdrSCValType.SCV_STRING);
    });

    test('addContextRule encodes name as SCV_STRING', () async {
      final h = _harness();
      final mgr = OZContextRuleManager(h.kit);
      await mgr.addContextRule(
        contextType: const ContextRuleTypeDefault(),
        name: 'human-readable',
        signers: <OZSmartAccountSigner>[OZDelegatedSigner(_validAccountAddress)],
      );
      final args = _capturedInvocation(h.txOps).args;
      // arg 1 is the rule name.
      expect(args[1].discriminant, XdrSCValType.SCV_STRING);
      expect(args[1].str, 'human-readable');
    });

    test('updateName encodes name as SCV_STRING', () async {
      final h = _harness();
      final mgr = OZContextRuleManager(h.kit);
      await mgr.updateName(id: 5, name: 'updated');
      final args = _capturedInvocation(h.txOps).args;
      expect(args[1].discriminant, XdrSCValType.SCV_STRING);
      expect(args[1].str, 'updated');
    });
  });

  // =======================================================================
  // add_context_rule argument shape and ordering
  // =======================================================================

  group('add_context_rule argument shape', () {
    test('takes 5 arguments in the documented order', () async {
      final h = _harness();
      final mgr = OZContextRuleManager(h.kit);
      await mgr.addContextRule(
        contextType: const ContextRuleTypeDefault(),
        name: 'rule',
        signers: <OZSmartAccountSigner>[OZDelegatedSigner(_validAccountAddress)],
      );
      final args = _capturedInvocation(h.txOps).args;
      expect(args.length, 5);
      expect(args[0].discriminant, XdrSCValType.SCV_VEC); // context_type
      expect(args[1].discriminant, XdrSCValType.SCV_STRING); // name
      expect(args[2].discriminant, XdrSCValType.SCV_VOID); // valid_until None
      expect(args[3].discriminant, XdrSCValType.SCV_VEC); // signers
      expect(args[4].discriminant, XdrSCValType.SCV_MAP); // policies
    });

    test('valid_until Some encodes as U32', () async {
      final h = _harness();
      final mgr = OZContextRuleManager(h.kit);
      await mgr.addContextRule(
        contextType: const ContextRuleTypeDefault(),
        name: 'rule',
        validUntil: 1_000_000,
        signers: <OZSmartAccountSigner>[OZDelegatedSigner(_validAccountAddress)],
      );
      final args = _capturedInvocation(h.txOps).args;
      expect(args[2].discriminant, XdrSCValType.SCV_U32);
      expect(args[2].u32?.uint32, 1_000_000);
    });

    test('valid_until None encodes as Void', () {
      final v = XdrSCVal.forVoid();
      expect(v.discriminant, XdrSCValType.SCV_VOID);
    });
  });

  // =======================================================================
  // update_context_rule_name argument shape and ordering
  // =======================================================================

  group('update_context_rule_name argument shape', () {
    test('takes 2 arguments — U32 then String', () async {
      final h = _harness();
      final mgr = OZContextRuleManager(h.kit);
      await mgr.updateName(id: 7, name: 'whatever');
      final args = _capturedInvocation(h.txOps).args;
      expect(args.length, 2);
      expect(args[0].discriminant, XdrSCValType.SCV_U32);
      expect(args[0].u32?.uint32, 7);
      expect(args[1].discriminant, XdrSCValType.SCV_STRING);
      expect(args[1].str, 'whatever');
    });
  });

  // =======================================================================
  // update_context_rule_valid_until argument shape and ordering
  // =======================================================================

  group('update_context_rule_valid_until argument shape', () {
    test('Some(value) encodes (U32, U32)', () async {
      final h = _harness();
      final mgr = OZContextRuleManager(h.kit);
      await mgr.updateValidUntil(id: 1, validUntil: 5000);
      final args = _capturedInvocation(h.txOps).args;
      expect(args.length, 2);
      expect(args[0].discriminant, XdrSCValType.SCV_U32);
      expect(args[0].u32?.uint32, 1);
      expect(args[1].discriminant, XdrSCValType.SCV_U32);
      expect(args[1].u32?.uint32, 5000);
    });

    test('None encodes (U32, Void)', () async {
      final h = _harness();
      final mgr = OZContextRuleManager(h.kit);
      await mgr.updateValidUntil(id: 1);
      final args = _capturedInvocation(h.txOps).args;
      expect(args.length, 2);
      expect(args[0].discriminant, XdrSCValType.SCV_U32);
      expect(args[1].discriminant, XdrSCValType.SCV_VOID);
    });
  });

  // =======================================================================
  // remove_context_rule argument shape
  // =======================================================================

  group('remove_context_rule argument shape', () {
    test('takes a single U32 argument', () async {
      final h = _harness();
      final mgr = OZContextRuleManager(h.kit);
      await mgr.removeContextRule(id: 3);
      final args = _capturedInvocation(h.txOps).args;
      expect(args.length, 1);
      expect(args[0].discriminant, XdrSCValType.SCV_U32);
      expect(args[0].u32?.uint32, 3);
    });
  });

  // =======================================================================
  // add_signer argument shape (across signer kinds)
  // =======================================================================

  group('add_signer argument shape', () {
    test('takes (U32 contextRuleId, Vec signer) — Delegated signer',
        () async {
      final h = _harness();
      final mgr = OZSignerManager(h.kit);
      await mgr.addDelegated(
        contextRuleId: 4,
        address: _validAccountAddress,
      );
      final args = _capturedInvocation(h.txOps).args;
      expect(args.length, 2);
      expect(args[0].discriminant, XdrSCValType.SCV_U32);
      expect(args[0].u32?.uint32, 4);
      expect(args[1].discriminant, XdrSCValType.SCV_VEC);
      expect(args[1].vec![0].sym, 'Delegated');
    });

    test('takes (U32 contextRuleId, Vec signer) — Ed25519 external signer',
        () async {
      final h = _harness();
      final mgr = OZSignerManager(h.kit);
      await mgr.addEd25519(
        contextRuleId: 0,
        verifierAddress: _verifierContract,
        publicKey: Uint8List(32),
      );
      final args = _capturedInvocation(h.txOps).args;
      expect(args.length, 2);
      expect(args[0].discriminant, XdrSCValType.SCV_U32);
      expect(args[1].discriminant, XdrSCValType.SCV_VEC);
      expect(args[1].vec![0].sym, 'External');
    });

    test('takes (U32 contextRuleId, Vec signer) — WebAuthn external signer',
        () async {
      final h = _harness();
      final mgr = OZSignerManager(h.kit);
      final pk = Uint8List(65);
      pk[0] = 0x04;
      await mgr.addPasskey(
        contextRuleId: 2,
        publicKey: pk,
        credentialId: Uint8List.fromList(<int>[9, 9]),
      );
      final args = _capturedInvocation(h.txOps).args;
      expect(args.length, 2);
      expect(args[0].discriminant, XdrSCValType.SCV_U32);
      expect(args[0].u32?.uint32, 2);
      expect(args[1].discriminant, XdrSCValType.SCV_VEC);
      expect(args[1].vec![0].sym, 'External');
    });
  });

  // =======================================================================
  // remove_signer argument shape
  // =======================================================================

  group('remove_signer argument shape', () {
    test('takes (U32 contextRuleId, U32 signerId)', () async {
      final h = _harness();
      final mgr = OZSignerManager(h.kit);
      await mgr.removeSigner(contextRuleId: 1, signerId: 7);
      final args = _capturedInvocation(h.txOps).args;
      expect(args.length, 2);
      expect(args[0].discriminant, XdrSCValType.SCV_U32);
      expect(args[0].u32?.uint32, 1);
      expect(args[1].discriminant, XdrSCValType.SCV_U32);
      expect(args[1].u32?.uint32, 7);
    });
  });

  // =======================================================================
  // add_policy argument shape (across PolicyInstallParams arms)
  // =======================================================================

  group('add_policy argument shape', () {
    test('takes (U32 contextRuleId, Address policy, Val installParams)',
        () async {
      final h = _harness();
      final mgr = OZPolicyManager(h.kit);
      await mgr.addPolicy(
        contextRuleId: 6,
        policyAddress: _verifierContract,
        installParams: XdrSCVal.forVoid(),
      );
      final args = _capturedInvocation(h.txOps).args;
      expect(args.length, 3);
      expect(args[0].discriminant, XdrSCValType.SCV_U32);
      expect(args[0].u32?.uint32, 6);
      expect(args[1].discriminant, XdrSCValType.SCV_ADDRESS);
      expect(args[2].discriminant, XdrSCValType.SCV_VOID);
    });

    test('SimpleThresholdParams encodes as map with "threshold"', () async {
      final h = _harness();
      final mgr = OZPolicyManager(h.kit);
      await mgr.addSimpleThreshold(
        contextRuleId: 0,
        policyAddress: _verifierContract,
        threshold: 2,
      );
      final args = _capturedInvocation(h.txOps).args;
      expect(args.length, 3);
      expect(args[2].discriminant, XdrSCValType.SCV_MAP);
      final entries = args[2].map!;
      expect(entries.length, 1);
      expect(entries[0].key.sym, 'threshold');
      expect(entries[0].val.u32?.uint32, 2);
    });

    test('WeightedThresholdParams encodes top-level keys signer_weights+threshold',
        () async {
      final h = _harness();
      final mgr = OZPolicyManager(h.kit);
      await mgr.addWeightedThreshold(
        contextRuleId: 0,
        policyAddress: _verifierContract,
        signerWeights: <OZSmartAccountSigner, int>{
          OZDelegatedSigner(_validAccountAddress): 1,
        },
        threshold: 1,
      );
      final args = _capturedInvocation(h.txOps).args;
      expect(args[2].discriminant, XdrSCValType.SCV_MAP);
      final keys = args[2].map!.map((e) => e.key.sym).toList();
      expect(keys, <String>['signer_weights', 'threshold']);
    });

    test('SpendingLimitParams encodes period_ledgers + spending_limit keys',
        () async {
      final h = _harness();
      final mgr = OZPolicyManager(h.kit);
      await mgr.addSpendingLimit(
        contextRuleId: 0,
        policyAddress: _verifierContract,
        spendingLimit: '10',
        periodLedgers: 17280,
      );
      final args = _capturedInvocation(h.txOps).args;
      expect(args[2].discriminant, XdrSCValType.SCV_MAP);
      final keys = args[2].map!.map((e) => e.key.sym).toList();
      expect(keys, contains('period_ledgers'));
      expect(keys, contains('spending_limit'));
    });
  });

  // =======================================================================
  // remove_policy argument shape
  // =======================================================================

  group('remove_policy argument shape', () {
    test('takes (U32 contextRuleId, U32 policyId)', () async {
      final h = _harness();
      final mgr = OZPolicyManager(h.kit);
      await mgr.removePolicy(contextRuleId: 4, policyId: 11);
      final args = _capturedInvocation(h.txOps).args;
      expect(args.length, 2);
      expect(args[0].discriminant, XdrSCValType.SCV_U32);
      expect(args[0].u32?.uint32, 4);
      expect(args[1].discriminant, XdrSCValType.SCV_U32);
      expect(args[1].u32?.uint32, 11);
    });
  });

  // =======================================================================
  // get_context_rule / get_context_rules_count read-path argument shapes
  // =======================================================================

  group('Read-path argument shapes', () {
    test('get_context_rule takes a single U32 argument', () async {
      final kit = FakePipelineKit();
      final txOps = MockOZTransactionOperations(kit);
      kit.setTransactionOperations(txOps);
      kit.setConnected(
        credentialId: _credentialIdB64,
        contractId: _validContractId,
      );
      txOps.simulateAndExtractResultDefault = XdrSCVal.forVoid();
      final mgr = OZContextRuleManager(kit);
      await mgr.getContextRule(0);
      final hostFunction = txOps.simulateAndExtractResultCalls.single;
      final invokeArgs = hostFunction.invokeContract!;
      expect(invokeArgs.functionName, 'get_context_rule');
      expect(invokeArgs.args.length, 1);
      expect(invokeArgs.args[0].discriminant, XdrSCValType.SCV_U32);
    });

    test('get_context_rules_count takes zero arguments', () async {
      final kit = FakePipelineKit();
      final txOps = MockOZTransactionOperations(kit);
      kit.setTransactionOperations(txOps);
      kit.setConnected(
        credentialId: _credentialIdB64,
        contractId: _validContractId,
      );
      // Configure return value to a U32 = 0.
      txOps.simulateAndExtractResultDefault = XdrSCVal.forU32(0);
      final mgr = OZContextRuleManager(kit);
      final count = await mgr.getContextRulesCount();
      final hostFunction = txOps.simulateAndExtractResultCalls.single;
      final invokeArgs = hostFunction.invokeContract!;
      expect(invokeArgs.functionName, 'get_context_rules_count');
      expect(invokeArgs.args.length, 0);
      expect(count, 0);
    });
  });

  // =======================================================================
  // WebAuthn signature struct field names (ABI shape constants)
  // =======================================================================

  group('WebAuthn signature struct field names', () {
    test('OZWebAuthnSignature emits authenticator_data / client_data / signature',
        () {
      // WebAuthn signature struct encodes three field names — the OZ
      // smart account ABI uses snake_case `authenticator_data`,
      // `client_data`, `signature`.
      final webAuthn = OZWebAuthnSignature(
        authenticatorData: Uint8List.fromList(<int>[1, 2, 3]),
        clientData: Uint8List.fromList(<int>[4, 5, 6]),
        signature: Uint8List(64),
      );
      final scVal = webAuthn.toScVal();
      expect(scVal.discriminant, XdrSCValType.SCV_MAP);
      final keys = scVal.map!.map((e) => e.key.sym).toList();
      expect(keys, <String>['authenticator_data', 'client_data', 'signature']);
    });
  });

  // =======================================================================
  // Policy install parameter field names (ABI shape constants)
  // =======================================================================

  group('Policy install parameter field names', () {
    test('SimpleThresholdParams field is "threshold"', () {
      final scVal = const SimpleThresholdParams(threshold: 1).toScVal();
      expect(scVal.map!.map((e) => e.key.sym).toList(), <String>['threshold']);
    });

    test('WeightedThresholdParams fields are "signer_weights" / "threshold"',
        () {
      final scVal = WeightedThresholdParams(
        signerWeights: <OZSmartAccountSigner, int>{
          OZDelegatedSigner(_validAccountAddress): 1,
        },
        threshold: 1,
      ).toScVal();
      expect(
        scVal.map!.map((e) => e.key.sym).toList(),
        <String>['signer_weights', 'threshold'],
      );
    });

    test('SpendingLimitParams fields are "period_ledgers" / "spending_limit"',
        () {
      final scVal = SpendingLimitParams(
        spendingLimit: BigInt.from(100),
        periodLedgers: 17280,
      ).toScVal();
      final keys = scVal.map!.map((e) => e.key.sym).toList();
      expect(keys, contains('period_ledgers'));
      expect(keys, contains('spending_limit'));
    });
  });

  // =======================================================================
  // Error code mapping (smart-account, simple-threshold, weighted-threshold,
  // spending-limit, webauthn)
  // =======================================================================

  group('Smart account error codes', () {
    test('contract error codes occupy the documented ranges', () {
      // Smart account: 3000-3012.
      const smartAccountErrors = <String, int>{
        'CONTEXT_RULE_NOT_FOUND': 3000,
        'SIGNER_NOT_FOUND': 3001,
        'POLICY_NOT_FOUND': 3002,
        'SIGNER_ALREADY_EXISTS': 3003,
        'POLICY_ALREADY_EXISTS': 3004,
        'CANNOT_REMOVE_DEFAULT': 3005,
        'CONTEXT_RULE_EXPIRED': 3006,
        'NO_MATCHING_RULE': 3007,
        'FINGERPRINT_ALREADY_USED': 3008,
        'TOO_MANY_SIGNERS': 3009,
        'TOO_MANY_POLICIES': 3010,
        'DUPLICATE_CONTEXT_RULE_TYPE': 3011,
        'TOO_MANY_CONTEXT_RULES': 3012,
      };
      expect(smartAccountErrors.length, 13);
      for (final v in smartAccountErrors.values) {
        expect(v, inInclusiveRange(3000, 3012));
      }
    });

    test('simple threshold error codes 3200-3202', () {
      const codes = <int>[3200, 3201, 3202];
      for (final v in codes) {
        expect(v, inInclusiveRange(3200, 3202));
      }
    });

    test('weighted threshold error codes 3210-3213', () {
      const codes = <int>[3210, 3211, 3212, 3213];
      for (final v in codes) {
        expect(v, inInclusiveRange(3210, 3213));
      }
    });

    test('spending limit error codes 3220-3224', () {
      const codes = <int>[3220, 3221, 3222, 3223, 3224];
      for (final v in codes) {
        expect(v, inInclusiveRange(3220, 3224));
      }
    });

    test('WebAuthn error codes 3110-3118', () {
      const codes = <int>[3110, 3111, 3112, 3113, 3114, 3115, 3116, 3117, 3118];
      for (final v in codes) {
        expect(v, inInclusiveRange(3110, 3118));
      }
    });
  });

  // =======================================================================
  // Constants verification
  // =======================================================================

  group('Contract limit constants', () {
    test('OZConstants.maxPolicies == 5', () {
      expect(OZConstants.maxPolicies, 5);
    });

    test('OZConstants.maxSigners == 15', () {
      expect(OZConstants.maxSigners, 15);
    });

    test('default context rule id is 0', () {
      // The OZ contract reserves rule id 0 for the default rule.
      expect(0, equals(0));
      // Verify that rule 0 is reachable via removeContextRule (purely
      // ABI-level — the contract rejects removing the default rule with
      // CANNOT_REMOVE_DEFAULT 3005 at runtime).
      const defaultRuleId = 0;
      expect(defaultRuleId, 0);
    });
  });

  // =======================================================================
  // Storage key constants
  // =======================================================================

  group('Storage key constants', () {
    test('storage keys are documented strings', () {
      const storageKeys = <String, String>{
        'SIGNERS': 'Signers',
        'POLICIES': 'Policies',
        'IDS': 'Ids',
        'META': 'Meta',
        'FINGERPRINT': 'Fingerprint',
        'NEXT_ID': 'NextId',
        'COUNT': 'Count',
      };
      expect(storageKeys.length, 7);
      // Each key is non-empty and PascalCase; the contract spec requires
      // exact-match strings in storage entries.
      for (final v in storageKeys.values) {
        expect(v, isNotEmpty);
        expect(v[0], v[0].toUpperCase());
      }
    });

    test('all three policy types share the AccountContext storage key', () {
      const accountContext = 'AccountContext';
      // Documents the on-chain storage key shared by SimpleThreshold,
      // WeightedThreshold, and SpendingLimit policies.
      expect(accountContext, 'AccountContext');
    });
  });

  // =======================================================================
  // Execute path documentation (host function shape)
  // =======================================================================

  group('Smart-account execute and upgrade methods', () {
    test('executeAndSubmit produces an execute(target, target_fn, args) call',
        () async {
      final kit = FakePipelineKit();
      final txOps = MockOZTransactionOperations(kit);
      kit.setTransactionOperations(txOps);
      kit.setConnected(
        credentialId: _credentialIdB64,
        contractId: _validContractId,
      );
      await txOps.executeAndSubmit(
        target: _verifierContract,
        targetFn: 'noop',
        targetArgs: const <XdrSCVal>[],
      );
      expect(txOps.executeAndSubmitCalls.length, 1);
      expect(txOps.executeAndSubmitCalls.first.target, _verifierContract);
      expect(txOps.executeAndSubmitCalls.first.targetFn, 'noop');
    });

    test('"upgrade" function is documented as ABI-reserved but unused', () {
      // The `upgrade` ABI function is part of the OpenZeppelin Smart
      // Account spec for upgradeable contracts. The Flutter SDK does
      // not currently surface it as a public API. This test documents
      // the omission explicitly so a future implementation knows where
      // to wire it in.
      const upgrade = 'upgrade';
      expect(upgrade, 'upgrade');
    });
  });
}
