# Soroban Smart Contracts Reference

All code assumes the standard SDK import:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
```

## High-Level: SorobanClient

`SorobanClient` handles simulation, signing, and submission automatically. Use this for most contract interactions.

### Install WASM Code

```dart
String wasmId = await SorobanClient.install(
  installRequest: InstallRequest(
    wasmBytes: wasmBytes,
    sourceAccountKeyPair: keyPair,
    network: Network.TESTNET,
    rpcUrl: 'https://soroban-testnet.stellar.org:443',
  ),
);
print('WASM hash: $wasmId');
```

### Deploy Contract Instance

```dart
SorobanClient client = await SorobanClient.deploy(
  deployRequest: DeployRequest(
    sourceAccountKeyPair: keyPair,
    network: Network.TESTNET,
    rpcUrl: 'https://soroban-testnet.stellar.org:443',
    wasmHash: wasmId,
  ),
);
print('Contract ID: ${client.getContractId()}');
```

### Deploy with Constructor Arguments

**Always match the exact type from contract introspection** -- do not guess based on convention:

```dart
// WRONG: using forSymbol because "token names are symbols" -- crashes with UnreachableCodeReached
// XdrSCVal.forSymbol('MyToken')  // WRONG if spec says String (type 16)
// CORRECT: spec says String -> use forString; spec says Symbol -> use forSymbol

SorobanClient client = await SorobanClient.deploy(
  deployRequest: DeployRequest(
    sourceAccountKeyPair: keyPair,
    network: Network.TESTNET,
    rpcUrl: 'https://soroban-testnet.stellar.org:443',
    wasmHash: wasmId,
    constructorArgs: [
      XdrSCVal.forString('MyToken'),  // name: String in spec
      XdrSCVal.forU32(8),             // decimals: u32 in spec
    ],
  ),
);
```

**Preferred: use `funcArgsToXdrSCValues` when you have the contract spec.** It auto-converts native Dart values to the correct `XdrSCVal` types -- no manual type mapping needed:

```dart
// Load spec from installed WASM
SorobanServer server = SorobanServer('https://soroban-testnet.stellar.org:443');
SorobanContractInfo? info = await server.loadContractInfoForWasmId(wasmId);
ContractSpec spec = ContractSpec(info!.specEntries);

// Auto-convert named args based on __constructor spec types
List<XdrSCVal> constructorArgs = spec.funcArgsToXdrSCValues('__constructor', {
  'admin': keyPair.accountId,   // String -> Address (automatic)
  'decimal': 7,                  // int -> U32 (automatic)
  'name': 'MyToken',            // String -> String (automatic)
  'symbol': 'MTK',              // String -> Symbol (automatic)
});

SorobanClient client = await SorobanClient.deploy(
  deployRequest: DeployRequest(
    sourceAccountKeyPair: keyPair,
    network: Network.TESTNET,
    rpcUrl: 'https://soroban-testnet.stellar.org:443',
    wasmHash: wasmId,
    constructorArgs: constructorArgs,
  ),
);
```

### Invoke Contract Methods

```dart
SorobanClient client = await SorobanClient.forClientOptions(
  options: ClientOptions(
    sourceAccountKeyPair: keyPair,
    contractId: 'CABC...',
    network: Network.TESTNET,
    rpcUrl: 'https://soroban-testnet.stellar.org:443',
  ),
);

// Read call -- auto-detected, simulation only, no signing needed
XdrSCVal balance = await client.invokeMethod(
  name: 'balance',
  args: [XdrSCVal.forAccountAddress(keyPair.accountId)],
);

// Write call -- auto-detected, simulates + signs + sends
XdrSCVal result = await client.invokeMethod(
  name: 'transfer',
  args: [
    XdrSCVal.forAccountAddress(keyPair.accountId),
    XdrSCVal.forAccountAddress('GDEST...'),
    XdrSCVal.forI128Parts(BigInt.zero, BigInt.from(1000000)),
  ],
);

// With custom options (higher fee, shorter timeout)
XdrSCVal result2 = await client.invokeMethod(
  name: 'expensive_op',
  args: [XdrSCVal.forSymbol('data')],
  methodOptions: MethodOptions(fee: 10000, timeoutInSeconds: 60),
);

