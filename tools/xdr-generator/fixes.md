# XDR Generator Fixes

Bug fixes and breaking changes in hand-written XDR files discovered by the generator.
These are cases where the hand-written code doesn't match the XDR definition
and the generator produces the correct output.

## User-Facing API Breaking Changes

These changes affect code outside `lib/src/xdr/` and may require updates by SDK users.

### Enum member renames (batches 1-10)

| Type | Old Name | New (XDR-correct) Name |
|------|----------|----------------------|
| XdrSignerKeyType | KEY_TYPE_ED25519_SIGNED_PAYLOAD | SIGNER_KEY_TYPE_ED25519_SIGNED_PAYLOAD |
| XdrPreconditionType | NONE | PRECOND_NONE |
| XdrPreconditionType | TIME | PRECOND_TIME |
| XdrPreconditionType | V2 | PRECOND_V2 |
| XdrManageOfferResultCode | MANAGE_OFFER_SUCCESS | MANAGE_SELL_OFFER_SUCCESS |

**SDK callers updated**: `key_pair.dart`, `txrep.dart`, `transaction.dart`

### Enum members removed (batch 10)

| Type | Removed Member | Reason |
|------|---------------|--------|
| XdrMessageType | GET_PEERS | Not in XDR spec |
| XdrMessageType | SURVEY_REQUEST | Replaced by TIME_SLICED_SURVEY_REQUEST in XDR |
| XdrMessageType | SURVEY_RESPONSE | Replaced by TIME_SLICED_SURVEY_RESPONSE in XDR |

### Struct constructor changes (batches 1-10)

| Type | Change | SDK impact |
|------|--------|------------|
| XdrSetOptionsOp | Constructor now requires all 9 fields as positional args (was no-arg) | `set_options_operation.dart`: pass nulls for unused fields |

### Struct constructor changes (clean regeneration)

| Type | Change | SDK callers updated |
|------|--------|---------------------|
| XdrOperation | Constructor now takes 2 positional args: sourceAccount, body (was 1 arg: body only) | `operation.dart` |

The XDR spec defines `Operation` with both `MuxedAccount* sourceAccount` and `OperationType body` as struct fields. The old hand-written code only accepted `body` in the constructor and set `sourceAccount` via a setter, which didn't match the struct definition.

### Field renames (clean regeneration)

| Type | Old Name | New (XDR-correct) Name | SDK callers updated |
|------|----------|----------------------|---------------------|
| XdrTransaction | preconditions | cond | `transaction.dart`, `webauth.dart` |

The XDR spec defines `Transaction.cond` (type `Preconditions`). The old hand-written code used `preconditions` for readability, but this violated the XDR field name.

### Type hierarchy corrections (clean regeneration)

| Type | Old (incorrect) | New (XDR-correct) | SDK callers updated |
|------|----------------|-------------------|---------------------|
| XdrChangeTrustAsset | Extended XdrAsset (inheritance) | Separate independent union | `assets.dart`, `change_trust_operation.dart`, `asset_type_pool_share.dart` |

The XDR spec defines `Asset` and `ChangeTrustAsset` as **separate unions** that happen to share 3 cases (`NATIVE`, `CREDIT_ALPHANUM4`, `CREDIT_ALPHANUM12`). `ChangeTrustAsset` has an additional `ASSET_TYPE_POOL_SHARE` case. The old code had `XdrChangeTrustAsset extends XdrAsset`, implying inheritance that doesn't exist in XDR. Fixed by:
- Adding `Asset.fromXdrChangeTrustAsset()` factory method
- `AssetTypePoolShare.toXdr()` now throws `UnsupportedError` (pool shares cannot be `XdrAsset`)
- `AssetTypePoolShare.toXdrChangeTrustAsset()` contains the actual implementation

### Type changes (clean regeneration)

| Type.field | Old Type | New (XDR-correct) Type | SDK callers updated |
|------------|----------|----------------------|---------------------|
| XdrSCVal.bytes | XdrDataValue | XdrSCBytes | `xdr_sc_val.dart`, `txrep.dart`, `soroban_client.dart`, `soroban_server.dart`, `webauth_for_contracts.dart` |
| XdrSCVal.vec | List\<XdrSCVal\> | XdrSCVec | `xdr_sc_val.dart`, `txrep.dart`, `soroban_auth.dart`, `webauth_for_contracts.dart` |
| XdrSCVal.map | List\<XdrSCMapEntry\> | XdrSCMap | `xdr_sc_val.dart`, `txrep.dart`, `webauth_for_contracts.dart` |

The XDR spec defines `SCVec`, `SCMap`, and `SCBytes` as named typedefs. The old code inlined these as raw `List`/`Uint8List` types. The generator correctly wraps them in `XdrSCVec`, `XdrSCMap`, `XdrSCBytes` classes with proper encode/decode. Access inner data via `.sCVec`, `.sCMap`, `.sCBytes` getters.

