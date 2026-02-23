# Horizon API Reference

The `StellarSDK` class is the main entry point for all Horizon REST API queries. Each property returns a fresh request builder with a fluent API.
For method signatures on response objects, see [API Reference](./api_reference.md).

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
```

## Common Query Methods

All request builders extend `RequestBuilder` and share these pagination methods:

```dart
builder.cursor(String token);                  // pagination cursor
builder.limit(int number);                     // max records (default 10, max 200)
builder.order(RequestBuilderOrder direction);   // ASC or DESC
```

Results are returned as `Page<T>` objects:

```dart
class Page<T> {
  List<T> records;   // list of result objects
  Links links;       // next, prev, self URIs
}
```

## Accounts

`sdk.accounts` returns `AccountsRequestBuilder`.

```dart
// Get single account
AccountResponse account = await sdk.accounts.account(accountId);
print('Sequence: ${account.sequenceNumber}');
print('Balances: ${account.balances.length}');

// Get account data entry
AccountDataResponse data = await sdk.accounts.accountData(accountId, 'my_key');

// Access account data entries (limited Map API)
// WRONG: account.data.containsKey('key') -- containsKey() does NOT exist
// WRONG: account.data.entries -- entries getter does NOT exist
// CORRECT: use keys.contains() and iterate keys
if (account.data.keys.contains('my_key')) {
  Uint8List decoded = account.data.getDecoded('my_key');
}

// Filter accounts
Page<AccountResponse> page = await sdk.accounts
    .forSigner(signerAccountId)
    .limit(20)
    .execute();

Page<AccountResponse> page = await sdk.accounts
    .forAsset(AssetTypeCreditAlphaNum4('USD', issuerAccountId))
    .execute();

Page<AccountResponse> page = await sdk.accounts
    .forSponsor(sponsorAccountId)
    .execute();

Page<AccountResponse> page = await sdk.accounts
    .forLiquidityPool(poolId)
    .execute();
```

**AccountResponse key fields:**

| Field | Type | Description |
|-------|------|-------------|
| `accountId` | String | G... public key |
| `sequenceNumber` | BigInt | Current sequence number |
| `balances` | List\<Balance\> | All asset balances |
| `signers` | List\<Signer\> | Account signers with weights |
| `thresholds` | Thresholds | low, med, high thresholds |
| `flags` | Flags | authRequired, authRevocable, authImmutable, authClawbackEnabled |
| `data` | Map\<String, String\> | Key-value data entries |
| `sponsor` | String? | Sponsoring account ID |
| `homeDomain` | String? | Federation home domain |
| `subentryCount` | int | Number of sub-entries |

**Balance fields:** `assetType`, `assetCode`, `assetIssuer`, `balance`, `limit`, `buyingLiabilities`, `sellingLiabilities`, `isAuthorized`, `isClawbackEnabled`, `liquidityPoolId`, `sponsor`.

## Transactions

`sdk.transactions` returns `TransactionsRequestBuilder`.

```dart
// Get single transaction by hash
TransactionResponse tx = await sdk.transactions.transaction(txHash);
print('Fee charged: ${tx.feeCharged}');
print('Successful: ${tx.successful}');
// WRONG: tx.memoType -- TransactionResponse does NOT have memoType
// CORRECT: tx.memo returns a Memo? object (MemoText, MemoHash, etc.)

// Query transactions for an account
Page<TransactionResponse> txs = await sdk.transactions
    .forAccount(accountId)
    .order(RequestBuilderOrder.DESC)
    .limit(10)
    .execute();

// Inspect transaction memos
for (var tx in txs.records) {
  print('Transaction: ${tx.hash}');
  
  // Check memo type and extract value
  Memo? memo = tx.memo;
  if (memo != null && memo is! MemoNone) {
    if (memo is MemoText) {
      print('  Memo (text): ${memo.text}');
    } else if (memo is MemoId) {
      print('  Memo (id): ${memo.getId()}');
    } else if (memo is MemoHash) {
      print('  Memo (hash): ${memo.hexValue}');
    } else if (memo is MemoReturnHash) {
      print('  Memo (return): ${memo.hexValue}');
    }
  }
}

