// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:stellar_flutter_sdk/src/smartaccount/oz/oz_internal_pipeline_interfaces.dart';
import 'package:stellar_flutter_sdk/src/smartaccount/oz/oz_multi_signer_manager.dart';
import 'package:stellar_flutter_sdk/src/smartaccount/oz/oz_smart_account_types.dart';
import 'package:stellar_flutter_sdk/src/smartaccount/oz/oz_transaction_operations.dart';
import 'package:stellar_flutter_sdk/src/xdr/xdr.dart';

/// Recording mock of [OZMultiSignerManager] used by manager tests to
/// assert that multi-signer routing reaches the multi-signer manager
/// with the correct host function, signer list, and submission options.
///
/// The mock extends the production class so that the
/// `kit.multiSignerManager as OZMultiSignerManager` cast performed by
/// the OZ sibling managers (`OZSignerManager`, `OZPolicyManager`,
/// `OZContextRuleManager`) succeeds. Every public entry point used by
/// those managers is overridden to record the call and return a canned
/// [TransactionResult] without touching the network.
class MockOZMultiSignerManager extends OZMultiSignerManager {
  /// Constructs the mock against the supplied [kit]. The kit is held only
  /// to satisfy the production base class; no kit member is reached
  /// because every public method is overridden.
  MockOZMultiSignerManager(OZSmartAccountWalletKitInterface kit) : super(kit);

  // ---------------------------------------------------------------------
  // Canned outcomes
  // ---------------------------------------------------------------------

  /// Default [TransactionResult] returned from [submitWithMultipleSigners].
  TransactionResult submitWithMultipleSignersDefault =
      const TransactionResult(success: true, hash: 'mock-multi-signer-hash');

  /// Default [TransactionResult] returned from [multiSignerTransfer].
  TransactionResult multiSignerTransferDefault =
      const TransactionResult(success: true, hash: 'mock-multi-transfer-hash');

  /// Default [TransactionResult] returned from [multiSignerContractCall].
  TransactionResult multiSignerContractCallDefault = const TransactionResult(
    success: true,
    hash: 'mock-multi-contract-call-hash',
  );

  /// Default [TransactionResult] returned from [multiSignerExecuteAndSubmit].
  TransactionResult multiSignerExecuteAndSubmitDefault =
      const TransactionResult(success: true, hash: 'mock-multi-execute-hash');

  /// Optional override applied per [submitWithMultipleSigners] call;
  /// when non-null and returning non-null the result supersedes
  /// [submitWithMultipleSignersDefault].
  TransactionResult? Function(SubmitWithMultipleSignersInvocation invocation)?
      submitWithMultipleSignersOverride;

  // ---------------------------------------------------------------------
  // Captured calls
  // ---------------------------------------------------------------------

  /// Every captured [submitWithMultipleSigners] invocation in call order.
  final List<SubmitWithMultipleSignersInvocation>
      submitWithMultipleSignersCalls = <SubmitWithMultipleSignersInvocation>[];

  /// Every captured [multiSignerTransfer] invocation in call order.
  final List<MultiSignerTransferInvocation> multiSignerTransferCalls =
      <MultiSignerTransferInvocation>[];

  /// Every captured [multiSignerContractCall] invocation in call order.
  final List<MultiSignerContractCallInvocation> multiSignerContractCallCalls =
      <MultiSignerContractCallInvocation>[];

  /// Every captured [multiSignerExecuteAndSubmit] invocation in call order.
  final List<MultiSignerExecuteInvocation> multiSignerExecuteAndSubmitCalls =
      <MultiSignerExecuteInvocation>[];

  // ---------------------------------------------------------------------
  // Public API overrides
  // ---------------------------------------------------------------------

  @override
  Future<TransactionResult> submitWithMultipleSigners({
    required XdrHostFunction hostFunction,
    required List<SelectedSigner> selectedSigners,
    SubmissionMethod? forceMethod,
    ResolveContextRuleIds? resolveContextRuleIds,
  }) async {
    final invocation = SubmitWithMultipleSignersInvocation(
      hostFunction: hostFunction,
      selectedSigners: List<SelectedSigner>.unmodifiable(selectedSigners),
      forceMethod: forceMethod,
      resolveContextRuleIds: resolveContextRuleIds,
    );
    submitWithMultipleSignersCalls.add(invocation);
    final override = submitWithMultipleSignersOverride?.call(invocation);
    return override ?? submitWithMultipleSignersDefault;
  }

  @override
  Future<TransactionResult> multiSignerTransfer({
    required String tokenContract,
    required String recipient,
    required String amount,
    required List<SelectedSigner> selectedSigners,
    SubmissionMethod? forceMethod,
    ResolveContextRuleIds? resolveContextRuleIds,
  }) async {
    multiSignerTransferCalls.add(MultiSignerTransferInvocation(
      tokenContract: tokenContract,
      recipient: recipient,
      amount: amount,
      selectedSigners: List<SelectedSigner>.unmodifiable(selectedSigners),
      forceMethod: forceMethod,
      resolveContextRuleIds: resolveContextRuleIds,
    ));
    return multiSignerTransferDefault;
  }

