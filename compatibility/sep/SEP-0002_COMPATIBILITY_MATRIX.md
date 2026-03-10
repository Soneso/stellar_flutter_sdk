# SEP-0002 (Federation protocol) Compatibility Matrix

**Generated:** 2026-03-10 17:28:42  
**SDK Version:** 3.0.3  
**SEP Version:** 1.1.0  
**SEP Status:** Final  
**SEP URL:** https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0002.md

## SEP Summary

The Stellar federation protocol maps Stellar addresses to more information
about a given user. It’s a way for Stellar client software to resolve
email-like addresses such as `name*yourdomain.com` into account IDs like:
`GCCVPYFOHY7ZB7557JKENAX62LUAPLMGIWNZJAFV2MITK6T32V37KEJU`. Stellar addresses
provide an easy way for users to share payment details by using a syntax that
interoperates across different domains and providers.

## Overall Coverage

**Total Coverage:** 100.0% (10/10 fields)

- ✅ **Implemented:** 10/10
- ❌ **Not Implemented:** 0/10

**Required Fields:** 100.0% (6/6)

**Optional Fields:** 100.0% (4/4)

## Implementation Status

✅ **Implemented**

### Implementation Files

- `lib/src/sep/0002/federation.dart`

### Key Classes

- **`Federation`**: Resolves federation addresses to Stellar account IDs
- **`FederationResponse`**: Response from federation server lookups

## Coverage by Section

| Section | Coverage | Required Coverage | Implemented | Not Implemented | Total |
|---------|----------|-------------------|-------------|-----------------|-------|
| Request Parameters | 100.0% | 100.0% | 2 | 0 | 2 |
| Request Types | 100.0% | 100.0% | 4 | 0 | 4 |
| Response Fields | 100.0% | 100.0% | 4 | 0 | 4 |

## Detailed Field Comparison

### Request Parameters

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `q` | ✓ | ✅ | `q` | String to look up (stellar address, account ID, or transaction ID) |
| `type` | ✓ | ✅ | `type` | Type of lookup (name, id, txid, or forward) |

### Request Types

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `forward` |  | ✅ | `resolveForward` | Used for forwarding the payment on to a different network or different financial institution. The other parameters of the query will vary depending on what kind of institution is the ultimate destinat... |
| `id` | ✓ | ✅ | `resolveStellarAccountId` | returns the federation record of the Stellar address associated with the given account ID. In some cases this is ambiguous. For instance if an anchor sends transactions on behalf of its users the acco... |
| `name` | ✓ | ✅ | `resolveStellarAddress` | returns the federation record for the given Stellar address. |
| `txid` |  | ✅ | `resolveStellarTransactionId` | returns the federation record of the sender of the transaction if known by the server. |

### Response Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `account_id` | ✓ | ✅ | `accountId` | Stellar public key / account ID |
| `memo` |  | ✅ | `memo` | value of memo to attach to transaction, for hash this should be base64-encoded. This field should always be of type string (even when memo_type is equal id) to support parsing value in languages that ... |
| `memo_type` |  | ✅ | `memoType` | type of memo to attach to transaction, one of text, id or hash |
| `stellar_address` | ✓ | ✅ | `stellarAddress` | stellar address |

## Implementation Gaps

🎉 **No gaps found!** All fields are implemented.

## Recommendations

✅ The SDK has full compatibility with SEP-0002!

## Legend

- ✅ **Implemented**: Field is implemented in SDK
- ❌ **Not Implemented**: Field is missing from SDK
- ⚙️ **Server**: Server-side only feature (not applicable to client SDKs)
- ✓ **Required**: Field is required by SEP specification
- (blank) **Optional**: Field is optional
