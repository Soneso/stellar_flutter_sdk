import 'package:http/http.dart' as http;
import 'package:stellar_flutter_sdk/src/util.dart';
import '../../responses/response.dart';
import 'dart:convert';

/// Implements SEP-0030 v0.8.1 - Account Recovery: multi-party recovery of Stellar accounts.
///
/// Provides a secure mechanism for account recovery using multiple identity providers.
/// This service allows users to recover access to their Stellar accounts through a
/// multi-party authentication process, eliminating single points of failure.
///
/// Recovery workflow:
/// 1. Register account with multiple identity providers (owners/signers)
/// 2. User authenticates with identity providers to prove ownership
/// 3. Recovery service verifies authentication from sufficient parties
/// 4. Service provides signatures for recovery transaction
/// 5. User rebuilds account access with recovered keys
///
/// Identity roles:
/// - Owner: Can sign transactions and modify account identities
/// - Other: Can only sign transactions (additional signers)
///
/// Authentication methods:
/// - Email verification
/// - Phone number verification
/// - Hardware security keys
/// - Biometric authentication
/// - Custom authentication methods
///
/// Protocol specification:
/// - [SEP-0030](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0030.md)
///
/// Example:
/// ```dart
/// // Initialize service
/// SEP30RecoveryService recovery = SEP30RecoveryService(
///   "https://recovery.example.com"
/// );
///
/// // Register account with identities
/// SEP30AuthMethod email = SEP30AuthMethod("email", "user@example.com");
/// SEP30AuthMethod phone = SEP30AuthMethod("phone_number", "+1234567890");
/// SEP30RequestIdentity owner = SEP30RequestIdentity("owner", [email, phone]);
///
/// SEP30Request request = SEP30Request([owner]);
/// SEP30AccountResponse response = await recovery.registerAccount(
///   accountId,
///   request,
///   jwtToken
/// );
///
/// // Later: sign transaction for recovery
/// SEP30SignatureResponse signature = await recovery.signTransaction(
///   accountId,
///   signingAddress,
///   transactionXdr,
///   jwtToken
/// );
/// ```
///
/// Security considerations:
/// - Use multiple independent identity providers
/// - Require authentication from multiple parties
/// - Store recovery configuration securely
/// - Regularly test recovery process
/// - Use SEP-0010 for JWT authentication
///
/// See also:
/// - [SEP-0010](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0010.md) for authentication
/// - [Account] for Stellar account management
class SEP30RecoveryService {
  String _serviceAddress;
  late http.Client httpClient;
  Map<String, String>? httpRequestHeaders;

  SEP30RecoveryService(this._serviceAddress,
      {http.Client? httpClient, this.httpRequestHeaders}) {
    this.httpClient = httpClient ?? http.Client();
  }

  /// Registers an account with the recovery service.
  ///
  /// Creates a new account registration with specified identity providers and
  /// authentication methods for future account recovery.
  ///
  /// Parameters:
  /// - [address]: Stellar account address to register
  /// - [request]: Identity configuration with authentication methods
  /// - [jwt]: Authentication token from SEP-10
  ///
  /// Returns account response with registered identities and signing addresses.
  ///
  /// Throws:
  /// - [SEP30BadRequestResponseException] on invalid request (HTTP 400)
  /// - [SEP30UnauthorizedResponseException] on authentication failure (HTTP 401)
  /// - [SEP30NotFoundResponseException] if endpoint not found (HTTP 404)
  /// - [SEP30ConflictResponseException] if account already exists (HTTP 409)
  /// - [SEP30UnknownResponseException] on other HTTP errors
  ///
  /// See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0030.md#post-accountsaddress
  Future<SEP30AccountResponse> registerAccount(
      String address, SEP30Request request, String jwt) async {
    Uri requestURI =
        Util.appendEndpointToUrl(_serviceAddress, 'accounts/$address');
    Map<String, String> headers = {...(this.httpRequestHeaders ?? {})};
    headers["Authorization"] = "Bearer " + jwt;
    headers.putIfAbsent("Content-Type", () => "application/json");

    SEP30AccountResponse result = await httpClient
        .post(requestURI, body: json.encode(request.toJson()), headers: headers)
        .then((response) {
      switch (response.statusCode) {
        case 200:
          return SEP30AccountResponse.fromJson(json.decode(response.body));
        case 400:
          throw SEP30BadRequestResponseException(
              errorFromResponseBody(response.body));
        case 401:
          throw SEP30UnauthorizedResponseException(
              errorFromResponseBody(response.body));
        case 404:
          throw SEP30NotFoundResponseException(
              errorFromResponseBody(response.body));
        case 409:
          throw SEP30ConflictResponseException(
              errorFromResponseBody(response.body));
        default:
          throw new SEP30UnknownResponseException(
              response.statusCode, response.body);
      }
    }).catchError((onError) {
      throw onError;
    });

    return result;
  }

