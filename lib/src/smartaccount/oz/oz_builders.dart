// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import '../../soroban/soroban_auth.dart';
import '../../util.dart';
import '../../xdr/xdr_sc_val.dart';
import '../core/smart_account_errors.dart';
import 'oz_smart_account_builders.dart';
import 'oz_smart_account_types.dart';
import 'oz_validation.dart';

/// Type of operations a context rule applies to.
///
/// Defines the matching criteria for a context rule, including default
/// catch-all behaviour, contract-specific calls, and contract-creation
/// patterns. Three matching types are supported:
///
/// - [OZContextRuleTypeDefault]: matches any operation that no other rule
///   matches.
/// - [OZContextRuleTypeCallContract]: matches invocations of a specific
///   contract address.
/// - [OZContextRuleTypeCreateContract]: matches contract deployments using a
///   specific WASM hash.
sealed class OZContextRuleType {
  const OZContextRuleType();

  /// Converts this rule type to its on-chain `ScVal` representation.
  ///
  /// The on-chain shape is:
  ///
  /// - [OZContextRuleTypeDefault]: `Vec([Symbol("Default")])`
  /// - [OZContextRuleTypeCallContract]:
  ///   `Vec([Symbol("CallContract"), Address(contractAddress)])`
  /// - [OZContextRuleTypeCreateContract]:
  ///   `Vec([Symbol("CreateContract"), Bytes(wasmHash)])`
  ///
  /// Throws an [SmartAccountInvalidAddress] validation exception when the contract
  /// address on a [OZContextRuleTypeCallContract] cannot be encoded.
  XdrSCVal toScVal() {
    final self = this;
    if (self is OZContextRuleTypeDefault) {
      return XdrSCVal.forVec([XdrSCVal.forSymbol('Default')]);
    }
    if (self is OZContextRuleTypeCallContract) {
      try {
        final scAddress = Address.forContractId(self.contractAddress).toXdr();
        return XdrSCVal.forVec([
          XdrSCVal.forSymbol('CallContract'),
          XdrSCVal.forAddress(scAddress),
        ]);
      } catch (e) {
        throw SmartAccountValidationException.invalidAddress(self.contractAddress,
            cause: e);
      }
    }
    if (self is OZContextRuleTypeCreateContract) {
      return XdrSCVal.forVec([
        XdrSCVal.forSymbol('CreateContract'),
        XdrSCVal.forBytes(self.wasmHash),
      ]);
    }
    throw StateError('Unhandled OZContextRuleType: $self');
  }
}

/// Matches any operation that does not match a more specific rule.
final class OZContextRuleTypeDefault extends OZContextRuleType {
  /// Constructs the default rule type.
  const OZContextRuleTypeDefault();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is OZContextRuleTypeDefault;

  @override
  int get hashCode => (OZContextRuleTypeDefault).hashCode;
}

/// Matches invocations targeting a specific contract address.
final class OZContextRuleTypeCallContract extends OZContextRuleType {
  /// Constructs a call-contract rule for [contractAddress] (a C-address).
  const OZContextRuleTypeCallContract(this.contractAddress);

  /// Contract address (C-address, 56 characters) the rule applies to.
  final String contractAddress;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OZContextRuleTypeCallContract &&
        other.contractAddress == contractAddress;
  }

  @override
  int get hashCode => contractAddress.hashCode;
}

/// Matches contract deployments using a specific WASM hash.
final class OZContextRuleTypeCreateContract extends OZContextRuleType {
  /// Constructs a create-contract rule for the given [wasmHash] (32 bytes).
  ///
  /// The bytes are copied so the caller may mutate the source buffer
  /// afterwards without affecting the rule.
  OZContextRuleTypeCreateContract(Uint8List wasmHash)
      : wasmHash = Uint8List.fromList(wasmHash);

  /// WASM hash (32 bytes) the rule matches against.
  final Uint8List wasmHash;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OZContextRuleTypeCreateContract) return false;
    if (other.wasmHash.length != wasmHash.length) return false;
    // why: constant-time byte comparison so a hash-prefix oracle cannot leak
    // through timing differences when comparing wasm-hash rules.
    return Util.constantTimeEquals(wasmHash, other.wasmHash);
  }

  @override
  int get hashCode {
    var result = 1;
    for (final b in wasmHash) {
      result = 31 * result + b;
    }
    return result;
  }
}

/// Parsed representation of a context rule loaded from on-chain storage.
///
/// Carries the rule's identifier, matching type, human-readable name, signer
/// and policy attachments, and an optional expiration ledger.
class OZParsedContextRule {
  /// Constructs a parsed context rule with all fields supplied.
  const OZParsedContextRule({
    required this.id,
    required this.contextType,
    required this.name,
    required this.signers,
    required this.signerIds,
    required this.policies,
    required this.policyIds,
    this.validUntil,
  });

