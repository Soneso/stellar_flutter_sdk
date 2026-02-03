# SEP-0045 (Stellar Web Authentication for Contract Accounts) Compatibility Matrix

**Generated:** 2026-02-03 17:26:57  
**SDK Version:** 3.0.1  
**SEP Version:** 0.1.1  
**SEP Status:** Draft  
**SEP URL:** https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0045.md

## SEP Summary

This SEP defines the standard way for clients such as wallets or exchanges to
create authenticated web sessions on behalf of a user who holds a contract
account. A wallet may want to authenticate with any web service which requires
a contract account ownership verification, for example, to upload KYC
information to an anchor in an authenticated way as described in
[SEP-12](sep-0012.md).

This SEP is based on [SEP-10](sep-0010.md), but does not replace it. This SEP
only supports `C` (contract) accounts. SEP-10 only supports `G` and `M`
accounts. Services wishing to support all accounts should implement both SEPs.

## Overall Coverage

**Total Coverage:** 100.0% (35/35 fields)

- ✅ **Implemented:** 35/35
- ❌ **Not Implemented:** 0/35

_Note: Excludes 1 server-side-only feature(s) not applicable to client SDKs_

**Required Fields:** 100.0% (28/28)

**Optional Fields:** 100.0% (7/7)

## Implementation Status

✅ **Implemented**

### Implementation Files

- `lib/src/sep/0045/webauth_for_contracts.dart`

### Key Classes

- **`ContractChallengeValidationException`**: Base exception for contract challenge validation errors
- **`ContractChallengeValidationErrorInvalidContractAddress`**: Error when contract address is invalid
- **`ContractChallengeValidationErrorInvalidFunctionName`**: Error when function name is not __check_auth
- **`ContractChallengeValidationErrorSubInvocationsFound`**: Error when sub-invocations are present
- **`ContractChallengeValidationErrorInvalidHomeDomain`**: Error when home domain is invalid
- **`ContractChallengeValidationErrorInvalidWebAuthDomain`**: Error when web auth domain is invalid
- **`ContractChallengeValidationErrorInvalidAccount`**: Error when account address is invalid
- **`ContractChallengeValidationErrorInvalidNonce`**: Error when nonce is invalid or expired
- **`ContractChallengeValidationErrorInvalidServerSignature`**: Error when server signature is invalid
- **`ContractChallengeValidationErrorMissingServerEntry`**: Error when server entry is missing
- **`ContractChallengeValidationErrorMissingClientEntry`**: Error when client entry is missing
- **`ContractChallengeValidationErrorInvalidArgs`**: Error when challenge arguments are invalid
- **`ContractChallengeValidationErrorInvalidNetworkPassphrase`**: Error when network passphrase is invalid
- **`ContractChallengeRequestErrorResponse`**: Error response from contract challenge request
- **`SubmitContractChallengeErrorResponseException`**: Exception when challenge submission returns error
- **`SubmitContractChallengeTimeoutResponseException`**: Exception when challenge submission times out
- **`SubmitContractChallengeUnknownResponseException`**: Exception for unknown challenge response
- **`NoWebAuthForContractsEndpointFoundException`**: Exception when contract auth endpoint not found
- **`NoWebAuthContractIdFoundException`**: Exception when contract ID not found in stellar.toml
- **`MissingClientDomainForContractAuthException`**: Exception when client domain is required but missing
- **`ContractChallengeResponse`**: Response containing contract authentication challenge
- **`SubmitContractChallengeResponse`**: Response after submitting signed contract challenge
- **`WebAuthForContracts`**: Client-side SEP-45 web authentication for contract accounts

## Coverage by Section

| Section | Coverage | Required Coverage | Implemented | Not Implemented | Total |
|---------|----------|-------------------|-------------|-----------------|-------|
| Authentication Endpoints | 100.0% | 100.0% | 2 | 0 | 2 |
| Challenge Features | 100.0% | 100.0% | 8 | 0 | 8 |
| Client Domain Features | 100.0% | 100% | 5 | 0 | 5 |
| Exception Types | 100.0% | 100.0% | 8 | 0 | 8 |
| JWT Token Features | 100.0% | 100.0% | 2 | 0 | 2 |
| Validation Features | 100.0% | 100.0% | 10 | 0 | 10 |

## Detailed Field Comparison

### Authentication Endpoints

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `get_auth_challenge` | ✓ | ✅ | `getChallenge` | GET /auth endpoint - Returns authorization entries for contract accounts |
| `post_auth_token` | ✓ | ✅ | `sendSignedChallenge` | POST /auth endpoint - Validates signed authorization entries and returns JWT token |

