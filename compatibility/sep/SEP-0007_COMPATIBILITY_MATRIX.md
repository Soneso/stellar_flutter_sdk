# SEP-0007 (URI Scheme to facilitate delegated signing) Compatibility Matrix

**Generated:** 2025-10-10 16:08:24

**SEP Version:** 2.1.0
**SEP Status:** Active
**SEP URL:** https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0007.md

## SEP Summary

This Stellar Ecosystem Proposal introduces a URI Scheme that can be used to
generate a URI that will serve as a request to sign a transaction. The URI
(request) will typically be signed by the user’s trusted wallet where she
stores her secret key(s).

## Overall Coverage

**Total Coverage:** 100.0% (31/31 fields)

- ✅ **Implemented:** 31/31
- ❌ **Not Implemented:** 0/31

**Required Fields:** 100.0% (18/18)

**Optional Fields:** 100.0% (13/13)

## Implementation Status

✅ **Implemented**

### Implementation Files

- `lib/src/sep/0007/URIScheme.dart`

### Key Classes

- **`URIScheme`**: Implements utility methods for SEP-007 - URI Scheme to facilitate delegated signing
- **`SubmitUriSchemeTransactionResponse`**: Implements utility methods for SEP-007 - URI Scheme to facilitate delegated signing
- **`URISchemeError`**: Implements utility methods for SEP-007 - URI Scheme to facilitate delegated signing
- **`IsValidSep7UrlResult`**: Implements utility methods for SEP-007 - URI Scheme to facilitate delegated signing
- **`ParsedSep7UrlResult`**: Implements utility methods for SEP-007 - URI Scheme to facilitate delegated signing
- **`UriSchemeReplacement`**: Implements utility methods for SEP-007 - URI Scheme to facilitate delegated signing

## Coverage by Section

| Section | Coverage | Required Coverage | Implemented | Total |
|---------|----------|-------------------|-------------|-------|
| Common Parameters | 100.0% | 100% | 4 | 4 |
| PAY Operation Parameters | 100.0% | 100.0% | 6 | 6 |
| Signature Features | 100.0% | 100.0% | 3 | 3 |
| TX Operation Parameters | 100.0% | 100.0% | 5 | 5 |
| URI Operations | 100.0% | 100.0% | 2 | 2 |
| Validation Features | 100.0% | 100.0% | 11 | 11 |

## Detailed Field Comparison

### Common Parameters

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `msg` |  | ✅ | `messageParameterName` | Message for the user (max 300 characters) |
| `network_passphrase` |  | ✅ | `networkPassphraseParameterName` | Network passphrase for the transaction |
| `origin_domain` |  | ✅ | `originDomainParameterName` | Fully qualified domain name of the service originating the request |
| `signature` |  | ✅ | `signatureParameterName` | Signature of the URL for verification |

### PAY Operation Parameters

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `amount` |  | ✅ | `amountParameterName` | Amount to send |
| `asset_code` |  | ✅ | `assetCodeParameterName` | Asset code for the payment (e.g., USD, BTC) |
| `asset_issuer` |  | ✅ | `assetIssuerParameterName` | Stellar account ID of asset issuer |
| `destination` | ✓ | ✅ | `destinationParameterName` | Stellar account ID or payment address to receive payment |
| `memo` |  | ✅ | `memoParameterName` | Memo value to attach to transaction |
| `memo_type` |  | ✅ | `memoTypeParameterName` | Type of memo (MEMO_TEXT, MEMO_ID, MEMO_HASH, MEMO_RETURN) |

### Signature Features

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `sign_uri` | ✓ | ✅ | `addSignature` | Sign a SEP-0007 URI with a keypair |
| `verify_signature` | ✓ | ✅ | `verifySignature` | Verify URI signature with a public key |
| `verify_signed_uri` | ✓ | ✅ | `isValidSep7SignedUrl` | Verify signed URI by fetching signing key from origin domain TOML |

### TX Operation Parameters

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `callback` |  | ✅ | `callbackParameterName` | URL for transaction submission callback |
| `chain` |  | ✅ | `chainParameterName` | Nested SEP-0007 URL for transaction chaining |
| `pubkey` |  | ✅ | `publicKeyParameterName` | Stellar public key to specify which key should sign |
| `replace` |  | ✅ | `replaceParameterName` | URL-encoded field replacement using Txrep (SEP-0011) format |
| `xdr` | ✓ | ✅ | `xdrParameterName` | Base64 encoded TransactionEnvelope XDR |

### URI Operations

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `pay` | ✓ | ✅ | `generatePayOperationURI` | Payment operation - Request to pay a specific address |
| `tx` | ✓ | ✅ | `generateSignTransactionURI` | Transaction operation - Request to sign a transaction |

### Validation Features

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `validate_asset_code` | ✓ | ✅ | `isValidSep7Url` | Validate asset code length and format |
| `validate_chain_nesting` | ✓ | ✅ | `isValidSep7Url` | Validate chain parameter nesting depth (max 7 levels) |
| `validate_destination_parameter` | ✓ | ✅ | `isValidSep7Url` | Validate destination parameter for pay operation |
| `validate_memo_type` | ✓ | ✅ | `isValidSep7Url` | Validate memo type is one of allowed types |
| `validate_memo_value` | ✓ | ✅ | `isValidSep7Url` | Validate memo value based on memo type |
| `validate_message_length` | ✓ | ✅ | `isValidSep7Url` | Validate message parameter length (max 300 chars) |
| `validate_operation_type` | ✓ | ✅ | `isValidSep7Url` | Validate operation type is tx or pay |
| `validate_origin_domain` | ✓ | ✅ | `isValidSep7Url` | Validate origin_domain is fully qualified domain name |
| `validate_stellar_address` | ✓ | ✅ | `isValidSep7Url` | Validate Stellar addresses (account IDs, muxed accounts, contract IDs) |
| `validate_uri_scheme` | ✓ | ✅ | `isValidSep7Url` | Validate that URI starts with web+stellar: |
| `validate_xdr_parameter` | ✓ | ✅ | `isValidSep7Url` | Validate XDR parameter for tx operation |

## Implementation Gaps

🎉 **No gaps found!** All fields are implemented.

## Recommendations

✅ The SDK has full compatibility with SEP-0007!

## Legend

- ✅ **Implemented**: Field is implemented in SDK
- ❌ **Not Implemented**: Field is missing from SDK
- ✓ **Required**: Field is required by SEP specification
- (blank) **Optional**: Field is optional
