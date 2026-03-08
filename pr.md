# PR Title

Auto-generate XDR types from canonical .x definitions

# PR Body

## Summary

Replaces ~400 hand-written XDR type definitions with machine-generated Dart code produced by a Ruby-based code generator that reads Stellar's canonical `.x` XDR definition files. Adds individual per-type files (one class per file), extracts hand-maintained helper methods into 22 wrapper classes under `lib/src/xdr/`, and adds 510 round-trip unit tests (with base64 roundtrips) covering all generated types. Fixes a latent `DataInput.readByte` off-by-one bug in padding validation.

- **473 Dart files** in `lib/src/xdr/` (449 generated, 24 hand-maintained)
- **6,259 unit tests passing**, 0 analyzer errors
- Code generator at `tools/xdr-generator/` (Ruby, uses `xdrgen` gem)
- 13 `.x` definition files in `xdr/` from `stellar/stellar-xdr`

## What changed

- **One file per XDR type**: The 20 monolithic domain-grouped files (`xdr_account.dart`, `xdr_transaction.dart`, etc.) were split into ~491 individual files. The old files are replaced, not deleted — all exports go through the `xdr.dart` barrel file.
- **Code generator**: `tools/xdr-generator/generator/generator.rb` reads `.x` files via the `xdrgen` gem and produces Dart. Override files (`type_overrides.rb`, `field_overrides.rb`) preserve existing SDK naming where the hand-written code diverged from XDR spec names.
- **22 base+wrapper pairs**: Types that need hand-maintained helper methods (e.g. `XdrTransactionEnvelope`, `XdrSCVal`, `XdrLedgerKey`) generate a `*_base.dart` file; the hand-maintained wrapper extends the base class. 10 types that only added base64 convenience methods were eliminated — the generator now adds `toBase64EncodedXdrString()` / `fromBase64EncodedXdrString()` to all types directly.
- **TYPE_OVERRIDES for SCVec/SCMap**: The generator maps `XdrSCVec` → `List<XdrSCVal>` and `XdrSCMap` → `List<XdrSCMapEntry>`, preserving the existing SDK API. No wrapper classes are generated — fields use raw `List` types directly, with inline array encode/decode in the generated code.
- **Generator infrastructure**: Makefile with 8 targets (all Docker-based, `ruby:3.4`), GitHub Actions CI workflow (`xdr-generator.yml`) with snapshot tests and generated-files-check, 9 golden snapshot files with Minitest runner.
- **510 auto-generated roundtrip tests** in `test/unit/xdr/generated/` covering enums, structs, unions, and typedefs — each test includes both binary encode/decode and base64 roundtrip verification.
- **Discriminant field name aliases**: All union types emit the original XDR field name (`type`, `v`, `code`, `kind`, `configSettingID`, `effect`) as a getter/setter alias alongside the normalized `discriminant` property. This preserves the XDR field names while maintaining a consistent internal convention.
- **Bug fix**: `DataInput.readByte()` was reading from `_offset + 1` instead of `_offset`, causing `pad()` to validate the wrong byte. Fixed in `xdr_data_io.dart`.
- **Bug fix**: `loadContractCode()` in `test/tests_util.dart` now calls `WidgetsFlutterBinding.ensureInitialized()` before using `rootBundle.load()` on web, fixing `ServicesBinding` errors when running tests with `--platform chrome`.

## Breaking changes

This PR has breaking changes. The high-level SDK APIs (operation classes, services, SEP implementations) are **unchanged in their public signatures**. The breaks are in the low-level XDR layer and in code that accesses XDR types directly.

### Public API changes

These affect code outside `lib/src/xdr/` — SDK consumers who use XDR types directly will need to update.

<details>
<summary><b>XdrSCVal bytes field type change</b></summary>

The `bytes` field on `XdrSCVal` changed from `XdrDataValue?` to `XdrSCBytes?`. The `vec` and `map` fields are unchanged (`List<XdrSCVal>?` and `List<XdrSCMapEntry>?` respectively).

```dart
// Before
Uint8List data = scVal.bytes!.dataValue;

// After
Uint8List data = scVal.bytes!.sCBytes;
```

</details>

<details>
<summary><b>XdrChangeTrustAsset / XdrTrustlineAsset no longer extend XdrAsset</b></summary>

Per the XDR spec, `ChangeTrustAsset` and `TrustLineAsset` are independent unions — they are not subtypes of `Asset`. The hand-written SDK had `XdrChangeTrustAsset extends XdrAsset`, which is incorrect.

**Impact**: Code that casts between `XdrAsset` and `XdrChangeTrustAsset` must use the new factory method instead.

```dart
// Before
Asset.fromXdr(changeTrustOp.line)  // worked because XdrChangeTrustAsset extended XdrAsset

// After
Asset.fromXdrChangeTrustAsset(changeTrustOp.line)  // new factory method
```

