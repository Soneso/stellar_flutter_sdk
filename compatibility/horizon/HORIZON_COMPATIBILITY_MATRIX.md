# Horizon API vs Flutter SDK Compatibility Matrix

**Horizon Version:** v26.0.0 (released unknown)  
**Horizon Source:** [v26.0.0](https://github.com/stellar/stellar-horizon/releases/tag/v26.0.0)  
**SDK Version:** 3.0.5  
**Generated:** 2026-04-08 23:12:28

**Horizon Endpoints Discovered:** 52  
**Public API Endpoints (in matrix):** 50

> **Note:** 2 endpoints are intentionally excluded from the matrix:
> - `GET /paths` - Deprecated (replaced by `/paths/strict-receive` and `/paths/strict-send`)
> - `POST /friendbot` - Redundant (GET method is used instead)

## Overall Coverage

**Coverage:** 100.0% (50/50 public API endpoints)

- ✅ **Fully Supported:** 50/50
- ⚠️ **Partially Supported:** 0/50
- ❌ **Not Supported:** 0/50
- 🔄 **Deprecated:** 0/50

## Coverage by Category

| Category | Coverage | Supported | Not Supported | Total |
|----------|----------|-----------|---------------|-------|
| root | 100.0% | 1 | 0 | 1 |
| accounts | 100.0% | 9 | 0 | 9 |
| assets | 100.0% | 1 | 0 | 1 |
| claimable_balances | 100.0% | 4 | 0 | 4 |
| effects | 100.0% | 1 | 0 | 1 |
| fee_stats | 100.0% | 1 | 0 | 1 |
| friendbot | 100.0% | 1 | 0 | 1 |
| health | 100.0% | 1 | 0 | 1 |
| ledgers | 100.0% | 6 | 0 | 6 |
| liquidity_pools | 100.0% | 6 | 0 | 6 |
| offers | 100.0% | 3 | 0 | 3 |
| operations | 100.0% | 3 | 0 | 3 |
| order_book | 100.0% | 1 | 0 | 1 |
| paths | 100.0% | 2 | 0 | 2 |
| payments | 100.0% | 1 | 0 | 1 |
| trade_aggregations | 100.0% | 1 | 0 | 1 |
| trades | 100.0% | 1 | 0 | 1 |
| transactions | 100.0% | 6 | 0 | 6 |
| transactions_async | 100.0% | 1 | 0 | 1 |

## Streaming Support

**Coverage:** 100.0%

- Streaming endpoints: 29
- Supported: 29

## Detailed Endpoint Comparison

### Root

| Endpoint | Method | Status | SDK Method | Streaming | Notes |
|----------|--------|--------|------------|-----------|-------|
| `/` | GET | ✅ | `root` |  | Full implementation with all features supported. Implemented via root() method |

### Accounts

| Endpoint | Method | Status | SDK Method | Streaming | Notes |
|----------|--------|--------|------------|-----------|-------|
| `/accounts` | GET | ✅ | `accounts` | ✓ | Full implementation with all features supported. Implemented via AccountsRequestBuilder |
| `/accounts/{account_id}` | GET | ✅ | `accounts.account` | ✓ | Full implementation with all features supported. Implemented via AccountsRequestBuilder |
| `/accounts/{account_id}/data/{key}` | GET | ✅ | `accounts.accountData` | ✓ | Full implementation with all features supported. Implemented via AccountsRequestBuilder |
| `/accounts/{account_id}/effects` | GET | ✅ | `effects.forAccount` | ✓ | Full implementation with all features supported. Implemented via EffectsRequestBuilder |
| `/accounts/{account_id}/offers` | GET | ✅ | `offers.forAccount` | ✓ | Full implementation with all features supported. Implemented via OffersRequestBuilder |
| `/accounts/{account_id}/operations` | GET | ✅ | `operations.forAccount` | ✓ | Full implementation with all features supported. Implemented via OperationsRequestBuilder |
| `/accounts/{account_id}/payments` | GET | ✅ | `payments.forAccount` | ✓ | Full implementation with all features supported. Implemented via PaymentsRequestBuilder |
| `/accounts/{account_id}/trades` | GET | ✅ | `trades.forAccount` | ✓ | Full implementation with all features supported. Implemented via TradesRequestBuilder |
| `/accounts/{account_id}/transactions` | GET | ✅ | `transactions.forAccount` | ✓ | Full implementation with all features supported. Implemented via TransactionsRequestBuilder |

### Assets

| Endpoint | Method | Status | SDK Method | Streaming | Notes |
|----------|--------|--------|------------|-----------|-------|
| `/assets` | GET | ✅ | `assets` |  | Full implementation with all features supported. Implemented via AssetsRequestBuilder |

### Claimable_Balances

| Endpoint | Method | Status | SDK Method | Streaming | Notes |
|----------|--------|--------|------------|-----------|-------|
| `/claimable_balances` | GET | ✅ | `claimableBalances` |  | Full implementation with all features supported. Implemented via ClaimableBalancesRequestBuilder |
| `/claimable_balances/{claimable_balance_id}` | GET | ✅ | `claimableBalances.claimableBalance` |  | Full implementation with all features supported. Implemented via ClaimableBalancesRequestBuilder |
| `/claimable_balances/{claimable_balance_id}/operations` | GET | ✅ | `operations.forClaimableBalance` | ✓ | Full implementation with all features supported. Implemented via OperationsRequestBuilder |
| `/claimable_balances/{claimable_balance_id}/transactions` | GET | ✅ | `transactions.forClaimableBalance` | ✓ | Full implementation with all features supported. Implemented via TransactionsRequestBuilder |

### Effects

| Endpoint | Method | Status | SDK Method | Streaming | Notes |
|----------|--------|--------|------------|-----------|-------|
| `/effects` | GET | ✅ | `effects` | ✓ | Full implementation with all features supported. Implemented via EffectsRequestBuilder |

### Fee_Stats

| Endpoint | Method | Status | SDK Method | Streaming | Notes |
|----------|--------|--------|------------|-----------|-------|
| `/fee_stats` | GET | ✅ | `feeStats` |  | Full implementation with all features supported. Implemented via FeeStatsRequestBuilder |

### Friendbot

| Endpoint | Method | Status | SDK Method | Streaming | Notes |
|----------|--------|--------|------------|-----------|-------|
| `/friendbot` | GET | ✅ | `FriendBot.fundTestAccount` |  | Full implementation with all features supported. Implemented via FriendBot.fundTestAccount() method. Testnet/Futurenet only |

### Health

| Endpoint | Method | Status | SDK Method | Streaming | Notes |
|----------|--------|--------|------------|-----------|-------|
| `/health` | GET | ✅ | `health` |  | Full implementation with all features supported. Implemented via HealthRequestBuilder |

### Ledgers

| Endpoint | Method | Status | SDK Method | Streaming | Notes |
|----------|--------|--------|------------|-----------|-------|
| `/ledgers` | GET | ✅ | `ledgers` | ✓ | Full implementation with all features supported. Implemented via LedgersRequestBuilder |
| `/ledgers/{ledger_id}` | GET | ✅ | `ledgers.ledger` | ✓ | Full implementation with all features supported. Implemented via LedgersRequestBuilder |
| `/ledgers/{ledger_id}/effects` | GET | ✅ | `effects.forLedger` | ✓ | Full implementation with all features supported. Implemented via EffectsRequestBuilder |
| `/ledgers/{ledger_id}/operations` | GET | ✅ | `operations.forLedger` | ✓ | Full implementation with all features supported. Implemented via OperationsRequestBuilder |
| `/ledgers/{ledger_id}/payments` | GET | ✅ | `payments.forLedger` | ✓ | Full implementation with all features supported. Implemented via PaymentsRequestBuilder |
| `/ledgers/{ledger_id}/transactions` | GET | ✅ | `transactions.forLedger` | ✓ | Full implementation with all features supported. Implemented via TransactionsRequestBuilder |

### Liquidity_Pools

| Endpoint | Method | Status | SDK Method | Streaming | Notes |
|----------|--------|--------|------------|-----------|-------|
| `/liquidity_pools` | GET | ✅ | `liquidityPools` |  | Full implementation with all features supported. Implemented via LiquidityPoolsRequestBuilder |
| `/liquidity_pools/{liquidity_pool_id}` | GET | ✅ | `liquidityPools.liquidityPool` |  | Full implementation with all features supported. Implemented via LiquidityPoolsRequestBuilder |
| `/liquidity_pools/{liquidity_pool_id}/effects` | GET | ✅ | `effects.forLiquidityPool` | ✓ | Full implementation with all features supported. Implemented via EffectsRequestBuilder |
| `/liquidity_pools/{liquidity_pool_id}/operations` | GET | ✅ | `operations.forLiquidityPool` | ✓ | Full implementation with all features supported. Implemented via OperationsRequestBuilder |
| `/liquidity_pools/{liquidity_pool_id}/trades` | GET | ✅ | `trades.liquidityPoolId` | ✓ | Full implementation with all features supported. Fully supported via TradesRequestBuilder.liquidityPoolId() |
| `/liquidity_pools/{liquidity_pool_id}/transactions` | GET | ✅ | `transactions.forLiquidityPool` | ✓ | Full implementation with all features supported. Implemented via TransactionsRequestBuilder |

### Offers

| Endpoint | Method | Status | SDK Method | Streaming | Notes |
|----------|--------|--------|------------|-----------|-------|
| `/offers` | GET | ✅ | `offers` | ✓ | Full implementation with all features supported. Implemented via OffersRequestBuilder |
| `/offers/{offer_id}` | GET | ✅ | `offers.offer` | ✓ | Full implementation with all features supported. Implemented via OffersRequestBuilder |
| `/offers/{offer_id}/trades` | GET | ✅ | `offers.forOffer` | ✓ | Full implementation with all features supported. Implemented via OffersRequestBuilder |

### Operations

| Endpoint | Method | Status | SDK Method | Streaming | Notes |
|----------|--------|--------|------------|-----------|-------|
| `/operations` | GET | ✅ | `operations` | ✓ | Full implementation with all features supported. Implemented via OperationsRequestBuilder |
| `/operations/{operation_id}` | GET | ✅ | `operations.operation` | ✓ | Full implementation with all features supported. Implemented via OperationsRequestBuilder |
| `/operations/{operation_id}/effects` | GET | ✅ | `effects.forOperation` | ✓ | Full implementation with all features supported. Implemented via EffectsRequestBuilder |

### Order_Book

| Endpoint | Method | Status | SDK Method | Streaming | Notes |
|----------|--------|--------|------------|-----------|-------|
| `/order_book` | GET | ✅ | `orderBook` | ✓ | Full implementation with all features supported. Implemented via OrderBookRequestBuilder |

### Paths

| Endpoint | Method | Status | SDK Method | Streaming | Notes |
|----------|--------|--------|------------|-----------|-------|
| `/paths/strict-receive` | GET | ✅ | `strictReceivePaths` |  | Full implementation with all features supported. Implemented via StrictReceivePathsRequestBuilder |
| `/paths/strict-send` | GET | ✅ | `strictSendPaths` |  | Full implementation with all features supported. Implemented via StrictSendPathsRequestBuilder |

### Payments

| Endpoint | Method | Status | SDK Method | Streaming | Notes |
|----------|--------|--------|------------|-----------|-------|
| `/payments` | GET | ✅ | `payments` | ✓ | Full implementation with all features supported. Implemented via PaymentsRequestBuilder |

### Trade_Aggregations

| Endpoint | Method | Status | SDK Method | Streaming | Notes |
|----------|--------|--------|------------|-----------|-------|
| `/trade_aggregations` | GET | ✅ | `tradeAggregations` |  | Full implementation with all features supported. Implemented via TradeAggregationsRequestBuilder |

### Trades

| Endpoint | Method | Status | SDK Method | Streaming | Notes |
|----------|--------|--------|------------|-----------|-------|
| `/trades` | GET | ✅ | `trades` | ✓ | Full implementation with all features supported. Implemented via TradesRequestBuilder |

### Transactions

| Endpoint | Method | Status | SDK Method | Streaming | Notes |
|----------|--------|--------|------------|-----------|-------|
| `/transactions` | GET | ✅ | `transactions` | ✓ | Full implementation with all features supported. Implemented via TransactionsRequestBuilder |
| `/transactions` | POST | ✅ | `submitTransactionEnvelopeXdrBase64` |  | Full implementation with all features supported. Implemented via submitTransactionEnvelopeXdrBase64() method |
| `/transactions/{transaction_id}` | GET | ✅ | `transactions.transaction` | ✓ | Full implementation with all features supported. Implemented via TransactionsRequestBuilder |
| `/transactions/{transaction_id}/effects` | GET | ✅ | `effects.forTransaction` | ✓ | Full implementation with all features supported. Implemented via EffectsRequestBuilder |
| `/transactions/{transaction_id}/operations` | GET | ✅ | `operations.forTransaction` | ✓ | Full implementation with all features supported. Implemented via OperationsRequestBuilder |
| `/transactions/{transaction_id}/payments` | GET | ✅ | `payments.forTransaction` | ✓ | Full implementation with all features supported. Implemented via PaymentsRequestBuilder |

### Transactions_Async

| Endpoint | Method | Status | SDK Method | Streaming | Notes |
|----------|--------|--------|------------|-----------|-------|
| `/transactions_async` | POST | ✅ | `submitAsyncTransactionEnvelopeXdrBase64` |  | Full implementation with all features supported. Implemented via submitAsyncTransactionEnvelopeXdrBase64() method |

## Legend

- ✅ **Fully Supported**: Complete implementation with all features
- ⚠️ **Partially Supported**: Basic functionality with some limitations
- ❌ **Not Supported**: Endpoint not implemented
- 🔄 **Deprecated**: Deprecated endpoint with alternative available