### Challenge Features

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `authorization_entry_decoding` | ✓ | ✅ | `decodeAuthorizationEntries` | Decode base64 XDR encoded authorization entries from server |
| `authorization_entry_encoding` | ✓ | ✅ | `sendSignedChallenge` | Encode signed authorization entries to base64 XDR for submission |
| `auto_signature_expiration` |  | ✅ | `fromDomain` | Automatically fetch and set signature expiration from Soroban RPC |
| `client_entry_signing` | ✓ | ✅ | `fromDomain` | Sign client authorization entry with provided signers |
| `contract_invocation_parsing` | ✓ | ✅ | `validateChallenge` | Parse web_auth_verify contract invocation from authorization entries |
| `nonce_consistency` | ✓ | ✅ | `validateChallenge` | Verify nonce is consistent across all authorization entries |
| `server_entry_signing` | ✓ | ✅ | `validateChallenge` | Server entry is pre-signed in challenge |
| `signature_expiration_ledger` | ✓ | ✅ | `fromDomain` | Support signature expiration ledger for replay protection |

### Client Domain Features

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `client_domain_callback_signing` |  | ✅ | `fromDomain` | Sign client domain entry via remote callback |
| `client_domain_entry` |  | ✅ | `fromDomain` | Handle client domain authorization entry in challenge |
| `client_domain_local_signing` |  | ✅ | `fromDomain` | Sign client domain entry with local keypair |
| `client_domain_parameter` |  | ✅ | `getChallenge` | Support optional client_domain parameter in challenge request |
| `client_domain_toml_lookup` |  | ✅ | `fromDomain` | Lookup client domain signing key from stellar.toml |

### Exception Types

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `challenge_request_error_exception` | ✓ | ✅ | `ContractChallengeRequestErrorResponse` | Exception for challenge request errors |
| `invalid_contract_address_exception` | ✓ | ✅ | `ContractChallengeValidationErrorInvalidContractAddress` | Exception for contract address mismatch |
| `invalid_function_name_exception` | ✓ | ✅ | `ContractChallengeValidationErrorInvalidFunctionName` | Exception for invalid function name |
| `invalid_server_signature_exception` | ✓ | ✅ | `ContractChallengeValidationErrorInvalidServerSignature` | Exception for invalid server signature |
| `missing_client_entry_exception` | ✓ | ✅ | `ContractChallengeValidationErrorMissingClientEntry` | Exception when client entry is missing |
| `missing_server_entry_exception` | ✓ | ✅ | `ContractChallengeValidationErrorMissingServerEntry` | Exception when server entry is missing |
| `sub_invocations_exception` | ✓ | ✅ | `ContractChallengeValidationErrorSubInvocationsFound` | Exception when sub-invocations found |
| `submit_challenge_error_exception` | ✓ | ✅ | `SubmitContractChallengeErrorResponseException` | Exception for challenge submission errors |

### JWT Token Features

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `complete_auth_flow` | ✓ | ✅ | `fromDomain` | Execute complete authentication flow via jwtToken method |
| `jwt_token_generation` |  | ⚙️ Server | N/A | Generate JWT token after successful challenge validation **Note:** Server-side feature. Client SDKs receive and use the JWT token. |
| `jwt_token_response` | ✓ | ✅ | `sendSignedChallenge` | Parse JWT token from server response |

### Validation Features

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `account_validation` | ✓ | ✅ | `validateChallenge` | Validate account argument matches client contract account |
| `client_entry_presence` | ✓ | ✅ | `validateChallenge` | Validate client authorization entry is present |
| `contract_address_validation` | ✓ | ✅ | `validateChallenge` | Validate contract address matches WEB_AUTH_CONTRACT_ID from stellar.toml |
| `function_name_validation` | ✓ | ✅ | `validateChallenge` | Validate function name is web_auth_verify |
| `home_domain_validation` | ✓ | ✅ | `validateChallenge` | Validate home_domain argument matches expected domain |
| `network_passphrase_validation` |  | ✅ | `fromDomain` | Validate network passphrase if provided in response |
| `server_entry_presence` | ✓ | ✅ | `validateChallenge` | Validate server authorization entry is present |
| `server_signature_verification` | ✓ | ✅ | `validateChallenge` | Verify server signature on server authorization entry |
| `sub_invocations_check` | ✓ | ✅ | `validateChallenge` | Reject authorization entries with sub-invocations |
| `web_auth_domain_validation` | ✓ | ✅ | `validateChallenge` | Validate web_auth_domain argument matches server domain |

## Implementation Gaps

🎉 **No gaps found!** All fields are implemented.

## Recommendations

✅ The SDK has full compatibility with SEP-0045!

## Legend

- ✅ **Implemented**: Field is implemented in SDK
- ❌ **Not Implemented**: Field is missing from SDK
- ⚙️ **Server**: Server-side only feature (not applicable to client SDKs)
- ✓ **Required**: Field is required by SEP specification
- (blank) **Optional**: Field is optional

**Note:** Excludes 1 server-side-only feature(s) not applicable to client SDKs
