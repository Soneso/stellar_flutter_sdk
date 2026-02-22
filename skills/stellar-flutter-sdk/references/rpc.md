# Soroban RPC API Reference

Complete guide to Soroban RPC methods with the Stellar Flutter SDK.

All code assumes the standard SDK import and a `SorobanServer` instance:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final server = SorobanServer('https://soroban-testnet.stellar.org:443');
// Public: SorobanServer('https://mainnet.sorobanrpc.com')
// Enable logging: server.enableLogging = true;
```

The `SorobanServer` class communicates via JSON-RPC over HTTP using the `dio` package. It is separate from `StellarSDK` (which uses `package:http` for Horizon).

---

## Network and Health Methods

### getHealth

Check if the RPC server is operational.

```dart
final health = await server.getHealth();

if (health.status == GetHealthResponse.HEALTHY) {
  print('Retention window: ${health.ledgerRetentionWindow} ledgers');
  print('Latest ledger: ${health.latestLedger}');
  print('Oldest ledger: ${health.oldestLedger}');
}
```

**Response fields:** `status`, `ledgerRetentionWindow`, `latestLedger`, `oldestLedger`.

---

### getNetwork

Retrieve network passphrase, protocol version, and friendbot URL.

```dart
final network = await server.getNetwork();

print('Passphrase: ${network.passphrase}');
print('Protocol: ${network.protocolVersion}');
if (network.friendbotUrl != null) {
  print('Friendbot: ${network.friendbotUrl}');
}
```

**Response fields:** `passphrase`, `friendbotUrl`, `protocolVersion`.

---

### getLatestLedger

Get the most recent ledger known to the server.

```dart
final latest = await server.getLatestLedger();

print('Sequence: ${latest.sequence}');
print('Hash: ${latest.id}');
print('Protocol version: ${latest.protocolVersion}');
```

**Response fields:** `id`, `sequence`, `protocolVersion`.

---

### getVersionInfo

Get RPC server and Captive Core version details.

```dart
final info = await server.getVersionInfo();

print('RPC version: ${info.version}');
print('Captive Core: ${info.captiveCoreVersion}');
print('Protocol: ${info.protocolVersion}');
```

**Response fields:** `version`, `commitHash`, `buildTimeStamp`, `captiveCoreVersion`, `protocolVersion`.

---

### getFeeStats

Get fee statistics for recent transactions.

```dart
final stats = await server.getFeeStats();

if (stats.sorobanInclusionFee != null) {
  final fee = stats.sorobanInclusionFee!;
  print('Soroban fee p50: ${fee.p50} stroops');
  print('Soroban fee p90: ${fee.p90} stroops');
  print('Soroban fee p99: ${fee.p99} stroops');
}
if (stats.inclusionFee != null) {
  print('Classic fee p50: ${stats.inclusionFee!.p50} stroops');
}
```

**Response type:** `GetFeeStatsResponse` with fields `sorobanInclusionFee`, `inclusionFee` (both `InclusionFee?`), `latestLedger`. Each `InclusionFee` object contains percentiles (`p10`, `p20`, ..., `p99`), `min`, `max`, `mode`, `transactionCount`, `ledgerCount`. **NOTE:** The type is `InclusionFee`, NOT `FeeDistribution`.

---

## Get Account Method

SorobanServer provides a convenience method to fetch accounts, but it returns a **different type** than Horizon's account endpoint:

```dart
// CORRECT: server.getAccount() returns Account? (nullable), NOT AccountResponse
Account? account = await server.getAccount(accountId);
if (account != null) {
  // Account exists, use it for TransactionBuilder
  Transaction tx = TransactionBuilder(account).addOperation(op).build();
}

// WRONG: expecting AccountResponse (Horizon type)
AccountResponse account = await server.getAccount(accountId); // Type error!
```

**Why `Account?` instead of `AccountResponse`?**
- `AccountResponse` is Horizon's rich response with balances, signers, subentries, etc.
- `Account` is a minimal wrapper with just `accountId` and `sequenceNumber` (sufficient for `TransactionBuilder`)
- Soroban RPC doesn't return full account details like Horizon does

---

## Transaction Methods

### simulateTransaction

Simulate a transaction to estimate resources and preview results. Required before submitting any Soroban transaction.

```dart
// Load account for sequence number
Account? account = await server.getAccount(sourceAccountId);
if (account == null) throw Exception('Account not found');

// Build a contract invocation transaction
final invokeOp = InvokeHostFuncOpBuilder(
  InvokeContractHostFunction(contractId, 'hello',
      arguments: [XdrSCVal.forSymbol('World')]),
).build();

final tx = TransactionBuilder(account!)
    .addOperation(invokeOp)
    .build();

// Simulate (optional: add ResourceConfig for instruction leeway)
final simResponse = await server.simulateTransaction(
  SimulateTransactionRequest(tx,
      resourceConfig: ResourceConfig(200000)), // instruction buffer
);

