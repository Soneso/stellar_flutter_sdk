// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:dio/dio.dart' as dio;
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import 'oz_pipeline_fixtures.dart';

const String _contractA =
    'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK';
const String _accountA =
    'GDAT5HWTGIU4TSSZ4752OUC4SABDLTLZFRPZUJ3D6LKBNEPA7V2CIG54';
const String _credentialId = 'aGVsbG8tc21hcnQtYWNjb3VudA';

/// Scriptable [SorobanServer] double whose `getAccount` faithfully returns
/// `null` (the real RPC's "not yet visible" signal) as well as a populated
/// [Account] (visible) or a thrown error (transient RPC failure).
///
/// The shared [MockSorobanServer] cannot represent `getAccount` returning
/// `null` — its queue holds non-null `Object`s and its default-fallback path
/// raises `StateError` on a `null` fallback — so visibility polling, which
/// hinges on the null-vs-non-null distinction, needs this purpose-built
/// double.
class _ProbeSorobanServer extends SorobanServer {
  _ProbeSorobanServer() : super('https://unused.test/');

  /// Outcomes returned in order: a `null` entry models "account not yet
  /// visible", an [Account] models "visible", and an [Exception]/[Error]
  /// models a transient RPC failure that is thrown.
  final List<Object?> getAccountOutcomes = <Object?>[];

  /// Fallback outcome once [getAccountOutcomes] is drained. `null` keeps the
  /// account invisible indefinitely.
  Object? getAccountFallback;

  /// Records every `getAccount` invocation in order.
  final List<String> getAccountCalls = <String>[];

  @override
  Future<Account?> getAccount(String accountId) async {
    getAccountCalls.add(accountId);
    final Object? outcome = getAccountOutcomes.isNotEmpty
        ? getAccountOutcomes.removeAt(0)
        : getAccountFallback;
    if (outcome is Exception) {
      throw outcome;
    }
    if (outcome is Error) {
      throw outcome;
    }
    return outcome as Account?;
  }
}

