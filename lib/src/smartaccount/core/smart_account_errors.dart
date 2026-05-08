// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

/// Numeric error codes for Smart Account operations.
///
/// Codes are partitioned into ranges by category so a numeric value identifies
/// the failure domain at a glance:
///
/// - `1xxx` Configuration errors
/// - `2xxx` Wallet state errors
/// - `3xxx` Credential errors
/// - `4xxx` WebAuthn errors
/// - `5xxx` Transaction errors
/// - `6xxx` Signer errors
/// - `7xxx` Validation errors
/// - `8xxx` Storage errors
/// - `9xxx` Session errors
/// - `10xxx` Indexer errors
enum SmartAccountErrorCode {
  /// Configuration is structurally invalid.
  invalidConfig(1001),

  /// A required configuration parameter is missing.
  missingConfig(1002),

  /// Operation requires a connected wallet, but none is connected.
  walletNotConnected(2001),

  /// A wallet with the same identifier already exists.
  walletAlreadyExists(2002),

  /// The requested wallet could not be found.
  walletNotFound(2003),

  /// The requested credential could not be found.
  credentialNotFound(3001),

  /// A credential with the same identifier already exists.
  credentialAlreadyExists(3002),

  /// The credential is invalid or malformed.
  credentialInvalid(3003),

  /// Credential deployment failed.
  credentialDeploymentFailed(3004),

  /// WebAuthn registration failed.
  webauthnRegistrationFailed(4001),

  /// WebAuthn authentication failed.
  webauthnAuthenticationFailed(4002),

  /// WebAuthn is not supported on the current platform.
  webauthnNotSupported(4003),

  /// The user cancelled the WebAuthn operation.
  webauthnCancelled(4004),

  /// Transaction simulation failed.
  transactionSimulationFailed(5001),

  /// Transaction signing failed.
  transactionSigningFailed(5002),

  /// Transaction submission failed.
  transactionSubmissionFailed(5003),

  /// Transaction did not reach a final state within the allotted time.
  transactionTimeout(5004),

  /// The requested signer could not be found.
  signerNotFound(6001),

  /// The signer is invalid or malformed.
  signerInvalid(6002),

  /// The supplied address is not a valid Stellar address.
  invalidAddress(7001),

  /// The supplied amount is not valid.
  invalidAmount(7002),

  /// The supplied input is not valid.
  invalidInput(7003),

  /// Reading from the storage backend failed.
  storageReadFailed(8001),

  /// Writing to the storage backend failed.
  storageWriteFailed(8002),

  /// Session has expired.
  sessionExpired(9001),

  /// Session is invalid or malformed.
  sessionInvalid(9002),

  /// The indexer request failed.
  indexerRequestFailed(10001),

  /// The indexer request timed out.
  indexerTimeout(10002);

  /// Constructs an enum constant with its numeric error code.
  const SmartAccountErrorCode(this.code);

  /// Numeric error code suitable for cross-SDK comparison and diagnostics.
  final int code;
}

/// Base sealed class for Smart Account exceptions.
///
/// `SmartAccountException` provides typed error information for every failure
/// surface inside the Smart Account Kit: a machine-readable
/// [SmartAccountErrorCode], a descriptive [message], and an optional
/// underlying [cause] preserved from the originating exception.
///
/// Consumers should catch [SmartAccountException] for general handling, and
/// switch on concrete subtypes when fine-grained recovery is required:
///
/// ```dart
/// try {
///   final wallet = await smartAccountKit.createWallet(name: 'My Wallet');
///   print('Wallet created: ${wallet.address}');
/// } on WebAuthnCancelled {
///   print('User cancelled authentication');
/// } on CredentialDeploymentFailed catch (e) {
///   print('Failed to deploy contract: ${e.message}');
/// } on SmartAccountException catch (e) {
///   print('Error ${e.code.code}: ${e.message}');
/// }
/// ```
sealed class SmartAccountException implements Exception {
  /// Constructs a `SmartAccountException` with its categorised error [code],
  /// a human-readable [message], and an optional underlying [cause].
  const SmartAccountException(this.code, this.message, [this.cause]);

