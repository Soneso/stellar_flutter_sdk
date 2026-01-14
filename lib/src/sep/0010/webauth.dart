// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../constants/network_constants.dart';
import '../../key_pair.dart';
import '../../muxed_account.dart';
import '../../network.dart';
import '../../requests/request_builder.dart';
import '../../responses/challenge_response.dart';
import '../../responses/response.dart';
import '../../transaction.dart';
import '../../xdr/xdr_memo.dart';
import '../../xdr/xdr_operation.dart';
import '../../xdr/xdr_signing.dart';
import '../../xdr/xdr_transaction.dart';
import '../0001/stellar_toml.dart';

/// Implements SEP-0010 Web Authentication protocol for Stellar applications.
///
/// This class implements SEP-0010 version 3.4.1, which defines a standard protocol
/// for authenticating users of Stellar applications using their Stellar account.
/// This is commonly used by anchors and services to verify that a user controls
/// a specific Stellar account before allowing access to services.
///
/// The authentication flow follows a challenge-response pattern:
/// 1. Client requests a challenge transaction from the auth server
/// 2. Server generates and signs a transaction with specific requirements
/// 3. Client validates the challenge transaction
/// 4. Client signs the transaction with their account key(s)
/// 5. Client submits the signed transaction back to the server
/// 6. Server validates the signatures and returns a JWT token
///
/// The JWT token can then be used to authenticate API requests to SEP-6, SEP-12,
/// SEP-24, SEP-31, and other Stellar services.
///
/// Security considerations:
/// - Always validate the challenge transaction before signing
/// - Verify the server's signing key matches the stellar.toml configuration
/// - Use HTTPS for all communication with the auth endpoint
/// - JWT tokens have expiration times; refresh as needed
/// - Never expose account secret keys in client-side code
///
/// CORS requirements for browser-based clients:
/// - The authentication endpoints must return proper CORS headers
/// - The server must set `Access-Control-Allow-Origin: *` for all responses
/// - Preflight OPTIONS requests must be supported for all endpoints
/// - This allows browser-based wallets to authenticate without CORS errors
///
/// Example - Basic authentication flow:
/// ```dart
/// // Create WebAuth from a domain's stellar.toml
/// final webAuth = await WebAuth.fromDomain('testanchor.stellar.org', Network.TESTNET);
///
/// // User's keypair (in production, never hardcode this!)
/// final userKeyPair = KeyPair.fromSecretSeed('S...');
///
/// // Authenticate and get JWT token
/// final jwtToken = await webAuth.jwtToken(
///   userKeyPair.accountId,
///   [userKeyPair],
/// );
///
/// // Use the JWT token for authenticated requests
/// print('Authentication successful. Token: $jwtToken');
/// ```
///
/// Example - Multi-signature account:
/// ```dart
/// // For accounts requiring multiple signatures
/// final webAuth = await WebAuth.fromDomain('example.com', Network.PUBLIC);
///
/// final signer1 = KeyPair.fromSecretSeed('S...');
/// final signer2 = KeyPair.fromSecretSeed('S...');
///
/// final jwtToken = await webAuth.jwtToken(
///   'GACCOUNT...',
///   [signer1, signer2], // Provide all required signers
/// );
/// ```
///
/// Example - Muxed account with memo:
/// ```dart
/// // For muxed accounts or accounts using memos
/// final webAuth = await WebAuth.fromDomain('example.com', Network.PUBLIC);
/// final userKeyPair = KeyPair.fromSecretSeed('S...');
///
/// final jwtToken = await webAuth.jwtToken(
///   userKeyPair.accountId,
///   [userKeyPair],
///   memo: 12345, // Required for some anchor configurations
/// );
/// ```
///
/// Example - Client domain authentication:
/// ```dart
/// // When your application wants to prove its domain ownership
/// final webAuth = await WebAuth.fromDomain('anchor.example.com', Network.PUBLIC);
/// final userKeyPair = KeyPair.fromSecretSeed('S...');
/// final clientDomainKeyPair = KeyPair.fromSecretSeed('S...'); // Your domain's signing key
///
/// final jwtToken = await webAuth.jwtToken(
///   userKeyPair.accountId,
///   [userKeyPair],
///   clientDomain: 'wallet.mycompany.com',
///   clientDomainAccountKeyPair: clientDomainKeyPair,
/// );
/// ```
///
/// See also:
/// - [SEP-0010 Specification](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0010.md)
/// - [fromDomain] for easy initialization from stellar.toml
/// - [jwtToken] for the complete authentication flow
/// - [StellarToml] for discovering service endpoints
class WebAuth {
  String _authEndpoint;
  String _serverSigningKey;
  Network _network;
  String _serverHomeDomain;
  late http.Client httpClient;
  int gracePeriod = NetworkConstants.WEBAUTH_GRACE_PERIOD_SECONDS;
  Map<String, String>? httpRequestHeaders;

  /// Creates a WebAuth instance with explicit configuration.
  ///
  /// For most use cases, prefer using [fromDomain] which automatically
  /// discovers the configuration from stellar.toml.
  ///
  /// Parameters:
  /// - [_authEndpoint] The authentication endpoint URL (from stellar.toml WEB_AUTH_ENDPOINT)
  /// - [_network] The Stellar network (Network.PUBLIC or Network.TESTNET)
  /// - [_serverSigningKey] The server's public signing key (from stellar.toml SIGNING_KEY)
  /// - [_serverHomeDomain] The home domain of the server
  /// - [httpClient] Optional custom HTTP client for testing or proxy configuration
  /// - [httpRequestHeaders] Optional custom HTTP headers for all requests
  ///
  /// Example:
  /// ```dart
  /// final webAuth = WebAuth(
  ///   'https://example.com/auth',
  ///   Network.PUBLIC,
  ///   'GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP',
  ///   'example.com',
  /// );
  /// ```
  WebAuth(this._authEndpoint, this._network, this._serverSigningKey,
      this._serverHomeDomain,
      {http.Client? httpClient, this.httpRequestHeaders}) {
    this.httpClient = httpClient ?? http.Client();
  }

  /// Creates a WebAuth instance by automatically discovering configuration from stellar.toml.
  ///
  /// This is the recommended way to initialize WebAuth. It fetches the stellar.toml
  /// file from the specified domain and extracts the required configuration:
  /// - WEB_AUTH_ENDPOINT: The authentication endpoint URL
  /// - SIGNING_KEY: The server's public signing key for validating challenges
  ///
  /// Parameters:
  /// - [domain] The domain name (without protocol) hosting the stellar.toml file
  /// - [network] The Stellar network (Network.PUBLIC or Network.TESTNET)
  /// - [httpClient] Optional custom HTTP client for testing or proxy configuration
  /// - [httpRequestHeaders] Optional custom HTTP headers for requests
  ///
  /// Returns: Future<WebAuth> configured with the domain's settings
  ///
  /// Throws:
  /// - [NoWebAuthEndpointFoundException] If WEB_AUTH_ENDPOINT is missing from stellar.toml
  /// - [NoWebAuthServerSigningKeyFoundException] If SIGNING_KEY is missing from stellar.toml
  /// - [Exception] If stellar.toml cannot be fetched or parsed
  ///
  /// Example:
  /// ```dart
  /// // Initialize from a domain's stellar.toml
  /// final webAuth = await WebAuth.fromDomain(
  ///   'testanchor.stellar.org',
  ///   Network.TESTNET,
  /// );
  ///
  /// // Then use for authentication
  /// final userKeyPair = KeyPair.fromSecretSeed('S...');
  /// final token = await webAuth.jwtToken(userKeyPair.accountId, [userKeyPair]);
  /// ```
  ///
  /// Example with error handling:
  /// ```dart
  /// try {
  ///   final webAuth = await WebAuth.fromDomain('example.com', Network.PUBLIC);
  /// } on NoWebAuthEndpointFoundException catch (e) {
  ///   print('Domain does not support WebAuth: ${e.domain}');
  /// } catch (e) {
  ///   print('Failed to initialize WebAuth: $e');
  /// }
  /// ```
  static Future<WebAuth> fromDomain(
    String domain,
    Network network, {
    http.Client? httpClient,
    Map<String, String>? httpRequestHeaders,
  }) async {
    final StellarToml toml = await StellarToml.fromDomain(
      domain,
      httpClient: httpClient,
      httpRequestHeaders: httpRequestHeaders,
    );

    if (toml.generalInformation.webAuthEndpoint == null) {
      throw NoWebAuthEndpointFoundException(domain);
    }
    if (toml.generalInformation.signingKey == null) {
      throw NoWebAuthServerSigningKeyFoundException(domain);
    }

    return new WebAuth(toml.generalInformation.webAuthEndpoint!, network,
        toml.generalInformation.signingKey!, domain,
        httpClient: httpClient);
  }

