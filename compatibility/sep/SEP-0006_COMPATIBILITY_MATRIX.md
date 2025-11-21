# SEP-0006 (Deposit and Withdrawal API) Compatibility Matrix

**Generated:** 2025-11-21 18:16:36

**SDK Version:** 2.2.0
**SEP Version:** 4.3.0
**SEP Status:** Active (Interactive components are deprecated in favor of SEP-24)
**SEP URL:** https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md

## SEP Summary

This SEP defines the standard way for anchors and wallets to interact on behalf
of users. This improves user experience by allowing wallets and other clients
to interact with anchors directly without the user needing to leave the wallet
to go to the anchor's site.

Please note that this SEP provides a normalized interface specification that
allows wallets and other services to interact with anchors _programmatically_.
[SEP-24](sep-0024.md) was created to support use cases where the anchor may
want to interact with users _interactively_ using a popup opened within the
wallet application.

## Overall Coverage

**Total Coverage:** 100.0% (95/95 fields)

- ✅ **Implemented:** 95/95
- ❌ **Not Implemented:** 0/95

**Required Fields:** 100.0% (22/22)

**Optional Fields:** 100.0% (73/73)

## Implementation Status

✅ **Implemented**

### Implementation Files

- `lib/src/sep/0006/transfer_server_service.dart`

### Key Classes

- **`TransferServerService`**: Implements SEP-0006 Programmatic Deposit and Withdrawal API.
- **`DepositRequest`**: Implements SEP-0006 Programmatic Deposit and Withdrawal API.
- **`DepositResponse`**: Implements SEP-0006 Programmatic Deposit and Withdrawal API.
- **`DepositInstruction`**: Implements SEP-0006 Programmatic Deposit and Withdrawal API.
- **`ExtraInfo`**: Implements SEP-0006 Programmatic Deposit and Withdrawal API.
- **`_DepositRequestBuilder`**: Implements SEP-0006 Programmatic Deposit and Withdrawal API.
- **`CustomerInformationNeededResponse`**: Implements SEP-0006 Programmatic Deposit and Withdrawal API.
- **`CustomerInformationNeededException`**: Implements SEP-0006 Programmatic Deposit and Withdrawal API.
- **`CustomerInformationStatusResponse`**: Implements SEP-0006 Programmatic Deposit and Withdrawal API.
- **`CustomerInformationStatusException`**: Implements SEP-0006 Programmatic Deposit and Withdrawal API.
- **`AuthenticationRequiredException`**: Implements SEP-0006 Programmatic Deposit and Withdrawal API.
- **`DepositExchangeRequest`**: Implements SEP-0006 Programmatic Deposit and Withdrawal API.
- **`WithdrawRequest`**: Implements SEP-0006 Programmatic Deposit and Withdrawal API.
- **`WithdrawExchangeRequest`**: Implements SEP-0006 Programmatic Deposit and Withdrawal API.
- **`WithdrawResponse`**: Implements SEP-0006 Programmatic Deposit and Withdrawal API.
- **`_WithdrawRequestBuilder`**: Implements SEP-0006 Programmatic Deposit and Withdrawal API.
- **`AnchorField`**: Implements SEP-0006 Programmatic Deposit and Withdrawal API.
- **`DepositAsset`**: Implements SEP-0006 Programmatic Deposit and Withdrawal API.
- **`DepositExchangeAsset`**: Implements SEP-0006 Programmatic Deposit and Withdrawal API.
- **`WithdrawAsset`**: Implements SEP-0006 Programmatic Deposit and Withdrawal API.
- **`WithdrawExchangeAsset`**: Implements SEP-0006 Programmatic Deposit and Withdrawal API.
- **`AnchorFeeInfo`**: Implements SEP-0006 Programmatic Deposit and Withdrawal API.
- **`AnchorTransactionInfo`**: Implements SEP-0006 Programmatic Deposit and Withdrawal API.
- **`AnchorTransactionsInfo`**: Implements SEP-0006 Programmatic Deposit and Withdrawal API.
- **`AnchorFeatureFlags`**: Implements SEP-0006 Programmatic Deposit and Withdrawal API.
- **`InfoResponse`**: Implements SEP-0006 Programmatic Deposit and Withdrawal API.
- **`_InfoRequestBuilder`**: Implements SEP-0006 Programmatic Deposit and Withdrawal API.
- **`FeeRequest`**: Implements SEP-0006 Programmatic Deposit and Withdrawal API.
- **`FeeResponse`**: Implements SEP-0006 Programmatic Deposit and Withdrawal API.
- **`_FeeRequestBuilder`**: Implements SEP-0006 Programmatic Deposit and Withdrawal API.
- **`AnchorTransactionsRequest`**: Implements SEP-0006 Programmatic Deposit and Withdrawal API.
- **`FeeDetails`**: Implements SEP-0006 Programmatic Deposit and Withdrawal API.
- **`FeeDetailsDetails`**: Implements SEP-0006 Programmatic Deposit and Withdrawal API.
- **`TransactionRefunds`**: Implements SEP-0006 Programmatic Deposit and Withdrawal API.
- **`TransactionRefundPayment`**: Implements SEP-0006 Programmatic Deposit and Withdrawal API.
- **`AnchorTransaction`**: Implements SEP-0006 Programmatic Deposit and Withdrawal API.
- **`AnchorTransactionsResponse`**: Implements SEP-0006 Programmatic Deposit and Withdrawal API.
- **`_AnchorTransactionsRequestBuilder`**: Implements SEP-0006 Programmatic Deposit and Withdrawal API.
- **`AnchorTransactionRequest`**: Implements SEP-0006 Programmatic Deposit and Withdrawal API.
- **`AnchorTransactionResponse`**: Implements SEP-0006 Programmatic Deposit and Withdrawal API.
- **`_AnchorTransactionRequestBuilder`**: Implements SEP-0006 Programmatic Deposit and Withdrawal API.
- **`PatchTransactionRequest`**: Implements SEP-0006 Programmatic Deposit and Withdrawal API.
- **`_PatchTransactionRequestBuilder`**: Implements SEP-0006 Programmatic Deposit and Withdrawal API.