// Include failed transactions
Page<TransactionResponse> allTxs = await sdk.transactions
    .forAccount(accountId)
    .includeFailed(true)
    .execute();

// Filter by ledger, claimable balance, or liquidity pool
await sdk.transactions.forLedger(12345).execute();
await sdk.transactions.forClaimableBalance(balanceId).execute();
await sdk.transactions.forLiquidityPool(poolId).execute();
```

### Submitting Transactions

```dart
// Synchronous submit (waits for ledger inclusion)
SubmitTransactionResponse response = await sdk.submitTransaction(transaction);
if (response.success) {
  print('Hash: ${response.hash}');
  print('Ledger: ${response.ledger}');
}

// Fee bump transaction
SubmitTransactionResponse response = await sdk.submitFeeBumpTransaction(feeBumpTx);

// Asynchronous submit (returns immediately with status)
SubmitAsyncTransactionResponse asyncResponse =
    await sdk.submitAsyncTransaction(transaction);
print('Status: ${asyncResponse.txStatus}');  // PENDING, DUPLICATE, TRY_AGAIN_LATER, ERROR

// Submit from raw XDR
await sdk.submitTransactionEnvelopeXdrBase64(xdrBase64String);

// Poll for result after async submission
if (asyncResponse.txStatus == SubmitAsyncTransactionResponse.txStatusPending) {
  await Future.delayed(Duration(seconds: 5));
  try {
    TransactionResponse tx = await sdk.transactions.transaction(asyncResponse.hash);
    print('Confirmed in ledger: ${tx.ledger}');
  } on ErrorResponse catch (e) {
    if (e.code == 404) { /* not yet ingested — retry later */ }
  }
}
```

### Fee Bump Transaction Response

When querying a fee bump transaction, `TransactionResponse` includes both the outer and inner transaction details:

```dart
TransactionResponse tx = await sdk.transactions.transaction(feeBumpHash);

// Inner (original) transaction details
InnerTransaction? inner = tx.innerTransaction;
if (inner != null) {
  print('Inner TX hash: ${inner.hash}');
  print('Inner TX max fee: ${inner.maxFee}');
}

// Fee bump wrapper details
FeeBumpTransactionResponse? feeBump = tx.feeBumpTransaction;
if (feeBump != null) {
  print('Fee bump hash: ${feeBump.hash}');
}
```

## Operations

`sdk.operations` returns `OperationsRequestBuilder`.

```dart
// Get single operation
OperationResponse op = await sdk.operations.operation(operationId);

// Query operations with filters
Page<OperationResponse> ops = await sdk.operations
    .forAccount(accountId)
    .order(RequestBuilderOrder.DESC)
    .limit(25)
    .execute();

await sdk.operations.forLedger(12345).execute();
await sdk.operations.forTransaction(txHash).execute();
await sdk.operations.forClaimableBalance(balanceId).execute();
await sdk.operations.forLiquidityPool(poolId).execute();

// Include failed operations
await sdk.operations.forAccount(accountId).includeFailed(true).execute();

// Join transactions
await sdk.operations.forAccount(accountId).join('transactions').execute();
```

## Payments

`sdk.payments` returns `PaymentsRequestBuilder`. Returns payment-type operations (payment, create_account, path_payment, account_merge).

```dart
Page<OperationResponse> payments = await sdk.payments
    .forAccount(accountId)
    .order(RequestBuilderOrder.DESC)
    .limit(10)
    .execute();