  /// Updates account recovery identities.
  ///
  /// Replaces all existing identities with those provided in the request.
  /// This is not a merge operation - identities not included are removed.
  ///
  /// Parameters:
  /// - [address]: Stellar account address to update
  /// - [request]: New identity configuration (replaces existing)
  /// - [jwt]: Authentication token from SEP-10
  ///
  /// Returns updated account response with new identities and signing addresses.
  ///
  /// Throws:
  /// - [SEP30BadRequestResponseException] on invalid request (HTTP 400)
  /// - [SEP30UnauthorizedResponseException] on authentication failure (HTTP 401)
  /// - [SEP30NotFoundResponseException] if account not found (HTTP 404)
  /// - [SEP30ConflictResponseException] on update conflict (HTTP 409)
  /// - [SEP30UnknownResponseException] on other HTTP errors
  ///
  /// See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0030.md#put-accountsaddress
  Future<SEP30AccountResponse> updateIdentitiesForAccount(
      String address, SEP30Request request, String jwt) async {
    Uri requestURI =
        Util.appendEndpointToUrl(_serviceAddress, 'accounts/$address');
    Map<String, String> headers = {...(this.httpRequestHeaders ?? {})};
    headers["Authorization"] = "Bearer " + jwt;
    headers.putIfAbsent("Content-Type", () => "application/json");

    SEP30AccountResponse result = await httpClient
        .put(requestURI, body: json.encode(request.toJson()), headers: headers)
        .then((response) {
      switch (response.statusCode) {
        case 200:
          return SEP30AccountResponse.fromJson(json.decode(response.body));
        case 400:
          throw SEP30BadRequestResponseException(
              errorFromResponseBody(response.body));
        case 401:
          throw SEP30UnauthorizedResponseException(
              errorFromResponseBody(response.body));
        case 404:
          throw SEP30NotFoundResponseException(
              errorFromResponseBody(response.body));
        case 409:
          throw SEP30ConflictResponseException(
              errorFromResponseBody(response.body));
        default:
          throw new SEP30UnknownResponseException(
              response.statusCode, response.body);
      }
    }).catchError((onError) {
      throw onError;
    });

    return result;
  }