  /// The categorised error code for this exception.
  final SmartAccountErrorCode code;

  /// A human-readable error message describing the failure.
  final String message;

  /// The original throwable that triggered this exception, if any.
  ///
  /// Preserved so failure reports can show the upstream stack trace
  /// or platform-specific error information.
  final Object? cause;

  @override
  String toString() {
    final causeMessage = _causeMessage(cause);
    if (causeMessage != null) {
      return 'SmartAccountException [${code.code}]: $message '
          '(caused by: $causeMessage)';
    }
    return 'SmartAccountException [${code.code}]: $message';
  }

  /// Wraps an arbitrary throwable into a [SmartAccountException].
  ///
  /// If [err] is already a [SmartAccountException] it is returned unchanged.
  /// Otherwise the throwable's message (or `toString()` representation when
  /// no message is available) is wrapped in the [SmartAccountException]
  /// subclass corresponding to [defaultCode], preserving the original
  /// throwable as the [cause].
  ///
  /// Use this helper inside boundary code (HTTP clients, RPC adapters,
  /// platform-specific bindings) to ensure every error surfaced from the
  /// Smart Account Kit is consistently typed.
  static SmartAccountException wrapError(
    Object err, {
    SmartAccountErrorCode defaultCode = SmartAccountErrorCode.invalidInput,
  }) {
    if (err is SmartAccountException) {
      return err;
    }
    final message = _extractMessage(err);
    switch (defaultCode) {
      case SmartAccountErrorCode.invalidConfig:
        return InvalidConfig(message, err);
      case SmartAccountErrorCode.missingConfig:
        return MissingConfig(message, err);
      case SmartAccountErrorCode.walletNotConnected:
        return WalletNotConnected(message: message, cause: err);
      case SmartAccountErrorCode.walletAlreadyExists:
        return WalletAlreadyExists(message, err);
      case SmartAccountErrorCode.walletNotFound:
        return WalletNotFound(message, err);
      case SmartAccountErrorCode.credentialNotFound:
        return CredentialNotFound(message, err);
      case SmartAccountErrorCode.credentialAlreadyExists:
        return CredentialAlreadyExists(message, err);
      case SmartAccountErrorCode.credentialInvalid:
        return CredentialInvalid(message, err);
      case SmartAccountErrorCode.credentialDeploymentFailed:
        return CredentialDeploymentFailed(message, err);
      case SmartAccountErrorCode.webauthnRegistrationFailed:
        return WebAuthnRegistrationFailed(message, err);
      case SmartAccountErrorCode.webauthnAuthenticationFailed:
        return WebAuthnAuthenticationFailed(message, err);
      case SmartAccountErrorCode.webauthnNotSupported:
        return WebAuthnNotSupported(message: message, cause: err);
      case SmartAccountErrorCode.webauthnCancelled:
        return WebAuthnCancelled(message: message, cause: err);
      case SmartAccountErrorCode.transactionSimulationFailed:
        return TransactionSimulationFailed(message, err);
      case SmartAccountErrorCode.transactionSigningFailed:
        return TransactionSigningFailed(message, err);
      case SmartAccountErrorCode.transactionSubmissionFailed:
        return TransactionSubmissionFailed(message, err);
      case SmartAccountErrorCode.transactionTimeout:
        return TransactionTimeout(message: message, cause: err);
      case SmartAccountErrorCode.signerNotFound:
        return SignerNotFound(message, err);
      case SmartAccountErrorCode.signerInvalid:
        return SignerInvalid(message, err);
      case SmartAccountErrorCode.invalidAddress:
        return InvalidAddress(message, err);
      case SmartAccountErrorCode.invalidAmount:
        return InvalidAmount(message, err);
      case SmartAccountErrorCode.invalidInput:
        return InvalidInput(message, err);
      case SmartAccountErrorCode.storageReadFailed:
        return StorageReadFailed(message, err);
      case SmartAccountErrorCode.storageWriteFailed:
        return StorageWriteFailed(message, err);
      case SmartAccountErrorCode.sessionExpired:
        return SessionExpired(message: message, cause: err);
      case SmartAccountErrorCode.sessionInvalid:
        return SessionInvalid(message, err);
      case SmartAccountErrorCode.indexerRequestFailed:
        return IndexerRequestFailed(message, err);
      case SmartAccountErrorCode.indexerTimeout:
        return IndexerTimeout(message, err);
    }
  }

