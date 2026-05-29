// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:dio/dio.dart' as dio;
import 'package:meta/meta.dart';

import '../../stellar_sdk.dart';
import '../../xdr/xdr_host_function.dart';
import '../../xdr/xdr_soroban_authorization_entry.dart';
import '../../xdr/xdr_transaction_envelope.dart';
import '../core/smart_account_errors.dart';
import 'oz_constants.dart';
import 'oz_http_internal.dart';

const DeepCollectionEquality _detailsEquality = DeepCollectionEquality();

/// Known error codes returned by the OpenZeppelin smart-account relayer
/// service.
///
/// Constants identify specific failure conditions and can be used for
/// programmatic error handling. The string value of each constant equals
/// the constant name so it can be compared directly with a server-emitted
/// error-code field.
class OZRelayerErrorCodes {
  OZRelayerErrorCodes._(); // coverage:ignore-line

  /// Request rejected due to invalid parameters.
  static const String invalidParams = 'INVALID_PARAMS';

  /// Request rejected due to invalid XDR.
  static const String invalidXdr = 'INVALID_XDR';

  /// Request rejected because the relayer's pool is full.
  static const String poolCapacity = 'POOL_CAPACITY';

  /// Transaction simulation failed.
  static const String simulationFailed = 'SIMULATION_FAILED';

  /// Transaction succeeded simulation but failed on-chain.
  static const String onchainFailed = 'ONCHAIN_FAILED';

  /// Request rejected due to invalid time bounds.
  static const String invalidTimeBounds = 'INVALID_TIME_BOUNDS';

  /// Request rejected because the requested fee exceeded the relayer limit.
  static const String feeLimitExceeded = 'FEE_LIMIT_EXCEEDED';

  /// Request rejected by the relayer's authorization layer.
  static const String unauthorized = 'UNAUTHORIZED';

  /// Request timed out before the relayer produced a response.
  static const String timeout = 'TIMEOUT';
}

/// Response from the OpenZeppelin smart-account relayer service.
///
/// The relayer wraps transactions with fee bumps and submits them to Stellar,
/// enabling gasless onboarding for users with empty wallets.
class OZRelayerResponse {
  /// Constructs a relayer response.
  const OZRelayerResponse({
    required this.success,
    this.transactionId,
    this.hash,
    this.status,
    this.error,
    this.errorCode,
    this.details,
  });

  /// Whether the relayer reported the submission as successful.
  final bool success;

  /// Transaction ID assigned by the relayer, when reported.
  final String? transactionId;

  /// Transaction hash if submission succeeded.
  final String? hash;

  /// Transaction status (e.g. `PENDING`, `SUCCESS`, `ERROR`).
  final String? status;

  /// Error message if the request failed.
  ///
  /// The `error` string is not further truncated; the entire response body is
  /// bounded by `maxRelayerResponseBytes`.
  final String? error;

  /// Error code if the request failed (see [OZRelayerErrorCodes]).
  ///
  /// Cancellation via the optional `cancelToken` parameter on [send] /
  /// [sendXdr] surfaces as a failed response with `error: 'Request
  /// cancelled'` and a `null` [errorCode]; no dedicated error code is
  /// emitted.
  final String? errorCode;

  /// Additional error details from the relayer, when reported.
  ///
  /// Holds either a JSON object or a JSON-compatible value depending on the
  /// relayer's response shape.
  final Object? details;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OZRelayerResponse) return false;
    return success == other.success &&
        transactionId == other.transactionId &&
        hash == other.hash &&
        status == other.status &&
        error == other.error &&
        errorCode == other.errorCode &&
        _detailsEquality.equals(details, other.details);
  }

  @override
  int get hashCode => Object.hash(
        success,
        transactionId,
        hash,
        status,
        error,
        errorCode,
        _detailsEquality.hash(details),
      );
}

