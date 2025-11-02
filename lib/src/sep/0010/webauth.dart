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
/// SEP-0010 defines a standard protocol for authenticating users of Stellar applications
/// using their Stellar account. This is commonly used by anchors and services to verify
/// that a user controls a specific Stellar account before allowing access to services.
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
  /// - authEndpoint: The authentication endpoint URL (from stellar.toml WEB_AUTH_ENDPOINT)
  /// - network: The Stellar network (Network.PUBLIC or Network.TESTNET)
  /// - serverSigningKey: The server's public signing key (from stellar.toml SIGNING_KEY)
  /// - serverHomeDomain: The home domain of the server
  /// - httpClient: Optional custom HTTP client for testing or proxy configuration
  /// - httpRequestHeaders: Optional custom HTTP headers for all requests
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
  /// - domain: The domain name (without protocol) hosting the stellar.toml file
  /// - network: The Stellar network (Network.PUBLIC or Network.TESTNET)
  /// - httpClient: Optional custom HTTP client for testing or proxy configuration
  /// - httpRequestHeaders: Optional custom HTTP headers for requests
  ///
  /// Returns: Future<WebAuth> configured with the domain's settings
  ///
  /// Throws:
  /// - NoWebAuthEndpointFoundException: If WEB_AUTH_ENDPOINT is missing from stellar.toml
  /// - NoWebAuthServerSigningKeyFoundException: If SIGNING_KEY is missing from stellar.toml
  /// - Exception: If stellar.toml cannot be fetched or parsed
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
  /// - clientAccountId: The Stellar account ID to authenticate (G... or M... address)
  /// - signers: List of keypairs (with secret seeds) needed to sign for the account.
  ///   For single-signature accounts, provide one keypair. For multi-signature accounts,
  ///   provide all required signers.
  /// - memo: Optional ID memo if using a muxed account that starts with G. Not allowed
  ///   for M... addresses as they encode the memo.
  /// - homeDomain: Optional home domain if the auth server serves multiple domains
  /// - clientDomain: Optional domain of the client application. When provided, proves
  ///   that the client controls this domain by signing with the domain's key.
  /// - clientDomainAccountKeyPair: Optional keypair for the client domain's signing key
  ///   (required if clientDomain is provided and no signing delegate is used)
  /// - clientDomainSigningDelegate: Optional async callback to sign the challenge with
  ///   the client domain key. Use this when the domain key is stored securely elsewhere.
  ///
  /// Returns: Future<String> containing the JWT authentication token
  ///
  /// Throws:
  /// - ChallengeValidationError: If the challenge transaction is invalid
  /// - SubmitCompletedChallengeErrorResponseException: If server rejects the signed challenge
  /// - NoMemoForMuxedAccountsException: If memo is provided for M... address
  /// - MissingClientDomainException: If signing delegate is provided without client domain
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
  /// - clientAccountId: The Stellar account ID requesting authentication
  /// - memo: Optional ID memo for G... addresses (not allowed for M... addresses)
  /// - homeDomain: Optional home domain if server serves multiple domains
  /// - clientDomain: Optional client application domain for domain verification
  ///
  /// Returns: Future<String> containing the base64-encoded XDR transaction envelope
  ///
  /// Throws:
  /// - MissingTransactionInChallengeResponseException: If response lacks transaction
  /// - ChallengeRequestErrorResponse: If server returns an error
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
  /// Parameters:
  /// - challengeTransaction: Base64-encoded XDR transaction envelope to validate
  /// - userAccountId: The user's account ID that requested the challenge
  /// - clientDomainAccountId: Optional client domain account ID if domain verification is used
  /// - timeBoundsGracePeriod: Optional grace period in seconds for time bounds validation
  /// - memo: Optional expected memo value for muxed accounts
  ///
  /// Throws:
  /// - ChallengeValidationError: If transaction type or format is invalid
  /// - ChallengeValidationErrorInvalidSeqNr: If sequence number is not 0
  /// - ChallengeValidationErrorMemoAndMuxedAccount: If memo present with M... address
  /// - ChallengeValidationErrorInvalidMemoType: If memo type is not MEMO_ID
  /// - ChallengeValidationErrorInvalidMemoValue: If memo value doesn't match expected
  /// - ChallengeValidationErrorInvalidSourceAccount: If operation source account is invalid
  /// - ChallengeValidationErrorInvalidOperationType: If operation is not ManageData
  /// - ChallengeValidationErrorInvalidHomeDomain: If first operation data name is incorrect
  /// - ChallengeValidationErrorInvalidWebAuthDomain: If web_auth_domain doesn't match
  /// - ChallengeValidationErrorInvalidTimeBounds: If time bounds are expired or invalid
  /// - ChallengeValidationErrorInvalidSignature: If server signature is missing or invalid
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
      } else if (memo != null && transaction.memo.id!.uint64 != memo) {
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
      if (currentTime < timeBounds.minTime.uint64 - grace ||
          currentTime > timeBounds.maxTime.uint64 + grace) {
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
  /// - challengeTransaction: Base64-encoded XDR transaction envelope
  /// - signers: List of keypairs to sign the transaction with
  ///
  /// Returns: Base64-encoded XDR transaction envelope with additional signatures
  ///
  /// Throws:
  /// - ChallengeValidationError: If transaction type is invalid
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
  /// - base64EnvelopeXDR: The signed challenge transaction as base64-encoded XDR
  ///
  /// Returns: Future<String> containing the JWT authentication token
  ///
  /// Throws:
  /// - SubmitCompletedChallengeErrorResponseException: If server rejects the transaction
  /// - SubmitCompletedChallengeTimeoutResponseException: If request times out (504)
  /// - SubmitCompletedChallengeUnknownResponseException: If server returns unexpected status
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

  _ChallengeRequestBuilder forAccountId(String accountId) {
    queryParameters.addAll({"account": accountId});
    return this;
  }

  _ChallengeRequestBuilder forHomeDomain(String? homeDomain) {
    if (homeDomain != null) {
      queryParameters.addAll({"home_domain": homeDomain});
    }
    return this;
  }

  _ChallengeRequestBuilder forMemo(int? memo) {
    if (memo != null) {
      queryParameters.addAll({"memo": memo.toString()});
    }
    return this;
  }

  _ChallengeRequestBuilder forClientDomain(String? clientDomain) {
    if (clientDomain != null) {
      queryParameters.addAll({"client_domain": clientDomain});
    }
    return this;
  }

  _ChallengeRequestBuilder forQueryParameters(Map<String, String> queryParams) {
    queryParameters.addAll(queryParams);
    return this;
  }

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

  Future<ChallengeResponse> execute() {
    return _ChallengeRequestBuilder.requestExecute(
        this.httpClient, this.buildUri(),
        httpRequestHeaders: this.httpRequestHeaders);
  }
}

class ChallengeRequestErrorResponse extends ErrorResponse {
  ChallengeRequestErrorResponse(super.response);
}

class ChallengeValidationError implements Exception {
  String _message;

  ChallengeValidationError(this._message);

  @override
  String toString() {
    return _message;
  }
}

class ChallengeValidationErrorInvalidSeqNr extends ChallengeValidationError {
  ChallengeValidationErrorInvalidSeqNr(String message) : super(message);
}

class ChallengeValidationErrorInvalidSourceAccount
    extends ChallengeValidationError {
  ChallengeValidationErrorInvalidSourceAccount(String message) : super(message);
}

class ChallengeValidationErrorInvalidTimeBounds
    extends ChallengeValidationError {
  ChallengeValidationErrorInvalidTimeBounds(String message) : super(message);
}

class ChallengeValidationErrorInvalidOperationType
    extends ChallengeValidationError {
  ChallengeValidationErrorInvalidOperationType(String message) : super(message);
}

class ChallengeValidationErrorInvalidHomeDomain
    extends ChallengeValidationError {
  ChallengeValidationErrorInvalidHomeDomain(String message) : super(message);
}

class ChallengeValidationErrorInvalidWebAuthDomain
    extends ChallengeValidationError {
  ChallengeValidationErrorInvalidWebAuthDomain(String message) : super(message);
}

class ChallengeValidationErrorInvalidSignature
    extends ChallengeValidationError {
  ChallengeValidationErrorInvalidSignature(String message) : super(message);
}

class ChallengeValidationErrorMemoAndMuxedAccount
    extends ChallengeValidationError {
  ChallengeValidationErrorMemoAndMuxedAccount(String message) : super(message);
}

class ChallengeValidationErrorInvalidMemoType extends ChallengeValidationError {
  ChallengeValidationErrorInvalidMemoType(String message) : super(message);
}

class ChallengeValidationErrorInvalidMemoValue
    extends ChallengeValidationError {
  ChallengeValidationErrorInvalidMemoValue(String message) : super(message);
}

class SubmitCompletedChallengeTimeoutResponseException implements Exception {
  String toString() {
    return "Timeout.";
  }
}

class SubmitCompletedChallengeUnknownResponseException implements Exception {
  int _code;
  String _body;

  SubmitCompletedChallengeUnknownResponseException(this._code, this._body);

  String toString() {
    return "Unknown response - code: $code - body:$body";
  }

  int get code => _code;

  String get body => _body;
}

class SubmitCompletedChallengeErrorResponseException implements Exception {
  String _error;

  SubmitCompletedChallengeErrorResponseException(this._error);

  String toString() {
    return "Error requesting jwtToken - error:$_error";
  }

  String get error => _error;
}

class NoWebAuthEndpointFoundException implements Exception {
  String domain;

  NoWebAuthEndpointFoundException(this.domain);

  String toString() {
    return "No WEB_AUTH_ENDPOINT found in stellar.toml for domain: $domain";
  }
}

class NoWebAuthServerSigningKeyFoundException implements Exception {
  String domain;

  NoWebAuthServerSigningKeyFoundException(this.domain);

  String toString() {
    return "No auth server SIGNING_KEY found in stellar.toml for domain: $domain";
  }
}

class NoClientDomainSigningKeyFoundException implements Exception {
  String domain;

  NoClientDomainSigningKeyFoundException(this.domain);

  String toString() {
    return "No client domain SIGNING_KEY found in stellar.toml for domain: $domain";
  }
}

class MissingClientDomainException implements Exception {
  MissingClientDomainException();

  String toString() {
    return "The clientDomain is required if clientDomainSigningDelegate is provided";
  }
}

class MissingTransactionInChallengeResponseException implements Exception {
  MissingTransactionInChallengeResponseException();

  String toString() {
    return "Missing transaction in challenge response";
  }
}

class NoMemoForMuxedAccountsException implements Exception {
  NoMemoForMuxedAccountsException();

  String toString() {
    return "Memo cannot be used if account is a muxed account";
  }
}
