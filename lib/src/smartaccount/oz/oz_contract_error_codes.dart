// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

/// A decoded OpenZeppelin smart-account contract error: its numeric [code],
/// the contract error enum it belongs to ([contract]), and the [name] of the
/// variant, exactly as declared by the deployed contracts. Variant names
/// repeat across the policy enums (for example `NotAllowed`), so [contract]
/// is required to disambiguate; [code] is globally unique.
class OZContractError {
  /// Constructs a decoded contract error from its [code], defining
  /// [contract] enum, and variant [name].
  const OZContractError(this.code, this.contract, this.name);

  /// The numeric contract error code (for example `3016`).
  final int code;

  /// The contract error enum the code belongs to (for example
  /// `SmartAccountError`).
  final String contract;

  /// The variant name inside [contract] (for example `UnauthorizedSigner`).
  final String name;

  @override
  bool operator ==(Object other) =>
      other is OZContractError &&
      other.code == code &&
      other.contract == contract &&
      other.name == name;

  @override
  int get hashCode => Object.hash(code, contract, name);

  @override
  String toString() =>
      'OZContractError(code: $code, contract: $contract, name: $name)';
}

/// Contract-level error codes from the OpenZeppelin smart account, WebAuthn
/// verifier, and policy contracts.
///
/// When a contract rejects a call, the code appears inside the message of a
/// `SmartAccountTransactionException` (for example `Error(Contract, #3016)`).
/// The SDK surfaces the raw error but does not parse or map contract error
/// codes itself; callers can extract the code from the message and compare it
/// against these constants, or resolve it with the consumer-side [decode] and
/// [decodeFromMessage] helpers.
///
/// The named constants below cover the smart account contract's own error
/// enum — the codes a caller is most likely to branch on. [decode] resolves
/// any known code (smart account, WebAuthn, or a policy contract) into its
/// contract and variant name.
class OZContractErrorCodes {
  OZContractErrorCodes._(); // coverage:ignore-line

  // Smart account contract (SmartAccountError, codes 3000-3016; 3001 is
  // unused).

  /// The referenced context rule does not exist on the account.
  static const int contextRuleNotFound = 3000;

  /// The invocation context could not be validated against the account's
  /// context rules.
  static const int unvalidatedContext = 3002;

  /// An external signer's verifier contract rejected the signature.
  static const int externalVerificationFailed = 3003;

  /// A context rule must have at least one signer or one policy.
  static const int noSignersAndPolicies = 3004;

  /// The context rule's `valid_until` ledger has already passed.
  static const int pastValidUntil = 3005;

  /// The referenced signer is not present on the context rule.
  static const int signerNotFound = 3006;

  /// The signer is already present on the context rule.
  static const int duplicateSigner = 3007;

  /// The referenced policy is not installed on the context rule.
  static const int policyNotFound = 3008;

  /// The policy is already installed on the context rule.
  static const int duplicatePolicy = 3009;

  /// The context rule exceeds the maximum number of signers.
  static const int tooManySigners = 3010;

  /// The context rule exceeds the maximum number of policies.
  static const int tooManyPolicies = 3011;

  /// Integer arithmetic overflow occurred in the contract.
  static const int mathOverflow = 3012;

  /// The `key_data` field on a signer exceeds the maximum allowed size.
  static const int keyDataTooLarge = 3013;

  /// The number of context-rule IDs in the auth payload does not match the
  /// expected count.
  static const int contextRuleIdsLengthMismatch = 3014;

  /// A name field (e.g. context-rule name) exceeds the maximum allowed length.
  static const int nameTooLong = 3015;

  /// The signer is not authorised to sign the given context rule.
  static const int unauthorizedSigner = 3016;

  /// Decodes a raw contract error [code] into the OZ contract and variant
  /// name that defined it, or `null` if [code] is not a known OZ
  /// smart-account contract error.
  static OZContractError? decode(int code) => _codeTable[code];

  /// Extracts and decodes the first known contract error code from an error
  /// [message].
  ///
  /// Soroban RPC surfaces contract failures as `Error(Contract, #NNNN)`
  /// inside simulation and submission error strings (typically the message
  /// of a thrown `SmartAccountTransactionException`). This scans the message
  /// for such markers and returns the first one whose code is a known OZ
  /// smart-account contract error, or `null` when the message is null,
  /// carries no marker, or carries only unknown codes.
  static OZContractError? decodeFromMessage(String? message) {
    if (message == null) return null;
    for (final match in _contractErrorRegex.allMatches(message)) {
      final code = int.tryParse(match.group(1)!);
      if (code == null) continue;
      final decoded = decode(code);
      if (decoded != null) return decoded;
    }
    return null;
  }