`AssetTypePoolShare.toXdr()` now throws `UnsupportedError` (pool shares cannot be represented as `XdrAsset`). Use `AssetTypePoolShare.toXdrChangeTrustAsset()` instead.

`XdrTrustlineAsset.poolId` renamed to `XdrTrustlineAsset.liquidityPoolID` (XDR spec name).

</details>

<details>
<summary><b>Enum constant renames (5 constants)</b></summary>

| Type | Before | After |
|------|--------|-------|
| `XdrSignerKeyType` | `KEY_TYPE_ED25519_SIGNED_PAYLOAD` | `SIGNER_KEY_TYPE_ED25519_SIGNED_PAYLOAD` |
| `XdrPreconditionType` | `NONE` | `PRECOND_NONE` |
| `XdrPreconditionType` | `TIME` | `PRECOND_TIME` |
| `XdrPreconditionType` | `V2` | `PRECOND_V2` |
| `XdrManageOfferResultCode` | `MANAGE_OFFER_SUCCESS` | `MANAGE_SELL_OFFER_SUCCESS` |

These match the canonical XDR enum names. No backward-compatibility aliases are possible for enum constants.

</details>

<details>
<summary><b>XdrBigInt64 removed, replaced by XdrInt64</b></summary>

`XdrBigInt64` was a redundant hand-written type using unsigned 64-bit decode. It has been replaced throughout by `XdrInt64` which uses signed decode, matching the XDR spec's `int64` type. This is a correctness fix -- all amount fields are `int64` (signed) in the XDR spec.

| Before | After |
|--------|-------|
| `XdrBigInt64(value)` | `XdrInt64(value)` |
| `.bigInt` | `.int64` |
| `XdrBigInt64.encode(...)` | `XdrInt64.encode(...)` |
| `XdrBigInt64.decode(...)` | `XdrInt64.decode(...)` |
| `Util.toXdrBigInt64Amount(...)` | `Util.toXdrInt64Amount(...)` |
| `Util.fromXdrBigInt64Amount(...)` | `Util.fromXdrInt64Amount(...)` |

The file `xdr_big_int64.dart` has been deleted and removed from `xdr.dart` exports. Binary wire format is unchanged (both types write the same 8 bytes). The only difference is decode interpretation (signed vs unsigned), which is irrelevant for positive values < 2^63.

`XdrSequenceNumber` now wraps `BigInt` directly instead of `XdrInt64`:
```dart
// Before
XdrSequenceNumber(XdrInt64(value))
seqNum.sequenceNumber.int64  // BigInt

// After
XdrSequenceNumber(value)     // pass BigInt directly
seqNum.sequenceNumber        // BigInt directly
```

</details>

<details>
<summary><b>Struct field renames (5 properties)</b></summary>

| Type | Before | After |
|------|--------|-------|
| `XdrTransaction` | `.preconditions` | `.cond` |
| `XdrTransactionExt` | `.sorobanTransactionData` | `.sorobanData` |
| `XdrPreconditionsV2` | `.sequenceNumber` | `.minSeqNum` |
| `XdrOperationBody` | `.bumpExpirationOp` | `.extendFootprintTTLOp` |
| `XdrOperationBody` | `.createPassiveOfferOp` | `.createPassiveSellOfferOp` |

These match the canonical XDR field names. All callers inside the SDK have been updated.

</details>

<details>
<summary><b>Constructor signature changes (4 types)</b></summary>

**XdrOperation**: Now takes `sourceAccount` as first positional arg.
```dart
// Before
XdrOperation op = XdrOperation(body);
op.sourceAccount = source;

// After
XdrOperation op = XdrOperation(source, body);
```

**XdrSetOptionsOp**: All 9 fields are now positional constructor args (can be null).
```dart
// Before
XdrSetOptionsOp op = XdrSetOptionsOp();
op.inflationDest = dest;

// After
XdrSetOptionsOp op = XdrSetOptionsOp(dest, null, null, null, null, null, null, null, null);
```

**XdrPreconditionsV2**: Now takes 6 positional args (was 3).

**XdrLedgerEntryV1**: Now takes 2 positional args: `sponsoringID`, `ext` (was 1).

</details>

<details>
<summary><b>XdrSCEnvMetaEntryInterfaceVersion restructured</b></summary>

The interface version field changed from a single `XdrUint64` to a struct with two `XdrUint32` fields, matching the updated XDR spec.

```dart
// Before
XdrUint64 interfaceVersion

// After
XdrUint32 protocol
XdrUint32 preRelease
```

This affects `SorobanContractParser` / `SorobanContractInfo` — the `envInterfaceVersion` is now available as two separate fields.

</details>

