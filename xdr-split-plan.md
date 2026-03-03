# Plan: Split XDR Files into One-File-Per-Type

## Context

The Stellar Flutter SDK is migrating its XDR code generation to an xdrgen-based approach (matching Python/Java SDKs). As a prerequisite, we need to split ~376 XDR classes from 21 domain-grouped files into individual files. This creates a 1:1 baseline for comparing generated output and enables incremental migration. Classes with custom helper methods get an inheritance wrapper pattern so custom code survives regeneration.

## Overview

- Split 20 XDR files (excluding `xdr_data_io.dart`) into ~378 individual type files
- Create base+wrapper pairs for ~32 classes with custom helper methods
- Create a barrel file (`xdr.dart`) and update all SDK imports
- Automate via a Python script (`tools/split_xdr.py`)

## Phase 0: Build the Python Extraction Script

Create `tools/split_xdr.py` with these stages:

### 0.1 Parse XDR files
- Read each of the 20 XDR source files in `lib/src/xdr/`
- Find class boundaries using regex `^class (\w+)` + brace-depth tracking — **not** `^class Xdr`. Two classes in `xdr_trustline.dart` lack the `Xdr` prefix: `TrustLineEntryExtensionV2` (line 231) and `TrustLineEntryExtensionV2Ext` (line 257, a version-union with `int _v`). The discovery regex must match ALL classes.
- Extract each class body with its full text

### 0.2 Build dependency graph
- For each class, scan its body for `Xdr\w+` references
- Map each reference to the file it will live in after splitting
- Also detect external imports needed: `dart:typed_data`, `dart:convert`, `key_pair.dart`, `soroban_auth.dart`, `package:pinenacl/api.dart`, `util.dart`, `constants/bit_constants.dart`, etc.
- **Import target rule:** Any call to a wrapper-only method (factory, custom getter, convenience method) from another class requires importing the **wrapper** file, not the base. The dependency graph must maintain a registry of which methods live in wrappers and resolve all references accordingly. This applies both to cross-type references within base files and wrapper-to-wrapper dependencies.

### 0.3 Classify classes
- **Wrapper-needed** (~32 classes): Have custom factory methods, computed properties, SDK-dependent helpers, or base64 convenience methods
- **Version-union** (~27 classes): Classes that use a raw `int` discriminant (`int _v`) instead of an XDR enum type. This is the standard pattern for all XDR `union switch (v)` extension points (e.g., `XdrTransactionMeta`, `XdrTransactionExt`, `XdrAccountEntryExt`, `XdrStellarValueExt`, etc.). These need a separate `decodeAs` template where the constructor takes `int` and decode reads `stream.readInt()` directly. None of these ~27 classes have custom methods requiring wrappers (confirmed by audit) — they are all trivially empty or single-version switches. They are a subset of "plain" for wrapper purposes but need the version-union decode template.
- **Plain** (~345 classes): Just encode/decode, one file each

### 0.3.1 Detect per-class accessor style
The script must detect the discriminant accessor style for each union class by scanning the actual source — **not by assuming a default**. The four patterns found in the codebase:

- **`get discriminant => this._type`** — many classes across all files
- **`get type => this._type`** — dominant pattern for contract-domain union types (~12+ classes including `XdrSorobanCredentials`, `XdrSCError`, `XdrContractExecutable`, `XdrContractIDPreimage`, `XdrHostFunction`, `XdrSorobanAuthorizedFunction`, etc.). Their `encode()` bodies use `encoded.type.value`, not `encoded.discriminant.value`. Note: `XdrSCSpecTypeDef` is NOT in this group — despite being in the contract domain, it uses `get discriminant =>` (see first group above).
- **`get discriminant => this._kind`** — 4 classes: `XdrSCEnvMetaEntry`, `XdrSCMetaEntry`, `XdrSCSpecUDTUnionCaseV0`, `XdrSCSpecEntry`. These use `_kind` as the backing field name, not `_type`.
- **`get discriminant => this._code`** — 29 result-code union classes across `xdr_account.dart`, `xdr_contract.dart`, `xdr_operation.dart`, `xdr_offer.dart`, `xdr_payment.dart`, `xdr_transaction.dart`, `xdr_trustline.dart`. These are all `*Result` types dispatching on a result code enum.
- **`get discriminant => this._effect`** — 1 class: `XdrManageOfferSuccessResultOffer` in `xdr_offer.dart` (line 369). Uses `XdrManageOfferEffect _effect`.
- **`getDiscriminant()` method** — `XdrPublicKey` only. Uses method-accessor style instead of property syntax.
- **`int _v` with `get discriminant => this._v`** — ~27 version-union extension-point classes (see §0.3), plus `TrustLineEntryExtensionV2Ext` in `xdr_trustline.dart` which lacks the `Xdr` prefix.

