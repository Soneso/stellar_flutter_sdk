// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart' as dio;
import 'package:stellar_flutter_sdk/src/account.dart';
import 'package:stellar_flutter_sdk/src/key_pair.dart';
import 'package:stellar_flutter_sdk/src/network.dart';
import 'package:stellar_flutter_sdk/src/smartaccount/core/allow_credential.dart';
import 'package:stellar_flutter_sdk/src/smartaccount/core/smart_account_errors.dart';
import 'package:stellar_flutter_sdk/src/smartaccount/core/web_authn_provider.dart';
import 'package:stellar_flutter_sdk/src/smartaccount/oz/oz_internal_pipeline_interfaces.dart';
import 'package:stellar_flutter_sdk/src/smartaccount/oz/oz_smart_account_events.dart';
import 'package:stellar_flutter_sdk/src/smartaccount/oz/oz_storage_adapter.dart';
import 'package:stellar_flutter_sdk/src/smartaccount/oz/oz_transaction_operations.dart';
import 'package:stellar_flutter_sdk/src/soroban/soroban_server.dart';
import 'package:stellar_flutter_sdk/src/transaction.dart';
import 'package:stellar_flutter_sdk/src/xdr/xdr.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart'
    show
        SmartAccountEventWalletDisconnected,
        StoredCredential,
        InMemoryStorageAdapter,
        StorageAdapter,
        OZSmartAccountConfig,
        OZExternalSignerManager,
        OZIndexerClient,
        OZRelayerClient,
        OZSmartAccountSigner,
        ExternalWalletAdapter,
        ParsedContextRule;

/// Test fixture: a fake transaction-operations kit that supplies just enough
/// surface to drive pipeline-level test cases without opening real network
/// connections. The default [_sorobanServer] is a [_NullSorobanServer] that
/// raises [UnsupportedError] on every call; tests that exercise the
/// pipeline supply a [MockSorobanServer] or alternative double.
class FakePipelineKit implements OZSmartAccountWalletKitInterface {
  FakePipelineKit({
    OZSmartAccountConfig? config,
    SorobanServer? sorobanServer,
    OZIndexerClient? indexerClient,
    OZRelayerClient? relayerClient,
    KeyPair? deployer,
    OZWalletCredentialManagerInterface? credentialManager,
    OZContextRuleManagerInterface? contextRuleManager,
    StorageAdapter? storage,
    OZTransactionOperations? transactionOperations,
    Object? multiSignerManager,
    ExternalWalletAdapter? externalWallet,
    OZExternalSignerManager? externalSignerManager,
  })  : _config = config ??
            OZSmartAccountConfig(
              rpcUrl: 'https://soroban-testnet.stellar.org',
              networkPassphrase: Network.TESTNET.networkPassphrase,
              accountWasmHash:
                  '0' * 64, // placeholder 32-byte hex
              webauthnVerifierAddress:
                  'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK',
            ),
        _sorobanServer = sorobanServer ?? _NullSorobanServer(),
        _indexerClient = indexerClient,
        _relayerClient = relayerClient,
        _deployer = deployer ?? KeyPair.random(),
        _credentialManager = credentialManager ?? StubCredentialManager(),
        _contextRuleManager =
            contextRuleManager ?? StubContextRuleManager(),
        _storage = storage ?? InMemoryStorageAdapter(),
        _events = SmartAccountEventEmitter(),
        _injectedMultiSignerManager = multiSignerManager,
        _externalWallet = externalWallet,
        _externalSignerManager = externalSignerManager {
    _transactionOperations =
        transactionOperations ?? OZTransactionOperations(this);
  }

  OZSmartAccountConfig _config;
  final SorobanServer _sorobanServer;
  final OZIndexerClient? _indexerClient;
  final OZRelayerClient? _relayerClient;
  final KeyPair _deployer;
  final OZWalletCredentialManagerInterface _credentialManager;
  final OZContextRuleManagerInterface _contextRuleManager;
  StorageAdapter _storage;
  final SmartAccountEventEmitter _events;
  late OZTransactionOperations _transactionOperations;
  Object? _injectedMultiSignerManager;
  ExternalWalletAdapter? _externalWallet;
  OZExternalSignerManager? _externalSignerManager;

  /// Test-only setter for the injected multi-signer manager. Lets tests
  /// rebind the kit's `multiSignerManager` accessor after construction
  /// (useful when the manager itself depends on the constructed kit).
  void setMultiSignerManager(Object manager) {
    _injectedMultiSignerManager = manager;
  }