// Type-check responses
for (OperationResponse op in payments.records) {
  if (op is PaymentOperationResponse) {
    print('Payment: ${op.amount} ${op.assetCode ?? "XLM"}');
    print('From: ${op.from}');
    print('To: ${op.to}');
  } else if (op is CreateAccountOperationResponse) {
    print('Account created: ${op.account}');
  } else if (op is AccountMergeOperationResponse) {
    print('Account merged into: ${op.into}');
  }
}

// Filter by ledger or transaction
await sdk.payments.forLedger(12345).execute();
await sdk.payments.forTransaction(txHash).execute();
```

## Ledgers

`sdk.ledgers` returns `LedgersRequestBuilder`.

```dart
// Get single ledger
LedgerResponse ledger = await sdk.ledgers.ledger(12345);
print('Closed at: ${ledger.closedAt}');
print('Transaction count: ${ledger.successfulTransactionCount}');
// WRONG: ledger.baseFee, ledger.baseReserve -- these fields do NOT exist
// CORRECT: ledger.baseFeeInStroops, ledger.baseReserveInStroops (int values)

// List ledgers
Page<LedgerResponse> ledgers = await sdk.ledgers
    .order(RequestBuilderOrder.DESC)
    .limit(10)
    .execute();
```

## Effects

`sdk.effects` returns `EffectsRequestBuilder`.

```dart
Page<EffectResponse> effects = await sdk.effects
    .forAccount(accountId)
    .limit(20)
    .execute();

// Filter by ledger, operation, transaction, or liquidity pool
await sdk.effects.forLedger(12345).execute();
await sdk.effects.forOperation(operationId).execute();
await sdk.effects.forTransaction(txHash).execute();
await sdk.effects.forLiquidityPool(poolId).execute();
```

## Offers

`sdk.offers` returns `OffersRequestBuilder`.

```dart
// Get single offer
OfferResponse offer = await sdk.offers.offer(offerId);

// Filter offers
Page<OfferResponse> offers = await sdk.offers
    .forAccount(accountId)
    .execute();

// Filter by buying/selling asset, seller, or sponsor
await sdk.offers.forBuyingAsset(usdAsset).execute();
await sdk.offers.forSellingAsset(Asset.NATIVE).execute();
await sdk.offers.forSeller(sellerAccountId).execute();
await sdk.offers.forSponsor(sponsorAccountId).execute();
```

## Order Book

`sdk.orderBook` returns `OrderBookRequestBuilder`.

Query parameters define the market from the **offer creator's perspective**:
- `sellingAsset` = what offers are SELLING
- `buyingAsset` = what offers want to BUY

```dart
// Example: Query the USD/XLM market (USD priced in XLM)
OrderBookResponse orderBook = await sdk.orderBook
    .sellingAsset(AssetTypeCreditAlphaNum4('USD', issuerAccountId))
    .buyingAsset(Asset.NATIVE)  // XLM
    .execute();

// Asks: offers selling USD (asking for XLM)
for (var ask in orderBook.asks) {
  print('Ask: ${ask.amount} USD @ ${ask.price} XLM each');
}

// Bids: offers buying USD (bidding with XLM) 
for (var bid in orderBook.bids) {
  print('Bid: ${bid.amount} USD @ ${bid.price} XLM each');
}
```

## Trades

`sdk.trades` returns `TradesRequestBuilder`.

```dart
Page<TradeResponse> trades = await sdk.trades
    .forAccount(accountId)
    .execute();

// Filter by offer or liquidity pool
await sdk.trades.offerId(offerId).execute();
await sdk.trades.liquidityPoolId(poolId).execute();

// Filter by base/counter asset pair
await sdk.trades.baseAsset(Asset.NATIVE).counterAsset(usdAsset).execute();

// Trade aggregations (OHLCV candlestick data)
Page<TradeAggregationResponse> candles = await sdk.tradeAggregations(
  Asset.NATIVE,                                          // base asset
  AssetTypeCreditAlphaNum4('USD', issuerAccountId),     // counter asset
  1609459200000,                                         // start time (ms)
  1609545600000,                                         // end time (ms)
  3600000,                                               // resolution (ms, 1 hour)
  0,                                                     // offset
).execute();
```

## Assets

`sdk.assets` returns `AssetsRequestBuilder`.

```dart
Page<AssetResponse> assets = await sdk.assets
    .assetCode('USD')
    .assetIssuer(issuerAccountId)
    .execute();
