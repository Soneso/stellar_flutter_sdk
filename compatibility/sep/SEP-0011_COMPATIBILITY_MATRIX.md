# SEP-0011 (Txrep: human-readable low-level representation of Stellar transactions) Compatibility Matrix

**Generated:** 2026-03-10 17:28:46  
**SDK Version:** 3.0.3  
**SEP Version:** 1.1.0  
**SEP Status:** Active  
**SEP URL:** https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0011.md

## SEP Summary

Txrep is a human-readable representation of Stellar transactions that functions
like an assembly language for XDR.

## Overall Coverage

**Total Coverage:** 100.0% (50/50 fields)

- ✅ **Implemented:** 50/50
- ❌ **Not Implemented:** 0/50

**Required Fields:** 100.0% (50/50)

**Optional Fields:** 0% (0/0)

## Implementation Status

✅ **Implemented**

### Implementation Files

- `lib/src/sep/0011/txrep.dart`

### Key Classes

- **`TxRep`**: SEP-0011 TxRep: Human-readable transaction representation.

## Coverage by Section

| Section | Coverage | Required Coverage | Implemented | Not Implemented | Total |
|---------|----------|-------------------|-------------|-----------------|-------|
| Asset Encoding | 100.0% | 100.0% | 3 | 0 | 3 |
| Decoding Features | 100.0% | 100.0% | 8 | 0 | 8 |
| Encoding Features | 100.0% | 100.0% | 8 | 0 | 8 |
| Format Features | 100.0% | 100.0% | 5 | 0 | 5 |
| Operation Types | 100.0% | 100.0% | 26 | 0 | 26 |

## Detailed Field Comparison

### Asset Encoding

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `encode_alphanumeric12_asset` | ✓ | ✅ | `_encodeAsset` | Encode 12-character alphanumeric asset |
| `encode_alphanumeric4_asset` | ✓ | ✅ | `_encodeAsset` | Encode 4-character alphanumeric asset |
| `encode_native_asset` | ✓ | ✅ | `_encodeAsset` | Encode native XLM asset in txrep format |

### Decoding Features

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `decode_fee_bump_transaction` | ✓ | ✅ | `transactionEnvelopeXdrBase64FromTxRep` | Parse fee bump transaction from txrep format |
| `decode_memo` | ✓ | ✅ | `transactionEnvelopeXdrBase64FromTxRep` | Parse all memo types from txrep |
| `decode_operations` | ✓ | ✅ | `transactionEnvelopeXdrBase64FromTxRep` | Parse all Stellar operation types from txrep |
| `decode_preconditions` | ✓ | ✅ | `transactionEnvelopeXdrBase64FromTxRep` | Parse transaction preconditions from txrep |
| `decode_signatures` | ✓ | ✅ | `transactionEnvelopeXdrBase64FromTxRep` | Parse transaction signatures from txrep |
| `decode_soroban_data` | ✓ | ✅ | `transactionEnvelopeXdrBase64FromTxRep` | Parse Soroban transaction data from txrep |
| `decode_source_account` | ✓ | ✅ | `transactionEnvelopeXdrBase64FromTxRep` | Parse source account (including muxed accounts) |
| `decode_transaction` | ✓ | ✅ | `transactionEnvelopeXdrBase64FromTxRep` | Parse txrep text format to transaction envelope XDR |

### Encoding Features

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `encode_fee_bump_transaction` | ✓ | ✅ | `fromTransactionEnvelopeXdrBase64` | Convert fee bump transaction envelope to txrep format |
| `encode_memo` | ✓ | ✅ | `fromTransactionEnvelopeXdrBase64` | Encode all memo types (NONE, TEXT, ID, HASH, RETURN) |
| `encode_operations` | ✓ | ✅ | `fromTransactionEnvelopeXdrBase64` | Encode all Stellar operation types |
| `encode_preconditions` | ✓ | ✅ | `fromTransactionEnvelopeXdrBase64` | Encode transaction preconditions (time bounds, ledger bounds, min seq num, etc.) |
| `encode_signatures` | ✓ | ✅ | `fromTransactionEnvelopeXdrBase64` | Encode transaction signatures |
| `encode_soroban_data` | ✓ | ✅ | `fromTransactionEnvelopeXdrBase64` | Encode Soroban transaction data (resources, footprint, etc.) |
| `encode_source_account` | ✓ | ✅ | `fromTransactionEnvelopeXdrBase64` | Encode source account (including muxed accounts) |
| `encode_transaction` | ✓ | ✅ | `fromTransactionEnvelopeXdrBase64` | Convert transaction envelope XDR to txrep text format |

### Format Features

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `array_indexing` | ✓ | ✅ | `TxRep format implementation` | Support array indexing in txrep format |
| `comment_support` | ✓ | ✅ | `TxRep format implementation` | Support for comments in txrep format |
| `dot_notation` | ✓ | ✅ | `TxRep format implementation` | Use dot notation for nested structures |
| `hex_encoding` | ✓ | ✅ | `TxRep format implementation` | Hexadecimal encoding for binary data |
| `string_escaping` | ✓ | ✅ | `TxRep format implementation` | Proper string escaping with double quotes |