if (simResponse.resultError != null) {
  print('Simulation error: ${simResponse.resultError}');
} else {
  print('Min resource fee: ${simResponse.minResourceFee}');

  // Check if entries need restoration
  if (simResponse.restorePreamble != null) {
    print('Restore required before submission');
  }

  // Get authorization entries
  final auth = simResponse.sorobanAuth;
  if (auth != null) {
    print('Auth entries: ${auth.length}');
  }
}
```

**Response fields:** `results`, `transactionData`, `minResourceFee`, `events`, `restorePreamble`, `sorobanAuth`, `resultError`, `latestLedger`, `stateChanges`.

---

### sendTransaction

Submit a signed transaction to the network. Returns immediately; poll `getTransaction` for results.

```dart
// After simulation, apply results to the transaction
tx.sorobanTransactionData = simResponse.transactionData;
tx.addResourceFee(simResponse.minResourceFee!);
tx.setSorobanAuth(simResponse.sorobanAuth);

// Sign and submit
tx.sign(keyPair, Network.TESTNET);
final sendResponse = await server.sendTransaction(tx);
print('Status: ${sendResponse.status}');
print('Hash: ${sendResponse.hash}');

if (sendResponse.status == SendTransactionResponse.STATUS_ERROR) {
  print('Error: ${sendResponse.errorResultXdr}');
}
```

**Response fields:** `status`, `hash`, `latestLedger`, `errorResultXdr`.

**Status values:** `STATUS_PENDING`, `STATUS_DUPLICATE`, `STATUS_TRY_AGAIN_LATER`, `STATUS_ERROR`.

---

### getTransaction

Poll for the status and result of a submitted transaction.

```dart
// Single check
final txResponse = await server.getTransaction(txHash);

if (txResponse.status == GetTransactionResponse.STATUS_SUCCESS) {
  final returnValue = txResponse.getResultValue();
  print('Return value: $returnValue');
  print('Ledger: ${txResponse.ledger}');
} else if (txResponse.status == GetTransactionResponse.STATUS_NOT_FOUND) {
  print('Transaction not yet processed');
} else if (txResponse.status == GetTransactionResponse.STATUS_FAILED) {
  print('Transaction failed: ${txResponse.resultXdr}');
}

// Polling pattern: loop until confirmed or failed
GetTransactionResponse result;
do {
  await Future.delayed(Duration(seconds: 3));
  result = await server.getTransaction(sendResponse.hash!);
} while (result.status == GetTransactionResponse.STATUS_NOT_FOUND);
```

**Response fields:** `status`, `latestLedger`, `ledger`, `createdAt`, `envelopeXdr`, `resultXdr`, `resultMetaXdr`.

**Status values:** `STATUS_SUCCESS`, `STATUS_NOT_FOUND`, `STATUS_FAILED`.

**Helper methods:** `getResultValue()` returns the `XdrSCVal` return value from contract invocations (null for classic operations or failed transactions). `getCreatedContractId()` returns the contract ID if the transaction deployed a contract. `getWasmId()` returns the wasm hash if the transaction uploaded code.

---

## Ledger Query Methods

### getLedgerEntries

Read specific ledger entries by their XDR-encoded keys.

```dart
// Build a ledger key for contract data
final ledgerKey = XdrLedgerKey(XdrLedgerEntryType.CONTRACT_DATA);
ledgerKey.contractData = XdrLedgerKeyContractData(
  Address.forContractId(contractId).toXdr(),
  XdrSCVal.forSymbol('counter'),
  XdrContractDataDurability.PERSISTENT,
);

final response = await server.getLedgerEntries([
  ledgerKey.toBase64EncodedXdrString(),
]);

if (response.entries != null && response.entries!.isNotEmpty) {
  final entry = response.entries!.first;
  print('Last modified: ${entry.lastModifiedLedgerSeq}');
  print('Expires at ledger: ${entry.liveUntilLedgerSeq}');
  final data = entry.ledgerEntryDataXdr;
  print('Value: ${data.contractData?.val}');
}
```

**Response type:** `GetLedgerEntriesResponse` with `List<LedgerEntry>? entries` and `int? latestLedger`. Each `LedgerEntry` has `key`, `xdr`, `lastModifiedLedgerSeq`, `liveUntilLedgerSeq?`, and `ledgerEntryDataXdr` getter. **NOTE:** The type is `LedgerEntry`, NOT `LedgerEntryResult`.

**Entry types:** `ACCOUNT`, `CONTRACT_DATA`, `CONTRACT_CODE`, `TRUSTLINE`.

---

### getContractData

Convenience method to read a single contract data entry.

```dart
final entry = await server.getContractData(
  contractId,
  XdrSCVal.forSymbol('counter'),
  XdrContractDataDurability.PERSISTENT,
);

if (entry != null) {
  final value = entry.ledgerEntryDataXdr.contractData?.val;
  print('Counter value: $value');
} else {
  print('Entry not found');
}
```

---

### getTransactions

Retrieve a paginated list of transactions from ledger history.

```dart
final request = GetTransactionsRequest(
  startLedger: 1000,
  paginationOptions: PaginationOptions(limit: 50),
);

