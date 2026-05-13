// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../../soroban/soroban_auth.dart';
import '../../util.dart';
import '../../xdr/xdr.dart';
import '../core/smart_account_errors.dart';
import 'oz_internal_pipeline_interfaces.dart';
import 'oz_selected_signer.dart';
import 'oz_smart_account_types.dart';
import 'oz_transaction_operations.dart';
import 'oz_validation.dart';

/// Policy installation parameters for OpenZeppelin smart-account
/// context rules.
///
/// Sealed hierarchy of three policy types:
///
/// - [SimpleThresholdParams]: M-of-N authorisation (equal-weight
///   signers).
/// - [WeightedThresholdParams]: weighted voting with a configurable
///   threshold.
/// - [SpendingLimitParams]: maximum spend per ledger window.
///
/// Policies are installed on a context rule and evaluated when matching
/// transactions request authorisation. For most use cases the
/// convenience helpers [OZPolicyManager.addSimpleThreshold],
/// [OZPolicyManager.addWeightedThreshold], and
/// [OZPolicyManager.addSpendingLimit] handle parameter encoding
/// internally — these `*Params` classes are used directly only when
/// calling [OZPolicyManager.addPolicy] with custom parameters.
sealed class PolicyInstallParams {
  /// Constructor for the sealed `PolicyInstallParams` hierarchy.
  const PolicyInstallParams();

  /// Returns the on-chain `ScVal` map encoding of the parameter shape.
  /// Marked [internal] because consumer code should prefer the
  /// convenience helpers on [OZPolicyManager].
  @internal
  XdrSCVal toScVal();
}

/// Simple threshold policy parameters. Requires at least [threshold]
/// signers from the context rule's signer list to authorise the call.
/// All signers carry equal weight.
final class SimpleThresholdParams extends PolicyInstallParams {
  /// Constructs simple threshold params. [threshold] must be > 0.
  const SimpleThresholdParams({required this.threshold});

  /// Minimum signer count required to authorise.
  final int threshold;

  @override
  XdrSCVal toScVal() {
    if (threshold <= 0) {
      throw ValidationException.invalidInput(
        'threshold',
        'Threshold must be greater than zero',
      );
    }
    final entries = <XdrSCMapEntry>[
      XdrSCMapEntry(
        XdrSCVal.forSymbol('threshold'),
        XdrSCVal.forU32(threshold),
      ),
    ];
    return XdrSCVal.forMap(entries);
  }

  @override
  bool operator ==(Object other) =>
      other is SimpleThresholdParams && other.threshold == threshold;

  @override
  int get hashCode => threshold.hashCode;
}

/// Weighted threshold policy parameters. Each signer carries a vote
/// weight; the sum of approving-signer weights must reach [threshold].
final class WeightedThresholdParams extends PolicyInstallParams {
  /// Constructs weighted threshold params. [threshold] must be > 0 and
  /// [signerWeights] must be non-empty.
  WeightedThresholdParams({
    required this.signerWeights,
    required this.threshold,
  });

  /// Map of signer to its vote weight.
  final Map<OZSmartAccountSigner, int> signerWeights;

  /// Minimum total weight required to authorise.
  final int threshold;

  @override
  XdrSCVal toScVal() {
    if (threshold <= 0) {
      throw ValidationException.invalidInput(
        'threshold',
        'Threshold must be greater than zero',
      );
    }
    if (signerWeights.isEmpty) {
      throw ValidationException.invalidInput(
        'signerWeights',
        'Weighted threshold policy requires at least one signer with weight',
      );
    }

    // Build signer weights inner map.
    final weightsEntries = <XdrSCMapEntry>[];
    for (final entry in signerWeights.entries) {
      final signerScVal = entry.key.toScVal();
      weightsEntries.add(
        XdrSCMapEntry(signerScVal, XdrSCVal.forU32(entry.value)),
      );
    }

    final sortedWeightsEntries =
        OZPolicyManager.sortMapByKeyXdr(weightsEntries);

    final topEntries = <XdrSCMapEntry>[
      XdrSCMapEntry(
        XdrSCVal.forSymbol('signer_weights'),
        XdrSCVal.forMap(sortedWeightsEntries),
      ),
      XdrSCMapEntry(
        XdrSCVal.forSymbol('threshold'),
        XdrSCVal.forU32(threshold),
      ),
    ];
    return XdrSCVal.forMap(topEntries);
  }