  /// Test-only setter for the external wallet adapter exposed via the
  /// kit interface, mirroring `setMultiSignerManager` above.
  void setExternalWallet(ExternalWalletAdapter? adapter) {
    _externalWallet = adapter;
  }

  /// Test-only setter for the external-signer manager.
  void setExternalSignerManager(OZExternalSignerManager? manager) {
    _externalSignerManager = manager;
  }

  /// Test-only setter for the transaction operations exposed via the
  /// `OZSmartAccountWalletKitInterface` accessor. The state-changing
  /// manager tests inject [MockOZTransactionOperations] after
  /// construction so the per-test mock is bound to the real kit
  /// reference.
  void setTransactionOperations(OZTransactionOperations operations) {
    _transactionOperations = operations;
  }

  String? _connectedCredentialId;
  String? _connectedContractId;

  /// Sets the connected state directly without going through the wallet
  /// lifecycle, useful for validation tests.
  void setConnected({required String credentialId, required String contractId}) {
    _connectedCredentialId = credentialId;
    _connectedContractId = contractId;
  }

  /// Allows tests to inject a freshly-rebuilt config (e.g. when toggling
  /// the WebAuthn provider on or off mid-test).
  void replaceConfig(OZSmartAccountConfig config) {
    _config = config;
  }

  /// Allows tests to inject a different storage adapter.
  void replaceStorage(StorageAdapter storage) {
    _storage = storage;
  }

  /// Test-only `disconnect()`. Clears the connected state, emits the
  /// `WalletDisconnected` event when a wallet was connected at call time,
  /// and clears the session entry from storage.
  Future<void> disconnect() async {
    final wasConnected =
        _connectedCredentialId != null && _connectedContractId != null;
    final priorContractId = _connectedContractId;
    _connectedCredentialId = null;
    _connectedContractId = null;
    try {
      await _storage.clearSession();
    } catch (_) {
      // Non-critical — clearing is best-effort.
    }
    if (wasConnected && priorContractId != null) {
      _events.emit(
        SmartAccountEventWalletDisconnected(contractId: priorContractId),
      );
    }
  }

  @override
  OZSmartAccountConfig get config => _config;

  @override
  SorobanServer get sorobanServer => _sorobanServer;

  @override
  SmartAccountEventEmitter get events => _events;

  @override
  OZIndexerClient? get indexerClient => _indexerClient;

  @override
  OZRelayerClient? get relayerClient => _relayerClient;

  @override
  OZWalletCredentialManagerInterface get credentialManager => _credentialManager;

  @override
  OZContextRuleManagerInterface get contextRuleManager => _contextRuleManager;

  @override
  Future<KeyPair> getDeployer() async => _deployer;

  @override
  StorageAdapter getStorage() => _storage;

  @override
  Future<OZConnectedState> requireConnected() async {
    final cid = _connectedCredentialId;
    final ctr = _connectedContractId;
    if (cid == null || ctr == null) {
      throw WalletException.notConnected();
    }
    return OZConnectedState(credentialId: cid, contractId: ctr);
  }

  @override
  Future<void> setConnectedState({
    required String credentialId,
    required String contractId,
  }) async {
    _connectedCredentialId = credentialId;
    _connectedContractId = contractId;
  }

  @override
  OZTransactionOperations get transactionOperations => _transactionOperations;

  @override
  String? get contractId => _connectedContractId;

  @override
  ExternalWalletAdapter? get externalWallet => _externalWallet;

  @override
  OZExternalSignerManager? get externalSignerManager => _externalSignerManager;

  @override
  Object get multiSignerManager {
    final injected = _injectedMultiSignerManager;
    if (injected != null) return injected;
    throw UnsupportedError(
      'FakePipelineKit does not provide a multi-signer manager by '
      'default; tests that exercise multi-signer routing should '
      'inject one via the constructor or `setMultiSignerManager`.',
    );
  }
}

/// Stub credential manager exposed for tests that need to inject stored
/// credentials directly or assert on stored state after operations.
class StubCredentialManager implements OZWalletCredentialManagerInterface {
  final Map<String, StoredCredential> _store = {};

  /// Records every `markDeploymentFailed` call so tests can assert on
  /// failure propagation.
  final List<({String credentialId, String error})> markedFailures =
      <({String credentialId, String error})>[];

  /// Records every `deleteCredential` call.
  final List<String> deletedCredentialIds = <String>[];

  @override
  Future<StoredCredential?> getCredential(String credentialId) async {
    return _store[credentialId];
  }