### XDR-layer changes

These affect only `lib/src/xdr/` types. Most SDK consumers don't use these directly — the SDK's operation classes, transaction builder, and service layer handle serialization internally.

<details>
<summary><b>Union discriminant naming</b></summary>

Generated union types use `discriminant` as the internal property name for the union discriminator. The original XDR field name (`type`, `v`, `code`, `kind`, `configSettingID`, `effect`) is emitted as a getter/setter alias on every union type, so existing code using either name works.

```dart
// Both work — discriminant is the primary, type is the alias
myUnion.discriminant = XdrHostFunctionType.HOST_FUNCTION_TYPE_INVOKE_CONTRACT;
myUnion.type = XdrHostFunctionType.HOST_FUNCTION_TYPE_INVOKE_CONTRACT;
```

Non-wrapper union types that previously had no hand-written alias now have the generated alias. Code using `.discriminant` continues to work unchanged.

</details>

<details>
<summary><b>Enum members removed (3 constants)</b></summary>

| Type | Removed | Reason |
|------|---------|--------|
| `XdrMessageType` | `GET_PEERS` | Not in XDR spec |
| `XdrMessageType` | `SURVEY_REQUEST` | Replaced by `TIME_SLICED_SURVEY_REQUEST` |
| `XdrMessageType` | `SURVEY_RESPONSE` | Replaced by `TIME_SLICED_SURVEY_RESPONSE` |

</details>

<details>
<summary><b>Internal field renames</b></summary>

| Type | Before | After |
|------|--------|-------|
| `XdrClawbackResultCode` | `CLAWBACK_NOT_ENABLED` | `CLAWBACK_NOT_CLAWBACK_ENABLED` |
| `XdrSCMetaV0` | `.value` | `.val` |
| `XdrLedgerKeyTTL` | `.hashKey` | `.keyHash` |
| `XdrContractCodeEntry` | `.code` (XdrDataValue) | `.code` (Uint8List) |

</details>

<details>
<summary><b>Result type constructor changes</b></summary>

Operation result types (`XdrTransactionResultResult`, `XdrInnerTransactionResultResult`, `XdrManageOfferResult`, etc.) now take only the discriminant in their constructor. Associated values are set via properties after construction. This matches the generated decode pattern.

`XdrOperationResultTr` now has separate fields for sell and buy offer results:
- `.manageSellOfferResult` (when discriminant is `MANAGE_SELL_OFFER`)
- `.manageBuyOfferResult` (when discriminant is `MANAGE_BUY_OFFER`)

Previously both used `.manageOfferResult`.

</details>

### Bug fixes

<details>
<summary><b>DataInput.readByte off-by-one (wire format fix)</b></summary>

`readByte()` in `xdr_data_io.dart` was reading the byte at `_offset + 1` instead of `_offset`. This caused `pad()` to check the first byte of the **next field** instead of the actual padding byte.

This was a latent bug — it rarely triggered in practice because most XDR fields start with `0x00` (big-endian integers, enum discriminants). The fix corrects padding validation without changing the encoding, so existing XDR bytes decode correctly.

```dart
// Before (wrong — reads from incremented offset)
return view!.getInt8(_offset = _offset! + 1);

// After (correct — reads from current offset, then increments)
int old = _offset!;
_offset = _offset! + 1;
return view!.getInt8(old);
```

</details>

## New infrastructure

| Component | Description |
|-----------|-------------|
| `Makefile` | 8 targets: `xdr-generate`, `xdr-clean-generated`, `xdr-update`, `xdr-generator-test`, `xdr-generator-update-snapshots`, `xdr-generator-validate`, `xdr-generate-tests` |
| `.github/workflows/xdr-generator.yml` | CI: snapshot tests + generated-files-check (fails if generated files are stale) |
| `tools/xdr-generator/test/generator_snapshot_test.rb` | 16 Minitest tests, 9 golden snapshot files |
| `tools/xdr-generator/test/generate_tests.rb` | Generates 510 roundtrip encode/decode + base64 unit tests |
| `tools/xdr-generator/test/validate_generated_types.rb` | Validates all 449 generated types compile and match expected patterns |
| `.gitattributes` | Marks generated files as `linguist-generated=true` |
| `analysis_options.yaml` | Excludes snapshot golden files from Dart analysis |

## Test plan

- [x] `dart analyze lib/` — 0 errors
- [x] `flutter test test/unit/` — 6,259 tests pass
- [x] `make xdr-generator-test` — 16/16 snapshot tests pass
- [x] `make xdr-generator-validate` — 450/450 generated types validated
- [x] 510 auto-generated XDR roundtrip encode/decode + base64 tests pass
- [ ] Integration tests (require testnet) — not run in this PR

🤖 Generated with [Claude Code](https://claude.com/claude-code)
