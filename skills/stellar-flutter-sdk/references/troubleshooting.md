# Troubleshooting Guide

Error handling patterns, common failures, and debugging techniques for the Stellar Flutter SDK.

All code assumes the standard SDK import:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
```

## Exception Hierarchy

| Exception | Source | Fields |
|-----------|--------|--------|
| `ErrorResponse` | Horizon HTTP errors (4xx/5xx) | `code` (int), `body` (String) |
| `TooManyRequestsException` | HTTP 429 rate limiting | `retryAfter` (int?, seconds) |
| `SubmitTransactionTimeoutResponseException` | HTTP 504 on tx submit | `type`, `title`, `status`, `detail` |

Soroban RPC errors use a different pattern -- all responses extend `SorobanRpcResponse` which has an `error` field of type `SorobanRpcErrorResponse?` and a computed `isErrorResponse` getter.

## Horizon HTTP Error Handling

```dart
try {
  AccountResponse account = await sdk.accounts.account(accountId);
  print('Balance: ${account.balances.first.balance}');
} on ErrorResponse catch (e) {
  switch (e.code) {
    case 400: print('Bad request: ${e.body}'); break;
    case 404: print('Account not found: $accountId'); break;
    case 500: print('Horizon server error: ${e.body}'); break;
    default:  print('HTTP ${e.code}: ${e.body}');
  }
} on TooManyRequestsException catch (e) {
  final int waitSeconds = e.retryAfter ?? 5;
  await Future.delayed(Duration(seconds: waitSeconds));
} catch (e) {
  print('Network or unexpected error: $e');
}
```

### Common HTTP Status Codes

| Status | Meaning | Typical Cause |
|--------|---------|---------------|
| 400 | Bad Request | Malformed transaction, invalid parameters |
| 404 | Not Found | Account/transaction/resource does not exist |
| 429 | Too Many Requests | Rate limit exceeded; check `retryAfter` |
| 500 | Internal Server Error | Horizon server issue |
| 504 | Gateway Timeout | Horizon overloaded or transaction took too long |

## Transaction Failure Debugging

When a transaction fails, `SubmitTransactionResponse.success` returns `false`. Diagnostic data is available through the `extras` field.

```dart
try {
  SubmitTransactionResponse response =
      await sdk.submitTransaction(transaction);

  if (response.success) {
    print('Success! Hash: ${response.hash}');
  } else {
    SubmitTransactionResponseExtras? extras = response.extras;
    if (extras != null) {
      ExtrasResultCodes? codes = extras.resultCodes;
      if (codes != null) {
        print('Transaction error: ${codes.transactionResultCode}');
        List<String?>? opCodes = codes.operationsResultCodes;
        if (opCodes != null) {
          for (int i = 0; i < opCodes.length; i++) {
            print('  Operation $i: ${opCodes[i]}');
          }
        }
      }
      print('Result XDR: ${extras.resultXdr}');
    }
  }
} on SubmitTransactionTimeoutResponseException catch (e) {
  print('Submission timed out (504): ${e.detail}');
  // Transaction may still succeed -- poll by hash
} catch (e) {
  print('Submission error: $e');
}
```

### Key Result Code Fields

`ExtrasResultCodes` contains:
- `transactionResultCode` -- transaction-level code (e.g., `tx_failed`, `tx_bad_seq`)
- `operationsResultCodes` -- per-operation codes (e.g., `op_underfunded`, `op_no_trust`)

When `transactionResultCode` is `tx_failed`, individual operations report their own codes in `operationsResultCodes`.

### Transaction Result Codes Reference

| Code | Cause | Solution |
|------|-------|----------|
| `tx_failed` | One or more operations failed | Check operation result codes |
| `tx_bad_seq` | Sequence number mismatch | Reload account, rebuild transaction |
| `tx_insufficient_fee` | Fee below network minimum | Increase base fee or check fee stats |
| `tx_bad_auth` | Invalid signature or insufficient weight | Verify signer key and threshold weights |
| `tx_no_source_account` | Source account does not exist | Create/fund the account first |
| `tx_too_early` | Current time before minTime bound | Adjust TimeBounds or wait |
| `tx_too_late` | Current time past maxTime bound | Rebuild with new TimeBounds |
| `tx_insufficient_balance` | Account lacks XLM for fee + reserves | Fund the source account |

### Operation Result Codes Reference

| Code | Cause | Solution |
|------|-------|----------|
| `op_underfunded` | Insufficient balance for payment | Check available balance minus reserves |
| `op_no_trust` | Destination has no trustline for asset | Destination must call `ChangeTrustOperation` first |
| `op_not_authorized` | Asset requires authorization | Issuer must authorize the trustline |
| `op_line_full` | Destination trustline at limit | Destination must increase trust limit |
| `op_no_destination` | Destination account does not exist | Create account first or verify address |
| `op_low_reserve` | Below minimum XLM reserve | Add XLM to cover base reserve (0.5 XLM per entry) |
| `op_already_exists` | Offer/entry already exists | Use update instead of create |
| `op_no_issuer` | Asset issuer account not found | Verify issuer account ID |
| `op_bad_auth` | Insufficient signature weight for multi-sig | Check signer weights vs operation thresholds |

---

## Common Error Patterns and Solutions

### Insufficient Balance (op_underfunded)

**Cause:** Source account does not have enough XLM (or asset) to cover the payment amount plus reserves.

**Solution:** Check the source balance before building the transaction:

```dart
AccountResponse account = await sdk.accounts.account(accountId);
for (Balance balance in account.balances) {
  if (balance.assetType == Asset.TYPE_NATIVE) {
    print('XLM balance: ${balance.balance}');
  }
}
```

Account minimum balance = `(2 + subentryCount) * 0.5 XLM`. Funds below this minimum cannot be spent.

### Missing Trustline (op_no_trust)

**Cause:** The destination account has no trustline for the asset being sent.

**Solution:** The recipient must establish a trustline before receiving the asset:

```dart
AccountResponse account =
    await sdk.accounts.account(recipientKeyPair.accountId);