  @override
  Future<void> updateLastUsed(String credentialId) async {
    final existing = _store[credentialId];
    if (existing != null) {
      _store[credentialId] = existing.copyWith(
        lastUsedAt: DateTime.now().millisecondsSinceEpoch,
      );
    }
  }

  @override
  Future<StoredCredential> createPendingCredential({
    required String credentialId,
    required Uint8List publicKey,
    required String contractId,
    String? nickname,
    List<String>? transports,
    String? deviceType,
    bool? backedUp,
  }) async {
    final c = StoredCredential(
      credentialId: credentialId,
      publicKey: publicKey,
      contractId: contractId,
      nickname: nickname,
      transports: transports,
      deviceType: deviceType,
      backedUp: backedUp,
    );
    _store[credentialId] = c;
    return c;
  }

  @override
  Future<void> markDeploymentFailed({
    required String credentialId,
    required String error,
  }) async {
    markedFailures.add((credentialId: credentialId, error: error));
    final existing = _store[credentialId];
    if (existing != null) {
      _store[credentialId] = existing.copyWith(
        deploymentStatus: CredentialDeploymentStatus.failed,
        deploymentError: error,
      );
    }
  }

  @override
  Future<void> setPrimary(String credentialId) async {
    final existing = _store[credentialId];
    if (existing != null) {
      _store[credentialId] = existing.copyWith(isPrimary: true);
    }
  }

  @override
  Future<void> deleteCredential({required String credentialId}) async {
    deletedCredentialIds.add(credentialId);
    _store.remove(credentialId);
  }

  /// Test-only: directly inject a stored credential.
  void inject(StoredCredential credential) {
    _store[credential.credentialId] = credential;
  }

  /// Test-only: returns the credential currently stored under
  /// [credentialId], or `null`.
  StoredCredential? peek(String credentialId) => _store[credentialId];
}

/// Stub context-rule manager exposed for tests that need to inject
/// context-rule state without standing up the full rule manager.
class StubContextRuleManager implements OZContextRuleManagerInterface {
  List<Object> rules = const <Object>[];
  List<XdrSCVal> allRules = const <XdrSCVal>[];
  List<int> resolved = const <int>[];

  /// Per-rule-id lookup table consumed by [getContextRule]. When unset,
  /// [getContextRule] throws to mirror the contract's "rule not found"
  /// behaviour.
  Map<int, XdrSCVal> contextRulesById = const <int, XdrSCVal>{};

  /// Pre-set table consumed by [parseContextRule]. When unset, the
  /// stub throws to surface accidental parser invocations during
  /// pipeline tests.
  Map<XdrSCVal, ParsedContextRule> parsedContextRules =
      const <XdrSCVal, ParsedContextRule>{};

  @override
  Future<List<Object>> listContextRules() async => rules;

  @override
  Future<List<int>> resolveContextRuleIdsForEntry(
    XdrSorobanAuthorizationEntry entry,
    List<OZSmartAccountSigner> signers,
    List<Object> contextRules,
  ) async {
    return resolved;
  }

  @override
  Future<List<XdrSCVal>> getAllContextRules({int? maxScanId}) async => allRules;

  @override
  Future<XdrSCVal> getContextRule(int id) async {
    final scVal = contextRulesById[id];
    if (scVal == null) {
      throw StateError(
        'StubContextRuleManager.getContextRule called with id=$id but '
        'no entry was set in contextRulesById.',
      );
    }
    return scVal;
  }

  @override
  ParsedContextRule parseContextRule(XdrSCVal scVal) {
    final rule = parsedContextRules[scVal];
    if (rule == null) {
      throw StateError(
        'StubContextRuleManager.parseContextRule called for an '
        'unregistered ScVal; populate parsedContextRules in the test '
        'fixture.',
      );
    }
    return rule;
  }
}

/// Test-only credential manager exposure for tests that need stub-level
/// behaviour mutation (no public API on the kit interface).
OZWalletCredentialManagerInterface stubCredentialManager() =>
    StubCredentialManager();

/// Test-only context-rule manager exposure.
OZContextRuleManagerInterface stubContextRuleManager() =>
    StubContextRuleManager();

// ---------------------------------------------------------------------------
// Mock SorobanServer infrastructure for the pipeline tests.
// ---------------------------------------------------------------------------

/// A [SorobanServer] subclass that throws [UnsupportedError] on every
/// method. Used as the FakePipelineKit default so validation-only tests
/// never make accidental network calls.
class _NullSorobanServer extends SorobanServer {
  _NullSorobanServer() : super('https://unused.test/');