// Discover available methods
List<String> methods = client.getMethodNames(); // ['transfer', 'balance', ...]
```

**Preferred: use `funcArgsToXdrSCValues` for type-safe invocation:**

```dart
// SorobanClient already has the spec loaded
ContractSpec spec = client.getContractSpec();

// Read call with auto-converted args
List<XdrSCVal> args = spec.funcArgsToXdrSCValues('balance', {
  'id': keyPair.accountId,  // String -> Address (automatic)
});
XdrSCVal balance = await client.invokeMethod(name: 'balance', args: args);

// Write call with auto-converted args
List<XdrSCVal> transferArgs = spec.funcArgsToXdrSCValues('transfer', {
  'from': keyPair.accountId,   // String -> Address
  'to': 'GDEST...',            // String -> Address
  'amount': 1000,              // int -> I128
});
XdrSCVal result = await client.invokeMethod(name: 'transfer', args: transferArgs);
```

### Multi-Auth Contract Invocation

When a contract call requires authorization from multiple parties (e.g., a swap), use `signAuthEntries` on `AssembledTransaction`:

```dart
AssembledTransaction swapTx = await client.buildInvokeMethodTx(
  name: 'swap',
  args: [
    XdrSCVal.forAccountAddress(aliceKeyPair.accountId),
    XdrSCVal.forAccountAddress(bobKeyPair.accountId),
    XdrSCVal.forContractAddress(tokenAContractId),
    XdrSCVal.forContractAddress(tokenBContractId),
    XdrSCVal.forI128Parts(BigInt.zero, BigInt.from(100)),
    XdrSCVal.forI128Parts(BigInt.zero, BigInt.from(50)),
  ],
);

// Check which non-invoker accounts must sign auth entries
List<String> needsSigning = swapTx.needsNonInvokerSigningBy();

// Sign Bob's auth entries
await swapTx.signAuthEntries(signerKeyPair: bobKeyPair);

// Sign and submit (Alice signs the transaction itself)
GetTransactionResponse response =
    await swapTx.signAndSend(sourceAccountKeyPair: aliceKeyPair);
```

---

## Low-Level: SorobanServer

Full control over simulation, signing, and submission. Use when you need custom transaction construction.

```dart
SorobanServer server = SorobanServer('https://soroban-testnet.stellar.org:443');
KeyPair sender = KeyPair.fromSecretSeed('SXXXXX...');
Account? account = await server.getAccount(sender.accountId);
if (account == null) throw Exception('Account not found');

// 1. Build the invocation operation
InvokeContractHostFunction invokeFn = InvokeContractHostFunction(
  contractId, 'transfer',
  arguments: [
    XdrSCVal.forAccountAddress(sender.accountId),
    XdrSCVal.forAccountAddress('GDEST...'),
    XdrSCVal.forI128Parts(BigInt.zero, BigInt.from(1000000)),
  ],
);
Transaction tx = TransactionBuilder(account)
    .addOperation(InvokeHostFuncOpBuilder(invokeFn).build())
    .build();

// 2. Simulate
SimulateTransactionResponse sim =
    await server.simulateTransaction(SimulateTransactionRequest(tx));
if (sim.resultError != null) {
  print('Simulation failed: ${sim.resultError}');
  return;
}

// 3. Apply simulation results, sign, send
tx.sorobanTransactionData = sim.transactionData;
tx.addResourceFee(sim.minResourceFee!);
tx.setSorobanAuth(sim.sorobanAuth);
tx.sign(sender, Network.TESTNET);
SendTransactionResponse sendResp = await server.sendTransaction(tx);

// 4. Poll for result
if (sendResp.status == SendTransactionResponse.STATUS_PENDING) {
  GetTransactionResponse txResp;
  do {
    await Future.delayed(Duration(seconds: 3));
    txResp = await server.getTransaction(sendResp.hash!);
  } while (txResp.status == GetTransactionResponse.STATUS_NOT_FOUND);

  if (txResp.status == GetTransactionResponse.STATUS_SUCCESS) {
    XdrSCVal? result = txResp.getResultValue();
    print('Result: $result');
  }
}
```

**Low-level deployment** follows the same simulate→sign→poll pattern:

```dart
// Upload WASM
UploadContractWasmHostFunction uploadFn = UploadContractWasmHostFunction(wasmBytes);
// Build tx with InvokeHostFuncOpBuilder(uploadFn).build(), simulate, sign, poll
// String? wasmId = txResponse.getWasmId();

