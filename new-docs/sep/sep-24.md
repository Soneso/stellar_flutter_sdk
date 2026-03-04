# SEP-24: Interactive Deposit and Withdrawal

SEP-24 defines how to move money between traditional financial systems and the Stellar network. The anchor hosts a web interface where users complete the deposit or withdrawal process—the web UI handles KYC and payment method selection.

Use SEP-24 when:
- You want to deposit fiat currency (USD, EUR, etc.) to receive Stellar tokens
- You want to withdraw Stellar tokens back to a bank account or other payment method
- The anchor needs to collect information interactively from the user
- You're building a wallet that integrates with regulated on/off ramps

See the [SEP-24 specification](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0024.md) for protocol details.

## Quick example

This example shows how to start a deposit flow. The anchor returns a URL where users complete the deposit process interactively:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Create service from anchor's domain
TransferServerSEP24Service service =
    await TransferServerSEP24Service.fromDomain('testanchor.stellar.org');

// Start a deposit flow (requires JWT token from SEP-10 or SEP-45)
SEP24DepositRequest request = SEP24DepositRequest()
  ..jwt = jwtToken
  ..assetCode = 'USD';

SEP24InteractiveResponse response = await service.deposit(request);

// Open this URL in a browser or webview for the user
String interactiveUrl = response.url;
String transactionId = response.id;

print('Open: $interactiveUrl');
print('Transaction ID: $transactionId');
```

## Creating the interactive service

The `TransferServerSEP24Service` class provides all SEP-24 operations. Create it from an anchor's domain (which discovers the transfer server URL from stellar.toml) or provide a direct URL.

**From an anchor's domain** (recommended):

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Loads the TRANSFER_SERVER_SEP0024 URL from stellar.toml
TransferServerSEP24Service service =
    await TransferServerSEP24Service.fromDomain('testanchor.stellar.org');
```

**From a direct URL**:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerSEP24Service service =
    TransferServerSEP24Service('https://api.anchor.com/sep24');
```

**With a custom HTTP client** (useful for testing or custom configurations):

```dart
import 'package:http/http.dart' as http;
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final httpClient = http.Client();

TransferServerSEP24Service service =
    await TransferServerSEP24Service.fromDomain(
  'testanchor.stellar.org',
  httpClient: httpClient,
  httpRequestHeaders: {'User-Agent': 'MyWallet/1.0'},
);
```

## Getting anchor information

Before starting a deposit or withdrawal, query the `/info` endpoint to see what assets the anchor supports and their fee structures:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerSEP24Service service =
    await TransferServerSEP24Service.fromDomain('testanchor.stellar.org');

// Get anchor info (optionally specify language code like 'de' for German)
SEP24InfoResponse info = await service.info();

// Check supported deposit assets
if (info.depositAssets != null) {
  info.depositAssets!.forEach((code, asset) {
    print('Deposit: $code');
    print('  Enabled: ${asset.enabled ? "Yes" : "No"}');
    if (asset.minAmount != null) {
      print('  Min: ${asset.minAmount}');
    }
    if (asset.maxAmount != null) {
      print('  Max: ${asset.maxAmount}');
    }
    if (asset.feeFixed != null) {
      print('  Fixed fee: ${asset.feeFixed}');
    }
    if (asset.feePercent != null) {
      print('  Percent fee: ${asset.feePercent}%');
    }
    if (asset.feeMinimum != null) {
      print('  Minimum fee: ${asset.feeMinimum}');
    }
  });
}

// Check supported withdrawal assets
Map<String, SEP24WithdrawAsset>? withdrawAssets = info.withdrawAssets;

// Check feature support (claimable balances, account creation)
if (info.featureFlags != null) {
  print('Account creation supported: ${info.featureFlags!.accountCreation ? "Yes" : "No"}');
  print('Claimable balances supported: ${info.featureFlags!.claimableBalances ? "Yes" : "No"}');
}

// Check if the deprecated fee endpoint is available
if (info.feeEndpointInfo != null && info.feeEndpointInfo!.enabled) {
  print('Fee endpoint is available');
  print('Requires authentication: ${info.feeEndpointInfo!.authenticationRequired ? "Yes" : "No"}');
}
```

## Deposit flow