```

## Claimable Balances

`sdk.claimableBalances` returns `ClaimableBalancesRequestBuilder`.

```dart
// Get single claimable balance
ClaimableBalanceResponse balance =
    await sdk.claimableBalances.claimableBalance(balanceId);

// Filter claimable balances
Page<ClaimableBalanceResponse> page =
    await sdk.claimableBalances.forClaimant(claimantAccountId).execute();
// WRONG: page.records.first.id -- ClaimableBalanceResponse does NOT have .id
// CORRECT: page.records.first.balanceId -- returns the balance ID string
String balanceId = page.records.first.balanceId;

await sdk.claimableBalances.forAsset(usdAsset).execute();
await sdk.claimableBalances.forSponsor(sponsorAccountId).execute();
```

## Liquidity Pools

`sdk.liquidityPools` returns `LiquidityPoolsRequestBuilder`.

```dart
// Get single pool
LiquidityPoolResponse pool =
    await sdk.liquidityPools.liquidityPool(poolId);

// Filter by reserve assets
Page<LiquidityPoolResponse> pools = await sdk.liquidityPools
    .forReserveAssets([Asset.NATIVE, usdAsset])
    .execute();
```

## Path Finding

```dart
// Strict receive: find paths to receive exact amount
Page<PathResponse> paths = await sdk.strictReceivePaths
    .destinationAsset(usdAsset)
    .destinationAmount('100.0')
    .sourceAccount(senderAccountId)
    .execute();

// Strict send: find paths sending exact amount
Page<PathResponse> paths = await sdk.strictSendPaths
    .sourceAsset(Asset.NATIVE)
    .sourceAmount('50.0')
    .destinationAssets([usdAsset])
    .execute();
```

## Fee Stats

```dart
FeeStatsResponse feeStats = await sdk.feeStats.execute();
print('Base fee: ${feeStats.lastLedgerBaseFee}');
print('Capacity: ${feeStats.lastLedgerCapacityUsage}');

// Fee charged and max fee have percentile breakdowns (min, mode, p10-p99)
print('Fee charged (min): ${feeStats.feeCharged.min}');
print('Fee charged (mode): ${feeStats.feeCharged.mode}');
print('Fee charged (p50): ${feeStats.feeCharged.p50}');
print('Fee charged (p99): ${feeStats.feeCharged.p99}');

print('Max fee (min): ${feeStats.maxFee.min}');
print('Max fee (p99): ${feeStats.maxFee.p99}');
```

## Health Check

```dart
HealthResponse health = await sdk.health.execute();
```

## Root

```dart
RootResponse root = await sdk.root();
print('Horizon version: ${root.horizonVersion}');
print('Core version: ${root.stellarCoreVersion}');
```

## Pagination

Navigate through paginated results using the `Page` object.

```dart
// First page
Page<TransactionResponse> page = await sdk.transactions
    .forAccount(accountId)
    .order(RequestBuilderOrder.DESC)
    .limit(10)
    .execute();

// Process records
for (var tx in page.records) {
  print('TX: ${tx.hash}');
}

// Fetch next page using the page links
// Re-execute with cursor from last record
if (page.records.isNotEmpty) {
  Page<TransactionResponse> nextPage = await sdk.transactions
      .forAccount(accountId)
      .order(RequestBuilderOrder.DESC)
      .limit(10)
      .cursor(page.records.last.pagingToken)
      .execute();
}
```

## Error Handling

For error handling patterns (Horizon HTTP errors, transaction submission errors, rate limiting), see [Troubleshooting Guide](./troubleshooting.md).
