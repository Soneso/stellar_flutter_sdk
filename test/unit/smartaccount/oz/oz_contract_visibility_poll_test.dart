// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:dio/dio.dart' as dio;
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import 'oz_pipeline_fixtures.dart';

const String _contractA =
    'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK';

/// Builds a populated [LedgerEntry] standing in for a visible contract
/// instance. Only its non-null presence matters to the poll; the encoded
/// payload is never inspected.
LedgerEntry _visibleInstanceEntry() => LedgerEntry('', '', 0, null, null);

/// Captured `getContractData` invocation: the contract address, the ledger
/// key ScVal, and the durability tier the poll queried with.
class _ContractDataCall {
  const _ContractDataCall(this.contractId, this.key, this.durability);

  final String contractId;
  final XdrSCVal key;
  final XdrContractDataDurability durability;
}

/// Scriptable [SorobanServer] double whose `getContractData` faithfully
/// returns `null` (the real RPC's "not yet visible" signal), a populated
/// [LedgerEntry] (visible), or a thrown error (transient RPC failure).
///
/// The shared [MockSorobanServer] cannot represent `getContractData` returning
/// `null` indefinitely (its fallback path raises `StateError` once the queue
/// drains), so visibility polling, which hinges on the null-vs-non-null
/// distinction over an open-ended number of polls, needs this purpose-built
/// double.
class _ProbeSorobanServer extends SorobanServer {
  _ProbeSorobanServer() : super('https://unused.test/');

  /// Outcomes returned in order: a `null` entry models "contract not yet
  /// visible", a [LedgerEntry] models "visible", and an [Exception]/[Error]
  /// models a transient RPC failure that is thrown.
  final List<Object?> getContractDataOutcomes = <Object?>[];

  /// Fallback outcome once [getContractDataOutcomes] is drained. `null` keeps
  /// the contract invisible indefinitely.
  Object? getContractDataFallback;

  /// Records every `getContractData` invocation in order.
  final List<_ContractDataCall> getContractDataCalls = <_ContractDataCall>[];

  @override
  Future<LedgerEntry?> getContractData(
    String contractId,
    XdrSCVal key,
    XdrContractDataDurability durability,
  ) async {
    getContractDataCalls.add(_ContractDataCall(contractId, key, durability));
    final Object? outcome = getContractDataOutcomes.isNotEmpty
        ? getContractDataOutcomes.removeAt(0)
        : getContractDataFallback;
    if (outcome is Exception) {
      throw outcome;
    }
    if (outcome is Error) {
      throw outcome;
    }
    return outcome as LedgerEntry?;
  }
}

