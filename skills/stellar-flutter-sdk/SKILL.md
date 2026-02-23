---
name: stellar-flutter-sdk
description: Build Stellar blockchain applications in Flutter/Dart using stellar_flutter_sdk. Use when generating Dart code for transaction building, signing, Horizon API queries, Soroban RPC, smart contract deployment and invocation, XDR encoding/decoding, and SEP protocol integration. Covers 26+ operations, 50 Horizon endpoints, 12 RPC methods, and 17 SEP implementations with async/await and Stream patterns across Android, iOS, Web, and Desktop.
license: Apache 2.0
compatibility: Requires Dart SDK >=3.8.0 <4.0.0 and stellar_flutter_sdk ^3.0.2
metadata:
  version: "1.0.0"
  sdk_version: "3.0.2"
  last_updated: "2026-02-22"
---

# Stellar SDK for Flutter

## Overview

The Stellar Flutter SDK (`stellar_flutter_sdk`) is a comprehensive Dart library for building Stellar blockchain applications on Android, iOS, Web, and Desktop. It provides 100% Horizon API coverage (50/50 endpoints), 100% Soroban RPC coverage (12/12 methods), and 17 SEP implementations. All APIs use Dart `Future` (async/await) for asynchronous operations and `Stream` for real-time event subscriptions. Version 3.0.0+ uses `BigInt` for all 64-bit integer types to ensure full web platform compatibility.

## Installation

```yaml
dependencies:
  stellar_flutter_sdk: ^3.0.2
```

> All code examples below assume `import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';`
>
> If you can't find a constructor or method signature in this file or the topic references, grep `references/api_reference.md` — it has all public class/method signatures.

## 1. Stellar Basics

Fundamental Stellar concepts and SDK patterns.

### Keys and KeyPairs

```dart
// Generate new keypair
KeyPair keyPair = KeyPair.random();
String accountId = keyPair.accountId;   // G... public address
String secretSeed = keyPair.secretSeed; // S... secret seed
// IMPORTANT: Store secretSeed securely. Never log or expose it.

// From existing seed
KeyPair keyPair = KeyPair.fromSecretSeed(secretSeed);
KeyPair publicOnly = KeyPair.fromAccountId(accountId); // public-key-only, cannot sign
```

### Accounts

```dart
KeyPair keyPair = KeyPair.random();
String accountId = keyPair.accountId;

// Fund on testnet using FriendBot (10,000 test XLM)
await FriendBot.fundTestAccount(accountId);

// Query account
StellarSDK sdk = StellarSDK.TESTNET;
AccountResponse account = await sdk.accounts.account(accountId);
print('Sequence: ${account.sequenceNumber}');
print('Subentries: ${account.subentryCount}');

for (Balance balance in account.balances) {
  if (balance.assetType == Asset.TYPE_NATIVE) {
    print('XLM: ${balance.balance}');
  } else {
    print('${balance.assetCode}: ${balance.balance}');
  }
}

// Check account existence (no built-in helper — use try/catch)
bool exists = true;
try { await sdk.accounts.account(accountId); } on ErrorResponse catch (e) {
  if (e.code == 404) exists = false;
}

// Check signers
for (Signer signer in account.signers) {
  // WRONG: signer.ed25519PublicKey -- does NOT exist
  // CORRECT: signer.key returns the public key string, signer.type returns the type
  print('${signer.key} weight=${signer.weight} type=${signer.type}');
}
```

### Assets

```dart
Asset xlm = Asset.NATIVE; // Returns AssetTypeNative instance

// 1-4 char code -> AssetTypeCreditAlphaNum4; 5-12 char -> AssetTypeCreditAlphaNum12
Asset usdc = Asset.createNonNativeAsset('USDC', 'GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN');

// From canonical form
Asset? parsed = Asset.createFromCanonicalForm('USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN');

// WRONG: asset.assetCode -- Asset base class has NO assetCode property
// CORRECT: For type-specific access, cast to AssetTypeCreditAlphaNum
Asset asset = ...; // from balance.asset, operation.asset, offer.selling, etc.
if (asset is AssetTypeCreditAlphaNum) {
  String code = (asset as AssetTypeCreditAlphaNum).code;
  String issuer = (asset as AssetTypeCreditAlphaNum).issuerId;
}

// BETTER for printing/logging: use canonical form (works for ALL asset types)
String display = Asset.canonicalForm(asset); // "native" for XLM, "USDC:GISSUER..." for custom
print('Asset: $display');
```

