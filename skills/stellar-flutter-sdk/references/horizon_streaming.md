# Horizon API - Streaming

Complete guide to Horizon streaming (Server-Sent Events) with the Stellar Flutter SDK.

All code examples assume `import 'dart:async';` and `import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';`.

## Overview

Horizon supports real-time updates via Server-Sent Events (SSE). The SDK wraps SSE connections as Dart `Stream` objects using a custom `EventSource` implementation. Streams automatically reconnect with exponential backoff on connection loss.

## Basic Streaming Pattern

Every streaming-capable request builder exposes a `stream()` method that returns a typed Dart `Stream`. Use `cursor("now")` to receive only new events. Always store the `StreamSubscription` to cancel later.

```dart
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
| `sdk.trades` | `TradeResponse` | No |
| `sdk.orderBook` | `OrderBookResponse` | No (requires `sellingAsset`/`buyingAsset`) |

### Stream Transactions (network-wide and per-account)

```dart
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
    // The SDK reconnects automatically via EventSource retry logic
  });
}

void stopPaymentStream() {
  subscription?.cancel();
  subscription = null;
}
```

## Reconnection Behavior

The SDK handles reconnection automatically through the `EventSource` class:

1. On connection close, the `stream()` method detects the "close" event and creates a new `EventSource` connection.
2. On parse errors, the stream reconnects by creating a fresh `EventSource`.
3. `EventSource` itself retries with exponential backoff starting at 3 seconds.
4. The `Last-Event-ID` header is sent on reconnection for server-side cursor tracking.

You do not need to implement manual reconnection. The SDK reconnects transparently.

## Error Handling

Stream errors are delivered through the `onError` callback. Common errors:

- `EventSourceSubscriptionException` -- initial connection failed (contains HTTP status code and message)
- Parse errors -- malformed event data (stream auto-reconnects)
- Network errors -- transient connection failures (auto-reconnected by `EventSource`)

```dart
StreamSubscription<OperationResponse> sub = sdk.payments
    .forAccount(accountId)
    .cursor('now')
    .stream()
    .listen(
  (OperationResponse response) { /* handle */ },
  onError: (error) {
    if (error is EventSourceSubscriptionException) {
      print('Subscription failed: ${error.statusCode} ${error.message}');
    } else {
      print('Stream error: $error');
    }
  },
);
```

## Resource Cleanup

Always cancel stream subscriptions when no longer needed. In Flutter widgets, cancel in `dispose()`:

```dart
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
