# Soroban Smart Contracts

Deploy and interact with Soroban smart contracts using the Stellar Flutter SDK.

**Protocol details**: [Soroban Documentation](https://developers.stellar.org/docs/smart-contracts)

## Quick Start

Install WASM, deploy a contract, and call a method in one go.

```dart
import 'dart:io';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

KeyPair keyPair = KeyPair.fromSecretSeed('SXXX...');
String rpcUrl = 'https://soroban-testnet.stellar.org:443';

// 1. Install WASM
String wasmHash = await SorobanClient.install(
  installRequest: InstallRequest(
    wasmBytes: File('hello.wasm').readAsBytesSync(),
    rpcUrl: rpcUrl,
    network: Network.TESTNET,
    sourceAccountKeyPair: keyPair,
  ),
);

// 2. Deploy
SorobanClient client = await SorobanClient.deploy(
  deployRequest: DeployRequest(
    rpcUrl: rpcUrl,
    network: Network.TESTNET,
    sourceAccountKeyPair: keyPair,
    wasmHash: wasmHash,
  ),
);

// 3. Invoke
XdrSCVal result = await client.invokeMethod(
  name: 'hello',
  args: [XdrSCVal.forSymbol('World')],
);
print('${result.vec![0].sym}, ${result.vec![1].sym}'); // Hello, World
```

## SorobanServer

Direct communication with Soroban RPC nodes for low-level operations.

### Connecting to RPC

Connect to a Soroban RPC node to send requests and receive responses.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SorobanServer server = SorobanServer('https://soroban-testnet.stellar.org:443');

// Optional: enable debug logging
server.enableLogging = true;
```

### Health Check

Verify the RPC node is operational before making requests.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SorobanServer server = SorobanServer('https://soroban-testnet.stellar.org:443');

GetHealthResponse health = await server.getHealth();
if (health.status == GetHealthResponse.HEALTHY) {
  print('Node healthy');
}
```

### Network Information

Get network passphrase and protocol version.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SorobanServer server = SorobanServer('https://soroban-testnet.stellar.org:443');

GetNetworkResponse network = await server.getNetwork();
print('Passphrase: ${network.passphrase}');
print('Protocol version: ${network.protocolVersion}');
```

### Latest Ledger

Get the current ledger sequence for transaction timing.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SorobanServer server = SorobanServer('https://soroban-testnet.stellar.org:443');

GetLatestLedgerResponse ledger = await server.getLatestLedger();
print('Sequence: ${ledger.sequence}');
```

### Account Data

Load account information (needed for transaction building).

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SorobanServer server = SorobanServer('https://soroban-testnet.stellar.org:443');

// Returns Account? (not AccountResponse like Horizon)
Account? account = await server.getAccount('GABC...');
if (account != null) {
  print('Sequence: ${account.sequenceNumber}');
}
```

### Contract Data

Read persistent or temporary data stored by a contract.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SorobanServer server = SorobanServer('https://soroban-testnet.stellar.org:443');

LedgerEntry? entry = await server.getContractData(
  'CCXYZ...',
  XdrSCVal.forSymbol('counter'),
  XdrContractDataDurability.PERSISTENT,
);

if (entry != null) {
  print('Value: ${entry.ledgerEntryDataXdr.contractData?.val}');
}
```

### Contract Info

Load contract specification and metadata.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SorobanServer server = SorobanServer('https://soroban-testnet.stellar.org:443');

// By contract ID
SorobanContractInfo? info = await server.loadContractInfoForContractId('CCXYZ...');
if (info != null) {
  print('Spec entries: ${info.specEntries.length}');
}

// By WASM ID (hash of uploaded code)
SorobanContractInfo? info2 = await server.loadContractInfoForWasmId(wasmId);
```

### Get Ledger Entries

Query raw ledger entries by their keys. Use when you need direct access to ledger state data.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SorobanServer server = SorobanServer('https://soroban-testnet.stellar.org:443');

// Build ledger key for contract data
XdrLedgerKey ledgerKey = XdrLedgerKey.forContractData(
  XdrSCAddress.forContractId('CABC...'),
  XdrSCVal.forSymbol('counter'),
  XdrContractDataDurability.PERSISTENT,
);

// Request ledger entries
GetLedgerEntriesResponse response = await server.getLedgerEntries([
  ledgerKey.toBase64EncodedXdrString(),
]);

if (response.entries != null) {
  for (LedgerEntry entry in response.entries!) {
    print('Ledger: ${entry.lastModifiedLedgerSeq}');
  }
}
```

### Load Contract Code

Helper methods to load contract bytecode from the network.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SorobanServer server = SorobanServer('https://soroban-testnet.stellar.org:443');

// By contract ID
XdrContractCodeEntry? code = await server.loadContractCodeForContractId('CCXYZ...');
if (code != null) {
  print('Code size: ${code.code.dataStore.length} bytes');
}

// By WASM ID
XdrContractCodeEntry? code2 = await server.loadContractCodeForWasmId(wasmId);
```

## SorobanClient

High-level API for contract interaction.

### Creating a Client

Set up a SorobanClient instance for interacting with a specific contract.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SorobanClient client = await SorobanClient.forClientOptions(
  options: ClientOptions(
    sourceAccountKeyPair: KeyPair.fromSecretSeed('SXXX...'),
    contractId: 'CCXYZ...',
    network: Network.TESTNET,
    rpcUrl: 'https://soroban-testnet.stellar.org:443',
  ),
);

List<String> methodNames = client.getMethodNames();
ContractSpec spec = client.getContractSpec();
```

### Invoking Methods

Call contract functions to read data or submit state changes.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SorobanClient client = await SorobanClient.forClientOptions(
  options: ClientOptions(
    sourceAccountKeyPair: KeyPair.fromSecretSeed('SXXX...'),
    contractId: 'CCXYZ...',
    network: Network.TESTNET,
    rpcUrl: 'https://soroban-testnet.stellar.org:443',
  ),
);

// Read-only (returns simulation result)
XdrSCVal balance = await client.invokeMethod(
  name: 'balance',
  args: [XdrSCVal.forAccountAddress('GABC...')],
);

// Write (auto-signs and submits)
XdrSCVal result = await client.invokeMethod(
  name: 'transfer',
  args: [
    XdrSCVal.forAccountAddress('GFROM...'),
    XdrSCVal.forAccountAddress('GTO...'),
    XdrSCVal.forI128Parts(BigInt.zero, BigInt.from(1000)),
  ],
);

// Custom options
XdrSCVal result2 = await client.invokeMethod(
  name: 'expensive_op',
  args: [],
  methodOptions: MethodOptions(
    fee: 10000,
    timeoutInSeconds: 30,
    restore: true, // Auto-restore expired state
  ),
);
```

## Installing and Deploying

Put your contract on the network. Install uploads the WASM bytecode once; deploy creates contract instances from that code.

### Installation

Upload WASM bytecode (do once per contract version):

```dart
import 'dart:io';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

String wasmHash = await SorobanClient.install(
  installRequest: InstallRequest(
    wasmBytes: File('contract.wasm').readAsBytesSync(),
    rpcUrl: 'https://soroban-testnet.stellar.org:443',
    network: Network.TESTNET,
    sourceAccountKeyPair: KeyPair.fromSecretSeed('SXXX...'),
  ),
);
```

### Deployment

Create contract instance from installed WASM:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Basic deployment
SorobanClient client = await SorobanClient.deploy(
  deployRequest: DeployRequest(
    rpcUrl: 'https://soroban-testnet.stellar.org:443',
    network: Network.TESTNET,
    sourceAccountKeyPair: KeyPair.fromSecretSeed('SXXX...'),
    wasmHash: wasmHash,
  ),
);

// With constructor (protocol 22+)
SorobanClient client2 = await SorobanClient.deploy(
  deployRequest: DeployRequest(
    rpcUrl: 'https://soroban-testnet.stellar.org:443',
    network: Network.TESTNET,
    sourceAccountKeyPair: KeyPair.fromSecretSeed('SXXX...'),
    wasmHash: wasmHash,
    constructorArgs: [XdrSCVal.forSymbol('MyToken'), XdrSCVal.forU32(8)],
  ),
);
```

## AssembledTransaction

Fine-grained control over the transaction lifecycle. Use `buildInvokeMethodTx()` instead of `invokeMethod()` when you need to inspect simulation results, add memos, or handle multi-signature workflows.

### Building Without Submitting

Build a transaction to inspect it before submission.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SorobanClient client = await SorobanClient.forClientOptions(
  options: ClientOptions(
    sourceAccountKeyPair: KeyPair.fromSecretSeed('SXXX...'),
    contractId: 'CCXYZ...',
    network: Network.TESTNET,
    rpcUrl: 'https://soroban-testnet.stellar.org:443',
  ),
);

// Build without submitting
AssembledTransaction tx = await client.buildInvokeMethodTx(
  name: 'transfer',
  args: [XdrSCVal.forSymbol('test')],
);
```

### Accessing Simulation Results

Get simulation data including return values and resource estimates.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Access simulation results
SimulateHostFunctionResult simData = tx.getSimulationData();
XdrSCVal returnValue = simData.returnedValue;
int? minResourceFee = tx.simulationResponse?.minResourceFee;
```

### Read-Only vs Write Calls

Check if a call is read-only (simulation only) or requires submission.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

if (tx.isReadCall()) {
  // Read-only: result available from simulation
  XdrSCVal result = tx.getSimulationData().returnedValue;
} else {
  // Write: must sign and submit
  GetTransactionResponse response = await tx.signAndSend();
  XdrSCVal? result = response.getResultValue();
}
```

### Modifying Before Submission

Skip automatic simulation to modify the transaction (e.g., add memo) before simulating.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Build without auto-simulation
AssembledTransaction tx = await client.buildInvokeMethodTx(
  name: 'my_method',
  args: [],
  methodOptions: MethodOptions(simulate: false),
);

// Modify the raw transaction builder
tx.raw!.addMemo(MemoText('My memo'));

// Now simulate and submit
await tx.simulate();
GetTransactionResponse response = await tx.signAndSend();
```

## Authorization

Handle multi-party signing for operations like swaps, escrow, and transfers that require consent from multiple accounts.

### Check Who Needs to Sign

Before submission, check which accounts need to authorize the transaction.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

KeyPair alice = KeyPair.fromSecretSeed('SALICE...');
KeyPair bob = KeyPair.fromSecretSeed('SBOB...');

SorobanClient client = await SorobanClient.forClientOptions(
  options: ClientOptions(
    sourceAccountKeyPair: alice,
    contractId: 'CSWAP...',
    network: Network.TESTNET,
    rpcUrl: 'https://soroban-testnet.stellar.org:443',
  ),
);

AssembledTransaction tx = await client.buildInvokeMethodTx(
  name: 'swap',
  args: [
    XdrSCVal.forAccountAddress(alice.accountId),
    XdrSCVal.forAccountAddress(bob.accountId),
    XdrSCVal.forI128Parts(BigInt.zero, BigInt.from(1000)),
    XdrSCVal.forI128Parts(BigInt.zero, BigInt.from(500)),
  ],
);

// Check who needs to sign (returns list of account IDs)
List<String> neededSigners = tx.needsNonInvokerSigningBy();
// e.g., ['GBOB...'] - Bob needs to authorize
```

### Local Signing

Sign auth entries when you have the private key locally.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Sign Bob's auth entries (Bob's keypair available locally)
await tx.signAuthEntries(signerKeyPair: bob);

// Submit (Alice signs the transaction envelope)
GetTransactionResponse response = await tx.signAndSend();
```

### Remote Signing

Sign auth entries when the private key is on another server (e.g., custody service).

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Only have Bob's public key locally
KeyPair bobPublicKey = KeyPair.fromAccountId('GBOB...');

await tx.signAuthEntries(
  signerKeyPair: bobPublicKey,
  authorizeEntryDelegate: (SorobanAuthorizationEntry entry, Network network) async {
    // Send to remote server for signing
    String base64Entry = entry.toBase64EncodedXdrString();
    String signedBase64 = await sendToRemoteServer(base64Entry); // Your implementation
    return SorobanAuthorizationEntry.fromBase64EncodedXdr(signedBase64);
  },
);

// Submit after all auth entries are signed
GetTransactionResponse response = await tx.signAndSend();
```

## Type Conversions

Convert between Dart native types and Soroban XDR values.

### Creating XdrSCVal

Create XDR values manually for contract arguments.

#### Primitives

Basic data types like numbers, booleans, and strings.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

XdrSCVal boolVal = XdrSCVal.forBool(true);
XdrSCVal u32Val = XdrSCVal.forU32(42);
XdrSCVal i32Val = XdrSCVal.forI32(-42);
XdrSCVal u64Val = XdrSCVal.forU64(BigInt.from(1000000));
XdrSCVal i64Val = XdrSCVal.forI64(BigInt.from(-1000000));
XdrSCVal stringVal = XdrSCVal.forString('Hello');
XdrSCVal symbolVal = XdrSCVal.forSymbol('transfer');
XdrSCVal bytesVal = XdrSCVal.forBytes(Uint8List.fromList([0xDE, 0xAD, 0xBE, 0xEF]));
XdrSCVal voidVal = XdrSCVal.forVoid();
```

#### Big Integers (128/256-bit)

Handle integers that exceed Dart's native int range using BigInt.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// From BigInt (recommended for large values)
XdrSCVal u128Val = XdrSCVal.forU128BigInt(BigInt.parse('340282366920938463463374607431768211455'));
XdrSCVal i128Val = XdrSCVal.forI128BigInt(BigInt.parse('-170141183460469231731687303715884105728'));

// 256-bit
XdrSCVal u256Val = XdrSCVal.forU256BigInt(BigInt.two.pow(200));
XdrSCVal i256Val = XdrSCVal.forI256BigInt(-BigInt.two.pow(200));

// Small integers work directly
XdrSCVal smallI128 = XdrSCVal.forI128BigInt(BigInt.from(42));

// Parts method (hi/lo)
XdrSCVal partsVal = XdrSCVal.forI128Parts(BigInt.zero, BigInt.from(1000));
```

#### Addresses

Account and contract addresses for referencing entities on the network.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Account address (G...) - convenience method
XdrSCVal account = XdrSCVal.forAccountAddress('GABC...');

// Contract address (C...) - convenience method
XdrSCVal contract = XdrSCVal.forContractAddress('CABC...');

// Via Address helper
XdrSCVal addr = Address.forAccountId('GABC...').toXdrSCVal();
```

#### Collections

Arrays (vectors) and key-value pairs (maps) for structured data.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Vector (array)
XdrSCVal vec = XdrSCVal.forVec([
  XdrSCVal.forSymbol('a'),
  XdrSCVal.forSymbol('b'),
]);

// Map (key-value pairs)
XdrSCVal map = XdrSCVal.forMap([
  XdrSCMapEntry(XdrSCVal.forSymbol('name'), XdrSCVal.forString('Alice')),
  XdrSCMapEntry(XdrSCVal.forSymbol('age'), XdrSCVal.forU32(30)),
]);
```

### Using ContractSpec

Auto-convert native Dart values based on the contract specification. The spec is loaded from the contract and knows the expected types.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

ContractSpec spec = client.getContractSpec();

// Convert function arguments (uses spec to determine types)
List<XdrSCVal> args = spec.funcArgsToXdrSCValues('swap', {
  'a': 'GALICE...',        // Auto-converts to Address
  'b': 'GBOB...',
  'token_a': 'CTOKEN1...', // Contract address
  'token_b': 'CTOKEN2...',
  'amount_a': 1000,         // Auto-converts to i128
  'min_b_for_a': 950,
  'amount_b': 500,
  'min_a_for_b': 450,
});

// Explore contract functions
List<XdrSCSpecFunctionV0> functions = spec.funcs();
XdrSCSpecFunctionV0? swapFunc = spec.getFunc('swap');

// Find custom types
XdrSCSpecEntry? myUnion = spec.findEntry('myUnion');
```

### Advanced Type Conversions

For low-level control, use `nativeToXdrSCVal()` with explicit type definitions.

#### Void and Option (Nullable)

Empty values and nullable types for optional data.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Void
XdrSCSpecTypeDef def = XdrSCSpecTypeDef.forVoid();
XdrSCVal val = spec.nativeToXdrSCVal(null, def);

// Option (nullable) - returns string or void
XdrSCSpecTypeDef optionDef = XdrSCSpecTypeDef.forOption(
  XdrSCSpecTypeOption(XdrSCSpecTypeDef.forString()),
);
XdrSCVal strVal = spec.nativeToXdrSCVal('a string', optionDef);  // String value
XdrSCVal noneVal = spec.nativeToXdrSCVal(null, optionDef);       // Void (none)
```

#### Vectors with Element Type

Strongly-typed arrays where all elements share the same type.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

XdrSCSpecTypeDef def = XdrSCSpecTypeDef.forVec(
  XdrSCSpecTypeVec(XdrSCSpecTypeDef.forSymbol()),
);
XdrSCVal val = spec.nativeToXdrSCVal(['a', 'b', 'c'], def);
```

#### Maps with Key/Value Types

Strongly-typed key-value mappings with specific types for keys and values.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

XdrSCSpecTypeMap mapType = XdrSCSpecTypeMap(
  XdrSCSpecTypeDef.forString(),
  XdrSCSpecTypeDef.forAddress(),
);
XdrSCSpecTypeDef def = XdrSCSpecTypeDef.forMap(mapType);
XdrSCVal val = spec.nativeToXdrSCVal({
  'alice': 'GALICE...',
  'bob': 'GBOB...',
}, def);
```

#### Tuples

Fixed-size collections of values where each position has a specific type.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

XdrSCSpecTypeTuple tuple = XdrSCSpecTypeTuple([
  XdrSCSpecTypeDef.forString(),
  XdrSCSpecTypeDef.forBool(),
  XdrSCSpecTypeDef.forU32(),
]);
XdrSCSpecTypeDef def = XdrSCSpecTypeDef.forTuple(tuple);
XdrSCVal val = spec.nativeToXdrSCVal(['hello', true, 42], def);
```

#### Bytes and BytesN

Binary data of variable or fixed length for hashes, keys, and raw data.

```dart
import 'dart:typed_data';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Variable-length bytes
XdrSCSpecTypeDef def = XdrSCSpecTypeDef.forBytes();
XdrSCVal val = spec.nativeToXdrSCVal(Uint8List(32), def);

// Fixed-length bytes (e.g., 32 bytes for a hash)
XdrSCSpecTypeDef fixedDef = XdrSCSpecTypeDef.forBytesN(XdrSCSpecTypeBytesN(XdrUint32(32)));
XdrSCVal fixedVal = spec.nativeToXdrSCVal(Uint8List(32), fixedDef);
```

#### User-Defined Types (Enum, Struct, Union)

**Enum** -- pass the integer value:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

XdrSCSpecTypeDef def = XdrSCSpecTypeDef.forUdt(XdrSCSpecTypeUDT('MyEnum'));
XdrSCVal val = spec.nativeToXdrSCVal(2, def); // Enum case with value 2
```

**Struct** -- pass a map:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

XdrSCSpecTypeDef def = XdrSCSpecTypeDef.forUdt(XdrSCSpecTypeUDT('MyStruct'));
XdrSCVal val = spec.nativeToXdrSCVal({
  'field1': 100,
  'field2': 'hello',
  'field3': true,
}, def);
```

**Union** -- use `NativeUnionVal`:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

XdrSCSpecTypeDef def = XdrSCSpecTypeDef.forUdt(XdrSCSpecTypeUDT('MyUnion'));

// Void case (no values)
XdrSCVal val = spec.nativeToXdrSCVal(NativeUnionVal('voidCase'), def);

// Tuple case (with values)
XdrSCVal tupleVal = spec.nativeToXdrSCVal(
  NativeUnionVal('tupleCase', values: ['hello', 42]),
  def,
);
```

### Reading Return Values

Access return values by their XDR type.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

XdrSCVal result = await client.invokeMethod(name: 'get_data', args: []);

// Direct types (no unwrapping needed)
String? name = result.str;
String? symbol = result.sym;
bool? flag = result.b;

// Numeric wrappers -- must unwrap to get Dart value
int? count = result.u32?.uint32;
BigInt? bigVal = result.i64?.int64;

// i128 extraction (common for token balances)
if (result.i128 != null) {
  BigInt hi = result.i128!.hi.int64;
  BigInt lo = result.i128!.lo.uint64;
  BigInt value = (hi << 64) + lo;
}

// Iterate vector elements
if (result.vec != null) {
  for (XdrSCVal item in result.vec!) {
    print(item.sym);
  }
}

// Access map entries
if (result.map != null) {
  for (XdrSCMapEntry entry in result.map!) {
    print('${entry.key.sym}: ${entry.val.str}');
  }
}
```

## Events

Query contract events emitted during execution. Useful for tracking transfers, state changes, and other contract activity.

### Basic Event Query

Query events starting from a specific ledger.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SorobanServer server = SorobanServer('https://soroban-testnet.stellar.org:443');

// Get events starting from ledger 12345
GetEventsResponse response = await server.getEvents(
  GetEventsRequest(startLedger: 12345),
);

if (response.events != null) {
  for (var event in response.events!) {
    print('Ledger: ${event.ledger}');
    print('Contract: ${event.contractId}');
    print('Type: ${event.type}');
  }
}
```

### Filtering by Contract and Topic

Filter events by contract ID and topic values.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SorobanServer server = SorobanServer('https://soroban-testnet.stellar.org:443');

String contractId = 'CCXYZ...';

// Filter: any first topic, "transfer" as second topic
EventFilter filter = EventFilter(
  type: 'contract',
  contractIds: [contractId],
  topics: [
    TopicFilter([
      '*', // Wildcard for first topic
      XdrSCVal.forSymbol('transfer').toBase64EncodedXdrString(),
    ]),
  ],
);

GetEventsResponse response = await server.getEvents(
  GetEventsRequest(
    startLedger: 12345,
    filters: [filter],
  ),
);

if (response.events != null) {
  for (var event in response.events!) {
    print('Ledger: ${event.ledger}');
  }
}
```

## Error Handling

Handle errors at different stages: client creation, simulation, and transaction submission.

### Debug Logging

Enable logging to diagnose issues.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SorobanClient client = await SorobanClient.forClientOptions(
  options: ClientOptions(
    sourceAccountKeyPair: KeyPair.fromSecretSeed('SXXX...'),
    contractId: 'CCXYZ...',
    network: Network.TESTNET,
    rpcUrl: 'https://soroban-testnet.stellar.org:443',
    enableServerLogging: true, // Debug JSON-RPC requests/responses
  ),
);
```

### Method Not Found

Handle invalid method names or arguments.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

try {
  AssembledTransaction tx = await client.buildInvokeMethodTx(
    name: 'nonexistent',
    args: [],
  );
} catch (e) {
  print('Error: ${e.toString()}');
}
```

### Simulation Errors

Check simulation response for errors before submission.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

AssembledTransaction tx = await client.buildInvokeMethodTx(
  name: 'my_method',
  args: [],
);

if (tx.simulationResponse?.resultError != null) {
  print('Simulation failed: ${tx.simulationResponse!.resultError}');
  // Don't submit - fix the issue first
}
```

### Transaction Failures

Handle failures after submission.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

try {
  GetTransactionResponse response = await tx.signAndSend();

  if (response.status == GetTransactionResponse.STATUS_FAILED) {
    print('Transaction failed: ${response.resultXdr}');
  } else if (response.status == GetTransactionResponse.STATUS_SUCCESS) {
    print('Success!');
  }
} catch (e) {
  print('Submission error: ${e.toString()}');
}
```

### Auto-Restore Expired State

Automatically restore expired contract state before invocation.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// If contract state has expired, restore it automatically
XdrSCVal result = await client.invokeMethod(
  name: 'my_method',
  args: [],
  methodOptions: MethodOptions(restore: true),
);
```

## Contract Bindings

Generate type-safe Dart classes from contract specifications. This provides IDE autocompletion and compile-time type checking.

### Generate Bindings

Use [stellar-contract-bindings](https://github.com/lightsail-network/stellar-contract-bindings) to generate Dart classes:

```bash
pip install stellar-contract-bindings

stellar-contract-bindings dart \
  --contract-id YOUR_CONTRACT_ID \
  --rpc-url https://soroban-testnet.stellar.org \
  --output ./generated \
  --class-name TokenClient
```

Or use the [web interface](https://stellar-contract-bindings.fly.dev/).

### Use Generated Client

The generated client provides type-safe method calls with native Dart types.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
// import your generated bindings

TokenClient client = await TokenClient.forContractId(
  sourceAccountKeyPair: KeyPair.fromSecretSeed('SXXX...'),
  contractId: 'CTOKEN...',
  network: Network.TESTNET,
  rpcUrl: 'https://soroban-testnet.stellar.org:443',
);

// Type-safe calls with native Dart types
BigInt balance = await client.balance(id: Address.forAccountId('GABC...'));
await client.transfer(
  from: Address.forAccountId('GFROM...'),
  to: Address.forAccountId('GTO...'),
  amount: BigInt.from(1000),
);
```

## Low-Level Operations

Manual operations for custom workflows requiring full control over the transaction process.

### Upload WASM

Upload contract bytecode to the network. Returns a WASM hash for deployment.

```dart
import 'dart:io';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

KeyPair keyPair = KeyPair.fromSecretSeed('SXXX...');
SorobanServer server = SorobanServer('https://soroban-testnet.stellar.org:443');

// Build upload operation
InvokeHostFunctionOperation uploadOp = InvokeHostFuncOpBuilder(
  UploadContractWasmHostFunction(File('contract.wasm').readAsBytesSync()),
).build();

// Build and simulate transaction
Account? account = await server.getAccount(keyPair.accountId);
Transaction tx = TransactionBuilder(account!).addOperation(uploadOp).build();

SimulateTransactionResponse sim = await server.simulateTransaction(
  SimulateTransactionRequest(tx),
);
tx.sorobanTransactionData = sim.transactionData;
tx.addResourceFee(sim.minResourceFee!);
tx.sign(keyPair, Network.TESTNET);

// Submit
SendTransactionResponse sendResponse = await server.sendTransaction(tx);

// Poll for result
GetTransactionResponse txResponse;
do {
  await Future.delayed(Duration(seconds: 3));
  txResponse = await server.getTransaction(sendResponse.hash!);
} while (txResponse.status == GetTransactionResponse.STATUS_NOT_FOUND);

if (txResponse.status == GetTransactionResponse.STATUS_SUCCESS) {
  String? wasmHash = txResponse.getWasmId();
}
```

### Create Contract Instance

Deploy a contract instance from an uploaded WASM hash.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

InvokeHostFunctionOperation createOp = InvokeHostFuncOpBuilder(
  CreateContractHostFunction(
    Address.forAccountId(keyPair.accountId),
    wasmHash,
  ),
).build();

// Build, simulate, set auth, sign, and send
Account? account = await server.getAccount(keyPair.accountId);
Transaction tx = TransactionBuilder(account!).addOperation(createOp).build();
SimulateTransactionResponse sim = await server.simulateTransaction(
  SimulateTransactionRequest(tx),
);

tx.sorobanTransactionData = sim.transactionData;
tx.setSorobanAuth(sim.sorobanAuth);
tx.addResourceFee(sim.minResourceFee!);
tx.sign(keyPair, Network.TESTNET);

SendTransactionResponse sendResponse = await server.sendTransaction(tx);
```

### Create Contract with Constructor (Protocol 22+)

Deploy contracts that have constructors.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

InvokeHostFunctionOperation createOp = InvokeHostFuncOpBuilder(
  CreateContractWithConstructorHostFunction(
    Address.forAccountId(keyPair.accountId),
    wasmHash,
    [XdrSCVal.forSymbol('MyToken'), XdrSCVal.forU32(8)], // Constructor args
  ),
).build();

// Build, simulate, sign, and send (same pattern)
```

### Invoke Contract (Low-Level)

Invoke a contract method without using SorobanClient.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

InvokeHostFunctionOperation invokeOp = InvokeHostFuncOpBuilder(
  InvokeContractHostFunction(
    contractId,
    'hello',
    arguments: [XdrSCVal.forSymbol('World')],
  ),
).build();

// Build transaction
Account? account = await server.getAccount(keyPair.accountId);
Transaction tx = TransactionBuilder(account!).addOperation(invokeOp).build();

// Simulate to get resource requirements
SimulateTransactionResponse sim = await server.simulateTransaction(
  SimulateTransactionRequest(tx),
);
tx.sorobanTransactionData = sim.transactionData;
tx.addResourceFee(sim.minResourceFee!);
tx.sign(keyPair, Network.TESTNET);

// Submit and poll for result
SendTransactionResponse sendResponse = await server.sendTransaction(tx);
// Poll getTransaction until success, then get result:
// XdrSCVal? result = txResponse.getResultValue();
```

### Deploy Stellar Asset Contract (SAC)

Wrap a classic Stellar asset as a Soroban token contract. The protocol requires a `FROM_ASSET` contract ID preimage, so SAC deployment uses `DeploySACWithAssetHostFunction` with the asset to wrap.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

Asset asset = Asset.createNonNativeAsset('USDC', 'GISSUER...');

InvokeHostFunctionOperation sacOp = InvokeHostFuncOpBuilder(
  DeploySACWithAssetHostFunction(asset),
).build();

// Build, simulate, sign, and send
```

### Direct Authorization Signing

For advanced auth workflows, sign authorization entries directly.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Get auth entries from simulation
List<SorobanAuthorizationEntry>? auth = simResponse.sorobanAuth;
GetLatestLedgerResponse latestLedger = await server.getLatestLedger();

if (auth != null) {
  for (SorobanAuthorizationEntry entry in auth) {
    // Set signature expiration (~50 seconds at 5s/ledger)
    entry.credentials.addressCredentials?.signatureExpirationLedger =
        latestLedger.sequence! + 10;

    // Sign the entry
    entry.sign(signerKeyPair, Network.TESTNET);
  }
}

// Set signed auth on transaction
tx.setSorobanAuth(auth);
```

> **Tip**: Contract IDs must be C-prefixed strkey format.

## Contract Parser

Parse contract bytecode to access specifications, metadata, and environment information without deploying.

### Parse from Bytecode

Parse a local WASM file directly.

```dart
import 'dart:io';
import 'dart:typed_data';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

Uint8List bytecode = File('contract.wasm').readAsBytesSync();
SorobanContractInfo contractInfo = SorobanContractParser.parseContractByteCode(bytecode);

// Contract spec (functions, structs, unions)
for (XdrSCSpecEntry entry in contractInfo.specEntries) {
  print(entry.discriminant.value);
}

// Contract meta (arbitrary metadata as key-value pairs)
Map<String, String> meta = contractInfo.metaEntries;
```

### Parse from Network

Load and parse contract info from a deployed contract.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SorobanServer server = SorobanServer('https://soroban-testnet.stellar.org:443');

// By contract ID
SorobanContractInfo? contractInfo = await server.loadContractInfoForContractId('CCXYZ...');

// By WASM ID
SorobanContractInfo? contractInfo2 = await server.loadContractInfoForWasmId(wasmId);

if (contractInfo != null) {
  // Use ContractSpec for type conversions
  ContractSpec spec = ContractSpec(contractInfo.specEntries);
  List<XdrSCSpecFunctionV0> functions = spec.funcs();

  for (XdrSCSpecFunctionV0 func in functions) {
    print('Function: ${func.name}');
  }
}
```

## Further Reading

- [soroban_client_test.dart](https://github.com/Soneso/stellar_flutter_sdk/blob/master/test/integration/soroban_client_test.dart) -- High-level API tests
- [Soroban Docs](https://developers.stellar.org/docs/smart-contracts) -- Protocol details
- [Soroban Examples](https://github.com/stellar/soroban-examples) -- Official example contracts
- [RPC API Reference](https://developers.stellar.org/docs/data/rpc/api-reference) -- Soroban RPC methods
- [SEP Protocols](sep/README.md) -- Stellar Ecosystem Proposals

---

**Navigation:** [← SDK Usage](sdk-usage.md) | [SEP Protocols →](sep/README.md)
