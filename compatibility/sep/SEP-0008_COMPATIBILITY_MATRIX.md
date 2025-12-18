# SEP-0008 (Regulated Assets) Compatibility Matrix

**Generated:** 2025-12-18 14:04:41

**SDK Version:** 2.2.1
**SEP Version:** 1.7.4
**SEP Status:** Active
**SEP URL:** https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0008.md

## SEP Summary

Regulated Assets are assets that require an issuer’s approval (or a delegated
third party’s approval, such as a licensed securities exchange) on a
per-transaction basis. It standardizes the identification of such assets as
well as defines the protocol for performing compliance checks and requesting
issuer approval.

## Overall Coverage

**Total Coverage:** 100.0% (32/32 fields)

- ✅ **Implemented:** 32/32
- ❌ **Not Implemented:** 0/32

**Required Fields:** 100.0% (27/27)

**Optional Fields:** 100.0% (5/5)

## Implementation Status

✅ **Implemented**

### Implementation Files

- `lib/src/sep/0008/regulated_assets.dart`

### Key Classes

- **`RegulatedAssetsService`**: Service for interacting with SEP-0008 regulated assets.
- **`PostActionResponse`**
- **`PostActionDone`**: Service for interacting with SEP-0008 regulated assets.
- **`PostActionNextUrl`**: Service for interacting with SEP-0008 regulated assets.
- **`PostTransactionResponse`**
- **`PostTransactionSuccess`**: Service for interacting with SEP-0008 regulated assets.
- **`PostTransactionRevised`**: Service for interacting with SEP-0008 regulated assets.
- **`PostTransactionPending`**: Service for interacting with SEP-0008 regulated assets.
- **`PostTransactionActionRequired`**: Service for interacting with SEP-0008 regulated assets.
- **`PostTransactionRejected`**: Service for interacting with SEP-0008 regulated assets.
- **`RegulatedAsset`**: Service for interacting with SEP-0008 regulated assets.
- **`IssuerAccountNotFound`**: Service for interacting with SEP-0008 regulated assets.
- **`IncompleteInitData`**: Service for interacting with SEP-0008 regulated assets.
- **`UnknownPostTransactionResponseStatus`**: Service for interacting with SEP-0008 regulated assets.
- **`UnknownPostTransactionResponse`**: Service for interacting with SEP-0008 regulated assets.
- **`UnknownPostActionResponse`**: Service for interacting with SEP-0008 regulated assets.
- **`UnknownPostActionResponseResult`**: Service for interacting with SEP-0008 regulated assets.

## Coverage by Section

| Section | Coverage | Required Coverage | Implemented | Total |
|---------|----------|-------------------|-------------|-------|
| Action Required Response Fields | 100.0% | 100.0% | 5 | 5 |
| Action URL Handling | 100.0% | 100.0% | 4 | 4 |
| Approval Endpoint | 100.0% | 100.0% | 1 | 1 |
| Authorization Flags | 100.0% | 100.0% | 2 | 2 |
| Pending Response Fields | 100.0% | 100.0% | 3 | 3 |
| Rejected Response Fields | 100.0% | 100.0% | 2 | 2 |
| Request Parameters | 100.0% | 100.0% | 1 | 1 |
| Response Statuses | 100.0% | 100.0% | 5 | 5 |
| Revised Response Fields | 100.0% | 100.0% | 3 | 3 |
| Stellar TOML Fields | 100.0% | 100.0% | 3 | 3 |
| Success Response Fields | 100.0% | 100.0% | 3 | 3 |

## Detailed Field Comparison

### Action Required Response Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `action_fields` |  | ✅ | `actionFields` | An array of additional fields defined by SEP-9 Standard KYC / AML fields that the client may optionally provide to the approval service when sending the request to the action_url |
| `action_method` |  | ✅ | `actionMethod` | GET or POST, indicating the type of request that should be made to the action_url. If not provided, GET is assumed. |
| `action_url` | ✓ | ✅ | `actionUrl` | A URL that allows the user to complete the actions required to have the transaction approved |
| `message` | ✓ | ✅ | `message` | A human readable string containing information regarding the action required |
| `status` | ✓ | ✅ | `status` | Status value "action_required" |