**Detection approach:** The script should regex-match `get (discriminant|type) => this\.(_\w+)` to capture both the accessor name and the backing field name per class. **Secondary validation required:** After matching, verify the class is actually a union type by checking that its `encode()` or `decode()` body contains a `switch (` statement. Four plain data classes in `xdr_contract.dart` have `get type =>` getters that are ordinary data fields, not union discriminants: `XdrSCSpecUDTStructFieldV0` (line 2314), `XdrSCSpecUDTUnionCaseTupleV0` (line 2413), `XdrSCSpecFunctionInputV0` (line 2731), `XdrSCSpecEventParamV0` (line 2897). Without the secondary check, the script would incorrectly generate union-style `decodeAs<T>` code for these plain classes, causing compile errors.

For `XdrPublicKey`, detect `getDiscriminant()` method style. For `int _v` classes, detect that the backing field type is `int` rather than an XDR enum type. The `encode()` and `decode()` templates must use the **actual accessor name** found in each class (`encoded.type.value` vs `encoded.discriminant.value`).

### 0.4 Generate files
For each class, generate `lib/src/xdr/xdr_<snake_case_name>.dart`

**Naming convention:** Strip `Xdr` prefix (if present), convert to snake_case, add `xdr_` prefix. If the class name does not start with `Xdr`, convert the full name to snake_case and prepend `xdr_`.
- `XdrSCVal` → `xdr_sc_val.dart`
- `XdrAssetType` → `xdr_asset_type.dart`
- `XdrInt128Parts` → `xdr_int128_parts.dart`
- `TrustLineEntryExtensionV2` → `xdr_trust_line_entry_extension_v2.dart` (no `Xdr` prefix to strip)
- `TrustLineEntryExtensionV2Ext` → `xdr_trust_line_entry_extension_v2_ext.dart`

### 0.5 Generate barrel file
Create `lib/src/xdr/xdr.dart` exporting all individual files plus `xdr_data_io.dart`.

### 0.6 Generate import update script
Produce sed/patch commands to update all SDK consumer imports.

## Phase 1: Execute the Split

The split proceeds one source file at a time with verification after every batch of ~5 generated files. This catches issues early when the scope is small and easy to debug.

### 1.1 Processing order
Process source files from smallest to largest, starting with simpler files that have no wrapper classes:
1. `xdr_error.dart` (2 classes)
2. `xdr_memo.dart` (3 classes)
3. `xdr_bucket.dart` (5 classes)
4. `xdr_data_entry.dart` (7 classes)
5. `xdr_network.dart` (8 classes)
6. `xdr_auth.dart` (9 classes)
7. `xdr_scp.dart` (13 classes)
8. `xdr_history.dart` (14 classes)
9. `xdr_other.dart` (15 classes)
10. `xdr_payment.dart` (17 classes)
11. `xdr_signing.dart` (18 classes)
12. `xdr_offer.dart` (19 classes)
13. `xdr_trustline.dart` (22 classes, includes 2 non-`Xdr`-prefixed classes)
14. `xdr_type.dart` (19 classes, includes `XdrPublicKey` wrapper)
15. `xdr_asset.dart` (7 classes, includes inheritance chain + downcast)
16. `xdr_operation.dart` (32 classes)
17. `xdr_account.dart` (56 classes, includes `XdrAccountID` + `XdrMuxedAccountMed25519` wrappers)
18. `xdr_transaction.dart` (59 classes, 8 wrapper-needing classes)
19. `xdr_ledger.dart` (64 classes, `XdrLedgerKey` + base64 wrappers)
20. `xdr_contract.dart` (68 classes, most complex wrappers)

