# XDR Encoding & Decoding Reference

All code assumes the standard SDK import:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
```

## Transaction Envelope Encoding

Convert a signed transaction to base64 XDR for storage, sharing, or submission:

```dart
// After building and signing a transaction (see operations.md)
String xdrBase64 = tx.toEnvelopeXdrBase64();
print('Signed XDR: $xdrBase64');
```

## Transaction Envelope Decoding

Parse a base64 XDR string back into a transaction object:

```dart
AbstractTransaction decoded = AbstractTransaction.fromEnvelopeXdrString(xdrBase64);

if (decoded is Transaction) {
  print('Source: ${decoded.sourceAccount.accountId}');
  print('Fee: ${decoded.fee}');
  print('Sequence: ${decoded.sequenceNumber}');
  print('Operations: ${decoded.operations.length}');
  print('Signatures: ${decoded.signatures.length}');
} else if (decoded is FeeBumpTransaction) {
  print('Fee source: ${decoded.feeAccount.accountId}');
  Transaction inner = decoded.innerTransaction;
  print('Inner tx ops: ${inner.operations.length}');
}
```

## XdrSCVal Factory Methods

Complete reference for Soroban smart contract value types:

| Category | Factory Method | Dart Input Type |
|----------|---------------|----------------|
| **Primitives** | | |
| Bool | `XdrSCVal.forBool(value)` | `bool` |
| Void | `XdrSCVal.forVoid()` | none |
| u32 | `XdrSCVal.forU32(value)` | `int` |
| i32 | `XdrSCVal.forI32(value)` | `int` |
| u64 | `XdrSCVal.forU64(value)` | `BigInt` |
| i64 | `XdrSCVal.forI64(value)` | `BigInt` |
| Timepoint | `XdrSCVal.forTimepoint(value)` | `BigInt` |
| Duration | `XdrSCVal.forDuration(value)` | `BigInt` |
| **128-bit** | | |
| u128 (parts) | `XdrSCVal.forU128Parts(hi, lo)` | `BigInt, BigInt` |
| i128 (parts) | `XdrSCVal.forI128Parts(hi, lo)` | `BigInt, BigInt` |
| u128 (BigInt) | `XdrSCVal.forU128BigInt(value)` | `BigInt` |
| i128 (BigInt) | `XdrSCVal.forI128BigInt(value)` | `BigInt` |
| **256-bit** | | |
| u256 (parts) | `XdrSCVal.forU256Parts(hiHi, hiLo, loHi, loLo)` | `BigInt` x4 |
| i256 (parts) | `XdrSCVal.forI256Parts(hiHi, hiLo, loHi, loLo)` | `BigInt` x4 |
| u256 (BigInt) | `XdrSCVal.forU256BigInt(value)` | `BigInt` |
| i256 (BigInt) | `XdrSCVal.forI256BigInt(value)` | `BigInt` |
| **Data** | | |
| Symbol | `XdrSCVal.forSymbol(str)` | `String` |
| String | `XdrSCVal.forString(str)` | `String` |
| Bytes | `XdrSCVal.forBytes(bytes)` | `Uint8List` |
| **Address** | | |
| Address (XDR) | `XdrSCVal.forAddress(xdrAddr)` | `XdrSCAddress` |
| Account | `XdrSCVal.forAccountAddress(accountId)` | `String` (G...) |
| Contract | `XdrSCVal.forContractAddress(contractId)` | `String` (C...) |
| Muxed | `XdrSCVal.forMuxedAccountAddress(muxedId)` | `String` (M...) |
| Claimable | `XdrSCVal.forClaimableBalanceAddress(id)` | `String` |
| Pool | `XdrSCVal.forLiquidityPoolAddress(id)` | `String` |
| **Collections** | | |
| Vec | `XdrSCVal.forVec(values)` | `List<XdrSCVal>` |
| Map | `XdrSCVal.forMap(entries)` | `List<XdrSCMapEntry>` |
| **Special** | | |
| Error | `XdrSCVal.forError(error)` | `XdrSCError` |
| Instance | `XdrSCVal.forLedgerKeyContractInstance()` | none |

### Building Vec and Map Values

```dart
// Vec: ordered list of values
XdrSCVal vec = XdrSCVal.forVec([
  XdrSCVal.forSymbol('hello'),
  XdrSCVal.forU32(42),
  XdrSCVal.forBool(true),
]);

// Map: key-value pairs using XdrSCMapEntry(key, val)
XdrSCVal map = XdrSCVal.forMap([
  XdrSCMapEntry(XdrSCVal.forSymbol('name'), XdrSCVal.forString('Alice')),
  XdrSCMapEntry(XdrSCVal.forSymbol('balance'), XdrSCVal.forI128BigInt(BigInt.from(1000000))),
]);
```

### Reading Values from XdrSCVal

Property getters return XDR wrapper types for numeric values. Unwrap to get Dart primitives:

```dart
XdrSCVal val = txResponse.getResultValue()!;

// Direct Dart types (no unwrapping needed)
bool? boolVal = val.b;
String? symbolVal = val.sym;
String? stringVal = val.str;
List<XdrSCVal>? vecVal = val.vec;
List<XdrSCMapEntry>? mapVal = val.map;
XdrSCAddress? addressVal = val.address;

// Numeric wrappers — must unwrap to get Dart value
int? u32Val = val.u32?.uint32;         // XdrUint32? → int
int? i32Val = val.i32?.int32;          // XdrInt32? → int
BigInt? u64Val = val.u64?.uint64;      // XdrUint64? → BigInt
BigInt? i64Val = val.i64?.int64;       // XdrInt64? → BigInt