  static String _extractMessage(Object err) {
    if (err is Exception) {
      final asString = err.toString();
      if (asString.isNotEmpty) {
        return asString;
      }
    }
    if (err is Error) {
      final asString = err.toString();
      if (asString.isNotEmpty) {
        return asString;
      }
    }
    return err.toString();
  }

  static String? _causeMessage(Object? cause) {
    if (cause == null) {
      return null;
    }
    if (cause is SmartAccountException) {
      return cause.message;
    }
    final text = cause.toString();
    return text.isEmpty ? null : text;
  }
}

/// Configuration-related errors (1xxx range).
sealed class ConfigurationException extends SmartAccountException {
  /// Constructs a configuration exception with the given [code], [message],
  /// and optional [cause].
  const ConfigurationException(super.code, super.message, [super.cause]);

  /// Creates an invalid configuration error using the standard message format
  /// `"Invalid configuration: <details>"`.
  static InvalidConfig invalidConfig(String details, {Object? cause}) =>
      InvalidConfig('Invalid configuration: $details', cause);

  /// Creates a missing configuration error using the standard message format
  /// `"Missing required configuration: <param>"`.
  static MissingConfig missingConfig(String param, {Object? cause}) =>
      MissingConfig('Missing required configuration: $param', cause);
}

/// Configuration is structurally invalid.
final class InvalidConfig extends ConfigurationException {
  /// Constructs an invalid-configuration exception with the given [message]
  /// and optional [cause].
  const InvalidConfig(String message, [Object? cause])
      : super(SmartAccountErrorCode.invalidConfig, message, cause);
}

/// A required configuration parameter is missing.
final class MissingConfig extends ConfigurationException {
  /// Constructs a missing-configuration exception with the given [message]
  /// and optional [cause].
  const MissingConfig(String message, [Object? cause])
      : super(SmartAccountErrorCode.missingConfig, message, cause);
}

/// Wallet state-related errors (2xxx range).
sealed class WalletException extends SmartAccountException {
  /// Constructs a wallet-state exception with the given [code], [message],
  /// and optional [cause].
  const WalletException(super.code, super.message, [super.cause]);

  /// Creates a wallet-not-connected error. When [details] is omitted the
  /// default message `"Wallet is not connected"` is used.
  static WalletNotConnected notConnected({String? details, Object? cause}) =>
      WalletNotConnected(
        message: details ?? 'Wallet is not connected',
        cause: cause,
      );

  /// Creates a wallet-already-exists error using the message format
  /// `"Wallet already exists: <identifier>"`.
  static WalletAlreadyExists alreadyExists(String identifier,
          {Object? cause}) =>
      WalletAlreadyExists('Wallet already exists: $identifier', cause);

  /// Creates a wallet-not-found error using the message format
  /// `"Wallet not found: <identifier>"`.
  static WalletNotFound notFound(String identifier, {Object? cause}) =>
      WalletNotFound('Wallet not found: $identifier', cause);
}

/// Operation requires a connected wallet, but none is connected.
final class WalletNotConnected extends WalletException {
  /// Constructs a wallet-not-connected exception. The [message] defaults to
  /// `"Wallet is not connected"`.
  const WalletNotConnected({
    String message = 'Wallet is not connected',
    Object? cause,
  }) : super(SmartAccountErrorCode.walletNotConnected, message, cause);
}

/// A wallet with the same identifier already exists.
final class WalletAlreadyExists extends WalletException {
  /// Constructs a wallet-already-exists exception with the given [message]
  /// and optional [cause].
  const WalletAlreadyExists(String message, [Object? cause])
      : super(SmartAccountErrorCode.walletAlreadyExists, message, cause);
}

/// The requested wallet could not be found.
final class WalletNotFound extends WalletException {
  /// Constructs a wallet-not-found exception with the given [message]
  /// and optional [cause].
  const WalletNotFound(String message, [Object? cause])
      : super(SmartAccountErrorCode.walletNotFound, message, cause);
}

