// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../key_pair.dart';
import '../../network.dart';
import '../../soroban/soroban_auth.dart';
import '../../soroban/soroban_server.dart';
import '../../util.dart';
import '../../xdr/xdr_contract.dart';
import '../../xdr/xdr_data_io.dart';
import '../../xdr/xdr_transaction.dart';
import '../../xdr/xdr_type.dart';
import '../0001/stellar_toml.dart';

// ============================================================================
// EXCEPTION CLASSES
// ============================================================================

/// Base exception for SEP-45 challenge validation errors.
class ContractChallengeValidationException implements Exception {
  final String message;
  ContractChallengeValidationException(this.message);

  @override
  String toString() => message;
}

/// Thrown when the contract address does not match WEB_AUTH_CONTRACT_ID.
class ContractChallengeValidationErrorInvalidContractAddress
    extends ContractChallengeValidationException {
  ContractChallengeValidationErrorInvalidContractAddress(String message)
      : super(message);
}

/// Thrown when the function name is not "web_auth_verify".
class ContractChallengeValidationErrorInvalidFunctionName
    extends ContractChallengeValidationException {
  ContractChallengeValidationErrorInvalidFunctionName(String message)
      : super(message);
}

/// Thrown when an authorization entry contains sub-invocations.
class ContractChallengeValidationErrorSubInvocationsFound
    extends ContractChallengeValidationException {
  ContractChallengeValidationErrorSubInvocationsFound(String message)
      : super(message);
}

/// Thrown when the home_domain argument does not match expected value.
class ContractChallengeValidationErrorInvalidHomeDomain
    extends ContractChallengeValidationException {
  ContractChallengeValidationErrorInvalidHomeDomain(String message)
      : super(message);
}

/// Thrown when the web_auth_domain argument does not match server domain.
class ContractChallengeValidationErrorInvalidWebAuthDomain
    extends ContractChallengeValidationException {
  ContractChallengeValidationErrorInvalidWebAuthDomain(String message)
      : super(message);
}

/// Thrown when the account argument does not match client account.
class ContractChallengeValidationErrorInvalidAccount
    extends ContractChallengeValidationException {
  ContractChallengeValidationErrorInvalidAccount(String message)
      : super(message);
}

/// Thrown when the nonce is inconsistent across authorization entries.
class ContractChallengeValidationErrorInvalidNonce
    extends ContractChallengeValidationException {
  ContractChallengeValidationErrorInvalidNonce(String message) : super(message);
}

/// Thrown when the server entry signature is invalid.
class ContractChallengeValidationErrorInvalidServerSignature
    extends ContractChallengeValidationException {
  ContractChallengeValidationErrorInvalidServerSignature(String message)
      : super(message);
}

/// Thrown when no authorization entry exists for the server account.
class ContractChallengeValidationErrorMissingServerEntry
    extends ContractChallengeValidationException {
  ContractChallengeValidationErrorMissingServerEntry(String message)
      : super(message);
}

/// Thrown when no authorization entry exists for the client account.
class ContractChallengeValidationErrorMissingClientEntry
    extends ContractChallengeValidationException {
  ContractChallengeValidationErrorMissingClientEntry(String message)
      : super(message);
}

/// Thrown when general arguments validation fails.
class ContractChallengeValidationErrorInvalidArgs
    extends ContractChallengeValidationException {
  ContractChallengeValidationErrorInvalidArgs(String message) : super(message);
}

/// Thrown when the network passphrase does not match expected value.
class ContractChallengeValidationErrorInvalidNetworkPassphrase
    extends ContractChallengeValidationException {
  ContractChallengeValidationErrorInvalidNetworkPassphrase(String message)
      : super(message);
}

/// Thrown when the challenge request fails.
class ContractChallengeRequestErrorResponse implements Exception {
  final String message;
  final int? statusCode;

  ContractChallengeRequestErrorResponse(this.message, {this.statusCode});

  @override
  String toString() => statusCode != null
      ? 'Challenge request error (HTTP $statusCode): $message'
      : 'Challenge request error: $message';
}

/// Thrown when the token request returns an error.
class SubmitContractChallengeErrorResponseException implements Exception {
  final String error;

  SubmitContractChallengeErrorResponseException(this.error);

  @override
  String toString() => 'Error requesting JWT token: $error';
}

/// Thrown when the token request times out (HTTP 504).
class SubmitContractChallengeTimeoutResponseException implements Exception {
  @override
  String toString() => 'Timeout (HTTP 504)';
}