  Never _unsupported() => throw UnsupportedError(
        'Test fixture has no SorobanServer configured; supply a '
        'MockSorobanServer or alternative double to exercise this path.',
      );

  @override
  Future<GetHealthResponse> getHealth() => _unsupported();

  @override
  Future<GetVersionInfoResponse> getVersionInfo() => _unsupported();

  @override
  Future<GetFeeStatsResponse> getFeeStats() => _unsupported();

  @override
  Future<GetLatestLedgerResponse> getLatestLedger() => _unsupported();

  @override
  Future<GetLedgerEntriesResponse> getLedgerEntries(List<String> base64keys) =>
      _unsupported();

  @override
  Future<Account?> getAccount(String accountId) => _unsupported();

  @override
  Future<LedgerEntry?> getContractData(
    String contractId,
    XdrSCVal key,
    XdrContractDataDurability durability,
  ) =>
      _unsupported();

  @override
  Future<SimulateTransactionResponse> simulateTransaction(
    SimulateTransactionRequest request,
  ) =>
      _unsupported();

  @override
  Future<SendTransactionResponse> sendTransaction(Transaction transaction) =>
      _unsupported();

  @override
  Future<GetTransactionResponse> getTransaction(String transactionHash) =>
      _unsupported();

  @override
  Future<GetTransactionResponse> pollTransaction(
    String transactionHash, {
    int maxAttempts = 30,
    Duration Function(int)? sleepStrategy,
  }) =>
      _unsupported();
}

/// A scriptable [SorobanServer] subclass used by pipeline tests.
///
/// Tests populate the [simulateResponses], [sendResponses], and
/// [getTransactionResponses] queues with the canned responses each call
/// should return. The mock records every invocation in the corresponding
/// `*Calls` list so tests can assert on call order, payloads, and counts.
class MockSorobanServer extends SorobanServer {
  MockSorobanServer() : super('https://unused.test/');

  /// Queue of simulation outcomes returned in order. When the queue is
  /// exhausted the mock falls back to [simulateDefault] (when set) or
  /// raises [StateError].
  final List<Object> simulateResponses = <Object>[];

  /// Optional fallback response when [simulateResponses] is empty.
  Object? simulateDefault;

  /// Captures every `simulateTransaction` invocation in order.
  final List<SimulateTransactionRequest> simulateCalls =
      <SimulateTransactionRequest>[];

  /// Queue of `sendTransaction` outcomes returned in order.
  final List<Object> sendResponses = <Object>[];

  /// Fallback `sendTransaction` outcome when [sendResponses] is empty.
  Object? sendDefault;

  /// Captures every `sendTransaction` invocation.
  final List<Transaction> sendCalls = <Transaction>[];

  /// Queue of `getTransaction` outcomes.
  final List<Object> getTransactionResponses = <Object>[];

  /// Fallback `getTransaction` outcome.
  Object? getTransactionDefault;

  /// Captures every `getTransaction` invocation.
  final List<String> getTransactionCalls = <String>[];

  /// Queue of `getLatestLedger` outcomes.
  final List<Object> latestLedgerResponses = <Object>[];

  /// Fallback `getLatestLedger` outcome.
  Object? latestLedgerDefault;

  /// Queue of `getAccount` outcomes.
  final List<Object> getAccountResponses = <Object>[];

  /// Fallback `getAccount` outcome.
  Object? getAccountDefault;

  /// Captures every `getAccount` invocation.
  final List<String> getAccountCalls = <String>[];

  /// Queue of `getContractData` outcomes. May contain a [LedgerEntry], a
  /// [Function] returning one, an exception to throw, or a plain `null`
  /// (`null` is used to signal "no entry on-chain" so the SDK throws
  /// [WalletException.notFound] in `_verifyContractExists`).
  final List<Object?> getContractDataResponses = <Object?>[];

  /// Fallback `getContractData` outcome.
  Object? getContractDataDefault;

  /// Captures every `getContractData` invocation as
  /// `(contractId, key, durability)`.
  final List<({String contractId, XdrSCVal key, XdrContractDataDurability durability})>
      getContractDataCalls = <({
    String contractId,
    XdrSCVal key,
    XdrContractDataDurability durability
  })>[];

  /// Queue of `pollTransaction` outcomes.
  final List<Object> pollResponses = <Object>[];

  /// Fallback `pollTransaction` outcome.
  Object? pollDefault;

