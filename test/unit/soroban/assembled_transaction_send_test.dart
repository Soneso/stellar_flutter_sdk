// Tests for AssembledTransaction.send() submission-status handling and for
// the time bounds set on transactions built by AssembledTransaction.
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
      KeyPair keyPair, SorobanServer server) {
    final clientOptions = ClientOptions(
      sourceAccountKeyPair: keyPair,
      contractId: contractId,
      network: Network.TESTNET,
      rpcUrl: rpcUrl,
      server: server,
    );
    return AssembledTransactionOptions(
      clientOptions: clientOptions,
      methodOptions: MethodOptions(),
      method: 'increment',
    );
  }

  /// Serves a build-sign-send flow whose sendTransaction answer is
  /// [sendResult]. Counts getTransaction polls into [getTransactionCalls]
  /// and captures every simulated envelope into [simulateEnvelopes].
  SorobanServer sendFlowMockServer(
    KeyPair keyPair,
    Map<String, dynamic> sendResult, {
    List<int>? getTransactionCalls,
    List<String>? simulateEnvelopes,
  }) {
    final txData = transactionDataWithWrites(keyPair);
    final mockDio = dio.Dio();
    mockDio.httpClientAdapter = MockDioAdapter((options) {
      final requestBody = jsonDecode(options.data);
      switch (requestBody['method']) {
        case 'getLedgerEntries':
          return accountEntryResponse(requestBody, keyPair, BigInt.from(1000));
        case 'simulateTransaction':
          simulateEnvelopes?.add(requestBody['params']['transaction']);
          return jsonRpcResponse(
              requestBody['id'], successfulSimulation(txData));
        case 'sendTransaction':
          return jsonRpcResponse(requestBody['id'], sendResult);
        case 'getTransaction':
          getTransactionCalls?.add(1);
          return jsonRpcResponse(requestBody['id'], {
            'status': 'SUCCESS',
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

  Future<AssembledTransaction> buildSignedTx(
      KeyPair keyPair, SorobanServer server) async {
    final tx =
        await AssembledTransaction.build(options: buildOptions(keyPair, server));
    tx.sign(force: true);
    return tx;
  }

  group('send() submission-status handling', () {
    test('PENDING is polled to the final transaction response', () async {
      final keyPair = KeyPair.random();
      final getTransactionCalls = <int>[];
      final server = sendFlowMockServer(
          keyPair,
          {
            'status': 'PENDING',
            'hash': txHash,
            'latestLedger': 100000,
            'latestLedgerCloseTime': '1234567890',
          },
          getTransactionCalls: getTransactionCalls);

      final tx = await buildSignedTx(keyPair, server);
      final response = await tx.send();

      expect(response.status, GetTransactionResponse.STATUS_SUCCESS);
      expect(getTransactionCalls, isNotEmpty);
    });

    test('DUPLICATE is polled to the final transaction response', () async {
      final keyPair = KeyPair.random();
      final getTransactionCalls = <int>[];
      final server = sendFlowMockServer(
          keyPair,
          {
            'status': 'DUPLICATE',
            'hash': txHash,
            'latestLedger': 100000,
            'latestLedgerCloseTime': '1234567890',
          },
          getTransactionCalls: getTransactionCalls);

      final tx = await buildSignedTx(keyPair, server);
      final response = await tx.send();

      expect(response.status, GetTransactionResponse.STATUS_SUCCESS);
      expect(getTransactionCalls, isNotEmpty);
    });

    test('TRY_AGAIN_LATER throws without polling', () async {
      final keyPair = KeyPair.random();
      final getTransactionCalls = <int>[];
      final server = sendFlowMockServer(
          keyPair,
          {
            'status': 'TRY_AGAIN_LATER',
            'hash': txHash,
            'latestLedger': 100000,
            'latestLedgerCloseTime': '1234567890',
          },
          getTransactionCalls: getTransactionCalls);

      final tx = await buildSignedTx(keyPair, server);

      await expectLater(
        tx.send(),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Send transaction failed with status: TRY_AGAIN_LATER'))),
      );
      expect(getTransactionCalls, isEmpty);
    });

    test('ERROR throws with the error result xdr and diagnostic events',
        () async {
      final keyPair = KeyPair.random();
      final getTransactionCalls = <int>[];
      // A TransactionResult with code txBAD_SEQ.
      const errorResult = 'AAAAAAAAAGT////7AAAAAA==';
      final eventBody = XdrContractEventBody(0);
      eventBody.v0 = XdrContractEventV0([], XdrSCVal.forU32(7));
      final diagnosticEvent = XdrDiagnosticEvent(
          true,
          XdrContractEvent(XdrExtensionPoint(0), null,
              XdrContractEventType.CONTRACT, eventBody));
      final diagnosticEventXdr = diagnosticEvent.toBase64EncodedXdrString();
      final server = sendFlowMockServer(
          keyPair,
          {
            'status': 'ERROR',
            'hash': txHash,
            'errorResultXdr': errorResult,
            'diagnosticEventsXdr': [diagnosticEventXdr],
            'latestLedger': 100000,
            'latestLedgerCloseTime': '1234567890',
          },
          getTransactionCalls: getTransactionCalls);

      final tx = await buildSignedTx(keyPair, server);

      await expectLater(
        tx.send(),
        throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            allOf(
                contains('Send transaction failed with status: ERROR'),
                contains(errorResult),
                contains(diagnosticEventXdr)))),
      );
      expect(getTransactionCalls, isEmpty);
    });

    test('an unknown status throws without polling', () async {
      final keyPair = KeyPair.random();
      final getTransactionCalls = <int>[];
      final server = sendFlowMockServer(
          keyPair,
          {
            'status': 'SOMETHING_UNEXPECTED',
            'hash': txHash,
            'latestLedger': 100000,
            'latestLedgerCloseTime': '1234567890',
          },
          getTransactionCalls: getTransactionCalls);

      final tx = await buildSignedTx(keyPair, server);

      await expectLater(
        tx.send(),
        throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains(
                'Send transaction failed with status: SOMETHING_UNEXPECTED'))),
      );
      expect(getTransactionCalls, isEmpty);
    });

    test('a pollable status without a transaction hash throws', () async {
      final keyPair = KeyPair.random();
      final server = sendFlowMockServer(keyPair, {
        'status': 'PENDING',
        'latestLedger': 100000,
        'latestLedgerCloseTime': '1234567890',
      });

      final tx = await buildSignedTx(keyPair, server);

      await expectLater(
        tx.send(),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('contains no transaction hash'))),
      );
    });
  });

  group('transaction time bounds', () {
    test('built transactions set no lower time bound', () async {
      final keyPair = KeyPair.random();
      final simulateEnvelopes = <String>[];
      final server = sendFlowMockServer(
          keyPair,
          {
            'status': 'PENDING',
            'hash': txHash,
            'latestLedger': 100000,
            'latestLedgerCloseTime': '1234567890',
          },
          simulateEnvelopes: simulateEnvelopes);

      await AssembledTransaction.build(options: buildOptions(keyPair, server));

      expect(simulateEnvelopes, hasLength(1));
      final transaction =
          AbstractTransaction.fromEnvelopeXdrString(simulateEnvelopes[0])
              as Transaction;
      final timeBounds = transaction.preconditions?.timeBounds;
      expect(timeBounds, isNotNull);
      expect(timeBounds!.minTime, 0);
      expect(timeBounds.maxTime,
          greaterThan(DateTime.now().millisecondsSinceEpoch ~/ 1000));
    });
  });
}
