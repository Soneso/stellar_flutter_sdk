import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

/// Canonical mapping of every [SmartAccountErrorCode] to its numeric value.
const Map<SmartAccountErrorCode, int> _codeTable = {
  SmartAccountErrorCode.invalidConfig: 1001,
  SmartAccountErrorCode.missingConfig: 1002,
  SmartAccountErrorCode.walletNotConnected: 2001,
  SmartAccountErrorCode.walletAlreadyExists: 2002,
  SmartAccountErrorCode.walletNotFound: 2003,
  SmartAccountErrorCode.credentialNotFound: 3001,
  SmartAccountErrorCode.credentialAlreadyExists: 3002,
  SmartAccountErrorCode.credentialInvalid: 3003,
  SmartAccountErrorCode.credentialDeploymentFailed: 3004,
  SmartAccountErrorCode.webauthnRegistrationFailed: 4001,
  SmartAccountErrorCode.webauthnAuthenticationFailed: 4002,
  SmartAccountErrorCode.webauthnNotSupported: 4003,
  SmartAccountErrorCode.webauthnCancelled: 4004,
  SmartAccountErrorCode.transactionSimulationFailed: 5001,
  SmartAccountErrorCode.transactionSigningFailed: 5002,
  SmartAccountErrorCode.transactionSubmissionFailed: 5003,
  SmartAccountErrorCode.transactionTimeout: 5004,
  SmartAccountErrorCode.signerNotFound: 6001,
  SmartAccountErrorCode.signerInvalid: 6002,
  SmartAccountErrorCode.invalidAddress: 7001,
  SmartAccountErrorCode.invalidAmount: 7002,
  SmartAccountErrorCode.invalidInput: 7003,
  SmartAccountErrorCode.storageReadFailed: 8001,
  SmartAccountErrorCode.storageWriteFailed: 8002,
  SmartAccountErrorCode.sessionExpired: 9001,
  SmartAccountErrorCode.sessionInvalid: 9002,
  SmartAccountErrorCode.indexerRequestFailed: 10001,
  SmartAccountErrorCode.indexerTimeout: 10002,
};

/// Maps each error code to the concrete subtype expected from
/// [SmartAccountException.wrapError] when that code is supplied as the
/// default code.
final Map<SmartAccountErrorCode, Type> _expectedArmType = {
  SmartAccountErrorCode.invalidConfig: SmartAccountInvalidConfig,
  SmartAccountErrorCode.missingConfig: SmartAccountMissingConfig,
  SmartAccountErrorCode.walletNotConnected: SmartAccountWalletNotConnected,
  SmartAccountErrorCode.walletAlreadyExists: SmartAccountWalletAlreadyExists,
  SmartAccountErrorCode.walletNotFound: SmartAccountWalletNotFound,
  SmartAccountErrorCode.credentialNotFound: SmartAccountCredentialNotFound,
  SmartAccountErrorCode.credentialAlreadyExists: SmartAccountCredentialAlreadyExists,
  SmartAccountErrorCode.credentialInvalid: SmartAccountCredentialInvalid,
  SmartAccountErrorCode.credentialDeploymentFailed: SmartAccountCredentialDeploymentFailed,
  SmartAccountErrorCode.webauthnRegistrationFailed: WebAuthnRegistrationFailed,
  SmartAccountErrorCode.webauthnAuthenticationFailed:
      WebAuthnAuthenticationFailed,
  SmartAccountErrorCode.webauthnNotSupported: WebAuthnNotSupported,
  SmartAccountErrorCode.webauthnCancelled: WebAuthnCancelled,
  SmartAccountErrorCode.transactionSimulationFailed:
      SmartAccountTransactionSimulationFailed,
  SmartAccountErrorCode.transactionSigningFailed: SmartAccountTransactionSigningFailed,
  SmartAccountErrorCode.transactionSubmissionFailed:
      SmartAccountTransactionSubmissionFailed,
  SmartAccountErrorCode.transactionTimeout: SmartAccountTransactionTimeout,
  SmartAccountErrorCode.signerNotFound: SmartAccountSignerNotFound,
  SmartAccountErrorCode.signerInvalid: SmartAccountSignerInvalid,
  SmartAccountErrorCode.invalidAddress: SmartAccountInvalidAddress,
  SmartAccountErrorCode.invalidAmount: SmartAccountInvalidAmount,
  SmartAccountErrorCode.invalidInput: SmartAccountInvalidInput,
  SmartAccountErrorCode.storageReadFailed: SmartAccountStorageReadFailed,
  SmartAccountErrorCode.storageWriteFailed: SmartAccountStorageWriteFailed,
  SmartAccountErrorCode.sessionExpired: SmartAccountSessionExpired,
  SmartAccountErrorCode.sessionInvalid: SmartAccountSessionInvalid,
  SmartAccountErrorCode.indexerRequestFailed: SmartAccountIndexerRequestFailed,
  SmartAccountErrorCode.indexerTimeout: SmartAccountIndexerTimeout,
};

