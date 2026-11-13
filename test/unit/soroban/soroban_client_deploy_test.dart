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

import 'simulation_contract_error_fixtures.dart';

dio.ResponseBody emptyLedgerEntriesResponse(Map<String, dynamic> requestBody) {
  return jsonRpcResponse(requestBody['id'], {
    'entries': [],
    'latestLedger': 100000,
  });
}

/// A SUCCESS getTransaction result whose meta returns the created contract
/// address, as required by [GetTransactionResponse.getCreatedContractId].
Map<String, dynamic> deploySuccessResult(Uint8List createdContractIdBytes) {
  final createdAddress = XdrSCAddress(
    XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT,
  );
  createdAddress.contractId = XdrHash(createdContractIdBytes);
  final sorobanMeta = XdrSorobanTransactionMeta(
    XdrSorobanTransactionMetaExt(0),
    [],
    XdrSCVal.forAddress(createdAddress),
    [],
  );
  final meta = XdrTransactionMeta(3);
  meta.v3 = XdrTransactionMetaV3(
    XdrExtensionPoint(0),
    XdrLedgerEntryChanges([]),
    [],
    XdrLedgerEntryChanges([]),
    sorobanMeta,
  );
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
  final helloWasm = File(
    'test/wasm/soroban_hello_world_contract.wasm',
  ).readAsBytesSync();

  /// Serves the full deploy flow. Ledger-entry requests are dispatched on the
  /// requested key type; the wasm code entry answer per request is taken from
  /// [codeEntryAnswers] in order (its last element repeats), so tests can
  /// serve a missing or unparseable entry to the pre-deploy load and the real
  /// one to the fallback. Every request is appended to [requestLog] as
  /// 'code', 'account', 'contractData', 'simulate', 'send' or 'getTx'; the
  /// submitted envelope is recorded into [capturedEnvelopes] when given.
  SorobanServer deployFlowMockServer(
    KeyPair keyPair,
    List<Uint8List?> codeEntryAnswers,
    List<String> requestLog, {
    List<String>? capturedEnvelopes,
    Map<String, dynamic>? simulationFailure,
  }) {
    final txData = transactionDataWithWrites(keyPair);
    var codeRequests = 0;
    final mockDio = dio.Dio();
    mockDio.httpClientAdapter = SimulationDioAdapter((options) {
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
              requestBody,
              contractCodeEntry(wasmHashBytes, answer),
            );
          }
          if (key.discriminant == XdrLedgerEntryType.CONTRACT_DATA) {
            requestLog.add('contractData');
            return ledgerEntryResponse(
              requestBody,
              contractInstanceEntry(createdContractIdBytes, wasmHashBytes),
            );
          }
          requestLog.add('account');
          return ledgerEntryResponse(requestBody, accountEntry(keyPair));
        case 'simulateTransaction':
          if (simulationFailure != null)
            return dio.ResponseBody.fromString(
              jsonEncode(simulationFailure),
              200,
              headers: {
                'content-type': [dio.Headers.jsonContentType],
              },
            );
          requestLog.add('simulate');
          return jsonRpcResponse(requestBody['id'], {
            'minResourceFee': '100000',
            'transactionData': txData.toBase64EncodedXdrString(),
            'results': [
              {
                'auth': [],
                'xdr': XdrSCVal.forU32(42).toBase64EncodedXdrString(),
              },
            ],
            'latestLedger': 100000,
          });
        case 'sendTransaction':
          requestLog.add('send');
          capturedEnvelopes?.add(
            requestBody['params']['transaction'] as String,
          );
          return jsonRpcResponse(requestBody['id'], {
            'status': 'PENDING',
            'hash': txHash,
            'latestLedger': 100000,
            'latestLedgerCloseTime': '1234567890',
          });
        case 'getTransaction':
          requestLog.add('getTx');
          return jsonRpcResponse(
            requestBody['id'],
            deploySuccessResult(createdContractIdBytes),
          );
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

  for (final name in ['case-a', 'case-a-rpc30.0.0']) {
    test('deploy $name retains constructor diagnostics', () async {
      final raw =
          jsonDecode(
                File(
                  'test/fixtures/simulation_contract_error/$name-response.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final c = capturedCase(name, SimulateTransactionResponse.fromJson(raw));
      final key = KeyPair.random();
      final log = <String>[];
      final server = deployFlowMockServer(
        key,
        [helloWasm],
        log,
        simulationFailure: raw,
      );
      expectSorobanFailure(
        await caught(
          () => SorobanClient.deploy(deployRequest: deployRequest(key, server)),
        ),
        c,
      );
      expect(log, isNot(contains('send')));
    });
  }

  group('SorobanClient.deploy spec loading', () {
    test('loads the spec from the wasm code entry before submitting', () async {
      final keyPair = KeyPair.random();
      final requestLog = <String>[];
      final server = deployFlowMockServer(keyPair, [helloWasm], requestLog);

      final client = await SorobanClient.deploy(
        deployRequest: deployRequest(keyPair, server),
      );

      expect(client.getContractId(), createdContractId);
      expect(client.getMethodNames(), contains('hello'));
      // The spec came from the code entry requested before submission; the
      // contract instance is never read.
      expect(requestLog, isNot(contains('contractData')));
      expect(requestLog.indexOf('code'), lessThan(requestLog.indexOf('send')));
    });

    test(
      'falls back to loading by contract id when the code entry is missing',
      () async {
        final keyPair = KeyPair.random();
        final requestLog = <String>[];
        final server = deployFlowMockServer(keyPair, [
          null,
          helloWasm,
        ], requestLog);

        final client = await SorobanClient.deploy(
          deployRequest: deployRequest(keyPair, server),
        );

        expect(client.getContractId(), createdContractId);
        expect(client.getMethodNames(), contains('hello'));
        expect(requestLog, contains('contractData'));
      },
    );

    test(
      'falls back to loading by contract id when the code has no parseable spec',
      () async {
        final keyPair = KeyPair.random();
        final requestLog = <String>[];
        final unparseable = Uint8List.fromList([1, 2, 3, 4]);
        final server = deployFlowMockServer(keyPair, [
          unparseable,
          helloWasm,
        ], requestLog);

        final client = await SorobanClient.deploy(
          deployRequest: deployRequest(keyPair, server),
        );

        expect(client.getContractId(), createdContractId);
        expect(client.getMethodNames(), contains('hello'));
        expect(requestLog, contains('contractData'));
      },
    );

    test('submits the V2 create-contract host function with an empty '
        'constructor vector', () async {
      // The deploy always takes the with-constructor (V2) form; absent
      // constructor args ride along as an empty vector.
      final keyPair = KeyPair.random();
      final requestLog = <String>[];
      final capturedEnvelopes = <String>[];
      final server = deployFlowMockServer(
        keyPair,
        [helloWasm],
        requestLog,
        capturedEnvelopes: capturedEnvelopes,
      );

      final client = await SorobanClient.deploy(
        deployRequest: deployRequest(keyPair, server),
      );

      expect(client.getContractId(), createdContractId);
      expect(capturedEnvelopes, hasLength(1));
      final tx = AbstractTransaction.fromEnvelopeXdrString(
        capturedEnvelopes[0],
      );
      expect(tx, isA<Transaction>());
      final op = (tx as Transaction).operations[0];
      expect(op, isA<InvokeHostFunctionOperation>());
      final hostFunction = (op as InvokeHostFunctionOperation).function;
      expect(hostFunction, isA<CreateContractWithConstructorHostFunction>());
      final typed = hostFunction as CreateContractWithConstructorHostFunction;
      expect(typed.wasmId, wasmHash);
      expect(typed.constructorArgs, isEmpty);
    });
  });
}
