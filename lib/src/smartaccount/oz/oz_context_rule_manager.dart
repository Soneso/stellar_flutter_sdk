// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../../soroban/soroban_auth.dart';
import '../../xdr/xdr.dart';
import '../core/smart_account_errors.dart';
import 'oz_address_strkey.dart';
import 'oz_builders.dart';
import 'oz_constants.dart';
import 'oz_internal_pipeline_interfaces.dart';
import 'oz_policy_manager.dart';
import 'oz_selected_signer.dart';
import 'oz_smart_account_builders.dart';
import 'oz_smart_account_types.dart';
import 'oz_transaction_operations.dart';
import 'oz_validation.dart';

/// Manages context rules on OpenZeppelin smart accounts.
///
/// Context rules define the authorisation requirements for different
/// transaction shapes. A rule pairs a [ContextRuleType] match (default,
/// call-contract, or create-contract) with a signer list and a policy
/// list. When a transaction matches a rule, the smart account
/// authorises it only if the rule's signer and policy requirements
/// are met.
///
/// Contract limits:
///
/// - Maximum 15 signers per rule.
/// - Maximum 5 policies per rule.
///
/// State-changing methods accept an optional [SelectedSigner] list to
/// route through the multi-signer pipeline; an empty list routes
/// through the single-signer path that the connected passkey signs.
class OZContextRuleManager implements OZContextRuleManagerInterface {
  /// Constructs a context-rule manager bound to the supplied kit.
  /// Marked [internal] because consumers reach the manager via
  /// `kit.contextRuleManager`.
  @internal
  OZContextRuleManager(this._kit);

  final OZSmartAccountKitInterface _kit;

  // -------------------------------------------------------------------------
  // Add context rule
  // -------------------------------------------------------------------------

  /// Adds a new context rule.
  ///
  /// Validates the inputs, builds an
  /// `add_context_rule(context_type, name, valid_until, signers,
  /// policies)` invocation, and routes through the single-signer or
  /// multi-signer pipeline.
  ///
  /// Throws [InvalidInput] when [name] is empty, when [signers] and
  /// [policies] are both empty, when [signers] exceeds
  /// [OZConstants.maxSigners], when [policies] exceeds
  /// [OZConstants.maxPolicies], or when any policy address is invalid.
  Future<TransactionResult> addContextRule({
    required ContextRuleType contextType,
    required String name,
    int? validUntil,
    required List<OZSmartAccountSigner> signers,
    Map<String, XdrSCVal> policies = const <String, XdrSCVal>{},
    List<SelectedSigner> selectedSigners = const <SelectedSigner>[],
    SubmissionMethod? forceMethod,
  }) async {
    final connected = _kit.requireConnected();

    if (name.isEmpty) {
      throw ValidationException.invalidInput(
        'name',
        'Context rule name cannot be empty',
      );
    }

    if (signers.isEmpty && policies.isEmpty) {
      throw ValidationException.invalidInput(
        'signers',
        'Context rule must have at least one signer or one policy',
      );
    }

    if (signers.length > OZConstants.maxSigners) {
      throw ValidationException.invalidInput(
        'signers',
        'Context rule cannot have more than ${OZConstants.maxSigners} '
            'signers, got: ${signers.length}',
      );
    }

    if (policies.length > OZConstants.maxPolicies) {
      throw ValidationException.invalidInput(
        'policies',
        'Context rule cannot have more than ${OZConstants.maxPolicies} '
            'policies, got: ${policies.length}',
      );
    }

    for (final address in policies.keys) {
      requireContractAddress(address, fieldName: 'contractAddress');
    }

    final contextTypeScVal = contextType.toScVal();
    final nameScVal = XdrSCVal.forString(name);

    final XdrSCVal validUntilScVal = validUntil != null
        ? XdrSCVal.forU32(validUntil)
        : XdrSCVal.forVoid();

    final signersScVal = XdrSCVal.forVec(
      signers.map((s) => s.toScVal()).toList(growable: false),
    );

    final policiesEntries = <XdrSCMapEntry>[];
    for (final entry in policies.entries) {
      policiesEntries.add(
        XdrSCMapEntry(
          XdrSCVal.forAddress(
            Address.forContractId(entry.key).toXdr(),
          ),
          entry.value,
        ),
      );
    }
    final sortedPoliciesEntries =
        OZPolicyManager.sortMapByKeyXdr(policiesEntries);
    final policiesScVal = XdrSCVal.forMap(sortedPoliciesEntries);

    final functionArgs = <XdrSCVal>[
      contextTypeScVal,
      nameScVal,
      validUntilScVal,
      signersScVal,
      policiesScVal,
    ];

    final hostFunction = XdrHostFunction.forInvokingContractWithArgs(
      XdrInvokeContractArgs(
        Address.forContractId(connected.contractId).toXdr(),
        'add_context_rule',
        functionArgs,
      ),
    );

    return _route(hostFunction, selectedSigners, forceMethod);
  }

