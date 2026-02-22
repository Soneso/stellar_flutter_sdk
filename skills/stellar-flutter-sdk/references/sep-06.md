# SEP-06: Programmatic Deposit and Withdrawal

**Purpose:** Non-interactive deposits and withdrawals through anchors without user-facing web flows. The user provides all required information in API requests — no popups or webviews.
**Prerequisites:** Requires JWT from SEP-10 (see `references/sep-10.md`); anchor must publish `TRANSFER_SERVER` in `stellar.toml`
**Spec:** SEP-0006 v4.3.0

Use SEP-06 when you can collect all user information programmatically. Use SEP-24 (`references/sep-24.md`) when the anchor requires an interactive KYC flow.

## Table of Contents

1. [Service Initialization](#1-service-initialization)
2. [Info Endpoint](#2-info-endpoint)
3. [Deposit Flow](#3-deposit-flow)
4. [Deposit Exchange (cross-asset)](#4-deposit-exchange-cross-asset)
5. [Withdraw Flow](#5-withdraw-flow)
6. [Withdraw Exchange (cross-asset)](#6-withdraw-exchange-cross-asset)
7. [Fee Endpoint](#7-fee-endpoint)
8. [Transaction History](#8-transaction-history)
9. [Single Transaction Status](#9-single-transaction-status)
10. [Patch Transaction](#10-patch-transaction)
11. [AnchorTransaction — All Fields](#11-anchortransaction--all-fields)
12. [Transaction Statuses](#12-transaction-statuses)
13. [Error Handling](#13-error-handling)
14. [Common Pitfalls](#14-common-pitfalls)

---

## 1. Service Initialization

### From domain (recommended)

`TransferServerService.fromDomain()` fetches the anchor's `stellar.toml`, reads the `TRANSFER_SERVER` field, and returns a configured service instance. Throws if `TRANSFER_SERVER` is absent.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Fetches https://anchor.example.com/.well-known/stellar.toml
// and reads TRANSFER_SERVER
TransferServerService service =
    await TransferServerService.fromDomain('anchor.example.com');
```

Method signature:
```dart
static Future<TransferServerService> fromDomain(
  String domain, {
  http.Client? httpClient,
  Map<String, String>? httpRequestHeaders,
})
```

### Direct construction

Use when you already have the transfer server URL.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerService service =
    TransferServerService('https://api.anchor.com/sep6');
```

Constructor signature:
```dart
TransferServerService(
  String _transferServiceAddress, {
  http.Client? httpClient,
  Map<String, String>? httpRequestHeaders,
})
```

### With a custom HTTP client

```dart
import 'package:http/http.dart' as http;
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final client = http.Client();
TransferServerService service = await TransferServerService.fromDomain(
  'anchor.example.com',
  httpClient: client,
  httpRequestHeaders: {'User-Agent': 'MyWallet/1.0'},
);
```

---

## 2. Info Endpoint

`info()` queries `GET /info` to discover supported assets, fee structures, and feature flags. JWT is optional but may be required by some anchors.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerService service =
    await TransferServerService.fromDomain('anchor.example.com');

// Optional: pass JWT and/or language code (ISO 639-1)
InfoResponse info = await service.info(jwt: jwtToken, language: 'en');
// Or without arguments:
InfoResponse info = await service.info();
```

Method signature:
```dart
Future<InfoResponse> info({String? language, String? jwt})
```

### InfoResponse fields

| Field | Type | Description |
|-------|------|-------------|
| `depositAssets` | `Map<String, DepositAsset>?` | Standard deposits, keyed by asset code |
| `depositExchangeAssets` | `Map<String, DepositExchangeAsset>?` | Cross-asset deposits, keyed by asset code |
| `withdrawAssets` | `Map<String, WithdrawAsset>?` | Standard withdrawals, keyed by asset code |
| `withdrawExchangeAssets` | `Map<String, WithdrawExchangeAsset>?` | Cross-asset withdrawals, keyed by asset code |
| `feeInfo` | `AnchorFeeInfo?` | `/fee` endpoint availability |
| `transactionsInfo` | `AnchorTransactionsInfo?` | `/transactions` endpoint availability |
| `transactionInfo` | `AnchorTransactionInfo?` | `/transaction` endpoint availability |
| `featureFlags` | `AnchorFeatureFlags?` | Supported anchor features |

### DepositAsset fields

| Field | Type | Description |
|-------|------|-------------|
| `enabled` | `bool` | Whether deposits are supported |
| `authenticationRequired` | `bool?` | JWT required before calling deposit |
| `feeFixed` | `double?` | Fixed fee in asset units |
| `feePercent` | `double?` | Percentage fee in percentage points |
| `minAmount` | `double?` | Minimum deposit amount |
| `maxAmount` | `double?` | Maximum deposit amount |
| `fields` | `Map<String, AnchorField>?` | Deprecated: required fields |

`DepositExchangeAsset` — for cross-asset deposits — has `enabled`, `authenticationRequired`, and `fields` only (no fee/amount fields).

### WithdrawAsset fields

| Field | Type | Description |
|-------|------|-------------|
| `enabled` | `bool` | Whether withdrawals are supported |
| `authenticationRequired` | `bool?` | JWT required before calling withdraw |
| `feeFixed` | `double?` | Fixed fee in asset units |
| `feePercent` | `double?` | Percentage fee in percentage points |
| `minAmount` | `double?` | Minimum withdrawal amount |
| `maxAmount` | `double?` | Maximum withdrawal amount |
| `types` | `Map<String, Map<String, AnchorField>?>?` | Withdrawal methods → fields map |

`WithdrawExchangeAsset` — for cross-asset withdrawals — has `enabled`, `authenticationRequired`, and `types` only (no fee/amount fields).

### AnchorFeeInfo fields

| Field | Type | Description |
|-------|------|-------------|
| `enabled` | `bool?` | Whether the `/fee` endpoint is available |
| `authenticationRequired` | `bool?` | JWT required for `/fee` |
| `description` | `String?` | Human-readable fee description |

### AnchorTransactionInfo / AnchorTransactionsInfo fields

Both have: `enabled` (`bool?`) and `authenticationRequired` (`bool?`).

### AnchorFeatureFlags fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `accountCreation` | `bool` | `true` | Anchor can create accounts for users |
| `claimableBalances` | `bool` | `false` | Anchor can send deposits as claimable balances |

### AnchorField fields

| Field | Type | Description |
|-------|------|-------------|
| `description` | `String?` | Human-readable label shown to user |
| `optional` | `bool?` | Whether field is optional (defaults to false) |
| `choices` | `List<String>?` | Valid values if constrained |

### Reading the info response

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerService service =
    await TransferServerService.fromDomain('anchor.example.com');
InfoResponse info = await service.info();

// Check deposit assets
if (info.depositAssets != null) {
  info.depositAssets!.forEach((code, asset) {
    if (asset.enabled) {
      print('Deposit $code: min=${asset.minAmount} max=${asset.maxAmount}');
      if (asset.feeFixed != null) print('  Fixed fee: ${asset.feeFixed}');
      if (asset.feePercent != null) print('  Percent fee: ${asset.feePercent}%');
      if (asset.authenticationRequired == true) print('  Auth required');
    }
  });
}

// Check a specific deposit asset
DepositAsset? usdDeposit = info.depositAssets?['USD'];
if (usdDeposit != null && usdDeposit.enabled) {
  print('USD deposits enabled, min: ${usdDeposit.minAmount}');
}

// Check withdrawal assets and their supported types
if (info.withdrawAssets != null) {
  info.withdrawAssets!.forEach((code, asset) {
    if (asset.enabled && asset.types != null) {
      asset.types!.forEach((typeName, fields) {
        print('  Withdraw $code via $typeName');
        if (fields != null) {
          fields.forEach((fieldName, field) {
            print('    $fieldName: ${field.description} '
                '(optional=${field.optional ?? false})');
          });
        }
      });
    }
  });
}

// Check fee endpoint
if (info.feeInfo?.enabled == true) {
  print('Fee endpoint available');
  if (info.feeInfo?.authenticationRequired == true) {
    print('Fee endpoint requires auth');
  }
}

// Check feature flags
print('Account creation: ${info.featureFlags?.accountCreation}');
print('Claimable balances: ${info.featureFlags?.claimableBalances}');
```

---

## 3. Deposit Flow

A deposit is when the user sends external funds (cash, BTC, bank transfer) to the anchor, and the anchor sends equivalent Stellar tokens to the user's Stellar account. Call `info()` first to check the asset's `minAmount`/`maxAmount` and whether `type` is required by the anchor.

### DepositRequest — required and optional fields

```dart
DepositRequest({
  required String assetCode,   // on-chain asset code (must match /info deposit keys)
  required String account,     // Stellar or muxed account to receive the asset (G... or M...)
  String? memoType,            // text, id, or hash
  String? memo,                // for hash: base64-encoded
  String? emailAddress,        // anchor may use for email updates
  String? type,                // deposit method: SEPA, SWIFT, bank_account, cash, etc.
  String? walletName,          // deprecated
  String? walletUrl,           // deprecated
  String? lang,                // ISO 639-1 language code (default 'en')
  String? onChangeCallback,    // URL for anchor to POST status updates to
  String? amount,              // helps anchor determine KYC requirements
  String? countryCode,         // ISO 3166-1 alpha-3 (e.g. 'USA', 'DEU')
  String? claimableBalanceSupported,  // 'true' or 'false' as string (NOT bool)
  String? customerId,          // SEP-12 customer ID
  String? locationId,          // cash drop-off location ID
  Map<String, String>? extraFields,   // anchor-specific extra fields
  String? jwt,                 // JWT from SEP-10 authentication
})
```

### Basic deposit request

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerService service =
    await TransferServerService.fromDomain('anchor.example.com');

DepositRequest request = DepositRequest(
  assetCode: 'USD',
  account: userAccountId,   // Stellar G... or M... account
  jwt: jwtToken,
);

try {
  DepositResponse response = await service.deposit(request);

  // how: deprecated terse instructions (prefer instructions map)
  if (response.how != null) {
    print('How: ${response.how}');
  }

  // instructions: structured deposit instructions keyed by SEP-9 field names
  if (response.instructions != null) {
    response.instructions!.forEach((key, instruction) {
      print('$key: ${instruction.value} (${instruction.description})');
    });
  }

  // id: anchor's transaction ID for status polling
  if (response.id != null) {
    print('Transaction ID: ${response.id}');
  }

  print('ETA: ${response.eta}s');
  print('Fee fixed: ${response.feeFixed}');
  print('Fee percent: ${response.feePercent}');
  print('Min: ${response.minAmount}  Max: ${response.maxAmount}');

  if (response.extraInfo?.message != null) {
    print('Note: ${response.extraInfo!.message}');
  }

} on CustomerInformationNeededException catch (e) {
  // HTTP 403, type=non_interactive_customer_info_needed
  // Submit listed fields via SEP-12, then retry
  print('KYC required: ${e.response.fields}');

} on CustomerInformationStatusException catch (e) {
  // HTTP 403, type=customer_info_status
  print('KYC status: ${e.response.status}');
  print('More info: ${e.response.moreInfoUrl}');
  print('ETA: ${e.response.eta}s');

} on AuthenticationRequiredException catch (e) {
  // HTTP 403, type=authentication_required
  print('Auth required — get a JWT via SEP-10 first');
}
```

### DepositResponse fields

| Field | Type | Description |
|-------|------|-------------|
| `how` | `String?` | Deprecated. Terse deposit instructions |
| `instructions` | `Map<String, DepositInstruction>?` | Structured deposit instructions (preferred) |
| `id` | `String?` | Anchor's transaction ID |
| `eta` | `int?` | Estimated seconds to credit |
| `minAmount` | `double?` | Minimum deposit amount |
| `maxAmount` | `double?` | Maximum deposit amount |
| `feeFixed` | `double?` | Fixed fee in deposited asset units |
| `feePercent` | `double?` | Percentage fee |
| `extraInfo` | `ExtraInfo?` | Additional anchor info; has `message: String?` |

**DepositInstruction** fields: `value` (`String`), `description` (`String`).

### Deposit with all optional fields

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

DepositRequest request = DepositRequest(
  assetCode: 'USD',
  account: userAccountId,
  memoType: 'id',
  memo: '12345',
  emailAddress: 'user@example.com',
  type: 'SEPA',
  lang: 'en',
  onChangeCallback: 'https://wallet.example.com/callback',
  amount: '500.00',
  countryCode: 'USA',
  claimableBalanceSupported: 'true',   // pass as string, NOT bool
  customerId: 'cust-123',
  locationId: 'loc-456',
  extraFields: {'custom_field': 'value'},
  jwt: jwtToken,
);

DepositResponse response = await service.deposit(request);
```

---

## 4. Deposit Exchange (cross-asset)

Used when the anchor supports SEP-38 quotes and the user deposits one asset type and receives a different Stellar asset. For example: deposit BRL cash and receive USDC on Stellar.

### DepositExchangeRequest — required and optional fields

```dart
DepositExchangeRequest({
  required String destinationAsset,  // on-chain Stellar asset code to receive
  required String sourceAsset,       // off-chain asset in SEP-38 format (e.g. 'iso4217:BRL')
  required String amount,            // amount of source asset to deposit
  required String account,           // Stellar or muxed account to receive the asset
  String? quoteId,           // SEP-38 quote ID to lock in exchange rate
  String? memoType,
  String? memo,
  String? emailAddress,
  String? type,              // deposit method
  String? walletName,        // deprecated
  String? walletUrl,         // deprecated
  String? lang,
  String? onChangeCallback,
  String? countryCode,
  String? claimableBalanceSupported,
  String? customerId,
  String? locationId,
  Map<String, String>? extraFields,
  String? jwt,
})
```

`depositExchange()` returns `DepositResponse` (the same class as regular deposit).

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerService service =
    await TransferServerService.fromDomain('anchor.example.com');

// Deposit BRL (off-chain) and receive USDC on Stellar
DepositExchangeRequest request = DepositExchangeRequest(
  destinationAsset: 'USDC',         // on-chain Stellar asset code
  sourceAsset: 'iso4217:BRL',       // SEP-38 format for off-chain fiat
  amount: '480.00',                 // amount in source asset (BRL)
  account: userAccountId,
  quoteId: 'quote-id-from-sep38',  // optional: lock in exchange rate
  jwt: jwtToken,
);

try {
  DepositResponse response = await service.depositExchange(request);
  print('Transaction ID: ${response.id}');
  if (response.instructions != null) {
    response.instructions!.forEach((key, instr) {
      print('$key: ${instr.value}');
    });
  }
} on CustomerInformationNeededException catch (e) {
  print('KYC required: ${e.response.fields}');
}
```

---

## 5. Withdraw Flow

A withdrawal is when the user sends Stellar tokens to the anchor's account, and the anchor sends equivalent external funds (fiat, crypto) to the user's off-chain destination.

### WithdrawRequest — required and optional fields

```dart
WithdrawRequest({
  required String assetCode,  // on-chain asset code (must match /info withdraw keys)
  required String type,       // withdrawal method: bank_account, crypto, cash, mobile, etc.
  String? dest,               // deprecated: destination (bank account, IBAN, address, etc.)
  String? destExtra,          // deprecated: extra info (routing number, BIC, memo, etc.)
  String? account,            // source Stellar or muxed account
  String? memo,               // deprecated when using SEP-10
  String? memoType,           // deprecated: text, id, or hash
  String? walletName,         // deprecated
  String? walletUrl,          // deprecated
  String? lang,
  String? onChangeCallback,
  String? amount,
  String? countryCode,
  String? refundMemo,         // memo for refund if withdrawal fails
  String? refundMemoType,     // id, text, or hash (required if refundMemo set)
  String? customerId,
  String? locationId,
  Map<String, String>? extraFields,
  String? jwt,
})
```

### Basic withdraw request

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerService service =
    await TransferServerService.fromDomain('anchor.example.com');

WithdrawRequest request = WithdrawRequest(
  assetCode: 'USDC',
  type: 'bank_account',
  account: userAccountId,   // source Stellar account
  amount: '500.00',
  jwt: jwtToken,
);

try {
  WithdrawResponse response = await service.withdraw(request);

  // accountId: the anchor's Stellar account — send your payment HERE
  if (response.accountId != null) {
    print('Send payment to: ${response.accountId}');
  }

  // memo / memoType: MUST be included in the Stellar payment to the anchor
  if (response.memoType != null && response.memo != null) {
    print('Memo (${response.memoType}): ${response.memo}');
  }

  print('Transaction ID: ${response.id}');
  print('ETA: ${response.eta}s');
  print('Fee: ${response.feeFixed}');

  if (response.extraInfo?.message != null) {
    print('Note: ${response.extraInfo!.message}');
  }

} on CustomerInformationNeededException catch (e) {
  print('KYC required: ${e.response.fields}');
} on CustomerInformationStatusException catch (e) {
  print('KYC status: ${e.response.status}');
} on AuthenticationRequiredException catch (e) {
  print('Auth required');
}
```

### WithdrawResponse fields

| Field | Type | Description |
|-------|------|-------------|
| `accountId` | `String?` | Anchor's Stellar account — send the payment HERE |
| `memoType` | `String?` | Memo type to attach to the Stellar payment (text, id, hash) |
| `memo` | `String?` | Memo value — MUST include in the Stellar payment |
| `id` | `String?` | Anchor's transaction ID |
| `eta` | `int?` | Estimated seconds to credit |
| `minAmount` | `double?` | Minimum withdrawal amount |
| `maxAmount` | `double?` | Maximum withdrawal amount |
| `feeFixed` | `double?` | Fixed fee in withdrawn asset units |
| `feePercent` | `double?` | Percentage fee |
| `extraInfo` | `ExtraInfo?` | Additional anchor info; has `message: String?` |

---

## 6. Withdraw Exchange (cross-asset)

Used when the anchor supports SEP-38 quotes and the user sends one Stellar asset and receives a different off-chain asset. For example: send USDC on Stellar, receive NGN to bank account.

### WithdrawExchangeRequest — required and optional fields

```dart
WithdrawExchangeRequest({
  required String sourceAsset,       // on-chain Stellar asset code to withdraw
  required String destinationAsset,  // off-chain asset in SEP-38 format (e.g. 'iso4217:NGN')
  required String amount,            // amount of source asset to send
  required String type,              // withdrawal method: bank_account, crypto, cash, etc.
  String? dest,               // deprecated
  String? destExtra,          // deprecated
  String? quoteId,            // SEP-38 quote ID to lock in exchange rate
  String? account,
  String? memo,
  String? memoType,
  String? walletName,         // deprecated
  String? walletUrl,          // deprecated
  String? lang,
  String? onChangeCallback,
  String? countryCode,
  String? claimableBalanceSupported,
  String? refundMemo,
  String? refundMemoType,
  String? customerId,
  String? locationId,
  Map<String, String>? extraFields,
  String? jwt,
})
```

`withdrawExchange()` returns `WithdrawResponse` (the same class as regular withdraw).

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerService service =
    await TransferServerService.fromDomain('anchor.example.com');

// Send USDC on Stellar, receive NGN to bank account
WithdrawExchangeRequest request = WithdrawExchangeRequest(
  sourceAsset: 'USDC',              // on-chain Stellar asset
  destinationAsset: 'iso4217:NGN',  // SEP-38 format for off-chain fiat
  amount: '700',                    // amount in source asset (USDC)
  type: 'bank_account',
  quoteId: 'quote-id-from-sep38',  // optional: lock in exchange rate
  jwt: jwtToken,
);

try {
  WithdrawResponse response = await service.withdrawExchange(request);
  print('Send to: ${response.accountId}');
  if (response.memo != null) {
    print('Memo (${response.memoType}): ${response.memo}');
  }
  print('Transaction ID: ${response.id}');
} on CustomerInformationNeededException catch (e) {
  print('KYC required: ${e.response.fields}');
}
```

---

## 7. Fee Endpoint

Query the fee before initiating a transfer. Only available when `info.feeInfo?.enabled == true`.

### FeeRequest fields

```dart
FeeRequest({
  required String operation,  // 'deposit' or 'withdraw'
  required String assetCode,  // Stellar asset code
  required double amount,     // amount as double (NOT a string)
  String? type,               // deposit/withdrawal method (SEPA, bank_account, etc.)
  String? jwt,                // required if feeInfo.authenticationRequired is true
})
```

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerService service =
    await TransferServerService.fromDomain('anchor.example.com');
InfoResponse info = await service.info();

if (info.feeInfo?.enabled == true) {
  FeeRequest feeRequest = FeeRequest(
    operation: 'deposit',      // 'deposit' or 'withdraw'
    assetCode: 'USD',
    amount: 123.09,            // double, NOT a string
    type: 'SEPA',              // optional payment method
    jwt: jwtToken,             // required if feeInfo.authenticationRequired is true
  );

  FeeResponse feeResponse = await service.fee(feeRequest);
  // fee is double — total fee in asset units
  print('Fee: ${feeResponse.fee}');
}
```

`FeeResponse` has a single field: `fee` (`double`).

---

## 8. Transaction History

`transactions()` queries `GET /transactions` for deposits and withdrawals associated with an account.

### AnchorTransactionsRequest fields

```dart
AnchorTransactionsRequest({
  required String assetCode,   // asset code to filter by
  required String account,     // Stellar account ID
  DateTime? noOlderThan,       // only return transactions on or after this date
  int? limit,                  // max results
  String? kind,                // 'deposit', 'deposit-exchange', 'withdrawal', 'withdrawal-exchange'
  String? pagingId,            // pagination: return transactions before this ID (exclusive)
  String? lang,
  String? jwt,
})
```

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerService service =
    await TransferServerService.fromDomain('anchor.example.com');

AnchorTransactionsRequest request = AnchorTransactionsRequest(
  assetCode: 'USD',
  account: userAccountId,
  noOlderThan: DateTime.now().subtract(Duration(days: 30)),
  limit: 10,
  kind: 'deposit',   // optional filter
  jwt: jwtToken,
);

AnchorTransactionsResponse response = await service.transactions(request);
// response.transactions is List<AnchorTransaction>

for (AnchorTransaction tx in response.transactions) {
  print('ID: ${tx.id}  kind: ${tx.kind}  status: ${tx.status}');
  print('  amountIn: ${tx.amountIn}  amountOut: ${tx.amountOut}');
  print('  startedAt: ${tx.startedAt}  completedAt: ${tx.completedAt}');
}
```

`AnchorTransactionsResponse` has a single field: `transactions` (`List<AnchorTransaction>`).

---

## 9. Single Transaction Status

`transaction()` queries `GET /transaction` to get details and status of a specific transaction.

### AnchorTransactionRequest fields

```dart
AnchorTransactionRequest({
  String? id,                       // anchor's transaction ID
  String? stellarTransactionId,     // Stellar network transaction hash
  String? externalTransactionId,    // external system ID
  String? lang,
  String? jwt,
})
```

At least one of `id`, `stellarTransactionId`, or `externalTransactionId` must be provided.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerService service =
    await TransferServerService.fromDomain('anchor.example.com');

// Query by anchor transaction ID
AnchorTransactionRequest request = AnchorTransactionRequest(
  id: '82fhs729f63dh0v4',
  jwt: jwtToken,
);

AnchorTransactionResponse response = await service.transaction(request);
AnchorTransaction tx = response.transaction;
print('Status: ${tx.status}');
print('Kind: ${tx.kind}');

// Or query by Stellar transaction hash
AnchorTransactionRequest request2 = AnchorTransactionRequest(
  stellarTransactionId: '17a670bc424ff5ce3b386dbfa...',
  jwt: jwtToken,
);

// Or query by external transaction ID
AnchorTransactionRequest request3 = AnchorTransactionRequest(
  externalTransactionId: '1238234',
  jwt: jwtToken,
);
```

`AnchorTransactionResponse` has a single field: `transaction` (`AnchorTransaction`).

### Status polling loop

```dart
import 'dart:async';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

Future<AnchorTransaction> pollForCompletion(
    TransferServerService service, String txId, String jwt) async {
  while (true) {
    AnchorTransactionResponse response = await service.transaction(
      AnchorTransactionRequest(id: txId, jwt: jwt),
    );
    AnchorTransaction tx = response.transaction;

    if (tx.status == 'completed' || tx.status == 'error' ||
        tx.status == 'refunded' || tx.status == 'expired') {
      return tx;
    }

    // Use statusEta if provided, otherwise default polling interval
    int waitSeconds = tx.statusEta ?? 5;
    await Future.delayed(Duration(seconds: waitSeconds));
  }
}
```

---

## 10. Patch Transaction

When a transaction reaches `pending_transaction_info_update` status, the anchor needs additional information. Use `patchTransaction()` to supply the requested fields.

### PatchTransactionRequest

```dart
// id is a POSITIONAL argument (not named)
PatchTransactionRequest(
  String id,                      // positional: transaction ID to update
  {Map<String, dynamic>? fields,  // key-value pairs of fields to update
  String? jwt}
)
```

`patchTransaction()` returns `http.Response` (raw HTTP response). Check `response.statusCode == 200` for success.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:http/http.dart' as http;

TransferServerService service =
    await TransferServerService.fromDomain('anchor.example.com');

// 1. Query the transaction to see what fields are needed
AnchorTransactionResponse txResponse = await service.transaction(
  AnchorTransactionRequest(id: '82fhs729f63dh0v4', jwt: jwtToken),
);
AnchorTransaction tx = txResponse.transaction;

if (tx.status == 'pending_transaction_info_update') {
  // requiredInfoMessage describes what the anchor needs
  if (tx.requiredInfoMessage != null) {
    print('Anchor says: ${tx.requiredInfoMessage}');
  }

  // requiredInfoUpdates maps field names to AnchorField descriptions
  if (tx.requiredInfoUpdates != null) {
    tx.requiredInfoUpdates!.forEach((fieldName, field) {
      print('Required: $fieldName — ${field.description}');
    });
  }

  // 2. Submit the updated fields
  PatchTransactionRequest patchRequest = PatchTransactionRequest(
    tx.id,           // positional argument
    fields: {
      'dest': '12345678901234',    // bank account number
      'dest_extra': '021000021',   // routing number
    },
    jwt: jwtToken,
  );

  http.Response patchResponse = await service.patchTransaction(patchRequest);
  print('PATCH status: ${patchResponse.statusCode}'); // 200 = success
}
```

---

## 11. AnchorTransaction — All Fields

```dart
// Required fields (always present)
tx.id;                     // String — unique anchor-generated ID
tx.kind;                   // String — 'deposit', 'deposit-exchange', 'withdrawal', 'withdrawal-exchange'
tx.status;                 // String — see Transaction Statuses section

// Status / timing
tx.statusEta;              // int?    — estimated seconds until status change
tx.moreInfoUrl;            // String? — URL for more account/status info
tx.startedAt;              // String? — UTC ISO 8601
tx.updatedAt;              // String? — UTC ISO 8601 (time of last status change)
tx.completedAt;            // String? — UTC ISO 8601
tx.userActionRequiredBy;   // String? — deadline ISO 8601 for user action

// Amount fields (strings with up to 7 decimal places)
tx.amountIn;               // String? — amount received by anchor
tx.amountInAsset;          // String? — SEP-38 format; present for exchange transactions
tx.amountOut;              // String? — amount sent to user
tx.amountOutAsset;         // String? — SEP-38 format; present for exchange transactions
tx.amountFee;              // String? — deprecated; prefer feeDetails
tx.amountFeeAsset;         // String? — deprecated; prefer feeDetails

// Fee details (preferred over amountFee / amountFeeAsset)
tx.feeDetails;             // FeeDetails? — structured fee breakdown
// tx.feeDetails!.total: String — total fee amount
// tx.feeDetails!.asset: String — fee asset in SEP-38 format
// tx.feeDetails!.details: List<FeeDetailsDetails>? — breakdown
//   FeeDetailsDetails.name: String    (e.g. 'ACH fee', 'Service fee')
//   FeeDetailsDetails.amount: String
//   FeeDetailsDetails.description: String?

// Quote
tx.quoteId;                // String? — SEP-38 quote ID if used

// Addresses
tx.from;                   // String? — sent-from address (BTC, IBAN, Stellar, etc.)
tx.to;                     // String? — sent-to address
tx.externalExtra;          // String? — routing number, BIC, etc.
tx.externalExtraText;      // String? — bank name or store name

// Deposit-specific
tx.depositMemo;            // String? — memo used on the Stellar payment
tx.depositMemoType;        // String?

// Withdrawal-specific
tx.withdrawAnchorAccount;  // String? — anchor's Stellar account for receiving payment
tx.withdrawMemo;           // String? — memo to include in the Stellar payment to anchor
tx.withdrawMemoType;       // String?

// Stellar/external identifiers
tx.stellarTransactionId;   // String? — Stellar transaction hash
tx.externalTransactionId;  // String? — external system transaction ID

// Status messages
tx.message;                // String? — human-readable explanation of current status

// Refunds
tx.refunded;               // bool?   — deprecated; use refunds
tx.refunds;                // TransactionRefunds?
// tx.refunds!.amountRefunded: String — total refunded
// tx.refunds!.amountFee: String      — total refund processing fees
// tx.refunds!.payments: List<TransactionRefundPayment>
//   TransactionRefundPayment.id: String    (Stellar hash or external ref)
//   TransactionRefundPayment.idType: String ('stellar' or 'external')
//   TransactionRefundPayment.amount: String
//   TransactionRefundPayment.fee: String

// Pending info update (when status = pending_transaction_info_update)
tx.requiredInfoMessage;    // String?                     — explanation of what's needed
tx.requiredInfoUpdates;    // Map<String, AnchorField>?   — fields to supply via PATCH

// Deposit instructions (appears when status reaches pending_user_transfer_start)
tx.instructions;           // Map<String, DepositInstruction>?

// Claimable balance
tx.claimableBalanceId;     // String? — Claimable Balance ID if deposit used claimable balances
```

---

## 12. Transaction Statuses

| Status | Meaning |
|--------|---------|
| `incomplete` | Missing required info; user action needed |
| `pending_user_transfer_start` | Waiting for user to send funds to anchor |
| `pending_user_transfer_complete` | User sent funds; anchor processing |
| `pending_external` | Waiting on external system (bank, crypto network) |
| `pending_anchor` | Anchor is processing internally |
| `pending_stellar` | Stellar transaction pending |
| `pending_trust` | User must add a trustline for the asset |
| `pending_customer_info_update` | Anchor needs more KYC info via SEP-12 |
| `pending_transaction_info_update` | Anchor needs more transaction info — check `requiredInfoUpdates`, then PATCH |
| `on_hold` | On hold (e.g., compliance review) |
| `completed` | Successfully completed |
| `refunded` | Refunded to user |
| `expired` | Timed out without completion |
| `no_market` | No market available for conversion |
| `too_small` | Amount below anchor's minimum |
| `too_large` | Amount exceeds anchor's maximum |
| `error` | Unrecoverable error |

---

## 13. Error Handling

Three domain-specific exceptions are thrown from `deposit()`, `depositExchange()`, `withdraw()`, and `withdrawExchange()` when the server returns HTTP 403.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

try {
  DepositResponse response = await service.deposit(request);

} on CustomerInformationNeededException catch (e) {
  // HTTP 403, type=non_interactive_customer_info_needed
  // e.response is CustomerInformationNeededResponse
  // e.response.fields is List<String>? — SEP-12 field names to submit
  print('KYC fields required: ${e.response.fields}');
  // Submit listed fields via SEP-12 PUT /customer, then retry

} on CustomerInformationStatusException catch (e) {
  // HTTP 403, type=customer_info_status
  // e.response is CustomerInformationStatusResponse
  String? status = e.response.status;    // 'pending' or 'denied'
  String? url = e.response.moreInfoUrl;  // String?
  int? eta = e.response.eta;             // int? seconds
  if (status == 'denied') {
    print('KYC denied. Details: $url');
  } else if (status == 'pending') {
    print('KYC under review. ETA: ${eta}s');
  }

} on AuthenticationRequiredException catch (e) {
  // HTTP 403, type=authentication_required
  // No JWT provided or JWT is invalid/expired
  print('Auth required — obtain a JWT via SEP-10 first');

} on ErrorResponse catch (e) {
  // Other HTTP error codes (400, 404, 500, etc.)
  print('HTTP ${e.code}: ${e.body}');
}
```

### Exception reference

| Exception | When thrown | `.response` type |
|-----------|-------------|-----------------|
| `CustomerInformationNeededException` | KYC data required | `CustomerInformationNeededResponse` |
| `CustomerInformationStatusException` | KYC pending or denied | `CustomerInformationStatusResponse` |
| `AuthenticationRequiredException` | No/invalid JWT token | none (no `.response` field) |

**CustomerInformationNeededResponse:**
- `fields: List<String>?` — list of SEP-12 field names to submit

**CustomerInformationStatusResponse:**
- `status: String?` — `'pending'` or `'denied'`
- `moreInfoUrl: String?`
- `eta: int?` — estimated seconds until status update

---

## 14. Common Pitfalls

**WRONG: `FeeRequest.amount` is `double`, not `String`**

```dart
// WRONG: amount field is double — passing a string causes a type error
FeeRequest(operation: 'deposit', assetCode: 'USD', amount: '123.09');

// CORRECT: amount is double
FeeRequest(operation: 'deposit', assetCode: 'USD', amount: 123.09);
```

**WRONG: `PatchTransactionRequest` takes `id` as positional, not named**

```dart
// WRONG: id is positional — named form causes compile error
PatchTransactionRequest(id: 'tx-123', fields: {...}, jwt: token);

// CORRECT: id is the first positional argument
PatchTransactionRequest('tx-123', fields: {...}, jwt: token);
```

**WRONG: forgetting the memo when sending a Stellar payment for a withdrawal**

When `withdraw()` returns, you must build a Stellar payment to `WithdrawResponse.accountId` and include `WithdrawResponse.memo` / `WithdrawResponse.memoType`. Without the memo the anchor cannot match the transaction.

```dart
// After calling service.withdraw(request):
// response.accountId — anchor's Stellar account to pay
// response.memo      — memo value to include
// response.memoType  — 'text', 'id', or 'hash'
```

**WRONG: `WithdrawAsset.types` values are `Map<String, AnchorField>?`, not `AnchorField`**

```dart
// WRONG: each type value is a fields map, not a single AnchorField
if (asset.types != null) {
  asset.types!.forEach((typeName, field) {
    print(field.description); // TypeError — field is Map<String, AnchorField>? not AnchorField
  });
}

// CORRECT: each type maps to a nullable map of field names to AnchorField
if (asset.types != null) {
  asset.types!.forEach((typeName, fields) {
    print('Type: $typeName');
    if (fields != null) {
      fields.forEach((fieldName, field) {
        print('  $fieldName: ${field.description}');
      });
    }
  });
}
```

**WRONG: treating `patchTransaction` response as a typed SDK object**

```dart
// WRONG: patchTransaction does not return a typed response
DepositResponse r = await service.patchTransaction(patchRequest); // compile error

// CORRECT: returns raw http.Response — check statusCode
import 'package:http/http.dart' as http;
http.Response response = await service.patchTransaction(patchRequest);
print(response.statusCode); // 200 = success
```

**WRONG: passing `claimableBalanceSupported` as a bool**

```dart
// WRONG: field type is String?, not bool
DepositRequest(assetCode: 'USD', account: id, claimableBalanceSupported: true);

// CORRECT: pass as string 'true' or 'false'
DepositRequest(assetCode: 'USD', account: id, claimableBalanceSupported: 'true');
```

**WRONG: using `fromDomain()` without `await`**

```dart
// WRONG: returns Future<TransferServerService>, not TransferServerService
TransferServerService service = TransferServerService.fromDomain('anchor.example.com');

// CORRECT: must await the async factory
TransferServerService service = await TransferServerService.fromDomain('anchor.example.com');
```

