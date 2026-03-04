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

### Test-only fixes (batch 14)

| Test File | Issue | Fix |
|-----------|-------|-----|
| xdr_soroban_types_test.dart | XdrSCError non-CONTRACT types missing required `code` field | Added `error.code = XdrSCErrorCode.SCEC_ARITH_DOMAIN` |
| xdr_contract_scval_test.dart | Same XdrSCError issue | Same fix |
| xdr_contract_types_test.dart | Same XdrSCError issue | Same fix |
| xdr_operation_test.dart | MANAGE_BUY_OFFER test set `manageSellOfferResult` instead of `manageBuyOfferResult` | Fixed to use correct field for discriminant |

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
