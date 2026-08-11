// Tests for SorobanClient.deploy() contract-spec loading.
//
// The spec of the returned client is loaded from the wasm code entry before
// the deploy transaction is submitted, because the code entry is already
// settled while the freshly created contract instance may not be visible to
// the RPC yet. Loading by contract id remains the fallback when the code
// entry cannot be read or parsed up front.
//
// All RPC calls are served by a mocked Dio adapter; no network access.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart' as dio;
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

class MockDioAdapter implements dio.HttpClientAdapter {
  final Function(dio.RequestOptions) onRequest;

  MockDioAdapter(this.onRequest);

  @override
  Future<dio.ResponseBody> fetch(
    dio.RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return onRequest(options);
  }

  @override
  void close({bool force = false}) {}
}

dio.ResponseBody jsonRpcResponse(dynamic id, Map<String, dynamic> result) {
  return dio.ResponseBody.fromString(
    jsonEncode({'jsonrpc': '2.0', 'id': id, 'result': result}),
    200,
    headers: {
      'content-type': [dio.Headers.jsonContentType]
    },
  );
}

dio.ResponseBody ledgerEntryResponse(
    Map<String, dynamic> requestBody, XdrLedgerEntryData entryData) {
  return jsonRpcResponse(requestBody['id'], {
    'entries': [
      {
        'key': (requestBody['params']['keys'] as List)[0],
        'xdr': entryData.toBase64EncodedXdrString(),
        'lastModifiedLedgerSeq': 99999,
      }
    ],
    'latestLedger': 100000,
  });
}

dio.ResponseBody emptyLedgerEntriesResponse(Map<String, dynamic> requestBody) {
  return jsonRpcResponse(requestBody['id'], {
    'entries': [],
    'latestLedger': 100000,
  });
}

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

XdrLedgerEntryData contractCodeEntry(Uint8List wasmHashBytes, Uint8List code) {
  final entryData = XdrLedgerEntryData(XdrLedgerEntryType.CONTRACT_CODE);
  entryData.contractCode = XdrContractCodeEntry(
      XdrContractCodeEntryExt(0), XdrHash(wasmHashBytes), code);
  return entryData;
}

XdrLedgerEntryData contractInstanceEntry(
    Uint8List contractIdBytes, Uint8List wasmHashBytes) {
  final executable =
      XdrContractExecutable(XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM);
  executable.wasmHash = XdrHash(wasmHashBytes);
  final instance = XdrSCContractInstance(executable, null);
  final contractAddress = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT);
  contractAddress.contractId = XdrHash(contractIdBytes);
  final entryData = XdrLedgerEntryData(XdrLedgerEntryType.CONTRACT_DATA);
  entryData.contractData = XdrContractDataEntry(
    XdrExtensionPoint(0),
    contractAddress,
    XdrSCVal.forLedgerKeyContractInstance(),
    XdrContractDataDurability.PERSISTENT,
    XdrSCVal.forContractInstance(instance),
  );
  return entryData;
}

/// Transaction data with a non-empty read-write footprint, so that the
/// deploy transaction is not considered a read call.
XdrSorobanTransactionData transactionDataWithWrites(KeyPair keyPair) {
  final key = XdrLedgerKey(XdrLedgerEntryType.ACCOUNT);
  key.account = XdrLedgerKeyAccount(XdrAccountID(keyPair.xdrPublicKey));
  final resources = XdrSorobanResources(
      XdrLedgerFootprint([], [key]), XdrUint32(0), XdrUint32(0), XdrUint32(0));
  return XdrSorobanTransactionData(
      XdrSorobanTransactionDataExt(0), resources, XdrInt64(BigInt.zero));
}

/// A SUCCESS getTransaction result whose meta returns the created contract
/// address, as required by [GetTransactionResponse.getCreatedContractId].
Map<String, dynamic> deploySuccessResult(Uint8List createdContractIdBytes) {
  final createdAddress = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT);
  createdAddress.contractId = XdrHash(createdContractIdBytes);
  final sorobanMeta = XdrSorobanTransactionMeta(
      XdrSorobanTransactionMetaExt(0),
      [],
      XdrSCVal.forAddress(createdAddress),
      []);
  final meta = XdrTransactionMeta(3);
  meta.v3 = XdrTransactionMetaV3(XdrExtensionPoint(0),
      XdrLedgerEntryChanges([]), [], XdrLedgerEntryChanges([]), sorobanMeta);
  return {
    'status': 'SUCCESS',
    'ledger': 99999,
    'createdAt': '1234567890',
    'applicationOrder': 1,
    'feeBump': false,
    'resultMetaXdr': meta.toBase64EncodedXdrString(),
  };
}