  static const _weightsEquality =
      MapEquality<OZSmartAccountSigner, int>();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! WeightedThresholdParams) return false;
    if (other.threshold != threshold) return false;
    return _weightsEquality.equals(other.signerWeights, signerWeights);
  }

  @override
  int get hashCode {
    // why: the order of entries in `signerWeights` is not part of the
    // logical identity (the contract sorts entries by XDR before
    // hashing). Folding through a sorted (key.hashCode, value)
    // projection keeps `hashCode` consistent with `==` regardless of
    // iteration order.
    final folded = signerWeights.entries
        .map((e) => Object.hash(e.key, e.value))
        .toList(growable: false)
      ..sort();
    return Object.hashAll(<Object?>[threshold, ...folded]);
  }
}

/// Spending limit policy parameters. Restricts the total amount spent
/// within a rolling ledger window.
final class SpendingLimitParams extends PolicyInstallParams {
  /// Constructs spending limit params. [spendingLimit] must be > 0 and
  /// [periodLedgers] must be > 0.
  const SpendingLimitParams({
    required this.spendingLimit,
    required this.periodLedgers,
  });

  /// Maximum amount in stroops (as a [BigInt]).
  final BigInt spendingLimit;

  /// Period length in ledgers.
  final int periodLedgers;

  @override
  XdrSCVal toScVal() {
    if (spendingLimit <= BigInt.zero) {
      throw ValidationException.invalidInput(
        'spendingLimit',
        'Spending limit must be greater than zero, got: $spendingLimit',
      );
    }
    if (periodLedgers <= 0) {
      throw ValidationException.invalidInput(
        'periodLedgers',
        'Period ledgers must be greater than zero, got: $periodLedgers',
      );
    }

    final limitI128 = Util.stroopsToI128ScVal(spendingLimit);

    final entries = <XdrSCMapEntry>[
      XdrSCMapEntry(
        XdrSCVal.forSymbol('period_ledgers'),
        XdrSCVal.forU32(periodLedgers),
      ),
      XdrSCMapEntry(XdrSCVal.forSymbol('spending_limit'), limitI128),
    ];
    return XdrSCVal.forMap(entries);
  }

  @override
  bool operator ==(Object other) =>
      other is SpendingLimitParams &&
      other.spendingLimit == spendingLimit &&
      other.periodLedgers == periodLedgers;

  @override
  int get hashCode => Object.hash(spendingLimit, periodLedgers);
}

/// Manager for policy operations on OpenZeppelin smart accounts.
///
/// Provides functionality to add and remove policies on context rules.
/// Policies define authorisation rules that must be satisfied for
/// transactions to execute. A context rule may carry up to 5 policies,
/// and every policy must be satisfied for the rule to authorise a
/// transaction.
///
/// Three convenience helpers are provided for the built-in policy
/// types ([addSimpleThreshold], [addWeightedThreshold],
/// [addSpendingLimit]). For custom policy contracts, call [addPolicy]
/// directly with the policy-specific installation parameters encoded
/// as [XdrSCVal].
class OZPolicyManager {
  /// Constructs a policy manager bound to the supplied kit. Marked
  /// [internal] because consumers access the manager via
  /// `kit.policyManager`.
  @internal
  OZPolicyManager(this._kit);

  final OZSmartAccountKitInterface _kit;

  // -------------------------------------------------------------------------
  // Convenience helpers
  // -------------------------------------------------------------------------

  /// Adds a simple threshold policy that requires at least [threshold]
  /// signers from the context rule's signer list to authorise.
  Future<TransactionResult> addSimpleThreshold({
    required int contextRuleId,
    required String policyAddress,
    required int threshold,
    List<SelectedSigner> selectedSigners = const <SelectedSigner>[],
    SubmissionMethod? forceMethod,
  }) async {
    final params = SimpleThresholdParams(threshold: threshold);
    return addPolicy(
      contextRuleId: contextRuleId,
      policyAddress: policyAddress,
      installParams: params.toScVal(),
      selectedSigners: selectedSigners,
      forceMethod: forceMethod,
    );
  }