/// Credential-related errors (3xxx range).
sealed class CredentialException extends SmartAccountException {
  /// Constructs a credential exception with the given [code], [message],
  /// and optional [cause].
  const CredentialException(super.code, super.message, [super.cause]);

  /// Creates a credential-not-found error using the message format
  /// `"Credential not found: <credentialId>"`.
  static CredentialNotFound notFound(String credentialId, {Object? cause}) =>
      CredentialNotFound('Credential not found: $credentialId', cause);

  /// Creates a credential-already-exists error using the message format
  /// `"Credential already exists: <credentialId>"`.
  static CredentialAlreadyExists alreadyExists(String credentialId,
          {Object? cause}) =>
      CredentialAlreadyExists('Credential already exists: $credentialId', cause);

  /// Creates an invalid-credential error using the message format
  /// `"Invalid credential: <reason>"`.
  static CredentialInvalid invalid(String reason, {Object? cause}) =>
      CredentialInvalid('Invalid credential: $reason', cause);

  /// Creates a credential-deployment-failed error using the message format
  /// `"Credential deployment failed: <reason>"`.
  static CredentialDeploymentFailed deploymentFailed(String reason,
          {Object? cause}) =>
      CredentialDeploymentFailed(
          'Credential deployment failed: $reason', cause);
}

/// The requested credential could not be found.
final class CredentialNotFound extends CredentialException {
  /// Constructs a credential-not-found exception with the given [message]
  /// and optional [cause].
  const CredentialNotFound(String message, [Object? cause])
      : super(SmartAccountErrorCode.credentialNotFound, message, cause);
}

/// A credential with the same identifier already exists.
final class CredentialAlreadyExists extends CredentialException {
  /// Constructs a credential-already-exists exception with the given [message]
  /// and optional [cause].
  const CredentialAlreadyExists(String message, [Object? cause])
      : super(SmartAccountErrorCode.credentialAlreadyExists, message, cause);
}

/// The credential is invalid or malformed.
final class CredentialInvalid extends CredentialException {
  /// Constructs an invalid-credential exception with the given [message]
  /// and optional [cause].
  const CredentialInvalid(String message, [Object? cause])
      : super(SmartAccountErrorCode.credentialInvalid, message, cause);
}

/// Credential deployment failed.
final class CredentialDeploymentFailed extends CredentialException {
  /// Constructs a credential-deployment-failed exception with the given
  /// [message] and optional [cause].
  const CredentialDeploymentFailed(String message, [Object? cause])
      : super(SmartAccountErrorCode.credentialDeploymentFailed, message, cause);
}

/// WebAuthn-related errors (4xxx range).
sealed class WebAuthnException extends SmartAccountException {
  /// Constructs a WebAuthn exception with the given [code], [message],
  /// and optional [cause].
  const WebAuthnException(super.code, super.message, [super.cause]);

  /// Creates a WebAuthn registration-failed error using the message format
  /// `"WebAuthn registration failed: <reason>"`.
  static WebAuthnRegistrationFailed registrationFailed(String reason,
          {Object? cause}) =>
      WebAuthnRegistrationFailed(
          'WebAuthn registration failed: $reason', cause);

  /// Creates a WebAuthn authentication-failed error using the message format
  /// `"WebAuthn authentication failed: <reason>"`.
  static WebAuthnAuthenticationFailed authenticationFailed(String reason,
          {Object? cause}) =>
      WebAuthnAuthenticationFailed(
          'WebAuthn authentication failed: $reason', cause);

  /// Creates a WebAuthn-not-supported error. When [details] is omitted the
  /// default message `"WebAuthn is not supported on this platform"` is used.
  static WebAuthnNotSupported notSupported({String? details, Object? cause}) =>
      WebAuthnNotSupported(
        message: details ?? 'WebAuthn is not supported on this platform',
        cause: cause,
      );

  /// Creates a user-cancelled WebAuthn operation error with the default
  /// message `"User cancelled WebAuthn operation"`.
  static WebAuthnCancelled cancelled({Object? cause}) =>
      WebAuthnCancelled(cause: cause);
}