### Networks

```dart
// Pre-configured: StellarSDK.TESTNET, StellarSDK.PUBLIC, StellarSDK.FUTURENET
// Network passphrases: Network.TESTNET, Network.PUBLIC, Network.FUTURENET
StellarSDK sdk = StellarSDK.TESTNET;
Network network = Network.TESTNET;

// Custom Horizon
StellarSDK customSdk = StellarSDK('https://my-horizon.example.com');
```

## 2. Horizon API - Fetching Data

Query patterns for retrieving blockchain data. All request builders support `.cursor()`, `.limit()`, `.order()` for pagination.

### Query Accounts

```dart
StellarSDK sdk = StellarSDK.TESTNET;

// Single account
AccountResponse account = await sdk.accounts.account(accountId);

// Builder pattern: forSigner(), forAsset(), limit(), order(), cursor()
Page<AccountResponse> bySigner = await sdk.accounts
    .forSigner(accountId)
    .limit(10)
    .order(RequestBuilderOrder.DESC)
    .execute();
for (AccountResponse acct in bySigner.records) {
  print('Account: ${acct.accountId}');
}
```

### Query Transactions

```dart
StellarSDK sdk = StellarSDK.TESTNET;

// Same builder pattern as accounts — forAccount(), limit(), order(), cursor()
Page<TransactionResponse> txPage = await sdk.transactions
    .forAccount(accountId)
    .order(RequestBuilderOrder.DESC)
    .limit(5)
    .execute();

for (TransactionResponse tx in txPage.records) {
  print('${tx.hash} ledger=${tx.ledger}');
}

// Pagination: cursor from last result
Page<TransactionResponse> nextPage = await sdk.transactions
    .forAccount(accountId)
    .cursor(txPage.records.last.pagingToken)
    .limit(5).order(RequestBuilderOrder.DESC).execute();

// Single transaction by hash
TransactionResponse single = await sdk.transactions.transaction('abc123...');
```

For all Horizon endpoints, advanced queries, and pagination patterns:
[Horizon API Reference](./references/horizon_api.md)

## 3. Horizon API - Streaming

Real-time update patterns using Server-Sent Events (SSE). Set cursor to `"now"` for real-time events. Always store the `StreamSubscription` to cancel later.

### Stream Payments

```dart
// Stream pattern — same for payments, transactions, ledgers, operations, effects, offers
StreamSubscription<OperationResponse> subscription = sdk.payments
    .forAccount(accountId)
    .cursor('now')
    .stream()
    .listen((OperationResponse response) {
  if (response is PaymentOperationResponse) {
    print('${response.amount} ${response.assetCode ?? "XLM"} from ${response.from}');
  }
});

// Cancel when no longer needed (e.g., in Flutter widget dispose())
// subscription.cancel();
```

Streams reconnect automatically on connection drops. Always cancel subscriptions to prevent resource leaks.

For reconnection patterns and all streaming endpoints:
[Horizon Streaming Guide](./references/horizon_streaming.md)

## 4. Transactions & Operations

Complete transaction lifecycle: Build -> Sign -> Submit.

### Transaction Lifecycle

