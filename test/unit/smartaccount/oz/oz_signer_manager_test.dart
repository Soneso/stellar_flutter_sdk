// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/src/smartaccount/oz/oz_internal_pipeline_interfaces.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

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
const String _accountAddressC =
    'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';
const String _credentialIdB64 = 'aGVsbG8tc21hcnQtYWNjb3VudA';

/// Builds a connected kit with the supplied [contextRuleManager] and a
/// mock transaction-operations layer. Returns the harness so tests can
/// inspect captured submissions.
({
  FakePipelineKit kit,
  MockOZTransactionOperations txOps,
}) _buildHarness({
  OZContextRuleManagerInterface? contextRuleManager,
}) {
  final kit = FakePipelineKit(contextRuleManager: contextRuleManager);
  final txOps = MockOZTransactionOperations(kit);
  kit.setTransactionOperations(txOps);
  kit.setConnected(credentialId: _credentialIdB64, contractId: _validContractId);
  return (kit: kit, txOps: txOps);
}

/// Stub context-rule manager that returns a pre-baked [ParsedContextRule]
/// for any rule id, so `removeSignerBySigner` can resolve a value to an
/// id without going on-chain.
class _ScriptedRuleManager implements OZContextRuleManagerInterface {
  _ScriptedRuleManager(this._rule);

  final ParsedContextRule _rule;

  @override
  Future<List<Object>> listContextRules() async => <Object>[_rule];

  @override
  Future<List<int>> resolveContextRuleIdsForEntry(
    XdrSorobanAuthorizationEntry entry,
    List<OZSmartAccountSigner> signers,
    List<Object> contextRules,
  ) async =>
      <int>[_rule.id];

  @override
  Future<List<XdrSCVal>> getAllContextRules({int? maxScanId}) async =>
      <XdrSCVal>[XdrSCVal.forVoid()];

  @override
  Future<XdrSCVal> getContextRule(int id) async => XdrSCVal.forVoid();

  @override
  ParsedContextRule parseContextRule(XdrSCVal scVal) => _rule;
}