// 128-bit parts (hi/lo are XdrUint64)
XdrUInt128Parts? u128 = val.u128;
if (u128 != null) {
  BigInt hi = u128.hi.uint64;
  BigInt lo = u128.lo.uint64;
}

// 256-bit parts (hiHi/hiLo/loHi/loLo are XdrUint64)
XdrUInt256Parts? u256 = val.u256;
```

**Common mistake:** Writing `val.u32 == 42` — this compares an `XdrUint32?` to `int`, which is always false. Use `val.u32?.uint32 == 42`.

## XdrSCVal Base64 Serialization

Serialize individual values for storage, caching, or RPC calls:

```dart
// Encode to base64
XdrSCVal original = XdrSCVal.forSymbol('hello');
String base64 = original.toBase64EncodedXdrString();

// Decode from base64
XdrSCVal restored = XdrSCVal.fromBase64EncodedXdrString(base64);
print(restored.sym);  // 'hello'
```

## Ledger Key Construction

Build XDR ledger keys for querying specific ledger entries:

```dart
// Account
XdrLedgerKey accountKey = XdrLedgerKey.forAccountId('GABC...');

// Trustline
XdrLedgerKey trustKey = XdrLedgerKey.forTrustLine(
  'GABC...',
  Asset.createNonNativeAsset('USDC', issuerAccountId).toXdr(),
);

// Contract data
XdrLedgerKey contractDataKey = XdrLedgerKey.forContractData(
  XdrSCAddress.forContractId('CABC...'),
  XdrSCVal.forSymbol('counter'),
  XdrContractDataDurability.PERSISTENT,
);

// Contract instance (metadata)
XdrLedgerKey instanceKey = XdrLedgerKey.forContractData(
  XdrSCAddress.forContractId('CABC...'),
  XdrSCVal.forLedgerKeyContractInstance(),
  XdrContractDataDurability.PERSISTENT,
);

// Contract code
XdrLedgerKey codeKey = XdrLedgerKey.forContractCode(wasmHashBytes);

// Serialize for RPC calls
String base64Key = contractDataKey.toBase64EncodedXdrString();
// Use with server.getLedgerEntries([base64Key])
```

Durability options for contract data:

| Durability | Usage |
|------------|-------|
| `XdrContractDataDurability.PERSISTENT` | Long-lived data that survives TTL reset |
| `XdrContractDataDurability.TEMPORARY` | Short-lived data cleared on TTL expiry |

## XdrSCAddress Construction and Conversion

```dart
// Build addresses
XdrSCAddress accountAddr = XdrSCAddress.forAccountId('GABC...');
XdrSCAddress contractAddr = XdrSCAddress.forContractId('CABC...');
XdrSCAddress claimableAddr = XdrSCAddress.forClaimableBalanceId('00000...');
XdrSCAddress poolAddr = XdrSCAddress.forLiquidityPoolId('abcdef...');

// Convert back to string key
String strKey = accountAddr.toStrKey();  // Returns G... or C... format

// Wrap in XdrSCVal for contract arguments
XdrSCVal addressArg = XdrSCVal.forAddress(accountAddr);
```

## Soroban Transaction Data Inspection

Inspect Soroban resource allocation from simulation results or existing transactions:

```dart
// From simulation response
SimulateTransactionResponse sim =
    await server.simulateTransaction(SimulateTransactionRequest(tx));

XdrSorobanTransactionData? txData = sim.transactionData;
if (txData != null) {
  XdrSorobanResources resources = txData.resources;
  XdrLedgerFootprint footprint = resources.footprint;

  print('Instructions: ${resources.instructions.uint32}');
  print('Disk read bytes: ${resources.diskReadBytes.uint32}');
  print('Write bytes: ${resources.writeBytes.uint32}');
  print('Resource fee: ${txData.resourceFee.int64}');
  print('Read-only entries: ${footprint.readOnly.length}');
  print('Read-write entries: ${footprint.readWrite.length}');
}

// From base64 string
XdrSorobanTransactionData parsedData =
    XdrSorobanTransactionData.fromBase64EncodedXdrString(base64SorobanData);
```

## Transaction Inspection Before Signing

Always inspect transaction details before signing XDR from external sources:

```dart
AbstractTransaction parsed = AbstractTransaction.fromEnvelopeXdrString(externalXdr);

if (parsed is Transaction) {
  print('Source: ${parsed.sourceAccount.accountId}');
  print('Fee: ${parsed.fee} stroops');
  print('Signatures: ${parsed.signatures.length}');
  for (int i = 0; i < parsed.operations.length; i++) {
    print('  Op $i: ${parsed.operations[i].runtimeType}');
  }
  // Check for unexpected Soroban resource fees
  if (parsed.sorobanTransactionData != null) {
    print('Soroban fee: ${parsed.sorobanTransactionData!.resourceFee.int64}');
  }
}
```

## SorobanAuthorizationEntry XDR

Serialize and deserialize authorization entries for remote signing workflows (e.g., when a non-invoker must sign on a separate server):

```dart
// Encode auth entry for transport to remote signer
SorobanAuthorizationEntry authEntry = simResponse.sorobanAuth!.first;
String base64 = authEntry.toBase64EncodedXdrString();
// Send base64 to remote signer

// Remote signer: decode, sign, return
SorobanAuthorizationEntry received =
    SorobanAuthorizationEntry.fromBase64EncodedXdr(base64);
received.sign(signerKeyPair, Network.TESTNET);
String signedBase64 = received.toBase64EncodedXdrString();
// Return signedBase64 to invoker
```

