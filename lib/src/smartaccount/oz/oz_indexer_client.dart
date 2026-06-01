// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:dio/dio.dart' as dio;
import 'package:meta/meta.dart';

import '../../stellar_sdk.dart';
import '../../util.dart';
import '../core/smart_account_errors.dart';
import 'oz_constants.dart';
import 'oz_http_internal.dart';
import 'oz_validation.dart';

const DeepCollectionEquality _deepEquality = DeepCollectionEquality();

/// Response from looking up a credential ID in the indexer.
///
/// Contains the credential ID, all contracts where this credential is
/// registered as a signer, and the total count of contracts.
class OZCredentialLookupResponse {
  /// Constructs a credential-lookup response.
  const OZCredentialLookupResponse({
    required this.credentialId,
    required this.contracts,
    required this.count,
  });

  /// The credential ID looked up.
  ///
  /// The indexer returns this top-level field as camelCase
  /// (`credentialId`) even though the inner contract entries use
  /// snake_case column names.
  final String credentialId;

  /// All contracts where this credential is registered as a signer.
  final List<OZIndexedContractSummary> contracts;

  /// The total number of matching contracts.
  final int count;

  factory OZCredentialLookupResponse.fromJson(Map<String, dynamic> json) {
    final rawContracts = json['contracts'] as List<dynamic>? ?? const [];
    return OZCredentialLookupResponse(
      credentialId: json['credentialId'] as String,
      contracts: rawContracts
          .map((e) =>
              OZIndexedContractSummary.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      count: _asInt(json['count'], 'count'),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'credentialId': credentialId,
        'contracts': contracts.map((c) => c.toJson()).toList(growable: false),
        'count': count,
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OZCredentialLookupResponse) return false;
    return credentialId == other.credentialId &&
        count == other.count &&
        _deepEquality.equals(contracts, other.contracts);
  }

  @override
  int get hashCode =>
      Object.hash(credentialId, count, _deepEquality.hash(contracts));
}

/// Response from looking up a signer address in the indexer.
///
/// Contains the signer address, all contracts where this address is
/// registered as a signer, and the total count of contracts.
class OZAddressLookupResponse {
  /// Constructs an address-lookup response.
  const OZAddressLookupResponse({
    required this.signerAddress,
    required this.contracts,
    required this.count,
  });

  /// The signer address looked up.
  ///
  /// The indexer returns this top-level field as camelCase
  /// (`signerAddress`) even though the inner contract entries use
  /// snake_case column names.
  final String signerAddress;

  /// All contracts where this address is registered as a signer.
  final List<OZIndexedContractSummary> contracts;

  /// The total number of matching contracts.
  final int count;

  factory OZAddressLookupResponse.fromJson(Map<String, dynamic> json) {
    final rawContracts = json['contracts'] as List<dynamic>? ?? const [];
    return OZAddressLookupResponse(
      signerAddress: json['signerAddress'] as String,
      contracts: rawContracts
          .map((e) =>
              OZIndexedContractSummary.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      count: _asInt(json['count'], 'count'),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'signerAddress': signerAddress,
        'contracts': contracts.map((c) => c.toJson()).toList(growable: false),
        'count': count,
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OZAddressLookupResponse) return false;
    return signerAddress == other.signerAddress &&
        count == other.count &&
        _deepEquality.equals(contracts, other.contracts);
  }

  @override
  int get hashCode =>
      Object.hash(signerAddress, count, _deepEquality.hash(contracts));
}

/// Response containing full details of a smart account contract.
///
/// Includes the contract ID, summary information, and all context rules
/// with their signers and policies.
class OZContractDetailsResponse {
  /// Constructs a contract-details response.
  const OZContractDetailsResponse({
    required this.contractId,
    required this.summary,
    required this.contextRules,
  });

  /// The contract ID queried.
  ///
  /// The indexer returns this top-level field as camelCase
  /// (`contractId`) even though the inner contract entries use
  /// snake_case column names.
  final String contractId;

  /// Summary information about the contract.
  final OZIndexedContractSummary summary;

  /// All context rules defined for the contract.
  final List<OZIndexedContextRule> contextRules;

