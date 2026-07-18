import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

/// Decoding of OZ smart-account, WebAuthn, and policy contract error codes
/// into their defining contract and variant name.
void main() {
  group('OZContractErrorCodes', () {
    test('contract error codes are correct', () {
      expect(OZContractErrorCodes.mathOverflow, 3012);
      expect(OZContractErrorCodes.keyDataTooLarge, 3013);
      expect(OZContractErrorCodes.contextRuleIdsLengthMismatch, 3014);
      expect(OZContractErrorCodes.nameTooLong, 3015);
      expect(OZContractErrorCodes.unauthorizedSigner, 3016);
    });

    test('testConstants_smartAccountEnumComplete', () {
      expect(OZContractErrorCodes.contextRuleNotFound, 3000);
      expect(OZContractErrorCodes.unvalidatedContext, 3002);
      expect(OZContractErrorCodes.externalVerificationFailed, 3003);
      expect(OZContractErrorCodes.noSignersAndPolicies, 3004);
      expect(OZContractErrorCodes.pastValidUntil, 3005);
      expect(OZContractErrorCodes.signerNotFound, 3006);
      expect(OZContractErrorCodes.duplicateSigner, 3007);
      expect(OZContractErrorCodes.policyNotFound, 3008);
      expect(OZContractErrorCodes.duplicatePolicy, 3009);
      expect(OZContractErrorCodes.tooManySigners, 3010);
      expect(OZContractErrorCodes.tooManyPolicies, 3011);
    });

    test('testDecode_smartAccountCodes', () {
      expect(
        OZContractErrorCodes.decode(3000),
        const OZContractError(3000, 'SmartAccountError', 'ContextRuleNotFound'),
      );
      expect(
        OZContractErrorCodes.decode(3015),
        const OZContractError(3015, 'SmartAccountError', 'NameTooLong'),
      );
      expect(
        OZContractErrorCodes.decode(3016),
        const OZContractError(3016, 'SmartAccountError', 'UnauthorizedSigner'),
      );
    });

    test('testDecode_webAuthnCode', () {
      expect(
        OZContractErrorCodes.decode(3114),
        const OZContractError(3114, 'WebAuthnError', 'ChallengeInvalid'),
      );
      expect(
        OZContractErrorCodes.decode(3110),
        const OZContractError(3110, 'WebAuthnError', 'SignaturePayloadInvalid'),
      );
    });

    test('testDecode_policyCode', () {
      expect(
        OZContractErrorCodes.decode(3221),
        const OZContractError(
            3221, 'SpendingLimitError', 'SpendingLimitExceeded'),
      );
      expect(
        OZContractErrorCodes.decode(3227),
        const OZContractError(
            3227, 'SpendingLimitError', 'OnlyCallContractAllowed'),
      );
    });

    test('testDecode_repeatedNames_disambiguatedByContract', () {
      // "NotAllowed" appears in all three policy enums at distinct codes.
      expect(
          OZContractErrorCodes.decode(3202)?.contract, 'SimpleThresholdError');
      expect(OZContractErrorCodes.decode(3213)?.contract,
          'WeightedThresholdError');
      expect(
          OZContractErrorCodes.decode(3223)?.contract, 'SpendingLimitError');
      expect(OZContractErrorCodes.decode(3202)?.name, 'NotAllowed');
      expect(OZContractErrorCodes.decode(3213)?.name, 'NotAllowed');
      expect(OZContractErrorCodes.decode(3223)?.name, 'NotAllowed');

      // "MathOverflow" exists in both the smart account and
      // weighted-threshold enums.
      expect(
        OZContractErrorCodes.decode(3012),
        const OZContractError(3012, 'SmartAccountError', 'MathOverflow'),
      );
      expect(
        OZContractErrorCodes.decode(3212),
        const OZContractError(3212, 'WeightedThresholdError', 'MathOverflow'),
      );
    });

    test('testDecode_unusedAndGapCodes_returnNull', () {
      // 3001 is unused in SmartAccountError; the policy enums have gaps.
      expect(OZContractErrorCodes.decode(3001), isNull);
      expect(OZContractErrorCodes.decode(3204), isNull);
      expect(OZContractErrorCodes.decode(3215), isNull);
      expect(OZContractErrorCodes.decode(3120), isNull);
    });

    test('testDecode_outOfRangeCodes_returnNull', () {
      expect(OZContractErrorCodes.decode(0), isNull);
      expect(OZContractErrorCodes.decode(2999), isNull);
      expect(OZContractErrorCodes.decode(9999), isNull);
      expect(OZContractErrorCodes.decode(-1), isNull);
    });

    test('testConstants_matchDecodeTable', () {
      expect(OZContractErrorCodes.contextRuleNotFound, 3000);
      expect(OZContractErrorCodes.nameTooLong, 3015);
      expect(OZContractErrorCodes.unauthorizedSigner, 3016);
      expect(
        OZContractErrorCodes.decode(OZContractErrorCodes.nameTooLong)?.name,
        'NameTooLong',
      );
    });

    test('testDecode_fullTableMatchesContractEnums', () {
      // Independent transcription of the contract enums; a transposed name
      // or wrong contract in the production table fails here.
      const expected = <int, (String, String)>{
        3000: ('SmartAccountError', 'ContextRuleNotFound'),
        3002: ('SmartAccountError', 'UnvalidatedContext'),
        3003: ('SmartAccountError', 'ExternalVerificationFailed'),
        3004: ('SmartAccountError', 'NoSignersAndPolicies'),
        3005: ('SmartAccountError', 'PastValidUntil'),
        3006: ('SmartAccountError', 'SignerNotFound'),
        3007: ('SmartAccountError', 'DuplicateSigner'),
        3008: ('SmartAccountError', 'PolicyNotFound'),
        3009: ('SmartAccountError', 'DuplicatePolicy'),
        3010: ('SmartAccountError', 'TooManySigners'),
        3011: ('SmartAccountError', 'TooManyPolicies'),
        3012: ('SmartAccountError', 'MathOverflow'),
        3013: ('SmartAccountError', 'KeyDataTooLarge'),
        3014: ('SmartAccountError', 'ContextRuleIdsLengthMismatch'),
        3015: ('SmartAccountError', 'NameTooLong'),
        3016: ('SmartAccountError', 'UnauthorizedSigner'),
        3110: ('WebAuthnError', 'SignaturePayloadInvalid'),
        3111: ('WebAuthnError', 'ClientDataTooLong'),
        3112: ('WebAuthnError', 'JsonParseError'),
        3113: ('WebAuthnError', 'TypeFieldInvalid'),
        3114: ('WebAuthnError', 'ChallengeInvalid'),
        3115: ('WebAuthnError', 'AuthDataFormatInvalid'),
        3116: ('WebAuthnError', 'PresentBitNotSet'),
        3117: ('WebAuthnError', 'VerifiedBitNotSet'),
        3118: ('WebAuthnError', 'BackupEligibilityAndStateNotSet'),
        3119: ('WebAuthnError', 'KeyDataInvalid'),
        3200: ('SimpleThresholdError', 'SmartAccountNotInstalled'),
        3201: ('SimpleThresholdError', 'InvalidThreshold'),
        3202: ('SimpleThresholdError', 'NotAllowed'),
        3203: ('SimpleThresholdError', 'AlreadyInstalled'),
        3210: ('WeightedThresholdError', 'SmartAccountNotInstalled'),
        3211: ('WeightedThresholdError', 'InvalidThreshold'),
        3212: ('WeightedThresholdError', 'MathOverflow'),
        3213: ('WeightedThresholdError', 'NotAllowed'),
        3214: ('WeightedThresholdError', 'AlreadyInstalled'),
        3220: ('SpendingLimitError', 'SmartAccountNotInstalled'),
        3221: ('SpendingLimitError', 'SpendingLimitExceeded'),
        3222: ('SpendingLimitError', 'InvalidLimitOrPeriod'),
        3223: ('SpendingLimitError', 'NotAllowed'),
        3224: ('SpendingLimitError', 'HistoryCapacityExceeded'),
        3225: ('SpendingLimitError', 'AlreadyInstalled'),
        3226: ('SpendingLimitError', 'LessThanZero'),
        3227: ('SpendingLimitError', 'OnlyCallContractAllowed'),
      };
      expect(expected.length, 43);
      for (final entry in expected.entries) {
        final decoded = OZContractErrorCodes.decode(entry.key);
        expect(
          decoded,
          OZContractError(entry.key, entry.value.$1, entry.value.$2),
          reason: 'code ${entry.key} must decode to its contract enum entry',
        );
      }
    });
  });

  group('OZContractErrorCodes.decodeFromMessage', () {
    test('testDecodeFromMessage_simulationErrorString', () {
      const message =
          'Transaction simulation failed: Simulation error: HostError: '
          'Error(Context, InvalidAction) Event log: [Diagnostic Event] '
          'topics:[error, Error(Context, InvalidAction)], '
          'data:["constructor invocation has failed with error", '
          'Error(Contract, #3201)]';
      expect(
        OZContractErrorCodes.decodeFromMessage(message),
        const OZContractError(3201, 'SimpleThresholdError', 'InvalidThreshold'),
      );
    });

    test('testDecodeFromMessage_whitespaceVariants', () {
      expect(
        OZContractErrorCodes.decodeFromMessage('Error(Contract, #3227)')?.code,
        3227,
      );
      expect(
        OZContractErrorCodes.decodeFromMessage('Error( Contract , #3227 )')
            ?.code,
        3227,
      );
    });

    test('testDecodeFromMessage_skipsUnknownCodeAndReturnsFirstKnown', () {
      // 3001 is unused in the contract enums; the scan continues to the next
      // marker.
      const message = 'Error(Contract, #3001) then Error(Contract, #3114)';
      expect(
        OZContractErrorCodes.decodeFromMessage(message),
        const OZContractError(3114, 'WebAuthnError', 'ChallengeInvalid'),
      );
    });

    test('testDecodeFromMessage_noMatchReturnsNull', () {
      expect(OZContractErrorCodes.decodeFromMessage(null), isNull);
      expect(
        OZContractErrorCodes.decodeFromMessage('no contract error here'),
        isNull,
      );
      expect(
        OZContractErrorCodes.decodeFromMessage('Error(Contract, #3001)'),
        isNull,
      );
      expect(
        OZContractErrorCodes.decodeFromMessage('Error(WasmVm, InternalError)'),
        isNull,
      );
    });
  });
}