  @override
  Future<TransactionResult> multiSignerContractCall({
    required String target,
    required String targetFn,
    List<XdrSCVal> targetArgs = const <XdrSCVal>[],
    required List<SelectedSigner> selectedSigners,
    SubmissionMethod? forceMethod,
    ResolveContextRuleIds? resolveContextRuleIds,
  }) async {
    multiSignerContractCallCalls.add(MultiSignerContractCallInvocation(
      target: target,
      targetFn: targetFn,
      targetArgs: List<XdrSCVal>.unmodifiable(targetArgs),
      selectedSigners: List<SelectedSigner>.unmodifiable(selectedSigners),
      forceMethod: forceMethod,
      resolveContextRuleIds: resolveContextRuleIds,
    ));
    return multiSignerContractCallDefault;
  }

  @override
  Future<TransactionResult> multiSignerExecuteAndSubmit({
    required String target,
    required String targetFn,
    List<XdrSCVal> targetArgs = const <XdrSCVal>[],
    required List<SelectedSigner> selectedSigners,
    SubmissionMethod? forceMethod,
    ResolveContextRuleIds? resolveContextRuleIds,
  }) async {
    multiSignerExecuteAndSubmitCalls.add(MultiSignerExecuteInvocation(
      target: target,
      targetFn: targetFn,
      targetArgs: List<XdrSCVal>.unmodifiable(targetArgs),
      selectedSigners: List<SelectedSigner>.unmodifiable(selectedSigners),
      forceMethod: forceMethod,
      resolveContextRuleIds: resolveContextRuleIds,
    ));
    return multiSignerExecuteAndSubmitDefault;
  }
}

/// Captured arguments of a
/// [MockOZMultiSignerManager.submitWithMultipleSigners] call.
class SubmitWithMultipleSignersInvocation {
  /// Constructs an immutable invocation record.
  const SubmitWithMultipleSignersInvocation({
    required this.hostFunction,
    required this.selectedSigners,
    required this.forceMethod,
    required this.resolveContextRuleIds,
  });

  /// Host function passed to the call.
  final XdrHostFunction hostFunction;

  /// Selected signers supplied by the caller.
  final List<SelectedSigner> selectedSigners;

  /// Optional submission-method override.
  final SubmissionMethod? forceMethod;

  /// Optional per-entry context-rule-id resolver.
  final ResolveContextRuleIds? resolveContextRuleIds;
}

/// Captured arguments of a [MockOZMultiSignerManager.multiSignerTransfer] call.
class MultiSignerTransferInvocation {
  /// Constructs an immutable transfer-invocation record.
  const MultiSignerTransferInvocation({
    required this.tokenContract,
    required this.recipient,
    required this.amount,
    required this.selectedSigners,
    required this.forceMethod,
    required this.resolveContextRuleIds,
  });

  /// Token contract address (C-address).
  final String tokenContract;

  /// Recipient address (G or C).
  final String recipient;

  /// Decimal amount string.
  final String amount;

  /// Selected signers participating in the multi-signature.
  final List<SelectedSigner> selectedSigners;

  /// Optional submission-method override.
  final SubmissionMethod? forceMethod;

  /// Optional per-entry context-rule-id resolver.
  final ResolveContextRuleIds? resolveContextRuleIds;
}

/// Captured arguments of a
/// [MockOZMultiSignerManager.multiSignerContractCall] call.
class MultiSignerContractCallInvocation {
  /// Constructs an immutable contract-call invocation record.
  const MultiSignerContractCallInvocation({
    required this.target,
    required this.targetFn,
    required this.targetArgs,
    required this.selectedSigners,
    required this.forceMethod,
    required this.resolveContextRuleIds,
  });

  /// Target contract address (C-address).
  final String target;

  /// Function name on the target contract.
  final String targetFn;

  /// Pre-encoded function arguments.
  final List<XdrSCVal> targetArgs;

  /// Selected signers participating in the multi-signature.
  final List<SelectedSigner> selectedSigners;

  /// Optional submission-method override.
  final SubmissionMethod? forceMethod;

  /// Optional per-entry context-rule-id resolver.
  final ResolveContextRuleIds? resolveContextRuleIds;
}

/// Captured arguments of a
/// [MockOZMultiSignerManager.multiSignerExecuteAndSubmit] call.
class MultiSignerExecuteInvocation {
  /// Constructs an immutable executeAndSubmit invocation record.
  const MultiSignerExecuteInvocation({
    required this.target,
    required this.targetFn,
    required this.targetArgs,
    required this.selectedSigners,
    required this.forceMethod,
    required this.resolveContextRuleIds,
  });

  /// Target contract address (C-address).
  final String target;

  /// Function name on the target contract.
  final String targetFn;

  /// Pre-encoded function arguments.
  final List<XdrSCVal> targetArgs;

  /// Selected signers participating in the multi-signature.
  final List<SelectedSigner> selectedSigners;

  /// Optional submission-method override.
  final SubmissionMethod? forceMethod;

  /// Optional per-entry context-rule-id resolver.
  final ResolveContextRuleIds? resolveContextRuleIds;
}
