// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart' as dio;
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

/// Answers one request. It receives the decoded JSON-RPC request body, which
/// holds the `id` to echo.
typedef RpcAnswer = dio.ResponseBody Function(Map<String, dynamic> request);

/// The name a request is logged under for [key]: `account`, `instance`,
/// `code`, `tag`, or `other` for any other ledger key.
String _ledgerKeyName(XdrLedgerKey key) {
  if (key.discriminant == XdrLedgerEntryType.ACCOUNT) {
    return 'account';
  }
  if (key.discriminant == XdrLedgerEntryType.CONTRACT_CODE) {
    return 'code';
  }
  if (key.discriminant == XdrLedgerEntryType.CONTRACT_DATA) {
    final keyKind = key.contractData?.key.discriminant;
    if (keyKind == XdrSCValType.SCV_LEDGER_KEY_CONTRACT_INSTANCE) {
      return 'instance';
    }
    if (keyKind == XdrSCValType.SCV_EXECUTABLE_TAG) {
      return 'tag';
    }
  }
  return 'other';
}

/// A SorobanServer whose HTTP adapter answers the JSON-RPC requests of one
/// test, logs each answered request by name, and checks each ledger key.
///
/// Every request is logged by name (`account`, `instance`, `code`, `tag`,
/// `simulate`, `send`, `getTx`), and its decoded body is kept in [bodies]. A
/// request with an unexpected ledger key, an unexpected JSON-RPC method, or no
/// configured answer is recorded in [violations] and answered with a JSON-RPC
/// error, so the client returns or throws without a hidden retry. Each test
/// asserts [violations] is empty through [expectNoViolations], because the
/// client may catch the failure. The double reaches no network.
class SacRpcDouble {
  /// Creates a double for the RPC endpoint [rpcUrl], with the expected keys
  /// and the answers of the test.
  SacRpcDouble({
    required this.rpcUrl,
    this.expectedKeys = const {},
    this.answers = const {},
  }) {
    _httpClient.httpClientAdapter = _Adapter(_handle);
    server = SorobanServer(rpcUrl, httpClient: _httpClient);
  }

  /// The endpoint the server is created for.
  final String rpcUrl;

  /// The expected ledger key of each ledger key name.
  final Map<String, XdrLedgerKey> expectedKeys;

  /// The answer to each request name.
  final Map<String, RpcAnswer> answers;

  /// The name of each answered request, in the order the server received it.
  final List<String> log = [];

  /// The decoded body of each request, in the order the server received it.
  final List<Map<String, dynamic>> bodies = [];

  /// Each request that broke the contract of this double: an unexpected
  /// ledger key, an unexpected method, or a request with no answer.
  final List<String> violations = [];

  /// The server to pass as `ClientOptions.server`.
  late final SorobanServer server;

  final dio.Dio _httpClient = dio.Dio();

  /// The HTTP client of [server], for a server subclass that shares this
  /// double's answers.
  dio.Dio get httpClient => _httpClient;

  /// Expects that no request broke the contract of this double.
  void expectNoViolations() {
    expect(violations, isEmpty, reason: 'unexpected requests');
  }

  dio.ResponseBody _handle(dio.RequestOptions options) {
    final request = jsonDecode(options.data as String) as Map<String, dynamic>;
    bodies.add(request);
    final method = request['method'];
    if (method == 'getLedgerEntries') {
      final keys = (request['params'] as Map)['keys'] as List;
      if (keys.length != 1) {
        return _violation(
          request,
          'getLedgerEntries requested ${keys.length} keys, expected 1',
        );
      }
      final requested = XdrLedgerKey.fromBase64EncodedXdrString(
        keys[0] as String,
      );
      final name = _ledgerKeyName(requested);
      final expected = expectedKeys[name];
      if (expected == null ||
          expected.toBase64EncodedXdrString() !=
              requested.toBase64EncodedXdrString()) {
        return _violation(request, 'Unexpected $name ledger key: ${keys[0]}');
      }
      return _answer(name, request);
    }
    if (method == 'simulateTransaction') {
      return _answer('simulate', request);
    }
    if (method == 'sendTransaction') {
      return _answer('send', request);
    }
    if (method == 'getTransaction') {
      return _answer('getTx', request);
    }
    return _violation(request, 'Unexpected RPC method: $method');
  }