A deposit converts external funds (bank transfer, card, crypto from another chain) into Stellar tokens sent to your account. The user provides payment details through the anchor's web interface and completes KYC if required.

### Basic deposit

Start a deposit by specifying the asset you want to receive. The anchor returns a URL to open in a browser or webview:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerSEP24Service service =
    await TransferServerSEP24Service.fromDomain('testanchor.stellar.org');

SEP24DepositRequest request = SEP24DepositRequest()
  ..jwt = jwtToken // From SEP-10 or SEP-45 authentication
  ..assetCode = 'USD';

SEP24InteractiveResponse response = await service.deposit(request);

// Show the interactive URL to your user
String url = response.url;
String transactionId = response.id;

// The user completes the deposit in their browser
// Then poll for status updates (see "Tracking Transactions" below)
```

### Deposit with amount and account options

You can specify an amount, destination account (if different from the authenticated account), and memo for the deposit:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerSEP24Service service =
    await TransferServerSEP24Service.fromDomain('testanchor.stellar.org');

SEP24DepositRequest request = SEP24DepositRequest()
  ..jwt = jwtToken
  ..assetCode = 'USD'
  ..amount = '100.0'
  // Receive tokens on a different account than the one used for authentication
  ..account = 'GXXXXXXX...'
  ..memo = '12345'
  ..memoType = 'id' // 'text', 'id', or 'hash'
  // Language for the interactive UI (RFC 4646 format)
  ..lang = 'en-US';

SEP24InteractiveResponse response = await service.deposit(request);
```

### Deposit with asset issuer

When the anchor supports multiple issuers for the same asset code, specify which issuer you want:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerSEP24Service service =
    await TransferServerSEP24Service.fromDomain('testanchor.stellar.org');

SEP24DepositRequest request = SEP24DepositRequest()
  ..jwt = jwtToken
  ..assetCode = 'USD'
  ..assetIssuer = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';

SEP24InteractiveResponse response = await service.deposit(request);
```

### Deposit with SEP-38 quote

For cross-asset deposits (deposit EUR to receive USDC), use a SEP-38 quote to lock in an exchange rate:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerSEP24Service service =
    await TransferServerSEP24Service.fromDomain('testanchor.stellar.org');

// First, get a quote from SEP-38 (see SEP-38 documentation)
String quoteId = 'quote-abc-123';

SEP24DepositRequest request = SEP24DepositRequest()
  ..jwt = jwtToken
  ..assetCode = 'USDC'
  ..quoteId = quoteId
  ..sourceAsset = 'iso4217:EUR' // Depositing EUR, receiving USDC tokens
  ..amount = '100.0'; // Must match the quote's sell_amount

SEP24InteractiveResponse response = await service.deposit(request);
```

### Pre-filling KYC data

Provide KYC data upfront to pre-fill the anchor's form:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerSEP24Service service =
    await TransferServerSEP24Service.fromDomain('testanchor.stellar.org');

// Provide personal KYC information
NaturalPersonKYCFields personFields = NaturalPersonKYCFields()
  ..firstName = 'Jane'
  ..lastName = 'Doe'
  ..emailAddress = 'jane@example.com'
  ..mobileNumber = '+1234567890';

StandardKYCFields kycFields = StandardKYCFields()
  ..naturalPersonKYCFields = personFields;

SEP24DepositRequest request = SEP24DepositRequest()
  ..jwt = jwtToken
  ..assetCode = 'USD'
  ..kycFields = kycFields;

SEP24InteractiveResponse response = await service.deposit(request);
// The anchor will pre-fill these fields in the interactive form
```

### Pre-filling organization KYC data

For business accounts, provide organization KYC fields:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerSEP24Service service =
    await TransferServerSEP24Service.fromDomain('testanchor.stellar.org');

OrganizationKYCFields orgFields = OrganizationKYCFields()
  ..name = 'Acme Corporation'
  ..registeredAddress = '123 Business St, Suite 100'
  ..email = 'contact@acme.com';

StandardKYCFields kycFields = StandardKYCFields()
  ..organizationKYCFields = orgFields;

SEP24DepositRequest request = SEP24DepositRequest()
  ..jwt = jwtToken
  ..assetCode = 'USD'
  ..kycFields = kycFields;

SEP24InteractiveResponse response = await service.deposit(request);
```

