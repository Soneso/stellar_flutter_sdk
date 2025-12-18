# SEP-0010 (Stellar Web Authentication) Compatibility Matrix

**Generated:** 2025-12-18 14:04:42

**SDK Version:** 2.2.1
**SEP Version:** 3.4.1
**SEP Status:** Active
**SEP URL:** https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0010.md

## SEP Summary

This SEP defines the standard way for clients such as wallets or exchanges to
create authenticated web sessions on behalf of a user who holds a Stellar
account. A wallet may want to authenticate with any web service which requires
a Stellar account ownership verification, for example, to upload KYC
information to an anchor in an authenticated way as described in
[SEP-12](sep-0012.md).

This SEP also supports authenticating users of shared, omnibus, or pooled
Stellar accounts. Clients can use [memos](#memos) or
[muxed accounts](#muxed-accounts) to distinguish users or sub-accounts of
shared accounts.

## Overall Coverage

**Total Coverage:** 100.0% (24/24 fields)

- ✅ **Implemented:** 24/24
- ❌ **Not Implemented:** 0/24

_Note: Excludes 2 server-side-only feature(s) not applicable to client SDKs_

**Required Fields:** 100.0% (19/19)

**Optional Fields:** 100.0% (5/5)

## Implementation Status

✅ **Implemented**

### Implementation Files

- `lib/src/sep/0010/webauth.dart`

### Key Classes

- **`WebAuth`**: Implements SEP-0010 Web Authentication protocol for Stellar applications.
- **`_ChallengeRequestBuilder`**: Implements SEP-0010 Web Authentication protocol for Stellar applications.
- **`ChallengeRequestErrorResponse`**: Implements SEP-0010 Web Authentication protocol for Stellar applications.
- **`ChallengeValidationError`**: Implements SEP-0010 Web Authentication protocol for Stellar applications.
- **`ChallengeValidationErrorInvalidSeqNr`**: Implements SEP-0010 Web Authentication protocol for Stellar applications.
- **`ChallengeValidationErrorInvalidSourceAccount`**: Implements SEP-0010 Web Authentication protocol for Stellar applications.
- **`ChallengeValidationErrorInvalidTimeBounds`**: Implements SEP-0010 Web Authentication protocol for Stellar applications.
- **`ChallengeValidationErrorInvalidOperationType`**: Implements SEP-0010 Web Authentication protocol for Stellar applications.
- **`ChallengeValidationErrorInvalidHomeDomain`**: Implements SEP-0010 Web Authentication protocol for Stellar applications.
- **`ChallengeValidationErrorInvalidWebAuthDomain`**: Implements SEP-0010 Web Authentication protocol for Stellar applications.
- **`ChallengeValidationErrorInvalidSignature`**: Implements SEP-0010 Web Authentication protocol for Stellar applications.
- **`ChallengeValidationErrorMemoAndMuxedAccount`**: Implements SEP-0010 Web Authentication protocol for Stellar applications.
- **`ChallengeValidationErrorInvalidMemoType`**: Implements SEP-0010 Web Authentication protocol for Stellar applications.
- **`ChallengeValidationErrorInvalidMemoValue`**: Implements SEP-0010 Web Authentication protocol for Stellar applications.
- **`SubmitCompletedChallengeTimeoutResponseException`**: Implements SEP-0010 Web Authentication protocol for Stellar applications.
- **`SubmitCompletedChallengeUnknownResponseException`**: Implements SEP-0010 Web Authentication protocol for Stellar applications.
- **`SubmitCompletedChallengeErrorResponseException`**: Implements SEP-0010 Web Authentication protocol for Stellar applications.
- **`NoWebAuthEndpointFoundException`**: Implements SEP-0010 Web Authentication protocol for Stellar applications.
- **`NoWebAuthServerSigningKeyFoundException`**: Implements SEP-0010 Web Authentication protocol for Stellar applications.
- **`NoClientDomainSigningKeyFoundException`**: Implements SEP-0010 Web Authentication protocol for Stellar applications.
- **`MissingClientDomainException`**: Implements SEP-0010 Web Authentication protocol for Stellar applications.
- **`MissingTransactionInChallengeResponseException`**: Implements SEP-0010 Web Authentication protocol for Stellar applications.
- **`NoMemoForMuxedAccountsException`**: Implements SEP-0010 Web Authentication protocol for Stellar applications.

## Coverage by Section

| Section | Coverage | Required Coverage | Implemented | Total |
|---------|----------|-------------------|-------------|-------|
| Authentication Endpoints | 100.0% | 100.0% | 2 | 2 |
| Challenge Transaction Features | 100.0% | 100.0% | 9 | 9 |
| Client Domain Features | 100.0% | 100% | 3 | 3 |
| JWT Token Features | 100.0% | 100.0% | 4 | 4 |
| Verification Features | 100.0% | 100.0% | 6 | 6 |

## Detailed Field Comparison

### Authentication Endpoints

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `get_auth_challenge` | ✓ | ✅ | `getChallenge` | GET /auth endpoint - Returns challenge transaction |
| `post_auth_token` | ✓ | ✅ | `sendSignedChallengeTransaction` | POST /auth endpoint - Validates signed challenge and returns JWT token |

### Challenge Transaction Features

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `challenge_transaction_generation` | ✓ | ✅ | `getChallenge` | Generate challenge transaction with proper structure |
| `home_domain_operation` | ✓ | ✅ | `validateChallenge` | First operation contains home_domain + " auth" as data name |
| `manage_data_operations` | ✓ | ✅ | `validateChallenge` | Challenge uses ManageData operations for auth data |
| `nonce_generation` | ✓ | ✅ | `getChallenge` | Random nonce in ManageData operation value |
| `sequence_number_zero` | ✓ | ✅ | `validateChallenge` | Challenge transaction has sequence number 0 |
| `server_signature` | ✓ | ✅ | `validateChallenge` | Challenge is signed by server before sending to client |
| `timebounds_enforcement` | ✓ | ✅ | `validateChallenge` | Challenge transaction has timebounds for expiration |
| `transaction_envelope_format` | ✓ | ✅ | `validateChallenge` | Challenge uses proper Stellar transaction envelope format |
| `web_auth_domain_operation` |  | ✅ | `validateChallenge` | Optional operation with web_auth_domain for domain verification |

### Client Domain Features

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `client_domain_operation` |  | ✅ | `validateChallenge` | Add client_domain ManageData operation to challenge |
| `client_domain_parameter` |  | ✅ | `getChallenge` | Support optional client_domain parameter in GET /auth |
| `client_domain_signature` |  | ✅ | `signTransaction` | Require signature from client domain account |
| `client_domain_verification` |  | ⚙️ Server | N/A | Verify client domain by checking stellar.toml **Note:** This is a server-side verification feature. Client SDKs only need to support the client_domain parameter and signing. |

### JWT Token Features

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `jwt_claims` | ✓ | ✅ | `sendSignedChallengeTransaction` | JWT token includes required claims (sub, iat, exp) |
| `jwt_expiration` | ✓ | ✅ | `sendSignedChallengeTransaction` | JWT token includes expiration time |
| `jwt_token_generation` | ✓ | ✅ | `sendSignedChallengeTransaction` | Generate JWT token after successful challenge validation |
| `jwt_token_response` | ✓ | ✅ | `sendSignedChallengeTransaction` | Return JWT token in JSON response with "token" field |
| `jwt_token_validation` |  | ⚙️ Server | N/A | Validate JWT token structure and signature **Note:** This is a server-side validation feature. Client SDKs only need to receive, store, and send the JWT as a bearer token. |

### Verification Features

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `challenge_validation` | ✓ | ✅ | `validateChallenge` | Validate challenge transaction structure and content |
| `home_domain_validation` | ✓ | ✅ | `validateChallenge` | Validate home domain in challenge matches server |
| `memo_support` |  | ✅ | `getChallenge` | Support optional memo in challenge for muxed accounts |
| `multi_signature_support` | ✓ | ✅ | `signTransaction` | Support multiple signatures on challenge (client account + signers) |
| `signature_verification` | ✓ | ✅ | `validateChallenge` | Verify all signatures on challenge transaction |
| `timebounds_validation` | ✓ | ✅ | `validateChallenge` | Validate challenge is within valid time window |

## Implementation Gaps

🎉 **No gaps found!** All fields are implemented.

## Recommendations

✅ The SDK has full compatibility with SEP-0010!

## Legend

- ✅ **Implemented**: Field is implemented in SDK
- ❌ **Not Implemented**: Field is missing from SDK
- ⚙️ **Server**: Server-side only feature (not applicable to client SDKs)
- ✓ **Required**: Field is required by SEP specification
- (blank) **Optional**: Field is optional

**Note:** Excludes 2 server-side-only feature(s) not applicable to client SDKs
