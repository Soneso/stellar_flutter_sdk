# Soroban Smart Contracts Reference

All code assumes the standard SDK import:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
```

- [High-Level: SorobanClient](#high-level-sorobanclient)
- [Low-Level: SorobanServer](#low-level-sorobanserver)
- [Argument Encoding with XdrSCVal](#argument-encoding-with-xdrscval)
- [Reading Contract Return Values](#reading-contract-return-values)
- [Reading Contract State](#reading-contract-state)
- [TTL Extension and Restore](#ttl-extension-and-restore)
- [Deploy Stellar Asset Contract (SAC)](#deploy-stellar-asset-contract-sac)
- [Contract Introspection](#contract-introspection)

## High-Level: SorobanClient

`SorobanClient` handles simulation, signing, and submission automatically. Use this for most contract interactions.

### Install WASM Code

```dart
import 'dart:typed_data';

// From your app: keyPair (KeyPair), wasmBytes (Uint8List)
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
// From your app: keyPair (KeyPair)
// From the section Install WASM Code: wasmId (String)
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
// From your app: keyPair (KeyPair)
// From the section Install WASM Code: wasmId (String)
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

`Address` parameters accept G/C strkeys, 64-character hex contract IDs, and corresponding `Address` objects; `MuxedAddress` also accepts M/W strkeys and objects.

**Preferred: use `funcArgsToXdrSCValues` when you have the contract spec.** It auto-converts native Dart values to the correct `XdrSCVal` types -- no manual type mapping needed:

```dart
// From your app: keyPair (KeyPair)
// From the section Install WASM Code: wasmId (String)
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

### Deploy from an External Reference (Protocol 28)

A CAP-85 external reference names an owner contract and a tag; the owner's persistent
entry under that tag holds the wasm hash the new instance runs. There is no install
step. `SorobanClient.deployFromExternalRef` resolves the reference before the
transaction is built (an unresolvable reference throws naming the owner and the tag),
loads the spec from the resolved wasm, and returns a ready client:

```dart
// keyPair: the account that signs and pays for the deployment
Future<SorobanClient> deployFromReference(KeyPair keyPair) async {
  return SorobanClient.deployFromExternalRef(
    deployRequest: DeployFromExternalRefRequest.forTagString(
      sourceAccountKeyPair: keyPair,
      network: Network.TESTNET,
      rpcUrl: 'https://soroban-testnet.stellar.org:443',
      // The owner contract holding the tag entry
      executableOwner: Address.forContractId(
          'CCTHWH6DJQY6N2HSPVOFNKFT3FBM4MFBVEXXOAQ6UOS7BTML4JDRSXQP'),
      tag: 'token-v1', // matched byte for byte
      // constructorArgs and salt work as in DeployRequest
    ),
  );
}
```

`DeployFromExternalRefRequest.tag` is `Uint8List` (an executable tag carries arbitrary
bytes); `forTagString` encodes a text tag as UTF-8 exactly once, and the default
constructor takes the raw bytes. The same bytes resolve the owner's entry and build the
create operation.

`deployFromExternalRef` builds the `CREATE_CONTRACT_V2` host function form (empty
constructor-argument vector when no args are given), as `deploy` does.

Without SorobanClient, build the create operation directly with
`CreateContractFromExternalRefHostFunction.forTagString(Address address,
Address executableOwner, String tag, {XdrUint256? salt})` in an
`InvokeHostFuncOpBuilder`;
`CreateContractFromExternalRefWithConstructorHostFunction` adds the constructor
argument list after the tag. Both builders throw `ArgumentError` for an
`executableOwner` that is not a contract address (constructor and setter).
`HostFunction.fromXdr` returns these classes for external-ref create operations
in parsed envelopes and applies the same owner check.

`Address.deriveContractId({deployer, salt, network})` returns the contract id ("C...")
a deployment creates. The id derives from deployer, salt and network only (the
executable does not enter it), so the address is known before deploying. The salt is
32 raw bytes (`Uint8List`), not hex; a wrong length throws `ArgumentError`.

### Invoke Contract Methods

```dart
// From your app: contractId (String), destinationAccountId (String), keyPair (KeyPair)
SorobanClient client = await SorobanClient.forClientOptions(
  options: ClientOptions(
    sourceAccountKeyPair: keyPair,
    contractId: contractId, // the C... id of the contract
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
    XdrSCVal.forAccountAddress(destinationAccountId), // the receiving G... account
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

Polling counts status-request time toward `timeoutInSeconds` and stops when a terminal transaction status arrives. If the transaction is unresolved at the deadline, one final status request can take up to three seconds. Failed status requests are retried. A timeout throws `Exception`, naming the last status-request error if any.

**Preferred: use `funcArgsToXdrSCValues` for type-safe invocation:**

```dart
// From the section Deploy Contract Instance: client (SorobanClient)
// From your app: keyPair (KeyPair)
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
  // String -> MuxedAddress (G, M, C or W)
  'to': 'GBMYYYOUQTENJ7DBSKCVRIOHINC2JJZVQX7B4WOQL4KNLRZEVK6TRNG7',
  'amount': 1000,              // int -> I128
});
XdrSCVal result = await client.invokeMethod(name: 'transfer', args: transferArgs);
```

The SAC `transfer` destination accepts `M...` and `W...` addresses through its `MuxedAddress` parameter.

### Multi-Auth Contract Invocation

When a contract call requires authorization from multiple parties (e.g., a swap), use `signAuthEntries` on `AssembledTransaction`:

```dart
// From your app: aliceKeyPair (KeyPair), bobKeyPair (KeyPair), client (SorobanClient, a client of the atomic swap contract), tokenAContractId (String), tokenBContractId (String)
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

The first signer chooses the expiration, defaulting to the latest ledger plus 100; subsequent signers preserve it, and conflicting explicit values throw.

### Protocol 27 Credentials (CAP-71)

`SorobanCredentials` arms: source-account, legacy `ADDRESS` (valid all protocols), `ADDRESS_V2` (the default arm), `ADDRESS_WITH_DELEGATES` (V2 and delegates are protocol 27+; emitting below p27 invalidates the tx). `forAddress`/`forAddressCredentials` build `ADDRESS_V2`; `forAddressLegacy`/`forAddressCredentialsLegacy` build legacy `ADDRESS`. `credentials.innerAddressCredentials` returns the inner creds for any address arm (null for source-account); `credentials.arm` is the discriminant.

Simulation requests V2 entries by default (`useUpgradedAuth` is `true` on `MethodOptions` and `SimulateTransactionRequest`, always sent on the wire); pass `false` for legacy `ADDRESS` entries. RPCs without support silently return legacy `ADDRESS` either way. Detect by inspecting `arm`, never by error code.

`signAuthEntries` handles all arms and preserves the stored expiration once any node carries a signature. A conflicting explicit `validUntilLedgerSeq` throws `ArgumentError`. Void and empty vectors are unsigned placeholders; `SorobanAuthorizationEntry.carriesSignature` exposes that check. `needsNonInvokerSigningBy` lists every unsigned node, including the top level. `AssembledTransaction.sign` blocks on unsigned accounts (`G...`) at either level, regardless of delegate signatures. Contract addresses (`C...`) never block because their `__check_auth` decides authorization.

Credential addresses, `forAddress` targets, and delegate addresses must be `G...` or `C...`; muxed addresses (`M...`, `W...`) throw. Credential and target guards throw `Exception`; the delegate guard throws `ArgumentError`. Their messages are:

```text
Muxed account (M...) and muxed contract (W...) addresses are not valid Soroban auth credential addresses: WA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAAAAAAAAAWWC; use the underlying G... or C... address instead
Muxed account (M...) and muxed contract (W...) addresses are not valid Soroban auth targets; use the underlying G... or C... address instead
Muxed account (M...) and muxed contract (W...) addresses are not valid Soroban delegate addresses: WA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAAAAAAAAAWWC
```

A `W...` address throws `ArgumentError` before any request as the contract to invoke or load, a contract data owner or part of a contract data key. Pass its base `C...` address.

```dart
// From your app: delegateKeyPair (KeyPair), sourceEntry (SorobanAuthorizationEntry), topLevelKeyPair (KeyPair)
// From the section Deploy with Constructor Arguments: server (SorobanServer)
// Build a WITH_DELEGATES entry from an ADDRESS/ADDRESS_V2 entry; the builder
// sorts delegate arrays by XDR-encoded address bytes and rejects duplicates.
int exp = (await server.getLatestLedger()).sequence! + 100;
SorobanAuthorizationEntry delegated = SorobanAuthorizationEntry.withDelegates(
  sourceEntry, // ADDRESS or ADDRESS_V2, from simulation
  [SorobanDelegateDescriptor(delegateKeyPair.accountId)], // nestedDelegates / signature optional
  exp,
);
delegated.sign(topLevelKeyPair, Network.TESTNET); // required for the top-level account
delegated.sign(delegateKeyPair, Network.TESTNET,
    forAddress: delegateKeyPair.accountId); // routes into matching node depth-first
```

Delegates share one payload bound to the top-level address; they carry no nonce/expiration. Multiple G-address signatures on one node must be added in ascending public-key order (the SDK appends in call order, no sorting). After `tx.setSorobanAuth([delegated])`, re-simulate in enforcing mode (`SimulateTransactionRequest(tx, authMode: 'enforce')`) and apply the returned resources (`sorobanTransactionData`, `addResourceFee`) before submitting: the recording simulation does not run `__check_auth`, so for a custom (contract) account it omits the footprint its authorization reads (and understates the delegate fee). `XdrSorobanCredentialsType` and `XdrEnvelopeType` are classes of constants; give every switch on them a `default` arm.

---

## Low-Level: SorobanServer

Full control over simulation, signing, and submission. Use when you need custom transaction construction.

```dart
// From your app: contractId (String), destinationAccountId (String), senderSecretSeed (String)
SorobanServer server = SorobanServer('https://soroban-testnet.stellar.org:443');
KeyPair sender = KeyPair.fromSecretSeed(senderSecretSeed); // S... seed of the funded sender, from secure storage
Account? account = await server.getAccount(sender.accountId);
if (account == null) throw Exception('Account not found');

// 1. Build the invocation operation
InvokeContractHostFunction invokeFn = InvokeContractHostFunction(
  contractId, 'transfer',
  arguments: [
    XdrSCVal.forAccountAddress(sender.accountId),
    XdrSCVal.forAccountAddress(destinationAccountId), // the receiving G... account
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

// 4. ERROR means rejected before inclusion: nothing to poll
// (the four send statuses: RPC Reference, sendTransaction)
if (sendResp.status == SendTransactionResponse.STATUS_ERROR) {
  throw Exception('Rejected: ${sendResp.errorResultXdr}');
}

// 5. Poll for the result: pollTransaction retries while NOT_FOUND, at most 30 times
// one second apart; the answer can still be NOT_FOUND after the limit
GetTransactionResponse txResp = await server.pollTransaction(sendResp.hash!);
if (txResp.status == GetTransactionResponse.STATUS_SUCCESS) {
  XdrSCVal? result = txResp.getResultValue();
  print('Result: $result');
} else if (txResp.status == GetTransactionResponse.STATUS_FAILED) {
  print('Failed: ${txResp.resultXdr}');
} else {
  // NOT_FOUND after the limit: keep the hash and check again later
}
```

**Low-level deployment** follows the same simulate→sign→poll pattern:

```dart
import 'dart:typed_data';

// From the setup above: constructorArgs (List<XdrSCVal>), wasmId (String)
// From your app: deployer (KeyPair), wasmBytes (Uint8List)
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
XdrSCVal accountAddr = XdrSCVal.forAccountAddress('GAB2CB576PHBBPQ5ODORRZ2LYCMWPZGWGCN2KDK7DXOIMZASKUY3QZ6Q');
XdrSCVal contractAddr = XdrSCVal.forContractAddress('CA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUWDA');

XdrSCVal muxedContractAddr = XdrSCVal.forMuxedContractAddress(
    'WA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAAAAAAAAAWWC');

// Or via XdrSCAddress
XdrSCAddress forAccount = XdrSCAddress.forAccountId('GAB2CB576PHBBPQ5ODORRZ2LYCMWPZGWGCN2KDK7DXOIMZASKUY3QZ6Q');
XdrSCAddress forContract = XdrSCAddress.forContractId('CA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUWDA');
XdrSCVal addressVal = XdrSCVal.forAddress(forAccount);
```

---

## Reading Contract Return Values

Extract typed results from contract invocations. Numeric XDR wrappers must be unwrapped:

```dart
// From your app: txResponse (GetTransactionResponse)
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

### Converting results to native Dart values

`dynamic toNative()` on `XdrSCVal` converts a value tree to native Dart values on a
best-effort basis, as an alternative to the manual unwrapping above. It never
throws: an arm with no faithful native representation converts to the `XdrSCVal`
itself, so the caller can detect that with `is XdrSCVal`.

| XDR type | Native result |
|---|---|
| Bool | `bool` |
| Void | `null` |
| U32, I32 | `int` |
| U64, I64, Timepoint, Duration | `BigInt` |
| U128, I128, U256, I256 | `BigInt` |
| Bytes | `Uint8List` (the stored instance, not a copy) |
| String, Symbol | `String` |
| Vec | `List<dynamic>`, elements converted recursively |
| Map | `Map<dynamic, dynamic>` (see below), or the `XdrSCVal` itself |
| Address | `Address` |
| Error, Contract Instance, Ledger Key Contract Instance, Ledger Key Nonce, Executable Tag, or any arm not listed above | the `XdrSCVal` itself |

Every integer 64 bits or wider converts to `BigInt`, never `int`, so the value
stays exact on Flutter web, where a Dart `int` above 2^53 is a JavaScript double.

**Map key rules.** `Address`, `Uint8List`, and `XdrSCVal` have no value equality, so
map keys use a narrower conversion than values:

| Key XDR type | Dart map key |
|---|---|
| Symbol, String | `String` |
| U32, I32 | `int` |
| U64, I64, Timepoint, Duration, U128, I128, U256, I256 | `BigInt` |
| Bool | `bool` |
| Void | `null` |
| Bytes | lowercase hex `String` |
| Address | StrKey `String` (`G...`/`C...`/`M...`/`B...`/`L...`/`W...`) |
| anything else | none -- the whole map falls back to the `XdrSCVal` itself |

An address *value* converts to an `Address` object, but an address *key* becomes
its StrKey string; a bytes *value* stays a `Uint8List`, but a bytes *key* becomes
its hex string. `int` and `BigInt` are distinct Dart key types even for the same
number (`BigInt.from(5) == 5` is `false`), so a U32 key and a U64 key holding the
same value coexist as two entries. The whole map falls back to the `XdrSCVal`
itself when a key has no representation in the table above, or when two entries
convert to the same Dart key.

```dart
// Every 64-bit-and-wider integer is BigInt, at any width.
XdrSCVal u64Val = XdrSCVal.forU64(BigInt.parse('18446744073709551615'));
print(u64Val.toNative()); // 18446744073709551615 (BigInt)

XdrSCVal i128Val = XdrSCVal.forI128BigInt(
    BigInt.parse('-170141183460469231731687303715884105728'));
print(i128Val.toNative()); // -170141183460469231731687303715884105728 (BigInt)
```

```dart
// An int key and a BigInt key holding the same number are distinct entries.
XdrSCVal val = XdrSCVal.forMap([
  XdrSCMapEntry(XdrSCVal.forU32(5), XdrSCVal.forString('u32 five')),
  XdrSCMapEntry(
      XdrSCVal.forU64(BigInt.from(5)), XdrSCVal.forString('u64 five')),
]);
Map<dynamic, dynamic> native = val.toNative() as Map<dynamic, dynamic>;
print(native.length); // 2 -- the int key and the BigInt key never collide
for (dynamic key in native.keys) {
  print('${key is BigInt}: $key'); // false: 5, then true: 5
}
```

```dart
import 'dart:typed_data';

// A Bytes key becomes a lowercase hex String, not a Uint8List.
XdrSCVal val = XdrSCVal.forMap([
  XdrSCMapEntry(
      XdrSCVal.forBytes(Uint8List.fromList([1, 2])), XdrSCVal.forU32(1)),
]);
Map<dynamic, dynamic> native = val.toNative() as Map<dynamic, dynamic>;
print(native.keys.toList()); // [0102]
```

**Detecting a fallback:**

```dart
// A vec has no value equality, so it cannot serve as a map key: the whole
// map falls back to the XdrSCVal itself.
XdrSCVal val = XdrSCVal.forMap([
  XdrSCMapEntry(
      XdrSCVal.forVec([XdrSCVal.forU32(1)]), XdrSCVal.forU32(1)),
]);
dynamic native = val.toNative();

// WRONG: assumes toNative() always returns a Map -- throws a cast error
// once a map contains an unrepresentable or colliding key.
Map<dynamic, dynamic> wrong = native as Map<dynamic, dynamic>;

// CORRECT: check the fallback before treating the result as a Map.
if (native is XdrSCVal) {
  print('unsupported map, handle the XdrSCVal directly');
} else {
  Map<dynamic, dynamic> map = native as Map<dynamic, dynamic>;
  print(map);
}
```

**Narrowing a BigInt result:**

```dart
XdrSCVal u64Val = XdrSCVal.forU64(BigInt.parse('18446744073709551615'));
dynamic native = u64Val.toNative();

// WRONG: BigInt.toInt() truncates silently on web once the value exceeds
// 2^53 -- no exception, just a wrong number.
int wrong = (native as BigInt).toInt();

// CORRECT: keep it as BigInt, or convert to String for display.
BigInt correct = native as BigInt;
print(correct.toString()); // 18446744073709551615
```

**Looking up an address-keyed map:**

```dart
const g = 'GBBM6BKZPEHWYO3E3YKREDPQXMS4VK35YLNU7NFBRI26RAN7GI5POFBB';
XdrSCVal val = XdrSCVal.forMap([
  XdrSCMapEntry(XdrSCVal.forAccountAddress(g), XdrSCVal.forU32(1)),
]);
Map<dynamic, dynamic> native = val.toNative() as Map<dynamic, dynamic>;

// WRONG: the map key is the StrKey String, not an Address -- Address has
// no value equality, so this lookup misses even for the same address.
Address lookupKey = Address.forAccountId(g);
dynamic wrong = native[lookupKey]; // null

// CORRECT: look the entry up with the StrKey String the key actually is.
dynamic correct = native[g]; // 1
```

**Expecting an int key to match a BigInt key:**

```dart
XdrSCVal val = XdrSCVal.forMap([
  XdrSCMapEntry(XdrSCVal.forU32(5), XdrSCVal.forString('u32 five')),
  XdrSCMapEntry(
      XdrSCVal.forU64(BigInt.from(5)), XdrSCVal.forString('u64 five')),
]);
Map<dynamic, dynamic> native = val.toNative() as Map<dynamic, dynamic>;

// WRONG: looking up the u64 entry with a plain int -- misses because the
// map holds a BigInt key, and 5 (int) != BigInt.from(5).
dynamic wrong = native[5]; // 'u32 five', not the u64 entry

// CORRECT: use a BigInt key to reach a U64-or-wider entry.
dynamic correct = native[BigInt.from(5)]; // 'u64 five'
```

---

## Reading Contract State

Read contract data directly from the ledger without invoking the contract:

```dart
// From your app: contractId (String)
// From the section Deploy with Constructor Arguments: server (SorobanServer)
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
// From your app: contractId (String), keyPair (KeyPair)
// From the section Deploy with Constructor Arguments: server (SorobanServer)
// The entry to extend: the counter (PERSISTENT) read in Reading Contract State
XdrLedgerKey dataKey = XdrLedgerKey.forContractData(
  XdrSCAddress.forContractId(contractId),
  XdrSCVal.forSymbol('counter'),
  XdrContractDataDurability.PERSISTENT,
);
// The operation extends the read-only footprint the transaction declares
XdrLedgerFootprint footprint = XdrLedgerFootprint([dataKey], []);
XdrSorobanResources resources =
    XdrSorobanResources(footprint, XdrUint32(0), XdrUint32(0), XdrUint32(0));
XdrSorobanTransactionData transactionData = XdrSorobanTransactionData(
    XdrSorobanTransactionDataExt(0), resources, XdrInt64(BigInt.zero));

ExtendFootprintTTLOperation extendOp =
    ExtendFootprintTTLOperationBuilder(100000).build();

Account? account = await server.getAccount(keyPair.accountId);
if (account == null) throw Exception('Account not found');
Transaction tx = TransactionBuilder(account!)
    .addOperation(extendOp)
    .build();
tx.sorobanTransactionData = transactionData;

// Simulate for the resource fee
SimulateTransactionResponse sim =
    await server.simulateTransaction(SimulateTransactionRequest(tx));
tx.sorobanTransactionData = sim.transactionData;
tx.addResourceFee(sim.minResourceFee!);
tx.sign(keyPair, Network.TESTNET);
await server.sendTransaction(tx);
```

An archived entry is not extended; restore it first (next section). For contract code the key is `XdrLedgerKey.forContractCode(Util.hexToBytes(wasmHash))`.

### Restore Expired Data

When simulation returns a `restorePreamble`, entries must be restored before invoking. With `SorobanClient`, `MethodOptions(restore: true)` does this: it restores, reloads the account, rebuilds, and simulates the call again, and throws when the restore fails. The fence shows the low-level way:

```dart
// From your app: contractId (String), keyPair (KeyPair)
// From the section Deploy with Constructor Arguments: server (SorobanServer)
// The original invocation (any contract call)
InvokeHostFunctionOperation invokeOp =
    InvokeHostFuncOpBuilder(InvokeContractHostFunction(contractId, 'increment')).build();
Account? account = await server.getAccount(keyPair.accountId);
if (account == null) throw Exception('Account not found');
Transaction tx = TransactionBuilder(account).addOperation(invokeOp).build();

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

  // pollTransaction: at most 30 tries; the answer can still be NOT_FOUND after the limit
  GetTransactionResponse restoreResult = await server.pollTransaction(restoreResp.hash!);
  if (restoreResult.status != GetTransactionResponse.STATUS_SUCCESS) {
    throw Exception('Restore failed: ${restoreResult.status}');
  }

  // The restore used the next sequence number: reload, rebuild, simulate again
  account = await server.getAccount(keyPair.accountId);
  if (account == null) throw Exception('Account not found');
  tx = TransactionBuilder(account).addOperation(invokeOp).build();
  sim = await server.simulateTransaction(SimulateTransactionRequest(tx));
}

// The usual steps: apply the simulation, sign, send, then poll as in Low-Level: SorobanServer
tx.sorobanTransactionData = sim.transactionData;
tx.addResourceFee(sim.minResourceFee!);
tx.setSorobanAuth(sim.sorobanAuth);
tx.sign(keyPair, Network.TESTNET);
SendTransactionResponse sendResp = await server.sendTransaction(tx);
```

---

## Deploy Stellar Asset Contract (SAC)

Wrap a classic Stellar asset for use in Soroban:

```dart
// From your app: issuerAccountId (String)
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

// From your app: contractId (String)
// From the section Install WASM Code: wasmId (String)
// From local WASM bytecode (offline)
Uint8List wasmBytes = File('contract.wasm').readAsBytesSync();
SorobanContractInfo contractInfo =
    SorobanContractParser.parseContractByteCode(wasmBytes);

// From network (by WASM hash or contract ID)
SorobanServer server = SorobanServer('https://soroban-testnet.stellar.org:443');
SorobanContractInfo? info = await server.loadContractInfoForWasmId(wasmId);
SorobanContractInfo? infoById = await server.loadContractInfoForContractId(contractId);
```

A contract created from a CAP-85 external reference (Protocol 28) resolves automatically.
See `rpc.md` > Contract Introspection Helpers for `getExternalRefWasmHash()`.

### SorobanContractInfo Properties

| Property | Type | Description |
|----------|------|-------------|
| `envProtocolVersion` | `int` | Environment protocol version |
| `envPreReleaseVersion` | `int` | Environment pre-release version |
| `specEntries` | `List<XdrSCSpecEntry>` | All spec entries (raw) |
| `funcs` | `List<XdrSCSpecFunctionV0>` | Contract functions |
| `udtStructs` | `List<XdrSCSpecUDTStructV0>` | Struct definitions |
| `udtUnions` | `List<XdrSCSpecUDTUnionV0>` | Union definitions |
| `udtEnums` | `List<XdrSCSpecUDTEnumV0>` | Enum definitions |
| `udtErrorEnums` | `List<XdrSCSpecUDTErrorEnumV0>` | Error enum definitions |
| `events` | `List<XdrSCSpecEventV0>` | Event definitions |
| `metaEntries` | `Map<String, String>` | Contract metadata |
| `supportedSeps` | `List<String>` | Supported SEP numbers (from metadata) |

### Listing Functions and Parameters

```dart
// From the section Loading Contract Info: contractInfo (SorobanContractInfo)
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
// From the section Loading Contract Info: contractInfo (SorobanContractInfo)
for (XdrSCSpecUDTStructV0 struct in contractInfo.udtStructs) {
  print('Struct: ${struct.name}');
  for (XdrSCSpecUDTStructFieldV0 field in struct.fields) {
    print('  ${field.name}: type ${field.type.discriminant.value}');
  }
}
```

### Listing Enum Types

```dart
// From the section Loading Contract Info: contractInfo (SorobanContractInfo)
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
// From the section Loading Contract Info: contractInfo (SorobanContractInfo)
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
      default:
        throw StateError('Unknown union case kind ${case_.discriminant.value}');
    }
  }
}
```

### Listing Error Enum Types

```dart
// From the section Loading Contract Info: contractInfo (SorobanContractInfo)
for (XdrSCSpecUDTErrorEnumV0 errorEnum in contractInfo.udtErrorEnums) {
  print('Error Enum: ${errorEnum.name}');
  for (XdrSCSpecUDTErrorEnumCaseV0 case_ in errorEnum.cases) {
    print('  ${case_.name} = ${case_.value.uint32}');
  }
}
```

### Listing Events

```dart
// From the section Loading Contract Info: contractInfo (SorobanContractInfo)
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
| `SC_SPEC_TYPE_MUXED_ADDRESS` | 20 | MuxedAddress | `XdrSCVal.forAddress(addr)` |
| `SC_SPEC_TYPE_VEC` | 1002 | Vec | `XdrSCVal.forVec(list)` -- check `.vec` for element type |
| `SC_SPEC_TYPE_MAP` | 1004 | Map | `XdrSCVal.forMap(entries)` -- check `.map` for key/value types |
| `SC_SPEC_TYPE_UDT` | 2000 | User-defined | check `.udt?.name` for the type name |