  // -------------------------------------------------------------------------
  // Read methods
  // -------------------------------------------------------------------------

  /// Retrieves a single context rule by its on-chain [id].
  ///
  /// Issues a simulated `get_context_rule(id)` invocation and returns
  /// the raw `ScVal` response. Use [parseContextRule] to translate the
  /// response into a [ParsedContextRule].
  @override
  Future<XdrSCVal> getContextRule(int id) async {
    final connected = _kit.requireConnected();

    final hostFunction = XdrHostFunction.forInvokingContractWithArgs(
      XdrInvokeContractArgs(
        Address.forContractId(connected.contractId).toXdr(),
        'get_context_rule',
        <XdrSCVal>[XdrSCVal.forU32(id)],
      ),
    );

    final transactionOps =
        (_kit as OZSmartAccountWalletKitInterface).transactionOperations;
    return transactionOps.simulateAndExtractResult(hostFunction);
  }

  /// Returns the count of currently active context rules on the
  /// connected smart account.
  Future<int> getContextRulesCount() async {
    final connected = _kit.requireConnected();

    final hostFunction = XdrHostFunction.forInvokingContractWithArgs(
      XdrInvokeContractArgs(
        Address.forContractId(connected.contractId).toXdr(),
        'get_context_rules_count',
        const <XdrSCVal>[],
      ),
    );

    final transactionOps =
        (_kit as OZSmartAccountWalletKitInterface).transactionOperations;
    final resultScVal = await transactionOps.simulateAndExtractResult(
      hostFunction,
    );

    final u32 = resultScVal.u32;
    if (u32 == null) {
      throw ValidationException.invalidInput(
        'result',
        'Expected U32 result from get_context_rules_count, got: $resultScVal',
      );
    }
    return u32.uint32;
  }

  /// Iterates monotonic on-chain IDs, returning the raw `ScVal`
  /// representation of every currently-active context rule. Stops as
  /// soon as the resolved count equals the on-chain reported active
  /// count. Removed-rule gaps are skipped via `try/catch` on simulation
  /// failure.
  @override
  Future<List<XdrSCVal>> getAllContextRules({int? maxScanId}) async {
    final scanLimit = maxScanId ?? _kit.config.maxContextRuleScanId;
    final activeCount = await getContextRulesCount();
    if (activeCount == 0) return const <XdrSCVal>[];

    final result = <XdrSCVal>[];
    for (var id = 0; id < scanLimit; id++) {
      if (result.length >= activeCount) break;
      try {
        final ruleScVal = await getContextRule(id);
        result.add(ruleScVal);
      } on TransactionSimulationFailed {
        // why: removed-rule gaps surface as simulation failures. Other
        // transaction failures must continue to propagate, hence the
        // narrow catch.
      }
    }
    return result;
  }

  /// Lists every active context rule, parsed into [ParsedContextRule]
  /// instances. Fetches the rules via [getAllContextRules] and translates
  /// each one through [parseContextRule].
  @override
  Future<List<ParsedContextRule>> listContextRules({int? maxScanId}) async {
    final raw = await getAllContextRules(maxScanId: maxScanId);
    return raw
        .map((scVal) => parseContextRule(scVal))
        .toList(growable: false);
  }

  // -------------------------------------------------------------------------
  // Parse context rule (inline; per D-103 not split into a separate file)
  // -------------------------------------------------------------------------

