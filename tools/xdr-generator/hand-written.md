# Hand-Written XDR Wrapper Classes

24 files in `lib/src/xdr/` are hand-maintained (not auto-generated).
This document tracks which ones can be eliminated or simplified.

## Trivial — candidates for removal (8 files)
These have no base class or only trivial code that could be generated.

| File | What it has | Status |
|------|------------|--------|
| `xdr_asset_code4.dart` | Direct encode/decode of 4-byte Uint8List | **deleted** — dead code, TYPE_OVERRIDES maps to Uint8List |
| `xdr_asset_code12.dart` | Direct encode/decode of 12-byte Uint8List | **deleted** — dead code, TYPE_OVERRIDES maps to Uint8List |
| `xdr_big_int64.dart` | Direct encode/decode of BigInt | **deleted** — replaced with XdrInt64, all callers updated |
| `xdr_constant_product.dart` | Struct with 5 fields, no helpers | **deleted** — dead code, replaced by generated `XdrLiquidityPoolEntryConstantProduct` |
| `xdr_contract_code_entry_ext_v1.dart` | Struct with 2 fields, no helpers | **deleted** — dead code, replaced by generated `XdrContractCodeEntryV1` |
| `xdr_contract_event_body_v0.dart` | Struct with 2 fields, no helpers | **deleted** — dead code, replaced by generated `XdrContractEventV0` |
| `xdr_contract_id.dart` | Single-field wrapper around XdrHash | **deleted** — dead code, TYPE_OVERRIDES maps to XdrHash |
| `xdr_pool_id.dart` | Single-field wrapper around XdrHash | **deleted** — dead code, TYPE_OVERRIDES maps to XdrHash |

## Base64 encode/decode only (11 files) — ELIMINATED
These were BASE_WRAPPER_TYPES wrappers that only added base64 convenience methods.
Now that the generator adds `toBase64EncodedXdrString()`/`fromBase64EncodedXdrString()`
to all types, these 10 types were removed from BASE_WRAPPER_TYPES and the generator
produces them directly. The `*_base.dart` files and hand-written wrappers are both gone.

| File | Status |
|------|--------|
| `xdr_contract_event.dart` | **deleted** — now generated directly |
| `xdr_diagnostic_event.dart` | **deleted** — now generated directly |
| `xdr_ledger_entry.dart` | **deleted** — now generated directly |
| `xdr_ledger_entry_changes.dart` | **deleted** — now generated directly |
| `xdr_ledger_entry_data.dart` | **deleted** — now generated directly |
| `xdr_ledger_footprint.dart` | **deleted** — now generated directly |
| `xdr_soroban_transaction_data.dart` | **deleted** — now generated directly |
| `xdr_transaction_event.dart` | **deleted** — now generated directly |
| `xdr_transaction_meta.dart` | **deleted** — now generated directly |
| `xdr_transaction_result.dart` | **deleted** — now generated directly |
| `xdr_transaction_envelope.dart` | **keep** — legacy names `toEnvelopeXdrBase64`/`fromEnvelopeXdrString` used in ~100 call sites |

## Discriminant aliases + factory methods (7 files)
These wrappers had `get type => discriminant` aliases and/or factory methods.
The `type` alias is now generated directly (all unions emit the original XDR
field name as an alias), so the redundant aliases were removed from 5 wrappers.
All 7 files still needed for factory methods / convenience accessors.

| File | Extras | Status |
|------|--------|--------|
| `xdr_contract_executable.dart` | `forWasm()`, `forAsset()` | **keep** — type alias removed (now inherited), factories remain |
| `xdr_host_function.dart` | 6 factory methods | **keep** — type alias removed (now inherited), factories remain |
| `xdr_soroban_authorized_function.dart` | 3 factories | **keep** — type alias removed (now inherited), factories remain |
| `xdr_soroban_credentials.dart` | 2 factories | **keep** — type alias removed (now inherited), factories remain |
| `xdr_contract_id_preimage.dart` | nested `address`/`salt` accessors + 2 factories | **keep** — type alias removed (now inherited), accessors + factories remain |
| `xdr_change_trust_asset.dart` | `fromXdrAsset()` factory | **keep** — no type alias was present, factory remains |
| `xdr_trustline_asset.dart` | `fromXdrAsset()` factory | **keep** — no type alias was present, factory remains |

## Significant helper logic (14 files)
These have substantial logic worth keeping.

| File | What it adds | Status |
|------|------------|--------|
| `xdr_account_id.dart` | `forAccountId(String)` factory | pending |
| `xdr_claimable_balance_id.dart` | `forId()` strkey parsing, hex conversion | pending |
| `xdr_int128_parts.dart` | `forHiLo(BigInt, BigInt)` | pending |
| `xdr_int256_parts.dart` | `forHiHiHiLoLoHiLoLo()` | pending |
| `xdr_u_int128_parts.dart` | `forHiLo(BigInt, BigInt)` | pending |
| `xdr_u_int256_parts.dart` | `forHiHiHiLoLoHiLoLo()` | pending |
| `xdr_ledger_key.dart` | 6 helper methods, 7 factories, compat aliases | pending |
| `xdr_ledger_key_data.dart` | `forDataName()` factory | pending |
| `xdr_ledger_key_offer.dart` | `forOfferId()` factory | pending |
| `xdr_muxed_account_med25519.dart` | `accountId` strkey property | pending |
| `xdr_public_key.dart` | `getEd25519()`/`setEd25519()`, `forAccountId()` | pending |
| `xdr_sc_address.dart` | 4 factories, `toStrKey()` | pending |
| `xdr_sc_spec_type_def.dart` | 17 factories | pending |
| `xdr_sc_val.dart` | 30+ factories, BigInt conversion, base64 | pending |
