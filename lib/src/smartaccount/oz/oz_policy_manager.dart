// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../../soroban/soroban_auth.dart';
import '../../util.dart';
import '../../xdr/xdr.dart';
import '../core/sc_val_host_order.dart';
import '../core/smart_account_errors.dart';
import 'oz_internal_pipeline_interfaces.dart';
import 'oz_selected_signer.dart';
import 'oz_smart_account_types.dart';
import 'oz_submission_routing.dart';
import 'oz_transaction_operations.dart';
import 'oz_validation.dart';

/// Policy installation parameters for OpenZeppelin smart-account
/// context rules.
///
/// Sealed hierarchy of policy types:
///
/// - [OZSimpleThresholdPolicyParams]: M-of-N authorisation (equal-weight
///   signers).
/// - [OZWeightedThresholdPolicyParams]: weighted voting with a configurable
///   threshold.
/// - [OZSpendingLimitPolicyParams]: maximum spend per ledger window.
/// - [OZRawPolicyParams]: escape hatch wrapping a pre-encoded [XdrSCVal]
///   for custom policy contracts not covered by the dedicated subclasses.
///
/// Policies are installed on a context rule and evaluated when matching
/// transactions request authorisation. For most use cases the
/// convenience helpers [OZPolicyManager.addSimpleThreshold],
/// [OZPolicyManager.addWeightedThreshold], and
/// [OZPolicyManager.addSpendingLimit] handle parameter encoding
/// internally — these `*Params` classes are used directly only when
/// calling [OZPolicyManager.addPolicy] with custom parameters.
sealed class OZPolicyInstallParams {
  const OZPolicyInstallParams();

  /// Returns the on-chain `ScVal` map encoding of the parameter shape. The
  /// managers call this internally when installing the policy.
  XdrSCVal toScVal();
}

/// Simple threshold policy parameters. Requires at least [threshold]
/// signers from the context rule's signer list to authorise the call.
/// All signers carry equal weight.
final class OZSimpleThresholdPolicyParams extends OZPolicyInstallParams {
  /// Constructs simple threshold params. [threshold] must be > 0.
  const OZSimpleThresholdPolicyParams({required this.threshold});

  /// Minimum signer count required to authorise.
  final int threshold;