Transaction transaction = TransactionBuilder(account)
    .addOperation(ChangeTrustOperationBuilder(asset).build())
    .build();
transaction.sign(recipientKeyPair, Network.TESTNET);
await sdk.submitTransaction(transaction);
```

### Account Not Found (404 ErrorResponse)

**Cause:** The account does not exist on the network (never funded or merged).

**Solution:** Create the account with `CreateAccountOperation` or fund via Friendbot on testnet:

```dart
KeyPair newKeyPair = KeyPair.random();
bool funded = await FriendBot.fundTestAccount(newKeyPair.accountId);
```

### Bad Sequence Number (tx_bad_seq)

**Cause:** The transaction's sequence number does not match the account's current sequence number + 1. Common scenarios:
- Loading an account, submitting a transaction, then building another from the same account object loaded separately
- Two code paths loading the same account and building transactions concurrently

**Key behavior:** `TransactionBuilder.build()` **mutates** the source account object's sequence number. After `build()`, the account object's sequence is incremented internally. This means:

```dart
// CORRECT: reload account, build() increments sequence internally
AccountResponse account = await sdk.accounts.account(accountId);  // on-chain seq N
Transaction tx = TransactionBuilder(account)
    .addOperation(op).build();  // tx uses seq N+1, account object now at N+1
await sdk.submitTransaction(tx);  // on-chain seq advances to N+1

// WRONG: manually incrementing — build() already does this
// account.incrementSequenceNumber(); // now N+1
// Transaction tx = TransactionBuilder(account).build(); // uses N+2 — tx_bad_seq!