  /// Performs the complete SEP-0010 authentication flow and returns a JWT token.
  ///
  /// This is the primary method for authenticating a user. It handles the entire
  /// challenge-response flow automatically:
  /// 1. Requests a challenge transaction from the server
  /// 2. Validates the challenge transaction
  /// 3. Signs the transaction with the provided keypair(s)
  /// 4. Submits the signed transaction to the server
  /// 5. Returns the JWT token from the server
  ///
  /// The returned JWT token can be used to authenticate requests to SEP-6, SEP-12,
  /// SEP-24, SEP-31, and other protected endpoints.
  ///
  /// Parameters:
  /// - [clientAccountId] The Stellar account ID to authenticate (G... or M... address)
  /// - [signers] List of keypairs (with secret seeds) needed to sign for the account.
  ///   For single-signature accounts, provide one keypair. For multi-signature accounts,
  ///   provide all required signers.
  /// - [memo] Optional ID memo if using a muxed account that starts with G. Not allowed
  ///   for M... addresses as they encode the memo.
  /// - [homeDomain] Optional home domain if the auth server serves multiple domains
  /// - [clientDomain] Optional domain of the client application. When provided, proves
  ///   that the client controls this domain by signing with the domain's key.
  /// - [clientDomainAccountKeyPair] Optional keypair for the client domain's signing key
  ///   (required if clientDomain is provided and no signing delegate is used)
  /// - [clientDomainSigningDelegate] Optional async callback to sign the challenge with
  ///   the client domain key. Use this when the domain key is stored securely elsewhere.
  ///
  /// Returns: Future<String> containing the JWT authentication token
  ///
  /// Throws:
  /// - [ChallengeValidationError] If the challenge transaction is invalid
  /// - [SubmitCompletedChallengeErrorResponseException] If server rejects the signed challenge
  /// - [NoMemoForMuxedAccountsException] If memo is provided for M... address
  /// - [MissingClientDomainException] If signing delegate is provided without client domain
  ///
  /// Example - Basic authentication:
  /// ```dart
  /// final webAuth = await WebAuth.fromDomain('testanchor.stellar.org', Network.TESTNET);
  /// final userKeyPair = KeyPair.fromSecretSeed('SCZANGBA5YHTNYVVV4C3U252E2B6P6F5T3U6MM63WBSBZATAQI3EBTQ4');
  ///
  /// final jwtToken = await webAuth.jwtToken(
  ///   userKeyPair.accountId,
  ///   [userKeyPair],
  /// );
  ///
  /// print('Authenticated! Token: $jwtToken');
  /// // Use token in subsequent API calls
  /// ```
  ///
  /// Example - Multi-signature account:
  /// ```dart
  /// // Account requires 2 of 3 signatures
  /// final signer1 = KeyPair.fromSecretSeed('S...');
  /// final signer2 = KeyPair.fromSecretSeed('S...');
  ///
  /// final jwtToken = await webAuth.jwtToken(
  ///   'GACCOUNT...',
  ///   [signer1, signer2], // Provide sufficient signers
  /// );
  /// ```
  ///
  /// Example - With client domain (proving your app's identity):
  /// ```dart
  /// final webAuth = await WebAuth.fromDomain('anchor.example.com', Network.PUBLIC);
  /// final userKeyPair = KeyPair.fromSecretSeed('S...');
  /// final clientDomainKeyPair = KeyPair.fromSecretSeed('S...'); // Your app's signing key
  ///
  /// final jwtToken = await webAuth.jwtToken(
  ///   userKeyPair.accountId,
  ///   [userKeyPair],
  ///   clientDomain: 'wallet.myapp.com',
  ///   clientDomainAccountKeyPair: clientDomainKeyPair,
  /// );
  /// ```
  ///
  /// Example - With external signing (for secure key storage):
  /// ```dart
  /// final jwtToken = await webAuth.jwtToken(
  ///   userKeyPair.accountId,
  ///   [userKeyPair],
  ///   clientDomain: 'wallet.myapp.com',
  ///   clientDomainSigningDelegate: (transactionXdr) async {
  ///     // Sign transaction using external service/hardware wallet
  ///     return await externalSigningService.sign(transactionXdr);
  ///   },
  /// );
  /// ```
  Future<String> jwtToken(String clientAccountId, List<KeyPair> signers,
      {int? memo,
      String? homeDomain,
      String? clientDomain,
      KeyPair? clientDomainAccountKeyPair,
      Future<String> Function(String transactionXdr)?
          clientDomainSigningDelegate}) async {
    // get the challenge transaction from the web auth server
    String transaction =
        await getChallenge(clientAccountId, memo, homeDomain, clientDomain);

    String? clientDomainAccountId;
    if (clientDomainAccountKeyPair != null) {
      clientDomainAccountId = clientDomainAccountKeyPair.accountId;
    } else if (clientDomainSigningDelegate != null) {
      if (clientDomain == null) {
        throw MissingClientDomainException();
      }
      final StellarToml clientToml = await StellarToml.fromDomain(
        clientDomain,
        httpClient: this.httpClient,
        httpRequestHeaders: this.httpRequestHeaders,
      );
      if (clientToml.generalInformation.signingKey == null) {
        throw NoClientDomainSigningKeyFoundException(clientDomain);
      }
      clientDomainAccountId = clientToml.generalInformation.signingKey;
    }
    // validate the transaction received from the web auth server.
    validateChallenge(transaction, clientAccountId, clientDomainAccountId,
        gracePeriod, memo); // throws if not valid

    if (clientDomainAccountKeyPair != null) {
      transaction = signTransaction(transaction, [clientDomainAccountKeyPair]);
    } else if (clientDomainSigningDelegate != null) {
      transaction = await clientDomainSigningDelegate(transaction);
    }

    List<KeyPair> mSigners = List.from(signers, growable: true);
    // sign the transaction received from the web auth server using the provided user/client keypair by parameter.
    final signedTransaction = signTransaction(transaction, mSigners);

    // request the jwt token by sending back the signed challenge transaction to the web auth server.
    final String jwtToken =
        await sendSignedChallengeTransaction(signedTransaction);

    return jwtToken;
  }

  /// Requests a challenge transaction from the WebAuth server.
  ///
  /// This is step 1 of the SEP-0010 authentication flow. The server returns a
  /// transaction that must be validated and signed by the client.
  ///
  /// Parameters:
  /// - [clientAccountId] The Stellar account ID requesting authentication
  /// - [memo] Optional ID memo for G... addresses (not allowed for M... addresses)
  /// - [homeDomain] Optional home domain if server serves multiple domains
  /// - [clientDomain] Optional client application domain for domain verification
  ///
  /// Authorization headers:
  /// The server may optionally require an Authorization header for this endpoint
  /// to protect against unauthorized access or limit usage to specific applications.
  /// If required, the client must provide a JWT token signed with either:
  /// - The client domain's signing key (if client_domain is provided)
  /// - The client account's signing key (otherwise)
  ///
  /// Set [httpRequestHeaders] with the Authorization header if needed:
  /// ```dart
  /// webAuth.httpRequestHeaders = {
  ///   'Authorization': 'Bearer eyJhbGc...',
  /// };
  /// ```
  ///
  /// Returns: Future<String> containing the base64-encoded XDR transaction envelope
  ///
  /// Throws:
  /// - [MissingTransactionInChallengeResponseException] If response lacks transaction
  /// - [ChallengeRequestErrorResponse] If server returns an error (401 if auth required, 403 if forbidden)
  ///
  /// Note: This is a low-level method. Most users should use [jwtToken] instead,
  /// which handles the complete authentication flow automatically.
  Future<String> getChallenge(String clientAccountId,
      [int? memo, String? homeDomain, String? clientDomain]) async {
    ChallengeResponse challengeResponse = await getChallengeResponse(
        clientAccountId, memo, homeDomain, clientDomain);

    String? transaction = challengeResponse.transaction;
    if (transaction == null) {
      throw MissingTransactionInChallengeResponseException();
    }
    return transaction;
  }