### Custom fields and files

For anchor-specific KYC requirements not covered by standard SEP-9 fields, use custom fields and files:

```dart
import 'dart:typed_data';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerSEP24Service service =
    await TransferServerSEP24Service.fromDomain('testanchor.stellar.org');

SEP24DepositRequest request = SEP24DepositRequest()
  ..jwt = jwtToken
  ..assetCode = 'USD'
  // Custom text fields
  ..customFields = {
    'employer_name': 'Tech Corp',
    'occupation': 'Software Engineer',
  }
  // Custom file uploads (binary content)
  ..customFiles = {
    'proof_of_income': Uint8List.fromList([/* file bytes */]),
  };

SEP24InteractiveResponse response = await service.deposit(request);
```

### Deposit with claimable balance support

If your account doesn't have a trustline for the asset, request that the anchor use claimable balances:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerSEP24Service service =
    await TransferServerSEP24Service.fromDomain('testanchor.stellar.org');

SEP24DepositRequest request = SEP24DepositRequest()
  ..jwt = jwtToken
  ..assetCode = 'USD'
  ..claimableBalanceSupported = 'true';

SEP24InteractiveResponse response = await service.deposit(request);
// The anchor may create a claimable balance instead of a direct payment
// Check the transaction's claimableBalanceId field after completion
```

### Deposit native XLM

To deposit and receive native XLM (lumens), use the special `native` asset code:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerSEP24Service service =
    await TransferServerSEP24Service.fromDomain('testanchor.stellar.org');

SEP24DepositRequest request = SEP24DepositRequest()
  ..jwt = jwtToken
  // Do not set assetIssuer for native assets
  ..assetCode = 'native';

SEP24InteractiveResponse response = await service.deposit(request);
```

## Withdrawal flow

A withdrawal converts Stellar tokens into external funds sent to a bank account, card, or other destination. The user completes the anchor's interactive flow, then sends tokens to the anchor's Stellar account.

### Basic withdrawal

Start a withdrawal by specifying the asset you want to withdraw:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerSEP24Service service =
    await TransferServerSEP24Service.fromDomain('testanchor.stellar.org');

SEP24WithdrawRequest request = SEP24WithdrawRequest()
  ..jwt = jwtToken
  ..assetCode = 'USD';

SEP24InteractiveResponse response = await service.withdraw(request);

// Show the interactive URL to your user
String url = response.url;
String transactionId = response.id;

// After completing the form, poll for status to get withdrawal instructions
// When status is "pending_user_transfer_start", send the Stellar payment
```

### Withdrawal with options

Specify additional options like amount, source account, and language:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerSEP24Service service =
    await TransferServerSEP24Service.fromDomain('testanchor.stellar.org');

SEP24WithdrawRequest request = SEP24WithdrawRequest()
  ..jwt = jwtToken
  ..assetCode = 'USD'
  ..amount = '500.0'
  // Specify which Stellar account will send the withdrawal payment
  ..account = 'GXXXXXXX...'
  // Language for the interactive UI
  ..lang = 'de'; // German

SEP24InteractiveResponse response = await service.withdraw(request);
```

### Withdrawal with refund memo

Specify a memo for refunds if the withdrawal fails or is cancelled:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerSEP24Service service =
    await TransferServerSEP24Service.fromDomain('testanchor.stellar.org');

SEP24WithdrawRequest request = SEP24WithdrawRequest()
  ..jwt = jwtToken
  ..assetCode = 'USD'
  ..amount = '500.0'
  // Memo for refund payments
  ..refundMemo = 'refund-123'
  ..refundMemoType = 'text'; // 'text', 'id', or 'hash'

SEP24InteractiveResponse response = await service.withdraw(request);
```

### Withdrawal with SEP-38 quote (asset exchange)

For cross-asset withdrawals (send USDC, receive EUR in bank), use a SEP-38 quote:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerSEP24Service service =
    await TransferServerSEP24Service.fromDomain('testanchor.stellar.org');

// First, get a quote from SEP-38 (see SEP-38 documentation)
String quoteId = 'quote-xyz-789';

SEP24WithdrawRequest request = SEP24WithdrawRequest()
  ..jwt = jwtToken
  ..assetCode = 'USDC'
  ..quoteId = quoteId
  ..destinationAsset = 'iso4217:EUR' // Sending USDC, receiving EUR
  ..amount = '500.0'; // Must match the quote's sell_amount

SEP24InteractiveResponse response = await service.withdraw(request);
```