/// Thrown when the token request returns an unknown response.
class SubmitContractChallengeUnknownResponseException implements Exception {
  final int code;
  final String body;

  SubmitContractChallengeUnknownResponseException(this.code, this.body);

  @override
  String toString() => 'Unknown response - code: $code - body: $body';
}

/// Thrown when WEB_AUTH_FOR_CONTRACTS_ENDPOINT is missing from stellar.toml.
class NoWebAuthForContractsEndpointFoundException implements Exception {
  final String domain;

  NoWebAuthForContractsEndpointFoundException(this.domain);

  @override
  String toString() =>
      'No WEB_AUTH_FOR_CONTRACTS_ENDPOINT found in stellar.toml for domain: $domain';
}

/// Thrown when WEB_AUTH_CONTRACT_ID is missing from stellar.toml.
class NoWebAuthContractIdFoundException implements Exception {
  final String domain;

  NoWebAuthContractIdFoundException(this.domain);

  @override
  String toString() =>
      'No WEB_AUTH_CONTRACT_ID found in stellar.toml for domain: $domain';
}

/// Thrown when clientDomainSigningCallback is provided without clientDomain.
class MissingClientDomainForContractAuthException implements Exception {
  @override
  String toString() =>
      'The clientDomain is required if clientDomainSigningCallback is provided';
}

// ============================================================================
// RESPONSE CLASSES
// ============================================================================

/// Response from the SEP-45 challenge endpoint.
class ContractChallengeResponse {
  /// Base64 XDR-encoded array of SorobanAuthorizationEntry
  final String authorizationEntries;

  /// Optional network passphrase for client verification
  final String? networkPassphrase;

  ContractChallengeResponse(this.authorizationEntries,
      {this.networkPassphrase});

  factory ContractChallengeResponse.fromJson(Map<String, dynamic> json) {
    // Handle both snake_case and camelCase field names
    final authEntries = json['authorization_entries'] ?? json['authorizationEntries'];
    if (authEntries == null) {
      throw ArgumentError('Missing required field: authorization_entries');
    }
    return ContractChallengeResponse(
      authEntries as String,
      networkPassphrase: (json['network_passphrase'] ?? json['networkPassphrase']) as String?,
    );
  }
}

/// Response from the SEP-45 token endpoint.
class SubmitContractChallengeResponse {
  final String? jwtToken;
  final String? error;

  SubmitContractChallengeResponse({this.jwtToken, this.error});

  factory SubmitContractChallengeResponse.fromJson(Map<String, dynamic> json) {
    return SubmitContractChallengeResponse(
      jwtToken: json['token'] as String?,
      error: json['error'] as String?,
    );
  }
}

// ============================================================================
// MAIN WEB AUTH FOR CONTRACTS CLASS
// ============================================================================

/// Implements SEP-45 Web Authentication for Contract Accounts protocol.
///
/// This class provides authentication for Soroban smart contract accounts (C... addresses).
/// For traditional Stellar accounts (G... and M... addresses), use SEP-10 WebAuth instead.
///
/// The returned JWT token can be used to authenticate requests to other SEP services
/// such as SEP-12 (KYC), SEP-38 (quotes), and SEP-24 (hosted deposits/withdrawals).
///
/// Example:
/// ```dart
/// // Create from domain's stellar.toml
/// final webAuth = await WebAuthForContracts.fromDomain(
///   'testanchor.stellar.org',
///   Network.TESTNET,
/// );
///
/// // Authenticate contract account
/// final contractId = 'CABC...';
/// final signerKeyPair = KeyPair.fromSecretSeed('S...');
/// final token = await webAuth.jwtToken(
///   contractId,
///   [signerKeyPair],
/// );
/// ```
class WebAuthForContracts {
  final String _authEndpoint;
  final String _webAuthContractId;
  final String _serverSigningKey;
  final String _serverHomeDomain;
  final Network _network;
  late http.Client httpClient;
  Map<String, String>? httpRequestHeaders;
  bool useFormUrlEncoded = true;
  String? sorobanRpcUrl;