  /// Adds a weighted threshold policy. Each signer carries a vote
  /// weight; the sum of approving-signer weights must reach
  /// [threshold].
  Future<TransactionResult> addWeightedThreshold({
    required int contextRuleId,
    required String policyAddress,
    required Map<OZSmartAccountSigner, int> signerWeights,
    required int threshold,
    List<SelectedSigner> selectedSigners = const <SelectedSigner>[],
    SubmissionMethod? forceMethod,
  }) async {
    final params = WeightedThresholdParams(
      signerWeights: signerWeights,
      threshold: threshold,
    );
    return addPolicy(
      contextRuleId: contextRuleId,
      policyAddress: policyAddress,
      installParams: params.toScVal(),
      selectedSigners: selectedSigners,
      forceMethod: forceMethod,
    );
  }

  /// Adds a spending-limit policy. Converts [spendingLimit] (a decimal
  /// XLM-style string with up to seven decimal places) to stroops via
  /// [Util.toXdrInt64Amount].
  Future<TransactionResult> addSpendingLimit({
    required int contextRuleId,
    required String policyAddress,
    required String spendingLimit,
    required int periodLedgers,
    List<SelectedSigner> selectedSigners = const <SelectedSigner>[],
    SubmissionMethod? forceMethod,
  }) async {
    final stroops = Util.toXdrInt64Amount(spendingLimit);
    final params = SpendingLimitParams(
      spendingLimit: stroops,
      periodLedgers: periodLedgers,
    );
    return addPolicy(
      contextRuleId: contextRuleId,
      policyAddress: policyAddress,
      installParams: params.toScVal(),
      selectedSigners: selectedSigners,
      forceMethod: forceMethod,
    );
  }

  // -------------------------------------------------------------------------
  // Remove policy
  // -------------------------------------------------------------------------

  /// Removes a policy by its on-chain ID.
  ///
  /// Builds a `remove_policy(context_rule_id, policy_id)` invocation
  /// and routes through single-signer or multi-signer submission.
  Future<TransactionResult> removePolicy({
    required int contextRuleId,
    required int policyId,
    List<SelectedSigner> selectedSigners = const <SelectedSigner>[],
    SubmissionMethod? forceMethod,
  }) async {
    final connected = await _kit.requireConnected();

    final hostFunction = _buildRemovePolicyFunction(
      contractId: connected.contractId,
      contextRuleId: contextRuleId,
      policyId: policyId,
    );

    return _route(hostFunction, selectedSigners, forceMethod);
  }

  /// Removes a policy by matching the policy contract [policyAddress].
  ///
  /// Fetches the target rule, parses it, finds the policy index, and
  /// delegates to the ID-based [removePolicy] overload. Renamed from
  /// `removePolicy` (the ID-based form) because Dart does not support
  /// overload-by-parameter-type.
  Future<TransactionResult> removePolicyByAddress({
    required int contextRuleId,
    required String policyAddress,
    List<SelectedSigner> selectedSigners = const <SelectedSigner>[],
    SubmissionMethod? forceMethod,
  }) async {
    requireContractAddress(policyAddress, fieldName: 'policyAddress');

    final ruleScVal = await _kit.contextRuleManager.getContextRule(
      contextRuleId,
    );
    final rule = _kit.contextRuleManager.parseContextRule(ruleScVal);

    final policyIndex = rule.policies.indexOf(policyAddress);
    if (policyIndex == -1) {
      throw ValidationException.invalidInput(
        'policyAddress',
        'Policy $policyAddress not found on context rule $contextRuleId',
      );
    }

    if (policyIndex >= rule.policyIds.length) {
      throw ValidationException.invalidInput(
        'policyAddress',
        'Policy found at index $policyIndex but policyIds has only '
            '${rule.policyIds.length} entries',
      );
    }

    return removePolicy(
      contextRuleId: contextRuleId,
      policyId: rule.policyIds[policyIndex],
      selectedSigners: selectedSigners,
      forceMethod: forceMethod,
    );
  }

  // -------------------------------------------------------------------------
  // Generic add policy
  // -------------------------------------------------------------------------