void main() {
  const rpcUrl = 'https://soroban-testnet.stellar.org';
  const txHash =
      'a7d8f6c5e9b1a3d2f4c8e7b9a5c3d1f2e8b6c4d7a9e1f3b5c2d8e6a4b7c9d1e2';

  final wasmHashBytes = Uint8List(32);
  final wasmHash = Util.bytesToHex(wasmHashBytes);
  final createdContractIdBytes = Uint8List(32);
  final createdContractId = StrKey.encodeContractId(createdContractIdBytes);
  final helloWasm =
      File('test/wasm/soroban_hello_world_contract.wasm').readAsBytesSync();

  /// Serves the full deploy flow. Ledger-entry requests are dispatched on the
  /// requested key type; the wasm code entry answer per request is taken from
  /// [codeEntryAnswers] in order (its last element repeats), so tests can
  /// serve a missing or unparseable entry to the pre-deploy load and the real
  /// one to the fallback. Every request is appended to [requestLog] as
  /// 'code', 'account', 'contractData', 'simulate', 'send' or 'getTx'.
  SorobanServer deployFlowMockServer(
    KeyPair keyPair,
    List<Uint8List?> codeEntryAnswers,
    List<String> requestLog,
  ) {
    final txData = transactionDataWithWrites(keyPair);
    var codeRequests = 0;
    final mockDio = dio.Dio();
    mockDio.httpClientAdapter = MockDioAdapter((options) {
      final requestBody = jsonDecode(options.data);
      switch (requestBody['method']) {
        case 'getLedgerEntries':
          final keyBase64 =
              (requestBody['params']['keys'] as List)[0] as String;
          final key = XdrLedgerKey.fromBase64EncodedXdrString(keyBase64);
          if (key.discriminant == XdrLedgerEntryType.CONTRACT_CODE) {
            requestLog.add('code');
            final answer = codeRequests < codeEntryAnswers.length
                ? codeEntryAnswers[codeRequests]
                : codeEntryAnswers.last;
            codeRequests++;
            if (answer == null) {
              return emptyLedgerEntriesResponse(requestBody);
            }
            return ledgerEntryResponse(
                requestBody, contractCodeEntry(wasmHashBytes, answer));
          }
          if (key.discriminant == XdrLedgerEntryType.CONTRACT_DATA) {
            requestLog.add('contractData');
            return ledgerEntryResponse(requestBody,
                contractInstanceEntry(createdContractIdBytes, wasmHashBytes));
          }
          requestLog.add('account');
          return ledgerEntryResponse(requestBody, accountEntry(keyPair));
        case 'simulateTransaction':
          requestLog.add('simulate');
          return jsonRpcResponse(requestBody['id'], {
            'minResourceFee': '100000',
            'transactionData': txData.toBase64EncodedXdrString(),
            'results': [
              {
                'auth': [],
                'xdr': XdrSCVal.forU32(42).toBase64EncodedXdrString(),
              }
            ],
            'latestLedger': 100000,
          });
        case 'sendTransaction':
          requestLog.add('send');
          return jsonRpcResponse(requestBody['id'], {
            'status': 'PENDING',
            'hash': txHash,
            'latestLedger': 100000,
            'latestLedgerCloseTime': '1234567890',
          });
        case 'getTransaction':
          requestLog.add('getTx');
          return jsonRpcResponse(
              requestBody['id'], deploySuccessResult(createdContractIdBytes));
        default:
          fail('Unexpected RPC method: ${requestBody['method']}');
      }
    });
    return SorobanServer(rpcUrl, httpClient: mockDio);
  }

  DeployRequest deployRequest(KeyPair keyPair, SorobanServer server) {
    return DeployRequest(
      sourceAccountKeyPair: keyPair,
      network: Network.TESTNET,
      rpcUrl: rpcUrl,
      wasmHash: wasmHash,
      server: server,
    );
  }

  group('SorobanClient.deploy spec loading', () {
    test('loads the spec from the wasm code entry before submitting',
        () async {
      final keyPair = KeyPair.random();
      final requestLog = <String>[];
      final server = deployFlowMockServer(keyPair, [helloWasm], requestLog);

      final client = await SorobanClient.deploy(
          deployRequest: deployRequest(keyPair, server));

      expect(client.getContractId(), createdContractId);
      expect(client.getMethodNames(), contains('hello'));
      // The spec came from the code entry requested before submission; the
      // contract instance is never read.
      expect(requestLog, isNot(contains('contractData')));
      expect(requestLog.indexOf('code'), lessThan(requestLog.indexOf('send')));
    });

    test('falls back to loading by contract id when the code entry is missing',
        () async {
      final keyPair = KeyPair.random();
      final requestLog = <String>[];
      final server =
          deployFlowMockServer(keyPair, [null, helloWasm], requestLog);

      final client = await SorobanClient.deploy(
          deployRequest: deployRequest(keyPair, server));

      expect(client.getContractId(), createdContractId);
      expect(client.getMethodNames(), contains('hello'));
      expect(requestLog, contains('contractData'));
    });

    test('falls back to loading by contract id when the code has no parseable spec',
        () async {
      final keyPair = KeyPair.random();
      final requestLog = <String>[];
      final unparseable = Uint8List.fromList([1, 2, 3, 4]);
      final server =
          deployFlowMockServer(keyPair, [unparseable, helloWasm], requestLog);

      final client = await SorobanClient.deploy(
          deployRequest: deployRequest(keyPair, server));

      expect(client.getContractId(), createdContractId);
      expect(client.getMethodNames(), contains('hello'));
      expect(requestLog, contains('contractData'));
    });
  });
}