// SAFE: building multiple transactions from the SAME account object
// build() auto-advances, so sequential builds work:
Transaction tx1 = TransactionBuilder(account).addOperation(op1).build(); // uses N+1
Transaction tx2 = TransactionBuilder(account).addOperation(op2).build(); // uses N+2
// Submit tx1 first, then tx2 — both succeed in order.
```

### Rate Limiting (429 TooManyRequestsException)

**Solution:** Implement exponential backoff:

```dart
Future<AccountResponse> fetchWithRetry(
  StellarSDK sdk, String accountId, {int maxRetries = 3}
) async {
  for (int attempt = 0; attempt < maxRetries; attempt++) {
    try {
      return await sdk.accounts.account(accountId);
    } on TooManyRequestsException catch (e) {
      final int waitSeconds = e.retryAfter ?? (2 * (attempt + 1));
      if (attempt == maxRetries - 1) rethrow;
      await Future.delayed(Duration(seconds: waitSeconds));
    }
  }
  throw Exception('Max retries exceeded');
}
```

---

## Soroban RPC Error Handling

Soroban uses `SorobanServer` with JSON-RPC. Errors appear at two levels: RPC-level errors (on the `SorobanRpcResponse.error` field) and application-level errors (like `SimulateTransactionResponse.resultError`).

### Simulation Errors

```dart
SimulateTransactionResponse simResponse = await server
    .simulateTransaction(SimulateTransactionRequest(transaction));

// Check RPC-level error
if (simResponse.isErrorResponse) {
  print('RPC error: ${simResponse.error!.code} ${simResponse.error!.message}');
  return;
}

// Check simulation-level error
if (simResponse.resultError != null) {
  print('Simulation failed: ${simResponse.resultError}');
  return;
}

// Check if entries need restoration before invocation
if (simResponse.restorePreamble != null) {
  print('Expired entries detected -- restore footprint first');
  // Build and submit a RestoreFootprint transaction before retrying
  // See soroban_contracts.md > Restore Expired Data
  return;
}

// Simulation succeeded -- apply results to transaction
transaction.sorobanTransactionData = simResponse.transactionData;
transaction.addResourceFee(simResponse.minResourceFee!);
transaction.setSorobanAuth(simResponse.sorobanAuth);
```

### SendTransaction Status Codes

```dart
SendTransactionResponse sendResponse = await server.sendTransaction(tx);

