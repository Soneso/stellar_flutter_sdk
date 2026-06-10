// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'oz_storage_adapter.dart';

/// Events emitted by the Smart Account Kit during wallet lifecycle operations.
///
/// These events provide hooks for monitoring and responding to key operations:
///
/// - Wallet connection and disconnection
/// - Credential lifecycle (creation, deletion)
/// - Transaction lifecycle (signing, submission)
/// - Session management (expiration)
///
/// Example:
///
/// ```dart
/// kit.events.addListener((event) {
///   if (event is OZSmartAccountEventWalletConnected) {
///     print('Connected to ${event.contractId}');
///   } else if (event is OZSmartAccountEventTransactionSubmitted) {
///     print('Transaction ${event.hash} submitted');
///   }
/// });
/// ```
sealed class OZSmartAccountEvent {
  const OZSmartAccountEvent();

  /// The string identifier used by [OZSmartAccountEventEmitter] when keying
  /// type-specific listeners and resolving counts in
  /// [OZSmartAccountEventEmitter.listenerCount].
  ///
  /// The identifier matches the unqualified arm name (for example
  /// `"WalletConnected"`) so it can be passed verbatim to
  /// [OZSmartAccountEventEmitter.removeAllListeners] and
  /// [OZSmartAccountEventEmitter.listenerCount].
  String get eventTypeName;
}

/// Emitted when a wallet is connected.
///
/// This event is fired when connecting to an existing wallet, either through
/// automatic session restoration or an explicit wallet connection call.
final class OZSmartAccountEventWalletConnected extends OZSmartAccountEvent {
  const OZSmartAccountEventWalletConnected({
    required this.contractId,
    required this.credentialId,
  });

  final String contractId;
  final String credentialId;

  @override
  String get eventTypeName => 'WalletConnected';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OZSmartAccountEventWalletConnected &&
        other.contractId == contractId &&
        other.credentialId == credentialId;
  }

  @override
  int get hashCode => Object.hash(contractId, credentialId);
}

/// Emitted when a wallet is disconnected.
///
/// This event is fired when `disconnect()` is called. The session is cleared,
/// but stored credentials remain for future reconnection.
final class OZSmartAccountEventWalletDisconnected extends OZSmartAccountEvent {
  const OZSmartAccountEventWalletDisconnected({required this.contractId});

  final String contractId;

  @override
  String get eventTypeName => 'WalletDisconnected';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OZSmartAccountEventWalletDisconnected &&
        other.contractId == contractId;
  }

  @override
  int get hashCode => contractId.hashCode;
}

/// Emitted when a new credential is created (passkey registered).
///
/// This event is fired after successful WebAuthn credential creation, whether
/// during initial wallet setup or when adding a new signer to an existing
/// wallet. Note that the wallet may not be deployed yet.
final class OZSmartAccountEventCredentialCreated extends OZSmartAccountEvent {
  const OZSmartAccountEventCredentialCreated({required this.credential});

  final OZStoredCredential credential;

  @override
  String get eventTypeName => 'CredentialCreated';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OZSmartAccountEventCredentialCreated &&
        other.credential == credential;
  }

  @override
  int get hashCode => credential.hashCode;
}

/// Emitted when a credential is deleted from storage.
///
/// This event is fired when a credential is removed via the credential
/// management API. Deleting a connected credential does not clear the
/// kit's connection state; call `disconnect()` first if that is required.
final class OZSmartAccountEventCredentialDeleted extends OZSmartAccountEvent {
  const OZSmartAccountEventCredentialDeleted({required this.credentialId});

  final String credentialId;

  @override
  String get eventTypeName => 'CredentialDeleted';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OZSmartAccountEventCredentialDeleted &&
        other.credentialId == credentialId;
  }

  @override
  int get hashCode => credentialId.hashCode;
}

/// Emitted when a session expires during a connection attempt.
///
/// This event is fired when attempting to restore a session that has expired.
/// The application should prompt the user to reconnect.
final class OZSmartAccountEventSessionExpired extends OZSmartAccountEvent {
  const OZSmartAccountEventSessionExpired({
    required this.contractId,
    required this.credentialId,
  });