  /// Adds a policy with custom installation parameters.
  ///
  /// This is the generic entry point that [addSimpleThreshold],
  /// [addWeightedThreshold], and [addSpendingLimit] delegate to. Call
  /// directly for custom policy contracts whose installation parameters
  /// are not covered by the convenience helpers.
  Future<TransactionResult> addPolicy({
    required int contextRuleId,
    required String policyAddress,
    required XdrSCVal installParams,
    List<SelectedSigner> selectedSigners = const <SelectedSigner>[],
    SubmissionMethod? forceMethod,
  }) async {
    final connected = await _kit.requireConnected();
    requireContractAddress(policyAddress, fieldName: 'policyAddress');

    final hostFunction = _buildAddPolicyFunction(
      contractId: connected.contractId,
      contextRuleId: contextRuleId,
      policyAddress: policyAddress,
      installParams: installParams,
    );

    return _route(hostFunction, selectedSigners, forceMethod);
  }

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  XdrHostFunction _buildAddPolicyFunction({
    required String contractId,
    required int contextRuleId,
    required String policyAddress,
    required XdrSCVal installParams,
  }) {
    return XdrHostFunction.forInvokingContractWithArgs(
      XdrInvokeContractArgs(
        Address.forContractId(contractId).toXdr(),
        'add_policy',
        <XdrSCVal>[
          XdrSCVal.forU32(contextRuleId),
          XdrSCVal.forAddress(Address.forContractId(policyAddress).toXdr()),
          installParams,
        ],
      ),
    );
  }

  XdrHostFunction _buildRemovePolicyFunction({
    required String contractId,
    required int contextRuleId,
    required int policyId,
  }) {
    return XdrHostFunction.forInvokingContractWithArgs(
      XdrInvokeContractArgs(
        Address.forContractId(contractId).toXdr(),
        'remove_policy',
        <XdrSCVal>[
          XdrSCVal.forU32(contextRuleId),
          XdrSCVal.forU32(policyId),
        ],
      ),
    );
  }

  Future<TransactionResult> _route(
    XdrHostFunction hostFunction,
    List<SelectedSigner> selectedSigners,
    SubmissionMethod? forceMethod,
  ) async {
    if (selectedSigners.isEmpty) {
      return (_kit as OZSmartAccountWalletKitInterface).transactionOperations.submit(
            hostFunction: hostFunction,
            auth: const <XdrSorobanAuthorizationEntry>[],
            forceMethod: forceMethod,
          );
    }
    final manager =
        _kit.multiSignerManager as OZMultiSignerManagerInterface;
    return manager.submitWithMultipleSigners(
      hostFunction: hostFunction,
      selectedSigners: selectedSigners,
      forceMethod: forceMethod,
    );
  }

  // -------------------------------------------------------------------------
  // Static ScMap key-sort helper
  // -------------------------------------------------------------------------

  /// Sorts a list of [XdrSCMapEntry] entries lexicographically by the
  /// XDR-byte representation of their keys.
  ///
  /// Soroban mandates ScMap keys are ordered lexicographically by their
  /// XDR encoding — this is a deterministic-encoding requirement, not
  /// stylistic. Used by [WeightedThresholdParams.toScVal] and by
  /// `OZContextRuleManager.addContextRule` when sorting the policies
  /// map.
  static List<XdrSCMapEntry> sortMapByKeyXdr(List<XdrSCMapEntry> entries) {
    final sorted = List<XdrSCMapEntry>.from(entries);
    sorted.sort((a, b) {
      final aBytes = scValToXdrBytes(a.key);
      final bBytes = scValToXdrBytes(b.key);
      return _compareBytes(aBytes, bBytes);
    });
    return sorted;
  }

  /// Encodes a single [XdrSCVal] to its XDR byte representation.
  /// Exposed for tests verifying deterministic key ordering.
  static List<int> scValToXdrBytes(XdrSCVal scVal) {
    final stream = XdrDataOutputStream();
    XdrSCVal.encode(stream, scVal);
    return stream.bytes;
  }

  static int _compareBytes(List<int> a, List<int> b) {
    final minLength = a.length < b.length ? a.length : b.length;
    for (var i = 0; i < minLength; i++) {
      final aByte = a[i] & 0xFF;
      final bByte = b[i] & 0xFF;
      if (aByte != bByte) return aByte - bByte;
    }
    return a.length - b.length;
  }
}