  /// Parses a raw `ScVal` context-rule struct into a typed
  /// [ParsedContextRule]. Exposed via the interface for sibling
  /// managers (signer manager, policy manager) that resolve value-form
  /// signers and policies to on-chain numeric IDs.
  ///
  /// The Soroban named-struct serialises as `ScVal::Map` with
  /// Symbol-keyed entries; fields are looked up by key name, not
  /// position. Expected keys (alphabetical): `context_type`, `id`,
  /// `name`, `policies`, `policy_ids`, `signer_ids`, `signers`,
  /// `valid_until`.
  @override
  ParsedContextRule parseContextRule(XdrSCVal scVal) {
    final mapEntries = scVal.map;
    if (mapEntries == null) {
      throw ValidationException.invalidInput(
        'contextRule',
        'Expected Map ScVal for context rule',
      );
    }

    final fields = <String, XdrSCVal>{};
    for (final entry in mapEntries) {
      final keySymbol = entry.key.sym;
      if (keySymbol == null) continue;
      fields[keySymbol] = entry.val;
    }

    final idField = fields['id'];
    if (idField == null) {
      throw ValidationException.invalidInput(
        'contextRule',
        'Missing required field: id',
      );
    }
    final id = _expectU32(idField, fieldName: 'id');

    final nameField = fields['name'];
    if (nameField == null) {
      throw ValidationException.invalidInput(
        'contextRule',
        'Missing required field: name',
      );
    }
    final name = nameField.str;
    if (name == null) {
      throw ValidationException.invalidInput(
        'name',
        'Expected String for name, got: $nameField',
      );
    }

    final contextTypeField = fields['context_type'];
    if (contextTypeField == null) {
      throw ValidationException.invalidInput(
        'contextRule',
        'Missing required field: context_type',
      );
    }
    final contextType = _parseContextRuleType(contextTypeField);

    final signers = _parseSignersVec(fields['signers']);
    final signerIds = _parseU32Vec(fields['signer_ids'], fieldName: 'signer_ids');
    final policies = _parseAddressVec(fields['policies'], fieldName: 'policies');
    final policyIds = _parseU32Vec(fields['policy_ids'], fieldName: 'policy_ids');

    int? validUntil;
    final validUntilField = fields['valid_until'];
    if (validUntilField != null) {
      if (validUntilField.discriminant == XdrSCValType.SCV_VOID) {
        validUntil = null;
      } else {
        validUntil = _expectU32(validUntilField, fieldName: 'valid_until');
      }
    }

    return ParsedContextRule(
      id: id,
      contextType: contextType,
      name: name,
      signers: signers,
      signerIds: signerIds,
      policies: policies,
      policyIds: policyIds,
      validUntil: validUntil,
    );
  }

  ContextRuleType _parseContextRuleType(XdrSCVal scVal) {
    final vec = scVal.vec;
    if (vec == null) {
      throw ValidationException.invalidInput(
        'context_type',
        'Expected Vec for context_type, got: $scVal',
      );
    }
    if (vec.isEmpty) {
      throw ValidationException.invalidInput(
        'context_type',
        'context_type Vec is empty',
      );
    }
    final discriminant = vec[0].sym;
    if (discriminant == null) {
      throw ValidationException.invalidInput(
        'context_type',
        'Expected Symbol discriminant in context_type Vec',
      );
    }
    switch (discriminant) {
      case 'Default':
        return const ContextRuleTypeDefault();
      case 'CallContract':
        if (vec.length < 2) {
          throw ValidationException.invalidInput(
            'context_type',
            'CallContract context_type missing address element',
          );
        }
        final addressXdr = vec[1].address;
        if (addressXdr == null) {
          throw ValidationException.invalidInput(
            'context_type',
            'Expected Address for CallContract context_type',
          );
        }
        return ContextRuleTypeCallContract(
          OZAddressStrKey.fromXdrOrEmpty(addressXdr),
        );
      case 'CreateContract':
        if (vec.length < 2) {
          throw ValidationException.invalidInput(
            'context_type',
            'CreateContract context_type missing wasm hash element',
          );
        }
        final bytes = vec[1].bytes;
        if (bytes == null) {
          throw ValidationException.invalidInput(
            'context_type',
            'Expected Bytes for CreateContract context_type',
          );
        }
        return ContextRuleTypeCreateContract(
          Uint8List.fromList(bytes.sCBytes),
        );
      default:
        throw ValidationException.invalidInput(
          'context_type',
          'Unknown context_type discriminant: $discriminant',
        );
    }
  }