```dart
StellarSDK sdk = StellarSDK.TESTNET;
Network network = Network.TESTNET;

// 1. Load sender keypair
KeyPair senderKeyPair = KeyPair.fromSecretSeed(senderSecret);
String senderAccountId = senderKeyPair.accountId;

// 2. Fetch source account (provides sequence number)
AccountResponse senderAccount = await sdk.accounts.account(senderAccountId);

// 3. Build transaction (up to 100 operations)
Transaction transaction = TransactionBuilder(senderAccount)
    .addOperation(
      PaymentOperationBuilder(destinationAccountId, Asset.NATIVE, '100.50')
          .build(),
    )
    .addMemo(Memo.text('payment'))
    .setMaxOperationFee(200) // stroops per operation (default: 100)
    .build();

// 4. Sign transaction
transaction.sign(senderKeyPair, network);

// 5. Submit to Horizon
SubmitTransactionResponse response = await sdk.submitTransaction(transaction);
if (response.success) {
  print('Success! Hash: ${response.hash}');
} else {
  print('Failed: ${response.extras?.resultCodes?.transactionResultCode}');
  print('Op codes: ${response.extras?.resultCodes?.operationsResultCodes}');
}
```

### Common Operations

**Change Trust (Establish Trustline):**

```dart
Asset usdc = Asset.createNonNativeAsset('USDC', 'GISSUER...');
Operation trustline = ChangeTrustOperationBuilder(usdc).build();
// Optional: set limit with ChangeTrustOperationBuilder(usdc, '1000.00')
```

**Manage Sell Offer (DEX):**

```dart
Asset selling = AssetTypeNative();
Asset buying = Asset.createNonNativeAsset('USDC', 'GISSUER...');

// Create new offer (offerId defaults to BigInt.zero = new offer)
Operation newOffer = ManageSellOfferOperationBuilder(
    selling, buying, '100.0', '0.5')  // sell 100 XLM at 0.5 USDC/XLM
    .build();
```

For all 26+ operations with parameters and examples:
[Operations Reference](./references/operations.md)

## 5. Soroban RPC API

RPC endpoint patterns for Soroban smart contract queries.

```dart
SorobanServer server = SorobanServer('https://soroban-testnet.stellar.org:443');
server.enableLogging = true; // optional: debug JSON-RPC requests/responses
GetHealthResponse health = await server.getHealth(); // .status, .latestLedger
```

For all 12 RPC methods including event queries and transaction simulation:
[RPC Reference](./references/rpc.md)

## 6. Smart Contracts

Contract deployment and invocation patterns using the high-level `SorobanClient`.

### Deploy Contract

```dart
KeyPair keyPair = KeyPair.fromSecretSeed(secretSeed);
String rpcUrl = 'https://soroban-testnet.stellar.org:443';

// Step 1: Install WASM bytecode (returns wasm hash)
String wasmHash = await SorobanClient.install(
  installRequest: InstallRequest(
    wasmBytes: wasmBytes,
    sourceAccountKeyPair: keyPair,
    network: Network.TESTNET,
    rpcUrl: rpcUrl,
  ),
);

// Step 2: Deploy contract instance
SorobanClient client = await SorobanClient.deploy(
  deployRequest: DeployRequest(
    sourceAccountKeyPair: keyPair,
    wasmHash: wasmHash,
    network: Network.TESTNET,
    rpcUrl: rpcUrl,
    constructorArgs: [XdrSCVal.forSymbol('init')], // optional
  ),
);
print('Contract ID: ${client.getContractId()}');
```

### Invoke Contract Function

```dart
// Create client for an existing contract
SorobanClient client = await SorobanClient.forClientOptions(
  options: ClientOptions(
    sourceAccountKeyPair: keyPair,
    contractId: 'CABC...',
    network: Network.TESTNET,
    rpcUrl: rpcUrl,
  ),
);

// Read call (simulation only)
XdrSCVal result = await client.invokeMethod(name: 'get_count');
print('Count: ${result.u32}');

// Write call (simulates, signs, submits automatically)
XdrSCVal result = await client.invokeMethod(
  name: 'increment', args: [XdrSCVal.forU32(5)],
);

// With custom options (fee, timeout)
XdrSCVal result = await client.invokeMethod(
  name: 'expensive_op', args: [XdrSCVal.forSymbol('data')],
  methodOptions: MethodOptions(fee: 10000, timeoutInSeconds: 60),
);
```

For contract authorization, multi-auth workflows, and low-level deploy/invoke:
[Smart Contracts Guide](./references/soroban_contracts.md)