/// WebAuthn registration failed.
final class WebAuthnRegistrationFailed extends WebAuthnException {
  /// Constructs a registration-failed exception with the given [message]
  /// and optional [cause].
  const WebAuthnRegistrationFailed(String message, [Object? cause])
      : super(SmartAccountErrorCode.webauthnRegistrationFailed, message, cause);
}

/// WebAuthn authentication failed.
final class WebAuthnAuthenticationFailed extends WebAuthnException {
  /// Constructs an authentication-failed exception with the given [message]
  /// and optional [cause].
  const WebAuthnAuthenticationFailed(String message, [Object? cause])
      : super(SmartAccountErrorCode.webauthnAuthenticationFailed, message,
            cause);
}

/// WebAuthn is not supported on the current platform.
final class WebAuthnNotSupported extends WebAuthnException {
  /// Constructs a not-supported exception. The [message] defaults to
  /// `"WebAuthn is not supported on this platform"`.
  const WebAuthnNotSupported({
    String message = 'WebAuthn is not supported on this platform',
    Object? cause,
  }) : super(SmartAccountErrorCode.webauthnNotSupported, message, cause);
}

/// The user cancelled the WebAuthn operation.
final class WebAuthnCancelled extends WebAuthnException {
  /// Constructs a cancelled exception. The [message] defaults to
  /// `"User cancelled WebAuthn operation"`.
  const WebAuthnCancelled({
    String message = 'User cancelled WebAuthn operation',
    Object? cause,
  }) : super(SmartAccountErrorCode.webauthnCancelled, message, cause);
}

/// Transaction-related errors (5xxx range).
sealed class TransactionException extends SmartAccountException {
  /// Constructs a transaction exception with the given [code], [message],
  /// and optional [cause].
  const TransactionException(super.code, super.message, [super.cause]);

  /// Creates a transaction-simulation-failed error using the message format
  /// `"Transaction simulation failed: <reason>"`.
  static TransactionSimulationFailed simulationFailed(String reason,
          {Object? cause}) =>
      TransactionSimulationFailed(
          'Transaction simulation failed: $reason', cause);

  /// Creates a transaction-signing-failed error using the message format
  /// `"Transaction signing failed: <reason>"`.
  static TransactionSigningFailed signingFailed(String reason,
          {Object? cause}) =>
      TransactionSigningFailed('Transaction signing failed: $reason', cause);

  /// Creates a transaction-submission-failed error using the message format
  /// `"Transaction submission failed: <reason>"`.
  static TransactionSubmissionFailed submissionFailed(String reason,
          {Object? cause}) =>
      TransactionSubmissionFailed(
          'Transaction submission failed: $reason', cause);

  /// Creates a transaction-timeout error. When [details] is omitted the
  /// default message `"Transaction timed out"` is used.
  static TransactionTimeout timeout({String? details, Object? cause}) =>
      TransactionTimeout(
        message: details ?? 'Transaction timed out',
        cause: cause,
      );
}

/// Transaction simulation failed.
final class TransactionSimulationFailed extends TransactionException {
  /// Constructs a simulation-failed exception with the given [message]
  /// and optional [cause].
  const TransactionSimulationFailed(String message, [Object? cause])
      : super(SmartAccountErrorCode.transactionSimulationFailed, message,
            cause);
}

/// Transaction signing failed.
final class TransactionSigningFailed extends TransactionException {
  /// Constructs a signing-failed exception with the given [message]
  /// and optional [cause].
  const TransactionSigningFailed(String message, [Object? cause])
      : super(SmartAccountErrorCode.transactionSigningFailed, message, cause);
}

/// Transaction submission failed.
final class TransactionSubmissionFailed extends TransactionException {
  /// Constructs a submission-failed exception with the given [message]
  /// and optional [cause].
  const TransactionSubmissionFailed(String message, [Object? cause])
      : super(SmartAccountErrorCode.transactionSubmissionFailed, message,
            cause);
}