  OZSmartAccountSigner _parseSigner(XdrSCVal scVal) {
    final vec = scVal.vec;
    if (vec == null) {
      throw ValidationException.invalidInput(
        'signer',
        'Expected Vec for signer, got: $scVal',
      );
    }
    if (vec.isEmpty) {
      throw ValidationException.invalidInput(
        'signer',
        'Signer Vec is empty',
      );
    }
    final discriminant = vec[0].sym;
    if (discriminant == null) {
      throw ValidationException.invalidInput(
        'signer',
        'Expected Symbol discriminant in signer Vec',
      );
    }
    switch (discriminant) {
      case 'Delegated':
        if (vec.length < 2) {
          throw ValidationException.invalidInput(
            'signer',
            'Delegated signer missing address element',
          );
        }
        final addressXdr = vec[1].address;
        if (addressXdr == null) {
          throw ValidationException.invalidInput(
            'signer',
            'Expected Address for Delegated signer',
          );
        }
        return OZDelegatedSigner(
          OZAddressStrKey.fromXdrOrEmpty(addressXdr),
        );
      case 'External':
        if (vec.length < 3) {
          throw ValidationException.invalidInput(
            'signer',
            'External signer missing address or keyData element',
          );
        }
        final verifierAddressXdr = vec[1].address;
        if (verifierAddressXdr == null) {
          throw ValidationException.invalidInput(
            'signer',
            'Expected Address for External signer verifier',
          );
        }
        final keyDataBytes = vec[2].bytes;
        if (keyDataBytes == null) {
          throw ValidationException.invalidInput(
            'signer',
            'Expected Bytes for External signer keyData',
          );
        }
        return OZExternalSigner(
          OZAddressStrKey.fromXdrOrEmpty(verifierAddressXdr),
          Uint8List.fromList(keyDataBytes.sCBytes),
        );
      default:
        throw ValidationException.invalidInput(
          'signer',
          'Unknown signer discriminant: $discriminant',
        );
    }
  }

  List<OZSmartAccountSigner> _parseSignersVec(XdrSCVal? field) {
    if (field == null) return const <OZSmartAccountSigner>[];
    final vec = field.vec;
    if (vec == null) {
      throw ValidationException.invalidInput(
        'signers',
        'Expected Vec for signers, got: $field',
      );
    }
    return vec.map(_parseSigner).toList(growable: false);
  }

  List<int> _parseU32Vec(XdrSCVal? field, {required String fieldName}) {
    if (field == null) return const <int>[];
    final vec = field.vec;
    if (vec == null) {
      throw ValidationException.invalidInput(
        fieldName,
        'Expected Vec for $fieldName, got: $field',
      );
    }
    return vec
        .map((entry) => _expectU32(entry, fieldName: fieldName))
        .toList(growable: false);
  }

  List<String> _parseAddressVec(XdrSCVal? field, {required String fieldName}) {
    if (field == null) return const <String>[];
    final vec = field.vec;
    if (vec == null) {
      throw ValidationException.invalidInput(
        fieldName,
        'Expected Vec for $fieldName, got: $field',
      );
    }
    return vec.map((entry) {
      final addressXdr = entry.address;
      if (addressXdr == null) {
        throw ValidationException.invalidInput(
          fieldName,
          'Expected Address entries in $fieldName',
        );
      }
      return OZAddressStrKey.fromXdrOrEmpty(addressXdr);
    }).toList(growable: false);
  }

  int _expectU32(XdrSCVal scVal, {required String fieldName}) {
    final u32 = scVal.u32;
    if (u32 == null) {
      throw ValidationException.invalidInput(
        fieldName,
        'Expected U32 for $fieldName, got: $scVal',
      );
    }
    return u32.uint32;
  }

  // -------------------------------------------------------------------------
  // Update operations
  // -------------------------------------------------------------------------