  /// Validates a challenge transaction according to SEP-0010 requirements.
  ///
  /// Performs comprehensive validation of the challenge transaction to ensure it
  /// is safe to sign. This includes checking:
  /// - Transaction type must be ENVELOPE_TYPE_TX
  /// - Sequence number must be 0
  /// - Memo validation for muxed accounts
  /// - All operations must be ManageData operations with correct source accounts
  /// - First operation must contain "{home_domain} auth" data name
  /// - web_auth_domain must match the auth endpoint's domain
  /// - Transaction time bounds must be valid (within grace period)
  /// - Transaction must have exactly one signature from the server
  /// - Server signature must be valid
  ///
  /// Note: This method validates the challenge structure but does NOT verify that
  /// signatures meet account thresholds. Threshold verification is performed by the
  /// server when the signed challenge is submitted. The server will:
  ///
  /// Verifying Authority to Move Funds:
  /// - Check if signatures meet the medium threshold of the client account
  /// - This verifies the client has authority similar to making payments
  /// - Appropriate for operations that move funds (like SEP-24 withdrawals)
  ///
  /// Verifying Complete Authority:
  /// - Check if signatures meet the high threshold of the client account
  /// - This verifies the client has complete control over the account
  /// - Appropriate for operations requiring full account authority
  ///
  /// Verifying Being a Signer:
  /// - Check if any valid signer of the account has signed
  /// - May allow third-party signers to authenticate
  /// - Server must decide if this level of control is sufficient for the use case
  ///
  /// Parameters:
  /// - [challengeTransaction] Base64-encoded XDR transaction envelope to validate
  /// - [userAccountId] The user's account ID that requested the challenge
  /// - [clientDomainAccountId] Optional client domain account ID if domain verification is used
  /// - [timeBoundsGracePeriod] Optional grace period in seconds for time bounds validation
  /// - [memo] Optional expected memo value for muxed accounts
  ///
  /// Throws:
  /// - [ChallengeValidationError] If transaction type or format is invalid
  /// - [ChallengeValidationErrorInvalidSeqNr] If sequence number is not 0
  /// - [ChallengeValidationErrorMemoAndMuxedAccount] If memo present with M... address
  /// - [ChallengeValidationErrorInvalidMemoType] If memo type is not MEMO_ID
  /// - [ChallengeValidationErrorInvalidMemoValue] If memo value doesn't match expected
  /// - [ChallengeValidationErrorInvalidSourceAccount] If operation source account is invalid
  /// - [ChallengeValidationErrorInvalidOperationType] If operation is not ManageData
  /// - [ChallengeValidationErrorInvalidHomeDomain] If first operation data name is incorrect
  /// - [ChallengeValidationErrorInvalidWebAuthDomain] If web_auth_domain doesn't match
  /// - [ChallengeValidationErrorInvalidTimeBounds] If time bounds are expired or invalid
  /// - [ChallengeValidationErrorInvalidSignature] If server signature is missing or invalid
  ///
  /// Note: This is a low-level method. Most users should use [jwtToken] instead,
  /// which automatically validates challenges as part of the authentication flow.
  ///
  /// Security note: Always validate challenges before signing them. This prevents
  /// attacks where a malicious server tries to get you to sign arbitrary transactions.
  void validateChallenge(String challengeTransaction, String userAccountId,
      String? clientDomainAccountId,
      [int? timeBoundsGracePeriod, int? memo]) {
    XdrTransactionEnvelope envelopeXdr =
        XdrTransactionEnvelope.fromEnvelopeXdrString(challengeTransaction);

    if (envelopeXdr.discriminant != XdrEnvelopeType.ENVELOPE_TYPE_TX) {
      throw ChallengeValidationError(
          "Invalid transaction type received in challenge");
    }

    final transaction = envelopeXdr.v1!.tx;

    if (transaction.seqNum.sequenceNumber.bigInt != BigInt.zero) {
      throw ChallengeValidationErrorInvalidSeqNr(
          "Invalid transaction, sequence number not 0");
    }

    if (transaction.memo.discriminant != XdrMemoType.MEMO_NONE) {
      if (userAccountId.startsWith("M")) {
        throw ChallengeValidationErrorMemoAndMuxedAccount(
            "Memo and muxed account (M...) found");
      } else if (transaction.memo.discriminant != XdrMemoType.MEMO_ID) {
        throw ChallengeValidationErrorInvalidMemoType("invalid memo type");
      } else if (memo != null && transaction.memo.id!.uint64 != BigInt.from(memo)) {
        throw ChallengeValidationErrorInvalidMemoValue("invalid memo value");
      }
    } else if (memo != null) {
      throw ChallengeValidationErrorInvalidMemoValue("missing memo");
    }

    if (transaction.operations.length == 0) {
      throw ChallengeValidationError("invalid number of operations (0)");
    }

    for (int i = 0; i < transaction.operations.length; i++) {
      final op = transaction.operations[i];
      if (op.sourceAccount == null) {
        throw ChallengeValidationErrorInvalidSourceAccount(
            "invalid source account (is null) in operation[$i]");
      }

      final opSourceAccountId =
          MuxedAccount.fromXdr(op.sourceAccount!).accountId;
      if (i == 0 && opSourceAccountId != userAccountId) {
        throw ChallengeValidationErrorInvalidSourceAccount(
            "invalid source account in operation[$i]");
      }

      // all operations must be manage data operations
      if (op.body.discriminant != XdrOperationType.MANAGE_DATA ||
          op.body.manageDataOp == null) {
        throw ChallengeValidationErrorInvalidOperationType(
            "invalid type of operation $i");
      }

      final dataName = op.body.manageDataOp!.dataName.string64;
      if (i > 0) {
        if (dataName == "client_domain") {
          if (opSourceAccountId != clientDomainAccountId) {
            throw ChallengeValidationErrorInvalidSourceAccount(
                "invalid source account in operation[$i]");
          }
        } else if (opSourceAccountId != _serverSigningKey) {
          throw ChallengeValidationErrorInvalidSourceAccount(
              "invalid source account in operation[$i]");
        }
      }

      if (i == 0 && dataName != _serverHomeDomain + " auth") {
        throw ChallengeValidationErrorInvalidHomeDomain(
            "invalid home domain in operation $i");
      }
      final dataValue = op.body.manageDataOp!.dataValue!.dataValue;
      if (i > 0 && dataName == "web_auth_domain") {
        final uri = Uri.parse(_authEndpoint);
        if (uri.host != String.fromCharCodes(dataValue)) {
          throw ChallengeValidationErrorInvalidWebAuthDomain(
              "invalid web auth domain in operation $i");
        }
      }
    }

    // check timebounds
    final timeBounds = transaction.preconditions.timeBounds;
    if (timeBounds != null) {
      int grace = 0;
      if (timeBoundsGracePeriod != null) {
        grace = timeBoundsGracePeriod;
      }
      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final minTime = timeBounds.minTime.uint64.toInt();
      final maxTime = timeBounds.maxTime.uint64.toInt();
      if (currentTime < minTime - grace ||
          currentTime > maxTime + grace) {
        throw ChallengeValidationErrorInvalidTimeBounds(
            "Invalid transaction, invalid time bounds");
      }
    }

    // the envelope must have one signature and it must be valid: transaction signed by the server
    final signatures = envelopeXdr.v1!.signatures;
    if (signatures.length != 1) {
      throw ChallengeValidationErrorInvalidSignature(
          "Invalid transaction envelope, invalid number of signatures");
    }
    final firstSignature = envelopeXdr.v1!.signatures[0];
    // validate signature
    final serverKeyPair = KeyPair.fromAccountId(_serverSigningKey);
    final transactionHash =
        AbstractTransaction.fromEnvelopeXdr(envelopeXdr).hash(_network);
    final valid = serverKeyPair.verify(
        transactionHash, firstSignature.signature.signature);
    if (!valid) {
      throw ChallengeValidationErrorInvalidSignature(
          "Invalid transaction envelope, invalid signature");
    }
  }

  /// Signs a challenge transaction with the provided keypairs.
  ///
  /// Adds signatures to the challenge transaction for each provided signer.
  /// Preserves existing signatures (including the server's signature).
  ///
  /// Parameters:
  /// - [challengeTransaction] Base64-encoded XDR transaction envelope
  /// - [signers] List of keypairs to sign the transaction with
  ///
  /// Returns: Base64-encoded XDR transaction envelope with additional signatures
  ///
  /// Throws:
  /// - [ChallengeValidationError] If transaction type is invalid
  ///
  /// Note: This is a low-level method. Most users should use [jwtToken] instead.
  String signTransaction(String challengeTransaction, List<KeyPair> signers) {
    XdrTransactionEnvelope envelopeXdr =
        XdrTransactionEnvelope.fromEnvelopeXdrString(challengeTransaction);

    if (envelopeXdr.discriminant != XdrEnvelopeType.ENVELOPE_TYPE_TX) {
      throw ChallengeValidationError("Invalid transaction type");
    }

    final txHash =
        AbstractTransaction.fromEnvelopeXdr(envelopeXdr).hash(_network);

    List<XdrDecoratedSignature> signatures =
        List<XdrDecoratedSignature>.empty(growable: true);
    signatures.addAll(envelopeXdr.v1!.signatures);
    for (KeyPair signer in signers) {
      signatures.add(signer.signDecorated(txHash));
    }
    envelopeXdr.v1!.signatures = signatures;
    return envelopeXdr.toEnvelopeXdrBase64();
  }