## 7. XDR Encoding & Decoding

XDR (External Data Representation) is Stellar's binary serialization format.

### Transaction XDR Roundtrip

```dart
// Encode: Transaction -> base64 XDR
String xdrBase64 = transaction.toEnvelopeXdrBase64();

// Decode: base64 XDR -> Transaction
AbstractTransaction decoded = AbstractTransaction.fromEnvelopeXdrString(xdrBase64);
if (decoded is Transaction) {
  print('Source: ${decoded.sourceAccount}, Fee: ${decoded.fee}');
  print('Operations: ${decoded.operations.length}');
}
```

### Working with Soroban XDR Values (XdrSCVal)

```dart
// Common types: forBool(), forU32(), forI64(), forString(), forSymbol(), forBytes(), forVoid()
XdrSCVal symVal  = XdrSCVal.forSymbol('transfer');
XdrSCVal addrVal = XdrSCVal.forAddress(Address.forAccountId('GABC...').toXdr());
XdrSCVal u128Val = XdrSCVal.forU128Parts(BigInt.zero, BigInt.from(1000));

// Vec (array of XdrSCVal) and Map (array of XdrSCMapEntry)
XdrSCVal vecVal = XdrSCVal.forVec([XdrSCVal.forU32(1), XdrSCVal.forU32(2)]);
XdrSCVal mapVal = XdrSCVal.forMap([XdrSCMapEntry(symVal, XdrSCVal.forU32(42))]);

// Serialize to/from base64 XDR
String base64 = u32Val.toBase64EncodedXdrString();
XdrSCVal decoded = XdrSCVal.fromBase64EncodedXdrString(base64);
```

To submit a pre-signed XDR envelope: `sdk.submitTransactionEnvelopeXdrBase64(signedXdrBase64)`.

For all XdrSCVal factory methods and type mapping:
[XDR Reference](./references/xdr.md) | [Contract Arguments](./references/soroban_contracts.md)

## 8. Error Handling & Troubleshooting

### Horizon Errors

```dart
try {
  AccountResponse account = await sdk.accounts.account(accountId);
} on ErrorResponse catch (e) {
  // HTTP error: e.code (404, 400, etc.), e.body
  print('Horizon error ${e.code}: ${e.body}');
} on TooManyRequestsException catch (e) {
  // Rate limiting (429): e.retryAfter seconds
  await Future.delayed(Duration(seconds: e.retryAfter ?? 5));
}
```

### Transaction Submission Errors

```dart
SubmitTransactionResponse response = await sdk.submitTransaction(transaction);
if (!response.success) {
  String? txCode = response.extras?.resultCodes?.transactionResultCode;
  List<String?>? opCodes = response.extras?.resultCodes?.operationsResultCodes;
  print('Transaction: $txCode, Operations: $opCodes');
  // Common: tx_failed (check opCodes), tx_bad_seq (reload account),
  //   tx_insufficient_balance, tx_bad_auth, tx_too_late
}
```

### Soroban RPC Errors

```dart
// Health check
GetHealthResponse health = await server.getHealth();
if (health.status != GetHealthResponse.HEALTHY) { /* server unhealthy */ }

// Simulation: check simResponse.resultError, simResponse.restorePreamble
// Send: check sendResponse.status == SendTransactionResponse.STATUS_ERROR
// Poll: check txResponse.status for STATUS_SUCCESS / STATUS_FAILED
```

For comprehensive error catalog and solutions:
[Troubleshooting Guide](./references/troubleshooting.md)

## 9. Security Best Practices

Covers secret key management (use `flutter_secure_storage` on mobile, environment variables on server, never store client-side on web), transaction verification before signing (inspect operations, validate fees), network passphrase validation, account ID validation via `StrKey`, and amount precision checks (max 7 decimal places).

For complete security patterns and platform-specific key storage:
[Security Guide](./references/security.md)

## 10. SEP Implementations

The Flutter SDK implements 17 Stellar Ecosystem Proposals (SEPs) — authentication, deposit/withdrawal, federation, KYC, and more.