  dio.ResponseBody _answer(String name, Map<String, dynamic> request) {
    final answer = answers[name];
    if (answer == null) {
      return _violation(request, 'No answer configured for the $name request');
    }
    log.add(name);
    return answer(request);
  }

  dio.ResponseBody _violation(Map<String, dynamic> request, String message) {
    violations.add(message);
    return jsonRpcError(request['id'], message);
  }
}

class _Adapter implements dio.HttpClientAdapter {
  _Adapter(this._onRequest);

  final dio.ResponseBody Function(dio.RequestOptions) _onRequest;

  @override
  Future<dio.ResponseBody> fetch(
    dio.RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return _onRequest(options);
  }

  @override
  void close({bool force = false}) {}
}

/// A JSON-RPC success response that echoes the request [id].
dio.ResponseBody _jsonRpcResult(Object? id, Map<String, dynamic> result) {
  return dio.ResponseBody.fromString(
    jsonEncode({'jsonrpc': '2.0', 'id': id, 'result': result}),
    200,
    headers: {
      'content-type': [dio.Headers.jsonContentType],
    },
  );
}

/// A JSON-RPC error response that echoes the request [id].
dio.ResponseBody jsonRpcError(Object? id, String message) {
  return dio.ResponseBody.fromString(
    jsonEncode({
      'jsonrpc': '2.0',
      'id': id,
      'error': {'code': -32600, 'message': message},
    }),
    200,
    headers: {
      'content-type': [dio.Headers.jsonContentType],
    },
  );
}

/// An answer that gives [result] for each request, built from the request.
RpcAnswer rpcResult(
  Map<String, dynamic> Function(Map<String, dynamic>) result,
) {
  return (request) => _jsonRpcResult(request['id'], result(request));
}

/// An answer that gives a JSON-RPC error with [message].
RpcAnswer rpcError(String message) {
  return (request) => jsonRpcError(request['id'], message);
}

/// A getLedgerEntries answer that returns [entry] under the requested key, or
/// no entry when [entry] is null.
RpcAnswer ledgerEntry(XdrLedgerEntryData? entry) {
  return (request) {
    final keys = (request['params'] as Map)['keys'] as List;
    final entries = entry == null
        ? <Map<String, dynamic>>[]
        : [
            {
              'key': keys[0],
              'xdr': entry.toBase64EncodedXdrString(),
              'lastModifiedLedgerSeq': 99999,
            },
          ];
    return _jsonRpcResult(request['id'], {
      'entries': entries,
      'latestLedger': 100000,
    });
  };
}

/// The ledger key of the account of [keyPair].
XdrLedgerKey accountLedgerKey(KeyPair keyPair) {
  final key = XdrLedgerKey(XdrLedgerEntryType.ACCOUNT);
  key.account = XdrLedgerKeyAccount(XdrAccountID(keyPair.xdrPublicKey));
  return key;
}

/// The ledger key of the instance of the contract [contractId] (`C...`).
XdrLedgerKey instanceLedgerKey(String contractId) {
  final key = XdrLedgerKey(XdrLedgerEntryType.CONTRACT_DATA);
  key.contractData = XdrLedgerKeyContractData(
    Address.forContractId(contractId).toXdr(),
    XdrSCVal.forLedgerKeyContractInstance(),
    XdrContractDataDurability.PERSISTENT,
  );
  return key;
}

/// The ledger key of the wasm code with the hash [wasmHash].
XdrLedgerKey codeLedgerKey(Uint8List wasmHash) {
  final key = XdrLedgerKey(XdrLedgerEntryType.CONTRACT_CODE);
  key.contractCode = XdrLedgerKeyContractCode(XdrHash(wasmHash));
  return key;
}

