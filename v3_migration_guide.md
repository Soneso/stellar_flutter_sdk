# Migration Guide: v2.x to v3.0.0

This guide helps you migrate from stellar_flutter_sdk v2.x to v3.0.0, which introduces BigInt for all 64-bit integer types to enable full web platform support.

## Why This Change?

JavaScript numbers have only 53 bits of integer precision. Values exceeding 2^53 (9,007,199,254,740,992) lose precision silently. Stellar and Soroban use 64-bit integers extensively, so BigInt is required for correct behavior on web platforms.

## Breaking Changes Overview

| Type | v2.x | v3.0.0 |
|------|------|--------|
| `XdrInt64.int64` | `int` | `BigInt` |
| `XdrUint64.uint64` | `int` | `BigInt` |
| `MemoId` constructor | `int` | `BigInt` |
| `MuxedAccount.id` | `int?` | `BigInt?` |
| `XdrSCVal.forU64()` | `int` | `BigInt` |
| `XdrSCVal.forI64()` | `int` | `BigInt` |
| `XdrSCVal.forTimepoint()` | `int` | `BigInt` |
| `XdrSCVal.forDuration()` | `int` | `BigInt` |
| `XdrInt128Parts.forHiLo()` | `int, int` | `BigInt, BigInt` |
| `XdrUInt128Parts.forHiLo()` | `int, int` | `BigInt, BigInt` |
| `XdrInt256Parts.forHiHiHiLoLoHiLoLo()` | `int` params | `BigInt` params |
| `XdrUInt256Parts.forHiHiHiLoLoHiLoLo()` | `int` params | `BigInt` params |
| `revokeOfferSponsorship()` | `int offerId` | `BigInt offerId` |
| `AccountResponse.muxedAccountMed25519Id` | `int?` | `BigInt?` |
| `SubmitTransactionResponse.getOfferIdFromResult()` | Returns `int?` | Returns `BigInt?` |
| `SorobanAddressCredentials.nonce` | `int` | `BigInt` |
| `SorobanCredentials.forAddress()` | `int nonce` | `BigInt nonce` |
| `XdrLedgerKey.forOffer()` | `int offerId` | `BigInt offerId` |
| `XdrLedgerKeyOffer.forOfferId()` | `int offerId` | `BigInt offerId` |
| `XdrLedgerKey.getOfferOfferId()` | Returns `int?` | Returns `BigInt?` |

## Migration Patterns

### MemoId

```dart
// v2.x
MemoId(12345)
Memo.id(12345)

// v3.0.0
MemoId(BigInt.from(12345))
Memo.id(BigInt.from(12345))

// Reading memo ID
BigInt id = memo.id;  // Returns BigInt
```

### MuxedAccount

```dart
// v2.x
MuxedAccount(accountId, 12345)

// v3.0.0
MuxedAccount(accountId, BigInt.from(12345))

// Reading muxed account ID
BigInt? id = muxedAccount.id;  // Returns BigInt?
```

### Account (with muxed ID)

```dart
// v2.x
Account(accountId, sequenceNumber, muxedAccountMed25519Id: 12345)

// v3.0.0
Account(accountId, sequenceNumber, muxedAccountMed25519Id: BigInt.from(12345))
```

### AccountResponse.muxedAccountMed25519Id

```dart
// v2.x
accountResponse.muxedAccountMed25519Id = 12345;

// v3.0.0
accountResponse.muxedAccountMed25519Id = BigInt.from(12345);
```

### XdrInt64 / XdrUint64

```dart
// v2.x
XdrInt64(someIntValue)
XdrUint64(someIntValue)

// v3.0.0
XdrInt64(BigInt.from(someIntValue))
XdrUint64(BigInt.from(someIntValue))

// Reading values
BigInt value = xdrInt64.int64;      // Returns BigInt
int intValue = xdrInt64.int64.toInt(); // Convert to int if needed
```

### Soroban Contract Values (XdrSCVal)

```dart
// v2.x
XdrSCVal.forU64(12345)
XdrSCVal.forI64(-12345)
XdrSCVal.forTimepoint(1234567890)
XdrSCVal.forDuration(3600)

// v3.0.0
XdrSCVal.forU64(BigInt.from(12345))
XdrSCVal.forI64(BigInt.from(-12345))
XdrSCVal.forTimepoint(BigInt.from(1234567890))
XdrSCVal.forDuration(BigInt.from(3600))
```

### 128-bit and 256-bit Parts

```dart
// v2.x
XdrInt128Parts.forHiLo(0, 12345)
XdrUInt128Parts.forHiLo(0, 12345)

// v3.0.0
XdrInt128Parts.forHiLo(BigInt.zero, BigInt.from(12345))
XdrUInt128Parts.forHiLo(BigInt.zero, BigInt.from(12345))
```

### TimeBounds

```dart
// No change required - TimeBounds still accepts int parameters
// Internal conversion to BigInt is handled automatically
TimeBounds(minTime, maxTime)
```

### Revoke Offer Sponsorship

```dart
// v2.x
builder.revokeOfferSponsorship(accountId, 12345)

// v3.0.0
builder.revokeOfferSponsorship(accountId, BigInt.from(12345))
```

### Reading 64-bit Values from XDR

```dart
// v2.x
int fee = transaction.fee.int64;
int sequenceNumber = account.sequenceNumber.uint64;

// v3.0.0
BigInt fee = transaction.fee.int64;
BigInt sequenceNumber = account.sequenceNumber.uint64;

// If you need int (safe for values < 2^53)
int feeInt = transaction.fee.int64.toInt();
```

## Search and Replace Patterns

Use these patterns to find code that needs updating:

| Search | Replace |
|--------|---------|
| `MemoId(` | Check if parameter is int, wrap with `BigInt.from()` |
| `Memo.id(` | Check if parameter is int, wrap with `BigInt.from()` |
| `MuxedAccount(` + int parameter | Wrap int with `BigInt.from()` |
| `XdrInt64(` + int parameter | Wrap with `BigInt.from()` |
| `XdrUint64(` + int parameter | Wrap with `BigInt.from()` |
| `.forU64(` + int | Wrap int parameter with `BigInt.from()` |
| `.forI64(` + int | Wrap int parameter with `BigInt.from()` |
| `.forHiLo(` + int | Wrap int parameters with `BigInt.from()` |
| `.int64` used as int | Add `.toInt()` or change variable type to BigInt |
| `.uint64` used as int | Add `.toInt()` or change variable type to BigInt |

## Common Errors After Migration

### Type Error: int vs BigInt

```
Error: The argument type 'int' can't be assigned to the parameter type 'BigInt'
```

**Fix:** Wrap int values with `BigInt.from()`:
```dart
MemoId(BigInt.from(12345))
```

### Comparison Errors

```dart
// This will fail - comparing BigInt with int
if (memo.id == 12345) { }

// Fix: Compare with BigInt
if (memo.id == BigInt.from(12345)) { }
```

### Integer Overflow on Web

If you see unexpected values on web but correct values on mobile/desktop, check for places where you're using `.toInt()` on values that might exceed 2^53.

## Testing Your Migration

1. Run static analysis to catch type errors:
   ```bash
   dart analyze
   ```

2. Run tests on native:
   ```bash
   flutter test
   ```

3. Run tests on web (Chrome):
   ```bash
   flutter test --platform chrome
   ```

## Questions?

If you encounter issues during migration, please open a discussion at:
https://github.com/Soneso/stellar_flutter_sdk/discussions