  factory OZContractDetailsResponse.fromJson(Map<String, dynamic> json) {
    final rawRules = json['contextRules'] as List<dynamic>? ?? const [];
    return OZContractDetailsResponse(
      contractId: json['contractId'] as String,
      summary: OZIndexedContractSummary.fromJson(
          json['summary'] as Map<String, dynamic>),
      contextRules: rawRules
          .map((e) => OZIndexedContextRule.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'contractId': contractId,
        'summary': summary.toJson(),
        'contextRules':
            contextRules.map((r) => r.toJson()).toList(growable: false),
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OZContractDetailsResponse) return false;
    return contractId == other.contractId &&
        summary == other.summary &&
        _deepEquality.equals(contextRules, other.contextRules);
  }

  @override
  int get hashCode =>
      Object.hash(contractId, summary, _deepEquality.hash(contextRules));
}

/// Summary information about a smart account contract.
///
/// Contains aggregate counts and metadata about signers, policies, and
/// context rules.
class OZIndexedContractSummary {
  /// Constructs an indexed contract summary.
  const OZIndexedContractSummary({
    required this.contractId,
    required this.contextRuleCount,
    required this.externalSignerCount,
    required this.delegatedSignerCount,
    required this.nativeSignerCount,
    required this.firstSeenLedger,
    required this.lastSeenLedger,
    required this.contextRuleIds,
  });

  /// The contract ID (`C...` address).
  final String contractId;

  /// Number of context rules configured on the contract.
  final int contextRuleCount;

  /// Number of external signers (WebAuthn/passkey) registered on the contract.
  final int externalSignerCount;

  /// Number of delegated signers (Stellar addresses) registered on the contract.
  final int delegatedSignerCount;

  /// Number of native signers registered on the contract.
  final int nativeSignerCount;

  /// Ledger number when the contract was first seen by the indexer.
  final int firstSeenLedger;

  /// Most recent ledger number when activity for the contract was seen.
  final int lastSeenLedger;

  /// Identifiers of all currently active context rules on the contract.
  final List<int> contextRuleIds;

  factory OZIndexedContractSummary.fromJson(Map<String, dynamic> json) {
    final rawIds = json['context_rule_ids'] as List<dynamic>? ?? const [];
    return OZIndexedContractSummary(
      contractId: json['contract_id'] as String,
      contextRuleCount: _asInt(json['context_rule_count'], 'context_rule_count'),
      externalSignerCount:
          _asInt(json['external_signer_count'], 'external_signer_count'),
      delegatedSignerCount:
          _asInt(json['delegated_signer_count'], 'delegated_signer_count'),
      nativeSignerCount:
          _asInt(json['native_signer_count'], 'native_signer_count'),
      firstSeenLedger: _asInt(json['first_seen_ledger'], 'first_seen_ledger'),
      lastSeenLedger: _asInt(json['last_seen_ledger'], 'last_seen_ledger'),
      contextRuleIds: rawIds
          .map((e) => _asInt(e, 'context_rule_ids[]'))
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'contract_id': contractId,
        'context_rule_count': contextRuleCount,
        'external_signer_count': externalSignerCount,
        'delegated_signer_count': delegatedSignerCount,
        'native_signer_count': nativeSignerCount,
        'first_seen_ledger': firstSeenLedger,
        'last_seen_ledger': lastSeenLedger,
        'context_rule_ids': contextRuleIds,
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OZIndexedContractSummary) return false;
    return contractId == other.contractId &&
        contextRuleCount == other.contextRuleCount &&
        externalSignerCount == other.externalSignerCount &&
        delegatedSignerCount == other.delegatedSignerCount &&
        nativeSignerCount == other.nativeSignerCount &&
        firstSeenLedger == other.firstSeenLedger &&
        lastSeenLedger == other.lastSeenLedger &&
        _deepEquality.equals(contextRuleIds, other.contextRuleIds);
  }

  @override
  int get hashCode => Object.hash(
        contractId,
        contextRuleCount,
        externalSignerCount,
        delegatedSignerCount,
        nativeSignerCount,
        firstSeenLedger,
        lastSeenLedger,
        _deepEquality.hash(contextRuleIds),
      );
}

/// A context rule within a smart account contract.
///
/// Defines authorization requirements (signers and policies) for a specific
/// context (e.g., "Default" or "Call Token Contract X").
class OZIndexedContextRule {
  /// Constructs an indexed context rule.
  const OZIndexedContextRule({
    required this.contextRuleId,
    required this.signers,
    required this.policies,
  });

  /// Identifier of the context rule within the contract.
  final int contextRuleId;