switch (sendResponse.status) {
  case SendTransactionResponse.STATUS_PENDING:
    // Accepted -- poll getTransaction() for final result
    break;
  case SendTransactionResponse.STATUS_DUPLICATE:
    // Already submitted -- poll getTransaction() with the hash
    break;
  case SendTransactionResponse.STATUS_TRY_AGAIN_LATER:
    // Network congestion -- wait and retry
    await Future.delayed(Duration(seconds: 5));
    break;
  case SendTransactionResponse.STATUS_ERROR:
    // Submission failed
    print('Error: ${sendResponse.errorResultXdr}');
    break;
}
```

### Soroban-Specific Errors

**Simulation failure** (`SimulateTransactionResponse.resultError`):
- Contract function does not exist
- Wrong number or type of arguments
- Contract logic reverted (e.g., assertion failed)
- Insufficient authorization

**Expired ledger entries** (`SimulateTransactionResponse.restorePreamble` non-null): Archived state must be restored before invoking. See [Soroban Contracts](./soroban_contracts.md) > Restore Expired Data.

**Resource limits exceeded:** If simulation succeeds but `sendTransaction` returns `STATUS_ERROR`, add a buffer to `minResourceFee`:

```dart
// Add 15% buffer to resource fee
int bufferedFee = (simResponse.minResourceFee! * 1.15).ceil();
transaction.addResourceFee(bufferedFee);
```

---

## Debugging Techniques

1. **Enable Soroban logging:** Set `server.enableLogging = true` on `SorobanServer` to see raw JSON-RPC request/response pairs in the console.

2. **Inspect transaction XDR before submission:**
   ```dart
   String envelopeXdr = transaction.toEnvelopeXdrBase64();
   // Paste into Stellar Laboratory XDR viewer to inspect contents
   ```

3. **Decode failed transaction results:**
   ```dart
   XdrTransactionResult result =
       XdrTransactionResult.fromBase64EncodedXdrString(resultXdrString);
   print('Result code: ${result.result.discriminant}');
   ```

4. **Check Horizon health:** Use `sdk.health.execute()` to verify the Horizon server is responding before debugging application logic.

5. **Verify network passphrase:** Signing with the wrong network passphrase produces invalid signatures. Confirm `Network.TESTNET` vs `Network.PUBLIC` matches your Horizon/RPC endpoint.

6. **Check transaction status on Horizon after uncertain submission:**
   ```dart
   try {
     TransactionResponse tx = await sdk.transactions.transaction(txHash);
     print('Confirmed in ledger: ${tx.ledger}');
   } on ErrorResponse catch (e) {
     if (e.code == 404) print('Transaction not found -- may still be pending');
   }
   ```

---

## Common Mistakes

**Wrong network passphrase:** Signing with `Network.TESTNET` for a mainnet transaction produces invalid signatures. Always match the Network to your Horizon/RPC endpoint.

**Stale sequence numbers:** Building multiple transactions for the same account without submitting them sequentially causes `tx_bad_seq`. Always reload the account or build from the same account object.

**Insufficient fee for Soroban:** Soroban transactions require a resource fee from simulation on top of the base fee. Always call `simulateTransaction()` first and apply `minResourceFee` via `transaction.addResourceFee()`.

**Missing trustline:** Sending non-native assets to an account without a trustline fails with `op_no_trust`. The destination must execute `ChangeTrustOperation` before receiving the asset.

**XLM reserve requirements:** Every subentry (trustline, offer, data entry, signer) requires 0.5 XLM base reserve. Creating entries without sufficient XLM fails with `op_low_reserve`.

**Forgetting to apply simulation data:** After simulating a Soroban transaction, you must call `sorobanTransactionData =`, `addResourceFee()`, and `setSorobanAuth()` on the transaction before signing and submitting.

---

## Platform & Environment

### Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Android  | Full   | Native crypto via pinenacl/pointycastle (pure Dart) |
| iOS      | Full   | Same pure Dart crypto, no platform channels needed |
| Web      | Full   | Since v3.0.0 with BigInt migration, no dart:io deps |
| Desktop  | Full   | Flutter desktop supported |

### Crypto Libraries

All cryptographic operations use **pure Dart** libraries with no platform-specific FFI:

- **Ed25519 signing**: `pinenacl` ^0.6.0
- **Cryptographic hashing**: `pointycastle` ^4.0.0 + `crypto` ^3.0.6
- **No native code**: Works identically across all platforms

### Key Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `http` | ^1.5.0 | HTTP client for Horizon requests |
| `dio` | ^5.9.0 | HTTP client for Soroban RPC (JSON-RPC) |
| `pointycastle` | ^4.0.0 | Cryptographic operations |
| `pinenacl` | ^0.6.0 | Ed25519 signing |
| `toml` | ^0.17.0 | stellar.toml parsing (SEP-0001) |
| `decimal` | ^3.2.4 | Precise decimal arithmetic |

### v3.0.0 Breaking Changes (BigInt Migration)

Version 3.0.0 migrated all 64-bit integer types to `BigInt` for JavaScript/web compatibility:

- `Memo.id(id)`: `int` -> `BigInt`
- `MuxedAccount(accountId, id)`: `int?` -> `BigInt?`
- `Account` sequence number: `BigInt`
- `XdrSCVal.forU64/forI64`: `int` -> `BigInt`
- `XdrInt64.int64` / `XdrUint64.uint64`: `int` -> `BigInt`
- Offer IDs (`ManageSellOfferOperationBuilder` etc.): `BigInt`
