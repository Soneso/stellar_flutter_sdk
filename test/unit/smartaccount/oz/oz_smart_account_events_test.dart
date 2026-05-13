// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

Uint8List _publicKeyBytes() {
  final bytes = Uint8List(65);
  bytes[0] = 0x04;
  for (var i = 1; i < 65; i++) {
    bytes[i] = i & 0xFF;
  }
  return bytes;
}

void main() {
  group('addListener', () {
    test('testAddListener_receivesAllEventTypes', () {
      final emitter = SmartAccountEventEmitter();
      final received = <SmartAccountEvent>[];

      emitter.addListener(received.add);

      emitter.emit(SmartAccountEventWalletConnected(
        contractId: 'CABC1234${'A' * 48}',
        credentialId: 'cred-1',
      ));
      emitter.emit(const SmartAccountEventTransactionSubmitted(
        hash: 'tx-hash-123',
        success: true,
      ));
      emitter.emit(SmartAccountEventWalletDisconnected(
        contractId: 'CABC1234${'A' * 48}',
      ));

      expect(received, hasLength(3));
      expect(received[0], isA<SmartAccountEventWalletConnected>());
      expect(received[1], isA<SmartAccountEventTransactionSubmitted>());
      expect(received[2], isA<SmartAccountEventWalletDisconnected>());
    });

    test('testAddListener_unsubscribeStopsReceiving', () {
      final emitter = SmartAccountEventEmitter();
      var callCount = 0;

      final unsubscribe = emitter.addListener((_) => callCount++);

      emitter.emit(
          const SmartAccountEventWalletDisconnected(contractId: 'C1234'));
      expect(callCount, 1);

      unsubscribe();

      emitter.emit(
          const SmartAccountEventWalletDisconnected(contractId: 'C5678'));
      expect(callCount, 1, reason: 'Should not receive events after unsubscribe');
    });

    test('testAddListener_multipleGlobalListenersAllReceive', () {
      final emitter = SmartAccountEventEmitter();
      var count1 = 0;
      var count2 = 0;
      var count3 = 0;

      emitter.addListener((_) => count1++);
      emitter.addListener((_) => count2++);
      emitter.addListener((_) => count3++);

      emitter.emit(const SmartAccountEventWalletConnected(
        contractId: 'CONTRACT',
        credentialId: 'cred',
      ));

      expect(count1, 1);
      expect(count2, 1);
      expect(count3, 1);
    });
  });

  group('errorHandler', () {
    test('testErrorHandler_failingListenerDoesNotAffectOthers', () {
      final emitter = SmartAccountEventEmitter();
      var listener1Called = false;
      var listener3Called = false;

      emitter.addListener((_) => listener1Called = true);
      emitter.addListener((_) {
        throw StateError('Intentional failure');
      });
      emitter.addListener((_) => listener3Called = true);

      emitter.setErrorHandler((_, __, ___) {});

      emitter.emit(
          const SmartAccountEventWalletDisconnected(contractId: 'CONTRACT'));

      expect(listener1Called, isTrue,
          reason: 'First listener should have been called');
      expect(listener3Called, isTrue,
          reason: 'Third listener should still be called despite second failing');
    });

    test('testSetErrorHandler_capturesEventAndError', () {
      final emitter = SmartAccountEventEmitter();
      SmartAccountEvent? capturedEvent;
      Object? capturedError;

      emitter.setErrorHandler((event, error, _) {
        capturedEvent = event;
        capturedError = error;
      });

      const errorMessage = 'Test error from listener';
      emitter.addListener((_) {
        throw StateError(errorMessage);
      });

      const event = SmartAccountEventTransactionSubmitted(
        hash: 'abc123',
        success: false,
      );
      emitter.emit(event);

      expect(capturedEvent, isNotNull);
      expect(capturedError, isNotNull);
      expect(capturedEvent, equals(event));
      expect(capturedError.toString(), contains(errorMessage));
    });

    test('testSetErrorHandler_nullDisablesHandler', () {
      final emitter = SmartAccountEventEmitter();
      var handlerCalled = false;

      emitter.setErrorHandler((_, __, ___) => handlerCalled = true);
      emitter.setErrorHandler(null);

      emitter.addListener((_) {
        throw StateError('Boom');
      });

      emitter
          .emit(const SmartAccountEventWalletDisconnected(contractId: 'C'));
      expect(handlerCalled, isFalse);
    });
  });

  group('listenerCount', () {
    test('testListenerCount_noListenersReturnsZero', () {
      final emitter = SmartAccountEventEmitter();
      expect(emitter.listenerCount('WalletConnected'), 0);
    });

    test('testListenerCount_countsTypeSpecificListeners', () {
      final emitter = SmartAccountEventEmitter();

      emitter.on<SmartAccountEventWalletConnected>((_) {});
      emitter.on<SmartAccountEventWalletConnected>((_) {});
      emitter.on<SmartAccountEventTransactionSubmitted>((_) {});

      expect(emitter.listenerCount('WalletConnected'), 2);
      expect(emitter.listenerCount('TransactionSubmitted'), 1);
    });

    test('testListenerCount_includesGlobalListeners', () {
      final emitter = SmartAccountEventEmitter();

      emitter.on<SmartAccountEventWalletConnected>((_) {});
      emitter.addListener((_) {});

      expect(emitter.listenerCount('WalletConnected'), 2);
      expect(emitter.listenerCount('TransactionSubmitted'), 1);
    });
  });

  group('emit isolation', () {
    test('testEmitIsolation_typeSpecificOnlyReceivesMatchingEvents', () {
      final emitter = SmartAccountEventEmitter();
      var walletConnectedCount = 0;
      var txSubmittedCount = 0;

      emitter.on<SmartAccountEventWalletConnected>(
          (_) => walletConnectedCount++);
      emitter.on<SmartAccountEventTransactionSubmitted>(
          (_) => txSubmittedCount++);

      emitter.emit(const SmartAccountEventWalletConnected(
        contractId: 'CONTRACT',
        credentialId: 'cred',
      ));

      expect(walletConnectedCount, 1);
      expect(txSubmittedCount, 0,
          reason:
              'TransactionSubmitted listener should not receive WalletConnected events');
    });

    test('testEmitIsolation_globalAndTypedMixed', () {
      final emitter = SmartAccountEventEmitter();
      var globalCount = 0;
      var typedCount = 0;

      emitter.addListener((_) => globalCount++);
      emitter.on<SmartAccountEventCredentialCreated>((_) => typedCount++);

      emitter
          .emit(const SmartAccountEventWalletDisconnected(contractId: 'C'));

      expect(globalCount, 1, reason: 'Global listener should receive all events');
      expect(typedCount, 0,
          reason: 'Typed listener should not receive unmatched events');

      final credential = StoredCredential(
        credentialId: 'cred-1',
        publicKey: _publicKeyBytes(),
        createdAt: 1700000000000,
      );
      emitter.emit(
          SmartAccountEventCredentialCreated(credential: credential));

      expect(globalCount, 2, reason: 'Global should now have 2 calls');
      expect(typedCount, 1, reason: 'Typed should now have 1 call');
    });
  });

  group('removeAllListeners', () {
    test('testRemoveAllListeners_specificTypeOnly', () {
      final emitter = SmartAccountEventEmitter();
      var walletCount = 0;
      var txCount = 0;

      emitter
          .on<SmartAccountEventWalletConnected>((_) => walletCount++);
      emitter
          .on<SmartAccountEventTransactionSubmitted>((_) => txCount++);

      emitter.removeAllListeners('WalletConnected');

      emitter.emit(const SmartAccountEventWalletConnected(
          contractId: 'C', credentialId: 'c'));
      emitter.emit(const SmartAccountEventTransactionSubmitted(
          hash: 'h', success: true));

      expect(walletCount, 0,
          reason: 'WalletConnected listener should have been removed');
      expect(txCount, 1,
          reason: 'TransactionSubmitted listener should still work');
    });

    test('testRemoveAllListeners_allTypesAndGlobal', () {
      final emitter = SmartAccountEventEmitter();
      var count = 0;

      emitter.on<SmartAccountEventWalletConnected>((_) => count++);
      emitter.on<SmartAccountEventTransactionSubmitted>((_) => count++);
      emitter.addListener((_) => count++);

      emitter.removeAllListeners();

      emitter.emit(const SmartAccountEventWalletConnected(
          contractId: 'C', credentialId: 'c'));
      emitter.emit(const SmartAccountEventTransactionSubmitted(
          hash: 'h', success: true));

      expect(count, 0,
          reason: 'No listeners should remain after removeAllListeners()');
    });
  });

  group('on / typed unsubscribe', () {
    test('testOnUnsubscribe_stopsReceivingTypedEvents', () {
      final emitter = SmartAccountEventEmitter();
      var count = 0;

      final unsubscribe =
          emitter.on<SmartAccountEventSessionExpired>((_) => count++);

      emitter.emit(const SmartAccountEventSessionExpired(
          contractId: 'C', credentialId: 'c'));
      expect(count, 1);

      unsubscribe();

      emitter.emit(const SmartAccountEventSessionExpired(
          contractId: 'C2', credentialId: 'c2'));
      expect(count, 1, reason: 'Should not receive after unsubscribe');
    });
  });

  group('event data', () {
    test('testWalletConnectedEvent', () {
      const event = SmartAccountEventWalletConnected(
        contractId: 'CABC',
        credentialId: 'cred-id',
      );
      expect(event.contractId, 'CABC');
      expect(event.credentialId, 'cred-id');
    });

    test('testWalletDisconnectedEvent', () {
      const event = SmartAccountEventWalletDisconnected(contractId: 'CXYZ');
      expect(event.contractId, 'CXYZ');
    });

    test('testCredentialDeletedEvent', () {
      const event =
          SmartAccountEventCredentialDeleted(credentialId: 'del-cred');
      expect(event.credentialId, 'del-cred');
    });

    test('testSessionExpiredEvent', () {
      const event = SmartAccountEventSessionExpired(
        contractId: 'CSESS',
        credentialId: 'cred-sess',
      );
      expect(event.contractId, 'CSESS');
      expect(event.credentialId, 'cred-sess');
    });

    test('testTransactionSignedEvent', () {
      const event = SmartAccountEventTransactionSigned(
        contractId: 'CTX',
        credentialId: 'cred-tx',
      );
      expect(event.contractId, 'CTX');
      expect(event.credentialId, 'cred-tx');

      const eventWithNull = SmartAccountEventTransactionSigned(
        contractId: 'CTX',
        credentialId: null,
      );
      expect(eventWithNull.credentialId, isNull);
    });

    test('testTransactionSubmittedEvent', () {
      const successEvent = SmartAccountEventTransactionSubmitted(
        hash: 'tx-hash',
        success: true,
      );
      expect(successEvent.hash, 'tx-hash');
      expect(successEvent.success, isTrue);

      const failEvent = SmartAccountEventTransactionSubmitted(
        hash: 'fail-hash',
        success: false,
      );
      expect(failEvent.success, isFalse);
    });

    test('testCredentialCreatedEvent', () {
      final credential = StoredCredential(
        credentialId: 'new-cred',
        publicKey: _publicKeyBytes(),
        createdAt: 1700000000000,
        nickname: 'Test Key',
      );
      final event =
          SmartAccountEventCredentialCreated(credential: credential);
      expect(event.credential.credentialId, 'new-cred');
      expect(event.credential.nickname, 'Test Key');
    });

    test('testCredentialSyncFailedEvent_carriesCredentialIdAndError', () {
      final error = Exception('rpc unreachable');
      final stack = StackTrace.current;
      final event = SmartAccountEventCredentialSyncFailed(
        credentialId: 'cred-xyz',
        error: error,
        stackTrace: stack,
      );
      expect(event.credentialId, 'cred-xyz');
      expect(event.error, same(error));
      expect(event.stackTrace, same(stack));
      expect(event.eventTypeName, 'CredentialSyncFailed');
    });

    test('testCredentialSyncFailedEvent_typedListenerReceivesEvent', () {
      final emitter = SmartAccountEventEmitter();
      final received = <SmartAccountEventCredentialSyncFailed>[];
      emitter.on<SmartAccountEventCredentialSyncFailed>(received.add);

      final event = SmartAccountEventCredentialSyncFailed(
        credentialId: 'cred-1',
        error: Exception('boom'),
      );
      emitter.emit(event);

      expect(received, hasLength(1));
      expect(received.single.credentialId, 'cred-1');
      expect(emitter.listenerCount('CredentialSyncFailed'), 1);
    });
  });

  group('once', () {
    test('testOnce_firesOnFirstEventOnly', () {
      final emitter = SmartAccountEventEmitter();
      final received = <SmartAccountEventWalletConnected>[];

      emitter.once<SmartAccountEventWalletConnected>(received.add);

      const event1 = SmartAccountEventWalletConnected(
          contractId: 'C1', credentialId: 'cr1');
      const event2 = SmartAccountEventWalletConnected(
          contractId: 'C2', credentialId: 'cr2');

      emitter.emit(event1);
      emitter.emit(event2);

      expect(received, hasLength(1),
          reason: 'once listener should fire exactly once');
      expect(received[0].contractId, 'C1',
          reason: 'once listener should receive the first event');
    });

    test('testOnce_unsubscribeBeforeEventFiresCancels', () {
      final emitter = SmartAccountEventEmitter();
      var callCount = 0;

      final unsubscribe =
          emitter.once<SmartAccountEventWalletDisconnected>((_) {
        callCount++;
      });

      unsubscribe();

      emitter
          .emit(const SmartAccountEventWalletDisconnected(contractId: 'C'));

      expect(callCount, 0,
          reason: 'once listener cancelled before firing should never fire');
    });

    test('testOnce_listenerCountDecrementsAfterFiring', () {
      final emitter = SmartAccountEventEmitter();

      emitter.once<SmartAccountEventTransactionSubmitted>((_) {});

      expect(emitter.listenerCount('TransactionSubmitted'), 1);

      emitter.emit(const SmartAccountEventTransactionSubmitted(
          hash: 'h', success: true));

      expect(emitter.listenerCount('TransactionSubmitted'), 0,
          reason:
              'Listener count should decrement after once listener auto-unsubscribes');
    });

    test('testOnce_multipleOnceListenersForSameType', () {
      final emitter = SmartAccountEventEmitter();
      var count1 = 0;
      var count2 = 0;

      emitter.once<SmartAccountEventSessionExpired>((_) => count1++);
      emitter.once<SmartAccountEventSessionExpired>((_) => count2++);

      expect(emitter.listenerCount('SessionExpired'), 2);

      emitter.emit(const SmartAccountEventSessionExpired(
          contractId: 'C', credentialId: 'cr'));

      expect(count1, 1, reason: 'First once listener should fire once');
      expect(count2, 1, reason: 'Second once listener should fire once');

      emitter.emit(const SmartAccountEventSessionExpired(
          contractId: 'C2', credentialId: 'cr2'));

      expect(count1, 1, reason: 'First once listener should not fire again');
      expect(count2, 1, reason: 'Second once listener should not fire again');
      expect(emitter.listenerCount('SessionExpired'), 0,
          reason:
              'All once listeners should be removed after firing');
    });

    test('testOnce_doesNotAffectOtherEventTypes', () {
      final emitter = SmartAccountEventEmitter();
      var onceCount = 0;
      var permanentCount = 0;

      emitter.once<SmartAccountEventWalletConnected>((_) => onceCount++);
      emitter.on<SmartAccountEventWalletDisconnected>(
          (_) => permanentCount++);

      emitter.emit(const SmartAccountEventWalletConnected(
          contractId: 'C', credentialId: 'cr'));
      emitter
          .emit(const SmartAccountEventWalletDisconnected(contractId: 'C'));
      emitter.emit(
          const SmartAccountEventWalletDisconnected(contractId: 'C2'));

      expect(onceCount, 1);
      expect(permanentCount, 2,
          reason: 'Permanent listener should still receive all events');
    });

    test('testOnce_listenerThrowsOnFirstEvent_errorHandlerCalled', () {
      final emitter = SmartAccountEventEmitter();
      var errorHandlerCalled = false;
      Object? capturedError;

      emitter.setErrorHandler((_, error, __) {
        errorHandlerCalled = true;
        capturedError = error;
      });

      emitter.once<SmartAccountEventTransactionSubmitted>((_) {
        throw StateError('Listener failure on first event');
      });

      emitter.emit(const SmartAccountEventTransactionSubmitted(
          hash: 'h1', success: true));

      expect(errorHandlerCalled, isTrue,
          reason: 'Error handler should be called when once listener throws');
      expect(capturedError.toString(),
          contains('Listener failure on first event'));
    });

    test('testOnce_listenerThrowsOnFirstEvent_stillAutoUnsubscribes', () {
      final emitter = SmartAccountEventEmitter();
      var callCount = 0;

      emitter.setErrorHandler((_, __, ___) {});

      emitter.once<SmartAccountEventWalletDisconnected>((_) {
        callCount++;
        throw StateError('Boom');
      });

      emitter
          .emit(const SmartAccountEventWalletDisconnected(contractId: 'C1'));
      emitter
          .emit(const SmartAccountEventWalletDisconnected(contractId: 'C2'));

      expect(callCount, 1,
          reason: 'once listener should fire exactly once even when it throws');
      expect(emitter.listenerCount('WalletDisconnected'), 0,
          reason: 'once listener should be removed even when it throws');
    });
  });

  group('error handler with typed listeners', () {
    test('testErrorHandler_failingTypedListenerDoesNotAffectGlobalListener',
        () {
      final emitter = SmartAccountEventEmitter();
      var globalCalled = false;

      emitter.setErrorHandler((_, __, ___) {});

      emitter.on<SmartAccountEventWalletConnected>((_) {
        throw StateError('Typed listener failure');
      });
      emitter.addListener((_) => globalCalled = true);

      emitter.emit(const SmartAccountEventWalletConnected(
          contractId: 'C', credentialId: 'cr'));

      expect(globalCalled, isTrue,
          reason: 'Global listener should still be called when typed listener throws');
    });
  });

  group('removeAllListeners(eventType) does not remove global listeners', () {
    test('testRemoveAllListeners_specificType_doesNotRemoveGlobalListeners',
        () {
      final emitter = SmartAccountEventEmitter();
      var globalCount = 0;
      var typedCount = 0;

      emitter.addListener((_) => globalCount++);
      emitter.on<SmartAccountEventWalletConnected>((_) => typedCount++);

      emitter.removeAllListeners('WalletConnected');

      emitter.emit(const SmartAccountEventWalletConnected(
          contractId: 'C', credentialId: 'cr'));

      expect(typedCount, 0, reason: 'Typed listener should have been removed');
      expect(globalCount, 1,
          reason:
              'Global listener should NOT be removed by removeAllListeners(eventType)');
    });

    test(
        'testRemoveAllListeners_specificType_globalListenerCountUnchanged',
        () {
      final emitter = SmartAccountEventEmitter();

      emitter.addListener((_) {});
      emitter.on<SmartAccountEventWalletConnected>((_) {});

      expect(emitter.listenerCount('WalletConnected'), 2);

      emitter.removeAllListeners('WalletConnected');

      expect(emitter.listenerCount('WalletConnected'), 1,
          reason:
              'Global listener should still be counted after removeAllListeners(eventType)');
    });
  });

  group('edge cases', () {
    test('testEmit_withNoListeners_doesNotThrow', () {
      final emitter = SmartAccountEventEmitter();

      emitter.emit(const SmartAccountEventWalletConnected(
          contractId: 'C', credentialId: 'cr'));
      emitter.emit(const SmartAccountEventTransactionSubmitted(
          hash: 'h', success: true));
      emitter.emit(
          const SmartAccountEventCredentialDeleted(credentialId: 'cr'));
      emitter.emit(const SmartAccountEventSessionExpired(
          contractId: 'C', credentialId: 'cr'));
      emitter.emit(const SmartAccountEventTransactionSigned(
          contractId: 'C', credentialId: null));
      emitter.emit(
          const SmartAccountEventWalletDisconnected(contractId: 'C'));

      final credential = StoredCredential(
        credentialId: 'cr',
        publicKey: _publicKeyBytes(),
        createdAt: 1700000000000,
      );
      emitter.emit(
          SmartAccountEventCredentialCreated(credential: credential));

      expect(true, isTrue);
    });

    test('testRemoveAllListeners_whenAlreadyEmpty_doesNotThrow', () {
      final emitter = SmartAccountEventEmitter();

      emitter.removeAllListeners();
      emitter.removeAllListeners('WalletConnected');
      emitter.removeAllListeners('NonExistentType');

      expect(true, isTrue);
    });

    test('testUnsubscribe_calledMultipleTimes_doesNotThrow', () {
      final emitter = SmartAccountEventEmitter();

      final unsubscribe =
          emitter.on<SmartAccountEventWalletConnected>((_) {});

      unsubscribe();
      unsubscribe();

      expect(emitter.listenerCount('WalletConnected'), 0);
    });

    test('testAddListenerUnsubscribe_calledMultipleTimes_doesNotThrow', () {
      final emitter = SmartAccountEventEmitter();

      final unsubscribe = emitter.addListener((_) {});

      unsubscribe();
      unsubscribe();

      expect(emitter.listenerCount('AnyType'), 0);
    });
  });

  group('rapid emission', () {
    test('testRapidEmission_allEventsDeliveredInOrder', () {
      final emitter = SmartAccountEventEmitter();
      final receivedHashes = <String>[];

      emitter.on<SmartAccountEventTransactionSubmitted>((event) {
        receivedHashes.add(event.hash);
      });

      const count = 100;
      for (var i = 0; i < count; i++) {
        emitter.emit(SmartAccountEventTransactionSubmitted(
            hash: 'tx-$i', success: true));
      }

      expect(receivedHashes, hasLength(count),
          reason: 'All $count events should be delivered');
      for (var i = 0; i < count; i++) {
        expect(receivedHashes[i], 'tx-$i',
            reason: 'Events should arrive in emission order');
      }
    });

    test('testRapidEmission_mixedEventTypes', () {
      final emitter = SmartAccountEventEmitter();
      final allEvents = <SmartAccountEvent>[];

      emitter.addListener(allEvents.add);

      for (var i = 0; i < 50; i++) {
        emitter.emit(SmartAccountEventWalletConnected(
            contractId: 'C$i', credentialId: 'cr$i'));
        emitter.emit(SmartAccountEventTransactionSubmitted(
            hash: 'tx-$i', success: i % 2 == 0));
      }

      expect(allEvents, hasLength(100),
          reason: 'All 100 mixed events should be delivered');
      for (var i = 0; i < 50; i++) {
        expect(allEvents[i * 2], isA<SmartAccountEventWalletConnected>());
        expect(allEvents[i * 2 + 1],
            isA<SmartAccountEventTransactionSubmitted>());
      }
    });
  });

  group('data class equality and copy', () {
    test('testWalletConnected_equalityAndCopy', () {
      const event1 = SmartAccountEventWalletConnected(
          contractId: 'C1', credentialId: 'cr1');
      const event2 = SmartAccountEventWalletConnected(
          contractId: 'C1', credentialId: 'cr1');
      const event3 = SmartAccountEventWalletConnected(
          contractId: 'C2', credentialId: 'cr1');

      expect(event1, equals(event2));
      expect(event1.hashCode, equals(event2.hashCode));
      expect(event1, isNot(equals(event3)));

      const copied = SmartAccountEventWalletConnected(
          contractId: 'C1', credentialId: 'cr-new');
      expect(copied.contractId, 'C1');
      expect(copied.credentialId, 'cr-new');
    });

    test('testWalletDisconnected_equalityAndCopy', () {
      const event1 = SmartAccountEventWalletDisconnected(contractId: 'C1');
      const event2 = SmartAccountEventWalletDisconnected(contractId: 'C1');
      const event3 = SmartAccountEventWalletDisconnected(contractId: 'C2');

      expect(event1, equals(event2));
      expect(event1.hashCode, equals(event2.hashCode));
      expect(event1, isNot(equals(event3)));

      const copied = SmartAccountEventWalletDisconnected(contractId: 'C-new');
      expect(copied.contractId, 'C-new');
    });

    test('testTransactionSubmitted_equalityAndCopy', () {
      const event1 = SmartAccountEventTransactionSubmitted(
          hash: 'h1', success: true);
      const event2 = SmartAccountEventTransactionSubmitted(
          hash: 'h1', success: true);
      const event3 = SmartAccountEventTransactionSubmitted(
          hash: 'h1', success: false);

      expect(event1, equals(event2));
      expect(event1.hashCode, equals(event2.hashCode));
      expect(event1, isNot(equals(event3)),
          reason: 'Different success value should not be equal');

      const copied = SmartAccountEventTransactionSubmitted(
          hash: 'h1', success: false);
      expect(copied.hash, 'h1');
      expect(copied.success, isFalse);
    });

    test('testTransactionSigned_equalityWithNullCredential', () {
      const event1 = SmartAccountEventTransactionSigned(
          contractId: 'C1', credentialId: null);
      const event2 = SmartAccountEventTransactionSigned(
          contractId: 'C1', credentialId: null);
      const event3 = SmartAccountEventTransactionSigned(
          contractId: 'C1', credentialId: 'cr');

      expect(event1, equals(event2),
          reason: 'Both with null credentialId should be equal');
      expect(event1, isNot(equals(event3)),
          reason: 'Null vs non-null credentialId should not be equal');
    });

    test('testSessionExpired_equalityAndCopy', () {
      const event1 = SmartAccountEventSessionExpired(
          contractId: 'C1', credentialId: 'cr1');
      const event2 = SmartAccountEventSessionExpired(
          contractId: 'C1', credentialId: 'cr1');

      expect(event1, equals(event2));
      expect(event1.hashCode, equals(event2.hashCode));

      const copied = SmartAccountEventSessionExpired(
          contractId: 'C-new', credentialId: 'cr1');
      expect(copied.contractId, 'C-new');
      expect(copied.credentialId, 'cr1');
    });

    test('testCredentialDeleted_equalityAndCopy', () {
      const event1 = SmartAccountEventCredentialDeleted(credentialId: 'cr1');
      const event2 = SmartAccountEventCredentialDeleted(credentialId: 'cr1');
      const event3 = SmartAccountEventCredentialDeleted(credentialId: 'cr2');

      expect(event1, equals(event2));
      expect(event1, isNot(equals(event3)));

      const copied =
          SmartAccountEventCredentialDeleted(credentialId: 'cr-new');
      expect(copied.credentialId, 'cr-new');
    });

    test('testDifferentEventTypes_areNeverEqual', () {
      const connected = SmartAccountEventWalletConnected(
          contractId: 'C', credentialId: 'cr');
      const disconnected =
          SmartAccountEventWalletDisconnected(contractId: 'C');
      const expired = SmartAccountEventSessionExpired(
          contractId: 'C', credentialId: 'cr');

      expect(connected, isNot(equals(disconnected)),
          reason: 'Different event types should never be equal');
      expect(connected, isNot(equals(expired)),
          reason:
              'Different event types should never be equal even with same properties');
    });
  });

  group('listener interaction during emission', () {
    test('testListener_canUnsubscribeItselfDuringEmission', () {
      final emitter = SmartAccountEventEmitter();
      var callCount = 0;

      late void Function() unsub;
      unsub = emitter.on<SmartAccountEventWalletDisconnected>((_) {
        callCount++;
        unsub();
      });

      emitter
          .emit(const SmartAccountEventWalletDisconnected(contractId: 'C1'));
      emitter
          .emit(const SmartAccountEventWalletDisconnected(contractId: 'C2'));

      expect(callCount, 1,
          reason:
              'Listener that unsubscribes itself during emission should fire once');
    });

    test('testOnce_combinedWithPermanentListener', () {
      final emitter = SmartAccountEventEmitter();
      var onceCount = 0;
      var permanentCount = 0;

      emitter
          .once<SmartAccountEventTransactionSubmitted>((_) => onceCount++);
      emitter
          .on<SmartAccountEventTransactionSubmitted>((_) => permanentCount++);

      emitter.emit(const SmartAccountEventTransactionSubmitted(
          hash: 'tx1', success: true));
      emitter.emit(const SmartAccountEventTransactionSubmitted(
          hash: 'tx2', success: true));
      emitter.emit(const SmartAccountEventTransactionSubmitted(
          hash: 'tx3', success: true));

      expect(onceCount, 1, reason: 'once listener should fire exactly once');
      expect(permanentCount, 3,
          reason: 'Permanent listener should fire for all events');
    });
  });
}