  /// Updates the human-readable name of a context rule.
  Future<TransactionResult> updateName({
    required int id,
    required String name,
    List<SelectedSigner> selectedSigners = const <SelectedSigner>[],
    SubmissionMethod? forceMethod,
  }) async {
    final connected = _kit.requireConnected();

    if (name.isEmpty) {
      throw ValidationException.invalidInput(
        'name',
        'Context rule name cannot be empty',
      );
    }

    final hostFunction = XdrHostFunction.forInvokingContractWithArgs(
      XdrInvokeContractArgs(
        Address.forContractId(connected.contractId).toXdr(),
        'update_context_rule_name',
        <XdrSCVal>[XdrSCVal.forU32(id), XdrSCVal.forString(name)],
      ),
    );

    return _route(hostFunction, selectedSigners, forceMethod);
  }

  /// Updates the expiration ledger of a context rule. Pass `null` to
  /// remove the expiration (encoded on-chain as `Option::None`).
  Future<TransactionResult> updateValidUntil({
    required int id,
    int? validUntil,
    List<SelectedSigner> selectedSigners = const <SelectedSigner>[],
    SubmissionMethod? forceMethod,
  }) async {
    final connected = _kit.requireConnected();

    final XdrSCVal validUntilScVal = validUntil != null
        ? XdrSCVal.forU32(validUntil)
        : XdrSCVal.forVoid();

    final hostFunction = XdrHostFunction.forInvokingContractWithArgs(
      XdrInvokeContractArgs(
        Address.forContractId(connected.contractId).toXdr(),
        'update_context_rule_valid_until',
        <XdrSCVal>[XdrSCVal.forU32(id), validUntilScVal],
      ),
    );

    return _route(hostFunction, selectedSigners, forceMethod);
  }

  /// Removes a context rule.
  Future<TransactionResult> removeContextRule({
    required int id,
    List<SelectedSigner> selectedSigners = const <SelectedSigner>[],
    SubmissionMethod? forceMethod,
  }) async {
    final connected = _kit.requireConnected();

    final hostFunction = XdrHostFunction.forInvokingContractWithArgs(
      XdrInvokeContractArgs(
        Address.forContractId(connected.contractId).toXdr(),
        'remove_context_rule',
        <XdrSCVal>[XdrSCVal.forU32(id)],
      ),
    );

    return _route(hostFunction, selectedSigners, forceMethod);
  }

  // -------------------------------------------------------------------------
  // Context-rule resolution (3-tier algorithm)
  // -------------------------------------------------------------------------

  /// Resolves the context-rule IDs that apply to [entry] under the
  /// supplied [signers]. Fetches the active rule list before delegating
  /// to the pre-fetched-rules overload.
  @override
  Future<List<int>> resolveContextRuleIdsForEntry(
    XdrSorobanAuthorizationEntry entry,
    List<OZSmartAccountSigner> signers,
    List<Object> contextRules,
  ) async {
    if (contextRules.isEmpty) {
      final rules = await listContextRules();
      return resolveContextRuleIdsForEntryWithRules(entry, signers, rules);
    }
    final parsed =
        contextRules.whereType<ParsedContextRule>().toList(growable: false);
    return resolveContextRuleIdsForEntryWithRules(entry, signers, parsed);
  }

  /// Synchronous 3-tier rule resolution against a pre-fetched
  /// [rules] list.
  ///
  /// Algorithm:
  ///
  /// - Build the list of [ContextRuleType]s from the auth entry's
  ///   invocation tree.
  /// - For each required type, filter the rules to those whose type
  ///   matches (Default matches anything; specific types require
  ///   equality).
  /// - If exactly one candidate remains, use it.
  /// - Tier 1: exact bidirectional signer-set match (same size, every
  ///   selected signer in rule, every rule signer in selected).
  /// - Tier 2: rule signers form a subset of selected, AND the rule
  ///   carries no policies.
  /// - Tier 3: selected signers form a subset of rule (threshold
  ///   scenarios where the user picks fewer signers than the rule).
  /// - When no candidates match, throw with the "Add a Default rule"
  ///   hint. When multiple candidates contain every selected signer,
  ///   throw with the matching-rule-id list.
  List<int> resolveContextRuleIdsForEntryWithRules(
    XdrSorobanAuthorizationEntry entry,
    List<OZSmartAccountSigner> selectedSigners,
    List<ParsedContextRule> rules,
  ) {
    final contexts = _buildInvocationContextTypes(entry);
    return contexts
        .map((contextType) =>
            _resolveSingleContext(contextType, selectedSigners, rules))
        .toList(growable: false);
  }

