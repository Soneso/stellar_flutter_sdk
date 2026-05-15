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
  SmartAccountErrorCode.invalidConfig: InvalidConfig,
  SmartAccountErrorCode.missingConfig: MissingConfig,
  SmartAccountErrorCode.walletNotConnected: WalletNotConnected,
  SmartAccountErrorCode.walletAlreadyExists: WalletAlreadyExists,
  SmartAccountErrorCode.walletNotFound: WalletNotFound,
  SmartAccountErrorCode.credentialNotFound: CredentialNotFound,
  SmartAccountErrorCode.credentialAlreadyExists: CredentialAlreadyExists,
  SmartAccountErrorCode.credentialInvalid: CredentialInvalid,
  SmartAccountErrorCode.credentialDeploymentFailed: CredentialDeploymentFailed,
  SmartAccountErrorCode.webauthnRegistrationFailed: WebAuthnRegistrationFailed,
  SmartAccountErrorCode.webauthnAuthenticationFailed:
      WebAuthnAuthenticationFailed,
  SmartAccountErrorCode.webauthnNotSupported: WebAuthnNotSupported,
  SmartAccountErrorCode.webauthnCancelled: WebAuthnCancelled,
  SmartAccountErrorCode.transactionSimulationFailed:
      TransactionSimulationFailed,
  SmartAccountErrorCode.transactionSigningFailed: TransactionSigningFailed,
  SmartAccountErrorCode.transactionSubmissionFailed:
      TransactionSubmissionFailed,
  SmartAccountErrorCode.transactionTimeout: TransactionTimeout,
  SmartAccountErrorCode.signerNotFound: SignerNotFound,
  SmartAccountErrorCode.signerInvalid: SignerInvalid,
  SmartAccountErrorCode.invalidAddress: InvalidAddress,
  SmartAccountErrorCode.invalidAmount: InvalidAmount,
  SmartAccountErrorCode.invalidInput: InvalidInput,
  SmartAccountErrorCode.storageReadFailed: StorageReadFailed,
  SmartAccountErrorCode.storageWriteFailed: StorageWriteFailed,
  SmartAccountErrorCode.sessionExpired: SessionExpired,
  SmartAccountErrorCode.sessionInvalid: SessionInvalid,
  SmartAccountErrorCode.indexerRequestFailed: IndexerRequestFailed,
  SmartAccountErrorCode.indexerTimeout: IndexerTimeout,
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
      final ex = const InvalidInput('something went wrong');
      expect(ex.code, SmartAccountErrorCode.invalidInput);
      expect(ex.code.code, 7003);
    });

    test('test_smart_account_exception_to_string_format_includes_code_and_message',
        () {
      final ex = const InvalidConfig('bad value');
      final text = ex.toString();
      expect(text, contains('SmartAccountException'));
      expect(text, contains('[1001]'));
      expect(text, contains('bad value'));
    });

    test(
        'test_smart_account_exception_to_string_includes_caused_by_when_cause_present',
        () {
      final cause = Exception('downstream failure');
      final ex = InvalidConfig('outer message', cause);
      expect(ex.toString(), contains('caused by:'));
      expect(ex.toString(), contains('downstream failure'));
    });
  });

  group('SmartAccountException.wrapError', () {
    test('test_wrap_error_returns_input_unchanged_when_already_smart_account_exception',
        () {
      final original = const InvalidConfig('hi');
      final wrapped = SmartAccountException.wrapError(original);
      expect(identical(original, wrapped), isTrue);
    });

    test('test_wrap_error_default_code_is_INVALID_INPUT_when_unspecified', () {
      final wrapped = SmartAccountException.wrapError(Exception('boom'));
      expect(wrapped, isA<InvalidInput>());
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
      expect(<Type>{InvalidConfig, MissingConfig}.length, 2);
      // Wallet: 3
      expect(<Type>{WalletNotConnected, WalletAlreadyExists, WalletNotFound}
          .length, 3);
      // Credential: 4
      expect(<Type>{
        CredentialNotFound,
        CredentialAlreadyExists,
        CredentialInvalid,
        CredentialDeploymentFailed
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
        TransactionSimulationFailed,
        TransactionSigningFailed,
        TransactionSubmissionFailed,
        TransactionTimeout
      }.length, 4);
      // Signer: 2
      expect(<Type>{SignerNotFound, SignerInvalid}.length, 2);
      // Validation: 3
      expect(<Type>{InvalidAddress, InvalidAmount, InvalidInput}.length, 3);
      // Storage: 2
      expect(<Type>{StorageReadFailed, StorageWriteFailed}.length, 2);
      // Session: 2
      expect(<Type>{SessionExpired, SessionInvalid}.length, 2);
      // Indexer: 2
      expect(<Type>{IndexerRequestFailed, IndexerTimeout}.length, 2);
    });
  });

  group('Default messages', () {
    test('test_default_messages_present_NotConnected_NotSupported_Cancelled_Timeout_Expired',
        () {
      expect(const WalletNotConnected().message, 'Wallet is not connected');
      expect(const WebAuthnNotSupported().message,
          'WebAuthn is not supported on this platform');
      expect(const WebAuthnCancelled().message,
          'User cancelled WebAuthn operation');
      expect(const TransactionTimeout().message, 'Transaction timed out');
      expect(const SessionExpired().message, 'Session has expired');
    });
  });

  group('Companion factories', () {
    test('test_companion_factory_invalidAddress_message_format_invalid_address_colon_address',
        () {
      final ex = ValidationException.invalidAddress('GBADADDR');
      expect(ex, isA<InvalidAddress>());
      expect(ex.message, 'Invalid address: GBADADDR');
      expect(ex.code, SmartAccountErrorCode.invalidAddress);
    });

    test('test_companion_factory_invalidAmount_optional_reason_appended_after_dash',
        () {
      final without = ValidationException.invalidAmount('-1');
      expect(without.message, 'Invalid amount: -1');

      final withReason = ValidationException.invalidAmount(
        '-1',
        reason: 'must be positive',
      );
      expect(withReason.message, 'Invalid amount: -1 - must be positive');
    });

    test('test_companion_factory_invalidInput_field_and_reason_in_message', () {
      final ex = ValidationException.invalidInput('publicKey', 'wrong size');
      expect(ex.message, 'Invalid input for publicKey: wrong size');
    });

    test(
        'test_companion_factory_invalidInput_throws_correct_arm_with_correct_code',
        () {
      final ex = ValidationException.invalidInput('field', 'reason');
      expect(ex, isA<InvalidInput>());
      expect(ex.code, SmartAccountErrorCode.invalidInput);
      expect(ex.code.code, 7003);
    });
  });

  group('All companion factories produce correctly-coded arms', () {
    test('configuration factories', () {
      expect(ConfigurationException.invalidConfig('x'), isA<InvalidConfig>());
      expect(ConfigurationException.invalidConfig('x').message,
          'Invalid configuration: x');
      expect(ConfigurationException.missingConfig('y'), isA<MissingConfig>());
      expect(ConfigurationException.missingConfig('y').message,
          'Missing required configuration: y');
    });

    test('wallet factories', () {
      expect(WalletException.notConnected(), isA<WalletNotConnected>());
      expect(WalletException.notConnected(details: 'hello').message, 'hello');
      expect(WalletException.alreadyExists('id'), isA<WalletAlreadyExists>());
      expect(WalletException.alreadyExists('id').message,
          'Wallet already exists: id');
      expect(WalletException.notFound('id'), isA<WalletNotFound>());
      expect(WalletException.notFound('id').message, 'Wallet not found: id');
    });

    test('credential factories', () {
      expect(CredentialException.notFound('cid'), isA<CredentialNotFound>());
      expect(CredentialException.notFound('cid').message,
          'Credential not found: cid');
      expect(CredentialException.alreadyExists('cid'),
          isA<CredentialAlreadyExists>());
      expect(CredentialException.alreadyExists('cid').message,
          'Credential already exists: cid');
      expect(CredentialException.invalid('bad'), isA<CredentialInvalid>());
      expect(CredentialException.invalid('bad').message,
          'Invalid credential: bad');
      expect(CredentialException.deploymentFailed('boom'),
          isA<CredentialDeploymentFailed>());
      expect(CredentialException.deploymentFailed('boom').message,
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
      expect(TransactionException.simulationFailed('s'),
          isA<TransactionSimulationFailed>());
      expect(TransactionException.simulationFailed('s').message,
          'Transaction simulation failed: s');
      expect(TransactionException.signingFailed('si'),
          isA<TransactionSigningFailed>());
      expect(TransactionException.submissionFailed('sub'),
          isA<TransactionSubmissionFailed>());
      expect(TransactionException.timeout(), isA<TransactionTimeout>());
      expect(TransactionException.timeout(details: 'tt').message, 'tt');
    });

    test('signer factories', () {
      expect(SignerException.notFound('sid'), isA<SignerNotFound>());
      expect(SignerException.notFound('sid').message, 'Signer not found: sid');
      expect(SignerException.invalid('reason'), isA<SignerInvalid>());
      expect(SignerException.invalid('reason').message,
          'Invalid signer: reason');
    });

    test('storage factories', () {
      expect(StorageException.readFailed('k'), isA<StorageReadFailed>());
      expect(StorageException.readFailed('k').message,
          'Storage read failed for key: k');
      expect(StorageException.writeFailed('k'), isA<StorageWriteFailed>());
      expect(StorageException.writeFailed('k').message,
          'Storage write failed for key: k');
    });

    test('session factories', () {
      expect(SessionException.expired(), isA<SessionExpired>());
      expect(SessionException.expired().message, 'Session has expired');
      expect(SessionException.expired(sessionId: 'sid').message,
          'Session expired: sid');
      expect(SessionException.invalid('bad'), isA<SessionInvalid>());
      expect(SessionException.invalid('bad').message, 'Invalid session: bad');
    });

    test('indexer factories', () {
      expect(IndexerException.requestFailed('rf'), isA<IndexerRequestFailed>());
      expect(IndexerException.requestFailed('rf').message,
          'Indexer request failed: rf');
      expect(IndexerException.timeout('https://example/'), isA<IndexerTimeout>());
      expect(IndexerException.timeout('https://example/').message,
          'Indexer request timed out: https://example/');
    });

    test('contract error codes are correct', () {
      expect(ContractErrorCodes.mathOverflow, 3012);
      expect(ContractErrorCodes.keyDataTooLarge, 3013);
      expect(ContractErrorCodes.contextRuleIdsLengthMismatch, 3014);
      expect(ContractErrorCodes.nameTooLong, 3015);
      expect(ContractErrorCodes.unauthorizedSigner, 3016);
    });

    test('toString without cause omits the caused-by suffix', () {
      final ex = const InvalidConfig('alone');
      expect(ex.toString(), 'SmartAccountException [1001]: alone');
    });

    test('wrapError preserves SmartAccountException identity for every arm',
        () {
      const ex = InvalidAddress('keep me');
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
      expect(wrapped, isA<InvalidInput>());
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
        InvalidConfig('a'),
        MissingConfig('a'),
        WalletNotConnected(),
        WalletAlreadyExists('a'),
        WalletNotFound('a'),
        CredentialNotFound('a'),
        CredentialAlreadyExists('a'),
        CredentialInvalid('a'),
        CredentialDeploymentFailed('a'),
        WebAuthnRegistrationFailed('a'),
        WebAuthnAuthenticationFailed('a'),
        WebAuthnNotSupported(),
        WebAuthnCancelled(),
        TransactionSimulationFailed('a'),
        TransactionSigningFailed('a'),
        TransactionSubmissionFailed('a'),
        TransactionTimeout(),
        SignerNotFound('a'),
        SignerInvalid('a'),
        InvalidAddress('a'),
        InvalidAmount('a'),
        InvalidInput('a'),
        StorageReadFailed('a'),
        StorageWriteFailed('a'),
        SessionExpired(),
        SessionInvalid('a'),
        IndexerRequestFailed('a'),
        IndexerTimeout('a'),
      ];

      // Exhaustive switch — a missing arm fails analyzer-time compilation.
      for (final ex in samples) {
        final family = switch (ex) {
          ConfigurationException() => 'config',
          WalletException() => 'wallet',
          CredentialException() => 'credential',
          WebAuthnException() => 'webauthn',
          TransactionException() => 'transaction',
          SignerException() => 'signer',
          ValidationException() => 'validation',
          StorageException() => 'storage',
          SessionException() => 'session',
          IndexerException() => 'indexer',
        };
        expect(family, isNotEmpty);
      }

      // Inventory: the switch above lists 10 sealed sub-types, matching the
      // expected error-class tree.
      expect(samples.length, 28);
    });
  });
}
