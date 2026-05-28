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
  MockOZTransactionOperations(OZSmartAccountKitInterface kit) : super(kit);

  TransactionResult submitDefault =
      const TransactionResult(success: true, hash: 'mock-submit-hash');

  TransactionResult transferDefault =
      const TransactionResult(success: true, hash: 'mock-transfer-hash');

  TransactionResult contractCallDefault =
      const TransactionResult(success: true, hash: 'mock-contract-call-hash');

  TransactionResult executeAndSubmitDefault =
      const TransactionResult(success: true, hash: 'mock-execute-hash');

  String fundWalletDefault = '100.0000000';

  /// Defaults to `XdrSCVal.forVoid()` so call sites that only need to assert
  /// the call happened do not need to wire a richer fixture.
  XdrSCVal simulateAndExtractResultDefault = XdrSCVal.forVoid();

  TransactionResult? Function(SubmitInvocation invocation)? submitOverride;

  XdrSCVal? Function(XdrHostFunction hostFunction)?
      simulateAndExtractResultOverride;

  final List<SubmitInvocation> submitCalls = <SubmitInvocation>[];
  final List<TransferInvocation> transferCalls = <TransferInvocation>[];
  final List<ContractCallInvocation> contractCallCalls =
      <ContractCallInvocation>[];
  final List<ExecuteAndSubmitInvocation> executeAndSubmitCalls =
      <ExecuteAndSubmitInvocation>[];
  final List<FundWalletInvocation> fundWalletCalls = <FundWalletInvocation>[];
  final List<XdrHostFunction> simulateAndExtractResultCalls =
      <XdrHostFunction>[];

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

/// Captured invocation record for [submit].
class SubmitInvocation {
  const SubmitInvocation({
    required this.hostFunction,
    required this.auth,
    required this.forceMethod,
    required this.resolveContextRuleIds,
    required this.cancelToken,
  });

  final XdrHostFunction hostFunction;
  final List<XdrSorobanAuthorizationEntry> auth;
  final SubmissionMethod? forceMethod;
  final ResolveContextRuleIds? resolveContextRuleIds;
  final dio.CancelToken? cancelToken;
}

/// Captured invocation record for [transfer].
class TransferInvocation {
  const TransferInvocation({
    required this.tokenContract,
    required this.recipient,
    required this.amount,
    required this.forceMethod,
    required this.cancelToken,
  });

  final String tokenContract;
  final String recipient;
  final String amount;
  final SubmissionMethod? forceMethod;
  final dio.CancelToken? cancelToken;
}

/// Captured invocation record for [contractCall].
class ContractCallInvocation {
  const ContractCallInvocation({
    required this.target,
    required this.targetFn,
    required this.targetArgs,
    required this.forceMethod,
    required this.resolveContextRuleIds,
    required this.cancelToken,
  });

  final String target;
  final String targetFn;
  final List<XdrSCVal> targetArgs;
  final SubmissionMethod? forceMethod;
  final ResolveContextRuleIds? resolveContextRuleIds;
  final dio.CancelToken? cancelToken;
}

/// Captured invocation record for [executeAndSubmit].
class ExecuteAndSubmitInvocation {
  const ExecuteAndSubmitInvocation({
    required this.target,
    required this.targetFn,
    required this.targetArgs,
    required this.forceMethod,
    required this.resolveContextRuleIds,
    required this.cancelToken,
  });

  final String target;
  final String targetFn;
  final List<XdrSCVal> targetArgs;
  final SubmissionMethod? forceMethod;
  final ResolveContextRuleIds? resolveContextRuleIds;
  final dio.CancelToken? cancelToken;
}

/// Captured invocation record for [fundWallet].
class FundWalletInvocation {
  const FundWalletInvocation({
    required this.nativeTokenContract,
    required this.forceMethod,
    required this.cancelToken,
  });

  final String nativeTokenContract;
  final SubmissionMethod? forceMethod;
  final dio.CancelToken? cancelToken;
}
