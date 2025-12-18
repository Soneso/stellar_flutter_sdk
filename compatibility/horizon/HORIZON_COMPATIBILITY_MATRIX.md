# Horizon API vs Flutter SDK Compatibility Matrix

**Generated:** 2025-12-18 14:04:38

**SDK Version:** 2.2.1

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

| Category | Coverage | Supported | Total |
|----------|----------|-----------|-------|
|  | 100.0% | 1 | 1 |
| accounts | 100.0% | 9 | 9 |
| assets | 100.0% | 1 | 1 |
| claimable_balances | 100.0% | 4 | 4 |
| effects | 100.0% | 1 | 1 |
| fee_stats | 100.0% | 1 | 1 |
| friendbot | 100.0% | 1 | 1 |
| health | 100.0% | 1 | 1 |
| ledgers | 100.0% | 6 | 6 |
| liquidity_pools | 100.0% | 6 | 6 |
| offers | 100.0% | 3 | 3 |
| operations | 100.0% | 3 | 3 |
| order_book | 100.0% | 1 | 1 |
| paths | 100.0% | 2 | 2 |
| payments | 100.0% | 1 | 1 |
| trade_aggregations | 100.0% | 1 | 1 |
| trades | 100.0% | 1 | 1 |
| transactions | 100.0% | 6 | 6 |
| transactions_async | 100.0% | 1 | 1 |

## Streaming Support

**Coverage:** 100.0%

- Streaming endpoints: 29
- Supported: 29

## Detailed Endpoint Comparison

### 

| Endpoint | Method | Status | SDK Method | Streaming | Notes |
|----------|--------|--------|------------|-----------|-------|
| `/` | GET | ✅ | `root` |  | Full implementation with all features supported. Implemented via root() method |

### Accounts

| Endpoint | Method | Status | SDK Method | Streaming | Notes |
|----------|--------|--------|------------|-----------|-------|
| `/accounts` | GET | ✅ | `accounts` | ✓ | Full implementation with all features supported. Implemented via AccountsRequestBuilder |
| `/accounts/{account_id}` | GET | ✅ | `accounts` | ✓ | Full implementation with all features supported. Implemented via AccountsRequestBuilder |
| `/accounts/{account_id}/data/{key}` | GET | ✅ | `accounts` | ✓ | Full implementation with all features supported. Implemented via AccountsRequestBuilder |
| `/accounts/{account_id}/effects` | GET | ✅ | `accounts.effects` | ✓ | Full implementation with all features supported. Implemented via EffectsRequestBuilder |
| `/accounts/{account_id}/offers` | GET | ✅ | `accounts.offers` | ✓ | Full implementation with all features supported. Implemented via OffersRequestBuilder |
| `/accounts/{account_id}/operations` | GET | ✅ | `accounts.operations` | ✓ | Full implementation with all features supported. Implemented via OperationsRequestBuilder |
| `/accounts/{account_id}/payments` | GET | ✅ | `accounts.payments` | ✓ | Full implementation with all features supported. Implemented via PaymentsRequestBuilder |
| `/accounts/{account_id}/trades` | GET | ✅ | `trades` | ✓ | Full implementation with all features supported. Implemented via TradesRequestBuilder |
| `/accounts/{account_id}/transactions` | GET | ✅ | `accounts.transactions` | ✓ | Full implementation with all features supported. Implemented via TransactionsRequestBuilder |

### Assets

| Endpoint | Method | Status | SDK Method | Streaming | Notes |
|----------|--------|--------|------------|-----------|-------|
| `/assets` | GET | ✅ | `assets` |  | Full implementation with all features supported. Implemented via AssetsRequestBuilder |

### Claimable_Balances

| Endpoint | Method | Status | SDK Method | Streaming | Notes |
|----------|--------|--------|------------|-----------|-------|
| `/claimable_balances` | GET | ✅ | `claimableBalances` |  | Full implementation with all features supported. Implemented via ClaimableBalancesRequestBuilder |
| `/claimable_balances/{claimable_balance_id}` | GET | ✅ | `claimableBalances` |  | Full implementation with all features supported. Implemented via ClaimableBalancesRequestBuilder |
| `/claimable_balances/{claimable_balance_id}/operations` | GET | ✅ | `claimableBalances.operations` | ✓ | Full implementation with all features supported. Implemented via OperationsRequestBuilder |
| `/claimable_balances/{claimable_balance_id}/transactions` | GET | ✅ | `claimableBalances.transactions` | ✓ | Full implementation with all features supported. Implemented via TransactionsRequestBuilder |

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
| `/ledgers/{ledger_id}` | GET | ✅ | `ledgers` | ✓ | Full implementation with all features supported. Implemented via LedgersRequestBuilder |
| `/ledgers/{ledger_id}/effects` | GET | ✅ | `ledgers.effects` | ✓ | Full implementation with all features supported. Implemented via EffectsRequestBuilder |
| `/ledgers/{ledger_id}/operations` | GET | ✅ | `ledgers.operations` | ✓ | Full implementation with all features supported. Implemented via OperationsRequestBuilder |
| `/ledgers/{ledger_id}/payments` | GET | ✅ | `ledgers.payments` | ✓ | Full implementation with all features supported. Implemented via PaymentsRequestBuilder |
| `/ledgers/{ledger_id}/transactions` | GET | ✅ | `ledgers.transactions` | ✓ | Full implementation with all features supported. Implemented via TransactionsRequestBuilder |