void main() {
  group('waitForAccountVisibleToRpc', () {
    // A short poll interval keeps the visibility-poll tests fast while still
    // exercising multiple iterations of the loop.
    const fastInterval = Duration(milliseconds: 1);

    test('pollsUntilAccountVisible_thenReturnsWithoutThrowing', () async {
      final probe = _ProbeSorobanServer()
        ..getAccountOutcomes.addAll(<Object?>[
          null, // not visible yet
          null, // still not visible
          null, // still not visible
          Account(_accountA, BigInt.from(1)), // now visible
        ]);
      final kit = FakePipelineKit(sorobanServer: probe);
      final ops = OZTransactionOperations(kit);

      await ops.waitForAccountVisibleToRpc(
        _accountA,
        null,
        pollInterval: fastInterval,
        timeout: const Duration(seconds: 30),
      );

      // Polled once per null outcome plus the final visible read.
      expect(probe.getAccountCalls.length, equals(4));
      expect(probe.getAccountCalls, everyElement(equals(_accountA)));
    });

    test('accountVisibleOnFirstPoll_returnsAfterSingleCall', () async {
      final probe = _ProbeSorobanServer()
        ..getAccountFallback = Account(_accountA, BigInt.from(7));
      final kit = FakePipelineKit(sorobanServer: probe);
      final ops = OZTransactionOperations(kit);

      await ops.waitForAccountVisibleToRpc(
        _accountA,
        null,
        pollInterval: fastInterval,
        timeout: const Duration(seconds: 30),
      );

      expect(probe.getAccountCalls.length, equals(1));
    });

    test('accountNeverVisible_throwsClearTimeoutError', () async {
      final probe = _ProbeSorobanServer()..getAccountFallback = null;
      final kit = FakePipelineKit(sorobanServer: probe);
      final ops = OZTransactionOperations(kit);

      await expectLater(
        () => ops.waitForAccountVisibleToRpc(
          _accountA,
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
              ),
        ),
      );

      // It actually polled (more than once) before giving up.
      expect(probe.getAccountCalls.length, greaterThan(1));
    });

    test('transientRpcErrors_thenVisible_recoversWithoutThrowing', () async {
      final probe = _ProbeSorobanServer()
        ..getAccountOutcomes.addAll(<Object?>[
          Exception('rpc 503'), // transient failure, retried
          null, // not visible yet
          Exception('rpc timeout'), // transient failure, retried
          Account(_accountA, BigInt.from(3)), // visible
        ]);
      final kit = FakePipelineKit(sorobanServer: probe);
      final ops = OZTransactionOperations(kit);

      await ops.waitForAccountVisibleToRpc(
        _accountA,
        null,
        pollInterval: fastInterval,
        timeout: const Duration(seconds: 30),
      );

      expect(probe.getAccountCalls.length, equals(4));
    });

    test('persistentRpcErrors_surfaceLastErrorAsTimeoutCause', () async {
      final boom = Exception('rpc permanently unhappy');
      final probe = _ProbeSorobanServer()..getAccountFallback = boom;
      final kit = FakePipelineKit(sorobanServer: probe);
      final ops = OZTransactionOperations(kit);

      await expectLater(
        () => ops.waitForAccountVisibleToRpc(
          _accountA,
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
      final probe = _ProbeSorobanServer()..getAccountFallback = null;
      final kit = FakePipelineKit(sorobanServer: probe);
      final ops = OZTransactionOperations(kit);

      final cancelToken = dio.CancelToken()..cancel();

      await expectLater(
        () => ops.waitForAccountVisibleToRpc(
          _accountA,
          cancelToken,
          pollInterval: fastInterval,
          timeout: const Duration(seconds: 30),
        ),
        throwsA(
          isA<SmartAccountTransactionSubmissionFailed>().having(
            (e) => e.message,
            'message',
            contains('Operation cancelled'),
          ),
        ),
      );

      // Cancellation is observed before the first RPC call is made.
      expect(probe.getAccountCalls, isEmpty);
    });

    test('cancelledMidPoll_stopsPollingAndThrows', () async {
      // Stays invisible so the loop would otherwise run to the timeout; the
      // cancel must abort it well before then.
      final probe = _ProbeSorobanServer()..getAccountFallback = null;
      final kit = FakePipelineKit(sorobanServer: probe);
      final ops = OZTransactionOperations(kit);

      final cancelToken = dio.CancelToken();
      // Cancel shortly after polling begins.
      Future<void>.delayed(
        const Duration(milliseconds: 20),
        cancelToken.cancel,
      );

      await expectLater(
        () => ops.waitForAccountVisibleToRpc(
          _accountA,
          cancelToken,
          pollInterval: fastInterval,
          timeout: const Duration(seconds: 30),
        ),
        throwsA(
          isA<SmartAccountTransactionSubmissionFailed>().having(
            (e) => e.message,
            'message',
            contains('Operation cancelled'),
          ),
        ),
      );
    });
  });

  group('fundWallet pre-poll validation still guards inputs', () {
    test('notConnected_throwsBeforeFunding', () async {
      final kit = FakePipelineKit();
      final ops = OZTransactionOperations(kit);
      await expectLater(
        () => ops.fundWallet(nativeTokenContract: _contractA),
        throwsA(isA<SmartAccountWalletNotConnected>()),
      );
    });

    test('invalidNativeTokenContract_throwsBeforeFunding', () async {
      final kit = FakePipelineKit()
        ..setConnected(credentialId: _credentialId, contractId: _contractA);
      final ops = OZTransactionOperations(kit);
      await expectLater(
        () => ops.fundWallet(nativeTokenContract: 'garbage'),
        throwsA(isA<SmartAccountInvalidAddress>()),
      );
    });
  });
}
