# Horizon API - Streaming

Complete guide to Horizon streaming (Server-Sent Events) with the Stellar Flutter SDK.

All code examples assume `import 'dart:async';` and `import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';`.

## Overview

Horizon supports real-time updates via Server-Sent Events (SSE). The SDK wraps SSE connections as Dart `Stream` objects using a custom `EventSource` implementation. It opens a new connection when Horizon sends its close event or an event fails to parse; the app keeps the position and watches for a dead stream ([Reconnection Behavior](#reconnection-behavior)).

## Basic Streaming Pattern

Every streaming-capable request builder exposes a `stream()` method that returns a typed Dart `Stream`. Use `cursor("now")` to receive only new events. Always store the `StreamSubscription` to cancel later.

```dart
import 'dart:async';

// From your app: accountId (String)
final sdk = StellarSDK.TESTNET;

StreamSubscription<OperationResponse> subscription = sdk.payments
    .forAccount(accountId)
    .cursor('now')
    .stream()
    .listen((OperationResponse response) {
  if (response is PaymentOperationResponse) {
    print('Payment: ${response.amount} ${response.assetCode ?? 'XLM'} from ${response.from}');
  }
}, onError: (error) {
  print('Stream error: $error');
});

// Cancel when done to release resources
// subscription.cancel();
```

The `stream()` method internally creates a broadcast `StreamController`. When you cancel the subscription (and no other listeners remain), the underlying `EventSource` is closed.

## Streamable Resources

All resources follow the same pattern: `sdk.<resource>[.forAccount(id)].cursor('now').stream().listen(...)`.

| Builder | Response Type | Supports `forAccount()` |
|---------|--------------|------------------------|
| `sdk.ledgers` | `LedgerResponse` | No |
| `sdk.transactions` | `TransactionResponse` | Yes |
| `sdk.operations` | `OperationResponse` | Yes |
| `sdk.payments` | `OperationResponse` (type-check subclasses) | Yes |
| `sdk.effects` | `EffectResponse` | Yes |
| `sdk.offers` | `OfferResponse` | Yes |
| `sdk.trades` | `TradeResponse` | Yes |
| `sdk.orderBook` | `OrderBookResponse` | No (requires `sellingAsset`/`buyingAsset`) |

### Stream Transactions (network-wide and per-account)

```dart
import 'dart:async';

// From your app: accountId (String)
final sdk = StellarSDK.TESTNET;

// All new transactions on the network
StreamSubscription<TransactionResponse> sub = sdk.transactions
    .cursor('now')
    .stream()
    .listen((TransactionResponse tx) {
  print('TX ${tx.hash}: ${tx.operationCount} ops');
});

// Transactions for a specific account
StreamSubscription<TransactionResponse> accountSub = sdk.transactions
    .forAccount(accountId)
    .cursor('now')
    .stream()
    .listen((TransactionResponse tx) {
  print('Account TX: ${tx.hash}');
});
```

### Stream Order Book

```dart
import 'dart:async';

// From your app: issuerId (String)
final sdk = StellarSDK.TESTNET;
final Asset selling = AssetTypeNative();
final Asset buying = Asset.createNonNativeAsset('USDC', issuerId);

StreamSubscription<OrderBookResponse> sub = sdk.orderBook
    .sellingAsset(selling)
    .buyingAsset(buying)
    .stream()
    .listen((OrderBookResponse book) {
  print('Bids: ${book.bids?.length}, Asks: ${book.asks?.length}');
});
```

## Cursor Management

Use `cursor("now")` for real-time events, or a saved paging token to resume from a known position:

```dart
import 'dart:async';

// From your app: accountId (String)
final sdk = StellarSDK.TESTNET;
String lastCursor = 'now'; // or load from persistent storage

StreamSubscription<OperationResponse>? subscription;

void startPaymentStream() {
  subscription = sdk.payments
      .forAccount(accountId)
      .cursor(lastCursor)
      .stream()
      .listen((OperationResponse response) {
    lastCursor = response.pagingToken;
    // Persist lastCursor to storage for crash recovery
    if (response is PaymentOperationResponse) {
      print('Payment: ${response.amount}');
    }
  }, onError: (error) {
    print('Stream error: $error');
    // Parse errors arrive here; connection failures do not (see Reconnection Behavior)
  });
}

void stopPaymentStream() {
  subscription?.cancel();
  subscription = null;
}
```

## Reconnection Behavior

The `stream()` method and the `EventSource` class reconnect as follows:

1. When Horizon sends its close event or an event fails to parse, `stream()` opens a new `EventSource` with the same request URI and no last event id. With `cursor('now')` the events between the two connections are lost; with a fixed cursor the new connection starts at that cursor again and repeats events.
2. A transport error inside a connection is not retried: the error escapes the stream as an uncaught asynchronous error, `onError` does not receive it, and no further events arrive. Catch it with `runZonedGuarded` around the subscription or with the app's global error handler, and restart the stream from the last saved paging token.
3. When the HTTP response ends without a close event, the connection stays closed and the stream delivers no further events.

So the app keeps the `pagingToken` of the last event, resumes with `.cursor(lastPagingToken)` as in [Cursor Management](#cursor-management), and treats silence as a possibly dead stream.

## Error Handling

The `onError` callback receives parse errors (malformed event data; the stream then reconnects). A failed connection, for example an HTTP error status when the stream opens, and transport errors do not reach `onError`; they surface as uncaught asynchronous errors. A stream that stops delivering events is detected through silence: restart it from the last paging token after a timeout.

```dart
import 'dart:async';

import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// From your app: savedPagingToken (String)
final StellarSDK sdk = StellarSDK.TESTNET;
// Resume from the saved numeric paging token; repeated events must be handled
// idempotently. Starting with 'now' can miss events during a reconnect.
String lastPagingToken = savedPagingToken;
StreamSubscription<OperationResponse>? subscription;
Timer? silenceTimer;

// Opens the stream at the last seen event and restarts it after two minutes of silence.
void subscribe(String accountId) {
  subscription?.cancel();
  subscription = sdk.payments
      .forAccount(accountId)
      .cursor(lastPagingToken)
      .stream()
      .listen((OperationResponse response) {
    lastPagingToken = response.pagingToken;
    restartSilenceTimer(accountId);
    // handle the payment
  }, onError: (error) {
    print('Stream error: $error'); // parse errors only
  });
  restartSilenceTimer(accountId);
}

// Silence is either a dead connection or an account without new payments;
// resubscribing continues after the last handled paging token in either case.
void restartSilenceTimer(String accountId) {
  silenceTimer?.cancel();
  silenceTimer = Timer(const Duration(minutes: 2), () => subscribe(accountId));
}

void unsubscribe() {
  silenceTimer?.cancel();
  subscription?.cancel();
}
```

## Resource Cleanup

Always cancel stream subscriptions when no longer needed. In Flutter widgets, cancel in `dispose()`:

```dart
import 'dart:async';
import 'package:flutter/widgets.dart';

// From your app: PaymentScreen (class, a StatefulWidget with an accountId field)
class _PaymentScreenState extends State<PaymentScreen> {
  StreamSubscription<OperationResponse>? _subscription;
  final StellarSDK _sdk = StellarSDK.TESTNET;

  @override
  void initState() {
    super.initState();
    _subscription = _sdk.payments
        .forAccount(widget.accountId)
        .cursor('now')
        .stream()
        .listen(_handlePayment);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink(); // the payment list UI

  void _handlePayment(OperationResponse response) {
    if (response is PaymentOperationResponse) {
      setState(() { /* update UI */ });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
```