### Withdrawal with KYC data

Pre-fill KYC data for the withdrawal form:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerSEP24Service service =
    await TransferServerSEP24Service.fromDomain('testanchor.stellar.org');

NaturalPersonKYCFields personFields = NaturalPersonKYCFields()
  ..firstName = 'John'
  ..lastName = 'Smith'
  ..emailAddress = 'john@example.com';

// Bank details go in FinancialAccountKYCFields
FinancialAccountKYCFields bankFields = FinancialAccountKYCFields()
  ..bankAccountNumber = '123456789'
  ..bankNumber = '987654321';
personFields.financialAccountKYCFields = bankFields;

StandardKYCFields kycFields = StandardKYCFields()
  ..naturalPersonKYCFields = personFields;

SEP24WithdrawRequest request = SEP24WithdrawRequest()
  ..jwt = jwtToken
  ..assetCode = 'USD'
  ..kycFields = kycFields;

SEP24InteractiveResponse response = await service.withdraw(request);
```

### Completing a withdrawal payment

After the user completes the interactive flow, poll the transaction endpoint to get payment instructions. When the status is `pending_user_transfer_start`, send the Stellar payment:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerSEP24Service service =
    await TransferServerSEP24Service.fromDomain('testanchor.stellar.org');

// Poll for transaction status
SEP24TransactionRequest txRequest = SEP24TransactionRequest()
  ..jwt = jwtToken
  ..id = transactionId;

SEP24TransactionResponse txResponse = await service.transaction(txRequest);
SEP24Transaction tx = txResponse.transaction;

if (tx.status == 'pending_user_transfer_start') {
  // User needs to send the Stellar payment
  String withdrawAccount = tx.withdrawAnchorAccount!;
  String withdrawMemo = tx.withdrawMemo!;
  String withdrawMemoType = tx.withdrawMemoType!;
  String amount = tx.amountIn!;

  // Build and submit the payment transaction
  StellarSDK sdk = StellarSDK.TESTNET;
  KeyPair sourceKeyPair = KeyPair.fromSecretSeed('SXXXXX...');
  AccountResponse sourceAccount =
      await sdk.accounts.account(sourceKeyPair.accountId);

  Asset asset = Asset.createNonNativeAsset('USD', 'ISSUER_ACCOUNT_ID');

  Transaction transaction = TransactionBuilder(sourceAccount)
      .addOperation(
          PaymentOperationBuilder(withdrawAccount, asset, amount).build())
      .addMemo(Memo.text(withdrawMemo)) // Adjust based on withdrawMemoType
      .build();

  transaction.sign(sourceKeyPair, Network.TESTNET);
  await sdk.submitTransaction(transaction);
}
```

## Tracking transactions

After starting a deposit or withdrawal, poll the anchor for status updates. The SDK provides methods to query single transactions or list multiple transactions.

### Get a single transaction by ID

Query a specific transaction using its anchor-generated ID:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerSEP24Service service =
    await TransferServerSEP24Service.fromDomain('testanchor.stellar.org');

SEP24TransactionRequest request = SEP24TransactionRequest()
  ..jwt = jwtToken
  ..id = transactionId; // From deposit/withdraw response

SEP24TransactionResponse response = await service.transaction(request);
SEP24Transaction tx = response.transaction;

print('ID: ${tx.id}');
print('Kind: ${tx.kind}');
print('Status: ${tx.status}');
print('Started: ${tx.startedAt}');

