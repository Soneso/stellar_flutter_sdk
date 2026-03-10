# SEP-0030 (Account Recovery: multi-party recovery of Stellar accounts) Compatibility Matrix

**Generated:** 2026-03-10 19:47:50  
**SDK Version:** 3.0.4  
**SEP Version:** 0.8.1  
**SEP Status:** Draft  
**SEP URL:** https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0030.md

## SEP Summary

This protocol defines an API that enables an individual (e.g., a user or
wallet) to regain access to a Stellar account that it owns after the individual
has lost its private key without providing any third party control of the
account. Using this protocol, the user or wallet will preregister the account
and a phone number, email, or other form of authentication with one or more
servers implementing the protocol and add those servers as signers of the
account. If two or more servers are used with appropriate signer configuration
no individual server will have control of the account, but collectively, they
may help the individual recover access to the account. The protocol also
enables individuals to pass control of a Stellar account to another individual.

## Overall Coverage

**Total Coverage:** 100.0% (33/33 fields)

- ✅ **Implemented:** 33/33
- ❌ **Not Implemented:** 0/33

**Required Fields:** 100.0% (29/29)

**Optional Fields:** 100.0% (4/4)

## Implementation Status

✅ **Implemented**

### Implementation Files

- `lib/src/sep/0030/recovery.dart`

### Key Classes

- **`SEP30RecoveryService`**: Main service for SEP-30 account recovery operations
- **`SEP30Request`**: Request for registering an account for recovery
- **`SEP30RequestIdentity`**: Identity information for recovery registration
- **`SEP30AuthMethod`**: Authentication method for identity verification
- **`SEP30AccountResponse`**: Response containing single account recovery details
- **`SEP30AccountsResponse`**: Response containing list of recoverable accounts
- **`SEP30ResponseSigner`**: Signer information in account recovery response
- **`SEP30ResponseIdentity`**: Identity information in account recovery response
- **`SEP30SignatureResponse`**: Response containing recovery signature
- **`SEP30ResponseException`**: Base exception for SEP-30 errors
- **`SEP30BadRequestResponseException`**: Exception for invalid request parameters
- **`SEP30UnauthorizedResponseException`**: Exception when authentication fails
- **`SEP30NotFoundResponseException`**: Exception when account is not found
- **`SEP30ConflictResponseException`**: Exception when account already registered
- **`SEP30UnknownResponseException`**: Exception for unrecognized response format

## Coverage by Section

| Section | Coverage | Required Coverage | Implemented | Not Implemented | Total |
|---------|----------|-------------------|-------------|-----------------|-------|
| API Endpoints | 100.0% | 100.0% | 6 | 0 | 6 |
| Authentication | 100.0% | 100.0% | 1 | 0 | 1 |
| Error Codes | 100.0% | 100.0% | 4 | 0 | 4 |
| Recovery Features | 100.0% | 100.0% | 6 | 0 | 6 |
| Request Fields | 100.0% | 100.0% | 7 | 0 | 7 |
| Response Fields | 100.0% | 100.0% | 9 | 0 | 9 |

## Detailed Field Comparison

### API Endpoints

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `delete_account` | ✓ | ✅ | `deleteAccount` | DELETE /accounts/{address} - Delete account record |
| `get_account` | ✓ | ✅ | `accountDetails` | GET /accounts/{address} - Retrieve account details |
| `list_accounts` | ✓ | ✅ | `accounts` | GET /accounts - List accessible accounts |
| `register_account` | ✓ | ✅ | `registerAccount` | POST /accounts/{address} - Register an account for recovery |
| `sign_transaction` | ✓ | ✅ | `signTransaction` | POST /accounts/{address}/sign/{signing-address} - Sign a transaction |
| `update_account` | ✓ | ✅ | `updateIdentitiesForAccount` | PUT /accounts/{address} - Update identities for an account |

### Authentication

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `jwt_token` | ✓ | ✅ | - | JWT token authentication via Authorization header |

### Error Codes

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `400` | ✓ | ✅ | `SEP30BadRequestResponseException` | Invalid request parameters or malformed data |
| `401` | ✓ | ✅ | `SEP30UnauthorizedResponseException` | Missing or invalid JWT token |
| `404` | ✓ | ✅ | `SEP30NotFoundResponseException` | Account or resource not found |
| `409` | ✓ | ✅ | `SEP30ConflictResponseException` | Account already exists or conflicting operation |

### Recovery Features

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `account_sharing` |  | ✅ | - | Support for shared account access |
| `flexible_auth_methods` | ✓ | ✅ | - | Support for multiple authentication method types |
| `identity_roles` | ✓ | ✅ | - | Support for owner and other identity roles |
| `multi_party_recovery` | ✓ | ✅ | - | Support for multi-server account recovery |
| `pagination` |  | ✅ | - | Pagination support in list accounts endpoint |
| `transaction_signing` | ✓ | ✅ | - | Server-side transaction signing for recovery |

### Request Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `after` |  | ✅ | `after` | Cursor for pagination in list accounts endpoint |
| `auth_methods` | ✓ | ✅ | `authMethods` | Array of authentication methods for the identity |
| `identities` | ✓ | ✅ | `identities` | Array of identity objects for account recovery |
| `role` | ✓ | ✅ | `role` | Role of the identity (owner or other) |
| `transaction` | ✓ | ✅ | `transaction` | Base64-encoded XDR transaction envelope to sign |
| `type` | ✓ | ✅ | `type` | Type of authentication method |
| `value` | ✓ | ✅ | `value` | Value of the authentication method (address, phone, email, etc.) |

### Response Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `accounts` | ✓ | ✅ | `accounts` | Array of account objects in list response |
| `address` | ✓ | ✅ | `address` | Stellar address of the registered account |
| `authenticated` |  | ✅ | `authenticated` | Whether the identity has been authenticated |
| `identities` | ✓ | ✅ | `identities` | Array of registered identity objects |
| `key` | ✓ | ✅ | `key` | Public key of the signer |
| `network_passphrase` | ✓ | ✅ | `networkPassphrase` | Network passphrase used for signing |
| `role` | ✓ | ✅ | `role` | Role of the identity in response |
| `signature` | ✓ | ✅ | `signature` | Base64-encoded signature of the transaction |
| `signers` | ✓ | ✅ | `signers` | Array of signer objects for the account |

## Implementation Gaps

🎉 **No gaps found!** All fields are implemented.

## Recommendations

✅ The SDK has full compatibility with SEP-0030!

## Legend

- ✅ **Implemented**: Field is implemented in SDK
- ❌ **Not Implemented**: Field is missing from SDK
- ⚙️ **Server**: Server-side only feature (not applicable to client SDKs)
- ✓ **Required**: Field is required by SEP specification
- (blank) **Optional**: Field is optional