  /// Signers registered for the context rule.
  final List<OZIndexedSigner> signers;

  /// Policies attached to the context rule.
  final List<OZIndexedPolicy> policies;

  factory OZIndexedContextRule.fromJson(Map<String, dynamic> json) {
    final rawSigners = json['signers'] as List<dynamic>? ?? const [];
    final rawPolicies = json['policies'] as List<dynamic>? ?? const [];
    return OZIndexedContextRule(
      contextRuleId: _asInt(json['context_rule_id'], 'context_rule_id'),
      signers: rawSigners
          .map((e) => OZIndexedSigner.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      policies: rawPolicies
          .map((e) => OZIndexedPolicy.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'context_rule_id': contextRuleId,
        'signers': signers.map((s) => s.toJson()).toList(growable: false),
        'policies': policies.map((p) => p.toJson()).toList(growable: false),
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OZIndexedContextRule) return false;
    return contextRuleId == other.contextRuleId &&
        _deepEquality.equals(signers, other.signers) &&
        _deepEquality.equals(policies, other.policies);
  }

  @override
  int get hashCode => Object.hash(
        contextRuleId,
        _deepEquality.hash(signers),
        _deepEquality.hash(policies),
      );
}

/// A signer within a context rule.
///
/// Can be an external signer (WebAuthn/passkey with credential ID), a
/// delegated signer (Stellar address), or a native signer.
class OZIndexedSigner {
  /// Constructs an indexed signer.
  const OZIndexedSigner({
    required this.signerType,
    this.signerAddress,
    this.credentialId,
  });

  /// Signer kind reported by the indexer. Known values: `External`,
  /// `Delegated`, and `Native`.
  final String signerType;

  /// Stellar address for delegated signers; `null` for external or native
  /// signers.
  final String? signerAddress;

  /// Hex-encoded credential ID for external (WebAuthn) signers; `null` for
  /// delegated or native signers.
  final String? credentialId;

  factory OZIndexedSigner.fromJson(Map<String, dynamic> json) {
    return OZIndexedSigner(
      signerType: json['signer_type'] as String,
      signerAddress: json['signer_address'] as String?,
      credentialId: json['credential_id'] as String?,
    );
  }

  /// Serializes the signer to its snake_case JSON object form, omitting
  /// fields whose value is `null` so the output mirrors the indexer's
  /// optional-field encoding.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'signer_type': signerType,
    };
    if (signerAddress != null) {
      map['signer_address'] = signerAddress;
    }
    if (credentialId != null) {
      map['credential_id'] = credentialId;
    }
    return map;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OZIndexedSigner) return false;
    return signerType == other.signerType &&
        signerAddress == other.signerAddress &&
        credentialId == other.credentialId;
  }

  @override
  int get hashCode => Object.hash(signerType, signerAddress, credentialId);
}

/// A policy attached to a context rule.
///
/// Policies enforce additional authorization requirements beyond signature
/// verification (e.g., spending limits, time locks, threshold requirements).
class OZIndexedPolicy {
  /// Constructs an indexed policy.
  const OZIndexedPolicy({
    required this.policyAddress,
    this.installParams,
  });

  /// Contract address of the policy (`C...` address).
  final String policyAddress;

  /// Arbitrary install-time parameters serialized by the policy contract.
  ///
  /// Encoded as an untyped JSON value to preserve any shape (object,
  /// array, primitive, or `null`) the indexer reports.
  final Object? installParams;

  factory OZIndexedPolicy.fromJson(Map<String, dynamic> json) {
    return OZIndexedPolicy(
      policyAddress: json['policy_address'] as String,
      installParams: json['install_params'],
    );
  }

  /// Serializes the policy to its snake_case JSON object form, omitting
  /// `install_params` when it is `null` so the output mirrors the
  /// indexer's optional-field encoding.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'policy_address': policyAddress,
    };
    if (installParams != null) {
      map['install_params'] = installParams;
    }
    return map;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OZIndexedPolicy) return false;
    return policyAddress == other.policyAddress &&
        _deepEquality.equals(installParams, other.installParams);
  }

  @override
  int get hashCode =>
      Object.hash(policyAddress, _deepEquality.hash(installParams));
}

/// Response from the indexer stats endpoint.
///
/// Wraps the indexer's [OZIndexerStats] payload returned at `/api/stats`.
class OZIndexerStatsResponse {
  /// Constructs an indexer stats response.
  const OZIndexerStatsResponse({required this.stats});

