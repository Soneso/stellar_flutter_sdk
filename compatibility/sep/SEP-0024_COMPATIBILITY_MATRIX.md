# SEP-0024 (Hosted Deposit and Withdrawal) Compatibility Matrix

**Generated:** 2025-11-16 01:16:39

**SDK Version:** 2.1.8
**SEP Version:** 3.8.0
**SEP Status:** Active
**SEP URL:** https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0024.md

## SEP Summary

This SEP defines the standard way for anchors and wallets to interact on behalf
of users. This improves user experience by allowing wallets and other clients
to interact with anchors directly without the user needing to leave the wallet
to go to the anchor's site. It is based on [SEP-0006](sep-0006.md), but only
supports the interactive flow, and cleans up or removes confusing artifacts. If
you are updating from SEP-0006 see the
[changes from SEP-6](#changes-from-SEP-6) at the bottom of this document.

## Overall Coverage

**Total Coverage:** 100.0% (94/94 fields)

- ✅ **Implemented:** 94/94
- ❌ **Not Implemented:** 0/94

**Required Fields:** 100.0% (24/24)

**Optional Fields:** 100.0% (70/70)

## Implementation Status

✅ **Implemented**

### Implementation Files

- `lib/src/sep/0024/sep24_service.dart`

### Key Classes

- **`TransferServerSEP24Service`**: Implements SEP-0024 v3.8.0 - Hosted Deposit and Withdrawal for Stellar anchors.
- **`SEP24DepositAsset`**: Implements SEP-0024 v3.8.0 - Hosted Deposit and Withdrawal for Stellar anchors.
- **`SEP24WithdrawAsset`**: Implements SEP-0024 v3.8.0 - Hosted Deposit and Withdrawal for Stellar anchors.
- **`FeeEndpointInfo`**: Implements SEP-0024 v3.8.0 - Hosted Deposit and Withdrawal for Stellar anchors.
- **`FeatureFlags`**: Implements SEP-0024 v3.8.0 - Hosted Deposit and Withdrawal for Stellar anchors.
- **`SEP24InfoResponse`**: Implements SEP-0024 v3.8.0 - Hosted Deposit and Withdrawal for Stellar anchors.
- **`_InfoRequestBuilder`**: Implements SEP-0024 v3.8.0 - Hosted Deposit and Withdrawal for Stellar anchors.
- **`SEP24FeeRequest`**: Implements SEP-0024 v3.8.0 - Hosted Deposit and Withdrawal for Stellar anchors.
- **`SEP24FeeResponse`**: Implements SEP-0024 v3.8.0 - Hosted Deposit and Withdrawal for Stellar anchors.
- **`_FeeRequestBuilder`**: Implements SEP-0024 v3.8.0 - Hosted Deposit and Withdrawal for Stellar anchors.
- **`SEP24DepositRequest`**: Implements SEP-0024 v3.8.0 - Hosted Deposit and Withdrawal for Stellar anchors.
- **`SEP24InteractiveResponse`**: Implements SEP-0024 v3.8.0 - Hosted Deposit and Withdrawal for Stellar anchors.
- **`_PostRequestBuilder`**: Implements SEP-0024 v3.8.0 - Hosted Deposit and Withdrawal for Stellar anchors.
- **`SEP24WithdrawRequest`**: Implements SEP-0024 v3.8.0 - Hosted Deposit and Withdrawal for Stellar anchors.
- **`SEP24TransactionsRequest`**: Implements SEP-0024 v3.8.0 - Hosted Deposit and Withdrawal for Stellar anchors.
- **`SEP24Transaction`**: Implements SEP-0024 v3.8.0 - Hosted Deposit and Withdrawal for Stellar anchors.
- **`SEP24TransactionsResponse`**: Implements SEP-0024 v3.8.0 - Hosted Deposit and Withdrawal for Stellar anchors.
- **`_AnchorTransactionsRequestBuilder`**: Implements SEP-0024 v3.8.0 - Hosted Deposit and Withdrawal for Stellar anchors.
- **`Refund`**: Implements SEP-0024 v3.8.0 - Hosted Deposit and Withdrawal for Stellar anchors.
- **`RefundPayment`**: Implements SEP-0024 v3.8.0 - Hosted Deposit and Withdrawal for Stellar anchors.
- **`SEP24TransactionRequest`**: Implements SEP-0024 v3.8.0 - Hosted Deposit and Withdrawal for Stellar anchors.
- **`SEP24TransactionResponse`**: Implements SEP-0024 v3.8.0 - Hosted Deposit and Withdrawal for Stellar anchors.
- **`_AnchorTransactionRequestBuilder`**: Implements SEP-0024 v3.8.0 - Hosted Deposit and Withdrawal for Stellar anchors.
- **`RequestErrorException`**: Implements SEP-0024 v3.8.0 - Hosted Deposit and Withdrawal for Stellar anchors.
- **`SEP24AuthenticationRequiredException`**: Implements SEP-0024 v3.8.0 - Hosted Deposit and Withdrawal for Stellar anchors.
- **`SEP24TransactionNotFoundException`**: Implements SEP-0024 v3.8.0 - Hosted Deposit and Withdrawal for Stellar anchors.

## Coverage by Section

| Section | Coverage | Required Coverage | Implemented | Total |
|---------|----------|-------------------|-------------|-------|
| Deposit Asset Fields | 100.0% | 100.0% | 6 | 6 |
| Deposit Request Parameters | 100.0% | 100.0% | 12 | 12 |
| Feature Flags Fields | 100.0% | 100% | 2 | 2 |
| Fee Endpoint | 100.0% | 100% | 1 | 1 |
| Fee Endpoint Info Fields | 100.0% | 100.0% | 2 | 2 |
| Info Endpoint | 100.0% | 100.0% | 1 | 1 |
| Info Response Fields | 100.0% | 100.0% | 4 | 4 |
| Interactive Deposit Endpoint | 100.0% | 100.0% | 1 | 1 |
| Interactive Response Fields | 100.0% | 100.0% | 3 | 3 |
| Interactive Withdraw Endpoint | 100.0% | 100.0% | 1 | 1 |
| Transaction Endpoints | 100.0% | 100.0% | 2 | 2 |
| Transaction Fields | 100.0% | 100.0% | 30 | 30 |
| Transaction Status Values | 100.0% | 100.0% | 12 | 12 |
| Withdraw Asset Fields | 100.0% | 100.0% | 6 | 6 |
| Withdraw Request Parameters | 100.0% | 100.0% | 11 | 11 |

## Detailed Field Comparison

### Deposit Asset Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `enabled` | ✓ | ✅ | `enabled` | Whether deposits are enabled for this asset |
| `fee_fixed` |  | ✅ | `feeFixed` | Fixed deposit fee |
| `fee_minimum` |  | ✅ | `feeMinimum` | Minimum deposit fee |
| `fee_percent` |  | ✅ | `feePercent` | Percentage deposit fee |
| `max_amount` |  | ✅ | `maxAmount` | Maximum deposit amount |
| `min_amount` |  | ✅ | `minAmount` | Minimum deposit amount |

### Deposit Request Parameters

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `account` |  | ✅ | `account` | Stellar or muxed account for receiving deposit |
| `amount` |  | ✅ | `amount` | Amount of asset to deposit |
| `asset_code` | ✓ | ✅ | `assetCode` | Code of the Stellar asset the user wants to receive |
| `asset_issuer` |  | ✅ | `assetIssuer` | Issuer of the Stellar asset (optional if anchor is issuer) |
| `claimable_balance_supported` |  | ✅ | `claimableBalanceSupported` | Whether client supports claimable balances |
| `lang` |  | ✅ | `lang` | Language code for UI and messages (RFC 4646) |
| `memo` |  | ✅ | `memo` | Memo value for transaction identification |
| `memo_type` |  | ✅ | `memoType` | Type of memo (text, id, or hash) |
| `quote_id` |  | ✅ | `quoteId` | ID from SEP-38 quote (for asset exchange) |
| `source_asset` |  | ✅ | `sourceAsset` | Off-chain asset user wants to deposit (in SEP-38 format) |
| `wallet_name` |  | ✅ | `walletName` | Name of wallet for user communication |
| `wallet_url` |  | ✅ | `walletUrl` | URL to link in transaction notifications |

### Feature Flags Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `account_creation` |  | ✅ | `accountCreation` | Whether anchor supports creating accounts |
| `claimable_balances` |  | ✅ | `claimableBalances` | Whether anchor supports claimable balances |

### Fee Endpoint

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `fee_endpoint` |  | ✅ | `fee` | GET /fee - Calculates fees for a deposit or withdrawal operation (optional) |

### Fee Endpoint Info Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `authentication_required` |  | ✅ | `authenticationRequired` | Whether authentication is required for fee endpoint |
| `enabled` | ✓ | ✅ | `enabled` | Whether fee endpoint is available |

### Info Endpoint

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `info_endpoint` | ✓ | ✅ | `info` | GET /info - Provides anchor capabilities and supported assets for interactive deposits/withdrawals |

### Info Response Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `deposit` | ✓ | ✅ | `depositAssets` | Map of asset codes to deposit asset information |
| `features` |  | ✅ | `featureFlags` | Feature flags object |
| `fee` |  | ✅ | `feeEndpointInfo` | Fee endpoint information object |
| `withdraw` | ✓ | ✅ | `withdrawAssets` | Map of asset codes to withdraw asset information |

### Interactive Deposit Endpoint

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `interactive_deposit` | ✓ | ✅ | `deposit` | POST /transactions/deposit/interactive - Initiates an interactive deposit transaction |

### Interactive Response Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `id` | ✓ | ✅ | `id` | Unique transaction identifier |
| `type` | ✓ | ✅ | `type` | Always "interactive_customer_info_needed" for SEP-24 |
| `url` | ✓ | ✅ | `url` | URL for interactive flow popup/iframe |

### Interactive Withdraw Endpoint

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `interactive_withdraw` | ✓ | ✅ | `withdraw` | POST /transactions/withdraw/interactive - Initiates an interactive withdrawal transaction |

### Transaction Endpoints

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `transaction` | ✓ | ✅ | `transaction` | GET /transaction - Retrieves details for a single transaction |
| `transactions` | ✓ | ✅ | `transactions` | GET /transactions - Retrieves transaction history for authenticated account |

### Transaction Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `amount_fee` |  | ✅ | `amountFee` | Total fee charged for transaction |
| `amount_fee_asset` |  | ✅ | `amountFeeAsset` | Asset in which fees are calculated (SEP-38 format) |
| `amount_in` |  | ✅ | `amountIn` | Amount received by anchor |
| `amount_in_asset` |  | ✅ | `amountInAsset` | Asset received by anchor (SEP-38 format) |
| `amount_out` |  | ✅ | `amountOut` | Amount sent by anchor to user |
| `amount_out_asset` |  | ✅ | `amountOutAsset` | Asset delivered to user (SEP-38 format) |
| `claimable_balance_id` |  | ✅ | `claimableBalanceId` | ID of claimable balance for deposit |
| `completed_at` |  | ✅ | `completedAt` | When transaction completed (ISO 8601) |
| `deposit_memo` |  | ✅ | `depositMemo` | Memo for deposit to Stellar address |
| `deposit_memo_type` |  | ✅ | `depositMemoType` | Type of deposit memo |
| `external_transaction_id` |  | ✅ | `externalTransactionId` | Identifier from external system |
| `from` |  | ✅ | `from` | Source address (Stellar for withdrawals, external for deposits) |
| `id` | ✓ | ✅ | `id` | Unique transaction identifier |
| `kind` | ✓ | ✅ | `kind` | Kind of transaction (deposit or withdrawal) |
| `kyc_verified` |  | ✅ | `kycVerified` | Whether KYC has been verified for this transaction |
| `message` |  | ✅ | `message` | Human-readable message about transaction |
| `more_info_url` | ✓ | ✅ | `moreInfoUrl` | URL with additional transaction information |
| `quote_id` |  | ✅ | `quoteId` | ID of SEP-38 quote used for this transaction |
| `refunded` |  | ✅ | `refunded` | Whether transaction was refunded (deprecated) |
| `refunds` |  | ✅ | `refunds` | Refund information object |
| `started_at` | ✓ | ✅ | `startedAt` | When transaction was created (ISO 8601) |
| `status` | ✓ | ✅ | `status` | Current status of the transaction |
| `status_eta` |  | ✅ | `statusEta` | Estimated seconds until status changes |
| `stellar_transaction_id` |  | ✅ | `stellarTransactionId` | Hash of the Stellar transaction |
| `to` |  | ✅ | `to` | Destination address (Stellar for deposits, external for withdrawals) |
| `updated_at` |  | ✅ | `updatedAt` | When transaction status last changed (ISO 8601) |
| `user_action_required_by` |  | ✅ | `userActionRequiredBy` | Deadline for user action (ISO 8601) |
| `withdraw_anchor_account` |  | ✅ | `withdrawAnchorAccount` | Anchor's Stellar account for withdrawal payment |
| `withdraw_memo` |  | ✅ | `withdrawMemo` | Memo for withdrawal to anchor account |
| `withdraw_memo_type` |  | ✅ | `withdrawMemoType` | Type of withdraw memo |

### Transaction Status Values

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `completed` | ✓ | ✅ | `status` | Transaction completed successfully |
| `error` |  | ✅ | `status` | Transaction encountered an error |
| `expired` |  | ✅ | `status` | Transaction expired before completion |
| `incomplete` | ✓ | ✅ | `status` | Customer information still being collected via interactive flow |
| `pending_anchor` | ✓ | ✅ | `status` | Anchor processing the transaction |
| `pending_external` |  | ✅ | `status` | Transaction being processed by external system |
| `pending_stellar` |  | ✅ | `status` | Transaction submitted to Stellar network |
| `pending_trust` |  | ✅ | `status` | User needs to establish trustline |
| `pending_user` |  | ✅ | `status` | Waiting for user action (e.g., accepting claimable balance) |
| `pending_user_transfer_complete` |  | ✅ | `status` | User transfer detected, awaiting confirmations |
| `pending_user_transfer_start` | ✓ | ✅ | `status` | Waiting for user to send funds (deposits) |
| `refunded` |  | ✅ | `status` | Transaction refunded |

### Withdraw Asset Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `enabled` | ✓ | ✅ | `enabled` | Whether withdrawals are enabled for this asset |
| `fee_fixed` |  | ✅ | `feeFixed` | Fixed withdrawal fee |
| `fee_minimum` |  | ✅ | `feeMinimum` | Minimum withdrawal fee |
| `fee_percent` |  | ✅ | `feePercent` | Percentage withdrawal fee |
| `max_amount` |  | ✅ | `maxAmount` | Maximum withdrawal amount |
| `min_amount` |  | ✅ | `minAmount` | Minimum withdrawal amount |

### Withdraw Request Parameters

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `account` |  | ✅ | `account` | Stellar or muxed account that will send the withdrawal |
| `amount` |  | ✅ | `amount` | Amount of asset to withdraw |
| `asset_code` | ✓ | ✅ | `assetCode` | Code of the Stellar asset user wants to send |
| `asset_issuer` |  | ✅ | `assetIssuer` | Issuer of the Stellar asset (optional if anchor is issuer) |
| `destination_asset` |  | ✅ | `destinationAsset` | Off-chain asset user wants to receive (in SEP-38 format) |
| `lang` |  | ✅ | `lang` | Language code for UI and messages (RFC 4646) |
| `memo` |  | ✅ | `memo` | Memo for identifying the withdrawal transaction |
| `memo_type` |  | ✅ | `memoType` | Type of memo (text, id, or hash) |
| `quote_id` |  | ✅ | `quoteId` | ID from SEP-38 quote (for asset exchange) |
| `wallet_name` |  | ✅ | `walletName` | Name of wallet for user communication |
| `wallet_url` |  | ✅ | `walletUrl` | URL to link in transaction notifications |

## Implementation Gaps

🎉 **No gaps found!** All fields are implemented.

## Recommendations

✅ The SDK has full compatibility with SEP-0024!

## Legend

- ✅ **Implemented**: Field is implemented in SDK
- ❌ **Not Implemented**: Field is missing from SDK
- ⚙️ **Server**: Server-side only feature (not applicable to client SDKs)
- ✓ **Required**: Field is required by SEP specification
- (blank) **Optional**: Field is optional