  final String contractId;
  final String credentialId;

  @override
  String get eventTypeName => 'SessionExpired';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OZSmartAccountEventSessionExpired &&
        other.contractId == contractId &&
        other.credentialId == credentialId;
  }

  @override
  int get hashCode => Object.hash(contractId, credentialId);
}

/// Emitted when a credential sync against on-chain state swallows a
/// non-fatal exception.
///
/// `OZCredentialManager.sync` is a best-effort discovery probe: a transient
/// RPC failure, a deletion failure on the storage adapter, or any other
/// `Exception` raised while reading on-chain state is reported as
/// "credential not deployed" rather than thrown back to the caller. This
/// event surfaces those swallowed exceptions to consumer code that wants
/// to log them, retry the sync, or warn the user that the deployment
/// state may be stale.
///
/// Programmer errors (subclasses of `Error` such as `StateError`,
/// `ArgumentError`, `RangeError`) are NOT routed through this event; they
/// continue to propagate so caller bugs surface as test failures rather
/// than silent debug events.
final class OZSmartAccountEventCredentialSyncFailed extends OZSmartAccountEvent {
  const OZSmartAccountEventCredentialSyncFailed({
    required this.credentialId,
    required this.error,
    this.stackTrace,
  });

  /// The Base64URL-encoded credential ID whose sync probe failed.
  final String credentialId;

  /// The swallowed exception. Always an `Exception` subclass; programmer
  /// errors are not routed here.
  final Object error;

  /// Optional stack trace captured at the throw site; `null` when not
  /// available.
  final StackTrace? stackTrace;

  @override
  String get eventTypeName => 'CredentialSyncFailed';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OZSmartAccountEventCredentialSyncFailed &&
        other.credentialId == credentialId &&
        other.error == error &&
        other.stackTrace == stackTrace;
  }

  @override
  int get hashCode => Object.hash(credentialId, error, stackTrace);
}

/// Emitted when a transaction is signed.
///
/// This event is fired after successfully collecting all required signatures
/// for a transaction, before submission to the network.
final class OZSmartAccountEventTransactionSigned extends OZSmartAccountEvent {
  const OZSmartAccountEventTransactionSigned({
    required this.contractId,
    required this.credentialId,
  });

  final String contractId;

  /// `null` when only external signers were involved.
  final String? credentialId;

  @override
  String get eventTypeName => 'TransactionSigned';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OZSmartAccountEventTransactionSigned &&
        other.contractId == contractId &&
        other.credentialId == credentialId;
  }

  @override
  int get hashCode => Object.hash(contractId, credentialId);
}

/// Emitted when a transaction is submitted to the network.
///
/// This event is fired after sending the signed transaction to Soroban RPC or
/// the relayer service. The success flag indicates whether the transaction
/// was successfully sent to the network node, not whether it was included in
/// a ledger.
final class OZSmartAccountEventTransactionSubmitted extends OZSmartAccountEvent {
  const OZSmartAccountEventTransactionSubmitted({
    required this.hash,
    required this.success,
  });

  final String hash;

  /// `true` when the transaction was sent to the network node; `false` when
  /// submission failed. Does not indicate ledger inclusion.
  final bool success;

  @override
  String get eventTypeName => 'TransactionSubmitted';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OZSmartAccountEventTransactionSubmitted &&
        other.hash == hash &&
        other.success == success;
  }

  @override
  int get hashCode => Object.hash(hash, success);
}

/// Listener function invoked when a [OZSmartAccountEvent] is dispatched.
///
/// Use [OZSmartAccountEventEmitter.addListener] to register a listener for all
/// event types, or [OZSmartAccountEventEmitter.on] / [OZSmartAccountEventEmitter.once]
/// for type-specific subscriptions.
typedef OZSmartAccountEventListener = void Function(OZSmartAccountEvent event);

/// Optional handler invoked when a listener throws while processing an event.
///
/// Receives the [event] that was being dispatched, the [error] thrown by the
/// listener, and the [stackTrace] captured at the throw site. Set via
/// [OZSmartAccountEventEmitter.setErrorHandler]; pass `null` to disable.
typedef OZSmartAccountEventErrorHandler = void Function(
  OZSmartAccountEvent event,
  Object error,
  StackTrace stackTrace,
);