/// Transaction did not reach a final state within the allotted time.
final class TransactionTimeout extends TransactionException {
  /// Constructs a transaction-timeout exception. The [message] defaults to
  /// `"Transaction timed out"`.
  const TransactionTimeout({
    String message = 'Transaction timed out',
    Object? cause,
  }) : super(SmartAccountErrorCode.transactionTimeout, message, cause);
}

/// Signer-related errors (6xxx range).
sealed class SignerException extends SmartAccountException {
  /// Constructs a signer exception with the given [code], [message],
  /// and optional [cause].
  const SignerException(super.code, super.message, [super.cause]);

  /// Creates a signer-not-found error using the message format
  /// `"Signer not found: <signerId>"`.
  static SignerNotFound notFound(String signerId, {Object? cause}) =>
      SignerNotFound('Signer not found: $signerId', cause);

  /// Creates an invalid-signer error using the message format
  /// `"Invalid signer: <reason>"`.
  static SignerInvalid invalid(String reason, {Object? cause}) =>
      SignerInvalid('Invalid signer: $reason', cause);
}

/// The requested signer could not be found.
final class SignerNotFound extends SignerException {
  /// Constructs a signer-not-found exception with the given [message]
  /// and optional [cause].
  const SignerNotFound(String message, [Object? cause])
      : super(SmartAccountErrorCode.signerNotFound, message, cause);
}

/// The signer is invalid or malformed.
final class SignerInvalid extends SignerException {
  /// Constructs an invalid-signer exception with the given [message]
  /// and optional [cause].
  const SignerInvalid(String message, [Object? cause])
      : super(SmartAccountErrorCode.signerInvalid, message, cause);
}

/// Validation-related errors (7xxx range).
sealed class ValidationException extends SmartAccountException {
  /// Constructs a validation exception with the given [code], [message],
  /// and optional [cause].
  const ValidationException(super.code, super.message, [super.cause]);

  /// Creates an invalid-address error using the message format
  /// `"Invalid address: <address>"`.
  static InvalidAddress invalidAddress(String address, {Object? cause}) =>
      InvalidAddress('Invalid address: $address', cause);

  /// Creates an invalid-amount error using the message format
  /// `"Invalid amount: <amount>"`, optionally followed by ` - <reason>`
  /// when [reason] is supplied.
  static InvalidAmount invalidAmount(String amount,
      {String? reason, Object? cause}) {
    final suffix = reason == null ? '' : ' - $reason';
    return InvalidAmount('Invalid amount: $amount$suffix', cause);
  }

  /// Creates an invalid-input error using the message format
  /// `"Invalid input for <field>: <reason>"`.
  static InvalidInput invalidInput(String field, String reason,
          {Object? cause}) =>
      InvalidInput('Invalid input for $field: $reason', cause);
}

/// The supplied address is not a valid Stellar address.
final class InvalidAddress extends ValidationException {
  /// Constructs an invalid-address exception with the given [message]
  /// and optional [cause].
  const InvalidAddress(String message, [Object? cause])
      : super(SmartAccountErrorCode.invalidAddress, message, cause);
}

/// The supplied amount is not valid.
final class InvalidAmount extends ValidationException {
  /// Constructs an invalid-amount exception with the given [message]
  /// and optional [cause].
  const InvalidAmount(String message, [Object? cause])
      : super(SmartAccountErrorCode.invalidAmount, message, cause);
}

/// The supplied input is not valid.
final class InvalidInput extends ValidationException {
  /// Constructs an invalid-input exception with the given [message]
  /// and optional [cause].
  const InvalidInput(String message, [Object? cause])
      : super(SmartAccountErrorCode.invalidInput, message, cause);
}

/// Storage-related errors (8xxx range).
sealed class StorageException extends SmartAccountException {
  /// Constructs a storage exception with the given [code], [message],
  /// and optional [cause].
  const StorageException(super.code, super.message, [super.cause]);

  /// Creates a storage-read-failed error using the message format
  /// `"Storage read failed for key: <key>"`.
  static StorageReadFailed readFailed(String key, {Object? cause}) =>
      StorageReadFailed('Storage read failed for key: $key', cause);