  /// Signs a transaction using a recovery signer.
  ///
  /// Requests the recovery service to sign a transaction with one of the
  /// account's registered signing addresses. Used during account recovery
  /// to authorize recovery transactions.
  ///
  /// The signing address must correspond to one of the signers returned when
  /// registering or querying the account.
  ///
  /// Parameters:
  /// - [address]: Stellar account address
  /// - [signingAddress]: Signing address from account's registered signers
  /// - [transaction]: Base64-encoded transaction XDR to sign
  /// - [jwt]: Authentication token from SEP-10
  ///
  /// Returns signature response with transaction signature and network passphrase.
  ///
  /// Throws:
  /// - [SEP30BadRequestResponseException] on invalid request (HTTP 400)
  /// - [SEP30UnauthorizedResponseException] on authentication failure (HTTP 401)
  /// - [SEP30NotFoundResponseException] if account or signer not found (HTTP 404)
  /// - [SEP30ConflictResponseException] on signing conflict (HTTP 409)
  /// - [SEP30UnknownResponseException] on other HTTP errors
  ///
  /// See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0030.md#post-accountsaddresssignsigning-address
  Future<SEP30SignatureResponse> signTransaction(String address,
      String signingAddress, String transaction, String jwt) async {
    Uri requestURI = Util.appendEndpointToUrl(
        _serviceAddress, 'accounts/$address/sign/$signingAddress');
    Map<String, String> headers = {...(this.httpRequestHeaders ?? {})};
    headers["Authorization"] = "Bearer " + jwt;
    headers.putIfAbsent("Content-Type", () => "application/json");

    SEP30SignatureResponse result = await httpClient
        .post(requestURI,
            body: json.encode({"transaction": transaction}), headers: headers)
        .then((response) {
      switch (response.statusCode) {
        case 200:
          return SEP30SignatureResponse.fromJson(json.decode(response.body));
        case 400:
          throw SEP30BadRequestResponseException(
              errorFromResponseBody(response.body));
        case 401:
          throw SEP30UnauthorizedResponseException(
              errorFromResponseBody(response.body));
        case 404:
          throw SEP30NotFoundResponseException(
              errorFromResponseBody(response.body));
        case 409:
          throw SEP30ConflictResponseException(
              errorFromResponseBody(response.body));
        default:
          throw new SEP30UnknownResponseException(
              response.statusCode, response.body);
      }
    }).catchError((onError) {
      throw onError;
    });

    return result;
  }

  /// Retrieves registered account details.
  ///
  /// Returns the account's recovery configuration including identities,
  /// authentication status, and signing addresses.
  ///
  /// Parameters:
  /// - [address]: Stellar account address to query
  /// - [jwt]: Authentication token from SEP-10
  ///
  /// Returns account response with identities and signers.
  ///
  /// Throws:
  /// - [SEP30BadRequestResponseException] on invalid request (HTTP 400)
  /// - [SEP30UnauthorizedResponseException] on authentication failure (HTTP 401)
  /// - [SEP30NotFoundResponseException] if account not found (HTTP 404)
  /// - [SEP30ConflictResponseException] on retrieval conflict (HTTP 409)
  /// - [SEP30UnknownResponseException] on other HTTP errors
  ///
  /// See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0030.md#get-accountsaddress
  Future<SEP30AccountResponse> accountDetails(
      String address, String jwt) async {
    Uri requestURI =
        Util.appendEndpointToUrl(_serviceAddress, 'accounts/$address');
    Map<String, String> headers = {...(this.httpRequestHeaders ?? {})};
    headers["Authorization"] = "Bearer " + jwt;
    headers.putIfAbsent("Content-Type", () => "application/json");

    SEP30AccountResponse result =
        await httpClient.get(requestURI, headers: headers).then((response) {
      switch (response.statusCode) {
        case 200:
          return SEP30AccountResponse.fromJson(json.decode(response.body));
        case 400:
          throw SEP30BadRequestResponseException(
              errorFromResponseBody(response.body));
        case 401:
          throw SEP30UnauthorizedResponseException(
              errorFromResponseBody(response.body));
        case 404:
          throw SEP30NotFoundResponseException(
              errorFromResponseBody(response.body));
        case 409:
          throw SEP30ConflictResponseException(
              errorFromResponseBody(response.body));
        default:
          throw new SEP30UnknownResponseException(
              response.statusCode, response.body);
      }
    }).catchError((onError) {
      throw onError;
    });

    return result;
  }

