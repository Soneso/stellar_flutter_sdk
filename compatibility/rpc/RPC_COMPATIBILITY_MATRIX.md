# Soroban RPC vs Flutter SDK Compatibility Matrix

**RPC Version:** v27.1.1 (released 2026-07-07)  
**RPC Source:** [https://github.com/stellar/stellar-rpc/releases/tag/v27.1.1](https://github.com/stellar/stellar-rpc/releases/tag/v27.1.1)  
**SDK Version:** 3.3.0  
**Generated:** 2026-07-13 21:50:49

## Overall Coverage

**Coverage:** 100.0%

- ✅ **Fully Supported:** 12/12
- ⚠️ **Partially Supported:** 0/12
- ❌ **Not Supported:** 0/12

## Method Comparison

| RPC Method | Status | Flutter Method | Required Params | Response Fields | Notes |
|------------|--------|----------------|-----------------|-----------------|-------|
| `getEvents` | ✅ Fully Supported | `getEvents` | 1/1 | N/A | All parameters and response fields implemented |
| `getFeeStats` | ✅ Fully Supported | `getFeeStats` | N/A | N/A | All parameters and response fields implemented |
| `getHealth` | ✅ Fully Supported | `getHealth` | N/A | N/A | All parameters and response fields implemented |
| `getLatestLedger` | ✅ Fully Supported | `getLatestLedger` | N/A | N/A | All parameters and response fields implemented |
| `getLedgerEntries` | ✅ Fully Supported | `getLedgerEntries` | 1/1 | N/A | All parameters and response fields implemented |
| `getLedgers` | ✅ Fully Supported | `getLedgers` | 1/1 | N/A | All parameters and response fields implemented |
| `getNetwork` | ✅ Fully Supported | `getNetwork` | N/A | N/A | All parameters and response fields implemented |
| `getTransaction` | ✅ Fully Supported | `getTransaction` | 1/1 | N/A | All parameters and response fields implemented |
| `getTransactions` | ✅ Fully Supported | `getTransactions` | 1/1 | N/A | All parameters and response fields implemented |
| `getVersionInfo` | ✅ Fully Supported | `getVersionInfo` | N/A | N/A | All parameters and response fields implemented |
| `sendTransaction` | ✅ Fully Supported | `sendTransaction` | 1/1 | N/A | All parameters and response fields implemented |
| `simulateTransaction` | ✅ Fully Supported | `simulateTransaction` | 1/1 | N/A | All parameters and response fields implemented |

## Response Field Coverage

Detailed breakdown of response field support per method.

| RPC Method | RPC Fields | SDK Fields | Missing Fields |
|------------|------------|------------|----------------|