/// Event emitter for Smart Account lifecycle events.
///
/// Supports global ([addListener]) and typed ([on] / [once]) subscriptions.
/// Error isolation: a failing listener does not affect other listeners.
///
/// Example:
///
/// ```dart
/// final emitter = OZSmartAccountEventEmitter();
///
/// final unsubscribe = emitter.on<OZSmartAccountEventWalletConnected>((event) {
///   print('Connected to ${event.contractId}');
/// });
///
/// final unsubGlobal = emitter.addListener((event) {
///   if (event is OZSmartAccountEventWalletDisconnected) {
///     print('Disconnected from ${event.contractId}');
///   }
/// });
///
/// emitter.once<OZSmartAccountEventTransactionSubmitted>((event) {
///   print('First transaction: ${event.hash}');
/// });
///
/// unsubscribe();
/// ```
class OZSmartAccountEventEmitter {
  OZSmartAccountEventEmitter();

  // why: Single-isolate concurrency model — all state mutation runs on Dart's
  // main isolate, which gives single-threaded mutation safety without an
  // explicit mutex. emit() snapshots both listener collections before dispatch
  // so a listener that calls addListener / on / removeAllListeners during its
  // callback cannot mutate the iteration target. Do not introduce an `await`
  // inside emit's dispatch loop without first introducing an explicit lock —
  // suspending mid-dispatch breaks this single-threaded invariant.
  final Map<String, List<OZSmartAccountEventListener>> _listeners = {};
  final List<OZSmartAccountEventListener> _globalListeners = [];
  OZSmartAccountEventErrorHandler? _errorHandler;

  /// Sets the error handler invoked when a listener throws.
  ///
  /// The handler receives the event being dispatched together with the error
  /// and stack trace produced by the failing listener. Pass `null` to
  /// disable error reporting; thrown errors are then silently caught so a
  /// single failing listener cannot affect other listeners.
  void setErrorHandler(OZSmartAccountEventErrorHandler? handler) {
    _errorHandler = handler;
  }

  /// Subscribes a global [listener] that receives every emitted event.
  ///
  /// Returns an idempotent unsubscribe function. Calling it more than once is
  /// safe and removes only the registration created by this `addListener`
  /// call.
  void Function() addListener(OZSmartAccountEventListener listener) {
    _globalListeners.add(listener);
    return () {
      _globalListeners.remove(listener);
    };
  }

  /// Subscribes [listener] to events whose runtime type is [E].
  ///
  /// The returned unsubscribe function removes only this typed registration;
  /// calling it more than once is safe. Type filtering uses Dart's `is` check
  /// so subclass relationships are honoured naturally.
  void Function() on<E extends OZSmartAccountEvent>(
    void Function(E event) listener,
  ) {
    final eventType = _eventTypeNameFor<E>();
    OZSmartAccountEventListener? wrapper;
    wrapper = (event) {
      if (event is E) {
        listener(event);
      }
    };
    _addTypedListener(eventType, wrapper);
    return () {
      final captured = wrapper;
      if (captured != null) {
        _removeTypedListener(eventType, captured);
      }
    };
  }

  /// Subscribes [listener] to a single occurrence of an event of type [E].
  ///
  /// After the first matching event the listener is auto-unsubscribed. The
  /// returned function may also be called manually to cancel the
  /// subscription before any event fires.
  void Function() once<E extends OZSmartAccountEvent>(
    void Function(E event) listener,
  ) {
    late void Function() unsubscribe;
    var fired = false;
    unsubscribe = on<E>((event) {
      if (fired) {
        return;
      }
      fired = true;
      // why: unsubscribe before invoking the user listener so a thrown
      // listener still releases its registration; verified by the
      // throws-on-first-event auto-unsubscribe behaviour.
      unsubscribe();
      listener(event);
    });
    return unsubscribe;
  }

