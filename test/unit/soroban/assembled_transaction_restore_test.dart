// Tests for AssembledTransaction automatic footprint restore and for
// injecting a preconfigured SorobanServer via ClientOptions.
//
// All RPC calls are served by a mocked Dio adapter; no network access.

import 'dart:convert';
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

dio.ResponseBody accountEntryResponse(
    Map<String, dynamic> requestBody, KeyPair keyPair, BigInt sequence) {
  final accountEntry = XdrAccountEntry(
    XdrAccountID(keyPair.xdrPublicKey),
    XdrInt64(BigInt.zero),
    XdrSequenceNumber(sequence),
    XdrUint32(0),
    null,
    XdrUint32(0),
    XdrString32(''),
    XdrThresholds(Uint8List.fromList([1, 0, 0, 0])),
    [],
    XdrAccountEntryExt(0),
  );
  final ledgerEntryData = XdrLedgerEntryData(XdrLedgerEntryType.ACCOUNT);
  ledgerEntryData.account = accountEntry;
  return jsonRpcResponse(requestBody['id'], {
    'entries': [
      {
        'key': (requestBody['params']['keys'] as List)[0],
        'xdr': ledgerEntryData.toBase64EncodedXdrString(),
        'lastModifiedLedgerSeq': 99999,
      }
    ],
    'latestLedger': 100000,
  });
}

/// Transaction data with a non-empty read-write footprint, so that
/// transactions simulated against it are not considered read calls.
XdrSorobanTransactionData transactionDataWithWrites(KeyPair keyPair) {
  final key = XdrLedgerKey(XdrLedgerEntryType.ACCOUNT);
  key.account = XdrLedgerKeyAccount(XdrAccountID(keyPair.xdrPublicKey));
  final resources = XdrSorobanResources(
      XdrLedgerFootprint([], [key]), XdrUint32(0), XdrUint32(0), XdrUint32(0));
  return XdrSorobanTransactionData(
      XdrSorobanTransactionDataExt(0), resources, XdrInt64(BigInt.zero));
}

Map<String, dynamic> successfulSimulation(XdrSorobanTransactionData txData) {
  return {
    'minResourceFee': '100000',
    'transactionData': txData.toBase64EncodedXdrString(),
    'results': [
      {
        'auth': [],
        'xdr': XdrSCVal.forU32(42).toBase64EncodedXdrString(),
      }
    ],
    'latestLedger': 100000,
  };
}

