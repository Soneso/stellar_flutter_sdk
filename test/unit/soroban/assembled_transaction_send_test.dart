// Tests for AssembledTransaction.send() submission-status handling and for
// the time bounds set on transactions built by AssembledTransaction.
//
// All RPC calls are served by a mocked Dio adapter; no network access.

import 'dart:async';
import 'dart:convert';
import 'dart:io' show sleep;
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

class PauseOnCancelTimer implements Timer {
  final Timer timer;
  final void Function() onCancel;

  PauseOnCancelTimer(this.timer, this.onCancel);

  @override
  bool get isActive => timer.isActive;

  @override
  int get tick => timer.tick;

  @override
  void cancel() {
    timer.cancel();
    onCancel();
  }
}

dio.ResponseBody jsonRpcResponse(dynamic id, Map<String, dynamic> result) {
  return dio.ResponseBody.fromString(
    jsonEncode({'jsonrpc': '2.0', 'id': id, 'result': result}),
    200,
    headers: {
      'content-type': [dio.Headers.jsonContentType],
    },
  );
}

dio.ResponseBody accountEntryResponse(
  Map<String, dynamic> requestBody,
  KeyPair keyPair,
  BigInt sequence,
) {
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
      },
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
    XdrLedgerFootprint([], [key]),
    XdrUint32(0),
    XdrUint32(0),
    XdrUint32(0),
  );
  return XdrSorobanTransactionData(
    XdrSorobanTransactionDataExt(0),
    resources,
    XdrInt64(BigInt.zero),
  );
}