### 1.2 Incremental review cycle
After generating files from each source file (or every ~5 generated files, whichever is smaller):

```bash
dart analyze lib/src/xdr/
```

If analysis fails, fix the issue before proceeding to the next source file. This keeps the blast radius small — at most ~5 files to inspect rather than ~412.

For source files containing wrapper classes (files 14–20), also verify that:
- Base file compiles independently
- Wrapper file compiles and references the base correctly
- Cross-type imports point to wrappers (not bases) where needed

### 1.3 Full XDR verification
After all 20 source files are processed:
```bash
dart analyze lib/src/xdr/
```

### 1.4 Generate barrel file
Create `lib/src/xdr/xdr.dart` exporting all ~412 individual files plus `xdr_data_io.dart`.

### 1.5 Update consumer imports
- In `lib/stellar_flutter_sdk.dart`: Replace 21 XDR exports with `export 'src/xdr/xdr.dart';`
- In `lib/src/*.dart` (~40 files, ~155 imports): Replace individual XDR imports with `import 'xdr/xdr.dart';` (relative) or `import 'package:stellar_flutter_sdk/src/xdr/xdr.dart';` (package-style, matching original)
- In `test/*.dart` (~5 imports): Update similarly
- **Within XDR type files**: Import specific types they depend on (NOT the barrel, to avoid cycles)

### 1.6 Verify full project compiles
```bash
dart analyze
```

### 1.7 Run tests (old + new files coexist)
```bash
dart test
```
Running tests while old files still exist ensures we can recover easily if anything fails.

## Phase 2: Delete Old Files

After all verification gates pass, delete the original 20 multi-class XDR files. Keep only `xdr_data_io.dart`.

Final verification:
```bash
dart analyze && dart test
```

## Rollback Strategy

All work happens on the `xdr-gen2` branch. If any phase fails:
- **Phase 1 fails:** Delete generated files, fix the script, re-run
- **Phase 2 fails post-deletion:** `git checkout -- lib/src/xdr/` restores old files
- **Worst case:** `git reset --hard` to the pre-split commit

Phase 2 (deletion) should be a separate commit from Phase 1 (generation + import updates), so each can be reverted independently.

## Inheritance Wrapper Pattern

### For union types (discriminant + switch-based decode):

```dart
// xdr_sc_val_base.dart (replaceable by generator)
class XdrSCValBase {
  XdrSCValType _type;
  XdrSCValType get discriminant => this._type;
  // ... all fields, getters, setters

  XdrSCValBase(this._type);

  static void encode(XdrDataOutputStream stream, XdrSCValBase val) { ... }

  static T decodeAs<T extends XdrSCValBase>(
    XdrDataInputStream stream,
    T Function(XdrSCValType) constructor,
  ) {
    T decoded = constructor(XdrSCValType.decode(stream));
    switch (decoded._type) { /* populate fields */ }
    return decoded;
  }

  static XdrSCValBase decode(XdrDataInputStream stream) {
    return decodeAs(stream, XdrSCValBase.new);
  }
}
```

```dart
// xdr_sc_val.dart (hand-maintained, survives regeneration)
class XdrSCVal extends XdrSCValBase {
  XdrSCVal(XdrSCValType type) : super(type);

  static void encode(XdrDataOutputStream stream, XdrSCVal val) {
    XdrSCValBase.encode(stream, val);
  }

  static XdrSCVal decode(XdrDataInputStream stream) {
    return XdrSCValBase.decodeAs(stream, XdrSCVal.new);
  }

  // Custom methods preserved here
  static XdrSCVal forBool(bool value) { ... }
  String toBase64EncodedXdrString() { ... }
}
```

### For sequential types (multi-field constructor):

```dart
// xdr_account_id_base.dart (replaceable by generator)
class XdrAccountIDBase {
  XdrPublicKey _accountID;
  // ... getters, setters, encode, decode
}
```