  /// Resolves a single context type by walking the 3-tier match
  /// hierarchy in order. Each tier helper returns the unique matching
  /// rule's id when there is exactly one candidate, or `null` to defer
  /// to the next tier. Disambiguation and "no match" diagnostics are
  /// emitted from the calling site once every tier has been exhausted.
  int _resolveSingleContext(
    ContextRuleType contextType,
    List<OZSmartAccountSigner> selectedSigners,
    List<ParsedContextRule> rules,
  ) {
    final candidates = rules
        .where((rule) => _contextRuleTypeMatches(rule.contextType, contextType))
        .toList(growable: false);

    if (candidates.length == 1) return candidates[0].id;

    final tier1 = _tier1Match(candidates, selectedSigners);
    if (tier1 != null) return tier1;

    final tier2 = _tier2Match(candidates, selectedSigners);
    if (tier2 != null) return tier2;

    final tier3 = _tier3Match(candidates, selectedSigners);
    if (tier3 != null) return tier3;

    if (candidates.isEmpty) {
      throw ValidationException.invalidInput(
        'contextRuleIds',
        'No context rule matches $contextType. Add a rule for this '
            'context type or a Default rule.',
      );
    }

    // Multiple candidates still contain all selected signers but none
    // matched the tiered constraints unambiguously — surface their ids
    // so the caller can pick a forced resolution.
    final allMatching =
        _candidatesContainingAllSelected(candidates, selectedSigners);
    if (allMatching.length > 1) {
      final ids = allMatching.map((r) => r.id.toString()).join(', ');
      throw ValidationException.invalidInput(
        'contextRuleIds',
        'Selected signers match multiple context rules: $ids.',
      );
    }

    throw ValidationException.invalidInput(
      'contextRuleIds',
      'No context rule contains all selected signers.',
    );
  }

  /// Tier 1: exact bidirectional signer-set match (same size, every
  /// selected signer in rule, every rule signer in selected).
  int? _tier1Match(
    List<ParsedContextRule> candidates,
    List<OZSmartAccountSigner> selectedSigners,
  ) {
    final matches = candidates.where((rule) {
      if (rule.signers.length != selectedSigners.length) return false;
      return _everySelectedInRule(rule, selectedSigners) &&
          _everyRuleSignerInSelected(rule, selectedSigners);
    }).toList(growable: false);
    return matches.length == 1 ? matches.first.id : null;
  }

  /// Tier 2: rule signers form a subset of selected, AND the rule
  /// carries no policies.
  int? _tier2Match(
    List<ParsedContextRule> candidates,
    List<OZSmartAccountSigner> selectedSigners,
  ) {
    final matches = candidates.where((rule) {
      if (rule.policies.isNotEmpty) return false;
      return _everyRuleSignerInSelected(rule, selectedSigners);
    }).toList(growable: false);
    return matches.length == 1 ? matches.first.id : null;
  }

  /// Tier 3: selected signers form a subset of rule (threshold
  /// scenarios where the user picks fewer signers than the rule).
  int? _tier3Match(
    List<ParsedContextRule> candidates,
    List<OZSmartAccountSigner> selectedSigners,
  ) {
    final matches = _candidatesContainingAllSelected(candidates, selectedSigners);
    return matches.length == 1 ? matches.first.id : null;
  }

  /// Predicate: every signer in [selectedSigners] is present in
  /// [rule.signers]. Used by Tier 1 and Tier 3.
  bool _everySelectedInRule(
    ParsedContextRule rule,
    List<OZSmartAccountSigner> selectedSigners,
  ) {
    return selectedSigners.every((selected) => rule.signers.any(
        (ruleSigner) =>
            OZSmartAccountBuilders.signersEqual(ruleSigner, selected)));
  }