void main() {
  // =======================================================================
  // Group J.2 — `removeSignerBySigner` round-trip (plan line 721)
  // =======================================================================

  group('Group J.2 removeSignerBySigner', () {
    test(
        'removeSigner_bySignerValue_resolvesToCorrectIdViaListContextRules',
        () async {
      // Given a context rule with three signers and known signerIds,
      // verify that removing by signer value resolves to the correct
      // numeric id and produces an identical XdrHostFunction to the
      // ID-based removeSigner overload for the same target.
      final signerA = OZDelegatedSigner(_accountAddressA);
      final signerB = OZDelegatedSigner(_accountAddressB);
      final signerC = OZDelegatedSigner(_accountAddressC);

      final rule = ParsedContextRule(
        id: 0,
        contextType: const ContextRuleTypeDefault(),
        name: 'rule',
        signers: <OZSmartAccountSigner>[signerA, signerB, signerC],
        signerIds: const <int>[10, 20, 30],
        policies: const <String>[],
        policyIds: const <int>[],
      );

      final h = _buildHarness(contextRuleManager: _ScriptedRuleManager(rule));
      final mgr = OZSignerManager(h.kit);

      // Resolve signerB to its id via removeSignerBySigner.
      await mgr.removeSignerBySigner(
        contextRuleId: 0,
        signer: signerB,
      );

      // For comparison, call the ID-based overload directly.
      await mgr.removeSigner(contextRuleId: 0, signerId: 20);

      expect(h.txOps.submitCalls.length, 2);
      final first = h.txOps.submitCalls[0].hostFunction.invokeContract!;
      final second = h.txOps.submitCalls[1].hostFunction.invokeContract!;

      // Same function name, same arg shape (U32, U32), same values.
      expect(first.functionName, second.functionName);
      expect(first.functionName, 'remove_signer');
      expect(first.args.length, 2);
      expect(first.args[0].u32?.uint32, second.args[0].u32?.uint32);
      expect(first.args[1].u32?.uint32, second.args[1].u32?.uint32);
      expect(first.args[1].u32?.uint32, 20);
    });

    test('removeSigner_bySignerValue_signerNotInRule_throwsValidation',
        () async {
      final ruleSigner = OZDelegatedSigner(_accountAddressA);
      final missingSigner = OZDelegatedSigner(_accountAddressB);

      final rule = ParsedContextRule(
        id: 0,
        contextType: const ContextRuleTypeDefault(),
        name: 'rule',
        signers: <OZSmartAccountSigner>[ruleSigner],
        signerIds: const <int>[10],
        policies: const <String>[],
        policyIds: const <int>[],
      );

      final h = _buildHarness(contextRuleManager: _ScriptedRuleManager(rule));
      final mgr = OZSignerManager(h.kit);

      await expectLater(
        () => mgr.removeSignerBySigner(
          contextRuleId: 0,
          signer: missingSigner,
        ),
        throwsA(isA<InvalidInput>()),
      );

      // No submission should have happened.
      expect(h.txOps.submitCalls, isEmpty);
    });
  });

  // =======================================================================
  // Additional signer-manager CRUD coverage worth shipping
  // =======================================================================

  group('OZSignerManager CRUD shape', () {
    test('addPasskey rejects a public key whose first byte is not 0x04',
        () async {
      final h = _buildHarness();
      final mgr = OZSignerManager(h.kit);
      final pk = Uint8List(65);
      pk[0] = 0x05;
      await expectLater(
        () => mgr.addPasskey(
          contextRuleId: 0,
          publicKey: pk,
          credentialId: Uint8List.fromList(<int>[1, 2, 3]),
        ),
        throwsA(isA<InvalidInput>()),
      );
    });

    test('addPasskey rejects an empty credential id', () async {
      final h = _buildHarness();
      final mgr = OZSignerManager(h.kit);
      final pk = Uint8List(65);
      pk[0] = 0x04;
      await expectLater(
        () => mgr.addPasskey(
          contextRuleId: 0,
          publicKey: pk,
          credentialId: Uint8List(0),
        ),
        throwsA(isA<InvalidInput>()),
      );
    });

    test('addEd25519 rejects a verifier address that is not a C-address',
        () async {
      final h = _buildHarness();
      final mgr = OZSignerManager(h.kit);
      await expectLater(
        () => mgr.addEd25519(
          contextRuleId: 0,
          verifierAddress: _accountAddressA,
          publicKey: Uint8List(32),
        ),
        throwsA(isA<InvalidAddress>()),
      );
    });

    test('addDelegated emits add_signer with the correct address payload',
        () async {
      final h = _buildHarness();
      final mgr = OZSignerManager(h.kit);
      await mgr.addDelegated(contextRuleId: 0, address: _accountAddressA);
      final args = h.txOps.submitCalls.single.hostFunction.invokeContract!.args;
      expect(args[1].vec![0].sym, 'Delegated');
      expect(args[1].vec![1].discriminant, XdrSCValType.SCV_ADDRESS);
    });

    test('addEd25519 emits add_signer with External + 32-byte keyData',
        () async {
      final h = _buildHarness();
      final mgr = OZSignerManager(h.kit);
      await mgr.addEd25519(
        contextRuleId: 0,
        verifierAddress: _verifierContract,
        publicKey: Uint8List(32),
      );
      final args = h.txOps.submitCalls.single.hostFunction.invokeContract!.args;
      expect(args[1].vec![0].sym, 'External');
      expect(args[1].vec![2].discriminant, XdrSCValType.SCV_BYTES);
      expect(args[1].vec![2].bytes!.sCBytes.length, 32);
    });

    test(
        'addPasskey emits add_signer with External + 65+credentialId.length keyData',
        () async {
      final h = _buildHarness();
      final mgr = OZSignerManager(h.kit);
      final pk = Uint8List(65);
      pk[0] = 0x04;
      final credentialId = Uint8List.fromList(<int>[1, 2, 3, 4, 5]);
      await mgr.addPasskey(
        contextRuleId: 0,
        publicKey: pk,
        credentialId: credentialId,
      );
      final args = h.txOps.submitCalls.single.hostFunction.invokeContract!.args;
      expect(args[1].vec![0].sym, 'External');
      // keyData is publicKey || credentialId.
      expect(args[1].vec![2].bytes!.sCBytes.length, 65 + 5);
    });

    test('removeSigner ID-overload arg order is (contextRuleId, signerId)',
        () async {
      final h = _buildHarness();
      final mgr = OZSignerManager(h.kit);
      await mgr.removeSigner(contextRuleId: 9, signerId: 13);
      final args = h.txOps.submitCalls.single.hostFunction.invokeContract!.args;
      expect(args.length, 2);
      expect(args[0].u32?.uint32, 9);
      expect(args[1].u32?.uint32, 13);
    });

    // Cross-SDK parity: iOS `OZSignerManagerTests.test_addPasskey_wrongSizePublicKey_throws`.
    test('addPasskey rejects a public key whose length is not 65 bytes',
        () async {
      final h = _buildHarness();
      final mgr = OZSignerManager(h.kit);
      final shortKey = Uint8List(64);
      shortKey[0] = 0x04;
      await expectLater(
        () => mgr.addPasskey(
          contextRuleId: 0,
          publicKey: shortKey,
          credentialId: Uint8List.fromList(<int>[1]),
        ),
        throwsA(isA<InvalidInput>()),
      );
      // Repeat with 66 bytes — same expectation.
      final longKey = Uint8List(66);
      longKey[0] = 0x04;
      await expectLater(
        () => mgr.addPasskey(
          contextRuleId: 0,
          publicKey: longKey,
          credentialId: Uint8List.fromList(<int>[1]),
        ),
        throwsA(isA<InvalidInput>()),
      );
    });

    // Cross-SDK parity: iOS `OZSignerManagerTests.test_addEd25519_wrongSizePublicKey_throws`.
    test('addEd25519 rejects a public key whose length is not 32 bytes',
        () async {
      final h = _buildHarness();
      final mgr = OZSignerManager(h.kit);
      await expectLater(
        () => mgr.addEd25519(
          contextRuleId: 0,
          verifierAddress: _verifierContract,
          publicKey: Uint8List(31),
        ),
        throwsA(isA<InvalidInput>()),
      );
      await expectLater(
        () => mgr.addEd25519(
          contextRuleId: 0,
          verifierAddress: _verifierContract,
          publicKey: Uint8List(33),
        ),
        throwsA(isA<InvalidInput>()),
      );
    });

    // Cross-SDK parity: iOS `OZSignerManagerTests.test_addDelegated_invalidAddress_throws`.
    test('addDelegated rejects an obviously invalid address', () async {
      final h = _buildHarness();
      final mgr = OZSignerManager(h.kit);
      await expectLater(
        () => mgr.addDelegated(contextRuleId: 0, address: 'NOTAVALIDADDRESS'),
        throwsA(isA<InvalidAddress>()),
      );
    });
  });

  // ==========================================================================
  // Cross-SDK parity: iOS
  // `OZSignerManagerTests.test_removeSignerBySigner_misalignedSignerIds_throwsValidation`.
  //
  // When the parsed context rule has a `signerIds` list shorter than its
  // `signers` list, attempting to look up the matching id by signer
  // value must surface as a [InvalidInput] rather than a generic
  // RangeError.
  // ==========================================================================

  group('removeSignerBySigner misaligned signerIds', () {
    test('signerIdsShorterThanSigners_throwsValidation', () async {
      final signerA = OZDelegatedSigner(_accountAddressA);
      final signerB = OZDelegatedSigner(_accountAddressB);

      final rule = ParsedContextRule(
        id: 0,
        contextType: const ContextRuleTypeDefault(),
        name: 'rule',
        signers: <OZSmartAccountSigner>[signerA, signerB],
        // signerIds contains only one entry, while signers has two —
        // the mapping for `signerB` is missing.
        signerIds: const <int>[10],
        policies: const <String>[],
        policyIds: const <int>[],
      );

      final h = _buildHarness(contextRuleManager: _ScriptedRuleManager(rule));
      final mgr = OZSignerManager(h.kit);

      await expectLater(
        () => mgr.removeSignerBySigner(
          contextRuleId: 0,
          signer: signerB,
        ),
        throwsA(isA<InvalidInput>()),
      );

      // No submission should have happened.
      expect(h.txOps.submitCalls, isEmpty);
    });
  });
}