  /// Deletes account recovery registration.
  ///
  /// Permanently removes the account's recovery configuration. This operation
  /// is irrecoverable and should be used with caution.
  ///
  /// Parameters:
  /// - [address]: Stellar account address to delete
  /// - [jwt]: Authentication token from SEP-10
  ///
  /// Returns final account response before deletion.
  ///
  /// Throws:
  /// - [SEP30BadRequestResponseException] on invalid request (HTTP 400)
  /// - [SEP30UnauthorizedResponseException] on authentication failure (HTTP 401)
  /// - [SEP30NotFoundResponseException] if account not found (HTTP 404)
  /// - [SEP30ConflictResponseException] on deletion conflict (HTTP 409)
  /// - [SEP30UnknownResponseException] on other HTTP errors
  ///
  /// See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0030.md#delete-accountsaddress
  Future<SEP30AccountResponse> deleteAccount(String address, String jwt) async {
    Uri requestURI =
        Util.appendEndpointToUrl(_serviceAddress, 'accounts/$address');
    Map<String, String> headers = {...(this.httpRequestHeaders ?? {})};
    headers["Authorization"] = "Bearer " + jwt;
    headers.putIfAbsent("Content-Type", () => "application/json");

    SEP30AccountResponse result =
        await httpClient.delete(requestURI, headers: headers).then((response) {
      switch (response.statusCode) {
        case 200:
          return SEP30AccountResponse.fromJson(json.decode(response.body));
        case 400:
          throw SEP30BadRequestResponseException(
              errorFromResponseBody(response.body));
        case 401:
          throw SEP30UnauthorizedResponseException(
              errorFromResponseBody(response.body));
        case 404:
          throw SEP30NotFoundResponseException(
              errorFromResponseBody(response.body));
        case 409:
          throw SEP30ConflictResponseException(
              errorFromResponseBody(response.body));
        default:
          throw new SEP30UnknownResponseException(
              response.statusCode, response.body);
      }
    }).catchError((onError) {
      throw onError;
    });

    return result;
  }

  /// Lists all accounts accessible with the JWT token.
  ///
  /// Returns accounts that the authenticated user has permission to access.
  /// Supports pagination for large account lists.
  ///
  /// Parameters:
  /// - `jwt`: Authentication token from SEP-10
  /// - `after`: Optional cursor for pagination (account address to start after)
  ///
  /// Returns paginated list of account responses.
  ///
  /// Throws:
  /// - [SEP30BadRequestResponseException] on invalid request (HTTP 400)
  /// - [SEP30UnauthorizedResponseException] on authentication failure (HTTP 401)
  /// - [SEP30NotFoundResponseException] if endpoint not found (HTTP 404)
  /// - [SEP30ConflictResponseException] on retrieval conflict (HTTP 409)
  /// - [SEP30UnknownResponseException] on other HTTP errors
  ///
  /// Example:
  /// ```dart
  /// // Get first page
  /// SEP30AccountsResponse page1 = await recovery.accounts(jwt);
  ///
  /// // Get next page using last account address as cursor
  /// String lastAddress = page1.accounts.last.address;
  /// SEP30AccountsResponse page2 = await recovery.accounts(jwt, after: lastAddress);
  /// ```
  ///
  /// See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0030.md#get-accounts
  Future<SEP30AccountsResponse> accounts(String jwt, {String? after}) async {
    Uri requestURI = after == null
        ? Util.appendEndpointToUrl(_serviceAddress, 'accounts')
        : Util.appendEndpointToUrl(_serviceAddress, 'accounts')
            .replace(queryParameters: {'after': after});

    Map<String, String> headers = {...(this.httpRequestHeaders ?? {})};
    headers["Authorization"] = "Bearer " + jwt;
    headers.putIfAbsent("Content-Type", () => "application/json");

    SEP30AccountsResponse result =
        await httpClient.get(requestURI, headers: headers).then((response) {
      switch (response.statusCode) {
        case 200:
          return SEP30AccountsResponse.fromJson(json.decode(response.body));
        case 400:
          throw SEP30BadRequestResponseException(
              errorFromResponseBody(response.body));
        case 401:
          throw SEP30UnauthorizedResponseException(
              errorFromResponseBody(response.body));
        case 404:
          throw SEP30NotFoundResponseException(
              errorFromResponseBody(response.body));
        case 409:
          throw SEP30ConflictResponseException(
              errorFromResponseBody(response.body));
        default:
          throw new SEP30UnknownResponseException(
              response.statusCode, response.body);
      }
    }).catchError((onError) {
      throw onError;
    });

    return result;
  }