  static final RegExp _contractErrorRegex =
      RegExp(r'Error\s*\(\s*Contract\s*,\s*#(\d+)\s*\)');

  static const List<OZContractError> _allErrors = <OZContractError>[
    // SmartAccountError (3000-3016; 3001 unused)
    OZContractError(3000, 'SmartAccountError', 'ContextRuleNotFound'),
    OZContractError(3002, 'SmartAccountError', 'UnvalidatedContext'),
    OZContractError(3003, 'SmartAccountError', 'ExternalVerificationFailed'),
    OZContractError(3004, 'SmartAccountError', 'NoSignersAndPolicies'),
    OZContractError(3005, 'SmartAccountError', 'PastValidUntil'),
    OZContractError(3006, 'SmartAccountError', 'SignerNotFound'),
    OZContractError(3007, 'SmartAccountError', 'DuplicateSigner'),
    OZContractError(3008, 'SmartAccountError', 'PolicyNotFound'),
    OZContractError(3009, 'SmartAccountError', 'DuplicatePolicy'),
    OZContractError(3010, 'SmartAccountError', 'TooManySigners'),
    OZContractError(3011, 'SmartAccountError', 'TooManyPolicies'),
    OZContractError(3012, 'SmartAccountError', 'MathOverflow'),
    OZContractError(3013, 'SmartAccountError', 'KeyDataTooLarge'),
    OZContractError(3014, 'SmartAccountError', 'ContextRuleIdsLengthMismatch'),
    OZContractError(3015, 'SmartAccountError', 'NameTooLong'),
    OZContractError(3016, 'SmartAccountError', 'UnauthorizedSigner'),
    // WebAuthnError (3110-3119)
    OZContractError(3110, 'WebAuthnError', 'SignaturePayloadInvalid'),
    OZContractError(3111, 'WebAuthnError', 'ClientDataTooLong'),
    OZContractError(3112, 'WebAuthnError', 'JsonParseError'),
    OZContractError(3113, 'WebAuthnError', 'TypeFieldInvalid'),
    OZContractError(3114, 'WebAuthnError', 'ChallengeInvalid'),
    OZContractError(3115, 'WebAuthnError', 'AuthDataFormatInvalid'),
    OZContractError(3116, 'WebAuthnError', 'PresentBitNotSet'),
    OZContractError(3117, 'WebAuthnError', 'VerifiedBitNotSet'),
    OZContractError(3118, 'WebAuthnError', 'BackupEligibilityAndStateNotSet'),
    OZContractError(3119, 'WebAuthnError', 'KeyDataInvalid'),
    // SimpleThresholdError (3200-3203)
    OZContractError(3200, 'SimpleThresholdError', 'SmartAccountNotInstalled'),
    OZContractError(3201, 'SimpleThresholdError', 'InvalidThreshold'),
    OZContractError(3202, 'SimpleThresholdError', 'NotAllowed'),
    OZContractError(3203, 'SimpleThresholdError', 'AlreadyInstalled'),
    // WeightedThresholdError (3210-3214)
    OZContractError(3210, 'WeightedThresholdError', 'SmartAccountNotInstalled'),
    OZContractError(3211, 'WeightedThresholdError', 'InvalidThreshold'),
    OZContractError(3212, 'WeightedThresholdError', 'MathOverflow'),
    OZContractError(3213, 'WeightedThresholdError', 'NotAllowed'),
    OZContractError(3214, 'WeightedThresholdError', 'AlreadyInstalled'),
    // SpendingLimitError (3220-3227)
    OZContractError(3220, 'SpendingLimitError', 'SmartAccountNotInstalled'),
    OZContractError(3221, 'SpendingLimitError', 'SpendingLimitExceeded'),
    OZContractError(3222, 'SpendingLimitError', 'InvalidLimitOrPeriod'),
    OZContractError(3223, 'SpendingLimitError', 'NotAllowed'),
    OZContractError(3224, 'SpendingLimitError', 'HistoryCapacityExceeded'),
    OZContractError(3225, 'SpendingLimitError', 'AlreadyInstalled'),
    OZContractError(3226, 'SpendingLimitError', 'LessThanZero'),
    OZContractError(3227, 'SpendingLimitError', 'OnlyCallContractAllowed'),
  ];

  static final Map<int, OZContractError> _codeTable =
      <int, OZContractError>{
    for (final error in _allErrors) error.code: error,
  };
}