  @override
  XdrSCVal toScVal() {
    if (threshold <= 0) {
      throw SmartAccountValidationException.invalidInput(
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
      other is OZSimpleThresholdPolicyParams && other.threshold == threshold;

  @override
  int get hashCode => threshold.hashCode;
}

/// Weighted threshold policy parameters. Each signer carries a vote
/// weight; the sum of approving-signer weights must reach [threshold].
final class OZWeightedThresholdPolicyParams extends OZPolicyInstallParams {
  /// Constructs weighted threshold params. [threshold] must be > 0 and
  /// [signerWeights] must be non-empty.
  OZWeightedThresholdPolicyParams({
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
      throw SmartAccountValidationException.invalidInput(
        'threshold',
        'Threshold must be greater than zero',
      );
    }
    if (signerWeights.isEmpty) {
      throw SmartAccountValidationException.invalidInput(
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
    if (other is! OZWeightedThresholdPolicyParams) return false;
    if (other.threshold != threshold) return false;
    return _weightsEquality.equals(other.signerWeights, signerWeights);
  }

  @override
  int get hashCode {
    // why: the order of entries in `signerWeights` is not part of the
    // logical identity (the encoder sorts entries into the host's ScMap
    // key order). Folding through a sorted (key.hashCode, value)
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
final class OZSpendingLimitPolicyParams extends OZPolicyInstallParams {
  /// Constructs spending limit params. [spendingLimit] must be > 0 and
  /// [periodLedgers] must be > 0.
  const OZSpendingLimitPolicyParams({
    required this.spendingLimit,
    required this.periodLedgers,
  });

  /// Maximum amount in the token's base units (as a [BigInt]).
  final BigInt spendingLimit;

  /// Period length in ledgers.
  final int periodLedgers;

  @override
  XdrSCVal toScVal() {
    if (spendingLimit <= BigInt.zero) {
      throw SmartAccountValidationException.invalidInput(
        'spendingLimit',
        'Spending limit must be greater than zero, got: $spendingLimit',
      );
    }
    if (periodLedgers <= 0) {
      throw SmartAccountValidationException.invalidInput(
        'periodLedgers',
        'Period ledgers must be greater than zero, got: $periodLedgers',
      );
    }

    final limitI128 = Util.bigIntToI128ScVal(spendingLimit);

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
      other is OZSpendingLimitPolicyParams &&
      other.spendingLimit == spendingLimit &&
      other.periodLedgers == periodLedgers;

  @override
  int get hashCode => Object.hash(spendingLimit, periodLedgers);
}

/// Escape-hatch policy parameters for policy contracts whose install
/// parameters are not modelled by a dedicated subclass. Wraps a
/// pre-encoded [XdrSCVal] and returns it unchanged from [toScVal].
final class OZRawPolicyParams extends OZPolicyInstallParams {
  /// Constructs raw params from a pre-encoded [installParams] `ScVal`.
  const OZRawPolicyParams(this.installParams);

  /// The pre-encoded policy installation parameters.
  final XdrSCVal installParams;

  @override
  XdrSCVal toScVal() => installParams;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OZRawPolicyParams) return false;
    return const ListEquality<int>().equals(
      OZPolicyManager.scValToXdrBytes(installParams),
      OZPolicyManager.scValToXdrBytes(other.installParams),
    );
  }

  @override
  int get hashCode =>
      const ListEquality<int>().hash(
        OZPolicyManager.scValToXdrBytes(installParams),
      );
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
/// directly with an [OZPolicyInstallParams] — a typed subclass, or
/// [OZRawPolicyParams] wrapping a pre-encoded [XdrSCVal].
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
  ///
  /// Parameters:
  ///
  /// - [contextRuleId]: on-chain id of the rule the policy is installed on.
  /// - [policyAddress]: policy contract C-address.
  /// - [threshold]: the M in M-of-N; must be between 1 and the rule's
  ///   signer count.
  /// - [selectedSigners]: empty routes the single-signer passkey path;
  ///   non-empty routes the multi-signer pipeline.
  /// - [forceMethod]: overrides direct-vs-relayer submission.
  Future<OZTransactionResult> addSimpleThreshold({
    required int contextRuleId,
    required String policyAddress,
    required int threshold,
    List<OZSelectedSigner> selectedSigners = const <OZSelectedSigner>[],
    OZSubmissionMethod? forceMethod,
  }) async {
    final params = OZSimpleThresholdPolicyParams(threshold: threshold);
    return addPolicy(
      contextRuleId: contextRuleId,
      policyAddress: policyAddress,
      installParams: params,
      selectedSigners: selectedSigners,
      forceMethod: forceMethod,
    );
  }

  /// Adds a weighted threshold policy. Each signer carries a vote
  /// weight; the sum of approving-signer weights must reach
  /// [threshold].
  ///
  /// Parameters:
  ///
  /// - [contextRuleId]: on-chain id of the rule the policy is installed on.
  /// - [policyAddress]: policy contract C-address.
  /// - [signerWeights]: each signer mapped to its vote weight. Only weights
  ///   of signers present on the rule count toward [threshold]; a weight for
  ///   a signer not on the rule has no effect.
  /// - [threshold]: total approving weight required to authorise.
  /// - [selectedSigners]: empty routes the single-signer passkey path;
  ///   non-empty routes the multi-signer pipeline.
  /// - [forceMethod]: overrides direct-vs-relayer submission.
  ///
  /// ```dart
  /// await kit.policyManager.addWeightedThreshold(
  ///   contextRuleId: 0,
  ///   policyAddress: policyContractId,
  ///   signerWeights: {signerA: 2, signerB: 1},
  ///   threshold: 2,
  /// );
  /// ```
  Future<OZTransactionResult> addWeightedThreshold({
    required int contextRuleId,
    required String policyAddress,
    required Map<OZSmartAccountSigner, int> signerWeights,
    required int threshold,
    List<OZSelectedSigner> selectedSigners = const <OZSelectedSigner>[],
    OZSubmissionMethod? forceMethod,
  }) async {
    final params = OZWeightedThresholdPolicyParams(
      signerWeights: signerWeights,
      threshold: threshold,
    );
    return addPolicy(
      contextRuleId: contextRuleId,
      policyAddress: policyAddress,
      installParams: params,
      selectedSigners: selectedSigners,
      forceMethod: forceMethod,
    );
  }

  /// Adds a spending-limit policy. Converts [spendingLimit] (a positive
  /// decimal string with up to [decimals] fractional digits) to the token's
  /// base units. [decimals] defaults to 7; this method has no token-contract
  /// parameter and therefore does not fetch the scale automatically.
  ///
  /// Parameters:
  ///
  /// - [contextRuleId]: on-chain id of the rule the policy is installed on.
  /// - [policyAddress]: policy contract C-address.
  /// - [spendingLimit]: maximum spend over the window as a positive decimal
  ///   string with up to [decimals] fractional digits.
  /// - [periodLedgers]: rolling window length in ledgers.
  /// - [decimals]: token scale used to convert [spendingLimit] to base
  ///   units; defaults to 7.
  /// - [selectedSigners]: empty routes the single-signer passkey path;
  ///   non-empty routes the multi-signer pipeline.
  /// - [forceMethod]: overrides direct-vs-relayer submission.
  Future<OZTransactionResult> addSpendingLimit({
    required int contextRuleId,
    required String policyAddress,
    required String spendingLimit,
    required int periodLedgers,
    int decimals = 7,
    List<OZSelectedSigner> selectedSigners = const <OZSelectedSigner>[],
    OZSubmissionMethod? forceMethod,
  }) async {
    final BigInt baseUnits;
    try {
      baseUnits = OZTransactionOperations.amountToBaseUnits(
        spendingLimit,
        decimals: decimals,
      );
    } on SmartAccountValidationException catch (e) {
      // Re-surface as a field-tagged validation error so the message refers
      // to the policy parameter the caller supplied.
      throw SmartAccountValidationException.invalidInput(
        'spendingLimit',
        'Invalid spending limit: ${e.message}',
        cause: e,
      );
    }
    final params = OZSpendingLimitPolicyParams(
      spendingLimit: baseUnits,
      periodLedgers: periodLedgers,
    );
    return addPolicy(
      contextRuleId: contextRuleId,
      policyAddress: policyAddress,
      installParams: params,
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
  ///
  /// Parameters:
  ///
  /// - [contextRuleId]: on-chain id of the rule the policy is on.
  /// - [policyId]: on-chain id of the policy on the rule.
  /// - [selectedSigners]: empty routes the single-signer passkey path;
  ///   non-empty routes the multi-signer pipeline.
  /// - [forceMethod]: overrides direct-vs-relayer submission.
  Future<OZTransactionResult> removePolicy({
    required int contextRuleId,
    required int policyId,
    List<OZSelectedSigner> selectedSigners = const <OZSelectedSigner>[],
    OZSubmissionMethod? forceMethod,
  }) async {
    final connected = await _kit.requireConnected();

    final hostFunction = _buildRemovePolicyFunction(
      contractId: connected.contractId,
      contextRuleId: contextRuleId,
      policyId: policyId,
    );

    return ozRouteSubmission(_kit as OZSmartAccountWalletKitInterface, hostFunction, selectedSigners, forceMethod);
  }

  /// Removes a policy by matching the policy contract [policyAddress].
  ///
  /// Fetches the target rule, parses it, finds the policy index, and
  /// delegates to the ID-based [removePolicy] form. The `ByAddress` suffix
  /// distinguishes this from the ID-based form (Dart has no
  /// overload-by-parameter-type).
  ///
  /// Parameters:
  ///
  /// - [contextRuleId]: on-chain id of the rule the policy is on.
  /// - [policyAddress]: policy contract C-address; matched against the
  ///   rule's installed policies.
  /// - [selectedSigners]: empty routes the single-signer passkey path;
  ///   non-empty routes the multi-signer pipeline.
  /// - [forceMethod]: overrides direct-vs-relayer submission.
  Future<OZTransactionResult> removePolicyByAddress({
    required int contextRuleId,
    required String policyAddress,
    List<OZSelectedSigner> selectedSigners = const <OZSelectedSigner>[],
    OZSubmissionMethod? forceMethod,
  }) async {
    requireContractAddress(policyAddress, fieldName: 'policyAddress');

    final ruleScVal = await _kit.contextRuleManager.getContextRule(
      contextRuleId,
    );
    final rule = _kit.contextRuleManager.parseContextRule(ruleScVal);

    final policyIndex = rule.policies.indexOf(policyAddress);
    if (policyIndex == -1) {
      throw SmartAccountValidationException.invalidInput(
        'policyAddress',
        'Policy $policyAddress not found on context rule $contextRuleId',
      );
    }

    if (policyIndex >= rule.policyIds.length) {
      throw SmartAccountValidationException.invalidInput(
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
  ///
  /// Parameters:
  ///
  /// - [contextRuleId]: on-chain id of the rule the policy is installed on.
  /// - [policyAddress]: policy contract C-address.
  /// - [installParams]: the policy's installation parameters as an
  ///   [OZPolicyInstallParams]. Use a typed subclass such as
  ///   [OZSimpleThresholdPolicyParams], or [OZRawPolicyParams] to wrap a
  ///   pre-encoded [XdrSCVal] for custom policies.
  /// - [selectedSigners]: empty routes the single-signer passkey path;
  ///   non-empty routes the multi-signer pipeline.
  /// - [forceMethod]: overrides direct-vs-relayer submission.
  ///
  /// ```dart
  /// await kit.policyManager.addPolicy(
  ///   contextRuleId: 0,
  ///   policyAddress: policyContractId,
  ///   installParams: OZSimpleThresholdPolicyParams(threshold: 2),
  /// );
  /// ```
  Future<OZTransactionResult> addPolicy({
    required int contextRuleId,
    required String policyAddress,
    required OZPolicyInstallParams installParams,
    List<OZSelectedSigner> selectedSigners = const <OZSelectedSigner>[],
    OZSubmissionMethod? forceMethod,
  }) async {
    final connected = await _kit.requireConnected();
    requireContractAddress(policyAddress, fieldName: 'policyAddress');

    final hostFunction = _buildAddPolicyFunction(
      contractId: connected.contractId,
      contextRuleId: contextRuleId,
      policyAddress: policyAddress,
      installParams: installParams.toScVal(),
    );

    return ozRouteSubmission(_kit as OZSmartAccountWalletKitInterface, hostFunction, selectedSigners, forceMethod);
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

  // -------------------------------------------------------------------------
  // Static ScMap key-sort helpers
  // -------------------------------------------------------------------------

  /// Sorts a list of [XdrSCMapEntry] entries into the Soroban host's ScMap
  /// key order.
  ///
  /// The host stores and validates ScMap keys in a semantic order (see
  /// `compareScValHostOrder`) and rejects a map materialized from an
  /// out-of-order `SCVal` argument. Used by
  /// [OZWeightedThresholdPolicyParams.toScVal] and by [policiesToScVal]
  /// when sorting the policies map.
  static List<XdrSCMapEntry> sortMapByKeyXdr(List<XdrSCMapEntry> entries) {
    final sorted = List<XdrSCMapEntry>.from(entries);
    sorted.sort((a, b) => compareScValHostOrder(a.key, b.key));
    return sorted;
  }

  /// Encodes a policies map (policy contract address -> install-param
  /// `ScVal`) into the ScMap [XdrSCVal] the smart-account contract expects:
  /// keys become contract Addresses and entries are sorted into the host's
  /// ScMap key order.
  static XdrSCVal policiesToScVal(Map<String, XdrSCVal> policies) {
    final entries = <XdrSCMapEntry>[];
    for (final entry in policies.entries) {
      entries.add(
        XdrSCMapEntry(
          XdrSCVal.forAddress(Address.forContractId(entry.key).toXdr()),
          entry.value,
        ),
      );
    }
    return XdrSCVal.forMap(sortMapByKeyXdr(entries));
  }

  /// Encodes a single [XdrSCVal] to its XDR byte representation. Backs
  /// [OZRawPolicyParams] value equality and hashing, and is used by tests
  /// comparing encoded key order.
  static List<int> scValToXdrBytes(XdrSCVal scVal) {
    final stream = XdrDataOutputStream();
    XdrSCVal.encode(stream, scVal);
    return stream.bytes;
  }
}