  String errorFromResponseBody(String body) {
    Map<String, dynamic>? res = json.decode(body);
    if (res != null && res["error"] != null) {
      return res["error"];
    }
    return "none";
  }
}

/// Request for registering or updating account recovery identities.
///
/// Contains a list of identities with their authentication methods that will
/// be used for account recovery.
///
/// Example:
/// ```dart
/// SEP30AuthMethod email = SEP30AuthMethod("email", "user@example.com");
/// SEP30RequestIdentity owner = SEP30RequestIdentity("owner", [email]);
/// SEP30Request request = SEP30Request([owner]);
/// ```
class SEP30Request {
  /// List of identities for account recovery.
  List<SEP30RequestIdentity> identities;

  SEP30Request(this.identities);

  Map<String, dynamic> toJson() {
    List<Map<String, dynamic>> valArr =
        List<Map<String, dynamic>>.empty(growable: true);
    for (SEP30RequestIdentity identity in identities) {
      valArr.add(identity.toJson());
    }
    return {
      'identities': valArr,
    };
  }
}

/// Identity configuration for account recovery.
///
/// Defines a recovery identity with its role and authentication methods.
///
/// Roles:
/// - "owner": Can sign transactions and modify account identities
/// - "other": Can only sign transactions (additional signers)
///
/// Example:
/// ```dart
/// SEP30AuthMethod email = SEP30AuthMethod("email", "user@example.com");
/// SEP30AuthMethod phone = SEP30AuthMethod("phone_number", "+1234567890");
/// SEP30RequestIdentity owner = SEP30RequestIdentity("owner", [email, phone]);
/// ```
class SEP30RequestIdentity {
  /// Role of the identity ("owner" or "other").
  String role;

  /// List of authentication methods for this identity.
  List<SEP30AuthMethod> authMethods;

  SEP30RequestIdentity(this.role, this.authMethods);

  Map<String, dynamic> toJson() {
    List<Map<String, dynamic>> valArr =
        List<Map<String, dynamic>>.empty(growable: true);
    for (SEP30AuthMethod authMethod in authMethods) {
      valArr.add(authMethod.toJson());
    }
    return {
      'role': role,
      'auth_methods': valArr,
    };
  }
}

/// Authentication method for identity verification.
///
/// Specifies how a recovery identity can be authenticated.
///
/// Common types:
/// - "email": Email address
/// - "phone_number": Phone number in E.164 format
/// - "stellar_address": Stellar account address
/// - "email_address": Deprecated, use "email"
///
/// Example:
/// ```dart
/// SEP30AuthMethod email = SEP30AuthMethod("email", "user@example.com");
/// SEP30AuthMethod phone = SEP30AuthMethod("phone_number", "+1234567890");
/// SEP30AuthMethod stellar = SEP30AuthMethod("stellar_address", "user*example.com");
/// ```
class SEP30AuthMethod {
  /// Type of authentication method.
  String type;

  /// Value for the authentication method (email, phone number, etc.).
  String value;

  SEP30AuthMethod(this.type, this.value);

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'value': value,
    };
  }
}

/// Response containing account recovery information.
///
/// Returned when registering, updating, querying, or deleting an account.
/// Contains the account's recovery configuration including identities and
/// the signing addresses that can authorize recovery transactions.
///
/// The [signers] correspond to the registered [identities] and represent
/// the Stellar addresses that the recovery service controls for signing
/// recovery transactions on behalf of authenticated identities.
///
/// Example:
/// ```dart
/// SEP30AccountResponse response = await recovery.accountDetails(
///   accountId,
///   jwtToken
/// );
/// print('Account: ${response.address}');
/// print('Identities: ${response.identities.length}');
/// print('Signers: ${response.signers.length}');
/// ```
class SEP30AccountResponse extends Response {
  /// Stellar account address.
  String address;