## Coverage by Section

| Section | Coverage | Required Coverage | Implemented | Total |
|---------|----------|-------------------|-------------|-------|
| Deposit Endpoints | 100.0% | 100.0% | 2 | 2 |
| Deposit Request Parameters | 100.0% | 100.0% | 15 | 15 |
| Deposit Response Fields | 100.0% | 100.0% | 8 | 8 |
| Fee Endpoint | 100.0% | 100% | 1 | 1 |
| Info Endpoint | 100.0% | 100.0% | 1 | 1 |
| Info Response Fields | 100.0% | 100.0% | 8 | 8 |
| Transaction Endpoints | 100.0% | 100.0% | 3 | 3 |
| Transaction Fields | 100.0% | 100.0% | 16 | 16 |
| Transaction Status Values | 100.0% | 100.0% | 12 | 12 |
| Withdraw Endpoints | 100.0% | 100.0% | 2 | 2 |
| Withdraw Request Parameters | 100.0% | 100.0% | 17 | 17 |
| Withdraw Response Fields | 100.0% | 100.0% | 10 | 10 |

## Detailed Field Comparison

### Deposit Endpoints

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `deposit` | ✓ | ✅ | `deposit` | GET /deposit - Initiates a deposit transaction for on-chain assets |
| `deposit_exchange` |  | ✅ | `depositExchange` | GET /deposit-exchange - Initiates a deposit with asset exchange (SEP-38 integration) |

### Deposit Request Parameters

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `account` | ✓ | ✅ | `account` | Stellar account ID of the user |
| `amount` |  | ✅ | `amount` | Amount of on-chain asset the user wants to receive |
| `asset_code` | ✓ | ✅ | `assetCode` | Code of the on-chain asset the user wants to receive |
| `claimable_balance_supported` |  | ✅ | `claimableBalanceSupported` | Whether the client supports receiving claimable balances |
| `country_code` |  | ✅ | `countryCode` | Country code of the user (ISO 3166-1 alpha-3) |
| `customer_id` |  | ✅ | `customerId` | ID of the customer from SEP-12 KYC process |
| `email_address` |  | ✅ | `emailAddress` | Email address of the user (for notifications) |
| `lang` |  | ✅ | `lang` | Language code for response messages (ISO 639-1) |
| `location_id` |  | ✅ | `locationId` | ID of the physical location for cash pickup |
| `memo` |  | ✅ | `memo` | Value of memo to attach to transaction |
| `memo_type` |  | ✅ | `memoType` | Type of memo to attach to transaction (text, id, or hash) |
| `on_change_callback` |  | ✅ | `onChangeCallback` | URL for anchor to send callback when transaction status changes |
| `type` |  | ✅ | `type` | Type of deposit method (e.g., bank_account, cash, mobile_money) |
| `wallet_name` |  | ✅ | `walletName` | Name of the wallet the user is using |
| `wallet_url` |  | ✅ | `walletUrl` | URL of the wallet the user is using |