```dart
// xdr_account_id.dart (hand-maintained)
class XdrAccountID extends XdrAccountIDBase {
  XdrAccountID(XdrPublicKey accountID) : super(accountID);

  static void encode(XdrDataOutputStream stream, XdrAccountID val) {
    XdrAccountIDBase.encode(stream, val);
  }

  static XdrAccountID decode(XdrDataInputStream stream) {
    return XdrAccountID(XdrPublicKey.decode(stream));
  }

  // Custom method
  static XdrAccountID forAccountId(String accountId) { ... }
}
```

### Other types reference the wrapper, not the base:

```dart
// xdr_account_entry.dart
import 'xdr_account_id.dart';  // imports wrapper, NOT base
// Uses XdrAccountID.decode(stream) → returns XdrAccountID (correct type)
```

## Classes Needing Wrappers

### Union types with `decodeAs` pattern (~13):
| Class | Source File | Custom Methods |
|-------|------------|---------------|
| XdrPublicKey | `xdr_type.dart` | `forAccountId()` |
| XdrSCVal | `xdr_contract.dart` | 30+ factories, BigInt helpers, base64 |
| XdrSCAddress | `xdr_contract.dart` | `forAccountId()`, `forContractId()`, `forClaimableBalanceId()`, `forLiquidityPoolId()`, `toStrKey()` (instance) |
| XdrSCSpecTypeDef | `xdr_contract.dart` | 25 factories |
| XdrHostFunction | `xdr_contract.dart` | 7 factories |
| XdrContractExecutable | `xdr_contract.dart` | `forWasm()`, `forAsset()` |
| XdrContractIDPreimage | `xdr_contract.dart` | `forAddress()`, `forAsset()` |
| XdrSorobanCredentials | `xdr_contract.dart` | 2 factories |
| XdrSorobanAuthorizedFunction | `xdr_transaction.dart` | 3 factories (`forInvokeContractArgs`, `forCreateContractArgs`, `forCreateContractArgsV2`) |
| XdrLedgerKey | `xdr_ledger.dart` | 10+ factories, getters, base64 |
| XdrClaimableBalanceID | `xdr_ledger.dart` | `forId()`, `claimableBalanceIdString` getter (uses `Util.bytesToHex`) |
| XdrTrustlineAsset | `xdr_asset.dart` | `fromXdrAsset()` (also extends XdrAsset) |
| XdrChangeTrustAsset | `xdr_asset.dart` | `fromXdrAsset()` (also extends XdrAsset) |

**Note:** The script must discover class locations by scanning all source files, not by assumption. Classes like `XdrSorobanAuthorizedFunction` live in `xdr_transaction.dart`, not `xdr_contract.dart` despite the Soroban prefix.

### Sequential types with simple decode override (~8):
| Class | Source File | Custom Methods |
|-------|------------|---------------|
| XdrAccountID | `xdr_account.dart` | `forAccountId()` |
| XdrMuxedAccountMed25519 | `xdr_account.dart` | `encodeInverted()`, `decodeInverted()`, `accountId` getter |
| XdrInt128Parts | `xdr_contract.dart` | `forHiLo()` |
| XdrUInt128Parts | `xdr_contract.dart` | `forHiLo()` |
| XdrInt256Parts | `xdr_contract.dart` | `forHiHiHiLoLoHiLoLo()` |
| XdrUInt256Parts | `xdr_contract.dart` | `forHiHiHiLoLoHiLoLo()` |
| XdrLedgerKeyOffer | `xdr_ledger.dart` | `forOfferId()` |
| XdrLedgerKeyData | `xdr_ledger.dart` | `forDataName()` |

### Base64/envelope-only (~11, ALSO need wrappers):
| Class | Source File | Custom Methods |
|-------|------------|---------------|
| XdrTransactionMeta | `xdr_transaction.dart` | base64 pair |
| XdrTransactionEvent | `xdr_transaction.dart` | base64 pair |
| XdrDiagnosticEvent | `xdr_transaction.dart` | base64 pair |
| XdrSorobanTransactionData | `xdr_transaction.dart` | base64 pair |
| XdrContractEvent | `xdr_transaction.dart` | base64 pair |
| XdrTransactionResult | `xdr_transaction.dart` | base64 pair |
| XdrTransactionEnvelope | `xdr_transaction.dart` | `fromEnvelopeXdrString()`, `toEnvelopeXdrBase64()` (non-standard naming) |
| XdrLedgerEntry | `xdr_ledger.dart` | base64 pair |
| XdrLedgerEntryData | `xdr_ledger.dart` | base64 pair |
| XdrLedgerEntryChanges | `xdr_ledger.dart` | base64 pair |
| XdrLedgerFootprint | `xdr_contract.dart` | base64 pair |

