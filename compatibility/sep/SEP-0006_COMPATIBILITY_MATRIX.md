# SEP-0006 (Deposit and Withdrawal API) Compatibility Matrix

**Generated:** 2026-02-03 17:26:53  
**SDK Version:** 3.0.1  
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

- **`TransferServerService`**: Main service class for SEP-6 deposit and withdrawal operations
- **`DepositRequest`**: Request parameters for initiating a deposit
- **`DepositResponse`**: Response containing deposit instructions from anchor
- **`DepositInstruction`**: Instructions for completing a deposit (account, memo, etc.)
- **`ExtraInfo`**: Additional information provided by anchor
- **`CustomerInformationNeededResponse`**: Response when additional KYC info is required
- **`CustomerInformationNeededException`**: Exception thrown when KYC info is needed
- **`CustomerInformationStatusResponse`**: Response with KYC verification status
- **`CustomerInformationStatusException`**: Exception for KYC status issues
- **`AuthenticationRequiredException`**: Exception when SEP-10 authentication is required
- **`DepositExchangeRequest`**: Request for deposit with on-chain asset exchange
- **`WithdrawRequest`**: Request parameters for initiating a withdrawal
- **`WithdrawExchangeRequest`**: Request for withdrawal with on-chain asset exchange
- **`WithdrawResponse`**: Response containing withdrawal details from anchor
- **`AnchorField`**: Custom field definition required by anchor for KYC/compliance
- **`DepositAsset`**: Asset configuration for deposits (min/max amounts, fees, etc.)
- **`DepositExchangeAsset`**: Asset configuration for deposit-exchange operations
- **`WithdrawAsset`**: Asset configuration for withdrawals (min/max amounts, fees, etc.)
- **`WithdrawExchangeAsset`**: Asset configuration for withdraw-exchange operations
- **`AnchorFeeInfo`**: Fee information from anchor /info endpoint
- **`AnchorTransactionInfo`**: Transaction information from /transaction endpoint
- **`AnchorTransactionsInfo`**: Transaction list from /transactions endpoint
- **`AnchorFeatureFlags`**: Feature flags indicating anchor capabilities
- **`InfoResponse`**: Response from /info endpoint with supported assets and features
- **`FeeRequest`**: Request parameters for fee calculation
- **`FeeResponse`**: Response containing calculated fee for operation
- **`AnchorTransactionsRequest`**: Request for transaction history
- **`FeeDetails`**: Detailed fee breakdown information
- **`FeeDetailsDetails`**: Individual fee component details
- **`TransactionRefunds`**: Refund information for a transaction
- **`TransactionRefundPayment`**: Individual refund payment details
- **`AnchorTransaction`**: Represents a single anchor transaction with full details
- **`AnchorTransactionsResponse`**: Response containing transaction list
- **`AnchorTransactionRequest`**: Request for single transaction status
- **`AnchorTransactionResponse`**: Response containing single transaction details
- **`PatchTransactionRequest`**: Request to update transaction with additional info

## Coverage by Section

| Section | Coverage | Required Coverage | Implemented | Not Implemented | Total |
|---------|----------|-------------------|-------------|-----------------|-------|
| Deposit Endpoints | 100.0% | 100.0% | 2 | 0 | 2 |
| Deposit Request Parameters | 100.0% | 100.0% | 15 | 0 | 15 |
| Deposit Response Fields | 100.0% | 100.0% | 8 | 0 | 8 |
| Fee Endpoint | 100.0% | 100% | 1 | 0 | 1 |
| Info Endpoint | 100.0% | 100.0% | 1 | 0 | 1 |
| Info Response Fields | 100.0% | 100.0% | 8 | 0 | 8 |
| Transaction Endpoints | 100.0% | 100.0% | 3 | 0 | 3 |
| Transaction Fields | 100.0% | 100.0% | 16 | 0 | 16 |
| Transaction Status Values | 100.0% | 100.0% | 12 | 0 | 12 |
| Withdraw Endpoints | 100.0% | 100.0% | 2 | 0 | 2 |
| Withdraw Request Parameters | 100.0% | 100.0% | 17 | 0 | 17 |
| Withdraw Response Fields | 100.0% | 100.0% | 10 | 0 | 10 |

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