  /// Creates a WebAuthForContracts instance with explicit configuration.
  ///
  /// Parameters:
  /// - [_authEndpoint] The authentication endpoint URL (WEB_AUTH_FOR_CONTRACTS_ENDPOINT from stellar.toml)
  /// - [_webAuthContractId] The web auth contract ID (WEB_AUTH_CONTRACT_ID from stellar.toml, C... address)
  /// - [_serverSigningKey] The server's signing key (SIGNING_KEY from stellar.toml, G... address)
  /// - [_serverHomeDomain] The server's home domain
  /// - [_network] The Stellar network (Network.PUBLIC or Network.TESTNET)
  /// - [httpClient] Optional custom HTTP client
  /// - [httpRequestHeaders] Optional custom HTTP headers
  /// - [sorobanRpcUrl] Optional Soroban RPC URL (defaults based on network)
  WebAuthForContracts(
    this._authEndpoint,
    this._webAuthContractId,
    this._serverSigningKey,
    this._serverHomeDomain,
    this._network, {
    http.Client? httpClient,
    this.httpRequestHeaders,
    this.sorobanRpcUrl,
  }) {
    if (!_webAuthContractId.startsWith('C')) {
      throw ArgumentError(
          "webAuthContractId must be a contract address starting with 'C'");
    }
    if (!_serverSigningKey.startsWith('G')) {
      throw ArgumentError(
          "serverSigningKey must be an account address starting with 'G'");
    }
    final uri = Uri.tryParse(_authEndpoint);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw ArgumentError("authEndpoint must be a valid URL");
    }
    if (_serverHomeDomain.trim().isEmpty) {
      throw ArgumentError("serverHomeDomain must not be empty");
    }

    this.httpClient = httpClient ?? http.Client();

