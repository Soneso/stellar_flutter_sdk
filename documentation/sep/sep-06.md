# SEP-06: Deposit and Withdrawal API

SEP-06 defines a standard protocol for programmatic deposits and withdrawals through anchors. Users send off-chain assets (USD via bank, BTC, etc.) to receive Stellar tokens, or redeem Stellar tokens for off-chain assets.

**Use SEP-06 when:**
- Building automated deposit/withdrawal flows
- Integrating anchor services programmatically without user-facing web flows
- You need direct API access (vs. SEP-24's interactive popup approach)

**Spec:** [SEP-0006](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md)

## Quick example

This example shows how to authenticate with an anchor via SEP-10 and initiate a deposit request.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// 1. Authenticate with the anchor via SEP-10
WebAuth webAuth = await WebAuth.fromDomain("testanchor.stellar.org", Network.TESTNET);
KeyPair userKeyPair = KeyPair.fromSecretSeed("SCZANGBA5YHTNYVVV3C7CAZMTQDBJHJG6C34CJDQ66EQ7DZTPBRJFN4A");
String jwtToken = await webAuth.jwtToken(userKeyPair.accountId, [userKeyPair]);

// 2. Create transfer service and request deposit
TransferServerService transferService =
    await TransferServerService.fromDomain("testanchor.stellar.org");

DepositRequest request = DepositRequest(
  assetCode: "USD",
  account: userKeyPair.accountId,
  jwt: jwtToken,
);

DepositResponse response = await transferService.deposit(request);

print("Deposit instructions: ${response.how}");
print("Fee: ${response.feeFixed}");
```

## Creating the service

### From domain (recommended)

The SDK discovers the `TRANSFER_SERVER` URL automatically from the anchor's `stellar.toml` file.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Discovers TRANSFER_SERVER from stellar.toml via SEP-01
TransferServerService transferService =
    await TransferServerService.fromDomain("testanchor.stellar.org");
```

### Direct URL

If you already know the transfer server URL, construct the service directly.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerService transferService =
    TransferServerService("https://testanchor.stellar.org/sep6");
```

## Querying anchor info

Before initiating deposits or withdrawals, query the info endpoint to discover supported assets, methods, and requirements.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerService transferService =
    await TransferServerService.fromDomain("testanchor.stellar.org");
InfoResponse info = await transferService.info();

// Check deposit assets and their limits
if (info.depositAssets != null) {
  info.depositAssets!.forEach((code, asset) {
    print('Deposit $code: ${asset.enabled ? "enabled" : "disabled"}');
    if (asset.authenticationRequired == true) {
      print('  Authentication required');
    }
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
  });
}

// Check withdrawal assets
if (info.withdrawAssets != null) {
  info.withdrawAssets!.forEach((code, asset) {
    print('Withdraw $code: ${asset.enabled ? "enabled" : "disabled"}');
  });
}

// Check deposit-exchange assets (for cross-asset deposits with SEP-38 quotes)
if (info.depositExchangeAssets != null) {
  info.depositExchangeAssets!.forEach((code, asset) {
    print('Deposit-Exchange $code: ${asset.enabled ? "enabled" : "disabled"}');
  });
}

// Check withdraw-exchange assets (for cross-asset withdrawals with SEP-38 quotes)
if (info.withdrawExchangeAssets != null) {
  info.withdrawExchangeAssets!.forEach((code, asset) {
    print('Withdraw-Exchange $code: ${asset.enabled ? "enabled" : "disabled"}');
  });
}

// Feature flags
if (info.featureFlags != null) {
  print('Account creation supported: ${info.featureFlags!.accountCreation ? "yes" : "no"}');
  print('Claimable balances supported: ${info.featureFlags!.claimableBalances ? "yes" : "no"}');
}

// Check endpoint availability
print('Fee endpoint enabled: ${info.feeInfo?.enabled == true ? "yes" : "no"}');
print('Transactions endpoint enabled: ${info.transactionsInfo?.enabled == true ? "yes" : "no"}');
print('Transaction endpoint enabled: ${info.transactionInfo?.enabled == true ? "yes" : "no"}');
```

## Deposits

A deposit is when a user sends an external asset (BTC, USD via bank, etc.) to an anchor and receives equivalent Stellar tokens in their account.

### Basic deposit request

Request deposit instructions from the anchor by specifying the asset code and destination Stellar account.

> **Note:** The `account` parameter accepts both regular Stellar accounts (`G...`) and muxed accounts (`M...`).

> **Note:** The `type` parameter corresponds to the SEP-06 `funding_method` concept introduced in v4.3.0. The SDK currently supports `type`; `funding_method` may be added in a future release.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerService transferService =
    await TransferServerService.fromDomain("testanchor.stellar.org");

DepositRequest request = DepositRequest(
  assetCode: "USD",
  account: "GCQTGZQTVZ...",  // Stellar account to receive tokens (G... or M... for muxed)
  jwt: jwtToken,
  type: "bank_account",      // Optional: deposit method (SEPA, SWIFT, etc.)
  amount: "100.00",          // Optional: helps anchor determine KYC needs
);

try {
  DepositResponse response = await transferService.deposit(request);

  // Display deposit instructions to user
  if (response.how != null) {
    print('How to deposit: ${response.how}');
  }

  // Structured deposit instructions (preferred over 'how')
  if (response.instructions != null) {
    response.instructions!.forEach((key, instruction) {
      print('$key: ${instruction.value}');
      if (instruction.description != null) {
        print('  (${instruction.description})');
      }
    });
  }

  // Save transaction ID for status tracking
  if (response.id != null) {
    print('Transaction ID: ${response.id}');
  }

  // Fee info
  if (response.feeFixed != null) {
    print('Fixed fee: ${response.feeFixed}');
  }
  if (response.feePercent != null) {
    print('Percent fee: ${response.feePercent}%');
  }

  // Amount limits
  if (response.minAmount != null) {
    print('Minimum deposit: ${response.minAmount}');
  }
  if (response.maxAmount != null) {
    print('Maximum deposit: ${response.maxAmount}');
  }

  // Estimated time
  if (response.eta != null) {
    print('Estimated time: ${response.eta} seconds');
  }

  // Extra info
  if (response.extraInfo?.message != null) {
    print('Note: ${response.extraInfo!.message}');
  }

} on CustomerInformationNeededException catch (e) {
  // Anchor needs KYC info via SEP-12
  print('Required fields:');
  if (e.response.fields != null) {
    for (var field in e.response.fields!) {
      print('  - $field');
    }
  }

} on CustomerInformationStatusException catch (e) {
  // KYC submitted but pending/denied
  print('KYC status: ${e.response.status}');
  if (e.response.moreInfoUrl != null) {
    print('More info: ${e.response.moreInfoUrl}');
  }
}
```

### Deposit with all options

The `DepositRequest` class supports optional parameters for different use cases.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerService transferService =
    await TransferServerService.fromDomain("testanchor.stellar.org");

DepositRequest request = DepositRequest(
  assetCode: "USD",
  account: "GCQTGZQTVZ...",
  memoType: "id",                           // Memo type for Stellar payment (text, id, hash)
  memo: "12345",                            // Memo value
  emailAddress: "user@example.com",         // For anchor to send updates
  type: "SEPA",                             // Deposit method
  lang: "en",                               // Response language (RFC 4646)
  onChangeCallback: "https://wallet.example.com/callback",  // Status update webhook
  amount: "500.00",                         // Deposit amount
  countryCode: "USA",                       // ISO 3166-1 alpha-3
  claimableBalanceSupported: "true",        // Enable claimable balance (pass as string, NOT bool)
  customerId: "cust-123",                   // SEP-12 customer ID if known
  locationId: "loc-456",                    // For cash deposits: pickup location
  extraFields: {"custom_field": "value"},   // Anchor-specific extra fields
  jwt: jwtToken,
);

DepositResponse response = await transferService.deposit(request);
```

## Withdrawals

A withdrawal is when a user redeems Stellar tokens for their off-chain equivalent, such as sending USDC to receive USD in a bank account.

### Basic withdrawal request

Request withdrawal instructions by specifying the asset and withdrawal method.

> **Note:** The `account` parameter accepts both regular Stellar accounts (`G...`) and muxed accounts (`M...`).

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerService transferService =
    await TransferServerService.fromDomain("testanchor.stellar.org");

WithdrawRequest request = WithdrawRequest(
  assetCode: "USDC",
  type: "bank_account",      // Withdrawal method: bank_account, cash, crypto, mobile, etc.
  jwt: jwtToken,
  account: "GCQTGZQTVZ...",  // Optional: source Stellar account
  amount: "500.00",          // Optional: withdrawal amount
);

try {
  WithdrawResponse response = await transferService.withdraw(request);

  // Where to send the Stellar payment
  if (response.accountId != null) {
    print('Send payment to: ${response.accountId}');
  }

  // Include memo in the payment
  if (response.memoType != null && response.memo != null) {
    print('Memo (${response.memoType}): ${response.memo}');
  }

  // Save transaction ID for status tracking
  if (response.id != null) {
    print('Transaction ID: ${response.id}');
  }

  // Fee info
  if (response.feeFixed != null) {
    print('Fixed fee: ${response.feeFixed}');
  }
  if (response.feePercent != null) {
    print('Percent fee: ${response.feePercent}%');
  }

  // Amount limits
  if (response.minAmount != null) {
    print('Minimum withdrawal: ${response.minAmount}');
  }
  if (response.maxAmount != null) {
    print('Maximum withdrawal: ${response.maxAmount}');
  }

  // Estimated time
  if (response.eta != null) {
    print('Estimated time: ${response.eta} seconds');
  }

} on CustomerInformationNeededException catch (e) {
  print('Need KYC fields: ${e.response.fields}');

} on CustomerInformationStatusException catch (e) {
  print('KYC status: ${e.response.status}');
}
```

### Withdrawal with all options

The `WithdrawRequest` class supports parameters for refund handling, memos, and more.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerService transferService =
    await TransferServerService.fromDomain("testanchor.stellar.org");

WithdrawRequest request = WithdrawRequest(
  assetCode: "USDC",
  type: "bank_account",
  account: "GCQTGZQTVZ...",                 // Source Stellar account
  lang: "en",                               // Response language
  onChangeCallback: "https://wallet.example.com/callback",
  amount: "1000.00",
  countryCode: "DEU",
  refundMemo: "refund-123",                  // Memo for refund payments
  refundMemoType: "text",                    // Refund memo type
  customerId: "cust-123",                    // SEP-12 customer ID
  locationId: "loc-456",                     // For cash withdrawals: pickup location
  extraFields: {"bank_name": "Example Bank"},
  jwt: jwtToken,
);

WithdrawResponse response = await transferService.withdraw(request);
```

## Exchange operations (cross-asset)

For deposits or withdrawals with currency conversion (e.g., deposit BRL, receive USDC), use the exchange endpoints. These require anchor support for SEP-38 quotes.

### Deposit exchange

Deposit one asset (e.g., off-chain BRL) and receive a different Stellar asset (e.g., USDC).

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerService transferService =
    await TransferServerService.fromDomain("testanchor.stellar.org");

// Deposit BRL, receive USDC on Stellar
DepositExchangeRequest depositExchange = DepositExchangeRequest(
  destinationAsset: "USDC",               // Stellar asset to receive
  sourceAsset: "iso4217:BRL",             // Off-chain asset being deposited (SEP-38 format)
  amount: "480.00",                       // Amount in source asset
  account: "GCQTGZQTVZ...",              // Stellar account to receive tokens
  quoteId: "282837",                      // Optional: SEP-38 quote ID for locked exchange rate
  type: "bank_account",                   // Deposit method
  jwt: jwtToken,
);

DepositResponse response = await transferService.depositExchange(depositExchange);

print('Transaction ID: ${response.id}');
if (response.instructions != null) {
  response.instructions!.forEach((key, instruction) {
    print('$key: ${instruction.value}');
  });
}
```

### Withdraw exchange

Send one Stellar asset (e.g., USDC) and receive a different off-chain asset (e.g., NGN).

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerService transferService =
    await TransferServerService.fromDomain("testanchor.stellar.org");

// Withdraw USDC, receive NGN to bank
WithdrawExchangeRequest withdrawExchange = WithdrawExchangeRequest(
  sourceAsset: "USDC",                    // Stellar asset to send
  destinationAsset: "iso4217:NGN",        // Off-chain asset to receive (SEP-38 format)
  amount: "100.00",                       // Amount in source asset
  type: "bank_account",                   // Withdrawal method
  quoteId: "282838",                      // Optional: SEP-38 quote ID for locked exchange rate
  account: "GCQTGZQTVZ...",              // Source Stellar account
  jwt: jwtToken,
);

WithdrawResponse response = await transferService.withdrawExchange(withdrawExchange);

print('Transaction ID: ${response.id}');
print('Send to: ${response.accountId}');
if (response.memo != null) {
  print('Memo: ${response.memo}');
}
```

## Checking fees

Query the fee endpoint to calculate fees before initiating transfers.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerService transferService =
    await TransferServerService.fromDomain("testanchor.stellar.org");

// Check if fee endpoint is enabled
InfoResponse info = await transferService.info();
if (info.feeInfo?.enabled == true) {
  FeeRequest feeRequest = FeeRequest(
    operation: "deposit",    // "deposit" or "withdraw"
    assetCode: "USD",
    amount: 100.00,          // Note: amount is double, NOT a string
    type: "bank_account",    // Optional: deposit/withdrawal method
    jwt: jwtToken,
  );

  FeeResponse feeResponse = await transferService.fee(feeRequest);
  print('Fee for deposit: ${feeResponse.fee}');
}
```

## Transaction history

List all transactions for an account, with optional filtering by asset, type, and time range.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerService transferService =
    await TransferServerService.fromDomain("testanchor.stellar.org");

AnchorTransactionsRequest request = AnchorTransactionsRequest(
  assetCode: "USD",
  account: "GCQTGZQTVZ...",
  jwt: jwtToken,
  noOlderThan: DateTime.now().subtract(Duration(days: 30)),  // Optional: filter by date
  limit: 10,                               // Optional: max results
  kind: "deposit",                         // Optional: "deposit" or "withdrawal"
  pagingId: null,                          // Optional: for pagination
  lang: "en",                              // Optional: response language
);

AnchorTransactionsResponse response = await transferService.transactions(request);

for (AnchorTransaction tx in response.transactions) {
  print('Transaction: ${tx.id}');
  print('  Kind: ${tx.kind}');
  print('  Status: ${tx.status}');
  print('  Amount In: ${tx.amountIn ?? "pending"}');
  print('  Amount Out: ${tx.amountOut ?? "pending"}');
  print('  Started: ${tx.startedAt}');

  // For exchange transactions
  if (tx.amountInAsset != null) {
    print('  Amount In Asset: ${tx.amountInAsset}');
  }
  if (tx.amountOutAsset != null) {
    print('  Amount Out Asset: ${tx.amountOutAsset}');
  }

  // Fee details
  if (tx.feeDetails != null) {
    print('  Total Fee: ${tx.feeDetails!.total}');
  } else if (tx.amountFee != null) {
    print('  Fee: ${tx.amountFee}');
  }

  // Refund information
  if (tx.refunds != null) {
    print('  Refunded: ${tx.refunds!.amountRefunded}');
  }
}
```

## Single transaction status

Query a specific transaction by ID, Stellar transaction hash, or external transaction ID.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

TransferServerService transferService =
    await TransferServerService.fromDomain("testanchor.stellar.org");

// Query by anchor transaction ID
AnchorTransactionRequest request = AnchorTransactionRequest();
request.id = "82fhs729f63dh0v4";
request.jwt = jwtToken;

AnchorTransactionResponse response = await transferService.transaction(request);
AnchorTransaction tx = response.transaction;

print('Status: ${tx.status}');
print('Kind: ${tx.kind}');

// Check if user action is required by a deadline
if (tx.userActionRequiredBy != null) {
  print('Action required by: ${tx.userActionRequiredBy}');
}

// For withdrawals, show payment destination
if (tx.withdrawAnchorAccount != null) {
  print('Send to: ${tx.withdrawAnchorAccount}');
  print('Memo: ${tx.withdrawMemo} (${tx.withdrawMemoType})');
}

// For deposits, show deposit instructions
if (tx.instructions != null) {
  tx.instructions!.forEach((key, instruction) {
    print('$key: ${instruction.value}');
  });
}

// Check for claimable balance (deposit)
if (tx.claimableBalanceId != null) {
  print('Claimable Balance ID: ${tx.claimableBalanceId}');
}

// Also supports lookup by Stellar transaction hash
AnchorTransactionRequest request2 = AnchorTransactionRequest();
request2.stellarTransactionId = "17a670bc424ff5ce3b386dbfaae9990b66a2a37b4fbe51547e8794962a3f9e6a";
request2.jwt = jwtToken;
AnchorTransactionResponse response2 = await transferService.transaction(request2);

// Or by external transaction ID
AnchorTransactionRequest request3 = AnchorTransactionRequest();
request3.externalTransactionId = "1238234";
request3.jwt = jwtToken;
AnchorTransactionResponse response3 = await transferService.transaction(request3);
```

## Updating pending transactions

When an anchor requests more info via `pending_transaction_info_update` status, use this endpoint to provide the missing information.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:http/http.dart' as http;

TransferServerService transferService =
    await TransferServerService.fromDomain("testanchor.stellar.org");

// First, check what fields are required
AnchorTransactionRequest txRequest = AnchorTransactionRequest();
txRequest.id = "82fhs729f63dh0v4";
txRequest.jwt = jwtToken;
AnchorTransactionResponse txResponse = await transferService.transaction(txRequest);

if (txResponse.transaction.status == "pending_transaction_info_update") {
  // Check required fields
  if (txResponse.transaction.requiredInfoUpdates != null) {
    print('Required updates:');
    txResponse.transaction.requiredInfoUpdates!.forEach((field, info) {
      print('  - $field: ${info.description}');
    });
  }

  if (txResponse.transaction.requiredInfoMessage != null) {
    print('Message: ${txResponse.transaction.requiredInfoMessage}');
  }

  // Submit the updated information
  // Note: id is a positional argument, not named
  PatchTransactionRequest patchRequest = PatchTransactionRequest(
    "82fhs729f63dh0v4",
    fields: {
      "dest": "12345678901234",        // Bank account
      "dest_extra": "021000021",       // Routing number
    },
    jwt: jwtToken,
  );

  http.Response patchResponse = await transferService.patchTransaction(patchRequest);
  print('Updated, status code: ${patchResponse.statusCode}');
}
```

## Error handling

The SDK throws specific exceptions for different error conditions.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

try {
  TransferServerService transferService =
      await TransferServerService.fromDomain("testanchor.stellar.org");

  DepositRequest request = DepositRequest(
    assetCode: "USD",
    account: "GCQTGZQTVZ...",
    jwt: jwtToken,
  );

  DepositResponse response = await transferService.deposit(request);

} on AuthenticationRequiredException catch (e) {
  // Endpoint requires SEP-10 authentication
  print('Authentication required. Get a JWT token via SEP-10 first.');

} on CustomerInformationNeededException catch (e) {
  // Anchor needs KYC info - submit via SEP-12
  print('KYC required. Fields needed:');
  if (e.response.fields != null) {
    for (var field in e.response.fields!) {
      print('  - $field');
    }
  }
  // Now use SEP-12 to submit the required customer information

} on CustomerInformationStatusException catch (e) {
  // KYC submitted but has issues
  String? status = e.response.status;
  if (status == "denied") {
    print('KYC denied. Contact anchor support.');
    if (e.response.moreInfoUrl != null) {
      print('Details: ${e.response.moreInfoUrl}');
    }
  } else if (status == "pending") {
    print('KYC pending review. Try again later.');
    if (e.response.eta != null) {
      print('Estimated wait: ${e.response.eta} seconds');
    }
  }

} catch (e) {
  // Network errors, domain not found, transfer server not available, etc.
  print('Error: $e');
}
```

### Common exceptions

| Exception | Cause | Solution |
|-----------|-------|----------|
| `AuthenticationRequiredException` | Missing or invalid JWT | Authenticate via SEP-10 first |
| `CustomerInformationNeededException` | KYC information required | Submit info via SEP-12 |
| `CustomerInformationStatusException` | KYC pending or denied | Wait for review or contact anchor |
| `Exception` | Network or domain/service unavailable | Check connectivity, verify anchor domain |

## Transaction statuses

| Status | Meaning |
|--------|---------|
| `incomplete` | Transaction not yet ready, more info needed (non-interactive) |
| `pending_user_transfer_start` | Waiting for user to send funds to anchor |
| `pending_user_transfer_complete` | User sent funds, processing |
| `pending_external` | Waiting on external system (bank, crypto network) |
| `pending_anchor` | Anchor is processing the transaction |
| `pending_stellar` | Stellar transaction pending |
| `pending_trust` | User must add trustline for the asset |
| `pending_customer_info_update` | Anchor needs more KYC info. Use SEP-12 `GET /customer` to find required fields |
| `pending_transaction_info_update` | Anchor needs more transaction info. Query `/transaction` for `requiredInfoUpdates`, then use PATCH |
| `on_hold` | Transaction is on hold (e.g., compliance review) |
| `completed` | Transaction successfully completed |
| `refunded` | Transaction refunded to user |
| `expired` | Transaction timed out without completion |
| `no_market` | No market available for requested conversion |
| `too_small` | Transaction amount below minimum |
| `too_large` | Transaction amount exceeds maximum |
| `error` | Unrecoverable error occurred |

## Complete deposit flow

This example shows a complete deposit flow: authentication, info discovery, deposit initiation, and transaction polling.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

String anchorDomain = "testanchor.stellar.org";
KeyPair userKeyPair = KeyPair.fromSecretSeed("SCZANGBA5YHTNYVVV3C7CAZMTQDBJHJG6C34CJDQ66EQ7DZTPBRJFN4A");

// 1. Authenticate via SEP-10
WebAuth webAuth = await WebAuth.fromDomain(anchorDomain, Network.TESTNET);
String jwtToken = await webAuth.jwtToken(userKeyPair.accountId, [userKeyPair]);

// 2. Create transfer service and check info
TransferServerService transferService =
    await TransferServerService.fromDomain(anchorDomain);
InfoResponse info = await transferService.info();

// Verify deposit is supported for USD
DepositAsset? usdDeposit = info.depositAssets?["USD"];
if (usdDeposit == null || !usdDeposit.enabled) {
  throw Exception("USD deposits not supported");
}

// 3. Initiate deposit
String? transactionId;
try {
  DepositRequest depositRequest = DepositRequest(
    assetCode: "USD",
    account: userKeyPair.accountId,
    type: "bank_account",
    amount: "100.00",
    claimableBalanceSupported: "true",
    jwt: jwtToken,
  );

  DepositResponse depositResponse = await transferService.deposit(depositRequest);
  transactionId = depositResponse.id;

  print('Deposit initiated. Transaction ID: $transactionId');

  // Display deposit instructions
  if (depositResponse.instructions != null) {
    print('Deposit instructions:');
    depositResponse.instructions!.forEach((key, instruction) {
      print('  $key: ${instruction.value}');
    });
  }

} on CustomerInformationNeededException catch (e) {
  // Handle KYC requirements via SEP-12
  print('KYC required. Submit via SEP-12: ${e.response.fields}');
  return;
}

// 4. Poll for transaction status
AnchorTransactionRequest txRequest = AnchorTransactionRequest();
txRequest.id = transactionId;
txRequest.jwt = jwtToken;

int maxAttempts = 60;
int attempt = 0;

while (attempt < maxAttempts) {
  AnchorTransactionResponse txResponse =
      await transferService.transaction(txRequest);
  String status = txResponse.transaction.status;

  print('Status: $status');

  switch (status) {
    case "completed":
      print('Deposit completed!');
      print('Amount received: ${txResponse.transaction.amountOut}');
      return;

    case "pending_user_transfer_start":
      print('Waiting for off-chain deposit...');
      break;

    case "pending_trust":
      print('Add trustline for the asset');
      break;

    case "pending_customer_info_update":
      print('Additional KYC required');
      break;

    case "error":
    case "expired":
      print('Transaction failed: ${txResponse.transaction.message ?? status}');
      return;
  }

  await Future.delayed(Duration(seconds: 10));
  attempt++;
}
```

## Related SEPs

- [SEP-01](sep-01.md) - Stellar TOML (service discovery)
- [SEP-10](sep-10.md) - Web authentication (required for most operations)
- [SEP-12](sep-12.md) - KYC API (for customer information submission)
- [SEP-24](sep-24.md) - Interactive deposits/withdrawals (alternative approach)
- [SEP-38](sep-38.md) - Quotes API (for exchange operations)

---

[Back to SEP Overview](README.md)