### Field renames (batch 14)

| Type | Old Name | New (XDR-correct) Name | SDK callers updated |
|------|----------|----------------------|---------------------|
| XdrTransactionExt | sorobanTransactionData | sorobanData | `transaction.dart`, `txrep.dart` |
| XdrPreconditionsV2 | sequenceNumber | minSeqNum | `transaction.dart` |
| XdrOperationBody | bumpExpirationOp | extendFootprintTTLOp | `operation.dart`, `extend_footprint_ttl_operation.dart` |
| XdrOperationBody | createPassiveOfferOp | createPassiveSellOfferOp | `create_passive_sell_offer_operation.dart` |
| XdrOperationResultTr | manageOfferResult | manageSellOfferResult / manageBuyOfferResult (split by discriminant) | `submit_transaction_response.dart` |

### Struct constructor changes (batch 14)

| Type | Change | SDK callers updated |
|------|--------|---------------------|
| XdrPreconditionsV2 | Constructor now takes 6 positional args (was 3) | `transaction.dart`, `txrep.dart` |

### Type changes (batch 14)

| Type.field | Old Type | New (XDR-correct) Type | SDK callers updated |
|------------|----------|----------------------|---------------------|
| XdrContractCodeEntry.code | XdrDataValue | Uint8List | `soroban_server.dart` |
| XdrSCEnvMetaEntryInterfaceVersion | Single XdrUint64 | Struct with `protocol` (XdrUint32) + `preRelease` (XdrUint32) | `soroban_contract_parser.dart` |

---

## Internal XDR Breaking Changes

These changes only affect `lib/src/xdr/` internals and test files. SDK users who don't
directly construct or access XDR objects are not affected.

### Field renames (batch 14)

| Type | Old Name | New (XDR-correct) Name |
|------|----------|----------------------|
| XdrSCError | type | discriminant |
| XdrSCMetaV0 | value | val |
| XdrLedgerKeyTTL | hashKey | keyHash |

### Union constructor changes (batch 14)

Union types now follow the correct pattern: constructor takes only the discriminant,
arm values are set via setters.

| Type | Change |
|------|--------|
| XdrTransactionResultResult | Constructor now takes only discriminant (was multi-arg) |
| XdrInnerTransactionResultResult | Constructor now takes only discriminant (was multi-arg) |
| XdrManageOfferResult | Constructor now takes only discriminant (was multi-arg) |

### Struct constructor changes (batch 14)

| Type | Change |
|------|--------|
| XdrLedgerEntryV1 | Now takes 2 positional args: sponsoringID, ext (was 1) |

### Enum member renames (batches 1-10)

| Type | Old Name | New (XDR-correct) Name |
|------|----------|----------------------|
| XdrClawbackResultCode | CLAWBACK_NOT_ENABLED | CLAWBACK_NOT_CLAWBACK_ENABLED |

Note: XdrClawbackResultCode is not referenced outside `lib/src/xdr/`, so this is not user-facing.

### Wrapper compatibility aliases added

These wrappers were added to maintain backward compatibility where the generated base
class uses different accessor patterns than the existing SDK callers:

| Wrapper Type | Alias Added | Delegates To |
|-------------|-------------|-------------|
| XdrPublicKey | getEd25519() / setEd25519() | ed25519 getter/setter on base |
| XdrContractExecutable | type getter/setter | discriminant getter/setter on base |
| XdrSorobanCredentials | type getter/setter | discriminant getter/setter on base |
| XdrLedgerKey | balanceID getter/setter | claimableBalance?.balanceID |
| XdrLedgerKey | liquidityPoolID getter/setter | liquidityPool?.liquidityPoolID |
| XdrLedgerKey | forConfigSetting() | wraps in XdrLedgerKeyConfigSetting |

### Union discriminant naming (clean regeneration)

The generator uses `discriminant` as the getter name for all union discriminants. Several types had custom getter names that matched the XDR field name:

| Type | Old Getter | New Getter |
|------|-----------|-----------|
| XdrConfigSettingEntry | configSettingID | discriminant |
| XdrHostFunction (base) | type | discriminant |
| XdrSorobanAuthorizedFunction (base) | type | discriminant |

Wrapper classes for `XdrHostFunction`, `XdrSorobanAuthorizedFunction`, and `XdrContractIDPreimage` add `type` getter aliases for backward compatibility.

### Primitive union discriminant type (clean regeneration)

| Type | Old Discriminant Type | New Type |
|------|----------------------|----------|
| XdrAuthenticatedMessage | XdrUint32 | int |

The XDR spec uses `uint32` for this union discriminant. The generator correctly maps primitive discriminants to native Dart `int`, removing the unnecessary `XdrUint32` wrapper.

