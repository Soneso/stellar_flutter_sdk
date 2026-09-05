# Soroban Smart Contracts

Deploy and interact with Soroban smart contracts using the Stellar Flutter SDK.

**Protocol details**: [Soroban Documentation](https://developers.stellar.org/docs/smart-contracts)

## Quick Start

Install WASM, deploy a contract, and call a method in one go.

```dart
import 'dart:io';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Secret seed of your funded account; replace it with yours
KeyPair keyPair = KeyPair.fromSecretSeed(
    'SAAACAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUPB6NKI');
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
// The id names a funded account; replace it with yours.
Account? account = await server.getAccount(
    'GAB2CB576PHBBPQ5ODORRZ2LYCMWPZGWGCN2KDK7DXOIMZASKUY3QZ6Q');
if (account != null) {
  print('Sequence: ${account.sequenceNumber}');
}
```

### Contract Data

Read persistent or temporary data stored by a contract.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SorobanServer server = SorobanServer('https://soroban-testnet.stellar.org:443');

// The id names a deployed contract; replace it with yours.
LedgerEntry? entry = await server.getContractData(
  'CCTHWH6DJQY6N2HSPVOFNKFT3FBM4MFBVEXXOAQ6UOS7BTML4JDRSXQP',
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
SorobanContractInfo? info = await server.loadContractInfoForContractId(
    'CCTHWH6DJQY6N2HSPVOFNKFT3FBM4MFBVEXXOAQ6UOS7BTML4JDRSXQP');
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
  XdrSCAddress.forContractId(
      'CCTHWH6DJQY6N2HSPVOFNKFT3FBM4MFBVEXXOAQ6UOS7BTML4JDRSXQP'),
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

Helper methods to load contract bytecode from the network. An instance created from a CAP-85
external reference resolves automatically; a Stellar Asset Contract has no wasm, so it
yields `null`.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SorobanServer server = SorobanServer('https://soroban-testnet.stellar.org:443');

// By contract ID
XdrContractCodeEntry? code = await server.loadContractCodeForContractId(
    'CCTHWH6DJQY6N2HSPVOFNKFT3FBM4MFBVEXXOAQ6UOS7BTML4JDRSXQP');
if (code != null) {
  print('Code size: ${code.code.length} bytes');
}

// By WASM ID
XdrContractCodeEntry? code2 = await server.loadContractCodeForWasmId(wasmId);
```

### External Reference Executables (CAP-85)

From Protocol 28 on, a contract can be created from an external reference: instead of
carrying its own wasm hash, the instance names an owner contract and a tag, and the owner
holds a persistent contract data entry under that tag whose value is the 32-byte hash of an
already uploaded wasm. `loadContractCodeForContractId` and `loadContractInfoForContractId`
resolve such instances without any extra step. To resolve a reference directly, use
`getExternalRefWasmHash`:

```dart
import 'dart:typed_data';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SorobanServer server = SorobanServer('https://soroban-testnet.stellar.org:443');

// Read the contract instance to inspect its executable.
// The id names a deployed contract; replace it with yours.
LedgerEntry? entry = await server.getContractData(
  'CCTHWH6DJQY6N2HSPVOFNKFT3FBM4MFBVEXXOAQ6UOS7BTML4JDRSXQP',
  XdrSCVal.forLedgerKeyContractInstance(),
  XdrContractDataDurability.PERSISTENT,
);

XdrContractExecutable? executable =
    entry?.ledgerEntryDataXdr.contractData?.val.instance?.executable;
if (executable != null && executable.externalRef != null) {
  // The tag entry on the owner contract holds the wasm hash the instance runs.
  Uint8List? wasmHash =
      await server.getExternalRefWasmHash(executable.externalRef!);
  if (wasmHash != null) {
    XdrContractCodeEntry? code =
        await server.loadContractCodeForWasmId(Util.bytesToHex(wasmHash));
    print('Code size: ${code?.code.length} bytes');
  }
}
```

`getExternalRefWasmHash` returns the 32-byte wasm hash, or `null` when the owner is not a
contract address, no entry exists under the tag, or the entry does not hold a 32-byte
`SCV_BYTES` value. The owner contract is read, never invoked.

## SorobanClient

High-level API for contract interaction.

### Creating a Client

Set up a SorobanClient instance for interacting with a specific contract.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// The seed names a funded account and the id a deployed contract;
// replace both with yours.
SorobanClient client = await SorobanClient.forClientOptions(
  options: ClientOptions(
    sourceAccountKeyPair: KeyPair.fromSecretSeed(
        'SAAACAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUPB6NKI'),
    contractId: 'CCTHWH6DJQY6N2HSPVOFNKFT3FBM4MFBVEXXOAQ6UOS7BTML4JDRSXQP',
    network: Network.TESTNET,
    rpcUrl: 'https://soroban-testnet.stellar.org:443',
  ),
);

List<String> methodNames = client.getMethodNames();
ContractSpec spec = client.getContractSpec();
```

`ClientOptions`, `InstallRequest` and `DeployRequest` also accept an optional
`server` parameter with a preconfigured `SorobanServer`. When provided, it is
used for all RPC calls instead of constructing a server from `rpcUrl`. This
allows reusing a single RPC connection across operations (for example to
guarantee that all calls hit the same backend node of a load-balanced RPC
endpoint) or supplying a server with a custom HTTP client configuration.

```dart
SorobanServer server = SorobanServer(rpcUrl);

SorobanClient client = await SorobanClient.forClientOptions(
  options: ClientOptions(
    sourceAccountKeyPair: keyPair,
    contractId: 'CCTHWH6DJQY6N2HSPVOFNKFT3FBM4MFBVEXXOAQ6UOS7BTML4JDRSXQP',
    network: Network.TESTNET,
    rpcUrl: rpcUrl,
    server: server,
  ),
);
```

### Invoking Methods

Call contract functions to read data or submit state changes.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SorobanClient client = await SorobanClient.forClientOptions(
  options: ClientOptions(
    sourceAccountKeyPair: KeyPair.fromSecretSeed(
        'SAAACAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUPB6NKI'),
    contractId: 'CCTHWH6DJQY6N2HSPVOFNKFT3FBM4MFBVEXXOAQ6UOS7BTML4JDRSXQP',
    network: Network.TESTNET,
    rpcUrl: 'https://soroban-testnet.stellar.org:443',
  ),
);

// Read-only (returns simulation result)
XdrSCVal balance = await client.invokeMethod(
  name: 'balance',
  args: [
    XdrSCVal.forAccountAddress(
        'GAB2CB576PHBBPQ5ODORRZ2LYCMWPZGWGCN2KDK7DXOIMZASKUY3QZ6Q'),
  ],
);

// Write (auto-signs and submits)
XdrSCVal result = await client.invokeMethod(
  name: 'transfer',
  args: [
    // Sender
    XdrSCVal.forAccountAddress(
        'GAB2CB576PHBBPQ5ODORRZ2LYCMWPZGWGCN2KDK7DXOIMZASKUY3QZ6Q'),
    // Destination
    XdrSCVal.forAccountAddress(
        'GBMYYYOUQTENJ7DBSKCVRIOHINC2JJZVQX7B4WOQL4KNLRZEVK6TRNG7'),
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
    // Secret seed of your funded account; replace it with yours
    sourceAccountKeyPair: KeyPair.fromSecretSeed(
        'SAAACAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUPB6NKI'),
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
    sourceAccountKeyPair: KeyPair.fromSecretSeed(
        'SAAACAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUPB6NKI'),
    wasmHash: wasmHash,
  ),
);

// With constructor (protocol 22+)
SorobanClient client2 = await SorobanClient.deploy(
  deployRequest: DeployRequest(
    rpcUrl: 'https://soroban-testnet.stellar.org:443',
    network: Network.TESTNET,
    sourceAccountKeyPair: KeyPair.fromSecretSeed(
        'SAAACAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUPB6NKI'),
    wasmHash: wasmHash,
    constructorArgs: [XdrSCVal.forSymbol('MyToken'), XdrSCVal.forU32(8)],
  ),
);
```

### Deployment from an External Reference (Protocol 28)

Create a contract instance that runs the wasm named by a CAP-85 external reference:
the owner contract holds a persistent entry under a tag, and its value is the hash of
the wasm the instance runs. There is no install step; the owner already holds the tag
entry. The reference is resolved before the transaction is built, so an unresolvable
reference throws naming the owner and the tag rather than failing on-chain.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SorobanClient client = await SorobanClient.deployFromExternalRef(
  deployRequest: DeployFromExternalRefRequest.forTagString(
    rpcUrl: 'https://soroban-testnet.stellar.org:443',
    network: Network.TESTNET,
    // Secret seed of the funded account that signs the deployment; replace it with yours
    sourceAccountKeyPair: KeyPair.fromSecretSeed(
        'SAAACAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUPB6NKI'),
    // The owner contract holding the tag entry; replace it with yours
    executableOwner: Address.forContractId(
        'CCTHWH6DJQY6N2HSPVOFNKFT3FBM4MFBVEXXOAQ6UOS7BTML4JDRSXQP'),
    tag: 'token-v1', // Tag of the executable entry on the owner; matched byte for byte
  ),
);
```

`DeployFromExternalRefRequest.tag` carries the tag as raw bytes (`Uint8List`) — an
executable tag is an XDR string, whose bytes need not be valid UTF-8. The
`forTagString` constructor takes a text tag and encodes it as UTF-8 exactly once; pass
the bytes to the default constructor for a tag that spells no text. The same bytes are
used to resolve the owner's entry and to build the create operation.

`constructorArgs` and `salt` work as in `DeployRequest`; the create operation uses the
`CREATE_CONTRACT_V2` host function form with an empty constructor-argument vector when
`constructorArgs` is not given, as `deploy` does. The contract spec is loaded
from the resolved wasm before submission and the returned client is ready to invoke.

### Deriving a Contract Id Before Deploying

`Address.deriveContractId` returns the contract id ("C...") a deployment by a given
deployer with a given salt creates on a given network. The id derives from the
deployer, the salt and the network only; the executable (wasm hash, external reference
or Stellar asset) does not enter the derivation. Use it when the address is needed
before the deployment, for example in constructor arguments of another contract.

```dart
import 'dart:math';
import 'dart:typed_data';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// The account (or contract) that will submit the deployment
Address deployer = Address.forAccountId(
    'GAB2CB576PHBBPQ5ODORRZ2LYCMWPZGWGCN2KDK7DXOIMZASKUY3QZ6Q');
// The salt determines the contract id, so it comes from a secure source
final random = Random.secure();
Uint8List salt = Uint8List.fromList(List<int>.generate(32, (_) => random.nextInt(256)));

String futureContractId = Address.deriveContractId(
  deployer: deployer,
  salt: salt,
  network: Network.TESTNET,
);

// Deploying with the same deployer and salt creates exactly this contract id
```

## AssembledTransaction

Fine-grained control over the transaction lifecycle. Use `buildInvokeMethodTx()` instead of `invokeMethod()` when you need to inspect simulation results, add memos, or handle multi-signature workflows.

### Building Without Submitting

Build a transaction to inspect it before submission.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SorobanClient client = await SorobanClient.forClientOptions(
  options: ClientOptions(
    sourceAccountKeyPair: KeyPair.fromSecretSeed(
        'SAAACAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUPB6NKI'),
    contractId: 'CCTHWH6DJQY6N2HSPVOFNKFT3FBM4MFBVEXXOAQ6UOS7BTML4JDRSXQP',
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

// Secret seeds of the two funded accounts; replace them with yours
KeyPair alice = KeyPair.fromSecretSeed(
    'SAAACAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUPB6NKI');
KeyPair bob = KeyPair.fromSecretSeed(
    'SDJRWLCGLROL365KUWQG7OAAYHBNCNV7TJ7LG2GW5663XVZED6YU7HXB');

SorobanClient client = await SorobanClient.forClientOptions(
  options: ClientOptions(
    sourceAccountKeyPair: alice,
    // The deployed swap contract
    contractId: 'CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE',
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
// e.g., ['GBMYYYOUQTENJ7DBSKCVRIOHINC2JJZVQX7B4WOQL4KNLRZEVK6TRNG7']
// - Bob needs to authorize
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
KeyPair bobPublicKey = KeyPair.fromAccountId(
    'GBMYYYOUQTENJ7DBSKCVRIOHINC2JJZVQX7B4WOQL4KNLRZEVK6TRNG7');

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

### Protocol 27 Credentials (CAP-71)

Protocol 27 adds two address-credential arms to `SorobanCredentials`:

- `ADDRESS_V2` carries the same `SorobanAddressCredentials` body as the legacy `ADDRESS` arm, but the signature payload additionally binds the credential address.
- `ADDRESS_WITH_DELEGATES` extends V2 with a tree of delegate signatures, letting additional addresses co-sign one authorization entry.

`ADDRESS_V2` is the default arm: simulation requests it, and `SorobanCredentials.forAddress` / `forAddressCredentials` build it. The legacy `ADDRESS` arm stays fully valid; use it on a network below protocol 27, where the newer arms invalidate the transaction — request it from simulation with `useUpgradedAuth: false` and build it with `forAddressLegacy` / `forAddressCredentialsLegacy`.

All signing APIs (`signAuthEntries`, `SorobanAuthorizationEntry.sign`, SEP-45) support all three arms and preserve the arm on write-back. `needsNonInvokerSigningBy` reports the address of every node whose signature is void, including each unsigned delegate node of a `WITH_DELEGATES` entry. Use `credentials.innerAddressCredentials` to read the inner credentials of any address arm (it returns `null` only for source-account credentials). Factories: `SorobanCredentials.forAddress` / `forAddressCredentials` build `ADDRESS_V2` (as does the explicit `forAddressV2`), `forAddressLegacy` / `forAddressCredentialsLegacy` build legacy `ADDRESS`, and `forAddressWithDelegates` builds the delegated arm.

#### V2 Entries from Simulation

Simulation requests `ADDRESS_V2` credential arms by default (`useUpgradedAuth` is `true` on `MethodOptions` and `SimulateTransactionRequest`, and the key is always sent in the JSON-RPC params). The flag is best-effort: an RPC server that supports it records `ADDRESS_V2` entries, while a server without support silently ignores it and returns legacy `ADDRESS` entries — detect which arm you got by inspecting the credential arm of the returned entries, never by expecting an error. Set `useUpgradedAuth` to `false` to request legacy `ADDRESS` entries, for example on a network below protocol 27.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Contract client: ADDRESS_V2 entries are requested by default
AssembledTransaction tx = await client.buildInvokeMethodTx(
  name: 'swap',
  args: args,
);

// Detect whether the RPC honored the flag
List<SorobanAuthorizationEntry> entries = tx.simulationResponse?.sorobanAuth ?? [];
bool gotV2 = entries.any((e) =>
    e.credentials.arm ==
    XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2);

// Low-level: request legacy ADDRESS entries on the simulate request
SimulateTransactionRequest request =
    SimulateTransactionRequest(transaction, useUpgradedAuth: false);
SimulateTransactionResponse sim = await server.simulateTransaction(request);
```

#### Delegated Authorization

A `WITH_DELEGATES` entry lets delegate addresses co-sign a single authorization entry. Simulation never returns `WITH_DELEGATES` entries; clients assemble the tree from an `ADDRESS` or `ADDRESS_V2` entry using `SorobanAuthorizationEntry.withDelegates`.

Rules enforced by the host and handled by the SDK builder:

- Every delegate array must be sorted ascending by the XDR-encoded bytes of the delegate address, with no duplicates within one array. The builder sorts automatically and throws on duplicates — always construct trees through `withDelegates` rather than assembling the XDR by hand.
- Every signer in the tree — top-level and delegates at any depth — signs the same payload, which is bound to the top-level credential address. Delegates carry no nonce and no expiration; only the top-level credentials do.
- A void top-level signature is legitimate when the delegates sign (the delegates-only pattern); such an entry passes the send precheck once every delegate is signed.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final SorobanServer server =
    SorobanServer('https://soroban-testnet.stellar.org:443');

// Top-level credential account and a delegate signer's account
final KeyPair topLevelKeyPair = KeyPair.fromSecretSeed(
    'SAAACAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUPB6NKI');
final KeyPair delegateKeyPair = KeyPair.fromSecretSeed(
    'SDJRWLCGLROL365KUWQG7OAAYHBNCNV7TJ7LG2GW5663XVZED6YU7HXB');

// An ADDRESS or ADDRESS_V2 entry bound to the top-level account. In practice
// this comes from simulation (tx.simulationResponse!.sorobanAuth!.first);
// it is built explicitly here so the snippet is self-contained.
final SorobanAuthorizationEntry sourceEntry = SorobanAuthorizationEntry(
  SorobanCredentials.forAddressV2(SorobanAddressCredentials(
    Address.forAccountId(topLevelKeyPair.accountId),
    BigInt.from(1234), // nonce
    0, // signatureExpirationLedger (set by withDelegates below)
    XdrSCVal.forVoid(),
  )),
  SorobanAuthorizedInvocation(SorobanAuthorizedFunction.forContractFunction(
    Address.forContractId(
        'CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE'),
    'swap',
    [],
  )),
);

// Latest ledger sequence, used to set the signature expiration
final GetLatestLedgerResponse latestLedger = await server.getLatestLedger();
final int expirationLedger = latestLedger.sequence! + 100;

// Build the WITH_DELEGATES entry. The builder sorts the delegate array,
// rejects duplicates, and resets the top-level signature to void.
SorobanAuthorizationEntry delegated = SorobanAuthorizationEntry.withDelegates(
  sourceEntry,
  [SorobanDelegateDescriptor(delegateKeyPair.accountId)],
  expirationLedger,
);

// Optional top-level signature (skip this for the delegates-only pattern).
// When one node needs multiple classical (G-address) signatures, add them in
// ascending public-key order — the host requires that order and the SDK
// appends signatures in the order you call sign.
delegated.sign(topLevelKeyPair, Network.TESTNET);

// Delegate signer: forAddress routes the signature into the matching node
// (top-level or any delegate, depth-first) and throws when no node matches.
delegated.sign(delegateKeyPair, Network.TESTNET,
    forAddress: delegateKeyPair.accountId);
```

`SorobanDelegateDescriptor` supports nesting via `nestedDelegates` and accepts a pre-built `signature` (default void) for nodes signed externally, such as contract addresses.

`WITH_DELEGATES` entries are never returned by simulation, so the delegated arm is always assembled client-side and submitted at the `SorobanServer` level. `ADDRESS_V2` entries come from a supporting RPC by default (`useUpgradedAuth`), or client-side from `SorobanCredentials.forAddressV2` when converting an entry in place.

After attaching the signed entries with `transaction.setSorobanAuth(...)`, re-simulate in enforcing mode before submitting. The first (recording) simulation does not run the authorizing account's `__check_auth`, so it understates the resource fee and — for a custom (contract) account whose `__check_auth` reads storage or calls into delegates — omits the footprint entries that authorization touches. Re-simulate with the signed entry attached and `authMode` set to `enforce` (`SimulateTransactionRequest(transaction, authMode: 'enforce')`), then apply the returned data before signing: assign `response.transactionData` to `transaction.sorobanTransactionData` and add `response.minResourceFee` via `transaction.addResourceFee(...)`. The already-signed auth is preserved.

When converting a simulated `ADDRESS` entry to `ADDRESS_V2` in place, reuse its nonce — `SorobanCredentials.forAddressV2(credentials.innerAddressCredentials!)` carries the nonce over; a fresh nonce will not match the recorded footprint and then relies on the enforcing re-simulation above.

#### Source Compatibility

`SorobanCredentials`, `XdrSorobanCredentialsType`, `XdrEnvelopeType`, and `XdrHashIDPreimage` gain new union cases for the V2 and delegated arms. Code that switches exhaustively over these without a `default` arm will no longer compile after upgrading. Add a `default` case to such switches.

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
XdrSCVal account = XdrSCVal.forAccountAddress(
    'GAB2CB576PHBBPQ5ODORRZ2LYCMWPZGWGCN2KDK7DXOIMZASKUY3QZ6Q');

// Contract address (C...) - convenience method
XdrSCVal contract = XdrSCVal.forContractAddress(
    'CCTHWH6DJQY6N2HSPVOFNKFT3FBM4MFBVEXXOAQ6UOS7BTML4JDRSXQP');

// Via Address helper
XdrSCVal addr = Address.forAccountId(
        'GAB2CB576PHBBPQ5ODORRZ2LYCMWPZGWGCN2KDK7DXOIMZASKUY3QZ6Q')
    .toXdrSCVal();
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
  // Auto-converts to Address
  'a': 'GAB2CB576PHBBPQ5ODORRZ2LYCMWPZGWGCN2KDK7DXOIMZASKUY3QZ6Q',
  'b': 'GBMYYYOUQTENJ7DBSKCVRIOHINC2JJZVQX7B4WOQL4KNLRZEVK6TRNG7',
  // Contract address
  'token_a': 'CCTHWH6DJQY6N2HSPVOFNKFT3FBM4MFBVEXXOAQ6UOS7BTML4JDRSXQP',
  'token_b': 'CAGRIGZCFEYDOPSFJRJVUYLIN53H3BELSKM2BJ5OWW6MHSWR3DP6MACS',
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
  'alice': 'GAB2CB576PHBBPQ5ODORRZ2LYCMWPZGWGCN2KDK7DXOIMZASKUY3QZ6Q',
  'bob': 'GBMYYYOUQTENJ7DBSKCVRIOHINC2JJZVQX7B4WOQL4KNLRZEVK6TRNG7',
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

// The id names a deployed contract; replace it with yours.
String contractId = 'CCTHWH6DJQY6N2HSPVOFNKFT3FBM4MFBVEXXOAQ6UOS7BTML4JDRSXQP';

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
    sourceAccountKeyPair: KeyPair.fromSecretSeed(
        'SAAACAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUPB6NKI'),
    contractId: 'CCTHWH6DJQY6N2HSPVOFNKFT3FBM4MFBVEXXOAQ6UOS7BTML4JDRSXQP',
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

stellar-contract-bindings flutter \
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

// The seed names a funded account and the id the deployed token contract;
// replace both with yours.
TokenClient client = await TokenClient.forContractId(
  sourceAccountKeyPair: KeyPair.fromSecretSeed(
      'SAAACAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUPB6NKI'),
  contractId: 'CCTHWH6DJQY6N2HSPVOFNKFT3FBM4MFBVEXXOAQ6UOS7BTML4JDRSXQP',
  network: Network.TESTNET,
  rpcUrl: 'https://soroban-testnet.stellar.org:443',
);

// Type-safe calls with native Dart types
BigInt balance = await client.balance(
    id: Address.forAccountId(
        'GAB2CB576PHBBPQ5ODORRZ2LYCMWPZGWGCN2KDK7DXOIMZASKUY3QZ6Q'),
);
await client.transfer(
  from: Address.forAccountId(
      'GAB2CB576PHBBPQ5ODORRZ2LYCMWPZGWGCN2KDK7DXOIMZASKUY3QZ6Q'),
  to: Address.forAccountId(
      'GBMYYYOUQTENJ7DBSKCVRIOHINC2JJZVQX7B4WOQL4KNLRZEVK6TRNG7'),
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

// Secret seed of your funded account; replace it with yours
KeyPair keyPair = KeyPair.fromSecretSeed(
    'SAAACAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUPB6NKI');
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

### Create Contract from an External Reference (Protocol 28)

Deploy a contract whose executable is a CAP-85 external reference: the owner contract's
persistent tag entry names the wasm the instance runs. The executable owner must be a
contract address — only a contract can hold the tag entry; the builders' constructor and
`executableOwner` setter throw `ArgumentError` for any other address type. For the
one-call variant, see "Deployment from an External Reference (Protocol 28)" under
Installing and Deploying.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Secret seed of your funded deployer account; replace it with yours
KeyPair keyPair = KeyPair.fromSecretSeed(
    'SAAACAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUPB6NKI');

InvokeHostFunctionOperation createOp = InvokeHostFuncOpBuilder(
  CreateContractFromExternalRefHostFunction.forTagString(
    Address.forAccountId(keyPair.accountId),
    // The owner contract holding the tag entry
    Address.forContractId(
        'CCTHWH6DJQY6N2HSPVOFNKFT3FBM4MFBVEXXOAQ6UOS7BTML4JDRSXQP'),
    'token-v1',
  ),
).build();

// Simulate, sign and send as for any create contract operation.
```

`CreateContractFromExternalRefWithConstructorHostFunction` is the variant taking
constructor arguments, mirroring `CreateContractWithConstructorHostFunction`.

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

// The id names the asset issuer account; replace it with yours.
Asset asset = Asset.createNonNativeAsset(
    'USDC', 'GAB2CB576PHBBPQ5ODORRZ2LYCMWPZGWGCN2KDK7DXOIMZASKUY3QZ6Q');

InvokeHostFunctionOperation sacOp = InvokeHostFuncOpBuilder(
  DeploySACWithAssetHostFunction(asset),
).build();

// Build, simulate, sign, and send
```

### Direct Authorization Signing

For advanced auth workflows, sign authorization entries directly.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// The simulation response, the transaction it simulated, and the authorizing
// keypair come from the surrounding flow and enter as parameters.
Future<void> signSimulatedAuth(
  SorobanServer server,
  SimulateTransactionResponse simResponse,
  Transaction tx,
  KeyPair signerKeyPair,
) async {
  // Get auth entries from simulation
  List<SorobanAuthorizationEntry>? auth = simResponse.sorobanAuth;
  GetLatestLedgerResponse latestLedger = await server.getLatestLedger();

  if (auth != null) {
    for (SorobanAuthorizationEntry entry in auth) {
      // Set signature expiration (~50 seconds at 5s/ledger)
      entry.credentials.innerAddressCredentials?.signatureExpirationLedger =
          latestLedger.sequence! + 10;

      // Sign the entry
      entry.sign(signerKeyPair, Network.TESTNET);
    }
  }

  // Set signed auth on transaction
  tx.setSorobanAuth(auth);
}
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

Load and parse contract info from a deployed contract. A contract created from a CAP-85
external reference (Protocol 28) is resolved automatically.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SorobanServer server = SorobanServer('https://soroban-testnet.stellar.org:443');

// By contract ID
SorobanContractInfo? contractInfo = await server.loadContractInfoForContractId(
    'CCTHWH6DJQY6N2HSPVOFNKFT3FBM4MFBVEXXOAQ6UOS7BTML4JDRSXQP');

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
