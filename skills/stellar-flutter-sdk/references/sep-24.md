# SEP-24: Interactive Deposit and Withdrawal

**Purpose:** Interactive web flows for depositing external assets (fiat, crypto) to receive Stellar tokens, or withdrawing Stellar tokens to an external destination (bank account, crypto wallet, etc.).
**Prerequisites:** Requires JWT from SEP-10 (see `references/sep-10.md`); anchor must publish `TRANSFER_SERVER_SEP0024` in `stellar.toml`

## Table of Contents

1. [Service Initialization](#1-service-initialization)
2. [Info Endpoint](#2-info-endpoint)
3. [Fee Endpoint (deprecated)](#3-fee-endpoint-deprecated)
4. [Deposit Flow](#4-deposit-flow)
5. [Withdrawal Flow](#5-withdrawal-flow)
6. [Transaction Status Polling](#6-transaction-status-polling)
7. [Transaction History](#7-transaction-history)
8. [SEP24Transaction — All Fields](#8-sep24transaction--all-fields)
9. [Transaction Statuses](#9-transaction-statuses)
10. [Refund Objects](#10-refund-objects)
11. [Error Handling](#11-error-handling)
12. [Common Pitfalls](#12-common-pitfalls)

---

## 1. Service Initialization

### From domain (recommended)

`TransferServerSEP24Service.fromDomain()` fetches the anchor's `stellar.toml`, reads `TRANSFER_SERVER_SEP0024`, and returns a configured service instance. Throws if the field is absent.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Fetches stellar.toml from https://testanchor.stellar.org/.well-known/stellar.toml
// and reads TRANSFER_SERVER_SEP0024
TransferServerSEP24Service service =
    await TransferServerSEP24Service.fromDomain('testanchor.stellar.org');
```

Method signature:
```dart
static Future<TransferServerSEP24Service> fromDomain(
  String domain, {
  http.Client? httpClient,
  Map<String, String>? httpRequestHeaders,
})
```

### Direct construction

Use when you already have the transfer server URL.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerSEP24Service service =
    TransferServerSEP24Service('https://api.anchor.com/sep24');
```

Constructor signature:
```dart
TransferServerSEP24Service(
  String transferServiceAddress, {
  http.Client? httpClient,
  Map<String, String>? httpRequestHeaders,
})
```

### With a custom HTTP client

```dart
import 'package:http/http.dart' as http;
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final client = http.Client();
TransferServerSEP24Service service = await TransferServerSEP24Service.fromDomain(
  'testanchor.stellar.org',
  httpClient: client,
  httpRequestHeaders: {'User-Agent': 'MyWallet/1.0'},
);
```

---

## 2. Info Endpoint

`info()` queries `GET /info` to discover supported assets, fee structures, and feature flags. No authentication required.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerSEP24Service service =
    await TransferServerSEP24Service.fromDomain('testanchor.stellar.org');

// Optional: pass a language code (ISO 639-1, e.g. 'en', 'de')
SEP24InfoResponse infoResponse = await service.info('en');
// Or without language:
SEP24InfoResponse infoResponse = await service.info();
```

Method signature:
```dart
Future<SEP24InfoResponse> info([String? lang])
```

### SEP24InfoResponse fields

| Field | Type | Description |
|-------|------|-------------|
| `depositAssets` | `Map<String, SEP24DepositAsset>?` | Keyed by asset code; null if absent |
| `withdrawAssets` | `Map<String, SEP24WithdrawAsset>?` | Keyed by asset code; null if absent |
| `feeEndpointInfo` | `FeeEndpointInfo?` | Info about the `/fee` endpoint; null if absent |
| `featureFlags` | `FeatureFlags?` | Optional features the anchor supports; null if absent |

### SEP24DepositAsset fields

| Field | Type | Description |
|-------|------|-------------|
| `enabled` | `bool` | Whether deposit of this asset is supported |
| `minAmount` | `double?` | Minimum deposit amount; no limit if null |
| `maxAmount` | `double?` | Maximum deposit amount; no limit if null |
| `feeFixed` | `double?` | Fixed fee in units of the deposited asset |
| `feePercent` | `double?` | Percentage fee in percentage points |
| `feeMinimum` | `double?` | Minimum fee in units of the deposited asset |

`SEP24WithdrawAsset` has the same fields.

### FeeEndpointInfo fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `enabled` | `bool` | — | Whether the `/fee` endpoint is available |
| `authenticationRequired` | `bool` | `false` | Whether JWT is required for `/fee` |

### FeatureFlags fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `accountCreation` | `bool` | `true` | Anchor can create accounts for users |
| `claimableBalances` | `bool` | `false` | Anchor can send deposits as claimable balances |

### Reading info response

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerSEP24Service service =
    await TransferServerSEP24Service.fromDomain('testanchor.stellar.org');
SEP24InfoResponse info = await service.info();

// Check deposit assets (keyed by asset code)
if (info.depositAssets != null) {
  info.depositAssets!.forEach((code, asset) {
    if (asset.enabled) {
      print('Deposit $code: min=${asset.minAmount} max=${asset.maxAmount}');
      if (asset.feeFixed != null) print('  Fixed fee: ${asset.feeFixed}');
      if (asset.feePercent != null) print('  Percent fee: ${asset.feePercent}%');
      if (asset.feeMinimum != null) print('  Min fee: ${asset.feeMinimum}');
    }
  });
}

// Check a specific asset
SEP24DepositAsset? usdDeposit = info.depositAssets?['USD'];
if (usdDeposit != null && usdDeposit.enabled) {
  print('USD deposit enabled');
}

// Check withdraw assets
SEP24WithdrawAsset? usdWithdraw = info.withdrawAssets?['USD'];
if (usdWithdraw != null && usdWithdraw.enabled) {
  print('USD withdrawal enabled, fee minimum: ${usdWithdraw.feeMinimum}');
}

// Check feature support
if (info.featureFlags != null) {
  print('Account creation: ${info.featureFlags!.accountCreation}');
  print('Claimable balances: ${info.featureFlags!.claimableBalances}');
}

// Check fee endpoint
if (info.feeEndpointInfo != null) {
  print('Fee endpoint enabled: ${info.feeEndpointInfo!.enabled}');
  print('Auth required: ${info.feeEndpointInfo!.authenticationRequired}');
}
```

---

## 3. Fee Endpoint (deprecated)

The `/fee` endpoint is deprecated in favor of SEP-38 `GET /price`. Only use it if the anchor's `/info` response indicates it is enabled (`info.feeEndpointInfo?.enabled == true`). Authentication may be required (check `info.feeEndpointInfo?.authenticationRequired`).

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerSEP24Service service =
    await TransferServerSEP24Service.fromDomain('testanchor.stellar.org');
SEP24InfoResponse info = await service.info();

if (info.feeEndpointInfo?.enabled == true) {
  SEP24FeeRequest feeRequest = SEP24FeeRequest()
    ..operation = 'deposit'     // 'deposit' or 'withdraw'
    ..assetCode = 'USD'
    ..amount = 100.0
    ..type = 'bank_account'     // optional: payment type (SEPA, bank_account, etc.)
    ..jwt = jwtToken;           // required if authenticationRequired is true

  SEP24FeeResponse feeResponse = await service.fee(feeRequest);
  print('Fee: ${feeResponse.fee}');
}
```

Method signature:
```dart
Future<SEP24FeeResponse> fee(SEP24FeeRequest request)
```

### SEP24FeeRequest fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `operation` | `String` | Yes (`late`) | `'deposit'` or `'withdraw'` |
| `assetCode` | `String` | Yes (`late`) | Asset code (e.g. `'USD'`, `'ETH'`) |
| `amount` | `double` | Yes (`late`) | Amount to deposit/withdraw |
| `type` | `String?` | No | Payment method type (e.g. `'SEPA'`, `'bank_account'`) |
| `jwt` | `String?` | Conditional | JWT token; required if `authenticationRequired` is true |

`SEP24FeeResponse` has a single field: `fee` (`double?`).

**Throws:** `SEP24AuthenticationRequiredException` (403), `RequestErrorException` (4xx/5xx).

---

## 4. Deposit Flow

A deposit converts external funds (bank transfer, crypto, etc.) into Stellar tokens sent to the user's account. The anchor returns a URL for the user to complete the process interactively.

`deposit()` posts to `POST /transactions/deposit/interactive`.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerSEP24Service service =
    await TransferServerSEP24Service.fromDomain('testanchor.stellar.org');

SEP24DepositRequest request = SEP24DepositRequest()
  ..assetCode = 'USDC'
  ..jwt = jwtToken;   // JWT from SEP-10 authentication — always required

SEP24InteractiveResponse response = await service.deposit(request);

// Open this URL in a browser popup or webview
print('Open URL: ${response.url}');
// Save transaction ID for polling
String transactionId = response.id;
// response.type is always 'interactive_customer_info_needed'
```

Method signature:
```dart
Future<SEP24InteractiveResponse> deposit(SEP24DepositRequest request)
```

### SEP24DepositRequest fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `jwt` | `String` | Yes (`late`) | JWT from SEP-10 authentication |
| `assetCode` | `String` | Yes (`late`) | Asset code to receive; use `'native'` for XLM |
| `assetIssuer` | `String?` | No | Issuer G... address; omit for `'native'` |
| `sourceAsset` | `String?` | No | SEP-38 format asset user sends (e.g. `'iso4217:EUR'`) |
| `amount` | `String?` | No | Amount as string (e.g. `'100.0'`); collected in flow if omitted |
| `quoteId` | `String?` | No | SEP-38 quote ID for cross-asset deposits |
| `account` | `String?` | No | Destination Stellar or muxed account; defaults to JWT account |
| `memo` | `String?` | No | Memo to attach; hash type must be base64-encoded |
| `memoType` | `String?` | No | Memo type: `'text'`, `'id'`, or `'hash'` |
| `walletName` | `String?` | No | Wallet display name |
| `walletUrl` | `String?` | No | Wallet URL |
| `lang` | `String?` | No | RFC 4646 language for the interactive UI (e.g. `'en-US'`) |
| `claimableBalanceSupported` | `String?` | No | `'true'` if client supports claimable balances |
| `kycFields` | `StandardKYCFields?` | No | SEP-9 KYC data to pre-fill the interactive form |
| `customFields` | `Map<String, String>?` | No | Non-standard KYC fields |
| `customFiles` | `Map<String, Uint8List>?` | No | Non-standard file uploads |

### SEP24InteractiveResponse fields

| Field | Type | Description |
|-------|------|-------------|
| `type` | `String` | Always `'interactive_customer_info_needed'` |
| `url` | `String` | URL to open in a browser or webview for the user |
| `id` | `String` | Anchor-generated transaction ID for polling |

### Deposit with amount and destination account

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerSEP24Service service =
    await TransferServerSEP24Service.fromDomain('testanchor.stellar.org');

SEP24DepositRequest request = SEP24DepositRequest()
  ..assetCode = 'USD'
  ..amount = '100.0'   // String, not double
  ..account = 'GXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
  ..memo = '12345'
  ..memoType = 'id'    // 'text', 'id', or 'hash'
  ..lang = 'en-US'
  ..jwt = jwtToken;

SEP24InteractiveResponse response = await service.deposit(request);
print('Open: ${response.url}');
```

### Deposit with SEP-38 quote (cross-asset)

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Get quoteId from SEP-38 service first
SEP24DepositRequest request = SEP24DepositRequest()
  ..assetCode = 'USDC'
  ..sourceAsset = 'iso4217:EUR'  // user sends EUR, receives USDC
  ..quoteId = 'quote-abc-123'
  ..amount = '100.0'             // must match the quote's sell_amount
  ..jwt = jwtToken;

SEP24InteractiveResponse response = await service.deposit(request);
```

### Deposit with KYC pre-fill

Pass KYC data to pre-fill the anchor's interactive form. Use `StandardKYCFields` with `NaturalPersonKYCFields` for individuals and `OrganizationKYCFields` for businesses.

```dart
import 'dart:typed_data';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerSEP24Service service =
    await TransferServerSEP24Service.fromDomain('testanchor.stellar.org');

// Individual KYC
NaturalPersonKYCFields personFields = NaturalPersonKYCFields()
  ..firstName = 'George'
  ..emailAddress = 'george@example.com';

// Bank details nested under person fields
FinancialAccountKYCFields bankFields = FinancialAccountKYCFields()
  ..bankAccountNumber = 'XX18981288373773';
personFields.financialAccountKYCFields = bankFields;

// Organization KYC (optional — add both if needed)
OrganizationKYCFields orgFields = OrganizationKYCFields()
  ..name = 'George Ltd.';
FinancialAccountKYCFields orgBankFields = FinancialAccountKYCFields()
  ..bankAccountNumber = 'YY76253437289616234';
orgFields.financialAccountKYCFields = orgBankFields;

StandardKYCFields kycFields = StandardKYCFields()
  ..naturalPersonKYCFields = personFields
  ..organizationKYCFields = orgFields;

// For file uploads (NOT available on web platforms):
// personFields.photoIdFront = await Util.readFile('/path/to/id.jpg');
// For web: use a file picker and pass bytes directly via customFiles

SEP24DepositRequest request = SEP24DepositRequest()
  ..assetCode = 'USD'
  ..kycFields = kycFields
  // Anchor-specific fields not in SEP-9:
  ..customFields = {'employer_name': 'Tech Corp'}
  ..customFiles = {'proof_of_income': Uint8List.fromList([...])}
  ..jwt = jwtToken;

SEP24InteractiveResponse response = await service.deposit(request);
```

### Deposit with claimable balance support

```dart
SEP24DepositRequest request = SEP24DepositRequest()
  ..assetCode = 'USD'
  // Tell the anchor the client supports receiving claimable balances.
  // Useful if the account has no trustline for the asset.
  // Note: this is a String field, not bool — pass 'true' not true
  ..claimableBalanceSupported = 'true'
  ..jwt = jwtToken;

SEP24InteractiveResponse response = await service.deposit(request);
// After completion, check tx.claimableBalanceId if the anchor used a claimable balance
```

**Throws:** `SEP24AuthenticationRequiredException` (403), `RequestErrorException` (4xx/5xx).

---

## 5. Withdrawal Flow

A withdrawal converts Stellar tokens into external assets sent to a bank account or other destination. After the user completes the interactive flow, the wallet sends a Stellar payment to the anchor's account.

`withdraw()` posts to `POST /transactions/withdraw/interactive`.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerSEP24Service service =
    await TransferServerSEP24Service.fromDomain('testanchor.stellar.org');

SEP24WithdrawRequest request = SEP24WithdrawRequest()
  ..assetCode = 'USDC'
  ..jwt = jwtToken;   // JWT from SEP-10 authentication — always required

SEP24InteractiveResponse response = await service.withdraw(request);

print('Open URL: ${response.url}');
String transactionId = response.id;
```

Method signature:
```dart
Future<SEP24InteractiveResponse> withdraw(SEP24WithdrawRequest request)
```

### SEP24WithdrawRequest fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `jwt` | `String` | Yes (`late`) | JWT from SEP-10 authentication |
| `assetCode` | `String` | Yes (`late`) | Asset code to withdraw; use `'native'` for XLM |
| `assetIssuer` | `String?` | No | Issuer G... address; omit for `'native'` |
| `destinationAsset` | `String?` | No | SEP-38 format asset user receives (e.g. `'iso4217:EUR'`) |
| `amount` | `String?` | No | Amount as string; collected in flow if omitted |
| `quoteId` | `String?` | No | SEP-38 quote ID for cross-asset withdrawals |
| `account` | `String?` | No | Source Stellar or muxed account; defaults to JWT account |
| `memo` | `String?` | No | Deprecated — use SEP-10 JWT `sub` for shared accounts |
| `memoType` | `String?` | No | Deprecated — type of deprecated `memo` field |
| `walletName` | `String?` | No | Wallet display name |
| `walletUrl` | `String?` | No | Wallet URL |
| `lang` | `String?` | No | RFC 4646 language for the interactive UI |
| `refundMemo` | `String?` | No | Memo for refund payments; requires `refundMemoType` |
| `refundMemoType` | `String?` | No | Refund memo type: `'text'`, `'id'`, or `'hash'` |
| `kycFields` | `StandardKYCFields?` | No | SEP-9 KYC data to pre-fill the interactive form |
| `customFields` | `Map<String, String>?` | No | Non-standard KYC fields |
| `customFiles` | `Map<String, Uint8List>?` | No | Non-standard file uploads |

### Withdrawal with refund memo

```dart
SEP24WithdrawRequest request = SEP24WithdrawRequest()
  ..assetCode = 'USD'
  ..amount = '500.0'
  // Memo the anchor uses if it needs to send a refund payment back
  ..refundMemo = 'refund-ref-123'
  ..refundMemoType = 'text'   // 'text', 'id', or 'hash'
  // Must set both refundMemo and refundMemoType together
  ..jwt = jwtToken;

SEP24InteractiveResponse response = await service.withdraw(request);
```

### Withdrawal with SEP-38 quote (cross-asset)

```dart
SEP24WithdrawRequest request = SEP24WithdrawRequest()
  ..assetCode = 'USDC'
  ..destinationAsset = 'iso4217:EUR'  // user sends USDC, receives EUR
  ..quoteId = 'quote-xyz-789'
  ..amount = '500.0'
  ..jwt = jwtToken;

SEP24InteractiveResponse response = await service.withdraw(request);
```

### Completing a withdrawal: sending the Stellar payment

After the user completes the interactive flow, poll for `pending_user_transfer_start` status, then send the Stellar payment to the anchor's account.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerSEP24Service service =
    await TransferServerSEP24Service.fromDomain('testanchor.stellar.org');

SEP24TransactionRequest txRequest = SEP24TransactionRequest()
  ..id = transactionId
  ..jwt = jwtToken;

SEP24TransactionResponse txResponse = await service.transaction(txRequest);
SEP24Transaction tx = txResponse.transaction;

if (tx.status == 'pending_user_transfer_start') {
  // withdrawMemo may be null if KYC is not yet complete — check before sending
  if (tx.withdrawMemo == null) {
    print('KYC not yet verified — wait before sending payment');
    // Continue polling until withdrawMemo is set
  } else {
    // Read withdrawal payment details from transaction
    String anchorAccount = tx.withdrawAnchorAccount!; // anchor's Stellar account
    String memo = tx.withdrawMemo!;
    String memoType = tx.withdrawMemoType!;  // 'text', 'id', or 'hash'
    String amount = tx.amountIn!;

    StellarSDK sdk = StellarSDK.TESTNET;
    KeyPair sourceKeyPair = KeyPair.fromSecretSeed(secretSeed);
    AccountResponse sourceAccount = await sdk.accounts.account(sourceKeyPair.accountId);

    Asset asset = Asset.createNonNativeAsset('USD', issuerAccountId);

    Transaction transaction = new TransactionBuilder(sourceAccount)
        .addOperation(PaymentOperationBuilder(anchorAccount, asset, amount).build())
        .addMemo(Memo.text(memo))  // adjust for memoType
        .build();

    transaction.sign(sourceKeyPair, Network.TESTNET);
    await sdk.submitTransaction(transaction);
  }
}
```

**Throws:** `SEP24AuthenticationRequiredException` (403), `RequestErrorException` (4xx/5xx).

---

## 6. Transaction Status Polling

Use `transaction()` to query a single transaction by ID. Always use the `id` from `deposit()` or `withdraw()` for polling.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerSEP24Service service =
    await TransferServerSEP24Service.fromDomain('testanchor.stellar.org');

// Query by anchor transaction ID (from deposit/withdraw response)
SEP24TransactionRequest request = SEP24TransactionRequest()
  ..id = transactionId           // from SEP24InteractiveResponse.id
  ..jwt = jwtToken;

// OR query by Stellar network transaction hash
// ..stellarTransactionId = 'abc123...'

// OR query by external system transaction ID
// ..externalTransactionId = 'BANK-REF-123'

// Optional: ..lang = 'en'

SEP24TransactionResponse response = await service.transaction(request);
SEP24Transaction tx = response.transaction;

print('Status: ${tx.status}');
print('Kind: ${tx.kind}');
```

Method signature:
```dart
Future<SEP24TransactionResponse> transaction(SEP24TransactionRequest request)
```

`SEP24TransactionResponse` has a single field: `transaction` (`SEP24Transaction`).

### SEP24TransactionRequest fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `jwt` | `String` | Yes (`late`) | JWT from SEP-10 authentication |
| `id` | `String?` | Conditional | Anchor's internal transaction ID |
| `stellarTransactionId` | `String?` | Conditional | Stellar network transaction hash |
| `externalTransactionId` | `String?` | Conditional | External system transaction ID |
| `lang` | `String?` | No | RFC 4646 language code |

At least one of `id`, `stellarTransactionId`, or `externalTransactionId` must be set.

**Throws:** `SEP24TransactionNotFoundException` (404), `SEP24AuthenticationRequiredException` (403), `RequestErrorException` (4xx/5xx).

### Polling loop

```dart
import 'dart:async';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

const terminalStatuses = {
  'completed', 'refunded', 'expired', 'error',
  'no_market', 'too_small', 'too_large',
};

SEP24TransactionRequest request = SEP24TransactionRequest()
  ..id = transactionId
  ..jwt = jwtToken;

// Poll every 5 seconds until terminal status
Timer? pollingTimer;
pollingTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
  try {
    SEP24TransactionResponse response = await service.transaction(request);
    SEP24Transaction tx = response.transaction;

    print('Status: ${tx.status}');

    if (terminalStatuses.contains(tx.status)) {
      timer.cancel();
      if (tx.status == 'completed') {
        print('Transaction completed! Amount out: ${tx.amountOut}');
      } else if (tx.status == 'error') {
        print('Error: ${tx.message}');
      }
      return;
    }

    if (tx.status == 'pending_user_transfer_start' && tx.kind == 'withdrawal') {
      timer.cancel();
      // User must send the Stellar payment now
      // See "Completing a withdrawal" above
      return;
    }

    // Use statusEta hint if provided
    if (tx.statusEta != null && tx.statusEta! > 0) {
      print('Expected update in ${tx.statusEta} seconds');
    }
  } on SEP24TransactionNotFoundException {
    pollingTimer?.cancel();
    print('Transaction not found');
  } on SEP24AuthenticationRequiredException {
    pollingTimer?.cancel();
    print('Re-authenticate and retry');
  } catch (e) {
    print('Error polling: $e');
  }
});
```

---

## 7. Transaction History

`transactions()` returns a list of transactions for the authenticated account, filtered by asset. Queries `GET /transactions`.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerSEP24Service service =
    await TransferServerSEP24Service.fromDomain('testanchor.stellar.org');

SEP24TransactionsRequest request = SEP24TransactionsRequest()
  ..assetCode = 'USD'       // required
  ..jwt = jwtToken;         // required

SEP24TransactionsResponse response = await service.transactions(request);
List<SEP24Transaction> transactions = response.transactions;

for (SEP24Transaction tx in transactions) {
  print('${tx.id}: ${tx.kind} - ${tx.status}');
}
```

Method signature:
```dart
Future<SEP24TransactionsResponse> transactions(SEP24TransactionsRequest request)
```

`SEP24TransactionsResponse` has a single field: `transactions` (`List<SEP24Transaction>`), always a list (never null; may be empty).

### SEP24TransactionsRequest fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `jwt` | `String` | Yes (`late`) | JWT from SEP-10 authentication |
| `assetCode` | `String` | Yes (`late`) | Asset code to filter by |
| `noOlderThan` | `DateTime?` | No | Only include transactions from this date onward |
| `limit` | `int?` | No | Maximum number of transactions to return |
| `kind` | `String?` | No | `'deposit'` or `'withdrawal'`; omit for both |
| `pagingId` | `String?` | No | Returns transactions prior to (exclusive) this ID |
| `lang` | `String?` | No | RFC 4646 language code |

### Transaction history with filters and pagination

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SEP24TransactionsRequest request = SEP24TransactionsRequest()
  ..assetCode = 'USD'
  ..limit = 10
  ..kind = 'deposit'                              // 'deposit' or 'withdrawal'
  ..noOlderThan = DateTime.utc(2024, 1, 1)        // DateTime, not String
  ..lang = 'en'
  ..jwt = jwtToken;

SEP24TransactionsResponse response = await service.transactions(request);

// Pagination: pass the last transaction ID as pagingId for the next page
if (response.transactions.isNotEmpty) {
  String lastId = response.transactions.last.id;

  SEP24TransactionsRequest nextPage = SEP24TransactionsRequest()
    ..assetCode = 'USD'
    ..limit = 10
    ..pagingId = lastId   // returns transactions prior to this ID (exclusive)
    ..jwt = jwtToken;

  SEP24TransactionsResponse page2 = await service.transactions(nextPage);
}
```

**Throws:** `SEP24AuthenticationRequiredException` (403), `RequestErrorException` (4xx/5xx).

---

## 8. SEP24Transaction — All Fields

The `SEP24Transaction` object is returned inside `SEP24TransactionResponse.transaction` and each element of `SEP24TransactionsResponse.transactions`.

### Always-present fields

| Dart field | JSON key | Type | Description |
|-----------|----------|------|-------------|
| `id` | `id` | `String` | Unique anchor-generated transaction ID |
| `kind` | `kind` | `String` | `'deposit'`, `'withdrawal'`, `'deposit-exchange'`, or `'withdrawal-exchange'` |
| `status` | `status` | `String` | Current processing status |
| `moreInfoUrl` | `more_info_url` | `String?` | URL with additional transaction details; null if anchor omits |
| `startedAt` | `started_at` | `String` | ISO 8601 UTC start timestamp |

### Optional fields (all nullable)

| Dart field | JSON key | Type | Description |
|-----------|----------|------|-------------|
| `statusEta` | `status_eta` | `int?` | Estimated seconds until next status change |
| `kycVerified` | `kyc_verified` | `bool?` | Whether anchor verified user's KYC |
| `amountIn` | `amount_in` | `String?` | Amount received by anchor (up to 7 decimals, as string) |
| `amountInAsset` | `amount_in_asset` | `String?` | SEP-38 format asset received |
| `amountOut` | `amount_out` | `String?` | Amount sent to user (up to 7 decimals, as string) |
| `amountOutAsset` | `amount_out_asset` | `String?` | SEP-38 format asset sent to user |
| `amountFee` | `amount_fee` | `String?` | Fee charged by anchor (as string) |
| `amountFeeAsset` | `amount_fee_asset` | `String?` | SEP-38 format asset for fee |
| `quoteId` | `quote_id` | `String?` | SEP-38 quote ID used for this transaction |
| `completedAt` | `completed_at` | `String?` | ISO 8601 UTC completion timestamp |
| `updatedAt` | `updated_at` | `String?` | ISO 8601 UTC last-update timestamp |
| `userActionRequiredBy` | `user_action_required_by` | `String?` | Deadline for user action (ISO 8601 UTC) |
| `stellarTransactionId` | `stellar_transaction_id` | `String?` | Stellar network transaction hash |
| `externalTransactionId` | `external_transaction_id` | `String?` | External system transaction ID |
| `message` | `message` | `String?` | Human-readable status explanation |
| `refunded` | `refunded` | `bool?` | Deprecated — use `refunds` and `'refunded'` status instead |
| `refunds` | `refunds` | `Refund?` | Refund details if transaction was refunded |
| `from` | `from` | `String?` | Deposit: sender address; Withdrawal: source Stellar address |
| `to` | `to` | `String?` | Deposit: destination Stellar address; Withdrawal: destination address |

### Deposit-only fields

| Dart field | JSON key | Type | Description |
|-----------|----------|------|-------------|
| `depositMemo` | `deposit_memo` | `String?` | Memo used in the deposit payment |
| `depositMemoType` | `deposit_memo_type` | `String?` | Memo type for `depositMemo` |
| `claimableBalanceId` | `claimable_balance_id` | `String?` | ID of Claimable Balance used to send asset |

### Withdrawal-only fields

| Dart field | JSON key | Type | Description |
|-----------|----------|------|-------------|
| `withdrawAnchorAccount` | `withdraw_anchor_account` | `String?` | Anchor's Stellar account to send payment to |
| `withdrawMemo` | `withdraw_memo` | `String?` | Memo to include in payment; null if KYC not complete |
| `withdrawMemoType` | `withdraw_memo_type` | `String?` | Memo type for `withdrawMemo` |

### Reading transaction fields

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SEP24TransactionResponse response = await service.transaction(
  SEP24TransactionRequest()
    ..id = transactionId
    ..jwt = jwtToken,
);
SEP24Transaction tx = response.transaction;

// Always-present fields
print('ID: ${tx.id}');
print('Kind: ${tx.kind}');
print('Status: ${tx.status}');
if (tx.moreInfoUrl != null) print('More info: ${tx.moreInfoUrl}');
print('Started: ${tx.startedAt}');

// Amount fields — strings (compare as strings or cast to double for arithmetic)
if (tx.amountIn != null) print('Amount in: ${tx.amountIn}');
if (tx.amountOut != null) print('Amount out: ${tx.amountOut}');
if (tx.amountFee != null) print('Fee: ${tx.amountFee}');

// KYC and deadline
if (tx.kycVerified == true) print('KYC verified');
if (tx.userActionRequiredBy != null) {
  print('Action required by: ${tx.userActionRequiredBy}');
}

// Withdrawal payment instructions
if (tx.kind == 'withdrawal' && tx.status == 'pending_user_transfer_start') {
  if (tx.withdrawMemo != null) {
    print('Send ${tx.amountIn} to ${tx.withdrawAnchorAccount}');
    print('Memo: ${tx.withdrawMemo} (${tx.withdrawMemoType})');
  }
}

// Deposit claimable balance
if (tx.kind == 'deposit' && tx.claimableBalanceId != null) {
  print('Claim balance ID: ${tx.claimableBalanceId}');
}
```

---

## 9. Transaction Statuses

The `status` field on `SEP24Transaction`:

| Status | Description |
|--------|-------------|
| `incomplete` | User has not completed the interactive flow yet |
| `pending_user_transfer_start` | Waiting for user to send funds (deposit: external; withdrawal: Stellar payment) |
| `pending_user_transfer_complete` | Stellar payment received; off-chain processing pending |
| `pending_external` | Waiting for off-chain confirmation (bank transfer, etc.) |
| `pending_anchor` | Anchor is processing the transaction |
| `pending_stellar` | Waiting for Stellar network confirmation |
| `pending_trust` | User must add a trustline for the asset before funds can be sent |
| `pending_user` | User must take an action; see `message` or `moreInfoUrl` |
| `completed` | Transaction finished successfully |
| `refunded` | Transaction was fully or partially refunded; see `refunds` |
| `expired` | Transaction expired before completion |
| `no_market` | No market available for the asset pair (SEP-38 exchange) |
| `too_small` | Amount is below the anchor's minimum threshold |
| `too_large` | Amount exceeds the anchor's maximum threshold |
| `error` | Transaction failed due to an error |

---

## 10. Refund Objects

When a transaction is refunded (`status == 'refunded'` or `refunds != null`), inspect the `refunds` field.

### Refund fields

| Dart field | JSON key | Type | Description |
|-----------|----------|------|-------------|
| `amountRefunded` | `amount_refunded` | `String` | Total refunded to user (in units of `amountInAsset`) |
| `amountFee` | `amount_fee` | `String` | Total fee charged for all refund payments |
| `payments` | `payments` | `List<RefundPayment>` | Individual refund payment records |

### RefundPayment fields

| Dart field | JSON key | Type | Description |
|-----------|----------|------|-------------|
| `id` | `id` | `String` | Stellar transaction hash or external reference |
| `idType` | `id_type` | `String` | `'stellar'` or `'external'` |
| `amount` | `amount` | `String` | Amount refunded by this payment |
| `fee` | `fee` | `String` | Fee charged for this refund payment |

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SEP24TransactionResponse response = await service.transaction(
  SEP24TransactionRequest()
    ..id = transactionId
    ..jwt = jwtToken,
);
SEP24Transaction tx = response.transaction;

if (tx.refunds != null) {
  Refund refund = tx.refunds!;

  print('Total refunded: ${refund.amountRefunded}');
  print('Refund fees: ${refund.amountFee}');

  for (RefundPayment payment in refund.payments) {
    print('Payment ID: ${payment.id}');
    print('  Type: ${payment.idType}');   // 'stellar' or 'external'
    print('  Amount: ${payment.amount}');
    print('  Fee: ${payment.fee}');
  }
}
```

---

## 11. Error Handling

Three exceptions can be thrown by SEP-24 service methods:

| Exception | HTTP status | Trigger | Action |
|-----------|-------------|---------|--------|
| `SEP24AuthenticationRequiredException` | 403 | JWT missing, expired, or invalid | Re-authenticate with SEP-10 and retry |
| `RequestErrorException` | 400/5xx | Invalid parameters, unsupported asset, server error | Check `exception.error` for anchor error details |
| `SEP24TransactionNotFoundException` | 404 | Transaction ID unknown or not owned by user | Only thrown by `transaction()`, not `transactions()` |

`RequestErrorException` has a field `error` (String) with the anchor's error message, and `toString()` returns that message.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerSEP24Service service =
    await TransferServerSEP24Service.fromDomain('testanchor.stellar.org');

// Deposit error handling
try {
  SEP24DepositRequest request = SEP24DepositRequest()
    ..assetCode = 'USD'
    ..jwt = jwtToken;

  SEP24InteractiveResponse response = await service.deposit(request);
  print('Open: ${response.url}');

} on SEP24AuthenticationRequiredException {
  // HTTP 403 — JWT is invalid, expired, or endpoint requires auth
  print('Need to re-authenticate with SEP-10');

} on RequestErrorException catch (e) {
  // HTTP 400/5xx — bad parameters, unsupported asset, etc.
  print('Request error: ${e.error}');
  // e.toString() also returns e.error

} catch (e) {
  print('Unexpected error: $e');
}

// Transaction lookup error handling
try {
  SEP24TransactionRequest request = SEP24TransactionRequest()
    ..id = transactionId
    ..jwt = jwtToken;

  SEP24TransactionResponse response = await service.transaction(request);
  print('Status: ${response.transaction.status}');

} on SEP24TransactionNotFoundException {
  // HTTP 404 — ID not found or not owned by authenticated user
  // Only thrown by transaction() (singular), NOT by transactions() (plural)
  print('Transaction not found');

} on SEP24AuthenticationRequiredException {
  print('Re-authenticate and retry');

} on RequestErrorException catch (e) {
  print('Error: ${e.error}');
}
```

---

## 12. Common Pitfalls

**Wrong: `amount` in deposit/withdraw requests is `String?`, not `double`**

```dart
// WRONG: amount field is String?, not double
SEP24DepositRequest request = SEP24DepositRequest()
  ..amount = 100.0;  // type error — amount is String?

// CORRECT: pass amount as a string
SEP24DepositRequest request = SEP24DepositRequest()
  ..amount = '100.0';
```

**Wrong: `claimableBalanceSupported` is `String?`, not `bool`**

```dart
// WRONG: field is String?, not bool
request.claimableBalanceSupported = true;  // type error

// CORRECT: pass the string 'true', not boolean true
request.claimableBalanceSupported = 'true';
```

**Wrong: using `transactions()` (plural) for ID-based lookup**

```dart
// WRONG: SEP24TransactionsRequest has no 'id' field
SEP24TransactionsRequest request = SEP24TransactionsRequest()
  ..jwt = jwtToken
  ..id = transactionId;  // field does not exist — compile error

// CORRECT: use transaction() (singular) for ID-based lookup
SEP24TransactionRequest request = SEP24TransactionRequest()
  ..jwt = jwtToken
  ..id = transactionId;
SEP24TransactionResponse response = await service.transaction(request);
```

**Wrong: setting `assetIssuer` for native XLM**

```dart
// WRONG: native assets have no issuer
SEP24DepositRequest request = SEP24DepositRequest()
  ..assetCode = 'native'
  ..assetIssuer = 'GABC...';  // anchor will reject this

// CORRECT: omit assetIssuer for native
SEP24DepositRequest request = SEP24DepositRequest()
  ..assetCode = 'native';
```

**Wrong: setting `refundMemo` without `refundMemoType` (or vice versa)**

```dart
// WRONG: both fields must be set together
SEP24WithdrawRequest request = SEP24WithdrawRequest()
  ..refundMemo = 'ref-123';
  // Missing: ..refundMemoType = 'text'

// CORRECT: always set both together
SEP24WithdrawRequest request = SEP24WithdrawRequest()
  ..refundMemo = 'ref-123'
  ..refundMemoType = 'text';
```

**Wrong: accessing `withdrawMemo` before KYC is complete**

The anchor sets `withdrawMemo` to null until KYC is verified, even when status is `pending_user_transfer_start`. Do not send the Stellar payment if the memo is null.

```dart
// WRONG: withdrawMemo may be null even in pending_user_transfer_start
String memo = tx.withdrawMemo!;  // throws if KYC not yet verified

// CORRECT: always check before sending
if (tx.status == 'pending_user_transfer_start') {
  if (tx.withdrawMemo == null) {
    // KYC not yet verified — open tx.moreInfoUrl or keep polling
    print('Waiting for KYC verification');
  } else {
    // Safe to send the payment
    print('Send to ${tx.withdrawAnchorAccount} with memo ${tx.withdrawMemo}');
  }
}
```

**Wrong: comparing `amountIn`, `amountOut`, `amountFee` as numbers**

These fields are `String?`, not `double`. Cast to double only for arithmetic.

```dart
// WRONG: these fields are strings
if (tx.amountIn! > 100.0) { ... }  // type error

// CORRECT: cast to double for comparison
if (tx.amountIn != null && double.parse(tx.amountIn!) > 100.0) { ... }
```

**Wrong: not awaiting `fromDomain()`**

```dart
// WRONG: returns Future<TransferServerSEP24Service>, not TransferServerSEP24Service
TransferServerSEP24Service service =
    TransferServerSEP24Service.fromDomain('testanchor.stellar.org');  // compile error

// CORRECT: must await
TransferServerSEP24Service service =
    await TransferServerSEP24Service.fromDomain('testanchor.stellar.org');
```

**Wrong: using `Util.readFile()` for KYC file uploads on web platforms**

```dart
// WRONG: Util.readFile() is not available on web platforms
personFields.photoIdFront = await Util.readFile('/path/to/id.jpg');

// CORRECT for native (iOS, Android, Desktop):
personFields.photoIdFront = await Util.readFile('/path/to/id.jpg');

// CORRECT for web: use a file picker and pass bytes via customFiles
Uint8List fileBytes = ...;  // obtained via file picker
SEP24DepositRequest request = SEP24DepositRequest()
  ..customFiles = {'photo_id_front': fileBytes};
```

---

## Related SEPs

- SEP-01 (`references/sep-01.md`) — stellar.toml (`TRANSFER_SERVER_SEP0024` is published here)
- SEP-10 (`references/sep-10.md`) — Web Authentication for traditional G... accounts (provides the JWT)
- SEP-12 (`references/sep-12.md`) — KYC API (often used alongside SEP-24)
- SEP-38 — Anchor RFQ API (quotes for exchange rates; use `quoteId` and `sourceAsset`/`destinationAsset`)