// Create contract instance
CreateContractHostFunction createFn =
    CreateContractHostFunction(Address.forAccountId(deployer.accountId), wasmId);
// Build tx with InvokeHostFuncOpBuilder(createFn).build(), simulate, sign, poll
// String? contractId = txResponse.getCreatedContractId();

// With constructor args
CreateContractWithConstructorHostFunction createWithArgs =
    CreateContractWithConstructorHostFunction(
  Address.forAccountId(deployer.accountId), wasmId, constructorArgs,
);
```

---

## Argument Encoding with XdrSCVal

All contract arguments use `XdrSCVal` factory methods:

| Type | Factory Method | Example |
|------|---------------|---------|
| Boolean | `XdrSCVal.forBool(value)` | `XdrSCVal.forBool(true)` |
| Void | `XdrSCVal.forVoid()` | `XdrSCVal.forVoid()` |
| u32 | `XdrSCVal.forU32(value)` | `XdrSCVal.forU32(42)` |
| i32 | `XdrSCVal.forI32(value)` | `XdrSCVal.forI32(-1)` |
| u64 | `XdrSCVal.forU64(value)` | `XdrSCVal.forU64(BigInt.from(1000))` |
| i64 | `XdrSCVal.forI64(value)` | `XdrSCVal.forI64(BigInt.from(-500))` |
| u128 | `XdrSCVal.forU128Parts(hi, lo)` | `XdrSCVal.forU128Parts(BigInt.zero, BigInt.from(1000000))` |
| i128 | `XdrSCVal.forI128Parts(hi, lo)` | `XdrSCVal.forI128Parts(BigInt.zero, BigInt.from(500))` |
| u256 | `XdrSCVal.forU256Parts(hiHi, hiLo, loHi, loLo)` | Four `BigInt` parts |
| i256 | `XdrSCVal.forI256Parts(hiHi, hiLo, loHi, loLo)` | Four `BigInt` parts |
| Symbol | `XdrSCVal.forSymbol(str)` | `XdrSCVal.forSymbol('transfer')` |
| String | `XdrSCVal.forString(str)` | `XdrSCVal.forString('hello')` |
| Bytes | `XdrSCVal.forBytes(bytes)` | `XdrSCVal.forBytes(Uint8List(32))` |
| Address | `XdrSCVal.forAddress(addr)` | See below |
| Vec | `XdrSCVal.forVec(list)` | `XdrSCVal.forVec([val1, val2])` |
| Map | `XdrSCVal.forMap(entries)` | `XdrSCVal.forMap([entry1])` |

**Address convenience methods** (skip manual XdrSCAddress construction):

```dart
XdrSCVal accountAddr = XdrSCVal.forAccountAddress('GABC...');
XdrSCVal contractAddr = XdrSCVal.forContractAddress('CABC...');

// Or via XdrSCAddress
XdrSCAddress forAccount = XdrSCAddress.forAccountId('GABC...');
XdrSCAddress forContract = XdrSCAddress.forContractId('CABC...');
XdrSCVal addressVal = XdrSCVal.forAddress(forAccount);
```

---

## Reading Contract Return Values

Extract typed results from contract invocations. Numeric XDR wrappers must be unwrapped:

```dart
XdrSCVal? result = txResponse.getResultValue();

// Direct types (no unwrapping)
String? strVal = result?.str;       // String return
String? symVal = result?.sym;       // Symbol return
bool? boolVal = result?.b;          // Bool return

// Numeric wrappers -- MUST unwrap to get Dart value
int? u32Val = result?.u32?.uint32;       // u32 -> int
int? i32Val = result?.i32?.int32;        // i32 -> int
BigInt? u64Val = result?.u64?.uint64;    // u64 -> BigInt
BigInt? i64Val = result?.i64?.int64;     // i64 -> BigInt