### File cleanup (clean regeneration)

Deleted orphaned hand-written files replaced by generator output:

| Deleted File | Replaced By |
|-------------|-------------|
| `xdr_trust_line_entry_extension_v2.dart` | `trust_line_entry_extension_v2.dart` (generated) |
| `xdr_trust_line_entry_extension_v2_ext.dart` | `trust_line_entry_extension_v2_ext.dart` (generated) |

The class `TrustLineEntryExtensionV2` has a NAME_OVERRIDE that preserves the class name without the `Xdr` prefix, matching the original SDK convention. The barrel export in `xdr.dart` was updated.

### Wrapper compatibility aliases added (clean regeneration)

| Wrapper Type | Alias Added | Delegates To |
|-------------|-------------|-------------|
| XdrContractIDPreimage | type getter/setter | discriminant getter/setter on base |
| XdrContractIDPreimage | address getter/setter | fromAddress?.address |
| XdrContractIDPreimage | salt getter/setter | fromAddress?.salt |
| XdrHostFunction | type getter | discriminant getter on base |
| XdrSorobanAuthorizedFunction | type getter | discriminant getter on base |

### Test-only fixes (batch 14)

| Test File | Issue | Fix |
|-----------|-------|-----|
| xdr_soroban_types_test.dart | XdrSCError non-CONTRACT types missing required `code` field | Added `error.code = XdrSCErrorCode.SCEC_ARITH_DOMAIN` |
| xdr_contract_scval_test.dart | Same XdrSCError issue | Same fix |
| xdr_contract_types_test.dart | Same XdrSCError issue | Same fix |
| xdr_operation_test.dart | MANAGE_BUY_OFFER test set `manageSellOfferResult` instead of `manageBuyOfferResult` | Fixed to use correct field for discriminant |

### Test-only fixes (clean regeneration)

| Test File | Issue | Fix |
|-----------|-------|-----|
| xdr_transaction_results_test.dart | XdrTransactionSignaturePayload FEE_BUMP test didn't set `taggedTx.feeBump` before encoding | Added `taggedTx.feeBump = feeBumpTx` |
| xdr_bucket_test.dart | METAENTRY test didn't set required `metaEntry` field before encoding | Created and set `XdrBucketMetadata` |
| xdr_bucket_test.dart | INITENTRY test didn't set required `liveEntry` field before encoding | Created and set `XdrLedgerEntry` |
| Multiple test files (6) | `XdrOperation(body)` → `XdrOperation(null, body)` | Updated for 2-arg constructor |
| Multiple test files (2) | `.preconditions` → `.cond` on XdrTransaction | Updated for XDR field name |
| Multiple test files (4) | `.configSettingID` → `.discriminant` on XdrConfigSettingEntry | Updated for generator convention |
| Multiple test files (8) | XdrSCVec/XdrSCMap/XdrSCBytes wrapper access patterns | Added `.sCVec`/`.sCMap`/`.sCBytes` accessors |
| xdr_auth_test.dart | `XdrUint32(0)` → `0` for AuthenticatedMessage discriminant | Updated for native int type |
| assets_test.dart | `Asset.fromXdr(changeTrustAsset)` → `Asset.fromXdrChangeTrustAsset(...)` | Updated for separate type hierarchy |
| contract_bindings (3 files) | XdrSCVec/XdrSCMap wrapper access patterns | Added `.sCVec`/`.sCMap` accessors |
| integration tests (2 files) | XdrSCVec wrapper access patterns | Added `.sCVec` accessors |

---

## Pre-Existing SDK Bugs Fixed

### DataInput.readByte/readUnsignedByte off-by-one (`xdr_data_io.dart`) — FIXED

`readByte()` and `readUnsignedByte()` read byte at `_offset + 1` instead of `_offset`:

```dart
return view!.getInt8(_offset = _offset! + 1);  // reads NEW offset, not current
```

This caused `pad()` to validate the first byte of the **next field** instead of the actual padding byte. The bug was latent because most XDR fields start with `0x00` in big-endian encoding (small integers, enum discriminants), so the incorrect check passed.

**Impact**: Any variable-length field (string, opaque) with non-4-aligned data followed by a field whose first byte is non-zero would trigger a spurious "non-zero padding" exception during decode. Conversely, actual non-zero padding bytes went undetected.

**Fix applied**: Read from old offset before incrementing:
```dart
int old = _offset!;
_offset = _offset! + 1;
return view!.getInt8(old);
```

`readByte` is only called by `pad()`, which is only called by `readBytes()`. No other callers. The `readUnsignedByte` fix is for correctness (only called by unused `readLine()`). All 6072 unit tests pass with the fix, including 470 generated roundtrip tests using non-zero (`0xAB`) fill values for fixed-opaque fields.