if (tx.amountIn != null) {
  print('Amount in: ${tx.amountIn}');
}
if (tx.amountOut != null) {
  print('Amount out: ${tx.amountOut}');
}
if (tx.amountFee != null) {
  print('Fee: ${tx.amountFee}');
}
if (tx.message != null) {
  print('Message: ${tx.message}');
}
if (tx.moreInfoUrl != null) {
  print('More info: ${tx.moreInfoUrl}');
}
```

### Get transaction by Stellar transaction ID

Look up a transaction using its Stellar network transaction hash:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerSEP24Service service =
    await TransferServerSEP24Service.fromDomain('testanchor.stellar.org');

SEP24TransactionRequest request = SEP24TransactionRequest()
  ..jwt = jwtToken
  ..stellarTransactionId = 'abc123def456...'; // Stellar transaction hash

SEP24TransactionResponse response = await service.transaction(request);
```

### Get transaction by external transaction ID

Look up a transaction using an external reference (e.g., bank transfer reference):

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerSEP24Service service =
    await TransferServerSEP24Service.fromDomain('testanchor.stellar.org');

SEP24TransactionRequest request = SEP24TransactionRequest()
  ..jwt = jwtToken
  ..externalTransactionId = 'BANK-REF-123456';

SEP24TransactionResponse response = await service.transaction(request);
```

### Get transaction history

Query multiple transactions with filtering and pagination:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerSEP24Service service =
    await TransferServerSEP24Service.fromDomain('testanchor.stellar.org');

SEP24TransactionsRequest request = SEP24TransactionsRequest()
  ..jwt = jwtToken
  ..assetCode = 'USD'
  ..limit = 10
  ..kind = 'deposit' // or 'withdrawal', or omit for both
  // Only transactions after this date
  ..noOlderThan = DateTime.utc(2024, 1, 1)
  // Language for localized responses
  ..lang = 'en';

SEP24TransactionsResponse response = await service.transactions(request);

for (SEP24Transaction tx in response.transactions) {
  String line = '${tx.id}: ${tx.kind} - ${tx.status}';
  if (tx.amountIn != null) {
    line += ' - ${tx.amountIn}';
  }
  print(line);
}
```

### Pagination with paging ID

For paginating through large transaction lists:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerSEP24Service service =
    await TransferServerSEP24Service.fromDomain('testanchor.stellar.org');

// First page
SEP24TransactionsRequest request = SEP24TransactionsRequest()
  ..jwt = jwtToken
  ..assetCode = 'USD'
  ..limit = 10;

SEP24TransactionsResponse response = await service.transactions(request);
List<SEP24Transaction> transactions = response.transactions;

// Get next page using the last transaction's ID
if (transactions.isNotEmpty) {
  String lastId = transactions.last.id;

  request.pagingId = lastId;
  SEP24TransactionsResponse nextPage = await service.transactions(request);
}
```

## Transaction object details

The `SEP24Transaction` object contains detailed information about a transaction. Here are the key fields:

### Common fields (all transactions)

| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` | Unique anchor-generated transaction ID |
| `kind` | `String` | `deposit` or `withdrawal` |
| `status` | `String` | Current status (see status table below) |
| `statusEta` | `int?` | Estimated seconds until next status change |
| `kycVerified` | `bool?` | Whether anchor verified user's KYC for this transaction |
| `moreInfoUrl` | `String?` | URL with additional transaction details |
| `amountIn` | `String?` | Amount received by anchor |
| `amountInAsset` | `String?` | Asset received (SEP-38 format) |
| `amountOut` | `String?` | Amount sent to user |
| `amountOutAsset` | `String?` | Asset sent (SEP-38 format) |
| `amountFee` | `String?` | Fee charged by anchor |
| `amountFeeAsset` | `String?` | Asset for fee calculation |
| `quoteId` | `String?` | SEP-38 quote ID if used |
| `startedAt` | `String` | Transaction start time (ISO 8601) |
| `completedAt` | `String?` | Completion time (ISO 8601) |
| `updatedAt` | `String?` | Last update time (ISO 8601) |
| `userActionRequiredBy` | `String?` | Deadline for user action (ISO 8601) |
| `stellarTransactionId` | `String?` | Stellar transaction hash |
| `externalTransactionId` | `String?` | External system transaction ID |
| `message` | `String?` | Human-readable status explanation |
| `from` | `String?` | Source address/account |
| `to` | `String?` | Destination address/account |

### Deposit-specific fields