  /// Creates a storage-write-failed error using the message format
  /// `"Storage write failed for key: <key>"`.
  static StorageWriteFailed writeFailed(String key, {Object? cause}) =>
      StorageWriteFailed('Storage write failed for key: $key', cause);
}

/// Reading from the storage backend failed.
final class StorageReadFailed extends StorageException {
  /// Constructs a storage-read-failed exception with the given [message]
  /// and optional [cause].
  const StorageReadFailed(String message, [Object? cause])
      : super(SmartAccountErrorCode.storageReadFailed, message, cause);
}

/// Writing to the storage backend failed.
final class StorageWriteFailed extends StorageException {
  /// Constructs a storage-write-failed exception with the given [message]
  /// and optional [cause].
  const StorageWriteFailed(String message, [Object? cause])
      : super(SmartAccountErrorCode.storageWriteFailed, message, cause);
}

/// Session-related errors (9xxx range).
sealed class SessionException extends SmartAccountException {
  /// Constructs a session exception with the given [code], [message],
  /// and optional [cause].
  const SessionException(super.code, super.message, [super.cause]);

  /// Creates a session-expired error. When [sessionId] is provided the
  /// message format is `"Session expired: <sessionId>"`; otherwise the
  /// default message `"Session has expired"` is used.
  static SessionExpired expired({String? sessionId, Object? cause}) =>
      SessionExpired(
        message: sessionId == null
            ? 'Session has expired'
            : 'Session expired: $sessionId',
        cause: cause,
      );

  /// Creates an invalid-session error using the message format
  /// `"Invalid session: <reason>"`.
  static SessionInvalid invalid(String reason, {Object? cause}) =>
      SessionInvalid('Invalid session: $reason', cause);
}

/// Session has expired.
final class SessionExpired extends SessionException {
  /// Constructs a session-expired exception. The [message] defaults to
  /// `"Session has expired"`.
  const SessionExpired({
    String message = 'Session has expired',
    Object? cause,
  }) : super(SmartAccountErrorCode.sessionExpired, message, cause);
}

/// Session is invalid or malformed.
final class SessionInvalid extends SessionException {
  /// Constructs a session-invalid exception with the given [message]
  /// and optional [cause].
  const SessionInvalid(String message, [Object? cause])
      : super(SmartAccountErrorCode.sessionInvalid, message, cause);
}

/// Indexer-related errors (10xxx range).
sealed class IndexerException extends SmartAccountException {
  /// Constructs an indexer exception with the given [code], [message],
  /// and optional [cause].
  const IndexerException(super.code, super.message, [super.cause]);

  /// Creates an indexer request-failed error using the message format
  /// `"Indexer request failed: <reason>"`.
  static IndexerRequestFailed requestFailed(String reason, {Object? cause}) =>
      IndexerRequestFailed('Indexer request failed: $reason', cause);

  /// Creates an indexer timeout error using the message format
  /// `"Indexer request timed out: <url>"`.
  static IndexerTimeout timeout(String url, {Object? cause}) =>
      IndexerTimeout('Indexer request timed out: $url', cause);
}

/// The indexer request failed (network error or non-success HTTP status).
final class IndexerRequestFailed extends IndexerException {
  /// Constructs an indexer request-failed exception with the given [message]
  /// and optional [cause].
  const IndexerRequestFailed(String message, [Object? cause])
      : super(SmartAccountErrorCode.indexerRequestFailed, message, cause);
}

/// The indexer request timed out.
final class IndexerTimeout extends IndexerException {
  /// Constructs an indexer timeout exception with the given [message]
  /// and optional [cause].
  const IndexerTimeout(String message, [Object? cause])
      : super(SmartAccountErrorCode.indexerTimeout, message, cause);
}

/// Contract-level error codes from the OpenZeppelin smart account contract.
///
/// These codes are returned in failed contract responses and can be mapped to
/// SDK exceptions by code-aware error handlers when interpreting transaction
/// results. The numeric range is `3xxx` (credential errors), aligned with the
/// contract's own `Error` enum.
class ContractErrorCodes {
  /// Private constructor prevents instantiation; this class exposes only
  /// static constants.
  ContractErrorCodes._();

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
}