  /// Submits a signed challenge transaction to obtain a JWT token.
  ///
  /// This is the final step of the SEP-0010 authentication flow. The server
  /// validates the signatures on the challenge transaction and, if valid,
  /// returns a JWT token that can be used for authenticated API requests.
  ///
  /// Parameters:
  /// - [base64EnvelopeXDR] The signed challenge transaction as base64-encoded XDR
  ///
  /// Returns: Future<String> containing the JWT authentication token
  ///
  /// Throws:
  /// - [SubmitCompletedChallengeErrorResponseException] If server rejects the transaction
  /// - [SubmitCompletedChallengeTimeoutResponseException] If request times out (504)
  /// - [SubmitCompletedChallengeUnknownResponseException] If server returns unexpected status
  ///
  /// Note: This is a low-level method. Most users should use [jwtToken] instead,
  /// which handles the complete authentication flow automatically.
  Future<String> sendSignedChallengeTransaction(
      String base64EnvelopeXDR) async {
    Uri serverURI = Uri.parse(_authEndpoint);

    Map<String, String> headers = {...(this.httpRequestHeaders ?? {})};
    headers.putIfAbsent("Content-Type", () => "application/json");

    SubmitCompletedChallengeResponse result = await httpClient
        .post(serverURI,
            body: json.encode({"transaction": base64EnvelopeXDR}),
            headers: headers)
        .then((response) {
      SubmitCompletedChallengeResponse submitTransactionResponse;
      switch (response.statusCode) {
        case 200:
        case 400:
          submitTransactionResponse = SubmitCompletedChallengeResponse.fromJson(
              json.decode(response.body));
          break;
        case 504:
          throw new SubmitCompletedChallengeTimeoutResponseException();
        default:
          throw new SubmitCompletedChallengeUnknownResponseException(
              response.statusCode, response.body);
      }
      return submitTransactionResponse;
    }).catchError((onError) {
      throw onError;
    });

    if (result.error != null) {
      throw SubmitCompletedChallengeErrorResponseException(result.error!);
    }

    return result.jwtToken!;
  }

  /// Requests a challenge response from the WebAuth server.
  ///
  /// This is a low-level method that returns the full [ChallengeResponse] object,
  /// including the transaction XDR and optional network passphrase. Most users
  /// should use [getChallenge] or [jwtToken] instead.
  ///
  /// Parameters:
  /// - [accountId] The Stellar account ID requesting authentication
  /// - [memo] Optional ID memo for G... addresses (not allowed for M... addresses)
  /// - [homeDomain] Optional home domain if server serves multiple domains
  /// - [clientDomain] Optional client application domain for domain verification
  ///
  /// Authorization headers:
  /// The server may optionally require an Authorization header for this endpoint.
  /// See [getChallenge] for details on authorization header requirements.
  ///
  /// Returns: Future<ChallengeResponse> with transaction XDR and optional network_passphrase
  ///
  /// Throws:
  /// - [NoMemoForMuxedAccountsException] If memo is provided for M... address
  /// - [ChallengeRequestErrorResponse] If server returns an error (401/403/400)
  Future<ChallengeResponse> getChallengeResponse(String accountId,
      [int? memo, String? homeDomain, String? clientDomain]) async {
    if (memo != null && accountId.startsWith("M")) {
      throw NoMemoForMuxedAccountsException();
    }

    Uri serverURI = Uri.parse(_authEndpoint);
    try {
      _ChallengeRequestBuilder requestBuilder = new _ChallengeRequestBuilder(
          httpClient, serverURI,
          httpRequestHeaders: this.httpRequestHeaders);
      ChallengeResponse response = await requestBuilder
          .forAccountId(accountId)
          .forHomeDomain(homeDomain)
          .forClientDomain(clientDomain)
          .forMemo(memo)
          .execute();
      return response;
    } catch (e) {
      if (e is ErrorResponse) {
        throw new ChallengeRequestErrorResponse(e.response);
      } else {
        throw e;
      }
    }
  }
}

// Requests the challenge data.
class _ChallengeRequestBuilder extends RequestBuilder {
  Map<String, String>? httpRequestHeaders;
  _ChallengeRequestBuilder(http.Client httpClient, Uri serverURI,
      {this.httpRequestHeaders})
      : super(httpClient, serverURI, null);