final response = await server.getTransactions(request);
if (response.transactions != null) {
  for (final tx in response.transactions!) {
    print('TX: ${tx.txHash}, Status: ${tx.status}, Ledger: ${tx.ledger}');
  }
  // Paginate with cursor
  if (response.cursor != null) {
    final nextPage = GetTransactionsRequest(
      paginationOptions: PaginationOptions(cursor: response.cursor),
    );
    // await server.getTransactions(nextPage);
  }
}
```

---

## Event Methods

### getEvents

Retrieve contract events within a ledger range with optional filters.

```dart
// Get transfer events from a specific contract
final filter = EventFilter(
  type: 'contract',
  contractIds: ['CABC...'],
  topics: [
    TopicFilter([
      '*',
      XdrSCVal.forSymbol('transfer').toBase64EncodedXdrString(),
    ]),
  ],
);

final request = GetEventsRequest(
  startLedger: 1000,
  filters: [filter],
  paginationOptions: PaginationOptions(limit: 100),
);

final response = await server.getEvents(request);
if (response.events != null) {
  for (final event in response.events!) {
    print('Event: ${event.id} at ledger ${event.ledger}');
    print('Type: ${event.type}');
    print('Contract: ${event.contractId}');
  }
}
```

**GetEventsRequest:** `startLedger`, `endLedger`, `filters` (max 5), `paginationOptions`.

**EventFilter:** `type`, `contractIds` (max 5), `topics`.

**Event filter types:**
- `"contract"` -- events emitted by contract code
- `"system"` -- system-level events (e.g., TTL extensions)
- `"diagnostic"` -- diagnostic events (includes internal host function calls)

**TopicFilter:** Takes a list of segment matchers. Use `"*"` as a wildcard for any segment, base64-encoded `XdrSCVal` for exact match.

---

## Contract Introspection Helpers

`SorobanServer` includes convenience methods for loading contract bytecode and metadata:

```dart
// Load contract bytecode by deployed contract ID
XdrContractCodeEntry? code = await server.loadContractCodeForContractId(contractId);
if (code != null) {
  print('Code size: ${code.code.dataStore.length} bytes');
}

// Load parsed contract info (functions, types, events)
SorobanContractInfo? info = await server.loadContractInfoForContractId(contractId);
// or by WASM hash: await server.loadContractInfoForWasmId(wasmId);
if (info != null) {
  for (final func in info.funcs) {
    print('Function: ${func.name}');
  }
}
```

For full introspection details (enumerating parameters, UDTs, events), see [Soroban Contracts](./soroban_contracts.md).

---

## Error Handling

All `SorobanServer` methods return response objects extending `SorobanRpcResponse`. Check `isErrorResponse` and `error` for JSON-RPC-level errors:

```dart
final health = await server.getHealth();
if (health.isErrorResponse) {
  print('RPC error: ${health.error?.message}');
}
```

For detailed error handling patterns (simulation errors, send errors, restore preamble), see [Troubleshooting Guide](./troubleshooting.md).

### Common RPC Error Codes

| Code | Meaning |
|------|---------|
| -32700 | Parse error |
| -32600 | Invalid request |
| -32601 | Method not found |
| -32602 | Invalid params |
| -32603 | Internal error |

---

## Method Summary

| RPC Method | SDK Method | Response Class |
|------------|-----------|----------------|
| `getHealth` | `getHealth()` | `GetHealthResponse` |
| `getNetwork` | `getNetwork()` | `GetNetworkResponse` |
| `getFeeStats` | `getFeeStats()` | `GetFeeStatsResponse` |
| `getVersionInfo` | `getVersionInfo()` | `GetVersionInfoResponse` |
| `getLatestLedger` | `getLatestLedger()` | `GetLatestLedgerResponse` |
| `getLedgerEntries` | `getLedgerEntries(List<String> keys)` | `GetLedgerEntriesResponse` |
| `getTransaction` | `getTransaction(String hash)` | `GetTransactionResponse` |
| `getTransactions` | `getTransactions(GetTransactionsRequest)` | `GetTransactionsResponse` |
| `getEvents` | `getEvents(GetEventsRequest)` | `GetEventsResponse` |
| `simulateTransaction` | `simulateTransaction(SimulateTransactionRequest)` | `SimulateTransactionResponse` |
| `sendTransaction` | `sendTransaction(Transaction)` | `SendTransactionResponse` |

**Helper methods** (not direct RPC calls):
- `getAccount(String accountId)` → `Account?` -- fetches account via `getLedgerEntries`
- `getContractData(String contractId, XdrSCVal key, XdrContractDataDurability durability)` → `LedgerEntry?`
- `loadContractCodeForContractId(String contractId)` → `XdrContractCodeEntry?`
- `loadContractCodeForWasmId(String wasmId)` → `XdrContractCodeEntry?`
- `loadContractInfoForContractId(String contractId)` → `SorobanContractInfo?`
- `loadContractInfoForWasmId(String wasmId)` → `SorobanContractInfo?`
