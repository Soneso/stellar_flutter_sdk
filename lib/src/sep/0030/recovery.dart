import 'package:http/http.dart' as http;
import 'package:stellar_flutter_sdk/src/util.dart';
import '../../responses/response.dart';
import 'dart:convert';

/// Implements SEP-0030 - Account Recovery: multi-party recovery of Stellar accounts.
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

  /// This endpoint registers an account.
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

  /// This endpoint updates the identities for the account.
  /// The identities should be entirely replaced with the identities provided in the request, and not merged. Either owner or other or both should be set. If one is currently set and the request does not include it, it is removed.
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

  /// This endpoint signs a transaction.
  /// See https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0030.md#post-accountsaddresssignsigning-address
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

  /// This endpoint returns the registered account’s details.
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

  /// This endpoint will delete the record for an account. This should be irrecoverable.
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

  /// This endpoint will return a list of accounts that the JWT allows access to.
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

class SEP30AccountResponse extends Response {
  String address;
  List<SEP30ResponseIdentity> identities;
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

class SEP30AccountsResponse extends Response {
  List<SEP30AccountResponse> accounts;

  SEP30AccountsResponse(this.accounts);

  factory SEP30AccountsResponse.fromJson(Map<String, dynamic> json) =>
      SEP30AccountsResponse(List<SEP30AccountResponse>.from(
          json['accounts'].map((e) => SEP30AccountResponse.fromJson(e))));
}

class SEP30ResponseSigner {
  String key;

  SEP30ResponseSigner(this.key);

  factory SEP30ResponseSigner.fromJson(Map<String, dynamic> json) =>
      SEP30ResponseSigner(json['key']);
}

class SEP30ResponseIdentity {
  String role;
  bool? authenticated;

  SEP30ResponseIdentity(this.role, {this.authenticated});

  factory SEP30ResponseIdentity.fromJson(Map<String, dynamic> json) =>
      SEP30ResponseIdentity(json['role'], authenticated: json['authenticated']);
}

class SEP30SignatureResponse extends Response {
  String signature;
  String networkPassphrase;

  SEP30SignatureResponse(this.signature, this.networkPassphrase);

  factory SEP30SignatureResponse.fromJson(Map<String, dynamic> json) =>
      SEP30SignatureResponse(json['signature'], json['network_passphrase']);
}

class SEP30ResponseException implements Exception {
  String error;

  SEP30ResponseException(this.error);

  String toString() {
    return "SEP30 response - error:$error";
  }
}

class SEP30BadRequestResponseException extends SEP30ResponseException {
  SEP30BadRequestResponseException(String error) : super(error);
}

class SEP30UnauthorizedResponseException extends SEP30ResponseException {
  SEP30UnauthorizedResponseException(String error) : super(error);
}

class SEP30NotFoundResponseException extends SEP30ResponseException {
  SEP30NotFoundResponseException(String error) : super(error);
}

class SEP30ConflictResponseException extends SEP30ResponseException {
  SEP30ConflictResponseException(String error) : super(error);
}

class SEP30UnknownResponseException implements Exception {
  int code;
  String body;

  SEP30UnknownResponseException(this.code, this.body);

  String toString() {
    return "Unknown response - code: $code - body:$body";
  }
}