  /// Predicate: every signer on the rule is present in
  /// [selectedSigners]. Used by Tier 1 and Tier 2.
  bool _everyRuleSignerInSelected(
    ParsedContextRule rule,
    List<OZSmartAccountSigner> selectedSigners,
  ) {
    return rule.signers.every((ruleSigner) => selectedSigners.any(
        (selected) =>
            OZSmartAccountBuilders.signersEqual(ruleSigner, selected)));
  }

  List<ParsedContextRule> _candidatesContainingAllSelected(
    List<ParsedContextRule> candidates,
    List<OZSmartAccountSigner> selectedSigners,
  ) {
    return candidates
        .where((rule) => _everySelectedInRule(rule, selectedSigners))
        .toList(growable: false);
  }

  // -------------------------------------------------------------------------
  // Invocation-tree walking
  // -------------------------------------------------------------------------

  List<ContextRuleType> _buildInvocationContextTypes(
    XdrSorobanAuthorizationEntry entry,
  ) {
    final result = <ContextRuleType>[];
    _collectInvocationContextTypes(entry.rootInvocation.function, result);
    _collectSubInvocationContextTypes(
      entry.rootInvocation.subInvocations,
      result,
    );
    return result;
  }

  void _collectInvocationContextTypes(
    XdrSorobanAuthorizedFunction function,
    List<ContextRuleType> result,
  ) {
    final discriminant = function.discriminant;
    switch (discriminant) {
      case XdrSorobanAuthorizedFunctionType
            .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN:
        final contractFn = function.contractFn;
        if (contractFn == null) return;
        result.add(ContextRuleTypeCallContract(
          OZAddressStrKey.fromXdrOrEmpty(contractFn.contractAddress),
        ));
        break;
      case XdrSorobanAuthorizedFunctionType
            .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CREATE_CONTRACT_HOST_FN:
        final createFn = function.createContractHostFn;
        if (createFn == null) return;
        final wasmHash = _extractWasmHash(createFn.executable);
        result.add(ContextRuleTypeCreateContract(wasmHash));
        break;
      case XdrSorobanAuthorizedFunctionType
            .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CREATE_CONTRACT_V2_HOST_FN:
        final createV2Fn = function.createContractV2HostFn;
        if (createV2Fn == null) return;
        final wasmHash = _extractWasmHash(createV2Fn.executable);
        result.add(ContextRuleTypeCreateContract(wasmHash));
        break;
    }
  }

  void _collectSubInvocationContextTypes(
    List<XdrSorobanAuthorizedInvocation> subInvocations,
    List<ContextRuleType> result,
  ) {
    for (final sub in subInvocations) {
      _collectInvocationContextTypes(sub.function, result);
      _collectSubInvocationContextTypes(sub.subInvocations, result);
    }
  }

  Uint8List _extractWasmHash(XdrContractExecutable executable) {
    final type = executable.type;
    switch (type) {
      case XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM:
        final hash = executable.wasmHash;
        if (hash == null) {
          throw ValidationException.invalidInput(
            'executable',
            'WASM contract executable is missing its hash',
          );
        }
        return Uint8List.fromList(hash.hash);
      case XdrContractExecutableType.CONTRACT_EXECUTABLE_STELLAR_ASSET:
        throw ValidationException.invalidInput(
          'executable',
          'CreateContract invocation references a Stellar Asset '
              'Contract, not a WASM contract',
        );
      default:
        throw ValidationException.invalidInput(
          'executable',
          'Unknown contract executable type: $type',
        );
    }
  }

  bool _contextRuleTypeMatches(
    ContextRuleType ruleType,
    ContextRuleType requiredType,
  ) {
    if (ruleType is ContextRuleTypeDefault) return true;
    return ruleType == requiredType;
  }

  // -------------------------------------------------------------------------
  // Routing helper
  // -------------------------------------------------------------------------

  Future<TransactionResult> _route(
    XdrHostFunction hostFunction,
    List<SelectedSigner> selectedSigners,
    SubmissionMethod? forceMethod,
  ) async {
    final transactionOps =
        (_kit as OZSmartAccountWalletKitInterface).transactionOperations;
    if (selectedSigners.isEmpty) {
      return transactionOps.submit(
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
}
