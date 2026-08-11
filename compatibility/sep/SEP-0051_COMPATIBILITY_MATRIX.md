# SEP-0051 (XDR-JSON) Compatibility Matrix

**Generated:** 2026-08-11 11:39:14  
**SDK Version:** 3.5.0  
**SEP Version:** 2.0.1  
**SEP Status:** Draft  
**SEP URL:** https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0051.md

## SEP Summary

This proposal defines XDR-JSON, a standard mapping between Stellar's XDR
(External Data Representation) structures and a JSON representation.

## Overall Coverage

**Total Coverage:** 100.0% (39/39 fields)

- ✅ **Implemented:** 39/39
- ❌ **Not Implemented:** 0/39

**Required Fields:** 100.0% (36/36)

**Optional Fields:** 100.0% (3/3)

## Implementation Status

✅ **Implemented**

### Implementation Files

- `lib/src/xdr/xdr_account_entry_v2.dart`
- `lib/src/xdr/xdr_account_id_base.dart`
- `lib/src/xdr/xdr_allow_trust_op_asset.dart`
- `lib/src/xdr/xdr_asset.dart`
- `lib/src/xdr/xdr_asset_type.dart`
- `lib/src/xdr/xdr_claimable_balance_id_base.dart`
- `lib/src/xdr/xdr_contract_event.dart`
- `lib/src/xdr/xdr_data_value.dart`
- `lib/src/xdr/xdr_extension_point.dart`
- `lib/src/xdr/xdr_hash.dart`
- `lib/src/xdr/xdr_int128_parts_base.dart`
- `lib/src/xdr/xdr_int256_parts_base.dart`
- `lib/src/xdr/xdr_int32.dart`
- `lib/src/xdr/xdr_int64.dart`
- `lib/src/xdr/xdr_json_helper.dart`
- `lib/src/xdr/xdr_ledger_header.dart`
- `lib/src/xdr/xdr_muxed_account.dart`
- `lib/src/xdr/xdr_muxed_account_med25519_base.dart`
- `lib/src/xdr/xdr_node_id.dart`
- `lib/src/xdr/xdr_public_key_base.dart`
- `lib/src/xdr/xdr_sc_address_base.dart`
- `lib/src/xdr/xdr_sc_val_base.dart`
- `lib/src/xdr/xdr_signed_payload.dart`
- `lib/src/xdr/xdr_signer_key.dart`
- `lib/src/xdr/xdr_time_bounds.dart`
- `lib/src/xdr/xdr_trustline_asset_base.dart`
- `lib/src/xdr/xdr_u_int128_parts_base.dart`
- `lib/src/xdr/xdr_u_int256_parts_base.dart`
- `lib/src/xdr/xdr_uint32.dart`
- `lib/src/xdr/xdr_uint64.dart`

### Key Classes

- **`XdrJsonHelper`**: Runtime for SEP-51 XDR-JSON encoding and decoding. Every generated XDR type carries toXdrJson, toXdrJsonValue, fromXdrJson and fromXdrJsonValue over it.

## Coverage by Section

| Section | Coverage | Required Coverage | Implemented | Not Implemented | Total |
|---------|----------|-------------------|-------------|-----------------|-------|
| JSON Schema | 100.0% | 100% | 1 | 0 | 1 |
| Stellar-Specific Types | 100.0% | 100.0% | 19 | 0 | 19 |
| XDR Data Types | 100.0% | 100.0% | 19 | 0 | 19 |

## Detailed Field Comparison

### JSON Schema

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `schema_property` |  | ✅ | `XdrJsonHelper.stripSchema` | JSON objects allow, but do not require, a $schema property |

### Stellar-Specific Types

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `account_id` | ✓ | ✅ | `XdrAccountID (delegates to XdrPublicKey)` | AccountID renders as a G strkey |
| `asset_code` | ✓ | ✅ | `XdrAllowTrustOpAsset (bare string by arm)` | AssetCode renders as the string of its AssetCode4 or AssetCode12 arm |
| `asset_code_12` | ✓ | ✅ | `XdrJsonHelper.assetCode12 / readAssetCode12` | AssetCode12 drops trailing zero bytes down to five, then takes the string escape ladder |
| `asset_code_4` | ✓ | ✅ | `XdrJsonHelper.assetCode4 / readAssetCode4` | AssetCode4 drops trailing zero bytes, then takes the string escape ladder |
| `claimable_balance_id` | ✓ | ✅ | `XdrClaimableBalanceID.toXdrJsonValue / fromXdrJsonValue` | ClaimableBalanceID renders as a B strkey |
| `contract_id` | ✓ | ✅ | `XdrContractEvent.contractID (C strkey)` | ContractID renders as a C strkey |
| `int128_parts` | ✓ | ✅ | `XdrInt128Parts.toXdrJsonValue / fromXdrJsonValue` | Int128Parts renders as one base-10 string of the reassembled integer |
| `int256_parts` | ✓ | ✅ | `XdrInt256Parts.toXdrJsonValue / fromXdrJsonValue` | Int256Parts renders as one base-10 string of the reassembled integer |
| `muxed_account` | ✓ | ✅ | `XdrMuxedAccount.toXdrJsonValue / fromXdrJsonValue` | MuxedAccount renders as a G strkey (ed25519) or an M strkey (muxed ed25519) |
| `muxed_account_med25519` | ✓ | ✅ | `XdrMuxedAccountMed25519.toXdrJsonValue / fromXdrJsonValue` | MuxedAccountMed25519 renders as an M strkey |
| `muxed_ed25519_account` | ✓ | ✅ | `XdrSCAddress muxed arm (XdrMuxedAccountMed25519)` | MuxedEd25519Account renders as an M strkey |
| `node_id` | ✓ | ✅ | `XdrNodeID (delegates to XdrPublicKey)` | NodeID renders as a G strkey |
| `pool_id` | ✓ | ✅ | `XdrTrustlineAsset pool_share arm (L strkey)` | PoolID renders as an L strkey |
| `public_key` | ✓ | ✅ | `XdrPublicKey.toXdrJsonValue / fromXdrJsonValueAs` | PublicKey renders as a G strkey |
| `sc_address` | ✓ | ✅ | `XdrSCAddress.toXdrJsonValue / fromXdrJsonValueAs` | ScAddress renders as a G, C, M, B or L strkey by arm |
| `signer_key` | ✓ | ✅ | `XdrSignerKey.toXdrJsonValue / fromXdrJsonValue` | SignerKey renders as a G, T, X or P strkey by arm |
| `signer_key_ed25519_signed_payload` | ✓ | ✅ | `XdrSignedPayload.toXdrJsonValue / fromXdrJsonValue` | SignerKeyEd25519SignedPayload renders as a P strkey |
| `uint128_parts` | ✓ | ✅ | `XdrUInt128Parts.toXdrJsonValue / fromXdrJsonValue` | UInt128Parts renders as one base-10 string of the reassembled integer |
| `uint256_parts` | ✓ | ✅ | `XdrUInt256Parts.toXdrJsonValue / fromXdrJsonValue` | UInt256Parts renders as one base-10 string of the reassembled integer |