  /// The indexer's aggregate statistics.
  final OZIndexerStats stats;

  factory OZIndexerStatsResponse.fromJson(Map<String, dynamic> json) {
    return OZIndexerStatsResponse(
      stats: OZIndexerStats.fromJson(json['stats'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'stats': stats.toJson(),
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OZIndexerStatsResponse) return false;
    return stats == other.stats;
  }

  @override
  int get hashCode => stats.hashCode;
}

/// Statistics about the indexer state.
class OZIndexerStats {
  /// Constructs an indexer stats payload.
  const OZIndexerStats({
    required this.totalEvents,
    required this.uniqueContracts,
    required this.uniqueCredentials,
    required this.firstLedger,
    required this.lastLedger,
    required this.eventTypes,
  });

  /// Total number of events processed by the indexer.
  final int totalEvents;

  /// Number of unique contract IDs indexed.
  final int uniqueContracts;

  /// Number of unique credential IDs indexed.
  final int uniqueCredentials;

  /// First ledger sequence indexed.
  final int firstLedger;

  /// Most recent ledger sequence indexed.
  final int lastLedger;

  /// Breakdown of event counts by event type.
  ///
  /// The indexer emits the JSON key as `eventTypes` (camelCase) while
  /// the count entries themselves use snake_case field names.
  final List<OZEventTypeCount> eventTypes;

  factory OZIndexerStats.fromJson(Map<String, dynamic> json) {
    final rawTypes = json['eventTypes'] as List<dynamic>? ?? const [];
    return OZIndexerStats(
      totalEvents: _asInt(json['total_events'], 'total_events'),
      uniqueContracts: _asInt(json['unique_contracts'], 'unique_contracts'),
      uniqueCredentials:
          _asInt(json['unique_credentials'], 'unique_credentials'),
      firstLedger: _asInt(json['first_ledger'], 'first_ledger'),
      lastLedger: _asInt(json['last_ledger'], 'last_ledger'),
      eventTypes: rawTypes
          .map((e) => OZEventTypeCount.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'total_events': totalEvents,
        'unique_contracts': uniqueContracts,
        'unique_credentials': uniqueCredentials,
        'first_ledger': firstLedger,
        'last_ledger': lastLedger,
        'eventTypes':
            eventTypes.map((e) => e.toJson()).toList(growable: false),
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OZIndexerStats) return false;
    return totalEvents == other.totalEvents &&
        uniqueContracts == other.uniqueContracts &&
        uniqueCredentials == other.uniqueCredentials &&
        firstLedger == other.firstLedger &&
        lastLedger == other.lastLedger &&
        _deepEquality.equals(eventTypes, other.eventTypes);
  }

  @override
  int get hashCode => Object.hash(
        totalEvents,
        uniqueContracts,
        uniqueCredentials,
        firstLedger,
        lastLedger,
        _deepEquality.hash(eventTypes),
      );
}

/// Count of events by type.
class OZEventTypeCount {
  /// Constructs an event-type count.
  const OZEventTypeCount({required this.eventType, required this.count});

  /// Identifier of the event type, e.g. `signer_added`.
  final String eventType;

  /// Number of events of this type observed by the indexer.
  final int count;

  factory OZEventTypeCount.fromJson(Map<String, dynamic> json) {
    return OZEventTypeCount(
      eventType: json['event_type'] as String,
      count: _asInt(json['count'], 'count'),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'event_type': eventType,
        'count': count,
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OZEventTypeCount) return false;
    return eventType == other.eventType && count == other.count;
  }

  @override
  int get hashCode => Object.hash(eventType, count);
}

/// Response from the health check endpoint.
class OZIndexerHealthCheckResponse {
  /// Constructs a health-check response.
  const OZIndexerHealthCheckResponse({required this.status});

  /// The reported health status string (typically `ok`).
  final String status;

  factory OZIndexerHealthCheckResponse.fromJson(Map<String, dynamic> json) {
    return OZIndexerHealthCheckResponse(status: json['status'] as String);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'status': status,
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OZIndexerHealthCheckResponse) return false;
    return status == other.status;
  }

  @override
  int get hashCode => status.hashCode;
}

const String _healthStatusOk = 'ok';

/// Coerces a JSON numeric field that may arrive as either a JSON number or a
/// JSON string-encoded number.
///
/// The indexer service serialises numeric columns (counts, ledger sequence
/// numbers, event totals) as JSON strings to preserve full precision beyond
/// JavaScript's safe-integer range; this helper accepts either a JSON number
/// or a numeric string.
int _asInt(Object? value, String field) {
  if (value is num) return value.toInt();
  if (value is String) {
    final parsed = int.tryParse(value);
    if (parsed != null) return parsed;
  }
  throw FormatException(
    'Indexer field "$field" expected a number or numeric string; '
    'got ${value?.runtimeType}: $value',
  );
}

const Map<String, String> _defaultIndexerUrls = <String, String>{
  'Test SDF Network ; September 2015':
      'https://smart-account-indexer.sdf-ecosystem.workers.dev',
  'Public Global Stellar Network ; September 2015':
      'https://smart-account-indexer-mainnet.sdf-ecosystem.workers.dev',
};

/// Client for interacting with the OpenZeppelin Smart Account indexer service.
///
/// The indexer maps WebAuthn credential IDs and signer addresses to deployed
/// smart account contract addresses, enabling "Connect Wallet" discovery and
/// contract exploration.
///
/// Example:
///
/// ```dart
/// final client = OZIndexerClient('https://indexer.example.com');
/// try {
///   final response = await client.lookupByCredentialId('abc123...');
///   print('Found ${response.count} contracts');
/// } finally {
///   await client.close();
/// }
/// ```
///
/// Throws [InvalidConfig] from the constructor when the URL is blank or
/// uses a non-HTTPS scheme other than `http://localhost`.
class OZIndexerClient {
  /// Creates an indexer client for the given [indexerUrl].
  ///
  /// The optional [timeout] sets the HTTP request timeout used for every
  /// indexer call. Default: [OZConstants.defaultIndexerTimeoutMs].
  OZIndexerClient(this._indexerUrl, {Duration? timeout}) : _dio = dio.Dio() {
    final effectiveTimeout = timeout ??
        Duration(milliseconds: OZConstants.defaultIndexerTimeoutMs);
    _baseUrl = normalizeOZUrl(_indexerUrl, serviceName: 'Indexer');
    _requestOptions = _buildRequestOptions();
    _dio.options.connectTimeout = capConnectTimeout(
        effectiveTimeout, OZConstants.maxIndexerConnectTimeoutMs);
    _dio.options.receiveTimeout = effectiveTimeout;
    _ownsDio = true;
  }

  /// Test-only constructor that injects a pre-configured [dio.Dio] instance.
  ///
  /// The injected client's `options` is not modified: every request is
  /// dispatched with a per-request [dio.Options] that carries the headers,
  /// response type, status validator, and redirect-suppression flags this
  /// client requires. The injected client is NOT closed by [close]; the
  /// caller retains ownership.
  @visibleForTesting
  OZIndexerClient.withDio(this._indexerUrl, this._dio) {
    _baseUrl = normalizeOZUrl(_indexerUrl, serviceName: 'Indexer');
    _requestOptions = _buildRequestOptions();
    _ownsDio = false;
  }

  final String _indexerUrl;
  final dio.Dio _dio;
  late final String _baseUrl;
  late final dio.Options _requestOptions;
  bool _ownsDio = false;
  bool _closed = false;

  /// Mapping from network passphrase to the default indexer URL.
  ///
  /// Entries cover the well-known Stellar testnet and mainnet passphrases.
  /// Reads return an unmodifiable view so callers cannot mutate the
  /// process-wide default map.
  static Map<String, String> get defaultIndexerUrls =>
      Map<String, String>.unmodifiable(_defaultIndexerUrls);

  /// Returns the default indexer URL for the given [networkPassphrase], or
  /// `null` when no default is configured for that network.
  static String? getDefaultUrl(String networkPassphrase) =>
      _defaultIndexerUrls[networkPassphrase];

  /// Returns an [OZIndexerClient] configured for the given [networkPassphrase]
  /// using the well-known default indexer URL, or `null` when no default
  /// URL is configured.
  ///
  /// The optional [timeout] is forwarded to the constructor.
  static OZIndexerClient? forNetwork(
    String networkPassphrase, {
    Duration? timeout,
  }) {
    final url = getDefaultUrl(networkPassphrase);
    if (url == null) {
      return null;
    }
    return OZIndexerClient(url, timeout: timeout);
  }

  /// Looks up smart account contracts by WebAuthn credential ID.
  ///
  /// [credentialId] is a base64url-encoded credential ID (RFC 4648, no
  /// padding). It is decoded to bytes and re-encoded as lowercase hex for
  /// the indexer API.
  ///
  /// The optional [cancelToken] can be cancelled to abort the in-flight
  /// request; a cancelled request surfaces as [IndexerRequestFailed]
  /// with a `Request cancelled` message.
  ///
  /// Throws [InvalidInput] when [credentialId] is not valid base64url,
  /// [IndexerRequestFailed] for network or non-2xx errors, and
  /// [IndexerTimeout] when the request exceeds the configured timeout.
  Future<OZCredentialLookupResponse> lookupByCredentialId(
    String credentialId, {
    dio.CancelToken? cancelToken,
  }) async {
    final hexCredentialId = _base64UrlToHex(credentialId);
    final url = '$_baseUrl/api/lookup/$hexCredentialId';
    final body = await _performRequest(url, cancelToken: cancelToken);
    return OZCredentialLookupResponse.fromJson(_decodeJsonObject(body));
  }

  /// Looks up smart account contracts by signer address.
  ///
  /// [address] is a Stellar account ID (`G...`) or contract address (`C...`).
  ///
  /// The optional [cancelToken] can be cancelled to abort the in-flight
  /// request; a cancelled request surfaces as [IndexerRequestFailed]
  /// with a `Request cancelled` message.
  ///
  /// Throws [InvalidAddress] when [address] is not a valid Stellar address,
  /// [IndexerRequestFailed] for network or non-2xx errors, and
  /// [IndexerTimeout] when the request exceeds the configured timeout.
  Future<OZAddressLookupResponse> lookupByAddress(
    String address, {
    dio.CancelToken? cancelToken,
  }) async {
    requireStellarAddress(address, fieldName: 'address');
    final url = '$_baseUrl/api/lookup/address/$address';
    final body = await _performRequest(url, cancelToken: cancelToken);
    return OZAddressLookupResponse.fromJson(_decodeJsonObject(body));
  }

  /// Gets detailed information about a smart account contract.
  ///
  /// [contractId] is a Stellar contract address (`C...`).
  ///
  /// The optional [cancelToken] can be cancelled to abort the in-flight
  /// request; a cancelled request surfaces as [IndexerRequestFailed]
  /// with a `Request cancelled` message.
  ///
  /// Throws [InvalidAddress] when [contractId] is not a valid contract
  /// address, [IndexerRequestFailed] for network or non-2xx errors, and
  /// [IndexerTimeout] when the request exceeds the configured timeout.
  Future<OZContractDetailsResponse> getContract(
    String contractId, {
    dio.CancelToken? cancelToken,
  }) async {
    requireContractAddress(contractId, fieldName: 'contractId');
    final url = '$_baseUrl/api/contract/$contractId';
    final body = await _performRequest(url, cancelToken: cancelToken);
    return OZContractDetailsResponse.fromJson(_decodeJsonObject(body));
  }

  /// Gets aggregate statistics from the indexer.
  ///
  /// The optional [cancelToken] can be cancelled to abort the in-flight
  /// request; a cancelled request surfaces as [IndexerRequestFailed]
  /// with a `Request cancelled` message.
  ///
  /// Throws [IndexerRequestFailed] for network or non-2xx errors, and
  /// [IndexerTimeout] when the request exceeds the configured timeout.
  Future<OZIndexerStatsResponse> getStats({
    dio.CancelToken? cancelToken,
  }) async {
    final url = '$_baseUrl/api/stats';
    final body = await _performRequest(url, cancelToken: cancelToken);
    return OZIndexerStatsResponse.fromJson(_decodeJsonObject(body));
  }

  /// Checks whether the indexer service is healthy and reachable.
  ///
  /// Performs a lightweight GET on the root endpoint and returns `true`
  /// only when the response is HTTP 2xx AND the body decodes to a JSON
  /// object whose `status` field equals `ok`. Any network failure,
  /// timeout, non-2xx status, cancellation, or malformed body returns
  /// `false`. This method never throws.
  ///
  /// The optional [cancelToken] can be cancelled to abort the in-flight
  /// request; cancellation simply causes the method to return `false`.
  Future<bool> isHealthy({dio.CancelToken? cancelToken}) async {
    try {
      final response = await _dio.get<String>(
        '$_baseUrl/',
        options: _requestOptions,
        cancelToken: cancelToken,
      );
      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        return false;
      }
      if (!isJsonContentType(response.headers.value('content-type'))) {
        return false;
      }
      final body = response.data ?? '';
      if (body.length > OZConstants.maxIndexerResponseBytes) {
        return false;
      }
      final parsed =
          OZIndexerHealthCheckResponse.fromJson(_decodeJsonObject(body));
      return parsed.status == _healthStatusOk;
    } catch (_) {
      return false;
    }
  }

  /// Closes the underlying HTTP client and releases its resources.
  ///
  /// When the client was constructed via [OZIndexerClient.withDio] the
  /// injected [dio.Dio] is NOT closed; the test caller retains ownership.
  /// Subsequent invocations are idempotent and never throw.
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    if (_ownsDio) {
      _dio.close(force: false);
    }
  }