// i128 extraction (common for token balances)
if (result?.i128 != null) {
  XdrInt128Parts parts = result!.i128!;
  BigInt hi = parts.hi.int64;    // XdrInt64 -> BigInt
  BigInt lo = parts.lo.uint64;   // XdrUint64 -> BigInt
  BigInt value = (hi << 64) + lo;
}

// Address extraction
if (result?.address != null) {
  String strKey = result!.address!.toStrKey();  // G... or C... format
}

// Map iteration
if (result?.map != null) {
  for (XdrSCMapEntry entry in result!.map!) {
    XdrSCVal key = entry.key;
    XdrSCVal val = entry.val;
  }
}

// Vec iteration
if (result?.vec != null) {
  for (XdrSCVal item in result!.vec!) {
    // each item is XdrSCVal
  }
}
```

**Common mistake:** `result.u32` returns `XdrUint32?`, not `int?`. Always unwrap: `result.u32?.uint32`.

---

## Reading Contract State

Read contract data directly from the ledger without invoking the contract:

```dart
XdrSCVal key = XdrSCVal.forSymbol('counter');
LedgerEntry? entry = await server.getContractData(
  contractId, key, XdrContractDataDurability.PERSISTENT,
);

if (entry != null) {
  XdrLedgerEntryData data = entry.ledgerEntryDataXdr;
  print('Live until ledger: ${entry.liveUntilLedgerSeq}');
}
```

For querying multiple entries at once, see [RPC Reference](./rpc.md) (`getLedgerEntries`).

---

## TTL Extension and Restore

### Extend Footprint TTL

Prevent contract data from being archived:

```dart
ExtendFootprintTTLOperation extendOp =
    ExtendFootprintTTLOperationBuilder(100000).build();

Account? account = await server.getAccount(keyPair.accountId);
if (account == null) throw Exception('Account not found');
Transaction tx = TransactionBuilder(account!)
    .addOperation(extendOp)
    .build();

// Simulate to get footprint and fees
SimulateTransactionResponse sim =
    await server.simulateTransaction(SimulateTransactionRequest(tx));
tx.sorobanTransactionData = sim.transactionData;
tx.addResourceFee(sim.minResourceFee!);
tx.sign(keyPair, Network.TESTNET);
await server.sendTransaction(tx);
```

### Restore Expired Data

When simulation returns a `restorePreamble`, entries must be restored before invoking:

```dart
SimulateTransactionResponse sim =
    await server.simulateTransaction(SimulateTransactionRequest(tx));

if (sim.restorePreamble != null) {
  Account? restoreAccount = await server.getAccount(keyPair.accountId);
  if (restoreAccount == null) throw Exception('Account not found');
  Transaction restoreTx = TransactionBuilder(restoreAccount!)
      .addOperation(RestoreFootprintOperationBuilder().build())
      .build();

  // Use restore preamble data
  restoreTx.sorobanTransactionData = sim.restorePreamble!.transactionData;
  restoreTx.addResourceFee(sim.restorePreamble!.minResourceFee);
  restoreTx.sign(keyPair, Network.TESTNET);
  SendTransactionResponse restoreResp = await server.sendTransaction(restoreTx);

  // Wait for restore to complete, then re-simulate and submit the original
  GetTransactionResponse restoreResult;
  do {
    await Future.delayed(Duration(seconds: 3));
    restoreResult = await server.getTransaction(restoreResp.hash!);
  } while (restoreResult.status == GetTransactionResponse.STATUS_NOT_FOUND);
}
```

---

## Deploy Stellar Asset Contract (SAC)

Wrap a classic Stellar asset for use in Soroban:

```dart
// For a specific asset
Asset usdcAsset = Asset.createNonNativeAsset('USDC', issuerAccountId);
DeploySACWithAssetHostFunction sacFn = DeploySACWithAssetHostFunction(usdcAsset);
InvokeHostFunctionOperation sacOp = InvokeHostFuncOpBuilder(sacFn).build();

// For native XLM
DeploySACWithAssetHostFunction xlmSacFn =
    DeploySACWithAssetHostFunction(AssetTypeNative());