void main() {
  const rpcUrl = 'https://soroban-testnet.stellar.org';
  const txHash =
      'a7d8f6c5e9b1a3d2f4c8e7b9a5c3d1f2e8b6c4d7a9e1f3b5c2d8e6a4b7c9d1e2';
  final contractId = StrKey.encodeContractId(Uint8List(32));

  AssembledTransactionOptions buildOptions(
      KeyPair keyPair, SorobanServer server, MethodOptions methodOptions) {
    final clientOptions = ClientOptions(
      sourceAccountKeyPair: keyPair,
      contractId: contractId,
      network: Network.TESTNET,
      rpcUrl: rpcUrl,
      server: server,
    );
    return AssembledTransactionOptions(
      clientOptions: clientOptions,
      methodOptions: methodOptions,
      method: 'increment',
    );
  }

  /// Serves the full automatic-restore flow: account fetches with an
  /// increasing sequence number per fetch (1000, 2000, ...), an initial
  /// simulation that requires restore, the restore transaction submission
  /// (with the outcome selected by [restoreSucceeds]), and successful
  /// follow-up simulations. Every simulated envelope is appended to
  /// [simulateEnvelopes] when provided.
  SorobanServer restoreFlowMockServer(
    KeyPair keyPair,
    XdrSorobanTransactionData txData, {
    bool restoreSucceeds = true,
    List<String>? simulateEnvelopes,
  }) {
    var ledgerEntriesCalls = 0;
    var simulateCalls = 0;

    final mockDio = dio.Dio();
    mockDio.httpClientAdapter = MockDioAdapter((options) {
      final requestBody = jsonDecode(options.data);
      switch (requestBody['method']) {
        case 'getLedgerEntries':
          // A fresh sequence number per fetch, emulating the sequence bump
          // consumed by the restore transaction: 1000, 2000, 3000.
          ledgerEntriesCalls++;
          return accountEntryResponse(
              requestBody, keyPair, BigInt.from(1000 * ledgerEntriesCalls));
        case 'simulateTransaction':
          simulateCalls++;
          simulateEnvelopes?.add(requestBody['params']['transaction']);
          if (simulateCalls == 1) {
            // The initial simulation of the invocation: state is archived.
            return jsonRpcResponse(requestBody['id'], {
              'restorePreamble': {
                'transactionData': txData.toBase64EncodedXdrString(),
                'minResourceFee': '50000',
              },
              'latestLedger': 100000,
            });
          }
          // The restore transaction simulation and the re-simulation of
          // the rebuilt invocation both succeed.
          return jsonRpcResponse(
              requestBody['id'], successfulSimulation(txData));
        case 'sendTransaction':
          return jsonRpcResponse(requestBody['id'], {
            'status': 'PENDING',
            'hash': txHash,
            'latestLedger': 100000,
            'latestLedgerCloseTime': '1234567890',
          });
        case 'getTransaction':
          return jsonRpcResponse(requestBody['id'], {
            'status': restoreSucceeds ? 'SUCCESS' : 'FAILED',
            'ledger': 99999,
            'createdAt': '1234567890',
            'applicationOrder': 1,
            'feeBump': false,
          });
        default:
          fail('Unexpected RPC method: ${requestBody['method']}');
      }
    });
    return SorobanServer(rpcUrl, httpClient: mockDio);
  }

  group('ClientOptions.server injection', () {
    test('AssembledTransaction uses the injected server for RPC calls',
        () async {
      final keyPair = KeyPair.random();
      var ledgerEntriesCalls = 0;

      final mockDio = dio.Dio();
      mockDio.httpClientAdapter = MockDioAdapter((options) {
        final requestBody = jsonDecode(options.data);
        expect(requestBody['method'], 'getLedgerEntries');
        ledgerEntriesCalls++;
        return accountEntryResponse(requestBody, keyPair, BigInt.from(1000));
      });
      final server = SorobanServer(rpcUrl, httpClient: mockDio);

      final tx = await AssembledTransaction.build(
          options:
              buildOptions(keyPair, server, MethodOptions(simulate: false)));

      expect(identical(tx.server, server), isTrue);
      expect(ledgerEntriesCalls, 1);
    });
  });

  group('automatic footprint restore', () {
    test('succeeds and re-simulates the rebuilt transaction', () async {
      final keyPair = KeyPair.random();
      final txData = transactionDataWithWrites(keyPair);
      final simulateEnvelopes = <String>[];
      final server = restoreFlowMockServer(keyPair, txData,
          simulateEnvelopes: simulateEnvelopes);

      final tx = await AssembledTransaction.build(
          options: buildOptions(
              keyPair, server, MethodOptions(fee: 250, restore: true)));

      // The transaction is assembled from the final successful simulation.
      expect(tx.tx, isNotNull);
      expect(tx.simulationResponse!.restorePreamble, isNull);
      expect(tx.getSimulationData().returnedValue.u32!.uint32, 42);

      // Simulations: initial (restore needed), restore transaction, rebuilt
      // invocation.
      expect(simulateEnvelopes.length, 3);

      final initial =
          AbstractTransaction.fromEnvelopeXdrString(simulateEnvelopes[0])
              as Transaction;
      final restore =
          AbstractTransaction.fromEnvelopeXdrString(simulateEnvelopes[1])
              as Transaction;
      final rebuilt =
          AbstractTransaction.fromEnvelopeXdrString(simulateEnvelopes[2])
              as Transaction;

      // The restore transaction contains a RestoreFootprint operation.
      expect(restore.operations.first, isA<RestoreFootprintOperation>());

      // The re-simulation uses the rebuilt transaction with the bumped
      // sequence number, not the stale pre-restore transaction.
      expect(initial.sequenceNumber, BigInt.from(1001));
      expect(rebuilt.sequenceNumber, BigInt.from(3001));

      // The rebuilt transaction keeps the configured fee and the original
      // invoke-contract operation.
      expect(rebuilt.fee, 250);
      final rebuiltOp = rebuilt.operations.first;
      expect(rebuiltOp, isA<InvokeHostFunctionOperation>());
      expect((rebuiltOp as InvokeHostFunctionOperation).function,
          isA<InvokeContractHostFunction>());
    });

    test('reuses the original operation from buildWithOp when rebuilding',
        () async {
      final keyPair = KeyPair.random();
      final txData = transactionDataWithWrites(keyPair);
      final simulateEnvelopes = <String>[];
      final server = restoreFlowMockServer(keyPair, txData,
          simulateEnvelopes: simulateEnvelopes);

      final uploadFunction =
          UploadContractWasmHostFunction(Uint8List.fromList([0, 1, 2, 3]));
      final operation = InvokeHostFuncOpBuilder(uploadFunction).build();

      final tx = await AssembledTransaction.buildWithOp(
          operation: operation,
          options: buildOptions(keyPair, server, MethodOptions(restore: true)));

      expect(tx.tx, isNotNull);
      expect(simulateEnvelopes.length, 3);

      // The rebuilt transaction carries the original upload operation, not a
      // reconstructed invoke-contract operation.
      final rebuilt =
          AbstractTransaction.fromEnvelopeXdrString(simulateEnvelopes[2])
              as Transaction;
      final rebuiltOp = rebuilt.operations.first;
      expect(rebuiltOp, isA<InvokeHostFunctionOperation>());
      expect((rebuiltOp as InvokeHostFunctionOperation).function,
          isA<UploadContractWasmHostFunction>());
    });

    test('throws when the restore transaction fails', () async {
      final keyPair = KeyPair.random();
      final txData = transactionDataWithWrites(keyPair);
      final server =
          restoreFlowMockServer(keyPair, txData, restoreSucceeds: false);

      await expectLater(
        AssembledTransaction.build(
            options:
                buildOptions(keyPair, server, MethodOptions(restore: true))),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Automatic restore failed'))),
      );
    });

    test('throws when restore is needed but the keypair has no private key',
        () async {
      final keyPair = KeyPair.random();
      final publicOnly = KeyPair.fromAccountId(keyPair.accountId);
      final txData = transactionDataWithWrites(keyPair);

      final mockDio = dio.Dio();
      mockDio.httpClientAdapter = MockDioAdapter((options) {
        final requestBody = jsonDecode(options.data);
        switch (requestBody['method']) {
          case 'getLedgerEntries':
            return accountEntryResponse(
                requestBody, keyPair, BigInt.from(1000));
          case 'simulateTransaction':
            return jsonRpcResponse(requestBody['id'], {
              'restorePreamble': {
                'transactionData': txData.toBase64EncodedXdrString(),
                'minResourceFee': '50000',
              },
              'latestLedger': 100000,
            });
          default:
            fail('Unexpected RPC method: ${requestBody['method']}');
        }
      });
      final server = SorobanServer(rpcUrl, httpClient: mockDio);

      await expectLater(
        AssembledTransaction.build(
            options:
                buildOptions(publicOnly, server, MethodOptions(restore: true))),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('no private key'))),
      );
    });
  });
}
