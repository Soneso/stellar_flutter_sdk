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
/// [OZTransactionResult] without touching the network.
class MockOZMultiSignerManager extends OZMultiSignerManager {
  MockOZMultiSignerManager(OZSmartAccountWalletKitInterface kit) : super(kit);

  OZTransactionResult submitWithMultipleSignersDefault =
      const OZTransactionResult(success: true, hash: 'mock-multi-signer-hash');

  OZTransactionResult multiSignerTransferDefault =
      const OZTransactionResult(success: true, hash: 'mock-multi-transfer-hash');

  OZTransactionResult multiSignerContractCallDefault = const OZTransactionResult(
    success: true,
    hash: 'mock-multi-contract-call-hash',
  );

  OZTransactionResult multiSignerExecuteAndSubmitDefault =
      const OZTransactionResult(success: true, hash: 'mock-multi-execute-hash');

  OZTransactionResult? Function(SubmitWithMultipleSignersInvocation invocation)?
      submitWithMultipleSignersOverride;

  final List<SubmitWithMultipleSignersInvocation>
      submitWithMultipleSignersCalls = <SubmitWithMultipleSignersInvocation>[];
  final List<MultiSignerTransferInvocation> multiSignerTransferCalls =
      <MultiSignerTransferInvocation>[];
  final List<MultiSignerContractCallInvocation> multiSignerContractCallCalls =
      <MultiSignerContractCallInvocation>[];
  final List<MultiSignerExecuteInvocation> multiSignerExecuteAndSubmitCalls =
      <MultiSignerExecuteInvocation>[];

  @override
  Future<OZTransactionResult> submitWithMultipleSigners({
    required XdrHostFunction hostFunction,
    required List<OZSelectedSigner> selectedSigners,
    OZSubmissionMethod? forceMethod,
    OZResolveContextRuleIds? resolveContextRuleIds,
  }) async {
    final invocation = SubmitWithMultipleSignersInvocation(
      hostFunction: hostFunction,
      selectedSigners: List<OZSelectedSigner>.unmodifiable(selectedSigners),
      forceMethod: forceMethod,
      resolveContextRuleIds: resolveContextRuleIds,
    );
    submitWithMultipleSignersCalls.add(invocation);
    final override = submitWithMultipleSignersOverride?.call(invocation);
    return override ?? submitWithMultipleSignersDefault;
  }

  @override
  Future<OZTransactionResult> multiSignerTransfer({
    required String tokenContract,
    required String recipient,
    required String amount,
    required List<OZSelectedSigner> selectedSigners,
    OZSubmissionMethod? forceMethod,
    OZResolveContextRuleIds? resolveContextRuleIds,
  }) async {
    multiSignerTransferCalls.add(MultiSignerTransferInvocation(
      tokenContract: tokenContract,
      recipient: recipient,
      amount: amount,
      selectedSigners: List<OZSelectedSigner>.unmodifiable(selectedSigners),
      forceMethod: forceMethod,
      resolveContextRuleIds: resolveContextRuleIds,
    ));
    return multiSignerTransferDefault;
  }

  @override
  Future<OZTransactionResult> multiSignerContractCall({
    required String target,
    required String targetFn,
    List<XdrSCVal> targetArgs = const <XdrSCVal>[],
    required List<OZSelectedSigner> selectedSigners,
    OZSubmissionMethod? forceMethod,
    OZResolveContextRuleIds? resolveContextRuleIds,
  }) async {
    multiSignerContractCallCalls.add(MultiSignerContractCallInvocation(
      target: target,
      targetFn: targetFn,
      targetArgs: List<XdrSCVal>.unmodifiable(targetArgs),
      selectedSigners: List<OZSelectedSigner>.unmodifiable(selectedSigners),
      forceMethod: forceMethod,
      resolveContextRuleIds: resolveContextRuleIds,
    ));
    return multiSignerContractCallDefault;
  }

  @override
  Future<OZTransactionResult> multiSignerExecuteAndSubmit({
    required String target,
    required String targetFn,
    List<XdrSCVal> targetArgs = const <XdrSCVal>[],
    required List<OZSelectedSigner> selectedSigners,
    OZSubmissionMethod? forceMethod,
    OZResolveContextRuleIds? resolveContextRuleIds,
  }) async {
    multiSignerExecuteAndSubmitCalls.add(MultiSignerExecuteInvocation(
      target: target,
      targetFn: targetFn,
      targetArgs: List<XdrSCVal>.unmodifiable(targetArgs),
      selectedSigners: List<OZSelectedSigner>.unmodifiable(selectedSigners),
      forceMethod: forceMethod,
      resolveContextRuleIds: resolveContextRuleIds,
    ));
    return multiSignerExecuteAndSubmitDefault;
  }
}

/// Captured invocation record for [submitWithMultipleSigners].
class SubmitWithMultipleSignersInvocation {
  const SubmitWithMultipleSignersInvocation({
    required this.hostFunction,
    required this.selectedSigners,
    required this.forceMethod,
    required this.resolveContextRuleIds,
  });

  final XdrHostFunction hostFunction;
  final List<OZSelectedSigner> selectedSigners;
  final OZSubmissionMethod? forceMethod;
  final OZResolveContextRuleIds? resolveContextRuleIds;
}

/// Captured invocation record for [multiSignerTransfer].
class MultiSignerTransferInvocation {
  const MultiSignerTransferInvocation({
    required this.tokenContract,
    required this.recipient,
    required this.amount,
    required this.selectedSigners,
    required this.forceMethod,
    required this.resolveContextRuleIds,
  });

  final String tokenContract;
  final String recipient;
  final String amount;
  final List<OZSelectedSigner> selectedSigners;
  final OZSubmissionMethod? forceMethod;
  final OZResolveContextRuleIds? resolveContextRuleIds;
}

/// Captured invocation record for [multiSignerContractCall].
class MultiSignerContractCallInvocation {
  const MultiSignerContractCallInvocation({
    required this.target,
    required this.targetFn,
    required this.targetArgs,
    required this.selectedSigners,
    required this.forceMethod,
    required this.resolveContextRuleIds,
  });

  final String target;
  final String targetFn;
  final List<XdrSCVal> targetArgs;
  final List<OZSelectedSigner> selectedSigners;
  final OZSubmissionMethod? forceMethod;
  final OZResolveContextRuleIds? resolveContextRuleIds;
}

/// Captured invocation record for [multiSignerExecuteAndSubmit].
class MultiSignerExecuteInvocation {
  const MultiSignerExecuteInvocation({
    required this.target,
    required this.targetFn,
    required this.targetArgs,
    required this.selectedSigners,
    required this.forceMethod,
    required this.resolveContextRuleIds,
  });

  final String target;
  final String targetFn;
  final List<XdrSCVal> targetArgs;
  final List<OZSelectedSigner> selectedSigners;
  final OZSubmissionMethod? forceMethod;
  final OZResolveContextRuleIds? resolveContextRuleIds;
}