### XDR Data Types

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `array_fixed` | ✓ | ✅ | `XdrLedgerHeader.skipList (readArray fixedLength)` | Fixed-length array maps to a JSON array |
| `array_variable` | ✓ | ✅ | `XdrAccountEntryV2.signerSponsoringIDs` | Variable-length array maps to a JSON array |
| `boolean` | ✓ | ✅ | `XdrSCVal bool arm` | Boolean maps to a JSON boolean |
| `enum` | ✓ | ✅ | `XdrAssetType.toXdrJsonValue / fromXdrJsonValue` | Enum maps to a snake_case string with any shared prefix removed |
| `hyper_integer` | ✓ | ✅ | `XdrInt64.toXdrJsonValue / fromXdrJsonValue` | 64-bit signed integer maps to a base-10 JSON string |
| `hyper_number_input` |  | ✅ | `XdrJsonHelper.readInt64 (JSON number accepted below 2^53)` | Deserializes a JSON number for Hyper, for XDR-JSON v1 compatibility |
| `integer_32` | ✓ | ✅ | `XdrInt32.toXdrJsonValue / fromXdrJsonValue` | 32-bit signed integer maps to a JSON number |
| `opaque_fixed` | ✓ | ✅ | `XdrHash.toXdrJsonValue / fromXdrJsonValue` | Fixed-length opaque data maps to a hexadecimal string |
| `opaque_variable` | ✓ | ✅ | `XdrDataValue.toXdrJsonValue / fromXdrJsonValue` | Variable-length opaque data maps to a hexadecimal string |
| `optional` | ✓ | ✅ | `XdrContractEvent.contractID (null when absent)` | Optional data maps to null when unset and to the value when set |
| `string_escaping` | ✓ | ✅ | `XdrJsonHelper.escapedString / readEscapedString` | String is escaped per the specification ladder: \0, \t, \n, \r, \\, printable ASCII verbatim, \xNN otherwise |
| `struct` | ✓ | ✅ | `XdrTimeBounds.toXdrJsonValue / fromXdrJsonValue` | Struct maps to a JSON object keyed by the snake_case field name |
| `union_integer_cases` | ✓ | ✅ | `XdrExtensionPoint.toXdrJsonValue / fromXdrJsonValue` | Union with integer cases keys on the discriminant name suffixed by the integer |
| `union_value_arm` | ✓ | ✅ | `XdrAsset credit_alphanum4 arm` | Union with a value arm maps to a single-key object keyed by the discriminant |
| `union_void_arm` | ✓ | ✅ | `XdrAsset native arm` | Union with a void arm maps to a bare discriminant string |
| `unsigned_hyper_integer` | ✓ | ✅ | `XdrUint64.toXdrJsonValue / fromXdrJsonValue` | 64-bit unsigned integer maps to a base-10 JSON string |
| `unsigned_hyper_number_input` |  | ✅ | `XdrJsonHelper.readUint64 (JSON number accepted below 2^53)` | Deserializes a JSON number for Unsigned Hyper, for XDR-JSON v1 compatibility |
| `unsigned_integer_32` | ✓ | ✅ | `XdrUint32.toXdrJsonValue / fromXdrJsonValue` | 32-bit unsigned integer maps to a JSON number |
| `void` | ✓ | ✅ | `XdrSCVal void arm (no value emitted)` | Void is omitted in JSON |

## Implementation Gaps

🎉 **No gaps found!** All fields are implemented.

## Recommendations

✅ The SDK has full compatibility with SEP-0051!

## Legend

- ✅ **Implemented**: Field is implemented in SDK
- ❌ **Not Implemented**: Field is missing from SDK
- ⚙️ **Server**: Server-side only feature (not applicable to client SDKs)
- ✓ **Required**: Field is required by SEP specification
- (blank) **Optional**: Field is optional