For all SEP examples with code: [SEP Implementations Guide](./references/sep.md)

## Reference Documentation

- [Operations Reference](./references/operations.md) - All 26+ Stellar operations with examples
- [Horizon API Reference](./references/horizon_api.md) - Complete Horizon endpoint coverage (50/50)
- [Horizon Streaming Guide](./references/horizon_streaming.md) - SSE patterns for all streaming endpoints
- [RPC Reference](./references/rpc.md) - All 12 Soroban RPC methods
- [Smart Contracts Guide](./references/soroban_contracts.md) - Contract deployment, invocation, auth
- [XDR Guide](./references/xdr.md) - XDR encoding/decoding and debugging
- [Troubleshooting Guide](./references/troubleshooting.md) - Error codes, platform & environment info
- [Security Guide](./references/security.md) - Platform-specific key storage, production deployment
- [SEP Implementations](./references/sep.md) - 17 SEP protocols: TOML, Federation, Web Auth, deposits, KYC
- [Advanced Features](./references/advanced.md) - Multi-sig, sponsorship, fee bumps, liquidity pools, muxed accounts, async submission
- [API Reference (Signatures)](./references/api_reference.md) - All public class/method signatures (grep for any class or method not covered above)

## Common Pitfalls

**Dart null safety:** All variables must be initialized before use.
```dart
// WRONG: KeyPair kp; — compile error: non-nullable must be assigned
// CORRECT options:
late KeyPair kp;          // assigned later, throws if used before assignment
KeyPair? kp;              // nullable, check with kp != null
KeyPair kp = KeyPair.random();  // assign immediately
```

**Amounts are always Strings:** All payment amounts, balances, and prices are `String` types (7 decimal places max). Internally, the network uses 64-bit integer stroops (1 XLM = 10,000,000 stroops).
```dart
// WRONG: numeric amount — loses precision
double amount = 100.1234567;

// CORRECT: string amount
String amount = '100.1234567';
```

**Sequence number management:** `TransactionBuilder.build()` mutates the source account's sequence number. A good practice is to reload the account from Horizon before building a new transaction. Don't increment manually unless you have a specific reason — `build()` handles it. Stale sequence numbers cause `tx_bad_seq` errors.

```dart
// CORRECT: reload account, build() increments sequence internally
AccountResponse account = await sdk.accounts.account(accountId); // on-chain seq N
Transaction tx = TransactionBuilder(account).addOperation(op).build(); // uses seq N+1
await sdk.submitTransaction(tx);

// WRONG: manually incrementing — build() already does this
AccountResponse account = await sdk.accounts.account(accountId); // on-chain seq N
account.incrementSequenceNumber(); // now N+1
Transaction tx = TransactionBuilder(account).addOperation(op).build(); // seq N+2 — tx_bad_seq

// When you DO need manual control (e.g., pre-authorized transactions):
BigInt customSeqNum = account.sequenceNumber + BigInt.from(5);
Account customAccount = Account(account.accountId, customSeqNum); // account with modified seq
Transaction tx = TransactionBuilder(customAccount).addOperation(op).build(); // uses customSeqNum+1
```

**Insufficient signatures return `op_bad_auth`, not `tx_bad_auth`:**
```dart
// WRONG: checking transaction code for auth failure
String? txCode = response.extras?.resultCodes?.transactionResultCode; // 'tx_failed'
if (txCode == 'tx_bad_auth') { /* never matches */ }

// CORRECT: check operation codes for op_bad_auth
List<String?>? opCodes = response.extras?.resultCodes?.operationsResultCodes; // ['op_bad_auth']
```

**Fee calculation:** The fee is per operation. For a transaction with N operations at `setMaxOperationFee(200)`, the total fee is N * 200 stroops. The minimum base fee is 100 stroops per operation.

**Two HTTP clients:** Horizon uses `package:http`, Soroban RPC uses `package:dio`. Custom HTTP client configuration differs between the two.

**Web platform restrictions:** `StellarSDK.httpOverrides` and `SorobanServer.httpOverrides` throw `UnsupportedError` on web. Only use on mobile/desktop.