### Liquidity_Pools

| Endpoint | Method | Status | SDK Method | Streaming | Notes |
|----------|--------|--------|------------|-----------|-------|
| `/liquidity_pools` | GET | ✅ | `liquidityPools` |  | Full implementation with all features supported. Implemented via LiquidityPoolsRequestBuilder |
| `/liquidity_pools/{liquidity_pool_id}` | GET | ✅ | `liquidityPools` |  | Full implementation with all features supported. Implemented via LiquidityPoolsRequestBuilder |
| `/liquidity_pools/{liquidity_pool_id}/effects` | GET | ✅ | `liquidityPools.effects` | ✓ | Full implementation with all features supported. Implemented via EffectsRequestBuilder |
| `/liquidity_pools/{liquidity_pool_id}/operations` | GET | ✅ | `liquidityPools.operations` | ✓ | Full implementation with all features supported. Implemented via OperationsRequestBuilder |
| `/liquidity_pools/{liquidity_pool_id}/trades` | GET | ✅ | `trades` | ✓ | Full implementation with all features supported. Implemented via TradesRequestBuilder |
| `/liquidity_pools/{liquidity_pool_id}/transactions` | GET | ✅ | `liquidityPools.transactions` | ✓ | Full implementation with all features supported. Implemented via TransactionsRequestBuilder |

### Offers

| Endpoint | Method | Status | SDK Method | Streaming | Notes |
|----------|--------|--------|------------|-----------|-------|
| `/offers` | GET | ✅ | `offers` | ✓ | Full implementation with all features supported. Implemented via OffersRequestBuilder |
| `/offers/{offer_id}` | GET | ✅ | `offers` | ✓ | Full implementation with all features supported. Implemented via OffersRequestBuilder |
| `/offers/{offer_id}/trades` | GET | ✅ | `offers` | ✓ | Full implementation with all features supported. Implemented via OffersRequestBuilder |

### Operations

| Endpoint | Method | Status | SDK Method | Streaming | Notes |
|----------|--------|--------|------------|-----------|-------|
| `/operations` | GET | ✅ | `operations` | ✓ | Full implementation with all features supported. Implemented via OperationsRequestBuilder |
| `/operations/{operation_id}` | GET | ✅ | `operations` | ✓ | Full implementation with all features supported. Implemented via OperationsRequestBuilder |
| `/operations/{operation_id}/effects` | GET | ✅ | `operations.effects` | ✓ | Full implementation with all features supported. Implemented via EffectsRequestBuilder |

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
| `/transactions/{transaction_id}` | GET | ✅ | `transactions` | ✓ | Full implementation with all features supported. Implemented via TransactionsRequestBuilder |
| `/transactions/{transaction_id}/effects` | GET | ✅ | `transactions.effects` | ✓ | Full implementation with all features supported. Implemented via EffectsRequestBuilder |
| `/transactions/{transaction_id}/operations` | GET | ✅ | `transactions.operations` | ✓ | Full implementation with all features supported. Implemented via OperationsRequestBuilder |
| `/transactions/{transaction_id}/payments` | GET | ✅ | `transactions.payments` | ✓ | Full implementation with all features supported. Implemented via PaymentsRequestBuilder |

### Transactions_Async

| Endpoint | Method | Status | SDK Method | Streaming | Notes |
|----------|--------|--------|------------|-----------|-------|
| `/transactions_async` | POST | ✅ | `submitAsyncTransactionEnvelopeXdrBase64` |  | Full implementation with all features supported. Implemented via submitAsyncTransactionEnvelopeXdrBase64() method |

## Implementation Gaps

## Legend

- ✅ **Fully Supported**: Complete implementation with all features
- ⚠️ **Partially Supported**: Basic functionality with some limitations
- ❌ **Not Supported**: Endpoint not implemented
- 🔄 **Deprecated**: Deprecated endpoint with alternative available
