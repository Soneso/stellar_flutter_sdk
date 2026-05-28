// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import 'oz_pipeline_fixtures.dart';

// ---------------------------------------------------------------------------
// Test fixtures: contract addresses, signers, and recording doubles
// ---------------------------------------------------------------------------

const String _accountContract =
    'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK';
const String _policyContractA =
    'CADQOBYHA4DQOBYHA4DQOBYHA4DQOBYHA4DQOBYHA4DQOBYHA4DQP5KR';
const String _policyContractB =
    'CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC';
const String _credentialId = 'aGVsbG8tcG9saWN5LW1hbmFnZXI';

const String _validG1 =
    'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';

/// Recording transaction operations double. Captures every `submit()`
/// call so tests can assert on routing arguments without driving
/// the full Soroban RPC pipeline.
class RecordingTransactionOperations extends OZTransactionOperations {
  RecordingTransactionOperations(super.kit);

  /// Captured calls in invocation order.
  final List<({
    XdrHostFunction hostFunction,
    List<XdrSorobanAuthorizationEntry> auth,
    SubmissionMethod? forceMethod,
  })> submitCalls = <({
    XdrHostFunction hostFunction,
    List<XdrSorobanAuthorizationEntry> auth,
    SubmissionMethod? forceMethod,
  })>[];

  /// Result returned from every `submit()` invocation.
  TransactionResult result =
      const TransactionResult(success: true, hash: 'recorded-tx');

  /// When non-null, `submit()` raises this error instead of returning
  /// [result]. Used by failure-propagation tests.
  Object? errorToThrow;

  @override
  Future<TransactionResult> submit({
    required XdrHostFunction hostFunction,
    required List<XdrSorobanAuthorizationEntry> auth,
    SubmissionMethod? forceMethod,
    dynamic resolveContextRuleIds,
    dynamic cancelToken,
  }) async {
    submitCalls.add((
      hostFunction: hostFunction,
      auth: auth,
      forceMethod: forceMethod,
    ));
    final err = errorToThrow;
    if (err != null) {
      if (err is Exception) throw err;
      if (err is Error) throw err;
    }
    return result;
  }
}

/// Recording multi-signer manager double. Captures every
/// `submitWithMultipleSigners()` call so tests can assert on routing
/// arguments when `selectedSigners` is non-empty.
class RecordingMultiSignerManager extends OZMultiSignerManager {
  RecordingMultiSignerManager(super.kit);

  final List<({
    XdrHostFunction hostFunction,
    List<SelectedSigner> selectedSigners,
    SubmissionMethod? forceMethod,
  })> calls = <({
    XdrHostFunction hostFunction,
    List<SelectedSigner> selectedSigners,
    SubmissionMethod? forceMethod,
  })>[];

  TransactionResult result =
      const TransactionResult(success: true, hash: 'multi-tx');

  @override
  Future<TransactionResult> submitWithMultipleSigners({
    required XdrHostFunction hostFunction,
    required List<SelectedSigner> selectedSigners,
    SubmissionMethod? forceMethod,
    ResolveContextRuleIds? resolveContextRuleIds,
  }) async {
    calls.add((
      hostFunction: hostFunction,
      selectedSigners: selectedSigners,
      forceMethod: forceMethod,
    ));
    return result;
  }
}

/// Pipeline kit subclass that supplies a configurable
/// [multiSignerManager] for the routing tests. The default
/// `FakePipelineKit.multiSignerManager` getter throws; overriding it
/// here allows tests to inject the recording manager.
class _RoutingKit extends FakePipelineKit {
  _RoutingKit({
    super.contextRuleManager,
    super.transactionOperations,
  });

  RecordingMultiSignerManager? recordingMulti;