  /// Unique identifier of this context rule.
  final int id;

  /// The matching type that determines which operations this rule applies
  /// to.
  final OZContextRuleType contextType;

  /// Human-readable name for the rule.
  final String name;

  /// Signers that can authorise operations matching this rule.
  final List<OZSmartAccountSigner> signers;

  /// Signer IDs positionally aligned with [signers].
  final List<int> signerIds;

  /// Policy contract addresses constraining matching operations.
  final List<String> policies;

  /// Policy IDs positionally aligned with [policies].
  final List<int> policyIds;

  /// Optional ledger number at which this rule expires; `null` means no
  /// expiration.
  final int? validUntil;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OZParsedContextRule) return false;
    return other.id == id &&
        other.contextType == contextType &&
        other.name == name &&
        _listEquals(other.signers, signers) &&
        _listEquals(other.signerIds, signerIds) &&
        _listEquals(other.policies, policies) &&
        _listEquals(other.policyIds, policyIds) &&
        other.validUntil == validUntil;
  }

  @override
  int get hashCode => Object.hash(
        id,
        contextType,
        name,
        Object.hashAll(signers),
        Object.hashAll(signerIds),
        Object.hashAll(policies),
        Object.hashAll(policyIds),
        validUntil,
      );

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Builder utilities for OpenZeppelin smart-account context rules.
///
/// Provides type-safe constructors for [OZContextRuleType] and helpers for
/// inspecting parsed rules. These functions are separated from
/// [OZSmartAccountBuilders] to keep core builder utilities free of
/// OZ-specific context-rule types.
class OZBuilders {
  OZBuilders._(); // coverage:ignore-line

  /// Creates a [OZContextRuleTypeDefault] rule.
  ///
  /// Default rules apply to any operation that does not match a more
  /// specific call-contract or create-contract rule.
  static OZContextRuleType createDefaultContext() {
    return const OZContextRuleTypeDefault();
  }

  /// Creates a [OZContextRuleTypeCallContract] rule for [contractAddress].
  ///
  /// Useful for restricting signers to specific dApps or operations.
  ///
  /// Throws an [SmartAccountInvalidAddress] validation exception when [contractAddress]
  /// is not a valid contract address.
  static OZContextRuleType createCallContractContext(String contractAddress) {
    requireContractAddress(contractAddress, fieldName: 'contractAddress');
    return OZContextRuleTypeCallContract(contractAddress);
  }

  /// Creates a [OZContextRuleTypeCreateContract] rule from a hex-encoded WASM
  /// hash.
  ///
  /// [wasmHashHex] may optionally be prefixed with `0x`. After stripping the
  /// prefix the string must be exactly 64 hex characters (32 bytes).
  ///
  /// Throws an [SmartAccountInvalidInput] validation exception when [wasmHashHex] is
  /// not the required length.
  static OZContextRuleType createCreateContractContextFromHex(
    String wasmHashHex,
  ) {
    final cleanHash =
        wasmHashHex.startsWith('0x') ? wasmHashHex.substring(2) : wasmHashHex;
    if (cleanHash.length != 64) {
      throw SmartAccountValidationException.invalidInput(
        'wasmHash',
        'WASM hash must be 32 bytes (64 hex characters), got: '
            '${cleanHash.length} characters',
      );
    }
    final hashBytes = Util.hexToBytes(cleanHash);
    return OZContextRuleTypeCreateContract(hashBytes);
  }

  /// Creates a [OZContextRuleTypeCreateContract] rule from raw WASM-hash
  /// bytes.
  ///
  /// [wasmHash] must be exactly 32 bytes long. Throws an [SmartAccountInvalidInput]
  /// validation exception otherwise.
  static OZContextRuleType createCreateContractContextFromBytes(
    Uint8List wasmHash,
  ) {
    if (wasmHash.length != 32) {
      throw SmartAccountValidationException.invalidInput(
        'wasmHash',
        'WASM hash must be 32 bytes, got: ${wasmHash.length}',
      );
    }
    return OZContextRuleTypeCreateContract(wasmHash);
  }

  /// Returns the unique signers from [rules], removing duplicates across
  /// rules.
  ///
  /// Iterates through each rule's signer list and delegates to
  /// [OZSmartAccountBuilders.collectUniqueSigners] for the deduplication
  /// pass; the first occurrence of each unique signer is preserved.
  static List<OZSmartAccountSigner> collectUniqueSignersFromRules(
    List<OZParsedContextRule> rules,
  ) {
    final allSigners = <OZSmartAccountSigner>[];
    for (final rule in rules) {
      allSigners.addAll(rule.signers);
    }
    return OZSmartAccountBuilders.collectUniqueSigners(allSigners);
  }
}