  /// Captures every `pollTransaction` invocation.
  final List<String> pollCalls = <String>[];

  T _next<T>(List<Object> queue, Object? fallback, String methodName) {
    if (queue.isNotEmpty) {
      final v = queue.removeAt(0);
      return _materialise<T>(v, methodName);
    }
    if (fallback != null) {
      return _materialise<T>(fallback, methodName);
    }
    throw StateError('MockSorobanServer.$methodName called but no response queued');
  }

  T _materialise<T>(Object v, String methodName) {
    if (v is Object Function()) {
      return v() as T;
    }
    if (v is Exception || v is Error) {
      throw v;
    }
    return v as T;
  }

  @override
  Future<SimulateTransactionResponse> simulateTransaction(
    SimulateTransactionRequest request,
  ) async {
    simulateCalls.add(request);
    return _next<SimulateTransactionResponse>(
      simulateResponses,
      simulateDefault,
      'simulateTransaction',
    );
  }

  @override
  Future<SendTransactionResponse> sendTransaction(Transaction transaction) async {
    sendCalls.add(transaction);
    return _next<SendTransactionResponse>(
      sendResponses,
      sendDefault,
      'sendTransaction',
    );
  }

  @override
  Future<GetTransactionResponse> getTransaction(String transactionHash) async {
    getTransactionCalls.add(transactionHash);
    return _next<GetTransactionResponse>(
      getTransactionResponses,
      getTransactionDefault,
      'getTransaction',
    );
  }

  @override
  Future<GetLatestLedgerResponse> getLatestLedger() async {
    return _next<GetLatestLedgerResponse>(
      latestLedgerResponses,
      latestLedgerDefault,
      'getLatestLedger',
    );
  }

  @override
  Future<Account?> getAccount(String accountId) async {
    getAccountCalls.add(accountId);
    return _next<Account?>(
      getAccountResponses,
      getAccountDefault,
      'getAccount',
    );
  }

  @override
  Future<LedgerEntry?> getContractData(
    String contractId,
    XdrSCVal key,
    XdrContractDataDurability durability,
  ) async {
    getContractDataCalls.add((
      contractId: contractId,
      key: key,
      durability: durability,
    ));
    return _nextNullable<LedgerEntry?>(
      getContractDataResponses,
      getContractDataDefault,
      'getContractData',
    );
  }

  /// Variant of [_next] that allows a `null` queue entry (used by
  /// [getContractData] to express "no on-chain entry").
  T _nextNullable<T>(
    List<Object?> queue,
    Object? fallback,
    String methodName,
  ) {
    if (queue.isNotEmpty) {
      final v = queue.removeAt(0);
      if (v == null) return null as T;
      return _materialise<T>(v, methodName);
    }
    if (fallback != null) {
      return _materialise<T>(fallback, methodName);
    }
    throw StateError('MockSorobanServer.$methodName called but no response queued');
  }

  @override
  Future<GetTransactionResponse> pollTransaction(
    String transactionHash, {
    int maxAttempts = 30,
    Duration Function(int)? sleepStrategy,
  }) async {
    pollCalls.add(transactionHash);
    return _next<GetTransactionResponse>(
      pollResponses,
      pollDefault,
      'pollTransaction',
    );
  }
}

// ---------------------------------------------------------------------------
// Recording WebAuthn provider — minimal stub for signing tests.
// ---------------------------------------------------------------------------

/// Records every `register`/`authenticate` call and returns canned
/// responses populated by the test.
class RecordingWebAuthnProvider implements WebAuthnProvider {
  final List<({Uint8List challenge, Uint8List userId, String userName})>
      registerCalls = <({
    Uint8List challenge,
    Uint8List userId,
    String userName
  })>[];

  final List<({Uint8List challenge, List<AllowCredential>? allowCredentials})>
      authenticateCalls = <({
    Uint8List challenge,
    List<AllowCredential>? allowCredentials
  })>[];

  /// Queue of registration outcomes; can hold [WebAuthnRegistrationResult]
  /// or an exception to throw.
  final List<Object> registerResponses = <Object>[];

  /// Queue of authentication outcomes.
  final List<Object> authenticateResponses = <Object>[];

  T _next<T>(List<Object> queue, String methodName) {
    if (queue.isEmpty) {
      throw StateError(
        'RecordingWebAuthnProvider.$methodName called but no response queued',
      );
    }
    final v = queue.removeAt(0);
    if (v is Exception || v is Error) {
      throw v;
    }
    return v as T;
  }