  /// Registered recovery identities with authentication status.
  List<SEP30ResponseIdentity> identities;

  /// Signing addresses controlled by the recovery service for this account.
  List<SEP30ResponseSigner> signers;

  SEP30AccountResponse(this.address, this.identities, this.signers);

  factory SEP30AccountResponse.fromJson(Map<String, dynamic> json) =>
      SEP30AccountResponse(
          json['address'],
          List<SEP30ResponseIdentity>.from(
              json['identities'].map((e) => SEP30ResponseIdentity.fromJson(e))),
          List<SEP30ResponseSigner>.from(
              json['signers'].map((e) => SEP30ResponseSigner.fromJson(e))));
}

/// Response containing a list of accounts.
///
/// Returned by the accounts list endpoint. Contains all accounts that
/// the authenticated user has permission to access.
///
/// Supports pagination via the `after` parameter in the request.
///
/// Example:
/// ```dart
/// SEP30AccountsResponse response = await recovery.accounts(jwtToken);
/// for (SEP30AccountResponse account in response.accounts) {
///   print('Account: ${account.address}');
/// }
/// ```
class SEP30AccountsResponse extends Response {
  /// List of accessible accounts with their recovery configurations.
  List<SEP30AccountResponse> accounts;

  SEP30AccountsResponse(this.accounts);

  factory SEP30AccountsResponse.fromJson(Map<String, dynamic> json) =>
      SEP30AccountsResponse(List<SEP30AccountResponse>.from(
          json['accounts'].map((e) => SEP30AccountResponse.fromJson(e))));
}

/// Signer information for recovery transactions.
///
/// Represents a signing address that the recovery service controls and can
/// use to sign recovery transactions after successful identity authentication.
///
/// Each signer corresponds to one or more registered identities. When identities
/// successfully authenticate, the recovery service can use these signers to
/// authorize transactions for account recovery.
///
/// Example:
/// ```dart
/// for (SEP30ResponseSigner signer in response.signers) {
///   print('Signer address: ${signer.key}');
/// }
/// ```
class SEP30ResponseSigner {
  /// Stellar public key (address) of the recovery signer.
  String key;

  SEP30ResponseSigner(this.key);

  factory SEP30ResponseSigner.fromJson(Map<String, dynamic> json) =>
      SEP30ResponseSigner(json['key']);
}

/// Identity information in recovery response.
///
/// Contains the role and authentication status of a registered recovery identity.
///
/// Roles:
/// - "owner": Can sign transactions and modify account recovery configuration
/// - "other": Can only sign transactions (additional signers)
///
/// The [authenticated] field indicates whether the identity has successfully
/// completed authentication with the recovery service. This is typically null
/// during registration and set during authentication flows.
///
/// Example:
/// ```dart
/// for (SEP30ResponseIdentity identity in response.identities) {
///   print('Role: ${identity.role}');
///   if (identity.authenticated != null) {
///     print('Authenticated: ${identity.authenticated}');
///   }
/// }
/// ```
class SEP30ResponseIdentity {
  /// Role of the identity ("owner" or "other").
  String role;

  /// Whether the identity has been authenticated. Null if not yet authenticated.
  bool? authenticated;

  SEP30ResponseIdentity(this.role, {this.authenticated});

  factory SEP30ResponseIdentity.fromJson(Map<String, dynamic> json) =>
      SEP30ResponseIdentity(json['role'], authenticated: json['authenticated']);
}

