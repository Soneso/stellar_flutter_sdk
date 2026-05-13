// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:dio/dio.dart' as dio;
import 'package:stellar_flutter_sdk/src/smartaccount/oz/oz_internal_pipeline_interfaces.dart';
import 'package:stellar_flutter_sdk/src/smartaccount/oz/oz_smart_account_types.dart';
import 'package:stellar_flutter_sdk/src/smartaccount/oz/oz_transaction_operations.dart';
import 'package:stellar_flutter_sdk/src/xdr/xdr.dart';

/// Recording mock of [OZTransactionOperations] used by manager tests
/// to assert that single-signer routing reaches the transaction
/// pipeline with the expected host function and options, without
/// performing any RPC interaction.
///
/// The mock extends the production class and overrides every public
/// surface that the OZ managers call (`submit`, `transfer`,
/// `contractCall`, `executeAndSubmit`, `fundWallet`,
/// `simulateAndExtractResult`). Each call records its arguments into
/// a typed record list and returns a canned [TransactionResult] from a
/// per-method default. Tests configure the canned outcomes by mutating
/// the public `*Default` fields and inspect captured calls through the
/// matching `*Calls` lists.
class MockOZTransactionOperations extends OZTransactionOperations {
  /// Constructs the mock against the supplied [kit]. The kit reference
  /// is held only so the production base class is satisfied; none of
  /// its members are reached because every public method is overridden.
  MockOZTransactionOperations(OZSmartAccountKitInterface kit) : super(kit);

  // ---------------------------------------------------------------------
  // Canned outcomes
  // ---------------------------------------------------------------------

  /// Default [TransactionResult] returned from [submit]. Tests override
  /// the value to express success / failure / specific hash and ledger.
  TransactionResult submitDefault =
      const TransactionResult(success: true, hash: 'mock-submit-hash');

  /// Default [TransactionResult] returned from [transfer].
  TransactionResult transferDefault =
      const TransactionResult(success: true, hash: 'mock-transfer-hash');

  /// Default [TransactionResult] returned from [contractCall].
  TransactionResult contractCallDefault =
      const TransactionResult(success: true, hash: 'mock-contract-call-hash');

  /// Default [TransactionResult] returned from [executeAndSubmit].
  TransactionResult executeAndSubmitDefault =
      const TransactionResult(success: true, hash: 'mock-execute-hash');

  /// Default funded amount returned from [fundWallet].
  String fundWalletDefault = '100.0000000';

  /// Default [XdrSCVal] returned from [simulateAndExtractResult]. Defaults to
  /// `XdrSCVal.forVoid()` so call sites that only need to assert the call
  /// happened do not need to wire a richer fixture.
  XdrSCVal simulateAndExtractResultDefault = XdrSCVal.forVoid();

  /// Optional override applied per [submit] call, evaluated against the
  /// captured invocation. When non-null and returning non-null the
  /// returned [TransactionResult] supersedes [submitDefault].
  TransactionResult? Function(SubmitInvocation invocation)? submitOverride;

  /// Per-call [simulateAndExtractResult] override. When non-null and
  /// returning non-null the result supersedes [simulateAndExtractResultDefault].
  XdrSCVal? Function(XdrHostFunction hostFunction)?
      simulateAndExtractResultOverride;

  // ---------------------------------------------------------------------
  // Captured calls
  // ---------------------------------------------------------------------

  /// Every captured [submit] invocation in call order.
  final List<SubmitInvocation> submitCalls = <SubmitInvocation>[];

  /// Every captured [transfer] invocation in call order.
  final List<TransferInvocation> transferCalls = <TransferInvocation>[];

  /// Every captured [contractCall] invocation in call order.
  final List<ContractCallInvocation> contractCallCalls =
      <ContractCallInvocation>[];

  /// Every captured [executeAndSubmit] invocation in call order.
  final List<ExecuteAndSubmitInvocation> executeAndSubmitCalls =
      <ExecuteAndSubmitInvocation>[];

  /// Every captured [fundWallet] invocation in call order.
  final List<FundWalletInvocation> fundWalletCalls = <FundWalletInvocation>[];

  /// Every captured [simulateAndExtractResult] invocation in call order.
  final List<XdrHostFunction> simulateAndExtractResultCalls =
      <XdrHostFunction>[];

  // ---------------------------------------------------------------------
  // Public API overrides
  // ---------------------------------------------------------------------

  @override
  Future<TransactionResult> submit({
    required XdrHostFunction hostFunction,
    required List<XdrSorobanAuthorizationEntry> auth,
    SubmissionMethod? forceMethod,
    ResolveContextRuleIds? resolveContextRuleIds,
    dio.CancelToken? cancelToken,
  }) async {
    final invocation = SubmitInvocation(
      hostFunction: hostFunction,
      auth: List<XdrSorobanAuthorizationEntry>.unmodifiable(auth),
      forceMethod: forceMethod,
      resolveContextRuleIds: resolveContextRuleIds,
      cancelToken: cancelToken,
    );
    submitCalls.add(invocation);
    final override = submitOverride?.call(invocation);
    return override ?? submitDefault;
  }

  @override
  Future<TransactionResult> transfer({
    required String tokenContract,
    required String recipient,
    required String amount,
    SubmissionMethod? forceMethod,
    dio.CancelToken? cancelToken,
  }) async {
    transferCalls.add(TransferInvocation(
      tokenContract: tokenContract,
      recipient: recipient,
      amount: amount,
      forceMethod: forceMethod,
      cancelToken: cancelToken,
    ));
    return transferDefault;
  }