  /// Builds the immutable [dio.Options] applied to every outgoing
  /// request. Captures the headers, response type, status validator,
  /// and redirect-suppression flags expected by every endpoint.
  dio.Options _buildRequestOptions() {
    return dio.Options(
      headers: <String, dynamic>{
        OZConstants.clientNameHeader: OZConstants.clientName,
        OZConstants.clientVersionHeader: StellarSDK.versionNumber,
        'Accept': 'application/json',
      },
      responseType: dio.ResponseType.plain,
      validateStatus: alwaysValidate,
      followRedirects: false,
      maxRedirects: 0,
    );
  }

  /// GETs [url] and returns the raw response body, mapping HTTP and
  /// transport errors to [IndexerException] subtypes.
  Future<String> _performRequest(
    String url, {
    dio.CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<String>(
        url,
        options: _requestOptions,
        cancelToken: cancelToken,
      );
      final body = response.data ?? '';
      if (body.length > OZConstants.maxIndexerResponseBytes) {
        throw IndexerException.requestFailed(
          'Indexer response body exceeds maximum size of '
          '${OZConstants.maxIndexerResponseBytes} bytes',
        );
      }
      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        throw IndexerException.requestFailed(
          'HTTP $status: ${truncateBody(body)}',
        );
      }
      final responseContentType = response.headers.value('content-type');
      if (!isJsonContentType(responseContentType)) {
        throw IndexerException.requestFailed(
          'Unexpected Content-Type: $responseContentType',
        );
      }
      return body;
    } on dio.DioException catch (e) {
      // validateStatus is configured to accept every status code, so dio
      // only raises DioException here for transport, timeout, cancellation,
      // or decoding failures.
      if (e.type == dio.DioExceptionType.cancel) {
        throw IndexerException.requestFailed(
          'Request cancelled',
          cause: e,
        );
      }
      if (isDioTimeout(e)) {
        throw IndexerException.timeout(url, cause: e);
      }
      throw IndexerException.requestFailed(
        dioErrorMessage(e),
        cause: e,
      );
    } on SmartAccountException {
      // SDK exceptions (including IndexerException raised by the
      // non-2xx branch above) must surface unchanged. The
      // `on SmartAccountException` clause prevents the catch-all below
      // from re-wrapping them.
      rethrow;
    } catch (e) {
      throw IndexerException.requestFailed(
        genericErrorMessage(e, defaultText: 'Request failed'),
        cause: e,
      );
    }
  }

  /// Decodes [body] as a JSON object, mapping malformed inputs to
  /// [IndexerRequestFailed] so callers never need to handle a Dart
  /// [FormatException] directly.
  Map<String, dynamic> _decodeJsonObject(String body) {
    Object? parsed;
    try {
      parsed = json.decode(body);
    } on FormatException catch (e) {
      throw IndexerException.requestFailed(
        'Failed to parse indexer response as JSON: ${truncateBody(body)}',
        cause: e,
      );
    }
    if (parsed is! Map<String, dynamic>) {
      throw IndexerException.requestFailed(
        'Indexer response is not a JSON object: ${truncateBody(body)}',
      );
    }
    return parsed;
  }

  String _base64UrlToHex(String base64Url) {
    Uint8List bytes;
    try {
      bytes = base64.decode(base64.normalize(base64Url));
    } on FormatException catch (e) {
      throw ValidationException.invalidInput(
        'credentialId',
        'Failed to decode base64url credential ID: $base64Url',
        cause: e,
      );
    }
    return Util.bytesToHex(bytes);
  }
}