void main() {
  group('waitForContractVisibleToRpc', () {
    // A short poll interval keeps the visibility-poll tests fast while still
    // exercising multiple iterations of the loop.
    const fastInterval = Duration(milliseconds: 1);

    test('pollsUntilContractVisible_thenReturns_pollingExactlyNPlusOneTimes',
        () async {
      final probe = _ProbeSorobanServer()
        ..getContractDataOutcomes.addAll(<Object?>[
          null, // not visible yet
          null, // still not visible
          null, // still not visible
          _visibleInstanceEntry(), // now visible
        ]);
      final kit = FakePipelineKit(sorobanServer: probe);
      final ops = OZWalletOperations(kit);

      await ops.waitForContractVisibleToRpc(
        _contractA,
        null,
        pollInterval: fastInterval,
        timeout: const Duration(seconds: 30),
      );

      // Polled once per null outcome (N = 3) plus the final visible read, and
      // stopped immediately on the visible read: exactly N + 1 = 4 polls means
      // no extra poll/sleep cycle ran after success.
      expect(probe.getContractDataCalls.length, equals(4));
      expect(
        probe.getContractDataCalls.map((c) => c.contractId),
        everyElement(equals(_contractA)),
      );

      // Each poll queried the contract-instance ledger key under persistent
      // durability: the structural visibility signal.
      final first = probe.getContractDataCalls.first;
      expect(
        first.key.discriminant,
        equals(XdrSCValType.SCV_LEDGER_KEY_CONTRACT_INSTANCE),
      );
      expect(first.durability, equals(XdrContractDataDurability.PERSISTENT));
    });

    test('contractVisibleOnFirstPoll_returnsAfterSingleCall_withoutSleeping',
        () async {
      final probe = _ProbeSorobanServer()
        ..getContractDataFallback = _visibleInstanceEntry();
      final kit = FakePipelineKit(sorobanServer: probe);
      final ops = OZWalletOperations(kit);

      // A deliberately large poll interval: if the helper slept on the visible
      // path (before or after the read) the call would hang for ~30s. The tight
      // elapsed bound below proves it returned without ever sleeping.
      final stopwatch = Stopwatch()..start();
      await ops.waitForContractVisibleToRpc(
        _contractA,
        null,
        pollInterval: const Duration(seconds: 30),
        timeout: const Duration(seconds: 60),
      );
      stopwatch.stop();

      expect(probe.getContractDataCalls.length, equals(1));
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 2)));
    });

    test('contractNeverVisible_throwsClearTimeoutError_withNoCause', () async {
      final probe = _ProbeSorobanServer()..getContractDataFallback = null;
      final kit = FakePipelineKit(sorobanServer: probe);
      final ops = OZWalletOperations(kit);

      await expectLater(
        () => ops.waitForContractVisibleToRpc(
          _contractA,
          null,
          pollInterval: fastInterval,
          timeout: const Duration(milliseconds: 40),
        ),
        throwsA(
          isA<SmartAccountTransactionTimeout>()
              .having(
                (e) => e.message,
                'message',
                contains('not visible to the Soroban RPC'),
              )
              .having(
                (e) => e.message,
                'message',
                contains('Retry shortly'),
              )
              // A pure timeout (no transient errors observed) carries no
              // spurious "last error" cause.
              .having((e) => e.cause, 'cause', isNull),
        ),
      );

      // It actually polled (more than once) before giving up.
      expect(probe.getContractDataCalls.length, greaterThan(1));
    });

    test('transientRpcErrors_thenVisible_recoversWithoutThrowing', () async {
      final probe = _ProbeSorobanServer()
        ..getContractDataOutcomes.addAll(<Object?>[
          Exception('rpc 503'), // transient failure, retried
          null, // not visible yet
          Exception('rpc timeout'), // transient failure, retried
          _visibleInstanceEntry(), // visible
        ]);
      final kit = FakePipelineKit(sorobanServer: probe);
      final ops = OZWalletOperations(kit);

      await ops.waitForContractVisibleToRpc(
        _contractA,
        null,
        pollInterval: fastInterval,
        timeout: const Duration(seconds: 30),
      );

      expect(probe.getContractDataCalls.length, equals(4));
    });

    test('persistentRpcErrors_surfaceLastErrorAsTimeoutCause', () async {
      final boom = Exception('rpc permanently unhappy');
      final probe = _ProbeSorobanServer()..getContractDataFallback = boom;
      final kit = FakePipelineKit(sorobanServer: probe);
      final ops = OZWalletOperations(kit);

      await expectLater(
        () => ops.waitForContractVisibleToRpc(
          _contractA,
          null,
          pollInterval: fastInterval,
          timeout: const Duration(milliseconds: 40),
        ),
        throwsA(
          isA<SmartAccountTransactionTimeout>().having(
            (e) => e.cause,
            'cause',
            same(boom),
          ),
        ),
      );
    });

    test('alreadyCancelledToken_throwsBeforeAnyPoll', () async {
      final probe = _ProbeSorobanServer()..getContractDataFallback = null;
      final kit = FakePipelineKit(sorobanServer: probe);
      final ops = OZWalletOperations(kit);

      final cancelToken = dio.CancelToken()..cancel();

      await expectLater(
        () => ops.waitForContractVisibleToRpc(
          _contractA,
          cancelToken,
          pollInterval: fastInterval,
          timeout: const Duration(seconds: 30),
        ),
        throwsA(
          isA<SmartAccountTransactionSubmissionFailed>()
              .having(
                (e) => e.message,
                'message',
                contains('Operation cancelled'),
              )
              // Cancellation is propagated verbatim, never relabelled as the
              // visibility timeout.
              .having(
                (e) => e.message,
                'message',
                isNot(contains('not visible to the Soroban RPC')),
              ),
        ),
      );

      // Cancellation is observed before the first RPC call is made.
      expect(probe.getContractDataCalls, isEmpty);
    });

    test('cancelledMidPoll_propagatesCancellation_notTimeoutOrTransient',
        () async {
      // Stays invisible so the loop would otherwise run to the timeout; the
      // cancel must abort it well before then.
      final probe = _ProbeSorobanServer()..getContractDataFallback = null;
      final kit = FakePipelineKit(sorobanServer: probe);
      final ops = OZWalletOperations(kit);

      final cancelToken = dio.CancelToken();
      // Cancel shortly after polling begins.
      Future<void>.delayed(
        const Duration(milliseconds: 20),
        cancelToken.cancel,
      );

      Object? thrown;
      try {
        await ops.waitForContractVisibleToRpc(
          _contractA,
          cancelToken,
          pollInterval: fastInterval,
          timeout: const Duration(seconds: 30),
        );
        fail('expected the cancelled poll to throw');
      } catch (e) {
        thrown = e;
      }

      // The cancellation surfaces as a submission-failed exception carrying the
      // cancellation marker.
      expect(thrown, isA<SmartAccountTransactionSubmissionFailed>());
      final ex = thrown as SmartAccountTransactionSubmissionFailed;
      expect(ex.message, contains('Operation cancelled'));
      // It was NOT converted into the visibility timeout...
      expect(ex.message, isNot(contains('not visible to the Soroban RPC')));
      // ...and the cancellation was NOT recorded as a transient RPC error and
      // re-surfaced as the timeout cause: the cause is the cancel error, not a
      // retried RPC exception.
      expect(ex.cause, same(cancelToken.cancelError));

      // Polling stopped well before the 30s timeout deadline.
      expect(probe.getContractDataCalls.length, greaterThan(0));
    });
  });
}