```

---

## Contract Introspection

Parse a contract's spec to discover its functions, types, and events programmatically.

### Loading Contract Info

```dart
import 'dart:io';
import 'dart:typed_data'; // Required for Uint8List

// From local WASM bytecode (offline)
Uint8List wasmBytes = File('contract.wasm').readAsBytesSync();
SorobanContractInfo contractInfo =
    SorobanContractParser.parseContractByteCode(wasmBytes);

// From network (by WASM hash or contract ID)
SorobanServer server = SorobanServer('https://soroban-testnet.stellar.org:443');
SorobanContractInfo? info = await server.loadContractInfoForWasmId(wasmId);
SorobanContractInfo? info = await server.loadContractInfoForContractId(contractId);
```

### SorobanContractInfo Properties

| Property | Type | Description |
|----------|------|-------------|
| `specEntries` | `List<XdrSCSpecEntry>` | All spec entries (raw) |
| `funcs` | `List<XdrSCSpecFunctionV0>` | Contract functions |
| `udtStructs` | `List<XdrSCSpecUDTStructV0>` | Struct definitions |
| `udtUnions` | `List<XdrSCSpecUDTUnionV0>` | Union definitions |
| `udtEnums` | `List<XdrSCSpecUDTEnumV0>` | Enum definitions |
| `udtErrorEnums` | `List<XdrSCSpecUDTErrorEnumV0>` | Error enum definitions |
| `events` | `List<XdrSCSpecEventV0>` | Event definitions |
| `metaEntries` | `Map<String, String>` | Contract metadata |

### Listing Functions and Parameters

```dart
for (XdrSCSpecFunctionV0 func in contractInfo.funcs) {
  print('Function: ${func.name}');
  for (XdrSCSpecFunctionInputV0 input in func.inputs) {
    // WRONG: input.type.discriminant.name -- XdrSCSpecType has NO .name getter
    // CORRECT: use .value for the int constant, or compare to known constants
    print('  param: ${input.name} (type: ${input.type.discriminant.value})');
  }
  for (XdrSCSpecTypeDef output in func.outputs) {
    print('  returns type: ${output.discriminant.value}');
  }
}
```

`XdrSCSpecType` is NOT a Dart enum -- it has no `.name` getter. Use `.value` to get the
integer constant (e.g., 4 = u32, 11 = i128, 16 = String, 17 = Symbol, 19 = Address).
See the mapping table below to convert these to human-readable names or `XdrSCVal` factories.

### Listing Struct Types

```dart
for (XdrSCSpecUDTStructV0 struct in contractInfo.udtStructs) {
  print('Struct: ${struct.name}');
  for (XdrSCSpecUDTStructFieldV0 field in struct.fields) {
    print('  ${field.name}: type ${field.type.discriminant.value}');
  }
}
```

### Listing Enum Types

```dart
for (XdrSCSpecUDTEnumV0 enumType in contractInfo.udtEnums) {
  print('Enum: ${enumType.name}');
  for (XdrSCSpecUDTEnumCaseV0 case_ in enumType.cases) {
    print('  ${case_.name} = ${case_.value.uint32}');
  }
}
```

### Listing Union Types

`XdrSCSpecUDTUnionCaseV0` is a **discriminated union** -- access the name through the specific case variant:

```dart
for (XdrSCSpecUDTUnionV0 union in contractInfo.udtUnions) {
  print('Union: ${union.name}');
  for (XdrSCSpecUDTUnionCaseV0 case_ in union.cases) {
    // WRONG: case_.name -- XdrSCSpecUDTUnionCaseV0 has no .name getter
    // CORRECT: check discriminant, then access voidCase or tupleCase
    switch (case_.discriminant) {
      case XdrSCSpecUDTUnionCaseV0Kind.SC_SPEC_UDT_UNION_CASE_VOID_V0:
        print('  ${case_.voidCase!.name} (void)');
        break;
      case XdrSCSpecUDTUnionCaseV0Kind.SC_SPEC_UDT_UNION_CASE_TUPLE_V0:
        print('  ${case_.tupleCase!.name} (tuple)');
        break;
    }
  }
}
```

### Listing Error Enum Types

```dart
for (XdrSCSpecUDTErrorEnumV0 errorEnum in contractInfo.udtErrorEnums) {
  print('Error Enum: ${errorEnum.name}');
  for (XdrSCSpecUDTErrorEnumCaseV0 case_ in errorEnum.cases) {
    print('  ${case_.name} = ${case_.value.uint32}');
  }
}
```

### Listing Events

```dart
for (XdrSCSpecEventV0 event in contractInfo.events) {
  print('Event: ${event.name}');
  // WRONG: event.topics, event.body -- XdrSCSpecEventV0 has NO topics/body getters
  // CORRECT: use event.params (List<XdrSCSpecEventParamV0>)
  for (XdrSCSpecEventParamV0 param in event.params) {
    print('  ${param.name}: type ${param.type.discriminant.value}');
  }
}
```

### XdrSCSpecEntry Discriminants

| Kind | Accessor | Type |
|------|----------|------|
| `XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0` | `.functionV0` | `XdrSCSpecFunctionV0?` |
| `XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_STRUCT_V0` | `.udtStructV0` | `XdrSCSpecUDTStructV0?` |
| `XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_UNION_V0` | `.udtUnionV0` | `XdrSCSpecUDTUnionV0?` |
| `XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_ENUM_V0` | `.udtEnumV0` | `XdrSCSpecUDTEnumV0?` |
| `XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_ERROR_ENUM_V0` | `.udtErrorEnumV0` | `XdrSCSpecUDTErrorEnumV0?` |
| `XdrSCSpecEntryKind.SC_SPEC_ENTRY_EVENT_V0` | `.eventV0` | `XdrSCSpecEventV0?` |

### XdrSCSpecType Constants to XdrSCVal Factories

Use this mapping to convert discovered parameter types to the **exact** `XdrSCVal` factory.
**Always use the type from introspection** -- do not override based on naming conventions:

<!-- WRONG: overriding discovered type based on convention -->
<!-- Spec says name: String (type 16) but "token names are usually Symbol" -->
<!-- XdrSCVal.forSymbol('TEST') // WRONG — crashes: UnreachableCodeReached -->
<!-- CORRECT: always use the exact type from introspection -->
<!-- XdrSCVal.forString('TEST') // CORRECT — spec says String, use forString -->

| Constant | Value | Soroban Type | XdrSCVal Factory |
|----------|-------|-------------|-----------------|
| `SC_SPEC_TYPE_BOOL` | 1 | bool | `XdrSCVal.forBool(val)` |
| `SC_SPEC_TYPE_VOID` | 2 | void | (no value needed) |
| `SC_SPEC_TYPE_U32` | 4 | u32 | `XdrSCVal.forU32(val)` |
| `SC_SPEC_TYPE_I32` | 5 | i32 | `XdrSCVal.forI32(val)` |
| `SC_SPEC_TYPE_U64` | 6 | u64 | `XdrSCVal.forU64(val)` |
| `SC_SPEC_TYPE_I64` | 7 | i64 | `XdrSCVal.forI64(val)` |
| `SC_SPEC_TYPE_U128` | 10 | u128 | `XdrSCVal.forU128Parts(hi, lo)` |
| `SC_SPEC_TYPE_I128` | 11 | i128 | `XdrSCVal.forI128Parts(hi, lo)` |
| `SC_SPEC_TYPE_BYTES` | 14 | Bytes | `XdrSCVal.forBytes(bytes)` |
| `SC_SPEC_TYPE_STRING` | 16 | String | `XdrSCVal.forString(val)` |
| `SC_SPEC_TYPE_SYMBOL` | 17 | Symbol | `XdrSCVal.forSymbol(val)` |
| `SC_SPEC_TYPE_ADDRESS` | 19 | Address | `XdrSCVal.forAddress(addr)` |
| `SC_SPEC_TYPE_VEC` | 1002 | Vec | `XdrSCVal.forVec(list)` -- check `.vec` for element type |
| `SC_SPEC_TYPE_MAP` | 1004 | Map | `XdrSCVal.forMap(entries)` -- check `.map` for key/value types |
| `SC_SPEC_TYPE_UDT` | 2000 | User-defined | check `.udt?.name` for the type name |