  /// Removes registered listeners.
  ///
  /// When [eventType] is supplied, only typed listeners for that name are
  /// removed; global listeners registered via [addListener] are left intact.
  /// When [eventType] is `null`, both typed and global listeners are
  /// removed.
  void removeAllListeners([String? eventType]) {
    if (eventType != null) {
      // why: typed-only removal preserves global listeners; passing null is
      // the explicit opt-in to clear global registrations as well.
      _listeners.remove(eventType);
    } else {
      _listeners.clear();
      _globalListeners.clear();
    }
  }

  /// Returns the number of registered listeners for [eventType].
  ///
  /// The count includes both typed listeners registered via [on] / [once]
  /// and global listeners registered via [addListener].
  int listenerCount(String eventType) {
    final typed = _listeners[eventType]?.length ?? 0;
    return typed + _globalListeners.length;
  }

  /// Dispatches [event] to all matching listeners.
  ///
  /// Typed listeners registered for the event's runtime type and every
  /// global listener registered via [addListener] are invoked. Listener
  /// snapshots are taken before iteration so a listener that mutates the
  /// emitter (for example by self-unsubscribing) does not affect the
  /// in-flight dispatch.
  ///
  /// Listener errors are routed to the error handler when one is set;
  /// otherwise they are silently caught so a single failing listener cannot
  /// affect other listeners.
  ///
  /// This method is intended for use by the Smart Account Kit's operation
  /// modules.
  void emit(OZSmartAccountEvent event) {
    final eventType = event.eventTypeName;
    // why: snapshot listeners before dispatch so a listener that calls
    // addListener / on / removeAllListeners during its callback cannot
    // mutate the iteration target. Global listeners are appended after the
    // typed snapshot so emission order matches subscription category.
    final snapshot = <OZSmartAccountEventListener>[];
    final typed = _listeners[eventType];
    if (typed != null && typed.isNotEmpty) {
      snapshot.addAll(typed);
    }
    if (_globalListeners.isNotEmpty) {
      snapshot.addAll(_globalListeners);
    }

    for (final listener in snapshot) {
      try {
        listener(event);
      } catch (err, stackTrace) {
        final handler = _errorHandler;
        if (handler != null) {
          handler(event, err, stackTrace);
        }
      }
    }
  }

  void _addTypedListener(
    String eventType,
    OZSmartAccountEventListener listener,
  ) {
    final bucket = _listeners.putIfAbsent(eventType, () => []);
    bucket.add(listener);
  }

  void _removeTypedListener(
    String eventType,
    OZSmartAccountEventListener listener,
  ) {
    final bucket = _listeners[eventType];
    if (bucket == null) {
      return;
    }
    bucket.remove(listener);
    if (bucket.isEmpty) {
      _listeners.remove(eventType);
    }
  }

  // why: keys returned here MUST match OZSmartAccountEvent subclass eventTypeName
  // values exactly. emit() looks up listener buckets by event.eventTypeName at
  // dispatch time; on<E> and once<E> register listeners under the bucket key
  // returned here. A drift between the two sources of truth (e.g. renaming an
  // arm's eventTypeName getter without updating this helper) produces silent
  // dead listeners — typed listeners land in a bucket the emitter never reads.
  // When adding a new OZSmartAccountEvent arm, update both: the arm's
  // eventTypeName override AND this helper's mapping.
  static String _eventTypeNameFor<E extends OZSmartAccountEvent>() {
    if (E == OZSmartAccountEventWalletConnected) {
      return 'WalletConnected';
    }
    if (E == OZSmartAccountEventWalletDisconnected) {
      return 'WalletDisconnected';
    }
    if (E == OZSmartAccountEventCredentialCreated) {
      return 'CredentialCreated';
    }
    if (E == OZSmartAccountEventCredentialDeleted) {
      return 'CredentialDeleted';
    }
    if (E == OZSmartAccountEventCredentialSyncFailed) {
      return 'CredentialSyncFailed';
    }
    if (E == OZSmartAccountEventSessionExpired) {
      return 'SessionExpired';
    }
    if (E == OZSmartAccountEventTransactionSigned) {
      return 'TransactionSigned';
    }
    if (E == OZSmartAccountEventTransactionSubmitted) {
      return 'TransactionSubmitted';
    }
    return E.toString();
  }
}