**Note on non-standard naming:** `XdrTransactionEnvelope` uses `fromEnvelopeXdrString()`/`toEnvelopeXdrBase64()` instead of the standard `from/toBase64EncodedXdrString()`. The script's custom-method classifier must detect `from*`/`to*` methods beyond the standard names, not rely on exact string matching.

**Note:** Initially classified as "no wrapper needed" assuming the generator would produce base64 methods. After review, xdrgen does NOT generate `toBase64EncodedXdrString()`/`fromBase64EncodedXdrString()` — these are SDK convenience methods, not XDR protocol methods. These 11 classes need wrappers to preserve the base64/envelope API. This increases the wrapper count to ~32.

## Special Cases

### XdrTrustlineAsset / XdrChangeTrustAsset (existing inheritance)
Three-level chain: `XdrAsset → XdrTrustlineAssetBase → XdrTrustlineAsset`
- **XdrAsset is "plain with downcast reference"** — it has no custom helper methods, but its `encode()` body contains `is XdrChangeTrustAsset` runtime type check and calls `XdrChangeTrustAsset.encode()`. This means `xdr_asset.dart` must import the `XdrChangeTrustAsset` **wrapper** file, creating a dependency on a subclass. The class cannot be regenerated without awareness of its subclasses. The script must handle this as a special case: `XdrAsset` gets no wrapper (no custom methods), but its generated file must import the wrapper for `XdrChangeTrustAsset`.
- XdrTrustlineAssetBase extends XdrAsset (generated, replaceable)
- XdrTrustlineAsset extends XdrTrustlineAssetBase (wrapper with `fromXdrAsset()`)
- **Circular import:** `xdr_asset.dart` must import `xdr_change_trust_asset.dart` (for the `is XdrChangeTrustAsset` check + `XdrChangeTrustAsset.encode()` call), and `xdr_change_trust_asset_base.dart` imports `xdr_asset.dart` (extends XdrAsset). This bidirectional dependency is intentional and works in Dart. The script must import the **wrapper** file, not the base, so `is XdrChangeTrustAsset` resolves the full inheritance chain.
- **Resolution order:** The script must generate files in dependency order: `xdr_asset.dart` first, then `xdr_trustline_asset_base.dart` / `xdr_change_trust_asset_base.dart`, then the wrappers. This ensures no forward references during analysis passes.

### XdrPublicKey (method-accessor style)
`XdrPublicKey` uses `getDiscriminant()`/`setEd25519()` method accessors rather than the `_field` property pattern used by other union types. The script must handle this class with care when generating the `decodeAs` pattern — the decode logic accesses `_ed25519` directly, which is legal within the same library file. Manually verify the generated base file compiles.

### Version-union classes with `int _v` discriminant (~27 classes)
~27 classes use a raw `int` discriminant (`int _v`) instead of an XDR enum type. This is the standard pattern for all XDR `union switch (v)` extension points. Examples: `XdrTransactionMeta`, `XdrTransactionExt`, `XdrFeeBumpTransactionExt`, `XdrTransactionV0Ext`, `XdrSorobanTransactionMetaExt`, `XdrContractEventBody`, `XdrSorobanTransactionDataExt`, `XdrTransactionResultExt`, `XdrStellarValueExt`, `XdrDataEntryExt`, `XdrAccountEntryExt`, and many more across `xdr_account.dart`, `xdr_ledger.dart`, `xdr_trustline.dart`, `xdr_offer.dart`, `xdr_history.dart`, and `xdr_other.dart`.

The standard `decodeAs<T>` template assumes the discriminant is an XDR enum with its own `decode()`. For these classes, the script must generate a variant where:
- The constructor takes `int` instead of an enum type
- The decode reads `stream.readInt()` directly instead of calling `EnumType.decode(stream)`
- The switch cases are `case 0:`, `case 1:`, etc. instead of enum constants