### Action URL Handling

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `action_url_get` | ✓ | ✅ | - | Support for GET method to action_url with query parameters |
| `action_url_post` | ✓ | ✅ | `postAction` | Support for POST method to action_url with JSON body |
| `action_url_post_response_follow_next_url` | ✓ | ✅ | `PostActionNextUrl` | Handle POST response with result "follow_next_url" and next_url field |
| `action_url_post_response_no_further_action` | ✓ | ✅ | `PostActionDone` | Handle POST response with result "no_further_action_required" |

### Approval Endpoint

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `tx_approve` | ✓ | ✅ | `postTransaction` | POST /tx_approve - Approval server endpoint that receives a signed transaction, checks for compliance, and signs it on success |

### Authorization Flags

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `authorization_required` | ✓ | ✅ | `authorizationRequired` | Authorization Required flag must be set on issuer account |
| `authorization_revocable` | ✓ | ✅ | `authorizationRequired` | Authorization Revocable flag must be set on issuer account |

### Pending Response Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `message` |  | ✅ | `message` | A human readable string containing information to pass on to the user |
| `status` | ✓ | ✅ | `status` | Status value "pending" |
| `timeout` | ✓ | ✅ | `timeout` | Number of milliseconds to wait before submitting the same transaction again. Use 0 if the wait time cannot be determined. |

### Rejected Response Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `error` | ✓ | ✅ | `error` | A human readable string explaining why the transaction is not compliant and could not be made compliant |
| `status` | ✓ | ✅ | `status` | Status value "rejected" |

### Request Parameters

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `tx` | ✓ | ✅ | `postTransaction` | A base64 encoded transaction envelope XDR signed by the user. This is the transaction that will be tested for compliance and signed on success. |

### Response Statuses

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `action_required` | ✓ | ✅ | `PostTransactionActionRequired` | User must complete an action before this transaction can be approved |
| `pending` | ✓ | ✅ | `PostTransactionPending` | Issuer could not determine whether to approve the transaction at the time of receiving it |
| `rejected` | ✓ | ✅ | `PostTransactionRejected` | Transaction is not compliant and could not be revised to be made compliant |
| `revised` | ✓ | ✅ | `PostTransactionRevised` | Transaction was revised to be made compliant |
| `success` | ✓ | ✅ | `PostTransactionSuccess` | Transaction was found compliant and signed without being revised |

### Revised Response Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `message` | ✓ | ✅ | `message` | A human readable string explaining the modifications made to the transaction to make it compliant |
| `status` | ✓ | ✅ | `status` | Status value "revised" |
| `tx` | ✓ | ✅ | `tx` | Transaction envelope XDR, base64 encoded. This transaction is a revised compliant version of the original request transaction, signed by the issuer. |

### Stellar TOML Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `approval_criteria` |  | ✅ | `approvalCriteria` | A human readable string that explains the issuer's requirements for approving transactions |
| `approval_server` | ✓ | ✅ | `approvalServer` | The URL of an approval service that signs validated transactions |
| `regulated` | ✓ | ✅ | `CurrencyInfo.regulated` | A boolean indicating whether or not this is a regulated asset. If missing, false is assumed. |

### Success Response Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `message` |  | ✅ | `message` | A human readable string containing information to pass on to the user |
| `status` | ✓ | ✅ | `status` | Status value "success" |
| `tx` | ✓ | ✅ | `tx` | Transaction envelope XDR, base64 encoded. This transaction will have both the original signature(s) from the request as well as one or multiple additional signatures from the issuer. |

## Implementation Gaps

🎉 **No gaps found!** All fields are implemented.

## Recommendations

✅ The SDK has full compatibility with SEP-0008!

## Legend

- ✅ **Implemented**: Field is implemented in SDK
- ❌ **Not Implemented**: Field is missing from SDK
- ⚙️ **Server**: Server-side only feature (not applicable to client SDKs)
- ✓ **Required**: Field is required by SEP specification
- (blank) **Optional**: Field is optional