    // Set Soroban RPC URL based on network if not provided
    if (sorobanRpcUrl == null) {
      this.sorobanRpcUrl = _network.networkPassphrase == Network.TESTNET.networkPassphrase
          ? 'https://soroban-testnet.stellar.org'
          : 'https://soroban.stellar.org';
    } else {
      this.sorobanRpcUrl = sorobanRpcUrl;
    }
  }

  /// Creates a WebAuthForContracts instance by loading configuration from stellar.toml.
  ///
  /// Parameters:
  /// - [domain] The domain from which to get the stellar information
  /// - [network] The network used (Network.PUBLIC or Network.TESTNET)
  /// - [httpClient] Optional HTTP client for requests
  /// - [httpRequestHeaders] Optional HTTP headers
  ///
  /// Returns: Configured WebAuthForContracts instance
  ///
  /// Throws:
  /// - [NoWebAuthForContractsEndpointFoundException] if WEB_AUTH_FOR_CONTRACTS_ENDPOINT is missing
  /// - [NoWebAuthContractIdFoundException] if WEB_AUTH_CONTRACT_ID is missing
  /// - [Exception] if auth server SIGNING_KEY is missing
  static Future<WebAuthForContracts> fromDomain(
    String domain,
    Network network, {
    http.Client? httpClient,
    Map<String, String>? httpRequestHeaders,
  }) async {
    final stellarToml = await StellarToml.fromDomain(
      domain,
      httpClient: httpClient,
      httpRequestHeaders: httpRequestHeaders,
    );

    final webAuthForContractsEndpoint =
        stellarToml.generalInformation.webAuthForContractsEndpoint;
    final webAuthContractId =
        stellarToml.generalInformation.webAuthContractId;
    final signingKey = stellarToml.generalInformation.signingKey;

    if (webAuthForContractsEndpoint == null) {
      throw NoWebAuthForContractsEndpointFoundException(domain);
    }
    if (webAuthContractId == null) {
      throw NoWebAuthContractIdFoundException(domain);
    }
    if (signingKey == null) {
      throw Exception('No auth server SIGNING_KEY found in stellar.toml');
    }

    return WebAuthForContracts(
      webAuthForContractsEndpoint,
      webAuthContractId,
      signingKey,
      domain,
      network,
      httpClient: httpClient,
      httpRequestHeaders: httpRequestHeaders,
    );
  }

  /// Executes the complete SEP-45 authentication flow.
  ///
  /// This method:
  /// 1. Requests a challenge from the server
  /// 2. Validates the authorization entries
  /// 3. Signs the client entry with provided signers
  /// 4. Submits the signed entries to obtain a JWT token
  ///
  /// Parameters:
  /// - [clientAccountId] Contract account (C...) to authenticate
  /// - [signers] Keypairs to sign the client authorization entry. For contracts
  ///   that implement __check_auth with signature verification, provide the keypairs
  ///   with sufficient weight to meet the contract's authentication requirements.
  ///   Can be empty for contracts whose __check_auth implementation does not require
  ///   signatures (per SEP-45).
  /// - [homeDomain] Optional home domain for the challenge request. If not provided,
  ///   defaults to the server home domain from stellar.toml.
  /// - [clientDomain] Optional client domain for verification
  /// - [clientDomainAccountKeyPair] Optional keypair for client domain signing
  /// - [clientDomainSigningCallback] Optional async callback for remote client domain signing.
  ///   The callback receives a single [SorobanAuthorizationEntry] (the client domain entry)
  ///   and must return it signed. This is useful for remote signing services.
  /// - [signatureExpirationLedger] Optional expiration ledger for signatures (for replay protection).
  ///   If null and signers are provided, automatically set to current ledger + 10
  ///   (approximately 50-60 seconds). If signers array is empty, this parameter is ignored.
  ///
  /// Returns: JWT token that can be used to authenticate requests to protected services
  Future<String> jwtToken(
    String clientAccountId,
    List<KeyPair> signers, {
    String? homeDomain,
    String? clientDomain,
    KeyPair? clientDomainAccountKeyPair,
    Future<SorobanAuthorizationEntry> Function(SorobanAuthorizationEntry)?
        clientDomainSigningCallback,
    int? signatureExpirationLedger,
  }) async {
    // Validate client account ID is a contract address
    if (!clientAccountId.startsWith('C')) {
      throw ArgumentError('Client account must be a contract address (C...)');
    }

    // Use server home domain as default if not provided
    final effectiveHomeDomain = homeDomain ?? _serverHomeDomain;

    // Get the challenge authorization entries from the web auth server
    final challengeResponse = await getChallenge(
      clientAccountId,
      homeDomain: effectiveHomeDomain,
      clientDomain: clientDomain,
    );

    // Validate network passphrase if provided in the challenge response
    if (challengeResponse.networkPassphrase != null) {
      final expectedNetworkPassphrase = _network.networkPassphrase;
      final responseNetworkPassphrase = challengeResponse.networkPassphrase;
      if (responseNetworkPassphrase != expectedNetworkPassphrase) {
        throw ContractChallengeValidationErrorInvalidNetworkPassphrase(
          "Network passphrase mismatch. Expected: '$expectedNetworkPassphrase', Got: '$responseNetworkPassphrase'",
        );
      }
    }

    final authEntries =
        decodeAuthorizationEntries(challengeResponse.authorizationEntries);

    // Determine client domain account ID if needed
    String? clientDomainAccountId;
    if (clientDomain != null) {
      if (clientDomainAccountKeyPair != null) {
        clientDomainAccountId = clientDomainAccountKeyPair.accountId;
      } else if (clientDomainSigningCallback != null) {
        final toml = await StellarToml.fromDomain(
          clientDomain,
          httpClient: httpClient,
          httpRequestHeaders: httpRequestHeaders,
        );
        clientDomainAccountId = toml.generalInformation.signingKey;
        if (clientDomainAccountId == null) {
          throw Exception(
              'Could not find signing key in stellar.toml for client domain');
        }
      } else {
        throw ArgumentError(
            'Client domain key pair or client domain signing callback is missing');
      }
    }

    // Validate the authorization entries
    validateChallenge(
      authEntries,
      clientAccountId,
      homeDomain: effectiveHomeDomain,
      clientDomainAccountId: clientDomainAccountId,
    );

    // Auto-fill signatureExpirationLedger if not provided and signers are present
    int? effectiveExpirationLedger = signatureExpirationLedger;
    if (signers.isNotEmpty && effectiveExpirationLedger == null) {
      final sorobanServer = SorobanServer(sorobanRpcUrl!);
      final latestLedgerResponse = await sorobanServer.getLatestLedger();
      if (latestLedgerResponse.sequence == null) {
        throw Exception('Failed to get current ledger from Soroban RPC');
      }
      effectiveExpirationLedger = latestLedgerResponse.sequence! + 10;
    }

    // Sign the authorization entries
    final signedEntries = await signAuthorizationEntries(
      authEntries,
      clientAccountId,
      signers,
      effectiveExpirationLedger,
      clientDomainAccountKeyPair,
      clientDomainAccountId,
      clientDomainSigningCallback,
    );

    // Request the JWT token by sending back the signed authorization entries
    return await sendSignedChallenge(signedEntries);
  }

  /// Requests a challenge from the authentication server.
  ///
  /// Parameters:
  /// - [clientAccountId] Contract account (C...) to authenticate
  /// - [homeDomain] Optional home domain for the request
  /// - [clientDomain] Optional client domain
  ///
  /// Returns: The challenge response
  Future<ContractChallengeResponse> getChallenge(
    String clientAccountId, {
    String? homeDomain,
    String? clientDomain,
  }) async {
    final effectiveHomeDomain = homeDomain ?? _serverHomeDomain;

    final uri = Uri.parse(_authEndpoint).replace(queryParameters: {
      'account': clientAccountId,
      'home_domain': effectiveHomeDomain,
      if (clientDomain != null) 'client_domain': clientDomain,
    });

    try {
      final response = await httpClient.get(
        uri,
        headers: httpRequestHeaders ?? {},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        return ContractChallengeResponse.fromJson(jsonData);
      } else {
        throw ContractChallengeRequestErrorResponse(
          response.body,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ContractChallengeRequestErrorResponse) {
        rethrow;
      }
      throw ContractChallengeRequestErrorResponse(e.toString());
    }
  }

  /// Validates the authorization entries from the challenge response.
  ///
  /// Validation steps:
  /// 1. Each entry has no sub-invocations
  /// 2. contract_address matches WEB_AUTH_CONTRACT_ID
  /// 3. function_name is "web_auth_verify"
  /// 4. Args validation (account, home_domain, web_auth_domain, nonce, etc.)
  /// 5. Server entry exists and has valid signature
  /// 6. Client entry exists
  ///
  /// Parameters:
  /// - [authEntries] Entries to validate
  /// - [clientAccountId] Expected client account
  /// - [homeDomain] Optional expected home domain
  /// - [clientDomainAccountId] Expected client domain account
  void validateChallenge(
    List<SorobanAuthorizationEntry> authEntries,
    String clientAccountId, {
    String? homeDomain,
    String? clientDomainAccountId,
  }) {
    if (authEntries.isEmpty) {
      throw ContractChallengeValidationException(
          'No authorization entries found');
    }

    // Use server home domain as default if not provided
    final effectiveHomeDomain = homeDomain ?? _serverHomeDomain;

    String? nonce;
    bool serverEntryFound = false;
    bool clientEntryFound = false;
    bool clientDomainEntryFound = false;

    // Extract web_auth_domain from auth endpoint URL (include port if present)
    final uri = Uri.parse(_authEndpoint);
    String webAuthDomain = uri.host;
    if (uri.hasPort && uri.port != 80 && uri.port != 443) {
      webAuthDomain += ':${uri.port}';
    }

    for (final entry in authEntries) {
      final rootInvocation = entry.rootInvocation;

      // Check 1: No sub-invocations
      if (rootInvocation.subInvocations.isNotEmpty) {
        throw ContractChallengeValidationErrorSubInvocationsFound(
          'Authorization entry contains sub-invocations',
        );
      }

      // Check 2: Function must be contract function
      final function = rootInvocation.function;
      if (function.contractFn == null) {
        throw ContractChallengeValidationException(
          'Authorization entry is not a contract function',
        );
      }

      // Check 3: Contract address matches WEB_AUTH_CONTRACT_ID
      final contractAddress = Address.fromXdr(function.contractFn!.contractAddress);
      if (contractAddress.type != Address.TYPE_CONTRACT) {
        throw ContractChallengeValidationErrorInvalidContractAddress(
          'Contract address is not a contract type',
        );
      }
      final contractIdHex = contractAddress.contractId;
      final expectedContractIdHex = StrKey.decodeContractIdHex(_webAuthContractId);
      if (contractIdHex != expectedContractIdHex) {
        throw ContractChallengeValidationErrorInvalidContractAddress(
          'Contract address does not match WEB_AUTH_CONTRACT_ID',
        );
      }

      // Check 4: Function name is "web_auth_verify"
      final functionName = function.contractFn!.functionName;
      if (functionName != 'web_auth_verify') {
        throw ContractChallengeValidationErrorInvalidFunctionName(
          'Function name is not "web_auth_verify": $functionName',
        );
      }

      // Check 5: Extract and validate args
      final args = _extractArgsFromEntry(entry);

      // Validate account
      if (args['account'] != clientAccountId) {
        throw ContractChallengeValidationErrorInvalidAccount(
          'Account argument does not match client account',
        );
      }

      // Validate home_domain
      if (args['home_domain'] != effectiveHomeDomain) {
        throw ContractChallengeValidationErrorInvalidHomeDomain(
          'Home domain argument does not match expected home domain',
        );
      }

      // Validate web_auth_domain
      if (args['web_auth_domain'] != webAuthDomain) {
        throw ContractChallengeValidationErrorInvalidWebAuthDomain(
          'Web auth domain argument does not match server domain',
        );
      }

      // Validate web_auth_domain_account
      if (args['web_auth_domain_account'] != _serverSigningKey) {
        throw ContractChallengeValidationErrorInvalidArgs(
          'Web auth domain account does not match server signing key',
        );
      }

      // Validate nonce consistency
      if (args['nonce'] == null) {
        throw ContractChallengeValidationErrorInvalidNonce(
            'Nonce argument is missing');
      }
      if (nonce == null) {
        nonce = args['nonce'];
      } else if (nonce != args['nonce']) {
        throw ContractChallengeValidationErrorInvalidNonce(
          'Nonce is not consistent across authorization entries',
        );
      }

      // Validate client domain if provided
      if (clientDomainAccountId != null) {
        if (args['client_domain_account'] != null &&
            args['client_domain_account'] != clientDomainAccountId) {
          throw ContractChallengeValidationErrorInvalidArgs(
            'Client domain account does not match expected value',
          );
        }
      }

      // Check which entry this is (server, client, or client domain)
      final credentials = entry.credentials;
      if (credentials.addressCredentials != null) {
        final credentialsAddress = credentials.addressCredentials!.address;
        final credentialsAddressStr = _addressToString(credentialsAddress);

        if (credentialsAddressStr == _serverSigningKey) {
          serverEntryFound = true;
          // Verify server signature
          if (!_verifyServerSignature(entry)) {
            throw ContractChallengeValidationErrorInvalidServerSignature(
              'Server authorization entry has invalid signature',
            );
          }
        } else if (credentialsAddressStr == clientAccountId) {
          clientEntryFound = true;
        } else if (clientDomainAccountId != null &&
            credentialsAddressStr == clientDomainAccountId) {
          clientDomainEntryFound = true;
        }
      }
    }

    // Check 6: Server entry must exist
    if (!serverEntryFound) {
      throw ContractChallengeValidationErrorMissingServerEntry(
        'No authorization entry found for server account',
      );
    }

    // Check 7: Client entry must exist
    if (!clientEntryFound) {
      throw ContractChallengeValidationErrorMissingClientEntry(
        'No authorization entry found for client account',
      );
    }

    // Check 8: Client domain entry must exist if client domain account is provided
    if (clientDomainAccountId != null && !clientDomainEntryFound) {
      throw ContractChallengeValidationErrorMissingClientEntry(
        'No authorization entry found for client domain account',
      );
    }
  }

  /// Signs the authorization entries for the client account.
  ///
  /// Parameters:
  /// - [authEntries] Entries to sign
  /// - [clientAccountId] Client account to sign for
  /// - [signers] Keypairs to sign with
  /// - [signatureExpirationLedger] Expiration ledger for signatures
  /// - [clientDomainKeyPair] Optional client domain keypair
  /// - [clientDomainAccountId] Optional client domain account ID (used with callback)
  /// - [clientDomainSigningCallback] Optional callback for remote signing (single entry)
  ///
  /// Returns: Signed entries
  Future<List<SorobanAuthorizationEntry>> signAuthorizationEntries(
    List<SorobanAuthorizationEntry> authEntries,
    String clientAccountId,
    List<KeyPair> signers,
    int? signatureExpirationLedger,
    KeyPair? clientDomainKeyPair,
    String? clientDomainAccountId,
    Future<SorobanAuthorizationEntry> Function(SorobanAuthorizationEntry)?
        clientDomainSigningCallback,
  ) async {
    final signedEntries = <SorobanAuthorizationEntry>[];

    for (final entry in authEntries) {
      final credentials = entry.credentials;
      if (credentials.addressCredentials != null) {
        final credentialsAddress = credentials.addressCredentials!.address;
        final credentialsAddressStr = _addressToString(credentialsAddress);

        // Sign client entry
        if (credentialsAddressStr == clientAccountId) {
          // Set signature expiration ledger if provided
          if (signatureExpirationLedger != null) {
            credentials.addressCredentials!.signatureExpirationLedger =
                signatureExpirationLedger;
          }

          // Sign with all provided signers
          for (final signer in signers) {
            entry.sign(signer, _network);
          }
          signedEntries.add(entry);
          continue;
        }

        // Sign client domain entry with local keypair
        if (clientDomainKeyPair != null &&
            credentialsAddressStr == clientDomainKeyPair.accountId) {
          if (signatureExpirationLedger != null) {
            credentials.addressCredentials!.signatureExpirationLedger =
                signatureExpirationLedger;
          }
          entry.sign(clientDomainKeyPair, _network);
          signedEntries.add(entry);
          continue;
        }

        // Sign client domain entry via callback (remote signing)
        if (clientDomainSigningCallback != null &&
            clientDomainAccountId != null &&
            credentialsAddressStr == clientDomainAccountId) {
          // Set signature expiration ledger before sending to callback
          if (signatureExpirationLedger != null) {
            credentials.addressCredentials!.signatureExpirationLedger =
                signatureExpirationLedger;
          }
          final signedEntry = await clientDomainSigningCallback(entry);
          signedEntries.add(signedEntry);
          continue;
        }
      }

      // Add entry as-is (e.g., server entry which is already signed)
      signedEntries.add(entry);
    }

    return signedEntries;
  }

  /// Submits signed authorization entries to obtain a JWT token.
  ///
  /// Parameters:
  /// - [signedEntries] Signed entries
  ///
  /// Returns: JWT token
  Future<String> sendSignedChallenge(
      List<SorobanAuthorizationEntry> signedEntries) async {
    final base64Xdr = _encodeAuthorizationEntries(signedEntries);

    Map<String, String> headers = {...(httpRequestHeaders ?? {})};
    Map<String, dynamic> body;

    if (useFormUrlEncoded) {
      headers['Content-Type'] = 'application/x-www-form-urlencoded';
      body = {'authorization_entries': base64Xdr};
    } else {
      headers['Content-Type'] = 'application/json';
      body = {'authorization_entries': base64Xdr};
    }

    final response = await httpClient.post(
      Uri.parse(_authEndpoint),
      headers: headers,
      body: useFormUrlEncoded
          ? body.entries.map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value as String)}').join('&')
          : json.encode(body),
    );

    final statusCode = response.statusCode;
    if (statusCode == 200 || statusCode == 400) {
      final jsonData = json.decode(response.body) as Map<String, dynamic>;
      final result = SubmitContractChallengeResponse.fromJson(jsonData);
      if (result.error != null) {
        throw SubmitContractChallengeErrorResponseException(result.error!);
      } else if (result.jwtToken != null) {
        return result.jwtToken!;
      } else {
        throw SubmitContractChallengeErrorResponseException(
            'An unknown error occurred');
      }
    } else if (statusCode == 504) {
      throw SubmitContractChallengeTimeoutResponseException();
    } else {
      throw SubmitContractChallengeUnknownResponseException(
        statusCode,
        response.body,
      );
    }
  }

  // ============================================================================
  // PRIVATE HELPER METHODS
  // ============================================================================

  /// Decodes authorization entries from base64 XDR.
  List<SorobanAuthorizationEntry> decodeAuthorizationEntries(
      String base64Xdr) {
    try {
      final xdr = base64Decode(base64Xdr);
      final xdrBuffer = XdrDataInputStream(xdr);

      // Decode as array of SorobanAuthorizationEntry
      final count = xdrBuffer.readInt();
      final entries = <SorobanAuthorizationEntry>[];
      for (int i = 0; i < count; i++) {
        entries.add(SorobanAuthorizationEntry.fromXdr(
            XdrSorobanAuthorizationEntry.decode(xdrBuffer)));
      }

      return entries;
    } catch (e) {
      throw ContractChallengeValidationException(
        'Failed to decode authorization entries: $e',
      );
    }
  }

  /// Encodes authorization entries to base64 XDR.
  String _encodeAuthorizationEntries(
      List<SorobanAuthorizationEntry> entries) {
    final xdrOutputStream = XdrDataOutputStream();

    // Write array length
    xdrOutputStream.writeInt(entries.length);

    // Write each entry
    for (final entry in entries) {
      XdrSorobanAuthorizationEntry.encode(xdrOutputStream, entry.toXdr());
    }

    return base64Encode(xdrOutputStream.bytes);
  }

  /// Extracts args map from authorization entry.
  Map<String, String> _extractArgsFromEntry(
      SorobanAuthorizationEntry entry) {
    try {
      final function = entry.rootInvocation.function;
      if (function.contractFn == null) {
        throw ContractChallengeValidationErrorInvalidArgs(
            'Not a contract function');
      }

      final argsArray = function.contractFn!.args;
      if (argsArray.isEmpty) {
        throw ContractChallengeValidationErrorInvalidArgs(
            'No arguments found');
      }

      // First arg should be a map
      final argsVal = argsArray[0];
      if (argsVal.discriminant != XdrSCValType.SCV_MAP || argsVal.map == null) {
        throw ContractChallengeValidationErrorInvalidArgs(
            'Arguments are not in map format');
      }

      final result = <String, String>{};
      for (final mapEntry in argsVal.map!) {
        // Key should be a symbol
        if (mapEntry.key.discriminant != XdrSCValType.SCV_SYMBOL ||
            mapEntry.key.sym == null) {
          continue;
        }
        final key = mapEntry.key.sym!;

        // Value should be a string
        if (mapEntry.val.discriminant != XdrSCValType.SCV_STRING ||
            mapEntry.val.str == null) {
          continue;
        }
        final value = mapEntry.val.str!;

        result[key] = value;
      }

      return result;
    } catch (e) {
      if (e is ContractChallengeValidationErrorInvalidArgs) {
        rethrow;
      }
      throw ContractChallengeValidationErrorInvalidArgs(
        'Failed to extract args: $e',
      );
    }
  }

  /// Verifies server signature on authorization entry.
  bool _verifyServerSignature(SorobanAuthorizationEntry entry) {
    try {
      final xdrCredentials = entry.credentials.toXdr();
      if (entry.credentials.addressCredentials == null ||
          xdrCredentials.type !=
              XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS ||
          xdrCredentials.address == null) {
        return false;
      }

      // Build authorization preimage
      final networkId = Util.hash(Uint8List.fromList(
          _network.networkPassphrase.codeUnits));
      final authPreimageXdr = XdrHashIDPreimageSorobanAuthorization(
        XdrHash(networkId),
        xdrCredentials.address!.nonce,
        xdrCredentials.address!.signatureExpirationLedger,
        entry.rootInvocation.toXdr(),
      );
      final rootInvocationPreimage = XdrHashIDPreimage(
        XdrEnvelopeType.ENVELOPE_TYPE_SOROBAN_AUTHORIZATION,
      );
      rootInvocationPreimage.sorobanAuthorization = authPreimageXdr;

      final xdrOutputStream = XdrDataOutputStream();
      XdrHashIDPreimage.encode(xdrOutputStream, rootInvocationPreimage);
      final payload = Util.hash(Uint8List.fromList(xdrOutputStream.bytes));

      // Get signature from credentials
      final signatureVal = entry.credentials.addressCredentials!.signature;
      if (signatureVal.discriminant != XdrSCValType.SCV_VEC ||
          signatureVal.vec == null ||
          signatureVal.vec!.isEmpty) {
        return false;
      }

      // Extract public key and signature from first signature entry
      final firstSig = signatureVal.vec![0];
      if (firstSig.discriminant != XdrSCValType.SCV_MAP ||
          firstSig.map == null) {
        return false;
      }

      Uint8List? publicKey;
      Uint8List? signature;
      for (final mapEntry in firstSig.map!) {
        if (mapEntry.key.discriminant == XdrSCValType.SCV_SYMBOL) {
          if (mapEntry.key.sym == 'public_key' &&
              mapEntry.val.discriminant == XdrSCValType.SCV_BYTES &&
              mapEntry.val.bytes != null) {
            publicKey = Uint8List.fromList(mapEntry.val.bytes!.dataValue);
          } else if (mapEntry.key.sym == 'signature' &&
              mapEntry.val.discriminant == XdrSCValType.SCV_BYTES &&
              mapEntry.val.bytes != null) {
            signature = Uint8List.fromList(mapEntry.val.bytes!.dataValue);
          }
        }
      }

      if (publicKey == null || signature == null) {
        return false;
      }

      // Verify that extracted public key matches expected server signing key
      final expectedPublicKey =
          KeyPair.fromAccountId(_serverSigningKey).publicKey;
      if (!_bytesEqual(publicKey, expectedPublicKey)) {
        return false;
      }

      // Verify signature
      final serverKeyPair = KeyPair.fromAccountId(_serverSigningKey);
      return serverKeyPair.verify(payload, signature);
    } catch (e) {
      return false;
    }
  }

  /// Compares two byte arrays for equality.
  bool _bytesEqual(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Converts an Address to its string representation.
  String _addressToString(Address address) {
    if (address.type == Address.TYPE_ACCOUNT) {
      return address.accountId!;
    } else if (address.type == Address.TYPE_CONTRACT) {
      return StrKey.encodeContractIdHex(address.contractId!);
    } else {
      throw Exception('Unsupported address type: ${address.type}');
    }
  }
}