/// Response containing a transaction signature.
///
/// Returned when requesting the recovery service to sign a transaction.
/// Contains the signature and network passphrase for verification.
///
/// The signature can be added to a transaction to authorize it with one of
/// the account's recovery signers. The network passphrase confirms which
/// Stellar network the signature is valid for.
///
/// Example:
/// ```dart
/// SEP30SignatureResponse response = await recovery.signTransaction(
///   accountId,
///   signingAddress,
///   transactionXdr,
///   jwtToken
/// );
/// print('Signature: ${response.signature}');
/// print('Network: ${response.networkPassphrase}');
/// ```
class SEP30SignatureResponse extends Response {
  /// Base64-encoded signature for the transaction.
  String signature;

  /// Network passphrase the signature is valid for.
  String networkPassphrase;

  SEP30SignatureResponse(this.signature, this.networkPassphrase);

  factory SEP30SignatureResponse.fromJson(Map<String, dynamic> json) =>
      SEP30SignatureResponse(json['signature'], json['network_passphrase']);
}

/// Base exception for SEP-30 API errors.
///
/// All SEP-30 exceptions extend this class and contain an error message
/// from the recovery service.
///
/// Specific exception types:
/// - [SEP30BadRequestResponseException]: Invalid request (HTTP 400)
/// - [SEP30UnauthorizedResponseException]: Authentication failure (HTTP 401)
/// - [SEP30NotFoundResponseException]: Resource not found (HTTP 404)
/// - [SEP30ConflictResponseException]: Request conflict (HTTP 409)
/// - [SEP30UnknownResponseException]: Other HTTP errors
class SEP30ResponseException implements Exception {
  /// Error message from the recovery service.
  String error;

  SEP30ResponseException(this.error);

  String toString() {
    return "SEP30 response - error:$error";
  }
}

/// Exception thrown for invalid requests (HTTP 400).
///
/// Indicates that the request was malformed or contained invalid parameters.
/// Common causes:
/// - Invalid account address format
/// - Missing required fields
/// - Invalid authentication method type
/// - Malformed transaction XDR
class SEP30BadRequestResponseException extends SEP30ResponseException {
  SEP30BadRequestResponseException(String error) : super(error);
}

/// Exception thrown for authentication failures (HTTP 401).
///
/// Indicates that the JWT token is invalid, expired, or missing required
/// permissions for the requested operation.
///
/// Resolution:
/// - Obtain a new JWT token using SEP-10 authentication
/// - Verify token has required permissions for the operation
class SEP30UnauthorizedResponseException extends SEP30ResponseException {
  SEP30UnauthorizedResponseException(String error) : super(error);
}

/// Exception thrown when a resource is not found (HTTP 404).
///
/// Indicates that the requested account, signer, or endpoint does not exist.
/// Common causes:
/// - Account not registered with recovery service
/// - Invalid signing address
/// - Endpoint not supported by server
class SEP30NotFoundResponseException extends SEP30ResponseException {
  SEP30NotFoundResponseException(String error) : super(error);
}

/// Exception thrown for request conflicts (HTTP 409).
///
/// Indicates a conflict with the current state of the resource.
/// Common causes:
/// - Attempting to register an account that already exists
/// - Concurrent modifications to account configuration
/// - Attempting to sign with unverified identity
class SEP30ConflictResponseException extends SEP30ResponseException {
  SEP30ConflictResponseException(String error) : super(error);
}

/// Exception thrown for unknown HTTP errors.
///
/// Represents HTTP errors not covered by other exception types.
/// Contains the raw HTTP status code and response body for debugging.
///
/// Example:
/// ```dart
/// try {
///   await recovery.registerAccount(address, request, jwt);
/// } on SEP30UnknownResponseException catch (e) {
///   print('HTTP ${e.code}: ${e.body}');
/// }
/// ```
class SEP30UnknownResponseException implements Exception {
  /// HTTP status code.
  int code;

  /// Raw response body.
  String body;

  SEP30UnknownResponseException(this.code, this.body);

  String toString() {
    return "Unknown response - code: $code - body:$body";
  }
}