/// Client for submitting transactions to an OpenZeppelin smart-account
/// relayer.
///
/// Two submission modes are supported:
///
/// 1. **Host function + auth entries** — [send] submits transaction
///    components separately for the relayer to assemble, fee-bump, and
///    submit.
/// 2. **Signed transaction envelope** — [sendXdr] submits a complete
///    signed envelope for the relayer to fee-bump and submit.
///
/// Both methods return an [OZRelayerResponse] and never throw on network
/// failure, timeout, cancellation, or relayer-reported errors; only
/// constructor validation throws.
///
/// Example:
///
/// ```dart
/// final relayer = OZRelayerClient('https://relayer.example.com');
/// try {
///   final response = await relayer.send(hostFunction, authEntries);
///   if (response.success) {
///     print('hash: ${response.hash}');
///   } else {
///     print('error: ${response.error} (${response.errorCode})');
///   }
/// } finally {
///   await relayer.close();
/// }
/// ```
///
/// Throws [InvalidConfig] from the constructor when the URL is blank or
/// uses a non-HTTPS scheme other than `http://localhost`.
class OZRelayerClient {
  /// Creates a relayer client for the given [relayerUrl].
  ///
  /// The optional [timeout] sets the default HTTP request timeout used
  /// when no per-request override is supplied. Default:
  /// [OZConstants.defaultRelayerTimeoutMs].
  OZRelayerClient(this._relayerUrl, {Duration? timeout}) : _dio = dio.Dio() {
    _defaultTimeout =
        timeout ?? Duration(milliseconds: OZConstants.defaultRelayerTimeoutMs);
    _normalizedUrl = normalizeOZUrl(_relayerUrl, serviceName: 'Relayer');
    _requestOptions = _buildRequestOptions();
    _dio.options.connectTimeout = capConnectTimeout(
        _defaultTimeout, OZConstants.maxRelayerConnectTimeoutMs);
    _dio.options.receiveTimeout = _defaultTimeout;
    _dio.options.sendTimeout = _defaultTimeout;
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
  OZRelayerClient.withDio(this._relayerUrl, this._dio) {
    _defaultTimeout =
        Duration(milliseconds: OZConstants.defaultRelayerTimeoutMs);
    _normalizedUrl = normalizeOZUrl(_relayerUrl, serviceName: 'Relayer');
    _requestOptions = _buildRequestOptions();
    _ownsDio = false;
  }

  final String _relayerUrl;
  final dio.Dio _dio;
  late final String _normalizedUrl;
  late final Duration _defaultTimeout;
  late final dio.Options _requestOptions;
  bool _ownsDio = false;
  bool _closed = false;

  /// Submits a transaction using a host function and authorization entries.
  ///
  /// The relayer constructs a full transaction from these components, wraps
  /// it with a fee bump, and submits it to the Stellar network. All
  /// failures are surfaced in the returned [OZRelayerResponse]; this method
  /// does not throw.
  ///
  /// The optional [perRequestTimeoutMs] overrides the client-level default
  /// timeout for this request only.
  ///
  /// The optional [cancelToken] can be cancelled to abort the in-flight
  /// request; a cancelled request surfaces as an [OZRelayerResponse] with
  /// `success: false`, `error: 'Request cancelled'`, and a `null`
  /// `errorCode`.
  Future<OZRelayerResponse> send(
    XdrHostFunction hostFunction,
    List<XdrSorobanAuthorizationEntry> authEntries, {
    int? perRequestTimeoutMs,
    dio.CancelToken? cancelToken,
  }) async {
    String funcBase64;
    try {
      funcBase64 = hostFunction.toBase64EncodedXdrString();
    } catch (e) {
      return OZRelayerResponse(
        success: false,
        error: 'Failed to encode host function to XDR: $e',
      );
    }
    final authBase64 = <String>[];
    try {
      for (final entry in authEntries) {
        authBase64.add(entry.toBase64EncodedXdrString());
      }
    } catch (e) {
      return OZRelayerResponse(
        success: false,
        error: 'Failed to encode auth entry to XDR: $e',
      );
    }
    final payload = <String, dynamic>{
      'func': funcBase64,
      'auth': authBase64,
    };
    return _performRequest(payload, perRequestTimeoutMs, cancelToken);
  }

  /// Submits a complete signed transaction envelope.
  ///
  /// Use this for transactions that require source-account authorization
  /// (e.g. deployment). The relayer fee-bumps the signed transaction,
  /// preserving the inner signature. All failures are surfaced in the
  /// returned [OZRelayerResponse]; this method does not throw.
  ///
  /// The optional [perRequestTimeoutMs] overrides the client-level default
  /// timeout for this request only.
  ///
  /// The optional [cancelToken] can be cancelled to abort the in-flight
  /// request; a cancelled request surfaces as an [OZRelayerResponse] with
  /// `success: false`, `error: 'Request cancelled'`, and a `null`
  /// `errorCode`.
  Future<OZRelayerResponse> sendXdr(
    XdrTransactionEnvelope transactionEnvelope, {
    int? perRequestTimeoutMs,
    dio.CancelToken? cancelToken,
  }) async {
    String xdrBase64;
    try {
      xdrBase64 = transactionEnvelope.toBase64EncodedXdrString();
    } catch (e) {
      return OZRelayerResponse(
        success: false,
        error: 'Failed to encode transaction envelope to XDR: $e',
      );
    }
    final payload = <String, dynamic>{
      'xdr': xdrBase64,
    };
    return _performRequest(payload, perRequestTimeoutMs, cancelToken);
  }

  /// Closes the underlying HTTP client and releases its resources.
  ///
  /// When the client was constructed via [OZRelayerClient.withDio] the
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
  /// and redirect-suppression flags expected by the relayer endpoint.
  dio.Options _buildRequestOptions() {
    return dio.Options(
      headers: <String, dynamic>{
        OZConstants.clientNameHeader: OZConstants.clientName,
        OZConstants.clientVersionHeader: StellarSDK.versionNumber,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      responseType: dio.ResponseType.plain,
      validateStatus: alwaysValidate,
      followRedirects: false,
      maxRedirects: 0,
    );
  }

  Future<OZRelayerResponse> _performRequest(
    Map<String, dynamic> payload,
    int? perRequestTimeoutMs,
    dio.CancelToken? cancelToken,
  ) async {
    dio.Response<String> response;
    try {
      dio.Options effectiveOptions = _requestOptions;
      if (perRequestTimeoutMs != null) {
        final perRequestDuration =
            Duration(milliseconds: perRequestTimeoutMs);
        effectiveOptions = effectiveOptions.copyWith(
          receiveTimeout: perRequestDuration,
          sendTimeout: perRequestDuration,
        );
      }
      response = await _dio.post<String>(
        _normalizedUrl,
        data: json.encode(payload),
        options: effectiveOptions,
        cancelToken: cancelToken,
      );
    } on dio.DioException catch (e) {
      if (e.type == dio.DioExceptionType.cancel) {
        return const OZRelayerResponse(
          success: false,
          error: 'Request cancelled',
        );
      }
      if (isDioTimeout(e)) {
        return const OZRelayerResponse(
          success: false,
          error: 'Relayer request timed out',
          errorCode: OZRelayerErrorCodes.timeout,
        );
      }
      return OZRelayerResponse(
        success: false,
        error: dioErrorMessage(e, defaultText: 'Relayer request failed'),
      );
    } catch (e) {
      return OZRelayerResponse(
        success: false,
        error:
            genericErrorMessage(e, defaultText: 'Relayer request failed'),
      );
    }

    final body = response.data ?? '';
    if (body.length > OZConstants.maxRelayerResponseBytes) {
      return OZRelayerResponse(
        success: false,
        error: 'Relayer response body exceeds maximum size of '
            '${OZConstants.maxRelayerResponseBytes} bytes',
      );
    }

    final responseContentType = response.headers.value('content-type');
    if (!isJsonContentType(responseContentType)) {
      return OZRelayerResponse(
        success: false,
        error: 'Unexpected Content-Type: $responseContentType',
      );
    }

    Map<String, dynamic> responseJson;
    try {
      final decoded = json.decode(body);
      if (decoded is! Map<String, dynamic>) {
        return OZRelayerResponse(
          success: false,
          error:
              'Failed to parse relayer response as JSON: ${truncateBody(body)}',
        );
      }
      responseJson = decoded;
    } on FormatException {
      return OZRelayerResponse(
        success: false,
        error:
            'Failed to parse relayer response as JSON: ${truncateBody(body)}',
      );
    }

    final status = response.statusCode ?? 0;
    final bodySuccess = _readBool(responseJson['success']);

    if (status >= 200 && status < 300 && bodySuccess) {
      Map<String, dynamic> source = responseJson;
      final wrapped = responseJson['data'];
      if (wrapped is Map<String, dynamic>) {
        source = wrapped;
      }
      return OZRelayerResponse(
        success: true,
        transactionId: _readString(source['transactionId']),
        hash: _readString(source['hash']),
        status: _readString(source['status']),
      );
    }

    final errorMessage = _readString(responseJson['error']) ??
        _readString(responseJson['message']) ??
        'Relayer request failed with status $status';
    // why: the relayer's `error` field is a server-curated string intended
    // for direct display, often containing a transaction simulation error
    // followed by a multi-line diagnostic event log. The overall body is
    // already bounded by `maxRelayerResponseBytes`; truncating the parsed
    // error a second time would drop the event log without preserving the
    // most actionable trailing context.
    final errorCode = _extractErrorCode(responseJson);
    final Object? details =
        responseJson.containsKey('data') ? responseJson['data'] : responseJson;

    return OZRelayerResponse(
      success: false,
      error: errorMessage,
      errorCode: errorCode,
      details: details,
    );
  }
}

/// Reads the relayer error code from the parsed [responseJson] in the
/// following lookup order:
///
/// 1. Top-level `code`
/// 2. Top-level `errorCode`
/// 3. Nested `data.code`
///
/// Returns `null` when none of the candidate fields contains a string
/// value.
String? _extractErrorCode(Map<String, dynamic> responseJson) {
  final topCode = _readString(responseJson['code']);
  if (topCode != null) {
    return topCode;
  }
  final topErrorCode = _readString(responseJson['errorCode']);
  if (topErrorCode != null) {
    return topErrorCode;
  }
  final data = responseJson['data'];
  if (data is Map<String, dynamic>) {
    final nested = _readString(data['code']);
    if (nested != null) {
      return nested;
    }
  }
  return null;
}

bool _readBool(Object? value) {
  if (value is bool) {
    return value;
  }
  return false;
}

String? _readString(Object? value) {
  if (value is String) {
    return value;
  }
  return null;
}