### Deposit Response Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `eta` |  | ✅ | `eta` | Estimated seconds until deposit completes |
| `extra_info` |  | ✅ | `extraInfo` | Additional information about the deposit |
| `fee_fixed` |  | ✅ | `feeFixed` | Fixed fee for deposit |
| `fee_percent` |  | ✅ | `feePercent` | Percentage fee for deposit |
| `how` | ✓ | ✅ | `how` | Instructions for how to deposit the asset |
| `id` |  | ✅ | `id` | Persistent transaction identifier |
| `max_amount` |  | ✅ | `maxAmount` | Maximum deposit amount |
| `min_amount` |  | ✅ | `minAmount` | Minimum deposit amount |

### Fee Endpoint

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `fee_endpoint` |  | ✅ | `fee` | GET /fee - Calculates fees for a deposit or withdrawal operation |

### Info Endpoint

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `info_endpoint` | ✓ | ✅ | `info` | GET /info - Provides anchor capabilities and asset information |

### Info Response Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `deposit` | ✓ | ✅ | `depositAssets` | Map of asset codes to deposit asset information |
| `deposit-exchange` |  | ✅ | `depositExchangeAssets` | Map of asset codes to deposit-exchange asset information |
| `features` |  | ✅ | `featureFlags` | Feature flags supported by the anchor |
| `fee` |  | ✅ | `feeInfo` | Fee endpoint information |
| `transaction` |  | ✅ | `transactionInfo` | Single transaction endpoint information |
| `transactions` |  | ✅ | `transactionsInfo` | Transaction history endpoint information |
| `withdraw` | ✓ | ✅ | `withdrawAssets` | Map of asset codes to withdraw asset information |
| `withdraw-exchange` |  | ✅ | `withdrawExchangeAssets` | Map of asset codes to withdraw-exchange asset information |

### Transaction Endpoints

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `patch_transaction` |  | ✅ | `patchTransaction` | PATCH /transaction - Updates transaction fields (for debugging/testing) |
| `transaction` | ✓ | ✅ | `transaction` | GET /transaction - Retrieves details for a single transaction |
| `transactions` | ✓ | ✅ | `transactions` | GET /transactions - Retrieves transaction history for an account |

### Transaction Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `amount_fee` |  | ✅ | `amountFee` | Total fee charged for transaction |
| `amount_in` |  | ✅ | `amountIn` | Amount received by anchor |
| `amount_out` |  | ✅ | `amountOut` | Amount sent by anchor to user |
| `completed_at` |  | ✅ | `completedAt` | When transaction completed (ISO 8601) |
| `external_transaction_id` |  | ✅ | `externalTransactionId` | Identifier from external system |
| `from` |  | ✅ | `from` | Stellar account that initiated the transaction |
| `id` | ✓ | ✅ | `id` | Unique transaction identifier |
| `kind` | ✓ | ✅ | `kind` | Kind of transaction (deposit, withdrawal, deposit-exchange, withdrawal-exchange) |
| `message` |  | ✅ | `message` | Human-readable message about transaction |
| `refunded` |  | ✅ | `refunded` | Whether transaction was refunded |
| `refunds` |  | ✅ | `refunds` | Refund information if applicable |
| `started_at` | ✓ | ✅ | `startedAt` | When transaction was created (ISO 8601) |
| `status` | ✓ | ✅ | `status` | Current status of the transaction |
| `status_eta` |  | ✅ | `statusEta` | Estimated seconds until status changes |
| `stellar_transaction_id` |  | ✅ | `stellarTransactionId` | Hash of the Stellar transaction |
| `to` |  | ✅ | `to` | Stellar account receiving the transaction |