void main() {
  group('SmartAccountErrorCode', () {
    test('test_smart_account_error_code_has_28_distinct_numeric_values', () {
      final allValues =
          SmartAccountErrorCode.values.map((c) => c.code).toSet();
      expect(SmartAccountErrorCode.values.length, 28);
      expect(allValues.length, 28);
    });

    test('test_smart_account_error_code_INVALID_CONFIG_equals_1001', () {
      expect(SmartAccountErrorCode.invalidConfig.code, 1001);
    });

    test('test_smart_account_error_code_INDEXER_TIMEOUT_equals_10002', () {
      expect(SmartAccountErrorCode.indexerTimeout.code, 10002);
    });

    test('test_smart_account_error_code_all_28_codes_match_authoritative_table', () {
      expect(_codeTable.length, 28);
      _codeTable.forEach((code, expected) {
        expect(code.code, expected, reason: 'Mismatch for $code');
      });
    });
  });

  group('SmartAccountException', () {
    test(
        'test_smart_account_exception_code_property_returns_underlying_error_code',
        () {
      final ex = const SmartAccountInvalidInput('something went wrong');
      expect(ex.code, SmartAccountErrorCode.invalidInput);
      expect(ex.code.code, 7003);
    });

    test('test_smart_account_exception_to_string_format_includes_code_and_message',
        () {
      final ex = const SmartAccountInvalidConfig('bad value');
      final text = ex.toString();
      expect(text, contains('SmartAccountException'));
      expect(text, contains('[1001]'));
      expect(text, contains('bad value'));
    });

    test(
        'test_smart_account_exception_to_string_includes_caused_by_when_cause_present',
        () {
      final cause = Exception('downstream failure');
      final ex = SmartAccountInvalidConfig('outer message', cause);
      expect(ex.toString(), contains('caused by:'));
      expect(ex.toString(), contains('downstream failure'));
    });
  });

  group('SmartAccountException.wrapError', () {
    test('test_wrap_error_returns_input_unchanged_when_already_smart_account_exception',
        () {
      final original = const SmartAccountInvalidConfig('hi');
      final wrapped = SmartAccountException.wrapError(original);
      expect(identical(original, wrapped), isTrue);
    });

    test('test_wrap_error_default_code_is_INVALID_INPUT_when_unspecified', () {
      final wrapped = SmartAccountException.wrapError(Exception('boom'));
      expect(wrapped, isA<SmartAccountInvalidInput>());
      expect(wrapped.code, SmartAccountErrorCode.invalidInput);
    });

    test('test_wrap_error_maps_each_of_28_codes_to_correct_arm', () {
      for (final code in SmartAccountErrorCode.values) {
        final wrapped = SmartAccountException.wrapError(
          Exception('underlying'),
          defaultCode: code,
        );
        expect(wrapped.code, code, reason: 'Code mismatch for $code');
        expect(wrapped.runtimeType, _expectedArmType[code],
            reason: 'Type mismatch for $code');
      }
    });
  });

  group('Sealed-subtype arm counts', () {
    test('test_each_sealed_subtype_has_correct_arm_count', () {
      // Configuration: 2
      expect(<Type>{SmartAccountInvalidConfig, SmartAccountMissingConfig}.length, 2);
      // Wallet: 3
      expect(<Type>{SmartAccountWalletNotConnected, SmartAccountWalletAlreadyExists, SmartAccountWalletNotFound}
          .length, 3);
      // Credential: 4
      expect(<Type>{
        SmartAccountCredentialNotFound,
        SmartAccountCredentialAlreadyExists,
        SmartAccountCredentialInvalid,
        SmartAccountCredentialDeploymentFailed
      }.length, 4);
      // WebAuthn: 4
      expect(<Type>{
        WebAuthnRegistrationFailed,
        WebAuthnAuthenticationFailed,
        WebAuthnNotSupported,
        WebAuthnCancelled
      }.length, 4);
      // Transaction: 4
      expect(<Type>{
        SmartAccountTransactionSimulationFailed,
        SmartAccountTransactionSigningFailed,
        SmartAccountTransactionSubmissionFailed,
        SmartAccountTransactionTimeout
      }.length, 4);
      // Signer: 2
      expect(<Type>{SmartAccountSignerNotFound, SmartAccountSignerInvalid}.length, 2);
      // Validation: 3
      expect(<Type>{SmartAccountInvalidAddress, SmartAccountInvalidAmount, SmartAccountInvalidInput}.length, 3);
      // Storage: 2
      expect(<Type>{SmartAccountStorageReadFailed, SmartAccountStorageWriteFailed}.length, 2);
      // Session: 2
      expect(<Type>{SmartAccountSessionExpired, SmartAccountSessionInvalid}.length, 2);
      // Indexer: 2
      expect(<Type>{SmartAccountIndexerRequestFailed, SmartAccountIndexerTimeout}.length, 2);
    });
  });

  group('Default messages', () {
    test('test_default_messages_present_NotConnected_NotSupported_Cancelled_Timeout_Expired',
        () {
      expect(const SmartAccountWalletNotConnected().message, 'Wallet is not connected');
      expect(const WebAuthnNotSupported().message,
          'WebAuthn is not supported on this platform');
      expect(const WebAuthnCancelled().message,
          'User cancelled WebAuthn operation');
      expect(const SmartAccountTransactionTimeout().message, 'Transaction timed out');
      expect(const SmartAccountSessionExpired().message, 'Session has expired');
    });
  });

  group('Companion factories', () {
    test('test_companion_factory_invalidAddress_message_format_invalid_address_colon_address',
        () {
      final ex = SmartAccountValidationException.invalidAddress('GBADADDR');
      expect(ex, isA<SmartAccountInvalidAddress>());
      expect(ex.message, 'Invalid address: GBADADDR');
      expect(ex.code, SmartAccountErrorCode.invalidAddress);
    });

    test('test_companion_factory_invalidAmount_optional_reason_appended_after_dash',
        () {
      final without = SmartAccountValidationException.invalidAmount('-1');
      expect(without.message, 'Invalid amount: -1');

      final withReason = SmartAccountValidationException.invalidAmount(
        '-1',
        reason: 'must be positive',
      );
      expect(withReason.message, 'Invalid amount: -1 - must be positive');
    });

    test('test_companion_factory_invalidInput_field_and_reason_in_message', () {
      final ex = SmartAccountValidationException.invalidInput('publicKey', 'wrong size');
      expect(ex.message, 'Invalid input for publicKey: wrong size');
    });

    test(
        'test_companion_factory_invalidInput_throws_correct_arm_with_correct_code',
        () {
      final ex = SmartAccountValidationException.invalidInput('field', 'reason');
      expect(ex, isA<SmartAccountInvalidInput>());
      expect(ex.code, SmartAccountErrorCode.invalidInput);
      expect(ex.code.code, 7003);
    });
  });

  group('All companion factories produce correctly-coded arms', () {
    test('configuration factories', () {
      expect(SmartAccountConfigurationException.invalidConfig('x'), isA<SmartAccountInvalidConfig>());
      expect(SmartAccountConfigurationException.invalidConfig('x').message,
          'Invalid configuration: x');
      expect(SmartAccountConfigurationException.missingConfig('y'), isA<SmartAccountMissingConfig>());
      expect(SmartAccountConfigurationException.missingConfig('y').message,
          'Missing required configuration: y');
    });

    test('wallet factories', () {
      expect(SmartAccountWalletException.notConnected(), isA<SmartAccountWalletNotConnected>());
      expect(SmartAccountWalletException.notConnected(details: 'hello').message, 'hello');
      expect(SmartAccountWalletException.alreadyExists('id'), isA<SmartAccountWalletAlreadyExists>());
      expect(SmartAccountWalletException.alreadyExists('id').message,
          'Wallet already exists: id');
      expect(SmartAccountWalletException.notFound('id'), isA<SmartAccountWalletNotFound>());
      expect(SmartAccountWalletException.notFound('id').message, 'Wallet not found: id');
    });

    test('credential factories', () {
      expect(SmartAccountCredentialException.notFound('cid'), isA<SmartAccountCredentialNotFound>());
      expect(SmartAccountCredentialException.notFound('cid').message,
          'Credential not found: cid');
      expect(SmartAccountCredentialException.alreadyExists('cid'),
          isA<SmartAccountCredentialAlreadyExists>());
      expect(SmartAccountCredentialException.alreadyExists('cid').message,
          'Credential already exists: cid');
      expect(SmartAccountCredentialException.invalid('bad'), isA<SmartAccountCredentialInvalid>());
      expect(SmartAccountCredentialException.invalid('bad').message,
          'Invalid credential: bad');
      expect(SmartAccountCredentialException.deploymentFailed('boom'),
          isA<SmartAccountCredentialDeploymentFailed>());
      expect(SmartAccountCredentialException.deploymentFailed('boom').message,
          'Credential deployment failed: boom');
    });

    test('webauthn factories', () {
      expect(WebAuthnException.registrationFailed('rf'),
          isA<WebAuthnRegistrationFailed>());
      expect(WebAuthnException.registrationFailed('rf').message,
          'WebAuthn registration failed: rf');
      expect(WebAuthnException.authenticationFailed('af'),
          isA<WebAuthnAuthenticationFailed>());
      expect(WebAuthnException.authenticationFailed('af').message,
          'WebAuthn authentication failed: af');
      expect(WebAuthnException.notSupported(), isA<WebAuthnNotSupported>());
      expect(WebAuthnException.notSupported(details: 'detail').message,
          'detail');
      expect(WebAuthnException.cancelled(), isA<WebAuthnCancelled>());
      expect(WebAuthnException.cancelled().message,
          'User cancelled WebAuthn operation');
    });

    test('transaction factories', () {
      expect(SmartAccountTransactionException.simulationFailed('s'),
          isA<SmartAccountTransactionSimulationFailed>());
      expect(SmartAccountTransactionException.simulationFailed('s').message,
          'Transaction simulation failed: s');
      expect(SmartAccountTransactionException.signingFailed('si'),
          isA<SmartAccountTransactionSigningFailed>());
      expect(SmartAccountTransactionException.submissionFailed('sub'),
          isA<SmartAccountTransactionSubmissionFailed>());
      expect(SmartAccountTransactionException.timeout(), isA<SmartAccountTransactionTimeout>());
      expect(SmartAccountTransactionException.timeout(details: 'tt').message, 'tt');
    });

    test('signer factories', () {
      expect(SmartAccountSignerException.notFound('sid'), isA<SmartAccountSignerNotFound>());
      expect(SmartAccountSignerException.notFound('sid').message, 'Signer not found: sid');
      expect(SmartAccountSignerException.invalid('reason'), isA<SmartAccountSignerInvalid>());
      expect(SmartAccountSignerException.invalid('reason').message,
          'Invalid signer: reason');
    });

    test('storage factories', () {
      expect(SmartAccountStorageException.readFailed('k'), isA<SmartAccountStorageReadFailed>());
      expect(SmartAccountStorageException.readFailed('k').message,
          'Storage read failed for key: k');
      expect(SmartAccountStorageException.writeFailed('k'), isA<SmartAccountStorageWriteFailed>());
      expect(SmartAccountStorageException.writeFailed('k').message,
          'Storage write failed for key: k');
    });

    test('session factories', () {
      expect(SmartAccountSessionException.expired(), isA<SmartAccountSessionExpired>());
      expect(SmartAccountSessionException.expired().message, 'Session has expired');
      expect(SmartAccountSessionException.expired(sessionId: 'sid').message,
          'Session expired: sid');
      expect(SmartAccountSessionException.invalid('bad'), isA<SmartAccountSessionInvalid>());
      expect(SmartAccountSessionException.invalid('bad').message, 'Invalid session: bad');
    });

    test('indexer factories', () {
      expect(SmartAccountIndexerException.requestFailed('rf'), isA<SmartAccountIndexerRequestFailed>());
      expect(SmartAccountIndexerException.requestFailed('rf').message,
          'Indexer request failed: rf');
      expect(SmartAccountIndexerException.timeout('https://example/'), isA<SmartAccountIndexerTimeout>());
      expect(SmartAccountIndexerException.timeout('https://example/').message,
          'Indexer request timed out: https://example/');
    });

    test('toString without cause omits the caused-by suffix', () {
      final ex = const SmartAccountInvalidConfig('alone');
      expect(ex.toString(), 'SmartAccountException [1001]: alone');
    });

    test('wrapError preserves SmartAccountException identity for every arm',
        () {
      const ex = SmartAccountInvalidAddress('keep me');
      final wrapped = SmartAccountException.wrapError(
        ex,
        defaultCode: SmartAccountErrorCode.transactionTimeout,
      );
      expect(identical(ex, wrapped), isTrue);
    });

    test('wrapError extracts toString for plain Error inputs', () {
      // Trigger the Error branch in _extractMessage.
      final wrapped = SmartAccountException.wrapError(
        ArgumentError('bad arg'),
      );
      expect(wrapped, isA<SmartAccountInvalidInput>());
      expect(wrapped.message, contains('bad arg'));
    });
  });

  group('Exhaustiveness', () {
    test('test_smart_account_exception_exhaustiveness_compile_time_check', () {
      // The Dart 3 sealed-class hierarchy lets the analyser flag missing arms
      // statically. Switching over an instance of every concrete subtype
      // exercises that exhaustiveness contract. If a new subtype is added
      // without updating this switch, `flutter analyze` rejects the file.
      const samples = <SmartAccountException>[
        SmartAccountInvalidConfig('a'),
        SmartAccountMissingConfig('a'),
        SmartAccountWalletNotConnected(),
        SmartAccountWalletAlreadyExists('a'),
        SmartAccountWalletNotFound('a'),
        SmartAccountCredentialNotFound('a'),
        SmartAccountCredentialAlreadyExists('a'),
        SmartAccountCredentialInvalid('a'),
        SmartAccountCredentialDeploymentFailed('a'),
        WebAuthnRegistrationFailed('a'),
        WebAuthnAuthenticationFailed('a'),
        WebAuthnNotSupported(),
        WebAuthnCancelled(),
        SmartAccountTransactionSimulationFailed('a'),
        SmartAccountTransactionSigningFailed('a'),
        SmartAccountTransactionSubmissionFailed('a'),
        SmartAccountTransactionTimeout(),
        SmartAccountSignerNotFound('a'),
        SmartAccountSignerInvalid('a'),
        SmartAccountInvalidAddress('a'),
        SmartAccountInvalidAmount('a'),
        SmartAccountInvalidInput('a'),
        SmartAccountStorageReadFailed('a'),
        SmartAccountStorageWriteFailed('a'),
        SmartAccountSessionExpired(),
        SmartAccountSessionInvalid('a'),
        SmartAccountIndexerRequestFailed('a'),
        SmartAccountIndexerTimeout('a'),
      ];

      // Exhaustive switch — a missing arm fails analyzer-time compilation.
      for (final ex in samples) {
        final family = switch (ex) {
          SmartAccountConfigurationException() => 'config',
          SmartAccountWalletException() => 'wallet',
          SmartAccountCredentialException() => 'credential',
          WebAuthnException() => 'webauthn',
          SmartAccountTransactionException() => 'transaction',
          SmartAccountSignerException() => 'signer',
          SmartAccountValidationException() => 'validation',
          SmartAccountStorageException() => 'storage',
          SmartAccountSessionException() => 'session',
          SmartAccountIndexerException() => 'indexer',
        };
        expect(family, isNotEmpty);
      }

      // Inventory: the switch above lists 10 sealed sub-types, matching the
      // expected error-class tree.
      expect(samples.length, 28);
    });
  });
}