| Field | Type | Description |
|-------|------|-------------|
| `depositMemo` | `String?` | Memo used in the deposit payment |
| `depositMemoType` | `String?` | Memo type (`text`, `id`, `hash`) |
| `claimableBalanceId` | `String?` | Claimable balance ID if used |

### Withdrawal-specific fields

| Field | Type | Description |
|-------|------|-------------|
| `withdrawAnchorAccount` | `String?` | Anchor's Stellar account to send payment to |
| `withdrawMemo` | `String?` | Memo to include in the payment |
| `withdrawMemoType` | `String?` | Memo type (`text`, `id`, `hash`) |

### Reading transaction fields

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerSEP24Service service =
    await TransferServerSEP24Service.fromDomain('testanchor.stellar.org');

SEP24TransactionRequest request = SEP24TransactionRequest()
  ..jwt = jwtToken
  ..id = transactionId;

SEP24TransactionResponse response = await service.transaction(request);
SEP24Transaction tx = response.transaction;

// Check if KYC is verified
if (tx.kycVerified == true) {
  print('KYC verified for this transaction');
}

// Check for user action deadline
if (tx.userActionRequiredBy != null) {
  print('Action required by: ${tx.userActionRequiredBy}');
}

// For deposits, check for claimable balance
if (tx.kind == 'deposit' && tx.claimableBalanceId != null) {
  print('Claim balance: ${tx.claimableBalanceId}');
}

// For withdrawals in pending_user_transfer_start status
if (tx.kind == 'withdrawal' && tx.status == 'pending_user_transfer_start') {
  print('Send ${tx.amountIn} to ${tx.withdrawAnchorAccount}');
  print('With memo: ${tx.withdrawMemo} (${tx.withdrawMemoType})');
}
```

## Transaction statuses

The `status` field indicates the current state of the transaction:

| Status | Description |
|--------|-------------|
| `incomplete` | User hasn't completed the interactive flow yet |
| `pending_user_transfer_start` | Waiting for user to send funds to anchor |
| `pending_user_transfer_complete` | Stellar payment received, off-chain funds ready for pickup |
| `pending_external` | Waiting for external network confirmation (bank, crypto) |
| `pending_anchor` | Anchor is processing the transaction |
| `on_hold` | Transaction on hold pending compliance review |
| `pending_stellar` | Waiting for Stellar network transaction confirmation |
| `pending_trust` | User needs to add a trustline for the asset |
| `pending_user` | User action required (see message or more_info_url) |
| `completed` | Transaction finished successfully |
| `refunded` | Transaction was refunded (see refunds object) |
| `expired` | Transaction expired before completion |
| `no_market` | No market available for the asset exchange |
| `too_small` | Amount below minimum threshold |
| `too_large` | Amount above maximum threshold |
| `error` | Transaction failed due to an error |

## Handling refunds

When a transaction is refunded, check the `refunds` object for details:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerSEP24Service service =
    await TransferServerSEP24Service.fromDomain('testanchor.stellar.org');

SEP24TransactionRequest request = SEP24TransactionRequest()
  ..jwt = jwtToken
  ..id = transactionId;

SEP24TransactionResponse response = await service.transaction(request);
SEP24Transaction tx = response.transaction;

if (tx.status == 'refunded' && tx.refunds != null) {
  Refund refund = tx.refunds!;

  print('Total refunded: ${refund.amountRefunded}');
  print('Refund fees: ${refund.amountFee}');

  // Individual refund payments
  for (RefundPayment payment in refund.payments) {
    print('Payment ID: ${payment.id}');
    print('Type: ${payment.idType}'); // 'stellar' or 'external'
    print('Amount: ${payment.amount}');
    print('Fee: ${payment.fee}');
  }
}
```

## Error handling

The SDK throws specific exceptions for different error scenarios:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerSEP24Service service =
    await TransferServerSEP24Service.fromDomain('testanchor.stellar.org');

try {
  SEP24DepositRequest request = SEP24DepositRequest()
    ..jwt = jwtToken
    ..assetCode = 'USD';

  SEP24InteractiveResponse response = await service.deposit(request);
  print('Interactive URL: ${response.url}');

} on SEP24AuthenticationRequiredException {
  // HTTP 403: JWT token is invalid, expired, or missing
  // Re-authenticate with SEP-10 or SEP-45 and retry
  print('Authentication required');

} on RequestErrorException catch (e) {
  // HTTP 400 or other error: Invalid parameters, unsupported asset, etc.
  // Check the error message for details from the anchor
  print('Request error: ${e.error}');

} catch (e) {
  // Other unexpected errors
  print('Unexpected error: $e');
}