Map<String, dynamic> successfulSimulation(XdrSorobanTransactionData txData) {
  return {
    'minResourceFee': '100000',
    'transactionData': txData.toBase64EncodedXdrString(),
    'results': [
      {'auth': [], 'xdr': XdrSCVal.forU32(42).toBase64EncodedXdrString()},
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
    KeyPair keyPair,
    SorobanServer server,
  ) {
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
    Future<dio.ResponseBody> Function(dynamic)? pollResponse,
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
            requestBody['id'],
            successfulSimulation(txData),
          );
        case 'sendTransaction':
          return jsonRpcResponse(requestBody['id'], sendResult);
        case 'getTransaction':
          getTransactionCalls?.add(1);
          if (pollResponse != null) return pollResponse(requestBody['id']);
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
    KeyPair keyPair,
    SorobanServer server,
  ) async {
    final tx = await AssembledTransaction.build(
      options: buildOptions(keyPair, server),
    );
    tx.sign(force: true);
    return tx;
  }

  Future<AssembledTransaction> pollingTx(
    int seconds,
    Future<dio.ResponseBody> Function(dynamic) poll,
  ) async {
    final keyPair = KeyPair.random();
    final server = sendFlowMockServer(keyPair, {
      'status': 'PENDING',
      'hash': txHash,
    }, pollResponse: poll);
    final tx = await buildSignedTx(keyPair, server);
    tx.options.methodOptions.timeoutInSeconds = seconds;
    return tx;
  }

  Matcher interrupted(int seconds, {String? reason}) => isA<Exception>()
      .having((e) => e.runtimeType, 'plain exception', Exception().runtimeType)
      .having(
        (e) => e.toString(),
        'message',
        allOf([
          contains(
            'Interrupted after waiting $seconds seconds '
            '(options.methodOptions.timeoutInSeconds) for the transaction '
            '$txHash to complete.',
          ),
          if (reason != null) contains(reason),
        ]),
      );

  group('signAndSend poll deadline', () {
    test('bounds stalled round and last status requests', () async {
      var calls = 0;
      final tx = await pollingTx(4, (_) {
        calls++;
        return Completer<dio.ResponseBody>().future;
      });
      final clock = Stopwatch()..start();
      await expectLater(
        tx.signAndSend(),
        throwsA(interrupted(4, reason: 'TimeoutException')),
      );
      expect(calls, 2);
      expect(clock.elapsed, greaterThanOrEqualTo(const Duration(seconds: 7)));
      expect(clock.elapsed, lessThan(const Duration(seconds: 8)));
    }, timeout: const Timeout(Duration(seconds: 9)));

    test('retries a thrown status request and returns SUCCESS', () async {
      var calls = 0;
      final tx = await pollingTx(7, (id) async {
        if (++calls == 1) throw Exception('temporary status failure');
        return jsonRpcResponse(id, {'status': 'SUCCESS', 'ledger': 123});
      });
      final response = await tx.signAndSend();
      expect(calls, 2);
      expect(response.status, GetTransactionResponse.STATUS_SUCCESS);
      expect(response.ledger, 123);
    }, timeout: const Timeout(Duration(seconds: 9)));

    test(
      'returns SUCCESS received within the bound and handled past the deadline',
      () async {
        var calls = 0;
        final tx = await pollingTx(4, (id) async {
          calls++;
          await Future<void>.delayed(const Duration(milliseconds: 700));
          return jsonRpcResponse(id, {'status': 'SUCCESS', 'ledger': 789});
        });
        final clock = Stopwatch()..start();
        var wrapped = false;
        Duration? receivedAt;
        final response = await runZoned(
          tx.signAndSend,
          zoneSpecification: ZoneSpecification(
            createTimer: (self, parent, zone, duration, callback) {
              final timer = parent.createTimer(zone, duration, callback);
              if (wrapped ||
                  duration <= Duration.zero ||
                  duration >= const Duration(seconds: 1))
                return timer;
              wrapped = true;
              // Pause after the status response wins its per-call timeout,
              // before the polling loop resumes to inspect the response.
              return PauseOnCancelTimer(timer, () {
                receivedAt = clock.elapsed;
                sleep(const Duration(milliseconds: 400));
              });
            },
          ),
        );
        expect(calls, 1);
        expect(receivedAt, lessThan(const Duration(seconds: 4)));
        expect(clock.elapsed, greaterThanOrEqualTo(const Duration(seconds: 4)));
        expect(response.status, GetTransactionResponse.STATUS_SUCCESS);
        expect(response.ledger, 789);
      },
      timeout: const Timeout(Duration(seconds: 6)),
    );

    test('includes the last RPC error at the deadline', () async {
      var calls = 0;
      final tx = await pollingTx(7, (id) async {
        calls++;
        return dio.ResponseBody.fromString(
          jsonEncode({
            'jsonrpc': '2.0',
            'id': id,
            'error': {'code': -32000 - calls, 'message': 'status error $calls'},
          }),
          200,
          headers: {
            'content-type': [dio.Headers.jsonContentType],
          },
        );
      });
      final clock = Stopwatch()..start();
      await expectLater(
        tx.signAndSend(),
        throwsA(
          allOf(
            interrupted(7, reason: '-32003'),
            predicate((e) => e.toString().contains('status error 3')),
          ),
        ),
      );
      expect(calls, 3);
      expect(clock.elapsed, lessThan(const Duration(seconds: 8)));
    }, timeout: const Timeout(Duration(seconds: 9)));

    test('counts slow NOT_FOUND requests in the elapsed budget', () async {
      var calls = 0;
      final tx = await pollingTx(7, (id) async {
        calls++;
        await Future<void>.delayed(const Duration(seconds: 2));
        return jsonRpcResponse(id, {'status': 'NOT_FOUND'});
      });
      final clock = Stopwatch()..start();
      await expectLater(tx.signAndSend(), throwsA(interrupted(7)));
      expect(calls, 2);
      expect(clock.elapsed, greaterThanOrEqualTo(const Duration(seconds: 9)));
      expect(clock.elapsed, lessThan(const Duration(seconds: 10)));
    }, timeout: const Timeout(Duration(seconds: 11)));

    test('makes one request when the clamped last timer fires early', () async {
      var calls = 0;
      final tx = await pollingTx(1, (id) async {
        calls++;
        return jsonRpcResponse(id, {'status': 'NOT_FOUND'});
      });
      await runZoned(
        () => expectLater(tx.signAndSend(), throwsA(interrupted(1))),
        zoneSpecification: ZoneSpecification(
          createTimer: (self, parent, zone, duration, callback) {
            if (calls == 0 &&
                duration > const Duration(milliseconds: 50) &&
                duration <= const Duration(seconds: 1)) {
              duration -= const Duration(milliseconds: 50);
            }
            return parent.createTimer(zone, duration, callback);
          },
        ),
      );
      expect(calls, 1);
    }, timeout: const Timeout(Duration(seconds: 3)));

    for (final status in ['NOT_FOUND', 'SUCCESS']) {
      test(
        'clamps the last sleep and requests $status at the deadline',
        () async {
          var calls = 0;
          final tx = await pollingTx(1, (id) async {
            calls++;
            return jsonRpcResponse(id, {'status': status, 'ledger': 234});
          });
          final clock = Stopwatch()..start();
          if (status == 'SUCCESS') {
            final response = await tx.signAndSend();
            expect(response.status, GetTransactionResponse.STATUS_SUCCESS);
            expect(response.ledger, 234);
          } else {
            await expectLater(tx.signAndSend(), throwsA(interrupted(1)));
          }
          expect(calls, 1);
          expect(
            clock.elapsed,
            greaterThanOrEqualTo(const Duration(seconds: 1)),
          );
          expect(clock.elapsed, lessThan(const Duration(seconds: 2)));
        },
        timeout: const Timeout(Duration(seconds: 3)),
      );
    }

    test(
      'returns SUCCESS at the deadline after the last round is NOT_FOUND',
      () async {
        var calls = 0;
        final tx = await pollingTx(5, (id) async {
          return jsonRpcResponse(id, {
            'status': ++calls == 1 ? 'NOT_FOUND' : 'SUCCESS',
            'ledger': 345,
          });
        });
        final clock = Stopwatch()..start();
        final response = await tx.signAndSend();
        expect(calls, 2);
        expect(response.status, GetTransactionResponse.STATUS_SUCCESS);
        expect(response.ledger, 345);
        expect(clock.elapsed, greaterThanOrEqualTo(const Duration(seconds: 5)));
        expect(clock.elapsed, lessThan(const Duration(seconds: 6)));
      },
      timeout: const Timeout(Duration(seconds: 7)),
    );

    for (final seconds in [0, -1]) {
      for (final status in ['NOT_FOUND', 'SUCCESS']) {
        test(
          'timeout $seconds makes one immediate request for $status',
          () async {
            var calls = 0;
            final tx = await pollingTx(seconds, (id) async {
              calls++;
              return jsonRpcResponse(id, {'status': status, 'ledger': 567});
            });
            final clock = Stopwatch()..start();
            if (status == 'SUCCESS') {
              final response = await tx.signAndSend();
              expect(response.status, GetTransactionResponse.STATUS_SUCCESS);
              expect(response.ledger, 567);
            } else {
              await expectLater(
                tx.signAndSend(),
                throwsA(interrupted(seconds)),
              );
            }
            expect(calls, 1);
            expect(clock.elapsed, lessThan(const Duration(seconds: 1)));
          },
          timeout: const Timeout(Duration(seconds: 2)),
        );
      }
    }

    test('returns FAILED as the final response', () async {
      final tx = await pollingTx(
        4,
        (id) async => jsonRpcResponse(id, {'status': 'FAILED', 'ledger': 456}),
      );
      final response = await tx.signAndSend();
      expect(response.status, GetTransactionResponse.STATUS_FAILED);
      expect(response.ledger, 456);
    }, timeout: const Timeout(Duration(seconds: 5)));
  });

  group('send() submission-status handling', () {
    test('PENDING is polled to the final transaction response', () async {
      final keyPair = KeyPair.random();
      final getTransactionCalls = <int>[];
      final server = sendFlowMockServer(keyPair, {
        'status': 'PENDING',
        'hash': txHash,
        'latestLedger': 100000,
        'latestLedgerCloseTime': '1234567890',
      }, getTransactionCalls: getTransactionCalls);

      final tx = await buildSignedTx(keyPair, server);
      final response = await tx.send();

      expect(response.status, GetTransactionResponse.STATUS_SUCCESS);
      expect(getTransactionCalls, isNotEmpty);
    }, timeout: const Timeout(Duration(seconds: 5)));

    test('DUPLICATE is polled to the final transaction response', () async {
      final keyPair = KeyPair.random();
      final getTransactionCalls = <int>[];
      final server = sendFlowMockServer(keyPair, {
        'status': 'DUPLICATE',
        'hash': txHash,
        'latestLedger': 100000,
        'latestLedgerCloseTime': '1234567890',
      }, getTransactionCalls: getTransactionCalls);

      final tx = await buildSignedTx(keyPair, server);
      final response = await tx.send();

      expect(response.status, GetTransactionResponse.STATUS_SUCCESS);
      expect(getTransactionCalls, isNotEmpty);
    }, timeout: const Timeout(Duration(seconds: 5)));

    test('TRY_AGAIN_LATER throws without polling', () async {
      final keyPair = KeyPair.random();
      final getTransactionCalls = <int>[];
      final server = sendFlowMockServer(keyPair, {
        'status': 'TRY_AGAIN_LATER',
        'hash': txHash,
        'latestLedger': 100000,
        'latestLedgerCloseTime': '1234567890',
      }, getTransactionCalls: getTransactionCalls);

      final tx = await buildSignedTx(keyPair, server);

      await expectLater(
        tx.send(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Send transaction failed with status: TRY_AGAIN_LATER'),
          ),
        ),
      );
      expect(getTransactionCalls, isEmpty);
    });

    test(
      'ERROR throws with the error result xdr and diagnostic events',
      () async {
        final keyPair = KeyPair.random();
        final getTransactionCalls = <int>[];
        // A TransactionResult with code txBAD_SEQ.
        const errorResult = 'AAAAAAAAAGT////7AAAAAA==';
        final eventBody = XdrContractEventBody(0);
        eventBody.v0 = XdrContractEventV0([], XdrSCVal.forU32(7));
        final diagnosticEvent = XdrDiagnosticEvent(
          true,
          XdrContractEvent(
            XdrExtensionPoint(0),
            null,
            XdrContractEventType.CONTRACT,
            eventBody,
          ),
        );
        final diagnosticEventXdr = diagnosticEvent.toBase64EncodedXdrString();
        final server = sendFlowMockServer(keyPair, {
          'status': 'ERROR',
          'hash': txHash,
          'errorResultXdr': errorResult,
          'diagnosticEventsXdr': [diagnosticEventXdr],
          'latestLedger': 100000,
          'latestLedgerCloseTime': '1234567890',
        }, getTransactionCalls: getTransactionCalls);

        final tx = await buildSignedTx(keyPair, server);

        await expectLater(
          tx.send(),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              allOf(
                contains('Send transaction failed with status: ERROR'),
                contains(errorResult),
                contains(diagnosticEventXdr),
              ),
            ),
          ),
        );
        expect(getTransactionCalls, isEmpty);
      },
    );

    test('an unknown status throws without polling', () async {
      final keyPair = KeyPair.random();
      final getTransactionCalls = <int>[];
      final server = sendFlowMockServer(keyPair, {
        'status': 'SOMETHING_UNEXPECTED',
        'hash': txHash,
        'latestLedger': 100000,
        'latestLedgerCloseTime': '1234567890',
      }, getTransactionCalls: getTransactionCalls);

      final tx = await buildSignedTx(keyPair, server);

      await expectLater(
        tx.send(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains(
              'Send transaction failed with status: SOMETHING_UNEXPECTED',
            ),
          ),
        ),
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
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('contains no transaction hash'),
          ),
        ),
      );
    });
  });

  group('transaction time bounds', () {
    test('built transactions set no lower time bound', () async {
      final keyPair = KeyPair.random();
      final simulateEnvelopes = <String>[];
      final server = sendFlowMockServer(keyPair, {
        'status': 'PENDING',
        'hash': txHash,
        'latestLedger': 100000,
        'latestLedgerCloseTime': '1234567890',
      }, simulateEnvelopes: simulateEnvelopes);

      await AssembledTransaction.build(options: buildOptions(keyPair, server));

      expect(simulateEnvelopes, hasLength(1));
      final transaction =
          AbstractTransaction.fromEnvelopeXdrString(simulateEnvelopes[0])
              as Transaction;
      final timeBounds = transaction.preconditions?.timeBounds;
      expect(timeBounds, isNotNull);
      expect(timeBounds!.minTime, 0);
      expect(
        timeBounds.maxTime,
        greaterThan(DateTime.now().millisecondsSinceEpoch ~/ 1000),
      );
    });
  });
}
