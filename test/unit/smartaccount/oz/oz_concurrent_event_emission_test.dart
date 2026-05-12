// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('concurrent emit', () {
    test('testConcurrentEmit_noLostEventsWithSingleListener', () async {
      final emitter = SmartAccountEventEmitter();
      var count = 0;

      emitter.addListener((_) => count++);

      const eventCount = 100;
      final jobs = <Future<void>>[];
      for (var i = 1; i <= eventCount; i++) {
        jobs.add(Future<void>(() {
          emitter.emit(SmartAccountEventTransactionSubmitted(
            hash: 'hash-$i',
            success: true,
          ));
        }));
      }
      await Future.wait(jobs);

      expect(count, eventCount,
          reason: 'All $eventCount events must be delivered');
    });

    test('testConcurrentEmit_noExceptionWithMultipleListeners', () async {
      final emitter = SmartAccountEventEmitter();

      for (var i = 0; i < 5; i++) {
        emitter.addListener((_) {});
      }

      final jobs = <Future<void>>[];
      for (var i = 1; i <= 50; i++) {
        jobs.add(Future<void>(() {
          emitter.emit(SmartAccountEventWalletConnected(
            contractId: 'contract-$i',
            credentialId: 'cred-$i',
          ));
        }));
      }
      await Future.wait(jobs);
    });

    test('testConcurrentSubscribeAndEmit_noException', () async {
      final emitter = SmartAccountEventEmitter();

      final jobs = <Future<void>>[];
      for (var i = 1; i <= 30; i++) {
        jobs.add(Future<void>(() {
          emitter.emit(SmartAccountEventTransactionSubmitted(
            hash: 'hash-$i',
            success: i % 2 == 0,
          ));
        }));
      }
      for (var i = 1; i <= 20; i++) {
        jobs.add(Future<void>(() {
          emitter.addListener((_) {});
        }));
      }

      await Future.wait(jobs);
    });

    test('testConcurrentUnsubscribeAndEmit_noException', () async {
      final emitter = SmartAccountEventEmitter();
      final unsubscribers = <void Function()>[];

      for (var i = 0; i < 20; i++) {
        unsubscribers.add(emitter.addListener((_) {}));
      }

      final jobs = <Future<void>>[];
      for (var i = 1; i <= 30; i++) {
        jobs.add(Future<void>(() {
          emitter.emit(
              SmartAccountEventWalletDisconnected(contractId: 'c-$i'));
        }));
      }
      for (final unsub in unsubscribers) {
        jobs.add(Future<void>(unsub));
      }

      await Future.wait(jobs);
    });

    test('testConcurrentTypedListeners_noException', () async {
      final emitter = SmartAccountEventEmitter();

      final subscribeJobs = <Future<void>>[];
      for (var i = 1; i <= 10; i++) {
        subscribeJobs.add(Future<void>(() {
          emitter.on<SmartAccountEventWalletConnected>((_) {});
        }));
      }
      await Future.wait(subscribeJobs);

      final emitJobs = <Future<void>>[];
      for (var i = 1; i <= 40; i++) {
        emitJobs.add(Future<void>(() {
          if (i % 2 == 0) {
            emitter.emit(SmartAccountEventWalletConnected(
              contractId: 'c-$i',
              credentialId: 'cred-$i',
            ));
          } else {
            emitter.emit(SmartAccountEventTransactionSubmitted(
              hash: 'h-$i',
              success: true,
            ));
          }
        }));
      }
      await Future.wait(emitJobs);
    });

    test('testConcurrentEmit_listenerCountRemainsConsistent', () async {
      final emitter = SmartAccountEventEmitter();

      emitter.addListener((_) {});

      final jobs = <Future<void>>[];
      for (var i = 1; i <= 60; i++) {
        jobs.add(Future<void>(() {
          emitter.emit(SmartAccountEventSessionExpired(
            contractId: 'c-$i',
            credentialId: 'cred-$i',
          ));
        }));
      }
      await Future.wait(jobs);

      expect(emitter.listenerCount('SessionExpired'), 1);
    });
  });

  group('removeAllListeners under concurrency', () {
    test('testConcurrentRemoveAllAndEmit_noException', () async {
      final emitter = SmartAccountEventEmitter();

      for (var i = 0; i < 10; i++) {
        emitter.addListener((_) {});
      }

      final jobs = <Future<void>>[];
      for (var i = 1; i <= 20; i++) {
        jobs.add(Future<void>(() {
          emitter.emit(
              SmartAccountEventCredentialDeleted(credentialId: 'cred-$i'));
        }));
      }
      jobs.add(Future<void>(() => emitter.removeAllListeners()));

      await Future.wait(jobs);
    });
  });
}