  @override
  Object get multiSignerManager {
    final m = recordingMulti;
    if (m == null) {
      throw StateError('recordingMulti not set');
    }
    return m;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Constructs a connected routing kit with recording transaction ops and
/// a recording multi-signer manager already wired through the kit.
({
  _RoutingKit kit,
  RecordingTransactionOperations recordingOps,
  RecordingMultiSignerManager recordingMulti,
  StubContextRuleManager ruleManager,
}) _buildKit() {
  final ruleManager = StubContextRuleManager();
  final kit = _RoutingKit(
    contextRuleManager: ruleManager,
  );
  // Replace transactionOperations with the recording double after the
  // kit is constructed so it owns the new ops object.
  final recordingOps = RecordingTransactionOperations(kit);
  final replaced = _RoutingKit(
    contextRuleManager: ruleManager,
    transactionOperations: recordingOps,
  )..setConnected(credentialId: _credentialId, contractId: _accountContract);
  final recordingMulti = RecordingMultiSignerManager(replaced);
  replaced.recordingMulti = recordingMulti;
  return (
    kit: replaced,
    recordingOps: recordingOps,
    recordingMulti: recordingMulti,
    ruleManager: ruleManager,
  );
}

/// Extracts the function name and args from a host function representing
/// an invocation. Used to verify the manager built the right contract
/// call.
({String fn, List<XdrSCVal> args, String contractIdHex}) _decodeInvoke(
  XdrHostFunction hostFunction,
) {
  final invoke = hostFunction.invokeContract!;
  return (
    fn: invoke.functionName,
    args: invoke.args,
    contractIdHex: Util.bytesToHex(invoke.contractAddress.contractId!.hash)
        .toLowerCase(),
  );
}

/// Returns the hex form of a strkey C-address (lowercase, no padding).
String _contractIdHex(String cAddress) =>
    Util.bytesToHex(StrKey.decodeContractId(cAddress)).toLowerCase();

void main() {
  group('addSimpleThreshold', () {
    test('zero threshold throws ValidationException', () async {
      final h = _buildKit();
      await expectLater(
        () => OZPolicyManager(h.kit).addSimpleThreshold(
          contextRuleId: 1,
          policyAddress: _policyContractA,
          threshold: 0,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('valid threshold builds add_policy host function', () async {
      final h = _buildKit();
      await OZPolicyManager(h.kit).addSimpleThreshold(
        contextRuleId: 7,
        policyAddress: _policyContractA,
        threshold: 2,
      );

      expect(h.recordingOps.submitCalls.length, equals(1));
      final call = h.recordingOps.submitCalls.single;
      final decoded = _decodeInvoke(call.hostFunction);
      expect(decoded.fn, equals('add_policy'));
      expect(decoded.contractIdHex, equals(_contractIdHex(_accountContract)));
      // args[0] = context_rule_id u32, args[1] = policy_address, args[2] = install_params map
      expect(decoded.args.length, equals(3));
      expect(decoded.args[0].discriminant, equals(XdrSCValType.SCV_U32));
      expect(decoded.args[0].u32!.uint32, equals(7));
      expect(decoded.args[1].discriminant, equals(XdrSCValType.SCV_ADDRESS));
      expect(decoded.args[2].discriminant, equals(XdrSCValType.SCV_MAP));
    });

    test('invalid policy address throws InvalidAddress', () async {
      final h = _buildKit();
      await expectLater(
        () => OZPolicyManager(h.kit).addSimpleThreshold(
          contextRuleId: 1,
          policyAddress: 'not-a-c-address',
          threshold: 1,
        ),
        throwsA(isA<InvalidAddress>()),
      );
    });

    test('not connected throws WalletNotConnected', () async {
      final ruleManager = StubContextRuleManager();
      final disconnectedKit = _RoutingKit(
        contextRuleManager: ruleManager,
      );
      // No setConnected call.
      await expectLater(
        () => OZPolicyManager(disconnectedKit).addSimpleThreshold(
          contextRuleId: 1,
          policyAddress: _policyContractA,
          threshold: 1,
        ),
        throwsA(isA<WalletNotConnected>()),
      );
    });

    test('routes to single-signer submit when selectedSigners is empty',
        () async {
      final h = _buildKit();
      await OZPolicyManager(h.kit).addSimpleThreshold(
        contextRuleId: 1,
        policyAddress: _policyContractA,
        threshold: 1,
      );
      expect(h.recordingOps.submitCalls.length, equals(1));
      expect(h.recordingMulti.calls, isEmpty);
    });

    test(
        'routes to multi-signer manager when selectedSigners is non-empty',
        () async {
      final h = _buildKit();
      await OZPolicyManager(h.kit).addSimpleThreshold(
        contextRuleId: 1,
        policyAddress: _policyContractA,
        threshold: 1,
        selectedSigners: const <SelectedSigner>[SelectedSignerPasskey()],
      );
      expect(h.recordingMulti.calls.length, equals(1));
      expect(h.recordingOps.submitCalls, isEmpty);
      expect(
        h.recordingMulti.calls.single.selectedSigners.length,
        equals(1),
      );
    });
  });

  group('addWeightedThreshold', () {
    test('empty signerWeights throws ValidationException', () async {
      final h = _buildKit();
      await expectLater(
        () => OZPolicyManager(h.kit).addWeightedThreshold(
          contextRuleId: 1,
          policyAddress: _policyContractA,
          signerWeights: const <OZSmartAccountSigner, int>{},
          threshold: 1,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('zero threshold throws ValidationException', () async {
      final h = _buildKit();
      await expectLater(
        () => OZPolicyManager(h.kit).addWeightedThreshold(
          contextRuleId: 1,
          policyAddress: _policyContractA,
          signerWeights: <OZSmartAccountSigner, int>{
            OZDelegatedSigner(_validG1): 1,
          },
          threshold: 0,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('valid input builds add_policy host function', () async {
      final h = _buildKit();
      await OZPolicyManager(h.kit).addWeightedThreshold(
        contextRuleId: 9,
        policyAddress: _policyContractA,
        signerWeights: <OZSmartAccountSigner, int>{
          OZDelegatedSigner(_validG1): 50,
        },
        threshold: 50,
      );
      final call = h.recordingOps.submitCalls.single;
      final decoded = _decodeInvoke(call.hostFunction);
      expect(decoded.fn, equals('add_policy'));
      expect(decoded.args.length, equals(3));
      expect(decoded.args[0].u32!.uint32, equals(9));
      expect(decoded.args[2].discriminant, equals(XdrSCValType.SCV_MAP));
      // top-level keys alphabetical: signer_weights, threshold.
      final topKeys =
          decoded.args[2].map!.map((e) => e.key.sym).toList();
      expect(topKeys, equals(<String>['signer_weights', 'threshold']));
    });

    test('signer_weights inner map is sorted by XDR key bytes', () async {
      final h = _buildKit();
      await OZPolicyManager(h.kit).addWeightedThreshold(
        contextRuleId: 1,
        policyAddress: _policyContractA,
        signerWeights: <OZSmartAccountSigner, int>{
          OZDelegatedSigner(_validG1): 30,
          OZDelegatedSigner(
            'GBVRV25F7XA5I2L3ILSA6XW3OCWLKGGLG4OP2EHKTWC5IHQ3EV26FQLS',
          ): 20,
        },
        threshold: 50,
      );
      final call = h.recordingOps.submitCalls.single;
      final decoded = _decodeInvoke(call.hostFunction);
      final innerMap = decoded.args[2].map![0].val.map!;
      // Two keys -> sorted by encoded XDR bytes.
      final firstBytes = OZPolicyManager.scValToXdrBytes(innerMap[0].key);
      final secondBytes = OZPolicyManager.scValToXdrBytes(innerMap[1].key);
      // Lexicographic compare.
      var less = false;
      final minLen = firstBytes.length < secondBytes.length
          ? firstBytes.length
          : secondBytes.length;
      for (var i = 0; i < minLen; i++) {
        final av = firstBytes[i] & 0xFF;
        final bv = secondBytes[i] & 0xFF;
        if (av != bv) {
          less = av < bv;
          break;
        }
      }
      expect(less, isTrue);
    });

    test('invalid policy address throws InvalidAddress', () async {
      final h = _buildKit();
      await expectLater(
        () => OZPolicyManager(h.kit).addWeightedThreshold(
          contextRuleId: 1,
          policyAddress: 'invalid',
          signerWeights: <OZSmartAccountSigner, int>{
            OZDelegatedSigner(_validG1): 1,
          },
          threshold: 1,
        ),
        throwsA(isA<InvalidAddress>()),
      );
    });

    test('not connected throws WalletNotConnected', () async {
      final ruleManager = StubContextRuleManager();
      final kit = _RoutingKit(contextRuleManager: ruleManager);
      await expectLater(
        () => OZPolicyManager(kit).addWeightedThreshold(
          contextRuleId: 1,
          policyAddress: _policyContractA,
          signerWeights: <OZSmartAccountSigner, int>{
            OZDelegatedSigner(_validG1): 1,
          },
          threshold: 1,
        ),
        throwsA(isA<WalletNotConnected>()),
      );
    });

    test(
        'routes to multi-signer manager when selectedSigners is non-empty',
        () async {
      final h = _buildKit();
      await OZPolicyManager(h.kit).addWeightedThreshold(
        contextRuleId: 1,
        policyAddress: _policyContractA,
        signerWeights: <OZSmartAccountSigner, int>{
          OZDelegatedSigner(_validG1): 1,
        },
        threshold: 1,
        selectedSigners: const <SelectedSigner>[SelectedSignerPasskey()],
      );
      expect(h.recordingMulti.calls.length, equals(1));
      expect(h.recordingOps.submitCalls, isEmpty);
    });
  });

  group('addSpendingLimit', () {
    test('zero amount string throws (Util.toXdrInt64Amount rejects)',
        () async {
      final h = _buildKit();
      await expectLater(
        () => OZPolicyManager(h.kit).addSpendingLimit(
          contextRuleId: 1,
          policyAddress: _policyContractA,
          spendingLimit: '0',
          periodLedgers: 1,
        ),
        // Either ValidationException (from SpendingLimitParams) or
        // ArgumentError (from Util.toXdrInt64Amount) is acceptable here;
        // the important contract is that no submit is dispatched.
        throwsA(anything),
      );
      expect(h.recordingOps.submitCalls, isEmpty);
    });

    test('negative amount string throws', () async {
      final h = _buildKit();
      await expectLater(
        () => OZPolicyManager(h.kit).addSpendingLimit(
          contextRuleId: 1,
          policyAddress: _policyContractA,
          spendingLimit: '-1',
          periodLedgers: 1,
        ),
        throwsA(anything),
      );
      expect(h.recordingOps.submitCalls, isEmpty);
    });

    test('zero periodLedgers throws ValidationException', () async {
      final h = _buildKit();
      await expectLater(
        () => OZPolicyManager(h.kit).addSpendingLimit(
          contextRuleId: 1,
          policyAddress: _policyContractA,
          spendingLimit: '1',
          periodLedgers: 0,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('valid input converts decimal amount to stroops via Util',
        () async {
      final h = _buildKit();
      await OZPolicyManager(h.kit).addSpendingLimit(
        contextRuleId: 4,
        policyAddress: _policyContractA,
        spendingLimit: '100', // 100 XLM = 1_000_000_000 stroops.
        periodLedgers: 17280,
      );
      final call = h.recordingOps.submitCalls.single;
      final decoded = _decodeInvoke(call.hostFunction);
      // Install-params map carries period_ledgers + spending_limit.
      final installParams = decoded.args[2].map!;
      final periodEntry =
          installParams.firstWhere((e) => e.key.sym == 'period_ledgers');
      final limitEntry =
          installParams.firstWhere((e) => e.key.sym == 'spending_limit');
      expect(periodEntry.val.u32!.uint32, equals(17280));
      expect(
        limitEntry.val.discriminant,
        equals(XdrSCValType.SCV_I128),
      );
      // 100 XLM in stroops fits entirely in the low part.
      expect(limitEntry.val.i128!.lo.uint64, equals(BigInt.from(1000000000)));
    });

    test('invalid policy address throws InvalidAddress', () async {
      final h = _buildKit();
      await expectLater(
        () => OZPolicyManager(h.kit).addSpendingLimit(
          contextRuleId: 1,
          policyAddress: 'invalid',
          spendingLimit: '1',
          periodLedgers: 1,
        ),
        throwsA(isA<InvalidAddress>()),
      );
    });

    test('routes to multi-signer manager when selectedSigners non-empty',
        () async {
      final h = _buildKit();
      await OZPolicyManager(h.kit).addSpendingLimit(
        contextRuleId: 1,
        policyAddress: _policyContractA,
        spendingLimit: '5',
        periodLedgers: 100,
        selectedSigners: const <SelectedSigner>[SelectedSignerPasskey()],
      );
      expect(h.recordingMulti.calls.length, equals(1));
      expect(h.recordingOps.submitCalls, isEmpty);
    });
  });

  group('addPolicy', () {
    test('invalid policy address throws InvalidAddress', () async {
      final h = _buildKit();
      await expectLater(
        () => OZPolicyManager(h.kit).addPolicy(
          contextRuleId: 1,
          policyAddress: 'not-c',
          installParams: XdrSCVal.forMap(const <XdrSCMapEntry>[]),
        ),
        throwsA(isA<InvalidAddress>()),
      );
    });

    test('not connected throws WalletNotConnected', () async {
      final ruleManager = StubContextRuleManager();
      final kit = _RoutingKit(contextRuleManager: ruleManager);
      await expectLater(
        () => OZPolicyManager(kit).addPolicy(
          contextRuleId: 1,
          policyAddress: _policyContractA,
          installParams: XdrSCVal.forMap(const <XdrSCMapEntry>[]),
        ),
        throwsA(isA<WalletNotConnected>()),
      );
    });

    test('valid input builds add_policy host function', () async {
      final h = _buildKit();
      await OZPolicyManager(h.kit).addPolicy(
        contextRuleId: 5,
        policyAddress: _policyContractA,
        installParams: XdrSCVal.forSymbol('custom-payload'),
      );
      final call = h.recordingOps.submitCalls.single;
      final decoded = _decodeInvoke(call.hostFunction);
      expect(decoded.fn, equals('add_policy'));
      expect(decoded.args.length, equals(3));
      expect(decoded.args[0].u32!.uint32, equals(5));
      expect(decoded.args[1].discriminant, equals(XdrSCValType.SCV_ADDRESS));
      expect(decoded.args[2].discriminant, equals(XdrSCValType.SCV_SYMBOL));
      expect(decoded.args[2].sym, equals('custom-payload'));
    });

    test('routes to single-signer submit when selectedSigners is empty',
        () async {
      final h = _buildKit();
      await OZPolicyManager(h.kit).addPolicy(
        contextRuleId: 1,
        policyAddress: _policyContractA,
        installParams: XdrSCVal.forMap(const <XdrSCMapEntry>[]),
      );
      expect(h.recordingOps.submitCalls.length, equals(1));
      expect(h.recordingMulti.calls, isEmpty);
    });

    test(
        'routes to multi-signer manager when selectedSigners is non-empty',
        () async {
      final h = _buildKit();
      await OZPolicyManager(h.kit).addPolicy(
        contextRuleId: 1,
        policyAddress: _policyContractA,
        installParams: XdrSCVal.forMap(const <XdrSCMapEntry>[]),
        selectedSigners: const <SelectedSigner>[SelectedSignerPasskey()],
      );
      expect(h.recordingMulti.calls.length, equals(1));
      expect(h.recordingOps.submitCalls, isEmpty);
    });
  });

  group('removePolicy by ID', () {
    test('not connected throws WalletNotConnected', () async {
      final ruleManager = StubContextRuleManager();
      final kit = _RoutingKit(contextRuleManager: ruleManager);
      await expectLater(
        () => OZPolicyManager(kit).removePolicy(
          contextRuleId: 1,
          policyId: 1,
        ),
        throwsA(isA<WalletNotConnected>()),
      );
    });

    test('builds remove_policy host function with rule and policy IDs',
        () async {
      final h = _buildKit();
      await OZPolicyManager(h.kit).removePolicy(
        contextRuleId: 11,
        policyId: 22,
      );
      final call = h.recordingOps.submitCalls.single;
      final decoded = _decodeInvoke(call.hostFunction);
      expect(decoded.fn, equals('remove_policy'));
      expect(decoded.contractIdHex, equals(_contractIdHex(_accountContract)));
      expect(decoded.args.length, equals(2));
      expect(decoded.args[0].u32!.uint32, equals(11));
      expect(decoded.args[1].u32!.uint32, equals(22));
    });

    test('routes to single-signer submit when selectedSigners is empty',
        () async {
      final h = _buildKit();
      await OZPolicyManager(h.kit).removePolicy(
        contextRuleId: 1,
        policyId: 1,
      );
      expect(h.recordingOps.submitCalls.length, equals(1));
      expect(h.recordingMulti.calls, isEmpty);
    });

    test(
        'routes to multi-signer manager when selectedSigners is non-empty',
        () async {
      final h = _buildKit();
      await OZPolicyManager(h.kit).removePolicy(
        contextRuleId: 1,
        policyId: 1,
        selectedSigners: const <SelectedSigner>[SelectedSignerPasskey()],
      );
      expect(h.recordingMulti.calls.length, equals(1));
      expect(h.recordingOps.submitCalls, isEmpty);
    });

    test('propagates submit failure to caller', () async {
      final h = _buildKit();
      h.recordingOps.errorToThrow =
          TransactionException.simulationFailed('boom');
      await expectLater(
        () => OZPolicyManager(h.kit).removePolicy(
          contextRuleId: 1,
          policyId: 1,
        ),
        throwsA(isA<TransactionSimulationFailed>()),
      );
    });
  });

  group('removePolicyByAddress', () {
    /// Pre-populates the stub context-rule manager so [removePolicyByAddress]
    /// resolves the supplied [policies] list (positionally aligned with
    /// [policyIds]).
    void _seedContextRule(
      StubContextRuleManager ruleManager,
      int contextRuleId, {
      required List<String> policies,
      required List<int> policyIds,
    }) {
      // Build a unique synthetic ScVal as the rule key.
      final scVal = XdrSCVal.forU32(contextRuleId);
      ruleManager.contextRulesById = <int, XdrSCVal>{contextRuleId: scVal};
      ruleManager.parsedContextRules = <XdrSCVal, ParsedContextRule>{
        scVal: ParsedContextRule(
          id: contextRuleId,
          contextType: const ContextRuleTypeDefault(),
          name: 'rule-$contextRuleId',
          signers: const <OZSmartAccountSigner>[],
          signerIds: const <int>[],
          policies: policies,
          policyIds: policyIds,
        ),
      };
    }

    test('policy not in rule list throws ValidationException',
        () async {
      final h = _buildKit();
      _seedContextRule(
        h.ruleManager,
        1,
        policies: <String>[_policyContractB],
        policyIds: <int>[42],
      );
      await expectLater(
        () => OZPolicyManager(h.kit).removePolicyByAddress(
          contextRuleId: 1,
          policyAddress: _policyContractA,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('invalid address throws InvalidAddress', () async {
      final h = _buildKit();
      await expectLater(
        () => OZPolicyManager(h.kit).removePolicyByAddress(
          contextRuleId: 1,
          policyAddress: 'not-a-c-address',
        ),
        throwsA(isA<InvalidAddress>()),
      );
    });

    test(
        'resolves matching policy address to its on-chain ID and '
        'delegates to ID-based removePolicy', () async {
      final h = _buildKit();
      _seedContextRule(
        h.ruleManager,
        7,
        policies: <String>[_policyContractB, _policyContractA],
        policyIds: <int>[100, 200],
      );

      await OZPolicyManager(h.kit).removePolicyByAddress(
        contextRuleId: 7,
        policyAddress: _policyContractA,
      );

      final call = h.recordingOps.submitCalls.single;
      final decoded = _decodeInvoke(call.hostFunction);
      expect(decoded.fn, equals('remove_policy'));
      expect(decoded.args[0].u32!.uint32, equals(7));
      // Index 1 -> policy id 200.
      expect(decoded.args[1].u32!.uint32, equals(200));
    });

    test(
        'bounds-check throws when policies / policyIds lengths disagree',
        () async {
      final h = _buildKit();
      _seedContextRule(
        h.ruleManager,
        2,
        policies: <String>[_policyContractA, _policyContractB],
        policyIds: <int>[1], // intentionally too short
      );
      await expectLater(
        () => OZPolicyManager(h.kit).removePolicyByAddress(
          contextRuleId: 2,
          policyAddress: _policyContractB,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('delegates to ID-based remove (verified via routed call shape)',
        () async {
      final h = _buildKit();
      _seedContextRule(
        h.ruleManager,
        3,
        policies: <String>[_policyContractA],
        policyIds: <int>[55],
      );

      await OZPolicyManager(h.kit).removePolicyByAddress(
        contextRuleId: 3,
        policyAddress: _policyContractA,
      );

      // Single submit with remove_policy invocation, args[0]==3 args[1]==55.
      final call = h.recordingOps.submitCalls.single;
      final decoded = _decodeInvoke(call.hostFunction);
      expect(decoded.fn, equals('remove_policy'));
      expect(decoded.args[0].u32!.uint32, equals(3));
      expect(decoded.args[1].u32!.uint32, equals(55));
    });

    test('empty policies list throws not-found ValidationException',
        () async {
      final h = _buildKit();
      _seedContextRule(
        h.ruleManager,
        9,
        policies: const <String>[],
        policyIds: const <int>[],
      );
      await expectLater(
        () => OZPolicyManager(h.kit).removePolicyByAddress(
          contextRuleId: 9,
          policyAddress: _policyContractA,
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  // The byte-equivalence assertions for the policy-install ScVal map shape
  // live in `oz_policy_install_params_test.dart`. The cases below cover the
  // sort/encode surface from the policy-manager side so the coverage is
  // self-contained and readable.
  group('sortMapByKeyXdr / scValToXdrBytes', () {
    test('sortMapByKeyXdr: empty input returns empty list', () {
      final sorted =
          OZPolicyManager.sortMapByKeyXdr(const <XdrSCMapEntry>[]);
      expect(sorted, isEmpty);
    });

    test('sortMapByKeyXdr: single entry returned unchanged', () {
      final entry = XdrSCMapEntry(
        XdrSCVal.forSymbol('only'),
        XdrSCVal.forU32(1),
      );
      final sorted = OZPolicyManager.sortMapByKeyXdr(<XdrSCMapEntry>[entry]);
      expect(sorted, hasLength(1));
      expect(sorted.first.key.sym, equals('only'));
      expect(sorted.first.val.u32!.uint32, equals(1));
    });

    test('sortMapByKeyXdr: multi-entry sorted by raw XDR bytes', () {
      // Build entries with keys that, when XDR-encoded as Symbols, sort
      // in a predictable lexicographic order.
      final entries = <XdrSCMapEntry>[
        XdrSCMapEntry(XdrSCVal.forSymbol('zeta'), XdrSCVal.forU32(3)),
        XdrSCMapEntry(XdrSCVal.forSymbol('alpha'), XdrSCVal.forU32(1)),
        XdrSCMapEntry(XdrSCVal.forSymbol('mu'), XdrSCVal.forU32(2)),
      ];
      final sorted = OZPolicyManager.sortMapByKeyXdr(entries);
      // The XDR encoding of a Symbol ScVal includes a length prefix,
      // so "mu" (length 2) sorts before "alpha"/"zeta" (length 5/4)
      // by raw bytes — verify against actual bytes rather than the
      // alphabetical order of the symbol names.
      for (var i = 0; i < sorted.length - 1; i++) {
        final a = OZPolicyManager.scValToXdrBytes(sorted[i].key);
        final b = OZPolicyManager.scValToXdrBytes(sorted[i + 1].key);
        final minLen = a.length < b.length ? a.length : b.length;
        var compared = false;
        for (var j = 0; j < minLen; j++) {
          final av = a[j] & 0xFF;
          final bv = b[j] & 0xFF;
          if (av != bv) {
            expect(av < bv, isTrue,
                reason: 'index $i not less than index ${i + 1}');
            compared = true;
            break;
          }
        }
        if (!compared) {
          expect(a.length <= b.length, isTrue);
        }
      }
    });

    test('sortMapByKeyXdr: values are preserved alongside keys', () {
      final e1 = XdrSCMapEntry(XdrSCVal.forSymbol('b'), XdrSCVal.forU32(2));
      final e2 = XdrSCMapEntry(XdrSCVal.forSymbol('a'), XdrSCVal.forU32(1));
      final sorted =
          OZPolicyManager.sortMapByKeyXdr(<XdrSCMapEntry>[e1, e2]);
      // Keys must match values from the same entry.
      for (final entry in sorted) {
        if (entry.key.sym == 'a') {
          expect(entry.val.u32!.uint32, equals(1));
        } else if (entry.key.sym == 'b') {
          expect(entry.val.u32!.uint32, equals(2));
        }
      }
    });

    test('scValToXdrBytes: round-trip yields decodable XDR', () {
      const value = 0x0123BABE;
      final scVal = XdrSCVal.forU32(value);
      final bytes = OZPolicyManager.scValToXdrBytes(scVal);
      expect(bytes, isNotEmpty);
      // Decode back via the SDK XDR machinery.
      final stream = XdrDataInputStream(Uint8List.fromList(bytes));
      final decoded = XdrSCVal.decode(stream);
      expect(decoded.discriminant, equals(XdrSCValType.SCV_U32));
      expect(decoded.u32!.uint32, equals(value));
    });
  });
}