  @override
  Future<TransactionResult> contractCall({
    required String target,
    required String targetFn,
    List<XdrSCVal> targetArgs = const <XdrSCVal>[],
    SubmissionMethod? forceMethod,
    ResolveContextRuleIds? resolveContextRuleIds,
    dio.CancelToken? cancelToken,
  }) async {
    contractCallCalls.add(ContractCallInvocation(
      target: target,
      targetFn: targetFn,
      targetArgs: List<XdrSCVal>.unmodifiable(targetArgs),
      forceMethod: forceMethod,
      resolveContextRuleIds: resolveContextRuleIds,
      cancelToken: cancelToken,
    ));
    return contractCallDefault;
  }

  @override
  Future<TransactionResult> executeAndSubmit({
    required String target,
    required String targetFn,
    List<XdrSCVal> targetArgs = const <XdrSCVal>[],
    SubmissionMethod? forceMethod,
    ResolveContextRuleIds? resolveContextRuleIds,
    dio.CancelToken? cancelToken,
  }) async {
    executeAndSubmitCalls.add(ExecuteAndSubmitInvocation(
      target: target,
      targetFn: targetFn,
      targetArgs: List<XdrSCVal>.unmodifiable(targetArgs),
      forceMethod: forceMethod,
      resolveContextRuleIds: resolveContextRuleIds,
      cancelToken: cancelToken,
    ));
    return executeAndSubmitDefault;
  }

  @override
  Future<String> fundWallet({
    required String nativeTokenContract,
    SubmissionMethod? forceMethod,
    dio.CancelToken? cancelToken,
  }) async {
    fundWalletCalls.add(FundWalletInvocation(
      nativeTokenContract: nativeTokenContract,
      forceMethod: forceMethod,
      cancelToken: cancelToken,
    ));
    return fundWalletDefault;
  }

  @override
  Future<XdrSCVal> simulateAndExtractResult(XdrHostFunction hostFunction) async {
    simulateAndExtractResultCalls.add(hostFunction);
    final override = simulateAndExtractResultOverride?.call(hostFunction);
    return override ?? simulateAndExtractResultDefault;
  }
}

/// Captured arguments of a [MockOZTransactionOperations.submit] call.
class SubmitInvocation {
  /// Constructs an immutable submit-invocation record.
  const SubmitInvocation({
    required this.hostFunction,
    required this.auth,
    required this.forceMethod,
    required this.resolveContextRuleIds,
    required this.cancelToken,
  });

  /// Host function passed to the call.
  final XdrHostFunction hostFunction;

  /// Authorisation entries supplied by the caller.
  final List<XdrSorobanAuthorizationEntry> auth;

  /// Optional submission-method override.
  final SubmissionMethod? forceMethod;

  /// Optional per-entry context-rule-id resolver.
  final ResolveContextRuleIds? resolveContextRuleIds;

  /// Optional cancellation token.
  final dio.CancelToken? cancelToken;
}

/// Captured arguments of a [MockOZTransactionOperations.transfer] call.
class TransferInvocation {
  /// Constructs an immutable transfer-invocation record.
  const TransferInvocation({
    required this.tokenContract,
    required this.recipient,
    required this.amount,
    required this.forceMethod,
    required this.cancelToken,
  });

  /// Token contract address (C-address).
  final String tokenContract;

  /// Recipient address (G or C).
  final String recipient;

  /// Decimal amount string.
  final String amount;

  /// Optional submission-method override.
  final SubmissionMethod? forceMethod;

  /// Optional cancellation token.
  final dio.CancelToken? cancelToken;
}

/// Captured arguments of a [MockOZTransactionOperations.contractCall] call.
class ContractCallInvocation {
  /// Constructs an immutable contract-call invocation record.
  const ContractCallInvocation({
    required this.target,
    required this.targetFn,
    required this.targetArgs,
    required this.forceMethod,
    required this.resolveContextRuleIds,
    required this.cancelToken,
  });

  /// Target contract address (C-address).
  final String target;

  /// Function name on the target contract.
  final String targetFn;

  /// Pre-encoded function arguments.
  final List<XdrSCVal> targetArgs;

  /// Optional submission-method override.
  final SubmissionMethod? forceMethod;

  /// Optional per-entry context-rule-id resolver.
  final ResolveContextRuleIds? resolveContextRuleIds;

  /// Optional cancellation token.
  final dio.CancelToken? cancelToken;
}

/// Captured arguments of a [MockOZTransactionOperations.executeAndSubmit] call.
class ExecuteAndSubmitInvocation {
  /// Constructs an immutable executeAndSubmit-invocation record.
  const ExecuteAndSubmitInvocation({
    required this.target,
    required this.targetFn,
    required this.targetArgs,
    required this.forceMethod,
    required this.resolveContextRuleIds,
    required this.cancelToken,
  });

  /// Target contract address (C-address).
  final String target;

  /// Function name on the target contract.
  final String targetFn;

  /// Pre-encoded function arguments.
  final List<XdrSCVal> targetArgs;

  /// Optional submission-method override.
  final SubmissionMethod? forceMethod;

  /// Optional per-entry context-rule-id resolver.
  final ResolveContextRuleIds? resolveContextRuleIds;

  /// Optional cancellation token.
  final dio.CancelToken? cancelToken;
}

/// Captured arguments of a [MockOZTransactionOperations.fundWallet] call.
class FundWalletInvocation {
  /// Constructs an immutable fundWallet-invocation record.
  const FundWalletInvocation({
    required this.nativeTokenContract,
    required this.forceMethod,
    required this.cancelToken,
  });

  /// Native-token contract used for the on-chain transfer.
  final String nativeTokenContract;

  /// Optional submission-method override.
  final SubmissionMethod? forceMethod;

  /// Optional cancellation token.
  final dio.CancelToken? cancelToken;
}