### Operation Types

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `account_merge` | ✓ | ✅ | `_addOperation (encode), operation parsing (decode)` | Encode/decode ACCOUNT_MERGE operation |
| `allow_trust` | ✓ | ✅ | `_addOperation (encode), operation parsing (decode)` | Encode/decode ALLOW_TRUST operation |
| `begin_sponsoring_future_reserves` | ✓ | ✅ | `_addOperation (encode), operation parsing (decode)` | Encode/decode BEGIN_SPONSORING_FUTURE_RESERVES operation |
| `bump_sequence` | ✓ | ✅ | `_addOperation (encode), operation parsing (decode)` | Encode/decode BUMP_SEQUENCE operation |
| `change_trust` | ✓ | ✅ | `_addOperation (encode), operation parsing (decode)` | Encode/decode CHANGE_TRUST operation |
| `claim_claimable_balance` | ✓ | ✅ | `_addOperation (encode), operation parsing (decode)` | Encode/decode CLAIM_CLAIMABLE_BALANCE operation |
| `clawback` | ✓ | ✅ | `_addOperation (encode), operation parsing (decode)` | Encode/decode CLAWBACK operation |
| `clawback_claimable_balance` | ✓ | ✅ | `_addOperation (encode), operation parsing (decode)` | Encode/decode CLAWBACK_CLAIMABLE_BALANCE operation |
| `create_account` | ✓ | ✅ | `_addOperation (encode), operation parsing (decode)` | Encode/decode CREATE_ACCOUNT operation |
| `create_claimable_balance` | ✓ | ✅ | `_addOperation (encode), operation parsing (decode)` | Encode/decode CREATE_CLAIMABLE_BALANCE operation |
| `create_passive_sell_offer` | ✓ | ✅ | `_addOperation (encode), operation parsing (decode)` | Encode/decode CREATE_PASSIVE_SELL_OFFER operation |
| `end_sponsoring_future_reserves` | ✓ | ✅ | `_addOperation (encode), operation parsing (decode)` | Encode/decode END_SPONSORING_FUTURE_RESERVES operation |
| `extend_footprint_ttl` | ✓ | ✅ | `_addOperation (encode), operation parsing (decode)` | Encode/decode EXTEND_FOOTPRINT_TTL operation (Soroban) |
| `invoke_host_function` | ✓ | ✅ | `_addOperation (encode), operation parsing (decode)` | Encode/decode INVOKE_HOST_FUNCTION operation (Soroban) |
| `liquidity_pool_deposit` | ✓ | ✅ | `_addOperation (encode), operation parsing (decode)` | Encode/decode LIQUIDITY_POOL_DEPOSIT operation |
| `liquidity_pool_withdraw` | ✓ | ✅ | `_addOperation (encode), operation parsing (decode)` | Encode/decode LIQUIDITY_POOL_WITHDRAW operation |
| `manage_buy_offer` | ✓ | ✅ | `_addOperation (encode), operation parsing (decode)` | Encode/decode MANAGE_BUY_OFFER operation |
| `manage_data` | ✓ | ✅ | `_addOperation (encode), operation parsing (decode)` | Encode/decode MANAGE_DATA operation |
| `manage_sell_offer` | ✓ | ✅ | `_addOperation (encode), operation parsing (decode)` | Encode/decode MANAGE_SELL_OFFER operation |
| `path_payment_strict_receive` | ✓ | ✅ | `_addOperation (encode), operation parsing (decode)` | Encode/decode PATH_PAYMENT_STRICT_RECEIVE operation |
| `path_payment_strict_send` | ✓ | ✅ | `_addOperation (encode), operation parsing (decode)` | Encode/decode PATH_PAYMENT_STRICT_SEND operation |
| `payment` | ✓ | ✅ | `_addOperation (encode), operation parsing (decode)` | Encode/decode PAYMENT operation |
| `restore_footprint` | ✓ | ✅ | `_addOperation (encode), operation parsing (decode)` | Encode/decode RESTORE_FOOTPRINT operation (Soroban) |
| `revoke_sponsorship` | ✓ | ✅ | `_addOperation (encode), operation parsing (decode)` | Encode/decode REVOKE_SPONSORSHIP operation |
| `set_options` | ✓ | ✅ | `_addOperation (encode), operation parsing (decode)` | Encode/decode SET_OPTIONS operation |
| `set_trust_line_flags` | ✓ | ✅ | `_addOperation (encode), operation parsing (decode)` | Encode/decode SET_TRUST_LINE_FLAGS operation |

## Implementation Gaps

🎉 **No gaps found!** All fields are implemented.

## Recommendations

✅ The SDK has full compatibility with SEP-0011!

## Legend

- ✅ **Implemented**: Field is implemented in SDK
- ❌ **Not Implemented**: Field is missing from SDK
- ⚙️ **Server**: Server-side only feature (not applicable to client SDKs)
- ✓ **Required**: Field is required by SEP specification
- (blank) **Optional**: Field is optional