  @override
  Future<WebAuthnRegistrationResult> register({
    required Uint8List challenge,
    required Uint8List userId,
    required String userName,
  }) async {
    registerCalls.add((
      challenge: challenge,
      userId: userId,
      userName: userName,
    ));
    return _next<WebAuthnRegistrationResult>(registerResponses, 'register');
  }

  @override
  Future<WebAuthnAuthenticationResult> authenticate({
    required Uint8List challenge,
    List<AllowCredential>? allowCredentials,
  }) async {
    authenticateCalls.add((
      challenge: challenge,
      allowCredentials: allowCredentials,
    ));
    return _next<WebAuthnAuthenticationResult>(
      authenticateResponses,
      'authenticate',
    );
  }
}

// ---------------------------------------------------------------------------
// Recording OZIndexerClient + OZRelayerClient via dio adapter hooks.
// ---------------------------------------------------------------------------

/// Records every invocation of an [OZIndexerClient] HTTP request and
/// returns canned responses. Drives the indexer-cascade tests without
/// making real network calls.
class RecordingIndexerClient extends OZIndexerClient {
  RecordingIndexerClient._(dio.Dio innerDio)
      : super.withDio('https://indexer.test', innerDio);

  factory RecordingIndexerClient(_RecordingDioAdapter adapter) {
    final inner = dio.Dio()..httpClientAdapter = adapter;
    return RecordingIndexerClient._(inner);
  }
}

/// Records every invocation of an [OZRelayerClient] HTTP request and
/// returns canned responses.
class RecordingRelayerClient extends OZRelayerClient {
  RecordingRelayerClient._(dio.Dio innerDio)
      : super.withDio('https://relayer.test', innerDio);

  factory RecordingRelayerClient(_RecordingDioAdapter adapter) {
    final inner = dio.Dio()..httpClientAdapter = adapter;
    return RecordingRelayerClient._(inner);
  }
}

/// Dio adapter that returns a fixed canned response (or raises a fixed
/// error) and captures the most recent request URL and body so tests can
/// assert the SDK constructed the expected HTTP request.
class _RecordingDioAdapter implements dio.HttpClientAdapter {
  _RecordingDioAdapter({
    required this.responseBody,
    this.statusCode = 200,
    this.throwError,
  });

  String responseBody;
  int statusCode;
  Object? throwError;

  /// Captures every URL accessed in order.
  final List<String> capturedUrls = <String>[];

  /// Captures every body sent in order (decoded as UTF-8).
  final List<String?> capturedBodies = <String?>[];

  @override
  Future<dio.ResponseBody> fetch(
    dio.RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    capturedUrls.add(options.uri.toString());
    if (requestStream != null) {
      final chunks = <int>[];
      await for (final chunk in requestStream) {
        chunks.addAll(chunk);
      }
      capturedBodies.add(String.fromCharCodes(chunks));
    } else {
      capturedBodies.add(null);
    }
    final error = throwError;
    if (error != null) {
      if (error is dio.DioException) {
        throw dio.DioException(
          requestOptions: options,
          type: error.type,
          error: error.error,
          message: error.message,
          response: error.response,
        );
      }
      throw error;
    }
    return dio.ResponseBody.fromString(
      responseBody,
      statusCode,
      headers: <String, List<String>>{
        'content-type': <String>['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Public factory that constructs a [_RecordingDioAdapter] and an
/// associated [RecordingIndexerClient]. Returned as a record so tests
/// can manipulate the adapter and assert on captured calls.
typedef IndexerHarness = ({
  RecordingIndexerClient client,
  _RecordingDioAdapter adapter,
});

IndexerHarness buildIndexerHarness({
  String responseBody = '{}',
  int statusCode = 200,
  Object? throwError,
}) {
  final adapter = _RecordingDioAdapter(
    responseBody: responseBody,
    statusCode: statusCode,
    throwError: throwError,
  );
  return (client: RecordingIndexerClient(adapter), adapter: adapter);
}

/// Public factory for the relayer harness.
typedef RelayerHarness = ({
  RecordingRelayerClient client,
  _RecordingDioAdapter adapter,
});

RelayerHarness buildRelayerHarness({
  String responseBody = '{"success":true,"hash":"deadbeef","status":"SUCCESS"}',
  int statusCode = 200,
  Object? throwError,
}) {
  final adapter = _RecordingDioAdapter(
    responseBody: responseBody,
    statusCode: statusCode,
    throwError: throwError,
  );
  return (client: RecordingRelayerClient(adapter), adapter: adapter);
}