The script must detect `int` discriminant fields automatically by checking the backing field's declared type. None of these ~27 classes have custom methods requiring wrappers — they are all trivially empty or single-version switches, so they remain in the "plain" category for wrapper purposes.

### XdrMuxedAccountMed25519.encodeInverted() / decodeInverted()
Both `encodeInverted()` and `decodeInverted()` are wrapper-only custom methods, but they are called from OTHER classes' encode/decode methods (e.g., `XdrSCAddress.decode()`). The dependency graph must track that references to `XdrMuxedAccountMed25519.encodeInverted()` or `decodeInverted()` require importing the wrapper, not the base.

### xdr_data_io.dart — keep unchanged
Hand-written I/O infrastructure. All type files import it.

### XdrSCVal private helpers
`_bigIntToFixedBytes`, `_bigIntFrom128Parts`, etc. move to the wrapper class (they're only used by custom factory methods).

### SDK-dependent imports stay in wrappers only
`KeyPair`, `StrKey`, `Address`, `Util` imports go in wrapper files, not bases. Bases have zero SDK dependencies — only XDR type imports and `dart:typed_data`.

### Base files must import wrappers for cross-type decode calls
When a base file's `decode()` body calls another type's `decode()`, it must call the **wrapper's** `decode()` (not the base's) for any type that has a wrapper. Example: `XdrSCValBase.decode()` calls `XdrSCAddress.decode(stream)` for the `SCV_ADDRESS` case — this must import `xdr_sc_address.dart` (wrapper), not `xdr_sc_address_base.dart`. This ensures the returned object is the correct wrapper type. The "bases have zero SDK dependencies" principle refers to SDK-layer code (`KeyPair`, `Util`, etc.) — importing other XDR wrapper files is allowed and necessary.

## Critical Files

- `lib/src/xdr/xdr_contract.dart` — largest file (68 classes, 3940 lines), most complex wrappers
- `lib/src/xdr/xdr_ledger.dart` — second largest (64 classes, 3884 lines)
- `lib/src/xdr/xdr_transaction.dart` — third largest (59 classes, 2745 lines), contains `XdrTransactionMeta`, `XdrTransactionEnvelope`, `XdrSorobanAuthorizedFunction`, `XdrContractEvent`, `XdrTransactionEvent`, `XdrDiagnosticEvent`, `XdrSorobanTransactionData`, `XdrTransactionResult` — 8 wrapper-needing classes
- `lib/src/xdr/xdr_asset.dart` — existing inheritance chain needing three-level handling, "plain with downcast" pattern
- `lib/stellar_flutter_sdk.dart` — barrel exports (lines 132-153) to update
- `lib/src/xdr/xdr_data_io.dart` — infrastructure, keep unchanged

## Verification

After each phase:
1. `dart analyze lib/src/xdr/` — XDR files compile
2. `dart analyze` — full project compiles
3. `dart test` — all tests pass
4. **File count gate:** Verify the generated file count matches expectations. The script should print a summary: N plain files, N base files, N wrapper files, N total. If the count deviates from the expected ~412 (346 plain + 32 base + 32 wrapper + 1 barrel + 1 data_io), investigate before proceeding. The authoritative count should be obtained by running `grep -c '^class ' lib/src/xdr/*.dart` before the split and verifying the output file count matches.

## File Count After Split

- ~346 plain type files (includes 2 non-`Xdr`-prefixed classes: `TrustLineEntryExtensionV2`, `TrustLineEntryExtensionV2Ext`)
- ~32 base files (`*_base.dart`)
- ~32 wrapper files
- 1 barrel file (`xdr.dart`)
- 1 infrastructure file (`xdr_data_io.dart`, unchanged)
- **Total: ~412 files** in `lib/src/xdr/`

## Barrel File Maintenance

The barrel file `lib/src/xdr/xdr.dart` must be kept in sync with the actual files:
- The Python script generates it automatically during Phase 1
- When the xdrgen generator replaces base files later, it must also regenerate the barrel
- The barrel exports wrapper files (not base files) for classes that have wrappers — this ensures consumers get the correct type with custom methods
- Both base and wrapper files are exported for wrapper classes (base for internal use, wrapper as the public API name)