### Transaction Status Values

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `completed` | ✓ | ✅ | - | Transaction completed successfully |
| `error` |  | ✅ | - | Transaction failed with error |
| `expired` |  | ✅ | - | Transaction expired without completion |
| `incomplete` | ✓ | ✅ | - | Deposit/withdrawal has not yet been submitted |
| `pending_anchor` | ✓ | ✅ | - | Anchor is processing the transaction |
| `pending_external` |  | ✅ | - | Waiting for external action (banking system, etc.) |
| `pending_stellar` |  | ✅ | - | Stellar transaction has been submitted |
| `pending_trust` |  | ✅ | - | User needs to add trustline for asset |
| `pending_user` |  | ✅ | - | Waiting for user action (accepting claimable balance) |
| `pending_user_transfer_complete` |  | ✅ | - | Off-chain transfer has been initiated |
| `pending_user_transfer_start` | ✓ | ✅ | - | Waiting for user to initiate off-chain transfer |
| `refunded` |  | ✅ | - | Transaction refunded |

### Withdraw Endpoints

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `withdraw` | ✓ | ✅ | `withdraw` | GET /withdraw - Initiates a withdrawal transaction for off-chain assets |
| `withdraw_exchange` |  | ✅ | `withdrawExchange` | GET /withdraw-exchange - Initiates a withdrawal with asset exchange (SEP-38 integration) |

### Withdraw Request Parameters

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `account` |  | ✅ | `account` | Stellar account ID of the user |
| `amount` |  | ✅ | `amount` | Amount of on-chain asset the user wants to send |
| `asset_code` | ✓ | ✅ | `assetCode` | Code of the on-chain asset the user wants to send |
| `country_code` |  | ✅ | `countryCode` | Country code of the user (ISO 3166-1 alpha-3) |
| `customer_id` |  | ✅ | `customerId` | ID of the customer from SEP-12 KYC process |
| `dest` |  | ✅ | `dest` | Destination for withdrawal (bank account number, etc.) |
| `dest_extra` |  | ✅ | `destExtra` | Extra information for destination (routing number, etc.) |
| `lang` |  | ✅ | `lang` | Language code for response messages (ISO 639-1) |
| `location_id` |  | ✅ | `locationId` | ID of the physical location for cash pickup |
| `memo` |  | ✅ | `memo` | Memo to identify the user if account is shared |
| `memo_type` |  | ✅ | `memoType` | Type of memo (text, id, or hash) |
| `on_change_callback` |  | ✅ | `onChangeCallback` | URL for anchor to send callback when transaction status changes |
| `refund_memo` |  | ✅ | `refundMemo` | Memo to use for refund transaction if withdrawal fails |
| `refund_memo_type` |  | ✅ | `refundMemoType` | Type of refund memo (text, id, or hash) |
| `type` | ✓ | ✅ | `type` | Type of withdrawal method (e.g., bank_account, cash, mobile_money) |
| `wallet_name` |  | ✅ | `walletName` | Name of the wallet the user is using |
| `wallet_url` |  | ✅ | `walletUrl` | URL of the wallet the user is using |

### Withdraw Response Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `account_id` | ✓ | ✅ | `accountId` | Stellar account to send withdrawn assets to |
| `eta` |  | ✅ | `eta` | Estimated seconds until withdrawal completes |
| `extra_info` |  | ✅ | `extraInfo` | Additional information about the withdrawal |
| `fee_fixed` |  | ✅ | `feeFixed` | Fixed fee for withdrawal |
| `fee_percent` |  | ✅ | `feePercent` | Percentage fee for withdrawal |
| `id` | ✓ | ✅ | `id` | Persistent transaction identifier |
| `max_amount` |  | ✅ | `maxAmount` | Maximum withdrawal amount |
| `memo` |  | ✅ | `memo` | Value of memo to attach to transaction |
| `memo_type` |  | ✅ | `memoType` | Type of memo to attach to transaction |
| `min_amount` |  | ✅ | `minAmount` | Minimum withdrawal amount |

## Implementation Gaps

🎉 **No gaps found!** All fields are implemented.

## Recommendations

✅ The SDK has full compatibility with SEP-0006!

## Legend

- ✅ **Implemented**: Field is implemented in SDK
- ❌ **Not Implemented**: Field is missing from SDK
- ⚙️ **Server**: Server-side only feature (not applicable to client SDKs)
- ✓ **Required**: Field is required by SEP specification
- (blank) **Optional**: Field is optional