// For transaction queries, handle the not-found case
try {
  SEP24TransactionRequest txRequest = SEP24TransactionRequest()
    ..jwt = jwtToken
    ..id = 'invalid-or-unknown-id';

  SEP24TransactionResponse response = await service.transaction(txRequest);

} on SEP24TransactionNotFoundException {
  // HTTP 404: Transaction doesn't exist or doesn't belong to this user
  print('Transaction not found');

} on SEP24AuthenticationRequiredException {
  print('Need to re-authenticate');

} on RequestErrorException catch (e) {
  print('Error: ${e.error}');
}
```

## Fee information (deprecated)

The `/fee` endpoint is deprecated in favor of SEP-38. For anchors that still support it:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerSEP24Service service =
    await TransferServerSEP24Service.fromDomain('testanchor.stellar.org');

// Check if fee endpoint is available
SEP24InfoResponse info = await service.info();

if (info.feeEndpointInfo != null && info.feeEndpointInfo!.enabled) {
  SEP24FeeRequest feeRequest = SEP24FeeRequest()
    ..operation = 'deposit'
    ..assetCode = 'USD'
    ..amount = 1000.0
    ..jwt = jwtToken
    // Optional: specify type (e.g., 'SEPA', 'bank_account')
    ..type = 'bank_account';

  SEP24FeeResponse feeResponse = await service.fee(feeRequest);
  print('Fee for \$1000 deposit: \$${feeResponse.fee}');
}
```

> **Note:** New integrations should use [SEP-38](sep-38.md) `/price` endpoint for fee and exchange rate information.

## Polling strategy

When monitoring transactions, use exponential backoff to avoid hammering the server:

```dart
import 'dart:math';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

Future<SEP24Transaction?> pollTransaction(
  TransferServerSEP24Service service,
  String jwt,
  String transactionId, {
  Set<String> terminalStatuses = const {
    'completed', 'refunded', 'expired', 'error',
  },
}) async {
  SEP24TransactionRequest request = SEP24TransactionRequest()
    ..jwt = jwt
    ..id = transactionId;

  int attempts = 0;
  int maxAttempts = 60;
  int baseDelay = 2; // seconds

  while (attempts < maxAttempts) {
    SEP24TransactionResponse response = await service.transaction(request);
    SEP24Transaction tx = response.transaction;

    print('Status: ${tx.status}');

    if (terminalStatuses.contains(tx.status)) {
      return tx;
    }

    // Use status_eta if provided, otherwise exponential backoff
    int delay;
    if (tx.statusEta != null && tx.statusEta! > 0) {
      delay = min(tx.statusEta!, 60); // Cap at 60 seconds
    } else {
      delay = min(baseDelay * pow(2, attempts).toInt(), 60);
    }

    await Future.delayed(Duration(seconds: delay));
    attempts++;
  }

  return null; // Timeout
}

// Usage:
// SEP24Transaction? completedTx =
//     await pollTransaction(service, jwtToken, transactionId);
// if (completedTx != null) {
//   print('Transaction completed with status: ${completedTx.status}');
// }
```

## Related specifications

- [SEP-1](sep-01.md) - stellar.toml (where `TRANSFER_SERVER_SEP0024` is published)
- [SEP-10](sep-10.md) - Web Authentication for traditional accounts (G... addresses)
- [SEP-45](sep-45.md) - Web Authentication for Contract Accounts (C... addresses)
- [SEP-12](sep-12.md) - KYC API (often used alongside SEP-24)
- [SEP-38](sep-38.md) - Anchor RFQ API (quotes for exchange rates)
- [SEP-6](sep-06.md) - Programmatic Deposit/Withdrawal (non-interactive alternative)

## Further reading

- [SDK test cases](https://github.com/niclas9/stellar_flutter_sdk/tree/master/test/integration) - examples covering deposits, withdrawals, transaction queries, and error handling

---

[Back to SEP Overview](README.md)
