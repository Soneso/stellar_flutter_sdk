# SEP-0046 (Contract Meta) Compatibility Matrix

**Generated:** 2026-01-07 12:16:30  
**SDK Version:** 2.2.1  
**SEP Version:** 1.0.0  
**SEP Status:** Active  
**SEP URL:** https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0046.md

## SEP Summary

A standard for the storage of metadata in contract Wasm files.

## Overall Coverage

**Total Coverage:** 100.0% (9/9 fields)

- ✅ **Implemented:** 9/9
- ❌ **Not Implemented:** 0/9

**Required Fields:** 100.0% (9/9)

**Optional Fields:** 0% (0/0)

## Implementation Status

✅ **Implemented**

### Implementation Files

- `lib/src/soroban/soroban_contract_parser.dart`

### Key Classes

- **`SorobanContractParser`**: Parser for extracting metadata from Soroban contract WASM
- **`SorobanContractParserFailed`**: Exception when contract parsing fails
- **`SorobanContractInfo`**: Container for parsed contract metadata and supported SEPs

## Coverage by Section

| Section | Coverage | Required Coverage | Implemented | Not Implemented | Total |
|---------|----------|-------------------|-------------|-----------------|-------|
| Encoding Format | 100.0% | 100.0% | 3 | 0 | 3 |
| Implementation Support | 100.0% | 100.0% | 3 | 0 | 3 |
| Metadata Storage | 100.0% | 100.0% | 3 | 0 | 3 |

## Detailed Field Comparison

### Encoding Format

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `binary_stream_encoding` | ✓ | ✅ | `_parseMeta` | Encode entries as a stream of binary values |
| `key_value_pairs` | ✓ | ✅ | `metaEntries` | Store metadata as key-value string pairs |
| `scmetaentry_xdr` | ✓ | ✅ | `_parseMeta` | Use SCMetaEntry XDR type for structuring metadata |

### Implementation Support

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `decode_scmetaentry` | ✓ | ✅ | `_parseMeta` | Decode SCMetaEntry XDR structures |
| `extract_meta_entries` | ✓ | ✅ | `_parseMeta` | Extract meta entries as key-value pairs from contract |
| `parse_contract_meta` | ✓ | ✅ | `parseContractByteCode` | Parse contract metadata from contract bytecode |

### Metadata Storage

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `contractmetav0_section` | ✓ | ✅ | `_parseMeta` | Support for storing metadata in "contractmetav0" Wasm custom sections |
| `multiple_entries_single_section` | ✓ | ✅ | `_parseMeta` | Support for multiple metadata entries in a single custom section |
| `multiple_sections` | ✓ | ✅ | `_parseMeta` | Support for multiple "contractmetav0" sections interpreted sequentially |

## Implementation Gaps

🎉 **No gaps found!** All fields are implemented.

## Recommendations

✅ The SDK has full compatibility with SEP-0046!

## Legend

- ✅ **Implemented**: Field is implemented in SDK
- ❌ **Not Implemented**: Field is missing from SDK
- ⚙️ **Server**: Server-side only feature (not applicable to client SDKs)
- ✓ **Required**: Field is required by SEP specification
- (blank) **Optional**: Field is optional