/// The ledger key of the executable tag [tag] of the contract [ownerContractId]
/// (`C...`), which an external reference resolves through.
XdrLedgerKey tagLedgerKey(String ownerContractId, Uint8List tag) {
  final key = XdrLedgerKey(XdrLedgerEntryType.CONTRACT_DATA);
  key.contractData = XdrLedgerKeyContractData(
    Address.forContractId(ownerContractId).toXdr(),
    XdrSCVal.forExecutableTagBytes(tag),
    XdrContractDataDurability.PERSISTENT,
  );
  return key;
}

/// The entry of an account with the sequence number 1000.
XdrLedgerEntryData accountEntry(KeyPair keyPair) {
  final account = XdrAccountEntry(
    XdrAccountID(keyPair.xdrPublicKey),
    XdrInt64(BigInt.zero),
    XdrSequenceNumber(BigInt.from(1000)),
    XdrUint32(0),
    null,
    XdrUint32(0),
    XdrString32(''),
    XdrThresholds(Uint8List.fromList([1, 0, 0, 0])),
    [],
    XdrAccountEntryExt(0),
  );
  final entryData = XdrLedgerEntryData(XdrLedgerEntryType.ACCOUNT);
  entryData.account = account;
  return entryData;
}

/// A contract data entry of [contractId] under [key], holding [value].
XdrLedgerEntryData contractDataEntry(
  String contractId,
  XdrSCVal key,
  XdrSCVal value,
) {
  final entryData = XdrLedgerEntryData(XdrLedgerEntryType.CONTRACT_DATA);
  entryData.contractData = XdrContractDataEntry(
    XdrExtensionPoint(0),
    Address.forContractId(contractId).toXdr(),
    key,
    XdrContractDataDurability.PERSISTENT,
    value,
  );
  return entryData;
}

/// The instance entry of the contract [contractId] with [executable].
XdrLedgerEntryData _contractInstanceEntry(
  String contractId,
  XdrContractExecutable executable,
) {
  final instance = XdrSCContractInstance(executable, null);
  return contractDataEntry(
    contractId,
    XdrSCVal.forLedgerKeyContractInstance(),
    XdrSCVal.forContractInstance(instance),
  );
}

/// The instance entry of a Stellar Asset Contract with the id [contractId].
XdrLedgerEntryData sacInstanceEntry(String contractId) {
  return _contractInstanceEntry(contractId, XdrContractExecutable.forAsset());
}

/// The instance entry of a contract that runs the wasm with [wasmHash].
XdrLedgerEntryData wasmInstanceEntry(String contractId, Uint8List wasmHash) {
  return _contractInstanceEntry(
    contractId,
    XdrContractExecutable.forWasm(wasmHash),
  );
}

/// The instance entry of a contract whose executable is the external
/// reference [tag] of the owner [ownerContractId].
XdrLedgerEntryData externalRefInstanceEntry(
  String contractId,
  String ownerContractId,
  Uint8List tag,
) {
  return _contractInstanceEntry(
    contractId,
    XdrContractExecutable.forExternalRefBytes(
      Address.forContractId(ownerContractId).toXdr(),
      tag,
    ),
  );
}

/// The code entry of the wasm with [wasmHash] and the bytes [code].
XdrLedgerEntryData contractCodeEntry(Uint8List wasmHash, Uint8List code) {
  final entryData = XdrLedgerEntryData(XdrLedgerEntryType.CONTRACT_CODE);
  entryData.contractCode = XdrContractCodeEntry(
    XdrContractCodeEntryExt(0),
    XdrHash(wasmHash),
    code,
  );
  return entryData;
}

/// The executable tag entry of the owner [ownerContractId] for [tag], holding
/// the 32-byte [wasmHash] as the value an external reference resolves to.
XdrLedgerEntryData executableTagEntry(
  String ownerContractId,
  Uint8List tag,
  Uint8List wasmHash,
) {
  return contractDataEntry(
    ownerContractId,
    XdrSCVal.forExecutableTagBytes(tag),
    XdrSCVal.forBytes(wasmHash),
  );
}