  /// Requests challenge from the specified URI.
  Future<ChallengeResponse> challengeURI(Uri uri) async {
    TypeToken<ChallengeResponse> type = new TypeToken<ChallengeResponse>();
    ResponseHandler<ChallengeResponse> responseHandler =
        ResponseHandler<ChallengeResponse>(type);

    return await httpClient
        .get(uri, headers: httpRequestHeaders ?? {})
        .then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  /// Sets the account ID parameter for the challenge request.
  _ChallengeRequestBuilder forAccountId(String accountId) {
    queryParameters.addAll({"account": accountId});
    return this;
  }

  /// Sets the home domain parameter for the challenge request.
  _ChallengeRequestBuilder forHomeDomain(String? homeDomain) {
    if (homeDomain != null) {
      queryParameters.addAll({"home_domain": homeDomain});
    }
    return this;
  }

  /// Sets the memo parameter for the challenge request.
  _ChallengeRequestBuilder forMemo(int? memo) {
    if (memo != null) {
      queryParameters.addAll({"memo": memo.toString()});
    }
    return this;
  }

  /// Sets the client domain parameter for the challenge request.
  _ChallengeRequestBuilder forClientDomain(String? clientDomain) {
    if (clientDomain != null) {
      queryParameters.addAll({"client_domain": clientDomain});
    }
    return this;
  }

  /// Sets additional query parameters for the challenge request.
  _ChallengeRequestBuilder forQueryParameters(Map<String, String> queryParams) {
    queryParameters.addAll(queryParams);
    return this;
  }

  /// Executes challenge request to the specified URI.
  static Future<ChallengeResponse> requestExecute(
      http.Client httpClient, Uri uri,
      {Map<String, String>? httpRequestHeaders}) async {
    TypeToken<ChallengeResponse> type = new TypeToken<ChallengeResponse>();
    ResponseHandler<ChallengeResponse> responseHandler =
        new ResponseHandler<ChallengeResponse>(type);

    return await httpClient
        .get(uri, headers: httpRequestHeaders ?? {})
        .then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  /// Executes the challenge request using configured parameters.
  Future<ChallengeResponse> execute() {
    return _ChallengeRequestBuilder.requestExecute(
        this.httpClient, this.buildUri(),
        httpRequestHeaders: this.httpRequestHeaders);
  }
}

/// Exception thrown when the challenge request endpoint returns an error.
///
/// This exception wraps error responses from the GET challenge endpoint,
/// which may return different HTTP status codes depending on the error:
///
/// HTTP 401 (Unauthorized):
/// - Authorization header is required but missing
/// - Authorization header is present but the JWT is expired or invalid
///
/// HTTP 403 (Forbidden):
/// - Authorization header is valid but the application is not permitted to use the endpoint
/// - The server has rejected the specific client domain or account
///
/// HTTP 400 (Bad Request):
/// - Invalid request parameters (invalid account, memo, etc.)
/// - Malformed authorization header
///
/// Example error handling:
/// ```dart
/// try {
///   var challenge = await webAuth.getChallenge(accountId);
/// } on ChallengeRequestErrorResponse catch (e) {
///   if (e.code == 401) {
///     print('Authentication required or token expired');
///   } else if (e.code == 403) {
///     print('Access forbidden for this application');
///   } else {
///     print('Challenge request failed: ${e.body}');
///   }
/// }
/// ```
class ChallengeRequestErrorResponse extends ErrorResponse {
  /// Creates a ChallengeRequestErrorResponse from HTTP error response.
  ///
  /// Parameters:
  /// - [response] The HTTP response containing error details
  ChallengeRequestErrorResponse(super.response);
}

/// Base class for all challenge validation errors in SEP-0010 authentication.
///
/// Thrown when a challenge transaction received from the WebAuth server
/// fails validation checks according to [SEP-10](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0010.md)
/// requirements. This ensures that clients only sign legitimate challenge
/// transactions and protects against various attack vectors.
///
/// Challenge transactions must meet strict requirements:
/// - Must be ENVELOPE_TYPE_TX transaction type
/// - Must have sequence number of 0
/// - Must contain only ManageData operations
/// - Must have valid time bounds within grace period
/// - Must be signed by the server's signing key
/// - Must have correct source accounts for all operations
/// - Must include proper home domain and web auth domain values
///
/// Subclasses provide specific validation error types for different failures.
/// Always validate challenge transactions before signing them to prevent
/// signing malicious or manipulated transactions.
///
/// See also:
/// - [WebAuth.validateChallenge] for the validation implementation
/// - [SEP-10 Specification](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0010.md)
class ChallengeValidationError implements Exception {
  String _message;

  /// Creates a ChallengeValidationError with error message.
  ///
  /// Parameters:
  /// - [_message] The error message describing the validation failure
  ChallengeValidationError(this._message);

  /// Returns a string representation of this instance for debugging.
  @override
  String toString() {
    return _message;
  }
}

/// Validation error thrown when the challenge transaction has an invalid sequence number.
///
/// According to [SEP-10](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0010.md),
/// challenge transactions must have a sequence number of exactly 0. This requirement
/// ensures that the challenge transaction cannot be submitted to the Stellar network
/// as a regular transaction, preventing it from executing actual operations.
///
/// A non-zero sequence number indicates either:
/// - The server is not generating challenges correctly
/// - The transaction has been maliciously modified
/// - The response is not a valid SEP-10 challenge
///
/// This is a critical security check and should never be bypassed.
///
/// Example handling:
/// ```dart
/// try {
///   webAuth.validateChallenge(challenge, accountId, null);
/// } on ChallengeValidationErrorInvalidSeqNr catch (e) {
///   print('Invalid challenge: sequence number must be 0');
///   // Request a new challenge from the server
/// }
/// ```
class ChallengeValidationErrorInvalidSeqNr extends ChallengeValidationError {
  /// Creates a ChallengeValidationErrorInvalidSeqNr with error message.
  ///
  /// Parameters:
  /// - [message] The error message describing the invalid sequence number
  ChallengeValidationErrorInvalidSeqNr(String message) : super(message);
}

/// Validation error thrown when an operation has an invalid source account.
///
/// According to [SEP-10](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0010.md),
/// challenge transactions have strict requirements for operation source accounts:
///
/// First operation:
/// - Source account must match the client's account ID that requested the challenge
/// - This proves the challenge is intended for the specific client
///
/// Subsequent operations:
/// - For "client_domain" operations: source must be the client domain's account ID
/// - For other operations: source must be the server's signing key account ID
/// - All operations must have a source account set (not null)
///
/// Invalid source accounts indicate:
/// - Challenge was generated incorrectly by the server
/// - Transaction has been tampered with
/// - Challenge is intended for a different account
///
/// This validation prevents attacks where a challenge for one account
/// is used to authenticate a different account.
///
/// Example handling:
/// ```dart
/// try {
///   webAuth.validateChallenge(challenge, accountId, clientDomainId);
/// } on ChallengeValidationErrorInvalidSourceAccount catch (e) {
///   print('Invalid source account in challenge operations');
///   // Do not sign this challenge
/// }
/// ```
class ChallengeValidationErrorInvalidSourceAccount
    extends ChallengeValidationError {
  /// Creates a ChallengeValidationErrorInvalidSourceAccount with error message.
  ///
  /// Parameters:
  /// - [message] The error message describing the invalid source account
  ChallengeValidationErrorInvalidSourceAccount(String message) : super(message);
}

/// Validation error thrown when the challenge transaction has invalid time bounds.
///
/// According to [SEP-10](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0010.md),
/// challenge transactions should have time bounds to prevent replay attacks and
/// ensure challenges are only valid for a limited time window.
///
/// Time bounds validation checks:
/// - Current time must be within the transaction's minTime and maxTime
/// - A grace period (default 5 minutes) is applied to account for clock skew
/// - The challenge should not be expired or from the future
///
/// Invalid time bounds indicate:
/// - Challenge has expired and should not be signed
/// - Challenge's time bounds are not yet valid (future dated)
/// - Server and client clocks are significantly out of sync
/// - Challenge may be a replay of an old transaction
///
/// If a challenge fails time bounds validation, request a new challenge
/// from the server rather than attempting to sign the expired one.
///
/// Example handling:
/// ```dart
/// try {
///   webAuth.validateChallenge(challenge, accountId, null);
/// } on ChallengeValidationErrorInvalidTimeBounds catch (e) {
///   print('Challenge has expired or invalid time bounds');
///   // Request a new challenge
///   var newChallenge = await webAuth.getChallenge(accountId);
/// }
/// ```
class ChallengeValidationErrorInvalidTimeBounds
    extends ChallengeValidationError {
  /// Creates a ChallengeValidationErrorInvalidTimeBounds with error message.
  ///
  /// Parameters:
  /// - [message] The error message describing the invalid time bounds
  ChallengeValidationErrorInvalidTimeBounds(String message) : super(message);
}

/// Validation error thrown when the challenge contains an operation of incorrect type.
///
/// According to [SEP-10](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0010.md),
/// all operations in a challenge transaction must be ManageData operations.
/// ManageData operations are used because they:
/// - Cannot modify account state when signed
/// - Are safe to sign without risk of unwanted side effects
/// - Can carry arbitrary data for authentication purposes
///
/// Valid challenge operations include:
/// - First operation: ManageData with data name "{home_domain} auth"
/// - Optional operations: ManageData with data names like "web_auth_domain" or "client_domain"
///
/// Any other operation type (Payment, CreateAccount, etc.) indicates:
/// - The transaction is not a valid SEP-10 challenge
/// - The server is malicious and trying to get you to sign a real transaction
/// - The transaction has been tampered with
///
/// This is a critical security check. Never sign a challenge transaction
/// that contains non-ManageData operations.
///
/// Example handling:
/// ```dart
/// try {
///   webAuth.validateChallenge(challenge, accountId, null);
/// } on ChallengeValidationErrorInvalidOperationType catch (e) {
///   print('Challenge contains invalid operation types - potential security risk!');
///   // Do not sign - report to server administrator
/// }
/// ```
class ChallengeValidationErrorInvalidOperationType
    extends ChallengeValidationError {
  /// Creates a ChallengeValidationErrorInvalidOperationType with error message.
  ///
  /// Parameters:
  /// - [message] The error message describing the invalid operation type
  ChallengeValidationErrorInvalidOperationType(String message) : super(message);
}

/// Validation error thrown when the first operation's data name does not match expected home domain.
///
/// According to [SEP-10](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0010.md),
/// the first ManageData operation in a challenge transaction must have a data name
/// of exactly "{home_domain} auth" where {home_domain} is the server's domain.
///
/// For example:
/// - If server is "testanchor.stellar.org", data name must be "testanchor.stellar.org auth"
/// - If server is "example.com", data name must be "example.com auth"
///
/// This requirement ensures:
/// - The challenge is bound to a specific domain
/// - Prevents challenges from being reused across different servers
/// - Client knows which service they are authenticating with
///
/// Invalid home domain indicates:
/// - Challenge is from a different server than expected
/// - Transaction has been modified
/// - Server configuration error
///
/// Never sign a challenge where the home domain doesn't match the server
/// you're trying to authenticate with.
///
/// Example handling:
/// ```dart
/// try {
///   webAuth.validateChallenge(challenge, accountId, null);
/// } on ChallengeValidationErrorInvalidHomeDomain catch (e) {
///   print('Challenge home domain does not match expected server domain');
///   // Verify you are connecting to the correct server
/// }
/// ```
class ChallengeValidationErrorInvalidHomeDomain
    extends ChallengeValidationError {
  /// Creates a ChallengeValidationErrorInvalidHomeDomain with error message.
  ///
  /// Parameters:
  /// - [message] The error message describing the invalid home domain
  ChallengeValidationErrorInvalidHomeDomain(String message) : super(message);
}

/// Validation error thrown when the web_auth_domain value does not match the auth endpoint domain.
///
/// According to [SEP-10](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0010.md),
/// if a ManageData operation contains a data name "web_auth_domain", its value must
/// match the domain (host) portion of the authentication endpoint URL.
///
/// For example:
/// - If auth endpoint is "https://auth.example.com/api/auth", web_auth_domain must be "auth.example.com"
/// - If auth endpoint is "https://example.com:8080/auth", web_auth_domain must be "example.com"
///
/// This validation protects against homograph attacks where:
/// - A malicious server with a similar-looking domain tries to impersonate the real server
/// - The challenge is being served from a different domain than expected
/// - Man-in-the-middle attacks that redirect to a different authentication server
///
/// The web_auth_domain field was added in SEP-10 version 1.3.0 to provide
/// additional protection for browser-based wallets against domain spoofing.
///
/// Invalid web_auth_domain indicates:
/// - Challenge may be from a spoofed or malicious server
/// - Request was redirected to an unexpected domain
/// - Server configuration error
///
/// Example handling:
/// ```dart
/// try {
///   webAuth.validateChallenge(challenge, accountId, null);
/// } on ChallengeValidationErrorInvalidWebAuthDomain catch (e) {
///   print('Challenge web_auth_domain does not match endpoint domain');
///   // Security risk - do not sign this challenge
/// }
/// ```
class ChallengeValidationErrorInvalidWebAuthDomain
    extends ChallengeValidationError {
  /// Creates a ChallengeValidationErrorInvalidWebAuthDomain with error message.
  ///
  /// Parameters:
  /// - [message] The error message describing the invalid web auth domain
  ChallengeValidationErrorInvalidWebAuthDomain(String message) : super(message);
}

/// Validation error thrown when the server's signature on the challenge is invalid or missing.
///
/// According to [SEP-10](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0010.md),
/// the challenge transaction must be pre-signed by the authentication server using
/// the signing key advertised in the server's stellar.toml file.
///
/// Validation requirements:
/// - Transaction envelope must have exactly one signature initially
/// - The signature must be from the server's signing key (SIGNING_KEY in stellar.toml)
/// - The signature must be cryptographically valid for the transaction hash
/// - Signature must be computed for the correct network (TESTNET or PUBLIC)
///
/// Invalid signature indicates:
/// - Challenge was not signed by the expected server
/// - Transaction has been modified after the server signed it
/// - Wrong network passphrase was used
/// - Potential man-in-the-middle attack
/// - Server's stellar.toml SIGNING_KEY doesn't match actual signing key
///
/// This is a critical security validation. Only sign challenges that have
/// a valid signature from the server's advertised signing key.
///
/// Example handling:
/// ```dart
/// try {
///   webAuth.validateChallenge(challenge, accountId, null);
/// } on ChallengeValidationErrorInvalidSignature catch (e) {
///   print('Challenge signature is invalid or missing');
///   // Critical security issue - do not sign this challenge
///   // Verify server's SIGNING_KEY in stellar.toml
/// }
/// ```
class ChallengeValidationErrorInvalidSignature
    extends ChallengeValidationError {
  /// Creates a ChallengeValidationErrorInvalidSignature with error message.
  ///
  /// Parameters:
  /// - [message] The error message describing the invalid signature
  ChallengeValidationErrorInvalidSignature(String message) : super(message);
}

/// Validation error thrown when both a memo and muxed account (M... address) are present.
///
/// According to [SEP-10](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0010.md),
/// a challenge transaction cannot have both:
/// - A memo field set in the transaction
/// - A muxed account ID (starting with "M") as the client account
///
/// This is because muxed accounts (M... addresses) already encode a memo ID
/// within the account address itself. Having both would create ambiguity about
/// which memo value should be used.
///
/// Muxed accounts format:
/// - Muxed accounts start with "M" (e.g., "MAAAAAAAA...")
/// - They encode both a G... account ID and a memo ID
/// - Regular accounts start with "G" (e.g., "GABC...")
///
/// If using a muxed account:
/// - Do not provide a separate memo parameter
/// - The memo is already encoded in the M... address
///
/// If using a regular G... account with memo:
/// - Provide the memo as a parameter to [WebAuth.jwtToken] or [WebAuth.getChallenge]
/// - Do not use a muxed account address
///
/// Example handling:
/// ```dart
/// try {
///   // Using muxed account - no separate memo needed
///   await webAuth.jwtToken('MAAAAAAAA...', [keyPair]);
/// } on ChallengeValidationErrorMemoAndMuxedAccount catch (e) {
///   print('Cannot use memo with muxed account - memo already encoded in address');
/// }
/// ```
class ChallengeValidationErrorMemoAndMuxedAccount
    extends ChallengeValidationError {
  /// Creates a ChallengeValidationErrorMemoAndMuxedAccount with error message.
  ///
  /// Parameters:
  /// - [message] The error message describing the conflict
  ChallengeValidationErrorMemoAndMuxedAccount(String message) : super(message);
}

/// Validation error thrown when the challenge transaction has an invalid memo type.
///
/// According to [SEP-10](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0010.md),
/// if a memo is present in the challenge transaction, it must be of type MEMO_ID.
///
/// Valid memo types in Stellar:
/// - MEMO_NONE: No memo (acceptable for SEP-10)
/// - MEMO_ID: Unsigned 64-bit integer (required type if memo is present)
/// - MEMO_TEXT: UTF-8 string up to 28 bytes (not allowed in SEP-10)
/// - MEMO_HASH: 32-byte hash (not allowed in SEP-10)
/// - MEMO_RETURN: 32-byte hash (not allowed in SEP-10)
///
/// SEP-10 only allows MEMO_ID because:
/// - It's used to identify sub-accounts or users within a pooled account
/// - It matches the memo type used by exchanges and custodians
/// - It's compatible with muxed account memo encoding
///
/// Invalid memo type indicates:
/// - Server is not following SEP-10 specification
/// - Transaction may have been modified
/// - Server configuration error
///
/// Example handling:
/// ```dart
/// try {
///   webAuth.validateChallenge(challenge, accountId, null, null, memo);
/// } on ChallengeValidationErrorInvalidMemoType catch (e) {
///   print('Challenge memo must be MEMO_ID type if present');
///   // Request a new challenge or contact server administrator
/// }
/// ```
class ChallengeValidationErrorInvalidMemoType extends ChallengeValidationError {
  /// Creates a ChallengeValidationErrorInvalidMemoType with error message.
  ///
  /// Parameters:
  /// - [message] The error message describing the invalid memo type
  ChallengeValidationErrorInvalidMemoType(String message) : super(message);
}

/// Validation error thrown when the challenge transaction's memo value does not match expected.
///
/// According to [SEP-10](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0010.md),
/// if a memo was provided when requesting the challenge, the challenge transaction's
/// memo must match that exact value.
///
/// Memo matching requirements:
/// - If memo was provided in challenge request: transaction must contain that exact memo value
/// - If no memo was provided in request: transaction should have no memo (MEMO_NONE)
/// - Memo values must match exactly (same unsigned 64-bit integer)
///
/// This validation ensures:
/// - The challenge is bound to the specific sub-account or user identifier
/// - Server correctly incorporated the requested memo
/// - Challenge cannot be used for a different sub-account
///
/// Common scenarios requiring memos:
/// - Exchange or custodial wallets using pooled accounts
/// - Services that map multiple users to a single Stellar account
/// - Systems using memos to identify individual users or accounts
///
/// Invalid memo value indicates:
/// - Server returned a challenge with wrong memo
/// - Challenge is for a different sub-account
/// - Server processing error
///
/// Example handling:
/// ```dart
/// int expectedMemo = 12345;
/// try {
///   webAuth.validateChallenge(challenge, accountId, null, null, expectedMemo);
/// } on ChallengeValidationErrorInvalidMemoValue catch (e) {
///   print('Challenge memo does not match expected value: $expectedMemo');
///   // Request a new challenge with correct memo
/// }
/// ```
class ChallengeValidationErrorInvalidMemoValue
    extends ChallengeValidationError {
  /// Creates a ChallengeValidationErrorInvalidMemoValue with error message.
  ///
  /// Parameters:
  /// - [message] The error message describing the invalid memo value
  ChallengeValidationErrorInvalidMemoValue(String message) : super(message);
}

/// Exception thrown when the token endpoint returns HTTP 504 (Gateway Timeout).
///
/// This indicates that the authentication server took too long to process
/// the signed challenge transaction and the request timed out.
///
/// HTTP 504 (Gateway Timeout):
/// - The server did not receive a timely response from an upstream server
/// - The authentication process is taking longer than expected
/// - Network connectivity issues may be present
///
/// Common causes:
/// - Server overload or high latency
/// - Database or network issues on the server side
/// - Proxy or gateway timeouts in the infrastructure
///
/// Recommended action: Retry the authentication flow after a brief delay.
///
/// Example:
/// ```dart
/// try {
///   var token = await webAuth.sendSignedChallengeTransaction(signedXdr);
/// } on SubmitCompletedChallengeTimeoutResponseException {
///   // Wait and retry the entire authentication flow
///   await Future.delayed(Duration(seconds: 2));
///   var token = await webAuth.jwtToken(accountId, signers);
/// }
/// ```
class SubmitCompletedChallengeTimeoutResponseException implements Exception {
  /// Returns error message indicating HTTP 504 timeout.
  String toString() {
    return "Timeout (HTTP 504).";
  }
}

/// Exception thrown when the token endpoint returns an unexpected HTTP status code.
///
/// This indicates that the authentication server returned a response that is not
/// defined in the [SEP-10](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0010.md)
/// specification for the token endpoint.
///
/// Expected responses from token endpoint:
/// - HTTP 200: Success - returns JWT token
/// - HTTP 400: Bad request - returns error message (handled by SubmitCompletedChallengeErrorResponseException)
/// - HTTP 504: Timeout (handled by SubmitCompletedChallengeTimeoutResponseException)
///
/// Any other status code triggers this exception.
///
/// Common unexpected status codes:
/// - HTTP 500: Internal server error - server-side problem
/// - HTTP 503: Service unavailable - server temporarily down
/// - HTTP 401/403: Authentication/authorization error - server misconfiguration
/// - HTTP 404: Endpoint not found - incorrect URL or server routing issue
///
/// The [code] property contains the HTTP status code, and [body] contains
/// the response body which may have additional error details.
///
/// Recommended actions:
/// - Check server status and availability
/// - Verify the authentication endpoint URL is correct
/// - Review server logs for internal errors
/// - Retry after a delay for transient errors
///
/// Example handling:
/// ```dart
/// try {
///   var token = await webAuth.sendSignedChallengeTransaction(signedXdr);
/// } on SubmitCompletedChallengeUnknownResponseException catch (e) {
///   print('Unexpected response: HTTP ${e.code}');
///   print('Response body: ${e.body}');
///   // Check server status or contact administrator
/// }
/// ```
class SubmitCompletedChallengeUnknownResponseException implements Exception {
  int _code;
  String _body;

  /// Creates a SubmitCompletedChallengeUnknownResponseException with HTTP details.
  ///
  /// Parameters:
  /// - [_code] The HTTP status code received
  /// - [_body] The HTTP response body
  SubmitCompletedChallengeUnknownResponseException(this._code, this._body);

  /// Returns error message with HTTP status code and response body.
  String toString() {
    return "Unknown response - code: $code - body:$body";
  }

  int get code => _code;

  String get body => _body;
}

/// Exception thrown when the token endpoint returns HTTP 400 with an error message.
///
/// This indicates that the server rejected the signed challenge transaction
/// for one of several reasons related to invalid signatures or authentication.
///
/// HTTP 400 (Bad Request):
/// - Invalid or missing signatures on the challenge transaction
/// - Challenge transaction has been modified from the original
/// - Insufficient signature weight to meet required thresholds
/// - Challenge transaction has expired (time bounds exceeded)
/// - Challenge transaction was already used
/// - Signatures don't match the expected client account signers
///
/// Common causes:
/// - Signing with the wrong keypair or wrong network passphrase
/// - Not providing enough signers for a multi-signature account
/// - Challenge expired before submission (took too long to sign)
/// - Reusing a challenge transaction that was already submitted
///
/// The [error] field contains the server's error message explaining the rejection.
///
/// Example:
/// ```dart
/// try {
///   var token = await webAuth.sendSignedChallengeTransaction(signedXdr);
/// } on SubmitCompletedChallengeErrorResponseException catch (e) {
///   if (e.error.contains('expired')) {
///     print('Challenge expired. Request a new one.');
///   } else if (e.error.contains('signature')) {
///     print('Invalid signature. Check keypair and network.');
///   } else {
///     print('Authentication failed: ${e.error}');
///   }
/// }
/// ```
class SubmitCompletedChallengeErrorResponseException implements Exception {
  String _error;

  /// Creates a SubmitCompletedChallengeErrorResponseException with error message.
  ///
  /// Parameters:
  /// - [_error] The server's error message describing why the challenge was rejected
  SubmitCompletedChallengeErrorResponseException(this._error);

  /// Returns error message describing the authentication failure.
  String toString() {
    return "Error requesting jwtToken - error:$_error";
  }

  String get error => _error;
}

/// Exception thrown when WEB_AUTH_ENDPOINT is not found in the domain's stellar.toml file.
///
/// According to [SEP-10](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0010.md),
/// servers supporting web authentication must advertise their authentication endpoint
/// in their stellar.toml file using the WEB_AUTH_ENDPOINT field.
///
/// This exception is thrown by [WebAuth.fromDomain] when:
/// - The stellar.toml file is found but does not contain WEB_AUTH_ENDPOINT
/// - The WEB_AUTH_ENDPOINT field is present but empty/null
///
/// The WEB_AUTH_ENDPOINT should be a complete URL like:
/// - "https://example.com/auth"
/// - "https://api.example.com/webauth"
///
/// Possible causes:
/// - Domain does not support SEP-10 web authentication
/// - stellar.toml configuration is incomplete
/// - Wrong domain specified
/// - Server has not implemented web authentication yet
///
/// To resolve:
/// - Verify the domain supports SEP-10 authentication
/// - Check the stellar.toml file at https://domain/.well-known/stellar.toml
/// - Contact the service provider about authentication support
/// - Use a different authentication method if available
///
/// Example handling:
/// ```dart
/// try {
///   var webAuth = await WebAuth.fromDomain('example.com', Network.PUBLIC);
/// } on NoWebAuthEndpointFoundException catch (e) {
///   print('${e.domain} does not support web authentication');
///   // Try alternative authentication methods or different domain
/// }
/// ```
///
/// See also:
/// - [SEP-1](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0001.md) for stellar.toml specification
class NoWebAuthEndpointFoundException implements Exception {
  /// The domain where WEB_AUTH_ENDPOINT was not found.
  String domain;

  /// Creates a NoWebAuthEndpointFoundException for the domain.
  ///
  /// Parameters:
  /// - [domain] The domain where WEB_AUTH_ENDPOINT was not found
  NoWebAuthEndpointFoundException(this.domain);

  /// Returns error message indicating missing WEB_AUTH_ENDPOINT.
  String toString() {
    return "No WEB_AUTH_ENDPOINT found in stellar.toml for domain: $domain";
  }
}

/// Exception thrown when SIGNING_KEY is not found in the domain's stellar.toml file.
///
/// According to [SEP-10](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0010.md),
/// servers supporting web authentication must advertise their signing public key
/// in their stellar.toml file using the SIGNING_KEY field.
///
/// This exception is thrown by [WebAuth.fromDomain] when:
/// - The stellar.toml file is found but does not contain SIGNING_KEY
/// - The SIGNING_KEY field is present but empty/null
///
/// The SIGNING_KEY must be:
/// - A valid Stellar public key (starting with "G")
/// - The public key corresponding to the private key used to sign challenges
/// - Listed in the stellar.toml file for security verification
///
/// The signing key is critical for security because:
/// - Clients verify challenge signatures against this key
/// - Prevents man-in-the-middle attacks
/// - Ensures challenges come from the legitimate server
/// - Required for validating challenge transaction authenticity
///
/// Possible causes:
/// - stellar.toml configuration is incomplete
/// - Server has not set up web authentication properly
/// - Wrong domain specified
/// - stellar.toml file is outdated or misconfigured
///
/// To resolve:
/// - Verify the stellar.toml file at https://domain/.well-known/stellar.toml
/// - Contact the service provider about missing SIGNING_KEY
/// - Check if the domain supports SEP-10 authentication
///
/// Example handling:
/// ```dart
/// try {
///   var webAuth = await WebAuth.fromDomain('example.com', Network.PUBLIC);
/// } on NoWebAuthServerSigningKeyFoundException catch (e) {
///   print('${e.domain} has no signing key configured');
///   // Contact service provider or use alternative domain
/// }
/// ```
///
/// See also:
/// - [SEP-1](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0001.md) for stellar.toml specification
class NoWebAuthServerSigningKeyFoundException implements Exception {
  /// The domain where the auth server SIGNING_KEY was not found.
  String domain;

  /// Creates a NoWebAuthServerSigningKeyFoundException for the domain.
  ///
  /// Parameters:
  /// - [domain] The domain where the auth server SIGNING_KEY was not found
  NoWebAuthServerSigningKeyFoundException(this.domain);

  /// Returns error message indicating missing auth server SIGNING_KEY.
  String toString() {
    return "No auth server SIGNING_KEY found in stellar.toml for domain: $domain";
  }
}

/// Exception thrown when client domain's SIGNING_KEY is not found in stellar.toml.
///
/// According to [SEP-10](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0010.md),
/// when using client domain authentication (to prove your application's identity),
/// the client domain must advertise its signing public key in its stellar.toml file.
///
/// This exception is thrown when:
/// - [WebAuth.jwtToken] is called with clientDomain and clientDomainSigningDelegate
/// - The client domain's stellar.toml is fetched but lacks SIGNING_KEY
///
/// Client domain authentication flow:
/// 1. Client requests challenge with clientDomain parameter
/// 2. Server includes "client_domain" operation in challenge
/// 3. Client must sign with the key advertised in their stellar.toml SIGNING_KEY
/// 4. Server verifies the signature against client domain's SIGNING_KEY
///
/// This proves:
/// - The client application controls the claimed domain
/// - Authentication comes from a legitimate application
/// - Helps servers identify and trust specific client applications
///
/// Requirements for client domain:
/// - Must have a valid stellar.toml at https://clientdomain/.well-known/stellar.toml
/// - stellar.toml must contain SIGNING_KEY field
/// - SIGNING_KEY must be a valid Stellar public key (starting with "G")
/// - Private key for this public key is used to sign challenges
///
/// Possible causes:
/// - Client domain's stellar.toml is not configured
/// - stellar.toml does not contain SIGNING_KEY field
/// - Client domain does not support SEP-10 client authentication
///
/// To resolve:
/// - Add SIGNING_KEY to your client domain's stellar.toml
/// - Ensure stellar.toml is accessible at /.well-known/stellar.toml
/// - Use clientDomainAccountKeyPair parameter instead of delegate if you have the key locally
///
/// Example handling:
/// ```dart
/// try {
///   var token = await webAuth.jwtToken(
///     accountId,
///     [keyPair],
///     clientDomain: 'wallet.example.com',
///     clientDomainSigningDelegate: signingFunction,
///   );
/// } on NoClientDomainSigningKeyFoundException catch (e) {
///   print('Client domain ${e.domain} missing SIGNING_KEY in stellar.toml');
///   // Configure stellar.toml or use local signing
/// }
/// ```
class NoClientDomainSigningKeyFoundException implements Exception {
  /// The client domain where SIGNING_KEY was not found.
  String domain;

  /// Creates a NoClientDomainSigningKeyFoundException for the domain.
  ///
  /// Parameters:
  /// - [domain] The client domain where SIGNING_KEY was not found
  NoClientDomainSigningKeyFoundException(this.domain);

  /// Returns error message indicating missing client domain SIGNING_KEY.
  String toString() {
    return "No client domain SIGNING_KEY found in stellar.toml for domain: $domain";
  }
}

/// Exception thrown when clientDomainSigningDelegate is provided without clientDomain.
///
/// When using [WebAuth.jwtToken], if you provide a clientDomainSigningDelegate
/// (an async callback function to sign with the client domain's key), you must
/// also provide the clientDomain parameter.
///
/// The clientDomainSigningDelegate is used to sign the challenge transaction
/// with the client domain's signing key when that key is stored securely elsewhere
/// (such as in a hardware security module, remote signing service, or secure enclave).
///
/// However, the clientDomain is required because:
/// - The SDK needs to fetch the client domain's stellar.toml
/// - The stellar.toml contains the SIGNING_KEY to verify signatures
/// - The server needs to know which domain's key to expect
/// - The challenge includes a "client_domain" operation with this value
///
/// Correct usage patterns:
///
/// Using local keypair (no delegate):
/// ```dart
/// await webAuth.jwtToken(
///   accountId,
///   [userKeyPair],
///   clientDomain: 'wallet.example.com',
///   clientDomainAccountKeyPair: clientDomainKeyPair,
/// );
/// ```
///
/// Using external signing (delegate):
/// ```dart
/// await webAuth.jwtToken(
///   accountId,
///   [userKeyPair],
///   clientDomain: 'wallet.example.com', // Required!
///   clientDomainSigningDelegate: (xdr) async {
///     return await remoteSigningService.sign(xdr);
///   },
/// );
/// ```
///
/// Incorrect usage (throws this exception):
/// ```dart
/// await webAuth.jwtToken(
///   accountId,
///   [userKeyPair],
///   // Missing clientDomain parameter
///   clientDomainSigningDelegate: (xdr) async => await sign(xdr),
/// );
/// ```
class MissingClientDomainException implements Exception {
  MissingClientDomainException();

  /// Returns error message indicating clientDomain is required with delegate.
  String toString() {
    return "The clientDomain is required if clientDomainSigningDelegate is provided";
  }
}

/// Exception thrown when the server's challenge response does not contain a transaction.
///
/// According to [SEP-10](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0010.md),
/// when requesting a challenge from the GET challenge endpoint, the server must
/// return a JSON response containing a "transaction" field with the base64-encoded
/// XDR transaction envelope.
///
/// Expected response format:
/// ```json
/// {
///   "transaction": "AAAAAgAAAAA...",
///   "network_passphrase": "Test SDF Network ; September 2015"
/// }
/// ```
///
/// This exception is thrown by [WebAuth.getChallenge] when:
/// - The server responds with HTTP 200 but the response is missing the "transaction" field
/// - The "transaction" field is present but null or empty
/// - The response JSON is malformed
///
/// Possible causes:
/// - Server implementation error or bug
/// - Incorrect server endpoint (not a SEP-10 challenge endpoint)
/// - Server-side processing failure that returned partial response
/// - Network or proxy issues that corrupted the response
///
/// This is a server-side error that indicates:
/// - The server is not properly implementing SEP-10
/// - There may be a bug in the server's challenge generation
/// - The endpoint may not be a valid WebAuth endpoint
///
/// To resolve:
/// - Verify the endpoint URL is correct
/// - Check server logs for errors
/// - Contact the service provider about the missing transaction
/// - Ensure you're using the correct WEB_AUTH_ENDPOINT from stellar.toml
///
/// Example handling:
/// ```dart
/// try {
///   var challenge = await webAuth.getChallenge(accountId);
/// } on MissingTransactionInChallengeResponseException {
///   print('Server returned invalid challenge response - missing transaction');
///   // Report to server administrator or try alternative endpoint
/// }
/// ```
class MissingTransactionInChallengeResponseException implements Exception {
  MissingTransactionInChallengeResponseException();

  /// Returns error message indicating missing transaction in response.
  String toString() {
    return "Missing transaction in challenge response";
  }
}

/// Exception thrown when attempting to use a memo with a muxed account (M... address).
///
/// According to [SEP-10](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0010.md),
/// when using muxed accounts (addresses starting with "M"), you cannot also provide
/// a separate memo parameter.
///
/// Muxed accounts explained:
/// - Muxed accounts start with "M" (e.g., "MAAAAAAAA...")
/// - They encode both a G... account ID AND a memo ID within the address
/// - The memo is intrinsic to the muxed account identifier
/// - They were introduced to simplify deposit flows for exchanges and custodians
///
/// Why this restriction exists:
/// - Muxed accounts already contain a memo - adding another would be redundant
/// - Having two memos would create ambiguity about which one is authoritative
/// - The specification prevents this conflict by disallowing separate memos
///
/// Correct usage patterns:
///
/// Using muxed account (no separate memo):
/// ```dart
/// // Muxed account already includes memo - no memo parameter needed
/// await webAuth.jwtToken(
///   'MAAAAAAAA...', // Muxed account
///   [keyPair],
///   // No memo parameter
/// );
/// ```
///
/// Using regular account with memo:
/// ```dart
/// // Regular G... account can have separate memo
/// await webAuth.jwtToken(
///   'GABC...', // Regular account
///   [keyPair],
///   memo: 12345, // Separate memo allowed
/// );
/// ```
///
/// Incorrect usage (throws this exception):
/// ```dart
/// await webAuth.jwtToken(
///   'MAAAAAAAA...', // Muxed account
///   [keyPair],
///   memo: 12345, // Error: muxed account already has memo
/// );
/// ```
///
/// To convert between formats:
/// - Use [MuxedAccount] class to work with muxed accounts
/// - Extract the underlying G... account and memo from a muxed account
/// - Create muxed accounts from G... account + memo
class NoMemoForMuxedAccountsException implements Exception {
  NoMemoForMuxedAccountsException();

  /// Returns error message indicating memo cannot be used with muxed accounts.
  String toString() {
    return "Memo cannot be used if account is a muxed account";
  }
}
